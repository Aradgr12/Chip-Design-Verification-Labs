`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: seg7 controller
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Time-multiplexes the 5 digits on the shared cathodes and drives the anodes
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module seg7_controller(
    input  wire        clk, rst_n,      // 100MHz clock, active-low async reset
    input  wire        tick,            // 400Hz enable: move to the next digit
    input  wire [19:0] digits,          // 5 digits x 4 bits from digit_formatter
    input  wire [2:0]  number_of_digits,// digits to light (leading-zero blanking)
    output wire [7:0]  an,              // anodes, active low
    output wire [6:0]  seg              // cathodes, active low
    );

    reg  [2:0] digit_idx;               // which digit is lit now (0..4)
    wire [3:0] digit;                   // value of the current digit

    // Digit counter: scans all 5 digits so every digit gets the same on-time (equal brightness).
    // 400Hz per digit / 5 digits = 80Hz refresh per digit -> no visible flicker.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_idx <= 3'd0;
        end else if (tick) begin
            if (digit_idx == 3'd4)
                digit_idx <= 3'd0;
            else
                digit_idx <= digit_idx + 3'd1;
        end
    end

    // Select the 4 bits of the current digit
    assign digit = (digit_idx == 3'd0) ? digits[3:0]   :
                   (digit_idx == 3'd1) ? digits[7:4]   :
                   (digit_idx == 3'd2) ? digits[11:8]  :
                   (digit_idx == 3'd3) ? digits[15:12] : digits[19:16];

    // One-hot, active-low anode. Digits beyond number_of_digits stay off (all ones).
    // an[7:5] are always '1' because digit_idx never exceeds 4.
    assign an = (digit_idx < number_of_digits) ? ~(8'd1 << digit_idx) : 8'hFF;

    // Anode and cathodes both depend on digit_idx, so they always change together
    seg7_decoder seg7_decoder_u (
        .digit(digit),
        .seg(seg)
    );

endmodule
