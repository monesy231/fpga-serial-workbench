`timescale 1ns / 1ps
`default_nettype none

module reg8file (
    input  wire       clk,
    input  wire       clr,
    input  wire       en,
    input  wire [7:0] d,
    input  wire [2:0] wsel,
    input  wire [2:0] rsel,
    output wire [7:0] q
);
    reg [7:0] registers [0:7];
    integer i;

    always @(posedge clk or posedge clr) begin
        if (clr) begin
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 8'h00;
        end else if (en) begin
            registers[wsel] <= d;
        end
    end

    assign q = registers[rsel];
endmodule

`default_nettype wire
