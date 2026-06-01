// UART 设备核心。
// 本模块只描述 UART 自身寄存器语义，不包含 AXI-Lite 握手；
// 总线协议由外层适配器负责，这样后续替换为 APB/TileLink 等接口时不用改 UART 本体。
module Uart #(
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8
) (
  input clk,
  input rst,

  input reg_read_valid_i,
  input [11:0] reg_read_addr_i,
  output reg [DATA_W-1:0] reg_read_data_o,

  input reg_write_valid_i,
  input [11:0] reg_write_addr_i,
  input [DATA_W-1:0] reg_write_data_i,
  input [STRB_W-1:0] reg_write_strb_i,

  output tx_valid_o,
  output [7:0] tx_data_o,
  output access_valid_o,
  output access_write_o,
  output irq_o
);

  localparam [11:0] UART_RBR_THR_DLL_OFFSET = 12'h000;
  localparam [11:0] UART_IER_DLM_OFFSET     = 12'h001;
  localparam [11:0] UART_IIR_FCR_OFFSET     = 12'h002;
  localparam [11:0] UART_LCR_OFFSET         = 12'h003;
  localparam [11:0] UART_COMPAT_STAT_OFFSET = 12'h004;
  localparam [11:0] UART_LSR_OFFSET         = 12'h005;

  reg [7:0] ier_q = 8'h00;
  reg [7:0] dll_q = 8'h01;
  reg [7:0] dlm_q = 8'h00;
  reg [7:0] fcr_q = 8'h00;
  reg [7:0] lcr_q = 8'h00;

  wire dlab_w = lcr_q[7];
  wire fifo_enabled_w = fcr_q[0];
  wire thre_ready_w = 1'b1;

  // 当前 LSU 会把 AXI 地址按 word 对齐，真实 byte lane 由 WSTRB 表达。
  // 只有 lane0 覆盖 TX offset 0 时才产生一个字符输出脉冲。
  assign tx_valid_o = reg_write_valid_i &&
                      (reg_write_addr_i == UART_RBR_THR_DLL_OFFSET) &&
                      reg_write_strb_i[0] &&
                      !dlab_w;
  assign tx_data_o = reg_write_data_i[7:0];
  assign access_valid_o = reg_read_valid_i || reg_write_valid_i;
  assign access_write_o = reg_write_valid_i;
  assign irq_o = ier_q[1] && thre_ready_w;

  integer read_lane_i;
  integer write_lane_i;

  always @(*) begin
    reg_read_data_o = {DATA_W{1'b0}};
    for (read_lane_i = 0; read_lane_i < STRB_W; read_lane_i = read_lane_i + 1) begin
      case (reg_read_addr_i + read_lane_i)
        UART_RBR_THR_DLL_OFFSET:
          reg_read_data_o[read_lane_i*8 +: 8] = dlab_w ? dll_q : 8'h00;
        UART_IER_DLM_OFFSET:
          reg_read_data_o[read_lane_i*8 +: 8] = dlab_w ? dlm_q : ier_q;
        UART_IIR_FCR_OFFSET:
          reg_read_data_o[read_lane_i*8 +: 8] =
              (fifo_enabled_w ? 8'hc0 : 8'h00) | (irq_o ? 8'h02 : 8'h01);
        UART_LCR_OFFSET:
          reg_read_data_o[read_lane_i*8 +: 8] = lcr_q;
        UART_COMPAT_STAT_OFFSET:
          reg_read_data_o[read_lane_i*8 +: 8] = 8'h01;
        UART_LSR_OFFSET:
          reg_read_data_o[read_lane_i*8 +: 8] = 8'h60;
        default:
          reg_read_data_o[read_lane_i*8 +: 8] = 8'h00;
      endcase
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ier_q <= 8'h00;
      dll_q <= 8'h01;
      dlm_q <= 8'h00;
      fcr_q <= 8'h00;
      lcr_q <= 8'h00;
    end else begin
      if (reg_write_valid_i) begin
        for (write_lane_i = 0; write_lane_i < STRB_W; write_lane_i = write_lane_i + 1) begin
          if (reg_write_strb_i[write_lane_i]) begin
            case (reg_write_addr_i + write_lane_i)
              UART_RBR_THR_DLL_OFFSET: begin
                if (dlab_w)
                  dll_q <= reg_write_data_i[write_lane_i*8 +: 8];
              end
              UART_IER_DLM_OFFSET: begin
                if (dlab_w)
                  dlm_q <= reg_write_data_i[write_lane_i*8 +: 8];
                else
                  ier_q <= reg_write_data_i[write_lane_i*8 +: 8] & 8'h0f;
              end
              UART_IIR_FCR_OFFSET: begin
                // 只保留 FIFO enable/trigger 配置；clear bits 在当前零延迟 TX 模型中自清。
                fcr_q <= reg_write_data_i[write_lane_i*8 +: 8] & 8'hc1;
              end
              UART_LCR_OFFSET: begin
                lcr_q <= reg_write_data_i[write_lane_i*8 +: 8];
              end
              default: begin end
            endcase
          end
        end
      end
    end
  end

endmodule
