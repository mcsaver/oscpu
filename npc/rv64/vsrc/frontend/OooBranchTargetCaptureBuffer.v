`include "define.v"

module OooBranchTargetCaptureBuffer (
  input clk,
  input rst,

  input global_clear_i,
  input frontend_clear_i,
  input hit_clear_enable_i,

  input arm_i,
  input [`XLEN-1:0] arm_branch_pc_i,
  input [`XLEN-1:0] arm_target_pc_i,

  input rsp_valid_i,
  input [`XLEN-1:0] rsp_pc_i,

  output pending_o,
  output [`XLEN-1:0] branch_pc_o,
  output [`XLEN-1:0] target_pc_o,
  output hit_o
);

  reg pending_q;
  reg [`XLEN-1:0] branch_pc_q;
  reg [`XLEN-1:0] target_pc_q;

  assign pending_o = pending_q;
  assign branch_pc_o = branch_pc_q;
  assign target_pc_o = target_pc_q;
  assign hit_o = pending_q && rsp_valid_i && (rsp_pc_i == target_pc_q);

  always @(posedge clk) begin
    if (rst) begin
      pending_q <= 1'b0;
      branch_pc_q <= {`XLEN{1'b0}};
      target_pc_q <= {`XLEN{1'b0}};
    end else if (global_clear_i) begin
      pending_q <= 1'b0;
      branch_pc_q <= {`XLEN{1'b0}};
      target_pc_q <= {`XLEN{1'b0}};
    end else if (arm_i) begin
      pending_q <= 1'b1;
      branch_pc_q <= arm_branch_pc_i;
      target_pc_q <= arm_target_pc_i;
    end else if (frontend_clear_i || (hit_clear_enable_i && hit_o)) begin
      pending_q <= 1'b0;
      branch_pc_q <= {`XLEN{1'b0}};
      target_pc_q <= {`XLEN{1'b0}};
    end
  end

endmodule
