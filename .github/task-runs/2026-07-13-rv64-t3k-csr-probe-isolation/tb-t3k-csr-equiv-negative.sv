`include "define.v"

// This is a deliberate assertion-negative harness.  It forces only the probe
// result after proving the two valid payloads are identical, so the assertion
// antecedent is demonstrably reachable and exactly one divergence is injected.
module tb_t3k_csr_equiv_negative;
  reg clk;
  reg rst;
  reg csr_valid;
  reg [11:0] csr_addr;
  reg [2:0] csr_funct3;
  reg [`REG_ADDR_W-1:0] csr_rs1_idx;
  reg csr_probe_valid;
  reg [11:0] csr_probe_addr;
  reg [2:0] csr_probe_funct3;
  reg [`REG_ADDR_W-1:0] csr_probe_rs1_idx;
  wire csr_illegal;
  wire [`XLEN-1:0] csr_rdata;
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
  wire [2:0] frm;
  wire [`PMP_CFG_BUS_W-1:0] pmpcfg;
  wire [`PMP_ADDR_BUS_W-1:0] pmpaddr;

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
    .csr_rs1_data_i({`XLEN{1'b0}}),
    .csr_zimm_i(csr_rs1_idx),
    .csr_commit_i(1'b0),
    .csr_probe_valid_i(csr_probe_valid),
    .csr_probe_addr_i(csr_probe_addr),
    .csr_probe_funct3_i(csr_probe_funct3),
    .csr_probe_rs1_idx_i(csr_probe_rs1_idx),
    .csr_rdata_o(csr_rdata),
    .csr_illegal_o(csr_illegal),
    .fp_fflags_valid_i(1'b0),
    .fp_fflags_i(5'b00000),
    .fp_dirty_i(1'b0),
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
    .mret_valid_i(1'b0),
    .sret_valid_i(1'b0),
    .trap_target_o(trap_target),
    .mepc_o(mepc),
    .ret_target_o(ret_target),
    .priv_mode_o(priv_mode),
    .ecall_cause_o(ecall_cause),
    .mstatus_o(mstatus),
    .satp_o(satp),
    .svpbmt_en_o(svpbmt_en),
    .frm_o(frm),
    .pmpcfg_o(pmpcfg),
    .pmpaddr_o(pmpaddr)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    csr_valid = 1'b0;
    csr_addr = `CSR_MSTATUS;
    csr_funct3 = 3'b010;
    csr_rs1_idx = {`REG_ADDR_W{1'b0}};
    csr_probe_valid = 1'b0;
    csr_probe_addr = `CSR_MSTATUS;
    csr_probe_funct3 = 3'b010;
    csr_probe_rs1_idx = {`REG_ADDR_W{1'b0}};

    @(posedge clk);
    @(negedge clk);
    rst = 1'b0;
    csr_valid = 1'b1;
    csr_probe_valid = 1'b1;
    #1;
    if ((dut.csr_access_illegal_w !== 1'b0) ||
        (dut.csr_probe_illegal_w !== 1'b0)) begin
      $display("[T3K-NEGATIVE-HARNESS-SETUP-ERROR] main=%b probe=%b",
               dut.csr_access_illegal_w, dut.csr_probe_illegal_w);
      $finish;
    end

    force dut.csr_probe_illegal_w = 1'b1;
    #1;
    if (!(csr_valid && csr_probe_valid &&
          (csr_addr == csr_probe_addr) &&
          (csr_funct3 == csr_probe_funct3) &&
          (csr_rs1_idx == csr_probe_rs1_idx) &&
          (dut.csr_access_illegal_w !== dut.csr_probe_illegal_w))) begin
      $display("[T3K-NEGATIVE-HARNESS-PREMISE-ERROR]");
      $finish;
    end
    $display("[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1");

    @(posedge clk);
    #1;
    release dut.csr_probe_illegal_w;
    csr_valid = 1'b0;
    csr_probe_valid = 1'b0;
    @(negedge clk);
    $display("[PASS] tb_t3k_csr_equiv_negative");
    $finish;
  end
endmodule
