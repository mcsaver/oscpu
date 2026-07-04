`include "define.v"

// DPI-C 仿真顶层：只负责把可综合 NpcCore 接到独立总线和宿主侧事件模型。
// 该文件不能进入 RTL_CORE_SRCS/STA_RTL_FILES。

import "DPI-C" function void npc_commit_event(
  input longint unsigned pc,
  input int unsigned inst,
  input longint unsigned next_pc,
  input int unsigned rd_en,
  input int unsigned rd_addr,
  input longint unsigned rd_data
);

import "DPI-C" function void npc_exit_event(
  input int unsigned is_ebreak,
  input int unsigned is_ecall,
  input longint unsigned code,
  input longint unsigned pc
);

import "DPI-C" function void npc_mmio_load_event();
import "DPI-C" function void npc_trap_event(
  input int unsigned cause,
  input longint unsigned pc,
  input longint unsigned tval
);

import "DPI-C" function void npc_handled_trap_event(
  input int unsigned kind,
  input int unsigned cause,
  input longint unsigned pc,
  input longint unsigned tval
);

`ifdef CONFIG_NPC_BRANCH_STATS
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
`endif

`ifdef CONFIG_NPC_CACHE_STATS
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
`endif

`ifdef CONFIG_NPC_OOO_STATS
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
  input int unsigned commit1_block,
  input int unsigned fetch_busy,
  input int unsigned mem_busy,
  input int unsigned axi_wait,
  input int unsigned hazard_busy,
  input int unsigned branch_flush,
  input int unsigned exception_busy,
  input longint unsigned pending_branch_pc,
  input longint unsigned pending_jump_pc
);
`endif

import "DPI-C" function void npc_uart_event(
  input int unsigned is_write,
  input int unsigned tx_valid,
  input int unsigned tx_data,
  input int unsigned access_addr,
  input longint unsigned access_wdata,
  input int unsigned access_wstrb,
  input longint unsigned access_rdata
);

import "DPI-C" function int npc_uart_rx_pop(
  output int unsigned data
);

import "DPI-C" function void npc_irq_event(
  input int unsigned uart_irq,
  input int unsigned plic_irq
);

`ifndef CONFIG_NPC_UART_RX_POLL_SHIFT
`define CONFIG_NPC_UART_RX_POLL_SHIFT 0
`endif

module NpcSimTop (
  input logic clk,
  input logic rst,

  output logic [`XLEN-1:0] debug_pc_o,
  output logic [`CORE_STATE_W-1:0] debug_state_o,
  output logic [63:0] debug_ooo_flags_o,
  output logic [63:0] debug_ooo_satp_o,
  output logic [63:0] debug_bus_flags_o,
  output logic [63:0] debug_bus2_flags_o,
  output logic [63:0] debug_fetch_addr_o,
  output logic [63:0] debug_mem_addr_o,
  output logic [63:0] debug_fetch_pte_addr_o,
  output logic [63:0] debug_fetch_pte_o,
  output logic [63:0] debug_fetch_pte_meta_o,
  output logic [63:0] debug_clint_mtime_o
);

