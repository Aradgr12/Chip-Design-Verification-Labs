`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   seg7_controller
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   8-digit multiplexed display. TX: rows/size/delay/char. RX:
//                row/col/--/pixel, errors shown as E-.
//////////////////////////////////////////////////////////////////////////////////

module seg7_controller
    import uart_pkg::SEG_DASH;
(
    input  logic       clk, rst_n,
    input  logic       refresh_tick,
    input  logic       rx_mode,
    // TX mode
    input  logic [7:0] char_latched,
    input  logic [1:0] delay_latched,
    input  logic [1:0] size_latched,
    input  logic [7:0] rows_cnt,
    input  logic       valid_latched,
    // RX mode
    input  logic [7:0] rx_row, rx_col, rx_pix,
    input  logic       rx_row_err, rx_col_err, rx_pix_err, rx_fmt_err,
    output logic [7:0] an,
    output logic [7:0] seg
);

    localparam logic [4:0] SEG_E = 5'h0E;       // hex digit E, used as the error mark

    logic [2:0] digit_idx;
    logic [4:0] digit, tx_digit, rx_digit;
    logic [3:0] delay_hi, delay_low, size_hi, size_low;
    logic       row_e, col_e, pix_e;
    logic       dp;
    logic [6:0] seg_raw;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_idx <= 3'd0;
        end else if (refresh_tick) begin
            digit_idx <= digit_idx + 3'd1;
        end
    end

    // TX: blank until the first latch. RX: always on
    assign an = (rx_mode || valid_latched) ? ~(8'd1 << digit_idx) : 8'hFF;

    // ---------------- TX mode digits (Lab 4) ----------------
    assign delay_hi  = (delay_latched == 2'd0) ? 4'd0 :
                       (delay_latched == 2'd1) ? 4'd0 :
                       (delay_latched == 2'd2) ? 4'd1 : 4'd2;
    assign delay_low = (delay_latched == 2'd0) ? 4'd0 :
                       (delay_latched == 2'd1) ? 4'd5 :
                       (delay_latched == 2'd2) ? 4'd0 : 4'd0;
    assign size_hi   = (size_latched == 2'd0) ? 4'd0 :
                       (size_latched == 2'd1) ? 4'd2 :
                       (size_latched == 2'd2) ? 4'd8 : 4'hF;
    assign size_low  = (size_latched == 2'd0) ? 4'd1 :
                       (size_latched == 2'd1) ? 4'd0 :
                       (size_latched == 2'd2) ? 4'd0 : 4'hF;

    assign tx_digit = (digit_idx == 3'd0) ? {1'b0, char_latched[3:0]} :
                      (digit_idx == 3'd1) ? {1'b0, char_latched[7:4]} :
                      (digit_idx == 3'd2) ? {1'b0, delay_low} :
                      (digit_idx == 3'd3) ? {1'b0, delay_hi} :
                      (digit_idx == 3'd4) ? {1'b0, size_low} :
                      (digit_idx == 3'd5) ? {1'b0, size_hi} :
                      (digit_idx == 3'd6) ? {1'b0, rows_cnt[3:0]} : {1'b0, rows_cnt[7:4]};

    // ---------------- RX mode digits ----------------
    assign row_e = rx_fmt_err || rx_row_err;
    assign col_e = rx_fmt_err || rx_col_err;
    assign pix_e = rx_fmt_err || rx_pix_err;

    // Error field = "E-" : E on the high digit, dash on the low digit
    assign rx_digit = (digit_idx == 3'd0) ? (pix_e ? SEG_DASH : {1'b0, rx_pix[3:0]}) :
                      (digit_idx == 3'd1) ? (pix_e ? SEG_E    : {1'b0, rx_pix[7:4]}) :
                      (digit_idx == 3'd2) ? SEG_DASH :
                      (digit_idx == 3'd3) ? SEG_DASH :
                      (digit_idx == 3'd4) ? (col_e ? SEG_DASH : {1'b0, rx_col[3:0]}) :
                      (digit_idx == 3'd5) ? (col_e ? SEG_E    : {1'b0, rx_col[7:4]}) :
                      (digit_idx == 3'd6) ? (row_e ? SEG_DASH : {1'b0, rx_row[3:0]}) :
                                            (row_e ? SEG_E    : {1'b0, rx_row[7:4]});

    assign digit = rx_mode ? rx_digit : tx_digit;

    // Decimal point only in TX mode, on the delay digit
    assign dp = (!rx_mode && digit_idx == 3'd3) ? 1'b0 : 1'b1;

    seg7_decoder seg7_decoder_u (
        .digit(digit),
        .seg(seg_raw)
    );

    assign seg = {dp, seg_raw};

endmodule
