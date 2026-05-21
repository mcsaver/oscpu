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

module NpcSimTop (
  input logic clk,
  input logic rst,

  output logic [`XLEN-1:0] debug_pc_o,
  output logic [`CORE_STATE_W-1:0] debug_state_o
);

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
  logic bus_axi_arvalid_w;
  logic bus_axi_arready_w;
  logic [`XLEN-1:0] bus_axi_araddr_w;
  logic bus_axi_aruser_w;
  logic bus_axi_rvalid_w;
  logic bus_axi_rready_w;
  logic [`XLEN-1:0] bus_axi_rdata_w;
  logic [1:0] bus_axi_rresp_w;
  logic bus_axi_awvalid_w;
  logic bus_axi_awready_w;
  logic [`XLEN-1:0] bus_axi_awaddr_w;
  logic bus_axi_wvalid_w;
  logic bus_axi_wready_w;
  logic [`XLEN-1:0] bus_axi_wdata_w;
  logic [3:0] bus_axi_wstrb_w;
  logic bus_axi_bvalid_w;
  logic bus_axi_bready_w;
  logic [1:0] bus_axi_bresp_w;
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

  function automatic logic sim_is_link_reg(input logic [4:0] reg_idx);
    begin
      sim_is_link_reg = (reg_idx == 5'd1) || (reg_idx == 5'd5);
    end
  endfunction

  NpcCore u_core (
    .clk(clk),
    .rst(rst),
    .ifu_axi_arvalid_o(ifu_axi_arvalid_w),
    .ifu_axi_arready_i(ifu_axi_arready_w),
    .ifu_axi_araddr_o(ifu_axi_araddr_w),
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
    /* verilator lint_off PINCONNECTEMPTY */
    .commit_valid_o(),
    .commit_pc_o(),
    .commit_inst_o(),
    .commit_next_pc_o(),
    .commit_rd_en_o(),
    .commit_rd_addr_o(),
    .commit_rd_data_o(),
    .trap_valid_o(),
    .trap_cause_o(),
    .trap_pc_o(),
    .trap_tval_o(),
    .exit_valid_o(),
    .exit_is_ecall_o(),
    .exit_is_ebreak_o(),
    .exit_code_o(),
    .halted_o(),
    .debug_pc_o(debug_pc_o),
    .debug_state_o(debug_state_o),
    .debug_gprs_o()
    /* verilator lint_on PINCONNECTEMPTY */
  );

  NpcAxiBus #(
    .S_COUNT(1),
    .DEFAULT_SLAVE(0),
    .SLAVE_BASE(32'h0000_0000),
    .SLAVE_MASK(32'h0000_0000)
  ) u_bus (
    .clk(clk),
    .rst(rst),
    .ifu_axi_arvalid_i(ifu_axi_arvalid_w),
    .ifu_axi_arready_o(ifu_axi_arready_w),
    .ifu_axi_araddr_i(ifu_axi_araddr_w),
    .ifu_axi_abort_i(u_core.ex_any_flush_w),
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

  AxiDpiSlave u_dpi_slave (
    .clk(clk),
    .rst(rst),
    .s_axi_arvalid_i(bus_axi_arvalid_w),
    .s_axi_arready_o(bus_axi_arready_w),
    .s_axi_araddr_i(bus_axi_araddr_w),
    .s_axi_aruser_i(bus_axi_aruser_w),
    .s_axi_rvalid_o(bus_axi_rvalid_w),
    .s_axi_rready_i(bus_axi_rready_w),
    .s_axi_rdata_o(bus_axi_rdata_w),
    .s_axi_rresp_o(bus_axi_rresp_w),
    .s_axi_awvalid_i(bus_axi_awvalid_w),
    .s_axi_awready_o(bus_axi_awready_w),
    .s_axi_awaddr_i(bus_axi_awaddr_w),
    .s_axi_wvalid_i(bus_axi_wvalid_w),
    .s_axi_wready_o(bus_axi_wready_w),
    .s_axi_wdata_i(bus_axi_wdata_w),
    .s_axi_wstrb_i(bus_axi_wstrb_w),
    .s_axi_bvalid_o(bus_axi_bvalid_w),
    .s_axi_bready_i(bus_axi_bready_w),
    .s_axi_bresp_o(bus_axi_bresp_w)
  );

  // 仿真兼容事件不进入 NpcCore 端口 ABI；DPI 顶层用层次化引用观察 RTL 内部 flush。
  assign sim_cache_flush_w = u_core.cache_flush_valid_w;
  // 性能统计属于仿真观测，不进入 NpcCore 端口 ABI；这里直接观察 RTL cache CPU-side 握手和 lookup 结果。
  assign sim_icache_access_w = u_core.u_icache.cpu_req_valid_i &&
                               u_core.u_icache.cpu_req_ready_o &&
                               u_core.u_icache.cur_cacheable_w &&
                               !u_core.u_icache.cur_misaligned_w;
  assign sim_icache_hit_w = sim_icache_access_w && u_core.u_icache.cur_lookup_hit_w;
  assign sim_icache_miss_w = sim_icache_access_w && !u_core.u_icache.cur_lookup_hit_w;

  assign sim_dcache_access_w = u_core.u_dcache.cpu_req_valid_i &&
                               u_core.u_dcache.cpu_req_ready_o &&
                               u_core.u_dcache.cur_req_cacheable_w &&
                               (!u_core.u_dcache.cpu_req_write_i ||
                                (u_core.u_dcache.cpu_req_wstrb_i != 4'b0000));
  assign sim_dcache_hit_w = sim_dcache_access_w && u_core.u_dcache.cur_req_lookup_hit_w;
  assign sim_dcache_miss_w = sim_dcache_access_w && !u_core.u_dcache.cur_req_lookup_hit_w;
  assign sim_dcache_store_access_w = sim_dcache_access_w && u_core.u_dcache.cpu_req_write_i;
  assign sim_dcache_writeback_w = u_core.u_dcache.wb_axi_write_fire_w;
  assign sim_dcache_write_through_w = 1'b0;
  assign sim_control_event_w = u_core.bpu_update_valid_w;
  assign sim_bpu_lookup_event_w = u_core.u_if_stage.u_branch_predictor.predict_valid_i &&
                                  u_core.u_if_stage.bpu_predict_control_w;
  assign sim_bpu_ret_resolve_w = u_core.id_ex_jalr_w &&
                                 !sim_is_link_reg(u_core.id_ex_inst_q[11:7]) &&
                                 sim_is_link_reg(u_core.id_ex_inst_q[19:15]);
  assign sim_bpu_pred_taken_w = u_core.id_ex_pred_pc_q != u_core.ex_pc_plus4_w;
  assign sim_bpu_resolve_correct_w = u_core.id_ex_pred_pc_q == u_core.ex_control_next_pc_w;

  // 仿真事件仍集中在顶层；真实 PMEM/MMIO 请求已经下沉到 AxiDpiSlave。
  always_ff @(posedge clk) begin
    if (rst) begin
      exit_reported_q <= 1'b0;
    end else begin
      // commit/trap/exit 只作为仿真事件推给宿主侧，避免把宽调试总线做成 Verilator 顶层 IO。
      if (u_core.mem_wb_load_w && !u_core.halt_q && !u_core.fatal_trap_q) begin
        npc_commit_event(
          u_core.ex_mem_pc_q,
          u_core.ex_mem_inst_q,
          u_core.ex_mem_next_pc_q,
          (u_core.ex_mem_need_wb_q && u_core.ex_mem_rd_en_q &&
           (u_core.ex_mem_rd_idx_q != {`REG_ADDR_W{1'b0}})) ? 32'd1 : 32'd0,
          {{(32-`REG_ADDR_W){1'b0}}, u_core.ex_mem_rd_idx_q},
          u_core.mem_wb_load_wb_data_w
        );
      end

      if (sim_control_event_w) begin
        npc_control_flow_event(
          u_core.id_ex_branch_w ? 32'd1 : 32'd0,
          (u_core.id_ex_branch_w && u_core.ex_control_redirect_w) ? 32'd1 : 32'd0,
          u_core.id_ex_jal_w ? 32'd1 : 32'd0,
          u_core.id_ex_jalr_w ? 32'd1 : 32'd0
        );
        npc_bpu_resolve_event(
          u_core.id_ex_branch_w ? 32'd1 : 32'd0,
          u_core.id_ex_pc_q,
          u_core.id_ex_jal_w ? 32'd1 : 32'd0,
          u_core.id_ex_jalr_w ? 32'd1 : 32'd0,
          sim_bpu_ret_resolve_w ? 32'd1 : 32'd0,
          sim_bpu_pred_taken_w ? 32'd1 : 32'd0,
          u_core.ex_control_redirect_w ? 32'd1 : 32'd0,
          sim_bpu_resolve_correct_w ? 32'd1 : 32'd0
        );
      end

      if (sim_bpu_lookup_event_w) begin
        // lookup 统计按预测发生点计数；最终正确率仍由 EX resolve 事件给出。
        npc_bpu_lookup_event(
          u_core.u_if_stage.bpu_predict_branch_w ? 32'd1 : 32'd0,
          (u_core.u_if_stage.bpu_predict_jalr_w &&
           !u_core.u_if_stage.bpu_predict_ras_hit_w) ? 32'd1 : 32'd0,
          u_core.u_if_stage.bpu_predict_ret_w ? 32'd1 : 32'd0,
          u_core.u_if_stage.bpu_predict_btb_hit_w ? 32'd1 : 32'd0,
          u_core.u_if_stage.bpu_predict_bht_valid_w ? 32'd1 : 32'd0,
          u_core.u_if_stage.bpu_predict_ras_lookup_w ? 32'd1 : 32'd0,
          u_core.u_if_stage.bpu_predict_ras_hit_w ? 32'd1 : 32'd0,
          u_core.u_if_stage.bpu_predict_ras_overflow_w ? 32'd1 : 32'd0
        );
      end

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

      if (u_core.exit_valid_o && !exit_reported_q) begin
        exit_reported_q <= 1'b1;
        npc_exit_event(
          u_core.exit_is_ebreak_o ? 32'd1 : 32'd0,
          u_core.exit_is_ecall_o ? 32'd1 : 32'd0,
          u_core.exit_code_o,
          u_core.stop_pc_q
        );
      end

      if (u_core.mem_fault_w && (u_core.trap_target_w == {`XLEN{1'b0}})) begin
        npc_trap_event(
          {{(32-`TRAP_CAUSE_W){1'b0}},
           (u_core.ex_mem_load_w ? `EXC_LOAD_ACCESS_FAULT : `EXC_STORE_ACCESS_FAULT)},
          u_core.ex_mem_pc_q,
          u_core.ex_mem_mem_addr_q
        );
      end else if (u_core.ex_exception_w && u_core.ex_exception_fatal_w) begin
        npc_trap_event(
          {{(32-`TRAP_CAUSE_W){1'b0}}, u_core.ex_exception_cause_w},
          u_core.id_ex_pc_q,
          u_core.ex_exception_tval_w
        );
      end

      if (sim_cache_flush_w) begin
        npc_cache_flush_all();
      end
    end
  end

endmodule
