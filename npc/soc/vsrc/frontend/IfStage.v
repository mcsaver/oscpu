`include "define.v"

module IfStage (
  input clk,
  input rst,

  input flush_i,
  input redirect_valid_i,
  input [`XLEN-1:0] redirect_pc_i,
  input pipe_ready_i,
  input halt_i,
  input fatal_i,
  input bpu_update_valid_i,
  input [`XLEN-1:0] bpu_update_pc_i,
  input [`INST_W-1:0] bpu_update_inst_i,
  input [`XLEN-1:0] bpu_update_seq_pc_i,
  input [`XLEN-1:0] bpu_update_next_pc_i,
  input bpu_update_taken_i,
  input [`BPU_BHT_INDEX_W-1:0] bpu_update_bht_idx_i,

  output pipe_valid_o,
  output [`XLEN-1:0] pipe_pc_o,
  output [`INST_W-1:0] pipe_inst_o,
  output [`XLEN-1:0] pipe_inst_len_o,
  output [`XLEN-1:0] pipe_pred_pc_o,
  output [`BPU_BHT_INDEX_W-1:0] pipe_bht_idx_o,
  output pipe_error_o,

  output ifu_req_valid_o,
  input ifu_req_ready_i,
  output [`XLEN-1:0] ifu_req_addr_o,
  input ifu_rsp_valid_i,
  output ifu_rsp_ready_o,
  input [`XLEN-1:0] ifu_rsp_data_i,
  input ifu_rsp_error_i,

  output [`XLEN-1:0] fetch_pc_o,
  output fetch_pending_o
);

  reg fetch_pending_q;
  reg [`XLEN-1:0] fetch_pc_q;
  reg [`XLEN-1:0] fetch_req_pc_q;

  reg fetch_buf_valid_q;
  reg [`XLEN-1:0] fetch_buf_pc_q;
  reg [`INST_W-1:0] fetch_buf_inst_q;
  reg [`XLEN-1:0] fetch_buf_inst_len_q;
  reg [`XLEN-1:0] fetch_buf_pred_pc_q;
  reg [`BPU_BHT_INDEX_W-1:0] fetch_buf_bht_idx_q;
  reg fetch_buf_error_q;

  /* verilator lint_off UNUSEDSIGNAL */
  function [`INST_W-1:0] enc_r;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
      enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    end
  endfunction

  function [`INST_W-1:0] enc_i;
    input [11:0] imm;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    input [6:0] opcode;
    begin
      enc_i = {imm, rs1, funct3, rd, opcode};
    end
  endfunction

  function [`INST_W-1:0] enc_s;
    input [11:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    begin
      enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], `OPCODE_STORE};
    end
  endfunction

  function [`INST_W-1:0] enc_b;
    input [12:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    begin
      enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], `OPCODE_BRANCH};
    end
  endfunction

  function [`INST_W-1:0] enc_u;
    input [19:0] imm;
    input [4:0] rd;
    input [6:0] opcode;
    begin
      enc_u = {imm, rd, opcode};
    end
  endfunction

  function [`INST_W-1:0] enc_j;
    input [20:0] imm;
    input [4:0] rd;
    begin
      enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, `OPCODE_JAL};
    end
  endfunction

  function [4:0] rvc_rdp;
    input [15:0] inst;
    begin
      rvc_rdp = {2'b01, inst[4:2]};
    end
  endfunction

  function [4:0] rvc_rs1p;
    input [15:0] inst;
    begin
      rvc_rs1p = {2'b01, inst[9:7]};
    end
  endfunction

  function [4:0] rvc_rs2p;
    input [15:0] inst;
    begin
      rvc_rs2p = {2'b01, inst[4:2]};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_addi4spn;
    input [15:0] inst;
    begin
      rvc_imm_addi4spn = {22'b0, inst[10:7], inst[12:11], inst[5], inst[6], 2'b00};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_lw_sw;
    input [15:0] inst;
    begin
      rvc_imm_lw_sw = {25'b0, inst[5], inst[12:10], inst[6], 2'b00};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_6;
    input [15:0] inst;
    begin
      rvc_imm_6 = {{26{inst[12]}}, inst[12], inst[6:2]};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_j;
    input [15:0] inst;
    begin
      rvc_imm_j = {{20{inst[12]}}, inst[12], inst[8], inst[10:9],
                   inst[6], inst[7], inst[2], inst[11], inst[5:3], 1'b0};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_addi16sp;
    input [15:0] inst;
    begin
      rvc_imm_addi16sp = {{22{inst[12]}}, inst[12], inst[4:3], inst[5],
                          inst[2], inst[6], 4'b0000};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_b;
    input [15:0] inst;
    begin
      rvc_imm_b = {{23{inst[12]}}, inst[12], inst[6:5], inst[2],
                   inst[11:10], inst[4:3], 1'b0};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_lwsp;
    input [15:0] inst;
    begin
      rvc_imm_lwsp = {24'b0, inst[3:2], inst[12], inst[6:4], 2'b00};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_swsp;
    input [15:0] inst;
    begin
      rvc_imm_swsp = {24'b0, inst[8:7], inst[12:9], 2'b00};
    end
  endfunction

  function [5:0] rvc_shamt;
    input [15:0] inst;
    begin
      rvc_shamt = {inst[12], inst[6:2]};
    end
  endfunction

  function [`INST_W-1:0] decompress_rvc;
    input [15:0] inst;
    reg [`XLEN-1:0] imm;
    reg [4:0] rd;
    reg [4:0] rs2;
    reg [4:0] rs1p;
    reg [4:0] rs2p;
    reg [5:0] shamt;
    begin
      decompress_rvc = 32'h0000_0000;
      rd = inst[11:7];
      rs2 = inst[6:2];
      rs1p = rvc_rs1p(inst);
      rs2p = rvc_rs2p(inst);
      shamt = rvc_shamt(inst);

      case (inst[1:0])
        2'b00: begin
          case (inst[15:13])
            3'b000: begin
              imm = rvc_imm_addi4spn(inst);
              if (imm != {`XLEN{1'b0}})
                decompress_rvc = enc_i(imm[11:0], 5'd2, `FUNCT3_ADD_SUB, rvc_rdp(inst), `OPCODE_OP_IMM);
            end
            3'b010: begin
              imm = rvc_imm_lw_sw(inst);
              decompress_rvc = enc_i(imm[11:0], rs1p, `FUNCT3_LW, rvc_rdp(inst), `OPCODE_LOAD);
            end
            3'b110: begin
              imm = rvc_imm_lw_sw(inst);
              decompress_rvc = enc_s(imm[11:0], rs2p, rs1p, `FUNCT3_SW);
            end
            default: begin end
          endcase
        end

        2'b01: begin
          case (inst[15:13])
            3'b000: begin
              imm = rvc_imm_6(inst);
              decompress_rvc = enc_i(imm[11:0], rd, `FUNCT3_ADD_SUB, rd, `OPCODE_OP_IMM);
            end
            3'b001: begin
              imm = rvc_imm_j(inst);
              decompress_rvc = enc_j(imm[20:0], 5'd1);
            end
            3'b010: begin
              imm = rvc_imm_6(inst);
              decompress_rvc = enc_i(imm[11:0], 5'd0, `FUNCT3_ADD_SUB, rd, `OPCODE_OP_IMM);
            end
            3'b011: begin
              if (rd == 5'd2) begin
                imm = rvc_imm_addi16sp(inst);
                if (imm != {`XLEN{1'b0}})
                  decompress_rvc = enc_i(imm[11:0], 5'd2, `FUNCT3_ADD_SUB, 5'd2, `OPCODE_OP_IMM);
              end else begin
                imm = rvc_imm_6(inst);
                if ((rd != 5'd0) && (imm != {`XLEN{1'b0}}))
                  decompress_rvc = enc_u(imm[19:0], rd, `OPCODE_LUI);
              end
            end
            3'b100: begin
              case (inst[11:10])
                2'b00: begin
                  if (inst[12] == 1'b0)
                    decompress_rvc = enc_i({7'h00, shamt[4:0]}, rs1p, `FUNCT3_SRL_SRA, rs1p, `OPCODE_OP_IMM);
                end
                2'b01: begin
                  if (inst[12] == 1'b0)
                    decompress_rvc = enc_i({7'h20, shamt[4:0]}, rs1p, `FUNCT3_SRL_SRA, rs1p, `OPCODE_OP_IMM);
                end
                2'b10: begin
                  imm = rvc_imm_6(inst);
                  decompress_rvc = enc_i(imm[11:0], rs1p, `FUNCT3_AND, rs1p, `OPCODE_OP_IMM);
                end
                2'b11: begin
                  if (inst[12] == 1'b0) begin
                    case (inst[6:5])
                      2'b00: decompress_rvc = enc_r(`FUNCT7_ALT, rs2p, rs1p, `FUNCT3_ADD_SUB, rs1p, `OPCODE_OP);
                      2'b01: decompress_rvc = enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_XOR, rs1p, `OPCODE_OP);
                      2'b10: decompress_rvc = enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_OR, rs1p, `OPCODE_OP);
                      2'b11: decompress_rvc = enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_AND, rs1p, `OPCODE_OP);
                      default: begin end
                    endcase
                  end
                end
                default: begin end
              endcase
            end
            3'b101: begin
              imm = rvc_imm_j(inst);
              decompress_rvc = enc_j(imm[20:0], 5'd0);
            end
            3'b110: begin
              imm = rvc_imm_b(inst);
              decompress_rvc = enc_b(imm[12:0], 5'd0, rs1p, `FUNCT3_BEQ);
            end
            3'b111: begin
              imm = rvc_imm_b(inst);
              decompress_rvc = enc_b(imm[12:0], 5'd0, rs1p, `FUNCT3_BNE);
            end
            default: begin end
          endcase
        end

        2'b10: begin
          case (inst[15:13])
            3'b000: begin
              if (inst[12] == 1'b0)
                decompress_rvc = enc_i({7'h00, shamt[4:0]}, rd, `FUNCT3_SLL, rd, `OPCODE_OP_IMM);
            end
            3'b010: begin
              imm = rvc_imm_lwsp(inst);
              if (rd != 5'd0)
                decompress_rvc = enc_i(imm[11:0], 5'd2, `FUNCT3_LW, rd, `OPCODE_LOAD);
            end
            3'b100: begin
              if (inst[12] == 1'b0) begin
                if (rs2 == 5'd0) begin
                  if (rd != 5'd0)
                    decompress_rvc = enc_i(12'h000, rd, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_JALR);
                end else begin
                  decompress_rvc = enc_r(`FUNCT7_STD, rs2, 5'd0, `FUNCT3_ADD_SUB, rd, `OPCODE_OP);
                end
              end else begin
                if (rs2 == 5'd0) begin
                  if (rd == 5'd0)
                    decompress_rvc = {12'h001, 5'd0, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
                  else
                    decompress_rvc = enc_i(12'h000, rd, `FUNCT3_ADD_SUB, 5'd1, `OPCODE_JALR);
                end else begin
                  decompress_rvc = enc_r(`FUNCT7_STD, rs2, rd, `FUNCT3_ADD_SUB, rd, `OPCODE_OP);
                end
              end
            end
            3'b110: begin
              imm = rvc_imm_swsp(inst);
              decompress_rvc = enc_s(imm[11:0], rs2, 5'd2, `FUNCT3_SW);
            end
            default: begin end
          endcase
        end

        default: begin end
      endcase
    end
  endfunction

  /* verilator lint_on UNUSEDSIGNAL */

  wire active_w = ~halt_i & ~fatal_i & ~flush_i;
  wire fetch_buf_to_pipe_w = fetch_buf_valid_q & pipe_ready_i & active_w;
  wire fetch_rsp_slot_w = (~fetch_buf_valid_q) | fetch_buf_to_pipe_w;
  wire ifu_req_fire_w = ifu_req_valid_o & ifu_req_ready_i;
  wire fetch_late_rsp_w = ifu_rsp_valid_i & ifu_rsp_ready_o & fetch_pending_q;
  wire fetch_same_cycle_rsp_w = ifu_rsp_valid_i & ifu_rsp_ready_o &
                                ifu_req_fire_w & ~fetch_pending_q;
  wire fetch_incoming_rsp_w = fetch_late_rsp_w | fetch_same_cycle_rsp_w;
  // buffer 为空且 IF/ID 可接收时，取指返回直接旁路到流水寄存器，消除前端多余一拍气泡。
  wire fetch_direct_to_pipe_w = fetch_incoming_rsp_w & pipe_ready_i & active_w &
                                ~fetch_buf_valid_q;
  wire fetch_rsp_accept_w = fetch_incoming_rsp_w & active_w &
                            (fetch_direct_to_pipe_w | fetch_rsp_slot_w);
  wire fetch_store_rsp_w = fetch_rsp_accept_w & ~fetch_direct_to_pipe_w;
  wire fetch_issue_slot_w = fetch_buf_to_pipe_w | (~fetch_buf_valid_q);
  wire pipe_load_w = fetch_buf_to_pipe_w | fetch_direct_to_pipe_w;
  wire [`XLEN-1:0] fetch_rsp_pc_w = fetch_pending_q ? fetch_req_pc_q : fetch_pc_q;
  wire fetch_rsp_compressed_w = ifu_rsp_data_i[1:0] != 2'b11;
  wire [`INST_W-1:0] fetch_rsp_inst_w = fetch_rsp_compressed_w ?
                                        decompress_rvc(ifu_rsp_data_i[15:0]) :
                                        ifu_rsp_data_i;
  wire [`XLEN-1:0] fetch_rsp_inst_len_w = fetch_rsp_compressed_w ? 32'd2 : 32'd4;
  wire [`XLEN-1:0] fetch_rsp_seq_pc_w = fetch_rsp_pc_w + fetch_rsp_inst_len_w;
  wire [`XLEN-1:0] bpu_predict_next_pc_w;
  wire [`BPU_BHT_INDEX_W-1:0] bpu_predict_bht_idx_w;
  /* verilator lint_off UNUSEDSIGNAL */
  wire bpu_predict_control_w;
  wire bpu_predict_branch_w;
  wire bpu_predict_jalr_w;
  wire bpu_predict_ret_w;
  wire bpu_predict_btb_hit_w;
  wire bpu_predict_bht_valid_w;
  wire bpu_predict_bht_taken_w;
  wire bpu_predict_ras_lookup_w;
  wire bpu_predict_ras_hit_w;
  wire bpu_predict_ras_overflow_w;
  /* verilator lint_on UNUSEDSIGNAL */
  wire [`XLEN-1:0] fetch_rsp_pred_pc_w =
      ifu_rsp_error_i ? fetch_rsp_seq_pc_w :
      bpu_predict_next_pc_w;
  // steady-state 取指允许“接收上一条返回”和“发起下一条预测 PC”同拍发生。
  wire fetch_late_direct_to_pipe_w = fetch_late_rsp_w & pipe_ready_i &
                                     active_w & ~fetch_buf_valid_q;
  wire fetch_late_accept_w = fetch_late_rsp_w & active_w &
                             (fetch_late_direct_to_pipe_w | fetch_rsp_slot_w);
  wire fetch_late_keeps_slot_w = fetch_late_direct_to_pipe_w | fetch_buf_to_pipe_w;
  wire fetch_pipeline_issue_w = fetch_late_accept_w & fetch_late_keeps_slot_w;
  wire ifu_req_issue_w = active_w & fetch_issue_slot_w &
                         ((~fetch_pending_q) | fetch_pipeline_issue_w);
  wire [`XLEN-1:0] ifu_req_addr_w = fetch_pipeline_issue_w ?
                                    fetch_rsp_pred_pc_w :
                                    fetch_pc_q;

  BranchPredictor u_branch_predictor (
    .clk(clk),
    .rst(rst),
    .predict_valid_i(fetch_rsp_accept_w && ~ifu_rsp_error_i),
    .predict_pc_i(fetch_rsp_pc_w),
    .predict_inst_i(fetch_rsp_inst_w),
    .predict_seq_pc_i(fetch_rsp_seq_pc_w),
    .predict_next_pc_o(bpu_predict_next_pc_w),
    .predict_bht_idx_o(bpu_predict_bht_idx_w),
    .predict_control_o(bpu_predict_control_w),
    .predict_branch_o(bpu_predict_branch_w),
    .predict_jalr_o(bpu_predict_jalr_w),
    .predict_ret_o(bpu_predict_ret_w),
    .predict_btb_hit_o(bpu_predict_btb_hit_w),
    .predict_bht_valid_o(bpu_predict_bht_valid_w),
    .predict_bht_taken_o(bpu_predict_bht_taken_w),
    .predict_ras_lookup_o(bpu_predict_ras_lookup_w),
    .predict_ras_hit_o(bpu_predict_ras_hit_w),
    .predict_ras_overflow_o(bpu_predict_ras_overflow_w),
    .rollback_i(flush_i),
    .update_valid_i(bpu_update_valid_i),
    .update_pc_i(bpu_update_pc_i),
    .update_inst_i(bpu_update_inst_i),
    .update_seq_pc_i(bpu_update_seq_pc_i),
    .update_next_pc_i(bpu_update_next_pc_i),
    .update_taken_i(bpu_update_taken_i),
    .update_bht_idx_i(bpu_update_bht_idx_i)
  );

  assign pipe_valid_o = pipe_load_w;
  assign pipe_pc_o = fetch_buf_valid_q ? fetch_buf_pc_q : fetch_rsp_pc_w;
  assign pipe_inst_o = fetch_buf_valid_q ? fetch_buf_inst_q : fetch_rsp_inst_w;
  assign pipe_inst_len_o = fetch_buf_valid_q ? fetch_buf_inst_len_q : fetch_rsp_inst_len_w;
  assign pipe_pred_pc_o = fetch_buf_valid_q ? fetch_buf_pred_pc_q : fetch_rsp_pred_pc_w;
  assign pipe_bht_idx_o = fetch_buf_valid_q ? fetch_buf_bht_idx_q : bpu_predict_bht_idx_w;
  assign pipe_error_o = fetch_buf_valid_q ? fetch_buf_error_q : ifu_rsp_error_i;

  assign ifu_req_valid_o = ifu_req_issue_w;
  assign ifu_req_addr_o = ifu_req_addr_w;
  assign ifu_rsp_ready_o = active_w & fetch_rsp_slot_w;
  assign fetch_pc_o = fetch_pc_q;
  assign fetch_pending_o = fetch_pending_q;

  always @(posedge clk) begin
    if (rst) begin
      fetch_pending_q <= 1'b0;
      fetch_pc_q <= `RESET_PC;
      fetch_req_pc_q <= `RESET_PC;
      fetch_buf_valid_q <= 1'b0;
      fetch_buf_pc_q <= {`XLEN{1'b0}};
      fetch_buf_inst_q <= {`INST_W{1'b0}};
      fetch_buf_inst_len_q <= `PC_STEP;
      fetch_buf_pred_pc_q <= `RESET_PC + `PC_STEP;
      fetch_buf_bht_idx_q <= {`BPU_BHT_INDEX_W{1'b0}};
      fetch_buf_error_q <= 1'b0;
    end else begin
      if (flush_i) begin
        fetch_pending_q <= 1'b0;
        fetch_buf_valid_q <= 1'b0;
        if (redirect_valid_i) begin
          fetch_pc_q <= redirect_pc_i;
        end
      end else if (~halt_i && ~fatal_i) begin
        if (fetch_buf_to_pipe_w) begin
          fetch_buf_valid_q <= 1'b0;
        end

        if (fetch_rsp_accept_w) begin
          fetch_pc_q <= fetch_rsp_pred_pc_w;
        end

        if (fetch_store_rsp_w) begin
          fetch_buf_valid_q <= 1'b1;
          fetch_buf_pc_q <= fetch_rsp_pc_w;
          fetch_buf_inst_q <= fetch_rsp_inst_w;
          fetch_buf_inst_len_q <= fetch_rsp_inst_len_w;
          fetch_buf_pred_pc_q <= fetch_rsp_pred_pc_w;
          fetch_buf_bht_idx_q <= bpu_predict_bht_idx_w;
          fetch_buf_error_q <= ifu_rsp_error_i;
        end

        if (fetch_late_rsp_w) begin
          fetch_pending_q <= 1'b0;
        end

        if (ifu_req_fire_w) begin
          // 同步 SRAM cache 正常晚拍返回；保留同拍分支只用于兼容其它前端存储实现。
          fetch_pending_q <= ~fetch_same_cycle_rsp_w;
          fetch_req_pc_q <= ifu_req_addr_w;
        end
      end
    end
  end

endmodule
