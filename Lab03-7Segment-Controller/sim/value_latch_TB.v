`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: Value Latch TestBench
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Testbench for value_latch: latch, hold and reset behavior
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module value_latch_TB;

    reg         clk, rst_n;
    reg  [15:0] sw;
    reg         latch_en, mode_dec;

    wire [15:0] latch_value;
    wire        disp_dec;

    // 100MHz clock, starts at 0 (avoids races with stimulus at multiples of 10ns)
    always #5 clk = ~clk;

    value_latch value_latch_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .sw(sw),
        .latch_en(latch_en),
        .mode_dec(mode_dec),
        .latch_value(latch_value),
        .disp_dec(disp_dec)
    );

    initial begin
        // Scenario 1: Reset - outputs initialize to latch_value = 0, disp_dec = 1
        clk      = 1'd0;
        rst_n    = 1'd0;
        sw       = 16'd0;
        mode_dec = 1'd0;
        latch_en = 1'd0;
        #20;
        rst_n = 1'd1;
        #100;

        // Scenario 2: Latch in decimal mode - sw = 1234 is captured with mode_dec = 1
        sw       = 16'd1234;
        mode_dec = 1'd1;
        latch_en = 1'd1;                // one-cycle latch pulse
        #10;
        latch_en = 1'd0;
        #100;

        // Scenario 3: Switches change without latch_en - latch_value must hold 1234
        sw = 16'd5678;
        #100;

        // Scenario 4: Latch in hex mode - sw = 5678 is captured with mode_dec = 0
        mode_dec = 1'h0;
        latch_en = 1'd1;
        #10;
        latch_en = 1'd0;
        #100;

        // Scenario 5: Reset mid-operation - outputs return to reset values immediately (async reset)
        rst_n = 1'd0;
        #20;
        rst_n = 1'd1;
        #50;
        $finish;
    end
endmodule
