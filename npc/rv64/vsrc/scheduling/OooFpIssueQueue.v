`include "define.v"

// 【B-FP 簇】FP 发射队列(spec ooo-fp-cluster-implementation-plan.md §7)。
// 8 项单发射 oldest-ready。承接纯 FP 算术与 FMV/FCVT 跨域指令(FP load/store 走
// 整数 IQ mem 通道, 不进本队列)。三 FP 源(fs1/fs2/fs3)监听 FP wakeup(算术 wb +
// load wb 双口), 一 GPR 源(FMV.W.X/FCVT.from-int)监听整数 formal wakeup 双口。
// T3F/T3H：integer/FP wake 都只在沿上落 sticky，不允许 resident entry
// 同拍 select；这与两类 PRF 只读已落账 regs_q 的 data 边界成对。
// squash 语义与 OooIntIssueQueue 对齐: flush 全清; mispredict kill 拍清掉比
// kill_rob_idx 更年轻(ROB 环形 age 更大)的 entry, recover 期冻结发射。
// 无 dispatch-bypass/mem-order 等整数 IQ 脚手架——FP 簇不需要。
module OooFpIssueQueue #(
  parameter ENTRY_INDEX_W = 3,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W
) (
  input clk,
  input rst,
  input flush_i,

  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,
  input recover_active_i,

  input dispatch_valid_i,
  output dispatch_ready_o,
  input [ROB_INDEX_W-1:0] dispatch_rob_idx_i,
  input [`INST_W-1:0] dispatch_inst_i,
  input dispatch_double_i,
  input [PHY_REG_ADDR_W-1:0] dispatch_pdest_i,
  input dispatch_dst_gpr_i,
  input dispatch_dst_en_i,
  input dispatch_fs1_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch_fs1_preg_i,
  input dispatch_fs1_ready_i,
  input dispatch_fs2_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch_fs2_preg_i,
  input dispatch_fs2_ready_i,
  input dispatch_fs3_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch_fs3_preg_i,
  input dispatch_fs3_ready_i,
  input dispatch_gpr_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch_gpr_preg_i,
  input dispatch_gpr_ready_i,

  // lane1(双发第二条 FP 算术; 程序序更年轻)
  input dispatch1_valid_i,
  output dispatch1_ready_o,
  input [ROB_INDEX_W-1:0] dispatch1_rob_idx_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input dispatch1_double_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_pdest_i,
  input dispatch1_dst_gpr_i,
  input dispatch1_dst_en_i,
  input dispatch1_fs1_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_fs1_preg_i,
  input dispatch1_fs1_ready_i,
  input dispatch1_fs2_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_fs2_preg_i,
  input dispatch1_fs2_ready_i,
  input dispatch1_fs3_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_fs3_preg_i,
  input dispatch1_fs3_ready_i,
  input dispatch1_gpr_en_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_gpr_preg_i,
  input dispatch1_gpr_ready_i,

  input fp_wake0_valid_i,
  input [PHY_REG_ADDR_W-1:0] fp_wake0_preg_i,
  input fp_wake1_valid_i,
  input [PHY_REG_ADDR_W-1:0] fp_wake1_preg_i,
  input int_wake0_valid_i,
  input [PHY_REG_ADDR_W-1:0] int_wake0_preg_i,
  input int_wake1_valid_i,
  input [PHY_REG_ADDR_W-1:0] int_wake1_preg_i,

  output issue_valid_o,
  input issue_ready_i,
  output [ROB_INDEX_W-1:0] issue_rob_idx_o,
  output [`INST_W-1:0] issue_inst_o,
  output issue_double_o,
  output [PHY_REG_ADDR_W-1:0] issue_pdest_o,
  output issue_dst_gpr_o,
  output issue_dst_en_o,
  output [PHY_REG_ADDR_W-1:0] issue_fs1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue_fs2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue_fs3_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue_gpr_preg_o,

  output [ENTRY_INDEX_W:0] count_o
);

  localparam ENTRY_COUNT = (1 << ENTRY_INDEX_W);

  reg valid_q [0:ENTRY_COUNT-1];
  reg [ROB_INDEX_W-1:0] rob_idx_q [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst_q [0:ENTRY_COUNT-1];
  reg double_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] pdest_q [0:ENTRY_COUNT-1];
  reg dst_gpr_q [0:ENTRY_COUNT-1];
  reg dst_en_q [0:ENTRY_COUNT-1];
  reg fs1_en_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] fs1_preg_q [0:ENTRY_COUNT-1];
  reg fs1_ready_q [0:ENTRY_COUNT-1];
  reg fs2_en_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] fs2_preg_q [0:ENTRY_COUNT-1];
  reg fs2_ready_q [0:ENTRY_COUNT-1];
  reg fs3_en_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] fs3_preg_q [0:ENTRY_COUNT-1];
  reg fs3_ready_q [0:ENTRY_COUNT-1];
  reg gpr_en_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] gpr_preg_q [0:ENTRY_COUNT-1];
  reg gpr_ready_q [0:ENTRY_COUNT-1];

  reg [ENTRY_INDEX_W:0] count_q;

  integer i;

  function [ROB_INDEX_W-1:0] rob_age;
    input [ROB_INDEX_W-1:0] idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      rob_age = idx - head;
    end
  endfunction

  // dispatch 拍同拍 wakeup 前视: 入队写与存量唤醒同 always(后写胜), 不捕获
  // 会把同拍广播覆盖成 not-ready → 错过唯一唤醒, entry 永睡(fcvt.d.w 等
  // GPR 源撞 li wb 拍即死锁)。
  wire d0_fs1_wake_w =
      (fp_wake0_valid_i && (fp_wake0_preg_i == dispatch_fs1_preg_i)) ||
      (fp_wake1_valid_i && (fp_wake1_preg_i == dispatch_fs1_preg_i));
  wire d0_fs2_wake_w =
      (fp_wake0_valid_i && (fp_wake0_preg_i == dispatch_fs2_preg_i)) ||
      (fp_wake1_valid_i && (fp_wake1_preg_i == dispatch_fs2_preg_i));
  wire d0_fs3_wake_w =
      (fp_wake0_valid_i && (fp_wake0_preg_i == dispatch_fs3_preg_i)) ||
      (fp_wake1_valid_i && (fp_wake1_preg_i == dispatch_fs3_preg_i));
  wire d0_gpr_wake_w =
      (int_wake0_valid_i && (int_wake0_preg_i == dispatch_gpr_preg_i)) ||
      (int_wake1_valid_i && (int_wake1_preg_i == dispatch_gpr_preg_i));
  wire d1_fs1_wake_w =
      (fp_wake0_valid_i && (fp_wake0_preg_i == dispatch1_fs1_preg_i)) ||
      (fp_wake1_valid_i && (fp_wake1_preg_i == dispatch1_fs1_preg_i));
  wire d1_fs2_wake_w =
      (fp_wake0_valid_i && (fp_wake0_preg_i == dispatch1_fs2_preg_i)) ||
      (fp_wake1_valid_i && (fp_wake1_preg_i == dispatch1_fs2_preg_i));
  wire d1_fs3_wake_w =
      (fp_wake0_valid_i && (fp_wake0_preg_i == dispatch1_fs3_preg_i)) ||
      (fp_wake1_valid_i && (fp_wake1_preg_i == dispatch1_fs3_preg_i));
  wire d1_gpr_wake_w =
      (int_wake0_valid_i && (int_wake0_preg_i == dispatch1_gpr_preg_i)) ||
      (int_wake1_valid_i && (int_wake1_preg_i == dispatch1_gpr_preg_i));

  reg [ENTRY_COUNT-1:0] entry_ready_r;
  always @(*) begin : ready_view_blk
    integer k;
    for (k = 0; k < ENTRY_COUNT; k = k + 1) begin
      entry_ready_r[k] = valid_q[k] &&
          (!fs1_en_q[k] || fs1_ready_q[k]) &&
          (!fs2_en_q[k] || fs2_ready_q[k]) &&
          (!fs3_en_q[k] || fs3_ready_q[k]) &&
          (!gpr_en_q[k] || gpr_ready_q[k]);
    end
  end

  // oldest-ready 选择(顺序扫描, 8 项组合)
  reg issue_found_r;
  reg [ENTRY_INDEX_W-1:0] issue_idx_r;
  always @(*) begin : oldest_select_blk
    integer k;
    issue_found_r = 1'b0;
    issue_idx_r = {ENTRY_INDEX_W{1'b0}};
    for (k = 0; k < ENTRY_COUNT; k = k + 1) begin
      if (entry_ready_r[k] &&
          (!issue_found_r ||
           (rob_age(rob_idx_q[k], rob_head_idx_i) <
            rob_age(rob_idx_q[issue_idx_r], rob_head_idx_i)))) begin
        issue_found_r = 1'b1;
        issue_idx_r = k[ENTRY_INDEX_W-1:0];
      end
    end
  end

  assign issue_valid_o = issue_found_r && !recover_active_i && !kill_valid_i &&
                         !flush_i;
  assign issue_rob_idx_o = rob_idx_q[issue_idx_r];
  assign issue_inst_o = inst_q[issue_idx_r];
  assign issue_double_o = double_q[issue_idx_r];
  assign issue_pdest_o = pdest_q[issue_idx_r];
  assign issue_dst_gpr_o = dst_gpr_q[issue_idx_r];
  assign issue_dst_en_o = dst_en_q[issue_idx_r];
  assign issue_fs1_preg_o = fs1_preg_q[issue_idx_r];
  assign issue_fs2_preg_o = fs2_preg_q[issue_idx_r];
  assign issue_fs3_preg_o = fs3_preg_q[issue_idx_r];
  assign issue_gpr_preg_o = gpr_preg_q[issue_idx_r];

  wire issue_fire_w = issue_valid_o && issue_ready_i;

  assign count_o = count_q;

  assign dispatch_ready_o =
      (count_q != ENTRY_COUNT[ENTRY_INDEX_W:0]) && !recover_active_i &&
      !kill_valid_i;
  assign dispatch1_ready_o =
      (count_q < (ENTRY_COUNT[ENTRY_INDEX_W:0] -
                  {{ENTRY_INDEX_W{1'b0}}, dispatch_valid_i})) &&
      !recover_active_i && !kill_valid_i;
  wire dispatch_fire_w = dispatch_valid_i && dispatch_ready_o && !flush_i;
  wire dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o && !flush_i;

  // 空闲槽选择(最低两个空位)
  reg [ENTRY_INDEX_W-1:0] alloc_idx_r;
  reg [ENTRY_INDEX_W-1:0] alloc1_idx_r;
  always @(*) begin : alloc_select_blk
    integer k;
    reg first_found_r;
    alloc_idx_r = {ENTRY_INDEX_W{1'b0}};
    alloc1_idx_r = {ENTRY_INDEX_W{1'b0}};
    first_found_r = 1'b0;
    for (k = ENTRY_COUNT - 1; k >= 0; k = k - 1) begin
      if (!valid_q[k]) begin
        alloc1_idx_r = alloc_idx_r;
        alloc_idx_r = k[ENTRY_INDEX_W-1:0];
        first_found_r = 1'b1;
      end
    end
    if (!first_found_r) begin
      alloc1_idx_r = {ENTRY_INDEX_W{1'b0}};
    end
  end

  // mispredict squash: 比 kill_rob_idx 更年轻者清除
  reg [ENTRY_COUNT-1:0] squash_r;
  reg [ENTRY_INDEX_W:0] squash_count_r;
  always @(*) begin : squash_blk
    integer k;
    squash_count_r = {(ENTRY_INDEX_W+1){1'b0}};
    for (k = 0; k < ENTRY_COUNT; k = k + 1) begin
      squash_r[k] = valid_q[k] && kill_valid_i &&
          (rob_age(rob_idx_q[k], rob_head_idx_i) >
           rob_age(kill_rob_idx_i, rob_head_idx_i));
      if (squash_r[k])
        squash_count_r = squash_count_r + {{ENTRY_INDEX_W{1'b0}}, 1'b1};
    end
  end

  always @(posedge clk) begin
    if (rst || flush_i) begin
      count_q <= {(ENTRY_INDEX_W+1){1'b0}};
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
        valid_q[i] <= 1'b0;
        rob_idx_q[i] <= {ROB_INDEX_W{1'b0}};
        inst_q[i] <= {`INST_W{1'b0}};
        double_q[i] <= 1'b0;
        pdest_q[i] <= {PHY_REG_ADDR_W{1'b0}};
        dst_gpr_q[i] <= 1'b0;
        dst_en_q[i] <= 1'b0;
        fs1_en_q[i] <= 1'b0;
        fs1_preg_q[i] <= {PHY_REG_ADDR_W{1'b0}};
        fs1_ready_q[i] <= 1'b0;
        fs2_en_q[i] <= 1'b0;
        fs2_preg_q[i] <= {PHY_REG_ADDR_W{1'b0}};
        fs2_ready_q[i] <= 1'b0;
        fs3_en_q[i] <= 1'b0;
        fs3_preg_q[i] <= {PHY_REG_ADDR_W{1'b0}};
        fs3_ready_q[i] <= 1'b0;
        gpr_en_q[i] <= 1'b0;
        gpr_preg_q[i] <= {PHY_REG_ADDR_W{1'b0}};
        gpr_ready_q[i] <= 1'b0;
      end
    end else begin
      // 唤醒时序落账：FP/GPR 源都只能在此处置 sticky，最早下一拍发射。
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
        if (valid_q[i]) begin
          if (fs1_en_q[i] &&
              ((fp_wake0_valid_i && (fp_wake0_preg_i == fs1_preg_q[i])) ||
               (fp_wake1_valid_i && (fp_wake1_preg_i == fs1_preg_q[i]))))
            fs1_ready_q[i] <= 1'b1;
          if (fs2_en_q[i] &&
              ((fp_wake0_valid_i && (fp_wake0_preg_i == fs2_preg_q[i])) ||
               (fp_wake1_valid_i && (fp_wake1_preg_i == fs2_preg_q[i]))))
            fs2_ready_q[i] <= 1'b1;
          if (fs3_en_q[i] &&
              ((fp_wake0_valid_i && (fp_wake0_preg_i == fs3_preg_q[i])) ||
               (fp_wake1_valid_i && (fp_wake1_preg_i == fs3_preg_q[i]))))
            fs3_ready_q[i] <= 1'b1;
          if (gpr_en_q[i] &&
              ((int_wake0_valid_i && (int_wake0_preg_i == gpr_preg_q[i])) ||
               (int_wake1_valid_i && (int_wake1_preg_i == gpr_preg_q[i]))))
            gpr_ready_q[i] <= 1'b1;
        end
      end

      if (issue_fire_w) begin
        valid_q[issue_idx_r] <= 1'b0;
      end

      if (dispatch1_fire_w) begin
        valid_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= 1'b1;
        rob_idx_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_rob_idx_i;
        inst_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_inst_i;
        double_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_double_i;
        pdest_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_pdest_i;
        dst_gpr_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_dst_gpr_i;
        dst_en_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_dst_en_i;
        fs1_en_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs1_en_i;
        fs1_preg_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs1_preg_i;
        fs1_ready_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs1_ready_i || d1_fs1_wake_w;
        fs2_en_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs2_en_i;
        fs2_preg_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs2_preg_i;
        fs2_ready_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs2_ready_i || d1_fs2_wake_w;
        fs3_en_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs3_en_i;
        fs3_preg_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs3_preg_i;
        fs3_ready_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_fs3_ready_i || d1_fs3_wake_w;
        gpr_en_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_gpr_en_i;
        gpr_preg_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_gpr_preg_i;
        gpr_ready_q[dispatch_fire_w ? alloc1_idx_r : alloc_idx_r] <= dispatch1_gpr_ready_i || d1_gpr_wake_w;
      end
      if (dispatch_fire_w) begin
        valid_q[alloc_idx_r] <= 1'b1;
        rob_idx_q[alloc_idx_r] <= dispatch_rob_idx_i;
        inst_q[alloc_idx_r] <= dispatch_inst_i;
        double_q[alloc_idx_r] <= dispatch_double_i;
        pdest_q[alloc_idx_r] <= dispatch_pdest_i;
        dst_gpr_q[alloc_idx_r] <= dispatch_dst_gpr_i;
        dst_en_q[alloc_idx_r] <= dispatch_dst_en_i;
        fs1_en_q[alloc_idx_r] <= dispatch_fs1_en_i;
        fs1_preg_q[alloc_idx_r] <= dispatch_fs1_preg_i;
        fs1_ready_q[alloc_idx_r] <= dispatch_fs1_ready_i || d0_fs1_wake_w;
        fs2_en_q[alloc_idx_r] <= dispatch_fs2_en_i;
        fs2_preg_q[alloc_idx_r] <= dispatch_fs2_preg_i;
        fs2_ready_q[alloc_idx_r] <= dispatch_fs2_ready_i || d0_fs2_wake_w;
        fs3_en_q[alloc_idx_r] <= dispatch_fs3_en_i;
        fs3_preg_q[alloc_idx_r] <= dispatch_fs3_preg_i;
        fs3_ready_q[alloc_idx_r] <= dispatch_fs3_ready_i || d0_fs3_wake_w;
        gpr_en_q[alloc_idx_r] <= dispatch_gpr_en_i;
        gpr_preg_q[alloc_idx_r] <= dispatch_gpr_preg_i;
        gpr_ready_q[alloc_idx_r] <= dispatch_gpr_ready_i || d0_gpr_wake_w;
      end

      if (kill_valid_i) begin
        for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
          if (squash_r[i]) begin
            valid_q[i] <= 1'b0;
          end
        end
        count_q <= count_q - squash_count_r -
                   {{ENTRY_INDEX_W{1'b0}}, issue_fire_w};
      end else begin
        count_q <= count_q +
                   {{ENTRY_INDEX_W{1'b0}}, dispatch_fire_w} +
                   {{ENTRY_INDEX_W{1'b0}}, dispatch1_fire_w} -
                   {{ENTRY_INDEX_W{1'b0}}, issue_fire_w};
      end
    end
  end

`ifdef OOO_ASSERT
  // T3F/T3H 硬边界：resident entry 的所有 source 都只能在 sticky ready
  // 已落账后发射，禁止恢复任一 formal-wake 同拍前视。
  always @(posedge clk) begin
    if (!rst && (issue_valid_o === 1'b1) &&
        (((fs1_en_q[issue_idx_r] === 1'b1) &&
          (fs1_ready_q[issue_idx_r] !== 1'b1)) ||
         ((fs2_en_q[issue_idx_r] === 1'b1) &&
          (fs2_ready_q[issue_idx_r] !== 1'b1)) ||
         ((fs3_en_q[issue_idx_r] === 1'b1) &&
          (fs3_ready_q[issue_idx_r] !== 1'b1)))) begin
      $error("[FP-IQ-FP-STICKY-ONLY] FP source issued before sticky ready");
    end
    if (!rst && (issue_valid_o === 1'b1) &&
        (gpr_en_q[issue_idx_r] === 1'b1) &&
        (gpr_ready_q[issue_idx_r] !== 1'b1)) begin
      $error("[FP-IQ-INT-STICKY-ONLY] GPR source issued before sticky ready");
    end
    if (!rst && (int_wake0_valid_i === 1'b1) &&
        (int_wake0_preg_i == {PHY_REG_ADDR_W{1'b0}})) begin
      $error("[FP-INT-WAKE-WRITE] lane0 formal wake targets p0");
    end
    if (!rst && (int_wake1_valid_i === 1'b1) &&
        (int_wake1_preg_i == {PHY_REG_ADDR_W{1'b0}})) begin
      $error("[FP-INT-WAKE-WRITE] lane1 formal wake targets p0");
    end
  end
`endif


endmodule
