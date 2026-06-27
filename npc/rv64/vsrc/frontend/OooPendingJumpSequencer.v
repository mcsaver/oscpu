`include "define.v"

module OooPendingJumpSequencer (
  input clk,
  input rst,

  input late_clear_i,
  input clear_i,
  input clear_dispatched_i,
  input dispatch_fire_i,
  input [`XLEN-1:0] dispatch_target_i,

  input capture_head0_i,
  input capture_head0_jalr_i,
  input [`XLEN-1:0] capture_head0_pc_i,
  input [`XLEN-1:0] capture_head0_next_pc_i,
  input [`INST_W-1:0] capture_head0_inst_i,
  input [`REG_ADDR_W-1:0] capture_head0_rs1_i,
  input [`XLEN-1:0] capture_head0_imm_i,

  input capture_lane1_i,
  input capture_lane1_valid_i,
  input capture_lane1_jalr_i,
  input [`XLEN-1:0] capture_lane1_pc_i,
  input [`XLEN-1:0] capture_lane1_next_pc_i,
  input [`INST_W-1:0] capture_lane1_inst_i,
  input [`REG_ADDR_W-1:0] capture_lane1_rs1_i,
  input [`XLEN-1:0] capture_lane1_imm_i,

  output valid_o,
  output dispatched_o,
  output jalr_o,
  output [`XLEN-1:0] pc_o,
  output [`XLEN-1:0] next_pc_o,
  output [`INST_W-1:0] inst_o,
  output [`REG_ADDR_W-1:0] rs1_o,
  output [`XLEN-1:0] imm_o,
  output [`XLEN-1:0] target_o
);

  reg valid_q;
  reg dispatched_q;
  reg jalr_q;
  reg [`XLEN-1:0] pc_q;
  reg [`XLEN-1:0] next_pc_q;
  reg [`INST_W-1:0] inst_q;
  reg [`REG_ADDR_W-1:0] rs1_q;
  reg [`XLEN-1:0] imm_q;
  reg [`XLEN-1:0] target_q;

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      jalr_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
      inst_q <= {`INST_W{1'b0}};
      rs1_q <= {`REG_ADDR_W{1'b0}};
      imm_q <= {`XLEN{1'b0}};
      target_q <= {`XLEN{1'b0}};
    end else if (late_clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      next_pc_q <= {`XLEN{1'b0}};
    end else if (capture_head0_i) begin
      valid_q <= 1'b1;
      dispatched_q <= 1'b0;
      jalr_q <= capture_head0_jalr_i;
      pc_q <= capture_head0_pc_i;
      next_pc_q <= capture_head0_next_pc_i;
      inst_q <= capture_head0_inst_i;
      rs1_q <= capture_head0_rs1_i;
      imm_q <= capture_head0_imm_i;
      target_q <= {`XLEN{1'b0}};
    end else if (capture_lane1_i) begin
      valid_q <= capture_lane1_valid_i;
      dispatched_q <= 1'b0;
      jalr_q <= capture_lane1_jalr_i;
      pc_q <= capture_lane1_pc_i;
      next_pc_q <= capture_lane1_next_pc_i;
      inst_q <= capture_lane1_inst_i;
      rs1_q <= capture_lane1_rs1_i;
      imm_q <= capture_lane1_imm_i;
      target_q <= {`XLEN{1'b0}};
    end else if (clear_i) begin
      valid_q <= 1'b0;
      dispatched_q <= 1'b0;
      next_pc_q <= {`XLEN{1'b0}};
    end else if (dispatch_fire_i) begin
      dispatched_q <= 1'b1;
      target_q <= dispatch_target_i;
    end else if (clear_dispatched_i) begin
      dispatched_q <= 1'b0;
    end
  end

  assign valid_o = valid_q;
  assign dispatched_o = dispatched_q;
  assign jalr_o = jalr_q;
  assign pc_o = pc_q;
  assign next_pc_o = next_pc_q;
  assign inst_o = inst_q;
  assign rs1_o = rs1_q;
  assign imm_o = imm_q;
  assign target_o = target_q;

endmodule
