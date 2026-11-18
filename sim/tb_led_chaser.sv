`timescale 1ns / 1ps

module tb_led_chaser;
    logic clk = 0;
    logic rst = 0;
    logic button = 0;
    logic [1:0] freq_set = 0;
    logic dir_set = 0;
    wire [7:0] led;

    led_chaser #(.INTERVAL_0(3), .INTERVAL_1(7), .INTERVAL_2(11), .INTERVAL_3(15)) dut (
        .clk(clk), .rst(rst), .button(button), .freq_set(freq_set),
        .dir_set(dir_set), .led(led)
    );
    always #5 clk = !clk;

    task automatic expect_led(input logic [7:0] value);
        if (led !== value) $fatal(1, "at %0t expected LED %h, got %h", $time, value, led);
    endtask

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_led_chaser.vcd");
            $dumpvars(0, tb_led_chaser);
        end

        #1 rst = 1;
        @(negedge clk);
        rst = 0;
        repeat (8) @(negedge clk);
        expect_led(8'h01);

        button = 1;
        @(posedge dut.running);
        @(negedge clk);
        repeat (2) @(negedge clk);
        expect_led(8'h01);
        @(negedge clk);
        expect_led(8'h80);
        repeat (3) @(negedge clk);
        expect_led(8'h40);

        button = 0;
        repeat (3) @(negedge clk);
        button = 1;
        @(negedge dut.running);
        @(negedge clk);
        expect_led(8'h20);
        button = 0;
        freq_set = 2'b01;
        dir_set = 1;
        repeat (12) @(negedge clk);
        expect_led(8'h20);

        button = 1;
        @(posedge dut.running);
        @(negedge clk);
        repeat (6) @(negedge clk);
        expect_led(8'h20);
        @(negedge clk);
        expect_led(8'h40);

        freq_set = 2'b00;
        wait (dut.speed == 2'b00);
        @(negedge clk);
        repeat (3) @(negedge clk);
        expect_led(8'h40);
        @(negedge clk);
        expect_led(8'h80);

        rst = 1;
        #1;
        expect_led(8'h01);
        $display("PASS led_chaser");
        $finish;
    end

    initial begin
        #10_000;
        $fatal(1, "LED test timed out");
    end
endmodule
