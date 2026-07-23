`include "define.v"

// ALU-only OoO integer backend slice.  The frontend still supplies decoded uops;
// this module closes the loop from rename/issue through PRF read, dual ALU
// execute, writeback wakeup, and in-order ROB commit.
module OooIntBackend #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter FREE_COUNT_W = `OOO_FREE_COUNT_W,
  parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W,
  parameter ENABLE_DUAL_MEM = 0
) (
  input clk,
  input rst,
  input flush_i,
  input checkpoint_capture_i,
  input checkpoint_restore_i,
  input checkpoint_quiesce_i,
  output checkpoint_restore_apply_o,
  input mem_issue_block_i,
  input pending_branch_fast_valid_i,
  input [`XLEN-1:0] pending_branch_fast_pc_i,
  // v8k pending CSR 的 edge-old Q-only external lease。只参与 ROB birth
  // collision fence，不进入 transport ready 的其它依赖锥。
  input pending_system_producer_valid_i,
  input [PRODUCER_ID_W-1:0] pending_system_producer_id_i,
  input [`XLEN * `REG_NUM - 1:0] recover_gprs_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  output [PRODUCER_ID_W-1:0] dispatch0_producer_id_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`XLEN-1:0] dispatch0_pred_npc_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch0_ctrl_i,
  input [`REG_ADDR_W-1:0] dispatch0_rs1_arch_i,
  input [`REG_ADDR_W-1:0] dispatch0_rs2_arch_i,
  input [`REG_ADDR_W-1:0] dispatch0_rd_arch_i,
  input [`XLEN-1:0] dispatch0_imm_i,

  input dispatch1_valid_i,
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`XLEN-1:0] dispatch1_pred_npc_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch1_ctrl_i,
  input [`REG_ADDR_W-1:0] dispatch1_rs1_arch_i,
  input [`REG_ADDR_W-1:0] dispatch1_rs2_arch_i,
  input [`REG_ADDR_W-1:0] dispatch1_rd_arch_i,
  input [`XLEN-1:0] dispatch1_imm_i,

  // 【F2】BPU 查询快照随行(bht_idx=lookup 拍 pc^ghr): thread 进 IQ, resolve 拍导出回训
  input [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx_i,
  input dispatch0_pred_taken_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch1_bht_idx_i,
  input dispatch1_pred_taken_i,

  // 【B-FP 簇】FP dispatch 属性(AluDecodeBackend 旁路 decode 供给; spec §7)
  input dispatch0_is_fp_i,
  input dispatch0_fp_load_i,
  input dispatch0_fp_store_i,
  input dispatch0_fp_double_i,
  input dispatch0_fp_gpr_write_i,
  input dispatch0_fp_gpr_src_i,
  input dispatch0_fp_fs1_en_i,
  input dispatch0_fp_fs2_en_i,
  input dispatch0_fp_fs3_en_i,
  input dispatch1_is_fp_i,
  input dispatch1_fp_load_i,
  input dispatch1_fp_store_i,
  input dispatch1_fp_double_i,
  input dispatch1_fp_gpr_write_i,
  input dispatch1_fp_gpr_src_i,
  input dispatch1_fp_fs1_en_i,
  input dispatch1_fp_fs2_en_i,
  input dispatch1_fp_fs3_en_i,
  input [2:0] frm_i,
  output [4:0] commit0_fflags_o,
  output commit0_is_fp_rd_o,
  output commit1_is_fp_rd_o,
  output [4:0] commit1_fflags_o,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  // 【LSQ·SQ 切换】事务属性(spec §3.6): probe=store 翻译探测(不写, PA 回传);
  // pretrans+nokill=ROB-head SQ physical write(已翻译、写必达；B 才 terminal)。
  output mem_req_probe_o,
  output mem_req_pretrans_o,
  output mem_req_nokill_o,
  output mem_req_attr_valid_o,
  output [1:0] mem_req_class_o,
  output mem_req_cacheable_o,
  output [1:0] mem_req_owner_kind_o,
  output [4:0] mem_req_owner_token_o,
  output [1:0] mem_req_mmu_epoch_o,
  output [`XLEN-1:0] mem_req_fault_tval_o,
  output mem_req_device_release_o,
  output mem_req_device_cancel_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  input mem_rsp_page_fault_i,
  input mem_rsp_attr_valid_i,
  input [1:0] mem_rsp_class_i,
  input mem_rsp_cacheable_i,
  input [1:0] mem_rsp_owner_kind_i,
  input [4:0] mem_rsp_owner_token_i,
  input [1:0] mem_rsp_mmu_epoch_i,
  input [`XLEN-1:0] mem_rsp_fault_tval_i,
  // Registered MIQ-head ordering proof exported to the bridge.  Equality is
  // side-effect qualification only; it must never enter transport READY.
  output mem_expected_valid_o,
  output [1:0] mem_expected_owner_kind_o,
  output [4:0] mem_expected_owner_token_o,
  output [1:0] mem_expected_mmu_epoch_o,
  output mem_expected_tval_valid_o,
  output [`XLEN-1:0] mem_expected_fault_tval_o,
  output mem_expected_effective_killed_o,
  // Bridge active/station token queries into the edge-old tracker table.
  input mem_owner_query_valid_i,
  input [4:0] mem_owner_query_token_i,
  output mem_tracker_expected_valid_o,
  output [1:0] mem_tracker_expected_owner_kind_o,
  output [4:0] mem_tracker_expected_owner_token_o,
  output [1:0] mem_tracker_expected_mmu_epoch_o,
  input mem_station_query_valid_i,
  input [4:0] mem_station_query_token_i,
  output mem_station_expected_valid_o,
  output [1:0] mem_station_expected_owner_kind_o,
  output [4:0] mem_station_expected_owner_token_o,
  output [1:0] mem_station_expected_mmu_epoch_o,
  // v8t/F3 registered final-PA SQ query from bank0 bridge.  Backend maps the
  // exact token to full ProducerId, owns the SQ CAM, and provides the distinct
  // retry-slot credit for a nonterminal MIQ-to-retry holder handoff.
  input mem_sq_query_valid_i,
  input [1:0] mem_sq_query_owner_kind_i,
  input [4:0] mem_sq_query_owner_token_i,
  input [1:0] mem_sq_query_mmu_epoch_i,
  input [`XLEN-1:0] mem_sq_query_paddr_i,
  input mem_sq_query_attr_valid_i,
  input [1:0] mem_sq_query_class_i,
  input [`STRB_W-1:0] mem_sq_query_wstrb_i,
  output mem_sq_query_allow_o,
  output mem_sq_query_forward_o,
  output mem_sq_query_replay_o,
  output mem_sq_query_retry_ready_o,
  output [`XLEN-1:0] mem_sq_query_forward_data_o,
  // Exact bridge cancellation/drain terminals and its edge-old residency.
  input mem_drop0_valid_i,
  input [1:0] mem_drop0_owner_kind_i,
  input [4:0] mem_drop0_owner_token_i,
  input [1:0] mem_drop0_mmu_epoch_i,
  input [`XLEN-1:0] mem_drop0_fault_tval_i,
  input mem_drop1_valid_i,
  input [1:0] mem_drop1_owner_kind_i,
  input [4:0] mem_drop1_owner_token_i,
  input [1:0] mem_drop1_mmu_epoch_i,
  input [`XLEN-1:0] mem_drop1_fault_tval_i,
  input [31:0] mem_bridge_owner_residency_mask_i,
  // v8s/F2 second canonical memory bank. Reusable wrappers default the
  // parameter off; NpcCoreTop enables and wires this complete face.
  output mem1_req_valid_o,
  input mem1_req_ready_i,
  output mem1_req_write_o,
  output mem1_req_probe_o,
  output mem1_req_pretrans_o,
  output mem1_req_nokill_o,
  output mem1_req_attr_valid_o,
  output [1:0] mem1_req_class_o,
  output mem1_req_cacheable_o,
  output [1:0] mem1_req_owner_kind_o,
  output [4:0] mem1_req_owner_token_o,
  output [1:0] mem1_req_mmu_epoch_o,
  output [`XLEN-1:0] mem1_req_fault_tval_o,
  output mem1_req_device_release_o,
  output mem1_req_device_cancel_o,
  output [`XLEN-1:0] mem1_req_addr_o,
  output [`XLEN-1:0] mem1_req_wdata_o,
  output [`STRB_W-1:0] mem1_req_wstrb_o,
  input mem1_rsp_valid_i,
  output mem1_rsp_ready_o,
  input [`XLEN-1:0] mem1_rsp_rdata_i,
  input mem1_rsp_error_i,
  input mem1_rsp_page_fault_i,
  input mem1_rsp_attr_valid_i,
  input [1:0] mem1_rsp_class_i,
  input mem1_rsp_cacheable_i,
  input [1:0] mem1_rsp_owner_kind_i,
  input [4:0] mem1_rsp_owner_token_i,
  input [1:0] mem1_rsp_mmu_epoch_i,
  input [`XLEN-1:0] mem1_rsp_fault_tval_i,
  output mem1_expected_valid_o,
  output [1:0] mem1_expected_owner_kind_o,
  output [4:0] mem1_expected_owner_token_o,
  output [1:0] mem1_expected_mmu_epoch_o,
  output mem1_expected_tval_valid_o,
  output [`XLEN-1:0] mem1_expected_fault_tval_o,
  output mem1_expected_effective_killed_o,
  input mem1_owner_query_valid_i,
  input [4:0] mem1_owner_query_token_i,
  output mem1_tracker_expected_valid_o,
  output [1:0] mem1_tracker_expected_owner_kind_o,
  output [4:0] mem1_tracker_expected_owner_token_o,
  output [1:0] mem1_tracker_expected_mmu_epoch_o,
  input mem1_station_query_valid_i,
  input [4:0] mem1_station_query_token_i,
  output mem1_station_expected_valid_o,
  output [1:0] mem1_station_expected_owner_kind_o,
  output [4:0] mem1_station_expected_owner_token_o,
  output [1:0] mem1_station_expected_mmu_epoch_o,
  input mem1_sq_query_valid_i,
  input [1:0] mem1_sq_query_owner_kind_i,
  input [4:0] mem1_sq_query_owner_token_i,
  input [1:0] mem1_sq_query_mmu_epoch_i,
  input [`XLEN-1:0] mem1_sq_query_paddr_i,
  input mem1_sq_query_attr_valid_i,
  input [1:0] mem1_sq_query_class_i,
  input [`STRB_W-1:0] mem1_sq_query_wstrb_i,
  output mem1_sq_query_allow_o,
  output mem1_sq_query_forward_o,
  output mem1_sq_query_replay_o,
  output mem1_sq_query_retry_ready_o,
  output [`XLEN-1:0] mem1_sq_query_forward_data_o,
  input mem1_drop0_valid_i,
  input [1:0] mem1_drop0_owner_kind_i,
  input [4:0] mem1_drop0_owner_token_i,
  input [1:0] mem1_drop0_mmu_epoch_i,
  input [`XLEN-1:0] mem1_drop0_fault_tval_i,
  input mem1_drop1_valid_i,
  input [1:0] mem1_drop1_owner_kind_i,
  input [4:0] mem1_drop1_owner_token_i,
  input [1:0] mem1_drop1_mmu_epoch_i,
  input [`XLEN-1:0] mem1_drop1_fault_tval_i,
  input [31:0] mem1_bridge_owner_residency_mask_i,
  input mem1_translate_active_i,
  // 当前上下文数据访问是否经 Sv39 翻译(load-vs-SQ 判定在翻译开启时保守 blind, 防 VA 别名)
  input mem_translate_active_i,

  input commit_ready_i,
  input commit1_block_i,
  output commit0_valid_o,
  output [PRODUCER_ID_W-1:0] commit0_producer_id_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit0_new_pdest_o,
  output [`XLEN-1:0] commit0_data_o,
  output commit0_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit0_cause_o,
  output [`XLEN-1:0] commit0_tval_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit1_new_pdest_o,
  output [`XLEN-1:0] commit1_data_o,
  output commit1_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit1_cause_o,
  output [`XLEN-1:0] commit1_tval_o,

  output [FREE_COUNT_W-1:0] free_count_o,
  output [ROB_COUNT_W-1:0] rob_count_o,
  output [ISSUE_COUNT_W-1:0] issue_count_o,
  output mem_idle_o,
  // 退休侧访存静默(SQ 排空且无 drain 在飞): AND 进 backend_drained, 保证 system/trap/FP
  // 等串行点看到的"后端排空"包含已退休未落存的 store(SQ 化后 ROB 空不再隐含内存静默)。
  output mem_retire_quiet_o,
  output execute0_valid_o,
  output execute1_valid_o,

  output branch_resolve_valid_o,
  output [`XLEN-1:0] branch_resolve_pc_o,
  output [`XLEN-1:0] branch_resolve_next_pc_o,
  output branch_resolve_misaligned_o,
  // B2：导出解析分支的 rob_idx（kill_younger_than 的年龄基准；issue 路径）。
  // 详见 design/arch/b2-branch-spec-redirect.md §3.1/§7。本切片纯增量，未接消费者。
  output [ROB_INDEX_W-1:0] branch_resolve_rob_idx_o,
  // B2 片4：被选中 lane 的 branch/JALR mispredict 脉冲（mode=1 驱动 ROB-walk kill + redirect）。
  output branch_resolve_mispredict_o,
  // 【F2】resolve 总线随行导出: BPU issue-resolve 回训(前端消费, 只在 is_branch 拍)
  output branch_resolve_is_branch_o,
  output branch_resolve_taken_o,
  output branch_resolve_pred_taken_o,
  output [`BPU_BHT_INDEX_W-1:0] branch_resolve_bht_idx_o,
  output dispatch_branch_resolve_valid_o,
  output [`XLEN-1:0] dispatch_branch_resolve_pc_o,
  output [`XLEN-1:0] dispatch_branch_resolve_next_pc_o,
  output dispatch_branch_resolve_misaligned_o,

  // 【P4 shadow】ROB 队头指针观测口（→AluDecodeBackend→AluCoreSlice→ExecuteBackend→glue）：
  // 供 OooCoreTopGlue 的 shadow RedirectArbiter 年龄律（age = rob_idx - head）；也是
  // flush 单点化真 arbiter 收敛所需的 plumbing（pipeline-stage-boundary.md §5），非一次性。
  output [ROB_INDEX_W-1:0] rob_head_idx_o,

  // S2-Q2 v8a：无状态、同名 shadow transport。
  input head0_context_permit_i,
  input fencei_retire_permit_i,
  output head0_retire_candidate_valid_o,
  output head0_identity_valid_o,
  output [`OOO_CONTEXT_ID_W-1:0] head0_identity_o
);

  localparam [1:0] CLMUL_OP_LOW = 2'd0;
  localparam [1:0] CLMUL_OP_HIGH = 2'd1;
  localparam [1:0] CLMUL_OP_REV = 2'd2;
  localparam [1:0] MEM_OWNER_LOAD = 2'b00;
  localparam [1:0] MEM_OWNER_STORE = 2'b01;
  localparam [1:0] MEM_OWNER_ATOMIC = 2'b10;
  localparam [1:0] MEM_OWNER_RESERVED = 2'b11;
  localparam integer LQ_ENTRY_N = (1 << ROB_INDEX_W);
  localparam integer LQ_COUNT_W = ROB_INDEX_W + 1;
  // Epoch advancement/lock remains a later hard gate.  The typed field is
  // nevertheless carried end-to-end in this exact-owner checkpoint.
  localparam [1:0] MEM_OWNER_EPOCH_BASE = 2'b00;
  localparam integer BRANCH_RESOLVE_PAYLOAD_W =
      (2 * `XLEN) + PRODUCER_ID_W + `BPU_BHT_INDEX_W + 5;
  // Registered EX completion packet, low to high:
  // tval/cause/exception/result/pdest/raw-ROB/fwd/generation.  Derive every
  // boundary from public width parameters; default 64/6/4/4 retains the
  // historical [148:0] layout (fwd=144, raw ROB=[143:140]).
  localparam integer EX_STAGE_TVAL_LSB = 0;
  localparam integer EX_STAGE_TVAL_MSB = EX_STAGE_TVAL_LSB + `XLEN - 1;
  localparam integer EX_STAGE_CAUSE_LSB = EX_STAGE_TVAL_MSB + 1;
  localparam integer EX_STAGE_CAUSE_MSB =
      EX_STAGE_CAUSE_LSB + `TRAP_CAUSE_W - 1;
  localparam integer EX_STAGE_EXCEPTION_BIT = EX_STAGE_CAUSE_MSB + 1;
  localparam integer EX_STAGE_RESULT_LSB = EX_STAGE_EXCEPTION_BIT + 1;
  localparam integer EX_STAGE_RESULT_MSB = EX_STAGE_RESULT_LSB + `XLEN - 1;
  localparam integer EX_STAGE_PDEST_LSB = EX_STAGE_RESULT_MSB + 1;
  localparam integer EX_STAGE_PDEST_MSB =
      EX_STAGE_PDEST_LSB + PHY_REG_ADDR_W - 1;
  localparam integer EX_STAGE_ROB_IDX_LSB = EX_STAGE_PDEST_MSB + 1;
  localparam integer EX_STAGE_ROB_IDX_MSB =
      EX_STAGE_ROB_IDX_LSB + ROB_INDEX_W - 1;
  localparam integer EX_STAGE_FWD_BIT = EX_STAGE_ROB_IDX_MSB + 1;
  localparam integer EX_STAGE_GEN_LSB = EX_STAGE_FWD_BIT + 1;
  localparam integer EX_STAGE_GEN_MSB =
      EX_STAGE_GEN_LSB + PRODUCER_GEN_W - 1;
  localparam integer EX_STAGE_PAYLOAD_W = EX_STAGE_GEN_MSB + 1;

  wire wb0_valid_w;
  wire [PRODUCER_ID_W-1:0] wb0_producer_id_w;
  wire [ROB_INDEX_W-1:0] wb0_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] wb0_pdest_w;
  wire [`XLEN-1:0] wb0_data_w;
  wire wb0_exception_w;
  wire [`TRAP_CAUSE_W-1:0] wb0_cause_w;
  wire [`XLEN-1:0] wb0_tval_w;
  wire wb1_valid_w;
  wire [PRODUCER_ID_W-1:0] wb1_producer_id_w;
  wire [ROB_INDEX_W-1:0] wb1_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] wb1_pdest_w;
  wire [`XLEN-1:0] wb1_data_w;
  wire wb1_exception_w;
  wire [`TRAP_CAUSE_W-1:0] wb1_cause_w;
  wire [`XLEN-1:0] wb1_tval_w;
  // R3.2 EX registers carry one forwarding-valid bit above the legacy
  // formal-WB payload; all legacy field positions remain unchanged.
  wire ex0_valid_q;
  wire [EX_STAGE_PAYLOAD_W-1:0] ex0_down_payload_w;
  wire ex1_valid_q;
  wire [EX_STAGE_PAYLOAD_W-1:0] ex1_down_payload_w;
  // v8d：raw stage valid 只表示物理寄存器占用；selective recovery 同拍
  // 必须先形成 effective completion，才能进入 WB/PRF/wakeup/ROB 副作用面。
  wire ex0_kill_now_w;
  wire ex1_kill_now_w;
  wire [PRODUCER_ID_W-1:0] ex0_producer_id_q;
  wire [PRODUCER_ID_W-1:0] ex1_producer_id_q;
  // v8l lease contributors are declared before the DispatchBackend instance
  // so no forward reference can create an implicit one-bit net in Icarus.
  reg mem_issue_res_valid_q;
  reg [PRODUCER_ID_W-1:0] mem_issue_res_producer_id_q;
  reg mem_issue1_res_valid_q;
  reg [PRODUCER_ID_W-1:0] mem_issue1_res_producer_id_q;
  wire branch_resolve_stage_valid_w;
  wire [PRODUCER_ID_W-1:0] branch_resolve_payload_producer_id_w;
  wire ex0_pre_auth_valid_w;
  wire ex1_pre_auth_valid_w;
  wire ex0_producer_open_w;
  wire ex1_producer_open_w;
  wire ex0_wb_valid_w;
  wire ex1_wb_valid_w;
  // Shared-WB flow control is deliberately earlier than exact completion
  // authorization.  A live, non-killed EX packet reserves its physical lane;
  // exact-open only decides whether that packet may produce side effects.
  // This keeps the ROB generation/done query out of transport/issue ready.
  wire ex0_wb_slot_occupied_w;
  wire ex1_wb_slot_occupied_w;
  // 真实 integer PRF write event 与送往 FP IQ 的 formal sticky wake
  // 共用同一 valid 真源，过滤 FP-only/probe/x0 completion 的 p0 tag。
  wire gpr_wb0_write_valid_w;
  wire gpr_wb1_write_valid_w;
  // T3S：IQ lane0 的 raw 选择端与执行端分离。memory uop 先进入
  // non-fallthrough reservation；执行端只在下一拍消费 reservation Q。
  wire iq_issue0_valid_w;
  wire iq_issue0_ready_w;
  wire iq_memory_pair_peek_enable_w;
  wire iq_memory_pair_peek_valid_w;
  wire iq_memory_pair_peek_ready_w;
  wire iq_issue_pair_swapped_w;
  wire [`XLEN-1:0] iq_issue0_pc_w;
  wire [`XLEN-1:0] iq_issue0_next_pc_w;
  wire [`XLEN-1:0] iq_issue0_pred_npc_w;
  wire [`BPU_BHT_INDEX_W-1:0] iq_issue0_bht_idx_w;
  wire iq_issue0_pred_taken_w;
  wire [`INST_W-1:0] iq_issue0_inst_w;
  wire [`CTRL_BUS_W-1:0] iq_issue0_ctrl_w;
  wire [ROB_INDEX_W-1:0] iq_issue0_rob_idx_w;
  wire [PRODUCER_ID_W-1:0] iq_issue0_producer_id_w;
  wire iq_issue0_producer_current_w;
  wire [PHY_REG_ADDR_W-1:0] iq_issue0_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] iq_issue0_src2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] iq_issue0_pdest_w;
  wire iq_issue0_fixed_gpr_producer_w;
  wire [`XLEN-1:0] iq_issue0_imm_w;
  wire issue0_valid_w;
  wire issue0_ready_w;
  wire issue0_fire_w;
  wire muldiv_req_ready_w;
  wire clmul_req_ready_w;
  wire muldiv_resp_valid_w;
  wire muldiv_resp_ready_w;
  wire [ROB_INDEX_W-1:0] muldiv_resp_rob_idx_w;
  wire [PRODUCER_ID_W-1:0] muldiv_resp_producer_id_w;
  wire [PHY_REG_ADDR_W-1:0] muldiv_resp_pdest_w;
  wire [`XLEN-1:0] muldiv_resp_data_w;
  wire muldiv_owner_valid_w;
  wire [PRODUCER_ID_W-1:0] muldiv_owner_producer_id_w;
  wire muldiv_completion_rob_open_w;
  wire clmul_resp_valid_w;
  wire clmul_resp_ready_w;
  wire [ROB_INDEX_W-1:0] clmul_resp_rob_idx_w;
  wire [PRODUCER_ID_W-1:0] clmul_resp_producer_id_w;
  wire [PHY_REG_ADDR_W-1:0] clmul_resp_pdest_w;
  wire [`XLEN-1:0] clmul_resp_data_w;
  wire clmul_owner_valid_w;
  wire [PRODUCER_ID_W-1:0] clmul_owner_producer_id_w;
  wire clmul_completion_rob_open_w;
  wire [`XLEN-1:0] issue0_pc_w;
  wire [`XLEN-1:0] issue0_next_pc_w;
  wire [`XLEN-1:0] issue0_pred_npc_w;
  wire [`BPU_BHT_INDEX_W-1:0] issue0_bht_idx_w;
  wire issue0_pred_taken_w;
  wire [`BPU_BHT_INDEX_W-1:0] issue1_bht_idx_w;
  wire issue1_pred_taken_w;
  wire [`INST_W-1:0] issue0_inst_w;
  wire [`CTRL_BUS_W-1:0] issue0_ctrl_w;
  wire [ROB_INDEX_W-1:0] issue0_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_pdest_w;
  wire [`XLEN-1:0] issue0_imm_w;

  wire issue1_valid_w;
  wire issue1_ready_w;
  wire issue1_fire_w;
  wire issue1_exec_fire_w;
  wire [`XLEN-1:0] issue1_pc_w;
  wire [`XLEN-1:0] issue1_next_pc_w;
  wire [`XLEN-1:0] issue1_pred_npc_w;
  wire [`INST_W-1:0] issue1_inst_w;
  wire [`CTRL_BUS_W-1:0] issue1_ctrl_w;
  wire [ROB_INDEX_W-1:0] issue1_rob_idx_w;
  wire [PRODUCER_ID_W-1:0] issue1_producer_id_w;
  wire issue1_producer_current_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_src1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_src2_preg_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_pdest_w;
  wire issue1_fixed_gpr_producer_w;
  wire [`XLEN-1:0] issue1_imm_w;
  wire mem_issue_block_w = mem_issue_block_i || checkpoint_quiesce_i ||
                           checkpoint_restore_hold_w;
  wire early_wakeup0_raw_valid_w =
      issue0_fire_w && iq_issue0_fixed_gpr_producer_w;
  wire early_wakeup1_raw_valid_w =
      issue1_exec_fire_w && issue1_fixed_gpr_producer_w;
  // v8f: issue-time sticky wake is a side effect.  It is legal only while the
  // carried ProducerId is the current ROB incarnation; the Q-only query does
  // not feed resident select or issue READY.
  wire early_wakeup0_valid_w =
      early_wakeup0_raw_valid_w && iq_issue0_producer_current_w;
  wire early_wakeup1_valid_w =
      early_wakeup1_raw_valid_w && issue1_producer_current_w;

  // 【B-FP 簇】dispatch 分流: FP 算术/跨域 → FpBackend.disp; FP load → fpld_alloc
  // (lane0/lane1 均可, 每拍一条); FP store → fpst_query(数据源进整数 IQ fp_src2)。
  // T3C/T4S: resource intent 不含 ready，也不把 packet valid 回灌到
  // capacity。class payload 在 valid=0 时是 don't-care，真正状态更新仍只认
  // DBE actual accept；这样 ready DAG 不会绕 FP credit 再回到 packet fire。
  wire d0_fp_arith_w = dispatch0_is_fp_i && !dispatch0_fp_load_i &&
                       !dispatch0_fp_store_i;
  wire d1_fp_arith_w = dispatch1_is_fp_i && !dispatch1_fp_load_i &&
                       !dispatch1_fp_store_i;
  wire d0_is_fp_rd_w = dispatch0_is_fp_i && !dispatch0_fp_store_i &&
                       !dispatch0_fp_gpr_write_i;   // FPR 目的(含 FP load)
  wire d1_is_fp_rd_w = dispatch1_is_fp_i && !dispatch1_fp_store_i &&
                       !dispatch1_fp_gpr_write_i;
  wire fp_disp_ready_w;
  wire fp_disp1_ready_w;
  wire fp_alloc0_ready_w;
  wire fp_alloc1_ready_w;
  wire d0_fp_own_ok_w = !dispatch0_is_fp_i ||
                        (d0_fp_arith_w ? fp_disp_ready_w :
                         dispatch0_fp_load_i ? fp_alloc0_ready_w : 1'b1);
  // lane1 的 ready 是两 lane FP need 的 packet credit（lane0 need=0 时自然退化）。
  wire d1_fp_pair_ok_w = !dispatch1_is_fp_i ||
                         (d1_fp_arith_w ? fp_disp1_ready_w :
                          dispatch1_fp_load_i ? fp_alloc1_ready_w : 1'b1);
  wire fp_mandatory_pair_w = dispatch0_valid_i && dispatch1_valid_i &&
                             !dispatch1_optional_i;
  wire d0_fp_ok_w = d0_fp_own_ok_w &&
                     (!fp_mandatory_pair_w || d1_fp_pair_ok_w);
  wire d1_fp_ok_w = d1_fp_pair_ok_w;
  wire [PHY_REG_ADDR_W-1:0] fp_disp_new_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fp_disp_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fp_disp1_new_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fp_disp1_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpld0_new_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpld0_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpld1_new_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpld1_old_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] fpst0_query_preg_w;
  wire fpst0_query_ready_w;
  wire [PHY_REG_ADDR_W-1:0] fpst1_query_preg_w;
  wire fpst1_query_ready_w;
  wire fp_wake0_valid_w;
  wire [PHY_REG_ADDR_W-1:0] fp_wake0_preg_w;
  wire fp_wake1_valid_w;
  wire [PHY_REG_ADDR_W-1:0] fp_wake1_preg_w;
  wire [PHY_REG_ADDR_W-1:0] fpst_read_preg_w;
  wire [`XLEN-1:0] fpst_read_data_w;
  wire [PHY_REG_ADDR_W-1:0] fp_gpr_read_addr_w;
  wire [`XLEN-1:0] fp_gpr_read_data_w;
  wire fpwb_valid_w;
  wire [PRODUCER_ID_W-1:0] fpwb_producer_id_w;
  wire [ROB_INDEX_W-1:0] fpwb_rob_idx_w;
  wire [PHY_REG_ADDR_W-1:0] fpwb_pdest_w;
  wire fpwb_rd_en_w;
  wire [`XLEN-1:0] fpwb_data_w;
  wire [4:0] fpwb_fflags_w;
  wire fpwb_ready_w;
  wire fp_result_query_valid_w;
  wire [PRODUCER_ID_W-1:0] fp_result_query_producer_id_w;
  wire fp_result_completion_rob_open_w;
  wire fp_result_authorized_w;
  wire fp_formal_completion_rob_open_w;
  wire [(1 << PRODUCER_ID_W)-1:0] fp_completion_pending_mask_w;
  wire [(1 << PRODUCER_ID_W)-1:0] fp_producer_live_mask_w;
  wire rob_walk0_is_fp_w;
  wire rob_walk1_is_fp_w;
  wire commit0_is_fp_rd_w;
  wire commit1_is_fp_rd_w;
  wire issue0_fp_pdest_w;
  wire issue0_fp_st_en_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_fp_st_preg_w;
  wire iq_issue0_fp_pdest_w;
  wire iq_issue0_fp_st_en_w;
  wire [PHY_REG_ADDR_W-1:0] iq_issue0_fp_st_preg_w;
  wire issue1_fp_pdest_w;
  wire issue1_fp_st_en_w;
  wire [PHY_REG_ADDR_W-1:0] issue1_fp_st_preg_w;
  wire rob_recover_active_w;
  wire dispatch0_dbe_ready_w;
  wire dispatch1_dbe_ready_w;
  reg checkpoint_restore_pending_q;
  reg checkpoint_restore_seen_q;
  reg checkpoint_irrevocable_write_q;
  reg [PRODUCER_ID_W-1:0] checkpoint_irrevocable_write_pid_q;
  wire checkpoint_restore_new_req_w =
      checkpoint_restore_i && !checkpoint_restore_seen_q;
  wire checkpoint_restore_hold_w =
      checkpoint_restore_i || checkpoint_restore_pending_q;
  wire checkpoint_restore_apply_w;
  // lane1 GPR 目的 FP 的整数 pdest(经 DispatchBackend 新输出)
  wire [PHY_REG_ADDR_W-1:0] dispatch1_new_pdest_probe_w;
  wire walk0_fp_valid_w;
  wire [`REG_ADDR_W-1:0] walk0_fp_arch_w;
  wire [PHY_REG_ADDR_W-1:0] walk0_fp_old_w;
  wire [PHY_REG_ADDR_W-1:0] walk0_fp_new_w;
  wire walk1_fp_valid_w;
  wire [`REG_ADDR_W-1:0] walk1_fp_arch_w;
  wire [PHY_REG_ADDR_W-1:0] walk1_fp_old_w;
  wire [PHY_REG_ADDR_W-1:0] walk1_fp_new_w;
  wire [4:0] wb0_fflags_w;
  wire [4:0] wb1_fflags_w;
  assign dispatch0_ready_o = dispatch0_dbe_ready_w && d0_fp_ok_w &&
                             !checkpoint_restore_hold_w;
  assign dispatch1_ready_o = dispatch1_dbe_ready_w && d1_fp_ok_w &&
                             !checkpoint_restore_hold_w;
  wire dispatch0_fire_w;
  wire [ROB_INDEX_W-1:0] dispatch0_rob_idx_w;
  wire [PRODUCER_ID_W-1:0] dispatch0_producer_id_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch0_pdest_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg_w;
  wire dispatch0_src1_ready_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg_w;
  wire dispatch0_src2_ready_w;
  wire dispatch1_fire_w;
  wire [ROB_INDEX_W-1:0] dispatch1_rob_idx_w;
  wire [PRODUCER_ID_W-1:0] dispatch1_producer_id_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg_w;
  wire dispatch1_src1_ready_w;
  wire [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg_w;
  wire dispatch1_src2_ready_w;
  wire [ROB_INDEX_W-1:0] rob_head_idx_w;
  wire rob_head_valid_w;
  wire [PRODUCER_ID_W-1:0] rob_head_producer_id_w;
  wire rob_head_launch_open_w;
  wire [PRODUCER_ID_W-1:0] rob_commit0_producer_id_w;
  wire [PRODUCER_ID_W-1:0] rob_commit1_producer_id_w;
  wire lq_alloc0_ready_w;
  wire lq_alloc1_ready_w;
  wire lq_issue0_open_w;
  wire lq_issue1_open_w;
  wire lq_query0_open_w;
  wire lq_query1_open_w;
  wire lq_response0_open_w;
  wire lq_response1_open_w;
  wire [(1 << PRODUCER_ID_W)-1:0] lq_producer_live_mask_w;
  wire [LQ_COUNT_W-1:0] lq_count_w;
  wire lq_alloc0_valid_w;
  wire [ROB_INDEX_W-1:0] lq_alloc0_rob_w;
  wire [PRODUCER_ID_W-1:0] lq_alloc0_producer_id_w;
  wire lq_alloc1_valid_w;
  wire lq_launch0_valid_w;
  wire [PRODUCER_ID_W-1:0] lq_launch0_producer_id_w;
  wire lq_launch1_valid_w;
  wire [PRODUCER_ID_W-1:0] lq_launch1_producer_id_w;
  wire lq_query0_update_w;
  wire lq_query1_update_w;
  wire lq_response0_query_valid_w;
  wire lq_response1_query_valid_w;
  wire lq_terminal0_valid_w;
  wire [PRODUCER_ID_W-1:0] lq_terminal0_producer_id_w;
  wire lq_terminal1_valid_w;
  wire [PRODUCER_ID_W-1:0] lq_terminal1_producer_id_w;
  wire lq_release0_valid_w;
  wire lq_release1_valid_w;
  wire lq_release0_commit_w;
  wire lq_release1_commit_w;
  wire lq_release0_ready_w;
  wire lq_release1_ready_w;
  wire lq_release0_fire_w;
  wire lq_release1_fire_w;
  wire lq_retire0_permit_w;
  wire lq_retire1_permit_w;
  wire [(1 << PRODUCER_ID_W)-1:0] mem_owner_producer_live_mask_w;
  wire [(1 << PRODUCER_ID_W)-1:0] muldiv_owner_producer_live_mask_w =
      muldiv_owner_valid_w ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
       muldiv_owner_producer_id_w) :
      {(1 << PRODUCER_ID_W){1'b0}};
  wire [(1 << PRODUCER_ID_W)-1:0] clmul_owner_producer_live_mask_w =
      clmul_owner_valid_w ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
       clmul_owner_producer_id_w) :
      {(1 << PRODUCER_ID_W){1'b0}};
  wire [(1 << PRODUCER_ID_W)-1:0] pending_system_producer_live_mask_w =
      pending_system_producer_valid_i ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
       pending_system_producer_id_i) :
      {(1 << PRODUCER_ID_W){1'b0}};
  wire [(1 << PRODUCER_ID_W)-1:0] mem_res_producer_live_mask_w =
      (mem_issue_res_valid_q ?
       ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
        mem_issue_res_producer_id_q) :
       {(1 << PRODUCER_ID_W){1'b0}}) |
      (mem_issue1_res_valid_q ?
       ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
        mem_issue1_res_producer_id_q) :
       {(1 << PRODUCER_ID_W){1'b0}});
  wire [(1 << PRODUCER_ID_W)-1:0] ex0_producer_live_mask_w =
      ex0_valid_q ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
       ex0_producer_id_q) :
      {(1 << PRODUCER_ID_W){1'b0}};
  wire [(1 << PRODUCER_ID_W)-1:0] ex1_producer_live_mask_w =
      ex1_valid_q ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
       ex1_producer_id_q) :
      {(1 << PRODUCER_ID_W){1'b0}};
  wire [(1 << PRODUCER_ID_W)-1:0] branch_producer_live_mask_w =
      branch_resolve_stage_valid_w ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
       branch_resolve_payload_producer_id_w) :
      {(1 << PRODUCER_ID_W){1'b0}};
  wire [(1 << PRODUCER_ID_W)-1:0]
      checkpoint_irrevocable_write_live_mask_w =
      checkpoint_irrevocable_write_q ?
      ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
       checkpoint_irrevocable_write_pid_q) :
      {(1 << PRODUCER_ID_W){1'b0}};
  wire [(1 << PRODUCER_ID_W)-1:0] transient_producer_live_mask_w =
      mem_res_producer_live_mask_w |
      ex0_producer_live_mask_w |
      ex1_producer_live_mask_w |
      branch_producer_live_mask_w |
      checkpoint_irrevocable_write_live_mask_w;
  wire [(1 << PRODUCER_ID_W)-1:0] external_producer_live_mask_w =
      mem_owner_producer_live_mask_w |
      lq_producer_live_mask_w |
      muldiv_owner_producer_live_mask_w |
      clmul_owner_producer_live_mask_w |
      fp_producer_live_mask_w |
      pending_system_producer_live_mask_w |
      transient_producer_live_mask_w;
  // Complete mask is driven by OooDispatchBackend after its local resident
  // integer-IQ mask is ORed with the external contributors above.
  wire [(1 << PRODUCER_ID_W)-1:0] producer_live_mask_w;
  wire [PRODUCER_ID_W-1:0] mem_completion_producer_id_w;
  wire mem_completion_query_valid_w;
  wire mem_completion_rob_open_w;
  wire [PRODUCER_ID_W-1:0] mem1_completion_producer_id_w;
  wire mem1_completion_query_valid_w;
  wire mem1_completion_rob_open_w;
  // 【P4 shadow】队头指针透出（驱动源=下方 u_rob.rob_head_idx_o，纯观测，不改任何现有行为）
  assign rob_head_idx_o = rob_head_idx_w;
  assign dispatch0_producer_id_o = dispatch0_producer_id_w;
  assign commit0_producer_id_o = rob_head_producer_id_w;
  // 声明前置：iverilog 14 拒绝前向引用（驱动仍在原处）
  wire branch_resolve_mispredict_w;
  wire branch_resolve_query_valid_w;
  wire [PRODUCER_ID_W-1:0] branch_resolve_query_producer_id_w;
  wire branch_resolve_rob_open_w;
  wire sq_alloc0_ready_w;
  wire sq_alloc1_ready_w;
  wire unused_issue_ctrl_bits_w =
      (|{issue0_ctrl_w[42:24], issue0_ctrl_w[15:0]}) |
      (|{issue1_ctrl_w[42:24], issue1_ctrl_w[15:0]});

  // OooRob exposes edge-old head payloads independently of commit fire.  Use
  // those identities for Q-only LQ retire lookups, then feed the resulting
  // completion/residency permits back into commit_ready/commit1_block.  The
  // separate commit wires below are the only events allowed to free entries.
  wire rob_head0_plain_load_w =
      (commit0_inst_o[6:0] == 7'b0000011) ||
      ((commit0_inst_o[6:0] == 7'b0000111) &&
       ((commit0_inst_o[14:12] == 3'b010) ||
        (commit0_inst_o[14:12] == 3'b011)));
  wire rob_head1_plain_load_w =
      (commit1_inst_o[6:0] == 7'b0000011) ||
      ((commit1_inst_o[6:0] == 7'b0000111) &&
       ((commit1_inst_o[14:12] == 3'b010) ||
        (commit1_inst_o[14:12] == 3'b011)));
  assign lq_release0_valid_w = head0_retire_candidate_valid_o &&
      rob_head0_plain_load_w;
  assign lq_release1_valid_w =
      (rob_count_o > {{(ROB_COUNT_W-1){1'b0}}, 1'b1}) &&
      rob_head1_plain_load_w;
  assign lq_release0_commit_w = commit0_valid_o && rob_head0_plain_load_w;
  assign lq_release1_commit_w = commit1_valid_o && rob_head1_plain_load_w;
  assign lq_retire0_permit_w = !lq_release0_valid_w || lq_release0_ready_w;
  assign lq_retire1_permit_w = !lq_release1_valid_w || lq_release1_ready_w;

  // checkpoint_restore_i is a request, not an unconditional destructive edge.
  // If a physical write has already fired, the request remains pending while
  // that exact ROB/SQ owner accepts B, writes ROB done, commits in lane0 and
  // releases SQ.  checkpoint_restore_apply_w is the sole backend-wide recovery
  // pulse after every irreversible write owner has retired.
  OooDispatchBackend #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_dispatch_backend (
    .clk(clk),
    .head0_context_permit_i(head0_context_permit_i),
    .fencei_retire_permit_i(fencei_retire_permit_i),
    .head0_retire_candidate_valid_o(head0_retire_candidate_valid_o),
    .head0_identity_valid_o(head0_identity_valid_o),
    .head0_identity_o(head0_identity_o),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_apply_w),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),   // B2 ROB-walk：mispredict 控制流 rob_idx（与 mispredict 同拍）
    .branch_mispredict_valid_i(branch_resolve_mispredict_w),  // B2 片4：ROB-walk kill 触发
    .issue_mem_block_i(mem_issue_block_w),
    .universal_owner_present_i(
        mem_issue_res_valid_q || mem_issue1_res_valid_q),
    .memory_pair_peek_enable_i(iq_memory_pair_peek_enable_w),
    .memory_pair_peek_valid_o(iq_memory_pair_peek_valid_w),
    .memory_pair_peek_ready_i(iq_memory_pair_peek_ready_w),
    .sq_alloc0_ready_i(sq_alloc0_ready_w),
    .sq_alloc1_ready_i(sq_alloc1_ready_w),
    .lq_alloc0_ready_i(lq_alloc0_ready_w),
    .lq_alloc1_ready_i(lq_alloc1_ready_w),
    .producer_live_mask_i(external_producer_live_mask_w),
    .producer_live_mask_o(producer_live_mask_w),
    .dispatch0_valid_i(dispatch0_valid_i && d0_fp_ok_w &&
                       !checkpoint_restore_hold_w),
    .dispatch0_ready_o(dispatch0_dbe_ready_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_pred_npc_i(dispatch0_pred_npc_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(dispatch0_ctrl_i),
    .dispatch0_rs1_arch_i(dispatch0_rs1_arch_i),
    .dispatch0_rs2_arch_i(dispatch0_rs2_arch_i),
    .dispatch0_rd_arch_i(dispatch0_rd_arch_i),
    .dispatch0_is_fp_rd_i(d0_is_fp_rd_w),
    .dispatch0_is_fp_i(dispatch0_is_fp_i),
    .dispatch0_fp_pdest_i(dispatch0_fp_load_i ? fpld0_new_pdest_w
                                              : fp_disp_new_pdest_w),
    .dispatch0_fp_old_pdest_i(dispatch0_fp_load_i ? fpld0_old_pdest_w
                                                  : fp_disp_old_pdest_w),
    .dispatch0_fp_st_src_en_i(dispatch0_fp_store_i),
    .dispatch0_fp_st_src_preg_i(fpst0_query_preg_w),
    .dispatch0_fp_st_src_ready_i(fpst0_query_ready_w),
    .dispatch0_imm_i(dispatch0_imm_i),
    .dispatch0_bht_idx_i(dispatch0_bht_idx_i),
    .dispatch0_pred_taken_i(dispatch0_pred_taken_i),
    .dispatch1_bht_idx_i(dispatch1_bht_idx_i),
    .dispatch1_pred_taken_i(dispatch1_pred_taken_i),
    .dispatch1_valid_i(dispatch1_valid_i && d1_fp_ok_w &&
                       !checkpoint_restore_hold_w),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(dispatch1_dbe_ready_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_pred_npc_i(dispatch1_pred_npc_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(dispatch1_ctrl_i),
    .dispatch1_rs1_arch_i(dispatch1_rs1_arch_i),
    .dispatch1_rs2_arch_i(dispatch1_rs2_arch_i),
    .dispatch1_rd_arch_i(dispatch1_rd_arch_i),
    .dispatch1_is_fp_rd_i(d1_is_fp_rd_w),
    .dispatch1_is_fp_i(dispatch1_is_fp_i),
    .dispatch1_fp_pdest_i(dispatch1_fp_load_i ? fpld1_new_pdest_w
                                              : fp_disp1_new_pdest_w),
    .dispatch1_fp_old_pdest_i(dispatch1_fp_load_i ? fpld1_old_pdest_w
                                                  : fp_disp1_old_pdest_w),
    .dispatch1_fp_st_src_en_i(dispatch1_fp_store_i),
    .dispatch1_fp_st_src_preg_i(fpst1_query_preg_w),
    .dispatch1_fp_st_src_ready_i(fpst1_query_ready_w),
    .fp_wake0_valid_i(fp_wake0_valid_w),
    .fp_wake0_preg_i(fp_wake0_preg_w),
    .fp_wake1_valid_i(fp_wake1_valid_w),
    .fp_wake1_preg_i(fp_wake1_preg_w),
    .dispatch1_imm_i(dispatch1_imm_i),
    .wb0_valid_i(wb0_valid_w),
    .wb0_rob_idx_i(wb0_rob_idx_w),
    .wb0_pdest_i(wb0_pdest_w),
    .wb0_data_i(wb0_data_w),
    .wb0_exception_i(wb0_exception_w),
    .wb0_cause_i(wb0_cause_w),
    .wb0_tval_i(wb0_tval_w),
    .wb0_fflags_i(wb0_fflags_w),
    .wb1_valid_i(wb1_valid_w),
    .wb1_rob_idx_i(wb1_rob_idx_w),
    .wb1_pdest_i(wb1_pdest_w),
    .wb1_data_i(wb1_data_w),
    .wb1_exception_i(wb1_exception_w),
    .wb1_cause_i(wb1_cause_w),
    .wb1_tval_i(wb1_tval_w),
    .wb1_fflags_i(wb1_fflags_w),
    .completion0_query_valid_i(ex0_pre_auth_valid_w),
    .completion0_query_producer_id_i(ex0_producer_id_q),
    .completion0_query_match_o(ex0_producer_open_w),
    .completion1_query_valid_i(ex1_pre_auth_valid_w),
    .completion1_query_producer_id_i(ex1_producer_id_q),
    .completion1_query_match_o(ex1_producer_open_w),
    .completion2_query_valid_i(mem_completion_query_valid_w),
    .completion2_query_producer_id_i(mem_completion_producer_id_w),
    .completion2_query_match_o(mem_completion_rob_open_w),
    .completion3_query_valid_i(muldiv_resp_valid_w),
    .completion3_query_producer_id_i(muldiv_resp_producer_id_w),
    .completion3_query_match_o(muldiv_completion_rob_open_w),
    .completion4_query_valid_i(clmul_resp_valid_w),
    .completion4_query_producer_id_i(clmul_resp_producer_id_w),
    .completion4_query_match_o(clmul_completion_rob_open_w),
    .completion5_query_valid_i(fp_result_query_valid_w),
    .completion5_query_producer_id_i(fp_result_query_producer_id_w),
    .completion5_query_match_o(fp_result_completion_rob_open_w),
    .completion6_query_valid_i(fpwb_valid_w),
    .completion6_query_producer_id_i(fpwb_producer_id_w),
    .completion6_query_match_o(fp_formal_completion_rob_open_w),
    .completion7_query_valid_i(mem1_completion_query_valid_w),
    .completion7_query_producer_id_i(mem1_completion_producer_id_w),
    .completion7_query_match_o(mem1_completion_rob_open_w),
    .resolve_query_valid_i(branch_resolve_query_valid_w),
    .resolve_query_producer_id_i(branch_resolve_query_producer_id_w),
    .resolve_query_match_o(branch_resolve_rob_open_w),
    .early_wakeup0_valid_i(early_wakeup0_valid_w),
    .early_wakeup0_pdest_i(iq_issue0_pdest_w),
    .early_wakeup1_valid_i(early_wakeup1_valid_w),
    .early_wakeup1_pdest_i(issue1_pdest_w),
    .issue0_valid_o(iq_issue0_valid_w),
    .issue0_ready_i(iq_issue0_ready_w),
    .issue0_pc_o(iq_issue0_pc_w),
    .issue0_next_pc_o(iq_issue0_next_pc_w),
    .issue0_pred_npc_o(iq_issue0_pred_npc_w),
    .issue0_inst_o(iq_issue0_inst_w),
    .issue0_ctrl_o(iq_issue0_ctrl_w),
    .issue0_rob_idx_o(iq_issue0_rob_idx_w),
    .issue0_producer_id_o(iq_issue0_producer_id_w),
    .issue0_producer_current_o(iq_issue0_producer_current_w),
    .issue0_src1_preg_o(iq_issue0_src1_preg_w),
    .issue0_src2_preg_o(iq_issue0_src2_preg_w),
    .issue0_pdest_o(iq_issue0_pdest_w),
    .issue0_fixed_gpr_producer_o(iq_issue0_fixed_gpr_producer_w),
    .issue0_fp_pdest_o(iq_issue0_fp_pdest_w),
    .issue0_fp_st_src_en_o(iq_issue0_fp_st_en_w),
    .issue0_fp_st_src_preg_o(iq_issue0_fp_st_preg_w),
    .issue0_imm_o(iq_issue0_imm_w),
    .issue0_bht_idx_o(iq_issue0_bht_idx_w),
    .issue0_pred_taken_o(iq_issue0_pred_taken_w),
    .issue_pair_swapped_o(iq_issue_pair_swapped_w),
    .issue1_bht_idx_o(issue1_bht_idx_w),
    .issue1_pred_taken_o(issue1_pred_taken_w),
    .issue1_valid_o(issue1_valid_w),
    .issue1_ready_i(issue1_ready_w),
    .issue1_pc_o(issue1_pc_w),
    .issue1_next_pc_o(issue1_next_pc_w),
    .issue1_pred_npc_o(issue1_pred_npc_w),
    .issue1_inst_o(issue1_inst_w),
    .issue1_ctrl_o(issue1_ctrl_w),
    .issue1_rob_idx_o(issue1_rob_idx_w),
    .issue1_producer_id_o(issue1_producer_id_w),
    .issue1_producer_current_o(issue1_producer_current_w),
    .issue1_src1_preg_o(issue1_src1_preg_w),
    .issue1_src2_preg_o(issue1_src2_preg_w),
    .issue1_pdest_o(issue1_pdest_w),
    .issue1_fixed_gpr_producer_o(issue1_fixed_gpr_producer_w),
    .issue1_fp_pdest_o(issue1_fp_pdest_w),
    .issue1_fp_st_src_en_o(issue1_fp_st_en_w),
    .issue1_fp_st_src_preg_o(issue1_fp_st_preg_w),
    .issue1_imm_o(issue1_imm_w),
    .dispatch0_fire_o(dispatch0_fire_w),
    .dispatch0_rob_idx_o(dispatch0_rob_idx_w),
    .dispatch0_producer_id_o(dispatch0_producer_id_w),
    .dispatch0_pdest_o(dispatch0_pdest_w),
    .dispatch1_pdest_o(dispatch1_new_pdest_probe_w),
    .dispatch0_src1_preg_o(dispatch0_src1_preg_w),
    .dispatch0_src1_ready_o(dispatch0_src1_ready_w),
    .dispatch0_src2_preg_o(dispatch0_src2_preg_w),
    .dispatch0_src2_ready_o(dispatch0_src2_ready_w),
    .dispatch1_fire_o(dispatch1_fire_w),
    .dispatch1_rob_idx_o(dispatch1_rob_idx_w),
    .dispatch1_producer_id_o(dispatch1_producer_id_w),
    .dispatch1_src1_preg_o(dispatch1_src1_preg_w),
    .dispatch1_src1_ready_o(dispatch1_src1_ready_w),
    .dispatch1_src2_preg_o(dispatch1_src2_preg_w),
    .dispatch1_src2_ready_o(dispatch1_src2_ready_w),
    .commit_ready_i(commit_ready_i && !checkpoint_capture_i &&
                    !checkpoint_restore_apply_w && !checkpoint_quiesce_i &&
                    lq_retire0_permit_w),
    .commit1_block_i(commit1_block_i || !lq_retire1_permit_w ||
                     checkpoint_restore_hold_w),
    // 【serialize Phase1 §9/§10.4】mem 门控用 mem_idle 单独，不含 sq_empty。head0 CSR
    // 之前不可能有未完成 older store（ROB 顺序）；younger store 即使已 probe/fill，也因
    // physical-head!=ROB-head 不能发真实写，serial flush 可安全清除。把 sq_empty 加入这里
    // 会让 head CSR 与 younger speculative SQ entry 相互等待。
    .mem_quiet_i(mem_idle_o),
    .commit0_valid_o(commit0_valid_o),
    .commit0_producer_id_o(rob_commit0_producer_id_w),
    .commit0_pc_o(commit0_pc_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_is_fp_rd_o(commit0_is_fp_rd_w),
    .commit0_fflags_o(commit0_fflags_o),
    .commit0_arch_rd_o(commit0_arch_rd_o),
    .commit0_old_pdest_o(commit0_old_pdest_o),
    .commit0_new_pdest_o(commit0_new_pdest_o),
    .commit0_data_o(commit0_data_o),
    .commit0_exception_o(commit0_exception_o),
    .commit0_cause_o(commit0_cause_o),
    .commit0_tval_o(commit0_tval_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_producer_id_o(rob_commit1_producer_id_w),
    .commit1_pc_o(commit1_pc_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_is_fp_rd_o(commit1_is_fp_rd_w),
    .commit1_fflags_o(commit1_fflags_o),
    .commit1_arch_rd_o(commit1_arch_rd_o),
    .commit1_old_pdest_o(commit1_old_pdest_o),
    .commit1_new_pdest_o(commit1_new_pdest_o),
    .commit1_data_o(commit1_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_cause_o(commit1_cause_o),
    .commit1_tval_o(commit1_tval_o),
    .rob_head_idx_o(rob_head_idx_w),
    .rob_head_producer_id_o(rob_head_producer_id_w),
    .rob_head_launch_open_o(rob_head_launch_open_w),
    .rob_recover_active_o(rob_recover_active_w),
    .walk0_fp_valid_o(walk0_fp_valid_w),
    .walk0_fp_arch_o(walk0_fp_arch_w),
    .walk0_fp_old_pdest_o(walk0_fp_old_w),
    .walk0_fp_new_pdest_o(walk0_fp_new_w),
    .walk1_fp_valid_o(walk1_fp_valid_w),
    .walk1_fp_arch_o(walk1_fp_arch_w),
    .walk1_fp_old_pdest_o(walk1_fp_old_w),
    .walk1_fp_new_pdest_o(walk1_fp_new_w),
    .rob_head_valid_o(rob_head_valid_w),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
    .issue_count_o(issue_count_o)
	  );

  // ===========================================================================
  // T3S lane0 memory issue reservation
  // ---------------------------------------------------------------------------
  // IQ 中的 memory uop 只凭该寄存站的空 credit 离队；其 source value/control
  // 原子锁存后，下一拍再走 AGU、SQ/MIQ 顺序、SC reservation 与 bridge ready。
  // 这里刻意禁止 full+pop look-through：downstream late-ready 不能返回 IQ compact。
  // T3T 起 IQ 只允许“前方无更老 valid 项”的 memory 晋升，故驻留项不会挡住
  // 更老 raw uop；执行 owner 只读 reservation valid，不再组合读取 IQ select/年龄。
  // ===========================================================================
  reg [`XLEN-1:0] mem_issue_res_pc_q;
  reg [`XLEN-1:0] mem_issue_res_next_pc_q;
  reg [`XLEN-1:0] mem_issue_res_pred_npc_q;
  reg [`BPU_BHT_INDEX_W-1:0] mem_issue_res_bht_idx_q;
  reg mem_issue_res_pred_taken_q;
  reg [`INST_W-1:0] mem_issue_res_inst_q;
  reg [`CTRL_BUS_W-1:0] mem_issue_res_ctrl_q;
  wire [ROB_INDEX_W-1:0] mem_issue_res_rob_idx_q =
      mem_issue_res_producer_id_q[ROB_INDEX_W-1:0];
  reg [PHY_REG_ADDR_W-1:0] mem_issue_res_src1_preg_q;
  reg [PHY_REG_ADDR_W-1:0] mem_issue_res_src2_preg_q;
  reg [PHY_REG_ADDR_W-1:0] mem_issue_res_pdest_q;
  reg mem_issue_res_fp_pdest_q;
  reg mem_issue_res_fp_st_en_q;
  reg [PHY_REG_ADDR_W-1:0] mem_issue_res_fp_st_preg_q;
  reg [`XLEN-1:0] mem_issue_res_imm_q;
  reg [`XLEN-1:0] mem_issue_res_src1_data_q;
  reg [`XLEN-1:0] mem_issue_res_src2_data_q;
  reg [`XLEN-1:0] mem_issue_res_store_data_q;
  reg [1:0] mem_issue_res_owner_kind_q;
  reg [4:0] mem_issue_res_owner_token_q;
  reg [1:0] mem_issue_res_mmu_epoch_q;
  reg [`XLEN-1:0] mem_issue_res_fault_tval_q;

  // v8p terminal1 is a second complete, non-fallthrough memory reservation.
  // It captures only plain integer LOAD/STORE from IQ index1 as part of an
  // atomic memory-memory issue package.  AMO/LR/SC and FP memory remain owned
  // exclusively by terminal0.
  reg [`XLEN-1:0] mem_issue1_res_pc_q;
  reg [`XLEN-1:0] mem_issue1_res_next_pc_q;
  reg [`XLEN-1:0] mem_issue1_res_pred_npc_q;
  reg [`BPU_BHT_INDEX_W-1:0] mem_issue1_res_bht_idx_q;
  reg mem_issue1_res_pred_taken_q;
  reg [`INST_W-1:0] mem_issue1_res_inst_q;
  reg [`CTRL_BUS_W-1:0] mem_issue1_res_ctrl_q;
  wire [ROB_INDEX_W-1:0] mem_issue1_res_rob_idx_q =
      mem_issue1_res_producer_id_q[ROB_INDEX_W-1:0];
  reg [PHY_REG_ADDR_W-1:0] mem_issue1_res_src1_preg_q;
  reg [PHY_REG_ADDR_W-1:0] mem_issue1_res_src2_preg_q;
  reg [PHY_REG_ADDR_W-1:0] mem_issue1_res_pdest_q;
  reg mem_issue1_res_fp_pdest_q;
  reg mem_issue1_res_fp_st_en_q;
  reg [PHY_REG_ADDR_W-1:0] mem_issue1_res_fp_st_preg_q;
  reg [`XLEN-1:0] mem_issue1_res_imm_q;
  reg [`XLEN-1:0] mem_issue1_res_src1_data_q;
  reg [`XLEN-1:0] mem_issue1_res_src2_data_q;
  reg [`XLEN-1:0] mem_issue1_res_store_data_q;
  reg [1:0] mem_issue1_res_owner_kind_q;
  reg [4:0] mem_issue1_res_owner_token_q;
  reg [1:0] mem_issue1_res_mmu_epoch_q;
  reg [`XLEN-1:0] mem_issue1_res_fault_tval_q;

  // v8t/F3 one exact retry holder per physical bank.  These are not new
  // architectural owners: a query retry atomically moves the live token from
  // MIQ+bridge into this payload, and a later normal request fire moves it
  // back.  Keeping the complete MIQ payload avoids reconstruction from a
  // current request, IQ, SQ, or peer-bank bus.
  reg mem_retry0_valid_q;
  reg [PRODUCER_ID_W-1:0] mem_retry0_producer_id_q;
  reg [ROB_INDEX_W-1:0] mem_retry0_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem_retry0_pdest_q;
  reg mem_retry0_pdest_fp_q;
  reg [1:0] mem_retry0_size_q;
  reg mem_retry0_unsigned_q;
  reg [`XLEN-1:0] mem_retry0_addr_q;
  reg [`XLEN-1:0] mem_retry0_wdata_q;
  reg [`STRB_W-1:0] mem_retry0_wstrb_q;
  reg [1:0] mem_retry0_owner_kind_q;
  reg [4:0] mem_retry0_owner_token_q;
  reg [1:0] mem_retry0_mmu_epoch_q;
  reg [`XLEN-1:0] mem_retry0_fault_tval_q;

  reg mem_retry1_valid_q;
  reg [PRODUCER_ID_W-1:0] mem_retry1_producer_id_q;
  reg [ROB_INDEX_W-1:0] mem_retry1_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem_retry1_pdest_q;
  reg mem_retry1_pdest_fp_q;
  reg [1:0] mem_retry1_size_q;
  reg mem_retry1_unsigned_q;
  reg [`XLEN-1:0] mem_retry1_addr_q;
  reg [`XLEN-1:0] mem_retry1_wdata_q;
  reg [`STRB_W-1:0] mem_retry1_wstrb_q;
  reg [1:0] mem_retry1_owner_kind_q;
  reg [4:0] mem_retry1_owner_token_q;
  reg [1:0] mem_retry1_mmu_epoch_q;
  reg [`XLEN-1:0] mem_retry1_fault_tval_q;

  wire mem_sq_retry0_capture_w;
  wire mem_sq_retry1_capture_w;
  wire mem_retry0_req_fire_w;
  wire mem_retry1_req_fire_w;
  wire mem_retry0_selective_kill_w;
  wire mem_retry1_selective_kill_w;
  wire mem_retry0_global_cancel_w;
  wire mem_retry1_global_cancel_w;
  wire mem_retry0_cancel_w;
  wire mem_retry1_cancel_w;

  function [1:0] mem_owner_kind_from_ctrl;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
      mem_owner_kind_from_ctrl = ctrl[`CTRL_AMO_BIT] ? MEM_OWNER_ATOMIC :
          ctrl[`CTRL_STORE_BIT] ? MEM_OWNER_STORE : MEM_OWNER_LOAD;
    end
  endfunction

  wire iq_issue0_mem_class_w =
      iq_issue0_valid_w &&
      (iq_issue0_ctrl_w[`CTRL_LOAD_BIT] ||
       iq_issue0_ctrl_w[`CTRL_STORE_BIT] ||
       iq_issue0_ctrl_w[`CTRL_AMO_BIT]);
  wire iq_issue0_plain_mem_class_w = iq_issue0_mem_class_w &&
      !iq_issue0_ctrl_w[`CTRL_AMO_BIT] &&
      !iq_issue0_fp_pdest_w && !iq_issue0_fp_st_en_w;
  wire iq_issue1_plain_mem_class_w = issue1_valid_w &&
      (issue1_ctrl_w[`CTRL_LOAD_BIT] ||
       issue1_ctrl_w[`CTRL_STORE_BIT]) &&
      !issue1_ctrl_w[`CTRL_AMO_BIT] &&
      !issue1_fp_pdest_w && !issue1_fp_st_en_w;
  wire iq_memory_pair_w = iq_issue0_plain_mem_class_w &&
                          iq_issue1_plain_mem_class_w;
  wire mem_issue_res_consume_fire_w;
  wire mem_issue1_res_consume_fire_w;
  // v8u/F4: while both physical memory terminals hold ordinary Q owners, the
  // IQ may expose its registered entries 0/1 on a dedicated pair-peek face.
  // This enable is Q-only; bridge READY and consume never enter the selector.
  assign iq_memory_pair_peek_enable_w = ENABLE_DUAL_MEM &&
      mem_issue_res_valid_q && mem_issue1_res_valid_q &&
      !mem_issue_res_ctrl_q[`CTRL_AMO_BIT] &&
      !mem_issue1_res_ctrl_q[`CTRL_AMO_BIT] &&
      !mem_issue_res_fp_pdest_q && !mem_issue_res_fp_st_en_q &&
      !mem_issue1_res_fp_pdest_q && !mem_issue1_res_fp_st_en_q;
  wire mem_issue_res_credit_w =
      !mem_issue_res_valid_q &&
      !rst && !flush_i &&
      !checkpoint_restore_hold_w && !checkpoint_capture_i &&
      !checkpoint_quiesce_i && !mem_issue_block_w &&
      !branch_resolve_mispredict_w;
  wire mem_issue1_res_credit_w =
      !mem_issue1_res_valid_q &&
      !rst && !flush_i &&
      !checkpoint_restore_hold_w && !checkpoint_capture_i &&
      !checkpoint_quiesce_i && !mem_issue_block_w &&
      !branch_resolve_mispredict_w;
  // AMO/LR/SC 本就要求独占并在 ROB head 执行；禁止它们提前占住单槽，既
  // 缩短驻留时间，也从准入侧消除 younger LR 等 head 的年龄倒置反例。
  // queue-head CSR 模式下进一步把所有 memory admission 收紧到 ROB head：
  // 较老 CSR 会等 mem_idle，而 reservation 也计入 mem_idle；若 younger load
  // 能先驻留，两者会互等。默认模式常量折叠后仍仅 AMO 受 head gate，不添路径。
  wire mem_issue_res_requires_head_w =
      iq_issue0_ctrl_w[`CTRL_AMO_BIT] || `OOO_CSR_QUEUE_HEAD;
  wire mem_issue_res_admit_w =
      !mem_issue_res_requires_head_w ||
      (rob_head_valid_w && (iq_issue0_rob_idx_w == rob_head_idx_w));
  wire mem_issue1_res_admit_w =
      !`OOO_CSR_QUEUE_HEAD ||
      (rob_head_valid_w && (issue1_rob_idx_w == rob_head_idx_w));
  // In a capability-swapped pair, issue0 is a younger complex uop while
  // issue1 is its older independent ALU partner.  A younger memory may enter
  // the registered reservation only when that older ALU actually fires.
  wire iq_issue0_swapped_memory_w =
      iq_issue_pair_swapped_w && iq_issue0_mem_class_w;
  // The swapped partner is necessarily the simple-ALU terminal.  Spell its
  // actual fire from that arm's local resource facts instead of reading the
  // generic issue1_ready mux, whose memory-pair arm reads tracker allocation
  // readiness and would form a structurally visible (though class-exclusive)
  // combinational cycle back into alloc0_valid.
  wire issue1_swapped_partner_fire_w = issue1_valid_w &&
      !iq_issue1_plain_mem_class_w && !mem_issue1_res_valid_q &&
      !flush_i && !checkpoint_restore_hold_w && !issue_block_w &&
      !mem_rsp_waiting_for_wb_w;
  wire mem_owner_alloc0_ready_w;
  wire [4:0] mem_owner_alloc0_token_w;
  wire mem_owner_alloc1_ready_w;
  wire [4:0] mem_owner_alloc1_token_w;
  wire [31:0] mem_owner_live_mask_w;
  wire [63:0] mem_owner_kind_table_w;
  wire [63:0] mem_owner_epoch_table_w;
  wire [32*PRODUCER_ID_W-1:0] mem_owner_producer_id_table_w;
  wire [5:0] mem_owner_live_count_w;
  wire [31:0] mem_terminal_pending_mask_w;
  wire [5:0] mem_terminal_pending_count_w;
  wire mem_terminal_deq0_valid_w;
  wire [1:0] mem_terminal_deq0_kind_w;
  wire [4:0] mem_terminal_deq0_token_w;
  wire [1:0] mem_terminal_deq0_epoch_w;
  wire mem_terminal_deq0_ready_w;
  wire mem_terminal_deq1_valid_w;
  wire [1:0] mem_terminal_deq1_kind_w;
  wire [4:0] mem_terminal_deq1_token_w;
  wire [1:0] mem_terminal_deq1_epoch_w;
  wire mem_terminal_deq1_ready_w;
  wire [11:0] mem_terminal_ingress_valid_w;
  wire [23:0] mem_terminal_ingress_kind_w;
  wire [59:0] mem_terminal_ingress_token_w;
  wire [23:0] mem_terminal_ingress_epoch_w;
  wire [31:0] mem_terminal_ingress0_mask_w;
  wire [31:0] mem_terminal_ingress1_mask_w;
  wire [31:0] mem_terminal_ingress2_mask_w;
  wire [31:0] mem_terminal_ingress3_mask_w;
  wire [31:0] mem_terminal_ingress4_mask_w;
  wire [31:0] mem_terminal_ingress5_mask_w;
  wire [31:0] mem_terminal_ingress6_mask_w;
  wire [31:0] mem_terminal_ingress7_mask_w;
  wire [31:0] mem_terminal_ingress8_mask_w;
  wire [31:0] mem_terminal_ingress9_mask_w;
  wire [31:0] mem_terminal_ingress10_mask_w;
  wire [31:0] mem_terminal_ingress11_mask_w;
  wire [31:0] mem_terminal_ingress_mask_w;
  wire [31:0] sq_owner_release_effective_mask_w;
  // The two existing SQ terminal CAM ports are globally allocated across the
  // two non-backpressurable local exception sources and the two response
  // sources.  Declarations live here because response READY consumes the raw
  // grants before the SQ payload mux is instantiated later in the module.
  wire sq_local_store_exception0_w;
  wire sq_local_store_exception1_w;
  wire mem_issue_res_dual_local_consume_w;
  wire mem_issue1_res_dual_local_consume_w;
  wire mem_rsp_waiting_for_wb_w;
  wire mem_sq_response_candidate_w;
  wire mem1_sq_response_candidate_w;
  wire mem_sq_response_grant_w;
  wire mem1_sq_response_grant_w;
  wire mem_issue_pair_base_candidate_w =
      iq_memory_pair_w && mem_issue_res_credit_w &&
      mem_issue1_res_credit_w && mem_issue_res_admit_w &&
      mem_issue1_res_admit_w;
  wire mem_issue_pair_capture_candidate_w =
      mem_issue_pair_base_candidate_w &&
      iq_issue0_producer_current_w && issue1_producer_current_w;
  wire mem_issue_pair_capture_w =
      mem_issue_pair_capture_candidate_w &&
      mem_owner_alloc0_ready_w && mem_owner_alloc1_ready_w;
  // The dedicated pair-peek payload remains a registered IQ observation.
  // Only an exact edge-old dual consume may turn it into two new reservation
  // owners; tracker allocation and dequeue remain pair-atomic.
  wire mem_issue_pair_turnover_base_candidate_w =
      iq_memory_pair_peek_valid_w &&
      mem_issue_res_consume_fire_w && mem_issue1_res_consume_fire_w &&
      mem_issue_res_admit_w && mem_issue1_res_admit_w &&
      !rst && !flush_i && !checkpoint_restore_hold_w &&
      !checkpoint_capture_i && !checkpoint_quiesce_i &&
      !mem_issue_block_w && !branch_resolve_mispredict_w;
  wire mem_issue_pair_turnover_capture_candidate_w =
      mem_issue_pair_turnover_base_candidate_w &&
      iq_issue0_producer_current_w && issue1_producer_current_w;
  wire mem_issue_pair_turnover_capture_w =
      mem_issue_pair_turnover_capture_candidate_w &&
      mem_owner_alloc0_ready_w && mem_owner_alloc1_ready_w;
  assign iq_memory_pair_peek_ready_w =
      mem_issue_pair_turnover_capture_w;
  wire mem_issue_pair_stale0_drop_w = iq_memory_pair_w &&
      mem_issue_res_credit_w && mem_issue1_res_credit_w &&
      !iq_issue0_producer_current_w;
  wire mem_issue_pair_stale1_drop_w = iq_memory_pair_w &&
      mem_issue_res_credit_w && mem_issue1_res_credit_w &&
      !issue1_producer_current_w;
  wire mem_issue_res_present_candidate_w =
      iq_issue0_mem_class_w && mem_issue_res_credit_w &&
      !iq_memory_pair_w &&
      mem_issue_res_admit_w &&
      (!iq_issue0_swapped_memory_w || issue1_swapped_partner_fire_w);
  wire mem_issue_res_capture_candidate_w =
      (mem_issue_res_present_candidate_w && iq_issue0_producer_current_w) ||
      mem_issue_pair_capture_candidate_w ||
      mem_issue_pair_turnover_capture_candidate_w;
  wire mem_issue1_res_capture_candidate_w =
      mem_issue_pair_capture_candidate_w ||
      mem_issue_pair_turnover_capture_candidate_w;
  wire mem_issue_res_stale_drop_w =
      mem_issue_res_present_candidate_w && !iq_issue0_producer_current_w;
  wire mem_issue_res_capture_w =
      mem_issue_res_capture_candidate_w && mem_owner_alloc0_ready_w &&
      (!mem_issue1_res_capture_candidate_w || mem_owner_alloc1_ready_w);
  wire mem_issue1_res_capture_w =
      mem_issue1_res_capture_candidate_w && mem_owner_alloc0_ready_w &&
      mem_owner_alloc1_ready_w;

  // raw non-memory 的 ready 锥只含全局门控及其自身 long-op resource，禁止复用
  // issue0_ready_w；后者含 AGU/SQ/MIQ/SC 深组合谓词，会重新回接 IQ compact。
  wire iq_issue0_raw_is_clmul_w =
      iq_issue0_ctrl_w[`CTRL_BITMANIP_BIT] &&
      (iq_issue0_inst_w[6:0] == `OPCODE_OP) &&
      (iq_issue0_inst_w[31:25] == 7'h05) &&
      ((iq_issue0_inst_w[14:12] == `FUNCT3_SLL) ||
       (iq_issue0_inst_w[14:12] == `FUNCT3_SLT) ||
       (iq_issue0_inst_w[14:12] == `FUNCT3_SLTU));
  wire iq_issue0_raw_global_ready_w =
      !flush_i && !checkpoint_restore_hold_w &&
      !checkpoint_capture_i && !checkpoint_quiesce_i;
  wire iq_issue0_raw_nonmem_ready_w =
      iq_issue0_raw_global_ready_w &&
      (!iq_issue0_ctrl_w[`CTRL_MULDIV_BIT] || muldiv_req_ready_w) &&
      (!iq_issue0_raw_is_clmul_w || clmul_req_ready_w);

  wire mem_issue_res_exec_owner_w = mem_issue_res_valid_q;
  wire iq_issue0_raw_exec_owner_w =
      iq_issue0_valid_w && !iq_issue0_mem_class_w &&
      !mem_issue_res_valid_q;

  // reservation 占用时 raw IQ 冻结；该驻留项在 capture 时已证明无更老 raw。
  assign iq_issue0_ready_w =
      !branch_resolve_mispredict_w &&
      (mem_issue_res_valid_q ? 1'b0 :
       iq_memory_pair_w ?
         ((iq_issue0_producer_current_w && issue1_producer_current_w) ?
            mem_issue_pair_capture_w : mem_issue_pair_stale0_drop_w) :
       iq_issue0_mem_class_w ?
         (mem_issue_res_credit_w && mem_issue_res_admit_w &&
          (!iq_issue0_swapped_memory_w || issue1_fire_w) &&
          (iq_issue0_producer_current_w ? mem_owner_alloc0_ready_w :
                                          1'b1)) :
                               iq_issue0_raw_nonmem_ready_w);

  // T3V：generic issue0 数据面只承载 raw non-memory。memory reservation 不再
  // 回灌这组 mux/PRF/ALU0，而是在下方使用独立 Q→AGU→LSU 数据面。这样不仅
  // capture 拍无 early execute，驻留拍也不存在 IQ/PRF/ALU0→request/MIQ 假路径。
  assign issue0_valid_w =
      !branch_resolve_mispredict_w && iq_issue0_raw_exec_owner_w;
  assign issue0_pc_w = iq_issue0_pc_w;
  assign issue0_next_pc_w = iq_issue0_next_pc_w;
  assign issue0_pred_npc_w = iq_issue0_pred_npc_w;
  assign issue0_bht_idx_w = iq_issue0_bht_idx_w;
  assign issue0_pred_taken_w = iq_issue0_pred_taken_w;
  assign issue0_inst_w = iq_issue0_inst_w;
  assign issue0_ctrl_w = iq_issue0_ctrl_w;
  assign issue0_rob_idx_w = iq_issue0_rob_idx_w;
  assign issue0_src1_preg_w = iq_issue0_src1_preg_w;
  assign issue0_src2_preg_w = iq_issue0_src2_preg_w;
  assign issue0_pdest_w = iq_issue0_pdest_w;
  assign issue0_fp_pdest_w = iq_issue0_fp_pdest_w;
  assign issue0_fp_st_en_w = iq_issue0_fp_st_en_w;
  assign issue0_fp_st_preg_w = iq_issue0_fp_st_preg_w;
  assign issue0_imm_w = iq_issue0_imm_w;

  wire [`XLEN-1:0] issue0_src1_data_w;
  wire [`XLEN-1:0] issue0_src2_data_w;
  wire [`XLEN-1:0] iq_issue0_src1_data_w;
  wire [`XLEN-1:0] iq_issue0_src2_data_w;
  wire [`XLEN-1:0] issue1_src1_data_w;
  wire [`XLEN-1:0] issue1_src2_data_w;
  // Wave4b 删除：dispatch 拍分支快解析全族（candidate/src/value/FAST_BRANCH_TRACK/
  // CompareUnit/PRF read4-5）——`!(`OOO_DBRANCH_DOMAIN_A)` 恒 0 证死。分支恒经 IQ →
  // issue-resolve → 强制 mispredict + ROB-walk kill（活 F2 路径，不受本次删除影响）。

  OooPhysRegFile #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_phys_reg_file (
    .clk(clk),
    .rst(rst),
    .recover_i(flush_i || checkpoint_restore_apply_w),
    .recover_gprs_i(recover_gprs_i),
    .read0_addr_i(iq_issue0_src1_preg_w),
    .read0_data_o(iq_issue0_src1_data_w),
    .read1_addr_i(iq_issue0_src2_preg_w),
    .read1_data_o(iq_issue0_src2_data_w),
    .read2_addr_i(issue1_src1_preg_w),
    .read2_data_o(issue1_src1_data_w),
    .read3_addr_i(issue1_src2_preg_w),
    .read3_data_o(issue1_src2_data_w),
    .read8_addr_i(fp_gpr_read_addr_w),
    .read8_data_o(fp_gpr_read_data_w),
    .write0_valid_i(gpr_wb0_write_valid_w),
    .write0_addr_i(wb0_pdest_w),
    .write0_data_i(wb0_data_w),
    .write1_valid_i(gpr_wb1_write_valid_w),
    .write1_addr_i(wb1_pdest_w),
    .write1_data_i(wb1_data_w)
  );

  // R3.2 forwarding is strictly EX-register -> consumer.  PRF remains
  // stored-only; no WB/result combinational arm is added inside the PRF.
  wire ex0_registered_fwd_valid_w =
      ex0_wb_valid_w && ex0_down_payload_w[EX_STAGE_FWD_BIT];
  wire ex1_registered_fwd_valid_w =
      ex1_wb_valid_w && ex1_down_payload_w[EX_STAGE_FWD_BIT];
  wire [PHY_REG_ADDR_W-1:0] ex0_registered_fwd_pdest_w =
      ex0_down_payload_w[EX_STAGE_PDEST_MSB:EX_STAGE_PDEST_LSB];
  wire [PHY_REG_ADDR_W-1:0] ex1_registered_fwd_pdest_w =
      ex1_down_payload_w[EX_STAGE_PDEST_MSB:EX_STAGE_PDEST_LSB];
  wire [`XLEN-1:0] ex0_registered_fwd_data_w =
      ex0_down_payload_w[EX_STAGE_RESULT_MSB:EX_STAGE_RESULT_LSB];
  wire [`XLEN-1:0] ex1_registered_fwd_data_w =
      ex1_down_payload_w[EX_STAGE_RESULT_MSB:EX_STAGE_RESULT_LSB];

  wire issue0_src1_ex0_fwd_hit_w =
      ex0_registered_fwd_valid_w &&
      (iq_issue0_src1_preg_w != {PHY_REG_ADDR_W{1'b0}}) &&
      (iq_issue0_src1_preg_w == ex0_registered_fwd_pdest_w);
  wire issue0_src1_ex1_fwd_hit_w =
      ex1_registered_fwd_valid_w &&
      (iq_issue0_src1_preg_w != {PHY_REG_ADDR_W{1'b0}}) &&
      (iq_issue0_src1_preg_w == ex1_registered_fwd_pdest_w);
  wire issue0_src2_ex0_fwd_hit_w =
      ex0_registered_fwd_valid_w &&
      (iq_issue0_src2_preg_w != {PHY_REG_ADDR_W{1'b0}}) &&
      (iq_issue0_src2_preg_w == ex0_registered_fwd_pdest_w);
  wire issue0_src2_ex1_fwd_hit_w =
      ex1_registered_fwd_valid_w &&
      (iq_issue0_src2_preg_w != {PHY_REG_ADDR_W{1'b0}}) &&
      (iq_issue0_src2_preg_w == ex1_registered_fwd_pdest_w);
  wire issue1_src1_ex0_fwd_hit_w =
      ex0_registered_fwd_valid_w &&
      (issue1_src1_preg_w != {PHY_REG_ADDR_W{1'b0}}) &&
      (issue1_src1_preg_w == ex0_registered_fwd_pdest_w);
  wire issue1_src1_ex1_fwd_hit_w =
      ex1_registered_fwd_valid_w &&
      (issue1_src1_preg_w != {PHY_REG_ADDR_W{1'b0}}) &&
      (issue1_src1_preg_w == ex1_registered_fwd_pdest_w);
  wire issue1_src2_ex0_fwd_hit_w =
      ex0_registered_fwd_valid_w &&
      (issue1_src2_preg_w != {PHY_REG_ADDR_W{1'b0}}) &&
      (issue1_src2_preg_w == ex0_registered_fwd_pdest_w);
  wire issue1_src2_ex1_fwd_hit_w =
      ex1_registered_fwd_valid_w &&
      (issue1_src2_preg_w != {PHY_REG_ADDR_W{1'b0}}) &&
      (issue1_src2_preg_w == ex1_registered_fwd_pdest_w);

  // Match write-port priority: ex1 wins only in the architecturally illegal
  // duplicate-pdest case, making the failure deterministic for assertions.
  assign issue0_src1_data_w =
      issue0_src1_ex1_fwd_hit_w ? ex1_registered_fwd_data_w :
      issue0_src1_ex0_fwd_hit_w ? ex0_registered_fwd_data_w :
                                  iq_issue0_src1_data_w;
  assign issue0_src2_data_w =
      issue0_src2_ex1_fwd_hit_w ? ex1_registered_fwd_data_w :
      issue0_src2_ex0_fwd_hit_w ? ex0_registered_fwd_data_w :
                                  iq_issue0_src2_data_w;
  wire [`XLEN-1:0] issue1_src1_value_w =
      issue1_src1_ex1_fwd_hit_w ? ex1_registered_fwd_data_w :
      issue1_src1_ex0_fwd_hit_w ? ex0_registered_fwd_data_w :
                                  issue1_src1_data_w;
  wire [`XLEN-1:0] issue1_src2_value_w =
      issue1_src2_ex1_fwd_hit_w ? ex1_registered_fwd_data_w :
      issue1_src2_ex0_fwd_hit_w ? ex0_registered_fwd_data_w :
                                  issue1_src2_data_w;

  wire mem_issue_res_kill_w =
      branch_resolve_mispredict_w && mem_issue_res_valid_q &&
      ((mem_issue_res_rob_idx_q - rob_head_idx_w) >
       (branch_resolve_rob_idx_o - rob_head_idx_w));
  wire mem_issue1_res_kill_w =
      branch_resolve_mispredict_w && mem_issue1_res_valid_q &&
      ((mem_issue1_res_rob_idx_q - rob_head_idx_w) >
       (branch_resolve_rob_idx_o - rob_head_idx_w));
  wire issue0_mem_request_fire_w;
  wire issue1_mem_request_fire_w;

  always @(posedge clk) begin
    if (rst || flush_i || checkpoint_restore_apply_w) begin
      mem_issue_res_valid_q <= 1'b0;
      mem_issue_res_pc_q <= {`XLEN{1'b0}};
      mem_issue_res_next_pc_q <= {`XLEN{1'b0}};
      mem_issue_res_pred_npc_q <= {`XLEN{1'b0}};
      mem_issue_res_bht_idx_q <= {`BPU_BHT_INDEX_W{1'b0}};
      mem_issue_res_pred_taken_q <= 1'b0;
      mem_issue_res_inst_q <= {`INST_W{1'b0}};
      mem_issue_res_ctrl_q <= {`CTRL_BUS_W{1'b0}};
      mem_issue_res_producer_id_q <= {PRODUCER_ID_W{1'b0}};
      mem_issue_res_src1_preg_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_issue_res_src2_preg_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_issue_res_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_issue_res_fp_pdest_q <= 1'b0;
      mem_issue_res_fp_st_en_q <= 1'b0;
      mem_issue_res_fp_st_preg_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_issue_res_imm_q <= {`XLEN{1'b0}};
      mem_issue_res_src1_data_q <= {`XLEN{1'b0}};
      mem_issue_res_src2_data_q <= {`XLEN{1'b0}};
      mem_issue_res_store_data_q <= {`XLEN{1'b0}};
      mem_issue_res_owner_kind_q <= MEM_OWNER_RESERVED;
      mem_issue_res_owner_token_q <= 5'b0;
      mem_issue_res_mmu_epoch_q <= MEM_OWNER_EPOCH_BASE;
      mem_issue_res_fault_tval_q <= {`XLEN{1'b0}};
    end else if (mem_issue_res_kill_w) begin
      mem_issue_res_valid_q <= 1'b0;
    end else if (mem_issue_res_capture_w) begin
      mem_issue_res_valid_q <= 1'b1;
      mem_issue_res_pc_q <= iq_issue0_pc_w;
      mem_issue_res_next_pc_q <= iq_issue0_next_pc_w;
      mem_issue_res_pred_npc_q <= iq_issue0_pred_npc_w;
      mem_issue_res_bht_idx_q <= iq_issue0_bht_idx_w;
      mem_issue_res_pred_taken_q <= iq_issue0_pred_taken_w;
      mem_issue_res_inst_q <= iq_issue0_inst_w;
      mem_issue_res_ctrl_q <= iq_issue0_ctrl_w;
      mem_issue_res_producer_id_q <= iq_issue0_producer_id_w;
      mem_issue_res_src1_preg_q <= iq_issue0_src1_preg_w;
      mem_issue_res_src2_preg_q <= iq_issue0_src2_preg_w;
      mem_issue_res_pdest_q <= iq_issue0_pdest_w;
      mem_issue_res_fp_pdest_q <= iq_issue0_fp_pdest_w;
      mem_issue_res_fp_st_en_q <= iq_issue0_fp_st_en_w;
      mem_issue_res_fp_st_preg_q <= iq_issue0_fp_st_preg_w;
      mem_issue_res_imm_q <= iq_issue0_imm_w;
      mem_issue_res_src1_data_q <= issue0_src1_data_w;
      mem_issue_res_src2_data_q <= issue0_src2_data_w;
      mem_issue_res_store_data_q <= iq_issue0_fp_st_en_w ?
                                    fpst_read_data_w :
                                    issue0_src2_data_w;
      mem_issue_res_owner_kind_q <=
          mem_owner_kind_from_ctrl(iq_issue0_ctrl_w);
      mem_issue_res_owner_token_q <= mem_owner_alloc0_token_w;
      mem_issue_res_mmu_epoch_q <= MEM_OWNER_EPOCH_BASE;
      mem_issue_res_fault_tval_q <= issue0_src1_data_w + iq_issue0_imm_w;
    end else if (mem_issue_res_consume_fire_w) begin
      mem_issue_res_valid_q <= 1'b0;
    end
  end

  always @(posedge clk) begin
    if (rst || flush_i || checkpoint_restore_apply_w) begin
      mem_issue1_res_valid_q <= 1'b0;
      mem_issue1_res_pc_q <= {`XLEN{1'b0}};
      mem_issue1_res_next_pc_q <= {`XLEN{1'b0}};
      mem_issue1_res_pred_npc_q <= {`XLEN{1'b0}};
      mem_issue1_res_bht_idx_q <= {`BPU_BHT_INDEX_W{1'b0}};
      mem_issue1_res_pred_taken_q <= 1'b0;
      mem_issue1_res_inst_q <= {`INST_W{1'b0}};
      mem_issue1_res_ctrl_q <= {`CTRL_BUS_W{1'b0}};
      mem_issue1_res_producer_id_q <= {PRODUCER_ID_W{1'b0}};
      mem_issue1_res_src1_preg_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_issue1_res_src2_preg_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_issue1_res_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_issue1_res_fp_pdest_q <= 1'b0;
      mem_issue1_res_fp_st_en_q <= 1'b0;
      mem_issue1_res_fp_st_preg_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_issue1_res_imm_q <= {`XLEN{1'b0}};
      mem_issue1_res_src1_data_q <= {`XLEN{1'b0}};
      mem_issue1_res_src2_data_q <= {`XLEN{1'b0}};
      mem_issue1_res_store_data_q <= {`XLEN{1'b0}};
      mem_issue1_res_owner_kind_q <= MEM_OWNER_RESERVED;
      mem_issue1_res_owner_token_q <= 5'b0;
      mem_issue1_res_mmu_epoch_q <= MEM_OWNER_EPOCH_BASE;
      mem_issue1_res_fault_tval_q <= {`XLEN{1'b0}};
    end else if (mem_issue1_res_kill_w) begin
      mem_issue1_res_valid_q <= 1'b0;
    end else if (mem_issue1_res_capture_w) begin
      mem_issue1_res_valid_q <= 1'b1;
      mem_issue1_res_pc_q <= issue1_pc_w;
      mem_issue1_res_next_pc_q <= issue1_next_pc_w;
      mem_issue1_res_pred_npc_q <= issue1_pred_npc_w;
      mem_issue1_res_bht_idx_q <= issue1_bht_idx_w;
      mem_issue1_res_pred_taken_q <= issue1_pred_taken_w;
      mem_issue1_res_inst_q <= issue1_inst_w;
      mem_issue1_res_ctrl_q <= issue1_ctrl_w;
      mem_issue1_res_producer_id_q <= issue1_producer_id_w;
      mem_issue1_res_src1_preg_q <= issue1_src1_preg_w;
      mem_issue1_res_src2_preg_q <= issue1_src2_preg_w;
      mem_issue1_res_pdest_q <= issue1_pdest_w;
      mem_issue1_res_fp_pdest_q <= issue1_fp_pdest_w;
      mem_issue1_res_fp_st_en_q <= issue1_fp_st_en_w;
      mem_issue1_res_fp_st_preg_q <= issue1_fp_st_preg_w;
      mem_issue1_res_imm_q <= issue1_imm_w;
      mem_issue1_res_src1_data_q <= issue1_src1_value_w;
      mem_issue1_res_src2_data_q <= issue1_src2_value_w;
      mem_issue1_res_store_data_q <= issue1_src2_value_w;
      mem_issue1_res_owner_kind_q <=
          mem_owner_kind_from_ctrl(issue1_ctrl_w);
      mem_issue1_res_owner_token_q <= mem_owner_alloc1_token_w;
      mem_issue1_res_mmu_epoch_q <= MEM_OWNER_EPOCH_BASE;
      mem_issue1_res_fault_tval_q <= issue1_src1_value_w + issue1_imm_w;
    end else if (mem_issue1_res_consume_fire_w) begin
      mem_issue1_res_valid_q <= 1'b0;
    end
  end

`ifdef OOO_ASSERT
  localparam integer MEM_ISSUE_RES_PAYLOAD_W =
      (7 * `XLEN) + `BPU_BHT_INDEX_W + `INST_W + `CTRL_BUS_W +
      PRODUCER_ID_W + (4 * PHY_REG_ADDR_W) + 3;
  wire [MEM_ISSUE_RES_PAYLOAD_W-1:0] mem_issue_res_payload_w =
      {mem_issue_res_pc_q, mem_issue_res_next_pc_q,
       mem_issue_res_pred_npc_q, mem_issue_res_bht_idx_q,
       mem_issue_res_pred_taken_q, mem_issue_res_inst_q,
       mem_issue_res_ctrl_q, mem_issue_res_producer_id_q,
       mem_issue_res_src1_preg_q, mem_issue_res_src2_preg_q,
       mem_issue_res_pdest_q, mem_issue_res_fp_pdest_q,
       mem_issue_res_fp_st_en_q, mem_issue_res_fp_st_preg_q,
       mem_issue_res_imm_q, mem_issue_res_src1_data_q,
       mem_issue_res_src2_data_q, mem_issue_res_store_data_q};
  wire [MEM_ISSUE_RES_PAYLOAD_W-1:0] mem_issue_res_capture_payload_w =
      {iq_issue0_pc_w, iq_issue0_next_pc_w, iq_issue0_pred_npc_w,
       iq_issue0_bht_idx_w, iq_issue0_pred_taken_w, iq_issue0_inst_w,
       iq_issue0_ctrl_w, iq_issue0_producer_id_w,
       iq_issue0_src1_preg_w, iq_issue0_src2_preg_w,
       iq_issue0_pdest_w, iq_issue0_fp_pdest_w,
       iq_issue0_fp_st_en_w, iq_issue0_fp_st_preg_w,
       iq_issue0_imm_w, issue0_src1_data_w,
       issue0_src2_data_w,
       iq_issue0_fp_st_en_w ? fpst_read_data_w : issue0_src2_data_w};
  reg mem_issue_res_capture_shadow_q;
  reg mem_issue_res_hold_shadow_q;
  reg [MEM_ISSUE_RES_PAYLOAD_W-1:0] mem_issue_res_capture_expect_q;
  reg [MEM_ISSUE_RES_PAYLOAD_W-1:0] mem_issue_res_hold_expect_q;
  wire [MEM_ISSUE_RES_PAYLOAD_W-1:0] mem_issue1_res_payload_w =
      {mem_issue1_res_pc_q, mem_issue1_res_next_pc_q,
       mem_issue1_res_pred_npc_q, mem_issue1_res_bht_idx_q,
       mem_issue1_res_pred_taken_q, mem_issue1_res_inst_q,
       mem_issue1_res_ctrl_q, mem_issue1_res_producer_id_q,
       mem_issue1_res_src1_preg_q, mem_issue1_res_src2_preg_q,
       mem_issue1_res_pdest_q, mem_issue1_res_fp_pdest_q,
       mem_issue1_res_fp_st_en_q, mem_issue1_res_fp_st_preg_q,
       mem_issue1_res_imm_q, mem_issue1_res_src1_data_q,
       mem_issue1_res_src2_data_q, mem_issue1_res_store_data_q};
  wire [MEM_ISSUE_RES_PAYLOAD_W-1:0] mem_issue1_res_capture_payload_w =
      {issue1_pc_w, issue1_next_pc_w, issue1_pred_npc_w,
       issue1_bht_idx_w, issue1_pred_taken_w, issue1_inst_w,
       issue1_ctrl_w, issue1_producer_id_w,
       issue1_src1_preg_w, issue1_src2_preg_w,
       issue1_pdest_w, issue1_fp_pdest_w,
       issue1_fp_st_en_w, issue1_fp_st_preg_w,
       issue1_imm_w, issue1_src1_value_w,
       issue1_src2_value_w, issue1_src2_value_w};
  reg mem_issue1_res_capture_shadow_q;
  reg mem_issue1_res_hold_shadow_q;
  reg [MEM_ISSUE_RES_PAYLOAD_W-1:0] mem_issue1_res_capture_expect_q;
  reg [MEM_ISSUE_RES_PAYLOAD_W-1:0] mem_issue1_res_hold_expect_q;

  always @(posedge clk) begin
    if (rst) begin
      mem_issue_res_capture_shadow_q <= 1'b0;
      mem_issue_res_hold_shadow_q <= 1'b0;
      mem_issue_res_capture_expect_q <= {MEM_ISSUE_RES_PAYLOAD_W{1'b0}};
      mem_issue_res_hold_expect_q <= {MEM_ISSUE_RES_PAYLOAD_W{1'b0}};
      mem_issue1_res_capture_shadow_q <= 1'b0;
      mem_issue1_res_hold_shadow_q <= 1'b0;
      mem_issue1_res_capture_expect_q <= {MEM_ISSUE_RES_PAYLOAD_W{1'b0}};
      mem_issue1_res_hold_expect_q <= {MEM_ISSUE_RES_PAYLOAD_W{1'b0}};
    end else begin
      if (mem_issue_res_capture_shadow_q &&
          (!mem_issue_res_valid_q ||
           (mem_issue_res_payload_w !== mem_issue_res_capture_expect_q)))
        $error("[T3S-MEM-RES-CAPTURE] capture payload/valid mismatch @%0t",
               $time);
      if (mem_issue_res_hold_shadow_q &&
          (!mem_issue_res_valid_q ||
           (mem_issue_res_payload_w !== mem_issue_res_hold_expect_q)))
        $error("[T3S-MEM-RES-HOLD] stalled reservation changed @%0t",
               $time);
      if (mem_issue_res_valid_q && iq_issue0_ready_w)
        $error("[T3S-MEM-RES-NON-FALLTHROUGH] occupied station exposed IQ ready @%0t",
               $time);
      if (mem_issue_res_valid_q && mem_issue_res_capture_w &&
          !mem_issue_pair_turnover_capture_w)
        $error("[V8U-MEM-RES-TURNOVER-SOURCE] occupied station captured without exact pair-peek turnover @%0t",
               $time);
      if (mem_issue_pair_turnover_capture_w &&
          (mem_issue_res_capture_w != mem_issue1_res_capture_w))
        $error("[V8U-MEM-RES-TURNOVER-ATOMIC] pair turnover capture diverged @%0t",
               $time);
      if (mem_issue_pair_turnover_capture_w &&
          (!iq_memory_pair_peek_enable_w ||
           !iq_memory_pair_peek_valid_w ||
           !mem_issue_res_valid_q || !mem_issue1_res_valid_q ||
           !mem_issue_res_consume_fire_w ||
           !mem_issue1_res_consume_fire_w ||
           !iq_issue0_producer_current_w ||
           !issue1_producer_current_w ||
           !mem_owner_alloc0_ready_w || !mem_owner_alloc1_ready_w ||
           flush_i || checkpoint_restore_hold_w || checkpoint_capture_i ||
           checkpoint_quiesce_i || branch_resolve_mispredict_w))
        $error("[V8U-MEM-RES-TURNOVER-QUAL] turnover lacked exact old-Q consume, current peek identities, dual tracker credit, or recovery quiet @%0t",
               $time);
      if (iq_memory_pair_peek_ready_w !=
          mem_issue_pair_turnover_capture_w)
        $error("[V8U-MEM-RES-TURNOVER-DEQUEUE] IQ pair dequeue diverged from dual reservation capture @%0t",
               $time);
      if (mem_issue_res_capture_w && issue0_valid_w)
        $error("[T3S-MEM-RES-NO-EARLY-EXEC] raw memory reached execution on capture @%0t",
               $time);
      if (mem_issue_res_valid_q &&
          !(mem_issue_res_ctrl_q[`CTRL_LOAD_BIT] ||
            mem_issue_res_ctrl_q[`CTRL_STORE_BIT] ||
            mem_issue_res_ctrl_q[`CTRL_AMO_BIT]))
        $error("[T3S-MEM-RES-CLASS] non-memory payload resident @%0t", $time);
      if (mem_issue_res_valid_q && mem_issue_res_ctrl_q[`CTRL_AMO_BIT] &&
          (!rob_head_valid_w ||
           (mem_issue_res_rob_idx_q != rob_head_idx_w)))
        $error("[T3S-MEM-RES-AMO-HEAD] resident AMO is not ROB head @%0t",
               $time);
      if (mem_issue_res_exec_owner_w && iq_issue0_raw_exec_owner_w)
        $error("[T3S-MEM-RES-OWNER] resident/raw owner overlap @%0t", $time);
      if (mem_issue1_res_capture_shadow_q &&
          (!mem_issue1_res_valid_q ||
           (mem_issue1_res_payload_w !==
            mem_issue1_res_capture_expect_q)))
        $error("[V8P-MEM1-RES-CAPTURE] capture payload/valid mismatch @%0t",
               $time);
      if (mem_issue1_res_hold_shadow_q &&
          (!mem_issue1_res_valid_q ||
           (mem_issue1_res_payload_w !== mem_issue1_res_hold_expect_q)))
        $error("[V8P-MEM1-RES-HOLD] stalled reservation changed @%0t",
               $time);
      if (mem_issue1_res_valid_q &&
          (mem_issue1_res_ctrl_q[`CTRL_AMO_BIT] ||
           mem_issue1_res_fp_pdest_q || mem_issue1_res_fp_st_en_q ||
           !(mem_issue1_res_ctrl_q[`CTRL_LOAD_BIT] ||
             mem_issue1_res_ctrl_q[`CTRL_STORE_BIT])))
        $error("[V8P-MEM1-RES-CLASS] terminal1 captured excluded memory class @%0t",
               $time);
      mem_issue_res_capture_shadow_q <= mem_issue_res_capture_w;
      mem_issue_res_capture_expect_q <= mem_issue_res_capture_payload_w;
      mem_issue_res_hold_shadow_q <=
          mem_issue_res_valid_q && !mem_issue_res_consume_fire_w &&
          !mem_issue_res_kill_w && !flush_i &&
          !checkpoint_restore_apply_w;
      mem_issue_res_hold_expect_q <= mem_issue_res_payload_w;
      mem_issue1_res_capture_shadow_q <= mem_issue1_res_capture_w;
      mem_issue1_res_capture_expect_q <= mem_issue1_res_capture_payload_w;
      mem_issue1_res_hold_shadow_q <=
          mem_issue1_res_valid_q && !mem_issue1_res_consume_fire_w &&
          !mem_issue1_res_kill_w && !flush_i &&
          !checkpoint_restore_apply_w;
      mem_issue1_res_hold_expect_q <= mem_issue1_res_payload_w;
    end
  end
`endif

  function [`XLEN-1:0] select_op1;
    input [1:0] op1_sel;
    input [`XLEN-1:0] rs1_data;
    input [`XLEN-1:0] pc;
    begin
      case (op1_sel)
        `OP1_SEL_RS1:  select_op1 = rs1_data;
        `OP1_SEL_PC:   select_op1 = pc;
        `OP1_SEL_ZERO: select_op1 = {`XLEN{1'b0}};
        default:       select_op1 = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function [`XLEN-1:0] select_op2;
    input [1:0] op2_sel;
    input [`XLEN-1:0] rs2_data;
    input [`XLEN-1:0] imm;
    begin
      case (op2_sel)
        `OP2_SEL_RS2:  select_op2 = rs2_data;
        `OP2_SEL_IMM:  select_op2 = imm;
        `OP2_SEL_FOUR: select_op2 = {{(`XLEN-3){1'b0}}, 3'd4};
        `OP2_SEL_ZERO: select_op2 = {`XLEN{1'b0}};
        default:       select_op2 = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function [`XLEN-1:0] sign_extend_word;
    input [31:0] word;
    begin
      sign_extend_word = {{(`XLEN-32){word[31]}}, word};
    end
  endfunction

  function [`XLEN-1:0] zero_extend_word;
    input [31:0] word;
    begin
      zero_extend_word = {{(`XLEN-32){1'b0}}, word};
    end
  endfunction

  // AMO 结果计算已抽到 execute/OooAmoGate.v

  // AMO 结果计算已抽到 execute/OooAmoGate.v

  function [`XLEN-1:0] rv64_word_alu_result;
    input [3:0] alu_op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    reg [31:0] result32;
    begin
      case (alu_op)
        `ALU_OP_ADD: result32 = src1[31:0] + src2[31:0];
        `ALU_OP_SUB: result32 = src1[31:0] - src2[31:0];
        `ALU_OP_SLL: result32 = src1[31:0] << src2[4:0];
        `ALU_OP_SRL: result32 = src1[31:0] >> src2[4:0];
        `ALU_OP_SRA: result32 = $signed(src1[31:0]) >>> src2[4:0];
        default:     result32 = src1[31:0] + src2[31:0];
      endcase
      rv64_word_alu_result = sign_extend_word(result32);
    end
  endfunction

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  // bitmanip 函数已抽到 execute/OooBitmanipGate.v

  function is_clmul_inst;
    input [`INST_W-1:0] inst;
    begin
      is_clmul_inst =
          (inst[6:0] == `OPCODE_OP) && (inst[31:25] == 7'h05) &&
          ((inst[14:12] == `FUNCT3_SLL) ||
           (inst[14:12] == `FUNCT3_SLT) ||
           (inst[14:12] == `FUNCT3_SLTU));
    end
  endfunction

  function [1:0] clmul_op_from_funct3;
    input [2:0] funct3;
    begin
      case (funct3)
        `FUNCT3_SLT:  clmul_op_from_funct3 = CLMUL_OP_HIGH;
        `FUNCT3_SLTU: clmul_op_from_funct3 = CLMUL_OP_REV;
        default:      clmul_op_from_funct3 = CLMUL_OP_LOW;
      endcase
    end
  endfunction

  // 与 OooIntIssueQueue 的物理 terminal capability 机械同源。issue1 是固定延迟
  // RV64I ALU terminal，而不是程序序/dispatch lane；IQ 可把 older simple 动态
  // steering 到这里，同时把 younger complex 送 Universal issue0。
  function is_alu_terminal_capable_ctrl;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
      is_alu_terminal_capable_ctrl =
          ctrl[`CTRL_VALID_BIT] &&
          ctrl[`CTRL_RD_EN_BIT] &&
          ctrl[`CTRL_NEED_EXEC_BIT] &&
          !ctrl[`CTRL_NEED_MEM_BIT] &&
          ctrl[`CTRL_NEED_WB_BIT] &&
          ((ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] == `WB_SEL_ALU) ||
           (ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] == `WB_SEL_IMM)) &&
          !ctrl[`CTRL_ILLEGAL_BIT] &&
          !ctrl[`CTRL_BRANCH_BIT] && !ctrl[`CTRL_JAL_BIT] &&
          !ctrl[`CTRL_JALR_BIT] && !ctrl[`CTRL_LOAD_BIT] &&
          !ctrl[`CTRL_STORE_BIT] && !ctrl[`CTRL_ECALL_BIT] &&
          !ctrl[`CTRL_EBREAK_BIT] && !ctrl[`CTRL_FENCE_BIT] &&
          !ctrl[`CTRL_SYSTEM_BIT] && !ctrl[`CTRL_MISC_MEM_BIT] &&
          !ctrl[`CTRL_CSR_BIT] && !ctrl[`CTRL_MRET_BIT] &&
          !ctrl[`CTRL_WFI_BIT] && !ctrl[`CTRL_MULDIV_BIT] &&
          !ctrl[`CTRL_BITMANIP_BIT] && !ctrl[`CTRL_SFENCE_VMA_BIT] &&
          !ctrl[`CTRL_SRET_BIT] && !ctrl[`CTRL_AMO_BIT] &&
          !ctrl[`CTRL_SFENCE_TVM_BIT] && !ctrl[`CTRL_FENCEI_BIT];
    end
  endfunction

  function is_plain_memory_terminal_capable_ctrl;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
      is_plain_memory_terminal_capable_ctrl =
          ctrl[`CTRL_VALID_BIT] && ctrl[`CTRL_NEED_MEM_BIT] &&
          (ctrl[`CTRL_LOAD_BIT] || ctrl[`CTRL_STORE_BIT]) &&
          !ctrl[`CTRL_AMO_BIT];
    end
  endfunction

  // T3P：RAW-I1 已证明合法双 issue lane 不会形成 lane0→lane1 RAW；现在又由
  // ALU-terminal capability 将两 terminal 的类别/ready 拆开，因此物理删除旧 current-result
  // 前递，而不是保留一个逻辑不可达却会串起 ALU0→ALU1 的 mux。
  wire [`XLEN-1:0] issue0_wb_data_w;

  wire [`XLEN-1:0] issue0_alu_src1_w =
      select_op1(issue0_ctrl_w[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB],
                 issue0_src1_data_w, issue0_pc_w);
  wire [`XLEN-1:0] issue0_alu_src2_w =
      select_op2(issue0_ctrl_w[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB],
                 issue0_src2_data_w, issue0_imm_w);
  wire [`XLEN-1:0] issue1_alu_src1_w =
      select_op1(issue1_ctrl_w[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB],
                 issue1_src1_value_w, issue1_pc_w);
  wire [`XLEN-1:0] issue1_alu_src2_w =
      select_op2(issue1_ctrl_w[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB],
                 issue1_src2_value_w, issue1_imm_w);

  wire [`XLEN-1:0] issue0_alu_result_w;
  wire [`XLEN-1:0] issue1_alu_result_w;
  wire [`XLEN-1:0] issue0_alu_result_final_w;
  wire [`XLEN-1:0] issue1_alu_result_final_w;
  wire [`XLEN-1:0] issue0_exec_result_w;
  // issue0_wb_data_w 声明已前置到 issue1 前递 wire 之前(iverilog 14)
  wire [`XLEN-1:0] issue1_wb_data_w;
  wire issue0_is_branch_w = issue0_valid_w && issue0_ctrl_w[`CTRL_BRANCH_BIT];
  // R3.4：物理 ALU terminal 不承载控制流；原始 ctrl 仍由下方 capability
  // 断言检查，不能把删去的分类逻辑当作错误输入的容错路径。
  wire issue0_branch_taken_w;
  wire [`XLEN-1:0] issue0_branch_target_w = issue0_pc_w + issue0_imm_w;
  wire [`XLEN-1:0] issue0_branch_next_pc_w =
      issue0_branch_taken_w ? issue0_branch_target_w : issue0_next_pc_w;
  CompareUnit u_branch_compare0 (
    .lhs_i(issue0_src1_data_w),
    .rhs_i(issue0_src2_data_w),
    .cmp_op_i(issue0_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB]),
    .cmp_true_o(issue0_branch_taken_w)
  );

  ALU u_alu0 (
    .src1_i(issue0_alu_src1_w),
    .src2_i(issue0_alu_src2_w),
    .alu_op_i(issue0_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB]),
    .result_o(issue0_alu_result_w)
  );

  ALU u_alu1 (
    .src1_i(issue1_alu_src1_w),
    .src2_i(issue1_alu_src2_w),
    .alu_op_i(issue1_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB]),
    .result_o(issue1_alu_result_w)
  );

  // RV64 的 ADDW/SLLIW 等 *W 指令写回前必须截断到 32 位再符号扩展；
  // OoO 后端复用 RV32 ALU 时不能直接写回 64-bit 组合结果。
  assign issue0_alu_result_final_w =
      (issue0_ctrl_w[`CTRL_WORD_OP_BIT] && !issue0_ctrl_w[`CTRL_MULDIV_BIT]) ?
      rv64_word_alu_result(issue0_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB],
                           issue0_alu_src1_w, issue0_alu_src2_w) :
      issue0_alu_result_w;
  assign issue1_alu_result_final_w =
      (issue1_ctrl_w[`CTRL_WORD_OP_BIT] && !issue1_ctrl_w[`CTRL_MULDIV_BIT]) ?
      rv64_word_alu_result(issue1_ctrl_w[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB],
                           issue1_alu_src1_w, issue1_alu_src2_w) :
      issue1_alu_result_w;

  // R3.4：bitmanip/CLMUL 只属于 Universal terminal。动态 steering 已保证
  // 任意程序位置的复杂 uop 都可进入 Universal，因此删除语义不可达的第二实例，
  // 既不形成静态 lane 语义，也不允许错误类别在 ALU terminal 静默完成。
  wire [`XLEN-1:0] issue0_bitmanip_result_w;
  OooBitmanipGate u_bitmanip0 (
    .opcode_i(issue0_inst_w[6:0]),
    .funct10_i({issue0_inst_w[31:25], issue0_inst_w[14:12]}),
    .imm_i(issue0_inst_w[25:20]),
    .src1_i(issue0_src1_data_w),
    .src2_i(issue0_src2_data_w),
    .result_o(issue0_bitmanip_result_w)
  );
  assign issue0_exec_result_w =
      issue0_ctrl_w[`CTRL_BITMANIP_BIT] ?
      issue0_bitmanip_result_w :
      issue0_alu_result_final_w;

  WBU u_wbu0 (
    .wb_sel_i(issue0_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB]),
    .alu_data_i(issue0_exec_result_w),
    .pc_plus4_i(issue0_next_pc_w),
    .imm_data_i(issue0_imm_w),
    .csr_data_i(issue0_imm_w),
    .wb_data_o(issue0_wb_data_w)
  );

  // ALU terminal 的 capability 只允许 ALU/IMM 两种写回。显式二选一让综合网表
  // 与能力合同一致，同时保留 AUIPC 的 PC operand 与 LUI 的 immediate 语义。
  assign issue1_wb_data_w =
      (issue1_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] == `WB_SEL_IMM) ?
      issue1_imm_w : issue1_alu_result_final_w;

  // T3V reservation-only memory classification。所有 memory 类别均直接读取 Q，
  // 禁止从 generic issue0 valid/control 反解，确保 raw IQ 永远不能成为 memory owner。
  wire issue0_is_load_w = mem_issue_res_valid_q &&
                          mem_issue_res_ctrl_q[`CTRL_LOAD_BIT];
  wire issue0_is_store_w = mem_issue_res_valid_q &&
                           mem_issue_res_ctrl_q[`CTRL_STORE_BIT];
  wire issue0_is_amo_w = mem_issue_res_valid_q &&
                         mem_issue_res_ctrl_q[`CTRL_AMO_BIT];
  wire issue0_is_lr_w = issue0_is_amo_w &&
                        mem_issue_res_ctrl_q[`CTRL_AMO_LR_BIT];
  wire issue0_is_sc_w = issue0_is_amo_w &&
                        mem_issue_res_ctrl_q[`CTRL_AMO_SC_BIT];
  // v8p terminal1 now owns a registered plain integer memory packet.  The
  // raw IQ lane remains the ALU dataplane only; all memory classification
  // below reads the reservation Q and therefore cannot execute on capture.
  wire issue1_is_load_w = mem_issue1_res_valid_q &&
                          mem_issue1_res_ctrl_q[`CTRL_LOAD_BIT];
  wire issue1_is_store_w = mem_issue1_res_valid_q &&
                           mem_issue1_res_ctrl_q[`CTRL_STORE_BIT];
  wire issue1_is_amo_w = 1'b0;
  wire issue1_is_lr_w = 1'b0;
  wire issue1_is_sc_w = 1'b0;

  wire [`XLEN-1:0] issue0_mem_addr_w;
  wire [`XLEN-1:0] issue0_mem_wdata_w;
  wire [`STRB_W-1:0] issue0_mem_wstrb_w;
  wire [`XLEN-1:0] issue0_mem_load_unused_w;
  wire issue0_mem_misaligned_w;
  wire [`XLEN-1:0] issue1_mem_addr_w;
  wire [`XLEN-1:0] issue1_mem_wdata_w;
  wire [`STRB_W-1:0] issue1_mem_wstrb_w;
  wire [`XLEN-1:0] issue1_mem_load_unused_w;
  wire issue1_mem_misaligned_w;

  // 专用单级 AGU：memory 的地址合同恒为 captured rs1 + captured imm；不再复用
  // ALU0，也不再读取驻留期间可能变化的 raw PRF/issue packet。
  wire [`XLEN-1:0] mem_issue_res_eff_addr_w =
      mem_issue_res_src1_data_q + mem_issue_res_imm_q;
  wire [`XLEN-1:0] mem_issue1_res_eff_addr_w =
      mem_issue1_res_src1_data_q + mem_issue1_res_imm_q;
  LSU u_issue0_lsu (
    .eff_addr_i(mem_issue_res_eff_addr_w),
    .store_data_i(mem_issue_res_store_data_q),
    .mem_size_i(mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .mem_unsigned_i(mem_issue_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(issue0_mem_addr_w),
    .mem_wdata_o(issue0_mem_wdata_w),
    .mem_wstrb_o(issue0_mem_wstrb_w),
    .load_data_o(issue0_mem_load_unused_w),
    .misaligned_o(issue0_mem_misaligned_w)
  );

  LSU u_issue1_lsu (
    .eff_addr_i(mem_issue1_res_eff_addr_w),
    .store_data_i(mem_issue1_res_store_data_q),
    .mem_size_i(
        mem_issue1_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .mem_unsigned_i(mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(issue1_mem_addr_w),
    .mem_wdata_o(issue1_mem_wdata_w),
    .mem_wstrb_o(issue1_mem_wstrb_w),
    .load_data_o(issue1_mem_load_unused_w),
    .misaligned_o(issue1_mem_misaligned_w)
  );

  reg reservation_valid_q;
  reg [`XLEN-1:0] reservation_addr_q;
  reg [1:0] reservation_size_q;

  wire [`XLEN-1:0] issue0_reservation_addr_w =
      (mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] ==
       `MEM_SIZE_WORD) ?
      (mem_issue_res_eff_addr_w & {{(`XLEN-2){1'b1}}, 2'b00}) :
      (mem_issue_res_eff_addr_w &
       {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}});
  wire [`XLEN-1:0] issue1_reservation_addr_w =
      (mem_issue1_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] ==
       `MEM_SIZE_WORD) ?
      (mem_issue1_res_eff_addr_w & {{(`XLEN-2){1'b1}}, 2'b00}) :
      (mem_issue1_res_eff_addr_w &
       {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}});
  wire issue0_sc_success_w = issue0_is_sc_w && reservation_valid_q &&
                             (reservation_size_q ==
                              mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:
                                                   `CTRL_MEM_SIZE_LSB]) &&
                             (reservation_addr_q == issue0_reservation_addr_w);
  wire issue1_sc_success_w = issue1_is_sc_w && reservation_valid_q &&
                             (reservation_size_q ==
                              mem_issue1_res_ctrl_q[`CTRL_MEM_SIZE_MSB:
                                                    `CTRL_MEM_SIZE_LSB]) &&
                             (reservation_addr_q == issue1_reservation_addr_w);
  wire issue0_mem_class_w =
      issue0_is_load_w || issue0_is_store_w || issue0_is_amo_w;
  wire issue0_is_mem_w = issue0_mem_class_w &&
                         !(issue0_is_sc_w && !issue0_sc_success_w);
  wire issue1_is_mem_w = (issue1_is_load_w || issue1_is_store_w || issue1_is_amo_w) &&
                         !(issue1_is_sc_w && !issue1_sc_success_w);
  // plain store(非 AMO/SC): SQ 模式下走 probe→SQ→退休 drain 生命周期
  wire issue0_is_plain_store_w = issue0_is_store_w && !issue0_is_amo_w;
  wire issue1_is_plain_store_w = issue1_is_store_w && !issue1_is_amo_w;

  reg mem_pending_q;
  reg [ROB_INDEX_W-1:0] mem_rob_idx_q;
  reg [PRODUCER_ID_W-1:0] mem_producer_id_q;
  reg [PHY_REG_ADDR_W-1:0] mem_pdest_q;
  reg mem_pdest_fp_q;
  reg mem_load_q;
  reg mem_store_q;
  reg mem_amo_q;
  reg mem_amo_lr_q;
  reg mem_amo_sc_q;
  reg mem_amo_write_phase_q;
  reg mem_amo_write_sent_q;
  reg [`XLEN-1:0] mem_eff_addr_q;
  reg [1:0] mem_size_q;
  reg mem_unsigned_q;
  reg [`INST_W-1:0] mem_amo_inst_q;
  reg [`XLEN-1:0] mem_amo_src2_q;
  reg [`XLEN-1:0] mem_amo_old_value_q;
  reg [`XLEN-1:0] mem_amo_write_data_q;
  reg [`STRB_W-1:0] mem_amo_write_wstrb_q;
  reg [1:0] mem_owner_kind_q;
  reg [4:0] mem_owner_token_q;
  reg [1:0] mem_mmu_epoch_q;
  reg [`XLEN-1:0] mem_fault_tval_q;
  reg mem_buffer_valid_q;
  reg [ROB_INDEX_W-1:0] mem_buffer_rob_idx_q;
  reg [PHY_REG_ADDR_W-1:0] mem_buffer_pdest_q;
  reg mem_buffer_pdest_fp_q;
  reg mem_buffer_load_q;
  reg mem_buffer_store_q;
  reg [`XLEN-1:0] mem_buffer_eff_addr_q;
  reg [1:0] mem_buffer_size_q;
  reg mem_buffer_unsigned_q;
  reg [`XLEN-1:0] mem_buffer_wdata_q;
  reg [`STRB_W-1:0] mem_buffer_wstrb_q;
  reg [1:0] mem_buffer_owner_kind_q;
  reg [4:0] mem_buffer_owner_token_q;
  reg [1:0] mem_buffer_mmu_epoch_q;
  reg [`XLEN-1:0] mem_buffer_fault_tval_q;

  // ===== 【LSQ·SQ 切换】(spec ooo-lsq-implementation-plan.md §3.6) =====
  // mode=1: plain store 发射即 probe(翻译探测), rsp 拍 VA/PA+data 进 SQ；只有
  // physical SQ head==ROB head 才发真实写，B response 才形成 ROB terminal WB，
  // 随后的 ROB commit 才释放 SQ owner。
  // mode=0: 旧路径(store 队头发射+真事务), SQ 保持影子对拍(深 16 不反压)。
  localparam SQ_ENTRY_W = `OOO_SQ_STORE_PATH ? 2 : 4;
  localparam SQ_ENTRY_N = (1 << SQ_ENTRY_W);
  wire sq_mode_w = `OOO_SQ_STORE_PATH;
  // 【B-FP 簇】FP store 数据在 reservation capture 拍读取并锁存；因此地址
  // 直接来自 raw IQ packet，驻留执行拍不再回读 FP PRF。
  assign fpst_read_preg_w = iq_issue0_fp_st_en_w ? iq_issue0_fp_st_preg_w
                                                 : issue1_fp_st_preg_w;
  reg mem_probe_q;                     // 当前 pending 事务是 store 翻译探测
  reg [`XLEN-1:0] mem_store_wdata_q;   // probe 完成后回填 SQ 的 store 数据
  reg [`STRB_W-1:0] mem_store_wstrb_q;
  reg drain_inflight_q;                // SQ physical write 已 fire、B 尚未 terminal
  // sq_alloc0/1_ready_w 声明已前置到 u_dispatch_backend 实例之前(iverilog 14)
  wire sq_drain_valid_w;
  wire [ROB_INDEX_W-1:0] sq_drain_rob_w;
  wire [PRODUCER_ID_W-1:0] sq_drain_producer_id_w;
  wire [1:0] sq_drain_owner_kind_w;
  wire [4:0] sq_drain_owner_token_w;
  wire [1:0] sq_drain_mmu_epoch_w;
  wire [`XLEN-1:0] sq_drain_fault_tval_w;
  wire [`XLEN-1:0] sq_drain_vaddr_w;
  wire [`XLEN-1:0] sq_drain_addr_w;
  wire sq_drain_attr_valid_w;
  wire [1:0] sq_drain_class_w;
  wire sq_drain_cacheable_w;
  wire [`XLEN-1:0] sq_drain_data_w;
  wire [`STRB_W-1:0] sq_drain_strb_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_valid_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_addr_valid_w;
  wire [SQ_ENTRY_N*`XLEN-1:0] sq_snoop_addr_w;
  wire [SQ_ENTRY_N*`XLEN-1:0] sq_snoop_paddr_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_attr_valid_w;
  wire [SQ_ENTRY_N*2-1:0] sq_snoop_class_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_cacheable_w;
  wire [SQ_ENTRY_N*`XLEN-1:0] sq_snoop_data_w;
  wire [SQ_ENTRY_N*`STRB_W-1:0] sq_snoop_strb_w;
  wire [SQ_ENTRY_N*ROB_INDEX_W-1:0] sq_snoop_rob_idx_w;
  wire [SQ_ENTRY_N*PRODUCER_ID_W-1:0] sq_snoop_producer_id_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_owner_valid_w;
  wire [SQ_ENTRY_N*5-1:0] sq_snoop_owner_token_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_request_sent_w;
  wire [SQ_ENTRY_N-1:0] sq_snoop_terminal_w;
  wire [SQ_ENTRY_W-1:0] sq_snoop_head_w;
  wire [SQ_ENTRY_W:0] sq_count_w;
  wire [31:0] sq_owner_release_mask_w;
  wire sq_empty_w = (sq_count_w == {(SQ_ENTRY_W+1){1'b0}});
  wire sq_no_active_write_w =
      (sq_snoop_request_sent_w == {SQ_ENTRY_N{1'b0}});

  // A physical write is irrevocable from bridge request fire until the same
  // ProducerId retires from ROB.  Keeping this lease through B (not merely
  // through request_sent/drain_inflight) also covers AMO and preserves precise
  // error retirement before checkpoint recovery.
  assign checkpoint_restore_apply_w =
      (checkpoint_restore_new_req_w || checkpoint_restore_pending_q) &&
      !checkpoint_irrevocable_write_q && sq_no_active_write_w &&
      !drain_inflight_q;
  assign checkpoint_restore_apply_o = checkpoint_restore_apply_w;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      checkpoint_restore_pending_q <= 1'b0;
      checkpoint_restore_seen_q <= 1'b0;
    end else begin
      checkpoint_restore_seen_q <= checkpoint_restore_i;
      if (checkpoint_restore_apply_w)
        checkpoint_restore_pending_q <= 1'b0;
      else if (checkpoint_restore_new_req_w)
        checkpoint_restore_pending_q <= 1'b1;
    end
  end

  // pending_load0/1 唤醒口已随 IQ load-branch-fast 死硅整族删除（消费端 E7 已删，
  // IQ 内选择逻辑空转）。miq_head 前递仍活于其它通路，此处不再驱动 IQ 二次唤醒。

  wire [`XLEN-1:0] mem_rsp_addr_unused_w;
  wire [`XLEN-1:0] mem_rsp_wdata_unused_w;
  wire [`STRB_W-1:0] mem_rsp_wstrb_unused_w;
  wire [`XLEN-1:0] mem_rsp_load_data_w;
  wire mem_rsp_misaligned_unused_w;
  wire [`XLEN-1:0] mem1_rsp_addr_unused_w;
  wire [`XLEN-1:0] mem1_rsp_wdata_unused_w;
  wire [`STRB_W-1:0] mem1_rsp_wstrb_unused_w;
  wire [`XLEN-1:0] mem1_rsp_load_data_w;
  wire mem1_rsp_misaligned_unused_w;
  wire [`XLEN-1:0] mem_amo_write_addr_unused_w;
  wire [`XLEN-1:0] mem_amo_write_wdata_w;
  wire [`STRB_W-1:0] mem_amo_write_wstrb_w;
  wire [`XLEN-1:0] mem_amo_write_load_unused_w;
  wire mem_amo_write_misaligned_unused_w;
  wire [`XLEN-1:0] mem_amo_old_value_w;
  wire [`XLEN-1:0] mem_amo_result_value_w;
  // 声明前置：iverilog 14 拒绝前向引用（由后文 u_mem_inflight_queue 驱动）
  wire [1:0] miq_head_size_w;
  wire miq_head_unsigned_w;
  wire [`XLEN-1:0] miq_head_addr_w;
  wire [1:0] miq1_head_size_w;
  wire miq1_head_unsigned_w;
  wire [`XLEN-1:0] miq1_head_addr_w;

  LSU u_mem_rsp_lsu (
    // rsp 数据展开按 MIQ 队头(LEGACY entry 的字段与单例一致, 恒可用 head)
    .eff_addr_i(miq_head_addr_w),
    .store_data_i({`XLEN{1'b0}}),
    .mem_size_i(miq_head_size_w),
    .mem_unsigned_i(miq_head_unsigned_w),
    .mem_rdata_i(mem_rsp_rdata_i),
    .mem_addr_o(mem_rsp_addr_unused_w),
    .mem_wdata_o(mem_rsp_wdata_unused_w),
    .mem_wstrb_o(mem_rsp_wstrb_unused_w),
    .load_data_o(mem_rsp_load_data_w),
    .misaligned_o(mem_rsp_misaligned_unused_w)
  );

  LSU u_mem1_rsp_lsu (
    .eff_addr_i(miq1_head_addr_w),
    .store_data_i({`XLEN{1'b0}}),
    .mem_size_i(miq1_head_size_w),
    .mem_unsigned_i(miq1_head_unsigned_w),
    .mem_rdata_i(mem1_rsp_rdata_i),
    .mem_addr_o(mem1_rsp_addr_unused_w),
    .mem_wdata_o(mem1_rsp_wdata_unused_w),
    .mem_wstrb_o(mem1_rsp_wstrb_unused_w),
    .load_data_o(mem1_rsp_load_data_w),
    .misaligned_o(mem1_rsp_misaligned_unused_w)
  );

  // AMO 旧值规整与结果计算下沉到 OooAmoGate。
  OooAmoGate u_amo_gate (
    .inst_i(mem_amo_inst_q),
    .load_data_i(mem_rsp_load_data_w),
    .src2_i(mem_amo_src2_q),
    .size_i(mem_size_q),
    .old_value_o(mem_amo_old_value_w),
    .result_o(mem_amo_result_value_w)
  );

  LSU u_mem_amo_write_lsu (
    .eff_addr_i(mem_eff_addr_q),
    .store_data_i(mem_amo_result_value_w),
    .mem_size_i(mem_size_q),
    .mem_unsigned_i(1'b0),
    .mem_rdata_i({`XLEN{1'b0}}),
    .mem_addr_o(mem_amo_write_addr_unused_w),
    .mem_wdata_o(mem_amo_write_wdata_w),
    .mem_wstrb_o(mem_amo_write_wstrb_w),
    .load_data_o(mem_amo_write_load_unused_w),
    .misaligned_o(mem_amo_write_misaligned_unused_w)
  );

  // ===========================================================================
  // 【LSQ Phase2+3 第一刀】访存在飞顺序队列(MIQ): plain LOAD/PROBE/DRAIN 可背
  // 靠背在飞(桥 back-to-back 已支持), AMO/LR/SC 走 LEGACY 独占。rsp 恒配队头。
  // ===========================================================================
  localparam MIQ_ENTRY_N = 4;
  localparam MIQ_ENTRY_W = 2;
  localparam [1:0] MIQ_KIND_LOAD = 2'd0;
  localparam [1:0] MIQ_KIND_PROBE = 2'd1;
  localparam [1:0] MIQ_KIND_DRAIN = 2'd2;
  localparam [1:0] MIQ_KIND_LEGACY = 2'd3;
  wire miq_push_valid_w;
  wire [1:0] miq_push_kind_w;
  wire [1:0] miq_push_owner_kind_w;
  wire [4:0] miq_push_owner_token_w;
  wire [1:0] miq_push_mmu_epoch_w;
  wire [`XLEN-1:0] miq_push_fault_tval_w;
  wire [ROB_INDEX_W-1:0] miq_push_rob_w;
  wire [PHY_REG_ADDR_W-1:0] miq_push_pdest_w;
  wire miq_push_pdest_fp_w;
  wire [1:0] miq_push_size_w;
  wire miq_push_unsigned_w;
  wire [`XLEN-1:0] miq_push_addr_w;
  wire [`XLEN-1:0] miq_push_wdata_w;
  wire [`STRB_W-1:0] miq_push_wstrb_w;
  wire miq_pop_transport_w;
  wire miq_drop0_pop_w;
  wire miq_pop_owner_match_w;
  wire miq_pop_tval_echo_match_w;
  wire miq_pop_w;
  wire miq_queue_pop_valid_w;
  wire [1:0] miq_queue_pop_owner_kind_w;
  wire [4:0] miq_queue_pop_owner_token_w;
  wire [1:0] miq_queue_pop_mmu_epoch_w;
  wire [`XLEN-1:0] miq_queue_pop_fault_tval_w;
  wire miq_head_valid_w;
  wire [1:0] miq_head_kind_w;
  wire [1:0] miq_head_owner_kind_w;
  wire [4:0] miq_head_owner_token_w;
  wire [1:0] miq_head_mmu_epoch_w;
  wire [`XLEN-1:0] miq_head_fault_tval_w;
  wire miq_head_killed_w;
  wire miq_head_effective_killed_w;
  wire [ROB_INDEX_W-1:0] miq_head_rob_w;
  wire [PHY_REG_ADDR_W-1:0] miq_head_pdest_w;
  wire miq_head_pdest_fp_w;
  // miq_head_size/unsigned/addr_w 声明已前置到 u_mem_rsp_lsu 之前(iverilog 14)
  wire [`XLEN-1:0] miq_head_wdata_w;
  wire [`STRB_W-1:0] miq_head_wstrb_w;
  wire miq_next_head_valid_w;
  wire [1:0] miq_next_head_kind_w;
  wire [1:0] miq_next_head_owner_kind_w;
  wire [4:0] miq_next_head_owner_token_w;
  wire [1:0] miq_next_head_mmu_epoch_w;
  wire [`XLEN-1:0] miq_next_head_fault_tval_w;
  wire miq_next_head_killed_w;
  wire miq_next_head_effective_killed_w;
  wire [ROB_INDEX_W-1:0] miq_next_head_rob_w;
  wire [MIQ_ENTRY_W:0] miq_count_w;
  wire miq_empty_w;
  wire miq_full_w;
  wire [MIQ_ENTRY_N-1:0] miq_entry_valid_unused_w;
  wire [MIQ_ENTRY_N*2-1:0] miq_entry_kind_unused_w;
  wire [MIQ_ENTRY_N*ROB_INDEX_W-1:0] miq_entry_rob_unused_w;
  wire [MIQ_ENTRY_N*`XLEN-1:0] miq_entry_addr_unused_w;
  wire [31:0] miq_occupancy_token_mask_w;
  wire miq1_push_valid_w;
  wire [1:0] miq1_push_kind_w;
  wire [1:0] miq1_push_owner_kind_w;
  wire [4:0] miq1_push_owner_token_w;
  wire [1:0] miq1_push_mmu_epoch_w;
  wire [`XLEN-1:0] miq1_push_fault_tval_w;
  wire [ROB_INDEX_W-1:0] miq1_push_rob_w;
  wire [PHY_REG_ADDR_W-1:0] miq1_push_pdest_w;
  wire miq1_push_pdest_fp_w;
  wire [1:0] miq1_push_size_w;
  wire miq1_push_unsigned_w;
  wire [`XLEN-1:0] miq1_push_addr_w;
  wire [`XLEN-1:0] miq1_push_wdata_w;
  wire [`STRB_W-1:0] miq1_push_wstrb_w;
  wire miq1_pop_transport_w;
  wire miq1_drop0_pop_w;
  wire miq1_pop_owner_match_w;
  wire miq1_pop_tval_echo_match_w;
  wire miq1_pop_w;
  wire miq1_queue_pop_valid_w;
  wire [1:0] miq1_queue_pop_owner_kind_w;
  wire [4:0] miq1_queue_pop_owner_token_w;
  wire [1:0] miq1_queue_pop_mmu_epoch_w;
  wire [`XLEN-1:0] miq1_queue_pop_fault_tval_w;
  wire miq1_head_valid_w;
  wire [1:0] miq1_head_kind_w;
  wire [1:0] miq1_head_owner_kind_w;
  wire [4:0] miq1_head_owner_token_w;
  wire [1:0] miq1_head_mmu_epoch_w;
  wire [`XLEN-1:0] miq1_head_fault_tval_w;
  wire miq1_head_killed_w;
  wire miq1_head_effective_killed_w;
  wire [ROB_INDEX_W-1:0] miq1_head_rob_w;
  wire [PHY_REG_ADDR_W-1:0] miq1_head_pdest_w;
  wire miq1_head_pdest_fp_w;
  wire [`XLEN-1:0] miq1_head_wdata_w;
  wire [`STRB_W-1:0] miq1_head_wstrb_w;
  wire miq1_next_head_valid_w;
  wire [1:0] miq1_next_head_kind_w;
  wire [1:0] miq1_next_head_owner_kind_w;
  wire [4:0] miq1_next_head_owner_token_w;
  wire [1:0] miq1_next_head_mmu_epoch_w;
  wire [`XLEN-1:0] miq1_next_head_fault_tval_w;
  wire miq1_next_head_killed_w;
  wire miq1_next_head_effective_killed_w;
  wire [ROB_INDEX_W-1:0] miq1_next_head_rob_w;
  wire [MIQ_ENTRY_W:0] miq1_count_w;
  wire miq1_empty_w;
  wire miq1_full_w;
  wire [MIQ_ENTRY_N-1:0] miq1_entry_valid_unused_w;
  wire [MIQ_ENTRY_N*2-1:0] miq1_entry_kind_unused_w;
  wire [MIQ_ENTRY_N*ROB_INDEX_W-1:0] miq1_entry_rob_unused_w;
  wire [MIQ_ENTRY_N*`XLEN-1:0] miq1_entry_addr_unused_w;
  wire [31:0] miq1_occupancy_token_mask_w;

  OooMemInflightQueue #(
    .ENTRY_N(MIQ_ENTRY_N),
    .ENTRY_W(MIQ_ENTRY_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_mem_inflight_queue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_apply_w),
    .push_valid_i(miq_push_valid_w),
    .push_kind_i(miq_push_kind_w),
    .push_owner_kind_i(miq_push_owner_kind_w),
    .push_owner_token_i(miq_push_owner_token_w),
    .push_mmu_epoch_i(miq_push_mmu_epoch_w),
    .push_fault_tval_i(miq_push_fault_tval_w),
    .push_rob_idx_i(miq_push_rob_w),
    .push_pdest_i(miq_push_pdest_w),
    .push_pdest_fp_i(miq_push_pdest_fp_w),
    .push_size_i(miq_push_size_w),
    .push_unsigned_i(miq_push_unsigned_w),
    .push_eff_addr_i(miq_push_addr_w),
    .push_wdata_i(miq_push_wdata_w),
    .push_wstrb_i(miq_push_wstrb_w),
    .pop_valid_i(miq_queue_pop_valid_w),
    .pop_owner_kind_i(miq_queue_pop_owner_kind_w),
    .pop_owner_token_i(miq_queue_pop_owner_token_w),
    .pop_mmu_epoch_i(miq_queue_pop_mmu_epoch_w),
    .pop_fault_tval_i(miq_queue_pop_fault_tval_w),
    .pop_owner_match_o(miq_pop_owner_match_w),
    .pop_tval_echo_match_o(miq_pop_tval_echo_match_w),
    .kill_valid_i(branch_resolve_mispredict_w),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),
    .rob_head_idx_i(rob_head_idx_w),
    .head_valid_o(miq_head_valid_w),
    .head_kind_o(miq_head_kind_w),
    .head_owner_kind_o(miq_head_owner_kind_w),
    .head_owner_token_o(miq_head_owner_token_w),
    .head_mmu_epoch_o(miq_head_mmu_epoch_w),
    .head_fault_tval_o(miq_head_fault_tval_w),
    .head_killed_o(miq_head_killed_w),
    .head_effective_killed_o(miq_head_effective_killed_w),
    .head_rob_idx_o(miq_head_rob_w),
    .head_pdest_o(miq_head_pdest_w),
    .head_pdest_fp_o(miq_head_pdest_fp_w),
    .head_size_o(miq_head_size_w),
    .head_unsigned_o(miq_head_unsigned_w),
    .head_eff_addr_o(miq_head_addr_w),
    .head_wdata_o(miq_head_wdata_w),
    .head_wstrb_o(miq_head_wstrb_w),
    .next_head_valid_o(miq_next_head_valid_w),
    .next_head_kind_o(miq_next_head_kind_w),
    .next_head_owner_kind_o(miq_next_head_owner_kind_w),
    .next_head_owner_token_o(miq_next_head_owner_token_w),
    .next_head_mmu_epoch_o(miq_next_head_mmu_epoch_w),
    .next_head_fault_tval_o(miq_next_head_fault_tval_w),
    .next_head_killed_o(miq_next_head_killed_w),
    .next_head_effective_killed_o(miq_next_head_effective_killed_w),
    .next_head_rob_idx_o(miq_next_head_rob_w),
    .count_o(miq_count_w),
    .empty_o(miq_empty_w),
    .full_o(miq_full_w),
    .occupancy_token_mask_o(miq_occupancy_token_mask_w),
    .entry_valid_o(miq_entry_valid_unused_w),
    .entry_kind_o(miq_entry_kind_unused_w),
    .entry_rob_idx_o(miq_entry_rob_unused_w),
    .entry_addr_o(miq_entry_addr_unused_w)
  );

  OooMemInflightQueue #(
    .ENTRY_N(MIQ_ENTRY_N),
    .ENTRY_W(MIQ_ENTRY_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_mem1_inflight_queue (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_apply_w),
    .push_valid_i(miq1_push_valid_w),
    .push_kind_i(miq1_push_kind_w),
    .push_owner_kind_i(miq1_push_owner_kind_w),
    .push_owner_token_i(miq1_push_owner_token_w),
    .push_mmu_epoch_i(miq1_push_mmu_epoch_w),
    .push_fault_tval_i(miq1_push_fault_tval_w),
    .push_rob_idx_i(miq1_push_rob_w),
    .push_pdest_i(miq1_push_pdest_w),
    .push_pdest_fp_i(miq1_push_pdest_fp_w),
    .push_size_i(miq1_push_size_w),
    .push_unsigned_i(miq1_push_unsigned_w),
    .push_eff_addr_i(miq1_push_addr_w),
    .push_wdata_i(miq1_push_wdata_w),
    .push_wstrb_i(miq1_push_wstrb_w),
    .pop_valid_i(miq1_queue_pop_valid_w),
    .pop_owner_kind_i(miq1_queue_pop_owner_kind_w),
    .pop_owner_token_i(miq1_queue_pop_owner_token_w),
    .pop_mmu_epoch_i(miq1_queue_pop_mmu_epoch_w),
    .pop_fault_tval_i(miq1_queue_pop_fault_tval_w),
    .pop_owner_match_o(miq1_pop_owner_match_w),
    .pop_tval_echo_match_o(miq1_pop_tval_echo_match_w),
    .kill_valid_i(branch_resolve_mispredict_w),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),
    .rob_head_idx_i(rob_head_idx_w),
    .head_valid_o(miq1_head_valid_w),
    .head_kind_o(miq1_head_kind_w),
    .head_owner_kind_o(miq1_head_owner_kind_w),
    .head_owner_token_o(miq1_head_owner_token_w),
    .head_mmu_epoch_o(miq1_head_mmu_epoch_w),
    .head_fault_tval_o(miq1_head_fault_tval_w),
    .head_killed_o(miq1_head_killed_w),
    .head_effective_killed_o(miq1_head_effective_killed_w),
    .head_rob_idx_o(miq1_head_rob_w),
    .head_pdest_o(miq1_head_pdest_w),
    .head_pdest_fp_o(miq1_head_pdest_fp_w),
    .head_size_o(miq1_head_size_w),
    .head_unsigned_o(miq1_head_unsigned_w),
    .head_eff_addr_o(miq1_head_addr_w),
    .head_wdata_o(miq1_head_wdata_w),
    .head_wstrb_o(miq1_head_wstrb_w),
    .next_head_valid_o(miq1_next_head_valid_w),
    .next_head_kind_o(miq1_next_head_kind_w),
    .next_head_owner_kind_o(miq1_next_head_owner_kind_w),
    .next_head_owner_token_o(miq1_next_head_owner_token_w),
    .next_head_mmu_epoch_o(miq1_next_head_mmu_epoch_w),
    .next_head_fault_tval_o(miq1_next_head_fault_tval_w),
    .next_head_killed_o(miq1_next_head_killed_w),
    .next_head_effective_killed_o(miq1_next_head_effective_killed_w),
    .next_head_rob_idx_o(miq1_next_head_rob_w),
    .count_o(miq1_count_w),
    .empty_o(miq1_empty_w),
    .full_o(miq1_full_w),
    .occupancy_token_mask_o(miq1_occupancy_token_mask_w),
    .entry_valid_o(miq1_entry_valid_unused_w),
    .entry_kind_o(miq1_entry_kind_unused_w),
    .entry_rob_idx_o(miq1_entry_rob_unused_w),
    .entry_addr_o(miq1_entry_addr_unused_w)
  );

  // 【正确性修复 2026-07-03: rtl-ground-truth §3.1 #2】跨 4KB 页 misaligned plain load/store
  // 精确异常。桥(OooMemAxiBridge)只翻译起始 VA 一次、第二页字节按起始 PA 物理连续读写
  // (OooMemAxiBridge.v:455-456/471/475-476/490); plain 访存 misaligned 又不 trap(下方原门只放 AMO),
  // 分页开启(Sv39)时跨 4KB 页 → 静默读错/写坏相邻物理页。此处对"分页开 + plain LS + misaligned +
  // 跨 4KB 页"抛精确 LOAD/STORE_ADDR_MISALIGN,交软件 trap-and-emulate(cause/tval/请求关断/ROB-commit
  // 上报整链复用 AMO misaligned 机制,一字未改; 页内 misaligned 仍由 byte-window 硬件正常支持不 trap;
  // M 态/satp=Bare(mem_translate_active_i=0)与对齐访存(cross_page=0)全不受影响)。
  wire issue0_plain_ls_w =
      (issue0_is_load_w && !issue0_is_amo_w) || issue0_is_plain_store_w;
  wire issue1_plain_ls_w =
      (issue1_is_load_w && !issue1_is_amo_w) || issue1_is_plain_store_w;
  // nbytes = 1<<size (BYTE/HALF/WORD/DWORD=00/01/10/11 → 1/2/4/8)。
  wire [3:0] issue0_acc_bytes_w =
      4'd1 << mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
  wire [3:0] issue1_acc_bytes_w =
      4'd1 <<
      mem_issue1_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
  // 跨 4KB 页 ⟺ EA[11:0]+nbytes > 0x1000 (13 位加法容纳 0xFFF+8=0x1007 不截断)。
  // 跨页 ⟹ 必 misaligned(4KB 是任何自然对齐的整数倍); &&misaligned 冗余但作为 cross_page 若误判对齐访存的
  // 安全网(对齐访存 misaligned=0 兜住,防误伤成回归)。
  wire issue0_cross_page_w =
      ({1'b0, mem_issue_res_eff_addr_w[11:0]} +
       {9'b0, issue0_acc_bytes_w}) > 13'h1000;
  wire issue1_cross_page_w =
      ({1'b0, mem_issue1_res_eff_addr_w[11:0]} +
       {9'b0, issue1_acc_bytes_w}) > 13'h1000;
  wire issue0_xpage_misalign_w =
      mem_translate_active_i && issue0_plain_ls_w &&
      issue0_mem_misaligned_w && issue0_cross_page_w;
  wire issue1_xpage_misalign_w =
      mem_translate_active_i && issue1_plain_ls_w &&
      issue1_mem_misaligned_w && issue1_cross_page_w;
  wire issue0_mem_exception_w =
      (issue0_is_amo_w && issue0_mem_misaligned_w) || issue0_xpage_misalign_w;
  wire issue1_mem_exception_w =
      (issue1_is_amo_w && issue1_mem_misaligned_w) || issue1_xpage_misalign_w;
  // Only architecturally atomic operations retain the LEGACY singleton path.
  // Plain loads are classified after translation in the bridge; a VA must
  // never be guessed as IO here.
  // (声明前置到 can_fire 之前——B2 S2 修 can_fire↔req-mux slot 分派不同源潜伏 bug)
  wire issue0_mem_needs_excl_w = issue0_is_amo_w;
  wire issue1_mem_needs_excl_w = issue1_is_amo_w;
  wire issue_block_w =
      checkpoint_capture_i || checkpoint_quiesce_i;
  // rsp 归属 = MIQ 队头。LEGACY 头沿旧 mem_pending_q 语义; plain 头按 kind 分派。
  wire miq_head_load_w = miq_head_valid_w && (miq_head_kind_w == MIQ_KIND_LOAD);
  wire miq_head_probe_w = miq_head_valid_w && (miq_head_kind_w == MIQ_KIND_PROBE);
  wire miq_head_drain_w = miq_head_valid_w && (miq_head_kind_w == MIQ_KIND_DRAIN);
  wire miq_head_legacy_w = miq_head_valid_w && (miq_head_kind_w == MIQ_KIND_LEGACY);
  wire miq1_head_load_w = miq1_head_valid_w &&
      (miq1_head_kind_w == MIQ_KIND_LOAD);
  wire miq1_head_probe_w = miq1_head_valid_w &&
      (miq1_head_kind_w == MIQ_KIND_PROBE);
  wire miq_next_head_load_w = miq_next_head_valid_w &&
      (miq_next_head_kind_w == MIQ_KIND_LOAD);
  wire miq1_next_head_load_w = ENABLE_DUAL_MEM &&
      miq1_next_head_valid_w &&
      (miq1_next_head_kind_w == MIQ_KIND_LOAD);
  assign mem_expected_valid_o = miq_head_valid_w;
  assign mem_expected_owner_kind_o = miq_head_owner_kind_w;
  assign mem_expected_owner_token_o = miq_head_owner_token_w;
  assign mem_expected_mmu_epoch_o = miq_head_mmu_epoch_w;
  assign mem_expected_tval_valid_o = miq_head_valid_w;
  assign mem_expected_fault_tval_o = miq_head_fault_tval_w;
  assign mem_expected_effective_killed_o = miq_head_effective_killed_w;
  assign mem1_expected_valid_o = ENABLE_DUAL_MEM && miq1_head_valid_w;
  assign mem1_expected_owner_kind_o = miq1_head_owner_kind_w;
  assign mem1_expected_owner_token_o = miq1_head_owner_token_w;
  assign mem1_expected_mmu_epoch_o = miq1_head_mmu_epoch_w;
  assign mem1_expected_tval_valid_o = ENABLE_DUAL_MEM && miq1_head_valid_w;
  assign mem1_expected_fault_tval_o = miq1_head_fault_tval_w;
  assign mem1_expected_effective_killed_o = miq1_head_effective_killed_w;
  assign mem_completion_producer_id_w =
      mem_owner_producer_id_table_w[
          miq_head_owner_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];
  wire miq_head_tracker_exact_w = miq_head_valid_w &&
      mem_owner_live_mask_w[miq_head_owner_token_w] &&
      (mem_owner_kind_table_w[miq_head_owner_token_w*2 +: 2] ==
       miq_head_owner_kind_w) &&
      (mem_owner_epoch_table_w[miq_head_owner_token_w*2 +: 2] ==
       miq_head_mmu_epoch_w);
  assign mem_completion_query_valid_w = mem_rsp_valid_i &&
      miq_head_valid_w && miq_pop_owner_match_w &&
      miq_head_tracker_exact_w;
  assign mem1_completion_producer_id_w =
      mem_owner_producer_id_table_w[
          miq1_head_owner_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];
  wire miq1_head_tracker_exact_w = ENABLE_DUAL_MEM && miq1_head_valid_w &&
      mem_owner_live_mask_w[miq1_head_owner_token_w] &&
      (mem_owner_kind_table_w[miq1_head_owner_token_w*2 +: 2] ==
       miq1_head_owner_kind_w) &&
      (mem_owner_epoch_table_w[miq1_head_owner_token_w*2 +: 2] ==
       miq1_head_mmu_epoch_w);

  // v8u/F4 final-PA query identity.  The ordinary F3 path compares the bridge
  // active query with the current MIQ head.  A station-sourced query is
  // identified by the independent station tracker face and may compare with
  // next-head while the current response Q names the exact current owner.
  // This read-only qualification deliberately excludes response READY so the
  // SQ decision cannot feed back into the response-credit cone.  The bridge
  // still requires the exact current-response handshake before the station
  // lookup may fire or the station owner may become active.  The next entry
  // remains resident: lookahead never owns the queue pop or retry-holder
  // credit.
  wire [PRODUCER_ID_W-1:0] mem_sq_query_producer_id_w =
      mem_owner_producer_id_table_w[
          mem_sq_query_owner_token_i*PRODUCER_ID_W +: PRODUCER_ID_W];
  wire [PRODUCER_ID_W-1:0] mem1_sq_query_producer_id_w =
      mem_owner_producer_id_table_w[
          mem1_sq_query_owner_token_i*PRODUCER_ID_W +: PRODUCER_ID_W];
  wire mem_sq_query_station_source_w = mem_sq_query_valid_i &&
      mem_station_query_valid_i && mem_station_expected_valid_o &&
      (mem_sq_query_owner_kind_i == mem_station_expected_owner_kind_o) &&
      (mem_sq_query_owner_token_i == mem_station_query_token_i) &&
      (mem_sq_query_owner_token_i == mem_station_expected_owner_token_o) &&
      (mem_sq_query_mmu_epoch_i == mem_station_expected_mmu_epoch_o);
  wire mem1_sq_query_station_source_w = ENABLE_DUAL_MEM &&
      mem1_sq_query_valid_i && mem1_station_query_valid_i &&
      mem1_station_expected_valid_o &&
      (mem1_sq_query_owner_kind_i == mem1_station_expected_owner_kind_o) &&
      (mem1_sq_query_owner_token_i == mem1_station_query_token_i) &&
      (mem1_sq_query_owner_token_i == mem1_station_expected_owner_token_o) &&
      (mem1_sq_query_mmu_epoch_i == mem1_station_expected_mmu_epoch_o);
  wire mem_current_rsp_exact_candidate_w = mem_rsp_valid_i &&
      miq_head_valid_w && miq_head_tracker_exact_w &&
      !miq_head_effective_killed_w &&
      (mem_completion_producer_id_w[ROB_INDEX_W-1:0] == miq_head_rob_w) &&
      (miq_head_owner_kind_w == mem_rsp_owner_kind_i) &&
      (miq_head_owner_token_w == mem_rsp_owner_token_i) &&
      (miq_head_mmu_epoch_w == mem_rsp_mmu_epoch_i);
  wire mem1_current_rsp_exact_candidate_w = ENABLE_DUAL_MEM &&
      mem1_rsp_valid_i && miq1_head_valid_w &&
      miq1_head_tracker_exact_w && !miq1_head_effective_killed_w &&
      (mem1_completion_producer_id_w[ROB_INDEX_W-1:0] ==
       miq1_head_rob_w) &&
      (miq1_head_owner_kind_w == mem1_rsp_owner_kind_i) &&
      (miq1_head_owner_token_w == mem1_rsp_owner_token_i) &&
      (miq1_head_mmu_epoch_w == mem1_rsp_mmu_epoch_i);
  wire mem_current_rsp_exact_fire_w =
      mem_current_rsp_exact_candidate_w && mem_rsp_ready_o;
  wire mem1_current_rsp_exact_fire_w =
      mem1_current_rsp_exact_candidate_w && mem1_rsp_ready_o;
  wire mem_sq_query_head_miq_exact_w = mem_sq_query_valid_i &&
      !mem_sq_query_station_source_w &&
      miq_head_load_w &&
      (miq_head_owner_kind_w == mem_sq_query_owner_kind_i) &&
      (miq_head_owner_token_w == mem_sq_query_owner_token_i) &&
      (miq_head_mmu_epoch_w == mem_sq_query_mmu_epoch_i);
  wire mem1_sq_query_head_miq_exact_w = ENABLE_DUAL_MEM &&
      mem1_sq_query_valid_i && !mem1_sq_query_station_source_w &&
      miq1_head_load_w &&
      (miq1_head_owner_kind_w == mem1_sq_query_owner_kind_i) &&
      (miq1_head_owner_token_w == mem1_sq_query_owner_token_i) &&
      (miq1_head_mmu_epoch_w == mem1_sq_query_mmu_epoch_i);
  wire mem_sq_query_next_miq_exact_w = mem_sq_query_station_source_w &&
      mem_current_rsp_exact_candidate_w && miq_next_head_load_w &&
      (miq_next_head_owner_kind_w == mem_sq_query_owner_kind_i) &&
      (miq_next_head_owner_token_w == mem_sq_query_owner_token_i) &&
      (miq_next_head_mmu_epoch_w == mem_sq_query_mmu_epoch_i);
  wire mem1_sq_query_next_miq_exact_w =
      mem1_sq_query_station_source_w && mem1_current_rsp_exact_candidate_w &&
      miq1_next_head_load_w &&
      (miq1_next_head_owner_kind_w == mem1_sq_query_owner_kind_i) &&
      (miq1_next_head_owner_token_w == mem1_sq_query_owner_token_i) &&
      (miq1_next_head_mmu_epoch_w == mem1_sq_query_mmu_epoch_i);
  wire mem_sq_query_selected_miq_exact_w =
      mem_sq_query_head_miq_exact_w || mem_sq_query_next_miq_exact_w;
  wire mem1_sq_query_selected_miq_exact_w =
      mem1_sq_query_head_miq_exact_w || mem1_sq_query_next_miq_exact_w;
  wire [ROB_INDEX_W-1:0] mem_sq_query_selected_rob_w =
      mem_sq_query_station_source_w ? miq_next_head_rob_w : miq_head_rob_w;
  wire [ROB_INDEX_W-1:0] mem1_sq_query_selected_rob_w =
      mem1_sq_query_station_source_w ? miq1_next_head_rob_w :
                                       miq1_head_rob_w;
  wire mem_sq_query_selected_killed_w = mem_sq_query_station_source_w ?
      miq_next_head_effective_killed_w : miq_head_effective_killed_w;
  wire mem1_sq_query_selected_killed_w = mem1_sq_query_station_source_w ?
      miq1_next_head_effective_killed_w : miq1_head_effective_killed_w;
  wire mem_sq_query_tracker_exact_w =
      mem_sq_query_selected_miq_exact_w &&
      mem_owner_live_mask_w[mem_sq_query_owner_token_i] &&
      (mem_owner_kind_table_w[mem_sq_query_owner_token_i*2 +: 2] ==
       mem_sq_query_owner_kind_i) &&
      (mem_owner_epoch_table_w[mem_sq_query_owner_token_i*2 +: 2] ==
       mem_sq_query_mmu_epoch_i) &&
      (mem_sq_query_owner_kind_i == MEM_OWNER_LOAD) &&
      (mem_sq_query_producer_id_w[ROB_INDEX_W-1:0] ==
       mem_sq_query_selected_rob_w);
  wire mem1_sq_query_tracker_exact_w =
      mem1_sq_query_selected_miq_exact_w &&
      mem_owner_live_mask_w[mem1_sq_query_owner_token_i] &&
      (mem_owner_kind_table_w[mem1_sq_query_owner_token_i*2 +: 2] ==
       mem1_sq_query_owner_kind_i) &&
      (mem_owner_epoch_table_w[mem1_sq_query_owner_token_i*2 +: 2] ==
       mem1_sq_query_mmu_epoch_i) &&
      (mem1_sq_query_owner_kind_i == MEM_OWNER_LOAD) &&
      (mem1_sq_query_producer_id_w[ROB_INDEX_W-1:0] ==
       mem1_sq_query_selected_rob_w);
  wire mem_sq_query_pre_lq_exact_w = mem_sq_query_tracker_exact_w &&
      !mem_sq_query_selected_killed_w;
  wire mem1_sq_query_pre_lq_exact_w = mem1_sq_query_tracker_exact_w &&
      !mem1_sq_query_selected_killed_w;
  wire mem_sq_query_exact_w = mem_sq_query_pre_lq_exact_w &&
      lq_query0_open_w;
  wire mem1_sq_query_exact_w = mem1_sq_query_pre_lq_exact_w &&
      lq_query1_open_w;

  wire sq_query0_allow_w;
  wire sq_query0_forward_w;
  wire sq_query0_replay_w;
  wire [`XLEN-1:0] sq_query0_forward_data_w;
  wire sq_query1_allow_w;
  wire sq_query1_forward_w;
  wire sq_query1_replay_w;
  wire [`XLEN-1:0] sq_query1_forward_data_w;

  assign lq_query0_update_w = ENABLE_DUAL_MEM &&
      mem_sq_query_pre_lq_exact_w && lq_query0_open_w &&
      (sq_query0_allow_w || sq_query0_forward_w || sq_query0_replay_w);
  assign lq_query1_update_w = ENABLE_DUAL_MEM &&
      mem1_sq_query_pre_lq_exact_w && lq_query1_open_w &&
      (sq_query1_allow_w || sq_query1_forward_w || sq_query1_replay_w);

  // Default-off reusable wrappers retain the legacy VA issue gate and merely
  // pass bank0 loads through this new bridge state.  Canonical dual mode owns
  // both physical queries and retry holders.
  assign mem_sq_query_allow_o = !ENABLE_DUAL_MEM ? mem_sq_query_valid_i :
      (mem_sq_query_exact_w && sq_query0_allow_w);
  assign mem_sq_query_forward_o = ENABLE_DUAL_MEM &&
      mem_sq_query_exact_w && sq_query0_forward_w;
  assign mem_sq_query_replay_o = ENABLE_DUAL_MEM && mem_sq_query_valid_i &&
      (!mem_sq_query_exact_w || sq_query0_replay_w);
  assign mem_sq_query_forward_data_o = sq_query0_forward_data_w;
  assign mem_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem_sq_query_exact_w && !mem_retry0_valid_q &&
      !mem_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w;

  assign mem1_sq_query_allow_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_exact_w && sq_query1_allow_w;
  assign mem1_sq_query_forward_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_exact_w && sq_query1_forward_w;
  assign mem1_sq_query_replay_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_valid_i &&
      (!mem1_sq_query_exact_w || sq_query1_replay_w);
  assign mem1_sq_query_forward_data_o = sq_query1_forward_data_w;
  assign mem1_sq_query_retry_ready_o = ENABLE_DUAL_MEM &&
      mem1_sq_query_exact_w && !mem_retry1_valid_q &&
      !mem1_sq_query_station_source_w &&
      !flush_i && !checkpoint_restore_hold_w;

  assign mem_sq_retry0_capture_w = mem_sq_query_valid_i &&
      mem_sq_query_replay_o && mem_sq_query_retry_ready_o;
  assign mem_sq_retry1_capture_w = mem1_sq_query_valid_i &&
      mem1_sq_query_replay_o && mem1_sq_query_retry_ready_o;

  // MIQ retry pop is a nonterminal holder transfer.  An active-owner bridge
  // drop is instead the terminal pop for a selectively recovered owner.  A
  // delayed global-flush drop may arrive after the MIQ flush compactor already
  // removed that owner, so only an exact, still-resident, effectively-killed
  // head is admitted to this queue pop port.  The tagged collector receives
  // every raw drop independently below and remains the tracker lifetime sink.
  wire miq_drop0_head_tuple_exact_w = mem_drop0_valid_i &&
      miq_head_valid_w &&
      (miq_head_owner_kind_w == mem_drop0_owner_kind_i) &&
      (miq_head_owner_token_w == mem_drop0_owner_token_i) &&
      (miq_head_mmu_epoch_w == mem_drop0_mmu_epoch_i) &&
      (miq_head_fault_tval_w == mem_drop0_fault_tval_i);
  wire miq1_drop0_head_tuple_exact_w = ENABLE_DUAL_MEM &&
      mem1_drop0_valid_i && miq1_head_valid_w &&
      (miq1_head_owner_kind_w == mem1_drop0_owner_kind_i) &&
      (miq1_head_owner_token_w == mem1_drop0_owner_token_i) &&
      (miq1_head_mmu_epoch_w == mem1_drop0_mmu_epoch_i) &&
      (miq1_head_fault_tval_w == mem1_drop0_fault_tval_i);
  assign miq_drop0_pop_w = miq_drop0_head_tuple_exact_w &&
      miq_head_effective_killed_w && miq_head_tracker_exact_w;
  assign miq1_drop0_pop_w = mem1_drop0_valid_i && miq1_head_valid_w &&
      miq1_head_effective_killed_w && miq1_head_tracker_exact_w;

  // Response, retry transfer and bridge drop are state-exclusive in one bank;
  // the explicit mux keeps the queue's identity/provenance comparator
  // authoritative for all three ownership transitions.
  assign miq_queue_pop_valid_w =
      miq_pop_transport_w || mem_sq_retry0_capture_w || miq_drop0_pop_w;
  assign miq_queue_pop_owner_kind_w = mem_sq_retry0_capture_w ?
      mem_sq_query_owner_kind_i :
      miq_drop0_pop_w ? mem_drop0_owner_kind_i : mem_rsp_owner_kind_i;
  assign miq_queue_pop_owner_token_w = mem_sq_retry0_capture_w ?
      mem_sq_query_owner_token_i :
      miq_drop0_pop_w ? mem_drop0_owner_token_i : mem_rsp_owner_token_i;
  assign miq_queue_pop_mmu_epoch_w = mem_sq_retry0_capture_w ?
      mem_sq_query_mmu_epoch_i :
      miq_drop0_pop_w ? mem_drop0_mmu_epoch_i : mem_rsp_mmu_epoch_i;
  assign miq_queue_pop_fault_tval_w = mem_sq_retry0_capture_w ?
      miq_head_fault_tval_w :
      miq_drop0_pop_w ? mem_drop0_fault_tval_i : mem_rsp_fault_tval_i;
  assign miq1_queue_pop_valid_w =
      miq1_pop_transport_w || mem_sq_retry1_capture_w || miq1_drop0_pop_w;
  assign miq1_queue_pop_owner_kind_w = mem_sq_retry1_capture_w ?
      mem1_sq_query_owner_kind_i :
      miq1_drop0_pop_w ? mem1_drop0_owner_kind_i : mem1_rsp_owner_kind_i;
  assign miq1_queue_pop_owner_token_w = mem_sq_retry1_capture_w ?
      mem1_sq_query_owner_token_i :
      miq1_drop0_pop_w ? mem1_drop0_owner_token_i : mem1_rsp_owner_token_i;
  assign miq1_queue_pop_mmu_epoch_w = mem_sq_retry1_capture_w ?
      mem1_sq_query_mmu_epoch_i :
      miq1_drop0_pop_w ? mem1_drop0_mmu_epoch_i : mem1_rsp_mmu_epoch_i;
  assign miq1_queue_pop_fault_tval_w = mem_sq_retry1_capture_w ?
      miq1_head_fault_tval_w :
      miq1_drop0_pop_w ? mem1_drop0_fault_tval_i : mem1_rsp_fault_tval_i;

  assign mem_retry0_selective_kill_w = branch_resolve_mispredict_w &&
      mem_retry0_valid_q &&
      ((mem_retry0_rob_idx_q - rob_head_idx_w) >
       (branch_resolve_rob_idx_o - rob_head_idx_w));
  assign mem_retry1_selective_kill_w = branch_resolve_mispredict_w &&
      mem_retry1_valid_q &&
      ((mem_retry1_rob_idx_q - rob_head_idx_w) >
       (branch_resolve_rob_idx_o - rob_head_idx_w));
  assign mem_retry0_global_cancel_w = mem_retry0_valid_q &&
      (flush_i || checkpoint_restore_apply_w);
  assign mem_retry1_global_cancel_w = mem_retry1_valid_q &&
      (flush_i || checkpoint_restore_apply_w);
  assign mem_retry0_cancel_w = mem_retry0_selective_kill_w ||
                               mem_retry0_global_cancel_w;
  assign mem_retry1_cancel_w = mem_retry1_selective_kill_w ||
                               mem_retry1_global_cancel_w;

  always @(posedge clk) begin
    if (rst) begin
      mem_retry0_valid_q <= 1'b0;
      mem_retry0_producer_id_q <= {PRODUCER_ID_W{1'b0}};
      mem_retry0_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem_retry0_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_retry0_pdest_fp_q <= 1'b0;
      mem_retry0_size_q <= 2'b0;
      mem_retry0_unsigned_q <= 1'b0;
      mem_retry0_addr_q <= {`XLEN{1'b0}};
      mem_retry0_wdata_q <= {`XLEN{1'b0}};
      mem_retry0_wstrb_q <= {`STRB_W{1'b0}};
      mem_retry0_owner_kind_q <= MEM_OWNER_RESERVED;
      mem_retry0_owner_token_q <= 5'b0;
      mem_retry0_mmu_epoch_q <= 2'b0;
      mem_retry0_fault_tval_q <= {`XLEN{1'b0}};
    end else if (mem_retry0_cancel_w || mem_retry0_req_fire_w) begin
      mem_retry0_valid_q <= 1'b0;
    end else if (mem_sq_retry0_capture_w) begin
      mem_retry0_valid_q <= 1'b1;
      mem_retry0_producer_id_q <= mem_sq_query_producer_id_w;
      mem_retry0_rob_idx_q <= miq_head_rob_w;
      mem_retry0_pdest_q <= miq_head_pdest_w;
      mem_retry0_pdest_fp_q <= miq_head_pdest_fp_w;
      mem_retry0_size_q <= miq_head_size_w;
      mem_retry0_unsigned_q <= miq_head_unsigned_w;
      mem_retry0_addr_q <= miq_head_addr_w;
      mem_retry0_wdata_q <= miq_head_wdata_w;
      mem_retry0_wstrb_q <= miq_head_wstrb_w;
      mem_retry0_owner_kind_q <= miq_head_owner_kind_w;
      mem_retry0_owner_token_q <= miq_head_owner_token_w;
      mem_retry0_mmu_epoch_q <= miq_head_mmu_epoch_w;
      mem_retry0_fault_tval_q <= miq_head_fault_tval_w;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      mem_retry1_valid_q <= 1'b0;
      mem_retry1_producer_id_q <= {PRODUCER_ID_W{1'b0}};
      mem_retry1_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem_retry1_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_retry1_pdest_fp_q <= 1'b0;
      mem_retry1_size_q <= 2'b0;
      mem_retry1_unsigned_q <= 1'b0;
      mem_retry1_addr_q <= {`XLEN{1'b0}};
      mem_retry1_wdata_q <= {`XLEN{1'b0}};
      mem_retry1_wstrb_q <= {`STRB_W{1'b0}};
      mem_retry1_owner_kind_q <= MEM_OWNER_RESERVED;
      mem_retry1_owner_token_q <= 5'b0;
      mem_retry1_mmu_epoch_q <= 2'b0;
      mem_retry1_fault_tval_q <= {`XLEN{1'b0}};
    end else if (mem_retry1_cancel_w || mem_retry1_req_fire_w) begin
      mem_retry1_valid_q <= 1'b0;
    end else if (mem_sq_retry1_capture_w) begin
      mem_retry1_valid_q <= 1'b1;
      mem_retry1_producer_id_q <= mem1_sq_query_producer_id_w;
      mem_retry1_rob_idx_q <= miq1_head_rob_w;
      mem_retry1_pdest_q <= miq1_head_pdest_w;
      mem_retry1_pdest_fp_q <= miq1_head_pdest_fp_w;
      mem_retry1_size_q <= miq1_head_size_w;
      mem_retry1_unsigned_q <= miq1_head_unsigned_w;
      mem_retry1_addr_q <= miq1_head_addr_w;
      mem_retry1_wdata_q <= miq1_head_wdata_w;
      mem_retry1_wstrb_q <= miq1_head_wstrb_w;
      mem_retry1_owner_kind_q <= miq1_head_owner_kind_w;
      mem_retry1_owner_token_q <= miq1_head_owner_token_w;
      mem_retry1_mmu_epoch_q <= miq1_head_mmu_epoch_w;
      mem_retry1_fault_tval_q <= miq1_head_fault_tval_w;
    end
  end

  assign mem1_completion_query_valid_w = ENABLE_DUAL_MEM &&
      mem1_rsp_valid_i && miq1_head_valid_w && miq1_pop_owner_match_w &&
      miq1_head_tracker_exact_w;
  wire mem_completion_done_now_w =
      (ex0_wb_valid_w &&
       (ex0_producer_id_q == mem_completion_producer_id_w)) ||
      (ex1_wb_valid_w &&
       (ex1_producer_id_q == mem_completion_producer_id_w));
  wire mem1_completion_done_now_w =
      (ex0_wb_valid_w &&
       (ex0_producer_id_q == mem1_completion_producer_id_w)) ||
      (ex1_wb_valid_w &&
       (ex1_producer_id_q == mem1_completion_producer_id_w));
  wire mem_response_tuple_exact_w =
      mem_rsp_valid_i && miq_head_valid_w && miq_pop_owner_match_w;
  wire mem_holder_phase_valid_w = !miq_head_legacy_w || mem_pending_q;
  wire mem_owner_base_open_w = mem_response_tuple_exact_w &&
      miq_head_tracker_exact_w && mem_holder_phase_valid_w &&
      mem_completion_rob_open_w &&
      !miq_head_effective_killed_w && !mem_completion_done_now_w;
  wire mem1_response_tuple_exact_w = ENABLE_DUAL_MEM &&
      mem1_rsp_valid_i && miq1_head_valid_w && miq1_pop_owner_match_w;
  wire mem1_owner_base_open_w = mem1_response_tuple_exact_w &&
      miq1_head_tracker_exact_w && mem1_completion_rob_open_w &&
      !miq1_head_effective_killed_w && !mem1_completion_done_now_w;
  assign lq_response0_query_valid_w = mem_owner_base_open_w &&
      miq_head_load_w;
  assign lq_response1_query_valid_w = mem1_owner_base_open_w &&
      miq1_head_load_w;
  wire mem_owner_open_w = mem_owner_base_open_w &&
      (!miq_head_load_w || lq_response0_open_w);
  wire mem1_owner_open_w = mem1_owner_base_open_w &&
      (!miq1_head_load_w || lq_response1_open_w);
  wire mem1_owner_closed_w = mem1_response_tuple_exact_w &&
      !mem1_owner_base_open_w;
  wire mem1_legal_closed_response_w = mem1_owner_closed_w &&
      miq1_head_tracker_exact_w;
  wire mem1_fatal_response_w = mem1_owner_closed_w &&
      !miq1_head_tracker_exact_w;
  wire mem_owner_closed_w =
      mem_response_tuple_exact_w && !mem_owner_base_open_w;
  wire mem_irrevocable_amo_response_w = miq_head_legacy_w &&
      mem_pending_q && mem_amo_q && mem_amo_write_sent_q;
  wire mem_fatal_irrevocable_response_w = mem_owner_closed_w &&
      (!miq_head_tracker_exact_w || !mem_holder_phase_valid_w ||
       miq_head_drain_w ||
       mem_irrevocable_amo_response_w);
  wire mem_legal_closed_response_w = mem_owner_closed_w &&
      miq_head_tracker_exact_w && mem_holder_phase_valid_w &&
      !miq_head_drain_w &&
      !mem_irrevocable_amo_response_w;
  // T4M: bridge FSM and MIQ responses are strictly in order, so MIQ head is
  // the exact owner of the current bridge transaction.  Physical device
  // classification remains in the bridge; backend only supplies lifetime.
  assign mem_req_device_release_o =
      miq_head_valid_w && miq_head_tracker_exact_w &&
      !miq_head_effective_killed_w && rob_head_valid_w &&
      rob_head_launch_open_w &&
      (mem_completion_producer_id_w == rob_head_producer_id_w);
  assign mem_req_device_cancel_o =
      miq_head_valid_w && miq_head_effective_killed_w;
  assign mem1_req_device_release_o = ENABLE_DUAL_MEM &&
      miq1_head_valid_w && miq1_head_tracker_exact_w &&
      !miq1_head_effective_killed_w && rob_head_valid_w &&
      rob_head_launch_open_w &&
      (mem1_completion_producer_id_w == rob_head_producer_id_w);
  assign mem1_req_device_cancel_o = ENABLE_DUAL_MEM &&
      miq1_head_valid_w && miq1_head_effective_killed_w;
  // 旧 wants 语义收窄到 LEGACY(AMO/LR/SC/MMIO 独占族)
  wire mem_rsp_wants_w = miq_head_legacy_w && mem_pending_q &&
                         mem_rsp_valid_i;
  // plain LOAD: killed 恒收(静默弃); 活 load 需 wb 槽。PROBE: mode1 成功只
  // fill、不占 wb；fault（以及 shadow mode 的真实写响应）需 wb 槽。DRAIN/B
  // 始终需要 formal WB credit，ready 不得提前吞掉精确 terminal。
  wire miq_load_rsp_wants_w = miq_head_load_w && mem_rsp_valid_i;
  wire miq_probe_rsp_wants_w = miq_head_probe_w && mem_rsp_valid_i;
  wire miq_drain_rsp_wants_w = miq_head_drain_w && mem_rsp_valid_i;
  wire miq1_load_rsp_wants_w = ENABLE_DUAL_MEM && miq1_head_load_w &&
      mem1_rsp_valid_i;
  wire miq1_probe_rsp_wants_w = ENABLE_DUAL_MEM && miq1_head_probe_w &&
      mem1_rsp_valid_i;
  wire mem_rsp_fault_w = mem_rsp_error_i || mem_rsp_page_fault_i;
  wire mem1_rsp_fault_w = mem1_rsp_error_i || mem1_rsp_page_fault_i;
  assign mem_idle_o =
      miq_empty_w && (!ENABLE_DUAL_MEM || miq1_empty_w) &&
      !mem_pending_q && !mem_buffer_valid_q &&
      !mem_retry0_valid_q && !mem_retry1_valid_q &&
      !mem_issue_res_valid_q && !mem_issue1_res_valid_q &&
      (mem_owner_live_count_w == 6'd0) &&
      (mem_terminal_pending_count_w == 6'd0);
  // 【LSQ·SQ 切换】退休侧静默: SQ 排空且无 drain 在飞。AND 进 backend_drained,
  // system/trap/FP 等串行点等它(mem_idle_o 保持原语义, 供分支恢复 quiet 判定)。
  assign mem_retire_quiet_o =
      !sq_mode_w || (sq_empty_w && !drain_inflight_q);
  // 【级间边界治理 P1】EX→WB 级间寄存簇提取为 PipeStageReg 实例
  // (spec: design/arch/pipeline-stage-boundary.md §4 P1——全核唯一真实 stage 寄存簇)。
  // payload 位段布局(default 149b/lane): high generation, bit144=fwd_valid；
  // 原 144b formal-WB
  // 位段保持原位：{rob[143:140], pdest[139:134], result[133:70],
  // exception[69], cause[68:64], tval[63:0]}。
  // up_valid/up_payload 由原 always 各赋值臂等价改写的组合逻辑生成(assign 在原
  // always 块位置, 见后文; 声明前置——iverilog 14 拒绝前向引用)。
  wire ex0_up_valid_w;
  wire [EX_STAGE_PAYLOAD_W-1:0] ex0_up_payload_w;
  wire ex0_up_ready_unused_w;
  wire ex1_up_valid_w;
  wire [EX_STAGE_PAYLOAD_W-1:0] ex1_up_payload_w;
  wire ex1_up_ready_unused_w;

  PipeStageReg #(.WIDTH(EX_STAGE_PAYLOAD_W)) u_ex0_stage (
    .clk(clk),
    .rst(rst),
    // destructive checkpoint recovery is issued only after irreversible writes retire
    .flush_i(flush_i || checkpoint_restore_apply_w),
    // selective kill 在消费沿前已组合切掉 completion；原语负责沿上清 raw stage。
    .kill_i(ex0_kill_now_w),
    .up_valid_i(ex0_up_valid_w),
    // up_ready: down_ready 恒 1 → up_ready 恒 1, 上游 issue 无反压消费点(现状语义)
    .up_ready_o(ex0_up_ready_unused_w),
    .up_payload_i(ex0_up_payload_w),
    .down_valid_o(ex0_valid_q),
    // down_ready: ROB wb 口恒收(ex_q 最高优先、单拍必消费)的现状语义; 未来 wb 仲裁引入反压再改
    .down_ready_i(1'b1),
    .down_payload_o(ex0_down_payload_w)
  );
  PipeStageReg #(.WIDTH(EX_STAGE_PAYLOAD_W)) u_ex1_stage (
    .clk(clk),
    .rst(rst),
    // destructive checkpoint recovery is issued only after irreversible writes retire
    .flush_i(flush_i || checkpoint_restore_apply_w),
    // selective kill 在消费沿前已组合切掉 completion；原语负责沿上清 raw stage。
    .kill_i(ex1_kill_now_w),
    .up_valid_i(ex1_up_valid_w),
    // up_ready: down_ready 恒 1 → up_ready 恒 1, 上游 issue 无反压消费点(现状语义)
    .up_ready_o(ex1_up_ready_unused_w),
    .up_payload_i(ex1_up_payload_w),
    .down_valid_o(ex1_valid_q),
    // down_ready: ROB wb 口恒收(ex_q 最高优先、单拍必消费)的现状语义; 未来 wb 仲裁引入反压再改
    .down_ready_i(1'b1),
    .down_payload_o(ex1_down_payload_w)
  );

  // _q 别名: 语义仍是寄存器输出(寄存器在 PipeStageReg 内), 下游 wb mux 读点零文本改动;
  // 提取见 design/arch/pipeline-stage-boundary.md P1。payload 仅 exN_valid_q=1 拍有效
  // (flush/未装载拍留脏——全核 valid-only 惯例, 消费方不得在 valid=0 时读)。
  assign ex0_producer_id_q =
      {ex0_down_payload_w[EX_STAGE_GEN_MSB:EX_STAGE_GEN_LSB],
       ex0_down_payload_w[EX_STAGE_ROB_IDX_MSB:EX_STAGE_ROB_IDX_LSB]};
  wire [ROB_INDEX_W-1:0] ex0_rob_idx_q =
      ex0_producer_id_q[ROB_INDEX_W-1:0];
  wire [PHY_REG_ADDR_W-1:0] ex0_pdest_q =
      ex0_down_payload_w[EX_STAGE_PDEST_MSB:EX_STAGE_PDEST_LSB];
  wire [`XLEN-1:0] ex0_result_q =
      ex0_down_payload_w[EX_STAGE_RESULT_MSB:EX_STAGE_RESULT_LSB];
  wire ex0_exception_q = ex0_down_payload_w[EX_STAGE_EXCEPTION_BIT];
  wire [`TRAP_CAUSE_W-1:0] ex0_cause_q =
      ex0_down_payload_w[EX_STAGE_CAUSE_MSB:EX_STAGE_CAUSE_LSB];
  wire [`XLEN-1:0] ex0_tval_q =
      ex0_down_payload_w[EX_STAGE_TVAL_MSB:EX_STAGE_TVAL_LSB];
  assign ex1_producer_id_q =
      {ex1_down_payload_w[EX_STAGE_GEN_MSB:EX_STAGE_GEN_LSB],
       ex1_down_payload_w[EX_STAGE_ROB_IDX_MSB:EX_STAGE_ROB_IDX_LSB]};
  wire [ROB_INDEX_W-1:0] ex1_rob_idx_q =
      ex1_producer_id_q[ROB_INDEX_W-1:0];
  wire [PHY_REG_ADDR_W-1:0] ex1_pdest_q =
      ex1_down_payload_w[EX_STAGE_PDEST_MSB:EX_STAGE_PDEST_LSB];
  wire [`XLEN-1:0] ex1_result_q =
      ex1_down_payload_w[EX_STAGE_RESULT_MSB:EX_STAGE_RESULT_LSB];
  wire ex1_exception_q = ex1_down_payload_w[EX_STAGE_EXCEPTION_BIT];
  wire [`TRAP_CAUSE_W-1:0] ex1_cause_q =
      ex1_down_payload_w[EX_STAGE_CAUSE_MSB:EX_STAGE_CAUSE_LSB];
  wire [`XLEN-1:0] ex1_tval_q =
      ex1_down_payload_w[EX_STAGE_TVAL_MSB:EX_STAGE_TVAL_LSB];

  // v8d INT-EX-K1/K3/K4：与 ROB/IQ/FP/long-op 共用等宽环形年龄律。
  // boundary 本身 age 相等必须存活；只清严格年轻后缀。这里不能只依赖
  // ROB squash，因为 PRF write、BusyTable/IQ wake 均发生在 ROB 入口之前。
  wire [ROB_INDEX_W-1:0] ex_kill_boundary_age_w =
      branch_resolve_rob_idx_o - rob_head_idx_w;
  wire [ROB_INDEX_W-1:0] ex0_completion_age_w =
      ex0_rob_idx_q - rob_head_idx_w;
  wire [ROB_INDEX_W-1:0] ex1_completion_age_w =
      ex1_rob_idx_q - rob_head_idx_w;
  assign ex0_kill_now_w =
      branch_resolve_mispredict_w && ex0_valid_q &&
      (ex0_completion_age_w > ex_kill_boundary_age_w);
  assign ex1_kill_now_w =
      branch_resolve_mispredict_w && ex1_valid_q &&
      (ex1_completion_age_w > ex_kill_boundary_age_w);
  assign ex0_pre_auth_valid_w = ex0_valid_q && !ex0_kill_now_w &&
                                !rst && !flush_i &&
                                !checkpoint_restore_apply_w;
  assign ex1_pre_auth_valid_w = ex1_valid_q && !ex1_kill_now_w &&
                                !rst && !flush_i &&
                                !checkpoint_restore_apply_w;
  wire ex0_fp_pending_owned_w =
      fp_completion_pending_mask_w[ex0_producer_id_q];
  wire ex1_fp_pending_owned_w =
      fp_completion_pending_mask_w[ex1_producer_id_q];
  assign ex0_wb_valid_w = ex0_pre_auth_valid_w && ex0_producer_open_w &&
                          !ex0_fp_pending_owned_w;
  // v8h same-edge claim head: both ROB queries observe edge-old done_q, so
  // full-PID equality must suppress the lower-priority actual side effect.
  wire ex1_same_edge_claimed_w = ex0_wb_valid_w &&
      (ex0_producer_id_q == ex1_producer_id_q);
  assign ex1_wb_valid_w = ex1_pre_auth_valid_w && ex1_producer_open_w &&
                          !ex1_fp_pending_owned_w &&
                          !ex1_same_edge_claimed_w;
  assign ex0_wb_slot_occupied_w = ex0_pre_auth_valid_w;
  assign ex1_wb_slot_occupied_w = ex1_pre_auth_valid_w;

`ifdef OOO_ASSERT
  // 独立按 raw identity/年龄检查副作用资格；compile-success mutation 若恢复
  // raw-valid 直通，会精确命中该 marker，而不是靠编译失败造 RED。
  always @(posedge clk) begin
    if (!rst && ex0_kill_now_w && ex0_wb_valid_w)
      $error("[INT-EX0-COMPLETION-KILL-CUT] younger raw EX0 exposed completion @%0t",
             $time);
    if (!rst && ex1_kill_now_w && ex1_wb_valid_w)
      $error("[INT-EX1-COMPLETION-KILL-CUT] younger raw EX1 exposed completion @%0t",
             $time);
    if (!rst && branch_resolve_mispredict_w && ex0_valid_q &&
        (ex0_completion_age_w <= ex_kill_boundary_age_w) &&
        !ex0_pre_auth_valid_w)
      $error("[INT-EX0-COMPLETION-SURVIVOR] older/equal EX0 was suppressed @%0t",
             $time);
    if (!rst && branch_resolve_mispredict_w && ex1_valid_q &&
        (ex1_completion_age_w <= ex_kill_boundary_age_w) &&
        !ex1_pre_auth_valid_w)
      $error("[INT-EX1-COMPLETION-SURVIVOR] older/equal EX1 was suppressed @%0t",
             $time);
    if (!rst && ex0_wb_valid_w && !ex0_producer_open_w)
      $error("[V8F-EX0-COMPLETION-AUTH] completion escaped exact-open gate @%0t",
             $time);
    if (!rst && ex1_wb_valid_w && !ex1_producer_open_w)
      $error("[V8F-EX1-COMPLETION-AUTH] completion escaped exact-open gate @%0t",
             $time);
    if (!rst && ex0_wb_valid_w && ex1_wb_valid_w &&
        (ex0_producer_id_q == ex1_producer_id_q))
      $error("[V8H-EX-SAME-EDGE-CLAIM] EX0/EX1 completed one PID twice @%0t",
             $time);
    if (!rst && ex0_wb_valid_w && ex0_fp_pending_owned_w)
      $error("[V8I-EX0-PENDING-FENCE] EX0 bypassed FP completion owner @%0t",
             $time);
    if (!rst && ex1_wb_valid_w && ex1_fp_pending_owned_w)
      $error("[V8I-EX1-PENDING-FENCE] EX1 bypassed FP completion owner @%0t",
             $time);
    if (!rst && early_wakeup0_valid_w && !iq_issue0_producer_current_w)
      $error("[V8F-EARLY0-CURRENT-AUTH] early wake escaped current-ID gate @%0t",
             $time);
    if (!rst && early_wakeup1_valid_w && !issue1_producer_current_w)
      $error("[V8F-EARLY1-CURRENT-AUTH] early wake escaped current-ID gate @%0t",
             $time);
    if (!rst && iq_issue0_valid_w &&
        (iq_issue0_producer_id_w[ROB_INDEX_W-1:0] != iq_issue0_rob_idx_w))
      $error("[V8F-ISSUE0-PID-INDEX] pid=%h raw=%h @%0t",
             iq_issue0_producer_id_w, iq_issue0_rob_idx_w, $time);
    if (!rst && issue1_valid_w &&
        (issue1_producer_id_w[ROB_INDEX_W-1:0] != issue1_rob_idx_w))
      $error("[V8F-ISSUE1-PID-INDEX] pid=%h raw=%h @%0t",
             issue1_producer_id_w, issue1_rob_idx_w, $time);
  end
`endif

  wire [1:0] wb_free_count_w =
      {1'b0, !ex0_wb_slot_occupied_w} +
      {1'b0, !ex1_wb_slot_occupied_w};
  wire wb_slot_free_w = (wb_free_count_w != 2'b00);
  wire mem_amo_read_candidate_w = mem_owner_open_w &&
      miq_head_legacy_w && mem_pending_q && mem_amo_q &&
      !mem_amo_lr_q && !mem_amo_sc_q && !mem_amo_write_phase_q &&
      !mem_rsp_error_i && !mem_rsp_page_fault_i;
  // v8t terminal DAG: lanes2..11 are raw, non-backpressurable candidates.
  // Response-bank cross masks are also raw (never READY/fire-derived), so two
  // malformed aliases fail closed instead of entering the collector twice.
  wire mem_response_terminal_raw_w = mem_response_tuple_exact_w &&
      !mem_fatal_irrevocable_response_w &&
      ((miq_head_legacy_w && !mem_amo_read_candidate_w) ||
       (miq_head_load_w &&
        (mem_owner_open_w || mem_legal_closed_response_w)) ||
       (miq_head_probe_w && mem_legal_closed_response_w));
  wire mem1_response_terminal_raw_w = mem1_response_tuple_exact_w &&
      !mem1_fatal_response_w &&
      ((miq1_head_load_w &&
        (mem1_owner_open_w || mem1_legal_closed_response_w)) ||
       (miq1_head_probe_w && mem1_legal_closed_response_w));
  wire [31:0] mem_terminal_nonresponse_raw_mask_w =
      mem_terminal_ingress2_mask_w | mem_terminal_ingress3_mask_w |
      mem_terminal_ingress4_mask_w | mem_terminal_ingress5_mask_w |
      mem_terminal_ingress6_mask_w | mem_terminal_ingress7_mask_w |
      mem_terminal_ingress8_mask_w | mem_terminal_ingress9_mask_w |
      mem_terminal_ingress10_mask_w | mem_terminal_ingress11_mask_w;
  wire [31:0] mem_response_other_raw_mask_w =
      mem_terminal_nonresponse_raw_mask_w |
      (mem1_response_terminal_raw_w ?
       (32'b1 << miq1_head_owner_token_w) : 32'b0);
  wire [31:0] mem1_response_other_raw_mask_w =
      mem_terminal_nonresponse_raw_mask_w |
      (mem_response_terminal_raw_w ?
       (32'b1 << miq_head_owner_token_w) : 32'b0);
  wire mem_response_terminal_credit_w =
      !mem_terminal_pending_mask_w[miq_head_owner_token_w] &&
      !mem_response_other_raw_mask_w[miq_head_owner_token_w];
  wire mem1_response_terminal_credit_w =
      !mem_terminal_pending_mask_w[miq1_head_owner_token_w] &&
      !mem1_response_other_raw_mask_w[miq1_head_owner_token_w];

  // The SQ terminal CAM has two physical write ports.  Local exception
  // terminals cannot be backpressured and therefore take fixed priority;
  // bank0 then bank1 response candidates consume any remaining ports.
  assign mem_sq_response_candidate_w = mem_owner_open_w &&
      ((miq_head_probe_w && (mem_rsp_fault_w || !sq_mode_w)) ||
       miq_head_drain_w);
  assign mem1_sq_response_candidate_w = mem1_owner_open_w &&
      miq1_head_probe_w && (mem1_rsp_fault_w || !sq_mode_w);
  wire [1:0] sq_local_terminal_count_w =
      {1'b0, sq_local_store_exception0_w} +
      {1'b0, sq_local_store_exception1_w};
  wire [1:0] sq_local_terminal_count_for_rsp_w = ENABLE_DUAL_MEM ?
      sq_local_terminal_count_w : 2'b00;
  assign mem_sq_response_grant_w = mem_sq_response_candidate_w &&
      (sq_local_terminal_count_for_rsp_w < 2'd2);
  assign mem1_sq_response_grant_w = mem1_sq_response_candidate_w &&
      ((sq_local_terminal_count_for_rsp_w +
        {1'b0, mem_sq_response_grant_w}) < 2'd2);

  wire mem_open_needs_wb_w = mem_owner_open_w &&
      (miq_head_drain_w || miq_head_load_w ||
       (miq_head_probe_w && (mem_rsp_fault_w || !sq_mode_w)) ||
       (miq_head_legacy_w && !mem_amo_read_candidate_w));
  wire mem1_open_needs_wb_w = mem1_owner_open_w &&
      (miq1_head_load_w ||
       (miq1_head_probe_w && (mem1_rsp_fault_w || !sq_mode_w)));
  wire mem_open_terminal_credit_w =
      miq_head_drain_w || mem_response_terminal_credit_w;
  wire mem1_open_terminal_credit_w = mem1_response_terminal_credit_w;
  wire mem_fp_load_sink_candidate_w = mem_owner_open_w &&
      miq_head_load_w && miq_head_pdest_fp_w;
  wire mem1_fp_load_sink_candidate_w = mem1_owner_open_w &&
      miq1_head_load_w && miq1_head_pdest_fp_w;
  wire mem_open_nonwb_sink_credit_w = mem_open_terminal_credit_w &&
      (!mem_sq_response_candidate_w || mem_sq_response_grant_w);
  wire mem1_open_nonwb_sink_credit_w = mem1_open_terminal_credit_w &&
      (!mem1_sq_response_candidate_w || mem1_sq_response_grant_w) &&
      !(mem1_fp_load_sink_candidate_w && mem_fp_load_sink_candidate_w);

  // One global two-slot allocator observes edge-old EX occupancy, then gives
  // bank0/bank1 memory candidates deterministic priority.  A candidate only
  // reserves WB after all of its non-WB sinks have credit, avoiding a stalled
  // collector/SQ sink from needlessly hiding a slot from the peer bank.
  wire mem_wb_slot0_grant_w = mem_open_needs_wb_w &&
      mem_open_nonwb_sink_credit_w && !ex0_wb_slot_occupied_w;
  wire mem_wb_slot1_grant_w = mem_open_needs_wb_w &&
      mem_open_nonwb_sink_credit_w && !mem_wb_slot0_grant_w &&
      !ex1_wb_slot_occupied_w;
  wire mem1_wb_slot0_grant_w = mem1_open_needs_wb_w &&
      mem1_open_nonwb_sink_credit_w && !ex0_wb_slot_occupied_w &&
      !mem_wb_slot0_grant_w;
  wire mem1_wb_slot1_grant_w = mem1_open_needs_wb_w &&
      mem1_open_nonwb_sink_credit_w && !mem1_wb_slot0_grant_w &&
      !ex1_wb_slot_occupied_w && !mem_wb_slot1_grant_w;
  wire mem_wb_route_credit_w = mem_wb_slot0_grant_w ||
                               mem_wb_slot1_grant_w;
  wire mem1_wb_route_credit_w = mem1_wb_slot0_grant_w ||
                                mem1_wb_slot1_grant_w;
  wire mem_open_all_sink_credit_w = mem_open_nonwb_sink_credit_w &&
      (!mem_open_needs_wb_w || mem_wb_route_credit_w);
  wire mem1_open_all_sink_credit_w = mem1_open_nonwb_sink_credit_w &&
      (!mem1_open_needs_wb_w || mem1_wb_route_credit_w);
  // exact open responses wait for every sink.  Legal speculative closed
  // responses wait only for lossless terminal credit.  Tracker/tag failures,
  // closed physical STORE, and post-write AMO responses drain the bus into a
  // fatal poison state without normal WB/collector/death.
  assign mem_rsp_ready_o =
      !miq_head_valid_w ? 1'b1 :
      !mem_rsp_valid_i ? 1'b1 :
      !miq_pop_owner_match_w ? 1'b1 :
      mem_owner_open_w ? mem_open_all_sink_credit_w :
      mem_fatal_irrevocable_response_w ? 1'b1 :
      mem_legal_closed_response_w ? mem_response_terminal_credit_w :
      1'b0;
  assign mem1_rsp_ready_o =
      !ENABLE_DUAL_MEM ? 1'b1 :
      !miq1_head_valid_w ? 1'b1 :
      !mem1_rsp_valid_i ? 1'b1 :
      !miq1_pop_owner_match_w ? 1'b1 :
      mem1_owner_open_w ? mem1_open_all_sink_credit_w :
      mem1_fatal_response_w ? 1'b1 :
      mem1_legal_closed_response_w ? mem1_response_terminal_credit_w :
      1'b0;
  // Outer transport drains independently of equality.  Only the exact 9-bit
  // owner advances MIQ/accounting and authorizes architectural side effects.
  wire mem_rsp_transport_fire_w = mem_rsp_wants_w && mem_rsp_ready_o;
  wire miq_load_rsp_transport_fire_w =
      miq_load_rsp_wants_w && mem_rsp_ready_o;
  wire miq_probe_rsp_transport_fire_w =
      miq_probe_rsp_wants_w && mem_rsp_ready_o;
  wire miq_drain_rsp_transport_fire_w =
      miq_drain_rsp_wants_w && mem_rsp_ready_o;
  assign miq_pop_transport_w = mem_rsp_valid_i && mem_rsp_ready_o;
  assign miq_pop_w = miq_pop_transport_w && miq_pop_owner_match_w;
  wire mem_rsp_fire_w = mem_rsp_transport_fire_w && miq_pop_owner_match_w;
  wire miq_load_rsp_fire_w =
      miq_load_rsp_transport_fire_w && miq_pop_owner_match_w;
  wire miq_probe_rsp_fire_w =
      miq_probe_rsp_transport_fire_w && miq_pop_owner_match_w;
  wire miq_drain_rsp_fire_w =
      miq_drain_rsp_transport_fire_w && miq_pop_owner_match_w;
  wire mem1_rsp_transport_fire_w = ENABLE_DUAL_MEM &&
      mem1_rsp_valid_i && mem1_rsp_ready_o;
  wire miq1_load_rsp_transport_fire_w =
      miq1_load_rsp_wants_w && mem1_rsp_ready_o;
  wire miq1_probe_rsp_transport_fire_w =
      miq1_probe_rsp_wants_w && mem1_rsp_ready_o;
  assign miq1_pop_transport_w = mem1_rsp_transport_fire_w;
  assign miq1_pop_w = miq1_pop_transport_w && miq1_pop_owner_match_w;
  wire mem1_rsp_fire_w = mem1_rsp_transport_fire_w &&
      miq1_pop_owner_match_w;
  wire miq1_load_rsp_fire_w = miq1_load_rsp_transport_fire_w &&
      miq1_pop_owner_match_w;
  wire miq1_probe_rsp_fire_w = miq1_probe_rsp_transport_fire_w &&
      miq1_pop_owner_match_w;
  // AMO#2: 读阶段若 fault(error/page_fault),不得进入写阶段(否则病态 PMP W&!R 下会静默错写 +
  // rd 垃圾 + 无异常)。fault 时 mem_amo_read_rsp_w=0 → 走 mem_rsp_final_fire_w 经 mem_rsp_wb_cause_w
  // 报 LOAD fault(对齐 NEMU "AMO 先 Mr→Load fault"),且不写内存。常态(无 fault)行为不变。
  wire mem_amo_read_rsp_w =
      mem_rsp_fire_w && mem_amo_read_candidate_w;
  wire mem_rsp_final_fire_w = mem_rsp_fire_w && !mem_amo_read_rsp_w &&
      !mem_fatal_irrevocable_response_w;
  // LEGACY 单例空闲(AMO/LR/SC 独占通道)
  wire mem_legacy_slot_open_w = ENABLE_DUAL_MEM ? !mem_pending_q :
      (!mem_pending_q || mem_rsp_final_fire_w);
  // plain(LOAD/PROBE)发射: MIQ 有空且 LEGACY 空(AMO 在飞时保守不混发,
  // 保持原子窗口语义与旧版一致)。
  // 满队列同拍 pop 不做 look-through refill。OooMemInflightQueue 的 full
  // 状态下 tail==head，旧实现若让 parent 接受新请求，queue 内 push_fire
  // 仍会因 old-full 为 0，导致桥已收请求而 MIQ metadata 丢失。这里保守
  // backpressure 一拍，既保持 request<->MIQ 双射，也切断 pop/response 到
  // 新 request-valid 的满队列反馈；非满时仍支持正常同拍 pop+push。
  wire miq_slot_open_w = mem_legacy_slot_open_w && !miq_full_w;
  wire miq1_slot_open_w = ENABLE_DUAL_MEM && mem_legacy_slot_open_w &&
      !miq1_full_w;
  // AMO/LR/SC 独占: MIQ 必须全空(其读-改-写窗口内无任何 plain 在飞)。
  wire mem_amo_slot_open_w = ENABLE_DUAL_MEM ?
      (mem_legacy_slot_open_w && miq_empty_w && miq1_empty_w) :
      (mem_legacy_slot_open_w &&
       (miq_empty_w || (miq_pop_w &&
        (miq_count_w == {{MIQ_ENTRY_W{1'b0}}, 1'b1}))));
  // 兼容名: 旧引用点按"发射者是否 AMO 族"细分, 在下方逐点替换。
  wire mem_request_slot_open_w = miq_slot_open_w;
  function [ROB_INDEX_W:0] rob_distance_from_head;
    input [ROB_INDEX_W-1:0] idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      rob_distance_from_head = {1'b0, (idx - head)};
    end
  endfunction

  function rob_idx_older_than;
    input [ROB_INDEX_W-1:0] older_idx;
    input [ROB_INDEX_W-1:0] younger_idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      rob_idx_older_than =
          rob_distance_from_head(older_idx, head) <
          rob_distance_from_head(younger_idx, head);
    end
  endfunction

  wire mem_pending_store_order_block_w =
      mem_pending_q && (mem_store_q || mem_amo_q);
  wire mem_buffer_store_order_block_w =
      mem_buffer_valid_q && mem_buffer_store_q;
  // 【LSQ·歧义消解切片(spec Phase2 前半)】load 对更老在飞 store 的等待从 addr-blind
  //   (任何 store 在飞就等)细化为地址重叠判定: 双方 8B line 距离 ≤1(覆盖任一侧跨线
  //   misaligned 的保守窗口)才等, 不重叠即放行——独立 load 不再被无关 store 卡死。
  //   保守保留 blind 等待的场景: AMO/LR/SC(原子语义)与 MMIO/非 PMEM store(设备顺序),
  //   经 mem_pending_amo/mmio 判定; store→load 同址可见性仍由 dcache 精确 per-store
  //   更新(LSQ Step1)+ 重叠即等待保证, 前递(forwarding)属 Phase2 后半未启用。
  function line_overlap_1;
    input [`XLEN-1:0] la;
    input [`XLEN-1:0] sa;
    reg [`XLEN-4:0] ll;
    reg [`XLEN-4:0] sl;
    begin
      ll = la[`XLEN-1:3];
      sl = sa[`XLEN-1:3];
      line_overlap_1 = (ll == sl) ||
                       (ll + {{(`XLEN-4){1'b0}}, 1'b1} == sl) ||
                       (sl + {{(`XLEN-4){1'b0}}, 1'b1} == ll);
    end
  endfunction
  // Return true only for a completely known, routable typed class.  The
  // default branch deliberately fail-closes X/Z and RSVD provenance.
  function typed_mem_attr_admitted;
    input attr_valid;
    input [1:0] mem_class;
    begin
      case ({attr_valid, mem_class})
        {1'b1, `OOO_MEM_CLASS_CACHED},
        {1'b1, `OOO_MEM_CLASS_NC},
        {1'b1, `OOO_MEM_CLASS_IO}: typed_mem_attr_admitted = 1'b1;
        default: typed_mem_attr_admitted = 1'b0;
      endcase
    end
  endfunction
  // A pending/buffered store has not completed the translated probe and has
  // no typed class yet.  It therefore remains address-blind for younger loads.
  wire mem_pending_blind_w =
      mem_pending_q && (mem_amo_q || mem_store_q);
  wire mem_buffer_blind_w = mem_buffer_valid_q && mem_buffer_store_q;
  // 【LSQ·T4N】An ordinary load is still unknown-class before bridge.  If it
  // were allowed to pass an older, filled-but-not-terminal store and later
  // classified IO, it could hold S_DEVICE_WAIT while that older store needs
  // the same bridge for its drain/B: a hard cycle.  Therefore every older SQ
  // owner remains a blind barrier until its B/probe terminal is recorded.
  // This can be relaxed only with preclassification+replay or an independent
  // IO queue; neither exists in this ABI-only round.
  // issue0/issue1 分两个 always 块: 同块合并会让 Verilator 把"issue1 地址经旁路
  // 依赖 issue0_fire"的单向链误判为组合环(UNOPTFLAT)。
  reg issue0_sq_block_r;
  reg issue1_sq_block_r;
  always @(*) begin : sq_load_block0_blk
    integer k;
    reg entry_older_r;
    issue0_sq_block_r = 1'b0;
    for (k = 0; k < SQ_ENTRY_N; k = k + 1) begin
      entry_older_r = sq_snoop_request_sent_w[k] ||
          rob_idx_older_than(sq_snoop_rob_idx_w[k*ROB_INDEX_W +: ROB_INDEX_W],
                             mem_issue_res_rob_idx_q, rob_head_idx_w);
      if (sq_snoop_valid_w[k] && entry_older_r &&
          !sq_snoop_terminal_w[k])
        issue0_sq_block_r = 1'b1;
    end
  end
  always @(*) begin : sq_load_block1_blk
    integer k;
    reg entry_older_r;
    issue1_sq_block_r = 1'b0;
    for (k = 0; k < SQ_ENTRY_N; k = k + 1) begin
      entry_older_r = sq_snoop_request_sent_w[k] ||
          rob_idx_older_than(sq_snoop_rob_idx_w[k*ROB_INDEX_W +: ROB_INDEX_W],
                             mem_issue1_res_rob_idx_q, rob_head_idx_w);
      if (sq_snoop_valid_w[k] && entry_older_r &&
          !sq_snoop_terminal_w[k])
        issue1_sq_block_r = 1'b1;
    end
  end

  // 【LSQ·前递】(spec §3.7) load 命中 SQ"最年轻的更老重叠 entry"且被其全覆盖时
  // 直接取数完成(不访存)。字节语义: entry 覆盖 [eaddr, eaddr+esize)、数据低位
  // 对齐(LSU wstrb=连续 1/wdata 不 shift/内存按 addr 顺序字节), 判定=区间包含
  // (天然支持 misaligned), 数据=entry.data 右移 delta 字节后按 size/unsigned
  // 抽取。禁前递(回落 sq_block 等待): Sv39(VA 别名)/load 或 entry MMIO(设备读
  // 语义)/存在更老 addr 未知 entry(probe 未完成防御)。issue0/issue1 独立块。
  function [3:0] strb_size;
    input [`STRB_W-1:0] strb;
    integer b;
    begin
      strb_size = 4'd0;
      for (b = 0; b < `STRB_W; b = b + 1)
        if (strb[b]) strb_size = strb_size + 4'd1;
    end
  endfunction

  reg issue0_sq_fwd_hit_r;
  reg [`XLEN-1:0] issue0_sq_fwd_raw_r;
  always @(*) begin : sq_fwd0_blk
    integer i;
    reg [SQ_ENTRY_W-1:0] idx_r;
    reg [`XLEN-1:0] laddr_r;
    reg [3:0] lsize_r;
    reg [`XLEN-1:0] eaddr_r;
    reg [3:0] esize_r;
    reg older_r;
    reg overlap_r;
    reg contain_r;
    reg entry_attr_admitted_r;
    reg entry_io_r;
    reg poison_r;
    reg [2:0] delta_r;
    laddr_r = issue0_mem_addr_w;
    lsize_r = strb_size(issue0_mem_wstrb_w);
    eaddr_r = {`XLEN{1'b0}};
    esize_r = 4'd0;
    older_r = 1'b0;
    overlap_r = 1'b0;
    contain_r = 1'b0;
    delta_r = 3'd0;
    idx_r = {SQ_ENTRY_W{1'b0}};
    issue0_sq_fwd_hit_r = 1'b0;
    issue0_sq_fwd_raw_r = {`XLEN{1'b0}};
    poison_r = 1'b0;
    for (i = 0; i < SQ_ENTRY_N; i = i + 1) begin
      idx_r = sq_snoop_head_w + i[SQ_ENTRY_W-1:0];
      older_r = sq_snoop_request_sent_w[idx_r] ||
          rob_idx_older_than(
              sq_snoop_rob_idx_w[idx_r*ROB_INDEX_W +: ROB_INDEX_W],
              mem_issue_res_rob_idx_q, rob_head_idx_w);
      if (sq_snoop_valid_w[idx_r] && older_r) begin
        entry_attr_admitted_r = typed_mem_attr_admitted(
            sq_snoop_attr_valid_w[idx_r],
            sq_snoop_class_w[idx_r*2 +: 2]);
        entry_io_r = entry_attr_admitted_r &&
                     (sq_snoop_class_w[idx_r*2 +: 2] ==
                      `OOO_MEM_CLASS_IO);
        if (!sq_snoop_addr_valid_w[idx_r] || !entry_attr_admitted_r) begin
          poison_r = 1'b1;
        end else begin
          eaddr_r = sq_snoop_addr_w[idx_r*`XLEN +: `XLEN];
          esize_r = strb_size(sq_snoop_strb_w[idx_r*`STRB_W +: `STRB_W]);
          overlap_r =
              !((laddr_r + {{(`XLEN-4){1'b0}}, lsize_r} <= eaddr_r) ||
                (eaddr_r + {{(`XLEN-4){1'b0}}, esize_r} <= laddr_r));
          if (overlap_r) begin
            // 程序序扫描, 后命中者更年轻——覆盖旧记录=取最年轻的更老重叠
            contain_r =
                (eaddr_r <= laddr_r) &&
                (laddr_r + {{(`XLEN-4){1'b0}}, lsize_r} <=
                 eaddr_r + {{(`XLEN-4){1'b0}}, esize_r}) &&
                !entry_io_r;
            delta_r = laddr_r[2:0] - eaddr_r[2:0];
            issue0_sq_fwd_hit_r = contain_r;
            issue0_sq_fwd_raw_r =
                sq_snoop_data_w[idx_r*`XLEN +: `XLEN] >> {delta_r, 3'b000};
          end
        end
      end
    end
    if (poison_r || mem_translate_active_i)
      issue0_sq_fwd_hit_r = 1'b0;
  end

  reg issue1_sq_fwd_hit_r;
  reg [`XLEN-1:0] issue1_sq_fwd_raw_r;
  always @(*) begin : sq_fwd1_blk
    integer i;
    reg [SQ_ENTRY_W-1:0] idx_r;
    reg [`XLEN-1:0] laddr_r;
    reg [3:0] lsize_r;
    reg [`XLEN-1:0] eaddr_r;
    reg [3:0] esize_r;
    reg older_r;
    reg overlap_r;
    reg contain_r;
    reg entry_attr_admitted_r;
    reg entry_io_r;
    reg poison_r;
    reg [2:0] delta_r;
    laddr_r = issue1_mem_addr_w;
    lsize_r = strb_size(issue1_mem_wstrb_w);
    eaddr_r = {`XLEN{1'b0}};
    esize_r = 4'd0;
    older_r = 1'b0;
    overlap_r = 1'b0;
    contain_r = 1'b0;
    delta_r = 3'd0;
    idx_r = {SQ_ENTRY_W{1'b0}};
    issue1_sq_fwd_hit_r = 1'b0;
    issue1_sq_fwd_raw_r = {`XLEN{1'b0}};
    poison_r = 1'b0;
    for (i = 0; i < SQ_ENTRY_N; i = i + 1) begin
      idx_r = sq_snoop_head_w + i[SQ_ENTRY_W-1:0];
      older_r = sq_snoop_request_sent_w[idx_r] ||
          rob_idx_older_than(
              sq_snoop_rob_idx_w[idx_r*ROB_INDEX_W +: ROB_INDEX_W],
              mem_issue1_res_rob_idx_q, rob_head_idx_w);
      if (sq_snoop_valid_w[idx_r] && older_r) begin
        entry_attr_admitted_r = typed_mem_attr_admitted(
            sq_snoop_attr_valid_w[idx_r],
            sq_snoop_class_w[idx_r*2 +: 2]);
        entry_io_r = entry_attr_admitted_r &&
                     (sq_snoop_class_w[idx_r*2 +: 2] ==
                      `OOO_MEM_CLASS_IO);
        if (!sq_snoop_addr_valid_w[idx_r] || !entry_attr_admitted_r) begin
          poison_r = 1'b1;
        end else begin
          eaddr_r = sq_snoop_addr_w[idx_r*`XLEN +: `XLEN];
          esize_r = strb_size(sq_snoop_strb_w[idx_r*`STRB_W +: `STRB_W]);
          overlap_r =
              !((laddr_r + {{(`XLEN-4){1'b0}}, lsize_r} <= eaddr_r) ||
                (eaddr_r + {{(`XLEN-4){1'b0}}, esize_r} <= laddr_r));
          if (overlap_r) begin
            contain_r =
                (eaddr_r <= laddr_r) &&
                (laddr_r + {{(`XLEN-4){1'b0}}, lsize_r} <=
                 eaddr_r + {{(`XLEN-4){1'b0}}, esize_r}) &&
                !entry_io_r;
            delta_r = laddr_r[2:0] - eaddr_r[2:0];
            issue1_sq_fwd_hit_r = contain_r;
            issue1_sq_fwd_raw_r =
                sq_snoop_data_w[idx_r*`XLEN +: `XLEN] >> {delta_r, 3'b000};
          end
        end
      end
    end
    if (poison_r || mem_translate_active_i)
      issue1_sq_fwd_hit_r = 1'b0;
  end

  // FP load 不吃前递: 前递走 ex0 单拍完成路(整数 wb), 无 FP PRF 写/FP 唤醒
  // 通道 → FP 目的悬死。FP load 命中重叠时按序等 SQ drain(慢但正确)。
  wire issue0_sq_fwd_w =
      !ENABLE_DUAL_MEM && sq_mode_w &&
      issue0_is_load_w && !issue0_is_amo_w &&
      !mem_issue_res_fp_pdest_q &&
      issue0_sq_fwd_hit_r;
  wire issue1_sq_fwd_w =
      !ENABLE_DUAL_MEM && sq_mode_w &&
      issue1_is_load_w && !issue1_is_amo_w &&
      !mem_issue1_res_fp_pdest_q &&
      issue1_sq_fwd_hit_r;

  // 前递数据抽取: 已右移的原始数据作 rdata, 按 load size/unsigned 扩展。
  wire [`XLEN-1:0] issue0_sq_fwd_data_w;
  wire [`XLEN-1:0] issue1_sq_fwd_data_w;
  wire [`XLEN-1:0] fwd0_extract_addr_unused_w;
  wire [`XLEN-1:0] fwd0_extract_wdata_unused_w;
  wire [`XLEN-1:0] fwd1_extract_addr_unused_w;
  wire [`XLEN-1:0] fwd1_extract_wdata_unused_w;
  LSUDataPath u_issue0_fwd_extract (
    .eff_addr_i(issue0_mem_addr_w),
    .store_data_i({`XLEN{1'b0}}),
    .byte_shift_i({`XLEN_BIT_SHIFT{1'b0}}),
    .load_size_i(mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .load_unsigned_i(mem_issue_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i(issue0_sq_fwd_raw_r),
    .mem_addr_o(fwd0_extract_addr_unused_w),
    .mem_wdata_o(fwd0_extract_wdata_unused_w),
    .load_data_o(issue0_sq_fwd_data_w)
  );
  LSUDataPath u_issue1_fwd_extract (
    .eff_addr_i(issue1_mem_addr_w),
    .store_data_i({`XLEN{1'b0}}),
    .byte_shift_i({`XLEN_BIT_SHIFT{1'b0}}),
    .load_size_i(
        mem_issue1_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB]),
    .load_unsigned_i(mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT]),
    .mem_rdata_i(issue1_sq_fwd_raw_r),
    .mem_addr_o(fwd1_extract_addr_unused_w),
    .mem_wdata_o(fwd1_extract_wdata_unused_w),
    .load_data_o(issue1_sq_fwd_data_w)
  );
  // sq_block 不受 rob_head_valid gate: dispatch-bypass 发射的 load 在发射拍自身
  // ROB 记账尚不可见(count=0/hv=0), 旧语义"ROB 空=无在飞 store"被 SQ 打破——
  // SQ 中 request/B/commit 三事件之间的 owner 仍常驻；accepted owner 的拦截判定
  // 不依赖 head 有效性，其余 entry 继续用 ROB age。
  // MIQ 在飞 PROBE = store class/address 尚未由翻译端确认的窗口；更老者
  // 对所有 younger load 保守 blind，禁止在 VA 上猜 PMA class。
  reg issue0_miq_probe_block_r;
  reg issue1_miq_probe_block_r;
  integer mpb;
  always @(*) begin : miq_probe_block_blk
    reg older0;
    reg older1;
    issue0_miq_probe_block_r = 1'b0;
    issue1_miq_probe_block_r = 1'b0;
    for (mpb = 0; mpb < MIQ_ENTRY_N; mpb = mpb + 1) begin
      older0 = 1'b0;
      older1 = 1'b0;
      if (miq_entry_valid_unused_w[mpb] &&
          (miq_entry_kind_unused_w[mpb*2 +: 2] == MIQ_KIND_PROBE)) begin
        older0 = rob_idx_older_than(
            miq_entry_rob_unused_w[mpb*ROB_INDEX_W +: ROB_INDEX_W],
            mem_issue_res_rob_idx_q, rob_head_idx_w);
        older1 = rob_idx_older_than(
            miq_entry_rob_unused_w[mpb*ROB_INDEX_W +: ROB_INDEX_W],
            mem_issue1_res_rob_idx_q, rob_head_idx_w);
        if (older0) issue0_miq_probe_block_r = 1'b1;
        if (older1) issue1_miq_probe_block_r = 1'b1;
      end
      older0 = 1'b0;
      older1 = 1'b0;
      if (ENABLE_DUAL_MEM && miq1_entry_valid_unused_w[mpb] &&
          (miq1_entry_kind_unused_w[mpb*2 +: 2] == MIQ_KIND_PROBE)) begin
        older0 = rob_idx_older_than(
            miq1_entry_rob_unused_w[mpb*ROB_INDEX_W +: ROB_INDEX_W],
            mem_issue_res_rob_idx_q, rob_head_idx_w);
        older1 = rob_idx_older_than(
            miq1_entry_rob_unused_w[mpb*ROB_INDEX_W +: ROB_INDEX_W],
            mem_issue1_res_rob_idx_q, rob_head_idx_w);
        if (older0) issue0_miq_probe_block_r = 1'b1;
        if (older1) issue1_miq_probe_block_r = 1'b1;
      end
    end
  end

  wire issue0_load_waits_for_inflight_store_w =
      !ENABLE_DUAL_MEM && issue0_is_load_w && !issue0_is_amo_w &&
      ((rob_head_valid_w &&
        ((mem_pending_store_order_block_w &&
          rob_idx_older_than(mem_rob_idx_q, mem_issue_res_rob_idx_q,
                             rob_head_idx_w) &&
          mem_pending_blind_w) ||
         (mem_buffer_store_order_block_w &&
          rob_idx_older_than(mem_buffer_rob_idx_q, mem_issue_res_rob_idx_q,
                             rob_head_idx_w) &&
          mem_buffer_blind_w))) ||
       (rob_head_valid_w && issue0_miq_probe_block_r) ||
       (issue0_sq_block_r && !issue0_sq_fwd_w));
  wire issue1_load_waits_for_inflight_store_w =
      !ENABLE_DUAL_MEM && issue1_is_load_w && !issue1_is_amo_w &&
      ((rob_head_valid_w &&
        ((mem_pending_store_order_block_w &&
          rob_idx_older_than(mem_rob_idx_q, mem_issue1_res_rob_idx_q,
                             rob_head_idx_w) &&
          mem_pending_blind_w) ||
         (mem_buffer_store_order_block_w &&
          rob_idx_older_than(mem_buffer_rob_idx_q,
                             mem_issue1_res_rob_idx_q,
                             rob_head_idx_w) &&
          mem_buffer_blind_w))) ||
       (rob_head_valid_w && issue1_miq_probe_block_r) ||
       (issue1_sq_block_r && !issue1_sq_fwd_w));
  // 【LSQ·SQ 切换】plain store 不再等 ROB 队头(probe 无副作用可投机发射);
  // AMO/SC(真读改写)仍队头，且要求 SQ 无 accepted physical-write owner；
  // younger speculative probe/fill 不应把 ROB-head AMO 全局串行化。
  wire amo_sq_quiet_w =
      !sq_mode_w || (sq_no_active_write_w && !drain_inflight_q);
  // Plain loads all enter the normal MIQ path.  Only the bridge owns the
  // post-translation IO decision and holds an IO request until this exact MIQ
  // owner reaches ROB head (or cancels it when killed).
  wire issue0_mem_order_ready_w =
      !issue0_is_mem_w ||
      (issue0_is_load_w && !issue0_is_amo_w &&
       !issue0_load_waits_for_inflight_store_w) ||
      (sq_mode_w && issue0_is_plain_store_w) ||
      (rob_head_valid_w && (mem_issue_res_rob_idx_q == rob_head_idx_w) &&
       !(issue0_is_load_w && !issue0_is_amo_w && issue0_sq_block_r));
  wire issue1_mem_order_ready_w =
      !issue1_is_mem_w ||
      (issue1_is_load_w && !issue1_is_amo_w &&
       !issue1_load_waits_for_inflight_store_w) ||
      (sq_mode_w && issue1_is_plain_store_w) ||
      (rob_head_valid_w &&
       (mem_issue1_res_rob_idx_q == rob_head_idx_w) &&
       !(issue1_is_load_w && !issue1_is_amo_w && issue1_sq_block_r));
  // Request-slot selection is mechanically shared with the request mux:
  // LEGACY atomics require the singleton slot; ordinary loads/stores use MIQ.
  wire issue0_mem_issue_eligible_w =
      issue0_is_mem_w &&
      !mem_issue_block_w &&
      issue0_mem_order_ready_w &&
      (!(issue0_is_load_w && !issue0_is_amo_w) || lq_issue0_open_w) &&
      (!issue0_is_amo_w || amo_sq_quiet_w);
  wire issue0_dual_transport_candidate_w = ENABLE_DUAL_MEM &&
      mem_issue_res_valid_q && issue0_mem_issue_eligible_w &&
      !issue0_mem_exception_w && !issue0_sq_fwd_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w;

  // F3 used active/station LOAD residency as an admission fence because only
  // one retry holder existed.  F4 gives an exact current/next-head handoff:
  // active and station capacity are therefore governed by their real request
  // READY, while a resident retry owner remains the bank-local conservative
  // fence.  If a queued next owner also replays, its current query simply
  // waits until the retry holder drains; no second retry owner is created.
  wire mem_bridge_active_load_w = mem_owner_query_valid_i &&
      mem_owner_live_mask_w[mem_owner_query_token_i] &&
      (mem_owner_kind_table_w[mem_owner_query_token_i*2 +: 2] ==
       MEM_OWNER_LOAD);
  wire mem_bridge_station_load_w = mem_station_query_valid_i &&
      mem_owner_live_mask_w[mem_station_query_token_i] &&
      (mem_owner_kind_table_w[mem_station_query_token_i*2 +: 2] ==
       MEM_OWNER_LOAD);
  wire mem1_bridge_active_load_w = ENABLE_DUAL_MEM &&
      mem1_owner_query_valid_i &&
      mem_owner_live_mask_w[mem1_owner_query_token_i] &&
      (mem_owner_kind_table_w[mem1_owner_query_token_i*2 +: 2] ==
       MEM_OWNER_LOAD);
  wire mem1_bridge_station_load_w = ENABLE_DUAL_MEM &&
      mem1_station_query_valid_i &&
      mem_owner_live_mask_w[mem1_station_query_token_i] &&
      (mem_owner_kind_table_w[mem1_station_query_token_i*2 +: 2] ==
       MEM_OWNER_LOAD);
  wire mem_bank0_load_admission_block_w = mem_retry0_valid_q;
  wire mem_bank1_load_admission_block_w = mem_retry1_valid_q;
  wire issue1_dual_transport_candidate_w = ENABLE_DUAL_MEM &&
      mem_issue1_res_valid_q && issue1_is_mem_w && !issue1_is_amo_w &&
      !mem_issue_block_w && issue1_mem_order_ready_w &&
      (!issue1_is_load_w || lq_issue1_open_w) &&
      !issue1_mem_exception_w && !issue1_sq_fwd_w &&
      !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w;
  wire issue0_dual_singleton_candidate_w =
      issue0_dual_transport_candidate_w && issue0_is_amo_w &&
      mem_amo_slot_open_w;
  wire issue0_dual_ordinary_candidate_w =
      issue0_dual_transport_candidate_w && !issue0_is_amo_w &&
      !issue0_dual_singleton_candidate_w;
  wire issue1_dual_ordinary_candidate_w =
      issue1_dual_transport_candidate_w &&
      !issue0_dual_singleton_candidate_w;
  wire issue0_dual_bank1_w = issue0_mem_addr_w[3];
  wire issue1_dual_bank1_w = issue1_mem_addr_w[3];
  wire issue0_dual_load_admission_block_w =
      issue0_is_load_w && !issue0_is_amo_w &&
      (issue0_dual_bank1_w ? mem_bank1_load_admission_block_w :
                            mem_bank0_load_admission_block_w);
  wire issue1_dual_load_admission_block_w =
      issue1_is_load_w && !issue1_is_amo_w &&
      (issue1_dual_bank1_w ? mem_bank1_load_admission_block_w :
                            mem_bank0_load_admission_block_w);
  // VALID must be backed by an actual bank-local MIQ slot.  In particular,
  // the LEGACY AMO singleton closes both slots; presenting an ordinary VALID
  // while can_fire is false would let the external bridge consume a request
  // whose metadata cannot be pushed.
  wire issue0_dual_bank_slot_open_w = issue0_dual_bank1_w ?
      miq1_slot_open_w : miq_slot_open_w;
  wire issue1_dual_bank_slot_open_w = issue1_dual_bank1_w ?
      miq1_slot_open_w : miq_slot_open_w;
  wire issue0_dual_ordinary_admitted_w =
      issue0_dual_ordinary_candidate_w &&
      issue0_dual_bank_slot_open_w &&
      !issue0_dual_load_admission_block_w;
  wire issue1_dual_ordinary_admitted_w =
      issue1_dual_ordinary_candidate_w &&
      issue1_dual_bank_slot_open_w &&
      !issue1_dual_load_admission_block_w;
  wire dual_ordinary_same_bank_w = issue0_dual_ordinary_admitted_w &&
      issue1_dual_ordinary_admitted_w &&
      (issue0_dual_bank1_w == issue1_dual_bank1_w);
  wire issue0_dual_older_or_tie_w = !rob_idx_older_than(
      mem_issue1_res_rob_idx_q, mem_issue_res_rob_idx_q, rob_head_idx_w);
  wire issue0_dual_base_selected_w = issue0_dual_ordinary_admitted_w &&
      (!dual_ordinary_same_bank_w || issue0_dual_older_or_tie_w);
  wire issue1_dual_base_selected_w = issue1_dual_ordinary_admitted_w &&
      (!dual_ordinary_same_bank_w || !issue0_dual_older_or_tie_w);

  wire mem_retry0_tracker_exact_w = mem_retry0_valid_q &&
      mem_owner_live_mask_w[mem_retry0_owner_token_q] &&
      (mem_owner_kind_table_w[mem_retry0_owner_token_q*2 +: 2] ==
       mem_retry0_owner_kind_q) &&
      (mem_owner_epoch_table_w[mem_retry0_owner_token_q*2 +: 2] ==
       mem_retry0_mmu_epoch_q) &&
      (mem_owner_producer_id_table_w[
           mem_retry0_owner_token_q*PRODUCER_ID_W +: PRODUCER_ID_W] ==
       mem_retry0_producer_id_q);
  wire mem_retry1_tracker_exact_w = ENABLE_DUAL_MEM &&
      mem_retry1_valid_q &&
      mem_owner_live_mask_w[mem_retry1_owner_token_q] &&
      (mem_owner_kind_table_w[mem_retry1_owner_token_q*2 +: 2] ==
       mem_retry1_owner_kind_q) &&
      (mem_owner_epoch_table_w[mem_retry1_owner_token_q*2 +: 2] ==
       mem_retry1_mmu_epoch_q) &&
      (mem_owner_producer_id_table_w[
           mem_retry1_owner_token_q*PRODUCER_ID_W +: PRODUCER_ID_W] ==
       mem_retry1_producer_id_q);
  wire mem_retry0_candidate_w = ENABLE_DUAL_MEM &&
      mem_retry0_valid_q && mem_retry0_tracker_exact_w &&
      !mem_retry0_cancel_w && !mem_retry0_addr_q[3];
  wire mem_retry1_candidate_w = ENABLE_DUAL_MEM &&
      mem_retry1_valid_q && mem_retry1_tracker_exact_w &&
      !mem_retry1_cancel_w && mem_retry1_addr_q[3];
  wire mem_bank0_store0_w = issue0_dual_base_selected_w &&
      issue0_is_plain_store_w && !issue0_dual_bank1_w;
  wire mem_bank0_store1_w = issue1_dual_base_selected_w &&
      issue1_is_plain_store_w && !issue1_dual_bank1_w;
  wire mem_bank1_store0_w = issue0_dual_base_selected_w &&
      issue0_is_plain_store_w && issue0_dual_bank1_w;
  wire mem_bank1_store1_w = issue1_dual_base_selected_w &&
      issue1_is_plain_store_w && issue1_dual_bank1_w;
  wire mem_bank0_store_candidate_w = mem_bank0_store0_w ||
                                     mem_bank0_store1_w;
  wire mem_bank1_store_candidate_w = mem_bank1_store0_w ||
                                     mem_bank1_store1_w;
  wire [ROB_INDEX_W-1:0] mem_bank0_store_rob_w = mem_bank0_store0_w ?
      mem_issue_res_rob_idx_q : mem_issue1_res_rob_idx_q;
  wire [ROB_INDEX_W-1:0] mem_bank1_store_rob_w = mem_bank1_store0_w ?
      mem_issue_res_rob_idx_q : mem_issue1_res_rob_idx_q;
  wire mem_bank0_store_older_than_retry_w =
      mem_bank0_store_candidate_w && mem_retry0_candidate_w &&
      rob_idx_older_than(mem_bank0_store_rob_w,
                         mem_retry0_rob_idx_q, rob_head_idx_w);
  wire mem_bank1_store_older_than_retry_w =
      mem_bank1_store_candidate_w && mem_retry1_candidate_w &&
      rob_idx_older_than(mem_bank1_store_rob_w,
                         mem_retry1_rob_idx_q, rob_head_idx_w);
  wire mem_retry0_selected_w = mem_retry0_candidate_w &&
      !mem_bank0_store_older_than_retry_w;
  wire mem_retry1_selected_w = mem_retry1_candidate_w &&
      !mem_bank1_store_older_than_retry_w;
  wire issue0_dual_selected_w = issue0_dual_base_selected_w &&
      !((!issue0_dual_bank1_w && mem_retry0_selected_w) ||
        (issue0_dual_bank1_w && mem_retry1_selected_w));
  wire issue1_dual_selected_w = issue1_dual_base_selected_w &&
      !((!issue1_dual_bank1_w && mem_retry0_selected_w) ||
        (issue1_dual_bank1_w && mem_retry1_selected_w));
  wire issue0_dual_bank_ready_w = issue0_dual_bank1_w ?
      (issue0_dual_bank_slot_open_w && mem1_req_ready_i) :
      (issue0_dual_bank_slot_open_w && mem_req_ready_i);
  wire issue1_dual_bank_ready_w = issue1_dual_bank1_w ?
      (issue1_dual_bank_slot_open_w && mem1_req_ready_i) :
      (issue1_dual_bank_slot_open_w && mem_req_ready_i);
  wire issue0_mem_can_fire_w =
      ENABLE_DUAL_MEM ?
      (issue0_mem_issue_eligible_w &&
       (issue0_mem_exception_w || issue0_sq_fwd_w ||
        (issue0_dual_singleton_candidate_w && mem_req_ready_i) ||
        (issue0_dual_selected_w && issue0_dual_bank_ready_w))) :
      (issue0_mem_issue_eligible_w &&
       (issue0_mem_exception_w ||
        issue0_sq_fwd_w ||
        (!mem_buffer_valid_q &&
         (issue0_mem_needs_excl_w ? mem_amo_slot_open_w
                                  : mem_request_slot_open_w) &&
         mem_req_ready_i) ||
        (!issue0_mem_needs_excl_w && mem_pending_q && !mem_rsp_fire_w &&
         !mem_buffer_valid_q)));
  // MEM-ISSUE-G1: lane0 只有“本地异常且本拍本身可发射”才把主请求 owner 交给
  // lane1。若异常访存仍被 ROB/order/SQ 条件挡住，cross-lane gate 会保留 lane1，
  // request-valid 也必须同步为 0，禁止 IQ 未 pop 却先建立 bridge/MIQ 幽灵事务。
  // 该 eligible 事实不依赖 mem_req_ready，保持 valid 不反向依赖 ready。
  wire issue1_mem_port_available_w =
      !issue0_is_mem_w ||
      (issue0_mem_exception_w && issue0_mem_issue_eligible_w);
  wire issue1_mem_can_fire_w =
      ENABLE_DUAL_MEM ?
      (issue1_is_mem_w && !mem_issue_block_w &&
       issue1_mem_order_ready_w &&
       (issue1_mem_exception_w || issue1_sq_fwd_w ||
        (issue1_dual_selected_w && issue1_dual_bank_ready_w))) :
      (issue1_is_mem_w &&
       !mem_issue_block_w &&
       issue1_mem_order_ready_w &&
       (!issue1_is_load_w || lq_issue1_open_w) &&
       (!issue1_is_amo_w || amo_sq_quiet_w) &&
       (issue1_mem_exception_w ||
        issue1_sq_fwd_w ||
        (issue1_mem_port_available_w &&
         !mem_buffer_valid_q &&
         (issue1_mem_needs_excl_w ? mem_amo_slot_open_w
                                  : mem_request_slot_open_w) &&
         mem_req_ready_i)));

  // LR/SC 修复:reservation 由前序 LR 的内存响应(晚于 LR issue 数拍)才置位，而 SC 的
  // sc_success 在 issue 当拍组合评估。失败的 SC(sc_success=0)因 issue*_is_mem_w=0 完全
  // 绕过「mem-order-ready=ROB 队头」约束→会先于前序 LR 完成就以失败短路退休，造成
  // 连续 lr;sc 重试活锁(rv64ua-p-lrsc 死循环)。修法:**只把当前评估为失败的 SC** 阻塞到
  // 它成为 ROB 队头且访存空闲——此时前序 LR 已退休并置好 reservation，sc_success 会重评为真，
  // SC 转为正常条件存(is_mem=1 走 mem_can_fire);若 reservation 确实无效则照常以失败退休。
  // 成功的 SC(sc_success=1，premature_w=0)路径不受影响，仍由既有 mem_order_ready 顺序约束。
  wire mem_idle_for_sc_w = !mem_pending_q && !mem_buffer_valid_q;
  wire issue0_sc_premature_w =
      issue0_is_sc_w && !issue0_sc_success_w &&
      !((rob_head_valid_w &&
         (mem_issue_res_rob_idx_q == rob_head_idx_w)) &&
        mem_idle_for_sc_w);
  wire issue1_sc_premature_w =
      issue1_is_sc_w && !issue1_sc_success_w &&
      !((rob_head_valid_w &&
         (mem_issue1_res_rob_idx_q == rob_head_idx_w)) &&
        mem_idle_for_sc_w);

  assign mem_rsp_waiting_for_wb_w =
      (mem_open_needs_wb_w && !wb_slot_free_w) ||
      (mem1_open_needs_wb_w &&
       (!wb_slot_free_w ||
        (mem_open_needs_wb_w && (wb_free_count_w < 2'd2))));
  wire issue0_is_muldiv_w =
      issue0_valid_w && issue0_ctrl_w[`CTRL_MULDIV_BIT];
  wire issue0_is_clmul_w =
      issue0_valid_w && issue0_ctrl_w[`CTRL_BITMANIP_BIT] &&
      is_clmul_inst(issue0_inst_w);
  wire muldiv_req_valid_w;
  wire clmul_req_valid_w;

  // T3N：控制流只能由 lane0 拥有。lane1 若选到 branch/JAL/JALR，先让更老的
  // lane0 离队，下一拍该控制流自然晋升 lane0；因此 resolve 不再需要 lane1 的
  // PRF/ALU/LSU-ready 组合锥。lane0 控制流的 ready 也只读全局 flush/quiesce，
  // 不复用与其类别互斥的 SC/memory/long-op resource predicates。
  wire issue0_is_jal_w  = issue0_valid_w && issue0_ctrl_w[`CTRL_JAL_BIT];
  wire issue0_is_jalr_w = issue0_valid_w && issue0_ctrl_w[`CTRL_JALR_BIT];
  wire issue0_is_ctrlflow_w =
      issue0_is_branch_w || issue0_is_jal_w || issue0_is_jalr_w;
  wire issue0_global_ready_w = !flush_i && !checkpoint_restore_hold_w &&
                               !issue_block_w;
  wire issue0_ctrlflow_ready_w = issue0_global_ready_w;
  wire issue0_muldiv_ready_w = issue0_global_ready_w && muldiv_req_ready_w;
  wire issue0_clmul_ready_w = issue0_global_ready_w && clmul_req_ready_w;
  // 旧 generic issue0_valid 在 branch resolve 拍统一遮蔽；拆 owner 后该门必须
  // 显式保留在 memory plane，避免 kill 判定沿前先产生 bridge/MIQ side effect。
  wire mem_issue_res_ready_w = issue0_global_ready_w &&
                               !branch_resolve_mispredict_w &&
                               !issue0_sc_premature_w &&
                               (!issue0_is_mem_w || issue0_mem_can_fire_w);
  assign mem_issue_res_dual_local_consume_w = ENABLE_DUAL_MEM &&
      mem_issue_res_valid_q && issue0_global_ready_w &&
      !branch_resolve_mispredict_w && !issue0_sc_premature_w &&
      (!issue0_is_mem_w ||
       (issue0_mem_issue_eligible_w &&
        (issue0_mem_exception_w || issue0_sq_fwd_w)));
  assign mem_issue_res_consume_fire_w =
      ENABLE_DUAL_MEM ?
      (mem_issue_res_dual_local_consume_w || issue0_mem_request_fire_w) :
      (mem_issue_res_valid_q && mem_issue_res_ready_w);
  // terminal1 drains only when terminal0 was already empty at the beginning
  // of the cycle.  This forbids same-edge bank0 consume -> bank1 look-through.
  wire mem_issue1_res_ready_w = issue0_global_ready_w &&
                                !branch_resolve_mispredict_w &&
                                !issue1_sc_premature_w &&
                                (!issue1_is_mem_w ||
                                 issue1_mem_can_fire_w);
  assign mem_issue1_res_dual_local_consume_w = ENABLE_DUAL_MEM &&
      mem_issue1_res_valid_q && issue0_global_ready_w &&
      !branch_resolve_mispredict_w && !issue1_sc_premature_w &&
      (!issue1_is_mem_w ||
       (issue1_mem_order_ready_w &&
        (issue1_mem_exception_w || issue1_sq_fwd_w)));
  assign mem_issue1_res_consume_fire_w =
      ENABLE_DUAL_MEM ?
      (mem_issue1_res_dual_local_consume_w || issue1_mem_request_fire_w) :
      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&
       mem_issue1_res_ready_w);
  // T3Q：ready 按互斥 owner 选择。MulDiv/CLMul 的许可不再穿过
  // memory/SQ/SC 谓词，避免 issue-fire→long-op request 的控制锥重新耦合。
  assign issue0_ready_w =
      issue0_is_ctrlflow_w ? issue0_ctrlflow_ready_w :
      issue0_is_muldiv_w ? issue0_muldiv_ready_w :
      issue0_is_clmul_w ? issue0_clmul_ready_w :
                          issue0_global_ready_w;
  // T3P：IQ 已保证 lane1 只有 fixed-latency simple-ALU，所以 ready 不得重新
  // 读取 ALU 地址、SQ containment、memory/SC 或 long-op resource predicate。
  // 保留 mem-rsp WB 饥饿门：响应等待 formal WB 槽时禁止 ex1 连续补满。
  assign issue1_ready_w = iq_issue1_plain_mem_class_w ?
      (iq_memory_pair_w ?
       ((iq_issue0_producer_current_w && issue1_producer_current_w) ?
        mem_issue_pair_capture_w : mem_issue_pair_stale1_drop_w) : 1'b0) :
      (!mem_issue1_res_valid_q && !flush_i &&
       !checkpoint_restore_hold_w &&
       !issue_block_w && !mem_rsp_waiting_for_wb_w);

  assign issue0_fire_w = issue0_valid_w && issue0_ready_w;
  assign issue1_fire_w = issue1_valid_w && issue1_ready_w;
  assign issue1_exec_fire_w = issue1_fire_w &&
                              !iq_issue1_plain_mem_class_w;

`ifdef OOO_ASSERT
  // Dynamic terminal numbering may reverse program age.  Check RAW in both
  // directions at the IQ packet boundary; terminal numbers are not age.
  always @(posedge clk) begin
    if (!rst && iq_issue0_valid_w && issue1_valid_w &&
        issue0_ctrl_w[`CTRL_RD_EN_BIT] && !issue0_fp_pdest_w &&
        (issue0_pdest_w != {PHY_REG_ADDR_W{1'b0}}) &&
        ((issue1_ctrl_w[`CTRL_RS1_EN_BIT] &&
          (issue1_src1_preg_w == issue0_pdest_w)) ||
         (issue1_ctrl_w[`CTRL_RS2_EN_BIT] &&
          (issue1_src2_preg_w == issue0_pdest_w)))) begin
      $error("[INT-ISSUE-CONTRACT RAW-I1] simultaneous issue lanes contain integer RAW: issue0 rob=%0d pdest=%0d issue1 rob=%0d src1=%0d src2=%0d @%0t",
             issue0_rob_idx_w, issue0_pdest_w, issue1_rob_idx_w,
             issue1_src1_preg_w, issue1_src2_preg_w, $time);
    end
    if (!rst && iq_issue_pair_swapped_w && iq_issue0_valid_w &&
        issue1_valid_w && issue1_ctrl_w[`CTRL_RD_EN_BIT] &&
        !issue1_fp_pdest_w &&
        (issue1_pdest_w != {PHY_REG_ADDR_W{1'b0}}) &&
        ((iq_issue0_ctrl_w[`CTRL_RS1_EN_BIT] &&
          (iq_issue0_src1_preg_w == issue1_pdest_w)) ||
         (iq_issue0_ctrl_w[`CTRL_RS2_EN_BIT] &&
          (iq_issue0_src2_preg_w == issue1_pdest_w)))) begin
      $error("[INT-ISSUE-CONTRACT RAW-DYNAMIC] swapped terminals contain older-issue1 to younger-issue0 RAW: issue1 rob=%0d pdest=%0d issue0 rob=%0d src1=%0d src2=%0d @%0t",
             issue1_rob_idx_w, issue1_pdest_w, iq_issue0_rob_idx_w,
             iq_issue0_src1_preg_w, iq_issue0_src2_preg_w, $time);
    end
    if (!rst && mem_req_device_release_o &&
        (!miq_head_valid_w || miq_head_effective_killed_w ||
         !rob_head_valid_w || (miq_head_rob_w != rob_head_idx_w))) begin
      $error("[INT-DEVICE-OWNER] release without live ROB-head MIQ owner @%0t", $time);
      $fatal;
    end
    if (!rst && mem_req_device_cancel_o &&
        (!miq_head_valid_w || !miq_head_effective_killed_w)) begin
      $error("[INT-DEVICE-OWNER] cancel without killed MIQ head @%0t", $time);
      $fatal;
    end
    if (!rst && mem_req_device_release_o && mem_req_device_cancel_o) begin
      $error("[INT-DEVICE-OWNER] release/cancel overlap @%0t", $time);
      $fatal;
    end
    if (!rst && issue1_exec_fire_w &&
        (issue1_ctrl_w[`CTRL_BRANCH_BIT] ||
         issue1_ctrl_w[`CTRL_JAL_BIT] ||
         issue1_ctrl_w[`CTRL_JALR_BIT])) begin
      $error("[INT-CTRL-LANE0-OWNER] lane1 fired control-flow rob=%0d pc=%h @%0t",
             issue1_rob_idx_w, issue1_pc_w, $time);
    end
    if (!rst && issue1_valid_w &&
        (!(is_alu_terminal_capable_ctrl(issue1_ctrl_w) ||
           is_plain_memory_terminal_capable_ctrl(issue1_ctrl_w)) ||
         issue1_fp_pdest_w || issue1_fp_st_en_w)) begin
      $error("[V8P-TERMINAL1-CAPABILITY] terminal1 selected unsupported uop rob=%0d pc=%h ctrl=%h @%0t",
             issue1_rob_idx_w, issue1_pc_w, issue1_ctrl_w, $time);
    end
    if (!rst && checkpoint_restore_hold_w &&
        (issue0_fire_w || issue1_fire_w || mem_issue_res_consume_fire_w ||
         mem_issue1_res_consume_fire_w)) begin
      $error("[INT-CHECKPOINT-RESTORE-NO-ISSUE] restore 拍仍有 issue fire={%b,%b} mem={%b,%b} @%0t",
             issue0_fire_w, issue1_fire_w, mem_issue_res_consume_fire_w,
             mem_issue1_res_consume_fire_w,
             $time);
    end
    if (!rst && issue0_valid_w &&
        ((issue0_is_ctrlflow_w && issue0_is_muldiv_w) ||
         (issue0_is_ctrlflow_w && issue0_is_clmul_w) ||
         (issue0_is_ctrlflow_w && issue0_mem_class_w) ||
         (issue0_is_muldiv_w && issue0_is_clmul_w) ||
         (issue0_is_muldiv_w && issue0_mem_class_w) ||
         (issue0_is_clmul_w && issue0_mem_class_w))) begin
      $error("[INT-ISSUE0-OWNER-ONEHOT0] overlapping issue owners rob=%0d pc=%h ctrlflow=%b muldiv=%b clmul=%b mem=%b ctrl=%h @%0t",
             issue0_rob_idx_w, issue0_pc_w, issue0_is_ctrlflow_w,
             issue0_is_muldiv_w, issue0_is_clmul_w,
             issue0_mem_class_w, issue0_ctrl_w, $time);
    end
    if (!rst && dispatch0_valid_i && dispatch1_valid_i &&
        !dispatch1_optional_i &&
        (dispatch0_fire_w != dispatch1_fire_w)) begin
      $error("[FP-DISPATCH-PAIR-ATOMIC] mandatory packet fired one lane only: fire0=%b fire1=%b fp_ok0=%b fp_ok1=%b @%0t",
             dispatch0_fire_w, dispatch1_fire_w,
             d0_fp_ok_w, d1_fp_ok_w, $time);
    end
    // T4S raw FP resource intent may legally observe payload while valid=0.
    // The frontend packet is therefore required to stay densely packed: a
    // younger lane1 uop can never be valid without the older lane0 uop.  This
    // is also the carrying premise for lane0->lane1 FP rename forwarding.
    if (!rst && dispatch1_valid_i && !dispatch0_valid_i) begin
      $error("[INT-DISPATCH-PACKET-PACKED] lane1 valid without lane0 @%0t",
             $time);
    end
    if (!rst && ((dispatch0_fire_w && !dispatch0_valid_i) ||
                 (dispatch1_fire_w && !dispatch1_valid_i))) begin
      $error("[INT-DISPATCH-FIRE-IMPLIES-VALID] fire={%b,%b} valid={%b,%b} @%0t",
             dispatch0_fire_w, dispatch1_fire_w,
             dispatch0_valid_i, dispatch1_valid_i, $time);
    end
    if (!rst && dispatch1_fire_w && !dispatch0_fire_w) begin
      $error("[FP-DISPATCH-PAIR-ATOMIC] lane1 fired without lane0 @%0t", $time);
    end
    // T3M 虽已删除 fast bypass，两个 formal WB lane 仍必须各自唯一拥有非零
    // 物理目的，禁止同拍双写同一 pdest。
    if (!rst && wb0_valid_w && wb1_valid_w &&
        (wb0_pdest_w != {PHY_REG_ADDR_W{1'b0}}) &&
        (wb0_pdest_w == wb1_pdest_w)) begin
      $error("[INT-WB-PDEST-UNIQUE] two formal WB lanes own pdest=%0d @%0t",
             wb0_pdest_w, $time);
    end
  end
`endif
  // T3Q canonical owner handshake：request valid 只表达“该 owner 有合法请求且
  // 全局允许发射”，绝不读取 resource ready；fire 在单元边界再与 ready 相与。
  // 物理 ALU-terminal capability 已结构禁止 long-op，删除不可达 payload mux 臂。
  wire issue0_muldiv_req_valid_w = issue0_is_muldiv_w &&
                                   issue0_global_ready_w;
  wire issue0_clmul_req_valid_w = issue0_is_clmul_w &&
                                  issue0_global_ready_w;
  wire issue0_muldiv_fire_w = issue0_muldiv_req_valid_w &&
                              muldiv_req_ready_w;
  wire issue0_clmul_fire_w = issue0_clmul_req_valid_w &&
                             clmul_req_ready_w;

`ifdef OOO_ASSERT
  always @(posedge clk) begin
    if (!rst && issue0_is_muldiv_w &&
        (issue0_fire_w != issue0_muldiv_fire_w)) begin
      $error("[INT-MULDIV-CANONICAL-FIRE] issue fire=%b request fire=%b rob=%0d @%0t",
             issue0_fire_w, issue0_muldiv_fire_w, issue0_rob_idx_w, $time);
    end
    if (!rst && issue0_is_clmul_w &&
        (issue0_fire_w != issue0_clmul_fire_w)) begin
      $error("[INT-CLMUL-CANONICAL-FIRE] issue fire=%b request fire=%b rob=%0d @%0t",
             issue0_fire_w, issue0_clmul_fire_w, issue0_rob_idx_w, $time);
    end
  end
`endif

  // ===== B2 片2：后端 branch+JAL+JALR 统一控制流解析（issue 级 per-uop mispredict）=====
  // 【F2】jal/jalr 恒判(不再挂 mode 条件): pred_npc 单源化后 jal 前后端同算 target
  // 恒免 redirect, ret/jalr-BTB/direct-jal 预测命中免——这些在旧强制项下每条都吃
  // redirect+ROB-walk。
  // JALR 目标 = (rs1+imm) & ~1；JAL 目标 = pc+imm(=branch_target)；BRANCH = taken?target:fallthrough。
  wire [`XLEN-1:0] issue0_jalr_target_w =
      (issue0_src1_data_w + issue0_imm_w) & {{(`XLEN-1){1'b1}}, 1'b0};
  wire [`XLEN-1:0] issue0_ctrlflow_next_pc_w =
      issue0_is_jalr_w ? issue0_jalr_target_w :
      issue0_is_jal_w  ? issue0_branch_target_w :
                         issue0_branch_next_pc_w;
  // 目标对齐异常（IALIGN=16）：JALR 清 bit0 故恒不失配；JAL 看 target[0]；BRANCH taken 看 target[0]。
  wire issue0_ctrlflow_misaligned_w =
      issue0_is_jalr_w ? 1'b0 :
      issue0_is_jal_w  ? issue0_branch_target_w[0] :
                         (issue0_branch_taken_w && issue0_branch_target_w[0]);
  wire issue0_ctrlflow_fire_w =
      issue0_valid_w && issue0_is_ctrlflow_w && issue0_ctrlflow_ready_w;
  // 误预测 = 架构后继 PC ≠ 前端 threaded 的预测后继 PC(pred_npc)，且非对齐异常(misaligned 走 trap)。
  // 【F2 分步落地·当前保留强制项】pred_npc 源已修好(OooFrontend.head_pred_succ_w = 统一 FIFO+bypass 的
  //   head_packet_next_pc_w，寄存/无环/取指时确定)——这是 F2 的必要前置。但仅此不足:去掉 mode_walk_w||
  //   启用真预测后,difftest 定位到 ROB-walk 恢复对**wrong-path squash 有缺陷**(预测-taken 的分支被真
  //   取错路后,mispredict redirect 未能干净 squash 错路指令→wrong-path 提交,如 rv64ui-p-add 的
  //   0x1ac bne)。此缺陷在强制项下从未被锻炼(强制项使前端从不真取预测错路)。故先锁定 pred_npc
  //   foundation、保留强制项,recovery 缺陷用现已可用的 difftest 单独死磕(见 known-issues #105)。
  // domain-A 拆总闸的正确性态: 强制 mispredict(每 ctrlflow redirect+ROB-walk kill)保证
  //   与前端任意取指决策一致(direct fire 的 BHT 重定向被 redirect 覆盖纠正)。F2 叠加
  //   (预测正确免 redirect)需 9946410ef 三件套完整移植(pred_npc BHT 项+DispatchMux 哨兵
  //   可靠性编码), 单独 pred 项会在取指-预测错配边界跑飞(CoreMark boot 1595 条→pc=0),
  //   纯哨兵版在 taken 紧循环退化(IPC 锁 0.53)。见 #105。
  // 【F2 整体落地 2026-07-03】强制项拆除, 真预测启用。pred_npc 已单源化(前端
  //   direct_fire_succ 与 next_fetch 共享同一 wire; dual 双发臂=d1.pc; 顺序臂=
  //   下包 pc0/64'h1 哨兵)——预测正确的控制流免 redirect+ROB-walk。历史 8 轮
  //   单点失败与三障碍的结构解详见 spec ooo-f2-per-packet-pred + known-issues #105。
  wire issue0_mispredict_w =
      (issue0_ctrlflow_next_pc_w != issue0_pred_npc_w) &&
      !issue0_ctrlflow_misaligned_w;

  // （声明已前置到 issue1 前递 wire 之前，iverilog 14 拒绝前向引用）
  assign muldiv_req_valid_w = issue0_muldiv_req_valid_w;
  wire [PHY_REG_ADDR_W-1:0] muldiv_req_pdest_w = issue0_pdest_w;
  wire [`INST_W-1:0] muldiv_req_inst_w = issue0_inst_w;
  wire [`XLEN-1:0] muldiv_req_src1_w = issue0_src1_data_w;
  wire [`XLEN-1:0] muldiv_req_src2_w = issue0_src2_data_w;
  wire muldiv_req_word_w = issue0_ctrl_w[`CTRL_WORD_OP_BIT];

  OooMulDivUnit #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_muldiv_unit (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_apply_w),
    .kill_valid_i(branch_resolve_mispredict_w),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),
    .rob_head_idx_i(rob_head_idx_w),
    .req_valid_i(muldiv_req_valid_w),
    .req_ready_o(muldiv_req_ready_w),
    .req_producer_id_i(iq_issue0_producer_id_w),
    .req_pdest_i(muldiv_req_pdest_w),
    .req_inst_i(muldiv_req_inst_w),
    .req_src1_i(muldiv_req_src1_w),
    .req_src2_i(muldiv_req_src2_w),
    .req_word_i(muldiv_req_word_w),
    .resp_valid_o(muldiv_resp_valid_w),
    .resp_ready_i(muldiv_resp_ready_w),
    .resp_rob_idx_o(muldiv_resp_rob_idx_w),
    .resp_producer_id_o(muldiv_resp_producer_id_w),
    .resp_pdest_o(muldiv_resp_pdest_w),
    .resp_data_o(muldiv_resp_data_w),
    .owner_valid_o(muldiv_owner_valid_w),
    .owner_producer_id_o(muldiv_owner_producer_id_w)
  );

  assign clmul_req_valid_w = issue0_clmul_req_valid_w;
  wire [PHY_REG_ADDR_W-1:0] clmul_req_pdest_w = issue0_pdest_w;
  wire [1:0] clmul_req_op_w = clmul_op_from_funct3(issue0_inst_w[14:12]);
  wire [`XLEN-1:0] clmul_req_src1_w = issue0_src1_data_w;
  wire [`XLEN-1:0] clmul_req_src2_w = issue0_src2_data_w;

  OooClmulUnit #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_clmul_unit (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_apply_w),
    .kill_valid_i(branch_resolve_mispredict_w),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),
    .rob_head_idx_i(rob_head_idx_w),
    .req_valid_i(clmul_req_valid_w),
    .req_ready_o(clmul_req_ready_w),
    .req_producer_id_i(iq_issue0_producer_id_w),
    .req_pdest_i(clmul_req_pdest_w),
    .req_op_i(clmul_req_op_w),
    .req_src1_i(clmul_req_src1_w),
    .req_src2_i(clmul_req_src2_w),
    .resp_valid_o(clmul_resp_valid_w),
    .resp_ready_i(clmul_resp_ready_w),
    .resp_rob_idx_o(clmul_resp_rob_idx_w),
    .resp_producer_id_o(clmul_resp_producer_id_w),
    .resp_pdest_o(clmul_resp_pdest_w),
    .resp_data_o(clmul_resp_data_w),
    .owner_valid_o(clmul_owner_valid_w),
    .owner_producer_id_o(clmul_owner_producer_id_w)
  );

  // Wave4b 删除：dispatch 拍分支快解析支撑网（src issue0/1 前递匹配、base/合成 ready、
  // src value、pc/fallthrough/imm/cmp_op、taken/target/next_pc/misaligned/rob_idx）——
  // 唯一 consumer dispatch_branch_fast_resolve_w 已随 candidate（恒 0）死硅摘除。

  // Request fires are assigned by the explicit one-hot grant mux below.  A
  // younger reservation may still hand off into the one-entry buffer while an
  // older SQ physical write wins the bridge; it must never report a false fire.
  wire issue0_mem_buffer_fire_w;
  wire mem_buffer_req_valid_w =
      !ENABLE_DUAL_MEM && mem_buffer_valid_q && mem_request_slot_open_w;
  wire mem_buffer_req_fire_w;
  // Selective ROB-walk kill for the post-reservation buffer owner.  A younger
  // killed item is discarded locally and is forbidden from entering the
  // request grant on the resolve cycle; this keeps cancellation independent
  // of bridge ready and avoids creating an unnecessary killed MIQ owner.
  wire mem_buffer_kill_w =
      branch_resolve_mispredict_w && mem_buffer_valid_q &&
      ((mem_buffer_rob_idx_q - rob_head_idx_w) >
       (branch_resolve_rob_idx_o - rob_head_idx_w));
  // issue0_mem_needs_excl_w 声明已前置(B2 S2, can_fire 同源分派需要)
  wire issue0_mem_req_valid_w =
      ENABLE_DUAL_MEM ?
      (issue0_dual_singleton_candidate_w || issue0_dual_selected_w) :
      (mem_issue_res_valid_q && issue0_is_mem_w && !issue0_mem_exception_w &&
       (!issue0_is_amo_w || amo_sq_quiet_w) && !issue0_sq_fwd_w &&
       (issue0_mem_needs_excl_w ? mem_amo_slot_open_w
                                : mem_request_slot_open_w) &&
       !mem_buffer_valid_q && !flush_i && !checkpoint_restore_hold_w &&
       !branch_resolve_mispredict_w &&
       !issue_block_w && !mem_issue_block_w && issue0_mem_order_ready_w);
  wire issue1_mem_buffer_fire_w;
  wire issue1_mem_req_valid_w =
      ENABLE_DUAL_MEM ? issue1_dual_selected_w :
      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&
       issue1_is_mem_w && !issue1_mem_exception_w &&
       !issue1_sq_fwd_w && mem_request_slot_open_w &&
       !mem_buffer_valid_q && !flush_i && !checkpoint_restore_hold_w &&
       !branch_resolve_mispredict_w && !issue_block_w &&
       !mem_issue_block_w && issue1_mem_order_ready_w);
  wire mem_retry0_req_valid_w = mem_retry0_selected_w &&
      miq_slot_open_w && !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w &&
      !mem_issue_block_w;
  wire mem_retry1_req_valid_w = mem_retry1_selected_w &&
      miq1_slot_open_w && !flush_i && !checkpoint_restore_hold_w &&
      !branch_resolve_mispredict_w && !issue_block_w &&
      !mem_issue_block_w;

`ifdef OOO_ASSERT
  wire [2:0] mem_issue_res_terminal_count_w =
      {2'b00, issue0_is_mem_w && issue0_mem_exception_w &&
                !issue0_sq_fwd_w} +
      {2'b00, issue0_is_mem_w && issue0_sq_fwd_w} +
      {2'b00, issue0_mem_request_fire_w} +
      {2'b00, issue0_mem_buffer_fire_w} +
      {2'b00, issue0_is_sc_w && !issue0_sc_success_w};
  wire [2:0] mem_issue1_res_terminal_count_w =
      {2'b00, issue1_is_mem_w && issue1_mem_exception_w &&
                !issue1_sq_fwd_w} +
      {2'b00, issue1_is_mem_w && issue1_sq_fwd_w} +
      {2'b00, issue1_mem_request_fire_w} +
      {2'b00, issue1_mem_buffer_fire_w};
  reg mem_buffer_kill_drop_shadow_q;
  always @(posedge clk) begin
    if (rst) begin
      mem_buffer_kill_drop_shadow_q <= 1'b0;
    end else begin
      if (mem_buffer_kill_drop_shadow_q && mem_buffer_valid_q)
        $error("[T3V-MEM-BUFFER-KILL] younger non-fired buffer survived kill @%0t",
               $time);
      if (miq_full_w && miq_pop_w && mem_request_slot_open_w)
        $error("[T3V-MIQ-FULL-REFILL] full+pop exposed parent request credit @%0t",
               $time);
      if (reservation_valid_q &&
          (reservation_size_q != `MEM_SIZE_WORD) &&
          (reservation_size_q != `MEM_SIZE_DWORD))
        $error("[T3V-LRSC-RES-SIZE] invalid reservation size=%0d @%0t",
               reservation_size_q, $time);
      if ((iq_issue0_valid_w && iq_issue0_ready_w &&
           iq_issue0_mem_class_w) !=
          ((mem_issue_res_capture_w &&
            !mem_issue_pair_turnover_capture_w) ||
           mem_issue_res_stale_drop_w ||
           mem_issue_pair_stale0_drop_w))
        $error("[T3S-MEM-RES-IQ-OWNER] IQ pop was neither exact capture nor stale drop @%0t",
               $time);
      if ((issue1_valid_w && issue1_ready_w &&
           iq_issue1_plain_mem_class_w) !=
          ((mem_issue1_res_capture_w &&
            !mem_issue_pair_turnover_capture_w) ||
           mem_issue_pair_stale1_drop_w))
        $error("[V8P-MEM1-RES-IQ-OWNER] terminal1 IQ pop was neither exact capture nor stale drop @%0t",
               $time);
      if (mem_issue_res_capture_w && !iq_issue0_producer_current_w)
        $error("[V8G-MEM-RES-CURRENT] stale PID created a memory owner @%0t",
               $time);
      if (mem_issue_res_stale_drop_w && mem_issue_res_capture_w)
        $error("[V8G-MEM-RES-STALE-DROP] stale IQ entry both dropped and captured @%0t",
               $time);
      if (mem_issue_res_capture_w && iq_issue_pair_swapped_w &&
          !issue1_fire_w)
        $error("[R3P1-SWAP-CAPTURE-ATOMIC] younger memory captured without older ALU fire @%0t",
               $time);

      if (mem_issue_res_capture_w && issue0_mem_req_valid_w &&
          !mem_issue_res_consume_fire_w)
        $error("[T3S-MEM-RES-NO-EARLY-REQ] raw capture generated lane0 request @%0t",
               $time);
      if (mem_issue_res_capture_w && mem_issue_res_requires_head_w &&
          (!rob_head_valid_w ||
           (iq_issue0_rob_idx_w != rob_head_idx_w)))
        $error("[T3U-MEM-RES-HEAD-ADMIT] head-only memory captured away from ROB head: raw=%0d head=%0d valid=%0b @%0t",
               iq_issue0_rob_idx_w, rob_head_idx_w,
               rob_head_valid_w, $time);
      if (mem_issue_res_consume_fire_w &&
          (mem_issue_res_terminal_count_w != 3'd1))
        $error("[T3S-MEM-RES-TERMINAL] consume owner count=%0d rob=%0d @%0t",
               mem_issue_res_terminal_count_w, mem_issue_res_rob_idx_q, $time);
      if (mem_issue1_res_consume_fire_w &&
          (mem_issue1_res_terminal_count_w != 3'd1))
        $error("[V8P-MEM1-RES-TERMINAL] consume owner count=%0d rob=%0d @%0t",
               mem_issue1_res_terminal_count_w,
               mem_issue1_res_rob_idx_q, $time);
      if (mem_issue_pair_capture_candidate_w &&
          ((mem_issue_res_capture_w != mem_issue1_res_capture_w) ||
           (iq_issue0_ready_w != issue1_ready_w) ||
           (iq_issue0_ready_w != mem_issue_res_capture_w)))
        $error("[V8P-MEM-PAIR-ATOMIC] pair capture/fire/ready diverged @%0t",
               $time);
      if (!ENABLE_DUAL_MEM && mem_issue1_res_valid_q &&
          mem_issue_res_valid_q &&
          mem_issue1_res_consume_fire_w)
        $error("[V8P-MEM1-NO-LOOKTHROUGH] terminal1 consumed behind edge-old terminal0 @%0t",
               $time);
      if (issue0_valid_w &&
          (issue0_ctrl_w[`CTRL_LOAD_BIT] || issue0_ctrl_w[`CTRL_STORE_BIT] ||
           issue0_ctrl_w[`CTRL_AMO_BIT]))
        $error("[T3S-MEM-RES-BYPASS] raw memory bypassed reservation @%0t",
               $time);
      if (mem_issue_res_valid_q && issue0_valid_w)
        $error("[T3V-MEM-RAW-OWNER-OVERLAP] memory and generic issue0 owners overlap @%0t",
               $time);
      if (mem_issue_res_consume_fire_w && issue0_fire_w)
        $error("[T3V-MEM-DATAPLANE-ISOLATION] memory consume overlapped generic issue0 fire @%0t",
               $time);
      if (checkpoint_restore_hold_w && issue0_mem_req_valid_w)
        $error("[T3S-MEM-RES-RESTORE-REQ] restore exposed lane0 request @%0t",
               $time);
      if (branch_resolve_mispredict_w &&
          (issue0_mem_req_valid_w || issue1_mem_req_valid_w ||
           mem_issue_res_consume_fire_w ||
           mem_issue1_res_consume_fire_w))
        $error("[T3V-MEM-RES-BRANCH-QUIET] resolve exposed memory request/consume @%0t",
               $time);
      if (mem_buffer_kill_w && mem_buffer_req_fire_w)
        $error("[V8G-MEM-BUFFER-KILL-READY-CUT] killed buffer entered request grant @%0t",
               $time);
      mem_buffer_kill_drop_shadow_q <= mem_buffer_kill_w;
    end
  end
`endif
  wire issue0_mem_req_write_w =
      issue0_is_store_w && (!issue0_is_amo_w || issue0_is_sc_w);
  wire issue1_mem_req_write_w = issue1_is_store_w;
  wire sq_drain_tracker_exact_w =
      mem_owner_live_mask_w[sq_drain_owner_token_w] &&
      (mem_owner_kind_table_w[sq_drain_owner_token_w*2 +: 2] ==
       sq_drain_owner_kind_w) &&
      (mem_owner_epoch_table_w[sq_drain_owner_token_w*2 +: 2] ==
       sq_drain_mmu_epoch_w);
  wire [PRODUCER_ID_W-1:0] sq_drain_tracker_producer_id_w =
      mem_owner_producer_id_table_w[
          sq_drain_owner_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];
  wire sq_drain_launch_authorized_w = sq_drain_tracker_exact_w &&
      (sq_drain_tracker_producer_id_w == sq_drain_producer_id_w) &&
      (sq_drain_producer_id_w == rob_head_producer_id_w) &&
      rob_head_launch_open_w;
  wire mem_amo_tracker_exact_w =
      mem_owner_live_mask_w[mem_owner_token_q] &&
      (mem_owner_kind_table_w[mem_owner_token_q*2 +: 2] ==
       mem_owner_kind_q) &&
      (mem_owner_epoch_table_w[mem_owner_token_q*2 +: 2] ==
       mem_mmu_epoch_q);
  wire [PRODUCER_ID_W-1:0] mem_amo_tracker_producer_id_w =
      mem_owner_producer_id_table_w[
          mem_owner_token_q*PRODUCER_ID_W +: PRODUCER_ID_W];
  wire mem_amo_launch_authorized_w = mem_amo_tracker_exact_w &&
      (mem_amo_tracker_producer_id_w == rob_head_producer_id_w) &&
      (mem_amo_tracker_producer_id_w ==
       mem_producer_id_q) &&
      rob_head_launch_open_w;
  wire mem_amo_write_req_valid_w =
      mem_pending_q && mem_amo_q && mem_amo_write_phase_q &&
      !mem_amo_write_sent_q && mem_amo_launch_authorized_w &&
      !flush_i && !checkpoint_restore_hold_w;

  // T4N: the SQ physical-head/ROB-head request has priority over every younger
  // buffer/issue source.  Source eligibility and grant/fire are deliberately
  // separate so a losing source cannot consume bridge ready.
  wire sq_drain_req_valid_w =
      sq_mode_w && sq_drain_valid_w && !drain_inflight_q &&
      sq_drain_launch_authorized_w &&
      // restore/flush 会清 MIQ；同拍不得让 SQ 置 request_sent 却丢掉 push owner。
      !flush_i && !checkpoint_restore_hold_w && mem_request_slot_open_w;
  wire mem_request_transport_open_w =
      !flush_i && !checkpoint_restore_hold_w;
  wire grant_sq_w =
      mem_request_transport_open_w && sq_drain_req_valid_w;
  wire grant_amo_write_w =
      mem_request_transport_open_w && !grant_sq_w &&
      mem_amo_write_req_valid_w;
  wire grant_buffer_w =
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !mem_buffer_kill_w &&
      mem_buffer_req_valid_w;
  wire grant_retry0_w = ENABLE_DUAL_MEM &&
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !grant_buffer_w && mem_retry0_req_valid_w;
  wire grant_issue0_w =
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !grant_buffer_w && !grant_retry0_w &&
      issue0_mem_req_valid_w &&
      (!ENABLE_DUAL_MEM || issue0_dual_singleton_candidate_w ||
       !issue0_dual_bank1_w);
  wire grant_issue1_w =
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !grant_buffer_w && !grant_retry0_w &&
      !grant_issue0_w &&
      issue1_mem_req_valid_w &&
      (!ENABLE_DUAL_MEM || !issue1_dual_bank1_w);
  wire grant_retry1_w = ENABLE_DUAL_MEM &&
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !grant_buffer_w && mem_retry1_req_valid_w;
  wire grant_mem1_issue0_w = ENABLE_DUAL_MEM &&
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !grant_buffer_w && !grant_retry1_w &&
      issue0_dual_selected_w && issue0_dual_bank1_w;
  wire grant_mem1_issue1_w = ENABLE_DUAL_MEM &&
      mem_request_transport_open_w && !grant_sq_w &&
      !grant_amo_write_w && !grant_buffer_w && !grant_retry1_w &&
      issue1_dual_selected_w &&
      issue1_dual_bank1_w && !grant_mem1_issue0_w;

  wire sq_drain_req_fire_w = grant_sq_w && mem_req_ready_i;
  assign mem_buffer_req_fire_w = grant_buffer_w && mem_req_ready_i;
  assign mem_retry0_req_fire_w = grant_retry0_w && mem_req_ready_i;
  assign mem_retry1_req_fire_w = grant_retry1_w && mem1_req_ready_i;
  assign issue0_mem_request_fire_w =
      (grant_issue0_w && mem_req_ready_i) ||
      (grant_mem1_issue0_w && mem1_req_ready_i);
  assign issue0_mem_buffer_fire_w =
      !ENABLE_DUAL_MEM && mem_issue_res_consume_fire_w &&
      issue0_is_mem_w && !issue0_is_amo_w &&
      !issue0_mem_exception_w && !issue0_sq_fwd_w &&
      !issue0_mem_request_fire_w && !mem_buffer_valid_q;
  assign issue1_mem_request_fire_w =
      (grant_issue1_w && mem_req_ready_i) ||
      (grant_mem1_issue1_w && mem1_req_ready_i);
  assign issue1_mem_buffer_fire_w =
      !ENABLE_DUAL_MEM && mem_issue1_res_consume_fire_w && issue1_is_mem_w &&
      !issue1_mem_exception_w && !issue1_sq_fwd_w &&
      !issue1_mem_request_fire_w && !mem_buffer_valid_q;

  assign mem_req_valid_o = grant_sq_w || grant_amo_write_w ||
                           grant_buffer_w || grant_retry0_w || grant_issue0_w ||
                           grant_issue1_w;
  assign mem_req_write_o = grant_sq_w ? 1'b1 :
                           grant_amo_write_w ? 1'b1 :
                           grant_buffer_w ? mem_buffer_store_q :
                           grant_retry0_w ? 1'b0 :
                           grant_issue0_w ? issue0_mem_req_write_w :
                                            issue1_mem_req_write_w;
  assign mem_req_addr_o = grant_sq_w ? sq_drain_addr_w :
                          grant_amo_write_w ? mem_eff_addr_q :
                          grant_buffer_w ? mem_buffer_eff_addr_q :
                          grant_retry0_w ? mem_retry0_addr_q :
                          grant_issue0_w ? issue0_mem_addr_w :
                                           issue1_mem_addr_w;
  assign mem_req_wdata_o = grant_sq_w ? sq_drain_data_w :
                           grant_amo_write_w ? mem_amo_write_data_q :
                           grant_buffer_w ? mem_buffer_wdata_q :
                           grant_retry0_w ? mem_retry0_wdata_q :
                           grant_issue0_w ? issue0_mem_wdata_w :
                                            issue1_mem_wdata_w;
  assign mem_req_wstrb_o = grant_sq_w ? sq_drain_strb_w :
                           grant_amo_write_w ? mem_amo_write_wstrb_q :
                           grant_buffer_w ? mem_buffer_wstrb_q :
                           grant_retry0_w ? mem_retry0_wstrb_q :
                           grant_issue0_w ? issue0_mem_wstrb_w :
                                            issue1_mem_wstrb_w;
  // 事务属性: probe 只标 plain store 的探测请求；SQ physical request pretrans+nokill。
  assign mem_req_probe_o =
      grant_buffer_w ? (sq_mode_w && mem_buffer_store_q) :
      grant_issue0_w ? (sq_mode_w && issue0_is_plain_store_w) :
      grant_issue1_w ? (sq_mode_w && issue1_is_plain_store_w) :
      1'b0;
  assign mem_req_pretrans_o = grant_sq_w;
  assign mem_req_nokill_o = grant_sq_w;
  // Only a translated SQ drain may carry request provenance.  Every ordinary
  // VA request starts invalid/RSVD and is classified exactly once in bridge.
  assign mem_req_attr_valid_o = grant_sq_w && sq_drain_attr_valid_w;
  assign mem_req_class_o = mem_req_attr_valid_o ? sq_drain_class_w :
                                                   `OOO_MEM_CLASS_RSVD;
  assign mem_req_cacheable_o = mem_req_attr_valid_o &&
                               (mem_req_class_o == `OOO_MEM_CLASS_CACHED);
  assign mem_req_owner_kind_o = grant_sq_w ? sq_drain_owner_kind_w :
      grant_amo_write_w ? mem_owner_kind_q :
      grant_buffer_w ? mem_buffer_owner_kind_q :
      grant_retry0_w ? mem_retry0_owner_kind_q :
      grant_issue0_w ? mem_issue_res_owner_kind_q :
                       mem_issue1_res_owner_kind_q;
  assign mem_req_owner_token_o = grant_sq_w ? sq_drain_owner_token_w :
      grant_amo_write_w ? mem_owner_token_q :
      grant_buffer_w ? mem_buffer_owner_token_q :
      grant_retry0_w ? mem_retry0_owner_token_q :
      grant_issue0_w ? mem_issue_res_owner_token_q :
                       mem_issue1_res_owner_token_q;
  assign mem_req_mmu_epoch_o = grant_sq_w ? sq_drain_mmu_epoch_w :
      grant_amo_write_w ? mem_mmu_epoch_q :
      grant_buffer_w ? mem_buffer_mmu_epoch_q :
      grant_retry0_w ? mem_retry0_mmu_epoch_q :
      grant_issue0_w ? mem_issue_res_mmu_epoch_q :
                       mem_issue1_res_mmu_epoch_q;
  assign mem_req_fault_tval_o = grant_sq_w ? sq_drain_fault_tval_w :
      grant_amo_write_w ? mem_fault_tval_q :
      grant_buffer_w ? mem_buffer_fault_tval_q :
      grant_retry0_w ? mem_retry0_fault_tval_q :
      grant_issue0_w ? mem_issue_res_fault_tval_q :
                       mem_issue1_res_fault_tval_q;

  assign mem1_req_valid_o = ENABLE_DUAL_MEM &&
      (grant_retry1_w || grant_mem1_issue0_w || grant_mem1_issue1_w);
  assign mem1_req_write_o = grant_retry1_w ? 1'b0 :
      grant_mem1_issue0_w ? issue0_mem_req_write_w : issue1_mem_req_write_w;
  assign mem1_req_probe_o = grant_retry1_w ? 1'b0 :
      grant_mem1_issue0_w ?
      (sq_mode_w && issue0_is_plain_store_w) :
      (grant_mem1_issue1_w && sq_mode_w && issue1_is_plain_store_w);
  assign mem1_req_pretrans_o = 1'b0;
  assign mem1_req_nokill_o = 1'b0;
  assign mem1_req_attr_valid_o = 1'b0;
  assign mem1_req_class_o = `OOO_MEM_CLASS_RSVD;
  assign mem1_req_cacheable_o = 1'b0;
  assign mem1_req_owner_kind_o = grant_retry1_w ?
      mem_retry1_owner_kind_q : grant_mem1_issue0_w ?
      mem_issue_res_owner_kind_q : mem_issue1_res_owner_kind_q;
  assign mem1_req_owner_token_o = grant_retry1_w ?
      mem_retry1_owner_token_q : grant_mem1_issue0_w ?
      mem_issue_res_owner_token_q : mem_issue1_res_owner_token_q;
  assign mem1_req_mmu_epoch_o = grant_retry1_w ?
      mem_retry1_mmu_epoch_q : grant_mem1_issue0_w ?
      mem_issue_res_mmu_epoch_q : mem_issue1_res_mmu_epoch_q;
  assign mem1_req_fault_tval_o = grant_retry1_w ?
      mem_retry1_fault_tval_q : grant_mem1_issue0_w ?
      mem_issue_res_fault_tval_q : mem_issue1_res_fault_tval_q;
  assign mem1_req_addr_o = grant_retry1_w ? mem_retry1_addr_q :
      grant_mem1_issue0_w ? issue0_mem_addr_w : issue1_mem_addr_w;
  assign mem1_req_wdata_o = grant_retry1_w ? mem_retry1_wdata_q :
      grant_mem1_issue0_w ? issue0_mem_wdata_w : issue1_mem_wdata_w;
  assign mem1_req_wstrb_o = grant_retry1_w ? mem_retry1_wstrb_q :
      grant_mem1_issue0_w ? issue0_mem_wstrb_w : issue1_mem_wstrb_w;

  // ============ MIQ push(与桥 req fire 同拍, 优先级与 req mux 一致) ============
  // 【P5 刀 M】fire 语义重释=进桥侧 req 寄存站(翻译/dcache 发射推迟到桥内 advance
  // 拍); push 时点不变——寄存站占用即记账, mem_idle 等独占谓词自动计入(跨模块断言
  // KM-STG-MIQ 固化)。桥 ready 含 !flush_i ⟺ flush 拍无 fire ⟺ MIQ else-if flush
  // 分支不会漏记 push。
  wire mem_req_fire_any_w = mem_req_valid_o && mem_req_ready_i;
  wire mem1_req_fire_any_w = mem1_req_valid_o && mem1_req_ready_i;
  wire checkpoint_irrevocable_write_launch_w =
      mem_req_fire_any_w && mem_req_write_o && !mem_req_probe_o;
  wire [PRODUCER_ID_W-1:0] checkpoint_irrevocable_write_launch_pid_w =
      mem_owner_producer_id_table_w[
          mem_req_owner_token_o*PRODUCER_ID_W +: PRODUCER_ID_W];
  wire checkpoint_irrevocable_write_retire_w =
      commit0_valid_o && checkpoint_irrevocable_write_q &&
      (rob_commit0_producer_id_w == checkpoint_irrevocable_write_pid_q);

  always @(posedge clk) begin
    if (rst) begin
      checkpoint_irrevocable_write_q <= 1'b0;
      checkpoint_irrevocable_write_pid_q <= {PRODUCER_ID_W{1'b0}};
    end else begin
      if (checkpoint_irrevocable_write_retire_w) begin
        checkpoint_irrevocable_write_q <= 1'b0;
        checkpoint_irrevocable_write_pid_q <= {PRODUCER_ID_W{1'b0}};
      end
      if (checkpoint_irrevocable_write_launch_w) begin
        checkpoint_irrevocable_write_q <= 1'b1;
        checkpoint_irrevocable_write_pid_q <=
            checkpoint_irrevocable_write_launch_pid_w;
      end
    end
  end

  wire push_amo_write_w = grant_amo_write_w && mem_req_ready_i;
  wire push_buffer_w = mem_buffer_req_fire_w;
  wire push_retry0_w = mem_retry0_req_fire_w;
  wire push_retry1_w = mem_retry1_req_fire_w;
  wire push_issue0_w = grant_issue0_w && mem_req_ready_i;
  wire push_issue1_w = grant_issue1_w && mem_req_ready_i;
  wire push_mem1_issue0_w = grant_mem1_issue0_w && mem1_req_ready_i;
  wire push_mem1_issue1_w = grant_mem1_issue1_w && mem1_req_ready_i;
  wire push_drain_w = sq_drain_req_fire_w;

  assign miq_push_valid_w = mem_req_fire_any_w;
  // kind: AMO 写阶段/AMO 族发射=LEGACY; drain=DRAIN; plain store(probe)=PROBE;
  // plain load=LOAD。buffer 只存 plain。
  wire issue0_is_excl_kind_w = issue0_is_amo_w;
  wire issue1_is_excl_kind_w = issue1_is_amo_w;
  assign miq_push_kind_w =
      push_amo_write_w ? MIQ_KIND_LEGACY :
      push_buffer_w ? (mem_buffer_store_q ? MIQ_KIND_PROBE : MIQ_KIND_LOAD) :
      push_retry0_w ? MIQ_KIND_LOAD :
      push_issue0_w ? (issue0_is_excl_kind_w ? MIQ_KIND_LEGACY :
                       issue0_is_plain_store_w ? MIQ_KIND_PROBE :
                                                 MIQ_KIND_LOAD) :
      push_issue1_w ? (issue1_is_plain_store_w ? MIQ_KIND_PROBE :
                                                 MIQ_KIND_LOAD) :
                      MIQ_KIND_DRAIN;
  assign miq_push_owner_kind_w = mem_req_owner_kind_o;
  assign miq_push_owner_token_w = mem_req_owner_token_o;
  assign miq_push_mmu_epoch_w = mem_req_mmu_epoch_o;
  assign miq_push_fault_tval_w = mem_req_fault_tval_o;
  assign miq_push_rob_w =
      push_amo_write_w ? mem_rob_idx_q :
      push_buffer_w ? mem_buffer_rob_idx_q :
      push_retry0_w ? mem_retry0_rob_idx_q :
      push_issue0_w ? mem_issue_res_rob_idx_q :
      push_issue1_w ? mem_issue1_res_rob_idx_q :
      sq_drain_rob_w;
  assign miq_push_pdest_w =
      push_amo_write_w ? mem_pdest_q :
      push_buffer_w ? mem_buffer_pdest_q :
      push_retry0_w ? mem_retry0_pdest_q :
      push_issue0_w ? mem_issue_res_pdest_q :
      push_issue1_w ? mem_issue1_res_pdest_q :
      {PHY_REG_ADDR_W{1'b0}};
  assign miq_push_pdest_fp_w =
      push_amo_write_w ? mem_pdest_fp_q :
      push_buffer_w ? mem_buffer_pdest_fp_q :
      push_retry0_w ? mem_retry0_pdest_fp_q :
      push_issue0_w ? mem_issue_res_fp_pdest_q :
      push_issue1_w ? mem_issue1_res_fp_pdest_q :
      1'b0;
  assign miq_push_size_w =
      push_amo_write_w ? mem_size_q :
      push_buffer_w ? mem_buffer_size_q :
      push_retry0_w ? mem_retry0_size_q :
      push_issue0_w ?
          mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] :
      push_issue1_w ?
          mem_issue1_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] :
                      2'b00;
  assign miq_push_unsigned_w =
      push_amo_write_w ? mem_unsigned_q :
      push_buffer_w ? mem_buffer_unsigned_q :
      push_retry0_w ? mem_retry0_unsigned_q :
      push_issue0_w ? mem_issue_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT] :
      push_issue1_w ? mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT] :
      1'b0;
  assign miq_push_addr_w = mem_req_addr_o;
  assign miq_push_wdata_w = mem_req_wdata_o;
  assign miq_push_wstrb_w = mem_req_wstrb_o;

  assign miq1_push_valid_w = mem1_req_fire_any_w;
  assign miq1_push_kind_w = push_retry1_w ? MIQ_KIND_LOAD :
      push_mem1_issue0_w ?
      (issue0_is_plain_store_w ? MIQ_KIND_PROBE : MIQ_KIND_LOAD) :
      (issue1_is_plain_store_w ? MIQ_KIND_PROBE : MIQ_KIND_LOAD);
  assign miq1_push_owner_kind_w = mem1_req_owner_kind_o;
  assign miq1_push_owner_token_w = mem1_req_owner_token_o;
  assign miq1_push_mmu_epoch_w = mem1_req_mmu_epoch_o;
  assign miq1_push_fault_tval_w = mem1_req_fault_tval_o;
  assign miq1_push_rob_w = push_retry1_w ? mem_retry1_rob_idx_q :
      push_mem1_issue0_w ?
      mem_issue_res_rob_idx_q : mem_issue1_res_rob_idx_q;
  assign miq1_push_pdest_w = push_retry1_w ? mem_retry1_pdest_q :
      push_mem1_issue0_w ?
      mem_issue_res_pdest_q : mem_issue1_res_pdest_q;
  assign miq1_push_pdest_fp_w = push_retry1_w ? mem_retry1_pdest_fp_q :
      push_mem1_issue0_w ?
      mem_issue_res_fp_pdest_q : mem_issue1_res_fp_pdest_q;
  assign miq1_push_size_w = push_retry1_w ? mem_retry1_size_q :
      push_mem1_issue0_w ?
      mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] :
      mem_issue1_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
  assign miq1_push_unsigned_w = push_retry1_w ? mem_retry1_unsigned_q :
      push_mem1_issue0_w ?
      mem_issue_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT] :
      mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT];
  assign miq1_push_addr_w = mem1_req_addr_o;
  assign miq1_push_wdata_w = mem1_req_wdata_o;
  assign miq1_push_wstrb_w = mem1_req_wstrb_o;

  assign lq_launch0_valid_w = miq_push_valid_w &&
      (miq_push_kind_w == MIQ_KIND_LOAD);
  assign lq_launch0_producer_id_w = mem_owner_producer_id_table_w[
      miq_push_owner_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];
  assign lq_launch1_valid_w = ENABLE_DUAL_MEM && miq1_push_valid_w &&
      (miq1_push_kind_w == MIQ_KIND_LOAD);
  assign lq_launch1_producer_id_w = mem_owner_producer_id_table_w[
      miq1_push_owner_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];

  // 【级间边界治理 P1】原 always 内 ex0/ex1 赋值臂等价改写为组合 up_valid/up_payload
  // 生成——"功能模块退化为纯组合 + 写入下一级 PipeStageReg"的目标形态
  // (design/arch/pipeline-stage-boundary.md §4 P1; 实例与位段布局见声明处)。
  // 原"未命中臂写全 0 payload"语义不保留: PipeStageReg 在 up_valid=0 拍不锁存 payload
  // (留脏), 下游 wb0/wb1 mux 全部以 exN_wb_valid_w 为最高优先选择条件,
  // wb_free_count_w 只读 pre-auth physical occupancy；exact-open 只授权
  // actual WB/PRF/wakeup/forward/public completion，不回灌 transport ready。
  // T3V：generic ex0 只接 raw non-memory；reservation 的三个本地终结
  // (SQ forward / failed SC / precise misalign)直接从 Q 形成独立 completion。
  wire mem_issue_res_local_terminal_reason_w =
      !issue0_is_mem_w || issue0_mem_exception_w || issue0_sq_fwd_w;
  // Boolean-equivalent ready cut.  For a local terminal, issue0_mem_can_fire
  // reduces to issue eligibility because exception/SQ-forward is already true.
  // Spell that reduction here so a terminal candidate cannot feed bridge
  // request-ready back into response terminal credit.
  wire mem_issue_res_local_complete_w =
      ENABLE_DUAL_MEM ? mem_issue_res_dual_local_consume_w :
      (mem_issue_res_valid_q && issue0_global_ready_w &&
       !branch_resolve_mispredict_w && !issue0_sc_premature_w &&
       (!issue0_is_mem_w ||
        (issue0_mem_issue_eligible_w &&
         (issue0_mem_exception_w || issue0_sq_fwd_w))));
  wire mem_issue1_res_local_terminal_reason_w =
      !issue1_is_mem_w || issue1_mem_exception_w || issue1_sq_fwd_w;
  wire mem_issue1_res_local_complete_w =
      ENABLE_DUAL_MEM ? mem_issue1_res_dual_local_consume_w :
      (mem_issue1_res_valid_q && !mem_issue_res_valid_q &&
       issue0_global_ready_w && !branch_resolve_mispredict_w &&
       !issue1_sc_premature_w &&
       (!issue1_is_mem_w ||
        (issue1_mem_order_ready_w &&
         (!issue1_is_load_w || lq_issue1_open_w) &&
         (issue1_mem_exception_w || issue1_sq_fwd_w))));
`ifdef OOO_ASSERT
  always @(posedge clk) begin
    if (!rst &&
        (mem_issue_res_local_complete_w !=
         (mem_issue_res_consume_fire_w &&
          mem_issue_res_local_terminal_reason_w)))
      $error("[V8G-MEM-LOCAL-READY-CUT] factored local terminal diverged from consume semantics @%0t",
             $time);
    if (!rst &&
        (mem_issue1_res_local_complete_w !=
         (mem_issue1_res_consume_fire_w &&
          mem_issue1_res_local_terminal_reason_w)))
      $error("[V8P-MEM1-LOCAL-READY-CUT] factored terminal1 local completion diverged @%0t",
             $time);
  end
`endif
  assign ex0_up_valid_w =
      (issue0_fire_w && !issue0_is_muldiv_w && !issue0_is_clmul_w) ||
      mem_issue_res_local_complete_w;
  wire ex0_up_from_mem_w = mem_issue_res_local_complete_w;
  // 保持既有 failed-SC 语义：is_mem 已把 reservation miss 的 SC 分类为本地失败，
  // 即使其地址同时 misaligned，也不把该失败短路改写成 memory exception。
  wire ex0_up_exception_w = ex0_up_from_mem_w && issue0_is_mem_w &&
                            !issue0_sq_fwd_w && issue0_mem_exception_w;
  // 【LSQ·前递】load 命中 SQ 全覆盖 entry, 单拍完成(不访存)→ 直取前递数据。
  wire [`XLEN-1:0] ex0_up_result_w =
      ex0_up_from_mem_w ?
          (issue0_sq_fwd_w ? issue0_sq_fwd_data_w :
           (issue0_is_sc_w && !issue0_sc_success_w) ?
               {{(`XLEN-1){1'b0}}, 1'b1} : {`XLEN{1'b0}}) :
          issue0_wb_data_w;
  // AMO/SC 非对齐报 Store/AMO,但 LR 非对齐报 Load(NEMU 金标:funct5==LR→LOAD_MISALIGN)。
  wire [`TRAP_CAUSE_W-1:0] ex0_up_cause_w =
      ex0_up_exception_w ?
      (((issue0_is_load_w && !issue0_is_amo_w) || issue0_is_lr_w) ?
       `EXC_LOAD_ADDR_MISALIGN : `EXC_STORE_ADDR_MISALIGN) :
      {`TRAP_CAUSE_W{1'b0}};
  wire [`XLEN-1:0] ex0_up_tval_w =
      ex0_up_exception_w ? mem_issue_res_eff_addr_w : {`XLEN{1'b0}};
  wire [PRODUCER_ID_W-1:0] ex0_up_producer_id_w =
      ex0_up_from_mem_w ? mem_issue_res_producer_id_q :
                          iq_issue0_producer_id_w;
  assign ex0_up_payload_w =
      {ex0_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup0_valid_w && !ex0_up_from_mem_w,
       ex0_up_producer_id_w[ROB_INDEX_W-1:0],
       ex0_up_from_mem_w ? mem_issue_res_pdest_q : issue0_pdest_w,
       ex0_up_result_w,
       ex0_up_exception_w, ex0_up_cause_w, ex0_up_tval_w};
  assign ex1_up_valid_w = issue1_exec_fire_w ||
                          mem_issue1_res_local_complete_w;
  wire ex1_up_from_mem_w = mem_issue1_res_local_complete_w;
  wire ex1_up_exception_w = ex1_up_from_mem_w && issue1_is_mem_w &&
                            !issue1_sq_fwd_w && issue1_mem_exception_w;
  wire [`XLEN-1:0] ex1_up_result_w = ex1_up_from_mem_w ?
      (issue1_sq_fwd_w ? issue1_sq_fwd_data_w : {`XLEN{1'b0}}) :
      issue1_wb_data_w;
  wire [`TRAP_CAUSE_W-1:0] ex1_up_cause_w = ex1_up_exception_w ?
      (issue1_is_load_w ? `EXC_LOAD_ADDR_MISALIGN :
                          `EXC_STORE_ADDR_MISALIGN) :
      {`TRAP_CAUSE_W{1'b0}};
  wire [`XLEN-1:0] ex1_up_tval_w = ex1_up_exception_w ?
      mem_issue1_res_eff_addr_w : {`XLEN{1'b0}};
  wire [PRODUCER_ID_W-1:0] ex1_up_producer_id_w = ex1_up_from_mem_w ?
      mem_issue1_res_producer_id_q : issue1_producer_id_w;
  assign ex1_up_payload_w =
      {ex1_up_producer_id_w[PRODUCER_ID_W-1:ROB_INDEX_W],
       early_wakeup1_valid_w && !ex1_up_from_mem_w,
       ex1_up_producer_id_w[ROB_INDEX_W-1:0],
       ex1_up_from_mem_w ? mem_issue1_res_pdest_q : issue1_pdest_w,
       ex1_up_result_w,
       ex1_up_exception_w, ex1_up_cause_w, ex1_up_tval_w};

  always @(posedge clk) begin
    if (rst || flush_i || checkpoint_restore_apply_w) begin
      mem_pending_q <= 1'b0;
      mem_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem_producer_id_q <= {PRODUCER_ID_W{1'b0}};
      mem_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_pdest_fp_q <= 1'b0;
      mem_load_q <= 1'b0;
      mem_store_q <= 1'b0;
      mem_amo_q <= 1'b0;
      mem_amo_lr_q <= 1'b0;
      mem_amo_sc_q <= 1'b0;
      mem_amo_write_phase_q <= 1'b0;
      mem_amo_write_sent_q <= 1'b0;
      mem_eff_addr_q <= {`XLEN{1'b0}};
      mem_size_q <= 2'b00;
      mem_unsigned_q <= 1'b0;
      mem_amo_inst_q <= {`INST_W{1'b0}};
      mem_amo_src2_q <= {`XLEN{1'b0}};
      mem_amo_old_value_q <= {`XLEN{1'b0}};
      mem_amo_write_data_q <= {`XLEN{1'b0}};
      mem_amo_write_wstrb_q <= {`STRB_W{1'b0}};
      mem_owner_kind_q <= MEM_OWNER_RESERVED;
      mem_owner_token_q <= 5'b0;
      mem_mmu_epoch_q <= MEM_OWNER_EPOCH_BASE;
      mem_fault_tval_q <= {`XLEN{1'b0}};
      mem_probe_q <= 1'b0;
      mem_store_wdata_q <= {`XLEN{1'b0}};
      mem_store_wstrb_q <= {`STRB_W{1'b0}};
      mem_buffer_valid_q <= 1'b0;
      mem_buffer_rob_idx_q <= {ROB_INDEX_W{1'b0}};
      mem_buffer_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
      mem_buffer_pdest_fp_q <= 1'b0;
      mem_buffer_load_q <= 1'b0;
      mem_buffer_store_q <= 1'b0;
      mem_buffer_eff_addr_q <= {`XLEN{1'b0}};
      mem_buffer_size_q <= 2'b00;
      mem_buffer_unsigned_q <= 1'b0;
      mem_buffer_wdata_q <= {`XLEN{1'b0}};
      mem_buffer_wstrb_q <= {`STRB_W{1'b0}};
      mem_buffer_owner_kind_q <= MEM_OWNER_RESERVED;
      mem_buffer_owner_token_q <= 5'b0;
      mem_buffer_mmu_epoch_q <= MEM_OWNER_EPOCH_BASE;
      mem_buffer_fault_tval_q <= {`XLEN{1'b0}};
      reservation_valid_q <= 1'b0;
      reservation_addr_q <= {`XLEN{1'b0}};
      reservation_size_q <= 2'b00;
      // ex0/ex1 EX→WB 级间簇已提取为 PipeStageReg 实例(flush 臂由其 flush_i 端口等价承载)
    end else begin
      if (mem_amo_read_rsp_w) begin
        mem_amo_write_phase_q <= 1'b1;
        mem_amo_write_sent_q <= 1'b0;
        mem_amo_old_value_q <= mem_amo_old_value_w;
        mem_amo_write_data_q <= mem_amo_write_wdata_w;
        mem_amo_write_wstrb_q <= mem_amo_write_wstrb_w;
      end else if (mem_rsp_final_fire_w) begin
        if (!miq_head_effective_killed_w) begin
          if (mem_amo_lr_q && !mem_rsp_error_i) begin
            reservation_valid_q <= 1'b1;
            reservation_addr_q <= (mem_size_q == `MEM_SIZE_WORD) ?
                (mem_eff_addr_q & {{(`XLEN-2){1'b1}}, 2'b00}) :
                (mem_eff_addr_q & {{(`XLEN-`XLEN_BYTE_W){1'b1}},
                                   {`XLEN_BYTE_W{1'b0}}});
            reservation_size_q <= mem_size_q;
          end else if (mem_amo_sc_q) begin
            reservation_valid_q <= 1'b0;
            reservation_addr_q <= {`XLEN{1'b0}};
            reservation_size_q <= 2'b00;
          end
        end
        mem_pending_q <= 1'b0;
        mem_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        mem_producer_id_q <= {PRODUCER_ID_W{1'b0}};
        mem_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        mem_load_q <= 1'b0;
        mem_store_q <= 1'b0;
        mem_amo_q <= 1'b0;
        mem_amo_lr_q <= 1'b0;
        mem_amo_sc_q <= 1'b0;
        mem_amo_write_phase_q <= 1'b0;
        mem_amo_write_sent_q <= 1'b0;
        mem_eff_addr_q <= {`XLEN{1'b0}};
        mem_size_q <= 2'b00;
        mem_unsigned_q <= 1'b0;
        mem_amo_inst_q <= {`INST_W{1'b0}};
        mem_amo_src2_q <= {`XLEN{1'b0}};
        mem_amo_old_value_q <= {`XLEN{1'b0}};
        mem_amo_write_data_q <= {`XLEN{1'b0}};
        mem_amo_write_wstrb_q <= {`STRB_W{1'b0}};
        mem_owner_kind_q <= MEM_OWNER_RESERVED;
        mem_owner_token_q <= 5'b0;
        mem_mmu_epoch_q <= MEM_OWNER_EPOCH_BASE;
        mem_fault_tval_q <= {`XLEN{1'b0}};
        mem_probe_q <= 1'b0;
      end
      if (mem_buffer_req_fire_w && mem_buffer_store_q) begin
        reservation_valid_q <= 1'b0;
        reservation_addr_q <= {`XLEN{1'b0}};
        reservation_size_q <= 2'b00;
      end
      if (mem_buffer_req_fire_w || mem_buffer_kill_w) begin
        mem_buffer_valid_q <= 1'b0;
        mem_buffer_rob_idx_q <= {ROB_INDEX_W{1'b0}};
        mem_buffer_pdest_q <= {PHY_REG_ADDR_W{1'b0}};
        mem_buffer_pdest_fp_q <= 1'b0;
        mem_buffer_load_q <= 1'b0;
        mem_buffer_store_q <= 1'b0;
        mem_buffer_eff_addr_q <= {`XLEN{1'b0}};
        mem_buffer_size_q <= 2'b00;
        mem_buffer_unsigned_q <= 1'b0;
        mem_buffer_wdata_q <= {`XLEN{1'b0}};
        mem_buffer_wstrb_q <= {`STRB_W{1'b0}};
        mem_buffer_owner_kind_q <= MEM_OWNER_RESERVED;
        mem_buffer_owner_token_q <= 5'b0;
        mem_buffer_mmu_epoch_q <= MEM_OWNER_EPOCH_BASE;
        mem_buffer_fault_tval_q <= {`XLEN{1'b0}};
      end
      if (push_amo_write_w) begin
        mem_amo_write_sent_q <= 1'b1;
        reservation_valid_q <= 1'b0;
        reservation_addr_q <= {`XLEN{1'b0}};
        reservation_size_q <= 2'b00;
      end
      // SC 一旦被执行端消费便无条件失效 reservation：包括成功请求、
      // reservation miss 的本地失败，以及 matching-but-misaligned 的本地异常。
      if ((mem_issue_res_consume_fire_w && issue0_is_sc_w) ||
          (mem_issue1_res_consume_fire_w && issue1_is_sc_w)) begin
        reservation_valid_q <= 1'b0;
        reservation_addr_q <= {`XLEN{1'b0}};
        reservation_size_q <= 2'b00;
      end
      if (issue0_mem_request_fire_w) begin
        if (issue0_mem_req_write_w && !issue0_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
          reservation_size_q <= 2'b00;
        end
      end
      // 单例(LEGACY)只承载 AMO/LR/SC/MMIO-load 独占族; plain 状态在 MIQ。
      if (issue0_mem_request_fire_w && issue0_is_excl_kind_w) begin
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= mem_issue_res_rob_idx_q;
        mem_producer_id_q <= mem_issue_res_producer_id_q;
        mem_pdest_q <= mem_issue_res_pdest_q;
        mem_pdest_fp_q <= mem_issue_res_fp_pdest_q;
        mem_load_q <= issue0_is_load_w || issue0_is_lr_w ||
                      (issue0_is_amo_w && !issue0_is_sc_w);
        mem_store_q <= issue0_mem_req_write_w;
        mem_amo_q <= issue0_is_amo_w;
        mem_amo_lr_q <= issue0_is_lr_w;
        mem_amo_sc_q <= issue0_is_sc_w;
        mem_amo_write_phase_q <= 1'b0;
        mem_amo_write_sent_q <= 1'b0;
        mem_eff_addr_q <= mem_issue_res_eff_addr_w;
        mem_size_q <=
            mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_unsigned_q <= mem_issue_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT] ||
                          (issue0_is_amo_w &&
                           (mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:
                                                 `CTRL_MEM_SIZE_LSB] ==
                            `MEM_SIZE_DWORD));
        mem_amo_inst_q <= mem_issue_res_inst_q;
        mem_amo_src2_q <= mem_issue_res_src2_data_q;
        mem_probe_q <= sq_mode_w && issue0_is_plain_store_w;
        mem_store_wdata_q <= issue0_mem_wdata_w;
        mem_store_wstrb_q <= issue0_mem_wstrb_w;
        mem_owner_kind_q <= mem_issue_res_owner_kind_q;
        mem_owner_token_q <= mem_issue_res_owner_token_q;
        mem_mmu_epoch_q <= mem_issue_res_mmu_epoch_q;
        mem_fault_tval_q <= mem_issue_res_fault_tval_q;
      end
      if (issue1_mem_request_fire_w) begin
        if (issue1_mem_req_write_w && !issue1_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
          reservation_size_q <= 2'b00;
        end
      end
      if (issue1_mem_request_fire_w && issue1_is_excl_kind_w) begin
        mem_pending_q <= 1'b1;
        mem_rob_idx_q <= mem_issue1_res_rob_idx_q;
        mem_producer_id_q <= mem_issue1_res_producer_id_q;
        mem_pdest_q <= mem_issue1_res_pdest_q;
        mem_pdest_fp_q <= mem_issue1_res_fp_pdest_q;
        mem_load_q <= issue1_is_load_w || issue1_is_lr_w ||
                      (issue1_is_amo_w && !issue1_is_sc_w);
        mem_store_q <= issue1_mem_req_write_w;
        mem_amo_q <= issue1_is_amo_w;
        mem_amo_lr_q <= issue1_is_lr_w;
        mem_amo_sc_q <= issue1_is_sc_w;
        mem_amo_write_phase_q <= 1'b0;
        mem_amo_write_sent_q <= 1'b0;
        mem_eff_addr_q <= mem_issue1_res_eff_addr_w;
        mem_size_q <= mem_issue1_res_ctrl_q[
            `CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_unsigned_q <= mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT] ||
                          (issue1_is_amo_w &&
                           (mem_issue1_res_ctrl_q[
                                `CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] ==
                            `MEM_SIZE_DWORD));
        mem_amo_inst_q <= mem_issue1_res_inst_q;
        mem_amo_src2_q <= mem_issue1_res_src2_data_q;
        mem_probe_q <= sq_mode_w && issue1_is_plain_store_w;
        mem_store_wdata_q <= issue1_mem_wdata_w;
        mem_store_wstrb_q <= issue1_mem_wstrb_w;
        mem_owner_kind_q <= mem_issue1_res_owner_kind_q;
        mem_owner_token_q <= mem_issue1_res_owner_token_q;
        mem_mmu_epoch_q <= mem_issue1_res_mmu_epoch_q;
        mem_fault_tval_q <= mem_issue1_res_fault_tval_q;
      end
      // buffer 迁移的 plain 事务状态在 MIQ, 不再写单例(LEGACY 只承载
      // AMO/LR/SC/MMIO-load 独占族)。
      if (issue0_mem_buffer_fire_w) begin
        if (issue0_is_store_w && !issue0_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
          reservation_size_q <= 2'b00;
        end
        mem_buffer_valid_q <= 1'b1;
        mem_buffer_rob_idx_q <= mem_issue_res_rob_idx_q;
        mem_buffer_pdest_q <= mem_issue_res_pdest_q;
        mem_buffer_pdest_fp_q <= mem_issue_res_fp_pdest_q;
        mem_buffer_load_q <= issue0_is_load_w;
        mem_buffer_store_q <= issue0_is_store_w;
        mem_buffer_eff_addr_q <= mem_issue_res_eff_addr_w;
        mem_buffer_size_q <=
            mem_issue_res_ctrl_q[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_buffer_unsigned_q <=
            mem_issue_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT];
        mem_buffer_wdata_q <= issue0_mem_wdata_w;
        mem_buffer_wstrb_q <= issue0_mem_wstrb_w;
        mem_buffer_owner_kind_q <= mem_issue_res_owner_kind_q;
        mem_buffer_owner_token_q <= mem_issue_res_owner_token_q;
        mem_buffer_mmu_epoch_q <= mem_issue_res_mmu_epoch_q;
        mem_buffer_fault_tval_q <= mem_issue_res_fault_tval_q;
      end
      if (issue1_mem_buffer_fire_w) begin
        if (issue1_is_store_w && !issue1_is_sc_w) begin
          reservation_valid_q <= 1'b0;
          reservation_addr_q <= {`XLEN{1'b0}};
          reservation_size_q <= 2'b00;
        end
        mem_buffer_valid_q <= 1'b1;
        mem_buffer_rob_idx_q <= mem_issue1_res_rob_idx_q;
        mem_buffer_pdest_q <= mem_issue1_res_pdest_q;
        mem_buffer_pdest_fp_q <= mem_issue1_res_fp_pdest_q;
        mem_buffer_load_q <= issue1_is_load_w;
        mem_buffer_store_q <= issue1_is_store_w;
        mem_buffer_eff_addr_q <= mem_issue1_res_eff_addr_w;
        mem_buffer_size_q <= mem_issue1_res_ctrl_q[
            `CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
        mem_buffer_unsigned_q <=
            mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT];
        mem_buffer_wdata_q <= issue1_mem_wdata_w;
        mem_buffer_wstrb_q <= issue1_mem_wstrb_w;
        mem_buffer_owner_kind_q <= mem_issue1_res_owner_kind_q;
        mem_buffer_owner_token_q <= mem_issue1_res_owner_token_q;
        mem_buffer_mmu_epoch_q <= mem_issue1_res_mmu_epoch_q;
        mem_buffer_fault_tval_q <= mem_issue1_res_fault_tval_q;
      end
      // ex0/ex1 EX→WB 级间簇装载臂已等价改写为组合 up_valid/up_payload(见 always 前),
      // 寄存本体在 PipeStageReg 实例 u_ex0_stage/u_ex1_stage 内。
    end
  end

  // mem 侧 wb 事务: LEGACY 完成 + plain LOAD + PROBE fault + physical
  // store B terminal。成功 probe 只 fill SQ，绝不提前标 ROB done。
  wire miq_load_wb_fire_w =
      miq_load_rsp_fire_w && mem_owner_open_w;
  wire miq_probe_wb_fire_w =
      miq_probe_rsp_fire_w && mem_owner_open_w &&
      (mem_rsp_fault_w || !sq_mode_w);
  wire miq_drain_wb_fire_w =
      miq_drain_rsp_fire_w && mem_owner_open_w;
  wire mem_legacy_wb_fire_w =
      mem_rsp_final_fire_w && mem_owner_open_w;
  wire mem_wb_fire_w = mem_legacy_wb_fire_w || miq_load_wb_fire_w ||
                       miq_probe_wb_fire_w || miq_drain_wb_fire_w;
  wire miq1_load_wb_fire_w =
      miq1_load_rsp_fire_w && mem1_owner_open_w;
  wire miq1_probe_wb_fire_w =
      miq1_probe_rsp_fire_w && mem1_owner_open_w &&
      (mem1_rsp_fault_w || !sq_mode_w);
  wire mem1_wb_fire_w = miq1_load_wb_fire_w || miq1_probe_wb_fire_w;
  // A FIFO token is an edge-old completion capability.  Once it exists, only
  // its formal head may close the PID; all later ordinary sources drain raw
  // and fail closed.  EX0/EX1 retain priority for a PID that has no token yet.
  wire mem_fp_pending_owned_w =
      fp_completion_pending_mask_w[mem_completion_producer_id_w];
  wire mem_same_edge_claimed_w =
      (ex0_wb_valid_w &&
       (ex0_producer_id_q == mem_completion_producer_id_w)) ||
      (ex1_wb_valid_w &&
       (ex1_producer_id_q == mem_completion_producer_id_w));
  wire mem_completion_authorized_w = mem_wb_fire_w &&
      !mem_fp_pending_owned_w && !mem_same_edge_claimed_w;
  // Raw route remains independent of completion authorization.  An exact
  // memory terminal that lost a PID claim still consumes its transport slot
  // for this cycle and releases its holder through the existing terminal path.
  wire mem_rsp_to_wb0_w = mem_wb_fire_w && mem_wb_slot0_grant_w;
  wire mem_rsp_to_wb1_w = mem_wb_fire_w && mem_wb_slot1_grant_w;
  wire mem_wb0_valid_w =
      mem_rsp_to_wb0_w && mem_completion_authorized_w;
  wire mem_wb1_valid_w =
      mem_rsp_to_wb1_w && mem_completion_authorized_w;
  wire mem_actual_claim_w = mem_wb0_valid_w || mem_wb1_valid_w;
  wire mem1_fp_pending_owned_w =
      fp_completion_pending_mask_w[mem1_completion_producer_id_w];
  wire mem1_same_edge_claimed_w =
      (ex0_wb_valid_w &&
       (ex0_producer_id_q == mem1_completion_producer_id_w)) ||
      (ex1_wb_valid_w &&
       (ex1_producer_id_q == mem1_completion_producer_id_w)) ||
      (mem_actual_claim_w &&
       (mem_completion_producer_id_w == mem1_completion_producer_id_w));
  wire mem1_completion_authorized_w = mem1_wb_fire_w &&
      !mem1_fp_pending_owned_w && !mem1_same_edge_claimed_w;
  wire mem1_rsp_to_wb0_w = mem1_wb_fire_w && mem1_wb_slot0_grant_w;
  wire mem1_rsp_to_wb1_w = mem1_wb_fire_w && mem1_wb_slot1_grant_w;
  wire mem1_wb0_valid_w = mem1_rsp_to_wb0_w &&
      mem1_completion_authorized_w;
  wire mem1_wb1_valid_w = mem1_rsp_to_wb1_w &&
      mem1_completion_authorized_w;
  wire mem1_actual_claim_w = mem1_wb0_valid_w || mem1_wb1_valid_w;
  wire muldiv_fp_pending_owned_w =
      fp_completion_pending_mask_w[muldiv_resp_producer_id_w];
  wire muldiv_same_edge_claimed_w =
      (ex0_wb_valid_w &&
       (ex0_producer_id_q == muldiv_resp_producer_id_w)) ||
      (ex1_wb_valid_w &&
       (ex1_producer_id_q == muldiv_resp_producer_id_w)) ||
      (mem_actual_claim_w &&
       (mem_completion_producer_id_w == muldiv_resp_producer_id_w)) ||
      (mem1_actual_claim_w &&
       (mem1_completion_producer_id_w == muldiv_resp_producer_id_w));
  wire muldiv_completion_authorized_w = muldiv_resp_valid_w &&
      muldiv_completion_rob_open_w && !muldiv_fp_pending_owned_w &&
      !muldiv_same_edge_claimed_w;
  // Long-op route/ready are raw transport facts.  Exact-open and same-edge
  // claim only qualify the *_wb*_valid side-effect facts below.
  wire muldiv_rsp_to_wb0_w =
      muldiv_resp_valid_w && !ex0_wb_slot_occupied_w &&
      !mem_rsp_to_wb0_w && !mem1_rsp_to_wb0_w;
  wire muldiv_rsp_to_wb1_w =
      muldiv_resp_valid_w && !muldiv_rsp_to_wb0_w &&
      !ex1_wb_slot_occupied_w &&
      !mem_rsp_to_wb1_w && !mem1_rsp_to_wb1_w;
  wire muldiv_wb0_valid_w =
      muldiv_rsp_to_wb0_w && muldiv_completion_authorized_w;
  wire muldiv_wb1_valid_w =
      muldiv_rsp_to_wb1_w && muldiv_completion_authorized_w;
  wire muldiv_actual_claim_w = muldiv_wb0_valid_w || muldiv_wb1_valid_w;
  wire clmul_fp_pending_owned_w =
      fp_completion_pending_mask_w[clmul_resp_producer_id_w];
  wire clmul_same_edge_claimed_w =
      (ex0_wb_valid_w &&
       (ex0_producer_id_q == clmul_resp_producer_id_w)) ||
      (ex1_wb_valid_w &&
       (ex1_producer_id_q == clmul_resp_producer_id_w)) ||
      (mem_actual_claim_w &&
       (mem_completion_producer_id_w == clmul_resp_producer_id_w)) ||
      (mem1_actual_claim_w &&
       (mem1_completion_producer_id_w == clmul_resp_producer_id_w)) ||
      (muldiv_actual_claim_w &&
       (muldiv_resp_producer_id_w == clmul_resp_producer_id_w));
  wire clmul_completion_authorized_w = clmul_resp_valid_w &&
      clmul_completion_rob_open_w && !clmul_fp_pending_owned_w &&
      !clmul_same_edge_claimed_w;
  wire clmul_rsp_to_wb0_w =
      clmul_resp_valid_w && !ex0_wb_slot_occupied_w &&
      !mem_rsp_to_wb0_w && !mem1_rsp_to_wb0_w && !muldiv_rsp_to_wb0_w;
  wire clmul_rsp_to_wb1_w =
      clmul_resp_valid_w && !clmul_rsp_to_wb0_w &&
      !ex1_wb_slot_occupied_w &&
      !mem_rsp_to_wb1_w && !mem1_rsp_to_wb1_w && !muldiv_rsp_to_wb1_w;
  wire clmul_wb0_valid_w =
      clmul_rsp_to_wb0_w && clmul_completion_authorized_w;
  wire clmul_wb1_valid_w =
      clmul_rsp_to_wb1_w && clmul_completion_authorized_w;
  // 【B-FP 簇】FP formal token: route/ready are raw; exact-open and the
  // per-PID claim chain qualify only actual WB side effects.
  wire fpwb_to_wb0_w =
      fpwb_valid_w && !ex0_wb_slot_occupied_w && !mem_rsp_to_wb0_w &&
      !mem1_rsp_to_wb0_w && !muldiv_rsp_to_wb0_w &&
      !clmul_rsp_to_wb0_w;
  wire fpwb_to_wb1_w =
      fpwb_valid_w && !fpwb_to_wb0_w && !ex1_wb_slot_occupied_w &&
      !mem_rsp_to_wb1_w &&
      !mem1_rsp_to_wb1_w && !muldiv_rsp_to_wb1_w &&
      !clmul_rsp_to_wb1_w;
  assign fpwb_ready_w = fpwb_to_wb0_w || fpwb_to_wb1_w;
  wire fpwb_pending_owner_w =
      fp_completion_pending_mask_w[fpwb_producer_id_w];
  wire fpwb_same_edge_claimed_w =
      (ex0_wb_valid_w &&
       (ex0_producer_id_q == fpwb_producer_id_w)) ||
      (ex1_wb_valid_w &&
       (ex1_producer_id_q == fpwb_producer_id_w)) ||
      (mem_actual_claim_w &&
       (mem_completion_producer_id_w == fpwb_producer_id_w)) ||
      (mem1_actual_claim_w &&
       (mem1_completion_producer_id_w == fpwb_producer_id_w)) ||
      (muldiv_actual_claim_w &&
       (muldiv_resp_producer_id_w == fpwb_producer_id_w)) ||
      ((clmul_wb0_valid_w || clmul_wb1_valid_w) &&
       (clmul_resp_producer_id_w == fpwb_producer_id_w));
  wire fpwb_completion_authorized_w = fpwb_valid_w &&
      fp_formal_completion_rob_open_w && fpwb_pending_owner_w &&
      !fpwb_same_edge_claimed_w;
  wire fpwb_wb0_valid_w =
      fpwb_to_wb0_w && fpwb_completion_authorized_w;
  wire fpwb_wb1_valid_w =
      fpwb_to_wb1_w && fpwb_completion_authorized_w;
  wire fpwb_actual_claim_w = fpwb_wb0_valid_w || fpwb_wb1_valid_w;

  wire fp_result_pending_owned_w =
      fp_completion_pending_mask_w[fp_result_query_producer_id_w];
  wire fp_result_same_edge_claimed_w =
      (ex0_wb_valid_w &&
       (ex0_producer_id_q == fp_result_query_producer_id_w)) ||
      (ex1_wb_valid_w &&
       (ex1_producer_id_q == fp_result_query_producer_id_w)) ||
      (mem_actual_claim_w &&
       (mem_completion_producer_id_w ==
        fp_result_query_producer_id_w)) ||
      (mem1_actual_claim_w &&
       (mem1_completion_producer_id_w ==
        fp_result_query_producer_id_w)) ||
      (muldiv_actual_claim_w &&
       (muldiv_resp_producer_id_w == fp_result_query_producer_id_w)) ||
      ((clmul_wb0_valid_w || clmul_wb1_valid_w) &&
       (clmul_resp_producer_id_w == fp_result_query_producer_id_w)) ||
      (fpwb_actual_claim_w &&
       (fpwb_producer_id_w == fp_result_query_producer_id_w));
  assign fp_result_authorized_w = fp_result_query_valid_w &&
      fp_result_completion_rob_open_w && !fp_result_pending_owned_w &&
      !fp_result_same_edge_claimed_w;
  // 【B-FP 簇】FP load: NaN-box(FLW 高 32 全 1)后进 ROB data(commit 写架构 FPR)
  // 与 fpld_wb(写 FP 物理堆+FP 唤醒); int PRF 写与 int 唤醒按 fp gate(pdest 置 0)。
  // wb 事务是否 load 语义(plain LOAD 恒是; LEGACY 按单例)
  wire mem_wb_is_load_w = miq_load_wb_fire_w ||
                          (mem_legacy_wb_fire_w && mem_load_q);
  wire mem_rsp_fp_load_w = miq_head_pdest_fp_w && mem_wb_is_load_w;
  wire [`XLEN-1:0] mem_rsp_fp_boxed_w =
      (miq_head_size_w == `MEM_SIZE_DWORD) ? mem_rsp_load_data_w :
      {32'hffff_ffff, mem_rsp_load_data_w[31:0]};
  wire [`XLEN-1:0] mem_rsp_wb_data_w =
      (miq_probe_wb_fire_w || miq_drain_wb_fire_w) ? {`XLEN{1'b0}} :
      (mem_legacy_wb_fire_w && mem_amo_q) ?
                  (mem_amo_sc_q ? {`XLEN{1'b0}} :
                   (mem_amo_write_phase_q ? mem_amo_old_value_q :
                                            mem_amo_old_value_w)) :
      mem_rsp_fp_load_w ? mem_rsp_fp_boxed_w :
      mem_wb_is_load_w ? mem_rsp_load_data_w : {`XLEN{1'b0}};
  // T3G：整数 MEM 目的只进入 formal WB；此处仍负责把 FP load / store probe
  // 映射为 p0，禁止它们误写或误唤醒整数物理寄存器。
  wire [PHY_REG_ADDR_W-1:0] mem_rsp_int_pdest_w =
      (miq_head_pdest_fp_w || miq_probe_wb_fire_w || miq_drain_wb_fire_w) ?
        {PHY_REG_ADDR_W{1'b0}} : miq_head_pdest_w;
  // store 语义(fault cause 用): PROBE(plain store 探测)或 LEGACY store/AMO 写臂
  wire mem_wb_store_cause_w =
      miq_probe_wb_fire_w || miq_drain_wb_fire_w ||
      (mem_legacy_wb_fire_w &&
       (mem_store_q || (mem_amo_q && (mem_amo_sc_q || mem_amo_write_phase_q))));
  wire [`TRAP_CAUSE_W-1:0] mem_rsp_wb_cause_w =
      miq_drain_wb_fire_w ? `EXC_STORE_ACCESS_FAULT :
      mem_rsp_page_fault_i ?
      (mem_wb_store_cause_w ? `EXC_STORE_PAGE_FAULT : `EXC_LOAD_PAGE_FAULT) :
      (mem_wb_store_cause_w ? `EXC_STORE_ACCESS_FAULT : `EXC_LOAD_ACCESS_FAULT);
  wire mem1_wb_is_load_w = miq1_load_wb_fire_w;
  wire mem1_rsp_fp_load_w = miq1_head_pdest_fp_w && mem1_wb_is_load_w;
  wire [`XLEN-1:0] mem1_rsp_fp_boxed_w =
      (miq1_head_size_w == `MEM_SIZE_DWORD) ? mem1_rsp_load_data_w :
      {32'hffff_ffff, mem1_rsp_load_data_w[31:0]};
  wire [`XLEN-1:0] mem1_rsp_wb_data_w =
      miq1_probe_wb_fire_w ? {`XLEN{1'b0}} :
      mem1_rsp_fp_load_w ? mem1_rsp_fp_boxed_w :
      mem1_wb_is_load_w ? mem1_rsp_load_data_w : {`XLEN{1'b0}};
  wire [PHY_REG_ADDR_W-1:0] mem1_rsp_int_pdest_w =
      (miq1_head_pdest_fp_w || miq1_probe_wb_fire_w) ?
      {PHY_REG_ADDR_W{1'b0}} : miq1_head_pdest_w;
  wire mem1_wb_store_cause_w = miq1_probe_wb_fire_w;
  wire [`TRAP_CAUSE_W-1:0] mem1_rsp_wb_cause_w =
      mem1_rsp_page_fault_i ?
      (mem1_wb_store_cause_w ? `EXC_STORE_PAGE_FAULT :
                                `EXC_LOAD_PAGE_FAULT) :
      (mem1_wb_store_cause_w ? `EXC_STORE_ACCESS_FAULT :
                                `EXC_LOAD_ACCESS_FAULT);

  assign muldiv_resp_ready_w = muldiv_rsp_to_wb0_w || muldiv_rsp_to_wb1_w;
  assign clmul_resp_ready_w = clmul_rsp_to_wb0_w || clmul_rsp_to_wb1_w;

  assign wb0_valid_w =
      ex0_wb_valid_w || mem_wb0_valid_w || mem1_wb0_valid_w ||
      muldiv_wb0_valid_w || clmul_wb0_valid_w || fpwb_wb0_valid_w;
  assign wb0_producer_id_w = ex0_wb_valid_w ? ex0_producer_id_q :
      mem_rsp_to_wb0_w ? mem_completion_producer_id_w :
      mem1_rsp_to_wb0_w ? mem1_completion_producer_id_w :
      muldiv_rsp_to_wb0_w ? muldiv_resp_producer_id_w :
      clmul_rsp_to_wb0_w ? clmul_resp_producer_id_w :
                           fpwb_producer_id_w;
  assign wb0_rob_idx_w = ex0_wb_valid_w ? ex0_rob_idx_q :
                         mem_rsp_to_wb0_w ? miq_head_rob_w :
                         mem1_rsp_to_wb0_w ? miq1_head_rob_w :
                         muldiv_rsp_to_wb0_w ? muldiv_resp_rob_idx_w :
                         clmul_rsp_to_wb0_w ? clmul_resp_rob_idx_w :
                                              fpwb_rob_idx_w;
  assign wb0_pdest_w = ex0_wb_valid_w ? ex0_pdest_q :
                       mem_rsp_to_wb0_w ? mem_rsp_int_pdest_w :
                       mem1_rsp_to_wb0_w ? mem1_rsp_int_pdest_w :
                       muldiv_rsp_to_wb0_w ? muldiv_resp_pdest_w :
                       clmul_rsp_to_wb0_w ? clmul_resp_pdest_w :
                       (fpwb_rd_en_w ? fpwb_pdest_w
                                     : {PHY_REG_ADDR_W{1'b0}});
  assign wb0_data_w = ex0_wb_valid_w ? ex0_result_q :
                      mem_rsp_to_wb0_w ? mem_rsp_wb_data_w :
                      mem1_rsp_to_wb0_w ? mem1_rsp_wb_data_w :
                      muldiv_rsp_to_wb0_w ? muldiv_resp_data_w :
                      clmul_rsp_to_wb0_w ? clmul_resp_data_w :
                                           fpwb_data_w;
  assign wb0_exception_w = ex0_wb_valid_w ? ex0_exception_q :
                           mem_rsp_to_wb0_w ?
                             ((miq_probe_wb_fire_w || miq_drain_wb_fire_w) ?
                                mem_rsp_fault_w : mem_rsp_error_i) :
                           mem1_rsp_to_wb0_w ?
                             (miq1_probe_wb_fire_w ? mem1_rsp_fault_w :
                                                    mem1_rsp_error_i) :
                                               1'b0;
  assign wb0_cause_w = ex0_wb_valid_w ? ex0_cause_q :
                       mem_rsp_to_wb0_w ? mem_rsp_wb_cause_w :
                       mem1_rsp_to_wb0_w ? mem1_rsp_wb_cause_w :
                                           {`TRAP_CAUSE_W{1'b0}};
  assign wb0_tval_w = ex0_wb_valid_w ? ex0_tval_q :
                      mem_rsp_to_wb0_w ?
                        (miq_drain_wb_fire_w ? sq_drain_vaddr_w :
                                               miq_head_addr_w) :
                      mem1_rsp_to_wb0_w ? miq1_head_addr_w :
                                          {`XLEN{1'b0}};
  assign wb0_fflags_w = fpwb_wb0_valid_w ? fpwb_fflags_w : 5'b00000;
  assign wb1_fflags_w = fpwb_wb1_valid_w ? fpwb_fflags_w : 5'b00000;
  assign wb1_valid_w =
      ex1_wb_valid_w || mem_wb1_valid_w || mem1_wb1_valid_w ||
      muldiv_wb1_valid_w || clmul_wb1_valid_w || fpwb_wb1_valid_w;
  assign wb1_producer_id_w = ex1_wb_valid_w ? ex1_producer_id_q :
      mem_rsp_to_wb1_w ? mem_completion_producer_id_w :
      mem1_rsp_to_wb1_w ? mem1_completion_producer_id_w :
      muldiv_rsp_to_wb1_w ? muldiv_resp_producer_id_w :
      clmul_rsp_to_wb1_w ? clmul_resp_producer_id_w :
                           fpwb_producer_id_w;
  assign wb1_rob_idx_w = ex1_wb_valid_w ? ex1_rob_idx_q :
                         mem_rsp_to_wb1_w ? miq_head_rob_w :
                         mem1_rsp_to_wb1_w ? miq1_head_rob_w :
                         muldiv_rsp_to_wb1_w ? muldiv_resp_rob_idx_w :
                         clmul_rsp_to_wb1_w ? clmul_resp_rob_idx_w :
                                              fpwb_rob_idx_w;
  assign wb1_pdest_w = ex1_wb_valid_w ? ex1_pdest_q :
                       mem_rsp_to_wb1_w ? mem_rsp_int_pdest_w :
                       mem1_rsp_to_wb1_w ? mem1_rsp_int_pdest_w :
                       muldiv_rsp_to_wb1_w ? muldiv_resp_pdest_w :
                       clmul_rsp_to_wb1_w ? clmul_resp_pdest_w :
                       (fpwb_rd_en_w ? fpwb_pdest_w
                                     : {PHY_REG_ADDR_W{1'b0}});
  assign wb1_data_w = ex1_wb_valid_w ? ex1_result_q :
                      mem_rsp_to_wb1_w ? mem_rsp_wb_data_w :
                      mem1_rsp_to_wb1_w ? mem1_rsp_wb_data_w :
                      muldiv_rsp_to_wb1_w ? muldiv_resp_data_w :
                      clmul_rsp_to_wb1_w ? clmul_resp_data_w :
                                           fpwb_data_w;
  assign wb1_exception_w = ex1_wb_valid_w ? ex1_exception_q :
                           mem_rsp_to_wb1_w ?
                             ((miq_probe_wb_fire_w || miq_drain_wb_fire_w) ?
                                mem_rsp_fault_w : mem_rsp_error_i) :
                           mem1_rsp_to_wb1_w ?
                             (miq1_probe_wb_fire_w ? mem1_rsp_fault_w :
                                                    mem1_rsp_error_i) :
                                               1'b0;
  assign wb1_cause_w = ex1_wb_valid_w ? ex1_cause_q :
                       mem_rsp_to_wb1_w ? mem_rsp_wb_cause_w :
                       mem1_rsp_to_wb1_w ? mem1_rsp_wb_cause_w :
                                           {`TRAP_CAUSE_W{1'b0}};
  assign wb1_tval_w = ex1_wb_valid_w ? ex1_tval_q :
                      mem_rsp_to_wb1_w ?
                        (miq_drain_wb_fire_w ? sq_drain_vaddr_w :
                                               miq_head_addr_w) :
                      mem1_rsp_to_wb1_w ? miq1_head_addr_w :
                                          {`XLEN{1'b0}};

  // P0-A: write-enable 在各 WB owner 的本地 pdest 上完成 p0 过滤后再 OR。
  // 这保持 formal-WB payload/ROB/exception/execute-valid 完全不变，同时把
  // MEM completion 从 generic pdest mux -> zero-compare 的控制锥中切开。
  // 可在两端口间迁移的 source 共用一个 nonzero predicate，避免复制比较器。
  wire ex0_wb_pdest_nonzero_w =
      ex0_pdest_q != {PHY_REG_ADDR_W{1'b0}};
  wire ex1_wb_pdest_nonzero_w =
      ex1_pdest_q != {PHY_REG_ADDR_W{1'b0}};
  wire mem_wb_pdest_nonzero_w =
      mem_rsp_int_pdest_w != {PHY_REG_ADDR_W{1'b0}};
  wire mem1_wb_pdest_nonzero_w =
      mem1_rsp_int_pdest_w != {PHY_REG_ADDR_W{1'b0}};
  wire muldiv_wb_pdest_nonzero_w =
      muldiv_resp_pdest_w != {PHY_REG_ADDR_W{1'b0}};
  wire clmul_wb_pdest_nonzero_w =
      clmul_resp_pdest_w != {PHY_REG_ADDR_W{1'b0}};
  wire fpwb_gpr_pdest_nonzero_w =
      fpwb_rd_en_w && (fpwb_pdest_w != {PHY_REG_ADDR_W{1'b0}});
  assign gpr_wb0_write_valid_w =
      (ex0_wb_valid_w && ex0_wb_pdest_nonzero_w) ||
      (mem_wb0_valid_w && mem_wb_pdest_nonzero_w) ||
      (mem1_wb0_valid_w && mem1_wb_pdest_nonzero_w) ||
      (muldiv_wb0_valid_w && muldiv_wb_pdest_nonzero_w) ||
      (clmul_wb0_valid_w && clmul_wb_pdest_nonzero_w) ||
      (fpwb_wb0_valid_w && fpwb_gpr_pdest_nonzero_w);
  assign gpr_wb1_write_valid_w =
      (ex1_wb_valid_w && ex1_wb_pdest_nonzero_w) ||
      (mem_wb1_valid_w && mem_wb_pdest_nonzero_w) ||
      (mem1_wb1_valid_w && mem1_wb_pdest_nonzero_w) ||
      (muldiv_wb1_valid_w && muldiv_wb_pdest_nonzero_w) ||
      (clmul_wb1_valid_w && clmul_wb_pdest_nonzero_w) ||
      (fpwb_wb1_valid_w && fpwb_gpr_pdest_nonzero_w);

`ifdef OOO_ASSERT
  // 旧 generic mux 表达式只作仿真 shadow，不进入 PPA。onehot0 是新局部
  // OR 拓扑与旧优先 mux cycle-exact 等价的承重前提，故两者都 fail closed。
  wire gpr_wb0_legacy_write_valid_w =
      wb0_valid_w && (wb0_pdest_w != {PHY_REG_ADDR_W{1'b0}});
  wire gpr_wb1_legacy_write_valid_w =
      wb1_valid_w && (wb1_pdest_w != {PHY_REG_ADDR_W{1'b0}});
  wire [5:0] wb0_source_onehot_w = {
      fpwb_wb0_valid_w, clmul_wb0_valid_w, muldiv_wb0_valid_w,
      mem1_wb0_valid_w, mem_wb0_valid_w, ex0_wb_valid_w
  };
  wire [5:0] wb1_source_onehot_w = {
      fpwb_wb1_valid_w, clmul_wb1_valid_w, muldiv_wb1_valid_w,
      mem1_wb1_valid_w, mem_wb1_valid_w, ex1_wb_valid_w
  };
  wire [2:0] wb0_source_count_w =
      {2'b00, wb0_source_onehot_w[0]} +
      {2'b00, wb0_source_onehot_w[1]} +
      {2'b00, wb0_source_onehot_w[2]} +
      {2'b00, wb0_source_onehot_w[3]} +
      {2'b00, wb0_source_onehot_w[4]} +
      {2'b00, wb0_source_onehot_w[5]};
  wire [2:0] wb1_source_count_w =
      {2'b00, wb1_source_onehot_w[0]} +
      {2'b00, wb1_source_onehot_w[1]} +
      {2'b00, wb1_source_onehot_w[2]} +
      {2'b00, wb1_source_onehot_w[3]} +
      {2'b00, wb1_source_onehot_w[4]} +
      {2'b00, wb1_source_onehot_w[5]};
  always @(posedge clk) begin
    if (!rst) begin
      if (pending_system_producer_valid_i &&
          (pending_system_producer_live_mask_w !=
           ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
            pending_system_producer_id_i))) begin
        $error("[V8K-PENDING-CSR-LEASE-DECODE] raw pending lease is not exact onehot pid=%h @%0t",
               pending_system_producer_id_i, $time);
        $fatal;
      end
      if (!pending_system_producer_valid_i &&
          (pending_system_producer_live_mask_w !=
           {(1 << PRODUCER_ID_W){1'b0}})) begin
        $error("[V8K-PENDING-CSR-LEASE-ZERO] invalid pending lease contributed holder bits @%0t",
               $time);
        $fatal;
      end
      if (dispatch0_fire_w && pending_system_producer_valid_i &&
          (dispatch0_producer_id_w == pending_system_producer_id_i)) begin
        $error("[V8K-PENDING-CSR-NO-LIVE-REUSE] lane0 reused pending CSR ProducerId=%h @%0t",
               dispatch0_producer_id_w, $time);
        $fatal;
      end
      if (wb0_source_count_w > 3'd1)
        $error("[INT-WB0-SOURCE-ONEHOT0] sources=%b @%0t",
               wb0_source_onehot_w, $time);
      if (wb1_source_count_w > 3'd1)
        $error("[INT-WB1-SOURCE-ONEHOT0] sources=%b @%0t",
               wb1_source_onehot_w, $time);
      if (gpr_wb0_write_valid_w !== gpr_wb0_legacy_write_valid_w)
        $error("[INT-WB0-WRITE-VALID-EQUIV] local=%b legacy=%b sources=%b @%0t",
               gpr_wb0_write_valid_w, gpr_wb0_legacy_write_valid_w,
               wb0_source_onehot_w, $time);
      if (gpr_wb1_write_valid_w !== gpr_wb1_legacy_write_valid_w)
        $error("[INT-WB1-WRITE-VALID-EQUIV] local=%b legacy=%b sources=%b @%0t",
               gpr_wb1_write_valid_w, gpr_wb1_legacy_write_valid_w,
               wb1_source_onehot_w, $time);
      if (muldiv_actual_claim_w &&
          (!muldiv_completion_rob_open_w || muldiv_same_edge_claimed_w ||
           muldiv_fp_pending_owned_w)) begin
        $error("[V8H-MULDIV-COMPLETION-AUTH] actual completion escaped exact-open/claim gate @%0t",
               $time);
        $fatal;
      end
      if ((clmul_wb0_valid_w || clmul_wb1_valid_w) &&
          (!clmul_completion_rob_open_w || clmul_same_edge_claimed_w ||
           clmul_fp_pending_owned_w)) begin
        $error("[V8H-CLMUL-COMPLETION-AUTH] actual completion escaped exact-open/claim gate @%0t",
               $time);
        $fatal;
      end
      if ((muldiv_resp_ready_w !==
           (muldiv_rsp_to_wb0_w || muldiv_rsp_to_wb1_w)) ||
          (clmul_resp_ready_w !==
           (clmul_rsp_to_wb0_w || clmul_rsp_to_wb1_w))) begin
        $error("[V8H-LONGOP-TRANSPORT-AUTH-SEPARATION] response ready diverged from raw route @%0t",
               $time);
        $fatal;
      end
      if (muldiv_actual_claim_w &&
          (clmul_wb0_valid_w || clmul_wb1_valid_w) &&
          (muldiv_resp_producer_id_w == clmul_resp_producer_id_w)) begin
        $error("[V8H-LONGOP-SAME-EDGE-CLAIM] MulDiv/CLMUL completed one PID twice @%0t",
               $time);
        $fatal;
      end
      if (muldiv_owner_valid_w &&
          !muldiv_owner_producer_live_mask_w[muldiv_owner_producer_id_w]) begin
        $error("[V8H-MULDIV-LEASE-DECODE] live holder missing from dispatch mask @%0t",
               $time);
        $fatal;
      end
      if (clmul_owner_valid_w &&
          !clmul_owner_producer_live_mask_w[clmul_owner_producer_id_w]) begin
        $error("[V8H-CLMUL-LEASE-DECODE] live holder missing from dispatch mask @%0t",
               $time);
        $fatal;
      end
      if (mem_actual_claim_w &&
          (!mem_completion_rob_open_w || mem_same_edge_claimed_w ||
           mem_fp_pending_owned_w)) begin
        $error("[V8I-MEM-COMPLETION-OWNER] memory bypassed exact/claim/pending fence @%0t",
               $time);
        $fatal;
      end
      if (mem1_actual_claim_w &&
          (!mem1_completion_rob_open_w || mem1_same_edge_claimed_w ||
           mem1_fp_pending_owned_w)) begin
        $error("[V8S-MEM1-COMPLETION-OWNER] bank1 memory bypassed exact/claim/pending fence @%0t",
               $time);
        $fatal;
      end
      if (mem_actual_claim_w && mem1_actual_claim_w &&
          (mem_completion_producer_id_w == mem1_completion_producer_id_w)) begin
        $error("[V8S-DUAL-MEM-SAME-EDGE-CLAIM] both banks completed one PID @%0t",
               $time);
        $fatal;
      end
      if (fpwb_actual_claim_w &&
          (!fp_formal_completion_rob_open_w || !fpwb_pending_owner_w ||
           fpwb_same_edge_claimed_w)) begin
        $error("[V8I-FP-FORMAL-AUTH] formal token bypassed exact owner/claim fence @%0t",
               $time);
        $fatal;
      end
      if (fp_result_authorized_w &&
          (!fp_result_completion_rob_open_w || fp_result_pending_owned_w ||
           fp_result_same_edge_claimed_w)) begin
        $error("[V8I-FP-RESULT-AUTH] result bypassed exact/pending/claim fence @%0t",
               $time);
        $fatal;
      end
      if ((fpwb_ready_w !== (fpwb_to_wb0_w || fpwb_to_wb1_w))) begin
        $error("[V8I-FP-FORMAL-TRANSPORT] raw ready read completion authority @%0t",
               $time);
        $fatal;
      end
      if ((fp_completion_pending_mask_w & ~fp_producer_live_mask_w) !=
          {(1 << PRODUCER_ID_W){1'b0}}) begin
        $error("[V8I-FP-PENDING-LEASE] completion owner missing from live mask @%0t",
               $time);
        $fatal;
      end
    end
  end
`endif

  assign execute0_valid_o = wb0_valid_w;
  assign execute1_valid_o = wb1_valid_w;
  // T3N：控制流只在 lane0 发射，raw resolve 不再经过 lane1 仲裁，也不再复用
  // generic issue-ready 的 LSU/SC/long-op 锥。完整 resolve packet 在这里打一拍；
  // redirect、BPU、ROB/IQ recovery、FP/long-op/MIQ/SQ kill 全部只消费同一 q 包，
  // 禁止 valid/rob_idx/payload 分拍。DispatchBackend 同时删除了旧 kill 再寄存，故
  // ROB/IQ kill 相对 issue 的总延迟仍为一拍。
  wire issue0_resolve_emit_w = issue0_ctrlflow_fire_w;
  wire [BRANCH_RESOLVE_PAYLOAD_W-1:0] branch_resolve_up_payload_w = {
      issue0_pc_w,
      issue0_ctrlflow_next_pc_w,
      issue0_ctrlflow_misaligned_w,
      iq_issue0_producer_id_w,
      issue0_mispredict_w,
      issue0_is_branch_w,
      issue0_branch_taken_w,
      issue0_pred_taken_w,
      issue0_bht_idx_w
  };
  wire branch_resolve_up_ready_unused_w;
  wire [BRANCH_RESOLVE_PAYLOAD_W-1:0] branch_resolve_down_payload_w;
  PipeStageReg #(.WIDTH(BRANCH_RESOLVE_PAYLOAD_W)) u_branch_resolve_stage (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_apply_w),
    .kill_i(1'b0),
    .up_valid_i(issue0_resolve_emit_w),
    .up_ready_o(branch_resolve_up_ready_unused_w),
    .up_payload_i(branch_resolve_up_payload_w),
    .down_valid_o(branch_resolve_stage_valid_w),
    .down_ready_i(1'b1),
    .down_payload_o(branch_resolve_down_payload_w)
  );
  wire [`XLEN-1:0] branch_resolve_payload_pc_w;
  wire [`XLEN-1:0] branch_resolve_payload_next_pc_w;
  wire branch_resolve_payload_misaligned_w;
  wire [ROB_INDEX_W-1:0] branch_resolve_payload_rob_idx_w =
      branch_resolve_payload_producer_id_w[ROB_INDEX_W-1:0];
  wire branch_resolve_payload_mispredict_w;
  wire branch_resolve_payload_is_branch_w;
  wire branch_resolve_payload_taken_w;
  wire branch_resolve_payload_pred_taken_w;
  wire [`BPU_BHT_INDEX_W-1:0] branch_resolve_payload_bht_idx_w;
  assign {
      branch_resolve_payload_pc_w,
      branch_resolve_payload_next_pc_w,
      branch_resolve_payload_misaligned_w,
      branch_resolve_payload_producer_id_w,
      branch_resolve_payload_mispredict_w,
      branch_resolve_payload_is_branch_w,
      branch_resolve_payload_taken_w,
      branch_resolve_payload_pred_taken_w,
      branch_resolve_payload_bht_idx_w
  } = branch_resolve_down_payload_w;

  // PipeStageReg 刻意在 invalid/flush 后保留 dirty payload；所有语义输出必须由
  // effective valid 掩护。flush/checkpoint_restore 同拍也立即压掉旧 q，不能等到
  // 上升沿才停止 redirect/BPU update/kill。
  wire branch_resolve_candidate_valid_w =
      branch_resolve_stage_valid_w && !rst && !flush_i &&
      !checkpoint_restore_hold_w;
  assign branch_resolve_query_valid_w = branch_resolve_candidate_valid_w;
  assign branch_resolve_query_producer_id_w =
      branch_resolve_payload_producer_id_w;
  // V8J RAW-EX0-ONLY: these are the physical registered holder outputs.  Do
  // not substitute ex0_pre_auth_valid_w, ex0_producer_open_w or ex0_wb_valid_w;
  // all of those enter the killed-now cone and would reconnect self-feedback.
  wire branch_resolve_raw_ex0_coherent_w =
      ex0_valid_q &&
      (branch_resolve_payload_producer_id_w == ex0_producer_id_q);
  wire branch_resolve_authorized_w =
      branch_resolve_candidate_valid_w && branch_resolve_rob_open_w &&
      branch_resolve_raw_ex0_coherent_w;
  assign branch_resolve_valid_o = branch_resolve_authorized_w;
  assign branch_resolve_pc_o = branch_resolve_authorized_w ?
                               branch_resolve_payload_pc_w : {`XLEN{1'b0}};
  assign branch_resolve_next_pc_o = branch_resolve_authorized_w ?
                                    branch_resolve_payload_next_pc_w :
                                    {`XLEN{1'b0}};
  assign branch_resolve_misaligned_o = branch_resolve_authorized_w &&
                                       branch_resolve_payload_misaligned_w;
  assign branch_resolve_rob_idx_o = branch_resolve_authorized_w ?
                                    branch_resolve_payload_rob_idx_w :
                                    {ROB_INDEX_W{1'b0}};
  assign branch_resolve_mispredict_w = branch_resolve_authorized_w &&
                                       branch_resolve_payload_mispredict_w;
  assign branch_resolve_is_branch_o = branch_resolve_authorized_w &&
                                      branch_resolve_payload_is_branch_w;
  assign branch_resolve_taken_o = branch_resolve_authorized_w &&
                                  branch_resolve_payload_taken_w;
  assign branch_resolve_pred_taken_o = branch_resolve_authorized_w &&
                                       branch_resolve_payload_pred_taken_w;
  assign branch_resolve_bht_idx_o = branch_resolve_authorized_w ?
                                    branch_resolve_payload_bht_idx_w :
                                    {`BPU_BHT_INDEX_W{1'b0}};
`ifdef OOO_ASSERT
  // resolve q 与 raw registered EX0 token 必须由同一次 lane0 control-flow
  // fire 同拍产生。Production logic fail-closes on mismatch; diagnostics
  // retain the stronger design invariant that a raw candidate must cohere.
  always @(posedge clk) begin
    if (!rst && branch_resolve_candidate_valid_w &&
        (!ex0_valid_q ||
         (branch_resolve_payload_producer_id_w != ex0_producer_id_q))) begin
      $error("[V8J-BRANCH-FULL-PID-COHERENT] raw resolve/ex0 mismatch: resolve_p=%0h ex0_valid=%b ex0_p=%0h @%0t",
             branch_resolve_payload_producer_id_w,
             ex0_valid_q, ex0_producer_id_q, $time);
    end
    if (branch_resolve_authorized_w &&
        (!branch_resolve_candidate_valid_w || !branch_resolve_rob_open_w ||
         !branch_resolve_raw_ex0_coherent_w)) begin
      $error("[V8J-BRANCH-RESOLVE-AUTH] capability escaped exact/raw-holder gate @%0t",
             $time);
    end
    if (branch_resolve_candidate_valid_w &&
        (!branch_resolve_rob_open_w ||
         !branch_resolve_raw_ex0_coherent_w) &&
        (branch_resolve_valid_o || (|branch_resolve_pc_o) ||
         (|branch_resolve_next_pc_o) || branch_resolve_misaligned_o ||
         (|branch_resolve_rob_idx_o) || branch_resolve_mispredict_w ||
         branch_resolve_is_branch_o || branch_resolve_taken_o ||
         branch_resolve_pred_taken_o || (|branch_resolve_bht_idx_o))) begin
      $error("[V8J-BRANCH-STALE-SILENT] unauthorized candidate exposed semantics @%0t",
             $time);
    end
    if (branch_resolve_authorized_w &&
        (branch_resolve_rob_idx_o !=
         branch_resolve_payload_producer_id_w[ROB_INDEX_W-1:0])) begin
      $error("[V8J-BRANCH-PID-PROJECTION] raw boundary is not P.index @%0t",
             $time);
    end
    if (!rst && branch_resolve_stage_valid_w &&
        (flush_i || checkpoint_restore_hold_w) &&
        (branch_resolve_valid_o || (|branch_resolve_pc_o) ||
         (|branch_resolve_next_pc_o) || branch_resolve_misaligned_o ||
         (|branch_resolve_rob_idx_o) || branch_resolve_mispredict_w ||
         branch_resolve_is_branch_o || branch_resolve_taken_o ||
         branch_resolve_pred_taken_o || (|branch_resolve_bht_idx_o))) begin
      $error("[INT-RESOLVE-CANCEL-MASK] cancel exposed staged resolve payload @%0t",
             $time);
    end
  end
`endif
`ifdef DBRA_PROBE
  always @(posedge clk) begin
    if (branch_resolve_valid_o)
      $display("[BRP ] pc=%h next=%h mis=%b rob=%h",
               branch_resolve_pc_o, branch_resolve_next_pc_o,
               branch_resolve_mispredict_w, branch_resolve_rob_idx_o);
  end
`endif
  assign branch_resolve_mispredict_o = branch_resolve_mispredict_w;
  // Wave4b: dispatch 拍分支快解析族已物理删除；输出恒 0 tie-off。跨模块消费者
  // (OooDirectBranchResolveGate 的 dispatch 臂、OooCommitOutputMux 的 synth-append) 在
  // domain-A 下本就只见 0，保持既有 0 语义，行为中性。
  assign dispatch_branch_resolve_valid_o = 1'b0;
  assign dispatch_branch_resolve_pc_o = {`XLEN{1'b0}};
  assign dispatch_branch_resolve_next_pc_o = {`XLEN{1'b0}};
  assign dispatch_branch_resolve_misaligned_o = 1'b0;

  // dispatch backend 的 load_branch_fast_* 输出族已物理删除（IQ 死硅摘除）；
  // 仅存 pending_branch_fast_* 输入（另一未删死硅族）悬空，reduction-OR 收口。
  wire unused_pending_branch_fast_w =
      pending_branch_fast_valid_i |
      (|pending_branch_fast_pc_i);

  wire unused_issue_payload_w =
      (|issue0_inst_w) | (|issue1_inst_w) |
      (|issue0_mem_load_unused_w) | (|issue1_mem_load_unused_w) |
      mem_store_q | mem_rsp_to_wb0_w |
      (|mem_rsp_addr_unused_w) | (|mem_rsp_wdata_unused_w) |
      (|mem_rsp_wstrb_unused_w) | mem_rsp_misaligned_unused_w |
      // Wave4b: dispatch0_src2 preg/ready 原仅喂 dispatch 拍分支快解析（已删）→ reduction-OR 收口。
      (|dispatch0_src2_preg_w) | dispatch0_src2_ready_w;

`ifdef ROB_WALK_DEBUG
  always @(posedge clk) begin
    if (!rst && branch_resolve_valid_o)
      $display("[CF] staged mispred=%b br=%b rob=%0d pc=%h next=%h",
               branch_resolve_mispredict_w, branch_resolve_is_branch_o,
               branch_resolve_rob_idx_o, branch_resolve_pc_o,
               branch_resolve_next_pc_o);
  end
`endif


  // ===========================================================================
  // 【B-FP 簇】FP 后端一体实例(spec ooo-fp-cluster §7): rename/IQ/物理堆/执行簇/
  // 完成 FIFO。FP load 写回=mem rsp 分流(box 后), FP store 数据=发射拍 R3 读。
  // ===========================================================================
  wire mem_fpld_wb_valid_w = mem_actual_claim_w && mem_rsp_fp_load_w &&
      !mem_rsp_error_i && !mem_rsp_page_fault_i;
  wire mem1_fpld_wb_valid_w = mem1_actual_claim_w &&
      mem1_rsp_fp_load_w && !mem1_rsp_error_i &&
      !mem1_rsp_page_fault_i;
  wire fpld_wb_valid_w = mem_fpld_wb_valid_w || mem1_fpld_wb_valid_w;
  wire [PHY_REG_ADDR_W-1:0] fpld_wb_pdest_w =
      mem1_fpld_wb_valid_w ? miq1_head_pdest_w : miq_head_pdest_w;
  wire [`XLEN-1:0] fpld_wb_data_w = mem1_fpld_wb_valid_w ?
      mem1_rsp_fp_boxed_w : mem_rsp_fp_boxed_w;

  OooFpBackend #(
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) u_fp_backend (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i || checkpoint_restore_apply_w),
    .frm_i(frm_i),
    .kill_valid_i(branch_resolve_mispredict_w),
    .kill_rob_idx_i(branch_resolve_rob_idx_o),
    .rob_head_idx_i(rob_head_idx_w),
    .recover_active_i(rob_recover_active_w),
    .dispatch0_accept_i(dispatch0_fire_w),
    .dispatch1_accept_i(dispatch1_fire_w),
    .walk0_fp_valid_i(walk0_fp_valid_w),
    .walk0_arch_i(walk0_fp_arch_w),
    .walk0_old_pdest_i(walk0_fp_old_w),
    .walk0_new_pdest_i(walk0_fp_new_w),
    .walk1_fp_valid_i(walk1_fp_valid_w),
    .walk1_arch_i(walk1_fp_arch_w),
    .walk1_old_pdest_i(walk1_fp_old_w),
    .walk1_new_pdest_i(walk1_fp_new_w),
    .disp_valid_i(d0_fp_arith_w),
    .disp_ready_o(fp_disp_ready_w),
    .disp_producer_id_i(dispatch0_producer_id_w),
    .disp_inst_i(dispatch0_inst_i),
    .disp_double_i(dispatch0_fp_double_i),
    .disp_frd_en_i(!dispatch0_fp_gpr_write_i),
    .disp_frd_arch_i(dispatch0_inst_i[11:7]),
    .disp_dst_gpr_i(dispatch0_fp_gpr_write_i),
    .disp_gpr_pdest_i(dispatch0_pdest_w),
    .disp_fs1_en_i(dispatch0_fp_fs1_en_i),
    .disp_fs1_arch_i(dispatch0_inst_i[19:15]),
    .disp_fs2_en_i(dispatch0_fp_fs2_en_i),
    .disp_fs2_arch_i(dispatch0_inst_i[24:20]),
    .disp_fs3_en_i(dispatch0_fp_fs3_en_i),
    .disp_fs3_arch_i(dispatch0_inst_i[31:27]),
    .disp_gpr_src_en_i(dispatch0_fp_gpr_src_i),
    .disp_gpr_src_preg_i(dispatch0_src1_preg_w),
    .disp_gpr_src_ready_i(dispatch0_src1_ready_w),
    .disp_frd_new_pdest_o(fp_disp_new_pdest_w),
    .disp_frd_old_pdest_o(fp_disp_old_pdest_w),
    .disp1_valid_i(d1_fp_arith_w),
    .disp1_ready_o(fp_disp1_ready_w),
    .disp1_producer_id_i(dispatch1_producer_id_w),
    .disp1_inst_i(dispatch1_inst_i),
    .disp1_double_i(dispatch1_fp_double_i),
    .disp1_frd_en_i(!dispatch1_fp_gpr_write_i),
    .disp1_frd_arch_i(dispatch1_inst_i[11:7]),
    .disp1_dst_gpr_i(dispatch1_fp_gpr_write_i),
    .disp1_gpr_pdest_i(dispatch1_new_pdest_probe_w),
    .disp1_fs1_en_i(dispatch1_fp_fs1_en_i),
    .disp1_fs1_arch_i(dispatch1_inst_i[19:15]),
    .disp1_fs2_en_i(dispatch1_fp_fs2_en_i),
    .disp1_fs2_arch_i(dispatch1_inst_i[24:20]),
    .disp1_fs3_en_i(dispatch1_fp_fs3_en_i),
    .disp1_fs3_arch_i(dispatch1_inst_i[31:27]),
    .disp1_gpr_src_en_i(dispatch1_fp_gpr_src_i),
    .disp1_gpr_src_preg_i(dispatch1_src1_preg_w),
    .disp1_gpr_src_ready_i(dispatch1_src1_ready_w),
    .disp1_frd_new_pdest_o(fp_disp1_new_pdest_w),
    .disp1_frd_old_pdest_o(fp_disp1_old_pdest_w),
    .fpld0_alloc_valid_i(dispatch0_is_fp_i && dispatch0_fp_load_i),
    .fpld0_alloc_arch_i(dispatch0_inst_i[11:7]),
    .fpld0_new_pdest_o(fpld0_new_pdest_w),
    .fpld0_old_pdest_o(fpld0_old_pdest_w),
    .fpld1_alloc_valid_i(dispatch1_is_fp_i && dispatch1_fp_load_i),
    .fpld1_alloc_arch_i(dispatch1_inst_i[11:7]),
    .fpld1_new_pdest_o(fpld1_new_pdest_w),
    .fpld1_old_pdest_o(fpld1_old_pdest_w),
    .fp_alloc0_ready_o(fp_alloc0_ready_w),
    .fp_alloc1_ready_o(fp_alloc1_ready_w),
    .fpst0_query_arch_i(dispatch0_inst_i[24:20]),
    .fpst0_query_preg_o(fpst0_query_preg_w),
    .fpst0_query_ready_o(fpst0_query_ready_w),
    .fpst1_query_arch_i(dispatch1_inst_i[24:20]),
    .fpst1_query_preg_o(fpst1_query_preg_w),
    .fpst1_query_ready_o(fpst1_query_ready_w),
    .fp_wake0_valid_o(fp_wake0_valid_w),
    .fp_wake0_preg_o(fp_wake0_preg_w),
    .fp_wake1_valid_o(fp_wake1_valid_w),
    .fp_wake1_preg_o(fp_wake1_preg_w),
    .fpst_read_preg_i(fpst_read_preg_w),
    .fpst_read_data_o(fpst_read_data_w),
    .fpld_wb_valid_i(fpld_wb_valid_w),
    .fpld_wb_pdest_i(fpld_wb_pdest_w),
    .fpld_wb_data_i(fpld_wb_data_w),
    .fpld_wb_double_i(1'b1),
    .int_wake0_valid_i(gpr_wb0_write_valid_w),
    .int_wake0_preg_i(wb0_pdest_w),
    .int_wake1_valid_i(gpr_wb1_write_valid_w),
    .int_wake1_preg_i(wb1_pdest_w),
    .gpr_read_addr_o(fp_gpr_read_addr_w),
    .gpr_read_data_i(fp_gpr_read_data_w),
    .fpwb_valid_o(fpwb_valid_w),
    .fpwb_producer_id_o(fpwb_producer_id_w),
    .fpwb_rob_idx_o(fpwb_rob_idx_w),
    .fpwb_pdest_o(fpwb_pdest_w),
    .fpwb_rd_en_o(fpwb_rd_en_w),
    .fpwb_data_o(fpwb_data_w),
    .fpwb_fflags_o(fpwb_fflags_w),
    .fpwb_ready_i(fpwb_ready_w),
    .result_query_valid_o(fp_result_query_valid_w),
    .result_query_producer_id_o(fp_result_query_producer_id_w),
    .result_authorized_i(fp_result_authorized_w),
    .completion_pending_mask_o(fp_completion_pending_mask_w),
    .producer_live_mask_o(fp_producer_live_mask_w),
    .commit0_fp_valid_i(commit0_valid_o && commit0_is_fp_rd_w &&
                        !commit0_exception_o),
    .commit0_fp_arch_i(commit0_arch_rd_o),
    .commit0_fp_data_i(commit0_data_o),
    .commit0_fp_old_pdest_i(commit0_old_pdest_o),
    .commit1_fp_valid_i(commit1_valid_o && commit1_is_fp_rd_w &&
                        !commit1_exception_o),
    .commit1_fp_arch_i(commit1_arch_rd_o),
    .commit1_fp_data_i(commit1_data_o),
    .commit1_fp_old_pdest_i(commit1_old_pdest_o)
  );


  // ===========================================================================
  // 【T4N·SQ 精确 late-B 接线】
  // mode=1: probe success 只填 VA/PA/data；physical head==ROB head 时发一次
  // pretrans+nokill 写；B 取得 formal WB credit 后形成唯一 terminal WB；ROB
  // commit 最后释放。mode=0 保留影子 fill，但真实写 response 仍作为 terminal。
  // store 判定含 FP store(FSW/FSD opcode 0100111)——FP store 同走 SQ 生命周期
  wire lq_d0_load_w = dispatch0_fire_w &&
      dispatch0_ctrl_i[`CTRL_LOAD_BIT] &&
      !dispatch0_ctrl_i[`CTRL_AMO_BIT];
  wire lq_d1_load_w = dispatch1_fire_w &&
      dispatch1_ctrl_i[`CTRL_LOAD_BIT] &&
      !dispatch1_ctrl_i[`CTRL_AMO_BIT];
  assign lq_alloc0_valid_w = lq_d0_load_w || lq_d1_load_w;
  assign lq_alloc0_rob_w = lq_d0_load_w ? dispatch0_rob_idx_w :
                                                dispatch1_rob_idx_w;
  assign lq_alloc0_producer_id_w = lq_d0_load_w ?
      dispatch0_producer_id_w : dispatch1_producer_id_w;
  assign lq_alloc1_valid_w = lq_d0_load_w && lq_d1_load_w;

  wire sq_d0_store_w =
      dispatch0_fire_w && ((dispatch0_inst_i[6:0] == 7'b0100011) ||
       ((dispatch0_inst_i[6:0] == 7'b0100111) &&
        ((dispatch0_inst_i[14:12] == 3'b010) || (dispatch0_inst_i[14:12] == 3'b011))));
  wire sq_d1_store_w =
      dispatch1_fire_w && ((dispatch1_inst_i[6:0] == 7'b0100011) ||
       ((dispatch1_inst_i[6:0] == 7'b0100111) &&
        ((dispatch1_inst_i[14:12] == 3'b010) || (dispatch1_inst_i[14:12] == 3'b011))));
  wire sq_alloc0_valid_w = sq_d0_store_w || sq_d1_store_w;
  wire [ROB_INDEX_W-1:0] sq_alloc0_rob_w =
      sq_d0_store_w ? dispatch0_rob_idx_w : dispatch1_rob_idx_w;
  wire [PRODUCER_ID_W-1:0] sq_alloc0_producer_id_w =
      sq_d0_store_w ? dispatch0_producer_id_w : dispatch1_producer_id_w;
  wire sq_alloc1_valid_w = sq_d0_store_w && sq_d1_store_w;
  wire sq_owner_bind_valid_w = mem_issue_res_capture_w &&
      (mem_owner_kind_from_ctrl(iq_issue0_ctrl_w) == MEM_OWNER_STORE);
  wire sq_owner_bind1_valid_w = mem_issue1_res_capture_w &&
      (mem_owner_kind_from_ctrl(issue1_ctrl_w) == MEM_OWNER_STORE);

  // 回填: mode=1 在 probe rsp 拍(PA=rsp_rdata + 发射拍寄存的 data/strb);
  // mode=0 影子在发射拍(VA; req 直入/req lane1/buffer 暂存三路同拍互斥)。
  // AMO/SC/FP-store 未 alloc, CAM miss 自然忽略。
  wire sq_fill_probe_w =
      miq_probe_rsp_fire_w && mem_owner_open_w &&
      !mem_rsp_error_i && !mem_rsp_page_fault_i;
  wire sq_fill1_probe_w = ENABLE_DUAL_MEM &&
      miq1_probe_rsp_fire_w && mem1_owner_open_w &&
      !mem1_rsp_error_i && !mem1_rsp_page_fault_i;
  wire shadow_fill_req0_w = issue0_mem_request_fire_w && issue0_is_store_w;
  wire shadow_fill_req1_w = issue1_mem_request_fire_w && issue1_is_store_w;
  wire shadow_fill_buf0_w = issue0_mem_buffer_fire_w && issue0_is_store_w;
  wire shadow_fill_buf1_w = issue1_mem_buffer_fire_w && issue1_is_store_w;
  wire shadow_fill_issue0_w = shadow_fill_req0_w || shadow_fill_buf0_w;
  wire shadow_fill_issue1_w = shadow_fill_req1_w || shadow_fill_buf1_w;
  wire shadow_fill_from1_w = ENABLE_DUAL_MEM ?
      (!shadow_fill_issue0_w && shadow_fill_issue1_w) :
      shadow_fill_issue1_w;
  wire shadow_fill_valid_w =
      shadow_fill_issue0_w || shadow_fill_issue1_w;
  wire shadow_fill1_valid_w = ENABLE_DUAL_MEM &&
      shadow_fill_issue0_w && shadow_fill_issue1_w;
  wire [ROB_INDEX_W-1:0] shadow_fill_rob_w =
      shadow_fill_from1_w ? mem_issue1_res_rob_idx_q :
                            mem_issue_res_rob_idx_q;
  wire [`XLEN-1:0] shadow_fill_addr_w =
      shadow_fill_from1_w ? mem_issue1_res_eff_addr_w :
                            mem_issue_res_eff_addr_w;
  wire [`XLEN-1:0] shadow_fill_data_w =
      shadow_fill_from1_w ? issue1_mem_wdata_w : issue0_mem_wdata_w;
  wire [`STRB_W-1:0] shadow_fill_strb_w =
      shadow_fill_from1_w ? issue1_mem_wstrb_w : issue0_mem_wstrb_w;
  wire mem_rsp_attr_admitted_w =
      typed_mem_attr_admitted(mem_rsp_attr_valid_i, mem_rsp_class_i);
  wire mem1_rsp_attr_admitted_w =
      typed_mem_attr_admitted(mem1_rsp_attr_valid_i, mem1_rsp_class_i);
  wire sq_fill_valid_w =
      sq_mode_w ? sq_fill_probe_w : shadow_fill_valid_w;
  wire [ROB_INDEX_W-1:0] sq_fill_rob_w =
      sq_mode_w ? miq_head_rob_w : shadow_fill_rob_w;
  wire [`XLEN-1:0] sq_fill_vaddr_w =
      sq_mode_w ? miq_head_addr_w : shadow_fill_addr_w;
  wire [`XLEN-1:0] sq_fill_paddr_w =
      sq_mode_w ? mem_rsp_rdata_i : shadow_fill_addr_w;
  // Probe response provenance is copied verbatim into SQ.  Shadow mode has no
  // translated class owner and therefore stays invalid/RSVD; no address-based
  // fallback is permitted.
  wire sq_fill_attr_valid_w = sq_mode_w && mem_rsp_attr_admitted_w;
  wire [1:0] sq_fill_class_w = sq_fill_attr_valid_w ? mem_rsp_class_i :
                                                       `OOO_MEM_CLASS_RSVD;
  wire sq_fill_cacheable_w = sq_fill_attr_valid_w &&
      (sq_fill_class_w == `OOO_MEM_CLASS_CACHED);
  wire [`XLEN-1:0] sq_fill_data_w =
      sq_mode_w ? miq_head_wdata_w : shadow_fill_data_w;
  wire [`STRB_W-1:0] sq_fill_strb_w =
      sq_mode_w ? miq_head_wstrb_w : shadow_fill_strb_w;
  wire [1:0] sq_fill_owner_kind_w = sq_mode_w ?
      miq_head_owner_kind_w :
      (shadow_fill_from1_w ? mem_issue1_res_owner_kind_q :
                             mem_issue_res_owner_kind_q);
  wire [4:0] sq_fill_owner_token_w = sq_mode_w ?
      miq_head_owner_token_w :
      (shadow_fill_from1_w ? mem_issue1_res_owner_token_q :
                             mem_issue_res_owner_token_q);
  wire [1:0] sq_fill_mmu_epoch_w = sq_mode_w ?
      miq_head_mmu_epoch_w :
      (shadow_fill_from1_w ? mem_issue1_res_mmu_epoch_q :
                             mem_issue_res_mmu_epoch_q);
  wire [`XLEN-1:0] sq_fill_fault_tval_w = sq_mode_w ?
      miq_head_fault_tval_w :
      (shadow_fill_from1_w ? mem_issue1_res_fault_tval_q :
                             mem_issue_res_fault_tval_q);
  wire sq_fill1_valid_w = sq_mode_w ? sq_fill1_probe_w :
      shadow_fill1_valid_w;
  wire [ROB_INDEX_W-1:0] sq_fill1_rob_w = sq_mode_w ?
      miq1_head_rob_w : mem_issue1_res_rob_idx_q;
  wire [`XLEN-1:0] sq_fill1_vaddr_w = sq_mode_w ?
      miq1_head_addr_w : mem_issue1_res_eff_addr_w;
  wire [`XLEN-1:0] sq_fill1_paddr_w = sq_mode_w ?
      mem1_rsp_rdata_i : mem_issue1_res_eff_addr_w;
  wire sq_fill1_attr_valid_w = sq_mode_w && mem1_rsp_attr_admitted_w;
  wire [1:0] sq_fill1_class_w = sq_fill1_attr_valid_w ?
      mem1_rsp_class_i : `OOO_MEM_CLASS_RSVD;
  wire sq_fill1_cacheable_w = sq_fill1_attr_valid_w &&
      (sq_fill1_class_w == `OOO_MEM_CLASS_CACHED);
  wire [`XLEN-1:0] sq_fill1_data_w = sq_mode_w ?
      miq1_head_wdata_w : issue1_mem_wdata_w;
  wire [`STRB_W-1:0] sq_fill1_strb_w = sq_mode_w ?
      miq1_head_wstrb_w : issue1_mem_wstrb_w;
  wire [1:0] sq_fill1_owner_kind_w = sq_mode_w ?
      miq1_head_owner_kind_w : mem_issue1_res_owner_kind_q;
  wire [4:0] sq_fill1_owner_token_w = sq_mode_w ?
      miq1_head_owner_token_w : mem_issue1_res_owner_token_q;
  wire [1:0] sq_fill1_mmu_epoch_w = sq_mode_w ?
      miq1_head_mmu_epoch_w : mem_issue1_res_mmu_epoch_q;
  wire [`XLEN-1:0] sq_fill1_fault_tval_w = sq_mode_w ?
      miq1_head_fault_tval_w : mem_issue1_res_fault_tval_q;

  // Store terminal is a local plain-store exception, a probe fault (no write
  // was sent), or the actual B response.  Successful probe is intentionally
  // absent。local exception 使用 reservation Q 的 ROB tag，覆盖 SD/FSW/FSD
  // translated page-end path，使 commit0 可在不发请求的情况下释放 SQ owner。
  assign sq_local_store_exception0_w =
      (ENABLE_DUAL_MEM ? mem_issue_res_dual_local_consume_w :
                         mem_issue_res_consume_fire_w) &&
      issue0_is_plain_store_w && issue0_mem_exception_w;
  assign sq_local_store_exception1_w =
      (ENABLE_DUAL_MEM ? mem_issue1_res_dual_local_consume_w :
                         mem_issue1_res_consume_fire_w) &&
      issue1_is_plain_store_w && issue1_mem_exception_w;
  wire sq_local_store_exception_w = sq_local_store_exception0_w ||
                                    sq_local_store_exception1_w;
  wire [ROB_INDEX_W-1:0] sq_local_store_exception_rob_w =
      sq_local_store_exception1_w ? mem_issue1_res_rob_idx_q :
                                    mem_issue_res_rob_idx_q;
  wire [1:0] sq_local_store_exception_kind_w =
      sq_local_store_exception1_w ? mem_issue1_res_owner_kind_q :
                                    mem_issue_res_owner_kind_q;
  wire [4:0] sq_local_store_exception_token_w =
      sq_local_store_exception1_w ? mem_issue1_res_owner_token_q :
                                    mem_issue_res_owner_token_q;
  wire [1:0] sq_local_store_exception_epoch_w =
      sq_local_store_exception1_w ? mem_issue1_res_mmu_epoch_q :
                                    mem_issue_res_mmu_epoch_q;
  wire [`XLEN-1:0] sq_local_store_exception_tval_w =
      sq_local_store_exception1_w ? mem_issue1_res_fault_tval_q :
                                    mem_issue_res_fault_tval_q;
  wire sq_probe_terminal_w =
      miq_probe_rsp_fire_w && mem_owner_open_w &&
      (mem_rsp_fault_w || !sq_mode_w);
  wire sq_response_terminal_w = sq_probe_terminal_w ||
      (miq_drain_rsp_fire_w && mem_owner_open_w);
  wire sq_response1_terminal_w =
      miq1_probe_rsp_fire_w && mem1_owner_open_w &&
      (mem1_rsp_fault_w || !sq_mode_w);

  // Stable priority mapping onto the two physical SQ terminal ports:
  // local0 > local1 > response0 > response1.  READY has already guaranteed
  // that every response which fires owns one of these two slots.
  wire sq_terminal0_local0_w = sq_local_store_exception0_w;
  wire sq_terminal0_local1_w = !sq_terminal0_local0_w &&
      sq_local_store_exception1_w;
  wire sq_terminal0_rsp0_w = !sq_terminal0_local0_w &&
      !sq_terminal0_local1_w && sq_response_terminal_w;
  wire sq_terminal0_rsp1_w = !sq_terminal0_local0_w &&
      !sq_terminal0_local1_w && !sq_terminal0_rsp0_w &&
      sq_response1_terminal_w;
  wire sq_terminal1_local1_w = sq_local_store_exception0_w &&
      sq_local_store_exception1_w;
  wire sq_terminal1_rsp0_w = sq_response_terminal_w &&
      (sq_local_store_exception0_w || sq_local_store_exception1_w);
  wire sq_terminal1_rsp1_w = sq_response1_terminal_w &&
      (sq_local_store_exception0_w || sq_local_store_exception1_w ||
       sq_response_terminal_w);
  wire sq_terminal0_valid_w = sq_terminal0_local0_w ||
      sq_terminal0_local1_w || sq_terminal0_rsp0_w || sq_terminal0_rsp1_w;
  wire sq_terminal1_valid_w = sq_terminal1_local1_w ||
      sq_terminal1_rsp0_w || sq_terminal1_rsp1_w;
  wire [ROB_INDEX_W-1:0] sq_terminal0_rob_w =
      sq_terminal0_local0_w ? mem_issue_res_rob_idx_q :
      sq_terminal0_local1_w ? mem_issue1_res_rob_idx_q :
      sq_terminal0_rsp0_w ? miq_head_rob_w : miq1_head_rob_w;
  wire [1:0] sq_terminal0_kind_w =
      sq_terminal0_local0_w ? mem_issue_res_owner_kind_q :
      sq_terminal0_local1_w ? mem_issue1_res_owner_kind_q :
      sq_terminal0_rsp0_w ? miq_head_owner_kind_w :
                            miq1_head_owner_kind_w;
  wire [4:0] sq_terminal0_token_w =
      sq_terminal0_local0_w ? mem_issue_res_owner_token_q :
      sq_terminal0_local1_w ? mem_issue1_res_owner_token_q :
      sq_terminal0_rsp0_w ? miq_head_owner_token_w :
                            miq1_head_owner_token_w;
  wire [1:0] sq_terminal0_epoch_w =
      sq_terminal0_local0_w ? mem_issue_res_mmu_epoch_q :
      sq_terminal0_local1_w ? mem_issue1_res_mmu_epoch_q :
      sq_terminal0_rsp0_w ? miq_head_mmu_epoch_w :
                            miq1_head_mmu_epoch_w;
  wire [`XLEN-1:0] sq_terminal0_tval_w =
      sq_terminal0_local0_w ? mem_issue_res_fault_tval_q :
      sq_terminal0_local1_w ? mem_issue1_res_fault_tval_q :
      sq_terminal0_rsp0_w ? miq_head_fault_tval_w :
                            miq1_head_fault_tval_w;
  wire [ROB_INDEX_W-1:0] sq_terminal1_rob_w =
      sq_terminal1_local1_w ? mem_issue1_res_rob_idx_q :
      sq_terminal1_rsp0_w ? miq_head_rob_w : miq1_head_rob_w;
  wire [1:0] sq_terminal1_kind_w =
      sq_terminal1_local1_w ? mem_issue1_res_owner_kind_q :
      sq_terminal1_rsp0_w ? miq_head_owner_kind_w :
                            miq1_head_owner_kind_w;
  wire [4:0] sq_terminal1_token_w =
      sq_terminal1_local1_w ? mem_issue1_res_owner_token_q :
      sq_terminal1_rsp0_w ? miq_head_owner_token_w :
                            miq1_head_owner_token_w;
  wire [1:0] sq_terminal1_epoch_w =
      sq_terminal1_local1_w ? mem_issue1_res_mmu_epoch_q :
      sq_terminal1_rsp0_w ? miq_head_mmu_epoch_w :
                            miq1_head_mmu_epoch_w;
  wire [`XLEN-1:0] sq_terminal1_tval_w =
      sq_terminal1_local1_w ? mem_issue1_res_fault_tval_q :
      sq_terminal1_rsp0_w ? miq_head_fault_tval_w :
                            miq1_head_fault_tval_w;
  // Compatibility observation is an OR only; release checks below compare
  // both concrete terminal ports and never compress their identities.
  wire sq_terminal_valid_w = sq_terminal0_valid_w || sq_terminal1_valid_w;
  wire [ROB_INDEX_W-1:0] sq_terminal_rob_w = sq_terminal0_rob_w;

  // A successful physical store cannot be lane1 commit: it was not allowed to
  // issue until it became ROB head.  Probe-fault stores follow the same single
  // release port so exception ordering cannot bypass physical SQ order.
  wire sq_release_valid_w =
      commit0_valid_o && ((commit0_inst_o[6:0] == 7'b0100011) ||
       ((commit0_inst_o[6:0] == 7'b0100111) &&
        ((commit0_inst_o[14:12] == 3'b010) || (commit0_inst_o[14:12] == 3'b011))));
  wire [ROB_INDEX_W-1:0] sq_release_rob_w = rob_head_idx_w;
  wire sq_commit1_store_w =
      commit1_valid_o && ((commit1_inst_o[6:0] == 7'b0100011) ||
       ((commit1_inst_o[6:0] == 7'b0100111) &&
        ((commit1_inst_o[14:12] == 3'b010) || (commit1_inst_o[14:12] == 3'b011))));

  // squash: flush/checkpoint restore 与 ROB/rename 同域全清；已发射 store
  // 仍由 SQ request_sent tombstone 等待精确 B terminal。mispredict 只清
  // wrap-safe younger suffix。
  wire sq_flush_valid_w = flush_i || checkpoint_restore_apply_w ||
      branch_resolve_mispredict_w;

  // B response clears only the bridge-inflight bit.  SQ ownership persists until
  // the separate release event above.
  wire sq_drain_rsp_fire_w = miq_drain_rsp_fire_w;
  wire sq_release_ready_w;
  wire sq_release_fire_w;

  always @(posedge clk) begin
    if (rst) begin
      drain_inflight_q <= 1'b0;
    end else if (sq_drain_req_fire_w) begin
      drain_inflight_q <= 1'b1;
    end else if (sq_drain_rsp_fire_w) begin
      drain_inflight_q <= 1'b0;
    end
  end

  OooStoreQueue #(
    .ENTRY_COUNT_W(SQ_ENTRY_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_store_queue (
    .clk(clk),
    .rst(rst),
    .flush_valid_i(sq_flush_valid_w),
    .flush_all_i(flush_i || checkpoint_restore_apply_w),
    .flush_rob_head_i(rob_head_idx_w),
    .flush_boundary_rob_i(branch_resolve_rob_idx_o),
    .rob_head_valid_i(rob_head_valid_w),
    .rob_head_idx_i(rob_head_idx_w),
    .rob_head_producer_id_i(rob_head_producer_id_w),
    .rob_head_launch_open_i(rob_head_launch_open_w),
    .alloc0_valid_i(sq_alloc0_valid_w),
    .alloc0_ready_o(sq_alloc0_ready_w),
    .alloc0_rob_idx_i(sq_alloc0_rob_w),
    .alloc0_producer_id_i(sq_alloc0_producer_id_w),
    .alloc1_valid_i(sq_alloc1_valid_w),
    .alloc1_ready_o(sq_alloc1_ready_w),
    .alloc1_rob_idx_i(dispatch1_rob_idx_w),
    .alloc1_producer_id_i(dispatch1_producer_id_w),
    .owner_bind_valid_i(sq_owner_bind_valid_w),
    .owner_bind_rob_idx_i(iq_issue0_rob_idx_w),
    .owner_bind_producer_id_i(iq_issue0_producer_id_w),
    .owner_bind_kind_i(mem_owner_kind_from_ctrl(iq_issue0_ctrl_w)),
    .owner_bind_token_i(mem_owner_alloc0_token_w),
    .owner_bind_mmu_epoch_i(MEM_OWNER_EPOCH_BASE),
    .owner_bind_fault_tval_i(issue0_src1_data_w + iq_issue0_imm_w),
    .owner_bind1_valid_i(sq_owner_bind1_valid_w),
    .owner_bind1_rob_idx_i(issue1_rob_idx_w),
    .owner_bind1_producer_id_i(issue1_producer_id_w),
    .owner_bind1_kind_i(mem_owner_kind_from_ctrl(issue1_ctrl_w)),
    .owner_bind1_token_i(mem_owner_alloc1_token_w),
    .owner_bind1_mmu_epoch_i(MEM_OWNER_EPOCH_BASE),
    .owner_bind1_fault_tval_i(issue1_src1_value_w + issue1_imm_w),
    .fill0_valid_i(sq_fill_valid_w),
    .fill0_rob_idx_i(sq_fill_rob_w),
    .fill0_owner_kind_i(sq_fill_owner_kind_w),
    .fill0_owner_token_i(sq_fill_owner_token_w),
    .fill0_mmu_epoch_i(sq_fill_mmu_epoch_w),
    .fill0_fault_tval_i(sq_fill_fault_tval_w),
    .fill0_vaddr_i(sq_fill_vaddr_w),
    .fill0_paddr_i(sq_fill_paddr_w),
    .fill0_attr_valid_i(sq_fill_attr_valid_w),
    .fill0_class_i(sq_fill_class_w),
    .fill0_cacheable_i(sq_fill_cacheable_w),
    .fill0_data_i(sq_fill_data_w),
    .fill0_strb_i(sq_fill_strb_w),
    .fill1_valid_i(sq_fill1_valid_w),
    .fill1_rob_idx_i(sq_fill1_rob_w),
    .fill1_owner_kind_i(sq_fill1_owner_kind_w),
    .fill1_owner_token_i(sq_fill1_owner_token_w),
    .fill1_mmu_epoch_i(sq_fill1_mmu_epoch_w),
    .fill1_fault_tval_i(sq_fill1_fault_tval_w),
    .fill1_vaddr_i(sq_fill1_vaddr_w),
    .fill1_paddr_i(sq_fill1_paddr_w),
    .fill1_attr_valid_i(sq_fill1_attr_valid_w),
    .fill1_class_i(sq_fill1_class_w),
    .fill1_cacheable_i(sq_fill1_cacheable_w),
    .fill1_data_i(sq_fill1_data_w),
    .fill1_strb_i(sq_fill1_strb_w),
    .terminal_valid_i(sq_terminal0_valid_w),
    .terminal_rob_idx_i(sq_terminal0_rob_w),
    .terminal_owner_kind_i(sq_terminal0_kind_w),
    .terminal_owner_token_i(sq_terminal0_token_w),
    .terminal_mmu_epoch_i(sq_terminal0_epoch_w),
    .terminal_fault_tval_i(sq_terminal0_tval_w),
    .terminal1_valid_i(sq_terminal1_valid_w),
    .terminal1_rob_idx_i(sq_terminal1_rob_w),
    .terminal1_owner_kind_i(sq_terminal1_kind_w),
    .terminal1_owner_token_i(sq_terminal1_token_w),
    .terminal1_mmu_epoch_i(sq_terminal1_epoch_w),
    .terminal1_fault_tval_i(sq_terminal1_tval_w),
    .release_valid_i(sq_release_valid_w),
    .release_rob_idx_i(sq_release_rob_w),
    .release_producer_id_i(rob_head_producer_id_w),
    .release_ready_o(sq_release_ready_w),
    .release_fire_o(sq_release_fire_w),
    .req_valid_o(sq_drain_valid_w),
    .req_rob_idx_o(sq_drain_rob_w),
    .req_producer_id_o(sq_drain_producer_id_w),
    .req_owner_kind_o(sq_drain_owner_kind_w),
    .req_owner_token_o(sq_drain_owner_token_w),
    .req_mmu_epoch_o(sq_drain_mmu_epoch_w),
    .req_fault_tval_o(sq_drain_fault_tval_w),
    .req_vaddr_o(sq_drain_vaddr_w),
    .req_paddr_o(sq_drain_addr_w),
    .req_attr_valid_o(sq_drain_attr_valid_w),
    .req_class_o(sq_drain_class_w),
    .req_cacheable_o(sq_drain_cacheable_w),
    .req_data_o(sq_drain_data_w),
    .req_strb_o(sq_drain_strb_w),
    .req_fire_i(sq_drain_req_fire_w),
    .owner_release_mask_o(sq_owner_release_mask_w),
    .snoop_valid_o(sq_snoop_valid_w),
    .snoop_addr_valid_o(sq_snoop_addr_valid_w),
    .snoop_addr_o(sq_snoop_addr_w),
    .snoop_paddr_o(sq_snoop_paddr_w),
    .snoop_attr_valid_o(sq_snoop_attr_valid_w),
    .snoop_class_o(sq_snoop_class_w),
    .snoop_cacheable_o(sq_snoop_cacheable_w),
    .snoop_data_o(sq_snoop_data_w),
    .snoop_strb_o(sq_snoop_strb_w),
    .snoop_rob_idx_o(sq_snoop_rob_idx_w),
    .snoop_producer_id_o(sq_snoop_producer_id_w),
    .snoop_owner_valid_o(sq_snoop_owner_valid_w),
    .snoop_owner_token_o(sq_snoop_owner_token_w),
    .snoop_request_sent_o(sq_snoop_request_sent_w),
    .snoop_terminal_o(sq_snoop_terminal_w),
    .snoop_head_o(sq_snoop_head_w),
    .query0_valid_i(ENABLE_DUAL_MEM && mem_sq_query_exact_w),
    .query0_producer_id_i(mem_sq_query_producer_id_w),
    .query0_paddr_i(mem_sq_query_paddr_i),
    .query0_attr_valid_i(mem_sq_query_attr_valid_i),
    .query0_class_i(mem_sq_query_class_i),
    .query0_strb_i(mem_sq_query_wstrb_i),
    .query0_allow_o(sq_query0_allow_w),
    .query0_forward_o(sq_query0_forward_w),
    .query0_replay_o(sq_query0_replay_w),
    .query0_forward_data_o(sq_query0_forward_data_w),
    .query1_valid_i(ENABLE_DUAL_MEM && mem1_sq_query_exact_w),
    .query1_producer_id_i(mem1_sq_query_producer_id_w),
    .query1_paddr_i(mem1_sq_query_paddr_i),
    .query1_attr_valid_i(mem1_sq_query_attr_valid_i),
    .query1_class_i(mem1_sq_query_class_i),
    .query1_strb_i(mem1_sq_query_wstrb_i),
    .query1_allow_o(sq_query1_allow_w),
    .query1_forward_o(sq_query1_forward_w),
    .query1_replay_o(sq_query1_replay_w),
    .query1_forward_data_o(sq_query1_forward_data_w),
    .count_o(sq_count_w)
  );

  // ===========================================================================
  // S2-G1 exact owner lifetime.  Allocation happens once at reservation
  // capture.  Logical terminals use the lossless tagged collector; only an SQ
  // release/squash may use the STORE-only bulk mask.  fault_tval remains
  // provenance payload and is deliberately absent from the identity collector.
  // ===========================================================================
  wire mem_amo_interphase_cancel_w =
      mem_pending_q && mem_amo_q && mem_amo_write_phase_q &&
      !mem_amo_write_sent_q &&
      (flush_i || checkpoint_restore_apply_w);
  wire mem_terminal_rsp_valid_w =
      mem_rsp_final_fire_w ||
      (miq_load_rsp_fire_w &&
       (mem_owner_open_w || mem_legal_closed_response_w)) ||
      (miq_probe_rsp_fire_w && mem_legal_closed_response_w);
  wire mem1_terminal_rsp_valid_w = ENABLE_DUAL_MEM &&
      ((miq1_load_rsp_fire_w &&
        (mem1_owner_open_w || mem1_legal_closed_response_w)) ||
       (miq1_probe_rsp_fire_w && mem1_legal_closed_response_w));
  wire mem_issue_res_global_cancel_w =
      (flush_i || checkpoint_restore_apply_w) && mem_issue_res_valid_q;
  wire mem_issue1_res_global_cancel_w =
      (flush_i || checkpoint_restore_apply_w) && mem_issue1_res_valid_q;
  wire mem_issue_res_tagged_terminal_w =
      (mem_issue_res_owner_kind_q != MEM_OWNER_STORE) &&
      (mem_issue_res_local_complete_w || mem_issue_res_kill_w ||
       mem_issue_res_global_cancel_w);
  wire mem_issue1_res_tagged_terminal_w =
      (mem_issue1_res_owner_kind_q != MEM_OWNER_STORE) &&
      (mem_issue1_res_local_complete_w || mem_issue1_res_kill_w ||
       mem_issue1_res_global_cancel_w);
  wire mem_buffer_cancel_w = mem_buffer_valid_q &&
      (mem_buffer_kill_w || flush_i || checkpoint_restore_apply_w);
  wire mem_buffer_tagged_terminal_w = mem_buffer_cancel_w &&
      (mem_buffer_owner_kind_q != MEM_OWNER_STORE);
  wire mem_retry0_tagged_terminal_w = mem_retry0_cancel_w;
  wire mem_retry1_tagged_terminal_w = mem_retry1_cancel_w;

  // Lane assignment is stable evidence, not priority: both responses, four
  // bridge drops, both reservation terminals, the legacy buffer cancel, the
  // exact AMO interphase cancel and both bank-local retry cancels may arrive
  // together.
  assign mem_terminal_ingress_valid_w = {
      mem_retry1_tagged_terminal_w,
      mem_retry0_tagged_terminal_w,
      mem_amo_interphase_cancel_w,
      mem_buffer_tagged_terminal_w,
      mem_issue1_res_tagged_terminal_w,
      mem_issue_res_tagged_terminal_w,
      mem1_drop1_valid_i,
      mem1_drop0_valid_i,
      mem_drop1_valid_i,
      mem_drop0_valid_i,
      mem1_terminal_rsp_valid_w,
      mem_terminal_rsp_valid_w
  };
  assign mem_terminal_ingress_kind_w = {
      mem_retry1_owner_kind_q,
      mem_retry0_owner_kind_q,
      mem_owner_kind_q,
      mem_buffer_owner_kind_q,
      mem_issue1_res_owner_kind_q,
      mem_issue_res_owner_kind_q,
      mem1_drop1_owner_kind_i,
      mem1_drop0_owner_kind_i,
      mem_drop1_owner_kind_i,
      mem_drop0_owner_kind_i,
      miq1_head_owner_kind_w,
      miq_head_owner_kind_w
  };
  assign mem_terminal_ingress_token_w = {
      mem_retry1_owner_token_q,
      mem_retry0_owner_token_q,
      mem_owner_token_q,
      mem_buffer_owner_token_q,
      mem_issue1_res_owner_token_q,
      mem_issue_res_owner_token_q,
      mem1_drop1_owner_token_i,
      mem1_drop0_owner_token_i,
      mem_drop1_owner_token_i,
      mem_drop0_owner_token_i,
      miq1_head_owner_token_w,
      miq_head_owner_token_w
  };
  assign mem_terminal_ingress_epoch_w = {
      mem_retry1_mmu_epoch_q,
      mem_retry0_mmu_epoch_q,
      mem_mmu_epoch_q,
      mem_buffer_mmu_epoch_q,
      mem_issue1_res_mmu_epoch_q,
      mem_issue_res_mmu_epoch_q,
      mem1_drop1_mmu_epoch_i,
      mem1_drop0_mmu_epoch_i,
      mem_drop1_mmu_epoch_i,
      mem_drop0_mmu_epoch_i,
      miq1_head_mmu_epoch_w,
      miq_head_mmu_epoch_w
  };

  assign mem_terminal_ingress0_mask_w =
      mem_terminal_rsp_valid_w ?
      (32'b1 << miq_head_owner_token_w) : 32'b0;
  assign mem_terminal_ingress1_mask_w =
      mem1_terminal_rsp_valid_w ?
      (32'b1 << miq1_head_owner_token_w) : 32'b0;
  assign mem_terminal_ingress2_mask_w =
      mem_drop0_valid_i ?
      (32'b1 << mem_drop0_owner_token_i) : 32'b0;
  assign mem_terminal_ingress3_mask_w =
      mem_drop1_valid_i ?
      (32'b1 << mem_drop1_owner_token_i) : 32'b0;
  assign mem_terminal_ingress4_mask_w =
      mem1_drop0_valid_i ?
      (32'b1 << mem1_drop0_owner_token_i) : 32'b0;
  assign mem_terminal_ingress5_mask_w =
      mem1_drop1_valid_i ?
      (32'b1 << mem1_drop1_owner_token_i) : 32'b0;
  assign mem_terminal_ingress6_mask_w =
      mem_issue_res_tagged_terminal_w ?
      (32'b1 << mem_issue_res_owner_token_q) : 32'b0;
  assign mem_terminal_ingress7_mask_w =
      mem_issue1_res_tagged_terminal_w ?
      (32'b1 << mem_issue1_res_owner_token_q) : 32'b0;
  assign mem_terminal_ingress8_mask_w =
      mem_buffer_tagged_terminal_w ?
      (32'b1 << mem_buffer_owner_token_q) : 32'b0;
  assign mem_terminal_ingress9_mask_w =
      mem_amo_interphase_cancel_w ?
      (32'b1 << mem_owner_token_q) : 32'b0;
  assign mem_terminal_ingress10_mask_w =
      mem_retry0_tagged_terminal_w ?
      (32'b1 << mem_retry0_owner_token_q) : 32'b0;
  assign mem_terminal_ingress11_mask_w =
      mem_retry1_tagged_terminal_w ?
      (32'b1 << mem_retry1_owner_token_q) : 32'b0;
  assign mem_terminal_ingress_mask_w =
      mem_terminal_ingress0_mask_w | mem_terminal_ingress1_mask_w |
      mem_terminal_ingress2_mask_w | mem_terminal_ingress3_mask_w |
      mem_terminal_ingress4_mask_w | mem_terminal_ingress5_mask_w |
      mem_terminal_ingress6_mask_w | mem_terminal_ingress7_mask_w |
      mem_terminal_ingress8_mask_w | mem_terminal_ingress9_mask_w |
      mem_terminal_ingress10_mask_w | mem_terminal_ingress11_mask_w;

  wire [31:0] mem_issue_res_owner_mask_w = mem_issue_res_valid_q ?
      (32'b1 << mem_issue_res_owner_token_q) : 32'b0;
  wire [31:0] mem_issue1_res_owner_mask_w = mem_issue1_res_valid_q ?
      (32'b1 << mem_issue1_res_owner_token_q) : 32'b0;
  wire [31:0] mem_buffer_owner_mask_w = mem_buffer_valid_q ?
      (32'b1 << mem_buffer_owner_token_q) : 32'b0;
  wire [31:0] mem_retry0_owner_mask_w = mem_retry0_valid_q ?
      (32'b1 << mem_retry0_owner_token_q) : 32'b0;
  wire [31:0] mem_retry1_owner_mask_w = mem_retry1_valid_q ?
      (32'b1 << mem_retry1_owner_token_q) : 32'b0;
  wire [31:0] mem_req_fire_owner_mask_w = mem_req_fire_any_w ?
      (32'b1 << mem_req_owner_token_o) : 32'b0;
  wire [31:0] mem1_req_fire_owner_mask_w = mem1_req_fire_any_w ?
      (32'b1 << mem1_req_owner_token_o) : 32'b0;

  // A raw SQ release cannot free a token that still has another authority.
  // Three exact same-edge handoffs are exceptions: an exact STORE response
  // ends MIQ/bridge residency, or a STORE reservation/buffer is locally
  // cancelled while the SQ squash removes its final architectural owner.
  wire [31:0] sq_response_terminal_owner_mask_w =
      sq_response_terminal_w &&
      (miq_head_owner_kind_w == MEM_OWNER_STORE) ?
      (32'b1 << miq_head_owner_token_w) : 32'b0;
  wire [31:0] sq_response1_terminal_owner_mask_w =
      sq_response1_terminal_w &&
      (miq1_head_owner_kind_w == MEM_OWNER_STORE) ?
      (32'b1 << miq1_head_owner_token_w) : 32'b0;
  wire mem_issue_res_store_authority_end_w = mem_issue_res_valid_q &&
      (mem_issue_res_owner_kind_q == MEM_OWNER_STORE) &&
      (mem_issue_res_local_complete_w || mem_issue_res_kill_w ||
       mem_issue_res_global_cancel_w);
  wire [31:0] mem_issue_res_store_authority_end_mask_w =
      mem_issue_res_store_authority_end_w ?
      (32'b1 << mem_issue_res_owner_token_q) : 32'b0;
  wire mem_issue1_res_store_authority_end_w = mem_issue1_res_valid_q &&
      (mem_issue1_res_owner_kind_q == MEM_OWNER_STORE) &&
      (mem_issue1_res_local_complete_w || mem_issue1_res_kill_w ||
       mem_issue1_res_global_cancel_w);
  wire [31:0] mem_issue1_res_store_authority_end_mask_w =
      mem_issue1_res_store_authority_end_w ?
      (32'b1 << mem_issue1_res_owner_token_q) : 32'b0;
  wire [31:0] mem_buffer_store_authority_end_mask_w =
      mem_buffer_cancel_w &&
      (mem_buffer_owner_kind_q == MEM_OWNER_STORE) ?
      (32'b1 << mem_buffer_owner_token_q) : 32'b0;
  wire [31:0] sq_owner_release_override_mask_w =
      sq_response_terminal_owner_mask_w |
      sq_response1_terminal_owner_mask_w |
      mem_issue_res_store_authority_end_mask_w |
      mem_issue1_res_store_authority_end_mask_w |
      mem_buffer_store_authority_end_mask_w;
  wire [31:0] sq_owner_release_resident_mask_w =
      miq_occupancy_token_mask_w | miq1_occupancy_token_mask_w |
      mem_bridge_owner_residency_mask_i |
      mem1_bridge_owner_residency_mask_i |
      mem_issue_res_owner_mask_w | mem_issue1_res_owner_mask_w |
      mem_buffer_owner_mask_w | mem_retry0_owner_mask_w |
      mem_retry1_owner_mask_w |
      mem_req_fire_owner_mask_w | mem1_req_fire_owner_mask_w;
  wire [31:0] sq_owner_release_nonoverride_mask_w =
      mem_terminal_pending_mask_w | mem_terminal_ingress_mask_w;
  assign sq_owner_release_effective_mask_w = sq_owner_release_mask_w &
      ~sq_owner_release_nonoverride_mask_w &
      (~sq_owner_release_resident_mask_w |
       sq_owner_release_override_mask_w);

  OooMemOwnerTerminalCollector #(
    .INGRESS_N(12)
  ) u_mem_owner_terminal_collector (
    .clk(clk),
    .rst(rst),
    .ingress_valid_i(mem_terminal_ingress_valid_w),
    .ingress_kind_i(mem_terminal_ingress_kind_w),
    .ingress_token_i(mem_terminal_ingress_token_w),
    .ingress_epoch_i(mem_terminal_ingress_epoch_w),
    .live_mask_i(mem_owner_live_mask_w),
    .live_kind_table_i(mem_owner_kind_table_w),
    .live_epoch_table_i(mem_owner_epoch_table_w),
    .deq0_valid_o(mem_terminal_deq0_valid_w),
    .deq0_kind_o(mem_terminal_deq0_kind_w),
    .deq0_token_o(mem_terminal_deq0_token_w),
    .deq0_epoch_o(mem_terminal_deq0_epoch_w),
    .deq0_ready_i(mem_terminal_deq0_ready_w),
    .deq1_valid_o(mem_terminal_deq1_valid_w),
    .deq1_kind_o(mem_terminal_deq1_kind_w),
    .deq1_token_o(mem_terminal_deq1_token_w),
    .deq1_epoch_o(mem_terminal_deq1_epoch_w),
    .deq1_ready_i(mem_terminal_deq1_ready_w),
    .pending_mask_o(mem_terminal_pending_mask_w),
    .pending_count_o(mem_terminal_pending_count_w)
  );

  OooMemOwnerTracker #(
    .PRODUCER_ID_W(PRODUCER_ID_W),
    .PRODUCER_COUNT(1 << PRODUCER_ID_W)
  ) u_mem_owner_tracker (
    .clk(clk),
    .rst(rst),
    .alloc0_valid_i(mem_issue_res_capture_candidate_w),
    .alloc0_kind_i(mem_owner_kind_from_ctrl(iq_issue0_ctrl_w)),
    .alloc0_epoch_i(MEM_OWNER_EPOCH_BASE),
    .alloc0_producer_id_i(iq_issue0_producer_id_w),
    .alloc0_ready_o(mem_owner_alloc0_ready_w),
    .alloc0_token_o(mem_owner_alloc0_token_w),
    .alloc1_valid_i(mem_issue1_res_capture_candidate_w),
    .alloc1_kind_i(mem_owner_kind_from_ctrl(issue1_ctrl_w)),
    .alloc1_epoch_i(MEM_OWNER_EPOCH_BASE),
    .alloc1_producer_id_i(issue1_producer_id_w),
    .alloc1_ready_o(mem_owner_alloc1_ready_w),
    .alloc1_token_o(mem_owner_alloc1_token_w),
    .alloc_pair_atomic_i(1'b1),
    .free0_valid_i(mem_terminal_deq0_valid_w),
    .free0_kind_i(mem_terminal_deq0_kind_w),
    .free0_token_i(mem_terminal_deq0_token_w),
    .free0_epoch_i(mem_terminal_deq0_epoch_w),
    .free0_ready_o(mem_terminal_deq0_ready_w),
    .free1_valid_i(mem_terminal_deq1_valid_w),
    .free1_kind_i(mem_terminal_deq1_kind_w),
    .free1_token_i(mem_terminal_deq1_token_w),
    .free1_epoch_i(mem_terminal_deq1_epoch_w),
    .free1_ready_o(mem_terminal_deq1_ready_w),
    .release_mask_i(sq_owner_release_effective_mask_w),
    .live_mask_o(mem_owner_live_mask_w),
    .kind_table_o(mem_owner_kind_table_w),
    .epoch_table_o(mem_owner_epoch_table_w),
    .producer_id_table_o(mem_owner_producer_id_table_w),
    .producer_live_mask_o(mem_owner_producer_live_mask_w),
    .live_count_o(mem_owner_live_count_w)
  );

  assign lq_terminal0_valid_w = mem_terminal_deq0_valid_w &&
      mem_terminal_deq0_ready_w &&
      (mem_terminal_deq0_kind_w == MEM_OWNER_LOAD);
  assign lq_terminal0_producer_id_w = mem_owner_producer_id_table_w[
      mem_terminal_deq0_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];
  assign lq_terminal1_valid_w = mem_terminal_deq1_valid_w &&
      mem_terminal_deq1_ready_w &&
      (mem_terminal_deq1_kind_w == MEM_OWNER_LOAD);
  assign lq_terminal1_producer_id_w = mem_owner_producer_id_table_w[
      mem_terminal_deq1_token_w*PRODUCER_ID_W +: PRODUCER_ID_W];

  OooLoadQueue #(
    .ENTRY_N(LQ_ENTRY_N),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_ID_W(PRODUCER_ID_W),
    .ENTRY_COUNT_W(LQ_COUNT_W)
  ) u_load_queue (
    .clk(clk),
    .rst(rst),
    .flush_valid_i(flush_i || checkpoint_restore_apply_w ||
                   branch_resolve_mispredict_w),
    .flush_all_i(flush_i || checkpoint_restore_apply_w),
    .flush_rob_head_i(rob_head_idx_w),
    .flush_boundary_rob_i(branch_resolve_rob_idx_o),
    .alloc0_valid_i(lq_alloc0_valid_w),
    .alloc0_ready_o(lq_alloc0_ready_w),
    .alloc0_rob_idx_i(lq_alloc0_rob_w),
    .alloc0_producer_id_i(lq_alloc0_producer_id_w),
    .alloc1_valid_i(lq_alloc1_valid_w),
    .alloc1_ready_o(lq_alloc1_ready_w),
    .alloc1_rob_idx_i(dispatch1_rob_idx_w),
    .alloc1_producer_id_i(dispatch1_producer_id_w),
    .issue0_valid_i(mem_issue_res_valid_q && issue0_is_load_w &&
                    !issue0_is_amo_w),
    .issue0_producer_id_i(mem_issue_res_producer_id_q),
    .issue0_open_o(lq_issue0_open_w),
    .issue1_valid_i(mem_issue1_res_valid_q && issue1_is_load_w),
    .issue1_producer_id_i(mem_issue1_res_producer_id_q),
    .issue1_open_o(lq_issue1_open_w),
    .launch0_valid_i(lq_launch0_valid_w),
    .launch0_producer_id_i(lq_launch0_producer_id_w),
    .launch1_valid_i(lq_launch1_valid_w),
    .launch1_producer_id_i(lq_launch1_producer_id_w),
    .query0_valid_i(ENABLE_DUAL_MEM && mem_sq_query_pre_lq_exact_w),
    .query0_producer_id_i(mem_sq_query_producer_id_w),
    .query0_paddr_i(mem_sq_query_paddr_i),
    .query0_attr_valid_i(mem_sq_query_attr_valid_i),
    .query0_class_i(mem_sq_query_class_i),
    .query0_strb_i(mem_sq_query_wstrb_i),
    .query0_open_o(lq_query0_open_w),
    .query0_update_i(lq_query0_update_w),
    .query0_allow_i(sq_query0_allow_w),
    .query0_forward_i(sq_query0_forward_w),
    .query0_replay_i(sq_query0_replay_w),
    .query1_valid_i(ENABLE_DUAL_MEM && mem1_sq_query_pre_lq_exact_w),
    .query1_producer_id_i(mem1_sq_query_producer_id_w),
    .query1_paddr_i(mem1_sq_query_paddr_i),
    .query1_attr_valid_i(mem1_sq_query_attr_valid_i),
    .query1_class_i(mem1_sq_query_class_i),
    .query1_strb_i(mem1_sq_query_wstrb_i),
    .query1_open_o(lq_query1_open_w),
    .query1_update_i(lq_query1_update_w),
    .query1_allow_i(sq_query1_allow_w),
    .query1_forward_i(sq_query1_forward_w),
    .query1_replay_i(sq_query1_replay_w),
    .response0_valid_i(lq_response0_query_valid_w),
    .response0_producer_id_i(mem_completion_producer_id_w),
    .response0_fault_i(!ENABLE_DUAL_MEM || mem_rsp_error_i ||
                       mem_rsp_page_fault_i),
    .response0_open_o(lq_response0_open_w),
    .response1_valid_i(lq_response1_query_valid_w),
    .response1_producer_id_i(mem1_completion_producer_id_w),
    .response1_fault_i(!ENABLE_DUAL_MEM || mem1_rsp_error_i ||
                       mem1_rsp_page_fault_i),
    .response1_open_o(lq_response1_open_w),
    .completion0_valid_i(wb0_valid_w),
    .completion0_producer_id_i(wb0_producer_id_w),
    .completion1_valid_i(wb1_valid_w),
    .completion1_producer_id_i(wb1_producer_id_w),
    .terminal0_valid_i(lq_terminal0_valid_w),
    .terminal0_producer_id_i(lq_terminal0_producer_id_w),
    .terminal1_valid_i(lq_terminal1_valid_w),
    .terminal1_producer_id_i(lq_terminal1_producer_id_w),
    .release0_valid_i(lq_release0_valid_w),
    .release0_producer_id_i(rob_commit0_producer_id_w),
    .release0_commit_i(lq_release0_commit_w),
    .release0_ready_o(lq_release0_ready_w),
    .release0_fire_o(lq_release0_fire_w),
    .release1_valid_i(lq_release1_valid_w),
    .release1_producer_id_i(rob_commit1_producer_id_w),
    .release1_commit_i(lq_release1_commit_w),
    .release1_ready_o(lq_release1_ready_w),
    .release1_fire_o(lq_release1_fire_w),
    .producer_live_mask_o(lq_producer_live_mask_w),
    .count_o(lq_count_w)
  );

`ifdef OOO_ASSERT
  // v8v integration contract: a plain load may cross each architectural
  // lifetime boundary only while its full ProducerId is resident in the
  // shared LQ.  These checks sit outside OooLoadQueue so a top-level wiring or
  // qualification mutation cannot obtain a false green from the module-local
  // assertions alone.
  always @(posedge clk) begin
    if (!rst) begin
      if (lq_alloc0_valid_w && !lq_alloc0_ready_w) begin
        $display("[V8V-LQ-INTEGRATION-ALLOC0] dispatched load lacked LQ credit pid=%h @%0t",
                 lq_alloc0_producer_id_w, $time);
        $fatal;
      end
      if (lq_alloc1_valid_w && !lq_alloc1_ready_w) begin
        $display("[V8V-LQ-INTEGRATION-ALLOC1] dispatched load pair lacked second LQ credit pid=%h @%0t",
                 dispatch1_producer_id_w, $time);
        $fatal;
      end
      if (mem_issue_res_consume_fire_w && issue0_is_load_w &&
          !issue0_is_amo_w && !lq_issue0_open_w) begin
        $display("[V8V-LQ-INTEGRATION-ISSUE0] plain load crossed reservation without exact LQ owner pid=%h @%0t",
                 mem_issue_res_producer_id_q, $time);
        $fatal;
      end
      if (mem_issue1_res_consume_fire_w && issue1_is_load_w &&
          !lq_issue1_open_w) begin
        $display("[V8V-LQ-INTEGRATION-ISSUE1] plain load crossed reservation without exact LQ owner pid=%h @%0t",
                 mem_issue1_res_producer_id_q, $time);
        $fatal;
      end
      if (lq_launch0_valid_w &&
          !lq_producer_live_mask_w[lq_launch0_producer_id_w]) begin
        $display("[V8V-LQ-INTEGRATION-LAUNCH0] bank0 LOAD request fire lacked resident LQ owner pid=%h @%0t",
                 lq_launch0_producer_id_w, $time);
        $fatal;
      end
      if (lq_launch1_valid_w &&
          !lq_producer_live_mask_w[lq_launch1_producer_id_w]) begin
        $display("[V8V-LQ-INTEGRATION-LAUNCH1] bank1 LOAD request fire lacked resident LQ owner pid=%h @%0t",
                 lq_launch1_producer_id_w, $time);
        $fatal;
      end
      if (lq_release0_commit_w && !lq_release0_fire_w) begin
        $display("[V8V-LQ-INTEGRATION-RETIRE0] ROB commit escaped exact completed LQ release pid=%h @%0t",
                 rob_commit0_producer_id_w, $time);
        $fatal;
      end
      if (lq_release1_commit_w && !lq_release1_fire_w) begin
        $display("[V8V-LQ-INTEGRATION-RETIRE1] ROB commit escaped exact completed LQ release pid=%h @%0t",
                 rob_commit1_producer_id_w, $time);
        $fatal;
      end
    end
  end
`endif

  assign mem_tracker_expected_valid_o = mem_owner_query_valid_i &&
      mem_owner_live_mask_w[mem_owner_query_token_i];
  assign mem_tracker_expected_owner_kind_o =
      mem_tracker_expected_valid_o ?
      mem_owner_kind_table_w[mem_owner_query_token_i*2 +: 2] :
      MEM_OWNER_RESERVED;
  assign mem_tracker_expected_owner_token_o =
      mem_tracker_expected_valid_o ? mem_owner_query_token_i : 5'b0;
  assign mem_tracker_expected_mmu_epoch_o =
      mem_tracker_expected_valid_o ?
      mem_owner_epoch_table_w[mem_owner_query_token_i*2 +: 2] :
      MEM_OWNER_EPOCH_BASE;
  assign mem_station_expected_valid_o = mem_station_query_valid_i &&
      mem_owner_live_mask_w[mem_station_query_token_i];
  assign mem_station_expected_owner_kind_o =
      mem_station_expected_valid_o ?
      mem_owner_kind_table_w[mem_station_query_token_i*2 +: 2] :
      MEM_OWNER_RESERVED;
  assign mem_station_expected_owner_token_o =
      mem_station_expected_valid_o ? mem_station_query_token_i : 5'b0;
  assign mem_station_expected_mmu_epoch_o =
      mem_station_expected_valid_o ?
      mem_owner_epoch_table_w[mem_station_query_token_i*2 +: 2] :
      MEM_OWNER_EPOCH_BASE;
  assign mem1_tracker_expected_valid_o = ENABLE_DUAL_MEM &&
      mem1_owner_query_valid_i &&
      mem_owner_live_mask_w[mem1_owner_query_token_i];
  assign mem1_tracker_expected_owner_kind_o =
      mem1_tracker_expected_valid_o ?
      mem_owner_kind_table_w[mem1_owner_query_token_i*2 +: 2] :
      MEM_OWNER_RESERVED;
  assign mem1_tracker_expected_owner_token_o =
      mem1_tracker_expected_valid_o ? mem1_owner_query_token_i : 5'b0;
  assign mem1_tracker_expected_mmu_epoch_o =
      mem1_tracker_expected_valid_o ?
      mem_owner_epoch_table_w[mem1_owner_query_token_i*2 +: 2] :
      MEM_OWNER_EPOCH_BASE;
  assign mem1_station_expected_valid_o = ENABLE_DUAL_MEM &&
      mem1_station_query_valid_i &&
      mem_owner_live_mask_w[mem1_station_query_token_i];
  assign mem1_station_expected_owner_kind_o =
      mem1_station_expected_valid_o ?
      mem_owner_kind_table_w[mem1_station_query_token_i*2 +: 2] :
      MEM_OWNER_RESERVED;
  assign mem1_station_expected_owner_token_o =
      mem1_station_expected_valid_o ? mem1_station_query_token_i : 5'b0;
  assign mem1_station_expected_mmu_epoch_o =
      mem1_station_expected_valid_o ?
      mem_owner_epoch_table_w[mem1_station_query_token_i*2 +: 2] :
      MEM_OWNER_EPOCH_BASE;

  reg sq_release_hit_r;
  reg sq_release_terminal_r;
  always @(*) begin : sq_release_cam_blk
    integer k;
    sq_release_hit_r = 1'b0;
    sq_release_terminal_r = 1'b0;
    for (k = 0; k < SQ_ENTRY_N; k = k + 1) begin
      if (sq_snoop_valid_w[k] &&
          (sq_snoop_rob_idx_w[k*ROB_INDEX_W +: ROB_INDEX_W] ==
           sq_release_rob_w) &&
          (sq_snoop_producer_id_w[
              k*PRODUCER_ID_W +: PRODUCER_ID_W] ==
           rob_head_producer_id_w)) begin
        sq_release_hit_r = 1'b1;
        sq_release_terminal_r = sq_snoop_terminal_w[k];
      end
    end
  end

  reg [7:0] sq_fail_count_q;
  always @(posedge clk) begin
    if (rst) begin
      sq_fail_count_q <= 8'd0;
    end else if (sq_fail_count_q < 8'd32) begin
      if (sq_alloc0_valid_w && !sq_alloc0_ready_w) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] alloc0 overflow rob=%0d count=%0d",
                 sq_alloc0_rob_w, sq_count_w);
      end
      if (sq_alloc1_valid_w && !sq_alloc1_ready_w) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] alloc1 overflow rob=%0d count=%0d",
                 dispatch1_rob_idx_w, sq_count_w);
      end
      if (sq_release_valid_w && !sq_release_hit_r) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[SQSHADOW-FAIL] commit0 store not in SQ rob=%0d pc=0x%h",
                 sq_release_rob_w, commit0_pc_o);
      end
      if (sq_release_valid_w && sq_release_hit_r &&
          !sq_release_terminal_r &&
          !((sq_terminal0_valid_w &&
             (sq_terminal0_rob_w == sq_release_rob_w)) ||
            (sq_terminal1_valid_w &&
             (sq_terminal1_rob_w == sq_release_rob_w)))) begin
        sq_fail_count_q <= sq_fail_count_q + 8'd1;
        $display("[T4N-SQ-RELEASE-EARLY] commit before terminal rob=%0d pc=0x%h",
                 sq_release_rob_w, commit0_pc_o);
      end
    end
  end

`ifdef OOO_ASSERT
  wire [2:0] mem_req_grant_count_w =
      {2'b00, grant_sq_w} + {2'b00, grant_amo_write_w} +
      {2'b00, grant_buffer_w} + {2'b00, grant_retry0_w} +
      {2'b00, grant_issue0_w} +
      {2'b00, grant_issue1_w};
  wire [1:0] mem1_req_grant_count_w =
      {1'b0, grant_retry1_w} + {1'b0, grant_mem1_issue0_w} +
      {1'b0, grant_mem1_issue1_w};
  // v8l independent holder reference.  This assertion-only view scans raw Q
  // valids/tokens and deliberately does not reuse the production
  // producer_live_mask_w construction.  It therefore catches an omitted
  // direct holder as well as a token-indirect holder detached from the memory
  // tracker.
  reg [31:0] v8l_sq_owner_token_mask_r;
  integer v8l_sq_mask_i;
  integer v8l_assert_i;
  always @(*) begin
    v8l_sq_owner_token_mask_r = 32'b0;
    for (v8l_sq_mask_i = 0; v8l_sq_mask_i < SQ_ENTRY_N;
         v8l_sq_mask_i = v8l_sq_mask_i + 1) begin
      if (sq_snoop_owner_valid_w[v8l_sq_mask_i])
        v8l_sq_owner_token_mask_r[
            sq_snoop_owner_token_w[v8l_sq_mask_i*5 +: 5]] = 1'b1;
    end
  end
  wire [31:0] v8l_mem_res_token_mask_w = mem_issue_res_valid_q ?
      (32'b1 << mem_issue_res_owner_token_q) : 32'b0;
  wire [31:0] v8l_mem1_res_token_mask_w = mem_issue1_res_valid_q ?
      (32'b1 << mem_issue1_res_owner_token_q) : 32'b0;
  wire [31:0] v8l_mem_buffer_token_mask_w = mem_buffer_valid_q ?
      (32'b1 << mem_buffer_owner_token_q) : 32'b0;
  wire [31:0] v8l_mem_retry0_token_mask_w = mem_retry0_valid_q ?
      (32'b1 << mem_retry0_owner_token_q) : 32'b0;
  wire [31:0] v8l_mem_retry1_token_mask_w = mem_retry1_valid_q ?
      (32'b1 << mem_retry1_owner_token_q) : 32'b0;
  wire [31:0] v8l_mem_pending_token_mask_w = mem_pending_q ?
      (32'b1 << mem_owner_token_q) : 32'b0;
  wire [31:0] v8l_indirect_resident_mask_w =
      miq_occupancy_token_mask_w | miq1_occupancy_token_mask_w |
      mem_bridge_owner_residency_mask_i |
      mem1_bridge_owner_residency_mask_i |
      mem_terminal_pending_mask_w |
      v8l_mem_res_token_mask_w |
      v8l_mem1_res_token_mask_w |
      v8l_mem_buffer_token_mask_w |
      v8l_mem_retry0_token_mask_w |
      v8l_mem_retry1_token_mask_w |
      v8l_mem_pending_token_mask_w |
      v8l_sq_owner_token_mask_r;
  reg v8l_mem_capture_shadow_q;
  reg [4:0] v8l_mem_capture_token_q;
  reg [PRODUCER_ID_W-1:0] v8l_mem_capture_producer_q;
  reg v8l_mem1_capture_shadow_q;
  reg [4:0] v8l_mem1_capture_token_q;
  reg [PRODUCER_ID_W-1:0] v8l_mem1_capture_producer_q;
  reg v8t_retry0_capture_shadow_q;
  reg [4:0] v8t_retry0_capture_token_q;
  reg [PRODUCER_ID_W-1:0] v8t_retry0_capture_producer_q;
  reg v8t_retry1_capture_shadow_q;
  reg [4:0] v8t_retry1_capture_token_q;
  reg [PRODUCER_ID_W-1:0] v8t_retry1_capture_producer_q;
  reg v8t_retry0_repush_shadow_q;
  reg [4:0] v8t_retry0_repush_token_q;
  reg v8t_retry1_repush_shadow_q;
  reg [4:0] v8t_retry1_repush_token_q;
  reg v8g_mem_wb_wait_q;
  always @(posedge clk) begin
    if (rst || flush_i || checkpoint_restore_apply_w) begin
      v8g_mem_wb_wait_q <= 1'b0;
      v8l_mem_capture_shadow_q <= 1'b0;
      v8l_mem_capture_token_q <= 5'b0;
      v8l_mem_capture_producer_q <= {PRODUCER_ID_W{1'b0}};
      v8l_mem1_capture_shadow_q <= 1'b0;
      v8l_mem1_capture_token_q <= 5'b0;
      v8l_mem1_capture_producer_q <= {PRODUCER_ID_W{1'b0}};
      v8t_retry0_capture_shadow_q <= 1'b0;
      v8t_retry0_capture_token_q <= 5'b0;
      v8t_retry0_capture_producer_q <= {PRODUCER_ID_W{1'b0}};
      v8t_retry1_capture_shadow_q <= 1'b0;
      v8t_retry1_capture_token_q <= 5'b0;
      v8t_retry1_capture_producer_q <= {PRODUCER_ID_W{1'b0}};
      v8t_retry0_repush_shadow_q <= 1'b0;
      v8t_retry0_repush_token_q <= 5'b0;
      v8t_retry1_repush_shadow_q <= 1'b0;
      v8t_retry1_repush_token_q <= 5'b0;
    end else begin
      if (mem_issue_res_capture_w !==
          (mem_issue_res_capture_candidate_w && mem_owner_alloc0_ready_w &&
           (!mem_issue1_res_capture_candidate_w ||
            mem_owner_alloc1_ready_w))) begin
        $display("[V8L-MEM-HANDOFF-ATOMIC] capture diverged from candidate&&tracker-ready @%0t",
                 $time);
        $fatal;
      end
      if (mem_issue_res_capture_candidate_w && !mem_owner_alloc0_ready_w &&
          (iq_issue0_ready_w || mem_issue_res_capture_w)) begin
        $display("[V8L-MEM-HANDOFF-BACKPRESSURE] failed tracker allocation popped/captured IQ owner @%0t",
                 $time);
        $fatal;
      end
      if (sq_owner_bind_valid_w !==
          (mem_issue_res_capture_w &&
           (mem_owner_kind_from_ctrl(iq_issue0_ctrl_w) == MEM_OWNER_STORE))) begin
        $display("[V8L-MEM-SQ-BIND-ATOMIC] SQ bind diverged from STORE capture @%0t",
                 $time);
        $fatal;
      end
      if (sq_owner_bind1_valid_w !==
          (mem_issue1_res_capture_w &&
           (mem_owner_kind_from_ctrl(issue1_ctrl_w) == MEM_OWNER_STORE))) begin
        $display("[V8P-MEM1-SQ-BIND-ATOMIC] SQ bind1 diverged from STORE capture @%0t",
                 $time);
        $fatal;
      end
      if (v8l_mem_capture_shadow_q &&
          (!mem_owner_live_mask_w[v8l_mem_capture_token_q] ||
           (mem_owner_producer_id_table_w[
               v8l_mem_capture_token_q*PRODUCER_ID_W +: PRODUCER_ID_W] !==
            v8l_mem_capture_producer_q))) begin
        $display("[V8L-MEM-HANDOFF-NEXT-Q] successful capture lacked stable tracker token/P next cycle @%0t",
                 $time);
        $fatal;
      end
      if (v8l_mem1_capture_shadow_q &&
          (!mem_owner_live_mask_w[v8l_mem1_capture_token_q] ||
           (mem_owner_producer_id_table_w[
               v8l_mem1_capture_token_q*PRODUCER_ID_W +: PRODUCER_ID_W] !==
            v8l_mem1_capture_producer_q))) begin
        $display("[V8P-MEM1-HANDOFF-NEXT-Q] successful capture lacked stable tracker token/P next cycle @%0t",
                 $time);
        $fatal;
      end
      if (v8t_retry0_capture_shadow_q &&
          (!mem_retry0_valid_q ||
           (mem_retry0_owner_token_q != v8t_retry0_capture_token_q) ||
           (mem_retry0_producer_id_q != v8t_retry0_capture_producer_q) ||
           !mem_retry0_tracker_exact_w ||
           miq_occupancy_token_mask_w[v8t_retry0_capture_token_q])) begin
        $display("[V8T-RETRY0-HANDOFF-NEXT-Q] MIQ-to-retry holder transfer was not exact/lossless @%0t",
                 $time);
        $fatal;
      end
      if (v8t_retry1_capture_shadow_q &&
          (!mem_retry1_valid_q ||
           (mem_retry1_owner_token_q != v8t_retry1_capture_token_q) ||
           (mem_retry1_producer_id_q != v8t_retry1_capture_producer_q) ||
           !mem_retry1_tracker_exact_w ||
           miq1_occupancy_token_mask_w[v8t_retry1_capture_token_q])) begin
        $display("[V8T-RETRY1-HANDOFF-NEXT-Q] MIQ1-to-retry holder transfer was not exact/lossless @%0t",
                 $time);
        $fatal;
      end
      if (v8t_retry0_repush_shadow_q &&
          !miq_occupancy_token_mask_w[v8t_retry0_repush_token_q]) begin
        $display("[V8T-RETRY0-REPUSH-NEXT-Q] retry request fire lacked exact MIQ residency next cycle @%0t",
                 $time);
        $fatal;
      end
      if (v8t_retry1_repush_shadow_q &&
          !miq1_occupancy_token_mask_w[v8t_retry1_repush_token_q]) begin
        $display("[V8T-RETRY1-REPUSH-NEXT-Q] retry1 request fire lacked exact MIQ residency next cycle @%0t",
                 $time);
        $fatal;
      end
      if ((v8l_indirect_resident_mask_w & ~mem_owner_live_mask_w) != 32'b0) begin
        $display("[V8L-MEM-INDIRECT-TRACKER] resident token domain escaped tracker live set resident=%h tracker=%h @%0t",
                 v8l_indirect_resident_mask_w, mem_owner_live_mask_w, $time);
        $fatal;
      end
      if ((mem_owner_producer_live_mask_w & ~producer_live_mask_w) !=
          {(1 << PRODUCER_ID_W){1'b0}}) begin
        $display("[V8L-MEM-LEASE-UNION] tracker ProducerId missing from complete mask @%0t",
                 $time);
        $fatal;
      end
      if ((fp_producer_live_mask_w & ~producer_live_mask_w) !=
          {(1 << PRODUCER_ID_W){1'b0}}) begin
        $display("[V8L-FP-LEASE-UNION] FP ProducerId missing from complete mask @%0t",
                 $time);
        $fatal;
      end
      if (mem_issue_res_valid_q &&
          ((^mem_issue_res_producer_id_q === 1'bx) ||
           (^mem_issue_res_owner_token_q === 1'bx) ||
           !producer_live_mask_w[mem_issue_res_producer_id_q])) begin
        $display("[V8L-TRANSIENT-LEASE] memory reservation has unknown/uncovered P or token @%0t",
                 $time);
        $fatal;
      end
      if (mem_issue1_res_valid_q &&
          ((^mem_issue1_res_producer_id_q === 1'bx) ||
           (^mem_issue1_res_owner_token_q === 1'bx) ||
           !producer_live_mask_w[mem_issue1_res_producer_id_q])) begin
        $display("[V8P-TRANSIENT1-LEASE] memory reservation1 has unknown/uncovered P or token @%0t",
                 $time);
        $fatal;
      end
      if (ex0_valid_q &&
          ((^ex0_producer_id_q === 1'bx) ||
           !producer_live_mask_w[ex0_producer_id_q])) begin
        $display("[V8L-TRANSIENT-LEASE] EX0 has unknown/uncovered P @%0t",
                 $time);
        $fatal;
      end
      if (ex1_valid_q &&
          ((^ex1_producer_id_q === 1'bx) ||
           !producer_live_mask_w[ex1_producer_id_q])) begin
        $display("[V8L-TRANSIENT-LEASE] EX1 has unknown/uncovered P @%0t",
                 $time);
        $fatal;
      end
      if (branch_resolve_stage_valid_w &&
          ((^branch_resolve_payload_producer_id_w === 1'bx) ||
           !producer_live_mask_w[branch_resolve_payload_producer_id_w])) begin
        $display("[V8L-TRANSIENT-LEASE] branch packet has unknown/uncovered P @%0t",
                 $time);
        $fatal;
      end
      if (pending_system_producer_valid_i &&
          ((^pending_system_producer_id_i === 1'bx) ||
           !producer_live_mask_w[pending_system_producer_id_i])) begin
        $display("[V8L-PENDING-CSR-LEASE-UNION] pending CSR has unknown/uncovered P @%0t",
                 $time);
        $fatal;
      end
      if (muldiv_owner_valid_w &&
          ((^muldiv_owner_producer_id_w === 1'bx) ||
           !producer_live_mask_w[muldiv_owner_producer_id_w])) begin
        $display("[V8L-MULDIV-LEASE-UNION] MulDiv owner has unknown/uncovered P @%0t",
                 $time);
        $fatal;
      end
      if (clmul_owner_valid_w &&
          ((^clmul_owner_producer_id_w === 1'bx) ||
           !producer_live_mask_w[clmul_owner_producer_id_w])) begin
        $display("[V8L-CLMUL-LEASE-UNION] CLMUL owner has unknown/uncovered P @%0t",
                 $time);
        $fatal;
      end
      if (miq_head_valid_w && (^miq_head_owner_token_w === 1'bx)) begin
        $display("[V8L-MIQ-TOKEN-KNOWN] valid MIQ head has unknown token @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && miq1_head_valid_w &&
          (^miq1_head_owner_token_w === 1'bx)) begin
        $display("[V8S-MIQ1-TOKEN-KNOWN] valid MIQ1 head has unknown token @%0t",
                 $time);
        $fatal;
      end
      if (mem_pending_q &&
          ((^mem_owner_token_q === 1'bx) ||
           (^mem_producer_id_q === 1'bx) ||
           (mem_owner_producer_id_table_w[
               mem_owner_token_q*PRODUCER_ID_W +: PRODUCER_ID_W] !==
            mem_producer_id_q))) begin
        $display("[V8L-MEM-PENDING-MAP] pending memory token/P mapping is unknown or unstable @%0t",
                 $time);
        $fatal;
      end
      if (mem_buffer_valid_q && (^mem_buffer_owner_token_q === 1'bx)) begin
        $display("[V8L-MEM-BUFFER-TOKEN-KNOWN] valid memory buffer has unknown token @%0t",
                 $time);
        $fatal;
      end
      for (v8l_assert_i = 0; v8l_assert_i < SQ_ENTRY_N;
           v8l_assert_i = v8l_assert_i + 1) begin
        if (sq_snoop_valid_w[v8l_assert_i] &&
            ((^sq_snoop_producer_id_w[
                v8l_assert_i*PRODUCER_ID_W +: PRODUCER_ID_W] === 1'bx) ||
             !producer_live_mask_w[sq_snoop_producer_id_w[
                 v8l_assert_i*PRODUCER_ID_W +: PRODUCER_ID_W]])) begin
          $display("[V8L-SQ-PRODUCER-LEASE] valid SQ entry has unknown/uncovered P entry=%0d @%0t",
                   v8l_assert_i, $time);
          $fatal;
        end
        if (sq_snoop_owner_valid_w[v8l_assert_i] &&
            ((^sq_snoop_owner_token_w[v8l_assert_i*5 +: 5] === 1'bx) ||
             (mem_owner_producer_id_table_w[
                 sq_snoop_owner_token_w[v8l_assert_i*5 +: 5]*PRODUCER_ID_W +:
                 PRODUCER_ID_W] !==
              sq_snoop_producer_id_w[
                  v8l_assert_i*PRODUCER_ID_W +: PRODUCER_ID_W]))) begin
          $display("[V8L-SQ-TRACKER-MAP] bound SQ owner token/P mapping is unknown or unstable entry=%0d @%0t",
                   v8l_assert_i, $time);
          $fatal;
        end
      end
      v8l_mem_capture_shadow_q <= mem_issue_res_capture_w;
      v8l_mem_capture_token_q <= mem_owner_alloc0_token_w;
      v8l_mem_capture_producer_q <= iq_issue0_producer_id_w;
      v8l_mem1_capture_shadow_q <= mem_issue1_res_capture_w;
      v8l_mem1_capture_token_q <= mem_owner_alloc1_token_w;
      v8l_mem1_capture_producer_q <= issue1_producer_id_w;
      v8t_retry0_capture_shadow_q <= mem_sq_retry0_capture_w;
      v8t_retry0_capture_token_q <= mem_sq_query_owner_token_i;
      v8t_retry0_capture_producer_q <= mem_sq_query_producer_id_w;
      v8t_retry1_capture_shadow_q <= mem_sq_retry1_capture_w;
      v8t_retry1_capture_token_q <= mem1_sq_query_owner_token_i;
      v8t_retry1_capture_producer_q <= mem1_sq_query_producer_id_w;
      v8t_retry0_repush_shadow_q <= mem_retry0_req_fire_w;
      v8t_retry0_repush_token_q <= mem_retry0_owner_token_q;
      v8t_retry1_repush_shadow_q <= mem_retry1_req_fire_w;
      v8t_retry1_repush_token_q <= mem_retry1_owner_token_q;
      if (v8g_mem_wb_wait_q && mem_owner_open_w &&
          mem_response_terminal_credit_w && !mem_wb_fire_w) begin
        $display("[V8G-MEM-BOUNDED-COMPLETION] stable open response missed next-cycle completion @%0t",
                 $time);
        $fatal;
      end
      v8g_mem_wb_wait_q <= mem_owner_open_w &&
          mem_response_terminal_credit_w && mem_open_needs_wb_w &&
          !wb_slot_free_w;
      if (mem_req_grant_count_w > 3'd1)
        $error("[T4N-REQ-ONEHOT] multiple request grants=%0d @%0t",
               mem_req_grant_count_w, $time);
      if (mem1_req_grant_count_w > 2'd1)
        $error("[V8S-REQ1-ONEHOT] multiple bank1 request grants=%0d @%0t",
               mem1_req_grant_count_w, $time);
      if (ENABLE_DUAL_MEM && (mem_sq_query_valid_i === 1'b1)) begin
        if (({1'b0, mem_sq_query_allow_o} +
             {1'b0, mem_sq_query_forward_o} +
             {1'b0, mem_sq_query_replay_o}) !== 2'd1) begin
          $display("[V8T-SQ-QUERY0-ONEHOT] valid query decision was unknown/non-onehot @%0t",
                   $time);
          $fatal;
        end
        if ((^mem_sq_query_owner_token_i === 1'bx) ||
            (^mem_sq_query_owner_kind_i === 1'bx) ||
            (^mem_sq_query_mmu_epoch_i === 1'bx) ||
            (^mem_sq_query_paddr_i === 1'bx) ||
            (^mem_sq_query_wstrb_i === 1'bx)) begin
          $display("[V8T-SQ-QUERY0-KNOWN] valid query carried unknown identity/address/mask @%0t",
                   $time);
          $fatal;
        end
        if (!mem_sq_query_exact_w && !mem_sq_query_station_source_w) begin
          $display("[V8T-SQ-QUERY0-EXACT] bridge query did not name exact bank0 MIQ/tracker owner @%0t",
                   $time);
          $fatal;
        end
        if (mem_sq_query_station_source_w &&
            (mem_sq_query_retry_ready_o ||
             (mem_sq_query_exact_w &&
              (!mem_current_rsp_exact_candidate_w ||
               !mem_sq_query_next_miq_exact_w)) ||
             (!mem_sq_query_exact_w && !mem_sq_query_replay_o))) begin
          $display("[V8U-SQ-LOOKAHEAD0-EXACT] station query violated current-owner/next-head/retry contract @%0t",
                   $time);
          $fatal;
        end
      end
      if (ENABLE_DUAL_MEM && (mem1_sq_query_valid_i === 1'b1)) begin
        if (({1'b0, mem1_sq_query_allow_o} +
             {1'b0, mem1_sq_query_forward_o} +
             {1'b0, mem1_sq_query_replay_o}) !== 2'd1) begin
          $display("[V8T-SQ-QUERY1-ONEHOT] valid query decision was unknown/non-onehot @%0t",
                   $time);
          $fatal;
        end
        if ((^mem1_sq_query_owner_token_i === 1'bx) ||
            (^mem1_sq_query_owner_kind_i === 1'bx) ||
            (^mem1_sq_query_mmu_epoch_i === 1'bx) ||
            (^mem1_sq_query_paddr_i === 1'bx) ||
            (^mem1_sq_query_wstrb_i === 1'bx)) begin
          $display("[V8T-SQ-QUERY1-KNOWN] valid query carried unknown identity/address/mask @%0t",
                   $time);
          $fatal;
        end
        if (!mem1_sq_query_exact_w &&
            !mem1_sq_query_station_source_w) begin
          $display("[V8T-SQ-QUERY1-EXACT] bridge query did not name exact bank1 MIQ/tracker owner @%0t",
                   $time);
          $fatal;
        end
        if (mem1_sq_query_station_source_w &&
            (mem1_sq_query_retry_ready_o ||
             (mem1_sq_query_exact_w &&
              (!mem1_current_rsp_exact_candidate_w ||
               !mem1_sq_query_next_miq_exact_w)) ||
             (!mem1_sq_query_exact_w && !mem1_sq_query_replay_o))) begin
          $display("[V8U-SQ-LOOKAHEAD1-EXACT] station query violated current-owner/next-head/retry contract @%0t",
                   $time);
          $fatal;
        end
      end
      if (mem_sq_retry0_capture_w &&
          (!mem_sq_query_exact_w || mem_retry0_valid_q ||
           !miq_pop_owner_match_w || !miq_pop_tval_echo_match_w ||
           miq_pop_transport_w || miq_head_effective_killed_w ||
           mem_terminal_ingress_mask_w[mem_sq_query_owner_token_i])) begin
        $display("[V8T-RETRY0-CAPTURE-ATOMIC] retry capture was not an exact nonterminal MIQ pop @%0t",
                 $time);
        $fatal;
      end
      if (mem_sq_retry1_capture_w &&
          (!mem1_sq_query_exact_w || mem_retry1_valid_q ||
           !miq1_pop_owner_match_w || !miq1_pop_tval_echo_match_w ||
           miq1_pop_transport_w || miq1_head_effective_killed_w ||
           mem_terminal_ingress_mask_w[mem1_sq_query_owner_token_i])) begin
        $display("[V8T-RETRY1-CAPTURE-ATOMIC] retry1 capture was not an exact nonterminal MIQ pop @%0t",
                 $time);
        $fatal;
      end
      if ((mem_sq_retry0_capture_w && miq_pop_transport_w) ||
          (mem_sq_retry1_capture_w && miq1_pop_transport_w)) begin
        $display("[V8T-RETRY-RESPONSE-XOR] one bank tried response-pop and retry-pop together @%0t",
                 $time);
        $fatal;
      end
      if ((mem_drop0_valid_i &&
           (((^mem_drop0_owner_kind_i) === 1'bx) ||
            ((^mem_drop0_owner_token_i) === 1'bx) ||
            ((^mem_drop0_mmu_epoch_i) === 1'bx) ||
            ((^mem_drop0_fault_tval_i) === 1'bx))) ||
          (ENABLE_DUAL_MEM && mem1_drop0_valid_i &&
           (((^mem1_drop0_owner_kind_i) === 1'bx) ||
            ((^mem1_drop0_owner_token_i) === 1'bx) ||
            ((^mem1_drop0_mmu_epoch_i) === 1'bx) ||
            ((^mem1_drop0_fault_tval_i) === 1'bx)))) begin
        $display("[V8W-DROP0-TUPLE-KNOWN] active-owner drop carried unknown identity/provenance @%0t",
                 $time);
        $fatal;
      end
      // A token still resident in this MIQ can only leave through an exact
      // effectively-killed head pop.  A delayed global-flush drop is allowed
      // to find no residency because the flush compactor already removed it.
      if ((mem_drop0_valid_i &&
           miq_occupancy_token_mask_w[mem_drop0_owner_token_i] &&
           (!miq_drop0_pop_w || !miq_pop_owner_match_w ||
            !miq_pop_tval_echo_match_w)) ||
          (ENABLE_DUAL_MEM && mem1_drop0_valid_i &&
           miq1_occupancy_token_mask_w[mem1_drop0_owner_token_i] &&
           (!miq1_drop0_pop_w || !miq1_pop_owner_match_w ||
            !miq1_pop_tval_echo_match_w))) begin
        $display("[V8W-DROP0-MIQ-EXACT] resident bridge drop was not an exact killed-head pop @%0t",
                 $time);
        $fatal;
      end
      if ((miq_drop0_pop_w &&
           (miq_pop_transport_w || mem_sq_retry0_capture_w)) ||
          (miq1_drop0_pop_w &&
           (miq1_pop_transport_w || mem_sq_retry1_capture_w))) begin
        $display("[V8W-DROP0-POP-XOR] one bank tried drop-pop with response/retry pop @%0t",
                 $time);
        $fatal;
      end
      if ((miq_drop0_pop_w &&
           (!mem_terminal_ingress_valid_w[2] || mem_wb_fire_w)) ||
          (miq1_drop0_pop_w &&
           (!mem_terminal_ingress_valid_w[4] || mem1_wb_fire_w))) begin
        $display("[V8W-DROP0-TERMINAL] killed-head pop lost its collector terminal or exposed WB @%0t",
                 $time);
        $fatal;
      end
      if (mem_retry0_req_fire_w &&
          (!mem_retry0_valid_q || !mem_retry0_tracker_exact_w ||
           !push_retry0_w || (miq_push_kind_w != MIQ_KIND_LOAD) ||
           (mem_req_owner_kind_o != mem_retry0_owner_kind_q) ||
           (mem_req_owner_token_o != mem_retry0_owner_token_q) ||
           (mem_req_mmu_epoch_o != mem_retry0_mmu_epoch_q) ||
           (mem_req_fault_tval_o != mem_retry0_fault_tval_q) ||
           (mem_req_addr_o != mem_retry0_addr_q) || mem_req_write_o ||
           mem_req_probe_o || mem_req_pretrans_o || mem_req_attr_valid_o)) begin
        $display("[V8T-RETRY0-REPUSH-ATOMIC] retry0 fire did not reissue/re-push the exact LOAD tuple @%0t",
                 $time);
        $fatal;
      end
      if (mem_retry1_req_fire_w &&
          (!mem_retry1_valid_q || !mem_retry1_tracker_exact_w ||
           !push_retry1_w || (miq1_push_kind_w != MIQ_KIND_LOAD) ||
           (mem1_req_owner_kind_o != mem_retry1_owner_kind_q) ||
           (mem1_req_owner_token_o != mem_retry1_owner_token_q) ||
           (mem1_req_mmu_epoch_o != mem_retry1_mmu_epoch_q) ||
           (mem1_req_fault_tval_o != mem_retry1_fault_tval_q) ||
           (mem1_req_addr_o != mem_retry1_addr_q) || mem1_req_write_o ||
           mem1_req_probe_o || mem1_req_pretrans_o ||
           mem1_req_attr_valid_o)) begin
        $display("[V8T-RETRY1-REPUSH-ATOMIC] retry1 fire did not reissue/re-push the exact LOAD tuple @%0t",
                 $time);
        $fatal;
      end
      if ((mem_retry0_cancel_w &&
           (mem_retry0_req_fire_w || mem_sq_retry0_capture_w)) ||
          (mem_retry1_cancel_w &&
           (mem_retry1_req_fire_w || mem_sq_retry1_capture_w))) begin
        $display("[V8T-RETRY-KILL-XOR] killed retry holder captured or re-pushed @%0t",
                 $time);
        $fatal;
      end
      if ((mem_retry0_valid_q &&
           (mem_bridge_active_load_w || mem_bridge_station_load_w)) ||
          (mem_retry1_valid_q &&
           (mem1_bridge_active_load_w || mem1_bridge_station_load_w))) begin
        $display("[V8T-RETRY-LOAD-FENCE] retry holder overlapped registered same-bank load @%0t",
                 $time);
        $fatal;
      end
      if (mem_sq_query_exact_w && !mem_sq_query_station_source_w &&
          !mem_retry0_valid_q &&
          !flush_i && !checkpoint_restore_apply_w &&
          !mem_sq_query_retry_ready_o) begin
        $display("[V8T-RETRY0-CREDIT-PROGRESS] empty exact retry slot withheld credit @%0t",
                 $time);
        $fatal;
      end
      if (mem1_sq_query_exact_w && !mem1_sq_query_station_source_w &&
          !mem_retry1_valid_q &&
          !flush_i && !checkpoint_restore_apply_w &&
          !mem1_sq_query_retry_ready_o) begin
        $display("[V8T-RETRY1-CREDIT-PROGRESS] empty exact retry slot withheld credit @%0t",
                 $time);
        $fatal;
      end
      if (mem_bank0_store_candidate_w && mem_retry0_candidate_w &&
          (mem_retry0_selected_w == mem_bank0_store_older_than_retry_w)) begin
        $display("[V8T-RETRY0-STORE-AGE] bank0 store/retry arbitration violated edge-old age @%0t",
                 $time);
        $fatal;
      end
      if (mem_bank1_store_candidate_w && mem_retry1_candidate_w &&
          (mem_retry1_selected_w == mem_bank1_store_older_than_retry_w)) begin
        $display("[V8T-RETRY1-STORE-AGE] bank1 store/retry arbitration violated edge-old age @%0t",
                 $time);
        $fatal;
      end
      if ((issue0_dual_selected_w && issue0_is_load_w &&
           !issue0_is_amo_w && issue0_dual_load_admission_block_w) ||
          (issue1_dual_selected_w && issue1_is_load_w &&
           !issue1_is_amo_w && issue1_dual_load_admission_block_w)) begin
        $display("[V8T-LOAD-ADMISSION-FENCE] second ordinary LOAD entered an occupied bank @%0t",
                 $time);
        $fatal;
      end
      if ((mem_retry0_valid_q &&
           ((mem_retry0_owner_kind_q != MEM_OWNER_LOAD) ||
            mem_retry0_addr_q[3] ||
            miq_occupancy_token_mask_w[mem_retry0_owner_token_q] ||
            mem_bridge_owner_residency_mask_i[mem_retry0_owner_token_q])) ||
          (mem_retry1_valid_q &&
           ((mem_retry1_owner_kind_q != MEM_OWNER_LOAD) ||
            !mem_retry1_addr_q[3] ||
            miq1_occupancy_token_mask_w[mem_retry1_owner_token_q] ||
            mem1_bridge_owner_residency_mask_i[mem_retry1_owner_token_q]))) begin
        $display("[V8T-RETRY-HOLDER-EXACT] retry holder had wrong kind/bank or duplicate residency @%0t",
                 $time);
        $fatal;
      end
      if ((grant_sq_w || grant_amo_write_w || grant_buffer_w) &&
          (grant_retry1_w || grant_mem1_issue0_w || grant_mem1_issue1_w))
        $error("[V8S-SINGLETON-DUAL-EXCLUSION] singleton/SQ launch overlapped bank1 ordinary request @%0t",
               $time);
      if (mem_req_fire_any_w && mem1_req_fire_any_w &&
          (mem_req_addr_o[3] == mem1_req_addr_o[3]))
        $error("[V8S-SAME-BANK-DUAL-FIRE] two requests fired into one captured bank @%0t",
               $time);
      if (sq_drain_req_fire_w &&
          (mem_buffer_req_fire_w || mem_retry0_req_fire_w ||
           mem_retry1_req_fire_w || issue0_mem_request_fire_w ||
           issue1_mem_request_fire_w || push_amo_write_w))
        $error("[T4N-SQ-PRIORITY] SQ fire overlapped younger/other fire @%0t",
               $time);
      if (sq_drain_req_fire_w && !sq_drain_launch_authorized_w) begin
        $display("[V8G-SQ-LAUNCH-AUTH] physical STORE fired without exact capability/PID/head @%0t",
                 $time);
        $fatal;
      end
      if (push_amo_write_w && !mem_amo_launch_authorized_w) begin
        $display("[V8G-AMO-LAUNCH-AUTH] AMO write fired without exact capability/PID/head @%0t",
                 $time);
        $fatal;
      end
      if (checkpoint_restore_apply_w &&
          (checkpoint_irrevocable_write_q || !sq_no_active_write_w ||
           drain_inflight_q)) begin
        $display("[V8V-CHECKPOINT-APPLY-IRREVOCABLE] recovery applied before physical write retirement @%0t",
                 $time);
        $fatal;
      end
      if (checkpoint_restore_hold_w &&
          (dispatch0_fire_w || dispatch1_fire_w || issue0_fire_w ||
           issue1_fire_w || mem_issue_res_capture_w ||
           mem_issue1_res_capture_w || mem_req_fire_any_w ||
           mem1_req_fire_any_w || miq_push_valid_w ||
           miq1_push_valid_w)) begin
        $display("[V8V-CHECKPOINT-HOLD-ADMISSION] pending restore admitted a new backend owner @%0t",
                 $time);
        $fatal;
      end
      if (checkpoint_restore_pending_q && commit1_valid_o) begin
        $display("[V8V-CHECKPOINT-COMMIT1] younger lane retired beside the irreversible owner @%0t",
                 $time);
        $fatal;
      end
      if (checkpoint_restore_pending_q && commit0_valid_o &&
          (!checkpoint_irrevocable_write_q ||
           (rob_commit0_producer_id_w !=
            checkpoint_irrevocable_write_pid_q))) begin
        $display("[V8V-CHECKPOINT-COMMIT0-OWNER] pending restore retired a non-physical-write owner @%0t",
                 $time);
        $fatal;
      end
      if (checkpoint_irrevocable_write_launch_w &&
          checkpoint_irrevocable_write_q) begin
        $display("[V8V-IRREVOCABLE-WRITE-DUP] second physical write launched before first retirement @%0t",
                 $time);
        $fatal;
      end
      if (checkpoint_irrevocable_write_q &&
          !checkpoint_irrevocable_write_live_mask_w[
              checkpoint_irrevocable_write_pid_q]) begin
        $display("[V8V-IRREVOCABLE-WRITE-LEASE-MASK] physical write owner missing from ProducerId birth fence @%0t",
                 $time);
        $fatal;
      end
      if (checkpoint_restore_pending_q && checkpoint_irrevocable_write_q &&
          (!rob_head_valid_w ||
           (rob_head_producer_id_w != checkpoint_irrevocable_write_pid_q))) begin
        $display("[V8V-CHECKPOINT-WRITE-ROB-OWNER] pending physical write lost exact ROB head @%0t",
                 $time);
        $fatal;
      end
      if (mem_amo_write_sent_q && mem_pending_q &&
          (!mem_amo_tracker_exact_w || !rob_head_launch_open_w ||
           (mem_amo_tracker_producer_id_w != mem_producer_id_q) ||
           (mem_producer_id_q != rob_head_producer_id_w))) begin
        $display("[V8G-AMO-POST-LAUNCH-OPEN] issued AMO lost exact-open ROB head before final response @%0t",
                 $time);
        $fatal;
      end
      if (sq_drain_valid_w &&
          ((sq_drain_addr_w !==
            sq_snoop_paddr_w[sq_snoop_head_w*`XLEN +: `XLEN]) ||
           (sq_drain_attr_valid_w !==
            sq_snoop_attr_valid_w[sq_snoop_head_w]) ||
           (sq_drain_class_w !==
            sq_snoop_class_w[sq_snoop_head_w*2 +: 2]) ||
           (sq_drain_cacheable_w !==
            sq_snoop_cacheable_w[sq_snoop_head_w])))
        $error("[R4-S0-SQ-PHYSICAL-VIEW] drain context drifted from SQ head @%0t",
               $time);
      if (mem_req_valid_o && !mem_req_pretrans_o &&
          ((mem_req_attr_valid_o !== 1'b0) ||
           (mem_req_class_o !== `OOO_MEM_CLASS_RSVD)))
        $error("[S1-TYPED-ORDINARY-POISON] ordinary VA request carried provenance @%0t",
               $time);
      if (mem_req_valid_o && mem_req_pretrans_o &&
          !typed_mem_attr_admitted(mem_req_attr_valid_o, mem_req_class_o))
        $error("[S1-TYPED-PRETRANS-INVALID] SQ drain lacked typed provenance @%0t",
               $time);
      if (mem_rsp_valid_i &&
          (mem_rsp_cacheable_i !==
           (mem_rsp_attr_admitted_w &&
            (mem_rsp_class_i == `OOO_MEM_CLASS_CACHED))))
        $error("[S1-TYPED-RSP-LEGACY] response legacy cacheable disagreed with typed class @%0t",
               $time);
      if (sq_mode_w && miq_probe_rsp_fire_w && mem_owner_open_w &&
          !mem_rsp_fault_w && !mem_rsp_attr_admitted_w)
        $error("[S1-TYPED-PROBE-MISSING] successful probe lacked admitted provenance @%0t",
               $time);
      if ((flush_i || checkpoint_restore_hold_w) &&
          (mem_req_fire_any_w || miq_push_valid_w ||
           mem1_req_fire_any_w || miq1_push_valid_w))
        $error("[S2-G1-RESTORE-REQ-GATE] flush/restore allowed request/MIQ push @%0t",
               $time);
      if (mem_amo_interphase_cancel_w &&
          (mem_owner_kind_q != MEM_OWNER_ATOMIC))
        $error("[S2-G1-AMO-INTERPHASE-KIND] cancel owner was not ATOMIC @%0t",
               $time);
      if (mem_amo_interphase_cancel_w &&
          (mem_req_fire_any_w || miq_push_valid_w ||
           mem1_req_fire_any_w || miq1_push_valid_w))
        $error("[S2-G1-AMO-INTERPHASE-FIRE] cancel overlapped request/MIQ push @%0t",
               $time);
      if (mem_amo_interphase_cancel_w &&
          ((mem_terminal_ingress9_mask_w &
            (mem_terminal_ingress0_mask_w |
             mem_terminal_ingress1_mask_w |
             mem_terminal_ingress2_mask_w |
             mem_terminal_ingress3_mask_w |
             mem_terminal_ingress4_mask_w |
             mem_terminal_ingress5_mask_w)) != 32'b0))
        $error("[S2-G1-AMO-INTERPHASE-DUP] cancel duplicated response/drop terminal @%0t",
               $time);
      if ((mem_retry0_cancel_w &&
           ((mem_retry0_owner_kind_q != MEM_OWNER_LOAD) ||
            !mem_terminal_ingress_valid_w[10] ||
            mem_terminal_pending_mask_w[mem_retry0_owner_token_q] ||
            ((mem_terminal_ingress10_mask_w &
              (mem_terminal_ingress0_mask_w |
               mem_terminal_ingress1_mask_w |
               mem_terminal_ingress2_mask_w |
               mem_terminal_ingress3_mask_w |
               mem_terminal_ingress4_mask_w |
               mem_terminal_ingress5_mask_w |
               mem_terminal_ingress6_mask_w |
               mem_terminal_ingress7_mask_w |
               mem_terminal_ingress8_mask_w |
               mem_terminal_ingress9_mask_w |
               mem_terminal_ingress11_mask_w)) != 32'b0))) ||
          (mem_retry1_cancel_w &&
           ((mem_retry1_owner_kind_q != MEM_OWNER_LOAD) ||
            !mem_terminal_ingress_valid_w[11] ||
            mem_terminal_pending_mask_w[mem_retry1_owner_token_q] ||
            ((mem_terminal_ingress11_mask_w &
              (mem_terminal_ingress0_mask_w |
               mem_terminal_ingress1_mask_w |
               mem_terminal_ingress2_mask_w |
               mem_terminal_ingress3_mask_w |
               mem_terminal_ingress4_mask_w |
               mem_terminal_ingress5_mask_w |
               mem_terminal_ingress6_mask_w |
               mem_terminal_ingress7_mask_w |
               mem_terminal_ingress8_mask_w |
               mem_terminal_ingress9_mask_w |
               mem_terminal_ingress10_mask_w)) != 32'b0)))) begin
        $display("[V8T-RETRY-CANCEL-TERMINAL] retry cancel lost or duplicated its exact LOAD terminal @%0t",
                 $time);
        $fatal;
      end
      if (mem_issue_res_capture_w &&
          mem_terminal_ingress_mask_w[mem_owner_alloc0_token_w])
        $error("[S2-G1-ALLOC-TERMINAL-ALIAS] new allocation aliased terminal ingress @%0t",
               $time);
      if (mem_issue1_res_capture_w &&
          mem_terminal_ingress_mask_w[mem_owner_alloc1_token_w])
        $error("[V8P-ALLOC1-TERMINAL-ALIAS] new allocation1 aliased terminal ingress @%0t",
               $time);
      if (mem_buffer_kill_w && !mem_buffer_cancel_w)
        $error("[V8G-MEM-BUFFER-KILL-TERMINAL] killed buffer lost local terminal @%0t",
               $time);
      if (mem_issue_res_consume_fire_w && issue0_is_plain_store_w &&
          issue0_mem_exception_w &&
          !((sq_terminal0_valid_w &&
             (sq_terminal0_rob_w == mem_issue_res_rob_idx_q)) ||
            (sq_terminal1_valid_w &&
             (sq_terminal1_rob_w == mem_issue_res_rob_idx_q))))
        $error("[T4N-SQ-LOCAL-TERMINAL] local store exception lost SQ terminal owner @%0t",
               $time);
      if (mem_issue1_res_consume_fire_w && issue1_is_plain_store_w &&
          issue1_mem_exception_w &&
          !((sq_terminal0_valid_w &&
             (sq_terminal0_rob_w == mem_issue1_res_rob_idx_q)) ||
            (sq_terminal1_valid_w &&
             (sq_terminal1_rob_w == mem_issue1_res_rob_idx_q))))
        $error("[V8P-SQ-LOCAL1-TERMINAL] local store exception lost SQ terminal1 owner @%0t",
               $time);
      if (sq_response_terminal_w && sq_local_store_exception_w &&
          (miq_head_rob_w == sq_local_store_exception_rob_w))
        $error("[T4N-SQ-DUAL-TERMINAL-TAG] independent terminal sources aliased ROB tag=%0d @%0t",
               miq_head_rob_w, $time);
      if (sq_terminal0_valid_w && sq_terminal1_valid_w &&
          (sq_terminal0_token_w == sq_terminal1_token_w))
        $error("[V8S-SQ-TERMINAL-TOKEN-ALIAS] two SQ terminal ports named one owner token @%0t",
               $time);
      if (miq_drain_rsp_wants_w && mem_owner_open_w &&
          !mem_wb_route_credit_w && mem_rsp_ready_o)
        $error("[T4N-B-WB-CREDIT] B consumed without formal WB credit @%0t",
               $time);
      if (miq_drain_rsp_fire_w && mem_owner_open_w &&
          !miq_drain_wb_fire_w)
        $error("[T4N-B-UNIQUE-WB] B terminal lacked unique WB @%0t", $time);
      if (sq_mode_w && miq_probe_rsp_fire_w &&
          !miq_head_effective_killed_w &&
          !mem_rsp_fault_w && miq_probe_wb_fire_w)
        $error("[T4N-PROBE-NO-DONE] successful probe generated WB @%0t", $time);
      if (sq_commit1_store_w)
        $error("[T4N-STORE-COMMIT1] store bypassed ROB-head terminal release @%0t",
               $time);
      if (mem_response_tuple_exact_w &&
          ((mem_owner_open_w ? 1 : 0) +
           (mem_legal_closed_response_w ? 1 : 0) +
           (mem_fatal_irrevocable_response_w ? 1 : 0) != 1)) begin
        $display("[V8G-MEM-OWNER-CLASS] exact response classification is not onehot @%0t",
                 $time);
        $fatal;
      end
      if (!mem_response_tuple_exact_w &&
          (mem_owner_open_w || mem_legal_closed_response_w ||
           mem_fatal_irrevocable_response_w)) begin
        $display("[V8G-MEM-OWNER-CLASS] tuple mismatch entered an owner class @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && mem1_response_tuple_exact_w &&
          ((mem1_owner_open_w ? 1 : 0) +
           (mem1_legal_closed_response_w ? 1 : 0) +
           (mem1_fatal_response_w ? 1 : 0) != 1)) begin
        $display("[V8S-MEM1-OWNER-CLASS] exact bank1 response classification is not onehot @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && !mem1_response_tuple_exact_w &&
          (mem1_owner_open_w || mem1_legal_closed_response_w ||
           mem1_fatal_response_w)) begin
        $display("[V8S-MEM1-OWNER-CLASS] bank1 tuple mismatch entered an owner class @%0t",
                 $time);
        $fatal;
      end
      if (mem_wb_fire_w &&
          (!mem_owner_open_w || !miq_head_tracker_exact_w ||
           !mem_completion_rob_open_w ||
           (mem_completion_producer_id_w[ROB_INDEX_W-1:0] !=
            miq_head_rob_w))) begin
        $display("[V8G-MEM-COMPLETION-AUTH] memory WB escaped exact PID/open gate @%0t",
                 $time);
        $fatal;
      end
      if (mem_owner_open_w && !mem_open_all_sink_credit_w &&
          (miq_pop_w || mem_wb_fire_w || sq_fill_probe_w ||
           sq_response_terminal_w)) begin
        $display("[V8G-MEM-OPEN-HOLD] open response produced side effect without all credit @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && mem1_wb_fire_w &&
          (!mem1_owner_open_w || !miq1_head_tracker_exact_w ||
           !mem1_completion_rob_open_w ||
           (mem1_completion_producer_id_w[ROB_INDEX_W-1:0] !=
            miq1_head_rob_w))) begin
        $display("[V8S-MEM1-COMPLETION-AUTH] bank1 WB escaped exact PID/open gate @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && mem1_owner_open_w &&
          !mem1_open_all_sink_credit_w &&
          (miq1_pop_w || mem1_wb_fire_w || sq_fill1_probe_w ||
           sq_response1_terminal_w)) begin
        $display("[V8S-MEM1-OPEN-HOLD] bank1 open response produced side effect without all credit @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && mem1_fatal_response_w && miq1_pop_w &&
          (mem1_wb_fire_w || mem_terminal_ingress_valid_w[1] ||
           sq_fill1_probe_w || sq_response1_terminal_w)) begin
        $display("[V8S-MEM1-FATAL-POISON] bank1 fatal response entered normal completion/death path @%0t",
                 $time);
        $fatal;
      end
      if (mem_fatal_irrevocable_response_w && miq_pop_w &&
          (mem_wb_fire_w || mem_terminal_ingress_valid_w[0] ||
           sq_fill_probe_w || sq_response_terminal_w)) begin
        $display("[V8G-MEM-FATAL-POISON] fatal response entered normal completion/death path @%0t",
                 $time);
        $fatal;
      end
      if (mem_fatal_irrevocable_response_w && miq_pop_w) begin
        $display("[V8G-MEM-FATAL-IRREVOCABLE] closed STORE/AMO or tracker-tag violation drained into poison @%0t",
                 $time);
        $fatal;
      end
      if (mem_response_tuple_exact_w && !miq_head_tracker_exact_w &&
          (mem_wb_fire_w || mem_terminal_ingress_valid_w[0])) begin
        $display("[V8G-MEM-TRACKER-EXACT] tracker tag mismatch completed or freed owner @%0t",
                 $time);
        $fatal;
      end
      if (mem_amo_read_rsp_w && !mem_owner_open_w) begin
        $display("[V8G-AMO-READ-OPEN] closed AMO response entered write phase @%0t",
                 $time);
        $fatal;
      end
      if (mem_terminal_ingress_valid_w[0] &&
          !mem_response_terminal_credit_w) begin
        $display("[V8G-MEM-TERMINAL-CREDIT] response terminal bypassed collector credit @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && mem_terminal_ingress_valid_w[1] &&
          !mem1_response_terminal_credit_w) begin
        $display("[V8S-MEM1-TERMINAL-CREDIT] bank1 response terminal bypassed collector credit @%0t",
                 $time);
        $fatal;
      end
      if (miq_head_tracker_exact_w &&
          (mem_completion_producer_id_w[ROB_INDEX_W-1:0] !=
           miq_head_rob_w)) begin
        $display("[V8G-MEM-PID-INDEX] token PID=%h raw=%h @%0t",
                 mem_completion_producer_id_w, miq_head_rob_w, $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && miq1_head_tracker_exact_w &&
          (mem1_completion_producer_id_w[ROB_INDEX_W-1:0] !=
           miq1_head_rob_w)) begin
        $display("[V8S-MEM1-PID-INDEX] token PID=%h raw=%h @%0t",
                 mem1_completion_producer_id_w, miq1_head_rob_w, $time);
        $fatal;
      end
      if (mem_req_device_release_o &&
          (!miq_head_tracker_exact_w || !rob_head_launch_open_w ||
           (mem_completion_producer_id_w != rob_head_producer_id_w))) begin
        $display("[V8G-MEM-DEVICE-RELEASE] device release escaped full-PID/head gate @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM && mem1_req_device_release_o &&
          (!miq1_head_tracker_exact_w || !rob_head_launch_open_w ||
           (mem1_completion_producer_id_w != rob_head_producer_id_w))) begin
        $display("[V8S-MEM1-DEVICE-RELEASE] bank1 device release escaped full-PID/head gate @%0t",
                 $time);
        $fatal;
      end
      if (ENABLE_DUAL_MEM &&
          ((miq_occupancy_token_mask_w & miq1_occupancy_token_mask_w) !=
           32'b0)) begin
        $display("[V8S-DUAL-MIQ-TOKEN-DISJOINT] one owner token resided in both MIQs @%0t",
                 $time);
        $fatal;
      end
      if (mem_fpld_wb_valid_w && mem1_fpld_wb_valid_w) begin
        $display("[V8S-FPLD-SINGLE-SINK] two FP loads reached the single FP write sink @%0t",
                 $time);
        $fatal;
      end
      // T4M load-bearing deadlock guard: an older filled/probing store must keep
      // a translated younger load out of the bridge's post-translate device wait.
      if (mem_translate_active_i && issue0_is_load_w &&
          issue0_load_waits_for_inflight_store_w && issue0_mem_req_valid_w)
        $error("[T4N-T4M-DEVICE-DEADLOCK] translated younger load escaped older-store block @%0t",
               $time);
    end
  end
`endif

  assign commit0_is_fp_rd_o = commit0_is_fp_rd_w;
  assign commit1_is_fp_rd_o = commit1_is_fp_rd_w;

endmodule
