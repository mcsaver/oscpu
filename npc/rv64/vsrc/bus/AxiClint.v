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

  input                   s_axi_arvalid_i,
  output                  s_axi_arready_o,
  input      [ADDR_W-1:0] s_axi_araddr_i,
  input      [       2:0] s_axi_arsize_i,
  output reg              s_axi_rvalid_o,
  input                   s_axi_rready_i,
  output reg [DATA_W-1:0] s_axi_rdata_o,
  output     [       1:0] s_axi_rresp_o,

  input                   s_axi_awvalid_i,
  output                  s_axi_awready_o,
  input      [ADDR_W-1:0] s_axi_awaddr_i,
  input      [       2:0] s_axi_awsize_i,
  input                   s_axi_wvalid_i,
  output                  s_axi_wready_o,
  input      [DATA_W-1:0] s_axi_wdata_i,
  input      [STRB_W-1:0] s_axi_wstrb_i,
  output reg              s_axi_bvalid_o,
  input                   s_axi_bready_i,
  output     [       1:0] s_axi_bresp_o,

  output     [63:0] mtime_o,
  output            msip_irq_o,
  output reg        mtip_irq_o,
  output            timer_wait_o
);

  localparam integer        LANE_BITS          = $clog2(STRB_W);

  localparam         [15:0] CLINT_MSIP_OFFSET  = 16'h0000;
  localparam         [15:0] CLINT_MTIMECMP_LO  = 16'h4000;
  localparam         [15:0] CLINT_MTIMECMP_HI  = 16'h4004;
  localparam         [15:0] CLINT_MTIME_LO     = 16'hbff8;
  localparam         [15:0] CLINT_MTIME_HI     = 16'hbffc;
  localparam         [31:0] MTIME_DIVISOR_SAFE = (MTIME_DIVISOR == 32'd0) ? 32'd1 : MTIME_DIVISOR;

  reg [15:0] araddr_low_q;
  reg ar_seen_q;
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
  // AW and W have independent capture slots. Only their registered owners
  // authorize the device write; Fabric admission is not in the register cone.
  wire write_done_w = !s_axi_bvalid_o && aw_seen_q && w_seen_q;
  wire [15:0] write_addr_low_w = awaddr_low_q;
  wire [DATA_W-1:0] write_data_w = wdata_q;
  wire [STRB_W-1:0] write_strb_w = wstrb_q;
  wire [LANE_BITS-1:0] write_lane_w = write_addr_low_w[LANE_BITS-1:0];
  wire [5:0] write_lane_shift_w = write_lane_w * 6'd8;
  wire [DATA_W-1:0] native_write_data_w = write_data_w >> write_lane_shift_w;
  wire [STRB_W-1:0] native_write_strb_w = write_strb_w >> write_lane_w;
  wire [63:0] write_data_pad_w;
  wire [7:0] write_strb_pad_w;
  wire unused_addr_hi_w =
      |{s_axi_araddr_i[ADDR_W-1:16], s_axi_awaddr_i[ADDR_W-1:16], s_axi_arsize_i, s_axi_awsize_i};

  assign s_axi_arready_o = !ar_seen_q && !s_axi_rvalid_o;
  assign s_axi_rresp_o = 2'b00;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;
  assign s_axi_bresp_o = 2'b00;
  assign mtime_o = mtime_q;
  assign timer_wait_o = mtimecmp_q != 64'hffffffffffffffff && !mtip_irq_o;
  // msip_irq_o 直连寄存器 msip_q,本就无组合锥,毋需再打拍。
  assign msip_irq_o = msip_q;
  // Register the timer comparison before the core interrupt-input boundary.
  // The exported interrupt is the preceding cycle's mtime/mtimecmp comparison.
  wire mtip_irq_next_w = (mtime_q >= mtimecmp_q);

  assign write_data_pad_w[31:0] = native_write_data_w[31:0];
  assign write_strb_pad_w[3:0]  = native_write_strb_w[3:0];
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

  // Identical byte muxes for MTIME and MTIMECMP. Address decode and the
  // timer-tick/software-write priority stay explicit in the state block.
  localparam TIMER_MTIME = 0, TIMER_MTIMECMP = 1;
  wire [127:0] timer_values_w;
  assign timer_values_w[TIMER_MTIME*64+:64] = mtime_q;
  assign timer_values_w[TIMER_MTIMECMP*64+:64] = mtimecmp_q;
  wire [127:0] aligned_write_w, high_word_write_w;
  genvar timer_reg, byte_lane;
  generate
    for (timer_reg = 0; timer_reg < 2; timer_reg = timer_reg + 1) begin : gen_timer_write
      for (byte_lane = 0; byte_lane < 8; byte_lane = byte_lane + 1) begin : gen_byte
        assign aligned_write_w[timer_reg*64+byte_lane*8+:8] = write_strb_pad_w[byte_lane] ?
            write_data_pad_w[byte_lane*8+:8] : timer_values_w[timer_reg*64+byte_lane*8+:8];
        if (byte_lane < 4) begin : gen_keep_low
          assign high_word_write_w[timer_reg*64+byte_lane*8+:8] =
              timer_values_w[timer_reg*64+byte_lane*8+:8];
        end else begin : gen_write_high
          // A HI register consumes the low four native write-data lanes.
          assign high_word_write_w[timer_reg*64+byte_lane*8+:8] = write_strb_pad_w[byte_lane-4] ?
              write_data_pad_w[(byte_lane-4)*8+:8] : timer_values_w[timer_reg*64+byte_lane*8+:8];
        end
      end
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_rdata_o <= {DATA_W{1'b0}};
      s_axi_bvalid_o <= 1'b0;
      araddr_low_q <= 16'h0000;
      ar_seen_q <= 1'b0;
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
      mtip_irq_o <= mtip_irq_next_w;
      if (mtime_tick_w) begin
        mtime_div_q <= 32'h0;
        mtime_q <= mtime_q + MTIME_INCREMENT;
      end else begin
        mtime_div_q <= mtime_div_q + 32'd1;
      end

      if (s_axi_rvalid_o && s_axi_rready_i) s_axi_rvalid_o <= 1'b0;

      if (s_axi_bvalid_o && s_axi_bready_i) s_axi_bvalid_o <= 1'b0;

      // Capture the physical request before selecting a timer/register value.
      // Its address remains authoritative after the Fabric reuses its AR pins.
      if (ar_fire_w) begin
        araddr_low_q <= s_axi_araddr_i[15:0];
        ar_seen_q <= 1'b1;
      end
      if (ar_seen_q && !s_axi_rvalid_o) begin
        ar_seen_q <= 1'b0;
        s_axi_rvalid_o <= 1'b1;
        // Sample the selected architectural register at this response edge.
        case (araddr_low_q)
          CLINT_MSIP_OFFSET: s_axi_rdata_o <= {{(DATA_W - 1) {1'b0}}, msip_q};
          CLINT_MTIMECMP_LO: s_axi_rdata_o <= mtimecmp_q[DATA_W-1:0];
          CLINT_MTIMECMP_HI:
          s_axi_rdata_o <= {{(DATA_W - 32) {1'b0}}, mtimecmp_q[63:32]} << ((DATA_W > 32) ? 32 : 0);
          CLINT_MTIME_LO: s_axi_rdata_o <= mtime_q[DATA_W-1:0];
          CLINT_MTIME_HI:
          s_axi_rdata_o <= {{(DATA_W - 32) {1'b0}}, mtime_q[63:32]} << ((DATA_W > 32) ? 32 : 0);
          default: s_axi_rdata_o <= {DATA_W{1'b0}};
        endcase
      end

      if (aw_fire_w) begin
        awaddr_low_q <= s_axi_awaddr_i[15:0];
        aw_seen_q <= 1'b1;
      end

      if (w_fire_w) begin
        wdata_q  <= s_axi_wdata_i;
        wstrb_q  <= s_axi_wstrb_i;
        w_seen_q <= 1'b1;
      end

      if (write_done_w) begin
        s_axi_bvalid_o <= 1'b1;
        aw_seen_q <= 1'b0;
        w_seen_q <= 1'b0;
        case (write_addr_low_w)
          CLINT_MSIP_OFFSET:
          msip_q <= native_write_strb_w[0] ? native_write_data_w[0] : msip_q;
          CLINT_MTIMECMP_LO:
          mtimecmp_q <= aligned_write_w[TIMER_MTIMECMP*64+:64];
          CLINT_MTIMECMP_HI:
          mtimecmp_q <= high_word_write_w[TIMER_MTIMECMP*64+:64];
          CLINT_MTIME_LO:
          mtime_q <= aligned_write_w[TIMER_MTIME*64+:64];
          CLINT_MTIME_HI:
          mtime_q <= high_word_write_w[TIMER_MTIME*64+:64];
          default: begin
          end
        endcase
      end
    end
  end

endmodule
