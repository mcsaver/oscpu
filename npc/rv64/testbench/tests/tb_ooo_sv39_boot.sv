`include "define.v"
`include "tb_common.svh"
`include "rv32_encode.svh"

module tb_ooo_sv39_boot;
  reg clk;
  reg rst;

  wire ifu_axi_arvalid;
  reg ifu_axi_arready;
  wire [`XLEN-1:0] ifu_axi_araddr;
  wire ifu_axi_abort;
  reg ifu_axi_rvalid;
  wire ifu_axi_rready;
  reg [`XLEN-1:0] ifu_axi_rdata;
  reg [1:0] ifu_axi_rresp;

  wire lsu_axi_arvalid;
  reg lsu_axi_arready;
  wire [`XLEN-1:0] lsu_axi_araddr;
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
  localparam [`XLEN-1:0] ROOT_PT = 64'h0000_0000_8000_2000;
  localparam [`XLEN-1:0] DATA_PA = 64'h0000_0000_8000_3000;
  localparam [`XLEN-1:0] DATA_VALUE = 64'h1122_3344_5566_7788;
  localparam [`XLEN-1:0] ROOT_PPN = ROOT_PT >> 12;
  localparam [`XLEN-1:0] SUPERPAGE_PPN = BASE_PC >> 12;
  localparam [`XLEN-1:0] LEAF_FLAGS = 64'h0cf;
  localparam [`XLEN-1:0] SUPERPAGE_PTE =
      (SUPERPAGE_PPN << 10) | LEAF_FLAGS;

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
  reg saw_sfence_commit;
  reg saw_sret_commit;

  NpcCoreTop dut (
    .clk(clk),
    .rst(rst),
    .ifu_axi_arvalid_o(ifu_axi_arvalid),
    .ifu_axi_arready_i(ifu_axi_arready),
    .ifu_axi_araddr_o(ifu_axi_araddr),
    .ifu_axi_abort_o(ifu_axi_abort),
    .ifu_axi_rvalid_i(ifu_axi_rvalid),
    .ifu_axi_rready_o(ifu_axi_rready),
    .ifu_axi_rdata_i(ifu_axi_rdata),
    .ifu_axi_rresp_i(ifu_axi_rresp),
    .lsu_axi_arvalid_o(lsu_axi_arvalid),
    .lsu_axi_arready_i(lsu_axi_arready),
    .lsu_axi_araddr_o(lsu_axi_araddr),
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
        BASE_PC + 64'h020: program_word = inst_addi(5'd4, 5'd0, 12'h001);
        BASE_PC + 64'h024: program_word = inst_slli(5'd4, 5'd4, 6'd11);
        BASE_PC + 64'h028: program_word = inst_csrrw(5'd0, `CSR_MSTATUS, 5'd4);
        BASE_PC + 64'h02c: program_word = inst_mret();

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
        S_ENTRY_PC + 64'h05c: program_word = inst_ebreak();

        S_HANDLER_PC + 64'h000: program_word = inst_csrrs(5'd8, `CSR_SCAUSE, 5'd0);
        S_HANDLER_PC + 64'h004: program_word = inst_csrrs(5'd9, `CSR_SEPC, 5'd0);
        S_HANDLER_PC + 64'h008: program_word = inst_csrrs(5'd14, `CSR_STVAL, 5'd0);
        S_HANDLER_PC + 64'h00c: program_word = inst_addi(5'd15, 5'd0, 12'h009);
        S_HANDLER_PC + 64'h010: program_word = inst_beq(5'd8, 5'd15, 13'h01c);
        S_HANDLER_PC + 64'h014: program_word = inst_addi(5'd15, 5'd0, 12'h00d);
        S_HANDLER_PC + 64'h018: program_word = inst_beq(5'd8, 5'd15, 13'h02c);
        S_HANDLER_PC + 64'h01c: program_word = inst_addi(5'd15, 5'd0, 12'h00c);
        S_HANDLER_PC + 64'h020: program_word = inst_beq(5'd8, 5'd15, 13'h040);
        S_HANDLER_PC + 64'h024: program_word = inst_addi(5'd10, 5'd0, 12'h07f);
        S_HANDLER_PC + 64'h028: program_word = inst_sret();
        S_HANDLER_PC + 64'h02c: program_word = inst_addi(5'd16, 5'd8, 12'h000);
        S_HANDLER_PC + 64'h030: program_word = inst_addi(5'd17, 5'd9, 12'h000);
        S_HANDLER_PC + 64'h034: program_word = inst_addi(5'd9, 5'd9, 12'h004);
        S_HANDLER_PC + 64'h038: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
        S_HANDLER_PC + 64'h03c: program_word = inst_addi(5'd10, 5'd0, 12'h066);
        S_HANDLER_PC + 64'h040: program_word = inst_sret();
        S_HANDLER_PC + 64'h044: program_word = inst_addi(5'd20, 5'd8, 12'h000);
        S_HANDLER_PC + 64'h048: program_word = inst_addi(5'd21, 5'd9, 12'h000);
        S_HANDLER_PC + 64'h04c: program_word = inst_addi(5'd22, 5'd14, 12'h000);
        S_HANDLER_PC + 64'h050: program_word = inst_addi(5'd9, 5'd9, 12'h004);
        S_HANDLER_PC + 64'h054: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
        S_HANDLER_PC + 64'h058: program_word = inst_addi(5'd10, 5'd0, 12'h055);
        S_HANDLER_PC + 64'h05c: program_word = inst_sret();
        S_HANDLER_PC + 64'h060: program_word = inst_addi(5'd23, 5'd8, 12'h000);
        S_HANDLER_PC + 64'h064: program_word = inst_addi(5'd24, 5'd9, 12'h000);
        S_HANDLER_PC + 64'h068: program_word = inst_addi(5'd25, 5'd14, 12'h000);
        S_HANDLER_PC + 64'h06c: program_word = inst_auipc(5'd9, 20'h00000);
        S_HANDLER_PC + 64'h070: program_word = inst_addi(5'd9, 5'd9, 12'hf6c);
        S_HANDLER_PC + 64'h074: program_word = inst_csrrw(5'd0, `CSR_SEPC, 5'd9);
        S_HANDLER_PC + 64'h078: program_word = inst_addi(5'd10, 5'd0, 12'h044);
        S_HANDLER_PC + 64'h07c: program_word = inst_sret();
        default: begin end
      endcase
    end
  endfunction

  function [`XLEN-1:0] read64;
    input [`XLEN-1:0] addr;
    begin
      if ((addr >= ROOT_PT) && (addr < (ROOT_PT + 64'h1000))) begin
        read64 = (addr == (ROOT_PT + 64'd16)) ? SUPERPAGE_PTE :
                                                   {`XLEN{1'b0}};
      end else if (addr == DATA_PA) begin
        read64 = DATA_VALUE;
      end else if (addr == (DATA_PA + 64'd8)) begin
        read64 = stored_data_q;
      end else begin
        read64 = {{(`XLEN-`INST_W){1'b0}}, program_word(addr)};
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
        ifu_axi_rvalid <= 1'b1;
        ifu_axi_rdata <= read64(ifu_axi_araddr);
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
    if (!rst) begin
      observe_commit(commit0_valid, commit0_inst);
      observe_commit(commit1_valid, commit1_inst);
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
    saw_sfence_commit = 1'b0;
    saw_sret_commit = 1'b0;
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
    tb_check1("sfence commit observed", saw_sfence_commit, 1'b1);
    tb_check1("sret commit observed", saw_sret_commit, 1'b1);
    tb_check64("sv39 load value", gpr(5'd6), DATA_VALUE);
    tb_check64("sv39 store value", stored_data_q, DATA_VALUE);
    tb_check64("s-mode final scause", gpr(5'd8),
               {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `EXC_INST_PAGE_FAULT});
    tb_check64("s-mode final sepc redirected", gpr(5'd9),
               S_ENTRY_PC + 64'h058);
    tb_check64("s-mode final stval", gpr(5'd14), 64'h0000_0000_4000_0000);
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

    tb_finish("tb_ooo_sv39_boot");
  end

  wire unused_w =
      ifu_axi_abort | (|commit0_pc) | (|commit0_next_pc) |
      commit0_rd_en | (|commit0_rd_addr) | (|commit0_rd_data) |
      commit0_exception | commit0_write | commit1_rd_en |
      (|commit1_pc) | (|commit1_next_pc) | (|commit1_rd_addr) |
      (|commit1_rd_data) | commit1_exception | commit1_write |
      (|trap_cause) | (|trap_pc) | (|trap_tval) |
      exit_is_ecall | (|exit_code) | (|exit_pc) | halted |
      (|debug_pc) | (|debug_state) | (|retire_count) |
      (|free_count) | (|rob_count) | (|issue_count);

endmodule
