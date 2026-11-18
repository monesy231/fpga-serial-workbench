`timescale 1ns / 1ps
`default_nettype none

module uart_rx #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD_RATE = 9600
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg        valid,
    output reg  [7:0] data
);
    localparam integer BIT_CYCLES = CLK_HZ / BAUD_RATE;
    localparam integer COUNT_BITS = BIT_CYCLES > 1 ? $clog2(BIT_CYCLES) : 1;
    localparam [2:0] IDLE = 3'd0, START = 3'd1, DATA = 3'd2,
                     STOP = 3'd3, WAIT_HIGH = 3'd4;

    (* ASYNC_REG = "TRUE" *) reg [1:0] rx_sync;
    reg [2:0] state;
    reg [COUNT_BITS-1:0] bit_timer;
    reg [2:0] bit_index;
    reg [7:0] received;
    wire line = rx_sync[1];
    wire bit_center = bit_timer == BIT_CYCLES / 2 - 1;
    wire next_center = bit_timer == BIT_CYCLES - 1;

    always @(posedge clk or posedge rst) begin
        if (rst)
            rx_sync <= 2'b11;
        else
            rx_sync <= {rx_sync[0], rx};
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_timer <= 0;
            bit_index <= 0;
            received <= 0;
            data <= 0;
            valid <= 1'b0;
        end else begin
            valid <= 1'b0;
            case (state)
                IDLE: if (!line) begin
                    bit_timer <= 0;
                    bit_index <= 0;
                    state <= START;
                end
                START: if (bit_center) begin
                    bit_timer <= 0;
                    state <= line ? IDLE : DATA;
                end else begin
                    bit_timer <= bit_timer + 1'b1;
                end
                DATA: if (next_center) begin
                    bit_timer <= 0;
                    received[bit_index] <= line;
                    if (bit_index == 3'd7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1'b1;
                end else begin
                    bit_timer <= bit_timer + 1'b1;
                end
                STOP: if (next_center) begin
                    if (line) begin
                        data <= received;
                        valid <= 1'b1;
                        state <= IDLE;
                    end else begin
                        state <= WAIT_HIGH;
                    end
                end else begin
                    bit_timer <= bit_timer + 1'b1;
                end
                WAIT_HIGH: if (line)
                    state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule

`default_nettype wire
