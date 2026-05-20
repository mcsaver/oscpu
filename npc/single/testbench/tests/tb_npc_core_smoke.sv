`include "define.v"

module tb_npc_core_smoke;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  reg clk;
  reg rst;
  wire ifu_req_valid;
  reg ifu_req_ready;
  wire [`XLEN-1:0] ifu_req_addr;
  reg ifu_rsp_valid;
  reg [`XLEN-1:0] ifu_rsp_data;
  reg ifu_rsp_error;
  wire lsu_req_valid;
  reg lsu_req_ready;
  wire lsu_req_write;
  wire [`XLEN-1:0] lsu_req_addr;
  wire [`XLEN-1:0] lsu_req_wdata;
  wire [3:0] lsu_req_wstrb;
  reg lsu_rsp_valid;
  reg [`XLEN-1:0] lsu_rsp_rdata;
  reg lsu_rsp_error;
  wire commit_valid;
  wire [`XLEN-1:0] commit_pc;
  wire [`INST_W-1:0] commit_inst;
  wire [`XLEN-1:0] commit_next_pc;
  wire commit_rd_en;
  wire [`REG_ADDR_W-1:0] commit_rd_addr;
  wire [`XLEN-1:0] commit_rd_data;
  wire trap_valid;
  wire [`TRAP_CAUSE_W-1:0] trap_cause;
  wire [`XLEN-1:0] trap_pc;
  wire [`XLEN-1:0] trap_tval;
  wire exit_valid;
  wire exit_is_ecall;
  wire exit_is_ebreak;
  wire [`XLEN-1:0] exit_code;
  wire halted;
  wire [`XLEN-1:0] debug_pc;
  wire [`CORE_STATE_W-1:0] debug_state;
  wire [`XLEN * `REG_NUM - 1:0] debug_gprs;

  reg ifu_pending;
  reg [`XLEN-1:0] ifu_pending_data;
  reg lsu_pending;
  reg [`XLEN-1:0] lsu_pending_data;
  reg lsu_pending_error;
  integer cycle;
  integer commits;
  integer ifu_seen;

  NpcCore dut (
    .clk(clk),
    .rst(rst),
    .ifu_req_valid_o(ifu_req_valid),
    .ifu_req_ready_i(ifu_req_ready),
    .ifu_req_addr_o(ifu_req_addr),
    .ifu_rsp_valid_i(ifu_rsp_valid),
    .ifu_rsp_data_i(ifu_rsp_data),
    .ifu_rsp_error_i(ifu_rsp_error),
    .lsu_req_valid_o(lsu_req_valid),
    .lsu_req_ready_i(lsu_req_ready),
    .lsu_req_write_o(lsu_req_write),
    .lsu_req_addr_o(lsu_req_addr),
    .lsu_req_wdata_o(lsu_req_wdata),
    .lsu_req_wstrb_o(lsu_req_wstrb),
    .lsu_rsp_valid_i(lsu_rsp_valid),
    .lsu_rsp_rdata_i(lsu_rsp_rdata),
    .lsu_rsp_error_i(lsu_rsp_error),
    .commit_valid_o(commit_valid),
    .commit_pc_o(commit_pc),
    .commit_inst_o(commit_inst),
    .commit_next_pc_o(commit_next_pc),
    .commit_rd_en_o(commit_rd_en),
    .commit_rd_addr_o(commit_rd_addr),
    .commit_rd_data_o(commit_rd_data),
    .trap_valid_o(trap_valid),
    .trap_cause_o(trap_cause),
    .trap_pc_o(trap_pc),
    .trap_tval_o(trap_tval),
    .exit_valid_o(exit_valid),
    .exit_is_ecall_o(exit_is_ecall),
    .exit_is_ebreak_o(exit_is_ebreak),
    .exit_code_o(exit_code),
    .halted_o(halted),
    .debug_pc_o(debug_pc),
    .debug_state_o(debug_state),
    .debug_gprs_o(debug_gprs)
  );

  function [`XLEN-1:0] imem_word;
    input [`XLEN-1:0] addr;
    begin
      case (addr)
        32'h8000_0000: imem_word = rv32_i(12'd5, 5'd0, `FUNCT3_ADD_SUB, 5'd1, `OPCODE_OP_IMM);
        32'h8000_0004: imem_word = rv32_i(12'd7, 5'd1, `FUNCT3_ADD_SUB, 5'd2, `OPCODE_OP_IMM);
        32'h8000_0008: imem_word = rv32_r(`FUNCT7_STD, 5'd2, 5'd1, `FUNCT3_ADD_SUB, 5'd10, `OPCODE_OP);
        32'h8000_000c: imem_word = {12'h001, 5'd0, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
        default:       imem_word = 32'h0000_0013;
      endcase
    end
  endfunction

  task automatic step_core;
    reg next_ifu_pending;
    reg [`XLEN-1:0] next_ifu_data;
    reg next_lsu_pending;
    reg [`XLEN-1:0] next_lsu_data;
    reg next_lsu_error;
    begin
      ifu_rsp_valid = ifu_pending;
      ifu_rsp_data = ifu_pending_data;
      ifu_rsp_error = 1'b0;
      lsu_rsp_valid = lsu_pending;
      lsu_rsp_rdata = lsu_pending_data;
      lsu_rsp_error = lsu_pending_error;

      next_ifu_pending = ifu_req_valid && ifu_req_ready;
      next_ifu_data = imem_word(ifu_req_addr);
      if (next_ifu_pending && (ifu_seen < 16)) begin
        tb_check32("core fill request addr", ifu_req_addr, 32'h8000_0000 + (ifu_seen << 2));
        ifu_seen = ifu_seen + 1;
      end
      next_lsu_pending = lsu_req_valid && lsu_req_ready;
      next_lsu_data = 32'h0;
      next_lsu_error = 1'b0;

      `TB_TICK(clk);

      ifu_pending = next_ifu_pending;
      ifu_pending_data = next_ifu_data;
      lsu_pending = next_lsu_pending;
      lsu_pending_data = next_lsu_data;
      lsu_pending_error = next_lsu_error;

      if (commit_valid) begin
        commits = commits + 1;
        if (commit_pc == 32'h8000_0000) begin
          tb_check1("commit x1 write", commit_rd_en, 1'b1);
          tb_check32("commit x1 rd", {27'b0, commit_rd_addr}, 32'd1);
          tb_check32("commit x1 data", commit_rd_data, 32'd5);
        end else if (commit_pc == 32'h8000_0004) begin
          tb_check32("commit x2 data", commit_rd_data, 32'd12);
        end else if (commit_pc == 32'h8000_0008) begin
          tb_check32("commit x10 rd", {27'b0, commit_rd_addr}, 32'd10);
          tb_check32("commit x10 data", commit_rd_data, 32'd17);
        end
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    ifu_req_ready = 1'b1;
    ifu_rsp_valid = 1'b0;
    ifu_rsp_data = 32'h0;
    ifu_rsp_error = 1'b0;
    lsu_req_ready = 1'b1;
    lsu_rsp_valid = 1'b0;
    lsu_rsp_rdata = 32'h0;
    lsu_rsp_error = 1'b0;
    ifu_pending = 1'b0;
    ifu_pending_data = 32'h0;
    lsu_pending = 1'b0;
    lsu_pending_data = 32'h0;
    lsu_pending_error = 1'b0;
    commits = 0;
    ifu_seen = 0;

    repeat (2) step_core();
    rst = 1'b0;

    for (cycle = 0; cycle < 120 && (ifu_seen < 16) && !trap_valid; cycle = cycle + 1) begin
      step_core();
    end

    tb_check1("no fatal trap during first fill", trap_valid, 1'b0);
    tb_check1("not halted during first fill", halted, 1'b0);
    tb_check1("no data-side request in fetch smoke", lsu_req_valid, 1'b0);
    if (ifu_seen != 16) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] expected 16 first-line fetch requests, got %0d", ifu_seen);
    end

    tb_finish("tb_npc_core_smoke");
  end
endmodule
