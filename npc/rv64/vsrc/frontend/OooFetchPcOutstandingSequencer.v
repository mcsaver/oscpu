`include "define.v"

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
  input [`XLEN-1:0] csr_trap_target_i,
  input [`XLEN-1:0] csr_ret_target_i,

  input direct_frontend_flush_i,
  input branch_fallthrough_keep_outstanding_i,
  input direct_jal_fire_i,
  input [`XLEN-1:0] direct_jal_target_i,
  input direct_ret_fire_i,
  input [`XLEN-1:0] direct_ret_target_i,
  input direct_branch_fire_i,
  input direct_branch1_fire_i,
  input direct_branch0_lane1_ret_i,
  input return_cont_dispatch_i,
  input [`XLEN-1:0] return_cont_next_pc_i,
  input [`XLEN-1:0] ras_top_i,
  input branch_target_dispatch_i,
  input [`XLEN-1:0] branch_target_cache_next_pc_i,
  input branch_fallthrough_dispatch_i,
  input [`XLEN-1:0] head_next_pc1_i,
  input direct_branch_resolve_redirect_i,
  input [`XLEN-1:0] direct_branch_resolve_next_pc_i,
  input direct_branch_spec_start_i,
  input [`XLEN-1:0] direct_branch_pred_pc_i,
  input [`XLEN-1:0] head_next_pc0_i,
  input branch_fallthrough_capture_rsp_i,
  input direct_jump_spec_fire_i,           // B2: 非返回 JALR 投机续取
  input [`XLEN-1:0] direct_jump_spec_target_i,

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
  input [`XLEN-1:0] pending_system_next_pc_i,

  input drain_complete_i,
  input pending_arch_trap_i,
  input pending_system_i,
  input pending_system_ecall_i,
  input pending_system_irq_i,
  input pending_system_mret_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input pending_jump_i,
  input [`XLEN-1:0] pending_jump_target_i,
  input pending_mem_i,
  input [`XLEN-1:0] pending_mem_next_pc_i,
  input pending_fp_i,
  input [`XLEN-1:0] pending_fp_next_pc_i,

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
      if (direct_frontend_flush_i) begin
        outstanding_valid_q <= branch_fallthrough_keep_outstanding_i ? 1'b1 :
                               fetch_req_fire_i;
        outstanding_pc_q <= branch_fallthrough_keep_outstanding_i ?
                            outstanding_pc_q :
                            (fetch_req_fire_i ? fetch_req_pc_i :
                                                {`XLEN{1'b0}});
        discard_fetch_rsp_q <= branch_fallthrough_keep_outstanding_i ? 1'b0 :
                               (outstanding_valid_q && !fetch_rsp_fire_i);
        if (direct_jal_fire_i) begin
          next_fetch_pc_q <= direct_jal_target_i;
        end else if (direct_ret_fire_i) begin
          next_fetch_pc_q <= direct_ret_target_i;
        end else if (direct_branch_fire_i) begin
          next_fetch_pc_q <= direct_branch0_lane1_ret_i ?
                             (return_cont_dispatch_i ?
                              return_cont_next_pc_i : ras_top_i) :
                             branch_target_dispatch_i ?
                             branch_target_cache_next_pc_i :
                             branch_fallthrough_dispatch_i ?
                             head_next_pc1_i :
                             direct_branch_resolve_redirect_i ?
                             direct_branch_resolve_next_pc_i :
                             direct_branch_spec_start_i ?
                             direct_branch_pred_pc_i :
                             (direct_branch1_fire_i ? head_next_pc1_i :
                                                      head_next_pc0_i);
          if (branch_fallthrough_capture_rsp_i) begin
            next_fetch_pc_q <= fetch_rsp_packet_next_pc_i;
          end
        end else if (direct_jump_spec_fire_i) begin
          next_fetch_pc_q <= direct_jump_spec_target_i;
        end
      end else begin
        if (discard_fetch_rsp_q && fetch_rsp_fire_i) begin
          discard_fetch_rsp_q <= 1'b0;
        end
      end

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
        outstanding_valid_q <= fetch_req_fire_i &&
                               !core_branch_resolve_misaligned_i;
        outstanding_pc_q <= (fetch_req_fire_i &&
                             !core_branch_resolve_misaligned_i) ?
                            fetch_req_pc_i : {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
        if (!core_branch_resolve_misaligned_i) begin
          next_fetch_pc_q <= core_branch_resolve_next_pc_i;
        end
      end else if (!direct_frontend_flush_i && pending_jump_resolve_ready_i) begin
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
      end else if (!direct_frontend_flush_i && pending_system_csr_commit_i) begin
        outstanding_valid_q <= 1'b0;
        outstanding_pc_q <= {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
        next_fetch_pc_q <= pending_system_next_pc_i;
      end else if (!csr_trap_mem_valid_i &&
                   !direct_frontend_flush_i && drain_complete_i) begin
        if (pending_arch_trap_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          next_fetch_pc_q <= csr_trap_target_i;
        end else if (pending_system_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          if (pending_system_ecall_i || pending_system_irq_i) begin
            next_fetch_pc_q <= csr_trap_target_i;
          end else if (pending_system_mret_i) begin
            next_fetch_pc_q <= csr_ret_target_i;
          end else begin
            next_fetch_pc_q <= pending_system_next_pc_i;
          end
        end else if (pending_branch_i && !pending_branch_dispatched_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          if (!pending_branch_misaligned_i) begin
            next_fetch_pc_q <= pending_branch_next_pc_i;
          end
        end else if (pending_jump_i) begin
          outstanding_valid_q <= jalr_prefetch_pending_match_i;
          outstanding_pc_q <= jalr_prefetch_pending_match_i ?
                              branch_prefetch_pc_i : {`XLEN{1'b0}};
          discard_fetch_rsp_q <= (!jalr_prefetch_pending_match_i &&
                                  outstanding_valid_q && !fetch_rsp_fire_i);
          if (jalr_prefetch_hit_available_i) begin
            next_fetch_pc_q <= jalr_prefetch_hit_packet_next_pc_i;
          end else begin
            next_fetch_pc_q <= pending_jump_target_i;
          end
        end else if (pending_mem_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          next_fetch_pc_q <= pending_mem_next_pc_i;
        end else if (pending_fp_i) begin
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          next_fetch_pc_q <= pending_fp_next_pc_i;
        end
      end

      // B2 mode=1: older backend mispredict redirect(untracked)与同拍 wrong-path 的 direct
      // dispatch flush 冲突时, untracked redirect 优先(架构真值, squash younger 投机指令)。
      // 否则 wrong-path 的 direct_branch_fire(younger beqz fall-through)会盖掉 jr/jalr 的真
      // redirect target, 使 sequential next_fetch_pc 续取 wrong-path → 取到已 squash 指令的
      // stale 源 → load access fault → CoreMark(未设 mtvec)redirect 到 0 → 卡死。
      // fetch_req(OooFetchRequestMux)已优先 untracked, 此处令 sequential next_fetch_pc 一致。
      if (direct_frontend_flush_i && branch_resolve_untracked_i &&
          !core_branch_resolve_misaligned_i) begin
        outstanding_valid_q <= fetch_req_fire_i;
        outstanding_pc_q <= fetch_req_fire_i ? fetch_req_pc_i : {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
        next_fetch_pc_q <= core_branch_resolve_next_pc_i;
      end

      if (csr_trap_mem_valid_i) begin
        outstanding_valid_q <= 1'b0;
        outstanding_pc_q <= {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_i;
        next_fetch_pc_q <= csr_trap_target_i;
      end
    end
  end

endmodule

