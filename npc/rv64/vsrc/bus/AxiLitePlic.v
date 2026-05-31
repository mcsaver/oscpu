`include "define.v"

// PLIC-like 最小外部中断控制器。当前只建模 source 1 与 M/S 两个 context，
// 先为 Linux/OpenSBI 早期外部中断路径提供标准 MMIO 形状和 claim/complete 边界。
module AxiLitePlic #(
  parameter ADDR_W = `XLEN,
  parameter DATA_W = `XLEN,
  parameter STRB_W = DATA_W / 8
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

  input source_irq_i,
  output external_irq_o
);

  localparam [21:0] PLIC_PRIORITY1_OFFSET = 22'h000004;
  localparam [21:0] PLIC_PENDING_OFFSET   = 22'h001000;
  localparam [21:0] PLIC_M_ENABLE_OFFSET  = 22'h002000;
  localparam [21:0] PLIC_S_ENABLE_OFFSET  = 22'h002080;
  localparam [21:0] PLIC_M_THRESH_OFFSET  = 22'h200000;
  localparam [21:0] PLIC_M_CLAIM_OFFSET   = 22'h200004;
  localparam [21:0] PLIC_S_THRESH_OFFSET  = 22'h201000;
  localparam [21:0] PLIC_S_CLAIM_OFFSET   = 22'h201004;

  reg [21:0] awaddr_low_q;
  reg aw_seen_q;
  reg [DATA_W-1:0] wdata_q;
  reg [STRB_W-1:0] wstrb_q;
  reg w_seen_q;

  reg [31:0] priority_q;
  reg pending_q;
  reg in_service_q;
  reg enable_m_q;
  reg enable_s_q;
  reg [31:0] threshold_m_q;
  reg [31:0] threshold_s_q;

  wire ar_fire_w = s_axi_arvalid_i && s_axi_arready_o;
  wire aw_fire_w = s_axi_awvalid_i && s_axi_awready_o;
  wire w_fire_w = s_axi_wvalid_i && s_axi_wready_o;
  wire write_done_w = !s_axi_bvalid_o &&
                      (aw_seen_q || aw_fire_w) &&
                      (w_seen_q || w_fire_w);
  wire [21:0] read_addr_low_w = s_axi_araddr_i[21:0];
  wire [21:0] write_addr_low_w = aw_fire_w ? s_axi_awaddr_i[21:0] : awaddr_low_q;
  wire [DATA_W-1:0] write_data_w = w_fire_w ? s_axi_wdata_i : wdata_q;
  wire [STRB_W-1:0] write_strb_w = w_fire_w ? s_axi_wstrb_i : wstrb_q;
  wire m_claimable_w = pending_q && enable_m_q &&
                       (priority_q > threshold_m_q) &&
                       (priority_q != 32'h0);
  wire s_claimable_w = pending_q && enable_s_q &&
                       (priority_q > threshold_s_q) &&
                       (priority_q != 32'h0);
  wire claim_read_w = ar_fire_w &&
      ((read_addr_low_w == PLIC_M_CLAIM_OFFSET) ||
       (read_addr_low_w == PLIC_S_CLAIM_OFFSET) ||
       (read_addr_low_w == (PLIC_M_CLAIM_OFFSET & 22'h3f_ff_f8)) ||
       (read_addr_low_w == (PLIC_S_CLAIM_OFFSET & 22'h3f_ff_f8)));
  wire complete_low_w =
      ((write_addr_low_w == PLIC_M_CLAIM_OFFSET) ||
       (write_addr_low_w == PLIC_S_CLAIM_OFFSET)) &&
      write_strb_w[0] &&
      (write_data_w[31:0] == 32'd1);
  wire complete_high_w =
      ((write_addr_low_w == (PLIC_M_CLAIM_OFFSET & 22'h3f_ff_f8)) ||
       (write_addr_low_w == (PLIC_S_CLAIM_OFFSET & 22'h3f_ff_f8))) &&
      write_strb_w[4] &&
      (write_data_w[63:32] == 32'd1);
  wire complete_write_w = write_done_w && (complete_low_w || complete_high_w);
  wire unused_addr_hi_w = |{
      s_axi_araddr_i[ADDR_W-1:22],
      s_axi_awaddr_i[ADDR_W-1:22]
  };

  assign s_axi_arready_o = !s_axi_rvalid_o;
  assign s_axi_rresp_o = 2'b00;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;
  assign s_axi_bresp_o = 2'b00;
  assign external_irq_o = m_claimable_w | s_claimable_w;

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

  function [31:0] apply_wstrb32;
    input [31:0] old_value;
    input [DATA_W-1:0] new_value;
    input [STRB_W-1:0] strb;
    reg [DATA_W-1:0] merged;
    begin
      /* verilator lint_off BLKSEQ */
      merged = apply_wstrb({{(DATA_W-32){1'b0}}, old_value}, new_value, strb);
      /* verilator lint_on BLKSEQ */
      apply_wstrb32 = merged[31:0];
    end
  endfunction

  function [DATA_W-1:0] read_plic_word;
    input [21:0] addr_low;
    begin
      case (addr_low)
        22'h000000:
          read_plic_word = {{(DATA_W-64){1'b0}}, priority_q, 32'h0};
        PLIC_PRIORITY1_OFFSET:
          read_plic_word = {{(DATA_W-32){1'b0}}, priority_q};
        PLIC_PENDING_OFFSET:
          read_plic_word = {{(DATA_W-2){1'b0}}, pending_q, 1'b0};
        PLIC_M_ENABLE_OFFSET:
          read_plic_word = {{(DATA_W-2){1'b0}}, enable_m_q, 1'b0};
        PLIC_S_ENABLE_OFFSET:
          read_plic_word = {{(DATA_W-2){1'b0}}, enable_s_q, 1'b0};
        PLIC_M_THRESH_OFFSET:
          read_plic_word = {{(DATA_W-64){1'b0}},
                            (m_claimable_w ? 32'd1 : 32'd0), threshold_m_q};
        PLIC_S_THRESH_OFFSET:
          read_plic_word = {{(DATA_W-64){1'b0}},
                            (s_claimable_w ? 32'd1 : 32'd0), threshold_s_q};
        PLIC_M_CLAIM_OFFSET:
          read_plic_word = {{(DATA_W-32){1'b0}}, (m_claimable_w ? 32'd1 : 32'd0)};
        PLIC_S_CLAIM_OFFSET:
          read_plic_word = {{(DATA_W-32){1'b0}}, (s_claimable_w ? 32'd1 : 32'd0)};
        default:
          read_plic_word = {DATA_W{1'b0}};
      endcase
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_rdata_o <= {DATA_W{1'b0}};
      s_axi_bvalid_o <= 1'b0;
      awaddr_low_q <= 22'h0;
      aw_seen_q <= 1'b0;
      wdata_q <= {DATA_W{1'b0}};
      wstrb_q <= {STRB_W{1'b0}};
      w_seen_q <= 1'b0;
      priority_q <= 32'h0;
      pending_q <= 1'b0;
      in_service_q <= 1'b0;
      enable_m_q <= 1'b0;
      enable_s_q <= 1'b0;
      threshold_m_q <= 32'h0;
      threshold_s_q <= 32'h0;
    end else begin
      if (source_irq_i && !in_service_q)
        pending_q <= 1'b1;

      if (s_axi_rvalid_o && s_axi_rready_i)
        s_axi_rvalid_o <= 1'b0;

      if (s_axi_bvalid_o && s_axi_bready_i)
        s_axi_bvalid_o <= 1'b0;

      if (ar_fire_w) begin
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= read_plic_word(read_addr_low_w);
        if (claim_read_w && (m_claimable_w || s_claimable_w)) begin
          pending_q <= 1'b0;
          in_service_q <= 1'b1;
        end
      end

      if (aw_fire_w) begin
        awaddr_low_q <= s_axi_awaddr_i[21:0];
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
          22'h000000:
            priority_q <= write_strb_w[4] ?
                          apply_wstrb32(priority_q,
                                        {{(DATA_W-32){1'b0}},
                                         write_data_w[63:32]},
                                        {{(STRB_W-4){1'b0}},
                                         write_strb_w[7:4]}) :
                          priority_q;
          PLIC_PRIORITY1_OFFSET:
            priority_q <= apply_wstrb32(priority_q, write_data_w, write_strb_w);
          PLIC_PENDING_OFFSET:
            pending_q <= write_strb_w[0] ? write_data_w[1] : pending_q;
          PLIC_M_ENABLE_OFFSET:
            enable_m_q <= write_strb_w[0] ? write_data_w[1] : enable_m_q;
          PLIC_S_ENABLE_OFFSET:
            enable_s_q <= write_strb_w[0] ? write_data_w[1] : enable_s_q;
          PLIC_M_THRESH_OFFSET:
            threshold_m_q <= write_strb_w[0] ?
                             apply_wstrb32(threshold_m_q, write_data_w, write_strb_w) :
                             threshold_m_q;
          PLIC_S_THRESH_OFFSET:
            threshold_s_q <= write_strb_w[0] ?
                             apply_wstrb32(threshold_s_q, write_data_w, write_strb_w) :
                             threshold_s_q;
          PLIC_M_CLAIM_OFFSET,
          PLIC_S_CLAIM_OFFSET:
            begin end
          default: begin end
        endcase
      end

      if (complete_write_w) begin
        in_service_q <= 1'b0;
        if (source_irq_i)
          pending_q <= 1'b1;
      end
    end
  end

endmodule
