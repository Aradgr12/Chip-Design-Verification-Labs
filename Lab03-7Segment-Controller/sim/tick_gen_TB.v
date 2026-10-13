`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: tick_gen TB
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Testbench for tick_gen with MAX reduced to 3
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tick_gen_TB;

    reg  clk;
    reg  rst_n;
    wire tick;

    // 100MHz clock: 10ns period. Starts at 0 so edges fall between stimulus changes.
    always #5 clk = ~clk;

    // MAX reduced to 3 -> expected: one-cycle tick every MAX+1 = 4 cycles (40ns)
    tick_gen #(.MAX(3)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick)
    );

    initial begin
        clk   = 1'd0;
        rst_n = 1'd0;                   // hold reset for 2 cycles
        #20;
        rst_n = 1'd1;                   // release reset, counter starts
        #200;                           // ~20 cycles -> 5 tick pulses
        $finish;
    end

endmodule
