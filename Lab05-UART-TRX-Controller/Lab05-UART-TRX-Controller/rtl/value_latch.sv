`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   value_latch
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Latches the switch configuration (char, delay, size) on a button pulse
//                while TX is idle.
//////////////////////////////////////////////////////////////////////////////////

module value_latch
    import uart_pkg::*;
    (
    input logic clk, rst_n,
    input logic  btn_pulse,
    input logic  tx_busy,
    input sw_config_t sw,
    output logic [7:0] char_latched,
    output logic [1:0] delay_latched,
    output logic [1:0] size_latched,
    output logic latched,
    output logic valid_latched
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latched <= '0;
            valid_latched <= '0;
            char_latched <= '0;
            delay_latched <= '0;
            size_latched <= '0;
        end else if (btn_pulse && !tx_busy) begin
            latched <= 1'b1;
            valid_latched <= 1'b1;
            char_latched <= sw.sw_value;
            delay_latched <= sw.sw_delay;
            size_latched <= sw.sw_bytes_qty;
       end else
            latched <= '0;           
    end
endmodule
