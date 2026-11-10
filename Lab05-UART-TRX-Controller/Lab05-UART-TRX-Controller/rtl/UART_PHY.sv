`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   UART_PHY
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   TX PHY: serializes a byte as start bit, 8 data bits (LSB first) and
//                stop bit at BIT_CYCLES per bit.
//////////////////////////////////////////////////////////////////////////////////

module UART_PHY #(
    parameter int BIT_CYCLES = 1736
)(
    input logic clk, rst_n,
    input logic [7:0] tx_byte,
    input logic tx_send,
    output logic uart_tx,
    output logic PHY_finish
    );
    
    logic [7:0] shift_reg;
    localparam int cycle_cnt = $clog2(BIT_CYCLES);
    logic [cycle_cnt-1:0] cyc_cnt;
    logic [3:0] index_cnt;
    
    typedef enum logic {IDLE, SENDING} state_t;
    state_t state, next; 
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin       
            state <= IDLE;
        end else
            state <= next;
    end        
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            uart_tx <= 1'b1;
            PHY_finish <= 1'b0;
            shift_reg <= 8'b0;
            cyc_cnt <= '0;
            index_cnt <= 4'b0;
        end else begin 
            PHY_finish <= (state == SENDING) && (next == IDLE);
            unique case (next)
                IDLE: uart_tx <= 1'b1;
                SENDING: begin
                    case (index_cnt)
                    4'd0: uart_tx <= 1'b0;
                    4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8: uart_tx <= shift_reg[0];
                    4'd9: uart_tx <= 1'b1;
                    default: uart_tx <= 1'b1;
                    endcase
                end
            endcase
            
            unique case (state)
            IDLE: begin
                if(tx_send) begin
                    shift_reg <= tx_byte;
                    cyc_cnt <= '0;
                    index_cnt <= 4'b0;
                end
            end
            SENDING: begin
                if (cyc_cnt == BIT_CYCLES-1) begin
                    cyc_cnt <= '0;
                    index_cnt <= index_cnt + 4'd1;
                    if (index_cnt >= 4'd1 && index_cnt <= 4'd8) 
                        shift_reg <= shift_reg >> 1;
                end else begin
                    cyc_cnt <= cyc_cnt + 1'b1;
               end
            end        
            endcase            
         end
     end   
     
     always_comb begin
        unique case (state)
            IDLE: next = tx_send ? SENDING : IDLE;
            SENDING: next = (index_cnt == 4'd9 && cyc_cnt == BIT_CYCLES - 1) ? IDLE : SENDING;
        endcase
     end
endmodule
