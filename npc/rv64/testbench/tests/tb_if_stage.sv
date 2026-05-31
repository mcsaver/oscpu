`include "define.v"

module tb_if_stage;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush;
  reg redirect_valid;
  reg [`XLEN-1:0] redirect_pc;
  reg pipe_ready;
  reg halt;
  reg fatal;
  reg bpu_update_valid;
  reg [`XLEN-1:0] bpu_update_pc;
  reg [`INST_W-1:0] bpu_update_inst;
  reg [`XLEN-1:0] bpu_update_seq_pc;
  reg [`XLEN-1:0] bpu_update_next_pc;
  reg bpu_update_taken;
  reg [9:0] bpu_update_bht_idx;
  wire pipe_valid;
  wire [`XLEN-1:0] pipe_pc;
  wire [`INST_W-1:0] pipe_inst;
  wire [`XLEN-1:0] pipe_inst_len;
  wire [`XLEN-1:0] pipe_pred_pc;
  wire [9:0] pipe_bht_idx;
  wire pipe_error;
  wire ifu_req_valid;
  reg ifu_req_ready;
  wire [`XLEN-1:0] ifu_req_addr;
  reg ifu_rsp_valid;
  wire ifu_rsp_ready;
  reg [`XLEN-1:0] ifu_rsp_data;
  reg ifu_rsp_error;
  wire [`XLEN-1:0] fetch_pc;
  wire fetch_pending;

  IfStage dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .redirect_valid_i(redirect_valid),
    .redirect_pc_i(redirect_pc),
    .pipe_ready_i(pipe_ready),
    .halt_i(halt),
    .fatal_i(fatal),
    .bpu_update_valid_i(bpu_update_valid),
    .bpu_update_pc_i(bpu_update_pc),
    .bpu_update_inst_i(bpu_update_inst),
    .bpu_update_seq_pc_i(bpu_update_seq_pc),
    .bpu_update_next_pc_i(bpu_update_next_pc),
    .bpu_update_taken_i(bpu_update_taken),
    .bpu_update_bht_idx_i(bpu_update_bht_idx),
    .pipe_valid_o(pipe_valid),
    .pipe_pc_o(pipe_pc),
    .pipe_inst_o(pipe_inst),
    .pipe_inst_len_o(pipe_inst_len),
    .pipe_pred_pc_o(pipe_pred_pc),
    .pipe_bht_idx_o(pipe_bht_idx),
    .pipe_error_o(pipe_error),
    .ifu_req_valid_o(ifu_req_valid),
    .ifu_req_ready_i(ifu_req_ready),
    .ifu_req_addr_o(ifu_req_addr),
    .ifu_rsp_valid_i(ifu_rsp_valid),
    .ifu_rsp_ready_o(ifu_rsp_ready),
    .ifu_rsp_data_i(ifu_rsp_data),
    .ifu_rsp_error_i(ifu_rsp_error),
    .fetch_pc_o(fetch_pc),
    .fetch_pending_o(fetch_pending)
  );

  task automatic reset_dut;
    begin
      rst = 1'b1;
      flush = 1'b0;
      redirect_valid = 1'b0;
      redirect_pc = 32'h0;
      pipe_ready = 1'b1;
      halt = 1'b0;
      fatal = 1'b0;
      bpu_update_valid = 1'b0;
      bpu_update_pc = 32'h0;
      bpu_update_inst = 32'h0;
      bpu_update_seq_pc = 32'h0;
      bpu_update_next_pc = 32'h0;
      bpu_update_taken = 1'b0;
      bpu_update_bht_idx = 10'h0;
      ifu_req_ready = 1'b1;
      ifu_rsp_valid = 1'b0;
      ifu_rsp_data = 32'h0;
      ifu_rsp_error = 1'b0;
      `TB_TICK(clk);
      rst = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    reset_dut();
    #1;
    tb_check1("reset fetch request", ifu_req_valid, 1'b1);
    tb_check32("reset pc", ifu_req_addr, `RESET_PC);

    ifu_rsp_valid = 1'b1;
    ifu_rsp_data = 32'h0000_0013;
    ifu_rsp_error = 1'b0;
    #1;
    tb_check1("same-cycle rsp to pipe", pipe_valid, 1'b1);
    tb_check32("pipe pc", pipe_pc, `RESET_PC);
    tb_check32("pipe inst", pipe_inst, 32'h0000_0013);
    tb_check32("pipe len", pipe_inst_len, 32'd4);
    tb_check32("pipe pred pc", pipe_pred_pc, `RESET_PC + 32'd4);
    `TB_TICK(clk);
    ifu_rsp_valid = 1'b0;
    #1;
    tb_check1("direct rsp not buffered again", pipe_valid, 1'b0);
    tb_check32("next fetch pc", ifu_req_addr, `RESET_PC + 32'd4);

    pipe_ready = 1'b0;
    ifu_rsp_valid = 1'b1;
    ifu_rsp_data = 32'h0000_0093;
    `TB_TICK(clk);
    ifu_rsp_valid = 1'b0;
    #1;
    tb_check1("backpressure hides pipe", pipe_valid, 1'b0);
    pipe_ready = 1'b1;
    #1;
    tb_check1("backpressure releases pipe", pipe_valid, 1'b1);
    tb_check32("second pipe pc", pipe_pc, `RESET_PC + 32'd4);
    `TB_TICK(clk);

    flush = 1'b1;
    redirect_valid = 1'b1;
    redirect_pc = 32'h8000_0100;
    `TB_TICK(clk);
    flush = 1'b0;
    redirect_valid = 1'b0;
    #1;
    tb_check32("redirect fetch pc", fetch_pc, 32'h8000_0100);
    tb_check1("redirect request", ifu_req_valid, 1'b1);
    tb_check32("redirect req addr", ifu_req_addr, 32'h8000_0100);

    halt = 1'b1;
    #1;
    tb_check1("halt stops request", ifu_req_valid, 1'b0);
    halt = 1'b0;

    tb_finish("tb_if_stage");
  end
endmodule
