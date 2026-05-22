`include "define.v"

module tb_npc_core_mcycle;
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
  reg [`XLEN-1:0] frozen_mcycle_low;
  integer cycle;
  integer saw_mcycle_low;
  integer saw_mcycle_high;
  integer saw_cycle_low;
  integer saw_cycle_high;
  integer saw_inhibit;
  integer saw_resume;
  integer saw_mvendorid;
  integer saw_marchid;

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
      // 读 CSR 使用标准 CSRRS rd, csr, x0，确保只读 CSR 不被误判为写操作。
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
        32'h8000_0004: imem_word = csr_set(`CSR_MCOUNTINHIBIT, 5'd1);
        32'h8000_0008: imem_word = rv32_i(12'h123, 5'd0, `FUNCT3_ADD_SUB, 5'd2, `OPCODE_OP_IMM);
        32'h8000_000c: imem_word = csr_write(`CSR_MCYCLE, 5'd2);
        32'h8000_0010: imem_word = rv32_i(12'd5, 5'd0, `FUNCT3_ADD_SUB, 5'd3, `OPCODE_OP_IMM);
        32'h8000_0014: imem_word = csr_write(`CSR_MCYCLEH, 5'd3);
        32'h8000_0018: imem_word = csr_read(`CSR_MCYCLE, 5'd4);
        32'h8000_001c: imem_word = csr_read(`CSR_MCYCLEH, 5'd5);
        32'h8000_0020: imem_word = csr_read(`CSR_CYCLE, 5'd6);
        32'h8000_0024: imem_word = csr_read(`CSR_CYCLEH, 5'd7);
        32'h8000_0028: imem_word = csr_read(`CSR_MCOUNTINHIBIT, 5'd8);
        32'h8000_002c: imem_word = csr_write(`CSR_MCOUNTINHIBIT, 5'd0);
        32'h8000_0030: imem_word = 32'h0000_0013;
        32'h8000_0034: imem_word = csr_read(`CSR_MCYCLE, 5'd9);
        32'h8000_0038: imem_word = 32'h0000_0013;
        32'h8000_003c: imem_word = csr_read(`CSR_MVENDORID, 5'd10);
        32'h8000_0040: imem_word = csr_read(`CSR_MARCHID, 5'd11);
        32'h8000_0044: imem_word = 32'h0000_0013;
        32'h8000_0048: imem_word = 32'h0000_0013;
        32'h8000_004c: imem_word = csr_write(`CSR_CYCLE, 5'd0);
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
        case (commit_pc)
          32'h8000_0018: begin
            saw_mcycle_low = 1;
            frozen_mcycle_low = commit_rd_data;
            tb_check1("mcycle read rd_en", commit_rd_en, 1'b1);
            tb_check32("mcycle read rd", {27'b0, commit_rd_addr}, 32'd4);
            tb_check32("mcycle low after write", commit_rd_data, 32'h0000_0123);
          end
          32'h8000_001c: begin
            saw_mcycle_high = 1;
            tb_check32("mcycleh high after write", commit_rd_data, 32'h0000_0005);
          end
          32'h8000_0020: begin
            saw_cycle_low = 1;
            tb_check32("cycle shadow low", commit_rd_data, frozen_mcycle_low);
          end
          32'h8000_0024: begin
            saw_cycle_high = 1;
            tb_check32("cycleh shadow high", commit_rd_data, 32'h0000_0005);
          end
          32'h8000_0028: begin
            saw_inhibit = 1;
            tb_check32("mcountinhibit only CY", commit_rd_data, `MCOUNTINHIBIT_CY);
          end
          32'h8000_0034: begin
            saw_resume = 1;
            if (!(commit_rd_data > frozen_mcycle_low)) begin
              tb_errors = tb_errors + 1;
              $display("[CHECK-FAIL] mcycle did not resume incrementing: got=%08x frozen=%08x",
                       commit_rd_data, frozen_mcycle_low);
            end
          end
          32'h8000_003c: begin
            saw_mvendorid = 1;
            tb_check32("mvendorid ysyx ascii", commit_rd_data, 32'h7973_7978);
          end
          32'h8000_0040: begin
            saw_marchid = 1;
            tb_check32("marchid student decimal", commit_rd_data, 32'd26010035);
          end
          default: begin end
        endcase
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
    ifu_pending = 1'b0;
    ifu_pending_data = 32'h0;
    frozen_mcycle_low = 32'h0;
    saw_mcycle_low = 0;
    saw_mcycle_high = 0;
    saw_cycle_low = 0;
    saw_cycle_high = 0;
    saw_inhibit = 0;
    saw_resume = 0;
    saw_mvendorid = 0;
    saw_marchid = 0;

    repeat (2) step_core();
    rst = 1'b0;

    for (cycle = 0; cycle < 340 && !trap_valid; cycle = cycle + 1) begin
      step_core();
    end

    tb_check1("saw mcycle low read", saw_mcycle_low != 0, 1'b1);
    tb_check1("saw mcycleh read", saw_mcycle_high != 0, 1'b1);
    tb_check1("saw cycle shadow read", saw_cycle_low != 0, 1'b1);
    tb_check1("saw cycleh shadow read", saw_cycle_high != 0, 1'b1);
    tb_check1("saw mcountinhibit read", saw_inhibit != 0, 1'b1);
    tb_check1("saw mcycle resume read", saw_resume != 0, 1'b1);
    tb_check1("saw mvendorid csr read", saw_mvendorid != 0, 1'b1);
    tb_check1("saw marchid csr read", saw_marchid != 0, 1'b1);
    tb_check1("cycle write raises trap", trap_valid, 1'b1);
    tb_check32("cycle write trap cause", {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_cause}, `EXC_ILLEGAL_INST);
    tb_check32("cycle write trap pc", trap_pc, 32'h8000_004c);
    tb_check1("no data-side axi read", lsu_axi_arvalid, 1'b0);
    tb_check1("no data-side axi write", lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);

    tb_finish("tb_npc_core_mcycle");
  end
endmodule
