`include "define.v"
`include "tb_common.svh"
`include "rv32_encode.svh"

module tb_ooo_priv_system;
  reg clk;
  reg rst;
  reg flush;
  reg run;
  reg irq_software;
  reg irq_timer;
  reg irq_external;
  reg commit_ready;

  wire fetch_req_valid;
  reg fetch_req_ready;
  wire [`XLEN-1:0] fetch_req_pc;
  reg fetch_rsp_valid;
  wire fetch_rsp_ready;
  reg [`INST_W-1:0] fetch_rsp_inst0;
  reg [1:0] fetch_rsp_resp0;
  reg [`INST_W-1:0] fetch_rsp_inst1;
  reg [1:0] fetch_rsp_resp1;

  wire mem_req_valid;
  reg mem_req_ready;
  wire mem_req_write;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  reg mem_rsp_valid;
  wire mem_rsp_ready;
  reg [`XLEN-1:0] mem_rsp_rdata;
  reg mem_rsp_error;
  wire mem1_req_valid;
  reg mem1_req_ready;
  wire mem1_req_write;
  wire [`XLEN-1:0] mem1_req_addr;
  wire [`XLEN-1:0] mem1_req_wdata;
  wire [`STRB_W-1:0] mem1_req_wstrb;
  reg mem1_rsp_valid;
  wire mem1_rsp_ready;
  reg [`XLEN-1:0] mem1_rsp_rdata;
  reg mem1_rsp_error;

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

  localparam [3:0] MODE_ECALL_MRET = 4'd0;
  localparam [3:0] MODE_IRQ_WFI = 4'd1;
  localparam [3:0] MODE_SMODE_BOOT = 4'd2;
  localparam [3:0] MODE_SBI_ECALL = 4'd3;
  localparam [3:0] MODE_S_EXT_IRQ = 4'd4;
  localparam [`XLEN-1:0] BASE_PC = 64'h0000_0000_8000_0000;
  localparam [`XLEN-1:0] HANDLER_PC = 64'h0000_0000_8000_0080;
  localparam [`XLEN-1:0] S_ENTRY_PC = 64'h0000_0000_8000_0040;
  localparam [`XLEN-1:0] S_HANDLER_PC = 64'h0000_0000_8000_0100;

  reg [3:0] program_mode;
  integer cycle_count;
  integer commit_total;
  reg saw_handler_fetch;
  reg saw_csr_commit;
  reg saw_lane1_csr_commit;
  reg saw_mret_commit;
  reg saw_sfence_commit;
  reg saw_wfi_commit;
  reg saw_irq_handler_fetch;
  reg saw_smode_handler_fetch;
  reg saw_sret_commit;
  reg saw_satp_commit;

  OooAluFetchCore dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .run_i(run),
    .reset_pc_i(`RESET_PC),
    .time_i(64'd1234),
    .irq_software_i(irq_software),
    .irq_timer_i(irq_timer),
    .irq_external_i(irq_external),
    .fetch_req_valid_o(fetch_req_valid),
    .fetch_req_ready_i(fetch_req_ready),
    .fetch_req_pc_o(fetch_req_pc),
    .fetch_rsp_valid_i(fetch_rsp_valid),
    .fetch_rsp_ready_o(fetch_rsp_ready),
    .fetch_rsp_inst0_i(fetch_rsp_inst0),
    .fetch_rsp_resp0_i(fetch_rsp_resp0),
    .fetch_rsp_inst1_i(fetch_rsp_inst1),
    .fetch_rsp_resp1_i(fetch_rsp_resp1),
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
    .mem1_req_valid_o(mem1_req_valid),
    .mem1_req_ready_i(mem1_req_ready),
    .mem1_req_write_o(mem1_req_write),
    .mem1_req_addr_o(mem1_req_addr),
    .mem1_req_wdata_o(mem1_req_wdata),
    .mem1_req_wstrb_o(mem1_req_wstrb),
    .mem1_rsp_valid_i(mem1_rsp_valid),
    .mem1_rsp_ready_o(mem1_rsp_ready),
    .mem1_rsp_rdata_i(mem1_rsp_rdata),
    .mem1_rsp_error_i(mem1_rsp_error),
    .mem1_rsp_page_fault_i(1'b0),
    .mem_flush_o(mem_flush),
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
    .debug_pc_o(debug_pc),
    .debug_state_o(debug_state),
    .debug_gprs_o(debug_gprs),
    .retire_count_o(retire_count),
    .free_count_o(free_count),
    .rob_count_o(rob_count),
    .issue_count_o(issue_count)
  );

  function [`XLEN-1:0] gpr;
    input [`REG_ADDR_W-1:0] idx;
    begin
      gpr = debug_gprs[idx * `XLEN +: `XLEN];
    end
  endfunction

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

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

  function [`INST_W-1:0] inst_auipc;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_auipc = rv32_u(imm, rd, `OPCODE_AUIPC);
    end
  endfunction

  function [`INST_W-1:0] inst_lui;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_lui = rv32_u(imm, rd, `OPCODE_LUI);
    end
  endfunction

  function [`INST_W-1:0] inst_csr;
    input [11:0] csr;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_csr = rv32_i(csr, rs1, funct3, rd, `OPCODE_SYSTEM);
    end
  endfunction

  function [`INST_W-1:0] inst_csrrw;
    input [4:0] rd;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      inst_csrrw = inst_csr(csr, rs1, 3'b001, rd);
    end
  endfunction

  function [`INST_W-1:0] inst_csrrs;
    input [4:0] rd;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      inst_csrrs = inst_csr(csr, rs1, 3'b010, rd);
    end
  endfunction

  function [`INST_W-1:0] inst_ecall;
    begin
      inst_ecall = 32'h0000_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_ebreak;
    begin
      inst_ebreak = 32'h0010_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_mret;
    begin
      inst_mret = 32'h3020_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_sret;
    begin
      inst_sret = 32'h1020_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_wfi;
    begin
      inst_wfi = 32'h1050_0073;
    end
  endfunction

  function [`INST_W-1:0] inst_sfence_vma;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_sfence_vma = {`SYSTEM_FUNCT7_SFENCE_VMA, rs2, rs1,
                         `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
    end
  endfunction

  function [`INST_W-1:0] program_word;
    input [`XLEN-1:0] addr;
    begin
      program_word = inst_ebreak();
      case (program_mode)
        MODE_ECALL_MRET: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_addi(5'd10, 5'd0, 12'h011);
            BASE_PC + 64'h04: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h08: program_word = inst_addi(5'd1, 5'd1, 12'h07c);
            BASE_PC + 64'h0c: program_word = inst_csrrw(5'd5, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h10: program_word = inst_csrrs(5'd6, `CSR_MTVEC, 5'd0);
            BASE_PC + 64'h14: program_word = inst_addi(5'd3, 5'd0, 12'h003);
            BASE_PC + 64'h18: program_word = inst_add(5'd4, 5'd10, 5'd3);
            BASE_PC + 64'h1c: program_word = inst_ecall();
            BASE_PC + 64'h20: program_word = inst_addi(5'd7, 5'd0, 12'h007);
            BASE_PC + 64'h24: program_word = inst_sfence_vma(5'd0, 5'd0);
            BASE_PC + 64'h28: program_word = inst_wfi();
            BASE_PC + 64'h2c: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_MEPC, 5'd0);
            HANDLER_PC + 64'h08: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            HANDLER_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd9);
            HANDLER_PC + 64'h10: program_word = inst_addi(5'd11, 5'd0, 12'h055);
            HANDLER_PC + 64'h14: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_IRQ_WFI: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h080);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd2, 5'd0, 12'h080);
            BASE_PC + 64'h10: program_word = inst_csrrw(5'd0, `CSR_MIE, 5'd2);
            BASE_PC + 64'h14: program_word = inst_addi(5'd3, 5'd0, 12'h008);
            BASE_PC + 64'h18: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd3);
            BASE_PC + 64'h1c: program_word = inst_wfi();
            BASE_PC + 64'h20: program_word = inst_addi(5'd13, 5'd0, 12'h00d);
            BASE_PC + 64'h24: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd14, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_addi(5'd15, 5'd0, 12'h066);
            HANDLER_PC + 64'h08: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_SMODE_BOOT: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h100);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_STVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd2, 5'd0, 12'h200);
            BASE_PC + 64'h10: program_word = inst_csrrw(5'd0, `CSR_MEDELEG, 5'd2);
            BASE_PC + 64'h14: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h18: program_word = inst_addi(5'd3, 5'd3, 12'h02c);
            BASE_PC + 64'h1c: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h20: program_word = inst_lui(5'd4, 20'h00001);
            BASE_PC + 64'h24: program_word = inst_addi(5'd4, 5'd4, 12'h800);
            BASE_PC + 64'h28: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
            BASE_PC + 64'h2c: program_word = inst_mret();
            S_ENTRY_PC + 64'h00: program_word = inst_csrrs(5'd5, `CSR_SSTATUS, 5'd0);
            S_ENTRY_PC + 64'h04: program_word = inst_csrrw(5'd0, `CSR_SATP, 5'd0);
            S_ENTRY_PC + 64'h08: program_word = inst_sfence_vma(5'd0, 5'd0);
            S_ENTRY_PC + 64'h0c: program_word = inst_ecall();
            S_ENTRY_PC + 64'h10: program_word = inst_addi(5'd7, 5'd0, 12'h077);
            S_ENTRY_PC + 64'h14: program_word = inst_ebreak();
            S_HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_SCAUSE, 5'd0);
            S_HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_SEPC, 5'd0);
            S_HANDLER_PC + 64'h08: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            S_HANDLER_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
            S_HANDLER_PC + 64'h10: program_word = inst_addi(5'd10, 5'd0, 12'h066);
            S_HANDLER_PC + 64'h14: program_word = inst_sret();
            default: begin end
          endcase
        end
        MODE_SBI_ECALL: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h080);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_MTVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_MEDELEG, 5'd0);
            BASE_PC + 64'h10: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h14: program_word = inst_addi(5'd3, 5'd3, 12'h030);
            BASE_PC + 64'h18: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h1c: program_word = inst_lui(5'd4, 20'h00001);
            BASE_PC + 64'h20: program_word = inst_addi(5'd4, 5'd4, 12'h800);
            BASE_PC + 64'h24: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
            BASE_PC + 64'h28: program_word = inst_mret();
            S_ENTRY_PC + 64'h00: program_word = inst_addi(5'd5, 5'd0, 12'h123);
            S_ENTRY_PC + 64'h04: program_word = inst_ecall();
            S_ENTRY_PC + 64'h08: program_word = inst_addi(5'd7, 5'd0, 12'h05a);
            S_ENTRY_PC + 64'h0c: program_word = inst_ebreak();
            HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_MCAUSE, 5'd0);
            HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_MEPC, 5'd0);
            HANDLER_PC + 64'h08: program_word = inst_csrrs(5'd10, `CSR_MSTATUS, 5'd0);
            HANDLER_PC + 64'h0c: program_word = inst_addi(5'd12, 5'd9, 12'h000);
            HANDLER_PC + 64'h10: program_word = inst_addi(5'd9, 5'd9, 12'h004);
            HANDLER_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd9);
            HANDLER_PC + 64'h18: program_word = inst_addi(5'd11, 5'd0, 12'h06b);
            HANDLER_PC + 64'h1c: program_word = inst_mret();
            default: begin end
          endcase
        end
        MODE_S_EXT_IRQ: begin
          case (addr)
            BASE_PC + 64'h00: program_word = inst_auipc(5'd1, 20'h00000);
            BASE_PC + 64'h04: program_word = inst_addi(5'd1, 5'd1, 12'h100);
            BASE_PC + 64'h08: program_word = inst_csrrw(5'd0, `CSR_STVEC, 5'd1);
            BASE_PC + 64'h0c: program_word = inst_addi(5'd2, 5'd0, 12'h200);
            BASE_PC + 64'h10: program_word = inst_addi(5'd0, 5'd0, 12'h000);
            BASE_PC + 64'h14: program_word = inst_csrrw(5'd0, `CSR_MIDELEG, 5'd2);
            BASE_PC + 64'h18: program_word = inst_auipc(5'd3, 20'h00000);
            BASE_PC + 64'h1c: program_word = inst_addi(5'd3, 5'd3, 12'h028);
            BASE_PC + 64'h20: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
            BASE_PC + 64'h24: program_word = inst_lui(5'd4, 20'h00001);
            BASE_PC + 64'h28: program_word = inst_addi(5'd4, 5'd4, 12'h800);
            BASE_PC + 64'h2c: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
            BASE_PC + 64'h30: program_word = inst_mret();
            S_ENTRY_PC + 64'h00: program_word = inst_addi(5'd5, 5'd0, 12'h200);
            S_ENTRY_PC + 64'h04: program_word = inst_csrrw(5'd0, `CSR_SIE, 5'd5);
            S_ENTRY_PC + 64'h08: program_word = inst_addi(5'd6, 5'd0, 12'h002);
            S_ENTRY_PC + 64'h0c: program_word = inst_csrrw(5'd0, `CSR_SSTATUS, 5'd6);
            S_ENTRY_PC + 64'h10: program_word = inst_wfi();
            S_ENTRY_PC + 64'h14: program_word = inst_addi(5'd7, 5'd0, 12'h071);
            S_ENTRY_PC + 64'h18: program_word = inst_ebreak();
            S_HANDLER_PC + 64'h00: program_word = inst_csrrs(5'd8, `CSR_SCAUSE, 5'd0);
            S_HANDLER_PC + 64'h04: program_word = inst_csrrs(5'd9, `CSR_SEPC, 5'd0);
            S_HANDLER_PC + 64'h08: program_word = inst_csrrs(5'd10, `CSR_SSTATUS, 5'd0);
            S_HANDLER_PC + 64'h0c: program_word = inst_addi(5'd11, 5'd0, 12'h072);
            S_HANDLER_PC + 64'h10: program_word = inst_sret();
            default: begin end
          endcase
        end
        default: begin end
      endcase
    end
  endfunction

  task automatic reset_dut;
    input [3:0] mode_i;
    begin
      clk = 1'b0;
      rst = 1'b1;
      flush = 1'b0;
      run = 1'b1;
      irq_software = 1'b0;
      irq_timer = 1'b0;
      irq_external = 1'b0;
      commit_ready = 1'b1;
      fetch_req_ready = 1'b1;
      fetch_rsp_valid = 1'b0;
      fetch_rsp_inst0 = {`INST_W{1'b0}};
      fetch_rsp_inst1 = {`INST_W{1'b0}};
      fetch_rsp_resp0 = 2'b00;
      fetch_rsp_resp1 = 2'b00;
      mem_req_ready = 1'b1;
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      mem1_req_ready = 1'b1;
      mem1_rsp_valid = 1'b0;
      mem1_rsp_rdata = {`XLEN{1'b0}};
      mem1_rsp_error = 1'b0;
      program_mode = mode_i;
      cycle_count = 0;
      commit_total = 0;
      saw_handler_fetch = 1'b0;
      saw_csr_commit = 1'b0;
      saw_lane1_csr_commit = 1'b0;
      saw_mret_commit = 1'b0;
      saw_sfence_commit = 1'b0;
      saw_wfi_commit = 1'b0;
      saw_irq_handler_fetch = 1'b0;
      saw_smode_handler_fetch = 1'b0;
      saw_sret_commit = 1'b0;
      saw_satp_commit = 1'b0;
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic run_until_exit;
    input integer max_cycles;
    begin
      while (!exit_valid && !trap_valid && cycle_count < max_cycles) begin
        `TB_TICK(clk);
        cycle_count = cycle_count + 1;
      end
      if (cycle_count >= max_cycles) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] timeout waiting for completion mode=%0d",
                 program_mode);
      end
    end
  endtask

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
        fetch_rsp_inst1 <= program_word(fetch_req_pc + 64'd4);
        fetch_rsp_resp0 <= 2'b00;
        fetch_rsp_resp1 <= 2'b00;
        if (fetch_req_pc == HANDLER_PC) begin
          saw_handler_fetch <= 1'b1;
          if (program_mode == MODE_IRQ_WFI) begin
            saw_irq_handler_fetch <= 1'b1;
            irq_timer <= 1'b0;
          end
        end
        if (fetch_req_pc == S_HANDLER_PC) begin
          saw_smode_handler_fetch <= 1'b1;
          if (program_mode == MODE_S_EXT_IRQ) begin
            irq_external <= 1'b0;
          end
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rst || flush) begin
      mem_rsp_valid <= 1'b0;
      mem_rsp_rdata <= {`XLEN{1'b0}};
      mem_rsp_error <= 1'b0;
      mem1_rsp_valid <= 1'b0;
      mem1_rsp_rdata <= {`XLEN{1'b0}};
      mem1_rsp_error <= 1'b0;
    end else begin
      if (mem_rsp_valid && mem_rsp_ready) mem_rsp_valid <= 1'b0;
      if (mem1_rsp_valid && mem1_rsp_ready) mem1_rsp_valid <= 1'b0;
      if (mem_req_valid && mem_req_ready) begin
        mem_rsp_valid <= 1'b1;
        mem_rsp_rdata <= {`XLEN{1'b0}};
        mem_rsp_error <= 1'b0;
      end
      if (mem1_req_valid && mem1_req_ready) begin
        mem1_rsp_valid <= 1'b1;
        mem1_rsp_rdata <= {`XLEN{1'b0}};
        mem1_rsp_error <= 1'b0;
      end
    end
  end

  task automatic observe_commit;
    input valid;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst;
    begin
      if (valid) begin
        if ((inst[6:0] == `OPCODE_SYSTEM) && (inst[14:12] != 3'b000)) begin
          saw_csr_commit <= 1'b1;
          if (pc == (BASE_PC + 64'h0c)) saw_lane1_csr_commit <= 1'b1;
          if (inst[31:20] == `CSR_SATP) saw_satp_commit <= 1'b1;
        end
        if (inst == inst_mret()) saw_mret_commit <= 1'b1;
        if (inst == inst_sret()) saw_sret_commit <= 1'b1;
        if (inst == inst_sfence_vma(5'd0, 5'd0)) saw_sfence_commit <= 1'b1;
        if (inst == inst_wfi()) saw_wfi_commit <= 1'b1;
      end
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      commit_total <= 0;
    end else begin
      commit_total <= commit_total + commit0_valid + commit1_valid;
      observe_commit(commit0_valid, commit0_pc, commit0_inst);
      observe_commit(commit1_valid, commit1_pc, commit1_inst);
    end
  end

  initial begin
    tb_errors = 0;

    reset_dut(MODE_ECALL_MRET);
    run_until_exit(500);
    tb_check1("ecall/mret reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("ecall/mret exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("ecall is architectural trap, not sim exit", exit_is_ecall, 1'b0);
    tb_check1("ecall/mret no fatal trap", trap_valid, 1'b0);
    tb_check1("ecall handler fetch observed", saw_handler_fetch, 1'b1);
    tb_check1("csr old-value commits observed", saw_csr_commit, 1'b1);
    tb_check1("lane1 csr barrier commits", saw_lane1_csr_commit, 1'b1);
    tb_check1("mret synthetic commit observed", saw_mret_commit, 1'b1);
    tb_check1("sfence synthetic commit observed", saw_sfence_commit, 1'b1);
    tb_check1("wfi synthetic commit observed", saw_wfi_commit, 1'b1);
    tb_check64("mtvec old value returned", gpr(5'd5), 64'h0);
    tb_check64("mtvec readback after lane1 csrrw", gpr(5'd6), HANDLER_PC);
    tb_check64("ecall mcause", gpr(5'd8), {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_MMODE});
    tb_check64("ecall mepc plus four", gpr(5'd9), BASE_PC + 64'h20);
    tb_check64("handler body executed", gpr(5'd11), 64'h55);
    tb_check64("post mret body executed", gpr(5'd7), 64'h7);
    tb_check64("older alu survived system drain", gpr(5'd4), 64'h14);
    tb_check32("backend drained after ebreak", {27'b0, rob_count}, 32'd0);

    reset_dut(MODE_IRQ_WFI);
    irq_timer = 1'b1;
    run_until_exit(700);
    tb_check1("irq/wfi reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("irq/wfi exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("irq/wfi no fatal trap", trap_valid, 1'b0);
    tb_check1("timer interrupt handler fetch observed", saw_irq_handler_fetch, 1'b1);
    tb_check1("timer interrupt mret observed", saw_mret_commit, 1'b1);
    tb_check1("wfi commit observed after interrupt return", saw_wfi_commit, 1'b1);
    tb_check64("timer mcause interrupt bit", gpr(5'd14), `MCAUSE_INTERRUPT | 64'd7);
    tb_check64("timer handler body executed", gpr(5'd15), 64'h66);
    tb_check64("post interrupt wfi fallthrough", gpr(5'd13), 64'h0d);
    tb_check32("irq backend drained after ebreak", {27'b0, rob_count}, 32'd0);

    reset_dut(MODE_SMODE_BOOT);
    run_until_exit(1000);
    tb_check1("s-mode boot reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("s-mode boot exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("s-mode boot no fatal trap", trap_valid, 1'b0);
    tb_check1("s-mode delegated handler fetch observed", saw_smode_handler_fetch, 1'b1);
    tb_check1("mret into s-mode observed", saw_mret_commit, 1'b1);
    tb_check1("sret back to s-mode observed", saw_sret_commit, 1'b1);
    tb_check1("satp csr commit observed", saw_satp_commit, 1'b1);
    tb_check1("sfence after satp observed", saw_sfence_commit, 1'b1);
    tb_check64("s-mode delegated scause", gpr(5'd8), {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_SMODE});
    tb_check64("s-mode sepc plus four", gpr(5'd9), S_ENTRY_PC + 64'h10);
    tb_check64("s-mode handler body executed", gpr(5'd10), 64'h66);
    tb_check64("post sret body executed", gpr(5'd7), 64'h77);
    tb_check32("s-mode backend drained after ebreak", {27'b0, rob_count}, 32'd0);

    reset_dut(MODE_SBI_ECALL);
    run_until_exit(1000);
    tb_check1("sbi ecall reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("sbi ecall exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("sbi ecall is architectural trap, not sim exit", exit_is_ecall, 1'b0);
    tb_check1("sbi ecall no fatal trap", trap_valid, 1'b0);
    tb_check1("sbi m-mode handler fetch observed", saw_handler_fetch, 1'b1);
    tb_check1("sbi path did not enter s-mode handler", saw_smode_handler_fetch, 1'b0);
    tb_check1("sbi handoff mret observed", saw_mret_commit, 1'b1);
    tb_check64("sbi mcause is s-mode ecall", gpr(5'd8),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_SMODE});
    tb_check64("sbi mepc points at s ecall", gpr(5'd12),
               S_ENTRY_PC + 64'h04);
    tb_check64("sbi mepc return target", gpr(5'd9),
               S_ENTRY_PC + 64'h08);
    tb_check64("sbi trap recorded mpp=s",
               gpr(5'd10) & `MSTATUS_MPP_MASK, `MSTATUS_MPP_S);
    tb_check64("sbi m-mode handler body executed", gpr(5'd11), 64'h6b);
    tb_check64("sbi s-mode pre-ecall body executed", gpr(5'd5), 64'h123);
    tb_check64("sbi returned to s-mode body", gpr(5'd7), 64'h5a);
    tb_check32("sbi backend drained after ebreak", {27'b0, rob_count}, 32'd0);

    reset_dut(MODE_S_EXT_IRQ);
    irq_external = 1'b1;
    run_until_exit(1000);
    tb_check1("s external irq reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("s external irq exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("s external irq no fatal trap", trap_valid, 1'b0);
    tb_check1("s external irq enters s handler", saw_smode_handler_fetch, 1'b1);
    tb_check1("s external irq does not enter m handler", saw_handler_fetch, 1'b0);
    tb_check1("s external irq sret observed", saw_sret_commit, 1'b1);
    tb_check1("s external irq wfi fallthrough observed", saw_wfi_commit, 1'b1);
    tb_check64("s external irq scause", gpr(5'd8),
               `MCAUSE_INTERRUPT | {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `IRQ_CAUSE_SEI});
    tb_check64("s external irq sepc", gpr(5'd9), S_ENTRY_PC + 64'h10);
    tb_check64("s external irq recorded spp=s",
               gpr(5'd10) & `MSTATUS_SPP, `MSTATUS_SPP);
    tb_check64("s external irq handler body executed", gpr(5'd11), 64'h72);
    tb_check64("s external irq returned to s body", gpr(5'd7), 64'h71);
    tb_check32("s external irq backend drained after ebreak", {27'b0, rob_count}, 32'd0);

    tb_finish("tb_ooo_priv_system");
  end

  wire unused_observe_w =
      mem_req_write | (|mem_req_addr) | (|mem_req_wdata) |
      (|mem_req_wstrb) | mem1_req_write | (|mem1_req_addr) |
      (|mem1_req_wdata) | (|mem1_req_wstrb) |
      commit0_rd_en | (|commit0_rd_addr) | (|commit0_rd_data) |
      commit0_exception | commit0_write | (|commit0_next_pc) |
      commit1_rd_en | (|commit1_rd_addr) | (|commit1_rd_data) |
      commit1_exception | commit1_write | (|commit1_next_pc) |
      halted | (|debug_pc) | (|debug_state) | (|retire_count) |
      (|free_count) | (|issue_count) | (|trap_cause) |
      (|trap_pc) | (|trap_tval) | (|exit_code);

endmodule
