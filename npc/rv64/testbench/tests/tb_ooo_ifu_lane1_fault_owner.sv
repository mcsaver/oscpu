`timescale 1ns/1ps
`include "define.v"
`include "common/OooSlotFacts.v"

// IFU-ACCESS-G1 / IFU-LANE1-OWNER permanent contract:
// 可见的 lane1 PF/AF 必须先成为 precise pending trap；只有随后证实 branch
// actual-taken 时才 squash。fetch-time pred-taken 截断的 poison slot1 从未成为 owner。
module tb_ooo_ifu_lane1_fault_owner;
  `include "tb_common.svh"

  localparam [`XLEN-1:0] PC0 = 64'h0000_0000_8000_1000;
  localparam [`XLEN-1:0] PC1 = 64'h0000_0000_8000_1004;
  localparam [`XLEN-1:0] FAULT_TVAL = 64'h0000_0000_8000_1006;
  localparam [`INST_W-1:0] INST_ADDI = 32'h0000_0093;
  localparam [`INST_W-1:0] INST_BNE_X0_X0 = 32'h0000_1063;
  localparam [`INST_W-1:0] INST_BEQ_X0_X0 = 32'h0000_0063;

  reg clk;
  reg rst;

  reg fifo_has_packet;
  reg head_slot1_valid;
  reg [1:0] head_resp0;
  reg [1:0] head_resp1;
  reg [`INST_W-1:0] head_inst0;
  reg [`INST_W-1:0] head_inst1;
  reg [`CTRL_BUS_W-1:0] head0_ctrl;
  reg [`CTRL_BUS_W-1:0] head1_ctrl;
  reg head0_branch_pred_taken;
  reg branch_resolve_untracked;
  reg drain_complete;

  // 这一路只用于锁住旧 ROB-walk 伪 ACCESS 过滤：arch_trap fact 存在、但没有
  // head_fetch_fault1 provenance 时，默认 cause=ACCESS 不得被误当成真实 IFU AF。
  reg pseudo_default_access;
  reg [`OOO_SLOT_FACTS_W-1:0] pseudo_head1_facts;

  wire head_fetch_fault0;
  wire head_fetch_fault1;
  wire head_fetch_fault;
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts0;
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts1;
  wire head0_fp_raw;
  wire head0_csr_raw;
  wire head1_fp_raw;
  wire head1_control_raw;
  wire head1_branch_raw;
  wire head1_jal_raw;
  wire head1_jalr_raw;
  wire head1_exit_raw;
  wire head1_system_raw;
  wire head1_arch_trap_raw;
  wire [`OOO_SLOT_FACTS_W-1:0] head0_facts;
  wire [`OOO_SLOT_FACTS_W-1:0] head1_facts;
  wire dispatch_valid;
  wire dispatch0_exit;
  wire dispatch0_arch_trap;
  wire dispatch0_system;
  wire dispatch0_fp;
  wire dispatch0_branch;
  wire dispatch0_jal;
  wire dispatch0_jump;
  wire direct_branch0_dispatch_valid;

  wire effective_head1_arch_trap =
      pseudo_default_access ? 1'b1 : head1_arch_trap_raw;
  wire [`OOO_SLOT_FACTS_W-1:0] effective_head1_facts =
      pseudo_default_access ? pseudo_head1_facts : head1_facts;

  wire dispatch_unsupported;
  wire dispatch_fire;
  wire dispatch1_barrier;
  wire dispatch1_barrier_fire;
  wire frontend_dispatch_to_backend_valid;
  wire dbranch_dual_go;

  wire pending_trap_clear_exit;
  wire pending_trap_clear_arch;
  wire pending_trap_clear_arch_squash;
  wire pending_trap_capture_exit;
  wire pending_trap_capture_exit_valid;
  wire pending_trap_capture_exit_ecall;
  wire pending_trap_capture_exit_ebreak;
  wire pending_trap_capture_arch;
  wire pending_trap_capture_arch_valid;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_capture_cause;
  wire [`XLEN-1:0] pending_trap_capture_pc;
  wire [`XLEN-1:0] pending_trap_capture_tval;

  wire pending_exit;
  wire pending_exit_ecall;
  wire pending_exit_ebreak;
  wire pending_arch_trap;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_cause;
  wire [`XLEN-1:0] pending_trap_pc;
  wire [`XLEN-1:0] pending_trap_tval;
  wire stop_pending;

  wire pending_arch_trap_fire;
  wire trap_ex_valid;
  wire [`TRAP_CAUSE_W-1:0] trap_ex_cause;
  wire [`XLEN-1:0] trap_ex_pc;
  wire [`XLEN-1:0] trap_ex_tval;

  OooFetchStaticClassify u_static0 (
    .inst_i(head_inst0),
    .semihost_peer_inst_i(head_inst1),
    .semihost_peer_is_enter_i(1'b0),
    .static_facts_o(head_static_facts0)
  );

  OooFetchStaticClassify u_static1 (
    .inst_i(head_inst1),
    .semihost_peer_inst_i(head_inst0),
    .semihost_peer_is_enter_i(1'b1),
    .static_facts_o(head_static_facts1)
  );

  OooFetchHeadPairGate u_pair (
    .fifo_has_packet_i(fifo_has_packet),
    .head_slot1_valid_i(head_slot1_valid),
    .head_resp0_i(head_resp0),
    .head_resp1_i(head_resp1),
    .head_static_facts0_i(head_static_facts0),
    .head_static_facts1_i(head_static_facts1),
    .head0_ctrl_i(head0_ctrl),
    .head1_ctrl_i(head1_ctrl),
    .priv_mode_i(`PRIV_M),
    .mstatus_i(`MSTATUS_FS_CLEAN),
    .frm_i(3'b000),
    .branch_spec_active_i(1'b0),
    .can_run_i(1'b1),
    .csr_irq_pending_i(1'b0),
    .head_fetch_fault0_o(head_fetch_fault0),
    .head_fetch_fault1_o(head_fetch_fault1),
    .head_fetch_fault_o(head_fetch_fault),
    .head0_fp_raw_o(head0_fp_raw),
    .head0_csr_raw_o(head0_csr_raw),
    .head0_facts_o(head0_facts),
    .head1_control_raw_o(head1_control_raw),
    .head1_branch_raw_o(head1_branch_raw),
    .head1_jal_raw_o(head1_jal_raw),
    .head1_jalr_raw_o(head1_jalr_raw),
    .head1_fp_raw_o(head1_fp_raw),
    .head1_exit_raw_o(head1_exit_raw),
    .head1_system_raw_o(head1_system_raw),
    .head1_arch_trap_raw_o(head1_arch_trap_raw),
    .head1_facts_o(head1_facts),
    .dispatch_valid_o(dispatch_valid),
    .dispatch0_exit_o(dispatch0_exit),
    .dispatch0_arch_trap_o(dispatch0_arch_trap),
    .dispatch0_system_o(dispatch0_system),
    .dispatch0_fp_o(dispatch0_fp),
    .dispatch0_branch_o(dispatch0_branch),
    .dispatch0_jal_o(dispatch0_jal),
    .dispatch0_jump_o(dispatch0_jump),
    .direct_branch0_dispatch_valid_o(direct_branch0_dispatch_valid)
  );

  OooFrontendDispatchGate u_dispatch (
    .dispatch_valid_i(dispatch_valid),
    .dispatch0_exit_i(dispatch0_exit),
    .dispatch0_arch_trap_i(dispatch0_arch_trap),
    .dispatch0_system_i(dispatch0_system),
    .dispatch0_csr_i(head0_csr_raw),
    .dispatch0_fp_i(dispatch0_fp),
    .head0_branch_pred_taken_i(head0_branch_pred_taken),
    .head_slot1_valid_i(head_slot1_valid),
    .dispatch0_branch_i(dispatch0_branch),
    .dispatch0_jal_i(dispatch0_jal),
    .dispatch0_jump_i(dispatch0_jump),
    .dispatch0_return_i(1'b0),
    .dispatch0_unsupported_i(1'b0),
    .dispatch1_unsupported_i(1'b0),
    .dispatch0_unsupported_raw_i(1'b0),
    .dispatch1_unsupported_raw_i(1'b0),
    .dispatch0_ready_i(1'b1),
    .dispatch1_ready_i(1'b1),
    .head0_fp_raw_i(head0_fp_raw),
    .head1_fp_raw_i(head1_fp_raw),
    .head_fetch_fault1_i(head_fetch_fault1),
    .head1_exit_raw_i(head1_exit_raw),
    .head1_system_raw_i(head1_system_raw),
    .head1_arch_trap_raw_i(effective_head1_arch_trap),
    .head1_control_raw_i(head1_control_raw),
    .head1_branch_raw_i(head1_branch_raw),
    .head1_jal_raw_i(head1_jal_raw),
    .head1_jalr_raw_i(head1_jalr_raw),
    .head1_jal_call_raw_i(1'b0),
    .head1_return_candidate_i(1'b0),
    .lane0_before_ret_safe_i(1'b1),
    .dispatch1_barrier_o(dispatch1_barrier),
    .dispatch_unsupported_o(dispatch_unsupported),
    .dispatch_fire_o(dispatch_fire),
    .dispatch1_barrier_fire_o(dispatch1_barrier_fire),
    .frontend_dispatch_to_backend_valid_o(
        frontend_dispatch_to_backend_valid),
    .dbranch_dual_go_o(dbranch_dual_go)
  );

  OooPendingDispatchArbiter u_pending_arbiter (
    .csr_trap_mem_valid_i(1'b0),
    .direct_frontend_flush_i(1'b0),
    .can_run_i(1'b1),
    .fifo_has_packet_i(fifo_has_packet),
    .csr_irq_pending_i(1'b0),
    .branch_spec_resolve_valid_i(1'b0),
    .pending_branch_commit_resolve_i(1'b0),
    .pending_branch_match_clear_i(1'b0),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .pending_jump_nolink_commit_i(1'b0),
    .pending_jump_redirect_after_dispatch_i(1'b0),
    .pending_system_csr_commit_i(1'b0),
    .head0_csr_commit_i(1'b0),
    .stop_pending_i(stop_pending),
    .drain_complete_i(drain_complete),
    .direct_branch0_fire_i(1'b0),
    .direct_branch1_fire_i(1'b0),
    .head_fetch_fault0_i(head_fetch_fault0),
    .head_fetch_fault1_i(head_fetch_fault1),
    .head_fetch_fault_tval_i(FAULT_TVAL),
    .head_resp0_i(head_resp0),
    .head_resp1_i(head_resp1),
    .head_pc0_i(PC0),
    .head_pc1_i(PC1),
    .head_inst0_i(head_inst0),
    .head_inst1_i(head_inst1),
    .dispatch0_facts_i(head0_facts),
    .head1_facts_i(effective_head1_facts),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid),
    .direct_jal0_dispatch_valid_i(1'b0),
    .dispatch0_return_i(1'b0),
    .dispatch0_unsupported_i(1'b0),
    .dispatch_unsupported_i(dispatch_unsupported),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .head0_csr_illegal_i(1'b0),
    .head1_csr_illegal_i(1'b0),
    .rob_walk_mode_i(1'b1),
    .pending_trap_exit_clear_exit_o(pending_trap_clear_exit),
    .pending_trap_exit_clear_arch_o(pending_trap_clear_arch),
    .pending_trap_exit_clear_arch_squash_o(
        pending_trap_clear_arch_squash),
    .pending_trap_exit_capture_exit_o(pending_trap_capture_exit),
    .pending_trap_exit_capture_exit_valid_o(
        pending_trap_capture_exit_valid),
    .pending_trap_exit_capture_exit_ecall_o(
        pending_trap_capture_exit_ecall),
    .pending_trap_exit_capture_exit_ebreak_o(
        pending_trap_capture_exit_ebreak),
    .pending_trap_exit_capture_arch_o(pending_trap_capture_arch),
    .pending_trap_exit_capture_arch_valid_o(
        pending_trap_capture_arch_valid),
    .pending_trap_exit_capture_cause_o(pending_trap_capture_cause),
    .pending_trap_exit_capture_pc_o(pending_trap_capture_pc),
    .pending_trap_exit_capture_tval_o(pending_trap_capture_tval)
  );

  OooPendingTrapExitSequencer u_pending_trap (
    .clk(clk),
    .rst(rst),
    .late_clear_i(1'b0),
    .clear_exit_i(pending_trap_clear_exit),
    .clear_arch_i(pending_trap_clear_arch),
    .clear_arch_squash_i(pending_trap_clear_arch_squash),
    .capture_exit_i(pending_trap_capture_exit),
    .capture_exit_valid_i(pending_trap_capture_exit_valid),
    .capture_exit_is_ecall_i(pending_trap_capture_exit_ecall),
    .capture_exit_is_ebreak_i(pending_trap_capture_exit_ebreak),
    .capture_arch_i(pending_trap_capture_arch),
    .capture_arch_valid_i(pending_trap_capture_arch_valid),
    .capture_trap_cause_i(pending_trap_capture_cause),
    .capture_trap_pc_i(pending_trap_capture_pc),
    .capture_trap_tval_i(pending_trap_capture_tval),
    .pending_exit_o(pending_exit),
    .pending_exit_is_ecall_o(pending_exit_ecall),
    .pending_exit_is_ebreak_o(pending_exit_ebreak),
    .pending_arch_trap_o(pending_arch_trap),
    .pending_trap_cause_o(pending_trap_cause),
    .pending_trap_pc_o(pending_trap_pc),
    .pending_trap_tval_o(pending_trap_tval)
  );

  OooStopPendingSequencer u_stop (
    .clk(clk),
    .rst(rst),
    .flush_i(1'b0),
    .csr_trap_mem_valid_i(1'b0),
    .direct_frontend_flush_i(1'b0),
    .direct_branch0_fire_i(1'b0),
    .direct_branch1_fire_i(1'b0),
    .direct_branch_resolve_redirect_i(1'b0),
    .branch_spec_checkpoint_capture_i(1'b0),
    .branch_spec_resolve_valid_i(1'b0),
    .orphan_stop_pending_i(1'b0),
    .pending_branch_commit_resolve_i(1'b0),
    .pending_branch_match_clear_i(1'b0),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .pending_jump_nolink_commit_i(1'b0),
    .pending_jump_redirect_after_dispatch_i(1'b0),
    .jump_dispatch_fire_i(1'b0),
    .pending_mem_resolve_ready_i(1'b0),
    .system_csr_dispatch_fire_i(1'b0),
    .pending_system_csr_commit_i(1'b0),
    .head0_csr_commit_i(1'b0),
    .head0_csr_inflight_i(1'b0),
    .drain_complete_i(drain_complete),
    .can_run_i(1'b1),
    .fifo_has_packet_i(fifo_has_packet),
    .csr_irq_pending_i(1'b0),
    .head_fetch_fault0_i(head_fetch_fault0),
    .dispatch0_arch_trap_i(dispatch0_arch_trap),
    .dispatch0_exit_i(dispatch0_exit),
    .dispatch0_fp_i(dispatch0_fp),
    .dispatch0_system_i(dispatch0_system),
    .head0_csr_illegal_i(1'b0),
    .dispatch0_branch_i(dispatch0_branch),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid),
    .dispatch0_jal_i(dispatch0_jal),
    .direct_jal0_dispatch_valid_i(1'b0),
    .dispatch0_jump_i(dispatch0_jump),
    .dispatch0_return_i(1'b0),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .dispatch_unsupported_i(dispatch_unsupported),
    .rob_walk_mode_i(1'b1),
    .stop_pending_o(stop_pending)
  );

  OooCsrTrapRequestMux u_trap_request (
    .core_commit0_valid_i(1'b0),
    .core_commit0_exception_i(1'b0),
    .core_commit0_pc_i({`XLEN{1'b0}}),
    .core_commit0_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .core_commit0_tval_i({`XLEN{1'b0}}),
    .core_commit1_valid_i(1'b0),
    .core_commit1_exception_i(1'b0),
    .core_commit1_pc_i({`XLEN{1'b0}}),
    .core_commit1_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .core_commit1_tval_i({`XLEN{1'b0}}),
    .stop_pending_i(stop_pending),
    .drain_complete_i(drain_complete),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_trap_cause_i(pending_trap_cause),
    .pending_trap_pc_i(pending_trap_pc),
    .pending_trap_tval_i(pending_trap_tval),
    .pending_system_i(1'b0),
    .pending_system_ecall_i(1'b0),
    .pending_system_mret_i(1'b0),
    .pending_system_irq_i(1'b0),
    .pending_system_pc_i({`XLEN{1'b0}}),
    .pending_system_inst_i({`INST_W{1'b0}}),
    .pending_system_irq_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .csr_ecall_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .pending_system_satp_write_commit_i(1'b0),
    .pending_system_sfence_commit_i(1'b0),
    .pending_arch_trap_fire_o(pending_arch_trap_fire),
    .trap_ex_valid_o(trap_ex_valid),
    .trap_ex_pc_o(trap_ex_pc),
    .trap_ex_cause_o(trap_ex_cause),
    .trap_ex_tval_o(trap_ex_tval)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic clear_drive;
    begin
      fifo_has_packet = 1'b0;
      head_slot1_valid = 1'b1;
      head_resp0 = 2'b00;
      head_resp1 = 2'b00;
      head_inst0 = INST_ADDI;
      head_inst1 = INST_ADDI;
      head0_ctrl = {`CTRL_BUS_W{1'b0}};
      head1_ctrl = {`CTRL_BUS_W{1'b0}};
      // 合法普通指令必须带 NEED_EXEC，避免 unsupported residual 干扰 owner 矩阵。
      head0_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      head1_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      head0_branch_pred_taken = 1'b0;
      branch_resolve_untracked = 1'b0;
      drain_complete = 1'b0;
      pseudo_default_access = 1'b0;
      pseudo_head1_facts = {`OOO_SLOT_FACTS_W{1'b0}};
    end
  endtask

  task automatic reset_case;
    begin
      clear_drive();
      rst = 1'b1;
      tick();
      rst = 1'b0;
      tick();
    end
  endtask

  task automatic arm_fault_packet;
    input is_branch;
    input predicted_taken;
    input slot1_valid;
    input [1:0] response;
    input actual_taken_encoding;
    begin
      clear_drive();
      fifo_has_packet = 1'b1;
      head_slot1_valid = slot1_valid;
      head_resp1 = response;
      head0_branch_pred_taken = predicted_taken;
      if (is_branch) begin
        head_inst0 = actual_taken_encoding ? INST_BEQ_X0_X0 :
                                             INST_BNE_X0_X0;
        head0_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
      end
      #1;
    end
  endtask

  // 每个 matrix row 只累计一个 verdict，避免同一断链造成级联 error 数膨胀。
  task automatic check_row;
    input [1023:0] name;
    input row_ok;
    begin
      if (row_ok === 1'b1) begin
        $display("[ROW-PASS] %0s", name);
      end else begin
        tb_errors = tb_errors + 1;
        $display("[ROW-FAIL] %0s fault1=%b dual=%b barrier=%b fire=%b capture=%b/%b pending=%b stop=%b cause=%h pc=%h tval=%h trap_ex=%b",
                 name, head_fetch_fault1, dbranch_dual_go,
                 dispatch1_barrier, dispatch1_barrier_fire,
                 pending_trap_capture_arch, pending_trap_capture_arch_valid,
                 pending_arch_trap, stop_pending, pending_trap_cause,
                 pending_trap_pc, pending_trap_tval, trap_ex_valid);
      end
    end
  endtask

  task automatic run_terminal_fault_row;
    input [1023:0] name;
    input is_branch;
    input [1:0] response;
    input [`TRAP_CAUSE_W-1:0] expected_cause;
    reg pair_ok;
    reg dispatch_ok;
    reg capture_request_ok;
    reg captured_ok;
    reg drained_ok;
    begin
      reset_case();
      arm_fault_packet(is_branch, 1'b0, 1'b1, response, 1'b0);
      pair_ok = (head_fetch_fault1 === 1'b1);
      dispatch_ok =
          (dbranch_dual_go === 1'b0) &&
          (dispatch_fire === 1'b0) &&
          (dispatch1_barrier === 1'b1) &&
          (dispatch1_barrier_fire === 1'b1) &&
          (frontend_dispatch_to_backend_valid === 1'b0);
      capture_request_ok =
          (pending_trap_capture_arch === 1'b1) &&
          (pending_trap_capture_arch_valid === 1'b1) &&
          (pending_trap_capture_cause === expected_cause) &&
          (pending_trap_capture_pc === PC1) &&
          (pending_trap_capture_tval === FAULT_TVAL);
      tick();
      captured_ok =
          (pending_arch_trap === 1'b1) &&
          (stop_pending === 1'b1) &&
          (pending_trap_cause === expected_cause) &&
          (pending_trap_pc === PC1) &&
          (pending_trap_tval === FAULT_TVAL);
      // barrier fire 后 packet 已 pop；drain 点必须把 pending owner 变成 CSR trap request。
      fifo_has_packet = 1'b0;
      drain_complete = 1'b1;
      #1;
      drained_ok =
          (pending_arch_trap_fire === 1'b1) &&
          (trap_ex_valid === 1'b1) &&
          (trap_ex_cause === expected_cause) &&
          (trap_ex_pc === PC1) &&
          (trap_ex_tval === FAULT_TVAL);
      $display("[ROW-STAGES] %0s pair=%b dispatch=%b capture_req=%b pending=%b drain=%b",
               name, pair_ok, dispatch_ok, capture_request_ok, captured_ok,
               drained_ok);
      check_row(name, pair_ok && dispatch_ok && capture_request_ok &&
                      captured_ok && drained_ok);
    end
  endtask

  task automatic run_actual_taken_squash_row;
    input [1023:0] name;
    input [1:0] response;
    input [`TRAP_CAUSE_W-1:0] expected_cause;
    reg captured_ok;
    reg squashed_ok;
    reg pair_ok;
    reg dispatch_ok;
    reg capture_request_ok;
    begin
      reset_case();
      arm_fault_packet(1'b1, 1'b0, 1'b1, response, 1'b1);
      pair_ok = (head_fetch_fault1 === 1'b1);
      dispatch_ok =
          (dbranch_dual_go === 1'b0) &&
          (dispatch1_barrier_fire === 1'b1);
      capture_request_ok =
          (pending_trap_capture_arch === 1'b1) &&
          (pending_trap_capture_cause === expected_cause);
      tick();
      captured_ok =
          (pending_arch_trap === 1'b1) &&
          (stop_pending === 1'b1) &&
          (pending_trap_cause === expected_cause);

      // actual-taken resolve 将此前 pred-NT 可见的 lane1 fault 认定为 wrong-path。
      fifo_has_packet = 1'b0;
      branch_resolve_untracked = 1'b1;
      tick();
      squashed_ok =
          (pending_arch_trap === 1'b0) &&
          (stop_pending === 1'b0) &&
          (pending_trap_cause === {`TRAP_CAUSE_W{1'b0}}) &&
          (pending_trap_pc === {`XLEN{1'b0}}) &&
          (pending_trap_tval === {`XLEN{1'b0}}) &&
          (trap_ex_valid === 1'b0);
      $display("[ROW-STAGES] %0s pair=%b dispatch=%b capture_req=%b pending=%b squash=%b",
               name, pair_ok, dispatch_ok, capture_request_ok, captured_ok,
               squashed_ok);
      check_row(name, pair_ok && dispatch_ok && capture_request_ok &&
                      captured_ok && squashed_ok);
    end
  endtask

  task automatic run_pred_taken_poison_row;
    input [1023:0] name;
    input [1:0] response;
    reg row_ok;
    begin
      reset_case();
      arm_fault_packet(1'b1, 1'b1, 1'b0, response, 1'b1);
      row_ok =
          (head_fetch_fault1 === 1'b0) &&
          (dbranch_dual_go === 1'b0) &&
          (dispatch1_barrier === 1'b0) &&
          (dispatch1_barrier_fire === 1'b0) &&
          (pending_trap_capture_arch === 1'b0);
      tick();
      row_ok = row_ok &&
          (pending_arch_trap === 1'b0) &&
          (stop_pending === 1'b0) &&
          (trap_ex_valid === 1'b0);
      check_row(name, row_ok);
    end
  endtask

  task automatic run_pseudo_default_access_row;
    reg row_ok;
    begin
      reset_case();
      clear_drive();
      fifo_has_packet = 1'b1;
      pseudo_default_access = 1'b1;
      pseudo_head1_facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b1;
      #1;
      row_ok =
          (head_fetch_fault1 === 1'b0) &&
          (dispatch1_barrier_fire === 1'b1) &&
          (pending_trap_capture_cause === `EXC_INST_ACCESS_FAULT) &&
          (pending_trap_capture_arch === 1'b0) &&
          (pending_trap_capture_arch_valid === 1'b0);
      tick();
      row_ok = row_ok && (pending_arch_trap === 1'b0);

      // barrier 的 stop 仍需随 squash 清掉；不能用“永远 stop”伪装成 no-trap。
      fifo_has_packet = 1'b0;
      branch_resolve_untracked = 1'b1;
      tick();
      row_ok = row_ok &&
          (stop_pending === 1'b0) &&
          (pending_trap_pc === {`XLEN{1'b0}}) &&
          (trap_ex_valid === 1'b0);
      check_row("pseudo arch_trap default ACCESS without fault provenance",
                row_ok);
    end
  endtask

  initial begin
    tb_errors = 0;
    rst = 1'b1;
    clear_drive();

    run_terminal_fault_row("ordinary head0 + lane1 PF",
                           1'b0, 2'b10, `EXC_INST_PAGE_FAULT);
    run_terminal_fault_row("ordinary head0 + lane1 AF",
                           1'b0, 2'b01, `EXC_INST_ACCESS_FAULT);
    run_terminal_fault_row("pred-NT correct-NT branch + lane1 PF",
                           1'b1, 2'b10, `EXC_INST_PAGE_FAULT);
    run_terminal_fault_row("pred-NT correct-NT branch + lane1 AF",
                           1'b1, 2'b01, `EXC_INST_ACCESS_FAULT);
    run_actual_taken_squash_row("pred-NT actual-taken branch squashes PF",
                                2'b10, `EXC_INST_PAGE_FAULT);
    run_actual_taken_squash_row("pred-NT actual-taken branch squashes AF",
                                2'b01, `EXC_INST_ACCESS_FAULT);
    run_pred_taken_poison_row("pred-taken poison lane1 PF is invisible",
                              2'b10);
    run_pred_taken_poison_row("pred-taken poison lane1 AF is invisible",
                              2'b01);
    run_pseudo_default_access_row();
    $display("[T4G-IFU-LANE1-FAULT-TVAL] PC=%h tval=%h survives capture/pending/drain",
             PC1, FAULT_TVAL);

    tb_finish("tb_ooo_ifu_lane1_fault_owner");
  end
endmodule
