`timescale 1ns / 1ps

module tb_add_sub_mux;
    logic en, mux_sel;
    logic [3:0] input_a, input_b;
    wire [3:0] output_c;
    logic [3:0] expected;

    add_sub_mux dut (.en(en), .mux_sel(mux_sel), .input_a(input_a),
                     .input_b(input_b), .output_c(output_c));

    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("tb_add_sub_mux.vcd");
            $dumpvars(0, tb_add_sub_mux);
        end
        for (int i = 0; i < 1024; i++) begin
            {en, mux_sel, input_a, input_b} = i[9:0];
            expected = !en ? 4'hf : mux_sel ? input_a - input_b : input_a + input_b;
            #1;
            if (output_c !== expected)
                $fatal(1, "vector %h: expected %h, got %h", i, expected, output_c);
        end
        $display("PASS add_sub_mux");
        $finish;
    end
endmodule
