module fp_ooc_constant_macro_harness (
  input         clk,
  input         rst,
  input         flush_i,
  input  [63:0] frs1_value_i,
  input  [63:0] frs2_value_i,
  input         sub_op_i,
  input  [2:0]  rm_i,
  output        dynamic_o,
  output        constant_o
);
  wire [63:0] addsub_d_value_q;
  wire [4:0]  addsub_d_fflags_q;
  wire [63:0] addsub_s_value_q;
  wire [4:0]  addsub_s_fflags_q;

  OooFpAddSubPipe u_macro (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .frs1_value_i(frs1_value_i),
    .frs2_value_i(frs2_value_i),
    .sub_op_i(sub_op_i),
    .rm_i(rm_i),
    .addsub_d_value_q_o(addsub_d_value_q),
    .addsub_d_fflags_q_o(addsub_d_fflags_q),
    .addsub_s_value_q_o(addsub_s_value_q),
    .addsub_s_fflags_q_o(addsub_s_fflags_q)
  );

  assign dynamic_o = addsub_d_fflags_q[4];
  assign constant_o = addsub_d_fflags_q[3];
endmodule
