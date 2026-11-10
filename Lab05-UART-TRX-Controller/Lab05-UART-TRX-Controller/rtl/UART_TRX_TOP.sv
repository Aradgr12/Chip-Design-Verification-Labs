`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   UART_TRX_TOP
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Top level: TX and RX paths, SW15 mode selection (waits for TX end),
//                LED15 mode indicator, LED0 data-byte toggle.
//////////////////////////////////////////////////////////////////////////////////

module UART_TRX_TOP #(
    parameter int BTN_CYCLES  = 1_500_000,
    parameter int BIT_CYCLES  = 1736,
    parameter int DELAY_50MS  = 5_000_000,
    parameter int DELAY_100MS = 10_000_000,
    parameter int DELAY_200MS = 20_000_000,
    parameter int REFRESH_MAX = 24_999        // 100MHz / (500Hz x 8 digits) - 1
)(
    input  logic        clk, rst_n,
    input  logic        btn_c,
    input  logic [15:0] sw,
    input  logic        uart_rx,
    output logic        uart_tx,
    output logic        led_byte,             // LED0
    output logic        led_mode,             // LED15 - 1 = RX mode
    output logic [7:0]  an,
    output logic [7:0]  seg
);

    // Reset synchronizer - async assert, sync de-assert
    logic [1:0] rst_sync;
    logic       rst_n_sync;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rst_sync <= '0;
        else        rst_sync <= {rst_sync[0], 1'b1};
    end

    assign rst_n_sync = rst_sync[1];

    // Mode selection: SW[15] is synchronized, and the mode changes only when TX is idle
    logic [1:0] mode_sync;
    logic       rx_mode;
    logic       tx_busy;

    always_ff @(posedge clk or negedge rst_n_sync) begin
        if (!rst_n_sync) mode_sync <= '0;
        else             mode_sync <= {mode_sync[0], sw[15]};
    end

    always_ff @(posedge clk or negedge rst_n_sync) begin
        if (!rst_n_sync)  rx_mode <= 1'b0;
        else if (!tx_busy) rx_mode <= mode_sync[1];
    end

    assign led_mode = rx_mode;

    // ---------------- TX path ----------------
    logic       btn_pulse;
    logic [7:0] char_latched;
    logic [1:0] delay_latched;
    logic [1:0] size_latched;
    logic       latched, valid_latched;
    logic [7:0] tx_byte;
    logic       tx_send, PHY_finish, data_byte_sent;
    logic [7:0] rows_cnt;

    Debouncer #(.BTN_CYCLES(BTN_CYCLES)) Debouncer_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .btn_c(btn_c),
        .btn_pulse(btn_pulse)
    );

    value_latch value_latch_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .btn_pulse(btn_pulse && !rx_mode),     // button ignored in RX mode
        .tx_busy(tx_busy),
        .sw(sw),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .latched(latched),
        .valid_latched(valid_latched)
    );

    TX_FSM #(
        .DELAY_50MS(DELAY_50MS),
        .DELAY_100MS(DELAY_100MS),
        .DELAY_200MS(DELAY_200MS)
    ) TX_FSM_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .latched(latched),
        .PHY_finish(PHY_finish),
        .tx_byte(tx_byte),
        .tx_send(tx_send),
        .tx_busy(tx_busy),
        .data_byte_sent(data_byte_sent),
        .led_byte(led_byte)
    );

    UART_PHY #(.BIT_CYCLES(BIT_CYCLES)) UART_PHY_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .tx_byte(tx_byte),
        .tx_send(tx_send),
        .uart_tx(uart_tx),
        .PHY_finish(PHY_finish)
    );

    bytes_counter bytes_counter_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .data_byte_sent(data_byte_sent),
        .latched(latched),
        .size_latched(size_latched),
        .rows_cnt(rows_cnt)
    );

    // ---------------- RX path ----------------
    logic [7:0] rx_byte;
    logic       rx_valid;
    logic [7:0] rx_row, rx_col, rx_pix;
    logic       rx_row_err, rx_col_err, rx_pix_err, rx_fmt_err;

    RX_PHY #(.BIT_CYCLES(BIT_CYCLES)) RX_PHY_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .uart_rx(uart_rx),
        .rx_en(rx_mode),
        .rx_byte(rx_byte),
        .rx_valid(rx_valid)
    );

    RX_Parser RX_Parser_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .rx_byte(rx_byte),
        .rx_valid(rx_valid),
        .row(rx_row),
        .col(rx_col),
        .pix(rx_pix),
        .row_err(rx_row_err),
        .col_err(rx_col_err),
        .pix_err(rx_pix_err),
        .fmt_err(rx_fmt_err),
        .msg_done()                            // used by RX_Parser_TB only
    );

    // ---------------- Display ----------------
    logic refresh_tick;

    tick_gen #(.MAX(REFRESH_MAX)) tick_gen_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .refresh_tick(refresh_tick)
    );

    seg7_controller seg7_controller_u (
        .clk(clk),
        .rst_n(rst_n_sync),
        .refresh_tick(refresh_tick),
        .rx_mode(rx_mode),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .rows_cnt(rows_cnt),
        .valid_latched(valid_latched),
        .rx_row(rx_row),
        .rx_col(rx_col),
        .rx_pix(rx_pix),
        .rx_row_err(rx_row_err),
        .rx_col_err(rx_col_err),
        .rx_pix_err(rx_pix_err),
        .rx_fmt_err(rx_fmt_err),
        .an(an),
        .seg(seg)
    );

endmodule
