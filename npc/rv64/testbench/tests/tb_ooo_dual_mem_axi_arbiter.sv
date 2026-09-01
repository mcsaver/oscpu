`timescale 1ns/1ps
`include "define.v"

module tb_ooo_dual_mem_axi_arbiter;
  reg clk;
  reg rst;

  reg lane0_axi_arvalid_i;
  wire lane0_axi_arready_o;
  reg [`XLEN-1:0] lane0_axi_araddr_i;
  reg [3:0] lane0_axi_arid_i;
  reg [7:0] lane0_axi_arlen_i;
  reg [2:0] lane0_axi_arsize_i;
  reg [1:0] lane0_axi_arburst_i;
  reg [2:0] lane0_axi_arprot_i;
  wire lane0_axi_rvalid_o;
  reg lane0_axi_rready_i;
  wire [`XLEN-1:0] lane0_axi_rdata_o;
  wire [1:0] lane0_axi_rresp_o;
  reg lane0_axi_awvalid_i;
  wire lane0_axi_awready_o;
  reg [`XLEN-1:0] lane0_axi_awaddr_i;
  reg [3:0] lane0_axi_awid_i;
  reg [7:0] lane0_axi_awlen_i;
  reg [2:0] lane0_axi_awsize_i;
  reg [1:0] lane0_axi_awburst_i;
  reg lane0_axi_wvalid_i;
  wire lane0_axi_wready_o;
  reg [`XLEN-1:0] lane0_axi_wdata_i;
  reg [`STRB_W-1:0] lane0_axi_wstrb_i;
  reg lane0_axi_wlast_i;
  wire lane0_axi_bvalid_o;
  reg lane0_axi_bready_i;
  wire [1:0] lane0_axi_bresp_o;

  reg lane1_axi_arvalid_i;
  wire lane1_axi_arready_o;
  reg [`XLEN-1:0] lane1_axi_araddr_i;
  reg [3:0] lane1_axi_arid_i;
  reg [7:0] lane1_axi_arlen_i;
  reg [2:0] lane1_axi_arsize_i;
  reg [1:0] lane1_axi_arburst_i;
  reg [2:0] lane1_axi_arprot_i;
  wire lane1_axi_rvalid_o;
  reg lane1_axi_rready_i;
  wire [`XLEN-1:0] lane1_axi_rdata_o;
  wire [1:0] lane1_axi_rresp_o;
  reg lane1_axi_awvalid_i;
  wire lane1_axi_awready_o;
  reg [`XLEN-1:0] lane1_axi_awaddr_i;
  reg [3:0] lane1_axi_awid_i;
  reg [7:0] lane1_axi_awlen_i;
  reg [2:0] lane1_axi_awsize_i;
  reg [1:0] lane1_axi_awburst_i;
  reg lane1_axi_wvalid_i;
  wire lane1_axi_wready_o;
  reg [`XLEN-1:0] lane1_axi_wdata_i;
  reg [`STRB_W-1:0] lane1_axi_wstrb_i;
  reg lane1_axi_wlast_i;
  wire lane1_axi_bvalid_o;
  reg lane1_axi_bready_i;
  wire [1:0] lane1_axi_bresp_o;

  wire d_axi_arvalid_o;
  reg d_axi_arready_i;
  wire [`XLEN-1:0] d_axi_araddr_o;
  wire [3:0] d_axi_arid_o;
  wire [7:0] d_axi_arlen_o;
  wire [2:0] d_axi_arsize_o;
  wire [1:0] d_axi_arburst_o;
  wire [2:0] d_axi_arprot_o;
  reg d_axi_rvalid_i;
  wire d_axi_rready_o;
  reg [`XLEN-1:0] d_axi_rdata_i;
  reg [1:0] d_axi_rresp_i;
  wire d_axi_awvalid_o;
  reg d_axi_awready_i;
  wire [`XLEN-1:0] d_axi_awaddr_o;
  wire [3:0] d_axi_awid_o;
  wire [7:0] d_axi_awlen_o;
  wire [2:0] d_axi_awsize_o;
  wire [1:0] d_axi_awburst_o;
  wire d_axi_wvalid_o;
  reg d_axi_wready_i;
  wire [`XLEN-1:0] d_axi_wdata_o;
  wire [`STRB_W-1:0] d_axi_wstrb_o;
  wire d_axi_wlast_o;
  reg d_axi_bvalid_i;
  wire d_axi_bready_o;
  reg [1:0] d_axi_bresp_i;

  OooDualMemAxiArbiter dut (
    .clk(clk), .rst(rst),
    .lane0_axi_arvalid_i(lane0_axi_arvalid_i),
    .lane0_axi_arready_o(lane0_axi_arready_o),
    .lane0_axi_araddr_i(lane0_axi_araddr_i),
    .lane0_axi_arid_i(lane0_axi_arid_i),
    .lane0_axi_arlen_i(lane0_axi_arlen_i),
    .lane0_axi_arsize_i(lane0_axi_arsize_i),
    .lane0_axi_arburst_i(lane0_axi_arburst_i),
    .lane0_axi_arprot_i(lane0_axi_arprot_i),
    .lane0_axi_rvalid_o(lane0_axi_rvalid_o),
    .lane0_axi_rready_i(lane0_axi_rready_i),
    .lane0_axi_rdata_o(lane0_axi_rdata_o),
    .lane0_axi_rresp_o(lane0_axi_rresp_o),
    .lane0_axi_awvalid_i(lane0_axi_awvalid_i),
    .lane0_axi_awready_o(lane0_axi_awready_o),
    .lane0_axi_awaddr_i(lane0_axi_awaddr_i),
    .lane0_axi_awid_i(lane0_axi_awid_i),
    .lane0_axi_awlen_i(lane0_axi_awlen_i),
    .lane0_axi_awsize_i(lane0_axi_awsize_i),
    .lane0_axi_awburst_i(lane0_axi_awburst_i),
    .lane0_axi_wvalid_i(lane0_axi_wvalid_i),
    .lane0_axi_wready_o(lane0_axi_wready_o),
    .lane0_axi_wdata_i(lane0_axi_wdata_i),
    .lane0_axi_wstrb_i(lane0_axi_wstrb_i),
    .lane0_axi_wlast_i(lane0_axi_wlast_i),
    .lane0_axi_bvalid_o(lane0_axi_bvalid_o),
    .lane0_axi_bready_i(lane0_axi_bready_i),
    .lane0_axi_bresp_o(lane0_axi_bresp_o),
    .lane1_axi_arvalid_i(lane1_axi_arvalid_i),
    .lane1_axi_arready_o(lane1_axi_arready_o),
    .lane1_axi_araddr_i(lane1_axi_araddr_i),
    .lane1_axi_arid_i(lane1_axi_arid_i),
    .lane1_axi_arlen_i(lane1_axi_arlen_i),
    .lane1_axi_arsize_i(lane1_axi_arsize_i),
    .lane1_axi_arburst_i(lane1_axi_arburst_i),
    .lane1_axi_arprot_i(lane1_axi_arprot_i),
    .lane1_axi_rvalid_o(lane1_axi_rvalid_o),
    .lane1_axi_rready_i(lane1_axi_rready_i),
    .lane1_axi_rdata_o(lane1_axi_rdata_o),
    .lane1_axi_rresp_o(lane1_axi_rresp_o),
    .lane1_axi_awvalid_i(lane1_axi_awvalid_i),
    .lane1_axi_awready_o(lane1_axi_awready_o),
    .lane1_axi_awaddr_i(lane1_axi_awaddr_i),
    .lane1_axi_awid_i(lane1_axi_awid_i),
    .lane1_axi_awlen_i(lane1_axi_awlen_i),
    .lane1_axi_awsize_i(lane1_axi_awsize_i),
    .lane1_axi_awburst_i(lane1_axi_awburst_i),
    .lane1_axi_wvalid_i(lane1_axi_wvalid_i),
    .lane1_axi_wready_o(lane1_axi_wready_o),
    .lane1_axi_wdata_i(lane1_axi_wdata_i),
    .lane1_axi_wstrb_i(lane1_axi_wstrb_i),
    .lane1_axi_wlast_i(lane1_axi_wlast_i),
    .lane1_axi_bvalid_o(lane1_axi_bvalid_o),
    .lane1_axi_bready_i(lane1_axi_bready_i),
    .lane1_axi_bresp_o(lane1_axi_bresp_o),
    .d_axi_arvalid_o(d_axi_arvalid_o),
    .d_axi_arready_i(d_axi_arready_i),
    .d_axi_araddr_o(d_axi_araddr_o),
    .d_axi_arid_o(d_axi_arid_o),
    .d_axi_arlen_o(d_axi_arlen_o),
    .d_axi_arsize_o(d_axi_arsize_o),
    .d_axi_arburst_o(d_axi_arburst_o),
    .d_axi_arprot_o(d_axi_arprot_o),
    .d_axi_rvalid_i(d_axi_rvalid_i),
    .d_axi_rready_o(d_axi_rready_o),
    .d_axi_rdata_i(d_axi_rdata_i),
    .d_axi_rresp_i(d_axi_rresp_i),
    .d_axi_awvalid_o(d_axi_awvalid_o),
    .d_axi_awready_i(d_axi_awready_i),
    .d_axi_awaddr_o(d_axi_awaddr_o),
    .d_axi_awid_o(d_axi_awid_o),
    .d_axi_awlen_o(d_axi_awlen_o),
    .d_axi_awsize_o(d_axi_awsize_o),
    .d_axi_awburst_o(d_axi_awburst_o),
    .d_axi_wvalid_o(d_axi_wvalid_o),
    .d_axi_wready_i(d_axi_wready_i),
    .d_axi_wdata_o(d_axi_wdata_o),
    .d_axi_wstrb_o(d_axi_wstrb_o),
    .d_axi_wlast_o(d_axi_wlast_o),
    .d_axi_bvalid_i(d_axi_bvalid_i),
    .d_axi_bready_o(d_axi_bready_o),
    .d_axi_bresp_i(d_axi_bresp_i)
  );

  always #5 clk = ~clk;

  task automatic die(input string marker, input string reason);
    begin
      $display("[%0s] %0s @%0t", marker, reason, $time);
      $fatal;
    end
  endtask

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic clear_inputs;
    begin
      lane0_axi_arvalid_i = 1'b0;
      lane0_axi_araddr_i = 64'h0000_0000_0000_1000;
      lane0_axi_arid_i = 4'h1;
      lane0_axi_arlen_i = 8'h00;
      lane0_axi_arsize_i = 3'd3;
      lane0_axi_arburst_i = 2'b01;
      lane0_axi_arprot_i = 3'b000;
      lane0_axi_rready_i = 1'b0;
      lane0_axi_awvalid_i = 1'b0;
      lane0_axi_awaddr_i = 64'h0000_0000_0000_2000;
      lane0_axi_awid_i = 4'h1;
      lane0_axi_awlen_i = 8'h00;
      lane0_axi_awsize_i = 3'd3;
      lane0_axi_awburst_i = 2'b01;
      lane0_axi_wvalid_i = 1'b0;
      lane0_axi_wdata_i = 64'h0123_4567_89ab_cdef;
      lane0_axi_wstrb_i = 8'hff;
      lane0_axi_wlast_i = 1'b1;
      lane0_axi_bready_i = 1'b0;

      lane1_axi_arvalid_i = 1'b0;
      lane1_axi_araddr_i = 64'h0000_0000_0000_3000;
      lane1_axi_arid_i = 4'h2;
      lane1_axi_arlen_i = 8'h00;
      lane1_axi_arsize_i = 3'd2;
      lane1_axi_arburst_i = 2'b01;
      lane1_axi_arprot_i = 3'b001;
      lane1_axi_rready_i = 1'b0;
      lane1_axi_awvalid_i = 1'b0;
      lane1_axi_awaddr_i = 64'h0000_0000_0000_4000;
      lane1_axi_awid_i = 4'h2;
      lane1_axi_awlen_i = 8'h00;
      lane1_axi_awsize_i = 3'd2;
      lane1_axi_awburst_i = 2'b01;
      lane1_axi_wvalid_i = 1'b0;
      lane1_axi_wdata_i = 64'hfedc_ba98_7654_3210;
      lane1_axi_wstrb_i = 8'h0f;
      lane1_axi_wlast_i = 1'b1;
      lane1_axi_bready_i = 1'b0;

      d_axi_arready_i = 1'b0;
      d_axi_rvalid_i = 1'b0;
      d_axi_rdata_i = 64'h0;
      d_axi_rresp_i = 2'b00;
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b0;
      d_axi_bvalid_i = 1'b0;
      d_axi_bresp_i = 2'b00;
    end
  endtask

  task automatic expect_quiet(input string marker);
    begin
      if (lane0_axi_arready_o || lane0_axi_awready_o ||
          lane0_axi_wready_o || lane0_axi_rvalid_o || lane0_axi_bvalid_o ||
          lane1_axi_arready_o || lane1_axi_awready_o ||
          lane1_axi_wready_o || lane1_axi_rvalid_o || lane1_axi_bvalid_o ||
          d_axi_arvalid_o || d_axi_rready_o || d_axi_awvalid_o ||
          d_axi_wvalid_o || d_axi_bready_o)
        die(marker, "expected all handshake outputs quiet");
    end
  endtask

  task automatic do_reset(input string marker);
    begin
      @(negedge clk);
      clear_inputs();
      rst = 1'b1;
      #1;
      expect_quiet(marker);
      tick();
      tick();
      if (dut.state_q !== 3'd0 || dut.owner_q !== 1'b0 ||
          dut.is_write_q !== 1'b0 || dut.rr_q !== 1'b0 ||
          dut.aw_seen_q !== 1'b0 || dut.w_seen_q !== 1'b0)
        die(marker, "reset did not establish cold-start state");
      @(negedge clk);
      rst = 1'b0;
      tick();
      expect_quiet(marker);
    end
  endtask

  task automatic reset_current_phase(input string marker);
    begin
      @(negedge clk);
      clear_inputs();
      rst = 1'b1;
      #1;
      expect_quiet(marker);
      tick();
      if (dut.state_q !== 3'd0 || dut.owner_q !== 1'b0 ||
          dut.is_write_q !== 1'b0 || dut.rr_q !== 1'b0 ||
          dut.aw_seen_q !== 1'b0 || dut.w_seen_q !== 1'b0)
        die(marker, "mid-transaction reset did not establish cold-start state");
      @(negedge clk);
      rst = 1'b0;
      // A downstream orphan response left over from the abandoned pre-reset
      // transaction must not be consumed or exposed after reset release.
      d_axi_rvalid_i = 1'b1;
      d_axi_rdata_i = 64'hdead_beef_0000_0001;
      d_axi_bvalid_i = 1'b1;
      lane0_axi_rready_i = 1'b1;
      lane1_axi_rready_i = 1'b1;
      lane0_axi_bready_i = 1'b1;
      lane1_axi_bready_i = 1'b1;
      #1;
      expect_quiet(marker);
      tick();
      @(negedge clk);
      clear_inputs();
      tick();
    end
  endtask

  task automatic test_reset_phase_matrix(input string marker);
    begin
      // A legal direct write may be visible combinationally in IDLE, but reset
      // must suppress it immediately and restore the cold-start state on edge.
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_wvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      if (!d_axi_awvalid_o || !d_axi_wvalid_o ||
          !lane0_axi_awready_o || !lane0_axi_wready_o)
        die(marker, "failed to expose pre-reset direct write");
      rst = 1'b1;
      #1;
      expect_quiet(marker);
      tick();
      if (dut.state_q !== 3'd0 || dut.owner_q !== 1'b0 ||
          dut.is_write_q !== 1'b0 || dut.rr_q !== 1'b0 ||
          dut.aw_seen_q !== 1'b0 || dut.w_seen_q !== 1'b0)
        die(marker, "reset did not cancel direct combinational offer");
      @(negedge clk);
      clear_inputs();
      rst = 1'b0;
      tick();
      expect_quiet(marker);

      // READ_ADDR
      do_reset(marker);
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b1;
      tick();
      if (dut.state_q !== 3'd1)
        die(marker, "failed to activate READ_ADDR reset case");
      reset_current_phase(marker);

      // READ_RESP
      do_reset(marker);
      @(negedge clk);
      lane1_axi_arvalid_i = 1'b1;
      tick();
      @(negedge clk);
      d_axi_arready_i = 1'b1;
      tick();
      if (dut.state_q !== 3'd2)
        die(marker, "failed to activate READ_RESP reset case");
      reset_current_phase(marker);

      // WRITE_DATA after AW only.
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      #1;
      if (!d_axi_awvalid_o || !lane0_axi_awready_o || d_axi_wvalid_o)
        die(marker, "AW-only source was not admitted directly");
      tick();
      if (dut.state_q !== 3'd3 || !dut.aw_seen_q || dut.w_seen_q)
        die(marker, "failed to activate AW-only reset case");
      reset_current_phase(marker);

      // WRITE_DATA after W only.
      do_reset(marker);
      @(negedge clk);
      lane1_axi_wvalid_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      if (!d_axi_wvalid_o || !lane1_axi_wready_o || d_axi_awvalid_o)
        die(marker, "W-only source was not admitted directly");
      tick();
      if (dut.state_q !== 3'd3 || dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "failed to activate W-only reset case");
      reset_current_phase(marker);

      // WRITE_RESP after both channels complete.
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_wvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      if (!d_axi_awvalid_o || !d_axi_wvalid_o ||
          !lane0_axi_awready_o || !lane0_axi_wready_o)
        die(marker, "dual-channel source was not admitted directly");
      tick();
      if (dut.state_q !== 3'd4 || !dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "failed to activate WRITE_RESP reset case");
      reset_current_phase(marker);
      $display("[%0s] direct/reset phase matrix PASS", marker);
    end
  endtask

  task automatic test_read_idle_registered(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b1;
      d_axi_arready_i = 1'b1;
      #1;
      expect_quiet(marker);
      tick();
      if (!d_axi_arvalid_o || !lane0_axi_arready_o || lane1_axi_arready_o)
        die(marker, "read request did not appear only after registered capture");
      $display("[%0s] read IDLE remains registered PASS", marker);
      lane0_axi_arvalid_i = 1'b0;
      clear_inputs();
      do_reset(marker);
    end
  endtask

  task automatic test_read0(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b1;
      lane0_axi_araddr_i = 64'h1111_2222_3333_4440;
      lane0_axi_arid_i = 4'ha;
      lane0_axi_arlen_i = 8'h00;
      lane0_axi_arsize_i = 3'd3;
      lane0_axi_arburst_i = 2'b01;
      lane0_axi_arprot_i = 3'b010;
      tick();
      if (!d_axi_arvalid_o || d_axi_araddr_o !== lane0_axi_araddr_i ||
          d_axi_arid_o !== 4'ha || lane1_axi_arready_o)
        die(marker, "lane0 AR owner/payload mismatch");
      tick();
      if (!d_axi_arvalid_o || d_axi_araddr_o !== 64'h1111_2222_3333_4440)
        die(marker, "lane0 AR did not remain stable under stall");
      @(negedge clk);
      d_axi_arready_i = 1'b1;
      tick();
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b0;
      d_axi_arready_i = 1'b0;
      d_axi_rvalid_i = 1'b1;
      d_axi_rdata_i = 64'h55aa_0123_4567_89ab;
      d_axi_rresp_i = 2'b10;
      lane0_axi_rready_i = 1'b0;
      lane1_axi_rready_i = 1'b1;
      #1;
      if (!lane0_axi_rvalid_o || lane1_axi_rvalid_o || d_axi_rready_o ||
          lane0_axi_rdata_o !== 64'h55aa_0123_4567_89ab ||
          lane0_axi_rresp_o !== 2'b10)
        die(marker, "lane0 R isolation/READY selection mismatch");
      tick();
      if (!lane0_axi_rvalid_o || lane1_axi_rvalid_o)
        die(marker, "lane0 R did not remain isolated under stall");
      @(negedge clk);
      lane0_axi_rready_i = 1'b1;
      tick();
      @(negedge clk);
      clear_inputs();
      tick();
      expect_quiet(marker);
    end
  endtask

  task automatic test_read1_isolation(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane1_axi_arvalid_i = 1'b1;
      tick();
      if (!d_axi_arvalid_o || d_axi_araddr_o !== lane1_axi_araddr_i ||
          lane0_axi_arready_o)
        die(marker, "lane1 AR owner mismatch");
      @(negedge clk);
      d_axi_arready_i = 1'b1;
      tick();
      @(negedge clk);
      lane1_axi_arvalid_i = 1'b0;
      d_axi_arready_i = 1'b0;
      d_axi_rvalid_i = 1'b1;
      d_axi_rdata_i = 64'h9999_aaaa_bbbb_cccc;
      lane0_axi_rready_i = 1'b1;
      lane1_axi_rready_i = 1'b1;
      #1;
      if (lane0_axi_rvalid_o || !lane1_axi_rvalid_o || !d_axi_rready_o)
        die(marker, "lane1 R was broadcast or not accepted");
      tick();
      @(negedge clk);
      clear_inputs();
      tick();
    end
  endtask

  task automatic test_round_robin(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b1;
      lane1_axi_arvalid_i = 1'b1;
      tick();
      if (dut.owner_q !== 1'b0)
        die(marker, "first dual contender did not select reset rr lane0");
      @(negedge clk);
      d_axi_arready_i = 1'b1;
      tick();
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b0;
      lane1_axi_arvalid_i = 1'b0;
      d_axi_arready_i = 1'b0;
      d_axi_rvalid_i = 1'b1;
      lane0_axi_rready_i = 1'b1;
      tick();
      @(negedge clk);
      d_axi_rvalid_i = 1'b0;
      lane0_axi_rready_i = 1'b0;
      lane0_axi_arvalid_i = 1'b1;
      lane1_axi_arvalid_i = 1'b1;
      tick();
      if (dut.owner_q !== 1'b1)
        die(marker, "waiting lane1 did not win next dual-contender capture");
      clear_inputs();
      do_reset(marker);
    end
  endtask

  task automatic test_rr_terminal_only(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b1;
      tick();
      if (dut.rr_q !== 1'b0)
        die(marker, "round-robin state changed at capture instead of terminal");
      clear_inputs();
      do_reset(marker);
    end
  endtask

  task automatic test_write_aw_first(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_wvalid_i = 1'b0;
      tick();
      @(negedge clk);
      d_axi_awready_i = 1'b1;
      tick();
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b0;
      d_axi_awready_i = 1'b0;
      lane0_axi_wvalid_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      if (d_axi_awvalid_o || !d_axi_wvalid_o || !lane0_axi_wready_o ||
          lane1_axi_wready_o)
        die(marker, "AW-first did not retain owner and accept W exactly once");
      tick();
      @(negedge clk);
      lane0_axi_wvalid_i = 1'b0;
      d_axi_wready_i = 1'b0;
      d_axi_bvalid_i = 1'b1;
      d_axi_bresp_i = 2'b01;
      lane0_axi_bready_i = 1'b0;
      #1;
      if (!lane0_axi_bvalid_o || lane1_axi_bvalid_o || d_axi_bready_o ||
          lane0_axi_bresp_o !== 2'b01)
        die(marker, "AW-first B isolation/stall mismatch");
      tick();
      if (dut.state_q !== 3'd4)
        die(marker, "B stall released write owner early");
      @(negedge clk);
      lane0_axi_bready_i = 1'b1;
      tick();
      @(negedge clk);
      clear_inputs();
      tick();
    end
  endtask

  task automatic test_write_w_first(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane1_axi_wvalid_i = 1'b1;
      tick();
      @(negedge clk);
      d_axi_wready_i = 1'b1;
      tick();
      @(negedge clk);
      lane1_axi_wvalid_i = 1'b0;
      d_axi_wready_i = 1'b0;
      lane1_axi_awvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      #1;
      if (!d_axi_awvalid_o || d_axi_wvalid_o || !lane1_axi_awready_o ||
          lane0_axi_awready_o)
        die(marker, "W-first did not retain owner and accept AW exactly once");
      tick();
      @(negedge clk);
      lane1_axi_awvalid_i = 1'b0;
      d_axi_awready_i = 1'b0;
      d_axi_bvalid_i = 1'b1;
      lane0_axi_bready_i = 1'b1;
      lane1_axi_bready_i = 1'b1;
      #1;
      if (lane0_axi_bvalid_o || !lane1_axi_bvalid_o || !d_axi_bready_o)
        die(marker, "lane1 B was broadcast or not accepted");
      tick();
      @(negedge clk);
      clear_inputs();
      tick();
    end
  endtask

  task automatic test_write_same_cycle(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_wvalid_i = 1'b1;
      tick();
      @(negedge clk);
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      if (!d_axi_awvalid_o || !d_axi_wvalid_o)
        die(marker, "same-cycle AW/W not presented together");
      tick();
      if (dut.state_q !== 3'd4 || !dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "same-cycle AW/W did not enter B phase exactly once");
      clear_inputs();
      do_reset(marker);
    end
  endtask

  task automatic expect_direct_write(
    input string marker,
    input owner,
    input aw_valid,
    input w_valid,
    input aw_ready,
    input w_ready,
    input [`XLEN-1:0] awaddr,
    input [3:0] awid,
    input [7:0] awlen,
    input [2:0] awsize,
    input [1:0] awburst,
    input [`XLEN-1:0] wdata,
    input [`STRB_W-1:0] wstrb,
    input wlast
  );
    begin
      if (dut.state_q !== 3'd0)
        die(marker, "direct write was not observed in IDLE");
      if (d_axi_awvalid_o !== aw_valid || d_axi_wvalid_o !== w_valid)
        die(marker, "direct AW/W VALID did not match selected source");
      if (aw_valid &&
          (d_axi_awaddr_o !== awaddr || d_axi_awid_o !== awid ||
           d_axi_awlen_o !== awlen || d_axi_awsize_o !== awsize ||
           d_axi_awburst_o !== awburst))
        die(marker, "direct AW payload did not come from selected source");
      if (w_valid &&
          (d_axi_wdata_o !== wdata || d_axi_wstrb_o !== wstrb ||
           d_axi_wlast_o !== wlast))
        die(marker, "direct W payload did not come from selected source");
      if (owner === 1'b0) begin
        if (lane0_axi_awready_o !== aw_ready ||
            lane0_axi_wready_o !== w_ready)
          die(marker, "lane0 direct READY mapping mismatch");
        if (lane1_axi_arready_o || lane1_axi_awready_o ||
            lane1_axi_wready_o || lane0_axi_arready_o)
          die(marker, "lane0 direct offer leaked READY to non-owner/read");
      end else if (owner === 1'b1) begin
        if (lane1_axi_awready_o !== aw_ready ||
            lane1_axi_wready_o !== w_ready)
          die(marker, "lane1 direct READY mapping mismatch");
        if (lane0_axi_arready_o || lane0_axi_awready_o ||
            lane0_axi_wready_o || lane1_axi_arready_o)
          die(marker, "lane1 direct offer leaked READY to non-owner/read");
      end else begin
        die(marker, "direct owner expectation was not exactly known");
      end
      if (d_axi_arvalid_o || d_axi_rready_o || d_axi_bready_o ||
          lane0_axi_rvalid_o || lane1_axi_rvalid_o ||
          lane0_axi_bvalid_o || lane1_axi_bvalid_o)
        die(marker, "direct write exposed an AR/R/B route");
    end
  endtask

  task automatic complete_write_b(
    input string marker,
    input owner,
    input [1:0] resp,
    input integer stall_cycles
  );
    integer stall_idx;
    begin
      @(negedge clk);
      clear_inputs();
      d_axi_bvalid_i = 1'b1;
      d_axi_bresp_i = resp;
      if (owner === 1'b0)
        lane0_axi_bready_i = 1'b0;
      else
        lane1_axi_bready_i = 1'b0;
      #1;
      if (dut.state_q !== 3'd4 || dut.owner_q !== owner ||
          dut.is_write_q !== 1'b1 || !dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "write response phase lost registered owner/seen state");
      if (owner === 1'b0) begin
        if (!lane0_axi_bvalid_o || lane1_axi_bvalid_o || d_axi_bready_o ||
            lane0_axi_bresp_o !== resp)
          die(marker, "lane0 registered B route mismatch");
      end else begin
        if (lane0_axi_bvalid_o || !lane1_axi_bvalid_o || d_axi_bready_o ||
            lane1_axi_bresp_o !== resp)
          die(marker, "lane1 registered B route mismatch");
      end
      for (stall_idx = 0; stall_idx < stall_cycles;
           stall_idx = stall_idx + 1) begin
        tick();
        if (dut.state_q !== 3'd4 || dut.owner_q !== owner ||
            !dut.aw_seen_q || !dut.w_seen_q)
          die(marker, "B backpressure released owner or completion state");
        if (owner === 1'b0) begin
          if (!lane0_axi_bvalid_o || lane1_axi_bvalid_o || d_axi_bready_o ||
              lane0_axi_bresp_o !== resp)
            die(marker, "lane0 B route changed under backpressure");
        end else begin
          if (lane0_axi_bvalid_o || !lane1_axi_bvalid_o || d_axi_bready_o ||
              lane1_axi_bresp_o !== resp)
            die(marker, "lane1 B route changed under backpressure");
        end
      end
      @(negedge clk);
      if (owner === 1'b0)
        lane0_axi_bready_i = 1'b1;
      else
        lane1_axi_bready_i = 1'b1;
      #1;
      if (!d_axi_bready_o)
        die(marker, "registered B owner READY did not reach downstream");
      tick();
      if (dut.state_q !== 3'd0 || dut.rr_q !== !owner)
        die(marker, "B terminal did not release owner/update RR exactly once");
      @(negedge clk);
      clear_inputs();
      tick();
      expect_quiet(marker);
    end
  endtask

  task automatic run_source11_ready_case(
    input string marker,
    input aw_ready,
    input w_ready
  );
    reg [`XLEN-1:0] awaddr_original;
    reg [`XLEN-1:0] wdata_original;
    reg [`STRB_W-1:0] wstrb_original;
    begin
      do_reset(marker);
      awaddr_original = 64'h5100_0000_0000_0080;
      wdata_original = 64'h1122_3344_5566_7788;
      wstrb_original = 8'hc3;
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_awaddr_i = awaddr_original;
      lane0_axi_awid_i = 4'hb;
      lane0_axi_awlen_i = 8'h00;
      lane0_axi_awsize_i = 3'd3;
      lane0_axi_awburst_i = 2'b01;
      lane0_axi_wvalid_i = 1'b1;
      lane0_axi_wdata_i = wdata_original;
      lane0_axi_wstrb_i = wstrb_original;
      lane0_axi_wlast_i = 1'b1;
      d_axi_awready_i = aw_ready;
      d_axi_wready_i = w_ready;
      // An early BVALID is deliberately present in the direct capture cycle.
      // It must remain unrouted until owner_q and S_WRITE_RESP are registered.
      d_axi_bvalid_i = 1'b1;
      d_axi_bresp_i = 2'b10;
      lane0_axi_bready_i = 1'b0;
      #1;
      expect_direct_write(marker, 1'b0, 1'b1, 1'b1,
                          aw_ready, w_ready,
                          awaddr_original, 4'hb, 8'h00, 3'd3, 2'b01,
                          wdata_original, wstrb_original, 1'b1);
      tick();
      if (dut.owner_q !== 1'b0 || dut.is_write_q !== 1'b1 ||
          dut.aw_seen_q !== aw_ready || dut.w_seen_q !== w_ready)
        die(marker, "direct capture did not seed owner/type/seen exactly");
      if (aw_ready && w_ready) begin
        if (dut.state_q !== 3'd4)
          die(marker, "READY=11 did not enter registered B phase");
      end else begin
        if (dut.state_q !== 3'd3 || d_axi_bready_o ||
            lane0_axi_bvalid_o || lane1_axi_bvalid_o)
          die(marker, "partial direct fire exposed B or skipped retry state");
        @(negedge clk);
        // Poison only the channel that already fired.  Any channel that did
        // not fire must retain its original payload until the retry handshake.
        if (aw_ready)
          lane0_axi_awaddr_i = 64'hdead_0000_0000_00a0;
        if (w_ready) begin
          lane0_axi_wdata_i = 64'hdead_0000_0000_00b0;
          lane0_axi_wstrb_i = 8'h5a;
        end
        d_axi_awready_i = !aw_ready;
        d_axi_wready_i = !w_ready;
        #1;
        if (d_axi_awvalid_o !== !aw_ready ||
            d_axi_wvalid_o !== !w_ready ||
            lane0_axi_awready_o !== !aw_ready ||
            lane0_axi_wready_o !== !w_ready)
          die(marker, "partial retry repeated a fired channel or lost pending channel");
        if (!aw_ready && d_axi_awaddr_o !== awaddr_original)
          die(marker, "pending AW payload changed across direct/register boundary");
        if (!w_ready &&
            (d_axi_wdata_o !== wdata_original ||
             d_axi_wstrb_o !== wstrb_original || !d_axi_wlast_o))
          die(marker, "pending W payload changed across direct/register boundary");
        if (d_axi_bready_o || lane0_axi_bvalid_o || lane1_axi_bvalid_o)
          die(marker, "early BVALID escaped during partial retry");
        tick();
        if (dut.state_q !== 3'd4 || !dut.aw_seen_q || !dut.w_seen_q)
          die(marker, "partial retry did not complete both channels exactly once");
      end

      @(negedge clk);
      // Once both channels have fired, neither current live source nor a new
      // contender may replace the registered transaction or reissue AW/W.
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_awaddr_i = 64'hdeaf_0000_0000_0001;
      lane0_axi_wvalid_i = 1'b1;
      lane0_axi_wdata_i = 64'hdeaf_0000_0000_0002;
      lane0_axi_wstrb_i = 8'h00;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_wvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      if (d_axi_awvalid_o || d_axi_wvalid_o ||
          lane0_axi_awready_o || lane0_axi_wready_o ||
          lane1_axi_awready_o || lane1_axi_wready_o)
        die(marker, "poison live payload reissued a completed write channel");
      if (!lane0_axi_bvalid_o || lane1_axi_bvalid_o || d_axi_bready_o ||
          lane0_axi_bresp_o !== 2'b10)
        die(marker, "early BVALID was not routed only after registered owner");
      complete_write_b(marker, 1'b0, 2'b10, 0);
      $display("[%0s] source=11 ready=%0b%0b PASS",
               marker, aw_ready, w_ready);
    end
  endtask

  task automatic test_direct_source10_01(input string marker);
    begin
      // AW-only source on lane0.
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_awaddr_i = 64'h6100_0000_0000_0100;
      lane0_axi_awid_i = 4'h6;
      lane0_axi_awlen_i = 8'h00;
      lane0_axi_awsize_i = 3'd3;
      lane0_axi_awburst_i = 2'b01;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      d_axi_bvalid_i = 1'b1;
      d_axi_bresp_i = 2'b01;
      #1;
      expect_direct_write(marker, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1,
                          64'h6100_0000_0000_0100, 4'h6, 8'h00,
                          3'd3, 2'b01, 64'h0, 8'h00, 1'b0);
      tick();
      if (dut.state_q !== 3'd3 || !dut.aw_seen_q || dut.w_seen_q)
        die(marker, "source=10 did not seed AW-only completion");
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_awaddr_i = 64'hdead_dead_dead_00a0;
      lane0_axi_wvalid_i = 1'b1;
      lane0_axi_wdata_i = 64'h0102_0304_0506_0708;
      lane0_axi_wstrb_i = 8'h81;
      lane0_axi_wlast_i = 1'b1;
      #1;
      if (d_axi_awvalid_o || lane0_axi_awready_o ||
          !d_axi_wvalid_o || !lane0_axi_wready_o ||
          d_axi_wdata_o !== 64'h0102_0304_0506_0708 ||
          d_axi_wstrb_o !== 8'h81 || !d_axi_wlast_o)
        die(marker, "source=10 retry repeated AW or lost W");
      tick();
      if (dut.state_q !== 3'd4 || !dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "source=10 retry did not enter B phase");
      complete_write_b(marker, 1'b0, 2'b01, 0);

      // W-only source on lane1.
      do_reset(marker);
      @(negedge clk);
      lane1_axi_wvalid_i = 1'b1;
      lane1_axi_wdata_i = 64'h8877_6655_4433_2211;
      lane1_axi_wstrb_i = 8'h3c;
      lane1_axi_wlast_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      d_axi_bvalid_i = 1'b1;
      d_axi_bresp_i = 2'b11;
      #1;
      expect_direct_write(marker, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1,
                          64'h0, 4'h0, 8'h00, 3'd0, 2'b00,
                          64'h8877_6655_4433_2211, 8'h3c, 1'b1);
      tick();
      if (dut.state_q !== 3'd3 || dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "source=01 did not seed W-only completion");
      @(negedge clk);
      lane1_axi_wvalid_i = 1'b1;
      lane1_axi_wdata_i = 64'hdead_dead_dead_00b0;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_awaddr_i = 64'h6200_0000_0000_0200;
      lane1_axi_awid_i = 4'h7;
      lane1_axi_awlen_i = 8'h00;
      lane1_axi_awsize_i = 3'd2;
      lane1_axi_awburst_i = 2'b01;
      #1;
      if (!d_axi_awvalid_o || !lane1_axi_awready_o ||
          d_axi_wvalid_o || lane1_axi_wready_o ||
          d_axi_awaddr_o !== 64'h6200_0000_0000_0200 ||
          d_axi_awid_o !== 4'h7)
        die(marker, "source=01 retry repeated W or lost AW");
      tick();
      if (dut.state_q !== 3'd4 || !dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "source=01 retry did not enter B phase");
      complete_write_b(marker, 1'b1, 2'b11, 0);
      $display("[%0s] source=10/source=01 partial retry PASS", marker);
    end
  endtask

  task automatic test_direct_contention_rr(input string marker);
    begin
      // Two write contenders: reset RR selects lane0, and only that lane may
      // observe READY or contribute either channel.
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_wvalid_i = 1'b1;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_wvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      expect_direct_write(marker, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1,
                          lane0_axi_awaddr_i, lane0_axi_awid_i,
                          lane0_axi_awlen_i, lane0_axi_awsize_i,
                          lane0_axi_awburst_i, lane0_axi_wdata_i,
                          lane0_axi_wstrb_i, lane0_axi_wlast_i);
      tick();
      if (dut.state_q !== 3'd4 || dut.owner_q !== 1'b0 ||
          dut.rr_q !== 1'b0)
        die(marker, "first dual-write contender did not lock RR lane0");
      complete_write_b(marker, 1'b0, 2'b00, 0);
      if (dut.rr_q !== 1'b1)
        die(marker, "lane0 B terminal did not rotate RR to lane1");

      // Preserve the rotated RR state and present both writes again.
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_wvalid_i = 1'b1;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_wvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      expect_direct_write(marker, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1,
                          lane1_axi_awaddr_i, lane1_axi_awid_i,
                          lane1_axi_awlen_i, lane1_axi_awsize_i,
                          lane1_axi_awburst_i, lane1_axi_wdata_i,
                          lane1_axi_wstrb_i, lane1_axi_wlast_i);
      tick();
      if (dut.state_q !== 3'd4 || dut.owner_q !== 1'b1 ||
          dut.rr_q !== 1'b1)
        die(marker, "second dual-write contender did not lock RR lane1");
      complete_write_b(marker, 1'b1, 2'b00, 0);

      // Mixed read/write contenders obey the same RR winner.  With RR=0 the
      // read wins and IDLE remains entirely registered/quiet.
      do_reset(marker);
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b1;
      lane0_axi_araddr_i = 64'h7100_0000_0000_0100;
      lane0_axi_arid_i = 4'h8;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_wvalid_i = 1'b1;
      d_axi_arready_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      expect_quiet(marker);
      tick();
      if (dut.state_q !== 3'd1 || dut.owner_q !== 1'b0 ||
          dut.is_write_q !== 1'b0 || !d_axi_arvalid_o ||
          d_axi_araddr_o !== 64'h7100_0000_0000_0100 ||
          !lane0_axi_arready_o)
        die(marker, "RR=0 mixed contention did not register lane0 read");
      tick();
      if (dut.state_q !== 3'd2)
        die(marker, "mixed-contention read address did not complete");
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b0;
      lane1_axi_awvalid_i = 1'b0;
      lane1_axi_wvalid_i = 1'b0;
      d_axi_arready_i = 1'b0;
      d_axi_rvalid_i = 1'b1;
      d_axi_rdata_i = 64'h7171_0000_0000_0100;
      lane0_axi_rready_i = 1'b1;
      tick();
      if (dut.state_q !== 3'd0 || dut.rr_q !== 1'b1)
        die(marker, "lane0 read terminal did not rotate mixed RR to lane1");

      // With RR=1 the write wins the same mixed contention and therefore gets
      // the legal write-only direct offer in the IDLE capture cycle.
      @(negedge clk);
      d_axi_rvalid_i = 1'b0;
      lane0_axi_rready_i = 1'b0;
      lane0_axi_arvalid_i = 1'b1;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_wvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      expect_direct_write(marker, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1,
                          lane1_axi_awaddr_i, lane1_axi_awid_i,
                          lane1_axi_awlen_i, lane1_axi_awsize_i,
                          lane1_axi_awburst_i, lane1_axi_wdata_i,
                          lane1_axi_wstrb_i, lane1_axi_wlast_i);
      tick();
      if (dut.state_q !== 3'd4 || dut.owner_q !== 1'b1 ||
          dut.is_write_q !== 1'b1)
        die(marker, "RR=1 mixed contention did not lock lane1 write");
      complete_write_b(marker, 1'b1, 2'b00, 0);
      $display("[%0s] write/write and read/write RR ownership PASS", marker);
    end
  endtask

  task automatic test_direct_contention_partial_owner_lock(
    input string marker
  );
    reg [`XLEN-1:0] lane0_awaddr_original;
    reg [`XLEN-1:0] lane0_wdata_original;
    reg [`XLEN-1:0] lane1_awaddr_original;
    reg [`XLEN-1:0] lane1_wdata_original;
    begin
      lane0_awaddr_original = 64'h8100_0000_0000_0010;
      lane0_wdata_original = 64'h0011_2233_4455_6677;
      lane1_awaddr_original = 64'h8200_0000_0000_0020;
      lane1_wdata_original = 64'h8899_aabb_ccdd_eeff;

      // RR=0 selects lane0.  All four source VALID signals stay asserted,
      // but only the winning lane0 AW channel may fire in the direct cycle.
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_awaddr_i = lane0_awaddr_original;
      lane0_axi_awid_i = 4'h8;
      lane0_axi_wvalid_i = 1'b1;
      lane0_axi_wdata_i = lane0_wdata_original;
      lane0_axi_wstrb_i = 8'h87;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_awaddr_i = lane1_awaddr_original;
      lane1_axi_awid_i = 4'h9;
      lane1_axi_wvalid_i = 1'b1;
      lane1_axi_wdata_i = lane1_wdata_original;
      lane1_axi_wstrb_i = 8'h78;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b0;
      #1;
      expect_direct_write(marker, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0,
                          lane0_awaddr_original, 4'h8,
                          lane0_axi_awlen_i, lane0_axi_awsize_i,
                          lane0_axi_awburst_i, lane0_wdata_original,
                          8'h87, lane0_axi_wlast_i);
      if (lane1_axi_awready_o || lane1_axi_wready_o)
        die(marker, "RR=0 loser observed READY during partial direct fire");
      tick();
      if (dut.state_q !== 3'd3 || dut.owner_q !== 1'b0 ||
          !dut.is_write_q || !dut.aw_seen_q || dut.w_seen_q ||
          dut.rr_q !== 1'b0)
        die(marker, "RR=0 partial direct fire did not lock lane0/AW state");

      @(negedge clk);
      // The sources deliberately keep AW/W VALID high.  Only lane0.W may be
      // retried; lane1 must not supply the missing half of lane0's write.
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      if (d_axi_awvalid_o || !d_axi_wvalid_o ||
          lane0_axi_awready_o || !lane0_axi_wready_o ||
          lane1_axi_awready_o || lane1_axi_wready_o)
        die(marker, "RR=0 retry repeated AW or exposed loser READY");
      if (d_axi_wdata_o !== lane0_wdata_original ||
          d_axi_wstrb_o !== 8'h87 ||
          d_axi_wlast_o !== lane0_axi_wlast_i ||
          d_axi_wdata_o === lane1_wdata_original)
        die(marker, "RR=0 retry borrowed W payload from loser");
      tick();
      if (dut.state_q !== 3'd4 || dut.owner_q !== 1'b0 ||
          !dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "RR=0 winner retry did not complete both channels");
      complete_write_b(marker, 1'b0, 2'b00, 0);
      if (dut.rr_q !== 1'b1)
        die(marker, "lane0 terminal did not rotate RR for cross case");

      // RR=1 now selects lane1.  Keep all four VALID signals asserted again,
      // this time accepting only W directly and retrying only lane1.AW.
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_awaddr_i = lane0_awaddr_original;
      lane0_axi_awid_i = 4'h8;
      lane0_axi_wvalid_i = 1'b1;
      lane0_axi_wdata_i = lane0_wdata_original;
      lane0_axi_wstrb_i = 8'h87;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_awaddr_i = lane1_awaddr_original;
      lane1_axi_awid_i = 4'h9;
      lane1_axi_wvalid_i = 1'b1;
      lane1_axi_wdata_i = lane1_wdata_original;
      lane1_axi_wstrb_i = 8'h78;
      d_axi_awready_i = 1'b0;
      d_axi_wready_i = 1'b1;
      #1;
      expect_direct_write(marker, 1'b1, 1'b1, 1'b1, 1'b0, 1'b1,
                          lane1_awaddr_original, 4'h9,
                          lane1_axi_awlen_i, lane1_axi_awsize_i,
                          lane1_axi_awburst_i, lane1_wdata_original,
                          8'h78, lane1_axi_wlast_i);
      if (lane0_axi_awready_o || lane0_axi_wready_o)
        die(marker, "RR=1 loser observed READY during partial direct fire");
      tick();
      if (dut.state_q !== 3'd3 || dut.owner_q !== 1'b1 ||
          !dut.is_write_q || dut.aw_seen_q || !dut.w_seen_q ||
          dut.rr_q !== 1'b1)
        die(marker, "RR=1 partial direct fire did not lock lane1/W state");

      @(negedge clk);
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      if (!d_axi_awvalid_o || d_axi_wvalid_o ||
          !lane1_axi_awready_o || lane1_axi_wready_o ||
          lane0_axi_awready_o || lane0_axi_wready_o)
        die(marker, "RR=1 retry repeated W or exposed loser READY");
      if (d_axi_awaddr_o !== lane1_awaddr_original ||
          d_axi_awid_o !== 4'h9 ||
          d_axi_awaddr_o === lane0_awaddr_original)
        die(marker, "RR=1 retry borrowed AW payload from loser");
      tick();
      if (dut.state_q !== 3'd4 || dut.owner_q !== 1'b1 ||
          !dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "RR=1 winner retry did not complete both channels");
      complete_write_b(marker, 1'b1, 2'b00, 0);
      $display("[%0s] RR=0 AW-only and RR=1 W-only owner lock PASS",
               marker);
    end
  endtask

  task automatic test_direct_b_backpressure(input string marker);
    integer hold_idx;
    begin
      do_reset(marker);
      @(negedge clk);
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_wvalid_i = 1'b1;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      d_axi_bvalid_i = 1'b1;
      d_axi_bresp_i = 2'b10;
      lane1_axi_bready_i = 1'b0;
      #1;
      expect_direct_write(marker, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1,
                          lane1_axi_awaddr_i, lane1_axi_awid_i,
                          lane1_axi_awlen_i, lane1_axi_awsize_i,
                          lane1_axi_awburst_i, lane1_axi_wdata_i,
                          lane1_axi_wstrb_i, lane1_axi_wlast_i);
      tick();
      if (dut.state_q !== 3'd4 || dut.owner_q !== 1'b1 ||
          !lane1_axi_bvalid_o || lane0_axi_bvalid_o || d_axi_bready_o)
        die(marker, "registered lane1 B route was not established after direct fire");

      @(negedge clk);
      // Keep unrelated requests and poisoned old-owner payloads live throughout
      // B backpressure; none may disturb the registered response owner.
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_awaddr_i = 64'hbad0_0000_0000_0001;
      lane0_axi_wvalid_i = 1'b1;
      lane0_axi_wdata_i = 64'hbad0_0000_0000_0002;
      lane1_axi_awvalid_i = 1'b1;
      lane1_axi_awaddr_i = 64'hbad1_0000_0000_0001;
      lane1_axi_wvalid_i = 1'b1;
      lane1_axi_wdata_i = 64'hbad1_0000_0000_0002;
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      #1;
      for (hold_idx = 0; hold_idx < 5; hold_idx = hold_idx + 1) begin
        if (dut.state_q !== 3'd4 || dut.owner_q !== 1'b1 ||
            dut.rr_q !== 1'b0 || !dut.aw_seen_q || !dut.w_seen_q ||
            !lane1_axi_bvalid_o || lane0_axi_bvalid_o ||
            lane1_axi_bresp_o !== 2'b10 || d_axi_bready_o ||
            d_axi_awvalid_o || d_axi_wvalid_o ||
            lane0_axi_awready_o || lane0_axi_wready_o ||
            lane1_axi_awready_o || lane1_axi_wready_o)
          die(marker, "long B backpressure changed owner/response or re-admitted write");
        tick();
      end
      @(negedge clk);
      lane1_axi_bready_i = 1'b1;
      #1;
      if (!d_axi_bready_o || !lane1_axi_bvalid_o || lane0_axi_bvalid_o)
        die(marker, "lane1 B terminal READY/VALID isolation mismatch");
      tick();
      if (dut.state_q !== 3'd0 || dut.rr_q !== 1'b0)
        die(marker, "lane1 B terminal did not release and rotate to lane0");
      @(negedge clk);
      clear_inputs();
      tick();
      expect_quiet(marker);
      $display("[%0s] five-cycle B backpressure/owner hold PASS", marker);
    end
  endtask

  task automatic test_release_illegal_fail_closed;
    reg [2:0] state_before;
    reg owner_before;
    reg is_write_before;
    reg rr_before;
    reg aw_seen_before;
    reg w_seen_before;
    begin
      do_reset("V8Q-ILLEGAL-FAIL-CLOSED");
      state_before = dut.state_q;
      owner_before = dut.owner_q;
      is_write_before = dut.is_write_q;
      rr_before = dut.rr_q;
      aw_seen_before = dut.aw_seen_q;
      w_seen_before = dut.w_seen_q;
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b1;
      lane0_axi_awvalid_i = 1'b1;
      lane1_axi_arvalid_i = 1'b1;
      d_axi_arready_i = 1'b1;
      d_axi_awready_i = 1'b1;
      #1;
      expect_quiet("V8Q-ILLEGAL-FAIL-CLOSED");
      tick();
      if (dut.state_q !== state_before || dut.owner_q !== owner_before ||
          dut.is_write_q !== is_write_before || dut.rr_q !== rr_before ||
          dut.aw_seen_q !== aw_seen_before ||
          dut.w_seen_q !== w_seen_before)
        die("V8Q-ILLEGAL-FAIL-CLOSED", "illegal lane changed arbiter state");
      expect_quiet("V8Q-ILLEGAL-FAIL-CLOSED");
      $display("[ARB-IDLE-WRITE-ILLEGAL] dual-type request failed closed PASS");
      clear_inputs();
      do_reset("V8Q-ILLEGAL-FAIL-CLOSED");
    end
  endtask

  integer mutation_case;
  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    mutation_case = 0;
    if (!$value$plusargs("MUTATION_CASE=%d", mutation_case))
      mutation_case = 0;

`ifdef NEGATIVE_CLASS
    do_reset("V8Q-NEGATIVE-SETUP");
    @(negedge clk);
    lane0_axi_arvalid_i = 1'b1;
    lane0_axi_awvalid_i = 1'b1;
    tick();
    die("V8Q-NEGATIVE-MISSING", "illegal dual-type request was not rejected");
`else
    case (mutation_case)
      1: begin
        $display("[V8Q-MUT-ACTIVE:read_release_on_ar]");
        test_read0("V8Q-MUT-READ-RELEASE-ON-AR");
      end
      2: begin
        $display("[V8Q-MUT-ACTIVE:write_release_on_aw]");
        test_write_aw_first("V8Q-MUT-WRITE-RELEASE-ON-AW");
      end
      3: begin
        $display("[V8Q-MUT-ACTIVE:write_release_on_w]");
        test_write_w_first("V8Q-MUT-WRITE-RELEASE-ON-W");
      end
      4: begin
        $display("[V8Q-MUT-ACTIVE:aw_seen_tieoff]");
        test_write_aw_first("V8Q-MUT-AW-SEEN-TIEOFF");
      end
      5: begin
        $display("[V8Q-MUT-ACTIVE:w_seen_tieoff]");
        test_write_w_first("V8Q-MUT-W-SEEN-TIEOFF");
      end
      6: begin
        $display("[V8Q-MUT-ACTIVE:broadcast_rvalid]");
        test_read1_isolation("V8Q-MUT-BROADCAST-RVALID");
      end
      7: begin
        $display("[V8Q-MUT-ACTIVE:swap_rready]");
        test_read0("V8Q-MUT-SWAP-RREADY");
      end
      8: begin
        $display("[V8Q-MUT-ACTIVE:broadcast_bvalid]");
        test_write_w_first("V8Q-MUT-BROADCAST-BVALID");
      end
      9: begin
        $display("[V8Q-MUT-ACTIVE:fixed_lane0_priority]");
        test_round_robin("V8Q-MUT-FIXED-LANE0-PRIORITY");
      end
      10: begin
        $display("[V8Q-MUT-ACTIVE:rr_update_on_capture]");
        test_rr_terminal_only("V8Q-MUT-RR-UPDATE-ON-CAPTURE");
      end
      11: begin
        $display("[V8Q-MUT-ACTIVE:read_idle_fallthrough]");
        test_read_idle_registered("V8Q-MUT-READ-IDLE-FALLTHROUGH");
      end
      12: begin
        $display("[V8Q-MUT-ACTIVE:reset_owner_residue]");
        do_reset("V8Q-MUT-RESET-OWNER-RESIDUE");
      end
      default: begin
        test_read_idle_registered("ARB-IDLE-READ-REGISTERED");
        run_source11_ready_case("ARB-IDLE-WRITE-READY-11", 1'b1, 1'b1);
        run_source11_ready_case("ARB-IDLE-WRITE-READY-10", 1'b1, 1'b0);
        run_source11_ready_case("ARB-IDLE-WRITE-READY-01", 1'b0, 1'b1);
        run_source11_ready_case("ARB-IDLE-WRITE-READY-00", 1'b0, 1'b0);
        $display("[ARB-IDLE-WRITE-DIRECT-READY] source=11 ready=11/10/01/00 PASS");
        $display("[ARB-IDLE-WRITE-PARTIAL-RETRY] fired channels were not repeated PASS");
        $display("[ARB-IDLE-WRITE-POISON] live payload could not replace owner transaction PASS");
        $display("[ARB-IDLE-WRITE-B-AUTH] early B hidden, registered-owner B visible PASS");
        test_direct_source10_01("ARB-IDLE-WRITE-SOURCE-10-01");
        test_direct_contention_rr("ARB-IDLE-WRITE-CONTENTION-RR");
        test_direct_contention_partial_owner_lock(
          "ARB-IDLE-WRITE-CONTENTION-PARTIAL-OWNER-LOCK"
        );
        test_direct_b_backpressure("ARB-IDLE-WRITE-B-STALL");
        test_read0("V8Q-BASE-READ0");
        test_read1_isolation("V8Q-BASE-READ1");
        test_round_robin("V8Q-BASE-FAIRNESS");
        test_rr_terminal_only("V8Q-BASE-RR");
        test_write_aw_first("V8Q-BASE-AW-FIRST");
        test_write_w_first("V8Q-BASE-W-FIRST");
        test_write_same_cycle("V8Q-BASE-AW-W-SAME");
        test_reset_phase_matrix("ARB-IDLE-WRITE-RESET-MATRIX");
`ifndef OOO_ASSERT
        test_release_illegal_fail_closed();
`endif
        $display("[ARB-IDLE-WRITE-ADMISSION][PASS] write direct/read registered transport matrix");
        $display("[PASS] tb_ooo_dual_mem_axi_arbiter");
      end
    endcase
    if (mutation_case != 0)
      die("V8Q-MUT-NOT-REJECTED", "active semantic mutation escaped its target");
    $finish;
`endif
  end

  initial begin
    #20000;
    die("V8Q-TIMEOUT", "testbench exceeded cycle budget");
  end
endmodule
