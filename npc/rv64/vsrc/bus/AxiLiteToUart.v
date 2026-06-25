// AXI-Lite 到 UART native 寄存器接口的适配器。
// UART 本体不感知 AXI；本模块只负责把 single-beat AXI-Lite 事务翻译为
// UART 的单拍寄存器读写访问。
module AxiLiteToUart #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8
) (
  input clk,
  input rst,

  input s_axi_arvalid_i,
  output s_axi_arready_o,
  input [ADDR_W-1:0] s_axi_araddr_i,
  input [STRB_W-1:0] s_axi_arstrb_i,
  output reg s_axi_rvalid_o,
  input s_axi_rready_i,
  output reg [DATA_W-1:0] s_axi_rdata_o,
  output [1:0] s_axi_rresp_o,

  input s_axi_awvalid_i,
  output s_axi_awready_o,
  input [ADDR_W-1:0] s_axi_awaddr_i,
  input s_axi_wvalid_i,
  output s_axi_wready_o,
  input [DATA_W-1:0] s_axi_wdata_i,
  input [STRB_W-1:0] s_axi_wstrb_i,
  output reg s_axi_bvalid_o,
  input s_axi_bready_i,
  output [1:0] s_axi_bresp_o,

  output uart_tx_valid_o,
  output [7:0] uart_tx_data_o,
  output uart_access_valid_o,
  output uart_access_write_o,
  output [11:0] uart_access_addr_o,
  output [DATA_W-1:0] uart_access_wdata_o,
  output [STRB_W-1:0] uart_access_wstrb_o,
  output [DATA_W-1:0] uart_access_rdata_o,
  input uart_rx_valid_i,
  input [7:0] uart_rx_data_i,
  output uart_rx_ready_o,
  output uart_irq_o
);

  reg [11:0] awaddr_low_q;
  reg aw_seen_q;
  reg [DATA_W-1:0] wdata_q;
  reg [STRB_W-1:0] wstrb_q;
  reg w_seen_q;

  wire ar_fire_w = s_axi_arvalid_i && s_axi_arready_o;
  wire aw_fire_w = s_axi_awvalid_i && s_axi_awready_o;
  wire w_fire_w = s_axi_wvalid_i && s_axi_wready_o;
  wire write_done_w = !s_axi_bvalid_o &&
                      (aw_seen_q || aw_fire_w) &&
                      (w_seen_q || w_fire_w);
  wire [11:0] write_addr_low_w = aw_fire_w ? s_axi_awaddr_i[11:0] : awaddr_low_q;
  wire [DATA_W-1:0] write_data_w = w_fire_w ? s_axi_wdata_i : wdata_q;
  wire [STRB_W-1:0] write_strb_w = w_fire_w ? s_axi_wstrb_i : wstrb_q;
  wire [DATA_W-1:0] uart_rdata_w;
  wire unused_addr_hi_w = |{
      s_axi_araddr_i[ADDR_W-1:12],
      s_axi_awaddr_i[ADDR_W-1:12]
  };

  assign s_axi_arready_o = !s_axi_rvalid_o;
  assign s_axi_rresp_o = 2'b00;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;
  assign s_axi_bresp_o = 2'b00;
  assign uart_access_addr_o = write_done_w ? write_addr_low_w
                                           : s_axi_araddr_i[11:0];
  assign uart_access_wdata_o = write_done_w ? write_data_w
                                            : {DATA_W{1'b0}};
  assign uart_access_wstrb_o = write_done_w ? write_strb_w
                                            : {STRB_W{1'b0}};
  assign uart_access_rdata_o = ar_fire_w ? uart_rdata_w
                                         : {DATA_W{1'b0}};

  Uart #(
    .DATA_W(DATA_W),
    .STRB_W(STRB_W)
  ) u_uart (
    .clk(clk),
    .rst(rst),
    .reg_read_valid_i(ar_fire_w),
    .reg_read_addr_i(s_axi_araddr_i[11:0]),
    .reg_read_strb_i(s_axi_arstrb_i),
    .reg_read_data_o(uart_rdata_w),
    .reg_write_valid_i(write_done_w),
    .reg_write_addr_i(write_addr_low_w),
    .reg_write_data_i(write_data_w),
    .reg_write_strb_i(write_strb_w),
    .rx_valid_i(uart_rx_valid_i),
    .rx_data_i(uart_rx_data_i),
    .rx_ready_o(uart_rx_ready_o),
    .tx_valid_o(uart_tx_valid_o),
    .tx_data_o(uart_tx_data_o),
    .access_valid_o(uart_access_valid_o),
    .access_write_o(uart_access_write_o),
    .irq_o(uart_irq_o)
  );

  always @(posedge clk) begin
    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_rdata_o <= {DATA_W{1'b0}};
      s_axi_bvalid_o <= 1'b0;
      awaddr_low_q <= 12'h000;
      aw_seen_q <= 1'b0;
      wdata_q <= {DATA_W{1'b0}};
      wstrb_q <= {STRB_W{1'b0}};
      w_seen_q <= 1'b0;
    end else begin
      if (s_axi_rvalid_o && s_axi_rready_i) begin
        s_axi_rvalid_o <= 1'b0;
      end

      if (s_axi_bvalid_o && s_axi_bready_i) begin
        s_axi_bvalid_o <= 1'b0;
      end

      if (ar_fire_w) begin
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= uart_rdata_w;
      end

      if (aw_fire_w) begin
        awaddr_low_q <= s_axi_awaddr_i[11:0];
        aw_seen_q <= 1'b1;
      end

      if (w_fire_w) begin
        wdata_q <= s_axi_wdata_i;
        wstrb_q <= s_axi_wstrb_i;
        w_seen_q <= 1'b1;
      end

      if (write_done_w) begin
        s_axi_bvalid_o <= 1'b1;
        aw_seen_q <= 1'b0;
        w_seen_q <= 1'b0;
      end
    end
  end

endmodule
