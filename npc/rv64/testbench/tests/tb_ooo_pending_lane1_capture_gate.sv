`timescale 1ns/1ps
`include "include/define.v"
`include "common/OooSlotFacts.v"
`include "tb_common.svh"

module tb_ooo_pending_lane1_capture_gate;
  reg barrier_base;
  reg head_fetch_fault;
  reg [1:0] head_resp;
  reg [`XLEN-1:0] head_pc;
  reg [`INST_W-1:0] head_inst;
  reg [`OOO_SLOT_FACTS_W-1:0] facts;
  reg csr_illegal;

  wire system_capture;
  wire branch_capture;
  wire jump_capture;
  wire fp_capture;
  wire mem_capture;
  wire trap_exit_capture;
  wire trap_exit_arch_valid;
  wire trap_exit_exit_valid;
  wire trap_exit_exit_ecall;
  wire trap_exit_exit_ebreak;
  wire [`TRAP_CAUSE_W-1:0] trap_exit_cause;
  wire [`XLEN-1:0] trap_exit_tval;

  OooPendingLane1CaptureGate dut (
    .barrier_base_i(barrier_base),
    .head_fetch_fault_i(head_fetch_fault),
    .head_resp_i(head_resp),
    .head_pc_i(head_pc),
    .head_inst_i(head_inst),
    .facts_i(facts),
    .csr_illegal_i(csr_illegal),
    .system_capture_o(system_capture),
    .branch_capture_o(branch_capture),
    .jump_capture_o(jump_capture),
    .fp_capture_o(fp_capture),
    .mem_capture_o(mem_capture),
    .trap_exit_capture_o(trap_exit_capture),
    .trap_exit_arch_valid_o(trap_exit_arch_valid),
    .trap_exit_exit_valid_o(trap_exit_exit_valid),
    .trap_exit_exit_ecall_o(trap_exit_exit_ecall),
    .trap_exit_exit_ebreak_o(trap_exit_exit_ebreak),
    .trap_exit_cause_o(trap_exit_cause),
    .trap_exit_tval_o(trap_exit_tval)
  );

  task automatic check_cause;
    input [1023:0] what;
    input [`TRAP_CAUSE_W-1:0] got;
    input [`TRAP_CAUSE_W-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%0x expected=0x%0x",
                 what, got, exp);
      end
    end
  endtask

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

  task automatic clear_inputs;
    begin
      barrier_base = 1'b0;
      head_fetch_fault = 1'b0;
      head_resp = 2'b00;
      head_pc = 64'h0000_0000_8000_2004;
      head_inst = 32'h0000_0073;
      facts = {`OOO_SLOT_FACTS_W{1'b0}};
      csr_illegal = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    clear_inputs();
    facts[`OOO_SLOT_FACT_BRANCH] = 1'b1;
    #1;
    tb_check1("idle blocks branch capture", branch_capture, 1'b0);
    tb_check1("idle blocks trap-exit scrub", trap_exit_capture, 1'b0);

    clear_inputs();
    barrier_base = 1'b1;
    #1;
    tb_check1("empty barrier scrubs trap-exit", trap_exit_capture, 1'b1);
    tb_check1("empty barrier has no arch valid", trap_exit_arch_valid, 1'b0);
    tb_check1("empty barrier has no exit valid", trap_exit_exit_valid, 1'b0);

    clear_inputs();
    barrier_base = 1'b1;
    facts[`OOO_SLOT_FACT_BRANCH] = 1'b1;
    facts[`OOO_SLOT_FACT_JUMP] = 1'b1;
    facts[`OOO_SLOT_FACT_MEM] = 1'b1;
    facts[`OOO_SLOT_FACT_FP_ENABLED] = 1'b1;
    #1;
    tb_check1("branch fact captures branch", branch_capture, 1'b1);
    tb_check1("jump fact captures jump", jump_capture, 1'b1);
    tb_check1("mem fact captures mem", mem_capture, 1'b1);
    tb_check1("fp fact captures fp", fp_capture, 1'b1);
    tb_check1("typed owner does not imply arch valid",
              trap_exit_arch_valid, 1'b0);

    clear_inputs();
    barrier_base = 1'b1;
    facts[`OOO_SLOT_FACT_SYSTEM] = 1'b1;
    #1;
    tb_check1("system captures when legal", system_capture, 1'b1);
    facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b1;
    #1;
    tb_check1("system blocked by arch trap", system_capture, 1'b0);
    facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b0;
    csr_illegal = 1'b1;
    #1;
    tb_check1("system blocked by csr illegal", system_capture, 1'b0);
    tb_check1("csr illegal gives arch valid", trap_exit_arch_valid, 1'b1);
    check_cause("csr illegal cause", trap_exit_cause, `EXC_ILLEGAL_INST);
    check_xlen("csr illegal tval", trap_exit_tval, head_inst);

    clear_inputs();
    barrier_base = 1'b1;
    facts[`OOO_SLOT_FACT_EXIT] = 1'b1;
    facts[`OOO_SLOT_FACT_ECALL] = 1'b1;
    #1;
    tb_check1("exit valid follows exit fact", trap_exit_exit_valid, 1'b1);
    tb_check1("exit ecall payload raw", trap_exit_exit_ecall, 1'b1);
    tb_check1("exit ebreak payload clear", trap_exit_exit_ebreak, 1'b0);

    clear_inputs();
    barrier_base = 1'b1;
    facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b1;
    facts[`OOO_SLOT_FACT_SEMIHOST_EBREAK] = 1'b1;
    #1;
    tb_check1("semihost arch valid", trap_exit_arch_valid, 1'b1);
    check_cause("semihost cause", trap_exit_cause, `EXC_BREAKPOINT);
    check_xlen("semihost tval", trap_exit_tval, {`XLEN{1'b0}});

    clear_inputs();
    barrier_base = 1'b1;
    facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b1;
    facts[`OOO_SLOT_FACT_ILLEGAL] = 1'b1;
    head_inst = 32'hffff_ffff;
    #1;
    check_cause("illegal cause", trap_exit_cause, `EXC_ILLEGAL_INST);
    check_xlen("illegal tval", trap_exit_tval, 64'h0000_0000_ffff_ffff);

    clear_inputs();
    barrier_base = 1'b1;
    facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b1;
    facts[`OOO_SLOT_FACT_FP_DISABLED] = 1'b1;
    #1;
    check_cause("fp disabled cause", trap_exit_cause, `EXC_ILLEGAL_INST);
    check_xlen("fp disabled tval", trap_exit_tval, head_inst);

    clear_inputs();
    barrier_base = 1'b1;
    head_fetch_fault = 1'b1;
    head_resp = 2'b10;
    #1;
    tb_check1("fetch page fault arch valid", trap_exit_arch_valid, 1'b1);
    check_cause("fetch page fault cause",
                trap_exit_cause, `EXC_INST_PAGE_FAULT);
    check_xlen("fetch page fault tval", trap_exit_tval, head_pc);
    head_resp = 2'b01;
    #1;
    check_cause("fetch access fault cause",
                trap_exit_cause, `EXC_INST_ACCESS_FAULT);

    tb_finish("tb_ooo_pending_lane1_capture_gate");
  end
endmodule
