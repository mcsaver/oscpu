// UART 设备核心。
// 本模块只描述 UART 自身寄存器语义，不包含 AXI-Lite 握手；
// 总线协议由外层适配器负责，这样后续替换为 APB/TileLink 等接口时不用改 UART 本体。
module Uart #(
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8
) (
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
  output access_write_o
);

  localparam [11:0] UART_TX_WORD_OFFSET = 12'h000;
  localparam [11:0] UART_STATUS_WORD_OFFSET = 12'h004;
  localparam [DATA_W-1:0] UART_STATUS_WORD = {{(DATA_W-16){1'b0}}, 8'h60, 8'h01};

  wire unused_payload_w = |{
      reg_write_data_i[DATA_W-1:8],
      reg_write_strb_i[STRB_W-1:1]
  };

  // 当前 LSU 会把 AXI 地址按 word 对齐，真实 byte lane 由 WSTRB 表达。
  // 只有 lane0 覆盖 TX offset 0 时才产生一个字符输出脉冲。
  assign tx_valid_o = reg_write_valid_i &&
                      (reg_write_addr_i == UART_TX_WORD_OFFSET) &&
                      reg_write_strb_i[0];
  assign tx_data_o = reg_write_data_i[7:0];
  assign access_valid_o = reg_read_valid_i || reg_write_valid_i;
  assign access_write_o = reg_write_valid_i;

  function [DATA_W-1:0] read_uart_word;
    input [11:0] addr_low;
    begin
      case (addr_low)
        UART_TX_WORD_OFFSET: begin
          read_uart_word = {DATA_W{1'b0}};
        end
        UART_STATUS_WORD_OFFSET: begin
          // bit0 作为简单 TX ready；byte offset 5 保持 16550 LSR 的 THRE/TEMT。
          read_uart_word = UART_STATUS_WORD;
        end
        default: begin
          read_uart_word = {DATA_W{1'b0}};
        end
      endcase
    end
  endfunction

  assign reg_read_data_o = read_uart_word(reg_read_addr_i);

endmodule
