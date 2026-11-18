`timescale 1ns / 1ps

module tb_uart_keyword_console;
    localparam integer BIT_CYCLES = 16;
    localparam [55:0] REPLIES = "1230020";
    logic clk = 0;
    logic rst = 0;
    wire tx, rx;
    logic [7:0] reply;
    integer reply_count = 0;

    uart_keyword_console #(.CLK_HZ(16_000), .BAUD_RATE(1000)) dut (
        .clk(clk), .rst(rst), .uart_rx(rx), .uart_tx(tx)
    );
    uart_test_link #(.BIT_CYCLES(BIT_CYCLES)) link (.clk(clk), .tx(tx), .rx(rx));
    always #5 clk = !clk;

    task automatic send_text(input string text);
        for (int i = 0; i < text.len(); i++)
            link.send(text[i]);
    endtask

    initial forever begin
        link.receive(reply);
        if (reply_count >= 7 || reply !== REPLIES[8*(6-reply_count) +: 8])
            $fatal(1, "unexpected response %0d: %h", reply_count, reply);
        reply_count = reply_count + 1;
    end

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_uart_keyword_console.vcd");
            $dumpvars(0, tb_uart_keyword_console);
        end

        #1 rst = 1;
        repeat (3) @(negedge clk);
        rst = 0;
        send_text("StArT");
        link.send(8'h0d);
        link.send(8'h0a);
        send_text("xSSTOPx");
        link.send(8'h0a);
        send_text("FFpGa?");
        link.send(8'h0d);
        send_text("sta");
        link.send(8'h0a);
        send_text("rt");
        link.send(8'h0a);
        send_text("fpga, start, STOP");
        link.send(8'h0d);
        link.send(8'h0a);
        send_text("else");
        link.send(8'h0a);

        repeat (12 * BIT_CYCLES) @(negedge clk);
        if (reply_count != 7) $fatal(1, "received %0d replies, expected seven", reply_count);
        $display("PASS uart_keyword_console");
        $finish;
    end

    initial begin
        #150_000;
        $fatal(1, "keyword console test timed out");
    end
endmodule
