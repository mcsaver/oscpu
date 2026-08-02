`include "define.v"

// 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作：
// 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。
// 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入
// 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BYPASS
// 立即断言看护)。T3M 起所有 integer full wakeup（含 EX）都只在沿上更新
// ready 状态，不直接进入 resident select。历史数据与决策见
// design/arch/timing-dispatch-issue-path.md §6c 与 design/arch/p5-repipeline-first-batch.md。
module OooIntIssueQueue #(
  parameter ENTRY_COUNT = (1 << `OOO_ISSUE_INDEX_W),
  parameter ENTRY_INDEX_W = `OOO_ISSUE_INDEX_W,
  parameter ENTRY_COUNT_W = `OOO_ISSUE_COUNT_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PRODUCER_ID_W = `OOO_PRODUCER_ID_W
) (
  input clk,
  input rst,
  input flush_i,
  input issue_mem_block_i,
  // Registered occupancy of the physical Universal terminal.  This is a
  // resource-owner fact, not a dispatch or program-order lane.  It must not
  // be driven from combinational ready.
  input universal_owner_present_i,
  // v8u/F4 Q-only refill face.  When enabled, resident entries 0/1 may be
  // exposed on the existing issue payload buses as an ordinary memory pair,
  // while both regular issue valids remain low.  READY only controls the
  // atomic dequeue of those two registered entries.
  input memory_pair_peek_enable_i,
  output memory_pair_peek_valid_o,
  input memory_pair_peek_ready_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`XLEN-1:0] dispatch0_pred_npc_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx_i,
  input dispatch0_pred_taken_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch0_ctrl_i,
  input dispatch0_is_fp_i,
  input [ROB_INDEX_W-1:0] dispatch0_rob_idx_i,
  input [PRODUCER_ID_W-1:0] dispatch0_producer_id_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg_i,
  input dispatch0_src1_ready_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg_i,
  input dispatch0_src2_ready_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_pdest_i,
  // 【B-FP 簇】fp_pdest=目的是 FP preg(mem rsp 写 FP 堆); fp_st_src=FP store 数据源
  input dispatch0_fp_pdest_i,
  input dispatch0_fp_st_src_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_fp_st_src_preg_i,
  input dispatch0_fp_st_src_ready_i,
  input [`XLEN-1:0] dispatch0_imm_i,

  input dispatch1_valid_i,
  // dispatch1_optional_i：P5 刀 B 删 bypass 后 IQ 内部不再消费(原 optional-bypass 判定用)；
  // 端口保留以维持上游 OooDispatchBackend 接口不变。
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`XLEN-1:0] dispatch1_pred_npc_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch1_bht_idx_i,
  input dispatch1_pred_taken_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch1_ctrl_i,
  input dispatch1_is_fp_i,
  input [ROB_INDEX_W-1:0] dispatch1_rob_idx_i,
  input [PRODUCER_ID_W-1:0] dispatch1_producer_id_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg_i,
  input dispatch1_src1_ready_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg_i,
  input dispatch1_src2_ready_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_pdest_i,
  input dispatch1_fp_pdest_i,
  input dispatch1_fp_st_src_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_fp_st_src_preg_i,
  input dispatch1_fp_st_src_ready_i,
  input [`XLEN-1:0] dispatch1_imm_i,

  input wakeup0_valid_i,
  input [PHY_REG_ADDR_W-1:0] wakeup0_pdest_i,
  input wakeup1_valid_i,
  input [PHY_REG_ADDR_W-1:0] wakeup1_pdest_i,
  // R3.2 lookahead wake comes only from an actual fixed-latency terminal
  // fire.  Like full WB wake it is sticky-only and never enters select.
  input early_wakeup0_valid_i,
  input [PHY_REG_ADDR_W-1:0] early_wakeup0_pdest_i,
  input early_wakeup1_valid_i,
  input [PHY_REG_ADDR_W-1:0] early_wakeup1_pdest_i,
  // 【B-FP 簇】FP wakeup(fp store 数据源 fs2 的就绪监听)
  input fp_wake0_valid_i,
  input [PHY_REG_ADDR_W-1:0] fp_wake0_preg_i,
  input fp_wake1_valid_i,
  input [PHY_REG_ADDR_W-1:0] fp_wake1_preg_i,

  output issue0_valid_o,
  input issue0_ready_i,
  output [`XLEN-1:0] issue0_pc_o,
  output [`XLEN-1:0] issue0_next_pc_o,
  output [`XLEN-1:0] issue0_pred_npc_o,
  output [`BPU_BHT_INDEX_W-1:0] issue0_bht_idx_o,
  output issue0_pred_taken_o,
  output [`INST_W-1:0] issue0_inst_o,
  output [`CTRL_BUS_W-1:0] issue0_ctrl_o,
  output [ROB_INDEX_W-1:0] issue0_rob_idx_o,
  output [PRODUCER_ID_W-1:0] issue0_producer_id_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_pdest_o,
  output issue0_fixed_gpr_producer_o,
  output issue0_fp_pdest_o,
  output issue0_fp_st_src_en_o,
  output [PHY_REG_ADDR_W-1:0] issue0_fp_st_src_preg_o,
  output [`XLEN-1:0] issue0_imm_o,
  // High when capability steering maps a younger complex uop to issue0 and
  // its older independent ALU partner to issue1.
  output issue_pair_swapped_o,

  output issue1_valid_o,
  input issue1_ready_i,
  output [`XLEN-1:0] issue1_pc_o,
  output [`XLEN-1:0] issue1_next_pc_o,
  output [`XLEN-1:0] issue1_pred_npc_o,
  output [`BPU_BHT_INDEX_W-1:0] issue1_bht_idx_o,
  output issue1_pred_taken_o,
  output [`INST_W-1:0] issue1_inst_o,
  output [`CTRL_BUS_W-1:0] issue1_ctrl_o,
  output [ROB_INDEX_W-1:0] issue1_rob_idx_o,
  output [PRODUCER_ID_W-1:0] issue1_producer_id_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_pdest_o,
  output issue1_fixed_gpr_producer_o,
  output issue1_fp_pdest_o,
  output issue1_fp_st_src_en_o,
  output [PHY_REG_ADDR_W-1:0] issue1_fp_st_src_preg_o,
  output [`XLEN-1:0] issue1_imm_o,

  output [ENTRY_COUNT_W-1:0] count_o,
  output empty_o,
  output full_o,
  // v8l: edge-old resident owner projection.  This mask is deliberately
  // generated from valid_q/producer_id_q only; dispatch D, select/fire,
  // ready and next-state are forbidden from the lease cone.
  output [(1 << PRODUCER_ID_W)-1:0] producer_live_mask_o,

  // B2 ROB-walk：误预测时 squash 比 kill_rob_idx 更年轻(age 更大)的 IQ entry（程序序后缀），
  // recover 期冻结发射。in-core 暂 kill 接 0、recover 接 ROB.recover_active → 行为中性。
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,
  input recover_active_i
);

  // V13I：normal compaction 将完整 entry 作为一个组合 payload 搬运。该打包宽度
  // 只描述既有 Q 字段，不增加寄存状态，也不改变任何端口或周期边界。
  localparam ENTRY_STATE_W =
      (4 * `XLEN) + `BPU_BHT_INDEX_W + `INST_W + `CTRL_BUS_W +
      PRODUCER_ID_W + (4 * PHY_REG_ADDR_W) + 9;

  reg valid_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pc_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] next_pc_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pred_npc_q [0:ENTRY_COUNT-1];
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx_q [0:ENTRY_COUNT-1];
  reg pred_taken_q [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst_q [0:ENTRY_COUNT-1];
  reg [`CTRL_BUS_W-1:0] ctrl_q [0:ENTRY_COUNT-1];
  // v8f: full ProducerId is the only sequential identity holder.  Legacy raw
  // ROB index is always a low-bit projection, avoiding a duplicated truth.
  reg [PRODUCER_ID_W-1:0] producer_id_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] src1_preg_q [0:ENTRY_COUNT-1];
  reg src1_ready_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] src2_preg_q [0:ENTRY_COUNT-1];
  reg src2_ready_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] pdest_q [0:ENTRY_COUNT-1];
  // 【B-FP 簇】fp 字段
  reg fp_pdest_q [0:ENTRY_COUNT-1];
  reg fp_st_en_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] fp_st_preg_q [0:ENTRY_COUNT-1];
  reg fp_st_ready_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] imm_q [0:ENTRY_COUNT-1];
  // R3 timing cut: capability is predecoded once at dispatch and compacted
  // beside the payload.  The oldest-first scan reads one bit per entry rather
  // than repeatedly decoding the wide ctrl bus on the select critical path.
  reg alu_terminal_capable_q [0:ENTRY_COUNT-1];
  // v8p: capability of the second physical memory terminal.  It is separate
  // from ALU capability and excludes AMO/LR/SC and every FP memory operation.
  reg plain_memory_terminal_capable_q [0:ENTRY_COUNT-1];
  // R3.2: compact one predecoded bit with each entry.  This is strictly the
  // fixed-latency integer GPR producer domain; it is not a lane capability.
  reg fixed_gpr_producer_q [0:ENTRY_COUNT-1];
  reg [ENTRY_COUNT_W-1:0] count_q;

  reg valid_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pc_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] next_pc_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pred_npc_next_r [0:ENTRY_COUNT-1];
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx_next_r [0:ENTRY_COUNT-1];
  reg pred_taken_next_r [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst_next_r [0:ENTRY_COUNT-1];
  reg [`CTRL_BUS_W-1:0] ctrl_next_r [0:ENTRY_COUNT-1];
  reg [PRODUCER_ID_W-1:0] producer_id_next_r [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] src1_preg_next_r [0:ENTRY_COUNT-1];
  reg src1_ready_next_r [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] src2_preg_next_r [0:ENTRY_COUNT-1];
  reg src2_ready_next_r [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] pdest_next_r [0:ENTRY_COUNT-1];
  reg fp_pdest_next_r [0:ENTRY_COUNT-1];
  reg fp_st_en_next_r [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] fp_st_preg_next_r [0:ENTRY_COUNT-1];
  reg fp_st_ready_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] imm_next_r [0:ENTRY_COUNT-1];
  reg alu_terminal_capable_next_r [0:ENTRY_COUNT-1];
  reg plain_memory_terminal_capable_next_r [0:ENTRY_COUNT-1];
  reg fixed_gpr_producer_next_r [0:ENTRY_COUNT-1];
  reg [ENTRY_COUNT_W-1:0] count_next_r;
  reg [ENTRY_COUNT_W-1:0] kill_keep_cnt_w;   // B2 ROB-walk squash 后存活计数（组合算，避免 BLKSEQ）
  integer kc_i;

  // V13I static survivor map：每个目的槽只允许读取自身及后续两个候选源。
  // 这样较年轻 remove 条件不会通过动态 write pointer 回灌较老目的槽。
  wire [3:0] compact_remove_prefix_count_w [0:7];
  wire [7:0] compact_source0_sel_w;
  wire [7:0] compact_source1_sel_w;
  wire [7:0] compact_source2_sel_w;
  wire [ENTRY_STATE_W-1:0] compact_source_state_w [0:7];
  wire [ENTRY_STATE_W-1:0] compact_survivor_state_w [0:7];
  wire [ENTRY_STATE_W-1:0] compact_next_state_w [0:7];
  wire [ENTRY_STATE_W-1:0] dispatch0_state_w;
  wire [ENTRY_STATE_W-1:0] dispatch1_state_w;
  wire [7:0] compact_survivor_valid_w;
  wire [7:0] compact_first_free_w;
  wire [7:0] compact_dispatch0_slot_w;
  wire [7:0] compact_dispatch1_slot_w;
  wire [7:0] compact_next_valid_w;

  // R3.3：选择器只消费寄存阵列投影。8 路资格比较并行展开，oldest-two 与
  // first-ALU 由三层平衡前缀树产生，不再用 loop-carried found/older 状态。
  wire [7:0] select_valid_w;
  wire [7:0] select_base_ready_w;
  wire [7:0] select_memory_w;
  wire [7:0] select_alu_capable_w;
  wire [7:0] select_plain_memory_capable_w;
  wire [7:0] select_eligible_w;
  wire issue0_found_w;
  wire issue1_found_w;
  wire issue_pair_swapped_w;
  wire memory_pair_peek_found_w;
  wire [ENTRY_INDEX_W-1:0] issue0_idx_w;
  wire [ENTRY_INDEX_W-1:0] issue1_idx_w;
  wire [7:0] issue0_onehot_w;
  wire [7:0] issue1_onehot_w;

  // R3.6 timing cut: the balanced selector already produces a onehot owner.
  // Feed only the two issue0 PRF addresses from that onehot instead of
  // encoding it to issue0_idx_w and decoding it again through an indexed 8:1
  // mux on the selector->PRF->Universal-terminal critical path.  Other payload
  // and observability reads retain issue0_idx_w as their owner identity;
  // V13G compaction consumes the same selector onehot directly, qualified by
  // fire, so it does not encode and then decode the pop owner.
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_01_w =
      ({PHY_REG_ADDR_W{issue0_onehot_w[0]}} & src1_preg_q[0]) |
      ({PHY_REG_ADDR_W{issue0_onehot_w[1]}} & src1_preg_q[1]);
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_23_w =
      ({PHY_REG_ADDR_W{issue0_onehot_w[2]}} & src1_preg_q[2]) |
      ({PHY_REG_ADDR_W{issue0_onehot_w[3]}} & src1_preg_q[3]);
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_45_w =
      ({PHY_REG_ADDR_W{issue0_onehot_w[4]}} & src1_preg_q[4]) |
      ({PHY_REG_ADDR_W{issue0_onehot_w[5]}} & src1_preg_q[5]);
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_67_w =
      ({PHY_REG_ADDR_W{issue0_onehot_w[6]}} & src1_preg_q[6]) |
      ({PHY_REG_ADDR_W{issue0_onehot_w[7]}} & src1_preg_q[7]);
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_03_w =
      issue0_src1_preg_01_w | issue0_src1_preg_23_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_47_w =
      issue0_src1_preg_45_w | issue0_src1_preg_67_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg_onehot_w =
      issue0_src1_preg_03_w | issue0_src1_preg_47_w;

  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_01_w =
      ({PHY_REG_ADDR_W{issue0_onehot_w[0]}} & src2_preg_q[0]) |
      ({PHY_REG_ADDR_W{issue0_onehot_w[1]}} & src2_preg_q[1]);
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_23_w =
      ({PHY_REG_ADDR_W{issue0_onehot_w[2]}} & src2_preg_q[2]) |
      ({PHY_REG_ADDR_W{issue0_onehot_w[3]}} & src2_preg_q[3]);
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_45_w =
      ({PHY_REG_ADDR_W{issue0_onehot_w[4]}} & src2_preg_q[4]) |
      ({PHY_REG_ADDR_W{issue0_onehot_w[5]}} & src2_preg_q[5]);
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_67_w =
      ({PHY_REG_ADDR_W{issue0_onehot_w[6]}} & src2_preg_q[6]) |
      ({PHY_REG_ADDR_W{issue0_onehot_w[7]}} & src2_preg_q[7]);
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_03_w =
      issue0_src2_preg_01_w | issue0_src2_preg_23_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_47_w =
      issue0_src2_preg_45_w | issue0_src2_preg_67_w;
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg_onehot_w =
      issue0_src2_preg_03_w | issue0_src2_preg_47_w;

  wire issue0_fire_w = issue0_valid_o && issue0_ready_i;
  wire issue1_fire_w = issue1_valid_o && issue1_ready_i;
  wire memory_pair_peek_fire_w =
      memory_pair_peek_valid_o && memory_pair_peek_ready_i;
  // V13G: selector 已经给出唯一 owner onehot；compaction 直接消费 fire-qualified
  // entry bit，避免 onehot 编码成 binary index 后再对 8 项逐项比较。memory-pair
  // peek 固定原子移除 packed-age 队首两项。该 mask 只改变 owner 表示，不改变
  // fire、年龄、双 pop 或 payload copy 语义。
  wire [7:0] compact_remove_w =
      ({8{issue0_fire_w}} & issue0_onehot_w) |
      ({8{issue1_fire_w}} & issue1_onehot_w) |
      ({8{memory_pair_peek_fire_w}} & 8'b0000_0011);
  // 8 个 1-bit remove 先按 2/4 项平衡求和，再形成局部前缀计数。对目的槽 d，
  // source select 最多消费 prefix[d+1]；高于 d+2 的 remove 位没有物理扇入。
  wire [3:0] compact_remove_count_01_w;
  wire [3:0] compact_remove_count_23_w;
  wire [3:0] compact_remove_count_45_w;
  wire [3:0] compact_remove_count_67_w;
  wire [3:0] compact_remove_count_03_w;
  wire [3:0] compact_remove_count_47_w;
  assign compact_remove_count_01_w =
      {3'b000, compact_remove_w[0]} + {3'b000, compact_remove_w[1]};
  assign compact_remove_count_23_w =
      {3'b000, compact_remove_w[2]} + {3'b000, compact_remove_w[3]};
  assign compact_remove_count_45_w =
      {3'b000, compact_remove_w[4]} + {3'b000, compact_remove_w[5]};
  assign compact_remove_count_67_w =
      {3'b000, compact_remove_w[6]} + {3'b000, compact_remove_w[7]};
  assign compact_remove_count_03_w =
      compact_remove_count_01_w + compact_remove_count_23_w;
  assign compact_remove_count_47_w =
      compact_remove_count_45_w + compact_remove_count_67_w;
  assign compact_remove_prefix_count_w[0] = {3'b000, compact_remove_w[0]};
  assign compact_remove_prefix_count_w[1] = compact_remove_count_01_w;
  assign compact_remove_prefix_count_w[2] =
      compact_remove_count_01_w + {3'b000, compact_remove_w[2]};
  assign compact_remove_prefix_count_w[3] = compact_remove_count_03_w;
  assign compact_remove_prefix_count_w[4] =
      compact_remove_count_03_w + {3'b000, compact_remove_w[4]};
  assign compact_remove_prefix_count_w[5] =
      compact_remove_count_03_w + compact_remove_count_45_w;
  assign compact_remove_prefix_count_w[6] =
      compact_remove_count_03_w + compact_remove_count_45_w +
      {3'b000, compact_remove_w[6]};
  assign compact_remove_prefix_count_w[7] =
      compact_remove_count_03_w + compact_remove_count_47_w;
  wire [ENTRY_COUNT_W-1:0] free_slots_w =
      ENTRY_COUNT[ENTRY_COUNT_W-1:0] - count_q;
  wire dispatch0_fire_w = dispatch0_valid_i && dispatch0_ready_o;
  wire dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o;

  integer compact_i;
  integer reset_i;

  function wakeup_match;
    input [PHY_REG_ADDR_W-1:0] preg;
    input wakeup0_valid;
    input [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
    input wakeup1_valid;
    input [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
    input early_wakeup0_valid;
    input [PHY_REG_ADDR_W-1:0] early_wakeup0_pdest;
    input early_wakeup1_valid;
    input [PHY_REG_ADDR_W-1:0] early_wakeup1_pdest;
    begin
      wakeup_match = (preg != {PHY_REG_ADDR_W{1'b0}}) &&
                     ((wakeup0_valid && (wakeup0_pdest == preg)) ||
                      (wakeup1_valid && (wakeup1_pdest == preg)) ||
                      (early_wakeup0_valid &&
                       (early_wakeup0_pdest == preg)) ||
                      (early_wakeup1_valid &&
                       (early_wakeup1_pdest == preg)));
    end
  endfunction

  // FP preg0 对应真实 f0，不能复用上面的整数 x0 过滤规则。
  function fp_wakeup_match;
    input [PHY_REG_ADDR_W-1:0] preg;
    input wakeup0_valid;
    input [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
    input wakeup1_valid;
    input [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
    begin
      fp_wakeup_match =
          (wakeup0_valid && (wakeup0_pdest == preg)) ||
          (wakeup1_valid && (wakeup1_pdest == preg));
    end
  endfunction

  function ctrl_is_mem;
    input ctrl_load;
    input ctrl_store;
    begin
      ctrl_is_mem = ctrl_load || ctrl_store;
    end
  endfunction

  // R3：这是物理 ALU terminal 的 capability，不是 dispatch lane 或程序序 lane
  // 的永久语义。Universal terminal 可接任意 ready 类别；ALU terminal 只接固定
  // 延迟 RV64I simple-ALU。select 会按 capability 动态交换两条 resident uop。
  function ctrl_is_alu_terminal_capable;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
      ctrl_is_alu_terminal_capable =
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

  function ctrl_is_plain_memory_terminal_capable;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
      ctrl_is_plain_memory_terminal_capable =
          ctrl[`CTRL_VALID_BIT] && ctrl[`CTRL_NEED_MEM_BIT] &&
          (ctrl[`CTRL_LOAD_BIT] || ctrl[`CTRL_STORE_BIT]) &&
          !ctrl[`CTRL_AMO_BIT];
    end
  endfunction

  function inst_is_clmul;
    input [`INST_W-1:0] inst;
    begin
      inst_is_clmul =
          (inst[6:0] == `OPCODE_OP) && (inst[31:25] == 7'h05) &&
          ((inst[14:12] == `FUNCT3_SLL) ||
           (inst[14:12] == `FUNCT3_SLT) ||
           (inst[14:12] == `FUNCT3_SLTU));
    end
  endfunction

  // The lookahead domain is deliberately narrower than "writes rd".
  // Memory/AMO, MulDiv, CLMUL, CSR, FP, control-flow and all synchronous
  // exception/system classes keep the formal WB sticky-wake latency.
  function ctrl_is_fixed_gpr_producer;
    input [`CTRL_BUS_W-1:0] ctrl;
    input [`INST_W-1:0] inst;
    input is_fp;
    input fp_pdest;
    input fp_st_src;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      ctrl_is_fixed_gpr_producer =
          ctrl[`CTRL_VALID_BIT] &&
          ctrl[`CTRL_RD_EN_BIT] &&
          ctrl[`CTRL_NEED_EXEC_BIT] &&
          ctrl[`CTRL_NEED_WB_BIT] &&
          !ctrl[`CTRL_NEED_MEM_BIT] &&
          (pdest != {PHY_REG_ADDR_W{1'b0}}) &&
          !is_fp && !fp_pdest && !fp_st_src &&
          !ctrl[`CTRL_LOAD_BIT] && !ctrl[`CTRL_STORE_BIT] &&
          !ctrl[`CTRL_AMO_BIT] && !ctrl[`CTRL_MULDIV_BIT] &&
          !inst_is_clmul(inst) &&
          !ctrl[`CTRL_CSR_BIT] &&
          !ctrl[`CTRL_BRANCH_BIT] && !ctrl[`CTRL_JAL_BIT] &&
          !ctrl[`CTRL_JALR_BIT] &&
          !ctrl[`CTRL_ILLEGAL_BIT] &&
          !ctrl[`CTRL_ECALL_BIT] && !ctrl[`CTRL_EBREAK_BIT] &&
          !ctrl[`CTRL_FENCE_BIT] && !ctrl[`CTRL_FENCEI_BIT] &&
          !ctrl[`CTRL_SYSTEM_BIT] && !ctrl[`CTRL_MISC_MEM_BIT] &&
          !ctrl[`CTRL_MRET_BIT] && !ctrl[`CTRL_SRET_BIT] &&
          !ctrl[`CTRL_WFI_BIT] && !ctrl[`CTRL_SFENCE_VMA_BIT] &&
          !ctrl[`CTRL_SFENCE_TVM_BIT] &&
          ((ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] == `WB_SEL_ALU) ||
           (ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] == `WB_SEL_IMM));
    end
  endfunction

  // V13I：把既有 entry 字段视为一条并行搬运总线。resident payload 在进入
  // survivor mux 前吸收本拍 sticky wake；dispatch payload 保持原写入臂的全部判定。
  genvar compact_g;
  generate
    for (compact_g = 0; compact_g < 8; compact_g = compact_g + 1) begin : gen_compact_source
      assign compact_source_state_w[compact_g] = {
        pc_q[compact_g],
        next_pc_q[compact_g],
        pred_npc_q[compact_g],
        bht_idx_q[compact_g],
        pred_taken_q[compact_g],
        inst_q[compact_g],
        ctrl_q[compact_g],
        producer_id_q[compact_g],
        src1_preg_q[compact_g],
        src1_ready_q[compact_g] ||
            wakeup_match(src1_preg_q[compact_g],
                         wakeup0_valid_i, wakeup0_pdest_i,
                         wakeup1_valid_i, wakeup1_pdest_i,
                         early_wakeup0_valid_i, early_wakeup0_pdest_i,
                         early_wakeup1_valid_i, early_wakeup1_pdest_i),
        src2_preg_q[compact_g],
        src2_ready_q[compact_g] ||
            wakeup_match(src2_preg_q[compact_g],
                         wakeup0_valid_i, wakeup0_pdest_i,
                         wakeup1_valid_i, wakeup1_pdest_i,
                         early_wakeup0_valid_i, early_wakeup0_pdest_i,
                         early_wakeup1_valid_i, early_wakeup1_pdest_i),
        pdest_q[compact_g],
        fp_pdest_q[compact_g],
        fp_st_en_q[compact_g],
        fp_st_preg_q[compact_g],
        fp_st_ready_q[compact_g] ||
            (fp_wake0_valid_i &&
             (fp_wake0_preg_i == fp_st_preg_q[compact_g])) ||
            (fp_wake1_valid_i &&
             (fp_wake1_preg_i == fp_st_preg_q[compact_g])),
        imm_q[compact_g],
        alu_terminal_capable_q[compact_g],
        plain_memory_terminal_capable_q[compact_g],
        fixed_gpr_producer_q[compact_g]
      };

      // packed queue 每拍最多删除两项，因此目的槽 d 只可能来自 d/d+1/d+2。
      assign compact_source0_sel_w[compact_g] =
          (compact_remove_prefix_count_w[compact_g] == 4'd0);
      if (compact_g < 6) begin : gen_three_source
        assign compact_source1_sel_w[compact_g] =
            (compact_remove_prefix_count_w[compact_g] == 4'd1) &&
            !compact_remove_w[compact_g+1];
        assign compact_source2_sel_w[compact_g] =
            (compact_remove_prefix_count_w[compact_g+1] == 4'd2) &&
            !compact_remove_w[compact_g+2];
        assign compact_survivor_valid_w[compact_g] =
            (compact_source0_sel_w[compact_g] && valid_q[compact_g]) ||
            (compact_source1_sel_w[compact_g] && valid_q[compact_g+1]) ||
            (compact_source2_sel_w[compact_g] && valid_q[compact_g+2]);
        assign compact_survivor_state_w[compact_g] =
            ({ENTRY_STATE_W{compact_source0_sel_w[compact_g]}} &
             compact_source_state_w[compact_g]) |
            ({ENTRY_STATE_W{compact_source1_sel_w[compact_g]}} &
             compact_source_state_w[compact_g+1]) |
            ({ENTRY_STATE_W{compact_source2_sel_w[compact_g]}} &
             compact_source_state_w[compact_g+2]);
      end else if (compact_g == 6) begin : gen_two_source
        assign compact_source1_sel_w[compact_g] =
            (compact_remove_prefix_count_w[compact_g] == 4'd1) &&
            !compact_remove_w[compact_g+1];
        assign compact_source2_sel_w[compact_g] = 1'b0;
        assign compact_survivor_valid_w[compact_g] =
            (compact_source0_sel_w[compact_g] && valid_q[compact_g]) ||
            (compact_source1_sel_w[compact_g] && valid_q[compact_g+1]);
        assign compact_survivor_state_w[compact_g] =
            ({ENTRY_STATE_W{compact_source0_sel_w[compact_g]}} &
             compact_source_state_w[compact_g]) |
            ({ENTRY_STATE_W{compact_source1_sel_w[compact_g]}} &
             compact_source_state_w[compact_g+1]);
      end else begin : gen_one_source
        assign compact_source1_sel_w[compact_g] = 1'b0;
        assign compact_source2_sel_w[compact_g] = 1'b0;
        assign compact_survivor_valid_w[compact_g] =
            compact_source0_sel_w[compact_g] && valid_q[compact_g];
        assign compact_survivor_state_w[compact_g] =
            {ENTRY_STATE_W{compact_source0_sel_w[compact_g]}} &
            compact_source_state_w[compact_g];
      end

      if (compact_g == 0) begin : gen_first_free_head
        assign compact_first_free_w[compact_g] =
            !compact_survivor_valid_w[compact_g];
      end else begin : gen_first_free_tail
        assign compact_first_free_w[compact_g] =
            compact_survivor_valid_w[compact_g-1] &&
            !compact_survivor_valid_w[compact_g];
      end
    end
  endgenerate

  assign dispatch0_state_w = {
    dispatch0_pc_i,
    dispatch0_next_pc_i,
    dispatch0_pred_npc_i,
    dispatch0_bht_idx_i,
    dispatch0_pred_taken_i,
    dispatch0_inst_i,
    dispatch0_ctrl_i,
    dispatch0_producer_id_i,
    dispatch0_src1_preg_i,
    dispatch0_src1_ready_i ||
        wakeup_match(dispatch0_src1_preg_i,
                     wakeup0_valid_i, wakeup0_pdest_i,
                     wakeup1_valid_i, wakeup1_pdest_i,
                     early_wakeup0_valid_i, early_wakeup0_pdest_i,
                     early_wakeup1_valid_i, early_wakeup1_pdest_i),
    dispatch0_src2_preg_i,
    dispatch0_src2_ready_i ||
        wakeup_match(dispatch0_src2_preg_i,
                     wakeup0_valid_i, wakeup0_pdest_i,
                     wakeup1_valid_i, wakeup1_pdest_i,
                     early_wakeup0_valid_i, early_wakeup0_pdest_i,
                     early_wakeup1_valid_i, early_wakeup1_pdest_i),
    dispatch0_pdest_i,
    dispatch0_fp_pdest_i,
    dispatch0_fp_st_src_en_i,
    dispatch0_fp_st_src_preg_i,
    dispatch0_fp_st_src_ready_i ||
        fp_wakeup_match(dispatch0_fp_st_src_preg_i,
                        fp_wake0_valid_i, fp_wake0_preg_i,
                        fp_wake1_valid_i, fp_wake1_preg_i),
    dispatch0_imm_i,
    ctrl_is_alu_terminal_capable(dispatch0_ctrl_i) &&
        !dispatch0_fp_pdest_i && !dispatch0_fp_st_src_en_i,
    ctrl_is_plain_memory_terminal_capable(dispatch0_ctrl_i) &&
        !dispatch0_is_fp_i && !dispatch0_fp_pdest_i &&
        !dispatch0_fp_st_src_en_i,
    ctrl_is_fixed_gpr_producer(
        dispatch0_ctrl_i, dispatch0_inst_i, dispatch0_is_fp_i,
        dispatch0_fp_pdest_i, dispatch0_fp_st_src_en_i,
        dispatch0_pdest_i)
  };

  assign dispatch1_state_w = {
    dispatch1_pc_i,
    dispatch1_next_pc_i,
    dispatch1_pred_npc_i,
    dispatch1_bht_idx_i,
    dispatch1_pred_taken_i,
    dispatch1_inst_i,
    dispatch1_ctrl_i,
    dispatch1_producer_id_i,
    dispatch1_src1_preg_i,
    dispatch1_src1_ready_i ||
        wakeup_match(dispatch1_src1_preg_i,
                     wakeup0_valid_i, wakeup0_pdest_i,
                     wakeup1_valid_i, wakeup1_pdest_i,
                     early_wakeup0_valid_i, early_wakeup0_pdest_i,
                     early_wakeup1_valid_i, early_wakeup1_pdest_i),
    dispatch1_src2_preg_i,
    dispatch1_src2_ready_i ||
        wakeup_match(dispatch1_src2_preg_i,
                     wakeup0_valid_i, wakeup0_pdest_i,
                     wakeup1_valid_i, wakeup1_pdest_i,
                     early_wakeup0_valid_i, early_wakeup0_pdest_i,
                     early_wakeup1_valid_i, early_wakeup1_pdest_i),
    dispatch1_pdest_i,
    dispatch1_fp_pdest_i,
    dispatch1_fp_st_src_en_i,
    dispatch1_fp_st_src_preg_i,
    dispatch1_fp_st_src_ready_i ||
        fp_wakeup_match(dispatch1_fp_st_src_preg_i,
                        fp_wake0_valid_i, fp_wake0_preg_i,
                        fp_wake1_valid_i, fp_wake1_preg_i),
    dispatch1_imm_i,
    ctrl_is_alu_terminal_capable(dispatch1_ctrl_i) &&
        !dispatch1_fp_pdest_i && !dispatch1_fp_st_src_en_i,
    ctrl_is_plain_memory_terminal_capable(dispatch1_ctrl_i) &&
        !dispatch1_is_fp_i && !dispatch1_fp_pdest_i &&
        !dispatch1_fp_st_src_en_i,
    ctrl_is_fixed_gpr_producer(
        dispatch1_ctrl_i, dispatch1_inst_i, dispatch1_is_fp_i,
        dispatch1_fp_pdest_i, dispatch1_fp_st_src_en_i,
        dispatch1_pdest_i)
  };

  // survivor valid 仍是前缀；first_free 是第一个空槽的一位码。dispatch1 在
  // dispatch0 同拍写入时只把该一位码左移一槽，保持 lane0→lane1 append 顺序。
  assign compact_dispatch0_slot_w =
      {8{dispatch0_fire_w}} & compact_first_free_w;
  assign compact_dispatch1_slot_w = {8{dispatch1_fire_w}} &
      (dispatch0_fire_w ? (compact_first_free_w << 1) :
                          compact_first_free_w);
  assign compact_next_valid_w = compact_survivor_valid_w |
      compact_dispatch0_slot_w | compact_dispatch1_slot_w;

  genvar compact_next_g;
  generate
    for (compact_next_g = 0; compact_next_g < 8;
         compact_next_g = compact_next_g + 1) begin : gen_compact_next
      assign compact_next_state_w[compact_next_g] =
          compact_survivor_valid_w[compact_next_g] ?
              compact_survivor_state_w[compact_next_g] :
          compact_dispatch0_slot_w[compact_next_g] ? dispatch0_state_w :
          compact_dispatch1_slot_w[compact_next_g] ? dispatch1_state_w :
              {ENTRY_STATE_W{1'b0}};
    end
  endgenerate

  // 【P5 刀 B】dispatch 活值继续完全退出 select 锥。下面的 generate loop 只把
  // 8 个寄存 entry 投影成并行资格位，综合为 8 份比较/AND，不含跨迭代依赖。
  genvar select_g;
  generate
    for (select_g = 0; select_g < 8; select_g = select_g + 1) begin : gen_select_projection
      assign select_valid_w[select_g] = valid_q[select_g];
      assign select_memory_w[select_g] =
          ctrl_q[select_g][`CTRL_LOAD_BIT] ||
          ctrl_q[select_g][`CTRL_STORE_BIT] ||
          ctrl_q[select_g][`CTRL_AMO_BIT];
      assign select_alu_capable_w[select_g] =
          alu_terminal_capable_q[select_g];
      assign select_plain_memory_capable_w[select_g] =
          plain_memory_terminal_capable_q[select_g];
      assign select_base_ready_w[select_g] =
          valid_q[select_g] &&
          !(issue_mem_block_i &&
            ctrl_is_mem(ctrl_q[select_g][`CTRL_LOAD_BIT],
                        ctrl_q[select_g][`CTRL_STORE_BIT])) &&
          src1_ready_q[select_g] && src2_ready_q[select_g] &&
          // full/early/FP wake 仍只在 N 沿落 sticky；这里仅读 Q。
          (!fp_st_en_q[select_g] || fp_st_ready_q[select_g]);
    end
  endgenerate

  OooIntIssueSelect8 u_balanced_select (
    .valid_i(select_valid_w),
    .base_ready_i(select_base_ready_w),
    .memory_i(select_memory_w),
    .alu_capable_i(select_alu_capable_w),
    .plain_memory_capable_i(select_plain_memory_capable_w),
    .universal_owner_present_i(universal_owner_present_i),
    .memory_pair_peek_enable_i(memory_pair_peek_enable_i),
    .eligible_o(select_eligible_w),
    .issue0_found_o(issue0_found_w),
    .issue0_idx_o(issue0_idx_w),
    .issue0_onehot_o(issue0_onehot_w),
    .issue1_found_o(issue1_found_w),
    .issue1_idx_o(issue1_idx_w),
    .issue1_onehot_o(issue1_onehot_w),
    .issue_pair_swapped_o(issue_pair_swapped_w),
    .memory_pair_peek_valid_o(memory_pair_peek_found_w)
  );

  assign dispatch0_ready_o = (free_slots_w != {ENTRY_COUNT_W{1'b0}});
  assign dispatch1_ready_o = (free_slots_w > {{(ENTRY_COUNT_W-1){1'b0}}, dispatch0_fire_w});

  // 【P5 刀 B】issue payload 直读寄存阵列(dispatch 活值直通臂已删):
  // pred_npc 恒取寄存 pred_npc_q,pred_npc→mispredict→redirect→前端预测→pred_npc 的
  // 组合环 loop-free 性质由"select 唯一真源=寄存项"结构直接保证,不再依赖控制流禁 bypass 特例。
  assign issue0_valid_o = issue0_found_w && !universal_owner_present_i &&
                          !recover_active_i && !kill_valid_i;
  assign memory_pair_peek_valid_o = memory_pair_peek_found_w &&
      !recover_active_i && !kill_valid_i;
  assign issue_pair_swapped_o = issue_pair_swapped_w && issue0_valid_o && issue1_valid_o;
  assign issue0_pc_o = pc_q[issue0_idx_w];
  assign issue0_next_pc_o = next_pc_q[issue0_idx_w];
  assign issue0_pred_npc_o = pred_npc_q[issue0_idx_w];
  assign issue0_bht_idx_o = bht_idx_q[issue0_idx_w];
  assign issue0_pred_taken_o = pred_taken_q[issue0_idx_w];
  assign issue0_inst_o = inst_q[issue0_idx_w];
  assign issue0_ctrl_o = ctrl_q[issue0_idx_w];
  assign issue0_producer_id_o = producer_id_q[issue0_idx_w];
  assign issue0_rob_idx_o = issue0_producer_id_o[ROB_INDEX_W-1:0];
  assign issue0_src1_preg_o = issue0_src1_preg_onehot_w;
  assign issue0_src2_preg_o = issue0_src2_preg_onehot_w;
  assign issue0_pdest_o = pdest_q[issue0_idx_w];
  assign issue0_fixed_gpr_producer_o =
      fixed_gpr_producer_q[issue0_idx_w];
  assign issue0_fp_pdest_o = fp_pdest_q[issue0_idx_w];
  assign issue0_fp_st_src_en_o = fp_st_en_q[issue0_idx_w];
  assign issue0_fp_st_src_preg_o = fp_st_preg_q[issue0_idx_w];
  assign issue0_imm_o = imm_q[issue0_idx_w];

  // issue1 对 issue0 的"结果前递依赖"(issue1_depends_on_issue0)只可能出现在 bypass 臂,
  // 寄存项扫描恒置 0——bypass 删除后 issue1_valid 不再消费 issue0_fire(反压环少一条回边)。
  assign issue1_valid_o =
      issue1_found_w && !recover_active_i && !kill_valid_i;
  assign issue1_pc_o = pc_q[issue1_idx_w];
  assign issue1_next_pc_o = next_pc_q[issue1_idx_w];
  assign issue1_pred_npc_o = pred_npc_q[issue1_idx_w];
  assign issue1_bht_idx_o = bht_idx_q[issue1_idx_w];
  assign issue1_pred_taken_o = pred_taken_q[issue1_idx_w];
  assign issue1_inst_o = inst_q[issue1_idx_w];
  assign issue1_ctrl_o = ctrl_q[issue1_idx_w];
  assign issue1_producer_id_o = producer_id_q[issue1_idx_w];
  assign issue1_rob_idx_o = issue1_producer_id_o[ROB_INDEX_W-1:0];
  assign issue1_src1_preg_o = src1_preg_q[issue1_idx_w];
  assign issue1_src2_preg_o = src2_preg_q[issue1_idx_w];
  assign issue1_pdest_o = pdest_q[issue1_idx_w];
  assign issue1_fixed_gpr_producer_o =
      fixed_gpr_producer_q[issue1_idx_w];
  assign issue1_fp_pdest_o = fp_pdest_q[issue1_idx_w];
  assign issue1_fp_st_src_en_o = fp_st_en_q[issue1_idx_w];
  assign issue1_fp_st_src_preg_o = fp_st_preg_q[issue1_idx_w];
  assign issue1_imm_o = imm_q[issue1_idx_w];

  assign count_o = count_q;
  assign empty_o = (count_q == {ENTRY_COUNT_W{1'b0}});
  assign full_o = (count_q == ENTRY_COUNT[ENTRY_COUNT_W-1:0]);

  // v8l finite-generation lease: the integer IQ's only full-P field is the
  // uop owner producer_id_q.  Source dependencies are physical-register tags
  // plus sticky-ready bits, so there is no second source ProducerId to decode.
  reg [(1 << PRODUCER_ID_W)-1:0] producer_live_mask_r;
  always @(*) begin : producer_live_mask_blk
    integer lease_i;
    producer_live_mask_r = {(1 << PRODUCER_ID_W){1'b0}};
    for (lease_i = 0; lease_i < ENTRY_COUNT; lease_i = lease_i + 1) begin
      if (valid_q[lease_i])
        producer_live_mask_r[producer_id_q[lease_i]] = 1'b1;
    end
  end
  assign producer_live_mask_o = producer_live_mask_r;

  // 【P5 刀 B】issue fire 恒为寄存项 fire(dispatch 活值当拍被发射的情形不复存在),
  // 压缩逻辑直接消费 issue*_fire_w;dispatch fire 无条件写阵列。
  always @(*) begin
    for (compact_i = 0; compact_i < ENTRY_COUNT; compact_i = compact_i + 1) begin
      valid_next_r[compact_i] = compact_next_valid_w[compact_i];
      {
        pc_next_r[compact_i],
        next_pc_next_r[compact_i],
        pred_npc_next_r[compact_i],
        bht_idx_next_r[compact_i],
        pred_taken_next_r[compact_i],
        inst_next_r[compact_i],
        ctrl_next_r[compact_i],
        producer_id_next_r[compact_i],
        src1_preg_next_r[compact_i],
        src1_ready_next_r[compact_i],
        src2_preg_next_r[compact_i],
        src2_ready_next_r[compact_i],
        pdest_next_r[compact_i],
        fp_pdest_next_r[compact_i],
        fp_st_en_next_r[compact_i],
        fp_st_preg_next_r[compact_i],
        fp_st_ready_next_r[compact_i],
        imm_next_r[compact_i],
        alu_terminal_capable_next_r[compact_i],
        plain_memory_terminal_capable_next_r[compact_i],
        fixed_gpr_producer_next_r[compact_i]
      } = compact_next_state_w[compact_i];
    end

    count_next_r = count_q -
        compact_remove_prefix_count_w[7][ENTRY_COUNT_W-1:0] +
        {{(ENTRY_COUNT_W-1){1'b0}}, dispatch0_fire_w} +
        {{(ENTRY_COUNT_W-1){1'b0}}, dispatch1_fire_w};
  end

  // B2 ROB-walk squash 后存活计数（组合）：valid 且 age 不大于 kill 的 entry 数。
  always @(*) begin
    kill_keep_cnt_w = {ENTRY_COUNT_W{1'b0}};
    for (kc_i = 0; kc_i < ENTRY_COUNT; kc_i = kc_i + 1) begin
      if (valid_q[kc_i] &&
          !((producer_id_q[kc_i][ROB_INDEX_W-1:0] - rob_head_idx_i) >
            (kill_rob_idx_i - rob_head_idx_i))) begin
        kill_keep_cnt_w = kill_keep_cnt_w + {{(ENTRY_COUNT_W-1){1'b0}}, 1'b1};
      end
    end
  end

  always @(posedge clk) begin
    if (rst || flush_i) begin
      count_q <= {ENTRY_COUNT_W{1'b0}};
      for (reset_i = 0; reset_i < ENTRY_COUNT; reset_i = reset_i + 1) begin
        valid_q[reset_i] <= 1'b0;
        pc_q[reset_i] <= {`XLEN{1'b0}};
        next_pc_q[reset_i] <= {`XLEN{1'b0}};
        pred_npc_q[reset_i] <= {`XLEN{1'b0}};
        bht_idx_q[reset_i] <= {`BPU_BHT_INDEX_W{1'b0}};
        pred_taken_q[reset_i] <= 1'b0;
        inst_q[reset_i] <= {`INST_W{1'b0}};
        ctrl_q[reset_i] <= {`CTRL_BUS_W{1'b0}};
        producer_id_q[reset_i] <= {PRODUCER_ID_W{1'b0}};
        src1_preg_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        src1_ready_q[reset_i] <= 1'b0;
        src2_preg_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        src2_ready_q[reset_i] <= 1'b0;
        pdest_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        fp_pdest_q[reset_i] <= 1'b0;
        fp_st_en_q[reset_i] <= 1'b0;
        fp_st_preg_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        fp_st_ready_q[reset_i] <= 1'b0;
        imm_q[reset_i] <= {`XLEN{1'b0}};
        alu_terminal_capable_q[reset_i] <= 1'b0;
        plain_memory_terminal_capable_q[reset_i] <= 1'b0;
        fixed_gpr_producer_q[reset_i] <= 1'b0;
      end
    end else if (kill_valid_i) begin
      // ROB-walk squash：清掉比 kill_rob_idx 更年轻(age 更大)的 entry（程序序后缀），存活=前缀，已紧凑。
      // 存活前缀必须继续吸收当拍 wakeup，否则 kill 与 writeback 同拍时唤醒永久丢失
      // （mode 下 wrong-path 每拍发 kill，load writeback 撞上 kill 拍 → jalr 等 load 结果死锁）。
      for (reset_i = 0; reset_i < ENTRY_COUNT; reset_i = reset_i + 1) begin
        if (valid_q[reset_i] &&
            ((producer_id_q[reset_i][ROB_INDEX_W-1:0] - rob_head_idx_i) >
             (kill_rob_idx_i - rob_head_idx_i))) begin
          valid_q[reset_i] <= 1'b0;
        end else if (valid_q[reset_i]) begin
          src1_ready_q[reset_i] <= src1_ready_q[reset_i] ||
              wakeup_match(src1_preg_q[reset_i],
                           wakeup0_valid_i, wakeup0_pdest_i,
                           wakeup1_valid_i, wakeup1_pdest_i,
                           early_wakeup0_valid_i, early_wakeup0_pdest_i,
                           early_wakeup1_valid_i, early_wakeup1_pdest_i);
          src2_ready_q[reset_i] <= src2_ready_q[reset_i] ||
              wakeup_match(src2_preg_q[reset_i],
                           wakeup0_valid_i, wakeup0_pdest_i,
                           wakeup1_valid_i, wakeup1_pdest_i,
                           early_wakeup0_valid_i, early_wakeup0_pdest_i,
                           early_wakeup1_valid_i, early_wakeup1_pdest_i);
          fp_st_ready_q[reset_i] <= fp_st_ready_q[reset_i] ||
              (fp_wake0_valid_i &&
               (fp_wake0_preg_i == fp_st_preg_q[reset_i])) ||
              (fp_wake1_valid_i &&
               (fp_wake1_preg_i == fp_st_preg_q[reset_i]));
        end
      end
      count_q <= kill_keep_cnt_w;
    end else begin
      count_q <= count_next_r;
      for (reset_i = 0; reset_i < ENTRY_COUNT; reset_i = reset_i + 1) begin
        valid_q[reset_i] <= valid_next_r[reset_i];
        pc_q[reset_i] <= pc_next_r[reset_i];
        next_pc_q[reset_i] <= next_pc_next_r[reset_i];
        pred_npc_q[reset_i] <= pred_npc_next_r[reset_i];
        bht_idx_q[reset_i] <= bht_idx_next_r[reset_i];
        pred_taken_q[reset_i] <= pred_taken_next_r[reset_i];
        inst_q[reset_i] <= inst_next_r[reset_i];
        ctrl_q[reset_i] <= ctrl_next_r[reset_i];
        producer_id_q[reset_i] <= producer_id_next_r[reset_i];
        src1_preg_q[reset_i] <= src1_preg_next_r[reset_i];
        src1_ready_q[reset_i] <= src1_ready_next_r[reset_i];
        src2_preg_q[reset_i] <= src2_preg_next_r[reset_i];
        src2_ready_q[reset_i] <= src2_ready_next_r[reset_i];
        pdest_q[reset_i] <= pdest_next_r[reset_i];
        fp_pdest_q[reset_i] <= fp_pdest_next_r[reset_i];
        fp_st_en_q[reset_i] <= fp_st_en_next_r[reset_i];
        fp_st_preg_q[reset_i] <= fp_st_preg_next_r[reset_i];
        fp_st_ready_q[reset_i] <= fp_st_ready_next_r[reset_i];
        imm_q[reset_i] <= imm_next_r[reset_i];
        alu_terminal_capable_q[reset_i] <=
            alu_terminal_capable_next_r[reset_i];
        plain_memory_terminal_capable_q[reset_i] <=
            plain_memory_terminal_capable_next_r[reset_i];
        fixed_gpr_producer_q[reset_i] <=
            fixed_gpr_producer_next_r[reset_i];
      end
    end
  end

`ifdef OOO_ASSERT
  // ===== P5 刀 B 契约立即断言(不可弱化) =====
  // IQ-NO-BYPASS:select 唯一真源=已寄存 valid_q 阵列项。删除 dispatch→issue bypass 后,
  // 任何被选中发射的 lane 必须指向 valid_q=1 的寄存项;若重新引入"dispatch 活值当拍参与
  // select"的臂,选中槽位将不是寄存项,此断言当拍命中(负测试证据见
  // .github/task-runs/2026-07-09-p5-first-batch/)。
  // IQ-KILL-NO-DISPATCH:kill 拍不得有 dispatch valid——T3N resolve packet 自身已经
  // 寄存，上游 OooDispatchBackend 直接用同一个 q valid 生成 dispatch_freeze。
  // 该互斥是"当拍 dispatch 写入+同拍 kill"窗口结构性不存在的承重契约:本模块 kill 分支
  // 不消费 valid_next_r 写入计划,若互斥被破坏,kill 拍的新写项会被静默丢弃而非入队。
  // V13I reference 只存在于 assertion build：它保留旧式 source-order scan，
  // 以独立算法逐槽复核静态 survivor/source 网络，不进入 production mapped netlist。
  reg [7:0] compact_reference_valid_r;
  reg [ENTRY_STATE_W-1:0] compact_reference_state_r [0:7];
  reg [ENTRY_COUNT_W-1:0] compact_reference_count_r;
  integer compact_reference_i;
  integer compact_reference_write_i;
  always @(*) begin
    compact_reference_valid_r = 8'b0;
    compact_reference_count_r = {ENTRY_COUNT_W{1'b0}};
    compact_reference_write_i = 0;
    for (compact_reference_i = 0; compact_reference_i < 8;
         compact_reference_i = compact_reference_i + 1) begin
      compact_reference_state_r[compact_reference_i] =
          {ENTRY_STATE_W{1'b0}};
    end
    for (compact_reference_i = 0; compact_reference_i < 8;
         compact_reference_i = compact_reference_i + 1) begin
      if (valid_q[compact_reference_i] &&
          !compact_remove_w[compact_reference_i]) begin
        compact_reference_valid_r[compact_reference_write_i] = 1'b1;
        compact_reference_state_r[compact_reference_write_i] =
            compact_source_state_w[compact_reference_i];
        compact_reference_write_i = compact_reference_write_i + 1;
      end
    end
    if (dispatch0_fire_w && (compact_reference_write_i < 8)) begin
      compact_reference_valid_r[compact_reference_write_i] = 1'b1;
      compact_reference_state_r[compact_reference_write_i] = dispatch0_state_w;
      compact_reference_write_i = compact_reference_write_i + 1;
    end
    if (dispatch1_fire_w && (compact_reference_write_i < 8)) begin
      compact_reference_valid_r[compact_reference_write_i] = 1'b1;
      compact_reference_state_r[compact_reference_write_i] = dispatch1_state_w;
      compact_reference_write_i = compact_reference_write_i + 1;
    end
    compact_reference_count_r =
        compact_reference_write_i[ENTRY_COUNT_W-1:0];
  end

  integer pack_assert_i;
  always @(posedge clk) begin
    if (!rst) begin
      if (ENTRY_COUNT != 8)
        $error("[IQ-R3P3-FIXED-EIGHT] balanced selector requires ENTRY_COUNT=8 @%0t",
               $time);
      // R3.3 的 memory-index 特化只建立在 IQ 既有 packed age order 上；
      // 任一洞态都会让“index1=唯一 older”不再成立，必须 fail closed。
      for (pack_assert_i = 1; pack_assert_i < 8;
           pack_assert_i = pack_assert_i + 1) begin
        if (valid_q[pack_assert_i] && !valid_q[pack_assert_i-1])
          $error("[IQ-R3P3-PACKED-AGE] valid hole before idx=%0d @%0t",
                 pack_assert_i, $time);
      end
      if (!flush_i && !kill_valid_i) begin
        if (^compact_remove_w === 1'bx)
          $error("[IQ-V13I-REMOVE-KNOWN] compact remove mask contains X/Z @%0t",
                 $time);
        if ((compact_remove_w & ~select_valid_w) !== 8'b0)
          $error("[IQ-V13I-REMOVE-VALID] remove mask selected a non-resident entry mask=%h valid=%h @%0t",
                 compact_remove_w, select_valid_w, $time);
        if (compact_remove_prefix_count_w[7] > 4'd2)
          $error("[IQ-V13I-REMOVE-COUNT] normal compaction removes more than two entries count=%0d @%0t",
                 compact_remove_prefix_count_w[7], $time);
        if (compact_next_valid_w !== compact_reference_valid_r)
          $error("[IQ-V13I-SURVIVOR-VALID] static map disagrees with scan reference got=%h ref=%h @%0t",
                 compact_next_valid_w, compact_reference_valid_r, $time);
        if (count_next_r !== compact_reference_count_r)
          $error("[IQ-V13I-SURVIVOR-COUNT] static count=%0d ref=%0d @%0t",
                 count_next_r, compact_reference_count_r, $time);
        for (pack_assert_i = 0; pack_assert_i < 8;
             pack_assert_i = pack_assert_i + 1) begin
          if (compact_next_state_w[pack_assert_i] !==
              compact_reference_state_r[pack_assert_i])
            $error("[IQ-V13I-SURVIVOR-PAYLOAD] destination=%0d remove=%h valid=%h sel={%h,%h,%h} static=%h reference=%h @%0t",
                   pack_assert_i, compact_remove_w, select_valid_w,
                   compact_source2_sel_w, compact_source1_sel_w,
                   compact_source0_sel_w,
                   compact_next_state_w[pack_assert_i],
                   compact_reference_state_r[pack_assert_i], $time);
        end
      end
      if ((issue0_onehot_w & (issue0_onehot_w - 8'b1)) != 8'b0)
        $error("[IQ-R3P3-ISSUE0-ONEHOT] issue0 owner is not onehot @%0t",
               $time);
      if ((issue1_onehot_w & (issue1_onehot_w - 8'b1)) != 8'b0)
        $error("[IQ-R3P3-ISSUE1-ONEHOT] issue1 owner is not onehot @%0t",
               $time);
      if (issue0_valid_o && select_memory_w[issue0_idx_w] &&
          (issue0_idx_w != {ENTRY_INDEX_W{1'b0}}) &&
          !((issue0_idx_w == {{(ENTRY_INDEX_W-1){1'b0}}, 1'b1}) &&
            issue_pair_swapped_o && issue1_valid_o &&
            (issue1_idx_w == {ENTRY_INDEX_W{1'b0}}) &&
            select_base_ready_w[0] && select_alu_capable_w[0] &&
            !universal_owner_present_i))
        $error("[IQ-R3P3-MEMORY-PREFIX] non-head memory lacked unique older-ready ALU pair idx=%0d @%0t",
               issue0_idx_w, $time);
      if (universal_owner_present_i && issue0_valid_o)
        $error("[IQ-UNIVERSAL-OWNER-EXCLUSIVE] registered owner overlapped resident issue0 @%0t",
               $time);
      if (memory_pair_peek_valid_o &&
          (issue0_valid_o || issue1_valid_o))
        $error("[V8U-IQ-PAIR-PEEK-EXCLUSIVE] pair peek overlapped regular issue @%0t",
               $time);
      if (memory_pair_peek_valid_o &&
          ((issue0_idx_w != {ENTRY_INDEX_W{1'b0}}) ||
           (issue1_idx_w != {{(ENTRY_INDEX_W-1){1'b0}}, 1'b1}) ||
           !plain_memory_terminal_capable_q[0] ||
           !plain_memory_terminal_capable_q[1] ||
           !select_base_ready_w[0] || !select_base_ready_w[1]))
        $error("[V8U-IQ-PAIR-PEEK-IDENTITY] pair peek was not ready resident entries 0/1 @%0t",
               $time);
      if (memory_pair_peek_fire_w &&
          (!memory_pair_peek_enable_i || !universal_owner_present_i))
        $error("[V8U-IQ-PAIR-PEEK-FIRE] pair dequeue lacked Q-only owner enable @%0t",
               $time);
      if (memory_pair_peek_fire_w &&
          ((!valid_q[0]) || (!valid_q[1]) ||
           (count_q < {{(ENTRY_COUNT_W-2){1'b0}}, 2'd2}) ||
           issue0_fire_w || issue1_fire_w ||
           (issue0_producer_id_o != producer_id_q[0]) ||
           (issue1_producer_id_o != producer_id_q[1])))
        $error("[V8U-IQ-PAIR-PEEK-POP2] pair dequeue was not an exclusive exact entry0/entry1 pop2 @%0t",
               $time);
      if (memory_pair_peek_fire_w &&
          ({1'b0, count_next_r} !==
           ({1'b0, count_q} - {{ENTRY_COUNT_W-1{1'b0}}, 2'd2} +
            {{ENTRY_COUNT_W{1'b0}}, dispatch0_fire_w} +
            {{ENTRY_COUNT_W{1'b0}}, dispatch1_fire_w})))
        $error("[V8U-IQ-PAIR-PEEK-COUNT] pair dequeue count delta was not pop2 plus accepted dispatch @%0t",
               $time);
      if (issue0_valid_o && issue1_valid_o &&
          (issue0_idx_w == issue1_idx_w))
        $error("[IQ-DYNAMIC-OWNER-DUP] one entry selected by both terminals idx=%0d @%0t",
               issue0_idx_w, $time);
      if (issue_pair_swapped_o &&
          !(issue1_idx_w < issue0_idx_w))
        $error("[IQ-DYNAMIC-OWNER-AGE] swapped pair lacks older issue1: i0=%0d i1=%0d @%0t",
               issue0_idx_w, issue1_idx_w, $time);
      if (issue_pair_swapped_o &&
          (!alu_terminal_capable_q[issue1_idx_w] ||
           alu_terminal_capable_q[issue0_idx_w]))
        $error("[IQ-DYNAMIC-OWNER-CAP] swapped capability mismatch i0=%0d i1=%0d @%0t",
               issue0_idx_w, issue1_idx_w, $time);
      if (issue0_valid_o && !valid_q[issue0_idx_w])
        $error("[IQ-NO-BYPASS] issue0 select 源非寄存 valid_q 项: idx=%0d @%0t",
               issue0_idx_w, $time);
      if (issue1_valid_o && !valid_q[issue1_idx_w])
        $error("[IQ-NO-BYPASS] issue1 select 源非寄存 valid_q 项: idx=%0d @%0t",
               issue1_idx_w, $time);
      if (issue1_valid_o &&
          (issue1_ctrl_o[`CTRL_BRANCH_BIT] || issue1_ctrl_o[`CTRL_JAL_BIT] ||
           issue1_ctrl_o[`CTRL_JALR_BIT]))
        $error("[IQ-CTRL-LANE0-OWNER] issue1 selected control-flow idx=%0d rob=%0d @%0t",
               issue1_idx_w, issue1_rob_idx_o, $time);
      if (issue1_valid_o &&
          !(ctrl_is_alu_terminal_capable(issue1_ctrl_o) ||
            plain_memory_terminal_capable_q[issue1_idx_w]) )
        $error("[V8P-IQ-TERMINAL1-CAPABILITY] issue1 selected unsupported uop idx=%0d rob=%0d ctrl=%h @%0t",
               issue1_idx_w, issue1_rob_idx_o, issue1_ctrl_o, $time);
      if (issue1_valid_o && select_memory_w[issue1_idx_w] &&
          !(issue0_valid_o && select_memory_w[issue0_idx_w] &&
            (issue0_idx_w < issue1_idx_w) &&
            plain_memory_terminal_capable_q[issue0_idx_w] &&
            plain_memory_terminal_capable_q[issue1_idx_w]))
        $error("[V8P-IQ-MEMORY-PAIR-AGE] issue1 memory lacks older issue0 memory owner @%0t",
               $time);
      if (kill_valid_i && (dispatch0_valid_i || dispatch1_valid_i))
        $error("[IQ-KILL-NO-DISPATCH] kill 拍收到 dispatch valid(上游 freeze 契约被破坏) @%0t",
               $time);
      if (dispatch0_valid_i &&
          (dispatch0_producer_id_i[ROB_INDEX_W-1:0] != dispatch0_rob_idx_i))
        $error("[V8F-IQ-DISPATCH0-PID-INDEX] pid=%h raw=%h @%0t",
               dispatch0_producer_id_i, dispatch0_rob_idx_i, $time);
      if (dispatch1_valid_i &&
          (dispatch1_producer_id_i[ROB_INDEX_W-1:0] != dispatch1_rob_idx_i))
        $error("[V8F-IQ-DISPATCH1-PID-INDEX] pid=%h raw=%h @%0t",
               dispatch1_producer_id_i, dispatch1_rob_idx_i, $time);
      if (issue0_valid_o &&
          (issue0_producer_id_o[ROB_INDEX_W-1:0] != issue0_rob_idx_o))
        $error("[V8F-IQ-ISSUE0-PID-INDEX] pid=%h raw=%h @%0t",
               issue0_producer_id_o, issue0_rob_idx_o, $time);
      if (issue1_valid_o &&
          (issue1_producer_id_o[ROB_INDEX_W-1:0] != issue1_rob_idx_o))
        $error("[V8F-IQ-ISSUE1-PID-INDEX] pid=%h raw=%h @%0t",
               issue1_producer_id_o, issue1_rob_idx_o, $time);
      for (pack_assert_i = 0; pack_assert_i < ENTRY_COUNT;
           pack_assert_i = pack_assert_i + 1) begin
        if (valid_q[pack_assert_i] &&
            (^producer_id_q[pack_assert_i] === 1'bx)) begin
          $error("[V8L-INT-IQ-LEASE-KNOWN] valid entry has unknown PID idx=%0d @%0t",
                 pack_assert_i, $time);
        end else if (valid_q[pack_assert_i] &&
                     !producer_live_mask_o[producer_id_q[pack_assert_i]]) begin
          $error("[V8L-INT-IQ-LEASE-DECODE] valid entry missing from Q-only mask idx=%0d pid=%h @%0t",
                 pack_assert_i, producer_id_q[pack_assert_i], $time);
        end
      end
      // T3M：任一被 select 的整数源都必须已经在前一上升沿落入 sticky
      // ready。full WB 当拍 pulse 不能替代这个状态；负变异把 wake CAM 重新
      // OR 进 entry_ready 时会精准命中本 marker。
      if (issue0_valid_o &&
          (!src1_ready_q[issue0_idx_w] || !src2_ready_q[issue0_idx_w]))
        $error("[IQ-INT-WAKE-STICKY-ONLY] issue0 selected before integer sticky ready @%0t",
               $time);
      if (issue1_valid_o &&
          (!src1_ready_q[issue1_idx_w] || !src2_ready_q[issue1_idx_w]))
        $error("[IQ-INT-WAKE-STICKY-ONLY] issue1 selected before integer sticky ready @%0t",
               $time);
      // T3H：跨域 FP wake0/1 都只能落 sticky ready。用更强的消费边界
      // 不变量覆盖两类 wake 和无 wake mutation：任何 FP-store source 在
      // 发射前都必须已有 fp_st_ready_q。
      if (issue0_valid_o && fp_st_en_q[issue0_idx_w] &&
          !fp_st_ready_q[issue0_idx_w])
        $error("[IQ-FP-WAKE-STICKY-ONLY] issue0 selected before FP sticky ready @%0t",
               $time);
      if (issue1_valid_o && fp_st_en_q[issue1_idx_w] &&
          !fp_st_ready_q[issue1_idx_w])
        $error("[IQ-FP-WAKE-STICKY-ONLY] issue1 selected before FP sticky ready @%0t",
               $time);
    end
  end
`endif

`ifdef ROB_WALK_DEBUG
  integer dbg_i;
  reg [15:0] iq_stall_q;
  reg [ENTRY_COUNT_W-1:0] iq_prev_count_q;
  always @(posedge clk) begin
    if (rst) begin iq_stall_q <= 16'd0; iq_prev_count_q <= {ENTRY_COUNT_W{1'b0}}; end
    else begin
      iq_prev_count_q <= count_q;
      iq_stall_q <= (count_q != {ENTRY_COUNT_W{1'b0}} && count_q == iq_prev_count_q) ? iq_stall_q + 16'd1 : 16'd0;
      if (iq_stall_q == 16'd2200) begin
        $display("[IQSTALL] count=%0d recover=%b kill_valid=%b rob_head=%0d", count_q, recover_active_i, kill_valid_i, rob_head_idx_i);
        for (dbg_i = 0; dbg_i < ENTRY_COUNT; dbg_i = dbg_i + 1)
          if (valid_q[dbg_i])
            $display("   IQ[%0d] rob=%0d pc=%h s1rdy=%b s2rdy=%b s1p=%0d s2p=%0d", dbg_i, producer_id_q[dbg_i][ROB_INDEX_W-1:0], pc_q[dbg_i],
                     src1_ready_q[dbg_i], src2_ready_q[dbg_i], src1_preg_q[dbg_i], src2_preg_q[dbg_i]);
      end
    end
  end
`endif

`ifdef ROB_WALK_DEBUG
  // [IQW] jalr de-pend wakeup 对照表：找 pc=0x1a8 的卡死 entry，逐拍打印 src1_preg/ready + 当拍全部 wakeup 总线
  reg [15:0] iqw_dbg_cnt;
  integer iqw_j;
  always @(posedge clk) begin
    if (rst) begin
      iqw_dbg_cnt <= 16'd0;
    end else begin
      for (iqw_j = 0; iqw_j < ENTRY_COUNT; iqw_j = iqw_j + 1) begin
        if (valid_q[iqw_j] && (pc_q[iqw_j] == `XLEN'h800001a8) &&
            !src1_ready_q[iqw_j] && (iqw_dbg_cnt < 16'd40)) begin
          $display("[IQW] e=%0d rob=%0d s1p=%0d s1rdy=%b | wk0=%b/%0d wk1=%b/%0d",
                   iqw_j, producer_id_q[iqw_j][ROB_INDEX_W-1:0], src1_preg_q[iqw_j], src1_ready_q[iqw_j],
                   wakeup0_valid_i, wakeup0_pdest_i, wakeup1_valid_i, wakeup1_pdest_i);
          iqw_dbg_cnt <= iqw_dbg_cnt + 16'd1;
        end
      end
    end
  end
`endif

endmodule
