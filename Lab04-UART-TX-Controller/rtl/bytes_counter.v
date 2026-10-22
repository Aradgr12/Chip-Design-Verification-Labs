`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        bytes_counter
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Counts transmitted data bytes (17 bits) and converts the count
//                to completed rows by shifting right by log2(N). The row count
//                is shown on display T3 and is cleared on every new start.
//////////////////////////////////////////////////////////////////////////////////

module bytes_counter(

    input wire clk, rst_n,
    input wire data_byte_sent,
    input wire latched,
    input wire [1:0] size_latched,
    output wire [7:0] rows_cnt
    );
    
    reg [16:0] byte_cnt;   // up to 65,536 data chars (256x256)
    wire [3:0] shift_amt;
    wire [16:0] rows_full;
    
    // Shift amount = log2(N)
    assign shift_amt =  (size_latched == 2'd0) ? 4'd0 : 
                        (size_latched == 2'd1) ? 4'd5 :
                        (size_latched == 2'd2) ? 4'd7 : 4'd8;
                       
    assign rows_full = byte_cnt >> shift_amt;        
    assign rows_cnt = rows_full[7:0];   // 8 bits displayed; N=256 wraps to 00 by spec (lint waiver ASSIGN-6)
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_cnt <= 17'b0;
        end else if (latched) begin   // clear on a new start
            byte_cnt <= 17'b0;
        end else if (data_byte_sent) begin
            byte_cnt <= byte_cnt + 17'd1;
        end
    end
endmodule
