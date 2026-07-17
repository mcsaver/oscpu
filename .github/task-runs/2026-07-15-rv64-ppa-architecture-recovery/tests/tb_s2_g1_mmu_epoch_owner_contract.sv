`timescale 1ns/1ps
`include "define.v"

module tb_s2_g1_mmu_epoch_owner_contract;
  reg clk;
  reg rst;
  reg context_quiet;
  reg owner_live_empty;
  reg sfence_commit;
  reg [1:0] priv_mode;
  reg [63:0] satp;
  reg [63:0] mstatus;
  reg pbmte;
  reg [`PMP_CFG_BUS_W-1:0] pmpcfg;
  reg [`PMP_ADDR_BUS_W-1:0] pmpaddr;
  wire initialized;
  wire capture_block;
  wire [1:0] mmu_epoch;

  OooMmuEpochOwner dut (
    .clk(clk),
    .rst(rst),
    .context_quiet_i(context_quiet),
    .owner_live_empty_i(owner_live_empty),
    .sfence_commit_i(sfence_commit),
    .priv_mode_i(priv_mode),
    .satp_i(satp),
    .mstatus_i(mstatus),
    .pbmte_i(pbmte),
    .pmpcfg_i(pmpcfg),
    .pmpaddr_i(pmpaddr),
    .initialized_o(initialized),
    .capture_block_o(capture_block),
    .mmu_epoch_o(mmu_epoch)
  );

  always #5 clk = ~clk;

  task fail;
    input [8*96-1:0] msg;
    begin
      $display("[S2-G1-EPOCH][FAIL] %0s", msg);
      $fatal(1);
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    context_quiet = 1'b1;
    owner_live_empty = 1'b1;
    sfence_commit = 1'b0;
    priv_mode = 2'b11;
    satp = 64'b0;
    mstatus = 64'b0;
    pbmte = 1'b0;
    pmpcfg = {`PMP_CFG_BUS_W{1'b0}};
    pmpaddr = {`PMP_ADDR_BUS_W{1'b0}};
    repeat (2) @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
    #1;
    if (!initialized || capture_block || mmu_epoch != 2'b00)
      fail("initial context sample must not consume an epoch");

    @(negedge clk);
    context_quiet = 1'b0;
    satp = 64'h8000000000000001;
    @(posedge clk);
    #1;
    if (!capture_block || mmu_epoch != 2'b00)
      fail("non-quiet effective change advanced or failed to block capture");

    @(negedge clk);
    context_quiet = 1'b1;
    @(posedge clk);
    #1;
    if (capture_block || mmu_epoch != 2'b01)
      fail("quiet effective change did not advance exactly once");

    @(negedge clk);
    owner_live_empty = 1'b0;
    sfence_commit = 1'b1;
    @(posedge clk);
    #1;
    if (!capture_block || mmu_epoch != 2'b01)
      fail("SFENCE advanced while a live owner existed");
    @(negedge clk);
    sfence_commit = 1'b0;
    owner_live_empty = 1'b1;
    @(posedge clk);
    #1;
    if (capture_block || mmu_epoch != 2'b10)
      fail("pending SFENCE did not advance at the first owner-empty quiet edge");

    repeat (4) begin
      @(negedge clk);
      satp[3:0] = satp[3:0] + 4'd1;
      @(posedge clk);
      #1;
    end
    if (mmu_epoch != 2'b10)
      fail("four quiet effective changes did not wrap modulo four");

    $display("[S2-G1-EPOCH][PASS] effective-change/quiet/owner-empty epoch contract");
    $finish;
  end
endmodule
