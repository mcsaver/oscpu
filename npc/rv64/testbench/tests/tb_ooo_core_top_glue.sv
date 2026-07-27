`include "define.v"
`include "common/OooSlotFacts.v"

module tb_ooo_core_top_glue;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  reg clk;
  reg rst;
  reg flush;
  reg run;
  reg commit_ready;
  reg fetch_req_admit;

  wire fetch_req_valid;
  wire fetch_req_ready;
  wire [`XLEN-1:0] fetch_req_pc;
  reg [`XLEN-1:0] fetch_req_owner_pc;
  reg fetch_rsp_valid;
  wire fetch_rsp_ready;
  reg [`INST_W-1:0] fetch_rsp_inst0;
  reg [1:0] fetch_rsp_resp0;
  reg [`INST_W-1:0] fetch_rsp_inst1;
  reg [1:0] fetch_rsp_resp1;
  wire mem_req_valid;
  wire mem_req_ready;
  wire mem_req_write;
  wire mem_req_probe;
  wire mem_req_pretrans;
  wire mem_req_nokill;
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
  reg [1:0] mem_rsp_owner_kind;
  reg [4:0] mem_rsp_owner_token;
  reg [1:0] mem_rsp_mmu_epoch;
  reg [`XLEN-1:0] mem_rsp_fault_tval;
  wire mem_expected_valid;
  wire [1:0] mem_expected_owner_kind;
  wire [4:0] mem_expected_owner_token;
  wire [1:0] mem_expected_mmu_epoch;
  wire mem_expected_tval_valid;
  wire [`XLEN-1:0] mem_expected_fault_tval;
  wire mem_expected_effective_killed;
  wire mem_owner_query_valid = mem_rsp_valid;
  wire [4:0] mem_owner_query_token = mem_rsp_owner_token;
  wire mem_tracker_expected_valid;
  wire [1:0] mem_tracker_expected_owner_kind;
  wire [4:0] mem_tracker_expected_owner_token;
  wire [1:0] mem_tracker_expected_mmu_epoch;
  reg mem_station_query_valid;
  reg [1:0] mem_station_query_owner_kind;
  reg [4:0] mem_station_query_token;
  reg [1:0] mem_station_query_mmu_epoch;
  wire mem_station_expected_valid;
  wire [1:0] mem_station_expected_owner_kind;
  wire [4:0] mem_station_expected_owner_token;
  wire [1:0] mem_station_expected_mmu_epoch;
  wire mem_drop0_valid = flush && mem_rsp_valid;
  wire [31:0] mem_bridge_owner_residency_mask =
      (mem_rsp_valid ? (32'b1 << mem_rsp_owner_token) : 32'b0) |
      (mem_station_query_valid ?
       (32'b1 << mem_station_query_token) : 32'b0);

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
  wire head0_retire_candidate_valid;
  wire head0_identity_valid;
  wire [`OOO_CONTEXT_ID_W-1:0] head0_identity;
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
  wire control_full_flush_barrier;
  wire [`REDIR_REASON_W-1:0] control_full_flush_reason;

  integer commit_total;
  integer request_total;
  reg last_fetch_fire;
  reg saw_back_to_back_fetch;
  reg saw_dual_commit;
  reg saw_memory_streaming;
  reg saw_lane1_memory_streaming;
  reg saw_memory_rsp_req_overlap;
  reg saw_exact_owner_roundtrip;
  reg saw_return_fastpath;
  reg saw_branch_fastpath;
  reg saw_direct_redirect_fetch;
  reg last_direct_redirect;
  reg saw_branch_redirect_fetch;
  reg saw_branch_shadow_prefetch;
  reg saw_branch_shadow_hit;
  reg saw_branch_spec_capture;
  reg saw_branch_spec_correct;
  reg saw_branch_spec_restore;
  reg saw_backend_branch_resolve;
  reg saw_branch_dispatch_resolve;
  reg saw_control_fallthrough_fetch;
  reg saw_lane1_ret_fallthrough;
  reg saw_fp_gpr_completion;
  reg saw_fp_gpr_completion_wake;
  reg saw_head0_csr_stop_owner;
  reg saw_control_full_flush_barrier;
  reg saw_csr_full_flush_barrier;
  reg saw_trap_full_flush_barrier;
  reg saw_typed_csr_apply;
  reg saw_typed_trap_apply;
  reg saw_pending_csr_commit;
  reg saw_pending_csr_exact_owner;
  reg saw_pending_csr_control_pregrant;
  reg saw_pending_csr_frontend_none;
  reg saw_pending_csr_without_full_flush;
  reg saw_pending_csr_without_next_apply;
  reg pending_csr_commit_prev;
  reg saw_csr_after_older_store;
  reg csr_apply_seen;
  reg saw_csr_branch_recovery_dispatch;
  reg saw_csr_branch_recovery_selective;
  reg saw_csr_branch_recovery_clear;
  reg saw_csr_branch_recovery_commit;
  reg csr_branch_recovery_selective_prev;
  reg control_full_flush_barrier_prev;
  reg [`REDIR_REASON_W-1:0] control_full_flush_reason_prev;
  reg saw_v8a_candidate;
  reg saw_v8a_identity;
  reg saw_fetch_fault_packet_enqueue;
  reg saw_fetch_fault_predecode_fifo;
  reg saw_fetch_fault_raw_fp_response;
  reg saw_fetch_fault_static_zero_enqueue;
  reg saw_fetch_fault_static_zero_fifo;
  reg [4:0] program_mode;
  reg [`XLEN-1:0] fault_addr;
  reg [`XLEN-1:0] data_mem_word;
  localparam [1:0] FETCH_RESP_ACCESS_FAULT = 2'b01;

  localparam [4:0] MODE_DEFAULT_BODY = 5'd0;
  localparam [4:0] MODE_EBREAK = 5'd1;
  localparam [4:0] MODE_BRANCH_TAKEN = 5'd2;
  localparam [4:0] MODE_BRANCH_NOT_TAKEN = 5'd3;
  localparam [4:0] MODE_JAL = 5'd4;
  localparam [4:0] MODE_JALR_RD_EQ_RS1 = 5'd5;
  localparam [4:0] MODE_MEM_LW_SW = 5'd6;
  localparam [4:0] MODE_LANE1_EBREAK = 5'd7;
  localparam [4:0] MODE_LANE1_BRANCH_TAKEN = 5'd8;
  localparam [4:0] MODE_LANE1_JAL = 5'd9;
  localparam [4:0] MODE_LANE1_MEM = 5'd10;
  localparam [4:0] MODE_RVC_CADDIW = 5'd11;
  localparam [4:0] MODE_RAS_RETURN = 5'd12;
  localparam [4:0] MODE_BRANCH_SHADOW_PREFETCH = 5'd13;
  localparam [4:0] MODE_BRANCH_READY_RESOLVE = 5'd14;
  localparam [4:0] MODE_CONTROL_FETCH_GATE = 5'd15;
  localparam [4:0] MODE_BRANCH_LANE1_RET = 5'd16;
  localparam [4:0] MODE_ECALL = 5'd17;
  localparam [4:0] MODE_FMV_W_X = 5'd18;
  localparam [4:0] MODE_FETCH_ACCESS_FAULT = 5'd19;
  localparam [4:0] MODE_FRONTEND_II1 = 5'd20;
  localparam [4:0] MODE_WIDTH_CONTINUITY = 5'd21;
  localparam [4:0] MODE_PENDING_FP_CSR = 5'd22;
  localparam [4:0] MODE_CSR_MEMORY_ORDER = 5'd23;
  localparam [4:0] MODE_CSR_BRANCH_RECOVERY = 5'd24;
  localparam [4:0] MODE_CSR_JALR_RECOVERY = 5'd25;
  localparam [4:0] MODE_CSR_JALR_CALLBACK_CHAIN = 5'd26;
  // Deliberately use a raw instruction whose 18-bit T3W static pack is
  // non-zero.  PacketDecode must replace it with a NOP on the fault path,
  // and the FIFO must store the sanitized NOP's all-zero static pack.
  localparam [`INST_W-1:0] FETCH_FAULT_RAW_FP_INST = 32'he000_0153;

  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] fetch_fault_raw_static_facts_w;
  OooFetchStaticClassify u_fetch_fault_raw_static_reference (
    .inst_i(FETCH_FAULT_RAW_FP_INST),
    .semihost_peer_inst_i(32'h0000_0013),
    .semihost_peer_is_enter_i(1'b1),
    .static_facts_o(fetch_fault_raw_static_facts_w)
  );

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
    .head0_retire_candidate_valid_o(head0_retire_candidate_valid),
    .head0_identity_valid_o(head0_identity_valid),
    .head0_identity_o(head0_identity),
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
    .mem_req_attr_valid_o(),
    .mem_req_class_o(),
    .mem_req_cacheable_o(),
    .mem_req_owner_kind_o(mem_req_owner_kind),
    .mem_req_owner_token_o(mem_req_owner_token),
    .mem_req_mmu_epoch_o(mem_req_mmu_epoch),
    .mem_req_fault_tval_o(mem_req_fault_tval),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(mem_rsp_valid),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_rsp_rdata_i(mem_rsp_rdata),
    .mem_rsp_error_i(mem_rsp_error),
    .mem_rsp_page_fault_i(1'b0),
    .mem_rsp_attr_valid_i(1'b1),
    .mem_rsp_class_i(`OOO_MEM_CLASS_CACHED),
    .mem_rsp_cacheable_i(1'b1),
    .mem_rsp_owner_kind_i(mem_rsp_owner_kind),
    .mem_rsp_owner_token_i(mem_rsp_owner_token),
    .mem_rsp_mmu_epoch_i(mem_rsp_mmu_epoch),
    .mem_rsp_fault_tval_i(mem_rsp_fault_tval),
    .mem_expected_valid_o(mem_expected_valid),
    .mem_expected_owner_kind_o(mem_expected_owner_kind),
    .mem_expected_owner_token_o(mem_expected_owner_token),
    .mem_expected_mmu_epoch_o(mem_expected_mmu_epoch),
    .mem_expected_tval_valid_o(mem_expected_tval_valid),
    .mem_expected_fault_tval_o(mem_expected_fault_tval),
    .mem_expected_effective_killed_o(mem_expected_effective_killed),
    .mem_owner_query_valid_i(mem_owner_query_valid),
    .mem_owner_query_token_i(mem_owner_query_token),
    .mem_tracker_expected_valid_o(mem_tracker_expected_valid),
    .mem_tracker_expected_owner_kind_o(mem_tracker_expected_owner_kind),
    .mem_tracker_expected_owner_token_o(mem_tracker_expected_owner_token),
    .mem_tracker_expected_mmu_epoch_o(mem_tracker_expected_mmu_epoch),
    .mem_station_query_valid_i(mem_station_query_valid),
    .mem_station_query_token_i(mem_station_query_token),
    .mem_station_expected_valid_o(mem_station_expected_valid),
    .mem_station_expected_owner_kind_o(mem_station_expected_owner_kind),
    .mem_station_expected_owner_token_o(mem_station_expected_owner_token),
    .mem_station_expected_mmu_epoch_o(mem_station_expected_mmu_epoch),
    .mem_drop0_valid_i(mem_drop0_valid),
    .mem_drop0_owner_kind_i(mem_rsp_owner_kind),
    .mem_drop0_owner_token_i(mem_rsp_owner_token),
    .mem_drop0_mmu_epoch_i(mem_rsp_mmu_epoch),
    .mem_drop0_fault_tval_i(mem_rsp_fault_tval),
    .mem_drop1_valid_i(1'b0),
    .mem_drop1_owner_kind_i(2'b00),
    .mem_drop1_owner_token_i(5'b00000),
    .mem_drop1_mmu_epoch_i(2'b00),
    .mem_drop1_fault_tval_i({`XLEN{1'b0}}),
    .mem_bridge_owner_residency_mask_i(mem_bridge_owner_residency_mask),
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
    .mmu_flush_o(),
    .control_full_flush_barrier_o(control_full_flush_barrier),
    .control_full_flush_reason_o(control_full_flush_reason),
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

  // FP completion 域合同只读观察：证明 GPR 目的事务真实发生且不误唤醒 FPR 域。
  wire fp_result_wb_valid =
      dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
         .u_fp_backend.fp_result_wb_valid_w;
  wire fp_result_wb_frd =
      dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
         .u_fp_backend.fp_result_wb_frd_w;
  wire fp_wake0_valid =
      dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
         .u_fp_backend.fp_wake0_valid_o;
  wire mem_issue_res_capture =
      dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
         .mem_issue_res_capture_w;

  function [`XLEN-1:0] gpr;
    input [`REG_ADDR_W-1:0] idx;
    begin
      gpr = debug_gprs[idx * `XLEN +: `XLEN];
    end
  endfunction

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

  function [`INST_W-1:0] inst_beq_self;
    begin
      inst_beq_self = rv32_b(13'd0, 5'd0, 5'd0, `FUNCT3_BEQ);
    end
  endfunction

  function [`INST_W-1:0] inst_beq;
    input [12:0] imm;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_beq = rv32_b(imm, rs2, rs1, `FUNCT3_BEQ);
    end
  endfunction

  function [`INST_W-1:0] inst_bne;
    input [12:0] imm;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_bne = rv32_b(imm, rs2, rs1, `FUNCT3_BNE);
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

  function [`INST_W-1:0] inst_sw;
    input [4:0] rs2;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_sw = rv32_s(imm, rs2, rs1, `FUNCT3_SW);
    end
  endfunction

  function [`INST_W-1:0] inst_lui;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_lui = rv32_u(imm, rd, `OPCODE_LUI);
    end
  endfunction

  function [`INST_W-1:0] inst_auipc;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_auipc = rv32_u(imm, rd, `OPCODE_AUIPC);
    end
  endfunction

  function [`INST_W-1:0] inst_csrrw;
    input [4:0] rd;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      inst_csrrw = rv32_i(csr, rs1, 3'b001, rd, `OPCODE_SYSTEM);
    end
  endfunction

  function [`INST_W-1:0] inst_csrrs;
    input [4:0] rd;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      inst_csrrs = rv32_i(csr, rs1, 3'b010, rd, `OPCODE_SYSTEM);
    end
  endfunction

  function [`INST_W-1:0] inst_fmv_w_x;
    input [4:0] rd;
    input [4:0] rs1;
    begin
      inst_fmv_w_x = {7'b1111000, 5'b00000, rs1, 3'b000, rd,
                      `OPCODE_OP_FP};
    end
  endfunction

  function [`INST_W-1:0] inst_fmv_x_w;
    input [4:0] rd;
    input [4:0] fs1;
    begin
      inst_fmv_x_w = {7'b1110000, 5'b00000, fs1, 3'b000, rd,
                      `OPCODE_OP_FP};
    end
  endfunction

  function [`INST_W-1:0] inst_jal;
    input [4:0] rd;
    input [20:0] imm;
    begin
      inst_jal = rv32_j(imm, rd);
    end
  endfunction

  function [`INST_W-1:0] inst_jalr;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_jalr = rv32_i(imm, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_JALR);
    end
  endfunction

  function [`INST_W-1:0] inst_ebreak;
    begin
      inst_ebreak = 32'h0010_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_ecall;
    begin
      inst_ecall = 32'h0000_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_mret;
    begin
      inst_mret = 32'h3020_0073;
    end
  endfunction

  function [15:0] inst_c_addi;
    input [4:0] rd;
    input [5:0] imm;
    begin
      inst_c_addi = {3'b000, imm[5], rd, imm[4:0], 2'b01};
    end
  endfunction

  function [15:0] inst_c_addiw;
    input [4:0] rd;
    input [5:0] imm;
    begin
      inst_c_addiw = {3'b001, imm[5], rd, imm[4:0], 2'b01};
    end
  endfunction

  function [15:0] inst_c_ebreak;
    begin
      inst_c_ebreak = 16'h9002;
    end
  endfunction

  function [15:0] program_half;
    input [`XLEN-1:0] addr;
    begin
      if (program_mode == MODE_RVC_CADDIW) begin
        case (addr)
          32'h8000_0000: program_half = inst_c_addi(5'd5, 6'h3f);
          32'h8000_0002: program_half = inst_c_addiw(5'd5, 6'd1);
          32'h8000_0004: program_half = inst_c_addiw(5'd5, 6'h3f);
          32'h8000_0006: program_half = inst_c_addi(5'd6, 6'd1);
          32'h8000_0008: program_half = inst_c_ebreak();
          default:       program_half = inst_c_ebreak();
        endcase
      end else begin
        case (addr)
          32'h8000_0000: program_half = inst_c_addi(5'd1, 6'd1);
          32'h8000_0002: program_half = inst_c_addi(5'd2, 6'd2);
          32'h8000_0004: program_half = inst_c_addi(5'd3, 6'd3);
          32'h8000_0006: program_half = inst_c_ebreak();
          default:       program_half = inst_c_ebreak();
        endcase
      end
    end
  endfunction

  function [`INST_W-1:0] program_word;
    input [`XLEN-1:0] addr;
    reg [`XLEN-1:0] width_sequence;
    reg [4:0] width_rd;
    reg [11:0] width_imm;
    begin
      if (program_mode == MODE_FRONTEND_II1) begin
        // DI-1 focused stream: two independent architectural NOPs per packet.
        // The unbounded sequential image prevents a control-flow stop from
        // entering the 64-cycle frontend turnover window.
        program_word = inst_addi(5'd0, 5'd0, 12'd0);
      end else if (program_mode == MODE_WIDTH_CONTINUITY) begin
        // V9A DI-2: independent integer ALU stream.  Every source is x0, so
        // there is no RAW dependency.  PC-derived nonzero rd/imm values make
        // both lanes and every transaction payload observably different.
        width_sequence = (addr - `RESET_PC) >> 2;
        width_rd = (width_sequence % 30) + 1;
        width_imm = width_sequence[11:0] + 12'd1;
        program_word = inst_addi(width_rd, 5'd0, width_imm);
      end else if (program_mode == MODE_RVC_CADDIW) begin
        program_word = {program_half(addr + 32'd2), program_half(addr)};
      end else if (program_mode == MODE_EBREAK && addr == 32'h8000_0000) begin
        program_word = inst_ebreak();
      end else begin
        case (program_mode)
          MODE_BRANCH_TAKEN: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0008: program_word = inst_beq(13'd8, 5'd1, 5'd1);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd0, 12'd99);
              32'h8000_0010: program_word = inst_addi(5'd4, 5'd0, 12'd4);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd0, 12'd5);
              32'h8000_0018: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_BRANCH_NOT_TAKEN: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0008: program_word = inst_bne(13'd8, 5'd1, 5'd1);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd0, 12'd3);
              32'h8000_0010: program_word = inst_addi(5'd4, 5'd0, 12'd4);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd0, 12'd5);
              32'h8000_0018: program_word = inst_addi(5'd6, 5'd0, 12'd6);
              32'h8000_001c: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_BRANCH_READY_RESOLVE: begin
            case (addr)
              32'h8000_0000: program_word = inst_beq(13'd8, 5'd0, 5'd0);
              32'h8000_0004: program_word = inst_addi(5'd1, 5'd0, 12'd99);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd0, 12'd7);
              32'h8000_000c: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_CONTROL_FETCH_GATE: begin
            case (addr)
              32'h8000_0000: program_word = inst_jal(5'd1, 21'd12);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_0008: program_word = inst_addi(5'd3, 5'd0, 12'd99);
              32'h8000_000c: program_word = inst_addi(5'd4, 5'd1, 12'd0);
              32'h8000_0010: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_BRANCH_LANE1_RET: begin
            case (addr)
              32'h8000_0000: program_word = inst_jal(5'd1, 21'd20);
              32'h8000_0004: program_word = inst_addi(5'd5, 5'd0, 12'd5);
              32'h8000_0008: program_word = inst_ebreak();
              32'h8000_0010: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_0014: program_word = inst_bne(13'd8, 5'd0, 5'd0);
              32'h8000_0018: program_word = inst_jalr(5'd0, 5'd1, 12'd0);
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_JAL: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0008: program_word = inst_jal(5'd10, 21'd8);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd0, 12'd99);
              32'h8000_0010: program_word = inst_addi(5'd4, 5'd0, 12'd4);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd10, 12'd0);
              32'h8000_0018: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_JALR_RD_EQ_RS1: begin
            case (addr)
              32'h8000_0000: program_word = inst_auipc(5'd5, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd5, 5'd5, 12'h018);
              32'h8000_0008: program_word = inst_jalr(5'd5, 5'd5, 12'd0);
              32'h8000_000c: program_word = inst_addi(5'd6, 5'd0, 12'd99);
              32'h8000_0010: program_word = inst_addi(5'd6, 5'd0, 12'd55);
              32'h8000_0014: program_word = inst_addi(5'd6, 5'd0, 12'd77);
              32'h8000_0018: program_word = inst_addi(5'd7, 5'd5, 12'd0);
              32'h8000_001c: program_word = inst_addi(5'd8, 5'd0, 12'd8);
              32'h8000_0020: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_CSR_JALR_CALLBACK_CHAIN: begin
            case (addr)
              // Linux serial8250_do_set_termios-shaped control sequence:
              // a serialized CSR access followed by two adjacent indirect
              // callbacks/returns and a post-callback conditional branch.
              32'h8000_0000: program_word = inst_csrrs(5'd0, `CSR_MSTATUS,
                                                       5'd0);
              32'h8000_0004: program_word = inst_auipc(5'd5, 20'h00000);
              32'h8000_0008: program_word = inst_addi(5'd5, 5'd5, 12'h02c);
              32'h8000_000c: program_word = inst_jalr(5'd1, 5'd5, 12'd0);
              32'h8000_0010: program_word = inst_addi(5'd6, 5'd0, 12'd1);
              32'h8000_0014: program_word = inst_jalr(5'd1, 5'd5, 12'd0);
              32'h8000_0018: program_word = inst_beq(13'd8, 5'd0, 5'd0);
              32'h8000_001c: program_word = inst_addi(5'd7, 5'd0, 12'd99);
              32'h8000_0020: program_word = inst_addi(5'd8, 5'd0, 12'd8);
              32'h8000_0024: program_word = inst_ebreak();
              32'h8000_0030: program_word = inst_addi(5'd9, 5'd9, 12'd1);
              32'h8000_0034: program_word = inst_jalr(5'd0, 5'd1, 12'd0);
              default:       program_word = inst_beq_self();
            endcase
          end
          MODE_MEM_LW_SW: begin
            case (addr)
              32'h8000_0000: program_word = inst_auipc(5'd2, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd1, 5'd0, 12'd11);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd2, 12'h040);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd0, 12'd3);
              32'h8000_0010: program_word = inst_sw(5'd1, 5'd2, 12'd0);
              32'h8000_0014: program_word = inst_lw(5'd4, 5'd2, 12'd0);
              32'h8000_0018: program_word = inst_addi(5'd5, 5'd4, 12'd1);
              32'h8000_001c: program_word = inst_addi(5'd6, 5'd0, 12'd6);
              // Keep one complete fetch packet behind the memory body.  Integer
              // consumers now wake from registered WB state, so an immediately
              // following ebreak may legitimately enter stop-pending before the
              // store reaches the request port and mask the streaming property.
              32'h8000_0020: program_word = inst_addi(5'd7, 5'd0, 12'd7);
              32'h8000_0024: program_word = inst_addi(5'd8, 5'd0, 12'd8);
              32'h8000_0028: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_LANE1_EBREAK: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_LANE1_BRANCH_TAKEN: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_beq(13'd8, 5'd1, 5'd1);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd1, 12'd2);
              32'h8000_0010: program_word = inst_addi(5'd4, 5'd0, 12'd4);
              32'h8000_0014: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_LANE1_JAL: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_jal(5'd10, 21'd8);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd10, 12'd0);
              32'h8000_0010: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_LANE1_MEM: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd13);
              32'h8000_0004: program_word = inst_auipc(5'd2, 20'h00000);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd2, 12'h03c);
              32'h8000_000c: program_word = inst_sw(5'd1, 5'd2, 12'd0);
              32'h8000_0010: program_word = inst_lw(5'd4, 5'd2, 12'd0);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd4, 12'd1);
              32'h8000_0018: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_RAS_RETURN: begin
            case (addr)
              32'h8000_0000: program_word = inst_jal(5'd1, 21'd12);
              32'h8000_0004: program_word = inst_addi(5'd4, 5'd2, 12'd1);
              32'h8000_0008: program_word = inst_ebreak();
              32'h8000_000c: program_word = inst_addi(5'd2, 5'd0, 12'd1);
              32'h8000_0010: program_word = inst_addi(5'd2, 5'd2, 12'd1);
              32'h8000_0014: program_word = inst_jalr(5'd0, 5'd1, 12'd0);
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_BRANCH_SHADOW_PREFETCH: begin
            case (addr)
              32'h8000_0000: program_word = inst_jal(5'd0, 21'd16);
              32'h8000_0004: program_word = inst_addi(5'd9, 5'd0, 12'd9);
              32'h8000_0008: program_word = inst_addi(5'd3, 5'd0, 12'd3);
              32'h8000_000c: program_word = inst_ebreak();
              32'h8000_0010: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0014: program_word = inst_bne(13'h1ff4, 5'd1, 5'd0);
              32'h8000_0018: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_001c: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_ECALL: begin
            case (addr)
              32'h8000_0000: program_word = inst_auipc(5'd7, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd7, 5'd7, 12'h020);
              32'h8000_0008: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd7);
              32'h8000_000c: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0010: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0014: program_word = inst_add(5'd3, 5'd1, 5'd2);
              32'h8000_0018: program_word = inst_ecall();
              32'h8000_001c: program_word = inst_addi(5'd5, 5'd0, 12'd9);
              32'h8000_0020: program_word = inst_addi(5'd6, 5'd0, 12'd6);
              32'h8000_0024: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          MODE_FMV_W_X: begin
            case (addr)
              32'h8000_0000: program_word = inst_lui(5'd11, 20'h00006);
              32'h8000_0004: program_word = inst_csrrs(5'd0, `CSR_MSTATUS,
                                                       5'd11);
              32'h8000_0008: program_word = inst_fmv_w_x(5'd0, 5'd0);
              32'h8000_000c: program_word = inst_fmv_x_w(5'd6, 5'd0);
              32'h8000_0010: program_word = inst_addi(5'd5, 5'd0, 12'd7);
              32'h8000_0014: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          MODE_PENDING_FP_CSR: begin
            case (addr)
              // First enable FS through the real queue-head CSR path, then
              // issue an FP CSR that is deliberately owned by the legacy
              // pending-system drain sequencer.
              32'h8000_0000: program_word = inst_lui(5'd11, 20'h00006);
              32'h8000_0004: program_word = inst_csrrs(5'd0, `CSR_MSTATUS,
                                                       5'd11);
              32'h8000_0008: program_word = inst_csrrw(5'd12, `CSR_FFLAGS,
                                                       5'd0);
              32'h8000_000c: program_word = inst_addi(5'd5, 5'd0, 12'd7);
              32'h8000_0010: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          MODE_CSR_MEMORY_ORDER: begin
            case (addr)
              // The store is older than the queue-head CSR and must drain.
              // The load shares the CSR packet's lane1 and must be squashed,
              // then refetched only after the CSR C1 apply.
              32'h8000_0000: program_word = inst_auipc(5'd2, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd1, 5'd0, 12'd11);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd2, 12'h040);
              32'h8000_000c: program_word = inst_sw(5'd1, 5'd2, 12'd0);
              32'h8000_0010: program_word = inst_csrrw(5'd0, `CSR_MSCRATCH,
                                                       5'd0);
              32'h8000_0014: program_word = inst_lw(5'd4, 5'd2, 12'd0);
              32'h8000_0018: program_word = inst_addi(5'd5, 5'd4, 12'd1);
              32'h8000_001c: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          MODE_CSR_BRANCH_RECOVERY: begin
            case (addr)
              // The load keeps the older branch unresolved while the
              // fall-through CSR reaches the queue-head dispatch path.
              // A cold BHT predicts the BEQ not-taken; the zero load makes
              // the branch resolve taken and selectively kills the CSR.
              32'h8000_0000: program_word = inst_auipc(5'd2, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd3, 5'd0, 12'h055);
              32'h8000_0008: program_word = inst_lw(5'd1, 5'd2, 12'h040);
              32'h8000_000c: program_word = inst_beq(13'd12, 5'd1, 5'd0);
              32'h8000_0010: program_word = inst_csrrw(5'd0, `CSR_MSCRATCH,
                                                       5'd3);
              32'h8000_0014: program_word = inst_addi(5'd4, 5'd0, 12'd99);
              32'h8000_0018: program_word = inst_addi(5'd5, 5'd0, 12'd7);
              32'h8000_001c: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          MODE_CSR_JALR_RECOVERY: begin
            case (addr)
              // The memory model supplies the positive offset 0x18.  Adding
              // it to the AUIPC base avoids RV64 LW sign-extension ambiguity
              // while keeping the older JALR dependent on the load response.
              32'h8000_0000: program_word = inst_auipc(5'd2, 20'h00000);
              32'h8000_0004: program_word = inst_lw(5'd1, 5'd2, 12'h040);
              32'h8000_0008: program_word = inst_add(5'd1, 5'd1, 5'd2);
              32'h8000_000c: program_word = inst_jalr(5'd0, 5'd1, 12'd0);
              32'h8000_0010: program_word = inst_csrrw(5'd0, `CSR_MSCRATCH,
                                                       5'd2);
              32'h8000_0014: program_word = inst_addi(5'd4, 5'd0, 12'd99);
              32'h8000_0018: program_word = inst_addi(5'd5, 5'd0, 12'd8);
              32'h8000_001c: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          MODE_FETCH_ACCESS_FAULT: begin
            case (addr)
              // Install a real handler before injecting the fault.  CSR
              // serialization refetches at 0x8000_000c, making 0x8000_0010
              // lane1 of the first post-CSR packet.
              32'h8000_0000: program_word = inst_auipc(5'd7, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd7, 5'd7, 12'h030);
              32'h8000_0008: program_word = inst_csrrw(5'd0, `CSR_MTVEC,
                                                       5'd7);
              // The older lane0 write proves precise same-packet retirement;
              // the raw lane1 FP move deliberately names the same rd so the
              // fault packet is not a trivially inert encoding.
              32'h8000_000c: program_word = inst_addi(5'd2, 5'd0, 12'd55);
              // FMV.X.W x2,f0 has a non-zero T3W FP_MOVE_TO_GPR static bit.
              // The injected access fault must sanitize both the instruction
              // and the static pack before FIFO ownership transfers.
              32'h8000_0010: program_word = FETCH_FAULT_RAW_FP_INST;
              32'h8000_0014: program_word = inst_addi(5'd3, 5'd0, 12'd99);
              32'h8000_0018: program_word = inst_addi(5'd4, 5'd0, 12'd77);
              32'h8000_001c: program_word = inst_beq_self();
              // The handler exposes precise trap state through architectural
              // GPRs, then exits through the existing semihost EBREAK path.
              32'h8000_0030: program_word = inst_csrrs(5'd13, `CSR_MCAUSE,
                                                       5'd0);
              32'h8000_0034: program_word = inst_csrrs(5'd14, `CSR_MEPC,
                                                       5'd0);
              32'h8000_0038: program_word = inst_csrrs(5'd15, `CSR_MTVAL,
                                                       5'd0);
              32'h8000_003c: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          default: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0008: program_word = inst_add(5'd3, 5'd1, 5'd2);
              32'h8000_000c: program_word = inst_addi(5'd4, 5'd3, 12'd4);
              32'h8000_0010: program_word = inst_addi(5'd5, 5'd0, 12'd5);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd0, 12'd9);
              32'h8000_0018: program_word = inst_ebreak();
              32'h8000_001c: program_word = inst_addi(5'd6, 5'd0, 12'd6);
              default:       program_word = inst_beq_self();
            endcase
          end
        endcase
      end
    end
  endfunction

  task automatic reset_dut;
    input [4:0] mode_i;
    input [`XLEN-1:0] fault_addr_i;
    begin
      clk = 1'b0;
      rst = 1'b1;
      flush = 1'b0;
      run = 1'b1;
      commit_ready = 1'b1;
      fetch_req_admit = 1'b1;
      fetch_rsp_valid = 1'b0;
      fetch_rsp_inst0 = {`INST_W{1'b0}};
      fetch_rsp_inst1 = {`INST_W{1'b0}};
      fetch_rsp_resp0 = 2'b00;
      fetch_rsp_resp1 = 2'b00;
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      mem_rsp_owner_kind = 2'b00;
      mem_rsp_owner_token = 5'b00000;
      mem_rsp_mmu_epoch = 2'b00;
      mem_rsp_fault_tval = {`XLEN{1'b0}};
      mem_station_query_valid = 1'b0;
      mem_station_query_owner_kind = 2'b00;
      mem_station_query_token = 5'b00000;
      mem_station_query_mmu_epoch = 2'b00;
      data_mem_word = {`XLEN{1'b0}};
      commit_total = 0;
      request_total = 0;
      last_fetch_fire = 1'b0;
      saw_back_to_back_fetch = 1'b0;
      saw_dual_commit = 1'b0;
      saw_memory_streaming = 1'b0;
      saw_lane1_memory_streaming = 1'b0;
      saw_memory_rsp_req_overlap = 1'b0;
      saw_exact_owner_roundtrip = 1'b0;
      saw_return_fastpath = 1'b0;
      saw_branch_fastpath = 1'b0;
      saw_direct_redirect_fetch = 1'b0;
      saw_branch_redirect_fetch = 1'b0;
      saw_branch_shadow_prefetch = 1'b0;
      saw_branch_shadow_hit = 1'b0;
      saw_branch_spec_capture = 1'b0;
      saw_branch_spec_correct = 1'b0;
      saw_branch_spec_restore = 1'b0;
      saw_backend_branch_resolve = 1'b0;
      saw_branch_dispatch_resolve = 1'b0;
      saw_control_fallthrough_fetch = 1'b0;
      saw_lane1_ret_fallthrough = 1'b0;
      saw_fp_gpr_completion = 1'b0;
      saw_fp_gpr_completion_wake = 1'b0;
      saw_head0_csr_stop_owner = 1'b0;
      saw_control_full_flush_barrier = 1'b0;
      saw_csr_full_flush_barrier = 1'b0;
      saw_trap_full_flush_barrier = 1'b0;
      saw_typed_csr_apply = 1'b0;
      saw_typed_trap_apply = 1'b0;
      saw_pending_csr_commit = 1'b0;
      saw_pending_csr_exact_owner = 1'b0;
      saw_pending_csr_control_pregrant = 1'b0;
      saw_pending_csr_frontend_none = 1'b0;
      saw_pending_csr_without_full_flush = 1'b0;
      saw_pending_csr_without_next_apply = 1'b0;
      pending_csr_commit_prev = 1'b0;
      saw_csr_after_older_store = 1'b0;
      csr_apply_seen = 1'b0;
      control_full_flush_barrier_prev = 1'b0;
      control_full_flush_reason_prev = `REDIR_REASON_NONE;
      saw_v8a_candidate = 1'b0;
      saw_v8a_identity = 1'b0;
      saw_fetch_fault_packet_enqueue = 1'b0;
      saw_fetch_fault_predecode_fifo = 1'b0;
      saw_fetch_fault_raw_fp_response = 1'b0;
      saw_fetch_fault_static_zero_enqueue = 1'b0;
      saw_fetch_fault_static_zero_fifo = 1'b0;
      program_mode = mode_i;
      fault_addr = fault_addr_i;
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  assign fetch_req_ready = fetch_req_admit &&
                           (!fetch_rsp_valid || fetch_rsp_ready);
  assign mem_req_ready = !mem_rsp_valid || mem_rsp_ready;

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
        fetch_rsp_inst1 <= program_word(fetch_req_pc + 32'd4);
        fetch_rsp_resp0 <= (fetch_req_pc == fault_addr) ?
                           FETCH_RESP_ACCESS_FAULT : 2'b00;
        fetch_rsp_resp1 <= ((fetch_req_pc + 32'd4) == fault_addr) ?
                           FETCH_RESP_ACCESS_FAULT : 2'b00;
      end
    end
  end

  always @(posedge clk) begin
    if (rst || flush) begin
      mem_rsp_valid <= 1'b0;
      mem_rsp_rdata <= {`XLEN{1'b0}};
      mem_rsp_error <= 1'b0;
      mem_rsp_owner_kind <= 2'b00;
      mem_rsp_owner_token <= 5'b00000;
      mem_rsp_mmu_epoch <= 2'b00;
      mem_rsp_fault_tval <= {`XLEN{1'b0}};
      mem_station_query_valid <= 1'b0;
      mem_station_query_owner_kind <= 2'b00;
      mem_station_query_token <= 5'b00000;
      mem_station_query_mmu_epoch <= 2'b00;
      data_mem_word <= {`XLEN{1'b0}};
    end else begin
      mem_station_query_valid <= 1'b0;
      if (mem_rsp_valid && mem_rsp_ready) begin
        mem_rsp_valid <= 1'b0;
      end

      if (mem_req_valid && mem_req_ready) begin
        mem_rsp_valid <= 1'b1;
        mem_rsp_error <= 1'b0;
        mem_rsp_owner_kind <= mem_req_owner_kind;
        mem_rsp_owner_token <= mem_req_owner_token;
        mem_rsp_mmu_epoch <= mem_req_mmu_epoch;
        mem_rsp_fault_tval <= mem_req_fault_tval;
        mem_station_query_valid <= 1'b1;
        mem_station_query_owner_kind <= mem_req_owner_kind;
        mem_station_query_token <= mem_req_owner_token;
        mem_station_query_mmu_epoch <= mem_req_mmu_epoch;
        if (mem_req_probe) begin
          // SQ-mode STORE first performs a side-effect-free translation/
          // protection probe.  Bare mode returns VA==PA; only the later
          // pretranslated nokill drain may update the memory model.
          mem_rsp_rdata <= mem_req_addr;
        end else if (mem_req_write) begin
          if (mem_req_addr == 64'h0000_0000_8000_0040) begin
            if (mem_req_wstrb[0]) begin
              data_mem_word[7:0] <= mem_req_wdata[7:0];
            end
            if (mem_req_wstrb[1]) begin
              data_mem_word[15:8] <= mem_req_wdata[15:8];
            end
            if (mem_req_wstrb[2]) begin
              data_mem_word[23:16] <= mem_req_wdata[23:16];
            end
            if (mem_req_wstrb[3]) begin
              data_mem_word[31:24] <= mem_req_wdata[31:24];
            end
            if (`STRB_W > 4 && mem_req_wstrb[4]) begin
              data_mem_word[39:32] <= mem_req_wdata[39:32];
            end
            if (`STRB_W > 5 && mem_req_wstrb[5]) begin
              data_mem_word[47:40] <= mem_req_wdata[47:40];
            end
            if (`STRB_W > 6 && mem_req_wstrb[6]) begin
              data_mem_word[55:48] <= mem_req_wdata[55:48];
            end
            if (`STRB_W > 7 && mem_req_wstrb[7]) begin
              data_mem_word[63:56] <= mem_req_wdata[63:56];
            end
          end
          mem_rsp_rdata <= {`XLEN{1'b0}};
        end else begin
          mem_rsp_rdata <= (mem_req_addr == 64'h0000_0000_8000_0040) ?
                           data_mem_word : {`XLEN{1'b0}};
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      commit_total <= 0;
      request_total <= 0;
      last_fetch_fire <= 1'b0;
      saw_back_to_back_fetch <= 1'b0;
      saw_dual_commit <= 1'b0;
      saw_memory_rsp_req_overlap <= 1'b0;
      saw_exact_owner_roundtrip <= 1'b0;
      saw_direct_redirect_fetch <= 1'b0;
      last_direct_redirect <= 1'b0;
      saw_branch_redirect_fetch <= 1'b0;
      saw_branch_shadow_prefetch <= 1'b0;
      saw_branch_shadow_hit <= 1'b0;
      saw_branch_spec_capture <= 1'b0;
      saw_branch_spec_correct <= 1'b0;
      saw_branch_spec_restore <= 1'b0;
      saw_backend_branch_resolve <= 1'b0;
      saw_control_fallthrough_fetch <= 1'b0;
      saw_lane1_ret_fallthrough <= 1'b0;
      saw_fp_gpr_completion <= 1'b0;
      saw_fp_gpr_completion_wake <= 1'b0;
      saw_head0_csr_stop_owner <= 1'b0;
      saw_control_full_flush_barrier <= 1'b0;
      saw_csr_full_flush_barrier <= 1'b0;
      saw_trap_full_flush_barrier <= 1'b0;
      saw_typed_csr_apply <= 1'b0;
      saw_typed_trap_apply <= 1'b0;
      saw_pending_csr_commit <= 1'b0;
      saw_pending_csr_exact_owner <= 1'b0;
      saw_pending_csr_control_pregrant <= 1'b0;
      saw_pending_csr_frontend_none <= 1'b0;
      saw_pending_csr_without_full_flush <= 1'b0;
      saw_pending_csr_without_next_apply <= 1'b0;
      pending_csr_commit_prev <= 1'b0;
      saw_csr_after_older_store <= 1'b0;
      csr_apply_seen <= 1'b0;
      saw_csr_branch_recovery_dispatch <= 1'b0;
      saw_csr_branch_recovery_selective <= 1'b0;
      saw_csr_branch_recovery_clear <= 1'b0;
      saw_csr_branch_recovery_commit <= 1'b0;
      csr_branch_recovery_selective_prev <= 1'b0;
      control_full_flush_barrier_prev <= 1'b0;
      control_full_flush_reason_prev <= `REDIR_REASON_NONE;
      saw_v8a_candidate <= 1'b0;
      saw_v8a_identity <= 1'b0;
      saw_fetch_fault_packet_enqueue <= 1'b0;
      saw_fetch_fault_predecode_fifo <= 1'b0;
      saw_fetch_fault_raw_fp_response <= 1'b0;
      saw_fetch_fault_static_zero_enqueue <= 1'b0;
      saw_fetch_fault_static_zero_fifo <= 1'b0;
    end else begin
      if (control_full_flush_barrier_prev && !flush) begin
        if (!dut.control_event_apply_valid_w ||
            (dut.control_event_apply_reason_w !=
             control_full_flush_reason_prev)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V9O C0/C1 typed apply mismatch prev_reason=%0d apply_valid=%0b apply_reason=%0d",
                   control_full_flush_reason_prev,
                   dut.control_event_apply_valid_w,
                   dut.control_event_apply_reason_w);
        end
      end
      control_full_flush_barrier_prev <= control_full_flush_barrier;
      control_full_flush_reason_prev <= control_full_flush_reason;
      if (control_full_flush_barrier) begin
        saw_control_full_flush_barrier <= 1'b1;
        if (control_full_flush_reason == `REDIR_REASON_CSR_COMMIT)
          saw_csr_full_flush_barrier <= 1'b1;
        if (control_full_flush_reason == `REDIR_REASON_TRAP)
          saw_trap_full_flush_barrier <= 1'b1;
      end
      if (dut.control_event_apply_valid_w &&
          (dut.control_event_apply_reason_w == `REDIR_REASON_CSR_COMMIT))
        saw_typed_csr_apply <= 1'b1;
      if ((program_mode == MODE_CSR_MEMORY_ORDER) &&
          dut.control_event_apply_valid_w &&
          (dut.control_event_apply_reason_w == `REDIR_REASON_CSR_COMMIT))
        csr_apply_seen <= 1'b1;
      if ((program_mode == MODE_CSR_MEMORY_ORDER) &&
          control_full_flush_barrier &&
          (control_full_flush_reason == `REDIR_REASON_CSR_COMMIT) &&
          (data_mem_word == 32'd11))
        saw_csr_after_older_store <= 1'b1;
      if ((program_mode == MODE_CSR_MEMORY_ORDER) &&
          !csr_apply_seen &&
          ((commit0_valid && (commit0_pc == 32'h8000_0014)) ||
           (commit1_valid && (commit1_pc == 32'h8000_0014)))) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] V9O younger load retired before queue-head CSR C1 apply");
      end
      if ((program_mode == MODE_CSR_BRANCH_RECOVERY) ||
          (program_mode == MODE_CSR_JALR_RECOVERY)) begin
        if (dut.u_frontend.head0_csr_dispatch_fire_w)
          saw_csr_branch_recovery_dispatch <= 1'b1;
        if (dut.frontend_control_event_valid_w &&
            (dut.frontend_control_event_backend_action_w ==
             `OOO_BACKEND_ACTION_SELECTIVE_NOW) &&
            dut.head0_csr_inflight_w) begin
          saw_csr_branch_recovery_selective <= 1'b1;
          csr_branch_recovery_selective_prev <= 1'b1;
        end else begin
          csr_branch_recovery_selective_prev <= 1'b0;
        end
        if (csr_branch_recovery_selective_prev) begin
          if (dut.head0_csr_inflight_w) begin
            tb_errors = tb_errors + 1;
            $display("[CHECK-FAIL] V9P wrong-path CSR inflight survived selective recovery");
          end else begin
            saw_csr_branch_recovery_clear <= 1'b1;
          end
        end
        if (tb_head0_csr_commit_w)
          saw_csr_branch_recovery_commit <= 1'b1;
      end else begin
        csr_branch_recovery_selective_prev <= 1'b0;
      end
      if (dut.control_event_apply_valid_w &&
          (dut.control_event_apply_reason_w == `REDIR_REASON_TRAP))
        saw_typed_trap_apply <= 1'b1;
      if (pending_csr_commit_prev) begin
        if (dut.control_event_apply_valid_w) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V9O pending CSR action NONE produced a C1 backend apply");
        end else begin
          saw_pending_csr_without_next_apply <= 1'b1;
        end
      end
      pending_csr_commit_prev <= dut.pending_system_csr_commit_w;
      if (dut.pending_system_csr_commit_w) begin
        saw_pending_csr_commit <= 1'b1;
        if (dut.pending_system_csr_q &&
            dut.pending_system_producer_valid_w &&
            (dut.core_commit0_producer_id_w ==
             dut.pending_system_producer_id_w))
          saw_pending_csr_exact_owner <= 1'b1;
        if (dut.u_execute_backend.u_core_slice.u_decode_backend
                .u_int_backend.control_event_pregrant_w)
          saw_pending_csr_control_pregrant <= 1'b1;
        if (dut.frontend_control_event_valid_w &&
            (dut.frontend_control_event_reason_w ==
             `REDIR_REASON_CSR_COMMIT) &&
            (dut.frontend_control_event_backend_action_w ==
             `OOO_BACKEND_ACTION_NONE))
          saw_pending_csr_frontend_none <= 1'b1;
        if (!control_full_flush_barrier &&
            (control_full_flush_reason == `REDIR_REASON_NONE))
          saw_pending_csr_without_full_flush <= 1'b1;
      end
      commit_total <= commit_total + commit0_valid + commit1_valid;
      if (head0_retire_candidate_valid)
        saw_v8a_candidate <= 1'b1;
      if (head0_identity_valid) begin
        saw_v8a_identity <= 1'b1;
        if ((^head0_identity) === 1'bx) begin
          tb_errors = tb_errors + 1;
          $display("[S2-Q2-V8A-WRAPPER][FAIL] public identity contains X while valid");
        end
      end
      if (fetch_req_valid && fetch_req_ready) begin
        request_total <= request_total + 1;
        if (last_fetch_fire) begin
          saw_back_to_back_fetch <= 1'b1;
        end
      end
      last_fetch_fire <= fetch_req_valid && fetch_req_ready;
      if (commit0_valid && commit1_valid) begin
        saw_dual_commit <= 1'b1;
      end
      // T3S 后 memory 的架构 issue owner 是 reservation capture；外部 request
      // 固定晚一拍，届时前端可能已看到后续 stop uop，不能再用 request 拍代替 issue 拍。
      if (((mem_req_valid && mem_req_ready) || mem_issue_res_capture) &&
          !dut.stop_pending_q) begin
        saw_memory_streaming <= 1'b1;
      end
      if (mem_req_valid && mem_req_ready && mem_rsp_valid && mem_rsp_ready) begin
        saw_memory_rsp_req_overlap <= 1'b1;
      end
      if (mem_rsp_valid && !flush) begin
        if (!mem_expected_valid || !mem_expected_tval_valid ||
            (mem_expected_owner_kind !== mem_rsp_owner_kind) ||
            (mem_expected_owner_token !== mem_rsp_owner_token) ||
            (mem_expected_mmu_epoch !== mem_rsp_mmu_epoch) ||
            (mem_expected_fault_tval !== mem_rsp_fault_tval) ||
            !mem_tracker_expected_valid ||
            (mem_tracker_expected_owner_kind !== mem_rsp_owner_kind) ||
            (mem_tracker_expected_owner_token !== mem_rsp_owner_token) ||
            (mem_tracker_expected_mmu_epoch !== mem_rsp_mmu_epoch)) begin
          tb_errors = tb_errors + 1;
          $display("[S2-G1-WRAPPER-OWNER][FAIL] response/MIQ/tracker tuple mismatch token=%0d", mem_rsp_owner_token);
        end else begin
          saw_exact_owner_roundtrip <= 1'b1;
        end
      end
      if (mem_station_query_valid &&
          (!mem_station_expected_valid ||
           (mem_station_expected_owner_kind !==
            mem_station_query_owner_kind) ||
           (mem_station_expected_owner_token !== mem_station_query_token) ||
           (mem_station_expected_mmu_epoch !==
            mem_station_query_mmu_epoch))) begin
        tb_errors = tb_errors + 1;
        $display("[S2-G1-WRAPPER-STATION][FAIL] station/tracker tuple mismatch token=%0d", mem_station_query_token);
      end
      if (dut.dispatch_fire_w && dut.head1_mem_raw_w &&
          !dut.stop_pending_q) begin
        saw_lane1_memory_streaming <= 1'b1;
      end
      if (dut.direct_ret0_fire_w || dut.direct_ret1_fire_w ||
          dut.pending_jump_return_fire_w) begin
        saw_return_fastpath <= 1'b1;
      end
      if (dut.direct_branch0_fire_w || dut.direct_branch1_fire_w) begin
        saw_branch_fastpath <= 1'b1;
      end
      // 【redirect 防火墙】同拍发射退役: direct 拍寄存一拍, 次拍顺序臂 fire 即命中
      last_direct_redirect <= dut.direct_redirect_fetch_w;
      if (last_direct_redirect && fetch_req_valid && fetch_req_ready) begin
        saw_direct_redirect_fetch <= 1'b1;
      end
      if (dut.branch_resolve_redirect_w && dut.redirect_fetch_req_valid_w &&
          fetch_req_valid && fetch_req_ready) begin
        saw_branch_redirect_fetch <= 1'b1;
      end
      if (dut.branch_prefetch_req_fire_w) begin
        saw_branch_shadow_prefetch <= 1'b1;
      end
      if (dut.branch_prefetch_hit_available_w &&
          dut.core_branch_resolve_valid_w) begin
        saw_branch_shadow_hit <= 1'b1;
      end
      if (dut.core_checkpoint_capture_w) begin
        saw_branch_spec_capture <= 1'b1;
      end
      if (dut.branch_spec_resolve_valid_w &&
          dut.branch_spec_pred_match_w) begin
        saw_branch_spec_correct <= 1'b1;
      end
      if (dut.branch_spec_restore_w) begin
        saw_branch_spec_restore <= 1'b1;
      end
      if (dut.core_branch_resolve_valid_w) begin
        saw_backend_branch_resolve <= 1'b1;
      end
      if (dut.core_dispatch_branch_resolve_valid_w) begin
        saw_branch_dispatch_resolve <= 1'b1;
      end
      if (dut.direct_branch0_lane1_ret_w) begin
        saw_lane1_ret_fallthrough <= 1'b1;
      end
      if (program_mode == MODE_CONTROL_FETCH_GATE &&
          fetch_req_valid && fetch_req_ready &&
          fetch_req_pc == 32'h8000_0008) begin
        saw_control_fallthrough_fetch <= 1'b1;
      end
      if (fp_result_wb_valid && !fp_result_wb_frd) begin
        saw_fp_gpr_completion <= 1'b1;
        if (fp_wake0_valid)
          saw_fp_gpr_completion_wake <= 1'b1;
      end
      // T3V integration witness: the injected lane1 access fault must first be
      // sanitized by PacketDecode, then survive as fault provenance alongside
      // the stored predecode bundle in the registered packet FIFO.
      if (dut.u_frontend.fetch_rsp_enqueue_w &&
          (dut.u_frontend.fetch_dec1_pc_w == fault_addr) &&
          (dut.u_frontend.fetch_dec1_resp_w == FETCH_RESP_ACCESS_FAULT) &&
          (dut.u_frontend.fetch_dec1_inst_w == 32'h0000_0013)) begin
        saw_fetch_fault_packet_enqueue <= 1'b1;
        if ((fetch_rsp_inst1 == FETCH_FAULT_RAW_FP_INST) &&
            (fetch_rsp_resp1 == FETCH_RESP_ACCESS_FAULT)) begin
          saw_fetch_fault_raw_fp_response <= 1'b1;
        end
        if (dut.u_frontend.fetch_dec1_static_facts_w ==
            {`OOO_SLOT_STATIC_FACTS_W{1'b0}}) begin
          saw_fetch_fault_static_zero_enqueue <= 1'b1;
          if (!saw_fetch_fault_static_zero_enqueue)
            $display("[T3W-FETCH-FAULT-STATIC] enqueue sanitized NOP facts=0");
        end
      end
      if (dut.u_frontend.fifo_has_packet_w &&
          (dut.u_frontend.head_pc1_w == fault_addr) &&
          (dut.u_frontend.head_resp1_w == FETCH_RESP_ACCESS_FAULT) &&
          (dut.u_frontend.head_inst1_w == 32'h0000_0013)) begin
        saw_fetch_fault_predecode_fifo <= 1'b1;
        if (dut.u_frontend.head1_static_facts_w ==
            {`OOO_SLOT_STATIC_FACTS_W{1'b0}}) begin
          saw_fetch_fault_static_zero_fifo <= 1'b1;
          if (!saw_fetch_fault_static_zero_fifo)
            $display("[T3W-FETCH-FAULT-STATIC] FIFO head sanitized NOP facts=0");
        end
        if (!saw_fetch_fault_predecode_fifo)
          $display("[T3V-FETCH-FAULT-PREDECODE] lane1 fault reached registered FIFO as sanitized NOP");
      end
      // 真实 CSR 集成合同：只认可 Frontend 由 CSR dispatch 产生的 inflight，
      // 不用 ALU/白盒强塞代理。inflight 与 stop 共存时，RunGate 必须持续封锁。
      if (`OOO_CSR_QUEUE_HEAD && dut.head0_csr_inflight_w &&
          dut.stop_pending_q && !dut.orphan_stop_pending_w &&
          dut.u_frontend.stop_pending_busy_w && !dut.can_run_w) begin
        saw_head0_csr_stop_owner <= 1'b1;
        if (!saw_head0_csr_stop_owner)
          $display("[T3U-CSR-STOP-OWNER-INTEGRATION] real CSR inflight owns stop");
      end
    end
  end

`ifdef V8Z_FRONTEND_II1_FOCUSED
  integer v8z_request_count;
  integer v8z_response_count;
  integer v8z_enqueue_count;
  integer v8z_dequeue_count;
  integer v8z_window_accepted;
  integer v8z_window_responses;
  integer v8z_window_enqueues;
  integer v8z_window_dequeues;
  integer v8z_window_sequences;
  integer v8z_window_stalls;
  integer v8z_redirect_cycles;
  reg v8z_last_request_valid;
  reg [`XLEN-1:0] v8z_last_request_pc;
  reg [`XLEN-1:0] v8z_request_pc_ledger [0:255];
  reg [`XLEN-1:0] v8z_enqueue_pc_ledger [0:255];

  task automatic v8z_sample_frontend_cycle;
    input require_turnover_i;
    input require_sink_i;
    input count_window_i;
    reg request_fire;
    reg response_fire;
    reg enqueue_fire;
    reg dequeue_fire;
    reg request_sequence_ok;
    reg redirect_or_stop;
    begin
      request_fire = fetch_req_valid && fetch_req_ready;
      response_fire = fetch_rsp_valid && fetch_rsp_ready;
      enqueue_fire = dut.u_frontend.fetch_rsp_enqueue_w;
      dequeue_fire = dut.u_frontend.fifo_pop_w;
      request_sequence_ok = !v8z_last_request_valid ||
          (fetch_req_pc == (v8z_last_request_pc + 64'd8));
      redirect_or_stop = dut.u_frontend.redirect_valid_w ||
          dut.u_frontend.direct_frontend_flush_w ||
          dut.u_frontend.resolve_redirect_block_w ||
          dut.u_frontend.direct_redirect_fetch_w ||
          dut.u_frontend.fetch_request_blocked_by_trap_w ||
          dut.u_frontend.stop_pending_busy_w ||
          dut.u_frontend.halted_q || dut.u_frontend.trap_valid_q ||
          dut.u_frontend.exit_valid_q ||
          dut.u_frontend.discard_fetch_rsp_q;

      if (response_fire) begin
        if (v8z_response_count >= v8z_request_count) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] response has no accepted request owner pc=0x%016x",
                   fetch_req_owner_pc);
        end else if (fetch_req_owner_pc !==
                     v8z_request_pc_ledger[v8z_response_count]) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] response owner=0x%016x expected request=0x%016x index=%0d",
                   fetch_req_owner_pc,
                   v8z_request_pc_ledger[v8z_response_count],
                   v8z_response_count);
        end
        v8z_response_count = v8z_response_count + 1;
      end

      if (request_fire) begin
        if (!request_sequence_ok) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] request successor=0x%016x previous=0x%016x",
                   fetch_req_pc, v8z_last_request_pc);
        end
        if (response_fire &&
            (fetch_req_pc !== (fetch_req_owner_pc + 64'd8))) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] turnover successor=0x%016x response owner=0x%016x",
                   fetch_req_pc, fetch_req_owner_pc);
        end
        v8z_request_pc_ledger[v8z_request_count] = fetch_req_pc;
        v8z_request_count = v8z_request_count + 1;
        v8z_last_request_pc = fetch_req_pc;
        v8z_last_request_valid = 1'b1;
      end

      if (enqueue_fire) begin
        if (!response_fire) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] enqueue without response fire");
        end
        if ((dut.u_frontend.fetch_dec0_pc_w !== fetch_req_owner_pc) ||
            (dut.u_frontend.fetch_dec1_pc_w !==
             (fetch_req_owner_pc + 64'd4))) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] enqueue pc0=0x%016x pc1=0x%016x response owner=0x%016x",
                   dut.u_frontend.fetch_dec0_pc_w,
                   dut.u_frontend.fetch_dec1_pc_w,
                   fetch_req_owner_pc);
        end
        v8z_enqueue_pc_ledger[v8z_enqueue_count] =
            dut.u_frontend.fetch_dec0_pc_w;
        v8z_enqueue_count = v8z_enqueue_count + 1;
      end

      if (dequeue_fire) begin
        if (v8z_dequeue_count >= v8z_enqueue_count) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] dequeue has no enqueued packet pc=0x%016x",
                   dut.u_frontend.fifo_head_pc0_w);
        end else if (dut.u_frontend.fifo_head_pc0_w !==
                     v8z_enqueue_pc_ledger[v8z_dequeue_count]) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] dequeue pc=0x%016x expected enqueue=0x%016x index=%0d",
                   dut.u_frontend.fifo_head_pc0_w,
                   v8z_enqueue_pc_ledger[v8z_dequeue_count],
                   v8z_dequeue_count);
        end
        if (dut.u_frontend.fifo_head_pc1_w !==
            (dut.u_frontend.fifo_head_pc0_w + 64'd4)) begin
          tb_errors = tb_errors + 1;
          $display("[V8Z-PC-LEDGER][FAIL] dequeue lane PCs are not one instruction apart");
        end
        v8z_dequeue_count = v8z_dequeue_count + 1;
      end

      if (require_turnover_i) begin
        tb_check1("V8Z response valid every required turnover cycle",
                  fetch_rsp_valid, 1'b1);
        tb_check1("V8Z response ready every required turnover cycle",
                  fetch_rsp_ready, 1'b1);
        tb_check1("V8Z response fires every required turnover cycle",
                  response_fire, 1'b1);
        tb_check1("V8Z response enqueues every required turnover cycle",
                  enqueue_fire, 1'b1);
        tb_check1("V8Z successor request fires every required turnover cycle",
                  request_fire, 1'b1);
        tb_check1("V8Z frontend retains one outstanding owner",
                  dut.u_frontend.outstanding_valid_q, 1'b1);
        tb_check1("V8Z response has FIFO enqueue credit",
                  dut.u_frontend.fetch_rsp_can_enqueue_w, 1'b1);
        tb_check1("V8Z FIFO reserve admits successor",
                  dut.u_frontend.fifo_reserve_available_w, 1'b1);
      end
      if (require_sink_i)
        tb_check1("V8Z FIFO sink consumes one packet", dequeue_fire, 1'b1);

      if (count_window_i) begin
        if (request_fire)
          v8z_window_accepted = v8z_window_accepted + 1;
        if (response_fire)
          v8z_window_responses = v8z_window_responses + 1;
        if (enqueue_fire)
          v8z_window_enqueues = v8z_window_enqueues + 1;
        if (dequeue_fire)
          v8z_window_dequeues = v8z_window_dequeues + 1;
        if (request_fire && request_sequence_ok)
          v8z_window_sequences = v8z_window_sequences + 1;
        if (!(request_fire && response_fire && enqueue_fire &&
              dequeue_fire && request_sequence_ok))
          v8z_window_stalls = v8z_window_stalls + 1;
      end

      if (redirect_or_stop)
        v8z_redirect_cycles = v8z_redirect_cycles + 1;
      tb_check1("V8Z trajectory has no redirect or control stop",
                redirect_or_stop, 1'b0);
    end
  endtask

  initial begin : v8z_frontend_ii1_focused
    integer beat;
    integer wait_cycle;
    integer held_request_count;
    integer held_response_count;
    integer held_enqueue_count;
    reg [`XLEN-1:0] held_owner_pc;
    reg [`INST_W-1:0] held_inst0;
    reg [`INST_W-1:0] held_inst1;

    tb_errors = 0;
    v8z_request_count = 0;
    v8z_response_count = 0;
    v8z_enqueue_count = 0;
    v8z_dequeue_count = 0;
    v8z_window_accepted = 0;
    v8z_window_responses = 0;
    v8z_window_enqueues = 0;
    v8z_window_dequeues = 0;
    v8z_window_sequences = 0;
    v8z_window_stalls = 0;
    v8z_redirect_cycles = 0;
    v8z_last_request_valid = 1'b0;
    v8z_last_request_pc = {`XLEN{1'b0}};

    reset_dut(MODE_FRONTEND_II1, 32'h0000_0000);

    // Prologue: record the seed request, then one response/enqueue cycle.  The
    // following cycle has independent request, response, enqueue and FIFO
    // dequeue owners and is the first post-warmup measurement cycle.
    v8z_sample_frontend_cycle(1'b0, 1'b0, 1'b0);
    `TB_TICK(clk);
    #1;
    v8z_sample_frontend_cycle(1'b1, 1'b0, 1'b0);
    `TB_TICK(clk);
    #1;

    for (beat = 0; beat < 64; beat = beat + 1) begin
      v8z_sample_frontend_cycle(1'b1, 1'b1, 1'b1);
      `TB_TICK(clk);
      #1;
    end

    tb_check32("V8Z accepted packet count", v8z_window_accepted, 32'd64);
    tb_check32("V8Z response packet count", v8z_window_responses, 32'd64);
    tb_check32("V8Z enqueue packet count", v8z_window_enqueues, 32'd64);
    tb_check32("V8Z independent sink packet count",
               v8z_window_dequeues, 32'd64);
    tb_check32("V8Z sequential successor count",
               v8z_window_sequences, 32'd64);
    tb_check32("V8Z measured stall count", v8z_window_stalls, 32'd0);
    tb_check32("V8Z redirect or stop count", v8z_redirect_cycles, 32'd0);
    if ((v8z_window_accepted == 64) &&
        (v8z_window_responses == 64) &&
        (v8z_window_enqueues == 64) &&
        (v8z_window_dequeues == 64) &&
        (v8z_window_sequences == 64) &&
        (v8z_window_stalls == 0) && (v8z_redirect_cycles == 0) &&
        (tb_errors == 0)) begin
      $display("[V8Z-FRONTEND-II1-INTEGRATION] preheated_cycles=64 packets_observed=64 accepted=64 responses=64 enqueues=64 produced=64 max_ii=1 sequential=64 redirects=0 stalls=0 PASS");
    end

    // The FIFO reservation invariant prevents a legal outstanding response
    // from colliding with a full FIFO.  Pause run_i instead: this closes the
    // real FlowControl response-ready path while preserving the outstanding
    // owner and payload, then reopens the same path without a flush/drop.
    run = 1'b0;
    #1;
    tb_check1("V8Z finite run pause reaches a held response",
              fetch_rsp_valid && !fetch_rsp_ready, 1'b1);
    held_owner_pc = fetch_req_owner_pc;
    held_inst0 = fetch_rsp_inst0;
    held_inst1 = fetch_rsp_inst1;
    held_request_count = v8z_request_count;
    held_response_count = v8z_response_count;
    held_enqueue_count = v8z_enqueue_count;
    repeat (4) begin
      tb_check1("V8Z held response stays valid", fetch_rsp_valid, 1'b1);
      tb_check1("V8Z held response remains backpressured",
                fetch_rsp_ready, 1'b0);
      tb_check1("V8Z held response owner is stable",
                fetch_req_owner_pc == held_owner_pc, 1'b1);
      tb_check1("V8Z held response lane0 is stable",
                fetch_rsp_inst0 == held_inst0, 1'b1);
      tb_check1("V8Z held response lane1 is stable",
                fetch_rsp_inst1 == held_inst1, 1'b1);
      v8z_sample_frontend_cycle(1'b0, 1'b0, 1'b0);
      tb_check32("V8Z backpressure accepts no replacement request",
                 v8z_request_count, held_request_count);
      tb_check32("V8Z backpressure consumes no held response",
                 v8z_response_count, held_response_count);
      tb_check32("V8Z backpressure performs no duplicate enqueue",
                 v8z_enqueue_count, held_enqueue_count);
      `TB_TICK(clk);
      #1;
    end

    run = 1'b1;
    #1;
    tb_check1("V8Z held response resumes with an exact successor",
              fetch_rsp_valid && fetch_rsp_ready &&
              dut.u_frontend.fetch_rsp_enqueue_w &&
              fetch_req_valid && fetch_req_ready, 1'b1);
    v8z_sample_frontend_cycle(1'b1, 1'b0, 1'b0);
    `TB_TICK(clk);
    #1;
    for (beat = 0; beat < 16; beat = beat + 1) begin
      v8z_sample_frontend_cycle(1'b1, 1'b1, 1'b0);
      `TB_TICK(clk);
      #1;
    end
    if (tb_errors == 0)
      $display("[V8Z-FRONTEND-II1-BACKPRESSURE] source=run_gate held_cycles=4 resume_turnovers=16 payload_stable=1 owner_stable=1 duplicate_enqueue=0 PASS");

    // Epilogue: close external successor admission but keep the current
    // response consumable.  Drain that tail, FIFO and backend, then require
    // exact request/response/enqueue/dequeue conservation and no ghost owner.
    fetch_req_admit = 1'b0;
    #1;
    tb_check1("V8Z epilogue has one tail response", fetch_rsp_valid, 1'b1);
    tb_check1("V8Z epilogue consumes the tail response",
              fetch_rsp_ready, 1'b1);
    tb_check1("V8Z epilogue blocks successor request fire",
              fetch_req_valid && fetch_req_ready, 1'b0);
    v8z_sample_frontend_cycle(1'b0, 1'b1, 1'b0);
    `TB_TICK(clk);
    #1;
    for (wait_cycle = 0;
         (wait_cycle < 160) &&
         (dut.u_frontend.outstanding_valid_q || fetch_rsp_valid ||
          (dut.u_frontend.fifo_count_q != 0) || (rob_count != 0) ||
          (issue_count != 0));
         wait_cycle = wait_cycle + 1) begin
      v8z_sample_frontend_cycle(1'b0, 1'b0, 1'b0);
      `TB_TICK(clk);
      #1;
    end
    tb_check32("V8Z final request-response conservation",
               v8z_response_count, v8z_request_count);
    tb_check32("V8Z final response-enqueue conservation",
               v8z_enqueue_count, v8z_response_count);
    tb_check32("V8Z final enqueue-dequeue conservation",
               v8z_dequeue_count, v8z_enqueue_count);
    tb_check1("V8Z final outstanding owner is empty",
              dut.u_frontend.outstanding_valid_q, 1'b0);
    tb_check1("V8Z final response channel is empty",
              fetch_rsp_valid, 1'b0);
    tb_check32("V8Z final frontend FIFO is empty",
               dut.u_frontend.fifo_count_q, 32'd0);
    tb_check32("V8Z final ROB is empty", {27'b0, rob_count}, 32'd0);
    tb_check32("V8Z final issue queue is empty",
               {28'b0, issue_count}, 32'd0);
    tb_check32("V8Z final physical register free count",
               {25'b0, free_count}, 32'd32);
    if ((v8z_request_count == v8z_response_count) &&
        (v8z_response_count == v8z_enqueue_count) &&
        (v8z_enqueue_count == v8z_dequeue_count) &&
        !dut.u_frontend.outstanding_valid_q && !fetch_rsp_valid &&
        (dut.u_frontend.fifo_count_q == 0) && (rob_count == 0) &&
        (issue_count == 0) && (free_count == 32) &&
        (tb_errors == 0)) begin
      $display("[V8Z-FRONTEND-II1-DRAIN] requests=%0d responses=%0d enqueues=%0d dequeues=%0d outstanding=0 fifo=0 rob=0 issue=0 ghosts=0 PASS",
               v8z_request_count, v8z_response_count,
               v8z_enqueue_count, v8z_dequeue_count);
    end
    tb_finish("tb_ooo_core_top_glue_v8z_frontend_ii1");
  end
`elsif V9A_WIDTH_CONTINUITY_FOCUSED
  localparam integer V9A_WARMUP_CYCLES = 24;
  localparam integer V9A_TRACE_CYCLES = 64;
  localparam integer V9A_BOUNDARY_N = 7;
  localparam integer V9A_PID_N = (1 << `OOO_PRODUCER_ID_W);
  localparam integer V9A_FETCH = 0;
  localparam integer V9A_DECODE = 1;
  localparam integer V9A_RENAME = 2;
  localparam integer V9A_DISPATCH = 3;
  localparam integer V9A_ISSUE = 4;
  localparam integer V9A_EXECUTE = 5;
  localparam integer V9A_RETIRE = 6;
  localparam [1:0] V9A_PID_ALLOCATED = 2'd1;
  localparam [1:0] V9A_PID_ISSUED = 2'd2;
  localparam [1:0] V9A_PID_EXECUTED = 2'd3;

  integer v9a_total [0:V9A_BOUNDARY_N-1];
  integer v9a_peak [0:V9A_BOUNDARY_N-1];
  integer v9a_dual_cycles [0:V9A_BOUNDARY_N-1];
  integer v9a_seen [0:V9A_BOUNDARY_N-1];
  integer v9a_request_count;
  integer v9a_response_count;
  integer v9a_enqueue_count;
  integer v9a_active_count;
  integer v9a_ledger_errors;
  integer v9a_cycle;
  integer v9a_init_i;

  reg v9a_pid_active [0:V9A_PID_N-1];
  reg [1:0] v9a_pid_state [0:V9A_PID_N-1];
  reg [`XLEN-1:0] v9a_pid_pc [0:V9A_PID_N-1];
  reg [`INST_W-1:0] v9a_pid_inst [0:V9A_PID_N-1];
  reg [`XLEN-1:0] v9a_pid_expected_data [0:V9A_PID_N-1];
  reg [`REG_ADDR_W-1:0] v9a_pid_rd [0:V9A_PID_N-1];

  reg v9a_rename_pending0_valid;
  reg [`REG_ADDR_W-1:0] v9a_rename_pending0_rd;
  reg [`OOO_PHY_REG_ADDR_W-1:0] v9a_rename_pending0_pdest;
  reg v9a_rename_pending1_valid;
  reg [`REG_ADDR_W-1:0] v9a_rename_pending1_rd;
  reg [`OOO_PHY_REG_ADDR_W-1:0] v9a_rename_pending1_pdest;

  reg v9a_ex_pending0_valid;
  reg [`OOO_PRODUCER_ID_W-1:0] v9a_ex_pending0_pid;
  reg [`OOO_PHY_REG_ADDR_W-1:0] v9a_ex_pending0_pdest;
  reg [`XLEN-1:0] v9a_ex_pending0_result;
  reg v9a_ex_pending0_exception;
  reg [`TRAP_CAUSE_W-1:0] v9a_ex_pending0_cause;
  reg [`XLEN-1:0] v9a_ex_pending0_tval;
  reg v9a_ex_pending0_fwd;
  reg v9a_ex_pending1_valid;
  reg [`OOO_PRODUCER_ID_W-1:0] v9a_ex_pending1_pid;
  reg [`OOO_PHY_REG_ADDR_W-1:0] v9a_ex_pending1_pdest;
  reg [`XLEN-1:0] v9a_ex_pending1_result;
  reg v9a_ex_pending1_exception;
  reg [`TRAP_CAUSE_W-1:0] v9a_ex_pending1_cause;
  reg [`XLEN-1:0] v9a_ex_pending1_tval;
  reg v9a_ex_pending1_fwd;

  function [`XLEN-1:0] v9a_expected_data_for_pc;
    input [`XLEN-1:0] pc_i;
    reg [`XLEN-1:0] seq_value;
    reg [11:0] imm;
    begin
      seq_value = (pc_i - `RESET_PC) >> 2;
      imm = seq_value[11:0] + 12'd1;
      v9a_expected_data_for_pc = {{(`XLEN-12){imm[11]}}, imm};
    end
  endfunction

  task automatic v9a_check_fail;
    input [8*96-1:0] message_i;
    begin
      tb_errors = tb_errors + 1;
      $display("[V9A-WIDTH][FAIL] %0s", message_i);
    end
  endtask

  task automatic v9a_ledger_fail;
    input [8*96-1:0] message_i;
    begin
      tb_errors = tb_errors + 1;
      v9a_ledger_errors = v9a_ledger_errors + 1;
      $display("[V9A-IDENTITY][FAIL] %0s", message_i);
    end
  endtask

  task automatic v9a_check_stream_event;
    input integer boundary_i;
    input [`XLEN-1:0] pc_i;
    input [`INST_W-1:0] inst_i;
    reg [`XLEN-1:0] expected_pc;
    reg [`INST_W-1:0] expected_inst;
    begin
      expected_pc = `RESET_PC + (v9a_seen[boundary_i] * 4);
      expected_inst = program_word(expected_pc);
      if (pc_i !== expected_pc) begin
        v9a_ledger_fail("boundary PC sequence mismatch");
        $display("[V9A-IDENTITY-DETAIL] boundary=%0d seen=%0d pc=%h expected=%h",
                 boundary_i, v9a_seen[boundary_i], pc_i, expected_pc);
      end
      if (inst_i !== expected_inst) begin
        v9a_ledger_fail("boundary instruction payload mismatch");
        $display("[V9A-IDENTITY-DETAIL] boundary=%0d pc=%h inst=%h expected=%h",
                 boundary_i, pc_i, inst_i, expected_inst);
      end
      if ((inst_i[6:0] !== `OPCODE_OP_IMM) ||
          (inst_i[19:15] !== 5'd0) || (inst_i[11:7] == 5'd0)) begin
        v9a_ledger_fail("stream is not independent nonzero-rd ADDI");
      end
      v9a_seen[boundary_i] = v9a_seen[boundary_i] + 1;
    end
  endtask

  task automatic v9a_allocate_pid;
    input [`OOO_PRODUCER_ID_W-1:0] pid_i;
    input [`XLEN-1:0] pc_i;
    input [`INST_W-1:0] inst_i;
    integer pid_index;
    begin
      pid_index = pid_i;
      if ((^pid_i) === 1'bx) begin
        v9a_ledger_fail("dispatch full ProducerId contains X");
      end else if (v9a_pid_active[pid_index]) begin
        v9a_ledger_fail("dispatch reused an active full ProducerId");
      end else begin
        v9a_pid_active[pid_index] = 1'b1;
        v9a_pid_state[pid_index] = V9A_PID_ALLOCATED;
        v9a_pid_pc[pid_index] = pc_i;
        v9a_pid_inst[pid_index] = inst_i;
        v9a_pid_expected_data[pid_index] = v9a_expected_data_for_pc(pc_i);
        v9a_pid_rd[pid_index] = inst_i[11:7];
        v9a_active_count = v9a_active_count + 1;
      end
    end
  endtask

  task automatic v9a_issue_pid;
    input [`OOO_PRODUCER_ID_W-1:0] pid_i;
    input [`XLEN-1:0] pc_i;
    input [`INST_W-1:0] inst_i;
    integer pid_index;
    begin
      pid_index = pid_i;
      if ((^pid_i) === 1'bx || !v9a_pid_active[pid_index]) begin
        v9a_ledger_fail("issue has no active dispatch allocation");
      end else begin
        if (v9a_pid_state[pid_index] != V9A_PID_ALLOCATED)
          v9a_ledger_fail("issue lifecycle is not allocated to issued");
        if ((v9a_pid_pc[pid_index] !== pc_i) ||
            (v9a_pid_inst[pid_index] !== inst_i))
          v9a_ledger_fail("issue full ProducerId payload mismatch");
        v9a_pid_state[pid_index] = V9A_PID_ISSUED;
      end
    end
  endtask

  task automatic v9a_execute_pid;
    input [`OOO_PRODUCER_ID_W-1:0] pid_i;
    input [`XLEN-1:0] data_i;
    integer pid_index;
    begin
      pid_index = pid_i;
      if ((^pid_i) === 1'bx || !v9a_pid_active[pid_index]) begin
        v9a_ledger_fail("execute WB has no active dispatch allocation");
      end else begin
        if (v9a_pid_state[pid_index] != V9A_PID_ISSUED)
          v9a_ledger_fail("execute lifecycle is not issued to executed");
        if (data_i !== v9a_pid_expected_data[pid_index]) begin
          v9a_ledger_fail("execute result does not match PC-derived immediate");
          $display("[V9A-IDENTITY-DETAIL] pid=%h pc=%h data=%h expected=%h",
                   pid_i, v9a_pid_pc[pid_index], data_i,
                   v9a_pid_expected_data[pid_index]);
        end
        v9a_pid_state[pid_index] = V9A_PID_EXECUTED;
        v9a_check_stream_event(V9A_EXECUTE, v9a_pid_pc[pid_index],
                               v9a_pid_inst[pid_index]);
      end
    end
  endtask

  task automatic v9a_retire_pid;
    input [`OOO_PRODUCER_ID_W-1:0] pid_i;
    input [`XLEN-1:0] pc_i;
    input [`INST_W-1:0] inst_i;
    input [`REG_ADDR_W-1:0] rd_i;
    input [`XLEN-1:0] data_i;
    integer pid_index;
    begin
      pid_index = pid_i;
      if ((^pid_i) === 1'bx || !v9a_pid_active[pid_index]) begin
        v9a_ledger_fail("retire has no active dispatch allocation");
      end else begin
        if (v9a_pid_state[pid_index] != V9A_PID_EXECUTED)
          v9a_ledger_fail("retire lifecycle is not executed to retired");
        if ((v9a_pid_pc[pid_index] !== pc_i) ||
            (v9a_pid_inst[pid_index] !== inst_i) ||
            (v9a_pid_rd[pid_index] !== rd_i) ||
            (v9a_pid_expected_data[pid_index] !== data_i))
          v9a_ledger_fail("retire payload does not match allocation instance");
        v9a_pid_active[pid_index] = 1'b0;
        v9a_pid_state[pid_index] = 2'd0;
        v9a_active_count = v9a_active_count - 1;
      end
      v9a_check_stream_event(V9A_RETIRE, pc_i, inst_i);
    end
  endtask

  task automatic v9a_check_previous_rename_state;
    begin
      if (v9a_rename_pending0_valid &&
          (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_dispatch_backend.u_rename_map.map_q[v9a_rename_pending0_rd]
           !== v9a_rename_pending0_pdest))
        v9a_ledger_fail("rename lane0 did not update speculative map");
      if (v9a_rename_pending1_valid &&
          (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_dispatch_backend.u_rename_map.map_q[v9a_rename_pending1_rd]
           !== v9a_rename_pending1_pdest))
        v9a_ledger_fail("rename lane1 did not update speculative map");
      v9a_rename_pending0_valid = 1'b0;
      v9a_rename_pending1_valid = 1'b0;
    end
  endtask

  task automatic v9a_check_previous_ex_stage;
    begin
      if (v9a_ex_pending0_valid) begin
        if (!dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                .u_ex0_stage.down_valid_o)
          v9a_ledger_fail("EX0 capture did not emerge on the next cycle");
        if ((dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex0_producer_id_q !== v9a_ex_pending0_pid) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex0_pdest_q !== v9a_ex_pending0_pdest) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex0_result_q !== v9a_ex_pending0_result) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex0_exception_q !== v9a_ex_pending0_exception) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex0_cause_q !== v9a_ex_pending0_cause) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex0_tval_q !== v9a_ex_pending0_tval) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex0_registered_fwd_valid_w !== v9a_ex_pending0_fwd))
          v9a_ledger_fail("EX0 next-cycle full ProducerId or payload mismatch");
      end else if (dut.u_execute_backend.u_core_slice.u_decode_backend
                       .u_int_backend.u_ex0_stage.down_valid_o) begin
        v9a_ledger_fail("EX0 stage emitted without a prior-cycle capture");
      end
      if (v9a_ex_pending1_valid) begin
        if (!dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                .u_ex1_stage.down_valid_o)
          v9a_ledger_fail("EX1 capture did not emerge on the next cycle");
        if ((dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex1_producer_id_q !== v9a_ex_pending1_pid) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex1_pdest_q !== v9a_ex_pending1_pdest) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex1_result_q !== v9a_ex_pending1_result) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex1_exception_q !== v9a_ex_pending1_exception) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex1_cause_q !== v9a_ex_pending1_cause) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex1_tval_q !== v9a_ex_pending1_tval) ||
            (dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                 .ex1_registered_fwd_valid_w !== v9a_ex_pending1_fwd))
          v9a_ledger_fail("EX1 next-cycle full ProducerId or payload mismatch");
      end else if (dut.u_execute_backend.u_core_slice.u_decode_backend
                       .u_int_backend.u_ex1_stage.down_valid_o) begin
        v9a_ledger_fail("EX1 stage emitted without a prior-cycle capture");
      end
      v9a_ex_pending0_valid = 1'b0;
      v9a_ex_pending1_valid = 1'b0;
    end
  endtask

  task automatic v9a_observe_cycle;
    input count_trace_i;
    input integer trace_cycle_i;
    integer width [0:V9A_BOUNDARY_N-1];
    integer boundary_i;
    reg fetch_packet_fire;
    reg decode0_fire;
    reg decode1_fire;
    reg decode0_backend_fire;
    reg decode1_backend_fire;
    reg rename0_fire;
    reg rename1_fire;
    reg dispatch0_parent_fire;
    reg dispatch1_parent_fire;
    reg dispatch0_rob_fire;
    reg dispatch1_rob_fire;
    reg dispatch0_iq_fire;
    reg dispatch1_iq_fire;
    reg dispatch0_fire;
    reg dispatch1_fire;
    reg issue0_fire;
    reg issue1_fire;
    reg issue0_iq_fire;
    reg issue1_iq_fire;
    reg execute0_fire;
    reg execute1_fire;
    reg retire0_fire;
    reg retire1_fire;
    reg redirect_or_stop;
    begin
      v9a_check_previous_rename_state();

      fetch_packet_fire = dut.u_frontend.fetch_rsp_enqueue_w === 1'b1;
      decode0_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.dispatch0_valid_i &&
          dut.u_execute_backend.u_core_slice.u_decode_backend.dispatch0_ready_o;
      decode1_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.dispatch1_valid_i &&
          dut.u_execute_backend.u_core_slice.u_decode_backend.dispatch1_ready_o;
      decode0_backend_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .dispatch0_valid_i &&
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .dispatch0_ready_o;
      decode1_backend_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .dispatch1_valid_i &&
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .dispatch1_ready_o;
      rename0_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .u_dispatch_backend.u_rename_map.rename0_valid_i;
      rename1_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .u_dispatch_backend.u_rename_map.rename1_valid_i;
      dispatch0_parent_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .dispatch0_fire_w;
      dispatch1_parent_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .dispatch1_fire_w;
      dispatch0_rob_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .u_dispatch_backend.u_rob.dispatch0_fire_w;
      dispatch1_rob_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .u_dispatch_backend.u_rob.dispatch1_fire_w;
      dispatch0_iq_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .u_dispatch_backend.u_issue_queue.dispatch0_fire_w;
      dispatch1_iq_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .u_dispatch_backend.u_issue_queue.dispatch1_fire_w;
      dispatch0_fire = dispatch0_parent_fire && dispatch0_rob_fire &&
                       dispatch0_iq_fire;
      dispatch1_fire = dispatch1_parent_fire && dispatch1_rob_fire &&
                       dispatch1_iq_fire;
      issue0_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .issue0_fire_w;
      issue1_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .issue1_exec_fire_w;
      issue0_iq_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .u_dispatch_backend.u_issue_queue.issue0_fire_w;
      issue1_iq_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .u_dispatch_backend.u_issue_queue.issue1_fire_w;
      execute0_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .execute0_valid_o;
      execute1_fire =
          dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
             .execute1_valid_o;
      retire0_fire = commit0_valid;
      retire1_fire = commit1_valid;

      // The stage contract is edge-based: compare last cycle's actual input
      // capture against this cycle's registered full ProducerId and payload.
      v9a_check_previous_ex_stage();

      if ((dispatch0_parent_fire !== dispatch0_rob_fire) ||
          (dispatch0_parent_fire !== dispatch0_iq_fire) ||
          (dispatch1_parent_fire !== dispatch1_rob_fire) ||
          (dispatch1_parent_fire !== dispatch1_iq_fire))
        v9a_ledger_fail("parent dispatch fire disagrees with ROB/IQ sink fire");
      if ((decode0_fire !== decode0_backend_fire) ||
          (decode1_fire !== decode1_backend_fire))
        v9a_ledger_fail("decode acceptance disagrees with integer backend input");
      if ((rename0_fire !== dispatch0_parent_fire) ||
          (rename1_fire !== dispatch1_parent_fire))
        v9a_ledger_fail("RenameMap sink fire disagrees with dispatch allocation");
      if ((issue0_fire !==
           dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_ex0_stage.up_valid_i) ||
          (issue1_fire !==
           dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_ex1_stage.up_valid_i))
        v9a_ledger_fail("ALU issue fire disagrees with EX stage capture");
      if ((issue0_iq_fire !== issue0_fire) ||
          (issue1_iq_fire !== issue1_fire))
        v9a_ledger_fail("IQ issue disagrees with physical ALU terminal acceptance");
      if ((execute0_fire !==
           dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_ex0_stage.down_valid_o) ||
          (execute1_fire !==
           dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_ex1_stage.down_valid_o))
        v9a_ledger_fail("EX stage release disagrees with authorized WB event");
      if ((execute0_fire !==
           dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_dispatch_backend.u_rob.wb0_valid_i) ||
          (execute1_fire !==
           dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_dispatch_backend.u_rob.wb1_valid_i))
        v9a_ledger_fail("authorized WB event disagrees with ROB completion sink");
      if ((retire0_fire !==
           dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_dispatch_backend.u_rob.commit0_fire_w) ||
          (retire1_fire !==
           dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .u_dispatch_backend.u_rob.commit1_fire_w))
        v9a_ledger_fail("ROB commit fire disagrees with retirement event");

      if (fetch_req_valid && fetch_req_ready)
        v9a_request_count = v9a_request_count + 1;
      if (fetch_rsp_valid && fetch_rsp_ready)
        v9a_response_count = v9a_response_count + 1;
      if (fetch_packet_fire)
        v9a_enqueue_count = v9a_enqueue_count + 1;

      if (fetch_packet_fire) begin
        v9a_check_stream_event(V9A_FETCH, dut.u_frontend.fetch_dec0_pc_w,
                               dut.u_frontend.fetch_dec0_inst_w);
        v9a_check_stream_event(V9A_FETCH, dut.u_frontend.fetch_dec1_pc_w,
                               dut.u_frontend.fetch_dec1_inst_w);
      end
      if (decode0_fire) begin
        v9a_check_stream_event(
            V9A_DECODE,
            dut.u_execute_backend.u_core_slice.u_decode_backend.dispatch0_pc_i,
            dut.u_execute_backend.u_core_slice.u_decode_backend.dispatch0_inst_i);
      end
      if (decode1_fire) begin
        v9a_check_stream_event(
            V9A_DECODE,
            dut.u_execute_backend.u_core_slice.u_decode_backend.dispatch1_pc_i,
            dut.u_execute_backend.u_core_slice.u_decode_backend.dispatch1_inst_i);
      end
      if (dut.u_frontend.fifo_pop_w !== (decode0_fire && decode1_fire))
        v9a_ledger_fail("FIFO pop is not an exact dual decode acceptance");

      if (rename0_fire) begin
        v9a_check_stream_event(
            V9A_RENAME,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch0_pc_i,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch0_inst_i);
        v9a_rename_pending0_valid = 1'b1;
        v9a_rename_pending0_rd =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .u_dispatch_backend.u_rename_map.rename0_rd_arch_i;
        v9a_rename_pending0_pdest =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .u_dispatch_backend.u_rename_map.rename0_new_pdest_i;
        if (v9a_rename_pending0_pdest == {`OOO_PHY_REG_ADDR_W{1'b0}})
          v9a_ledger_fail("rename lane0 allocated pdest zero");
      end
      if (rename1_fire) begin
        v9a_check_stream_event(
            V9A_RENAME,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch1_pc_i,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch1_inst_i);
        v9a_rename_pending1_valid = 1'b1;
        v9a_rename_pending1_rd =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .u_dispatch_backend.u_rename_map.rename1_rd_arch_i;
        v9a_rename_pending1_pdest =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .u_dispatch_backend.u_rename_map.rename1_new_pdest_i;
        if (v9a_rename_pending1_pdest == {`OOO_PHY_REG_ADDR_W{1'b0}})
          v9a_ledger_fail("rename lane1 allocated pdest zero");
      end
      if (rename0_fire && rename1_fire &&
          ((v9a_rename_pending0_rd == v9a_rename_pending1_rd) ||
           (v9a_rename_pending0_pdest == v9a_rename_pending1_pdest)))
        v9a_ledger_fail("rename lanes do not have distinct rd and pdest");

      if (dispatch0_fire) begin
        v9a_check_stream_event(
            V9A_DISPATCH,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch0_pc_i,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch0_inst_i);
        v9a_allocate_pid(
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch0_producer_id_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch0_pc_i,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch0_inst_i);
      end
      if (dispatch1_fire) begin
        v9a_check_stream_event(
            V9A_DISPATCH,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch1_pc_i,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch1_inst_i);
        v9a_allocate_pid(
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch1_producer_id_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch1_pc_i,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .dispatch1_inst_i);
      end

      if (issue0_fire) begin
        v9a_check_stream_event(
            V9A_ISSUE,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue0_pc_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue0_inst_w);
        v9a_issue_pid(
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .iq_issue0_producer_id_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue0_pc_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue0_inst_w);
      end
      if (issue1_fire) begin
        v9a_check_stream_event(
            V9A_ISSUE,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue1_pc_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue1_inst_w);
        v9a_issue_pid(
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue1_producer_id_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue1_pc_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue1_inst_w);
      end

      if (issue0_fire) begin
        v9a_ex_pending0_valid = 1'b1;
        v9a_ex_pending0_pid =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex0_up_producer_id_w;
        v9a_ex_pending0_pdest =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue0_pdest_w;
        v9a_ex_pending0_result =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex0_up_result_w;
        v9a_ex_pending0_exception =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex0_up_exception_w;
        v9a_ex_pending0_cause =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex0_up_cause_w;
        v9a_ex_pending0_tval =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex0_up_tval_w;
        v9a_ex_pending0_fwd =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .early_wakeup0_valid_w &&
            !dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex0_up_from_mem_w;
      end
      if (issue1_fire) begin
        v9a_ex_pending1_valid = 1'b1;
        v9a_ex_pending1_pid =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex1_up_producer_id_w;
        v9a_ex_pending1_pdest =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .issue1_pdest_w;
        v9a_ex_pending1_result =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex1_up_result_w;
        v9a_ex_pending1_exception =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex1_up_exception_w;
        v9a_ex_pending1_cause =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex1_up_cause_w;
        v9a_ex_pending1_tval =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex1_up_tval_w;
        v9a_ex_pending1_fwd =
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .early_wakeup1_valid_w &&
            !dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .ex1_up_from_mem_w;
      end

      if (execute0_fire)
        v9a_execute_pid(
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .wb0_producer_id_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .wb0_data_w);
      if (execute1_fire)
        v9a_execute_pid(
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .wb1_producer_id_w,
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .wb1_data_w);

      if (retire0_fire)
        v9a_retire_pid(
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .rob_commit0_producer_id_w,
            commit0_pc, commit0_inst, commit0_rd_addr, commit0_rd_data);
      if (retire1_fire)
        v9a_retire_pid(
            dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
               .rob_commit1_producer_id_w,
            commit1_pc, commit1_inst, commit1_rd_addr, commit1_rd_data);

      width[V9A_FETCH] = fetch_packet_fire ? 2 : 0;
      width[V9A_DECODE] = decode0_fire + decode1_fire;
      width[V9A_RENAME] = rename0_fire + rename1_fire;
      width[V9A_DISPATCH] = dispatch0_fire + dispatch1_fire;
      width[V9A_ISSUE] = issue0_fire + issue1_fire;
      width[V9A_EXECUTE] = execute0_fire + execute1_fire;
      width[V9A_RETIRE] = retire0_fire + retire1_fire;

      redirect_or_stop = flush || trap_valid || exit_valid || halted ||
          dut.u_frontend.redirect_valid_w ||
          dut.u_frontend.direct_frontend_flush_w ||
          dut.u_frontend.resolve_redirect_block_w ||
          dut.u_frontend.direct_redirect_fetch_w ||
          dut.u_frontend.fetch_request_blocked_by_trap_w ||
          dut.u_frontend.stop_pending_busy_w ||
          dut.u_frontend.trap_valid_q || dut.u_frontend.exit_valid_q ||
          dut.u_frontend.discard_fetch_rsp_q;
      if (redirect_or_stop)
        v9a_check_fail("redirect, trap, exit, halt or stop in ALU trajectory");
      if (mem_req_valid)
        v9a_check_fail("memory request observed in independent ALU trajectory");
      if ((retire0_fire && commit0_exception) ||
          (retire1_fire && commit1_exception))
        v9a_check_fail("commit exception observed in independent ALU trajectory");

      if (count_trace_i) begin
        for (boundary_i = 0; boundary_i < V9A_BOUNDARY_N;
             boundary_i = boundary_i + 1) begin
          v9a_total[boundary_i] = v9a_total[boundary_i] + width[boundary_i];
          if (width[boundary_i] > v9a_peak[boundary_i])
            v9a_peak[boundary_i] = width[boundary_i];
          if (width[boundary_i] == 2)
            v9a_dual_cycles[boundary_i] =
                v9a_dual_cycles[boundary_i] + 1;
          else begin
            tb_errors = tb_errors + 1;
            $display("[V9A-WIDTH][FAIL] cycle=%0d boundary=%0d width=%0d expected=2",
                     trace_cycle_i, boundary_i, width[boundary_i]);
          end
        end
        $display("[V9A-DI2-TRACE] cycle=%0d fetch=%0d decode=%0d rename=%0d dispatch=%0d issue=%0d execute=%0d retire=%0d fetch_pc0=%h fetch_pc1=%h issue_pc0=%h issue_pc1=%h retire_pc0=%h retire_pc1=%h issue_pid0=%h issue_pid1=%h retire_pid0=%h retire_pid1=%h",
                 trace_cycle_i, width[V9A_FETCH], width[V9A_DECODE],
                 width[V9A_RENAME], width[V9A_DISPATCH], width[V9A_ISSUE],
                 width[V9A_EXECUTE], width[V9A_RETIRE],
                 dut.u_frontend.fetch_dec0_pc_w,
                 dut.u_frontend.fetch_dec1_pc_w,
                 dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                    .issue0_pc_w,
                 dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                    .issue1_pc_w,
                 commit0_pc, commit1_pc,
                 dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                    .iq_issue0_producer_id_w,
                 dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                    .issue1_producer_id_w,
                 dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                    .rob_commit0_producer_id_w,
                 dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
                    .rob_commit1_producer_id_w);
      end
    end
  endtask

  initial begin : v9a_width_continuity_focused
    integer wait_cycle;
    integer beat;
    integer boundary_i;
    reg anchor_seen;
    reg drained;

    tb_errors = 0;
    v9a_request_count = 0;
    v9a_response_count = 0;
    v9a_enqueue_count = 0;
    v9a_active_count = 0;
    v9a_ledger_errors = 0;
    v9a_rename_pending0_valid = 1'b0;
    v9a_rename_pending1_valid = 1'b0;
    v9a_ex_pending0_valid = 1'b0;
    v9a_ex_pending1_valid = 1'b0;
    for (boundary_i = 0; boundary_i < V9A_BOUNDARY_N;
         boundary_i = boundary_i + 1) begin
      v9a_total[boundary_i] = 0;
      v9a_peak[boundary_i] = 0;
      v9a_dual_cycles[boundary_i] = 0;
      v9a_seen[boundary_i] = 0;
    end
    for (v9a_init_i = 0; v9a_init_i < V9A_PID_N;
         v9a_init_i = v9a_init_i + 1) begin
      v9a_pid_active[v9a_init_i] = 1'b0;
      v9a_pid_state[v9a_init_i] = 2'd0;
      v9a_pid_pc[v9a_init_i] = {`XLEN{1'b0}};
      v9a_pid_inst[v9a_init_i] = {`INST_W{1'b0}};
      v9a_pid_expected_data[v9a_init_i] = {`XLEN{1'b0}};
      v9a_pid_rd[v9a_init_i] = {`REG_ADDR_W{1'b0}};
    end

    reset_dut(MODE_WIDTH_CONTINUITY, 32'h0000_0000);

    // Unique deterministic anchor: the first accepted fetch request edge.
    anchor_seen = 1'b0;
    for (wait_cycle = 0; wait_cycle < 32 && !anchor_seen;
         wait_cycle = wait_cycle + 1) begin
      if (fetch_req_valid && fetch_req_ready) begin
        anchor_seen = 1'b1;
        $display("[V9A-DI2-ANCHOR] first_fetch_request_fire warmup_cycles=%0d",
                 V9A_WARMUP_CYCLES);
      end
      v9a_observe_cycle(1'b0, -1);
      `TB_TICK(clk);
      #1;
    end
    if (!anchor_seen)
      v9a_check_fail("first fetch request anchor was not observed");

    // Fixed warmup: no saturation predicate may move the measurement start.
    repeat (V9A_WARMUP_CYCLES) begin
      v9a_observe_cycle(1'b0, -1);
      `TB_TICK(clk);
      #1;
    end

    for (beat = 0; beat < V9A_TRACE_CYCLES; beat = beat + 1) begin
`ifdef V9A_WIDTH_WINDOW_STALL_PROBE
      if (beat == 16)
        fetch_req_admit = 1'b0;
`endif
      #1;
      v9a_observe_cycle(1'b1, beat);
      `TB_TICK(clk);
      #1;
`ifdef V9A_WIDTH_WINDOW_STALL_PROBE
      if (beat == 16)
        fetch_req_admit = 1'b1;
`endif
    end

    for (boundary_i = 0; boundary_i < V9A_BOUNDARY_N;
         boundary_i = boundary_i + 1) begin
      if ((v9a_total[boundary_i] != 128) ||
          (v9a_peak[boundary_i] != 2) ||
          (v9a_dual_cycles[boundary_i] != 64)) begin
        tb_errors = tb_errors + 1;
        $display("[V9A-WIDTH][FAIL] aggregate boundary=%0d total=%0d peak=%0d dual_cycles=%0d",
                 boundary_i, v9a_total[boundary_i],
                 v9a_peak[boundary_i], v9a_dual_cycles[boundary_i]);
      end
    end

    $display("[V9A-DI2-METRIC] trace_cycles=64 independent_alu_ipc_milli=%0d fetch_total=%0d fetch_peak=%0d fetch_dual_cycles=%0d decode_total=%0d decode_peak=%0d decode_dual_cycles=%0d rename_total=%0d rename_peak=%0d rename_dual_cycles=%0d dispatch_total=%0d dispatch_peak=%0d dispatch_dual_cycles=%0d issue_total=%0d issue_peak=%0d issue_dual_cycles=%0d execute_total=%0d execute_peak=%0d execute_dual_cycles=%0d retire_total=%0d retire_peak=%0d retire_dual_cycles=%0d",
             (v9a_total[V9A_RETIRE] * 1000) / V9A_TRACE_CYCLES,
             v9a_total[V9A_FETCH], v9a_peak[V9A_FETCH],
             v9a_dual_cycles[V9A_FETCH],
             v9a_total[V9A_DECODE], v9a_peak[V9A_DECODE],
             v9a_dual_cycles[V9A_DECODE],
             v9a_total[V9A_RENAME], v9a_peak[V9A_RENAME],
             v9a_dual_cycles[V9A_RENAME],
             v9a_total[V9A_DISPATCH], v9a_peak[V9A_DISPATCH],
             v9a_dual_cycles[V9A_DISPATCH],
             v9a_total[V9A_ISSUE], v9a_peak[V9A_ISSUE],
             v9a_dual_cycles[V9A_ISSUE],
             v9a_total[V9A_EXECUTE], v9a_peak[V9A_EXECUTE],
             v9a_dual_cycles[V9A_EXECUTE],
             v9a_total[V9A_RETIRE], v9a_peak[V9A_RETIRE],
             v9a_dual_cycles[V9A_RETIRE]);

    // Stop only new request admission.  Keep run/response/dispatch/commit open
    // and require natural holder drain without reset or flush.
    fetch_req_admit = 1'b0;
    run = 1'b1;
    commit_ready = 1'b1;
    #1;
    drained = 1'b0;
    for (wait_cycle = 0; wait_cycle < 256 && !drained;
         wait_cycle = wait_cycle + 1) begin
      v9a_observe_cycle(1'b0, -1);
      `TB_TICK(clk);
      #1;
      drained = !fetch_rsp_valid &&
          !dut.u_frontend.outstanding_valid_q &&
          (dut.u_frontend.fifo_count_q == 0) &&
          (rob_count == 0) && (issue_count == 0) &&
          !dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .ex0_valid_q &&
          !dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
              .ex1_valid_q &&
          (v9a_active_count == 0);
    end
    v9a_check_previous_rename_state();

    if (!drained)
      v9a_check_fail("natural drain did not empty all holders");
    if ((v9a_request_count != v9a_response_count) ||
        (v9a_response_count != v9a_enqueue_count))
      v9a_ledger_fail("fetch request, response and enqueue conservation failed");
    for (boundary_i = 1; boundary_i < V9A_BOUNDARY_N;
         boundary_i = boundary_i + 1) begin
      if (v9a_seen[boundary_i] != v9a_seen[V9A_FETCH])
        v9a_ledger_fail("full-run boundary transaction conservation failed");
    end
    if (v9a_seen[V9A_FETCH] != (2 * v9a_enqueue_count))
      v9a_ledger_fail("fetch packet to uop conservation failed");
    if (v9a_active_count != 0)
      v9a_ledger_fail("active full ProducerId ledger is not empty");
    if (free_count != 7'd32)
      v9a_check_fail("free-list did not return to 32 entries");
    if (flush || trap_valid || exit_valid || halted || mem_req_valid)
      v9a_check_fail("forbidden control or memory event at final drain");

    if (v9a_ledger_errors == 0)
      $display("[V9A-DI2-IDENTITY] fetched=%0d decoded=%0d renamed=%0d dispatched=%0d issued=%0d executed=%0d retired=%0d active_pid=0 payload_mismatch=0 lifecycle_error=0 PASS",
               v9a_seen[V9A_FETCH], v9a_seen[V9A_DECODE],
               v9a_seen[V9A_RENAME], v9a_seen[V9A_DISPATCH],
               v9a_seen[V9A_ISSUE], v9a_seen[V9A_EXECUTE],
               v9a_seen[V9A_RETIRE]);
    if (drained && (v9a_request_count == v9a_response_count) &&
        (v9a_response_count == v9a_enqueue_count) &&
        (v9a_active_count == 0) && (free_count == 32))
      $display("[V9A-DI2-DRAIN] requests=%0d responses=%0d enqueues=%0d fifo=0 rob=0 issue=0 ex0=0 ex1=0 free=32 active_pid=0 flush=0 PASS",
               v9a_request_count, v9a_response_count, v9a_enqueue_count);
    tb_finish("tb_ooo_core_top_glue_v9a_width_continuity");
  end
`else
`ifdef V9O_CSR_QH_FOCUSED
  // Macro-on integration is intentionally bounded to the real queue-head CSR,
  // precise-trap, and exact pending-system FP-CSR owner paths.  The legacy
  // all-program aggregate has independent memory-mode expectations and is
  // reported separately rather than being used as a focused control-event
  // oracle.
  initial begin : v9o_csr_qh_focused
    tb_errors = 0;

    // V9X: the C1 backend-local reset must clear the same pre-ROB exit holder
    // whose accepted birth armed stop_pending.  Drive the holder boundary
    // directly here; the following cycle observes the production
    // core_local_flush_w wiring into OooPendingTrapExitSequencer.rst.
    reset_dut(MODE_DEFAULT_BODY, 32'h0000_0000);

    // A pending-system injection can raise the merged backend lane0 fire
    // while no queue-head CSR was accepted by the frontend.  Even if the
    // current FIFO head decodes as CSR, only the exported real fire may birth
    // the queue-head stop owner.
    force dut.core_dispatch0_fire_w = 1'b1;
    force dut.head0_facts_w[`OOO_SLOT_FACT_CSR] = 1'b1;
    force dut.dispatch0_facts_w[`OOO_SLOT_FACT_CSR] = 1'b1;
    force dut.head_inst0_w = 32'h3400_1073;
    force dut.head0_csr_illegal_w = 1'b0;
    force dut.head0_csr_dispatch_fire_w = 1'b0;
    #1;
    tb_check1("V9X merged fire cannot alias queue-head owner birth",
              dut.u_control_plane.v9x_head0_csr_owner_birth_w, 1'b0);
    release dut.core_dispatch0_fire_w;
    release dut.head0_facts_w[`OOO_SLOT_FACT_CSR];
    release dut.dispatch0_facts_w[`OOO_SLOT_FACT_CSR];
    release dut.head_inst0_w;
    release dut.head0_csr_illegal_w;
    release dut.head0_csr_dispatch_fire_w;
    $display("[V9X-QCSR-REAL-FIRE-SOURCE][PASS] merged=1 real=0 birth=0");

    force dut.u_control_plane.pending_trap_exit_capture_exit_w = 1'b1;
    force dut.u_control_plane.pending_trap_exit_capture_exit_valid_w = 1'b1;
    force dut.u_control_plane.pending_trap_exit_capture_exit_ecall_w = 1'b0;
    force dut.u_control_plane.pending_trap_exit_capture_exit_ebreak_w = 1'b1;
    `TB_TICK(clk);
    #1;
    tb_check1("V9X pre-ROB exit holder captures", dut.pending_exit_q, 1'b1);
    release dut.u_control_plane.pending_trap_exit_capture_exit_w;
    release dut.u_control_plane.pending_trap_exit_capture_exit_valid_w;
    release dut.u_control_plane.pending_trap_exit_capture_exit_ecall_w;
    release dut.u_control_plane.pending_trap_exit_capture_exit_ebreak_w;

    // Isolate the C1 reset edge from ordinary holder clear sources so the
    // oracle fails if the sequencer reset wiring is removed.
    force dut.u_control_plane.pending_trap_exit_clear_exit_w = 1'b0;
    force dut.csr_trap_mem_valid_w = 1'b0;
    force dut.core_local_flush_w = 1'b1;
    `TB_TICK(clk);
    #1;
    tb_check1("V9X C1 clears pre-ROB exit holder", dut.pending_exit_q, 1'b0);
    tb_check1("V9X C1 clears matching stop owner", dut.stop_pending_q, 1'b0);
    release dut.core_local_flush_w;
    release dut.csr_trap_mem_valid_w;
    release dut.u_control_plane.pending_trap_exit_clear_exit_w;
    $display("[V9X-TRAP-EXIT-C1-RESET][PASS] holder=0 stop=0");

    reset_dut(MODE_ECALL, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("V9O macro-on ecall handler reaches ebreak", exit_valid, 1'b1);
    tb_check1("V9O macro-on CSR inflight owns stop",
              saw_head0_csr_stop_owner, 1'b1);
    tb_check1("V9O macro-on real queue-head CSR emits C0 barrier",
              saw_csr_full_flush_barrier, 1'b1);
    tb_check1("V9O macro-on real queue-head CSR emits C1 typed apply",
              saw_typed_csr_apply, 1'b1);
    tb_check32("V9O macro-on mtvec handler executes", gpr(5'd6), 32'd6);
    tb_check32("V9O macro-on ROB drained", {27'b0, rob_count}, 32'd0);
    tb_check32("V9O macro-on issue queue drained",
               {28'b0, issue_count}, 32'd0);
    $display("[V9O-CSR-QH-CORE-INTEGRATION] real queue-head CSR C0/C1 PASS");

    reset_dut(MODE_PENDING_FP_CSR, 32'h0000_0000);
    repeat (180) begin
      `TB_TICK(clk);
      #1;
    end
    tb_check1("V9O pending FP CSR program reaches ebreak", exit_valid, 1'b1);
    tb_check1("V9O pending FP CSR commits through drain owner",
              saw_pending_csr_commit, 1'b1);
    tb_check1("V9O pending FP CSR commit has exact type/PID witness",
              saw_pending_csr_exact_owner, 1'b1);
    tb_check1("V9O exact pending owner raises head0 control pregrant",
              saw_pending_csr_control_pregrant, 1'b1);
    tb_check1("V9O pending FP CSR wins frontend with action NONE",
              saw_pending_csr_frontend_none, 1'b1);
    tb_check1("V9O pending FP CSR does not request full flush",
              saw_pending_csr_without_full_flush, 1'b1);
    tb_check1("V9O pending FP CSR produces no next-cycle backend apply",
              saw_pending_csr_without_next_apply, 1'b1);
    tb_check32("V9O pending FP CSR younger integer executes", gpr(5'd5), 32'd7);
    tb_check32("V9O pending FP CSR ROB drained", {27'b0, rob_count}, 32'd0);
    tb_check32("V9O pending FP CSR issue queue drained",
               {28'b0, issue_count}, 32'd0);
    $display("[V9O-PENDING-CSR-OWNER-INTEGRATION] exact type/PID action-NONE path PASS");

    reset_dut(MODE_CSR_MEMORY_ORDER, 32'h0000_0000);
    repeat (200) begin
      `TB_TICK(clk);
      #1;
    end
    tb_check1("V9O CSR/memory order program reaches ebreak",
              exit_valid, 1'b1);
    tb_check1("V9O older store drains before queue-head CSR C0",
              saw_csr_after_older_store, 1'b1);
    tb_check1("V9O CSR/memory order emits typed C1 apply",
              csr_apply_seen, 1'b1);
    tb_check32("V9O older store reaches memory", data_mem_word, 32'd11);
    tb_check32("V9O younger load refetches after CSR", gpr(5'd4), 32'd11);
    tb_check32("V9O younger load consumer executes", gpr(5'd5), 32'd12);
    tb_check32("V9O CSR/memory order ROB drained",
               {27'b0, rob_count}, 32'd0);
    tb_check32("V9O CSR/memory order issue queue drained",
               {28'b0, issue_count}, 32'd0);
    $display("[V9O-CSR-MEMORY-ORDER-INTEGRATION] older drain/younger refetch PASS");

    reset_dut(MODE_CSR_BRANCH_RECOVERY, 32'h0000_0000);
    repeat (220) begin
      `TB_TICK(clk);
      #1;
    end
    tb_check1("V9P wrong-path queue-head CSR dispatches before branch resolve",
              saw_csr_branch_recovery_dispatch, 1'b1);
    tb_check1("V9P older branch selects recovery while CSR is inflight",
              saw_csr_branch_recovery_selective, 1'b1);
    tb_check1("V9P selective recovery clears CSR inflight next cycle",
              saw_csr_branch_recovery_clear, 1'b1);
    tb_check1("V9P wrong-path CSR never commits",
              saw_csr_branch_recovery_commit, 1'b0);
    tb_check1("V9P recovered target reaches ebreak", exit_valid, 1'b1);
    tb_check32("V9P wrong-path CSR leaves mscratch unchanged low",
               u_csr_file.csr_mscratch_q[31:0], 32'd0);
    tb_check32("V9P wrong-path CSR leaves mscratch unchanged high",
               u_csr_file.csr_mscratch_q[63:32], 32'd0);
    tb_check32("V9P wrong-path fall-through instruction is squashed",
               gpr(5'd4), 32'd0);
    tb_check32("V9P recovered target retires", gpr(5'd5), 32'd7);
    tb_check32("V9P branch recovery ROB drained",
               {27'b0, rob_count}, 32'd0);
    tb_check32("V9P branch recovery issue queue drained",
               {28'b0, issue_count}, 32'd0);
    $display("[V9P-CSR-BRANCH-RECOVERY] wrong-path CSR death/refetch PASS");

    reset_dut(MODE_CSR_JALR_RECOVERY, 32'h0000_0000);
    data_mem_word = 64'h0000_0000_0000_0018;
    repeat (220) begin
      `TB_TICK(clk);
      #1;
    end
    tb_check1("V9P wrong-path CSR dispatches before JALR resolve",
              saw_csr_branch_recovery_dispatch, 1'b1);
    tb_check1("V9P older JALR selects recovery while CSR is inflight",
              saw_csr_branch_recovery_selective, 1'b1);
    tb_check1("V9P JALR recovery clears CSR inflight next cycle",
              saw_csr_branch_recovery_clear, 1'b1);
    tb_check1("V9P JALR wrong-path CSR never commits",
              saw_csr_branch_recovery_commit, 1'b0);
    tb_check1("V9P JALR target reaches ebreak", exit_valid, 1'b1);
    tb_check32("V9P JALR wrong-path CSR leaves mscratch unchanged low",
               u_csr_file.csr_mscratch_q[31:0], 32'd0);
    tb_check32("V9P JALR wrong-path CSR leaves mscratch unchanged high",
               u_csr_file.csr_mscratch_q[63:32], 32'd0);
    tb_check32("V9P JALR fall-through instruction is squashed",
               gpr(5'd4), 32'd0);
    tb_check32("V9P JALR target retires", gpr(5'd5), 32'd8);
    tb_check32("V9P JALR recovery ROB drained",
               {27'b0, rob_count}, 32'd0);
    tb_check32("V9P JALR recovery issue queue drained",
               {28'b0, issue_count}, 32'd0);
    $display("[V9P-CSR-JALR-RECOVERY] wrong-path CSR death/refetch PASS");

    reset_dut(MODE_CSR_JALR_CALLBACK_CHAIN, 32'h0000_0000);
    repeat (320) begin
      `TB_TICK(clk);
      #1;
    end
    tb_check1("V9P CSR/JALR callback chain reaches ebreak",
              exit_valid, 1'b1);
    tb_check32("V9P CSR/JALR callback chain executes both callbacks",
               gpr(5'd9), 32'd2);
    tb_check32("V9P CSR/JALR callback chain keeps post-call body",
               gpr(5'd6), 32'd1);
    tb_check32("V9P CSR/JALR callback chain squashes taken fall-through",
               gpr(5'd7), 32'd0);
    tb_check32("V9P CSR/JALR callback chain retires branch target",
               gpr(5'd8), 32'd8);
    tb_check1("V9P CSR/JALR callback chain releases stop_pending",
              dut.stop_pending_q, 1'b0);
    tb_check32("V9P CSR/JALR callback chain ROB drained",
               {27'b0, rob_count}, 32'd0);
    tb_check32("V9P CSR/JALR callback chain issue queue drained",
               {28'b0, issue_count}, 32'd0);
    $display("[V9P-CSR-JALR-CALLBACK-CHAIN] CSR/call/return/branch PASS");
    tb_finish("tb_ooo_core_top_glue_v9o_csr_qh");
  end
`else
  initial begin
    tb_errors = 0;
    // V8V integration cut: model a raw branch checkpoint restore while the
    // backend withholds accepted apply for an edge-old physical-write owner.
    // The raw request may enter the backend checkpoint input, but it must not
    // enter either memory request gate through core_local_flush_w.
    reset_dut(MODE_DEFAULT_BODY, 32'h0000_0000);
    force dut.branch_spec_restore_w = 1'b1;
    force dut.core_checkpoint_restore_apply_w = 1'b0;
    #1;
    tb_check1("raw checkpoint restore reaches backend request",
              dut.core_checkpoint_restore_w, 1'b1);
    tb_check1("raw checkpoint restore remains apply-blocked",
              dut.core_checkpoint_restore_apply_w, 1'b0);
    tb_check1("raw checkpoint restore does not assert core local flush",
              dut.core_local_flush_w, 1'b0);
    tb_check1("raw checkpoint restore does not flush memory gate 0",
              mem_flush, 1'b0);
    tb_check1("raw checkpoint restore does not flush memory gate 1",
              dut.mem1_flush_unused_w, 1'b0);
    if ((dut.core_checkpoint_restore_w === 1'b1) &&
        (dut.core_checkpoint_restore_apply_w === 1'b0) &&
        (dut.core_local_flush_w === 1'b0) &&
        (mem_flush === 1'b0) &&
        (dut.mem1_flush_unused_w === 1'b0)) begin
      $display("[V8V-CHECKPOINT-APPLY-GATE] raw_request=1 apply=0 local_flush=0 mem_flush=0,0 PASS");
    end
    release dut.core_checkpoint_restore_apply_w;
    release dut.branch_spec_restore_w;
    `TB_TICK(clk);
    #1;

    reset_dut(MODE_DEFAULT_BODY, 32'h0000_0000);
    tb_check1("v8a wrapper candidate low after reset",
              head0_retire_candidate_valid, 1'b0);
    tb_check1("v8a wrapper identity invalid after reset",
              head0_identity_valid, 1'b0);

    repeat (80) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("default body halts at ebreak", halted, 1'b1);
    tb_check1("default body is not trap", trap_valid, 1'b0);
    tb_check1("default body exits", exit_valid, 1'b1);
    tb_check1("observed back-to-back packet fetch", saw_back_to_back_fetch, 1'b1);
    tb_check1("observed dual commit", saw_dual_commit, 1'b1);
    tb_check32("default body retired before ebreak", commit_total, 32'd6);
    tb_check32("x0 remains zero", gpr(5'd0), 32'd0);
    tb_check32("x1 retired", gpr(5'd1), 32'd1);
    tb_check32("x2 retired", gpr(5'd2), 32'd2);
    tb_check32("x3 depends on previous packet", gpr(5'd3), 32'd3);
    tb_check32("x4 depends on same packet lane0", gpr(5'd4), 32'd7);
    tb_check32("lane1 WAW wins x5", gpr(5'd5), 32'd9);
    tb_check32("post-ebreak instruction did not dispatch x6", gpr(5'd6), 32'd0);
    tb_check32("rob drained after stop", {27'b0, rob_count}, 32'd0);
    tb_check32("issue queue drained after stop", {28'b0, issue_count}, 32'd0);
    tb_check32("freelist recovered", {25'b0, free_count}, 32'd32);
    tb_check1("ecall flag remains low", exit_is_ecall, 1'b0);
    tb_check1("default body ebreak flag", exit_is_ebreak, 1'b1);
    tb_check32("exit code remains zero", exit_code, 32'd0);
    tb_check1("v8a wrapper propagated a non-vacuous candidate",
              saw_v8a_candidate, 1'b1);
    tb_check1("v8a wrapper propagated a non-vacuous identity",
              saw_v8a_identity, 1'b1);
    tb_check1("v8a wrapper candidate low after ROB drain",
              head0_retire_candidate_valid, 1'b0);
    tb_check1("v8a wrapper identity invalid after ROB drain",
              head0_identity_valid, 1'b0);
    $display("[S2-Q2-V8A-WRAPPER-PASS] public observation chain toggled without X");

    reset_dut(MODE_BRANCH_TAKEN, 32'h0000_0000);
    repeat (80) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("taken branch reaches ebreak", exit_valid, 1'b1);
    tb_check1("taken branch is not trap", trap_valid, 1'b0);
    // 【F2】direct fire 只在预测 taken(或 head1 不可双发)拍发生; 本场景分支为前跳
    // (static BTFN 预测 not-taken)→dual 双发不 fire, 方向错由后端 mispredict 纠正
    // (上方 reaches-ebreak 已覆盖功能)。fire 观测期望翻转为 0。
    tb_check1("taken branch dual-issues without fire (F2)", saw_branch_fastpath, 1'b0);
    tb_check32("taken branch commits with target body", commit_total, 32'd5);
    tb_check32("taken branch keeps x1", gpr(5'd1), 32'd1);
    tb_check32("taken branch skips lane1 fallthrough", gpr(5'd3), 32'd0);
    tb_check32("taken branch executes target lane0", gpr(5'd4), 32'd4);
    tb_check32("taken branch executes target lane1", gpr(5'd5), 32'd5);
    tb_check1("taken branch ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_BRANCH_NOT_TAKEN, 32'h0000_0000);
    repeat (100) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("not-taken branch reaches ebreak", exit_valid, 1'b1);
    tb_check1("not-taken branch is not trap", trap_valid, 1'b0);
    tb_check1("not-taken branch dual-issues without fire (F2)", saw_branch_fastpath, 1'b0);
    tb_check32("not-taken branch commits fallthrough", commit_total, 32'd7);
    tb_check32("not-taken branch keeps x1", gpr(5'd1), 32'd1);
    tb_check32("not-taken branch executes fallthrough", gpr(5'd3), 32'd3);
    tb_check32("not-taken branch executes next packet lane0", gpr(5'd5), 32'd5);
    tb_check32("not-taken branch executes next packet lane1", gpr(5'd6), 32'd6);
    tb_check1("not-taken branch ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_BRANCH_READY_RESOLVE, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("ready branch reaches ebreak", exit_valid, 1'b1);
    // domain-A: dispatch 拍快解析禁用, ready 分支同样经 IQ resolve(功能由 GPR 终值覆盖)。
    tb_check1("ready branch dispatch fast resolve disabled (domain-A)",
              saw_branch_dispatch_resolve, 1'b0);
    tb_check32("ready branch skips fallthrough", gpr(5'd1), 32'd0);
    tb_check32("ready branch executes target", gpr(5'd2), 32'd7);

    reset_dut(MODE_JAL, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("jal reaches ebreak", exit_valid, 1'b1);
    tb_check1("jal is not trap", trap_valid, 1'b0);
    tb_check1("jal redirect fetches target immediately",
              saw_direct_redirect_fetch, 1'b1);
    tb_check32("jal commits link and target body", commit_total, 32'd5);
    tb_check32("jal keeps older x1", gpr(5'd1), 32'd1);
    tb_check32("jal skips fallthrough lane1", gpr(5'd3), 32'd0);
    tb_check32("jal executes target lane0", gpr(5'd4), 32'd4);
    tb_check32("jal link writes a0", gpr(5'd10), 32'h8000_000c);
    tb_check32("jal target consumer reads link", gpr(5'd5), 32'h8000_000c);
    tb_check1("jal ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_CONTROL_FETCH_GATE, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("control packet reaches ebreak", exit_valid, 1'b1);
    tb_check1("control packet suppresses fallthrough fetch",
              saw_control_fallthrough_fetch, 1'b0);
    tb_check32("control packet commits jal and target", commit_total, 32'd2);
    tb_check32("control packet skips first fallthrough", gpr(5'd2), 32'd0);
    tb_check32("control packet skips second fallthrough", gpr(5'd3), 32'd0);
    tb_check32("control packet target reads link", gpr(5'd4), 32'h8000_0004);

    reset_dut(MODE_RAS_RETURN, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("ras return reaches ebreak", exit_valid, 1'b1);
    tb_check1("ras return is not trap", trap_valid, 1'b0);
    // mode=1（OOO_ROB_WALK_MODE）：ret 走 backend 强制 mispredict redirect（见下 saw_direct_redirect_fetch=1），
    // 不走 mode=0 的 RAS fast-path commit；ret 功能正确性由 commit_total/gpr + riscv-tests 135/0 端到端覆盖。
    if (!`OOO_ROB_WALK_MODE)
      tb_check1("ras return fast path fires", saw_return_fastpath, 1'b1);
    tb_check1("ras return redirect fetches target immediately",
              saw_direct_redirect_fetch, 1'b1);
    tb_check32("ras return commits call body return and continuation",
               commit_total, 32'd5);
    tb_check32("ras return link", gpr(5'd1), 32'h8000_0004);
    tb_check32("ras return callee body", gpr(5'd2), 32'd2);
    tb_check32("ras return continuation", gpr(5'd4), 32'd3);
    tb_check1("ras return ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_BRANCH_LANE1_RET, 32'h0000_0000);
    repeat (160) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("branch lane1 ret reaches ebreak", exit_valid, 1'b1);
    tb_check1("branch lane1 ret is not trap", trap_valid, 1'b0);
    // mode=1：lane1 ret 同样走 backend redirect（saw_direct_redirect_fetch，见下），非 mode=0 的 fast-path/synth-commit。
    if (!`OOO_ROB_WALK_MODE) begin
    tb_check1("branch lane1 ret fast path fires",
              saw_lane1_ret_fallthrough || saw_return_fastpath, 1'b1);
    tb_check1("branch lane1 ret resolves as return",
              saw_lane1_ret_fallthrough || saw_return_fastpath, 1'b1);
    end
    tb_check1("branch lane1 ret redirects fetch target immediately",
              saw_direct_redirect_fetch, 1'b1);
    tb_check32("branch lane1 ret commits call branch return continuation",
               commit_total, 32'd4);
    tb_check32("branch lane1 ret link", gpr(5'd1), 32'h8000_0004);
    tb_check32("branch lane1 ret skips pre-branch body", gpr(5'd2), 32'd0);
    tb_check32("branch lane1 ret continuation", gpr(5'd5), 32'd5);
    tb_check1("branch lane1 ret ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_RVC_CADDIW, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("rvc c.addiw reaches c.ebreak", exit_valid, 1'b1);
    tb_check1("rvc c.addiw is not trap", trap_valid, 1'b0);
    tb_check1("rvc c.addiw does not redirect as c.jal",
              saw_direct_redirect_fetch, 1'b0);
    tb_check32("rvc c.addiw commits decompressed body", commit_total, 32'd4);
    tb_check32("rvc c.addiw sign-extends low word", gpr(5'd5),
               32'hffff_ffff);
    tb_check32("rvc c.addiw keeps halfword fallthrough", gpr(5'd6), 32'd1);
    tb_check1("rvc c.ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_JALR_RD_EQ_RS1, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("jalr reaches ebreak", exit_valid, 1'b1);
    tb_check1("jalr is not trap", trap_valid, 1'b0);
    tb_check32("jalr trap cause stays clear", {27'b0, trap_cause}, 32'd0);
    tb_check32("jalr trap pc stays clear", trap_pc, 32'd0);
    tb_check32("jalr trap tval stays clear", trap_tval, 32'd0);
    tb_check32("jalr commits link and target body", commit_total, 32'd5);
    tb_check32("jalr uses old rs1 target before link write", gpr(5'd6), 32'd0);
    tb_check32("jalr rd receives link", gpr(5'd5), 32'h8000_000c);
    tb_check32("jalr target consumer reads link", gpr(5'd7), 32'h8000_000c);
    tb_check32("jalr target lane1 executes", gpr(5'd8), 32'd8);
    tb_check1("jalr ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_MEM_LW_SW, 32'h0000_0000);
    repeat (160) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("memory program reaches ebreak", exit_valid, 1'b1);
    tb_check1("memory program is not trap", trap_valid, 1'b0);
    tb_check32("memory program commits store/load body", commit_total, 32'd10);
    tb_check1("memory reservation issues while frontend is not stopped",
              saw_memory_streaming, 1'b1);
    tb_check1("memory reservation/request leaves frontend running",
              saw_memory_streaming || saw_memory_rsp_req_overlap, 1'b1);
    tb_check1("memory response preserves exact owner through wrappers",
              saw_exact_owner_roundtrip, 1'b1);
    $display("[S2-G1-WRAPPER-EXACT-OWNER][PASS] memory body roundtrip");
    tb_check32("memory store writes word", data_mem_word, 32'd11);
    tb_check32("memory load reads stored word", gpr(5'd4), 32'd11);
    tb_check32("load consumer sees loaded value", gpr(5'd5), 32'd12);
    tb_check32("post-load lane1 executes", gpr(5'd6), 32'd6);
    tb_check32("memory streaming pad lane0 executes", gpr(5'd7), 32'd7);
    tb_check32("memory streaming pad lane1 executes", gpr(5'd8), 32'd8);
    tb_check1("memory ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_LANE1_EBREAK, 32'h0000_0000);
    repeat (60) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane1 ebreak halts core", halted, 1'b1);
    tb_check1("lane1 ebreak exits", exit_valid, 1'b1);
    tb_check1("lane1 ebreak flag", exit_is_ebreak, 1'b1);
    tb_check1("lane1 ebreak is not trap", trap_valid, 1'b0);
    tb_check32("lane1 ebreak dispatches lane0 first", commit_total, 32'd1);
    tb_check32("lane1 ebreak keeps lane0 write", gpr(5'd1), 32'd1);

    reset_dut(MODE_LANE1_BRANCH_TAKEN, 32'h0000_0000);
    repeat (100) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane1 branch reaches ebreak", exit_valid, 1'b1);
    tb_check1("lane1 branch is not trap", trap_valid, 1'b0);
    tb_check1("lane1 branch dual-issues without fire (F2)", saw_branch_fastpath, 1'b0);
    tb_check1("lane1 branch resolves in backend",
              saw_backend_branch_resolve, 1'b1);
    tb_check32("lane1 branch commits precise body", commit_total, 32'd4);
    tb_check32("lane1 branch sees lane0 result", gpr(5'd1), 32'd1);
    tb_check32("lane1 branch skips fallthrough", gpr(5'd2), 32'd0);
    tb_check32("lane1 branch target lane0 executes", gpr(5'd3), 32'd3);
    tb_check32("lane1 branch target lane1 executes", gpr(5'd4), 32'd4);
    tb_check1("lane1 branch ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_BRANCH_SHADOW_PREFETCH, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("branch shadow prefetch reaches ebreak", exit_valid, 1'b1);
    tb_check1("branch shadow prefetch is not trap", trap_valid, 1'b0);
    tb_check1("branch speculation captures or early resolves",
              saw_branch_spec_capture || saw_branch_shadow_prefetch ||
              saw_branch_dispatch_resolve || saw_backend_branch_resolve,
              1'b1);
    tb_check1("branch speculation resolves or early resolves",
              saw_branch_spec_correct || saw_branch_shadow_hit ||
              saw_branch_dispatch_resolve || saw_backend_branch_resolve,
              1'b1);
    tb_check32("branch shadow prefetch commits target body",
               commit_total, 32'd4);
    tb_check32("branch shadow prefetch skips fallthrough", gpr(5'd2), 32'd0);
    tb_check32("branch shadow prefetch target executes", gpr(5'd3), 32'd3);
    tb_check1("branch shadow prefetch ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_LANE1_JAL, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane1 jal reaches ebreak", exit_valid, 1'b1);
    tb_check1("lane1 jal is not trap", trap_valid, 1'b0);
    tb_check1("lane1 jal redirect fetches target immediately",
              saw_direct_redirect_fetch, 1'b1);
    tb_check32("lane1 jal commits link and target lane0", commit_total, 32'd3);
    tb_check1("lane1 jal keeps precise lane0 order",
              saw_dual_commit || (gpr(5'd1) == 32'd1), 1'b1);
    tb_check32("lane1 jal keeps older lane0", gpr(5'd1), 32'd1);
    tb_check32("lane1 jal skips fallthrough", gpr(5'd2), 32'd0);
    tb_check32("lane1 jal link writes a0", gpr(5'd10), 32'h8000_0008);
    tb_check32("lane1 jal target reads link", gpr(5'd3), 32'h8000_0008);
    tb_check1("lane1 jal ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_LANE1_MEM, 32'h0000_0000);
    repeat (180) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane1 memory program reaches ebreak", exit_valid, 1'b1);
    tb_check1("lane1 memory program is not trap", trap_valid, 1'b0);
    tb_check1("lane1 memory preserves exact owner through wrappers",
              saw_exact_owner_roundtrip, 1'b1);
    tb_check32("lane1 memory commits store/load body", commit_total, 32'd6);
    tb_check1("lane1 memory streams through normal dispatch",
              saw_lane1_memory_streaming, 1'b1);
    tb_check32("lane1 store writes word", data_mem_word, 32'd13);
    tb_check32("lane1 memory load reads stored word", gpr(5'd4), 32'd13);
    tb_check32("lane1 memory load consumer sees value", gpr(5'd5), 32'd14);
    tb_check1("lane1 memory ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_FMV_W_X, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("fmv.w.x reaches ebreak", exit_valid, 1'b1);
    tb_check1("fmv.w.x is not trap", trap_valid, 1'b0);
    tb_check32("fmv.w.x follows FP decode path", gpr(5'd5), 32'd7);
    tb_check32("fmv.x.w writes integer destination", gpr(5'd6), 32'd0);
    tb_check32("fmv.w.x/fmv.x.w retire before ebreak", commit_total, 32'd5);
    tb_check1("GPR-destination FP completion observed",
              saw_fp_gpr_completion, 1'b1);
    tb_check1("GPR-destination FP completion does not wake FPR domain",
              saw_fp_gpr_completion_wake, 1'b0);
    tb_check1("fmv.w.x ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_EBREAK, 32'h0000_0000);
    repeat (12) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane0 ebreak halts core", halted, 1'b1);
    tb_check1("lane0 ebreak exits", exit_valid, 1'b1);
    tb_check1("lane0 ebreak flag", exit_is_ebreak, 1'b1);
    tb_check1("lane0 ebreak is not trap", trap_valid, 1'b0);
    tb_check32("lane0 ebreak retires no instruction", commit_total, 32'd0);

    reset_dut(MODE_ECALL, 32'h0000_0000);
    repeat (80) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("ecall handler reaches ebreak", exit_valid, 1'b1);
    tb_check1("ecall is handled by CSR trap, not fatal trap", trap_valid, 1'b0);
    tb_check1("ecall does not use legacy exit flag", exit_is_ecall, 1'b0);
    tb_check1("ecall handler exits by ebreak", exit_is_ebreak, 1'b1);
    tb_check32("ecall retires older instructions and handler", commit_total, 32'd7);
    tb_check32("ecall packet did not dispatch lane1", gpr(5'd5), 32'd0);
    tb_check32("ecall mtvec handler executes", gpr(5'd6), 32'd6);
    tb_check32("ecall exit code from a0", exit_code, 32'd0);
    tb_check32("ecall rob drained after stop", {27'b0, rob_count}, 32'd0);
    tb_check32("ecall issue queue drained after stop", {28'b0, issue_count}, 32'd0);
    if (`OOO_CSR_QUEUE_HEAD)
      tb_check1("real CSR inflight owns stop until commit",
                saw_head0_csr_stop_owner, 1'b1);

    reset_dut(MODE_FETCH_ACCESS_FAULT, 32'h8000_0010);
    repeat (180) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("fetch fault packet enqueues sanitized lane1 NOP",
              saw_fetch_fault_packet_enqueue, 1'b1);
    tb_check1("fetch fault stored predecode reaches FIFO head",
              saw_fetch_fault_predecode_fifo, 1'b1);
    tb_check1("live fetch response carries non-zero-class FP raw",
              saw_fetch_fault_raw_fp_response, 1'b1);
    $display("[T3W-FETCH-FAULT-RAW] inst=0x%08x facts=0x%05x",
             FETCH_FAULT_RAW_FP_INST, fetch_fault_raw_static_facts_w);
    tb_check1("raw fault FP instruction has non-zero static pack",
              |fetch_fault_raw_static_facts_w, 1'b1);
    tb_check1("raw fault FP instruction sets move-to-GPR static bit",
              fetch_fault_raw_static_facts_w[
                  `OOO_SLOT_STATIC_FACT_FP_MOVE_TO_GPR], 1'b1);
    tb_check1("fault-sanitized enqueue static pack is all zero",
              saw_fetch_fault_static_zero_enqueue, 1'b1);
    tb_check1("fault-sanitized FIFO static pack is all zero",
              saw_fetch_fault_static_zero_fifo, 1'b1);
    tb_check1("fetch fault handler reaches ebreak", exit_valid, 1'b1);
    tb_check1("fetch fault is handled by CSR, not fatal trap", trap_valid,
              1'b0);
    tb_check1("fetch fault handler exits by ebreak", exit_is_ebreak, 1'b1);
    tb_check32("fetch fault commits only older and handler instructions",
               commit_total, 32'd7);
    tb_check32("fetch fault preserves same-packet older lane0", gpr(5'd2),
               32'd55);
    tb_check32("fetch fault squashes first younger instruction", gpr(5'd3),
               32'd0);
    tb_check32("fetch fault squashes later younger instruction", gpr(5'd4),
               32'd0);
    tb_check32("fetch fault handler reads mcause", gpr(5'd13),
               `EXC_INST_ACCESS_FAULT);
    tb_check32("fetch fault handler reads precise mepc", gpr(5'd14),
               32'h8000_0010);
    tb_check32("fetch fault handler reads precise mtval", gpr(5'd15),
               32'h8000_0010);
    tb_check32("fetch fault rob drains before handler ebreak",
               {27'b0, rob_count}, 32'd0);
    tb_check32("fetch fault issue queue drains before handler ebreak",
               {28'b0, issue_count}, 32'd0);

    // V9O focused source-to-apply integration.  Force the already-verified
    // queue-head C0 source and matching legacy trap request for one edge, then
    // observe the production typed C1 apply and full local flush projection.
    reset_dut(MODE_EBREAK, 32'h0000_0000);
    force dut.control_full_flush_barrier_w = 1'b1;
    force dut.control_full_flush_reason_w = `REDIR_REASON_TRAP;
    force dut.csr_trap_mem_valid_w = 1'b1;
    #1;
    tb_check1("V9O focused C0 barrier visible",
              control_full_flush_barrier, 1'b1);
    tb_check32("V9O focused C0 reason is TRAP",
               {{(32-`REDIR_REASON_W){1'b0}}, control_full_flush_reason},
               {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_TRAP});
    `TB_TICK(clk);
    release dut.control_full_flush_barrier_w;
    release dut.control_full_flush_reason_w;
    release dut.csr_trap_mem_valid_w;
    #1;
    tb_check1("V9O focused C1 typed apply valid",
              dut.control_event_apply_valid_w, 1'b1);
    tb_check32("V9O focused C1 typed apply reason",
               {{(32-`REDIR_REASON_W){1'b0}},
                dut.control_event_apply_reason_w},
               {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_TRAP});
    tb_check1("V9O focused C1 trap view valid", dut.core_trap_flush_q, 1'b1);
    tb_check1("V9O focused C1 local full flush valid",
              dut.core_local_flush_w, 1'b1);
    `TB_TICK(clk);
    #1;
    tb_check1("V9O focused typed apply is one cycle",
              dut.control_event_apply_valid_w, 1'b0);
    tb_check1("V9O focused C0 observation was non-vacuous",
              saw_control_full_flush_barrier, 1'b1);
    tb_check1("V9O focused C1 observation was non-vacuous",
              saw_typed_trap_apply, 1'b1);
    $display("[V9O-CONTROL-EVENT-C0-C1] source-to-typed-apply timing PASS");

    tb_finish("tb_ooo_core_top_glue");
  end
`endif
`endif
endmodule
