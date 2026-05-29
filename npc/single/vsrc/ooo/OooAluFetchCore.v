`include "define.v"

// 受控 ALU-only OoO 核心壳：前端一次取回 PC/PC+4 两条 32-bit 指令，
// 通过小 fetch FIFO 连续喂给 OooAluCoreSlice，避免旧版串行取两次指令的前端空泡。
module OooAluFetchCore #(
  parameter PHY_REG_ADDR_W = 6,
  parameter ROB_INDEX_W = 4,
  parameter ROB_COUNT_W = 5,
  parameter FREE_COUNT_W = 7,
  parameter ISSUE_COUNT_W = 4,
  parameter FETCH_PACKET_COUNT_W = 2
) (
  input clk,
  input rst,
  input flush_i,
  input run_i,
  input [`XLEN-1:0] reset_pc_i,

  output fetch_req_valid_o,
  input fetch_req_ready_i,
  output [`XLEN-1:0] fetch_req_pc_o,
  input fetch_rsp_valid_i,
  output fetch_rsp_ready_o,
  input [`INST_W-1:0] fetch_rsp_inst0_i,
  input [1:0] fetch_rsp_resp0_i,
  input [`INST_W-1:0] fetch_rsp_inst1_i,
  input [1:0] fetch_rsp_resp1_i,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [3:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  output mem1_req_valid_o,
  input mem1_req_ready_i,
  output mem1_req_write_o,
  output [`XLEN-1:0] mem1_req_addr_o,
  output [`XLEN-1:0] mem1_req_wdata_o,
  output [3:0] mem1_req_wstrb_o,
  input mem1_rsp_valid_i,
  output mem1_rsp_ready_o,
  input [`XLEN-1:0] mem1_rsp_rdata_i,
  input mem1_rsp_error_i,

  input commit_ready_i,

  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_rd_addr_o,
  output [`XLEN-1:0] commit0_rd_data_o,
  output commit0_exception_o,
  output commit0_write_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_rd_addr_o,
  output [`XLEN-1:0] commit1_rd_data_o,
  output commit1_exception_o,
  output commit1_write_o,

  output trap_valid_o,
  output [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output [`XLEN-1:0] trap_pc_o,
  output [`XLEN-1:0] trap_tval_o,
  output exit_valid_o,
  output exit_is_ecall_o,
  output exit_is_ebreak_o,
  output [`XLEN-1:0] exit_code_o,
  output halted_o,

  output [`XLEN-1:0] debug_pc_o,
  output [`CORE_STATE_W-1:0] debug_state_o,
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o,
  output [1:0] retire_count_o,
  output [FREE_COUNT_W-1:0] free_count_o,
  output [ROB_COUNT_W-1:0] rob_count_o,
  output [ISSUE_COUNT_W-1:0] issue_count_o
);

  localparam FETCH_PACKET_COUNT = (1 << FETCH_PACKET_COUNT_W);
  localparam FETCH_COUNT_W = FETCH_PACKET_COUNT_W + 1;
  localparam [FETCH_COUNT_W-1:0] FETCH_PACKET_COUNT_VALUE =
      (1 << FETCH_PACKET_COUNT_W);
  localparam RAS_DEPTH = 32;
  localparam RAS_INDEX_W = 5;
  localparam RAS_COUNT_W = 6;
  localparam [RAS_COUNT_W-1:0] RAS_DEPTH_VALUE = RAS_DEPTH;
  localparam [RAS_INDEX_W-1:0] RAS_LAST_INDEX = {RAS_INDEX_W{1'b1}};
  localparam BRANCH_TARGET_CACHE_INDEX_W = 4;
  localparam BRANCH_TARGET_CACHE_ENTRIES =
      (1 << BRANCH_TARGET_CACHE_INDEX_W);

  function [FETCH_PACKET_COUNT_W-1:0] ptr_inc;
    input [FETCH_PACKET_COUNT_W-1:0] ptr;
    begin
      ptr_inc = ptr + {{(FETCH_PACKET_COUNT_W-1){1'b0}}, 1'b1};
    end
  endfunction

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
      enc_b = {imm[12], imm[10:5], rs2, rs1, funct3,
               imm[4:1], imm[11], `OPCODE_BRANCH};
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
      rvc_imm_addi4spn =
          {22'b0, inst[10:7], inst[12:11], inst[5], inst[6], 2'b00};
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
      rvc_imm_addi16sp = {{22{inst[12]}}, inst[12], inst[4:3],
                          inst[5], inst[2], inst[6], 4'b0000};
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
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_ADD_SUB,
                          rvc_rdp(inst), `OPCODE_OP_IMM);
            end
            3'b010: begin
              imm = rvc_imm_lw_sw(inst);
              decompress_rvc =
                  enc_i(imm[11:0], rs1p, `FUNCT3_LW,
                        rvc_rdp(inst), `OPCODE_LOAD);
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
              decompress_rvc =
                  enc_i(imm[11:0], rd, `FUNCT3_ADD_SUB, rd,
                        `OPCODE_OP_IMM);
            end
            3'b001: begin
              imm = rvc_imm_j(inst);
              decompress_rvc = enc_j(imm[20:0], 5'd1);
            end
            3'b010: begin
              imm = rvc_imm_6(inst);
              decompress_rvc =
                  enc_i(imm[11:0], 5'd0, `FUNCT3_ADD_SUB, rd,
                        `OPCODE_OP_IMM);
            end
            3'b011: begin
              if (rd == 5'd2) begin
                imm = rvc_imm_addi16sp(inst);
                if (imm != {`XLEN{1'b0}})
                  decompress_rvc =
                      enc_i(imm[11:0], 5'd2, `FUNCT3_ADD_SUB, 5'd2,
                            `OPCODE_OP_IMM);
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
                    decompress_rvc =
                        enc_i({7'h00, shamt[4:0]}, rs1p,
                              `FUNCT3_SRL_SRA, rs1p, `OPCODE_OP_IMM);
                end
                2'b01: begin
                  if (inst[12] == 1'b0)
                    decompress_rvc =
                        enc_i({7'h20, shamt[4:0]}, rs1p,
                              `FUNCT3_SRL_SRA, rs1p, `OPCODE_OP_IMM);
                end
                2'b10: begin
                  imm = rvc_imm_6(inst);
                  decompress_rvc =
                      enc_i(imm[11:0], rs1p, `FUNCT3_AND, rs1p,
                            `OPCODE_OP_IMM);
                end
                2'b11: begin
                  if (inst[12] == 1'b0) begin
                    case (inst[6:5])
                      2'b00: decompress_rvc =
                          enc_r(`FUNCT7_ALT, rs2p, rs1p, `FUNCT3_ADD_SUB,
                                rs1p, `OPCODE_OP);
                      2'b01: decompress_rvc =
                          enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_XOR,
                                rs1p, `OPCODE_OP);
                      2'b10: decompress_rvc =
                          enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_OR,
                                rs1p, `OPCODE_OP);
                      2'b11: decompress_rvc =
                          enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_AND,
                                rs1p, `OPCODE_OP);
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
                decompress_rvc =
                    enc_i({7'h00, shamt[4:0]}, rd, `FUNCT3_SLL, rd,
                          `OPCODE_OP_IMM);
            end
            3'b010: begin
              imm = rvc_imm_lwsp(inst);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_LW, rd, `OPCODE_LOAD);
            end
            3'b100: begin
              if (inst[12] == 1'b0) begin
                if (rs2 == 5'd0) begin
                  if (rd != 5'd0)
                    decompress_rvc =
                        enc_i(12'h000, rd, `FUNCT3_ADD_SUB, 5'd0,
                              `OPCODE_JALR);
                end else begin
                  decompress_rvc =
                      enc_r(`FUNCT7_STD, rs2, 5'd0, `FUNCT3_ADD_SUB, rd,
                            `OPCODE_OP);
                end
              end else begin
                if (rs2 == 5'd0) begin
                  if (rd == 5'd0)
                    decompress_rvc =
                        {12'h001, 5'd0, `FUNCT3_ADD_SUB, 5'd0,
                         `OPCODE_SYSTEM};
                  else
                    decompress_rvc =
                        enc_i(12'h000, rd, `FUNCT3_ADD_SUB, 5'd1,
                              `OPCODE_JALR);
                end else begin
                  decompress_rvc =
                      enc_r(`FUNCT7_STD, rs2, rd, `FUNCT3_ADD_SUB, rd,
                            `OPCODE_OP);
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

  reg [`XLEN-1:0] next_fetch_pc_q;
  reg outstanding_valid_q;
  reg [`XLEN-1:0] outstanding_pc_q;
  reg discard_fetch_rsp_q;
  reg [`XLEN-1:0] ras_stack_q [0:RAS_DEPTH-1];
  reg [RAS_COUNT_W-1:0] ras_count_q;
  reg ras_reliable_q;

  reg [FETCH_PACKET_COUNT_W-1:0] fifo_head_q;
  reg [FETCH_PACKET_COUNT_W-1:0] fifo_tail_q;
  reg [FETCH_COUNT_W-1:0] fifo_count_q;
  reg [`XLEN-1:0] fifo_pc0_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] fifo_pc1_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] fifo_next_pc0_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] fifo_next_pc1_q [0:FETCH_PACKET_COUNT-1];
  reg [`XLEN-1:0] fifo_packet_next_pc_q [0:FETCH_PACKET_COUNT-1];
  reg [`INST_W-1:0] fifo_inst0_q [0:FETCH_PACKET_COUNT-1];
  reg [`INST_W-1:0] fifo_inst1_q [0:FETCH_PACKET_COUNT-1];
  reg [1:0] fifo_resp0_q [0:FETCH_PACKET_COUNT-1];
  reg [1:0] fifo_resp1_q [0:FETCH_PACKET_COUNT-1];
  reg branch_prefetch_active_q;
  reg branch_prefetch_buffer_valid_q;
  reg [`XLEN-1:0] branch_prefetch_pc_q;
  reg [`XLEN-1:0] branch_prefetch_buf_pc0_q;
  reg [`XLEN-1:0] branch_prefetch_buf_pc1_q;
  reg [`XLEN-1:0] branch_prefetch_buf_next_pc0_q;
  reg [`XLEN-1:0] branch_prefetch_buf_next_pc1_q;
  reg [`XLEN-1:0] branch_prefetch_buf_packet_next_pc_q;
  reg [`INST_W-1:0] branch_prefetch_buf_inst0_q;
  reg [`INST_W-1:0] branch_prefetch_buf_inst1_q;
  reg [1:0] branch_prefetch_buf_resp0_q;
  reg [1:0] branch_prefetch_buf_resp1_q;
  reg branch_spec_active_q;
  reg branch_spec_checkpoint_pending_q;
  reg [`XLEN-1:0] branch_spec_pred_pc_q;
  reg branch_target_capture_pending_q;
  reg [`XLEN-1:0] branch_target_capture_branch_pc_q;
  reg [`XLEN-1:0] branch_target_capture_target_pc_q;
  reg branch_target_cache_valid_q [0:BRANCH_TARGET_CACHE_ENTRIES-1];
  reg [`XLEN-1:0] branch_target_cache_branch_pc_q [0:BRANCH_TARGET_CACHE_ENTRIES-1];
  reg [`XLEN-1:0] branch_target_cache_target_pc_q [0:BRANCH_TARGET_CACHE_ENTRIES-1];
  reg [`XLEN-1:0] branch_target_cache_next_pc_q [0:BRANCH_TARGET_CACHE_ENTRIES-1];
  reg [`INST_W-1:0] branch_target_cache_inst_q [0:BRANCH_TARGET_CACHE_ENTRIES-1];

  reg trap_valid_q;
  reg [`TRAP_CAUSE_W-1:0] trap_cause_q;
  reg [`XLEN-1:0] trap_pc_q;
  reg [`XLEN-1:0] trap_tval_q;
  reg exit_valid_q;
  reg halted_q;
  reg stop_pending_q;
  reg pending_exit_q;
  reg pending_branch_q;
  reg pending_branch_dispatched_q;
  reg pending_jump_q;
  reg pending_jump_dispatched_q;
  reg pending_jump_jalr_q;
  reg pending_mem_q;
  reg pending_mem_dispatched_q;
  reg [`TRAP_CAUSE_W-1:0] pending_trap_cause_q;
  reg [`XLEN-1:0] pending_trap_pc_q;
  reg [`XLEN-1:0] pending_trap_tval_q;
  reg [`XLEN-1:0] pending_branch_pc_q;
  reg [`XLEN-1:0] pending_branch_next_pc_q;
  reg [`INST_W-1:0] pending_branch_inst_q;
  reg [`REG_ADDR_W-1:0] pending_branch_rs1_q;
  reg [`REG_ADDR_W-1:0] pending_branch_rs2_q;
  reg [`XLEN-1:0] pending_branch_imm_q;
  reg [2:0] pending_branch_cmp_op_q;
  reg [`XLEN-1:0] pending_jump_pc_q;
  reg [`XLEN-1:0] pending_jump_next_pc_q;
  reg [`INST_W-1:0] pending_jump_inst_q;
  reg [`REG_ADDR_W-1:0] pending_jump_rs1_q;
  reg [`XLEN-1:0] pending_jump_imm_q;
  reg [`XLEN-1:0] pending_jump_target_q;
  reg pending_lane1_ret_q;
  reg [`XLEN-1:0] pending_lane1_ret_pc_q;
  reg [`XLEN-1:0] pending_lane1_ret_next_pc_q;
  reg [`INST_W-1:0] pending_lane1_ret_inst_q;
  reg return_cont_valid_q;
  reg [`XLEN-1:0] return_cont_pc_q;
  reg [`XLEN-1:0] return_cont_next_pc_q;
  reg [`INST_W-1:0] return_cont_inst_q;
  reg synth_lane1_ret_pending_q;
  reg synth_lane1_ret_branch_seen_q;
  reg [`XLEN-1:0] synth_lane1_ret_branch_pc_q;
  reg [`XLEN-1:0] synth_lane1_ret_pc_q;
  reg [`XLEN-1:0] synth_lane1_ret_next_pc_q;
  reg [`INST_W-1:0] synth_lane1_ret_inst_q;
  reg synth_lane1_branch_drop_pending_q;
  reg [`XLEN-1:0] synth_lane1_branch_drop_pc_q;
  reg [`XLEN-1:0] pending_mem_pc_q;
  reg [`INST_W-1:0] pending_mem_inst_q;
  reg [`XLEN-1:0] pending_mem_next_pc_q;
  reg ctrl_commit_valid_q;
  reg [`XLEN-1:0] ctrl_commit_pc_q;
  reg [`INST_W-1:0] ctrl_commit_inst_q;
  reg [`XLEN-1:0] ctrl_commit_next_pc_q;
  reg backend_drained_q;

  wire can_run_w = run_i && !stop_pending_q && !halted_q &&
                   !trap_valid_q && !exit_valid_q;
  wire fifo_empty_storage_w = (fifo_count_q == {FETCH_COUNT_W{1'b0}});
  wire fetch_rsp_dispatch_bypass_w =
      fifo_empty_storage_w && can_run_w && outstanding_valid_q &&
      fetch_rsp_valid_i && !discard_fetch_rsp_q;
  wire fifo_has_packet_w = !fifo_empty_storage_w ||
                           fetch_rsp_dispatch_bypass_w;
  wire [FETCH_COUNT_W-1:0] outstanding_count_w =
      {{(FETCH_COUNT_W-1){1'b0}}, outstanding_valid_q};
  wire fifo_reserve_available_w =
      ((fifo_count_q + outstanding_count_w) < FETCH_PACKET_COUNT_VALUE);
  wire ras_empty_w = (ras_count_q == {RAS_COUNT_W{1'b0}});
  wire ras_full_w = (ras_count_q == RAS_DEPTH_VALUE);
  wire [RAS_INDEX_W-1:0] ras_push_idx_w =
      ras_full_w ? RAS_LAST_INDEX : ras_count_q[RAS_INDEX_W-1:0];
  wire [RAS_INDEX_W-1:0] ras_top_idx_w =
      ras_full_w ? RAS_LAST_INDEX :
                   (ras_count_q[RAS_INDEX_W-1:0] -
                    {{(RAS_INDEX_W-1){1'b0}}, 1'b1});
  wire [`XLEN-1:0] ras_top_w = ras_stack_q[ras_top_idx_w];

  wire [`XLEN-1:0] head_pc_w =
      fetch_rsp_dispatch_bypass_w ? fetch_dec0_pc_w :
                                    fifo_pc0_q[fifo_head_q];
  wire [`XLEN-1:0] head_pc1_w =
      fetch_rsp_dispatch_bypass_w ? fetch_dec1_pc_w :
                                    fifo_pc1_q[fifo_head_q];
  wire [`XLEN-1:0] head_next_pc0_w =
      fetch_rsp_dispatch_bypass_w ? fetch_dec0_next_pc_w :
                                    fifo_next_pc0_q[fifo_head_q];
  wire [`XLEN-1:0] head_next_pc1_w =
      fetch_rsp_dispatch_bypass_w ? fetch_dec1_next_pc_w :
                                    fifo_next_pc1_q[fifo_head_q];
  wire [`XLEN-1:0] head_packet_next_pc_w =
      fetch_rsp_dispatch_bypass_w ? fetch_rsp_packet_next_pc_w :
                                    fifo_packet_next_pc_q[fifo_head_q];
  wire [`INST_W-1:0] head_inst0_w =
      fetch_rsp_dispatch_bypass_w ? fetch_dec0_inst_w :
                                    fifo_inst0_q[fifo_head_q];
  wire [`INST_W-1:0] head_inst1_w =
      fetch_rsp_dispatch_bypass_w ? fetch_dec1_inst_w :
                                    fifo_inst1_q[fifo_head_q];
  wire [1:0] head_resp0_w =
      fetch_rsp_dispatch_bypass_w ? fetch_rsp_resp0_i :
                                    fifo_resp0_q[fifo_head_q];
  wire [1:0] head_resp1_w =
      fetch_rsp_dispatch_bypass_w ? fetch_dec1_resp_w :
                                    fifo_resp1_q[fifo_head_q];
  wire head_fetch_fault0_w = fifo_has_packet_w && (head_resp0_w != 2'b00);
  wire [`CTRL_BUS_W-1:0] head0_ctrl_w;
  wire [`REG_ADDR_W-1:0] head0_rs1_w;
  wire [`REG_ADDR_W-1:0] head0_rs2_w;
  wire [`REG_ADDR_W-1:0] head0_rd_unused_w;
  wire [`XLEN-1:0] head0_imm_w;
  wire [`CTRL_BUS_W-1:0] head1_ctrl_w;
  wire [`REG_ADDR_W-1:0] head1_rs1_w;
  wire [`REG_ADDR_W-1:0] head1_rs2_w;
  wire [`REG_ADDR_W-1:0] head1_rd_unused_w;
  wire [`XLEN-1:0] head1_imm_w;
  wire [`CTRL_BUS_W-1:0] branch_target_capture_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rd_unused_w;
  wire [`XLEN-1:0] branch_target_capture_imm_unused_w;
  wire head0_decode_valid_w = fifo_has_packet_w && !head_fetch_fault0_w;
  wire head0_branch_raw_w = head0_decode_valid_w &&
                            head0_ctrl_w[`CTRL_BRANCH_BIT] &&
                            !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_jal_raw_w = head0_decode_valid_w &&
                         head0_ctrl_w[`CTRL_JAL_BIT] &&
                         !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_jalr_raw_w = head0_decode_valid_w &&
                          head0_ctrl_w[`CTRL_JALR_BIT] &&
                          !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_jump_raw_w = head0_jal_raw_w || head0_jalr_raw_w;
  wire head0_mem_raw_w = head0_decode_valid_w &&
                         !head0_ctrl_w[`CTRL_ILLEGAL_BIT] &&
                         (head0_ctrl_w[`CTRL_LOAD_BIT] ||
                          head0_ctrl_w[`CTRL_STORE_BIT]);
  wire head0_ebreak_raw_w = head0_decode_valid_w &&
                            (head_inst0_w == 32'h0010_0073);
  wire head_fetch_fault1_w = fifo_has_packet_w && !head_fetch_fault0_w &&
                             !head0_branch_raw_w && !head0_jump_raw_w &&
                             !head0_ebreak_raw_w &&
                             (head_resp1_w != 2'b00);
  wire head_fetch_fault_w = head_fetch_fault0_w | head_fetch_fault1_w;
  wire head1_decode_valid_w = fifo_has_packet_w && !head_fetch_fault0_w &&
                              !head0_branch_raw_w && !head0_jump_raw_w &&
                              !head0_ebreak_raw_w &&
                              (head_resp1_w == 2'b00);
  wire head1_control_raw_w = head1_decode_valid_w &&
                             !head1_ctrl_w[`CTRL_ILLEGAL_BIT] &&
                             (head1_ctrl_w[`CTRL_BRANCH_BIT] ||
                              head1_ctrl_w[`CTRL_JAL_BIT] ||
                              head1_ctrl_w[`CTRL_JALR_BIT]);
  wire head1_branch_raw_w = head1_decode_valid_w &&
                            head1_ctrl_w[`CTRL_BRANCH_BIT] &&
                            !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_jal_raw_w = head1_decode_valid_w &&
                         head1_ctrl_w[`CTRL_JAL_BIT] &&
                         !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_jalr_raw_w = head1_decode_valid_w &&
                          head1_ctrl_w[`CTRL_JALR_BIT] &&
                          !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_jump_raw_w = head1_jal_raw_w || head1_jalr_raw_w;
  wire head1_mem_raw_w = head1_decode_valid_w &&
                         !head1_ctrl_w[`CTRL_ILLEGAL_BIT] &&
                         (head1_ctrl_w[`CTRL_LOAD_BIT] ||
                          head1_ctrl_w[`CTRL_STORE_BIT]);
  wire head1_ebreak_raw_w = head1_decode_valid_w &&
                            (head_inst1_w == 32'h0010_0073);
  wire branch_spec_dispatch_block_w =
      branch_spec_active_q && fifo_has_packet_w &&
      (head_fetch_fault0_w || head_fetch_fault1_w ||
       head0_ebreak_raw_w || head0_branch_raw_w || head0_jump_raw_w ||
       head0_mem_raw_w || head1_ebreak_raw_w || head1_control_raw_w ||
       head1_mem_raw_w);

  wire dispatch0_ready_w;
  /* verilator lint_off UNOPTFLAT */
  wire dispatch1_ready_w;
  /* verilator lint_on UNOPTFLAT */
  wire dispatch0_unsupported_w;
  wire dispatch1_unsupported_w;
  wire dispatch_valid_w = fifo_has_packet_w && can_run_w &&
                          !pending_lane1_ret_q &&
                          !head_fetch_fault0_w &&
                          !branch_spec_dispatch_block_w;
  wire dispatch0_ebreak_w = dispatch_valid_w && head0_ebreak_raw_w;
  wire dispatch0_branch_w = dispatch_valid_w && head0_branch_raw_w;
  wire direct_branch0_dispatch_valid_w = dispatch0_branch_w;
  wire direct_branch0_fire_w = dispatch0_branch_w &&
                               !dispatch0_unsupported_w &&
                               dispatch0_ready_w;
  wire dispatch0_jal_w = dispatch_valid_w && head0_jal_raw_w;
  wire dispatch0_jump_w = dispatch_valid_w && head0_jalr_raw_w;
  wire dispatch0_return_w = dispatch0_jump_w &&
                             ras_reliable_q &&
                             !ras_empty_w &&
                             (head0_rd_unused_w == 5'd0) &&
                             ((head0_rs1_w == 5'd1) ||
                              (head0_rs1_w == 5'd5)) &&
                             (head0_imm_w == {`XLEN{1'b0}});
  wire head1_return_candidate_w =
      ras_reliable_q && !ras_empty_w && !head1_ctrl_w[`CTRL_ILLEGAL_BIT] &&
      head1_ctrl_w[`CTRL_JALR_BIT] &&
      (head1_rd_unused_w == {`REG_ADDR_W{1'b0}}) &&
      ((head1_rs1_w == 5'd1) || (head1_rs1_w == 5'd5)) &&
      (head1_imm_w == {`XLEN{1'b0}});
  // lane1 ret 只有在 lane0 是不会异常的简单 ALU 且不改写 ret 源寄存器时才直接走 RAS，
  // 否则仍保留 drain 后重放，避免把精确异常和数据相关性变成控制流猜测。
  wire lane0_before_ret_safe_w =
      head0_ctrl_w[`CTRL_VALID_BIT] &&
      !head0_ctrl_w[`CTRL_ILLEGAL_BIT] &&
      head0_ctrl_w[`CTRL_NEED_EXEC_BIT] &&
      !head0_ctrl_w[`CTRL_BRANCH_BIT] &&
      !head0_ctrl_w[`CTRL_JAL_BIT] &&
      !head0_ctrl_w[`CTRL_JALR_BIT] &&
      !head0_ctrl_w[`CTRL_LOAD_BIT] &&
      !head0_ctrl_w[`CTRL_STORE_BIT] &&
      !head0_ctrl_w[`CTRL_ECALL_BIT] &&
      !head0_ctrl_w[`CTRL_EBREAK_BIT] &&
      !head0_ctrl_w[`CTRL_SYSTEM_BIT] &&
      !head0_ctrl_w[`CTRL_CSR_BIT] &&
      !head0_ctrl_w[`CTRL_FENCE_BIT] &&
      !head0_ctrl_w[`CTRL_MISC_MEM_BIT] &&
      !head0_ctrl_w[`CTRL_MRET_BIT] &&
      !head0_ctrl_w[`CTRL_WFI_BIT] &&
      !head0_ctrl_w[`CTRL_MULDIV_BIT] &&
      !head0_ctrl_w[`CTRL_BITMANIP_BIT] &&
      (!head0_ctrl_w[`CTRL_RD_EN_BIT] ||
       (head0_rd_unused_w == {`REG_ADDR_W{1'b0}}) ||
       (head0_rd_unused_w != head1_rs1_w));
  wire dispatch1_direct_jal_w = dispatch_valid_w &&
                                !dispatch0_ebreak_w &&
                                !dispatch0_branch_w &&
                                !dispatch0_jal_w &&
                                !dispatch0_jump_w &&
                                head1_jal_raw_w;
  wire dispatch1_return_w = dispatch_valid_w &&
                            !dispatch0_ebreak_w &&
                            !dispatch0_branch_w &&
                            !dispatch0_jal_w &&
                            !dispatch0_jump_w &&
                            head1_return_candidate_w &&
                            lane0_before_ret_safe_w;
  wire direct_branch1_dispatch_valid_w = dispatch_valid_w &&
                                         head1_branch_raw_w &&
                                         !head_fetch_fault1_w &&
                                         !dispatch0_ebreak_w &&
                                         !dispatch0_branch_w &&
                                         !dispatch0_jal_w &&
                                         !dispatch0_jump_w;
  wire dispatch1_barrier_w = dispatch_valid_w &&
                             !dispatch0_ebreak_w &&
                             !dispatch0_branch_w &&
                             !dispatch0_jal_w &&
                             !dispatch0_jump_w &&
                             (head_fetch_fault1_w ||
                              head1_ebreak_raw_w ||
                              (head1_branch_raw_w &&
                               !direct_branch1_dispatch_valid_w) ||
                              (head1_jalr_raw_w &&
                               !dispatch1_return_w));
  wire dispatch1_control_unsupported_w = dispatch_valid_w &&
                                         !dispatch0_ebreak_w &&
                                         !dispatch0_branch_w &&
                                         !dispatch0_jal_w &&
                                         !dispatch0_jump_w &&
                                         !dispatch1_barrier_w &&
                                         !direct_branch1_dispatch_valid_w &&
                                         !dispatch1_return_w &&
                                         head1_control_raw_w &&
                                         !head1_jal_raw_w;
  wire dispatch1_mem_unsupported_w = 1'b0;
  wire dispatch_unsupported_w = dispatch_valid_w && !dispatch0_ebreak_w &&
                                !dispatch0_branch_w && !dispatch0_jump_w &&
                                (dispatch0_unsupported_w |
                                 dispatch1_unsupported_w |
                                 dispatch1_control_unsupported_w |
                                 dispatch1_mem_unsupported_w);
  wire dispatch_fire_w = dispatch_valid_w &&
                         !dispatch0_ebreak_w &&
                         !dispatch0_branch_w &&
                         !dispatch0_jal_w &&
                         !dispatch0_jump_w &&
                         !dispatch1_barrier_w &&
                         !dispatch_unsupported_w &&
                         dispatch0_ready_w &&
                         dispatch1_ready_w;
  wire direct_jal0_dispatch_valid_w = dispatch0_jal_w;
  wire direct_jal0_fire_w = dispatch0_jal_w &&
                            !dispatch0_unsupported_w &&
                            dispatch0_ready_w;
  wire direct_jal1_fire_w = dispatch_fire_w && head1_jal_raw_w;
  wire direct_jal_fire_w = direct_jal0_fire_w || direct_jal1_fire_w;
  wire direct_ret1_fire_w = dispatch_fire_w && dispatch1_return_w;
  wire direct_branch1_fire_w = dispatch_fire_w && head1_branch_raw_w;
  wire direct_branch_fire_w = direct_branch0_fire_w || direct_branch1_fire_w;
  wire [`XLEN-1:0] direct_branch_pc_w =
      direct_branch1_fire_w ? head_pc1_w : head_pc_w;
  wire [`XLEN-1:0] direct_branch_next_pc_w =
      direct_branch1_fire_w ? head_next_pc1_w : head_next_pc0_w;
  wire [`XLEN-1:0] direct_branch_imm_w =
      direct_branch1_fire_w ? head1_imm_w : head0_imm_w;
  wire [`XLEN-1:0] direct_branch_target_w =
      direct_branch_pc_w + direct_branch_imm_w;
  wire direct_branch_predict_taken_w = direct_branch_imm_w[`XLEN-1];
  wire [`XLEN-1:0] direct_branch_pred_pc_w =
      direct_branch_predict_taken_w ? direct_branch_target_w :
                                      direct_branch_next_pc_w;
  wire direct_branch0_resolve_valid_w =
      direct_branch0_fire_w && core_dispatch_branch_resolve_valid_w &&
      (core_dispatch_branch_resolve_pc_w == head_pc_w);
  wire direct_branch1_resolve_valid_w =
      direct_branch1_fire_w && core_dispatch_branch_resolve_valid_w &&
      (core_dispatch_branch_resolve_pc_w == head_pc1_w);
  wire direct_branch_resolve_valid_w =
      direct_branch0_resolve_valid_w || direct_branch1_resolve_valid_w;
  wire direct_branch_resolve_redirect_w =
      direct_branch_resolve_valid_w &&
      !core_dispatch_branch_resolve_misaligned_w;
  wire direct_branch_resolve_taken_w =
      direct_branch_resolve_redirect_w &&
      (core_dispatch_branch_resolve_next_pc_w == direct_branch_target_w);
  wire direct_branch0_lane1_ret_w =
      direct_branch0_resolve_valid_w &&
      !synth_lane1_ret_pending_q &&
      !synth_lane1_branch_drop_pending_q &&
      !core_dispatch_branch_resolve_misaligned_w &&
      (core_dispatch_branch_resolve_next_pc_w == head_pc1_w) &&
      head1_return_candidate_w;
  wire direct_ret0_dispatch_valid_w = dispatch0_return_w;
  wire direct_ret0_fire_w = dispatch0_return_w &&
                            !dispatch0_unsupported_w &&
                            dispatch0_ready_w;
  wire direct_frontend_flush_w = direct_jal_fire_w ||
                                 direct_branch0_fire_w ||
                                 direct_branch1_fire_w ||
                                 direct_ret0_fire_w ||
                                 direct_ret1_fire_w;
  wire [`XLEN-1:0] direct_jal_target_w =
      direct_jal0_fire_w ? (head_pc_w + head0_imm_w) :
                           (head_pc1_w + head1_imm_w);
  wire [`XLEN-1:0] direct_ret_target_w = ras_top_w;
  wire direct_jal0_call_w = direct_jal0_fire_w &&
                            ((head0_rd_unused_w == 5'd1) ||
                             (head0_rd_unused_w == 5'd5));
  wire direct_jal1_call_w = direct_jal1_fire_w &&
                            ((head1_rd_unused_w == 5'd1) ||
                             (head1_rd_unused_w == 5'd5));
  wire direct_jal_call_w = direct_jal0_call_w || direct_jal1_call_w;
  wire [`XLEN-1:0] direct_jal_link_w =
      direct_jal0_call_w ? head_next_pc0_w : head_next_pc1_w;
  wire return_cont_safe_w =
      !head_fetch_fault1_w &&
      head1_ctrl_w[`CTRL_VALID_BIT] &&
      !head1_ctrl_w[`CTRL_ILLEGAL_BIT] &&
      head1_ctrl_w[`CTRL_NEED_EXEC_BIT] &&
      !head1_ctrl_w[`CTRL_BRANCH_BIT] &&
      !head1_ctrl_w[`CTRL_JAL_BIT] &&
      !head1_ctrl_w[`CTRL_JALR_BIT] &&
      !head1_ctrl_w[`CTRL_LOAD_BIT] &&
      !head1_ctrl_w[`CTRL_STORE_BIT] &&
      !head1_ctrl_w[`CTRL_ECALL_BIT] &&
      !head1_ctrl_w[`CTRL_EBREAK_BIT] &&
      !head1_ctrl_w[`CTRL_SYSTEM_BIT] &&
      !head1_ctrl_w[`CTRL_CSR_BIT] &&
      !head1_ctrl_w[`CTRL_FENCE_BIT] &&
      !head1_ctrl_w[`CTRL_MISC_MEM_BIT] &&
      !head1_ctrl_w[`CTRL_MRET_BIT] &&
      !head1_ctrl_w[`CTRL_WFI_BIT] &&
      !head1_ctrl_w[`CTRL_MULDIV_BIT] &&
      !head1_ctrl_w[`CTRL_BITMANIP_BIT];
  wire return_cont_capture_w =
      direct_jal0_call_w && return_cont_safe_w;
  wire return_cont_match_w =
      return_cont_valid_q && (return_cont_pc_q == ras_top_w);
  wire branch_fallthrough_safe_w =
      (head_resp1_w == 2'b00) &&
      (head_inst1_w != 32'h0010_0073) &&
      head1_ctrl_w[`CTRL_VALID_BIT] &&
      !head1_ctrl_w[`CTRL_ILLEGAL_BIT] &&
      head1_ctrl_w[`CTRL_NEED_EXEC_BIT] &&
      !head1_ctrl_w[`CTRL_BRANCH_BIT] &&
      !head1_ctrl_w[`CTRL_JAL_BIT] &&
      !head1_ctrl_w[`CTRL_JALR_BIT] &&
      !head1_ctrl_w[`CTRL_STORE_BIT] &&
      !head1_ctrl_w[`CTRL_ECALL_BIT] &&
      !head1_ctrl_w[`CTRL_EBREAK_BIT] &&
      !head1_ctrl_w[`CTRL_SYSTEM_BIT] &&
      !head1_ctrl_w[`CTRL_CSR_BIT] &&
      !head1_ctrl_w[`CTRL_FENCE_BIT] &&
      !head1_ctrl_w[`CTRL_MISC_MEM_BIT] &&
      !head1_ctrl_w[`CTRL_MRET_BIT] &&
      !head1_ctrl_w[`CTRL_WFI_BIT] &&
      !head1_ctrl_w[`CTRL_MULDIV_BIT] &&
      !head1_ctrl_w[`CTRL_BITMANIP_BIT];
  wire dispatch1_barrier_fire_w = dispatch1_barrier_w &&
                                  !dispatch0_unsupported_w &&
                                  dispatch0_ready_w;
  wire stop_head_w = can_run_w && fifo_has_packet_w &&
                     !branch_spec_dispatch_block_w &&
                     (head_fetch_fault0_w | dispatch0_ebreak_w |
                      dispatch0_branch_w | dispatch0_jal_w |
                      dispatch0_jump_w |
                      dispatch1_barrier_w | dispatch1_direct_jal_w |
                      direct_branch1_dispatch_valid_w |
                      dispatch_unsupported_w);
  wire fifo_pop_w = dispatch_fire_w || dispatch1_barrier_fire_w ||
                    direct_jal0_fire_w;
  wire fetch_rsp_bypass_consumed_w =
      fetch_rsp_dispatch_bypass_w &&
      (fifo_pop_w || direct_frontend_flush_w);
  wire fifo_storage_pop_w = fifo_pop_w && !fetch_rsp_dispatch_bypass_w;
  wire fifo_can_accept_rsp_w =
      (fifo_count_q < FETCH_PACKET_COUNT_VALUE) || fifo_storage_pop_w;

  wire fetch_rsp_can_enqueue_w = can_run_w && outstanding_valid_q &&
                                 fifo_can_accept_rsp_w;
  wire fetch_rsp_can_drop_w = stop_pending_q || halted_q ||
                              trap_valid_q || exit_valid_q;
  wire direct_fetch_drop_w = direct_frontend_flush_w ||
                             discard_fetch_rsp_q;
  wire fetch_rsp_fire_w = fetch_rsp_valid_i && fetch_rsp_ready_o;
  wire fetch_rsp_enqueue_w = fetch_rsp_valid_i && fetch_rsp_can_enqueue_w &&
                             !direct_fetch_drop_w &&
                             !fetch_rsp_bypass_consumed_w;
  wire [15:0] fetch_half0_w = fetch_rsp_inst0_i[15:0];
  wire [15:0] fetch_half1_w = fetch_rsp_inst0_i[31:16];
  wire [15:0] fetch_half2_w = fetch_rsp_inst1_i[15:0];
  wire fetch_dec0_compressed_w = (fetch_half0_w[1:0] != 2'b11);
  wire [`XLEN-1:0] fetch_dec0_len_w =
      fetch_dec0_compressed_w ? 32'd2 : 32'd4;
  wire [`XLEN-1:0] fetch_dec0_pc_w = outstanding_pc_q;
  wire [`XLEN-1:0] fetch_dec0_next_pc_w =
      fetch_dec0_pc_w + fetch_dec0_len_w;
  wire [15:0] fetch_dec1_half_w =
      fetch_dec0_compressed_w ? fetch_half1_w : fetch_half2_w;
  wire fetch_dec1_compressed_w = (fetch_dec1_half_w[1:0] != 2'b11);
  wire [`XLEN-1:0] fetch_dec1_len_w =
      fetch_dec1_compressed_w ? 32'd2 : 32'd4;
  wire [`XLEN-1:0] fetch_dec1_pc_w = fetch_dec0_next_pc_w;
  wire [`XLEN-1:0] fetch_dec1_next_pc_w =
      fetch_dec1_pc_w + fetch_dec1_len_w;
  wire [`INST_W-1:0] fetch_dec0_inst_w =
      fetch_dec0_compressed_w ? decompress_rvc(fetch_half0_w) :
                                fetch_rsp_inst0_i;
  wire [`INST_W-1:0] fetch_dec1_raw32_w =
      fetch_dec0_compressed_w ? {fetch_half2_w, fetch_half1_w} :
                                fetch_rsp_inst1_i;
  wire [`INST_W-1:0] fetch_dec1_inst_w =
      fetch_dec1_compressed_w ? decompress_rvc(fetch_dec1_half_w) :
                                fetch_dec1_raw32_w;
  wire fetch_dec0_control_stop_w =
      (fetch_rsp_resp0_i != 2'b00) ||
      (fetch_dec0_inst_w[6:0] == `OPCODE_BRANCH) ||
      (fetch_dec0_inst_w[6:0] == `OPCODE_JAL) ||
      (fetch_dec0_inst_w[6:0] == `OPCODE_JALR) ||
      (fetch_dec0_inst_w[6:0] == `OPCODE_SYSTEM);
  wire fetch_dec1_needs_word1_w =
      !fetch_dec0_compressed_w || !fetch_dec1_compressed_w;
  wire [1:0] fetch_dec1_resp_w =
      fetch_dec1_needs_word1_w ? fetch_rsp_resp1_i : fetch_rsp_resp0_i;
  wire fetch_dec1_control_stop_w =
      (fetch_dec1_resp_w != 2'b00) ||
      (fetch_dec1_inst_w[6:0] == `OPCODE_BRANCH) ||
      (fetch_dec1_inst_w[6:0] == `OPCODE_JAL) ||
      (fetch_dec1_inst_w[6:0] == `OPCODE_JALR) ||
      (fetch_dec1_inst_w[6:0] == `OPCODE_SYSTEM);
  wire fetch_rsp_control_stop_w =
      fetch_rsp_fire_w && fetch_rsp_can_enqueue_w &&
      (fetch_dec0_control_stop_w || fetch_dec1_control_stop_w);
  wire [`XLEN-1:0] fetch_rsp_packet_next_pc_w = fetch_dec1_next_pc_w;
  wire branch_target_capture_safe_w =
      (fetch_rsp_resp0_i == 2'b00) &&
      (fetch_dec0_inst_w != 32'h0010_0073) &&
      branch_target_capture_ctrl_w[`CTRL_VALID_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_ILLEGAL_BIT] &&
      branch_target_capture_ctrl_w[`CTRL_NEED_EXEC_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_BRANCH_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_JAL_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_JALR_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_STORE_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_ECALL_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_EBREAK_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_SYSTEM_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_CSR_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_FENCE_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_MISC_MEM_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_MRET_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_WFI_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_MULDIV_BIT] &&
      !branch_target_capture_ctrl_w[`CTRL_BITMANIP_BIT];
  wire branch_target_capture_hit_w =
      branch_target_capture_pending_q && fetch_rsp_fire_w &&
      (fetch_dec0_pc_w == branch_target_capture_target_pc_q);
  wire branch_target_cache_capture_w =
      branch_target_capture_hit_w && branch_target_capture_safe_w;
  wire [`XLEN-1:0] pending_branch_target_w =
      pending_branch_pc_q + pending_branch_imm_q;
  wire branch_prefetch_predict_taken_w = pending_branch_imm_q[`XLEN-1];
  wire [`XLEN-1:0] branch_prefetch_pred_pc_w =
      branch_prefetch_predict_taken_w ? pending_branch_target_w :
                                        pending_branch_next_pc_q;
  wire branch_prefetch_req_valid_w =
      stop_pending_q && pending_branch_q && pending_branch_dispatched_q &&
      !branch_prefetch_active_q && !outstanding_valid_q &&
      !discard_fetch_rsp_q && !branch_resolve_pending_match_w &&
      !branch_spec_checkpoint_pending_q && !branch_spec_active_q &&
      !halted_q && !trap_valid_q && !exit_valid_q;
  wire branch_prefetch_rsp_capture_w =
      branch_prefetch_active_q && !branch_prefetch_buffer_valid_q &&
      stop_pending_q && pending_branch_q && pending_branch_dispatched_q &&
      fetch_rsp_fire_w;
  wire branch_prefetch_match_w =
      branch_prefetch_active_q &&
      (branch_prefetch_pc_q == core_branch_resolve_next_pc_w);
  wire branch_prefetch_buffer_match_w =
      branch_prefetch_match_w && branch_prefetch_buffer_valid_q;
  wire branch_prefetch_rsp_match_w =
      branch_prefetch_match_w && branch_prefetch_rsp_capture_w;
  wire branch_prefetch_hit_available_w =
      branch_prefetch_buffer_match_w || branch_prefetch_rsp_match_w;
  wire branch_prefetch_pending_match_w =
      branch_prefetch_match_w && !branch_prefetch_hit_available_w;
  wire branch_prefetch_req_fire_w =
      branch_prefetch_req_valid_w && fetch_req_ready_i;
  wire [`XLEN-1:0] branch_prefetch_hit_pc0_w =
      branch_prefetch_rsp_match_w ? fetch_dec0_pc_w :
                                    branch_prefetch_buf_pc0_q;
  wire [`XLEN-1:0] branch_prefetch_hit_pc1_w =
      branch_prefetch_rsp_match_w ? fetch_dec1_pc_w :
                                    branch_prefetch_buf_pc1_q;
  wire [`XLEN-1:0] branch_prefetch_hit_next_pc0_w =
      branch_prefetch_rsp_match_w ? fetch_dec0_next_pc_w :
                                    branch_prefetch_buf_next_pc0_q;
  wire [`XLEN-1:0] branch_prefetch_hit_next_pc1_w =
      branch_prefetch_rsp_match_w ? fetch_dec1_next_pc_w :
                                    branch_prefetch_buf_next_pc1_q;
  wire [`XLEN-1:0] branch_prefetch_hit_packet_next_pc_w =
      branch_prefetch_rsp_match_w ? fetch_rsp_packet_next_pc_w :
                                    branch_prefetch_buf_packet_next_pc_q;
  wire [`INST_W-1:0] branch_prefetch_hit_inst0_w =
      branch_prefetch_rsp_match_w ? fetch_dec0_inst_w :
                                    branch_prefetch_buf_inst0_q;
  wire [`INST_W-1:0] branch_prefetch_hit_inst1_w =
      branch_prefetch_rsp_match_w ? fetch_dec1_inst_w :
                                    branch_prefetch_buf_inst1_q;
  wire [1:0] branch_prefetch_hit_resp0_w =
      branch_prefetch_rsp_match_w ? fetch_rsp_resp0_i :
                                    branch_prefetch_buf_resp0_q;
  wire [1:0] branch_prefetch_hit_resp1_w =
      branch_prefetch_rsp_match_w ? fetch_dec1_resp_w :
                                    branch_prefetch_buf_resp1_q;
  wire [`XLEN-1:0] fetch_req_seq_pc_w =
      (outstanding_valid_q && fetch_rsp_fire_w) ?
      fetch_rsp_packet_next_pc_w : next_fetch_pc_q;
  wire branch_resolve_pending_match_w =
      core_branch_resolve_valid_w &&
      (core_branch_resolve_pc_w == pending_branch_pc_q);
  wire branch_resolve_redirect_w = stop_pending_q && pending_branch_q &&
                                   pending_branch_dispatched_q &&
                                   branch_resolve_pending_match_w &&
                                   !core_branch_resolve_misaligned_w &&
                                   !branch_prefetch_match_w;
  wire backend_execute_quiet_w =
      !execute0_valid_unused_w && !execute1_valid_unused_w &&
      !mem_rsp_ready_o && !mem1_rsp_ready_o;
  wire branch_spec_checkpoint_capture_w =
      branch_spec_checkpoint_pending_q && stop_pending_q &&
      pending_branch_q && pending_branch_dispatched_q &&
      backend_execute_quiet_w;
  wire branch_spec_resolve_valid_w =
      branch_spec_active_q && pending_branch_q &&
      pending_branch_dispatched_q && branch_resolve_pending_match_w;
  wire branch_spec_pred_match_w =
      !core_branch_resolve_misaligned_w &&
      (core_branch_resolve_next_pc_w == branch_spec_pred_pc_q);
  wire branch_spec_restore_w =
      branch_spec_resolve_valid_w && !branch_spec_pred_match_w;
  wire branch_spec_redirect_w =
      branch_spec_restore_w && !core_branch_resolve_misaligned_w;
  wire branch_resolve_untracked_w =
      core_branch_resolve_valid_w &&
      !branch_resolve_pending_match_w &&
      !branch_spec_resolve_valid_w &&
      !direct_branch_resolve_valid_w;
  wire branch_resolve_untracked_redirect_w =
      branch_resolve_untracked_w && !core_branch_resolve_misaligned_w;
  wire direct_redirect_fetch_w =
      direct_jal_fire_w || direct_ret0_fire_w || direct_ret1_fire_w ||
      direct_branch0_lane1_ret_w ||
      pending_jump_nolink_commit_w ||
      direct_branch_resolve_redirect_w;
  wire redirect_fetch_req_valid_w =
      (direct_redirect_fetch_w || branch_resolve_redirect_w ||
       branch_spec_redirect_w || branch_resolve_untracked_redirect_w) &&
      (!outstanding_valid_q || fetch_rsp_fire_w);
  wire [`XLEN-1:0] redirect_fetch_pc_w =
      direct_jal_fire_w ? direct_jal_target_w :
      (direct_ret0_fire_w || direct_ret1_fire_w) ? direct_ret_target_w :
      direct_branch0_lane1_ret_w ? (return_cont_dispatch_w ?
                                    return_cont_next_pc_q : ras_top_w) :
      branch_target_dispatch_w ?
      branch_target_cache_next_pc_q[branch_target_cache_head_idx_w] :
      branch_fallthrough_dispatch_w ? head_next_pc1_w :
      direct_branch_resolve_redirect_w ?
          core_dispatch_branch_resolve_next_pc_w :
      pending_jump_nolink_commit_w ? pending_jump_resolved_target_w :
      branch_spec_redirect_w ? core_branch_resolve_next_pc_w :
                           core_branch_resolve_next_pc_w;
  wire [`XLEN-1:0] fetch_req_pc_w =
      redirect_fetch_req_valid_w ? redirect_fetch_pc_w :
      branch_prefetch_req_valid_w ? branch_prefetch_pred_pc_w :
                                    fetch_req_seq_pc_w;
  wire can_issue_request_w = can_run_w && !stop_head_w &&
                             !fetch_rsp_control_stop_w &&
                             !discard_fetch_rsp_q &&
                             fifo_reserve_available_w &&
                             (!outstanding_valid_q || fetch_rsp_fire_w);
  wire fetch_req_fire_w = fetch_req_valid_o && fetch_req_ready_i;
  wire frontend_dispatch_to_backend_valid_w =
      dispatch_valid_w && !dispatch0_branch_w && !dispatch0_jal_w &&
      !dispatch0_jump_w && !dispatch1_barrier_w &&
      !dispatch1_control_unsupported_w &&
      !dispatch1_mem_unsupported_w;
  wire lane1_barrier_dispatch0_valid_w =
      dispatch1_barrier_w;

  wire execute0_valid_unused_w;
  wire execute1_valid_unused_w;
  wire core_branch_resolve_valid_w;
  wire [`XLEN-1:0] core_branch_resolve_pc_w;
  wire [`XLEN-1:0] core_branch_resolve_next_pc_w;
  wire core_branch_resolve_misaligned_w;
  wire core_dispatch_branch_resolve_valid_w;
  wire [`XLEN-1:0] core_dispatch_branch_resolve_pc_w;
  wire [`XLEN-1:0] core_dispatch_branch_resolve_next_pc_w;
  wire core_dispatch_branch_resolve_misaligned_w;
  wire [`XLEN-1:0] a0_data_w;
  wire core_commit0_valid_w;
  wire [`XLEN-1:0] core_commit0_pc_w;
  wire [`XLEN-1:0] core_commit0_next_pc_w;
  wire [`INST_W-1:0] core_commit0_inst_w;
  wire core_commit0_rd_en_w;
  wire [`REG_ADDR_W-1:0] core_commit0_rd_addr_w;
  wire [`XLEN-1:0] core_commit0_rd_data_w;
  wire core_commit0_exception_w;
  wire core_commit0_write_w;
  wire core_commit1_valid_w;
  wire [`XLEN-1:0] core_commit1_pc_w;
  wire [`XLEN-1:0] core_commit1_next_pc_w;
  wire [`INST_W-1:0] core_commit1_inst_w;
  wire core_commit1_rd_en_w;
  wire [`REG_ADDR_W-1:0] core_commit1_rd_addr_w;
  wire [`XLEN-1:0] core_commit1_rd_data_w;
  wire core_commit1_exception_w;
  wire core_commit1_write_w;
  wire [1:0] core_retire_count_w;
  wire [`XLEN * `REG_NUM - 1:0] core_debug_gprs_w;
  wire [`XLEN-1:0] pending_branch_rs1_data_w;
  wire [`XLEN-1:0] pending_branch_rs2_data_w;
  wire [`XLEN-1:0] pending_jump_rs1_data_w;
  wire pending_branch_taken_w;
  wire [`XLEN-1:0] pending_branch_fallthrough_w =
      pending_branch_next_pc_q;
  wire [`XLEN-1:0] pending_branch_next_pc_w =
      pending_branch_taken_w ? pending_branch_target_w :
                               pending_branch_fallthrough_w;
  wire pending_branch_misaligned_w =
      pending_branch_taken_w && pending_branch_target_w[0];
  wire [`XLEN-1:0] pending_jump_jal_target_w =
      pending_jump_pc_q + pending_jump_imm_q;
  wire [`XLEN-1:0] pending_jump_jalr_sum_w =
      pending_jump_rs1_data_w + pending_jump_imm_q;
  wire pending_jump_jalr_sum_lsb_unused_w = pending_jump_jalr_sum_w[0];
  wire [`XLEN-1:0] pending_jump_resolved_target_w =
      pending_jump_jalr_q ? {pending_jump_jalr_sum_w[`XLEN-1:1], 1'b0} :
                            pending_jump_jal_target_w;
  wire pending_jump_misaligned_w =
      pending_jump_resolved_target_w[0];
  wire pending_jump_return_w =
      pending_jump_q && pending_jump_jalr_q && !ras_empty_w &&
      (pending_jump_inst_q[11:7] == 5'd0) &&
      ((pending_jump_rs1_q == 5'd1) || (pending_jump_rs1_q == 5'd5)) &&
      (pending_jump_imm_q == {`XLEN{1'b0}});
  wire pending_jump_return_fire_w =
      pending_jump_return_w && pending_jump_resolve_ready_w &&
      jump_dispatch_fire_w && !pending_jump_misaligned_w;
  wire pending_jump_call_w =
      pending_jump_q && pending_jump_jalr_q &&
      ((pending_jump_inst_q[11:7] == 5'd1) ||
       (pending_jump_inst_q[11:7] == 5'd5));
  wire pending_jump_call_fire_w =
      pending_jump_call_w && pending_jump_resolve_ready_w &&
      jump_dispatch_fire_w && !pending_jump_misaligned_w;
  wire pending_jump_nolink_w =
      pending_jump_q && pending_jump_jalr_q && !pending_jump_return_w &&
      (pending_jump_inst_q[11:7] == 5'd0);
  wire pending_jump_nolink_commit_w =
      pending_jump_nolink_w && pending_jump_resolve_ready_w &&
      !pending_jump_misaligned_w && commit_ready_i;
  wire pending_control_ready_w = !pending_branch_q || commit_ready_i;
  wire synth_lane1_ret_branch_commit0_w =
      synth_lane1_ret_pending_q && !synth_lane1_ret_branch_seen_q &&
      core_commit0_valid_w &&
      (core_commit0_pc_w == synth_lane1_ret_branch_pc_q);
  wire synth_lane1_ret_branch_commit1_w =
      synth_lane1_ret_pending_q && !synth_lane1_ret_branch_seen_q &&
      core_commit1_valid_w &&
      (core_commit1_pc_w == synth_lane1_ret_branch_pc_q);
  wire return_cont_optional_w = dispatch0_branch_w && return_cont_match_w;
  wire [BRANCH_TARGET_CACHE_INDEX_W-1:0] branch_target_cache_head_idx_w =
      head_pc_w[BRANCH_TARGET_CACHE_INDEX_W+1:2];
  wire [BRANCH_TARGET_CACHE_INDEX_W-1:0] branch_target_cache_capture_idx_w =
      branch_target_capture_branch_pc_q[BRANCH_TARGET_CACHE_INDEX_W+1:2];
  wire branch_target_cache_hit_w =
      branch_target_cache_valid_q[branch_target_cache_head_idx_w] &&
      (branch_target_cache_branch_pc_q[branch_target_cache_head_idx_w] ==
       head_pc_w) &&
      (branch_target_cache_target_pc_q[branch_target_cache_head_idx_w] ==
       direct_branch_target_w);
  wire branch_target_cache_invalidate_w =
      (mem_req_valid_o && mem_req_ready_i && mem_req_write_o) ||
      (mem1_req_valid_o && mem1_req_ready_i && mem1_req_write_o) ||
      (core_commit0_valid_w &&
       (core_commit0_inst_w[6:0] == `OPCODE_MISC_MEM)) ||
      (core_commit1_valid_w &&
       (core_commit1_inst_w[6:0] == `OPCODE_MISC_MEM));
  /* verilator lint_off UNOPTFLAT */
  wire return_cont_attempt_w =
      direct_branch0_lane1_ret_w &&
      !ctrl_commit_valid_q && commit_ready_i &&
      return_cont_match_w &&
      core_commit0_valid_w && !core_commit1_valid_w &&
      (rob_count_o == {{(ROB_COUNT_W-1){1'b0}}, 1'b1});
  wire branch_target_append_candidate_w =
      dispatch0_branch_w && branch_target_cache_hit_w && !ctrl_commit_valid_q;
  wire branch_fallthrough_append_candidate_w =
      dispatch0_branch_w && branch_fallthrough_safe_w && !ctrl_commit_valid_q;
  wire branch_target_append_attempt_w =
      direct_branch0_fire_w && direct_branch_resolve_taken_w &&
      branch_target_cache_hit_w && !direct_branch0_lane1_ret_w &&
      !ctrl_commit_valid_q;
  wire branch_fallthrough_append_attempt_w =
      direct_branch0_fire_w && direct_branch_resolve_redirect_w &&
      !direct_branch_resolve_taken_w && branch_fallthrough_safe_w &&
      !direct_branch0_lane1_ret_w && !ctrl_commit_valid_q;
  wire synth_lane1_branch_append_w =
      return_cont_attempt_w && dispatch1_ready_w;
  wire branch_target_append_w =
      branch_target_append_attempt_w && dispatch1_ready_w;
  wire branch_fallthrough_append_w =
      branch_fallthrough_append_attempt_w && dispatch1_ready_w;
  wire return_cont_dispatch_w = synth_lane1_branch_append_w;
  wire branch_target_dispatch_w = branch_target_append_w;
  wire branch_fallthrough_dispatch_w = branch_fallthrough_append_w;
  wire dispatch1_optional_w =
      return_cont_optional_w || branch_target_append_candidate_w ||
      branch_fallthrough_append_candidate_w;
  /* verilator lint_on UNOPTFLAT */
  wire synth_lane1_branch_drop_match_w =
      synth_lane1_branch_drop_pending_q &&
      core_commit0_valid_w &&
      (core_commit0_pc_w == synth_lane1_branch_drop_pc_q);
  wire synth_lane1_ret_drop_branch_w =
      synth_lane1_branch_drop_match_w &&
      synth_lane1_ret_pending_q && synth_lane1_ret_branch_seen_q &&
      !ctrl_commit_valid_q && commit_ready_i;
  wire synth_lane1_ret_before_core0_w =
      synth_lane1_ret_pending_q && synth_lane1_ret_branch_seen_q &&
      !synth_lane1_branch_drop_match_w &&
      !ctrl_commit_valid_q && commit_ready_i;
  wire synth_lane1_ret_after_core0_w =
      !ctrl_commit_valid_q && synth_lane1_ret_branch_commit0_w;
  wire synth_lane1_ret_commit_w =
      synth_lane1_ret_before_core0_w ||
      synth_lane1_ret_after_core0_w ||
      synth_lane1_ret_drop_branch_w;
  wire backend_drained_w = (rob_count_o == {ROB_COUNT_W{1'b0}}) &&
                           (issue_count_o == {ISSUE_COUNT_W{1'b0}}) &&
                           (core_retire_count_w == 2'b00) &&
                           !synth_lane1_ret_pending_q &&
                           !synth_lane1_branch_drop_pending_q;
  wire direct_branch_spec_start_w =
      direct_branch_fire_w && backend_drained_w &&
      (!direct_branch1_fire_w || !head0_mem_raw_w);
  wire pending_jump_resolve_ready_w = stop_pending_q && pending_jump_q &&
                                      !pending_jump_dispatched_q &&
                                      backend_drained_q;
  wire jump_dispatch_valid_w = pending_jump_resolve_ready_w &&
                               !pending_jump_nolink_w &&
                               !pending_jump_misaligned_w;
  wire pending_lane1_ret_dispatch_valid_w = pending_lane1_ret_q;
  wire pending_lane1_ret_fire_w =
      pending_lane1_ret_dispatch_valid_w && dispatch0_ready_w;
  wire pending_mem_resolve_ready_w = stop_pending_q && pending_mem_q &&
                                     !pending_mem_dispatched_q &&
                                     backend_drained_q;
  wire mem_dispatch_valid_w = pending_mem_resolve_ready_w;
  wire pending_replay_wait_w =
      (pending_jump_q && !pending_jump_dispatched_q) ||
      (pending_mem_q && !pending_mem_dispatched_q);
  wire drain_complete_w = stop_pending_q && backend_drained_w &&
                          pending_control_ready_w &&
                          !pending_replay_wait_w;
  wire core_checkpoint_capture_w = branch_spec_checkpoint_capture_w;
  wire core_checkpoint_restore_w = branch_spec_restore_w;
  wire core_checkpoint_quiesce_w =
      branch_spec_checkpoint_pending_q && !core_checkpoint_capture_w;
  wire core_mem_issue_block_w = branch_spec_active_q;
  wire core_commit_ready_w =
      commit_ready_i && !branch_spec_checkpoint_pending_q &&
      !branch_spec_active_q && !core_checkpoint_restore_w;
  wire core_commit1_block_w =
      !ctrl_commit_valid_q && synth_lane1_ret_pending_q &&
      !synth_lane1_branch_drop_match_w &&
      (synth_lane1_ret_branch_seen_q ||
       synth_lane1_ret_branch_commit0_w);
  wire core_dispatch0_valid_w =
      pending_lane1_ret_dispatch_valid_w ||
      frontend_dispatch_to_backend_valid_w ||
      direct_branch0_dispatch_valid_w ||
      direct_jal0_dispatch_valid_w ||
      direct_ret0_dispatch_valid_w ||
      lane1_barrier_dispatch0_valid_w ||
      jump_dispatch_valid_w || mem_dispatch_valid_w;
  /* verilator lint_off UNOPTFLAT */
  wire core_dispatch1_valid_w =
      !pending_lane1_ret_dispatch_valid_w &&
      (return_cont_attempt_w || branch_target_append_attempt_w ||
       branch_fallthrough_append_attempt_w ||
       frontend_dispatch_to_backend_valid_w);
  /* verilator lint_on UNOPTFLAT */
  wire core_dispatch0_fire_w = core_dispatch0_valid_w && dispatch0_ready_w;
  wire [`XLEN-1:0] core_dispatch0_pc_w =
      pending_lane1_ret_dispatch_valid_w ? pending_lane1_ret_pc_q :
      jump_dispatch_valid_w ? pending_jump_pc_q :
      mem_dispatch_valid_w ? pending_mem_pc_q :
      head_pc_w;
  wire [`XLEN-1:0] core_dispatch0_next_pc_w =
      pending_lane1_ret_dispatch_valid_w ? pending_lane1_ret_next_pc_q :
      jump_dispatch_valid_w ? pending_jump_next_pc_q :
      mem_dispatch_valid_w ? pending_mem_next_pc_q :
      head_next_pc0_w;
  wire [`INST_W-1:0] core_dispatch0_inst_w =
      pending_lane1_ret_dispatch_valid_w ? pending_lane1_ret_inst_q :
      jump_dispatch_valid_w ? pending_jump_inst_q :
      mem_dispatch_valid_w ? pending_mem_inst_q :
      head_inst0_w;
  wire [`XLEN-1:0] core_dispatch1_pc_w =
      return_cont_attempt_w ? return_cont_pc_q :
      branch_target_append_attempt_w ?
      branch_target_cache_target_pc_q[branch_target_cache_head_idx_w] :
                                       head_pc1_w;
  wire [`XLEN-1:0] core_dispatch1_next_pc_w =
      return_cont_attempt_w ? return_cont_next_pc_q :
      branch_target_append_attempt_w ?
      branch_target_cache_next_pc_q[branch_target_cache_head_idx_w] :
                                       head_next_pc1_w;
  wire [`INST_W-1:0] core_dispatch1_inst_w =
      return_cont_attempt_w ? return_cont_inst_q :
      branch_target_append_attempt_w ?
      branch_target_cache_inst_q[branch_target_cache_head_idx_w] :
                                       head_inst1_w;
  wire jump_dispatch_fire_w = jump_dispatch_valid_w && dispatch0_ready_w;
  wire mem_dispatch_fire_w = mem_dispatch_valid_w && dispatch0_ready_w;

  assign fetch_req_valid_o = redirect_fetch_req_valid_w ||
                             branch_prefetch_req_valid_w ||
                             can_issue_request_w;
  assign fetch_req_pc_o = fetch_req_pc_w;
  assign fetch_rsp_ready_o = fetch_rsp_can_enqueue_w ||
                             fetch_rsp_dispatch_bypass_w ||
                             fetch_rsp_can_drop_w || direct_fetch_drop_w;

  function [`XLEN-1:0] arch_gpr;
    input [`XLEN * `REG_NUM - 1:0] gprs;
    input [`REG_ADDR_W-1:0] idx;
    begin
      arch_gpr = gprs[idx * `XLEN +: `XLEN];
    end
  endfunction

  assign pending_branch_rs1_data_w =
      arch_gpr(core_debug_gprs_w, pending_branch_rs1_q);
  assign pending_branch_rs2_data_w =
      arch_gpr(core_debug_gprs_w, pending_branch_rs2_q);
  assign pending_jump_rs1_data_w =
      arch_gpr(core_debug_gprs_w, pending_jump_rs1_q);

  DecodeStage u_head0_decode (
    .inst_i(head_inst0_w),
    .ctrl_o(head0_ctrl_w),
    .rs1_idx_o(head0_rs1_w),
    .rs2_idx_o(head0_rs2_w),
    .rd_idx_o(head0_rd_unused_w),
    .imm_o(head0_imm_w)
  );

  DecodeStage u_head1_decode (
    .inst_i(head_inst1_w),
    .ctrl_o(head1_ctrl_w),
    .rs1_idx_o(head1_rs1_w),
    .rs2_idx_o(head1_rs2_w),
    .rd_idx_o(head1_rd_unused_w),
    .imm_o(head1_imm_w)
  );

  DecodeStage u_branch_target_capture_decode (
    .inst_i(fetch_dec0_inst_w),
    .ctrl_o(branch_target_capture_ctrl_w),
    .rs1_idx_o(branch_target_capture_rs1_unused_w),
    .rs2_idx_o(branch_target_capture_rs2_unused_w),
    .rd_idx_o(branch_target_capture_rd_unused_w),
    .imm_o(branch_target_capture_imm_unused_w)
  );

  CompareUnit u_pending_branch_compare (
    .lhs_i(pending_branch_rs1_data_w),
    .rhs_i(pending_branch_rs2_data_w),
    .cmp_op_i(pending_branch_cmp_op_q),
    .cmp_true_o(pending_branch_taken_w)
  );

  OooAluCoreSlice #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_core_slice (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .checkpoint_capture_i(core_checkpoint_capture_w),
    .checkpoint_restore_i(core_checkpoint_restore_w),
    .checkpoint_quiesce_i(core_checkpoint_quiesce_w),
    .mem_issue_block_i(core_mem_issue_block_w),
    .dispatch0_valid_i(core_dispatch0_valid_w),
    .dispatch0_ready_o(dispatch0_ready_w),
    .dispatch0_pc_i(core_dispatch0_pc_w),
    .dispatch0_next_pc_i(core_dispatch0_next_pc_w),
    .dispatch0_inst_i(core_dispatch0_inst_w),
    .dispatch0_unsupported_o(dispatch0_unsupported_w),
    .dispatch1_valid_i(core_dispatch1_valid_w),
    .dispatch1_optional_i(dispatch1_optional_w),
    .dispatch1_ready_o(dispatch1_ready_w),
    .dispatch1_pc_i(core_dispatch1_pc_w),
    .dispatch1_next_pc_i(core_dispatch1_next_pc_w),
    .dispatch1_inst_i(core_dispatch1_inst_w),
    .dispatch1_unsupported_o(dispatch1_unsupported_w),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_write_o(mem_req_write_o),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_req_wdata_o(mem_req_wdata_o),
    .mem_req_wstrb_o(mem_req_wstrb_o),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_rsp_rdata_i(mem_rsp_rdata_i),
    .mem_rsp_error_i(mem_rsp_error_i),
    .mem1_req_valid_o(mem1_req_valid_o),
    .mem1_req_ready_i(mem1_req_ready_i),
    .mem1_req_write_o(mem1_req_write_o),
    .mem1_req_addr_o(mem1_req_addr_o),
    .mem1_req_wdata_o(mem1_req_wdata_o),
    .mem1_req_wstrb_o(mem1_req_wstrb_o),
    .mem1_rsp_valid_i(mem1_rsp_valid_i),
    .mem1_rsp_ready_o(mem1_rsp_ready_o),
    .mem1_rsp_rdata_i(mem1_rsp_rdata_i),
    .mem1_rsp_error_i(mem1_rsp_error_i),
    .commit_ready_i(core_commit_ready_w),
    .commit1_block_i(core_commit1_block_w),
    .commit0_valid_o(core_commit0_valid_w),
    .commit0_pc_o(core_commit0_pc_w),
    .commit0_next_pc_o(core_commit0_next_pc_w),
    .commit0_inst_o(core_commit0_inst_w),
    .commit0_rd_en_o(core_commit0_rd_en_w),
    .commit0_arch_rd_o(core_commit0_rd_addr_w),
    .commit0_data_o(core_commit0_rd_data_w),
    .commit0_exception_o(core_commit0_exception_w),
    .commit0_write_o(core_commit0_write_w),
    .commit1_valid_o(core_commit1_valid_w),
    .commit1_pc_o(core_commit1_pc_w),
    .commit1_next_pc_o(core_commit1_next_pc_w),
    .commit1_inst_o(core_commit1_inst_w),
    .commit1_rd_en_o(core_commit1_rd_en_w),
    .commit1_arch_rd_o(core_commit1_rd_addr_w),
    .commit1_data_o(core_commit1_rd_data_w),
    .commit1_exception_o(core_commit1_exception_w),
    .commit1_write_o(core_commit1_write_w),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
	    .issue_count_o(issue_count_o),
	    .execute0_valid_o(execute0_valid_unused_w),
	    .execute1_valid_o(execute1_valid_unused_w),
	    .branch_resolve_valid_o(core_branch_resolve_valid_w),
	    .branch_resolve_pc_o(core_branch_resolve_pc_w),
	    .branch_resolve_next_pc_o(core_branch_resolve_next_pc_w),
	    .branch_resolve_misaligned_o(core_branch_resolve_misaligned_w),
	    .dispatch_branch_resolve_valid_o(core_dispatch_branch_resolve_valid_w),
	    .dispatch_branch_resolve_pc_o(core_dispatch_branch_resolve_pc_w),
	    .dispatch_branch_resolve_next_pc_o(core_dispatch_branch_resolve_next_pc_w),
	    .dispatch_branch_resolve_misaligned_o(core_dispatch_branch_resolve_misaligned_w),
	    .retire_count_o(core_retire_count_w),
    .a0_data_o(a0_data_w),
    .debug_gprs_o(core_debug_gprs_w)
  );

  assign commit0_valid_o =
      ctrl_commit_valid_q ? 1'b1 :
      (synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ? 1'b1 :
      core_commit0_valid_w;
  assign commit0_pc_o =
      ctrl_commit_valid_q ? ctrl_commit_pc_q :
      (synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ? synth_lane1_ret_pc_q :
      core_commit0_pc_w;
  assign commit0_inst_o =
      ctrl_commit_valid_q ? ctrl_commit_inst_q :
      (synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ? synth_lane1_ret_inst_q :
      core_commit0_inst_w;
  assign commit0_next_pc_o =
      ctrl_commit_valid_q ? ctrl_commit_next_pc_q :
      (synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ? synth_lane1_ret_next_pc_q :
      core_commit0_next_pc_w;
  assign commit0_rd_en_o =
      (ctrl_commit_valid_q || synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ?
      1'b0 : core_commit0_rd_en_w;
  assign commit0_rd_addr_o =
      (ctrl_commit_valid_q || synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ?
      {`REG_ADDR_W{1'b0}} : core_commit0_rd_addr_w;
  assign commit0_rd_data_o =
      (ctrl_commit_valid_q || synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ?
      {`XLEN{1'b0}} : core_commit0_rd_data_w;
  assign commit0_exception_o =
      (ctrl_commit_valid_q || synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ?
      1'b0 : core_commit0_exception_w;
  assign commit0_write_o =
      (ctrl_commit_valid_q || synth_lane1_ret_before_core0_w ||
       synth_lane1_ret_drop_branch_w) ?
      1'b0 : core_commit0_write_w;
  assign commit1_valid_o =
      ctrl_commit_valid_q ? 1'b0 :
      synth_lane1_branch_append_w ? 1'b1 :
      synth_lane1_ret_after_core0_w ? 1'b1 :
      synth_lane1_ret_before_core0_w ? core_commit0_valid_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_valid_w :
      core_commit1_valid_w;
  assign commit1_pc_o =
      ctrl_commit_valid_q ? {`XLEN{1'b0}} :
      synth_lane1_branch_append_w ? head_pc_w :
      synth_lane1_ret_after_core0_w ? synth_lane1_ret_pc_q :
      synth_lane1_ret_before_core0_w ? core_commit0_pc_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_pc_w :
      core_commit1_pc_w;
  assign commit1_inst_o =
      ctrl_commit_valid_q ? {`INST_W{1'b0}} :
      synth_lane1_branch_append_w ? head_inst0_w :
      synth_lane1_ret_after_core0_w ? synth_lane1_ret_inst_q :
      synth_lane1_ret_before_core0_w ? core_commit0_inst_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_inst_w :
      core_commit1_inst_w;
  assign commit1_next_pc_o =
      ctrl_commit_valid_q ? {`XLEN{1'b0}} :
      synth_lane1_branch_append_w ? core_dispatch_branch_resolve_next_pc_w :
      synth_lane1_ret_after_core0_w ? synth_lane1_ret_next_pc_q :
      synth_lane1_ret_before_core0_w ? core_commit0_next_pc_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_next_pc_w :
      core_commit1_next_pc_w;
  assign commit1_rd_en_o =
      (ctrl_commit_valid_q || synth_lane1_branch_append_w ||
       synth_lane1_ret_after_core0_w) ?
      1'b0 :
      synth_lane1_ret_before_core0_w ? core_commit0_rd_en_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_rd_en_w :
      core_commit1_rd_en_w;
  assign commit1_rd_addr_o =
      (ctrl_commit_valid_q || synth_lane1_branch_append_w ||
       synth_lane1_ret_after_core0_w) ?
      {`REG_ADDR_W{1'b0}} :
      synth_lane1_ret_before_core0_w ? core_commit0_rd_addr_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_rd_addr_w :
      core_commit1_rd_addr_w;
  assign commit1_rd_data_o =
      (ctrl_commit_valid_q || synth_lane1_branch_append_w ||
       synth_lane1_ret_after_core0_w) ?
      {`XLEN{1'b0}} :
      synth_lane1_ret_before_core0_w ? core_commit0_rd_data_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_rd_data_w :
      core_commit1_rd_data_w;
  assign commit1_exception_o =
      (ctrl_commit_valid_q || synth_lane1_branch_append_w ||
       synth_lane1_ret_after_core0_w) ?
      1'b0 :
      synth_lane1_ret_before_core0_w ? core_commit0_exception_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_exception_w :
      core_commit1_exception_w;
  assign commit1_write_o =
      (ctrl_commit_valid_q || synth_lane1_branch_append_w ||
       synth_lane1_ret_after_core0_w) ?
      1'b0 :
      synth_lane1_ret_before_core0_w ? core_commit0_write_w :
      synth_lane1_ret_drop_branch_w ? core_commit1_write_w :
      core_commit1_write_w;
  assign trap_valid_o = trap_valid_q;
  assign trap_cause_o = trap_cause_q;
  assign trap_pc_o = trap_pc_q;
  assign trap_tval_o = trap_tval_q;
  assign exit_valid_o = exit_valid_q;
  assign exit_is_ecall_o = 1'b0;
  assign exit_is_ebreak_o = exit_valid_q;
  assign exit_code_o = a0_data_w;
  assign halted_o = halted_q ||
                    (stop_pending_q && !pending_branch_q && !pending_jump_q &&
                     !pending_mem_q && !synth_lane1_ret_pending_q &&
                     !synth_lane1_branch_drop_pending_q);
  assign debug_gprs_o = core_debug_gprs_w;
  assign retire_count_o = core_retire_count_w +
                          {1'b0, ctrl_commit_valid_q} +
                          {1'b0, synth_lane1_branch_append_w} +
                          {1'b0, synth_lane1_ret_commit_w} -
                          {1'b0, synth_lane1_ret_drop_branch_w};
  assign debug_pc_o = trap_valid_q ? trap_pc_q :
                      fifo_has_packet_w ? head_pc_w :
                      outstanding_valid_q ? outstanding_pc_q :
                      next_fetch_pc_q;
  assign debug_state_o =
      trap_valid_q ? `CORE_STATE_TRAP :
      halted_q ? `CORE_STATE_HALT :
      fifo_has_packet_w ? `CORE_STATE_DECODE :
      outstanding_valid_q ? `CORE_STATE_FETCH_WAIT :
      fetch_req_valid_o ? `CORE_STATE_FETCH_REQ :
      `CORE_STATE_FETCH_REQ;

  wire unused_core_slice_observe_w =
      execute0_valid_unused_w | execute1_valid_unused_w |
      (|head0_ctrl_w) | (|head0_rd_unused_w) |
      (|head1_ctrl_w) | (|head1_rd_unused_w) |
      (|branch_target_capture_ctrl_w) |
      (|branch_target_capture_rs1_unused_w) |
      (|branch_target_capture_rs2_unused_w) |
      (|branch_target_capture_rd_unused_w) |
      (|branch_target_capture_imm_unused_w) |
      branch_fallthrough_safe_w | branch_target_cache_hit_w |
      pending_jump_jalr_sum_lsb_unused_w | head_fetch_fault_w |
      (|head_packet_next_pc_w);

  integer reset_idx;
  integer ras_reset_idx;
  integer branch_target_cache_reset_idx;

  always @(posedge clk) begin
    if (rst || flush_i) begin
      next_fetch_pc_q <= reset_pc_i;
      outstanding_valid_q <= 1'b0;
      outstanding_pc_q <= {`XLEN{1'b0}};
      discard_fetch_rsp_q <= 1'b0;
      ras_count_q <= {RAS_COUNT_W{1'b0}};
      ras_reliable_q <= 1'b1;
      fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
      fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
      fifo_count_q <= {FETCH_COUNT_W{1'b0}};
      branch_prefetch_active_q <= 1'b0;
      branch_prefetch_buffer_valid_q <= 1'b0;
      branch_prefetch_pc_q <= {`XLEN{1'b0}};
      branch_prefetch_buf_pc0_q <= {`XLEN{1'b0}};
      branch_prefetch_buf_pc1_q <= {`XLEN{1'b0}};
      branch_prefetch_buf_next_pc0_q <= {`XLEN{1'b0}};
      branch_prefetch_buf_next_pc1_q <= {`XLEN{1'b0}};
      branch_prefetch_buf_packet_next_pc_q <= {`XLEN{1'b0}};
      branch_prefetch_buf_inst0_q <= {`INST_W{1'b0}};
      branch_prefetch_buf_inst1_q <= {`INST_W{1'b0}};
      branch_prefetch_buf_resp0_q <= 2'b00;
      branch_prefetch_buf_resp1_q <= 2'b00;
      branch_spec_active_q <= 1'b0;
      branch_spec_checkpoint_pending_q <= 1'b0;
      branch_spec_pred_pc_q <= {`XLEN{1'b0}};
      branch_target_capture_pending_q <= 1'b0;
      branch_target_capture_branch_pc_q <= {`XLEN{1'b0}};
      branch_target_capture_target_pc_q <= {`XLEN{1'b0}};
      trap_valid_q <= 1'b0;
      trap_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      trap_pc_q <= {`XLEN{1'b0}};
      trap_tval_q <= {`XLEN{1'b0}};
      exit_valid_q <= 1'b0;
      halted_q <= 1'b0;
      stop_pending_q <= 1'b0;
      pending_exit_q <= 1'b0;
      pending_branch_q <= 1'b0;
      pending_branch_dispatched_q <= 1'b0;
      pending_jump_q <= 1'b0;
      pending_jump_dispatched_q <= 1'b0;
      pending_jump_jalr_q <= 1'b0;
      pending_mem_q <= 1'b0;
      pending_mem_dispatched_q <= 1'b0;
      pending_trap_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      pending_trap_pc_q <= {`XLEN{1'b0}};
      pending_trap_tval_q <= {`XLEN{1'b0}};
      pending_branch_pc_q <= {`XLEN{1'b0}};
      pending_branch_next_pc_q <= {`XLEN{1'b0}};
      pending_branch_inst_q <= {`INST_W{1'b0}};
      pending_branch_rs1_q <= {`REG_ADDR_W{1'b0}};
      pending_branch_rs2_q <= {`REG_ADDR_W{1'b0}};
      pending_branch_imm_q <= {`XLEN{1'b0}};
      pending_branch_cmp_op_q <= `CMP_OP_NONE;
      pending_jump_pc_q <= {`XLEN{1'b0}};
      pending_jump_next_pc_q <= {`XLEN{1'b0}};
      pending_jump_inst_q <= {`INST_W{1'b0}};
      pending_jump_rs1_q <= {`REG_ADDR_W{1'b0}};
      pending_jump_imm_q <= {`XLEN{1'b0}};
      pending_jump_target_q <= {`XLEN{1'b0}};
      pending_lane1_ret_q <= 1'b0;
      pending_lane1_ret_pc_q <= {`XLEN{1'b0}};
      pending_lane1_ret_next_pc_q <= {`XLEN{1'b0}};
      pending_lane1_ret_inst_q <= {`INST_W{1'b0}};
      return_cont_valid_q <= 1'b0;
      return_cont_pc_q <= {`XLEN{1'b0}};
      return_cont_next_pc_q <= {`XLEN{1'b0}};
      return_cont_inst_q <= {`INST_W{1'b0}};
      synth_lane1_ret_pending_q <= 1'b0;
      synth_lane1_ret_branch_seen_q <= 1'b0;
      synth_lane1_ret_branch_pc_q <= {`XLEN{1'b0}};
      synth_lane1_ret_pc_q <= {`XLEN{1'b0}};
      synth_lane1_ret_next_pc_q <= {`XLEN{1'b0}};
      synth_lane1_ret_inst_q <= {`INST_W{1'b0}};
      synth_lane1_branch_drop_pending_q <= 1'b0;
      synth_lane1_branch_drop_pc_q <= {`XLEN{1'b0}};
      pending_mem_pc_q <= {`XLEN{1'b0}};
      pending_mem_inst_q <= {`INST_W{1'b0}};
      pending_mem_next_pc_q <= {`XLEN{1'b0}};
      ctrl_commit_valid_q <= 1'b0;
      ctrl_commit_pc_q <= {`XLEN{1'b0}};
      ctrl_commit_inst_q <= {`INST_W{1'b0}};
      ctrl_commit_next_pc_q <= {`XLEN{1'b0}};
      backend_drained_q <= 1'b1;
      for (reset_idx = 0; reset_idx < FETCH_PACKET_COUNT; reset_idx = reset_idx + 1) begin
        fifo_pc0_q[reset_idx] <= {`XLEN{1'b0}};
        fifo_pc1_q[reset_idx] <= {`XLEN{1'b0}};
        fifo_next_pc0_q[reset_idx] <= {`XLEN{1'b0}};
        fifo_next_pc1_q[reset_idx] <= {`XLEN{1'b0}};
        fifo_packet_next_pc_q[reset_idx] <= {`XLEN{1'b0}};
        fifo_inst0_q[reset_idx] <= {`INST_W{1'b0}};
        fifo_inst1_q[reset_idx] <= {`INST_W{1'b0}};
        fifo_resp0_q[reset_idx] <= 2'b00;
        fifo_resp1_q[reset_idx] <= 2'b00;
      end
      for (ras_reset_idx = 0; ras_reset_idx < RAS_DEPTH; ras_reset_idx = ras_reset_idx + 1) begin
        ras_stack_q[ras_reset_idx] <= {`XLEN{1'b0}};
      end
      for (branch_target_cache_reset_idx = 0;
           branch_target_cache_reset_idx < BRANCH_TARGET_CACHE_ENTRIES;
           branch_target_cache_reset_idx = branch_target_cache_reset_idx + 1) begin
        branch_target_cache_valid_q[branch_target_cache_reset_idx] <= 1'b0;
        branch_target_cache_branch_pc_q[branch_target_cache_reset_idx] <=
            {`XLEN{1'b0}};
        branch_target_cache_target_pc_q[branch_target_cache_reset_idx] <=
            {`XLEN{1'b0}};
        branch_target_cache_next_pc_q[branch_target_cache_reset_idx] <=
            {`XLEN{1'b0}};
        branch_target_cache_inst_q[branch_target_cache_reset_idx] <=
            {`INST_W{1'b0}};
      end
    end else begin
      ctrl_commit_valid_q <= 1'b0;
      backend_drained_q <= backend_drained_w && !core_dispatch0_fire_w;

      if (branch_target_cache_invalidate_w) begin
        for (branch_target_cache_reset_idx = 0;
             branch_target_cache_reset_idx < BRANCH_TARGET_CACHE_ENTRIES;
             branch_target_cache_reset_idx = branch_target_cache_reset_idx + 1) begin
          branch_target_cache_valid_q[branch_target_cache_reset_idx] <= 1'b0;
        end
      end else if (branch_target_cache_capture_w) begin
        branch_target_capture_pending_q <= 1'b0;
        branch_target_capture_branch_pc_q <= {`XLEN{1'b0}};
        branch_target_capture_target_pc_q <= {`XLEN{1'b0}};
        branch_target_cache_valid_q[branch_target_cache_capture_idx_w] <=
            1'b1;
        branch_target_cache_branch_pc_q[branch_target_cache_capture_idx_w] <=
            branch_target_capture_branch_pc_q;
        branch_target_cache_target_pc_q[branch_target_cache_capture_idx_w] <=
            branch_target_capture_target_pc_q;
        branch_target_cache_next_pc_q[branch_target_cache_capture_idx_w] <=
            fetch_dec0_next_pc_w;
        branch_target_cache_inst_q[branch_target_cache_capture_idx_w] <=
            fetch_dec0_inst_w;
      end else if (branch_target_capture_hit_w) begin
        branch_target_capture_pending_q <= 1'b0;
        branch_target_capture_branch_pc_q <= {`XLEN{1'b0}};
        branch_target_capture_target_pc_q <= {`XLEN{1'b0}};
      end

      if (pending_lane1_ret_fire_w) begin
        pending_lane1_ret_q <= 1'b0;
        pending_lane1_ret_pc_q <= {`XLEN{1'b0}};
        pending_lane1_ret_next_pc_q <= {`XLEN{1'b0}};
        pending_lane1_ret_inst_q <= {`INST_W{1'b0}};
      end

      if (return_cont_dispatch_w) begin
        return_cont_valid_q <= 1'b0;
        return_cont_pc_q <= {`XLEN{1'b0}};
        return_cont_next_pc_q <= {`XLEN{1'b0}};
        return_cont_inst_q <= {`INST_W{1'b0}};
      end

      if (direct_jal_call_w) begin
        return_cont_valid_q <= return_cont_capture_w;
        return_cont_pc_q <= return_cont_capture_w ? head_pc1_w :
                                                 {`XLEN{1'b0}};
        return_cont_next_pc_q <= return_cont_capture_w ? head_next_pc1_w :
                                                      {`XLEN{1'b0}};
        return_cont_inst_q <= return_cont_capture_w ? head_inst1_w :
                                                   {`INST_W{1'b0}};
      end

      if (synth_lane1_ret_commit_w) begin
        synth_lane1_ret_pending_q <= 1'b0;
        synth_lane1_ret_branch_seen_q <= 1'b0;
        synth_lane1_ret_branch_pc_q <= {`XLEN{1'b0}};
        synth_lane1_ret_pc_q <= {`XLEN{1'b0}};
        synth_lane1_ret_next_pc_q <= {`XLEN{1'b0}};
        synth_lane1_ret_inst_q <= {`INST_W{1'b0}};
        synth_lane1_branch_drop_pending_q <= 1'b0;
        synth_lane1_branch_drop_pc_q <= {`XLEN{1'b0}};
      end else if (synth_lane1_branch_drop_match_w) begin
        synth_lane1_branch_drop_pending_q <= 1'b0;
        synth_lane1_branch_drop_pc_q <= {`XLEN{1'b0}};
      end else if (synth_lane1_ret_branch_commit1_w) begin
        synth_lane1_ret_branch_seen_q <= 1'b1;
      end

      if (branch_prefetch_req_fire_w) begin
        // 分支预测包只进入影子槽，resolve 命中前绝不暴露给正常 dispatch FIFO。
        branch_prefetch_active_q <= 1'b1;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= branch_prefetch_pred_pc_w;
      end

      if (branch_prefetch_rsp_capture_w) begin
        branch_prefetch_buffer_valid_q <= 1'b1;
        branch_prefetch_buf_pc0_q <= fetch_dec0_pc_w;
        branch_prefetch_buf_pc1_q <= fetch_dec1_pc_w;
        branch_prefetch_buf_next_pc0_q <= fetch_dec0_next_pc_w;
        branch_prefetch_buf_next_pc1_q <= fetch_dec1_next_pc_w;
        branch_prefetch_buf_packet_next_pc_q <= fetch_rsp_packet_next_pc_w;
        branch_prefetch_buf_inst0_q <= fetch_dec0_inst_w;
        branch_prefetch_buf_inst1_q <= fetch_dec1_inst_w;
        branch_prefetch_buf_resp0_q <= fetch_rsp_resp0_i;
        branch_prefetch_buf_resp1_q <= fetch_dec1_resp_w;
      end

      if (fetch_rsp_enqueue_w) begin
        fifo_pc0_q[fifo_tail_q] <= fetch_dec0_pc_w;
        fifo_pc1_q[fifo_tail_q] <= fetch_dec1_pc_w;
        fifo_next_pc0_q[fifo_tail_q] <= fetch_dec0_next_pc_w;
        fifo_next_pc1_q[fifo_tail_q] <= fetch_dec1_next_pc_w;
        fifo_packet_next_pc_q[fifo_tail_q] <= fetch_rsp_packet_next_pc_w;
        fifo_inst0_q[fifo_tail_q] <= fetch_dec0_inst_w;
        fifo_inst1_q[fifo_tail_q] <= fetch_dec1_inst_w;
        fifo_resp0_q[fifo_tail_q] <= fetch_rsp_resp0_i;
        fifo_resp1_q[fifo_tail_q] <= fetch_dec1_resp_w;
        fifo_tail_q <= ptr_inc(fifo_tail_q);
      end

      if (fifo_storage_pop_w) begin
        fifo_head_q <= ptr_inc(fifo_head_q);
      end

      case ({fetch_rsp_enqueue_w, fifo_storage_pop_w})
        2'b10: fifo_count_q <= fifo_count_q + {{(FETCH_COUNT_W-1){1'b0}}, 1'b1};
        2'b01: fifo_count_q <= fifo_count_q - {{(FETCH_COUNT_W-1){1'b0}}, 1'b1};
        default: fifo_count_q <= fifo_count_q;
      endcase

      if ((fetch_rsp_enqueue_w || fetch_rsp_bypass_consumed_w) &&
          !fetch_req_fire_w) begin
        next_fetch_pc_q <= fetch_rsp_packet_next_pc_w;
      end else if (fetch_req_fire_w) begin
        next_fetch_pc_q <= fetch_req_pc_w;
      end

      if (fetch_rsp_fire_w && !fetch_req_fire_w) begin
        outstanding_valid_q <= 1'b0;
      end else if (fetch_req_fire_w) begin
        outstanding_valid_q <= 1'b1;
        outstanding_pc_q <= fetch_req_pc_w;
      end

      if (direct_frontend_flush_w) begin
        fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_count_q <= {FETCH_COUNT_W{1'b0}};
        pending_lane1_ret_q <= 1'b0;
        pending_lane1_ret_pc_q <= {`XLEN{1'b0}};
        pending_lane1_ret_next_pc_q <= {`XLEN{1'b0}};
        pending_lane1_ret_inst_q <= {`INST_W{1'b0}};
        branch_prefetch_active_q <= 1'b0;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= {`XLEN{1'b0}};
        branch_spec_active_q <= 1'b0;
        branch_spec_checkpoint_pending_q <= 1'b0;
        branch_spec_pred_pc_q <= {`XLEN{1'b0}};
        branch_target_capture_pending_q <= 1'b0;
        branch_target_capture_branch_pc_q <= {`XLEN{1'b0}};
        branch_target_capture_target_pc_q <= {`XLEN{1'b0}};
        outstanding_valid_q <= fetch_req_fire_w;
        outstanding_pc_q <= fetch_req_fire_w ? fetch_req_pc_w :
                                                {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_w;
        if (direct_jal_fire_w) begin
          next_fetch_pc_q <= direct_jal_target_w;
        end else if (direct_ret0_fire_w || direct_ret1_fire_w) begin
          next_fetch_pc_q <= direct_ret_target_w;
        end else if (direct_branch0_fire_w || direct_branch1_fire_w) begin
          stop_pending_q <= !direct_branch_resolve_redirect_w;
          branch_spec_checkpoint_pending_q <=
              !direct_branch_resolve_redirect_w && direct_branch_spec_start_w;
          branch_spec_pred_pc_q <= (!direct_branch_resolve_redirect_w &&
                                    direct_branch_spec_start_w) ?
                                   direct_branch_pred_pc_w :
                                   {`XLEN{1'b0}};
          pending_exit_q <= 1'b0;
          pending_branch_q <= !direct_branch_resolve_redirect_w;
          pending_branch_dispatched_q <= !direct_branch_resolve_redirect_w;
          pending_jump_q <= 1'b0;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_pc_q <= direct_branch1_fire_w ? head_pc1_w :
                                                          head_pc_w;
          pending_branch_next_pc_q <= direct_branch1_fire_w ?
                                      head_next_pc1_w : head_next_pc0_w;
          pending_branch_inst_q <= direct_branch1_fire_w ? head_inst1_w :
                                                            head_inst0_w;
          pending_branch_rs1_q <= direct_branch1_fire_w ? head1_rs1_w :
                                                           head0_rs1_w;
          pending_branch_rs2_q <= direct_branch1_fire_w ? head1_rs2_w :
                                                           head0_rs2_w;
          pending_branch_imm_q <= direct_branch1_fire_w ? head1_imm_w :
                                                           head0_imm_w;
          pending_branch_cmp_op_q <=
              direct_branch1_fire_w ?
              head1_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] :
              head0_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          if (direct_branch_resolve_redirect_w &&
              !direct_branch0_lane1_ret_w && !branch_target_dispatch_w &&
              direct_branch_resolve_taken_w) begin
            branch_target_capture_pending_q <= 1'b1;
            branch_target_capture_branch_pc_q <= direct_branch1_fire_w ?
                                                 head_pc1_w : head_pc_w;
            branch_target_capture_target_pc_q <=
                core_dispatch_branch_resolve_next_pc_w;
          end
          if (direct_branch0_lane1_ret_w) begin
            synth_lane1_ret_pending_q <= 1'b1;
            synth_lane1_ret_branch_seen_q <= synth_lane1_branch_append_w;
            synth_lane1_ret_branch_pc_q <= head_pc_w;
            synth_lane1_ret_pc_q <= head_pc1_w;
            synth_lane1_ret_next_pc_q <= head_next_pc1_w;
            synth_lane1_ret_inst_q <= head_inst1_w;
            if (synth_lane1_branch_append_w) begin
              synth_lane1_branch_drop_pending_q <= 1'b1;
              synth_lane1_branch_drop_pc_q <= head_pc_w;
            end
          end
          next_fetch_pc_q <= direct_branch0_lane1_ret_w ?
                             (return_cont_dispatch_w ?
                              return_cont_next_pc_q : ras_top_w) :
	                             branch_target_dispatch_w ?
	                             branch_target_cache_next_pc_q[branch_target_cache_head_idx_w] :
                             branch_fallthrough_dispatch_w ?
                             head_next_pc1_w :
                             direct_branch_resolve_redirect_w ?
                             core_dispatch_branch_resolve_next_pc_w :
                             direct_branch_spec_start_w ?
                             direct_branch_pred_pc_w :
                             (direct_branch1_fire_w ? head_next_pc1_w :
                                                      head_next_pc0_w);
        end
      end else begin
        if (discard_fetch_rsp_q && fetch_rsp_fire_w) begin
          discard_fetch_rsp_q <= 1'b0;
        end
      end

      if (direct_ret0_fire_w || direct_ret1_fire_w ||
          pending_lane1_ret_fire_w ||
          pending_jump_return_fire_w ||
          direct_branch0_lane1_ret_w) begin
        ras_count_q <= ras_count_q - {{(RAS_COUNT_W-1){1'b0}}, 1'b1};
        if (ras_count_q == {{(RAS_COUNT_W-1){1'b0}}, 1'b1}) begin
          ras_reliable_q <= 1'b1;
        end
      end else if (direct_jal_call_w || pending_jump_call_fire_w) begin
        ras_stack_q[ras_push_idx_w] <= pending_jump_call_fire_w ?
                                      pending_jump_next_pc_q :
                                      direct_jal_link_w;
        if (!ras_full_w) begin
          ras_count_q <= ras_count_q + {{(RAS_COUNT_W-1){1'b0}}, 1'b1};
        end else begin
          ras_reliable_q <= 1'b0;
        end
      end

      if (!direct_frontend_flush_w && branch_spec_checkpoint_capture_w) begin
        // capture 周期只冻结后端状态；下一拍开始按预测 PC 正常取指/派发 ALU-only 路径。
        branch_spec_checkpoint_pending_q <= 1'b0;
        branch_spec_active_q <= 1'b1;
        stop_pending_q <= 1'b0;
      end

      if (!direct_frontend_flush_w && branch_spec_resolve_valid_w) begin
        branch_spec_active_q <= 1'b0;
        branch_spec_checkpoint_pending_q <= 1'b0;
        branch_spec_pred_pc_q <= {`XLEN{1'b0}};
        stop_pending_q <= 1'b0;
        pending_exit_q <= 1'b0;
        pending_branch_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_mem_next_pc_q <= {`XLEN{1'b0}};
        pending_branch_next_pc_q <= {`XLEN{1'b0}};
        pending_jump_next_pc_q <= {`XLEN{1'b0}};
        branch_spec_active_q <= 1'b0;
        branch_spec_checkpoint_pending_q <= 1'b0;
        branch_spec_pred_pc_q <= {`XLEN{1'b0}};
        branch_prefetch_active_q <= 1'b0;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= {`XLEN{1'b0}};

        if (branch_spec_restore_w) begin
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= fetch_req_fire_w &&
                                 !core_branch_resolve_misaligned_w;
          outstanding_pc_q <= (fetch_req_fire_w &&
                               !core_branch_resolve_misaligned_w) ?
                              fetch_req_pc_w : {`XLEN{1'b0}};
          discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_w;
          if (core_branch_resolve_misaligned_w) begin
            halted_q <= 1'b1;
            trap_valid_q <= 1'b1;
            trap_cause_q <= `EXC_INST_ADDR_MISALIGN;
            trap_pc_q <= core_branch_resolve_pc_w;
            trap_tval_q <= core_branch_resolve_next_pc_w;
          end else begin
            next_fetch_pc_q <= core_branch_resolve_next_pc_w;
          end
        end
      end

      if (!direct_frontend_flush_w && stop_pending_q &&
          pending_branch_q && pending_branch_dispatched_q &&
          branch_resolve_pending_match_w && !branch_spec_active_q) begin
        stop_pending_q <= 1'b0;
        pending_exit_q <= 1'b0;
        pending_branch_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_mem_next_pc_q <= {`XLEN{1'b0}};
        pending_branch_next_pc_q <= {`XLEN{1'b0}};
        pending_jump_next_pc_q <= {`XLEN{1'b0}};
        branch_spec_active_q <= 1'b0;
        branch_spec_checkpoint_pending_q <= 1'b0;
        branch_spec_pred_pc_q <= {`XLEN{1'b0}};
        branch_prefetch_active_q <= 1'b0;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= {`XLEN{1'b0}};
        fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_tail_q <= (!core_branch_resolve_misaligned_w &&
                        branch_prefetch_hit_available_w) ?
                       ptr_inc({FETCH_PACKET_COUNT_W{1'b0}}) :
                       {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_count_q <= (!core_branch_resolve_misaligned_w &&
                         branch_prefetch_hit_available_w) ?
                        {{(FETCH_COUNT_W-1){1'b0}}, 1'b1} :
                        {FETCH_COUNT_W{1'b0}};
        outstanding_valid_q <= (!core_branch_resolve_misaligned_w &&
                                branch_prefetch_pending_match_w) ? 1'b1 :
                               fetch_req_fire_w;
        outstanding_pc_q <= (!core_branch_resolve_misaligned_w &&
                             branch_prefetch_pending_match_w) ?
                            branch_prefetch_pc_q :
                            (fetch_req_fire_w ? fetch_req_pc_w :
                                                {`XLEN{1'b0}});
        discard_fetch_rsp_q <= ((core_branch_resolve_misaligned_w ||
                                 !branch_prefetch_pending_match_w) &&
                                outstanding_valid_q && !fetch_rsp_fire_w);
        if (core_branch_resolve_misaligned_w) begin
          halted_q <= 1'b1;
          trap_valid_q <= 1'b1;
          trap_cause_q <= `EXC_INST_ADDR_MISALIGN;
          trap_pc_q <= core_branch_resolve_pc_w;
          trap_tval_q <= core_branch_resolve_next_pc_w;
        end else if (branch_prefetch_hit_available_w) begin
          // 影子预取命中后才转正为普通 FIFO 包，避免错误预测污染 dispatch 边界。
          fifo_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <= branch_prefetch_hit_pc0_w;
          fifo_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <= branch_prefetch_hit_pc1_w;
          fifo_next_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
              branch_prefetch_hit_next_pc0_w;
          fifo_next_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
              branch_prefetch_hit_next_pc1_w;
          fifo_packet_next_pc_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
              branch_prefetch_hit_packet_next_pc_w;
          fifo_inst0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
              branch_prefetch_hit_inst0_w;
          fifo_inst1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
              branch_prefetch_hit_inst1_w;
          fifo_resp0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
              branch_prefetch_hit_resp0_w;
          fifo_resp1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
              branch_prefetch_hit_resp1_w;
          next_fetch_pc_q <= branch_prefetch_hit_packet_next_pc_w;
        end else begin
          next_fetch_pc_q <= core_branch_resolve_next_pc_w;
        end
      end else if (!direct_frontend_flush_w && branch_resolve_untracked_w) begin
        stop_pending_q <= 1'b0;
        pending_exit_q <= 1'b0;
        pending_branch_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_mem_next_pc_q <= {`XLEN{1'b0}};
        pending_branch_next_pc_q <= {`XLEN{1'b0}};
        pending_jump_next_pc_q <= {`XLEN{1'b0}};
        branch_spec_active_q <= 1'b0;
        branch_spec_checkpoint_pending_q <= 1'b0;
        branch_spec_pred_pc_q <= {`XLEN{1'b0}};
        branch_prefetch_active_q <= 1'b0;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= {`XLEN{1'b0}};
        fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_count_q <= {FETCH_COUNT_W{1'b0}};
        outstanding_valid_q <= fetch_req_fire_w &&
                               !core_branch_resolve_misaligned_w;
        outstanding_pc_q <= (fetch_req_fire_w &&
                             !core_branch_resolve_misaligned_w) ?
                            fetch_req_pc_w : {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_w;
        if (core_branch_resolve_misaligned_w) begin
          halted_q <= 1'b1;
          trap_valid_q <= 1'b1;
          trap_cause_q <= `EXC_INST_ADDR_MISALIGN;
          trap_pc_q <= core_branch_resolve_pc_w;
          trap_tval_q <= core_branch_resolve_next_pc_w;
        end else begin
          next_fetch_pc_q <= core_branch_resolve_next_pc_w;
        end
      end else if (!direct_frontend_flush_w && pending_jump_resolve_ready_w) begin
        if (pending_jump_misaligned_w) begin
          stop_pending_q <= 1'b0;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= 1'b0;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          halted_q <= 1'b1;
          trap_valid_q <= 1'b1;
          trap_cause_q <= `EXC_INST_ADDR_MISALIGN;
          trap_pc_q <= pending_jump_pc_q;
          trap_tval_q <= pending_jump_resolved_target_w;
        end else if (pending_jump_nolink_commit_w) begin
          stop_pending_q <= 1'b0;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= 1'b0;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= fetch_req_fire_w;
          outstanding_pc_q <= fetch_req_fire_w ? fetch_req_pc_w : {`XLEN{1'b0}};
          discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_w;
          next_fetch_pc_q <= pending_jump_resolved_target_w;
          ctrl_commit_valid_q <= 1'b1;
          ctrl_commit_pc_q <= pending_jump_pc_q;
          ctrl_commit_inst_q <= pending_jump_inst_q;
          ctrl_commit_next_pc_q <= pending_jump_resolved_target_w;
        end else if (jump_dispatch_fire_w) begin
          pending_jump_dispatched_q <= 1'b1;
          pending_jump_target_q <= pending_jump_resolved_target_w;
        end
      end else if (!direct_frontend_flush_w && pending_mem_resolve_ready_w) begin
        if (mem_dispatch_fire_w) begin
          pending_mem_dispatched_q <= 1'b1;
        end
      end else if (!direct_frontend_flush_w && stop_pending_q && drain_complete_w) begin
        stop_pending_q <= 1'b0;
        pending_branch_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_mem_next_pc_q <= {`XLEN{1'b0}};
        pending_branch_next_pc_q <= {`XLEN{1'b0}};
        pending_jump_next_pc_q <= {`XLEN{1'b0}};
        if (pending_branch_q && !pending_branch_dispatched_q) begin
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          if (pending_branch_misaligned_w) begin
            halted_q <= 1'b1;
            trap_valid_q <= 1'b1;
            trap_cause_q <= `EXC_INST_ADDR_MISALIGN;
            trap_pc_q <= pending_branch_pc_q;
            trap_tval_q <= pending_branch_target_w;
          end else begin
            next_fetch_pc_q <= pending_branch_next_pc_w;
            ctrl_commit_valid_q <= 1'b1;
            ctrl_commit_pc_q <= pending_branch_pc_q;
            ctrl_commit_inst_q <= pending_branch_inst_q;
            ctrl_commit_next_pc_q <= pending_branch_next_pc_w;
          end
        end else if (pending_jump_q) begin
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          next_fetch_pc_q <= pending_jump_target_q;
        end else if (pending_mem_q) begin
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          next_fetch_pc_q <= pending_mem_next_pc_q;
        end else if (pending_exit_q) begin
          halted_q <= 1'b1;
          exit_valid_q <= 1'b1;
        end else begin
          halted_q <= 1'b1;
          trap_valid_q <= 1'b1;
          trap_cause_q <= pending_trap_cause_q;
          trap_pc_q <= pending_trap_pc_q;
          trap_tval_q <= pending_trap_tval_q;
        end
      end else if (!direct_frontend_flush_w && can_run_w && fifo_has_packet_w) begin
        if (head_fetch_fault0_w) begin
          // 先冻结前端，等已派发的更老指令全部退休后再报 trap，保持精确异常边界。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= 1'b0;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_trap_cause_q <= `EXC_INST_ACCESS_FAULT;
          pending_trap_pc_q <= head_pc_w;
          pending_trap_tval_q <= head_pc_w;
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
        end else if (dispatch0_ebreak_w) begin
          // 当前实验壳只允许 ebreak 位于 packet lane0；它不进入后端，但必须等更老指令退休。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b1;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= 1'b0;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
        end else if (dispatch0_branch_w && !direct_branch0_dispatch_valid_w) begin
          // lane0 branch fast-dispatch 不可用时，回落到精确 drain 后解析。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b1;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= 1'b0;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_pc_q <= head_pc_w;
          pending_branch_next_pc_q <= head_next_pc0_w;
          pending_branch_inst_q <= head_inst0_w;
          pending_branch_rs1_q <= head0_rs1_w;
          pending_branch_rs2_q <= head0_rs2_w;
          pending_branch_imm_q <= head0_imm_w;
          pending_branch_cmp_op_q <=
              head0_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
        end else if (dispatch0_jump_w && !dispatch0_return_w) begin
          // JALR 目标依赖寄存器值：先排空更老项，再单 lane 派发 jump uop。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= 1'b1;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_jalr_q <= head0_jalr_raw_w;
          pending_jump_pc_q <= head_pc_w;
          pending_jump_next_pc_q <= head_next_pc0_w;
          pending_jump_inst_q <= head_inst0_w;
          pending_jump_rs1_q <= head0_rs1_w;
          pending_jump_imm_q <= head0_imm_w;
          pending_jump_target_q <= {`XLEN{1'b0}};
        end else if (dispatch1_barrier_fire_w) begin
          // lane1 半包屏障：lane0 已进入后端，lane1 等 lane0/更老 ROB 项退休后精确处理。
          stop_pending_q <= 1'b1;
          pending_exit_q <= head1_ebreak_raw_w;
          pending_branch_q <= head1_branch_raw_w;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= head1_jump_raw_w;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= head1_mem_raw_w;
          pending_mem_dispatched_q <= 1'b0;
          pending_trap_cause_q <= `EXC_INST_ACCESS_FAULT;
          pending_trap_pc_q <= head_pc1_w;
          pending_trap_tval_q <= head_pc1_w;

          pending_branch_pc_q <= head_pc1_w;
          pending_branch_next_pc_q <= head_next_pc1_w;
          pending_branch_inst_q <= head_inst1_w;
          pending_branch_rs1_q <= head1_rs1_w;
          pending_branch_rs2_q <= head1_rs2_w;
          pending_branch_imm_q <= head1_imm_w;
          pending_branch_cmp_op_q <=
              head1_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];

          pending_jump_jalr_q <= head1_jalr_raw_w;
          pending_jump_pc_q <= head_pc1_w;
          pending_jump_next_pc_q <= head_next_pc1_w;
          pending_jump_inst_q <= head_inst1_w;
          pending_jump_rs1_q <= head1_rs1_w;
          pending_jump_imm_q <= head1_imm_w;
          pending_jump_target_q <= {`XLEN{1'b0}};

          pending_mem_pc_q <= head_pc1_w;
          pending_mem_inst_q <= head_inst1_w;
          pending_mem_next_pc_q <= head_next_pc1_w;
        end else if (dispatch_unsupported_w) begin
          // unsupported 是当前实验核心的停机边界，同样等待更老 ROB 项 drain 后再报精确 trap。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= 1'b0;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          pending_trap_cause_q <= `EXC_ILLEGAL_INST;
          pending_trap_pc_q <= dispatch0_unsupported_w ? head_pc_w :
                                                       head_pc1_w;
          pending_trap_tval_q <= dispatch0_unsupported_w ? head_inst0_w :
                                                         head_inst1_w;
        end
      end
    end
  end

endmodule
