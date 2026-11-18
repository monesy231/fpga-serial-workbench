`timescale 1ns / 1ps
`default_nettype none

module uart_hex_monitor #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD_RATE = 9600,
    parameter integer DEBOUNCE_CYCLES = (CLK_HZ / 1000) * 30,
    parameter integer SCAN_CYCLES = CLK_HZ / 8000
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       uart_rx,
    input  wire       key,
    output wire       uart_tx,
    output wire [7:0] seg,
    output wire [7:0] sel
);
    wire rx_valid;
    wire [7:0] rx_data;
    wire [31:0] digits;
    wire [7:0] visible;
    wire key_press, tx_busy, tx_valid;
    wire [7:0] tx_data;

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE)) receiver (
        .clk(clk), .rst(rst), .rx(uart_rx), .valid(rx_valid), .data(rx_data)
    );

    hex_history display_data (
        .clk(clk), .rst(rst), .rx_valid(rx_valid), .rx_data(rx_data),
        .digits(digits), .visible(visible)
    );

    sevenseg_scan #(.SCAN_CYCLES(SCAN_CYCLES)) scan (
        .clk(clk), .rst(rst), .digits(digits), .visible(visible), .seg(seg), .sel(sel)
    );

    button_debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) key_filter (
        .clk(clk), .rst(rst), .button(key), .raw_level(), .pressed(key_press)
    );

    uart_message message (
        .clk(clk), .rst(rst), .start(key_press), .tx_busy(tx_busy),
        .active(), .tx_valid(tx_valid), .tx_data(tx_data)
    );

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE)) transmitter (
        .clk(clk), .rst(rst), .valid(tx_valid), .data(tx_data),
        .busy(tx_busy), .tx(uart_tx)
    );
endmodule

`default_nettype wire
