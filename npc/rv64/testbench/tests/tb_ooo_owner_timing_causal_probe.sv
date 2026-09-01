`timescale 1ns/1ps
`include "define.v"

// L0 causal probe for the current store path:
//   lane0/lane1 -> OooDualMemAxiArbiter -> OooLsuAxiLaneAdapter -> slave
//
// The probe varies only the slave AW/W-to-B delay. It measures how that delay
// reaches the lane0 store terminal and a simultaneously offered lane1 read.
// This is diagnostic evidence; it does not alter architectural completion.
module tb_ooo_owner_timing_causal_probe;
  reg clk;
  reg rst;

  reg lane0_arvalid;
  wire lane0_arready;
  reg [63:0] lane0_araddr;
  wire lane0_rvalid;
  reg lane0_rready;
  wire [63:0] lane0_rdata;
  wire [1:0] lane0_rresp;
  reg lane0_awvalid;
  wire lane0_awready;
  reg [63:0] lane0_awaddr;
  reg lane0_wvalid;
  wire lane0_wready;
  reg [63:0] lane0_wdata;
  reg [7:0] lane0_wstrb;
  wire lane0_bvalid;
  reg lane0_bready;
  wire [1:0] lane0_bresp;

  reg lane1_arvalid;
  wire lane1_arready;
  reg [63:0] lane1_araddr;
  wire lane1_rvalid;
  reg lane1_rready;
  wire [63:0] lane1_rdata;
  wire [1:0] lane1_rresp;
  reg lane1_awvalid;
  wire lane1_awready;
  reg [63:0] lane1_awaddr;
  reg lane1_wvalid;
  wire lane1_wready;
  reg [63:0] lane1_wdata;
  reg [7:0] lane1_wstrb;
  wire lane1_bvalid;
  reg lane1_bready;
  wire [1:0] lane1_bresp;

  wire fabric_arvalid;
  wire fabric_arready;
  wire [63:0] fabric_araddr;
  wire [3:0] fabric_arid;
  wire [7:0] fabric_arlen;
  wire [2:0] fabric_arsize;
  wire [1:0] fabric_arburst;
  wire [2:0] fabric_arprot;
  wire fabric_rvalid;
  wire fabric_rready;
  wire [63:0] fabric_rdata;
  wire [1:0] fabric_rresp;
  wire fabric_awvalid;
  wire fabric_awready;
  wire [63:0] fabric_awaddr;
  wire [3:0] fabric_awid;
  wire [7:0] fabric_awlen;
  wire [2:0] fabric_awsize;
  wire [1:0] fabric_awburst;
  wire fabric_wvalid;
  wire fabric_wready;
  wire [63:0] fabric_wdata;
  wire [7:0] fabric_wstrb;
  wire fabric_wlast;
  wire fabric_bvalid;
  wire fabric_bready;
  wire [1:0] fabric_bresp;

  wire slave_arvalid;
  wire slave_arready;
  wire [63:0] slave_araddr;
  wire [2:0] slave_arsize;
  wire [2:0] slave_arprot;
  wire slave_rvalid;
  wire slave_rready;
  wire [63:0] slave_rdata;
  wire [1:0] slave_rresp;
  wire slave_awvalid;
  wire slave_awready;
  wire [63:0] slave_awaddr;
  wire [2:0] slave_awsize;
  wire slave_wvalid;
  wire slave_wready;
  wire [63:0] slave_wdata;
  wire [7:0] slave_wstrb;
  wire slave_bvalid;
  wire slave_bready;
  wire [1:0] slave_bresp;

  integer cycle_q;
  integer fabric_aww_cycle_q;
  integer lane0_b_cycle_q;
  integer lane1_ar_cycle_q;
  integer peer_offer_cycle_q;
  integer peer_blocked_b_cycles_q;
  integer peer_early_admission_q;
  integer b_delay_cfg_q;
  integer b_countdown_q;
  reg slave_aw_seen_q;
  reg slave_w_seen_q;
  reg slave_b_pending_q;
  reg slave_r_pending_q;

  OooDualMemAxiArbiter u_arbiter (
    .clk(clk),
    .rst(rst),
    .lane0_axi_arvalid_i(lane0_arvalid),
    .lane0_axi_arready_o(lane0_arready),
    .lane0_axi_araddr_i(lane0_araddr),
    .lane0_axi_arid_i(4'h0),
    .lane0_axi_arlen_i(8'h00),
    .lane0_axi_arsize_i(3'd3),
    .lane0_axi_arburst_i(2'b01),
    .lane0_axi_arprot_i(3'b000),
    .lane0_axi_rvalid_o(lane0_rvalid),
    .lane0_axi_rready_i(lane0_rready),
    .lane0_axi_rdata_o(lane0_rdata),
    .lane0_axi_rresp_o(lane0_rresp),
    .lane0_axi_awvalid_i(lane0_awvalid),
    .lane0_axi_awready_o(lane0_awready),
    .lane0_axi_awaddr_i(lane0_awaddr),
    .lane0_axi_awid_i(4'h0),
    .lane0_axi_awlen_i(8'h00),
    .lane0_axi_awsize_i(3'd3),
    .lane0_axi_awburst_i(2'b01),
    .lane0_axi_wvalid_i(lane0_wvalid),
    .lane0_axi_wready_o(lane0_wready),
    .lane0_axi_wdata_i(lane0_wdata),
    .lane0_axi_wstrb_i(lane0_wstrb),
    .lane0_axi_wlast_i(1'b1),
    .lane0_axi_bvalid_o(lane0_bvalid),
    .lane0_axi_bready_i(lane0_bready),
    .lane0_axi_bresp_o(lane0_bresp),
    .lane1_axi_arvalid_i(lane1_arvalid),
    .lane1_axi_arready_o(lane1_arready),
    .lane1_axi_araddr_i(lane1_araddr),
    .lane1_axi_arid_i(4'h1),
    .lane1_axi_arlen_i(8'h00),
    .lane1_axi_arsize_i(3'd3),
    .lane1_axi_arburst_i(2'b01),
    .lane1_axi_arprot_i(3'b000),
    .lane1_axi_rvalid_o(lane1_rvalid),
    .lane1_axi_rready_i(lane1_rready),
    .lane1_axi_rdata_o(lane1_rdata),
    .lane1_axi_rresp_o(lane1_rresp),
    .lane1_axi_awvalid_i(lane1_awvalid),
    .lane1_axi_awready_o(lane1_awready),
    .lane1_axi_awaddr_i(lane1_awaddr),
    .lane1_axi_awid_i(4'h1),
    .lane1_axi_awlen_i(8'h00),
    .lane1_axi_awsize_i(3'd3),
    .lane1_axi_awburst_i(2'b01),
    .lane1_axi_wvalid_i(lane1_wvalid),
    .lane1_axi_wready_o(lane1_wready),
    .lane1_axi_wdata_i(lane1_wdata),
    .lane1_axi_wstrb_i(lane1_wstrb),
    .lane1_axi_wlast_i(1'b1),
    .lane1_axi_bvalid_o(lane1_bvalid),
    .lane1_axi_bready_i(lane1_bready),
    .lane1_axi_bresp_o(lane1_bresp),
    .d_axi_arvalid_o(fabric_arvalid),
    .d_axi_arready_i(fabric_arready),
    .d_axi_araddr_o(fabric_araddr),
    .d_axi_arid_o(fabric_arid),
    .d_axi_arlen_o(fabric_arlen),
    .d_axi_arsize_o(fabric_arsize),
    .d_axi_arburst_o(fabric_arburst),
    .d_axi_arprot_o(fabric_arprot),
    .d_axi_rvalid_i(fabric_rvalid),
    .d_axi_rready_o(fabric_rready),
    .d_axi_rdata_i(fabric_rdata),
    .d_axi_rresp_i(fabric_rresp),
    .d_axi_awvalid_o(fabric_awvalid),
    .d_axi_awready_i(fabric_awready),
    .d_axi_awaddr_o(fabric_awaddr),
    .d_axi_awid_o(fabric_awid),
    .d_axi_awlen_o(fabric_awlen),
    .d_axi_awsize_o(fabric_awsize),
    .d_axi_awburst_o(fabric_awburst),
    .d_axi_wvalid_o(fabric_wvalid),
    .d_axi_wready_i(fabric_wready),
    .d_axi_wdata_o(fabric_wdata),
    .d_axi_wstrb_o(fabric_wstrb),
    .d_axi_wlast_o(fabric_wlast),
    .d_axi_bvalid_i(fabric_bvalid),
    .d_axi_bready_o(fabric_bready),
    .d_axi_bresp_i(fabric_bresp)
  );

  OooLsuAxiLaneAdapter u_adapter (
    .clk(clk),
    .rst(rst),
    .u_axi_split_allowed_i(1'b1),
    .u_axi_arvalid_i(fabric_arvalid),
    .u_axi_arready_o(fabric_arready),
    .u_axi_araddr_i(fabric_araddr),
    .u_axi_arsize_i(fabric_arsize),
    .u_axi_arprot_i(fabric_arprot),
    .u_axi_rvalid_o(fabric_rvalid),
    .u_axi_rready_i(fabric_rready),
    .u_axi_rdata_o(fabric_rdata),
    .u_axi_rresp_o(fabric_rresp),
    .u_axi_awvalid_i(fabric_awvalid),
    .u_axi_awready_o(fabric_awready),
    .u_axi_awaddr_i(fabric_awaddr),
    .u_axi_awsize_i(fabric_awsize),
    .u_axi_wvalid_i(fabric_wvalid),
    .u_axi_wready_o(fabric_wready),
    .u_axi_wdata_i(fabric_wdata),
    .u_axi_wstrb_i(fabric_wstrb),
    .u_axi_bvalid_o(fabric_bvalid),
    .u_axi_bready_i(fabric_bready),
    .u_axi_bresp_o(fabric_bresp),
    .d_axi_arvalid_o(slave_arvalid),
    .d_axi_arready_i(slave_arready),
    .d_axi_araddr_o(slave_araddr),
    .d_axi_arsize_o(slave_arsize),
    .d_axi_arprot_o(slave_arprot),
    .d_axi_rvalid_i(slave_rvalid),
    .d_axi_rready_o(slave_rready),
    .d_axi_rdata_i(slave_rdata),
    .d_axi_rresp_i(slave_rresp),
    .d_axi_awvalid_o(slave_awvalid),
    .d_axi_awready_i(slave_awready),
    .d_axi_awaddr_o(slave_awaddr),
    .d_axi_awsize_o(slave_awsize),
    .d_axi_wvalid_o(slave_wvalid),
    .d_axi_wready_i(slave_wready),
    .d_axi_wdata_o(slave_wdata),
    .d_axi_wstrb_o(slave_wstrb),
    .d_axi_bvalid_i(slave_bvalid),
    .d_axi_bready_o(slave_bready),
    .d_axi_bresp_i(slave_bresp)
  );

  assign slave_arready = 1'b1;
  assign slave_awready = 1'b1;
  assign slave_wready = 1'b1;
  assign slave_rvalid = slave_r_pending_q;
  assign slave_rdata = 64'h55aa_0123_4567_89ab;
  assign slave_rresp = 2'b00;
  assign slave_bvalid = slave_b_pending_q && (b_countdown_q == 0);
  assign slave_bresp = 2'b00;

  initial clk = 1'b0;
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst) begin
      cycle_q <= 0;
      fabric_aww_cycle_q <= -1;
      lane0_b_cycle_q <= -1;
      lane1_ar_cycle_q <= -1;
      peer_blocked_b_cycles_q <= 0;
      peer_early_admission_q <= 0;
    end else begin
      cycle_q <= cycle_q + 1;
      if (fabric_awvalid && fabric_awready &&
          fabric_wvalid && fabric_wready)
        fabric_aww_cycle_q <= cycle_q;
      if (lane0_bvalid && lane0_bready)
        lane0_b_cycle_q <= cycle_q;
      if (lane1_arvalid && lane1_arready) begin
        lane1_ar_cycle_q <= cycle_q;
        if (lane0_b_cycle_q < 0)
          peer_early_admission_q <= 1;
      end
      if (lane1_arvalid && !lane1_arready && slave_bready)
        peer_blocked_b_cycles_q <= peer_blocked_b_cycles_q + 1;
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      slave_aw_seen_q <= 1'b0;
      slave_w_seen_q <= 1'b0;
      slave_b_pending_q <= 1'b0;
      slave_r_pending_q <= 1'b0;
      b_countdown_q <= 0;
    end else begin
      if (slave_awvalid && slave_awready)
        slave_aw_seen_q <= 1'b1;
      if (slave_wvalid && slave_wready)
        slave_w_seen_q <= 1'b1;

      if (!slave_b_pending_q &&
          (slave_aw_seen_q || (slave_awvalid && slave_awready)) &&
          (slave_w_seen_q || (slave_wvalid && slave_wready))) begin
        slave_aw_seen_q <= 1'b0;
        slave_w_seen_q <= 1'b0;
        slave_b_pending_q <= 1'b1;
        b_countdown_q <= b_delay_cfg_q;
      end else if (slave_b_pending_q && (b_countdown_q > 0)) begin
        b_countdown_q <= b_countdown_q - 1;
      end

      if (slave_bvalid && slave_bready)
        slave_b_pending_q <= 1'b0;

      if (slave_arvalid && slave_arready)
        slave_r_pending_q <= 1'b1;
      if (slave_rvalid && slave_rready)
        slave_r_pending_q <= 1'b0;
    end
  end

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic fail(input string reason);
    begin
      $display("[OWNER-TIMING-CAUSAL-PROBE][FAIL] %0s", reason);
      $fatal(1);
    end
  endtask

  task automatic clear_inputs;
    begin
      lane0_arvalid = 1'b0;
      lane0_araddr = 64'h0000_0000_8000_1000;
      lane0_rready = 1'b1;
      lane0_awvalid = 1'b0;
      lane0_awaddr = 64'h0000_0000_8000_2000;
      lane0_wvalid = 1'b0;
      lane0_wdata = 64'h0123_4567_89ab_cdef;
      lane0_wstrb = 8'hff;
      lane0_bready = 1'b1;
      lane1_arvalid = 1'b0;
      lane1_araddr = 64'h0000_0000_8000_3000;
      lane1_rready = 1'b1;
      lane1_awvalid = 1'b0;
      lane1_awaddr = 64'h0000_0000_8000_4000;
      lane1_wvalid = 1'b0;
      lane1_wdata = 64'hfedc_ba98_7654_3210;
      lane1_wstrb = 8'hff;
      lane1_bready = 1'b1;
      peer_offer_cycle_q = -1;
    end
  endtask

  task automatic do_reset;
    begin
      @(negedge clk);
      clear_inputs();
      rst = 1'b1;
      tick();
      tick();
      @(negedge clk);
      rst = 1'b0;
      tick();
    end
  endtask

  task automatic run_case(
    input integer b_delay,
    input integer with_peer,
    output integer terminal_cycles,
    output integer peer_admission_cycles,
    output integer peer_blocked_b_cycles
  );
    integer timeout;
    begin
      b_delay_cfg_q = b_delay;
      do_reset();

      @(negedge clk);
      lane0_awvalid = 1'b1;
      lane0_wvalid = 1'b1;
      tick();

      if (with_peer != 0) begin
        @(negedge clk);
        lane1_arvalid = 1'b1;
        peer_offer_cycle_q = cycle_q;
      end

      timeout = 0;
      while ((fabric_aww_cycle_q < 0) && (timeout < 20)) begin
        tick();
        timeout = timeout + 1;
      end
      if (fabric_aww_cycle_q < 0)
        fail("fabric AW/W handshake timeout");

      @(negedge clk);
      lane0_awvalid = 1'b0;
      lane0_wvalid = 1'b0;

      timeout = 0;
      while ((lane0_b_cycle_q < 0) && (timeout < 40)) begin
        tick();
        timeout = timeout + 1;
      end
      if (lane0_b_cycle_q < 0)
        fail("lane0 B terminal timeout");
      terminal_cycles = lane0_b_cycle_q - fabric_aww_cycle_q;

      if (with_peer != 0) begin
        timeout = 0;
        while ((lane1_ar_cycle_q < 0) && (timeout < 20)) begin
          tick();
          timeout = timeout + 1;
        end
        if (lane1_ar_cycle_q < 0)
          fail("lane1 peer AR admission timeout");
        if (peer_early_admission_q != 0)
          fail("lane1 peer request crossed the lane0 B terminal");
        peer_admission_cycles = lane1_ar_cycle_q - peer_offer_cycle_q;
        peer_blocked_b_cycles = peer_blocked_b_cycles_q;

        @(negedge clk);
        lane1_arvalid = 1'b0;
        timeout = 0;
        while (!lane1_rvalid && (timeout < 20)) begin
          tick();
          timeout = timeout + 1;
        end
        if (!lane1_rvalid)
          fail("lane1 peer R terminal timeout");
        tick();
      end else begin
        peer_admission_cycles = -1;
        peer_blocked_b_cycles = -1;
      end

      $display("[OWNER-TIMING-CAUSAL-PROBE] b_delay=%0d peer=%0d store_terminal_cycles=%0d peer_admission_cycles=%0d peer_blocked_b_cycles=%0d early_peer_admission=%0d",
               b_delay, with_peer, terminal_cycles, peer_admission_cycles,
               peer_blocked_b_cycles, peer_early_admission_q);
    end
  endtask

  integer iso_term_0;
  integer iso_term_2;
  integer iso_term_5;
  integer peer_term_0;
  integer peer_term_2;
  integer peer_term_5;
  integer peer_wait_0;
  integer peer_wait_2;
  integer peer_wait_5;
  integer peer_b_0;
  integer peer_b_2;
  integer peer_b_5;
  integer unused_wait;
  integer unused_block;

  initial begin
    rst = 1'b1;
    b_delay_cfg_q = 0;
    clear_inputs();

    run_case(0, 0, iso_term_0, unused_wait, unused_block);
    run_case(2, 0, iso_term_2, unused_wait, unused_block);
    run_case(5, 0, iso_term_5, unused_wait, unused_block);
    run_case(0, 1, peer_term_0, peer_wait_0, peer_b_0);
    run_case(2, 1, peer_term_2, peer_wait_2, peer_b_2);
    run_case(5, 1, peer_term_5, peer_wait_5, peer_b_5);

    if ((iso_term_2 - iso_term_0) != 2 ||
        (iso_term_5 - iso_term_0) != 5)
      fail("store terminal does not track B delay with unit slope");
    if ((peer_wait_2 - peer_wait_0) != 2 ||
        (peer_wait_5 - peer_wait_0) != 5)
      fail("peer admission does not track B delay with unit slope");
    if ((peer_b_2 - peer_b_0) != 2 ||
        (peer_b_5 - peer_b_0) != 5)
      fail("peer B-phase blocking does not track B delay with unit slope");
    if ((iso_term_0 != peer_term_0) ||
        (iso_term_2 != peer_term_2) ||
        (iso_term_5 != peer_term_5))
      fail("peer offer changed store terminal latency");
    if ((iso_term_0 != 1) || (iso_term_2 != 3) || (iso_term_5 != 6))
      fail("adapter write-path fall-through absolute terminal latency mismatch");
    if ((peer_wait_0 != 2) || (peer_wait_2 != 4) || (peer_wait_5 != 7))
      fail("adapter write-path fall-through peer admission mismatch");
    if ((peer_b_0 != 1) || (peer_b_2 != 3) || (peer_b_5 != 6))
      fail("B-phase blocking absolute latency mismatch");

    $display("[OWNER-TIMING-CAUSAL-PROBE-ABSOLUTE] adapter_input_aw_w_fallthrough=1 adapter_final_b_fallthrough=1 arbiter_idle_write_admission=1 store_terminal=1,3,6 peer_admission=2,4,7 peer_b_block=1,3,6");

    $display("[OWNER-TIMING-CAUSAL-PROBE-SUMMARY] write_admission_cycle_saved=1 terminal_b_delay_slope=1 peer_admission_b_delay_slope=1 peer_b_block_slope=1 early_peer_admission=0 observer_noninterference=1 conclusion=H1_H2_COUPLED_RESEARCH_REQUIRED");
    $display("[PASS] tb_ooo_owner_timing_causal_probe");
    $finish;
  end

  initial begin
    #100000;
    fail("global timeout");
  end
endmodule
