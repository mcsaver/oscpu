`ifdef CONFIG_NPC_OOO_WRITE_PATH_BUBBLE

// Diagnostic-only observer.  It is injected by write-path-bubble.mk and is
// deliberately absent from the production RTL file list.
module NpcOooWritePathBubbleProbe (
  input logic clk,
  input logic rst,
  input logic commit0_valid_i,
  input logic [63:0] commit0_pc_i,
  input logic commit1_valid_i,
  input logic [63:0] commit1_pc_i,

  input logic [2:0] arb_state_i,
  input logic arb_capture_valid_i,
  input logic arb_capture_write_i,
  input logic arb_capture_owner_i,
  input logic arb_request_illegal_i,
  input logic arb_lane0_request_i,
  input logic arb_lane1_request_i,
  input logic arb_lane0_awvalid_i,
  input logic arb_lane0_wvalid_i,
  input logic arb_lane1_awvalid_i,
  input logic arb_lane1_wvalid_i,
  input logic arb_down_awready_i,
  input logic arb_down_wready_i,

  input logic [15:0] xbar_grant_valid_i,
  input logic [15:0] xbar_grant_master_i,
  input logic [15:0] xbar_active_i,
  input logic [15:0] xbar_target_awready_i,
  input logic [15:0] xbar_target_wready_i,
  input logic [15:0] xbar_target_bvalid_i,
  input logic [1:0] xbar_master_awvalid_i,
  input logic [1:0] xbar_master_awready_i,
  input logic [1:0] xbar_master_wvalid_i,
  input logic [1:0] xbar_master_wready_i,
  input logic [1:0] xbar_master_aw_hold_i,
  input logic [1:0] xbar_master_w_hold_i,
  input logic [3:0] xbar_live_target0_i,
  input logic [3:0] xbar_live_target1_i,
  input logic [3:0] xbar_hold_target0_i,
  input logic [3:0] xbar_hold_target1_i,

  input logic [3:0] retire0_reason_i,
  input logic [2:0] retire0_request_detail_i,
  input logic [3:0] retire1_reason_i,
  input logic [2:0] retire1_request_detail_i
);

  localparam logic [2:0] ARB_S_IDLE = 3'd0;
  localparam logic [3:0] RETIRE_MEMORY_REQUEST_OUTSTANDING = 4'd7;
  localparam logic [2:0] REQUEST_AXI_WRITE_RESPONSE = 3'd6;

  logic [63:0] start_pc_q;
  logic [63:0] end_pc_q;
  integer start_plusarg_ok_q;
  integer end_plusarg_ok_q;

  logic start_seen_q;
  logic end_seen_q;
  logic roi_active_q;
  logic emit_pending_q;
  logic emitted_q;
  logic overflow_q;
  logic [63:0] invalid_q;
  logic [63:0] roi_cycles_q;

  logic [63:0] arb_events_q;
  logic [63:0] arb_source11_q;
  logic [63:0] arb_source10_q;
  logic [63:0] arb_source01_q;
  logic [63:0] arb_source00_q;
  logic [63:0] arb_ready11_q;
  logic [63:0] arb_ready10_q;
  logic [63:0] arb_ready01_q;
  logic [63:0] arb_ready00_q;
  logic [63:0] arb_lane0_q;
  logic [63:0] arb_lane1_q;
  logic [63:0] arb_contention_q;
  logic [63:0] arb_strict_opportunity_q;

  logic [63:0] xbar_grant_cycles_q;
  logic [63:0] xbar_grants_q;
  logic [63:0] xbar_ready11_q;
  logic [63:0] xbar_ready10_q;
  logic [63:0] xbar_ready01_q;
  logic [63:0] xbar_ready00_q;
  logic [63:0] xbar_master0_q;
  logic [63:0] xbar_master1_q;
  logic [63:0] xbar_grant_bvalid_q;
  logic [63:0] xbar_head0_write_response_q;
  logic [63:0] xbar_head1_write_response_q;
  logic [63:0] xbar_head_any_write_response_q;
  logic [63:0] xbar_strict_opportunity_q;
  logic [63:0] xbar_target_q [0:15];

  logic [63:0] live_pairs_q;
  logic [63:0] live_master0_q;
  logic [63:0] live_master1_q;
  logic [63:0] live_target_inactive_q;
  logic [63:0] live_target_active_q;
  logic [63:0] live_older_complete_holder_q;
  logic [63:0] live_same_target_conflict_q;
  logic [63:0] live_narrow_eligible_q;

  logic start_hit_v;
  logic end_hit_v;
  logic arb_src_aw_v;
  logic arb_src_w_v;
  logic [1:0] grant_owner_seen_v;
  logic [1:0] live_pair_v;
  logic [3:0] live_target_v;
  logic live_other_conflict_v;
  logic any_old_complete_holder_v;
  integer i;
  integer j;

  wire arb_conservation_w =
      (arb_events_q ==
       (arb_source11_q + arb_source10_q + arb_source01_q + arb_source00_q)) &&
      (arb_events_q ==
       (arb_ready11_q + arb_ready10_q + arb_ready01_q + arb_ready00_q)) &&
      (arb_events_q == (arb_lane0_q + arb_lane1_q));
  wire xbar_ready_conservation_w =
      (xbar_grants_q ==
       (xbar_ready11_q + xbar_ready10_q + xbar_ready01_q + xbar_ready00_q));
  wire xbar_master_conservation_w =
      (xbar_grants_q == (xbar_master0_q + xbar_master1_q));
  wire live_conservation_w =
      (live_pairs_q == (live_master0_q + live_master1_q)) &&
      (live_pairs_q == (live_target_inactive_q + live_target_active_q));

  logic [63:0] xbar_target_sum_w;
  always_comb begin
    xbar_target_sum_w = 64'd0;
    for (j = 0; j < 16; j = j + 1)
      xbar_target_sum_w = xbar_target_sum_w + xbar_target_q[j];
  end
  wire xbar_target_conservation_w = (xbar_grants_q == xbar_target_sum_w);

  initial begin
    start_pc_q = 64'd0;
    end_pc_q = 64'd0;
    start_plusarg_ok_q =
        $value$plusargs("WRITE_PATH_START_PC=%h", start_pc_q);
    end_plusarg_ok_q =
        $value$plusargs("WRITE_PATH_END_PC=%h", end_pc_q);
  end

  /* verilator lint_off BLKSEQ */
  task automatic inc_counter(inout logic [63:0] counter);
    begin
      if (&counter)
        overflow_q = 1'b1;
      else
        counter = counter + 64'd1;
    end
  endtask

  task automatic classify_matrix(
    input logic first,
    input logic second,
    inout logic [63:0] count11,
    inout logic [63:0] count10,
    inout logic [63:0] count01,
    inout logic [63:0] count00
  );
    begin
      case ({first, second})
        2'b11: inc_counter(count11);
        2'b10: inc_counter(count10);
        2'b01: inc_counter(count01);
        2'b00: inc_counter(count00);
        default: inc_counter(invalid_q);
      endcase
    end
  endtask

  always @(posedge clk) begin
    if (rst) begin
      start_seen_q = 1'b0;
      end_seen_q = 1'b0;
      roi_active_q = 1'b0;
      emit_pending_q = 1'b0;
      emitted_q = 1'b0;
      overflow_q = 1'b0;
      invalid_q = 64'd0;
      roi_cycles_q = 64'd0;
      arb_events_q = 64'd0;
      arb_source11_q = 64'd0;
      arb_source10_q = 64'd0;
      arb_source01_q = 64'd0;
      arb_source00_q = 64'd0;
      arb_ready11_q = 64'd0;
      arb_ready10_q = 64'd0;
      arb_ready01_q = 64'd0;
      arb_ready00_q = 64'd0;
      arb_lane0_q = 64'd0;
      arb_lane1_q = 64'd0;
      arb_contention_q = 64'd0;
      arb_strict_opportunity_q = 64'd0;
      xbar_grant_cycles_q = 64'd0;
      xbar_grants_q = 64'd0;
      xbar_ready11_q = 64'd0;
      xbar_ready10_q = 64'd0;
      xbar_ready01_q = 64'd0;
      xbar_ready00_q = 64'd0;
      xbar_master0_q = 64'd0;
      xbar_master1_q = 64'd0;
      xbar_grant_bvalid_q = 64'd0;
      xbar_head0_write_response_q = 64'd0;
      xbar_head1_write_response_q = 64'd0;
      xbar_head_any_write_response_q = 64'd0;
      xbar_strict_opportunity_q = 64'd0;
      live_pairs_q = 64'd0;
      live_master0_q = 64'd0;
      live_master1_q = 64'd0;
      live_target_inactive_q = 64'd0;
      live_target_active_q = 64'd0;
      live_older_complete_holder_q = 64'd0;
      live_same_target_conflict_q = 64'd0;
      live_narrow_eligible_q = 64'd0;
      for (i = 0; i < 16; i = i + 1)
        xbar_target_q[i] = 64'd0;
    end else begin
      start_hit_v = (commit0_valid_i && (commit0_pc_i == start_pc_q)) ||
                    (commit1_valid_i && (commit1_pc_i == start_pc_q));
      end_hit_v = (commit0_valid_i && (commit0_pc_i == end_pc_q)) ||
                  (commit1_valid_i && (commit1_pc_i == end_pc_q));

      if (emit_pending_q && !emitted_q) begin
        $display("WRITE_PATH_BUBBLE_FINAL schema=npc-rv64-write-path-bubble-v1 complete=%0d available=%0d overflow=%0d invalid=%0d cycles=%0d arb_events=%0d arb_source11=%0d arb_source10=%0d arb_source01=%0d arb_source00=%0d arb_ready11=%0d arb_ready10=%0d arb_ready01=%0d arb_ready00=%0d arb_lane0=%0d arb_lane1=%0d arb_contention=%0d arb_strict=%0d xbar_grant_cycles=%0d xbar_grants=%0d xbar_ready11=%0d xbar_ready10=%0d xbar_ready01=%0d xbar_ready00=%0d xbar_master0=%0d xbar_master1=%0d xbar_grant_bvalid=%0d xbar_head0_wr_rsp=%0d xbar_head1_wr_rsp=%0d xbar_head_any_wr_rsp=%0d xbar_strict=%0d xbar_target0=%0d xbar_target1=%0d xbar_target2=%0d xbar_target3=%0d xbar_target4=%0d xbar_target5=%0d xbar_target6=%0d xbar_target7=%0d xbar_target8=%0d xbar_target9=%0d xbar_target10=%0d xbar_target11=%0d xbar_target12=%0d xbar_target13=%0d xbar_target14=%0d xbar_target15=%0d live_pairs=%0d live_master0=%0d live_master1=%0d live_target_inactive=%0d live_target_active=%0d live_older_holder=%0d live_same_target_conflict=%0d live_narrow_eligible=%0d arb_conservation=%0d xbar_ready_conservation=%0d xbar_master_conservation=%0d xbar_target_conservation=%0d live_conservation=%0d",
                 end_seen_q, start_plusarg_ok_q && end_plusarg_ok_q,
                 overflow_q, invalid_q, roi_cycles_q,
                 arb_events_q, arb_source11_q, arb_source10_q,
                 arb_source01_q, arb_source00_q, arb_ready11_q,
                 arb_ready10_q, arb_ready01_q, arb_ready00_q,
                 arb_lane0_q, arb_lane1_q, arb_contention_q,
                 arb_strict_opportunity_q, xbar_grant_cycles_q,
                 xbar_grants_q, xbar_ready11_q, xbar_ready10_q,
                 xbar_ready01_q, xbar_ready00_q, xbar_master0_q,
                 xbar_master1_q, xbar_grant_bvalid_q,
                 xbar_head0_write_response_q,
                 xbar_head1_write_response_q,
                 xbar_head_any_write_response_q,
                 xbar_strict_opportunity_q,
                 xbar_target_q[0], xbar_target_q[1],
                 xbar_target_q[2], xbar_target_q[3],
                 xbar_target_q[4], xbar_target_q[5],
                 xbar_target_q[6], xbar_target_q[7],
                 xbar_target_q[8], xbar_target_q[9],
                 xbar_target_q[10], xbar_target_q[11],
                 xbar_target_q[12], xbar_target_q[13],
                 xbar_target_q[14], xbar_target_q[15],
                 live_pairs_q, live_master0_q, live_master1_q,
                 live_target_inactive_q, live_target_active_q,
                 live_older_complete_holder_q,
                 live_same_target_conflict_q, live_narrow_eligible_q,
                 arb_conservation_w, xbar_ready_conservation_w,
                 xbar_master_conservation_w, xbar_target_conservation_w,
                 live_conservation_w);
        emit_pending_q = 1'b0;
        emitted_q = 1'b1;
      end

      if (!(start_plusarg_ok_q && end_plusarg_ok_q)) begin
        if (!emitted_q)
          invalid_q = 64'd1;
      end else if (roi_active_q) begin
        inc_counter(roi_cycles_q);

        if ($isunknown({arb_state_i, arb_capture_valid_i,
                        arb_capture_write_i, arb_capture_owner_i,
                        arb_request_illegal_i, arb_lane0_request_i,
                        arb_lane1_request_i, arb_lane0_awvalid_i,
                        arb_lane0_wvalid_i, arb_lane1_awvalid_i,
                        arb_lane1_wvalid_i, arb_down_awready_i,
                        arb_down_wready_i, xbar_grant_valid_i,
                        xbar_grant_master_i, xbar_active_i,
                        xbar_target_awready_i, xbar_target_wready_i,
                        xbar_target_bvalid_i, xbar_master_awvalid_i,
                        xbar_master_awready_i, xbar_master_wvalid_i,
                        xbar_master_wready_i, xbar_master_aw_hold_i,
                        xbar_master_w_hold_i, xbar_live_target0_i,
                        xbar_live_target1_i, xbar_hold_target0_i,
                        xbar_hold_target1_i, retire0_reason_i,
                        retire0_request_detail_i, retire1_reason_i,
                        retire1_request_detail_i})) begin
          inc_counter(invalid_q);
        end else begin
          if ((arb_state_i == ARB_S_IDLE) && arb_capture_valid_i &&
              arb_capture_write_i) begin
            inc_counter(arb_events_q);
            if (arb_request_illegal_i)
              inc_counter(invalid_q);
            if (arb_capture_owner_i) begin
              arb_src_aw_v = arb_lane1_awvalid_i;
              arb_src_w_v = arb_lane1_wvalid_i;
              inc_counter(arb_lane1_q);
            end else begin
              arb_src_aw_v = arb_lane0_awvalid_i;
              arb_src_w_v = arb_lane0_wvalid_i;
              inc_counter(arb_lane0_q);
            end
            classify_matrix(arb_src_aw_v, arb_src_w_v,
                            arb_source11_q, arb_source10_q,
                            arb_source01_q, arb_source00_q);
            classify_matrix(arb_down_awready_i, arb_down_wready_i,
                            arb_ready11_q, arb_ready10_q,
                            arb_ready01_q, arb_ready00_q);
            if (arb_lane0_request_i && arb_lane1_request_i)
              inc_counter(arb_contention_q);
            if (arb_src_aw_v && arb_src_w_v && arb_down_awready_i &&
                arb_down_wready_i)
              inc_counter(arb_strict_opportunity_q);
          end

          grant_owner_seen_v = 2'b00;
          if (|xbar_grant_valid_i)
            inc_counter(xbar_grant_cycles_q);
          for (i = 0; i < 16; i = i + 1) begin
            if (xbar_grant_valid_i[i]) begin
              inc_counter(xbar_grants_q);
              inc_counter(xbar_target_q[i]);
              if (xbar_active_i[i])
                inc_counter(invalid_q);
              if (grant_owner_seen_v[xbar_grant_master_i[i]])
                inc_counter(invalid_q);
              grant_owner_seen_v[xbar_grant_master_i[i]] = 1'b1;
              if (xbar_grant_master_i[i])
                inc_counter(xbar_master1_q);
              else
                inc_counter(xbar_master0_q);
              classify_matrix(xbar_target_awready_i[i],
                              xbar_target_wready_i[i],
                              xbar_ready11_q, xbar_ready10_q,
                              xbar_ready01_q, xbar_ready00_q);
              if (xbar_target_bvalid_i[i])
                inc_counter(xbar_grant_bvalid_q);
              if ((retire0_reason_i ==
                   RETIRE_MEMORY_REQUEST_OUTSTANDING) &&
                  (retire0_request_detail_i ==
                   REQUEST_AXI_WRITE_RESPONSE))
                inc_counter(xbar_head0_write_response_q);
              if ((retire1_reason_i ==
                   RETIRE_MEMORY_REQUEST_OUTSTANDING) &&
                  (retire1_request_detail_i ==
                   REQUEST_AXI_WRITE_RESPONSE))
                inc_counter(xbar_head1_write_response_q);
              if (((retire0_reason_i ==
                    RETIRE_MEMORY_REQUEST_OUTSTANDING) &&
                   (retire0_request_detail_i ==
                    REQUEST_AXI_WRITE_RESPONSE)) ||
                  ((retire1_reason_i ==
                    RETIRE_MEMORY_REQUEST_OUTSTANDING) &&
                   (retire1_request_detail_i ==
                    REQUEST_AXI_WRITE_RESPONSE)))
                inc_counter(xbar_head_any_write_response_q);
              if (xbar_target_awready_i[i] &&
                  xbar_target_wready_i[i] &&
                  !xbar_target_bvalid_i[i])
                inc_counter(xbar_strict_opportunity_q);
            end
          end

          live_pair_v[0] = xbar_master_awvalid_i[0] &&
                           xbar_master_awready_i[0] &&
                           xbar_master_wvalid_i[0] &&
                           xbar_master_wready_i[0];
          live_pair_v[1] = xbar_master_awvalid_i[1] &&
                           xbar_master_awready_i[1] &&
                           xbar_master_wvalid_i[1] &&
                           xbar_master_wready_i[1];
          any_old_complete_holder_v =
              |(xbar_master_aw_hold_i & xbar_master_w_hold_i);
          for (i = 0; i < 2; i = i + 1) begin
            if (live_pair_v[i]) begin
              inc_counter(live_pairs_q);
              if (i == 0) begin
                inc_counter(live_master0_q);
                live_target_v = xbar_live_target0_i;
                live_other_conflict_v =
                    (live_pair_v[1] &&
                     (xbar_live_target1_i == xbar_live_target0_i)) ||
                    (xbar_master_aw_hold_i[1] &&
                     xbar_master_w_hold_i[1] &&
                     (xbar_hold_target1_i == xbar_live_target0_i));
              end else begin
                inc_counter(live_master1_q);
                live_target_v = xbar_live_target1_i;
                live_other_conflict_v =
                    (live_pair_v[0] &&
                     (xbar_live_target0_i == xbar_live_target1_i)) ||
                    (xbar_master_aw_hold_i[0] &&
                     xbar_master_w_hold_i[0] &&
                     (xbar_hold_target0_i == xbar_live_target1_i));
              end
              if (xbar_active_i[live_target_v])
                inc_counter(live_target_active_q);
              else
                inc_counter(live_target_inactive_q);
              if (any_old_complete_holder_v)
                inc_counter(live_older_complete_holder_q);
              if (live_other_conflict_v)
                inc_counter(live_same_target_conflict_q);
              if (!xbar_active_i[live_target_v] &&
                  !any_old_complete_holder_v &&
                  !live_other_conflict_v)
                inc_counter(live_narrow_eligible_q);
            end
          end
        end

        if (end_hit_v) begin
          end_seen_q = 1'b1;
          roi_active_q = 1'b0;
          emit_pending_q = 1'b1;
        end
      end else if (!start_seen_q && start_hit_v) begin
        start_seen_q = 1'b1;
        roi_active_q = 1'b1;
        if (end_hit_v)
          inc_counter(invalid_q);
      end else if (!start_seen_q && end_hit_v) begin
        inc_counter(invalid_q);
      end
    end
  end
  /* verilator lint_on BLKSEQ */
endmodule

bind NpcSimTop NpcOooWritePathBubbleProbe u_write_path_bubble_probe (
  .clk(clk),
  .rst(rst),
  .commit0_valid_i(core_commit0_valid_w && !core_commit0_exception_w),
  .commit0_pc_i(core_commit0_pc_w),
  .commit1_valid_i(core_commit1_valid_w && !core_commit1_exception_w),
  .commit1_pc_i(core_commit1_pc_w),

  .arb_state_i(u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.state_q),
  .arb_capture_valid_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.capture_valid_w),
  .arb_capture_write_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.capture_write_w),
  .arb_capture_owner_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.capture_owner_w),
  .arb_request_illegal_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.request_illegal_w),
  .arb_lane0_request_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.lane0_request_w),
  .arb_lane1_request_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.lane1_request_w),
  .arb_lane0_awvalid_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.lane0_axi_awvalid_i),
  .arb_lane0_wvalid_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.lane0_axi_wvalid_i),
  .arb_lane1_awvalid_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.lane1_axi_awvalid_i),
  .arb_lane1_wvalid_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.lane1_axi_wvalid_i),
  .arb_down_awready_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.d_axi_awready_i),
  .arb_down_wready_i(
      u_top.u_core.u_ooo_dual_mem_bridge.u_miss_arbiter.d_axi_wready_i),

  .xbar_grant_valid_i(u_top.u_bus.u_crossbar.wr_grant_valid_r),
  .xbar_grant_master_i({
      u_top.u_bus.u_crossbar.wr_grant_master_r[15],
      u_top.u_bus.u_crossbar.wr_grant_master_r[14],
      u_top.u_bus.u_crossbar.wr_grant_master_r[13],
      u_top.u_bus.u_crossbar.wr_grant_master_r[12],
      u_top.u_bus.u_crossbar.wr_grant_master_r[11],
      u_top.u_bus.u_crossbar.wr_grant_master_r[10],
      u_top.u_bus.u_crossbar.wr_grant_master_r[9],
      u_top.u_bus.u_crossbar.wr_grant_master_r[8],
      u_top.u_bus.u_crossbar.wr_grant_master_r[7],
      u_top.u_bus.u_crossbar.wr_grant_master_r[6],
      u_top.u_bus.u_crossbar.wr_grant_master_r[5],
      u_top.u_bus.u_crossbar.wr_grant_master_r[4],
      u_top.u_bus.u_crossbar.wr_grant_master_r[3],
      u_top.u_bus.u_crossbar.wr_grant_master_r[2],
      u_top.u_bus.u_crossbar.wr_grant_master_r[1],
      u_top.u_bus.u_crossbar.wr_grant_master_r[0]}),
  .xbar_active_i(u_top.u_bus.u_crossbar.wr_active_q),
  .xbar_target_awready_i(u_top.u_bus.u_crossbar.s_awready_i),
  .xbar_target_wready_i(u_top.u_bus.u_crossbar.s_wready_i),
  .xbar_target_bvalid_i(u_top.u_bus.u_crossbar.s_bvalid_i),
  .xbar_master_awvalid_i(u_top.u_bus.u_crossbar.m_awvalid_i),
  .xbar_master_awready_i(u_top.u_bus.u_crossbar.m_awready_r),
  .xbar_master_wvalid_i(u_top.u_bus.u_crossbar.m_wvalid_i),
  .xbar_master_wready_i(u_top.u_bus.u_crossbar.m_wready_r),
  .xbar_master_aw_hold_i(u_top.u_bus.u_crossbar.wr_aw_hold_q),
  .xbar_master_w_hold_i(u_top.u_bus.u_crossbar.wr_w_hold_q),
  .xbar_live_target0_i(u_top.u_bus.u_crossbar.awtarget_decode_r[0]),
  .xbar_live_target1_i(u_top.u_bus.u_crossbar.awtarget_decode_r[1]),
  .xbar_hold_target0_i(u_top.u_bus.u_crossbar.wr_awtarget_q[0]),
  .xbar_hold_target1_i(u_top.u_bus.u_crossbar.wr_awtarget_q[1]),

  .retire0_reason_i(sim_retire_slot0_reason_w),
  .retire0_request_detail_i(sim_retire_slot0_request_detail_w),
  .retire1_reason_i(sim_retire_slot1_reason_w),
  .retire1_request_detail_i(sim_retire_slot1_request_detail_w)
);

`endif
