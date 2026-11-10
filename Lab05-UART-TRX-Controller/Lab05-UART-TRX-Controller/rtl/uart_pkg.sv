`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   uart_pkg
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Shared types and constants: switch mapping struct, 7-segment special
//                codes, MAX_ROW and ASCII characters for TX and RX.
//////////////////////////////////////////////////////////////////////////////////

package uart_pkg;

    // Switches mapping (SW[15:0])
    typedef struct packed {
        logic       trx_mode;       // bit 15     - 0 = TX, 1 = RX
        logic [1:0] sw_bytes_qty;   // bits 14:13
        logic [2:0] reserved;       // bits 12:10
        logic [1:0] sw_delay;       // bits 9:8
        logic [7:0] sw_value;       // bits 7:0
    } sw_config_t;

    // 7-segment special codes (above the hex digits 0-F)
    localparam logic [4:0] SEG_DASH = 5'h10;

    // Largest square side (256x256)
    localparam int MAX_ROW = 256;

    // ASCII control characters used by TX
    localparam logic [7:0] ASCII_SPACE = 8'h20;
    localparam logic [7:0] ASCII_CR    = 8'h0D;
    localparam logic [7:0] ASCII_LF    = 8'h0A;

    // ASCII characters of the RX message "{Rddd,Cddd,Vddd}"
    localparam logic [7:0] ASCII_LBRACE = 8'h7B;   // {
    localparam logic [7:0] ASCII_RBRACE = 8'h7D;   // }
    localparam logic [7:0] ASCII_COMMA  = 8'h2C;   // ,
    localparam logic [7:0] ASCII_R      = 8'h52;
    localparam logic [7:0] ASCII_C      = 8'h43;
    localparam logic [7:0] ASCII_V      = 8'h56;
    localparam logic [7:0] ASCII_0      = 8'h30;
    localparam logic [7:0] ASCII_9      = 8'h39;

endpackage
