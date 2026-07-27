`include "define.v"

module tb_csr_file;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg cycle_count_enable;
  reg [1:0] instret_inc;
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
  reg fp_fflags_valid;
  reg [4:0] fp_fflags;
  reg fp_dirty;  // F8：FP 写 FPR/fcsr 的脏脉冲（硬件中 fp_fflags_valid ⊆ fp_dirty）
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
  reg [`XLEN-1:0] mstatus_snapshot;

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
      // 默认镜像 main/probe，旧用例同时证明两份纯 legality predicate 一致。
      csr_probe_valid = 1'b1;
      csr_probe_addr = addr;
      csr_probe_funct3 = funct3;
      csr_probe_rs1_idx = rs1_idx;
    end
  endtask

  task automatic drive_probe;
    input valid;
    input [11:0] addr;
    input [2:0] funct3;
    input [`REG_ADDR_W-1:0] rs1_idx;
    begin
      csr_probe_valid = valid;
      csr_probe_addr = addr;
      csr_probe_funct3 = funct3;
      csr_probe_rs1_idx = rs1_idx;
    end
  endtask

  task automatic tb_check_mirrored_legality;
    input [1023:0] what;
    input exp;
    begin
      tb_check1(what, csr_illegal, exp);
      if (dut.csr_access_illegal_w !== exp ||
          dut.csr_access_illegal_w !== csr_illegal) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s main_illegal=%0b probe_illegal=%0b expected=%0b",
                 what, dut.csr_access_illegal_w, csr_illegal, exp);
      end
    end
  endtask

  CsrFile dut (
    .clk(clk),
    .rst(rst),
    .cycle_count_enable_i(cycle_count_enable),
    .time_i({`XLEN{1'b0}}),
    .instret_inc_i(instret_inc),
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
    .fp_fflags_valid_i(fp_fflags_valid),
    .fp_fflags_i(fp_fflags),
    // 硬件不变量：fp_fflags_commit 是 fp_dirty 的子集，故这里 OR 以维持旧 fflags 测试有效。
    .fp_dirty_i(fp_fflags_valid | fp_dirty),
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
    cycle_count_enable = 1'b0;
    instret_inc = 2'b00;
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
    fp_fflags_valid = 1'b0;
    fp_fflags = 5'b00000;
    fp_dirty = 1'b0;
    mret_valid = 1'b0;
    sret_valid = 1'b0;

    `TB_TICK(clk);
    rst = 1'b0;

    // INSTRET-G1 owner contract: CsrFile consumes exactly the supplied unique
    // ISA-retirement count, supports dual retirement, obeys IR inhibit, and an
    // explicit minstret write wins over the automatic increment on that edge.
    drive_csr(`CSR_MINSTRET, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("minstret reset value", csr_rdata, 64'd0);

    cycle_count_enable = 1'b1;
    instret_inc = 2'd1;
    csr_valid = 1'b0;
    csr_commit = 1'b0;
    drive_probe(1'b0, 12'h000, 3'b010, {`REG_ADDR_W{1'b0}});
    `TB_TICK(clk);
    instret_inc = 2'd0;
    drive_csr(`CSR_MINSTRET, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("minstret increments by one", csr_rdata, 64'd1);

    instret_inc = 2'd2;
    `TB_TICK(clk);
    instret_inc = 2'd0;
    #1;
    tb_check64("minstret increments by two", csr_rdata, 64'd3);

    instret_inc = 2'd1;
    drive_csr(`CSR_MINSTRET, 3'b001, 5'd1, 64'd9, 1'b1);
    `TB_TICK(clk);
    instret_inc = 2'd0;
    drive_csr(`CSR_MINSTRET, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("explicit minstret write suppresses same-edge increment",
               csr_rdata, 64'd9);

    drive_csr(`CSR_MCOUNTINHIBIT, 3'b001, 5'd1,
              `MCOUNTINHIBIT_IR, 1'b1);
    `TB_TICK(clk);
    csr_valid = 1'b0;
    csr_commit = 1'b0;
    instret_inc = 2'd2;
    `TB_TICK(clk);
    instret_inc = 2'd0;
    drive_csr(`CSR_MINSTRET, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("mcountinhibit IR suppresses minstret", csr_rdata, 64'd9);

    drive_csr(`CSR_MCOUNTINHIBIT, 3'b001, 5'd1,
              {`XLEN{1'b0}}, 1'b1);
    `TB_TICK(clk);
    cycle_count_enable = 1'b0;
    instret_inc = 2'd0;

    // 只读 CSR 的 CSRRS/CSRRC 零源操作不产生写意图；非零源必须判非法。
    drive_csr(`CSR_MVENDORID, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("read-only CSRRS x0 is legal", 1'b0);
    drive_csr(`CSR_MVENDORID, 3'b010, 5'd1, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("read-only CSRRS x1 has write intent", 1'b1);
    drive_csr(`CSR_MVENDORID, 3'b110, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("read-only CSRRSI zimm0 is legal", 1'b0);
    drive_csr(`CSR_MVENDORID, 3'b110, 5'd1, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("read-only CSRRSI zimm1 has write intent", 1'b1);

    // probe 不携带 data/commit，单独拉高写型 metadata 也不得改变 CSR 状态。
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    mstatus_snapshot = csr_rdata;
    csr_valid = 1'b0;
    csr_commit = 1'b0;
    drive_probe(1'b1, `CSR_MSTATUS, 3'b001, 5'd1);
    #1;
    tb_check1("probe-only write metadata is legal", csr_illegal, 1'b0);
    tb_check1("inactive main access is not illegal",
              dut.csr_access_illegal_w, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("probe-only metadata has no mstatus side effect",
               csr_rdata, mstatus_snapshot);

    // main 与 probe 可同拍访问不同地址；probe 非法不能阻塞合法 main 提交。
    drive_csr(`CSR_MSCRATCH, 3'b001, 5'd1,
              64'h0123_4567_89ab_cdef, 1'b1);
    drive_probe(1'b1, 12'h7af, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("unknown probe is illegal", csr_illegal, 1'b1);
    tb_check1("legal main stays legal beside illegal probe",
              dut.csr_access_illegal_w, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MSCRATCH, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("illegal probe does not suppress legal main write",
               csr_rdata, 64'h0123_4567_89ab_cdef);

    // 反向交叉也必须独立：probe 合法不能把 read-only main 写误判为合法。
    drive_csr(`CSR_MVENDORID, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    drive_probe(1'b1, `CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("legal probe remains legal beside illegal main", csr_illegal, 1'b0);
    tb_check1("read-only main write remains illegal",
              dut.csr_access_illegal_w, 1'b1);
    `TB_TICK(clk);

    drive_csr(`CSR_MVENDORID, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b0);
    drive_probe(1'b0, 12'h7af, 3'b001, 5'd1);
    #1;
    tb_check1("inactive probe suppresses illegal payload", csr_illegal, 1'b0);
    tb_check1("inactive probe does not mask main illegality",
              dut.csr_access_illegal_w, 1'b1);

    drive_csr(`CSR_TSELECT, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("tselect read is legal", 1'b0);
    tb_check64("tselect reports no usable trigger", csr_rdata, {{(`XLEN-1){1'b0}}, 1'b1});

    drive_csr(`CSR_TSELECT, 3'b001, 5'd1, {`XLEN{1'b0}}, 1'b1);
    #1;
    tb_check_mirrored_legality("tselect write is WARL legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_TSELECT, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("tselect remains hard-wired", csr_rdata, {{(`XLEN-1){1'b0}}, 1'b1});

    drive_csr(`CSR_TDATA1, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check_mirrored_legality("tdata1 write is legal no-op", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_TDATA1, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("tdata1 unsupported value", csr_rdata, {`XLEN{1'b0}});

    drive_csr(`CSR_TDATA2, 3'b001, 5'd1, 64'h8000_0040, 1'b1);
    #1;
    tb_check_mirrored_legality("tdata2 write is legal no-op", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_TDATA2, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("tdata2 unsupported value", csr_rdata, {`XLEN{1'b0}});

    drive_csr(`CSR_TCONTROL, 3'b010, 5'd1, 64'h8, 1'b1);
    #1;
    tb_check_mirrored_legality("tcontrol csrs is legal no-op", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_TCONTROL, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("tcontrol unsupported value", csr_rdata, {`XLEN{1'b0}});

    drive_csr(`CSR_MISA, 3'b111, 5'd4, {`XLEN{1'b0}}, 1'b1);
    #1;
    tb_check_mirrored_legality("misa csrci is legal WARL no-op", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MISA, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check1("misa C bit remains set", |(csr_rdata & 64'h4), 1'b1);

    drive_csr(`CSR_PMPCFG0, 3'b001, 5'd1, 64'h18, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpcfg0 write is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpcfg0 readback", csr_rdata, 64'h18);

    drive_csr(`CSR_PMPCFG0, 3'b001, 5'd1, 64'h1e, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpcfg0 R0W1 WARL write is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpcfg0 R0W1 clears permissions", csr_rdata, 64'h18);

    drive_csr(`CSR_PMPADDR15, 3'b001, 5'd1, 64'h0000_0000_1234_5678, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpaddr15 write is legal before lock", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR15, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr15 readback before lock", csr_rdata, 64'h0000_0000_1234_5678);
    tb_check64("pmpaddr15 export before lock", pmpaddr[15*`XLEN +: `XLEN], 64'h0000_0000_1234_5678);

    drive_csr(`CSR_PMPCFG2, 3'b001, 5'd1, 64'h9f00_0000_0000_0000, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpcfg2 entry15 lock write is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG2, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpcfg2 readback", csr_rdata, 64'h9f00_0000_0000_0000);
    tb_check64("pmpcfg entry15 export", {{(`XLEN-8){1'b0}}, pmpcfg[15*8 +: 8]}, 64'h9f);

    drive_csr(`CSR_PMPADDR15, 3'b001, 5'd1, 64'h0000_0000_8765_4321, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpaddr15 locked write remains legal no-op", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR15, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr15 readback after lock", csr_rdata, 64'h0000_0000_1234_5678);

    drive_csr(`CSR_PMPCFG2, 3'b001, 5'd1, 64'h0000_0000_0800_0000, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpcfg2 locked byte preserve write is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG2, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpcfg2 keeps locked entry15 while updating entry11",
               csr_rdata, 64'h9f00_0000_0800_0000);

    drive_csr(`CSR_PMPCFG1, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpcfg1 write is illegal on RV64", 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG1, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("pmpcfg1 read is illegal on RV64", 1'b1);

    drive_csr(`CSR_PMPCFG3, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpcfg3 write is illegal on RV64", 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPCFG3, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("pmpcfg3 read is illegal on RV64", 1'b1);

    drive_csr(`CSR_PMPADDR0, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpaddr0 write is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr0 masks to implemented PA bits", csr_rdata, PMPADDR_MASK_TB);
    tb_check64("pmpaddr0 export masks high bits", pmpaddr[0 +: `XLEN], PMPADDR_MASK_TB);

    drive_csr(`CSR_PMPADDR0, 3'b001, 5'd1, (64'h1 << (`PMP_ADDR_BITS - 1)), 1'b1);
    #1;
    tb_check_mirrored_legality("pmpaddr0 top implemented bit write is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr0 keeps top implemented bit", csr_rdata,
               (64'h1 << (`PMP_ADDR_BITS - 1)));

    drive_csr(`CSR_PMPADDR0, 3'b001, 5'd1, (64'h1 << `PMP_ADDR_BITS), 1'b1);
    #1;
    tb_check_mirrored_legality("pmpaddr0 first unimplemented bit write is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_PMPADDR0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("pmpaddr0 clears first unimplemented bit", csr_rdata, {`XLEN{1'b0}});

    drive_csr(12'h3c0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("pmpaddr16 is outside configured 16-entry PMP", 1'b1);

    drive_csr(`CSR_MENVCFG, 3'b001, 5'd1, `MENVCFG_PBMTE, 1'b1);
    #1;
    tb_check_mirrored_legality("menvcfg PBMTE set is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MENVCFG, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("menvcfg only exposes PBMTE", csr_rdata, `MENVCFG_PBMTE);
    tb_check1("svpbmt enable output follows menvcfg", svpbmt_en, 1'b1);
    drive_csr(`CSR_MENVCFG, 3'b011, 5'd1, `MENVCFG_PBMTE, 1'b1);
    #1;
    tb_check_mirrored_legality("menvcfg PBMTE clear is legal", 1'b0);
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
    tb_check_mirrored_legality("fflags explicit write remains legal", 1'b0);
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
    tb_check_mirrored_legality("mstatus TVM/TSR write is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("mstatus keeps TVM/TSR",
               csr_rdata & (`MSTATUS_TVM | `MSTATUS_TSR),
               `MSTATUS_TVM | `MSTATUS_TSR);

    // ===== F8：FP 写 FP 态置 mstatus.FS=Dirty（用位操作保留 MPP/TVM/TSR）=====
    drive_csr(`CSR_MSTATUS, 3'b011, 5'd1, `MSTATUS_FS_MASK, 1'b1);   // CSRRC：清 FS
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, 5'd1, `MSTATUS_FS_CLEAN, 1'b1);  // CSRRS：FS=Clean
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("FS preset to Clean (non-Dirty)", csr_rdata & `MSTATUS_FS_MASK, `MSTATUS_FS_CLEAN);
    tb_check64("SD clear when FS not Dirty", csr_rdata & `MSTATUS_SD, {`XLEN{1'b0}});
    fp_dirty = 1'b1;
    `TB_TICK(clk);
    fp_dirty = 1'b0;
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("FP write sets mstatus.FS=Dirty", csr_rdata & `MSTATUS_FS_MASK, `MSTATUS_FS_DIRTY);
    tb_check64("mstatus.SD derives from FS=Dirty", csr_rdata & `MSTATUS_SD, `MSTATUS_SD);

    // VS 可在 misa.V=0 时作为状态字段存在。虚拟内存架构测试环境保存/恢复
    // 该字段；CsrFile 必须经 mstatus/sstatus 精确保留，但仍不声明 V ISA。
    drive_csr(`CSR_MSTATUS, 3'b011, 5'd1,
              `MSTATUS_FS_MASK | `MSTATUS_VS_MASK, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, 5'd1, `MSTATUS_VS_CLEAN, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("mstatus retains VS=Clean",
               csr_rdata & `MSTATUS_VS_MASK, `MSTATUS_VS_CLEAN);
    tb_check64("SD clear when FS and VS are not Dirty",
               csr_rdata & `MSTATUS_SD, {`XLEN{1'b0}});

    drive_csr(`CSR_SSTATUS, 3'b010, 5'd1, `MSTATUS_VS_DIRTY, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_SSTATUS, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("sstatus retains VS=Dirty",
               csr_rdata & `MSTATUS_VS_MASK, `MSTATUS_VS_DIRTY);
    tb_check64("sstatus.SD derives from VS=Dirty",
               csr_rdata & `MSTATUS_SD, `MSTATUS_SD);

    drive_csr(`CSR_SSTATUS, 3'b011, 5'd1, `MSTATUS_VS_MASK, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("sstatus write clears mstatus.VS",
               csr_rdata & `MSTATUS_VS_MASK, {`XLEN{1'b0}});
    tb_check64("SD clears after FS and VS clear",
               csr_rdata & `MSTATUS_SD, {`XLEN{1'b0}});

    // ===== F6：mip 的 MTIP/MSIP/MEIP 只读，M 态写应被忽略（irq 线为低）=====
    drive_csr(`CSR_MIP, 3'b010, 5'd1, `MIP_MTIP | `MIP_MSIP | `MIP_MEIP, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_MIP, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("mip MTIP/MSIP/MEIP read-only (write ignored)",
               csr_rdata & (`MIP_MTIP | `MIP_MSIP | `MIP_MEIP), {`XLEN{1'b0}});
    drive_csr(`CSR_MIP, 3'b010, 5'd1, `MIP_STIP, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_MIP, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("mip STIP writable from M-mode", csr_rdata & `MIP_STIP, `MIP_STIP);

    // ===== F11：sip 视图仅 SSIP 可写；经 sip 写 STIP 被忽略 =====
    drive_csr(`CSR_MIP, 3'b011, 5'd1, `MIP_STIP | `MIP_SSIP, 1'b1);  // CSRRC：清 STIP/SSIP
    `TB_TICK(clk);
    drive_csr(`CSR_SIP, 3'b010, 5'd1, `MIP_STIP | `MIP_SSIP, 1'b1);  // 经 sip CSRRS 写
    `TB_TICK(clk);
    drive_csr(`CSR_MIP, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("sip write of STIP ignored (read-only via sip)", csr_rdata & `MIP_STIP, {`XLEN{1'b0}});
    tb_check64("sip write of SSIP takes effect", csr_rdata & `MIP_SSIP, `MIP_SSIP);

    // ===== F7：RV64 下 *h 计数器 CSR 非法 =====
    drive_csr(`CSR_CYCLEH, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("RV64 cycleh is illegal", 1'b1);
    drive_csr(`CSR_MCYCLEH, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("RV64 mcycleh is illegal", 1'b1);
    drive_csr(`CSR_INSTRETH, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("RV64 instreth is illegal", 1'b1);

    // 为 S/U 计数器 probe 构造逐级授权：M 放行 CY/TM，S 只放行 CY。
    drive_csr(`CSR_MCOUNTEREN, 3'b001, 5'd1,
              `COUNTEREN_CY | `COUNTEREN_TM, 1'b1);
    #1;
    tb_check_mirrored_legality("mcounteren setup is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_SCOUNTEREN, 3'b001, 5'd1, `COUNTEREN_CY, 1'b1);
    #1;
    tb_check_mirrored_legality("scounteren setup is legal", 1'b0);
    `TB_TICK(clk);

    // 早先的 TSR=1 读回覆盖保留；进入可达 xRET 流程前，由 M 态合法写只清 TSR，
    // 同时证明 TVM 与 MPP=S 未被误伤，使后续 SRET 符合真实前端的准入条件。
    drive_csr(`CSR_MSTATUS, 3'b011, 5'd1, `MSTATUS_TSR, 1'b1);
    #1;
    tb_check_mirrored_legality("mstatus TSR clear before xRET is legal", 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("xRET setup keeps TVM, clears TSR, and keeps MPP=S",
               csr_rdata & (`MSTATUS_TVM | `MSTATUS_TSR | `MSTATUS_MPP_MASK),
               `MSTATUS_TVM | `MSTATUS_MPP_S);

    // policy 改变沿采用 pre-edge 状态：MRET 沿前 MSTATUS probe 合法，沿后才因 S 态非法。
    csr_valid = 1'b0;
    csr_commit = 1'b0;
    drive_probe(1'b1, `CSR_MSTATUS, 3'b010, {`REG_ADDR_W{1'b0}});
    mret_valid = 1'b1;
    #1;
    tb_check1("mret edge probe sees pre-edge M privilege", csr_illegal, 1'b0);
    `TB_TICK(clk);
    mret_valid = 1'b0;
    #1;
    tb_check1("mret enters supervisor mode", priv_mode == `PRIV_S, 1'b1);
    tb_check1("same probe sees post-edge S privilege", csr_illegal, 1'b1);

    // S 态只看 mcounteren：CY/TM 均放行，IR 未放行。
    drive_csr(`CSR_SSTATUS, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    drive_probe(1'b1, `CSR_CYCLE, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("S-mode cycle probe allowed by mcounteren", csr_illegal, 1'b0);
    tb_check1("independent SSTATUS main access stays legal",
              dut.csr_access_illegal_w, 1'b0);
    drive_probe(1'b1, `CSR_TIME, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("S-mode time probe allowed by mcounteren", csr_illegal, 1'b0);
    drive_probe(1'b1, `CSR_INSTRET, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("S-mode instret probe denied by mcounteren", csr_illegal, 1'b1);

    // TVM 非法 probe 不得反向阻塞合法的 S-mode main 写。
    drive_csr(`CSR_SSCRATCH, 3'b001, 5'd1,
              64'h55aa_0123_4567_89ab, 1'b1);
    drive_probe(1'b1, `CSR_SATP, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("S-mode SATP probe is illegal under TVM", csr_illegal, 1'b1);
    tb_check1("legal SSCRATCH main write remains legal",
              dut.csr_access_illegal_w, 1'b0);
    `TB_TICK(clk);
    drive_csr(`CSR_SSCRATCH, 3'b010, {`REG_ADDR_W{1'b0}},
              {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check64("illegal SATP probe does not suppress SSCRATCH write",
               csr_rdata, 64'h55aa_0123_4567_89ab);

    // 反向交叉：S 态 main 写 MSTATUS 非法，即使同拍 probe 合法也不得清掉 TVM。
    drive_csr(`CSR_MSTATUS, 3'b001, 5'd1, {`XLEN{1'b0}}, 1'b1);
    drive_probe(1'b1, `CSR_SSTATUS, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("SSTATUS probe remains legal beside illegal main", csr_illegal, 1'b0);
    tb_check1("S-mode MSTATUS main write is illegal",
              dut.csr_access_illegal_w, 1'b1);
    `TB_TICK(clk);
    drive_csr(`CSR_SATP, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("illegal main write preserves TVM policy", 1'b1);

    drive_csr(`CSR_PMPADDR0, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("pmpaddr0 access traps outside M-mode", 1'b1);

    drive_csr(`CSR_PMPCFG0, 3'b001, 5'd1, {`XLEN{1'b1}}, 1'b1);
    #1;
    tb_check_mirrored_legality("pmpcfg0 write traps outside M-mode", 1'b1);

    drive_csr(12'h7af, 3'b010, {`REG_ADDR_W{1'b0}}, {`XLEN{1'b0}}, 1'b0);
    #1;
    tb_check_mirrored_legality("unknown debug CSR remains illegal", 1'b1);

    // TSR 已由上面的合法 M 态 CSR 写清零，因此该 SRET 是前端可达请求；其状态变化
    // 同样只在时钟沿后进入 probe 视图。U 态计数器需同时通过 M/S 两级授权。
    csr_valid = 1'b0;
    csr_commit = 1'b0;
    drive_probe(1'b1, `CSR_SSTATUS, 3'b010, {`REG_ADDR_W{1'b0}});
    sret_valid = 1'b1;
    #1;
    tb_check1("sret edge probe sees pre-edge S privilege", csr_illegal, 1'b0);
    `TB_TICK(clk);
    sret_valid = 1'b0;
    #1;
    tb_check1("sret enters user mode", priv_mode == `PRIV_U, 1'b1);
    tb_check1("same probe sees post-edge U privilege", csr_illegal, 1'b1);
    drive_probe(1'b1, `CSR_CYCLE, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("U-mode cycle probe allowed by M/S counteren", csr_illegal, 1'b0);
    drive_probe(1'b1, `CSR_TIME, 3'b010, {`REG_ADDR_W{1'b0}});
    #1;
    tb_check1("U-mode time probe denied by scounteren", csr_illegal, 1'b1);

    tb_finish("tb_csr_file");
  end
endmodule
