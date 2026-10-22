`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        tick_gen
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Generates a one-cycle refresh_tick every MAX+1 clocks (4 kHz
//                at 100 MHz), used as an enable for the 7-segment scan. A
//                pulse, not a derived clock, so the whole design stays in one
//                clock domain.
//////////////////////////////////////////////////////////////////////////////////

module tick_gen #(
    parameter MAX = 24999
)(
    
    input wire clk, rst_n,
    output wire refresh_tick
    );
    
    reg [14:0] tick_cnt;   // 15 bits cover MAX = 24999
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            tick_cnt <= 15'd0;
        else if (tick_cnt == MAX)
            tick_cnt <= 15'd0;
        else 
            tick_cnt <= tick_cnt + 15'd1;
    end
    
    assign refresh_tick = (tick_cnt == MAX);   // one-cycle enable pulse
    
endmodule
