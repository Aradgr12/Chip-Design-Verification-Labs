`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        seg7_controller_TB
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Testbench for seg7_controller: blank display before the first
//                latch, two sets of displayed values, and blank again.
//////////////////////////////////////////////////////////////////////////////////

module seg7_controller_TB;

    reg clk, rst_n;
    reg refresh_tick;
    reg [7:0] char_latched;
    reg [1:0] delay_latched;
    reg [1:0] size_latched;
    reg [7:0] rows_cnt;
    reg valid_latched;
    wire [7:0] an;
    wire [7:0] seg;

    seg7_controller seg7_controller_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .refresh_tick(refresh_tick),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .rows_cnt(rows_cnt),
        .valid_latched(valid_latched),
        .an(an),
        .seg(seg)
    );

    always #5 clk = ~clk;

    // Fast refresh tick for simulation: 10ns pulse every 40ns
    always begin
        #30 refresh_tick = 1'b1;
        #10 refresh_tick = 1'b0;
    end

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        refresh_tick = 1'b0;
        char_latched = 8'h00;
        delay_latched = 2'd0;
        size_latched = 2'd0;
        rows_cnt = 8'h00;
        valid_latched = 1'b0;
        #20;
        rst_n = 1'b1;

        // Scenario 1: nothing latched yet - expect a blank display (an = FF).
        #400;

        // Scenario 2: char 41, delay 0.5, size 20, rows 20 - expect the digits to cycle with DP on an3.
        char_latched = 8'h41;
        delay_latched = 2'd1;
        size_latched = 2'd1;
        rows_cnt = 8'h20;
        valid_latched = 1'b1;
        #400;

        // Scenario 3: char 5A, delay 2.0, size FF, rows FF - expect all digits updated.
        char_latched = 8'h5A;
        delay_latched = 2'd3;
        size_latched = 2'd3;
        rows_cnt = 8'hFF;
        #400;

        // Scenario 4: valid_latched cleared - expect the display to go blank again.
        valid_latched = 1'b0;
        #400;

        $finish;
    end

endmodule
