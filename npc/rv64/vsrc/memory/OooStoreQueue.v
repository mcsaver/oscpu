`include "define.v"

// 【LSQ·Store Queue 组件】(spec: design/specs/ooo-lsq-implementation-plan.md Phase1/§3.5)
// 程序序环形 SQ: dispatch 拍按序 alloc(entry 序即年龄, 双发口), 发射拍按 rob_idx CAM
// 单拍回填 addr+data+strb(§3.5 首选: uop 不必携带 sq_idx; 双口覆盖同拍直入/入 buffer
// 两路), ROB 退休按 rob_idx CAM 置 committed(双退休口; 不假设退休者恰为 SQ 队头——
// 队头可能是更早已退休、尚未 drain 的 store), 队头 committed 且齐备的 entry 经 drain
// 口后台落存, fire 即释放。CAM 无命中的回填/退休标记被忽略(消费侧可宽判定: AMO/SC
// 未 alloc, 天然 miss)。
// squash 语义分两种(§3.5 推演: 全清未 committed 对 branch-kill 会错杀分支之前的在飞
// store):
//   - flush_all_i=1(trap): 清全部未 committed(trap 之前的 store 必已退休);
//   - flush_all_i=0(branch ROB-walk kill): 只清比 boundary(分支 rob_idx)年轻的
//     未 committed entry, 分支之前的在飞 store 保留。年龄以 ROB head 为基准环形距离
//     判定; 已退休 entry 恒 committed 存活, 不参与距离判定。
// 本模块只管数据结构与顺序不变量; 前递 CAM/发射决策替换属接线步。
module OooStoreQueue #(
  parameter ENTRY_COUNT_W = 2,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W
)(
  input clk,
  input rst,

  // squash(flush 拍的同拍 alloc 属 wrong-path, 一并丢弃; 同拍退休标记/drain 正常生效)
  input flush_valid_i,
  input flush_all_i,
  input [ROB_INDEX_W-1:0] flush_rob_head_i,
  input [ROB_INDEX_W-1:0] flush_boundary_rob_i,

  // dispatch 拍按程序序分配(双发; slot1 仅在 slot0 同拍 fire 时可 fire)
  input alloc0_valid_i,
  output alloc0_ready_o,
  input [ROB_INDEX_W-1:0] alloc0_rob_idx_i,
  input alloc1_valid_i,
  output alloc1_ready_o,
  input [ROB_INDEX_W-1:0] alloc1_rob_idx_i,

  // 发射拍回填(rob_idx CAM; addr/data/strb 单拍全填, 已填则忽略——misaligned 硬件
  // 拆笔/buffer 转发重复触发只记首笔; CAM miss 忽略)
  input fill0_valid_i,
  input [ROB_INDEX_W-1:0] fill0_rob_idx_i,
  input [`XLEN-1:0] fill0_addr_i,
  input [`XLEN-1:0] fill0_data_i,
  input [`STRB_W-1:0] fill0_strb_i,
  input fill1_valid_i,
  input [ROB_INDEX_W-1:0] fill1_rob_idx_i,
  input [`XLEN-1:0] fill1_addr_i,
  input [`XLEN-1:0] fill1_data_i,
  input [`STRB_W-1:0] fill1_strb_i,

  // ROB 退休标记(rob_idx CAM 匹配; 双退休口)
  input mark0_valid_i,
  input [ROB_INDEX_W-1:0] mark0_rob_idx_i,
  input mark1_valid_i,
  input [ROB_INDEX_W-1:0] mark1_rob_idx_i,

  // drain 口: 队头 committed 且 addr/data 齐备的 entry 供落存; fire 即释放
  output drain_valid_o,
  output [`XLEN-1:0] drain_addr_o,
  output [`XLEN-1:0] drain_data_o,
  output [`STRB_W-1:0] drain_strb_o,
  input drain_fire_i,

  // 前递/歧义消解查询面: 全 entry 平铺导出(消费者做 CAM); head 供程序序遍历
  // (前递取"最年轻的更老重叠"需按年龄序扫描)。
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_valid_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_addr_valid_o,
  output [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_addr_o,
  output [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_data_o,
  output [(1 << ENTRY_COUNT_W) * `STRB_W - 1:0] snoop_strb_o,
  output [(1 << ENTRY_COUNT_W) * ROB_INDEX_W - 1:0] snoop_rob_idx_o,
  output [(1 << ENTRY_COUNT_W)-1:0] snoop_committed_o,
  output [ENTRY_COUNT_W-1:0] snoop_head_o,
  output [ENTRY_COUNT_W:0] count_o
);

  localparam ENTRY_COUNT = (1 << ENTRY_COUNT_W);

  reg [ENTRY_COUNT_W-1:0] head_q;
  reg [ENTRY_COUNT_W-1:0] tail_q;
  reg [ENTRY_COUNT_W:0] count_q;
  reg valid_q [0:ENTRY_COUNT-1];
  reg committed_q [0:ENTRY_COUNT-1];
  reg addr_valid_q [0:ENTRY_COUNT-1];
  reg data_valid_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] addr_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] data_q [0:ENTRY_COUNT-1];
  reg [`STRB_W-1:0] strb_q [0:ENTRY_COUNT-1];
  reg [ROB_INDEX_W-1:0] rob_idx_q [0:ENTRY_COUNT-1];

  integer i;
`ifdef OOO_ASSERT
  integer assert_i;
`endif

  wire alloc0_fire_w = alloc0_valid_i && alloc0_ready_o && !flush_valid_i;
  wire alloc1_fire_w = alloc1_valid_i && alloc1_ready_o && alloc0_fire_w;
  wire drain_release_w = drain_fire_i && drain_valid_o;
  wire [ENTRY_COUNT_W-1:0] alloc0_idx_w = tail_q;
  wire [ENTRY_COUNT_W-1:0] alloc1_idx_w =
      tail_q + {{(ENTRY_COUNT_W-1){1'b0}}, 1'b1};

  // 回填 CAM(命中未填 entry 才写, 首笔保持)
  wire [ENTRY_COUNT-1:0] fill_hit0_w;
  wire [ENTRY_COUNT-1:0] fill_hit1_w;
  genvar gf;
  generate
    for (gf = 0; gf < ENTRY_COUNT; gf = gf + 1) begin : gen_fill
      assign fill_hit0_w[gf] =
          fill0_valid_i && valid_q[gf] && !addr_valid_q[gf] &&
          (rob_idx_q[gf] == fill0_rob_idx_i);
      assign fill_hit1_w[gf] =
          fill1_valid_i && valid_q[gf] && !addr_valid_q[gf] &&
          (rob_idx_q[gf] == fill1_rob_idx_i);
    end
  endgenerate

  // 退休标记 CAM(幂等; 命中含"本拍即将退休"供 flush 存活判定并用)
  wire [ENTRY_COUNT-1:0] mark_hit0_w;
  wire [ENTRY_COUNT-1:0] mark_hit1_w;
  genvar gm;
  generate
    for (gm = 0; gm < ENTRY_COUNT; gm = gm + 1) begin : gen_mark
      assign mark_hit0_w[gm] =
          mark0_valid_i && valid_q[gm] && (rob_idx_q[gm] == mark0_rob_idx_i);
      assign mark_hit1_w[gm] =
          mark1_valid_i && valid_q[gm] && (rob_idx_q[gm] == mark1_rob_idx_i);
    end
  endgenerate

  // flush 存活判定: committed(含本拍标记)恒存活; 未 committed 仅在非全清且
  // 不比 boundary 年轻(环形距离以 ROB head 为基准)时存活。
  function [ROB_INDEX_W-1:0] rob_dist;
    input [ROB_INDEX_W-1:0] idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      rob_dist = idx - head;
    end
  endfunction

  reg survive_r [0:ENTRY_COUNT-1];
  reg [ENTRY_COUNT_W:0] survive_count_r;
  always @(*) begin : survive_blk
    integer k;
    survive_count_r = {(ENTRY_COUNT_W+1){1'b0}};
    for (k = 0; k < ENTRY_COUNT; k = k + 1) begin
      survive_r[k] = valid_q[k] &&
          (committed_q[k] || mark_hit0_w[k] || mark_hit1_w[k] ||
           (!flush_all_i &&
            (rob_dist(rob_idx_q[k], flush_rob_head_i) <=
             rob_dist(flush_boundary_rob_i, flush_rob_head_i))));
      if (survive_r[k])
        survive_count_r = survive_count_r + {{ENTRY_COUNT_W{1'b0}}, 1'b1};
    end
  end

  wire head_valid_w = (count_q != {(ENTRY_COUNT_W+1){1'b0}});

  assign alloc0_ready_o = (count_q != ENTRY_COUNT[ENTRY_COUNT_W:0]);
  assign alloc1_ready_o =
      (count_q != ENTRY_COUNT[ENTRY_COUNT_W:0]) &&
      (count_q != ENTRY_COUNT[ENTRY_COUNT_W:0] - {{ENTRY_COUNT_W{1'b0}}, 1'b1});

  assign drain_valid_o =
      head_valid_w && valid_q[head_q] && committed_q[head_q] &&
      addr_valid_q[head_q] && data_valid_q[head_q];
  assign drain_addr_o = addr_q[head_q];
  assign drain_data_o = data_q[head_q];
  assign drain_strb_o = strb_q[head_q];
  assign count_o = count_q;

  genvar g;
  generate
    for (g = 0; g < ENTRY_COUNT; g = g + 1) begin : gen_snoop
      assign snoop_valid_o[g] = valid_q[g];
      assign snoop_addr_valid_o[g] = valid_q[g] && addr_valid_q[g];
      assign snoop_addr_o[g * `XLEN +: `XLEN] = addr_q[g];
      assign snoop_data_o[g * `XLEN +: `XLEN] = data_q[g];
      assign snoop_strb_o[g * `STRB_W +: `STRB_W] = strb_q[g];
      assign snoop_rob_idx_o[g * ROB_INDEX_W +: ROB_INDEX_W] = rob_idx_q[g];
      assign snoop_committed_o[g] = valid_q[g] && committed_q[g];
    end
  endgenerate
  assign snoop_head_o = head_q;

  always @(posedge clk) begin
    if (rst) begin
      head_q <= {ENTRY_COUNT_W{1'b0}};
      tail_q <= {ENTRY_COUNT_W{1'b0}};
      count_q <= {(ENTRY_COUNT_W+1){1'b0}};
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
        valid_q[i] <= 1'b0;
        committed_q[i] <= 1'b0;
        addr_valid_q[i] <= 1'b0;
        data_valid_q[i] <= 1'b0;
        addr_q[i] <= {`XLEN{1'b0}};
        data_q[i] <= {`XLEN{1'b0}};
        strb_q[i] <= {`STRB_W{1'b0}};
        rob_idx_q[i] <= {ROB_INDEX_W{1'b0}};
      end
    end else begin
      // 乱序回填(CAM; flush 拍也生效——被清 entry 的回填无害, 存活 entry 的不可丢)
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
        if (fill_hit0_w[i]) begin
          addr_q[i] <= fill0_addr_i;
          data_q[i] <= fill0_data_i;
          strb_q[i] <= fill0_strb_i;
          addr_valid_q[i] <= 1'b1;
          data_valid_q[i] <= 1'b1;
        end else if (fill_hit1_w[i]) begin
          addr_q[i] <= fill1_addr_i;
          data_q[i] <= fill1_data_i;
          strb_q[i] <= fill1_strb_i;
          addr_valid_q[i] <= 1'b1;
          data_valid_q[i] <= 1'b1;
        end
      end
      // 退休标记(CAM; flush 拍同拍退休的 entry 经 survive 判定保留)
      for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
        if (mark_hit0_w[i] || mark_hit1_w[i])
          committed_q[i] <= 1'b1;
      end
      // 队头 drain 释放(flush 拍照常——head 为 committed, 不在清除域)
      if (drain_release_w) begin
        valid_q[head_q] <= 1'b0;
        committed_q[head_q] <= 1'b0;
        addr_valid_q[head_q] <= 1'b0;
        data_valid_q[head_q] <= 1'b0;
        head_q <= head_q + {{(ENTRY_COUNT_W-1){1'b0}}, 1'b1};
      end

      if (flush_valid_i) begin
        // 清除域: 非存活 entry(同拍 drain 释放的 head 已在上方清, 恒属存活集)
        for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
          if (valid_q[i] && !survive_r[i]) begin
            valid_q[i] <= 1'b0;
            addr_valid_q[i] <= 1'b0;
            data_valid_q[i] <= 1'b0;
          end
        end
        // 存活段自 head 连续(committed 前缀 + 比 boundary 老的程序序段), tail 回卷
        tail_q <= head_q + survive_count_r[ENTRY_COUNT_W-1:0];
        count_q <= survive_count_r -
            {{ENTRY_COUNT_W{1'b0}}, drain_release_w};
      end else begin
        if (alloc0_fire_w) begin
          valid_q[alloc0_idx_w] <= 1'b1;
          committed_q[alloc0_idx_w] <= 1'b0;
          addr_valid_q[alloc0_idx_w] <= 1'b0;
          data_valid_q[alloc0_idx_w] <= 1'b0;
          rob_idx_q[alloc0_idx_w] <= alloc0_rob_idx_i;
        end
        if (alloc1_fire_w) begin
          valid_q[alloc1_idx_w] <= 1'b1;
          committed_q[alloc1_idx_w] <= 1'b0;
          addr_valid_q[alloc1_idx_w] <= 1'b0;
          data_valid_q[alloc1_idx_w] <= 1'b0;
          rob_idx_q[alloc1_idx_w] <= alloc1_rob_idx_i;
        end
        tail_q <= tail_q +
            {{(ENTRY_COUNT_W-1){1'b0}}, alloc0_fire_w} +
            {{(ENTRY_COUNT_W-1){1'b0}}, alloc1_fire_w};
        count_q <= count_q +
            {{ENTRY_COUNT_W{1'b0}}, alloc0_fire_w} +
            {{ENTRY_COUNT_W{1'b0}}, alloc1_fire_w} -
            {{ENTRY_COUNT_W{1'b0}}, drain_release_w};
      end
    end
  end

`ifdef OOO_ASSERT
  // INV-4-committed: flush 只允许清未退休 store; 已 committed 或同拍 mark 的 store 必须进入 survive 集。
  // 这是 serial/trap flush 能安全接入 SQ flush_all 的承重不变量。
  always @(posedge clk) begin
    if (!rst && flush_valid_i) begin
      for (assert_i = 0; assert_i < ENTRY_COUNT; assert_i = assert_i + 1) begin
        if (valid_q[assert_i] &&
            (committed_q[assert_i] || mark_hit0_w[assert_i] || mark_hit1_w[assert_i]) &&
            !survive_r[assert_i])
          $error("[FLUSH-CONTRACT INV-4] SQ flush 试图清 committed store entry=%0d rob=%0d @%0t",
                 assert_i, rob_idx_q[assert_i], $time);
      end
    end
  end
`endif

endmodule
