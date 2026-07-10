`include "define.v"

// Encodes redirect/recovery events into fetch-packet FIFO clear/seed actions.
// Event predicates and packet validation stay in OooCoreTopGlue.
module OooFetchPacketSeedMux (
  input csr_trap_i,
  input direct_flush_i,
  input fallthrough_capture_i,
  input branch_spec_restore_i,
  input pending_branch_commit_resolve_i,
  input pending_branch_match_i,
  input pending_branch_misaligned_i,
  input branch_prefetch_hit_i,
  input branch_resolve_untracked_i,
  input pending_jump_resolve_i,
  input pending_jump_misaligned_i,
  input pending_jump_redirect_i,
  input pending_mem_resolve_i,
  input system_csr_dispatch_i,
  input pending_system_csr_commit_i,
  input head0_csr_commit_i,   // 【serialize Phase1】head0-CSR 队头提交拍清前端 FIFO(redirect 由 pc-seq 驱动)
  input drain_complete_i,
  input drain_pending_arch_trap_i,
  input drain_pending_system_i,
  input drain_pending_branch_undispatched_i,
  input drain_pending_jump_i,
  input drain_pending_mem_i,
  input jalr_prefetch_hit_i,

  input [`XLEN-1:0] fallthrough_pc0_i,
  input [`XLEN-1:0] fallthrough_pc1_i,
  input [`XLEN-1:0] fallthrough_next_pc0_i,
  input [`XLEN-1:0] fallthrough_next_pc1_i,
  input [`XLEN-1:0] fallthrough_packet_next_pc_i,
  input [`INST_W-1:0] fallthrough_inst0_i,
  input [`INST_W-1:0] fallthrough_inst1_i,
  input [1:0] fallthrough_resp0_i,
  input [1:0] fallthrough_resp1_i,
  // 【B2 S1】fallthrough capture 的预测位: payload 与 enqueue 同拍同包(fetch_dec*),
  // 直接跟随 resp 拍 BPU lookup 组合输出——与 enqueue 路径机械同源, 预测一次定格。
  input fallthrough_pred_taken0_i,
  input fallthrough_pred_taken1_i,
  input [`BPU_BHT_INDEX_W-1:0] fallthrough_bht_idx0_i,
  input [`BPU_BHT_INDEX_W-1:0] fallthrough_bht_idx1_i,
  input fallthrough_bht_valid0_i,
  input fallthrough_bht_valid1_i,

  input [`XLEN-1:0] branch_pc0_i,
  input [`XLEN-1:0] branch_pc1_i,
  input [`XLEN-1:0] branch_next_pc0_i,
  input [`XLEN-1:0] branch_next_pc1_i,
  input [`XLEN-1:0] branch_packet_next_pc_i,
  input [`INST_W-1:0] branch_inst0_i,
  input [`INST_W-1:0] branch_inst1_i,
  input [1:0] branch_resp0_i,
  input [1:0] branch_resp1_i,

  input [`XLEN-1:0] jalr_pc0_i,
  input [`XLEN-1:0] jalr_pc1_i,
  input [`XLEN-1:0] jalr_next_pc0_i,
  input [`XLEN-1:0] jalr_next_pc1_i,
  input [`XLEN-1:0] jalr_packet_next_pc_i,
  input [`INST_W-1:0] jalr_inst0_i,
  input [`INST_W-1:0] jalr_inst1_i,
  input [1:0] jalr_resp0_i,
  input [1:0] jalr_resp1_i,

  output reg clear_o,
  output reg seed_valid_o,
  output reg [`XLEN-1:0] seed_pc0_o,
  output reg [`XLEN-1:0] seed_pc1_o,
  output reg [`XLEN-1:0] seed_next_pc0_o,
  output reg [`XLEN-1:0] seed_next_pc1_o,
  output reg [`XLEN-1:0] seed_packet_next_pc_o,
  output reg [`INST_W-1:0] seed_inst0_o,
  output reg [`INST_W-1:0] seed_inst1_o,
  output reg [1:0] seed_resp0_o,
  output reg [1:0] seed_resp1_o,
  output reg seed_pred_taken0_o,
  output reg seed_pred_taken1_o,
  output reg [`BPU_BHT_INDEX_W-1:0] seed_bht_idx0_o,
  output reg [`BPU_BHT_INDEX_W-1:0] seed_bht_idx1_o,
  output reg seed_bht_valid0_o,
  output reg seed_bht_valid1_o
);

  task set_seed;
    input [`XLEN-1:0] pc0;
    input [`XLEN-1:0] pc1;
    input [`XLEN-1:0] next_pc0;
    input [`XLEN-1:0] next_pc1;
    input [`XLEN-1:0] packet_next_pc;
    input [`INST_W-1:0] inst0;
    input [`INST_W-1:0] inst1;
    input [1:0] resp0;
    input [1:0] resp1;
    input pred_taken0;
    input pred_taken1;
    input [`BPU_BHT_INDEX_W-1:0] bht_idx0;
    input [`BPU_BHT_INDEX_W-1:0] bht_idx1;
    input bht_valid0;
    input bht_valid1;
    begin
      clear_o = 1'b0;
      seed_valid_o = 1'b1;
      seed_pc0_o = pc0;
      seed_pc1_o = pc1;
      seed_next_pc0_o = next_pc0;
      seed_next_pc1_o = next_pc1;
      seed_packet_next_pc_o = packet_next_pc;
      seed_inst0_o = inst0;
      seed_inst1_o = inst1;
      seed_resp0_o = resp0;
      seed_resp1_o = resp1;
      seed_pred_taken0_o = pred_taken0;
      seed_pred_taken1_o = pred_taken1;
      seed_bht_idx0_o = bht_idx0;
      seed_bht_idx1_o = bht_idx1;
      seed_bht_valid0_o = bht_valid0;
      seed_bht_valid1_o = bht_valid1;
    end
  endtask

  task set_clear;
    begin
      clear_o = 1'b1;
      seed_valid_o = 1'b0;
    end
  endtask

  always @* begin
    clear_o = 1'b0;
    seed_valid_o = 1'b0;
    seed_pc0_o = {`XLEN{1'b0}};
    seed_pc1_o = {`XLEN{1'b0}};
    seed_next_pc0_o = {`XLEN{1'b0}};
    seed_next_pc1_o = {`XLEN{1'b0}};
    seed_packet_next_pc_o = {`XLEN{1'b0}};
    seed_inst0_o = {`INST_W{1'b0}};
    seed_inst1_o = {`INST_W{1'b0}};
    seed_resp0_o = 2'b00;
    seed_resp1_o = 2'b00;
    seed_pred_taken0_o = 1'b0;
    seed_pred_taken1_o = 1'b0;
    seed_bht_idx0_o = {`BPU_BHT_INDEX_W{1'b0}};
    seed_bht_idx1_o = {`BPU_BHT_INDEX_W{1'b0}};
    seed_bht_valid0_o = 1'b0;
    seed_bht_valid1_o = 1'b0;

    if (csr_trap_i) begin
      set_clear;
    end else if (direct_flush_i) begin
      set_clear;
      if (fallthrough_capture_i) begin
        set_seed(fallthrough_pc0_i, fallthrough_pc1_i,
                 fallthrough_next_pc0_i, fallthrough_next_pc1_i,
                 fallthrough_packet_next_pc_i, fallthrough_inst0_i,
                 fallthrough_inst1_i, fallthrough_resp0_i,
                 fallthrough_resp1_i,
                 fallthrough_pred_taken0_i, fallthrough_pred_taken1_i,
                 fallthrough_bht_idx0_i, fallthrough_bht_idx1_i,
                 fallthrough_bht_valid0_i, fallthrough_bht_valid1_i);
      end
    end

    if (!direct_flush_i && branch_spec_restore_i) begin
      set_clear;
    end

    if (pending_branch_commit_resolve_i) begin
      set_clear;
    end else if (!direct_flush_i && pending_branch_match_i) begin
      if (pending_branch_misaligned_i) begin
        set_clear;
      end else if (branch_prefetch_hit_i) begin
        // 死硅臂(hit 恒0): 预测位=静态 not-taken 安全值 0。
        set_seed(branch_pc0_i, branch_pc1_i, branch_next_pc0_i,
                 branch_next_pc1_i, branch_packet_next_pc_i, branch_inst0_i,
                 branch_inst1_i, branch_resp0_i, branch_resp1_i,
                 1'b0, 1'b0, {`BPU_BHT_INDEX_W{1'b0}},
                 {`BPU_BHT_INDEX_W{1'b0}}, 1'b0, 1'b0);
      end else begin
        set_clear;
      end
    end else if (!direct_flush_i && branch_resolve_untracked_i) begin
      set_clear;
    end else if (!direct_flush_i && pending_jump_resolve_i) begin
      if (pending_jump_misaligned_i) begin
        set_clear;
      end else if (pending_jump_redirect_i) begin
        if (jalr_prefetch_hit_i) begin
          // 死硅臂(hit 恒0): 预测位=静态 not-taken 安全值 0。
          set_seed(jalr_pc0_i, jalr_pc1_i, jalr_next_pc0_i,
                   jalr_next_pc1_i, jalr_packet_next_pc_i, jalr_inst0_i,
                   jalr_inst1_i, jalr_resp0_i, jalr_resp1_i,
                   1'b0, 1'b0, {`BPU_BHT_INDEX_W{1'b0}},
                   {`BPU_BHT_INDEX_W{1'b0}}, 1'b0, 1'b0);
        end else begin
          set_clear;
        end
      end
    end else if (!direct_flush_i && pending_mem_resolve_i) begin
      // LSU replay dispatch does not change front-end FIFO storage.
    end else if (!direct_flush_i && system_csr_dispatch_i) begin
      // CSR dispatch waits for commit before the front-end FIFO is cleared.
    end else if (!direct_flush_i &&
        (pending_system_csr_commit_i || head0_csr_commit_i)) begin
      // head0-CSR(队头路)与 lane1-drain CSR 互斥, 同 set_clear: 清 FIFO, 重取由 pc-seq next_fetch_pc 驱动。
      set_clear;
    end else if (!csr_trap_i && !direct_flush_i && drain_complete_i) begin
      if (drain_pending_arch_trap_i) begin
        set_clear;
      end else if (drain_pending_system_i) begin
        set_clear;
      end else if (drain_pending_branch_undispatched_i) begin
        set_clear;
      end else if (drain_pending_jump_i) begin
        if (jalr_prefetch_hit_i) begin
          // 死硅臂(hit 恒0): 预测位=静态 not-taken 安全值 0。
          set_seed(jalr_pc0_i, jalr_pc1_i, jalr_next_pc0_i,
                   jalr_next_pc1_i, jalr_packet_next_pc_i, jalr_inst0_i,
                   jalr_inst1_i, jalr_resp0_i, jalr_resp1_i,
                   1'b0, 1'b0, {`BPU_BHT_INDEX_W{1'b0}},
                   {`BPU_BHT_INDEX_W{1'b0}}, 1'b0, 1'b0);
        end else begin
          set_clear;
        end
      end else if (drain_pending_mem_i) begin
        set_clear;
      end
    end

    if (csr_trap_i) begin
      set_clear;
    end
  end

endmodule
