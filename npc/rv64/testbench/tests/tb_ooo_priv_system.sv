`include "define.v"
`include "tb_common.svh"
`include "rv32_encode.svh"

module tb_ooo_priv_system;
  localparam PRODUCER_ID_W =
      `OOO_ROB_INDEX_W + `OOO_PRODUCER_GEN_W;
  reg clk;
  reg rst;
  reg flush;
  reg run;
  reg irq_software;
  reg irq_timer;
  reg irq_external;
  reg commit_ready;

  wire fetch_req_valid;
  reg fetch_req_ready;
  wire [`XLEN-1:0] fetch_req_pc;
  reg [`XLEN-1:0] fetch_req_owner_pc;
  reg fetch_rsp_valid;
  wire fetch_rsp_ready;
  reg [`INST_W-1:0] fetch_rsp_inst0;
  reg [1:0] fetch_rsp_resp0;
  reg [`INST_W-1:0] fetch_rsp_inst1;
  reg [1:0] fetch_rsp_resp1;

  wire mem_req_valid;
  reg mem_req_ready;
  wire mem_req_write;
  wire mem_req_probe;
  wire mem_req_pretrans;
  wire mem_req_nokill;
  wire mem_req_attr_valid;
  wire [1:0] mem_req_class;
  wire mem_req_cacheable;
  wire [1:0] mem_req_owner_kind;
  wire [4:0] mem_req_owner_token;
  wire [1:0] mem_req_mmu_epoch;
  wire [`XLEN-1:0] mem_req_fault_tval;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  reg mem_rsp_valid;
  wire mem_rsp_ready;
  reg [`XLEN-1:0] mem_rsp_rdata;
  reg mem_rsp_error;
  reg mem_rsp_attr_valid;
  reg [1:0] mem_rsp_class;
  reg mem_rsp_cacheable;
  reg [1:0] mem_rsp_owner_kind;
  reg [4:0] mem_rsp_owner_token;
  reg [1:0] mem_rsp_mmu_epoch;
  reg [`XLEN-1:0] mem_rsp_fault_tval;
  wire tb_rsp_pma_fault;
  wire tb_rsp_pma_attr_valid;
  wire [1:0] tb_rsp_pma_class;
  wire [31:0] mem_bridge_owner_residency_mask =
      mem_rsp_valid ? (32'b1 << mem_rsp_owner_token) : 32'b0;

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
  wire mem_flush;
  wire mmu_flush;

  localparam [3:0] MODE_ECALL_MRET = 4'd0;
  localparam [3:0] MODE_IRQ_WFI = 4'd1;
  localparam [3:0] MODE_SMODE_BOOT = 4'd2;
  localparam [3:0] MODE_SBI_ECALL = 4'd3;
  localparam [3:0] MODE_S_EXT_IRQ = 4'd4;
  localparam [3:0] MODE_MRET_S_ILLEGAL = 4'd5;
  localparam [3:0] MODE_SRET_U_ILLEGAL = 4'd6;
  localparam [3:0] MODE_FENCE_ORDERING = 4'd7;
  localparam [3:0] MODE_FDG_ARCH_TRAP = 4'd8;
  localparam [3:0] MODE_M_VEC_IRQ = 4'd9;
  localparam [3:0] MODE_S_VEC_IRQ = 4'd10;
  localparam [3:0] MODE_M_VEC_SYNC = 4'd11;
  localparam [3:0] MODE_QH_SATP = 4'd12;
  localparam [3:0] V10B_KIND_NONE = 4'd0;
  localparam [3:0] V10B_KIND_CSR = 4'd1;
  localparam [3:0] V10B_KIND_ECALL = 4'd2;
  localparam [3:0] V10B_KIND_XRET = 4'd3;
  localparam [3:0] V10B_KIND_WFI = 4'd4;
  localparam [3:0] V10B_KIND_SFENCE = 4'd5;
  localparam [3:0] V10B_KIND_FENCEI = 4'd6;
  localparam [3:0] V10B_KIND_FENCE = 4'd7;
  localparam [3:0] V10B_KIND_IRQ = 4'd8;
  localparam [`XLEN-1:0] BASE_PC = 64'h0000_0000_8000_0000;
  localparam [`XLEN-1:0] HANDLER_PC = 64'h0000_0000_8000_0080;
  localparam [`XLEN-1:0] S_ENTRY_PC = 64'h0000_0000_8000_0040;
  localparam [`XLEN-1:0] S_HANDLER_PC = 64'h0000_0000_8000_0100;
  localparam [`XLEN-1:0] M_TIMER_VECTOR_PC = HANDLER_PC + 64'h1c;
  localparam [`XLEN-1:0] S_EXTERNAL_VECTOR_PC = S_HANDLER_PC + 64'h24;
  localparam [`XLEN-1:0] M_ECALL_WRONG_VECTOR_PC = HANDLER_PC + 64'h2c;
  localparam [`INST_W-1:0] FDG_ILLEGAL_FP_INST =
      {7'b0111111, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP};

  reg [3:0] program_mode;
  integer cycle_count;
  integer commit_total;
  reg saw_handler_fetch;
  reg saw_csr_commit;
  reg saw_lane1_csr_commit;
  reg saw_mret_commit;
  reg saw_sfence_commit;
  reg saw_sinval_commit;
  reg saw_sinval_typed_redirect;
  reg saw_fencei_commit;
  reg saw_fencei_typed_redirect;
  reg saw_wfi_commit;
  reg saw_irq_handler_fetch;
  reg saw_smode_handler_fetch;
  reg saw_sret_commit;
  reg saw_satp_commit;
  reg saw_illegal_xret_commit;
  reg saw_illegal_xret_csr_request;
  reg [31:0] t3k_lane1_candidate_count;
  reg [31:0] t3k_lane1_match_count;
  reg [31:0] v8k_dispatch_count;
  reg [31:0] v8k_birth_count;
  reg [31:0] v8k_exact_commit_count;
  reg [31:0] v8k_death_count;
  reg v8k_birth_check_pending_q;
  reg v8k_death_check_pending_q;
  reg [PRODUCER_ID_W-1:0] v8k_expected_pid_q;
  reg [31:0] fence_commit_count;
  reg [31:0] fence_store_probe_count;
  reg [31:0] fence_store_drain_count;
  reg [31:0] fence_device_read_count;
  integer fence_mem_ready_hold_count;
  reg saw_fence_lane1_capture;
  reg saw_fence_drain_wait;
  reg saw_fence_busy_mem_idle_binding;
  reg fence_mem_idle_binding_mismatch;
  reg fence_retired_before_store_drain;
  reg device_read_before_store_drain;
  reg device_read_before_fence_retire;
  reg [31:0] fdg_arch_trap_capture_count;
  reg [31:0] fdg_capture_pc_match_count;
  reg [31:0] fdg_capture_tval_match_count;
  reg [31:0] fdg_ordinary_backend_present_count;
  reg [31:0] fdg_core_backend_present_count;
  reg [31:0] fdg_commit_oracle_hit_count;
  reg [31:0] fdg_illegal_fp_commit_count;
  reg [31:0] xret_legal_csr_request_count;
  reg [31:0] xret_legal_commit_count;
  reg [31:0] xret_arch_trap_capture_count;
  reg [31:0] xret_capture_pc_match_count;
  reg [31:0] xret_capture_tval_match_count;
  reg [31:0] xret_request_oracle_hit_count;
  reg [31:0] xret_illegal_csr_request_count;
  reg [31:0] xret_commit_oracle_hit_count;
  reg [31:0] xret_illegal_commit_count;
  reg [31:0] vec_trap_mem_count;
  reg [31:0] vec_trap_ex_count;
  reg [31:0] vec_trap_irq_count;
  reg [31:0] vec_target_match_count;
  reg [31:0] vec_target_mismatch_count;
  reg [31:0] vec_exact_handler_fetch_count;
  reg [31:0] vec_wrong_base_fetch_count;
  reg [31:0] vec_xret_request_count;
  reg [31:0] vec_xret_commit_count;
  reg [31:0] vec_return_commit_count;
  reg [31:0] v10b_terminal_count [0:8];
  reg [31:0] v10b_redirect_match_count [0:8];
  reg [31:0] v10b_raw_request_match_count [0:8];
  reg [31:0] v10b_c1_clear_count [0:8];
  reg [31:0] v10b_c2_quiet_count [0:8];
  reg [31:0] v10b_ctrl_commit_count [0:8];
  reg [31:0] v10b_violation_count;
  reg [31:0] v10b_mmu_satp_source_count;
  reg [31:0] v10b_mmu_sfence_source_count;
  reg [31:0] v10b_mmu_fencei_source_count;
  reg [31:0] v10b_mmu_flush_count;
  reg [31:0] v10b_mmu_timing_mismatch_count;
  reg [3:0] v10b_sfence_terminal_mask;
  reg [3:0] v10b_sfence_commit_mask;
  reg v10b_mmu_expected_q;
  reg v10b_c1_check_pending_q;
  reg [3:0] v10b_c1_kind_q;
  reg [`XLEN-1:0] v10b_c1_pc_q;
  reg [`INST_W-1:0] v10b_c1_inst_q;
  reg v10b_c2_check_pending_q;
  reg [3:0] v10b_c2_kind_q;
  reg [`XLEN-1:0] v10b_c2_pc_q;
  reg [`INST_W-1:0] v10b_c2_inst_q;
  reg [31:0] v10g_satp_lane1_capture_count;
  reg [31:0] v10g_qh_satp_birth_count;
  reg [31:0] v10g_qh_satp_c0_commit_count;
  reg [31:0] v10g_qh_satp_c0_barrier_count;
  reg [31:0] v10g_qh_satp_csrfile_request_count;
  reg [31:0] v10g_qh_satp_c1_apply_count;
  reg v10g_qh_satp_owner_live_q;
  reg v10g_qh_satp_expect_c1_q;
  reg v10g_qh_satp_expect_c2_q;
  integer v10b_monitor_index;

  wire [`XLEN-1:0] tb_csr_time_w = 64'd1234;
  wire tb_csr_irq_software_w = irq_software;
  wire tb_csr_irq_timer_w = irq_timer;
  wire tb_csr_irq_external_w = irq_external;
  `include "tb_ooo_core_top_glue_csr.svh"

  // 本 TB 在 Bare 模式下扮演翻译/PMA 响应端；复用平台 PMA 真源，
  // 不从旧 cacheable Boolean 反推 typed provenance。
  OooTypedPmaChecker u_tb_response_pma (
    .paddr_i(mem_req_addr),
    .access_size_i(4'd8),
    .access_read_i(mem_req_valid && !mem_req_write),
    .access_write_i(mem_req_valid && mem_req_write),
    .fault_o(tb_rsp_pma_fault),
    .attr_valid_o(tb_rsp_pma_attr_valid),
    .class_o(tb_rsp_pma_class)
  );

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
    .fetch_req_ready_i(fetch_req_ready),
    .fetch_req_pc_o(fetch_req_pc),
    .fetch_req_owner_pc_i(fetch_req_owner_pc),
    .fetch_rsp_valid_i(fetch_rsp_valid),
    .fetch_rsp_ready_o(fetch_rsp_ready),
    .fetch_rsp_inst0_i(fetch_rsp_inst0),
    .fetch_rsp_resp0_i(fetch_rsp_resp0),
    .fetch_rsp_inst1_i(fetch_rsp_inst1),
    .fetch_rsp_resp1_i(fetch_rsp_resp1),
    .fetch_rsp_resp0_bytes_i(3'd4),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(mem_req_ready),
    .mem_req_write_o(mem_req_write),
    .mem_req_probe_o(mem_req_probe),
    .mem_req_pretrans_o(mem_req_pretrans),
    .mem_req_nokill_o(mem_req_nokill),
    .mem_req_attr_valid_o(mem_req_attr_valid),
    .mem_req_class_o(mem_req_class),
    .mem_req_cacheable_o(mem_req_cacheable),
    .mem_req_owner_kind_o(mem_req_owner_kind),
    .mem_req_owner_token_o(mem_req_owner_token),
    .mem_req_mmu_epoch_o(mem_req_mmu_epoch),
    .mem_req_fault_tval_o(mem_req_fault_tval),
    .mem_req_device_release_o(),
    .mem_req_device_cancel_o(),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(mem_rsp_valid),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_rsp_rdata_i(mem_rsp_rdata),
    .mem_rsp_error_i(mem_rsp_error),
    .mem_rsp_page_fault_i(1'b0),
    .mem_rsp_attr_valid_i(mem_rsp_attr_valid),
    .mem_rsp_class_i(mem_rsp_class),
    .mem_rsp_cacheable_i(mem_rsp_cacheable),
    .mem_rsp_owner_kind_i(mem_rsp_owner_kind),
    .mem_rsp_owner_token_i(mem_rsp_owner_token),
    .mem_rsp_mmu_epoch_i(mem_rsp_mmu_epoch),
    .mem_rsp_fault_tval_i(mem_rsp_fault_tval),
    .mem_expected_valid_o(),
    .mem_expected_owner_kind_o(),
    .mem_expected_owner_token_o(),
    .mem_expected_mmu_epoch_o(),
    .mem_expected_tval_valid_o(),
    .mem_expected_fault_tval_o(),
    .mem_expected_effective_killed_o(),
    .mem_owner_query_valid_i(mem_rsp_valid),
    .mem_owner_query_token_i(mem_rsp_owner_token),
    .mem_tracker_expected_valid_o(),
    .mem_tracker_expected_owner_kind_o(),
    .mem_tracker_expected_owner_token_o(),
    .mem_tracker_expected_mmu_epoch_o(),
    .mem_station_query_valid_i(1'b0),
    .mem_station_query_token_i(5'b00000),
    .mem_station_expected_valid_o(),
    .mem_station_expected_owner_kind_o(),
    .mem_station_expected_owner_token_o(),
    .mem_station_expected_mmu_epoch_o(),
    .mem_drop0_valid_i(flush && mem_rsp_valid),
    .mem_drop0_owner_kind_i(mem_rsp_owner_kind),
    .mem_drop0_owner_token_i(mem_rsp_owner_token),
    .mem_drop0_mmu_epoch_i(mem_rsp_mmu_epoch),
    .mem_drop0_fault_tval_i(mem_rsp_fault_tval),
    .mem_drop1_valid_i(1'b0),
    .mem_drop1_owner_kind_i(2'b00),
    .mem_drop1_owner_token_i(5'b00000),
    .mem_drop1_mmu_epoch_i(2'b00),
    .mem_drop1_fault_tval_i({`XLEN{1'b0}}),
    .mem_bridge_owner_residency_mask_i(
        mem_bridge_owner_residency_mask),
    .mem_sq_query_valid_i(1'b0),
    .mem_sq_query_owner_kind_i(2'b00),
    .mem_sq_query_owner_token_i(5'b00000),
    .mem_sq_query_mmu_epoch_i(2'b00),
    .mem_sq_query_paddr_i({`XLEN{1'b0}}),
    .mem_sq_query_attr_valid_i(1'b0),
    .mem_sq_query_class_i(`OOO_MEM_CLASS_RSVD),
    .mem_sq_query_wstrb_i({`STRB_W{1'b0}}),
    .mem_sq_query_allow_o(),
    .mem_sq_query_forward_o(),
    .mem_sq_query_replay_o(),
    .mem_sq_query_retry_ready_o(),
    .mem_sq_query_forward_data_o(),
    .mem1_req_ready_i(1'b0),
    .mem1_rsp_valid_i(1'b0),
    .mem1_rsp_rdata_i({`XLEN{1'b0}}),
    .mem1_rsp_error_i(1'b0),
    .mem1_rsp_page_fault_i(1'b0),
    .mem1_rsp_attr_valid_i(1'b0),
    .mem1_rsp_class_i(`OOO_MEM_CLASS_RSVD),
    .mem1_rsp_cacheable_i(1'b0),
    .mem1_rsp_owner_kind_i(2'b00),
    .mem1_rsp_owner_token_i(5'b00000),
    .mem1_rsp_mmu_epoch_i(2'b00),
    .mem1_rsp_fault_tval_i({`XLEN{1'b0}}),
    .mem1_owner_query_valid_i(1'b0),
    .mem1_owner_query_token_i(5'b00000),
    .mem1_station_query_valid_i(1'b0),
    .mem1_station_query_token_i(5'b00000),
    .mem1_sq_query_valid_i(1'b0),
    .mem1_sq_query_owner_kind_i(2'b00),
    .mem1_sq_query_owner_token_i(5'b00000),
    .mem1_sq_query_mmu_epoch_i(2'b00),
    .mem1_sq_query_paddr_i({`XLEN{1'b0}}),
    .mem1_sq_query_attr_valid_i(1'b0),
    .mem1_sq_query_class_i(`OOO_MEM_CLASS_RSVD),
    .mem1_sq_query_wstrb_i({`STRB_W{1'b0}}),
    .mem1_sq_query_allow_o(),
    .mem1_sq_query_forward_o(),
    .mem1_sq_query_replay_o(),
    .mem1_sq_query_retry_ready_o(),
    .mem1_sq_query_forward_data_o(),
    .mem1_drop0_valid_i(1'b0),
    .mem1_drop0_owner_kind_i(2'b00),
    .mem1_drop0_owner_token_i(5'b00000),
    .mem1_drop0_mmu_epoch_i(2'b00),
    .mem1_drop0_fault_tval_i({`XLEN{1'b0}}),
    .mem1_drop1_valid_i(1'b0),
    .mem1_drop1_owner_kind_i(2'b00),
    .mem1_drop1_owner_token_i(5'b00000),
    .mem1_drop1_mmu_epoch_i(2'b00),
    .mem1_drop1_fault_tval_i({`XLEN{1'b0}}),
    .mem1_bridge_owner_residency_mask_i(32'b0),
    .mem1_translate_active_i(1'b0),
    .mem_translate_active_i(1'b0),
    .mem_flush_o(mem_flush),
    .mmu_flush_o(mmu_flush),
    .csr_frm_w(3'b000),
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

  function [`XLEN-1:0] gpr;
    input [`REG_ADDR_W-1:0] idx;
    begin
      gpr = debug_gprs[idx * `XLEN +: `XLEN];
    end
  endfunction

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  function [`INST_W-1:0] inst_addi;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_addi = rv32_i(imm, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_OP_IMM);
    end
  endfunction

  function [`INST_W-1:0] inst_add;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_add = rv32_r(`FUNCT7_STD, rs2, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_OP);
    end
  endfunction

  function [`INST_W-1:0] inst_auipc;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_auipc = rv32_u(imm, rd, `OPCODE_AUIPC);
    end
  endfunction

  function [`INST_W-1:0] inst_lui;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_lui = rv32_u(imm, rd, `OPCODE_LUI);
    end
  endfunction

  function [`INST_W-1:0] inst_csr;
    input [11:0] csr;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_csr = rv32_i(csr, rs1, funct3, rd, `OPCODE_SYSTEM);
    end
  endfunction

  function [`INST_W-1:0] inst_csrrw;
    input [4:0] rd;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      inst_csrrw = inst_csr(csr, rs1, 3'b001, rd);
    end
  endfunction

  function [`INST_W-1:0] inst_csrrs;
    input [4:0] rd;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      inst_csrrs = inst_csr(csr, rs1, 3'b010, rd);
    end
  endfunction

  function [`INST_W-1:0] inst_ecall;
    begin
      inst_ecall = 32'h0000_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_ebreak;
    begin
      inst_ebreak = 32'h0010_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_mret;
    begin
      inst_mret = 32'h3020_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_sret;
    begin
      inst_sret = 32'h1020_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_wfi;
    begin
      inst_wfi = 32'h1050_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_fence;
    begin
      // fm=0, pred=RW, succ=RW, rs1=rd=0.
      inst_fence = 32'h0ff0_000f;
    end
  endfunction

  function [`INST_W-1:0] inst_sd;
    input [4:0] rs2;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_sd = rv32_s(imm, rs2, rs1, `FUNCT3_SD);
    end
  endfunction

  function [`INST_W-1:0] inst_lw;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_lw = rv32_i(imm, rs1, `FUNCT3_LW, rd, `OPCODE_LOAD);
    end
  endfunction

  function [`INST_W-1:0] inst_sfence_vma;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_sfence_vma = {`SYSTEM_FUNCT7_SFENCE_VMA, rs2, rs1,
                         `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
    end
  endfunction

  function [`INST_W-1:0] inst_sinval_vma;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_sinval_vma = {`SYSTEM_FUNCT7_SINVAL_VMA, rs2, rs1,
                         `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
    end
  endfunction

  function [`INST_W-1:0] inst_sfence_w_inval;
    begin
      inst_sfence_w_inval = {
          `SYSTEM_FUNCT7_SFENCE_INVAL,
          `SYSTEM_RS2_SFENCE_W_INVAL,
          5'd0, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
    end
  endfunction

  function [`INST_W-1:0] inst_sfence_inval_ir;
    begin
      inst_sfence_inval_ir = {
          `SYSTEM_FUNCT7_SFENCE_INVAL,
          `SYSTEM_RS2_SFENCE_INVAL_IR,
          5'd0, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
    end
  endfunction

  function [`INST_W-1:0] inst_fencei;
    begin
      inst_fencei = 32'h0000_100f;
    end
  endfunction

  function [`INST_W-1:0] program_word;
    input [`XLEN-1:0] addr;
    begin
      program_word = inst_ebreak();
      case (program_mode)
        MODE_ECALL_MRET: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_addi(5'd10, 5'd0, 12'h011);
            BASE_PC + 64'h04: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h08: program_word = inst_addi(5'd1, 5'd1, 12'h07c);
            BASE_PC + 64'h0c: program_word = inst_csrrw(5'd5, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h10: program_word = inst_csrrs(5'd6, `CSR_MTVEC, 5'd0);
            BASE_PC + 64'h14: program_word = inst_addi(5'd3, 5'd0, 12'h003);
            BASE_PC + 64'h18: program_word = inst_add(5'd4, 5'd10, 5'd3);
            BASE_PC + 64'h1c: program_word = inst_ecall();
            BASE_PC + 64'h20: program_word = inst_addi(5'd7, 5'd0, 12'h007);
            BASE_PC + 64'h24: program_word = inst_sfence_vma(5'd0, 5'd0);
            BASE_PC + 64'h28: program_word = inst_sinval_vma(5'd0, 5'd0);
            BASE_PC + 64'h2c: program_word = inst_sfence_w_inval();
            BASE_PC + 64'h30: program_word = inst_sfence_inval_ir();
            BASE_PC + 64'h34: program_word = inst_fencei();
            BASE_PC + 64'h38: program_word = inst_wfi();
            BASE_PC + 64'h3c: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_MEPC, 5'd0);
            HANDLER_PC + 64'h08: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            HANDLER_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd9);
            HANDLER_PC + 64'h10: program_word = inst_addi(5'd11, 5'd0, 12'h055);
            HANDLER_PC + 64'h14: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_IRQ_WFI: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h080);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd2, 5'd0, 12'h080);
            BASE_PC + 64'h10: program_word = inst_csrrw(5'd0, `CSR_MIE, 5'd2);
            BASE_PC + 64'h14: program_word = inst_addi(5'd3, 5'd0, 12'h008);
            BASE_PC + 64'h18: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd3);
            BASE_PC + 64'h1c: program_word = inst_wfi();
            BASE_PC + 64'h20: program_word = inst_addi(5'd13, 5'd0, 12'h00d);
            BASE_PC + 64'h24: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd14, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_addi(5'd15, 5'd0, 12'h066);
            HANDLER_PC + 64'h08: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_SMODE_BOOT: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h100);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_STVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd2, 5'd0, 12'h200);
            BASE_PC + 64'h10: program_word = inst_csrrw(5'd0, `CSR_MEDELEG, 5'd2);
            BASE_PC + 64'h14: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h18: program_word = inst_addi(5'd3, 5'd3, 12'h02c);
            BASE_PC + 64'h1c: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h20: program_word = inst_lui(5'd4, 20'h00001);
            BASE_PC + 64'h24: program_word = inst_addi(5'd4, 5'd4, 12'h800);
            BASE_PC + 64'h28: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
            BASE_PC + 64'h2c: program_word = inst_mret();
            // Keep SATP in lane1 so the product queue-head configuration still
            // proves the lane1/full-drain CSR domain and its registered MMU pulse.
            S_ENTRY_PC + 64'h00: program_word = inst_addi(5'd5, 5'd0, 12'h055);
            S_ENTRY_PC + 64'h04: program_word = inst_csrrw(5'd0, `CSR_SATP, 5'd0);
            S_ENTRY_PC + 64'h08: program_word = inst_sfence_vma(5'd0, 5'd0);
            S_ENTRY_PC + 64'h0c: program_word = inst_ecall();
            S_ENTRY_PC + 64'h10: program_word = inst_addi(5'd7, 5'd0, 12'h077);
            S_ENTRY_PC + 64'h14: program_word = inst_ebreak();
            S_HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_SCAUSE, 5'd0);
            S_HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_SEPC, 5'd0);
            S_HANDLER_PC + 64'h08: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            S_HANDLER_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
            S_HANDLER_PC + 64'h10: program_word = inst_addi(5'd10, 5'd0, 12'h066);
            S_HANDLER_PC + 64'h14: program_word = inst_sret();
            default: begin end
          endcase
        end
        MODE_SBI_ECALL: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h080);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_MEDELEG, 5'd0);
            BASE_PC + 64'h10: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h14: program_word = inst_addi(5'd3, 5'd3, 12'h030);
            BASE_PC + 64'h18: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h1c: program_word = inst_lui(5'd4, 20'h00001);
            BASE_PC + 64'h20: program_word = inst_addi(5'd4, 5'd4, 12'h800);
            BASE_PC + 64'h24: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
            BASE_PC + 64'h28: program_word = inst_mret();
            S_ENTRY_PC + 64'h00: program_word = inst_addi(5'd5, 5'd0, 12'h123);
            S_ENTRY_PC + 64'h04: program_word = inst_ecall();
            S_ENTRY_PC + 64'h08: program_word = inst_addi(5'd7, 5'd0, 12'h05a);
            S_ENTRY_PC + 64'h0c: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_MEPC, 5'd0);
            HANDLER_PC + 64'h08: program_word = inst_csrrs(5'd10, `CSR_MSTATUS, 5'd0);
            HANDLER_PC + 64'h0c: program_word = inst_addi(5'd12, 5'd9, 12'h000);
            HANDLER_PC + 64'h10: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            HANDLER_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd9);
            HANDLER_PC + 64'h18: program_word = inst_addi(5'd11, 5'd0, 12'h06b);
            HANDLER_PC + 64'h1c: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_S_EXT_IRQ: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h100);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_STVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd2, 5'd0, 12'h200);
            BASE_PC + 64'h10: program_word = inst_addi(5'd0, 5'd0, 12'h000);
            BASE_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MIDELEG, 5'd2);
            BASE_PC + 64'h18: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h1c: program_word = inst_addi(5'd3, 5'd3, 12'h028);
            BASE_PC + 64'h20: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h24: program_word = inst_lui(5'd4, 20'h00001);
            BASE_PC + 64'h28: program_word = inst_addi(5'd4, 5'd4, 12'h800);
            BASE_PC + 64'h2c: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
            BASE_PC + 64'h30: program_word = inst_mret();
            S_ENTRY_PC + 64'h00: program_word = inst_addi(5'd5, 5'd0, 12'h200);
            S_ENTRY_PC + 64'h04: program_word = inst_csrrw(5'd0, `CSR_SIE, 5'd5);
            S_ENTRY_PC + 64'h08: program_word = inst_addi(5'd6, 5'd0, 12'h002);
            S_ENTRY_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_SSTATUS, 5'd6);
            S_ENTRY_PC + 64'h10: program_word = inst_wfi();
            S_ENTRY_PC + 64'h14: program_word = inst_addi(5'd7, 5'd0, 12'h071);
            S_ENTRY_PC + 64'h18: program_word = inst_ebreak();
            S_HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_SCAUSE, 5'd0);
            S_HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_SEPC, 5'd0);
            S_HANDLER_PC + 64'h08: program_word = inst_csrrs(5'd10, `CSR_SSTATUS, 5'd0);
            S_HANDLER_PC + 64'h0c: program_word = inst_addi(5'd11, 5'd0, 12'h072);
            S_HANDLER_PC + 64'h10: program_word = inst_sret();
            default: begin end
          endcase
        end
        MODE_MRET_S_ILLEGAL: begin
          case (addr)
            // M-mode setup enters S-mode at S_ENTRY_PC.
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h080);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h10: program_word = inst_addi(5'd3, 5'd3, 12'h034);
            BASE_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h18: program_word = inst_lui(5'd4, 20'h00001);
            BASE_PC + 64'h1c: program_word = inst_addi(5'd4, 5'd4, 12'h800);
            BASE_PC + 64'h20: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
            BASE_PC + 64'h24: program_word = inst_mret();
            // This MRET is illegal in S-mode and must not become a synthetic commit.
            S_ENTRY_PC + 64'h00: program_word = inst_mret();
            S_ENTRY_PC + 64'h04: program_word = inst_addi(5'd7, 5'd0, 12'h075);
            S_ENTRY_PC + 64'h08: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_MEPC, 5'd0);
            HANDLER_PC + 64'h08: program_word = inst_csrrs(5'd10, `CSR_MTVAL, 5'd0);
            HANDLER_PC + 64'h0c: program_word = inst_addi(5'd12, 5'd9, 12'h000);
            HANDLER_PC + 64'h10: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            HANDLER_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd9);
            HANDLER_PC + 64'h18: program_word = inst_addi(5'd11, 5'd0, 12'h076);
            HANDLER_PC + 64'h1c: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_SRET_U_ILLEGAL: begin
          case (addr)
            // M-mode setup enters U-mode at S_ENTRY_PC (the address name is historical).
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h080);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h10: program_word = inst_addi(5'd3, 5'd3, 12'h034);
            BASE_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h18: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd0);
            BASE_PC + 64'h1c: program_word = inst_mret();
            // Place SRET in lane1 to cover the lane1 pending-trap capture path.
            S_ENTRY_PC + 64'h00: program_word = inst_addi(5'd6, 5'd0, 12'h065);
            S_ENTRY_PC + 64'h04: program_word = inst_sret();
            S_ENTRY_PC + 64'h08: program_word = inst_addi(5'd7, 5'd0, 12'h075);
            S_ENTRY_PC + 64'h0c: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_MEPC, 5'd0);
            HANDLER_PC + 64'h08: program_word = inst_csrrs(5'd10, `CSR_MTVAL, 5'd0);
            HANDLER_PC + 64'h0c: program_word = inst_addi(5'd12, 5'd9, 12'h000);
            HANDLER_PC + 64'h10: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            HANDLER_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd9);
            HANDLER_PC + 64'h18: program_word = inst_addi(5'd11, 5'd0, 12'h076);
            HANDLER_PC + 64'h1c: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_FENCE_ORDERING: begin
          case (addr)
            // +08/+0c is the decisive dual-lane packet: an older store in
            // lane0 and FENCE in lane1.  +14 is a younger side-effecting
            // device read that must not reach the memory bridge early.
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd3, 5'd0, 12'h035);
            BASE_PC + 64'h08: program_word = inst_sd(5'd3, 5'd1, 12'h000);
            BASE_PC + 64'h0c: program_word = inst_fence();
            BASE_PC + 64'h10: program_word = inst_lui(5'd2, 20'h10000);
            BASE_PC + 64'h14: program_word = inst_lw(5'd4, 5'd2, 12'h000);
            BASE_PC + 64'h18: program_word = inst_ebreak();
            default: begin end
          endcase
        end
        MODE_FDG_ARCH_TRAP: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h080);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd6, 5'd0, 12'h041);
            BASE_PC + 64'h10: program_word = FDG_ILLEGAL_FP_INST;
            BASE_PC + 64'h14: program_word = inst_addi(5'd7, 5'd0, 12'h047);
            BASE_PC + 64'h18: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_MEPC, 5'd0);
            HANDLER_PC + 64'h08: program_word = inst_csrrs(5'd10, `CSR_MTVAL, 5'd0);
            HANDLER_PC + 64'h0c: program_word = inst_addi(5'd12, 5'd9, 12'h000);
            HANDLER_PC + 64'h10: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            HANDLER_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd9);
            HANDLER_PC + 64'h18: program_word = inst_addi(5'd11, 5'd0, 12'h04d);
            HANDLER_PC + 64'h1c: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_M_VEC_IRQ: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h081);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd2, 5'd0, 12'h080);
            BASE_PC + 64'h10: program_word = inst_csrrw(5'd0, `CSR_MIE, 5'd2);
            BASE_PC + 64'h14: program_word = inst_addi(5'd3, 5'd0, 12'h008);
            BASE_PC + 64'h18: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd3);
            BASE_PC + 64'h1c: program_word = inst_wfi();
            BASE_PC + 64'h20: program_word = inst_addi(5'd13, 5'd0, 12'h031);
            BASE_PC + 64'h24: program_word = inst_ebreak();
            M_TIMER_VECTOR_PC + 64'h00:
                program_word = inst_csrrs(5'd14, `CSR_MCAUSE, 5'd0);
            M_TIMER_VECTOR_PC + 64'h04:
                program_word = inst_addi(5'd15, 5'd0, 12'h061);
            M_TIMER_VECTOR_PC + 64'h08: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_S_VEC_IRQ: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h101);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_STVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd2, 5'd0, 12'h200);
            BASE_PC + 64'h10: program_word = inst_addi(5'd0, 5'd0, 12'h000);
            BASE_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MIDELEG, 5'd2);
            BASE_PC + 64'h18: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h1c: program_word = inst_addi(5'd3, 5'd3, 12'h028);
            BASE_PC + 64'h20: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h24: program_word = inst_lui(5'd4, 20'h00001);
            BASE_PC + 64'h28: program_word = inst_addi(5'd4, 5'd4, 12'h800);
            BASE_PC + 64'h2c: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
            BASE_PC + 64'h30: program_word = inst_mret();
            S_ENTRY_PC + 64'h00: program_word = inst_addi(5'd5, 5'd0, 12'h200);
            S_ENTRY_PC + 64'h04: program_word = inst_csrrw(5'd0, `CSR_SIE, 5'd5);
            S_ENTRY_PC + 64'h08: program_word = inst_addi(5'd6, 5'd0, 12'h002);
            S_ENTRY_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_SSTATUS, 5'd6);
            S_ENTRY_PC + 64'h10: program_word = inst_wfi();
            S_ENTRY_PC + 64'h14: program_word = inst_addi(5'd7, 5'd0, 12'h032);
            S_ENTRY_PC + 64'h18: program_word = inst_ebreak();
            S_EXTERNAL_VECTOR_PC + 64'h00:
                program_word = inst_csrrs(5'd8, `CSR_SCAUSE, 5'd0);
            S_EXTERNAL_VECTOR_PC + 64'h04:
                program_word = inst_csrrs(5'd9, `CSR_SEPC, 5'd0);
            S_EXTERNAL_VECTOR_PC + 64'h08:
                program_word = inst_csrrs(5'd10, `CSR_SSTATUS, 5'd0);
            S_EXTERNAL_VECTOR_PC + 64'h0c:
                program_word = inst_addi(5'd11, 5'd0, 12'h063);
            S_EXTERNAL_VECTOR_PC + 64'h10: program_word = inst_sret();
            default: begin end
          endcase
        end
        MODE_M_VEC_SYNC: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h081);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_ecall();
            BASE_PC + 64'h10: program_word = inst_addi(5'd7, 5'd0, 12'h033);
            BASE_PC + 64'h14: program_word = inst_ebreak();
            HANDLER_PC + 64'h00:
                program_word = inst_csrrs(5'd8, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04:
                program_word = inst_csrrs(5'd9, `CSR_MEPC, 5'd0);
            HANDLER_PC + 64'h08:
                program_word = inst_addi(5'd9, 5'd9, 12'h004);
            HANDLER_PC + 64'h0c:
                program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd9);
            HANDLER_PC + 64'h10:
                program_word = inst_addi(5'd11, 5'd0, 12'h062);
            HANDLER_PC + 64'h14: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_QH_SATP: begin
          case (addr)
            // SATP is deliberately lane0/head0 here.  The product configuration
            // must use the queue-head C0/C1 transaction without a pending-SYSTEM
            // SATP pulse; the following ebreak proves forward progress.
            BASE_PC + 64'h00:
                program_word = inst_csrrw(5'd0, `CSR_SATP, 5'd0);
            BASE_PC + 64'h04: program_word = inst_ebreak();
            default: begin end
          endcase
        end
        default: begin end
      endcase
    end
  endfunction

  function [`REDIR_REASON_W-1:0] v10b_reason_for_kind;
    input [3:0] kind;
    begin
      case (kind)
        V10B_KIND_CSR:
          v10b_reason_for_kind = `REDIR_REASON_CSR_COMMIT;
        V10B_KIND_ECALL, V10B_KIND_IRQ:
          v10b_reason_for_kind = `REDIR_REASON_TRAP;
        V10B_KIND_XRET:
          v10b_reason_for_kind = `REDIR_REASON_XRET;
        V10B_KIND_SFENCE:
          v10b_reason_for_kind = `REDIR_REASON_SFENCE;
        V10B_KIND_FENCEI:
          v10b_reason_for_kind = `REDIR_REASON_FENCEI;
        default:
          v10b_reason_for_kind = `REDIR_REASON_SERIAL;
      endcase
    end
  endfunction

  function [3:0] v10b_kind_from_ctrl_inst;
    input [`INST_W-1:0] inst;
    begin
      if ((inst == inst_mret()) || (inst == inst_sret()))
        v10b_kind_from_ctrl_inst = V10B_KIND_XRET;
      else if (inst == inst_wfi())
        v10b_kind_from_ctrl_inst = V10B_KIND_WFI;
      else if ((inst == inst_sfence_vma(5'd0, 5'd0)) ||
               (inst == inst_sinval_vma(5'd0, 5'd0)) ||
               (inst == inst_sfence_w_inval()) ||
               (inst == inst_sfence_inval_ir()))
        v10b_kind_from_ctrl_inst = V10B_KIND_SFENCE;
      else if (inst == inst_fencei())
        v10b_kind_from_ctrl_inst = V10B_KIND_FENCEI;
      else if (inst == inst_fence())
        v10b_kind_from_ctrl_inst = V10B_KIND_FENCE;
      else
        v10b_kind_from_ctrl_inst = V10B_KIND_NONE;
    end
  endfunction

  function [3:0] v10b_sfence_encoding_bit;
    input [`INST_W-1:0] inst;
    begin
      if (inst == inst_sfence_vma(5'd0, 5'd0))
        v10b_sfence_encoding_bit = 4'b0001;
      else if (inst == inst_sinval_vma(5'd0, 5'd0))
        v10b_sfence_encoding_bit = 4'b0010;
      else if (inst == inst_sfence_w_inval())
        v10b_sfence_encoding_bit = 4'b0100;
      else if (inst == inst_sfence_inval_ir())
        v10b_sfence_encoding_bit = 4'b1000;
      else
        v10b_sfence_encoding_bit = 4'b0000;
    end
  endfunction

  wire [3:0] v10b_pending_kind_w =
      dut.pending_system_csr_q ? V10B_KIND_CSR :
      dut.pending_system_ecall_q ? V10B_KIND_ECALL :
      dut.pending_system_mret_q ? V10B_KIND_XRET :
      dut.u_control_plane.pending_system_wfi_q ? V10B_KIND_WFI :
      dut.u_control_plane.pending_system_sfence_q ? V10B_KIND_SFENCE :
      dut.u_control_plane.pending_system_fencei_q ? V10B_KIND_FENCEI :
      dut.u_control_plane.pending_system_fence_q ? V10B_KIND_FENCE :
      dut.pending_system_irq_q ? V10B_KIND_IRQ :
      V10B_KIND_NONE;
  wire [3:0] v10b_pending_kind_count_w =
      {3'b000, dut.pending_system_csr_q} +
      {3'b000, dut.pending_system_ecall_q} +
      {3'b000, dut.pending_system_mret_q} +
      {3'b000, dut.u_control_plane.pending_system_wfi_q} +
      {3'b000, dut.u_control_plane.pending_system_sfence_q} +
      {3'b000, dut.u_control_plane.pending_system_fencei_q} +
      {3'b000, dut.u_control_plane.pending_system_fence_q} +
      {3'b000, dut.pending_system_irq_q};
  wire v10b_terminal_fire_w =
      dut.pending_system_csr_commit_w ||
      (dut.u_frontend.commit_e6_valid_w &&
       dut.u_frontend.commit_e6_sel_system_w);
  wire [3:0] v10b_terminal_kind_w =
      dut.pending_system_csr_commit_w ?
          V10B_KIND_CSR : v10b_pending_kind_w;
  wire [`XLEN-1:0] v10b_expected_redirect_pc_w =
      ((v10b_terminal_kind_w == V10B_KIND_ECALL) ||
       (v10b_terminal_kind_w == V10B_KIND_IRQ)) ?
          tb_csr_trap_target_w :
      (v10b_terminal_kind_w == V10B_KIND_XRET) ?
          tb_csr_ret_target_w :
          dut.pending_system_next_pc_q;
  wire v10b_redirect_match_w =
      dut.frontend_control_event_valid_w &&
      (dut.frontend_control_event_reason_w ==
       v10b_reason_for_kind(v10b_terminal_kind_w)) &&
      (dut.frontend_control_event_pc_w ==
       v10b_expected_redirect_pc_w) &&
      dut.frontend_control_event_flush_fetch_w &&
      (dut.frontend_control_event_backend_action_w ==
       `OOO_BACKEND_ACTION_NONE);
  wire [3:0] v10b_csr_request_count_w =
      {3'b000, tb_csr_access_valid_w} +
      {3'b000, tb_csr_trap_mem_valid_w} +
      {3'b000, tb_csr_trap_ex_valid_w} +
      {3'b000, tb_csr_trap_irq_valid_w} +
      {3'b000, tb_csr_real_mret_valid_w} +
      {3'b000, tb_csr_sret_valid_w};
  wire v10b_raw_request_match_w =
      ((v10b_terminal_kind_w == V10B_KIND_CSR) &&
       tb_csr_access_valid_w &&
       (v10b_csr_request_count_w == 4'd1)) ||
      ((v10b_terminal_kind_w == V10B_KIND_ECALL) &&
       tb_csr_trap_ex_valid_w &&
       (tb_csr_trap_ex_pc_w == dut.pending_system_pc_q) &&
       (tb_csr_trap_ex_cause_w == tb_csr_ecall_cause_w) &&
       (v10b_csr_request_count_w == 4'd1)) ||
      ((v10b_terminal_kind_w == V10B_KIND_XRET) &&
       (tb_csr_real_mret_valid_w || tb_csr_sret_valid_w) &&
       (v10b_csr_request_count_w == 4'd1)) ||
      ((v10b_terminal_kind_w == V10B_KIND_IRQ) &&
       tb_csr_trap_irq_valid_w &&
       (tb_csr_trap_irq_pc_w == dut.pending_system_pc_q) &&
       (tb_csr_trap_irq_cause_w ==
        dut.pending_system_irq_cause_q) &&
       (v10b_csr_request_count_w == 4'd1)) ||
      (((v10b_terminal_kind_w == V10B_KIND_WFI) ||
        (v10b_terminal_kind_w == V10B_KIND_SFENCE) ||
        (v10b_terminal_kind_w == V10B_KIND_FENCEI) ||
        (v10b_terminal_kind_w == V10B_KIND_FENCE)) &&
       (v10b_csr_request_count_w == 4'd0));
  wire v10b_mmu_source_w =
      dut.pending_system_satp_write_commit_w ||
      dut.pending_system_sfence_commit_w ||
      dut.pending_system_fencei_commit_w;
  wire [2:0] v10b_mmu_source_count_w =
      {2'b00, dut.pending_system_satp_write_commit_w} +
      {2'b00, dut.pending_system_sfence_commit_w} +
      {2'b00, dut.pending_system_fencei_commit_w};
  wire v10b_pending_csr_write_intent_w =
      (dut.pending_system_inst_q[14:12] == 3'b001) ||
      (dut.pending_system_inst_q[14:12] == 3'b101) ||
      (((dut.pending_system_inst_q[14:12] == 3'b010) ||
         (dut.pending_system_inst_q[14:12] == 3'b011) ||
         (dut.pending_system_inst_q[14:12] == 3'b110) ||
         (dut.pending_system_inst_q[14:12] == 3'b111)) &&
       (dut.pending_system_inst_q[19:15] != 5'd0));
  wire v10b_expected_mmu_source_w =
      (v10b_terminal_kind_w == V10B_KIND_SFENCE) ||
      (v10b_terminal_kind_w == V10B_KIND_FENCEI) ||
      ((v10b_terminal_kind_w == V10B_KIND_CSR) &&
       (dut.pending_system_inst_q[31:20] == `CSR_SATP) &&
       v10b_pending_csr_write_intent_w);
  wire [3:0] v10b_ctrl_commit_kind_w =
      v10b_kind_from_ctrl_inst(dut.u_writeback.ctrl_commit_inst_q);

  task automatic reset_dut;
    input [3:0] mode_i;
    integer v10b_reset_index;
    begin
      clk = 1'b0;
      rst = 1'b1;
      flush = 1'b0;
      run = 1'b1;
      irq_software = 1'b0;
      irq_timer = 1'b0;
      irq_external = 1'b0;
      commit_ready = 1'b1;
      fetch_req_ready = 1'b1;
      fetch_rsp_valid = 1'b0;
      fetch_rsp_inst0 = {`INST_W{1'b0}};
      fetch_rsp_inst1 = {`INST_W{1'b0}};
      fetch_rsp_resp0 = 2'b00;
      fetch_rsp_resp1 = 2'b00;
      mem_req_ready = 1'b1;
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      mem_rsp_attr_valid = 1'b0;
      mem_rsp_class = `OOO_MEM_CLASS_RSVD;
      mem_rsp_cacheable = 1'b0;
      mem_rsp_owner_kind = 2'b00;
      mem_rsp_owner_token = 5'b00000;
      mem_rsp_mmu_epoch = 2'b00;
      mem_rsp_fault_tval = {`XLEN{1'b0}};
      program_mode = mode_i;
      cycle_count = 0;
      commit_total = 0;
      saw_handler_fetch = 1'b0;
      saw_csr_commit = 1'b0;
      saw_lane1_csr_commit = 1'b0;
      saw_mret_commit = 1'b0;
      saw_sfence_commit = 1'b0;
      saw_sinval_commit = 1'b0;
      saw_sinval_typed_redirect = 1'b0;
      saw_fencei_commit = 1'b0;
      saw_fencei_typed_redirect = 1'b0;
      saw_wfi_commit = 1'b0;
      saw_irq_handler_fetch = 1'b0;
      saw_smode_handler_fetch = 1'b0;
      saw_sret_commit = 1'b0;
      saw_satp_commit = 1'b0;
      saw_illegal_xret_commit = 1'b0;
      saw_illegal_xret_csr_request = 1'b0;
      t3k_lane1_candidate_count = 32'd0;
      t3k_lane1_match_count = 32'd0;
      v8k_dispatch_count = 32'd0;
      v8k_birth_count = 32'd0;
      v8k_exact_commit_count = 32'd0;
      v8k_death_count = 32'd0;
      v8k_birth_check_pending_q = 1'b0;
      v8k_death_check_pending_q = 1'b0;
      v8k_expected_pid_q = {PRODUCER_ID_W{1'b0}};
      fence_commit_count = 32'd0;
      fence_store_probe_count = 32'd0;
      fence_store_drain_count = 32'd0;
      fence_device_read_count = 32'd0;
      fence_mem_ready_hold_count = 0;
      saw_fence_lane1_capture = 1'b0;
      saw_fence_drain_wait = 1'b0;
      saw_fence_busy_mem_idle_binding = 1'b0;
      fence_mem_idle_binding_mismatch = 1'b0;
      fence_retired_before_store_drain = 1'b0;
      device_read_before_store_drain = 1'b0;
      device_read_before_fence_retire = 1'b0;
      fdg_arch_trap_capture_count = 32'd0;
      fdg_capture_pc_match_count = 32'd0;
      fdg_capture_tval_match_count = 32'd0;
      fdg_ordinary_backend_present_count = 32'd0;
      fdg_core_backend_present_count = 32'd0;
      fdg_commit_oracle_hit_count = 32'd0;
      fdg_illegal_fp_commit_count = 32'd0;
      xret_legal_csr_request_count = 32'd0;
      xret_legal_commit_count = 32'd0;
      xret_arch_trap_capture_count = 32'd0;
      xret_capture_pc_match_count = 32'd0;
      xret_capture_tval_match_count = 32'd0;
      xret_request_oracle_hit_count = 32'd0;
      xret_illegal_csr_request_count = 32'd0;
      xret_commit_oracle_hit_count = 32'd0;
      xret_illegal_commit_count = 32'd0;
      vec_trap_mem_count = 32'd0;
      vec_trap_ex_count = 32'd0;
      vec_trap_irq_count = 32'd0;
      vec_target_match_count = 32'd0;
      vec_target_mismatch_count = 32'd0;
      vec_exact_handler_fetch_count = 32'd0;
      vec_wrong_base_fetch_count = 32'd0;
      vec_xret_request_count = 32'd0;
      vec_xret_commit_count = 32'd0;
      vec_return_commit_count = 32'd0;
      for (v10b_reset_index = 0;
           v10b_reset_index <= 8;
           v10b_reset_index = v10b_reset_index + 1) begin
        v10b_terminal_count[v10b_reset_index] = 32'd0;
        v10b_redirect_match_count[v10b_reset_index] = 32'd0;
        v10b_raw_request_match_count[v10b_reset_index] = 32'd0;
        v10b_c1_clear_count[v10b_reset_index] = 32'd0;
        v10b_c2_quiet_count[v10b_reset_index] = 32'd0;
        v10b_ctrl_commit_count[v10b_reset_index] = 32'd0;
      end
      v10b_violation_count = 32'd0;
      v10b_mmu_satp_source_count = 32'd0;
      v10b_mmu_sfence_source_count = 32'd0;
      v10b_mmu_fencei_source_count = 32'd0;
      v10b_mmu_flush_count = 32'd0;
      v10b_mmu_timing_mismatch_count = 32'd0;
      v10b_sfence_terminal_mask = 4'b0000;
      v10b_sfence_commit_mask = 4'b0000;
      v10b_mmu_expected_q = 1'b0;
      v10b_c1_check_pending_q = 1'b0;
      v10b_c1_kind_q = V10B_KIND_NONE;
      v10b_c1_pc_q = {`XLEN{1'b0}};
      v10b_c1_inst_q = {`INST_W{1'b0}};
      v10b_c2_check_pending_q = 1'b0;
      v10b_c2_kind_q = V10B_KIND_NONE;
      v10b_c2_pc_q = {`XLEN{1'b0}};
      v10b_c2_inst_q = {`INST_W{1'b0}};
      v10g_satp_lane1_capture_count = 32'd0;
      v10g_qh_satp_birth_count = 32'd0;
      v10g_qh_satp_c0_commit_count = 32'd0;
      v10g_qh_satp_c0_barrier_count = 32'd0;
      v10g_qh_satp_csrfile_request_count = 32'd0;
      v10g_qh_satp_c1_apply_count = 32'd0;
      v10g_qh_satp_owner_live_q = 1'b0;
      v10g_qh_satp_expect_c1_q = 1'b0;
      v10g_qh_satp_expect_c2_q = 1'b0;
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic run_until_exit;
    input integer max_cycles;
    begin
      while (!exit_valid && !trap_valid && cycle_count < max_cycles) begin
        `TB_TICK(clk);
        cycle_count = cycle_count + 1;
      end
      if (cycle_count >= max_cycles) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] timeout waiting for completion mode=%0d",
                 program_mode);
      end
    end
  endtask

  task automatic check_v10b_scoreboard;
    input [3:0] mode_i;
    integer kind;
    integer errors_before;
    begin
      errors_before = tb_errors;
      for (kind = V10B_KIND_CSR; kind <= V10B_KIND_IRQ;
           kind = kind + 1) begin
        if ((v10b_terminal_count[kind] !==
             v10b_redirect_match_count[kind]) ||
            (v10b_terminal_count[kind] !==
             v10b_raw_request_match_count[kind]) ||
            (v10b_terminal_count[kind] !==
             v10b_c1_clear_count[kind]) ||
            (v10b_terminal_count[kind] !==
             v10b_c2_quiet_count[kind])) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10B mode=%0d kind=%0d terminal=%0d redirect=%0d raw=%0d C1=%0d C2=%0d",
                   mode_i, kind, v10b_terminal_count[kind],
                   v10b_redirect_match_count[kind],
                   v10b_raw_request_match_count[kind],
                   v10b_c1_clear_count[kind],
                   v10b_c2_quiet_count[kind]);
        end
      end

      if ((v10b_ctrl_commit_count[V10B_KIND_CSR] != 32'd0) ||
          (v10b_ctrl_commit_count[V10B_KIND_ECALL] != 32'd0) ||
          (v10b_ctrl_commit_count[V10B_KIND_IRQ] != 32'd0) ||
          (v10b_ctrl_commit_count[V10B_KIND_XRET] !=
           v10b_terminal_count[V10B_KIND_XRET]) ||
          (v10b_ctrl_commit_count[V10B_KIND_WFI] !=
           v10b_terminal_count[V10B_KIND_WFI]) ||
          (v10b_ctrl_commit_count[V10B_KIND_SFENCE] !=
           v10b_terminal_count[V10B_KIND_SFENCE]) ||
          (v10b_ctrl_commit_count[V10B_KIND_FENCEI] !=
           v10b_terminal_count[V10B_KIND_FENCEI]) ||
          (v10b_ctrl_commit_count[V10B_KIND_FENCE] !=
           v10b_terminal_count[V10B_KIND_FENCE])) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] V10B mode=%0d ctrl-commit CSR=%0d ECALL=%0d XRET=%0d/%0d WFI=%0d/%0d SFENCE=%0d/%0d FENCEI=%0d/%0d FENCE=%0d/%0d IRQ=%0d",
                 mode_i,
                 v10b_ctrl_commit_count[V10B_KIND_CSR],
                 v10b_ctrl_commit_count[V10B_KIND_ECALL],
                 v10b_ctrl_commit_count[V10B_KIND_XRET],
                 v10b_terminal_count[V10B_KIND_XRET],
                 v10b_ctrl_commit_count[V10B_KIND_WFI],
                 v10b_terminal_count[V10B_KIND_WFI],
                 v10b_ctrl_commit_count[V10B_KIND_SFENCE],
                 v10b_terminal_count[V10B_KIND_SFENCE],
                 v10b_ctrl_commit_count[V10B_KIND_FENCEI],
                 v10b_terminal_count[V10B_KIND_FENCEI],
                 v10b_ctrl_commit_count[V10B_KIND_FENCE],
                 v10b_terminal_count[V10B_KIND_FENCE],
                 v10b_ctrl_commit_count[V10B_KIND_IRQ]);
      end

      if ((v10b_violation_count != 32'd0) ||
          (v10b_mmu_timing_mismatch_count != 32'd0) ||
          v10b_c1_check_pending_q || v10b_c2_check_pending_q ||
          v10b_mmu_expected_q || mmu_flush ||
          (v10b_mmu_flush_count !=
           (v10b_mmu_satp_source_count +
            v10b_mmu_sfence_source_count +
            v10b_mmu_fencei_source_count))) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] V10B mode=%0d violations=%0d mmu_mismatch=%0d C1_pending=%0d C2_pending=%0d mmu_expected=%0d mmu_flush=%0d mmu_sources=%0d/%0d/%0d mmu_out=%0d",
                 mode_i, v10b_violation_count,
                 v10b_mmu_timing_mismatch_count,
                 v10b_c1_check_pending_q, v10b_c2_check_pending_q,
                 v10b_mmu_expected_q, mmu_flush,
                 v10b_mmu_satp_source_count,
                 v10b_mmu_sfence_source_count,
                 v10b_mmu_fencei_source_count,
                 v10b_mmu_flush_count);
      end

      if (tb_errors == errors_before) begin
        $display("[V10B-SYSTEM-POST-FIRE] mode=%0d terminal={csr:%0d,ecall:%0d,xret:%0d,wfi:%0d,sfence:%0d,fencei:%0d,fence:%0d,irq:%0d} C1=matched C2=no-repeat ctrl=matched mmu={satp:%0d,sfence:%0d,fencei:%0d,out:%0d} PASS",
                 mode_i,
                 v10b_terminal_count[V10B_KIND_CSR],
                 v10b_terminal_count[V10B_KIND_ECALL],
                 v10b_terminal_count[V10B_KIND_XRET],
                 v10b_terminal_count[V10B_KIND_WFI],
                 v10b_terminal_count[V10B_KIND_SFENCE],
                 v10b_terminal_count[V10B_KIND_FENCEI],
                 v10b_terminal_count[V10B_KIND_FENCE],
                 v10b_terminal_count[V10B_KIND_IRQ],
                 v10b_mmu_satp_source_count,
                 v10b_mmu_sfence_source_count,
                 v10b_mmu_fencei_source_count,
                 v10b_mmu_flush_count);
      end
    end
  endtask

  always @(posedge clk) begin
    if (rst || flush) begin
      fetch_req_owner_pc <= {`XLEN{1'b0}};
      fetch_rsp_valid <= 1'b0;
      fetch_rsp_inst0 <= {`INST_W{1'b0}};
      fetch_rsp_inst1 <= {`INST_W{1'b0}};
      fetch_rsp_resp0 <= 2'b00;
      fetch_rsp_resp1 <= 2'b00;
    end else begin
      if (fetch_rsp_valid && fetch_rsp_ready) begin
        fetch_rsp_valid <= 1'b0;
      end
      if (fetch_req_valid && fetch_req_ready) begin
        fetch_req_owner_pc <= fetch_req_pc;
        fetch_rsp_valid <= 1'b1;
        fetch_rsp_inst0 <= program_word(fetch_req_pc);
        fetch_rsp_inst1 <= program_word(fetch_req_pc + 64'd4);
        fetch_rsp_resp0 <= 2'b00;
        fetch_rsp_resp1 <= 2'b00;
        if (fetch_req_pc == HANDLER_PC) begin
          saw_handler_fetch <= 1'b1;
          if (program_mode == MODE_IRQ_WFI) begin
            saw_irq_handler_fetch <= 1'b1;
            irq_timer <= 1'b0;
          end
        end
        if ((program_mode == MODE_M_VEC_IRQ) &&
            (fetch_req_pc == M_TIMER_VECTOR_PC)) begin
          saw_handler_fetch <= 1'b1;
          saw_irq_handler_fetch <= 1'b1;
          irq_timer <= 1'b0;
        end
        if (fetch_req_pc == S_HANDLER_PC) begin
          saw_smode_handler_fetch <= 1'b1;
          if (program_mode == MODE_S_EXT_IRQ) begin
            irq_external <= 1'b0;
          end
        end
        if ((program_mode == MODE_S_VEC_IRQ) &&
            (fetch_req_pc == S_EXTERNAL_VECTOR_PC)) begin
          saw_smode_handler_fetch <= 1'b1;
          irq_external <= 1'b0;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rst || flush) begin
      mem_req_ready <= 1'b1;
      fence_mem_ready_hold_count <= 0;
    end else if (program_mode == MODE_FENCE_ORDERING) begin
      // After the store translation probe is accepted, close the shared
      // request port long enough for a broken backend-no-op FENCE and its
      // younger device load to become contenders.  When the port reopens,
      // the architectural ordering contract requires the SQ drain to win.
      if (mem_req_valid && mem_req_ready && mem_req_probe &&
          (mem_req_addr == BASE_PC)) begin
        mem_req_ready <= 1'b0;
        fence_mem_ready_hold_count <= 40;
      end else if (fence_mem_ready_hold_count > 0) begin
        fence_mem_ready_hold_count <= fence_mem_ready_hold_count - 1;
        if (fence_mem_ready_hold_count == 1) begin
          mem_req_ready <= 1'b1;
        end
      end
    end else begin
      mem_req_ready <= 1'b1;
      fence_mem_ready_hold_count <= 0;
    end
  end

  always @(posedge clk) begin
    if (rst || flush) begin
      mem_rsp_valid <= 1'b0;
      mem_rsp_rdata <= {`XLEN{1'b0}};
      mem_rsp_error <= 1'b0;
      mem_rsp_attr_valid <= 1'b0;
      mem_rsp_class <= `OOO_MEM_CLASS_RSVD;
      mem_rsp_cacheable <= 1'b0;
      mem_rsp_owner_kind <= 2'b00;
      mem_rsp_owner_token <= 5'b00000;
      mem_rsp_mmu_epoch <= 2'b00;
      mem_rsp_fault_tval <= {`XLEN{1'b0}};
    end else begin
      if (mem_rsp_valid && mem_rsp_ready) mem_rsp_valid <= 1'b0;
      if (mem_req_valid && mem_req_ready) begin
        mem_rsp_valid <= 1'b1;
        // Store probes return the translated PA; ordinary reads get a stable
        // data signature so the younger device load can be checked end-to-end.
        mem_rsp_rdata <= mem_req_probe ? mem_req_addr :
                         (!mem_req_write ? 64'h0000_0000_1234_5678 :
                                           {`XLEN{1'b0}});
        mem_rsp_error <= tb_rsp_pma_fault;
        mem_rsp_attr_valid <= tb_rsp_pma_attr_valid;
        mem_rsp_class <= tb_rsp_pma_class;
        mem_rsp_cacheable <= tb_rsp_pma_attr_valid &&
            (tb_rsp_pma_class == `OOO_MEM_CLASS_CACHED);
        mem_rsp_owner_kind <= mem_req_owner_kind;
        mem_rsp_owner_token <= mem_req_owner_token;
        mem_rsp_mmu_epoch <= mem_req_mmu_epoch;
        mem_rsp_fault_tval <= mem_req_fault_tval;
      end
    end
  end

  task automatic observe_commit;
    input valid;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst;
    begin
      if (valid) begin
        if ((inst[6:0] == `OPCODE_SYSTEM) && (inst[14:12] != 3'b000)) begin
          saw_csr_commit <= 1'b1;
          if (pc == (BASE_PC + 64'h0c)) saw_lane1_csr_commit <= 1'b1;
          if (inst[31:20] == `CSR_SATP) saw_satp_commit <= 1'b1;
        end
        if (inst == inst_mret()) saw_mret_commit <= 1'b1;
        if (inst == inst_sret()) saw_sret_commit <= 1'b1;
        if (((program_mode == MODE_MRET_S_ILLEGAL) ||
             (program_mode == MODE_SRET_U_ILLEGAL)) &&
            (pc == S_ENTRY_PC || pc == (S_ENTRY_PC + 64'h04)) &&
            ((inst == inst_mret()) || (inst == inst_sret()))) begin
          saw_illegal_xret_commit <= 1'b1;
        end
        if (inst == inst_sfence_vma(5'd0, 5'd0)) saw_sfence_commit <= 1'b1;
        if (inst == inst_sinval_vma(5'd0, 5'd0)) saw_sinval_commit <= 1'b1;
        if (inst == inst_fencei()) saw_fencei_commit <= 1'b1;
        if (inst == inst_wfi()) saw_wfi_commit <= 1'b1;
      end
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      commit_total <= 0;
      fence_commit_count <= 32'd0;
      fence_store_probe_count <= 32'd0;
      fence_store_drain_count <= 32'd0;
      fence_device_read_count <= 32'd0;
      saw_fence_lane1_capture <= 1'b0;
      saw_fence_drain_wait <= 1'b0;
      saw_fence_busy_mem_idle_binding <= 1'b0;
      fence_mem_idle_binding_mismatch <= 1'b0;
      fence_retired_before_store_drain <= 1'b0;
      device_read_before_store_drain <= 1'b0;
      device_read_before_fence_retire <= 1'b0;
      v8k_dispatch_count <= 32'd0;
      v8k_birth_count <= 32'd0;
      v8k_exact_commit_count <= 32'd0;
      v8k_death_count <= 32'd0;
      v8k_birth_check_pending_q <= 1'b0;
      v8k_death_check_pending_q <= 1'b0;
      v8k_expected_pid_q <= {PRODUCER_ID_W{1'b0}};
      fdg_arch_trap_capture_count <= 32'd0;
      fdg_capture_pc_match_count <= 32'd0;
      fdg_capture_tval_match_count <= 32'd0;
      fdg_ordinary_backend_present_count <= 32'd0;
      fdg_core_backend_present_count <= 32'd0;
      fdg_commit_oracle_hit_count <= 32'd0;
      fdg_illegal_fp_commit_count <= 32'd0;
      xret_legal_csr_request_count <= 32'd0;
      xret_legal_commit_count <= 32'd0;
      xret_arch_trap_capture_count <= 32'd0;
      xret_capture_pc_match_count <= 32'd0;
      xret_capture_tval_match_count <= 32'd0;
      xret_request_oracle_hit_count <= 32'd0;
      xret_illegal_csr_request_count <= 32'd0;
      xret_commit_oracle_hit_count <= 32'd0;
      xret_illegal_commit_count <= 32'd0;
      vec_trap_mem_count <= 32'd0;
      vec_trap_ex_count <= 32'd0;
      vec_trap_irq_count <= 32'd0;
      vec_target_match_count <= 32'd0;
      vec_target_mismatch_count <= 32'd0;
      vec_exact_handler_fetch_count <= 32'd0;
      vec_wrong_base_fetch_count <= 32'd0;
      vec_xret_request_count <= 32'd0;
      vec_xret_commit_count <= 32'd0;
      vec_return_commit_count <= 32'd0;
    end else begin
      commit_total <= commit_total + commit0_valid + commit1_valid;
      observe_commit(commit0_valid, commit0_pc, commit0_inst);
      observe_commit(commit1_valid, commit1_pc, commit1_inst);

      // VECTORED-TRAP-G2/G3/G4 intentionally count every raw CsrFile request
      // pulse and every fetch/commit handshake.  No deduplication is permitted:
      // a repeated terminal transaction must make the exact-one checks fail.
      if ((program_mode == MODE_M_VEC_IRQ) ||
          (program_mode == MODE_S_VEC_IRQ) ||
          (program_mode == MODE_M_VEC_SYNC)) begin
        if (tb_csr_trap_mem_valid_w)
          vec_trap_mem_count <= vec_trap_mem_count + 32'd1;
        if (tb_csr_trap_ex_valid_w)
          vec_trap_ex_count <= vec_trap_ex_count + 32'd1;
        if (tb_csr_trap_irq_valid_w)
          vec_trap_irq_count <= vec_trap_irq_count + 32'd1;

        if (tb_csr_trap_mem_valid_w ||
            tb_csr_trap_ex_valid_w ||
            tb_csr_trap_irq_valid_w) begin
          if (((program_mode == MODE_M_VEC_IRQ) &&
               (tb_csr_trap_target_w == M_TIMER_VECTOR_PC)) ||
              ((program_mode == MODE_S_VEC_IRQ) &&
               (tb_csr_trap_target_w == S_EXTERNAL_VECTOR_PC)) ||
              ((program_mode == MODE_M_VEC_SYNC) &&
               (tb_csr_trap_target_w == HANDLER_PC))) begin
            vec_target_match_count <= vec_target_match_count + 32'd1;
          end else begin
            vec_target_mismatch_count <= vec_target_mismatch_count + 32'd1;
          end
        end

        if (fetch_req_valid && fetch_req_ready) begin
          if (((program_mode == MODE_M_VEC_IRQ) &&
               (fetch_req_pc == M_TIMER_VECTOR_PC)) ||
              ((program_mode == MODE_S_VEC_IRQ) &&
               (fetch_req_pc == S_EXTERNAL_VECTOR_PC)) ||
              ((program_mode == MODE_M_VEC_SYNC) &&
               (fetch_req_pc == HANDLER_PC))) begin
            vec_exact_handler_fetch_count <=
                vec_exact_handler_fetch_count + 32'd1;
          end
          if (((program_mode == MODE_M_VEC_IRQ) &&
               (fetch_req_pc == HANDLER_PC)) ||
              ((program_mode == MODE_S_VEC_IRQ) &&
               (fetch_req_pc == S_HANDLER_PC)) ||
              ((program_mode == MODE_M_VEC_SYNC) &&
               (fetch_req_pc == M_ECALL_WRONG_VECTOR_PC))) begin
            vec_wrong_base_fetch_count <= vec_wrong_base_fetch_count + 32'd1;
          end
        end

        if (((program_mode == MODE_M_VEC_IRQ) &&
             tb_csr_real_mret_valid_w &&
             (dut.pending_system_pc_q == (M_TIMER_VECTOR_PC + 64'h08))) ||
            ((program_mode == MODE_S_VEC_IRQ) &&
             tb_csr_sret_valid_w &&
             (dut.pending_system_pc_q == (S_EXTERNAL_VECTOR_PC + 64'h10))) ||
            ((program_mode == MODE_M_VEC_SYNC) &&
             tb_csr_real_mret_valid_w &&
             (dut.pending_system_pc_q == (HANDLER_PC + 64'h14)))) begin
          vec_xret_request_count <= vec_xret_request_count + 32'd1;
        end

        vec_xret_commit_count <= vec_xret_commit_count +
            (commit0_valid &&
             (((program_mode == MODE_M_VEC_IRQ) &&
               (commit0_pc == (M_TIMER_VECTOR_PC + 64'h08)) &&
               (commit0_inst == inst_mret())) ||
              ((program_mode == MODE_S_VEC_IRQ) &&
               (commit0_pc == (S_EXTERNAL_VECTOR_PC + 64'h10)) &&
               (commit0_inst == inst_sret())) ||
              ((program_mode == MODE_M_VEC_SYNC) &&
               (commit0_pc == (HANDLER_PC + 64'h14)) &&
               (commit0_inst == inst_mret())))) +
            (commit1_valid &&
             (((program_mode == MODE_M_VEC_IRQ) &&
               (commit1_pc == (M_TIMER_VECTOR_PC + 64'h08)) &&
               (commit1_inst == inst_mret())) ||
              ((program_mode == MODE_S_VEC_IRQ) &&
               (commit1_pc == (S_EXTERNAL_VECTOR_PC + 64'h10)) &&
               (commit1_inst == inst_sret())) ||
              ((program_mode == MODE_M_VEC_SYNC) &&
               (commit1_pc == (HANDLER_PC + 64'h14)) &&
               (commit1_inst == inst_mret()))));

        vec_return_commit_count <= vec_return_commit_count +
            (commit0_valid &&
             (((program_mode == MODE_M_VEC_IRQ) &&
               (commit0_pc == (BASE_PC + 64'h20)) &&
               (commit0_inst == inst_addi(5'd13, 5'd0, 12'h031))) ||
              ((program_mode == MODE_S_VEC_IRQ) &&
               (commit0_pc == (S_ENTRY_PC + 64'h14)) &&
               (commit0_inst == inst_addi(5'd7, 5'd0, 12'h032))) ||
              ((program_mode == MODE_M_VEC_SYNC) &&
               (commit0_pc == (BASE_PC + 64'h10)) &&
               (commit0_inst == inst_addi(5'd7, 5'd0, 12'h033))))) +
            (commit1_valid &&
             (((program_mode == MODE_M_VEC_IRQ) &&
               (commit1_pc == (BASE_PC + 64'h20)) &&
               (commit1_inst == inst_addi(5'd13, 5'd0, 12'h031))) ||
              ((program_mode == MODE_S_VEC_IRQ) &&
               (commit1_pc == (S_ENTRY_PC + 64'h14)) &&
               (commit1_inst == inst_addi(5'd7, 5'd0, 12'h032))) ||
              ((program_mode == MODE_M_VEC_SYNC) &&
               (commit1_pc == (BASE_PC + 64'h10)) &&
               (commit1_inst == inst_addi(5'd7, 5'd0, 12'h033)))));
      end

      // XRET-G1 legal controls use the same CsrFile request and architectural
      // commit interfaces as the illegal-return zero-side-effect oracles.
      if (program_mode == MODE_ECALL_MRET) begin
        if (tb_csr_real_mret_valid_w &&
            (dut.pending_system_pc_q == (HANDLER_PC + 64'h14))) begin
          xret_legal_csr_request_count <=
              xret_legal_csr_request_count + 32'd1;
        end
        xret_legal_commit_count <= xret_legal_commit_count +
            (commit0_valid && (commit0_pc == (HANDLER_PC + 64'h14)) &&
             (commit0_inst == inst_mret())) +
            (commit1_valid && (commit1_pc == (HANDLER_PC + 64'h14)) &&
             (commit1_inst == inst_mret()));
      end else if (program_mode == MODE_SMODE_BOOT) begin
        if (tb_csr_sret_valid_w &&
            (dut.pending_system_pc_q == (S_HANDLER_PC + 64'h14))) begin
          xret_legal_csr_request_count <=
              xret_legal_csr_request_count + 32'd1;
        end
        xret_legal_commit_count <= xret_legal_commit_count +
            (commit0_valid && (commit0_pc == (S_HANDLER_PC + 64'h14)) &&
             (commit0_inst == inst_sret())) +
            (commit1_valid && (commit1_pc == (S_HANDLER_PC + 64'h14)) &&
             (commit1_inst == inst_sret()));
      end

      if ((program_mode == MODE_MRET_S_ILLEGAL) ||
          (program_mode == MODE_SRET_U_ILLEGAL)) begin
        if (dut.u_control_plane.pending_trap_exit_capture_arch_w &&
            dut.u_control_plane.pending_trap_exit_capture_arch_valid_w) begin
          xret_arch_trap_capture_count <=
              xret_arch_trap_capture_count + 32'd1;
          if (((program_mode == MODE_MRET_S_ILLEGAL) &&
               (dut.u_control_plane.pending_trap_exit_capture_pc_w ==
                S_ENTRY_PC)) ||
              ((program_mode == MODE_SRET_U_ILLEGAL) &&
               (dut.u_control_plane.pending_trap_exit_capture_pc_w ==
                (S_ENTRY_PC + 64'h04)))) begin
            xret_capture_pc_match_count <=
                xret_capture_pc_match_count + 32'd1;
          end
          if (((program_mode == MODE_MRET_S_ILLEGAL) &&
               (dut.u_control_plane.pending_trap_exit_capture_tval_w ==
                64'h0000_0000_3020_0073)) ||
              ((program_mode == MODE_SRET_U_ILLEGAL) &&
               (dut.u_control_plane.pending_trap_exit_capture_tval_w ==
                64'h0000_0000_1020_0073))) begin
            xret_capture_tval_match_count <=
                xret_capture_tval_match_count + 32'd1;
          end
        end

        // Each illegal program first executes one known-legal MRET to enter
        // S/U mode.  These exact hits prove both zero oracles are live.
        if (tb_csr_real_mret_valid_w &&
            (((program_mode == MODE_MRET_S_ILLEGAL) &&
              (dut.pending_system_pc_q == (BASE_PC + 64'h24))) ||
             ((program_mode == MODE_SRET_U_ILLEGAL) &&
              (dut.pending_system_pc_q == (BASE_PC + 64'h1c))))) begin
          xret_request_oracle_hit_count <=
              xret_request_oracle_hit_count + 32'd1;
        end
        xret_commit_oracle_hit_count <= xret_commit_oracle_hit_count +
            (commit0_valid && (commit0_inst == inst_mret()) &&
             (((program_mode == MODE_MRET_S_ILLEGAL) &&
               (commit0_pc == (BASE_PC + 64'h24))) ||
              ((program_mode == MODE_SRET_U_ILLEGAL) &&
               (commit0_pc == (BASE_PC + 64'h1c))))) +
            (commit1_valid && (commit1_inst == inst_mret()) &&
             (((program_mode == MODE_MRET_S_ILLEGAL) &&
               (commit1_pc == (BASE_PC + 64'h24))) ||
              ((program_mode == MODE_SRET_U_ILLEGAL) &&
               (commit1_pc == (BASE_PC + 64'h1c)))));

`ifdef XRET_CSR_REQUEST_ORACLE_SENSITIVITY
        if (tb_csr_real_mret_valid_w &&
            (((program_mode == MODE_MRET_S_ILLEGAL) &&
              (dut.pending_system_pc_q == (BASE_PC + 64'h24))) ||
             ((program_mode == MODE_SRET_U_ILLEGAL) &&
              (dut.pending_system_pc_q == (BASE_PC + 64'h1c))))) begin
          xret_illegal_csr_request_count <=
              xret_illegal_csr_request_count + 32'd1;
        end
`else
        if (((program_mode == MODE_MRET_S_ILLEGAL) &&
             tb_csr_real_mret_valid_w &&
             (dut.pending_system_pc_q == S_ENTRY_PC)) ||
            ((program_mode == MODE_SRET_U_ILLEGAL) &&
             tb_csr_sret_valid_w &&
             (dut.pending_system_pc_q == (S_ENTRY_PC + 64'h04)))) begin
          xret_illegal_csr_request_count <=
              xret_illegal_csr_request_count + 32'd1;
        end
`endif

`ifdef XRET_COMMIT_ORACLE_SENSITIVITY
        xret_illegal_commit_count <= xret_illegal_commit_count +
            (commit0_valid && (commit0_inst == inst_mret()) &&
             (((program_mode == MODE_MRET_S_ILLEGAL) &&
               (commit0_pc == (BASE_PC + 64'h24))) ||
              ((program_mode == MODE_SRET_U_ILLEGAL) &&
               (commit0_pc == (BASE_PC + 64'h1c))))) +
            (commit1_valid && (commit1_inst == inst_mret()) &&
             (((program_mode == MODE_MRET_S_ILLEGAL) &&
               (commit1_pc == (BASE_PC + 64'h24))) ||
              ((program_mode == MODE_SRET_U_ILLEGAL) &&
               (commit1_pc == (BASE_PC + 64'h1c)))));
`else
        xret_illegal_commit_count <= xret_illegal_commit_count +
            (commit0_valid &&
             (((program_mode == MODE_MRET_S_ILLEGAL) &&
               (commit0_pc == S_ENTRY_PC) &&
               (commit0_inst == inst_mret())) ||
              ((program_mode == MODE_SRET_U_ILLEGAL) &&
               (commit0_pc == (S_ENTRY_PC + 64'h04)) &&
               (commit0_inst == inst_sret())))) +
            (commit1_valid &&
             (((program_mode == MODE_MRET_S_ILLEGAL) &&
               (commit1_pc == S_ENTRY_PC) &&
               (commit1_inst == inst_mret())) ||
              ((program_mode == MODE_SRET_U_ILLEGAL) &&
               (commit1_pc == (S_ENTRY_PC + 64'h04)) &&
               (commit1_inst == inst_sret()))));
`endif
      end

      // v8k real forward path: the lane1 CSRRW at BASE+0x0c is captured
      // pre-ROB, then re-dispatched through lane0.  Birth is edge-old (no mask
      // on the enqueue edge), the next cycle holds the exact full PID in the
      // shared census, and only the exact PID+PC commit can kill it.
      if (v8k_birth_check_pending_q) begin
        if (!dut.pending_system_producer_valid_w ||
            (dut.pending_system_producer_id_w != v8k_expected_pid_q) ||
            !dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.producer_live_mask_w[
                v8k_expected_pid_q]) begin
          $fatal(1, "[V8K-PRIV-BIRTH] enqueue failed to create exact live lease expected=%h held=%h valid=%b",
                 v8k_expected_pid_q, dut.pending_system_producer_id_w,
                 dut.pending_system_producer_valid_w);
        end
        v8k_birth_count <= v8k_birth_count + 32'd1;
        v8k_birth_check_pending_q <= 1'b0;
      end
      if ((program_mode == MODE_ECALL_MRET) &&
          dut.system_csr_dispatch_fire_w &&
          (dut.pending_system_pc_q == (BASE_PC + 64'h0c))) begin
        if (!dut.core_dispatch0_fire_w ||
            dut.pending_system_producer_valid_w ||
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.producer_live_mask_w[
                dut.core_dispatch0_producer_id_w]) begin
          $fatal(1, "[V8K-PRIV-DISPATCH] birth edge was not edge-old/core-fire exact pid=%h",
                 dut.core_dispatch0_producer_id_w);
        end
        v8k_dispatch_count <= v8k_dispatch_count + 32'd1;
        v8k_expected_pid_q <= dut.core_dispatch0_producer_id_w;
        v8k_birth_check_pending_q <= 1'b1;
      end
      if ((program_mode == MODE_ECALL_MRET) &&
          dut.pending_system_csr_commit_w &&
          (dut.pending_system_pc_q == (BASE_PC + 64'h0c))) begin
        if (!dut.pending_system_producer_valid_w ||
            (dut.pending_system_producer_id_w != v8k_expected_pid_q) ||
            (dut.core_commit0_producer_id_w != v8k_expected_pid_q) ||
            (dut.core_commit0_pc_w != (BASE_PC + 64'h0c)) ||
            dut.head0_csr_commit_w ||
            !dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.producer_live_mask_w[
                v8k_expected_pid_q]) begin
          $fatal(1, "[V8K-PRIV-EXACT-COMMIT] pending CSR lacked sole PID/PC/live witness expected=%h held=%h commit=%h pc=%h head0=%b",
                 v8k_expected_pid_q, dut.pending_system_producer_id_w,
                 dut.core_commit0_producer_id_w, dut.core_commit0_pc_w,
                 dut.head0_csr_commit_w);
        end
        v8k_exact_commit_count <= v8k_exact_commit_count + 32'd1;
        v8k_death_check_pending_q <= 1'b1;
      end
      if (v8k_death_check_pending_q) begin
        if (dut.pending_system_producer_valid_w ||
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend.producer_live_mask_w[
                v8k_expected_pid_q]) begin
          $fatal(1, "[V8K-PRIV-DEATH] exact commit did not release raw lease/mask pid=%h",
                 v8k_expected_pid_q);
        end
        v8k_death_count <= v8k_death_count + 32'd1;
        v8k_death_check_pending_q <= 1'b0;
      end
      if (program_mode == MODE_FDG_ARCH_TRAP) begin
        if (dut.u_control_plane.pending_trap_exit_capture_arch_w &&
            dut.u_control_plane.pending_trap_exit_capture_arch_valid_w) begin
          fdg_arch_trap_capture_count <=
              fdg_arch_trap_capture_count + 32'd1;
          if (dut.u_control_plane.pending_trap_exit_capture_pc_w ==
              (BASE_PC + 64'h10)) begin
            fdg_capture_pc_match_count <=
                fdg_capture_pc_match_count + 32'd1;
          end
          if (dut.u_control_plane.pending_trap_exit_capture_tval_w ==
              {{(`XLEN-`INST_W){1'b0}}, FDG_ILLEGAL_FP_INST}) begin
            fdg_capture_tval_match_count <=
                fdg_capture_tval_match_count + 32'd1;
          end
        end
        if (dut.dispatch0_arch_trap_w &&
            (dut.head_pc_w == (BASE_PC + 64'h10)) &&
            dut.u_frontend.frontend_dispatch_to_backend_valid_w) begin
          fdg_ordinary_backend_present_count <=
              fdg_ordinary_backend_present_count + 32'd1;
        end
        if (dut.dispatch0_arch_trap_w &&
            (dut.head_pc_w == (BASE_PC + 64'h10)) &&
            (dut.core_dispatch0_valid_w || dut.core_dispatch1_valid_w)) begin
          fdg_core_backend_present_count <=
              fdg_core_backend_present_count + 32'd1;
        end
        fdg_commit_oracle_hit_count <= fdg_commit_oracle_hit_count +
            (commit0_valid && (commit0_pc == (BASE_PC + 64'h0c)) &&
             (commit0_inst == inst_addi(5'd6, 5'd0, 12'h041))) +
            (commit1_valid && (commit1_pc == (BASE_PC + 64'h0c)) &&
             (commit1_inst == inst_addi(5'd6, 5'd0, 12'h041)));
`ifdef FDG_COMMIT_ORACLE_SENSITIVITY
        // Verification-only sensitivity configuration: point the exact same
        // commit-valid/PC observation chain at the known older ADDI.  The
        // illegal-commit zero oracle must become non-zero and reject the run.
        fdg_illegal_fp_commit_count <= fdg_illegal_fp_commit_count +
            (commit0_valid && (commit0_pc == (BASE_PC + 64'h0c))) +
            (commit1_valid && (commit1_pc == (BASE_PC + 64'h0c)));
`else
        fdg_illegal_fp_commit_count <= fdg_illegal_fp_commit_count +
            (commit0_valid && (commit0_pc == (BASE_PC + 64'h10))) +
            (commit1_valid && (commit1_pc == (BASE_PC + 64'h10)));
`endif
      end
      if (program_mode == MODE_FENCE_ORDERING) begin
        if ((commit0_valid && (commit0_inst == inst_fence())) ||
            (commit1_valid && (commit1_inst == inst_fence()))) begin
          fence_commit_count <= fence_commit_count +
              (commit0_valid && (commit0_inst == inst_fence())) +
              (commit1_valid && (commit1_inst == inst_fence()));
          if (fence_store_drain_count == 32'd0) begin
            fence_retired_before_store_drain <= 1'b1;
          end
        end

        if (mem_req_valid && mem_req_ready && mem_req_probe &&
            (mem_req_addr == BASE_PC)) begin
          fence_store_probe_count <= fence_store_probe_count + 32'd1;
        end
        if (mem_req_valid && mem_req_ready && mem_req_write &&
            mem_req_pretrans && mem_req_nokill &&
            (mem_req_addr == BASE_PC)) begin
          fence_store_drain_count <= fence_store_drain_count + 32'd1;
        end
        if (mem_req_valid && mem_req_ready && !mem_req_write &&
            !mem_req_probe && !mem_req_pretrans &&
            (mem_req_addr == 64'h0000_0000_1000_0000)) begin
          fence_device_read_count <= fence_device_read_count + 32'd1;
          if (fence_store_drain_count == 32'd0) begin
            device_read_before_store_drain <= 1'b1;
          end
          if (fence_commit_count == 32'd0) begin
            device_read_before_fence_retire <= 1'b1;
          end
        end

        if (dut.dispatch1_barrier_fire_w &&
            dut.pending_system_capture_lane1_w &&
            (dut.head_pc_w == (BASE_PC + 64'h08)) &&
            (dut.head_pc1_w == (BASE_PC + 64'h0c)) &&
            (dut.head_inst1_w == inst_fence())) begin
          saw_fence_lane1_capture <= 1'b1;
        end
        if (dut.pending_system_q &&
            (dut.pending_system_inst_q == inst_fence()) &&
            !dut.core_mem_idle_w && !dut.drain_complete_w) begin
          saw_fence_drain_wait <= 1'b1;
        end
        // FENCE-G1：程序在完整 memory-owner graph 非 idle 的周期，独立核对
        // CoreGlue 到 ControlPlane 的 mem_idle 端口仍消费同一个真实信号。
        // 该观测使跨模块常量化连接的可编译负向 RTL 版本必然被本程序检出。
        if (dut.pending_system_q &&
            (dut.pending_system_inst_q == inst_fence()) &&
            !dut.core_mem_idle_w) begin
          if (dut.u_control_plane.mem_idle_i === dut.core_mem_idle_w)
            saw_fence_busy_mem_idle_binding <= 1'b1;
          else
            fence_mem_idle_binding_mismatch <= 1'b1;
        end
      end
      // MODE_ECALL_MRET 的 0x08/0x0c 包是真实 decode/classify 链产生的
      // lane0 ADDI + lane1 CSRRW。candidate 钉住真实 barrier fire；match 再要求
      // pending capture 与 head-only probe 同拍命中，exact-one 可抓缺失或重复消费。
      if ((program_mode == MODE_ECALL_MRET) &&
          dut.dispatch1_barrier_fire_w &&
          (dut.head_pc_w == (BASE_PC + 64'h08)) &&
          (dut.head_pc1_w == (BASE_PC + 64'h0c)) &&
          (dut.head_inst0_w == inst_addi(5'd1, 5'd1, 12'h07c)) &&
          (dut.head_inst1_w == inst_csrrw(5'd5, `CSR_MTVEC, 5'd1)) &&
          !dut.dispatch0_system_w &&
          !dut.head0_csr_raw_w && dut.head1_csr_raw_w) begin
        t3k_lane1_candidate_count <= t3k_lane1_candidate_count + 32'd1;
        if (dut.pending_system_capture_lane1_w &&
            tb_csr_probe_valid_w &&
            (tb_csr_probe_addr_w == `CSR_MTVEC) &&
            (tb_csr_probe_funct3_w == 3'b001) &&
            (tb_csr_probe_rs1_idx_w == 5'd1) &&
            !tb_csr_illegal_w) begin
          if (t3k_lane1_match_count == 32'd0) begin
            $display("[T3K-LANE1-CSR-PROBE] pc0=%h pc1=%h addr=%03h funct3=%b rs1=%0d illegal=%b",
                     dut.head_pc_w, dut.head_pc1_w, tb_csr_probe_addr_w,
                     tb_csr_probe_funct3_w, tb_csr_probe_rs1_idx_w,
                     tb_csr_illegal_w);
          end
          t3k_lane1_match_count <= t3k_lane1_match_count + 32'd1;
          end
      end
      if ((program_mode == MODE_ECALL_MRET) &&
          dut.u_frontend.commit_e6_system_sfence_w &&
          (dut.pending_system_inst_q == inst_sinval_vma(5'd0, 5'd0)) &&
          (dut.u_frontend.commit_trap_reason_w == `REDIR_REASON_SFENCE)) begin
        saw_sinval_typed_redirect <= 1'b1;
      end
      if ((program_mode == MODE_ECALL_MRET) &&
          dut.u_frontend.commit_e6_system_fencei_w &&
          (dut.pending_system_inst_q == inst_fencei()) &&
          (dut.u_frontend.commit_trap_reason_w == `REDIR_REASON_FENCEI)) begin
        saw_fencei_typed_redirect <= 1'b1;
      end
      if ((program_mode == MODE_MRET_S_ILLEGAL) &&
          tb_csr_real_mret_valid_w &&
          (dut.pending_system_pc_q == S_ENTRY_PC)) begin
        saw_illegal_xret_csr_request <= 1'b1;
      end
      if ((program_mode == MODE_SRET_U_ILLEGAL) &&
          tb_csr_sret_valid_w) begin
        saw_illegal_xret_csr_request <= 1'b1;
      end
    end
  end

  // Product configuration split-domain SATP scoreboard:
  //   * lane1 SATP remains in the pending-SYSTEM/full-drain domain;
  //   * legal lane0/head0 SATP uses the queue-head C0/C1 transaction.
  // Raw request pulses are counted directly and C2 must be quiet.
  always @(posedge clk) begin
    if (rst) begin
      v10g_satp_lane1_capture_count <= 32'd0;
      v10g_qh_satp_birth_count <= 32'd0;
      v10g_qh_satp_c0_commit_count <= 32'd0;
      v10g_qh_satp_c0_barrier_count <= 32'd0;
      v10g_qh_satp_csrfile_request_count <= 32'd0;
      v10g_qh_satp_c1_apply_count <= 32'd0;
      v10g_qh_satp_owner_live_q <= 1'b0;
      v10g_qh_satp_expect_c1_q <= 1'b0;
      v10g_qh_satp_expect_c2_q <= 1'b0;
    end else begin
      if ((program_mode == MODE_SMODE_BOOT) &&
          dut.pending_system_capture_lane1_w &&
          (dut.head_pc1_w == (S_ENTRY_PC + 64'h04)) &&
          (dut.head_inst1_w == inst_csrrw(5'd0, `CSR_SATP, 5'd0))) begin
        v10g_satp_lane1_capture_count <=
            v10g_satp_lane1_capture_count + 32'd1;
      end

      if ((program_mode == MODE_QH_SATP) &&
          dut.head0_csr_dispatch_fire_w &&
          (dut.u_frontend.fifo_head_pc0_w == BASE_PC) &&
          (dut.head_inst0_w == inst_csrrw(5'd0, `CSR_SATP, 5'd0))) begin
        if (v10g_qh_satp_owner_live_q ||
            v10g_qh_satp_expect_c1_q) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10G head0 SATP birth overlapped an owner");
        end
        v10g_qh_satp_birth_count <= v10g_qh_satp_birth_count + 32'd1;
        v10g_qh_satp_owner_live_q <= 1'b1;
      end

      if ((program_mode == MODE_QH_SATP) &&
          dut.head0_csr_commit_w &&
          (dut.core_commit0_pc_w == BASE_PC) &&
          (dut.core_commit0_inst_w ==
           inst_csrrw(5'd0, `CSR_SATP, 5'd0))) begin
        if (!v10g_qh_satp_owner_live_q) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10G head0 SATP C0 lacked a live owner");
        end
        if (!dut.control_full_flush_barrier_w ||
            (dut.control_full_flush_reason_w !=
             `REDIR_REASON_CSR_COMMIT)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10G head0 SATP C0 barrier/reason missing");
        end else begin
          v10g_qh_satp_c0_barrier_count <=
              v10g_qh_satp_c0_barrier_count + 32'd1;
        end
        if (!tb_csr_commit_w || !tb_head0_csr_commit_w ||
            tb_pending_system_csr_commit_w ||
            !tb_csr_access_valid_w ||
            (tb_csr_access_addr_w != `CSR_SATP)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10G head0 SATP CsrFile request mismatch commit=%0b head0=%0b pending=%0b access=%0b addr=%03h",
                   tb_csr_commit_w, tb_head0_csr_commit_w,
                   tb_pending_system_csr_commit_w,
                   tb_csr_access_valid_w, tb_csr_access_addr_w);
        end else begin
          v10g_qh_satp_csrfile_request_count <=
              v10g_qh_satp_csrfile_request_count + 32'd1;
        end
        v10g_qh_satp_c0_commit_count <=
            v10g_qh_satp_c0_commit_count + 32'd1;
        v10g_qh_satp_owner_live_q <= 1'b0;
        v10g_qh_satp_expect_c1_q <= 1'b1;
      end

      if (v10g_qh_satp_expect_c1_q) begin
        if (!dut.control_event_apply_valid_w ||
            (dut.control_event_apply_reason_w !=
             `REDIR_REASON_CSR_COMMIT)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10G head0 SATP C1 typed apply missing");
        end else begin
          v10g_qh_satp_c1_apply_count <=
              v10g_qh_satp_c1_apply_count + 32'd1;
        end
        if (dut.head0_csr_inflight_w || dut.stop_pending_q) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10G head0 SATP C1 holder/stop not clear");
        end
        if (tb_csr_commit_w && !tb_pending_system_csr_commit_w) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10G head0 SATP C1 repeated CsrFile request");
        end
        v10g_qh_satp_expect_c1_q <= 1'b0;
        v10g_qh_satp_expect_c2_q <= 1'b1;
      end

      if (v10g_qh_satp_expect_c2_q) begin
        if (dut.head0_csr_commit_w ||
            (tb_csr_commit_w && !tb_pending_system_csr_commit_w) ||
            (dut.control_full_flush_barrier_w &&
             (dut.control_full_flush_reason_w ==
              `REDIR_REASON_CSR_COMMIT)) ||
            (dut.control_event_apply_valid_w &&
             (dut.control_event_apply_reason_w ==
              `REDIR_REASON_CSR_COMMIT))) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V10G head0 SATP C2 repeated request/apply");
        end
        v10g_qh_satp_expect_c2_q <= 1'b0;
      end
    end
  end

  // V10B production-glue scoreboard.  Every raw terminal request is counted
  // directly; no event is deduplicated.  The C1/C2 checks therefore expose a
  // repeated fire instead of hiding it behind a seen-bit.
  always @(posedge clk) begin
    if (rst) begin
      for (v10b_monitor_index = 0;
           v10b_monitor_index <= 8;
           v10b_monitor_index = v10b_monitor_index + 1) begin
        v10b_terminal_count[v10b_monitor_index] <= 32'd0;
        v10b_redirect_match_count[v10b_monitor_index] <= 32'd0;
        v10b_raw_request_match_count[v10b_monitor_index] <= 32'd0;
        v10b_c1_clear_count[v10b_monitor_index] <= 32'd0;
        v10b_c2_quiet_count[v10b_monitor_index] <= 32'd0;
        v10b_ctrl_commit_count[v10b_monitor_index] <= 32'd0;
      end
      v10b_violation_count <= 32'd0;
      v10b_mmu_satp_source_count <= 32'd0;
      v10b_mmu_sfence_source_count <= 32'd0;
      v10b_mmu_fencei_source_count <= 32'd0;
      v10b_mmu_flush_count <= 32'd0;
      v10b_mmu_timing_mismatch_count <= 32'd0;
      v10b_sfence_terminal_mask <= 4'b0000;
      v10b_sfence_commit_mask <= 4'b0000;
      v10b_mmu_expected_q <= 1'b0;
      v10b_c1_check_pending_q <= 1'b0;
      v10b_c1_kind_q <= V10B_KIND_NONE;
      v10b_c1_pc_q <= {`XLEN{1'b0}};
      v10b_c1_inst_q <= {`INST_W{1'b0}};
      v10b_c2_check_pending_q <= 1'b0;
      v10b_c2_kind_q <= V10B_KIND_NONE;
      v10b_c2_pc_q <= {`XLEN{1'b0}};
      v10b_c2_inst_q <= {`INST_W{1'b0}};
    end else begin
      if (mmu_flush !== v10b_mmu_expected_q) begin
        v10b_mmu_timing_mismatch_count <=
            v10b_mmu_timing_mismatch_count + 32'd1;
        v10b_violation_count <= v10b_violation_count + 32'd1;
        $display("[CHECK-FAIL] V10B MMU registered action got=%b expected_prior_source=%b @%0t",
                 mmu_flush, v10b_mmu_expected_q, $time);
      end
      v10b_mmu_expected_q <= v10b_mmu_source_w;
      if (mmu_flush)
        v10b_mmu_flush_count <= v10b_mmu_flush_count + 32'd1;
      if (dut.pending_system_satp_write_commit_w)
        v10b_mmu_satp_source_count <=
            v10b_mmu_satp_source_count + 32'd1;
      if (dut.pending_system_sfence_commit_w)
        v10b_mmu_sfence_source_count <=
            v10b_mmu_sfence_source_count + 32'd1;
      if (dut.pending_system_fencei_commit_w)
        v10b_mmu_fencei_source_count <=
            v10b_mmu_fencei_source_count + 32'd1;

      if (dut.ctrl_commit_valid_q &&
          (v10b_ctrl_commit_kind_w != V10B_KIND_NONE)) begin
        v10b_ctrl_commit_count[v10b_ctrl_commit_kind_w] <=
            v10b_ctrl_commit_count[v10b_ctrl_commit_kind_w] + 32'd1;
        if (v10b_ctrl_commit_kind_w == V10B_KIND_SFENCE)
          v10b_sfence_commit_mask <= v10b_sfence_commit_mask |
              v10b_sfence_encoding_bit(
                  dut.u_writeback.ctrl_commit_inst_q);
      end

      if (v10b_c2_check_pending_q) begin
        if (v10b_terminal_fire_w &&
            (v10b_terminal_kind_w == v10b_c2_kind_q) &&
            (dut.pending_system_pc_q == v10b_c2_pc_q) &&
            (dut.pending_system_inst_q == v10b_c2_inst_q)) begin
          v10b_violation_count <= v10b_violation_count + 32'd1;
          $display("[CHECK-FAIL] V10B C2 repeated terminal kind=%0d pc=%h inst=%h @%0t",
                   v10b_c2_kind_q, v10b_c2_pc_q,
                   v10b_c2_inst_q, $time);
        end else begin
          v10b_c2_quiet_count[v10b_c2_kind_q] <=
              v10b_c2_quiet_count[v10b_c2_kind_q] + 32'd1;
        end
        v10b_c2_check_pending_q <= 1'b0;
      end

      if (v10b_c1_check_pending_q) begin
        if (dut.pending_system_q || dut.stop_pending_q) begin
          v10b_violation_count <= v10b_violation_count + 32'd1;
          $display("[CHECK-FAIL] V10B C1 owner/stop not clear kind=%0d pc=%h inst=%h owner=%b stop=%b @%0t",
                   v10b_c1_kind_q, v10b_c1_pc_q,
                   v10b_c1_inst_q, dut.pending_system_q,
                   dut.stop_pending_q, $time);
        end else begin
          v10b_c1_clear_count[v10b_c1_kind_q] <=
              v10b_c1_clear_count[v10b_c1_kind_q] + 32'd1;
        end
        v10b_c1_check_pending_q <= 1'b0;
        v10b_c2_check_pending_q <= 1'b1;
        v10b_c2_kind_q <= v10b_c1_kind_q;
        v10b_c2_pc_q <= v10b_c1_pc_q;
        v10b_c2_inst_q <= v10b_c1_inst_q;
      end

      if (v10b_terminal_fire_w) begin
        v10b_terminal_count[v10b_terminal_kind_w] <=
            v10b_terminal_count[v10b_terminal_kind_w] + 32'd1;
        if (!dut.pending_system_q || !dut.stop_pending_q ||
            (v10b_pending_kind_count_w != 4'd1) ||
            (v10b_terminal_kind_w == V10B_KIND_NONE) ||
            v10b_c1_check_pending_q || v10b_c2_check_pending_q) begin
          v10b_violation_count <= v10b_violation_count + 32'd1;
          $display("[CHECK-FAIL] V10B C0 owner/kind overlap kind=%0d count=%0d owner=%b stop=%b C1=%b C2=%b @%0t",
                   v10b_terminal_kind_w, v10b_pending_kind_count_w,
                   dut.pending_system_q, dut.stop_pending_q,
                   v10b_c1_check_pending_q,
                   v10b_c2_check_pending_q, $time);
        end

        if (v10b_redirect_match_w) begin
          v10b_redirect_match_count[v10b_terminal_kind_w] <=
              v10b_redirect_match_count[v10b_terminal_kind_w] + 32'd1;
        end else begin
          v10b_violation_count <= v10b_violation_count + 32'd1;
          $display("[CHECK-FAIL] V10B typed redirect kind=%0d valid=%b reason=%0d expected_reason=%0d pc=%h expected_pc=%h flush=%b action=%0d @%0t",
                   v10b_terminal_kind_w,
                   dut.frontend_control_event_valid_w,
                   dut.frontend_control_event_reason_w,
                   v10b_reason_for_kind(v10b_terminal_kind_w),
                   dut.frontend_control_event_pc_w,
                   v10b_expected_redirect_pc_w,
                   dut.frontend_control_event_flush_fetch_w,
                   dut.frontend_control_event_backend_action_w,
                   $time);
        end

        if (v10b_raw_request_match_w) begin
          v10b_raw_request_match_count[v10b_terminal_kind_w] <=
              v10b_raw_request_match_count[v10b_terminal_kind_w] + 32'd1;
        end else begin
          v10b_violation_count <= v10b_violation_count + 32'd1;
          $display("[CHECK-FAIL] V10B selected CsrFile request kind=%0d count=%0d access=%b mem=%b ex=%b irq=%b mret=%b sret=%b @%0t",
                   v10b_terminal_kind_w, v10b_csr_request_count_w,
                   tb_csr_access_valid_w, tb_csr_trap_mem_valid_w,
                   tb_csr_trap_ex_valid_w, tb_csr_trap_irq_valid_w,
                   tb_csr_real_mret_valid_w, tb_csr_sret_valid_w,
                   $time);
        end

        if ((v10b_expected_mmu_source_w &&
             ((v10b_mmu_source_count_w != 3'd1) ||
              ((v10b_terminal_kind_w == V10B_KIND_SFENCE) &&
               !dut.pending_system_sfence_commit_w) ||
              ((v10b_terminal_kind_w == V10B_KIND_FENCEI) &&
               !dut.pending_system_fencei_commit_w) ||
              ((v10b_terminal_kind_w == V10B_KIND_CSR) &&
               !dut.pending_system_satp_write_commit_w))) ||
            (!v10b_expected_mmu_source_w &&
             (v10b_mmu_source_count_w != 3'd0))) begin
          v10b_violation_count <= v10b_violation_count + 32'd1;
          $display("[CHECK-FAIL] V10B MMU source kind=%0d expected=%b satp=%b sfence=%b fencei=%b @%0t",
                   v10b_terminal_kind_w,
                   v10b_expected_mmu_source_w,
                   dut.pending_system_satp_write_commit_w,
                   dut.pending_system_sfence_commit_w,
                   dut.pending_system_fencei_commit_w, $time);
        end

        if (v10b_terminal_kind_w == V10B_KIND_SFENCE)
          v10b_sfence_terminal_mask <= v10b_sfence_terminal_mask |
              v10b_sfence_encoding_bit(dut.pending_system_inst_q);

        v10b_c1_check_pending_q <= 1'b1;
        v10b_c1_kind_q <= v10b_terminal_kind_w;
        v10b_c1_pc_q <= dut.pending_system_pc_q;
        v10b_c1_inst_q <= dut.pending_system_inst_q;
      end
    end
  end

  initial begin
    tb_errors = 0;

    reset_dut(MODE_ECALL_MRET);
    run_until_exit(500);
    tb_check1("ecall/mret reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("ecall/mret exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("ecall is architectural trap, not sim exit", exit_is_ecall, 1'b0);
    tb_check1("ecall/mret no fatal trap", trap_valid, 1'b0);
    tb_check1("ecall handler fetch observed", saw_handler_fetch, 1'b1);
    tb_check1("csr old-value commits observed", saw_csr_commit, 1'b1);
    tb_check1("lane1 csr barrier commits", saw_lane1_csr_commit, 1'b1);
    tb_check32("T3K real lane0-ordinary/lane1-CSR fire count",
               t3k_lane1_candidate_count, 32'd1);
    tb_check32("T3K lane1 capture/probe/legality match count",
               t3k_lane1_match_count, 32'd1);
    tb_check32("V8K pending CSR real dispatch count", v8k_dispatch_count, 32'd1);
    tb_check32("V8K pending CSR exact lease birth count", v8k_birth_count, 32'd1);
    tb_check32("V8K pending CSR exact commit count",
               v8k_exact_commit_count, 32'd1);
    tb_check32("V8K pending CSR exact lease death count", v8k_death_count, 32'd1);
    tb_check1("mret synthetic commit observed", saw_mret_commit, 1'b1);
    tb_check1("sfence synthetic commit observed", saw_sfence_commit, 1'b1);
    tb_check1("sinval synthetic commit observed", saw_sinval_commit, 1'b1);
    tb_check1("sinval uses SFENCE typed redirect",
              saw_sinval_typed_redirect, 1'b1);
    tb_check1("fence.i synthetic commit observed", saw_fencei_commit, 1'b1);
    tb_check1("fence.i uses FENCEI typed redirect",
              saw_fencei_typed_redirect, 1'b1);
    tb_check1("wfi synthetic commit observed", saw_wfi_commit, 1'b1);
    if (saw_sfence_commit && saw_sinval_commit &&
        saw_sinval_typed_redirect && saw_fencei_commit &&
        saw_fencei_typed_redirect && saw_wfi_commit) begin
      $display("[V9W-SERIAL-TYPED-REDIRECT] sfence=1 sinval=1 sinval_reason=SFENCE fencei=1 fencei_reason=FENCEI wfi=1 PASS");
    end else begin
      $display("[V9W-SERIAL-TYPED-REDIRECT] sfence=%0d sinval=%0d sinval_reason=%0d fencei=%0d fencei_reason=%0d wfi=%0d FAIL",
               saw_sfence_commit, saw_sinval_commit,
               saw_sinval_typed_redirect, saw_fencei_commit,
               saw_fencei_typed_redirect, saw_wfi_commit);
    end
    tb_check64("mtvec old value returned", gpr(5'd5), 64'h0);
    tb_check64("mtvec readback after lane1 csrrw", gpr(5'd6), HANDLER_PC);
    tb_check64("ecall mcause", gpr(5'd8), {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_MMODE});
    tb_check64("ecall mepc plus four", gpr(5'd9), BASE_PC + 64'h20);
    tb_check64("handler body executed", gpr(5'd11), 64'h55);
    tb_check64("post mret body executed", gpr(5'd7), 64'h7);
    tb_check64("older alu survived system drain", gpr(5'd4), 64'h14);
    tb_check32("backend drained after ebreak", {27'b0, rob_count}, 32'd0);
    tb_check32("XRET-G1 legal MRET CsrFile request count",
               xret_legal_csr_request_count, 32'd1);
    tb_check32("XRET-G1 legal MRET commit count",
               xret_legal_commit_count, 32'd1);
    if ((xret_legal_csr_request_count == 32'd1) &&
        (xret_legal_commit_count == 32'd1) &&
        (gpr(5'd7) == 64'h7) && (rob_count == 5'd0)) begin
      $display("[XRET-G1-PROGRAM-LEGAL-MRET] csr_request=1 commit=1 return=1 backend_drained=1 PASS");
    end else begin
      $display("[XRET-G1-PROGRAM-LEGAL-MRET] csr_request=%0d commit=%0d return=%0d backend_drained=%0d FAIL",
               xret_legal_csr_request_count, xret_legal_commit_count,
               (gpr(5'd7) == 64'h7), (rob_count == 5'd0));
    end
    check_v10b_scoreboard(MODE_ECALL_MRET);
    tb_check1("V10B CSR terminal path exercised",
              v10b_terminal_count[V10B_KIND_CSR] != 32'd0, 1'b1);
    tb_check32("V10B ECALL terminal count",
               v10b_terminal_count[V10B_KIND_ECALL], 32'd1);
    tb_check32("V10B xRET terminal count",
               v10b_terminal_count[V10B_KIND_XRET], 32'd1);
    tb_check32("V10B WFI terminal count",
               v10b_terminal_count[V10B_KIND_WFI], 32'd1);
    tb_check32("V10B SFENCE-family terminal count",
               v10b_terminal_count[V10B_KIND_SFENCE], 32'd4);
    tb_check32("V10B FENCE.I terminal count",
               v10b_terminal_count[V10B_KIND_FENCEI], 32'd1);
    tb_check32("V10B no ordinary FENCE in mixed-system program",
               v10b_terminal_count[V10B_KIND_FENCE], 32'd0);
    tb_check32("V10B no IRQ in mixed-system program",
               v10b_terminal_count[V10B_KIND_IRQ], 32'd0);
    tb_check32("V10B four SFENCE-family C0 encodings",
               {28'b0, v10b_sfence_terminal_mask}, 32'h0000_000f);
    tb_check32("V10B four SFENCE-family C1 commits",
               {28'b0, v10b_sfence_commit_mask}, 32'h0000_000f);
    tb_check32("V10B mixed-system SATP MMU sources",
               v10b_mmu_satp_source_count, 32'd0);
    tb_check32("V10B mixed-system SFENCE MMU sources",
               v10b_mmu_sfence_source_count, 32'd4);
    tb_check32("V10B mixed-system FENCE.I MMU sources",
               v10b_mmu_fencei_source_count, 32'd1);
    tb_check32("V10B mixed-system registered MMU actions",
               v10b_mmu_flush_count, 32'd5);
    if ((tb_errors == 0) &&
        (v10b_terminal_count[V10B_KIND_ECALL] == 32'd1) &&
        (v10b_terminal_count[V10B_KIND_XRET] == 32'd1) &&
        (v10b_terminal_count[V10B_KIND_WFI] == 32'd1) &&
        (v10b_terminal_count[V10B_KIND_SFENCE] == 32'd4) &&
        (v10b_terminal_count[V10B_KIND_FENCEI] == 32'd1) &&
        (v10b_sfence_terminal_mask == 4'b1111) &&
        (v10b_sfence_commit_mask == 4'b1111) &&
        (v10b_mmu_sfence_source_count == 32'd4) &&
        (v10b_mmu_fencei_source_count == 32'd1) &&
        (v10b_mmu_flush_count == 32'd5)) begin
      $display("[V10B-SYSTEM-MIXED] csr=exercised ecall=1 xret=1 wfi=1 sfence-family=4 fencei=1 typed=exact raw-csr-selected=exact C1=clear C2=no-repeat mmu=5 PASS");
    end else begin
      $display("[V10B-SYSTEM-MIXED] csr=%0d ecall=%0d xret=%0d wfi=%0d sfence-family=%0d fencei=%0d typed-fencei=%0d/%0d C1=%0d/%0d C2=%0d/%0d mmu=%0d errors=%0d violations=%0d FAIL",
               v10b_terminal_count[V10B_KIND_CSR],
               v10b_terminal_count[V10B_KIND_ECALL],
               v10b_terminal_count[V10B_KIND_XRET],
               v10b_terminal_count[V10B_KIND_WFI],
               v10b_terminal_count[V10B_KIND_SFENCE],
               v10b_terminal_count[V10B_KIND_FENCEI],
               v10b_redirect_match_count[V10B_KIND_FENCEI],
               v10b_terminal_count[V10B_KIND_FENCEI],
               v10b_c1_clear_count[V10B_KIND_FENCEI],
               v10b_terminal_count[V10B_KIND_FENCEI],
               v10b_c2_quiet_count[V10B_KIND_FENCEI],
               v10b_terminal_count[V10B_KIND_FENCEI],
               v10b_mmu_flush_count, tb_errors,
               v10b_violation_count);
    end

    reset_dut(MODE_IRQ_WFI);
    irq_timer = 1'b1;
    run_until_exit(700);
    tb_check1("irq/wfi reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("irq/wfi exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("irq/wfi no fatal trap", trap_valid, 1'b0);
    tb_check1("timer interrupt handler fetch observed", saw_irq_handler_fetch, 1'b1);
    tb_check1("timer interrupt mret observed", saw_mret_commit, 1'b1);
    tb_check1("wfi commit observed after interrupt return", saw_wfi_commit, 1'b1);
    tb_check64("timer mcause interrupt bit", gpr(5'd14), `MCAUSE_INTERRUPT | 64'd7);
    tb_check64("timer handler body executed", gpr(5'd15), 64'h66);
    tb_check64("post interrupt wfi fallthrough", gpr(5'd13), 64'h0d);
    tb_check32("irq backend drained after ebreak", {27'b0, rob_count}, 32'd0);

    reset_dut(MODE_SMODE_BOOT);
    run_until_exit(1000);
    tb_check1("s-mode boot reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("s-mode boot exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("s-mode boot no fatal trap", trap_valid, 1'b0);
    tb_check1("s-mode delegated handler fetch observed", saw_smode_handler_fetch, 1'b1);
    tb_check1("mret into s-mode observed", saw_mret_commit, 1'b1);
    tb_check1("sret back to s-mode observed", saw_sret_commit, 1'b1);
    tb_check1("satp csr commit observed", saw_satp_commit, 1'b1);
    tb_check1("sfence after satp observed", saw_sfence_commit, 1'b1);
    tb_check64("s-mode older lane0 before SATP retires",
               gpr(5'd5), 64'h55);
    tb_check32("product SATP lane1 capture count",
               v10g_satp_lane1_capture_count, 32'd1);
    tb_check64("s-mode delegated scause", gpr(5'd8), {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_SMODE});
    tb_check64("s-mode sepc plus four", gpr(5'd9), S_ENTRY_PC + 64'h10);
    tb_check64("s-mode handler body executed", gpr(5'd10), 64'h66);
    tb_check64("post sret body executed", gpr(5'd7), 64'h77);
    tb_check32("s-mode backend drained after ebreak", {27'b0, rob_count}, 32'd0);
    tb_check32("XRET-G1 legal SRET CsrFile request count",
               xret_legal_csr_request_count, 32'd1);
    tb_check32("XRET-G1 legal SRET commit count",
               xret_legal_commit_count, 32'd1);
    if ((xret_legal_csr_request_count == 32'd1) &&
        (xret_legal_commit_count == 32'd1) &&
        (gpr(5'd7) == 64'h77) && (rob_count == 5'd0)) begin
      $display("[XRET-G1-PROGRAM-LEGAL-SRET] csr_request=1 commit=1 return=1 backend_drained=1 PASS");
    end else begin
      $display("[XRET-G1-PROGRAM-LEGAL-SRET] csr_request=%0d commit=%0d return=%0d backend_drained=%0d FAIL",
               xret_legal_csr_request_count, xret_legal_commit_count,
               (gpr(5'd7) == 64'h77), (rob_count == 5'd0));
    end
    check_v10b_scoreboard(MODE_SMODE_BOOT);
    tb_check32("V10B SATP write MMU source count",
               v10b_mmu_satp_source_count, 32'd1);
    tb_check32("V10B S-mode SFENCE MMU source count",
               v10b_mmu_sfence_source_count, 32'd1);
    tb_check32("V10B S-mode FENCE.I MMU source count",
               v10b_mmu_fencei_source_count, 32'd0);
    tb_check32("V10B SATP plus SFENCE registered MMU action count",
               v10b_mmu_flush_count, 32'd2);
    if ((v10b_mmu_satp_source_count == 32'd1) &&
        (v10b_mmu_sfence_source_count == 32'd1) &&
        (v10b_mmu_fencei_source_count == 32'd0) &&
        (v10b_mmu_flush_count == 32'd2) &&
        (v10g_satp_lane1_capture_count == 32'd1)) begin
      $display("[V10B-SATP-MMU] lane1-capture=1 exact-csr-commit=1 sfence=1 registered-mmu-actions=2 C1=clear C2=no-repeat PASS");
    end

    reset_dut(MODE_SBI_ECALL);
    run_until_exit(1000);
    tb_check1("sbi ecall reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("sbi ecall exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("sbi ecall is architectural trap, not sim exit", exit_is_ecall, 1'b0);
    tb_check1("sbi ecall no fatal trap", trap_valid, 1'b0);
    tb_check1("sbi m-mode handler fetch observed", saw_handler_fetch, 1'b1);
    tb_check1("sbi path did not enter s-mode handler", saw_smode_handler_fetch, 1'b0);
    tb_check1("sbi handoff mret observed", saw_mret_commit, 1'b1);
    tb_check64("sbi mcause is s-mode ecall", gpr(5'd8),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_SMODE});
    tb_check64("sbi mepc points at s ecall", gpr(5'd12),
               S_ENTRY_PC + 64'h04);
    tb_check64("sbi mepc return target", gpr(5'd9),
               S_ENTRY_PC + 64'h08);
    tb_check64("sbi trap recorded mpp=s",
               gpr(5'd10) & `MSTATUS_MPP_MASK, `MSTATUS_MPP_S);
    tb_check64("sbi m-mode handler body executed", gpr(5'd11), 64'h6b);
    tb_check64("sbi s-mode pre-ecall body executed", gpr(5'd5), 64'h123);
    tb_check64("sbi returned to s-mode body", gpr(5'd7), 64'h5a);
    tb_check32("sbi backend drained after ebreak", {27'b0, rob_count}, 32'd0);

    reset_dut(MODE_S_EXT_IRQ);
    irq_external = 1'b1;
    run_until_exit(1000);
    tb_check1("s external irq reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("s external irq exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("s external irq no fatal trap", trap_valid, 1'b0);
    tb_check1("s external irq enters s handler", saw_smode_handler_fetch, 1'b1);
    tb_check1("s external irq does not enter m handler", saw_handler_fetch, 1'b0);
    tb_check1("s external irq sret observed", saw_sret_commit, 1'b1);
    tb_check1("s external irq wfi fallthrough observed", saw_wfi_commit, 1'b1);
    tb_check64("s external irq scause", gpr(5'd8),
               `MCAUSE_INTERRUPT | {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `IRQ_CAUSE_SEI});
    tb_check64("s external irq sepc", gpr(5'd9), S_ENTRY_PC + 64'h10);
    tb_check64("s external irq recorded spp=s",
               gpr(5'd10) & `MSTATUS_SPP, `MSTATUS_SPP);
    tb_check64("s external irq handler body executed", gpr(5'd11), 64'h72);
    tb_check64("s external irq returned to s body", gpr(5'd7), 64'h71);
    tb_check32("s external irq backend drained after ebreak", {27'b0, rob_count}, 32'd0);

    reset_dut(MODE_M_VEC_IRQ);
    irq_timer = 1'b1;
    run_until_exit(1000);
    tb_check1("m vectored timer irq reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("m vectored timer irq exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("m vectored timer irq has no terminal trap", trap_valid, 1'b0);
    tb_check32("m vectored timer irq raw mem request count",
               vec_trap_mem_count, 32'd0);
    tb_check32("m vectored timer irq raw ex request count",
               vec_trap_ex_count, 32'd0);
    tb_check32("m vectored timer irq raw irq request count",
               vec_trap_irq_count, 32'd1);
    tb_check32("m vectored timer irq target match count",
               vec_target_match_count, 32'd1);
    tb_check32("m vectored timer irq target mismatch count",
               vec_target_mismatch_count, 32'd0);
    tb_check32("m vectored timer irq exact handler fetch count",
               vec_exact_handler_fetch_count, 32'd1);
    tb_check32("m vectored timer irq wrong base fetch count",
               vec_wrong_base_fetch_count, 32'd0);
    tb_check32("m vectored timer irq mret request count",
               vec_xret_request_count, 32'd1);
    tb_check32("m vectored timer irq mret commit count",
               vec_xret_commit_count, 32'd1);
    tb_check32("m vectored timer irq return commit count",
               vec_return_commit_count, 32'd1);
    tb_check64("m vectored timer irq mcause", gpr(5'd14),
               `MCAUSE_INTERRUPT | 64'd7);
    tb_check64("m vectored timer irq handler body", gpr(5'd15), 64'h61);
    tb_check64("m vectored timer irq return body", gpr(5'd13), 64'h31);
    tb_check32("m vectored timer irq backend drained",
               {27'b0, rob_count}, 32'd0);
    if (exit_valid && exit_is_ebreak && !trap_valid &&
        (vec_trap_mem_count == 32'd0) &&
        (vec_trap_ex_count == 32'd0) &&
        (vec_trap_irq_count == 32'd1) &&
        (vec_target_match_count == 32'd1) &&
        (vec_target_mismatch_count == 32'd0) &&
        (vec_exact_handler_fetch_count == 32'd1) &&
        (vec_wrong_base_fetch_count == 32'd0) &&
        (vec_xret_request_count == 32'd1) &&
        (vec_xret_commit_count == 32'd1) &&
        (vec_return_commit_count == 32'd1) &&
        (gpr(5'd14) == (`MCAUSE_INTERRUPT | 64'd7)) &&
        (gpr(5'd15) == 64'h61) && (gpr(5'd13) == 64'h31) &&
        (rob_count == 5'd0)) begin
      $display("[VECTORED-TRAP-G2-M-IRQ] trap_mem=0 trap_ex=0 trap_irq=1 target_match=1 target_mismatch=0 exact_handler_fetch=1 wrong_base_fetch=0 xret_request=1 xret_commit=1 return_commit=1 cause=7 handler_body=1 backend_drained=1 PASS");
    end else begin
      $display("[VECTORED-TRAP-G2-M-IRQ] trap_mem=%0d trap_ex=%0d trap_irq=%0d target_match=%0d target_mismatch=%0d exact_handler_fetch=%0d wrong_base_fetch=%0d xret_request=%0d xret_commit=%0d return_commit=%0d cause_match=%0d handler_body=%0d backend_drained=%0d FAIL",
               vec_trap_mem_count, vec_trap_ex_count, vec_trap_irq_count,
               vec_target_match_count, vec_target_mismatch_count,
               vec_exact_handler_fetch_count, vec_wrong_base_fetch_count,
               vec_xret_request_count, vec_xret_commit_count,
               vec_return_commit_count,
               (gpr(5'd14) == (`MCAUSE_INTERRUPT | 64'd7)),
               (gpr(5'd15) == 64'h61), (rob_count == 5'd0));
    end
    check_v10b_scoreboard(MODE_M_VEC_IRQ);
    tb_check32("V10B IRQ terminal count",
               v10b_terminal_count[V10B_KIND_IRQ], 32'd1);
    if ((v10b_terminal_count[V10B_KIND_IRQ] == 32'd1) &&
        (v10b_raw_request_match_count[V10B_KIND_IRQ] == 32'd1) &&
        (v10b_redirect_match_count[V10B_KIND_IRQ] == 32'd1) &&
        (v10b_c1_clear_count[V10B_KIND_IRQ] == 32'd1) &&
        (v10b_c2_quiet_count[V10B_KIND_IRQ] == 32'd1)) begin
      $display("[V10B-IRQ-POST-FIRE] raw-irq=1 typed-trap=1 C1-owner-stop-clear=1 C2-repeat=0 PASS");
    end

    reset_dut(MODE_S_VEC_IRQ);
    irq_external = 1'b1;
    run_until_exit(1200);
    tb_check1("s vectored external irq reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("s vectored external irq exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("s vectored external irq has no terminal trap", trap_valid, 1'b0);
    tb_check32("s vectored external irq raw mem request count",
               vec_trap_mem_count, 32'd0);
    tb_check32("s vectored external irq raw ex request count",
               vec_trap_ex_count, 32'd0);
    tb_check32("s vectored external irq raw irq request count",
               vec_trap_irq_count, 32'd1);
    tb_check32("s vectored external irq target match count",
               vec_target_match_count, 32'd1);
    tb_check32("s vectored external irq target mismatch count",
               vec_target_mismatch_count, 32'd0);
    tb_check32("s vectored external irq exact handler fetch count",
               vec_exact_handler_fetch_count, 32'd1);
    tb_check32("s vectored external irq wrong base fetch count",
               vec_wrong_base_fetch_count, 32'd0);
    tb_check32("s vectored external irq sret request count",
               vec_xret_request_count, 32'd1);
    tb_check32("s vectored external irq sret commit count",
               vec_xret_commit_count, 32'd1);
    tb_check32("s vectored external irq return commit count",
               vec_return_commit_count, 32'd1);
    tb_check64("s vectored external irq scause", gpr(5'd8),
               `MCAUSE_INTERRUPT |
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `IRQ_CAUSE_SEI});
    tb_check64("s vectored external irq sepc", gpr(5'd9),
               S_ENTRY_PC + 64'h10);
    tb_check64("s vectored external irq recorded spp=s",
               gpr(5'd10) & `MSTATUS_SPP, `MSTATUS_SPP);
    tb_check64("s vectored external irq handler body", gpr(5'd11), 64'h63);
    tb_check64("s vectored external irq return body", gpr(5'd7), 64'h32);
    tb_check32("s vectored external irq backend drained",
               {27'b0, rob_count}, 32'd0);
    if (exit_valid && exit_is_ebreak && !trap_valid &&
        (vec_trap_mem_count == 32'd0) &&
        (vec_trap_ex_count == 32'd0) &&
        (vec_trap_irq_count == 32'd1) &&
        (vec_target_match_count == 32'd1) &&
        (vec_target_mismatch_count == 32'd0) &&
        (vec_exact_handler_fetch_count == 32'd1) &&
        (vec_wrong_base_fetch_count == 32'd0) &&
        (vec_xret_request_count == 32'd1) &&
        (vec_xret_commit_count == 32'd1) &&
        (vec_return_commit_count == 32'd1) &&
        (gpr(5'd8) ==
         (`MCAUSE_INTERRUPT |
          {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `IRQ_CAUSE_SEI})) &&
        (gpr(5'd11) == 64'h63) && (gpr(5'd7) == 64'h32) &&
        (rob_count == 5'd0)) begin
      $display("[VECTORED-TRAP-G3-S-IRQ] trap_mem=0 trap_ex=0 trap_irq=1 target_match=1 target_mismatch=0 exact_handler_fetch=1 wrong_base_fetch=0 xret_request=1 xret_commit=1 return_commit=1 cause=9 handler_body=1 backend_drained=1 PASS");
    end else begin
      $display("[VECTORED-TRAP-G3-S-IRQ] trap_mem=%0d trap_ex=%0d trap_irq=%0d target_match=%0d target_mismatch=%0d exact_handler_fetch=%0d wrong_base_fetch=%0d xret_request=%0d xret_commit=%0d return_commit=%0d cause_match=%0d handler_body=%0d backend_drained=%0d FAIL",
               vec_trap_mem_count, vec_trap_ex_count, vec_trap_irq_count,
               vec_target_match_count, vec_target_mismatch_count,
               vec_exact_handler_fetch_count, vec_wrong_base_fetch_count,
               vec_xret_request_count, vec_xret_commit_count,
               vec_return_commit_count,
               (gpr(5'd8) ==
                (`MCAUSE_INTERRUPT |
                 {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `IRQ_CAUSE_SEI})),
               (gpr(5'd11) == 64'h63), (rob_count == 5'd0));
    end

    reset_dut(MODE_M_VEC_SYNC);
    run_until_exit(1000);
    tb_check1("m vectored-mode ecall reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("m vectored-mode ecall exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("m vectored-mode ecall has no terminal trap", trap_valid, 1'b0);
    tb_check32("m vectored-mode ecall raw mem request count",
               vec_trap_mem_count, 32'd0);
    tb_check32("m vectored-mode ecall raw ex request count",
               vec_trap_ex_count, 32'd1);
    tb_check32("m vectored-mode ecall raw irq request count",
               vec_trap_irq_count, 32'd0);
    tb_check32("m vectored-mode ecall base target match count",
               vec_target_match_count, 32'd1);
    tb_check32("m vectored-mode ecall target mismatch count",
               vec_target_mismatch_count, 32'd0);
    tb_check32("m vectored-mode ecall exact base fetch count",
               vec_exact_handler_fetch_count, 32'd1);
    tb_check32("m vectored-mode ecall wrong vector fetch count",
               vec_wrong_base_fetch_count, 32'd0);
    tb_check32("m vectored-mode ecall mret request count",
               vec_xret_request_count, 32'd1);
    tb_check32("m vectored-mode ecall mret commit count",
               vec_xret_commit_count, 32'd1);
    tb_check32("m vectored-mode ecall return commit count",
               vec_return_commit_count, 32'd1);
    tb_check64("m vectored-mode ecall mcause", gpr(5'd8),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_MMODE});
    tb_check64("m vectored-mode ecall mepc plus four", gpr(5'd9),
               BASE_PC + 64'h10);
    tb_check64("m vectored-mode ecall handler body", gpr(5'd11), 64'h62);
    tb_check64("m vectored-mode ecall return body", gpr(5'd7), 64'h33);
    tb_check32("m vectored-mode ecall backend drained",
               {27'b0, rob_count}, 32'd0);
    if (exit_valid && exit_is_ebreak && !trap_valid &&
        (vec_trap_mem_count == 32'd0) &&
        (vec_trap_ex_count == 32'd1) &&
        (vec_trap_irq_count == 32'd0) &&
        (vec_target_match_count == 32'd1) &&
        (vec_target_mismatch_count == 32'd0) &&
        (vec_exact_handler_fetch_count == 32'd1) &&
        (vec_wrong_base_fetch_count == 32'd0) &&
        (vec_xret_request_count == 32'd1) &&
        (vec_xret_commit_count == 32'd1) &&
        (vec_return_commit_count == 32'd1) &&
        (gpr(5'd8) ==
         {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_MMODE}) &&
        (gpr(5'd11) == 64'h62) && (gpr(5'd7) == 64'h33) &&
        (rob_count == 5'd0)) begin
      $display("[VECTORED-TRAP-G4-M-SYNC] trap_mem=0 trap_ex=1 trap_irq=0 target_match=1 target_mismatch=0 exact_handler_fetch=1 wrong_vector_fetch=0 xret_request=1 xret_commit=1 return_commit=1 cause=11 handler_body=1 backend_drained=1 PASS");
    end else begin
      $display("[VECTORED-TRAP-G4-M-SYNC] trap_mem=%0d trap_ex=%0d trap_irq=%0d target_match=%0d target_mismatch=%0d exact_handler_fetch=%0d wrong_vector_fetch=%0d xret_request=%0d xret_commit=%0d return_commit=%0d cause_match=%0d handler_body=%0d backend_drained=%0d FAIL",
               vec_trap_mem_count, vec_trap_ex_count, vec_trap_irq_count,
               vec_target_match_count, vec_target_mismatch_count,
               vec_exact_handler_fetch_count, vec_wrong_base_fetch_count,
               vec_xret_request_count, vec_xret_commit_count,
               vec_return_commit_count,
               (gpr(5'd8) ==
                {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_MMODE}),
               (gpr(5'd11) == 64'h62), (rob_count == 5'd0));
    end

    reset_dut(MODE_MRET_S_ILLEGAL);
    run_until_exit(1000);
    tb_check1("s-mode mret reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("s-mode mret exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("s-mode mret no fatal trap", trap_valid, 1'b0);
    tb_check1("s-mode mret enters m handler", saw_handler_fetch, 1'b1);
    tb_check1("s-mode illegal mret does not commit", saw_illegal_xret_commit, 1'b0);
    tb_check1("s-mode illegal mret does not request CsrFile mret",
              saw_illegal_xret_csr_request, 1'b0);
    tb_check64("s-mode mret mcause", gpr(5'd8),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ILLEGAL_INST});
    tb_check64("s-mode mret mepc", gpr(5'd12), S_ENTRY_PC);
    tb_check64("s-mode mret mtval", gpr(5'd10), 64'h0000_0000_3020_0073);
    tb_check64("s-mode mret handler body", gpr(5'd11), 64'h76);
    tb_check64("s-mode mret returns after fault", gpr(5'd7), 64'h75);
    tb_check32("s-mode mret backend drained", {27'b0, rob_count}, 32'd0);
    tb_check32("s-mode illegal mret architectural-trap capture count",
               xret_arch_trap_capture_count, 32'd1);
    tb_check32("s-mode illegal mret capture PC match count",
               xret_capture_pc_match_count, 32'd1);
    tb_check32("s-mode illegal mret capture tval match count",
               xret_capture_tval_match_count, 32'd1);
    tb_check32("s-mode illegal mret request oracle hit count",
               xret_request_oracle_hit_count, 32'd1);
    tb_check32("s-mode illegal mret CSR request count",
               xret_illegal_csr_request_count, 32'd0);
    tb_check32("s-mode illegal mret commit oracle hit count",
               xret_commit_oracle_hit_count, 32'd1);
    tb_check32("s-mode illegal mret commit count",
               xret_illegal_commit_count, 32'd0);
    if ((xret_arch_trap_capture_count == 32'd1) &&
        (xret_capture_pc_match_count == 32'd1) &&
        (xret_capture_tval_match_count == 32'd1) &&
        (xret_request_oracle_hit_count == 32'd1) &&
        (xret_illegal_csr_request_count == 32'd0) &&
        (xret_commit_oracle_hit_count == 32'd1) &&
        (xret_illegal_commit_count == 32'd0) && saw_handler_fetch &&
        (gpr(5'd8) == {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ILLEGAL_INST}) &&
        (gpr(5'd12) == S_ENTRY_PC) &&
        (gpr(5'd10) == 64'h0000_0000_3020_0073) &&
        (gpr(5'd7) == 64'h75) && (rob_count == 5'd0)) begin
      $display("[XRET-G1-PROGRAM-ILLEGAL-MRET] arch_trap_capture=1 capture_pc_match=1 capture_tval_match=1 request_oracle_hits=1 csr_request=0 commit_oracle_hits=1 commit=0 handler=1 cause=2 csr_mepc_match=1 csr_mtval_match=1 return=1 backend_drained=1 PASS");
    end else begin
      $display("[XRET-G1-PROGRAM-ILLEGAL-MRET] arch_trap_capture=%0d capture_pc_match=%0d capture_tval_match=%0d request_oracle_hits=%0d csr_request=%0d commit_oracle_hits=%0d commit=%0d handler=%0d cause=%0d csr_mepc_match=%0d csr_mtval_match=%0d return=%0d backend_drained=%0d FAIL",
               xret_arch_trap_capture_count, xret_capture_pc_match_count,
               xret_capture_tval_match_count, xret_request_oracle_hit_count,
               xret_illegal_csr_request_count, xret_commit_oracle_hit_count,
               xret_illegal_commit_count, saw_handler_fetch, gpr(5'd8),
               (gpr(5'd12) == S_ENTRY_PC),
               (gpr(5'd10) == 64'h0000_0000_3020_0073),
               (gpr(5'd7) == 64'h75), (rob_count == 5'd0));
    end

    reset_dut(MODE_SRET_U_ILLEGAL);
    run_until_exit(1000);
    tb_check1("u-mode lane1 sret reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("u-mode lane1 sret exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("u-mode lane1 sret no fatal trap", trap_valid, 1'b0);
    tb_check1("u-mode lane1 sret enters m handler", saw_handler_fetch, 1'b1);
    tb_check1("u-mode illegal sret does not commit", saw_illegal_xret_commit, 1'b0);
    tb_check1("u-mode illegal sret does not request CsrFile sret",
              saw_illegal_xret_csr_request, 1'b0);
    tb_check1("u-mode illegal sret is not a legal xret commit", saw_sret_commit, 1'b0);
    tb_check64("u-mode lane1 sret mcause", gpr(5'd8),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ILLEGAL_INST});
    tb_check64("u-mode lane1 sret mepc", gpr(5'd12), S_ENTRY_PC + 64'h04);
    tb_check64("u-mode lane1 sret mtval", gpr(5'd10), 64'h0000_0000_1020_0073);
    tb_check64("u-mode lane1 sret older instruction", gpr(5'd6), 64'h65);
    tb_check64("u-mode lane1 sret handler body", gpr(5'd11), 64'h76);
    tb_check64("u-mode lane1 sret returns after fault", gpr(5'd7), 64'h75);
    tb_check32("u-mode lane1 sret backend drained", {27'b0, rob_count}, 32'd0);
    tb_check32("u-mode illegal sret architectural-trap capture count",
               xret_arch_trap_capture_count, 32'd1);
    tb_check32("u-mode illegal sret capture PC match count",
               xret_capture_pc_match_count, 32'd1);
    tb_check32("u-mode illegal sret capture tval match count",
               xret_capture_tval_match_count, 32'd1);
    tb_check32("u-mode illegal sret request oracle hit count",
               xret_request_oracle_hit_count, 32'd1);
    tb_check32("u-mode illegal sret CSR request count",
               xret_illegal_csr_request_count, 32'd0);
    tb_check32("u-mode illegal sret commit oracle hit count",
               xret_commit_oracle_hit_count, 32'd1);
    tb_check32("u-mode illegal sret commit count",
               xret_illegal_commit_count, 32'd0);
    if ((xret_arch_trap_capture_count == 32'd1) &&
        (xret_capture_pc_match_count == 32'd1) &&
        (xret_capture_tval_match_count == 32'd1) &&
        (xret_request_oracle_hit_count == 32'd1) &&
        (xret_illegal_csr_request_count == 32'd0) &&
        (xret_commit_oracle_hit_count == 32'd1) &&
        (xret_illegal_commit_count == 32'd0) && saw_handler_fetch &&
        (gpr(5'd8) == {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ILLEGAL_INST}) &&
        (gpr(5'd12) == (S_ENTRY_PC + 64'h04)) &&
        (gpr(5'd10) == 64'h0000_0000_1020_0073) &&
        (gpr(5'd6) == 64'h65) && (gpr(5'd7) == 64'h75) &&
        (rob_count == 5'd0)) begin
      $display("[XRET-G1-PROGRAM-ILLEGAL-SRET] arch_trap_capture=1 capture_pc_match=1 capture_tval_match=1 request_oracle_hits=1 csr_request=0 commit_oracle_hits=1 commit=0 handler=1 cause=2 csr_mepc_match=1 csr_mtval_match=1 older_lane0=1 return=1 backend_drained=1 PASS");
    end else begin
      $display("[XRET-G1-PROGRAM-ILLEGAL-SRET] arch_trap_capture=%0d capture_pc_match=%0d capture_tval_match=%0d request_oracle_hits=%0d csr_request=%0d commit_oracle_hits=%0d commit=%0d handler=%0d cause=%0d csr_mepc_match=%0d csr_mtval_match=%0d older_lane0=%0d return=%0d backend_drained=%0d FAIL",
               xret_arch_trap_capture_count, xret_capture_pc_match_count,
               xret_capture_tval_match_count, xret_request_oracle_hit_count,
               xret_illegal_csr_request_count, xret_commit_oracle_hit_count,
               xret_illegal_commit_count, saw_handler_fetch, gpr(5'd8),
               (gpr(5'd12) == (S_ENTRY_PC + 64'h04)),
               (gpr(5'd10) == 64'h0000_0000_1020_0073),
               (gpr(5'd6) == 64'h65), (gpr(5'd7) == 64'h75),
               (rob_count == 5'd0));
    end

    reset_dut(MODE_FENCE_ORDERING);
    run_until_exit(1000);
    tb_check1("fence ordering reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("fence ordering exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("fence ordering no fatal trap", trap_valid, 1'b0);
    tb_check1("store/fence dual-lane capture observed",
              saw_fence_lane1_capture, 1'b1);
    tb_check1("fence waits while memory system is not idle",
              saw_fence_drain_wait, 1'b1);
    tb_check1("fence control plane consumes core memory idle",
              saw_fence_busy_mem_idle_binding &&
              !fence_mem_idle_binding_mismatch, 1'b1);
    tb_check32("ordinary fence retires exactly once",
               fence_commit_count, 32'd1);
    tb_check32("older store probes exactly once",
               fence_store_probe_count, 32'd1);
    tb_check32("older store drains exactly once",
               fence_store_drain_count, 32'd1);
    tb_check32("younger device read issues exactly once",
               fence_device_read_count, 32'd1);
    tb_check1("fence cannot retire before older store drain",
              fence_retired_before_store_drain, 1'b0);
    tb_check1("younger device read cannot overtake store drain",
              device_read_before_store_drain, 1'b0);
    tb_check1("younger device read waits for fence retirement",
              device_read_before_fence_retire, 1'b0);
    tb_check64("younger device read returns expected data",
               gpr(5'd4), 64'h0000_0000_1234_5678);
    tb_check32("fence ordering backend drained after ebreak",
               {27'b0, rob_count}, 32'd0);
    // FENCE-G1 证据 marker：把完整定向程序的控制流、访存顺序与最终状态
    // 收敛为一条可由 evidence checker 精确解析的本地 RV64 仿真事实。
    if (exit_valid && exit_is_ebreak && !trap_valid &&
        saw_fence_lane1_capture && saw_fence_drain_wait &&
        saw_fence_busy_mem_idle_binding &&
        !fence_mem_idle_binding_mismatch &&
        (fence_commit_count == 32'd1) &&
        (fence_store_probe_count == 32'd1) &&
        (fence_store_drain_count == 32'd1) &&
        (fence_device_read_count == 32'd1) &&
        !fence_retired_before_store_drain &&
        !device_read_before_store_drain &&
        !device_read_before_fence_retire &&
        (gpr(5'd4) == 64'h0000_0000_1234_5678) &&
        (rob_count == 5'd0)) begin
      $display("[FENCE-G1-PROGRAM] exit=1 ebreak=1 trap=0 lane1_capture=1 full_memory_wait=1 mem_idle_binding=1 fence_commit=1 store_probe=1 store_drain=1 device_read=1 fence_before_store=0 device_before_store=0 device_before_fence=0 readback_match=1 backend_drained=1 PASS");
    end else begin
      $display("[FENCE-G1-PROGRAM] exit=%0d ebreak=%0d trap=%0d lane1_capture=%0d full_memory_wait=%0d mem_idle_binding=%0d fence_commit=%0d store_probe=%0d store_drain=%0d device_read=%0d fence_before_store=%0d device_before_store=%0d device_before_fence=%0d readback_match=%0d backend_drained=%0d FAIL",
               exit_valid, exit_is_ebreak, trap_valid,
               saw_fence_lane1_capture, saw_fence_drain_wait,
               (saw_fence_busy_mem_idle_binding &&
                !fence_mem_idle_binding_mismatch),
               fence_commit_count, fence_store_probe_count,
               fence_store_drain_count, fence_device_read_count,
               fence_retired_before_store_drain,
               device_read_before_store_drain,
               device_read_before_fence_retire,
               (gpr(5'd4) == 64'h0000_0000_1234_5678),
               (rob_count == 5'd0));
    end
    check_v10b_scoreboard(MODE_FENCE_ORDERING);
    tb_check32("V10B ordinary FENCE terminal count",
               v10b_terminal_count[V10B_KIND_FENCE], 32'd1);
    tb_check32("V10B ordinary FENCE MMU action count",
               v10b_mmu_flush_count, 32'd0);
    if ((v10b_terminal_count[V10B_KIND_FENCE] == 32'd1) &&
        (v10b_raw_request_match_count[V10B_KIND_FENCE] == 32'd1) &&
        (v10b_redirect_match_count[V10B_KIND_FENCE] == 32'd1) &&
        (v10b_ctrl_commit_count[V10B_KIND_FENCE] == 32'd1) &&
        (v10b_c1_clear_count[V10B_KIND_FENCE] == 32'd1) &&
        (v10b_c2_quiet_count[V10B_KIND_FENCE] == 32'd1) &&
        (v10b_mmu_flush_count == 32'd0)) begin
      $display("[V10B-FENCE-POST-FIRE] full-mem-idle=1 typed-serial=1 ctrl-commit=1 mmu=0 C1-owner-stop-clear=1 C2-repeat=0 PASS");
    end

    if (`OOO_CSR_QUEUE_HEAD) begin
      reset_dut(MODE_QH_SATP);
      run_until_exit(300);
      tb_check1("product head0 SATP reaches ebreak exit",
                exit_valid, 1'b1);
      tb_check1("product head0 SATP exits via ebreak",
                exit_is_ebreak, 1'b1);
      tb_check1("product head0 SATP has no fatal trap",
                trap_valid, 1'b0);
      tb_check1("product head0 SATP commit observed",
                saw_satp_commit, 1'b1);
      tb_check32("product head0 SATP birth count",
                 v10g_qh_satp_birth_count, 32'd1);
      tb_check32("product head0 SATP C0 commit count",
                 v10g_qh_satp_c0_commit_count, 32'd1);
      tb_check32("product head0 SATP C0 barrier count",
                 v10g_qh_satp_c0_barrier_count, 32'd1);
      tb_check32("product head0 SATP CsrFile request count",
                 v10g_qh_satp_csrfile_request_count, 32'd1);
      tb_check32("product head0 SATP C1 apply count",
                 v10g_qh_satp_c1_apply_count, 32'd1);
      tb_check1("product head0 SATP owner clear",
                v10g_qh_satp_owner_live_q, 1'b0);
      tb_check1("product head0 SATP C1 pending clear",
                v10g_qh_satp_expect_c1_q, 1'b0);
      tb_check1("product head0 SATP C2 completed",
                v10g_qh_satp_expect_c2_q, 1'b0);
      tb_check32("product head0 SATP has no pending-SYSTEM terminal",
                 v10b_terminal_count[V10B_KIND_CSR], 32'd0);
      tb_check32("product head0 SATP has no pending MMU source",
                 v10b_mmu_satp_source_count, 32'd0);
      tb_check32("product head0 SATP has no registered MMU pulse",
                 v10b_mmu_flush_count, 32'd0);
      tb_check32("product head0 SATP backend drained",
                 {27'b0, rob_count}, 32'd0);
      check_v10b_scoreboard(MODE_QH_SATP);
      if ((v10g_qh_satp_birth_count == 32'd1) &&
          (v10g_qh_satp_c0_commit_count == 32'd1) &&
          (v10g_qh_satp_c0_barrier_count == 32'd1) &&
          (v10g_qh_satp_csrfile_request_count == 32'd1) &&
          (v10g_qh_satp_c1_apply_count == 32'd1) &&
          !v10g_qh_satp_owner_live_q &&
          !v10g_qh_satp_expect_c1_q &&
          !v10g_qh_satp_expect_c2_q &&
          (v10b_terminal_count[V10B_KIND_CSR] == 32'd0) &&
          (v10b_mmu_satp_source_count == 32'd0) &&
          (v10b_mmu_flush_count == 32'd0) &&
          (rob_count == 5'd0)) begin
        $display("[V10G-PRODUCT-QH-SATP] birth=1 C0_commit=1 C0_barrier=1 CsrFile_request=1 C1_apply=1 C2_quiet=1 pending_terminal=0 pending_mmu=0 backend_drained=1 PASS");
      end
    end

    reset_dut(MODE_FDG_ARCH_TRAP);
    run_until_exit(1000);
    tb_check1("FDG program reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("FDG program exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("FDG program no terminal trap", trap_valid, 1'b0);
    tb_check1("FDG program enters m handler", saw_handler_fetch, 1'b1);
    tb_check1("FDG handler returns with mret", saw_mret_commit, 1'b1);
    tb_check32("FDG exact arch-trap capture count",
               fdg_arch_trap_capture_count, 32'd1);
    tb_check32("FDG capture PC exact-match count",
               fdg_capture_pc_match_count, 32'd1);
    tb_check32("FDG capture tval exact-match count",
               fdg_capture_tval_match_count, 32'd1);
    tb_check32("FDG ordinary backend present count",
               fdg_ordinary_backend_present_count, 32'd0);
    tb_check32("FDG core backend present count",
               fdg_core_backend_present_count, 32'd0);
    tb_check32("FDG illegal FP commit count",
               fdg_illegal_fp_commit_count, 32'd0);
    tb_check32("FDG commit oracle known-transaction hit count",
               fdg_commit_oracle_hit_count, 32'd1);
    tb_check64("FDG illegal FP mcause", gpr(5'd8),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ILLEGAL_INST});
    tb_check64("FDG illegal FP mepc", gpr(5'd12), BASE_PC + 64'h10);
    tb_check64("FDG illegal FP mtval", gpr(5'd10),
               {{(`XLEN-`INST_W){1'b0}}, FDG_ILLEGAL_FP_INST});
    tb_check64("FDG older integer operation retires", gpr(5'd6), 64'h41);
    tb_check64("FDG handler body executes", gpr(5'd11), 64'h4d);
    tb_check64("FDG returns after illegal FP", gpr(5'd7), 64'h47);
    tb_check32("FDG backend drained after ebreak", {27'b0, rob_count}, 32'd0);
    if (tb_errors == 0) begin
      $display("[FDG-G1-PROGRAM] arch_trap_capture=%0d capture_pc_match=%0d capture_tval_match=%0d ordinary_backend_present=%0d core_backend_present=%0d commit_oracle_hits=%0d illegal_fp_commit=%0d handler=%0d mret=%0d cause=%0d csr_mepc_match=%0d csr_mtval_match=%0d PASS",
               fdg_arch_trap_capture_count,
               fdg_capture_pc_match_count,
               fdg_capture_tval_match_count,
               fdg_ordinary_backend_present_count,
               fdg_core_backend_present_count,
               fdg_commit_oracle_hit_count,
               fdg_illegal_fp_commit_count,
               saw_handler_fetch,
               saw_mret_commit,
               gpr(5'd8),
               gpr(5'd12) == (BASE_PC + 64'h10),
               gpr(5'd10) == {{(`XLEN-`INST_W){1'b0}}, FDG_ILLEGAL_FP_INST});
    end

    tb_finish("tb_ooo_priv_system");
  end

  wire unused_observe_w =
      mem_req_write | (|mem_req_addr) | (|mem_req_wdata) |
      mem_req_probe | mem_req_pretrans | mem_req_nokill |
      (|mem_req_wstrb) |
      commit0_rd_en | (|commit0_rd_addr) | (|commit0_rd_data) |
      commit0_exception | commit0_write | (|commit0_next_pc) |
      commit1_rd_en | (|commit1_rd_addr) | (|commit1_rd_data) |
      commit1_exception | commit1_write | (|commit1_next_pc) |
      mmu_flush | halted | (|debug_pc) | (|debug_state) | (|retire_count) |
      (|free_count) | (|issue_count) | (|trap_cause) |
      (|trap_pc) | (|trap_tval) | (|exit_code);

endmodule
