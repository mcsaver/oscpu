`include "define.v"

// NPC 总线壳：把当前 IFU/LSU 两个 single-beat AXI-like master
// 打包后交给通用 crossbar。后续加设备只扩展 slave 侧地址表和端口，
// 不再把设备译码塞回 NpcCore 或 NpcSimTop。
module NpcAxiBus #(
  parameter S_COUNT = 1,
  parameter DEFAULT_SLAVE = 0,
  parameter [S_COUNT*`XLEN-1:0] SLAVE_BASE = {S_COUNT{32'h0000_0000}},
  parameter [S_COUNT*`XLEN-1:0] SLAVE_MASK = {S_COUNT{32'h0000_0000}},
  parameter [S_COUNT-1:0] SLAVE_EXEC_MASK = {S_COUNT{1'b1}}
) (
  input clk,
  input rst,

  input ifu_axi_arvalid_i,
  output ifu_axi_arready_o,
  input [`XLEN-1:0] ifu_axi_araddr_i,
  input [3:0] ifu_axi_arid_i,
  input [7:0] ifu_axi_arlen_i,
  input [2:0] ifu_axi_arsize_i,
  input [1:0] ifu_axi_arburst_i,
  input [2:0] ifu_axi_arprot_i,
  output ifu_axi_rvalid_o,
  input ifu_axi_rready_i,
  output [`XLEN-1:0] ifu_axi_rdata_o,
  output [1:0] ifu_axi_rresp_o,
  // HW-managed A 更新：取指桥写通道(写回 PTE 置 A 位), 接 xbar 现成 M_IFU 写 master 口。
  input ifu_axi_awvalid_i,
  output ifu_axi_awready_o,
  input [`XLEN-1:0] ifu_axi_awaddr_i,
  input [3:0] ifu_axi_awid_i,
  input [7:0] ifu_axi_awlen_i,
  input [2:0] ifu_axi_awsize_i,
  input [1:0] ifu_axi_awburst_i,
  input ifu_axi_wvalid_i,
  output ifu_axi_wready_o,
  input [`XLEN-1:0] ifu_axi_wdata_i,
  input [`STRB_W-1:0] ifu_axi_wstrb_i,
  input ifu_axi_wlast_i,
  output ifu_axi_bvalid_o,
  input ifu_axi_bready_i,
  output [1:0] ifu_axi_bresp_o,

  input lsu_axi_arvalid_i,
  output lsu_axi_arready_o,
  input [`XLEN-1:0] lsu_axi_araddr_i,
  input [3:0] lsu_axi_arid_i,
  input [7:0] lsu_axi_arlen_i,
  input [2:0] lsu_axi_arsize_i,
  input [1:0] lsu_axi_arburst_i,
  input [2:0] lsu_axi_arprot_i,
  output lsu_axi_rvalid_o,
  input lsu_axi_rready_i,
  output [`XLEN-1:0] lsu_axi_rdata_o,
  output [1:0] lsu_axi_rresp_o,
  input lsu_axi_awvalid_i,
  output lsu_axi_awready_o,
  input [`XLEN-1:0] lsu_axi_awaddr_i,
  input [3:0] lsu_axi_awid_i,
  input [7:0] lsu_axi_awlen_i,
  input [2:0] lsu_axi_awsize_i,
  input [1:0] lsu_axi_awburst_i,
  input lsu_axi_wvalid_i,
  output lsu_axi_wready_o,
  input [`XLEN-1:0] lsu_axi_wdata_i,
  input [`STRB_W-1:0] lsu_axi_wstrb_i,
  input lsu_axi_wlast_i,
  output lsu_axi_bvalid_o,
  input lsu_axi_bready_i,
  output [1:0] lsu_axi_bresp_o,

  output [S_COUNT-1:0] s_axi_arvalid_o,
  input [S_COUNT-1:0] s_axi_arready_i,
  output [S_COUNT*`XLEN-1:0] s_axi_araddr_o,
  output [S_COUNT*3-1:0] s_axi_arsize_o,
  output [S_COUNT*3-1:0] s_axi_arprot_o,
  input [S_COUNT-1:0] s_axi_rvalid_i,
  output [S_COUNT-1:0] s_axi_rready_o,
  input [S_COUNT*`XLEN-1:0] s_axi_rdata_i,
  input [S_COUNT*2-1:0] s_axi_rresp_i,

  output [S_COUNT-1:0] s_axi_awvalid_o,
  input [S_COUNT-1:0] s_axi_awready_i,
  output [S_COUNT*`XLEN-1:0] s_axi_awaddr_o,
  output [S_COUNT*3-1:0] s_axi_awsize_o,
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

  wire [M_COUNT-1:0] m_arvalid_w;
  wire [M_COUNT-1:0] m_arready_w;
  wire [M_COUNT*`XLEN-1:0] m_araddr_w;
  wire [M_COUNT*4-1:0] m_arid_w;
  wire [M_COUNT*8-1:0] m_arlen_w;
  wire [M_COUNT*3-1:0] m_arsize_w;
  wire [M_COUNT*2-1:0] m_arburst_w;
  wire [M_COUNT*3-1:0] m_arprot_w;
  wire [M_COUNT-1:0] m_rvalid_w;
  wire [M_COUNT-1:0] m_rready_w;
  wire [M_COUNT*`XLEN-1:0] m_rdata_w;
  wire [M_COUNT*2-1:0] m_rresp_w;
  // RID/RLAST/BID 由 xbar 按 owner 记账回环; 桥侧单 outstanding 恒定 ID,
  // 暂无消费者——线到位, 汇 unused(SoC 对接刀再接)。
  wire [M_COUNT*4-1:0] m_rid_w;
  wire [M_COUNT-1:0] m_rlast_w;
  wire [M_COUNT*4-1:0] m_bid_w;

  wire [M_COUNT-1:0] m_awvalid_w;
  wire [M_COUNT-1:0] m_awready_w;
  wire [M_COUNT*`XLEN-1:0] m_awaddr_w;
  wire [M_COUNT*4-1:0] m_awid_w;
  wire [M_COUNT*8-1:0] m_awlen_w;
  wire [M_COUNT*3-1:0] m_awsize_w;
  wire [M_COUNT*2-1:0] m_awburst_w;
  wire [M_COUNT-1:0] m_wvalid_w;
  wire [M_COUNT-1:0] m_wready_w;
  wire [M_COUNT*`XLEN-1:0] m_wdata_w;
  wire [M_COUNT*`STRB_W-1:0] m_wstrb_w;
  wire [M_COUNT-1:0] m_wlast_w;
  wire [M_COUNT-1:0] m_bvalid_w;
  wire [M_COUNT-1:0] m_bready_w;
  wire [M_COUNT*2-1:0] m_bresp_w;

  wire unused_axi4_resp_meta_w = |{m_rid_w, m_rlast_w, m_bid_w};

  assign m_arvalid_w[M_IFU] = ifu_axi_arvalid_i;
  assign m_arvalid_w[M_LSU] = lsu_axi_arvalid_i;
  assign m_araddr_w[M_IFU*`XLEN +: `XLEN] = ifu_axi_araddr_i;
  assign m_araddr_w[M_LSU*`XLEN +: `XLEN] = lsu_axi_araddr_i;
  assign m_arid_w[M_IFU*4 +: 4] = ifu_axi_arid_i;
  assign m_arid_w[M_LSU*4 +: 4] = lsu_axi_arid_i;
  assign m_arlen_w[M_IFU*8 +: 8] = ifu_axi_arlen_i;
  assign m_arlen_w[M_LSU*8 +: 8] = lsu_axi_arlen_i;
  assign m_arsize_w[M_IFU*3 +: 3] = ifu_axi_arsize_i;
  assign m_arsize_w[M_LSU*3 +: 3] = lsu_axi_arsize_i;
  assign m_arburst_w[M_IFU*2 +: 2] = ifu_axi_arburst_i;
  assign m_arburst_w[M_LSU*2 +: 2] = lsu_axi_arburst_i;
  assign m_arprot_w[M_IFU*3 +: 3] = ifu_axi_arprot_i;
  assign m_arprot_w[M_LSU*3 +: 3] = lsu_axi_arprot_i;
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

  assign m_awvalid_w[M_IFU] = ifu_axi_awvalid_i;
  assign m_awvalid_w[M_LSU] = lsu_axi_awvalid_i;
  assign m_awaddr_w[M_IFU*`XLEN +: `XLEN] = ifu_axi_awaddr_i;
  assign m_awaddr_w[M_LSU*`XLEN +: `XLEN] = lsu_axi_awaddr_i;
  assign m_awid_w[M_IFU*4 +: 4] = ifu_axi_awid_i;
  assign m_awid_w[M_LSU*4 +: 4] = lsu_axi_awid_i;
  assign m_awlen_w[M_IFU*8 +: 8] = ifu_axi_awlen_i;
  assign m_awlen_w[M_LSU*8 +: 8] = lsu_axi_awlen_i;
  assign m_awsize_w[M_IFU*3 +: 3] = ifu_axi_awsize_i;
  assign m_awsize_w[M_LSU*3 +: 3] = lsu_axi_awsize_i;
  assign m_awburst_w[M_IFU*2 +: 2] = ifu_axi_awburst_i;
  assign m_awburst_w[M_LSU*2 +: 2] = lsu_axi_awburst_i;
  assign m_wvalid_w[M_IFU] = ifu_axi_wvalid_i;
  assign m_wvalid_w[M_LSU] = lsu_axi_wvalid_i;
  assign m_wdata_w[M_IFU*`XLEN +: `XLEN] = ifu_axi_wdata_i;
  assign m_wdata_w[M_LSU*`XLEN +: `XLEN] = lsu_axi_wdata_i;
  assign m_wstrb_w[M_IFU*`STRB_W +: `STRB_W] = ifu_axi_wstrb_i;
  assign m_wstrb_w[M_LSU*`STRB_W +: `STRB_W] = lsu_axi_wstrb_i;
  assign m_wlast_w[M_IFU] = ifu_axi_wlast_i;
  assign m_wlast_w[M_LSU] = lsu_axi_wlast_i;
  assign m_bready_w[M_IFU] = ifu_axi_bready_i;
  assign m_bready_w[M_LSU] = lsu_axi_bready_i;

  assign ifu_axi_awready_o = m_awready_w[M_IFU];
  assign ifu_axi_wready_o = m_wready_w[M_IFU];
  assign ifu_axi_bvalid_o = m_bvalid_w[M_IFU];
  assign ifu_axi_bresp_o = m_bresp_w[M_IFU*2 +: 2];
  assign lsu_axi_awready_o = m_awready_w[M_LSU];
  assign lsu_axi_wready_o = m_wready_w[M_LSU];
  assign lsu_axi_bvalid_o = m_bvalid_w[M_LSU];
  assign lsu_axi_bresp_o = m_bresp_w[M_LSU*2 +: 2];

  AxiXbar #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W),
    .M_COUNT(M_COUNT),
    .S_COUNT(S_COUNT),
    .DEFAULT_SLAVE(DEFAULT_SLAVE),
    .SLAVE_BASE(SLAVE_BASE),
    .SLAVE_MASK(SLAVE_MASK),
    .SLAVE_EXEC_MASK(SLAVE_EXEC_MASK)
  ) u_xbar (
    .clk(clk),
    .rst(rst),
    .m_arvalid_i(m_arvalid_w),
    .m_arready_o(m_arready_w),
    .m_araddr_i(m_araddr_w),
    .m_arid_i(m_arid_w),
    .m_arlen_i(m_arlen_w),
    .m_arsize_i(m_arsize_w),
    .m_arburst_i(m_arburst_w),
    .m_arprot_i(m_arprot_w),
    .m_rvalid_o(m_rvalid_w),
    .m_rready_i(m_rready_w),
    .m_rdata_o(m_rdata_w),
    .m_rresp_o(m_rresp_w),
    .m_rid_o(m_rid_w),
    .m_rlast_o(m_rlast_w),
    .m_awvalid_i(m_awvalid_w),
    .m_awready_o(m_awready_w),
    .m_awaddr_i(m_awaddr_w),
    .m_awid_i(m_awid_w),
    .m_awlen_i(m_awlen_w),
    .m_awsize_i(m_awsize_w),
    .m_awburst_i(m_awburst_w),
    .m_wvalid_i(m_wvalid_w),
    .m_wready_o(m_wready_w),
    .m_wdata_i(m_wdata_w),
    .m_wstrb_i(m_wstrb_w),
    .m_wlast_i(m_wlast_w),
    .m_bvalid_o(m_bvalid_w),
    .m_bready_i(m_bready_w),
    .m_bresp_o(m_bresp_w),
    .m_bid_o(m_bid_w),
    .s_arvalid_o(s_axi_arvalid_o),
    .s_arready_i(s_axi_arready_i),
    .s_araddr_o(s_axi_araddr_o),
    .s_arsize_o(s_axi_arsize_o),
    .s_arprot_o(s_axi_arprot_o),
    .s_rvalid_i(s_axi_rvalid_i),
    .s_rready_o(s_axi_rready_o),
    .s_rdata_i(s_axi_rdata_i),
    .s_rresp_i(s_axi_rresp_i),
    .s_awvalid_o(s_axi_awvalid_o),
    .s_awready_i(s_axi_awready_i),
    .s_awaddr_o(s_axi_awaddr_o),
    .s_awsize_o(s_axi_awsize_o),
    .s_wvalid_o(s_axi_wvalid_o),
    .s_wready_i(s_axi_wready_i),
    .s_wdata_o(s_axi_wdata_o),
    .s_wstrb_o(s_axi_wstrb_o),
    .s_bvalid_i(s_axi_bvalid_i),
    .s_bready_o(s_axi_bready_o),
    .s_bresp_i(s_axi_bresp_i)
  );

endmodule
