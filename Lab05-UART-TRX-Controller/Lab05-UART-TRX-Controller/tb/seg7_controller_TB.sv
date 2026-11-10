`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   seg7_controller_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for seg7_controller: digit-by-digit model check in TX
//                and RX modes, E- errors.
//////////////////////////////////////////////////////////////////////////////////

module seg7_controller_TB;

    import uart_pkg::SEG_DASH;

    logic clk = 1'b0;
    logic rst_n, refresh_tick, rx_mode;
    logic [7:0] char_latched, rows_cnt;
    logic [1:0] delay_latched, size_latched;
    logic valid_latched;
    logic [7:0] rx_row, rx_col, rx_pix;
    logic rx_row_err, rx_col_err, rx_pix_err, rx_fmt_err;
    logic [7:0] an, seg;

    always #5 clk = ~clk;

    seg7_controller seg7_controller_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
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

    int errors = 0;
    bit check_en = 0;

    // Expected 5-bit decoder input for a digit index (reference model)
    function automatic logic [4:0] exp_digit(input logic [2:0] idx);
        logic [3:0] d_hi, d_lo, s_hi, s_lo;
        logic re, ce, pe;
        if (!rx_mode) begin
            d_hi = (delay_latched == 2'd2) ? 4'd1 : (delay_latched == 2'd3) ? 4'd2 : 4'd0;
            d_lo = (delay_latched == 2'd1) ? 4'd5 : 4'd0;
            s_hi = (size_latched == 2'd1) ? 4'd2 : (size_latched == 2'd2) ? 4'd8 : (size_latched == 2'd3) ? 4'hF : 4'd0;
            s_lo = (size_latched == 2'd0) ? 4'd1 : (size_latched == 2'd3) ? 4'hF : 4'd0;
            case (idx)
                3'd0: return {1'b0, char_latched[3:0]};
                3'd1: return {1'b0, char_latched[7:4]};
                3'd2: return {1'b0, d_lo};
                3'd3: return {1'b0, d_hi};
                3'd4: return {1'b0, s_lo};
                3'd5: return {1'b0, s_hi};
                3'd6: return {1'b0, rows_cnt[3:0]};
                default: return {1'b0, rows_cnt[7:4]};
            endcase
        end else begin
            re = rx_fmt_err || rx_row_err;
            ce = rx_fmt_err || rx_col_err;
            pe = rx_fmt_err || rx_pix_err;
            case (idx)
                3'd0: return pe ? SEG_DASH : {1'b0, rx_pix[3:0]};
                3'd1: return pe ? 5'h0E    : {1'b0, rx_pix[7:4]};
                3'd2, 3'd3: return SEG_DASH;
                3'd4: return ce ? SEG_DASH : {1'b0, rx_col[3:0]};
                3'd5: return ce ? 5'h0E    : {1'b0, rx_col[7:4]};
                3'd6: return re ? SEG_DASH : {1'b0, rx_row[3:0]};
                default: return re ? 5'h0E : {1'b0, rx_row[7:4]};
            endcase
        end
    endfunction

    // Monitor: every digit shown is compared with the model (anode, digit, DP)
    always @(negedge clk) begin
        if (check_en) begin
            logic [2:0] idx;
            logic [7:0] exp_an;
            idx = seg7_controller_TB_DUT.digit_idx;
            exp_an = (rx_mode || valid_latched) ? ~(8'd1 << idx) : 8'hFF;
            if (an !== exp_an) begin
                $display("ERROR t=%0t: an=%h, expected %h", $time, an, exp_an); errors++;
            end
            if (exp_an != 8'hFF && seg7_controller_TB_DUT.digit !== exp_digit(idx)) begin
                $display("ERROR t=%0t: digit %0d = %h, expected %h", $time, idx,
                         seg7_controller_TB_DUT.digit, exp_digit(idx)); errors++;
            end
            if (seg[7] !== ((!rx_mode && idx == 3'd3) ? 1'b0 : 1'b1)) begin
                $display("ERROR t=%0t: DP wrong on digit %0d", $time, idx); errors++;
            end
        end
    end

    // At most one digit is on at any time
    assert property (@(posedge clk) disable iff (!rst_n) $onehot0(~an))
        else begin $error("more than one anode active at t=%0t", $time); errors++; end

    // Refresh tick every 2 clocks -> a full 8-digit sweep takes 16 clocks
    always @(posedge clk) refresh_tick <= ~refresh_tick;

    // Run one scenario: hold the inputs for two full sweeps while the monitor checks
    task automatic run_scenario(input string name);
        int err_before;
        err_before = errors;
        check_en = 1;
        repeat (40) @(negedge clk);
        check_en = 0;
        if (errors == err_before) $display("PASS  [%s]", name);
        else                      $display("FAIL  [%s]", name);
    endtask

    initial begin
        rst_n = 1'b0; refresh_tick = 1'b0; rx_mode = 1'b0;
        char_latched = '0; delay_latched = '0; size_latched = '0; rows_cnt = '0; valid_latched = 1'b0;
        rx_row = '0; rx_col = '0; rx_pix = '0;
        {rx_row_err, rx_col_err, rx_pix_err, rx_fmt_err} = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Scenario 1 - TX mode before the first latch: display blank
        run_scenario("S1 TX blank before latch");

        // Scenario 2 - TX mode: char 41, delay 0.5, size 20, rows 05
        valid_latched = 1'b1; char_latched = 8'h41; delay_latched = 2'd1; size_latched = 2'd1; rows_cnt = 8'h05;
        run_scenario("S2 TX values");

        // Scenario 3 - TX mode: char 5A, delay 2.0, size FF, rows FF
        char_latched = 8'h5A; delay_latched = 2'd3; size_latched = 2'd3; rows_cnt = 8'hFF;
        run_scenario("S3 TX max values");

        // Scenario 4 - RX mode, valid message: R=01 C=02 V=80, dashes on T1, no DP
        rx_mode = 1'b1; rx_row = 8'h01; rx_col = 8'h02; rx_pix = 8'h80;
        run_scenario("S4 RX valid message");

        // Scenario 5 - RX mode, row out of range: row shows E-, col and pix shown
        rx_row_err = 1'b1;
        run_scenario("S5 RX row error");

        // Scenario 6 - RX mode, broken format: all fields E-
        rx_row_err = 1'b0; rx_fmt_err = 1'b1;
        run_scenario("S6 RX broken format");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule
