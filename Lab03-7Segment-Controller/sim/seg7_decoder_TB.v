`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: seg7_decoder TestBench
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Testbench for seg7_decoder: all 16 input values
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module seg7_decoder_TB;
    reg [3:0] digit;
    wire [6:0] seg;
    
    seg7_decoder seg7_decoder_TB_DUT(
        .digit(digit),
       .seg(seg)
    );
    
    // Combinational DUT: apply all 16 values, 10ns apart, and print each result
    // (expected values are written independently from the segment drawings)
    initial begin
        digit = 4'd0;
        #10;
        $display("digit=%0d, seg=%b, (expected = 1000000)", digit, seg);
        
         digit = 4'd1;
        #10;
        $display("digit=%0d, seg=%b, (expected = 1111001)", digit, seg);
        
        digit = 4'd2;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0100100)", digit, seg);
        
        digit = 4'd3;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0110000)", digit, seg);
        
        digit = 4'd4;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0011001)", digit, seg);
        
        digit = 4'd5;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0010010)", digit, seg);
        
        digit = 4'd6;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0000010)", digit, seg);
        
        digit = 4'd7;
        #10;
        $display("digit=%0d, seg=%b, (expected = 1111000)", digit, seg);
        
        digit = 4'd8;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0000000)", digit, seg);
        
        digit = 4'd9;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0011000)", digit, seg);
        
        digit = 4'hA;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0001000)", digit, seg);
        
        digit = 4'hB;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0000011)", digit, seg);
        
        digit = 4'hC;
        #10;
        $display("digit=%0d, seg=%b, (expected = 1000110)", digit, seg);
        
        digit = 4'hD;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0100001)", digit, seg);
        
        digit = 4'hE;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0000110)", digit, seg);
        
        digit = 4'hF;
        #10;
        $display("digit=%0d, seg=%b, (expected = 0001110)", digit, seg);
        
        $finish;
    end
endmodule
