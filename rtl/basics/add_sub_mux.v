`timescale 1ns / 1ps
`default_nettype none

module add_sub_mux (
    input  wire       en,
    input  wire       mux_sel,
    input  wire [3:0] input_a,
    input  wire [3:0] input_b,
    output reg  [3:0] output_c
);
    always @* begin
        if (!en)
            output_c = 4'hf;
        else if (mux_sel)
            output_c = input_a - input_b;
        else
            output_c = input_a + input_b;
    end
endmodule

`default_nettype wire
