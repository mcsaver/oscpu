`include "define.v"

// PLIC-like 最小外部中断控制器。rootfs 路线需要 UART 与 virtio-blk
// 同时可中断，因此这里按标准 bitmap 形态支持 source 1..31。
module AxiLitePlic #(
  parameter ADDR_W = `XLEN,
  parameter DATA_W = `XLEN,
  parameter STRB_W = DATA_W / 8,
  parameter SOURCE_NUM = 32
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

  input [SOURCE_NUM-1:0] source_irq_i,
  output external_irq_o
);

  localparam [21:0] PLIC_PRIORITY_BASE = 22'h000000;
  localparam [21:0] PLIC_PENDING_OFFSET = 22'h001000;
  localparam [21:0] PLIC_M_ENABLE_OFFSET = 22'h002000;
  localparam [21:0] PLIC_S_ENABLE_OFFSET = 22'h002080;
  localparam [21:0] PLIC_M_THRESH_OFFSET = 22'h200000;
  localparam [21:0] PLIC_M_CLAIM_OFFSET = 22'h200004;
  localparam [21:0] PLIC_S_THRESH_OFFSET = 22'h201000;
  localparam [21:0] PLIC_S_CLAIM_OFFSET = 22'h201004;

  reg [21:0] awaddr_low_q;
  reg aw_seen_q;
  reg [DATA_W-1:0] wdata_q;
  reg [STRB_W-1:0] wstrb_q;
  reg w_seen_q;

  reg [31:0] priority_q [0:SOURCE_NUM-1];
  reg [SOURCE_NUM-1:0] pending_q;
  reg [SOURCE_NUM-1:0] in_service_q;
  reg [SOURCE_NUM-1:0] enable_m_q;
  reg [SOURCE_NUM-1:0] enable_s_q;
  reg [31:0] threshold_m_q;
  reg [31:0] threshold_s_q;

  wire [4:0] m_claim_id_r;
  wire [4:0] s_claim_id_r;
  reg [SOURCE_NUM-1:0] pending_next_r;
  reg [SOURCE_NUM-1:0] in_service_next_r;
  reg [31:0] pending_write_bitmap_r;
  integer i;

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
  wire [63:0] write_data_pad_w;
  wire [7:0] write_strb_pad_w;
  wire [31:0] m_claim_prio_l0 [0:31];
  wire [4:0] m_claim_id_l0 [0:31];
  wire [31:0] s_claim_prio_l0 [0:31];
  wire [4:0] s_claim_id_l0 [0:31];
  wire [31:0] m_claim_prio_l1 [0:15];
  wire [4:0] m_claim_id_l1 [0:15];
  wire [31:0] s_claim_prio_l1 [0:15];
  wire [4:0] s_claim_id_l1 [0:15];
  wire [31:0] m_claim_prio_l2 [0:7];
  wire [4:0] m_claim_id_l2 [0:7];
  wire [31:0] s_claim_prio_l2 [0:7];
  wire [4:0] s_claim_id_l2 [0:7];
  wire [31:0] m_claim_prio_l3 [0:3];
  wire [4:0] m_claim_id_l3 [0:3];
  wire [31:0] s_claim_prio_l3 [0:3];
  wire [4:0] s_claim_id_l3 [0:3];
  wire [31:0] m_claim_prio_l4 [0:1];
  wire [4:0] m_claim_id_l4 [0:1];
  wire [31:0] s_claim_prio_l4 [0:1];
  wire [4:0] s_claim_id_l4 [0:1];
  wire m_claim_take_upper_w;
  wire s_claim_take_upper_w;
  wire m_claim_addr_w =
      (read_addr_low_w == PLIC_M_CLAIM_OFFSET) ||
      (read_addr_low_w == (PLIC_M_CLAIM_OFFSET & 22'h3f_ff_f8));
  wire s_claim_addr_w =
      (read_addr_low_w == PLIC_S_CLAIM_OFFSET) ||
      (read_addr_low_w == (PLIC_S_CLAIM_OFFSET & 22'h3f_ff_f8));
  wire claim_read_w = ar_fire_w && (m_claim_addr_w || s_claim_addr_w);
  wire [4:0] claim_id_w = m_claim_addr_w ? m_claim_id_r : s_claim_id_r;
  wire complete_low_w =
      ((write_addr_low_w == PLIC_M_CLAIM_OFFSET) ||
       (write_addr_low_w == PLIC_S_CLAIM_OFFSET)) &&
      write_strb_pad_w[0] &&
      (write_data_pad_w[4:0] != 5'd0) &&
      (write_data_pad_w[4:0] < SOURCE_NUM);
  wire complete_high_w =
      ((write_addr_low_w == (PLIC_M_CLAIM_OFFSET & 22'h3f_ff_f8)) ||
       (write_addr_low_w == (PLIC_S_CLAIM_OFFSET & 22'h3f_ff_f8))) &&
      write_strb_pad_w[4] &&
      (write_data_pad_w[36:32] != 5'd0) &&
      (write_data_pad_w[36:32] < SOURCE_NUM);
  wire complete_write_w = write_done_w && (complete_low_w || complete_high_w);
  wire [4:0] complete_id_w = complete_high_w ? write_data_pad_w[36:32] : write_data_pad_w[4:0];
  wire [31:0] enable_m_write_bitmap_w =
      apply_wstrb32_lane(bitmap32(enable_m_q), write_data_pad_w[31:0], write_strb_pad_w[3:0]);
  wire [31:0] enable_s_write_bitmap_w =
      apply_wstrb32_lane(bitmap32(enable_s_q), write_data_pad_w[31:0], write_strb_pad_w[3:0]);
  wire unused_addr_hi_w = |{
      s_axi_araddr_i[ADDR_W-1:22],
      s_axi_awaddr_i[ADDR_W-1:22],
      PLIC_PRIORITY_BASE
  };

  assign s_axi_arready_o = !s_axi_rvalid_o;
  assign s_axi_rresp_o = 2'b00;
  assign s_axi_awready_o = !aw_seen_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_seen_q && !s_axi_bvalid_o;
  assign s_axi_bresp_o = 2'b00;
  assign external_irq_o = (m_claim_id_r != 5'd0) || (s_claim_id_r != 5'd0);
  assign write_data_pad_w[31:0] = write_data_w[31:0];
  assign write_strb_pad_w[3:0] = write_strb_w[3:0];

  generate
    if (DATA_W >= 64) begin : gen_write_data_hi
      assign write_data_pad_w[63:32] = write_data_w[63:32];
    end else begin : gen_write_data_hi_zero
      assign write_data_pad_w[63:32] = 32'h0;
    end
    if (STRB_W >= 8) begin : gen_write_strb_hi
      assign write_strb_pad_w[7:4] = write_strb_w[7:4];
    end else begin : gen_write_strb_hi_zero
      assign write_strb_pad_w[7:4] = 4'h0;
    end
  endgenerate

  genvar claim_idx;
  generate
    for (claim_idx = 0; claim_idx < 32; claim_idx = claim_idx + 1) begin : gen_claim_l0
      if ((claim_idx > 0) && (claim_idx < SOURCE_NUM)) begin : gen_source_candidate
        wire m_valid_w;
        wire s_valid_w;
        assign m_valid_w = pending_q[claim_idx] && enable_m_q[claim_idx] &&
                           !in_service_q[claim_idx] &&
                           (priority_q[claim_idx] > threshold_m_q) &&
                           (priority_q[claim_idx] != 32'h0);
        assign s_valid_w = pending_q[claim_idx] && enable_s_q[claim_idx] &&
                           !in_service_q[claim_idx] &&
                           (priority_q[claim_idx] > threshold_s_q) &&
                           (priority_q[claim_idx] != 32'h0);
        assign m_claim_prio_l0[claim_idx] = m_valid_w ? priority_q[claim_idx] : 32'h0;
        assign s_claim_prio_l0[claim_idx] = s_valid_w ? priority_q[claim_idx] : 32'h0;
        assign m_claim_id_l0[claim_idx] = m_valid_w ? claim_idx[4:0] : 5'd0;
        assign s_claim_id_l0[claim_idx] = s_valid_w ? claim_idx[4:0] : 5'd0;
      end else begin : gen_source_tieoff
        assign m_claim_prio_l0[claim_idx] = 32'h0;
        assign s_claim_prio_l0[claim_idx] = 32'h0;
        assign m_claim_id_l0[claim_idx] = 5'd0;
        assign s_claim_id_l0[claim_idx] = 5'd0;
      end
    end

    for (claim_idx = 0; claim_idx < 16; claim_idx = claim_idx + 1) begin : gen_claim_l1
      wire m_take_hi_w;
      wire s_take_hi_w;
      assign m_take_hi_w = m_claim_prio_l0[(claim_idx * 2) + 1] >
                           m_claim_prio_l0[claim_idx * 2];
      assign s_take_hi_w = s_claim_prio_l0[(claim_idx * 2) + 1] >
                           s_claim_prio_l0[claim_idx * 2];
      assign m_claim_prio_l1[claim_idx] =
          m_take_hi_w ? m_claim_prio_l0[(claim_idx * 2) + 1] : m_claim_prio_l0[claim_idx * 2];
      assign s_claim_prio_l1[claim_idx] =
          s_take_hi_w ? s_claim_prio_l0[(claim_idx * 2) + 1] : s_claim_prio_l0[claim_idx * 2];
      assign m_claim_id_l1[claim_idx] =
          m_take_hi_w ? m_claim_id_l0[(claim_idx * 2) + 1] : m_claim_id_l0[claim_idx * 2];
      assign s_claim_id_l1[claim_idx] =
          s_take_hi_w ? s_claim_id_l0[(claim_idx * 2) + 1] : s_claim_id_l0[claim_idx * 2];
    end

    for (claim_idx = 0; claim_idx < 8; claim_idx = claim_idx + 1) begin : gen_claim_l2
      wire m_take_hi_w;
      wire s_take_hi_w;
      assign m_take_hi_w = m_claim_prio_l1[(claim_idx * 2) + 1] >
                           m_claim_prio_l1[claim_idx * 2];
      assign s_take_hi_w = s_claim_prio_l1[(claim_idx * 2) + 1] >
                           s_claim_prio_l1[claim_idx * 2];
      assign m_claim_prio_l2[claim_idx] =
          m_take_hi_w ? m_claim_prio_l1[(claim_idx * 2) + 1] : m_claim_prio_l1[claim_idx * 2];
      assign s_claim_prio_l2[claim_idx] =
          s_take_hi_w ? s_claim_prio_l1[(claim_idx * 2) + 1] : s_claim_prio_l1[claim_idx * 2];
      assign m_claim_id_l2[claim_idx] =
          m_take_hi_w ? m_claim_id_l1[(claim_idx * 2) + 1] : m_claim_id_l1[claim_idx * 2];
      assign s_claim_id_l2[claim_idx] =
          s_take_hi_w ? s_claim_id_l1[(claim_idx * 2) + 1] : s_claim_id_l1[claim_idx * 2];
    end

    for (claim_idx = 0; claim_idx < 4; claim_idx = claim_idx + 1) begin : gen_claim_l3
      wire m_take_hi_w;
      wire s_take_hi_w;
      assign m_take_hi_w = m_claim_prio_l2[(claim_idx * 2) + 1] >
                           m_claim_prio_l2[claim_idx * 2];
      assign s_take_hi_w = s_claim_prio_l2[(claim_idx * 2) + 1] >
                           s_claim_prio_l2[claim_idx * 2];
      assign m_claim_prio_l3[claim_idx] =
          m_take_hi_w ? m_claim_prio_l2[(claim_idx * 2) + 1] : m_claim_prio_l2[claim_idx * 2];
      assign s_claim_prio_l3[claim_idx] =
          s_take_hi_w ? s_claim_prio_l2[(claim_idx * 2) + 1] : s_claim_prio_l2[claim_idx * 2];
      assign m_claim_id_l3[claim_idx] =
          m_take_hi_w ? m_claim_id_l2[(claim_idx * 2) + 1] : m_claim_id_l2[claim_idx * 2];
      assign s_claim_id_l3[claim_idx] =
          s_take_hi_w ? s_claim_id_l2[(claim_idx * 2) + 1] : s_claim_id_l2[claim_idx * 2];
    end

    for (claim_idx = 0; claim_idx < 2; claim_idx = claim_idx + 1) begin : gen_claim_l4
      wire m_take_hi_w;
      wire s_take_hi_w;
      assign m_take_hi_w = m_claim_prio_l3[(claim_idx * 2) + 1] >
                           m_claim_prio_l3[claim_idx * 2];
      assign s_take_hi_w = s_claim_prio_l3[(claim_idx * 2) + 1] >
                           s_claim_prio_l3[claim_idx * 2];
      assign m_claim_prio_l4[claim_idx] =
          m_take_hi_w ? m_claim_prio_l3[(claim_idx * 2) + 1] : m_claim_prio_l3[claim_idx * 2];
      assign s_claim_prio_l4[claim_idx] =
          s_take_hi_w ? s_claim_prio_l3[(claim_idx * 2) + 1] : s_claim_prio_l3[claim_idx * 2];
      assign m_claim_id_l4[claim_idx] =
          m_take_hi_w ? m_claim_id_l3[(claim_idx * 2) + 1] : m_claim_id_l3[claim_idx * 2];
      assign s_claim_id_l4[claim_idx] =
          s_take_hi_w ? s_claim_id_l3[(claim_idx * 2) + 1] : s_claim_id_l3[claim_idx * 2];
    end
  endgenerate

  assign m_claim_take_upper_w = m_claim_prio_l4[1] > m_claim_prio_l4[0];
  assign s_claim_take_upper_w = s_claim_prio_l4[1] > s_claim_prio_l4[0];
  assign m_claim_id_r = m_claim_take_upper_w ? m_claim_id_l4[1] : m_claim_id_l4[0];
  assign s_claim_id_r = s_claim_take_upper_w ? s_claim_id_l4[1] : s_claim_id_l4[0];

  function [DATA_W-1:0] pack_u32_pair;
    input [31:0] low;
    input [31:0] high;
    begin
      pack_u32_pair = {high, low};
    end
  endfunction

  function [31:0] apply_wstrb32_lane;
    input [31:0] old_value;
    input [31:0] new_value;
    input [3:0] strb;
    begin
      apply_wstrb32_lane[7:0] = strb[0] ? new_value[7:0] : old_value[7:0];
      apply_wstrb32_lane[15:8] = strb[1] ? new_value[15:8] : old_value[15:8];
      apply_wstrb32_lane[23:16] = strb[2] ? new_value[23:16] : old_value[23:16];
      apply_wstrb32_lane[31:24] = strb[3] ? new_value[31:24] : old_value[31:24];
    end
  endfunction

  function [31:0] priority_at;
    input [21:0] word_index;
    begin
      if (word_index < SOURCE_NUM[21:0])
        priority_at = priority_q[word_index];
      else
        priority_at = 32'h0;
    end
  endfunction

  function [31:0] bitmap32;
    input [SOURCE_NUM-1:0] bits;
    begin
      bitmap32 = 32'h0;
      bitmap32[SOURCE_NUM-1:0] = bits;
    end
  endfunction

  function [DATA_W-1:0] read_plic_word;
    input [21:0] addr_low;
    begin
      if (addr_low < PLIC_PENDING_OFFSET) begin
        // Priority 区域按 32-bit word 编址；64-bit beat 同时返回相邻两个 source。
        read_plic_word = pack_u32_pair(priority_at(addr_low[21:2]),
                                       priority_at(addr_low[21:2] + 22'd1));
      end else begin
        case (addr_low)
          PLIC_PENDING_OFFSET:
            read_plic_word = pack_u32_pair(bitmap32(pending_q), 32'h0);
          PLIC_M_ENABLE_OFFSET:
            read_plic_word = pack_u32_pair(bitmap32(enable_m_q), 32'h0);
          PLIC_S_ENABLE_OFFSET:
            read_plic_word = pack_u32_pair(bitmap32(enable_s_q), 32'h0);
          PLIC_M_THRESH_OFFSET:
            read_plic_word = pack_u32_pair(threshold_m_q, {27'h0, m_claim_id_r});
          PLIC_S_THRESH_OFFSET:
            read_plic_word = pack_u32_pair(threshold_s_q, {27'h0, s_claim_id_r});
          PLIC_M_CLAIM_OFFSET:
            read_plic_word = pack_u32_pair({27'h0, m_claim_id_r}, 32'h0);
          PLIC_S_CLAIM_OFFSET:
            read_plic_word = pack_u32_pair({27'h0, s_claim_id_r}, 32'h0);
          default:
            read_plic_word = {DATA_W{1'b0}};
        endcase
      end
    end
  endfunction

  always @(*) begin
    pending_next_r = pending_q | (source_irq_i & ~in_service_q);
    in_service_next_r = in_service_q;
    pending_write_bitmap_r = bitmap32(pending_next_r);

    if (claim_read_w && (claim_id_w != 5'd0) && (claim_id_w < SOURCE_NUM)) begin
      pending_next_r[claim_id_w] = 1'b0;
      in_service_next_r[claim_id_w] = 1'b1;
    end

    if (write_done_w && (write_addr_low_w == PLIC_PENDING_OFFSET) &&
        (write_strb_pad_w[3:0] != 4'h0)) begin
      pending_write_bitmap_r =
          apply_wstrb32_lane(bitmap32(pending_next_r), write_data_pad_w[31:0], write_strb_pad_w[3:0]);
      pending_next_r = pending_write_bitmap_r[SOURCE_NUM-1:0];
    end

    if (complete_write_w) begin
      in_service_next_r[complete_id_w] = 1'b0;
      if (source_irq_i[complete_id_w])
        pending_next_r[complete_id_w] = 1'b1;
    end

    pending_next_r[0] = 1'b0;
    in_service_next_r[0] = 1'b0;
  end

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
      pending_q <= {SOURCE_NUM{1'b0}};
      in_service_q <= {SOURCE_NUM{1'b0}};
      enable_m_q <= {SOURCE_NUM{1'b0}};
      enable_s_q <= {SOURCE_NUM{1'b0}};
      threshold_m_q <= 32'h0;
      threshold_s_q <= 32'h0;
      for (i = 0; i < SOURCE_NUM; i = i + 1)
        priority_q[i] <= 32'h0;
    end else begin
      pending_q <= pending_next_r;
      in_service_q <= in_service_next_r;

      if (s_axi_rvalid_o && s_axi_rready_i)
        s_axi_rvalid_o <= 1'b0;

      if (s_axi_bvalid_o && s_axi_bready_i)
        s_axi_bvalid_o <= 1'b0;

      if (ar_fire_w) begin
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= read_plic_word(read_addr_low_w);
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

        if (write_addr_low_w < PLIC_PENDING_OFFSET) begin
          if (write_strb_pad_w[3:0] != 4'h0 &&
              (write_addr_low_w[21:2] < SOURCE_NUM[21:0])) begin
            priority_q[write_addr_low_w[21:2]] <=
                apply_wstrb32_lane(priority_q[write_addr_low_w[21:2]],
                                   write_data_pad_w[31:0],
                                   write_strb_pad_w[3:0]);
          end
          if (write_strb_pad_w[7:4] != 4'h0 &&
              ((write_addr_low_w[21:2] + 22'd1) < SOURCE_NUM[21:0])) begin
            priority_q[write_addr_low_w[21:2] + 22'd1] <=
                apply_wstrb32_lane(priority_q[write_addr_low_w[21:2] + 22'd1],
                                   write_data_pad_w[63:32],
                                   write_strb_pad_w[7:4]);
          end
        end else begin
          case (write_addr_low_w)
            PLIC_M_ENABLE_OFFSET:
              if (write_strb_pad_w[3:0] != 4'h0)
                enable_m_q <= enable_m_write_bitmap_w[SOURCE_NUM-1:0];
            PLIC_S_ENABLE_OFFSET:
              if (write_strb_pad_w[3:0] != 4'h0)
                enable_s_q <= enable_s_write_bitmap_w[SOURCE_NUM-1:0];
            PLIC_M_THRESH_OFFSET:
              if (write_strb_pad_w[3:0] != 4'h0)
                threshold_m_q <= apply_wstrb32_lane(threshold_m_q,
                                                    write_data_pad_w[31:0],
                                                    write_strb_pad_w[3:0]);
            PLIC_S_THRESH_OFFSET:
              if (write_strb_pad_w[3:0] != 4'h0)
                threshold_s_q <= apply_wstrb32_lane(threshold_s_q,
                                                    write_data_pad_w[31:0],
                                                    write_strb_pad_w[3:0]);
            default: begin end
          endcase
        end
      end
    end
  end

endmodule
