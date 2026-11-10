`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   UART_TRX_TOP_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   System TB: TX squares, SW15 change during TX, RX messages, button
//                ignored in RX, back to TX.
//////////////////////////////////////////////////////////////////////////////////

module UART_TRX_TOP_TB;

    // Short simulation values (the TB overrides the top parameters)
    localparam int BIT_CYCLES  = 64;           // multiple of 16 for RX oversampling
    localparam int BTN_CYCLES  = 10;
    localparam int DELAY_50MS  = 20;
    localparam int DELAY_100MS = 40;
    localparam int DELAY_200MS = 80;
    localparam int REFRESH_MAX = 3;

    logic clk = 1'b0;
    logic rst_n, btn_c, uart_rx;
    logic [15:0] sw;
    logic uart_tx, led_byte, led_mode;
    logic [7:0] an, seg;

    always #5 clk = ~clk;

    UART_TRX_TOP #(
        .BTN_CYCLES(BTN_CYCLES),
        .BIT_CYCLES(BIT_CYCLES),
        .DELAY_50MS(DELAY_50MS),
        .DELAY_100MS(DELAY_100MS),
        .DELAY_200MS(DELAY_200MS),
        .REFRESH_MAX(REFRESH_MAX)
    ) UART_TRX_TOP_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .btn_c(btn_c),
        .sw(sw),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .led_byte(led_byte),
        .led_mode(led_mode),
        .an(an),
        .seg(seg)
    );

    int errors   = 0;
    int tx_bytes = 0;

    // Count the bytes handed from TX_FSM to UART_PHY
    always @(posedge clk) if (UART_TRX_TOP_TB_DUT.tx_send) tx_bytes++;

    // Bytes in an n x n square: every row = n chars + (n-1) spaces + CR + LF,
    // the last row ends without CR/LF
    function automatic int square_bytes(input int n);
        return n * (2*n + 1) - 2;
    endfunction

    // In RX mode the TX line must stay idle
    assert property (@(posedge clk) disable iff (!rst_n) led_mode |-> uart_tx)
        else begin $error("uart_tx active in RX mode at t=%0t", $time); errors++; end

    // The mode never changes while a transmission is running
    assert property (@(posedge clk) disable iff (!rst_n)
        UART_TRX_TOP_TB_DUT.tx_busy |=> $stable(led_mode))
        else begin $error("mode changed during TX at t=%0t", $time); errors++; end

    task automatic press_btn();
        @(negedge clk) btn_c = 1'b1;
        repeat (2*BTN_CYCLES) @(negedge clk);
        btn_c = 1'b0;
        repeat (2*BTN_CYCLES) @(negedge clk);
    endtask

    task automatic set_sw(input logic mode, input logic [1:0] size, input logic [1:0] delay, input logic [7:0] value);
        @(negedge clk) sw = {mode, size, 3'b000, delay, value};
        repeat (5) @(negedge clk);
    endtask

    task automatic uart_send(input logic [7:0] b);
        uart_rx = 1'b0;                                     // start bit
        repeat (BIT_CYCLES) @(negedge clk);
        for (int i = 0; i < 8; i++) begin                   // LSB first
            uart_rx = b[i];
            repeat (BIT_CYCLES) @(negedge clk);
        end
        uart_rx = 1'b1;                                     // stop bit
        repeat (BIT_CYCLES) @(negedge clk);
    endtask

    task automatic uart_send_str(input string s);
        for (int i = 0; i < s.len(); i++) uart_send(s[i]);
        repeat (2*BIT_CYCLES) @(negedge clk);
    endtask

    task automatic wait_tx_done();
        wait (UART_TRX_TOP_TB_DUT.tx_busy == 1'b1);
        wait (UART_TRX_TOP_TB_DUT.tx_busy == 1'b0);
        repeat (2*BIT_CYCLES*10) @(negedge clk);
    endtask

    task automatic check_int(input int got, input int exp, input string name);
        if (got !== exp) begin
            $display("ERROR [%s] t=%0t: got %0d, expected %0d", name, $time, got, exp); errors++;
        end else $display("PASS  [%s]: %0d", name, got);
    endtask

    task automatic check_rx(input logic [7:0] r, c, v, input logic fmt, input string name);
        logic [7:0] gr, gc, gv; logic gf;
        gr = UART_TRX_TOP_TB_DUT.rx_row;
        gc = UART_TRX_TOP_TB_DUT.rx_col;
        gv = UART_TRX_TOP_TB_DUT.rx_pix;
        gf = UART_TRX_TOP_TB_DUT.rx_fmt_err;
        if ({gr, gc, gv, gf} !== {r, c, v, fmt}) begin
            $display("ERROR [%s] t=%0t: got R=%h C=%h V=%h fmt=%b, expected R=%h C=%h V=%h fmt=%b",
                     name, $time, gr, gc, gv, gf, r, c, v, fmt); errors++;
        end else $display("PASS  [%s]: R=%h C=%h V=%h fmt=%b", name, gr, gc, gv, gf);
    endtask

    initial begin
        rst_n = 1'b0; btn_c = 1'b0; uart_rx = 1'b1; sw = '0;
        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        repeat (5) @(negedge clk);

        // Scenario 1 - TX single byte: expect 1 byte, LED15 off
        set_sw(1'b0, 2'd0, 2'd0, 8'h41);
        tx_bytes = 0;
        press_btn();
        wait_tx_done();
        check_int(tx_bytes, square_bytes(1), "S1 TX single byte");
        check_int(led_mode, 0, "S1 LED15 = TX mode");

        // Scenario 2 - TX 32x32, SW15 moved to RX in the middle:
        //              the square completes, the mode changes only after it
        set_sw(1'b0, 2'd1, 2'd0, 8'h5A);
        tx_bytes = 0;
        press_btn();
        repeat (20*10*BIT_CYCLES) @(negedge clk);           // ~20 bytes into the square
        sw[15] = 1'b1;
        repeat (10) @(negedge clk);
        check_int(led_mode, 0, "S2 mode held during TX");
        wait_tx_done();
        check_int(tx_bytes, square_bytes(32), "S2 TX 32x32 completed");
        check_int(led_mode, 1, "S2 LED15 = RX mode after TX");

        // Scenario 3 - RX valid message: R=0x01 C=0x02 V=0x80
        uart_send_str("{R001,C002,V128}");
        check_rx(8'h01, 8'h02, 8'h80, 1'b0, "S3 RX valid message");

        // Scenario 4 - RX broken format: fmt_err, values kept
        uart_send_str("{R001;C002,V003}");
        check_rx(8'h01, 8'h02, 8'h80, 1'b1, "S4 RX broken format");

        // Scenario 5 - Button in RX mode: no TX bytes (also checked by the assertion)
        tx_bytes = 0;
        press_btn();
        repeat (20*BIT_CYCLES) @(negedge clk);
        check_int(tx_bytes, 0, "S5 button ignored in RX");

        // Scenario 6 - Back to TX: switch is immediate (TX idle), transmission works again
        set_sw(1'b0, 2'd0, 2'd0, 8'h33);
        check_int(led_mode, 0, "S6 LED15 = TX mode");
        tx_bytes = 0;
        press_btn();
        wait_tx_done();
        check_int(tx_bytes, square_bytes(1), "S6 TX after RX");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule
