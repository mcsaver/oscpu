module fp_ooc_constant_output_harness (
  input  wire       clk,
  input  wire       data_i,
  output wire [1:0] data_o,
  output wire       macro_dynamic_o,
  output wire       macro_constant_o
);
  DFFQX1H7L u_dynamic (
    .CK(clk),
    .D(data_i),
    .Q(data_o[0])
  );
  TIELOH7L u_constant (
    .Z(data_o[1])
  );

  fp_ooc_constant_macro_harness u_macro_harness (
    .clk(clk),
    .rst(1'b0),
    .flush_i(1'b0),
    .frs1_value_i(64'b0),
    .frs2_value_i(64'b0),
    .sub_op_i(1'b0),
    .rm_i(3'b0),
    .dynamic_o(macro_dynamic_o),
    .constant_o(macro_constant_o)
  );
endmodule
