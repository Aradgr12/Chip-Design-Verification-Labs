`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: Value Latch
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Latches the switch value and the display mode on latch_en
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module value_latch(
    input  wire        clk, rst_n,      // 100MHz clock, active-low async reset
    input  wire [15:0] sw,              // live switch value
    input  wire        latch_en,        // one-cycle pulse from btn_hold_detector
    input  wire        mode_dec,        // requested display mode at the moment of latching

    output reg  [15:0] latch_value,     // value shown on the display
    output reg         disp_dec         // stored display mode: 1 = decimal, 0 = hex
    );

    // Registers with enable: the display follows the switches only when latch_en is high
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latch_value <= 16'd0;       // reset clears the stored value
            disp_dec    <= 1'd1;        // decimal after reset (value 0 looks the same in both modes)
        end else if (latch_en == 1'd1) begin
            latch_value <= sw;
            disp_dec    <= mode_dec;
        end
        // otherwise: both registers hold their value
    end

endmodule
