`timescale 1ns / 1ps

// Independent 8N1 stimulus and center-of-bit sampling for the UART benches.
module uart_test_link #(
    parameter integer BIT_CYCLES = 16
) (
    input  wire clk,
    input  wire tx,
    output reg  rx = 1'b1
);
    task automatic drive(input logic level, input integer cycles);
        rx = level;
        repeat (cycles) @(negedge clk);
    endtask

    task automatic send(input logic [7:0] value, input logic stop = 1'b1);
        drive(1'b0, BIT_CYCLES);
        for (int i = 0; i < 8; i++)
            drive(value[i], BIT_CYCLES);
        drive(stop, BIT_CYCLES);
    endtask

    task automatic receive(output logic [7:0] value);
        @(negedge tx);
        repeat (BIT_CYCLES / 2) @(negedge clk);
        if (tx !== 1'b0) $fatal(1, "TX start bit did not stay low");
        for (int i = 0; i < 8; i++) begin
            repeat (BIT_CYCLES) @(negedge clk);
            value[i] = tx;
        end
        repeat (BIT_CYCLES) @(negedge clk);
        if (tx !== 1'b1) $fatal(1, "TX stop bit was not high");
    endtask
endmodule
