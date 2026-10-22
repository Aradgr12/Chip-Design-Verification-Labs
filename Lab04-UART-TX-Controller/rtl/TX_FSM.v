`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Course:        Chip Design & Verification - Reichman University & Google
// Project:       Lab 4 - UART TX Controller
// Module:        TX_FSM
// Target Device: Nexys A7-100T (xc7a100tcsg324-1)
// Tool:          Vivado
// Description:   Main transmit FSM (Moore, 3 always blocks, registered
//                outputs). Sends an NxN square of the selected character: N
//                chars per row separated by spaces, CR LF after every row
//                except the last, and the selected delay after every data
//                character.
//////////////////////////////////////////////////////////////////////////////////

module TX_FSM #(

    parameter DELAY_50MS = 5000000,
    parameter DELAY_100MS = 10000000,
    parameter DELAY_200MS = 20000000
)(
    input wire clk, rst_n,
    input wire [7:0] char_latched,
    input wire [1:0] delay_latched,
    input wire [1:0] size_latched,
    input wire latched,
    input wire PHY_finish,
    output reg [7:0] tx_byte,
    output reg tx_send,
    output reg tx_busy,
    output reg data_byte_sent,
    output reg led_byte,
    output reg led_done
);

    // State encoding (Vivado re-encodes it to one-hot during synthesis)
    localparam [2:0] IDLE = 3'b000;
    localparam [2:0] SEND_CHAR = 3'b001;
    localparam [2:0] WAIT_DELAY = 3'b010;
    localparam [2:0] SEND_SPACE= 3'b011;
    localparam [2:0] SEND_CR = 3'b100;
    localparam [2:0] SEND_LF = 3'b101;
    
    reg [2:0] state, next;
    reg [24:0] delay_cnt;   // 25 bits cover 20,000,000 (200 ms)
    reg [8:0] char_cnt;   // data chars sent in the current row (up to 256)
    reg [7:0] line_cnt;   // completed rows (CR+LF sent)
    wire [8:0] row_height;
    wire [24:0] delay_target;
    wire delay_done;
    wire last_char;
    wire last_line;
    
    // Row length (= number of rows) according to the latched size
    assign row_height = (size_latched == 2'd0) ? 9'd1 : 
                        (size_latched == 2'd1) ? 9'd32 :
                        (size_latched == 2'd2) ? 9'd128 : 9'd256;
                        
    // Delay length in clock cycles according to the latched delay
    assign delay_target = (delay_latched == 2'd0) ? 25'd0 :
                          (delay_latched == 2'd1) ? DELAY_50MS :
                          (delay_latched == 2'd2) ? DELAY_100MS : DELAY_200MS;  
                          
    assign delay_done = (delay_target == 25'b0) || (delay_cnt == delay_target - 1);   // zero delay passes immediately
    assign last_char = (char_cnt == row_height);   // all data chars of the row were sent
    assign last_line = (line_cnt == row_height - 1);   // current row is the last one
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin       
            state <= IDLE;
        end else
            state <= next;
    end
    
    // Registered outputs (decoded from next state) and datapath counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_byte <= 8'b0;
            tx_send <= 1'b0;
            tx_busy <= 1'b0;
            data_byte_sent <= 1'b0;
            delay_cnt <= 25'b0;
            char_cnt <= 9'b0;
            line_cnt <= 8'b0;
            led_byte <= 1'b0;
            led_done <= 1'b0;
        end else begin
            case (next)
                IDLE: tx_byte <= 8'h0;
                WAIT_DELAY: tx_byte <= 8'h0;
                SEND_CHAR: tx_byte <= char_latched;
                SEND_SPACE: tx_byte <= 8'h20;
                SEND_CR: tx_byte <= 8'h0D;
                SEND_LF: tx_byte <= 8'h0A;
                default: tx_byte <= 8'h00;
                endcase
                
                tx_busy <= (next != IDLE);   // high from start until the last delay ends
                // One-cycle send request on entry to any SEND state
                tx_send <= ((next == SEND_CHAR) || (next == SEND_SPACE) || (next == SEND_CR) || (next == SEND_LF)) && (next != state);
                data_byte_sent <= (state == SEND_CHAR) && (PHY_finish);   // data chars only (not spaces / CR / LF)
                
                // led_byte toggles per data char, cleared on a new start
                if (latched) begin
                    led_byte <= 1'b0;
                end else if ((state == SEND_CHAR) && (PHY_finish)) begin
                    led_byte <= ~led_byte;
                end 
                
                // led_done: on at completion, off at the next start
                if ((state == WAIT_DELAY) && (next == IDLE)) begin
                    led_done <=1'b1;
                end else if ((state == IDLE) && (next == SEND_CHAR)) begin
                    led_done <= 1'b0;
                end              
            // Row / line counters
            case (state)
                IDLE: begin
                char_cnt <= 9'b0; 
                line_cnt <= 8'b0;
                end
                SEND_CHAR: if (PHY_finish) begin   
                    char_cnt <= char_cnt + 9'd1;
                end
                SEND_LF: if (PHY_finish) begin
                    char_cnt <= 9'b0;
                    line_cnt <= line_cnt + 8'd1;
               end 
               default: ;
            endcase   
            // Delay counter runs only in WAIT_DELAY
            delay_cnt <= (state == WAIT_DELAY) ? delay_cnt + 25'd1 : 25'b0;
            end                  
    end    
    
    // Next-state logic
    always @(*) begin   
        case (state)
            IDLE: next = (latched) ? SEND_CHAR : IDLE;
            SEND_CHAR: next = (PHY_finish) ? WAIT_DELAY : SEND_CHAR;
            WAIT_DELAY: next = (!delay_done) ? WAIT_DELAY :   // after each data char: delay, then space / CR+LF / done
                               (!last_char) ? SEND_SPACE : 
                               (!last_line) ? SEND_CR : IDLE;
            SEND_SPACE: next = (PHY_finish) ? SEND_CHAR : SEND_SPACE;
            SEND_CR: next = (PHY_finish) ? SEND_LF : SEND_CR;
            SEND_LF: next = (PHY_finish) ? SEND_CHAR : SEND_LF;
            default: next = IDLE;
        endcase
    end                                                       
endmodule
