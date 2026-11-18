`timescale 1ns / 1ps

module tb_uart_core;
    localparam integer BIT_CYCLES = 100_000_000 / 9600;
    logic clk = 0;
    logic rst = 0;
    logic tx_valid = 0;
    logic [7:0] tx_data = 0;
    wire tx, tx_busy, rx, rx_valid;
    wire [7:0] rx_data;
    logic rx_valid_prev = 0;
    integer received_count = 0;

    uart_tx transmitter (.clk(clk), .rst(rst), .valid(tx_valid), .data(tx_data),
                         .busy(tx_busy), .tx(tx));
    uart_rx receiver (.clk(clk), .rst(rst), .rx(rx), .valid(rx_valid), .data(rx_data));
    uart_test_link #(.BIT_CYCLES(BIT_CYCLES)) link (.clk(clk), .tx(1'b1), .rx(rx));
    always #5 clk = !clk;

    always @(negedge clk) begin
        if (!rst && rx_valid) begin
            if (rx_valid_prev) $fatal(1, "RX valid must be one clock wide");
            case (received_count)
                0: if (rx_data !== 8'ha3) $fatal(1, "first RX byte was %h", rx_data);
                1: if (rx_data !== 8'h00) $fatal(1, "second RX byte was %h", rx_data);
                2: if (rx_data !== 8'hff) $fatal(1, "RX did not recover after a bad stop");
                default: $fatal(1, "unexpected RX byte %h", rx_data);
            endcase
            received_count = received_count + 1;
        end
        rx_valid_prev = rx_valid;
    end

    task automatic check_tx(input logic [7:0] value);
        logic [9:0] frame;
        frame = {1'b1, value, 1'b0};
        @(negedge clk);
        tx_data = value;
        tx_valid = 1;
        @(negedge clk);
        tx_valid = 0;
        tx_data = ~value;
        for (int i = 0; i < 10; i++) begin
            if (tx !== frame[i] || tx_busy !== 1'b1)
                $fatal(1, "TX byte %h, first cycle of bit %0d", value, i);
            repeat (BIT_CYCLES - 1) @(negedge clk);
            if (tx !== frame[i] || tx_busy !== 1'b1)
                $fatal(1, "TX byte %h, last cycle of bit %0d", value, i);
            @(negedge clk);
        end
        if (tx !== 1'b1 || tx_busy !== 1'b0) $fatal(1, "TX did not return to idle");
    endtask

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_uart_core.vcd");
            $dumpvars(0, tb_uart_core);
        end

        #1 rst = 1;
        repeat (3) @(negedge clk);
        if (tx !== 1'b1 || tx_busy !== 1'b0) $fatal(1, "reset must leave TX idle");
        rst = 0;

        fork
            begin
                check_tx(8'h96);
                check_tx(8'h00);
                check_tx(8'hff);
            end
            begin
                link.drive(1'b0, BIT_CYCLES / 4);
                link.drive(1'b1, BIT_CYCLES);
                link.send(8'ha3);
                link.send(8'h00);
                #1;
                if (received_count != 2) $fatal(1, "back-to-back RX bytes were lost");
                @(negedge clk);
                link.send(8'h5a, 1'b0);
                link.drive(1'b0, 12 * BIT_CYCLES);
                link.drive(1'b1, BIT_CYCLES);
                if (received_count != 2) $fatal(1, "bad stop or held-low RX produced a byte");
                link.send(8'hff);
                #1;
                if (received_count != 3) $fatal(1, "receiver did not recover");
            end
        join

        $display("PASS uart_core");
        $finish;
    end
endmodule
