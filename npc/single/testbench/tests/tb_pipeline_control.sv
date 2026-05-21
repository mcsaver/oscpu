`include "define.v"

module tb_pipeline_control;
  `include "tb_common.svh"

  reg if_id_valid;
  reg id_ex_valid;
  reg id_ex_load;
  reg id_ex_ecall;
  reg id_ex_ebreak;
  reg id_ex_mret;
  reg id_ex_branch;
  reg id_ex_jal;
  reg id_ex_jalr;
  reg [`REG_ADDR_W-1:0] id_ex_rd_idx;
  reg [`XLEN-1:0] id_ex_pred_pc;
  reg dec_uses_rs1;
  reg dec_uses_rs2;
  reg [`REG_ADDR_W-1:0] dec_rs1_idx;
  reg [`REG_ADDR_W-1:0] dec_rs2_idx;
  reg ex_mem_valid;
  reg ex_mem_is_mem;
  reg mem_response;
  reg mem_fault;
  reg ex_wait;
  reg halt;
  reg fatal;
  reg ex_fetch_fault;
  reg ex_illegal;
  reg ex_redirect_misaligned;
  reg ex_load_store_misaligned;
  reg [`XLEN-1:0] ex_control_next_pc;
  reg [`XLEN-1:0] ex_redirect_pc;
  reg [`XLEN-1:0] trap_target;
  reg [`XLEN-1:0] csr_mepc;
  reg cache_flush_valid;
  reg [`XLEN-1:0] cache_flush_redirect_pc;
  wire ex_fire;
  wire ex_exception;
  wire ex_exception_fatal;
  wire ex_mret_redirect;
  wire ex_any_flush;
  wire id_accept;
  wire if_id_consume;
  wire if_id_can_refill;
  wire ebreak_fire;
  wire pipeline_normal_update;
  wire if_redirect_valid;
  wire [`XLEN-1:0] if_redirect_pc;
  wire ex_mem_leave_update;
  wire ex_mem_load_update;
  wire mem_wb_from_mem;
  wire mem_wb_from_ex;
  wire mem_wb_load;
  wire bpu_update_valid;

  PipelineControl dut (
    .if_id_valid_i(if_id_valid), .id_ex_valid_i(id_ex_valid), .id_ex_load_i(id_ex_load),
    .id_ex_ecall_i(id_ex_ecall), .id_ex_ebreak_i(id_ex_ebreak), .id_ex_mret_i(id_ex_mret),
    .id_ex_branch_i(id_ex_branch), .id_ex_jal_i(id_ex_jal), .id_ex_jalr_i(id_ex_jalr),
    .id_ex_rd_idx_i(id_ex_rd_idx), .id_ex_pred_pc_i(id_ex_pred_pc),
    .dec_uses_rs1_i(dec_uses_rs1), .dec_uses_rs2_i(dec_uses_rs2),
    .dec_rs1_idx_i(dec_rs1_idx), .dec_rs2_idx_i(dec_rs2_idx),
    .ex_mem_valid_i(ex_mem_valid), .ex_mem_is_mem_i(ex_mem_is_mem),
    .mem_response_i(mem_response), .mem_fault_i(mem_fault), .ex_wait_i(ex_wait),
    .halt_i(halt), .fatal_i(fatal), .ex_fetch_fault_i(ex_fetch_fault),
    .ex_illegal_i(ex_illegal), .ex_redirect_misaligned_i(ex_redirect_misaligned),
    .ex_load_store_misaligned_i(ex_load_store_misaligned),
    .ex_control_next_pc_i(ex_control_next_pc), .ex_redirect_pc_i(ex_redirect_pc),
    .trap_target_i(trap_target), .csr_mepc_i(csr_mepc),
    .cache_flush_valid_i(cache_flush_valid), .cache_flush_redirect_pc_i(cache_flush_redirect_pc),
    .ex_fire_o(ex_fire), .ex_exception_o(ex_exception), .ex_exception_fatal_o(ex_exception_fatal),
    .ex_mret_redirect_o(ex_mret_redirect), .ex_any_flush_o(ex_any_flush),
    .id_accept_o(id_accept), .if_id_consume_o(if_id_consume), .if_id_can_refill_o(if_id_can_refill),
    .ebreak_fire_o(ebreak_fire), .pipeline_normal_update_o(pipeline_normal_update),
    .if_redirect_valid_o(if_redirect_valid), .if_redirect_pc_o(if_redirect_pc),
    .ex_mem_leave_update_o(ex_mem_leave_update), .ex_mem_load_update_o(ex_mem_load_update),
    .mem_wb_from_mem_o(mem_wb_from_mem), .mem_wb_from_ex_o(mem_wb_from_ex),
    .mem_wb_load_o(mem_wb_load), .bpu_update_valid_o(bpu_update_valid)
  );

  task automatic defaults;
    begin
      if_id_valid = 1'b1; id_ex_valid = 1'b1; id_ex_load = 1'b0;
      id_ex_ecall = 1'b0; id_ex_ebreak = 1'b0; id_ex_mret = 1'b0;
      id_ex_branch = 1'b0; id_ex_jal = 1'b0; id_ex_jalr = 1'b0;
      id_ex_rd_idx = 5'd5; id_ex_pred_pc = 32'h8000_0004;
      dec_uses_rs1 = 1'b0; dec_uses_rs2 = 1'b0; dec_rs1_idx = 5'd0; dec_rs2_idx = 5'd0;
      ex_mem_valid = 1'b0; ex_mem_is_mem = 1'b0; mem_response = 1'b0; mem_fault = 1'b0; ex_wait = 1'b0;
      halt = 1'b0; fatal = 1'b0; ex_fetch_fault = 1'b0; ex_illegal = 1'b0;
      ex_redirect_misaligned = 1'b0; ex_load_store_misaligned = 1'b0;
      ex_control_next_pc = 32'h8000_0004; ex_redirect_pc = 32'h8000_0100;
      trap_target = 32'h8000_1000; csr_mepc = 32'h8000_2000;
      cache_flush_valid = 1'b0; cache_flush_redirect_pc = 32'h8000_3000;
    end
  endtask

  initial begin
    tb_errors = 0;

    defaults(); id_ex_load = 1'b1; dec_uses_rs1 = 1'b1; dec_rs1_idx = 5'd5; #1;
    tb_check1("load-use accepts into ex", id_accept, 1'b1);
    tb_check1("load-use consumes ifid", if_id_consume, 1'b1);
    tb_check1("load-use load can still fire", ex_fire, 1'b1);

    defaults(); ex_mem_valid = 1'b1; ex_mem_is_mem = 1'b1; mem_response = 1'b0; #1;
    tb_check1("dependent waits behind load miss in EX", ex_fire, 1'b0);
    tb_check1("busy EX keeps IF/ID", id_accept, 1'b0);

    defaults(); id_ex_branch = 1'b1; id_ex_pred_pc = 32'h8000_0004; ex_control_next_pc = 32'h8000_0100; #1;
    tb_check1("branch flush", ex_any_flush, 1'b1);
    tb_check1("branch redirect", if_redirect_valid, 1'b1);
    tb_check32("branch redirect pc", if_redirect_pc, 32'h8000_0100);
    tb_check1("bpu update", bpu_update_valid, 1'b1);

    defaults(); ex_illegal = 1'b1; #1;
    tb_check1("exception", ex_exception, 1'b1);
    tb_check1("exception redirect", if_redirect_valid, 1'b1);
    tb_check32("exception target", if_redirect_pc, 32'h8000_1000);
    tb_check1("exception stops normal", pipeline_normal_update, 1'b0);

    defaults(); trap_target = 32'h0; ex_fetch_fault = 1'b1; #1;
    tb_check1("fatal exception", ex_exception_fatal, 1'b1);

    defaults(); id_ex_mret = 1'b1; #1;
    tb_check1("mret redirect", ex_mret_redirect, 1'b1);
    tb_check32("mret pc", if_redirect_pc, 32'h8000_2000);

    defaults(); ex_wait = 1'b1; #1;
    tb_check1("ex wait blocks fire", ex_fire, 1'b0);

    defaults(); ex_mem_valid = 1'b1; ex_mem_is_mem = 1'b1; mem_response = 1'b1; #1;
    tb_check1("mem wb from mem", mem_wb_from_mem, 1'b1);
    tb_check1("exmem leave", ex_mem_leave_update, 1'b1);

    defaults(); cache_flush_valid = 1'b1; #1;
    tb_check1("cache redirect", if_redirect_valid, 1'b1);
    tb_check32("cache redirect pc", if_redirect_pc, 32'h8000_3000);

    tb_finish("tb_pipeline_control");
  end
endmodule
