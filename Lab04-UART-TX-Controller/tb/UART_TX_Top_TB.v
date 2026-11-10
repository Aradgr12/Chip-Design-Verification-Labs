`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        UART_TX_Top_TB
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   System testbench for UART_TX_TOP with shortened timing (100 ns
//                button press): single byte, 32x32 square, press during
//                transmission, and reset during transmission.
//////////////////////////////////////////////////////////////////////////////////

module UART_TX_Top_TB;

    reg clk, rst_n;
    reg btn_c;
    reg [15:0] sw;
    wire uart_tx;
    wire led_byte, led_done;
    wire [7:0] an;
    wire [7:0] seg;
    
    always #5 clk = ~clk;
    
    UART_TX_TOP #(.BTN_CYCLES(5), .BIT_CYCLES(10), .DELAY_50MS(5), .DELAY_100MS(10),   // short timing parameters for simulation
                  .DELAY_200MS(20),.REFRESH_MAX(3))
                   UART_TX_TOP_DUT(
        
        .clk(clk),
        .rst_n(rst_n),
        .btn_c(btn_c),
        .sw(sw),
        .uart_tx(uart_tx),
        .led_byte(led_byte),
        .led_done(led_done),
        .an(an),
        .seg(seg)
    );
    
    initial begin
    
        // Reset and idle preparation
        clk = 1'b0;
        rst_n = 1'b0;
        btn_c = 1'b0;
        sw = 16'b0;#20;
        #100;
        
        rst_n = 1'b1;
        #100;
        @(negedge clk);
        // Scenario 1: single char 'A' (size 1, no delay) - expect one UART frame and led_done set.
        sw = 16'h0041;
        btn_c = 1'b1; #100;
        btn_c = 1'b0;
        @(posedge led_done);
        #1000;
        
        @(negedge clk);
        // Scenario 2: 32x32 square of 'A' with 50 ms delay - expect 32 rows separated by spaces and CR/LF.
        sw = 16'h2141;
        btn_c = 1'b1; #100;
        btn_c = 1'b0;
        #50000;
        // Scenario 3: new press with other switches during transmission - expect it to be ignored.
        sw = 16'h6342;
        btn_c = 1'b1; #100;
        btn_c = 1'b0;
        @(posedge led_done);
        #1000;
        
        @(negedge clk);
        // Scenario 4: reset during a 32x32 transmission - expect it to stop, display blank and LEDs off.
        sw = 16'h2141;
        btn_c = 1'b1; #100;
        btn_c = 1'b0;
        #1000000;
        rst_n = 1'b0; #30;
        rst_n = 1'b1;
        #1000;
        
        $finish;
    end      
endmodule
