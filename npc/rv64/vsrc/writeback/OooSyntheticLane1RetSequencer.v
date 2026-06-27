`include "define.v"

module OooSyntheticLane1RetSequencer (
  input clk,
  input rst,

  input ret_commit_i,
  input branch_drop_match_i,
  input branch_commit1_i,

  input capture_i,
  input capture_branch_seen_i,
  input capture_branch_drop_i,
  input [`XLEN-1:0] capture_branch_pc_i,
  input [`XLEN-1:0] capture_ret_pc_i,
  input [`XLEN-1:0] capture_ret_next_pc_i,
  input [`INST_W-1:0] capture_ret_inst_i,

  input satp_clear_i,
  input trap_clear_i,

  output ret_pending_o,
  output ret_branch_seen_o,
  output [`XLEN-1:0] ret_branch_pc_o,
  output [`XLEN-1:0] ret_pc_o,
  output [`XLEN-1:0] ret_next_pc_o,
  output [`INST_W-1:0] ret_inst_o,
  output branch_drop_pending_o,
  output [`XLEN-1:0] branch_drop_pc_o
);

  reg ret_pending_q;
  reg ret_branch_seen_q;
  reg [`XLEN-1:0] ret_branch_pc_q;
  reg [`XLEN-1:0] ret_pc_q;
  reg [`XLEN-1:0] ret_next_pc_q;
  reg [`INST_W-1:0] ret_inst_q;
  reg branch_drop_pending_q;
  reg [`XLEN-1:0] branch_drop_pc_q;

  task automatic clear_ret_state;
    begin
      ret_pending_q <= 1'b0;
      ret_branch_seen_q <= 1'b0;
      ret_branch_pc_q <= {`XLEN{1'b0}};
      ret_pc_q <= {`XLEN{1'b0}};
      ret_next_pc_q <= {`XLEN{1'b0}};
      ret_inst_q <= {`INST_W{1'b0}};
      branch_drop_pending_q <= 1'b0;
      branch_drop_pc_q <= {`XLEN{1'b0}};
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      clear_ret_state();
    end else begin
      if (ret_commit_i) begin
        clear_ret_state();
      end else if (branch_drop_match_i) begin
        branch_drop_pending_q <= 1'b0;
        branch_drop_pc_q <= {`XLEN{1'b0}};
      end else if (branch_commit1_i) begin
        ret_branch_seen_q <= 1'b1;
      end

      if (capture_i) begin
        ret_pending_q <= 1'b1;
        ret_branch_seen_q <= capture_branch_seen_i;
        ret_branch_pc_q <= capture_branch_pc_i;
        ret_pc_q <= capture_ret_pc_i;
        ret_next_pc_q <= capture_ret_next_pc_i;
        ret_inst_q <= capture_ret_inst_i;
        if (capture_branch_drop_i) begin
          branch_drop_pending_q <= 1'b1;
          branch_drop_pc_q <= capture_branch_pc_i;
        end
      end

      if (satp_clear_i || trap_clear_i) begin
        clear_ret_state();
      end
    end
  end

  assign ret_pending_o = ret_pending_q;
  assign ret_branch_seen_o = ret_branch_seen_q;
  assign ret_branch_pc_o = ret_branch_pc_q;
  assign ret_pc_o = ret_pc_q;
  assign ret_next_pc_o = ret_next_pc_q;
  assign ret_inst_o = ret_inst_q;
  assign branch_drop_pending_o = branch_drop_pending_q;
  assign branch_drop_pc_o = branch_drop_pc_q;

endmodule
