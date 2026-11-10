`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   tick_gen
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Refresh tick generator for the 7-segment controller (1-cycle tick
//                every MAX+1 clocks).
//////////////////////////////////////////////////////////////////////////////////

module tick_gen #(
    parameter int MAX = 24_999 // 100MHz / (500Hz x 8 digits) - 1
)(
    
    input logic clk, rst_n,
    output logic refresh_tick
    );
    
    localparam int TICK_W = $clog2(MAX + 1);
    logic [TICK_W-1:0] tick_cnt;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            tick_cnt <= '0;
        else if (tick_cnt == MAX)
            tick_cnt <= '0;
        else 
            tick_cnt <= tick_cnt + 1'b1;
    end
    
    assign refresh_tick = (tick_cnt == MAX);
    
endmodule
