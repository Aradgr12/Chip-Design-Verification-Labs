`timescale 1ns / 1ps

module Full_Adder(
    input wire x, y, z,
    output wire S, C
    );
  
assign S = z^(x^y);
assign C = z&(x^y) | (x&y);     
    
endmodule



