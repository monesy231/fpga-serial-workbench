`timescale 1ns / 1ps
`default_nettype none

module button_debounce #(
    parameter integer STABLE_CYCLES = 2_000_000
) (
    input  wire clk,
    input  wire rst,
    input  wire button,
    output wire raw_level,
    output reg  pressed
);
    localparam integer COUNT_BITS = STABLE_CYCLES > 1 ? $clog2(STABLE_CYCLES) : 1;
    (* ASYNC_REG = "TRUE" *) reg [1:0] button_sync;
    reg stable_level;
    reg [COUNT_BITS-1:0] count;

    assign raw_level = button_sync[1];

    always @(posedge clk or posedge rst) begin
        if (rst)
            button_sync <= 2'b00;
        else
            button_sync <= {button_sync[0], button};
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stable_level <= 1'b0;
            pressed <= 1'b0;
            count <= 0;
        end else begin
            pressed <= 1'b0;
            if (raw_level == stable_level) begin
                count <= 0;
            end else if (count == STABLE_CYCLES - 1) begin
                stable_level <= raw_level;
                pressed <= raw_level;
                count <= 0;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule

`default_nettype wire
