`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   TX_FSM
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   TX MAC: sends an NxN square of the latched char with spaces, CR/LF and
//                inter-byte delays to UART_PHY.
//////////////////////////////////////////////////////////////////////////////////

module TX_FSM 
    import uart_pkg::MAX_ROW, 
    uart_pkg::ASCII_SPACE, 
    uart_pkg::ASCII_LF, 
    uart_pkg::ASCII_CR;
#(

    parameter int DELAY_50MS = 5_000_000,
    parameter int DELAY_100MS = 10_000_000,
    parameter int DELAY_200MS = 20_000_000
)(
    input logic clk, rst_n,
    input logic [7:0] char_latched,
    input logic [1:0] delay_latched,
    input logic [1:0] size_latched,
    input logic latched,
    input logic PHY_finish,
    output logic [7:0] tx_byte,
    output logic tx_send,
    output logic tx_busy,
    output logic data_byte_sent,
    output logic led_byte
);
    
    typedef enum logic [2:0] {IDLE, SEND_CHAR, WAIT_DELAY, SEND_SPACE, SEND_CR, SEND_LF} state_t;
    state_t state, next;
    
    localparam int DELAY_W = $clog2(DELAY_200MS);
    logic [DELAY_W-1:0] delay_cnt;
    
    localparam int CHAR_W = $clog2(MAX_ROW + 1);
    logic [CHAR_W-1:0] char_cnt;          
    logic [CHAR_W-1:0] row_height;
           
    localparam int LINE_W = $clog2(MAX_ROW);    
    logic [LINE_W-1:0] line_cnt;
    
    localparam int TARGET_W = $clog2(DELAY_200MS + 1);
    logic [TARGET_W-1:0] delay_target;
    
    logic delay_done;
    logic last_char;
    logic last_line;
    
    assign row_height = (size_latched == 2'd0) ? 9'd1 : 
                        (size_latched == 2'd1) ? 9'd32 :
                        (size_latched == 2'd2) ? 9'd128 : 9'd256;
                        
    assign delay_target = (delay_latched == 2'd0) ? '0 :
                          (delay_latched == 2'd1) ? DELAY_50MS :
                          (delay_latched == 2'd2) ? DELAY_100MS : DELAY_200MS;  
                          
    assign delay_done = (delay_target == '0) || (delay_cnt == delay_target - 1);
    assign last_char = (char_cnt == row_height);
    assign last_line = (line_cnt == row_height - 1);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin       
            state <= IDLE;
        end else
            state <= next;
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_byte <= 8'b0;
            tx_send <= 1'b0;
            tx_busy <= 1'b0;
            data_byte_sent <= 1'b0;
            delay_cnt <= '0;
            char_cnt <= '0;
            line_cnt <= '0;
            led_byte <= 1'b0;
        end else begin
            unique case (next)
                IDLE: tx_byte <= 8'h0;
                WAIT_DELAY: tx_byte <= 8'h0;
                SEND_CHAR: tx_byte <= char_latched;
                SEND_SPACE: tx_byte <= ASCII_SPACE;
                SEND_CR: tx_byte <= ASCII_CR;
                SEND_LF: tx_byte <= ASCII_LF;
                endcase
                
                tx_busy <= (next != IDLE);
                tx_send <= ((next == SEND_CHAR) || (next == SEND_SPACE) || (next == SEND_CR) || (next == SEND_LF)) && (next != state);
                data_byte_sent <= (state == SEND_CHAR) && (PHY_finish);
                
                if (latched) begin
                    led_byte <= 1'b0;
                end else if ((state == SEND_CHAR) && (PHY_finish)) begin
                    led_byte <= ~led_byte;
                end 
            unique case (state)
                IDLE: begin
                char_cnt <= '0; 
                line_cnt <= '0;
                end
                SEND_CHAR: if (PHY_finish) begin   
                    char_cnt <= char_cnt + 1'b1;
                end
                SEND_LF: if (PHY_finish) begin
                    char_cnt <= '0;
                    line_cnt <= line_cnt + 1'b1;
               end 
               default: ;
            endcase   
            delay_cnt <= (state == WAIT_DELAY) ? delay_cnt + 1'b1 : '0;
            end                  
    end    
    
    always_comb begin   
        next = state;                                   // default: stay
        unique case (state)
            IDLE: next = (latched) ? SEND_CHAR : IDLE;
            SEND_CHAR: next = (PHY_finish) ? WAIT_DELAY : SEND_CHAR;
            WAIT_DELAY: next = (!delay_done) ? WAIT_DELAY : 
                               (!last_char) ? SEND_SPACE : 
                               (!last_line) ? SEND_CR : IDLE;
            SEND_SPACE: next = (PHY_finish) ? SEND_CHAR : SEND_SPACE;
            SEND_CR: next = (PHY_finish) ? SEND_LF : SEND_CR;
            SEND_LF: next = (PHY_finish) ? SEND_CHAR : SEND_LF;
            default: next = IDLE;                       // unused 3-bit encodings
        endcase
    end                                                       
endmodule
