`timescale 1ns / 1ps

module tb_uart_beacon;
    localparam integer BIT_CYCLES = 16;
    localparam integer GAP_CYCLES = 37;
    localparam [95:0] MESSAGE = {"HELLO FPGA", 8'h0d, 8'h0a};
    logic clk = 0;
    logic rst = 0;
    wire tx;
    logic [7:0] received;
    time last_stop_sample;

    uart_beacon #(.CLK_HZ(16_000), .BAUD_RATE(1000), .GAP_CYCLES(GAP_CYCLES)) dut (
        .clk(clk), .rst(rst), .uart_tx(tx)
    );
    uart_test_link #(.BIT_CYCLES(BIT_CYCLES)) link (.clk(clk), .tx(tx), .rx());
    always #5 clk = !clk;

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_uart_beacon.vcd");
            $dumpvars(0, tb_uart_beacon);
        end

        #1 rst = 1;
        repeat (3) @(negedge clk);
        rst = 0;
        for (int frame = 0; frame < 2; frame++) begin
            for (int i = 0; i < 12; i++) begin
                link.receive(received);
                if (received !== MESSAGE[8*(11-i) +: 8])
                    $fatal(1, "beacon frame %0d byte %0d was %h", frame, i, received);
                if (frame == 1 && i == 0 &&
                    $time - last_stop_sample < (GAP_CYCLES + 10 * BIT_CYCLES) * 10)
                    $fatal(1, "beacon's inter-message gap was too short");
                if (i == 11)
                    last_stop_sample = $time;
            end
        end
        $display("PASS uart_beacon");
        $finish;
    end

    initial begin
        #60_000;
        $fatal(1, "beacon test timed out");
    end
endmodule
