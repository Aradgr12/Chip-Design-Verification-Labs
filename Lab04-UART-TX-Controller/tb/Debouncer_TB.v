`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        Debouncer_TB
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Self-contained testbench for Debouncer with BTN_CYCLES = 10:
//                clean press, long hold, glitch, bouncing press and release,
//                double press and reset while held.
//////////////////////////////////////////////////////////////////////////////////

module Debouncer_TB;

    reg clk, rst_n;
    reg btn_c;
    wire btn_pulse;

    always #5 clk = ~clk;   // 100 MHz clock

    Debouncer #(.BTN_CYCLES(10)) Debouncer_TB_DUT(   // short debounce for simulation
        
        .clk(clk),
        .rst_n(rst_n),
        .btn_c(btn_c),
        .btn_pulse(btn_pulse)
    );
    
    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        btn_c = 1'b0;
        
        #20;
        rst_n = 1'b1;
        // Scenario 1: clean press longer than BTN_CYCLES - expect one btn_pulse.
        btn_c = 1'b1; #120;
        btn_c = 1'b0; 
        #200;
        // Scenario 2: long hold (360 ns) - expect a single pulse, no repeats while held.
        btn_c = 1'b1; #360;
        btn_c = 1'b0; #20;
        #200;
        // Scenario 3: short glitch (30 ns) shorter than BTN_CYCLES - expect no pulse.
        btn_c = 1'b1; #30;
        btn_c = 1'b0; 
        #200;
        // Scenario 4: bouncing press that settles high - expect one pulse once stable.
        btn_c = 1'b1; #30;
        btn_c = 1'b0; #30;
        btn_c = 1'b1; #30;
        btn_c = 1'b0; #30;
        btn_c = 1'b1; #30;
        btn_c = 1'b0; #30;
        btn_c = 1'b1; #120;
        btn_c = 1'b0;
        #200;
        // Scenario 5: stable press followed by a bouncing release - expect one pulse only.
        btn_c = 1'b1; #120;
        btn_c = 1'b0; #30;
        btn_c = 1'b1; #30;
        btn_c = 1'b0; #30;
        btn_c = 1'b1; #30;
        btn_c = 1'b0; 
        #200;
        // Scenario 6: two separate presses - expect two pulses.
        btn_c = 1'b1; #120;
        btn_c = 1'b0; #100;
        btn_c = 1'b1; #120;
        btn_c = 1'b0;
        #200;
        // Scenario 7: reset while held - expect no pulse in reset, then a new pulse since the button is still high.
        btn_c = 1'b1; #80;
        rst_n = 1'b0; #120;
        rst_n = 1'b1; #120;
        #200;
        $finish;
     end
        
endmodule
