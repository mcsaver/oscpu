`include "define.v"

module IfIdPipeReg #(
  parameter BPU_BHT_INDEX_W = 10
) (
  input clk,
  input rst,
  input clear_i,
  input consume_i,
  input load_i,
  input [`XLEN-1:0] load_pc_i,
  input [`INST_W-1:0] load_inst_i,
  input [`XLEN-1:0] load_inst_len_i,
  input [`XLEN-1:0] load_pred_pc_i,
  input [BPU_BHT_INDEX_W-1:0] load_bht_idx_i,
  input load_error_i,
  output reg valid_o,
  output reg [`XLEN-1:0] pc_o,
  output reg [`INST_W-1:0] inst_o,
  output reg [`XLEN-1:0] inst_len_o,
  output reg [`XLEN-1:0] pred_pc_o,
  output reg [BPU_BHT_INDEX_W-1:0] bht_idx_o,
  output reg error_o
);

  always @(posedge clk) begin
    if (rst) begin
      valid_o <= 1'b0;
      pc_o <= {`XLEN{1'b0}};
      inst_o <= {`INST_W{1'b0}};
      inst_len_o <= `PC_STEP;
      pred_pc_o <= `RESET_PC + `PC_STEP;
      bht_idx_o <= {BPU_BHT_INDEX_W{1'b0}};
      error_o <= 1'b0;
    end else if (clear_i) begin
      valid_o <= 1'b0;
    end else if (load_i) begin
      valid_o <= 1'b1;
      pc_o <= load_pc_i;
      inst_o <= load_inst_i;
      inst_len_o <= load_inst_len_i;
      pred_pc_o <= load_pred_pc_i;
      bht_idx_o <= load_bht_idx_i;
      error_o <= load_error_i;
    end else if (consume_i) begin
      valid_o <= 1'b0;
    end
  end

endmodule
