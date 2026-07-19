`include "define.v"

module tb_ooo_fetch_trap_gate;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg flush;
  reg run;
  reg commit_ready;
  wire fetch_req_valid;
  wire [`XLEN-1:0] fetch_req_pc;
  reg [`XLEN-1:0] fetch_req_owner_pc;
  wire fetch_rsp_ready;
  wire mem_req_valid;
  wire mem_req_write;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  wire mem_rsp_ready;
  wire mem_flush;
  wire commit0_valid;
  wire [`XLEN-1:0] commit0_pc;
  wire [`INST_W-1:0] commit0_inst;
  wire [`XLEN-1:0] commit0_next_pc;
  wire commit0_rd_en;
  wire [`REG_ADDR_W-1:0] commit0_rd_addr;
  wire [`XLEN-1:0] commit0_rd_data;
  wire commit0_exception;
  wire commit0_write;
  wire commit1_valid;
  wire [`XLEN-1:0] commit1_pc;
  wire [`INST_W-1:0] commit1_inst;
  wire [`XLEN-1:0] commit1_next_pc;
  wire commit1_rd_en;
  wire [`REG_ADDR_W-1:0] commit1_rd_addr;
  wire [`XLEN-1:0] commit1_rd_data;
  wire commit1_exception;
  wire commit1_write;
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
  wire [1:0] retire_count;
  wire [6:0] free_count;
  wire [4:0] rob_count;
  wire [3:0] issue_count;
  localparam [`XLEN-1:0] STALE_USER_PC = 64'h0000003fa795aa32;

  wire [`XLEN-1:0] tb_csr_time_w = {`XLEN{1'b0}};
  wire tb_csr_irq_software_w = 1'b0;
  wire tb_csr_irq_timer_w = 1'b0;
  wire tb_csr_irq_external_w = 1'b0;
  `include "tb_ooo_core_top_glue_csr.svh"

  OooCoreTopGlue dut (
    .clk(clk),
    .rst(rst),
    .head0_context_permit_i(1'b1),
    .fencei_retire_permit_i(1'b1),
    .head0_retire_candidate_valid_o(),
    .head0_identity_valid_o(),
    .head0_identity_o(),
    .flush_i(flush),
    .run_i(run),
    .reset_pc_i(`RESET_PC),
    .fetch_req_valid_o(fetch_req_valid),
    .fetch_req_ready_i(1'b1),
    .fetch_req_pc_o(fetch_req_pc),
    .fetch_req_owner_pc_i(fetch_req_owner_pc),
    .fetch_rsp_valid_i(1'b0),
    .fetch_rsp_ready_o(fetch_rsp_ready),
    .fetch_rsp_inst0_i({`INST_W{1'b0}}),
    .fetch_rsp_resp0_i(2'b00),
    .fetch_rsp_inst1_i({`INST_W{1'b0}}),
    .fetch_rsp_resp1_i(2'b00),
    .fetch_rsp_resp0_bytes_i(3'd4),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(1'b1),
    .mem_req_write_o(mem_req_write),
    .mem_req_cacheable_o(),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(1'b0),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_rsp_rdata_i({`XLEN{1'b0}}),
    .mem_rsp_error_i(1'b0),
    .mem_rsp_page_fault_i(1'b0),
    .mem_rsp_cacheable_i(1'b1),
    .mem_translate_active_i(1'b0),
    .mem_flush_o(mem_flush),
    .mmu_flush_o(),
    `TB_OOO_CORE_TOP_GLUE_CSR_PORTS
    .commit_ready_i(commit_ready),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_rd_addr_o(commit0_rd_addr),
    .commit0_rd_data_o(commit0_rd_data),
    .commit0_exception_o(commit0_exception),
    .commit0_write_o(commit0_write),
    .commit1_valid_o(commit1_valid),
    .commit1_pc_o(commit1_pc),
    .commit1_inst_o(commit1_inst),
    .commit1_next_pc_o(commit1_next_pc),
    .commit1_rd_en_o(commit1_rd_en),
    .commit1_rd_addr_o(commit1_rd_addr),
    .commit1_rd_data_o(commit1_rd_data),
    .commit1_exception_o(commit1_exception),
    .commit1_write_o(commit1_write),
    .trap_valid_o(trap_valid),
    .trap_cause_o(trap_cause),
    .trap_pc_o(trap_pc),
    .trap_tval_o(trap_tval),
    .exit_valid_o(exit_valid),
    .exit_is_ecall_o(exit_is_ecall),
    .exit_is_ebreak_o(exit_is_ebreak),
    .exit_code_o(exit_code),
    .halted_o(halted),
    .priv_mode_o(),
    .mstatus_o(),
    .satp_o(),
    .pmpcfg_o(),
    .pmpaddr_o(),
    .debug_pc_o(debug_pc),
    .debug_state_o(debug_state),
    .debug_gprs_o(debug_gprs),
    .retire_count_o(retire_count),
    .free_count_o(free_count),
    .rob_count_o(rob_count),
    .issue_count_o(issue_count)
  );

  always #5 clk = ~clk;

  // Minimal clocked Bridge-owner model.  Do not tie this input directly to
  // candidate fetch_req_pc: response ownership survives until the handshake.
  always @(posedge clk) begin
    if (rst || flush) begin
      fetch_req_owner_pc <= {`XLEN{1'b0}};
    end else if (fetch_req_valid) begin
      fetch_req_owner_pc <= fetch_req_pc;
    end
  end

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    flush = 1'b0;
    run = 1'b1;
    commit_ready = 1'b1;
    fetch_req_owner_pc = {`XLEN{1'b0}};
    repeat (3) @(posedge clk);
    #1;
    rst = 1'b0;
    #1;

    tb_check1("baseline fetch request valid", fetch_req_valid, 1'b1);

`ifdef FDG_G1_NEGATIVE_PROBE
    // 合同非真空探针：只在显式负测试构建中制造不可能组合，证明父级立即断言确实会响。
    // 正常 module 回归不定义本宏，因此不会 force 生产信号或改变功能路径。
    force dut.u_frontend.dispatch0_arch_trap_w = 1'b1;
    force dut.u_frontend.frontend_dispatch_to_backend_valid_w = 1'b1;
    @(posedge clk);
    #1;
    $display("[FDG-G1-NEGATIVE-PROBE] forced arch_trap && backend_valid");
    // 负探针只验证断言有牙；立即退出，避免多消耗的一拍污染本 TB 后续正常时序场景。
    $finish_and_return(0);
`endif

    force dut.csr_trap_mem_valid_w = 1'b1;
    #1;
    tb_check1("committing memory trap blocks fetch request",
              fetch_req_valid, 1'b0);
    release dut.csr_trap_mem_valid_w;

    force dut.core_trap_flush_q = 1'b1;
    #1;
    tb_check1("trap flush blocks fetch request", fetch_req_valid, 1'b0);
    release dut.core_trap_flush_q;

    force dut.core_serial_flush_q = 1'b1;
    #1;
    tb_check1("serial flush blocks fetch request", fetch_req_valid, 1'b0);
    release dut.core_serial_flush_q;

    force dut.backend_drained_w = 1'b0;
    force dut.csr_trap_mem_valid_w = 1'b1;
    @(posedge clk);
    #1;
    release dut.csr_trap_mem_valid_w;
    tb_check1("memory trap starts trap flush", dut.core_trap_flush_q, 1'b1);
    tb_check1("memory trap starts redirect squash",
              dut.trap_redirect_squash_q, 1'b1);
    tb_check1("trap flush blocks fetch request", fetch_req_valid, 1'b0);
    @(posedge clk);
    #1;
    tb_check1("trap flush is one-shot", dut.core_trap_flush_q, 1'b0);
    tb_check1("redirect squash waits for backend drain",
              dut.trap_redirect_squash_q, 1'b1);
    tb_check1("redirect squash does not block sequential trap fetch",
              fetch_req_valid, 1'b1);
    force dut.u_frontend.u_branch_resolve_recovery_gate.branch_resolve_untracked_raw_w = 1'b1;
    force dut.core_branch_resolve_misaligned_w = 1'b0;
    force dut.core_branch_resolve_next_pc_w = STALE_USER_PC;
    #1;
    tb_check1("redirect squash masks untracked resolve",
              dut.branch_resolve_untracked_w, 1'b0);
    if (fetch_req_pc === STALE_USER_PC) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] stale user redirect selected during squash pc=0x%016x",
               fetch_req_pc);
    end
    release dut.u_frontend.u_branch_resolve_recovery_gate.branch_resolve_untracked_raw_w;
    release dut.core_branch_resolve_misaligned_w;
    release dut.core_branch_resolve_next_pc_w;
    force dut.u_frontend.u_direct_branch_resolve_gate.direct_branch_resolve_redirect_raw_w = 1'b1;
    force dut.direct_branch_resolve_next_pc_w = STALE_USER_PC;
    #1;
    tb_check1("redirect squash masks direct branch resolve",
              dut.direct_branch_resolve_redirect_w, 1'b0);
    if (fetch_req_pc === STALE_USER_PC) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] stale direct branch redirect selected during squash pc=0x%016x",
               fetch_req_pc);
    end
    release dut.u_frontend.u_direct_branch_resolve_gate.direct_branch_resolve_redirect_raw_w;
    release dut.direct_branch_resolve_next_pc_w;
    force dut.u_frontend.u_branch_resolve_recovery_gate.branch_resolve_redirect_raw_w = 1'b1;
    force dut.core_branch_resolve_next_pc_w = STALE_USER_PC;
    #1;
    tb_check1("redirect squash masks tracked branch resolve",
              dut.branch_resolve_redirect_w, 1'b0);
    if (fetch_req_pc === STALE_USER_PC) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] stale tracked branch redirect selected during squash pc=0x%016x",
               fetch_req_pc);
    end
    release dut.u_frontend.u_branch_resolve_recovery_gate.branch_resolve_redirect_raw_w;
    release dut.core_branch_resolve_next_pc_w;
    force dut.u_frontend.u_branch_resolve_recovery_gate.branch_spec_redirect_raw_w = 1'b1;
    force dut.core_branch_resolve_next_pc_w = STALE_USER_PC;
    #1;
    tb_check1("redirect squash masks speculative branch restore",
              dut.branch_spec_redirect_w, 1'b0);
    if (fetch_req_pc === STALE_USER_PC) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] stale speculative branch redirect selected during squash pc=0x%016x",
               fetch_req_pc);
    end
    release dut.u_frontend.u_branch_resolve_recovery_gate.branch_spec_redirect_raw_w;
    release dut.core_branch_resolve_next_pc_w;
    force dut.backend_drained_w = 1'b1;
    @(posedge clk);
    #1;
    tb_check1("redirect squash clears after backend drain",
              dut.trap_redirect_squash_q, 1'b0);
    release dut.backend_drained_w;

    tb_finish("tb_ooo_fetch_trap_gate");
  end
endmodule
