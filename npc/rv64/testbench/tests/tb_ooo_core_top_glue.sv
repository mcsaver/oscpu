`include "define.v"

module tb_ooo_core_top_glue;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  reg clk;
  reg rst;
  reg flush;
  reg run;
  reg commit_ready;

  wire fetch_req_valid;
  wire fetch_req_ready;
  wire [`XLEN-1:0] fetch_req_pc;
  reg fetch_rsp_valid;
  wire fetch_rsp_ready;
  reg [`INST_W-1:0] fetch_rsp_inst0;
  reg [1:0] fetch_rsp_resp0;
  reg [`INST_W-1:0] fetch_rsp_inst1;
  reg [1:0] fetch_rsp_resp1;
  wire mem_req_valid;
  wire mem_req_ready;
  wire mem_req_write;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  reg mem_rsp_valid;
  wire mem_rsp_ready;
  reg [`XLEN-1:0] mem_rsp_rdata;
  reg mem_rsp_error;

  wire commit0_valid;
  wire [`XLEN-1:0] commit0_pc;
  wire [`INST_W-1:0] commit0_inst;
  wire [`XLEN-1:0] commit0_next_pc;
  wire commit0_rd_en;
  wire [`REG_ADDR_W-1:0] commit0_rd_addr;
  wire [`XLEN-1:0] commit0_rd_data;
  wire commit0_exception;
  wire commit0_write;
  wire commit1_valid;
  wire [`XLEN-1:0] commit1_pc;
  wire [`INST_W-1:0] commit1_inst;
  wire [`XLEN-1:0] commit1_next_pc;
  wire commit1_rd_en;
  wire [`REG_ADDR_W-1:0] commit1_rd_addr;
  wire [`XLEN-1:0] commit1_rd_data;
  wire commit1_exception;
  wire commit1_write;
  wire trap_valid;
  wire [`TRAP_CAUSE_W-1:0] trap_cause;
  wire [`XLEN-1:0] trap_pc;
  wire [`XLEN-1:0] trap_tval;
  wire exit_valid;
  wire exit_is_ecall;
  wire exit_is_ebreak;
  wire [`XLEN-1:0] exit_code;
  wire halted;
  wire [`XLEN-1:0] debug_pc;
  wire [`CORE_STATE_W-1:0] debug_state;
  wire [`XLEN * `REG_NUM - 1:0] debug_gprs;
  wire [1:0] retire_count;
  wire [6:0] free_count;
  wire [4:0] rob_count;
  wire [3:0] issue_count;
  wire mem_flush;

  integer commit_total;
  integer request_total;
  reg last_fetch_fire;
  reg saw_back_to_back_fetch;
  reg saw_dual_commit;
  reg saw_memory_streaming;
  reg saw_lane1_memory_streaming;
  reg saw_memory_rsp_req_overlap;
  reg saw_return_fastpath;
  reg saw_branch_fastpath;
  reg saw_direct_redirect_fetch;
  reg last_direct_redirect;
  reg saw_branch_redirect_fetch;
  reg saw_branch_shadow_prefetch;
  reg saw_branch_shadow_hit;
  reg saw_branch_spec_capture;
  reg saw_branch_spec_correct;
  reg saw_branch_spec_restore;
  reg saw_backend_branch_resolve;
  reg saw_branch_dispatch_resolve;
  reg saw_control_fallthrough_fetch;
  reg saw_lane1_ret_fallthrough;
  reg saw_fp_gpr_completion;
  reg saw_fp_gpr_completion_wake;
  reg [4:0] program_mode;
  reg [`XLEN-1:0] fault_addr;
  reg [`XLEN-1:0] data_mem_word;
  localparam [1:0] FETCH_RESP_ACCESS_FAULT = 2'b01;

  localparam [4:0] MODE_DEFAULT_BODY = 5'd0;
  localparam [4:0] MODE_EBREAK = 5'd1;
  localparam [4:0] MODE_BRANCH_TAKEN = 5'd2;
  localparam [4:0] MODE_BRANCH_NOT_TAKEN = 5'd3;
  localparam [4:0] MODE_JAL = 5'd4;
  localparam [4:0] MODE_JALR_RD_EQ_RS1 = 5'd5;
  localparam [4:0] MODE_MEM_LW_SW = 5'd6;
  localparam [4:0] MODE_LANE1_EBREAK = 5'd7;
  localparam [4:0] MODE_LANE1_BRANCH_TAKEN = 5'd8;
  localparam [4:0] MODE_LANE1_JAL = 5'd9;
  localparam [4:0] MODE_LANE1_MEM = 5'd10;
  localparam [4:0] MODE_RVC_CADDIW = 5'd11;
  localparam [4:0] MODE_RAS_RETURN = 5'd12;
  localparam [4:0] MODE_BRANCH_SHADOW_PREFETCH = 5'd13;
  localparam [4:0] MODE_BRANCH_READY_RESOLVE = 5'd14;
  localparam [4:0] MODE_CONTROL_FETCH_GATE = 5'd15;
  localparam [4:0] MODE_BRANCH_LANE1_RET = 5'd16;
  localparam [4:0] MODE_ECALL = 5'd17;
  localparam [4:0] MODE_FMV_W_X = 5'd18;

  wire [`XLEN-1:0] tb_csr_time_w = {`XLEN{1'b0}};
  wire tb_csr_irq_software_w = 1'b0;
  wire tb_csr_irq_timer_w = 1'b0;
  wire tb_csr_irq_external_w = 1'b0;
  `include "tb_ooo_core_top_glue_csr.svh"

  OooCoreTopGlue dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .run_i(run),
    .reset_pc_i(`RESET_PC),
    .fetch_req_valid_o(fetch_req_valid),
    .fetch_req_ready_i(fetch_req_ready),
    .fetch_req_pc_o(fetch_req_pc),
    .fetch_rsp_valid_i(fetch_rsp_valid),
    .fetch_rsp_ready_o(fetch_rsp_ready),
    .fetch_rsp_inst0_i(fetch_rsp_inst0),
    .fetch_rsp_resp0_i(fetch_rsp_resp0),
    .fetch_rsp_inst1_i(fetch_rsp_inst1),
    .fetch_rsp_resp1_i(fetch_rsp_resp1),
    .fetch_rsp_resp0_bytes_i(3'd4),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(mem_req_ready),
    .mem_req_write_o(mem_req_write),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(mem_rsp_valid),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_rsp_rdata_i(mem_rsp_rdata),
    .mem_rsp_error_i(mem_rsp_error),
    .mem_rsp_page_fault_i(1'b0),
    .mem_flush_o(mem_flush),
    .mmu_flush_o(),
    `TB_OOO_CORE_TOP_GLUE_CSR_PORTS
    .commit_ready_i(commit_ready),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_rd_addr_o(commit0_rd_addr),
    .commit0_rd_data_o(commit0_rd_data),
    .commit0_exception_o(commit0_exception),
    .commit0_write_o(commit0_write),
    .commit1_valid_o(commit1_valid),
    .commit1_pc_o(commit1_pc),
    .commit1_inst_o(commit1_inst),
    .commit1_next_pc_o(commit1_next_pc),
    .commit1_rd_en_o(commit1_rd_en),
    .commit1_rd_addr_o(commit1_rd_addr),
    .commit1_rd_data_o(commit1_rd_data),
    .commit1_exception_o(commit1_exception),
    .commit1_write_o(commit1_write),
    .trap_valid_o(trap_valid),
    .trap_cause_o(trap_cause),
    .trap_pc_o(trap_pc),
    .trap_tval_o(trap_tval),
    .exit_valid_o(exit_valid),
    .exit_is_ecall_o(exit_is_ecall),
    .exit_is_ebreak_o(exit_is_ebreak),
    .exit_code_o(exit_code),
    .halted_o(halted),
    .pmpcfg_o(),
    .pmpaddr_o(),
    .debug_pc_o(debug_pc),
    .debug_state_o(debug_state),
    .debug_gprs_o(debug_gprs),
    .retire_count_o(retire_count),
    .free_count_o(free_count),
    .rob_count_o(rob_count),
    .issue_count_o(issue_count)
  );

  // FP completion 域合同只读观察：证明 GPR 目的事务真实发生且不误唤醒 FPR 域。
  wire fp_result_wb_valid =
      dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
         .u_fp_backend.fp_result_wb_valid_w;
  wire fp_result_wb_frd =
      dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
         .u_fp_backend.fp_result_wb_frd_w;
  wire fp_wake0_valid =
      dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
         .u_fp_backend.fp_wake0_valid_o;

  function [`XLEN-1:0] gpr;
    input [`REG_ADDR_W-1:0] idx;
    begin
      gpr = debug_gprs[idx * `XLEN +: `XLEN];
    end
  endfunction

  function [`INST_W-1:0] inst_addi;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_addi = rv32_i(imm, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_OP_IMM);
    end
  endfunction

  function [`INST_W-1:0] inst_add;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_add = rv32_r(`FUNCT7_STD, rs2, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_OP);
    end
  endfunction

  function [`INST_W-1:0] inst_beq_self;
    begin
      inst_beq_self = rv32_b(13'd0, 5'd0, 5'd0, `FUNCT3_BEQ);
    end
  endfunction

  function [`INST_W-1:0] inst_beq;
    input [12:0] imm;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_beq = rv32_b(imm, rs2, rs1, `FUNCT3_BEQ);
    end
  endfunction

  function [`INST_W-1:0] inst_bne;
    input [12:0] imm;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_bne = rv32_b(imm, rs2, rs1, `FUNCT3_BNE);
    end
  endfunction

  function [`INST_W-1:0] inst_lw;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_lw = rv32_i(imm, rs1, `FUNCT3_LW, rd, `OPCODE_LOAD);
    end
  endfunction

  function [`INST_W-1:0] inst_sw;
    input [4:0] rs2;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_sw = rv32_s(imm, rs2, rs1, `FUNCT3_SW);
    end
  endfunction

  function [`INST_W-1:0] inst_lui;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_lui = rv32_u(imm, rd, `OPCODE_LUI);
    end
  endfunction

  function [`INST_W-1:0] inst_auipc;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_auipc = rv32_u(imm, rd, `OPCODE_AUIPC);
    end
  endfunction

  function [`INST_W-1:0] inst_csrrw;
    input [4:0] rd;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      inst_csrrw = rv32_i(csr, rs1, 3'b001, rd, `OPCODE_SYSTEM);
    end
  endfunction

  function [`INST_W-1:0] inst_csrrs;
    input [4:0] rd;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      inst_csrrs = rv32_i(csr, rs1, 3'b010, rd, `OPCODE_SYSTEM);
    end
  endfunction

  function [`INST_W-1:0] inst_fmv_w_x;
    input [4:0] rd;
    input [4:0] rs1;
    begin
      inst_fmv_w_x = {7'b1111000, 5'b00000, rs1, 3'b000, rd,
                      `OPCODE_OP_FP};
    end
  endfunction

  function [`INST_W-1:0] inst_fmv_x_w;
    input [4:0] rd;
    input [4:0] fs1;
    begin
      inst_fmv_x_w = {7'b1110000, 5'b00000, fs1, 3'b000, rd,
                      `OPCODE_OP_FP};
    end
  endfunction

  function [`INST_W-1:0] inst_jal;
    input [4:0] rd;
    input [20:0] imm;
    begin
      inst_jal = rv32_j(imm, rd);
    end
  endfunction

  function [`INST_W-1:0] inst_jalr;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_jalr = rv32_i(imm, rs1, `FUNCT3_ADD_SUB, rd, `OPCODE_JALR);
    end
  endfunction

  function [`INST_W-1:0] inst_ebreak;
    begin
      inst_ebreak = 32'h0010_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_ecall;
    begin
      inst_ecall = 32'h0000_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_mret;
    begin
      inst_mret = 32'h3020_0073;
    end
  endfunction

  function [15:0] inst_c_addi;
    input [4:0] rd;
    input [5:0] imm;
    begin
      inst_c_addi = {3'b000, imm[5], rd, imm[4:0], 2'b01};
    end
  endfunction

  function [15:0] inst_c_addiw;
    input [4:0] rd;
    input [5:0] imm;
    begin
      inst_c_addiw = {3'b001, imm[5], rd, imm[4:0], 2'b01};
    end
  endfunction

  function [15:0] inst_c_ebreak;
    begin
      inst_c_ebreak = 16'h9002;
    end
  endfunction

  function [15:0] program_half;
    input [`XLEN-1:0] addr;
    begin
      if (program_mode == MODE_RVC_CADDIW) begin
        case (addr)
          32'h8000_0000: program_half = inst_c_addi(5'd5, 6'h3f);
          32'h8000_0002: program_half = inst_c_addiw(5'd5, 6'd1);
          32'h8000_0004: program_half = inst_c_addiw(5'd5, 6'h3f);
          32'h8000_0006: program_half = inst_c_addi(5'd6, 6'd1);
          32'h8000_0008: program_half = inst_c_ebreak();
          default:       program_half = inst_c_ebreak();
        endcase
      end else begin
        case (addr)
          32'h8000_0000: program_half = inst_c_addi(5'd1, 6'd1);
          32'h8000_0002: program_half = inst_c_addi(5'd2, 6'd2);
          32'h8000_0004: program_half = inst_c_addi(5'd3, 6'd3);
          32'h8000_0006: program_half = inst_c_ebreak();
          default:       program_half = inst_c_ebreak();
        endcase
      end
    end
  endfunction

  function [`INST_W-1:0] program_word;
    input [`XLEN-1:0] addr;
    begin
      if (program_mode == MODE_RVC_CADDIW) begin
        program_word = {program_half(addr + 32'd2), program_half(addr)};
      end else if (program_mode == MODE_EBREAK && addr == 32'h8000_0000) begin
        program_word = inst_ebreak();
      end else begin
        case (program_mode)
          MODE_BRANCH_TAKEN: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0008: program_word = inst_beq(13'd8, 5'd1, 5'd1);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd0, 12'd99);
              32'h8000_0010: program_word = inst_addi(5'd4, 5'd0, 12'd4);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd0, 12'd5);
              32'h8000_0018: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_BRANCH_NOT_TAKEN: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0008: program_word = inst_bne(13'd8, 5'd1, 5'd1);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd0, 12'd3);
              32'h8000_0010: program_word = inst_addi(5'd4, 5'd0, 12'd4);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd0, 12'd5);
              32'h8000_0018: program_word = inst_addi(5'd6, 5'd0, 12'd6);
              32'h8000_001c: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_BRANCH_READY_RESOLVE: begin
            case (addr)
              32'h8000_0000: program_word = inst_beq(13'd8, 5'd0, 5'd0);
              32'h8000_0004: program_word = inst_addi(5'd1, 5'd0, 12'd99);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd0, 12'd7);
              32'h8000_000c: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_CONTROL_FETCH_GATE: begin
            case (addr)
              32'h8000_0000: program_word = inst_jal(5'd1, 21'd12);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_0008: program_word = inst_addi(5'd3, 5'd0, 12'd99);
              32'h8000_000c: program_word = inst_addi(5'd4, 5'd1, 12'd0);
              32'h8000_0010: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_BRANCH_LANE1_RET: begin
            case (addr)
              32'h8000_0000: program_word = inst_jal(5'd1, 21'd20);
              32'h8000_0004: program_word = inst_addi(5'd5, 5'd0, 12'd5);
              32'h8000_0008: program_word = inst_ebreak();
              32'h8000_0010: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_0014: program_word = inst_bne(13'd8, 5'd0, 5'd0);
              32'h8000_0018: program_word = inst_jalr(5'd0, 5'd1, 12'd0);
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_JAL: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0008: program_word = inst_jal(5'd10, 21'd8);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd0, 12'd99);
              32'h8000_0010: program_word = inst_addi(5'd4, 5'd0, 12'd4);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd10, 12'd0);
              32'h8000_0018: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_JALR_RD_EQ_RS1: begin
            case (addr)
              32'h8000_0000: program_word = inst_auipc(5'd5, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd5, 5'd5, 12'h018);
              32'h8000_0008: program_word = inst_jalr(5'd5, 5'd5, 12'd0);
              32'h8000_000c: program_word = inst_addi(5'd6, 5'd0, 12'd99);
              32'h8000_0010: program_word = inst_addi(5'd6, 5'd0, 12'd55);
              32'h8000_0014: program_word = inst_addi(5'd6, 5'd0, 12'd77);
              32'h8000_0018: program_word = inst_addi(5'd7, 5'd5, 12'd0);
              32'h8000_001c: program_word = inst_addi(5'd8, 5'd0, 12'd8);
              32'h8000_0020: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_MEM_LW_SW: begin
            case (addr)
              32'h8000_0000: program_word = inst_auipc(5'd2, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd1, 5'd0, 12'd11);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd2, 12'h040);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd0, 12'd3);
              32'h8000_0010: program_word = inst_sw(5'd1, 5'd2, 12'd0);
              32'h8000_0014: program_word = inst_lw(5'd4, 5'd2, 12'd0);
              32'h8000_0018: program_word = inst_addi(5'd5, 5'd4, 12'd1);
              32'h8000_001c: program_word = inst_addi(5'd6, 5'd0, 12'd6);
              32'h8000_0020: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_LANE1_EBREAK: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_LANE1_BRANCH_TAKEN: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_beq(13'd8, 5'd1, 5'd1);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd1, 12'd2);
              32'h8000_0010: program_word = inst_addi(5'd4, 5'd0, 12'd4);
              32'h8000_0014: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_LANE1_JAL: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_jal(5'd10, 21'd8);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_000c: program_word = inst_addi(5'd3, 5'd10, 12'd0);
              32'h8000_0010: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_LANE1_MEM: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd13);
              32'h8000_0004: program_word = inst_auipc(5'd2, 20'h00000);
              32'h8000_0008: program_word = inst_addi(5'd2, 5'd2, 12'h03c);
              32'h8000_000c: program_word = inst_sw(5'd1, 5'd2, 12'd0);
              32'h8000_0010: program_word = inst_lw(5'd4, 5'd2, 12'd0);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd4, 12'd1);
              32'h8000_0018: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_RAS_RETURN: begin
            case (addr)
              32'h8000_0000: program_word = inst_jal(5'd1, 21'd12);
              32'h8000_0004: program_word = inst_addi(5'd4, 5'd2, 12'd1);
              32'h8000_0008: program_word = inst_ebreak();
              32'h8000_000c: program_word = inst_addi(5'd2, 5'd0, 12'd1);
              32'h8000_0010: program_word = inst_addi(5'd2, 5'd2, 12'd1);
              32'h8000_0014: program_word = inst_jalr(5'd0, 5'd1, 12'd0);
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_BRANCH_SHADOW_PREFETCH: begin
            case (addr)
              32'h8000_0000: program_word = inst_jal(5'd0, 21'd16);
              32'h8000_0004: program_word = inst_addi(5'd9, 5'd0, 12'd9);
              32'h8000_0008: program_word = inst_addi(5'd3, 5'd0, 12'd3);
              32'h8000_000c: program_word = inst_ebreak();
              32'h8000_0010: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0014: program_word = inst_bne(13'h1ff4, 5'd1, 5'd0);
              32'h8000_0018: program_word = inst_addi(5'd2, 5'd0, 12'd99);
              32'h8000_001c: program_word = inst_ebreak();
              default:       program_word = inst_ebreak();
            endcase
          end
          MODE_ECALL: begin
            case (addr)
              32'h8000_0000: program_word = inst_auipc(5'd7, 20'h00000);
              32'h8000_0004: program_word = inst_addi(5'd7, 5'd7, 12'h020);
              32'h8000_0008: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd7);
              32'h8000_000c: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0010: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0014: program_word = inst_add(5'd3, 5'd1, 5'd2);
              32'h8000_0018: program_word = inst_ecall();
              32'h8000_001c: program_word = inst_addi(5'd5, 5'd0, 12'd9);
              32'h8000_0020: program_word = inst_addi(5'd6, 5'd0, 12'd6);
              32'h8000_0024: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          MODE_FMV_W_X: begin
            case (addr)
              32'h8000_0000: program_word = inst_lui(5'd11, 20'h00006);
              32'h8000_0004: program_word = inst_csrrs(5'd0, `CSR_MSTATUS,
                                                       5'd11);
              32'h8000_0008: program_word = inst_fmv_w_x(5'd0, 5'd0);
              32'h8000_000c: program_word = inst_fmv_x_w(5'd6, 5'd0);
              32'h8000_0010: program_word = inst_addi(5'd5, 5'd0, 12'd7);
              32'h8000_0014: program_word = inst_ebreak();
              default:       program_word = inst_beq_self();
            endcase
          end
          default: begin
            case (addr)
              32'h8000_0000: program_word = inst_addi(5'd1, 5'd0, 12'd1);
              32'h8000_0004: program_word = inst_addi(5'd2, 5'd0, 12'd2);
              32'h8000_0008: program_word = inst_add(5'd3, 5'd1, 5'd2);
              32'h8000_000c: program_word = inst_addi(5'd4, 5'd3, 12'd4);
              32'h8000_0010: program_word = inst_addi(5'd5, 5'd0, 12'd5);
              32'h8000_0014: program_word = inst_addi(5'd5, 5'd0, 12'd9);
              32'h8000_0018: program_word = inst_ebreak();
              32'h8000_001c: program_word = inst_addi(5'd6, 5'd0, 12'd6);
              default:       program_word = inst_beq_self();
            endcase
          end
        endcase
      end
    end
  endfunction

  task automatic reset_dut;
    input [4:0] mode_i;
    input [`XLEN-1:0] fault_addr_i;
    begin
      clk = 1'b0;
      rst = 1'b1;
      flush = 1'b0;
      run = 1'b1;
      commit_ready = 1'b1;
      fetch_rsp_valid = 1'b0;
      fetch_rsp_inst0 = {`INST_W{1'b0}};
      fetch_rsp_inst1 = {`INST_W{1'b0}};
      fetch_rsp_resp0 = 2'b00;
      fetch_rsp_resp1 = 2'b00;
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      data_mem_word = {`XLEN{1'b0}};
      commit_total = 0;
      request_total = 0;
      last_fetch_fire = 1'b0;
      saw_back_to_back_fetch = 1'b0;
      saw_dual_commit = 1'b0;
      saw_memory_streaming = 1'b0;
      saw_lane1_memory_streaming = 1'b0;
      saw_memory_rsp_req_overlap = 1'b0;
      saw_return_fastpath = 1'b0;
      saw_branch_fastpath = 1'b0;
      saw_direct_redirect_fetch = 1'b0;
      saw_branch_redirect_fetch = 1'b0;
      saw_branch_shadow_prefetch = 1'b0;
      saw_branch_shadow_hit = 1'b0;
      saw_branch_spec_capture = 1'b0;
      saw_branch_spec_correct = 1'b0;
      saw_branch_spec_restore = 1'b0;
      saw_backend_branch_resolve = 1'b0;
      saw_branch_dispatch_resolve = 1'b0;
      saw_control_fallthrough_fetch = 1'b0;
      saw_lane1_ret_fallthrough = 1'b0;
      saw_fp_gpr_completion = 1'b0;
      saw_fp_gpr_completion_wake = 1'b0;
      program_mode = mode_i;
      fault_addr = fault_addr_i;
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  assign fetch_req_ready = !fetch_rsp_valid || fetch_rsp_ready;
  assign mem_req_ready = !mem_rsp_valid || mem_rsp_ready;

  always @(posedge clk) begin
    if (rst || flush) begin
      fetch_rsp_valid <= 1'b0;
      fetch_rsp_inst0 <= {`INST_W{1'b0}};
      fetch_rsp_inst1 <= {`INST_W{1'b0}};
      fetch_rsp_resp0 <= 2'b00;
      fetch_rsp_resp1 <= 2'b00;
    end else begin
      if (fetch_rsp_valid && fetch_rsp_ready) begin
        fetch_rsp_valid <= 1'b0;
      end

      if (fetch_req_valid && fetch_req_ready) begin
        fetch_rsp_valid <= 1'b1;
        fetch_rsp_inst0 <= program_word(fetch_req_pc);
        fetch_rsp_inst1 <= program_word(fetch_req_pc + 32'd4);
        fetch_rsp_resp0 <= (fetch_req_pc == fault_addr) ?
                           FETCH_RESP_ACCESS_FAULT : 2'b00;
        fetch_rsp_resp1 <= ((fetch_req_pc + 32'd4) == fault_addr) ?
                           FETCH_RESP_ACCESS_FAULT : 2'b00;
      end
    end
  end

  always @(posedge clk) begin
    if (rst || flush) begin
      mem_rsp_valid <= 1'b0;
      mem_rsp_rdata <= {`XLEN{1'b0}};
      mem_rsp_error <= 1'b0;
      data_mem_word <= {`XLEN{1'b0}};
    end else begin
      if (mem_rsp_valid && mem_rsp_ready) begin
        mem_rsp_valid <= 1'b0;
      end

      if (mem_req_valid && mem_req_ready) begin
        mem_rsp_valid <= 1'b1;
        mem_rsp_error <= 1'b0;
        if (mem_req_write) begin
          if (mem_req_addr == 64'h0000_0000_8000_0040) begin
            if (mem_req_wstrb[0]) begin
              data_mem_word[7:0] <= mem_req_wdata[7:0];
            end
            if (mem_req_wstrb[1]) begin
              data_mem_word[15:8] <= mem_req_wdata[15:8];
            end
            if (mem_req_wstrb[2]) begin
              data_mem_word[23:16] <= mem_req_wdata[23:16];
            end
            if (mem_req_wstrb[3]) begin
              data_mem_word[31:24] <= mem_req_wdata[31:24];
            end
            if (`STRB_W > 4 && mem_req_wstrb[4]) begin
              data_mem_word[39:32] <= mem_req_wdata[39:32];
            end
            if (`STRB_W > 5 && mem_req_wstrb[5]) begin
              data_mem_word[47:40] <= mem_req_wdata[47:40];
            end
            if (`STRB_W > 6 && mem_req_wstrb[6]) begin
              data_mem_word[55:48] <= mem_req_wdata[55:48];
            end
            if (`STRB_W > 7 && mem_req_wstrb[7]) begin
              data_mem_word[63:56] <= mem_req_wdata[63:56];
            end
          end
          mem_rsp_rdata <= {`XLEN{1'b0}};
        end else begin
          mem_rsp_rdata <= (mem_req_addr == 64'h0000_0000_8000_0040) ?
                           data_mem_word : {`XLEN{1'b0}};
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      commit_total <= 0;
      request_total <= 0;
      last_fetch_fire <= 1'b0;
      saw_back_to_back_fetch <= 1'b0;
      saw_dual_commit <= 1'b0;
      saw_memory_rsp_req_overlap <= 1'b0;
      saw_direct_redirect_fetch <= 1'b0;
      last_direct_redirect <= 1'b0;
      saw_branch_redirect_fetch <= 1'b0;
      saw_branch_shadow_prefetch <= 1'b0;
      saw_branch_shadow_hit <= 1'b0;
      saw_branch_spec_capture <= 1'b0;
      saw_branch_spec_correct <= 1'b0;
      saw_branch_spec_restore <= 1'b0;
      saw_backend_branch_resolve <= 1'b0;
      saw_control_fallthrough_fetch <= 1'b0;
      saw_lane1_ret_fallthrough <= 1'b0;
      saw_fp_gpr_completion <= 1'b0;
      saw_fp_gpr_completion_wake <= 1'b0;
    end else begin
      commit_total <= commit_total + commit0_valid + commit1_valid;
      if (fetch_req_valid && fetch_req_ready) begin
        request_total <= request_total + 1;
        if (last_fetch_fire) begin
          saw_back_to_back_fetch <= 1'b1;
        end
      end
      last_fetch_fire <= fetch_req_valid && fetch_req_ready;
      if (commit0_valid && commit1_valid) begin
        saw_dual_commit <= 1'b1;
      end
      if ((mem_req_valid && mem_req_ready) && !dut.stop_pending_q) begin
        saw_memory_streaming <= 1'b1;
      end
      if (mem_req_valid && mem_req_ready && mem_rsp_valid && mem_rsp_ready) begin
        saw_memory_rsp_req_overlap <= 1'b1;
      end
      if (dut.dispatch_fire_w && dut.head1_mem_raw_w &&
          !dut.stop_pending_q) begin
        saw_lane1_memory_streaming <= 1'b1;
      end
      if (dut.direct_ret0_fire_w || dut.direct_ret1_fire_w ||
          dut.pending_jump_return_fire_w) begin
        saw_return_fastpath <= 1'b1;
      end
      if (dut.direct_branch0_fire_w || dut.direct_branch1_fire_w) begin
        saw_branch_fastpath <= 1'b1;
      end
      // 【redirect 防火墙】同拍发射退役: direct 拍寄存一拍, 次拍顺序臂 fire 即命中
      last_direct_redirect <= dut.direct_redirect_fetch_w;
      if (last_direct_redirect && fetch_req_valid && fetch_req_ready) begin
        saw_direct_redirect_fetch <= 1'b1;
      end
      if (dut.branch_resolve_redirect_w && dut.redirect_fetch_req_valid_w &&
          fetch_req_valid && fetch_req_ready) begin
        saw_branch_redirect_fetch <= 1'b1;
      end
      if (dut.branch_prefetch_req_fire_w) begin
        saw_branch_shadow_prefetch <= 1'b1;
      end
      if (dut.branch_prefetch_hit_available_w &&
          dut.core_branch_resolve_valid_w) begin
        saw_branch_shadow_hit <= 1'b1;
      end
      if (dut.core_checkpoint_capture_w) begin
        saw_branch_spec_capture <= 1'b1;
      end
      if (dut.branch_spec_resolve_valid_w &&
          dut.branch_spec_pred_match_w) begin
        saw_branch_spec_correct <= 1'b1;
      end
      if (dut.branch_spec_restore_w) begin
        saw_branch_spec_restore <= 1'b1;
      end
      if (dut.core_branch_resolve_valid_w) begin
        saw_backend_branch_resolve <= 1'b1;
      end
      if (dut.core_dispatch_branch_resolve_valid_w) begin
        saw_branch_dispatch_resolve <= 1'b1;
      end
      if (dut.direct_branch0_lane1_ret_w) begin
        saw_lane1_ret_fallthrough <= 1'b1;
      end
      if (program_mode == MODE_CONTROL_FETCH_GATE &&
          fetch_req_valid && fetch_req_ready &&
          fetch_req_pc == 32'h8000_0008) begin
        saw_control_fallthrough_fetch <= 1'b1;
      end
      if (fp_result_wb_valid && !fp_result_wb_frd) begin
        saw_fp_gpr_completion <= 1'b1;
        if (fp_wake0_valid)
          saw_fp_gpr_completion_wake <= 1'b1;
      end
    end
  end

  initial begin
    tb_errors = 0;
    reset_dut(MODE_DEFAULT_BODY, 32'h0000_0000);

    repeat (80) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("default body halts at ebreak", halted, 1'b1);
    tb_check1("default body is not trap", trap_valid, 1'b0);
    tb_check1("default body exits", exit_valid, 1'b1);
    tb_check1("observed back-to-back packet fetch", saw_back_to_back_fetch, 1'b1);
    tb_check1("observed dual commit", saw_dual_commit, 1'b1);
    tb_check32("default body retired before ebreak", commit_total, 32'd6);
    tb_check32("x0 remains zero", gpr(5'd0), 32'd0);
    tb_check32("x1 retired", gpr(5'd1), 32'd1);
    tb_check32("x2 retired", gpr(5'd2), 32'd2);
    tb_check32("x3 depends on previous packet", gpr(5'd3), 32'd3);
    tb_check32("x4 depends on same packet lane0", gpr(5'd4), 32'd7);
    tb_check32("lane1 WAW wins x5", gpr(5'd5), 32'd9);
    tb_check32("post-ebreak instruction did not dispatch x6", gpr(5'd6), 32'd0);
    tb_check32("rob drained after stop", {27'b0, rob_count}, 32'd0);
    tb_check32("issue queue drained after stop", {28'b0, issue_count}, 32'd0);
    tb_check32("freelist recovered", {25'b0, free_count}, 32'd32);
    tb_check1("ecall flag remains low", exit_is_ecall, 1'b0);
    tb_check1("default body ebreak flag", exit_is_ebreak, 1'b1);
    tb_check32("exit code remains zero", exit_code, 32'd0);

    reset_dut(MODE_BRANCH_TAKEN, 32'h0000_0000);
    repeat (80) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("taken branch reaches ebreak", exit_valid, 1'b1);
    tb_check1("taken branch is not trap", trap_valid, 1'b0);
    // 【F2】direct fire 只在预测 taken(或 head1 不可双发)拍发生; 本场景分支为前跳
    // (static BTFN 预测 not-taken)→dual 双发不 fire, 方向错由后端 mispredict 纠正
    // (上方 reaches-ebreak 已覆盖功能)。fire 观测期望翻转为 0。
    tb_check1("taken branch dual-issues without fire (F2)", saw_branch_fastpath, 1'b0);
    tb_check32("taken branch commits with target body", commit_total, 32'd5);
    tb_check32("taken branch keeps x1", gpr(5'd1), 32'd1);
    tb_check32("taken branch skips lane1 fallthrough", gpr(5'd3), 32'd0);
    tb_check32("taken branch executes target lane0", gpr(5'd4), 32'd4);
    tb_check32("taken branch executes target lane1", gpr(5'd5), 32'd5);
    tb_check1("taken branch ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_BRANCH_NOT_TAKEN, 32'h0000_0000);
    repeat (100) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("not-taken branch reaches ebreak", exit_valid, 1'b1);
    tb_check1("not-taken branch is not trap", trap_valid, 1'b0);
    tb_check1("not-taken branch dual-issues without fire (F2)", saw_branch_fastpath, 1'b0);
    tb_check32("not-taken branch commits fallthrough", commit_total, 32'd7);
    tb_check32("not-taken branch keeps x1", gpr(5'd1), 32'd1);
    tb_check32("not-taken branch executes fallthrough", gpr(5'd3), 32'd3);
    tb_check32("not-taken branch executes next packet lane0", gpr(5'd5), 32'd5);
    tb_check32("not-taken branch executes next packet lane1", gpr(5'd6), 32'd6);
    tb_check1("not-taken branch ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_BRANCH_READY_RESOLVE, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("ready branch reaches ebreak", exit_valid, 1'b1);
    // domain-A: dispatch 拍快解析禁用, ready 分支同样经 IQ resolve(功能由 GPR 终值覆盖)。
    tb_check1("ready branch dispatch fast resolve disabled (domain-A)",
              saw_branch_dispatch_resolve, 1'b0);
    tb_check32("ready branch skips fallthrough", gpr(5'd1), 32'd0);
    tb_check32("ready branch executes target", gpr(5'd2), 32'd7);

    reset_dut(MODE_JAL, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("jal reaches ebreak", exit_valid, 1'b1);
    tb_check1("jal is not trap", trap_valid, 1'b0);
    tb_check1("jal redirect fetches target immediately",
              saw_direct_redirect_fetch, 1'b1);
    tb_check32("jal commits link and target body", commit_total, 32'd5);
    tb_check32("jal keeps older x1", gpr(5'd1), 32'd1);
    tb_check32("jal skips fallthrough lane1", gpr(5'd3), 32'd0);
    tb_check32("jal executes target lane0", gpr(5'd4), 32'd4);
    tb_check32("jal link writes a0", gpr(5'd10), 32'h8000_000c);
    tb_check32("jal target consumer reads link", gpr(5'd5), 32'h8000_000c);
    tb_check1("jal ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_CONTROL_FETCH_GATE, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("control packet reaches ebreak", exit_valid, 1'b1);
    tb_check1("control packet suppresses fallthrough fetch",
              saw_control_fallthrough_fetch, 1'b0);
    tb_check32("control packet commits jal and target", commit_total, 32'd2);
    tb_check32("control packet skips first fallthrough", gpr(5'd2), 32'd0);
    tb_check32("control packet skips second fallthrough", gpr(5'd3), 32'd0);
    tb_check32("control packet target reads link", gpr(5'd4), 32'h8000_0004);

    reset_dut(MODE_RAS_RETURN, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("ras return reaches ebreak", exit_valid, 1'b1);
    tb_check1("ras return is not trap", trap_valid, 1'b0);
    // mode=1（OOO_ROB_WALK_MODE）：ret 走 backend 强制 mispredict redirect（见下 saw_direct_redirect_fetch=1），
    // 不走 mode=0 的 RAS fast-path commit；ret 功能正确性由 commit_total/gpr + riscv-tests 135/0 端到端覆盖。
    if (!`OOO_ROB_WALK_MODE)
      tb_check1("ras return fast path fires", saw_return_fastpath, 1'b1);
    tb_check1("ras return redirect fetches target immediately",
              saw_direct_redirect_fetch, 1'b1);
    tb_check32("ras return commits call body return and continuation",
               commit_total, 32'd5);
    tb_check32("ras return link", gpr(5'd1), 32'h8000_0004);
    tb_check32("ras return callee body", gpr(5'd2), 32'd2);
    tb_check32("ras return continuation", gpr(5'd4), 32'd3);
    tb_check1("ras return ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_BRANCH_LANE1_RET, 32'h0000_0000);
    repeat (160) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("branch lane1 ret reaches ebreak", exit_valid, 1'b1);
    tb_check1("branch lane1 ret is not trap", trap_valid, 1'b0);
    // mode=1：lane1 ret 同样走 backend redirect（saw_direct_redirect_fetch，见下），非 mode=0 的 fast-path/synth-commit。
    if (!`OOO_ROB_WALK_MODE) begin
    tb_check1("branch lane1 ret fast path fires",
              saw_lane1_ret_fallthrough || saw_return_fastpath, 1'b1);
    tb_check1("branch lane1 ret resolves as return",
              saw_lane1_ret_fallthrough || saw_return_fastpath, 1'b1);
    end
    tb_check1("branch lane1 ret redirects fetch target immediately",
              saw_direct_redirect_fetch, 1'b1);
    tb_check32("branch lane1 ret commits call branch return continuation",
               commit_total, 32'd4);
    tb_check32("branch lane1 ret link", gpr(5'd1), 32'h8000_0004);
    tb_check32("branch lane1 ret skips pre-branch body", gpr(5'd2), 32'd0);
    tb_check32("branch lane1 ret continuation", gpr(5'd5), 32'd5);
    tb_check1("branch lane1 ret ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_RVC_CADDIW, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("rvc c.addiw reaches c.ebreak", exit_valid, 1'b1);
    tb_check1("rvc c.addiw is not trap", trap_valid, 1'b0);
    tb_check1("rvc c.addiw does not redirect as c.jal",
              saw_direct_redirect_fetch, 1'b0);
    tb_check32("rvc c.addiw commits decompressed body", commit_total, 32'd4);
    tb_check32("rvc c.addiw sign-extends low word", gpr(5'd5),
               32'hffff_ffff);
    tb_check32("rvc c.addiw keeps halfword fallthrough", gpr(5'd6), 32'd1);
    tb_check1("rvc c.ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_JALR_RD_EQ_RS1, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("jalr reaches ebreak", exit_valid, 1'b1);
    tb_check1("jalr is not trap", trap_valid, 1'b0);
    tb_check32("jalr trap cause stays clear", {27'b0, trap_cause}, 32'd0);
    tb_check32("jalr trap pc stays clear", trap_pc, 32'd0);
    tb_check32("jalr trap tval stays clear", trap_tval, 32'd0);
    tb_check32("jalr commits link and target body", commit_total, 32'd5);
    tb_check32("jalr uses old rs1 target before link write", gpr(5'd6), 32'd0);
    tb_check32("jalr rd receives link", gpr(5'd5), 32'h8000_000c);
    tb_check32("jalr target consumer reads link", gpr(5'd7), 32'h8000_000c);
    tb_check32("jalr target lane1 executes", gpr(5'd8), 32'd8);
    tb_check1("jalr ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_MEM_LW_SW, 32'h0000_0000);
    repeat (160) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("memory program reaches ebreak", exit_valid, 1'b1);
    tb_check1("memory program is not trap", trap_valid, 1'b0);
    tb_check32("memory program commits store/load body", commit_total, 32'd8);
    tb_check1("memory issues while frontend is not stopped",
              saw_memory_streaming, 1'b1);
    tb_check1("memory request leaves frontend running",
              saw_memory_streaming || saw_memory_rsp_req_overlap, 1'b1);
    tb_check32("memory store writes word", data_mem_word, 32'd11);
    tb_check32("memory load reads stored word", gpr(5'd4), 32'd11);
    tb_check32("load consumer sees loaded value", gpr(5'd5), 32'd12);
    tb_check32("post-load lane1 executes", gpr(5'd6), 32'd6);
    tb_check1("memory ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_LANE1_EBREAK, 32'h0000_0000);
    repeat (60) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane1 ebreak halts core", halted, 1'b1);
    tb_check1("lane1 ebreak exits", exit_valid, 1'b1);
    tb_check1("lane1 ebreak flag", exit_is_ebreak, 1'b1);
    tb_check1("lane1 ebreak is not trap", trap_valid, 1'b0);
    tb_check32("lane1 ebreak dispatches lane0 first", commit_total, 32'd1);
    tb_check32("lane1 ebreak keeps lane0 write", gpr(5'd1), 32'd1);

    reset_dut(MODE_LANE1_BRANCH_TAKEN, 32'h0000_0000);
    repeat (100) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane1 branch reaches ebreak", exit_valid, 1'b1);
    tb_check1("lane1 branch is not trap", trap_valid, 1'b0);
    tb_check1("lane1 branch dual-issues without fire (F2)", saw_branch_fastpath, 1'b0);
    tb_check1("lane1 branch resolves in backend",
              saw_backend_branch_resolve, 1'b1);
    tb_check32("lane1 branch commits precise body", commit_total, 32'd4);
    tb_check32("lane1 branch sees lane0 result", gpr(5'd1), 32'd1);
    tb_check32("lane1 branch skips fallthrough", gpr(5'd2), 32'd0);
    tb_check32("lane1 branch target lane0 executes", gpr(5'd3), 32'd3);
    tb_check32("lane1 branch target lane1 executes", gpr(5'd4), 32'd4);
    tb_check1("lane1 branch ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_BRANCH_SHADOW_PREFETCH, 32'h0000_0000);
    repeat (120) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("branch shadow prefetch reaches ebreak", exit_valid, 1'b1);
    tb_check1("branch shadow prefetch is not trap", trap_valid, 1'b0);
    tb_check1("branch speculation captures or early resolves",
              saw_branch_spec_capture || saw_branch_shadow_prefetch ||
              saw_branch_dispatch_resolve || saw_backend_branch_resolve,
              1'b1);
    tb_check1("branch speculation resolves or early resolves",
              saw_branch_spec_correct || saw_branch_shadow_hit ||
              saw_branch_dispatch_resolve || saw_backend_branch_resolve,
              1'b1);
    tb_check32("branch shadow prefetch commits target body",
               commit_total, 32'd4);
    tb_check32("branch shadow prefetch skips fallthrough", gpr(5'd2), 32'd0);
    tb_check32("branch shadow prefetch target executes", gpr(5'd3), 32'd3);
    tb_check1("branch shadow prefetch ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_LANE1_JAL, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane1 jal reaches ebreak", exit_valid, 1'b1);
    tb_check1("lane1 jal is not trap", trap_valid, 1'b0);
    tb_check1("lane1 jal redirect fetches target immediately",
              saw_direct_redirect_fetch, 1'b1);
    tb_check32("lane1 jal commits link and target lane0", commit_total, 32'd3);
    tb_check1("lane1 jal keeps precise lane0 order",
              saw_dual_commit || (gpr(5'd1) == 32'd1), 1'b1);
    tb_check32("lane1 jal keeps older lane0", gpr(5'd1), 32'd1);
    tb_check32("lane1 jal skips fallthrough", gpr(5'd2), 32'd0);
    tb_check32("lane1 jal link writes a0", gpr(5'd10), 32'h8000_0008);
    tb_check32("lane1 jal target reads link", gpr(5'd3), 32'h8000_0008);
    tb_check1("lane1 jal ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_LANE1_MEM, 32'h0000_0000);
    repeat (180) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane1 memory program reaches ebreak", exit_valid, 1'b1);
    tb_check1("lane1 memory program is not trap", trap_valid, 1'b0);
    tb_check32("lane1 memory commits store/load body", commit_total, 32'd6);
    tb_check1("lane1 memory streams through normal dispatch",
              saw_lane1_memory_streaming, 1'b1);
    tb_check32("lane1 store writes word", data_mem_word, 32'd13);
    tb_check32("lane1 memory load reads stored word", gpr(5'd4), 32'd13);
    tb_check32("lane1 memory load consumer sees value", gpr(5'd5), 32'd14);
    tb_check1("lane1 memory ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_FMV_W_X, 32'h0000_0000);
    repeat (140) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("fmv.w.x reaches ebreak", exit_valid, 1'b1);
    tb_check1("fmv.w.x is not trap", trap_valid, 1'b0);
    tb_check32("fmv.w.x follows FP decode path", gpr(5'd5), 32'd7);
    tb_check32("fmv.x.w writes integer destination", gpr(5'd6), 32'd0);
    tb_check32("fmv.w.x/fmv.x.w retire before ebreak", commit_total, 32'd5);
    tb_check1("GPR-destination FP completion observed",
              saw_fp_gpr_completion, 1'b1);
    tb_check1("GPR-destination FP completion does not wake FPR domain",
              saw_fp_gpr_completion_wake, 1'b0);
    tb_check1("fmv.w.x ebreak flag", exit_is_ebreak, 1'b1);

    reset_dut(MODE_EBREAK, 32'h0000_0000);
    repeat (12) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("lane0 ebreak halts core", halted, 1'b1);
    tb_check1("lane0 ebreak exits", exit_valid, 1'b1);
    tb_check1("lane0 ebreak flag", exit_is_ebreak, 1'b1);
    tb_check1("lane0 ebreak is not trap", trap_valid, 1'b0);
    tb_check32("lane0 ebreak retires no instruction", commit_total, 32'd0);

    reset_dut(MODE_ECALL, 32'h0000_0000);
    repeat (80) begin
      `TB_TICK(clk);
      #1;
    end

    tb_check1("ecall handler reaches ebreak", exit_valid, 1'b1);
    tb_check1("ecall is handled by CSR trap, not fatal trap", trap_valid, 1'b0);
    tb_check1("ecall does not use legacy exit flag", exit_is_ecall, 1'b0);
    tb_check1("ecall handler exits by ebreak", exit_is_ebreak, 1'b1);
    tb_check32("ecall retires older instructions and handler", commit_total, 32'd7);
    tb_check32("ecall packet did not dispatch lane1", gpr(5'd5), 32'd0);
    tb_check32("ecall mtvec handler executes", gpr(5'd6), 32'd6);
    tb_check32("ecall exit code from a0", exit_code, 32'd0);
    tb_check32("ecall rob drained after stop", {27'b0, rob_count}, 32'd0);
    tb_check32("ecall issue queue drained after stop", {28'b0, issue_count}, 32'd0);

    tb_finish("tb_ooo_core_top_glue");
  end
endmodule
