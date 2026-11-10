`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        TX_FSM_TB
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Testbench for TX_FSM with an emulated PHY: two single bytes, a
//                full 32x32 square with delay (data bytes counted and printed),
//                and reset in the middle of a square.
//////////////////////////////////////////////////////////////////////////////////

module TX_FSM_TB;

    reg clk, rst_n;
    reg [7:0] char_latched;
    reg [1:0] delay_latched;
    reg [1:0] size_latched;
    reg latched;
    reg PHY_finish = 1'b0;
    wire [7:0] tx_byte;
    wire tx_send, tx_busy;
    wire data_byte_sent;
    wire led_byte, led_done;
    reg [31:0] data_cnt;
    
    TX_FSM #(.DELAY_50MS(5), .DELAY_100MS(10), .DELAY_200MS(20)) TX_FSM_TB_DUT(
        
        .clk(clk),
        .rst_n(rst_n),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .latched(latched),
        .PHY_finish(PHY_finish),
        .tx_byte(tx_byte),
        .tx_send(tx_send),
        .tx_busy(tx_busy),
        .data_byte_sent(data_byte_sent),
        .led_byte(led_byte),
        .led_done(led_done)
     );
     
     always #5 clk = ~clk;
     
     // Count data bytes reported by the FSM
     always @(posedge data_byte_sent)
        data_cnt = data_cnt + 1;
        
     // Simple PHY model: answers each tx_send with a one-cycle PHY_finish a few cycles later
     integer phy_wait = -1;   // -1 = idle, otherwise cycles left

     always @(negedge clk) begin
         PHY_finish <= 1'b0;                  // default: one-cycle pulse
         if (tx_send)
             phy_wait <= 3;                   // new request: start counting
         else if (phy_wait > 0)
             phy_wait <= phy_wait - 1;        // still "sending"
         else if (phy_wait == 0) begin
             PHY_finish <= 1'b1;              // done
             phy_wait   <= -1;
         end
     end 
        
     initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        char_latched = 8'b0;
        delay_latched = 2'b0;
        size_latched = 2'b0;
        latched = 1'b0;
        data_cnt = 32'b0;
        #100;
        
        @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        // Scenario 1: single char 'A' (size 1, no delay) - expect one data byte, no space / CR / LF, led_done set.
        char_latched = 8'h41;
        delay_latched = 2'd0;
        size_latched = 2'd0;
        latched = 1'b1; #10;
        latched = 1'b0;
        @(negedge tx_busy);
        #100;
        
        // Scenario 2: second single char 'B' - expect counters restarted, led_byte and led_done cleared then updated.
        @(negedge clk);
        char_latched = 8'h42;
        delay_latched = 2'd0;
        size_latched = 2'd0;
        latched = 1'b1; #10;
        latched = 1'b0;
        @(negedge tx_busy);
        #100;
        
        // Scenario 3: 32x32 square of 'B' with 50 ms delay (5 cycles) - expect 1024 data bytes, spaces and CR/LF.
        @(negedge clk);
        data_cnt = 32'b0;
        @(negedge clk);
        char_latched = 8'h42;
        delay_latched = 2'd1;
        size_latched = 2'd1;
        latched = 1'b1; #10;
        latched = 1'b0;
        @(negedge tx_busy);
        $display("data bytes send = %0d", data_cnt);
        #100;
        
        // Scenario 4: reset during a 32x32 transmission - expect return to IDLE with all outputs cleared.
        @(negedge clk);
        char_latched = 8'h42;
        delay_latched = 2'd1;
        size_latched = 2'd1;
        latched = 1'b1; #10;
        latched = 1'b0; #80000;
        rst_n = 1'b0; #20;
        rst_n = 1'b1;
        #100;
        
        $finish;
    end
endmodule
