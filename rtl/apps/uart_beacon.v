`timescale 1ns / 1ps
`default_nettype none

module uart_beacon #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD_RATE = 9600,
    parameter integer GAP_CYCLES = CLK_HZ / 5
) (
    input  wire clk,
    input  wire rst,
    output wire uart_tx
);
    localparam integer GAP_BITS = GAP_CYCLES > 1 ? $clog2(GAP_CYCLES) : 1;
    reg [GAP_BITS-1:0] gap_count;
    wire active, tx_busy, tx_valid;
    wire [7:0] tx_data;
    wire start = !active && gap_count == GAP_CYCLES - 1;

    always @(posedge clk or posedge rst) begin
        if (rst)
            gap_count <= 0;
        else if (active || start)
            gap_count <= 0;
        else
            gap_count <= gap_count + 1'b1;
    end

    uart_message #(.LENGTH(12), .MESSAGE({"HELLO FPGA", 8'h0d, 8'h0a})) message (
        .clk(clk), .rst(rst), .start(start), .tx_busy(tx_busy),
        .active(active), .tx_valid(tx_valid), .tx_data(tx_data)
    );

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD_RATE(BAUD_RATE)) transmitter (
        .clk(clk), .rst(rst), .valid(tx_valid), .data(tx_data),
        .busy(tx_busy), .tx(uart_tx)
    );
endmodule

`default_nettype wire
