`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        value_latch
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Latches the switch configuration (character, inter-byte delay,
//                square size) on btn_pulse, only while no transmission is
//                running (tx_busy = 0). Outputs a registered one-cycle start
//                pulse (latched) and valid_latched for the display.
//////////////////////////////////////////////////////////////////////////////////

module value_latch(

    input wire clk, rst_n,
    input wire btn_pulse,
    input wire tx_busy,
    input wire [15:0] sw,
    output reg [7:0] char_latched,
    output reg [1:0] delay_latched,
    output reg [1:0] size_latched,
    output reg latched,
    output reg valid_latched
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latched <= 1'b0;
            valid_latched <= 1'b0;
            char_latched <= 8'd0;
            delay_latched <= 2'd0;
            size_latched <= 2'd0;
        // Capture a new configuration only when idle
        end else if (btn_pulse && !tx_busy) begin
            latched <= 1'b1;
            valid_latched <= 1'b1;   // stays high after the first press
            char_latched <= sw[7:0];   // ASCII character
            delay_latched <= sw[9:8];   // 00=0, 01=50, 10=100, 11=200 ms
            size_latched <= sw[14:13];   // 00=1, 01=32, 10=128, 11=256
 30          end else
            latched <= 1'b0;   // one-cycle pulse; settings are held
    end
endmodule
