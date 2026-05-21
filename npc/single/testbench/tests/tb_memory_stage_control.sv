`include "define.v"

module tb_memory_stage_control;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg update_en;
  reg clear;
  reg ex_valid;
  reg ex_load;
  reg ex_store;
  wire lsu_req_valid;
  reg lsu_req_ready;
  reg lsu_rsp_valid;
  reg lsu_rsp_error;
  wire response;
  wire fault;
  wire pending;

  MemoryStageControl dut (
    .clk(clk),
    .rst(rst),
    .update_en_i(update_en),
    .clear_i(clear),
    .ex_valid_i(ex_valid),
    .ex_load_i(ex_load),
    .ex_store_i(ex_store),
    .lsu_req_valid_o(lsu_req_valid),
    .lsu_req_ready_i(lsu_req_ready),
    .lsu_rsp_valid_i(lsu_rsp_valid),
    .lsu_rsp_error_i(lsu_rsp_error),
    .response_o(response),
    .fault_o(fault),
    .pending_o(pending)
  );

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    update_en = 1'b1;
    clear = 1'b0;
    ex_valid = 1'b0;
    ex_load = 1'b0;
    ex_store = 1'b0;
    lsu_req_ready = 1'b1;
    lsu_rsp_valid = 1'b0;
    lsu_rsp_error = 1'b0;
    `TB_TICK(clk);
    rst = 1'b0;
    #1;
    tb_check1("reset pending", pending, 1'b0);

    ex_valid = 1'b1; ex_load = 1'b1; #1;
    tb_check1("load req", lsu_req_valid, 1'b1);
    `TB_TICK(clk); #1;
    tb_check1("pending after req", pending, 1'b1);
    tb_check1("no req while pending", lsu_req_valid, 1'b0);

    lsu_rsp_valid = 1'b1; lsu_rsp_error = 1'b0; #1;
    tb_check1("response", response, 1'b1);
    tb_check1("no fault", fault, 1'b0);
    `TB_TICK(clk); lsu_rsp_valid = 1'b0; ex_load = 1'b0; ex_valid = 1'b0; #1;
    tb_check1("pending cleared", pending, 1'b0);

    `TB_TICK(clk);
    lsu_rsp_valid = 1'b0; ex_valid = 1'b1; ex_store = 1'b1; ex_load = 1'b0; #1;
    tb_check1("store req", lsu_req_valid, 1'b1);
    `TB_TICK(clk); #1;
    lsu_rsp_valid = 1'b1; lsu_rsp_error = 1'b1; #1;
    tb_check1("fault response", fault, 1'b1);
    clear = 1'b1; `TB_TICK(clk); clear = 1'b0; lsu_rsp_valid = 1'b0; lsu_rsp_error = 1'b0; #1;
    tb_check1("clear pending", pending, 1'b0);

    ex_store = 1'b0; ex_load = 1'b1; ex_valid = 1'b1;
    lsu_req_ready = 1'b1; lsu_rsp_valid = 1'b1; lsu_rsp_error = 1'b0; #1;
    tb_check1("same-cycle req visible", lsu_req_valid, 1'b1);
    tb_check1("same-cycle response", response, 1'b1);
    tb_check1("same-cycle no fault", fault, 1'b0);
    `TB_TICK(clk);
    lsu_rsp_valid = 1'b0; ex_load = 1'b0; ex_valid = 1'b0; #1;
    tb_check1("same-cycle leaves no pending", pending, 1'b0);

    update_en = 1'b0; ex_valid = 1'b1; ex_store = 1'b1; #1;
    tb_check1("req still visible when update disabled", lsu_req_valid, 1'b1);
    `TB_TICK(clk); #1;
    tb_check1("no state update when disabled", pending, 1'b0);

    tb_finish("tb_memory_stage_control");
  end
endmodule
