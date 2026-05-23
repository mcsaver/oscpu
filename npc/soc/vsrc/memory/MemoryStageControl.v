`include "define.v"

module MemoryStageControl (
  input clk,
  input rst,
  input update_en_i,
  input clear_i,

  input ex_valid_i,
  input ex_load_i,
  input ex_store_i,

  output lsu_req_valid_o,
  input lsu_req_ready_i,
  input lsu_rsp_valid_i,
  output lsu_rsp_ready_o,
  input lsu_rsp_error_i,

  output response_o,
  output fault_o,
  output pending_o
);

  reg mem_pending_q;

  wire ex_is_mem_w = ex_load_i | ex_store_i;
  wire req_fire_w = lsu_req_valid_o & lsu_req_ready_i;
  wire rsp_fire_w = lsu_rsp_valid_i & lsu_rsp_ready_o;
  wire pending_rsp_w = mem_pending_q & rsp_fire_w;
  wire same_cycle_rsp_w = req_fire_w & rsp_fire_w;

  // 访存控制面只管理“已发请求但尚未响应”的生命周期，数据 lane 由 LSU 处理。
  assign lsu_req_valid_o = ex_valid_i & ex_is_mem_w & (~mem_pending_q);
  // MEM 级持有有效访存指令时即可接收 cache 响应；是否推进流水由 update_en_i 控制。
  assign lsu_rsp_ready_o = ex_valid_i & ex_is_mem_w;
  // DCache load hit 允许 req/rsp 同周期完成，此时不需要进入 pending 状态。
  assign response_o = ex_valid_i & ex_is_mem_w & (pending_rsp_w | same_cycle_rsp_w);
  assign fault_o = response_o & lsu_rsp_error_i;
  assign pending_o = mem_pending_q;

  always @(posedge clk) begin
    if (rst) begin
      mem_pending_q <= 1'b0;
    end else if (clear_i) begin
      mem_pending_q <= 1'b0;
    end else if (update_en_i) begin
      if (response_o) begin
        mem_pending_q <= 1'b0;
      end else if (req_fire_w) begin
        mem_pending_q <= 1'b1;
      end
    end
  end

endmodule