`ifdef CONFIG_NPC_DEBUG_PORTS
  localparam [3:0] AXI_S_CLINT = 4'd0;
  localparam [3:0] AXI_S_SRAM = 4'd2;
  localparam [3:0] AXI_S_UART = 4'd3;
  localparam [3:0] AXI_S_DEFAULT = 4'd15;
`endif
  logic psram_axi_arvalid_w;
  logic psram_axi_arready_w;
  logic [`XLEN-1:0] psram_axi_araddr_w;
  logic psram_axi_aruser_w;
  logic psram_axi_rvalid_w;
  logic psram_axi_rready_w;
  logic [`XLEN-1:0] psram_axi_rdata_w;
  logic [1:0] psram_axi_rresp_w;
  logic psram_axi_awvalid_w;
  logic psram_axi_awready_w;
  logic [`XLEN-1:0] psram_axi_awaddr_w;
  logic psram_axi_wvalid_w;
  logic psram_axi_wready_w;
  logic [`XLEN-1:0] psram_axi_wdata_w;
  logic [`STRB_W-1:0] psram_axi_wstrb_w;
  logic psram_axi_bvalid_w;
  logic psram_axi_bready_w;
  logic [1:0] psram_axi_bresp_w;

  logic sdram_axi_arvalid_w;
  logic sdram_axi_arready_w;
  logic [`XLEN-1:0] sdram_axi_araddr_w;
  logic sdram_axi_aruser_w;
  logic sdram_axi_rvalid_w;
  logic sdram_axi_rready_w;
  logic [`XLEN-1:0] sdram_axi_rdata_w;
  logic [1:0] sdram_axi_rresp_w;
  logic sdram_axi_awvalid_w;
  logic sdram_axi_awready_w;
  logic [`XLEN-1:0] sdram_axi_awaddr_w;
  logic sdram_axi_wvalid_w;
  logic sdram_axi_wready_w;
  logic [`XLEN-1:0] sdram_axi_wdata_w;
  logic [`STRB_W-1:0] sdram_axi_wstrb_w;
  logic sdram_axi_bvalid_w;
  logic sdram_axi_bready_w;
  logic [1:0] sdram_axi_bresp_w;

  logic legacy_mmio_axi_arvalid_w;
  logic legacy_mmio_axi_arready_w;
  logic [`XLEN-1:0] legacy_mmio_axi_araddr_w;
  logic legacy_mmio_axi_aruser_w;
  logic legacy_mmio_axi_rvalid_w;
  logic legacy_mmio_axi_rready_w;
  logic [`XLEN-1:0] legacy_mmio_axi_rdata_w;
  logic [1:0] legacy_mmio_axi_rresp_w;
  logic legacy_mmio_axi_awvalid_w;
  logic legacy_mmio_axi_awready_w;
  logic [`XLEN-1:0] legacy_mmio_axi_awaddr_w;
  logic legacy_mmio_axi_wvalid_w;
  logic legacy_mmio_axi_wready_w;
  logic [`XLEN-1:0] legacy_mmio_axi_wdata_w;
  logic [`STRB_W-1:0] legacy_mmio_axi_wstrb_w;
  logic legacy_mmio_axi_bvalid_w;
  logic legacy_mmio_axi_bready_w;
  logic [1:0] legacy_mmio_axi_bresp_w;

  logic virtio_blk_axi_arvalid_w;
  logic virtio_blk_axi_arready_w;
  logic [`XLEN-1:0] virtio_blk_axi_araddr_w;
  logic virtio_blk_axi_aruser_w;
  logic virtio_blk_axi_rvalid_w;
  logic virtio_blk_axi_rready_w;
  logic [`XLEN-1:0] virtio_blk_axi_rdata_w;
  logic [1:0] virtio_blk_axi_rresp_w;
  logic virtio_blk_axi_awvalid_w;
  logic virtio_blk_axi_awready_w;
  logic [`XLEN-1:0] virtio_blk_axi_awaddr_w;
  logic virtio_blk_axi_wvalid_w;
  logic virtio_blk_axi_wready_w;
  logic [`XLEN-1:0] virtio_blk_axi_wdata_w;
  logic [`STRB_W-1:0] virtio_blk_axi_wstrb_w;
  logic virtio_blk_axi_bvalid_w;
  logic virtio_blk_axi_bready_w;
  logic [1:0] virtio_blk_axi_bresp_w;

  logic uart_tx_valid_w;
  logic [7:0] uart_tx_data_w;
  logic uart_access_valid_w;
  logic uart_access_write_w;
  logic [11:0] uart_access_addr_w;
  logic [`XLEN-1:0] uart_access_wdata_w;
  logic [`STRB_W-1:0] uart_access_wstrb_w;
  logic [`XLEN-1:0] uart_access_rdata_w;
  logic uart_rx_valid_q;
  logic [7:0] uart_rx_data_q;
  logic uart_rx_ready_w;
  logic [31:0] uart_rx_poll_q;
  logic [63:0] clint_mtime_w;
  logic plic_external_irq_w;
  logic uart_irq_w;
  logic virtio_blk_irq_w;
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
  logic uart_irq_prev_q;
  logic plic_irq_prev_q;

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
  logic [1:0] core_retire_count_w;
  logic [6:0] core_free_count_w;
  logic [4:0] core_rob_count_w;
  logic [3:0] core_issue_count_w;

  NpcTop u_top (
    .clk(clk),
    .rst(rst),

    .psram_axi_arvalid_o(psram_axi_arvalid_w),
    .psram_axi_arready_i(psram_axi_arready_w),
    .psram_axi_araddr_o(psram_axi_araddr_w),
    .psram_axi_aruser_o(psram_axi_aruser_w),
    .psram_axi_rvalid_i(psram_axi_rvalid_w),
    .psram_axi_rready_o(psram_axi_rready_w),
    .psram_axi_rdata_i(psram_axi_rdata_w),
    .psram_axi_rresp_i(psram_axi_rresp_w),
    .psram_axi_awvalid_o(psram_axi_awvalid_w),
    .psram_axi_awready_i(psram_axi_awready_w),
    .psram_axi_awaddr_o(psram_axi_awaddr_w),
    .psram_axi_wvalid_o(psram_axi_wvalid_w),
    .psram_axi_wready_i(psram_axi_wready_w),
    .psram_axi_wdata_o(psram_axi_wdata_w),
    .psram_axi_wstrb_o(psram_axi_wstrb_w),
    .psram_axi_bvalid_i(psram_axi_bvalid_w),
    .psram_axi_bready_o(psram_axi_bready_w),
    .psram_axi_bresp_i(psram_axi_bresp_w),

    .sdram_axi_arvalid_o(sdram_axi_arvalid_w),
    .sdram_axi_arready_i(sdram_axi_arready_w),
    .sdram_axi_araddr_o(sdram_axi_araddr_w),
    .sdram_axi_aruser_o(sdram_axi_aruser_w),
    .sdram_axi_rvalid_i(sdram_axi_rvalid_w),
    .sdram_axi_rready_o(sdram_axi_rready_w),
    .sdram_axi_rdata_i(sdram_axi_rdata_w),
    .sdram_axi_rresp_i(sdram_axi_rresp_w),
    .sdram_axi_awvalid_o(sdram_axi_awvalid_w),
    .sdram_axi_awready_i(sdram_axi_awready_w),
    .sdram_axi_awaddr_o(sdram_axi_awaddr_w),
    .sdram_axi_wvalid_o(sdram_axi_wvalid_w),
    .sdram_axi_wready_i(sdram_axi_wready_w),
    .sdram_axi_wdata_o(sdram_axi_wdata_w),
    .sdram_axi_wstrb_o(sdram_axi_wstrb_w),
    .sdram_axi_bvalid_i(sdram_axi_bvalid_w),
    .sdram_axi_bready_o(sdram_axi_bready_w),
    .sdram_axi_bresp_i(sdram_axi_bresp_w),

    .legacy_mmio_axi_arvalid_o(legacy_mmio_axi_arvalid_w),
    .legacy_mmio_axi_arready_i(legacy_mmio_axi_arready_w),
    .legacy_mmio_axi_araddr_o(legacy_mmio_axi_araddr_w),
    .legacy_mmio_axi_aruser_o(legacy_mmio_axi_aruser_w),
    .legacy_mmio_axi_rvalid_i(legacy_mmio_axi_rvalid_w),
    .legacy_mmio_axi_rready_o(legacy_mmio_axi_rready_w),
    .legacy_mmio_axi_rdata_i(legacy_mmio_axi_rdata_w),
    .legacy_mmio_axi_rresp_i(legacy_mmio_axi_rresp_w),
    .legacy_mmio_axi_awvalid_o(legacy_mmio_axi_awvalid_w),
    .legacy_mmio_axi_awready_i(legacy_mmio_axi_awready_w),
    .legacy_mmio_axi_awaddr_o(legacy_mmio_axi_awaddr_w),
    .legacy_mmio_axi_wvalid_o(legacy_mmio_axi_wvalid_w),
    .legacy_mmio_axi_wready_i(legacy_mmio_axi_wready_w),
    .legacy_mmio_axi_wdata_o(legacy_mmio_axi_wdata_w),
    .legacy_mmio_axi_wstrb_o(legacy_mmio_axi_wstrb_w),
    .legacy_mmio_axi_bvalid_i(legacy_mmio_axi_bvalid_w),
    .legacy_mmio_axi_bready_o(legacy_mmio_axi_bready_w),
    .legacy_mmio_axi_bresp_i(legacy_mmio_axi_bresp_w),

    .virtio_blk_axi_arvalid_o(virtio_blk_axi_arvalid_w),
    .virtio_blk_axi_arready_i(virtio_blk_axi_arready_w),
    .virtio_blk_axi_araddr_o(virtio_blk_axi_araddr_w),
    .virtio_blk_axi_aruser_o(virtio_blk_axi_aruser_w),
    .virtio_blk_axi_rvalid_i(virtio_blk_axi_rvalid_w),
    .virtio_blk_axi_rready_o(virtio_blk_axi_rready_w),
    .virtio_blk_axi_rdata_i(virtio_blk_axi_rdata_w),
    .virtio_blk_axi_rresp_i(virtio_blk_axi_rresp_w),
    .virtio_blk_axi_awvalid_o(virtio_blk_axi_awvalid_w),
    .virtio_blk_axi_awready_i(virtio_blk_axi_awready_w),
    .virtio_blk_axi_awaddr_o(virtio_blk_axi_awaddr_w),
    .virtio_blk_axi_wvalid_o(virtio_blk_axi_wvalid_w),
    .virtio_blk_axi_wready_i(virtio_blk_axi_wready_w),
    .virtio_blk_axi_wdata_o(virtio_blk_axi_wdata_w),
    .virtio_blk_axi_wstrb_o(virtio_blk_axi_wstrb_w),
    .virtio_blk_axi_bvalid_i(virtio_blk_axi_bvalid_w),
    .virtio_blk_axi_bready_o(virtio_blk_axi_bready_w),
    .virtio_blk_axi_bresp_i(virtio_blk_axi_bresp_w),
    .virtio_blk_irq_i(virtio_blk_irq_w),

    .uart_rx_valid_i(uart_rx_valid_q),
    .uart_rx_data_i(uart_rx_data_q),
    .uart_rx_ready_o(uart_rx_ready_w),
    .uart_tx_valid_o(uart_tx_valid_w),
    .uart_tx_data_o(uart_tx_data_w),
    .uart_access_valid_o(uart_access_valid_w),
    .uart_access_write_o(uart_access_write_w),
    .uart_access_addr_o(uart_access_addr_w),
    .uart_access_wdata_o(uart_access_wdata_w),
    .uart_access_wstrb_o(uart_access_wstrb_w),
    .uart_access_rdata_o(uart_access_rdata_w),
    .uart_irq_o(uart_irq_w),
    .plic_external_irq_o(plic_external_irq_w),
    .clint_mtime_o(clint_mtime_w),

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
    .retire_count_o(core_retire_count_w),
    .free_count_o(core_free_count_w),
    .rob_count_o(core_rob_count_w),
    .issue_count_o(core_issue_count_w)
  );

  wire unused_top_status_w =
      core_halted_w | core_commit0_write_w | core_commit1_write_w |
      (|core_retire_count_w) | (|core_free_count_w) |
      (|core_rob_count_w) | (|core_issue_count_w) |
      virtio_blk_axi_aruser_w;

  assign debug_clint_mtime_o = clint_mtime_w;
`ifdef CONFIG_NPC_DEBUG_PORTS
  assign debug_ooo_satp_o = u_top.u_core.u_ooo_core.csr_satp_w;
  assign debug_ooo_flags_o = {
    23'd0,
    u_top.u_core.u_ooo_core.direct_frontend_flush_w,
    u_top.u_core.u_ooo_core.pending_replay_wait_w,
    u_top.u_core.u_ooo_core.drain_complete_w,
    u_top.u_core.u_ooo_core.csr_trap_ex_valid_w,
    u_top.u_core.u_ooo_core.pending_arch_trap_fire_w,
    (u_top.u_core.u_ooo_core.csr_satp_w[63:60] == 4'h8),
    u_top.u_core.u_ooo_core.csr_priv_mode_w,
    u_top.u_core.u_ooo_core.dispatch0_system_w,
    u_top.u_core.u_ooo_core.head0_csr_illegal_w,
    u_top.u_core.u_ooo_core.dispatch0_arch_trap_w,
    u_top.u_core.u_ooo_core.head_fetch_fault0_w,
    u_top.u_core.u_ooo_core.head_resp0_w,
    {1'b0, u_top.u_core.u_ooo_core.pending_trap_cause_q},
    u_top.u_core.u_ooo_core.fifo_has_packet_w,
    u_top.u_core.u_ooo_core.can_run_w,
    u_top.u_core.u_ooo_core.pending_system_csr_commit_w,
    u_top.u_core.u_ooo_core.system_csr_dispatch_fire_w,
    u_top.u_core.u_ooo_core.system_csr_dispatch_valid_w,
    u_top.u_core.u_ooo_core.dispatch0_ready_w,
    u_top.u_core.u_ooo_core.backend_drained_w,
    u_top.u_core.u_ooo_core.backend_drained_q,
    u_top.u_core.u_ooo_core.csr_irq_pending_w,
    u_top.u_core.u_ooo_core.pending_system_dispatched_q,
    u_top.u_core.u_ooo_core.pending_system_csr_q,
    u_top.u_core.u_ooo_core.pending_system_irq_q,
    u_top.u_core.u_ooo_core.pending_system_q,
    u_top.u_core.u_ooo_core.pending_arch_trap_q,
    u_top.u_core.u_ooo_core.pending_mem_q,
    u_top.u_core.u_ooo_core.pending_jump_q,
    u_top.u_core.u_ooo_core.pending_branch_q,
    u_top.u_core.u_ooo_core.pending_exit_q,
    u_top.u_core.u_ooo_core.orphan_stop_pending_w,
    u_top.u_core.u_ooo_core.stop_pending_owner_w,
    u_top.u_core.u_ooo_core.stop_pending_q
  };
  assign debug_bus_flags_o = {
    9'd0,
    u_top.u_bus.u_xbar.rd_active_q,
    u_top.u_bus.u_xbar.rd_resp_valid_q,
    u_top.u_bus.u_xbar.rd_master_busy_q,
    u_top.lsu_axi_bready_w,
    u_top.lsu_axi_bvalid_w,
    u_top.lsu_axi_wready_w,
    u_top.lsu_axi_wvalid_w,
    u_top.lsu_axi_awready_w,
    u_top.lsu_axi_awvalid_w,
    u_top.lsu_axi_rready_w,
    u_top.lsu_axi_rvalid_w,
    u_top.lsu_axi_arready_w,
    u_top.lsu_axi_arvalid_w,
    u_top.ifu_axi_rready_w,
    u_top.ifu_axi_rvalid_w,
    u_top.ifu_axi_arready_w,
    u_top.ifu_axi_arvalid_w,
    u_top.u_core.u_ooo_mem_bridge.drop_rsp_q,
    u_top.u_core.u_ooo_mem_bridge.active_port_q,
    u_top.u_core.u_ooo_mem_bridge.write_q,
    u_top.u_core.u_ooo_mem_bridge.state_q,
    u_top.u_core.u_ooo_fetch_bridge.walk_second_q,
    u_top.u_core.u_ooo_fetch_bridge.walk_level_q,
    u_top.u_core.u_ooo_fetch_bridge.paging_q,
    u_top.u_core.u_ooo_fetch_bridge.state_q,
    u_top.u_core.u_ooo_core.discard_fetch_rsp_q,
    u_top.u_core.u_ooo_core.outstanding_valid_q,
    u_top.u_core.u_ooo_core.fetch_rsp_ready_o,
    u_top.u_core.u_ooo_core.fetch_rsp_valid_i,
    u_top.u_core.u_ooo_core.fetch_req_ready_i,
    u_top.u_core.u_ooo_core.fetch_req_valid_o
  };
  assign debug_bus2_flags_o = {
    15'd0,
    u_top.u_bus.u_xbar.rd_drop_q,
    u_top.u_bus.u_xbar.rd_ar_sent_q,
    u_top.u_bus.u_xbar.rd_owner_q[AXI_S_DEFAULT],
    u_top.u_bus.u_xbar.rd_owner_q[AXI_S_SRAM],
    u_top.u_bus.u_xbar.rd_owner_q[AXI_S_UART],
    u_top.u_bus.u_xbar.rd_owner_q[AXI_S_CLINT],
    u_top.bus_axi_rready_w[AXI_S_SRAM],
    u_top.bus_axi_rvalid_w[AXI_S_SRAM],
    u_top.bus_axi_arready_w[AXI_S_SRAM],
    u_top.bus_axi_arvalid_w[AXI_S_SRAM],
    u_top.lsu_axi_abort_w,
    u_top.ifu_axi_abort_w,
    u_top.u_core.u_ooo_mem_bridge.flush_i,
    u_top.u_core.u_ooo_fetch_bridge.mmu_flush_i
  };
  assign debug_fetch_addr_o = u_top.u_core.u_ooo_fetch_bridge.pc_q;
  assign debug_mem_addr_o = u_top.u_core.u_ooo_mem_bridge.addr_q;
  assign debug_fetch_pte_addr_o = u_top.u_core.u_ooo_fetch_bridge.debug_last_pte_addr_q;
  assign debug_fetch_pte_o = u_top.u_core.u_ooo_fetch_bridge.debug_last_pte_q;
  assign debug_fetch_pte_meta_o = {
    61'd0,
    u_top.u_core.u_ooo_fetch_bridge.debug_last_pte_second_q,
    u_top.u_core.u_ooo_fetch_bridge.debug_last_pte_level_q
  };
`else
  assign debug_ooo_satp_o = 64'd0;
  assign debug_ooo_flags_o = 64'd0;
  assign debug_bus_flags_o = 64'd0;
  assign debug_bus2_flags_o = 64'd0;
  assign debug_fetch_addr_o = 64'd0;
  assign debug_mem_addr_o = 64'd0;
  assign debug_fetch_pte_addr_o = 64'd0;
  assign debug_fetch_pte_o = 64'd0;
  assign debug_fetch_pte_meta_o = 64'd0;
`endif

  AxiLiteVirtioBlk #(
    .ADDR_W(`XLEN),
    .DATA_W(`XLEN),
    .STRB_W(`STRB_W)
  ) u_virtio_blk_axi (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(virtio_blk_axi_arvalid_w),
    .s_axi_arready_o(virtio_blk_axi_arready_w),
    .s_axi_araddr_i(virtio_blk_axi_araddr_w),
    .s_axi_rvalid_o(virtio_blk_axi_rvalid_w),
    .s_axi_rready_i(virtio_blk_axi_rready_w),
    .s_axi_rdata_o(virtio_blk_axi_rdata_w),
    .s_axi_rresp_o(virtio_blk_axi_rresp_w),
    .s_axi_awvalid_i(virtio_blk_axi_awvalid_w),
    .s_axi_awready_o(virtio_blk_axi_awready_w),
    .s_axi_awaddr_i(virtio_blk_axi_awaddr_w),
    .s_axi_wvalid_i(virtio_blk_axi_wvalid_w),
    .s_axi_wready_o(virtio_blk_axi_wready_w),
    .s_axi_wdata_i(virtio_blk_axi_wdata_w),
    .s_axi_wstrb_i(virtio_blk_axi_wstrb_w),
    .s_axi_bvalid_o(virtio_blk_axi_bvalid_w),
    .s_axi_bready_i(virtio_blk_axi_bready_w),
    .s_axi_bresp_o(virtio_blk_axi_bresp_w),
    .irq_o(virtio_blk_irq_w)
  );

  AxiDpiSlave u_psram_slave (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(psram_axi_arvalid_w),
    .s_axi_arready_o(psram_axi_arready_w),
    .s_axi_araddr_i(psram_axi_araddr_w),
    .s_axi_aruser_i(psram_axi_aruser_w),
    .s_axi_rvalid_o(psram_axi_rvalid_w),
    .s_axi_rready_i(psram_axi_rready_w),
    .s_axi_rdata_o(psram_axi_rdata_w),
    .s_axi_rresp_o(psram_axi_rresp_w),
    .s_axi_awvalid_i(psram_axi_awvalid_w),
    .s_axi_awready_o(psram_axi_awready_w),
    .s_axi_awaddr_i(psram_axi_awaddr_w),
    .s_axi_wvalid_i(psram_axi_wvalid_w),
    .s_axi_wready_o(psram_axi_wready_w),
    .s_axi_wdata_i(psram_axi_wdata_w),
    .s_axi_wstrb_i(psram_axi_wstrb_w),
    .s_axi_bvalid_o(psram_axi_bvalid_w),
    .s_axi_bready_i(psram_axi_bready_w),
    .s_axi_bresp_o(psram_axi_bresp_w)
  );

  AxiDpiSlave u_sdram_slave (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(sdram_axi_arvalid_w),
    .s_axi_arready_o(sdram_axi_arready_w),
    .s_axi_araddr_i(sdram_axi_araddr_w),
    .s_axi_aruser_i(sdram_axi_aruser_w),
    .s_axi_rvalid_o(sdram_axi_rvalid_w),
    .s_axi_rready_i(sdram_axi_rready_w),
    .s_axi_rdata_o(sdram_axi_rdata_w),
    .s_axi_rresp_o(sdram_axi_rresp_w),
    .s_axi_awvalid_i(sdram_axi_awvalid_w),
    .s_axi_awready_o(sdram_axi_awready_w),
    .s_axi_awaddr_i(sdram_axi_awaddr_w),
    .s_axi_wvalid_i(sdram_axi_wvalid_w),
    .s_axi_wready_o(sdram_axi_wready_w),
    .s_axi_wdata_i(sdram_axi_wdata_w),
    .s_axi_wstrb_i(sdram_axi_wstrb_w),
    .s_axi_bvalid_o(sdram_axi_bvalid_w),
    .s_axi_bready_i(sdram_axi_bready_w),
    .s_axi_bresp_o(sdram_axi_bresp_w)
  );

  AxiDpiSlave u_legacy_mmio_slave (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(legacy_mmio_axi_arvalid_w),
    .s_axi_arready_o(legacy_mmio_axi_arready_w),
    .s_axi_araddr_i(legacy_mmio_axi_araddr_w),
    .s_axi_aruser_i(legacy_mmio_axi_aruser_w),
    .s_axi_rvalid_o(legacy_mmio_axi_rvalid_w),
    .s_axi_rready_i(legacy_mmio_axi_rready_w),
    .s_axi_rdata_o(legacy_mmio_axi_rdata_w),
    .s_axi_rresp_o(legacy_mmio_axi_rresp_w),
    .s_axi_awvalid_i(legacy_mmio_axi_awvalid_w),
    .s_axi_awready_o(legacy_mmio_axi_awready_w),
    .s_axi_awaddr_i(legacy_mmio_axi_awaddr_w),
    .s_axi_wvalid_i(legacy_mmio_axi_wvalid_w),
    .s_axi_wready_o(legacy_mmio_axi_wready_w),
    .s_axi_wdata_i(legacy_mmio_axi_wdata_w),
    .s_axi_wstrb_i(legacy_mmio_axi_wstrb_w),
    .s_axi_bvalid_o(legacy_mmio_axi_bvalid_w),
    .s_axi_bready_i(legacy_mmio_axi_bready_w),
    .s_axi_bresp_o(legacy_mmio_axi_bresp_w)
  );

`ifdef CONFIG_NPC_SIM_STATS
  // RV64 只保留 OoO/superscalar core，cache/BPU/pipe 统计均从 OoO bridge/core 只读观察。
  assign sim_icache_access_w = u_top.u_core.u_ooo_fetch_bridge.fetch_req_fire_w;
  assign sim_icache_hit_w = sim_icache_access_w &&
                            u_top.u_core.u_ooo_fetch_bridge.cache_hit_w;
  assign sim_icache_miss_w = sim_icache_access_w &&
                             !u_top.u_core.u_ooo_fetch_bridge.cache_hit_w;
  assign sim_dcache_access_w =
      u_top.u_core.u_ooo_mem_bridge.mem0_req_fire_w;
  assign sim_dcache_store_access_w =
      sim_dcache_access_w && u_top.u_core.u_ooo_mem_bridge.req_write_w;
  assign sim_dcache_hit_w =
      sim_dcache_access_w && u_top.u_core.u_ooo_mem_bridge.req_dcache_hit_w;
  assign sim_dcache_miss_w =
      sim_dcache_access_w && !u_top.u_core.u_ooo_mem_bridge.req_write_w &&
      !u_top.u_core.u_ooo_mem_bridge.req_dcache_hit_w;
  assign sim_dcache_writeback_w = 1'b0;
  assign sim_dcache_write_through_w = 1'b0;
  assign sim_control_event_w = 1'b0;
  assign sim_bpu_ret_resolve_w = 1'b0;
  assign sim_bpu_pred_taken_w = 1'b0;
  assign sim_bpu_resolve_correct_w = 1'b0;
  wire sim_ooo_pending_jalr_ret_w =
      u_top.u_core.u_ooo_core.pending_jump_q &&
      u_top.u_core.u_ooo_core.pending_jump_jalr_q &&
      (u_top.u_core.u_ooo_core.pending_jump_inst_q[11:7] == 5'd0) &&
      sim_is_link_reg(u_top.u_core.u_ooo_core.pending_jump_rs1_q) &&
      (u_top.u_core.u_ooo_core.pending_jump_imm_q == {`XLEN{1'b0}});
  wire sim_ooo_pending_jalr_lookup_w =
      u_top.u_core.u_ooo_core.pending_jump_resolve_ready_w &&
      u_top.u_core.u_ooo_core.pending_jump_jalr_q &&
      !u_top.u_core.u_ooo_core.pending_jump_misaligned_w;
  wire sim_ooo_direct_ras_lookup_w =
      u_top.u_core.u_ooo_core.direct_ret0_fire_w ||
      u_top.u_core.u_ooo_core.direct_ret1_fire_w ||
      u_top.u_core.u_ooo_core.direct_branch0_lane1_ret_w;
  wire sim_ooo_pending_ras_lookup_w =
      sim_ooo_pending_jalr_lookup_w && sim_ooo_pending_jalr_ret_w;
  wire sim_ooo_ras_lookup_event_w =
      sim_ooo_direct_ras_lookup_w || sim_ooo_pending_ras_lookup_w;
  wire sim_ooo_ras_hit_w =
      sim_ooo_direct_ras_lookup_w ||
      (sim_ooo_pending_ras_lookup_w && !u_top.u_core.u_ooo_core.ras_empty_w);
  wire sim_ooo_btb_lookup_event_w =
      sim_ooo_pending_jalr_lookup_w &&
      !(sim_ooo_pending_jalr_ret_w && !u_top.u_core.u_ooo_core.ras_empty_w);
  wire sim_ooo_ras_overflow_event_w =
      (u_top.u_core.u_ooo_core.direct_jal_call_w ||
       u_top.u_core.u_ooo_core.pending_jump_call_fire_w) &&
      u_top.u_core.u_ooo_core.ras_full_w;
  assign sim_bpu_lookup_event_w =
      u_top.u_core.u_ooo_core.branch_bpu_lookup_event_w ||
      sim_ooo_btb_lookup_event_w ||
      sim_ooo_ras_lookup_event_w ||
      sim_ooo_ras_overflow_event_w;
  // OoO 统计只在仿真顶层旁路观察已有信号，不回馈任何 ready/valid 或提交路径。
  wire [1:0] sim_ooo_execute_count_w =
      {1'b0, u_top.u_core.u_ooo_core.execute0_valid_unused_w} +
      {1'b0, u_top.u_core.u_ooo_core.execute1_valid_unused_w};
  wire [1:0] sim_ooo_dispatch_count_w =
      {1'b0, u_top.u_core.u_ooo_core.core_dispatch0_fire_w} +
      {1'b0, (u_top.u_core.u_ooo_core.core_dispatch1_valid_w &&
              u_top.u_core.u_ooo_core.dispatch1_ready_w)};
  // 1M-cycle 性能桶保持只读旁路采样；同一 cycle 可同时归入多个桶。
  wire sim_ooo_fetch_busy_w =
      u_top.u_core.u_ooo_core.fetch_req_valid_o ||
      u_top.u_core.u_ooo_core.outstanding_valid_q ||
      (u_top.u_core.u_ooo_fetch_bridge.state_q != 4'd0);
  wire sim_ooo_mem_busy_w =
      u_top.u_core.u_ooo_core.pending_mem_q ||
      (u_top.u_core.u_ooo_mem_bridge.state_q != 4'd0) ||
      u_top.u_core.u_ooo_mem_bridge.mem0_req_fire_w;
  wire sim_ooo_axi_wait_w =
      (u_top.ifu_axi_arvalid_w && !u_top.ifu_axi_arready_w) ||
      (u_top.ifu_axi_rready_w && !u_top.ifu_axi_rvalid_w) ||
      (u_top.lsu_axi_arvalid_w && !u_top.lsu_axi_arready_w) ||
      (u_top.lsu_axi_rready_w && !u_top.lsu_axi_rvalid_w) ||
      (u_top.lsu_axi_awvalid_w && !u_top.lsu_axi_awready_w) ||
      (u_top.lsu_axi_wvalid_w && !u_top.lsu_axi_wready_w) ||
      (u_top.lsu_axi_bready_w && !u_top.lsu_axi_bvalid_w);
  wire sim_ooo_hazard_busy_w =
      u_top.u_core.u_ooo_core.core_commit1_block_w ||
      (u_top.u_core.u_ooo_core.fifo_has_packet_w &&
       u_top.u_core.u_ooo_core.can_run_w &&
       (u_top.u_core.u_ooo_core.dispatch_unsupported_w ||
        u_top.u_core.u_ooo_core.branch_spec_dispatch_block_w ||
        (u_top.u_core.u_ooo_core.dispatch_valid_w &&
         (!u_top.u_core.u_ooo_core.dispatch0_ready_w ||
          !u_top.u_core.u_ooo_core.dispatch1_ready_w))));
  wire sim_ooo_branch_flush_w =
      u_top.u_core.u_ooo_core.direct_frontend_flush_w ||
      u_top.u_core.u_ooo_core.branch_resolve_redirect_w ||
      u_top.u_core.u_ooo_core.branch_spec_redirect_w ||
      u_top.u_core.u_ooo_core.branch_resolve_untracked_redirect_w ||
      u_top.u_core.u_ooo_core.pending_jump_redirect_after_dispatch_w ||
      u_top.u_core.u_ooo_core.pending_jump_nolink_commit_w ||
      u_top.u_core.u_ooo_core.pending_branch_commit_resolve_w;
  wire sim_ooo_exception_busy_w =
      u_top.u_core.u_ooo_core.pending_arch_trap_q ||
      u_top.u_core.u_ooo_core.trap_valid_q ||
      u_top.u_core.u_ooo_core.core_trap_flush_q ||
      u_top.u_core.u_ooo_core.pending_system_ecall_trap_w ||
      u_top.u_core.u_ooo_core.pending_system_irq_q ||
      u_top.u_core.u_ooo_core.csr_trap_mem_valid_w ||
      u_top.u_core.u_ooo_core.csr_trap_ex_valid_w ||
      u_top.u_core.u_ooo_core.csr_trap_irq_valid_w;
  wire unused_ooo_sim_stat_w =
      sim_icache_access_w | sim_icache_hit_w | sim_icache_miss_w |
      sim_dcache_access_w | sim_dcache_hit_w | sim_dcache_miss_w |
      sim_dcache_store_access_w | sim_dcache_writeback_w |
      sim_dcache_write_through_w | sim_control_event_w |
      sim_bpu_lookup_event_w | sim_bpu_ret_resolve_w |
      sim_bpu_pred_taken_w | sim_bpu_resolve_correct_w |
      u_top.u_core.u_ooo_core.branch_bpu_update_valid_w |
      u_top.u_core.u_ooo_core.branch_bpu_update_correct_w |
      sim_ooo_pending_jalr_ret_w | sim_ooo_pending_jalr_lookup_w |
      sim_ooo_direct_ras_lookup_w | sim_ooo_pending_ras_lookup_w |
      sim_ooo_ras_lookup_event_w | sim_ooo_ras_hit_w |
      sim_ooo_btb_lookup_event_w | sim_ooo_ras_overflow_event_w |
      sim_ooo_fetch_busy_w | sim_ooo_mem_busy_w | sim_ooo_axi_wait_w |
      sim_ooo_hazard_busy_w | sim_ooo_branch_flush_w |
      sim_ooo_exception_busy_w |
      (|sim_ooo_execute_count_w) | (|sim_ooo_dispatch_count_w);
`endif

  localparam int UART_RX_POLL_SHIFT = `CONFIG_NPC_UART_RX_POLL_SHIFT;
  localparam logic [31:0] UART_RX_POLL_MASK =
      (UART_RX_POLL_SHIFT <= 0) ? 32'd0 :
      (UART_RX_POLL_SHIFT >= 32) ? 32'hffff_ffff :
      ((32'd1 << UART_RX_POLL_SHIFT) - 32'd1);
  wire uart_rx_poll_due_w =
      (UART_RX_POLL_MASK == 32'd0) ||
      ((uart_rx_poll_q & UART_RX_POLL_MASK) == 32'd0);

  always_ff @(posedge clk) begin
    int unsigned uart_rx_data_v;
    int uart_rx_has_data_v;

    if (rst) begin
      uart_rx_valid_q <= 1'b0;
      uart_rx_data_q <= 8'h00;
      uart_rx_poll_q <= 32'd0;
    end else begin
      uart_rx_poll_q <= uart_rx_poll_q + 32'd1;
      if (uart_rx_valid_q && !uart_rx_ready_w) begin
        uart_rx_valid_q <= uart_rx_valid_q;
        uart_rx_data_q <= uart_rx_data_q;
      end else if (uart_rx_poll_due_w) begin
        uart_rx_has_data_v = npc_uart_rx_pop(uart_rx_data_v);
        uart_rx_valid_q <= (uart_rx_has_data_v != 0);
        uart_rx_data_q <= uart_rx_data_v[7:0];
      end else begin
        uart_rx_valid_q <= 1'b0;
        uart_rx_data_q <= 8'h00;
      end
    end
  end

  // 仿真事件仍集中在顶层；真实 PMEM/MMIO 请求已经下沉到 AxiDpiSlave。
  always_ff @(posedge clk) begin
    if (rst) begin
      exit_reported_q <= 1'b0;
      uart_irq_prev_q <= 1'b0;
      plic_irq_prev_q <= 1'b0;
    end else begin
      if ((uart_irq_w != uart_irq_prev_q) ||
          (plic_external_irq_w != plic_irq_prev_q)) begin
        npc_irq_event(
          uart_irq_w ? 32'd1 : 32'd0,
          plic_external_irq_w ? 32'd1 : 32'd0
        );
      end
      uart_irq_prev_q <= uart_irq_w;
      plic_irq_prev_q <= plic_external_irq_w;

      // difftest: 非 pmem 的 load(MMIO 读, 如 goldfish timer)返回值依赖设备
      // 状态, ref 无法对齐 → 挂起 skip_ref(uart 同款粗粒度; 该 load 的
      // difftest_step 消费并以 dut 状态覆盖 ref)。
      if (u_top.u_core.u_ooo_mem_bridge.mem0_rsp_valid_o &&
          u_top.u_core.u_ooo_mem_bridge.mem0_rsp_ready_i &&
          !u_top.u_core.u_ooo_mem_bridge.write_q &&
          ((u_top.u_core.u_ooo_mem_bridge.paddr_q & `NPC_AXI_PMEM_MASK)
             != `NPC_AXI_PMEM_BASE) &&
          ((u_top.u_core.u_ooo_mem_bridge.paddr_q & 64'hffff_f000)
             != 64'h1000_0000)) begin
        npc_mmio_load_event();
      end

      if (uart_access_valid_w) begin
        // UART 已从 DPI 大从设备拆出；这里补回仿真侧输出和 difftest MMIO skip。
        npc_uart_event(
          uart_access_write_w ? 32'd1 : 32'd0,
          uart_tx_valid_w ? 32'd1 : 32'd0,
          {24'd0, uart_tx_data_w},
          {20'd0, uart_access_addr_w},
          uart_access_wdata_w,
          {{(32-`STRB_W){1'b0}}, uart_access_wstrb_w},
          uart_access_rdata_w
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

`ifdef CONFIG_NPC_BRANCH_STATS
      if (u_top.u_core.u_ooo_core.branch_bpu_update_valid_w) begin
        npc_bpu_resolve_event(
          32'd1,
          u_top.u_core.u_ooo_core.branch_bpu_update_pc_w[31:0],
          32'd0,
          32'd0,
          32'd0,
          u_top.u_core.u_ooo_core.branch_bpu_update_pred_taken_w ? 32'd1 : 32'd0,
          u_top.u_core.u_ooo_core.branch_bpu_update_taken_w ? 32'd1 : 32'd0,
          u_top.u_core.u_ooo_core.branch_bpu_update_correct_w ? 32'd1 : 32'd0
        );
      end

      if (sim_bpu_lookup_event_w) begin
        // OoO 侧 BPU 仍不进入端口 ABI；仿真顶层只读观察预测表 lookup 结果。
        // branch 走 OoO gshare/local，普通非 return JALR 走 OoO JALR BTB，return 走 OoO RAS。
        npc_bpu_lookup_event(
          u_top.u_core.u_ooo_core.branch_bpu_lookup_event_w ? 32'd1 : 32'd0,
          sim_ooo_btb_lookup_event_w ? 32'd1 : 32'd0,
          sim_ooo_ras_lookup_event_w ? 32'd1 : 32'd0,
          u_top.u_core.u_ooo_core.pending_jump_jalr_btb_hit_w ? 32'd1 : 32'd0,
          u_top.u_core.u_ooo_core.branch_bpu_lookup_bht_valid_w ? 32'd1 : 32'd0,
          sim_ooo_ras_lookup_event_w ? 32'd1 : 32'd0,
          sim_ooo_ras_hit_w ? 32'd1 : 32'd0,
          sim_ooo_ras_overflow_event_w ? 32'd1 : 32'd0
        );
      end
`endif

`ifdef CONFIG_NPC_CACHE_STATS
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
`endif

`ifdef CONFIG_NPC_OOO_STATS
      npc_ooo_cycle_event(
        {30'd0, core_retire_count_w},
        {30'd0, sim_ooo_execute_count_w},
        {30'd0, sim_ooo_dispatch_count_w},
        u_top.u_core.u_ooo_core.fetch_req_valid_o ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.fetch_req_fire_w ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.fetch_rsp_fire_w ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.fetch_rsp_enqueue_w ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.fetch_rsp_bypass_consumed_w ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.stop_pending_q ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.pending_branch_q ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.pending_jump_q ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.pending_mem_q ? 32'd1 : 32'd0,
	        u_top.u_core.u_ooo_core.synth_lane1_ret_pending_q ? 32'd1 : 32'd0,
	        u_top.u_core.u_ooo_core.branch_prefetch_req_fire_w ? 32'd1 : 32'd0,
	        (u_top.u_core.u_ooo_core.branch_prefetch_hit_available_w ||
	         u_top.u_core.u_ooo_core.jalr_prefetch_hit_available_w) ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_mem_bridge.mem0_req_fire_w ? 32'd1 : 32'd0,
        32'd0,  // mem1(双发射 load 第二端口)死硅删除:mem1_req_fire 恒 0
        (u_top.u_core.ooo_mem0_rsp_valid_w && u_top.u_core.ooo_mem0_rsp_ready_w) ? 32'd1 : 32'd0,
        32'd0,  // mem1_rsp_fire 恒 0(死硅删除)
        u_top.u_core.u_ooo_core.core_commit1_block_w ? 32'd1 : 32'd0,
        sim_ooo_fetch_busy_w ? 32'd1 : 32'd0,
        sim_ooo_mem_busy_w ? 32'd1 : 32'd0,
        sim_ooo_axi_wait_w ? 32'd1 : 32'd0,
        sim_ooo_hazard_busy_w ? 32'd1 : 32'd0,
        sim_ooo_branch_flush_w ? 32'd1 : 32'd0,
        sim_ooo_exception_busy_w ? 32'd1 : 32'd0,
        u_top.u_core.u_ooo_core.pending_branch_pc_q,
        u_top.u_core.u_ooo_core.pending_jump_pc_q
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

      if (u_top.u_core.u_ooo_core.csr_trap_mem_valid_w) begin
        npc_handled_trap_event(
          32'd0,
          {{(32-`TRAP_CAUSE_W){1'b0}}, u_top.u_core.u_ooo_core.csr_trap_mem_cause_w},
          u_top.u_core.u_ooo_core.csr_trap_mem_pc_w,
          u_top.u_core.u_ooo_core.csr_trap_mem_tval_w
        );
      end

      if (u_top.u_core.u_ooo_core.csr_trap_ex_valid_w) begin
        npc_handled_trap_event(
          32'd1,
          {{(32-`TRAP_CAUSE_W){1'b0}}, u_top.u_core.u_ooo_core.csr_trap_ex_cause_w},
          u_top.u_core.u_ooo_core.csr_trap_ex_pc_w,
          u_top.u_core.u_ooo_core.csr_trap_ex_tval_w
        );
        // difftest: ecall/ebreak 走 pending-trap 通道, 不产生 ROB/ctrl commit,
        // ref 单步会停在 ecall 本身等待——在 trap 注入拍补一条 commit 事件
        // (GPR 不变, next=trap 目标), 让 ref 同步跨过这条指令。
        if ((u_top.u_core.u_ooo_core.csr_trap_ex_cause_w == `TRAP_CAUSE_W'd8) ||
            (u_top.u_core.u_ooo_core.csr_trap_ex_cause_w == `TRAP_CAUSE_W'd9) ||
            (u_top.u_core.u_ooo_core.csr_trap_ex_cause_w == `TRAP_CAUSE_W'd11) ||
            (u_top.u_core.u_ooo_core.csr_trap_ex_cause_w == `TRAP_CAUSE_W'd3)) begin
          npc_commit_event(
            u_top.u_core.u_ooo_core.csr_trap_ex_pc_w,
            (u_top.u_core.u_ooo_core.csr_trap_ex_cause_w == `TRAP_CAUSE_W'd3) ?
              32'h00100073 : 32'h00000073,
            u_top.u_core.u_ooo_core.csr_trap_target_w,
            32'd0,
            32'd0,
            64'd0
          );
        end
      end

      if (u_top.u_core.u_ooo_core.csr_trap_irq_valid_w) begin
        npc_handled_trap_event(
          32'd2,
          {{(32-`TRAP_CAUSE_W){1'b0}}, u_top.u_core.u_ooo_core.pending_system_irq_cause_q},
          u_top.u_core.u_ooo_core.pending_system_pc_q,
          64'd0
        );
      end

    end
  end

endmodule
