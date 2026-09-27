`timescale 1ns / 1ps

module Adder_8bit_str(
    input  wire [7:0] a, b,
    input  wire       Cin,
    output wire [7:0] sum,
    output wire       Cout
    );

    wire [8:0] carry;
    assign carry[0] = Cin;
    assign Cout      = carry[8];

    Full_Adder fa0 (.x(a[0]), .y(b[0]), .z(carry[0]), .S(sum[0]), .C(carry[1]));
    Full_Adder fa1 (.x(a[1]), .y(b[1]), .z(carry[1]), .S(sum[1]), .C(carry[2]));
    Full_Adder fa2 (.x(a[2]), .y(b[2]), .z(carry[2]), .S(sum[2]), .C(carry[3]));
    Full_Adder fa3 (.x(a[3]), .y(b[3]), .z(carry[3]), .S(sum[3]), .C(carry[4]));
    Full_Adder fa4 (.x(a[4]), .y(b[4]), .z(carry[4]), .S(sum[4]), .C(carry[5]));
    Full_Adder fa5 (.x(a[5]), .y(b[5]), .z(carry[5]), .S(sum[5]), .C(carry[6]));
    Full_Adder fa6 (.x(a[6]), .y(b[6]), .z(carry[6]), .S(sum[6]), .C(carry[7]));
    Full_Adder fa7 (.x(a[7]), .y(b[7]), .z(carry[7]), .S(sum[7]), .C(carry[8]));

endmodule



