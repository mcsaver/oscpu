`include "define.v"

// DPI-C 仿真顶层：只负责把可综合 NpcCore 的总线/flush 事件桥接到宿主侧模型。
// 该文件不能进入 RTL_CORE_SRCS/STA_RTL_FILES。
import "DPI-C" task npc_ifetch(
  input int unsigned addr,
  output int unsigned data,
  output bit error
);

import "DPI-C" task npc_mem_read(
  input int unsigned addr,
  output int unsigned data,
  output bit error
);

import "DPI-C" task npc_mem_write(
  input int unsigned addr,
  input int unsigned data,
  input int unsigned mask,
  output bit error
);

import "DPI-C" task npc_cache_flush_all();

module NpcSimTop (
  input logic clk,
  input logic rst,

  output logic commit_valid_o,
  output logic [`XLEN-1:0] commit_pc_o,
  output logic [`INST_W-1:0] commit_inst_o,
  output logic [`XLEN-1:0] commit_next_pc_o,
  output logic commit_rd_en_o,
  output logic [`REG_ADDR_W-1:0] commit_rd_addr_o,
  output logic [`XLEN-1:0] commit_rd_data_o,

  output logic trap_valid_o,
  output logic [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output logic [`XLEN-1:0] trap_pc_o,
  output logic [`XLEN-1:0] trap_tval_o,
  output logic exit_valid_o,
  output logic exit_is_ecall_o,
  output logic exit_is_ebreak_o,
  output logic [`XLEN-1:0] exit_code_o,
  output logic halted_o,

  output logic [`XLEN-1:0] debug_pc_o,
  output logic [`CORE_STATE_W-1:0] debug_state_o,
  output logic [`XLEN * `REG_NUM - 1:0] debug_gprs_o
);

  logic ifu_req_valid_w;
  logic ifu_req_ready_w;
  logic [`XLEN-1:0] ifu_req_addr_w;
  logic ifu_rsp_valid_q;
  logic [`XLEN-1:0] ifu_rsp_data_q;
  logic ifu_rsp_error_q;

  logic lsu_req_valid_w;
  logic lsu_req_ready_w;
  logic lsu_req_write_w;
  logic [`XLEN-1:0] lsu_req_addr_w;
  logic [`XLEN-1:0] lsu_req_wdata_w;
  logic [3:0] lsu_req_wstrb_w;
  logic lsu_rsp_valid_q;
  logic [`XLEN-1:0] lsu_rsp_rdata_q;
  logic lsu_rsp_error_q;
  logic sim_cache_flush_w;

  assign ifu_req_ready_w = 1'b1;
  assign lsu_req_ready_w = 1'b1;

  NpcCore u_core (
    .clk(clk),
    .rst(rst),
    .ifu_req_valid_o(ifu_req_valid_w),
    .ifu_req_ready_i(ifu_req_ready_w),
    .ifu_req_addr_o(ifu_req_addr_w),
    .ifu_rsp_valid_i(ifu_rsp_valid_q),
    .ifu_rsp_data_i(ifu_rsp_data_q),
    .ifu_rsp_error_i(ifu_rsp_error_q),
    .lsu_req_valid_o(lsu_req_valid_w),
    .lsu_req_ready_i(lsu_req_ready_w),
    .lsu_req_write_o(lsu_req_write_w),
    .lsu_req_addr_o(lsu_req_addr_w),
    .lsu_req_wdata_o(lsu_req_wdata_w),
    .lsu_req_wstrb_o(lsu_req_wstrb_w),
    .lsu_rsp_valid_i(lsu_rsp_valid_q),
    .lsu_rsp_rdata_i(lsu_rsp_rdata_q),
    .lsu_rsp_error_i(lsu_rsp_error_q),
    .commit_valid_o(commit_valid_o),
    .commit_pc_o(commit_pc_o),
    .commit_inst_o(commit_inst_o),
    .commit_next_pc_o(commit_next_pc_o),
    .commit_rd_en_o(commit_rd_en_o),
    .commit_rd_addr_o(commit_rd_addr_o),
    .commit_rd_data_o(commit_rd_data_o),
    .trap_valid_o(trap_valid_o),
    .trap_cause_o(trap_cause_o),
    .trap_pc_o(trap_pc_o),
    .trap_tval_o(trap_tval_o),
    .exit_valid_o(exit_valid_o),
    .exit_is_ecall_o(exit_is_ecall_o),
    .exit_is_ebreak_o(exit_is_ebreak_o),
    .exit_code_o(exit_code_o),
    .halted_o(halted_o),
    .debug_pc_o(debug_pc_o),
    .debug_state_o(debug_state_o),
    .debug_gprs_o(debug_gprs_o)
  );

  // 仿真兼容事件不进入 NpcCore 端口 ABI；DPI 顶层用层次化引用观察 RTL 内部 flush。
  assign sim_cache_flush_w = u_core.cache_flush_valid_w;

  // 这里故意把 DPI 总线做成“一拍请求、一拍返回”，避免在组合路径里重复调用 C++ 侧带副作用的总线函数。
  always_ff @(posedge clk) begin
    int unsigned bus_data_v;
    int unsigned write_mask_v;
    bit bus_error_v;

    if (rst) begin
      ifu_rsp_valid_q <= 1'b0;
      ifu_rsp_data_q <= {`XLEN{1'b0}};
      ifu_rsp_error_q <= 1'b0;
      lsu_rsp_valid_q <= 1'b0;
      lsu_rsp_rdata_q <= {`XLEN{1'b0}};
      lsu_rsp_error_q <= 1'b0;
    end else begin
      ifu_rsp_valid_q <= 1'b0;
      ifu_rsp_error_q <= 1'b0;
      lsu_rsp_valid_q <= 1'b0;
      lsu_rsp_error_q <= 1'b0;

      if (sim_cache_flush_w) begin
        npc_cache_flush_all();
      end

      if (ifu_req_valid_w && ifu_req_ready_w) begin
        npc_ifetch(ifu_req_addr_w, bus_data_v, bus_error_v);
        ifu_rsp_valid_q <= 1'b1;
        ifu_rsp_data_q <= bus_data_v[`XLEN-1:0];
        ifu_rsp_error_q <= bus_error_v;
      end

      if (lsu_req_valid_w && lsu_req_ready_w) begin
        if (lsu_req_write_w) begin
          write_mask_v = {28'b0, lsu_req_wstrb_w};
          npc_mem_write(lsu_req_addr_w, lsu_req_wdata_w, write_mask_v, bus_error_v);
          lsu_rsp_rdata_q <= {`XLEN{1'b0}};
        end else begin
          npc_mem_read(lsu_req_addr_w, bus_data_v, bus_error_v);
          lsu_rsp_rdata_q <= bus_data_v[`XLEN-1:0];
        end

        lsu_rsp_valid_q <= 1'b1;
        lsu_rsp_error_q <= bus_error_v;
      end

    end
  end

endmodule
