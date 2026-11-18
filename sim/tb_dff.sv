`timescale 1ns / 1ps

module tb_dff;
    logic clk = 0;
    logic clr = 0;
    logic en = 0;
    logic d = 0;
    wire q;

    dff dut (.clk(clk), .clr(clr), .en(en), .d(d), .q(q));
    always #5 clk = !clk;

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_dff.vcd");
            $dumpvars(0, tb_dff);
        end

        #1 clr = 1;
        #1;
        if (q !== 1'b0) $fatal(1, "clear must act before the clock edge");
        @(negedge clk);
        clr = 0;
        en = 1;
        d = 1;
        #1;
        if (q !== 1'b0) $fatal(1, "output changed before the write edge");
        @(negedge clk);
        if (q !== 1'b1) $fatal(1, "enabled edge did not latch D");
        en = 0;
        d = 0;
        @(negedge clk);
        if (q !== 1'b1) $fatal(1, "disabled edge overwrote Q");

        clr = 1;
        #1;
        if (q !== 1'b0) $fatal(1, "clear did not reset a stored 1");
        $display("PASS dff");
        $finish;
    end
endmodule
