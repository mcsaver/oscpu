`include "define.v"

module BranchPredictor (
  input clk,
  input rst,

  input predict_valid_i,
  input [`XLEN-1:0] predict_pc_i,
  input [`INST_W-1:0] predict_inst_i,
  input [`XLEN-1:0] predict_seq_pc_i,
  output [`XLEN-1:0] predict_next_pc_o,
  output [`BPU_BHT_INDEX_W-1:0] predict_bht_idx_o,
  output predict_control_o,
  output predict_branch_o,
  output predict_jalr_o,
  output predict_ret_o,
  output predict_btb_hit_o,
  output predict_bht_valid_o,
  output predict_bht_taken_o,
  output predict_ras_lookup_o,
  output predict_ras_hit_o,
  output predict_ras_overflow_o,
  input rollback_i,

  input update_valid_i,
  input [`XLEN-1:0] update_pc_i,
  input [`INST_W-1:0] update_inst_i,
  input [`XLEN-1:0] update_seq_pc_i,
  input [`XLEN-1:0] update_next_pc_i,
  input update_taken_i,
  input [`BPU_BHT_INDEX_W-1:0] update_bht_idx_i
);

  localparam [1:0] RAS_NONE = 2'd0;
  localparam [1:0] RAS_PUSH = 2'd1;
  localparam [1:0] RAS_POP = 2'd2;
  localparam [1:0] RAS_POP_PUSH = 2'd3;
  localparam [`BPU_RAS_INDEX_W-1:0] RAS_INDEX_ONE =
      {{(`BPU_RAS_INDEX_W-1){1'b0}}, 1'b1};
  localparam [`BPU_RAS_SIZE_W-1:0] RAS_SIZE_ZERO = {`BPU_RAS_SIZE_W{1'b0}};
  localparam [`BPU_RAS_SIZE_W-1:0] RAS_SIZE_ONE =
      {{(`BPU_RAS_SIZE_W-1){1'b0}}, 1'b1};

  reg btb_valid_q [0:`BPU_BTB_ENTRIES-1];
  reg [`XLEN-1:0] btb_pc_q [0:`BPU_BTB_ENTRIES-1];
  reg [`XLEN-1:0] btb_target_q [0:`BPU_BTB_ENTRIES-1];
  reg bht_valid_q [0:`BPU_BHT_ENTRIES-1];
  reg [1:0] bht_q [0:`BPU_BHT_ENTRIES-1];
  reg [`BPU_BHT_INDEX_W-1:0] ghr_q;
  reg [`BPU_LOCAL_HISTORY_W-1:0] local_hist_q [0:`BPU_LOCAL_HISTORY_ENTRIES-1];
  reg local_pht_valid_q [0:`BPU_LOCAL_PHT_ENTRIES-1];
  reg [1:0] local_pht_q [0:`BPU_LOCAL_PHT_ENTRIES-1];
  reg [`XLEN-1:0] ras_arch_q [0:`BPU_RAS_ENTRIES-1];
  reg [`XLEN-1:0] ras_spec_q [0:`BPU_RAS_ENTRIES-1];
  reg [`BPU_RAS_SIZE_W-1:0] ras_arch_size_q;
  reg [`BPU_RAS_SIZE_W-1:0] ras_spec_size_q;
  integer bpu_i;

  /* verilator lint_off UNUSEDSIGNAL */
  function is_link_reg;
    input [4:0] reg_idx;
    begin
      is_link_reg = (reg_idx == 5'd1) || (reg_idx == 5'd5);
    end
  endfunction

  function [`XLEN-1:0] rv32_imm_b;
    input [`INST_W-1:0] inst;
    begin
      rv32_imm_b = {{(`XLEN-13){inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    end
  endfunction

  function [`XLEN-1:0] rv32_imm_j;
    input [`INST_W-1:0] inst;
    begin
      rv32_imm_j = {{(`XLEN-21){inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    end
  endfunction

  function [1:0] jalr_ras_action;
    input [4:0] rd_idx;
    input [4:0] rs1_idx;
    reg rd_link;
    reg rs1_link;
    begin
      rd_link = is_link_reg(rd_idx);
      rs1_link = is_link_reg(rs1_idx);
      if (~rd_link && ~rs1_link)
        jalr_ras_action = RAS_NONE;
      else if (~rd_link && rs1_link)
        jalr_ras_action = RAS_POP;
      else if (rd_link && ~rs1_link)
        jalr_ras_action = RAS_PUSH;
      else
        jalr_ras_action = (rd_idx == rs1_idx) ? RAS_PUSH : RAS_POP_PUSH;
    end
  endfunction

  function [1:0] ras_action;
    input [`INST_W-1:0] inst;
    begin
      case (inst[6:0])
        `OPCODE_JAL:  ras_action = is_link_reg(inst[11:7]) ? RAS_PUSH : RAS_NONE;
        `OPCODE_JALR: ras_action = jalr_ras_action(inst[11:7], inst[19:15]);
        default:      ras_action = RAS_NONE;
      endcase
    end
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */

  wire predict_is_branch_w = predict_inst_i[6:0] == `OPCODE_BRANCH;
  wire predict_is_jal_w = predict_inst_i[6:0] == `OPCODE_JAL;
  wire predict_is_jalr_w = (predict_inst_i[6:0] == `OPCODE_JALR) &&
                           (predict_inst_i[14:12] == `FUNCT3_ADD_SUB);
  wire predict_is_control_w = predict_is_branch_w | predict_is_jal_w | predict_is_jalr_w;
  wire [`BPU_BTB_INDEX_W-1:0] predict_btb_idx_w = predict_pc_i[`BPU_BTB_INDEX_W:1];
  wire [`BPU_BHT_INDEX_W-1:0] predict_pc_idx_w = predict_pc_i[`BPU_BHT_INDEX_W:1];
  wire [`BPU_BHT_INDEX_W-1:0] predict_bht_idx_w = predict_pc_idx_w ^ ghr_q;
  wire predict_btb_hit_w = btb_valid_q[predict_btb_idx_w] &&
                           (btb_pc_q[predict_btb_idx_w] == predict_pc_i);
  wire predict_bht_valid_w = bht_valid_q[predict_bht_idx_w];
  wire predict_static_taken_w = predict_inst_i[31];
  wire predict_gshare_taken_w = predict_bht_valid_w ?
                                (bht_q[predict_bht_idx_w] >= 2'd2) :
                                predict_static_taken_w;
  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] predict_local_hist_idx_w =
      predict_pc_i[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire [`BPU_LOCAL_HISTORY_W-1:0] predict_local_hist_w =
      local_hist_q[predict_local_hist_idx_w];
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] predict_local_pc_idx_w =
      predict_pc_i[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] predict_local_pht_idx_w =
      {predict_local_pc_idx_w, predict_local_hist_w};
  wire predict_local_valid_w = local_pht_valid_q[predict_local_pht_idx_w];
  wire [1:0] predict_local_ctr_w = local_pht_q[predict_local_pht_idx_w];
  wire predict_local_taken_w = predict_local_valid_w ?
                               (predict_local_ctr_w >= 2'd2) :
                               predict_static_taken_w;
  wire predict_local_strong_w = predict_local_valid_w &&
                                ((predict_local_ctr_w == 2'd0) ||
                                 (predict_local_ctr_w == 2'd3));
  // 局部历史只在强置信时覆盖 gshare，避免弱置信项扰动已稳定的全局预测。
  wire predict_dir_taken_w = predict_local_strong_w ?
                             predict_local_taken_w :
                             predict_gshare_taken_w;
  wire [1:0] predict_ras_action_w = ras_action(predict_inst_i);
  wire predict_ras_uses_top_w = (predict_ras_action_w == RAS_POP) ||
                                (predict_ras_action_w == RAS_POP_PUSH);
  wire predict_ras_hit_w = predict_ras_uses_top_w && (ras_spec_size_q != RAS_SIZE_ZERO);
  wire predict_ras_overflow_w = (predict_ras_action_w == RAS_PUSH) &&
                                (ras_spec_size_q == `BPU_RAS_DEPTH);
  wire [`BPU_RAS_INDEX_W-1:0] ras_spec_top_idx_w =
      ras_spec_size_q[`BPU_RAS_INDEX_W-1:0] - RAS_INDEX_ONE;
  wire [`BPU_RAS_INDEX_W-1:0] ras_spec_push_idx_w =
      ras_spec_size_q[`BPU_RAS_INDEX_W-1:0];
  wire [`BPU_RAS_INDEX_W-1:0] ras_arch_top_idx_w =
      ras_arch_size_q[`BPU_RAS_INDEX_W-1:0] - RAS_INDEX_ONE;
  wire [`BPU_RAS_INDEX_W-1:0] ras_arch_push_idx_w =
      ras_arch_size_q[`BPU_RAS_INDEX_W-1:0];
  wire [`XLEN-1:0] predict_branch_target_w = predict_pc_i + rv32_imm_b(predict_inst_i);
  wire [`XLEN-1:0] predict_jal_target_w = predict_pc_i + rv32_imm_j(predict_inst_i);
  wire [`XLEN-1:0] predict_jalr_target_w =
      predict_ras_hit_w ? ras_spec_q[ras_spec_top_idx_w] :
      predict_btb_hit_w ? btb_target_q[predict_btb_idx_w] :
                          predict_seq_pc_i;
  wire [`XLEN-1:0] predict_next_pc_w =
      predict_is_branch_w ? (predict_dir_taken_w ? predict_branch_target_w : predict_seq_pc_i) :
      predict_is_jal_w ? predict_jal_target_w :
      predict_is_jalr_w ? predict_jalr_target_w :
      predict_seq_pc_i;

  wire update_is_branch_w = update_inst_i[6:0] == `OPCODE_BRANCH;
  wire update_is_control_w = update_is_branch_w ||
                             (update_inst_i[6:0] == `OPCODE_JAL) ||
                             (update_inst_i[6:0] == `OPCODE_JALR);
  wire [`BPU_BTB_INDEX_W-1:0] update_btb_idx_w = update_pc_i[`BPU_BTB_INDEX_W:1];
  wire [`BPU_BHT_INDEX_W-1:0] update_bht_idx_w = update_bht_idx_i;
  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] update_local_hist_idx_w =
      update_pc_i[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire [`BPU_LOCAL_HISTORY_W-1:0] update_local_hist_w =
      local_hist_q[update_local_hist_idx_w];
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] update_local_pc_idx_w =
      update_pc_i[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] update_local_pht_idx_w =
      {update_local_pc_idx_w, update_local_hist_w};
  wire [1:0] update_ras_action_w = ras_action(update_inst_i);

  assign predict_next_pc_o = predict_valid_i ? predict_next_pc_w : predict_seq_pc_i;
  assign predict_bht_idx_o = predict_bht_idx_w;
  assign predict_control_o = predict_is_control_w;
  assign predict_branch_o = predict_is_branch_w;
  assign predict_jalr_o = predict_is_jalr_w;
  assign predict_ret_o = predict_is_jalr_w && predict_ras_uses_top_w;
  assign predict_btb_hit_o = predict_btb_hit_w;
  assign predict_bht_valid_o = predict_bht_valid_w;
  assign predict_bht_taken_o = predict_dir_taken_w;
  assign predict_ras_lookup_o = predict_is_jalr_w && predict_ras_uses_top_w;
  assign predict_ras_hit_o = predict_ras_hit_w;
  assign predict_ras_overflow_o = predict_ras_overflow_w;

  /* verilator lint_off BLKSEQ */
  always @(posedge clk) begin
    if (rst) begin
      ras_arch_size_q <= RAS_SIZE_ZERO;
      ras_spec_size_q <= RAS_SIZE_ZERO;
      ghr_q <= {`BPU_BHT_INDEX_W{1'b0}};
      for (bpu_i = 0; bpu_i < `BPU_BTB_ENTRIES; bpu_i = bpu_i + 1) begin
        btb_valid_q[bpu_i] = 1'b0;
        btb_pc_q[bpu_i] = {`XLEN{1'b0}};
        btb_target_q[bpu_i] = {`XLEN{1'b0}};
      end
      for (bpu_i = 0; bpu_i < `BPU_BHT_ENTRIES; bpu_i = bpu_i + 1) begin
        bht_valid_q[bpu_i] = 1'b0;
        // 复位后计数器从弱跳转开始；valid 仍为 0，首轮 cold 预测继续交给 BTFNT。
        bht_q[bpu_i] = `BPU_COUNTER_INIT;
      end
      for (bpu_i = 0; bpu_i < `BPU_LOCAL_HISTORY_ENTRIES; bpu_i = bpu_i + 1) begin
        local_hist_q[bpu_i] = {`BPU_LOCAL_HISTORY_W{1'b0}};
      end
      for (bpu_i = 0; bpu_i < `BPU_LOCAL_PHT_ENTRIES; bpu_i = bpu_i + 1) begin
        local_pht_valid_q[bpu_i] = 1'b0;
        local_pht_q[bpu_i] = `BPU_COUNTER_INIT;
      end
      for (bpu_i = 0; bpu_i < `BPU_RAS_ENTRIES; bpu_i = bpu_i + 1) begin
        ras_arch_q[bpu_i] = {`XLEN{1'b0}};
        ras_spec_q[bpu_i] = {`XLEN{1'b0}};
      end
    end else begin
      if (update_valid_i && update_is_control_w) begin
        if (update_is_branch_w) begin
          // gshare 用预测时携带下来的 index 更新，避免 EX 阶段 GHR 漂移训练错表项。
          bht_valid_q[update_bht_idx_w] <= 1'b1;
          if (update_taken_i) begin
            if (bht_q[update_bht_idx_w] != 2'd3)
              bht_q[update_bht_idx_w] <= bht_q[update_bht_idx_w] + 2'd1;
          end else if (bht_q[update_bht_idx_w] != 2'd0) begin
            bht_q[update_bht_idx_w] <= bht_q[update_bht_idx_w] - 2'd1;
          end
          ghr_q <= {ghr_q[`BPU_BHT_INDEX_W-2:0], update_taken_i};

          // local PHT 混入更多 PC 位，减少 CoreMark 字符状态机多分支共用同一 history 时的别名。
          local_pht_valid_q[update_local_pht_idx_w] <= 1'b1;
          if (update_taken_i) begin
            if (local_pht_q[update_local_pht_idx_w] != 2'd3)
              local_pht_q[update_local_pht_idx_w] <= local_pht_q[update_local_pht_idx_w] + 2'd1;
          end else if (local_pht_q[update_local_pht_idx_w] != 2'd0) begin
            local_pht_q[update_local_pht_idx_w] <= local_pht_q[update_local_pht_idx_w] - 2'd1;
          end
          local_hist_q[update_local_hist_idx_w] <=
              {update_local_hist_w[`BPU_LOCAL_HISTORY_W-2:0], update_taken_i};
        end

        if (update_taken_i) begin
          btb_valid_q[update_btb_idx_w] <= 1'b1;
          btb_pc_q[update_btb_idx_w] <= update_pc_i;
          btb_target_q[update_btb_idx_w] <= update_next_pc_i;
        end

        case (update_ras_action_w)
          RAS_PUSH: begin
            if (ras_arch_size_q == `BPU_RAS_DEPTH) begin
              for (bpu_i = 0; bpu_i < `BPU_RAS_ENTRIES - 1; bpu_i = bpu_i + 1)
                ras_arch_q[bpu_i] <= ras_arch_q[bpu_i + 1];
              ras_arch_q[`BPU_RAS_ENTRIES-1] <= update_seq_pc_i;
            end else begin
              ras_arch_q[ras_arch_push_idx_w] <= update_seq_pc_i;
              ras_arch_size_q <= ras_arch_size_q + RAS_SIZE_ONE;
            end
          end
          RAS_POP: begin
            if (ras_arch_size_q != RAS_SIZE_ZERO)
              ras_arch_size_q <= ras_arch_size_q - RAS_SIZE_ONE;
          end
          RAS_POP_PUSH: begin
            if (ras_arch_size_q == RAS_SIZE_ZERO) begin
              ras_arch_q[0] <= update_seq_pc_i;
              ras_arch_size_q <= RAS_SIZE_ONE;
            end else begin
              ras_arch_q[ras_arch_top_idx_w] <= update_seq_pc_i;
            end
          end
          default: begin end
        endcase
      end

      if (rollback_i) begin
        // flush 会丢弃所有 younger 预测，spec RAS 回到已解析边界；若同拍 EX 有 control update，则包含该 update 的效果。
        ras_spec_size_q <= ras_arch_size_q;
        for (bpu_i = 0; bpu_i < `BPU_RAS_ENTRIES; bpu_i = bpu_i + 1)
          ras_spec_q[bpu_i] <= ras_arch_q[bpu_i];

        if (update_valid_i && update_is_control_w) begin
          case (update_ras_action_w)
            RAS_PUSH: begin
              if (ras_arch_size_q == `BPU_RAS_DEPTH) begin
                for (bpu_i = 0; bpu_i < `BPU_RAS_ENTRIES - 1; bpu_i = bpu_i + 1)
                  ras_spec_q[bpu_i] <= ras_arch_q[bpu_i + 1];
                ras_spec_q[`BPU_RAS_ENTRIES-1] <= update_seq_pc_i;
              end else begin
                ras_spec_q[ras_arch_push_idx_w] <= update_seq_pc_i;
                ras_spec_size_q <= ras_arch_size_q + RAS_SIZE_ONE;
              end
            end
            RAS_POP: begin
              if (ras_arch_size_q != RAS_SIZE_ZERO)
                ras_spec_size_q <= ras_arch_size_q - RAS_SIZE_ONE;
            end
            RAS_POP_PUSH: begin
              if (ras_arch_size_q == RAS_SIZE_ZERO) begin
                ras_spec_q[0] <= update_seq_pc_i;
                ras_spec_size_q <= RAS_SIZE_ONE;
              end else begin
                ras_spec_q[ras_arch_top_idx_w] <= update_seq_pc_i;
              end
            end
            default: begin end
          endcase
        end
      end else if (predict_valid_i) begin
        case (predict_ras_action_w)
          RAS_PUSH: begin
            if (ras_spec_size_q == `BPU_RAS_DEPTH) begin
              for (bpu_i = 0; bpu_i < `BPU_RAS_ENTRIES - 1; bpu_i = bpu_i + 1)
                ras_spec_q[bpu_i] <= ras_spec_q[bpu_i + 1];
              ras_spec_q[`BPU_RAS_ENTRIES-1] <= predict_seq_pc_i;
            end else begin
              ras_spec_q[ras_spec_push_idx_w] <= predict_seq_pc_i;
              ras_spec_size_q <= ras_spec_size_q + RAS_SIZE_ONE;
            end
          end
          RAS_POP: begin
            if (ras_spec_size_q != RAS_SIZE_ZERO)
              ras_spec_size_q <= ras_spec_size_q - RAS_SIZE_ONE;
          end
          RAS_POP_PUSH: begin
            if (ras_spec_size_q == RAS_SIZE_ZERO) begin
              ras_spec_q[0] <= predict_seq_pc_i;
              ras_spec_size_q <= RAS_SIZE_ONE;
            end else begin
              ras_spec_q[ras_spec_top_idx_w] <= predict_seq_pc_i;
            end
          end
          default: begin end
        endcase
      end
    end
  end
  /* verilator lint_on BLKSEQ */

endmodule
