`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        UART_PHY
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   8N1 UART transmitter at 57600 baud (BIT_CYCLES = 1736 clocks
//                per bit). Copies tx_byte on tx_send, shifts it out LSB first
//                with start and stop bits, and pulses PHY_finish at the end of
//                the stop bit.
//////////////////////////////////////////////////////////////////////////////////

module UART_PHY #(
    parameter BIT_CYCLES = 1736
)(
    input wire clk, rst_n,
    input wire [7:0] tx_byte,
    input wire tx_send,
    output reg uart_tx,
    output reg PHY_finish
    );
    
    reg [7:0] shift_reg;
    reg [10:0] cycle_cnt;   // counts BIT_CYCLES per bit (11 bits cover 1736)
    reg [3:0] index_cnt;   // 0=start, 1-8=data, 9=stop (reaches 10 back in IDLE)
    reg state, next;
    
    localparam IDLE = 1'b0;
    localparam SENDING = 1'b1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin       
            state <= IDLE;
        end else
            state <= next;
    end        
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            uart_tx <= 1'b1;
            PHY_finish <= 1'b0;
            shift_reg <= 8'b0;
            cycle_cnt <= 11'b0;
            index_cnt <= 4'b0;
        end else begin 
            // One-cycle pulse at the end of the stop bit
            PHY_finish <= (state == SENDING) && (next == IDLE);
            // Registered line output, driven by the next state and the bit index.
            // Note: index_cnt is 10 after a frame, so the start bit begins one cycle
            // after tx_send; after reset index_cnt is 0, so the first start bit is one cycle longer.
            case (next)
                IDLE: uart_tx <= 1'b1;
                SENDING: begin
                    case (index_cnt)
                    4'd0: uart_tx <= 1'b0;
                    4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8: uart_tx <= shift_reg[0];   // data bits, LSB first
                    4'd9: uart_tx <= 1'b1;
                    default: uart_tx <= 1'b1;
                    endcase
                end
                default: uart_tx <= 1'b1;
            endcase
            
            // Datapath: load byte on tx_send, then count cycles per bit and bits per frame
            case (state)
            IDLE: begin
                if(tx_send) begin
                    shift_reg <= tx_byte;
                    cycle_cnt <= 11'b0;
                    index_cnt <= 4'b0;
                end
            end
            SENDING: begin
                if (cycle_cnt == BIT_CYCLES -1) begin
                    cycle_cnt <= 11'b0;
                    index_cnt <= index_cnt + 4'd1;
                    if (index_cnt >= 4'd1 && index_cnt <= 4'd8)   // shift only after each data bit
                        shift_reg <= shift_reg >> 1;
                end else begin
                    cycle_cnt <= cycle_cnt + 11'd1;
               end
            end        
            endcase            
         end
     end   
     
     // Next-state logic
     always @(*) begin
        case (state)
            IDLE: next = tx_send ? SENDING : IDLE;
            SENDING: next = (index_cnt == 4'd9 && cycle_cnt == BIT_CYCLES - 1) ? IDLE : SENDING;
            default: next = IDLE;
        endcase
     end
endmodule
