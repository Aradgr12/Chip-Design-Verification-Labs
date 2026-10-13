`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: seg7 Top
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Top level: connects all blocks and maps to the Nexys A7 board pins
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module seg7_top #(
    parameter TICK_MAX   = 249999,      // real HW values; testbenches override them
    parameter HOLD_TICKS = 400
)(
    input  wire        clk, rst_n,      // 100MHz clock (E3), CPU_RESETN (active low)
    input  wire [15:0] sw,              // SW[15:0]
    input  wire        btn_c, btn_d,    // BTNC = decimal, BTND = hex
    output wire [7:0]  an,              // AN[7:0], active low
    output wire [6:0]  seg              // CA..CG, active low
    );

    // Internal connections between the blocks
    wire        tick;                   // 400Hz enable pulse
    wire        latch_en;               // latch pulse after a 1 sec hold
    wire        mode_dec;               // requested mode at latch time
    wire        disp_dec;               // stored display mode
    wire [15:0] latch_value;            // stored switch value
    wire [19:0] digits;                 // 5 display digits
    wire [2:0]  number_of_digits;       // digits to light

    // 400Hz enable for both the hold counter and the digit scan (single clock domain)
    tick_gen #(.MAX(TICK_MAX)) tick_gen_u (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick)
    );

    // Button sync, 1 sec hold detection, single latch per press
    btn_hold_detector #(.HOLD_TICKS(HOLD_TICKS)) btn_hold_detector_u (
        .clk(clk),
        .rst_n(rst_n),
        .btn_c(btn_c),
        .btn_d(btn_d),
        .tick(tick),
        .latch_en(latch_en),
        .mode_dec(mode_dec)
    );

    // Stores the switch value and the display mode
    value_latch value_latch_u (
        .clk(clk),
        .rst_n(rst_n),
        .sw(sw),
        .latch_en(latch_en),
        .mode_dec(mode_dec),
        .latch_value(latch_value),
        .disp_dec(disp_dec)
    );

    // Binary to BCD / hex digits and leading-zero count (combinational)
    digit_formatter digit_formatter_u (
        .latch_value(latch_value),
        .disp_dec(disp_dec),
        .digits(digits),
        .number_of_digits(number_of_digits)
    );

    // Digit scanning, anodes and 7-segment decoding
    seg7_controller seg7_controller_u (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .digits(digits),
        .number_of_digits(number_of_digits),
        .an(an),
        .seg(seg)
    );
endmodule
