`timescale 1ns / 1ps

module Chip_Top(
    input [15:0] SW, 
    input        BTNC,
    output [8:0] LED
    );

Adder_8bit_beh Adder_8bit_beh_i (
    .Cin(BTNC),
    .a(SW[7:0]),
    .b(SW[15:8]),
    .Cout(LED[8]),
    .sum(LED[7:0])
);

    
endmodule



