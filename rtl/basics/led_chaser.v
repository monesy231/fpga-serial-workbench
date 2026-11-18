`timescale 1ns / 1ps
`default_nettype none

module led_chaser #(
    parameter integer INTERVAL_0 = 100_000,
    parameter integer INTERVAL_1 = 1_000_000,
    parameter integer INTERVAL_2 = 5_000_000,
    parameter integer INTERVAL_3 = 20_000_000
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       button,
    input  wire [1:0] freq_set,
    input  wire       dir_set,
    output reg  [7:0] led
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] button_sync;
    (* ASYNC_REG = "TRUE" *) reg [2:0] controls_meta, controls_sync;
    reg button_prev;
    wire press = button_sync[1] && !button_prev;
    wire [1:0] speed = controls_sync[2:1];
    wire direction = controls_sync[0];

    reg running;
    reg [1:0] previous_speed;
    reg [31:0] elapsed;
    reg [31:0] interval;

    always @* begin
        case (speed)
            2'b01: interval = INTERVAL_1;
            2'b10: interval = INTERVAL_2;
            2'b11: interval = INTERVAL_3;
            default: interval = INTERVAL_0;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            button_sync <= 2'b00;
            button_prev <= 1'b0;
            controls_meta <= 3'b000;
            controls_sync <= 3'b000;
        end else begin
            button_sync <= {button_sync[0], button};
            button_prev <= button_sync[1];
            controls_meta <= {freq_set, dir_set};
            controls_sync <= controls_meta;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            running <= 1'b0;
            previous_speed <= 2'b00;
            elapsed <= 0;
            led <= 8'h01;
        end else begin
            previous_speed <= speed;
            if (press)
                running <= !running;

            // Start a full interval after a speed change or a new run.
            if (press || !running || speed != previous_speed) begin
                elapsed <= 0;
            end else if (elapsed == interval - 1) begin
                elapsed <= 0;
                if (direction)
                    led <= {led[6:0], led[7]};
                else
                    led <= {led[0], led[7:1]};
            end else begin
                elapsed <= elapsed + 1'b1;
            end
        end
    end
endmodule

`default_nettype wire
