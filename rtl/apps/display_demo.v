`timescale 1ns / 1ps
`default_nettype none

module display_demo #(
    parameter integer DEBOUNCE_CYCLES = 2_000_000,
    parameter integer SCAN_CYCLES = 12_500,
    parameter integer TICK_CYCLES = 10_000_000,
    parameter [7:0] DEMO_NUMBER = 8'd42
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       run_button,
    input  wire       count_button,
    input  wire       display_en,
    output wire [7:0] seg,
    output wire [7:0] sel
);
    localparam integer TICK_BITS = TICK_CYCLES > 1 ? $clog2(TICK_CYCLES) : 1;
    wire run_press;
    wire count_raw, count_press;
    reg count_raw_prev;
    reg timer_running;
    reg [6:0] raw_count, stable_count;
    reg [5:0] timer_count;
    reg [TICK_BITS-1:0] tick_count;

    button_debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) run_filter (
        .clk(clk), .rst(rst), .button(run_button),
        .raw_level(), .pressed(run_press)
    );

    button_debounce #(.STABLE_CYCLES(DEBOUNCE_CYCLES)) count_filter (
        .clk(clk), .rst(rst), .button(count_button),
        .raw_level(count_raw), .pressed(count_press)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_raw_prev <= 1'b0;
            raw_count <= 0;
            stable_count <= 0;
            timer_running <= 1'b1;
            timer_count <= 0;
            tick_count <= 0;
        end else begin
            count_raw_prev <= count_raw;
            if (count_raw && !count_raw_prev)
                raw_count <= raw_count == 7'd99 ? 7'd0 : raw_count + 1'b1;
            if (count_press)
                stable_count <= stable_count == 7'd99 ? 7'd0 : stable_count + 1'b1;

            if (run_press)
                timer_running <= !timer_running;
            if (tick_count == TICK_CYCLES - 1) begin
                tick_count <= 0;
                if (timer_running)
                    timer_count <= timer_count == 6'd30 ? 6'd0 : timer_count + 1'b1;
            end else begin
                tick_count <= tick_count + 1'b1;
            end
        end
    end

    wire [3:0] demo_tens   = (DEMO_NUMBER / 10) % 10;
    wire [3:0] demo_ones   = DEMO_NUMBER % 10;
    wire [3:0] raw_tens    = raw_count / 10;
    wire [3:0] raw_ones    = raw_count % 10;
    wire [3:0] stable_tens = stable_count / 10;
    wire [3:0] stable_ones = stable_count % 10;
    wire [3:0] timer_tens  = timer_count / 10;
    wire [3:0] timer_ones  = timer_count % 10;

    sevenseg_scan #(.SCAN_CYCLES(SCAN_CYCLES)) scan (
        .clk(clk), .rst(rst),
        .digits({demo_tens, demo_ones, raw_tens, raw_ones,
                 stable_tens, stable_ones, timer_tens, timer_ones}),
        .visible({8{display_en}}), .seg(seg), .sel(sel)
    );
endmodule

`default_nettype wire
