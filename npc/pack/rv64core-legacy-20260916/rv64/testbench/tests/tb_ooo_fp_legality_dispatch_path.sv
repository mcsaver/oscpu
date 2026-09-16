`timescale 1ns/1ps
`include "define.v"
`include "common/OooSlotFacts.v"
`include "tb_common.svh"

// FDG-G1 常驻整链回归：不能把“classifier 已标 trap”误当成“backend 已被阻断”。
// 这里把真实 DecodeUnit + FP classifier + dispatch gate 串起来，分别验证四类保留编码
// 与合法 FADD.S 正对照；后续任何一端合同漂移都会让本测试失败。
module tb_ooo_fp_legality_dispatch_path;
  reg [`INST_W-1:0] inst;
  reg [2:0] frm;
  wire [`CTRL_BUS_W-1:0] ctrl;
  wire illegal_raw;
  wire fp_raw;
  wire fp_enabled;
  wire arch_trap;
  wire frontend_backend_valid;
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] static_facts;
  integer illegal_fp_cases;
  integer illegal_classified_cases;
  integer arch_trap_cases;
  integer fp_disabled_cases;
  integer backend_blocked_cases;

  DecodeUnit u_decode (
    .inst_i(inst),
    .ctrl_o(ctrl)
  );

  OooFetchStaticClassify u_static_classify (
    .inst_i(inst),
    .semihost_peer_inst_i({`INST_W{1'b0}}),
    .semihost_peer_is_enter_i(1'b0),
    .static_facts_o(static_facts)
  );

  OooFetchHeadClassifyGate u_classify (
    .decode_valid_i(1'b1),
    .fetch_fault_i(1'b0),
    .static_facts_i(static_facts),
    .ctrl_i(ctrl),
    .priv_mode_i(`PRIV_M),
    .mstatus_i(`MSTATUS_FS_DIRTY),
    .frm_i(frm),
    .illegal_raw_o(illegal_raw),
    .fp_raw_o(fp_raw),
    .fp_enabled_o(fp_enabled),
    .arch_trap_raw_o(arch_trap)
  );

  OooFrontendDispatchGate u_dispatch_gate (
    .dispatch_valid_i(1'b1),
    .dispatch0_exit_i(1'b0),
    .dispatch0_arch_trap_i(arch_trap),
    .dispatch0_system_i(1'b0),
    .dispatch0_csr_i(1'b0),
    .dispatch0_fp_i(fp_enabled),
    .head0_branch_pred_taken_i(1'b0),
    .head_slot1_valid_i(1'b0),
    .dispatch0_branch_i(1'b0),
    .dispatch0_jal_i(1'b0),
    .dispatch0_jump_i(1'b0),
    .dispatch0_return_i(1'b0),
    .dispatch0_unsupported_i(1'b0),
    .dispatch1_unsupported_i(1'b0),
    .dispatch0_ready_i(1'b1),
    .dispatch1_ready_i(1'b1),
    .head0_fp_raw_i(fp_raw),
    .head1_fp_raw_i(1'b0),
    .head_fetch_fault1_i(1'b0),
    .head1_exit_raw_i(1'b0),
    .head1_system_raw_i(1'b0),
    .head1_arch_trap_raw_i(1'b0),
    .head1_control_raw_i(1'b0),
    .head1_branch_raw_i(1'b0),
    .head1_jal_raw_i(1'b0),
    .head1_jalr_raw_i(1'b0),
    .head1_jal_call_raw_i(1'b0),
    .head1_return_candidate_i(1'b0),
    .lane0_before_ret_safe_i(1'b0),
    .frontend_dispatch_to_backend_valid_o(frontend_backend_valid)
  );

  task automatic expect_rejected;
    input [`INST_W-1:0] test_inst;
    input [2:0] test_frm;
    input [8*32-1:0] label;
    begin
      inst = test_inst;
      frm = test_frm;
      #1;
      tb_check1({label, " classified illegal"}, illegal_raw, 1'b1);
      tb_check1({label, " classified arch trap"}, arch_trap, 1'b1);
      tb_check1({label, " excluded from FP cluster"}, fp_enabled, 1'b0);
      tb_check1({label, " blocked before backend"}, frontend_backend_valid, 1'b0);
      illegal_fp_cases = illegal_fp_cases + 1;
      if (illegal_raw === 1'b1)
        illegal_classified_cases = illegal_classified_cases + 1;
      if (arch_trap === 1'b1)
        arch_trap_cases = arch_trap_cases + 1;
      if (fp_enabled === 1'b0)
        fp_disabled_cases = fp_disabled_cases + 1;
      if (frontend_backend_valid === 1'b0)
        backend_blocked_cases = backend_blocked_cases + 1;
    end
  endtask

  initial begin
    tb_errors = 0;
    inst = {`INST_W{1'b0}};
    frm = 3'b000;
    illegal_fp_cases = 0;
    illegal_classified_cases = 0;
    arch_trap_cases = 0;
    fp_disabled_cases = 0;
    backend_blocked_cases = 0;
    #1;

    expect_rejected(
        {7'b0111111, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
        3'b000, "unknown OP-FP funct7");
    expect_rejected(
        {5'd4, 2'b10, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_MADD},
        3'b000, "reserved FMA fmt");
    expect_rejected(
        {7'b0000000, 5'd3, 5'd2, 3'b101, 5'd1, `OPCODE_OP_FP},
        3'b000, "reserved static rm");
    expect_rejected(
        {7'b0000000, 5'd3, 5'd2, 3'b111, 5'd1, `OPCODE_OP_FP},
        3'b101, "reserved dynamic frm");

    // 正对照：合法 FADD.S + RNE 必须继续进入 FP/backend，防止用“全部关断”假修复。
    inst = {7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP};
    frm = 3'b000;
    #1;
    tb_check1("legal FADD.S recognized", fp_raw, 1'b1);
    tb_check1("legal FADD.S enabled", fp_enabled, 1'b1);
    tb_check1("legal FADD.S no illegal", illegal_raw, 1'b0);
    tb_check1("legal FADD.S no trap", arch_trap, 1'b0);
    tb_check1("legal FADD.S reaches backend", frontend_backend_valid, 1'b1);

    if ((illegal_fp_cases == 4) &&
        (illegal_classified_cases == 4) &&
        (arch_trap_cases == 4) &&
        (fp_disabled_cases == 4) &&
        (backend_blocked_cases == 4) &&
        (fp_raw === 1'b1) &&
        (fp_enabled === 1'b1) &&
        (illegal_raw === 1'b0) &&
        (arch_trap === 1'b0) &&
        (frontend_backend_valid === 1'b1)) begin
      $display("[FDG-G1-FOCUSED] illegal_fp_cases=4 illegal_classified=4 arch_trap=4 fp_disabled=4 backend_blocked=4 legal_fp_cases=1 legal_backend_present=1 PASS");
    end

    tb_finish("tb_ooo_fp_legality_dispatch_path");
  end
endmodule
