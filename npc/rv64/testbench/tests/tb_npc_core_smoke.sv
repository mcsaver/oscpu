`include "define.v"

module tb_npc_core_smoke;
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
  reg lsu_pending;
  reg [`XLEN-1:0] lsu_pending_data;
  integer cycle;
  integer commits;
  integer ifu_seen;
  integer lsu_reads;
  integer saw_exit;

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
    .irq_timer_i(1'b0),
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

  function [`XLEN-1:0] imem_word;
    input [`XLEN-1:0] addr;
    begin
      case (addr)
        32'h8000_0000: imem_word = rv32_u(20'h80002, 5'd1, `OPCODE_LUI);
        32'h8000_0004: imem_word = rv32_i(12'd7, 5'd0, `FUNCT3_ADD_SUB, 5'd3, `OPCODE_OP_IMM);
        32'h8000_0008: imem_word = rv32_i(12'd0, 5'd1, `FUNCT3_LW, 5'd2, `OPCODE_LOAD);
        32'h8000_000c: imem_word = rv32_r(`FUNCT7_MULDIV, 5'd3, 5'd2, `FUNCT3_ADD_SUB, 5'd10, `OPCODE_OP);
        32'h8000_0010: imem_word = {12'h001, 5'd0, `FUNCT3_ADD_SUB, 5'd0, `OPCODE_SYSTEM};
        default:       imem_word = 32'h0000_0013;
      endcase
    end
  endfunction

  function [`XLEN-1:0] dmem_word;
    input [`XLEN-1:0] addr;
    begin
      case (addr)
        32'h8000_2000: dmem_word = 32'd6;
        default:       dmem_word = 32'h0;
      endcase
    end
  endfunction

  task automatic step_core;
    reg next_ifu_pending;
    reg [`XLEN-1:0] next_ifu_data;
    reg next_lsu_pending;
    reg [`XLEN-1:0] next_lsu_data;
    begin
      ifu_axi_rvalid = ifu_pending;
      ifu_axi_rdata = ifu_pending_data;
      ifu_axi_rresp = 2'b00;
      lsu_axi_rvalid = lsu_pending;
      lsu_axi_rdata = lsu_pending_data;
      lsu_axi_rresp = 2'b00;
      lsu_axi_bvalid = 1'b0;
      lsu_axi_bresp = 2'b00;

      next_ifu_pending = ifu_axi_arvalid && ifu_axi_arready;
      next_ifu_data = imem_word(ifu_axi_araddr);
      if (next_ifu_pending && (ifu_seen < 16)) begin
        tb_check32("core fill request addr", ifu_axi_araddr, 32'h8000_0000 + (ifu_seen << 2));
        ifu_seen = ifu_seen + 1;
      end
      next_lsu_pending = lsu_axi_arvalid && lsu_axi_arready;
      next_lsu_data = dmem_word(lsu_axi_araddr);
      if (next_lsu_pending) begin
        lsu_reads = lsu_reads + 1;
      end

      `TB_TICK(clk);

      ifu_pending = next_ifu_pending;
      ifu_pending_data = next_ifu_data;
      lsu_pending = next_lsu_pending;
      lsu_pending_data = next_lsu_data;

      if (commit_valid) begin
        commits = commits + 1;
        if (commit_pc == 32'h8000_0000) begin
          tb_check1("commit x1 write", commit_rd_en, 1'b1);
          tb_check32("commit x1 rd", {27'b0, commit_rd_addr}, 32'd1);
          tb_check32("commit x1 data", commit_rd_data, 32'h8000_2000);
        end else if (commit_pc == 32'h8000_0004) begin
          tb_check32("commit x3 data", commit_rd_data, 32'd7);
        end else if (commit_pc == 32'h8000_0008) begin
          tb_check32("commit x2 data", commit_rd_data, 32'd6);
        end else if (commit_pc == 32'h8000_000c) begin
          tb_check32("commit x10 rd", {27'b0, commit_rd_addr}, 32'd10);
          tb_check32("commit x10 data", commit_rd_data, 32'd42);
        end
      end
      if (exit_valid && exit_is_ebreak) begin
        saw_exit = 1;
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
    lsu_pending = 1'b0;
    lsu_pending_data = 32'h0;
    commits = 0;
    ifu_seen = 0;
    lsu_reads = 0;
    saw_exit = 0;

    repeat (2) step_core();
    rst = 1'b0;

    for (cycle = 0; cycle < 220 && !saw_exit && !trap_valid; cycle = cycle + 1) begin
      step_core();
    end

    tb_check1("no fatal trap during first fill", trap_valid, 1'b0);
    tb_check1("ebreak observed", saw_exit[0], 1'b1);
    tb_check1("no data-side axi write in fetch smoke", lsu_axi_awvalid | lsu_axi_wvalid, 1'b0);
    if (ifu_seen != 16) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] expected 16 first-line fetch requests, got %0d", ifu_seen);
    end
    if (lsu_reads == 0) begin
      tb_errors = tb_errors + 1;
      $display("[CHECK-FAIL] expected at least one data-side line fill read");
    end

    tb_finish("tb_npc_core_smoke");
  end
endmodule
