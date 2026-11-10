`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   Debouncer_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for Debouncer: clean, long, short and bouncing
//                presses, reset mid-press.
//////////////////////////////////////////////////////////////////////////////////

module Debouncer_TB;

    logic clk, rst_n;
    logic btn_c;
    logic btn_pulse;

    always # 5 clk = ~clk;
    
    Debouncer #(.BTN_CYCLES(10)) Debouncer_TB_DUT(
    
        .clk(clk),
        .rst_n(rst_n),
        .btn_c(btn_c),
        .btn_pulse(btn_pulse)
    );    

    int pulse_cnt = 0;
    int errors = 0;
    
    always @(posedge clk) begin 
        if (btn_pulse) pulse_cnt ++;
    end
        
    assert property (@(posedge clk) disable iff (!rst_n)    
        btn_pulse |=> !btn_pulse)
    else $error("btn_pulse wider than one cycle at t=%0t", $time);
    
    assert property (@(posedge clk)     
        !rst_n |-> !btn_pulse)
    else $error("btn_pulse during reset at t=%0t", $time);
    
    assert property (@(posedge clk) disable iff (!rst_n)
        btn_pulse |-> Debouncer_TB_DUT.btn_sync[1])
    else $error("btn_pulse while button not pressed at t=%0t", $time);
    
    task automatic check_pulses(input int expected, input string name);
        if (pulse_cnt !== expected) begin
            $display("ERROR [%s] t=%0t: got %0d pulses, expected %0d",
                 name, $time, pulse_cnt, expected);
            errors++;
        end else begin
            $display("PASS  [%s]: %0d pulses", name, pulse_cnt);
        end
        pulse_cnt = 0;
    endtask 
    
    task automatic press(input int hold_ns);
        btn_c = 1'b1;
        #hold_ns;
        btn_c = 1'b0;
    endtask
    
    task automatic bounce(input int n, input int width_ns);
        repeat (n) begin
            btn_c = 1'b1;  #width_ns;
            btn_c = 1'b0;  #width_ns;
        end
    endtask
    
    initial begin 
        // reset
        clk = 0;
        rst_n = 0;
        btn_c = 0;
        #20;
        rst_n = 1;
        
        // Scenario 1 - Clean valid press: expect one pulse
        press(120);
        #200;
        check_pulses(1, "S1 valid press");
        
        // Scenario 2 - long press: expect one pulse
        press(360);
        #200;
        check_pulses(1, "S2, long press");
        
        // Scenario 3 - short press : expect zero pulse
        press(30);
        #200;
        check_pulses(0, "S3, short press");
        
        // Scenario 4 - bouncing press then settles high : expect one pulse
        bounce(3,30);
        press(120);
        #200;
        check_pulses(1, "S4, bouncing press");
        
        // Scenario 5 - valid press then bouncing release : expect one pulse
        press(120);
        bounce(2,30);
        #200;
        check_pulses(1, "S5, bouncing release");
        
        // Scenario 6 - two separate presses : expect two pulses
        press(120);
        #100;
        press(120);
        #200;
        check_pulses(2, "S6, two presses");
        
        // Scenario 7 - reset while pressed : expect no pulse in reset, then one pulse because button still pressed
        btn_c = 1'b1;
        #80;
        rst_n = 1'b0;
        #120;
        rst_n = 1'b1;
        #120;
        btn_c = 1'b0;
        #200;
        check_pulses(1, "S7 reset mid-press");
        
        //final report
        if (errors == 0) $display("TEST PASSED");
        else $display("TEST FAILED: %0d errors", errors);
        
        $finish;
    end    
endmodule
