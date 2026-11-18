`timescale 1ns / 1ps
`default_nettype none

module keyword_matcher (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] rx_data,
    input  wire       rx_valid,
    output reg  [7:0] reply_data,
    output reg        reply_valid
);
    wire [7:0] lower_char = (rx_data >= "A" && rx_data <= "Z")
                          ? rx_data + 8'd32 : rx_data;
    wire terminator = rx_data == 8'h0d || rx_data == 8'h0a;
    reg [2:0] start_prefix;
    reg [1:0] stop_prefix, fpga_prefix;
    reg [7:0] last_match;
    reg end_seen;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start_prefix <= 0;
            stop_prefix <= 0;
            fpga_prefix <= 0;
            last_match <= "0";
            end_seen <= 1'b0;
            reply_data <= "0";
            reply_valid <= 1'b0;
        end else begin
            reply_valid <= 1'b0;
            if (rx_valid && terminator && !end_seen) begin
                reply_data <= last_match;
                reply_valid <= 1'b1;
                start_prefix <= 0;
                stop_prefix <= 0;
                fpga_prefix <= 0;
                last_match <= "0";
                end_seen <= 1'b1;
            end else if (rx_valid && !terminator) begin
                end_seen <= 1'b0;
                // A failed extension can still be the first letter of a new candidate.
                start_prefix <= lower_char == "s" ? 3'd1 : 3'd0;
                stop_prefix <= lower_char == "s" ? 2'd1 : 2'd0;
                fpga_prefix <= lower_char == "f" ? 2'd1 : 2'd0;

                case (start_prefix)
                    3'd1: if (lower_char == "t") start_prefix <= 3'd2;
                    3'd2: if (lower_char == "a") start_prefix <= 3'd3;
                    3'd3: if (lower_char == "r") start_prefix <= 3'd4;
                    3'd4: if (lower_char == "t") last_match <= "1";
                    default: ;
                endcase

                case (stop_prefix)
                    2'd1: if (lower_char == "t") stop_prefix <= 2'd2;
                    2'd2: if (lower_char == "o") stop_prefix <= 2'd3;
                    2'd3: if (lower_char == "p") last_match <= "2";
                    default: ;
                endcase

                case (fpga_prefix)
                    2'd1: if (lower_char == "p") fpga_prefix <= 2'd2;
                    2'd2: if (lower_char == "g") fpga_prefix <= 2'd3;
                    2'd3: if (lower_char == "a") last_match <= "3";
                    default: ;
                endcase
            end
        end
    end
endmodule

`default_nettype wire
