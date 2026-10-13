`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: btn_hold_detector TestBench
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Testbench for btn_hold_detector: hold duration reduced to 100ns
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module btn_hold_detector_TB;

    reg  clk, rst_n;
    reg  btn_c, btn_d;
    wire tick;
    wire latch_en, mode_dec;

    // 100MHz clock, starts at 0
    always #5 clk = ~clk;

    // Real tick source with MAX = 4 -> one tick every 5 cycles (50ns)
    tick_gen #(.MAX(4)) u_tick (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick)
    );

    // HOLD_TICKS = 2 -> "1 sec" hold reduced to 2 x 50ns = 100ns in simulation
    btn_hold_detector #(.HOLD_TICKS(2)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_c(btn_c),
        .btn_d(btn_d),
        .tick(tick),
        .latch_en(latch_en),
        .mode_dec(mode_dec)
    );

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        btn_c = 1'b0;
        btn_d = 1'b0;

        // Reset
        #20;
        rst_n = 1'b1;
        #30;

        // Scenario 1: normal hold on Center -> one latch_en pulse, mode_dec = 1
        btn_c = 1'b1;
        #200;
        btn_c = 1'b0;
        #200;

        // Scenario 2: normal hold on Down -> one latch_en pulse, mode_dec = 0
        btn_d = 1'b1;
        #200;
        btn_d = 1'b0;
        #200;

        // Scenario 3: short press (shorter than one tick period) -> no latch_en
        btn_c = 1'b1;
        #30;
        btn_c = 1'b0;
        #200;

        // Scenario 4: both buttons together, Center released first
        //             -> one pulse with mode_dec = 1, FSM stays LOCKED while Down is still held
        btn_c = 1'b1;
        btn_d = 1'b1;
        #200;
        btn_c = 1'b0;
        #100;
        btn_d = 1'b0;
        #200;

        // Scenario 5: long hold (27us > 512 ticks) -> cnt wraps past 511 and hits HOLD_TICKS again,
        //             but no second latch_en because the FSM is LOCKED
        btn_c = 1'b1;
        #27000;
        btn_c = 1'b0;
        #200;

        #100;
        $finish;
    end
endmodule
