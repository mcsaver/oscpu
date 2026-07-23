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
      tick();
      @(negedge clk);
      d_axi_awready_i = 1'b1;
      tick();
      if (dut.state_q !== 3'd3 || !dut.aw_seen_q || dut.w_seen_q)
        die(marker, "failed to activate AW-only reset case");
      reset_current_phase(marker);

      // WRITE_DATA after W only.
      do_reset(marker);
      @(negedge clk);
      lane1_axi_wvalid_i = 1'b1;
      tick();
      @(negedge clk);
      d_axi_wready_i = 1'b1;
      tick();
      if (dut.state_q !== 3'd3 || dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "failed to activate W-only reset case");
      reset_current_phase(marker);

      // WRITE_RESP after both channels complete.
      do_reset(marker);
      @(negedge clk);
      lane0_axi_awvalid_i = 1'b1;
      lane0_axi_wvalid_i = 1'b1;
      tick();
      @(negedge clk);
      d_axi_awready_i = 1'b1;
      d_axi_wready_i = 1'b1;
      tick();
      if (dut.state_q !== 3'd4 || !dut.aw_seen_q || !dut.w_seen_q)
        die(marker, "failed to activate WRITE_RESP reset case");
      reset_current_phase(marker);
    end
  endtask

  task automatic test_idle_registered(input string marker);
    begin
      do_reset(marker);
      @(negedge clk);
      lane0_axi_arvalid_i = 1'b1;
      d_axi_arready_i = 1'b1;
      #1;
      expect_quiet(marker);
      tick();
      if (!d_axi_arvalid_o || !lane0_axi_arready_o || lane1_axi_arready_o)
        die(marker, "request did not appear only after registered capture");
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

  task automatic test_release_illegal_fail_closed;
    reg [2:0] state_before;
    reg owner_before;
    reg rr_before;
    begin
      do_reset("V8Q-ILLEGAL-FAIL-CLOSED");
      state_before = dut.state_q;
      owner_before = dut.owner_q;
      rr_before = dut.rr_q;
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
          dut.rr_q !== rr_before)
        die("V8Q-ILLEGAL-FAIL-CLOSED", "illegal lane changed arbiter state");
      expect_quiet("V8Q-ILLEGAL-FAIL-CLOSED");
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
        $display("[V8Q-MUT-ACTIVE:idle_fallthrough]");
        test_idle_registered("V8Q-MUT-IDLE-FALLTHROUGH");
      end
      12: begin
        $display("[V8Q-MUT-ACTIVE:reset_owner_residue]");
        do_reset("V8Q-MUT-RESET-OWNER-RESIDUE");
      end
      default: begin
        test_idle_registered("V8Q-BASE-IDLE");
        test_read0("V8Q-BASE-READ0");
        test_read1_isolation("V8Q-BASE-READ1");
        test_round_robin("V8Q-BASE-FAIRNESS");
        test_rr_terminal_only("V8Q-BASE-RR");
        test_write_aw_first("V8Q-BASE-AW-FIRST");
        test_write_w_first("V8Q-BASE-W-FIRST");
        test_write_same_cycle("V8Q-BASE-AW-W-SAME");
        test_reset_phase_matrix("V8Q-BASE-RESET-MATRIX");
`ifndef OOO_ASSERT
        test_release_illegal_fail_closed();
`endif
        $display("[V8Q-F0-TB][PASS] release/assert directed transport matrix");
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
