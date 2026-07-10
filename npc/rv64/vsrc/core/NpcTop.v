`include "define.v"

// Synthesizable SoC-level top.  The CPU core, AXI crossbar, UART, CLINT, PLIC,
// and default error slaves live here; Verilator-only DPI devices are connected
// by NpcSimTop through the exported AXI-Lite slave ports.
module NpcTop (
  input clk,
  input rst,

  output psram_axi_arvalid_o,
  input psram_axi_arready_i,
  output [`XLEN-1:0] psram_axi_araddr_o,
  output psram_axi_aruser_o,
  input psram_axi_rvalid_i,
  output psram_axi_rready_o,
  input [`XLEN-1:0] psram_axi_rdata_i,
  input [1:0] psram_axi_rresp_i,
  output psram_axi_awvalid_o,
  input psram_axi_awready_i,
  output [`XLEN-1:0] psram_axi_awaddr_o,
  output psram_axi_wvalid_o,
  input psram_axi_wready_i,
  output [`XLEN-1:0] psram_axi_wdata_o,
  output [`STRB_W-1:0] psram_axi_wstrb_o,
  input psram_axi_bvalid_i,
  output psram_axi_bready_o,
  input [1:0] psram_axi_bresp_i,

  output sdram_axi_arvalid_o,
  input sdram_axi_arready_i,
  output [`XLEN-1:0] sdram_axi_araddr_o,
  output sdram_axi_aruser_o,
  input sdram_axi_rvalid_i,
  output sdram_axi_rready_o,
  input [`XLEN-1:0] sdram_axi_rdata_i,
  input [1:0] sdram_axi_rresp_i,
  output sdram_axi_awvalid_o,
  input sdram_axi_awready_i,
  output [`XLEN-1:0] sdram_axi_awaddr_o,
  output sdram_axi_wvalid_o,
  input sdram_axi_wready_i,
  output [`XLEN-1:0] sdram_axi_wdata_o,
  output [`STRB_W-1:0] sdram_axi_wstrb_o,
  input sdram_axi_bvalid_i,
  output sdram_axi_bready_o,
  input [1:0] sdram_axi_bresp_i,

  output legacy_mmio_axi_arvalid_o,
  input legacy_mmio_axi_arready_i,
  output [`XLEN-1:0] legacy_mmio_axi_araddr_o,
  output legacy_mmio_axi_aruser_o,
  input legacy_mmio_axi_rvalid_i,
  output legacy_mmio_axi_rready_o,
  input [`XLEN-1:0] legacy_mmio_axi_rdata_i,
  input [1:0] legacy_mmio_axi_rresp_i,
  output legacy_mmio_axi_awvalid_o,
  input legacy_mmio_axi_awready_i,
  output [`XLEN-1:0] legacy_mmio_axi_awaddr_o,
  output legacy_mmio_axi_wvalid_o,
  input legacy_mmio_axi_wready_i,
  output [`XLEN-1:0] legacy_mmio_axi_wdata_o,
  output [`STRB_W-1:0] legacy_mmio_axi_wstrb_o,
  input legacy_mmio_axi_bvalid_i,
  output legacy_mmio_axi_bready_o,
  input [1:0] legacy_mmio_axi_bresp_i,

  output virtio_blk_axi_arvalid_o,
  input virtio_blk_axi_arready_i,
  output [`XLEN-1:0] virtio_blk_axi_araddr_o,
  output virtio_blk_axi_aruser_o,
  input virtio_blk_axi_rvalid_i,
  output virtio_blk_axi_rready_o,
  input [`XLEN-1:0] virtio_blk_axi_rdata_i,
  input [1:0] virtio_blk_axi_rresp_i,
  output virtio_blk_axi_awvalid_o,
  input virtio_blk_axi_awready_i,
  output [`XLEN-1:0] virtio_blk_axi_awaddr_o,
  output virtio_blk_axi_wvalid_o,
  input virtio_blk_axi_wready_i,
  output [`XLEN-1:0] virtio_blk_axi_wdata_o,
  output [`STRB_W-1:0] virtio_blk_axi_wstrb_o,
  input virtio_blk_axi_bvalid_i,
  output virtio_blk_axi_bready_o,
  input [1:0] virtio_blk_axi_bresp_i,
  input virtio_blk_irq_i,

  input uart_rx_valid_i,
  input [7:0] uart_rx_data_i,
  output uart_rx_ready_o,
  output uart_tx_valid_o,
  output [7:0] uart_tx_data_o,
  output uart_access_valid_o,
  output uart_access_write_o,
  output [11:0] uart_access_addr_o,
  output [`XLEN-1:0] uart_access_wdata_o,
  output [`STRB_W-1:0] uart_access_wstrb_o,
  output [`XLEN-1:0] uart_access_rdata_o,
  output uart_irq_o,
  output plic_external_irq_o,
  output [63:0] clint_mtime_o,

  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_rd_addr_o,
  output [`XLEN-1:0] commit0_rd_data_o,
  output commit0_exception_o,
  output commit0_write_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_rd_addr_o,
  output [`XLEN-1:0] commit1_rd_data_o,
  output commit1_exception_o,
  output commit1_write_o,

  output trap_valid_o,
  output [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output [`XLEN-1:0] trap_pc_o,
  output [`XLEN-1:0] trap_tval_o,
  output exit_valid_o,
  output exit_is_ecall_o,
  output exit_is_ebreak_o,
  output [`XLEN-1:0] exit_code_o,
  output [`XLEN-1:0] exit_pc_o,
  output halted_o,

  output [`XLEN-1:0] debug_pc_o,
  output [`CORE_STATE_W-1:0] debug_state_o,
  output [1:0] retire_count_o,
  output [`OOO_FREE_COUNT_W-1:0] free_count_o,
  output [`OOO_ROB_COUNT_W-1:0] rob_count_o,
  output [`OOO_ISSUE_COUNT_W-1:0] issue_count_o
);

  localparam [3:0] AXI_S_CLINT = 4'd0;
  localparam [3:0] AXI_S_PLIC = 4'd1;
  localparam [3:0] AXI_S_SRAM = 4'd2;
  localparam [3:0] AXI_S_UART = 4'd3;
  localparam [3:0] AXI_S_VIRTIO_BLK = 4'd4;
  localparam [3:0] AXI_S_GPIO = 4'd5;
  localparam [3:0] AXI_S_PS2 = 4'd6;
  localparam [3:0] AXI_S_MROM = 4'd7;
  localparam [3:0] AXI_S_VGA = 4'd8;
  localparam [3:0] AXI_S_FLASH = 4'd9;
  localparam [3:0] AXI_S_CHIPLINK_MMIO = 4'd10;
  localparam [3:0] AXI_S_PSRAM = 4'd11;
  localparam [3:0] AXI_S_LEGACY_MMIO = 4'd12;
  localparam [3:0] AXI_S_SDRAM = 4'd13;
  localparam [3:0] AXI_S_CHIPLINK_MEM = 4'd14;
  localparam [3:0] AXI_S_DEFAULT = 4'd15;
  localparam AXI_S_DEFAULT_PARAM = 15;
  localparam AXI_S_COUNT = 16;
  localparam [31:0] CLINT_MTIME_DIVISOR = 32'd10;

  function [AXI_S_COUNT-1:0] axi_slave_bit;
    input [3:0] idx;
    begin
      axi_slave_bit = {AXI_S_COUNT{1'b0}};
      axi_slave_bit[idx] = 1'b1;
    end
  endfunction

  localparam [AXI_S_COUNT-1:0] AXI_S_STUB_MASK =
      axi_slave_bit(AXI_S_SRAM) |
      axi_slave_bit(AXI_S_GPIO) |
      axi_slave_bit(AXI_S_PS2) |
      axi_slave_bit(AXI_S_MROM) |
      axi_slave_bit(AXI_S_VGA) |
      axi_slave_bit(AXI_S_FLASH) |
      axi_slave_bit(AXI_S_CHIPLINK_MMIO) |
      axi_slave_bit(AXI_S_CHIPLINK_MEM) |
      axi_slave_bit(AXI_S_DEFAULT);

  wire ifu_axi_arvalid_w;
  wire ifu_axi_arready_w;
  wire [`XLEN-1:0] ifu_axi_araddr_w;
  wire ifu_axi_rvalid_w;
  wire ifu_axi_rready_w;
  wire [`XLEN-1:0] ifu_axi_rdata_w;
  wire [1:0] ifu_axi_rresp_w;
  // HW-managed A 更新：取指桥写通道(写回 PTE 置 A 位)。
  wire ifu_axi_awvalid_w;
  wire ifu_axi_awready_w;
  wire [`XLEN-1:0] ifu_axi_awaddr_w;
  wire ifu_axi_wvalid_w;
  wire ifu_axi_wready_w;
  wire [`XLEN-1:0] ifu_axi_wdata_w;
  wire [`STRB_W-1:0] ifu_axi_wstrb_w;
  wire ifu_axi_bvalid_w;
  wire ifu_axi_bready_w;
  wire [1:0] ifu_axi_bresp_w;

  wire lsu_axi_arvalid_w;
  wire lsu_axi_arready_w;
  wire [`XLEN-1:0] lsu_axi_araddr_w;
  wire [`STRB_W-1:0] lsu_axi_arstrb_w;
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
  wire [`STRB_W-1:0] lsu_axi_wstrb_w;
  wire lsu_axi_bvalid_w;
  wire lsu_axi_bready_w;
  wire [1:0] lsu_axi_bresp_w;

  wire [AXI_S_COUNT-1:0] bus_axi_arvalid_w;
  wire [AXI_S_COUNT-1:0] bus_axi_arready_w;
  wire [AXI_S_COUNT*`XLEN-1:0] bus_axi_araddr_w;
  wire [AXI_S_COUNT*`STRB_W-1:0] bus_axi_arstrb_w;
  wire [AXI_S_COUNT-1:0] bus_axi_aruser_w;
  wire [AXI_S_COUNT-1:0] bus_axi_rvalid_w;
  wire [AXI_S_COUNT-1:0] bus_axi_rready_w;
  wire [AXI_S_COUNT*`XLEN-1:0] bus_axi_rdata_w;
  wire [AXI_S_COUNT*2-1:0] bus_axi_rresp_w;
  wire [AXI_S_COUNT-1:0] bus_axi_awvalid_w;
  wire [AXI_S_COUNT-1:0] bus_axi_awready_w;
  wire [AXI_S_COUNT*`XLEN-1:0] bus_axi_awaddr_w;
  wire [AXI_S_COUNT-1:0] bus_axi_wvalid_w;
  wire [AXI_S_COUNT-1:0] bus_axi_wready_w;
  wire [AXI_S_COUNT*`XLEN-1:0] bus_axi_wdata_w;
  wire [AXI_S_COUNT*`STRB_W-1:0] bus_axi_wstrb_w;
  wire [AXI_S_COUNT-1:0] bus_axi_bvalid_w;
  wire [AXI_S_COUNT-1:0] bus_axi_bready_w;
  wire [AXI_S_COUNT*2-1:0] bus_axi_bresp_w;

  wire [63:0] clint_mtime_w;
  wire clint_msip_irq_w;
  wire clint_mtip_irq_w;
  wire plic_external_irq_w;
  wire uart_irq_w;
  wire [31:0] plic_sources_w;
  wire [`XLEN * `REG_NUM - 1:0] core_debug_gprs_w;

  NpcCoreTop u_core (
    .clk(clk),
    .rst(rst),
    .ifu_axi_arvalid_o(ifu_axi_arvalid_w),
    .ifu_axi_arready_i(ifu_axi_arready_w),
    .ifu_axi_araddr_o(ifu_axi_araddr_w),
    .ifu_axi_rvalid_i(ifu_axi_rvalid_w),
    .ifu_axi_rready_o(ifu_axi_rready_w),
    .ifu_axi_rdata_i(ifu_axi_rdata_w),
    .ifu_axi_rresp_i(ifu_axi_rresp_w),
    .ifu_axi_awvalid_o(ifu_axi_awvalid_w),
    .ifu_axi_awready_i(ifu_axi_awready_w),
    .ifu_axi_awaddr_o(ifu_axi_awaddr_w),
    .ifu_axi_wvalid_o(ifu_axi_wvalid_w),
    .ifu_axi_wready_i(ifu_axi_wready_w),
    .ifu_axi_wdata_o(ifu_axi_wdata_w),
    .ifu_axi_wstrb_o(ifu_axi_wstrb_w),
    .ifu_axi_bvalid_i(ifu_axi_bvalid_w),
    .ifu_axi_bready_o(ifu_axi_bready_w),
    .ifu_axi_bresp_i(ifu_axi_bresp_w),
    .lsu_axi_arvalid_o(lsu_axi_arvalid_w),
    .lsu_axi_arready_i(lsu_axi_arready_w),
    .lsu_axi_araddr_o(lsu_axi_araddr_w),
    .lsu_axi_arstrb_o(lsu_axi_arstrb_w),
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
    .irq_software_i(clint_msip_irq_w),
    .irq_timer_i(clint_mtip_irq_w),
    .irq_external_i(plic_external_irq_w),
    .mtime_i(clint_mtime_w),
    .commit0_valid_o(commit0_valid_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_rd_addr_o(commit0_rd_addr_o),
    .commit0_rd_data_o(commit0_rd_data_o),
    .commit0_exception_o(commit0_exception_o),
    .commit0_write_o(commit0_write_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_pc_o(commit1_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_rd_addr_o(commit1_rd_addr_o),
    .commit1_rd_data_o(commit1_rd_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_write_o(commit1_write_o),
    .trap_valid_o(trap_valid_o),
    .trap_cause_o(trap_cause_o),
    .trap_pc_o(trap_pc_o),
    .trap_tval_o(trap_tval_o),
    .exit_valid_o(exit_valid_o),
    .exit_is_ecall_o(exit_is_ecall_o),
    .exit_is_ebreak_o(exit_is_ebreak_o),
    .exit_code_o(exit_code_o),
    .exit_pc_o(exit_pc_o),
    .halted_o(halted_o),
    .debug_pc_o(debug_pc_o),
    .debug_state_o(debug_state_o),
    .debug_gprs_o(core_debug_gprs_w),
    .retire_count_o(retire_count_o),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
    .issue_count_o(issue_count_o)
  );

  wire unused_core_status_w =
      halted_o | commit0_write_o | commit1_write_o |
      (|core_debug_gprs_w) | (|retire_count_o) |
      (|free_count_o) | (|rob_count_o) | (|issue_count_o);

  NpcAxiBus #(
    .S_COUNT(AXI_S_COUNT),
    .DEFAULT_SLAVE(AXI_S_DEFAULT_PARAM),
    .SLAVE_BASE({`NPC_AXI_DEFAULT_BASE, `NPC_AXI_CHIPLINK_MEM_BASE,
                 `NPC_AXI_SDRAM_BASE, `NPC_AXI_LEGACY_MMIO_BASE,
                 `NPC_AXI_PSRAM_BASE, `NPC_AXI_CHIPLINK_MMIO_BASE,
                 `NPC_AXI_FLASH_BASE, `NPC_AXI_VGA_BASE,
                 `NPC_AXI_MROM_BASE, `NPC_AXI_PS2_BASE,
                 `NPC_AXI_GPIO_BASE, `NPC_AXI_VIRTIO_BLK_BASE,
                 `NPC_AXI_UART_BASE, `NPC_AXI_SRAM_BASE,
                 `NPC_AXI_PLIC_BASE,
                 `NPC_AXI_CLINT_BASE}),
    .SLAVE_MASK({`NPC_AXI_DEFAULT_MASK, `NPC_AXI_CHIPLINK_MEM_MASK,
                 `NPC_AXI_SDRAM_MASK, `NPC_AXI_LEGACY_MMIO_MASK,
                 `NPC_AXI_PSRAM_MASK, `NPC_AXI_CHIPLINK_MMIO_MASK,
                 `NPC_AXI_FLASH_MASK, `NPC_AXI_VGA_MASK,
                 `NPC_AXI_MROM_MASK, `NPC_AXI_PS2_MASK,
                 `NPC_AXI_GPIO_MASK, `NPC_AXI_VIRTIO_BLK_MASK,
                 `NPC_AXI_UART_MASK, `NPC_AXI_SRAM_MASK,
                 `NPC_AXI_PLIC_MASK,
                 `NPC_AXI_CLINT_MASK})
  ) u_bus (
    .clk(clk),
    .rst(rst),
    .ifu_axi_arvalid_i(ifu_axi_arvalid_w),
    .ifu_axi_arready_o(ifu_axi_arready_w),
    .ifu_axi_araddr_i(ifu_axi_araddr_w),
    .ifu_axi_rvalid_o(ifu_axi_rvalid_w),
    .ifu_axi_rready_i(ifu_axi_rready_w),
    .ifu_axi_rdata_o(ifu_axi_rdata_w),
    .ifu_axi_rresp_o(ifu_axi_rresp_w),
    .ifu_axi_awvalid_i(ifu_axi_awvalid_w),
    .ifu_axi_awready_o(ifu_axi_awready_w),
    .ifu_axi_awaddr_i(ifu_axi_awaddr_w),
    .ifu_axi_wvalid_i(ifu_axi_wvalid_w),
    .ifu_axi_wready_o(ifu_axi_wready_w),
    .ifu_axi_wdata_i(ifu_axi_wdata_w),
    .ifu_axi_wstrb_i(ifu_axi_wstrb_w),
    .ifu_axi_bvalid_o(ifu_axi_bvalid_w),
    .ifu_axi_bready_i(ifu_axi_bready_w),
    .ifu_axi_bresp_o(ifu_axi_bresp_w),
    .lsu_axi_arvalid_i(lsu_axi_arvalid_w),
    .lsu_axi_arready_o(lsu_axi_arready_w),
    .lsu_axi_araddr_i(lsu_axi_araddr_w),
    .lsu_axi_arstrb_i(lsu_axi_arstrb_w),
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
    .s_axi_arvalid_o(bus_axi_arvalid_w),
    .s_axi_arready_i(bus_axi_arready_w),
    .s_axi_araddr_o(bus_axi_araddr_w),
    .s_axi_arstrb_o(bus_axi_arstrb_w),
    .s_axi_aruser_o(bus_axi_aruser_w),
    .s_axi_rvalid_i(bus_axi_rvalid_w),
    .s_axi_rready_o(bus_axi_rready_w),
    .s_axi_rdata_i(bus_axi_rdata_w),
    .s_axi_rresp_i(bus_axi_rresp_w),
    .s_axi_awvalid_o(bus_axi_awvalid_w),
    .s_axi_awready_i(bus_axi_awready_w),
    .s_axi_awaddr_o(bus_axi_awaddr_w),
    .s_axi_wvalid_o(bus_axi_wvalid_w),
    .s_axi_wready_i(bus_axi_wready_w),
    .s_axi_wdata_o(bus_axi_wdata_w),
    .s_axi_wstrb_o(bus_axi_wstrb_w),
    .s_axi_bvalid_i(bus_axi_bvalid_w),
    .s_axi_bready_o(bus_axi_bready_w),
    .s_axi_bresp_i(bus_axi_bresp_w)
  );

  AxiLiteToUart #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W)
  ) u_uart_axi (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(bus_axi_arvalid_w[AXI_S_UART]),
    .s_axi_arready_o(bus_axi_arready_w[AXI_S_UART]),
    .s_axi_araddr_i(bus_axi_araddr_w[AXI_S_UART*`XLEN +: `XLEN]),
    .s_axi_arstrb_i(bus_axi_arstrb_w[AXI_S_UART*`STRB_W +: `STRB_W]),
    .s_axi_rvalid_o(bus_axi_rvalid_w[AXI_S_UART]),
    .s_axi_rready_i(bus_axi_rready_w[AXI_S_UART]),
    .s_axi_rdata_o(bus_axi_rdata_w[AXI_S_UART*`XLEN +: `XLEN]),
    .s_axi_rresp_o(bus_axi_rresp_w[AXI_S_UART*2 +: 2]),
    .s_axi_awvalid_i(bus_axi_awvalid_w[AXI_S_UART]),
    .s_axi_awready_o(bus_axi_awready_w[AXI_S_UART]),
    .s_axi_awaddr_i(bus_axi_awaddr_w[AXI_S_UART*`XLEN +: `XLEN]),
    .s_axi_wvalid_i(bus_axi_wvalid_w[AXI_S_UART]),
    .s_axi_wready_o(bus_axi_wready_w[AXI_S_UART]),
    .s_axi_wdata_i(bus_axi_wdata_w[AXI_S_UART*`XLEN +: `XLEN]),
    .s_axi_wstrb_i(bus_axi_wstrb_w[AXI_S_UART*`STRB_W +: `STRB_W]),
    .s_axi_bvalid_o(bus_axi_bvalid_w[AXI_S_UART]),
    .s_axi_bready_i(bus_axi_bready_w[AXI_S_UART]),
    .s_axi_bresp_o(bus_axi_bresp_w[AXI_S_UART*2 +: 2]),
    .uart_tx_valid_o(uart_tx_valid_o),
    .uart_tx_data_o(uart_tx_data_o),
    .uart_access_valid_o(uart_access_valid_o),
    .uart_access_write_o(uart_access_write_o),
    .uart_access_addr_o(uart_access_addr_o),
    .uart_access_wdata_o(uart_access_wdata_o),
    .uart_access_wstrb_o(uart_access_wstrb_o),
    .uart_access_rdata_o(uart_access_rdata_o),
    .uart_rx_valid_i(uart_rx_valid_i),
    .uart_rx_data_i(uart_rx_data_i),
    .uart_rx_ready_o(uart_rx_ready_o),
    .uart_irq_o(uart_irq_w)
  );

  AxiLiteClint #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W),
    .MTIME_DIVISOR(CLINT_MTIME_DIVISOR)
  ) u_clint_axi (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(bus_axi_arvalid_w[AXI_S_CLINT]),
    .s_axi_arready_o(bus_axi_arready_w[AXI_S_CLINT]),
    .s_axi_araddr_i(bus_axi_araddr_w[AXI_S_CLINT*`XLEN +: `XLEN]),
    .s_axi_rvalid_o(bus_axi_rvalid_w[AXI_S_CLINT]),
    .s_axi_rready_i(bus_axi_rready_w[AXI_S_CLINT]),
    .s_axi_rdata_o(bus_axi_rdata_w[AXI_S_CLINT*`XLEN +: `XLEN]),
    .s_axi_rresp_o(bus_axi_rresp_w[AXI_S_CLINT*2 +: 2]),
    .s_axi_awvalid_i(bus_axi_awvalid_w[AXI_S_CLINT]),
    .s_axi_awready_o(bus_axi_awready_w[AXI_S_CLINT]),
    .s_axi_awaddr_i(bus_axi_awaddr_w[AXI_S_CLINT*`XLEN +: `XLEN]),
    .s_axi_wvalid_i(bus_axi_wvalid_w[AXI_S_CLINT]),
    .s_axi_wready_o(bus_axi_wready_w[AXI_S_CLINT]),
    .s_axi_wdata_i(bus_axi_wdata_w[AXI_S_CLINT*`XLEN +: `XLEN]),
    .s_axi_wstrb_i(bus_axi_wstrb_w[AXI_S_CLINT*`STRB_W +: `STRB_W]),
    .s_axi_bvalid_o(bus_axi_bvalid_w[AXI_S_CLINT]),
    .s_axi_bready_i(bus_axi_bready_w[AXI_S_CLINT]),
    .s_axi_bresp_o(bus_axi_bresp_w[AXI_S_CLINT*2 +: 2]),
    .mtime_o(clint_mtime_w),
    .msip_irq_o(clint_msip_irq_w),
    .mtip_irq_o(clint_mtip_irq_w)
  );

  assign clint_mtime_o = clint_mtime_w;
  assign uart_irq_o = uart_irq_w;
  assign plic_external_irq_o = plic_external_irq_w;
  assign plic_sources_w = {29'd0, virtio_blk_irq_i, uart_irq_w, 1'b0};

  AxiLitePlic #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W),
    .SOURCE_NUM(32)
  ) u_plic_axi (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(bus_axi_arvalid_w[AXI_S_PLIC]),
    .s_axi_arready_o(bus_axi_arready_w[AXI_S_PLIC]),
    .s_axi_araddr_i(bus_axi_araddr_w[AXI_S_PLIC*`XLEN +: `XLEN]),
    .s_axi_rvalid_o(bus_axi_rvalid_w[AXI_S_PLIC]),
    .s_axi_rready_i(bus_axi_rready_w[AXI_S_PLIC]),
    .s_axi_rdata_o(bus_axi_rdata_w[AXI_S_PLIC*`XLEN +: `XLEN]),
    .s_axi_rresp_o(bus_axi_rresp_w[AXI_S_PLIC*2 +: 2]),
    .s_axi_awvalid_i(bus_axi_awvalid_w[AXI_S_PLIC]),
    .s_axi_awready_o(bus_axi_awready_w[AXI_S_PLIC]),
    .s_axi_awaddr_i(bus_axi_awaddr_w[AXI_S_PLIC*`XLEN +: `XLEN]),
    .s_axi_wvalid_i(bus_axi_wvalid_w[AXI_S_PLIC]),
    .s_axi_wready_o(bus_axi_wready_w[AXI_S_PLIC]),
    .s_axi_wdata_i(bus_axi_wdata_w[AXI_S_PLIC*`XLEN +: `XLEN]),
    .s_axi_wstrb_i(bus_axi_wstrb_w[AXI_S_PLIC*`STRB_W +: `STRB_W]),
    .s_axi_bvalid_o(bus_axi_bvalid_w[AXI_S_PLIC]),
    .s_axi_bready_i(bus_axi_bready_w[AXI_S_PLIC]),
    .s_axi_bresp_o(bus_axi_bresp_w[AXI_S_PLIC*2 +: 2]),
    .source_irq_i(plic_sources_w),
    .external_irq_o(plic_external_irq_w)
  );

  assign psram_axi_arvalid_o = bus_axi_arvalid_w[AXI_S_PSRAM];
  assign bus_axi_arready_w[AXI_S_PSRAM] = psram_axi_arready_i;
  assign psram_axi_araddr_o = bus_axi_araddr_w[AXI_S_PSRAM*`XLEN +: `XLEN];
  assign psram_axi_aruser_o = bus_axi_aruser_w[AXI_S_PSRAM];
  assign bus_axi_rvalid_w[AXI_S_PSRAM] = psram_axi_rvalid_i;
  assign psram_axi_rready_o = bus_axi_rready_w[AXI_S_PSRAM];
  assign bus_axi_rdata_w[AXI_S_PSRAM*`XLEN +: `XLEN] = psram_axi_rdata_i;
  assign bus_axi_rresp_w[AXI_S_PSRAM*2 +: 2] = psram_axi_rresp_i;
  assign psram_axi_awvalid_o = bus_axi_awvalid_w[AXI_S_PSRAM];
  assign bus_axi_awready_w[AXI_S_PSRAM] = psram_axi_awready_i;
  assign psram_axi_awaddr_o = bus_axi_awaddr_w[AXI_S_PSRAM*`XLEN +: `XLEN];
  assign psram_axi_wvalid_o = bus_axi_wvalid_w[AXI_S_PSRAM];
  assign bus_axi_wready_w[AXI_S_PSRAM] = psram_axi_wready_i;
  assign psram_axi_wdata_o = bus_axi_wdata_w[AXI_S_PSRAM*`XLEN +: `XLEN];
  assign psram_axi_wstrb_o = bus_axi_wstrb_w[AXI_S_PSRAM*`STRB_W +: `STRB_W];
  assign bus_axi_bvalid_w[AXI_S_PSRAM] = psram_axi_bvalid_i;
  assign psram_axi_bready_o = bus_axi_bready_w[AXI_S_PSRAM];
  assign bus_axi_bresp_w[AXI_S_PSRAM*2 +: 2] = psram_axi_bresp_i;

  assign sdram_axi_arvalid_o = bus_axi_arvalid_w[AXI_S_SDRAM];
  assign bus_axi_arready_w[AXI_S_SDRAM] = sdram_axi_arready_i;
  assign sdram_axi_araddr_o =
      bus_axi_araddr_w[AXI_S_SDRAM*`XLEN +: `XLEN];
  assign sdram_axi_aruser_o = bus_axi_aruser_w[AXI_S_SDRAM];
  assign bus_axi_rvalid_w[AXI_S_SDRAM] = sdram_axi_rvalid_i;
  assign sdram_axi_rready_o = bus_axi_rready_w[AXI_S_SDRAM];
  assign bus_axi_rdata_w[AXI_S_SDRAM*`XLEN +: `XLEN] = sdram_axi_rdata_i;
  assign bus_axi_rresp_w[AXI_S_SDRAM*2 +: 2] = sdram_axi_rresp_i;
  assign sdram_axi_awvalid_o = bus_axi_awvalid_w[AXI_S_SDRAM];
  assign bus_axi_awready_w[AXI_S_SDRAM] = sdram_axi_awready_i;
  assign sdram_axi_awaddr_o =
      bus_axi_awaddr_w[AXI_S_SDRAM*`XLEN +: `XLEN];
  assign sdram_axi_wvalid_o = bus_axi_wvalid_w[AXI_S_SDRAM];
  assign bus_axi_wready_w[AXI_S_SDRAM] = sdram_axi_wready_i;
  assign sdram_axi_wdata_o = bus_axi_wdata_w[AXI_S_SDRAM*`XLEN +: `XLEN];
  assign sdram_axi_wstrb_o =
      bus_axi_wstrb_w[AXI_S_SDRAM*`STRB_W +: `STRB_W];
  assign bus_axi_bvalid_w[AXI_S_SDRAM] = sdram_axi_bvalid_i;
  assign sdram_axi_bready_o = bus_axi_bready_w[AXI_S_SDRAM];
  assign bus_axi_bresp_w[AXI_S_SDRAM*2 +: 2] = sdram_axi_bresp_i;

  assign legacy_mmio_axi_arvalid_o = bus_axi_arvalid_w[AXI_S_LEGACY_MMIO];
  assign bus_axi_arready_w[AXI_S_LEGACY_MMIO] = legacy_mmio_axi_arready_i;
  assign legacy_mmio_axi_araddr_o =
      bus_axi_araddr_w[AXI_S_LEGACY_MMIO*`XLEN +: `XLEN];
  assign legacy_mmio_axi_aruser_o = bus_axi_aruser_w[AXI_S_LEGACY_MMIO];
  assign bus_axi_rvalid_w[AXI_S_LEGACY_MMIO] = legacy_mmio_axi_rvalid_i;
  assign legacy_mmio_axi_rready_o = bus_axi_rready_w[AXI_S_LEGACY_MMIO];
  assign bus_axi_rdata_w[AXI_S_LEGACY_MMIO*`XLEN +: `XLEN] =
      legacy_mmio_axi_rdata_i;
  assign bus_axi_rresp_w[AXI_S_LEGACY_MMIO*2 +: 2] =
      legacy_mmio_axi_rresp_i;
  assign legacy_mmio_axi_awvalid_o = bus_axi_awvalid_w[AXI_S_LEGACY_MMIO];
  assign bus_axi_awready_w[AXI_S_LEGACY_MMIO] = legacy_mmio_axi_awready_i;
  assign legacy_mmio_axi_awaddr_o =
      bus_axi_awaddr_w[AXI_S_LEGACY_MMIO*`XLEN +: `XLEN];
  assign legacy_mmio_axi_wvalid_o = bus_axi_wvalid_w[AXI_S_LEGACY_MMIO];
  assign bus_axi_wready_w[AXI_S_LEGACY_MMIO] = legacy_mmio_axi_wready_i;
  assign legacy_mmio_axi_wdata_o =
      bus_axi_wdata_w[AXI_S_LEGACY_MMIO*`XLEN +: `XLEN];
  assign legacy_mmio_axi_wstrb_o =
      bus_axi_wstrb_w[AXI_S_LEGACY_MMIO*`STRB_W +: `STRB_W];
  assign bus_axi_bvalid_w[AXI_S_LEGACY_MMIO] = legacy_mmio_axi_bvalid_i;
  assign legacy_mmio_axi_bready_o = bus_axi_bready_w[AXI_S_LEGACY_MMIO];
  assign bus_axi_bresp_w[AXI_S_LEGACY_MMIO*2 +: 2] =
      legacy_mmio_axi_bresp_i;

  assign virtio_blk_axi_arvalid_o = bus_axi_arvalid_w[AXI_S_VIRTIO_BLK];
  assign bus_axi_arready_w[AXI_S_VIRTIO_BLK] = virtio_blk_axi_arready_i;
  assign virtio_blk_axi_araddr_o =
      bus_axi_araddr_w[AXI_S_VIRTIO_BLK*`XLEN +: `XLEN];
  assign virtio_blk_axi_aruser_o = bus_axi_aruser_w[AXI_S_VIRTIO_BLK];
  assign bus_axi_rvalid_w[AXI_S_VIRTIO_BLK] = virtio_blk_axi_rvalid_i;
  assign virtio_blk_axi_rready_o = bus_axi_rready_w[AXI_S_VIRTIO_BLK];
  assign bus_axi_rdata_w[AXI_S_VIRTIO_BLK*`XLEN +: `XLEN] =
      virtio_blk_axi_rdata_i;
  assign bus_axi_rresp_w[AXI_S_VIRTIO_BLK*2 +: 2] =
      virtio_blk_axi_rresp_i;
  assign virtio_blk_axi_awvalid_o = bus_axi_awvalid_w[AXI_S_VIRTIO_BLK];
  assign bus_axi_awready_w[AXI_S_VIRTIO_BLK] = virtio_blk_axi_awready_i;
  assign virtio_blk_axi_awaddr_o =
      bus_axi_awaddr_w[AXI_S_VIRTIO_BLK*`XLEN +: `XLEN];
  assign virtio_blk_axi_wvalid_o = bus_axi_wvalid_w[AXI_S_VIRTIO_BLK];
  assign bus_axi_wready_w[AXI_S_VIRTIO_BLK] = virtio_blk_axi_wready_i;
  assign virtio_blk_axi_wdata_o =
      bus_axi_wdata_w[AXI_S_VIRTIO_BLK*`XLEN +: `XLEN];
  assign virtio_blk_axi_wstrb_o =
      bus_axi_wstrb_w[AXI_S_VIRTIO_BLK*`STRB_W +: `STRB_W];
  assign bus_axi_bvalid_w[AXI_S_VIRTIO_BLK] = virtio_blk_axi_bvalid_i;
  assign virtio_blk_axi_bready_o = bus_axi_bready_w[AXI_S_VIRTIO_BLK];
  assign bus_axi_bresp_w[AXI_S_VIRTIO_BLK*2 +: 2] =
      virtio_blk_axi_bresp_i;

  genvar stub_idx;
  generate
    for (stub_idx = 0; stub_idx < AXI_S_COUNT; stub_idx = stub_idx + 1) begin : gen_device_stub
      if (AXI_S_STUB_MASK[stub_idx]) begin : g
        AxiDefaultSlave #(
          .DATA_W(`XLEN)
        ) u_stub (
          .clk(clk),
          .rst(rst),
          .s_axi_arvalid_i(bus_axi_arvalid_w[stub_idx]),
          .s_axi_arready_o(bus_axi_arready_w[stub_idx]),
          .s_axi_rvalid_o(bus_axi_rvalid_w[stub_idx]),
          .s_axi_rready_i(bus_axi_rready_w[stub_idx]),
          .s_axi_rdata_o(bus_axi_rdata_w[stub_idx*`XLEN +: `XLEN]),
          .s_axi_rresp_o(bus_axi_rresp_w[stub_idx*2 +: 2]),
          .s_axi_awvalid_i(bus_axi_awvalid_w[stub_idx]),
          .s_axi_awready_o(bus_axi_awready_w[stub_idx]),
          .s_axi_wvalid_i(bus_axi_wvalid_w[stub_idx]),
          .s_axi_wready_o(bus_axi_wready_w[stub_idx]),
          .s_axi_bvalid_o(bus_axi_bvalid_w[stub_idx]),
          .s_axi_bready_i(bus_axi_bready_w[stub_idx]),
          .s_axi_bresp_o(bus_axi_bresp_w[stub_idx*2 +: 2])
        );
        wire unused_stub_payload_w = |{
            bus_axi_araddr_w[stub_idx*`XLEN +: `XLEN],
            bus_axi_aruser_w[stub_idx],
            bus_axi_awaddr_w[stub_idx*`XLEN +: `XLEN],
            bus_axi_wdata_w[stub_idx*`XLEN +: `XLEN],
            bus_axi_wstrb_w[stub_idx*`STRB_W +: `STRB_W]
        };
      end
    end
  endgenerate

endmodule
