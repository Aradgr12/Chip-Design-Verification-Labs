`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: digit_formatter
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Splits the latched value into 5 display digits (BCD or hex) and counts the digits to light
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module digit_formatter(
    input  wire [15:0] latch_value,     // binary value from value_latch
    input  wire        disp_dec,        // 1 = decimal, 0 = hex
    output wire [19:0] digits,          // 5 digits x 4 bits, digit 0 in bits [3:0]
    output wire [2:0]  number_of_digits // digits to light (1..5), blanks leading zeros
    );

    // Decimal digits (BCD), 65535 needs 5 digits
    wire [3:0] bcd4;
    wire [3:0] bcd3;
    wire [3:0] bcd2;
    wire [3:0] bcd1;
    wire [3:0] bcd0;

    // Hex digits, FFFF needs 4 digits
    wire [3:0] hex3;
    wire [3:0] hex2;
    wire [3:0] hex1;
    wire [3:0] hex0;

    // Binary to BCD with division by constants: digit_k = (value / 10^k) % 10
    assign bcd0 = latch_value % 10;
    assign bcd1 = (latch_value/10) % 10;
    assign bcd2 = (latch_value/100) % 10;
    assign bcd3 = (latch_value/1000) % 10;
    assign bcd4 = latch_value / 10000;  // at most 6, no modulo needed

    // Hex needs no conversion: each nibble is one digit
    assign hex0 = latch_value[3:0];
    assign hex1 = latch_value[7:4];
    assign hex2 = latch_value[11:8];
    assign hex3 = latch_value[15:12];

    // Select the digit set by display mode (hex uses only 4 digits, top digit forced to 0)
    assign digits = disp_dec ? {bcd4, bcd3, bcd2, bcd1, bcd0}
                             : {4'd0, hex3, hex2, hex1, hex0};

    // Priority chain: the leftmost non-zero digit sets the count.
    // Minimum is 1, so the value 0 still shows a single "0".
    assign number_of_digits = (digits[19:16] != 4'd0) ? 3'd5 :
                              (digits[15:12] != 4'd0) ? 3'd4 :
                              (digits[11:8]  != 4'd0) ? 3'd3 :
                              (digits[7:4]   != 4'd0) ? 3'd2 : 3'd1;
endmodule
