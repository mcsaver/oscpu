`include "define.v"

// NPC 总线壳：把当前 IFU/LSU 两个 single-beat AXI-like master
// 打包后交给通用 crossbar。后续加设备只扩展 slave 侧地址表和端口，
// 不再把设备译码塞回 NpcCore 或 NpcSimTop。
module NpcAxiBus #(
  parameter S_COUNT = 1,
  parameter DEFAULT_SLAVE = 0,
  parameter [S_COUNT*`XLEN-1:0] SLAVE_BASE = {S_COUNT{32'h0000_0000}},
  parameter [S_COUNT*`XLEN-1:0] SLAVE_MASK = {S_COUNT{32'h0000_0000}}
) (
  input clk,
  input rst,

  input ifu_axi_arvalid_i,
  output ifu_axi_arready_o,
  input [`XLEN-1:0] ifu_axi_araddr_i,
  input ifu_axi_abort_i,
  output ifu_axi_rvalid_o,
  input ifu_axi_rready_i,
  output [`XLEN-1:0] ifu_axi_rdata_o,
  output [1:0] ifu_axi_rresp_o,

  input lsu_axi_arvalid_i,
  output lsu_axi_arready_o,
  input [`XLEN-1:0] lsu_axi_araddr_i,
  input lsu_axi_abort_i,
  output lsu_axi_rvalid_o,
  input lsu_axi_rready_i,
  output [`XLEN-1:0] lsu_axi_rdata_o,
  output [1:0] lsu_axi_rresp_o,
  input lsu_axi_awvalid_i,
  output lsu_axi_awready_o,
  input [`XLEN-1:0] lsu_axi_awaddr_i,
  input lsu_axi_wvalid_i,
  output lsu_axi_wready_o,
  input [`XLEN-1:0] lsu_axi_wdata_i,
  input [`STRB_W-1:0] lsu_axi_wstrb_i,
  output lsu_axi_bvalid_o,
  input lsu_axi_bready_i,
  output [1:0] lsu_axi_bresp_o,

  output [S_COUNT-1:0] s_axi_arvalid_o,
  input [S_COUNT-1:0] s_axi_arready_i,
  output [S_COUNT*`XLEN-1:0] s_axi_araddr_o,
  output [S_COUNT-1:0] s_axi_aruser_o,
  input [S_COUNT-1:0] s_axi_rvalid_i,
  output [S_COUNT-1:0] s_axi_rready_o,
  input [S_COUNT*`XLEN-1:0] s_axi_rdata_i,
  input [S_COUNT*2-1:0] s_axi_rresp_i,

  output [S_COUNT-1:0] s_axi_awvalid_o,
  input [S_COUNT-1:0] s_axi_awready_i,
  output [S_COUNT*`XLEN-1:0] s_axi_awaddr_o,
  output [S_COUNT-1:0] s_axi_wvalid_o,
  input [S_COUNT-1:0] s_axi_wready_i,
  output [S_COUNT*`XLEN-1:0] s_axi_wdata_o,
  output [S_COUNT*`STRB_W-1:0] s_axi_wstrb_o,
  input [S_COUNT-1:0] s_axi_bvalid_i,
  output [S_COUNT-1:0] s_axi_bready_o,
  input [S_COUNT*2-1:0] s_axi_bresp_i
);

  localparam M_COUNT = 2;
  localparam M_IFU = 0;
  localparam M_LSU = 1;
  localparam ARUSER_IFETCH = 1'b0;
  localparam ARUSER_LOAD = 1'b1;

  wire [M_COUNT-1:0] m_arvalid_w;
  wire [M_COUNT-1:0] m_arready_w;
  wire [M_COUNT*`XLEN-1:0] m_araddr_w;
  wire [M_COUNT-1:0] m_aruser_w;
  wire [M_COUNT-1:0] m_read_abort_w;
  wire [M_COUNT-1:0] m_rvalid_w;
  wire [M_COUNT-1:0] m_rready_w;
  wire [M_COUNT*`XLEN-1:0] m_rdata_w;
  wire [M_COUNT*2-1:0] m_rresp_w;

  wire [M_COUNT-1:0] m_awvalid_w;
  wire [M_COUNT-1:0] m_awready_w;
  wire [M_COUNT*`XLEN-1:0] m_awaddr_w;
  wire [M_COUNT-1:0] m_wvalid_w;
  wire [M_COUNT-1:0] m_wready_w;
  wire [M_COUNT*`XLEN-1:0] m_wdata_w;
  wire [M_COUNT*`STRB_W-1:0] m_wstrb_w;
  wire [M_COUNT-1:0] m_bvalid_w;
  wire [M_COUNT-1:0] m_bready_w;
  wire [M_COUNT*2-1:0] m_bresp_w;

  assign m_arvalid_w[M_IFU] = ifu_axi_arvalid_i;
  assign m_arvalid_w[M_LSU] = lsu_axi_arvalid_i;
  assign m_araddr_w[M_IFU*`XLEN +: `XLEN] = ifu_axi_araddr_i;
  assign m_araddr_w[M_LSU*`XLEN +: `XLEN] = lsu_axi_araddr_i;
  assign m_aruser_w[M_IFU] = ARUSER_IFETCH;
  assign m_aruser_w[M_LSU] = ARUSER_LOAD;
  assign m_read_abort_w[M_IFU] = ifu_axi_abort_i;
  assign m_read_abort_w[M_LSU] = lsu_axi_abort_i;
  assign m_rready_w[M_IFU] = ifu_axi_rready_i;
  assign m_rready_w[M_LSU] = lsu_axi_rready_i;

  assign ifu_axi_arready_o = m_arready_w[M_IFU];
  assign lsu_axi_arready_o = m_arready_w[M_LSU];
  assign ifu_axi_rvalid_o = m_rvalid_w[M_IFU];
  assign lsu_axi_rvalid_o = m_rvalid_w[M_LSU];
  assign ifu_axi_rdata_o = m_rdata_w[M_IFU*`XLEN +: `XLEN];
  assign lsu_axi_rdata_o = m_rdata_w[M_LSU*`XLEN +: `XLEN];
  assign ifu_axi_rresp_o = m_rresp_w[M_IFU*2 +: 2];
  assign lsu_axi_rresp_o = m_rresp_w[M_LSU*2 +: 2];

  assign m_awvalid_w[M_IFU] = 1'b0;
  assign m_awvalid_w[M_LSU] = lsu_axi_awvalid_i;
  assign m_awaddr_w[M_IFU*`XLEN +: `XLEN] = {`XLEN{1'b0}};
  assign m_awaddr_w[M_LSU*`XLEN +: `XLEN] = lsu_axi_awaddr_i;
  assign m_wvalid_w[M_IFU] = 1'b0;
  assign m_wvalid_w[M_LSU] = lsu_axi_wvalid_i;
  assign m_wdata_w[M_IFU*`XLEN +: `XLEN] = {`XLEN{1'b0}};
  assign m_wdata_w[M_LSU*`XLEN +: `XLEN] = lsu_axi_wdata_i;
  assign m_wstrb_w[M_IFU*`STRB_W +: `STRB_W] = {`STRB_W{1'b0}};
  assign m_wstrb_w[M_LSU*`STRB_W +: `STRB_W] = lsu_axi_wstrb_i;
  assign m_bready_w[M_IFU] = 1'b0;
  assign m_bready_w[M_LSU] = lsu_axi_bready_i;

  assign lsu_axi_awready_o = m_awready_w[M_LSU];
  assign lsu_axi_wready_o = m_wready_w[M_LSU];
  assign lsu_axi_bvalid_o = m_bvalid_w[M_LSU];
  assign lsu_axi_bresp_o = m_bresp_w[M_LSU*2 +: 2];
  wire unused_ifu_bresp_w = |m_bresp_w[M_IFU*2 +: 2];

  AxiLiteXbar #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W),
    .ARUSER_W(1),
    .M_COUNT(M_COUNT),
    .S_COUNT(S_COUNT),
    .DEFAULT_SLAVE(DEFAULT_SLAVE),
    .SLAVE_BASE(SLAVE_BASE),
    .SLAVE_MASK(SLAVE_MASK)
  ) u_xbar (
    .clk(clk),
    .rst(rst),
    .m_arvalid_i(m_arvalid_w),
    .m_arready_o(m_arready_w),
    .m_araddr_i(m_araddr_w),
    .m_aruser_i(m_aruser_w),
    .m_read_abort_i(m_read_abort_w),
    .m_rvalid_o(m_rvalid_w),
    .m_rready_i(m_rready_w),
    .m_rdata_o(m_rdata_w),
    .m_rresp_o(m_rresp_w),
    .m_awvalid_i(m_awvalid_w),
    .m_awready_o(m_awready_w),
    .m_awaddr_i(m_awaddr_w),
    .m_wvalid_i(m_wvalid_w),
    .m_wready_o(m_wready_w),
    .m_wdata_i(m_wdata_w),
    .m_wstrb_i(m_wstrb_w),
    .m_bvalid_o(m_bvalid_w),
    .m_bready_i(m_bready_w),
    .m_bresp_o(m_bresp_w),
    .s_arvalid_o(s_axi_arvalid_o),
    .s_arready_i(s_axi_arready_i),
    .s_araddr_o(s_axi_araddr_o),
    .s_aruser_o(s_axi_aruser_o),
    .s_rvalid_i(s_axi_rvalid_i),
    .s_rready_o(s_axi_rready_o),
    .s_rdata_i(s_axi_rdata_i),
    .s_rresp_i(s_axi_rresp_i),
    .s_awvalid_o(s_axi_awvalid_o),
    .s_awready_i(s_axi_awready_i),
    .s_awaddr_o(s_axi_awaddr_o),
    .s_wvalid_o(s_axi_wvalid_o),
    .s_wready_i(s_axi_wready_i),
    .s_wdata_o(s_axi_wdata_o),
    .s_wstrb_o(s_axi_wstrb_o),
    .s_bvalid_i(s_axi_bvalid_i),
    .s_bready_o(s_axi_bready_o),
    .s_bresp_i(s_axi_bresp_i)
  );

endmodule
