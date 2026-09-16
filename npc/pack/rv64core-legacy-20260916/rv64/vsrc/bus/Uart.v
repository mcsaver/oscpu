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
  input [2:0] reg_read_size_i,
  output [DATA_W-1:0] reg_read_data_o,

  input reg_write_valid_i,
  input [11:0] reg_write_addr_i,
  input [DATA_W-1:0] reg_write_data_i,
  input [STRB_W-1:0] reg_write_strb_i,

  input rx_valid_i,
  input [7:0] rx_data_i,
  output rx_ready_o,
  output tx_valid_o,
  output [7:0] tx_data_o,
  output access_valid_o,
  output access_write_o,
  output irq_o
);


  // Byte-stream 16550A: the host/board supplies complete received characters.
  // TX is consumed immediately; RX has the architectural 16-byte FIFO.
  // No baud/serial-bit timing is synthesized at this interface. A nonempty FIFO
  // below its trigger reports CTI, matching the platform's untimed UART model.
  reg [7:0] ier_q, dll_q, dlm_q, fcr_q, lcr_q, mcr_q, scr_q;
  reg [3:0] msr_delta_q;
  reg thre_pending_q, overrun_q;
  reg [7:0] rx_fifo_q [0:15];
  reg [3:0] rx_head_q, rx_tail_q;
  reg [4:0] rx_count_q;

  wire dlab_w = lcr_q[7];
  wire [3:0] modem_status_w =
      mcr_q[4] ? {mcr_q[3], mcr_q[2], mcr_q[0], mcr_q[1]} : 4'hb;
  wire [4:0] rx_capacity_w = fcr_q[0] ? 5'd16 : 5'd1;
  wire [4:0] rx_trigger_w = fcr_q[7:6] == 2'b00 ? 5'd1 :
                            fcr_q[7:6] == 2'b01 ? 5'd4 :
                            fcr_q[7:6] == 2'b10 ? 5'd8 : 5'd14;
  wire [3:0] interrupt_id_w =
      ier_q[2] && overrun_q ? 4'h6 :
      ier_q[0] && rx_count_q != 0 ?
          ((!fcr_q[0] || rx_count_q >= rx_trigger_w) ? 4'h4 : 4'hc) :
      ier_q[1] && thre_pending_q ? 4'h2 :
      ier_q[3] && msr_delta_q != 0 ? 4'h0 : 4'h1;

  // ARSIZE qualifies side effects. Returning neighboring register bytes in the
  // AXI beat must not acknowledge an IIR/MSR/LSR that the CPU did not read.
  function read_hits;
    input [12:0] addr;
    input valid;
    input [11:0] base;
    input [2:0] size;
    begin
      read_hits = valid && addr >= {1'b0, base} &&
                  addr < ({1'b0, base} + (13'd1 << size));
    end
  endfunction
  wire rbr_pop_w = read_hits(13'd0, reg_read_valid_i, reg_read_addr_i, reg_read_size_i) && !dlab_w && rx_count_q != 0;
  wire thr_write_w = reg_write_valid_i && reg_write_addr_i == 12'd0 &&
                     reg_write_strb_i[0] && !dlab_w;
  wire loopback_push_w = thr_write_w && mcr_q[4];

  assign tx_valid_o = thr_write_w && !mcr_q[4];
  assign tx_data_o = reg_write_data_i[7:0];
  // One FIFO write port: loopback owns it when THR is written in loop mode.
  // An accepted external byte wins over a concurrent FIFO clear (see below).
  assign rx_ready_o = !loopback_push_w &&
                      (rx_count_q < rx_capacity_w || rbr_pop_w);
  assign access_valid_o = reg_read_valid_i || reg_write_valid_i;
  assign access_write_o = reg_write_valid_i;
  assign irq_o = !interrupt_id_w[0];

  wire [63:0] register_window_w = {
      scr_q, modem_status_w, msr_delta_q,
      fcr_q[0] && overrun_q, 2'b11, 3'b000, overrun_q, rx_count_q != 0,
      mcr_q, lcr_q, fcr_q[0], fcr_q[0], 2'b00, interrupt_id_w,
      dlab_w ? dlm_q : ier_q,
      dlab_w ? dll_q : (rx_count_q != 0 ? rx_fifo_q[rx_head_q] : 8'h00)
  };
  function [7:0] uart_read_byte;
    input [12:0] addr;
    input [63:0] registers;
    begin
      case (addr)
        13'd0: uart_read_byte = registers[7:0];
        13'd1: uart_read_byte = registers[15:8];
        13'd2: uart_read_byte = registers[23:16];
        13'd3: uart_read_byte = registers[31:24];
        13'd4: uart_read_byte = registers[39:32];
        13'd5: uart_read_byte = registers[47:40];
        13'd6: uart_read_byte = registers[55:48];
        13'd7: uart_read_byte = registers[63:56];
        default: uart_read_byte = 8'h00;
      endcase
    end
  endfunction
  genvar lane;
  generate
    for (lane = 0; lane < STRB_W; lane = lane + 1) begin : gen_read_lane
      assign reg_read_data_o[lane*8 +: 8] =
          uart_read_byte({1'b0, reg_read_addr_i} + 13'(lane), register_window_w);
    end
  endgenerate

  reg [7:0] ier_d, dll_d, dlm_d, fcr_d, lcr_d, mcr_d, scr_d;
  reg [3:0] msr_delta_d;
  reg thre_pending_d, overrun_d;
  reg [3:0] rx_head_d, rx_tail_d;
  reg [4:0] rx_count_d;
  reg fifo_write_r;
  reg [3:0] fifo_write_addr_r;
  reg [7:0] fifo_write_data_r;
  reg [7:0] write_byte_r;
  reg [3:0] new_modem_r;
  integer i;
  always @(*) begin
    ier_d = ier_q; dll_d = dll_q; dlm_d = dlm_q;
    fcr_d = fcr_q; lcr_d = lcr_q; mcr_d = mcr_q; scr_d = scr_q;
    msr_delta_d = msr_delta_q;
    thre_pending_d = thre_pending_q;
    overrun_d = overrun_q;
    rx_head_d = rx_head_q; rx_tail_d = rx_tail_q; rx_count_d = rx_count_q;
    fifo_write_r = 1'b0; fifo_write_addr_r = rx_tail_q;
    fifo_write_data_r = 8'h00; write_byte_r = 8'h00;
    new_modem_r = modem_status_w;

    if (rbr_pop_w) begin
      rx_head_d = rx_head_q + 4'd1;
      rx_count_d = rx_count_q - 5'd1;
    end
    if (read_hits(13'd2, reg_read_valid_i, reg_read_addr_i, reg_read_size_i) && interrupt_id_w == 4'h2)
      thre_pending_d = 1'b0;
    if (read_hits(13'd5, reg_read_valid_i, reg_read_addr_i, reg_read_size_i)) overrun_d = 1'b0;
    if (read_hits(13'd6, reg_read_valid_i, reg_read_addr_i, reg_read_size_i)) msr_delta_d = 4'h0;

    // Lane order is byte-address order. DLAB and IER updates therefore have the
    // same meaning for byte, halfword and wider accesses.
    for (i = 0; i < STRB_W; i = i + 1) begin
      write_byte_r = reg_write_data_i[i*8 +: 8];
      if (reg_write_valid_i && reg_write_strb_i[i]) begin
        case ({1'b0, reg_write_addr_i} + 13'(i))
          13'd0: begin
            if (lcr_d[7]) dll_d = write_byte_r;
            else thre_pending_d = ier_d[1];
          end
          13'd1: begin
            if (lcr_d[7]) dlm_d = write_byte_r;
            else begin
              if (!write_byte_r[1]) thre_pending_d = 1'b0;
              else if (!ier_d[1]) thre_pending_d = 1'b1;
              ier_d = write_byte_r & 8'h0f;
            end
          end
          13'd2: begin
            if (write_byte_r[1] || (fcr_d[0] && !write_byte_r[0])) begin
              rx_head_d = 4'd0; rx_tail_d = 4'd0; rx_count_d = 5'd0;
              overrun_d = 1'b0;
            end
            if (write_byte_r[2] && ier_d[1]) thre_pending_d = 1'b1;
            fcr_d = write_byte_r & 8'hc9;
          end
          13'd3: lcr_d = write_byte_r;
          13'd4: begin
            mcr_d = write_byte_r & 8'h1f;
            new_modem_r = mcr_d[4] ?
                {mcr_d[3], mcr_d[2], mcr_d[0], mcr_d[1]} : 4'hb;
            // RI is an active status bit: only its falling edge sets TERI.
            msr_delta_d = msr_delta_d |
                {(modem_status_w[3] ^ new_modem_r[3]),
                 (modem_status_w[2] && !new_modem_r[2]),
                 (modem_status_w[1] ^ new_modem_r[1]),
                 (modem_status_w[0] ^ new_modem_r[0])};
          end
          13'd7: scr_d = write_byte_r;
          default: begin end
        endcase
      end
    end

    if (loopback_push_w || (rx_valid_i && rx_ready_o)) begin
      if (rx_count_d < (fcr_d[0] ? 5'd16 : 5'd1)) begin
        fifo_write_r = 1'b1;
        fifo_write_addr_r = rx_tail_d;
        fifo_write_data_r = loopback_push_w ? reg_write_data_i[7:0] : rx_data_i;
        rx_tail_d = rx_tail_d + 4'd1;
        rx_count_d = rx_count_d + 5'd1;
      end else begin
        overrun_d = 1'b1;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ier_q <= 8'h00; dll_q <= 8'h01; dlm_q <= 8'h00;
      fcr_q <= 8'h00; lcr_q <= 8'h00; mcr_q <= 8'h00; scr_q <= 8'h00;
      msr_delta_q <= 4'h0; thre_pending_q <= 1'b0; overrun_q <= 1'b0;
      rx_head_q <= 4'd0; rx_tail_q <= 4'd0; rx_count_q <= 5'd0;
    end else begin
      ier_q <= ier_d; dll_q <= dll_d; dlm_q <= dlm_d;
      fcr_q <= fcr_d; lcr_q <= lcr_d; mcr_q <= mcr_d; scr_q <= scr_d;
      msr_delta_q <= msr_delta_d;
      thre_pending_q <= thre_pending_d; overrun_q <= overrun_d;
      rx_head_q <= rx_head_d; rx_tail_q <= rx_tail_d; rx_count_q <= rx_count_d;
      if (fifo_write_r) rx_fifo_q[fifo_write_addr_r] <= fifo_write_data_r;
    end
  end
endmodule
