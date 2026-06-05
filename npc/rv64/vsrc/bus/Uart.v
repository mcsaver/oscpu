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

  wire [63:0] reg_write_data_pad_w;
  wire [7:0] reg_write_strb_pad_w;

  assign reg_write_data_pad_w[31:0] = reg_write_data_i[31:0];
  assign reg_write_strb_pad_w[3:0] = reg_write_strb_i[3:0];
  generate
    if (DATA_W > 32) begin : gen_uart_data_high_lanes
      assign reg_write_data_pad_w[63:32] = reg_write_data_i[63:32];
    end else begin : gen_uart_data_high_zero
      assign reg_write_data_pad_w[63:32] = 32'b0;
    end
    if (STRB_W > 4) begin : gen_uart_strb_high_lanes
      assign reg_write_strb_pad_w[7:4] = reg_write_strb_i[7:4];
    end else begin : gen_uart_strb_high_zero
      assign reg_write_strb_pad_w[7:4] = 4'b0;
    end
  endgenerate

  function [7:0] uart_read_byte;
    input [12:0] byte_addr;
    input dlab;
    input fifo_enabled;
    input irq;
    input [7:0] ier;
    input [7:0] dll;
    input [7:0] dlm;
    input [7:0] lcr;
    begin
      case (byte_addr)
        {1'b0, UART_RBR_THR_DLL_OFFSET}:
          uart_read_byte = dlab ? dll : 8'h00;
        {1'b0, UART_IER_DLM_OFFSET}:
          uart_read_byte = dlab ? dlm : ier;
        {1'b0, UART_IIR_FCR_OFFSET}:
          uart_read_byte =
              (fifo_enabled ? 8'hc0 : 8'h00) | (irq ? 8'h02 : 8'h01);
        {1'b0, UART_LCR_OFFSET}: uart_read_byte = lcr;
        {1'b0, UART_COMPAT_STAT_OFFSET}: uart_read_byte = 8'h01;
        {1'b0, UART_LSR_OFFSET}: uart_read_byte = 8'h60;
        default: uart_read_byte = 8'h00;
      endcase
    end
  endfunction

  // UART 寄存器窗口最多接 64-bit AXI beat；固定 lane 网络比 procedural
  // byte loop 更容易审查每个 byte 对应的寄存器副作用。
  assign reg_read_data_o[7:0] =
      uart_read_byte({1'b0, reg_read_addr_i} + 13'd0, dlab_w,
                     fifo_enabled_w, irq_o, ier_q, dll_q, dlm_q, lcr_q);
  assign reg_read_data_o[15:8] =
      uart_read_byte({1'b0, reg_read_addr_i} + 13'd1, dlab_w,
                     fifo_enabled_w, irq_o, ier_q, dll_q, dlm_q, lcr_q);
  assign reg_read_data_o[23:16] =
      uart_read_byte({1'b0, reg_read_addr_i} + 13'd2, dlab_w,
                     fifo_enabled_w, irq_o, ier_q, dll_q, dlm_q, lcr_q);
  assign reg_read_data_o[31:24] =
      uart_read_byte({1'b0, reg_read_addr_i} + 13'd3, dlab_w,
                     fifo_enabled_w, irq_o, ier_q, dll_q, dlm_q, lcr_q);

  generate
    if (STRB_W > 4) begin : gen_uart_read_high_lanes
      assign reg_read_data_o[39:32] =
          uart_read_byte({1'b0, reg_read_addr_i} + 13'd4, dlab_w,
                         fifo_enabled_w, irq_o, ier_q, dll_q, dlm_q, lcr_q);
      assign reg_read_data_o[47:40] =
          uart_read_byte({1'b0, reg_read_addr_i} + 13'd5, dlab_w,
                         fifo_enabled_w, irq_o, ier_q, dll_q, dlm_q, lcr_q);
      assign reg_read_data_o[55:48] =
          uart_read_byte({1'b0, reg_read_addr_i} + 13'd6, dlab_w,
                         fifo_enabled_w, irq_o, ier_q, dll_q, dlm_q, lcr_q);
      assign reg_read_data_o[63:56] =
          uart_read_byte({1'b0, reg_read_addr_i} + 13'd7, dlab_w,
                         fifo_enabled_w, irq_o, ier_q, dll_q, dlm_q, lcr_q);
    end
  endgenerate

  reg [7:0] ier_next_r;
  reg [7:0] dll_next_r;
  reg [7:0] dlm_next_r;
  reg [7:0] fcr_next_r;
  reg [7:0] lcr_next_r;
  always @(*) begin
    ier_next_r = ier_q;
    dll_next_r = dll_q;
    dlm_next_r = dlm_q;
    fcr_next_r = fcr_q;
    lcr_next_r = lcr_q;
    if (reg_write_valid_i) begin
      if (reg_write_strb_pad_w[0]) begin
        case ({1'b0, reg_write_addr_i} + 13'd0)
          {1'b0, UART_RBR_THR_DLL_OFFSET}: begin
            if (dlab_w) dll_next_r = reg_write_data_pad_w[7:0];
          end
          {1'b0, UART_IER_DLM_OFFSET}: begin
            if (dlab_w)
              dlm_next_r = reg_write_data_pad_w[7:0];
            else
              ier_next_r = reg_write_data_pad_w[7:0] & 8'h0f;
          end
          {1'b0, UART_IIR_FCR_OFFSET}: begin
            fcr_next_r = reg_write_data_pad_w[7:0] & 8'hc1;
          end
          {1'b0, UART_LCR_OFFSET}: begin
            lcr_next_r = reg_write_data_pad_w[7:0];
          end
          default: begin end
        endcase
      end
      if (reg_write_strb_pad_w[1]) begin
        case ({1'b0, reg_write_addr_i} + 13'd1)
          {1'b0, UART_RBR_THR_DLL_OFFSET}: begin
            if (dlab_w) dll_next_r = reg_write_data_pad_w[15:8];
          end
          {1'b0, UART_IER_DLM_OFFSET}: begin
            if (dlab_w)
              dlm_next_r = reg_write_data_pad_w[15:8];
            else
              ier_next_r = reg_write_data_pad_w[15:8] & 8'h0f;
          end
          {1'b0, UART_IIR_FCR_OFFSET}: begin
            fcr_next_r = reg_write_data_pad_w[15:8] & 8'hc1;
          end
          {1'b0, UART_LCR_OFFSET}: begin
            lcr_next_r = reg_write_data_pad_w[15:8];
          end
          default: begin end
        endcase
      end
      if (reg_write_strb_pad_w[2]) begin
        case ({1'b0, reg_write_addr_i} + 13'd2)
          {1'b0, UART_RBR_THR_DLL_OFFSET}: begin
            if (dlab_w) dll_next_r = reg_write_data_pad_w[23:16];
          end
          {1'b0, UART_IER_DLM_OFFSET}: begin
            if (dlab_w)
              dlm_next_r = reg_write_data_pad_w[23:16];
            else
              ier_next_r = reg_write_data_pad_w[23:16] & 8'h0f;
          end
          {1'b0, UART_IIR_FCR_OFFSET}: begin
            fcr_next_r = reg_write_data_pad_w[23:16] & 8'hc1;
          end
          {1'b0, UART_LCR_OFFSET}: begin
            lcr_next_r = reg_write_data_pad_w[23:16];
          end
          default: begin end
        endcase
      end
      if (reg_write_strb_pad_w[3]) begin
        case ({1'b0, reg_write_addr_i} + 13'd3)
          {1'b0, UART_RBR_THR_DLL_OFFSET}: begin
            if (dlab_w) dll_next_r = reg_write_data_pad_w[31:24];
          end
          {1'b0, UART_IER_DLM_OFFSET}: begin
            if (dlab_w)
              dlm_next_r = reg_write_data_pad_w[31:24];
            else
              ier_next_r = reg_write_data_pad_w[31:24] & 8'h0f;
          end
          {1'b0, UART_IIR_FCR_OFFSET}: begin
            fcr_next_r = reg_write_data_pad_w[31:24] & 8'hc1;
          end
          {1'b0, UART_LCR_OFFSET}: begin
            lcr_next_r = reg_write_data_pad_w[31:24];
          end
          default: begin end
        endcase
      end
      if (reg_write_strb_pad_w[4]) begin
        case ({1'b0, reg_write_addr_i} + 13'd4)
          {1'b0, UART_RBR_THR_DLL_OFFSET}: begin
            if (dlab_w) dll_next_r = reg_write_data_pad_w[39:32];
          end
          {1'b0, UART_IER_DLM_OFFSET}: begin
            if (dlab_w)
              dlm_next_r = reg_write_data_pad_w[39:32];
            else
              ier_next_r = reg_write_data_pad_w[39:32] & 8'h0f;
          end
          {1'b0, UART_IIR_FCR_OFFSET}: begin
            fcr_next_r = reg_write_data_pad_w[39:32] & 8'hc1;
          end
          {1'b0, UART_LCR_OFFSET}: begin
            lcr_next_r = reg_write_data_pad_w[39:32];
          end
          default: begin end
        endcase
      end
      if (reg_write_strb_pad_w[5]) begin
        case ({1'b0, reg_write_addr_i} + 13'd5)
          {1'b0, UART_RBR_THR_DLL_OFFSET}: begin
            if (dlab_w) dll_next_r = reg_write_data_pad_w[47:40];
          end
          {1'b0, UART_IER_DLM_OFFSET}: begin
            if (dlab_w)
              dlm_next_r = reg_write_data_pad_w[47:40];
            else
              ier_next_r = reg_write_data_pad_w[47:40] & 8'h0f;
          end
          {1'b0, UART_IIR_FCR_OFFSET}: begin
            fcr_next_r = reg_write_data_pad_w[47:40] & 8'hc1;
          end
          {1'b0, UART_LCR_OFFSET}: begin
            lcr_next_r = reg_write_data_pad_w[47:40];
          end
          default: begin end
        endcase
      end
      if (reg_write_strb_pad_w[6]) begin
        case ({1'b0, reg_write_addr_i} + 13'd6)
          {1'b0, UART_RBR_THR_DLL_OFFSET}: begin
            if (dlab_w) dll_next_r = reg_write_data_pad_w[55:48];
          end
          {1'b0, UART_IER_DLM_OFFSET}: begin
            if (dlab_w)
              dlm_next_r = reg_write_data_pad_w[55:48];
            else
              ier_next_r = reg_write_data_pad_w[55:48] & 8'h0f;
          end
          {1'b0, UART_IIR_FCR_OFFSET}: begin
            fcr_next_r = reg_write_data_pad_w[55:48] & 8'hc1;
          end
          {1'b0, UART_LCR_OFFSET}: begin
            lcr_next_r = reg_write_data_pad_w[55:48];
          end
          default: begin end
        endcase
      end
      if (reg_write_strb_pad_w[7]) begin
        case ({1'b0, reg_write_addr_i} + 13'd7)
          {1'b0, UART_RBR_THR_DLL_OFFSET}: begin
            if (dlab_w) dll_next_r = reg_write_data_pad_w[63:56];
          end
          {1'b0, UART_IER_DLM_OFFSET}: begin
            if (dlab_w)
              dlm_next_r = reg_write_data_pad_w[63:56];
            else
              ier_next_r = reg_write_data_pad_w[63:56] & 8'h0f;
          end
          {1'b0, UART_IIR_FCR_OFFSET}: begin
            fcr_next_r = reg_write_data_pad_w[63:56] & 8'hc1;
          end
          {1'b0, UART_LCR_OFFSET}: begin
            lcr_next_r = reg_write_data_pad_w[63:56];
          end
          default: begin end
        endcase
      end
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
        ier_q <= ier_next_r;
        dll_q <= dll_next_r;
        dlm_q <= dlm_next_r;
        fcr_q <= fcr_next_r;
        lcr_q <= lcr_next_r;
      end
    end
  end

endmodule
