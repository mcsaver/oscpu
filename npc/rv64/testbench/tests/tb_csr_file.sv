`include "define.v"

module tb_csr_file;
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
  reg fp_fflags_valid;
  reg [4:0] fp_fflags;
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

  localparam [`XLEN-1:0] PMPADDR_MASK_TB = `PMP_ADDR_MASK;

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016h expected=0x%016h", what, got, exp);
      end
    end
  endtask

  task automatic drive_csr;
    input [11:0] addr;
    input [2:0] funct3;
    input [`REG_ADDR_W-1:0] rs1_idx;
    input [`XLEN-1:0] rs1_data;
    input do_commit;
    begin
      csr_valid = 1'b1;
      csr_addr = addr;
      csr_funct3 = funct3;
      csr_rs1_idx = rs1_idx;
      csr_rs1_data = rs1_data;
      csr_zimm = rs1_idx[4:0];
      csr_commit = do_commit;
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
    .csr_rdata_o(csr_rdata),
    .csr_illegal_o(csr_illegal),
    .fp_fflags_valid_i(fp_fflags_valid),
    .fp_fflags_i(fp_fflags),
    .trap_mem_valid_i(1'b0),
    .trap_mem_pc_i({`XLEN{1'b0}}),
    .trap_mem_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .trap_mem_tval_i({`XLEN{1'b0}}),
    .trap_ex_valid_i(1'b0),
    .trap_ex_pc_i({`XLEN{1'b0}}),
    .trap_ex_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .trap_ex_tval_i({`XLEN{1'b0}}),
    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(1'b0),
    .irq_pending_o(irq_pending),
    .irq_cause_o(irq_cause),
    .trap_irq_valid_i(1'b0),
    .trap_irq_pc_i({`XLEN{1'b0}}),
    .trap_irq_cause_i({`TRAP_CAUSE_W{1'b0}}),
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
    .pmpcfg_o(pmpcfg),
    .pmpaddr_o(pmpaddr)
  );

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    csr_valid = 1'b0;
    csr_addr = 12'h000;
    csr_funct3 = 3'b010;
    csr_rs1_idx = {`REG_ADDR_W{1'b0}};
    csr_rs1_data = {`XLEN{1'b0}};
    csr_zimm = 5'd0;
    csr_commit = 1'b0;
    fp_fflags_valid = 1'b0;
    fp_fflags = 5'b00000;
    mret_valid = 1'b0;
    sret_valid = 1'b0;

    `TB_TICK(clk);
    rst = 1'b0;

    drive_csr(`CSR_TSELECT, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("tselect read is legal", csr_illegal, 1'b0);
    tb_check64("tselect reports no usable trigger", csr_rdata, {{(`XLEN-1){1'b0}}, 1'b1});

    drive_csr(`CSR_TSELECT, 3'b001, 5'd1, {`XLEN{1'b0}}, 1'b1);
    #1;
    tb_check1("tselect write is WARL legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_TSELECT, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("tselect remains hard-wired", csr_rdata, {{(`XLEN-1){1'b0}}, 1'b1});

    drive_csr(`CSR_TDATA1, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check1("tdata1 write is legal no-op", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_TDATA1, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("tdata1 unsupported value", csr_rdata, {`XLEN{1'b0}});

    drive_csr(`CSR_TDATA2, 3'b001, 5'd1, 64'h8000_0040, 1'b1);
    #1;
    tb_check1("tdata2 write is legal no-op", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_TDATA2, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("tdata2 unsupported value", csr_rdata, {`XLEN{1'b0}});

    drive_csr(`CSR_TCONTROL, 3'b010, 5'd1, 64'h8, 1'b1);
    #1;
    tb_check1("tcontrol csrs is legal no-op", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_TCONTROL, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("tcontrol unsupported value", csr_rdata, {`XLEN{1'b0}});

    drive_csr(`CSR_MISA, 3'b111, 5'd4, {`XLEN{1'b0}}, 1'b1);
    #1;
    tb_check1("misa csrci is legal WARL no-op", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MISA, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("misa C bit remains set", |(csr_rdata & 64'h4), 1'b1);

    drive_csr(`CSR_PMPCFG0, 3'b001, 5'd1, 64'h18, 1'b1);
    #1;
    tb_check1("pmpcfg0 write is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpcfg0 readback", csr_rdata, 64'h18);

    drive_csr(`CSR_PMPCFG0, 3'b001, 5'd1, 64'h1e, 1'b1);
    #1;
    tb_check1("pmpcfg0 R0W1 WARL write is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpcfg0 R0W1 clears permissions", csr_rdata, 64'h18);

    drive_csr(`CSR_PMPADDR15, 3'b001, 5'd1, 64'h0000_0000_1234_5678, 1'b1);
    #1;
    tb_check1("pmpaddr15 write is legal before lock", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR15, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr15 readback before lock", csr_rdata, 64'h0000_0000_1234_5678);
    tb_check64("pmpaddr15 export before lock", pmpaddr[15*`XLEN +: `XLEN], 64'h0000_0000_1234_5678);

    drive_csr(`CSR_PMPCFG2, 3'b001, 5'd1, 64'h9f00_0000_0000_0000, 1'b1);
    #1;
    tb_check1("pmpcfg2 entry15 lock write is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG2, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpcfg2 readback", csr_rdata, 64'h9f00_0000_0000_0000);
    tb_check64("pmpcfg entry15 export", {{(`XLEN-8){1'b0}}, pmpcfg[15*8 +: 8]}, 64'h9f);

    drive_csr(`CSR_PMPADDR15, 3'b001, 5'd1, 64'h0000_0000_8765_4321, 1'b1);
    #1;
    tb_check1("pmpaddr15 locked write remains legal no-op", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR15, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr15 readback after lock", csr_rdata, 64'h0000_0000_1234_5678);

    drive_csr(`CSR_PMPCFG2, 3'b001, 5'd1, 64'h0000_0000_0800_0000, 1'b1);
    #1;
    tb_check1("pmpcfg2 locked byte preserve write is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG2, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpcfg2 keeps locked entry15 while updating entry11",
               csr_rdata, 64'h9f00_0000_0800_0000);

    drive_csr(`CSR_PMPCFG1, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check1("pmpcfg1 write is illegal on RV64", csr_illegal, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG1, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("pmpcfg1 read is illegal on RV64", csr_illegal, 1'b1);

    drive_csr(`CSR_PMPCFG3, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check1("pmpcfg3 write is illegal on RV64", csr_illegal, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG3, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("pmpcfg3 read is illegal on RV64", csr_illegal, 1'b1);

    drive_csr(`CSR_PMPADDR0, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check1("pmpaddr0 write is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr0 masks to implemented PA bits", csr_rdata, PMPADDR_MASK_TB);
    tb_check64("pmpaddr0 export masks high bits", pmpaddr[0 +: `XLEN], PMPADDR_MASK_TB);

    drive_csr(`CSR_PMPADDR0, 3'b001, 5'd1, (64'h1 << (`PMP_ADDR_BITS - 1)), 1'b1);
    #1;
    tb_check1("pmpaddr0 top implemented bit write is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr0 keeps top implemented bit", csr_rdata,
               (64'h1 << (`PMP_ADDR_BITS - 1)));

    drive_csr(`CSR_PMPADDR0, 3'b001, 5'd1, (64'h1 << `PMP_ADDR_BITS), 1'b1);
    #1;
    tb_check1("pmpaddr0 first unimplemented bit write is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr0 clears first unimplemented bit", csr_rdata, {`XLEN{1'b0}});

    drive_csr(12'h3c0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("pmpaddr16 is outside configured 16-entry PMP", csr_illegal, 1'b1);

    drive_csr(`CSR_MENVCFG, 3'b001, 5'd1, `MENVCFG_PBMTE, 1'b1);
    #1;
    tb_check1("menvcfg PBMTE set is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MENVCFG, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("menvcfg only exposes PBMTE", csr_rdata, `MENVCFG_PBMTE);
    tb_check1("svpbmt enable output follows menvcfg", svpbmt_en, 1'b1);
    drive_csr(`CSR_MENVCFG, 3'b011, 5'd1, `MENVCFG_PBMTE, 1'b1);
    #1;
    tb_check1("menvcfg PBMTE clear is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MENVCFG, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("menvcfg PBMTE clears", csr_rdata, {`XLEN{1'b0}});
    tb_check1("svpbmt enable output clears", svpbmt_en, 1'b0);

    fp_fflags_valid = 1'b1;
    fp_fflags = 5'b10001;
    `TB_TICK(clk);
    fp_fflags_valid = 1'b0;
    drive_csr(`CSR_FFLAGS, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("fflags accumulates committed FP flags", csr_rdata, 64'h11);

    fp_fflags_valid = 1'b1;
    fp_fflags = 5'b01000;
    drive_csr(`CSR_FFLAGS, 3'b001, 5'd1, {`XLEN{1'b0}}, 1'b1);
    #1;
    tb_check1("fflags explicit write remains legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    fp_fflags_valid = 1'b0;
    drive_csr(`CSR_FFLAGS, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("fflags CSR write wins over same-cycle FP flags", csr_rdata, 64'h0);

    fp_fflags_valid = 1'b1;
    fp_fflags = 5'b01000;
    `TB_TICK(clk);
    fp_fflags_valid = 1'b0;
    drive_csr(`CSR_FFLAGS, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("fflags accepts later divide-by-zero flag", csr_rdata, 64'h8);

    drive_csr(`CSR_MSTATUS, 3'b001, 5'd1,
              `MSTATUS_TVM | `MSTATUS_TSR | `MSTATUS_MPP_S, 1'b1);
    #1;
    tb_check1("mstatus TVM/TSR write is legal", csr_illegal, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("mstatus keeps TVM/TSR",
               csr_rdata & (`MSTATUS_TVM | `MSTATUS_TSR),
               `MSTATUS_TVM | `MSTATUS_TSR);

    mret_valid = 1'b1;
    `TB_TICK(clk);
    mret_valid = 1'b0;
    #1;
    tb_check1("mret enters supervisor mode", priv_mode == `PRIV_S, 1'b1);
    drive_csr(`CSR_SATP, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("satp access traps under S-mode TVM", csr_illegal, 1'b1);

    drive_csr(`CSR_PMPADDR0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("pmpaddr0 access traps outside M-mode", csr_illegal, 1'b1);

    drive_csr(`CSR_PMPCFG0, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check1("pmpcfg0 write traps outside M-mode", csr_illegal, 1'b1);

    drive_csr(12'h7af, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("unknown debug CSR remains illegal", csr_illegal, 1'b1);

    tb_finish("tb_csr_file");
  end
endmodule
