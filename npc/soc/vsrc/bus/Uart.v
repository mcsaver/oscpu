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
  output access_write_o
);

  localparam [7:0] UART_LSR_READY = 8'h60;

  reg [7:0] dll_q;
  reg [7:0] dlm_q;
  reg [7:0] fcr_q;
  reg [7:0] lcr_q;

  wire write_word0_w = reg_write_addr_i[11:0] <= 12'h003;
  wire write_tx_w = reg_write_valid_i &&
                    write_word0_w &&
                    reg_write_strb_i[0] &&
                    !lcr_q[7];

  // 当前 LSU 会把 AXI 地址按 word 对齐，真实 byte offset 由 WSTRB lane 表达。
  // 兼容 16550 的 DLAB：LCR[7]=1 时 offset 0/1 是 DLL/DLM，不再产生字符输出。
  assign tx_valid_o = write_tx_w;
  assign tx_data_o = reg_write_data_i[7:0];
  assign access_valid_o = reg_read_valid_i || reg_write_valid_i;
  assign access_write_o = reg_write_valid_i;

  always @(posedge clk) begin
    if (rst) begin
      dll_q <= 8'h00;
      dlm_q <= 8'h00;
      fcr_q <= 8'h00;
      lcr_q <= 8'h00;
    end else if (reg_write_valid_i && write_word0_w) begin
      if (reg_write_strb_i[0] && lcr_q[7]) begin
        dll_q <= reg_write_data_i[7:0];
      end

      if (reg_write_strb_i[1] && lcr_q[7]) begin
        dlm_q <= reg_write_data_i[15:8];
      end

      if (reg_write_strb_i[2]) begin
        fcr_q <= reg_write_data_i[23:16];
      end

      if (reg_write_strb_i[3]) begin
        lcr_q <= reg_write_data_i[31:24];
      end
    end
  end

  function [7:0] read_uart_byte;
    input [11:0] byte_addr;
    begin
      case (byte_addr)
        12'h000: read_uart_byte = lcr_q[7] ? dll_q : 8'h00;
        12'h001: read_uart_byte = lcr_q[7] ? dlm_q : 8'h00;
        12'h002: read_uart_byte = fcr_q;
        12'h003: read_uart_byte = lcr_q;
        12'h005: read_uart_byte = UART_LSR_READY;
        default: read_uart_byte = 8'h00;
      endcase
    end
  endfunction

  function [DATA_W-1:0] read_uart_word;
    input [11:0] addr_low;
    reg [11:0] base;
    begin
      base = addr_low - {10'h000, addr_low[1:0]};
      read_uart_word = {
        read_uart_byte(base + 12'd3),
        read_uart_byte(base + 12'd2),
        read_uart_byte(base + 12'd1),
        read_uart_byte(base)
      };
    end
  endfunction

  assign reg_read_data_o = read_uart_word(reg_read_addr_i);

endmodule
