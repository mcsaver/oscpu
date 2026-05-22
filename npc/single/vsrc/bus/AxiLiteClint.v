`include "define.v"

// CLINT-like 设备提供 M-mode 软件/定时器中断源；core 只消费标准 irq_* 信号。
module AxiLiteClint #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8,
  parameter [63:0] MTIME_INCREMENT = 64'd1
) (
  input clk,
  input rst,

  input s_axi_arvalid_i,
  output s_axi_arready_o,
  input [ADDR_W-1:0] s_axi_araddr_i,
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

  output [63:0] mtime_o,
  output msip_irq_o,
  output mtip_irq_o
);

  localparam [15:0] CLINT_MSIP_OFFSET      = 16'h0000;
  localparam [15:0] CLINT_MTIMECMP_LO      = 16'h4000;
  localparam [15:0] CLINT_MTIMECMP_HI      = 16'h4004;
  localparam [15:0] CLINT_MTIME_LO         = 16'hbff8;
  localparam [15:0] CLINT_MTIME_HI         = 16'hbffc;

  reg [15:0] awaddr_low_q;
  reg aw_seen_q;
  reg [DATA_W-1:0] wdata_q;
  reg [STRB_W-1:0] wstrb_q;
  reg w_seen_q;
  reg msip_q;
  reg [63:0] mtimecmp_q;
  reg [63:0] mtime_q;

  wire ar_fire_w = s_axi_arvalid_i && s_axi_arready_o;
  wire aw_fire_w = s_axi_awvalid_i && s_axi_awready_o;
  wire w_fire_w = s_axi_wvalid_i && s_axi_wready_o;
  wire write_done_w = !s_axi_bvalid_o &&
                      (aw_seen_q || aw_fire_w) &&
                      (w_seen_q || w_fire_w);
  wire [15:0] write_addr_low_w = aw_fire_w ? s_axi_awaddr_i[15:0] : awaddr_low_q;
  wire [DATA_W-1:0] write_data_w = w_fire_w ? s_axi_wdata_i : wdata_q;
  wire [STRB_W-1:0] write_strb_w = w_fire_w ? s_axi_wstrb_i : wstrb_q;
  wire unused_addr_hi_w = |{
      s_axi_araddr_i[ADDR_W-1:16],
      s_axi_awaddr_i[ADDR_W-1:16]
  };

  assign s_axi_arready_o = !s_axi_rvalid_o;
  assign s_axi_rresp_o = 2'b00;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;
  assign s_axi_bresp_o = 2'b00;
  assign mtime_o = mtime_q;
  assign msip_irq_o = msip_q;
  assign mtip_irq_o = (mtime_q >= mtimecmp_q);

  function [DATA_W-1:0] apply_wstrb;
    input [DATA_W-1:0] old_value;
    input [DATA_W-1:0] new_value;
    input [STRB_W-1:0] strb;
    integer i;
    begin
      apply_wstrb = old_value;
      for (i = 0; i < STRB_W; i = i + 1) begin
        if (strb[i])
          apply_wstrb[i*8 +: 8] = new_value[i*8 +: 8];
      end
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
        CLINT_MTIMECMP_LO: read_clint_word = mtimecmp_q[31:0];
        CLINT_MTIMECMP_HI: read_clint_word = mtimecmp_q[63:32];
        CLINT_MTIME_LO:    read_clint_word = mtime_q[31:0];
        CLINT_MTIME_HI:    read_clint_word = mtime_q[63:32];
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
    end else begin
      mtime_q <= mtime_q + MTIME_INCREMENT;

      if (s_axi_rvalid_o && s_axi_rready_i)
        s_axi_rvalid_o <= 1'b0;

      if (s_axi_bvalid_o && s_axi_bready_i)
        s_axi_bvalid_o <= 1'b0;

      if (ar_fire_w) begin
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= read_clint_word(s_axi_araddr_i[15:0]);
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
          CLINT_MSIP_OFFSET: msip_q <= apply_msip_wstrb_bit(msip_q, write_data_w[0], write_strb_w[0]);
          CLINT_MTIMECMP_LO: mtimecmp_q <= {mtimecmp_q[63:32],
                                            apply_wstrb(mtimecmp_q[31:0], write_data_w, write_strb_w)};
          CLINT_MTIMECMP_HI: mtimecmp_q <= {apply_wstrb(mtimecmp_q[63:32], write_data_w, write_strb_w),
                                            mtimecmp_q[31:0]};
          CLINT_MTIME_LO: mtime_q <= {mtime_q[63:32],
                                      apply_wstrb(mtime_q[31:0], write_data_w, write_strb_w)};
          CLINT_MTIME_HI: mtime_q <= {apply_wstrb(mtime_q[63:32], write_data_w, write_strb_w),
                                      mtime_q[31:0]};
          default: begin end
        endcase
      end
    end
  end

endmodule
