`timescale 1ns / 1ps
`default_nettype none

module hex_history (
    input  wire        clk,
    input  wire        rst,
    input  wire        rx_valid,
    input  wire [7:0]  rx_data,
    output wire [31:0] digits,
    output wire [7:0]  visible
);
    reg [23:0] history;
    reg [5:0] occupied;
    reg [6:0] count;
    reg [3:0] nibble;
    reg is_hex;

    always @* begin
        is_hex = 1'b1;
        nibble = 4'h0;
        if (rx_data >= "0" && rx_data <= "9")
            nibble = rx_data[3:0];
        else if ((rx_data >= "A" && rx_data <= "F") ||
                 (rx_data >= "a" && rx_data <= "f"))
            nibble = rx_data[3:0] + 4'd9;
        else
            is_hex = 1'b0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            history <= 0;
            occupied <= 0;
            count <= 0;
        end else if (rx_valid && is_hex) begin
            history <= {history[19:0], nibble};
            occupied <= {occupied[4:0], 1'b1};
            count <= count == 7'd99 ? 7'd0 : count + 1'b1;
        end
    end

    wire [3:0] count_tens = count / 10;
    wire [3:0] count_ones = count % 10;
    assign digits = {history, count_tens, count_ones};
    assign visible = {occupied, 2'b11};
endmodule

`default_nettype wire
