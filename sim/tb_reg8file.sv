`timescale 1ns / 1ps

module tb_reg8file;
    logic clk = 0;
    logic clr = 0;
    logic en = 0;
    logic [7:0] d = 0;
    logic [2:0] wsel = 0, rsel = 0;
    wire [7:0] q;

    reg8file dut (.clk(clk), .clr(clr), .en(en), .d(d),
                  .wsel(wsel), .rsel(rsel), .q(q));
    always #5 clk = !clk;

    task automatic check_clear;
        for (int i = 0; i < 8; i++) begin
            rsel = i[2:0];
            #1;
            if (q !== 8'h00) $fatal(1, "register %0d did not clear", i);
        end
    endtask

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_reg8file.vcd");
            $dumpvars(0, tb_reg8file);
        end

        #1 clr = 1;
        check_clear();
        @(negedge clk);
        clr = 0;
        en = 1;
        for (int i = 0; i < 8; i++) begin
            wsel = i[2:0];
            d = 8'h90 + i[7:0];
            @(negedge clk);
        end
        en = 0;
        wsel = 7;
        d = 8'hff;
        @(negedge clk);
        for (int i = 7; i >= 0; i--) begin
            rsel = i[2:0];
            #1;
            if (q !== 8'h90 + i[7:0])
                $fatal(1, "asynchronous read of register %0d gave %h", i, q);
        end

        @(negedge clk);
        clr = 1;
        #1;
        if (q !== 8'h00) $fatal(1, "write contents survived async clear");
        check_clear();
        $display("PASS reg8file");
        $finish;
    end
endmodule
