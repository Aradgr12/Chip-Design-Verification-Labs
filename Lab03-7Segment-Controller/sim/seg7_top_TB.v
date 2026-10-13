`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: seg7 Top TestBench
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: End-to-end testbench for seg7_top with reduced timing parameters
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module seg7_top_TB;

    reg         clk, rst_n;
    reg  [15:0] sw;
    reg         btn_c, btn_d;
    wire [7:0]  an;
    wire [6:0]  seg;

    // 100MHz clock, starts at 0
    always #5 clk = ~clk;

    // Reduced parameters: tick every 2 cycles (20ns), hold = 5 ticks = 100ns
    seg7_top #(.TICK_MAX(1), .HOLD_TICKS(5)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .sw(sw),
        .btn_c(btn_c),
        .btn_d(btn_d),
        .an(an),
        .seg(seg)
    );

    initial begin
        // Reset and initialization
        clk   = 1'b0;
        rst_n = 1'b0;
        sw    = 16'd0;
        btn_c = 1'b0;
        btn_d = 1'b0;
        #20;
        rst_n = 1'b1;

        // Scenario 1: End-to-end decimal - sw = 1234, hold Center, display shows 1234
        sw    = 16'd1234;
        btn_c = 1'b1;
        #200;
        btn_c = 1'b0;
        #300;

        // Scenario 2: End-to-end hex - hold Down without changing sw, display shows 4D2
        btn_d = 1'd1;
        #200;
        btn_d = 1'd0;
        #300;

        // Scenario 3: Reset - display clears to a single 0 on the rightmost digit
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        #200;

        $finish;
    end
endmodule
