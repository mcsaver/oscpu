// SiFive Test/Reset syscon 的最小 AXI-Lite 从设备。
// 地址窗口由上游 crossbar 选择，本模块只接受窗口内 offset 0 的 32-bit 单拍访问。
module AxiResetSyscon #(
  parameter ADDR_W = 64,
  parameter DATA_W = 64,
  parameter STRB_W = DATA_W / 8
) (
  input clk,
  input rst,

  input s_axi_arvalid_i,
  output s_axi_arready_o,
  input [ADDR_W-1:0] s_axi_araddr_i,
  input [2:0] s_axi_arsize_i,
  output reg s_axi_rvalid_o,
  input s_axi_rready_i,
  output reg [DATA_W-1:0] s_axi_rdata_o,
  output reg [1:0] s_axi_rresp_o,

  input s_axi_awvalid_i,
  output s_axi_awready_o,
  input [ADDR_W-1:0] s_axi_awaddr_i,
  input [2:0] s_axi_awsize_i,
  input s_axi_wvalid_i,
  output s_axi_wready_o,
  input [DATA_W-1:0] s_axi_wdata_i,
  input [STRB_W-1:0] s_axi_wstrb_i,
  output reg s_axi_bvalid_o,
  input s_axi_bready_i,
  output reg [1:0] s_axi_bresp_o,

  // 事件必须晚于成功 B 握手；消费者据此区分已被 guest 观察到的写完成。
  output reg syscon_write_valid_o,
  output reg [31:0] syscon_write_value_o
);

  localparam integer LANE_BITS = $clog2(STRB_W);
  localparam [1:0] AXI_RESP_OKAY = 2'b00;
  localparam [1:0] AXI_RESP_SLVERR = 2'b10;

  reg [11:0] awaddr_low_q;
  reg [2:0] awsize_q;
  reg aw_seen_q;
  reg [DATA_W-1:0] wdata_q;
  reg [STRB_W-1:0] wstrb_q;
  reg w_seen_q;
  reg [31:0] syscon_value_q;
  reg b_event_pending_q;
  reg [31:0] b_event_value_q;

  wire ar_fire_w = s_axi_arvalid_i && s_axi_arready_o;
  wire aw_fire_w = s_axi_awvalid_i && s_axi_awready_o;
  wire w_fire_w = s_axi_wvalid_i && s_axi_wready_o;
  wire b_fire_w = s_axi_bvalid_o && s_axi_bready_i;
  wire write_done_w = !s_axi_bvalid_o &&
                      (aw_seen_q || aw_fire_w) &&
                      (w_seen_q || w_fire_w);

  // AW/W 独立到达时，完成拍显式选择“本拍输入”或“已缓存 payload”。
  wire [11:0] write_addr_low_w = aw_fire_w ? s_axi_awaddr_i[11:0]
                                                    : awaddr_low_q;
  wire [2:0] write_size_w = aw_fire_w ? s_axi_awsize_i : awsize_q;
  wire [DATA_W-1:0] write_data_w = w_fire_w ? s_axi_wdata_i : wdata_q;
  wire [STRB_W-1:0] write_strb_w = w_fire_w ? s_axi_wstrb_i : wstrb_q;
  wire [LANE_BITS-1:0] write_lane_w =
      write_addr_low_w[LANE_BITS-1:0];
  wire [5:0] write_shift_w = write_lane_w * 6'd8;
  wire [31:0] native_write_data_w = write_data_w >> write_shift_w;
  wire [3:0] native_write_strb_w = write_strb_w >> write_lane_w;
  wire write_legal_w = (write_addr_low_w == 12'h000) &&
                       (write_size_w == 3'd2);
  wire write_has_bytes_w = |native_write_strb_w;

  wire [LANE_BITS-1:0] read_lane_w =
      s_axi_araddr_i[LANE_BITS-1:0];
  wire [5:0] read_shift_w = read_lane_w * 6'd8;
  wire read_legal_w = (s_axi_araddr_i[11:0] == 12'h000) &&
                      (s_axi_arsize_i == 3'd2);
  wire unused_addr_hi_w = |{
      s_axi_araddr_i[ADDR_W-1:12],
      s_axi_awaddr_i[ADDR_W-1:12]
  };

  // 四个固定 byte-enable mux 对应 32-bit syscon 寄存器的真实写掩码硬件。
  function [31:0] apply_wstrb32;
    input [31:0] old_value;
    input [31:0] new_value;
    input [3:0] strb;
    begin
      apply_wstrb32[7:0] = strb[0] ? new_value[7:0] : old_value[7:0];
      apply_wstrb32[15:8] = strb[1] ? new_value[15:8] : old_value[15:8];
      apply_wstrb32[23:16] = strb[2] ? new_value[23:16] : old_value[23:16];
      apply_wstrb32[31:24] = strb[3] ? new_value[31:24] : old_value[31:24];
    end
  endfunction

  wire [31:0] merged_write_value_w = apply_wstrb32(
      syscon_value_q, native_write_data_w, native_write_strb_w);

  // 每侧只允许一个未完成响应；背压期间 payload 由响应寄存器冻结。
  assign s_axi_arready_o = !s_axi_rvalid_o;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;

  always @(posedge clk) begin
    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_rdata_o <= {DATA_W{1'b0}};
      s_axi_rresp_o <= AXI_RESP_OKAY;
      s_axi_bvalid_o <= 1'b0;
      s_axi_bresp_o <= AXI_RESP_OKAY;
      awaddr_low_q <= 12'h000;
      awsize_q <= 3'd0;
      aw_seen_q <= 1'b0;
      wdata_q <= {DATA_W{1'b0}};
      wstrb_q <= {STRB_W{1'b0}};
      w_seen_q <= 1'b0;
      syscon_value_q <= 32'h0000_0000;
      b_event_pending_q <= 1'b0;
      b_event_value_q <= 32'h0000_0000;
      syscon_write_valid_o <= 1'b0;
      syscon_write_value_o <= 32'h0000_0000;
    end else begin
      // 默认撤销事件；只有成功 B 握手分支能把它抬高一个完整周期。
      syscon_write_valid_o <= 1'b0;

      if (s_axi_rvalid_o && s_axi_rready_i)
        s_axi_rvalid_o <= 1'b0;

      if (ar_fire_w) begin
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= read_legal_w
            ? ({{(DATA_W-32){1'b0}}, syscon_value_q} << read_shift_w)
            : {DATA_W{1'b0}};
        s_axi_rresp_o <= read_legal_w ? AXI_RESP_OKAY : AXI_RESP_SLVERR;
      end

      if (aw_fire_w) begin
        awaddr_low_q <= s_axi_awaddr_i[11:0];
        awsize_q <= s_axi_awsize_i;
        aw_seen_q <= 1'b1;
      end

      if (w_fire_w) begin
        wdata_q <= s_axi_wdata_i;
        wstrb_q <= s_axi_wstrb_i;
        w_seen_q <= 1'b1;
      end

      if (b_fire_w) begin
        s_axi_bvalid_o <= 1'b0;
        if (b_event_pending_q) begin
          syscon_write_valid_o <= 1'b1;
          syscon_write_value_o <= b_event_value_q;
        end
        b_event_pending_q <= 1'b0;
      end

      if (write_done_w) begin
        s_axi_bvalid_o <= 1'b1;
        s_axi_bresp_o <= write_legal_w ? AXI_RESP_OKAY : AXI_RESP_SLVERR;
        aw_seen_q <= 1'b0;
        w_seen_q <= 1'b0;
        if (write_legal_w && write_has_bytes_w) begin
          // 寄存器先按 WSTRB 合并，B 握手后再发布相同的最终值。
          syscon_value_q <= merged_write_value_w;
          b_event_pending_q <= 1'b1;
          b_event_value_q <= merged_write_value_w;
        end else begin
          b_event_pending_q <= 1'b0;
        end
      end
    end
  end

endmodule
