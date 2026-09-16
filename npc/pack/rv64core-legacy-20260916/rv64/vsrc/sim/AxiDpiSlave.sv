`include "define.v"

// 仿真专用 AXI-like slave：把 crossbar slave 端请求桥接到宿主 PMEM/MMIO。
// 该模块只属于 Verilator 顶层，不进入综合路径中的真实外设实现。
import "DPI-C" task npc_ifetch_sized(
  input longint unsigned addr,
  input int unsigned nbytes,
  output longint unsigned data,
  output bit error
);

import "DPI-C" task npc_mem_read_sized(
  input longint unsigned addr,
  input int unsigned nbytes,
  output longint unsigned data,
  output bit error
);

import "DPI-C" task npc_mem_write(
  input longint unsigned addr,
  input longint unsigned data,
  input longint unsigned mask,
  output bit error
);

module AxiDpiSlave (
  input logic clk,
  input logic rst,

  input logic s_axi_arvalid_i,
  output logic s_axi_arready_o,
  input logic [`XLEN-1:0] s_axi_araddr_i,
  input logic [2:0] s_axi_arsize_i,
  input logic [2:0] s_axi_arprot_i,
  output logic s_axi_rvalid_o,
  input logic s_axi_rready_i,
  output logic [`XLEN-1:0] s_axi_rdata_o,
  output logic [1:0] s_axi_rresp_o,

  input logic s_axi_awvalid_i,
  output logic s_axi_awready_o,
  input logic [`XLEN-1:0] s_axi_awaddr_i,
  input logic [2:0] s_axi_awsize_i,
  input logic s_axi_wvalid_i,
  output logic s_axi_wready_o,
  input logic [`XLEN-1:0] s_axi_wdata_i,
  input logic [`STRB_W-1:0] s_axi_wstrb_i,
  output logic s_axi_bvalid_o,
  input logic s_axi_bready_i,
  output logic [1:0] s_axi_bresp_o
);

  logic [`XLEN-1:0] awaddr_q;
  logic [2:0] awsize_q;
  logic aw_valid_q;
  logic [`XLEN-1:0] wdata_q;
  logic [`STRB_W-1:0] wstrb_q;
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

  always_ff @(posedge clk) begin
    longint unsigned bus_data_v;
    longint unsigned read_data_v;
    longint unsigned write_addr_v;
    longint unsigned write_data_v;
    longint unsigned write_mask_v;
    int unsigned read_size_v;
    int unsigned write_size_v;
    int unsigned lane_shift_v;
    bit bus_error_v;

    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_rdata_o <= {`XLEN{1'b0}};
      s_axi_rresp_o <= 2'b00;
      s_axi_bvalid_o <= 1'b0;
      s_axi_bresp_o <= 2'b00;
      awaddr_q <= {`XLEN{1'b0}};
      awsize_q <= 3'd0;
      aw_valid_q <= 1'b0;
      wdata_q <= {`XLEN{1'b0}};
      wstrb_q <= {`STRB_W{1'b0}};
      w_valid_q <= 1'b0;
    end else begin
      if (s_axi_rvalid_o && s_axi_rready_i) begin
        s_axi_rvalid_o <= 1'b0;
      end

      if (s_axi_bvalid_o && s_axi_bready_i) begin
        s_axi_bvalid_o <= 1'b0;
      end

      if (ar_fire_w) begin
        read_size_v = (s_axi_arsize_i <= 3'd3) ?
                      (32'd1 << s_axi_arsize_i) : 32'd0;
        bus_data_v = 64'd0;
        read_data_v = 64'd0;
        bus_error_v = 1'b0;
        // DPI returns a low-window value.  Both IFU and LSU now use the same
        // standard AXI byte-lane ABI, so every successful read is shifted into
        // the lane selected by ARADDR[2:0].
        if (s_axi_arprot_i[2] && (read_size_v != 0)) begin
          npc_ifetch_sized(s_axi_araddr_i, read_size_v,
                           bus_data_v, bus_error_v);
          lane_shift_v = {29'd0, s_axi_araddr_i[2:0]} * 8;
          read_data_v = bus_data_v << lane_shift_v;
        end else if (!s_axi_arprot_i[2] && (read_size_v != 0)) begin
          npc_mem_read_sized(s_axi_araddr_i, read_size_v,
                             bus_data_v, bus_error_v);
          lane_shift_v = {29'd0, s_axi_araddr_i[2:0]} * 8;
          read_data_v = bus_data_v << lane_shift_v;
        end else begin
          bus_error_v = 1'b1;
        end
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= read_data_v[`XLEN-1:0];
        s_axi_rresp_o <= bus_error_v ? 2'b10 : 2'b00;
      end

      if (aw_fire_w) begin
        awaddr_q <= s_axi_awaddr_i;
        awsize_q <= s_axi_awsize_i;
        aw_valid_q <= 1'b1;
      end

      if (w_fire_w) begin
        wdata_q <= s_axi_wdata_i;
        wstrb_q <= s_axi_wstrb_i;
        w_valid_q <= 1'b1;
      end

      if (write_complete_w) begin
        write_addr_v = aw_fire_w ? s_axi_awaddr_i : awaddr_q;
        write_size_v = ((aw_fire_w ? s_axi_awsize_i : awsize_q) <= 3'd3) ?
                       (32'd1 << (aw_fire_w ? s_axi_awsize_i : awsize_q)) :
                       32'd0;
        lane_shift_v = {29'd0, write_addr_v[2:0]} * 8;
        write_data_v = (w_fire_w ? s_axi_wdata_i : wdata_q) >> lane_shift_v;
        write_mask_v =
            {{(64-`STRB_W){1'b0}}, (w_fire_w ? s_axi_wstrb_i : wstrb_q)} >>
            write_addr_v[2:0];
        bus_error_v = 1'b0;
        if ((write_size_v == 0) ||
            (({29'd0, write_addr_v[2:0]} + write_size_v) > 32'd8) ||
            (write_mask_v != ((64'd1 << write_size_v) - 64'd1))) begin
          bus_error_v = 1'b1;
        end else begin
          npc_mem_write(write_addr_v, write_data_v, write_mask_v, bus_error_v);
        end
        s_axi_bvalid_o <= 1'b1;
        s_axi_bresp_o <= bus_error_v ? 2'b10 : 2'b00;
        aw_valid_q <= 1'b0;
        w_valid_q <= 1'b0;
      end
    end
  end

endmodule
