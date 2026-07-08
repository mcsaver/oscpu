`include "define.v"

// 【P4 切消费点(2026-07-09)】redirect PC 真源已收敛到 OooRedirectArbiter(年龄律,
// OooFrontend 内实例)。本模块被删除的 next_fetch_pc_q 写者 = E1(csr_trap)/E3(untracked
// :178 臂与 :263 override 臂)/E4(direct flush 装载)/E5(csr commit)/E6(drain 终态各 owner)
// 六处——恰为 shadow 等价断言(SHADOW-EQ-PC, 2026-07-08 落地)覆盖域; 取代物 = always 块
// 文本最后的唯一 arb 终写(redirect_valid_i → redirect_pc_i, 取代原 :271 E1 的最高优先位)。
// ★各臂 outstanding/discard 记账全部原样保留(尤其 E3-over-E4 override 臂——direct_flush
// 拍它是该拍唯一 E3 记账执行点, 整臂删除 = outstanding 状态机破坏, CoreMark 静默卡死家族)。
// 保留 PC 写者 = 顺序推进 + E9(branch_spec restore, rob_walk 下死)+ E7(commit_resolve/
// match_clear, 半死)+ E8(pending_jump, tie-0 死硅, OooRedirectSeqChecker INV-S1 哨兵)——
// shadow 排除集, 无等价证据, 不动; arb 终写在文本序上压过它们, 该同拍仅在 E1 拍(与现行
// 序一致)或不可达拍发生, 由 INV-3c 钉住。
module OooFetchPcOutstandingSequencer (
  input clk,
  input rst,

  input [`XLEN-1:0] reset_pc_i,

  input fetch_rsp_enqueue_i,
  input fetch_rsp_bypass_consumed_i,
  input fetch_rsp_fire_i,
  input [`XLEN-1:0] fetch_rsp_packet_next_pc_i,
  input fetch_req_fire_i,
  input [`XLEN-1:0] fetch_req_pc_i,

  input csr_trap_mem_valid_i,

  input direct_frontend_flush_i,
  input branch_fallthrough_keep_outstanding_i,

  input branch_spec_resolve_valid_i,
  input branch_spec_restore_i,
  input core_branch_resolve_misaligned_i,
  input [`XLEN-1:0] core_branch_resolve_next_pc_i,

  input pending_branch_commit_resolve_i,
  input pending_branch_match_clear_i,
  input pending_branch_misaligned_i,
  input [`XLEN-1:0] pending_branch_next_pc_i,

  input branch_prefetch_pending_match_i,
  input [`XLEN-1:0] branch_prefetch_pc_i,
  input branch_prefetch_hit_available_i,
  input [`XLEN-1:0] branch_prefetch_hit_packet_next_pc_i,

  input branch_resolve_untracked_i,

  input pending_jump_resolve_ready_i,
  input pending_jump_misaligned_i,
  input pending_jump_nolink_commit_i,
  input pending_jump_redirect_after_dispatch_i,
  input jalr_prefetch_pending_match_i,
  input jalr_prefetch_hit_available_i,
  input [`XLEN-1:0] jalr_prefetch_hit_packet_next_pc_i,
  input [`XLEN-1:0] pending_jump_resolved_target_i,

  input pending_system_csr_commit_i,
  // 【serialize Phase1】head0-CSR 队头提交拍 redirect: 清 outstanding + discard 在飞取指
  // 响应(记账臂)。重取 PC 已迁 arbiter trap 口(E5 pre-mux), 本模块不再收 next_pc 载荷。
  input head0_csr_commit_i,

  input drain_complete_i,
  input pending_arch_trap_i,
  input pending_system_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input pending_jump_i,
  input pending_mem_i,

  // 【P4】统一 redirect 仲裁赢家(OooRedirectArbiter 输出, 唯一 arb PC 终写源)
  input redirect_valid_i,
  input [`XLEN-1:0] redirect_pc_i,

  output [`XLEN-1:0] next_fetch_pc_o,
  output outstanding_valid_o,
  output [`XLEN-1:0] outstanding_pc_o,
  output discard_fetch_rsp_o
);

  reg [`XLEN-1:0] next_fetch_pc_q;
  reg outstanding_valid_q;
  reg [`XLEN-1:0] outstanding_pc_q;
  reg discard_fetch_rsp_q;

  assign next_fetch_pc_o = next_fetch_pc_q;
  assign outstanding_valid_o = outstanding_valid_q;
  assign outstanding_pc_o = outstanding_pc_q;
  assign discard_fetch_rsp_o = discard_fetch_rsp_q;

  always @(posedge clk) begin
    if (rst) begin
      next_fetch_pc_q <= reset_pc_i;
      outstanding_valid_q <= 1'b0;
      outstanding_pc_q <= {`XLEN{1'b0}};
      discard_fetch_rsp_q <= 1'b0;
    end else begin
      if ((fetch_rsp_enqueue_i || fetch_rsp_bypass_consumed_i) &&
          !fetch_req_fire_i) begin
        next_fetch_pc_q <= fetch_rsp_packet_next_pc_i;
      end else if (fetch_req_fire_i) begin
        next_fetch_pc_q <= fetch_req_pc_i;
      end

      if (fetch_rsp_fire_i && !fetch_req_fire_i) begin
        outstanding_valid_q <= 1'b0;
      end else if (fetch_req_fire_i) begin
        outstanding_valid_q <= 1'b1;
        outstanding_pc_q <= fetch_req_pc_i;
      end

      // 下面的顺序刻意保持父模块原 nonblocking 覆盖优先级。
      // 【P4】E4 direct flush 臂: outstanding/discard 记账保留; 原内层 PC 写
      // (direct fire → direct_fire_succ / fallthrough-capture 覆写)已删——该拍
      // arbiter direct 口(e4 构造式, OooFrontend)给出同值赢家, arb 终写覆盖。
      if (direct_frontend_flush_i) begin
        outstanding_valid_q <= branch_fallthrough_keep_outstanding_i ? 1'b1 :
                               fetch_req_fire_i;
        outstanding_pc_q <= branch_fallthrough_keep_outstanding_i ?
                            outstanding_pc_q :
                            (fetch_req_fire_i ? fetch_req_pc_i :
                                                {`XLEN{1'b0}});
        discard_fetch_rsp_q <= branch_fallthrough_keep_outstanding_i ? 1'b0 :
                               (outstanding_valid_q && !fetch_rsp_fire_i);
      end else begin
        if (discard_fetch_rsp_q && fetch_rsp_fire_i) begin
          discard_fetch_rsp_q <= 1'b0;
        end
      end

      // E9 branch_spec restore(rob_walk 下 branch_spec_active≡0, 死臂): 原样保留
      // (shadow 排除集, 无 arbiter 等价证据)。
      if (!direct_frontend_flush_i && branch_spec_resolve_valid_i) begin
        if (branch_spec_restore_i) begin
          outstanding_valid_q <= fetch_req_fire_i &&
                                 !core_branch_resolve_misaligned_i;
          outstanding_pc_q <= (fetch_req_fire_i &&
                               !core_branch_resolve_misaligned_i) ?
                              fetch_req_pc_i : {`XLEN{1'b0}};
          discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
          if (!core_branch_resolve_misaligned_i) begin
            next_fetch_pc_q <= core_branch_resolve_next_pc_i;
          end
        end
      end

      // E7 commit_resolve / match_clear(半死): 整臂原样保留(记账+PC)。
      if (pending_branch_commit_resolve_i) begin
        outstanding_valid_q <= 1'b0;
        outstanding_pc_q <= {`XLEN{1'b0}};
        discard_fetch_rsp_q <= fetch_req_fire_i ||
                               (outstanding_valid_q && !fetch_rsp_fire_i);
        if (!pending_branch_misaligned_i) begin
          next_fetch_pc_q <= pending_branch_next_pc_i;
        end
      end else if (pending_branch_match_clear_i) begin
        outstanding_valid_q <= (!core_branch_resolve_misaligned_i &&
                                branch_prefetch_pending_match_i) ? 1'b1 :
                               fetch_req_fire_i;
        outstanding_pc_q <= (!core_branch_resolve_misaligned_i &&
                             branch_prefetch_pending_match_i) ?
                            branch_prefetch_pc_i :
                            (fetch_req_fire_i ? fetch_req_pc_i :
                                                {`XLEN{1'b0}});
        discard_fetch_rsp_q <= ((core_branch_resolve_misaligned_i ||
                                 !branch_prefetch_pending_match_i) &&
                                outstanding_valid_q && !fetch_rsp_fire_i);
        if (!core_branch_resolve_misaligned_i) begin
          if (branch_prefetch_hit_available_i) begin
            next_fetch_pc_q <= branch_prefetch_hit_packet_next_pc_i;
          end else begin
            next_fetch_pc_q <= core_branch_resolve_next_pc_i;
          end
        end
      end else if (!direct_frontend_flush_i && branch_resolve_untracked_i) begin
        // 【P4】E3 untracked 臂: 记账保留; PC 写(core_branch_resolve_next_pc)已删
        // ——arbiter branch 口(真 rob_idx 年龄)给出同值赢家。
        outstanding_valid_q <= fetch_req_fire_i &&
                               !core_branch_resolve_misaligned_i;
        outstanding_pc_q <= (fetch_req_fire_i &&
                             !core_branch_resolve_misaligned_i) ?
                            fetch_req_pc_i : {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
      end else if (!direct_frontend_flush_i && pending_jump_resolve_ready_i) begin
        // E8 pending_jump(OooFrontend tie-0 死硅, OooRedirectSeqChecker INV-S1 哨兵):
        // 整臂原样保留(记账+PC)。
        if (pending_jump_misaligned_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
        end else if (pending_jump_nolink_commit_i ||
                     pending_jump_redirect_after_dispatch_i) begin
          outstanding_valid_q <= jalr_prefetch_pending_match_i ? 1'b1 :
                                 fetch_req_fire_i;
          outstanding_pc_q <= jalr_prefetch_pending_match_i ?
                              branch_prefetch_pc_i :
                              (fetch_req_fire_i ? fetch_req_pc_i :
                                                  {`XLEN{1'b0}});
          discard_fetch_rsp_q <= (jalr_prefetch_hit_available_i &&
                                  fetch_req_fire_i) ||
                                 (!jalr_prefetch_pending_match_i &&
                                  outstanding_valid_q && !fetch_rsp_fire_i);
          if (jalr_prefetch_hit_available_i) begin
            next_fetch_pc_q <= jalr_prefetch_hit_packet_next_pc_i;
          end else begin
            next_fetch_pc_q <= pending_jump_resolved_target_i;
          end
        end
      end else if (!direct_frontend_flush_i &&
          (pending_system_csr_commit_i || head0_csr_commit_i)) begin
        // 【P4】E5 csr commit 臂: 记账保留; PC 写(head0?core_commit0_next_pc:
        // pending_system_next_pc)已删——arbiter trap 口(E5 pre-mux, age0)覆盖。
        outstanding_valid_q <= 1'b0;
        outstanding_pc_q <= {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
      end else if (!csr_trap_mem_valid_i &&
                   !direct_frontend_flush_i && drain_complete_i) begin
        // 【P4】E6 drain 终态: 各 owner 记账保留(owner 序 arch>system>branch>jump>mem);
        // 各 PC 写(csr_trap_target/csr_ret_target/system_next_pc/branch_next_pc/
        // jalr_prefetch/jump_target/mem_next_pc)已删——arbiter trap 口(E6 pre-mux)覆盖。
        if (pending_arch_trap_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
        end else if (pending_system_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
        end else if (pending_branch_i && !pending_branch_dispatched_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
        end else if (pending_jump_i) begin
          outstanding_valid_q <= jalr_prefetch_pending_match_i;
          outstanding_pc_q <= jalr_prefetch_pending_match_i ?
                              branch_prefetch_pc_i : {`XLEN{1'b0}};
          discard_fetch_rsp_q <= (!jalr_prefetch_pending_match_i &&
                                  outstanding_valid_q && !fetch_rsp_fire_i);
        end else if (pending_mem_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
        end
      end

      // B2 mode=1: older backend mispredict redirect(untracked)与同拍 wrong-path 的 direct
      // dispatch flush 冲突时, untracked redirect 优先(架构真值, squash younger 投机指令)。
      // 【P4】此臂 PC 写已删(年龄律 branch 口 age<15 构造性胜过 direct 口 head-1 哨兵,
      // GAP-1 双落点人工同步随之消灭); ★记账必须保留——direct_flush 拍上面 :178 位置的
      // E3 臂被 !direct_frontend_flush_i 门死, 本臂是该拍唯一 E3 记账执行点, 整臂删除 =
      // outstanding 状态机破坏 → 续取 wrong-path stale 源 → CoreMark 静默卡死(修复史)。
      if (direct_frontend_flush_i && branch_resolve_untracked_i &&
          !core_branch_resolve_misaligned_i) begin
        outstanding_valid_q <= fetch_req_fire_i;
        outstanding_pc_q <= fetch_req_fire_i ? fetch_req_pc_i : {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
      end

      // 【P4】E1 csr_trap 臂: 记账保留; PC 写(csr_trap_target)已删——arbiter trap 口
      // (E1 pre-mux 最高档, age0 恒胜)覆盖, 由 OooRedirectSeqChecker INV-S2 延迟一拍守。
      if (csr_trap_mem_valid_i) begin
        outstanding_valid_q <= 1'b0;
        outstanding_pc_q <= {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
      end

      // 【P4 arb 终写】唯一 redirect PC 落点(文本最后 = 最高优先, 取代原 E1 位置):
      // OooRedirectArbiter 年龄律赢家。E1/E3/E4/E5/E6 六族全部经此写入。
      if (redirect_valid_i) begin
        next_fetch_pc_q <= redirect_pc_i;
      end
    end
  end

`ifdef OOO_ASSERT
  // INV-2 (flush-redirect 契约 §4, P4 切消费点后重写): next_fetch_pc_q 各终态写者同拍
  // 至多一个赢。新写者集 = {顺序推进(非终态, 不计), E9(:c), E7cr/E7mc/E8 保留臂(:d),
  // arb 终写(:g, 文本最后 = 最高优先)}。win_x = 条件成立且无更高优先(文本更后)写者。
  // 用手工计数(非 $onehot0)保 iverilog -g2012 与 Verilator 双端可编译。
  wire inv2_cond_c_w = !direct_frontend_flush_i && branch_spec_resolve_valid_i &&
         branch_spec_restore_i && !core_branch_resolve_misaligned_i; // E9
  wire inv2_e7cr_pc_w = pending_branch_commit_resolve_i &&
         !pending_branch_misaligned_i;                               // E7 commit_resolve PC 写
  wire inv2_e7mc_pc_w = !pending_branch_commit_resolve_i &&
         pending_branch_match_clear_i &&
         !core_branch_resolve_misaligned_i;                          // E7 match_clear PC 写
  wire inv2_e8_pc_w = !pending_branch_commit_resolve_i &&
         !pending_branch_match_clear_i &&
         !direct_frontend_flush_i && !branch_resolve_untracked_i &&
         pending_jump_resolve_ready_i && !pending_jump_misaligned_i &&
         (pending_jump_nolink_commit_i ||
          pending_jump_redirect_after_dispatch_i);                   // E8 PC 写(链序守卫)
  wire inv2_cond_d_w = inv2_e7cr_pc_w || inv2_e7mc_pc_w || inv2_e8_pc_w;
  wire inv2_cond_g_w = redirect_valid_i;                             // arb 终写
  wire inv2_win_g_w = inv2_cond_g_w;
  wire inv2_win_d_w = inv2_cond_d_w && !inv2_cond_g_w;
  wire inv2_win_c_w = inv2_cond_c_w && !inv2_cond_d_w && !inv2_cond_g_w;
  wire [1:0] inv2_win_count_w = inv2_win_c_w + inv2_win_d_w + inv2_win_g_w;
  always @(posedge clk) if (!rst) begin
    if (inv2_win_count_w > 2'd1)
      $error("[FLUSH-CONTRACT INV-2] 同拍多个 redirect 终态写者赢: c=%b d=%b g=%b @%0t",
             inv2_win_c_w, inv2_win_d_w, inv2_win_g_w, $time);
  end

  // INV-3c (P4 排除拍互斥哨兵, 新增): arb 终写(文本最后)压过 E7/E8/E9 保留臂 PC 写
  // 的同拍, 只允许发生在 E1 拍(csr_trap——现行序 :271 本就压过一切, 序不变)——其余
  // 组合 = 排除集臂与 arbiter 源同拍共活, 现行文本序与年龄律可能分歧, 全测试集应
  // 不可达; fire = 排除集互斥被打破, 须回契约重审(不得静默扩排除集)。
  always @(posedge clk) if (!rst) begin
    if (redirect_valid_i &&
        (inv2_e7cr_pc_w || inv2_e7mc_pc_w || inv2_e8_pc_w || inv2_cond_c_w) &&
        !csr_trap_mem_valid_i)
      $error("[FLUSH-CONTRACT INV-3c] arb 终写与保留臂(E7/E8/E9)非 E1 同拍共活: e7cr=%b e7mc=%b e8=%b e9=%b @%0t",
             inv2_e7cr_pc_w, inv2_e7mc_pc_w, inv2_e8_pc_w, inv2_cond_c_w, $time);
  end
`endif

endmodule
