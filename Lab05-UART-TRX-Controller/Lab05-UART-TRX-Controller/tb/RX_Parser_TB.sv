`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   RX_Parser_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for RX_Parser: valid, garbage, out of range, broken
//                format, restart on {, reset.
//////////////////////////////////////////////////////////////////////////////////

module RX_Parser_TB;

    logic clk = 1'b0;
    logic rst_n;
    logic [7:0] rx_byte;
    logic rx_valid;
    logic [7:0] row, col, pix;
    logic row_err, col_err, pix_err, fmt_err, msg_done;

    always #5 clk = ~clk;

    RX_Parser RX_Parser_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .rx_byte(rx_byte),
        .rx_valid(rx_valid),
        .row(row),
        .col(col),
        .pix(pix),
        .row_err(row_err),
        .col_err(col_err),
        .pix_err(pix_err),
        .fmt_err(fmt_err),
        .msg_done(msg_done)
    );

    int errors = 0;

    // Builds a message string "{Rddd,Cddd,Vddd}" from three numbers
    function automatic string make_msg(input int r, input int c, input int v);
        return $sformatf("{R%03d,C%03d,V%03d}", r, c, v);
    endfunction

    // One byte from RX_PHY: rx_valid high for exactly one clock
    task automatic send_byte(input logic [7:0] b);
        @(negedge clk);
        rx_byte  = b;
        rx_valid = 1'b1;
        @(negedge clk);
        rx_valid = 1'b0;
        repeat (3) @(negedge clk);              // gap between bytes, like a real UART
    endtask

    task automatic send_str(input string s);
        for (int i = 0; i < s.len(); i++) send_byte(s[i]);
        repeat (3) @(negedge clk);
    endtask

    task automatic check(input logic [7:0] exp_row, exp_col, exp_pix,
                         input logic exp_re, exp_ce, exp_pe, exp_fe, input string name);
        if ({row, col, pix} !== {exp_row, exp_col, exp_pix} ||
            {row_err, col_err, pix_err, fmt_err} !== {exp_re, exp_ce, exp_pe, exp_fe}) begin
            $display("ERROR [%s] t=%0t: got R=%h C=%h V=%h err=%b%b%b fmt=%b, expected R=%h C=%h V=%h err=%b%b%b fmt=%b",
                     name, $time, row, col, pix, row_err, col_err, pix_err, fmt_err,
                     exp_row, exp_col, exp_pix, exp_re, exp_ce, exp_pe, exp_fe);
            errors++;
        end else begin
            $display("PASS  [%s]: R=%h C=%h V=%h err=%b%b%b fmt=%b",
                     name, row, col, pix, row_err, col_err, pix_err, fmt_err);
        end
    endtask

    // msg_done is a 1-cycle pulse
    assert property (@(posedge clk) disable iff (!rst_n) msg_done |=> !msg_done)
        else begin $error("msg_done wider than one cycle at t=%0t", $time); errors++; end

    // The outputs change only when a message ends
    assert property (@(posedge clk) disable iff (!rst_n)
        ({row, col, pix, fmt_err} != $past({row, col, pix, fmt_err})) |-> msg_done)
        else begin $error("outputs changed without a message end at t=%0t", $time); errors++; end

    initial begin
        rst_n = 1'b0; rx_byte = '0; rx_valid = 1'b0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Scenario 1 - Valid message: values updated, no errors
        send_str(make_msg(1, 2, 128));
        check(8'd1, 8'd2, 8'd128, 0, 0, 0, 0, "S1 valid message");

        // Scenario 2 - Garbage before '{' is ignored, then a valid message
        send_str("ab");
        send_str(make_msg(10, 20, 255));
        check(8'd10, 8'd20, 8'd255, 0, 0, 0, 0, "S2 garbage before message");

        // Scenario 3 - Row out of range (300): only row_err, col and pix updated
        send_str(make_msg(300, 5, 9));
        check(8'(300), 8'd5, 8'd9, 1, 0, 0, 0, "S3 row out of range");

        // Scenario 4 - Broken format (';' instead of ','): fmt_err, values kept
        send_str("{R001;C002,V003}");
        check(8'(300), 8'd5, 8'd9, 1, 0, 0, 1, "S4 broken format");

        // Scenario 5 - Message cut in the middle, then a new '{' restarts: valid message
        send_str("{R001,C0");
        send_str(make_msg(7, 8, 9));
        check(8'd7, 8'd8, 8'd9, 0, 0, 0, 0, "S5 restart on new brace");

        // Scenario 6 - Reset in the middle of a message: outputs cleared, then a valid message
        send_str("{R123,C");
        rst_n = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        check(8'd0, 8'd0, 8'd0, 0, 0, 0, 0, "S6 reset mid-message");
        send_str(make_msg(255, 0, 100));
        check(8'd255, 8'd0, 8'd100, 0, 0, 0, 0, "S6 message after reset");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule
