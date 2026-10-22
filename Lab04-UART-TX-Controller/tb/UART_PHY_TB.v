`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        UART_PHY_TB
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Testbench for UART_PHY with BIT_CYCLES = 10: single byte,
//                back-to-back bytes, tx_send during a frame, and reset in the
//                middle of a frame.
//////////////////////////////////////////////////////////////////////////////////

module UART_PHY_TB;

    reg clk, rst_n;
    reg [7:0] tx_byte;
    reg tx_send;
    wire uart_tx;
    wire PHY_finish;
    
    UART_PHY #(.BIT_CYCLES(10)) UART_PHY_TB_DUT(
    
        .clk(clk),
        .rst_n(rst_n),
        .tx_byte(tx_byte),
        .tx_send(tx_send),
        .uart_tx(uart_tx),
        .PHY_finish(PHY_finish)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        
        clk = 1'b0;
        rst_n = 1'b0;
        tx_send = 1'b0;
        tx_byte = 8'b0;
        #20;
        rst_n = 1'b1;
        #100;
        
        // Scenario 1: single frame of 0x0F - expect start bit, data LSB first, stop bit, then PHY_finish.
        tx_byte = 8'h0F;
        tx_send = 1'b1; #10;
        tx_send = 1'b0;
        #1100;
        
        // Scenario 2: 0x41 then 0x0F sent right after PHY_finish - expect back-to-back frames with no gap.
        tx_byte = 8'h41;
        tx_send = 1'b1; #10;
        tx_send = 1'b0;
        @(posedge PHY_finish);
        @(negedge clk);
        tx_byte = 8'h0F;
        tx_send = 1'b1; #10;
        tx_send = 1'b0;
        #1100;
        
        // Scenario 3: tx_send of 0xFF during a frame - expect it ignored and 0x41 to complete normally.
        tx_byte = 8'h41;
        tx_send = 1'b1; #10;
        tx_send = 1'b0;
        #400;
        tx_byte = 8'hFF;
        tx_send = 1'b1; #10;
        tx_send = 1'b0;
        #1100;
        
        // Scenario 4: reset in the middle of a frame - expect the line to return high, then a normal 0x41 frame.
        tx_byte = 8'h0F;
        tx_send = 1'b1; #10;
        tx_send = 1'b0;
        #400;
        rst_n = 1'b0; #30;
        rst_n = 1'b1; #30;
        tx_byte = 8'h41;
        tx_send = 1'b1; #10;
        tx_send = 1'b0;
        #1100;
        
        $finish;
    end          
endmodule
