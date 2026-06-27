`include "define.v"
`include "tb_common.svh"

module tb_ooo_direct_branch_resolve_gate;
  reg direct_branch0_fire;
  reg direct_branch1_fire;
  reg [`XLEN-1:0] head0_pc;
  reg [`XLEN-1:0] head1_pc;
  reg [`XLEN-1:0] head0_next_pc;
  reg [`XLEN-1:0] head1_next_pc;
  reg [`XLEN-1:0] head0_imm;
  reg [`XLEN-1:0] head1_imm;
  reg [`BPU_BHT_INDEX_W-1:0] head0_bht_idx;
  reg head0_bht_valid;
  reg head0_pred_taken;
  reg [`BPU_BHT_INDEX_W-1:0] head1_bht_idx;
  reg head1_bht_valid;
  reg head1_pred_taken;
  reg dispatch_resolve_valid;
  reg [`XLEN-1:0] dispatch_resolve_pc;
  reg [`XLEN-1:0] dispatch_resolve_next_pc;
  reg dispatch_resolve_misaligned;
  reg issue_resolve_valid;
  reg [`XLEN-1:0] issue_resolve_pc;
  reg [`XLEN-1:0] issue_resolve_next_pc;
  reg issue_resolve_misaligned;
  reg trap_redirect_squash;
  reg synth_lane1_ret_pending;
  reg synth_lane1_branch_drop_pending;
  reg head1_return_candidate;

  wire direct_branch_fire;
  wire [`XLEN-1:0] direct_branch_pc;
  wire [`XLEN-1:0] direct_branch_next_pc;
  wire [`XLEN-1:0] direct_branch_imm;
  wire [`XLEN-1:0] head0_branch_target;
  wire [`XLEN-1:0] direct_branch_target;
  wire [`BPU_BHT_INDEX_W-1:0] direct_branch_bht_idx;
  wire direct_branch_bht_valid;
  wire direct_branch_predict_taken;
  wire [`XLEN-1:0] direct_branch_pred_pc;
  wire direct_branch_resolve_valid;
  wire [`XLEN-1:0] direct_branch_resolve_next_pc;
  wire direct_branch_resolve_misaligned;
  wire direct_branch_resolve_redirect;
  wire direct_branch_resolve_taken;
  wire direct_branch0_lane1_ret;

  OooDirectBranchResolveGate dut (
    .direct_branch0_fire_i(direct_branch0_fire),
    .direct_branch1_fire_i(direct_branch1_fire),
    .head0_pc_i(head0_pc),
    .head1_pc_i(head1_pc),
    .head0_next_pc_i(head0_next_pc),
    .head1_next_pc_i(head1_next_pc),
    .head0_imm_i(head0_imm),
    .head1_imm_i(head1_imm),
    .head0_bht_idx_i(head0_bht_idx),
    .head0_bht_valid_i(head0_bht_valid),
    .head0_pred_taken_i(head0_pred_taken),
    .head1_bht_idx_i(head1_bht_idx),
    .head1_bht_valid_i(head1_bht_valid),
    .head1_pred_taken_i(head1_pred_taken),
    .dispatch_resolve_valid_i(dispatch_resolve_valid),
    .dispatch_resolve_pc_i(dispatch_resolve_pc),
    .dispatch_resolve_next_pc_i(dispatch_resolve_next_pc),
    .dispatch_resolve_misaligned_i(dispatch_resolve_misaligned),
    .issue_resolve_valid_i(issue_resolve_valid),
    .issue_resolve_pc_i(issue_resolve_pc),
    .issue_resolve_next_pc_i(issue_resolve_next_pc),
    .issue_resolve_misaligned_i(issue_resolve_misaligned),
    .trap_redirect_squash_i(trap_redirect_squash),
    .synth_lane1_ret_pending_i(synth_lane1_ret_pending),
    .synth_lane1_branch_drop_pending_i(synth_lane1_branch_drop_pending),
    .head1_return_candidate_i(head1_return_candidate),
    .direct_branch_fire_o(direct_branch_fire),
    .direct_branch_pc_o(direct_branch_pc),
    .direct_branch_next_pc_o(direct_branch_next_pc),
    .direct_branch_imm_o(direct_branch_imm),
    .head0_branch_target_o(head0_branch_target),
    .direct_branch_target_o(direct_branch_target),
    .direct_branch_bht_idx_o(direct_branch_bht_idx),
    .direct_branch_bht_valid_o(direct_branch_bht_valid),
    .direct_branch_predict_taken_o(direct_branch_predict_taken),
    .direct_branch_pred_pc_o(direct_branch_pred_pc),
    .direct_branch_resolve_valid_o(direct_branch_resolve_valid),
    .direct_branch_resolve_next_pc_o(direct_branch_resolve_next_pc),
    .direct_branch_resolve_misaligned_o(direct_branch_resolve_misaligned),
    .direct_branch_resolve_redirect_o(direct_branch_resolve_redirect),
    .direct_branch_resolve_taken_o(direct_branch_resolve_taken),
    .direct_branch0_lane1_ret_o(direct_branch0_lane1_ret)
  );

  task automatic check_xlen;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic reset_inputs;
    begin
      direct_branch0_fire = 1'b0;
      direct_branch1_fire = 1'b0;
      head0_pc = 64'h0000_0000_0000_1000;
      head1_pc = 64'h0000_0000_0000_1004;
      head0_next_pc = 64'h0000_0000_0000_1004;
      head1_next_pc = 64'h0000_0000_0000_1008;
      head0_imm = 64'h0000_0000_0000_0020;
      head1_imm = 64'h0000_0000_0000_0040;
      head0_bht_idx = 3;
      head0_bht_valid = 1'b1;
      head0_pred_taken = 1'b0;
      head1_bht_idx = 9;
      head1_bht_valid = 1'b0;
      head1_pred_taken = 1'b1;
      dispatch_resolve_valid = 1'b0;
      dispatch_resolve_pc = {`XLEN{1'b0}};
      dispatch_resolve_next_pc = {`XLEN{1'b0}};
      dispatch_resolve_misaligned = 1'b0;
      issue_resolve_valid = 1'b0;
      issue_resolve_pc = {`XLEN{1'b0}};
      issue_resolve_next_pc = {`XLEN{1'b0}};
      issue_resolve_misaligned = 1'b0;
      trap_redirect_squash = 1'b0;
      synth_lane1_ret_pending = 1'b0;
      synth_lane1_branch_drop_pending = 1'b0;
      head1_return_candidate = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    direct_branch0_fire = 1'b1;
    #1;
    tb_check1("lane0 fire", direct_branch_fire, 1'b1);
    check_xlen("lane0 pc", direct_branch_pc, head0_pc);
    check_xlen("lane0 next", direct_branch_next_pc, head0_next_pc);
    check_xlen("lane0 target", direct_branch_target,
               64'h0000_0000_0000_1020);
    check_xlen("head0 target", head0_branch_target,
               64'h0000_0000_0000_1020);
    tb_check1("lane0 bht valid", direct_branch_bht_valid, 1'b1);
    tb_check1("lane0 predict not taken", direct_branch_predict_taken, 1'b0);
    check_xlen("lane0 pred pc fallthrough", direct_branch_pred_pc,
               head0_next_pc);

    reset_inputs();
    direct_branch0_fire = 1'b1;
    direct_branch1_fire = 1'b1;
    #1;
    check_xlen("lane1 pc priority", direct_branch_pc, head1_pc);
    check_xlen("lane1 target priority", direct_branch_target,
               64'h0000_0000_0000_1044);
    tb_check1("lane1 bht valid priority", direct_branch_bht_valid, 1'b0);
    tb_check1("lane1 predict taken", direct_branch_predict_taken, 1'b1);
    check_xlen("lane1 pred pc target", direct_branch_pred_pc,
               64'h0000_0000_0000_1044);

    reset_inputs();
    direct_branch0_fire = 1'b1;
    dispatch_resolve_valid = 1'b1;
    dispatch_resolve_pc = head0_pc;
    dispatch_resolve_next_pc = 64'h0000_0000_0000_1020;
    issue_resolve_valid = 1'b1;
    issue_resolve_pc = head0_pc;
    issue_resolve_next_pc = 64'h0000_0000_0000_1abc;
    #1;
    tb_check1("dispatch resolve valid", direct_branch_resolve_valid, 1'b1);
    check_xlen("dispatch resolve priority", direct_branch_resolve_next_pc,
               64'h0000_0000_0000_1020);
    tb_check1("dispatch redirect", direct_branch_resolve_redirect, 1'b1);
    tb_check1("dispatch taken", direct_branch_resolve_taken, 1'b1);

    reset_inputs();
    direct_branch1_fire = 1'b1;
    issue_resolve_valid = 1'b1;
    issue_resolve_pc = head1_pc;
    issue_resolve_next_pc = head1_next_pc;
    #1;
    tb_check1("issue resolve valid", direct_branch_resolve_valid, 1'b1);
    tb_check1("issue redirect", direct_branch_resolve_redirect, 1'b1);
    tb_check1("issue not taken", direct_branch_resolve_taken, 1'b0);

    reset_inputs();
    direct_branch0_fire = 1'b1;
    issue_resolve_valid = 1'b1;
    issue_resolve_pc = 64'h0000_0000_0000_dead;
    #1;
    tb_check1("issue pc mismatch blocks resolve",
              direct_branch_resolve_valid, 1'b0);

    reset_inputs();
    direct_branch0_fire = 1'b1;
    dispatch_resolve_valid = 1'b1;
    dispatch_resolve_pc = head0_pc;
    dispatch_resolve_next_pc = 64'h0000_0000_0000_1020;
    dispatch_resolve_misaligned = 1'b1;
    #1;
    tb_check1("misaligned keeps resolve valid", direct_branch_resolve_valid,
              1'b1);
    tb_check1("misaligned blocks redirect", direct_branch_resolve_redirect,
              1'b0);

    reset_inputs();
    direct_branch0_fire = 1'b1;
    dispatch_resolve_valid = 1'b1;
    dispatch_resolve_pc = head0_pc;
    dispatch_resolve_next_pc = 64'h0000_0000_0000_1020;
    trap_redirect_squash = 1'b1;
    #1;
    tb_check1("trap squash blocks redirect", direct_branch_resolve_redirect,
              1'b0);
    tb_check1("trap squash blocks taken", direct_branch_resolve_taken, 1'b0);

    reset_inputs();
    direct_branch0_fire = 1'b1;
    dispatch_resolve_valid = 1'b1;
    dispatch_resolve_pc = head0_pc;
    dispatch_resolve_next_pc = head1_pc;
    head1_return_candidate = 1'b1;
    #1;
    tb_check1("lane1 return capture", direct_branch0_lane1_ret, 1'b1);

    synth_lane1_ret_pending = 1'b1;
    #1;
    tb_check1("lane1 return pending blocks capture",
              direct_branch0_lane1_ret, 1'b0);

    tb_finish("tb_ooo_direct_branch_resolve_gate");
  end

endmodule
