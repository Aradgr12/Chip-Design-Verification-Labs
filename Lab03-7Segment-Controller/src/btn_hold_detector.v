`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Arad Greenshtein
// 
// Create Date: 10/09/2026 03:01:01 PM
// Design Name: lab3_seg7_controller
// Module Name: btn_hold_detector
// Project Name: LAB 3 
// Target Devices: NEXYS A7 100T
// Tool Versions: 01    
// Description: Synchronizes the push-buttons, detects a 1 sec hold and issues a single latch pulse per press
// 
// Revision: 01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module btn_hold_detector #(
    parameter HOLD_TICKS = 400          // 400 ticks of 400Hz = 1 sec (reduced in simulation)
)(
    input  wire clk, rst_n,             // 100MHz clock, active-low async reset
    input  wire btn_c, btn_d,           // raw push-buttons (asynchronous, active high)
    input  wire tick,                   // 400Hz enable pulse from tick_gen
    output wire latch_en,               // one-cycle pulse: latch the switches now
    output wire mode_dec                // 1 = decimal (Center), 0 = hex (Down)
    );

    // Synchronizers: 2 D-FFs per button against metastability
    reg btn_c_meta, btn_c_sync;
    reg btn_d_meta, btn_d_sync;

    // Button state: at least one (synchronized) button is pressed
    wire any_btn;

    // Hold counter: counts ticks while a button is held (9 bits, up to 511)
    reg  [8:0] cnt;
    wire       sec_flag;                // counter reached HOLD_TICKS

    // FSM states: WAIT = waiting for a full 1 sec hold, LOCKED = already latched, waiting for release
    localparam WAIT   = 1'b0;
    localparam LOCKED = 1'b1;
    reg state;

    // ---- Synchronizers ----
    // Only the *_sync signals are used by the rest of the logic; *_meta may be metastable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_c_meta <= 1'd0;
            btn_c_sync <= 1'd0;
            btn_d_meta <= 1'd0;
            btn_d_sync <= 1'd0;
        end else begin
            btn_c_meta <= btn_c;        // 1st FF samples the asynchronous button
            btn_c_sync <= btn_c_meta;   // 2nd FF: one full cycle to settle
            btn_d_meta <= btn_d;
            btn_d_sync <= btn_d_meta;
        end
    end

    // ---- FSM: guarantees a single latch per press ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= WAIT;
        end else begin
            case (state)
                WAIT: begin
                    if (sec_flag) begin // full 1 sec hold detected
                        state <= LOCKED;
                    end else begin
                        state <= WAIT;
                    end
                end

                LOCKED: begin
                    if (!any_btn) begin // both buttons released -> ready for a new press
                        state <= WAIT;
                    end else begin
                        state <= LOCKED;
                    end
                end

                default: state <= WAIT; // safe recovery state
            endcase
        end
    end

    // ---- Hold counter ----
    // Resets on release, so short presses never accumulate to 1 sec.
    // Also filters button bouncing: every bounce restarts the count.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 9'd0;
        end else if (!any_btn) begin
            cnt <= 9'd0;
        end else if (tick) begin        // advance only on the 400Hz enable
            cnt <= cnt + 9'd1;
        end
    end

    assign any_btn  = btn_c_sync | btn_d_sync;
    assign sec_flag = (cnt == HOLD_TICKS);
    assign mode_dec = btn_c_sync;                   // Center has priority when both are pressed
    assign latch_en = (state == WAIT) && sec_flag;  // only on WAIT -> LOCKED: one pulse per press

endmodule
