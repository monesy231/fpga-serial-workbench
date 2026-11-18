`timescale 1ns / 1ps
`default_nettype none

module dff (
    input  wire clk,
    input  wire clr,
    input  wire en,
    input  wire d,
    output reg  q
);
    always @(posedge clk or posedge clr) begin
        if (clr)
            q <= 1'b0;
        else if (en)
            q <= d;
    end
endmodule

`default_nettype wire
