`include "define.v"

module CacheControl (
  input ex_fire_i,
  input fence_i_i,
  input exception_i,
  input [`XLEN-1:0] seq_pc_i,

  output flush_valid_o,
  output [`XLEN-1:0] flush_redirect_pc_o
);

  assign flush_valid_o = ex_fire_i && fence_i_i && ~exception_i;
  assign flush_redirect_pc_o = seq_pc_i;

endmodule
