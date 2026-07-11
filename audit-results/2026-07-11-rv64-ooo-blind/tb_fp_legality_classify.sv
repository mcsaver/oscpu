`timescale 1ns/1ps
`include "define.v"

module tb_fp_legality_classify;
  reg [31:0] inst;
  reg [2:0] frm;
  wire [`CTRL_BUS_W-1:0] ctrl;
  wire illegal_raw;
  wire fp_raw;
  wire fp_enabled;
  wire arch_trap;
  wire frontend_backend_valid;

  DecodeUnit decode (
    .inst_i(inst),
    .ctrl_o(ctrl)
  );

  OooFetchHeadClassifyGate classify (
    .decode_valid_i(1'b1),
    .fetch_fault_i(1'b0),
    .inst_i(inst),
    .semihost_peer_inst_i(32'b0),
    .semihost_peer_is_enter_i(1'b0),
    .ctrl_i(ctrl),
    .priv_mode_i(`PRIV_M),
    .mstatus_i(`MSTATUS_FS_DIRTY),
    .frm_i(frm),
    .illegal_raw_o(illegal_raw),
    .fp_raw_o(fp_raw),
    .fp_enabled_o(fp_enabled),
    .arch_trap_raw_o(arch_trap)
  );

  // 继续追到真实前端 dispatch gate，避免把“已分类为 trap”误当成
  // “已经阻止送往后端”。其余输入固定为普通 head0、无 lane1 的最小场景。
  OooFrontendDispatchGate dispatch_gate (
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
    .dispatch0_unsupported_raw_i(1'b0),
    .dispatch1_unsupported_raw_i(1'b0),
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

  task expect_rejected;
    input [31:0] test_inst;
    input [2:0] test_frm;
    input [8*32-1:0] label;
    begin
      inst = test_inst;
      frm = test_frm;
      #1;
      if (illegal_raw && arch_trap && !fp_enabled && frontend_backend_valid)
        $display("TRAP_CLASSIFIED_BUT_BACKEND_PRESENT %0s fp_raw=%0d", label, fp_raw);
      else begin
        $display("PATH_MISMATCH %0s illegal=%0d trap=%0d fp_raw=%0d fp_enabled=%0d backend=%0d",
                 label, illegal_raw, arch_trap, fp_raw, fp_enabled,
                 frontend_backend_valid);
        $finish_and_return(2);
      end
    end
  endtask

  initial begin
    inst = 32'b0;
    frm = 3'b000;
    #1;

    // OP-FP 未识别 funct7。
    expect_rejected({7'b0111111, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP},
                    3'b000, "unknown OP-FP funct7");

    // FMA 的 fmt=10 不属于当前实现的 S/D 格式。
    expect_rejected({5'd4, 2'b10, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_MADD},
                    3'b000, "reserved FMA fmt");

    // 静态 rm=101 应在前端分类阶段被拒绝。
    expect_rejected({7'b0000000, 5'd3, 5'd2, 3'b101, 5'd1, `OPCODE_OP_FP},
                    3'b000, "reserved static rm");

    // 动态 rm=111 且 committed frm=101 也应被拒绝。
    expect_rejected({7'b0000000, 5'd3, 5'd2, 3'b111, 5'd1, `OPCODE_OP_FP},
                    3'b101, "reserved dynamic frm");

    // 正对照：FADD.S + RNE 应作为 FP 指令进入后端。
    inst = {7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP};
    frm = 3'b000;
    #1;
    if (fp_raw && fp_enabled && !illegal_raw && !arch_trap &&
        frontend_backend_valid) begin
      $display("PATH_OK accepted legal FADD.S");
      $finish_and_return(0);
    end

    $display("PATH_MISMATCH legal FADD.S illegal=%0d trap=%0d fp_raw=%0d fp_enabled=%0d backend=%0d",
             illegal_raw, arch_trap, fp_raw, fp_enabled,
             frontend_backend_valid);
    $finish_and_return(1);
  end
endmodule
