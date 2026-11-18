`timescale 1ns / 1ps

module tb_uart_hex_monitor;
    localparam integer BIT_CYCLES = 16;
    localparam integer SCAN_CYCLES = 3;
    localparam [55:0] MESSAGE = {"READY", 8'h0d, 8'h0a};
    logic clk = 0;
    logic rst = 0;
    logic key = 0;
    wire tx, rx;
    wire [7:0] seg, sel;
    logic [7:0] received;
    integer tx_count = 0;

    uart_hex_monitor #(.CLK_HZ(16_000), .BAUD_RATE(1000),
                       .DEBOUNCE_CYCLES(8), .SCAN_CYCLES(SCAN_CYCLES)) dut (
        .clk(clk), .rst(rst), .uart_rx(rx), .key(key),
        .uart_tx(tx), .seg(seg), .sel(sel)
    );
    uart_test_link #(.BIT_CYCLES(BIT_CYCLES)) link (.clk(clk), .tx(tx), .rx(rx));
    always #5 clk = !clk;

    initial forever begin
        link.receive(received);
        if (received !== MESSAGE[8*(6 - tx_count % 7) +: 8])
            $fatal(1, "key-triggered message byte %0d was %h", tx_count, received);
        tx_count = tx_count + 1;
    end

    task automatic check_display(input logic [31:0] expected_digits,
                                 input logic [7:0] expected_visible);
        logic [7:0] seen, selected;
        if (dut.digits !== expected_digits || dut.visible !== expected_visible)
            $fatal(1, "display content/visibility %h %h, expected %h %h",
                   dut.digits, dut.visible, expected_digits, expected_visible);
        seen = 0;
        repeat (8 * SCAN_CYCLES) begin
            @(negedge clk);
            selected = ~sel;
            if ((selected & ~expected_visible) !== 8'h00 ||
                (selected == 0 && seg !== 8'hff) ||
                (selected != 0 && (!$onehot(selected) || seg[7] !== 1'b1)))
                $fatal(1, "invalid physical scan output: sel %h, seg %h", sel, seg);
            seen = seen | selected;
        end
        if (seen !== expected_visible) $fatal(1, "scan did not reach all visible positions");
    endtask

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_uart_hex_monitor.vcd");
            $dumpvars(0, tb_uart_hex_monitor);
        end

        #1 rst = 1;
        repeat (3) @(negedge clk);
        rst = 0;
        check_display(32'h00000000, 8'h03);

        key = 1;
        repeat (2) @(negedge clk);
        key = 0;
        repeat (20) @(negedge clk);
        if (tx !== 1'b1 || tx_count != 0) $fatal(1, "short key bounce triggered a message");

        key = 1;
        link.send("1");
        link.send("x");
        check_display(32'h00000101, 8'h07);
        link.send("2");
        link.send("A");
        link.send("b");
        link.send("3");
        link.send("c");
        link.send("D");
        check_display(32'h2ab3cd07, 8'hff);

        for (int i = 0; i < 92; i++)
            link.send("0");
        check_display(32'h00000099, 8'hff);
        link.send("F");
        check_display(32'h00000f00, 8'hff);
        if (tx_count != 7) $fatal(1, "a held key must send exactly one message");

        key = 0;
        repeat (20) @(negedge clk);
        key = 1;
        repeat (1400) @(negedge clk);
        if (tx_count != 14) $fatal(1, "a second clean press did not send the next message");

        rst = 1;
        #1;
        if ({seg, sel} !== 16'hffff) $fatal(1, "reset must blank the physical display");
        $display("PASS uart_hex_monitor");
        $finish;
    end

    initial begin
        #500_000;
        $fatal(1, "monitor test timed out");
    end
endmodule
