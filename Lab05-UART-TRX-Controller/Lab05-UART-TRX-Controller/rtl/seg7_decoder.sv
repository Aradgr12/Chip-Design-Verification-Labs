`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   seg7_decoder
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   5-bit to 7-segment decoder (active low): hex digits 0-F and special
//                codes (dash).
//////////////////////////////////////////////////////////////////////////////////

module seg7_decoder
    import uart_pkg::SEG_DASH;    
(
    
    input logic [4:0] digit,
    output logic [6:0] seg
);
    
    always_comb begin
        seg = '1;
        unique case (digit)
            5'h0: seg = 7'b1000000;
            5'h1: seg = 7'b1111001;
            5'h2: seg = 7'b0100100;
            5'h3: seg = 7'b0110000;
            5'h4: seg = 7'b0011001;
            5'h5: seg = 7'b0010010;
            5'h6: seg = 7'b0000010;
            5'h7: seg = 7'b1111000;
            5'h8: seg = 7'b0000000;
            5'h9: seg = 7'b0011000;
            5'hA: seg = 7'b0001000;
            5'hB: seg = 7'b0000011;
            5'hC: seg = 7'b1000110;
            5'hD: seg = 7'b0100001;
            5'hE: seg = 7'b0000110;
            5'hF: seg = 7'b0001110;
            SEG_DASH: seg = 7'b0111111;   
            default: seg = '1;      
        endcase
     end
endmodule
