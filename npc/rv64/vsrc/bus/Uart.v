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
  output [DATA_W-1:0] reg_read_data_o,

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
  reg [7:0] lcr_q = 8'h00;
  reg thre_pending_q = 1'b0;

  wire unused_payload_w = |{
      reg_write_data_i[DATA_W-1:8],
      reg_write_strb_i[STRB_W-1:1]
  };
  wire iir_read_w = reg_read_valid_i &&
                    (reg_read_addr_i <= UART_IIR_FCR_OFFSET) &&
                    ((reg_read_addr_i + STRB_W) > UART_IIR_FCR_OFFSET);

  // 当前 LSU 会把 AXI 地址按 word 对齐，真实 byte lane 由 WSTRB 表达。
  // 只有 lane0 覆盖 TX offset 0 时才产生一个字符输出脉冲。
  assign tx_valid_o = reg_write_valid_i &&
                      (reg_write_addr_i == UART_RBR_THR_DLL_OFFSET) &&
                      reg_write_strb_i[0];
  assign tx_data_o = reg_write_data_i[7:0];
  assign access_valid_o = reg_read_valid_i || reg_write_valid_i;
  assign access_write_o = reg_write_valid_i;
  assign irq_o = ier_q[1] && thre_pending_q;

  function [7:0] read_uart_byte;
    input [11:0] byte_addr;
    begin
      case (byte_addr)
        UART_RBR_THR_DLL_OFFSET: read_uart_byte = 8'h00;
        UART_IER_DLM_OFFSET:     read_uart_byte = ier_q;
        UART_IIR_FCR_OFFSET:     read_uart_byte = irq_o ? 8'h02 : 8'h01;
        UART_LCR_OFFSET:         read_uart_byte = lcr_q;
        UART_COMPAT_STAT_OFFSET: read_uart_byte = 8'h01;
        UART_LSR_OFFSET:         read_uart_byte = 8'h60;
        default:                 read_uart_byte = 8'h00;
      endcase
    end
  endfunction

  function [DATA_W-1:0] read_uart_word;
    input [11:0] addr_low;
    integer i;
    begin
      read_uart_word = {DATA_W{1'b0}};
      for (i = 0; i < STRB_W; i = i + 1) begin
        read_uart_word[i*8 +: 8] = read_uart_byte(addr_low + i);
      end
    end
  endfunction

  assign reg_read_data_o = read_uart_word(reg_read_addr_i);

  integer write_lane_i;
  always @(posedge clk) begin
    if (rst) begin
      ier_q <= 8'h00;
      lcr_q <= 8'h00;
      thre_pending_q <= 1'b0;
    end else begin
      if (reg_write_valid_i) begin
        for (write_lane_i = 0; write_lane_i < STRB_W; write_lane_i = write_lane_i + 1) begin
          if (reg_write_strb_i[write_lane_i]) begin
            case (reg_write_addr_i + write_lane_i)
              UART_RBR_THR_DLL_OFFSET: begin
                // 当前模型没有真实 TX FIFO，写 THR 后立即回到 empty。
                thre_pending_q <= ier_q[1];
              end
              UART_IER_DLM_OFFSET: begin
                ier_q <= reg_write_data_i[write_lane_i*8 +: 8] & 8'h0f;
                thre_pending_q <= reg_write_data_i[write_lane_i*8 + 1];
              end
              UART_IIR_FCR_OFFSET: begin
                // FCR 只接受写入，不建模 FIFO 深度；保持 Linux 初始化可安全通过。
              end
              UART_LCR_OFFSET: begin
                lcr_q <= reg_write_data_i[write_lane_i*8 +: 8];
              end
              default: begin end
            endcase
          end
        end
      end

      if (iir_read_w)
        thre_pending_q <= 1'b0;
    end
  end

endmodule
