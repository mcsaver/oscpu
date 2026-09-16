`include "define.v"
`include "rv32_encode.svh"

// The actual NpcCoreTop fetches and executes this program over its normal AXI
// port. Nothing drives internal valid/ready signals or bypasses the I-cache.
// One cold traversal warms the cache; eight fixed windows each cover 64
// consecutive clocks, beginning at the same PC on subsequent traversals.
module tb_ooo_core_ideal_ipc;
  `include "tb_common.svh"
  localparam [63:0] BASE_PC = 64'h8000_0000;
  localparam integer BODY_BYTES = 1024;
  localparam integer WINDOW_CYCLES = 64;
  localparam integer WINDOWS = 8;

  reg clk = 0;
  reg rst = 1;
  wire arvalid, arready, rready;
  wire [63:0] araddr;
  reg rvalid = 0;
  reg [63:0] rdata = 0;
  wire c0valid, c1valid, c0wen, c1wen, c0exception, c1exception;
  wire [63:0] c0pc, c1pc, c0data, c1data;
  wire [31:0] c0inst, c1inst;
  wire [4:0] c0rd, c1rd;
  wire trap, halted, exited;
  wire lsu_arvalid, lsu_awvalid, lsu_wvalid, ifu_awvalid, ifu_wvalid;
  integer cycles = 0;
  integer wraps = 0;
  integer measured_windows = 0;
  integer window_cycles = 0;
  integer window_commits = 0;
  integer measured_cycles = 0;
  integer measured_commits = 0;
  integer retired = 0;
  reg measuring = 0;
  reg [63:0] expected_pc = BASE_PC;

  NpcCoreTop dut (
    .clk(clk), .rst(rst), .dcache_dma_invalidate_all_i(1'b0),
    .tensor_cmd_ready_i(1'b1), .tensor_terminal_valid_i(1'b0),
    .tensor_terminal_producer_id_i({`OOO_PRODUCER_ID_W{1'b0}}),
    .tensor_terminal_error_i(1'b0), .tensor_terminal_error_code_i(8'd0),
    .ifu_axi_arvalid_o(arvalid), .ifu_axi_arready_i(arready),
    .ifu_axi_araddr_o(araddr), .ifu_axi_rvalid_i(rvalid),
    .ifu_axi_rready_o(rready), .ifu_axi_rdata_i(rdata),
    .ifu_axi_rresp_i(2'b00),
    .ifu_axi_awvalid_o(ifu_awvalid), .ifu_axi_awready_i(1'b1),
    .ifu_axi_wvalid_o(ifu_wvalid), .ifu_axi_wready_i(1'b1),
    .ifu_axi_bvalid_i(1'b0), .ifu_axi_bresp_i(2'b00),
    .lsu_axi_arvalid_o(lsu_arvalid), .lsu_axi_arready_i(1'b1),
    .lsu_axi_rvalid_i(1'b0), .lsu_axi_rdata_i(64'd0),
    .lsu_axi_rresp_i(2'b00), .lsu_axi_awvalid_o(lsu_awvalid),
    .lsu_axi_awready_i(1'b1), .lsu_axi_wvalid_o(lsu_wvalid),
    .lsu_axi_wready_i(1'b1), .lsu_axi_bvalid_i(1'b0),
    .lsu_axi_bresp_i(2'b00),
    .irq_software_i(1'b0), .irq_timer_i(1'b0), .irq_external_i(1'b0),
    .mtime_i(64'd0),
    .commit0_valid_o(c0valid), .commit0_pc_o(c0pc),
    .commit0_inst_o(c0inst), .commit0_rd_en_o(c0wen),
    .commit0_rd_addr_o(c0rd), .commit0_rd_data_o(c0data),
    .commit0_exception_o(c0exception),
    .commit1_valid_o(c1valid), .commit1_pc_o(c1pc),
    .commit1_inst_o(c1inst), .commit1_rd_en_o(c1wen),
    .commit1_rd_addr_o(c1rd), .commit1_rd_data_o(c1data),
    .commit1_exception_o(c1exception),
    .trap_valid_o(trap), .halted_o(halted), .exit_valid_o(exited)
  );

  function [31:0] program_word;
    input [63:0] pc;
    integer idx;
    reg [4:0] rd;
    begin
      idx = (pc - BASE_PC) >> 2;
      rd = 8 + (idx % 24);
      if (pc >= BASE_PC && pc < BASE_PC + BODY_BYTES)
        program_word = rv32_i(idx[11:0], 5'd0, 3'b000, rd, `OPCODE_OP_IMM);
      else if (pc == BASE_PC + BODY_BYTES)
        program_word = rv32_j(21'h1ffc00, 5'd0); // JAL x0, -1024
      else
        program_word = 32'h0000_0013;
    end
  endfunction

  // One registered response slot, with legal turnover and payload hold.
  assign arready = !rvalid || rready;
  always @(posedge clk) begin
    if (rst)
      rvalid <= 0;
    else begin
      if (rvalid && rready)
        rvalid <= 0;
      if (arvalid && arready) begin
        rvalid <= 1;
        rdata <= {program_word({araddr[63:3],3'b000} + 4),
                  program_word({araddr[63:3],3'b000})};
      end
    end
  end

  task check_retire;
    input valid;
    input [63:0] pc;
    input [31:0] inst;
    input wen;
    input [4:0] rd;
    input [63:0] data;
    input exception;
    integer idx;
    begin
      if (valid) begin
        retired = retired + 1;
        if (pc !== expected_pc || inst !== program_word(pc) || exception) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] retirement pc=%h expected=%h inst=%h exception=%b",
                   pc, expected_pc, inst, exception);
        end
        if (pc == BASE_PC + BODY_BYTES) begin
          wraps = wraps + 1;
          expected_pc = BASE_PC;
        end else begin
          idx = (pc - BASE_PC) >> 2;
          if (!wen || rd != (8 + (idx % 24)) || data !== {32'd0,idx[31:0]}) begin
            tb_errors = tb_errors + 1;
            $display("[CHECK-FAIL] architectural result pc=%h rd=%d data=%h",pc,rd,data);
          end
          expected_pc = pc + 4;
        end
      end
    end
  endtask

  always @(posedge clk) begin
    if (!rst) begin
      cycles = cycles + 1;
      if (trap || halted || exited ||
          lsu_arvalid || lsu_awvalid || lsu_wvalid || ifu_awvalid || ifu_wvalid) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] unexpected trap, termination, or data access");
      end
      // The boundary is chosen by program PC, never by observed throughput.
      if (!measuring && wraps > measured_windows &&
          ((c0valid && c0pc == BASE_PC + 128) ||
           (c1valid && c1pc == BASE_PC + 128))) begin
        measuring = 1;
        window_cycles = 0;
        window_commits = 0;
      end
      if (measuring) begin
        window_cycles = window_cycles + 1;
        window_commits = window_commits + c0valid + c1valid;
        measured_cycles = measured_cycles + 1;
        measured_commits = measured_commits + c0valid + c1valid;
        if (!(c0valid && c1valid)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] ideal flow bubble window=%0d cycle=%0d commits=%b%b",
                   measured_windows,window_cycles,c1valid,c0valid);
        end
        if (window_cycles == WINDOW_CYCLES) begin
          $display("[IDEAL-IPC] window=%0d cycles=%0d commits=%0d",
                   measured_windows,window_cycles,window_commits);
          measured_windows = measured_windows + 1;
          measuring = 0;
        end
      end
      check_retire(c0valid,c0pc,c0inst,c0wen,c0rd,c0data,c0exception);
      check_retire(c1valid,c1pc,c1inst,c1wen,c1rd,c1data,c1exception);
    end
  end

  initial begin
    tb_errors = 0;
    `TB_TICK(clk);
    rst = 0;
    while (measured_windows < WINDOWS && cycles < 20000) begin
      `TB_TICK(clk);
    end
    if (measured_windows != WINDOWS || measured_cycles != WINDOWS * WINDOW_CYCLES ||
        measured_commits != 2 * measured_cycles)
      tb_errors = tb_errors + 1;
    $display("[IDEAL-CPI] windows=%0d cycles=%0d commits=%0d total_cycles=%0d total_retired=%0d",
             measured_windows,measured_cycles,measured_commits,cycles,retired);
    tb_finish("tb_ooo_core_ideal_ipc");
  end
endmodule
