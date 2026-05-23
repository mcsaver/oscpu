`include "define.v"

/* verilator lint_off UNUSEDSIGNAL */

// ysyxSoC 规范顶层：端口命名、方向和位宽对齐 spec/cpu-interface.md。
// 内部仍复用 NpcCore，SoC AXI4 适配只留在这一层。
module ysyx_26010035 (
  input clock,
  input reset,
  input io_interrupt,

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
  input [3:0] io_master_rid,

  output io_slave_awready,
  input io_slave_awvalid,
  input [`XLEN-1:0] io_slave_awaddr,
  input [3:0] io_slave_awid,
  input [7:0] io_slave_awlen,
  input [2:0] io_slave_awsize,
  input [1:0] io_slave_awburst,
  output io_slave_wready,
  input io_slave_wvalid,
  input [`XLEN-1:0] io_slave_wdata,
  input [3:0] io_slave_wstrb,
  input io_slave_wlast,
  input io_slave_bready,
  output io_slave_bvalid,
  output [1:0] io_slave_bresp,
  output [3:0] io_slave_bid,
  output io_slave_arready,
  input io_slave_arvalid,
  input [`XLEN-1:0] io_slave_araddr,
  input [3:0] io_slave_arid,
  input [7:0] io_slave_arlen,
  input [2:0] io_slave_arsize,
  input [1:0] io_slave_arburst,
  input io_slave_rready,
  output io_slave_rvalid,
  output [1:0] io_slave_rresp,
  output [`XLEN-1:0] io_slave_rdata,
  output io_slave_rlast,
  output [3:0] io_slave_rid
);

  wire ifu_axi_arvalid_w;
  wire ifu_axi_arready_w;
  wire [`XLEN-1:0] ifu_axi_araddr_w;
  wire ifu_axi_abort_w;
  wire ifu_axi_rvalid_w;
  wire ifu_axi_rready_w;
  wire [`XLEN-1:0] ifu_axi_rdata_w;
  wire [1:0] ifu_axi_rresp_w;

  wire lsu_axi_arvalid_w;
  wire lsu_axi_arready_w;
  wire [`XLEN-1:0] lsu_axi_araddr_w;
  wire lsu_axi_rvalid_w;
  wire lsu_axi_rready_w;
  wire [`XLEN-1:0] lsu_axi_rdata_w;
  wire [1:0] lsu_axi_rresp_w;
  wire lsu_axi_awvalid_w;
  wire lsu_axi_awready_w;
  wire [`XLEN-1:0] lsu_axi_awaddr_w;
  wire lsu_axi_wvalid_w;
  wire lsu_axi_wready_w;
  wire [`XLEN-1:0] lsu_axi_wdata_w;
  wire [3:0] lsu_axi_wstrb_w;
  wire lsu_axi_bvalid_w;
  wire lsu_axi_bready_w;
  wire [1:0] lsu_axi_bresp_w;

  wire commit_valid_w;
  wire [`XLEN-1:0] commit_pc_w;
  wire [`INST_W-1:0] commit_inst_w;
  wire [`XLEN-1:0] commit_next_pc_w;
  wire commit_rd_en_w;
  wire [`REG_ADDR_W-1:0] commit_rd_addr_w;
  wire [`XLEN-1:0] commit_rd_data_w;
  wire trap_valid_w;
  wire [`TRAP_CAUSE_W-1:0] trap_cause_w;
  wire [`XLEN-1:0] trap_pc_w;
  wire [`XLEN-1:0] trap_tval_w;
  wire exit_valid_w;
  wire exit_is_ecall_w;
  wire exit_is_ebreak_w;
  wire [`XLEN-1:0] exit_code_w;
  wire halted_w;
  wire [`XLEN-1:0] debug_pc_w;
  wire [`CORE_STATE_W-1:0] debug_state_w;
  wire [`XLEN * `REG_NUM - 1:0] debug_gprs_w;

  NpcCore u_core (
    .clk(clock),
    .rst(reset),
    .ifu_axi_arvalid_o(ifu_axi_arvalid_w),
    .ifu_axi_arready_i(ifu_axi_arready_w),
    .ifu_axi_araddr_o(ifu_axi_araddr_w),
    .ifu_axi_abort_o(ifu_axi_abort_w),
    .ifu_axi_rvalid_i(ifu_axi_rvalid_w),
    .ifu_axi_rready_o(ifu_axi_rready_w),
    .ifu_axi_rdata_i(ifu_axi_rdata_w),
    .ifu_axi_rresp_i(ifu_axi_rresp_w),
    .lsu_axi_arvalid_o(lsu_axi_arvalid_w),
    .lsu_axi_arready_i(lsu_axi_arready_w),
    .lsu_axi_araddr_o(lsu_axi_araddr_w),
    .lsu_axi_rvalid_i(lsu_axi_rvalid_w),
    .lsu_axi_rready_o(lsu_axi_rready_w),
    .lsu_axi_rdata_i(lsu_axi_rdata_w),
    .lsu_axi_rresp_i(lsu_axi_rresp_w),
    .lsu_axi_awvalid_o(lsu_axi_awvalid_w),
    .lsu_axi_awready_i(lsu_axi_awready_w),
    .lsu_axi_awaddr_o(lsu_axi_awaddr_w),
    .lsu_axi_wvalid_o(lsu_axi_wvalid_w),
    .lsu_axi_wready_i(lsu_axi_wready_w),
    .lsu_axi_wdata_o(lsu_axi_wdata_w),
    .lsu_axi_wstrb_o(lsu_axi_wstrb_w),
    .lsu_axi_bvalid_i(lsu_axi_bvalid_w),
    .lsu_axi_bready_o(lsu_axi_bready_w),
    .lsu_axi_bresp_i(lsu_axi_bresp_w),
    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(io_interrupt),
    .commit_valid_o(commit_valid_w),
    .commit_pc_o(commit_pc_w),
    .commit_inst_o(commit_inst_w),
    .commit_next_pc_o(commit_next_pc_w),
    .commit_rd_en_o(commit_rd_en_w),
    .commit_rd_addr_o(commit_rd_addr_w),
    .commit_rd_data_o(commit_rd_data_w),
    .trap_valid_o(trap_valid_w),
    .trap_cause_o(trap_cause_w),
    .trap_pc_o(trap_pc_w),
    .trap_tval_o(trap_tval_w),
    .exit_valid_o(exit_valid_w),
    .exit_is_ecall_o(exit_is_ecall_w),
    .exit_is_ebreak_o(exit_is_ebreak_w),
    .exit_code_o(exit_code_w),
    .halted_o(halted_w),
    .debug_pc_o(debug_pc_w),
    .debug_state_o(debug_state_w),
    .debug_gprs_o(debug_gprs_w)
  );

  NpcSoCAxiBridge u_axi4_bridge (
    .clk(clock),
    .rst(reset),
    .ifu_axi_arvalid_i(ifu_axi_arvalid_w),
    .ifu_axi_arready_o(ifu_axi_arready_w),
    .ifu_axi_araddr_i(ifu_axi_araddr_w),
    .ifu_axi_abort_i(ifu_axi_abort_w),
    .ifu_axi_rvalid_o(ifu_axi_rvalid_w),
    .ifu_axi_rready_i(ifu_axi_rready_w),
    .ifu_axi_rdata_o(ifu_axi_rdata_w),
    .ifu_axi_rresp_o(ifu_axi_rresp_w),
    .lsu_axi_arvalid_i(lsu_axi_arvalid_w),
    .lsu_axi_arready_o(lsu_axi_arready_w),
    .lsu_axi_araddr_i(lsu_axi_araddr_w),
    .lsu_axi_rvalid_o(lsu_axi_rvalid_w),
    .lsu_axi_rready_i(lsu_axi_rready_w),
    .lsu_axi_rdata_o(lsu_axi_rdata_w),
    .lsu_axi_rresp_o(lsu_axi_rresp_w),
    .lsu_axi_awvalid_i(lsu_axi_awvalid_w),
    .lsu_axi_awready_o(lsu_axi_awready_w),
    .lsu_axi_awaddr_i(lsu_axi_awaddr_w),
    .lsu_axi_wvalid_i(lsu_axi_wvalid_w),
    .lsu_axi_wready_o(lsu_axi_wready_w),
    .lsu_axi_wdata_i(lsu_axi_wdata_w),
    .lsu_axi_wstrb_i(lsu_axi_wstrb_w),
    .lsu_axi_bvalid_o(lsu_axi_bvalid_w),
    .lsu_axi_bready_i(lsu_axi_bready_w),
    .lsu_axi_bresp_o(lsu_axi_bresp_w),
    .io_master_awready(io_master_awready),
    .io_master_awvalid(io_master_awvalid),
    .io_master_awaddr(io_master_awaddr),
    .io_master_awid(io_master_awid),
    .io_master_awlen(io_master_awlen),
    .io_master_awsize(io_master_awsize),
    .io_master_awburst(io_master_awburst),
    .io_master_wready(io_master_wready),
    .io_master_wvalid(io_master_wvalid),
    .io_master_wdata(io_master_wdata),
    .io_master_wstrb(io_master_wstrb),
    .io_master_wlast(io_master_wlast),
    .io_master_bready(io_master_bready),
    .io_master_bvalid(io_master_bvalid),
    .io_master_bresp(io_master_bresp),
    .io_master_bid(io_master_bid),
    .io_master_arready(io_master_arready),
    .io_master_arvalid(io_master_arvalid),
    .io_master_araddr(io_master_araddr),
    .io_master_arid(io_master_arid),
    .io_master_arlen(io_master_arlen),
    .io_master_arsize(io_master_arsize),
    .io_master_arburst(io_master_arburst),
    .io_master_rready(io_master_rready),
    .io_master_rvalid(io_master_rvalid),
    .io_master_rresp(io_master_rresp),
    .io_master_rdata(io_master_rdata),
    .io_master_rlast(io_master_rlast),
    .io_master_rid(io_master_rid)
  );

  assign io_slave_awready = 1'b0;
  assign io_slave_wready = 1'b0;
  assign io_slave_bvalid = 1'b0;
  assign io_slave_bresp = 2'b00;
  assign io_slave_bid = 4'h0;
  assign io_slave_arready = 1'b0;
  assign io_slave_rvalid = 1'b0;
  assign io_slave_rresp = 2'b00;
  assign io_slave_rdata = {`XLEN{1'b0}};
  assign io_slave_rlast = 1'b0;
  assign io_slave_rid = 4'h0;

  wire unused_slave_inputs_w = |{
      io_slave_awvalid, io_slave_awaddr, io_slave_awid, io_slave_awlen,
      io_slave_awsize, io_slave_awburst, io_slave_wvalid, io_slave_wdata,
      io_slave_wstrb, io_slave_wlast, io_slave_bready, io_slave_arvalid,
      io_slave_araddr, io_slave_arid, io_slave_arlen, io_slave_arsize,
      io_slave_arburst, io_slave_rready
  };
  wire unused_debug_w = |{
      commit_valid_w, commit_pc_w, commit_inst_w, commit_next_pc_w,
      commit_rd_en_w, commit_rd_addr_w, commit_rd_data_w,
      trap_valid_w, trap_cause_w, trap_pc_w, trap_tval_w,
      exit_valid_w, exit_is_ecall_w, exit_is_ebreak_w, exit_code_w,
      halted_w, debug_pc_w, debug_state_w, debug_gprs_w
  };

endmodule

/* verilator lint_on UNUSEDSIGNAL */
