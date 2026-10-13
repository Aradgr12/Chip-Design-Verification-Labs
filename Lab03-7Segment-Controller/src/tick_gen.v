`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: tick_gen
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Generates a one-cycle enable pulse (tick) every MAX+1 clock cycles
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tick_gen #(
    parameter MAX = 249999              // 100MHz / 250,000 = 400Hz tick (counts 0..249,999)
)(
    input  wire clk, rst_n,             // 100MHz system clock, active-low async reset
    output wire tick                    // one-cycle pulse, used as an enable (not as a clock)
    );

    // 18-bit counter: 2^18 = 262,144 > 249,999
    reg [17:0] tick_cnt;

    // Free-running counter: 0 -> MAX, then wraps back to 0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tick_cnt <= 18'd0;
        else if (tick_cnt == MAX)
            tick_cnt <= 18'd0;          // wrap after MAX+1 cycles (no off-by-one)
        else
            tick_cnt <= tick_cnt + 1'd1;
    end

    // Pulse is high for exactly one clock cycle per period
    assign tick = (tick_cnt == MAX);

endmodule
