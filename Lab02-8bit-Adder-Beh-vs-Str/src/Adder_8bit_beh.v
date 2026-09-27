`timescale 1ns / 1ps

module Adder_8bit_beh(
    input wire [7:0] a,b,  
    input wire Cin,      
    output wire [7:0] sum,
    output wire Cout
    );
    
    assign {Cout, sum} = a + b + Cin;
    
endmodule




        