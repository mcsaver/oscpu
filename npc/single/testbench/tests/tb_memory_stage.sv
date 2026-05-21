`include "define.v"

module tb_memory_stage;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg update_en;
  reg clear;
  reg ex_valid;
  reg ex_load;
  reg ex_store;
  reg [1:0] ex_mem_size;
  reg ex_mem_unsigned;
  reg [`XLEN-1:0] ex_mem_addr;
  reg [`XLEN-1:0] ex_store_data;
  wire lsu_req_valid;
  reg lsu_req_ready;
  wire lsu_req_write;
  wire [`XLEN-1:0] lsu_req_addr;
  wire [`XLEN-1:0] lsu_req_wdata;
  wire [3:0] lsu_req_wstrb;
  reg lsu_rsp_valid;
  reg [`XLEN-1:0] lsu_rsp_rdata;
  reg lsu_rsp_error;
  wire [`XLEN-1:0] load_data;
  wire response;
  wire fault;
  wire pending;

  MemoryStage dut (
    .clk(clk),
    .rst(rst),
    .update_en_i(update_en),
    .clear_i(clear),
    .ex_valid_i(ex_valid),
    .ex_load_i(ex_load),
    .ex_store_i(ex_store),
    .ex_mem_size_i(ex_mem_size),
    .ex_mem_unsigned_i(ex_mem_unsigned),
    .ex_mem_addr_i(ex_mem_addr),
    .ex_store_data_i(ex_store_data),
    .lsu_req_valid_o(lsu_req_valid),
    .lsu_req_ready_i(lsu_req_ready),
    .lsu_req_write_o(lsu_req_write),
    .lsu_req_addr_o(lsu_req_addr),
    .lsu_req_wdata_o(lsu_req_wdata),
    .lsu_req_wstrb_o(lsu_req_wstrb),
    .lsu_rsp_valid_i(lsu_rsp_valid),
    .lsu_rsp_rdata_i(lsu_rsp_rdata),
    .lsu_rsp_error_i(lsu_rsp_error),
    .load_data_o(load_data),
    .response_o(response),
    .fault_o(fault),
    .pending_o(pending)
  );

  initial begin
    tb_errors = 0;
    clk = 1'b0; rst = 1'b1; update_en = 1'b1; clear = 1'b0;
    ex_valid = 1'b0; ex_load = 1'b0; ex_store = 1'b0;
    ex_mem_size = `MEM_SIZE_BYTE; ex_mem_unsigned = 1'b0;
    ex_mem_addr = 32'h8000_0003; ex_store_data = 32'h0000_00aa;
    lsu_req_ready = 1'b1; lsu_rsp_valid = 1'b0; lsu_rsp_rdata = 32'h8000_ff7f; lsu_rsp_error = 1'b0;
    `TB_TICK(clk);
    rst = 1'b0;

    ex_valid = 1'b1; ex_load = 1'b1; #1;
    tb_check1("load req valid", lsu_req_valid, 1'b1);
    tb_check1("load req write", lsu_req_write, 1'b0);
    tb_check32("load req addr", lsu_req_addr, 32'h8000_0000);
    `TB_TICK(clk); #1;
    tb_check1("load pending", pending, 1'b1);
    lsu_rsp_valid = 1'b1; #1;
    tb_check1("load response", response, 1'b1);
    tb_check32("load signed byte", load_data, 32'hffff_ff80);
    `TB_TICK(clk); lsu_rsp_valid = 1'b0; ex_load = 1'b0; #1;

    ex_load = 1'b1; ex_store = 1'b0; ex_mem_size = `MEM_SIZE_WORD;
    ex_mem_addr = 32'h8000_0000; lsu_rsp_valid = 1'b1; lsu_rsp_rdata = 32'hdead_beef; #1;
    tb_check1("same-cycle load req", lsu_req_valid, 1'b1);
    tb_check1("same-cycle load response", response, 1'b1);
    tb_check32("same-cycle load data", load_data, 32'hdead_beef);
    `TB_TICK(clk); lsu_rsp_valid = 1'b0; ex_load = 1'b0; #1;
    tb_check1("same-cycle load no pending", pending, 1'b0);

    ex_store = 1'b1; ex_mem_size = `MEM_SIZE_HALF; ex_mem_addr = 32'h8000_0002; ex_store_data = 32'h0000_beef; #1;
    tb_check1("store req valid", lsu_req_valid, 1'b1);
    tb_check1("store req write", lsu_req_write, 1'b1);
    tb_check32("store addr", lsu_req_addr, 32'h8000_0000);
    tb_check32("store wdata", lsu_req_wdata, 32'hbeef_0000);
    tb_check32("store wstrb", {28'b0, lsu_req_wstrb}, 32'h0000_000c);
    `TB_TICK(clk); #1;
    lsu_rsp_valid = 1'b1; lsu_rsp_error = 1'b1; #1;
    tb_check1("store fault", fault, 1'b1);
    `TB_TICK(clk); lsu_rsp_valid = 1'b0; lsu_rsp_error = 1'b0; #1;

    tb_finish("tb_memory_stage");
  end
endmodule
