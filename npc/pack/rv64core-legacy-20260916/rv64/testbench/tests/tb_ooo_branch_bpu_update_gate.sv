`timescale 1ns/1ps
`include "include/define.v"

// [wave5b 死硅拆除] OooBranchBpuUpdateGate 旧四臂(direct/pending/drained/commit)+pending_like
// 已删，BHT update 化简为 issue-resolve 单源。TB 同步退休四臂场景，保留 BHT lookup 触发路径 +
// 新增 issue-resolve 单源 update 断言。
module tb_ooo_branch_bpu_update_gate;
  reg direct_frontend_flush;
  reg can_run;
  reg fifo_has_packet;
  reg dispatch0_branch;
  reg direct_branch0_dispatch_valid;
  reg dispatch1_barrier_fire;
  reg head1_branch_raw;
  reg direct_branch_fire;
  reg direct_branch_bht_valid;
  reg head0_branch_bht_valid;
  reg head1_branch_bht_valid;
  reg resolve_update_valid;
  reg resolve_update_taken;
  reg resolve_update_pred_taken;
  reg [`XLEN-1:0] resolve_update_pc;
  reg [`BPU_BHT_INDEX_W-1:0] resolve_update_bht_idx;

  wire branch_bpu_pending0_capture;
  wire branch_bpu_pending1_capture;
  wire branch_bpu_lookup_event;
  wire branch_bpu_lookup_bht_valid;
  wire branch_bpu_update_valid;
  wire branch_bpu_update_taken;
  wire branch_bpu_update_pred_taken;
  wire branch_bpu_update_correct;
  wire [`XLEN-1:0] branch_bpu_update_pc;
  wire [`BPU_BHT_INDEX_W-1:0] branch_bpu_update_bht_idx;

  integer errors;

  OooBranchBpuUpdateGate dut (
    .direct_frontend_flush_i(direct_frontend_flush),
    .can_run_i(can_run),
    .fifo_has_packet_i(fifo_has_packet),
    .dispatch0_branch_i(dispatch0_branch),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .head1_branch_raw_i(head1_branch_raw),
    .direct_branch_fire_i(direct_branch_fire),
    .direct_branch_bht_valid_i(direct_branch_bht_valid),
    .head0_branch_bht_valid_i(head0_branch_bht_valid),
    .head1_branch_bht_valid_i(head1_branch_bht_valid),
    .resolve_update_valid_i(resolve_update_valid),
    .resolve_update_taken_i(resolve_update_taken),
    .resolve_update_pred_taken_i(resolve_update_pred_taken),
    .resolve_update_pc_i(resolve_update_pc),
    .resolve_update_bht_idx_i(resolve_update_bht_idx),
    .branch_bpu_pending0_capture_o(branch_bpu_pending0_capture),
    .branch_bpu_pending1_capture_o(branch_bpu_pending1_capture),
    .branch_bpu_lookup_event_o(branch_bpu_lookup_event),
    .branch_bpu_lookup_bht_valid_o(branch_bpu_lookup_bht_valid),
    .branch_bpu_update_valid_o(branch_bpu_update_valid),
    .branch_bpu_update_taken_o(branch_bpu_update_taken),
    .branch_bpu_update_pred_taken_o(branch_bpu_update_pred_taken),
    .branch_bpu_update_correct_o(branch_bpu_update_correct),
    .branch_bpu_update_pc_o(branch_bpu_update_pc),
    .branch_bpu_update_bht_idx_o(branch_bpu_update_bht_idx)
  );

  task check1;
    input [191:0] name;
    input got;
    input exp;
    begin
      if (got !== exp) begin
        errors = errors + 1;
        $display("[FAIL] %0s got=%0b exp=%0b", name, got, exp);
      end
    end
  endtask

  task check64;
    input [191:0] name;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        errors = errors + 1;
        $display("[FAIL] %0s got=0x%016x exp=0x%016x", name, got, exp);
      end
    end
  endtask

  task check_bht;
    input [191:0] name;
    input [`BPU_BHT_INDEX_W-1:0] got;
    input [`BPU_BHT_INDEX_W-1:0] exp;
    begin
      if (got !== exp) begin
        errors = errors + 1;
        $display("[FAIL] %0s got=0x%0x exp=0x%0x", name, got, exp);
      end
    end
  endtask

  task reset_inputs;
    begin
      direct_frontend_flush = 1'b0;
      can_run = 1'b0;
      fifo_has_packet = 1'b0;
      dispatch0_branch = 1'b0;
      direct_branch0_dispatch_valid = 1'b0;
      dispatch1_barrier_fire = 1'b0;
      head1_branch_raw = 1'b0;
      direct_branch_fire = 1'b0;
      direct_branch_bht_valid = 1'b0;
      head0_branch_bht_valid = 1'b0;
      head1_branch_bht_valid = 1'b0;
      resolve_update_valid = 1'b0;
      resolve_update_taken = 1'b0;
      resolve_update_pred_taken = 1'b0;
      resolve_update_pc = 64'h8000_0200;
      resolve_update_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
    end
  endtask

  initial begin
    errors = 0;

    // ---- BHT lookup 触发路径（活 F2 预测，保留） ----
    reset_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch0_branch = 1'b1;
    head0_branch_bht_valid = 1'b1;
    #1;
    check1("lane0 pending capture", branch_bpu_pending0_capture, 1'b1);
    check1("lookup event lane0", branch_bpu_lookup_event, 1'b1);
    check1("lookup bht valid lane0", branch_bpu_lookup_bht_valid, 1'b1);
    direct_branch0_dispatch_valid = 1'b1;
    #1;
    check1("direct dispatch blocks pending0",
           branch_bpu_pending0_capture, 1'b0);

    reset_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch1_barrier_fire = 1'b1;
    head1_branch_raw = 1'b1;
    head1_branch_bht_valid = 1'b1;
    #1;
    check1("lane1 pending capture", branch_bpu_pending1_capture, 1'b1);
    check1("lookup bht valid lane1", branch_bpu_lookup_bht_valid, 1'b1);
    direct_frontend_flush = 1'b1;
    #1;
    check1("flush blocks lane1 capture", branch_bpu_pending1_capture, 1'b0);

    reset_inputs();
    direct_branch_fire = 1'b1;
    direct_branch_bht_valid = 1'b1;
    #1;
    check1("direct lookup event", branch_bpu_lookup_event, 1'b1);
    check1("direct lookup bht valid", branch_bpu_lookup_bht_valid, 1'b1);

    // ---- issue-resolve 单源 update（F2 唯一活 update） ----
    reset_inputs();
    #1;
    check1("no update when resolve idle", branch_bpu_update_valid, 1'b0);

    reset_inputs();
    resolve_update_valid = 1'b1;
    resolve_update_taken = 1'b1;
    resolve_update_pred_taken = 1'b1;
    resolve_update_pc = 64'h8000_1004;
    resolve_update_bht_idx = 12'h123;
    #1;
    check1("resolve update valid", branch_bpu_update_valid, 1'b1);
    check1("resolve update taken", branch_bpu_update_taken, 1'b1);
    check1("resolve pred selected", branch_bpu_update_pred_taken, 1'b1);
    check1("resolve update correct", branch_bpu_update_correct, 1'b1);
    check64("resolve update pc", branch_bpu_update_pc, 64'h8000_1004);
    check_bht("resolve update bht", branch_bpu_update_bht_idx, 12'h123);

    reset_inputs();
    resolve_update_valid = 1'b1;
    resolve_update_taken = 1'b1;
    resolve_update_pred_taken = 1'b0;
    resolve_update_pc = 64'h8000_2000;
    resolve_update_bht_idx = 12'h456;
    #1;
    check1("resolve mispredict update valid", branch_bpu_update_valid, 1'b1);
    check1("resolve mispredict taken", branch_bpu_update_taken, 1'b1);
    check1("resolve mispredict incorrect", branch_bpu_update_correct, 1'b0);
    check64("resolve mispredict pc", branch_bpu_update_pc, 64'h8000_2000);
    check_bht("resolve mispredict bht", branch_bpu_update_bht_idx, 12'h456);

    if (errors == 0) begin
      $display("[PASS] tb_ooo_branch_bpu_update_gate");
      $finish;
    end
    $display("[FAIL] tb_ooo_branch_bpu_update_gate errors=%0d", errors);
    $finish;
  end
endmodule
