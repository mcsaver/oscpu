`include "define.v"

// 【LSQ Phase2+3 第一刀】访存在飞事务顺序队列(spec ooo-lsq-implementation-plan.md §4)。
//
// 桥响应恒按请求序返回(单 FSM; 后续 slave/xbar 流水化亦保持 in-order), 因此
// FIFO 头是响应归属的顺序候选；它不是身份本身。任何架构副作用必须再精确匹配
// {owner_kind, owner_token, mmu_epoch}。fault_tval 是捕获时 provenance payload，
// 必须独立精确回声但不进入正常身份门。mismatch 响应仍从传输面 drain，
// 但上层必须 fail-closed，不能用 ROB tag 或 FIFO head 猜测 owner。
//
// kind 语义:
//   LOAD  = plain load(数据回填 wb/fpld_wb), 可被 ROB-walk kill(killed 置位,
//           rsp 到达即静默弃);
//   PROBE = plain store 的翻译/PMP 探测(rsp: PA→SQ fill / fault→wb exception);
//   DRAIN = SQ 退休落存写(nokill, flush 不清, rsp 仅通知 SQ pop);
//   LEGACY= AMO/LR/SC 与 mem_buffer 迁移等旧单例通道事务的占位——状态仍在
//           IntBackend 的 mem_*_q 单例(该族发射条件=本队列空, 在飞期间不发新,
//           故 LEGACY 在队列中恒独占且深度恒 1, 行为与旧版逐位一致)。
//
// 发射并发度: LOAD/PROBE/DRAIN 互相可背靠背(队列有空+桥 ready 即发);
// LEGACY 独占。这把"每 load 发→等 rsp→再发"的单例串行(访存 ILP 真封顶之一)
// 换成 dcache-hit 流 1 load/拍的流水。
module OooMemInflightQueue #(
  parameter ENTRY_N = 4,
  parameter ENTRY_W = 2,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter OWNER_TOKEN_W = 5,
  parameter MMU_EPOCH_W = 2
) (
  input clk,
  input rst,
  input flush_i,

  // push(发射拍, 与桥 req fire 同拍——【P5 刀 M】fire 语义=进桥侧 req 寄存站,
  // 事务从进站起即被记账, 桥内寄存站项↔MIQ 项保持双射)
  input push_valid_i,
  input [1:0] push_kind_i,
  input [1:0] push_owner_kind_i,
  input [OWNER_TOKEN_W-1:0] push_owner_token_i,
  input [MMU_EPOCH_W-1:0] push_mmu_epoch_i,
  input [`XLEN-1:0] push_fault_tval_i,
  input [ROB_INDEX_W-1:0] push_rob_idx_i,
  input [PHY_REG_ADDR_W-1:0] push_pdest_i,
  input push_pdest_fp_i,
  input [1:0] push_size_i,
  input push_unsigned_i,
  input [`XLEN-1:0] push_eff_addr_i,
  // PROBE 专用: 发射拍寄存的 store 数据/掩码(rsp 拍随 PA 一起回填 SQ)
  input [`XLEN-1:0] push_wdata_i,
  input [`STRB_W-1:0] push_wstrb_i,

  // pop(rsp 消费拍)
  input pop_valid_i,
  input [1:0] pop_owner_kind_i,
  input [OWNER_TOKEN_W-1:0] pop_owner_token_i,
  input [MMU_EPOCH_W-1:0] pop_mmu_epoch_i,
  input [`XLEN-1:0] pop_fault_tval_i,
  output pop_owner_match_o,
  output pop_tval_echo_match_o,

  // ROB-walk kill: 比 kill_rob_idx 年轻的 LOAD/PROBE 标 killed
  input kill_valid_i,
  input [ROB_INDEX_W-1:0] kill_rob_idx_i,
  input [ROB_INDEX_W-1:0] rob_head_idx_i,

  // 队头视图(rsp 归属)
  output head_valid_o,
  output [1:0] head_kind_o,
  output [1:0] head_owner_kind_o,
  output [OWNER_TOKEN_W-1:0] head_owner_token_o,
  output [MMU_EPOCH_W-1:0] head_mmu_epoch_o,
  output [`XLEN-1:0] head_fault_tval_o,
  output head_killed_o,
  output head_effective_killed_o,
  output [ROB_INDEX_W-1:0] head_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] head_pdest_o,
  output head_pdest_fp_o,
  output [1:0] head_size_o,
  output head_unsigned_o,
  output [`XLEN-1:0] head_eff_addr_o,
  output [`XLEN-1:0] head_wdata_o,
  output [`STRB_W-1:0] head_wstrb_o,

  // v8u/F4 read-only lookahead view.  It is meaningful only while at least
  // two entries are resident.  The queue still has one pop port: this face
  // never advances ownership and is used only to qualify a station load on
  // the exact edge where the current head response is consumed.
  output next_head_valid_o,
  output [1:0] next_head_kind_o,
  output [1:0] next_head_owner_kind_o,
  output [OWNER_TOKEN_W-1:0] next_head_owner_token_o,
  output [MMU_EPOCH_W-1:0] next_head_mmu_epoch_o,
  output [`XLEN-1:0] next_head_fault_tval_o,
  output next_head_killed_o,
  output next_head_effective_killed_o,
  output [ROB_INDEX_W-1:0] next_head_rob_idx_o,

  // 占用视图(发射决策/序判定)
  output [ENTRY_W:0] count_o,
  output empty_o,
  output full_o,
  // MIQ occupancy subset only.  The owner tracker live bitmap is the sole
  // global liveness truth; this mask must never authorize token reuse.
  output [(1 << OWNER_TOKEN_W)-1:0] occupancy_token_mask_o,
  // 在飞 LOAD/PROBE 中是否存在 store 序相关项(恒 0——LOAD/PROBE 无写副作用;
  // 保留口位由 IntBackend 的 LEGACY 单例判定承担)
  output [ENTRY_N-1:0] entry_valid_o,
  output [ENTRY_N*2-1:0] entry_kind_o,
  output [ENTRY_N*ROB_INDEX_W-1:0] entry_rob_idx_o,
  output [ENTRY_N*`XLEN-1:0] entry_addr_o
);

  localparam [1:0] KIND_LOAD = 2'd0;
  localparam [1:0] KIND_PROBE = 2'd1;
  localparam [1:0] KIND_DRAIN = 2'd2;
  localparam [1:0] KIND_LEGACY = 2'd3;
  // KIND_LEGACY 仅由父模块比对 head_kind 使用, 本模块内 kill 白名单不含它
  wire [1:0] kind_legacy_unused_w = KIND_LEGACY;
  wire push_phase_owner_match_w =
      ((push_kind_i == KIND_LOAD) && (push_owner_kind_i == 2'b00)) ||
      (((push_kind_i == KIND_PROBE) || (push_kind_i == KIND_DRAIN)) &&
       (push_owner_kind_i == 2'b01)) ||
      ((push_kind_i == KIND_LEGACY) && (push_owner_kind_i == 2'b10));

  reg valid_q [0:ENTRY_N-1];
  reg [1:0] kind_q [0:ENTRY_N-1];
  reg [1:0] owner_kind_q [0:ENTRY_N-1];
  reg [OWNER_TOKEN_W-1:0] owner_token_q [0:ENTRY_N-1];
  reg [MMU_EPOCH_W-1:0] mmu_epoch_q [0:ENTRY_N-1];
  reg [`XLEN-1:0] fault_tval_q [0:ENTRY_N-1];
  reg killed_q [0:ENTRY_N-1];
  reg [ROB_INDEX_W-1:0] rob_idx_q [0:ENTRY_N-1];
  reg [PHY_REG_ADDR_W-1:0] pdest_q [0:ENTRY_N-1];
  reg pdest_fp_q [0:ENTRY_N-1];
  reg [1:0] size_q [0:ENTRY_N-1];
  reg unsigned_q [0:ENTRY_N-1];
  reg [`XLEN-1:0] eff_addr_q [0:ENTRY_N-1];
  reg [`XLEN-1:0] wdata_q [0:ENTRY_N-1];
  reg [`STRB_W-1:0] wstrb_q [0:ENTRY_N-1];

  reg [ENTRY_W-1:0] head_q;
  reg [ENTRY_W-1:0] tail_q;
  reg [ENTRY_W:0] count_q;

  integer i;

  assign head_valid_o = (count_q != {(ENTRY_W+1){1'b0}});
  assign head_kind_o = kind_q[head_q];
  assign head_owner_kind_o = owner_kind_q[head_q];
  assign head_owner_token_o = owner_token_q[head_q];
  assign head_mmu_epoch_o = mmu_epoch_q[head_q];
  assign head_fault_tval_o = fault_tval_q[head_q];
  assign head_killed_o = killed_q[head_q];
  assign head_rob_idx_o = rob_idx_q[head_q];
  assign head_pdest_o = pdest_q[head_q];
  assign head_pdest_fp_o = pdest_fp_q[head_q];
  assign head_size_o = size_q[head_q];
  assign head_unsigned_o = unsigned_q[head_q];
  assign head_eff_addr_o = eff_addr_q[head_q];
  assign head_wdata_o = wdata_q[head_q];
  assign head_wstrb_o = wstrb_q[head_q];

  wire [ENTRY_W-1:0] next_head_idx_w =
      head_q + {{(ENTRY_W-1){1'b0}}, 1'b1};
  assign next_head_valid_o =
      (count_q >= {{(ENTRY_W-1){1'b0}}, 2'b10});
  assign next_head_kind_o = kind_q[next_head_idx_w];
  assign next_head_owner_kind_o = owner_kind_q[next_head_idx_w];
  assign next_head_owner_token_o = owner_token_q[next_head_idx_w];
  assign next_head_mmu_epoch_o = mmu_epoch_q[next_head_idx_w];
  assign next_head_fault_tval_o = fault_tval_q[next_head_idx_w];
  assign next_head_killed_o = killed_q[next_head_idx_w];
  assign next_head_rob_idx_o = rob_idx_q[next_head_idx_w];

  assign count_o = count_q;
  assign empty_o = (count_q == {(ENTRY_W+1){1'b0}});
  assign full_o = (count_q == ENTRY_N[ENTRY_W:0]);
  assign pop_owner_match_o = head_valid_o &&
      (head_owner_kind_o == pop_owner_kind_i) &&
      (head_owner_token_o == pop_owner_token_i) &&
      (head_mmu_epoch_o == pop_mmu_epoch_i);
  assign pop_tval_echo_match_o = head_valid_o &&
      (head_fault_tval_o == pop_fault_tval_i);

  reg [(1 << OWNER_TOKEN_W)-1:0] live_token_mask_r;
  integer live_i;
  always @(*) begin
    live_token_mask_r = {(1 << OWNER_TOKEN_W){1'b0}};
    for (live_i = 0; live_i < ENTRY_N; live_i = live_i + 1) begin
      if (valid_q[live_i])
        live_token_mask_r[owner_token_q[live_i]] = 1'b1;
    end
  end
  assign occupancy_token_mask_o = live_token_mask_r;

  genvar gi;
  generate
    for (gi = 0; gi < ENTRY_N; gi = gi + 1) begin : g_snoop
      assign entry_valid_o[gi] = valid_q[gi];
      assign entry_kind_o[gi*2 +: 2] = kind_q[gi];
      assign entry_rob_idx_o[gi*ROB_INDEX_W +: ROB_INDEX_W] = rob_idx_q[gi];
      assign entry_addr_o[gi*`XLEN +: `XLEN] = eff_addr_q[gi];
    end
  endgenerate

  // flush 时 DRAIN(nokill 写必达)必须存活: 队列压缩保留 DRAIN——
  // 但 DRAIN 与被清事务在桥内的 AXI 序: 桥 cpu_kill 会丢弃非 nokill 在飞
  // 事务的响应(drop_rsp), 响应流中被丢事务不再产生 rsp, 压缩后的队列序
  // 与存活响应序保持一致(桥按请求序, 丢弃不改变存活者相对序)。
  reg [ENTRY_W:0] flush_keep_count_r;
  always @(*) begin : flush_count_blk
    integer k;
    flush_keep_count_r = {(ENTRY_W+1){1'b0}};
    for (k = 0; k < ENTRY_N; k = k + 1) begin
      if (valid_q[k] && (kind_q[k] == KIND_DRAIN))
        flush_keep_count_r = flush_keep_count_r + {{ENTRY_W{1'b0}}, 1'b1};
    end
  end

  wire head_same_cycle_kill_w = head_valid_o && kill_valid_i &&
      ((head_kind_o == KIND_LOAD) || (head_kind_o == KIND_PROBE)) &&
      ((head_rob_idx_o - rob_head_idx_i) >
       (kill_rob_idx_i - rob_head_idx_i));
  assign head_effective_killed_o = head_valid_o &&
      (head_killed_o || head_same_cycle_kill_w ||
       (flush_i && (head_kind_o != KIND_DRAIN)));
  wire next_head_same_cycle_kill_w = next_head_valid_o && kill_valid_i &&
      ((next_head_kind_o == KIND_LOAD) ||
       (next_head_kind_o == KIND_PROBE)) &&
      ((next_head_rob_idx_o - rob_head_idx_i) >
       (kill_rob_idx_i - rob_head_idx_i));
  assign next_head_effective_killed_o = next_head_valid_o &&
      (next_head_killed_o || next_head_same_cycle_kill_w ||
       (flush_i && (next_head_kind_o != KIND_DRAIN)));

  wire push_fire_w = push_valid_i && !full_o && !flush_i;
  // The bridge/AXI beat may already have been accepted by the outer transport,
  // but the architectural owner queue advances only on the exact 9-bit identity.
  // fault_tval is captured provenance: an echo drift asserts below, while a
  // non-assert build still consumes the exact identity and keeps the captured
  // head_fault_tval_o as the sole architectural source.
  wire pop_fire_w = pop_valid_i && head_valid_o && pop_owner_match_o;
  wire flush_pop_drain_w = pop_fire_w && (kind_q[head_q] == KIND_DRAIN);

  always @(posedge clk) begin
    if (rst) begin
      head_q <= {ENTRY_W{1'b0}};
      tail_q <= {ENTRY_W{1'b0}};
      count_q <= {(ENTRY_W+1){1'b0}};
      for (i = 0; i < ENTRY_N; i = i + 1) begin
        valid_q[i] <= 1'b0;
        kind_q[i] <= 2'b00;
        owner_kind_q[i] <= 2'b00;
        owner_token_q[i] <= {OWNER_TOKEN_W{1'b0}};
        mmu_epoch_q[i] <= {MMU_EPOCH_W{1'b0}};
        fault_tval_q[i] <= {`XLEN{1'b0}};
        killed_q[i] <= 1'b0;
        rob_idx_q[i] <= {ROB_INDEX_W{1'b0}};
        pdest_q[i] <= {PHY_REG_ADDR_W{1'b0}};
        pdest_fp_q[i] <= 1'b0;
        size_q[i] <= 2'b00;
        unsigned_q[i] <= 1'b0;
        eff_addr_q[i] <= {`XLEN{1'b0}};
        wdata_q[i] <= {`XLEN{1'b0}};
        wstrb_q[i] <= {`STRB_W{1'b0}};
      end
    end else if (flush_i) begin : flush_blk
      // 压缩保留 DRAIN(程序序=队列序, 压缩保序)
      integer rd;
      integer wr;
      reg [ENTRY_W-1:0] src;
      wr = 0;
      for (rd = 0; rd < ENTRY_N; rd = rd + 1) begin
        src = head_q + rd[ENTRY_W-1:0];
        // MIQ-G1：pop 永远消费逻辑 head(rd=0)。flush 必须先兑现该 fire，
        // 再过滤未消费 DRAIN；否则已完成的 retired-store owner 会被压回成 ghost。
        if ((rd[ENTRY_W:0] < count_q) && valid_q[src] &&
            (kind_q[src] == KIND_DRAIN) &&
            !(pop_fire_w && (rd == 0))) begin
          kind_q[wr[ENTRY_W-1:0]] <= kind_q[src];
          owner_kind_q[wr[ENTRY_W-1:0]] <= owner_kind_q[src];
          owner_token_q[wr[ENTRY_W-1:0]] <= owner_token_q[src];
          mmu_epoch_q[wr[ENTRY_W-1:0]] <= mmu_epoch_q[src];
          fault_tval_q[wr[ENTRY_W-1:0]] <= fault_tval_q[src];
          killed_q[wr[ENTRY_W-1:0]] <= 1'b0;
          rob_idx_q[wr[ENTRY_W-1:0]] <= rob_idx_q[src];
          pdest_q[wr[ENTRY_W-1:0]] <= pdest_q[src];
          pdest_fp_q[wr[ENTRY_W-1:0]] <= pdest_fp_q[src];
          size_q[wr[ENTRY_W-1:0]] <= size_q[src];
          unsigned_q[wr[ENTRY_W-1:0]] <= unsigned_q[src];
          eff_addr_q[wr[ENTRY_W-1:0]] <= eff_addr_q[src];
          wdata_q[wr[ENTRY_W-1:0]] <= wdata_q[src];
          wstrb_q[wr[ENTRY_W-1:0]] <= wstrb_q[src];
          wr = wr + 1;
        end
      end
      for (i = 0; i < ENTRY_N; i = i + 1)
        valid_q[i] <= (i < wr) ? 1'b1 : 1'b0;
      head_q <= {ENTRY_W{1'b0}};
      tail_q <= wr[ENTRY_W-1:0];
      count_q <= wr[ENTRY_W:0];
    end else begin
      if (push_fire_w) begin
        valid_q[tail_q] <= 1'b1;
        kind_q[tail_q] <= push_kind_i;
        owner_kind_q[tail_q] <= push_owner_kind_i;
        owner_token_q[tail_q] <= push_owner_token_i;
        mmu_epoch_q[tail_q] <= push_mmu_epoch_i;
        fault_tval_q[tail_q] <= push_fault_tval_i;
        // 【F2】kill 拍同拍 push 的 entry 也按 age 判杀: mispredict 当拍 IQ squash 尚未
        // 生效(寄存一拍), wrong-path load/probe 仍可 issue 并 push——kill 扫描只看
        // valid_q 旧值会漏标它, 其迟到 rsp 会写"已被 walk 回收并重分配"的 preg
        // (CoreMark p42 污染案, 架构 GPR 对拍不炸、IQ 消费者读脏)。mode=1 恒 kill
        // 时代漏标 entry 总被下一次 kill 补标, 免 redirect 后窗口显形。
        killed_q[tail_q] <= kill_valid_i &&
            ((push_kind_i == KIND_LOAD) || (push_kind_i == KIND_PROBE)) &&
            ((push_rob_idx_i - rob_head_idx_i) >
             (kill_rob_idx_i - rob_head_idx_i));
        rob_idx_q[tail_q] <= push_rob_idx_i;
        pdest_q[tail_q] <= push_pdest_i;
        pdest_fp_q[tail_q] <= push_pdest_fp_i;
        size_q[tail_q] <= push_size_i;
        unsigned_q[tail_q] <= push_unsigned_i;
        eff_addr_q[tail_q] <= push_eff_addr_i;
        wdata_q[tail_q] <= push_wdata_i;
        wstrb_q[tail_q] <= push_wstrb_i;
        tail_q <= tail_q + {{(ENTRY_W-1){1'b0}}, 1'b1};
      end
      if (pop_fire_w) begin
        valid_q[head_q] <= 1'b0;
        head_q <= head_q + {{(ENTRY_W-1){1'b0}}, 1'b1};
      end
      count_q <= count_q + {{ENTRY_W{1'b0}}, push_fire_w}
                         - {{ENTRY_W{1'b0}}, pop_fire_w};
      // ROB-walk kill: LOAD/PROBE 且比 kill 点年轻 → killed(rsp 到弃)。
      // DRAIN(已退休)/LEGACY(发射条件=独占, kill 语义沿旧 flush 路)不标。
      if (kill_valid_i) begin
        for (i = 0; i < ENTRY_N; i = i + 1) begin
          if (valid_q[i] &&
              ((kind_q[i] == KIND_LOAD) || (kind_q[i] == KIND_PROBE)) &&
              ((rob_idx_q[i] - rob_head_idx_i) >
               (kill_rob_idx_i - rob_head_idx_i))) begin
            killed_q[i] <= 1'b1;
          end
        end
      end
    end
  end

`ifdef OOO_ASSERT
  // MIQ-G1：flush 的 keep-set 必须先扣除同拍已经 fire 的 head pop。
  // 用独立的“旧 DRAIN 总数 - popped DRAIN”算术延迟一拍核对实现压缩结果，
  // 防止压缩循环再次把已消费的 retired-store owner 复活成 ghost。
  reg flush_count_check_q;
  reg [ENTRY_W:0] flush_expected_count_q;
  reg owner_tuple_stable_check_q;
  reg [1:0] owner_tuple_stable_kind_q;
  reg [OWNER_TOKEN_W-1:0] owner_tuple_stable_token_q;
  reg [MMU_EPOCH_W-1:0] owner_tuple_stable_epoch_q;
  integer owner_assert_i;
  always @(posedge clk) begin
    if (rst) begin
      flush_count_check_q <= 1'b0;
      flush_expected_count_q <= {(ENTRY_W+1){1'b0}};
      owner_tuple_stable_check_q <= 1'b0;
      owner_tuple_stable_kind_q <= 2'b00;
      owner_tuple_stable_token_q <= {OWNER_TOKEN_W{1'b0}};
      owner_tuple_stable_epoch_q <= {MMU_EPOCH_W{1'b0}};
    end else begin
      if (flush_count_check_q && (count_q !== flush_expected_count_q))
        $error("[MIQ-FLUSH-POP-COUNT] flush keep count=%0d expected=%0d @%0t",
               count_q, flush_expected_count_q, $time);
      flush_count_check_q <= flush_i;
      if (flush_i)
        flush_expected_count_q <= flush_keep_count_r -
            {{ENTRY_W{1'b0}}, flush_pop_drain_w};
      if (push_fire_w &&
          (^{push_owner_kind_i, push_owner_token_i, push_mmu_epoch_i}
           === 1'bx)) begin
        $display("[V11K-MIQ-PUSH-TUPLE-KNOWN] accepted push has unknown owner tuple @%0t",
                 $time);
        $fatal;
      end
      if (pop_valid_i && head_valid_o &&
          (^{pop_owner_kind_i, pop_owner_token_i, pop_mmu_epoch_i}
           === 1'bx)) begin
        $display("[V11K-MIQ-POP-TUPLE-KNOWN] response has unknown owner tuple @%0t",
                 $time);
        $fatal;
      end
      if (pop_valid_i && head_valid_o && !pop_owner_match_o) begin
        $display("[MIQ-OWNER-MISMATCH] rsp owner does not match FIFO head @%0t", $time);
        $fatal;
      end
      if (pop_valid_i && head_valid_o && pop_owner_match_o &&
          !pop_tval_echo_match_o) begin
        $display("[MIQ-TVAL-ECHO-MISMATCH] rsp tval does not echo captured FIFO provenance @%0t", $time);
        $fatal;
      end
      if (pop_valid_i && !head_valid_o) begin
        $display("[MIQ-OWNER-EMPTY] stale response arrived with no MIQ owner @%0t", $time);
        $fatal;
      end
      if (push_fire_w && (push_owner_kind_i == 2'b11)) begin
        $display("[MIQ-OWNER-RESERVED] reserved owner kind entered MIQ @%0t", $time);
        $fatal;
      end
      if (push_fire_w && !push_phase_owner_match_w) begin
        $display("[MIQ-PHASE-OWNER-MISMATCH] phase=%0d owner_kind=%0d @%0t",
                 push_kind_i, push_owner_kind_i, $time);
        $fatal;
      end
      if (push_fire_w) begin
        for (owner_assert_i = 0; owner_assert_i < ENTRY_N;
             owner_assert_i = owner_assert_i + 1) begin
          if (valid_q[owner_assert_i] &&
              (owner_token_q[owner_assert_i] == push_owner_token_i)) begin
            $display("[MIQ-OWNER-DUP] one live token names two MIQ entries @%0t", $time);
            $fatal;
          end
        end
      end
      for (owner_assert_i = 0; owner_assert_i < ENTRY_N;
           owner_assert_i = owner_assert_i + 1) begin
        if (valid_q[owner_assert_i] &&
            (^{owner_kind_q[owner_assert_i],
               owner_token_q[owner_assert_i],
               mmu_epoch_q[owner_assert_i]} === 1'bx)) begin
          $display("[V11K-MIQ-OWNER-TUPLE-KNOWN] valid entry=%0d has unknown owner tuple @%0t",
                   owner_assert_i, $time);
          $fatal;
        end
      end
      if (owner_tuple_stable_check_q && head_valid_o &&
          ({head_owner_kind_o, head_owner_token_o, head_mmu_epoch_o} !==
           {owner_tuple_stable_kind_q, owner_tuple_stable_token_q,
            owner_tuple_stable_epoch_q})) begin
        $display("[V11K-MIQ-OWNER-TUPLE-STABLE] head owner tuple drifted without queue event @%0t",
                 $time);
        $fatal;
      end
      owner_tuple_stable_check_q <= head_valid_o && !push_fire_w &&
          !pop_fire_w && !flush_i && !kill_valid_i;
      owner_tuple_stable_kind_q <= head_owner_kind_o;
      owner_tuple_stable_token_q <= head_owner_token_o;
      owner_tuple_stable_epoch_q <= head_mmu_epoch_o;
    end
  end
`endif

endmodule
