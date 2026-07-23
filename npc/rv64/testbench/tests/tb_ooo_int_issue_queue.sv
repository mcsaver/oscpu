`include "define.v"

// tb_ooo_int_issue_queue —— P5 刀 B(2026-07-09)后的 IQ 契约:
// 1. 【N+1 发射口径】dispatch 项当拍只写入阵列,当拍 issue*_valid 不得由 dispatch 活值拉高
//    (dispatch→issue 同拍 bypass 已整体删除);次拍起才可被 select 发射。
// 2. 【T3M sticky 边界】所有 integer full wakeup（含 EX）只被
//    compaction/dispatch/kill survivor 吸收到 ready，下拍发射(IQ-I2 无漏唤醒)。
// 3. select 唯一真源=已寄存 valid_q 项,由 RTL 内 IQ-NO-BYPASS 立即断言看护
//    (本 TB 带 -DOOO_ASSERT 编译,断言命中会打印 [IQ-NO-BYPASS])。
// 4. kill/recover/flush 语义不变:kill 拍压 issue、squash 更年轻后缀、幸存前缀同拍吸收 wakeup。
// 5. 【T3N lane0 owner】第二候选跳过 branch/JAL/JALR，可继续选择更年轻的
//    非控制流 ready 项；被跳过的控制流留队，下一拍晋升 lane0。
// 断言与检查不可弱化;负测试(临时保留一条 bypass 臂使断言 fire)证据存
// .github/task-runs/2026-07-09-p5-first-batch/。
module tb_ooo_int_issue_queue;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam ENTRY_COUNT_W = 4;
  localparam PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W;
  localparam PRODUCER_COUNT = (1 << PRODUCER_ID_W);

  reg clk;
  reg rst;
  reg flush;
  reg issue_mem_block;
  reg universal_owner_present;
  reg memory_pair_peek_enable;
  wire memory_pair_peek_valid;
  reg memory_pair_peek_ready;
  reg dispatch0_valid;
  wire dispatch0_ready;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`INST_W-1:0] dispatch0_inst;
  reg [`CTRL_BUS_W-1:0] dispatch0_ctrl;
  reg dispatch0_is_fp;
  reg [ROB_INDEX_W-1:0] dispatch0_rob_idx;
  reg [PRODUCER_ID_W-1:0] dispatch0_producer_id;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg;
  reg dispatch0_src1_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg;
  reg dispatch0_src2_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_pdest;
  reg dispatch0_fp_st_src_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_fp_st_src_preg;
  reg dispatch0_fp_st_src_ready;
  reg [`XLEN-1:0] dispatch0_imm;
  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  reg [`CTRL_BUS_W-1:0] dispatch1_ctrl;
  reg dispatch1_is_fp;
  reg dispatch1_optional;
  reg [ROB_INDEX_W-1:0] dispatch1_rob_idx;
  reg [PRODUCER_ID_W-1:0] dispatch1_producer_id;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg;
  reg dispatch1_src1_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg;
  reg dispatch1_src2_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_pdest;
  reg dispatch1_fp_st_src_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_fp_st_src_preg;
  reg dispatch1_fp_st_src_ready;
  reg [`XLEN-1:0] dispatch1_imm;
  reg wakeup0_valid;
  reg [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
  reg wakeup1_valid;
  reg [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
  reg early_wakeup0_valid;
  reg [PHY_REG_ADDR_W-1:0] early_wakeup0_pdest;
  reg early_wakeup1_valid;
  reg [PHY_REG_ADDR_W-1:0] early_wakeup1_pdest;
  reg fp_wake0_valid;
  reg [PHY_REG_ADDR_W-1:0] fp_wake0_preg;
  reg fp_wake1_valid;
  reg [PHY_REG_ADDR_W-1:0] fp_wake1_preg;
  wire issue0_valid;
  reg issue0_ready;
  wire issue_pair_swapped;
  wire [`XLEN-1:0] issue0_pc;
  wire [`XLEN-1:0] issue0_next_pc;
  wire [`INST_W-1:0] issue0_inst;
  wire [`CTRL_BUS_W-1:0] issue0_ctrl;
  wire [ROB_INDEX_W-1:0] issue0_rob_idx;
  wire [PRODUCER_ID_W-1:0] issue0_producer_id;
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg;
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg;
  wire [PHY_REG_ADDR_W-1:0] issue0_pdest;
  wire issue0_fixed_gpr_producer;
  wire issue0_fp_st_src_en;
  wire [PHY_REG_ADDR_W-1:0] issue0_fp_st_src_preg;
  wire [`XLEN-1:0] issue0_imm;
  wire issue1_valid;
  reg issue1_ready;
  wire [`XLEN-1:0] issue1_pc;
  wire [`XLEN-1:0] issue1_next_pc;
  wire [`INST_W-1:0] issue1_inst;
  wire [`CTRL_BUS_W-1:0] issue1_ctrl;
  wire [ROB_INDEX_W-1:0] issue1_rob_idx;
  wire [PRODUCER_ID_W-1:0] issue1_producer_id;
  wire [PHY_REG_ADDR_W-1:0] issue1_src1_preg;
  wire [PHY_REG_ADDR_W-1:0] issue1_src2_preg;
  wire [PHY_REG_ADDR_W-1:0] issue1_pdest;
  wire issue1_fixed_gpr_producer;
  wire issue1_fp_st_src_en;
  wire [PHY_REG_ADDR_W-1:0] issue1_fp_st_src_preg;
  wire [`XLEN-1:0] issue1_imm;
  wire [ENTRY_COUNT_W-1:0] count;
  wire empty;
  wire full;
  wire [PRODUCER_COUNT-1:0] producer_live_mask;
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  reg [ROB_INDEX_W-1:0] rob_head_idx;
  reg recover_active;
  integer lane1_negative_i;
  integer v8o_same_cycle_pair_fires;
  integer v8o_exact_full_pid_matches;
  integer v8o_static_lane_role_violations;
  integer v8o_accepted_transactions;
  integer v8o_fired_transactions;
  reg [1:0] v8o_slot_coverage [0:5];
  reg [PRODUCER_COUNT-1:0] v8o_accepted_mask;
  reg [PRODUCER_COUNT-1:0] v8o_fired_mask;

  OooIntIssueQueue #(
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .issue_mem_block_i(issue_mem_block),
    .universal_owner_present_i(universal_owner_present),
    .memory_pair_peek_enable_i(memory_pair_peek_enable),
    .memory_pair_peek_valid_o(memory_pair_peek_valid),
    .memory_pair_peek_ready_i(memory_pair_peek_ready),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i('0),
    .dispatch0_bht_idx_i('0),
    .dispatch0_pred_taken_i(1'b0),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_ctrl_i(dispatch0_ctrl),
    .dispatch0_is_fp_i(dispatch0_is_fp),
    .dispatch0_rob_idx_i(dispatch0_rob_idx),
    .dispatch0_producer_id_i(dispatch0_producer_id),
    .dispatch0_src1_preg_i(dispatch0_src1_preg),
    .dispatch0_src1_ready_i(dispatch0_src1_ready),
    .dispatch0_src2_preg_i(dispatch0_src2_preg),
    .dispatch0_src2_ready_i(dispatch0_src2_ready),
    .dispatch0_pdest_i(dispatch0_pdest),
    .dispatch0_fp_pdest_i(1'b0),
    .dispatch0_fp_st_src_en_i(dispatch0_fp_st_src_en),
    .dispatch0_fp_st_src_preg_i(dispatch0_fp_st_src_preg),
    .dispatch0_fp_st_src_ready_i(dispatch0_fp_st_src_ready),
    .dispatch0_imm_i(dispatch0_imm),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_optional_i(dispatch1_optional),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_pred_npc_i('0),
    .dispatch1_bht_idx_i('0),
    .dispatch1_pred_taken_i(1'b0),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_ctrl_i(dispatch1_ctrl),
    .dispatch1_is_fp_i(dispatch1_is_fp),
    .dispatch1_rob_idx_i(dispatch1_rob_idx),
    .dispatch1_producer_id_i(dispatch1_producer_id),
    .dispatch1_src1_preg_i(dispatch1_src1_preg),
    .dispatch1_src1_ready_i(dispatch1_src1_ready),
    .dispatch1_src2_preg_i(dispatch1_src2_preg),
    .dispatch1_src2_ready_i(dispatch1_src2_ready),
    .dispatch1_pdest_i(dispatch1_pdest),
    .dispatch1_fp_pdest_i(1'b0),
    .dispatch1_fp_st_src_en_i(dispatch1_fp_st_src_en),
    .dispatch1_fp_st_src_preg_i(dispatch1_fp_st_src_preg),
    .dispatch1_fp_st_src_ready_i(dispatch1_fp_st_src_ready),
    .dispatch1_imm_i(dispatch1_imm),
    .wakeup0_valid_i(wakeup0_valid),
    .wakeup0_pdest_i(wakeup0_pdest),
    .wakeup1_valid_i(wakeup1_valid),
    .wakeup1_pdest_i(wakeup1_pdest),
    .early_wakeup0_valid_i(early_wakeup0_valid),
    .early_wakeup0_pdest_i(early_wakeup0_pdest),
    .early_wakeup1_valid_i(early_wakeup1_valid),
    .early_wakeup1_pdest_i(early_wakeup1_pdest),
    .fp_wake0_valid_i(fp_wake0_valid),
    .fp_wake0_preg_i(fp_wake0_preg),
    .fp_wake1_valid_i(fp_wake1_valid),
    .fp_wake1_preg_i(fp_wake1_preg),
    .issue0_valid_o(issue0_valid),
    .issue0_ready_i(issue0_ready),
    .issue0_pc_o(issue0_pc),
    .issue0_next_pc_o(issue0_next_pc),
    .issue0_inst_o(issue0_inst),
    .issue0_ctrl_o(issue0_ctrl),
    .issue0_rob_idx_o(issue0_rob_idx),
    .issue0_producer_id_o(issue0_producer_id),
    .issue0_src1_preg_o(issue0_src1_preg),
    .issue0_src2_preg_o(issue0_src2_preg),
    .issue0_pdest_o(issue0_pdest),
    .issue0_fixed_gpr_producer_o(issue0_fixed_gpr_producer),
    .issue0_fp_st_src_en_o(issue0_fp_st_src_en),
    .issue0_fp_st_src_preg_o(issue0_fp_st_src_preg),
    .issue0_imm_o(issue0_imm),
    .issue_pair_swapped_o(issue_pair_swapped),
    .issue1_valid_o(issue1_valid),
    .issue1_ready_i(issue1_ready),
    .issue1_pc_o(issue1_pc),
    .issue1_next_pc_o(issue1_next_pc),
    .issue1_inst_o(issue1_inst),
    .issue1_ctrl_o(issue1_ctrl),
    .issue1_rob_idx_o(issue1_rob_idx),
    .issue1_producer_id_o(issue1_producer_id),
    .issue1_src1_preg_o(issue1_src1_preg),
    .issue1_src2_preg_o(issue1_src2_preg),
    .issue1_pdest_o(issue1_pdest),
    .issue1_fixed_gpr_producer_o(issue1_fixed_gpr_producer),
    .issue1_fp_st_src_en_o(issue1_fp_st_src_en),
    .issue1_fp_st_src_preg_o(issue1_fp_st_src_preg),
    .issue1_imm_o(issue1_imm),
    .count_o(count),
    .empty_o(empty),
    .full_o(full),
    .producer_live_mask_o(producer_live_mask),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .rob_head_idx_i(rob_head_idx),
    .recover_active_i(recover_active)
  );

  wire unused_next_pc_w = (|issue0_next_pc) | (|issue1_next_pc);

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      issue_mem_block = 1'b0;
      universal_owner_present = 1'b0;
      memory_pair_peek_enable = 1'b0;
      memory_pair_peek_ready = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
      dispatch0_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch0_is_fp = 1'b0;
      dispatch0_rob_idx = 4'd0;
      dispatch0_producer_id = {PRODUCER_ID_W{1'b0}};
      dispatch0_src1_preg = 6'd0;
      dispatch0_src1_ready = 1'b0;
      dispatch0_src2_preg = 6'd0;
      dispatch0_src2_ready = 1'b0;
      dispatch0_pdest = 6'd0;
      dispatch0_fp_st_src_en = 1'b0;
      dispatch0_fp_st_src_preg = 6'd0;
      dispatch0_fp_st_src_ready = 1'b1;
      dispatch0_imm = 32'h0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_inst = 32'h0;
      dispatch1_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch1_is_fp = 1'b0;
      dispatch1_optional = 1'b0;
      dispatch1_rob_idx = 4'd0;
      dispatch1_producer_id = {PRODUCER_ID_W{1'b0}};
      dispatch1_src1_preg = 6'd0;
      dispatch1_src1_ready = 1'b0;
      dispatch1_src2_preg = 6'd0;
      dispatch1_src2_ready = 1'b0;
      dispatch1_pdest = 6'd0;
      dispatch1_fp_st_src_en = 1'b0;
      dispatch1_fp_st_src_preg = 6'd0;
      dispatch1_fp_st_src_ready = 1'b1;
      dispatch1_imm = 32'h0;
      wakeup0_valid = 1'b0;
      wakeup0_pdest = 6'd0;
      wakeup1_valid = 1'b0;
      wakeup1_pdest = 6'd0;
      early_wakeup0_valid = 1'b0;
      early_wakeup0_pdest = 6'd0;
      early_wakeup1_valid = 1'b0;
      early_wakeup1_pdest = 6'd0;
      fp_wake0_valid = 1'b0;
      fp_wake0_preg = 6'd0;
      fp_wake1_valid = 1'b0;
      fp_wake1_preg = 6'd0;
      kill_valid = 1'b0;
      kill_rob_idx = 4'd0;
      rob_head_idx = 4'd0;
      recover_active = 1'b0;
    end
  endtask

  // v8u/F4: an occupied Universal terminal may observe the two edge-old IQ
  // heads through the dedicated pair face.  READY must only control the
  // atomic pop2; it must not change the Q-only payload or expose a regular
  // issue transaction.
  task automatic run_v8u_memory_pair_peek;
    reg [PRODUCER_ID_W-1:0] pid0;
    reg [PRODUCER_ID_W-1:0] pid1;
    begin
      reset_dut();
      issue0_ready = 1'b1;
      issue1_ready = 1'b1;
      set_dispatch0(32'h8500_0000, 4'd2,
                    6'd10, 1'b1, 6'd11, 1'b1, 6'd42);
      set_dispatch1(32'h8500_0004, 4'd3,
                    6'd12, 1'b1, 6'd13, 1'b1, 6'd43);
      dispatch0_ctrl = r3_complex_ctrl(3);
      dispatch1_ctrl = r3_complex_ctrl(3);
      dispatch0_producer_id[PRODUCER_ID_W-1:ROB_INDEX_W] = 2'd1;
      dispatch1_producer_id[PRODUCER_ID_W-1:ROB_INDEX_W] = 2'd2;
      pid0 = dispatch0_producer_id;
      pid1 = dispatch1_producer_id;
      `TB_TICK(clk);
      clear_inputs();
      universal_owner_present = 1'b1;
      memory_pair_peek_enable = 1'b1;
      #1;
      tb_check32("V8U pair peek starts with two residents",
                 {28'b0, count}, 32'd2);
      tb_check1("V8U pair peek valid from Q-only entries",
                memory_pair_peek_valid, 1'b1);
      tb_check1("V8U pair peek suppresses regular issue0",
                issue0_valid, 1'b0);
      tb_check1("V8U pair peek suppresses regular issue1",
                issue1_valid, 1'b0);
      tb_check32("V8U pair peek entry0 PC", issue0_pc, 32'h8500_0000);
      tb_check32("V8U pair peek entry1 PC", issue1_pc, 32'h8500_0004);
      tb_check1("V8U pair peek entry0 full ProducerId",
                issue0_producer_id == pid0, 1'b1);
      tb_check1("V8U pair peek entry1 full ProducerId",
                issue1_producer_id == pid1, 1'b1);

      // Hold one full edge with READY low: both entries and payload identities
      // remain resident even though the owner/enable face is active.
      `TB_TICK(clk);
      #1;
      tb_check32("V8U pair peek READY-low holds count",
                 {28'b0, count}, 32'd2);
      tb_check1("V8U pair peek READY-low holds entry0 identity",
                issue0_producer_id == pid0, 1'b1);
      tb_check1("V8U pair peek READY-low holds entry1 identity",
                issue1_producer_id == pid1, 1'b1);

      memory_pair_peek_ready = 1'b1;
      #1;
      tb_check1("V8U pair peek fire remains non-regular",
                !issue0_valid && !issue1_valid, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("V8U pair peek atomically drains both entries", empty, 1'b1);
      tb_check32("V8U pair peek atomic pop2 count",
                 {28'b0, count}, 32'd0);
      $display("[V8U-IQ-PAIR-PEEK] q_only_payload/ready_hold/atomic_pop2/full_pid PASS");
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      issue0_ready = 1'b1;
      issue1_ready = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic set_dispatch0;
    input [`XLEN-1:0] pc;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] src1;
    input src1_ready;
    input [PHY_REG_ADDR_W-1:0] src2;
    input src2_ready;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = pc;
      dispatch0_inst = pc;
      dispatch0_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch0_ctrl[`CTRL_VALID_BIT] = 1'b1;
      dispatch0_ctrl[`CTRL_RD_EN_BIT] = 1'b1;
      dispatch0_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      dispatch0_ctrl[`CTRL_NEED_WB_BIT] = 1'b1;
      dispatch0_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;
      dispatch0_rob_idx = rob_idx;
      dispatch0_producer_id = {{PRODUCER_GEN_W{1'b0}}, rob_idx};
      dispatch0_src1_preg = src1;
      dispatch0_src1_ready = src1_ready;
      dispatch0_src2_preg = src2;
      dispatch0_src2_ready = src2_ready;
      dispatch0_pdest = pdest;
      dispatch0_imm = pc + 32'h10;
    end
  endtask

  task automatic set_dispatch1;
    input [`XLEN-1:0] pc;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] src1;
    input src1_ready;
    input [PHY_REG_ADDR_W-1:0] src2;
    input src2_ready;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      dispatch1_valid = 1'b1;
      dispatch1_pc = pc;
      dispatch1_inst = pc;
      dispatch1_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch1_ctrl[`CTRL_VALID_BIT] = 1'b1;
      dispatch1_ctrl[`CTRL_RD_EN_BIT] = 1'b1;
      dispatch1_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      dispatch1_ctrl[`CTRL_NEED_WB_BIT] = 1'b1;
      dispatch1_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;
      dispatch1_rob_idx = rob_idx;
      dispatch1_producer_id = {{PRODUCER_GEN_W{1'b0}}, rob_idx};
      dispatch1_src1_preg = src1;
      dispatch1_src1_ready = src1_ready;
      dispatch1_src2_preg = src2;
      dispatch1_src2_ready = src2_ready;
      dispatch1_pdest = pdest;
      dispatch1_imm = pc + 32'h20;
    end
  endtask

  // R3 capability steering matrix.  issue0 is the universal terminal and
  // issue1 is the fixed-latency ALU terminal; neither name is a program-order
  // lane.  When an older ALU precedes a younger complex uop, the IQ must swap
  // their terminal assignment so that both resident, independent uops fire in
  // the same cycle.  The reverse program order must work as well.
  function automatic [`CTRL_BUS_W-1:0] r3_complex_ctrl;
    input integer class_id;
    reg [`CTRL_BUS_W-1:0] ctrl;
    begin
      ctrl = {`CTRL_BUS_W{1'b0}};
      ctrl[`CTRL_VALID_BIT] = 1'b1;
      ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      case (class_id)
        0: begin // branch
          ctrl[`CTRL_BRANCH_BIT] = 1'b1;
          ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;
        end
        1: begin // JAL
          ctrl[`CTRL_JAL_BIT] = 1'b1;
          ctrl[`CTRL_RD_EN_BIT] = 1'b1;
          ctrl[`CTRL_NEED_WB_BIT] = 1'b1;
          ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_PC4;
        end
        2: begin // JALR
          ctrl[`CTRL_JALR_BIT] = 1'b1;
          ctrl[`CTRL_RD_EN_BIT] = 1'b1;
          ctrl[`CTRL_NEED_WB_BIT] = 1'b1;
          ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_PC4;
        end
        3: begin // load
          ctrl[`CTRL_LOAD_BIT] = 1'b1;
          ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
          ctrl[`CTRL_RD_EN_BIT] = 1'b1;
          ctrl[`CTRL_NEED_WB_BIT] = 1'b1;
          ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
        end
        4: begin // store
          ctrl[`CTRL_STORE_BIT] = 1'b1;
          ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
          ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;
        end
        default: begin // MulDiv
          ctrl[`CTRL_MULDIV_BIT] = 1'b1;
          ctrl[`CTRL_RD_EN_BIT] = 1'b1;
          ctrl[`CTRL_NEED_WB_BIT] = 1'b1;
          ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_ALU;
        end
      endcase
      r3_complex_ctrl = ctrl;
    end
  endfunction

  function automatic integer v8o_decode_complex_class;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
      if (ctrl[`CTRL_BRANCH_BIT])
        v8o_decode_complex_class = 0;
      else if (ctrl[`CTRL_JAL_BIT])
        v8o_decode_complex_class = 1;
      else if (ctrl[`CTRL_JALR_BIT])
        v8o_decode_complex_class = 2;
      else if (ctrl[`CTRL_LOAD_BIT])
        v8o_decode_complex_class = 3;
      else if (ctrl[`CTRL_STORE_BIT])
        v8o_decode_complex_class = 4;
      else if (ctrl[`CTRL_MULDIV_BIT])
        v8o_decode_complex_class = 5;
      else
        v8o_decode_complex_class = -1;
    end
  endfunction

  task automatic run_r3_capability_pair;
    input integer class_id;
    input complex_older;
    reg [`XLEN-1:0] older_pc;
    reg [`XLEN-1:0] younger_pc;
    reg [`XLEN-1:0] expect_universal_pc;
    reg [`XLEN-1:0] expect_alu_pc;
    reg [PRODUCER_ID_W-1:0] dispatch0_pid_frozen;
    reg [PRODUCER_ID_W-1:0] dispatch1_pid_frozen;
    reg [PRODUCER_ID_W-1:0] expect_universal_pid;
    reg [PRODUCER_ID_W-1:0] expect_alu_pid;
    reg [`CTRL_BUS_W-1:0] dispatch0_ctrl_frozen;
    reg [`CTRL_BUS_W-1:0] dispatch1_ctrl_frozen;
    reg [`CTRL_BUS_W-1:0] expect_complex_ctrl;
    reg [`CTRL_BUS_W-1:0] expect_simple_ctrl;
    reg same_edge_accept;
    reg resident_witness;
    reg canonical_dual_fire;
    reg universal_pid_match;
    reg alu_pid_match;
    reg role_match;
    reg drain_match;
    integer observed_class;
    integer class_bit_count;
    integer case_index;
    time fire_time;
    begin
      reset_dut();
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      older_pc = 32'h8200_0000 + (class_id * 32'h40) +
                 (complex_older ? 32'h20 : 32'h00);
      younger_pc = older_pc + 32'd4;
      set_dispatch0(older_pc, 4'd1, 6'd1, 1'b1,
                    6'd2, 1'b1, 6'd40);
      set_dispatch1(younger_pc, 4'd2, 6'd3, 1'b1,
                    6'd4, 1'b1, 6'd41);
      case_index = class_id * 2 + (complex_older ? 0 : 1);
      dispatch0_producer_id[PRODUCER_ID_W-1:ROB_INDEX_W] = case_index + 1;
      dispatch1_producer_id[PRODUCER_ID_W-1:ROB_INDEX_W] = case_index + 1;
      if (complex_older) begin
        dispatch0_ctrl = r3_complex_ctrl(class_id);
        expect_universal_pc = older_pc;
        expect_alu_pc = younger_pc;
      end else begin
        dispatch1_ctrl = r3_complex_ctrl(class_id);
        expect_universal_pc = younger_pc;
        expect_alu_pc = older_pc;
      end
      dispatch0_pid_frozen = dispatch0_producer_id;
      dispatch1_pid_frozen = dispatch1_producer_id;
      dispatch0_ctrl_frozen = dispatch0_ctrl;
      dispatch1_ctrl_frozen = dispatch1_ctrl;
      expect_universal_pid = complex_older ?
          dispatch0_pid_frozen : dispatch1_pid_frozen;
      expect_alu_pid = complex_older ?
          dispatch1_pid_frozen : dispatch0_pid_frozen;
      expect_complex_ctrl = complex_older ?
          dispatch0_ctrl_frozen : dispatch1_ctrl_frozen;
      expect_simple_ctrl = complex_older ?
          dispatch1_ctrl_frozen : dispatch0_ctrl_frozen;
      same_edge_accept = dispatch0_valid && dispatch0_ready &&
                         dispatch1_valid && dispatch1_ready;
      tb_check1("V8O same-edge dispatch package accept",
                same_edge_accept, 1'b1);
      tb_check1("V8O dispatch0 generation nonzero",
                |dispatch0_pid_frozen[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
      tb_check1("V8O dispatch1 generation nonzero",
                |dispatch1_pid_frozen[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
      tb_check1("V8O package identities differ",
                dispatch0_pid_frozen != dispatch1_pid_frozen, 1'b1);
`ifdef V8O_NO_STATIC_LANE_SEMANTICS_FOCUSED
      tb_check1("V8O dispatch0 identity not previously accepted",
                v8o_accepted_mask[dispatch0_pid_frozen], 1'b0);
      tb_check1("V8O dispatch1 identity not previously accepted",
                v8o_accepted_mask[dispatch1_pid_frozen], 1'b0);
      if (same_edge_accept) begin
        v8o_accepted_mask[dispatch0_pid_frozen] = 1'b1;
        v8o_accepted_mask[dispatch1_pid_frozen] = 1'b1;
        v8o_accepted_transactions = v8o_accepted_transactions + 2;
      end
`endif
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("R3 pair keeps two resident uops", {28'b0, count}, 32'd2);
      resident_witness = (count == 4'd2) && dut.valid_q[0] && dut.valid_q[1] &&
          (dut.producer_id_q[0] == dispatch0_pid_frozen) &&
          (dut.producer_id_q[1] == dispatch1_pid_frozen) &&
          (dut.ctrl_q[0] == dispatch0_ctrl_frozen) &&
          (dut.ctrl_q[1] == dispatch1_ctrl_frozen);
      tb_check1("V8O two exact entries resident", resident_witness, 1'b1);
      tb_check1("V8O complex resident capability",
                complex_older ? dut.alu_terminal_capable_q[0] :
                                dut.alu_terminal_capable_q[1], 1'b0);
      tb_check1("V8O simple resident capability",
                complex_older ? dut.alu_terminal_capable_q[1] :
                                dut.alu_terminal_capable_q[0], 1'b1);
      tb_check1("V8O slot1 resident capability",
                dut.alu_terminal_capable_q[1], complex_older ? 1'b1 : 1'b0);
      tb_check1("V8O per-entry selector projection",
                dut.select_alu_capable_w[0] ==
                    dut.alu_terminal_capable_q[0] &&
                dut.select_alu_capable_w[1] ==
                    dut.alu_terminal_capable_q[1], 1'b1);
      class_bit_count = expect_complex_ctrl[`CTRL_BRANCH_BIT] +
                        expect_complex_ctrl[`CTRL_JAL_BIT] +
                        expect_complex_ctrl[`CTRL_JALR_BIT] +
                        expect_complex_ctrl[`CTRL_LOAD_BIT] +
                        expect_complex_ctrl[`CTRL_STORE_BIT] +
                        expect_complex_ctrl[`CTRL_MULDIV_BIT];
      observed_class = v8o_decode_complex_class(expect_complex_ctrl);
      tb_check32("V8O accepted control has one complex class",
                 class_bit_count, 32'd1);
      tb_check32("V8O accepted control class matches stimulus",
                 observed_class, class_id);
      // Hold both entries for one complete cycle.  This prevents a
      // dispatch-to-select bypass or adjacent-cycle serialization from
      // satisfying the focused witness.
      `TB_TICK(clk);
      #1;
      tb_check1("V8O full-cycle resident witness",
                resident_witness && count == 4'd2 &&
                dut.producer_id_q[0] == dispatch0_pid_frozen &&
                dut.producer_id_q[1] == dispatch1_pid_frozen, 1'b1);
      issue0_ready = 1'b1;
      issue1_ready = 1'b1;
      #1;
      tb_check1("R3 pair universal terminal valid", issue0_valid, 1'b1);
      tb_check1("R3 pair ALU terminal valid", issue1_valid, 1'b1);
      tb_check32("R3 pair complex routes to universal", issue0_pc,
                 expect_universal_pc);
      tb_check32("R3 pair simple routes to ALU terminal", issue1_pc,
                 expect_alu_pc);
      tb_check1("R3 pair universal owns complex class",
                issue0_ctrl[`CTRL_BRANCH_BIT] || issue0_ctrl[`CTRL_JAL_BIT] ||
                issue0_ctrl[`CTRL_JALR_BIT] || issue0_ctrl[`CTRL_LOAD_BIT] ||
                issue0_ctrl[`CTRL_STORE_BIT] ||
                issue0_ctrl[`CTRL_MULDIV_BIT], 1'b1);
      tb_check1("R3 pair ALU terminal owns simple class",
                issue1_ctrl[`CTRL_BRANCH_BIT] || issue1_ctrl[`CTRL_JAL_BIT] ||
                issue1_ctrl[`CTRL_JALR_BIT] || issue1_ctrl[`CTRL_LOAD_BIT] ||
                issue1_ctrl[`CTRL_STORE_BIT] ||
                issue1_ctrl[`CTRL_MULDIV_BIT], 1'b0);
      tb_check1("V8O output complex control exact",
                issue0_ctrl == expect_complex_ctrl, 1'b1);
      tb_check1("V8O output simple control exact",
                issue1_ctrl == expect_simple_ctrl, 1'b1);
      tb_check1("V8O dynamic swap polarity",
                issue_pair_swapped, complex_older ? 1'b0 : 1'b1);
      universal_pid_match = issue0_producer_id == expect_universal_pid;
      alu_pid_match = issue1_producer_id == expect_alu_pid;
      tb_check1("V8O Universal exact full ProducerId",
                universal_pid_match, 1'b1);
      tb_check1("V8O ALU exact full ProducerId", alu_pid_match, 1'b1);
      canonical_dual_fire = issue0_valid && issue0_ready &&
                            issue1_valid && issue1_ready;
      tb_check1("V8O canonical same-edge dual fire",
                canonical_dual_fire, 1'b1);
      role_match = (issue0_pc == expect_universal_pc) &&
                   (issue1_pc == expect_alu_pc) &&
                   (issue0_ctrl == expect_complex_ctrl) &&
                   (issue1_ctrl == expect_simple_ctrl);
      if (!role_match)
        v8o_static_lane_role_violations =
            v8o_static_lane_role_violations + 1;
      $display("[V8O-ACTIVATION] class=%0d slot=slot%0d accepted_same_edge=%0b resident=%0b qcap=%0b%0b projection=%0b%0b swap=%0b fire=%0b%0b universal_pid=%0d expected_universal_pid=%0d alu_pid=%0d expected_alu_pid=%0d",
               observed_class, complex_older ? 0 : 1, same_edge_accept,
               resident_witness, dut.alu_terminal_capable_q[0],
               dut.alu_terminal_capable_q[1],
               dut.select_alu_capable_w[0], dut.select_alu_capable_w[1],
               issue_pair_swapped, issue0_valid && issue0_ready,
               issue1_valid && issue1_ready, issue0_producer_id,
               expect_universal_pid, issue1_producer_id, expect_alu_pid);
      fire_time = $time;
`ifdef V8O_NO_STATIC_LANE_SEMANTICS_FOCUSED
      if (canonical_dual_fire && universal_pid_match && alu_pid_match &&
          role_match && same_edge_accept && resident_witness &&
          (observed_class >= 0) && (observed_class < 6)) begin
        v8o_slot_coverage[observed_class][complex_older ? 0 : 1] = 1'b1;
      end
      if (canonical_dual_fire)
        v8o_same_cycle_pair_fires = v8o_same_cycle_pair_fires + 1;
      if (universal_pid_match)
        v8o_exact_full_pid_matches = v8o_exact_full_pid_matches + 1;
      if (alu_pid_match)
        v8o_exact_full_pid_matches = v8o_exact_full_pid_matches + 1;
      if (universal_pid_match && canonical_dual_fire) begin
        tb_check1("V8O Universal identity not previously fired",
                  v8o_fired_mask[expect_universal_pid], 1'b0);
        v8o_fired_mask[expect_universal_pid] = 1'b1;
        v8o_fired_transactions = v8o_fired_transactions + 1;
      end
      if (alu_pid_match && canonical_dual_fire) begin
        tb_check1("V8O ALU identity not previously fired",
                  v8o_fired_mask[expect_alu_pid], 1'b0);
        v8o_fired_mask[expect_alu_pid] = 1'b1;
        v8o_fired_transactions = v8o_fired_transactions + 1;
      end
`endif
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("R3 pair fires exactly once and drains", empty, 1'b1);
      drain_match = empty && count == 4'd0;
      $display("[V8O-SLOT-WITNESS] class=%0d slot=slot%0d accepted_same_edge=%0b resident_full_cycle=%0b pair_fire=%0b universal_pid_match=%0b alu_pid_match=%0b role_match=%0b drain=%0b fire_time=%0t",
               observed_class, complex_older ? 0 : 1, same_edge_accept,
               resident_witness, canonical_dual_fire, universal_pid_match,
               alu_pid_match, role_match, drain_match, fire_time);
    end
  endtask

  task automatic run_v8o_split_accept_negative;
    integer fill_i;
    integer before_pairs;
    integer before_pid_matches;
    reg split_credit;
    begin
      reset_dut();
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      // Fill seven of eight entries through ordinary accepted dispatches.
      for (fill_i = 0; fill_i < 3; fill_i = fill_i + 1) begin
        set_dispatch0(32'h8400_0000 + fill_i * 8, fill_i * 2,
                      6'd1, 1'b1, 6'd2, 1'b1, 6'd20 + fill_i * 2);
        set_dispatch1(32'h8400_0004 + fill_i * 8, fill_i * 2 + 1,
                      6'd3, 1'b1, 6'd4, 1'b1, 6'd21 + fill_i * 2);
        #1;
        tb_check1("V8O split-negative fill slot0 accepts",
                  dispatch0_valid && dispatch0_ready, 1'b1);
        tb_check1("V8O split-negative fill slot1 accepts",
                  dispatch1_valid && dispatch1_ready, 1'b1);
        `TB_TICK(clk);
        clear_inputs();
      end
      set_dispatch0(32'h8400_0030, 4'd6,
                    6'd5, 1'b1, 6'd6, 1'b1, 6'd26);
      #1;
      tb_check1("V8O split-negative seventh entry accepts",
                dispatch0_valid && dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("V8O split-negative starts with seven residents",
                 {28'b0, count}, 32'd7);
      before_pairs = v8o_same_cycle_pair_fires;
      before_pid_matches = v8o_exact_full_pid_matches;
      set_dispatch0(32'h8400_0040, 4'd7,
                    6'd7, 1'b1, 6'd8, 1'b1, 6'd27);
      set_dispatch1(32'h8400_0044, 4'd8,
                    6'd9, 1'b1, 6'd10, 1'b1, 6'd28);
      dispatch1_ctrl = r3_complex_ctrl(3);
      #1;
      split_credit = dispatch0_valid && dispatch0_ready &&
                     dispatch1_valid && dispatch1_ready;
      tb_check1("V8O split-negative slot0 accepts",
                dispatch0_valid && dispatch0_ready, 1'b1);
      tb_check1("V8O split-negative slot1 is backpressured",
                dispatch1_valid && dispatch1_ready, 1'b0);
      tb_check1("V8O split-negative package gets no credit",
                split_credit, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("V8O split-negative queue reaches eight",
                 {28'b0, count}, 32'd8);
      tb_check32("V8O split-negative pair counter unchanged",
                 v8o_same_cycle_pair_fires, before_pairs);
      tb_check32("V8O split-negative PID counter unchanged",
                 v8o_exact_full_pid_matches, before_pid_matches);
      $display("[V8O-SPLIT-ACCEPT-NEGATIVE] accepted_slot0=1 accepted_slot1=0 coverage_credit=0 count=%0d",
               count);
      reset_dut();
    end
  endtask

  // R3.1 handshake matrix.  Bits are {Universal-base-ready, ALU-ready}.
  // The backend must turn Universal ready into 0 for an age-swapped pair
  // unless the older ALU terminal is also firing.  This task models that
  // coupling at the standalone IQ boundary and verifies compaction.
  task automatic run_r3p1_swapped_ready_case;
    input [1:0] ready_case;
    reg effective_universal_ready;
    begin
      reset_dut();
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      set_dispatch0(32'h8300_0000 + ({30'b0, ready_case} << 4),
                    4'd1, 6'd1, 1'b1, 6'd2, 1'b1, 6'd40);
      set_dispatch1(32'h8300_0004 + ({30'b0, ready_case} << 4),
                    4'd2, 6'd3, 1'b1, 6'd4, 1'b1, 6'd41);
      dispatch1_ctrl = r3_complex_ctrl(3);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("R3.1 ready matrix presents Universal", issue0_valid, 1'b1);
      tb_check1("R3.1 ready matrix presents ALU", issue1_valid, 1'b1);
      tb_check1("R3.1 ready matrix marks age swap", issue_pair_swapped, 1'b1);
      tb_check32("R3.1 ready matrix younger load on Universal", issue0_pc,
                 32'h8300_0004 + ({30'b0, ready_case} << 4));
      tb_check32("R3.1 ready matrix older ALU on ALU terminal", issue1_pc,
                 32'h8300_0000 + ({30'b0, ready_case} << 4));
      issue1_ready = ready_case[0];
      effective_universal_ready =
          ready_case[1] && (!issue_pair_swapped || issue1_ready);
      issue0_ready = effective_universal_ready;
      #1;
      tb_check1("R3.1 memory-pop implies older-ALU fire",
                issue0_ready && !issue1_ready, 1'b0);
      `TB_TICK(clk);
      #1;
      case (ready_case)
        2'b00: begin
          tb_check32("R3.1 ready00 holds both", {28'b0, count}, 32'd2);
          tb_check1("R3.1 ready00 keeps swap", issue_pair_swapped, 1'b1);
        end
        2'b01: begin
          tb_check32("R3.1 ready01 fires only older ALU",
                     {28'b0, count}, 32'd1);
          tb_check1("R3.1 ready01 leaves younger memory", issue0_valid, 1'b1);
          tb_check1("R3.1 ready01 clears pair marker", issue_pair_swapped, 1'b0);
        end
        2'b10: begin
          tb_check32("R3.1 ready10 blocks orphan memory",
                     {28'b0, count}, 32'd2);
          tb_check1("R3.1 ready10 keeps swap", issue_pair_swapped, 1'b1);
        end
        default: tb_check1("R3.1 ready11 drains both", empty, 1'b1);
      endcase
      $display("[R3P1-READY-MATRIX] ready=%b effective_universal=%0b count=%0d",
               ready_case, effective_universal_ready, count);
    end
  endtask

  task automatic run_r3p1_registered_owner_sole_alu;
    begin
      reset_dut();
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      set_dispatch0(32'h8300_0100, 4'd3, 6'd5, 1'b1,
                    6'd6, 1'b1, 6'd42);
      `TB_TICK(clk);
      clear_inputs();
      universal_owner_present = 1'b1;
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      #1;
      tb_check1("R3.1 registered owner suppresses Universal",
                issue0_valid, 1'b0);
      tb_check1("R3.1 sole ALU dynamically owns ALU terminal",
                issue1_valid, 1'b1);
      tb_check32("R3.1 sole ALU identity", issue1_pc, 32'h8300_0100);
      `TB_TICK(clk);
      #1;
      tb_check32("R3.1 sole ALU backpressure holds",
                 {28'b0, count}, 32'd1);
      issue1_ready = 1'b1;
      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 sole ALU drains while owner remains", empty, 1'b1);
      tb_check1("R3.1 Universal stays quiet while owner remains",
                issue0_valid, 1'b0);
      $display("[R3P1-REGISTERED-OWNER-SOLE-ALU] PASS");
    end
  endtask


  // R3 capability 反例矩阵：每个复杂候选均夹在 older/younger simple-ALU
  // 之间。复杂候选必须当拍路由到 Universal terminal，older simple 必须动态
  // 路由到 ALU terminal；不得用跳过复杂候选、下一拍再晋升来伪装双发。
  task automatic run_lane1_negative_class;
    input integer class_id;
    reg [`CTRL_BUS_W-1:0] candidate_ctrl;
    reg candidate_fp_st;
    begin
      reset_dut();
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      set_dispatch0(32'h8100_0000 + (class_id * 32'h20),
                    4'd1, 6'd1, 1'b1, 6'd2, 1'b1, 6'd40);
      set_dispatch1(32'h8100_0004 + (class_id * 32'h20),
                    4'd2, 6'd3, 1'b1, 6'd4, 1'b1, 6'd41);
      candidate_ctrl = dispatch1_ctrl;
      candidate_fp_st = 1'b0;
      case (class_id)
        0: begin
          candidate_ctrl[`CTRL_LOAD_BIT] = 1'b1;
          candidate_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
          candidate_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
        end
        1: candidate_ctrl[`CTRL_MULDIV_BIT] = 1'b1;
        2: candidate_ctrl[`CTRL_BITMANIP_BIT] = 1'b1;
        3: begin
          candidate_ctrl[`CTRL_CSR_BIT] = 1'b1;
          candidate_ctrl[`CTRL_SYSTEM_BIT] = 1'b1;
          candidate_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_CSR;
        end
        4: begin
          candidate_ctrl[`CTRL_FENCE_BIT] = 1'b1;
          candidate_ctrl[`CTRL_MISC_MEM_BIT] = 1'b1;
          candidate_ctrl[`CTRL_RD_EN_BIT] = 1'b0;
          candidate_ctrl[`CTRL_NEED_WB_BIT] = 1'b0;
          candidate_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_NONE;
        end
        5: begin
          candidate_ctrl[`CTRL_AMO_BIT] = 1'b1;
          candidate_ctrl[`CTRL_LOAD_BIT] = 1'b1;
          candidate_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
        end
        6: candidate_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
        7: candidate_fp_st = 1'b1;
        default: candidate_ctrl[`CTRL_ILLEGAL_BIT] = 1'b1;
      endcase
      dispatch1_ctrl = candidate_ctrl;
      dispatch1_fp_st_src_en = candidate_fp_st;
      dispatch1_fp_st_src_preg = 6'd9;
      dispatch1_fp_st_src_ready = 1'b1;
      `TB_TICK(clk);
      clear_inputs();
      set_dispatch0(32'h8100_0008 + (class_id * 32'h20),
                    4'd3, 6'd5, 1'b1, 6'd6, 1'b1, 6'd42);
      `TB_TICK(clk);
      clear_inputs();
      issue0_ready = 1'b1;
      issue1_ready = 1'b1;
      #1;
      $display("[T3Q-LANE1-NEG] class=%0d lane0_pc=%h lane1_pc=%h count=%0d",
               class_id, issue0_pc, issue1_pc, count);
      tb_check1("R3 complex owns Universal terminal", issue0_valid, 1'b1);
      tb_check1("R3 older simple owns ALU terminal", issue1_valid, 1'b1);
      tb_check32("R3 Universal takes complex candidate", issue0_pc,
                 32'h8100_0004 + (class_id * 32'h20));
      tb_check32("R3 ALU terminal takes older simple", issue1_pc,
                 32'h8100_0000 + (class_id * 32'h20));
      `TB_TICK(clk);
      #1;
      tb_check32("R3 younger simple remains", {28'b0, count}, 32'd1);
      tb_check1("R3 remaining simple uses Universal alone", issue0_valid, 1'b1);
      tb_check1("R3 no duplicate ALU-terminal owner", issue1_valid, 1'b0);
      tb_check32("R3 remaining simple identity", issue0_pc,
                 32'h8100_0008 + (class_id * 32'h20));
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("T3Q negative case drains", empty, 1'b1);
    end
  endtask

  // R3.2 allow-list proof.  Class 0 is the only positive fixed-latency GPR
  // producer; all speculative/multicycle/exception-bearing categories must
  // retain formal-WB wake latency.
  task automatic run_r3p2_fixed_class_case;
    input integer class_id;
    reg expected_fixed;
    begin
      reset_dut();
      set_dispatch0(32'h8400_0000 + (class_id * 32'h20),
                    4'd1, 6'd1, 1'b1, 6'd2, 1'b1, 6'd40);
      expected_fixed = (class_id == 0);
      case (class_id)
        1: begin // load
          dispatch0_ctrl[`CTRL_LOAD_BIT] = 1'b1;
          dispatch0_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
          dispatch0_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
        end
        2: begin // AMO
          dispatch0_ctrl[`CTRL_AMO_BIT] = 1'b1;
          dispatch0_ctrl[`CTRL_LOAD_BIT] = 1'b1;
          dispatch0_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
        end
        3: dispatch0_ctrl[`CTRL_MULDIV_BIT] = 1'b1;
        4: begin // CLMUL encoding: funct7=0x05, funct3=SLL
          dispatch0_ctrl[`CTRL_BITMANIP_BIT] = 1'b1;
          dispatch0_inst = {7'h05, 5'd2, 5'd1, `FUNCT3_SLL,
                            5'd5, `OPCODE_OP};
        end
        5: begin // CSR/system
          dispatch0_ctrl[`CTRL_CSR_BIT] = 1'b1;
          dispatch0_ctrl[`CTRL_SYSTEM_BIT] = 1'b1;
          dispatch0_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_CSR;
        end
        6: dispatch0_is_fp = 1'b1;
        7: dispatch0_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
        8: dispatch0_ctrl[`CTRL_ILLEGAL_BIT] = 1'b1;
        default: begin end
      endcase
      #1;
      tb_check1("R3.2 fixed-class dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("R3.2 fixed-class metadata", dut.fixed_gpr_producer_q[0],
                expected_fixed);
      $display("[R3P2-FIXED-CLASS] class=%0d fixed=%0b expected=%0b",
               class_id, dut.fixed_gpr_producer_q[0], expected_fixed);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("R3.2 fixed-class drains", empty, 1'b1);
    end
  endtask

  task automatic run_fp_dispatch_wake_collision;
    input dispatch_lane;
    input wake_lane;
    input [PHY_REG_ADDR_W-1:0] fp_preg;
    input [`XLEN-1:0] pc;
    input [ROB_INDEX_W-1:0] rob_idx;
    begin
      reset_dut();
      if (dispatch_lane == 1'b0) begin
        set_dispatch0(pc, rob_idx, 6'd9, 1'b1, 6'd10, 1'b1, 6'd0);
        dispatch0_ctrl[`CTRL_STORE_BIT] = 1'b1;
        dispatch0_fp_st_src_en = 1'b1;
        dispatch0_fp_st_src_preg = fp_preg;
        dispatch0_fp_st_src_ready = 1'b0;
      end else begin
        set_dispatch1(pc, rob_idx, 6'd11, 1'b1, 6'd12, 1'b1, 6'd0);
        dispatch1_ctrl[`CTRL_STORE_BIT] = 1'b1;
        dispatch1_fp_st_src_en = 1'b1;
        dispatch1_fp_st_src_preg = fp_preg;
        dispatch1_fp_st_src_ready = 1'b0;
      end
      if (wake_lane == 1'b0) begin
        fp_wake0_valid = 1'b1;
        fp_wake0_preg = fp_preg;
      end else begin
        fp_wake1_valid = 1'b1;
        fp_wake1_preg = fp_preg;
      end
      #1;
      if (dispatch_lane == 1'b0)
        tb_check1("[T3H-COLLISION] lane0 dispatch accepted",
                  dispatch0_ready, 1'b1);
      else
        tb_check1("[T3H-COLLISION] lane1 dispatch accepted",
                  dispatch1_ready, 1'b1);
      tb_check1("[T3H-COLLISION] no dispatch bypass issue0",
                issue0_valid, 1'b0);
      tb_check1("[T3H-COLLISION] no dispatch bypass issue1",
                issue1_valid, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      $display("[T3H-COLLISION-OBS] dispatch=%0d wake=%0d preg=%0d N+1 count=%0d sticky=%0b issue={%0b,%0b} pc=0x%08x",
               dispatch_lane, wake_lane, fp_preg, count,
               dut.fp_st_ready_q[0], issue0_valid, issue1_valid,
               issue0_pc[31:0]);
      tb_check32("[T3H-COLLISION] entry remains resident",
                 {28'b0, count}, 32'd1);
      tb_check1("[T3H-COLLISION] N edge captures wake into sticky",
                dut.fp_st_ready_q[0], 1'b1);
      tb_check1("[T3H-COLLISION] captured entry issues in N+1",
                issue0_valid, 1'b1);
      tb_check32("[T3H-COLLISION] issue PC identity", issue0_pc, pc);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("[T3H-COLLISION] captured entry drains", empty, 1'b1);
    end
  endtask

  // v8f carrier contract: full ProducerId, rather than a parallel raw-index
  // state array, must remain attached to the same entry across hold,
  // compaction, simultaneous replacement dispatch, and selective kill.
  task automatic run_v8f_producer_id_carrier;
    reg [PRODUCER_ID_W-1:0] id0;
    reg [PRODUCER_ID_W-1:0] id1;
    reg [PRODUCER_ID_W-1:0] id2;
    reg [PRODUCER_COUNT-1:0] expected_live_mask;
    begin
      id0 = {PRODUCER_ID_W{1'b0}};
      id0[PRODUCER_ID_W-1:ROB_INDEX_W] = {PRODUCER_GEN_W{1'b1}};
      id0[ROB_INDEX_W-1:0] = 4'd3;
      id1 = {PRODUCER_ID_W{1'b0}};
      id1[ROB_INDEX_W] = 1'b1;
      id1[ROB_INDEX_W-1:0] = 4'd4;
      id2 = {PRODUCER_ID_W{1'b0}};
      id2[PRODUCER_ID_W-1] = 1'b1;
      id2[ROB_INDEX_W-1:0] = 4'd5;

      reset_dut();
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      set_dispatch0(32'h8000_1200, 4'd3,
                    6'd1, 1'b1, 6'd2, 1'b1, 6'd40);
      dispatch0_producer_id = id0;
      set_dispatch1(32'h8000_1204, 4'd4,
                    6'd3, 1'b1, 6'd4, 1'b1, 6'd41);
      dispatch1_producer_id = id1;
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("v8f dual carrier exposes issue0", issue0_valid, 1'b1);
      tb_check1("v8f dual carrier exposes issue1", issue1_valid, 1'b1);
      tb_check32("v8f lane0 full producer id",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id0});
      tb_check32("v8f lane1 full producer id",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue1_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id1});
      tb_check32("v8f lane0 raw projection", {28'b0, issue0_rob_idx},
                 {28'b0, id0[ROB_INDEX_W-1:0]});
      tb_check32("v8f lane1 raw projection", {28'b0, issue1_rob_idx},
                 {28'b0, id1[ROB_INDEX_W-1:0]});
      expected_live_mask = {PRODUCER_COUNT{1'b0}};
      expected_live_mask[id0] = 1'b1;
      expected_live_mask[id1] = 1'b1;
      if (producer_live_mask !== expected_live_mask) begin
        $display("FAIL v8l IntIQ dual raw-Q mask actual=%h expected=%h",
                 producer_live_mask, expected_live_mask);
        tb_errors = tb_errors + 1;
      end

      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("v8f stalled lane0 id holds",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id0});
      tb_check32("v8f stalled lane1 id holds",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue1_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id1});
      if (producer_live_mask !== expected_live_mask) begin
        $display("FAIL v8l IntIQ hold changed raw-Q mask");
        tb_errors = tb_errors + 1;
      end

      issue0_ready = 1'b1;
      issue1_ready = 1'b0;
      `TB_TICK(clk);
      clear_inputs();
      issue0_ready = 1'b0;
      #1;
      tb_check32("v8f survivor compacts with full id",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id1});
      tb_check32("v8f compaction leaves one entry", {28'b0, count}, 32'd1);
      expected_live_mask = {PRODUCER_COUNT{1'b0}};
      expected_live_mask[id1] = 1'b1;
      if (producer_live_mask !== expected_live_mask) begin
        $display("FAIL v8l IntIQ death-edge survivor mask actual=%h expected=%h",
                 producer_live_mask, expected_live_mask);
        tb_errors = tb_errors + 1;
      end

      issue0_ready = 1'b1;
      set_dispatch0(32'h8000_1208, 4'd5,
                    6'd5, 1'b1, 6'd6, 1'b1, 6'd42);
      dispatch0_producer_id = id2;
      `TB_TICK(clk);
      clear_inputs();
      issue0_ready = 1'b0;
      #1;
      tb_check32("v8f replacement dispatch keeps its full id",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id2});
      tb_check32("v8f replacement leaves one entry", {28'b0, count}, 32'd1);
      expected_live_mask = {PRODUCER_COUNT{1'b0}};
      expected_live_mask[id2] = 1'b1;
      if (producer_live_mask !== expected_live_mask) begin
        $display("FAIL v8l IntIQ replacement mask actual=%h expected=%h",
                 producer_live_mask, expected_live_mask);
        tb_errors = tb_errors + 1;
      end

      reset_dut();
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      id0[ROB_INDEX_W-1:0] = 4'd14;
      id1[ROB_INDEX_W-1:0] = 4'd15;
      id2[ROB_INDEX_W-1:0] = 4'd0;
      set_dispatch0(32'h8000_1210, 4'd14,
                    6'd7, 1'b1, 6'd8, 1'b1, 6'd43);
      dispatch0_producer_id = id0;
      set_dispatch1(32'h8000_1214, 4'd15,
                    6'd9, 1'b1, 6'd10, 1'b1, 6'd44);
      dispatch1_producer_id = id1;
      `TB_TICK(clk);
      clear_inputs();
      set_dispatch0(32'h8000_1218, 4'd0,
                    6'd11, 1'b1, 6'd12, 1'b1, 6'd45);
      dispatch0_producer_id = id2;
      `TB_TICK(clk);
      clear_inputs();
      expected_live_mask = {PRODUCER_COUNT{1'b0}};
      expected_live_mask[id0] = 1'b1;
      expected_live_mask[id1] = 1'b1;
      expected_live_mask[id2] = 1'b1;
      if (producer_live_mask !== expected_live_mask) begin
        $display("FAIL v8l IntIQ pre-kill raw-Q mask actual=%h expected=%h",
                 producer_live_mask, expected_live_mask);
        tb_errors = tb_errors + 1;
      end
      kill_valid = 1'b1;
      kill_rob_idx = 4'd15;
      rob_head_idx = 4'd14;
      #1;
      tb_check1("v8f kill cycle suppresses issue0", issue0_valid, 1'b0);
      tb_check1("v8f kill cycle suppresses issue1", issue1_valid, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      issue0_ready = 1'b0;
      issue1_ready = 1'b0;
      #1;
      tb_check32("v8f kill keeps survivor count", {28'b0, count}, 32'd2);
      tb_check32("v8f kill keeps oldest full id",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue0_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id0});
      tb_check32("v8f kill keeps boundary full id",
                 {{(32-PRODUCER_ID_W){1'b0}}, issue1_producer_id},
                 {{(32-PRODUCER_ID_W){1'b0}}, id1});
      tb_check1("v8f kill clears strictly-younger slot", dut.valid_q[2], 1'b0);
      expected_live_mask = {PRODUCER_COUNT{1'b0}};
      expected_live_mask[id0] = 1'b1;
      expected_live_mask[id1] = 1'b1;
      if (producer_live_mask !== expected_live_mask) begin
        $display("FAIL v8l IntIQ selective-kill mask actual=%h expected=%h",
                 producer_live_mask, expected_live_mask);
        tb_errors = tb_errors + 1;
      end
      $display("[V8F-INTIQ-PRODUCER-CARRIER] dual/hold/compact/replace/kill PASS");
      reset_dut();
      if (producer_live_mask !== {PRODUCER_COUNT{1'b0}}) begin
        $display("FAIL v8l IntIQ reset mask is nonzero");
        tb_errors = tb_errors + 1;
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

`ifdef V8O_NO_STATIC_LANE_SEMANTICS_FOCUSED
    v8o_same_cycle_pair_fires = 0;
    v8o_exact_full_pid_matches = 0;
    v8o_static_lane_role_violations = 0;
    v8o_accepted_transactions = 0;
    v8o_fired_transactions = 0;
    v8o_accepted_mask = {PRODUCER_COUNT{1'b0}};
    v8o_fired_mask = {PRODUCER_COUNT{1'b0}};
    for (lane1_negative_i = 0; lane1_negative_i < 6;
         lane1_negative_i = lane1_negative_i + 1)
      v8o_slot_coverage[lane1_negative_i] = 2'b00;

    run_v8o_split_accept_negative();
    for (lane1_negative_i = 0; lane1_negative_i < 6;
         lane1_negative_i = lane1_negative_i + 1) begin
      run_r3_capability_pair(lane1_negative_i, 1'b1);
      run_r3_capability_pair(lane1_negative_i, 1'b0);
    end
    for (lane1_negative_i = 0; lane1_negative_i < 6;
         lane1_negative_i = lane1_negative_i + 1)
      tb_check32("V8O each accepted class covers both program slots",
                 {30'b0, v8o_slot_coverage[lane1_negative_i]}, 32'd3);
    tb_check32("V8O twelve same-edge pair fires",
               v8o_same_cycle_pair_fires, 32'd12);
    tb_check32("V8O twenty-four exact full PID matches",
               v8o_exact_full_pid_matches, 32'd24);
    tb_check32("V8O accepted transaction ledger size",
               v8o_accepted_transactions, 32'd24);
    tb_check32("V8O fired transaction ledger size",
               v8o_fired_transactions, 32'd24);
    tb_check1("V8O accepted and fired identity masks equal",
              v8o_accepted_mask == v8o_fired_mask, 1'b1);
    tb_check32("V8O zero static role violations",
               v8o_static_lane_role_violations, 32'd0);
`ifdef V8O_MODE_ASSERT
    $display("[V8O-NO-STATIC-LANE-METRICS] mode=assert permutations=12 static_lane_role_violations=%0d same_cycle_pair_fires=%0d exact_full_pid_matches=%0d accepted=%0d fired=%0d",
             v8o_static_lane_role_violations,
             v8o_same_cycle_pair_fires, v8o_exact_full_pid_matches,
             v8o_accepted_transactions, v8o_fired_transactions);
`else
    $display("[V8O-NO-STATIC-LANE-METRICS] mode=release permutations=12 static_lane_role_violations=%0d same_cycle_pair_fires=%0d exact_full_pid_matches=%0d accepted=%0d fired=%0d",
             v8o_static_lane_role_violations,
             v8o_same_cycle_pair_fires, v8o_exact_full_pid_matches,
             v8o_accepted_transactions, v8o_fired_transactions);
`endif
    $display("[V8O-NO-STATIC-LANE-SEMANTICS] accepted-package/resident/capability/full-PID/canonical-fire PASS");
    tb_finish("tb_ooo_int_issue_queue");
`endif

`ifdef IQ_FP_WAKE_STICKY_NEGATIVE
    // T3D 非真空负探针：先经合法 dispatch 建立 index0 resident FP-store，
    // integer operands 均 ready、FP source sticky 尚未 ready。匹配 fp_wake
    // 本身不得拉 issue；仅在消费边界 force issue0_valid 跨一个 posedge，
    // 证明 IQ-FP-WAKE-STICKY-ONLY 的 issue0 分支有牙且 lane1 静默。
    set_dispatch0(32'h8000_0fc0, 4'd6,
                  6'd1, 1'b1, 6'd2, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_STORE_BIT] = 1'b1;
    dispatch0_fp_st_src_en = 1'b1;
    dispatch0_fp_st_src_preg = 6'd23;
    dispatch0_fp_st_src_ready = 1'b0;
    #1;
    tb_check1("IQ FP sticky negative dispatch ready",
              dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("IQ FP sticky negative index0 valid", dut.valid_q[0], 1'b1);
    tb_check1("IQ FP sticky negative source enabled",
              dut.fp_st_en_q[0], 1'b1);
    tb_check1("IQ FP sticky negative starts unready",
              dut.fp_st_ready_q[0], 1'b0);
    tb_check1("IQ FP sticky negative naturally not selected",
              issue0_valid, 1'b0);

    fp_wake0_valid = 1'b1;
    fp_wake0_preg = 6'd23;
    #1;
    tb_check1("IQ FP sticky negative wake alone stays non-select",
              issue0_valid, 1'b0);
    $display("[IQ-FP-WAKE-STICKY-NEGATIVE] resident idx0 valid=%0b fp_en=%0b fp_ready=%0b fp_preg=%0d wake=%0b/%0d natural_issue={%0b,%0b}",
             dut.valid_q[0], dut.fp_st_en_q[0], dut.fp_st_ready_q[0],
             dut.fp_st_preg_q[0], fp_wake0_valid, fp_wake0_preg,
             issue0_valid, issue1_valid);
    force dut.issue0_valid_o = 1'b1;
    $display("[IQ-FP-WAKE-STICKY-NEGATIVE] force issue0_valid across assertion edge");
    `TB_TICK(clk);
    #1;
    release dut.issue0_valid_o;
    $display("[IQ-FP-WAKE-STICKY-NEGATIVE] completed one assertion edge");
    $finish_and_return(0);
`endif

`ifdef IQ_FP_WAKE_STICKY_NEGATIVE_LANE1
    // issue1 对 store 在合法 select 中结构性禁止；该防御分支用最小 malformed
    // mutation 证明并非真空。index 默认指向合法 resident idx0，只 force valid。
    set_dispatch0(32'h8000_0fc4, 4'd7,
                  6'd3, 1'b1, 6'd4, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_STORE_BIT] = 1'b1;
    dispatch0_fp_st_src_en = 1'b1;
    dispatch0_fp_st_src_preg = 6'd24;
    dispatch0_fp_st_src_ready = 1'b0;
    `TB_TICK(clk);
    clear_inputs();
    issue0_ready = 1'b0;
    issue1_ready = 1'b0;
    fp_wake1_valid = 1'b1;
    fp_wake1_preg = 6'd24;
    #1;
    tb_check1("IQ FP sticky lane1 negative resident valid",
              dut.valid_q[0], 1'b1);
    tb_check1("IQ FP sticky lane1 negative starts unready",
              dut.fp_st_ready_q[0], 1'b0);
    tb_check1("IQ FP sticky lane1 negative naturally blocked",
              issue1_valid, 1'b0);
    force dut.issue1_valid_o = 1'b1;
    $display("[IQ-FP-WAKE-STICKY-NEGATIVE-LANE1] force issue1_valid idx=%0d sticky=%0b",
             dut.issue1_idx_r, dut.fp_st_ready_q[0]);
    `TB_TICK(clk);
    release dut.issue1_valid_o;
    $display("[IQ-FP-WAKE-STICKY-NEGATIVE-LANE1] completed one assertion edge");
    $finish_and_return(0);
`endif

`ifdef IQ_INT_WAKE_STICKY_NEGATIVE
    // 非真空负探针：合法建立一个等待 preg21 的 resident，匹配 full wake
    // 自然不能在 N 拍 select；只 force issue valid 跨过 N 沿，精准证明
    // IQ-INT-WAKE-STICKY-ONLY 有牙。
    set_dispatch0(32'h8000_0fb0, 4'd5,
                  6'd21, 1'b0, 6'd0, 1'b1, 6'd22);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("IQ integer sticky negative resident valid",
              dut.valid_q[0], 1'b1);
    tb_check1("IQ integer sticky negative source starts unready",
              dut.src1_ready_q[0], 1'b0);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd21;
    #1;
    tb_check1("IQ integer sticky negative full wake stays non-select",
              issue0_valid, 1'b0);
    force dut.issue0_valid_o = 1'b1;
    $display("[IQ-INT-WAKE-STICKY-NEGATIVE] force issue0 with sticky=%0b wake=%0b/%0d",
             dut.src1_ready_q[0], wakeup0_valid, wakeup0_pdest);
    `TB_TICK(clk);
    release dut.issue0_valid_o;
    #1;
    $display("[IQ-INT-WAKE-STICKY-NEGATIVE] completed one assertion edge");
    $finish_and_return(0);
`endif

    run_v8u_memory_pair_peek();
    tb_check1("reset empty", empty, 1'b1);

    // ===== S2 单发 N+1 契约:dispatch 当拍绝不发射,次拍从寄存项发射 =====
    set_dispatch0(32'h8000_0000, 4'd0, 6'd1, 1'b1, 6'd2, 1'b1, 6'd32);
    #1;
    tb_check1("dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("dispatch1 ready", dispatch1_ready, 1'b1);
    tb_check1("no same-cycle bypass issue0", issue0_valid, 1'b0);
    tb_check1("no same-cycle bypass issue1", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("queued after dispatch", {28'b0, count}, 32'd1);
    tb_check1("next-cycle issue from queue", issue0_valid, 1'b1);
    tb_check32("next-cycle issue pc", issue0_pc, 32'h8000_0000);
    tb_check32("next-cycle issue imm", issue0_imm, 32'h8000_0010);
    tb_check1("single entry keeps issue1 idle", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after single issue", empty, 1'b1);

    // ===== S3 双发 N+1 契约:双 dispatch 次拍程序序双发 =====
    set_dispatch0(32'h8000_0010, 4'd2, 6'd1, 1'b1, 6'd2, 1'b1, 6'd34);
    set_dispatch1(32'h8000_0014, 4'd3, 6'd3, 1'b1, 6'd4, 1'b1, 6'd35);
    #1;
    tb_check1("dual dispatch no same-cycle issue0", issue0_valid, 1'b0);
    tb_check1("dual dispatch no same-cycle issue1", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("dual dispatch queued", {28'b0, count}, 32'd2);
    tb_check1("dual issue0 valid", issue0_valid, 1'b1);
    tb_check1("dual issue1 valid", issue1_valid, 1'b1);
    tb_check32("dual issue0 oldest pc", issue0_pc, 32'h8000_0010);
    tb_check32("dual issue1 younger pc", issue1_pc, 32'h8000_0014);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after dual issue", empty, 1'b1);

    // ===== R3：控制流动态取得 Universal，older ALU 改走 ALU terminal =====
    set_dispatch0(32'h8000_0018, 4'd10,
                  6'd1, 1'b1, 6'd2, 1'b1, 6'd36);
    set_dispatch1(32'h8000_001c, 4'd11,
                  6'd3, 1'b1, 6'd4, 1'b1, 6'd0);
    dispatch1_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    issue0_ready = 1'b0;
    issue1_ready = 1'b0;
    set_dispatch0(32'h8000_0020, 4'd12,
                  6'd5, 1'b1, 6'd6, 1'b1, 6'd37);
    #1;
    tb_check1("R3 branch occupies Universal", issue0_valid, 1'b1);
    tb_check32("R3 Universal branch pc", issue0_pc, 32'h8000_001c);
    tb_check1("R3 older ALU occupies ALU terminal", issue1_valid, 1'b1);
    tb_check32("R3 ALU terminal older pc", issue1_pc, 32'h8000_0018);
    `TB_TICK(clk);
    clear_inputs();
    issue0_ready = 1'b1;
    issue1_ready = 1'b1;
    #1;
    tb_check32("T3N three entries resident", {28'b0, count}, 32'd3);
    tb_check1("R3 Universal terminal valid", issue0_valid, 1'b1);
    tb_check1("R3 ALU terminal valid", issue1_valid, 1'b1);
    tb_check32("R3 Universal selects branch", issue0_pc, 32'h8000_001c);
    tb_check32("R3 ALU terminal selects oldest ALU", issue1_pc, 32'h8000_0018);
    tb_check1("R3 ALU terminal payload is not branch",
              issue1_ctrl[`CTRL_BRANCH_BIT], 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("R3 younger ALU remains", {28'b0, count}, 32'd1);
    tb_check1("R3 remaining ALU uses Universal alone", issue0_valid, 1'b1);
    tb_check32("R3 remaining ALU pc", issue0_pc, 32'h8000_0020);
    tb_check1("R3 remaining payload is not branch",
              issue0_ctrl[`CTRL_BRANCH_BIT], 1'b0);
    tb_check1("R3 ALU terminal idle for sole uop", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("R3 capability trio drains", empty, 1'b1);

    // ===== S4 / T3M RED→GREEN：EX/full wake 只落 sticky，N+1 发射 =====
    set_dispatch0(32'h8000_0020, 4'd4, 6'd1, 1'b1, 6'd2, 1'b1, 6'd40);
    set_dispatch1(32'h8000_0024, 4'd5, 6'd40, 1'b0, 6'd3, 1'b1, 6'd41);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("producer issues", issue0_valid, 1'b1);
    tb_check32("producer pc", issue0_pc, 32'h8000_0020);
    tb_check1("dependent lane1 waits (no forward)", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("dependent stays queued", {28'b0, count}, 32'd1);
    tb_check1("dependent not ready yet", issue0_valid, 1'b0);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd40;
    #1;
    tb_check1("T3M full wake does not select queued entry in N",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3M sticky entry selects in N+1", issue0_valid, 1'b1);
    tb_check32("T3M sticky issue pc", issue0_pc, 32'h8000_0024);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after wakeup issue", empty, 1'b1);

    // ===== T3B RED→GREEN:full-only wakeup 只更新 resident ready =====
    // N 拍不发射，上升沿吸收 full wakeup 后 N+1 发射。
    set_dispatch0(32'h8000_0028, 4'd6, 6'd42, 1'b0,
                  6'd0, 1'b1, 6'd39);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("[T3B-RED] resident setup count", {28'b0, count}, 32'd1);
    tb_check1("[T3B-RED] resident waits before full wakeup",
              issue0_valid, 1'b0);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd42;
    #1;
    tb_check1("[T3B-RED] full wakeup must not issue in N",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3B-RED] full wakeup issues in N+1",
              issue0_valid, 1'b1);
    tb_check32("[T3B-RED] N+1 issue keeps resident PC",
               issue0_pc, 32'h8000_0028);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3B-RED] delayed resident drains", empty, 1'b1);

    // ===== T3B WB1 full-only：与 lane0 同样必须延迟到 N+1 =====
    set_dispatch0(32'h8000_002c, 4'd7, 6'd43, 1'b0,
                  6'd0, 1'b1, 6'd40);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3B-GREEN] WB1 resident waits", issue0_valid, 1'b0);
    wakeup1_valid = 1'b1;
    wakeup1_pdest = 6'd43;
    #1;
    tb_check1("[T3B-GREEN] WB1 full-only must not issue in N",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3B-GREEN] WB1 full-only issues in N+1",
              issue0_valid, 1'b1);
    tb_check32("[T3B-GREEN] WB1 N+1 resident PC",
               issue0_pc, 32'h8000_002c);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3B-GREEN] WB1 delayed resident drains", empty, 1'b1);

    // ===== T3M dual-source：两路 full wake 同沿落 sticky，N+1 双发 =====
    set_dispatch0(32'h8000_0034, 4'd8, 6'd45, 1'b0,
                  6'd0, 1'b1, 6'd46);
    set_dispatch1(32'h8000_0038, 4'd9, 6'd44, 1'b0,
                  6'd0, 1'b1, 6'd47);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("[T3B-GREEN] mixed resident count", {28'b0, count}, 32'd2);
    tb_check1("[T3B-GREEN] mixed residents initially wait",
              issue0_valid, 1'b0);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd44;
    wakeup1_valid = 1'b1;
    wakeup1_pdest = 6'd45;
    #1;
    tb_check1("[T3M-RED] dual full wake does not issue0 in N",
              issue0_valid, 1'b0);
    tb_check1("[T3M-RED] dual full wake does not issue1 in N",
              issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("[T3M-GREEN] dual wake keeps both residents through edge",
               {28'b0, count}, 32'd2);
    tb_check1("[T3M-GREEN] older resident issues in N+1",
              issue0_valid, 1'b1);
    tb_check1("[T3M-GREEN] younger resident issues in N+1",
              issue1_valid, 1'b1);
    tb_check32("[T3M-GREEN] older resident PC",
               issue0_pc, 32'h8000_0034);
    tb_check32("[T3M-GREEN] younger resident PC",
               issue1_pc, 32'h8000_0038);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3B-GREEN] mixed residents drain", empty, 1'b1);

    // ===== S5 dispatch 撞 full-only wakeup:当拍不发射,写入仍吸收唤醒 =====
    set_dispatch0(32'h8000_0030, 4'd6, 6'd9, 1'b0, 6'd0, 1'b1, 6'd38);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd9;
    #1;
    tb_check1("wakeup does not enable same-cycle dispatch issue",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3B-GREEN] dispatch absorbed full wakeup issues next cycle",
              issue0_valid, 1'b1);
    tb_check32("absorbed wakeup issue pc", issue0_pc, 32'h8000_0030);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after absorbed wakeup issue", empty, 1'b1);

    // ===== S6 访存程序序:store 队头先行,younger load 被阻塞;store 不上 issue1 =====
    set_dispatch0(32'h8000_0040, 4'd7, 6'd1, 1'b1, 6'd2, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_STORE_BIT] = 1'b1;
    set_dispatch1(32'h8000_0044, 4'd8, 6'd3, 1'b1, 6'd0, 1'b1, 6'd54);
    dispatch1_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("oldest store issues", issue0_valid, 1'b1);
    tb_check32("oldest store pc", issue0_pc, 32'h8000_0040);
    tb_check1("younger load blocked by older store", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("load remains queued", {28'b0, count}, 32'd1);
    tb_check1("load released after store", issue0_valid, 1'b1);
    tb_check32("released load pc", issue0_pc, 32'h8000_0044);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after store-load order", empty, 1'b1);

    // ===== T3S 年龄反例：younger LR 不得越过未 ready 的 older load =====
    // 单槽 reservation 若先捕获 younger LR，LR 等 ROB head 与 older load 等
    // raw lane0 会形成自等待；因此 memory uop 之间必须保持程序序。
    set_dispatch0(32'h8000_0048, 4'd9,
                  6'd20, 1'b0, 6'd0, 1'b1, 6'd55);
    dispatch0_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    dispatch0_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
    dispatch0_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
    set_dispatch1(32'h8000_004c, 4'd10,
                  6'd0, 1'b1, 6'd0, 1'b1, 6'd56);
    dispatch1_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    dispatch1_ctrl[`CTRL_AMO_BIT] = 1'b1;
    dispatch1_ctrl[`CTRL_AMO_LR_BIT] = 1'b1;
    dispatch1_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
    dispatch1_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3S load-LR pair resident", {28'b0, count}, 32'd2);
    tb_check1("T3S younger LR blocked behind unready load",
              issue0_valid, 1'b0);
    tb_check1("T3S memory pair never reaches lane1", issue1_valid, 1'b0);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd20;
    #1;
    tb_check1("T3S wake is sticky-only in N", issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3S older load releases first", issue0_valid, 1'b1);
    tb_check32("T3S older load identity", issue0_pc, 32'h8000_0048);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3S younger LR remains after older pop",
               {28'b0, count}, 32'd1);
    tb_check1("T3S younger LR releases second", issue0_valid, 1'b1);
    tb_check32("T3S younger LR identity", issue0_pc, 32'h8000_004c);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3S ordered memory pair drains", empty, 1'b1);

    // ===== T3T 年龄反例：memory 不越过未 ready 的 older non-memory =====
    set_dispatch0(32'h8000_0140, 4'd11,
                  6'd21, 1'b0, 6'd0, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
    dispatch0_ctrl[`CTRL_RD_EN_BIT] = 1'b0;
    dispatch0_ctrl[`CTRL_NEED_WB_BIT] = 1'b0;
    set_dispatch1(32'h8000_0144, 4'd12,
                  6'd0, 1'b1, 6'd0, 1'b1, 6'd57);
    dispatch1_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    dispatch1_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
    dispatch1_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3T branch-load pair resident", {28'b0, count}, 32'd2);
    tb_check1("T3T younger load blocked behind branch",
              issue0_valid, 1'b0);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd21;
    #1;
    tb_check1("T3T branch wake remains sticky-only in N",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3T older branch releases first",
               issue0_pc, 32'h8000_0140);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("T3T younger load releases second",
               issue0_pc, 32'h8000_0144);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("T3T branch-load pair drains", empty, 1'b1);

    // ===== S7 issue_mem_block 压制 mem 类寄存项 =====
    set_dispatch0(32'h8000_0050, 4'd9, 6'd1, 1'b1, 6'd2, 1'b1, 6'd42);
    dispatch0_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    issue_mem_block = 1'b1;
    #1;
    tb_check1("mem block gates queued load", issue0_valid, 1'b0);
    issue_mem_block = 1'b0;
    #1;
    tb_check1("mem unblock releases load", issue0_valid, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after mem block scenario", empty, 1'b1);

    // ===== S8 反压非承诺:issue_ready=0 时 valid 保持、项不丢,ready 恢复即发射 =====
    issue0_ready = 1'b0;
    set_dispatch0(32'h8000_0060, 4'd10, 6'd1, 1'b1, 6'd2, 1'b1, 6'd48);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("backpressure holds valid", issue0_valid, 1'b1);
    tb_check32("backpressure keeps entry", {28'b0, count}, 32'd1);
    `TB_TICK(clk);
    #1;
    tb_check32("no fire under backpressure", {28'b0, count}, 32'd1);
    issue0_ready = 1'b1;
    `TB_TICK(clk);
    #1;
    tb_check1("entry drains after ready", empty, 1'b1);
    $display("[R3P2-STALL] IQ valid held under ready=0 and drained after release PASS");

    // ===== T3P：lane1 跳过复杂 load，选择更年轻 simple-ALU；load 随后晋升 lane0 =====
    issue0_ready = 1'b0;
    issue1_ready = 1'b0;
    set_dispatch0(32'h8000_0070, 4'd11, 6'd1, 1'b1, 6'd2, 1'b1, 6'd43);
    dispatch0_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    set_dispatch1(32'h8000_0074, 4'd12, 6'd3, 1'b1, 6'd4, 1'b1, 6'd44);
    dispatch1_ctrl[`CTRL_LOAD_BIT] = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    set_dispatch0(32'h8000_0078, 4'd13, 6'd5, 1'b1, 6'd6, 1'b1, 6'd45);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("dual load setup count", {28'b0, count}, 32'd3);
    issue0_ready = 1'b1;
    issue1_ready = 1'b1;
    #1;
    tb_check1("T3P oldest load owns lane0", issue0_valid, 1'b1);
    tb_check1("T3P younger simple ALU owns lane1", issue1_valid, 1'b1);
    tb_check32("T3P lane0 oldest load", issue0_pc, 32'h8000_0070);
    tb_check32("T3P lane1 skips second load", issue1_pc, 32'h8000_0078);
    tb_check1("T3P lane1 payload is non-memory",
              issue1_ctrl[`CTRL_LOAD_BIT] || issue1_ctrl[`CTRL_STORE_BIT],
              1'b0);
    `TB_TICK(clk);
    #1;
    tb_check32("T3P skipped load remains", {28'b0, count}, 32'd1);
    tb_check32("T3P skipped load promotes lane0", issue0_pc, 32'h8000_0074);
    tb_check1("T3P promoted payload remains load",
              issue0_ctrl[`CTRL_LOAD_BIT], 1'b1);
    `TB_TICK(clk);
    #1;
    tb_check1("T3P promoted load drains", empty, 1'b1);

    // T3Q reviewer matrix: LOAD/MULDIV/BITMANIP/CSR/FENCE/AMO/residual
    // NEED_MEM/FP-store-sideband 全部必须 fail-closed，且不会阻断更年轻 simple。
    for (lane1_negative_i = 0; lane1_negative_i < 8;
         lane1_negative_i = lane1_negative_i + 1)
      run_lane1_negative_class(lane1_negative_i);

    for (lane1_negative_i = 0; lane1_negative_i < 9;
         lane1_negative_i = lane1_negative_i + 1)
      run_r3p2_fixed_class_case(lane1_negative_i);

    // ===== S10 乱序 select:ready 新项越过 unready 老项,但仍须先寄存(N+1) =====
    set_dispatch0(32'h8000_0080, 4'd14, 6'd20, 1'b0, 6'd0, 1'b1, 6'd50);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("unready entry queued", {28'b0, count}, 32'd1);
    tb_check1("unready entry blocks issue", issue0_valid, 1'b0);
    set_dispatch0(32'h8000_0084, 4'd15, 6'd1, 1'b1, 6'd2, 1'b1, 6'd51);
    #1;
    tb_check1("ready dispatch never issues same cycle", issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("both entries queued", {28'b0, count}, 32'd2);
    tb_check1("registered entry overtakes unready older", issue0_valid, 1'b1);
    tb_check32("overtaking issue pc", issue0_pc, 32'h8000_0084);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("unready entry preserved", {28'b0, count}, 32'd1);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd20;
    #1;
    tb_check1("preserved entry does not wake-select in N",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("preserved entry wakes in N+1", issue0_valid, 1'b1);
    tb_check32("preserved entry issue pc", issue0_pc, 32'h8000_0080);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("preserved entry drains", empty, 1'b1);

    // ===== S11 kill:压 issue、squash 更年轻后缀、幸存前缀吸收 full-only wakeup =====
    issue0_ready = 1'b0;
    issue1_ready = 1'b0;
    set_dispatch0(32'h8000_0090, 4'd1, 6'd21, 1'b0, 6'd0, 1'b1, 6'd52);
    set_dispatch1(32'h8000_0094, 4'd2, 6'd1, 1'b1, 6'd2, 1'b1, 6'd53);
    `TB_TICK(clk);
    clear_inputs();
    set_dispatch0(32'h8000_0098, 4'd3, 6'd3, 1'b1, 6'd4, 1'b1, 6'd55);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("kill setup count", {28'b0, count}, 32'd3);
    tb_check1("ready younger visible before kill", issue0_valid, 1'b1);
    issue0_ready = 1'b1;
    issue1_ready = 1'b1;
    kill_valid = 1'b1;
    kill_rob_idx = 4'd1;
    rob_head_idx = 4'd1;
    early_wakeup0_valid = 1'b1;
    early_wakeup0_pdest = 6'd21;
    #1;
    tb_check1("kill gates issue0", issue0_valid, 1'b0);
    tb_check1("kill gates issue1", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("kill squashes younger suffix", {28'b0, count}, 32'd1);
    tb_check1("[R3P2-KILL] survivor absorbed kill-cycle early wakeup",
              issue0_valid, 1'b1);
    tb_check32("survivor pc", issue0_pc, 32'h8000_0090);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after kill scenario", empty, 1'b1);
    $display("[R3P2-KILL] younger suffix removed, early-woken survivor fired PASS");

    // ===== S12 recover 冻结发射 =====
    set_dispatch0(32'h8000_00a0, 4'd4, 6'd1, 1'b1, 6'd2, 1'b1, 6'd56);
    `TB_TICK(clk);
    clear_inputs();
    recover_active = 1'b1;
    #1;
    tb_check1("recover freezes issue", issue0_valid, 1'b0);
    recover_active = 1'b0;
    #1;
    tb_check1("issue resumes after recover", issue0_valid, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after recover scenario", empty, 1'b1);

    // ===== S13 flush 清队 =====
    set_dispatch0(32'h8000_00b0, 4'd5, 6'd1, 1'b1, 6'd2, 1'b1, 6'd57);
    `TB_TICK(clk);
    clear_inputs();
    flush = 1'b1;
    early_wakeup0_valid = 1'b1;
    early_wakeup0_pdest = 6'd57;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("flush empties queue", empty, 1'b1);
    $display("[R3P2-FLUSH] flush dominates matching early wake and clears IQ PASS");

    // ===== T3D RED：FP store wakeup 只可落 sticky，禁止 N 拍直进 select =====
    reset_dut();
    set_dispatch0(32'h8000_00c0, 4'd6,
                  6'd1, 1'b1, 6'd2, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_STORE_BIT] = 1'b1;
    dispatch0_fp_st_src_en = 1'b1;
    dispatch0_fp_st_src_preg = 6'd23;
    dispatch0_fp_st_src_ready = 1'b0;
    #1;
    tb_check1("[T3D-RED] FP store dispatch ready", dispatch0_ready, 1'b1);
    tb_check1("[T3D-RED] FP store has no dispatch bypass",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("[T3D-RED] FP store resident count",
               {28'b0, count}, 32'd1);
    tb_check1("[T3D-RED] integer-ready FP store waits for FP source",
              issue0_valid, 1'b0);
    tb_check1("[T3D-RED] resident FP source starts not-ready",
              dut.fp_st_ready_q[0], 1'b0);

    // N 拍只脉冲跨域 fp_wake0；integer full wake 保持 0。
    fp_wake0_valid = 1'b1;
    fp_wake0_preg = 6'd23;
    #1;
    $display("[T3D-RED-OBS] N fp_wake0=%0b fp_preg=%0d int_full={%0b,%0b} issue={%0b,%0b} count=%0d sticky=%0b",
             fp_wake0_valid, fp_wake0_preg,
             wakeup0_valid, wakeup1_valid,
             issue0_valid, issue1_valid, count, dut.fp_st_ready_q[0]);
    tb_check1("[T3D-RED] N contains no integer full wake",
              wakeup0_valid || wakeup1_valid, 1'b0);
    tb_check1("[T3D-RED] FP wake must not issue in N",
              issue0_valid, 1'b0);
    tb_check32("[T3D-RED] FP store remains resident during N",
               {28'b0, count}, 32'd1);

    `TB_TICK(clk);
    clear_inputs();
    #1;
    $display("[T3D-RED-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d sticky=%0b fp_src={en=%0b,preg=%0d}",
             issue0_valid, issue1_valid, issue0_pc[31:0], count,
             dut.fp_st_ready_q[0], issue0_fp_st_src_en,
             issue0_fp_st_src_preg);
    tb_check32("[T3D-RED] N edge preserves resident",
               {28'b0, count}, 32'd1);
    tb_check1("[T3D-RED] N edge absorbs FP wake into sticky",
              dut.fp_st_ready_q[0], 1'b1);
    tb_check1("[T3D-RED] FP store issues in N+1",
              issue0_valid, 1'b1);
    tb_check32("[T3D-RED] N+1 FP store PC",
               issue0_pc, 32'h8000_00c0);
    tb_check1("[T3D-RED] N+1 keeps FP store source enable",
              issue0_fp_st_src_en, 1'b1);
    tb_check32("[T3D-RED] N+1 keeps FP store source preg",
               {26'b0, issue0_fp_st_src_preg}, 32'd23);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3D-RED] delayed FP store drains", empty, 1'b1);

    // ===== T3D kill-survivor：wake0 与 kill 同拍只能唤醒存活前缀 =====
    // 先同时放入等待 FP 数据的较老 store 与 ready 的较年轻 uop；kill 拍 issue
    // 必须全压住，但较老 store 要在该沿吸收 wake0，下一拍独自恢复发射。
    issue0_ready = 1'b0;
    issue1_ready = 1'b0;
    set_dispatch0(32'h8000_00c8, 4'd8,
                  6'd5, 1'b1, 6'd6, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_STORE_BIT] = 1'b1;
    dispatch0_fp_st_src_en = 1'b1;
    dispatch0_fp_st_src_preg = 6'd25;
    dispatch0_fp_st_src_ready = 1'b0;
    set_dispatch1(32'h8000_00cc, 4'd9,
                  6'd7, 1'b1, 6'd8, 1'b1, 6'd58);
    #1;
    tb_check1("[T3D-KILL] survivor store dispatch ready",
              dispatch0_ready, 1'b1);
    tb_check1("[T3D-KILL] younger uop dispatch ready",
              dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("[T3D-KILL] setup keeps two residents",
               {28'b0, count}, 32'd2);
    tb_check1("[T3D-KILL] survivor source starts sticky-low",
              dut.fp_st_ready_q[0], 1'b0);

    issue0_ready = 1'b1;
    issue1_ready = 1'b1;
    kill_valid = 1'b1;
    kill_rob_idx = 4'd8;
    rob_head_idx = 4'd8;
    fp_wake0_valid = 1'b1;
    fp_wake0_preg = 6'd25;
    #1;
    $display("[T3D-KILL-OBS] N kill=%0b/%0d wake0=%0b/%0d issue={%0b,%0b} count=%0d survivor={valid=%0b,sticky=%0b}",
             kill_valid, kill_rob_idx, fp_wake0_valid, fp_wake0_preg,
             issue0_valid, issue1_valid, count,
             dut.valid_q[0], dut.fp_st_ready_q[0]);
    tb_check1("[T3D-KILL] kill N gates issue0", issue0_valid, 1'b0);
    tb_check1("[T3D-KILL] kill N gates issue1", issue1_valid, 1'b0);
    tb_check1("[T3D-KILL] survivor remains sticky-low before N edge",
              dut.fp_st_ready_q[0], 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    $display("[T3D-KILL-OBS] N+1 issue={%0b,%0b} pc=0x%08x count=%0d survivor={valid=%0b,sticky=%0b}",
             issue0_valid, issue1_valid, issue0_pc[31:0], count,
             dut.valid_q[0], dut.fp_st_ready_q[0]);
    tb_check32("[T3D-KILL] younger suffix squashed",
               {28'b0, count}, 32'd1);
    tb_check1("[T3D-KILL] survivor remains resident",
              dut.valid_q[0], 1'b1);
    tb_check1("[T3D-KILL] N edge absorbs wake0 into survivor sticky",
              dut.fp_st_ready_q[0], 1'b1);
    tb_check1("[T3D-KILL] survivor issues in N+1", issue0_valid, 1'b1);
    tb_check32("[T3D-KILL] survivor issue PC",
               issue0_pc, 32'h8000_00c8);
    tb_check1("[T3D-KILL] survivor keeps FP source enable",
              issue0_fp_st_src_en, 1'b1);
    tb_check32("[T3D-KILL] survivor keeps FP source preg",
               {26'b0, issue0_fp_st_src_preg}, 32'd25);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3D-KILL] survivor drains after delayed issue", empty, 1'b1);

    // ===== T3H RED：fp_wake1(load WB)也只可落 sticky，N+1 才 select =====
    set_dispatch0(32'h8000_00c4, 4'd7,
                  6'd3, 1'b1, 6'd4, 1'b1, 6'd0);
    dispatch0_ctrl[`CTRL_STORE_BIT] = 1'b1;
    dispatch0_fp_st_src_en = 1'b1;
    dispatch0_fp_st_src_preg = 6'd24;
    dispatch0_fp_st_src_ready = 1'b0;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("[T3D-GREEN] load-WB FP store resident count",
               {28'b0, count}, 32'd1);
    tb_check1("[T3D-GREEN] load-WB FP store initially waits",
              issue0_valid, 1'b0);
    fp_wake1_valid = 1'b1;
    fp_wake1_preg = 6'd24;
    #1;
    $display("[T3H-RED-OBS] N fp_wake1=%0b fp_preg=%0d issue={%0b,%0b} pc=0x%08x sticky=%0b",
             fp_wake1_valid, fp_wake1_preg,
             issue0_valid, issue1_valid, issue0_pc[31:0],
             dut.fp_st_ready_q[0]);
    tb_check1("[T3H-RED] load-WB FP wake must not issue in N",
              issue0_valid, 1'b0);
    tb_check1("[T3H-RED] load-WB sticky remains low before N edge",
              dut.fp_st_ready_q[0], 1'b0);
    tb_check32("[T3H-RED] load-WB FP store remains resident in N",
               {28'b0, count}, 32'd1);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    $display("[T3H-RED-OBS] N+1 issue={%0b,%0b} pc=0x%08x sticky=%0b count=%0d",
             issue0_valid, issue1_valid, issue0_pc[31:0],
             dut.fp_st_ready_q[0], count);
    tb_check1("[T3H-RED] load-WB sticky set at N edge",
              dut.fp_st_ready_q[0], 1'b1);
    tb_check1("[T3H-RED] load-WB FP store issues in N+1",
              issue0_valid, 1'b1);
    tb_check32("[T3H-RED] load-WB FP wake issue PC",
               issue0_pc, 32'h8000_00c4);
    tb_check1("[T3H-RED] load-WB keeps FP source enable",
              issue0_fp_st_src_en, 1'b1);
    tb_check32("[T3H-RED] load-WB keeps FP source preg",
               {26'b0, issue0_fp_st_src_preg}, 32'd24);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("[T3H-RED] delayed load-WB FP store drains", empty, 1'b1);

    // ===== T3H dispatch/wake collision：IQ 自身必须吸收唯一 FP 广播 =====
    // 集成查询面会给 ready 前视，但队列不能把正确性隐式绑定到上游实现。
    // 四象限覆盖两个 dispatch lane、两个 wake lane；preg0 是真 FPR，必须命中。
    run_fp_dispatch_wake_collision(1'b0, 1'b0, 6'd0,
                                   32'h8000_00d0, 4'd10);
    run_fp_dispatch_wake_collision(1'b0, 1'b1, 6'd26,
                                   32'h8000_00d4, 4'd11);
    run_fp_dispatch_wake_collision(1'b1, 1'b0, 6'd27,
                                   32'h8000_00d8, 4'd12);
    run_fp_dispatch_wake_collision(1'b1, 1'b1, 6'd0,
                                   32'h8000_00dc, 4'd13);

    // R3 RED->GREEN pair matrix: branch/JAL/JALR/load/store, both program
    // orders.  A passing result requires two simultaneous terminal fires;
    // serial promotion is not accepted as dual issue.
    for (lane1_negative_i = 0; lane1_negative_i < 6;
         lane1_negative_i = lane1_negative_i + 1) begin
      run_r3_capability_pair(lane1_negative_i, 1'b0);
      run_r3_capability_pair(lane1_negative_i, 1'b1);
    end

    run_r3p1_swapped_ready_case(2'b00);
    run_r3p1_swapped_ready_case(2'b01);
    run_r3p1_swapped_ready_case(2'b10);
    run_r3p1_swapped_ready_case(2'b11);
    run_r3p1_registered_owner_sole_alu;
    run_v8f_producer_id_carrier;

`ifdef R3P3_PACKED_HOLE_NEGATIVE
    // Reachable design state must never contain a hole.  This negative probe
    // deliberately deposits only idx1 as a ready memory uop: combinational
    // outputs must fail closed before PACKED-AGE reports the violation.
    clear_inputs();
    dut.valid_q[0] = 1'b0;
    dut.valid_q[1] = 1'b1;
    dut.src1_ready_q[1] = 1'b1;
    dut.src2_ready_q[1] = 1'b1;
    dut.fp_st_en_q[1] = 1'b0;
    dut.alu_terminal_capable_q[1] = 1'b0;
    dut.ctrl_q[1][`CTRL_LOAD_BIT] = 1'b1;
    dut.ctrl_q[1][`CTRL_STORE_BIT] = 1'b0;
    dut.ctrl_q[1][`CTRL_AMO_BIT] = 1'b0;
    #1;
    tb_check1("[R3P3-HOLE-QUIET] issue0 suppressed", issue0_valid, 1'b0);
    tb_check1("[R3P3-HOLE-QUIET] issue1 suppressed", issue1_valid, 1'b0);
    tb_check1("[R3P3-HOLE-QUIET] eligible suppressed",
              |dut.select_eligible_w, 1'b0);
    $display("[R3P3-HOLE-QUIET] outputs quiet before assertion edge");
    `TB_TICK(clk);
    #1;
    $display("[R3P3-PACKED-HOLE-NEGATIVE-DONE] completed one assertion edge");
    $finish_and_return(0);
`else
    tb_finish("tb_ooo_int_issue_queue");
`endif
  end
endmodule
