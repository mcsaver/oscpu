`include "define.v"

// Test-only AXI B-channel latency intervention.
//
// The run harness replaces the normal AxiDpiSlave source with an exact copy
// whose module name is changed to AxiDpiSlaveOwnerBDelayBase.  This wrapper
// keeps the production NpcSimTop instance bindings unchanged and forwards
// every channel except B without adding state.  The original slave still
// performs the DPI write and owns BRESP/BVALID; this wrapper only withholds the
// response handshake for the requested number of additional cycles.
module AxiDpiSlave (
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

  integer configured_delay_cycles_q;
  logic [31:0] delay_remaining_q;
  logic base_bvalid_w;
  logic base_bready_w;
  logic [1:0] base_bresp_w;

  wire delay_elapsed_w = (delay_remaining_q == 32'd0);

  initial begin
    configured_delay_cycles_q = -1;
    if (!$value$plusargs(
          "owner_b_delay_cycles=%d", configured_delay_cycles_q)) begin
      $fatal(1,
        "[OWNER-B-LATENCY-PROBE][FAIL] missing +owner_b_delay_cycles=<0|2>");
    end else if ((configured_delay_cycles_q != 0) &&
                 (configured_delay_cycles_q != 2)) begin
      $fatal(1,
        "[OWNER-B-LATENCY-PROBE][FAIL] unsupported delay_cycles=%0d",
        configured_delay_cycles_q);
    end else begin
      $display(
        "[OWNER-B-LATENCY-PROBE] instance=%m delay_cycles=%0d mode=test-only",
        configured_delay_cycles_q);
    end
  end

  assign s_axi_bvalid_o = base_bvalid_w && delay_elapsed_w;
  assign base_bready_w = s_axi_bready_i && delay_elapsed_w;
  assign s_axi_bresp_o = base_bresp_w;

  always_ff @(posedge clk) begin
    if (rst || !base_bvalid_w) begin
      delay_remaining_q <= configured_delay_cycles_q[31:0];
    end else if (!delay_elapsed_w) begin
      delay_remaining_q <= delay_remaining_q - 32'd1;
    end
  end

  AxiDpiSlaveOwnerBDelayBase u_base (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(s_axi_arvalid_i),
    .s_axi_arready_o(s_axi_arready_o),
    .s_axi_araddr_i(s_axi_araddr_i),
    .s_axi_arsize_i(s_axi_arsize_i),
    .s_axi_arprot_i(s_axi_arprot_i),
    .s_axi_rvalid_o(s_axi_rvalid_o),
    .s_axi_rready_i(s_axi_rready_i),
    .s_axi_rdata_o(s_axi_rdata_o),
    .s_axi_rresp_o(s_axi_rresp_o),
    .s_axi_awvalid_i(s_axi_awvalid_i),
    .s_axi_awready_o(s_axi_awready_o),
    .s_axi_awaddr_i(s_axi_awaddr_i),
    .s_axi_awsize_i(s_axi_awsize_i),
    .s_axi_wvalid_i(s_axi_wvalid_i),
    .s_axi_wready_o(s_axi_wready_o),
    .s_axi_wdata_i(s_axi_wdata_i),
    .s_axi_wstrb_i(s_axi_wstrb_i),
    .s_axi_bvalid_o(base_bvalid_w),
    .s_axi_bready_i(base_bready_w),
    .s_axi_bresp_o(base_bresp_w)
  );

`ifdef OOO_ASSERT
  always_ff @(posedge clk) begin
    if (!rst) begin
      if (base_bvalid_w && !delay_elapsed_w && s_axi_bvalid_o)
        $error("[OWNER-B-LATENCY-EARLY-VALID] BVALID escaped before countdown");
      if (base_bvalid_w && !delay_elapsed_w && base_bready_w)
        $error("[OWNER-B-LATENCY-EARLY-READY] base B consumed before countdown");
      if (s_axi_bvalid_o && !base_bvalid_w)
        $error("[OWNER-B-LATENCY-SPURIOUS-VALID] wrapper created a B response");
      if (s_axi_bresp_o !== base_bresp_w)
        $error("[OWNER-B-LATENCY-BRESP] wrapper changed BRESP");
    end
  end
`endif

endmodule
