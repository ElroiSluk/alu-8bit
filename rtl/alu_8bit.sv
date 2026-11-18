`timescale 1ns/1ps

module alu_8bit (
  input  logic [7:0] a, b,
  input  logic [2:0] op,
  output logic [7:0] result,
  output logic carry, zero
);

  // ADD and SUB can be implemented with one adder: a - b = a + ~b + 1
  logic sub;
  logic [7:0] b_in;
  logic [8:0] sum;

  assign sub  = (op == 3'b001);
  assign b_in = sub ? ~b : b;
  assign sum  = a + b_in + sub;

  always_comb begin
    carry  = 1'b0;
    result = '0;
    case (op)
      3'b000,
      3'b001:  {carry, result} = sum;
      3'b010:  result = a & b;
      3'b011:  result = a | b;
      3'b100:  result = a ^ b;
      3'b101:  result = ~a;
      3'b110:  result = a << 1;
      3'b111:  result = a >> 1;
      default: result = 'x;
    endcase
  end

  assign zero = ~|result;

endmodule
