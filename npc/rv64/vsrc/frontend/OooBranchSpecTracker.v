`include "define.v"

module OooBranchSpecTracker (
  input clk,
  input rst,

  input csr_trap_clear_i,

  input direct_frontend_flush_i,
  input direct_branch_fire_i,
  input direct_branch_resolve_redirect_i,
  input direct_branch_spec_start_i,
  input [`XLEN-1:0] direct_branch_pred_pc_i,

  input checkpoint_capture_i,
  input resolve_valid_i,
  input pending_branch_commit_resolve_i,
  input pending_branch_match_clear_i,
  input branch_resolve_untracked_i,

  output active_o,
  output checkpoint_pending_o,
  output [`XLEN-1:0] pred_pc_o
);

  reg active_q;
  reg checkpoint_pending_q;
  reg [`XLEN-1:0] pred_pc_q;

  wire direct_spec_start_w =
      direct_branch_fire_i &&
      !direct_branch_resolve_redirect_i &&
      direct_branch_spec_start_i;

  assign active_o = active_q;
  assign checkpoint_pending_o = checkpoint_pending_q;
  assign pred_pc_o = pred_pc_q;

  always @(posedge clk) begin
    if (rst || csr_trap_clear_i) begin
      active_q <= 1'b0;
      checkpoint_pending_q <= 1'b0;
      pred_pc_q <= {`XLEN{1'b0}};
    end else begin
      if (direct_frontend_flush_i) begin
        active_q <= 1'b0;
        checkpoint_pending_q <= direct_spec_start_w;
        pred_pc_q <= direct_spec_start_w ? direct_branch_pred_pc_i :
                                        {`XLEN{1'b0}};
      end

      if (!direct_frontend_flush_i && checkpoint_capture_i) begin
        checkpoint_pending_q <= 1'b0;
        active_q <= 1'b1;
      end

      if (!direct_frontend_flush_i && resolve_valid_i) begin
        active_q <= 1'b0;
        checkpoint_pending_q <= 1'b0;
        pred_pc_q <= {`XLEN{1'b0}};
      end

      if (pending_branch_commit_resolve_i) begin
        active_q <= 1'b0;
        checkpoint_pending_q <= 1'b0;
        pred_pc_q <= {`XLEN{1'b0}};
      end else if (pending_branch_match_clear_i) begin
        active_q <= 1'b0;
        checkpoint_pending_q <= 1'b0;
        pred_pc_q <= {`XLEN{1'b0}};
      end else if (!direct_frontend_flush_i && branch_resolve_untracked_i) begin
        active_q <= 1'b0;
        checkpoint_pending_q <= 1'b0;
        pred_pc_q <= {`XLEN{1'b0}};
      end
    end
  end

endmodule
