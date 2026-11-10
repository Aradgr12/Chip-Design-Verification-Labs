`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        seg7_controller
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Scans the 8 seven-segment digits (one per refresh_tick, 500 Hz
//                full refresh). Builds T0-T3 (character, delay with decimal
//                point, size, rows) and blanks the display until the first
//                latch.
//////////////////////////////////////////////////////////////////////////////////

module seg7_controller(
    
    input wire clk, rst_n,
    input wire refresh_tick,
    input wire [7:0] char_latched,
    input wire [1:0] delay_latched,
    input wire [1:0] size_latched,
    input wire [7:0] rows_cnt,
    input wire valid_latched,
    output wire [7:0] an,
    output wire [7:0] seg
    );
    
    reg [2:0] digit_idx;   // active digit, advanced by refresh_tick
    wire [3:0] digit;
    wire [3:0] delay_hi, delay_low, size_hi, size_low;
    wire dp;
    wire [6:0] seg_raw;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_idx <= 3'd0;
        end else if (refresh_tick) begin
                digit_idx <= digit_idx + 3'd1;
        end            
    end   
                   
    // Active-low anodes; all digits off until the first press
    assign an = (valid_latched) ? ~(8'd1 << digit_idx) : 8'hFF;   
    
    // Delay digits in units of 100 ms: 0.0 / 0.5 / 1.0 / 2.0
    assign delay_hi = (delay_latched == 2'd0) ? 4'd0 :
                      (delay_latched == 2'd1) ? 4'd0 :
                      (delay_latched == 2'd2) ? 4'd1 : 4'd2;  
                      
    assign delay_low = (delay_latched == 2'd0) ? 4'd0 :
                       (delay_latched == 2'd1) ? 4'd5 :
                       (delay_latched == 2'd2) ? 4'd0 : 4'd0;
                       
    // Size digits in hex: 01 / 20 / 80 / FF
    assign size_hi = (size_latched == 2'd0) ? 4'd0 :
                     (size_latched == 2'd1) ? 4'd2 :
                     (size_latched == 2'd2) ? 4'd8 : 4'hF;            
                     
    assign size_low = (size_latched == 2'd0) ? 4'd1 :
                      (size_latched == 2'd1) ? 4'd0 :
                      (size_latched == 2'd2) ? 4'd0 : 4'hF;   
                      
    // Digit select
    assign digit = (digit_idx == 3'd0) ? char_latched [3:0] :
                   (digit_idx == 3'd1) ? char_latched [7:4] :
                   (digit_idx == 3'd2) ? delay_low :
                   (digit_idx == 3'd3) ? delay_hi :
                   (digit_idx == 3'd4) ? size_low :
                   (digit_idx == 3'd5) ? size_hi :
                   (digit_idx == 3'd6) ? rows_cnt [3:0] : rows_cnt [7:4];
                   
     assign dp = (digit_idx == 3) ? 1'b0 : 1'b1;   // decimal point (active low) on an3
                   
    seg7_decoder seg7_decoder_u (
        .digit(digit),
        .seg(seg_raw)
    );    
    
    assign seg = {dp, seg_raw};   // seg[7]=DP, seg[6:0]=CG..CA
                    
endmodule
