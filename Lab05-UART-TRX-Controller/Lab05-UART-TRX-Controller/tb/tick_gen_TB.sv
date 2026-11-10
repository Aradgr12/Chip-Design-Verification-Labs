`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   tick_gen_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for tick_gen: tick interval monitor, first interval
//                after reset, reset mid-interval.
//////////////////////////////////////////////////////////////////////////////////

module tick_gen_TB;
    
    logic clk, rst_n;
    logic refresh_tick;
    
    localparam int MAX = 3;

    always #5 clk = ~clk;
    
    tick_gen #(.MAX(MAX)) tick_gen_TB_DUT(
        .clk(clk),
        .rst_n(rst_n),
        .refresh_tick(refresh_tick)
    );
    
    int pulse_space_cnt = '0;
    logic first_tick = '0;
    int errors = 0;
        
    task automatic clock_cycles_check (input int exp, input string name);
        if (pulse_space_cnt !== exp) begin
            $display("ERROR [%s] t=%0t: got %0d clock cycles, expected %0d",  name, $time, pulse_space_cnt, exp);
            errors ++;
        end else begin
             $display("PASS  [%s]: %0d clock cycles", name, pulse_space_cnt);
        end
        pulse_space_cnt = 32'd1;
    endtask
    
    task automatic reset_block (input int cycles);
        rst_n = 1'b0;
        repeat (cycles) @(negedge clk); 
        pulse_space_cnt = 0;
        first_tick = 1'b0;
        rst_n = 1'b1;
    endtask
    
    always @(posedge clk) begin
        if (refresh_tick) begin
            if (first_tick) 
                clock_cycles_check(MAX + 1, "interval");
            else 
                clock_cycles_check (MAX, "first interval");
                
            first_tick = 1'b1;
            end else begin
                pulse_space_cnt++;
            end      
      end
      
      assert property (@(posedge clk) disable iff (!rst_n)
          refresh_tick |=> !refresh_tick)
      else $error("refresh_tick is wider than clock cycle at t=%0t", $time);

      assert property (@(posedge clk)
         !rst_n |-> !refresh_tick)
      else $error("refresh_tick during reset at t=%0t", $time);
      
      initial begin 
        clk = 0;
        reset_block (2);
        
        // Scenario 1 - Free run: first interval = MAX, then every interval = MAX+1
        repeat (5*(MAX+1)) @(negedge clk);
        
        // Scenario 2 - Reset mid-interval: partial count is discarded, first interval after reset = MAX, then MAX+1
        @(posedge refresh_tick);
        repeat (MAX) @(negedge clk);
        reset_block(2);
        repeat (5*(MAX + 1)) @(negedge clk);
       
        if (errors == 0) $display("TEST PASSED");
        else $display("TEST FAILED: %0d errors", errors);
        
        $finish;
     end   
endmodule
