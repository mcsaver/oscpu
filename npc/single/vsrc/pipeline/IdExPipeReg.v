`include "define.v"

module IdExPipeReg (
  input clk,
  input rst,
  input clear_i,
  input kill_i,
  input load_i,
  input [`XLEN-1:0] load_pc_i,
  input [`INST_W-1:0] load_inst_i,
  input [`XLEN-1:0] load_inst_len_i,
  input [`XLEN-1:0] load_pred_pc_i,
  input [`BPU_BHT_INDEX_W-1:0] load_bht_idx_i,
  input [`CTRL_BUS_W-1:0] load_ctrl_i,
  input [`XLEN-1:0] load_imm_i,
  input [`REG_ADDR_W-1:0] load_rs1_idx_i,
  input [`REG_ADDR_W-1:0] load_rs2_idx_i,
  input [`REG_ADDR_W-1:0] load_rd_idx_i,
  input [`XLEN-1:0] load_rs1_data_i,
  input [`XLEN-1:0] load_rs2_data_i,
  input load_fetch_error_i,
  output reg valid_o,
  output reg [`XLEN-1:0] pc_o,
  output reg [`INST_W-1:0] inst_o,
  output reg [`XLEN-1:0] inst_len_o,
  output reg [`XLEN-1:0] pred_pc_o,
  output reg [`BPU_BHT_INDEX_W-1:0] bht_idx_o,
  output reg [`CTRL_BUS_W-1:0] ctrl_o,
  output reg [`XLEN-1:0] imm_o,
  output reg [`REG_ADDR_W-1:0] rs1_idx_o,
  output reg [`REG_ADDR_W-1:0] rs2_idx_o,
  output reg [`REG_ADDR_W-1:0] rd_idx_o,
  output reg [`XLEN-1:0] rs1_data_o,
  output reg [`XLEN-1:0] rs2_data_o,
  output reg fetch_error_o
);

  always @(posedge clk) begin
    if (rst) begin
      valid_o <= 1'b0;
      pc_o <= {`XLEN{1'b0}};
      inst_o <= {`INST_W{1'b0}};
      inst_len_o <= `PC_STEP;
      pred_pc_o <= `RESET_PC + `PC_STEP;
      bht_idx_o <= {`BPU_BHT_INDEX_W{1'b0}};
      ctrl_o <= {`CTRL_BUS_W{1'b0}};
      imm_o <= {`XLEN{1'b0}};
      rs1_idx_o <= {`REG_ADDR_W{1'b0}};
      rs2_idx_o <= {`REG_ADDR_W{1'b0}};
      rd_idx_o <= {`REG_ADDR_W{1'b0}};
      rs1_data_o <= {`XLEN{1'b0}};
      rs2_data_o <= {`XLEN{1'b0}};
      fetch_error_o <= 1'b0;
    end else if (clear_i) begin
      valid_o <= 1'b0;
    end else if (load_i) begin
      valid_o <= 1'b1;
      pc_o <= load_pc_i;
      inst_o <= load_inst_i;
      inst_len_o <= load_inst_len_i;
      pred_pc_o <= load_pred_pc_i;
      bht_idx_o <= load_bht_idx_i;
      ctrl_o <= load_ctrl_i;
      imm_o <= load_imm_i;
      rs1_idx_o <= load_rs1_idx_i;
      rs2_idx_o <= load_rs2_idx_i;
      rd_idx_o <= load_rd_idx_i;
      rs1_data_o <= load_rs1_data_i;
      rs2_data_o <= load_rs2_data_i;
      fetch_error_o <= load_fetch_error_i;
    end else if (kill_i) begin
      valid_o <= 1'b0;
    end
  end

endmodule
