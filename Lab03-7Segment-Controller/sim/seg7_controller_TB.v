`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: seg7 controller TestBench
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Testbench for seg7_controller: digit toggling and all 16 characters
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module seg7_controller_TB;

    reg         clk, rst_n;
    reg         tick;
    reg  [19:0] digits;
    reg  [2:0]  number_of_digits;
    wire [7:0]  an;
    wire [6:0]  seg;

    seg7_controller seg7_controller_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .digits(digits),
        .number_of_digits(number_of_digits),
        .an(an),
        .seg(seg)
    );

    // 100MHz clock, starts at 0
    always #5 clk = ~clk;

    initial begin
        // Reset and initialization.
        // tick held at 1 -> the controller moves to the next digit every cycle (fast scan for simulation)
        clk              = 1'b0;
        rst_n            = 1'b0;
        tick             = 1'b1;
        digits           = 20'h0;
        number_of_digits = 3'd0;
        #20;
        rst_n = 1'b1;

        // Scenario 1: number with a leading zero - 4,3,2,1 lit, digit 4 blank
        digits           = 20'h01234;
        number_of_digits = 3'd4;
        #100;

        // Scenario 2: number with five digits - all 5 anodes toggle
        digits           = 20'h56789;
        number_of_digits = 3'd5;
        #100;

        // Scenario 3: hex letters - E, d, C, b, A
        digits           = 20'hABCDE;
        number_of_digits = 3'd5;
        #100;

        // Scenario 4: a single digit - only the rightmost anode is active
        // (scenarios 1-4 together cover all 16 characters 0-F)
        digits           = 20'h0000F;
        number_of_digits = 3'd1;
        #100;

        $finish;
    end
endmodule
