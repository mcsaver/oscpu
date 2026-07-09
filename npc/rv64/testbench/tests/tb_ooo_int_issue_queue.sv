`include "define.v"

// tb_ooo_int_issue_queue —— P5 刀 B(2026-07-09)后的 IQ 契约:
// 1. 【N+1 发射口径】dispatch 项当拍只写入阵列,当拍 issue*_valid 不得由 dispatch 活值拉高
//    (dispatch→issue 同拍 bypass 已整体删除);次拍起才可被 select 发射。
// 2. 【wakeup 直通保留】寄存项的同拍 wakeup→select 直通仍然有效(唤醒 CAM 非 bypass);
//    dispatch 当拍撞上匹配 wakeup 时,写入阵列的 ready 位吸收该唤醒(IQ-I2 无漏唤醒)。
// 3. select 唯一真源=已寄存 valid_q 项,由 RTL 内 IQ-NO-BYPASS 立即断言看护
//    (本 TB 带 -DOOO_ASSERT 编译,断言命中会打印 [IQ-NO-BYPASS])。
// 4. kill/recover/flush 语义不变:kill 拍压 issue、squash 更年轻后缀、幸存前缀同拍吸收 wakeup。
// 断言与检查不可弱化;负测试(临时保留一条 bypass 臂使断言 fire)证据存
// .github/task-runs/2026-07-09-p5-first-batch/。
module tb_ooo_int_issue_queue;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam ENTRY_COUNT_W = 4;

  reg clk;
  reg rst;
  reg flush;
  reg issue_mem_block;
  reg dispatch0_valid;
  wire dispatch0_ready;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`INST_W-1:0] dispatch0_inst;
  reg [`CTRL_BUS_W-1:0] dispatch0_ctrl;
  reg [ROB_INDEX_W-1:0] dispatch0_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg;
  reg dispatch0_src1_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg;
  reg dispatch0_src2_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_pdest;
  reg [`XLEN-1:0] dispatch0_imm;
  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  reg [`CTRL_BUS_W-1:0] dispatch1_ctrl;
  reg dispatch1_optional;
  reg [ROB_INDEX_W-1:0] dispatch1_rob_idx;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg;
  reg dispatch1_src1_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg;
  reg dispatch1_src2_ready;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_pdest;
  reg [`XLEN-1:0] dispatch1_imm;
  reg wakeup0_valid;
  reg [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
  reg wakeup1_valid;
  reg [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
  wire issue0_valid;
  reg issue0_ready;
  wire [`XLEN-1:0] issue0_pc;
  wire [`XLEN-1:0] issue0_next_pc;
  wire [`INST_W-1:0] issue0_inst;
  wire [`CTRL_BUS_W-1:0] issue0_ctrl;
  wire [ROB_INDEX_W-1:0] issue0_rob_idx;
  wire [PHY_REG_ADDR_W-1:0] issue0_src1_preg;
  wire [PHY_REG_ADDR_W-1:0] issue0_src2_preg;
  wire [PHY_REG_ADDR_W-1:0] issue0_pdest;
  wire [`XLEN-1:0] issue0_imm;
  wire issue1_valid;
  reg issue1_ready;
  wire [`XLEN-1:0] issue1_pc;
  wire [`XLEN-1:0] issue1_next_pc;
  wire [`INST_W-1:0] issue1_inst;
  wire [`CTRL_BUS_W-1:0] issue1_ctrl;
  wire [ROB_INDEX_W-1:0] issue1_rob_idx;
  wire [PHY_REG_ADDR_W-1:0] issue1_src1_preg;
  wire [PHY_REG_ADDR_W-1:0] issue1_src2_preg;
  wire [PHY_REG_ADDR_W-1:0] issue1_pdest;
  wire [`XLEN-1:0] issue1_imm;
  wire [ENTRY_COUNT_W-1:0] count;
  wire empty;
  wire full;
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  reg [ROB_INDEX_W-1:0] rob_head_idx;
  reg recover_active;

  OooIntIssueQueue dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .issue_mem_block_i(issue_mem_block),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i('0),
    .dispatch0_bht_idx_i('0),
    .dispatch0_pred_taken_i(1'b0),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_ctrl_i(dispatch0_ctrl),
    .dispatch0_rob_idx_i(dispatch0_rob_idx),
    .dispatch0_src1_preg_i(dispatch0_src1_preg),
    .dispatch0_src1_ready_i(dispatch0_src1_ready),
    .dispatch0_src2_preg_i(dispatch0_src2_preg),
    .dispatch0_src2_ready_i(dispatch0_src2_ready),
    .dispatch0_pdest_i(dispatch0_pdest),
    .dispatch0_fp_pdest_i(1'b0),
    .dispatch0_fp_st_src_en_i(1'b0),
    .dispatch0_fp_st_src_preg_i('0),
    .dispatch0_fp_st_src_ready_i(1'b1),
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
    .dispatch1_rob_idx_i(dispatch1_rob_idx),
    .dispatch1_src1_preg_i(dispatch1_src1_preg),
    .dispatch1_src1_ready_i(dispatch1_src1_ready),
    .dispatch1_src2_preg_i(dispatch1_src2_preg),
    .dispatch1_src2_ready_i(dispatch1_src2_ready),
    .dispatch1_pdest_i(dispatch1_pdest),
    .dispatch1_fp_pdest_i(1'b0),
    .dispatch1_fp_st_src_en_i(1'b0),
    .dispatch1_fp_st_src_preg_i('0),
    .dispatch1_fp_st_src_ready_i(1'b1),
    .dispatch1_imm_i(dispatch1_imm),
    .wakeup0_valid_i(wakeup0_valid),
    .wakeup0_pdest_i(wakeup0_pdest),
    .wakeup1_valid_i(wakeup1_valid),
    .wakeup1_pdest_i(wakeup1_pdest),
    .fp_wake0_valid_i(1'b0),
    .fp_wake0_preg_i('0),
    .fp_wake1_valid_i(1'b0),
    .fp_wake1_preg_i('0),
    .issue0_valid_o(issue0_valid),
    .issue0_ready_i(issue0_ready),
    .issue0_pc_o(issue0_pc),
    .issue0_next_pc_o(issue0_next_pc),
    .issue0_inst_o(issue0_inst),
    .issue0_ctrl_o(issue0_ctrl),
    .issue0_rob_idx_o(issue0_rob_idx),
    .issue0_src1_preg_o(issue0_src1_preg),
    .issue0_src2_preg_o(issue0_src2_preg),
    .issue0_pdest_o(issue0_pdest),
    .issue0_imm_o(issue0_imm),
    .issue1_valid_o(issue1_valid),
    .issue1_ready_i(issue1_ready),
    .issue1_pc_o(issue1_pc),
    .issue1_next_pc_o(issue1_next_pc),
    .issue1_inst_o(issue1_inst),
    .issue1_ctrl_o(issue1_ctrl),
    .issue1_rob_idx_o(issue1_rob_idx),
    .issue1_src1_preg_o(issue1_src1_preg),
    .issue1_src2_preg_o(issue1_src2_preg),
    .issue1_pdest_o(issue1_pdest),
    .issue1_imm_o(issue1_imm),
    .count_o(count),
    .empty_o(empty),
    .full_o(full),
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
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
      dispatch0_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch0_rob_idx = 4'd0;
      dispatch0_src1_preg = 6'd0;
      dispatch0_src1_ready = 1'b0;
      dispatch0_src2_preg = 6'd0;
      dispatch0_src2_ready = 1'b0;
      dispatch0_pdest = 6'd0;
      dispatch0_imm = 32'h0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_inst = 32'h0;
      dispatch1_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch1_optional = 1'b0;
      dispatch1_rob_idx = 4'd0;
      dispatch1_src1_preg = 6'd0;
      dispatch1_src1_ready = 1'b0;
      dispatch1_src2_preg = 6'd0;
      dispatch1_src2_ready = 1'b0;
      dispatch1_pdest = 6'd0;
      dispatch1_imm = 32'h0;
      wakeup0_valid = 1'b0;
      wakeup0_pdest = 6'd0;
      wakeup1_valid = 1'b0;
      wakeup1_pdest = 6'd0;
      kill_valid = 1'b0;
      kill_rob_idx = 4'd0;
      rob_head_idx = 4'd0;
      recover_active = 1'b0;
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
      dispatch0_ctrl = {{(`CTRL_BUS_W-1){1'b0}}, 1'b1};
      dispatch0_rob_idx = rob_idx;
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
      dispatch1_ctrl = {{(`CTRL_BUS_W-1){1'b0}}, 1'b1};
      dispatch1_rob_idx = rob_idx;
      dispatch1_src1_preg = src1;
      dispatch1_src1_ready = src1_ready;
      dispatch1_src2_preg = src2;
      dispatch1_src2_ready = src2_ready;
      dispatch1_pdest = pdest;
      dispatch1_imm = pc + 32'h20;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();
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

    // ===== S4 依赖对:issue1 无同拍前递;寄存项 wakeup→select 直通保留 =====
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
    tb_check1("same-cycle wakeup selects queued entry", issue0_valid, 1'b1);
    tb_check32("wakeup issue pc", issue0_pc, 32'h8000_0024);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after wakeup issue", empty, 1'b1);

    // ===== S5 dispatch 撞同拍 wakeup:当拍不发射,写入吸收唤醒(IQ-I2 无漏唤醒) =====
    set_dispatch0(32'h8000_0030, 4'd6, 6'd9, 1'b0, 6'd0, 1'b1, 6'd38);
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd9;
    #1;
    tb_check1("wakeup does not enable same-cycle dispatch issue",
              issue0_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("absorbed wakeup issues next cycle", issue0_valid, 1'b1);
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

    // ===== S9 双 load 成对发射(issue1 可载 load,不可载 store) =====
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
    tb_check1("dual load issue0 valid", issue0_valid, 1'b1);
    tb_check1("dual load issue1 valid", issue1_valid, 1'b1);
    tb_check32("dual load issue0 oldest load", issue0_pc, 32'h8000_0070);
    tb_check32("dual load issue1 second load", issue1_pc, 32'h8000_0074);
    `TB_TICK(clk);
    #1;
    tb_check32("dual load leaves later alu", {28'b0, count}, 32'd1);
    tb_check32("dual load remaining pc", issue0_pc, 32'h8000_0078);
    `TB_TICK(clk);
    #1;
    tb_check1("dual load drains", empty, 1'b1);

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
    tb_check1("preserved entry wakes", issue0_valid, 1'b1);
    tb_check32("preserved entry issue pc", issue0_pc, 32'h8000_0080);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("preserved entry drains", empty, 1'b1);

    // ===== S11 kill:压 issue、squash 更年轻后缀、幸存前缀同拍吸收 wakeup =====
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
    wakeup0_valid = 1'b1;
    wakeup0_pdest = 6'd21;
    #1;
    tb_check1("kill gates issue0", issue0_valid, 1'b0);
    tb_check1("kill gates issue1", issue1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("kill squashes younger suffix", {28'b0, count}, 32'd1);
    tb_check1("survivor absorbed kill-cycle wakeup", issue0_valid, 1'b1);
    tb_check32("survivor pc", issue0_pc, 32'h8000_0090);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("empty after kill scenario", empty, 1'b1);

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
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("flush empties queue", empty, 1'b1);

    tb_finish("tb_ooo_int_issue_queue");
  end
endmodule
