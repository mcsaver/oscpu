`include "define.v"
`include "tb_common.svh"
`include "rv32_encode.svh"

module tb_ooo_sv39_boot;
  reg clk;
  reg rst;

  wire ifu_axi_arvalid;
  reg ifu_axi_arready;
  wire [`XLEN-1:0] ifu_axi_araddr;
  wire [2:0] ifu_axi_arsize;
  wire [2:0] ifu_axi_arprot;
  reg ifu_axi_rvalid;
  wire ifu_axi_rready;
  reg [`XLEN-1:0] ifu_axi_rdata;
  reg [1:0] ifu_axi_rresp;

  wire lsu_axi_arvalid;
  reg lsu_axi_arready;
  wire [`XLEN-1:0] lsu_axi_araddr;
  wire [2:0] lsu_axi_arsize;
  reg lsu_axi_rvalid;
  wire lsu_axi_rready;
  reg [`XLEN-1:0] lsu_axi_rdata;
  reg [1:0] lsu_axi_rresp;
  wire lsu_axi_awvalid;
  reg lsu_axi_awready;
  wire [`XLEN-1:0] lsu_axi_awaddr;
  wire lsu_axi_wvalid;
  reg lsu_axi_wready;
  wire [`XLEN-1:0] lsu_axi_wdata;
  wire [`STRB_W-1:0] lsu_axi_wstrb;
  reg lsu_axi_bvalid;
  wire lsu_axi_bready;
  reg [1:0] lsu_axi_bresp;

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
  wire [`XLEN-1:0] exit_pc;
  wire halted;
  wire [`XLEN-1:0] debug_pc;
  wire [`CORE_STATE_W-1:0] debug_state;
  wire [`XLEN * `REG_NUM - 1:0] debug_gprs;
  wire [1:0] retire_count;
  wire [6:0] free_count;
  wire [4:0] rob_count;
  wire [3:0] issue_count;

  localparam [`XLEN-1:0] BASE_PC = 64'h0000_0000_8000_0000;
  localparam [`XLEN-1:0] S_ENTRY_PC = 64'h0000_0000_8000_0080;
  localparam [`XLEN-1:0] S_HANDLER_PC = 64'h0000_0000_8000_0100;
  localparam [`XLEN-1:0] USER_ENTRY_VA = 64'h0000_0000_c000_0200;
  localparam [`XLEN-1:0] USER_ENTRY_PA = 64'h0000_0000_8000_0200;
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8000_2000;
  localparam [`XLEN-1:0] DATA_PA = 64'h0000_0000_8000_3000;
  localparam [`XLEN-1:0] DATA_VALUE = 64'h1122_3344_5566_7788;
  localparam [`XLEN-1:0] ROOT_PPN = ROOT_PT >> 12;
  localparam [`XLEN-1:0] SUPERPAGE_PPN = BASE_PC >> 12;
  localparam [`XLEN-1:0] LEAF_FLAGS = 64'h0cf;
  localparam [`XLEN-1:0] SUPERPAGE_PTE =
      (SUPERPAGE_PPN << 10) | LEAF_FLAGS;
  localparam [`XLEN-1:0] USER_SUPERPAGE_PTE =
      (SUPERPAGE_PPN << 10) | LEAF_FLAGS | 64'h010;

  integer cycle_count;
  integer ifu_page_walk_reads;
  integer lsu_page_walk_reads;
  integer ifu_fault_walk_reads;
  integer lsu_fault_walk_reads;
  integer data_load_reads;
  integer data_store_writes;
  reg [`XLEN-1:0] stored_data_q;
  reg aw_pending_q;
  reg w_pending_q;
  reg [`XLEN-1:0] awaddr_q;
  reg [`XLEN-1:0] wdata_q;
  reg [`STRB_W-1:0] wstrb_q;
  reg saw_satp_commit;
  reg saw_mret_commit;
  reg saw_sfence_commit;
  reg saw_sret_commit;
  reg debug_sv39;
  reg v8a_eq_trace;
  reg [`XLEN-1:0] expected_minstret_q;
  reg [`XLEN-1:0] instret_prev_q;
  reg [1:0] instret_prev_count_q;
  reg instret_delta_valid_q;
  integer instret_delta_checks;
  integer instret_exception_lanes;
  integer instret_exception_zero_lanes;
  integer instret_mret_commits;
  integer instret_sret_commits;
  integer instret_sfence_commits;
  integer instret_control_commits;
  integer instret_control_exact_commits;

  NpcCoreTop dut (
    .clk(clk),
    .rst(rst),
    .dcache_dma_invalidate_all_i(1'b0),
    .ifu_axi_arvalid_o(ifu_axi_arvalid),
    .ifu_axi_arready_i(ifu_axi_arready),
    .ifu_axi_araddr_o(ifu_axi_araddr),
    .ifu_axi_arsize_o(ifu_axi_arsize),
    .ifu_axi_arprot_o(ifu_axi_arprot),
    .ifu_axi_rvalid_i(ifu_axi_rvalid),
    .ifu_axi_rready_o(ifu_axi_rready),
    .ifu_axi_rdata_i(ifu_axi_rdata),
    .ifu_axi_rresp_i(ifu_axi_rresp),
    .lsu_axi_arvalid_o(lsu_axi_arvalid),
    .lsu_axi_arready_i(lsu_axi_arready),
    .lsu_axi_araddr_o(lsu_axi_araddr),
    .lsu_axi_arsize_o(lsu_axi_arsize),
    .lsu_axi_rvalid_i(lsu_axi_rvalid),
    .lsu_axi_rready_o(lsu_axi_rready),
    .lsu_axi_rdata_i(lsu_axi_rdata),
    .lsu_axi_rresp_i(lsu_axi_rresp),
    .lsu_axi_awvalid_o(lsu_axi_awvalid),
    .lsu_axi_awready_i(lsu_axi_awready),
    .lsu_axi_awaddr_o(lsu_axi_awaddr),
    .lsu_axi_wvalid_o(lsu_axi_wvalid),
    .lsu_axi_wready_i(lsu_axi_wready),
    .lsu_axi_wdata_o(lsu_axi_wdata),
    .lsu_axi_wstrb_o(lsu_axi_wstrb),
    .lsu_axi_bvalid_i(lsu_axi_bvalid),
    .lsu_axi_bready_o(lsu_axi_bready),
    .lsu_axi_bresp_i(lsu_axi_bresp),
    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(1'b0),
    .mtime_i(64'd5678),
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
    .exit_pc_o(exit_pc),
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

  function [`INST_W-1:0] inst_slli;
    input [4:0] rd;
    input [4:0] rs1;
    input [5:0] shamt;
    begin
      inst_slli = {6'b000000, shamt, rs1, `FUNCT3_SLL, rd,
                   `OPCODE_OP_IMM};
    end
  endfunction

  function [`INST_W-1:0] inst_or;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_or = rv32_r(`FUNCT7_STD, rs2, rs1, `FUNCT3_OR, rd, `OPCODE_OP);
    end
  endfunction

  function [`INST_W-1:0] inst_and;
    input [4:0] rd;
    input [4:0] rs1;
    input [4:0] rs2;
    begin
      inst_and = rv32_r(`FUNCT7_STD, rs2, rs1, `FUNCT3_AND, rd,
                        `OPCODE_OP);
    end
  endfunction

  function [`INST_W-1:0] inst_auipc;
    input [4:0] rd;
    input [19:0] imm;
    begin
      inst_auipc = rv32_u(imm, rd, `OPCODE_AUIPC);
    end
  endfunction

  function [`INST_W-1:0] inst_beq;
    input [4:0] rs1;
    input [4:0] rs2;
    input [12:0] imm;
    begin
      inst_beq = rv32_b(imm, rs2, rs1, `FUNCT3_BEQ);
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

  function [`INST_W-1:0] inst_ld;
    input [4:0] rd;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_ld = rv32_i(imm, rs1, `FUNCT3_LD, rd, `OPCODE_LOAD);
    end
  endfunction

  function [`INST_W-1:0] inst_sd;
    input [4:0] rs2;
    input [4:0] rs1;
    input [11:0] imm;
    begin
      inst_sd = rv32_s(imm, rs2, rs1, `FUNCT3_SD);
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

  function [`INST_W-1:0] inst_sfence_vma;
    begin
      inst_sfence_vma = {`SYSTEM_FUNCT7_SFENCE_VMA, 5'd0, 5'd0,
                         `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
    end
  endfunction

  function [`INST_W-1:0] program_word;
    input [`XLEN-1:0] addr;
    begin
      program_word = inst_ebreak();
      case (addr)
        BASE_PC + 64'h000: program_word = inst_auipc(5'd1, 20'h00000);
        BASE_PC + 64'h004: program_word = inst_addi(5'd1, 5'd1, 12'h100);
        BASE_PC + 64'h008: program_word = inst_csrrw(5'd0, `CSR_STVEC, 5'd1);
        BASE_PC + 64'h00c: program_word = inst_addi(5'd2, 5'd0, 12'hfff);
        BASE_PC + 64'h010: program_word = inst_csrrw(5'd0, `CSR_MEDELEG, 5'd2);
        BASE_PC + 64'h014: program_word = inst_auipc(5'd3, 20'h00000);
        BASE_PC + 64'h018: program_word = inst_addi(5'd3, 5'd3, 12'h06c);
        BASE_PC + 64'h01c: program_word = inst_csrrw(5'd0, `CSR_MEPC, 5'd3);
        // 进入 S-mode 前必须显式打开 PMP，否则无匹配 PMP 项会按规范拒绝 S/U 取指。
        BASE_PC + 64'h020: program_word = inst_addi(5'd4, 5'd0, 12'hfff);
        BASE_PC + 64'h024: program_word = inst_csrrw(5'd0, `CSR_PMPADDR0, 5'd4);
        BASE_PC + 64'h028: program_word = inst_addi(5'd4, 5'd0, 12'h01f);
        BASE_PC + 64'h02c: program_word = inst_csrrw(5'd0, `CSR_PMPCFG0, 5'd4);
        BASE_PC + 64'h030: program_word = inst_addi(5'd4, 5'd0, 12'h001);
        BASE_PC + 64'h034: program_word = inst_slli(5'd4, 5'd4, 6'd11);
        BASE_PC + 64'h038: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
        BASE_PC + 64'h03c: program_word = inst_mret();

        S_ENTRY_PC + 64'h000: program_word = inst_addi(5'd4, 5'd0, 12'h008);
        S_ENTRY_PC + 64'h004: program_word = inst_slli(5'd4, 5'd4, 6'd60);
        S_ENTRY_PC + 64'h008: program_word = inst_addi(5'd5, 5'd0, 12'h001);
        S_ENTRY_PC + 64'h00c: program_word = inst_slli(5'd5, 5'd5, 6'd19);
        S_ENTRY_PC + 64'h010: program_word = inst_addi(5'd5, 5'd5, 12'h002);
        S_ENTRY_PC + 64'h014: program_word = inst_or(5'd4, 5'd4, 5'd5);
        S_ENTRY_PC + 64'h018: program_word = inst_csrrw(5'd0, `CSR_SATP, 5'd4);
        S_ENTRY_PC + 64'h01c: program_word = inst_sfence_vma();
        S_ENTRY_PC + 64'h020: program_word = inst_auipc(5'd11, 20'h00003);
        S_ENTRY_PC + 64'h024: program_word = inst_addi(5'd11, 5'd11, 12'hf60);
        S_ENTRY_PC + 64'h028: program_word = inst_addi(5'd0, 5'd0, 12'h000);
        S_ENTRY_PC + 64'h02c: program_word = inst_addi(5'd0, 5'd0, 12'h000);
        S_ENTRY_PC + 64'h030: program_word = inst_ld(5'd6, 5'd11, 12'h000);
        S_ENTRY_PC + 64'h034: program_word = inst_sd(5'd6, 5'd11, 12'h008);
        S_ENTRY_PC + 64'h038: program_word = inst_ecall();
        S_ENTRY_PC + 64'h03c: program_word = inst_addi(5'd7, 5'd0, 12'h077);
        S_ENTRY_PC + 64'h040: program_word = inst_addi(5'd12, 5'd0, 12'h001);
        S_ENTRY_PC + 64'h044: program_word = inst_slli(5'd12, 5'd12, 6'd30);
        S_ENTRY_PC + 64'h048: program_word = inst_ld(5'd13, 5'd12, 12'h000);
        S_ENTRY_PC + 64'h04c: program_word = inst_addi(5'd18, 5'd0, 12'h088);
        S_ENTRY_PC + 64'h050: program_word = inst_jalr(5'd0, 5'd12, 12'h000);
        S_ENTRY_PC + 64'h054: program_word = inst_addi(5'd18, 5'd0, 12'hee);
        S_ENTRY_PC + 64'h058: program_word = inst_addi(5'd19, 5'd0, 12'h099);
        S_ENTRY_PC + 64'h05c: program_word = inst_addi(5'd26, 5'd0, 12'h003);
        S_ENTRY_PC + 64'h060: program_word = inst_slli(5'd26, 5'd26, 6'd30);
        S_ENTRY_PC + 64'h064: program_word = inst_addi(5'd26, 5'd26, 12'h200);
        S_ENTRY_PC + 64'h068: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd26);
        S_ENTRY_PC + 64'h06c: program_word = inst_addi(5'd27, 5'd0, 12'h020);
        S_ENTRY_PC + 64'h070: program_word = inst_csrrw(5'd0, `CSR_SSTATUS, 5'd27);
        S_ENTRY_PC + 64'h074: program_word = inst_sret();
        S_ENTRY_PC + 64'h078: program_word = inst_ebreak();

        USER_ENTRY_PA + 64'h000: program_word = inst_addi(5'd26, 5'd0, 12'hab);
        USER_ENTRY_PA + 64'h004: program_word = inst_ecall();
        USER_ENTRY_PA + 64'h008: program_word = inst_addi(5'd30, 5'd0, 12'hcd);
        USER_ENTRY_PA + 64'h00c: program_word = inst_addi(5'd12, 5'd0, 12'h001);
        USER_ENTRY_PA + 64'h010: program_word = inst_slli(5'd12, 5'd12, 6'd30);
        USER_ENTRY_PA + 64'h014: program_word = inst_ld(5'd3, 5'd12, 12'h000);
        USER_ENTRY_PA + 64'h018: program_word = inst_addi(5'd4, 5'd0, 12'hef);
        USER_ENTRY_PA + 64'h01c: program_word = inst_ebreak();

        S_HANDLER_PC + 64'h000: program_word = inst_csrrs(5'd8, `CSR_SCAUSE, 5'd0);
        S_HANDLER_PC + 64'h004: program_word = inst_csrrs(5'd9, `CSR_SEPC, 5'd0);
        S_HANDLER_PC + 64'h008: program_word = inst_csrrs(5'd14, `CSR_STVAL, 5'd0);
        S_HANDLER_PC + 64'h00c: program_word = inst_addi(5'd15, 5'd0, 12'h009);
        S_HANDLER_PC + 64'h010: program_word = inst_beq(5'd8, 5'd15, 13'h01c);
        S_HANDLER_PC + 64'h014: program_word = inst_addi(5'd15, 5'd0, 12'h00d);
        S_HANDLER_PC + 64'h018: program_word = inst_beq(5'd8, 5'd15, 13'h02c);
        S_HANDLER_PC + 64'h01c: program_word = inst_addi(5'd15, 5'd0, 12'h00c);
        S_HANDLER_PC + 64'h020: program_word = inst_beq(5'd8, 5'd15, 13'h040);
        S_HANDLER_PC + 64'h024: program_word = inst_addi(5'd15, 5'd0, 12'h008);
        S_HANDLER_PC + 64'h028: program_word = inst_beq(5'd8, 5'd15, 13'h058);
        S_HANDLER_PC + 64'h02c: program_word = inst_addi(5'd16, 5'd8, 12'h000);
        S_HANDLER_PC + 64'h030: program_word = inst_addi(5'd17, 5'd9, 12'h000);
        S_HANDLER_PC + 64'h034: program_word = inst_addi(5'd9, 5'd9, 12'h004);
        S_HANDLER_PC + 64'h038: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
        S_HANDLER_PC + 64'h03c: program_word = inst_addi(5'd10, 5'd0, 12'h066);
        S_HANDLER_PC + 64'h040: program_word = inst_sret();
        S_HANDLER_PC + 64'h044: program_word = inst_csrrs(5'd27, `CSR_SSTATUS, 5'd0);
        S_HANDLER_PC + 64'h048: program_word = inst_addi(5'd15, 5'd0, 12'h100);
        S_HANDLER_PC + 64'h04c: program_word = inst_and(5'd15, 5'd27, 5'd15);
        S_HANDLER_PC + 64'h050: program_word = inst_beq(5'd15, 5'd0, 13'h050);
        S_HANDLER_PC + 64'h054: program_word = inst_beq(5'd0, 5'd0, 13'h06c);
        S_HANDLER_PC + 64'h060: program_word = inst_addi(5'd23, 5'd8, 12'h000);
        S_HANDLER_PC + 64'h064: program_word = inst_addi(5'd24, 5'd9, 12'h000);
        S_HANDLER_PC + 64'h068: program_word = inst_addi(5'd25, 5'd14, 12'h000);
        S_HANDLER_PC + 64'h06c: program_word = inst_auipc(5'd9, 20'h00000);
        S_HANDLER_PC + 64'h070: program_word = inst_addi(5'd9, 5'd9, 12'hf6c);
        S_HANDLER_PC + 64'h074: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
        S_HANDLER_PC + 64'h078: program_word = inst_addi(5'd10, 5'd0, 12'h044);
        S_HANDLER_PC + 64'h07c: program_word = inst_sret();
        S_HANDLER_PC + 64'h080: program_word = inst_csrrs(5'd5, `CSR_SSTATUS, 5'd0);
        S_HANDLER_PC + 64'h084: program_word = inst_addi(5'd28, 5'd8, 12'h000);
        S_HANDLER_PC + 64'h088: program_word = inst_addi(5'd29, 5'd9, 12'h000);
        S_HANDLER_PC + 64'h08c: program_word = inst_addi(5'd9, 5'd9, 12'h004);
        S_HANDLER_PC + 64'h090: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
        S_HANDLER_PC + 64'h094: program_word = inst_addi(5'd31, 5'd0, 12'h033);
        S_HANDLER_PC + 64'h098: program_word = inst_sret();
        S_HANDLER_PC + 64'h0a0: program_word = inst_addi(5'd11, 5'd8, 12'h000);
        S_HANDLER_PC + 64'h0a4: program_word = inst_addi(5'd12, 5'd9, 12'h000);
        S_HANDLER_PC + 64'h0a8: program_word = inst_addi(5'd13, 5'd14, 12'h000);
        S_HANDLER_PC + 64'h0ac: program_word = inst_addi(5'd9, 5'd9, 12'h004);
        S_HANDLER_PC + 64'h0b0: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
        S_HANDLER_PC + 64'h0b4: program_word = inst_addi(5'd1, 5'd0, 12'h05a);
        S_HANDLER_PC + 64'h0b8: program_word = inst_sret();
        S_HANDLER_PC + 64'h0c0: program_word = inst_addi(5'd20, 5'd8, 12'h000);
        S_HANDLER_PC + 64'h0c4: program_word = inst_addi(5'd21, 5'd9, 12'h000);
        S_HANDLER_PC + 64'h0c8: program_word = inst_addi(5'd22, 5'd14, 12'h000);
        S_HANDLER_PC + 64'h0cc: program_word = inst_addi(5'd9, 5'd9, 12'h004);
        S_HANDLER_PC + 64'h0d0: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
        S_HANDLER_PC + 64'h0d4: program_word = inst_addi(5'd10, 5'd0, 12'h055);
        S_HANDLER_PC + 64'h0d8: program_word = inst_sret();
        default: begin end
      endcase
    end
  endfunction

  function [`XLEN-1:0] read64;
    input [`XLEN-1:0] addr;
    begin
      if ((addr >= ROOT_PT) && (addr < (ROOT_PT + 64'h1000))) begin
        case (addr)
          ROOT_PT + 64'd16: read64 = SUPERPAGE_PTE;
          ROOT_PT + 64'd24: read64 = USER_SUPERPAGE_PTE;
          default:          read64 = {`XLEN{1'b0}};
        endcase
      end else if (addr == DATA_PA) begin
        read64 = DATA_VALUE;
      end else if (addr == (DATA_PA + 64'd8)) begin
        read64 = stored_data_q;
      end else begin
        read64 = {program_word(addr + 64'd4), program_word(addr)};
      end
    end
  endfunction

  task automatic write64;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    input [`STRB_W-1:0] strb;
    integer byte_idx;
    begin
      if (addr == (DATA_PA + 64'd8)) begin
        for (byte_idx = 0; byte_idx < `STRB_W; byte_idx = byte_idx + 1) begin
          if (strb[byte_idx]) begin
            stored_data_q[byte_idx*8 +: 8] = data[byte_idx*8 +: 8];
          end
        end
        data_store_writes = data_store_writes + 1;
      end
    end
  endtask

  task automatic observe_commit;
    input valid;
    input [`INST_W-1:0] inst;
    begin
      if (valid) begin
        if ((inst[6:0] == `OPCODE_SYSTEM) && (inst[14:12] != 3'b000) &&
            (inst[31:20] == `CSR_SATP)) saw_satp_commit <= 1'b1;
        if (inst == inst_mret()) saw_mret_commit <= 1'b1;
        if (inst == inst_sfence_vma()) saw_sfence_commit <= 1'b1;
        if (inst == inst_sret()) saw_sret_commit <= 1'b1;
      end
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      ifu_axi_rvalid <= 1'b0;
      ifu_axi_rdata <= {`XLEN{1'b0}};
      ifu_axi_rresp <= 2'b00;
    end else begin
      if (ifu_axi_rvalid && ifu_axi_rready) ifu_axi_rvalid <= 1'b0;
      if (ifu_axi_arvalid && ifu_axi_arready) begin
        if (ifu_axi_arprot[2] && (ifu_axi_arsize !== 3'd1)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] IFU instruction AR size got=%0d expected=1",
                   ifu_axi_arsize);
        end
        if (!ifu_axi_arprot[2] && (ifu_axi_arsize !== 3'd3)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] IFU PTW AR size got=%0d expected=3",
                   ifu_axi_arsize);
        end
        ifu_axi_rvalid <= 1'b1;
        // instruction narrow transfer 返回标准 AXI byte lanes；PTE 地址本就 8B 对齐。
        ifu_axi_rdata <= read64({ifu_axi_araddr[`XLEN-1:3], 3'b000});
        ifu_axi_rresp <= 2'b00;
        if (ifu_axi_araddr == (ROOT_PT + 64'd16)) begin
          ifu_page_walk_reads = ifu_page_walk_reads + 1;
        end
        if (ifu_axi_araddr == (ROOT_PT + 64'd8)) begin
          ifu_fault_walk_reads = ifu_fault_walk_reads + 1;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      lsu_axi_rvalid <= 1'b0;
      lsu_axi_rdata <= {`XLEN{1'b0}};
      lsu_axi_rresp <= 2'b00;
      lsu_axi_bvalid <= 1'b0;
      lsu_axi_bresp <= 2'b00;
      aw_pending_q <= 1'b0;
      w_pending_q <= 1'b0;
      awaddr_q <= {`XLEN{1'b0}};
      wdata_q <= {`XLEN{1'b0}};
      wstrb_q <= {`STRB_W{1'b0}};
    end else begin
      if (lsu_axi_rvalid && lsu_axi_rready) lsu_axi_rvalid <= 1'b0;
      if (lsu_axi_arvalid && lsu_axi_arready) begin
        if (lsu_axi_arsize !== 3'd3) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] LSU sv39 AR size got=0x%0x expected=0x%0x",
                   lsu_axi_arsize, 3'd3);
        end
        lsu_axi_rvalid <= 1'b1;
        lsu_axi_rdata <= read64(lsu_axi_araddr);
        lsu_axi_rresp <= 2'b00;
        if (lsu_axi_araddr == (ROOT_PT + 64'd16)) begin
          lsu_page_walk_reads = lsu_page_walk_reads + 1;
        end
        if (lsu_axi_araddr == (ROOT_PT + 64'd8)) begin
          lsu_fault_walk_reads = lsu_fault_walk_reads + 1;
        end
        if (lsu_axi_araddr == DATA_PA) begin
          data_load_reads = data_load_reads + 1;
        end
      end
      if (lsu_axi_bvalid && lsu_axi_bready) lsu_axi_bvalid <= 1'b0;
      if (lsu_axi_awvalid && lsu_axi_awready) begin
        aw_pending_q <= 1'b1;
        awaddr_q <= lsu_axi_awaddr;
      end
      if (lsu_axi_wvalid && lsu_axi_wready) begin
        w_pending_q <= 1'b1;
        wdata_q <= lsu_axi_wdata;
        wstrb_q <= lsu_axi_wstrb;
      end
      if (!lsu_axi_bvalid &&
          ((aw_pending_q || (lsu_axi_awvalid && lsu_axi_awready)) &&
           (w_pending_q || (lsu_axi_wvalid && lsu_axi_wready)))) begin
        write64((lsu_axi_awvalid && lsu_axi_awready) ? lsu_axi_awaddr : awaddr_q,
                (lsu_axi_wvalid && lsu_axi_wready) ? lsu_axi_wdata : wdata_q,
                (lsu_axi_wvalid && lsu_axi_wready) ? lsu_axi_wstrb : wstrb_q);
        aw_pending_q <= 1'b0;
        w_pending_q <= 1'b0;
        lsu_axi_bvalid <= 1'b1;
        lsu_axi_bresp <= 2'b00;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      expected_minstret_q <= {`XLEN{1'b0}};
      instret_prev_q <= {`XLEN{1'b0}};
      instret_prev_count_q <= 2'd0;
      instret_delta_valid_q <= 1'b0;
      instret_delta_checks <= 0;
      instret_exception_lanes <= 0;
      instret_exception_zero_lanes <= 0;
      instret_mret_commits <= 0;
      instret_sret_commits <= 0;
      instret_sfence_commits <= 0;
      instret_control_commits <= 0;
      instret_control_exact_commits <= 0;
    end else begin
      // 独立从最终可见退休 lane 计数；异常 lane 不属于 minstret。
      // 该 oracle 跨越 mret/sret/sfence/ecall/page-fault，防止隐藏退休源
      // 或前级“完成数”再次污染 CsrFile 的单一计数源。
      expected_minstret_q <= expected_minstret_q +
          {{(`XLEN-1){1'b0}}, commit0_valid && !commit0_exception} +
          {{(`XLEN-1){1'b0}}, commit1_valid && !commit1_exception};
      observe_commit(commit0_valid, commit0_inst);
      observe_commit(commit1_valid, commit1_inst);

      // INSTRET-G1 program-level contract.  This checker samples only the
      // final visible commit interface and the architectural minstret state.
      if (retire_count !==
          ({1'b0, commit0_valid && !commit0_exception} +
           {1'b0, commit1_valid && !commit1_exception})) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] INSTRET final-lane population count cyc=%0d count=%0d c0=%b/%b c1=%b/%b",
                 cycle_count, retire_count,
                 commit0_valid, commit0_exception,
                 commit1_valid, commit1_exception);
      end
      if (retire_count === 2'b11) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] INSTRET count uses invalid encoding 3 cyc=%0d",
                 cycle_count);
      end

      // CsrFile applies the previous edge's final count.  No instruction in
      // this program writes minstret or sets mcountinhibit.IR.
      if (instret_delta_valid_q) begin
        instret_delta_checks <= instret_delta_checks + 1;
        if (dut.u_csr_file.csr_minstret_q !==
            (instret_prev_q +
             {{(`XLEN-2){1'b0}}, instret_prev_count_q})) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] INSTRET CsrFile edge delta cyc=%0d old=%0d count=%0d got=%0d",
                   cycle_count, instret_prev_q, instret_prev_count_q,
                   dut.u_csr_file.csr_minstret_q);
        end
      end
      instret_prev_q <= dut.u_csr_file.csr_minstret_q;
      instret_prev_count_q <= retire_count;
      instret_delta_valid_q <= 1'b1;

      instret_exception_lanes <= instret_exception_lanes +
          ((commit0_valid && commit0_exception) ? 1 : 0) +
          ((commit1_valid && commit1_exception) ? 1 : 0);
      if (commit0_valid && commit0_exception) begin
        if (!commit1_valid && (retire_count == 2'd0)) begin
          instret_exception_zero_lanes <= instret_exception_zero_lanes + 1;
        end else begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] INSTRET lane0 precise exception must add zero and suppress lane1 cyc=%0d count=%0d c1=%b",
                   cycle_count, retire_count, commit1_valid);
        end
      end
      if (commit1_valid && commit1_exception) begin
        if (retire_count == {1'b0, commit0_valid && !commit0_exception}) begin
          instret_exception_zero_lanes <= instret_exception_zero_lanes + 1;
        end else begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] INSTRET lane1 exception contributed to count cyc=%0d count=%0d c0=%b/%b",
                   cycle_count, retire_count, commit0_valid, commit0_exception);
        end
      end

      instret_mret_commits <= instret_mret_commits +
          ((commit0_valid && (commit0_inst == inst_mret())) ? 1 : 0) +
          ((commit1_valid && (commit1_inst == inst_mret())) ? 1 : 0);
      instret_sret_commits <= instret_sret_commits +
          ((commit0_valid && (commit0_inst == inst_sret())) ? 1 : 0) +
          ((commit1_valid && (commit1_inst == inst_sret())) ? 1 : 0);
      instret_sfence_commits <= instret_sfence_commits +
          ((commit0_valid && (commit0_inst == inst_sfence_vma())) ? 1 : 0) +
          ((commit1_valid && (commit1_inst == inst_sfence_vma())) ? 1 : 0);
      if (commit0_valid &&
          ((commit0_inst == inst_mret()) ||
           (commit0_inst == inst_sret()) ||
           (commit0_inst == inst_sfence_vma()))) begin
        instret_control_commits <= instret_control_commits + 1;
        if (!commit0_exception && !commit1_valid && (retire_count == 2'd1)) begin
          instret_control_exact_commits <= instret_control_exact_commits + 1;
        end else begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] INSTRET control pseudo-commit must be one non-exception lane cyc=%0d inst=%08x count=%0d ex=%b c1=%b",
                   cycle_count, commit0_inst, retire_count,
                   commit0_exception, commit1_valid);
        end
      end
      if (commit1_valid &&
          ((commit1_inst == inst_mret()) ||
           (commit1_inst == inst_sret()) ||
           (commit1_inst == inst_sfence_vma()))) begin
        instret_control_commits <= instret_control_commits + 1;
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] INSTRET control pseudo-commit appeared on lane1 cyc=%0d inst=%08x",
                 cycle_count, commit1_inst);
      end
    end
  end

  always @(posedge clk) begin
    // Candidate-vs-pre-snapshot equivalence uses only the pre-existing
    // NpcCoreTop ABI.  The runner extracts these deterministic lines and
    // compares them byte-for-byte for release and OOO_ASSERT builds.
    if (v8a_eq_trace && !rst) begin
      $display("[S2-Q2-V8A-OLD-ABI-TRACE] cyc=%0d ifu=%b:%016x:%0d:%0d:%b lsu_r=%b:%016x:%0d:%b lsu_w=%b:%016x:%b:%016x:%02x:%b c0=%b:%016x:%08x:%016x:%b:%0d:%016x:%b:%b c1=%b:%016x:%08x:%016x:%b:%0d:%016x:%b:%b trap=%b:%0d:%016x:%016x exit=%b:%b:%b:%016x:%016x halt=%b dbg=%016x:%0d rc=%0d fc=%0d rob=%0d iq=%0d gprs=%h",
               cycle_count,
               ifu_axi_arvalid, ifu_axi_araddr, ifu_axi_arsize,
               ifu_axi_arprot, ifu_axi_rready,
               lsu_axi_arvalid, lsu_axi_araddr, lsu_axi_arsize,
               lsu_axi_rready,
               lsu_axi_awvalid, lsu_axi_awaddr, lsu_axi_wvalid,
               lsu_axi_wdata, lsu_axi_wstrb, lsu_axi_bready,
               commit0_valid, commit0_pc, commit0_inst, commit0_next_pc,
               commit0_rd_en, commit0_rd_addr, commit0_rd_data,
               commit0_exception, commit0_write,
               commit1_valid, commit1_pc, commit1_inst, commit1_next_pc,
               commit1_rd_en, commit1_rd_addr, commit1_rd_data,
               commit1_exception, commit1_write,
               trap_valid, trap_cause, trap_pc, trap_tval,
               exit_valid, exit_is_ecall, exit_is_ebreak, exit_code,
               exit_pc, halted, debug_pc, debug_state, retire_count,
               free_count, rob_count, issue_count, debug_gprs);
    end
    if (debug_sv39 && !rst) begin
      if (commit0_valid || commit1_valid ||
          dut.u_ooo_core.pending_system_capture_head0_w ||
          dut.u_ooo_core.pending_system_capture_lane1_w ||
          dut.u_ooo_core.system_csr_dispatch_fire_w ||
          dut.u_ooo_core.pending_system_csr_commit_w ||
          dut.u_ooo_core.pending_system_clear_w ||
          dut.u_ooo_core.csr_trap_mem_valid_w ||
          (cycle_count < 64)) begin
        $display("[DBG-SV39] cyc=%0d pc=%016x st=%0d c0=%b:%08x c1=%b:%08x priv=%0d mstatus=%016x satp=%016x ret=%016x mret=%b/%b trapcause=%0d run=%b fifo=%b disp=%b irq=%b ff0=%b ff1=%b bspec=%b/%b stop=%b be=%b ctrl=%b drain=%b ctrap=%b dflush=%b owners=%b%b%b%b%b%b psys=%b/%b csr=%b pc=%016x inst=%08x hpc=%016x hinst=%08x h0stop=%b h0sys=%b h0trap=%b h1stop=%b h1ctl=%b h1mem=%b unsup=%b bar1=%b cap0=%b cap1=%b fire=%b commit=%b clr=%b trap=%b exit=%b",
                 cycle_count, debug_pc, debug_state,
                 commit0_valid, commit0_inst, commit1_valid, commit1_inst,
                 dut.u_ooo_core.csr_priv_mode_w,
                 dut.u_ooo_core.csr_mstatus_w,
                 dut.u_ooo_core.csr_satp_w,
                 dut.u_ooo_core.csr_ret_target_w,
                 dut.u_ooo_core.csr_mret_valid_w,
                 dut.u_ooo_core.csr_real_mret_valid_w,
                 dut.u_ooo_core.csr_trap_mem_cause_w,
                 dut.u_ooo_core.can_run_w,
                 dut.u_ooo_core.fifo_has_packet_w,
                 dut.u_ooo_core.dispatch_valid_w,
                 dut.u_ooo_core.csr_irq_pending_w,
                 dut.u_ooo_core.head_fetch_fault0_w,
                 dut.u_ooo_core.head_fetch_fault1_w,
                 dut.u_ooo_core.branch_spec_active_q,
                 dut.u_ooo_core.branch_spec_dispatch_block_w,
                 dut.u_ooo_core.stop_pending_q,
                 dut.u_ooo_core.backend_drained_w,
                 dut.u_ooo_core.pending_control_ready_w,
                 dut.u_ooo_core.drain_complete_w,
                 dut.u_ooo_core.csr_trap_mem_valid_w,
                 dut.u_ooo_core.direct_frontend_flush_w,
                 dut.u_ooo_core.pending_exit_q,
                 dut.u_ooo_core.pending_arch_trap_q,
                 dut.u_ooo_core.pending_branch_q,
                 dut.u_ooo_core.pending_jump_q,
                 dut.u_ooo_core.pending_mem_q,
                 1'b0,  // pending_fp_q: pending-FP 壳已拆, 占位保持格式对齐
                 dut.u_ooo_core.pending_system_q,
                 dut.u_ooo_core.pending_system_dispatched_q,
                 dut.u_ooo_core.pending_system_csr_q,
                 dut.u_ooo_core.pending_system_pc_q,
                 dut.u_ooo_core.pending_system_inst_q,
                 dut.u_ooo_core.head_pc_w,
                 dut.u_ooo_core.head_inst0_w,
                 dut.u_ooo_core.head0_stop_raw_w,
                 dut.u_ooo_core.head0_system_raw_w,
                 dut.u_ooo_core.head0_arch_trap_raw_w,
                 dut.u_ooo_core.head1_stop_raw_w,
                 dut.u_ooo_core.head1_control_raw_w,
                 dut.u_ooo_core.head1_mem_raw_w,
                 dut.u_ooo_core.dispatch_unsupported_w,
                 dut.u_ooo_core.dispatch1_barrier_fire_w,
                 dut.u_ooo_core.pending_system_capture_head0_w,
                 dut.u_ooo_core.pending_system_capture_lane1_w,
                 dut.u_ooo_core.system_csr_dispatch_fire_w,
                 dut.u_ooo_core.pending_system_csr_commit_w,
                 dut.u_ooo_core.pending_system_clear_w,
                 trap_valid, exit_valid);
      end
    end
  end

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    ifu_axi_arready = 1'b1;
    lsu_axi_arready = 1'b1;
    lsu_axi_awready = 1'b1;
    lsu_axi_wready = 1'b1;
    ifu_page_walk_reads = 0;
    lsu_page_walk_reads = 0;
    ifu_fault_walk_reads = 0;
    lsu_fault_walk_reads = 0;
    data_load_reads = 0;
    data_store_writes = 0;
    stored_data_q = {`XLEN{1'b0}};
    saw_satp_commit = 1'b0;
    saw_mret_commit = 1'b0;
    saw_sfence_commit = 1'b0;
    saw_sret_commit = 1'b0;
    debug_sv39 = $test$plusargs("debug_sv39");
    v8a_eq_trace = $test$plusargs("S2_Q2_V8A_EQ_TRACE");
    cycle_count = 0;
    `TB_TICK(clk);
    rst = 1'b0;
    #1;

    while (!exit_valid && !trap_valid && cycle_count < 4000) begin
      `TB_TICK(clk);
      cycle_count = cycle_count + 1;
    end

    if (cycle_count >= 4000) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] timeout waiting for sv39 boot exit");
    end
    tb_check1("sv39 boot reaches ebreak exit", exit_valid, 1'b1);
    tb_check1("sv39 boot exits via ebreak", exit_is_ebreak, 1'b1);
    tb_check1("sv39 boot no fatal trap", trap_valid, 1'b0);
    tb_check1("satp commit observed", saw_satp_commit, 1'b1);
    tb_check1("mret commit observed", saw_mret_commit, 1'b1);
    tb_check1("sfence commit observed", saw_sfence_commit, 1'b1);
    tb_check1("sret commit observed", saw_sret_commit, 1'b1);
    tb_check64("sv39 load value", gpr(5'd6), DATA_VALUE);
    tb_check64("sv39 store value", stored_data_q, DATA_VALUE);
    tb_check64("s-mode final scause snapshot", gpr(5'd23),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_INST_PAGE_FAULT});
    tb_check64("s-mode final sepc snapshot", gpr(5'd24),
               64'h0000_0000_4000_0000);
    tb_check64("s-mode final stval snapshot", gpr(5'd25),
               64'h0000_0000_4000_0000);
    tb_check64("s-mode ecall scause snapshot", gpr(5'd16),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_SMODE});
    tb_check64("s-mode ecall sepc snapshot", gpr(5'd17),
               S_ENTRY_PC + 64'h038);
    tb_check64("s-mode load page fault scause", gpr(5'd20),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_LOAD_PAGE_FAULT});
    tb_check64("s-mode load page fault sepc", gpr(5'd21),
               S_ENTRY_PC + 64'h048);
    tb_check64("s-mode load page fault stval", gpr(5'd22),
               64'h0000_0000_4000_0000);
    tb_check64("s-mode inst page fault scause", gpr(5'd23),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_INST_PAGE_FAULT});
    tb_check64("s-mode inst page fault sepc", gpr(5'd24),
               64'h0000_0000_4000_0000);
    tb_check64("s-mode inst page fault stval", gpr(5'd25),
               64'h0000_0000_4000_0000);
    tb_check64("s-mode handler final body executed", gpr(5'd10), 64'h44);
    tb_check64("post sret body executed", gpr(5'd7), 64'h77);
    tb_check64("post load page fault body executed", gpr(5'd18), 64'h88);
    tb_check64("post inst page fault body executed", gpr(5'd19), 64'h99);
    tb_check64("u-mode body executed before ecall", gpr(5'd26), 64'hab);
    tb_check64("u-mode ecall scause", gpr(5'd28),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_ECALL_UMODE});
    tb_check64("u-mode ecall sepc", gpr(5'd29), USER_ENTRY_VA + 64'h004);
    tb_check64("u-mode ecall recorded spp clear",
               gpr(5'd5) & `MSTATUS_SPP, 64'h0);
    tb_check64("u-mode returned after sret", gpr(5'd30), 64'hcd);
    tb_check64("u-mode handler marker", gpr(5'd31), 64'h33);
    tb_check64("u-mode load page fault scause", gpr(5'd11),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_LOAD_PAGE_FAULT});
    tb_check64("u-mode load page fault sepc", gpr(5'd12),
               USER_ENTRY_VA + 64'h014);
    tb_check64("u-mode load page fault stval", gpr(5'd13),
               64'h0000_0000_4000_0000);
    tb_check64("u-mode load page fault recorded spp clear",
               gpr(5'd27) & `MSTATUS_SPP, 64'h0);
    tb_check64("u-mode returned after load page fault", gpr(5'd4), 64'hef);
    tb_check64("u-mode load fault handler marker", gpr(5'd1), 64'h5a);
    tb_check64("minstret equals final non-exception commit lanes",
               dut.u_csr_file.csr_minstret_q, expected_minstret_q);
    if (instret_delta_checks == 0) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] INSTRET CsrFile edge-delta checker was vacuous");
    end
    if ((instret_exception_lanes != 2) ||
        (instret_exception_zero_lanes != instret_exception_lanes)) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] INSTRET exception coverage expected=2 lanes=%0d zero_delta=%0d",
               instret_exception_lanes, instret_exception_zero_lanes);
    end
    if ((instret_mret_commits != 1) || (instret_sret_commits != 6) ||
        (instret_sfence_commits != 1) ||
        (instret_control_commits != 8) ||
        (instret_control_exact_commits != 8)) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] INSTRET control coverage expected=1/6/1/8 mret=%0d sret=%0d sfence=%0d exact=%0d total=%0d",
               instret_mret_commits, instret_sret_commits,
               instret_sfence_commits, instret_control_exact_commits,
               instret_control_commits);
    end
    if (ifu_page_walk_reads == 0) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] IFU page-table walk was not observed");
    end
    if (lsu_page_walk_reads == 0) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] LSU page-table walk was not observed");
    end
    if (lsu_fault_walk_reads == 0) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] LSU faulting page-table walk was not observed");
    end
    if (ifu_fault_walk_reads == 0) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] IFU faulting page-table walk was not observed");
    end
    if (data_load_reads == 0 || data_store_writes == 0) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] translated data load/store not observed load=%0d store=%0d",
               data_load_reads, data_store_writes);
    end
    $display("[INFO] sv39 page walks ifu=%0d ifu_fault=%0d lsu=%0d lsu_fault=%0d data_load=%0d data_store=%0d",
             ifu_page_walk_reads, ifu_fault_walk_reads, lsu_page_walk_reads,
             lsu_fault_walk_reads, data_load_reads, data_store_writes);
    // Canonical dual-memory routes DATA and DATA+8 to different banks.  Each
    // bridge owns a private DTLB, so the translated load and store seed one
    // walk per bank; neither may repeat within its bank.
    if (lsu_page_walk_reads != 2) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] dual-bank private DTLBs should issue exactly two data walks, lsu_walk=%0d",
               lsu_page_walk_reads);
    end
    if (ifu_page_walk_reads > 4) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] ITLB should bound same-superpage instruction walks, ifu_walk=%0d",
               ifu_page_walk_reads);
    end

    if (tb_errors == 0) begin
      $display("[INSTRET-G1-PROGRAM] exception_lanes=%0d exception_zero_delta=%0d mret=%0d sret=%0d sfence_vma=%0d control_exact=%0d control_total=%0d csr_delta_checks=%0d PASS",
               instret_exception_lanes, instret_exception_zero_lanes,
               instret_mret_commits, instret_sret_commits,
               instret_sfence_commits, instret_control_exact_commits,
               instret_control_commits, instret_delta_checks);
    end else begin
      $display("[INSTRET-G1-PROGRAM] exception_lanes=%0d exception_zero_delta=%0d mret=%0d sret=%0d sfence_vma=%0d control_exact=%0d control_total=%0d csr_delta_checks=%0d FAIL",
               instret_exception_lanes, instret_exception_zero_lanes,
               instret_mret_commits, instret_sret_commits,
               instret_sfence_commits, instret_control_exact_commits,
               instret_control_commits, instret_delta_checks);
    end

    tb_finish("tb_ooo_sv39_boot");
  end

  wire unused_w =
      (|commit0_pc) | (|commit0_next_pc) |
      commit0_rd_en | (|commit0_rd_addr) | (|commit0_rd_data) |
      commit0_exception | commit0_write | commit1_rd_en |
      (|commit1_pc) | (|commit1_next_pc) | (|commit1_rd_addr) |
      (|commit1_rd_data) | commit1_exception | commit1_write |
      (|trap_cause) | (|trap_pc) | (|trap_tval) |
      exit_is_ecall | (|exit_code) | (|exit_pc) | halted |
      (|debug_pc) | (|debug_state) | (|retire_count) |
      (|free_count) | (|rob_count) | (|issue_count);

endmodule
