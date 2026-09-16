`ifdef CONFIG_NPC_OOO_OWNER_TIMING

module NpcOooOwnerTimingProbe (
  input logic clk,
  input logic rst,
  input logic commit0_valid_i,
  input logic [63:0] commit0_pc_i,
  input logic commit1_valid_i,
  input logic [63:0] commit1_pc_i,
  input logic head0_valid_i,
  input logic [4:0] head0_token_i,
  input logic head1_valid_i,
  input logic [4:0] head1_token_i,

  input logic [3:0] bridge0_state_i,
  input logic [1:0] bridge0_active_kind_i,
  input logic [4:0] bridge0_active_token_i,
  input logic [1:0] bridge0_active_epoch_i,
  input logic bridge0_station_valid_i,
  input logic [1:0] bridge0_station_kind_i,
  input logic [4:0] bridge0_station_token_i,
  input logic [1:0] bridge0_station_epoch_i,
  input logic bridge0_request_valid_i,
  input logic bridge0_request_fire_i,
  input logic [1:0] bridge0_request_kind_i,
  input logic [4:0] bridge0_request_token_i,
  input logic [1:0] bridge0_request_epoch_i,
  input logic bridge0_aw_complete_i,
  input logic bridge0_w_complete_i,
  input logic bridge0_bvalid_i,
  input logic bridge0_stage_advance_i,
  input logic bridge0_station_cancel_i,
  input logic bridge0_active_drop_i,
  input logic bridge0_response_fire_i,

  input logic [3:0] bridge1_state_i,
  input logic [1:0] bridge1_active_kind_i,
  input logic [4:0] bridge1_active_token_i,
  input logic [1:0] bridge1_active_epoch_i,
  input logic bridge1_station_valid_i,
  input logic [1:0] bridge1_station_kind_i,
  input logic [4:0] bridge1_station_token_i,
  input logic [1:0] bridge1_station_epoch_i,
  input logic bridge1_request_valid_i,
  input logic bridge1_request_fire_i,
  input logic [1:0] bridge1_request_kind_i,
  input logic [4:0] bridge1_request_token_i,
  input logic [1:0] bridge1_request_epoch_i,
  input logic bridge1_aw_complete_i,
  input logic bridge1_w_complete_i,
  input logic bridge1_bvalid_i,
  input logic bridge1_stage_advance_i,
  input logic bridge1_station_cancel_i,
  input logic bridge1_active_drop_i,
  input logic bridge1_response_fire_i
);

  import "DPI-C" function void npc_ooo_owner_timing_event(
    input int unsigned reset,
    input int unsigned commit0_valid,
    input longint unsigned commit0_pc,
    input int unsigned commit1_valid,
    input longint unsigned commit1_pc,
    input int unsigned head0_valid,
    input int unsigned head0_token,
    input int unsigned head1_valid,
    input int unsigned head1_token,
    input longint unsigned bridge0_sample,
    input longint unsigned bridge1_sample
  );

  logic [63:0] bridge0_sample_w;
  logic [63:0] bridge1_sample_w;

  always_comb begin
    bridge0_sample_w = 64'b0;
    bridge0_sample_w[3:0] = bridge0_state_i;
    bridge0_sample_w[5:4] = bridge0_active_kind_i;
    bridge0_sample_w[10:6] = bridge0_active_token_i;
    bridge0_sample_w[12:11] = bridge0_active_epoch_i;
    bridge0_sample_w[13] = bridge0_station_valid_i;
    bridge0_sample_w[15:14] = bridge0_station_kind_i;
    bridge0_sample_w[20:16] = bridge0_station_token_i;
    bridge0_sample_w[22:21] = bridge0_station_epoch_i;
    bridge0_sample_w[23] = bridge0_request_valid_i;
    bridge0_sample_w[24] = bridge0_request_fire_i;
    bridge0_sample_w[26:25] = bridge0_request_kind_i;
    bridge0_sample_w[31:27] = bridge0_request_token_i;
    bridge0_sample_w[33:32] = bridge0_request_epoch_i;
    bridge0_sample_w[34] = bridge0_aw_complete_i;
    bridge0_sample_w[35] = bridge0_w_complete_i;
    bridge0_sample_w[36] = bridge0_bvalid_i;
    bridge0_sample_w[37] = bridge0_stage_advance_i;
    bridge0_sample_w[38] = bridge0_station_cancel_i;
    bridge0_sample_w[39] = bridge0_active_drop_i;
    bridge0_sample_w[40] = bridge0_response_fire_i;

    bridge1_sample_w = 64'b0;
    bridge1_sample_w[3:0] = bridge1_state_i;
    bridge1_sample_w[5:4] = bridge1_active_kind_i;
    bridge1_sample_w[10:6] = bridge1_active_token_i;
    bridge1_sample_w[12:11] = bridge1_active_epoch_i;
    bridge1_sample_w[13] = bridge1_station_valid_i;
    bridge1_sample_w[15:14] = bridge1_station_kind_i;
    bridge1_sample_w[20:16] = bridge1_station_token_i;
    bridge1_sample_w[22:21] = bridge1_station_epoch_i;
    bridge1_sample_w[23] = bridge1_request_valid_i;
    bridge1_sample_w[24] = bridge1_request_fire_i;
    bridge1_sample_w[26:25] = bridge1_request_kind_i;
    bridge1_sample_w[31:27] = bridge1_request_token_i;
    bridge1_sample_w[33:32] = bridge1_request_epoch_i;
    bridge1_sample_w[34] = bridge1_aw_complete_i;
    bridge1_sample_w[35] = bridge1_w_complete_i;
    bridge1_sample_w[36] = bridge1_bvalid_i;
    bridge1_sample_w[37] = bridge1_stage_advance_i;
    bridge1_sample_w[38] = bridge1_station_cancel_i;
    bridge1_sample_w[39] = bridge1_active_drop_i;
    bridge1_sample_w[40] = bridge1_response_fire_i;
  end

  always @(posedge clk) begin
    npc_ooo_owner_timing_event(
      rst ? 32'd1 : 32'd0,
      commit0_valid_i ? 32'd1 : 32'd0,
      commit0_pc_i,
      commit1_valid_i ? 32'd1 : 32'd0,
      commit1_pc_i,
      head0_valid_i ? 32'd1 : 32'd0,
      {27'd0, head0_token_i},
      head1_valid_i ? 32'd1 : 32'd0,
      {27'd0, head1_token_i},
      bridge0_sample_w,
      bridge1_sample_w
    );
  end
endmodule

bind NpcSimTop NpcOooOwnerTimingProbe u_npc_ooo_owner_timing_probe (
  .clk(clk),
  .rst(rst),
  .commit0_valid_i(core_commit0_valid_w && !core_commit0_exception_w),
  .commit0_pc_i(core_commit0_pc_w),
  .commit1_valid_i(core_commit1_valid_w && !core_commit1_exception_w),
  .commit1_pc_i(core_commit1_pc_w),
  .head0_valid_i(sim_head0_mem_token_live_w),
  .head0_token_i(sim_head0_mem_token_r),
  .head1_valid_i(sim_head1_mem_token_live_w),
  .head1_token_i(sim_head1_mem_token_r),

  .bridge0_state_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.state_q),
  .bridge0_active_kind_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.active_owner_kind_q),
  .bridge0_active_token_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.active_owner_token_q),
  .bridge0_active_epoch_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.active_mmu_epoch_q),
  .bridge0_station_valid_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.stg_valid_q),
  .bridge0_station_kind_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.stg_owner_kind_q),
  .bridge0_station_token_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.stg_owner_token_q),
  .bridge0_station_epoch_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.stg_mmu_epoch_q),
  .bridge0_request_valid_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.mem0_req_valid_i),
  .bridge0_request_fire_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.mem0_req_fire_w),
  .bridge0_request_kind_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.mem0_req_owner_kind_i),
  .bridge0_request_token_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.mem0_req_owner_token_i),
  .bridge0_request_epoch_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.mem0_req_mmu_epoch_i),
  .bridge0_aw_complete_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.aw_done_q ||
                         u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.aw_fire_w),
  .bridge0_w_complete_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.w_done_q ||
                        u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.w_fire_w),
  .bridge0_bvalid_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.lsu_axi_bvalid_i),
  .bridge0_stage_advance_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.stage_advance_w),
  .bridge0_station_cancel_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.station_drop_terminal_w),
  .bridge0_active_drop_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.active_drop_terminal_r),
  .bridge0_response_fire_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.mem0_rsp_valid_o &&
      u_top.u_core.u_ooo_dual_mem_bridge.u_bridge0.mem0_rsp_ready_i),

  .bridge1_state_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.state_q),
  .bridge1_active_kind_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.active_owner_kind_q),
  .bridge1_active_token_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.active_owner_token_q),
  .bridge1_active_epoch_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.active_mmu_epoch_q),
  .bridge1_station_valid_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.stg_valid_q),
  .bridge1_station_kind_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.stg_owner_kind_q),
  .bridge1_station_token_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.stg_owner_token_q),
  .bridge1_station_epoch_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.stg_mmu_epoch_q),
  .bridge1_request_valid_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.mem0_req_valid_i),
  .bridge1_request_fire_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.mem0_req_fire_w),
  .bridge1_request_kind_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.mem0_req_owner_kind_i),
  .bridge1_request_token_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.mem0_req_owner_token_i),
  .bridge1_request_epoch_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.mem0_req_mmu_epoch_i),
  .bridge1_aw_complete_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.aw_done_q ||
                         u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.aw_fire_w),
  .bridge1_w_complete_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.w_done_q ||
                        u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.w_fire_w),
  .bridge1_bvalid_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.lsu_axi_bvalid_i),
  .bridge1_stage_advance_i(u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.stage_advance_w),
  .bridge1_station_cancel_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.station_drop_terminal_w),
  .bridge1_active_drop_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.active_drop_terminal_r),
  .bridge1_response_fire_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.mem0_rsp_valid_o &&
      u_top.u_core.u_ooo_dual_mem_bridge.u_bridge1.mem0_rsp_ready_i)
);

`endif
