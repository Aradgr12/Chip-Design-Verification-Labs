`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   value_latch_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for value_latch: latch when idle, ignore when busy or
//                without press, reset.
//////////////////////////////////////////////////////////////////////////////////

module value_latch_TB;

import uart_pkg::sw_config_t;

    logic clk, rst_n;
    logic btn_pulse;
    logic tx_busy;
    logic [15:0] sw;
    logic [7:0] char_latched;
    logic [1:0] delay_latched;
    logic [1:0] size_latched;
    logic latched;
    logic valid_latched;
    
    always #5 clk = ~clk;
    
    value_latch value_latch_TB_DUT (
    
        .clk(clk),
        .rst_n(rst_n),
        .btn_pulse(btn_pulse),
        .tx_busy(tx_busy),
        .sw(sw),
        .char_latched(char_latched),
        .delay_latched(delay_latched),
        .size_latched(size_latched),
        .latched(latched),
        .valid_latched(valid_latched)
     );

    int errors = 0;
    sw_config_t exp_cfg = '0;
    
    function automatic logic [15:0] make_sw(input logic [7:0] value, input logic [1:0] delay, input logic [1:0] bytes_qty);
        sw_config_t cfg;
        cfg = '0;
        cfg.sw_value = value;
        cfg.sw_delay = delay;
        cfg.sw_bytes_qty = bytes_qty;
        return cfg;
    endfunction 
    
    task automatic press_btn();
        @(negedge clk);
        if (!tx_busy) exp_cfg = sw;
        btn_pulse = 1'b1;
        @(negedge clk);
        btn_pulse = 1'b0;
    endtask
    
   task automatic check_validation (input exp_valid, input string name);
    if (valid_latched !== exp_valid || char_latched !== exp_cfg.sw_value || delay_latched !== exp_cfg.sw_delay || size_latched !== exp_cfg.sw_bytes_qty) begin
        $display ("ERROR [%s] t=%0t : got char=%h delay=%0d size=%0d valid=%b, expected char=%h delay=%0d size=%0d valid=%b",
        name, $time, char_latched, delay_latched, size_latched, valid_latched, exp_cfg.sw_value, exp_cfg.sw_delay, exp_cfg.sw_bytes_qty, exp_valid);
        errors++;
    end else begin
        $display("PASS [%s]: char=%h delay=%0d size=%0d valid=%b", name, char_latched, delay_latched, size_latched, valid_latched);
    end
    endtask
    
    assert property (@(posedge clk) disable iff (!rst_n)
        latched |-> ($past(btn_pulse) && !$past(tx_busy)))
    else $error("latched '1' without a valid press at t=%0t", $time);
    
    assert property (@(posedge clk) disable iff (!rst_n)
        !latched |-> ((char_latched  == $past(char_latched))  && (delay_latched == $past(delay_latched)) && (size_latched  == $past(size_latched))))
    else $error("latched outputs changed without a lock at t=%0t", $time);
    
    assert property (@(posedge clk)
        !rst_n |-> ((char_latched  == '0) && (delay_latched == '0) && (size_latched  == '0) && (latched == '0) && (valid_latched == '0)))
    else $error("outputs not cleared during reset at t=%0t", $time);
    
     initial begin 
        // Initialization - reset asserted, all inputs cleared
        clk = '0;
        rst_n = '0;
        btn_pulse = '0;
        tx_busy = '0;
        sw = '0;
        #100;
        rst_n = 1'b1;
        
        // Scenario 1 - Press while TX idle: latch sw=0x2241 -> char=0x41 ('A'), delay=2, size=1; latched pulses, valid_latched rises
        sw = make_sw(8'h41, 2'd2, 2'd1);
        press_btn();
        repeat (2) @(negedge clk);
        check_validation(1, "S1 latch while TX IDLE");        
        #200;
        
        // Scenario 2 - Switches change without a press: latched outputs must keep the previous values
        sw = make_sw(8'h20, 2'd0, 2'd2);
        repeat (2) @(negedge clk);
        check_validation(1, "S2 change value in SW without pressing the button");
        #200;
        
        // Scenario 3 - Press while TX busy: press ignored, no latched pulse, outputs unchanged
        sw = make_sw(8'h20, 2'd0, 2'd2);
        tx_busy = 1'b1;
        press_btn();
        repeat (2) @(negedge clk);
        tx_busy = 1'b0;
        check_validation(1,"S3 pressed while TX is busy, nothing changed");
        #200;
        
        // Scenario 4 - Press after TX is free: new values latched -> char=0x65 ('e'), delay=1, size=1
        sw = make_sw(8'h65, 2'd1, 2'd1);
        press_btn();
        repeat (2) @(negedge clk);
        check_validation(1, "S4 latch for the second time while TX IDLE");
        #200;
        
        // Scenario 5 - Reset: all outputs cleared, including valid_latched
        sw = make_sw(8'h10, 2'd1, 2'd1);
        press_btn(); #80;
        rst_n = 1'b0;
        #120;
        rst_n = 1'b1;
        #200;
        exp_cfg = '0;
        check_validation(0, "S5 reset after lock");
        
        if (errors == 0) $display("TEST PASSED");
        else $display("TEST FAILED: %0d errors", errors);
        
        $finish;
     end    
endmodule
