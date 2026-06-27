`include "define.v"

module OooPendingBranchSequencer (
  input clk,
  input rst,

  input late_clear_i,
  input clear_i,
  input clear_dispatched_i,

  input capture_direct_i,
  input capture_direct_valid_i,
  input [`XLEN-1:0] capture_direct_pc_i,
  input [`XLEN-1:0] capture_direct_next_pc_i,
  input [`INST_W-1:0] capture_direct_inst_i,
  input [`REG_ADDR_W-1:0] capture_direct_rs1_i,
  input [`REG_ADDR_W-1:0] capture_direct_rs2_i,
  input [`XLEN-1:0] capture_direct_imm_i,
  input [2:0] capture_direct_cmp_op_i,
  input capture_direct_pred_taken_i,
  input capture_direct_bht_valid_i,
  input [`BPU_BHT_INDEX_W-1:0] capture_direct_bht_idx_i,

  input capture_head0_i,
  input [`XLEN-1:0] capture_head0_pc_i,
  input [`XLEN-1:0] capture_head0_next_pc_i,
  input [`INST_W-1:0] capture_head0_inst_i,
  input [`REG_ADDR_W-1:0] capture_head0_rs1_i,
  input [`REG_ADDR_W-1:0] capture_head0_rs2_i,
  input [`XLEN-1:0] capture_head0_imm_i,
  input [2:0] capture_head0_cmp_op_i,
  input capture_head0_pred_taken_i,
  input capture_head0_bht_valid_i,
  input [`BPU_BHT_INDEX_W-1:0] capture_head0_bht_idx_i,

  input capture_lane1_i,
  input capture_lane1_valid_i,
  input [`XLEN-1:0] capture_lane1_pc_i,
  input [`XLEN-1:0] capture_lane1_next_pc_i,
  input [`INST_W-1:0] capture_lane1_inst_i,
  input [`REG_ADDR_W-1:0] capture_lane1_rs1_i,
  input [`REG_ADDR_W-1:0] capture_lane1_rs2_i,
  input [`XLEN-1:0] capture_lane1_imm_i,
  input [2:0] capture_lane1_cmp_op_i,
  input capture_lane1_pred_taken_i,
  input capture_lane1_bht_valid_i,
  input [`BPU_BHT_INDEX_W-1:0] capture_lane1_bht_idx_i,

  output valid_o,
  output dispatched_o,
  output [`XLEN-1:0] pc_o,
  output [`XLEN-1:0] next_pc_o,
  output [`INST_W-1:0] inst_o,
  output [`REG_ADDR_W-1:0] rs1_o,
  output [`REG_ADDR_W-1:0] rs2_o,
  output [`XLEN-1:0] imm_o,
  output [2:0] cmp_op_o,
  output pred_taken_o,
  output bht_valid_o,
  output [`BPU_BHT_INDEX_W-1:0] bht_idx_o
);

  reg valid_q;
  reg dispatched_q;
  reg [`XLEN-1:0] pc_q;
  reg [`XLEN-1:0] next_pc_q;
  reg [`INST_W-1:0] inst_q;
  reg [`REG_ADDR_W-1:0] rs1_q;
  reg [`REG_ADDR_W-1:0] rs2_q;
  reg [`XLEN-1:0] imm_q;
  reg [2:0] cmp_op_q;
  reg pred_taken_q;
  reg bht_valid_q;
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx_q;

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
      inst_q <= {`INST_W{1'b0}};
      rs1_q <= {`REG_ADDR_W{1'b0}};
      rs2_q <= {`REG_ADDR_W{1'b0}};
      imm_q <= {`XLEN{1'b0}};
      cmp_op_q <= `CMP_OP_NONE;
      pred_taken_q <= 1'b0;
      bht_valid_q <= 1'b0;
      bht_idx_q <= {`BPU_BHT_INDEX_W{1'b0}};
    end else if (late_clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      next_pc_q <= {`XLEN{1'b0}};
    end else if (capture_direct_i) begin
      valid_q <= capture_direct_valid_i;
      dispatched_q <= capture_direct_valid_i;
      pc_q <= capture_direct_pc_i;
      next_pc_q <= capture_direct_next_pc_i;
      inst_q <= capture_direct_inst_i;
      rs1_q <= capture_direct_rs1_i;
      rs2_q <= capture_direct_rs2_i;
      imm_q <= capture_direct_imm_i;
      cmp_op_q <= capture_direct_cmp_op_i;
      pred_taken_q <= capture_direct_pred_taken_i;
      bht_valid_q <= capture_direct_bht_valid_i;
      bht_idx_q <= capture_direct_bht_idx_i;
    end else if (capture_head0_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      pc_q <= capture_head0_pc_i;
      next_pc_q <= capture_head0_next_pc_i;
      inst_q <= capture_head0_inst_i;
      rs1_q <= capture_head0_rs1_i;
      rs2_q <= capture_head0_rs2_i;
      imm_q <= capture_head0_imm_i;
      cmp_op_q <= capture_head0_cmp_op_i;
      pred_taken_q <= capture_head0_pred_taken_i;
      bht_valid_q <= capture_head0_bht_valid_i;
      bht_idx_q <= capture_head0_bht_idx_i;
    end else if (capture_lane1_i) begin
      valid_q <= capture_lane1_valid_i;
      dispatched_q <= 1'b0;
      pc_q <= capture_lane1_pc_i;
      next_pc_q <= capture_lane1_next_pc_i;
      inst_q <= capture_lane1_inst_i;
      rs1_q <= capture_lane1_rs1_i;
      rs2_q <= capture_lane1_rs2_i;
      imm_q <= capture_lane1_imm_i;
      cmp_op_q <= capture_lane1_cmp_op_i;
      pred_taken_q <= capture_lane1_pred_taken_i;
      bht_valid_q <= capture_lane1_bht_valid_i;
      bht_idx_q <= capture_lane1_bht_idx_i;
    end else if (clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      next_pc_q <= {`XLEN{1'b0}};
    end else if (clear_dispatched_i) begin
      dispatched_q <= 1'b0;
    end
  end

  assign valid_o = valid_q;
  assign dispatched_o = dispatched_q;
  assign pc_o = pc_q;
  assign next_pc_o = next_pc_q;
  assign inst_o = inst_q;
  assign rs1_o = rs1_q;
  assign rs2_o = rs2_q;
  assign imm_o = imm_q;
  assign cmp_op_o = cmp_op_q;
  assign pred_taken_o = pred_taken_q;
  assign bht_valid_o = bht_valid_q;
  assign bht_idx_o = bht_idx_q;

endmodule
