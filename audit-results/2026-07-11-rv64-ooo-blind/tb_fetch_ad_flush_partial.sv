`timescale 1ns/1ps
`include "define.v"

module tb_fetch_ad_flush_partial;
  reg clk = 1'b0;
  reg rst = 1'b1;
  reg mmu_flush = 1'b0;
  reg awready = 1'b0;
  reg wready = 1'b0;
  wire awvalid;
  wire wvalid;
  wire bready;
  wire [63:0] awaddr;
  wire [63:0] wdata;

  always #5 clk = ~clk;

  OooFetchAxiBridge dut (
    .clk(clk), .rst(rst), .mmu_flush_i(mmu_flush),
    .invalidate_valid_i(1'b0), .invalidate_addr_i(64'b0),
    .priv_mode_i(`PRIV_S), .satp_i(64'b0), .svpbmt_en_i(1'b0),
    .pmpcfg_i({`PMP_CFG_BUS_W{1'b0}}),
    .pmpaddr_i({`PMP_ADDR_BUS_W{1'b0}}),
    .fetch_req_valid_i(1'b0), .fetch_req_pc_i(64'b0),
    .fetch_rsp_ready_i(1'b0), .ifu_axi_arready_i(1'b0),
    .ifu_axi_rvalid_i(1'b0), .ifu_axi_rdata_i(64'b0),
    .ifu_axi_rresp_i(2'b00),
    .ifu_axi_awvalid_o(awvalid), .ifu_axi_awready_i(awready),
    .ifu_axi_awaddr_o(awaddr), .ifu_axi_wvalid_o(wvalid),
    .ifu_axi_wready_i(wready), .ifu_axi_wdata_o(wdata),
    .ifu_axi_bvalid_i(1'b0), .ifu_axi_bready_o(bready),
    .ifu_axi_bresp_i(2'b00)
  );

  initial begin
    repeat (2) @(posedge clk);
    #1 rst = 1'b0;
    @(negedge clk);

    // Deposit an A-bit update with independently accepted AXI write channels.
    dut.state_q = 4'd8;                 // S_AD_UPDATE
    dut.walk_ppn_q = 44'h20;
    dut.walk_level_q = 2'd0;
    dut.pc_q = 64'h0000_0000_8000_1000;
    dut.ad_pte_q = 64'h0000_0000_1234_004f;
    dut.aw_done_q = 1'b0;
    dut.w_done_q = 1'b0;
    awready = 1'b1;
    wready = 1'b0;

    @(posedge clk);
    #1 awready = 1'b0;
    if (!dut.aw_done_q || dut.w_done_q || dut.state_q != 4'd8) begin
      $display("SETUP_FAIL state=%0d aw_done=%0d w_done=%0d",
               dut.state_q, dut.aw_done_q, dut.w_done_q);
      $finish_and_return(2);
    end

    // Flush after AW was accepted but before W. The bridge forgets the partial write.
    mmu_flush = 1'b1;
    @(posedge clk);
    #1 mmu_flush = 1'b0;

    if (dut.state_q == 4'd0 && !dut.aw_done_q && !dut.w_done_q &&
        !awvalid && !wvalid && !bready) begin
      $display("BUG_REPRODUCED aw_accepted_then_flush state=%0d awv=%0d wv=%0d br=%0d",
               dut.state_q, awvalid, wvalid, bready);
      $finish_and_return(0);
    end

    $display("BUG_NOT_REPRODUCED state=%0d aw_done=%0d w_done=%0d awv=%0d wv=%0d br=%0d",
             dut.state_q, dut.aw_done_q, dut.w_done_q, awvalid, wvalid, bready);
    $finish_and_return(1);
  end
endmodule
