`include "define.v"

module BranchPredictor (
  input clk,
  input rst,

  input predict_valid_i,
  input [`XLEN-1:0] predict_pc_i,
  input [`INST_W-1:0] predict_inst_i,
  input [`XLEN-1:0] predict_seq_pc_i,
  output [`XLEN-1:0] predict_next_pc_o,

  input update_valid_i,
  input [`XLEN-1:0] update_pc_i,
  input [`INST_W-1:0] update_inst_i,
  input [`XLEN-1:0] update_seq_pc_i,
  input [`XLEN-1:0] update_next_pc_i,
  input update_taken_i
);

  localparam BPU_BTB_ENTRIES = 128;
  localparam BPU_BHT_ENTRIES = 256;
  localparam BPU_RAS_ENTRIES = 16;
  localparam [4:0] BPU_RAS_DEPTH = 5'd16;

  localparam [1:0] RAS_NONE = 2'd0;
  localparam [1:0] RAS_PUSH = 2'd1;
  localparam [1:0] RAS_POP = 2'd2;
  localparam [1:0] RAS_POP_PUSH = 2'd3;

  reg btb_valid_q [0:BPU_BTB_ENTRIES-1];
  reg [`XLEN-1:0] btb_pc_q [0:BPU_BTB_ENTRIES-1];
  reg [`XLEN-1:0] btb_target_q [0:BPU_BTB_ENTRIES-1];
  reg [1:0] bht_q [0:BPU_BHT_ENTRIES-1];
  reg [`XLEN-1:0] ras_q [0:BPU_RAS_ENTRIES-1];
  reg [4:0] ras_size_q;
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
      rv32_imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
    end
  endfunction

  function [`XLEN-1:0] rv32_imm_j;
    input [`INST_W-1:0] inst;
    begin
      rv32_imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
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
  wire [6:0] predict_btb_idx_w = predict_pc_i[7:1];
  wire [7:0] predict_bht_idx_w = predict_pc_i[8:1];
  wire predict_btb_hit_w = btb_valid_q[predict_btb_idx_w] &&
                           (btb_pc_q[predict_btb_idx_w] == predict_pc_i);
  wire predict_bht_taken_w = bht_q[predict_bht_idx_w] >= 2'd2;
  wire [1:0] predict_ras_action_w = ras_action(predict_inst_i);
  wire predict_ras_uses_top_w = (predict_ras_action_w == RAS_POP) ||
                                (predict_ras_action_w == RAS_POP_PUSH);
  wire predict_ras_hit_w = predict_ras_uses_top_w && (ras_size_q != 5'd0);
  wire [3:0] ras_top_idx_w = ras_size_q[3:0] - 4'd1;
  wire [3:0] ras_push_idx_w = ras_size_q[3:0];
  wire [`XLEN-1:0] predict_branch_target_w = predict_pc_i + rv32_imm_b(predict_inst_i);
  wire [`XLEN-1:0] predict_jal_target_w = predict_pc_i + rv32_imm_j(predict_inst_i);
  wire [`XLEN-1:0] predict_jalr_target_w =
      predict_ras_hit_w ? ras_q[ras_top_idx_w] :
      predict_btb_hit_w ? btb_target_q[predict_btb_idx_w] :
                          predict_seq_pc_i;
  wire [`XLEN-1:0] predict_next_pc_w =
      predict_is_branch_w ? (predict_bht_taken_w ? predict_branch_target_w : predict_seq_pc_i) :
      predict_is_jal_w ? predict_jal_target_w :
      predict_is_jalr_w ? predict_jalr_target_w :
      predict_seq_pc_i;

  wire update_is_branch_w = update_inst_i[6:0] == `OPCODE_BRANCH;
  wire update_is_control_w = update_is_branch_w ||
                             (update_inst_i[6:0] == `OPCODE_JAL) ||
                             (update_inst_i[6:0] == `OPCODE_JALR);
  wire [6:0] update_btb_idx_w = update_pc_i[7:1];
  wire [7:0] update_bht_idx_w = update_pc_i[8:1];
  wire [1:0] update_ras_action_w = ras_action(update_inst_i);

  assign predict_next_pc_o = predict_valid_i ? predict_next_pc_w : predict_seq_pc_i;

  /* verilator lint_off BLKSEQ */
  always @(posedge clk) begin
    if (rst) begin
      ras_size_q <= 5'd0;
      for (bpu_i = 0; bpu_i < BPU_BTB_ENTRIES; bpu_i = bpu_i + 1) begin
        btb_valid_q[bpu_i] = 1'b0;
        btb_pc_q[bpu_i] = {`XLEN{1'b0}};
        btb_target_q[bpu_i] = {`XLEN{1'b0}};
      end
      for (bpu_i = 0; bpu_i < BPU_BHT_ENTRIES; bpu_i = bpu_i + 1) begin
        bht_q[bpu_i] = 2'd1;
      end
      for (bpu_i = 0; bpu_i < BPU_RAS_ENTRIES; bpu_i = bpu_i + 1) begin
        ras_q[bpu_i] = {`XLEN{1'b0}};
      end
    end else if (update_valid_i && update_is_control_w) begin
      if (update_is_branch_w) begin
        if (update_taken_i) begin
          if (bht_q[update_bht_idx_w] != 2'd3)
            bht_q[update_bht_idx_w] <= bht_q[update_bht_idx_w] + 2'd1;
        end else if (bht_q[update_bht_idx_w] != 2'd0) begin
          bht_q[update_bht_idx_w] <= bht_q[update_bht_idx_w] - 2'd1;
        end
      end

      if (update_taken_i) begin
        btb_valid_q[update_btb_idx_w] <= 1'b1;
        btb_pc_q[update_btb_idx_w] <= update_pc_i;
        btb_target_q[update_btb_idx_w] <= update_next_pc_i;
      end

      case (update_ras_action_w)
        RAS_PUSH: begin
          if (ras_size_q == BPU_RAS_DEPTH) begin
            for (bpu_i = 0; bpu_i < BPU_RAS_ENTRIES - 1; bpu_i = bpu_i + 1)
              ras_q[bpu_i] = ras_q[bpu_i + 1];
            ras_q[BPU_RAS_ENTRIES-1] <= update_seq_pc_i;
          end else begin
            ras_q[ras_push_idx_w] <= update_seq_pc_i;
            ras_size_q <= ras_size_q + 5'd1;
          end
        end
        RAS_POP: begin
          if (ras_size_q != 5'd0)
            ras_size_q <= ras_size_q - 5'd1;
        end
        RAS_POP_PUSH: begin
          if (ras_size_q == 5'd0) begin
            ras_q[0] <= update_seq_pc_i;
            ras_size_q <= 5'd1;
          end else begin
            ras_q[ras_top_idx_w] <= update_seq_pc_i;
          end
        end
        default: begin end
      endcase
    end
  end
  /* verilator lint_on BLKSEQ */

endmodule
