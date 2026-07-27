`include "define.v"

// ROB 是乱序执行和精确提交之间的边界：执行可乱序完成，
// 但对外 commit、异常和旧物理寄存器释放必须按 head 顺序发生。
module OooRob #(
  parameter ROB_ENTRIES = (1 << `OOO_ROB_INDEX_W),
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W
) (
  input clk,
  input rst,
  input flush_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  output [ROB_INDEX_W-1:0] dispatch0_rob_idx_o,
  output [PRODUCER_ID_W-1:0] dispatch0_producer_id_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input dispatch0_rd_en_i,
  // 【B-FP Phase0 地基】FPR 目的标记: commit 时写架构 FPR 而非 GPR(arch_rd 复用为
  // FPR 号)。fflags 随 wb 回填、随 commit 输出。接 0 时行为与旧版逐位一致。
  input dispatch0_is_fp_rd_i,
  input [`REG_ADDR_W-1:0] dispatch0_arch_rd_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_old_pdest_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_new_pdest_i,

  input dispatch1_valid_i,
  output dispatch1_ready_o,
  output [ROB_INDEX_W-1:0] dispatch1_rob_idx_o,
  output [PRODUCER_ID_W-1:0] dispatch1_producer_id_o,
  // Q-only candidate for an atomic two-lane parent decision.  Unlike the
  // standalone lane1 presentation above, it never depends on lane0 fire.
  output [PRODUCER_ID_W-1:0] dispatch1_pair_producer_id_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input dispatch1_rd_en_i,
  input dispatch1_is_fp_rd_i,
  input [`REG_ADDR_W-1:0] dispatch1_arch_rd_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_old_pdest_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_new_pdest_i,

  input wb0_valid_i,
  input [ROB_INDEX_W-1:0] wb0_rob_idx_i,
  input [`XLEN-1:0] wb0_data_i,
  input wb0_exception_i,
  input [`TRAP_CAUSE_W-1:0] wb0_cause_i,
  input [`XLEN-1:0] wb0_tval_i,
  input [4:0] wb0_fflags_i,
  input [PHY_REG_ADDR_W-1:0] wb0_pdest_i,   // A1 生产者身份哨兵(UC-A)

  input wb1_valid_i,
  input [ROB_INDEX_W-1:0] wb1_rob_idx_i,
  input [`XLEN-1:0] wb1_data_i,
  input wb1_exception_i,
  input [`TRAP_CAUSE_W-1:0] wb1_cause_i,
  input [`XLEN-1:0] wb1_tval_i,
  input [4:0] wb1_fflags_i,
  input [PHY_REG_ADDR_W-1:0] wb1_pdest_i,   // A1 生产者身份哨兵(UC-A)

  // v8f scoped ProducerId authorization queries.  The current queries serve
  // issue-time early wake; completion-open additionally requires !done.  All
  // queries are Q-only observations and must never enter transport READY.
  input current0_query_valid_i,
  input [PRODUCER_ID_W-1:0] current0_query_producer_id_i,
  output current0_query_match_o,
  input current1_query_valid_i,
  input [PRODUCER_ID_W-1:0] current1_query_producer_id_i,
  output current1_query_match_o,
  input completion0_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion0_query_producer_id_i,
  output completion0_query_match_o,
  input completion1_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion1_query_producer_id_i,
  output completion1_query_match_o,
  input completion2_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion2_query_producer_id_i,
  output completion2_query_match_o,
  input completion3_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion3_query_producer_id_i,
  output completion3_query_match_o,
  input completion4_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion4_query_producer_id_i,
  output completion4_query_match_o,
  input completion5_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion5_query_producer_id_i,
  output completion5_query_match_o,
  input completion6_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion6_query_producer_id_i,
  output completion6_query_match_o,
  input completion7_query_valid_i,
  input [PRODUCER_ID_W-1:0] completion7_query_producer_id_i,
  output completion7_query_match_o,
  // v8j registered branch-resolve authority.  Unlike completion queries,
  // this edge-old lookup deliberately ignores the current kill input: the
  // only current kill source is the authorized branch itself, so reading it
  // here would close a combinational self-feedback loop.  Prior recovery is
  // still a hard death edge through recover_q.
  input resolve_query_valid_i,
  input [PRODUCER_ID_W-1:0] resolve_query_producer_id_i,
  output resolve_query_match_o,

  input commit_ready_i,
  // V9O edge-old terminal permit.  Unlike commit_ready_i this input must not
  // include current completion/WB bypasses, because it feeds C0 pregrant.
  input commit_pregrant_ready_i,
  input commit1_block_i,
  // 【serialize-at-retire Phase1 §9 修向①】mem 静默门控: head0-CSR 退休拍会触发 serial_flush,
  // 若此时 LSU/MIQ 有在飞 AXI(store probe/drain), serial_flush→mem_flush→lsu_axi_abort 会中止它
  // → 更老 store 卡队头 head_done=0 → backend_drained 恒假 → drain-based trap 死锁。故 head0-CSR
  // 必须等 mem_quiet(=mem_idle && mem_retire_quiet, 即 MIQ 空+SQ 排空+无在飞)才退休。此门控放在
  // commit0_fire(而非 ControlPlane 的 commit_ready)是为避开 commit_ready→commit0_valid→core_commit0_csr
  // 组合环; head0_is_csr_w 只看 inst_q/done/exception, 不依赖 commit_ready。
  input mem_quiet_i,
  // S2-Q2 v8a：未来 context/FENCE.I owner 的末端准入。当前 live top 精确
  // tie-high，因此只预埋接口，不改变退休行为。
  input head0_context_permit_i,
  input fencei_retire_permit_i,
  // V9O：pending-system CSR lease 已由 ControlPlane 的 CSR 类型与 ProducerId
  // 出生合同限定。ROB 只接受该 edge-old typed owner identity，并与当前 head0
  // ProducerId 精确比较；不能用“存在任意 pending owner”替代队首所有权判定。
  input pending_csr_owner_valid_i,
  input [PRODUCER_ID_W-1:0] pending_csr_owner_producer_id_i,
  output head0_retire_candidate_valid_o,
  output head0_identity_valid_o,
  output [`OOO_CONTEXT_ID_W-1:0] head0_identity_o,
  output [PRODUCER_ID_W-1:0] head0_producer_id_o,
  output head0_owner_open_o,
  output head0_launch_open_o,
  output head0_control_event_pregrant_o,
  output head0_full_flush_pregrant_o,
  output [`REDIR_REASON_W-1:0] head0_full_flush_reason_o,
  output commit0_valid_o,
  output [PRODUCER_ID_W-1:0] commit0_producer_id_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output commit0_rd_en_o,
  output commit0_is_fp_rd_o,
  output [4:0] commit0_fflags_o,
  output [`REG_ADDR_W-1:0] commit0_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit0_new_pdest_o,
  output [`XLEN-1:0] commit0_data_o,
  output commit0_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit0_cause_o,
  output [`XLEN-1:0] commit0_tval_o,

  output commit1_valid_o,
  output [PRODUCER_ID_W-1:0] commit1_producer_id_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output commit1_rd_en_o,
  output commit1_is_fp_rd_o,
  output [4:0] commit1_fflags_o,
  output [`REG_ADDR_W-1:0] commit1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit1_new_pdest_o,
  output [`XLEN-1:0] commit1_data_o,
  output commit1_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit1_cause_o,
  output [`XLEN-1:0] commit1_tval_o,

  output [ROB_INDEX_W-1:0] head_idx_o,
  output head_valid_o,
  output [ROB_COUNT_W-1:0] count_o,
  output empty_o,
  output full_o,

  // B2 ROB-walk 误预测恢复：给定存活分支 rob_idx，多周期反向 walk 把严格更年轻的 uop squash，
  // 并逐拍(2/拍)emit 其 arch_rd/old_pdest/new_pdest 供 rename 还原 + free-list 回收。
  // 详见 design/arch/b2-branch-spec-redirect.md §4.1。当前由已寄存、同源的 branch
  // mispredict packet 驱动；walk_* 已接 rename/free-list 恢复端口。
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,    // 存活分支 idx；squash 严格更年轻者(R+1..tail-1)
  output recover_active_o,                   // walk 进行中：核需冻结 dispatch/commit/wb
  output walk0_valid_o,
  output [PRODUCER_ID_W-1:0] walk0_producer_id_o,
  output [`REG_ADDR_W-1:0] walk0_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] walk0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] walk0_new_pdest_o,
  output walk0_rd_en_o,
  output walk0_is_fp_o,
  output walk1_valid_o,
  output [PRODUCER_ID_W-1:0] walk1_producer_id_o,
  output [`REG_ADDR_W-1:0] walk1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] walk1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] walk1_new_pdest_o,
  output walk1_rd_en_o,
  output walk1_is_fp_o
);

  reg valid_q [0:ROB_ENTRIES-1];
  reg done_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] pc_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] next_pc_q [0:ROB_ENTRIES-1];
  reg [`INST_W-1:0] inst_q [0:ROB_ENTRIES-1];
  reg rd_en_q [0:ROB_ENTRIES-1];
  reg [`REG_ADDR_W-1:0] arch_rd_q [0:ROB_ENTRIES-1];
  reg [PHY_REG_ADDR_W-1:0] old_pdest_q [0:ROB_ENTRIES-1];
  reg [PHY_REG_ADDR_W-1:0] new_pdest_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] data_q [0:ROB_ENTRIES-1];
  reg exception_q [0:ROB_ENTRIES-1];
  reg [`TRAP_CAUSE_W-1:0] cause_q [0:ROB_ENTRIES-1];
  reg [`XLEN-1:0] tval_q [0:ROB_ENTRIES-1];
  // 【B-FP Phase0 地基】
  reg is_fp_rd_q [0:ROB_ENTRIES-1];
  reg [4:0] fflags_q [0:ROB_ENTRIES-1];

  // v8e P1：每槽最近一次 accepted allocation 的 generation。它只建立
  // allocation-issued 编码真源；没有 global-live collision fence 时仍不可用于 active 授权。
  reg [PRODUCER_GEN_W-1:0] slot_generation_q [0:ROB_ENTRIES-1];

  reg [ROB_INDEX_W-1:0] head_q;
  reg [ROB_INDEX_W-1:0] tail_q;
  reg [ROB_COUNT_W-1:0] count_q;

  // B2 ROB-walk 恢复状态机
