`include "define.v"
`include "tb_common.svh"

module tb_ooo_jalr_prefetch_status_gate;
  reg branch_prefetch_active;
  reg branch_prefetch_buffer_valid;
  reg branch_prefetch_rsp_capture;
  reg stop_pending;
  reg pending_jump;
  reg pending_jump_jalr;
  reg pending_jump_dispatched;
  reg [`XLEN-1:0] pending_jump_target;
  reg pending_jump_resolve_ready;
  reg [`XLEN-1:0] pending_jump_resolved_target;
  reg pending_jump_misaligned;
  reg [`XLEN-1:0] branch_prefetch_pc;

  wire match;
  wire buffer_match;
  wire rsp_match;
  wire hit_available;
  wire pending_match;

  OooJalrPrefetchStatusGate dut (
    .branch_prefetch_active_i(branch_prefetch_active),
    .branch_prefetch_buffer_valid_i(branch_prefetch_buffer_valid),
    .branch_prefetch_rsp_capture_i(branch_prefetch_rsp_capture),
    .stop_pending_i(stop_pending),
    .pending_jump_i(pending_jump),
    .pending_jump_jalr_i(pending_jump_jalr),
    .pending_jump_dispatched_i(pending_jump_dispatched),
    .pending_jump_target_i(pending_jump_target),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready),
    .pending_jump_resolved_target_i(pending_jump_resolved_target),
    .pending_jump_misaligned_i(pending_jump_misaligned),
    .branch_prefetch_pc_i(branch_prefetch_pc),
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
      branch_prefetch_rsp_capture = 1'b0;
      stop_pending = 1'b1;
      pending_jump = 1'b0;
      pending_jump_jalr = 1'b0;
      pending_jump_dispatched = 1'b0;
      pending_jump_target = 64'h0000_0000_0000_7000;
      pending_jump_resolve_ready = 1'b0;
      pending_jump_resolved_target = 64'h0000_0000_0000_8000;
      pending_jump_misaligned = 1'b0;
      branch_prefetch_pc = 64'h0000_0000_0000_9000;
      #1;
    end
  endtask

  task automatic set_resolve_match_base;
    begin
      reset_inputs();
      branch_prefetch_active = 1'b1;
      pending_jump = 1'b1;
      pending_jump_jalr = 1'b1;
      pending_jump_resolve_ready = 1'b1;
      branch_prefetch_pc = pending_jump_resolved_target;
      #1;
    end
  endtask

  task automatic check_no_hit;
    input [1023:0] tag;
    begin
      #1;
      tb_check1({tag, " no match"}, match, 1'b0);
      tb_check1({tag, " no buffer match"}, buffer_match, 1'b0);
      tb_check1({tag, " no rsp match"}, rsp_match, 1'b0);
      tb_check1({tag, " no hit"}, hit_available, 1'b0);
      tb_check1({tag, " no pending"}, pending_match, 1'b0);
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    check_no_hit("idle");

    set_resolve_match_base();
    tb_check1("resolve target match", match, 1'b1);
    tb_check1("resolve target pending", pending_match, 1'b1);
    tb_check1("resolve target no hit yet", hit_available, 1'b0);

    reset_inputs();
    branch_prefetch_active = 1'b1;
    pending_jump = 1'b1;
    pending_jump_jalr = 1'b1;
    pending_jump_dispatched = 1'b1;
    pending_jump_target = 64'h0000_0000_0000_a000;
    pending_jump_resolve_ready = 1'b1;
    pending_jump_resolved_target = 64'h0000_0000_0000_b000;
    branch_prefetch_pc = 64'h0000_0000_0000_a000;
    #1;
    tb_check1("dispatched target has priority", match, 1'b1);

    branch_prefetch_pc = 64'h0000_0000_0000_b000;
    #1;
    tb_check1("resolve target ignored when dispatched", match, 1'b0);

    set_resolve_match_base();
    branch_prefetch_buffer_valid = 1'b1;
    #1;
    tb_check1("buffer match", buffer_match, 1'b1);
    tb_check1("buffer hit available", hit_available, 1'b1);
    tb_check1("buffer hit not pending", pending_match, 1'b0);

    set_resolve_match_base();
    branch_prefetch_rsp_capture = 1'b1;
    #1;
    tb_check1("same-cycle response match", rsp_match, 1'b1);
    tb_check1("same-cycle response hit available", hit_available, 1'b1);
    tb_check1("same-cycle response not pending", pending_match, 1'b0);

    set_resolve_match_base();
    branch_prefetch_active = 1'b0;
    check_no_hit("inactive");

    set_resolve_match_base();
    stop_pending = 1'b0;
    check_no_hit("no stop pending");

    set_resolve_match_base();
    pending_jump = 1'b0;
    check_no_hit("no pending jump");

    set_resolve_match_base();
    pending_jump_jalr = 1'b0;
    check_no_hit("not jalr");

    set_resolve_match_base();
    pending_jump_resolve_ready = 1'b0;
    check_no_hit("target not ready");

    set_resolve_match_base();
    pending_jump_misaligned = 1'b1;
    check_no_hit("misaligned target");

    set_resolve_match_base();
    branch_prefetch_pc = 64'h0000_0000_0000_c000;
    check_no_hit("pc mismatch");

    tb_finish("tb_ooo_jalr_prefetch_status_gate");
  end

endmodule
