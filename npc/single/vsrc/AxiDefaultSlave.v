// 默认错误 slave：用于 crossbar 地址未命中时返回 SLVERR/DECERR 风格响应。
// 当前仿真第一阶段仍把所有地址交给 DPI slave，后续拆多设备时可把
// `DEFAULT_SLAVE` 指向本模块，避免非法地址静默成功。
module AxiDefaultSlave #(
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8
) (
  input clk,
  input rst,

  input s_axi_arvalid_i,
  output s_axi_arready_o,
  output reg s_axi_rvalid_o,
  input s_axi_rready_i,
  output [DATA_W-1:0] s_axi_rdata_o,
  output [1:0] s_axi_rresp_o,

  input s_axi_awvalid_i,
  output s_axi_awready_o,
  input s_axi_wvalid_i,
  output s_axi_wready_o,
  output reg s_axi_bvalid_o,
  input s_axi_bready_i,
  output [1:0] s_axi_bresp_o
);

  reg aw_seen_q;
  reg w_seen_q;

  assign s_axi_arready_o = !s_axi_rvalid_o;
  assign s_axi_rdata_o = {DATA_W{1'b0}};
  assign s_axi_rresp_o = 2'b10;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;
  assign s_axi_bresp_o = 2'b10;

  wire ar_fire_w = s_axi_arvalid_i && s_axi_arready_o;
  wire aw_fire_w = s_axi_awvalid_i && s_axi_awready_o;
  wire w_fire_w = s_axi_wvalid_i && s_axi_wready_o;
  wire write_done_w = !s_axi_bvalid_o &&
                      (aw_seen_q || aw_fire_w) &&
                      (w_seen_q || w_fire_w);

  always @(posedge clk) begin
    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_bvalid_o <= 1'b0;
      aw_seen_q <= 1'b0;
      w_seen_q <= 1'b0;
    end else begin
      if (s_axi_rvalid_o && s_axi_rready_i)
        s_axi_rvalid_o <= 1'b0;
      if (s_axi_bvalid_o && s_axi_bready_i)
        s_axi_bvalid_o <= 1'b0;

      if (ar_fire_w)
        s_axi_rvalid_o <= 1'b1;

      if (aw_fire_w)
        aw_seen_q <= 1'b1;
      if (w_fire_w)
        w_seen_q <= 1'b1;

      if (write_done_w) begin
        s_axi_bvalid_o <= 1'b1;
        aw_seen_q <= 1'b0;
        w_seen_q <= 1'b0;
      end
    end
  end

endmodule
