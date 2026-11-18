`timescale 1ns / 1ps
`default_nettype none

module uart_tx #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD_RATE = 9600
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       valid,
    input  wire [7:0] data,
    output wire       busy,
    output reg        tx
);
    localparam integer BIT_CYCLES = CLK_HZ / BAUD_RATE;
    localparam integer COUNT_BITS = BIT_CYCLES > 1 ? $clog2(BIT_CYCLES) : 1;
    localparam [1:0] IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0] state;
    reg [COUNT_BITS-1:0] bit_timer;
    reg [2:0] bit_index;
    reg [7:0] latched_data;
    wire bit_done = bit_timer == BIT_CYCLES - 1;

    assign busy = state != IDLE;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_timer <= 0;
            bit_index <= 0;
            latched_data <= 0;
            tx <= 1'b1;
        end else begin
            if (!busy || bit_done)
                bit_timer <= 0;
            else
                bit_timer <= bit_timer + 1'b1;

            case (state)
                IDLE: if (valid) begin
                    latched_data <= data;
                    bit_index <= 0;
                    tx <= 1'b0;
                    state <= START;
                end
                START: if (bit_done) begin
                    tx <= latched_data[0];
                    state <= DATA;
                end
                DATA: if (bit_done) begin
                    if (bit_index == 3'd7) begin
                        tx <= 1'b1;
                        state <= STOP;
                    end else begin
                        bit_index <= bit_index + 1'b1;
                        tx <= latched_data[bit_index + 1'b1];
                    end
                end
                STOP: if (bit_done)
                    state <= IDLE;
                default: begin
                    state <= IDLE;
                    tx <= 1'b1;
                end
            endcase
        end
    end
endmodule

`default_nettype wire
