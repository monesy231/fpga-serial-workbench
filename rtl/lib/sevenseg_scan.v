`timescale 1ns / 1ps
`default_nettype none

module sevenseg_scan #(
    parameter integer SCAN_CYCLES = 12_500
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] digits,
    input  wire [7:0]  visible,
    output reg  [7:0]  seg,
    output reg  [7:0]  sel
);
    localparam integer TIMER_BITS = SCAN_CYCLES > 1 ? $clog2(SCAN_CYCLES) : 1;
    reg [TIMER_BITS-1:0] timer;
    reg [2:0] index;

    function [6:0] active_high_segments;
        input [3:0] digit;
        begin
            case (digit)
                4'h0: active_high_segments = 7'h3f;
                4'h1: active_high_segments = 7'h06;
                4'h2: active_high_segments = 7'h5b;
                4'h3: active_high_segments = 7'h4f;
                4'h4: active_high_segments = 7'h66;
                4'h5: active_high_segments = 7'h6d;
                4'h6: active_high_segments = 7'h7d;
                4'h7: active_high_segments = 7'h07;
                4'h8: active_high_segments = 7'h7f;
                4'h9: active_high_segments = 7'h6f;
                4'ha: active_high_segments = 7'h77;
                4'hb: active_high_segments = 7'h7c;
                4'hc: active_high_segments = 7'h39;
                4'hd: active_high_segments = 7'h5e;
                4'he: active_high_segments = 7'h79;
                4'hf: active_high_segments = 7'h71;
                default: active_high_segments = 7'h00;
            endcase
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 0;
            index <= 3'd0;
            sel <= 8'hff;
            seg <= 8'hff;
        end else begin
            if (timer == SCAN_CYCLES - 1) begin
                timer <= 0;
                index <= index + 1'b1;
            end else begin
                timer <= timer + 1'b1;
            end

            if (visible[index]) begin
                sel <= ~(8'b0000_0001 << index);
                // {dp, g, f, e, d, c, b, a}, all active low on Minisys.
                seg <= {1'b1, ~active_high_segments(digits[4*index +: 4])};
            end else begin
                sel <= 8'hff;
                seg <= 8'hff;
            end
        end
    end
endmodule

`default_nettype wire
