`include "define.v"

module tb_npc_core_interrupt;
  `include "tb_common.svh"
  `include "rv32_encode.svh"

  reg clk;
  reg rst;
  wire ifu_axi_arvalid;
  reg ifu_axi_arready;
  wire [`XLEN-1:0] ifu_axi_araddr;
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
  wire [3:0] lsu_axi_wstrb;
  reg lsu_axi_bvalid;
  wire lsu_axi_bready;
  reg [1:0] lsu_axi_bresp;
  reg irq_timer;
  wire commit_valid;
  wire [`XLEN-1:0] commit_pc;
  wire [`INST_W-1:0] commit_inst;
  wire [`XLEN-1:0] commit_next_pc;
  wire commit_rd_en;
  wire [`REG_ADDR_W-1:0] commit_rd_addr;
  wire [`XLEN-1:0] commit_rd_data;
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

  reg ifu_pending;
  reg [`XLEN-1:0] ifu_pending_data;
  integer cycle;
  integer saw_cause;
  integer saw_mepc;
  integer saw_mstatus;
  integer saw_interrupted_commit;

  NpcCore dut (
    .clk(clk),
    .rst(rst),
    .ifu_axi_arvalid_o(ifu_axi_arvalid),
    .ifu_axi_arready_i(ifu_axi_arready),
    .ifu_axi_araddr_o(ifu_axi_araddr),
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
    .irq_timer_i(irq_timer),
    .irq_external_i(1'b0),
    .commit_valid_o(commit_valid),
    .commit_pc_o(commit_pc),
    .commit_inst_o(commit_inst),
    .commit_next_pc_o(commit_next_pc),
    .commit_rd_en_o(commit_rd_en),
    .commit_rd_addr_o(commit_rd_addr),
    .commit_rd_data_o(commit_rd_data),
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
    .debug_gprs_o(debug_gprs)
  );

  function [31:0] csr_read;
    input [11:0] csr;
    input [4:0] rd;
    begin
      csr_read = rv32_i(csr, 5'd0, 3'b010, rd, `OPCODE_SYSTEM);
    end
  endfunction

  function [31:0] csr_write;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      csr_write = rv32_i(csr, rs1, 3'b001, 5'd0, `OPCODE_SYSTEM);
    end
  endfunction

  function [31:0] csr_set;
    input [11:0] csr;
    input [4:0] rs1;
    begin
      csr_set = rv32_i(csr, rs1, 3'b010, 5'd0, `OPCODE_SYSTEM);
    end
  endfunction

  function [`XLEN-1:0] imem_word;
    input [`XLEN-1:0] addr;
    begin
      case (addr)
        32'h8000_0000: imem_word = rv32_i(12'd1, 5'd0, `FUNCT3_ADD_SUB, 5'd1, `OPCODE_OP_IMM);
        32'h8000_0004: imem_word = rv32_u(20'h80000, 5'd2, `OPCODE_LUI);
        32'h8000_0008: imem_word = rv32_i(12'h100, 5'd2, `FUNCT3_ADD_SUB, 5'd2, `OPCODE_OP_IMM);
        32'h8000_000c: imem_word = csr_write(`CSR_MTVEC, 5'd2);
        32'h8000_0010: imem_word = rv32_i(12'h080, 5'd0, `FUNCT3_ADD_SUB, 5'd3, `OPCODE_OP_IMM);
        32'h8000_0014: imem_word = csr_write(`CSR_MIE, 5'd3);
        32'h8000_0018: imem_word = rv32_i(12'h008, 5'd0, `FUNCT3_ADD_SUB, 5'd4, `OPCODE_OP_IMM);
        32'h8000_001c: imem_word = csr_set(`CSR_MSTATUS, 5'd4);
        32'h8000_0020: imem_word = rv32_i(12'h055, 5'd0, `FUNCT3_ADD_SUB, 5'd5, `OPCODE_OP_IMM);
        32'h8000_0100: imem_word = csr_read(`CSR_MCAUSE, 5'd6);
        32'h8000_0104: imem_word = csr_read(`CSR_MEPC, 5'd7);
        32'h8000_0108: imem_word = csr_read(`CSR_MSTATUS, 5'd8);
        32'h8000_010c: imem_word = 32'h0000_0013;
        32'h8000_0110: imem_word = {12'h001, 5'd0, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
        default:       imem_word = 32'h0000_0013;
      endcase
    end
  endfunction

  task automatic step_core;
    reg next_ifu_pending;
    reg [`XLEN-1:0] next_ifu_data;
    begin
      ifu_axi_rvalid = ifu_pending;
      ifu_axi_rdata = ifu_pending_data;
      ifu_axi_rresp = 2'b00;
      lsu_axi_rvalid = 1'b0;
      lsu_axi_rdata = 32'h0;
      lsu_axi_rresp = 2'b00;
      lsu_axi_bvalid = 1'b0;
      lsu_axi_bresp = 2'b00;

      next_ifu_pending = ifu_axi_arvalid && ifu_axi_arready;
      next_ifu_data = imem_word(ifu_axi_araddr);

      `TB_TICK(clk);

      ifu_pending = next_ifu_pending;
      ifu_pending_data = next_ifu_data;

      if (commit_valid) begin
        if (commit_pc == 32'h8000_0020)
          saw_interrupted_commit = 1;
        if (commit_pc == 32'h8000_0100) begin
          saw_cause = 1;
          tb_check1("mcause interrupt rd_en", commit_rd_en, 1'b1);
          tb_check32("mcause interrupt rd", {27'b0, commit_rd_addr}, 32'd6);
          tb_check32("mcause timer interrupt", commit_rd_data, `MCAUSE_INTERRUPT | 32'd7);
        end else if (commit_pc == 32'h8000_0104) begin
          saw_mepc = 1;
          tb_check32("mepc interrupted pc", commit_rd_data, 32'h8000_0020);
        end else if (commit_pc == 32'h8000_0108) begin
          saw_mstatus = 1;
          tb_check32("mstatus trap stack", commit_rd_data, `MSTATUS_MPIE | `MSTATUS_MPP_M);
        end
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    ifu_axi_arready = 1'b1;
    ifu_axi_rvalid = 1'b0;
    ifu_axi_rdata = 32'h0;
    ifu_axi_rresp = 2'b00;
    lsu_axi_arready = 1'b1;
    lsu_axi_rvalid = 1'b0;
    lsu_axi_rdata = 32'h0;
    lsu_axi_rresp = 2'b00;
    lsu_axi_awready = 1'b1;
    lsu_axi_wready = 1'b1;
    lsu_axi_bvalid = 1'b0;
    lsu_axi_bresp = 2'b00;
    irq_timer = 1'b1;
    ifu_pending = 1'b0;
    ifu_pending_data = 32'h0;
    saw_cause = 0;
    saw_mepc = 0;
    saw_mstatus = 0;
    saw_interrupted_commit = 0;

    repeat (2) step_core();
    rst = 1'b0;

    for (cycle = 0; cycle < 500 && !exit_valid && !trap_valid; cycle = cycle + 1) begin
      step_core();
    end

    tb_check1("handler read mcause", saw_cause != 0, 1'b1);
    tb_check1("handler read mepc", saw_mepc != 0, 1'b1);
    tb_check1("handler read mstatus", saw_mstatus != 0, 1'b1);
    tb_check1("interrupted instruction not committed", saw_interrupted_commit != 0, 1'b0);
    tb_check1("no fatal trap", trap_valid, 1'b0);
    tb_check1("exit via ebreak", exit_valid & exit_is_ebreak, 1'b1);
    tb_check1("no data-side axi read", lsu_axi_arvalid, 1'b0);
    tb_check1("no data-side axi write", lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);

    tb_finish("tb_npc_core_interrupt");
  end
endmodule
