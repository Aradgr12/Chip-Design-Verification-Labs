`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   RX_PHY
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   RX PHY: 2-FF synchronizer, start-bit detection with mid-bit check, 16x
//                oversampling, 1-cycle rx_valid per byte.
//////////////////////////////////////////////////////////////////////////////////

module RX_PHY #(
    parameter int BIT_CYCLES = 1736
)(
    input logic clk, rst_n,
    input logic uart_rx,
    input logic rx_en,
    output logic [7:0] rx_byte,
    output logic rx_valid
    );
    
    localparam int ovs_cycles = (BIT_CYCLES / 16);
    localparam int CYC_W = $clog2(ovs_cycles);
    
    logic [1:0] uart_rx_sync;
    
    typedef enum logic [1:0] {IDLE, START_BIT, RECEIVING} state_t;
    state_t state, next;
    
    logic [CYC_W-1:0] cycles_cnt;
    logic tick;
    logic [3:0] tick_cnt;
    logic [3:0] bit_cnt;    
    logic [7:0] shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else 
            state <= next;
    end        
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            uart_rx_sync <= '1;
        end else begin
            uart_rx_sync <= {uart_rx_sync[0], uart_rx};
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cycles_cnt <= '0;
        end else if (cycles_cnt == ovs_cycles - 1) begin
            cycles_cnt <= '0;
        end else begin
            cycles_cnt <= cycles_cnt + 1'b1;
        end
    end
    
    assign tick = (cycles_cnt == ovs_cycles - 1);        
    
    always_comb begin   
        next = state;
        unique case (state)
            IDLE: if(rx_en && !uart_rx_sync[1])
                    next = START_BIT;
            START_BIT: if(tick && tick_cnt == 4'd7)
                    next = uart_rx_sync[1] ? IDLE : RECEIVING;
            RECEIVING: if(tick && tick_cnt == 4'd15 && bit_cnt == 4'd8)
                    next = IDLE;
            default: next = IDLE;
        endcase
    end
            
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin   
           rx_valid <= 1'b0;
           shift_reg <= 8'b0;
           tick_cnt <= 4'b0;
           bit_cnt <= 4'b0;
        end else begin
           rx_valid <= 1'b0;
           unique case (state)
            IDLE: begin
                tick_cnt <= 4'b0;
                bit_cnt <= 4'b0;
            end
            
            START_BIT: if(tick) begin
                        if(tick_cnt == 4'd7)
                            tick_cnt <=4'b0;
                        else
                            tick_cnt <= tick_cnt + 1'b1;       
            end
            
            RECEIVING: if(tick) begin
                        if(tick_cnt == 4'd15) begin
                            tick_cnt <= 4'b0;
                        if (bit_cnt == 4'd8) begin
                            rx_valid <= 1'b1;
                            bit_cnt <= 4'b0;
                        end else begin 
                            shift_reg <= {uart_rx_sync[1], shift_reg[7:1]};
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                       end else begin 
                            tick_cnt <= tick_cnt + 1'b1;
                       end
            end
            default: ;
           endcase
          end
        end
        assign rx_byte = shift_reg; 
endmodule
