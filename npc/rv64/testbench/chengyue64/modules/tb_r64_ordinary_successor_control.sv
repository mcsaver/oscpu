`timescale 1ns / 1ps
// Native Control peer; no backend, ROB, rename, decoder or private UOP layout.
`include "R64Protocol.vh"
module tb_r64_ordinary_successor_control;
  parameter N1=0;
  parameter N2=1;
  reg [1:0] writes=0;
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

  R64Control #(.SUCCESSOR_STORE_LEASE(N1), .ORDINARY_SUCCESSOR_STORE_LEASE(N2)) dut (
    .serial_retire_candidate_i(valid[0] && !exception[0] && serial_class[0]),
    .pair_store_candidate_valid_i(1'b0),.pair_store_candidate_tag_i(9'b0),
    .clk_i(clk), .rst_i(rst), .run_i(1'b1),
    .irq_software_i(1'b0), .irq_timer_i(1'b0), .irq_external_i(1'b0),
    .irq_supervisor_external_i(1'b0), .wfi_wait_i(1'b0), .time_i(64'd0),
    .rob_valid_i(valid), .rob_serial_i(serial_class), .rob_exception_i(exception),
    .rob_write_i(writes), .rob_fp_i(2'b00), .rob_ready_o(rob_ready),
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

  wire lease_valid=memory_effect[`R64_EFFECT_MEMORY(9)];
  task reset_phase;
    begin
      rst=1;valid=0;count=0;head=0;tags=0;meta=0;serial_class=0;writes=0;
      recover=0;exception=0;head_exception=0;head_serial=0;trace_ready=0;tick;rst=0;tick;
    end
  endtask

  task resident_pair(input[7:0]oldkind,input[7:0]nextkind);
    begin
      count=2;head=9'h11f;tags={9'h120,9'h11f};valid=1;trace_ready=1;writes=1;
      meta={md(64'h80000004,64'h23,nextkind),md(64'h80000000,64'h13,oldkind)};
      #1;
    end
  endtask
  task retire_current(input expect_early);
    begin
      check(retire[1:0]==1,"ordinary predecessor did not actually retire");
      check(dut.successor_grant_w==(N2!=0&&expect_early),"current Q pair grant qualification");
      check(!lease_valid,"new successor lease appeared before retirement edge");
      tick;
      head=tags[17:9];tags={9'b0,head};meta={{M{1'b0}},meta[M+:M]};count=1;valid=0;writes=0;
      check(lease_valid==(N2!=0&&expect_early),"retirement edge did not register exact successor");
      if(lease_valid)check(memory_effect[8:0]==head,"wrong successor full tag");
      tick;check(lease_valid&&memory_effect[8:0]==head,"normal fallback did not grant new memory head");
    end
  endtask
  initial begin
    // No preceding clock can have captured a pair hint. Old destination writes
    // are legal for NORMAL/BRANCH/LOAD; only the next store must be a nonwriter.
    for(integer kind=0;kind<4;kind=kind+1)begin
      reset_phase;resident_pair(8'(kind),`R64_K_STORE);retire_current(1);
    end
    for(integer kind=4;kind<17;kind=kind+1)begin
      reset_phase;resident_pair(8'(kind),`R64_K_STORE);
      check(!dut.successor_grant_w,"unsupported predecessor granted successor");
    end
    for(integer kind=0;kind<17;kind=kind+1)if(kind!=3)begin
      reset_phase;resident_pair(`R64_K_NORMAL,8'(kind));
      check(!dut.successor_grant_w,"nonstore successor granted");
    end
    reset_phase;resident_pair(`R64_K_NORMAL,`R64_K_STORE);
    trace_ready=0;repeat(3)begin tick;check(!lease_valid&&!dut.successor_grant_w,"Trace stall installed lease");end
    trace_ready=1;#1;retire_current(1);
    reset_phase;resident_pair(`R64_K_NORMAL,`R64_K_STORE);recover=1;#1;
    check(retire[1:0]==0&&!dut.successor_grant_w,"recovery granted successor");
    recover=0;#1;retire_current(1);
    // Qualification failures are exact and retain normal fallback.
    for(integer bad=0;bad<7;bad=bad+1)begin
      reset_phase;resident_pair(`R64_K_NORMAL,`R64_K_STORE);
      case(bad)
        0:writes=3;
        1:serial_class=1;
        2:serial_class=2;
        3:count=1;
        4:head=9'h13f;
        5:begin valid=3;trace_ready=3;end
        6:begin valid=3;trace_ready=1;exception=2;end
      endcase
      #1;check(!dut.successor_grant_w,"ineligible current Q candidate granted");
    end
    reset_phase;resident_pair(`R64_K_NORMAL,`R64_K_STORE);exception=1;head_exception=1;#1;
    check(retire[1:0]==0&&!dut.successor_grant_w,"fault predecessor granted");
    // Full tag comes from the currently resident Q owner, never old hint data.
    reset_phase;resident_pair(`R64_K_NORMAL,`R64_K_STORE);tags[17:9]=9'h140;#1;
    retire_current(1);check(memory_effect[8:0]==9'h140,"current generation was not preserved");
    $display("[PASS] tb_r64_ordinary_successor_control N1=%0d N2=%0d checks=%0d current_Q_no_hint_class_write_prefix_fault_Trace_recovery=1",N1,N2,checks);
    $finish;
  end
  initial begin #30000;$fatal(1,"ordinary successor control timeout");end
endmodule
