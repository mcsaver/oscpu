`include "define.v"

module tb_csr_file_vectored_trap;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg csr_valid;
  reg [11:0] csr_addr;
  reg [2:0] csr_funct3;
  reg [`REG_ADDR_W-1:0] csr_rs1_idx;
  reg [`XLEN-1:0] csr_rs1_data;
  reg [4:0] csr_zimm;
  reg csr_commit;
  reg csr_probe_valid;
  reg [11:0] csr_probe_addr;
  reg [2:0] csr_probe_funct3;
  reg [`REG_ADDR_W-1:0] csr_probe_rs1_idx;
  reg trap_mem_valid;
  reg [`XLEN-1:0] trap_mem_pc;
  reg [`TRAP_CAUSE_W-1:0] trap_mem_cause;
  reg [`XLEN-1:0] trap_mem_tval;
  reg trap_ex_valid;
  reg [`XLEN-1:0] trap_ex_pc;
  reg [`TRAP_CAUSE_W-1:0] trap_ex_cause;
  reg [`XLEN-1:0] trap_ex_tval;
  reg trap_irq_valid;
  reg [`XLEN-1:0] trap_irq_pc;
  reg [`TRAP_CAUSE_W-1:0] trap_irq_cause;
  reg mret_valid;
  reg sret_valid;

  wire [`XLEN-1:0] csr_rdata;
  wire csr_illegal;
  wire irq_pending;
  wire [`TRAP_CAUSE_W-1:0] irq_cause;
  wire [`XLEN-1:0] trap_target;
  wire [`XLEN-1:0] mepc;
  wire [`XLEN-1:0] ret_target;
  wire [1:0] priv_mode;
  wire [`TRAP_CAUSE_W-1:0] ecall_cause;
  wire [`XLEN-1:0] mstatus;
  wire [`XLEN-1:0] satp;
  wire svpbmt_en;
  wire [`PMP_CFG_BUS_W-1:0] pmpcfg;
  wire [`PMP_ADDR_BUS_W-1:0] pmpaddr;

  task automatic check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016h expected=0x%016h",
                 what, got, exp);
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      csr_valid = 1'b0;
      csr_addr = 12'h000;
      csr_funct3 = 3'b010;
      csr_rs1_idx = {`REG_ADDR_W{1'b0}};
      csr_rs1_data = {`XLEN{1'b0}};
      csr_zimm = 5'd0;
      csr_commit = 1'b0;
      csr_probe_valid = 1'b0;
      csr_probe_addr = 12'h000;
      csr_probe_funct3 = 3'b010;
      csr_probe_rs1_idx = {`REG_ADDR_W{1'b0}};
      trap_mem_valid = 1'b0;
      trap_mem_pc = {`XLEN{1'b0}};
      trap_mem_cause = {`TRAP_CAUSE_W{1'b0}};
      trap_mem_tval = {`XLEN{1'b0}};
      trap_ex_valid = 1'b0;
      trap_ex_pc = {`XLEN{1'b0}};
      trap_ex_cause = {`TRAP_CAUSE_W{1'b0}};
      trap_ex_tval = {`XLEN{1'b0}};
      trap_irq_valid = 1'b0;
      trap_irq_pc = {`XLEN{1'b0}};
      trap_irq_cause = {`TRAP_CAUSE_W{1'b0}};
      mret_valid = 1'b0;
      sret_valid = 1'b0;
    end
  endtask

  task automatic reset_case;
    begin
      clear_inputs();
      rst = 1'b1;
      `TB_TICK(clk);
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic csr_write;
    input [11:0] addr;
    input [`XLEN-1:0] value;
    begin
      csr_valid = 1'b1;
      csr_addr = addr;
      csr_funct3 = 3'b001;
      csr_rs1_idx = {{(`REG_ADDR_W-1){1'b0}}, 1'b1};
      csr_rs1_data = value;
      csr_zimm = 5'd1;
      csr_commit = 1'b1;
      csr_probe_valid = 1'b1;
      csr_probe_addr = addr;
      csr_probe_funct3 = 3'b001;
      csr_probe_rs1_idx = {{(`REG_ADDR_W-1){1'b0}}, 1'b1};
      #1;
      tb_check1("CSR write must be legal", csr_illegal, 1'b0);
      `TB_TICK(clk);
      csr_valid = 1'b0;
      csr_commit = 1'b0;
      csr_probe_valid = 1'b0;
      // A3/A4 shadow checks observe the stored value on this following edge.
      `TB_TICK(clk);
      #1;
    end
  endtask

  task automatic check_csr;
    input [1023:0] what;
    input [11:0] addr;
    input [`XLEN-1:0] expected;
    begin
      csr_valid = 1'b1;
      csr_addr = addr;
      csr_funct3 = 3'b010;
      csr_rs1_idx = {`REG_ADDR_W{1'b0}};
      csr_rs1_data = {`XLEN{1'b0}};
      csr_zimm = 5'd0;
      csr_commit = 1'b0;
      csr_probe_valid = 1'b1;
      csr_probe_addr = addr;
      csr_probe_funct3 = 3'b010;
      csr_probe_rs1_idx = {`REG_ADDR_W{1'b0}};
      #1;
      tb_check1("CSR read must be legal", csr_illegal, 1'b0);
      check64(what, csr_rdata, expected);
      csr_valid = 1'b0;
      csr_probe_valid = 1'b0;
    end
  endtask

  task automatic enter_s_mode;
    begin
      csr_write(`CSR_MSTATUS, `MSTATUS_MPP_S);
      mret_valid = 1'b1;
      `TB_TICK(clk);
      mret_valid = 1'b0;
      #1;
      tb_check1("MRET setup enters S-mode", priv_mode == `PRIV_S, 1'b1);
    end
  endtask

  CsrFile dut (
    .clk(clk),
    .rst(rst),
    .cycle_count_enable_i(1'b0),
    .time_i({`XLEN{1'b0}}),
    .instret_inc_i(2'b00),
    .csr_valid_i(csr_valid),
    .csr_addr_i(csr_addr),
    .csr_funct3_i(csr_funct3),
    .csr_rs1_idx_i(csr_rs1_idx),
    .csr_rs1_data_i(csr_rs1_data),
    .csr_zimm_i(csr_zimm),
    .csr_commit_i(csr_commit),
    .csr_probe_valid_i(csr_probe_valid),
    .csr_probe_addr_i(csr_probe_addr),
    .csr_probe_funct3_i(csr_probe_funct3),
    .csr_probe_rs1_idx_i(csr_probe_rs1_idx),
    .csr_rdata_o(csr_rdata),
    .csr_illegal_o(csr_illegal),
    .fp_fflags_valid_i(1'b0),
    .fp_fflags_i(5'b00000),
    .fp_dirty_i(1'b0),
    .trap_mem_valid_i(trap_mem_valid),
    .trap_mem_pc_i(trap_mem_pc),
    .trap_mem_cause_i(trap_mem_cause),
    .trap_mem_tval_i(trap_mem_tval),
    .trap_ex_valid_i(trap_ex_valid),
    .trap_ex_pc_i(trap_ex_pc),
    .trap_ex_cause_i(trap_ex_cause),
    .trap_ex_tval_i(trap_ex_tval),
    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(1'b0),
    .irq_pending_o(irq_pending),
    .irq_cause_o(irq_cause),
    .trap_irq_valid_i(trap_irq_valid),
    .trap_irq_pc_i(trap_irq_pc),
    .trap_irq_cause_i(trap_irq_cause),
    .mret_valid_i(mret_valid),
    .sret_valid_i(sret_valid),
    .trap_target_o(trap_target),
    .mepc_o(mepc),
    .ret_target_o(ret_target),
    .priv_mode_o(priv_mode),
    .ecall_cause_o(ecall_cause),
    .mstatus_o(mstatus),
    .satp_o(satp),
    .svpbmt_en_o(svpbmt_en),
    .frm_o(),
    .pmpcfg_o(pmpcfg),
    .pmpaddr_o(pmpaddr)
  );

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();

    // WARL case 1: Direct and Vectored are both legal stored MODE values.
    reset_case();
    csr_write(`CSR_MTVEC, 64'h0000_0000_0000_1001);
    check_csr("mtvec keeps Vectored MODE", `CSR_MTVEC, 64'h1001);
    csr_write(`CSR_STVEC, 64'h0000_0000_0000_2001);
    check_csr("stvec keeps Vectored MODE", `CSR_STVEC, 64'h2001);

    // WARL case 2: reserved mtvec MODE=2 clamps to Direct.
    reset_case();
    csr_write(`CSR_MTVEC, 64'h0000_0000_0000_1002);
    check_csr("mtvec reserved MODE clamps to Direct", `CSR_MTVEC, 64'h1000);

    // WARL case 3: reserved stvec MODE=3 clamps to Direct.
    reset_case();
    csr_write(`CSR_STVEC, 64'h0000_0000_0000_2003);
    check_csr("stvec reserved MODE clamps to Direct", `CSR_STVEC, 64'h2000);

    // IRQ routing case 1: a writable, nondelegated SSIP is serviced by M
    // with its architectural supervisor-software cause number.
    reset_case();
    csr_write(`CSR_MTVEC, 64'h1001);
    csr_write(`CSR_MIP, `MIP_SSIP);
    csr_write(`CSR_MIE, `MIE_SSIE);
    csr_write(`CSR_MSTATUS, `MSTATUS_MIE);
    tb_check1("M nondelegated SSIP raises IRQ", irq_pending, 1'b1);
    check64("M nondelegated SSIP cause", {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, irq_cause},
            {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `IRQ_CAUSE_SSI});
    trap_irq_valid = 1'b1;
    trap_irq_pc = 64'h8000_0010;
    trap_irq_cause = irq_cause;
    #1;
    check64("M nondelegated SSIP vector", trap_target, 64'h1004);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    check64("M nondelegated SSIP mcause", dut.csr_mcause_q,
            `MCAUSE_INTERRUPT | 64'd1);

    // IRQ routing case 2: below M, an undelegated SSIP still enters M.
    reset_case();
    csr_write(`CSR_MTVEC, 64'h1001);
    csr_write(`CSR_MIP, `MIP_SSIP);
    csr_write(`CSR_MIE, `MIE_SSIE);
    enter_s_mode();
    tb_check1("S-mode undelegated SSIP raises IRQ", irq_pending, 1'b1);
    check64("S-mode undelegated SSIP cause",
            {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, irq_cause},
            {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `IRQ_CAUSE_SSI});
    trap_irq_valid = 1'b1;
    trap_irq_pc = 64'h8000_0014;
    trap_irq_cause = irq_cause;
    #1;
    check64("S-mode undelegated SSIP uses M vector", trap_target, 64'h1004);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("S-mode undelegated SSIP enters M", priv_mode == `PRIV_M, 1'b1);
    check64("S-mode undelegated SSIP mcause", dut.csr_mcause_q,
            `MCAUSE_INTERRUPT | 64'd1);

    // IRQ routing case 3: the same SSIP delegates to S only when mideleg[1]
    // is set and S-level global interrupt enable is open.
    reset_case();
    csr_write(`CSR_STVEC, 64'h2001);
    csr_write(`CSR_MIDELEG, `MIP_SSIP);
    csr_write(`CSR_MIP, `MIP_SSIP);
    csr_write(`CSR_MIE, `MIE_SSIE);
    enter_s_mode();
    csr_write(`CSR_SSTATUS, `MSTATUS_SIE);
    tb_check1("delegated SSIP raises S IRQ", irq_pending, 1'b1);
    check64("delegated SSIP cause",
            {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, irq_cause},
            {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, `IRQ_CAUSE_SSI});
    trap_irq_valid = 1'b1;
    trap_irq_pc = 64'h8000_0018;
    trap_irq_cause = irq_cause;
    #1;
    check64("delegated SSIP uses S vector", trap_target, 64'h2004);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("delegated SSIP stays in S", priv_mode == `PRIV_S, 1'b1);
    check64("delegated SSIP scause", dut.csr_scause_q,
            `MCAUSE_INTERRUPT | 64'd1);

    // M IRQ case 1: Vectored adds 4*cause.
    reset_case();
    csr_write(`CSR_MTVEC, 64'h1001);
    trap_irq_valid = 1'b1;
    trap_irq_pc = 64'h8000_0020;
    trap_irq_cause = `IRQ_CAUSE_MTI;
    #1;
    check64("M vectored IRQ target", trap_target, 64'h101c);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    check64("M vectored IRQ mepc", dut.csr_mepc_q, 64'h8000_0020);
    check64("M vectored IRQ mcause", dut.csr_mcause_q,
            `MCAUSE_INTERRUPT | 64'd7);

    // M synchronous case: MODE=Vectored still uses BASE for exceptions.
    reset_case();
    csr_write(`CSR_MTVEC, 64'h1001);
    trap_ex_valid = 1'b1;
    trap_ex_pc = 64'h8000_0040;
    trap_ex_cause = `EXC_ECALL_MMODE;
    trap_ex_tval = 64'h0000_0000_0000_0042;
    #1;
    check64("M synchronous trap uses BASE", trap_target, 64'h1000);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    check64("M synchronous mcause", dut.csr_mcause_q, 64'd11);
    check64("M synchronous mtval", dut.csr_mtval_q, 64'h42);

    // M IRQ case 2: Direct ignores the IRQ cause offset.
    reset_case();
    csr_write(`CSR_MTVEC, 64'h1000);
    trap_irq_valid = 1'b1;
    trap_irq_pc = 64'h8000_0060;
    trap_irq_cause = `IRQ_CAUSE_MTI;
    #1;
    check64("M direct IRQ uses BASE", trap_target, 64'h1000);
    `TB_TICK(clk);
    clear_inputs();

    // Source-priority case 1: mem wins over delegated ex/irq and therefore
    // selects M target/state as one record.
    reset_case();
    csr_write(`CSR_MTVEC, 64'h1000);
    csr_write(`CSR_STVEC, 64'h2001);
    csr_write(`CSR_MEDELEG, 64'h0000_0000_0000_0200);
    enter_s_mode();
    trap_mem_valid = 1'b1;
    trap_mem_pc = 64'h8000_0080;
    trap_mem_cause = 5'd5;
    trap_mem_tval = 64'h1111_2222_3333_4444;
    trap_ex_valid = 1'b1;
    trap_ex_pc = 64'h8000_0090;
    trap_ex_cause = 5'd9;
    trap_ex_tval = 64'haaaa_bbbb_cccc_dddd;
    trap_irq_valid = 1'b1;
    trap_irq_pc = 64'h8000_00a0;
    trap_irq_cause = `IRQ_CAUSE_SEI;
    #1;
    check64("mem priority selects nondelegated M target", trap_target, 64'h1000);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("mem priority enters M-mode", priv_mode == `PRIV_M, 1'b1);
    check64("mem priority mepc", dut.csr_mepc_q, 64'h8000_0080);
    check64("mem priority mcause", dut.csr_mcause_q, 64'd5);
    check64("mem priority mtval", dut.csr_mtval_q,
            64'h1111_2222_3333_4444);
    check64("losing delegated ex does not write sepc", dut.csr_sepc_q, 64'h0);

    // Source-priority case 2: delegated synchronous ex wins over S IRQ;
    // synchronous source does not receive a Vectored offset.
    reset_case();
    csr_write(`CSR_STVEC, 64'h2001);
    csr_write(`CSR_MEDELEG, 64'h0000_0000_0000_0200);
    enter_s_mode();
    trap_ex_valid = 1'b1;
    trap_ex_pc = 64'h8000_00b0;
    trap_ex_cause = 5'd9;
    trap_ex_tval = 64'h88;
    trap_irq_valid = 1'b1;
    trap_irq_pc = 64'h8000_00c0;
    trap_irq_cause = `IRQ_CAUSE_SEI;
    #1;
    check64("delegated ex priority uses S BASE", trap_target, 64'h2000);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("delegated ex stays in S-mode", priv_mode == `PRIV_S, 1'b1);
    check64("delegated ex sepc", dut.csr_sepc_q, 64'h8000_00b0);
    check64("delegated ex scause", dut.csr_scause_q, 64'd9);
    check64("delegated ex stval", dut.csr_stval_q, 64'h88);

    // S IRQ case: Vectored stvec adds 4*SEI(9).
    reset_case();
    csr_write(`CSR_STVEC, 64'h2001);
    csr_write(`CSR_MIDELEG, `MIP_SEIP);
    enter_s_mode();
    trap_irq_valid = 1'b1;
    trap_irq_pc = 64'h8000_00d0;
    trap_irq_cause = `IRQ_CAUSE_SEI;
    #1;
    check64("S vectored IRQ target", trap_target, 64'h2024);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("S IRQ stays in S-mode", priv_mode == `PRIV_S, 1'b1);
    check64("S IRQ scause", dut.csr_scause_q,
            `MCAUSE_INTERRUPT | 64'd9);
    check64("S IRQ stval is zero", dut.csr_stval_q, 64'h0);

    // S synchronous case: delegated exception uses stvec BASE.
    reset_case();
    csr_write(`CSR_STVEC, 64'h2001);
    csr_write(`CSR_MEDELEG, 64'h0000_0000_0000_0200);
    enter_s_mode();
    trap_ex_valid = 1'b1;
    trap_ex_pc = 64'h8000_00e0;
    trap_ex_cause = 5'd9;
    trap_ex_tval = 64'h99;
    #1;
    check64("S delegated synchronous target", trap_target, 64'h2000);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    check64("S delegated synchronous sepc", dut.csr_sepc_q, 64'h8000_00e0);
    check64("S delegated synchronous scause", dut.csr_scause_q, 64'd9);

    if (tb_errors == 0) begin
      $display("[VECTORED-TRAP-G1-CSR-FILE] cases=13 warl=3 irq_routing=3 m_irq=2 m_sync=1 source_priority=2 s_irq=1 s_sync=1 PASS");
    end else begin
      $display("[VECTORED-TRAP-G1-CSR-FILE] cases=13 warl=3 irq_routing=3 m_irq=2 m_sync=1 source_priority=2 s_irq=1 s_sync=1 errors=%0d FAIL",
               tb_errors);
    end
    tb_finish("tb_csr_file_vectored_trap");
  end
endmodule
