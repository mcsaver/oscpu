module OooControlFlushSequencer (
  input clk,
  input rst,

  input trap_flush_req_i,
  input priv_predictor_boundary_i,
  input backend_drained_i,
  input checkpoint_restore_i,

  output core_trap_flush_o,
  output trap_redirect_squash_o,
  output checkpoint_mem_flush_o
);

  reg core_trap_flush_q;
  reg trap_redirect_squash_q;
  reg checkpoint_mem_flush_q;

  always @(posedge clk) begin
    if (rst) begin
      core_trap_flush_q <= 1'b0;
      trap_redirect_squash_q <= 1'b0;
      checkpoint_mem_flush_q <= 1'b0;
    end else begin
      core_trap_flush_q <= trap_flush_req_i;
      trap_redirect_squash_q <=
          (trap_redirect_squash_q && !backend_drained_i) ||
          priv_predictor_boundary_i;
      checkpoint_mem_flush_q <= checkpoint_restore_i;
    end
  end

  assign core_trap_flush_o = core_trap_flush_q;
  assign trap_redirect_squash_o = trap_redirect_squash_q;
  assign checkpoint_mem_flush_o = checkpoint_mem_flush_q;

endmodule
