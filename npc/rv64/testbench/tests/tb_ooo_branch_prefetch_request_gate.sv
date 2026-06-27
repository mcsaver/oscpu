`include "define.v"
`include "tb_common.svh"

module tb_ooo_branch_prefetch_request_gate;
  reg stop_pending;
  reg pending_branch;
  reg pending_branch_dispatched;
  reg branch_resolve_pending_match;
  reg jalr_btb_hit;
  reg pending_jump_dispatched;
  reg branch_prefetch_active;
  reg outstanding_valid;
  reg discard_fetch_rsp;
  reg branch_spec_checkpoint_pending;
  reg branch_spec_active;
  reg halted;
  reg trap_valid;
  reg exit_valid;
  reg [`XLEN-1:0] branch_pred_pc;
  reg [`XLEN-1:0] jalr_btb_target;

  wire branch_req_valid;
  wire jalr_req_valid;
  wire req_valid;
  wire [`XLEN-1:0] req_pc;

  OooBranchPrefetchRequestGate dut (
    .stop_pending_i(stop_pending),
    .pending_branch_i(pending_branch),
    .pending_branch_dispatched_i(pending_branch_dispatched),
    .branch_resolve_pending_match_i(branch_resolve_pending_match),
    .jalr_btb_hit_i(jalr_btb_hit),
    .pending_jump_dispatched_i(pending_jump_dispatched),
    .branch_prefetch_active_i(branch_prefetch_active),
    .outstanding_valid_i(outstanding_valid),
    .discard_fetch_rsp_i(discard_fetch_rsp),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending),
    .branch_spec_active_i(branch_spec_active),
    .halted_i(halted),
    .trap_valid_i(trap_valid),
    .exit_valid_i(exit_valid),
    .branch_pred_pc_i(branch_pred_pc),
    .jalr_btb_target_i(jalr_btb_target),
    .branch_req_valid_o(branch_req_valid),
    .jalr_req_valid_o(jalr_req_valid),
    .req_valid_o(req_valid),
    .req_pc_o(req_pc)
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
      stop_pending = 1'b1;
      pending_branch = 1'b0;
      pending_branch_dispatched = 1'b0;
      branch_resolve_pending_match = 1'b0;
      jalr_btb_hit = 1'b0;
      pending_jump_dispatched = 1'b0;
      branch_prefetch_active = 1'b0;
      outstanding_valid = 1'b0;
      discard_fetch_rsp = 1'b0;
      branch_spec_checkpoint_pending = 1'b0;
      branch_spec_active = 1'b0;
      halted = 1'b0;
      trap_valid = 1'b0;
      exit_valid = 1'b0;
      branch_pred_pc = 64'h0000_0000_0000_2000;
      jalr_btb_target = 64'h0000_0000_0000_3000;
      #1;
    end
  endtask

  task automatic check_shared_blocker;
    input [1023:0] tag;
    begin
      #1;
      tb_check1({tag, " blocks branch"}, branch_req_valid, 1'b0);
      tb_check1({tag, " blocks jalr"}, jalr_req_valid, 1'b0);
      tb_check1({tag, " blocks req"}, req_valid, 1'b0);
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    tb_check1("idle no request", req_valid, 1'b0);
    check_xlen("idle pc falls to branch pred", req_pc, branch_pred_pc);

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    #1;
    tb_check1("branch request valid", branch_req_valid, 1'b1);
    tb_check1("branch drives request valid", req_valid, 1'b1);
    check_xlen("branch request pc", req_pc, branch_pred_pc);

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    stop_pending = 1'b0;
    #1;
    tb_check1("branch requires stop pending", branch_req_valid, 1'b0);

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    branch_resolve_pending_match = 1'b1;
    #1;
    tb_check1("resolve match blocks branch prefetch", branch_req_valid,
              1'b0);

    reset_inputs();
    jalr_btb_hit = 1'b1;
    #1;
    tb_check1("jalr request valid", jalr_req_valid, 1'b1);
    tb_check1("jalr drives request valid", req_valid, 1'b1);
    check_xlen("jalr request pc", req_pc, jalr_btb_target);

    reset_inputs();
    jalr_btb_hit = 1'b1;
    pending_jump_dispatched = 1'b1;
    #1;
    tb_check1("dispatched jalr blocks request", jalr_req_valid, 1'b0);

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    #1;
    tb_check1("branch remains valid when jalr also valid", branch_req_valid,
              1'b1);
    tb_check1("jalr also valid", jalr_req_valid, 1'b1);
    check_xlen("jalr pc priority", req_pc, jalr_btb_target);

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    branch_prefetch_active = 1'b1;
    check_shared_blocker("active prefetch");

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    outstanding_valid = 1'b1;
    check_shared_blocker("outstanding");

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    discard_fetch_rsp = 1'b1;
    check_shared_blocker("discard response");

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    branch_spec_checkpoint_pending = 1'b1;
    check_shared_blocker("checkpoint pending");

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    branch_spec_active = 1'b1;
    check_shared_blocker("branch spec active");

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    halted = 1'b1;
    check_shared_blocker("halted");

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    trap_valid = 1'b1;
    check_shared_blocker("trap valid");

    reset_inputs();
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    jalr_btb_hit = 1'b1;
    exit_valid = 1'b1;
    check_shared_blocker("exit valid");

    tb_finish("tb_ooo_branch_prefetch_request_gate");
  end

endmodule
