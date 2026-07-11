`timescale 1ns/1ps
`include "define.v"

module tb_xret_privilege_classify;
  reg [31:0] inst;
  reg [1:0] priv;
  reg [63:0] mstatus;
  wire [`CTRL_BUS_W-1:0] ctrl;
  wire mret_raw;
  wire sret_raw;
  wire xret_raw;
  wire priv_illegal;
  wire arch_trap;
  wire system_raw;

  DecodeUnit decode (
    .inst_i(inst), .ctrl_o(ctrl)
  );

  OooFetchHeadClassifyGate classify (
    .decode_valid_i(1'b1), .fetch_fault_i(1'b0), .inst_i(inst),
    .semihost_peer_inst_i(32'b0), .semihost_peer_is_enter_i(1'b0),
    .ctrl_i(ctrl), .priv_mode_i(priv), .mstatus_i(mstatus), .frm_i(3'b000),
    .mret_raw_o(mret_raw), .sret_raw_o(sret_raw), .xret_raw_o(xret_raw),
    .priv_system_illegal_o(priv_illegal), .arch_trap_raw_o(arch_trap),
    .system_raw_o(system_raw)
  );

  task expect_missing_illegal;
    input [31:0] test_inst;
    input [1:0] test_priv;
    input [8*20-1:0] label;
    begin
      inst = test_inst;
      priv = test_priv;
      mstatus = 64'b0;
      #1;
      if (xret_raw && system_raw && !priv_illegal && !arch_trap)
        $display("MISSING_ILLEGAL %0s priv=%0d inst=%h", label, priv, inst);
      else begin
        $display("UNEXPECTED_CLASSIFICATION %0s xret=%0d sys=%0d pill=%0d trap=%0d",
                 label, xret_raw, system_raw, priv_illegal, arch_trap);
        $finish_and_return(2);
      end
    end
  endtask

  initial begin
    inst = 0;
    priv = `PRIV_M;
    mstatus = 0;
    #1;

    expect_missing_illegal(32'h3020_0073, `PRIV_S, "MRET-from-S");
    expect_missing_illegal(32'h3020_0073, `PRIV_U, "MRET-from-U");
    expect_missing_illegal(32'h1020_0073, `PRIV_U, "SRET-from-U");

    // Positive control: the existing S-mode+TSR path must still trap.
    inst = 32'h1020_0073;
    priv = `PRIV_S;
    mstatus = `MSTATUS_TSR;
    #1;
    if (sret_raw && priv_illegal && arch_trap) begin
      $display("POSITIVE_CONTROL SRET-from-S-with-TSR traps");
      $finish_and_return(0);
    end

    $display("POSITIVE_CONTROL_FAILED sret=%0d pill=%0d trap=%0d",
             sret_raw, priv_illegal, arch_trap);
    $finish_and_return(1);
  end
endmodule
