`include "define.v"

// 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作：
// 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。
// 【P5 刀 B(2026-07-09)】dispatch→issue 同拍 bypass 族已整体删除：dispatch 项当拍只写入
// 阵列，次拍(N+1)起才可被 select——select 唯一真源=已寄存 valid_q 阵列项(有 IQ-NO-BYPASS
// 立即断言看护)。同拍 fast wakeup→select 直通(寄存项的唤醒 CAM)保留；
// full wakeup 只更新 ready 状态，不直接进入 select。历史数据与决策见
// design/arch/timing-dispatch-issue-path.md §6c 与 design/arch/p5-repipeline-first-batch.md。
module OooIntIssueQueue #(
  parameter ENTRY_COUNT = (1 << `OOO_ISSUE_INDEX_W),
  parameter ENTRY_INDEX_W = `OOO_ISSUE_INDEX_W,
  parameter ENTRY_COUNT_W = `OOO_ISSUE_COUNT_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W
) (
  input clk,
  input rst,
  input flush_i,
  input issue_mem_block_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`XLEN-1:0] dispatch0_pred_npc_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx_i,
  input dispatch0_pred_taken_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch0_ctrl_i,
  input [ROB_INDEX_W-1:0] dispatch0_rob_idx_i,
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
  input [ROB_INDEX_W-1:0] dispatch1_rob_idx_i,
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
  // T3B：select 只前视 EX/MEM fast broadcast；full wakeup 仍用于
  // compaction/dispatch/kill survivor 的时序 ready 更新。
  input select_wakeup0_valid_i,
  input [PHY_REG_ADDR_W-1:0] select_wakeup0_pdest_i,
  input select_wakeup1_valid_i,
  input [PHY_REG_ADDR_W-1:0] select_wakeup1_pdest_i,
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
  output [PHY_REG_ADDR_W-1:0] issue0_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_pdest_o,
  output issue0_fp_pdest_o,
  output issue0_fp_st_src_en_o,
  output [PHY_REG_ADDR_W-1:0] issue0_fp_st_src_preg_o,
  output [`XLEN-1:0] issue0_imm_o,

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
  output [PHY_REG_ADDR_W-1:0] issue1_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_pdest_o,
  output issue1_fp_pdest_o,
  output issue1_fp_st_src_en_o,
  output [PHY_REG_ADDR_W-1:0] issue1_fp_st_src_preg_o,
  output [`XLEN-1:0] issue1_imm_o,

  output [ENTRY_COUNT_W-1:0] count_o,
  output empty_o,
  output full_o,

  // B2 ROB-walk：误预测时 squash 比 kill_rob_idx 更年轻(age 更大)的 IQ entry（程序序后缀），
  // recover 期冻结发射。in-core 暂 kill 接 0、recover 接 ROB.recover_active → 行为中性。
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,
  input recover_active_i
);

  reg valid_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pc_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] next_pc_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pred_npc_q [0:ENTRY_COUNT-1];
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx_q [0:ENTRY_COUNT-1];
  reg pred_taken_q [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst_q [0:ENTRY_COUNT-1];
  reg [`CTRL_BUS_W-1:0] ctrl_q [0:ENTRY_COUNT-1];
  reg [ROB_INDEX_W-1:0] rob_idx_q [0:ENTRY_COUNT-1];
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
  reg [ENTRY_COUNT_W-1:0] count_q;

  reg valid_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pc_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] next_pc_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pred_npc_next_r [0:ENTRY_COUNT-1];
  reg [`BPU_BHT_INDEX_W-1:0] bht_idx_next_r [0:ENTRY_COUNT-1];
  reg pred_taken_next_r [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst_next_r [0:ENTRY_COUNT-1];
  reg [`CTRL_BUS_W-1:0] ctrl_next_r [0:ENTRY_COUNT-1];
  reg [ROB_INDEX_W-1:0] rob_idx_next_r [0:ENTRY_COUNT-1];
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
  reg [ENTRY_COUNT_W-1:0] count_next_r;
  reg [ENTRY_COUNT_W-1:0] kill_keep_cnt_w;   // B2 ROB-walk squash 后存活计数（组合算，避免 BLKSEQ）
  integer kc_i;

  // select 扫描的组合中间量：P5 刀 B 后只剩寄存阵列项的 oldest-first 扫描,
  // dispatch 活值相关的 issue*_dispatch*/forward/entry_ready_for_issue1 族已删除。
  reg issue0_found_r;
  reg issue1_found_r;
  reg issue0_mem_r;
  reg issue0_load_r;
  reg older_store_seen_r;
  reg older_valid_seen_r;
  reg entry_load_r;
  reg entry_store_r;
  reg entry_mem_order_block_r;
  reg [ENTRY_INDEX_W-1:0] issue0_idx_r;
  reg [ENTRY_INDEX_W-1:0] issue1_idx_r;
  reg entry_ready_r [0:ENTRY_COUNT-1];

  wire issue0_fire_w = issue0_valid_o && issue0_ready_i;
  wire issue1_fire_w = issue1_valid_o && issue1_ready_i;
  wire [ENTRY_COUNT_W-1:0] free_slots_w =
      ENTRY_COUNT[ENTRY_COUNT_W-1:0] - count_q;
  wire dispatch0_fire_w = dispatch0_valid_i && dispatch0_ready_o;
  wire dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o;

  integer scan_i;
  integer compact_i;
  integer write_i;
  integer reset_i;

  function wakeup_match;
    input [PHY_REG_ADDR_W-1:0] preg;
    input wakeup0_valid;
    input [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
    input wakeup1_valid;
    input [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
    begin
      wakeup_match = (preg != {PHY_REG_ADDR_W{1'b0}}) &&
                     ((wakeup0_valid && (wakeup0_pdest == preg)) ||
                      (wakeup1_valid && (wakeup1_pdest == preg)));
    end
  endfunction

  function ctrl_is_mem;
    input ctrl_load;
    input ctrl_store;
    begin
      ctrl_is_mem = ctrl_load || ctrl_store;
    end
  endfunction

  // 【P5 刀 B】dispatch→issue bypass 族(bypass 许可判定/dispatch 活值 entry_ready/
  // issue0 结果前递 forward 判定/clmul 甄别)已整体删除:dispatch 活值退出 select 锥,
  // select 唯一真源=已寄存阵列项。mode 下 branch/JAL/JALR 原"禁 bypass"特例随之普适化,
  // pred_npc→mispredict→redirect→前端预测后继 的组合环由结构保证不存在。
  always @(*) begin
    issue0_found_r = 1'b0;
    issue1_found_r = 1'b0;
    issue0_mem_r = 1'b0;
    issue0_load_r = 1'b0;
    older_store_seen_r = 1'b0;
    older_valid_seen_r = 1'b0;
    entry_load_r = 1'b0;
    entry_store_r = 1'b0;
    entry_mem_order_block_r = 1'b0;
    issue0_idx_r = {ENTRY_INDEX_W{1'b0}};
    issue1_idx_r = {ENTRY_INDEX_W{1'b0}};
    for (scan_i = 0; scan_i < ENTRY_COUNT; scan_i = scan_i + 1) begin
      entry_load_r = ctrl_q[scan_i][`CTRL_LOAD_BIT];
      entry_store_r = ctrl_q[scan_i][`CTRL_STORE_BIT];
      entry_mem_order_block_r =
          (entry_load_r && older_store_seen_r) ||
          (entry_store_r && older_valid_seen_r);
      entry_ready_r[scan_i] = valid_q[scan_i] &&
                              !(issue_mem_block_i &&
                                ctrl_is_mem(ctrl_q[scan_i][`CTRL_LOAD_BIT],
                                            ctrl_q[scan_i][`CTRL_STORE_BIT])) &&
                              !entry_mem_order_block_r &&
                              (src1_ready_q[scan_i] ||
                               wakeup_match(src1_preg_q[scan_i],
                                            select_wakeup0_valid_i,
                                            select_wakeup0_pdest_i,
                                            select_wakeup1_valid_i,
                                            select_wakeup1_pdest_i)) &&
                              (src2_ready_q[scan_i] ||
                               wakeup_match(src2_preg_q[scan_i],
                                            select_wakeup0_valid_i,
                                            select_wakeup0_pdest_i,
                                            select_wakeup1_valid_i,
                                            select_wakeup1_pdest_i)) &&
                              // T3D：FP execution completion(wake0)只在时序
                              // next-state粘住fp_st_ready，避免 completion→branch
                              // kill→completion 环；FP load WB(wake1)无该回边，保留快路。
                              (!fp_st_en_q[scan_i] ||
                               fp_st_ready_q[scan_i] ||
                               (fp_wake1_valid_i &&
                                (fp_wake1_preg_i == fp_st_preg_q[scan_i])));
      if (entry_ready_r[scan_i]) begin
        if (!issue0_found_r) begin
          issue0_found_r = 1'b1;
          issue0_idx_r = scan_i[ENTRY_INDEX_W-1:0];
          issue0_mem_r = ctrl_is_mem(ctrl_q[scan_i][`CTRL_LOAD_BIT],
                                     ctrl_q[scan_i][`CTRL_STORE_BIT]);
          issue0_load_r = ctrl_q[scan_i][`CTRL_LOAD_BIT];
        end else if (!issue1_found_r &&
                     !ctrl_q[scan_i][`CTRL_STORE_BIT] &&
                     !(issue0_mem_r &&
                       ctrl_is_mem(ctrl_q[scan_i][`CTRL_LOAD_BIT],
                                   ctrl_q[scan_i][`CTRL_STORE_BIT]) &&
                       !(issue0_load_r &&
                         ctrl_q[scan_i][`CTRL_LOAD_BIT]))) begin
          issue1_found_r = 1'b1;
          issue1_idx_r = scan_i[ENTRY_INDEX_W-1:0];
        end
      end
      older_store_seen_r = older_store_seen_r ||
                           (valid_q[scan_i] &&
                            ctrl_q[scan_i][`CTRL_STORE_BIT]);
      older_valid_seen_r = older_valid_seen_r || valid_q[scan_i];
    end
    // 【P5 刀 B】"dispatch 活值作 IQ 虚拟队尾同拍参与 select" 的三个臂已删除:
    // 刚 dispatch 的 uop 一律当拍写入阵列、次拍起从寄存项被 select(空队列 refill 多一拍气泡,
    // CPI 实测代价见 p5-repipeline-first-batch.md S0 数据),换取 dispatch 锥与 issue 锥解耦。
  end

  assign dispatch0_ready_o = (free_slots_w != {ENTRY_COUNT_W{1'b0}});
  assign dispatch1_ready_o = (free_slots_w > {{(ENTRY_COUNT_W-1){1'b0}}, dispatch0_fire_w});

  // 【P5 刀 B】issue payload 直读寄存阵列(dispatch 活值直通臂已删):
  // pred_npc 恒取寄存 pred_npc_q,pred_npc→mispredict→redirect→前端预测→pred_npc 的
  // 组合环 loop-free 性质由"select 唯一真源=寄存项"结构直接保证,不再依赖控制流禁 bypass 特例。
  assign issue0_valid_o = issue0_found_r && !recover_active_i && !kill_valid_i;
  assign issue0_pc_o = pc_q[issue0_idx_r];
  assign issue0_next_pc_o = next_pc_q[issue0_idx_r];
  assign issue0_pred_npc_o = pred_npc_q[issue0_idx_r];
  assign issue0_bht_idx_o = bht_idx_q[issue0_idx_r];
  assign issue0_pred_taken_o = pred_taken_q[issue0_idx_r];
  assign issue0_inst_o = inst_q[issue0_idx_r];
  assign issue0_ctrl_o = ctrl_q[issue0_idx_r];
  assign issue0_rob_idx_o = rob_idx_q[issue0_idx_r];
  assign issue0_src1_preg_o = src1_preg_q[issue0_idx_r];
  assign issue0_src2_preg_o = src2_preg_q[issue0_idx_r];
  assign issue0_pdest_o = pdest_q[issue0_idx_r];
  assign issue0_fp_pdest_o = fp_pdest_q[issue0_idx_r];
  assign issue0_fp_st_src_en_o = fp_st_en_q[issue0_idx_r];
  assign issue0_fp_st_src_preg_o = fp_st_preg_q[issue0_idx_r];
  assign issue0_imm_o = imm_q[issue0_idx_r];

  // issue1 对 issue0 的"结果前递依赖"(issue1_depends_on_issue0)只可能出现在 bypass 臂,
  // 寄存项扫描恒置 0——bypass 删除后 issue1_valid 不再消费 issue0_fire(反压环少一条回边)。
  assign issue1_valid_o =
      issue1_found_r && !recover_active_i && !kill_valid_i;
  assign issue1_pc_o = pc_q[issue1_idx_r];
  assign issue1_next_pc_o = next_pc_q[issue1_idx_r];
  assign issue1_pred_npc_o = pred_npc_q[issue1_idx_r];
  assign issue1_bht_idx_o = bht_idx_q[issue1_idx_r];
  assign issue1_pred_taken_o = pred_taken_q[issue1_idx_r];
  assign issue1_inst_o = inst_q[issue1_idx_r];
  assign issue1_ctrl_o = ctrl_q[issue1_idx_r];
  assign issue1_rob_idx_o = rob_idx_q[issue1_idx_r];
  assign issue1_src1_preg_o = src1_preg_q[issue1_idx_r];
  assign issue1_src2_preg_o = src2_preg_q[issue1_idx_r];
  assign issue1_pdest_o = pdest_q[issue1_idx_r];
  assign issue1_fp_pdest_o = fp_pdest_q[issue1_idx_r];
  assign issue1_fp_st_src_en_o = fp_st_en_q[issue1_idx_r];
  assign issue1_fp_st_src_preg_o = fp_st_preg_q[issue1_idx_r];
  assign issue1_imm_o = imm_q[issue1_idx_r];

  assign count_o = count_q;
  assign empty_o = (count_q == {ENTRY_COUNT_W{1'b0}});
  assign full_o = (count_q == ENTRY_COUNT[ENTRY_COUNT_W-1:0]);

  // 【P5 刀 B】issue fire 恒为寄存项 fire(dispatch 活值当拍被发射的情形不复存在),
  // 压缩逻辑直接消费 issue*_fire_w;dispatch fire 无条件写阵列。
  always @(*) begin
    write_i = 0;
    count_next_r = {ENTRY_COUNT_W{1'b0}};
    for (compact_i = 0; compact_i < ENTRY_COUNT; compact_i = compact_i + 1) begin
      valid_next_r[compact_i] = 1'b0;
      pc_next_r[compact_i] = {`XLEN{1'b0}};
      next_pc_next_r[compact_i] = {`XLEN{1'b0}};
      pred_npc_next_r[compact_i] = {`XLEN{1'b0}};
      bht_idx_next_r[compact_i] = {`BPU_BHT_INDEX_W{1'b0}};
      pred_taken_next_r[compact_i] = 1'b0;
      inst_next_r[compact_i] = {`INST_W{1'b0}};
      ctrl_next_r[compact_i] = {`CTRL_BUS_W{1'b0}};
      rob_idx_next_r[compact_i] = {ROB_INDEX_W{1'b0}};
      src1_preg_next_r[compact_i] = {PHY_REG_ADDR_W{1'b0}};
      fp_pdest_next_r[compact_i] = 1'b0;
      fp_st_en_next_r[compact_i] = 1'b0;
      fp_st_preg_next_r[compact_i] = {PHY_REG_ADDR_W{1'b0}};
      fp_st_ready_next_r[compact_i] = 1'b0;
      src1_ready_next_r[compact_i] = 1'b0;
      src2_preg_next_r[compact_i] = {PHY_REG_ADDR_W{1'b0}};
      src2_ready_next_r[compact_i] = 1'b0;
      pdest_next_r[compact_i] = {PHY_REG_ADDR_W{1'b0}};
      imm_next_r[compact_i] = {`XLEN{1'b0}};
    end

    for (compact_i = 0; compact_i < ENTRY_COUNT; compact_i = compact_i + 1) begin
      if (valid_q[compact_i] &&
          !(issue0_fire_w &&
            (compact_i[ENTRY_INDEX_W-1:0] == issue0_idx_r)) &&
          !(issue1_fire_w &&
            (compact_i[ENTRY_INDEX_W-1:0] == issue1_idx_r))) begin
        valid_next_r[write_i] = 1'b1;
        pc_next_r[write_i] = pc_q[compact_i];
        next_pc_next_r[write_i] = next_pc_q[compact_i];
        pred_npc_next_r[write_i] = pred_npc_q[compact_i];
        bht_idx_next_r[write_i] = bht_idx_q[compact_i];
        pred_taken_next_r[write_i] = pred_taken_q[compact_i];
        inst_next_r[write_i] = inst_q[compact_i];
        ctrl_next_r[write_i] = ctrl_q[compact_i];
        rob_idx_next_r[write_i] = rob_idx_q[compact_i];
        src1_preg_next_r[write_i] = src1_preg_q[compact_i];
        src1_ready_next_r[write_i] =
            src1_ready_q[compact_i] ||
            wakeup_match(src1_preg_q[compact_i],
                         wakeup0_valid_i, wakeup0_pdest_i,
                         wakeup1_valid_i, wakeup1_pdest_i);
        src2_preg_next_r[write_i] = src2_preg_q[compact_i];
        src2_ready_next_r[write_i] =
            src2_ready_q[compact_i] ||
            wakeup_match(src2_preg_q[compact_i],
                         wakeup0_valid_i, wakeup0_pdest_i,
                         wakeup1_valid_i, wakeup1_pdest_i);
        pdest_next_r[write_i] = pdest_q[compact_i];
        fp_pdest_next_r[write_i] = fp_pdest_q[compact_i];
        fp_st_en_next_r[write_i] = fp_st_en_q[compact_i];
        fp_st_preg_next_r[write_i] = fp_st_preg_q[compact_i];
        fp_st_ready_next_r[write_i] =
            fp_st_ready_q[compact_i] ||
            (fp_wake0_valid_i && (fp_wake0_preg_i == fp_st_preg_q[compact_i])) ||
            (fp_wake1_valid_i && (fp_wake1_preg_i == fp_st_preg_q[compact_i]));
        imm_next_r[write_i] = imm_q[compact_i];
        write_i = write_i + 1;
      end
    end

    if (dispatch0_fire_w) begin
      valid_next_r[write_i] = 1'b1;
      pc_next_r[write_i] = dispatch0_pc_i;
      next_pc_next_r[write_i] = dispatch0_next_pc_i;
      pred_npc_next_r[write_i] = dispatch0_pred_npc_i;
      bht_idx_next_r[write_i] = dispatch0_bht_idx_i;
      pred_taken_next_r[write_i] = dispatch0_pred_taken_i;
      inst_next_r[write_i] = dispatch0_inst_i;
      ctrl_next_r[write_i] = dispatch0_ctrl_i;
      rob_idx_next_r[write_i] = dispatch0_rob_idx_i;
      src1_preg_next_r[write_i] = dispatch0_src1_preg_i;
      src1_ready_next_r[write_i] =
          dispatch0_src1_ready_i ||
          wakeup_match(dispatch0_src1_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      src2_preg_next_r[write_i] = dispatch0_src2_preg_i;
      src2_ready_next_r[write_i] =
          dispatch0_src2_ready_i ||
          wakeup_match(dispatch0_src2_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      pdest_next_r[write_i] = dispatch0_pdest_i;
      fp_pdest_next_r[write_i] = dispatch0_fp_pdest_i;
      fp_st_en_next_r[write_i] = dispatch0_fp_st_src_en_i;
      fp_st_preg_next_r[write_i] = dispatch0_fp_st_src_preg_i;
      fp_st_ready_next_r[write_i] = dispatch0_fp_st_src_ready_i;
      imm_next_r[write_i] = dispatch0_imm_i;
      write_i = write_i + 1;
    end

    if (dispatch1_fire_w) begin
      valid_next_r[write_i] = 1'b1;
      pc_next_r[write_i] = dispatch1_pc_i;
      next_pc_next_r[write_i] = dispatch1_next_pc_i;
      pred_npc_next_r[write_i] = dispatch1_pred_npc_i;
      bht_idx_next_r[write_i] = dispatch1_bht_idx_i;
      pred_taken_next_r[write_i] = dispatch1_pred_taken_i;
      inst_next_r[write_i] = dispatch1_inst_i;
      ctrl_next_r[write_i] = dispatch1_ctrl_i;
      rob_idx_next_r[write_i] = dispatch1_rob_idx_i;
      src1_preg_next_r[write_i] = dispatch1_src1_preg_i;
      src1_ready_next_r[write_i] =
          dispatch1_src1_ready_i ||
          wakeup_match(dispatch1_src1_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      src2_preg_next_r[write_i] = dispatch1_src2_preg_i;
      src2_ready_next_r[write_i] =
          dispatch1_src2_ready_i ||
          wakeup_match(dispatch1_src2_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      pdest_next_r[write_i] = dispatch1_pdest_i;
      fp_pdest_next_r[write_i] = dispatch1_fp_pdest_i;
      fp_st_en_next_r[write_i] = dispatch1_fp_st_src_en_i;
      fp_st_preg_next_r[write_i] = dispatch1_fp_st_src_preg_i;
      fp_st_ready_next_r[write_i] = dispatch1_fp_st_src_ready_i;
      imm_next_r[write_i] = dispatch1_imm_i;
      write_i = write_i + 1;
    end

    count_next_r = write_i[ENTRY_COUNT_W-1:0];
  end

  // B2 ROB-walk squash 后存活计数（组合）：valid 且 age 不大于 kill 的 entry 数。
  always @(*) begin
    kill_keep_cnt_w = {ENTRY_COUNT_W{1'b0}};
    for (kc_i = 0; kc_i < ENTRY_COUNT; kc_i = kc_i + 1) begin
      if (valid_q[kc_i] &&
          !((rob_idx_q[kc_i] - rob_head_idx_i) > (kill_rob_idx_i - rob_head_idx_i))) begin
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
        rob_idx_q[reset_i] <= {ROB_INDEX_W{1'b0}};
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
      end
    end else if (kill_valid_i) begin
      // ROB-walk squash：清掉比 kill_rob_idx 更年轻(age 更大)的 entry（程序序后缀），存活=前缀，已紧凑。
      // 存活前缀必须继续吸收当拍 wakeup，否则 kill 与 writeback 同拍时唤醒永久丢失
      // （mode 下 wrong-path 每拍发 kill，load writeback 撞上 kill 拍 → jalr 等 load 结果死锁）。
      for (reset_i = 0; reset_i < ENTRY_COUNT; reset_i = reset_i + 1) begin
        if (valid_q[reset_i] &&
            ((rob_idx_q[reset_i] - rob_head_idx_i) >
             (kill_rob_idx_i - rob_head_idx_i))) begin
          valid_q[reset_i] <= 1'b0;
        end else if (valid_q[reset_i]) begin
          src1_ready_q[reset_i] <= src1_ready_q[reset_i] ||
              wakeup_match(src1_preg_q[reset_i],
                           wakeup0_valid_i, wakeup0_pdest_i,
                           wakeup1_valid_i, wakeup1_pdest_i);
          src2_ready_q[reset_i] <= src2_ready_q[reset_i] ||
              wakeup_match(src2_preg_q[reset_i],
                           wakeup0_valid_i, wakeup0_pdest_i,
                           wakeup1_valid_i, wakeup1_pdest_i);
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
        rob_idx_q[reset_i] <= rob_idx_next_r[reset_i];
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
      end
    end
  end

`ifdef OOO_ASSERT
  // ===== P5 刀 B 契约立即断言(不可弱化) =====
  // IQ-NO-BYPASS:select 唯一真源=已寄存 valid_q 阵列项。删除 dispatch→issue bypass 后,
  // 任何被选中发射的 lane 必须指向 valid_q=1 的寄存项;若重新引入"dispatch 活值当拍参与
  // select"的臂,选中槽位将不是寄存项,此断言当拍命中(负测试证据见
  // .github/task-runs/2026-07-09-p5-first-batch/)。
  // IQ-KILL-NO-DISPATCH:kill 拍不得有 dispatch valid——上游 OooDispatchBackend 用与
  // kill_valid_i 同源的寄存 kill_valid_q 生成 dispatch_freeze(OooDispatchBackend.v:313)。
  // 该互斥是"当拍 dispatch 写入+同拍 kill"窗口结构性不存在的承重契约:本模块 kill 分支
  // 不消费 valid_next_r 写入计划,若互斥被破坏,kill 拍的新写项会被静默丢弃而非入队。
  always @(posedge clk) begin
    if (!rst) begin
      if (issue0_valid_o && !valid_q[issue0_idx_r])
        $error("[IQ-NO-BYPASS] issue0 select 源非寄存 valid_q 项: idx=%0d @%0t",
               issue0_idx_r, $time);
      if (issue1_valid_o && !valid_q[issue1_idx_r])
        $error("[IQ-NO-BYPASS] issue1 select 源非寄存 valid_q 项: idx=%0d @%0t",
               issue1_idx_r, $time);
      if (kill_valid_i && (dispatch0_valid_i || dispatch1_valid_i))
        $error("[IQ-KILL-NO-DISPATCH] kill 拍收到 dispatch valid(上游 freeze 契约被破坏) @%0t",
               $time);
      // Fast select 必须是同 lane full WB 广播的子集；否则反压拍只看到
      // 瞬时 select wakeup，却无法在上升沿把 ready 持久化。
      if ((select_wakeup0_valid_i === 1'b1) &&
          !((wakeup0_valid_i === 1'b1) &&
            (select_wakeup0_pdest_i === wakeup0_pdest_i)))
        $error("[IQ-FAST-WAKE-SUBSET] lane0 select=%0d full_valid=%b full=%0d @%0t",
               select_wakeup0_pdest_i, wakeup0_valid_i, wakeup0_pdest_i, $time);
      if ((select_wakeup1_valid_i === 1'b1) &&
          !((wakeup1_valid_i === 1'b1) &&
            (select_wakeup1_pdest_i === wakeup1_pdest_i)))
        $error("[IQ-FAST-WAKE-SUBSET] lane1 select=%0d full_valid=%b full=%0d @%0t",
               select_wakeup1_pdest_i, wakeup1_valid_i, wakeup1_pdest_i, $time);
      // 跨域 FP wake 只能落 sticky ready；若未 sticky 的 FP-store 项在命中
      // wake 的同拍被选中，说明 same-cycle select 回边被重新引入。
      if (issue0_valid_o && fp_st_en_q[issue0_idx_r] &&
          !fp_st_ready_q[issue0_idx_r] &&
          (fp_wake0_valid_i &&
           (fp_wake0_preg_i == fp_st_preg_q[issue0_idx_r])))
        $error("[IQ-FP-WAKE-STICKY-ONLY] issue0 selected on same-cycle FP wake @%0t",
               $time);
      if (issue1_valid_o && fp_st_en_q[issue1_idx_r] &&
          !fp_st_ready_q[issue1_idx_r] &&
          (fp_wake0_valid_i &&
           (fp_wake0_preg_i == fp_st_preg_q[issue1_idx_r])))
        $error("[IQ-FP-WAKE-STICKY-ONLY] issue1 selected on same-cycle FP wake @%0t",
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
            $display("   IQ[%0d] rob=%0d pc=%h s1rdy=%b s2rdy=%b s1p=%0d s2p=%0d", dbg_i, rob_idx_q[dbg_i], pc_q[dbg_i],
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
                   iqw_j, rob_idx_q[iqw_j], src1_preg_q[iqw_j], src1_ready_q[iqw_j],
                   wakeup0_valid_i, wakeup0_pdest_i, wakeup1_valid_i, wakeup1_pdest_i);
          iqw_dbg_cnt <= iqw_dbg_cnt + 16'd1;
        end
      end
    end
  end
`endif

endmodule
