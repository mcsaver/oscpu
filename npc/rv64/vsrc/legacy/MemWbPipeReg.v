`include "define.v"

module MemWbPipeReg (
  input clk,
  input rst,
  input load_i,
  input [`XLEN-1:0] load_pc_i,
  input [`INST_W-1:0] load_inst_i,
  input [`XLEN-1:0] load_next_pc_i,
  input load_rd_en_i,
  input load_need_wb_i,
  input [`REG_ADDR_W-1:0] load_rd_idx_i,
  input [`XLEN-1:0] load_wb_data_i,
  output reg valid_o,
  output reg [`XLEN-1:0] pc_o,
  output reg [`INST_W-1:0] inst_o,
  output reg [`XLEN-1:0] next_pc_o,
  output reg rd_en_o,
  output reg need_wb_o,
  output reg [`REG_ADDR_W-1:0] rd_idx_o,
  output reg [`XLEN-1:0] wb_data_o
);

  always @(posedge clk) begin
    if (rst) begin
      valid_o <= 1'b0;
      pc_o <= {`XLEN{1'b0}};
      inst_o <= {`INST_W{1'b0}};
      next_pc_o <= `RESET_PC;
      rd_en_o <= 1'b0;
      need_wb_o <= 1'b0;
      rd_idx_o <= {`REG_ADDR_W{1'b0}};
      wb_data_o <= {`XLEN{1'b0}};
    end else begin
      valid_o <= 1'b0;
      if (load_i) begin
        valid_o <= 1'b1;
        pc_o <= load_pc_i;
        inst_o <= load_inst_i;
        next_pc_o <= load_next_pc_i;
        rd_en_o <= load_rd_en_i;
        need_wb_o <= load_need_wb_i;
        rd_idx_o <= load_rd_idx_i;
        wb_data_o <= load_wb_data_i;
      end
    end
  end

endmodule
