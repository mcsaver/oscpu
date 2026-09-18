`include "define.v"

// DPI-C 仿真顶层：只负责把可综合 NpcCore 接到独立总线和宿主侧事件模型。
// 该文件不能进入 RTL_CORE_SRCS/STA_RTL_FILES。
import "DPI-C" task npc_cache_flush_all();

import "DPI-C" function void npc_commit_event(
  input int unsigned pc,
  input int unsigned inst,
  input int unsigned next_pc,
  input int unsigned rd_en,
  input int unsigned rd_addr,
  input int unsigned rd_data
);

import "DPI-C" function void npc_exit_event(
  input int unsigned is_ebreak,
  input int unsigned is_ecall,
  input int unsigned code,
  input int unsigned pc
);

import "DPI-C" function void npc_trap_event(
  input int unsigned cause,
  input int unsigned pc,
  input int unsigned tval
);

import "DPI-C" function void npc_control_flow_event(
  input int unsigned is_branch,
  input int unsigned branch_taken,
  input int unsigned is_jal,
  input int unsigned is_jalr
);

import "DPI-C" function void npc_bpu_lookup_event(
  input int unsigned is_branch,
  input int unsigned is_jalr,
  input int unsigned is_ret,
  input int unsigned btb_hit,
  input int unsigned bht_valid,
  input int unsigned ras_lookup,
  input int unsigned ras_hit,
  input int unsigned ras_overflow
);

import "DPI-C" function void npc_bpu_resolve_event(
  input int unsigned is_branch,
  input int unsigned pc,
  input int unsigned is_jal,
  input int unsigned is_jalr,
  input int unsigned is_ret,
  input int unsigned pred_taken,
  input int unsigned actual_taken,
  input int unsigned correct
);

import "DPI-C" function void npc_icache_event(
  input int unsigned access,
  input int unsigned hit,
  input int unsigned miss
);

import "DPI-C" function void npc_dcache_event(
  input int unsigned access,
  input int unsigned hit,
  input int unsigned miss,
  input int unsigned writeback,
  input int unsigned write_through,
  input int unsigned is_store
);

import "DPI-C" function void npc_ooo_cycle_event(
  input int unsigned retire_count,
  input int unsigned execute_count,
  input int unsigned dispatch_count,
  input int unsigned fetch_req_valid,
  input int unsigned fetch_req_fire,
  input int unsigned fetch_rsp_fire,
  input int unsigned fetch_rsp_enqueue,
  input int unsigned fetch_rsp_bypass,
  input int unsigned stop_pending,
  input int unsigned pending_branch,
  input int unsigned pending_jump,
  input int unsigned pending_mem,
  input int unsigned synth_ret_pending,
  input int unsigned branch_prefetch_fire,
  input int unsigned branch_prefetch_hit,
  input int unsigned mem0_req_fire,
  input int unsigned mem1_req_fire,
  input int unsigned mem0_rsp_fire,
  input int unsigned mem1_rsp_fire,
  input int unsigned commit1_block
);

import "DPI-C" function void npc_uart_event(
  input int unsigned is_write,
  input int unsigned tx_valid,
  input int unsigned tx_data
);

module NpcSimTop (
  input logic clk,
  input logic rst,

  output logic [`XLEN-1:0] debug_pc_o,
  output logic [`CORE_STATE_W-1:0] debug_state_o,
  output logic [63:0] debug_clint_mtime_o
);

  localparam [3:0] AXI_S_CLINT = 4'd0;
  localparam [3:0] AXI_S_SRAM = 4'd1;
  localparam [3:0] AXI_S_UART = 4'd2;
  localparam [3:0] AXI_S_SPI = 4'd3;
  localparam [3:0] AXI_S_GPIO = 4'd4;
  localparam [3:0] AXI_S_PS2 = 4'd5;
  localparam [3:0] AXI_S_MROM = 4'd6;
  localparam [3:0] AXI_S_VGA = 4'd7;
  localparam [3:0] AXI_S_FLASH = 4'd8;
  localparam [3:0] AXI_S_CHIPLINK_MMIO = 4'd9;
  localparam [3:0] AXI_S_PSRAM = 4'd10;
  // 当前 AM/NEMU 兼容设备仍走 legacy DPI；严格 SoC 模式迁移后可删除这个覆盖窗口。
  localparam [3:0] AXI_S_LEGACY_MMIO = 4'd11;
  localparam [3:0] AXI_S_SDRAM = 4'd12;
  localparam [3:0] AXI_S_CHIPLINK_MEM = 4'd13;
  localparam [3:0] AXI_S_DEFAULT = 4'd14;
  localparam int AXI_S_DEFAULT_PARAM = 14;
  localparam int AXI_S_COUNT = 15;

  function automatic logic [AXI_S_COUNT-1:0] axi_slave_bit(input [3:0] idx);
    begin
      axi_slave_bit = {AXI_S_COUNT{1'b0}};
      axi_slave_bit[idx] = 1'b1;
    end
  endfunction

  localparam logic [AXI_S_COUNT-1:0] AXI_S_STUB_MASK =
      axi_slave_bit(AXI_S_SRAM) |
      axi_slave_bit(AXI_S_SPI) |
      axi_slave_bit(AXI_S_GPIO) |
      axi_slave_bit(AXI_S_PS2) |
      axi_slave_bit(AXI_S_MROM) |
      axi_slave_bit(AXI_S_VGA) |
      axi_slave_bit(AXI_S_FLASH) |
      axi_slave_bit(AXI_S_CHIPLINK_MMIO) |
      axi_slave_bit(AXI_S_SDRAM) |
      axi_slave_bit(AXI_S_CHIPLINK_MEM) |
      axi_slave_bit(AXI_S_DEFAULT);

  logic ifu_axi_arvalid_w;
  logic ifu_axi_arready_w;
  logic [`XLEN-1:0] ifu_axi_araddr_w;
  logic ifu_axi_rvalid_w;
  logic ifu_axi_rready_w;
  logic [`XLEN-1:0] ifu_axi_rdata_w;
  logic [1:0] ifu_axi_rresp_w;

  logic lsu_axi_arvalid_w;
  logic lsu_axi_arready_w;
  logic [`XLEN-1:0] lsu_axi_araddr_w;
  logic lsu_axi_rvalid_w;
  logic lsu_axi_rready_w;
  logic [`XLEN-1:0] lsu_axi_rdata_w;
  logic [1:0] lsu_axi_rresp_w;
  logic lsu_axi_awvalid_w;
  logic lsu_axi_awready_w;
  logic [`XLEN-1:0] lsu_axi_awaddr_w;
  logic lsu_axi_wvalid_w;
  logic lsu_axi_wready_w;
  logic [`XLEN-1:0] lsu_axi_wdata_w;
  logic [3:0] lsu_axi_wstrb_w;
  logic lsu_axi_bvalid_w;
  logic lsu_axi_bready_w;
  logic [1:0] lsu_axi_bresp_w;
  logic [AXI_S_COUNT-1:0] bus_axi_arvalid_w;
  logic [AXI_S_COUNT-1:0] bus_axi_arready_w;
  logic [AXI_S_COUNT*`XLEN-1:0] bus_axi_araddr_w;
  logic [AXI_S_COUNT-1:0] bus_axi_aruser_w;
  logic [AXI_S_COUNT-1:0] bus_axi_rvalid_w;
  logic [AXI_S_COUNT-1:0] bus_axi_rready_w;
  logic [AXI_S_COUNT*`XLEN-1:0] bus_axi_rdata_w;
  logic [AXI_S_COUNT*2-1:0] bus_axi_rresp_w;
  logic [AXI_S_COUNT-1:0] bus_axi_awvalid_w;
  logic [AXI_S_COUNT-1:0] bus_axi_awready_w;
  logic [AXI_S_COUNT*`XLEN-1:0] bus_axi_awaddr_w;
  logic [AXI_S_COUNT-1:0] bus_axi_wvalid_w;
  logic [AXI_S_COUNT-1:0] bus_axi_wready_w;
  logic [AXI_S_COUNT*`XLEN-1:0] bus_axi_wdata_w;
  logic [AXI_S_COUNT*4-1:0] bus_axi_wstrb_w;
  logic [AXI_S_COUNT-1:0] bus_axi_bvalid_w;
  logic [AXI_S_COUNT-1:0] bus_axi_bready_w;
  logic [AXI_S_COUNT*2-1:0] bus_axi_bresp_w;
  logic uart_tx_valid_w;
  logic [7:0] uart_tx_data_w;
  logic uart_access_valid_w;
  logic uart_access_write_w;
  logic [63:0] clint_mtime_w;
  logic clint_msip_irq_w;
  logic clint_mtip_irq_w;
  logic sim_cache_flush_w;
  logic sim_icache_access_w;
  logic sim_icache_hit_w;
  logic sim_icache_miss_w;
  logic sim_dcache_access_w;
  logic sim_dcache_hit_w;
  logic sim_dcache_miss_w;
  logic sim_dcache_store_access_w;
  logic sim_dcache_writeback_w;
  logic sim_dcache_write_through_w;
  logic sim_control_event_w;
  logic sim_bpu_lookup_event_w;
  logic sim_bpu_ret_resolve_w;
  logic sim_bpu_pred_taken_w;
  logic sim_bpu_resolve_correct_w;
  logic exit_reported_q;
  logic ifu_axi_abort_w;

  function automatic logic sim_is_link_reg(input logic [4:0] reg_idx);
    begin
      sim_is_link_reg = (reg_idx == 5'd1) || (reg_idx == 5'd5);
    end
  endfunction

  logic core_commit0_valid_w;
  logic [`XLEN-1:0] core_commit0_pc_w;
  logic [`INST_W-1:0] core_commit0_inst_w;
  logic [`XLEN-1:0] core_commit0_next_pc_w;
  logic core_commit0_rd_en_w;
  logic [`REG_ADDR_W-1:0] core_commit0_rd_addr_w;
  logic [`XLEN-1:0] core_commit0_rd_data_w;
  logic core_commit0_exception_w;
  logic core_commit0_write_w;
  logic core_commit1_valid_w;
  logic [`XLEN-1:0] core_commit1_pc_w;
  logic [`INST_W-1:0] core_commit1_inst_w;
  logic [`XLEN-1:0] core_commit1_next_pc_w;
  logic core_commit1_rd_en_w;
  logic [`REG_ADDR_W-1:0] core_commit1_rd_addr_w;
  logic [`XLEN-1:0] core_commit1_rd_data_w;
  logic core_commit1_exception_w;
  logic core_commit1_write_w;
  logic core_trap_valid_w;
  logic [`TRAP_CAUSE_W-1:0] core_trap_cause_w;
  logic [`XLEN-1:0] core_trap_pc_w;
  logic [`XLEN-1:0] core_trap_tval_w;
  logic core_exit_valid_w;
  logic core_exit_is_ecall_w;
  logic core_exit_is_ebreak_w;
  logic [`XLEN-1:0] core_exit_code_w;
  logic [`XLEN-1:0] core_exit_pc_w;
  logic core_halted_w;
  logic [`XLEN * `REG_NUM - 1:0] core_debug_gprs_w;
  logic [1:0] core_retire_count_w;
  logic [6:0] core_free_count_w;
  logic [4:0] core_rob_count_w;
  logic [3:0] core_issue_count_w;

  NpcCoreTop u_core (
    .clk(clk),
    .rst(rst),
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
    .irq_software_i(clint_msip_irq_w),
    .irq_timer_i(clint_mtip_irq_w),
    .irq_external_i(1'b0),
    .commit0_valid_o(core_commit0_valid_w),
    .commit0_pc_o(core_commit0_pc_w),
    .commit0_inst_o(core_commit0_inst_w),
    .commit0_next_pc_o(core_commit0_next_pc_w),
    .commit0_rd_en_o(core_commit0_rd_en_w),
    .commit0_rd_addr_o(core_commit0_rd_addr_w),
    .commit0_rd_data_o(core_commit0_rd_data_w),
    .commit0_exception_o(core_commit0_exception_w),
    .commit0_write_o(core_commit0_write_w),
    .commit1_valid_o(core_commit1_valid_w),
    .commit1_pc_o(core_commit1_pc_w),
    .commit1_inst_o(core_commit1_inst_w),
    .commit1_next_pc_o(core_commit1_next_pc_w),
    .commit1_rd_en_o(core_commit1_rd_en_w),
    .commit1_rd_addr_o(core_commit1_rd_addr_w),
    .commit1_rd_data_o(core_commit1_rd_data_w),
    .commit1_exception_o(core_commit1_exception_w),
    .commit1_write_o(core_commit1_write_w),
    .trap_valid_o(core_trap_valid_w),
    .trap_cause_o(core_trap_cause_w),
    .trap_pc_o(core_trap_pc_w),
    .trap_tval_o(core_trap_tval_w),
    .exit_valid_o(core_exit_valid_w),
    .exit_is_ecall_o(core_exit_is_ecall_w),
    .exit_is_ebreak_o(core_exit_is_ebreak_w),
    .exit_code_o(core_exit_code_w),
    .exit_pc_o(core_exit_pc_w),
    .halted_o(core_halted_w),
    .debug_pc_o(debug_pc_o),
    .debug_state_o(debug_state_o),
    .debug_gprs_o(core_debug_gprs_w),
    .retire_count_o(core_retire_count_w),
    .free_count_o(core_free_count_w),
    .rob_count_o(core_rob_count_w),
    .issue_count_o(core_issue_count_w)
  );

  wire unused_core_status_w =
      core_halted_w | core_commit0_write_w | core_commit1_write_w |
      (|core_debug_gprs_w) | (|core_retire_count_w) |
      (|core_free_count_w) | (|core_rob_count_w) | (|core_issue_count_w);

  NpcAxiBus #(
    .S_COUNT(AXI_S_COUNT),
    .DEFAULT_SLAVE(AXI_S_DEFAULT_PARAM),
    // 按 ysyxSoC 表预留 slave 窗口；未实现设备先接 SLVERR stub，避免非法地址静默成功。
    .SLAVE_BASE({`NPC_AXI_DEFAULT_BASE, `NPC_AXI_CHIPLINK_MEM_BASE,
                 `NPC_AXI_SDRAM_BASE, `NPC_AXI_LEGACY_MMIO_BASE,
                 `NPC_AXI_PSRAM_BASE, `NPC_AXI_CHIPLINK_MMIO_BASE,
                 `NPC_AXI_FLASH_BASE, `NPC_AXI_VGA_BASE,
                 `NPC_AXI_MROM_BASE, `NPC_AXI_PS2_BASE,
                 `NPC_AXI_GPIO_BASE, `NPC_AXI_SPI_BASE,
                 `NPC_AXI_UART_BASE, `NPC_AXI_SRAM_BASE,
                 `NPC_AXI_CLINT_BASE}),
    .SLAVE_MASK({`NPC_AXI_DEFAULT_MASK, `NPC_AXI_CHIPLINK_MEM_MASK,
                 `NPC_AXI_SDRAM_MASK, `NPC_AXI_LEGACY_MMIO_MASK,
                 `NPC_AXI_PSRAM_MASK, `NPC_AXI_CHIPLINK_MMIO_MASK,
                 `NPC_AXI_FLASH_MASK, `NPC_AXI_VGA_MASK,
                 `NPC_AXI_MROM_MASK, `NPC_AXI_PS2_MASK,
                 `NPC_AXI_GPIO_MASK, `NPC_AXI_SPI_MASK,
                 `NPC_AXI_UART_MASK, `NPC_AXI_SRAM_MASK,
                 `NPC_AXI_CLINT_MASK})
  ) u_bus (
    .clk(clk),
    .rst(rst),
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
    .s_axi_arvalid_o(bus_axi_arvalid_w),
    .s_axi_arready_i(bus_axi_arready_w),
    .s_axi_araddr_o(bus_axi_araddr_w),
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

  AxiLiteToUart u_uart_axi (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(bus_axi_arvalid_w[AXI_S_UART]),
    .s_axi_arready_o(bus_axi_arready_w[AXI_S_UART]),
    .s_axi_araddr_i(bus_axi_araddr_w[AXI_S_UART*`XLEN +: `XLEN]),
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
    .s_axi_wstrb_i(bus_axi_wstrb_w[AXI_S_UART*4 +: 4]),
    .s_axi_bvalid_o(bus_axi_bvalid_w[AXI_S_UART]),
    .s_axi_bready_i(bus_axi_bready_w[AXI_S_UART]),
    .s_axi_bresp_o(bus_axi_bresp_w[AXI_S_UART*2 +: 2]),
    .uart_tx_valid_o(uart_tx_valid_w),
    .uart_tx_data_o(uart_tx_data_w),
    .uart_access_valid_o(uart_access_valid_w),
    .uart_access_write_o(uart_access_write_w)
  );

  AxiLiteClint u_clint_axi (
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
    .s_axi_wstrb_i(bus_axi_wstrb_w[AXI_S_CLINT*4 +: 4]),
    .s_axi_bvalid_o(bus_axi_bvalid_w[AXI_S_CLINT]),
    .s_axi_bready_i(bus_axi_bready_w[AXI_S_CLINT]),
    .s_axi_bresp_o(bus_axi_bresp_w[AXI_S_CLINT*2 +: 2]),
    .mtime_o(clint_mtime_w),
    .msip_irq_o(clint_msip_irq_w),
    .mtip_irq_o(clint_mtip_irq_w)
  );
  wire unused_clint_mtime_w = |clint_mtime_w;
  // 仿真统计需要观察 CLINT 内部计时器；层次化引用避免把调试口并入可综合 core ABI。
  assign debug_clint_mtime_o = u_clint_axi.mtime_q;

  AxiDpiSlave u_psram_slave (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(bus_axi_arvalid_w[AXI_S_PSRAM]),
    .s_axi_arready_o(bus_axi_arready_w[AXI_S_PSRAM]),
    .s_axi_araddr_i(bus_axi_araddr_w[AXI_S_PSRAM*`XLEN +: `XLEN]),
    .s_axi_aruser_i(bus_axi_aruser_w[AXI_S_PSRAM]),
    .s_axi_rvalid_o(bus_axi_rvalid_w[AXI_S_PSRAM]),
    .s_axi_rready_i(bus_axi_rready_w[AXI_S_PSRAM]),
    .s_axi_rdata_o(bus_axi_rdata_w[AXI_S_PSRAM*`XLEN +: `XLEN]),
    .s_axi_rresp_o(bus_axi_rresp_w[AXI_S_PSRAM*2 +: 2]),
    .s_axi_awvalid_i(bus_axi_awvalid_w[AXI_S_PSRAM]),
    .s_axi_awready_o(bus_axi_awready_w[AXI_S_PSRAM]),
    .s_axi_awaddr_i(bus_axi_awaddr_w[AXI_S_PSRAM*`XLEN +: `XLEN]),
    .s_axi_wvalid_i(bus_axi_wvalid_w[AXI_S_PSRAM]),
    .s_axi_wready_o(bus_axi_wready_w[AXI_S_PSRAM]),
    .s_axi_wdata_i(bus_axi_wdata_w[AXI_S_PSRAM*`XLEN +: `XLEN]),
    .s_axi_wstrb_i(bus_axi_wstrb_w[AXI_S_PSRAM*4 +: 4]),
    .s_axi_bvalid_o(bus_axi_bvalid_w[AXI_S_PSRAM]),
    .s_axi_bready_i(bus_axi_bready_w[AXI_S_PSRAM]),
    .s_axi_bresp_o(bus_axi_bresp_w[AXI_S_PSRAM*2 +: 2])
  );

  AxiDpiSlave u_legacy_mmio_slave (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(bus_axi_arvalid_w[AXI_S_LEGACY_MMIO]),
    .s_axi_arready_o(bus_axi_arready_w[AXI_S_LEGACY_MMIO]),
    .s_axi_araddr_i(bus_axi_araddr_w[AXI_S_LEGACY_MMIO*`XLEN +: `XLEN]),
    .s_axi_aruser_i(bus_axi_aruser_w[AXI_S_LEGACY_MMIO]),
    .s_axi_rvalid_o(bus_axi_rvalid_w[AXI_S_LEGACY_MMIO]),
    .s_axi_rready_i(bus_axi_rready_w[AXI_S_LEGACY_MMIO]),
    .s_axi_rdata_o(bus_axi_rdata_w[AXI_S_LEGACY_MMIO*`XLEN +: `XLEN]),
    .s_axi_rresp_o(bus_axi_rresp_w[AXI_S_LEGACY_MMIO*2 +: 2]),
    .s_axi_awvalid_i(bus_axi_awvalid_w[AXI_S_LEGACY_MMIO]),
    .s_axi_awready_o(bus_axi_awready_w[AXI_S_LEGACY_MMIO]),
    .s_axi_awaddr_i(bus_axi_awaddr_w[AXI_S_LEGACY_MMIO*`XLEN +: `XLEN]),
    .s_axi_wvalid_i(bus_axi_wvalid_w[AXI_S_LEGACY_MMIO]),
    .s_axi_wready_o(bus_axi_wready_w[AXI_S_LEGACY_MMIO]),
    .s_axi_wdata_i(bus_axi_wdata_w[AXI_S_LEGACY_MMIO*`XLEN +: `XLEN]),
    .s_axi_wstrb_i(bus_axi_wstrb_w[AXI_S_LEGACY_MMIO*4 +: 4]),
    .s_axi_bvalid_o(bus_axi_bvalid_w[AXI_S_LEGACY_MMIO]),
    .s_axi_bready_i(bus_axi_bready_w[AXI_S_LEGACY_MMIO]),
    .s_axi_bresp_o(bus_axi_bresp_w[AXI_S_LEGACY_MMIO*2 +: 2])
  );

  genvar stub_idx;
  generate
    for (stub_idx = 0; stub_idx < AXI_S_COUNT; stub_idx = stub_idx + 1) begin : gen_device_stub
      if (AXI_S_STUB_MASK[stub_idx]) begin : g
        AxiDefaultSlave u_stub (
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
            bus_axi_wstrb_w[stub_idx*4 +: 4]
        };
      end
    end
  endgenerate

`ifndef NPC_OOO_ALU_EXPERIMENT
  // 仿真兼容事件不进入 NpcCore 端口 ABI；DPI 顶层用层次化引用观察 RTL 内部 flush。
  assign sim_cache_flush_w = u_core.u_inorder.cache_flush_valid_w;
  // 性能统计属于仿真观测，不进入 NpcCore 端口 ABI；同步 SRAM 下 lookup 结果晚于请求握手一拍。
  assign sim_icache_access_w = (u_core.u_inorder.u_icache.state_q == 3'd1) &&
                               u_core.u_inorder.u_icache.req_cacheable_w &&
                               !u_core.u_inorder.u_icache.req_misaligned_w;
  assign sim_icache_hit_w = sim_icache_access_w && u_core.u_inorder.u_icache.lookup_hit_w;
  assign sim_icache_miss_w = sim_icache_access_w && !u_core.u_inorder.u_icache.lookup_hit_w;

  assign sim_dcache_access_w = (u_core.u_inorder.u_dcache.state_q == 5'd1) &&
                               u_core.u_inorder.u_dcache.req_cacheable_w &&
                               (!u_core.u_inorder.u_dcache.req_write_q ||
                                (u_core.u_inorder.u_dcache.req_wstrb_q != 4'b0000));
  assign sim_dcache_hit_w = sim_dcache_access_w && u_core.u_inorder.u_dcache.lookup_hit_w;
  assign sim_dcache_miss_w = sim_dcache_access_w && !u_core.u_inorder.u_dcache.lookup_hit_w;
  assign sim_dcache_store_access_w = sim_dcache_access_w && u_core.u_inorder.u_dcache.req_write_q;
  assign sim_dcache_writeback_w = u_core.u_inorder.u_dcache.wb_axi_write_fire_w;
  assign sim_dcache_write_through_w = 1'b0;
  assign sim_control_event_w = u_core.u_inorder.bpu_update_valid_w;
  assign sim_bpu_lookup_event_w = u_core.u_inorder.u_if_stage.u_branch_predictor.predict_valid_i &&
                                  u_core.u_inorder.u_if_stage.bpu_predict_control_w;
  assign sim_bpu_ret_resolve_w = u_core.u_inorder.id_ex_jalr_w &&
                                 !sim_is_link_reg(u_core.u_inorder.id_ex_inst_q[11:7]) &&
                                 sim_is_link_reg(u_core.u_inorder.id_ex_inst_q[19:15]);
  assign sim_bpu_pred_taken_w = u_core.u_inorder.id_ex_pred_pc_q != u_core.u_inorder.ex_pc_plus4_w;
  assign sim_bpu_resolve_correct_w =
      u_core.u_inorder.id_ex_pred_pc_q == u_core.u_inorder.ex_control_next_pc_w;
`else
  assign sim_cache_flush_w = 1'b0;
  // OoO 实验核的 packet I-cache 位于 core top fetch bridge 内；这里仅做仿真统计观察。
  assign sim_icache_access_w = u_core.u_ooo_fetch_bridge.fetch_req_fire_w;
  assign sim_icache_hit_w = sim_icache_access_w &&
                            u_core.u_ooo_fetch_bridge.cache_hit_w;
  assign sim_icache_miss_w = sim_icache_access_w &&
                             !u_core.u_ooo_fetch_bridge.cache_hit_w;
  assign sim_dcache_access_w =
      u_core.u_ooo_mem_bridge.mem0_req_fire_w ||
      u_core.u_ooo_mem_bridge.mem1_req_fire_w;
  assign sim_dcache_store_access_w =
      sim_dcache_access_w && u_core.u_ooo_mem_bridge.req_write_w;
  assign sim_dcache_hit_w =
      sim_dcache_access_w && u_core.u_ooo_mem_bridge.req_dcache_hit_w;
  assign sim_dcache_miss_w =
      sim_dcache_access_w && !u_core.u_ooo_mem_bridge.req_write_w &&
      !u_core.u_ooo_mem_bridge.req_dcache_hit_w;
  assign sim_dcache_writeback_w = 1'b0;
  assign sim_dcache_write_through_w = 1'b0;
  assign sim_control_event_w = 1'b0;
  assign sim_bpu_ret_resolve_w = 1'b0;
  assign sim_bpu_pred_taken_w = 1'b0;
  assign sim_bpu_resolve_correct_w = 1'b0;
  wire sim_ooo_pending_jalr_ret_w =
      u_core.u_ooo_core.pending_jump_q &&
      u_core.u_ooo_core.pending_jump_jalr_q &&
      (u_core.u_ooo_core.pending_jump_inst_q[11:7] == 5'd0) &&
      sim_is_link_reg(u_core.u_ooo_core.pending_jump_rs1_q) &&
      (u_core.u_ooo_core.pending_jump_imm_q == {`XLEN{1'b0}});
  wire sim_ooo_pending_jalr_lookup_w =
      u_core.u_ooo_core.pending_jump_resolve_ready_w &&
      u_core.u_ooo_core.pending_jump_jalr_q &&
      !u_core.u_ooo_core.pending_jump_misaligned_w;
  wire sim_ooo_direct_ras_lookup_w =
      u_core.u_ooo_core.direct_ret0_fire_w ||
      u_core.u_ooo_core.direct_ret1_fire_w ||
      u_core.u_ooo_core.direct_branch0_lane1_ret_w;
  wire sim_ooo_pending_ras_lookup_w =
      sim_ooo_pending_jalr_lookup_w && sim_ooo_pending_jalr_ret_w;
  wire sim_ooo_ras_lookup_event_w =
      sim_ooo_direct_ras_lookup_w || sim_ooo_pending_ras_lookup_w;
  wire sim_ooo_ras_hit_w =
      sim_ooo_direct_ras_lookup_w ||
      (sim_ooo_pending_ras_lookup_w && !u_core.u_ooo_core.ras_empty_w);
  wire sim_ooo_btb_lookup_event_w =
      sim_ooo_pending_jalr_lookup_w &&
      !(sim_ooo_pending_jalr_ret_w && !u_core.u_ooo_core.ras_empty_w);
  wire sim_ooo_ras_overflow_event_w =
      (u_core.u_ooo_core.direct_jal_call_w ||
       u_core.u_ooo_core.pending_jump_call_fire_w) &&
      u_core.u_ooo_core.ras_full_w;
  assign sim_bpu_lookup_event_w =
      u_core.u_ooo_core.branch_bpu_lookup_event_w ||
      sim_ooo_btb_lookup_event_w ||
      sim_ooo_ras_lookup_event_w ||
      sim_ooo_ras_overflow_event_w;
  // OoO 统计只在仿真顶层旁路观察已有信号，不回馈任何 ready/valid 或提交路径。
  wire [1:0] sim_ooo_execute_count_w =
      {1'b0, u_core.u_ooo_core.execute0_valid_unused_w} +
      {1'b0, u_core.u_ooo_core.execute1_valid_unused_w};
  wire [1:0] sim_ooo_dispatch_count_w =
      {1'b0, u_core.u_ooo_core.core_dispatch0_fire_w} +
      {1'b0, (u_core.u_ooo_core.core_dispatch1_valid_w &&
              u_core.u_ooo_core.dispatch1_ready_w)};
  wire unused_ooo_sim_stat_w =
      sim_icache_access_w | sim_icache_hit_w | sim_icache_miss_w |
      sim_dcache_access_w | sim_dcache_hit_w | sim_dcache_miss_w |
      sim_dcache_store_access_w | sim_dcache_writeback_w |
      sim_dcache_write_through_w | sim_control_event_w |
      sim_bpu_lookup_event_w | sim_bpu_ret_resolve_w |
      sim_bpu_pred_taken_w | sim_bpu_resolve_correct_w |
      u_core.u_ooo_core.branch_bpu_update_valid_w |
      u_core.u_ooo_core.branch_bpu_update_correct_w |
      sim_ooo_pending_jalr_ret_w | sim_ooo_pending_jalr_lookup_w |
      sim_ooo_direct_ras_lookup_w | sim_ooo_pending_ras_lookup_w |
      sim_ooo_ras_lookup_event_w | sim_ooo_ras_hit_w |
      sim_ooo_btb_lookup_event_w | sim_ooo_ras_overflow_event_w |
      (|sim_ooo_execute_count_w) | (|sim_ooo_dispatch_count_w);
`endif

  // 仿真事件仍集中在顶层；真实 PMEM/MMIO 请求已经下沉到 AxiDpiSlave。
  always_ff @(posedge clk) begin
    if (rst) begin
      exit_reported_q <= 1'b0;
    end else begin
      if (uart_access_valid_w) begin
        // UART 已从 DPI 大从设备拆出；这里补回仿真侧输出和 difftest MMIO skip。
        npc_uart_event(
          uart_access_write_w ? 32'd1 : 32'd0,
          uart_tx_valid_w ? 32'd1 : 32'd0,
          {24'd0, uart_tx_data_w}
        );
      end

      // commit/trap/exit 只作为仿真事件推给宿主侧，避免把宽调试总线做成 Verilator 顶层 IO。
      if (core_commit0_valid_w && !core_commit0_exception_w) begin
        npc_commit_event(
          core_commit0_pc_w,
          core_commit0_inst_w,
          core_commit0_next_pc_w,
          core_commit0_rd_en_w ? 32'd1 : 32'd0,
          {{(32-`REG_ADDR_W){1'b0}}, core_commit0_rd_addr_w},
          core_commit0_rd_data_w
        );
      end

      if (core_commit1_valid_w && !core_commit1_exception_w) begin
        npc_commit_event(
          core_commit1_pc_w,
          core_commit1_inst_w,
          core_commit1_next_pc_w,
          core_commit1_rd_en_w ? 32'd1 : 32'd0,
          {{(32-`REG_ADDR_W){1'b0}}, core_commit1_rd_addr_w},
          core_commit1_rd_data_w
        );
      end

`ifndef NPC_OOO_ALU_EXPERIMENT
      if (sim_control_event_w) begin
        npc_control_flow_event(
          u_core.u_inorder.id_ex_branch_w ? 32'd1 : 32'd0,
          (u_core.u_inorder.id_ex_branch_w &&
           u_core.u_inorder.ex_control_redirect_w) ? 32'd1 : 32'd0,
          u_core.u_inorder.id_ex_jal_w ? 32'd1 : 32'd0,
          u_core.u_inorder.id_ex_jalr_w ? 32'd1 : 32'd0
        );
        npc_bpu_resolve_event(
          u_core.u_inorder.id_ex_branch_w ? 32'd1 : 32'd0,
          u_core.u_inorder.id_ex_pc_q,
          u_core.u_inorder.id_ex_jal_w ? 32'd1 : 32'd0,
          u_core.u_inorder.id_ex_jalr_w ? 32'd1 : 32'd0,
          sim_bpu_ret_resolve_w ? 32'd1 : 32'd0,
          sim_bpu_pred_taken_w ? 32'd1 : 32'd0,
          u_core.u_inorder.ex_control_redirect_w ? 32'd1 : 32'd0,
          sim_bpu_resolve_correct_w ? 32'd1 : 32'd0
        );
      end

      if (sim_bpu_lookup_event_w) begin
        // lookup 统计按预测发生点计数；最终正确率仍由 EX resolve 事件给出。
        npc_bpu_lookup_event(
          u_core.u_inorder.u_if_stage.bpu_predict_branch_w ? 32'd1 : 32'd0,
          (u_core.u_inorder.u_if_stage.bpu_predict_jalr_w &&
           !u_core.u_inorder.u_if_stage.bpu_predict_ras_hit_w) ? 32'd1 : 32'd0,
          u_core.u_inorder.u_if_stage.bpu_predict_ret_w ? 32'd1 : 32'd0,
          u_core.u_inorder.u_if_stage.bpu_predict_btb_hit_w ? 32'd1 : 32'd0,
          u_core.u_inorder.u_if_stage.bpu_predict_bht_valid_w ? 32'd1 : 32'd0,
          u_core.u_inorder.u_if_stage.bpu_predict_ras_lookup_w ? 32'd1 : 32'd0,
          u_core.u_inorder.u_if_stage.bpu_predict_ras_hit_w ? 32'd1 : 32'd0,
          u_core.u_inorder.u_if_stage.bpu_predict_ras_overflow_w ? 32'd1 : 32'd0
        );
      end
`else
      if (u_core.u_ooo_core.branch_bpu_update_valid_w) begin
        npc_bpu_resolve_event(
          32'd1,
          u_core.u_ooo_core.branch_bpu_update_pc_w,
          32'd0,
          32'd0,
          32'd0,
          u_core.u_ooo_core.branch_bpu_update_pred_taken_w ? 32'd1 : 32'd0,
          u_core.u_ooo_core.branch_bpu_update_taken_w ? 32'd1 : 32'd0,
          u_core.u_ooo_core.branch_bpu_update_correct_w ? 32'd1 : 32'd0
        );
      end

      if (sim_bpu_lookup_event_w) begin
        // OoO 侧 BPU 仍不进入端口 ABI；仿真顶层只读观察预测表 lookup 结果。
        // branch 走 OoO gshare/local，普通非 return JALR 走 OoO JALR BTB，return 走 OoO RAS。
        npc_bpu_lookup_event(
          u_core.u_ooo_core.branch_bpu_lookup_event_w ? 32'd1 : 32'd0,
          sim_ooo_btb_lookup_event_w ? 32'd1 : 32'd0,
          sim_ooo_ras_lookup_event_w ? 32'd1 : 32'd0,
          u_core.u_ooo_core.pending_jump_jalr_btb_hit_w ? 32'd1 : 32'd0,
          u_core.u_ooo_core.branch_bpu_lookup_bht_valid_w ? 32'd1 : 32'd0,
          sim_ooo_ras_lookup_event_w ? 32'd1 : 32'd0,
          sim_ooo_ras_hit_w ? 32'd1 : 32'd0,
          sim_ooo_ras_overflow_event_w ? 32'd1 : 32'd0
        );
      end
`endif

      if (sim_icache_access_w) begin
        npc_icache_event(
          32'd1,
          sim_icache_hit_w ? 32'd1 : 32'd0,
          sim_icache_miss_w ? 32'd1 : 32'd0
        );
      end

      if (sim_dcache_access_w) begin
        npc_dcache_event(
          32'd1,
          sim_dcache_hit_w ? 32'd1 : 32'd0,
          sim_dcache_miss_w ? 32'd1 : 32'd0,
          32'd0,
          sim_dcache_write_through_w ? 32'd1 : 32'd0,
          sim_dcache_store_access_w ? 32'd1 : 32'd0
        );
      end

      if (sim_dcache_writeback_w) begin
        npc_dcache_event(32'd0, 32'd0, 32'd0, 32'd1, 32'd0, 32'd0);
      end

`ifdef NPC_OOO_ALU_EXPERIMENT
      npc_ooo_cycle_event(
        {30'd0, core_retire_count_w},
        {30'd0, sim_ooo_execute_count_w},
        {30'd0, sim_ooo_dispatch_count_w},
        u_core.u_ooo_core.fetch_req_valid_o ? 32'd1 : 32'd0,
        u_core.u_ooo_core.fetch_req_fire_w ? 32'd1 : 32'd0,
        u_core.u_ooo_core.fetch_rsp_fire_w ? 32'd1 : 32'd0,
        u_core.u_ooo_core.fetch_rsp_enqueue_w ? 32'd1 : 32'd0,
        u_core.u_ooo_core.fetch_rsp_bypass_consumed_w ? 32'd1 : 32'd0,
        u_core.u_ooo_core.stop_pending_q ? 32'd1 : 32'd0,
        u_core.u_ooo_core.pending_branch_q ? 32'd1 : 32'd0,
        u_core.u_ooo_core.pending_jump_q ? 32'd1 : 32'd0,
        u_core.u_ooo_core.pending_mem_q ? 32'd1 : 32'd0,
	        u_core.u_ooo_core.synth_lane1_ret_pending_q ? 32'd1 : 32'd0,
	        u_core.u_ooo_core.branch_prefetch_req_fire_w ? 32'd1 : 32'd0,
	        (u_core.u_ooo_core.branch_prefetch_hit_available_w ||
	         u_core.u_ooo_core.jalr_prefetch_hit_available_w) ? 32'd1 : 32'd0,
        u_core.u_ooo_mem_bridge.mem0_req_fire_w ? 32'd1 : 32'd0,
        u_core.u_ooo_mem_bridge.mem1_req_fire_w ? 32'd1 : 32'd0,
        (u_core.ooo_mem0_rsp_valid_w && u_core.ooo_mem0_rsp_ready_w) ? 32'd1 : 32'd0,
        (u_core.ooo_mem1_rsp_valid_w && u_core.ooo_mem1_rsp_ready_w) ? 32'd1 : 32'd0,
        u_core.u_ooo_core.core_commit1_block_w ? 32'd1 : 32'd0
      );
`endif

      if (core_exit_valid_w && !exit_reported_q) begin
        exit_reported_q <= 1'b1;
        npc_exit_event(
          core_exit_is_ebreak_w ? 32'd1 : 32'd0,
          core_exit_is_ecall_w ? 32'd1 : 32'd0,
          core_exit_code_w,
          core_exit_pc_w
        );
      end

      if (core_trap_valid_w) begin
        npc_trap_event(
          {{(32-`TRAP_CAUSE_W){1'b0}}, core_trap_cause_w},
          core_trap_pc_w,
          core_trap_tval_w
        );
      end

      if (sim_cache_flush_w) begin
        npc_cache_flush_all();
      end
    end
  end

endmodule
