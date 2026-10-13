`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: digit_formatter TestBench
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Testbench for digit_formatter: edge values in decimal and hex
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module digit_formatter_TB;

    // Combinational DUT: no clock or reset needed
    reg  [15:0] latch_value;
    reg         disp_dec;
    wire [19:0] digits;                 // view in hex radix: each hex char = one display digit
    wire [2:0]  number_of_digits;

    digit_formatter digit_formatter_tb_DUT(
        .latch_value(latch_value),
        .disp_dec(disp_dec),
        .digits(digits),
        .number_of_digits(number_of_digits)
    );

    initial begin
        // Case 1: Zero in decimal - rightmost digit must still be lit (1 digit)
        latch_value = 16'd0;
        disp_dec    = 1'd1;
        #10;

        // Case 2: Single digit in decimal - 7 shows as 1 digit
        latch_value = 16'd7;
        disp_dec    = 1'd1;
        #10;

        // Case 3: Typical value in decimal - 1234 shows as 4 digits
        latch_value = 16'd1234;
        disp_dec    = 1'd1;
        #10;

        // Case 4: Max value in decimal - 65535 uses all 5 digits
        latch_value = 16'd65535;
        disp_dec    = 1'd1;
        #10;

        // Case 5: Same value in hex - 1234 shows as 4D2 (3 digits)
        latch_value = 16'd1234;
        disp_dec    = 1'd0;
        #10;

        // Case 6: Max value in hex - 65535 shows as FFFF (4 digits)
        latch_value = 16'd65535;
        disp_dec    = 1'd0;
        #10;

        // Case 7: Zero in hex - rightmost digit must still be lit (1 digit)
        latch_value = 16'd0;
        disp_dec    = 1'h0;
        #10;
        $finish;
    end
endmodule
