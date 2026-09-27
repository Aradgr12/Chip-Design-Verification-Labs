`timescale 1ns / 1ps

module Adder_8bit_TB;
    reg [7:0] a, b;
    reg       Cin;
    
    wire [7:0] sum_beh, sum_str;
    wire       Cout_beh, Cout_str;
    
Adder_8bit_beh dut_beh (
    .a(a),
    .b(b),
    .Cin(Cin),    
    .sum(sum_beh),
    .Cout(Cout_beh)
);
Adder_8bit_str dut_str (
    .a(a),
    .b(b),
    .Cin(Cin),    
    .sum(sum_str),
    .Cout(Cout_str) 
);  
initial begin 
    #10;
    a=90; b=10; Cin=0; #10;
    a=150; b=150; Cin=0; #10;
    a=200; b=54; Cin=1; #10;
    a=255; b=255; Cin=1; #10;    
    $finish;
end
    
initial begin
    $monitor ("Time:%t, | a=%d, | b=%d, | Cin=%d, | sum_beh=%d, | Cout_beh=%d, | sum_str=%d, | Cout_str=%d", $time,  a, b, Cin, sum_beh, Cout_beh, sum_str,
    Cout_str);
end    
endmodule



