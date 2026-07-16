`include "define.v"

// CLINT-like 设备提供 M-mode 软件/定时器中断源；core 只消费标准 irq_* 信号。
module AxiClint #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8,
  parameter [63:0] MTIME_INCREMENT = 64'd1,
  parameter [31:0] MTIME_DIVISOR = 32'd1
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
  output [1:0] s_axi_rresp_o,

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
  output [1:0] s_axi_bresp_o,

  output [63:0] mtime_o,
  output msip_irq_o,
  output reg mtip_irq_o
);

  localparam integer LANE_BITS = $clog2(STRB_W);

  localparam [15:0] CLINT_MSIP_OFFSET      = 16'h0000;
  localparam [15:0] CLINT_MTIMECMP_LO      = 16'h4000;
  localparam [15:0] CLINT_MTIMECMP_HI      = 16'h4004;
  localparam [15:0] CLINT_MTIME_LO         = 16'hbff8;
  localparam [15:0] CLINT_MTIME_HI         = 16'hbffc;
  localparam [31:0] MTIME_DIVISOR_SAFE     = (MTIME_DIVISOR == 32'd0) ? 32'd1 : MTIME_DIVISOR;

  reg [15:0] awaddr_low_q;
  reg aw_seen_q;
  reg [DATA_W-1:0] wdata_q;
  reg [STRB_W-1:0] wstrb_q;
  reg w_seen_q;
  reg msip_q;
  reg [63:0] mtimecmp_q;
  reg [63:0] mtime_q;
  reg [31:0] mtime_div_q;

  wire ar_fire_w = s_axi_arvalid_i && s_axi_arready_o;
  wire aw_fire_w = s_axi_awvalid_i && s_axi_awready_o;
  wire w_fire_w = s_axi_wvalid_i && s_axi_wready_o;
  wire mtime_tick_w = (mtime_div_q >= (MTIME_DIVISOR_SAFE - 32'd1));
  wire write_done_w = !s_axi_bvalid_o &&
                      (aw_seen_q || aw_fire_w) &&
                      (w_seen_q || w_fire_w);
  wire [15:0] write_addr_low_w = aw_fire_w ? s_axi_awaddr_i[15:0] : awaddr_low_q;
  wire [DATA_W-1:0] write_data_w = w_fire_w ? s_axi_wdata_i : wdata_q;
  wire [STRB_W-1:0] write_strb_w = w_fire_w ? s_axi_wstrb_i : wstrb_q;
  wire [LANE_BITS-1:0] write_lane_w = write_addr_low_w[LANE_BITS-1:0];
  wire [LANE_BITS-1:0] read_lane_w = s_axi_araddr_i[LANE_BITS-1:0];
  wire [5:0] write_lane_shift_w = write_lane_w * 6'd8;
  wire [5:0] read_lane_shift_w = read_lane_w * 6'd8;
  wire [DATA_W-1:0] native_write_data_w = write_data_w >> write_lane_shift_w;
  wire [STRB_W-1:0] native_write_strb_w = write_strb_w >> write_lane_w;
  wire [63:0] write_data_pad_w;
  wire [7:0] write_strb_pad_w;
  wire unused_addr_hi_w = |{
      s_axi_araddr_i[ADDR_W-1:16],
      s_axi_awaddr_i[ADDR_W-1:16],
      s_axi_arsize_i,
      s_axi_awsize_i
  };

  assign s_axi_arready_o = !s_axi_rvalid_o;
  assign s_axi_rresp_o = 2'b00;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;
  assign s_axi_bresp_o = 2'b00;
  assign mtime_o = mtime_q;
  // msip_irq_o 直连寄存器 msip_q,本就无组合锥,毋需再打拍。
  assign msip_irq_o = msip_q;
  // P5 刀P 同链核查:mtip 原为 64 位幅值比较组合直通输出,与 PLIC external_irq
  // 同属"设备比较锥→CsrFile irq_pending→frontend dispatch 门控"直通家族。
  // 中断 pending 异步语义允许 +1 拍可见(mip.MTIP 采样无拍数承诺),出口寄存一拍
  // 斩断该组合直通(P5 刀P,白送时序余量)。
  wire mtip_irq_next_w = (mtime_q >= mtimecmp_q);

  assign write_data_pad_w[31:0] = native_write_data_w[31:0];
  assign write_strb_pad_w[3:0] = native_write_strb_w[3:0];
  generate
    if (DATA_W > 32) begin : gen_clint_data_high_lanes
      assign write_data_pad_w[63:32] = native_write_data_w[63:32];
    end else begin : gen_clint_data_high_zero
      assign write_data_pad_w[63:32] = 32'h0000_0000;
    end

    if (STRB_W > 4) begin : gen_clint_strb_high_lanes
      assign write_strb_pad_w[7:4] = native_write_strb_w[7:4];
    end else begin : gen_clint_strb_high_zero
      assign write_strb_pad_w[7:4] = 4'h0;
    end
  endgenerate

  function [63:0] apply_wstrb64_aligned;
    input [63:0] old_value;
    input [63:0] new_value;
    input [7:0] strb;
    begin
      // 固定 8-lane byte-enable mux，替代仿真式循环，便于综合审查每个 byte 的来源。
      apply_wstrb64_aligned[7:0]   = strb[0] ? new_value[7:0]   : old_value[7:0];
      apply_wstrb64_aligned[15:8]  = strb[1] ? new_value[15:8]  : old_value[15:8];
      apply_wstrb64_aligned[23:16] = strb[2] ? new_value[23:16] : old_value[23:16];
      apply_wstrb64_aligned[31:24] = strb[3] ? new_value[31:24] : old_value[31:24];
      apply_wstrb64_aligned[39:32] = strb[4] ? new_value[39:32] : old_value[39:32];
      apply_wstrb64_aligned[47:40] = strb[5] ? new_value[47:40] : old_value[47:40];
      apply_wstrb64_aligned[55:48] = strb[6] ? new_value[55:48] : old_value[55:48];
      apply_wstrb64_aligned[63:56] = strb[7] ? new_value[63:56] : old_value[63:56];
    end
  endfunction

  function [63:0] apply_wstrb64_high_word;
    input [63:0] old_value;
    input [63:0] new_value;
    input [7:0] strb;
    begin
      // *_HI 寄存器只消费写数据低 4 lane，高 4 lane 被显式忽略。
      apply_wstrb64_high_word[31:0]  = old_value[31:0];
      apply_wstrb64_high_word[39:32] = strb[0] ? new_value[7:0]   : old_value[39:32];
      apply_wstrb64_high_word[47:40] = strb[1] ? new_value[15:8]  : old_value[47:40];
      apply_wstrb64_high_word[55:48] = strb[2] ? new_value[23:16] : old_value[55:48];
      apply_wstrb64_high_word[63:56] = strb[3] ? new_value[31:24] : old_value[63:56];
    end
  endfunction

  function [DATA_W-1:0] read64_aligned;
    input [63:0] value;
    begin
      read64_aligned = value[DATA_W-1:0];
    end
  endfunction

  function [DATA_W-1:0] read32_zero_extend;
    input [31:0] value;
    begin
      read32_zero_extend = {{(DATA_W-32){1'b0}}, value};
    end
  endfunction

  function apply_msip_wstrb_bit;
    input old_bit;
    input new_bit;
    input strb0;
    begin
      apply_msip_wstrb_bit = strb0 ? new_bit : old_bit;
    end
  endfunction

  function [DATA_W-1:0] read_clint_word;
    input [15:0] addr_low;
    begin
      case (addr_low)
        CLINT_MSIP_OFFSET: read_clint_word = {{(DATA_W-1){1'b0}}, msip_q};
        CLINT_MTIMECMP_LO: read_clint_word = read64_aligned(mtimecmp_q);
        CLINT_MTIMECMP_HI: read_clint_word = read32_zero_extend(mtimecmp_q[63:32]);
        CLINT_MTIME_LO:    read_clint_word = read64_aligned(mtime_q);
        CLINT_MTIME_HI:    read_clint_word = read32_zero_extend(mtime_q[63:32]);
        default:           read_clint_word = {DATA_W{1'b0}};
      endcase
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_rdata_o <= {DATA_W{1'b0}};
      s_axi_bvalid_o <= 1'b0;
      awaddr_low_q <= 16'h0000;
      aw_seen_q <= 1'b0;
      wdata_q <= {DATA_W{1'b0}};
      wstrb_q <= {STRB_W{1'b0}};
      w_seen_q <= 1'b0;
      msip_q <= 1'b0;
      mtimecmp_q <= 64'hffff_ffff_ffff_ffff;
      mtime_q <= 64'h0;
      mtime_div_q <= 32'h0;
      mtip_irq_o <= 1'b0;
    end else begin
      // P5 刀P:mtip 出口打拍(见 mtip_irq_next_w 处注释)
      mtip_irq_o <= mtip_irq_next_w;
      if (mtime_tick_w) begin
        mtime_div_q <= 32'h0;
        mtime_q <= mtime_q + MTIME_INCREMENT;
      end else begin
        mtime_div_q <= mtime_div_q + 32'd1;
      end

      if (s_axi_rvalid_o && s_axi_rready_i)
        s_axi_rvalid_o <= 1'b0;

      if (s_axi_bvalid_o && s_axi_bready_i)
        s_axi_bvalid_o <= 1'b0;

      if (ar_fire_w) begin
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= read_clint_word(s_axi_araddr_i[15:0]) <<
                        read_lane_shift_w;
      end

      if (aw_fire_w) begin
        awaddr_low_q <= s_axi_awaddr_i[15:0];
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
        case (write_addr_low_w)
          CLINT_MSIP_OFFSET: msip_q <= apply_msip_wstrb_bit(
              msip_q, native_write_data_w[0], native_write_strb_w[0]);
          CLINT_MTIMECMP_LO: mtimecmp_q <= apply_wstrb64_aligned(mtimecmp_q,
                                                                 write_data_pad_w,
                                                                 write_strb_pad_w);
          CLINT_MTIMECMP_HI: mtimecmp_q <= apply_wstrb64_high_word(mtimecmp_q,
                                                                   write_data_pad_w,
                                                                   write_strb_pad_w);
          CLINT_MTIME_LO: mtime_q <= apply_wstrb64_aligned(mtime_q,
                                                           write_data_pad_w,
                                                           write_strb_pad_w);
          CLINT_MTIME_HI: mtime_q <= apply_wstrb64_high_word(mtime_q,
                                                             write_data_pad_w,
                                                             write_strb_pad_w);
          default: begin end
        endcase
      end
    end
  end

endmodule
