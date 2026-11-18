`timescale 1ns / 1ps
`default_nettype none

module uart_message #(
    parameter integer LENGTH = 7,
    parameter [8*LENGTH-1:0] MESSAGE = {"READY", 8'h0d, 8'h0a}
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire       tx_busy,
    output reg        active,
    output wire       tx_valid,
    output wire [7:0] tx_data
);
    localparam integer INDEX_BITS = LENGTH > 1 ? $clog2(LENGTH) : 1;
    reg [INDEX_BITS-1:0] byte_index;
    reg draining;

    assign tx_valid = active && !draining && !tx_busy;
    assign tx_data = MESSAGE[8*(LENGTH - 1 - byte_index) +: 8];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active <= 1'b0;
            byte_index <= 0;
            draining <= 1'b0;
        end else if (!active) begin
            if (start)
                active <= 1'b1;
        end else if (tx_valid) begin
            if (byte_index == LENGTH - 1)
                draining <= 1'b1;
            else
                byte_index <= byte_index + 1'b1;
        end else if (draining && !tx_busy) begin
            // Keep the message active through the last stop bit.
            active <= 1'b0;
            byte_index <= 0;
            draining <= 1'b0;
        end
    end
endmodule

`default_nettype wire
