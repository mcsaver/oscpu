`include "include/define.v"

module tb_ooo_csr_trap_request_mux;
  reg core_commit0_valid_i;
  reg core_commit0_exception_i;
  reg [`XLEN-1:0] core_commit0_pc_i;
  reg [`TRAP_CAUSE_W-1:0] core_commit0_cause_i;
  reg [`XLEN-1:0] core_commit0_tval_i;
  reg core_commit1_valid_i;
  reg core_commit1_exception_i;
  reg [`XLEN-1:0] core_commit1_pc_i;
  reg [`TRAP_CAUSE_W-1:0] core_commit1_cause_i;
  reg [`XLEN-1:0] core_commit1_tval_i;
  reg stop_pending_i;
  reg drain_complete_i;
  reg pending_arch_trap_i;
  reg [`TRAP_CAUSE_W-1:0] pending_trap_cause_i;
  reg [`XLEN-1:0] pending_trap_pc_i;
  reg [`XLEN-1:0] pending_trap_tval_i;
  reg pending_system_i;
  reg pending_system_ecall_i;
  reg pending_system_mret_i;
  reg pending_system_irq_i;
  reg [`XLEN-1:0] pending_system_pc_i;
  reg [`INST_W-1:0] pending_system_inst_i;
  reg [`TRAP_CAUSE_W-1:0] pending_system_irq_cause_i;
  reg [`TRAP_CAUSE_W-1:0] csr_ecall_cause_i;
  reg pending_system_satp_write_commit_i;
  reg pending_system_sfence_commit_i;

  wire core_commit_exception_trap_o;
  wire trap_mem_valid_o;
  wire [`XLEN-1:0] trap_mem_pc_o;
  wire [`TRAP_CAUSE_W-1:0] trap_mem_cause_o;
  wire [`XLEN-1:0] trap_mem_tval_o;
  wire pending_system_ecall_trap_o;
  wire pending_arch_trap_fire_o;
  wire trap_ex_valid_o;
  wire [`XLEN-1:0] trap_ex_pc_o;
  wire [`TRAP_CAUSE_W-1:0] trap_ex_cause_o;
  wire [`XLEN-1:0] trap_ex_tval_o;
  wire trap_irq_valid_o;
  wire [`XLEN-1:0] trap_irq_pc_o;
  wire [`TRAP_CAUSE_W-1:0] trap_irq_cause_o;
  wire mret_valid_o;
  wire sret_valid_o;
  wire real_mret_valid_o;
  wire priv_predictor_boundary_o;

  OooCsrTrapRequestMux dut (
    .core_commit0_valid_i(core_commit0_valid_i),
    .core_commit0_exception_i(core_commit0_exception_i),
    .core_commit0_pc_i(core_commit0_pc_i),
    .core_commit0_cause_i(core_commit0_cause_i),
    .core_commit0_tval_i(core_commit0_tval_i),
    .core_commit1_valid_i(core_commit1_valid_i),
    .core_commit1_exception_i(core_commit1_exception_i),
    .core_commit1_pc_i(core_commit1_pc_i),
    .core_commit1_cause_i(core_commit1_cause_i),
    .core_commit1_tval_i(core_commit1_tval_i),
    .stop_pending_i(stop_pending_i),
    .drain_complete_i(drain_complete_i),
    .pending_arch_trap_i(pending_arch_trap_i),
    .pending_trap_cause_i(pending_trap_cause_i),
    .pending_trap_pc_i(pending_trap_pc_i),
    .pending_trap_tval_i(pending_trap_tval_i),
    .pending_system_i(pending_system_i),
    .pending_system_ecall_i(pending_system_ecall_i),
    .pending_system_mret_i(pending_system_mret_i),
    .pending_system_irq_i(pending_system_irq_i),
    .pending_system_pc_i(pending_system_pc_i),
    .pending_system_inst_i(pending_system_inst_i),
    .pending_system_irq_cause_i(pending_system_irq_cause_i),
    .csr_ecall_cause_i(csr_ecall_cause_i),
    .pending_system_satp_write_commit_i(pending_system_satp_write_commit_i),
    .pending_system_sfence_commit_i(pending_system_sfence_commit_i),
    .core_commit_exception_trap_o(core_commit_exception_trap_o),
    .trap_mem_valid_o(trap_mem_valid_o),
    .trap_mem_pc_o(trap_mem_pc_o),
    .trap_mem_cause_o(trap_mem_cause_o),
    .trap_mem_tval_o(trap_mem_tval_o),
    .pending_system_ecall_trap_o(pending_system_ecall_trap_o),
    .pending_arch_trap_fire_o(pending_arch_trap_fire_o),
    .trap_ex_valid_o(trap_ex_valid_o),
    .trap_ex_pc_o(trap_ex_pc_o),
    .trap_ex_cause_o(trap_ex_cause_o),
    .trap_ex_tval_o(trap_ex_tval_o),
    .trap_irq_valid_o(trap_irq_valid_o),
    .trap_irq_pc_o(trap_irq_pc_o),
    .trap_irq_cause_o(trap_irq_cause_o),
    .mret_valid_o(mret_valid_o),
    .sret_valid_o(sret_valid_o),
    .real_mret_valid_o(real_mret_valid_o),
    .priv_predictor_boundary_o(priv_predictor_boundary_o)
  );

  task clear_inputs;
    begin
      core_commit0_valid_i = 1'b0;
      core_commit0_exception_i = 1'b0;
      core_commit0_pc_i = 64'h8000_0010;
      core_commit0_cause_i = `EXC_LOAD_PAGE_FAULT;
      core_commit0_tval_i = 64'hdead_0000;
      core_commit1_valid_i = 1'b0;
      core_commit1_exception_i = 1'b0;
      core_commit1_pc_i = 64'h8000_0020;
      core_commit1_cause_i = `EXC_STORE_PAGE_FAULT;
      core_commit1_tval_i = 64'hdead_1111;
      stop_pending_i = 1'b0;
      drain_complete_i = 1'b0;
      pending_arch_trap_i = 1'b0;
      pending_trap_cause_i = `EXC_ILLEGAL_INST;
      pending_trap_pc_i = 64'h8000_0030;
      pending_trap_tval_i = 64'hbad0_bad0;
      pending_system_i = 1'b0;
      pending_system_ecall_i = 1'b0;
      pending_system_mret_i = 1'b0;
      pending_system_irq_i = 1'b0;
      pending_system_pc_i = 64'h8000_0040;
      pending_system_inst_i = 32'h3020_0073;
      pending_system_irq_cause_i = `IRQ_CAUSE_MTI;
      csr_ecall_cause_i = `EXC_ECALL_MMODE;
      pending_system_satp_write_commit_i = 1'b0;
      pending_system_sfence_commit_i = 1'b0;
    end
  endtask

  task expect_common;
    input exp_mem;
    input [`XLEN-1:0] exp_mem_pc;
    input [`TRAP_CAUSE_W-1:0] exp_mem_cause;
    input [`XLEN-1:0] exp_mem_tval;
    input exp_ecall_fire;
    input exp_arch_fire;
    input exp_ex;
    input [`XLEN-1:0] exp_ex_pc;
    input [`TRAP_CAUSE_W-1:0] exp_ex_cause;
    input [`XLEN-1:0] exp_ex_tval;
    begin
      #1;
      if (core_commit_exception_trap_o !== exp_mem ||
          trap_mem_valid_o !== exp_mem ||
          trap_mem_pc_o !== exp_mem_pc ||
          trap_mem_cause_o !== exp_mem_cause ||
          trap_mem_tval_o !== exp_mem_tval ||
          pending_system_ecall_trap_o !== exp_ecall_fire ||
          pending_arch_trap_fire_o !== exp_arch_fire ||
          trap_ex_valid_o !== exp_ex ||
          trap_ex_pc_o !== exp_ex_pc ||
          trap_ex_cause_o !== exp_ex_cause ||
          trap_ex_tval_o !== exp_ex_tval) begin
        $display("FAIL mem=%0b pc=%0h cause=%0h tval=%0h ecall=%0b arch=%0b ex=%0b ex_pc=%0h ex_cause=%0h ex_tval=%0h",
                 trap_mem_valid_o, trap_mem_pc_o, trap_mem_cause_o,
                 trap_mem_tval_o, pending_system_ecall_trap_o,
                 pending_arch_trap_fire_o, trap_ex_valid_o, trap_ex_pc_o,
                 trap_ex_cause_o, trap_ex_tval_o);
        $finish;
      end
    end
  endtask

  task expect_irq_ret;
    input exp_irq;
    input [`XLEN-1:0] exp_irq_pc;
    input [`TRAP_CAUSE_W-1:0] exp_irq_cause;
    input exp_mret;
    input exp_sret;
    input exp_real_mret;
    input exp_boundary;
    begin
      #1;
      if (trap_irq_valid_o !== exp_irq ||
          trap_irq_pc_o !== exp_irq_pc ||
          trap_irq_cause_o !== exp_irq_cause ||
          mret_valid_o !== exp_mret ||
          sret_valid_o !== exp_sret ||
          real_mret_valid_o !== exp_real_mret ||
          priv_predictor_boundary_o !== exp_boundary) begin
        $display("FAIL irq=%0b irq_pc=%0h irq_cause=%0h mret=%0b sret=%0b real=%0b boundary=%0b",
                 trap_irq_valid_o, trap_irq_pc_o, trap_irq_cause_o,
                 mret_valid_o, sret_valid_o, real_mret_valid_o,
                 priv_predictor_boundary_o);
        $finish;
      end
    end
  endtask

  task make_drained_system;
    begin
      stop_pending_i = 1'b1;
      drain_complete_i = 1'b1;
      pending_system_i = 1'b1;
    end
  endtask

  initial begin
    clear_inputs();
    expect_common(1'b0, 64'h8000_0020, `EXC_STORE_PAGE_FAULT, 64'hdead_1111,
                  1'b0, 1'b0, 1'b0, 64'h8000_0040,
                  `EXC_ECALL_MMODE, {`XLEN{1'b0}});
    expect_irq_ret(1'b0, 64'h8000_0040, `IRQ_CAUSE_MTI,
                   1'b0, 1'b0, 1'b0, 1'b0);

    clear_inputs();
    core_commit1_valid_i = 1'b1;
    core_commit1_exception_i = 1'b1;
    expect_common(1'b1, 64'h8000_0020, `EXC_STORE_PAGE_FAULT, 64'hdead_1111,
                  1'b0, 1'b0, 1'b0, 64'h8000_0040,
                  `EXC_ECALL_MMODE, {`XLEN{1'b0}});

    clear_inputs();
    core_commit0_valid_i = 1'b1;
    core_commit0_exception_i = 1'b1;
    core_commit1_valid_i = 1'b1;
    core_commit1_exception_i = 1'b1;
    expect_common(1'b1, 64'h8000_0010, `EXC_LOAD_PAGE_FAULT, 64'hdead_0000,
                  1'b0, 1'b0, 1'b0, 64'h8000_0040,
                  `EXC_ECALL_MMODE, {`XLEN{1'b0}});

    clear_inputs();
    stop_pending_i = 1'b1;
    drain_complete_i = 1'b1;
    pending_arch_trap_i = 1'b1;
    expect_common(1'b0, 64'h8000_0020, `EXC_STORE_PAGE_FAULT, 64'hdead_1111,
                  1'b0, 1'b1, 1'b1, 64'h8000_0030,
                  `EXC_ILLEGAL_INST, 64'hbad0_bad0);
    expect_irq_ret(1'b0, 64'h8000_0040, `IRQ_CAUSE_MTI,
                   1'b0, 1'b0, 1'b0, 1'b1);

    clear_inputs();
    make_drained_system();
    pending_system_ecall_i = 1'b1;
    expect_common(1'b0, 64'h8000_0020, `EXC_STORE_PAGE_FAULT, 64'hdead_1111,
                  1'b1, 1'b0, 1'b1, 64'h8000_0040,
                  `EXC_ECALL_MMODE, {`XLEN{1'b0}});

    clear_inputs();
    make_drained_system();
    pending_system_ecall_i = 1'b1;
    pending_arch_trap_i = 1'b1;
    expect_common(1'b0, 64'h8000_0020, `EXC_STORE_PAGE_FAULT, 64'hdead_1111,
                  1'b1, 1'b1, 1'b1, 64'h8000_0030,
                  `EXC_ILLEGAL_INST, 64'hbad0_bad0);

    clear_inputs();
    make_drained_system();
    pending_system_irq_i = 1'b1;
    pending_system_pc_i = 64'h8000_0880;
    pending_system_irq_cause_i = `IRQ_CAUSE_MEI;
    expect_irq_ret(1'b1, 64'h8000_0880, `IRQ_CAUSE_MEI,
                   1'b0, 1'b0, 1'b0, 1'b1);

    clear_inputs();
    make_drained_system();
    pending_system_mret_i = 1'b1;
    pending_system_inst_i = 32'h3020_0073;
    expect_irq_ret(1'b0, 64'h8000_0040, `IRQ_CAUSE_MTI,
                   1'b1, 1'b0, 1'b1, 1'b1);

    clear_inputs();
    make_drained_system();
    pending_system_mret_i = 1'b1;
    pending_system_inst_i = 32'h1020_0073;
    expect_irq_ret(1'b0, 64'h8000_0040, `IRQ_CAUSE_MTI,
                   1'b1, 1'b1, 1'b0, 1'b1);

    clear_inputs();
    pending_system_satp_write_commit_i = 1'b1;
    expect_irq_ret(1'b0, 64'h8000_0040, `IRQ_CAUSE_MTI,
                   1'b0, 1'b0, 1'b0, 1'b1);

    clear_inputs();
    pending_system_sfence_commit_i = 1'b1;
    expect_irq_ret(1'b0, 64'h8000_0040, `IRQ_CAUSE_MTI,
                   1'b0, 1'b0, 1'b0, 1'b1);

    clear_inputs();
    pending_system_i = 1'b1;
    pending_system_ecall_i = 1'b1;
    pending_system_irq_i = 1'b1;
    pending_system_mret_i = 1'b1;
    expect_common(1'b0, 64'h8000_0020, `EXC_STORE_PAGE_FAULT, 64'hdead_1111,
                  1'b0, 1'b0, 1'b0, 64'h8000_0040,
                  `EXC_ECALL_MMODE, {`XLEN{1'b0}});
    expect_irq_ret(1'b0, 64'h8000_0040, `IRQ_CAUSE_MTI,
                   1'b0, 1'b0, 1'b0, 1'b0);

    $display("[TVAL-G1-CSR-MUX] pending_owner=1 ex_pc_tval_split=1 system_tval_zero=1 PASS");
    $display("PASS tb_ooo_csr_trap_request_mux");
    $finish;
  end
endmodule
