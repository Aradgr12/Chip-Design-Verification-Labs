`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        Debouncer
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Synchronizes the center push-button (2 FFs) and filters
//                contact bounce. A press must stay stable for BTN_CYCLES clocks
//                (15 ms) before a single one-cycle btn_pulse is produced;
//                WAIT/LOCKED FSM prevents repeats while held.
//////////////////////////////////////////////////////////////////////////////////

module Debouncer #(
    parameter BTN_CYCLES = 1500000
)(
    input wire clk, rst_n,
    input wire btn_c,
    output wire btn_pulse
    );
    
    // 2-FF synchronizer for the asynchronous button input
    reg btn_c_meta, btn_c_sync;

    // Button state
    wire any_btn;
    
    // Counts consecutive cycles with the button held (saturates at BTN_CYCLES)
    reg  [20:0]stable_cnt;   // 21 bits cover 1,500,000
    wire       stable_flag;
    
    // FSM: WAIT = ready for a new press, LOCKED = press reported, wait for release
    localparam WAIT   = 1'b0;
    localparam LOCKED = 1'b1;
    reg state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_c_meta <= 1'd0;
            btn_c_sync <= 1'd0;
         end else begin
            btn_c_meta <= btn_c;
            btn_c_sync <= btn_c_meta;
         end
     end
     
     always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT;
        end else begin
            case (state)
                WAIT: begin
                    if (stable_flag) begin
                        state <= LOCKED;
                    end else begin
                        state <= WAIT;
                end
             end
                                
                LOCKED: begin
                    if (!any_btn) begin
                        state <= WAIT;
                    end else begin
                        state <= LOCKED;
                    end
                 end
                 
                 default: state <= WAIT;
                 
              endcase      
         end
     end
     
     always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_cnt <= 21'd0;
        end else if (!any_btn) begin
            stable_cnt <= 21'd0;
        end else if (stable_cnt < BTN_CYCLES) begin
            stable_cnt <= stable_cnt + 21'd1;
        end
     end
     
    assign any_btn = btn_c_sync;
    assign stable_flag = (stable_cnt == BTN_CYCLES);
    assign btn_pulse = (state == WAIT) && stable_flag;   // one-cycle pulse: FSM moves to LOCKED on the next edge
     
endmodule
