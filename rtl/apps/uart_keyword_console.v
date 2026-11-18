`timescale 1ns / 1ps
`default_nettype none

module uart_keyword_console #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD_RATE = 9600
) (
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx
);
    wire rx_valid, reply_valid;
    wire [7:0] rx_data, reply_data;

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE)) receiver (
        .clk(clk), .rst(rst), .rx(uart_rx), .valid(rx_valid), .data(rx_data)
    );

    keyword_matcher matcher (
        .clk(clk), .rst(rst), .rx_data(rx_data), .rx_valid(rx_valid),
        .reply_data(reply_data), .reply_valid(reply_valid)
    );

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE)) transmitter (
        .clk(clk), .rst(rst), .valid(reply_valid), .data(reply_data),
        .busy(), .tx(uart_tx)
    );
endmodule

`default_nettype wire
