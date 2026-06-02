`include "define.v"

// Simulation-only virtio-mmio block frontend. The register model and disk DMA
// live in csrc/device/virtio_blk.c; this module only bridges AXI-Lite to DPI-C.
import "DPI-C" task npc_virtio_blk_read(
  input int unsigned offset,
  output longint unsigned data,
  output bit error,
  output bit irq
);

import "DPI-C" task npc_virtio_blk_write(
  input int unsigned offset,
  input longint unsigned data,
  input longint unsigned mask,
  output bit error,
  output bit irq
);

import "DPI-C" task npc_virtio_blk_irq(
  output bit irq
);

module AxiLiteVirtioBlk #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter STRB_W = DATA_W / 8
) (
  input logic clk,
  input logic rst,

  input logic s_axi_arvalid_i,
  output logic s_axi_arready_o,
  input logic [ADDR_W-1:0] s_axi_araddr_i,
  output logic s_axi_rvalid_o,
  input logic s_axi_rready_i,
  output logic [DATA_W-1:0] s_axi_rdata_o,
  output logic [1:0] s_axi_rresp_o,

  input logic s_axi_awvalid_i,
  output logic s_axi_awready_o,
  input logic [ADDR_W-1:0] s_axi_awaddr_i,
  input logic s_axi_wvalid_i,
  output logic s_axi_wready_o,
  input logic [DATA_W-1:0] s_axi_wdata_i,
  input logic [STRB_W-1:0] s_axi_wstrb_i,
  output logic s_axi_bvalid_o,
  input logic s_axi_bready_i,
  output logic [1:0] s_axi_bresp_o,

  output logic irq_o
);

  logic [11:0] awaddr_low_q;
  logic aw_valid_q;
  logic [DATA_W-1:0] wdata_q;
  logic [STRB_W-1:0] wstrb_q;
  logic w_valid_q;

  wire ar_fire_w = s_axi_arvalid_i && s_axi_arready_o;
  wire aw_fire_w = s_axi_awvalid_i && s_axi_awready_o;
  wire w_fire_w = s_axi_wvalid_i && s_axi_wready_o;
  wire write_complete_w = !s_axi_bvalid_o &&
                          (aw_valid_q || aw_fire_w) &&
                          (w_valid_q || w_fire_w);

  assign s_axi_arready_o = !s_axi_rvalid_o;
  assign s_axi_awready_o = !aw_valid_q && !s_axi_bvalid_o;
  assign s_axi_wready_o = !w_valid_q && !s_axi_bvalid_o;

  wire unused_addr_hi_w = |{
      s_axi_araddr_i[ADDR_W-1:12],
      s_axi_awaddr_i[ADDR_W-1:12]
  };

  always_ff @(posedge clk) begin
    longint unsigned dpi_data_v;
    longint unsigned write_data_v;
    longint unsigned write_mask_v;
    int unsigned offset_v;
    bit dpi_error_v;
    bit dpi_irq_v;

    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_rdata_o <= {DATA_W{1'b0}};
      s_axi_rresp_o <= 2'b00;
      s_axi_bvalid_o <= 1'b0;
      s_axi_bresp_o <= 2'b00;
      irq_o <= 1'b0;
      awaddr_low_q <= 12'h000;
      aw_valid_q <= 1'b0;
      wdata_q <= {DATA_W{1'b0}};
      wstrb_q <= {STRB_W{1'b0}};
      w_valid_q <= 1'b0;
    end else begin
      npc_virtio_blk_irq(dpi_irq_v);
      irq_o <= dpi_irq_v;

      if (s_axi_rvalid_o && s_axi_rready_i) begin
        s_axi_rvalid_o <= 1'b0;
      end

      if (s_axi_bvalid_o && s_axi_bready_i) begin
        s_axi_bvalid_o <= 1'b0;
      end

      if (ar_fire_w) begin
        offset_v = {20'd0, s_axi_araddr_i[11:0]};
        npc_virtio_blk_read(offset_v, dpi_data_v, dpi_error_v, dpi_irq_v);
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= dpi_data_v[DATA_W-1:0];
        s_axi_rresp_o <= dpi_error_v ? 2'b10 : 2'b00;
        irq_o <= dpi_irq_v;
      end

      if (aw_fire_w) begin
        awaddr_low_q <= s_axi_awaddr_i[11:0];
        aw_valid_q <= 1'b1;
      end

      if (w_fire_w) begin
        wdata_q <= s_axi_wdata_i;
        wstrb_q <= s_axi_wstrb_i;
        w_valid_q <= 1'b1;
      end

      if (write_complete_w) begin
        offset_v = {20'd0, (aw_fire_w ? s_axi_awaddr_i[11:0] : awaddr_low_q)};
        write_data_v = {{(64-DATA_W){1'b0}}, (w_fire_w ? s_axi_wdata_i : wdata_q)};
        write_mask_v = {{(64-STRB_W){1'b0}}, (w_fire_w ? s_axi_wstrb_i : wstrb_q)};
        npc_virtio_blk_write(offset_v, write_data_v, write_mask_v,
                             dpi_error_v, dpi_irq_v);
        s_axi_bvalid_o <= 1'b1;
        s_axi_bresp_o <= dpi_error_v ? 2'b10 : 2'b00;
        irq_o <= dpi_irq_v;
        aw_valid_q <= 1'b0;
        w_valid_q <= 1'b0;
      end
    end
  end

endmodule
