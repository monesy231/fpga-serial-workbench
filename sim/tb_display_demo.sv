`timescale 1ns / 1ps

module tb_display_demo;
    localparam integer SCAN_CYCLES = 3;
    logic clk = 0;
    logic rst = 0;
    logic run_button = 0, count_button = 0, display_en = 0;
    wire [7:0] seg, sel;
    logic [7:0] seen, selected;
    logic [5:0] paused_count;

    display_demo #(.DEBOUNCE_CYCLES(6), .SCAN_CYCLES(SCAN_CYCLES), .TICK_CYCLES(64)) dut (
        .clk(clk), .rst(rst), .run_button(run_button), .count_button(count_button),
        .display_en(display_en), .seg(seg), .sel(sel)
    );
    always #5 clk = !clk;

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_display_demo.vcd");
            $dumpvars(0, tb_display_demo);
        end

        #1 rst = 1;
        @(negedge clk);
        rst = 0;
        repeat (6) @(negedge clk);
        if ({seg, sel} !== 16'hffff) $fatal(1, "disabled display is not blank");

        display_en = 1;
        count_button = 1;
        repeat (2) @(negedge clk);
        count_button = 0;
        repeat (2) @(negedge clk);
        count_button = 1;
        repeat (2) @(negedge clk);
        count_button = 0;
        repeat (2) @(negedge clk);
        count_button = 1;
        repeat (24) @(negedge clk);
        if (dut.raw_count !== 7'd3 || dut.stable_count !== 7'd1)
            $fatal(1, "one bounced press must count as three raw edges and one stable edge");

        count_button = 0;
        repeat (12) @(negedge clk);
        count_button = 1;
        repeat (24) @(negedge clk);
        if (dut.raw_count !== 7'd4 || dut.stable_count !== 7'd2)
            $fatal(1, "a held second press must increment each count once");

        seen = 0;
        repeat (8 * SCAN_CYCLES) begin
            @(negedge clk);
            selected = ~sel;
            if (!$onehot(selected) || seg[7] !== 1'b1)
                $fatal(1, "invalid digit select or lit decimal point: %h %h", sel, seg);
            if (selected == 8'h80 && seg !== 8'h99)
                $fatal(1, "leftmost demo digit should display 4");
            if (selected == 8'h40 && seg !== 8'ha4)
                $fatal(1, "second demo digit should display 2");
            seen = seen | selected;
        end
        if (seen !== 8'hff) $fatal(1, "scan missed a digit");

        run_button = 1;
        repeat (12) @(negedge clk);
        paused_count = dut.timer_count;
        repeat (128) @(negedge clk);
        if (dut.timer_count !== paused_count) $fatal(1, "timer did not pause");
        run_button = 0;
        repeat (12) @(negedge clk);
        run_button = 1;
        repeat (80) @(negedge clk);
        if (dut.timer_count === paused_count) $fatal(1, "timer did not resume");

        display_en = 0;
        @(negedge clk);
        if ({seg, sel} !== 16'hffff) $fatal(1, "display did not blank again");
        $display("PASS display_demo");
        $finish;
    end
endmodule
