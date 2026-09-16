`timescale 1ns/1ps
`include "define.v"

// Minimal stand-in for the generated, renamed production AxiDpiSlave.  The
// wrapper test only needs one AW/W-to-B transaction; all non-B outputs remain
// deterministic so pass-through wiring is also checked.
module AxiDpiSlaveOwnerBDelayBase (
  input logic clk,
  input logic rst,
  input logic s_axi_arvalid_i,
  output logic s_axi_arready_o,
  input logic [`XLEN-1:0] s_axi_araddr_i,
  input logic [2:0] s_axi_arsize_i,
  input logic [2:0] s_axi_arprot_i,
  output logic s_axi_rvalid_o,
  input logic s_axi_rready_i,
  output logic [`XLEN-1:0] s_axi_rdata_o,
  output logic [1:0] s_axi_rresp_o,
  input logic s_axi_awvalid_i,
  output logic s_axi_awready_o,
  input logic [`XLEN-1:0] s_axi_awaddr_i,
  input logic [2:0] s_axi_awsize_i,
  input logic s_axi_wvalid_i,
  output logic s_axi_wready_o,
  input logic [`XLEN-1:0] s_axi_wdata_i,
  input logic [`STRB_W-1:0] s_axi_wstrb_i,
  output logic s_axi_bvalid_o,
  input logic s_axi_bready_i,
  output logic [1:0] s_axi_bresp_o
);
  assign s_axi_arready_o = 1'b1;
  assign s_axi_rvalid_o = 1'b0;
  assign s_axi_rdata_o = {`XLEN{1'b0}};
  assign s_axi_rresp_o = 2'b00;
  assign s_axi_awready_o = !s_axi_bvalid_o;
  assign s_axi_wready_o = !s_axi_bvalid_o;
  assign s_axi_bresp_o = 2'b00;

  wire write_fire_w = s_axi_awvalid_i && s_axi_awready_o &&
                      s_axi_wvalid_i && s_axi_wready_o;

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axi_bvalid_o <= 1'b0;
    end else begin
      if (s_axi_bvalid_o && s_axi_bready_i)
        s_axi_bvalid_o <= 1'b0;
      if (write_fire_w)
        s_axi_bvalid_o <= 1'b1;
    end
  end
endmodule

module tb_axi_dpi_owner_b_delay_probe;
  logic clk;
  logic rst;
  logic arvalid;
  wire arready;
  logic [`XLEN-1:0] araddr;
  logic [2:0] arsize;
  logic [2:0] arprot;
  wire rvalid;
  logic rready;
  wire [`XLEN-1:0] rdata;
  wire [1:0] rresp;
  logic awvalid;
  wire awready;
  logic [`XLEN-1:0] awaddr;
  logic [2:0] awsize;
  logic wvalid;
  wire wready;
  logic [`XLEN-1:0] wdata;
  logic [`STRB_W-1:0] wstrb;
  wire bvalid;
  logic bready;
  wire [1:0] bresp;

  integer expected_delay;
  integer cycle_q;
  integer base_cycle;
  integer wrapper_cycle;
  integer failures;

  AxiDpiSlave dut (
    .clk(clk), .rst(rst),
    .s_axi_arvalid_i(arvalid), .s_axi_arready_o(arready),
    .s_axi_araddr_i(araddr), .s_axi_arsize_i(arsize),
    .s_axi_arprot_i(arprot), .s_axi_rvalid_o(rvalid),
    .s_axi_rready_i(rready), .s_axi_rdata_o(rdata),
    .s_axi_rresp_o(rresp), .s_axi_awvalid_i(awvalid),
    .s_axi_awready_o(awready), .s_axi_awaddr_i(awaddr),
    .s_axi_awsize_i(awsize), .s_axi_wvalid_i(wvalid),
    .s_axi_wready_o(wready), .s_axi_wdata_i(wdata),
    .s_axi_wstrb_i(wstrb), .s_axi_bvalid_o(bvalid),
    .s_axi_bready_i(bready), .s_axi_bresp_o(bresp)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst)
      cycle_q <= 0;
    else
      cycle_q <= cycle_q + 1;
  end

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic check(input string label, input logic condition);
    begin
      if (!condition) begin
        $display("[OWNER-B-LATENCY-WRAPPER][FAIL] %s", label);
        failures = failures + 1;
      end
    end
  endtask

  initial begin
    failures = 0;
    expected_delay = -1;
    if (!$value$plusargs("owner_b_delay_cycles=%d", expected_delay))
      $fatal(1, "[OWNER-B-LATENCY-WRAPPER][FAIL] test plusarg missing");

    rst = 1'b1;
    arvalid = 1'b0;
    araddr = 64'h8000_0000;
    arsize = 3'd3;
    arprot = 3'b000;
    rready = 1'b1;
    awvalid = 1'b0;
    awaddr = 64'h8000_0040;
    awsize = 3'd3;
    wvalid = 1'b0;
    wdata = 64'h0123_4567_89ab_cdef;
    wstrb = {`STRB_W{1'b1}};
    bready = 1'b0;
    cycle_q = 0;

    repeat (2) tick();
    rst = 1'b0;
    tick();
    check("read path ready passes through", arready === 1'b1);
    check("read path valid passes through", rvalid === 1'b0);
    check("AW ready passes through", awready === 1'b1);
    check("W ready passes through", wready === 1'b1);

    awvalid = 1'b1;
    wvalid = 1'b1;
    tick();
    awvalid = 1'b0;
    wvalid = 1'b0;
    check("base produced B response", dut.base_bvalid_w === 1'b1);
    base_cycle = cycle_q;

    while (!bvalid && (cycle_q - base_cycle <= 4))
      tick();
    wrapper_cycle = cycle_q;
    check("wrapper produced B response", bvalid === 1'b1);
    check("configured delay is exact",
          (wrapper_cycle - base_cycle) == expected_delay);
    check("BRESP passes through", bresp === 2'b00);
    check("base response is not consumed early", dut.base_bvalid_w === 1'b1);

    bready = 1'b1;
    tick();
    bready = 1'b0;
    check("B response consumed exactly once", bvalid === 1'b0);

    if (failures == 0) begin
      $display(
        "[OWNER-B-LATENCY-WRAPPER][PASS] configured=%0d observed=%0d non_b_passthrough=1",
        expected_delay, wrapper_cycle - base_cycle);
      $finish;
    end
    $fatal(1, "[OWNER-B-LATENCY-WRAPPER][FAIL] failures=%0d", failures);
  end
endmodule
