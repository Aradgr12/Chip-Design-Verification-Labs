`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   TX_FSM_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for TX_FSM: emulated PHY, every byte compared to the
//                square model, LED0 and counts.
//////////////////////////////////////////////////////////////////////////////////

module TX_FSM_TB;

    import uart_pkg::ASCII_SPACE, uart_pkg::ASCII_CR, uart_pkg::ASCII_LF;

    localparam int DELAY_50MS  = 4;
    localparam int DELAY_100MS = 8;
    localparam int DELAY_200MS = 16;
    localparam int PHY_CYCLES  = 6;      // emulated UART_PHY frame length

    logic clk = 1'b0;
    logic rst_n;
    logic [7:0] char_latched;
    logic [1:0] delay_latched, size_latched;
    logic latched, PHY_finish;
    logic [7:0] tx_byte;
    logic tx_send, tx_busy, data_byte_sent, led_byte;

    always #5 clk = ~clk;

    TX_FSM #(
        .DELAY_50MS(DELAY_50MS),
        .DELAY_100MS(DELAY_100MS),
        .DELAY_200MS(DELAY_200MS)
    ) TX_FSM_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
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

    int errors    = 0;
    int byte_idx  = 0;       // bytes sent in the current square
    int data_cnt  = 0;       // data bytes (data_byte_sent pulses)
    int n         = 1;       // current square side

    // Expected byte by index: row = char,(space,char)*(n-1),CR,LF; last row without CR,LF
    function automatic logic [7:0] exp_byte(input int idx, input int side);
        int col;
        col = idx % (2*side + 1);
        if (col == 2*side - 1) return ASCII_CR;
        if (col == 2*side)     return ASCII_LF;
        return (col % 2 == 0) ? char_latched : ASCII_SPACE;
    endfunction

    function automatic int square_bytes(input int side);
        return side * (2*side + 1) - 2;
    endfunction

    // Emulated UART_PHY: every tx_send is checked against the model and answered
    // with a 1-cycle PHY_finish after PHY_CYCLES clocks
    always @(posedge clk) begin
        if (tx_send) begin
            if (tx_byte !== exp_byte(byte_idx, n)) begin
                $display("ERROR t=%0t: byte #%0d = %h, expected %h", $time, byte_idx, tx_byte, exp_byte(byte_idx, n));
                errors++;
            end
            byte_idx++;
            fork
                begin
                    repeat (PHY_CYCLES) @(posedge clk);
                    PHY_finish <= 1'b1;
                    @(posedge clk);
                    PHY_finish <= 1'b0;
                end
            join_none
        end
        if (data_byte_sent) data_cnt++;
    end

    // tx_send is a 1-cycle pulse, and only while busy
    assert property (@(posedge clk) disable iff (!rst_n) tx_send |-> tx_busy ##1 !tx_send)
        else begin $error("tx_send not a single pulse during busy at t=%0t", $time); errors++; end

    task automatic run_square(input logic [1:0] size, input int side, input logic [1:0] delay,
                              input logic [7:0] ch, input string name);
        @(negedge clk);
        char_latched = ch; size_latched = size; delay_latched = delay;
        n = side; byte_idx = 0; data_cnt = 0;
        latched = 1'b1;
        @(negedge clk);
        latched = 1'b0;
        wait (tx_busy == 1'b1);
        wait (tx_busy == 1'b0);
        repeat (2*PHY_CYCLES) @(negedge clk);
        if (byte_idx != square_bytes(side) || data_cnt != side*side ||
            led_byte !== ((side*side) % 2 == 1)) begin
            $display("ERROR [%s]: bytes=%0d (exp %0d), data=%0d (exp %0d), led_byte=%b",
                     name, byte_idx, square_bytes(side), data_cnt, side*side, led_byte);
            errors++;
        end else $display("PASS  [%s]: %0d bytes, %0d data bytes", name, byte_idx, data_cnt);
    endtask

    initial begin
        rst_n = 1'b0; latched = 1'b0; PHY_finish = 1'b0;
        char_latched = '0; size_latched = '0; delay_latched = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Scenario 1 - Single byte, no delay: 1 byte, LED0 on
        run_square(2'd0, 1, 2'd0, 8'h41, "S1 single byte");

        // Scenario 2 - 32x32 with delay 50ms (4 cycles): every byte checked, 2078 bytes
        run_square(2'd1, 32, 2'd1, 8'h5A, "S2 32x32 delay 50ms");

        // Scenario 3 - 128x128 with delay 200ms (16 cycles): 32894 bytes, LED0 off (even)
        run_square(2'd2, 128, 2'd3, 8'h33, "S3 128x128 delay 200ms");

        // Scenario 4 - Reset in the middle of a square: busy drops, next square works
        @(negedge clk);
        char_latched = 8'h21; size_latched = 2'd1; delay_latched = 2'd0;
        n = 32; byte_idx = 0;
        latched = 1'b1; @(negedge clk); latched = 1'b0;
        repeat (200) @(negedge clk);
        rst_n = 1'b0; repeat (2) @(negedge clk); rst_n = 1'b1;
        repeat (2*PHY_CYCLES) @(negedge clk);
        if (tx_busy !== 1'b0) begin $display("ERROR [S4 reset mid-square]: still busy"); errors++; end
        else                       $display("PASS  [S4 reset mid-square]");
        run_square(2'd0, 1, 2'd0, 8'h42, "S4 square after reset");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule
