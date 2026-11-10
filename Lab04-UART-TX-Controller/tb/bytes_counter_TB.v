`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        bytes_counter_TB
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Testbench for bytes_counter: sends N*N data-byte pulses for
//                each square size and prints the resulting row count.
//////////////////////////////////////////////////////////////////////////////////

module bytes_counter_TB;

    reg clk, rst_n;
    reg data_byte_sent;
    reg latched;
    reg [1:0] size_latched;
    wire [7:0] rows_cnt;

    bytes_counter bytes_counter_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .data_byte_sent(data_byte_sent),
        .latched(latched),
        .size_latched(size_latched),
        .rows_cnt(rows_cnt)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        data_byte_sent = 1'b0;
        latched = 1'b0;
        size_latched = 2'd0;
        #20;
        rst_n = 1'b1;
        #100;

        // Scenario 1: size 1, one data byte - expect rows_cnt = 01.
        size_latched = 2'd0;
        latched = 1'b1; #10;
        latched = 1'b0; #10;
        repeat (1) begin
            data_byte_sent = 1'b1; #10;
            data_byte_sent = 1'b0; #10;
        end
        #100;
        $display("size 0: rows_cnt = %h (expected 01)", rows_cnt);

        // Scenario 2: size 32, 1024 data bytes - expect rows_cnt = 20 (hex).
        size_latched = 2'd1;
        latched = 1'b1; #10;
        latched = 1'b0; #10;
        repeat (1024) begin
            data_byte_sent = 1'b1; #10;
            data_byte_sent = 1'b0; #10;
        end
        #100;
        $display("size 1: rows_cnt = %h (expected 20)", rows_cnt);

        // Scenario 3: size 128, 16384 data bytes - expect rows_cnt = 80 (hex).
        size_latched = 2'd2;
        latched = 1'b1; #10;
        latched = 1'b0; #10;
        repeat (16384) begin
            data_byte_sent = 1'b1; #10;
            data_byte_sent = 1'b0; #10;
        end
        #100;
        $display("size 2: rows_cnt = %h (expected 80)", rows_cnt);

        // Scenario 4: size 256, 65536 data bytes - expect rows_cnt to wrap to 00.
        size_latched = 2'd3;
        latched = 1'b1; #10;
        latched = 1'b0; #10;
        repeat (65536) begin
            data_byte_sent = 1'b1; #10;
            data_byte_sent = 1'b0; #10;
        end
        #100;
        $display("size 3: rows_cnt = %h (expected 00)", rows_cnt);

        $finish;
    end

endmodule