`ifdef ROB_WALK_DEBUG
  reg [11:0] rob_stall_cnt_q;
`endif
  reg recover_q;
  reg [ROB_INDEX_W-1:0] walk_ptr_q;   // 当前待 squash 的最年轻未处理 entry
  reg [ROB_INDEX_W-1:0] kill_idx_q;   // 存活分支 idx（walk 终点：到它即停）

  wire [ROB_INDEX_W-1:0] head1_w;
  wire head_done_w;
  wire head1_done_w;
  wire [`XLEN-1:0] head_data_w;
  wire [`XLEN-1:0] head1_data_w;
  wire head_exception_w;
  wire head1_exception_w;
  wire [`TRAP_CAUSE_W-1:0] head_cause_w;
  wire [`TRAP_CAUSE_W-1:0] head1_cause_w;
  wire [`XLEN-1:0] head_tval_w;
  wire [`XLEN-1:0] head1_tval_w;
  wire [4:0] head_fflags_w;
  wire [4:0] head1_fflags_w;
  wire commit0_fire_w;
  wire commit1_fire_w;
  wire head0_base_ready_w;
  wire [1:0] commit_count_w;
  wire [ROB_COUNT_W-1:0] free_slots_w;
  wire dispatch0_fire_w;
  wire dispatch1_fire_w;
  wire [1:0] dispatch_count_w;

  integer idx;

  function [ROB_INDEX_W-1:0] rob_ptr_add;
    input [ROB_INDEX_W-1:0] base;
    input [1:0] inc;
    begin
      rob_ptr_add = base + {{(ROB_INDEX_W-2){1'b0}}, inc};
    end
  endfunction

  assign head1_w = rob_ptr_add(head_q, 2'd1);
  // T3W retirement boundary: writeback is absorbed by ROB state on this edge;
  // commit validity and every commit payload are generated only from Q on the
  // following cycle.  The former same-cycle head bypass let a D-cache SRAM
  // response traverse memory arbitration, ROB matching, CSR ownership and the
  // architectural CSR flops in one cycle.  Wakeup/PRF write latency is
  // unchanged; only completion-to-retirement gains one cycle.
  assign head_done_w = done_q[head_q];
  assign head1_done_w = done_q[head1_w];
  assign head_data_w = data_q[head_q];
  assign head1_data_w = data_q[head1_w];
  assign head_exception_w = exception_q[head_q];
  assign head1_exception_w = exception_q[head1_w];
  assign head_cause_w = cause_q[head_q];
  assign head1_cause_w = cause_q[head1_w];
  assign head_fflags_w = fflags_q[head_q];
  assign head1_fflags_w = fflags_q[head1_w];
  assign head_tval_w = tval_q[head_q];
  assign head1_tval_w = tval_q[head1_w];
  // ---- B2 ROB-walk 恢复（组合）----
  wire [ROB_INDEX_W-1:0] kill_next_start_w = rob_ptr_add(kill_rob_idx_i, 2'd1);
  wire kill_has_younger_w = kill_valid_i && (tail_q != kill_next_start_w);
  // 冻结 dispatch/commit/wb：必须在「kill 脉冲当拍」就冻结，与 IQ 的 squash/issue-gate（均按 kill_valid_i）
  // 严格一致；否则 kill 当拍 ROB 仍放新指令进 ROB、而 IQ 把它的发射项 squash 掉 → 僵尸 ROB 项永不 done。
  wire recovering_w = recover_q || kill_valid_i;
  wire [ROB_INDEX_W-1:0] wptr_m1_w = walk_ptr_q - {{(ROB_INDEX_W-1){1'b0}}, 1'b1};
  wire [ROB_INDEX_W-1:0] kill_next_q_w = rob_ptr_add(kill_idx_q, 2'd1);
  wire lane0_sq_w = recover_q;                           // 不变量：recover 期 walk_ptr_q 恒为更年轻 entry
  wire lane1_sq_w = recover_q && (wptr_m1_w != kill_idx_q);
  wire last_one_w = recover_q && (wptr_m1_w == kill_idx_q);
  wire last_two_w = recover_q && (wptr_m1_w != kill_idx_q) &&
                    ((walk_ptr_q - {{(ROB_INDEX_W-2){1'b0}}, 2'd2}) == kill_idx_q);
  wire walk_done_w = last_one_w || last_two_w;

  assign recover_active_o   = recover_q;
  assign walk0_valid_o      = lane0_sq_w;
  assign walk0_producer_id_o = {slot_generation_q[walk_ptr_q], walk_ptr_q};
  assign walk0_arch_rd_o    = arch_rd_q[walk_ptr_q];
  assign walk0_old_pdest_o  = old_pdest_q[walk_ptr_q];
  assign walk0_new_pdest_o  = new_pdest_q[walk_ptr_q];
  assign walk0_rd_en_o      = rd_en_q[walk_ptr_q];
  assign walk0_is_fp_o      = is_fp_rd_q[walk_ptr_q];
  assign walk1_valid_o      = lane1_sq_w;
  assign walk1_producer_id_o = {slot_generation_q[wptr_m1_w], wptr_m1_w};
  assign walk1_arch_rd_o    = arch_rd_q[wptr_m1_w];
  assign walk1_old_pdest_o  = old_pdest_q[wptr_m1_w];
  assign walk1_new_pdest_o  = new_pdest_q[wptr_m1_w];
  assign walk1_rd_en_o      = rd_en_q[wptr_m1_w];
  assign walk1_is_fp_o      = is_fp_rd_q[wptr_m1_w];

  // V9O C0 control-event pregrant classification.  This edge-old decision
  // reads only stable ROB state, commit permits, and the exact pending CSR
  // ProducerId; in particular it deliberately ignores the current branch
  // kill input so it cannot close a resolve/ready feedback path.  The full
  // subset requests the typed C1 clear, while an exact pending CSR commit is
  // action-NONE and only closes same-cycle dispatch/younger branch work.
  wire head0_is_csr_w = valid_q[head_q] && head_done_w && !head_exception_w &&
      (inst_q[head_q][6:0] == `OPCODE_SYSTEM) &&
      (inst_q[head_q][14:12] != 3'b000);
  wire head0_csr_mem_hold_w;
  generate
    if (`OOO_CSR_QUEUE_HEAD) begin : gen_csr_queue_head_hold
      assign head0_csr_mem_hold_w = head0_is_csr_w && !mem_quiet_i;
    end else begin : gen_no_csr_queue_head_hold
      assign head0_csr_mem_hold_w = 1'b0;
    end
  endgenerate
  wire head0_commit_pregrant_w =
      !rst && !flush_i && !recover_q && commit_pregrant_ready_i &&
      (count_q != {ROB_COUNT_W{1'b0}}) &&
      valid_q[head_q] && head_done_w && !head0_csr_mem_hold_w &&
      head0_context_permit_i && fencei_retire_permit_i;
  wire head0_pending_csr_owner_match_w =
      pending_csr_owner_valid_i && head0_is_csr_w &&
      ({slot_generation_q[head_q], head_q} ==
       pending_csr_owner_producer_id_i);
  wire head0_queue_csr_w =
      head0_is_csr_w && !head0_pending_csr_owner_match_w;
  wire head0_full_flush_pregrant_w =
      head0_commit_pregrant_w &&
      (head_exception_w ||
       (`OOO_CSR_QUEUE_HEAD && head0_queue_csr_w));
  wire head0_pending_csr_commit_pregrant_w =
      head0_commit_pregrant_w && head0_pending_csr_owner_match_w;
  // Cycle-free winner projection: both queue-head full-flush requests and the
  // exact pending-system CSR commit are older than any executing branch.
  wire head0_control_event_pregrant_w =
      head0_full_flush_pregrant_w ||
      head0_pending_csr_commit_pregrant_w;
  assign head0_control_event_pregrant_o = head0_control_event_pregrant_w;
  assign head0_full_flush_pregrant_o = head0_full_flush_pregrant_w;
  assign head0_full_flush_reason_o =
      head_exception_w ? `REDIR_REASON_TRAP :
      ((`OOO_CSR_QUEUE_HEAD && head0_queue_csr_w) ?
       `REDIR_REASON_CSR_COMMIT : `REDIR_REASON_NONE);
  wire completion_cut_valid_w =
      kill_valid_i || head0_full_flush_pregrant_w;
  wire [ROB_INDEX_W-1:0] completion_cut_idx_w =
      head0_full_flush_pregrant_w ? head_q : kill_rob_idx_i;

  // v8f current/open target authority.  During a selective recovery, valid_q
  // is cleared over several walk cycles; nevertheless every strictly-younger
  // target loses side-effect authority on the first kill edge.  Older/equal
  // survivors remain eligible so their in-flight completion is not lost.
  // This function is called concurrently by every current/completion query.
  // Its age temporaries must be per invocation; a static Verilog function can
  // cross-contaminate parallel dynamic-index calls and fabricate a kill even
  // when kill_valid_i/recover_q are both zero.
  function automatic producer_target_killed_now;
    input [ROB_INDEX_W-1:0] target_idx;
    input [ROB_INDEX_W-1:0] head_idx;
    input current_kill_valid;
    input [ROB_INDEX_W-1:0] current_kill_idx;
    input recovery_valid;
    input [ROB_INDEX_W-1:0] recovery_kill_idx;
    reg [ROB_INDEX_W-1:0] target_age;
    reg [ROB_INDEX_W-1:0] boundary_age;
    begin
      target_age = target_idx - head_idx;
      if (current_kill_valid) begin
        boundary_age = current_kill_idx - head_idx;
        producer_target_killed_now = target_age > boundary_age;
      end else if (recovery_valid) begin
        boundary_age = recovery_kill_idx - head_idx;
        producer_target_killed_now = target_age > boundary_age;
      end else begin
        producer_target_killed_now = 1'b0;
      end
    end
  endfunction

  // Clamp an inactive query to slot zero.  Besides making the simulation
  // interface deterministic when an unused caller leaves the ID at X, this
  // keeps inactive dynamic array selects out of the authorization cone.
  wire [ROB_INDEX_W-1:0] current0_query_idx_w = current0_query_valid_i ?
      current0_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] current1_query_idx_w = current1_query_valid_i ?
      current1_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] completion0_query_idx_w = completion0_query_valid_i ?
      completion0_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] completion1_query_idx_w = completion1_query_valid_i ?
      completion1_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] completion2_query_idx_w = completion2_query_valid_i ?
      completion2_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] completion3_query_idx_w = completion3_query_valid_i ?
      completion3_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] completion4_query_idx_w = completion4_query_valid_i ?
      completion4_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] completion5_query_idx_w = completion5_query_valid_i ?
      completion5_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] completion6_query_idx_w = completion6_query_valid_i ?
      completion6_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] completion7_query_idx_w = completion7_query_valid_i ?
      completion7_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire [ROB_INDEX_W-1:0] resolve_query_idx_w = resolve_query_valid_i ?
      resolve_query_producer_id_i[ROB_INDEX_W-1:0] : {ROB_INDEX_W{1'b0}};
  wire current0_query_exact_w =
      {slot_generation_q[current0_query_idx_w], current0_query_idx_w} ==
      current0_query_producer_id_i;
  wire current1_query_exact_w =
      {slot_generation_q[current1_query_idx_w], current1_query_idx_w} ==
      current1_query_producer_id_i;
  wire completion0_query_exact_w =
      {slot_generation_q[completion0_query_idx_w], completion0_query_idx_w} ==
      completion0_query_producer_id_i;
  wire completion1_query_exact_w =
      {slot_generation_q[completion1_query_idx_w], completion1_query_idx_w} ==
      completion1_query_producer_id_i;
  wire completion2_query_exact_w =
      {slot_generation_q[completion2_query_idx_w], completion2_query_idx_w} ==
      completion2_query_producer_id_i;
  wire completion3_query_exact_w =
      {slot_generation_q[completion3_query_idx_w], completion3_query_idx_w} ==
      completion3_query_producer_id_i;
  wire completion4_query_exact_w =
      {slot_generation_q[completion4_query_idx_w], completion4_query_idx_w} ==
      completion4_query_producer_id_i;
  wire completion5_query_exact_w =
      {slot_generation_q[completion5_query_idx_w], completion5_query_idx_w} ==
      completion5_query_producer_id_i;
  wire completion6_query_exact_w =
      {slot_generation_q[completion6_query_idx_w], completion6_query_idx_w} ==
      completion6_query_producer_id_i;
  wire completion7_query_exact_w =
      {slot_generation_q[completion7_query_idx_w], completion7_query_idx_w} ==
      completion7_query_producer_id_i;
  wire resolve_query_exact_w =
      {slot_generation_q[resolve_query_idx_w], resolve_query_idx_w} ==
      resolve_query_producer_id_i;

  assign current0_query_match_o = current0_query_valid_i && !rst && !flush_i &&
      valid_q[current0_query_idx_w] && current0_query_exact_w &&
      !producer_target_killed_now(current0_query_idx_w, head_q,
                                  kill_valid_i, kill_rob_idx_i,
                                  recover_q, kill_idx_q);
  assign current1_query_match_o = current1_query_valid_i && !rst && !flush_i &&
      valid_q[current1_query_idx_w] && current1_query_exact_w &&
      !producer_target_killed_now(current1_query_idx_w, head_q,
                                  kill_valid_i, kill_rob_idx_i,
                                  recover_q, kill_idx_q);
  // Keep killed-now as an explicit Q-only term.  Besides documenting the
  // authorization boundary, the named term prevents a simulator from
  // treating the dynamic-slot function call as the sole reevaluation key
  // when query-valid toggles with the same raw index.
  wire completion0_query_live_w = completion0_query_valid_i && !rst && !flush_i &&
      valid_q[completion0_query_idx_w] && !done_q[completion0_query_idx_w] &&
      completion0_query_exact_w;
  wire completion0_query_killed_w =
      producer_target_killed_now(completion0_query_idx_w, head_q,
                                 completion_cut_valid_w,
                                 completion_cut_idx_w,
                                 recover_q, kill_idx_q);
  assign completion0_query_match_o =
      completion0_query_live_w && !completion0_query_killed_w;
  assign completion1_query_match_o = completion1_query_valid_i && !rst && !flush_i &&
      valid_q[completion1_query_idx_w] && !done_q[completion1_query_idx_w] &&
      completion1_query_exact_w &&
      !producer_target_killed_now(completion1_query_idx_w, head_q,
                                  completion_cut_valid_w,
                                  completion_cut_idx_w,
                                  recover_q, kill_idx_q);
  assign completion2_query_match_o = completion2_query_valid_i && !rst && !flush_i &&
      valid_q[completion2_query_idx_w] && !done_q[completion2_query_idx_w] &&
      completion2_query_exact_w &&
      !producer_target_killed_now(completion2_query_idx_w, head_q,
                                  completion_cut_valid_w,
                                  completion_cut_idx_w,
                                  recover_q, kill_idx_q);
  assign completion3_query_match_o = completion3_query_valid_i && !rst && !flush_i &&
      valid_q[completion3_query_idx_w] && !done_q[completion3_query_idx_w] &&
      completion3_query_exact_w &&
      !producer_target_killed_now(completion3_query_idx_w, head_q,
                                  completion_cut_valid_w,
                                  completion_cut_idx_w,
                                  recover_q, kill_idx_q);
  assign completion4_query_match_o = completion4_query_valid_i && !rst && !flush_i &&
      valid_q[completion4_query_idx_w] && !done_q[completion4_query_idx_w] &&
      completion4_query_exact_w &&
      !producer_target_killed_now(completion4_query_idx_w, head_q,
                                  completion_cut_valid_w,
                                  completion_cut_idx_w,
                                  recover_q, kill_idx_q);
  assign completion5_query_match_o = completion5_query_valid_i && !rst && !flush_i &&
      valid_q[completion5_query_idx_w] && !done_q[completion5_query_idx_w] &&
      completion5_query_exact_w &&
      !producer_target_killed_now(completion5_query_idx_w, head_q,
                                  completion_cut_valid_w,
                                  completion_cut_idx_w,
                                  recover_q, kill_idx_q);
  assign completion6_query_match_o = completion6_query_valid_i && !rst && !flush_i &&
      valid_q[completion6_query_idx_w] && !done_q[completion6_query_idx_w] &&
      completion6_query_exact_w &&
      !producer_target_killed_now(completion6_query_idx_w, head_q,
                                  completion_cut_valid_w,
                                  completion_cut_idx_w,
                                  recover_q, kill_idx_q);
  assign completion7_query_match_o = completion7_query_valid_i && !rst && !flush_i &&
      valid_q[completion7_query_idx_w] && !done_q[completion7_query_idx_w] &&
      completion7_query_exact_w &&
      !producer_target_killed_now(completion7_query_idx_w, head_q,
                                  completion_cut_valid_w,
                                  completion_cut_idx_w,
                                  recover_q, kill_idx_q);
  // V8J cycle-free resolve query: do not replace !recover_q with recovering_w
  // and do not call producer_target_killed_now() here.  Either change reads
  // kill_valid_i and creates resolve->kill->resolve feedback.
  assign resolve_query_match_o = resolve_query_valid_i && !rst && !flush_i &&
      !recover_q && valid_q[resolve_query_idx_w] &&
      !done_q[resolve_query_idx_w] && resolve_query_exact_w;

  // S2-Q2 v8a / V9O edge-old candidate: this observation intentionally reads
  // recover_q rather than recovering_w.  LQ retire permission feeds
  // commit_ready and the C0 pregrant; reading current kill_valid_i here would
  // close pregrant -> branch-apply -> candidate -> commit-ready -> pregrant.
  // Actual commit remains blocked by recovering_w below, so a current branch
  // event can perform a read-only LQ release query but cannot free the entry.
  // identity-valid only answers whether the current head slot remains live.
  assign head0_retire_candidate_valid_o =
      !recover_q && (count_q != {ROB_COUNT_W{1'b0}}) &&
      valid_q[head_q] && head_done_w;
  assign head0_identity_valid_o =
      (count_q != {ROB_COUNT_W{1'b0}}) && valid_q[head_q];
  assign head0_identity_o =
      {{(`OOO_CONTEXT_ID_W-ROB_INDEX_W){1'b0}}, head_q};
  assign head0_producer_id_o = {slot_generation_q[head_q], head_q};
  // An already-issued physical write remains owned across a selective
  // recovery of younger ROB entries.  Keep this ownership fact independent
  // of the stricter first-launch admission gate below.
  assign head0_owner_open_o = !rst &&
      (count_q != {ROB_COUNT_W{1'b0}}) && valid_q[head_q] &&
      !done_q[head_q];
  assign head0_launch_open_o = !rst && !flush_i && !recovering_w &&
      (count_q != {ROB_COUNT_W{1'b0}}) && valid_q[head_q] &&
      !done_q[head_q];

  // 【serialize-at-retire Phase1】head0/head1 CSR 识别；head0 的定义与
  // mem-quiet hold 已在 V9O pregrant 区域集中，保证提交与屏障共用同一真源。
  // head1 是否为 CSR: CSR 必须单发经 commit0 退休(否则经 commit1 会漏掉 head0_csr_commit → serial_flush/
  // csr状态写/rd覆写全不触发, 如 mtvec 静默不写)。故 head1=CSR 时禁 commit1, 逼 CSR 等到自己成 head0。
  wire head1_is_csr_w = valid_q[head1_w] && head1_done_w && !head1_exception_w &&
      (inst_q[head1_w][6:0] == `OPCODE_SYSTEM) && (inst_q[head1_w][14:12] != 3'b000);
  // v8a lane1 只形成 potential context-boundary observation；在 owner/payload
  // 契约完成前，禁止把这个 shadow 接入 commit1 gate。
  wire head1_is_csr_raw_w =
      (inst_q[head1_w][6:0] == `OPCODE_SYSTEM) &&
      (inst_q[head1_w][14:12] != 3'b000);
  wire head1_is_sfence_vma_raw_w =
      (inst_q[head1_w] & 32'hfe007fff) == 32'h12000073;
  wire head1_is_xret_raw_w =
      (inst_q[head1_w] == 32'h30200073) ||
      (inst_q[head1_w] == 32'h10200073);
  wire head1_is_fencei_raw_w = inst_q[head1_w] == 32'h0000100f;
  wire head1_potential_context_boundary_w =
      head1_is_csr_raw_w || head1_is_sfence_vma_raw_w ||
      head1_is_xret_raw_w || head1_is_fencei_raw_w;
  wire head1_context_boundary_shadow_w =
      valid_q[head1_w] && head1_done_w && !head1_exception_w &&
      head1_potential_context_boundary_w;
  wire _unused_v8a_lane1_shadow_w = head1_context_boundary_shadow_w;

  assign head0_base_ready_w = !recovering_w && commit_ready_i &&
                              (count_q != {ROB_COUNT_W{1'b0}}) &&
                              valid_q[head_q] && head_done_w &&
                              !head0_csr_mem_hold_w;
  assign commit0_fire_w = head0_base_ready_w &&
                          head0_context_permit_i &&
                          fencei_retire_permit_i;
  // 禁 CSR 双提交(仅 flag ON): (a) head0=CSR 时 serial_flush 刷 younger(含 head1), head1 不得同拍提交;
  //               (b) head1=CSR 时禁 commit1, 逼 CSR 单发经 commit0(否则漏 head0_csr_commit)。
  wire csr_commit1_block_w =
      `OOO_CSR_QUEUE_HEAD && (head0_is_csr_w || head1_is_csr_w);
  assign commit1_fire_w = commit0_fire_w && !commit1_block_i &&
                          !head_exception_w && !head1_exception_w &&
                          !csr_commit1_block_w &&
                          (count_q > {{(ROB_COUNT_W-1){1'b0}}, 1'b1}) &&
                          valid_q[head1_w] && head1_done_w;
  assign commit_count_w = {1'b0, commit0_fire_w} + {1'b0, commit1_fire_w};

  // Dispatch ready 只看当前已登记的 ROB 空位，不借用同拍 commit 释放的槽。
  // 这样避免 dispatch->issue 旁路和 writeback/commit 之间形成组合环。
  assign free_slots_w = ROB_ENTRIES[ROB_COUNT_W-1:0] - count_q;
  // reset/flush 分支会优先吞掉本拍状态更新，因此 ready 必须同步 fail-closed；
  // 禁止 valid&&ready 宣告 accepted、而 entry/generation 实际未写入。
  assign dispatch0_ready_o = !rst && !flush_i && !recovering_w &&
                             !head0_control_event_pregrant_w &&
                             (free_slots_w != {ROB_COUNT_W{1'b0}});
  assign dispatch0_fire_w = dispatch0_valid_i && dispatch0_ready_o;
  assign dispatch1_ready_o = !rst && !flush_i && !recovering_w &&
                             !head0_control_event_pregrant_w &&
                             (free_slots_w > {{(ROB_COUNT_W-1){1'b0}}, dispatch0_fire_w});
  assign dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o;
  assign dispatch_count_w = {1'b0, dispatch0_fire_w} + {1'b0, dispatch1_fire_w};
  assign dispatch0_rob_idx_o = tail_q;
  assign dispatch1_rob_idx_o = rob_ptr_add(tail_q, {1'b0, dispatch0_fire_w});
  wire [PRODUCER_GEN_W-1:0] dispatch0_generation_candidate_w =
      slot_generation_q[dispatch0_rob_idx_o] +
      {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1};
  wire [PRODUCER_GEN_W-1:0] dispatch1_generation_candidate_w =
      slot_generation_q[dispatch1_rob_idx_o] +
      {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1};
  assign dispatch0_producer_id_o =
      {dispatch0_generation_candidate_w, dispatch0_rob_idx_o};
  assign dispatch1_producer_id_o =
      {dispatch1_generation_candidate_w, dispatch1_rob_idx_o};
  wire [ROB_INDEX_W-1:0] dispatch1_pair_idx_w =
      rob_ptr_add(tail_q, 2'd1);
  wire [PRODUCER_GEN_W-1:0] dispatch1_pair_generation_candidate_w =
      slot_generation_q[dispatch1_pair_idx_w] +
      {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1};
  assign dispatch1_pair_producer_id_o =
      {dispatch1_pair_generation_candidate_w, dispatch1_pair_idx_w};

`ifdef DBRA_PROBE
  always @(posedge clk) begin
    if (commit0_fire_w || commit1_fire_w || kill_valid_i || recover_q)
      $display("[ROBP] c0=%b pc0=%h c1=%b pc1=%h kill=%b kidx=%h recov=%b head=%h cnt=%d",
               commit0_fire_w, pc_q[head_q], commit1_fire_w, pc_q[head1_w],
               kill_valid_i, kill_rob_idx_i, recover_q, head_q, count_q);
  end
`endif
  assign commit0_valid_o = commit0_fire_w;
  assign commit0_producer_id_o = {slot_generation_q[head_q], head_q};
  assign commit0_pc_o = pc_q[head_q];
  assign commit0_next_pc_o = next_pc_q[head_q];
  assign commit0_inst_o = inst_q[head_q];
  assign commit0_rd_en_o = rd_en_q[head_q];
  assign commit0_is_fp_rd_o = is_fp_rd_q[head_q];
  assign commit0_fflags_o = head_fflags_w;
  assign commit0_arch_rd_o = arch_rd_q[head_q];
  assign commit0_old_pdest_o = old_pdest_q[head_q];
  assign commit0_new_pdest_o = new_pdest_q[head_q];
  assign commit0_data_o = head_data_w;
  assign commit0_exception_o = head_exception_w;
  assign commit0_cause_o = head_cause_w;
  assign commit0_tval_o = head_tval_w;

  assign commit1_valid_o = commit1_fire_w;
  assign commit1_producer_id_o = {slot_generation_q[head1_w], head1_w};
  assign commit1_pc_o = pc_q[head1_w];
  assign commit1_next_pc_o = next_pc_q[head1_w];
  assign commit1_inst_o = inst_q[head1_w];
  assign commit1_rd_en_o = rd_en_q[head1_w];
  assign commit1_is_fp_rd_o = is_fp_rd_q[head1_w];
  assign commit1_fflags_o = head1_fflags_w;
  assign commit1_arch_rd_o = arch_rd_q[head1_w];
  assign commit1_old_pdest_o = old_pdest_q[head1_w];
  assign commit1_new_pdest_o = new_pdest_q[head1_w];
  assign commit1_data_o = head1_data_w;
  assign commit1_exception_o = head1_exception_w;
  assign commit1_cause_o = head1_cause_w;
  assign commit1_tval_o = head1_tval_w;

  assign head_idx_o = head_q;
  assign head_valid_o = (count_q != {ROB_COUNT_W{1'b0}});
  assign count_o = count_q;
  assign empty_o = (count_q == {ROB_COUNT_W{1'b0}});
  assign full_o = (count_q == ROB_ENTRIES[ROB_COUNT_W-1:0]);

  always @(posedge clk) begin
    if (rst || flush_i) begin
      head_q <= {ROB_INDEX_W{1'b0}};
      tail_q <= {ROB_INDEX_W{1'b0}};
      count_q <= {ROB_COUNT_W{1'b0}};
      for (idx = 0; idx < ROB_ENTRIES; idx = idx + 1) begin
        valid_q[idx] <= 1'b0;
        done_q[idx] <= 1'b0;
        pc_q[idx] <= {`XLEN{1'b0}};
        next_pc_q[idx] <= {`XLEN{1'b0}};
        inst_q[idx] <= {`INST_W{1'b0}};
        rd_en_q[idx] <= 1'b0;
        arch_rd_q[idx] <= {`REG_ADDR_W{1'b0}};
        old_pdest_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
        new_pdest_q[idx] <= {PHY_REG_ADDR_W{1'b0}};
        data_q[idx] <= {`XLEN{1'b0}};
        exception_q[idx] <= 1'b0;
        cause_q[idx] <= {`TRAP_CAUSE_W{1'b0}};
        tval_q[idx] <= {`XLEN{1'b0}};
        is_fp_rd_q[idx] <= 1'b0;
        fflags_q[idx] <= 5'b00000;
        // 普通 flush 只清 ROB 本地生命周期，不能让尚在外部 holder 的旧 ID
        // 与下一 incarnation 立即重名；只有全 reset domain 的 rst 才重置编码源。
        if (rst)
          slot_generation_q[idx] <= {PRODUCER_GEN_W{1'b1}};
      end
      recover_q <= 1'b0;
      walk_ptr_q <= {ROB_INDEX_W{1'b0}};
      kill_idx_q <= {ROB_INDEX_W{1'b0}};
    end else if (recover_q) begin
      // ROB-walk：本拍 squash lane0(恒)/lane1(若仍更年轻)，count 递减；到存活分支即收尾回退 tail。
      // 关键：recovery 窗口内仍须吸收 in-flight 写回——更老(存活)指令的执行结果若恰在此时回写，
      // 丢弃会令其 ROB 项永不 done → head 永久卡死。写回放在 squash 之前，被 squash 的更年轻项由
      // 其后的 valid/done<=0 覆盖（nonblocking 源序后写胜），故对被压制项无副作用。
      if (wb0_valid_i && valid_q[wb0_rob_idx_i]) begin
        done_q[wb0_rob_idx_i] <= 1'b1;
        data_q[wb0_rob_idx_i] <= wb0_data_i;
        exception_q[wb0_rob_idx_i] <= wb0_exception_i;
        cause_q[wb0_rob_idx_i] <= wb0_cause_i;
        tval_q[wb0_rob_idx_i] <= wb0_tval_i;
        fflags_q[wb0_rob_idx_i] <= wb0_fflags_i;
      end
      if (wb1_valid_i && valid_q[wb1_rob_idx_i]) begin
        done_q[wb1_rob_idx_i] <= 1'b1;
        data_q[wb1_rob_idx_i] <= wb1_data_i;
        exception_q[wb1_rob_idx_i] <= wb1_exception_i;
        cause_q[wb1_rob_idx_i] <= wb1_cause_i;
        tval_q[wb1_rob_idx_i] <= wb1_tval_i;
        fflags_q[wb1_rob_idx_i] <= wb1_fflags_i;
      end
      valid_q[walk_ptr_q] <= 1'b0;
      done_q[walk_ptr_q] <= 1'b0;
      if (lane1_sq_w) begin
        valid_q[wptr_m1_w] <= 1'b0;
        done_q[wptr_m1_w] <= 1'b0;
      end
      count_q <= count_q - (lane1_sq_w ? {{(ROB_COUNT_W-2){1'b0}}, 2'd2}
                                       : {{(ROB_COUNT_W-1){1'b0}}, 1'b1});
      if (walk_done_w) begin
        recover_q <= 1'b0;
        tail_q <= kill_next_q_w;
      end else begin
        walk_ptr_q <= walk_ptr_q - {{(ROB_INDEX_W-2){1'b0}}, 2'd2};
      end
    end else if (kill_has_younger_w) begin
      // 启动 walk：从 tail-1（最年轻）开始反向 squash，终点=存活分支 kill_rob_idx。
      // 同样吸收本拍 in-flight 写回（此拍尚未 squash 任何项，无冲突）。
      if (wb0_valid_i && valid_q[wb0_rob_idx_i]) begin
        done_q[wb0_rob_idx_i] <= 1'b1;
        data_q[wb0_rob_idx_i] <= wb0_data_i;
        exception_q[wb0_rob_idx_i] <= wb0_exception_i;
        cause_q[wb0_rob_idx_i] <= wb0_cause_i;
        tval_q[wb0_rob_idx_i] <= wb0_tval_i;
        fflags_q[wb0_rob_idx_i] <= wb0_fflags_i;
      end
      if (wb1_valid_i && valid_q[wb1_rob_idx_i]) begin
        done_q[wb1_rob_idx_i] <= 1'b1;
        data_q[wb1_rob_idx_i] <= wb1_data_i;
        exception_q[wb1_rob_idx_i] <= wb1_exception_i;
        cause_q[wb1_rob_idx_i] <= wb1_cause_i;
        tval_q[wb1_rob_idx_i] <= wb1_tval_i;
        fflags_q[wb1_rob_idx_i] <= wb1_fflags_i;
      end
      recover_q <= 1'b1;
      kill_idx_q <= kill_rob_idx_i;
      walk_ptr_q <= tail_q - {{(ROB_INDEX_W-1){1'b0}}, 1'b1};
    end else begin
      if (commit0_fire_w) begin
        valid_q[head_q] <= 1'b0;
        done_q[head_q] <= 1'b0;
      end
      if (commit1_fire_w) begin
        valid_q[head1_w] <= 1'b0;
        done_q[head1_w] <= 1'b0;
      end

      if (wb0_valid_i && valid_q[wb0_rob_idx_i]) begin
        done_q[wb0_rob_idx_i] <= 1'b1;
        data_q[wb0_rob_idx_i] <= wb0_data_i;
        exception_q[wb0_rob_idx_i] <= wb0_exception_i;
        cause_q[wb0_rob_idx_i] <= wb0_cause_i;
        tval_q[wb0_rob_idx_i] <= wb0_tval_i;
        fflags_q[wb0_rob_idx_i] <= wb0_fflags_i;
      end
      if (wb1_valid_i && valid_q[wb1_rob_idx_i]) begin
        done_q[wb1_rob_idx_i] <= 1'b1;
        data_q[wb1_rob_idx_i] <= wb1_data_i;
        exception_q[wb1_rob_idx_i] <= wb1_exception_i;
        cause_q[wb1_rob_idx_i] <= wb1_cause_i;
        tval_q[wb1_rob_idx_i] <= wb1_tval_i;
        fflags_q[wb1_rob_idx_i] <= wb1_fflags_i;
      end

      if (dispatch0_fire_w) begin
        slot_generation_q[dispatch0_rob_idx_o] <=
            dispatch0_generation_candidate_w;
        valid_q[dispatch0_rob_idx_o] <= 1'b1;
        done_q[dispatch0_rob_idx_o] <= 1'b0;
        pc_q[dispatch0_rob_idx_o] <= dispatch0_pc_i;
        next_pc_q[dispatch0_rob_idx_o] <= dispatch0_next_pc_i;
        inst_q[dispatch0_rob_idx_o] <= dispatch0_inst_i;
        rd_en_q[dispatch0_rob_idx_o] <= dispatch0_rd_en_i;
        is_fp_rd_q[dispatch0_rob_idx_o] <= dispatch0_is_fp_rd_i;
        fflags_q[dispatch0_rob_idx_o] <= 5'b00000;
        arch_rd_q[dispatch0_rob_idx_o] <= dispatch0_arch_rd_i;
        old_pdest_q[dispatch0_rob_idx_o] <= dispatch0_old_pdest_i;
        new_pdest_q[dispatch0_rob_idx_o] <= dispatch0_new_pdest_i;
        data_q[dispatch0_rob_idx_o] <= {`XLEN{1'b0}};
        exception_q[dispatch0_rob_idx_o] <= 1'b0;
        cause_q[dispatch0_rob_idx_o] <= {`TRAP_CAUSE_W{1'b0}};
        tval_q[dispatch0_rob_idx_o] <= {`XLEN{1'b0}};
      end
      if (dispatch1_fire_w) begin
        slot_generation_q[dispatch1_rob_idx_o] <=
            dispatch1_generation_candidate_w;
        valid_q[dispatch1_rob_idx_o] <= 1'b1;
        done_q[dispatch1_rob_idx_o] <= 1'b0;
        pc_q[dispatch1_rob_idx_o] <= dispatch1_pc_i;
        next_pc_q[dispatch1_rob_idx_o] <= dispatch1_next_pc_i;
        inst_q[dispatch1_rob_idx_o] <= dispatch1_inst_i;
        rd_en_q[dispatch1_rob_idx_o] <= dispatch1_rd_en_i;
        is_fp_rd_q[dispatch1_rob_idx_o] <= dispatch1_is_fp_rd_i;
        fflags_q[dispatch1_rob_idx_o] <= 5'b00000;
        arch_rd_q[dispatch1_rob_idx_o] <= dispatch1_arch_rd_i;
        old_pdest_q[dispatch1_rob_idx_o] <= dispatch1_old_pdest_i;
        new_pdest_q[dispatch1_rob_idx_o] <= dispatch1_new_pdest_i;
        data_q[dispatch1_rob_idx_o] <= {`XLEN{1'b0}};
        exception_q[dispatch1_rob_idx_o] <= 1'b0;
        cause_q[dispatch1_rob_idx_o] <= {`TRAP_CAUSE_W{1'b0}};
        tval_q[dispatch1_rob_idx_o] <= {`XLEN{1'b0}};
      end

      head_q <= rob_ptr_add(head_q, commit_count_w);
      tail_q <= rob_ptr_add(tail_q, dispatch_count_w);
      count_q <= count_q + {{(ROB_COUNT_W-2){1'b0}}, dispatch_count_w} -
                 {{(ROB_COUNT_W-2){1'b0}}, commit_count_w};
    end
`ifdef ROB_WALK_DEBUG
    if (rst) rob_stall_cnt_q <= 12'd0;
    else begin
      rob_stall_cnt_q <= (count_q != {ROB_COUNT_W{1'b0}} && !commit0_fire_w) ? rob_stall_cnt_q + 12'd1 : 12'd0;
      if (rob_stall_cnt_q == 12'd2000)
        $display("[ROBSTALL] head=%0d tail=%0d count=%0d recover=%b validH=%b doneH=%b pcH=%h instH=%h commit_ready=%b kill_valid=%b",
                 head_q, tail_q, count_q, recover_q, valid_q[head_q], done_q[head_q], pc_q[head_q], inst_q[head_q], commit_ready_i, kill_valid_i);
    end
`endif
  end


`ifdef OOO_ASSERT
  // A1 生产者身份哨兵 (UC-A): wb 写已 valid 的 ROB 槽时, 携带的 pdest 必须等于该槽 dispatch 记录的
  // new_pdest_q。不等 = wrong-path stale 生产者(muldiv/clmul/alu 无 mispredict-kill)写了被 kill 后
  // 复用的槽 = 静默撞号。仅 pdest!=0(真 int 生产者写 PRF)时校验; FP-rd/store/no-rd 携 0 跳过, 无假阳。
  always @(posedge clk) begin
    if (!rst && !flush_i) begin
      // A ROB entry has exactly one completion owner per cycle.  Silently
      // defining WB1 as the winner would make exception/data/fflags depend on
      // source ordering and leaves pdest=0 producers outside UC-A coverage.
      if (wb0_valid_i && wb1_valid_i &&
          (wb0_rob_idx_i == wb1_rob_idx_i) && valid_q[wb0_rob_idx_i]) begin
        $error("[T3W-ROB-WB-OWNER-COLLISION] WB0/WB1 completed the same live ROB idx=%0d @%0t",
               wb0_rob_idx_i, $time);
        $fatal;
      end
      if (commit0_fire_w && !done_q[head_q])
        $error("[T3W-ROB-Q-RETIRE] commit0 bypassed registered done state @%0t",
               $time);
      // 独立后果而非方程重述：任何 edge-old candidate 都必须仍对应
      // live/done 且不处于 registered recovery。current kill 仍由实际 commit
      // 的 recovering_w 门阻断；candidate 不读取它以保持 C0 pregrant 无环。
      if ((head0_retire_candidate_valid_o === 1'b1) &&
          ((head0_identity_valid_o !== 1'b1) ||
           (head_done_w !== 1'b1) || (recover_q !== 1'b0))) begin
        $error("[S2-Q2-V8A-CANDIDATE-LIVE] retire candidate lost live/done/recovery provenance @%0t",
               $time);
        $fatal;
      end
      if (commit1_fire_w && !commit0_fire_w) begin
        $error("[S2-Q2-V8A-RETIRE-PREFIX] lane1 retired without the older lane0 @%0t",
               $time);
        $fatal;
      end
      if (commit1_fire_w && !done_q[head1_w])
        $error("[T3W-ROB-Q-RETIRE] commit1 bypassed registered done state @%0t",
               $time);
      // 精确异常只允许从 commit0 宣告；older normal 可先退休，但异常项必须
      // 留到下一拍成为 ROB head，不能由 commit1 越过精确 trap 边界。
      if (commit1_fire_w && (head_exception_w || head1_exception_w))
        $error("[T4N-ROB-EXCEPTION-LANE0] exception retired through commit1 @%0t",
               $time);
      if (commit0_fire_w &&
          ((commit0_data_o !== data_q[head_q]) ||
           (commit0_exception_o !== exception_q[head_q]) ||
           (commit0_cause_o !== cause_q[head_q]) ||
           (commit0_tval_o !== tval_q[head_q]) ||
           (commit0_fflags_o !== fflags_q[head_q])))
        $error("[T3W-ROB-Q-RETIRE] commit0 payload bypassed registered ROB state @%0t",
               $time);
      if (commit1_fire_w &&
          ((commit1_data_o !== data_q[head1_w]) ||
           (commit1_exception_o !== exception_q[head1_w]) ||
           (commit1_cause_o !== cause_q[head1_w]) ||
           (commit1_tval_o !== tval_q[head1_w]) ||
           (commit1_fflags_o !== fflags_q[head1_w])))
        $error("[T3W-ROB-Q-RETIRE] commit1 payload bypassed registered ROB state @%0t",
               $time);
      if (wb0_valid_i && valid_q[wb0_rob_idx_i] &&
          (wb0_pdest_i != {PHY_REG_ADDR_W{1'b0}}) &&
          (wb0_pdest_i !== new_pdest_q[wb0_rob_idx_i]))
        $error("[FLUSH-CONTRACT UC-A] ROB 生产者撞号 WB0 idx=%0d pdest=%0d != slot.new_pdest=%0d (pc=%h) wrong-path 生产者写复用槽 @%0t",
               wb0_rob_idx_i, wb0_pdest_i, new_pdest_q[wb0_rob_idx_i], pc_q[wb0_rob_idx_i], $time);
      if (wb1_valid_i && valid_q[wb1_rob_idx_i] &&
          (wb1_pdest_i != {PHY_REG_ADDR_W{1'b0}}) &&
          (wb1_pdest_i !== new_pdest_q[wb1_rob_idx_i]))
        $error("[FLUSH-CONTRACT UC-A] ROB 生产者撞号 WB1 idx=%0d pdest=%0d != slot.new_pdest=%0d (pc=%h) wrong-path 生产者写复用槽 @%0t",
               wb1_rob_idx_i, wb1_pdest_i, new_pdest_q[wb1_rob_idx_i], pc_q[wb1_rob_idx_i], $time);
      // P1 shadow 非真空合同：accepted allocation 的公开 ID 必须由该槽
      // next-generation 与 raw index 同源组成；它不承担 active WB authorization。
      if (dispatch0_fire_w &&
          ((dispatch0_producer_id_o[ROB_INDEX_W-1:0] !== dispatch0_rob_idx_o) ||
           (dispatch0_producer_id_o[PRODUCER_ID_W-1:ROB_INDEX_W] !==
            dispatch0_generation_candidate_w)))
        $error("[V8E-PRODUCER-ID-DISPATCH0] allocation identity/source mismatch @%0t",
               $time);
      if (dispatch1_fire_w &&
          ((dispatch1_producer_id_o[ROB_INDEX_W-1:0] !== dispatch1_rob_idx_o) ||
           (dispatch1_producer_id_o[PRODUCER_ID_W-1:ROB_INDEX_W] !==
            dispatch1_generation_candidate_w)))
        $error("[V8E-PRODUCER-ID-DISPATCH1] allocation identity/source mismatch @%0t",
               $time);
      if (dispatch1_pair_producer_id_o[ROB_INDEX_W-1:0] !==
          rob_ptr_add(tail_q, 2'd1))
        $error("[V8G-ROB-PAIR-CANDIDATE] pair lane1 candidate depends on fire @%0t",
               $time);
      if (dispatch0_producer_id_o === dispatch1_pair_producer_id_o)
        $error("[V8H-ROB-PAIR-PID-DISTINCT] pair candidates share one ProducerId @%0t",
               $time);
      if (dispatch0_fire_w &&
          (dispatch1_producer_id_o !== dispatch1_pair_producer_id_o))
        $error("[V8G-ROB-PAIR-ACTUAL] accepted pair lane1 identity diverged @%0t",
               $time);
      if (completion2_query_match_o &&
          (!completion2_query_valid_i ||
           !valid_q[completion2_query_idx_w] ||
           done_q[completion2_query_idx_w] ||
           !completion2_query_exact_w ||
           producer_target_killed_now(completion2_query_idx_w, head_q,
                                      completion_cut_valid_w,
                                      completion_cut_idx_w,
                                      recover_q, kill_idx_q)))
        $error("[V8G-ROB-MEM-COMPLETION-QUERY] query2 escaped exact-open gate @%0t",
               $time);
      if (completion3_query_match_o &&
          (!completion3_query_valid_i ||
           !valid_q[completion3_query_idx_w] ||
           done_q[completion3_query_idx_w] ||
           !completion3_query_exact_w ||
           producer_target_killed_now(completion3_query_idx_w, head_q,
                                      completion_cut_valid_w,
                                      completion_cut_idx_w,
                                      recover_q, kill_idx_q)))
        $error("[V8H-ROB-MULDIV-COMPLETION-QUERY] query3 escaped exact-open gate @%0t",
               $time);
      if (completion4_query_match_o &&
          (!completion4_query_valid_i ||
           !valid_q[completion4_query_idx_w] ||
           done_q[completion4_query_idx_w] ||
           !completion4_query_exact_w ||
           producer_target_killed_now(completion4_query_idx_w, head_q,
                                      completion_cut_valid_w,
                                      completion_cut_idx_w,
                                      recover_q, kill_idx_q)))
        $error("[V8H-ROB-CLMUL-COMPLETION-QUERY] query4 escaped exact-open gate @%0t",
               $time);
      if (completion5_query_match_o &&
          (!completion5_query_valid_i ||
           !valid_q[completion5_query_idx_w] ||
           done_q[completion5_query_idx_w] ||
           !completion5_query_exact_w ||
           producer_target_killed_now(completion5_query_idx_w, head_q,
                                      completion_cut_valid_w,
                                      completion_cut_idx_w,
                                      recover_q, kill_idx_q)))
        $error("[V8I-ROB-FP-RESULT-QUERY] query5 escaped exact-open gate @%0t",
               $time);
      if (completion6_query_match_o &&
          (!completion6_query_valid_i ||
           !valid_q[completion6_query_idx_w] ||
           done_q[completion6_query_idx_w] ||
           !completion6_query_exact_w ||
           producer_target_killed_now(completion6_query_idx_w, head_q,
                                      completion_cut_valid_w,
                                      completion_cut_idx_w,
                                      recover_q, kill_idx_q)))
        $error("[V8I-ROB-FP-FORMAL-QUERY] query6 escaped exact-open gate @%0t",
               $time);
      if (completion7_query_match_o &&
          (!completion7_query_valid_i ||
           !valid_q[completion7_query_idx_w] ||
           done_q[completion7_query_idx_w] ||
           !completion7_query_exact_w ||
           producer_target_killed_now(completion7_query_idx_w, head_q,
                                      completion_cut_valid_w,
                                      completion_cut_idx_w,
                                      recover_q, kill_idx_q)))
        $error("[V8S-ROB-MEM1-COMPLETION-QUERY] query7 escaped exact-open gate @%0t",
               $time);
      if (resolve_query_match_o &&
          (!resolve_query_valid_i || rst || flush_i || recover_q ||
           !valid_q[resolve_query_idx_w] || done_q[resolve_query_idx_w] ||
           !resolve_query_exact_w))
        $error("[V8J-ROB-RESOLVE-QUERY] resolve query escaped exact edge-old gate @%0t",
               $time);
      if (kill_valid_i && resolve_query_valid_i &&
          (resolve_query_idx_w == kill_rob_idx_i) &&
          !rst && !flush_i && !recover_q &&
          valid_q[resolve_query_idx_w] && !done_q[resolve_query_idx_w] &&
          resolve_query_exact_w && !resolve_query_match_o)
        $error("[V8J-ROB-RESOLVE-SELF-KILL] boundary P rejected itself @%0t",
               $time);
      if (head0_identity_valid_o &&
          ((head0_producer_id_o[ROB_INDEX_W-1:0] !== head_q) ||
           (head0_producer_id_o[PRODUCER_ID_W-1:ROB_INDEX_W] !==
            slot_generation_q[head_q])))
        $error("[V8E-PRODUCER-ID-HEAD] live head identity/source mismatch @%0t",
               $time);
      if (head0_full_flush_pregrant_w &&
          (!head0_commit_pregrant_w ||
           ((head0_full_flush_reason_o != `REDIR_REASON_TRAP) &&
            (head0_full_flush_reason_o != `REDIR_REASON_CSR_COMMIT)))) begin
        $error("[V9O-ROB-PREGRANT] invalid full-flush pregrant provenance @%0t",
               $time);
        $fatal;
      end
      if (head0_pending_csr_commit_pregrant_w &&
          (!head0_commit_pregrant_w || !pending_csr_owner_valid_i ||
           !head0_is_csr_w ||
           ({slot_generation_q[head_q], head_q} !=
            pending_csr_owner_producer_id_i) ||
           (head0_full_flush_reason_o != `REDIR_REASON_NONE))) begin
        $error("[V9O-ROB-PENDING-CSR-PREGRANT] invalid exact-owner provenance @%0t",
               $time);
        $fatal;
      end
      if (head0_control_event_pregrant_w &&
          (dispatch0_ready_o || dispatch1_ready_o))
        $error("[V9O-ROB-CONTROL-PREGRANT] dispatch remained open in C0 @%0t",
               $time);
      // INV-4-serial: head0 CSR 退休会在下一拍触发 serial_flush; 退休拍必须已经无在飞内存事务。
      // 当前 mem_quiet_i 接 mem_idle(不含 SQ empty), 这是 §10.4 为避免 younger-store 死锁后的真实契约。
      if (`OOO_CSR_QUEUE_HEAD && commit0_fire_w && head0_is_csr_w && !mem_quiet_i)
        $error("[FLUSH-CONTRACT INV-4] head0 CSR 在 mem_idle=0 时退休: serial_flush 会 abort 在飞内存事务 @%0t", $time);
    end
  end
`endif

endmodule
