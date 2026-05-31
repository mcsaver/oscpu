`include "define.v"

module MemoryStage (
  input clk,
  input rst,
  input update_en_i,
  input clear_i,

  input ex_valid_i,
  input ex_load_i,
  input ex_store_i,
  input [1:0] ex_mem_size_i,
  input ex_mem_unsigned_i,
  input [`XLEN-1:0] ex_mem_addr_i,
  input [`XLEN-1:0] ex_store_data_i,

  output lsu_req_valid_o,
  input lsu_req_ready_i,
  output lsu_req_write_o,
  output [`XLEN-1:0] lsu_req_addr_o,
  output [`XLEN-1:0] lsu_req_wdata_o,
  output [`STRB_W-1:0] lsu_req_wstrb_o,
  input lsu_rsp_valid_i,
  output lsu_rsp_ready_o,
  input [`XLEN-1:0] lsu_rsp_rdata_i,
  input lsu_rsp_error_i,

  output [`XLEN-1:0] load_data_o,
  output response_o,
  output fault_o,
  output pending_o
);

  wire [`XLEN-1:0] lsu_bus_addr_w;
  wire [`XLEN-1:0] lsu_bus_wdata_w;
  wire [`STRB_W-1:0] lsu_bus_wstrb_w;
  wire lsu_misaligned_unused_w;

  MemoryStageControl u_memory_stage_control (
    .clk(clk),
    .rst(rst),
    .update_en_i(update_en_i),
    .clear_i(clear_i),
    .ex_valid_i(ex_valid_i),
    .ex_load_i(ex_load_i),
    .ex_store_i(ex_store_i),
    .lsu_req_valid_o(lsu_req_valid_o),
    .lsu_req_ready_i(lsu_req_ready_i),
    .lsu_rsp_valid_i(lsu_rsp_valid_i),
    .lsu_rsp_ready_o(lsu_rsp_ready_o),
    .lsu_rsp_error_i(lsu_rsp_error_i),
    .response_o(response_o),
    .fault_o(fault_o),
    .pending_o(pending_o)
  );

  LSU u_lsu_mem (
    .eff_addr_i(ex_mem_addr_i),
    .store_data_i(ex_store_data_i),
    .mem_size_i(ex_mem_size_i),
    .mem_unsigned_i(ex_mem_unsigned_i),
    .mem_rdata_i(lsu_rsp_rdata_i),
    .mem_addr_o(lsu_bus_addr_w),
    .mem_wdata_o(lsu_bus_wdata_w),
    .mem_wstrb_o(lsu_bus_wstrb_w),
    .load_data_o(load_data_o),
    .misaligned_o(lsu_misaligned_unused_w)
  );

  assign lsu_req_write_o = ex_store_i;
  assign lsu_req_addr_o = lsu_bus_addr_w;
  assign lsu_req_wdata_o = lsu_bus_wdata_w;
  assign lsu_req_wstrb_o = lsu_bus_wstrb_w;

endmodule
