`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        UART_TX_TOP
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Top level of the UART TX controller. Contains the reset
//                synchronizer (asynchronous assert, synchronous release) and
//                connects all blocks; timing parameters are passed down so the
//                testbench can shorten them.
//////////////////////////////////////////////////////////////////////////////////

module UART_TX_TOP #(
    
    parameter BTN_CYCLES = 1500000,   // 15 ms debounce @ 100 MHz
    parameter BIT_CYCLES = 1736,   // 100 MHz / 57600 baud
    parameter DELAY_50MS = 5000000,   // 50 ms @ 100 MHz
    parameter DELAY_100MS = 10000000,   // 100 ms @ 100 MHz
    parameter DELAY_200MS = 20000000,   // 200 ms @ 100 MHz
    parameter REFRESH_MAX = 24999   // 4 kHz digit refresh (500 Hz full display cycle)
)(
    input wire clk, rst_n,   // rst_n = CPU_RESETN (active low)
    input wire btn_c,
    input wire [15:0] sw,   // sw[7:0]=char, sw[9:8]=delay, sw[14:13]=size
    output wire uart_tx,
    output wire led_byte, led_done,
    output wire [7:0] an,
    output wire [7:0] seg
);
    
    wire btn_pulse;
    wire [7:0] char_latched;
    wire [1:0] delay_latched;
    wire [1:0] size_latched;
    wire latched, valid_latched;
    wire tx_busy;
    wire [7:0] tx_byte;
    wire tx_send, PHY_finish, data_byte_sent;
    wire [7:0] rows_cnt;
    wire refresh_tick;
    
    // Reset synchronizer: asynchronous assert, synchronous de-assert
    reg rst_n_sync;
    reg rst_meta;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
        rst_n_sync <= 1'b0;
        rst_meta <= 1'b0;
        end else begin
            rst_meta <= 1'b1;
            rst_n_sync <= rst_meta;
        end
    end    
    
    // Button debounce -> single-cycle press pulse
    Debouncer#(.BTN_CYCLES(BTN_CYCLES)) Debouncer_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .btn_c(btn_c),
        .btn_pulse(btn_pulse)
    );
    
    // Latch switches on a press (ignored while transmitting)
    value_latch value_latch_u(
        .clk(clk),
        .rst_n(rst_n_sync),
        .btn_pulse(btn_pulse),
        .tx_busy(tx_busy),       
        .sw(sw),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .latched(latched),
        .valid_latched(valid_latched)
    );
    
    // Main control FSM: sequences data chars, spaces, CR/LF and delays
    TX_FSM #(.DELAY_50MS(DELAY_50MS), .DELAY_100MS(DELAY_100MS), .DELAY_200MS(DELAY_200MS)) TX_FSM_u(
        .clk(clk),
        .rst_n(rst_n_sync),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .latched(latched),
        .tx_send(tx_send),
        .PHY_finish(PHY_finish),
        .tx_byte(tx_byte),
        .tx_busy(tx_busy),
        .data_byte_sent(data_byte_sent),
        .led_byte(led_byte),
        .led_done(led_done)        
    );
    
    // UART serializer: start bit, 8 data bits LSB first, stop bit
    UART_PHY #(.BIT_CYCLES(BIT_CYCLES)) UART_PHY_u(
        .clk(clk),
        .rst_n(rst_n_sync),
        .tx_byte(tx_byte),
        .tx_send(tx_send),
        .uart_tx(uart_tx),
        .PHY_finish(PHY_finish)
    );
    
    // Counts data chars and converts them to completed rows for the display
    bytes_counter bytes_counter_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .data_byte_sent(data_byte_sent),
        .latched(latched),
        .size_latched(size_latched),
        .rows_cnt(rows_cnt)
    );
    
    // Digit refresh enable pulse (an enable, not a derived clock - avoids CDC)
    tick_gen #(.MAX(REFRESH_MAX)) tick_gen_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .refresh_tick(refresh_tick)
    );
    
    // 8-digit multiplexed 7-segment display
    seg7_controller seg7_controller_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .refresh_tick(refresh_tick),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .rows_cnt(rows_cnt),
        .valid_latched(valid_latched),
        .an(an),
        .seg(seg)
    );
endmodule
