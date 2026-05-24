`include "define.v"

// ysyxSoC 只接受一路 AXI4 master；这里把 NpcCore 内部 IFU/LSU 的
// single-beat AXI-like 访问汇聚到完整命名的 AXI4 通道，保持 core 边界不被 SoC 细节污染。
module NpcSoCAxiBridge (
  input clk,
  input rst,

  input ifu_axi_arvalid_i,
  output ifu_axi_arready_o,
  input [`XLEN-1:0] ifu_axi_araddr_i,
  input ifu_axi_abort_i,
  output ifu_axi_rvalid_o,
  input ifu_axi_rready_i,
  output [`XLEN-1:0] ifu_axi_rdata_o,
  output [1:0] ifu_axi_rresp_o,

  input lsu_axi_arvalid_i,
  output lsu_axi_arready_o,
  input [`XLEN-1:0] lsu_axi_araddr_i,
  output lsu_axi_rvalid_o,
  input lsu_axi_rready_i,
  output [`XLEN-1:0] lsu_axi_rdata_o,
  output [1:0] lsu_axi_rresp_o,
  input lsu_axi_awvalid_i,
  output lsu_axi_awready_o,
  input [`XLEN-1:0] lsu_axi_awaddr_i,
  input lsu_axi_wvalid_i,
  output lsu_axi_wready_o,
  input [`XLEN-1:0] lsu_axi_wdata_i,
  input [3:0] lsu_axi_wstrb_i,
  output lsu_axi_bvalid_o,
  input lsu_axi_bready_i,
  output [1:0] lsu_axi_bresp_o,

  input io_master_awready,
  output io_master_awvalid,
  output [`XLEN-1:0] io_master_awaddr,
  output [3:0] io_master_awid,
  output [7:0] io_master_awlen,
  output [2:0] io_master_awsize,
  output [1:0] io_master_awburst,
  input io_master_wready,
  output io_master_wvalid,
  output [`XLEN-1:0] io_master_wdata,
  output [3:0] io_master_wstrb,
  output io_master_wlast,
  output io_master_bready,
  input io_master_bvalid,
  input [1:0] io_master_bresp,
  input [3:0] io_master_bid,
  input io_master_arready,
  output io_master_arvalid,
  output [`XLEN-1:0] io_master_araddr,
  output [3:0] io_master_arid,
  output [7:0] io_master_arlen,
  output [2:0] io_master_arsize,
  output [1:0] io_master_arburst,
  output io_master_rready,
  input io_master_rvalid,
  input [1:0] io_master_rresp,
  input [`XLEN-1:0] io_master_rdata,
  input io_master_rlast,
  input [3:0] io_master_rid
);

  localparam RD_OWNER_IFU = 1'b0;
  localparam RD_OWNER_LSU = 1'b1;
  localparam [1:0] RD_IDLE = 2'd0;
  localparam [1:0] RD_AR = 2'd1;
  localparam [1:0] RD_R = 2'd2;

  reg [1:0] rd_state_q;
  reg rd_owner_q;
  reg [`XLEN-1:0] rd_addr_q;
  reg rd_drop_q;

  wire ifu_req_w = ifu_axi_arvalid_i && !ifu_axi_abort_i;
  wire lsu_req_w = lsu_axi_arvalid_i;
  wire pick_lsu_w = lsu_req_w;
  wire pick_ifu_w = !lsu_req_w && ifu_req_w;
  wire pick_valid_w = pick_lsu_w || pick_ifu_w;
  wire pick_owner_w = pick_lsu_w ? RD_OWNER_LSU : RD_OWNER_IFU;
  wire [`XLEN-1:0] pick_addr_w = pick_lsu_w ? lsu_axi_araddr_i : ifu_axi_araddr_i;
  wire [`XLEN-1:0] araddr_sel_w = (rd_state_q == RD_IDLE) ? pick_addr_w : rd_addr_q;
  wire ar_owner_lsu_sel_w = (rd_state_q == RD_IDLE) ?
                            (pick_owner_w == RD_OWNER_LSU) :
                            rd_owner_lsu_w;
  wire ar_uart_w = (araddr_sel_w & `NPC_AXI_UART_MASK) == `NPC_AXI_UART_BASE;
  wire aw_uart_w = (lsu_axi_awaddr_i & `NPC_AXI_UART_MASK) == `NPC_AXI_UART_BASE;
  wire aw_byte_w = (lsu_axi_wstrb_i == 4'b0001) ||
                   (lsu_axi_wstrb_i == 4'b0010) ||
                   (lsu_axi_wstrb_i == 4'b0100) ||
                   (lsu_axi_wstrb_i == 4'b1000);
  wire aw_half_w = (lsu_axi_wstrb_i == 4'b0011) ||
                   (lsu_axi_wstrb_i == 4'b0110) ||
                   (lsu_axi_wstrb_i == 4'b1100);
  wire [2:0] awsize_w = aw_byte_w ? 3'b000 :
                        (aw_half_w ? 3'b001 : 3'b010);

  wire rd_ar_cancel_w = (rd_state_q == RD_AR) &&
                        (rd_owner_q == RD_OWNER_IFU) &&
                        ifu_axi_abort_i;
  wire rd_ifu_drop_w = (rd_owner_q == RD_OWNER_IFU) &&
                       (rd_drop_q || ifu_axi_abort_i);
  wire rd_owner_ifu_w = (rd_owner_q == RD_OWNER_IFU);
  wire rd_owner_lsu_w = (rd_owner_q == RD_OWNER_LSU);
  wire rd_r_fire_w = (rd_state_q == RD_R) &&
                     io_master_rvalid && io_master_rready;

  assign io_master_arvalid = ((rd_state_q == RD_IDLE) && pick_valid_w) ||
                             ((rd_state_q == RD_AR) && !rd_ar_cancel_w);
  assign io_master_araddr = araddr_sel_w;
  assign io_master_arid = 4'h0;
  assign io_master_arlen = 8'h00;
  assign io_master_arsize = (ar_owner_lsu_sel_w && ar_uart_w) ? 3'b000 : 3'b010;
  assign io_master_arburst = 2'b01;

  assign ifu_axi_arready_o = ((rd_state_q == RD_IDLE) &&
                              pick_ifu_w && io_master_arready) ||
                             ((rd_state_q == RD_AR) &&
                              rd_owner_ifu_w && !rd_ar_cancel_w &&
                              io_master_arready);
  assign lsu_axi_arready_o = ((rd_state_q == RD_IDLE) &&
                              pick_lsu_w && io_master_arready) ||
                             ((rd_state_q == RD_AR) &&
                              rd_owner_lsu_w && io_master_arready);

  assign io_master_rready = (rd_state_q == RD_R) &&
                            (rd_ifu_drop_w ||
                             (rd_owner_ifu_w && ifu_axi_rready_i) ||
                             (rd_owner_lsu_w && lsu_axi_rready_i));
  assign ifu_axi_rvalid_o = (rd_state_q == RD_R) && rd_owner_ifu_w &&
                            !rd_ifu_drop_w && io_master_rvalid;
  assign lsu_axi_rvalid_o = (rd_state_q == RD_R) && rd_owner_lsu_w &&
                            io_master_rvalid;
  assign ifu_axi_rdata_o = io_master_rdata;
  assign lsu_axi_rdata_o = io_master_rdata;
  assign ifu_axi_rresp_o = io_master_rresp;
  assign lsu_axi_rresp_o = io_master_rresp;

  assign io_master_awvalid = lsu_axi_awvalid_i;
  assign lsu_axi_awready_o = io_master_awready;
  assign io_master_awaddr = lsu_axi_awaddr_i;
  assign io_master_awid = 4'h0;
  assign io_master_awlen = 8'h00;
  assign io_master_awsize = aw_uart_w ? awsize_w : 3'b010;
  assign io_master_awburst = 2'b01;

  assign io_master_wvalid = lsu_axi_wvalid_i;
  assign lsu_axi_wready_o = io_master_wready;
  assign io_master_wdata = lsu_axi_wdata_i;
  assign io_master_wstrb = lsu_axi_wstrb_i;
  assign io_master_wlast = 1'b1;

  assign lsu_axi_bvalid_o = io_master_bvalid;
  assign lsu_axi_bresp_o = io_master_bresp;
  assign io_master_bready = lsu_axi_bready_i;

  wire unused_axi_payload_w = |{io_master_bid, io_master_rid, io_master_rlast};

  always @(posedge clk) begin
    if (rst) begin
      rd_state_q <= RD_IDLE;
      rd_owner_q <= RD_OWNER_IFU;
      rd_addr_q <= {`XLEN{1'b0}};
      rd_drop_q <= 1'b0;
    end else begin
      case (rd_state_q)
        RD_IDLE: begin
          rd_drop_q <= 1'b0;
          if (pick_valid_w) begin
            rd_owner_q <= pick_owner_w;
            rd_addr_q <= pick_addr_w;
            rd_state_q <= io_master_arready ? RD_R : RD_AR;
          end
        end

        RD_AR: begin
          if (rd_ar_cancel_w) begin
            rd_state_q <= RD_IDLE;
            rd_drop_q <= 1'b0;
          end else if (io_master_arready) begin
            rd_state_q <= RD_R;
          end
        end

        RD_R: begin
          if ((rd_owner_q == RD_OWNER_IFU) && ifu_axi_abort_i)
            rd_drop_q <= 1'b1;
          if (rd_r_fire_w) begin
            rd_state_q <= RD_IDLE;
            rd_drop_q <= 1'b0;
          end
        end

        default: begin
          rd_state_q <= RD_IDLE;
          rd_drop_q <= 1'b0;
        end
      endcase
    end
  end

endmodule
