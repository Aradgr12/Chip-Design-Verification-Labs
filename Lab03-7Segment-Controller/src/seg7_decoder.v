`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: seg7_decoder
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Converts a 4-bit digit (0-F) into the 7 active-low cathode signals
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seg7_decoder(
    input  wire [3:0] digit,            // digit value 0..F
    output reg  [6:0] seg               // seg[0] = CA ... seg[6] = CG, active low
    );

    // Bit order in the patterns below: {G, F, E, D, C, B, A}, '0' = segment on
    always @(*) begin
        seg = 7'b1111111;               // default: all segments off (prevents latch inference)
        case (digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0011000;     // 9 drawn without the bottom segment D
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;     // lower-case b (upper-case B looks like 8)
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;     // lower-case d (upper-case D looks like 0)
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
