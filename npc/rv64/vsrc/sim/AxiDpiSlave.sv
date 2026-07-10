`include "define.v"

// 仿真专用 AXI-like slave：把 crossbar slave 端请求桥接到宿主 PMEM/MMIO。
// 该模块只属于 Verilator 顶层，不进入综合路径中的真实外设实现。
import "DPI-C" task npc_ifetch(
  input longint unsigned addr,
  output longint unsigned data,
  output bit error
);

import "DPI-C" task npc_mem_read(
  input longint unsigned addr,
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
  input logic [2:0] s_axi_arprot_i,
  output logic s_axi_rvalid_o,
  input logic s_axi_rready_i,
  output logic [`XLEN-1:0] s_axi_rdata_o,
  output logic [1:0] s_axi_rresp_o,

  input logic s_axi_awvalid_i,
  output logic s_axi_awready_o,
  input logic [`XLEN-1:0] s_axi_awaddr_i,
  input logic s_axi_wvalid_i,
  output logic s_axi_wready_o,
  input logic [`XLEN-1:0] s_axi_wdata_i,
  input logic [`STRB_W-1:0] s_axi_wstrb_i,
  output logic s_axi_bvalid_o,
  input logic s_axi_bready_i,
  output logic [1:0] s_axi_bresp_o
);

  logic [`XLEN-1:0] awaddr_q;
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
    longint unsigned write_addr_v;
    longint unsigned write_data_v;
    longint unsigned write_mask_v;
    bit bus_error_v;

    if (rst) begin
      s_axi_rvalid_o <= 1'b0;
      s_axi_rdata_o <= {`XLEN{1'b0}};
      s_axi_rresp_o <= 2'b00;
      s_axi_bvalid_o <= 1'b0;
      s_axi_bresp_o <= 2'b00;
      awaddr_q <= {`XLEN{1'b0}};
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
        // 【AXI4 化 S3】aruser→ARPROT[2](AXI 语义: bit2=1 表 instruction access)。
        if (s_axi_arprot_i[2]) begin
          npc_ifetch(s_axi_araddr_i, bus_data_v, bus_error_v);
        end else begin
          npc_mem_read(s_axi_araddr_i, bus_data_v, bus_error_v);
        end
        s_axi_rvalid_o <= 1'b1;
        s_axi_rdata_o <= bus_data_v[`XLEN-1:0];
        s_axi_rresp_o <= bus_error_v ? 2'b10 : 2'b00;
      end

      if (aw_fire_w) begin
        awaddr_q <= s_axi_awaddr_i;
        aw_valid_q <= 1'b1;
      end

      if (w_fire_w) begin
        wdata_q <= s_axi_wdata_i;
        wstrb_q <= s_axi_wstrb_i;
        w_valid_q <= 1'b1;
      end

      if (write_complete_w) begin
        write_addr_v = aw_fire_w ? s_axi_awaddr_i : awaddr_q;
        write_data_v = w_fire_w ? s_axi_wdata_i : wdata_q;
        write_mask_v = {{(64-`STRB_W){1'b0}}, (w_fire_w ? s_axi_wstrb_i : wstrb_q)};
        npc_mem_write(write_addr_v, write_data_v, write_mask_v, bus_error_v);
        s_axi_bvalid_o <= 1'b1;
        s_axi_bresp_o <= bus_error_v ? 2'b10 : 2'b00;
        aw_valid_q <= 1'b0;
        w_valid_q <= 1'b0;
      end
    end
  end

endmodule
