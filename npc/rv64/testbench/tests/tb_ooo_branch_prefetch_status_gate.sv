`include "define.v"
`include "tb_common.svh"

module tb_ooo_branch_prefetch_status_gate;
  reg branch_prefetch_active;
  reg branch_prefetch_buffer_valid;
  reg stop_pending;
  reg pending_branch;
  reg pending_branch_dispatched;
  reg pending_jump;
  reg pending_jump_jalr;
  reg fetch_rsp_fire;
  reg [`XLEN-1:0] branch_prefetch_pc;
  reg [`XLEN-1:0] core_branch_resolve_next_pc;

  wire rsp_capture;
  wire match;
  wire buffer_match;
  wire rsp_match;
  wire hit_available;
  wire pending_match;

  OooBranchPrefetchStatusGate dut (
    .branch_prefetch_active_i(branch_prefetch_active),
    .branch_prefetch_buffer_valid_i(branch_prefetch_buffer_valid),
    .stop_pending_i(stop_pending),
    .pending_branch_i(pending_branch),
    .pending_branch_dispatched_i(pending_branch_dispatched),
    .pending_jump_i(pending_jump),
    .pending_jump_jalr_i(pending_jump_jalr),
    .fetch_rsp_fire_i(fetch_rsp_fire),
    .branch_prefetch_pc_i(branch_prefetch_pc),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc),
    .rsp_capture_o(rsp_capture),
    .match_o(match),
    .buffer_match_o(buffer_match),
    .rsp_match_o(rsp_match),
    .hit_available_o(hit_available),
    .pending_match_o(pending_match)
  );

  task automatic reset_inputs;
    begin
      branch_prefetch_active = 1'b0;
      branch_prefetch_buffer_valid = 1'b0;
      stop_pending = 1'b1;
      pending_branch = 1'b0;
      pending_branch_dispatched = 1'b0;
      pending_jump = 1'b0;
      pending_jump_jalr = 1'b0;
      fetch_rsp_fire = 1'b0;
      branch_prefetch_pc = 64'h0000_0000_0000_4000;
      core_branch_resolve_next_pc = 64'h0000_0000_0000_5000;
      #1;
    end
  endtask

  task automatic check_idle_status;
    input [1023:0] tag;
    begin
      #1;
      tb_check1({tag, " no capture"}, rsp_capture, 1'b0);
      tb_check1({tag, " no match"}, match, 1'b0);
      tb_check1({tag, " no buffer match"}, buffer_match, 1'b0);
      tb_check1({tag, " no rsp match"}, rsp_match, 1'b0);
      tb_check1({tag, " no hit available"}, hit_available, 1'b0);
      tb_check1({tag, " no pending match"}, pending_match, 1'b0);
    end
  endtask

  task automatic set_branch_capture_base;
    begin
      reset_inputs();
      branch_prefetch_active = 1'b1;
      pending_branch = 1'b1;
      pending_branch_dispatched = 1'b1;
      fetch_rsp_fire = 1'b1;
      #1;
    end
  endtask

  task automatic check_capture_blocked;
    input [1023:0] tag;
    begin
      #1;
      tb_check1({tag, " blocks capture"}, rsp_capture, 1'b0);
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    check_idle_status("idle");

    set_branch_capture_base();
    tb_check1("dispatched branch captures response", rsp_capture, 1'b1);

    reset_inputs();
    branch_prefetch_active = 1'b1;
    pending_jump = 1'b1;
    pending_jump_jalr = 1'b1;
    fetch_rsp_fire = 1'b1;
    #1;
    tb_check1("pending jalr captures response", rsp_capture, 1'b1);

    set_branch_capture_base();
    branch_prefetch_buffer_valid = 1'b1;
    check_capture_blocked("buffer valid");

    set_branch_capture_base();
    branch_prefetch_active = 1'b0;
    check_capture_blocked("inactive");

    set_branch_capture_base();
    stop_pending = 1'b0;
    check_capture_blocked("no stop pending");

    set_branch_capture_base();
    pending_branch_dispatched = 1'b0;
    check_capture_blocked("undispatched branch");

    set_branch_capture_base();
    pending_branch = 1'b0;
    pending_branch_dispatched = 1'b0;
    check_capture_blocked("no capture owner");

    set_branch_capture_base();
    fetch_rsp_fire = 1'b0;
    check_capture_blocked("no response fire");

    reset_inputs();
    branch_prefetch_active = 1'b1;
    branch_prefetch_pc = 64'h0000_0000_0000_6000;
    core_branch_resolve_next_pc = 64'h0000_0000_0000_6000;
    #1;
    tb_check1("active equal pc matches", match, 1'b1);
    tb_check1("match without packet is pending", pending_match, 1'b1);
    tb_check1("pending match has no hit", hit_available, 1'b0);

    reset_inputs();
    branch_prefetch_pc = 64'h0000_0000_0000_6000;
    core_branch_resolve_next_pc = 64'h0000_0000_0000_6000;
    #1;
    tb_check1("inactive equal pc does not match", match, 1'b0);

    reset_inputs();
    branch_prefetch_active = 1'b1;
    branch_prefetch_buffer_valid = 1'b1;
    branch_prefetch_pc = 64'h0000_0000_0000_7000;
    core_branch_resolve_next_pc = 64'h0000_0000_0000_7000;
    #1;
    tb_check1("buffer match", buffer_match, 1'b1);
    tb_check1("buffer hit available", hit_available, 1'b1);
    tb_check1("buffer hit not pending", pending_match, 1'b0);

    reset_inputs();
    branch_prefetch_active = 1'b1;
    pending_branch = 1'b1;
    pending_branch_dispatched = 1'b1;
    fetch_rsp_fire = 1'b1;
    branch_prefetch_pc = 64'h0000_0000_0000_8000;
    core_branch_resolve_next_pc = 64'h0000_0000_0000_8000;
    #1;
    tb_check1("same-cycle response match", rsp_match, 1'b1);
    tb_check1("same-cycle response hit available", hit_available, 1'b1);
    tb_check1("same-cycle response not pending", pending_match, 1'b0);

    tb_finish("tb_ooo_branch_prefetch_status_gate");
  end

endmodule
