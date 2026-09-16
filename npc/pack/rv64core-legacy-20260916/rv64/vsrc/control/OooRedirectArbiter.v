`include "include/define.v"

// =============================================================================
// OooRedirectArbiter —— 单一控制流重定向仲裁器（B2 共享地基）
// 详见 design/arch/b2-branch-spec-redirect.md §3.2、ooo-core-architecture.md §5.5。
// -----------------------------------------------------------------------------
// 职责：把全核多个 redirect/flush 源仲裁成**唯一**的 redirect_request。后续切片用它取代
//        OooFetchRequestMux 的隐式优先级链与控制面各汇合点（本切片只建模块+单测，不接线）。
// 协议：纯组合 selector。每个源提供
// {valid, pc, rob_idx, reason, flush_fetch, backend_action}；
//        本模块只"选择并透传胜者字段"，不发明 flush 策略，使仲裁规则显式可见。
//
// ---- RTL 拓扑（topology-first）----
// ① 边界/协议：纯组合，无 clk/状态。输入 N=3 个 redirect 源 + rob_head_idx；输出 1 个 redirect_request。
// ② 状态寄存器：无（寄存交由下游 sequencer）。
// ③ 组合块：(a) 年龄 age = rob_idx - head（`OOO_ROB_INDEX_W` 位环形减法）；
//            (b) 三路胜者判定（显式 wire，非 function）；(c) 胜者字段 mux。
// ④ FSM：无。  ⑤ pipeline/valid：组合，redirect_valid_o = OR(各源 valid)。
// ⑥ flush/kill 优先级：**按年龄——最老(age 最小)胜**；同 age 平手按类 trap>branch>direct。
//    依据：trap/xret 只在 commit(ROB head) 产生 → 恒为最老 → 年龄律天然给它最高优先级；
//    同 age 平手仅发生在"同一条指令既误预测又异常"(misaligned 分支)，此时 trap 胜。
//    kill_younger_than = 胜者 rob_idx；下游 squash age 比它大的全部 uop。
// ⑦ 资源：无共享资源，纯组合 mux。
// ⑧ 关键路径：3 路 `OOO_ROB_INDEX_W`(=4) 位 age 比较 + 字段 mux，浅；远低于 dispatch 39 级，不影响 Fmax。
// ⑨ function：无（年龄比较内联为 wire，仲裁显式）。
// 源（本切片固定 3 路，后续可扩 commit lane1 / sfence / fence.i / debug 等）：
//   - trap  ：TRAP_COMMITTED 类，commit 异常 / xret（恒在 head=最老）。
//   - branch：DEFERRED 类，后端 branch / JALR 误预测。
//   - direct：IMMEDIATE 类，dispatch 期直算的 direct 控制流（最年轻）。
// =============================================================================
module OooRedirectArbiter (
  input  wire [`OOO_ROB_INDEX_W-1:0] rob_head_idx_i,

  // 源 0：trap / xret（commit 阶段，恒在 ROB head）
  input  wire                        trap_valid_i,
  input  wire [`XLEN-1:0]            trap_pc_i,
  input  wire [`OOO_ROB_INDEX_W-1:0] trap_rob_idx_i,
  input  wire [`REDIR_REASON_W-1:0]  trap_reason_i,
  input  wire                        trap_flush_fetch_i,
  input  wire [`OOO_BACKEND_ACTION_W-1:0] trap_backend_action_i,

  // 源 1：branch / JALR 误预测（后端解析）
  input  wire                        branch_valid_i,
  input  wire [`XLEN-1:0]            branch_pc_i,
  input  wire [`OOO_ROB_INDEX_W-1:0] branch_rob_idx_i,
  input  wire [`REDIR_REASON_W-1:0]  branch_reason_i,
  input  wire                        branch_flush_fetch_i,
  input  wire [`OOO_BACKEND_ACTION_W-1:0] branch_backend_action_i,

  // 源 2：direct 控制流（dispatch 期直算，最年轻）
  input  wire                        direct_valid_i,
  input  wire [`XLEN-1:0]            direct_pc_i,
  input  wire [`OOO_ROB_INDEX_W-1:0] direct_rob_idx_i,
  input  wire [`REDIR_REASON_W-1:0]  direct_reason_i,
  input  wire                        direct_flush_fetch_i,
  input  wire [`OOO_BACKEND_ACTION_W-1:0] direct_backend_action_i,

  // 类型化控制事件与 fetch redirect 分离：misaligned branch 等事件可以只做
  // selective backend action，而不直接改 fetch PC。
  output wire                        control_event_valid_o,
  output wire                        redirect_valid_o,
  output wire [`XLEN-1:0]            redirect_pc_o,
  output wire [`OOO_ROB_INDEX_W-1:0] redirect_kill_idx_o,    // kill_younger_than
  output wire [`REDIR_REASON_W-1:0]  redirect_reason_o,
  output wire                        redirect_flush_fetch_o,
  output wire                        redirect_flush_backend_o,
  output wire [`OOO_BACKEND_ACTION_W-1:0] redirect_backend_action_o
);

  // (a) 年龄：age = rob_idx - head（环形减法；head 处=age0 最老，越大越年轻）
  wire [`OOO_ROB_INDEX_W-1:0] trap_age_w   = trap_rob_idx_i   - rob_head_idx_i;
  wire [`OOO_ROB_INDEX_W-1:0] branch_age_w = branch_rob_idx_i - rob_head_idx_i;
  wire [`OOO_ROB_INDEX_W-1:0] direct_age_w = direct_rob_idx_i - rob_head_idx_i;

  // (b) 三路胜者：最老(age 最小)胜；平手按 trap>branch>direct
  wire trap_win_w =
      trap_valid_i &&
      (!branch_valid_i || (trap_age_w <= branch_age_w)) &&   // trap 占平手胜 branch
      (!direct_valid_i || (trap_age_w <= direct_age_w));     // trap 占平手胜 direct
  wire branch_win_w =
      branch_valid_i && !trap_win_w &&
      (!trap_valid_i   || (branch_age_w <  trap_age_w)) &&   // 须严格老于 trap（trap 占平手）
      (!direct_valid_i || (branch_age_w <= direct_age_w));   // branch 占平手胜 direct
  wire direct_win_w =
      direct_valid_i && !trap_win_w && !branch_win_w;

  // (c) 胜者字段 mux（valid 时三 win 必恰好一个为真）
  assign control_event_valid_o =
      trap_valid_i || branch_valid_i || direct_valid_i;
  assign redirect_pc_o =
      trap_win_w   ? trap_pc_i   :
      branch_win_w ? branch_pc_i :
                     direct_pc_i;
  assign redirect_kill_idx_o =
      trap_win_w   ? trap_rob_idx_i   :
      branch_win_w ? branch_rob_idx_i :
                     direct_rob_idx_i;
  assign redirect_reason_o =
      trap_win_w   ? trap_reason_i   :
      branch_win_w ? branch_reason_i :
                     direct_reason_i;
  assign redirect_flush_fetch_o =
      trap_win_w   ? trap_flush_fetch_i   :
      branch_win_w ? branch_flush_fetch_i :
                     direct_flush_fetch_i;
  assign redirect_backend_action_o =
      trap_win_w   ? trap_backend_action_i   :
      branch_win_w ? branch_backend_action_i :
                     direct_backend_action_i;
  assign redirect_flush_backend_o =
      redirect_backend_action_o != `OOO_BACKEND_ACTION_NONE;
  assign redirect_valid_o =
      control_event_valid_o && redirect_flush_fetch_o;

`ifdef OOO_ASSERT
  always @(*) begin
    // Compare the source inputs directly.  Separate continuous legality wires
    // can lag the valid/action pair by one simulation delta and report a
    // transient reserved value even though the settled typed packet is legal.
    if ((trap_valid_i &&
         (trap_backend_action_i != `OOO_BACKEND_ACTION_NONE) &&
         (trap_backend_action_i != `OOO_BACKEND_ACTION_SELECTIVE_NOW) &&
         (trap_backend_action_i != `OOO_BACKEND_ACTION_FULL_NEXT)) ||
        (branch_valid_i &&
         (branch_backend_action_i != `OOO_BACKEND_ACTION_NONE) &&
         (branch_backend_action_i != `OOO_BACKEND_ACTION_SELECTIVE_NOW) &&
         (branch_backend_action_i != `OOO_BACKEND_ACTION_FULL_NEXT)) ||
        (direct_valid_i &&
         (direct_backend_action_i != `OOO_BACKEND_ACTION_NONE) &&
         (direct_backend_action_i != `OOO_BACKEND_ACTION_SELECTIVE_NOW) &&
         (direct_backend_action_i != `OOO_BACKEND_ACTION_FULL_NEXT)))
      $error("[V9O-REDIRECT-ACTION] source supplied reserved backend action");
  end
`endif

endmodule
