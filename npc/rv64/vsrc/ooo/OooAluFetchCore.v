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
  input [`XLEN-1:0] time_i,
  input irq_software_i,
  input irq_timer_i,
  input irq_external_i,

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
  output [`STRB_W-1:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  input mem_rsp_page_fault_i,
  output mem1_req_valid_o,
  input mem1_req_ready_i,
  output mem1_req_write_o,
  output [`XLEN-1:0] mem1_req_addr_o,
  output [`XLEN-1:0] mem1_req_wdata_o,
  output [`STRB_W-1:0] mem1_req_wstrb_o,
  input mem1_rsp_valid_i,
  output mem1_rsp_ready_o,
  input [`XLEN-1:0] mem1_rsp_rdata_i,
  input mem1_rsp_error_i,
  input mem1_rsp_page_fault_i,
  output mem_flush_o,
  output mmu_flush_o,

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
  output [1:0] priv_mode_o,
  output [`XLEN-1:0] mstatus_o,
  output [`XLEN-1:0] satp_o,

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
  localparam ENABLE_DIRECT_RAS_RET = 1'b0;
  localparam BRANCH_TARGET_CACHE_INDEX_W = 4;
  localparam BRANCH_TARGET_CACHE_ENTRIES =
      (1 << BRANCH_TARGET_CACHE_INDEX_W);
  localparam [`INST_W-1:0] SEMIHOST_ENTER_INST = 32'h01f01013;
  localparam [`INST_W-1:0] SEMIHOST_EXIT_INST  = 32'h40705013;

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

  function [`INST_W-1:0] enc_s_op;
    input [11:0] imm;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
      enc_s_op = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
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

  function [`XLEN-1:0] rvc_imm_ld_sd;
    input [15:0] inst;
    begin
      rvc_imm_ld_sd = {24'b0, inst[6:5], inst[12:10], 3'b000};
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

  function [`XLEN-1:0] rvc_imm_ldsp;
    input [15:0] inst;
    begin
      rvc_imm_ldsp = {23'b0, inst[4:2], inst[12], inst[6:5], 3'b000};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_swsp;
    input [15:0] inst;
    begin
      rvc_imm_swsp = {24'b0, inst[8:7], inst[12:9], 2'b00};
    end
  endfunction

  function [`XLEN-1:0] rvc_imm_sdsp;
    input [15:0] inst;
    begin
      rvc_imm_sdsp = {23'b0, inst[9:7], inst[12:10], 3'b000};
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
            3'b001: begin
              imm = rvc_imm_ld_sd(inst);
              decompress_rvc =
                  enc_i(imm[11:0], rs1p, `FUNCT3_LD,
                        rvc_rdp(inst), `OPCODE_LOAD_FP);
            end
            3'b010: begin
              imm = rvc_imm_lw_sw(inst);
              decompress_rvc =
                  enc_i(imm[11:0], rs1p, `FUNCT3_LW,
                        rvc_rdp(inst), `OPCODE_LOAD);
            end
            3'b011: begin
              imm = rvc_imm_ld_sd(inst);
              decompress_rvc =
                  enc_i(imm[11:0], rs1p, `FUNCT3_LD,
                        rvc_rdp(inst), `OPCODE_LOAD);
            end
            3'b101: begin
              imm = rvc_imm_ld_sd(inst);
              decompress_rvc =
                  enc_s_op(imm[11:0], rs2p, rs1p, `FUNCT3_SD,
                           `OPCODE_STORE_FP);
            end
            3'b110: begin
              imm = rvc_imm_lw_sw(inst);
              decompress_rvc = enc_s(imm[11:0], rs2p, rs1p, `FUNCT3_SW);
            end
            3'b111: begin
              imm = rvc_imm_ld_sd(inst);
              decompress_rvc = enc_s(imm[11:0], rs2p, rs1p, `FUNCT3_SD);
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
              imm = rvc_imm_6(inst);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], rd, `FUNCT3_ADD_SUB, rd,
                          `OPCODE_OP_IMM_32);
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
                  decompress_rvc =
                      enc_i({6'b000000, shamt}, rs1p,
                            `FUNCT3_SRL_SRA, rs1p, `OPCODE_OP_IMM);
                end
                2'b01: begin
                  decompress_rvc =
                      enc_i({6'b010000, shamt}, rs1p,
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
                  end else begin
                    case (inst[6:5])
                      2'b00: decompress_rvc =
                          enc_r(`FUNCT7_ALT, rs2p, rs1p, `FUNCT3_ADD_SUB,
                                rs1p, `OPCODE_OP_32);
                      2'b01: decompress_rvc =
                          enc_r(`FUNCT7_STD, rs2p, rs1p, `FUNCT3_ADD_SUB,
                                rs1p, `OPCODE_OP_32);
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
              decompress_rvc =
                  enc_i({6'b000000, shamt}, rd, `FUNCT3_SLL, rd,
                        `OPCODE_OP_IMM);
            end
            3'b001: begin
              imm = rvc_imm_ldsp(inst);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_LD, rd,
                          `OPCODE_LOAD_FP);
            end
            3'b010: begin
              imm = rvc_imm_lwsp(inst);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_LW, rd, `OPCODE_LOAD);
            end
            3'b011: begin
              imm = rvc_imm_ldsp(inst);
              if (rd != 5'd0)
                decompress_rvc =
                    enc_i(imm[11:0], 5'd2, `FUNCT3_LD, rd, `OPCODE_LOAD);
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
            3'b101: begin
              imm = rvc_imm_sdsp(inst);
              decompress_rvc =
                  enc_s_op(imm[11:0], rs2, 5'd2, `FUNCT3_SD,
                           `OPCODE_STORE_FP);
            end
            3'b110: begin
              imm = rvc_imm_swsp(inst);
              decompress_rvc = enc_s(imm[11:0], rs2, 5'd2, `FUNCT3_SW);
            end
            3'b111: begin
              imm = rvc_imm_sdsp(inst);
              decompress_rvc = enc_s(imm[11:0], rs2, 5'd2, `FUNCT3_SD);
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
  reg jalr_btb_valid_q [0:`BPU_BTB_ENTRIES-1];
  reg [`XLEN-1:0] jalr_btb_pc_q [0:`BPU_BTB_ENTRIES-1];
  reg [`XLEN-1:0] jalr_btb_target_q [0:`BPU_BTB_ENTRIES-1];
  reg branch_bht_valid_q [0:`BPU_BHT_ENTRIES-1];
  reg [1:0] branch_bht_q [0:`BPU_BHT_ENTRIES-1];
  reg [`BPU_BHT_INDEX_W-1:0] branch_ghr_q;
  reg [`BPU_LOCAL_HISTORY_W-1:0] branch_local_hist_q
      [0:`BPU_LOCAL_HISTORY_ENTRIES-1];
  reg branch_local_pht_valid_q [0:`BPU_LOCAL_PHT_ENTRIES-1];
  reg [1:0] branch_local_pht_q [0:`BPU_LOCAL_PHT_ENTRIES-1];

  reg trap_valid_q;
  reg [`TRAP_CAUSE_W-1:0] trap_cause_q;
  reg [`XLEN-1:0] trap_pc_q;
  reg [`XLEN-1:0] trap_tval_q;
  reg exit_valid_q;
  reg exit_is_ecall_q;
  reg exit_is_ebreak_q;
  reg halted_q;
  reg stop_pending_q;
  reg pending_exit_q;
  reg pending_exit_is_ecall_q;
  reg pending_exit_is_ebreak_q;
  reg pending_branch_q;
  reg pending_branch_dispatched_q;
  reg pending_jump_q;
  reg pending_jump_dispatched_q;
  reg pending_jump_jalr_q;
  reg pending_mem_q;
  reg pending_mem_dispatched_q;
  reg pending_fp_q;
  reg pending_fp_mem_pending_q;
  reg pending_fp_mem_done_q;
  reg pending_fp_load_q;
  reg pending_fp_store_q;
  reg pending_fp_double_q;
  reg pending_arch_trap_q;
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
  reg pending_branch_pred_taken_q;
  reg pending_branch_bht_valid_q;
  reg [`BPU_BHT_INDEX_W-1:0] pending_branch_bht_idx_q;
  reg direct_branch_wait_q;
  reg [`XLEN-1:0] direct_branch_wait_pc_q;
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
  reg [`XLEN-1:0] pending_fp_pc_q;
  reg [`INST_W-1:0] pending_fp_inst_q;
  reg [`XLEN-1:0] pending_fp_next_pc_q;
  reg [`XLEN-1:0] pending_fp_addr_q;
  reg [`XLEN-1:0] pending_fp_wdata_q;
  reg [`STRB_W-1:0] pending_fp_wstrb_q;
  reg [`REG_ADDR_W-1:0] pending_fp_rd_q;
  reg [`XLEN-1:0] fpr_q [0:`REG_NUM-1];
  reg pending_system_q;
  reg pending_system_dispatched_q;
  reg pending_system_csr_q;
  reg pending_system_ecall_q;
  reg pending_system_mret_q;
  reg pending_system_wfi_q;
  reg pending_system_sfence_q;
  reg pending_system_irq_q;
  reg [`XLEN-1:0] pending_system_pc_q;
  reg [`INST_W-1:0] pending_system_inst_q;
  reg [`XLEN-1:0] pending_system_next_pc_q;
  reg [`XLEN-1:0] pending_system_csr_rdata_q;
  reg [`TRAP_CAUSE_W-1:0] pending_system_irq_cause_q;
  reg ctrl_commit_valid_q;
  reg [`XLEN-1:0] ctrl_commit_pc_q;
  reg [`INST_W-1:0] ctrl_commit_inst_q;
  reg [`XLEN-1:0] ctrl_commit_next_pc_q;
  reg backend_drained_q;
  reg core_trap_flush_q;
  reg checkpoint_mem_flush_q;

  wire stop_pending_owner_w =
      pending_exit_q || pending_branch_q || pending_jump_q || pending_mem_q ||
      pending_fp_q ||
      pending_arch_trap_q || pending_system_q || synth_lane1_ret_pending_q ||
      synth_lane1_branch_drop_pending_q || branch_spec_checkpoint_pending_q ||
      branch_spec_active_q;
  wire orphan_stop_pending_w = stop_pending_q && !stop_pending_owner_w;
  wire stop_pending_busy_w = stop_pending_q && !orphan_stop_pending_w;
  wire can_run_w = run_i && !core_trap_flush_q && !stop_pending_busy_w &&
                   !halted_q && !trap_valid_q && !exit_valid_q;
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
  wire pending_system_csr_commit_w;
  wire csr_irq_pending_w;
  wire [`TRAP_CAUSE_W-1:0] csr_irq_cause_w;

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
  wire [`CTRL_BUS_W-1:0] branch_prefetch0_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch0_imm_unused_w;
  wire [`CTRL_BUS_W-1:0] branch_prefetch1_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch1_imm_unused_w;
  wire [`CTRL_BUS_W-1:0] branch_prefetch_rsp1_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch_rsp1_imm_unused_w;
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
  wire head0_fp_load_raw_w = head0_decode_valid_w &&
                             (head_inst0_w[6:0] == `OPCODE_LOAD_FP) &&
                             ((head_inst0_w[14:12] == `FUNCT3_LW) ||
                              (head_inst0_w[14:12] == `FUNCT3_LD));
  wire head0_fp_store_raw_w = head0_decode_valid_w &&
                              (head_inst0_w[6:0] == `OPCODE_STORE_FP) &&
                              ((head_inst0_w[14:12] == `FUNCT3_SW) ||
                               (head_inst0_w[14:12] == `FUNCT3_SD));
  wire head0_fp_move_to_fpr_raw_w =
      head0_decode_valid_w &&
      (head_inst0_w[6:0] == `OPCODE_OP_FP) &&
      (head_inst0_w[14:12] == 3'b000) &&
      (head_inst0_w[24:20] == 5'b00000) &&
      ((head_inst0_w[31:25] == 7'b1111000) ||
       (head_inst0_w[31:25] == 7'b1111001));
  wire head0_fp_raw_w = head0_fp_load_raw_w || head0_fp_store_raw_w ||
                        head0_fp_move_to_fpr_raw_w;
  wire head0_ecall_raw_w = head0_decode_valid_w &&
                           head0_ctrl_w[`CTRL_ECALL_BIT] &&
                           !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_ebreak_raw_w = head0_decode_valid_w &&
                             head0_ctrl_w[`CTRL_EBREAK_BIT] &&
                             !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_semihost_ebreak_w = head0_ebreak_raw_w &&
                                 (head_inst1_w == SEMIHOST_EXIT_INST);
  wire head0_csr_raw_w = head0_decode_valid_w &&
                         head0_ctrl_w[`CTRL_CSR_BIT] &&
                         !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_mret_raw_w = head0_decode_valid_w &&
                          head0_ctrl_w[`CTRL_MRET_BIT] &&
                          !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_sret_raw_w = head0_decode_valid_w &&
                          head0_ctrl_w[`CTRL_SRET_BIT] &&
                          !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_xret_raw_w = head0_mret_raw_w || head0_sret_raw_w;
  wire head0_wfi_raw_w = head0_decode_valid_w &&
                         head0_ctrl_w[`CTRL_WFI_BIT] &&
                         !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_sfence_raw_w = head0_decode_valid_w &&
                            head0_ctrl_w[`CTRL_SFENCE_VMA_BIT] &&
                            !head0_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head0_exit_raw_w = head0_ebreak_raw_w && !head0_semihost_ebreak_w;
  wire head0_system_raw_w = head0_ecall_raw_w || head0_csr_raw_w ||
                            head0_xret_raw_w || head0_wfi_raw_w ||
                            head0_sfence_raw_w;
  wire head0_arch_trap_raw_w = head0_semihost_ebreak_w;
  wire head0_stop_raw_w = head0_exit_raw_w || head0_system_raw_w ||
                          head0_fp_raw_w ||
                          head0_arch_trap_raw_w;
  wire head_fetch_fault1_w = fifo_has_packet_w && !head_fetch_fault0_w &&
                             !head0_branch_raw_w && !head0_jump_raw_w &&
                             !head0_stop_raw_w &&
                             (head_resp1_w != 2'b00);
  wire head_fetch_fault_w = head_fetch_fault0_w | head_fetch_fault1_w;
  wire head1_decode_valid_w = fifo_has_packet_w && !head_fetch_fault0_w &&
                              !head0_branch_raw_w && !head0_jump_raw_w &&
                              !head0_stop_raw_w &&
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
  wire head1_fp_load_raw_w = head1_decode_valid_w &&
                             (head_inst1_w[6:0] == `OPCODE_LOAD_FP) &&
                             ((head_inst1_w[14:12] == `FUNCT3_LW) ||
                              (head_inst1_w[14:12] == `FUNCT3_LD));
  wire head1_fp_store_raw_w = head1_decode_valid_w &&
                              (head_inst1_w[6:0] == `OPCODE_STORE_FP) &&
                              ((head_inst1_w[14:12] == `FUNCT3_SW) ||
                               (head_inst1_w[14:12] == `FUNCT3_SD));
  wire head1_fp_move_to_fpr_raw_w =
      head1_decode_valid_w &&
      (head_inst1_w[6:0] == `OPCODE_OP_FP) &&
      (head_inst1_w[14:12] == 3'b000) &&
      (head_inst1_w[24:20] == 5'b00000) &&
      ((head_inst1_w[31:25] == 7'b1111000) ||
       (head_inst1_w[31:25] == 7'b1111001));
  wire head1_fp_raw_w = head1_fp_load_raw_w || head1_fp_store_raw_w ||
                        head1_fp_move_to_fpr_raw_w;
  wire head1_ecall_raw_w = head1_decode_valid_w &&
                           head1_ctrl_w[`CTRL_ECALL_BIT] &&
                           !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_ebreak_raw_w = head1_decode_valid_w &&
                             head1_ctrl_w[`CTRL_EBREAK_BIT] &&
                             !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_semihost_ebreak_w = head1_ebreak_raw_w &&
                                 (head_inst0_w == SEMIHOST_ENTER_INST);
  wire head1_csr_raw_w = head1_decode_valid_w &&
                         head1_ctrl_w[`CTRL_CSR_BIT] &&
                         !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_mret_raw_w = head1_decode_valid_w &&
                          head1_ctrl_w[`CTRL_MRET_BIT] &&
                          !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_sret_raw_w = head1_decode_valid_w &&
                          head1_ctrl_w[`CTRL_SRET_BIT] &&
                          !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_xret_raw_w = head1_mret_raw_w || head1_sret_raw_w;
  wire head1_wfi_raw_w = head1_decode_valid_w &&
                         head1_ctrl_w[`CTRL_WFI_BIT] &&
                         !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_sfence_raw_w = head1_decode_valid_w &&
                            head1_ctrl_w[`CTRL_SFENCE_VMA_BIT] &&
                            !head1_ctrl_w[`CTRL_ILLEGAL_BIT];
  wire head1_exit_raw_w = head1_ebreak_raw_w && !head1_semihost_ebreak_w;
  wire head1_system_raw_w = head1_ecall_raw_w || head1_csr_raw_w ||
                            head1_xret_raw_w || head1_wfi_raw_w ||
                            head1_sfence_raw_w;
  wire head1_arch_trap_raw_w = head1_semihost_ebreak_w;
  wire head1_stop_raw_w = head1_exit_raw_w || head1_system_raw_w ||
                          head1_fp_raw_w ||
                          head1_arch_trap_raw_w;
  wire branch_spec_dispatch_block_w =
      branch_spec_active_q && fifo_has_packet_w &&
      (head_fetch_fault0_w || head_fetch_fault1_w ||
       head0_stop_raw_w || head0_branch_raw_w || head0_jump_raw_w ||
       head0_mem_raw_w || head1_stop_raw_w || head1_control_raw_w ||
       head1_mem_raw_w);

  wire dispatch0_ready_w;
  /* verilator lint_off UNOPTFLAT */
  wire dispatch1_ready_w;
  /* verilator lint_on UNOPTFLAT */
  wire dispatch0_unsupported_w;
  wire dispatch1_unsupported_w;
  wire dispatch_valid_w = fifo_has_packet_w && can_run_w &&
                          !csr_irq_pending_w &&
                          !pending_lane1_ret_q &&
                          !head_fetch_fault0_w &&
                          !branch_spec_dispatch_block_w;
  wire dispatch0_ecall_w = dispatch_valid_w && head0_ecall_raw_w;
  wire dispatch0_ebreak_w = dispatch_valid_w && head0_ebreak_raw_w;
  wire dispatch0_exit_w = dispatch_valid_w && head0_exit_raw_w;
  wire dispatch0_arch_trap_w = dispatch_valid_w && head0_arch_trap_raw_w;
  wire dispatch0_system_w = dispatch_valid_w && head0_system_raw_w;
  wire dispatch0_fp_w = dispatch_valid_w && head0_fp_raw_w;
  wire dispatch0_branch_w = dispatch_valid_w && head0_branch_raw_w;
  wire direct_branch0_dispatch_valid_w = dispatch0_branch_w;
  wire direct_branch0_fire_w = dispatch0_branch_w &&
                               !dispatch0_unsupported_w &&
                               dispatch0_ready_w;
  wire dispatch0_jal_w = dispatch_valid_w && head0_jal_raw_w;
  wire dispatch0_jump_w = dispatch_valid_w && head0_jalr_raw_w;
  wire head0_jal_call_raw_w =
      head0_jal_raw_w &&
      ((head0_rd_unused_w == 5'd1) || (head0_rd_unused_w == 5'd5));
  wire head1_jal_call_raw_w =
      head1_jal_raw_w &&
      ((head1_rd_unused_w == 5'd1) || (head1_rd_unused_w == 5'd5));
  wire dispatch0_return_w =
      ENABLE_DIRECT_RAS_RET &&
      dispatch0_jump_w &&
      ras_reliable_q && !ras_empty_w &&
      (head0_rd_unused_w == {`REG_ADDR_W{1'b0}}) &&
      ((head0_rs1_w == 5'd1) || (head0_rs1_w == 5'd5)) &&
      (head0_imm_w == {`XLEN{1'b0}});
  wire head1_return_candidate_w =
      ENABLE_DIRECT_RAS_RET &&
      head1_jalr_raw_w &&
      ras_reliable_q && !ras_empty_w &&
      (head1_rd_unused_w == {`REG_ADDR_W{1'b0}}) &&
      ((head1_rs1_w == 5'd1) || (head1_rs1_w == 5'd5)) &&
      (head1_imm_w == {`XLEN{1'b0}});
  // lane1 ret 在 lane0 不改写 ret 源寄存器、且不是控制/CSR/AMO 时可直接走 RAS。
  // 普通 load/store 由 ROB 精确异常和 IQ/LSU 的 store-order 规则约束，不需要退化成 drain 边界。
  wire lane0_before_ret_safe_w =
      head0_ctrl_w[`CTRL_VALID_BIT] &&
      !head0_ctrl_w[`CTRL_ILLEGAL_BIT] &&
      head0_ctrl_w[`CTRL_NEED_EXEC_BIT] &&
      !head0_ctrl_w[`CTRL_BRANCH_BIT] &&
      !head0_ctrl_w[`CTRL_JAL_BIT] &&
      !head0_ctrl_w[`CTRL_JALR_BIT] &&
      !head0_ctrl_w[`CTRL_ECALL_BIT] &&
      !head0_ctrl_w[`CTRL_EBREAK_BIT] &&
      !head0_ctrl_w[`CTRL_SYSTEM_BIT] &&
      !head0_ctrl_w[`CTRL_CSR_BIT] &&
      !head0_ctrl_w[`CTRL_FENCE_BIT] &&
      !head0_ctrl_w[`CTRL_MISC_MEM_BIT] &&
      !head0_ctrl_w[`CTRL_MRET_BIT] &&
      !head0_ctrl_w[`CTRL_WFI_BIT] &&
      !head0_ctrl_w[`CTRL_SFENCE_VMA_BIT] &&
      !head0_ctrl_w[`CTRL_SRET_BIT] &&
      !head0_ctrl_w[`CTRL_MULDIV_BIT] &&
      !head0_ctrl_w[`CTRL_BITMANIP_BIT] &&
      !head0_ctrl_w[`CTRL_AMO_BIT] &&
      (!head0_ctrl_w[`CTRL_RD_EN_BIT] ||
       (head0_rd_unused_w == {`REG_ADDR_W{1'b0}}) ||
       (head0_rd_unused_w != head1_rs1_w));
  wire dispatch1_direct_jal_w = dispatch_valid_w &&
                                !dispatch0_exit_w &&
                                !dispatch0_arch_trap_w &&
                                !dispatch0_system_w &&
                                !dispatch0_fp_w &&
                                !dispatch0_branch_w &&
                                !dispatch0_jal_w &&
                                !dispatch0_jump_w &&
                                head1_jal_raw_w &&
                                !head1_jal_call_raw_w;
  wire dispatch1_return_w = dispatch_valid_w &&
                            !dispatch0_exit_w &&
                            !dispatch0_arch_trap_w &&
                            !dispatch0_system_w &&
                            !dispatch0_fp_w &&
                            !dispatch0_branch_w &&
                            !dispatch0_jal_w &&
                            !dispatch0_jump_w &&
                            head1_return_candidate_w &&
                            lane0_before_ret_safe_w;
  wire direct_branch1_dispatch_valid_w = dispatch_valid_w &&
                                         head1_branch_raw_w &&
                                         !head_fetch_fault1_w &&
                                         !dispatch0_exit_w &&
                                         !dispatch0_arch_trap_w &&
                                         !dispatch0_system_w &&
                                         !dispatch0_fp_w &&
                                         !dispatch0_branch_w &&
                                         !dispatch0_jal_w &&
                                         !dispatch0_jump_w;
  wire dispatch1_barrier_w = dispatch_valid_w &&
                             !dispatch0_exit_w &&
                             !dispatch0_arch_trap_w &&
                             !dispatch0_system_w &&
                             !dispatch0_fp_w &&
                             !dispatch0_branch_w &&
                             !dispatch0_jal_w &&
                             !dispatch0_jump_w &&
                             (head_fetch_fault1_w ||
                              head1_exit_raw_w ||
                              head1_system_raw_w ||
                              head1_fp_raw_w ||
                              head1_arch_trap_raw_w ||
                              (head1_branch_raw_w &&
                               !direct_branch1_dispatch_valid_w) ||
                              (head1_jalr_raw_w &&
                               !dispatch1_return_w));
  wire dispatch1_control_unsupported_w = dispatch_valid_w &&
                                         !dispatch0_exit_w &&
                                         !dispatch0_arch_trap_w &&
                                         !dispatch0_system_w &&
                                         !dispatch0_fp_w &&
                                         !dispatch0_branch_w &&
                                         !dispatch0_jal_w &&
                                         !dispatch0_jump_w &&
                                         !dispatch1_barrier_w &&
                                         !direct_branch1_dispatch_valid_w &&
                                         !dispatch1_return_w &&
                                         head1_control_raw_w &&
                                         !head1_jal_raw_w;
  wire dispatch1_mem_unsupported_w = 1'b0;
  wire dispatch_unsupported_w = dispatch_valid_w && !dispatch0_exit_w &&
                                !dispatch0_arch_trap_w &&
                                !dispatch0_system_w && !dispatch0_fp_w &&
                                !dispatch0_branch_w && !dispatch0_jump_w &&
                                ((dispatch0_unsupported_w && !head0_fp_raw_w) |
                                 (dispatch1_unsupported_w && !head1_fp_raw_w) |
                                 dispatch1_control_unsupported_w |
                                 dispatch1_mem_unsupported_w);
  wire dispatch_fire_w = dispatch_valid_w &&
                         !dispatch0_exit_w &&
                         !dispatch0_arch_trap_w &&
                         !dispatch0_system_w &&
                         !dispatch0_fp_w &&
                         !dispatch0_branch_w &&
                         !dispatch0_jal_w &&
                         !dispatch0_jump_w &&
                         !dispatch1_barrier_w &&
                         !dispatch_unsupported_w &&
                         dispatch0_ready_w &&
                         dispatch1_ready_w;
  wire direct_jal0_dispatch_valid_w = dispatch0_jal_w;
  wire direct_jal0_fire_w = dispatch0_jal_w &&
                            direct_jal0_dispatch_valid_w &&
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
  wire [`BPU_BHT_INDEX_W-1:0] head0_branch_pc_idx_w =
      head_pc_w[`BPU_BHT_INDEX_W:1];
  wire [`BPU_BHT_INDEX_W-1:0] head0_branch_bht_idx_w =
      head0_branch_pc_idx_w ^ branch_ghr_q;
  wire head0_branch_bht_valid_w =
      branch_bht_valid_q[head0_branch_bht_idx_w];
  wire head0_branch_static_taken_w = head0_imm_w[`XLEN-1];
  wire head0_branch_gshare_taken_w =
      head0_branch_bht_valid_w ?
      (branch_bht_q[head0_branch_bht_idx_w] >= 2'd2) :
      head0_branch_static_taken_w;
  wire [1:0] head0_branch_gshare_ctr_w =
      branch_bht_q[head0_branch_bht_idx_w];
  wire head0_branch_gshare_strong_w =
      head0_branch_bht_valid_w &&
      ((head0_branch_gshare_ctr_w == 2'd0) ||
       (head0_branch_gshare_ctr_w == 2'd3));
  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] head0_branch_local_hist_idx_w =
      head_pc_w[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire [`BPU_LOCAL_HISTORY_W-1:0] head0_branch_local_hist_w =
      branch_local_hist_q[head0_branch_local_hist_idx_w];
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] head0_branch_local_pc_idx_w =
      head_pc_w[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] head0_branch_local_pht_idx_w =
      {head0_branch_local_pc_idx_w, head0_branch_local_hist_w};
  wire head0_branch_local_valid_w =
      branch_local_pht_valid_q[head0_branch_local_pht_idx_w];
  wire [1:0] head0_branch_local_ctr_w =
      branch_local_pht_q[head0_branch_local_pht_idx_w];
  wire head0_branch_local_taken_w =
      head0_branch_local_valid_w ?
      (head0_branch_local_ctr_w >= 2'd2) :
      head0_branch_static_taken_w;
  wire head0_branch_local_strong_w =
      head0_branch_local_valid_w &&
      ((head0_branch_local_ctr_w == 2'd0) ||
       (head0_branch_local_ctr_w == 2'd3));
  wire head0_branch_pred_taken_w =
      (head0_branch_local_valid_w && !head0_branch_gshare_strong_w) ?
      head0_branch_local_taken_w :
      head0_branch_local_strong_w ? head0_branch_local_taken_w :
                                    head0_branch_gshare_taken_w;
  wire [`BPU_BHT_INDEX_W-1:0] head1_branch_pc_idx_w =
      head_pc1_w[`BPU_BHT_INDEX_W:1];
  wire [`BPU_BHT_INDEX_W-1:0] head1_branch_bht_idx_w =
      head1_branch_pc_idx_w ^ branch_ghr_q;
  wire head1_branch_bht_valid_w =
      branch_bht_valid_q[head1_branch_bht_idx_w];
  wire head1_branch_static_taken_w = head1_imm_w[`XLEN-1];
  wire head1_branch_gshare_taken_w =
      head1_branch_bht_valid_w ?
      (branch_bht_q[head1_branch_bht_idx_w] >= 2'd2) :
      head1_branch_static_taken_w;
  wire [1:0] head1_branch_gshare_ctr_w =
      branch_bht_q[head1_branch_bht_idx_w];
  wire head1_branch_gshare_strong_w =
      head1_branch_bht_valid_w &&
      ((head1_branch_gshare_ctr_w == 2'd0) ||
       (head1_branch_gshare_ctr_w == 2'd3));
  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] head1_branch_local_hist_idx_w =
      head_pc1_w[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire [`BPU_LOCAL_HISTORY_W-1:0] head1_branch_local_hist_w =
      branch_local_hist_q[head1_branch_local_hist_idx_w];
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] head1_branch_local_pc_idx_w =
      head_pc1_w[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] head1_branch_local_pht_idx_w =
      {head1_branch_local_pc_idx_w, head1_branch_local_hist_w};
  wire head1_branch_local_valid_w =
      branch_local_pht_valid_q[head1_branch_local_pht_idx_w];
  wire [1:0] head1_branch_local_ctr_w =
      branch_local_pht_q[head1_branch_local_pht_idx_w];
  wire head1_branch_local_taken_w =
      head1_branch_local_valid_w ?
      (head1_branch_local_ctr_w >= 2'd2) :
      head1_branch_static_taken_w;
  wire head1_branch_local_strong_w =
      head1_branch_local_valid_w &&
      ((head1_branch_local_ctr_w == 2'd0) ||
       (head1_branch_local_ctr_w == 2'd3));
  wire head1_branch_pred_taken_w =
      (head1_branch_local_valid_w && !head1_branch_gshare_strong_w) ?
      head1_branch_local_taken_w :
      head1_branch_local_strong_w ? head1_branch_local_taken_w :
                                    head1_branch_gshare_taken_w;
  wire [`BPU_BHT_INDEX_W-1:0] direct_branch_bht_idx_w =
      direct_branch1_fire_w ? head1_branch_bht_idx_w :
                              head0_branch_bht_idx_w;
  wire direct_branch_bht_valid_w =
      direct_branch1_fire_w ? head1_branch_bht_valid_w :
                              head0_branch_bht_valid_w;
  wire direct_branch_predict_strong_w =
      direct_branch1_fire_w ?
      (head1_branch_gshare_strong_w || head1_branch_local_strong_w) :
      (head0_branch_gshare_strong_w || head0_branch_local_strong_w);
  wire direct_branch_predict_taken_w =
      direct_branch1_fire_w ? head1_branch_pred_taken_w :
                              head0_branch_pred_taken_w;
  wire [`XLEN-1:0] direct_branch_pred_pc_w =
      direct_branch_predict_taken_w ? direct_branch_target_w :
                                      direct_branch_next_pc_w;
  wire direct_branch0_dispatch_resolve_valid_w =
      direct_branch0_fire_w && core_dispatch_branch_resolve_valid_w &&
      (core_dispatch_branch_resolve_pc_w == head_pc_w);
  wire direct_branch1_dispatch_resolve_valid_w =
      direct_branch1_fire_w && core_dispatch_branch_resolve_valid_w &&
      (core_dispatch_branch_resolve_pc_w == head_pc1_w);
  wire direct_branch_dispatch_resolve_valid_w =
      direct_branch0_dispatch_resolve_valid_w ||
      direct_branch1_dispatch_resolve_valid_w;
  wire direct_branch_issue_resolve_valid_w =
      direct_branch_fire_w && core_branch_resolve_valid_w &&
      (core_branch_resolve_pc_w == direct_branch_pc_w);
  wire direct_branch_resolve_valid_w =
      direct_branch_dispatch_resolve_valid_w ||
      direct_branch_issue_resolve_valid_w;
  wire [`XLEN-1:0] direct_branch_resolve_next_pc_w =
      direct_branch_dispatch_resolve_valid_w ?
      core_dispatch_branch_resolve_next_pc_w : core_branch_resolve_next_pc_w;
  wire direct_branch_resolve_misaligned_w =
      direct_branch_dispatch_resolve_valid_w ?
      core_dispatch_branch_resolve_misaligned_w :
      core_branch_resolve_misaligned_w;
  wire direct_branch_resolve_redirect_w =
      direct_branch_resolve_valid_w && !direct_branch_resolve_misaligned_w;
  wire direct_branch_resolve_taken_w =
      direct_branch_resolve_redirect_w &&
      (direct_branch_resolve_next_pc_w == direct_branch_target_w);
  wire direct_branch0_lane1_ret_w =
      direct_branch0_fire_w && direct_branch_resolve_valid_w &&
      !synth_lane1_ret_pending_q &&
      !synth_lane1_branch_drop_pending_q &&
      !direct_branch_resolve_misaligned_w &&
      (direct_branch_resolve_next_pc_w == head_pc1_w) &&
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
                     (head_fetch_fault0_w | dispatch0_exit_w |
                      dispatch0_arch_trap_w |
                      dispatch0_system_w |
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
  wire fetch_rsp_can_drop_w = !outstanding_valid_q ||
                              stop_pending_busy_w || halted_q ||
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
  wire branch_prefetch_branch_predict_taken_w = pending_branch_pred_taken_q;
  wire [`XLEN-1:0] branch_prefetch_branch_pred_pc_w =
      branch_prefetch_branch_predict_taken_w ? pending_branch_target_w :
                                               pending_branch_next_pc_q;
  wire pending_jump_jalr_ret_hint_w =
      pending_jump_q && pending_jump_jalr_q &&
      (pending_jump_inst_q[11:7] == 5'd0) &&
      ((pending_jump_rs1_q == 5'd1) || (pending_jump_rs1_q == 5'd5)) &&
      (pending_jump_imm_q == {`XLEN{1'b0}});
  wire pending_jump_jalr_btb_lookup_w =
      stop_pending_q && pending_jump_q && pending_jump_jalr_q &&
      !(pending_jump_jalr_ret_hint_w && !ras_empty_w);
  wire [`BPU_BTB_INDEX_W-1:0] pending_jump_jalr_btb_idx_w =
      pending_jump_pc_q[`BPU_BTB_INDEX_W:1];
  wire pending_jump_jalr_btb_entry_hit_w =
      pending_jump_jalr_q &&
      jalr_btb_valid_q[pending_jump_jalr_btb_idx_w] &&
      (jalr_btb_pc_q[pending_jump_jalr_btb_idx_w] == pending_jump_pc_q);
  wire pending_jump_jalr_btb_hit_w =
      pending_jump_jalr_btb_lookup_w && pending_jump_jalr_btb_entry_hit_w;
  wire [`XLEN-1:0] pending_jump_jalr_btb_target_w =
      jalr_btb_target_q[pending_jump_jalr_btb_idx_w];
  wire branch_prefetch_branch_req_valid_w =
      stop_pending_q && pending_branch_q && pending_branch_dispatched_q &&
      !branch_prefetch_active_q && !outstanding_valid_q &&
      !discard_fetch_rsp_q && !branch_resolve_pending_match_w &&
      !branch_spec_checkpoint_pending_q && !branch_spec_active_q &&
      !halted_q && !trap_valid_q && !exit_valid_q;
  wire branch_prefetch_jalr_req_valid_w =
      pending_jump_jalr_btb_hit_w && !pending_jump_dispatched_q &&
      !branch_prefetch_active_q && !outstanding_valid_q &&
      !discard_fetch_rsp_q && !branch_spec_checkpoint_pending_q &&
      !branch_spec_active_q && !halted_q && !trap_valid_q && !exit_valid_q;
  wire branch_prefetch_req_valid_w =
      branch_prefetch_branch_req_valid_w || branch_prefetch_jalr_req_valid_w;
  wire [`XLEN-1:0] branch_prefetch_req_pc_w =
      branch_prefetch_jalr_req_valid_w ? pending_jump_jalr_btb_target_w :
                                         branch_prefetch_branch_pred_pc_w;
  wire branch_prefetch_rsp_capture_w =
      branch_prefetch_active_q && !branch_prefetch_buffer_valid_q &&
      stop_pending_q &&
      ((pending_branch_q && pending_branch_dispatched_q) ||
       (pending_jump_q && pending_jump_jalr_q)) &&
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
  wire branch_resolve_pending_pc_match_w =
      core_branch_resolve_valid_w &&
      (core_branch_resolve_pc_w == pending_branch_pc_q);
  wire branch_resolve_pending_match_w =
      stop_pending_q && pending_branch_q && pending_branch_dispatched_q &&
      branch_resolve_pending_pc_match_w;
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
      backend_execute_quiet_w &&
      (core_mem_idle_w || core_pending_load_branch_dep_w);
  wire branch_spec_resolve_valid_w =
      branch_spec_active_q && pending_branch_q &&
      pending_branch_dispatched_q && branch_resolve_pending_pc_match_w;
  wire branch_spec_pred_match_w =
      !core_branch_resolve_misaligned_w &&
      (core_branch_resolve_next_pc_w == branch_spec_pred_pc_q);
  wire branch_spec_restore_w =
      branch_spec_resolve_valid_w && !branch_spec_pred_match_w;
  wire branch_spec_redirect_w =
      branch_spec_restore_w && !core_branch_resolve_misaligned_w;
  wire direct_branch_wait_resolve_match_w =
      direct_branch_wait_q && core_branch_resolve_valid_w &&
      (core_branch_resolve_pc_w == direct_branch_wait_pc_q);
  wire direct_branch_wait_untracked_w =
      direct_branch_wait_resolve_match_w &&
      !branch_resolve_pending_match_w &&
      !direct_branch_resolve_valid_w;
  wire branch_resolve_untracked_w =
      (direct_branch_wait_untracked_w ||
       (core_branch_resolve_valid_w &&
        !stop_pending_q &&
        !branch_resolve_pending_pc_match_w &&
        !direct_branch_resolve_valid_w)) &&
      !branch_spec_resolve_valid_w;
  wire branch_resolve_untracked_redirect_w =
      branch_resolve_untracked_w && !core_branch_resolve_misaligned_w;
  wire direct_redirect_fetch_w =
      direct_jal_fire_w || direct_ret0_fire_w || direct_ret1_fire_w ||
      direct_branch0_lane1_ret_w ||
      pending_jump_nolink_commit_w ||
      pending_jump_redirect_after_dispatch_w ||
      direct_branch_resolve_redirect_w;
  wire redirect_fetch_req_valid_w =
      (direct_redirect_fetch_w || branch_resolve_redirect_w ||
       branch_spec_redirect_w || branch_resolve_untracked_redirect_w) &&
      (!branch_fallthrough_dispatch_w ||
       !branch_fallthrough_outstanding_match_w) &&
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
          direct_branch_resolve_next_pc_w :
      (pending_jump_nolink_commit_w ||
       pending_jump_redirect_after_dispatch_w) ? pending_jump_resolved_target_w :
      branch_spec_redirect_w ? core_branch_resolve_next_pc_w :
                           core_branch_resolve_next_pc_w;
  wire [`XLEN-1:0] fetch_req_pc_w =
      redirect_fetch_req_valid_w ? redirect_fetch_pc_w :
      branch_prefetch_req_valid_w ? branch_prefetch_req_pc_w :
                                    fetch_req_seq_pc_w;
  wire can_issue_request_w = can_run_w && !stop_head_w &&
                             !fetch_rsp_control_stop_w &&
                             !discard_fetch_rsp_q &&
                             fifo_reserve_available_w &&
                             (!outstanding_valid_q || fetch_rsp_fire_w);
  wire fetch_req_fire_w = fetch_req_valid_o && fetch_req_ready_i;
  wire frontend_dispatch_to_backend_valid_w =
      dispatch_valid_w && !dispatch0_branch_w && !dispatch0_jal_w &&
      !dispatch0_jump_w && !dispatch0_exit_w && !dispatch0_system_w &&
      !dispatch0_fp_w &&
      !dispatch1_barrier_w &&
      !dispatch1_control_unsupported_w &&
      !dispatch1_mem_unsupported_w;
  wire lane1_barrier_dispatch0_valid_w =
      dispatch1_barrier_w;

  wire execute0_valid_unused_w;
  wire execute1_valid_unused_w;
  wire core_mem_idle_w;
  wire core_mem_req_valid_w;
  wire core_mem_req_write_w;
  wire [`XLEN-1:0] core_mem_req_addr_w;
  wire [`XLEN-1:0] core_mem_req_wdata_w;
  wire [`STRB_W-1:0] core_mem_req_wstrb_w;
  wire core_mem_rsp_ready_w;
  wire core_mem1_req_valid_w;
  wire core_mem1_req_write_w;
  wire [`XLEN-1:0] core_mem1_req_addr_w;
  wire [`XLEN-1:0] core_mem1_req_wdata_w;
  wire [`STRB_W-1:0] core_mem1_req_wstrb_w;
  wire core_mem1_rsp_ready_w;
  wire core_branch_resolve_valid_w;
  wire [`XLEN-1:0] core_branch_resolve_pc_w;
  wire [`XLEN-1:0] core_branch_resolve_next_pc_w;
  wire core_branch_resolve_misaligned_w;
  wire core_dispatch_branch_resolve_valid_w;
  wire [`XLEN-1:0] core_dispatch_branch_resolve_pc_w;
  wire [`XLEN-1:0] core_dispatch_branch_resolve_next_pc_w;
  wire core_dispatch_branch_resolve_misaligned_w;
  wire core_pending_load_branch_dep_w;
  wire [`XLEN-1:0] a0_data_w;
  wire core_commit0_valid_w;
  wire [`XLEN-1:0] core_commit0_pc_w;
  wire [`XLEN-1:0] core_commit0_next_pc_w;
  wire [`INST_W-1:0] core_commit0_inst_w;
  wire core_commit0_rd_en_w;
  wire [`REG_ADDR_W-1:0] core_commit0_rd_addr_w;
  wire [`XLEN-1:0] core_commit0_rd_data_w;
  wire core_commit0_exception_w;
  wire [`TRAP_CAUSE_W-1:0] core_commit0_cause_w;
  wire [`XLEN-1:0] core_commit0_tval_w;
  wire core_commit0_write_w;
  wire core_commit1_valid_w;
  wire [`XLEN-1:0] core_commit1_pc_w;
  wire [`XLEN-1:0] core_commit1_next_pc_w;
  wire [`INST_W-1:0] core_commit1_inst_w;
  wire core_commit1_rd_en_w;
  wire [`REG_ADDR_W-1:0] core_commit1_rd_addr_w;
  wire [`XLEN-1:0] core_commit1_rd_data_w;
  wire core_commit1_exception_w;
  wire [`TRAP_CAUSE_W-1:0] core_commit1_cause_w;
  wire [`XLEN-1:0] core_commit1_tval_w;
  wire core_commit1_write_w;
  wire [1:0] core_retire_count_w;
  wire [`XLEN * `REG_NUM - 1:0] core_debug_gprs_w;
  wire core_commit0_csr_w =
      core_commit0_valid_w && !core_commit0_exception_w &&
      (core_commit0_inst_w[6:0] == `OPCODE_SYSTEM) &&
      (core_commit0_inst_w[14:12] != 3'b000);
  wire core_commit_exception_trap_w =
      (core_commit0_valid_w && core_commit0_exception_w) ||
      (core_commit1_valid_w && core_commit1_exception_w);
  wire csr_trap_mem_valid_w = core_commit_exception_trap_w;
  wire [`XLEN-1:0] csr_trap_mem_pc_w =
      (core_commit0_valid_w && core_commit0_exception_w) ?
      core_commit0_pc_w : core_commit1_pc_w;
  wire [`TRAP_CAUSE_W-1:0] csr_trap_mem_cause_w =
      (core_commit0_valid_w && core_commit0_exception_w) ?
      core_commit0_cause_w : core_commit1_cause_w;
  wire [`XLEN-1:0] csr_trap_mem_tval_w =
      (core_commit0_valid_w && core_commit0_exception_w) ?
      core_commit0_tval_w : core_commit1_tval_w;
  assign pending_system_csr_commit_w =
      pending_system_q && pending_system_csr_q && pending_system_dispatched_q &&
      core_commit0_csr_w && (core_commit0_pc_w == pending_system_pc_q);
  wire head1_csr_probe_w =
      dispatch_valid_w && !dispatch0_system_w && dispatch1_barrier_w &&
      head1_csr_raw_w;
  wire [`INST_W-1:0] csr_access_inst_w =
      core_commit0_csr_w ? core_commit0_inst_w :
      pending_system_q ? pending_system_inst_q :
      head1_csr_probe_w ? head_inst1_w : head_inst0_w;
  wire [11:0] csr_access_addr_w = csr_access_inst_w[31:20];
  wire [2:0] csr_access_funct3_w = csr_access_inst_w[14:12];
  wire [`REG_ADDR_W-1:0] csr_access_rs1_idx_w = csr_access_inst_w[19:15];
  wire [`XLEN-1:0] csr_access_rs1_data_w =
      core_debug_gprs_w[csr_access_rs1_idx_w * `XLEN +: `XLEN];
  wire csr_access_set_clear_noop_w =
      ((csr_access_funct3_w == 3'b010) || (csr_access_funct3_w == 3'b011) ||
       (csr_access_funct3_w == 3'b110) || (csr_access_funct3_w == 3'b111)) &&
      (csr_access_rs1_idx_w == {`REG_ADDR_W{1'b0}});
  wire csr_access_need_write_w =
      (csr_access_funct3_w == 3'b001) ||
      (csr_access_funct3_w == 3'b101) ||
      !csr_access_set_clear_noop_w;
  wire csr_access_valid_w =
      core_commit0_csr_w || (pending_system_q && pending_system_csr_q) ||
      head0_csr_raw_w || head1_csr_probe_w;
  wire pending_system_satp_write_commit_w =
      pending_system_csr_commit_w &&
      (csr_access_addr_w == `CSR_SATP) &&
      csr_access_need_write_w;
  wire pending_system_sfence_commit_w =
      stop_pending_q && drain_complete_w && pending_system_q &&
      pending_system_sfence_q;
  wire [`TRAP_CAUSE_W-1:0] csr_ecall_cause_w;
  wire pending_system_ecall_trap_w =
      stop_pending_q && drain_complete_w && pending_system_q &&
      pending_system_ecall_q;
  wire pending_arch_trap_fire_w =
      stop_pending_q && drain_complete_w && pending_arch_trap_q;
  wire csr_trap_ex_valid_w =
      pending_system_ecall_trap_w || pending_arch_trap_fire_w;
  wire [`XLEN-1:0] csr_trap_ex_pc_w =
      pending_arch_trap_fire_w ? pending_trap_pc_q : pending_system_pc_q;
  wire [`TRAP_CAUSE_W-1:0] csr_trap_ex_cause_w =
      pending_arch_trap_fire_w ? pending_trap_cause_q : csr_ecall_cause_w;
  wire [`XLEN-1:0] csr_trap_ex_tval_w =
      pending_arch_trap_fire_w ? pending_trap_tval_q : {`XLEN{1'b0}};
  wire csr_trap_irq_valid_w =
      stop_pending_q && drain_complete_w && pending_system_q &&
      pending_system_irq_q;
  wire csr_mret_valid_w =
      stop_pending_q && drain_complete_w && pending_system_q &&
      pending_system_mret_q;
  wire csr_sret_valid_w =
      csr_mret_valid_w &&
      (pending_system_inst_q[31:20] == `SYSTEM_FUNCT12_SRET);
  wire csr_real_mret_valid_w = csr_mret_valid_w && !csr_sret_valid_w;
  wire [`XLEN-1:0] csr_rdata_w;
  wire csr_illegal_w;
  wire [`XLEN-1:0] csr_trap_target_w;
  wire [`XLEN-1:0] csr_mepc_w;
  wire [`XLEN-1:0] csr_ret_target_w;
  wire [1:0] csr_priv_mode_w;
  wire [`XLEN-1:0] csr_mstatus_w;
  wire [`XLEN-1:0] csr_satp_w;
  wire head0_csr_illegal_w = head0_csr_raw_w && !head1_csr_probe_w &&
                             csr_illegal_w;
  wire head1_csr_illegal_w = head1_csr_probe_w && csr_illegal_w;
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
  wire pending_jump_resolve_ready_w = stop_pending_q && pending_jump_q &&
                                      !pending_jump_dispatched_q &&
                                      backend_drained_q;
  wire jalr_prefetch_target_ready_w =
      pending_jump_dispatched_q || pending_jump_resolve_ready_w;
  wire [`XLEN-1:0] jalr_prefetch_target_w =
      pending_jump_dispatched_q ? pending_jump_target_q :
                                  pending_jump_resolved_target_w;
  wire jalr_prefetch_match_w =
      branch_prefetch_active_q && stop_pending_q && pending_jump_q &&
      pending_jump_jalr_q && jalr_prefetch_target_ready_w &&
      !pending_jump_misaligned_w &&
      (branch_prefetch_pc_q == jalr_prefetch_target_w);
  wire jalr_prefetch_buffer_match_w =
      jalr_prefetch_match_w && branch_prefetch_buffer_valid_q;
  wire jalr_prefetch_rsp_match_w =
      jalr_prefetch_match_w && branch_prefetch_rsp_capture_w;
  wire jalr_prefetch_hit_available_w =
      jalr_prefetch_buffer_match_w || jalr_prefetch_rsp_match_w;
  wire jalr_prefetch_pending_match_w =
      jalr_prefetch_match_w && !jalr_prefetch_hit_available_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_pc0_w =
      jalr_prefetch_rsp_match_w ? fetch_dec0_pc_w :
                                  branch_prefetch_buf_pc0_q;
  wire [`XLEN-1:0] jalr_prefetch_hit_pc1_w =
      jalr_prefetch_rsp_match_w ? fetch_dec1_pc_w :
                                  branch_prefetch_buf_pc1_q;
  wire [`XLEN-1:0] jalr_prefetch_hit_next_pc0_w =
      jalr_prefetch_rsp_match_w ? fetch_dec0_next_pc_w :
                                  branch_prefetch_buf_next_pc0_q;
  wire [`XLEN-1:0] jalr_prefetch_hit_next_pc1_w =
      jalr_prefetch_rsp_match_w ? fetch_dec1_next_pc_w :
                                  branch_prefetch_buf_next_pc1_q;
  wire [`XLEN-1:0] jalr_prefetch_hit_packet_next_pc_w =
      jalr_prefetch_rsp_match_w ? fetch_rsp_packet_next_pc_w :
                                  branch_prefetch_buf_packet_next_pc_q;
  wire [`INST_W-1:0] jalr_prefetch_hit_inst0_w =
      jalr_prefetch_rsp_match_w ? fetch_dec0_inst_w :
                                  branch_prefetch_buf_inst0_q;
  wire [`INST_W-1:0] jalr_prefetch_hit_inst1_w =
      jalr_prefetch_rsp_match_w ? fetch_dec1_inst_w :
                                  branch_prefetch_buf_inst1_q;
  wire [1:0] jalr_prefetch_hit_resp0_w =
      jalr_prefetch_rsp_match_w ? fetch_rsp_resp0_i :
                                  branch_prefetch_buf_resp0_q;
  wire [1:0] jalr_prefetch_hit_resp1_w =
      jalr_prefetch_rsp_match_w ? fetch_dec1_resp_w :
                                  branch_prefetch_buf_resp1_q;
  wire jalr_btb_update_w =
      pending_jump_resolve_ready_w && pending_jump_jalr_q &&
      !pending_jump_misaligned_w;
  wire pending_jump_return_w =
      pending_jump_q && pending_jump_jalr_q && !ras_empty_w &&
      (pending_jump_inst_q[11:7] == 5'd0) &&
      ((pending_jump_rs1_q == 5'd1) || (pending_jump_rs1_q == 5'd5)) &&
      (pending_jump_imm_q == {`XLEN{1'b0}});
  wire pending_jump_return_fire_w =
      pending_jump_return_w && pending_jump_resolve_ready_w &&
      jump_dispatch_fire_w && !pending_jump_misaligned_w;
  wire pending_jump_call_w =
      pending_jump_q &&
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
  wire pending_jump_redirect_after_dispatch_w =
      pending_jump_resolve_ready_w && !pending_jump_misaligned_w &&
      !pending_jump_nolink_w && jump_dispatch_fire_w;
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
  function branch_target_same_fetch_word;
    input [`XLEN-1:0] lhs;
    input [`XLEN-1:0] rhs;
    begin
      branch_target_same_fetch_word =
          lhs[`XLEN-1:`XLEN_BYTE_W] == rhs[`XLEN-1:`XLEN_BYTE_W];
    end
  endfunction

  function branch_prefetch_plain_uop_safe;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
      branch_prefetch_plain_uop_safe =
          ctrl[`CTRL_VALID_BIT] &&
          !ctrl[`CTRL_ILLEGAL_BIT] &&
          ctrl[`CTRL_NEED_EXEC_BIT] &&
          !ctrl[`CTRL_BRANCH_BIT] &&
          !ctrl[`CTRL_JAL_BIT] &&
          !ctrl[`CTRL_JALR_BIT] &&
          !ctrl[`CTRL_STORE_BIT] &&
          !ctrl[`CTRL_ECALL_BIT] &&
          !ctrl[`CTRL_EBREAK_BIT] &&
          !ctrl[`CTRL_SYSTEM_BIT] &&
          !ctrl[`CTRL_CSR_BIT] &&
          !ctrl[`CTRL_FENCE_BIT] &&
          !ctrl[`CTRL_MISC_MEM_BIT] &&
          !ctrl[`CTRL_MRET_BIT] &&
          !ctrl[`CTRL_WFI_BIT] &&
          !ctrl[`CTRL_SFENCE_VMA_BIT] &&
          !ctrl[`CTRL_SRET_BIT] &&
          !ctrl[`CTRL_AMO_BIT];
    end
  endfunction

  wire branch_target_store_fire_w =
      (mem_req_valid_o && mem_req_ready_i && mem_req_write_o) ||
      (mem1_req_valid_o && mem1_req_ready_i && mem1_req_write_o);
  wire [`XLEN-1:0] branch_target_store_addr_w =
      (mem_req_valid_o && mem_req_ready_i && mem_req_write_o) ?
      mem_req_addr_o : mem1_req_addr_o;
  wire branch_target_cache_invalidate_all_w =
      (core_commit0_valid_w &&
       (core_commit0_inst_w[6:0] == `OPCODE_MISC_MEM)) ||
      (core_commit1_valid_w &&
       (core_commit1_inst_w[6:0] == `OPCODE_MISC_MEM));
  wire branch_fallthrough_outstanding_match_w =
      outstanding_valid_q && (outstanding_pc_q == head_next_pc1_w);
  /* verilator lint_off UNOPTFLAT */
  wire return_cont_attempt_w =
      direct_branch0_lane1_ret_w &&
      !ctrl_commit_valid_q && commit_ready_i &&
      return_cont_match_w &&
      core_commit0_valid_w && !core_commit1_valid_w &&
      (rob_count_o == {{(ROB_COUNT_W-1){1'b0}}, 1'b1});
  wire branch_target_append_candidate_w =
      dispatch0_branch_w && branch_target_cache_hit_w;
  // FIFO 头包后面若已有旧取指响应在路上，直接追加落空 lane1 可能把同一窗口
  // 重复入队；但当前包来自 bypass response 时，这个 response 本身会在 flush
  // 周期被消费，不属于旧响应，可以安全追加 lane1。
  wire branch_fallthrough_append_safe_w =
      branch_fallthrough_safe_w &&
      (!outstanding_valid_q || fetch_rsp_dispatch_bypass_w ||
       branch_fallthrough_outstanding_match_w);
  wire branch_fallthrough_append_candidate_w =
      dispatch0_branch_w && branch_fallthrough_append_safe_w;
  wire branch_target_append_attempt_w =
      branch_target_append_candidate_w &&
      direct_branch0_fire_w && direct_branch_resolve_redirect_w &&
      direct_branch_resolve_taken_w;
  wire branch_fallthrough_append_attempt_w =
      branch_fallthrough_append_candidate_w &&
      direct_branch0_fire_w && direct_branch_resolve_redirect_w &&
      !direct_branch_resolve_taken_w;
  wire synth_lane1_branch_append_w =
      return_cont_attempt_w && dispatch1_ready_w;
  wire branch_target_append_w =
      branch_target_append_attempt_w && dispatch1_ready_w;
  wire branch_fallthrough_append_w =
      branch_fallthrough_append_attempt_w && dispatch1_ready_w;
  wire return_cont_dispatch_w = synth_lane1_branch_append_w;
  wire branch_target_dispatch_w = branch_target_append_w;
  wire branch_fallthrough_dispatch_w = branch_fallthrough_append_w;
  wire branch_fallthrough_keep_outstanding_w =
      branch_fallthrough_dispatch_w && branch_fallthrough_outstanding_match_w &&
      !fetch_rsp_fire_w;
  wire branch_fallthrough_capture_rsp_w =
      branch_fallthrough_dispatch_w && branch_fallthrough_outstanding_match_w &&
      fetch_rsp_fire_w;
  wire branch_prefetch_dispatch0_safe_w =
      (branch_prefetch_buf_resp0_q == 2'b00) &&
      branch_prefetch_plain_uop_safe(branch_prefetch0_ctrl_w);
  wire branch_prefetch_dispatch1_safe_w =
      (branch_prefetch_buf_resp1_q == 2'b00) &&
      branch_prefetch_plain_uop_safe(branch_prefetch1_ctrl_w);
  wire branch_prefetch_rsp_raw_match_w =
      branch_prefetch_active_q && !branch_prefetch_buffer_valid_q &&
      stop_pending_q && pending_branch_q && pending_branch_dispatched_q &&
      fetch_rsp_valid_i &&
      (branch_prefetch_pc_q == core_branch_resolve_next_pc_w);
  wire branch_prefetch_rsp_dispatch0_safe_w =
      (fetch_rsp_resp0_i == 2'b00) &&
      branch_prefetch_plain_uop_safe(branch_target_capture_ctrl_w);
  wire branch_prefetch_rsp_dispatch1_safe_w =
      (fetch_dec1_resp_w == 2'b00) &&
      branch_prefetch_plain_uop_safe(branch_prefetch_rsp1_ctrl_w);
  wire branch_prefetch_dispatch_buffer_w =
      !direct_frontend_flush_w && stop_pending_q && pending_branch_q &&
      pending_branch_dispatched_q && branch_resolve_pending_match_w &&
      !branch_spec_active_q && !core_branch_resolve_misaligned_w &&
      branch_prefetch_buffer_match_w &&
      branch_prefetch_dispatch0_safe_w &&
      branch_prefetch_dispatch1_safe_w;
  wire branch_prefetch_dispatch_rsp_w =
      !direct_frontend_flush_w && stop_pending_q && pending_branch_q &&
      pending_branch_dispatched_q && branch_resolve_pending_match_w &&
      !branch_spec_active_q && !core_branch_resolve_misaligned_w &&
      branch_prefetch_rsp_raw_match_w &&
      branch_prefetch_rsp_dispatch0_safe_w &&
      branch_prefetch_rsp_dispatch1_safe_w;
  wire branch_prefetch_dispatch_attempt_w = 1'b0;
  wire branch_prefetch_dispatch_fire_w = 1'b0;
  wire branch_prefetch_hit_to_fifo_w =
      branch_prefetch_hit_available_w && !branch_prefetch_dispatch_fire_w;
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
  wire direct_branch_spec_start_w = 1'b0;
  wire branch_bpu_pending0_capture_w =
      !direct_frontend_flush_w && can_run_w && fifo_has_packet_w &&
      dispatch0_branch_w && !direct_branch0_dispatch_valid_w;
  wire branch_bpu_pending1_capture_w =
      !direct_frontend_flush_w && can_run_w && fifo_has_packet_w &&
      dispatch1_barrier_fire_w && head1_branch_raw_w;
  wire branch_bpu_lookup_event_w =
      direct_branch_fire_w || branch_bpu_pending0_capture_w ||
      branch_bpu_pending1_capture_w;
  wire branch_bpu_lookup_bht_valid_w =
      (direct_branch_fire_w ? direct_branch_bht_valid_w : 1'b0) |
      (branch_bpu_pending0_capture_w ? head0_branch_bht_valid_w : 1'b0) |
      (branch_bpu_pending1_capture_w ? head1_branch_bht_valid_w : 1'b0);
  wire jump_dispatch_valid_w = pending_jump_resolve_ready_w &&
                               !pending_jump_nolink_w &&
                               !pending_jump_misaligned_w;
  wire pending_lane1_ret_dispatch_valid_w = pending_lane1_ret_q;
  wire pending_lane1_ret_fire_w =
      pending_lane1_ret_dispatch_valid_w && dispatch0_ready_w;
  wire system_csr_dispatch_valid_w =
      stop_pending_q && pending_system_q && pending_system_csr_q &&
      !pending_system_dispatched_q && backend_drained_q;
  wire system_csr_dispatch_fire_w =
      system_csr_dispatch_valid_w && dispatch0_ready_w;
  wire pending_mem_resolve_ready_w = stop_pending_q && pending_mem_q &&
                                     !pending_mem_dispatched_q &&
                                     backend_drained_q;
  wire mem_dispatch_valid_w = pending_mem_resolve_ready_w;
  wire pending_branch_commit_resolve_w =
      !direct_frontend_flush_w && stop_pending_q && backend_drained_w &&
      pending_branch_q && pending_branch_dispatched_q &&
      !branch_resolve_pending_match_w && !branch_spec_active_q &&
      !branch_spec_checkpoint_pending_q && !pending_jump_q &&
      !pending_mem_q && !pending_fp_q && !pending_arch_trap_q &&
      !pending_system_q;
  wire pending_branch_resolve_wait_w =
      pending_branch_q && pending_branch_dispatched_q &&
      !branch_resolve_pending_match_w && !pending_branch_commit_resolve_w;
  wire pending_replay_wait_w =
      pending_branch_resolve_wait_w ||
      (pending_jump_q && !pending_jump_dispatched_q) ||
      (pending_mem_q && !pending_mem_dispatched_q) ||
      (pending_fp_q && !pending_fp_mem_done_q) ||
      (pending_system_q && pending_system_csr_q);
  wire drain_complete_w = stop_pending_q && backend_drained_w &&
                          pending_control_ready_w &&
                          !pending_replay_wait_w;
  wire branch_bpu_direct_update_w = direct_branch_resolve_valid_w;
  wire branch_bpu_pending_update_w =
      stop_pending_q && pending_branch_q && pending_branch_dispatched_q &&
      branch_resolve_pending_match_w;
  wire branch_bpu_drained_update_w =
      stop_pending_q && drain_complete_w &&
      pending_branch_q && !pending_branch_dispatched_q;
  wire branch_bpu_commit_update_w = pending_branch_commit_resolve_w;
  wire branch_bpu_update_valid_w =
      branch_bpu_direct_update_w || branch_bpu_pending_update_w ||
      branch_bpu_drained_update_w || branch_bpu_commit_update_w;
  wire branch_bpu_pending_like_update_w =
      branch_bpu_pending_update_w || branch_bpu_drained_update_w ||
      branch_bpu_commit_update_w;
  wire branch_bpu_update_taken_w =
      branch_bpu_pending_update_w ?
          (!core_branch_resolve_misaligned_w &&
           (core_branch_resolve_next_pc_w == pending_branch_target_w)) :
      (branch_bpu_drained_update_w || branch_bpu_commit_update_w) ?
          pending_branch_taken_w :
      direct_branch_resolve_taken_w;
  wire branch_bpu_update_pred_taken_w =
      branch_bpu_pending_like_update_w ? pending_branch_pred_taken_q :
                                         direct_branch_predict_taken_w;
  wire branch_bpu_update_correct_w =
      branch_bpu_update_pred_taken_w == branch_bpu_update_taken_w;
  wire [`XLEN-1:0] branch_bpu_update_pc_w =
      branch_bpu_pending_like_update_w ? pending_branch_pc_q :
                                         direct_branch_pc_w;
  wire [`BPU_BHT_INDEX_W-1:0] branch_bpu_update_bht_idx_w =
      branch_bpu_pending_like_update_w ? pending_branch_bht_idx_q :
                                         direct_branch_bht_idx_w;
  wire [`BPU_LOCAL_HISTORY_INDEX_W-1:0] branch_bpu_update_local_hist_idx_w =
      branch_bpu_update_pc_w[`BPU_LOCAL_HISTORY_INDEX_W:1];
  wire [`BPU_LOCAL_HISTORY_W-1:0] branch_bpu_update_local_hist_w =
      branch_local_hist_q[branch_bpu_update_local_hist_idx_w];
  wire [`BPU_LOCAL_PHT_PC_BITS-1:0] branch_bpu_update_local_pc_idx_w =
      branch_bpu_update_pc_w[`BPU_LOCAL_PHT_PC_BITS:1];
  wire [`BPU_LOCAL_PHT_INDEX_W-1:0] branch_bpu_update_local_pht_idx_w =
      {branch_bpu_update_local_pc_idx_w, branch_bpu_update_local_hist_w};
  wire core_checkpoint_capture_w = branch_spec_checkpoint_capture_w;
  wire core_checkpoint_restore_w = branch_spec_restore_w;
  wire core_checkpoint_quiesce_w =
      branch_spec_checkpoint_pending_q && !core_checkpoint_capture_w;
  wire core_mem_issue_block_w = branch_spec_active_q;
  wire core_local_flush_w = flush_i || core_trap_flush_q;
  assign mem_flush_o = core_local_flush_w || checkpoint_mem_flush_q;
  wire core_commit_ready_w =
      commit_ready_i && !core_trap_flush_q &&
      !branch_spec_checkpoint_pending_q &&
      !branch_spec_active_q && !core_checkpoint_restore_w;
  wire core_commit1_block_w =
      !ctrl_commit_valid_q && synth_lane1_ret_pending_q &&
      !synth_lane1_branch_drop_match_w &&
      (synth_lane1_ret_branch_seen_q ||
       synth_lane1_ret_branch_commit0_w);
  wire core_dispatch0_valid_w =
      branch_prefetch_dispatch_attempt_w ||
      pending_lane1_ret_dispatch_valid_w ||
      system_csr_dispatch_valid_w ||
      frontend_dispatch_to_backend_valid_w ||
      direct_branch0_dispatch_valid_w ||
      direct_jal0_dispatch_valid_w ||
      direct_ret0_dispatch_valid_w ||
      lane1_barrier_dispatch0_valid_w ||
      jump_dispatch_valid_w || mem_dispatch_valid_w;
  /* verilator lint_off UNOPTFLAT */
  wire core_dispatch1_valid_w =
      branch_prefetch_dispatch_attempt_w ||
      (!pending_lane1_ret_dispatch_valid_w &&
      (return_cont_attempt_w || branch_target_append_attempt_w ||
       branch_fallthrough_append_attempt_w ||
       frontend_dispatch_to_backend_valid_w));
  /* verilator lint_on UNOPTFLAT */
  wire core_dispatch0_fire_w = core_dispatch0_valid_w && dispatch0_ready_w;
  wire [`XLEN-1:0] core_dispatch0_pc_w =
      branch_prefetch_dispatch_buffer_w ? branch_prefetch_buf_pc0_q :
      branch_prefetch_dispatch_rsp_w ? fetch_dec0_pc_w :
      pending_lane1_ret_dispatch_valid_w ? pending_lane1_ret_pc_q :
      system_csr_dispatch_valid_w ? pending_system_pc_q :
      jump_dispatch_valid_w ? pending_jump_pc_q :
      mem_dispatch_valid_w ? pending_mem_pc_q :
      head_pc_w;
  wire [`XLEN-1:0] core_dispatch0_next_pc_w =
      branch_prefetch_dispatch_buffer_w ? branch_prefetch_buf_next_pc0_q :
      branch_prefetch_dispatch_rsp_w ? fetch_dec0_next_pc_w :
      pending_lane1_ret_dispatch_valid_w ? pending_lane1_ret_next_pc_q :
      system_csr_dispatch_valid_w ? pending_system_next_pc_q :
      jump_dispatch_valid_w ? pending_jump_next_pc_q :
      mem_dispatch_valid_w ? pending_mem_next_pc_q :
      direct_ret0_dispatch_valid_w ? direct_ret_target_w :
      head_next_pc0_w;
  wire [`INST_W-1:0] core_dispatch0_inst_w =
      branch_prefetch_dispatch_buffer_w ? branch_prefetch_buf_inst0_q :
      branch_prefetch_dispatch_rsp_w ? fetch_dec0_inst_w :
      pending_lane1_ret_dispatch_valid_w ? pending_lane1_ret_inst_q :
      system_csr_dispatch_valid_w ? pending_system_inst_q :
      jump_dispatch_valid_w ? pending_jump_inst_q :
      mem_dispatch_valid_w ? pending_mem_inst_q :
      head_inst0_w;
  wire [`XLEN-1:0] core_dispatch1_pc_w =
      branch_prefetch_dispatch_buffer_w ? branch_prefetch_buf_pc1_q :
      branch_prefetch_dispatch_rsp_w ? fetch_dec1_pc_w :
      return_cont_attempt_w ? return_cont_pc_q :
      branch_target_append_attempt_w ?
      branch_target_cache_target_pc_q[branch_target_cache_head_idx_w] :
                                       head_pc1_w;
  wire [`XLEN-1:0] core_dispatch1_next_pc_w =
      branch_prefetch_dispatch_buffer_w ? branch_prefetch_buf_next_pc1_q :
      branch_prefetch_dispatch_rsp_w ? fetch_dec1_next_pc_w :
      return_cont_attempt_w ? return_cont_next_pc_q :
      branch_target_append_attempt_w ?
      branch_target_cache_next_pc_q[branch_target_cache_head_idx_w] :
      direct_ret1_fire_w ? direct_ret_target_w :
                                       head_next_pc1_w;
  wire [`INST_W-1:0] core_dispatch1_inst_w =
      branch_prefetch_dispatch_buffer_w ? branch_prefetch_buf_inst1_q :
      branch_prefetch_dispatch_rsp_w ? fetch_dec1_inst_w :
      return_cont_attempt_w ? return_cont_inst_q :
      branch_target_append_attempt_w ?
      branch_target_cache_inst_q[branch_target_cache_head_idx_w] :
                                       head_inst1_w;
  wire jump_dispatch_fire_w = jump_dispatch_valid_w && dispatch0_ready_w;
  wire mem_dispatch_fire_w = mem_dispatch_valid_w && dispatch0_ready_w;
  wire [`XLEN-1:0] core_dispatch0_csr_rdata_w =
      system_csr_dispatch_valid_w ? pending_system_csr_rdata_q :
                                    {`XLEN{1'b0}};

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

  function [`XLEN-1:0] fp_i_imm;
    input [`INST_W-1:0] inst;
    begin
      fp_i_imm = {{(`XLEN-12){inst[31]}}, inst[31:20]};
    end
  endfunction

  function [`XLEN-1:0] fp_s_imm;
    input [`INST_W-1:0] inst;
    begin
      fp_s_imm = {{(`XLEN-12){inst[31]}}, inst[31:25], inst[11:7]};
    end
  endfunction

  function [`XLEN-1:0] fp_aligned_addr;
    input [`XLEN-1:0] addr;
    begin
      fp_aligned_addr = addr & {{(`XLEN-`XLEN_BYTE_W){1'b1}}, {`XLEN_BYTE_W{1'b0}}};
    end
  endfunction

  function [`STRB_W-1:0] fp_store_wstrb;
    input [`XLEN-1:0] addr;
    input is_double;
    begin
      fp_store_wstrb = is_double ? {`STRB_W{1'b1}} :
                       ({{(`STRB_W-4){1'b0}}, 4'b1111} << addr[`XLEN_BYTE_W-1:0]);
    end
  endfunction

  function [`XLEN-1:0] fp_store_wdata;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] value;
    input is_double;
    begin
      fp_store_wdata = is_double ? value :
                       ({{32{1'b0}}, value[31:0]} << {addr[`XLEN_BYTE_W-1:0], 3'b000});
    end
  endfunction

  wire pending_fp_mem_req_valid_w =
      stop_pending_q && pending_fp_q && backend_drained_q &&
      !pending_fp_mem_pending_q && !pending_fp_mem_done_q;
  wire pending_fp_mem_req_fire_w =
      pending_fp_mem_req_valid_w && mem_req_ready_i;
  wire pending_fp_mem_rsp_fire_w =
      pending_fp_mem_pending_q && mem_rsp_valid_i;
  wire [`XLEN-1:0] pending_fp_shifted_rdata_w =
      mem_rsp_rdata_i >> {pending_fp_addr_q[`XLEN_BYTE_W-1:0], 3'b000};
  wire [`XLEN-1:0] pending_fp_load_value_w =
      pending_fp_double_q ? pending_fp_shifted_rdata_w :
      {32'hffff_ffff, pending_fp_shifted_rdata_w[31:0]};

  assign mem_req_valid_o = pending_fp_mem_req_valid_w ? 1'b1 : core_mem_req_valid_w;
  assign mem_req_write_o = pending_fp_mem_req_valid_w ? pending_fp_store_q :
                           core_mem_req_write_w;
  assign mem_req_addr_o = pending_fp_mem_req_valid_w ? fp_aligned_addr(pending_fp_addr_q) :
                          core_mem_req_addr_w;
  assign mem_req_wdata_o = pending_fp_mem_req_valid_w ? pending_fp_wdata_q :
                           core_mem_req_wdata_w;
  assign mem_req_wstrb_o = pending_fp_mem_req_valid_w ? pending_fp_wstrb_q :
                           core_mem_req_wstrb_w;
  assign mem_rsp_ready_o = pending_fp_mem_pending_q ? 1'b1 : core_mem_rsp_ready_w;
  assign mem1_req_valid_o = core_mem1_req_valid_w;
  assign mem1_req_write_o = core_mem1_req_write_w;
  assign mem1_req_addr_o = core_mem1_req_addr_w;
  assign mem1_req_wdata_o = core_mem1_req_wdata_w;
  assign mem1_req_wstrb_o = core_mem1_req_wstrb_w;
  assign mem1_rsp_ready_o = core_mem1_rsp_ready_w;

  assign pending_branch_rs1_data_w =
      arch_gpr(core_debug_gprs_w, pending_branch_rs1_q);
  assign pending_branch_rs2_data_w =
      arch_gpr(core_debug_gprs_w, pending_branch_rs2_q);
  assign pending_jump_rs1_data_w =
      arch_gpr(core_debug_gprs_w, pending_jump_rs1_q);
  wire head0_fp_double_w =
      (head_inst0_w[14:12] == `FUNCT3_LD) ||
      (head_inst0_w[14:12] == `FUNCT3_SD) ||
      (head_inst0_w[31:25] == 7'b1111001);
  wire head1_fp_double_w =
      (head_inst1_w[14:12] == `FUNCT3_LD) ||
      (head_inst1_w[14:12] == `FUNCT3_SD) ||
      (head_inst1_w[31:25] == 7'b1111001);
  wire [`XLEN-1:0] head0_fp_addr_w =
      arch_gpr(core_debug_gprs_w, head0_rs1_w) +
      (head0_fp_load_raw_w ? fp_i_imm(head_inst0_w) : fp_s_imm(head_inst0_w));
  wire [`XLEN-1:0] head1_fp_addr_w =
      arch_gpr(core_debug_gprs_w, head1_rs1_w) +
      (head1_fp_load_raw_w ? fp_i_imm(head_inst1_w) : fp_s_imm(head_inst1_w));
  wire [`XLEN-1:0] head0_fp_store_value_w = fpr_q[head0_rs2_w];
  wire [`XLEN-1:0] head1_fp_store_value_w = fpr_q[head1_rs2_w];
  wire [`XLEN-1:0] head0_fp_rs1_value_w =
      arch_gpr(core_debug_gprs_w, head0_rs1_w);
  wire [`XLEN-1:0] head1_fp_rs1_value_w =
      arch_gpr(core_debug_gprs_w, head1_rs1_w);
  wire [`XLEN-1:0] head0_fp_move_value_w =
      head0_fp_double_w ? head0_fp_rs1_value_w :
      {32'hffff_ffff, head0_fp_rs1_value_w[31:0]};
  wire [`XLEN-1:0] head1_fp_move_value_w =
      head1_fp_double_w ? head1_fp_rs1_value_w :
      {32'hffff_ffff, head1_fp_rs1_value_w[31:0]};

  CsrFile u_csr_file (
    .clk(clk),
    .rst(rst),
    .cycle_count_enable_i(run_i && !halted_q),
    .time_i(time_i),
    .instret_inc_i(core_retire_count_w),
    .csr_valid_i(csr_access_valid_w),
    .csr_addr_i(csr_access_addr_w),
    .csr_funct3_i(csr_access_funct3_w),
    .csr_rs1_idx_i(csr_access_rs1_idx_w),
    .csr_rs1_data_i(csr_access_rs1_data_w),
    .csr_zimm_i(csr_access_rs1_idx_w),
    .csr_commit_i(pending_system_csr_commit_w),
    .csr_rdata_o(csr_rdata_w),
    .csr_illegal_o(csr_illegal_w),
    .trap_mem_valid_i(csr_trap_mem_valid_w),
    .trap_mem_pc_i(csr_trap_mem_pc_w),
    .trap_mem_cause_i(csr_trap_mem_cause_w),
    .trap_mem_tval_i(csr_trap_mem_tval_w),
    .trap_ex_valid_i(csr_trap_ex_valid_w),
    .trap_ex_pc_i(csr_trap_ex_pc_w),
    .trap_ex_cause_i(csr_trap_ex_cause_w),
    .trap_ex_tval_i(csr_trap_ex_tval_w),
    .irq_software_i(irq_software_i),
    .irq_timer_i(irq_timer_i),
    .irq_external_i(irq_external_i),
    .irq_pending_o(csr_irq_pending_w),
    .irq_cause_o(csr_irq_cause_w),
    .trap_irq_valid_i(csr_trap_irq_valid_w),
    .trap_irq_pc_i(pending_system_pc_q),
    .trap_irq_cause_i(pending_system_irq_cause_q),
    .mret_valid_i(csr_real_mret_valid_w),
    .sret_valid_i(csr_sret_valid_w),
    .trap_target_o(csr_trap_target_w),
    .mepc_o(csr_mepc_w),
    .ret_target_o(csr_ret_target_w),
    .priv_mode_o(csr_priv_mode_w),
    .ecall_cause_o(csr_ecall_cause_w),
    .mstatus_o(csr_mstatus_w),
    .satp_o(csr_satp_w)
  );

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

  DecodeStage u_branch_prefetch0_decode (
    .inst_i(branch_prefetch_buf_inst0_q),
    .ctrl_o(branch_prefetch0_ctrl_w),
    .rs1_idx_o(branch_prefetch0_rs1_unused_w),
    .rs2_idx_o(branch_prefetch0_rs2_unused_w),
    .rd_idx_o(branch_prefetch0_rd_unused_w),
    .imm_o(branch_prefetch0_imm_unused_w)
  );

  DecodeStage u_branch_prefetch1_decode (
    .inst_i(branch_prefetch_buf_inst1_q),
    .ctrl_o(branch_prefetch1_ctrl_w),
    .rs1_idx_o(branch_prefetch1_rs1_unused_w),
    .rs2_idx_o(branch_prefetch1_rs2_unused_w),
    .rd_idx_o(branch_prefetch1_rd_unused_w),
    .imm_o(branch_prefetch1_imm_unused_w)
  );

  DecodeStage u_branch_prefetch_rsp1_decode (
    .inst_i(fetch_dec1_inst_w),
    .ctrl_o(branch_prefetch_rsp1_ctrl_w),
    .rs1_idx_o(branch_prefetch_rsp1_rs1_unused_w),
    .rs2_idx_o(branch_prefetch_rsp1_rs2_unused_w),
    .rd_idx_o(branch_prefetch_rsp1_rd_unused_w),
    .imm_o(branch_prefetch_rsp1_imm_unused_w)
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
    .flush_i(core_local_flush_w),
    .checkpoint_capture_i(core_checkpoint_capture_w),
    .checkpoint_restore_i(core_checkpoint_restore_w),
    .checkpoint_quiesce_i(core_checkpoint_quiesce_w),
    .mem_issue_block_i(core_mem_issue_block_w),
    .pending_branch_fast_valid_i(stop_pending_q && pending_branch_q &&
                                 pending_branch_dispatched_q),
    .pending_branch_fast_pc_i(pending_branch_pc_q),
    .dispatch0_valid_i(core_dispatch0_valid_w),
    .dispatch0_ready_o(dispatch0_ready_w),
    .dispatch0_pc_i(core_dispatch0_pc_w),
    .dispatch0_next_pc_i(core_dispatch0_next_pc_w),
    .dispatch0_inst_i(core_dispatch0_inst_w),
    .dispatch0_csr_rdata_i(core_dispatch0_csr_rdata_w),
    .dispatch0_unsupported_o(dispatch0_unsupported_w),
    .dispatch1_valid_i(core_dispatch1_valid_w),
    .dispatch1_optional_i(dispatch1_optional_w),
    .dispatch1_ready_o(dispatch1_ready_w),
    .dispatch1_pc_i(core_dispatch1_pc_w),
    .dispatch1_next_pc_i(core_dispatch1_next_pc_w),
    .dispatch1_inst_i(core_dispatch1_inst_w),
    .dispatch1_csr_rdata_i({`XLEN{1'b0}}),
    .dispatch1_unsupported_o(dispatch1_unsupported_w),
    .mem_req_valid_o(core_mem_req_valid_w),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_write_o(core_mem_req_write_w),
    .mem_req_addr_o(core_mem_req_addr_w),
    .mem_req_wdata_o(core_mem_req_wdata_w),
    .mem_req_wstrb_o(core_mem_req_wstrb_w),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mem_rsp_ready_o(core_mem_rsp_ready_w),
    .mem_rsp_rdata_i(mem_rsp_rdata_i),
    .mem_rsp_error_i(mem_rsp_error_i),
    .mem_rsp_page_fault_i(mem_rsp_page_fault_i),
    .mem1_req_valid_o(core_mem1_req_valid_w),
    .mem1_req_ready_i(mem1_req_ready_i),
    .mem1_req_write_o(core_mem1_req_write_w),
    .mem1_req_addr_o(core_mem1_req_addr_w),
    .mem1_req_wdata_o(core_mem1_req_wdata_w),
    .mem1_req_wstrb_o(core_mem1_req_wstrb_w),
    .mem1_rsp_valid_i(mem1_rsp_valid_i),
    .mem1_rsp_ready_o(core_mem1_rsp_ready_w),
    .mem1_rsp_rdata_i(mem1_rsp_rdata_i),
    .mem1_rsp_error_i(mem1_rsp_error_i),
    .mem1_rsp_page_fault_i(mem1_rsp_page_fault_i),
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
    .commit0_cause_o(core_commit0_cause_w),
    .commit0_tval_o(core_commit0_tval_w),
    .commit0_write_o(core_commit0_write_w),
    .commit1_valid_o(core_commit1_valid_w),
    .commit1_pc_o(core_commit1_pc_w),
    .commit1_next_pc_o(core_commit1_next_pc_w),
    .commit1_inst_o(core_commit1_inst_w),
    .commit1_rd_en_o(core_commit1_rd_en_w),
    .commit1_arch_rd_o(core_commit1_rd_addr_w),
    .commit1_data_o(core_commit1_rd_data_w),
    .commit1_exception_o(core_commit1_exception_w),
    .commit1_cause_o(core_commit1_cause_w),
    .commit1_tval_o(core_commit1_tval_w),
    .commit1_write_o(core_commit1_write_w),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
	    .issue_count_o(issue_count_o),
	    .mem_idle_o(core_mem_idle_w),
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
	    .pending_load_branch_dep_o(core_pending_load_branch_dep_w),
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
  assign exit_is_ecall_o = exit_is_ecall_q;
  assign exit_is_ebreak_o = exit_is_ebreak_q;
  assign exit_code_o = a0_data_w;
  assign halted_o = halted_q ||
                    (stop_pending_q && !pending_branch_q && !pending_jump_q &&
                     !pending_mem_q && !pending_fp_q && !pending_system_q &&
                     !synth_lane1_ret_pending_q &&
                     !synth_lane1_branch_drop_pending_q);
  assign priv_mode_o = csr_priv_mode_w;
  assign mstatus_o = csr_mstatus_w;
  assign satp_o = csr_satp_w;
  assign mmu_flush_o =
      pending_system_satp_write_commit_w || pending_system_sfence_commit_w;
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
      (|branch_prefetch0_rs1_unused_w) |
      (|branch_prefetch0_rs2_unused_w) |
      (|branch_prefetch0_rd_unused_w) |
      (|branch_prefetch0_imm_unused_w) |
      (|branch_prefetch1_rs1_unused_w) |
      (|branch_prefetch1_rs2_unused_w) |
      (|branch_prefetch1_rd_unused_w) |
      (|branch_prefetch1_imm_unused_w) |
      (|branch_prefetch_rsp1_rs1_unused_w) |
      (|branch_prefetch_rsp1_rs2_unused_w) |
      (|branch_prefetch_rsp1_rd_unused_w) |
      (|branch_prefetch_rsp1_imm_unused_w) |
      branch_fallthrough_safe_w | branch_target_cache_hit_w |
      pending_jump_jalr_sum_lsb_unused_w | head_fetch_fault_w |
      pending_branch_bht_valid_q |
      branch_bpu_lookup_event_w | branch_bpu_lookup_bht_valid_w |
      branch_bpu_update_correct_w |
      csr_irq_pending_w | (|csr_irq_cause_w) | (|csr_trap_target_w) |
      (|csr_mepc_w) | (|csr_priv_mode_w) | (|csr_satp_w) |
      (|head_packet_next_pc_w);

  integer reset_idx;
  integer ras_reset_idx;
  integer branch_target_cache_reset_idx;
  integer jalr_btb_reset_idx;
  integer branch_bht_reset_idx;
  integer branch_local_hist_reset_idx;
  integer branch_local_pht_reset_idx;
  integer fpr_reset_idx;

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
      exit_is_ecall_q <= 1'b0;
      exit_is_ebreak_q <= 1'b0;
      halted_q <= 1'b0;
      stop_pending_q <= 1'b0;
      pending_exit_q <= 1'b0;
      pending_exit_is_ecall_q <= 1'b0;
      pending_exit_is_ebreak_q <= 1'b0;
      pending_branch_q <= 1'b0;
      pending_branch_dispatched_q <= 1'b0;
      pending_jump_q <= 1'b0;
      pending_jump_dispatched_q <= 1'b0;
      pending_jump_jalr_q <= 1'b0;
      pending_mem_q <= 1'b0;
      pending_mem_dispatched_q <= 1'b0;
      pending_fp_q <= 1'b0;
      pending_fp_mem_pending_q <= 1'b0;
      pending_fp_mem_done_q <= 1'b0;
      pending_fp_load_q <= 1'b0;
      pending_fp_store_q <= 1'b0;
      pending_fp_double_q <= 1'b0;
      pending_arch_trap_q <= 1'b0;
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
      pending_branch_pred_taken_q <= 1'b0;
      pending_branch_bht_valid_q <= 1'b0;
      pending_branch_bht_idx_q <= {`BPU_BHT_INDEX_W{1'b0}};
      direct_branch_wait_q <= 1'b0;
      direct_branch_wait_pc_q <= {`XLEN{1'b0}};
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
      pending_fp_pc_q <= {`XLEN{1'b0}};
      pending_fp_inst_q <= {`INST_W{1'b0}};
      pending_fp_next_pc_q <= {`XLEN{1'b0}};
      pending_fp_addr_q <= {`XLEN{1'b0}};
      pending_fp_wdata_q <= {`XLEN{1'b0}};
      pending_fp_wstrb_q <= {`STRB_W{1'b0}};
      pending_fp_rd_q <= {`REG_ADDR_W{1'b0}};
      pending_system_q <= 1'b0;
      pending_system_dispatched_q <= 1'b0;
      pending_system_csr_q <= 1'b0;
      pending_system_ecall_q <= 1'b0;
      pending_system_mret_q <= 1'b0;
      pending_system_wfi_q <= 1'b0;
      pending_system_sfence_q <= 1'b0;
      pending_system_irq_q <= 1'b0;
      pending_system_pc_q <= {`XLEN{1'b0}};
      pending_system_inst_q <= {`INST_W{1'b0}};
      pending_system_next_pc_q <= {`XLEN{1'b0}};
      pending_system_csr_rdata_q <= {`XLEN{1'b0}};
      pending_system_irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
      ctrl_commit_valid_q <= 1'b0;
      ctrl_commit_pc_q <= {`XLEN{1'b0}};
      ctrl_commit_inst_q <= {`INST_W{1'b0}};
      ctrl_commit_next_pc_q <= {`XLEN{1'b0}};
      backend_drained_q <= 1'b1;
      core_trap_flush_q <= 1'b0;
      checkpoint_mem_flush_q <= 1'b0;
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
      /* verilator lint_off BLKSEQ */
      for (jalr_btb_reset_idx = 0;
           jalr_btb_reset_idx < `BPU_BTB_ENTRIES;
           jalr_btb_reset_idx = jalr_btb_reset_idx + 1) begin
        jalr_btb_valid_q[jalr_btb_reset_idx] = 1'b0;
        jalr_btb_pc_q[jalr_btb_reset_idx] = {`XLEN{1'b0}};
        jalr_btb_target_q[jalr_btb_reset_idx] = {`XLEN{1'b0}};
      end
      branch_ghr_q <= {`BPU_BHT_INDEX_W{1'b0}};
      for (branch_bht_reset_idx = 0;
           branch_bht_reset_idx < `BPU_BHT_ENTRIES;
           branch_bht_reset_idx = branch_bht_reset_idx + 1) begin
        branch_bht_valid_q[branch_bht_reset_idx] = 1'b0;
        branch_bht_q[branch_bht_reset_idx] = `BPU_COUNTER_INIT;
      end
      for (branch_local_hist_reset_idx = 0;
           branch_local_hist_reset_idx < `BPU_LOCAL_HISTORY_ENTRIES;
           branch_local_hist_reset_idx = branch_local_hist_reset_idx + 1) begin
        branch_local_hist_q[branch_local_hist_reset_idx] =
            {`BPU_LOCAL_HISTORY_W{1'b0}};
      end
      for (branch_local_pht_reset_idx = 0;
           branch_local_pht_reset_idx < `BPU_LOCAL_PHT_ENTRIES;
           branch_local_pht_reset_idx = branch_local_pht_reset_idx + 1) begin
        branch_local_pht_valid_q[branch_local_pht_reset_idx] = 1'b0;
        branch_local_pht_q[branch_local_pht_reset_idx] = `BPU_COUNTER_INIT;
      end
      for (fpr_reset_idx = 0; fpr_reset_idx < `REG_NUM; fpr_reset_idx = fpr_reset_idx + 1) begin
        fpr_q[fpr_reset_idx] = {`XLEN{1'b0}};
      end
      /* verilator lint_on BLKSEQ */
    end else begin
      ctrl_commit_valid_q <= 1'b0;
      backend_drained_q <= backend_drained_w && !core_dispatch0_fire_w;
      core_trap_flush_q <= 1'b0;
      checkpoint_mem_flush_q <= core_checkpoint_restore_w;

      if (pending_fp_mem_req_fire_w) begin
        pending_fp_mem_pending_q <= 1'b1;
      end
      if (pending_fp_mem_rsp_fire_w) begin
        pending_fp_mem_pending_q <= 1'b0;
        pending_fp_mem_done_q <= 1'b1;
        if (pending_fp_load_q)
          fpr_q[pending_fp_rd_q] <= pending_fp_load_value_w;
      end

      if (branch_bpu_update_valid_w) begin
        // 条件分支按预测时携带的 gshare index 训练，避免 resolve 阶段 GHR 漂移写错表项。
        branch_bht_valid_q[branch_bpu_update_bht_idx_w] <= 1'b1;
        if (branch_bpu_update_taken_w) begin
          if (branch_bht_q[branch_bpu_update_bht_idx_w] != 2'd3)
            branch_bht_q[branch_bpu_update_bht_idx_w] <=
                branch_bht_q[branch_bpu_update_bht_idx_w] + 2'd1;
        end else if (branch_bht_q[branch_bpu_update_bht_idx_w] != 2'd0) begin
          branch_bht_q[branch_bpu_update_bht_idx_w] <=
              branch_bht_q[branch_bpu_update_bht_idx_w] - 2'd1;
        end
        branch_ghr_q <= {branch_ghr_q[`BPU_BHT_INDEX_W-2:0],
                         branch_bpu_update_taken_w};

        // local predictor 与原 BPU 一致：强置信 local 项才覆盖 gshare，弱项只参与训练。
        branch_local_pht_valid_q[branch_bpu_update_local_pht_idx_w] <= 1'b1;
        if (branch_bpu_update_taken_w) begin
          if (branch_local_pht_q[branch_bpu_update_local_pht_idx_w] != 2'd3)
            branch_local_pht_q[branch_bpu_update_local_pht_idx_w] <=
                branch_local_pht_q[branch_bpu_update_local_pht_idx_w] + 2'd1;
        end else if (branch_local_pht_q[branch_bpu_update_local_pht_idx_w] != 2'd0) begin
          branch_local_pht_q[branch_bpu_update_local_pht_idx_w] <=
              branch_local_pht_q[branch_bpu_update_local_pht_idx_w] - 2'd1;
        end
        branch_local_hist_q[branch_bpu_update_local_hist_idx_w] <=
            {branch_bpu_update_local_hist_w[`BPU_LOCAL_HISTORY_W-2:0],
             branch_bpu_update_taken_w};
      end

      if (jalr_btb_update_w) begin
        jalr_btb_valid_q[pending_jump_jalr_btb_idx_w] <= 1'b1;
        jalr_btb_pc_q[pending_jump_jalr_btb_idx_w] <= pending_jump_pc_q;
        jalr_btb_target_q[pending_jump_jalr_btb_idx_w] <=
            pending_jump_resolved_target_w;
      end

      if (branch_target_cache_invalidate_all_w) begin
        for (branch_target_cache_reset_idx = 0;
             branch_target_cache_reset_idx < BRANCH_TARGET_CACHE_ENTRIES;
             branch_target_cache_reset_idx = branch_target_cache_reset_idx + 1) begin
          branch_target_cache_valid_q[branch_target_cache_reset_idx] <= 1'b0;
        end
      end else begin
        if (branch_target_store_fire_w) begin
          for (branch_target_cache_reset_idx = 0;
               branch_target_cache_reset_idx < BRANCH_TARGET_CACHE_ENTRIES;
               branch_target_cache_reset_idx = branch_target_cache_reset_idx + 1) begin
            if (branch_target_cache_valid_q[branch_target_cache_reset_idx] &&
                branch_target_same_fetch_word(
                    branch_target_store_addr_w,
                    branch_target_cache_target_pc_q[branch_target_cache_reset_idx])) begin
              branch_target_cache_valid_q[branch_target_cache_reset_idx] <=
                  1'b0;
            end
          end
        end
        if (branch_target_cache_capture_w) begin
          branch_target_capture_pending_q <= 1'b0;
          branch_target_capture_branch_pc_q <= {`XLEN{1'b0}};
          branch_target_capture_target_pc_q <= {`XLEN{1'b0}};
          if (!branch_target_store_fire_w ||
              !branch_target_same_fetch_word(branch_target_store_addr_w,
                                             fetch_dec0_pc_w)) begin
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
          end
        end else if (branch_target_capture_hit_w) begin
          branch_target_capture_pending_q <= 1'b0;
          branch_target_capture_branch_pc_q <= {`XLEN{1'b0}};
          branch_target_capture_target_pc_q <= {`XLEN{1'b0}};
        end
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

      if (direct_branch_wait_resolve_match_w) begin
        direct_branch_wait_q <= 1'b0;
        direct_branch_wait_pc_q <= {`XLEN{1'b0}};
      end
      if (direct_branch_fire_w) begin
        direct_branch_wait_q <= !direct_branch_resolve_valid_w;
        direct_branch_wait_pc_q <= direct_branch_resolve_valid_w ?
                                   {`XLEN{1'b0}} : direct_branch_pc_w;
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
        // 控制流预测包只进入影子槽，resolve 命中前绝不暴露给正常 dispatch FIFO。
        branch_prefetch_active_q <= 1'b1;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= branch_prefetch_req_pc_w;
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

      if (csr_trap_mem_valid_w) begin
        fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_count_q <= {FETCH_COUNT_W{1'b0}};
        outstanding_valid_q <= 1'b0;
        outstanding_pc_q <= {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_w;
        stop_pending_q <= 1'b0;
        pending_exit_q <= 1'b0;
        pending_exit_is_ecall_q <= 1'b0;
        pending_exit_is_ebreak_q <= 1'b0;
        pending_branch_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_fp_q <= 1'b0;
        pending_fp_mem_pending_q <= 1'b0;
        pending_fp_mem_done_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
        pending_mem_next_pc_q <= {`XLEN{1'b0}};
        pending_fp_next_pc_q <= {`XLEN{1'b0}};
        pending_branch_next_pc_q <= {`XLEN{1'b0}};
        pending_jump_next_pc_q <= {`XLEN{1'b0}};
        direct_branch_wait_q <= 1'b0;
        direct_branch_wait_pc_q <= {`XLEN{1'b0}};
        pending_trap_cause_q <= {`TRAP_CAUSE_W{1'b0}};
        pending_trap_pc_q <= {`XLEN{1'b0}};
        pending_trap_tval_q <= {`XLEN{1'b0}};
        branch_prefetch_active_q <= 1'b0;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= {`XLEN{1'b0}};
        branch_spec_active_q <= 1'b0;
        branch_spec_checkpoint_pending_q <= 1'b0;
        branch_spec_pred_pc_q <= {`XLEN{1'b0}};
        branch_target_capture_pending_q <= 1'b0;
        branch_target_capture_branch_pc_q <= {`XLEN{1'b0}};
        branch_target_capture_target_pc_q <= {`XLEN{1'b0}};
        backend_drained_q <= 1'b1;
        core_trap_flush_q <= 1'b1;
        next_fetch_pc_q <= csr_trap_target_w;
      end else if (direct_frontend_flush_w) begin
        fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_count_q <= {FETCH_COUNT_W{1'b0}};
        pending_lane1_ret_q <= 1'b0;
        pending_lane1_ret_pc_q <= {`XLEN{1'b0}};
        pending_lane1_ret_next_pc_q <= {`XLEN{1'b0}};
        pending_lane1_ret_inst_q <= {`INST_W{1'b0}};
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        branch_prefetch_active_q <= 1'b0;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= {`XLEN{1'b0}};
        branch_spec_active_q <= 1'b0;
        branch_spec_checkpoint_pending_q <= 1'b0;
        branch_spec_pred_pc_q <= {`XLEN{1'b0}};
        branch_target_capture_pending_q <= 1'b0;
        branch_target_capture_branch_pc_q <= {`XLEN{1'b0}};
        branch_target_capture_target_pc_q <= {`XLEN{1'b0}};
        outstanding_valid_q <= branch_fallthrough_keep_outstanding_w ? 1'b1 :
                               fetch_req_fire_w;
        outstanding_pc_q <= branch_fallthrough_keep_outstanding_w ?
                            outstanding_pc_q :
                            (fetch_req_fire_w ? fetch_req_pc_w :
                                                {`XLEN{1'b0}});
        discard_fetch_rsp_q <= branch_fallthrough_keep_outstanding_w ? 1'b0 :
                               (outstanding_valid_q && !fetch_rsp_fire_w);
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
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
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
          pending_branch_pred_taken_q <= direct_branch_predict_taken_w;
          pending_branch_bht_valid_q <= direct_branch_bht_valid_w;
          pending_branch_bht_idx_q <= direct_branch_bht_idx_w;
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          if (direct_branch_resolve_redirect_w &&
              !direct_branch0_lane1_ret_w && !branch_target_dispatch_w &&
              direct_branch_resolve_taken_w) begin
            branch_target_capture_pending_q <= 1'b1;
            branch_target_capture_branch_pc_q <= direct_branch1_fire_w ?
                                                 head_pc1_w : head_pc_w;
            branch_target_capture_target_pc_q <=
                direct_branch_resolve_next_pc_w;
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
                             direct_branch_resolve_next_pc_w :
	                             direct_branch_spec_start_w ?
	                             direct_branch_pred_pc_w :
	                             (direct_branch1_fire_w ? head_next_pc1_w :
	                                                      head_next_pc0_w);
          if (branch_fallthrough_capture_rsp_w) begin
            fifo_tail_q <= ptr_inc({FETCH_PACKET_COUNT_W{1'b0}});
            fifo_count_q <= {{(FETCH_COUNT_W-1){1'b0}}, 1'b1};
            fifo_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <= fetch_dec0_pc_w;
            fifo_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <= fetch_dec1_pc_w;
            fifo_next_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                fetch_dec0_next_pc_w;
            fifo_next_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                fetch_dec1_next_pc_w;
            fifo_packet_next_pc_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                fetch_rsp_packet_next_pc_w;
            fifo_inst0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <= fetch_dec0_inst_w;
            fifo_inst1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <= fetch_dec1_inst_w;
            fifo_resp0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <= fetch_rsp_resp0_i;
            fifo_resp1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <= fetch_dec1_resp_w;
            next_fetch_pc_q <= fetch_rsp_packet_next_pc_w;
          end
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
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
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

      if (orphan_stop_pending_w) begin
        stop_pending_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
      end

      if (pending_branch_commit_resolve_w) begin
        // 后端已在精确边界退休该分支，但 resolve pulse 没被前端采到；
        // 此时后端已清空，可用架构寄存器重算分支方向并收束前端停顿。
        stop_pending_q <= 1'b0;
        pending_exit_q <= 1'b0;
        pending_branch_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
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
        outstanding_valid_q <= 1'b0;
        outstanding_pc_q <= {`XLEN{1'b0}};
        discard_fetch_rsp_q <= fetch_req_fire_w ||
                               (outstanding_valid_q && !fetch_rsp_fire_w);
        if (pending_branch_misaligned_w) begin
          halted_q <= 1'b1;
          trap_valid_q <= 1'b1;
          trap_cause_q <= `EXC_INST_ADDR_MISALIGN;
          trap_pc_q <= pending_branch_pc_q;
          trap_tval_q <= pending_branch_target_w;
        end else begin
          next_fetch_pc_q <= pending_branch_next_pc_w;
        end
      end else if (!direct_frontend_flush_w && stop_pending_q &&
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
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
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
                        branch_prefetch_hit_to_fifo_w) ?
                       ptr_inc({FETCH_PACKET_COUNT_W{1'b0}}) :
                       {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_count_q <= (!core_branch_resolve_misaligned_w &&
                         branch_prefetch_hit_to_fifo_w) ?
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
          // 普通 uop 包可在 resolve 同拍送入后端；不能旁路时仍转正为 FIFO 包。
          if (branch_prefetch_hit_to_fifo_w) begin
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
          end
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
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
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
          pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          branch_prefetch_active_q <= 1'b0;
          branch_prefetch_buffer_valid_q <= 1'b0;
          branch_prefetch_pc_q <= {`XLEN{1'b0}};
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
          pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          branch_prefetch_active_q <= 1'b0;
          branch_prefetch_buffer_valid_q <= 1'b0;
          branch_prefetch_pc_q <= {`XLEN{1'b0}};
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= jalr_prefetch_hit_available_w ?
                         ptr_inc({FETCH_PACKET_COUNT_W{1'b0}}) :
                         {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= jalr_prefetch_hit_available_w ?
                          {{(FETCH_COUNT_W-1){1'b0}}, 1'b1} :
                          {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= jalr_prefetch_pending_match_w ? 1'b1 :
                                 fetch_req_fire_w;
          outstanding_pc_q <= jalr_prefetch_pending_match_w ?
                              branch_prefetch_pc_q :
                              (fetch_req_fire_w ? fetch_req_pc_w :
                                                  {`XLEN{1'b0}});
          discard_fetch_rsp_q <= (jalr_prefetch_hit_available_w &&
                                  fetch_req_fire_w) ||
                                 (!jalr_prefetch_pending_match_w &&
                                  outstanding_valid_q && !fetch_rsp_fire_w);
          if (jalr_prefetch_hit_available_w) begin
            fifo_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_pc0_w;
            fifo_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_pc1_w;
            fifo_next_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_next_pc0_w;
            fifo_next_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_next_pc1_w;
            fifo_packet_next_pc_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_packet_next_pc_w;
            fifo_inst0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_inst0_w;
            fifo_inst1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_inst1_w;
            fifo_resp0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_resp0_w;
            fifo_resp1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_resp1_w;
            next_fetch_pc_q <= jalr_prefetch_hit_packet_next_pc_w;
          end else begin
            next_fetch_pc_q <= pending_jump_resolved_target_w;
          end
          ctrl_commit_valid_q <= 1'b1;
	          ctrl_commit_pc_q <= pending_jump_pc_q;
	          ctrl_commit_inst_q <= pending_jump_inst_q;
	          ctrl_commit_next_pc_q <= pending_jump_resolved_target_w;
	        end else if (pending_jump_redirect_after_dispatch_w) begin
	          stop_pending_q <= 1'b0;
	          pending_exit_q <= 1'b0;
	          pending_branch_q <= 1'b0;
	          pending_branch_dispatched_q <= 1'b0;
	          pending_jump_q <= 1'b0;
	          pending_jump_dispatched_q <= 1'b0;
	          pending_mem_q <= 1'b0;
	          pending_mem_dispatched_q <= 1'b0;
	          pending_system_q <= 1'b0;
	          pending_system_dispatched_q <= 1'b0;
	          pending_system_csr_q <= 1'b0;
	          pending_system_ecall_q <= 1'b0;
	          pending_system_mret_q <= 1'b0;
	          pending_system_wfi_q <= 1'b0;
	          pending_system_sfence_q <= 1'b0;
	          pending_system_irq_q <= 1'b0;
	          pending_mem_next_pc_q <= {`XLEN{1'b0}};
	          pending_branch_next_pc_q <= {`XLEN{1'b0}};
	          pending_jump_next_pc_q <= {`XLEN{1'b0}};
	          branch_prefetch_active_q <= 1'b0;
	          branch_prefetch_buffer_valid_q <= 1'b0;
	          branch_prefetch_pc_q <= {`XLEN{1'b0}};
	          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
	          fifo_tail_q <= jalr_prefetch_hit_available_w ?
	                         ptr_inc({FETCH_PACKET_COUNT_W{1'b0}}) :
	                         {FETCH_PACKET_COUNT_W{1'b0}};
	          fifo_count_q <= jalr_prefetch_hit_available_w ?
	                          {{(FETCH_COUNT_W-1){1'b0}}, 1'b1} :
	                          {FETCH_COUNT_W{1'b0}};
	          outstanding_valid_q <= jalr_prefetch_pending_match_w ? 1'b1 :
	                                 fetch_req_fire_w;
	          outstanding_pc_q <= jalr_prefetch_pending_match_w ?
	                              branch_prefetch_pc_q :
	                              (fetch_req_fire_w ? fetch_req_pc_w :
	                                                  {`XLEN{1'b0}});
	          discard_fetch_rsp_q <= (jalr_prefetch_hit_available_w &&
	                                  fetch_req_fire_w) ||
	                                 (!jalr_prefetch_pending_match_w &&
	                                  outstanding_valid_q && !fetch_rsp_fire_w);
	          if (jalr_prefetch_hit_available_w) begin
	            fifo_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_pc0_w;
	            fifo_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_pc1_w;
	            fifo_next_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_next_pc0_w;
	            fifo_next_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_next_pc1_w;
	            fifo_packet_next_pc_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_packet_next_pc_w;
	            fifo_inst0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_inst0_w;
	            fifo_inst1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_inst1_w;
	            fifo_resp0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_resp0_w;
	            fifo_resp1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
	                jalr_prefetch_hit_resp1_w;
	            next_fetch_pc_q <= jalr_prefetch_hit_packet_next_pc_w;
	          end else begin
	            next_fetch_pc_q <= pending_jump_resolved_target_w;
	          end
	        end else if (jump_dispatch_fire_w) begin
	          pending_jump_dispatched_q <= 1'b1;
	          pending_jump_target_q <= pending_jump_resolved_target_w;
	        end
      end else if (!direct_frontend_flush_w && pending_mem_resolve_ready_w) begin
        if (mem_dispatch_fire_w) begin
          pending_mem_dispatched_q <= 1'b1;
        end
      end else if (!direct_frontend_flush_w && system_csr_dispatch_fire_w) begin
        pending_system_dispatched_q <= 1'b1;
      end else if (!direct_frontend_flush_w && pending_system_csr_commit_w) begin
        stop_pending_q <= 1'b0;
        pending_exit_q <= 1'b0;
        pending_branch_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
        pending_mem_next_pc_q <= {`XLEN{1'b0}};
        pending_branch_next_pc_q <= {`XLEN{1'b0}};
        pending_jump_next_pc_q <= {`XLEN{1'b0}};
        branch_prefetch_active_q <= 1'b0;
        branch_prefetch_buffer_valid_q <= 1'b0;
        branch_prefetch_pc_q <= {`XLEN{1'b0}};
        if (pending_system_satp_write_commit_w) begin
          ras_count_q <= {RAS_COUNT_W{1'b0}};
          ras_reliable_q <= 1'b1;
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
          /* verilator lint_off BLKSEQ */
          for (branch_target_cache_reset_idx = 0;
               branch_target_cache_reset_idx < BRANCH_TARGET_CACHE_ENTRIES;
               branch_target_cache_reset_idx = branch_target_cache_reset_idx + 1) begin
            branch_target_cache_valid_q[branch_target_cache_reset_idx] = 1'b0;
          end
          for (jalr_btb_reset_idx = 0;
               jalr_btb_reset_idx < `BPU_BTB_ENTRIES;
               jalr_btb_reset_idx = jalr_btb_reset_idx + 1) begin
            jalr_btb_valid_q[jalr_btb_reset_idx] = 1'b0;
          end
          /* verilator lint_on BLKSEQ */
        end
        fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
        fifo_count_q <= {FETCH_COUNT_W{1'b0}};
        outstanding_valid_q <= 1'b0;
        outstanding_pc_q <= {`XLEN{1'b0}};
        discard_fetch_rsp_q <= outstanding_valid_q && !fetch_rsp_fire_w;
        next_fetch_pc_q <= pending_system_next_pc_q;
      end else if (!direct_frontend_flush_w && stop_pending_q && drain_complete_w) begin
        stop_pending_q <= 1'b0;
        pending_branch_q <= 1'b0;
        pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
        pending_system_dispatched_q <= 1'b0;
        pending_system_csr_q <= 1'b0;
        pending_system_ecall_q <= 1'b0;
        pending_system_mret_q <= 1'b0;
        pending_system_wfi_q <= 1'b0;
        pending_system_sfence_q <= 1'b0;
        pending_system_irq_q <= 1'b0;
        pending_mem_next_pc_q <= {`XLEN{1'b0}};
        pending_branch_next_pc_q <= {`XLEN{1'b0}};
        pending_jump_next_pc_q <= {`XLEN{1'b0}};
        if (pending_arch_trap_q) begin
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          branch_prefetch_active_q <= 1'b0;
          branch_prefetch_buffer_valid_q <= 1'b0;
          branch_prefetch_pc_q <= {`XLEN{1'b0}};
          next_fetch_pc_q <= csr_trap_target_w;
        end else if (pending_system_q) begin
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          branch_prefetch_active_q <= 1'b0;
          branch_prefetch_buffer_valid_q <= 1'b0;
          branch_prefetch_pc_q <= {`XLEN{1'b0}};
          // ECALL/中断在精确边界写 CSR 并跳 mtvec；MRET/WFI/SFENCE 则作为序列化控制提交。
          if (pending_system_ecall_q || pending_system_irq_q) begin
            next_fetch_pc_q <= csr_trap_target_w;
          end else if (pending_system_mret_q) begin
            next_fetch_pc_q <= csr_ret_target_w;
            ctrl_commit_valid_q <= 1'b1;
            ctrl_commit_pc_q <= pending_system_pc_q;
            ctrl_commit_inst_q <= pending_system_inst_q;
            ctrl_commit_next_pc_q <= csr_ret_target_w;
          end else begin
            next_fetch_pc_q <= pending_system_next_pc_q;
            ctrl_commit_valid_q <= 1'b1;
            ctrl_commit_pc_q <= pending_system_pc_q;
            ctrl_commit_inst_q <= pending_system_inst_q;
            ctrl_commit_next_pc_q <= pending_system_next_pc_q;
          end
        end else if (pending_branch_q && !pending_branch_dispatched_q) begin
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
          fifo_tail_q <= jalr_prefetch_hit_available_w ?
                         ptr_inc({FETCH_PACKET_COUNT_W{1'b0}}) :
                         {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= jalr_prefetch_hit_available_w ?
                          {{(FETCH_COUNT_W-1){1'b0}}, 1'b1} :
                          {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= jalr_prefetch_pending_match_w;
          outstanding_pc_q <= jalr_prefetch_pending_match_w ?
                              branch_prefetch_pc_q : {`XLEN{1'b0}};
          discard_fetch_rsp_q <= (!jalr_prefetch_pending_match_w &&
                                  outstanding_valid_q && !fetch_rsp_fire_w);
          branch_prefetch_active_q <= 1'b0;
          branch_prefetch_buffer_valid_q <= 1'b0;
          branch_prefetch_pc_q <= {`XLEN{1'b0}};
          if (jalr_prefetch_hit_available_w) begin
            fifo_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_pc0_w;
            fifo_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_pc1_w;
            fifo_next_pc0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_next_pc0_w;
            fifo_next_pc1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_next_pc1_w;
            fifo_packet_next_pc_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_packet_next_pc_w;
            fifo_inst0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_inst0_w;
            fifo_inst1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_inst1_w;
            fifo_resp0_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_resp0_w;
            fifo_resp1_q[{FETCH_PACKET_COUNT_W{1'b0}}] <=
                jalr_prefetch_hit_resp1_w;
            next_fetch_pc_q <= jalr_prefetch_hit_packet_next_pc_w;
          end else begin
            next_fetch_pc_q <= pending_jump_target_q;
          end
        end else if (pending_mem_q) begin
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          next_fetch_pc_q <= pending_mem_next_pc_q;
        end else if (pending_fp_q) begin
          fifo_head_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_tail_q <= {FETCH_PACKET_COUNT_W{1'b0}};
          fifo_count_q <= {FETCH_COUNT_W{1'b0}};
          outstanding_valid_q <= 1'b0;
          outstanding_pc_q <= {`XLEN{1'b0}};
          branch_prefetch_active_q <= 1'b0;
          branch_prefetch_buffer_valid_q <= 1'b0;
          branch_prefetch_pc_q <= {`XLEN{1'b0}};
          next_fetch_pc_q <= pending_fp_next_pc_q;
          if (!pending_fp_load_q && !pending_fp_store_q)
            fpr_q[pending_fp_rd_q] <= pending_fp_wdata_q;
          ctrl_commit_valid_q <= 1'b1;
          ctrl_commit_pc_q <= pending_fp_pc_q;
          ctrl_commit_inst_q <= pending_fp_inst_q;
          ctrl_commit_next_pc_q <= pending_fp_next_pc_q;
        end else if (pending_exit_q) begin
          halted_q <= 1'b1;
          exit_valid_q <= 1'b1;
          exit_is_ecall_q <= pending_exit_is_ecall_q;
          exit_is_ebreak_q <= pending_exit_is_ebreak_q;
        end else begin
          halted_q <= 1'b1;
          trap_valid_q <= 1'b1;
          trap_cause_q <= pending_trap_cause_q;
          trap_pc_q <= pending_trap_pc_q;
          trap_tval_q <= pending_trap_tval_q;
        end
      end else if (!direct_frontend_flush_w && can_run_w && fifo_has_packet_w) begin
        if (csr_irq_pending_w) begin
          // 中断在下一条指令边界进入 SYSTEM drain；mepc 指向尚未执行的 head PC。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b1;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b1;
          pending_system_pc_q <= head_pc_w;
          pending_system_inst_q <= {`INST_W{1'b0}};
          pending_system_next_pc_q <= head_pc_w;
          pending_system_csr_rdata_q <= {`XLEN{1'b0}};
          pending_system_irq_cause_q <= csr_irq_cause_w;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
        end else if (head_fetch_fault0_w) begin
          // 先冻结前端，等已派发的更老指令全部退休后再报 trap，保持精确异常边界。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b1;
        pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
          pending_trap_cause_q <= (head_resp0_w == 2'b10) ?
                                  `EXC_INST_PAGE_FAULT :
                                  `EXC_INST_ACCESS_FAULT;
          pending_trap_pc_q <= head_pc_w;
          pending_trap_tval_q <= head_pc_w;
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
        end else if (dispatch0_arch_trap_w) begin
          // OpenSBI semihosting probe uses a magic ebreak sequence and expects
          // the architectural breakpoint trap; plain ebreak remains AM halt.
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b1;
        pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          pending_trap_cause_q <= `EXC_BREAKPOINT;
          pending_trap_pc_q <= head_pc_w;
          pending_trap_tval_q <= {`XLEN{1'b0}};
        end else if (dispatch0_exit_w) begin
          // EBREAK 保留为实验壳退出边界；ECALL 改走架构 trap 以承接 Linux/SBI。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b1;
          pending_exit_is_ecall_q <= dispatch0_ecall_w;
          pending_exit_is_ebreak_q <= dispatch0_ebreak_w;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
        end else if (dispatch0_fp_w) begin
          // F/D bring-up path: FP load/store 是序列化边界，先排空整数 OoO 后端，
          // 再通过同一 LSU/MMU 通路访问内存并提交 FPR 副作用。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
          pending_jump_q <= 1'b0;
          pending_jump_dispatched_q <= 1'b0;
          pending_mem_q <= 1'b0;
          pending_mem_dispatched_q <= 1'b0;
          pending_fp_q <= 1'b1;
          pending_fp_mem_pending_q <= 1'b0;
          pending_fp_mem_done_q <= head0_fp_move_to_fpr_raw_w;
          pending_fp_load_q <= head0_fp_load_raw_w;
          pending_fp_store_q <= head0_fp_store_raw_w;
          pending_fp_double_q <= head0_fp_double_w;
          pending_arch_trap_q <= 1'b0;
          pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          pending_fp_pc_q <= head_pc_w;
          pending_fp_inst_q <= head_inst0_w;
          pending_fp_next_pc_q <= head_next_pc0_w;
          pending_fp_addr_q <= head0_fp_addr_w;
          pending_fp_wdata_q <= head0_fp_move_to_fpr_raw_w ?
                                head0_fp_move_value_w :
                                fp_store_wdata(head0_fp_addr_w,
                                               head0_fp_store_value_w,
                                               head0_fp_double_w);
          pending_fp_wstrb_q <= fp_store_wstrb(head0_fp_addr_w,
                                               head0_fp_double_w);
          pending_fp_rd_q <= head_inst0_w[11:7];
        end else if (dispatch0_system_w && head0_csr_illegal_w) begin
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b1;
        pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_next_pc_q <= {`XLEN{1'b0}};
          pending_jump_next_pc_q <= {`XLEN{1'b0}};
          pending_trap_cause_q <= `EXC_ILLEGAL_INST;
          pending_trap_pc_q <= head_pc_w;
          pending_trap_tval_q <= head_inst0_w;
        end else if (dispatch0_system_w) begin
          // SYSTEM/CSR 是特权控制面边界：先等更老 ROB 项全部退休，再执行副作用或单 lane CSR。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b0;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b1;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= head0_csr_raw_w;
          pending_system_ecall_q <= head0_ecall_raw_w;
          pending_system_mret_q <= head0_xret_raw_w;
          pending_system_wfi_q <= head0_wfi_raw_w;
          pending_system_sfence_q <= head0_sfence_raw_w;
          pending_system_irq_q <= 1'b0;
          pending_system_pc_q <= head_pc_w;
          pending_system_inst_q <= head_inst0_w;
          pending_system_next_pc_q <= head_next_pc0_w;
          pending_system_csr_rdata_q <= csr_rdata_w;
          pending_system_irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
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
          pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
          pending_mem_next_pc_q <= {`XLEN{1'b0}};
          pending_branch_pc_q <= head_pc_w;
          pending_branch_next_pc_q <= head_next_pc0_w;
          pending_branch_inst_q <= head_inst0_w;
          pending_branch_rs1_q <= head0_rs1_w;
          pending_branch_rs2_q <= head0_rs2_w;
          pending_branch_imm_q <= head0_imm_w;
          pending_branch_cmp_op_q <=
              head0_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
          pending_branch_pred_taken_q <= head0_branch_pred_taken_w;
          pending_branch_bht_valid_q <= head0_branch_bht_valid_w;
          pending_branch_bht_idx_q <= head0_branch_bht_idx_w;
        end else if ((dispatch0_jal_w && !direct_jal0_dispatch_valid_w) ||
                     (dispatch0_jump_w && !dispatch0_return_w)) begin
          // 函数调用 JAL 和 JALR 都是精确控制流边界：先排空更老项，
          // 再单 lane 派发 jump uop，避免 caller fall-through 混入 callee ROB。
          stop_pending_q <= 1'b1;
          pending_exit_q <= 1'b0;
          pending_branch_q <= 1'b0;
          pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= 1'b1;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= 1'b0;
        pending_mem_dispatched_q <= 1'b0;
        pending_arch_trap_q <= 1'b0;
        pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
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
          pending_exit_q <= head1_exit_raw_w;
          pending_exit_is_ecall_q <= head1_ecall_raw_w;
          pending_exit_is_ebreak_q <= head1_ebreak_raw_w;
          pending_branch_q <= head1_branch_raw_w;
          pending_branch_dispatched_q <= 1'b0;
        pending_jump_q <= head1_jump_raw_w;
        pending_jump_dispatched_q <= 1'b0;
        pending_mem_q <= head1_mem_raw_w;
        pending_mem_dispatched_q <= 1'b0;
        pending_fp_q <= head1_fp_raw_w;
        pending_fp_mem_pending_q <= 1'b0;
        pending_fp_mem_done_q <= head1_fp_move_to_fpr_raw_w;
        pending_fp_load_q <= head1_fp_load_raw_w;
        pending_fp_store_q <= head1_fp_store_raw_w;
        pending_fp_double_q <= head1_fp_double_w;
          pending_arch_trap_q <= head_fetch_fault1_w || head1_csr_illegal_w ||
                                 head1_arch_trap_raw_w;
        pending_system_q <= head1_system_raw_w && !head1_csr_illegal_w;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= head1_csr_raw_w && !head1_csr_illegal_w;
          pending_system_ecall_q <= head1_ecall_raw_w;
          pending_system_mret_q <= head1_xret_raw_w;
          pending_system_wfi_q <= head1_wfi_raw_w;
          pending_system_sfence_q <= head1_sfence_raw_w;
          pending_system_irq_q <= 1'b0;
          pending_system_pc_q <= head_pc1_w;
          pending_system_inst_q <= head_inst1_w;
          pending_system_next_pc_q <= head_next_pc1_w;
          pending_system_csr_rdata_q <= csr_rdata_w;
          pending_system_irq_cause_q <= {`TRAP_CAUSE_W{1'b0}};
          pending_trap_cause_q <= head1_arch_trap_raw_w ? `EXC_BREAKPOINT :
                                  head1_csr_illegal_w ? `EXC_ILLEGAL_INST :
                                  ((head_resp1_w == 2'b10) ?
                                   `EXC_INST_PAGE_FAULT :
                                   `EXC_INST_ACCESS_FAULT);
          pending_trap_pc_q <= head_pc1_w;
          pending_trap_tval_q <= head1_arch_trap_raw_w ? {`XLEN{1'b0}} :
                                 head1_csr_illegal_w ? head_inst1_w :
                                 head_pc1_w;

          pending_branch_pc_q <= head_pc1_w;
          pending_branch_next_pc_q <= head_next_pc1_w;
          pending_branch_inst_q <= head_inst1_w;
          pending_branch_rs1_q <= head1_rs1_w;
          pending_branch_rs2_q <= head1_rs2_w;
          pending_branch_imm_q <= head1_imm_w;
          pending_branch_cmp_op_q <=
              head1_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
          pending_branch_pred_taken_q <= head1_branch_pred_taken_w;
          pending_branch_bht_valid_q <= head1_branch_bht_valid_w;
          pending_branch_bht_idx_q <= head1_branch_bht_idx_w;

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
          pending_fp_pc_q <= head_pc1_w;
          pending_fp_inst_q <= head_inst1_w;
          pending_fp_next_pc_q <= head_next_pc1_w;
          pending_fp_addr_q <= head1_fp_addr_w;
          pending_fp_wdata_q <= head1_fp_move_to_fpr_raw_w ?
                                head1_fp_move_value_w :
                                fp_store_wdata(head1_fp_addr_w,
                                               head1_fp_store_value_w,
                                               head1_fp_double_w);
          pending_fp_wstrb_q <= fp_store_wstrb(head1_fp_addr_w,
                                               head1_fp_double_w);
          pending_fp_rd_q <= head_inst1_w[11:7];
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
        pending_arch_trap_q <= 1'b1;
        pending_system_q <= 1'b0;
          pending_system_dispatched_q <= 1'b0;
          pending_system_csr_q <= 1'b0;
          pending_system_ecall_q <= 1'b0;
          pending_system_mret_q <= 1'b0;
          pending_system_wfi_q <= 1'b0;
          pending_system_sfence_q <= 1'b0;
          pending_system_irq_q <= 1'b0;
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
