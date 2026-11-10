`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   bytes_counter_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for bytes_counter: rows for every square size, 256
//                rows wrap, latch clears.
//////////////////////////////////////////////////////////////////////////////////

module bytes_counter_TB;

    logic clk = 1'b0;
    logic rst_n, data_byte_sent, latched;
    logic [1:0] size_latched;
    logic [7:0] rows_cnt;

    always #5 clk = ~clk;

    bytes_counter bytes_counter_TB_DUT (
        .clk(clk),
        .rst_n(rst_n),
        .data_byte_sent(data_byte_sent),
        .latched(latched),
        .size_latched(size_latched),
        .rows_cnt(rows_cnt)
    );

    int errors = 0;

    // Expected rows for a number of data bytes: bytes / row length, truncated to 8 bits
    function automatic logic [7:0] exp_rows(input int bytes, input logic [1:0] size);
        int shift;
        shift = (size == 2'd0) ? 0 : (size == 2'd1) ? 5 : (size == 2'd2) ? 7 : 8;
        return 8'(bytes >> shift);
    endfunction

    // rows_cnt changes only after a data byte or a new latch
    assert property (@(posedge clk) disable iff (!rst_n)
        (rows_cnt != $past(rows_cnt)) |-> $past(data_byte_sent || latched))
        else begin $error("rows_cnt changed without a byte or latch at t=%0t", $time); errors++; end

    task automatic new_square(input logic [1:0] size);
        @(negedge clk);
        size_latched = size; latched = 1'b1;
        @(negedge clk);
        latched = 1'b0;
    endtask

    task automatic send_bytes(input int count);
        repeat (count) begin
            @(negedge clk) data_byte_sent = 1'b1;
            @(negedge clk) data_byte_sent = 1'b0;
        end
        @(negedge clk);
    endtask

    task automatic check(input int bytes, input string name);
        if (rows_cnt !== exp_rows(bytes, size_latched)) begin
            $display("ERROR [%s]: rows_cnt=%h, expected %h", name, rows_cnt, exp_rows(bytes, size_latched)); errors++;
        end else $display("PASS  [%s]: rows_cnt=%h", name, rows_cnt);
    endtask

    initial begin
        rst_n = 1'b0; data_byte_sent = 1'b0; latched = 1'b0; size_latched = '0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Scenario 1 - Single byte: 1 row
        new_square(2'd0); send_bytes(1);         check(1, "S1 single byte");
        // Scenario 2 - 32x32: 1024 bytes -> 0x20 rows
        new_square(2'd1); send_bytes(1024);      check(1024, "S2 32x32");
        // Scenario 3 - 128x128: 16384 bytes -> 0x80 rows
        new_square(2'd2); send_bytes(16384);     check(16384, "S3 128x128");
        // Scenario 4 - 256x256: 65536 bytes -> 256 rows, shown as 00 (2-digit display)
        new_square(2'd3); send_bytes(65536);     check(65536, "S4 256x256 wraps to 00");
        // Scenario 5 - New latch clears the count
        new_square(2'd1);                        check(0, "S5 latch clears");

        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d errors", errors);
        $finish;
    end

endmodule
