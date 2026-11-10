`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   UART_PHY_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for UART_PHY: frame decoding of several bytes,
//                PHY_finish pulse, reset mid-frame.
//////////////////////////////////////////////////////////////////////////////////

module UART_PHY_TB;

    localparam int BIT_CYCLES = 16;

    logic clk = 1'b0;
    logic rst_n, tx_send;
    logic [7:0] tx_byte;
    logic uart_tx, PHY_finish;

    always #5 clk = ~clk;

    UART_PHY #(.BIT_CYCLES(BIT_CYCLES)) UART_PHY_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .tx_byte(tx_byte),
        .tx_send(tx_send),
        .uart_tx(uart_tx),
        .PHY_finish(PHY_finish)
    );

    int errors = 0;
    int finish_cnt = 0;

    always @(posedge clk) if (PHY_finish) finish_cnt++;

    // PHY_finish is a 1-cycle pulse
    assert property (@(posedge clk) disable iff (!rst_n) PHY_finish |=> !PHY_finish)
        else begin $error("PHY_finish wider than one cycle at t=%0t", $time); errors++; end

    // Line idle (1) during reset
    assert property (@(posedge clk) !rst_n |-> uart_tx)
        else begin $error("uart_tx not idle during reset at t=%0t", $time); errors++; end

    // Send one byte and decode the frame on uart_tx (start, 8 bits LSB first, stop)
    task automatic send_and_check(input logic [7:0] b, input string name);
        logic [7:0] got;
        int fin_before;
        fin_before = finish_cnt;
        @(negedge clk);
        tx_byte = b; tx_send = 1'b1;
        @(negedge clk);
        tx_send = 1'b0;
        wait (uart_tx == 1'b0);                         // start bit
        repeat (BIT_CYCLES/2) @(negedge clk);           // middle of start bit
        for (int i = 0; i < 8; i++) begin
            repeat (BIT_CYCLES) @(negedge clk);
            got[i] = uart_tx;
        end
        repeat (BIT_CYCLES) @(negedge clk);             // middle of stop bit
        if (uart_tx !== 1'b1) begin
            $display("ERROR [%s]: stop bit is 0", name); errors++;
        end
        repeat (BIT_CYCLES) @(negedge clk);
        if (got !== b || finish_cnt != fin_before + 1) begin
            $display("ERROR [%s]: sent %h, decoded %h, PHY_finish pulses %0d",
                     name, b, got, finish_cnt - fin_before); errors++;
        end else $display("PASS  [%s]: %h", name, got);
    endtask

    initial begin
        rst_n = 1'b0; tx_send = 1'b0; tx_byte = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        repeat (3) @(negedge clk);

        // Scenario 1 - Alternating bits 0x55
        send_and_check(8'h55, "S1 byte 55");
        // Scenario 2 - All zeros / all ones
        send_and_check(8'h00, "S2 byte 00");
        send_and_check(8'hFF, "S2 byte FF");
        // Scenario 3 - Asymmetric byte (catches reversed bit order)
        send_and_check(8'hA5, "S3 byte A5");
        // Scenario 4 - Reset in the middle of a frame: line back to idle, no PHY_finish
        @(negedge clk); tx_byte = 8'h3C; tx_send = 1'b1;
        @(negedge clk); tx_send = 1'b0;
        repeat (4*BIT_CYCLES) @(negedge clk);
        finish_cnt = 0;
        rst_n = 1'b0; repeat (2) @(negedge clk); rst_n = 1'b1;
        repeat (12*BIT_CYCLES) @(negedge clk);
        if (uart_tx !== 1'b1 || finish_cnt != 0) begin
            $display("ERROR [S4 reset mid-frame]"); errors++;
        end else $display("PASS  [S4 reset mid-frame]");
        // Scenario 5 - Normal byte after reset
        send_and_check(8'h3C, "S5 byte after reset");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule
