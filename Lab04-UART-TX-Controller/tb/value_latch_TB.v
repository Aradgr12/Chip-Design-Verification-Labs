`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        value_latch_TB
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Testbench for value_latch: first latch, switch change without
//                a press, press during tx_busy, second latch, and reset.
//////////////////////////////////////////////////////////////////////////////////

module value_latch_TB;

    reg clk, rst_n;
    reg btn_pulse;
    reg tx_busy;
    reg [15:0] sw;
    wire [7:0] char_latched;
    wire [1:0] delay_latched;
    wire [1:0] size_latched;
    wire latched;
    wire valid_latched;
    
    value_latch value_latch_TB_DUT (
    
        .clk(clk),
        .rst_n(rst_n),
        .btn_pulse(btn_pulse),
        .tx_busy(tx_busy),
        .sw(sw),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .latched(latched),
        .valid_latched(valid_latched)
     );

    always #5 clk = ~clk;

     initial begin 
        clk = 1'b0;
        rst_n = 1'b0;
        btn_pulse = 1'b0;
        tx_busy = 1'b0;
        sw = 16'b0;
        #100;
        
        rst_n = 1'b1;
        #20;
        // Scenario 1: press while idle - expect char 41, delay code 10, size code 01 and a one-cycle latched pulse.
        sw = 16'h2241;
        btn_pulse = 1'b1; #10;
        btn_pulse = 1'b0;
        #100;
        
        // Scenario 2: switches change without a press - expect the latched values to stay unchanged.
        sw = 16'h6342; #30;
        #100;
        
        // Scenario 3: press while tx_busy is high - expect the press to be ignored.
        tx_busy = 1'b1;
        btn_pulse = 1'b1; #10;
        btn_pulse = 1'b0;
        #100;
        
        // Scenario 4: press after tx_busy drops - expect char 42, delay code 11, size code 11 to be latched.
        tx_busy = 1'b0;
        btn_pulse = 1'b1; #10;
        btn_pulse = 1'b0;
        #100;
        
        // Scenario 5: reset - expect all outputs cleared, including valid_latched.
        rst_n = 1'b0;
        #30;
        rst_n = 1'b1;
        #100;
        $finish;
     end    
endmodule
