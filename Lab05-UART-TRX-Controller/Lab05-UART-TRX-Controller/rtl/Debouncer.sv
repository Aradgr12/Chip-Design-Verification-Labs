`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   Debouncer
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   Push-button debouncer: 2-FF synchronizer, saturating hold counter and
//                a single 1-cycle pulse per press.
//////////////////////////////////////////////////////////////////////////////////

module Debouncer #(
    parameter int BTN_CYCLES = 1_500_000
)(
    input logic clk, rst_n,
    input logic btn_c,
    output logic btn_pulse
    );
    
    // Synchronizers
    logic [1:0] btn_sync; 

    // Hold counter
    localparam int CNT_W = $clog2(BTN_CYCLES + 1);
    logic [CNT_W-1:0] stable_cnt;
    logic stable_flag;
    
    // FSM
    typedef enum logic {WAIT, LOCKED} state_t;
    state_t state;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync <= '0;
         end else begin
            btn_sync <= {btn_sync[0], btn_c};
         end
     end
     
     always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT;
        end else begin
            unique case (state)
                WAIT: state <= stable_flag ? LOCKED : WAIT;
                LOCKED: state<= !btn_sync[1] ? WAIT : LOCKED;
            endcase
        end
    end
     
     always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_cnt <= '0;
        end else if (!btn_sync[1]) begin
            stable_cnt <= '0;
        end else if (stable_cnt < BTN_CYCLES) begin
            stable_cnt <= stable_cnt + 1'b1;
        end
     end
     
    assign stable_flag = (stable_cnt == BTN_CYCLES);
    assign btn_pulse = (state == WAIT) && stable_flag;
     
endmodule
