`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   RX_PHY_TB
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Self-checking TB for RX_PHY: single and back-to-back bytes, short
//                noise, rx_en off, reset mid-byte.
//////////////////////////////////////////////////////////////////////////////////

module RX_PHY_TB;

    logic clk, rst_n;
    logic uart_rx;
    logic rx_en;
    logic [7:0] rx_byte;
    logic rx_valid;
    
    always #5 clk = ~clk;
    
    localparam int BIT_CYCLE = 64;
    
    RX_PHY #(.BIT_CYCLES(BIT_CYCLE)) RX_PHY_TB_DUT (
        
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .rx_en(rx_en),
        .rx_byte(rx_byte),
        .rx_valid(rx_valid)
    );
    
    int errors = 0;
    int pulse_cnt = 0;
    logic [7:0] exp_byte = '0;
    
    always @(posedge clk) begin
        if (rx_valid) begin
            pulse_cnt = pulse_cnt + 1'b1;
            if(rx_byte !== exp_byte) begin
                $display("there is a error between the byte that sent: %0h and the byte that has been received: %0h", exp_byte, rx_byte);
                errors ++;
            end else begin
                $display("the byte that sent is equal to the byte that has been received");
            end
         end   
     end   
        
        
     task automatic sending_byte (input logic [7:0] data);
           exp_byte = data;
           uart_rx = 1'b0;
           repeat (BIT_CYCLE) @(negedge clk);
           
           for (int i = 0; i < 8; i++) begin
            uart_rx = data[i];
            repeat (BIT_CYCLE) @(negedge clk);
           end
           
           uart_rx = 1'b1;
           repeat (BIT_CYCLE) @(negedge clk);
      endtask
      
      task automatic check_valid_cnt (input int expected, input string name);
        if (pulse_cnt !== expected) begin
            $display("Error [%s] t=%0t: got %0d bytes, expected %0d", name, $time, pulse_cnt, expected);
            errors ++;
        end else begin
            $display ("PASS [%s]: %0d bytes", name, pulse_cnt);
        end
        pulse_cnt = 0;
      endtask
           
      assert property (@(posedge clk)
        rx_valid |=> ~rx_valid)
      else $error("rx_valid is wider than clock cycle at t=%0t", $time);
      
      assert property (@(posedge clk)
        !rst_n |-> !rx_valid)
      else $error("rx_valid worked while reset at t=%0t", $time);      
       
      initial begin
        clk = 0;
        rst_n = 1;
        uart_rx = 1;
        rx_en = 1;
        rst_n = 0; #100;
        rst_n = 1;
        #200;
        
        //Scenario 1 - single byte
        sending_byte(8'h55);
        repeat (2*BIT_CYCLE) @(negedge clk);
        check_valid_cnt (1, "S1 single byte");
        #200;
        
        //Scenario 2 - few bytes in row
        sending_byte(8'h00);
        sending_byte(8'hFF);
        sending_byte(8'hA5);
        repeat (2*BIT_CYCLE) @(negedge clk);
        check_valid_cnt (3, "S2 bytes in a row");
        #200;
        
        //Scenario 3 - noise
        uart_rx = 0;
        repeat (BIT_CYCLE/4) @(negedge clk);
        uart_rx = 1;
        repeat (2*BIT_CYCLE) @(negedge clk);
        check_valid_cnt (0, "S3 short noise");
        #200;
        
        //Scenario 4 - rx_en is '0'
        rx_en = 0;
        sending_byte(8'h10);
        repeat (2*BIT_CYCLE) @(negedge clk);
        check_valid_cnt (0, "S4 rx_en is down");
        rx_en = 1;
        #200;
        
        //Scenerio 5 - reset while sending byte
        uart_rx = 0;
        repeat (BIT_CYCLE) @(negedge clk);
        uart_rx = 1;
        repeat (3*BIT_CYCLE) @(negedge clk);
        
        rst_n = 0;
        uart_rx = 1;
        repeat (5) @(negedge clk);
        rst_n = 1;
        repeat (2*BIT_CYCLE) @(negedge clk);
        check_valid_cnt (0, "S5 reset mid-byte");
        
        sending_byte(8'h3C);
        repeat(2*BIT_CYCLE) @(negedge clk);
        check_valid_cnt (1, "S5 byte after reset");
        
        
        if (errors == 0) $display("TEST PASSED");
        else $display("TEST FAILED: %0d errors", errors);
        
        $finish;
    end                    
endmodule
