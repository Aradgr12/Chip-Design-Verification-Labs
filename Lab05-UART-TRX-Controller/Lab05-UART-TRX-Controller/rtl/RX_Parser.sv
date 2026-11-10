`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer:      Arad Greenshtein
// Design Name:   LAB 5
// Module Name:   RX_Parser
// Project Name:  UART TRX Controller
// Target Device: Nexys A7-100T
// Language:      SystemVerilog
// Description:   RX MAC: parses {Rddd,Cddd,Vddd}; ignores bytes before {, restarts on
//                {, flags broken format and out-of-range fields.
//////////////////////////////////////////////////////////////////////////////////

module RX_Parser
    import uart_pkg::*;
(
    input  logic       clk, rst_n,
    input  logic [7:0] rx_byte,
    input  logic       rx_valid,
    output logic [7:0] row, col, pix,
    output logic       row_err, col_err, pix_err,   // value out of range (> 255)
    output logic       fmt_err,                     // broken message format
    output logic       msg_done                     // 1-cycle pulse when a message ends
);

    typedef enum logic {WAIT_START, COLLECT} state_t;
    state_t state;

    logic [3:0] idx;                        // position of the expected byte (1..15)
    logic [9:0] acc_row, acc_col, acc_pix;  // decimal accumulators (0..999)
    logic       is_digit;
    logic       byte_ok;

    assign is_digit = (rx_byte >= ASCII_0) && (rx_byte <= ASCII_9);

    // Expected character for every position of the message
    always_comb begin
        unique case (idx)
            4'd1:                       byte_ok = (rx_byte == ASCII_R);
            4'd2, 4'd3, 4'd4,
            4'd7, 4'd8, 4'd9,
            4'd12, 4'd13, 4'd14:        byte_ok = is_digit;
            4'd5, 4'd10:                byte_ok = (rx_byte == ASCII_COMMA);
            4'd6:                       byte_ok = (rx_byte == ASCII_C);
            4'd11:                      byte_ok = (rx_byte == ASCII_V);
            4'd15:                      byte_ok = (rx_byte == ASCII_RBRACE);
            default:                    byte_ok = 1'b0;
        endcase
    end

    // One more decimal digit: acc*10 + digit
    function automatic logic [9:0] add_digit(input logic [9:0] acc, input logic [7:0] ch);
        return acc * 10 + ch[3:0];
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= WAIT_START;
            idx      <= '0;
            acc_row  <= '0;
            acc_col  <= '0;
            acc_pix  <= '0;
            row      <= '0;
            col      <= '0;
            pix      <= '0;
            row_err  <= 1'b0;
            col_err  <= 1'b0;
            pix_err  <= 1'b0;
            fmt_err  <= 1'b0;
            msg_done <= 1'b0;
        end else begin
            msg_done <= 1'b0;                                   // default: 1-cycle pulse
            if (rx_valid) begin
                if (rx_byte == ASCII_LBRACE) begin              // '{' (re)starts a message
                    state   <= COLLECT;
                    idx     <= 4'd1;
                    acc_row <= '0;
                    acc_col <= '0;
                    acc_pix <= '0;
                end else if (state == COLLECT) begin
                    if (!byte_ok) begin                         // broken format
                        fmt_err  <= 1'b1;
                        msg_done <= 1'b1;
                        state    <= WAIT_START;
                    end else begin
                        unique case (idx)
                            4'd2, 4'd3, 4'd4:    acc_row <= add_digit(acc_row, rx_byte);
                            4'd7, 4'd8, 4'd9:    acc_col <= add_digit(acc_col, rx_byte);
                            4'd12, 4'd13, 4'd14: acc_pix <= add_digit(acc_pix, rx_byte);
                            default: ;
                        endcase
                        if (idx == 4'd15) begin                 // '}' - message complete
                            row      <= acc_row[7:0];
                            col      <= acc_col[7:0];
                            pix      <= acc_pix[7:0];
                            row_err  <= (acc_row > 10'd255);
                            col_err  <= (acc_col > 10'd255);
                            pix_err  <= (acc_pix > 10'd255);
                            fmt_err  <= 1'b0;
                            msg_done <= 1'b1;
                            state    <= WAIT_START;
                        end else begin
                            idx <= idx + 1'b1;
                        end
                    end
                end
                // WAIT_START and not '{' -> byte ignored
            end
        end
    end

endmodule
