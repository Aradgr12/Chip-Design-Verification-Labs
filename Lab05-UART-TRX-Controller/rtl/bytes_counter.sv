`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   bytes_counter
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Counts transmitted data bytes and converts them to transmitted rows
//                for the display (8-bit, wraps at 256).
//////////////////////////////////////////////////////////////////////////////////

module bytes_counter(

    input logic clk, rst_n,
    input logic data_byte_sent,
    input logic latched,
    input logic [1:0] size_latched,
    output logic [7:0] rows_cnt
    );
    
    // Largest square: 256x256 bytes
    localparam int MAX_BYTES = 256 * 256;
    localparam int CNT_W     = $clog2(MAX_BYTES + 1);   // = 17
    
    logic [CNT_W-1:0] byte_cnt;
    logic [3:0]       shift_amt;
    logic [CNT_W-1:0] rows_full;
    
    assign shift_amt =  (size_latched == 2'd0) ? 4'd0 : 
                        (size_latched == 2'd1) ? 4'd5 :
                        (size_latched == 2'd2) ? 4'd7 : 4'd8;
                       
    assign rows_full = byte_cnt >> shift_amt;        
    assign rows_cnt = rows_full[7:0];             
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_cnt <= '0;
        end else if (latched) begin
            byte_cnt <= '0;
        end else if (data_byte_sent) begin
            byte_cnt <= byte_cnt + 1'b1;
        end
    end
endmodule
