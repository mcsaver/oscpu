`include "define.v"

module ExMemPipeReg (
  input clk,
  input rst,
  input clear_i,
  input leave_i,
  input load_i,
  input [`XLEN-1:0] load_pc_i,
  input [`INST_W-1:0] load_inst_i,
  input [`XLEN-1:0] load_next_pc_i,
  input load_is_load_i,
  input load_is_store_i,
  input load_rd_en_i,
  input load_need_wb_i,
  input [1:0] load_mem_size_i,
  input load_mem_unsigned_i,
  input [`REG_ADDR_W-1:0] load_rd_idx_i,
  input [`XLEN-1:0] load_wb_data_i,
  input [`XLEN-1:0] load_mem_addr_i,
  input [`XLEN-1:0] load_store_data_i,
  output reg valid_o,
  output reg [`XLEN-1:0] pc_o,
  output reg [`INST_W-1:0] inst_o,
  output reg [`XLEN-1:0] next_pc_o,
  output reg is_load_o,
  output reg is_store_o,
  output reg rd_en_o,
  output reg need_wb_o,
  output reg [1:0] mem_size_o,
  output reg mem_unsigned_o,
  output reg [`REG_ADDR_W-1:0] rd_idx_o,
  output reg [`XLEN-1:0] wb_data_o,
  output reg [`XLEN-1:0] mem_addr_o,
  output reg [`XLEN-1:0] store_data_o
);

  always @(posedge clk) begin
    if (rst) begin
      valid_o <= 1'b0;
      pc_o <= {`XLEN{1'b0}};
      inst_o <= {`INST_W{1'b0}};
      next_pc_o <= `RESET_PC;
      is_load_o <= 1'b0;
      is_store_o <= 1'b0;
      rd_en_o <= 1'b0;
      need_wb_o <= 1'b0;
      mem_size_o <= `MEM_SIZE_WORD;
      mem_unsigned_o <= 1'b0;
      rd_idx_o <= {`REG_ADDR_W{1'b0}};
      wb_data_o <= {`XLEN{1'b0}};
      mem_addr_o <= {`XLEN{1'b0}};
      store_data_o <= {`XLEN{1'b0}};
    end else if (clear_i) begin
      valid_o <= 1'b0;
    end else begin
      if (leave_i) begin
        valid_o <= 1'b0;
      end

      if (load_i) begin
        valid_o <= 1'b1;
        pc_o <= load_pc_i;
        inst_o <= load_inst_i;
        next_pc_o <= load_next_pc_i;
        is_load_o <= load_is_load_i;
        is_store_o <= load_is_store_i;
        rd_en_o <= load_rd_en_i;
        need_wb_o <= load_need_wb_i;
        mem_size_o <= load_mem_size_i;
        mem_unsigned_o <= load_mem_unsigned_i;
        rd_idx_o <= load_rd_idx_i;
        wb_data_o <= load_wb_data_i;
        mem_addr_o <= load_mem_addr_i;
        store_data_o <= load_store_data_i;
      end
    end
  end

endmodule
