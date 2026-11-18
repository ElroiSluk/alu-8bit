`timescale 1ns/1ps

module tb;
  logic [7:0] a, b;
  logic [2:0] op;
  logic [7:0] result;
  logic       carry, zero;

  int errors = 0;
  int checks = 0;

  alu_8bit dut (
    .a      (a),
    .b      (b),
    .op     (op),
    .result (result),
    .carry  (carry),
    .zero   (zero)
  );

  // Reference model: returns {carry, result}
  // {1'b0, ...} keeps the op 8 bits wide so the carry bit stays 0
  // SUB carry = no borrow (a >= b)
  function automatic logic [8:0] ref_model(input logic [7:0] in_a, in_b,
                                           input logic [2:0] in_op);
    case (in_op)
      3'b000:  return in_a + in_b;
      3'b001:  return {in_a >= in_b, in_a - in_b};
      3'b010:  return {1'b0, in_a & in_b};
      3'b011:  return {1'b0, in_a | in_b};
      3'b100:  return {1'b0, in_a ^ in_b};
      3'b101:  return {1'b0, ~in_a};
      3'b110:  return {1'b0, in_a << 1};
      3'b111:  return {1'b0, in_a >> 1};
      default: return 'x;
    endcase
  endfunction

  task automatic run_test(input logic [7:0] in_a, in_b,
                          input logic [2:0] in_op);
    logic [8:0] expected;
    logic       exp_zero;

    a  = in_a;
    b  = in_b;
    op = in_op;
    #1;
    checks++;

    expected = ref_model(in_a, in_b, in_op);
    exp_zero = (expected[7:0] == 0);

    if (result !== expected[7:0] || carry !== expected[8] || zero !== exp_zero) begin
      errors++;
      if (errors <= 10)
        $display("ERROR: a=%0d b=%0d op=%b got %0d/%b/%b expected %0d/%b/%b",
                 in_a, in_b, in_op, result, carry, zero,
                 expected[7:0], expected[8], exp_zero);
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);

    // Corner cases
    run_test(8'd200, 8'd100, 3'b000);  // ADD with carry
    run_test(8'd255, 8'd1,   3'b000);  // ADD wraps to 0: carry=1, zero=1
    run_test(8'd0,   8'd1,   3'b001);  // SUB borrow: carry=0
    run_test(8'd77,  8'd77,  3'b001);  // SUB result 0: carry=1, zero=1
    run_test(8'd255, 8'd0,   3'b101);  // NOT 255 = 0
    run_test(8'h80,  8'd0,   3'b110);  // SHL drops MSB

    // waveform only for the corner cases, the full sweep would make a huge file
    $dumpoff;

    // All combinations
    for (int i = 0; i < 256; i++)
      for (int j = 0; j < 256; j++)
        for (int k = 0; k < 8; k++)
          run_test(i, j, k);

    $display("Checks run: %0d", checks);
    if (errors == 0)
      $display("*** TEST PASSED ***");
    else
      $display("*** TEST FAILED: %0d errors ***", errors);

    $finish;
  end
endmodule
