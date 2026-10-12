`timescale 1ns / 1ps
// Native Control peer; no backend, ROB, rename, decoder or private UOP layout.
`include "R64Protocol.vh"
module tb_r64_control_domain;
  localparam M = `R64_META_W;
  reg clk = 0;
  always #5 clk = ~clk;
  reg rst = 1, recover = 0, lsu_irrevocable = 0;
  reg [1:0] valid = 0, serial_class = 0, exception = 0, trace_ready = 0;
  reg [17:0] tags = 0;
  reg [2*M-1:0] meta = 0;
  reg [127:0] data = 0, tval = 0;
  reg [11:0] cause = 0;
  reg [5:0] count = 0;
  reg [8:0] head = 0;
  reg head_serial = 0, head_exception = 0;
  reg [`R64_RECOVERY_W(32)-1:0] recovery = 0;
  reg serial_fire = 0, result_ready = 0;
  reg [8:0] command_tag = 0;
  reg [`R64_SERIAL_CMD_W-1:0] command = 0;
  wire [1:0] rob_ready, trace_valid;
  wire [`R64_EFFECT_W(9)-1:0] effect, memory_effect;
  wire [`R64_RETIRE_W(9)-1:0] retire;
  wire serial_ready, result_valid, serial_idle, serial_irrevocable;
  wire [8:0] result_tag;
  wire [`R64_RESULT_W-1:0] result;
  wire [31:0] serial_reuse;
  wire stop_birth, flush, redirect, trap, trap_irq;
  wire [63:0] target, status, satp, trap_pc, trap_tval, trap_raw, trap_target;
  wire [1:0] privilege;
  wire [5:0] trap_cause;
  wire [3:0] trap_length;
  wire [127:0] trace_pc, trace_raw, trace_data, trace_npc;
  integer accepted = 0, traps = 0, flushes = 0, checks = 0;
  integer before_count;
  reg [`R64_RESULT_W-1:0] saved_result;
  reg [63:0] saved_status;

  R64Control dut (
    .serial_retire_candidate_i(valid[0] && !exception[0] && serial_class[0]),
    .pair_store_candidate_valid_i(1'b0),.pair_store_candidate_tag_i(9'b0),
    .clk_i(clk), .rst_i(rst), .run_i(1'b1),
    .irq_software_i(1'b0), .irq_timer_i(1'b0), .irq_external_i(1'b0),
    .irq_supervisor_external_i(1'b0), .wfi_wait_i(1'b0), .time_i(64'd0),
    .rob_valid_i(valid), .rob_serial_i(serial_class), .rob_exception_i(exception),
    .rob_write_i(2'b11), .rob_fp_i(2'b00), .rob_ready_o(rob_ready),
    .rob_tag_i(tags), .rob_meta_i(meta), .rob_data_i(data), .rob_tval_i(tval),
    .rob_cause_i(cause), .rob_arch_i({5'd2, 5'd1}), .rob_flags_i(10'd0),
    .rob_count_i(count), .head_tag_i(head), .head_serial_i(head_serial),
    .head_exception_raw_i(head_exception), .recover_i(recover), .recovery_i(recovery),
    .effect_o(effect), .memory_effect_o(memory_effect), .serial_fire_i(serial_fire), .serial_ready_o(serial_ready),
    .serial_tag_i(command_tag), .serial_command_i(command),
    .serial_result_valid_o(result_valid), .serial_result_ready_i(result_ready),
    .serial_result_tag_o(result_tag), .serial_result_o(result),
    .memory_idle_i(1'b1), .lsu_irrevocable_i(lsu_irrevocable),
    .serial_irrevocable_o(serial_irrevocable), .serial_idle_o(serial_idle),
    .serial_reuse_o(serial_reuse), .stop_birth_o(stop_birth), .full_flush_o(flush),
    .control_redirect_o(redirect), .control_target_o(target), .retire_o(retire),
    .privilege_o(privilege), .mstatus_o(status), .satp_o(satp),
    .tensor_cmd_ready_i(1'b0), .tensor_terminal_valid_i(1'b0),
    .tensor_error_i(1'b0), .tensor_terminal_tag_i(9'd0), .tensor_error_code_i(8'd0),
    .trace_ready_i(trace_ready), .trace_valid_o(trace_valid),
    .trace_pc_o(trace_pc), .trace_raw_o(trace_raw), .trace_npc_o(trace_npc),
    .trace_data_o(trace_data), .trap_valid_o(trap), .trap_interrupt_o(trap_irq),
    .trap_cause_o(trap_cause), .trap_pc_o(trap_pc), .trap_tval_o(trap_tval),
    .trap_raw_o(trap_raw), .trap_target_o(trap_target), .trap_length_o(trap_length)
  );
  function [M-1:0] md(input [63:0] pc, input [63:0] raw, input [7:0] kind);
    md = {kind, 4'd4, pc + 64'd4, raw, pc};
  endfunction
  task check(input condition, input [511:0] message);
    begin
      checks = checks + 1;
      if (condition !== 1'b1) $fatal(1, "%0s", message);
    end
  endtask
  // Peers update after falling edges; monitor sees the accepting rising edge.
  task tick;
    begin
      @(posedge clk);
      @(negedge clk);
      #1;
    end
  endtask
  task empty_peer;
    begin
      valid = 0; serial_class = 0; exception = 0; tags = 0; meta = 0;
      data = 0; tval = 0; cause = 0; count = 0; head = 0;
      head_serial = 0; head_exception = 0;
    end
  endtask
  task issue(input [8:0] tag_value, input [63:0] pc_value,
             input [63:0] instruction, input [63:0] operand, input [7:0] kind);
    begin
      empty_peer;
      count = 1; head = tag_value; head_serial = 1; command_tag = tag_value;
      command = 0;
      command[`R64_SERIAL_PC] = pc_value;
      command[`R64_SERIAL_INST] = instruction;
      command[`R64_SERIAL_OPERAND] = operand;
      command[`R64_SERIAL_KIND] = kind;
      meta[0+:M] = md(pc_value, instruction, kind);
      serial_class = 1; tags[8:0] = tag_value;
      #1;
      check(serial_ready && effect[`R64_EFFECT_PRESENT(9)] &&
            effect[`R64_EFFECT_SERIAL(9)] && effect[8:0] == tag_value,
            "native serial admission lost head authorization");
      serial_fire = 1;
      tick;
      serial_fire = 0;
    end
  endtask
  task await_result;
    integer waits;
    begin
      waits = 0;
      while (!result_valid && waits < 12) begin
        tick;
        waits = waits + 1;
      end
      check(result_valid && result_tag == head, "serial completion missing or wrong tag");
    end
  endtask
  task accept_result;
    begin
      data[63:0] = result[`R64_R_DATA];
      exception[0] = result[`R64_R_EXCEPTION];
      cause[5:0] = result[`R64_R_CAUSE];
      tval[63:0] = result[`R64_R_TVAL];
      head_exception = result[`R64_R_EXCEPTION];
      result_ready = 1;
      tick;
      result_ready = 0;
    end
  endtask
  task retire_serial;
    begin
      valid = 1; trace_ready = 1;
      #1;
      check(retire[1:0] == 1 && retire[10:2] == head,
            "serial retirement did not carry matching owner");
      tick;
      check(flush && redirect && !trap && target == meta[191:128],
            "serial retirement did not generate precise full flush");
      empty_peer;
      tick;
      check(!flush && serial_idle, "serial full flush did not drain local ownership");
    end
  endtask
  always @(posedge clk)
    if (!rst) begin
      if (retire[1] && !retire[0]) $fatal(1, "non-dense retirement");
      if (trace_valid !== retire[1:0]) $fatal(1, "trace and accepted retirement disagree");
      if (effect[8:0] !== head || effect[`R64_EFFECT_PRESENT(9)] !== (count != 0))
        $fatal(1, "effect head identity disagrees with public peer");
      if (retire[0] && retire[10:2] !== tags[8:0]) $fatal(1, "retire lane0 tag");
      if (retire[1] && retire[19:11] !== tags[17:9]) $fatal(1, "retire lane1 tag");
      accepted = accepted + retire[0] + retire[1];
      if (trap) traps = traps + 1;
      if (flush) begin
        flushes = flushes + 1;
        if (|retire[1:0] || memory_effect[`R64_EFFECT_MEMORY(9)] || effect[`R64_EFFECT_SERIAL(9)])
          $fatal(1, "full flush overlapped retirement or side-effect authorization");
      end
    end
  initial begin
    repeat (3) tick;
    rst = 0;
    tick;
    check(privilege == 3 && serial_idle && !effect[`R64_EFFECT_PRESENT(9)], "reset context");
    // Peer holds two immutable candidates until a dense accepted prefix.
    valid = 3; count = 2; head = 9'h045; tags = {9'h066, 9'h045};
    meta = {md(64'h80000104, 64'h00200113, `R64_K_NORMAL),
            md(64'h80000100, 64'h00100093, `R64_K_NORMAL)};
    data = {64'h2222, 64'h1111}; trace_ready = 0; before_count = accepted;
    repeat (3) begin
      tick;
      check(retire[1:0] == 0 && accepted == before_count &&
            trace_pc == {64'h80000104, 64'h80000100} && trace_data == {64'h2222, 64'h1111},
            "held candidate changed under backpressure");
    end
    trace_ready = 2;
    tick;
    check(retire[1:0] == 0 && accepted == before_count, "lane1 bypassed blocked lane0");
    recover = 1; trace_ready = 3;
    #1;
    check(stop_birth && retire[1:0] == 0 &&
          !memory_effect[`R64_EFFECT_MEMORY(9)] && effect[`R64_EFFECT_SERIAL(9)],
          "undo revoked head service or allowed retirement");
    tick;
    recover = 0; trace_ready = 1;
    #1;
    check(retire[1:0] == 1 && retire[10:2] == 9'h045, "one-ready dense prefix");
    tick;
    check(accepted == before_count + 1, "one-ready retirement count");
    valid = 1; count = 1; head = 9'h066; tags = {9'd0, 9'h066};
    meta = {{M{1'b0}}, meta[M+:M]}; data = {64'd0, 64'h2222}; trace_ready = 3;
    tick;
    check(accepted == before_count + 2, "retained candidate did not retire once");
    empty_peer;
    valid = 3; count = 2; head = 9'h067; tags = {9'h068, 9'h067};
    meta = {md(64'h8000010c, 64'h00400213, `R64_K_NORMAL),
            md(64'h80000108, 64'h00300193, `R64_K_NORMAL)};
    #1;
    check(retire[1:0] == 3 && retire[19:2] == tags, "two-ready dual tagged retirement");
    tick;
    empty_peer;
    trace_ready = 0;
    check(accepted == before_count + 4, "dual retirement count");
    $display("[CASE] native candidates hold/dense-prefix/tags/recovery authorization PASS");

    saved_status = status;
    issue(9'h069, 64'h80000200, 64'h300110f3, 64'h8, `R64_K_CSR);
    command = 0; // Accepted command is locally owned, independent of live input.
    await_result;
    check(!result[`R64_R_EXCEPTION] && result[`R64_R_DATA] == saved_status,
          "CSR completion did not return pre-write value");
    saved_result = result;
    repeat (3) begin
      tick;
      check(result_valid && result == saved_result && result_tag == 9'h069 &&
            status == saved_status, "held CSR completion changed or wrote early");
    end
    accept_result;
    valid = 1;
    repeat (3) begin
      tick;
      check(!result_valid && status == saved_status && retire[1:0] == 0 && !serial_idle,
            "completion acceptance caused premature CSR effect");
    end
    retire_serial;
    check(status[3], "matching CSR retirement did not set MIE");
    $display("[CASE] CSR command/held completion/accepted result/tagged retire PASS");

    // Victim candidates do not cancel until an active recovery event arrives.
    saved_status = status;
    issue(9'h06a, 64'h80000204, 64'h300110f3, 64'h0, `R64_K_CSR);
    await_result;
    recovery[10] = 1;
    repeat (2) begin
      tick;
      check(result_valid && !serial_idle && status == saved_status,
            "inactive recovery candidate cancelled owner");
    end
    recovery[`R64_RECOVERY_ACTIVE(32)] = 1;
    #1;
    check(result_valid && !serial_idle, "source recovery bypassed local inbox");
    tick;
    recovery = 0;
    tick;
    check(serial_idle && !result_valid && status == saved_status,
          "active recovery failed to cancel unretired CSR");
    recovery = 0;
    empty_peer;
    $display("[CASE] recovery hint/active distinction and cancelled CSR has no effect PASS");

    issue(9'h08a, 64'h80000208, 64'h305110f3, 64'h80002000, `R64_K_CSR);
    await_result;
    check(!result[`R64_R_EXCEPTION], "mtvec write became illegal");
    accept_result;
    retire_serial;

    // Native ECALL completion supplies the exceptional candidate. The older
    // memory lease must drain before trap; trap flush releases Serial's owner.
    trace_ready = 0;
    issue(9'h08b, 64'h80000300, 64'h00000073, 64'd0, `R64_K_ECALL);
    await_result;
    check(result[`R64_R_EXCEPTION] && result[`R64_R_CAUSE] == 11,
          "native ECALL completion is not machine exception");
    accept_result;
    valid = 1; lsu_irrevocable = 1; before_count = accepted;
    repeat (3) begin
      tick;
      check(!trap && !flush && retire[1:0] == 0 && stop_birth &&
            !memory_effect[`R64_EFFECT_MEMORY(9)] && effect[8:0] == 9'h08b,
            "exception escaped older memory lease or authorized memory effect");
    end
    lsu_irrevocable = 0;
    tick;
    check(!trap && !flush && stop_birth && retire[1:0] == 0, "trap skipped preparation");
    tick;
    check(trap && flush && redirect && !trap_irq && trap_cause == 11 &&
          trap_pc == 64'h80000300 && trap_tval == 0 && trap_target == 64'h80002000 &&
          trap_raw == 64'h73 && trap_length == 4, "precise trap lost payload or vector");
    tick;
    empty_peer;
    check(serial_idle && !result_valid && !flush && accepted == before_count &&
          traps == 1 && !status[3] && status[7], "trap flush or CSR context incomplete");
    tick;
    check(!memory_effect[`R64_EFFECT_MEMORY(9)] && effect[`R64_EFFECT_SERIAL(9)] &&
          !effect[`R64_EFFECT_PRESENT(9)], "post-trap domain did not return to idle");
    $display("[CASE] memory irrevocable deferral/prepared trap/full-flush/CSR state PASS");
    // A memory grant is registered and persists through branch recovery and
    // external backpressure. Completion, not current allow, terminates it.
    empty_peer; trace_ready=0; count=1; head=9'h12c; tags[8:0]=head;
    meta[0+:M]=md(64'h80000400,64'h00003023,`R64_K_STORE);
    #1;
    check(!memory_effect[`R64_EFFECT_MEMORY(9)], "memory grant bypassed register");
    tick;
    check(memory_effect[`R64_EFFECT_MEMORY(9)] &&
          memory_effect[8:0]==head, "memory head did not receive tagged lease");
    recover=1;
    repeat(4) begin
      tick;
      check(memory_effect[`R64_EFFECT_MEMORY(9)] &&
            memory_effect[8:0]==head && !flush,
            "branch recovery revoked accepted memory permission");
    end
    recover=0; valid=1; trace_ready=1;
    tick;
    check(!memory_effect[`R64_EFFECT_MEMORY(9)], "terminal did not close lease");
    empty_peer; trace_ready=0; tick;
    check(!memory_effect[`R64_EFFECT_MEMORY(9)], "retired memory lease revived");
    // Fault arrives just after grant: lease releases first, then precise trap
    // preparation progresses without waiting for an impossible retirement.
    count=1; head=9'h14c; tags[8:0]=head;
    meta[0+:M]=md(64'h80000404,64'h00003003,`R64_K_LOAD);
    tick;
    check(memory_effect[`R64_EFFECT_MEMORY(9)], "fault case missing initial grant");
    valid=1; exception=1; head_exception=1; cause[5:0]=13; tval[63:0]=64'hbad000;
    tick;
    check(!memory_effect[`R64_EFFECT_MEMORY(9)] && !flush && !trap,
          "fault crossed lease or failed to release it");
    tick; tick;
    check(trap && flush && trap_cause==13 && trap_tval==64'hbad000,
          "released fault lease failed precise trap progress");
    tick; empty_peer; tick;
    $display("[CASE] registered memory grant/branch hold/terminal/fault drain PASS");
    $display("[PASS] tb_r64_control_domain checks=%0d retired=%0d traps=%0d flushes=%0d native_ports_only",
             checks, accepted, traps, flushes);
    $finish;
  end
  initial begin
    #20000;
    $fatal(1, "control domain timeout");
  end
endmodule
