  wire tb_csr_cycle_count_enable_w;
  wire [1:0] tb_core_retire_count_w;
  wire tb_pending_system_csr_commit_w;
  wire tb_head0_csr_commit_w;
  wire tb_csr_access_valid_w;
  wire [11:0] tb_csr_access_addr_w;
  wire [2:0] tb_csr_access_funct3_w;
  wire [`REG_ADDR_W-1:0] tb_csr_access_rs1_idx_w;
  wire [`XLEN-1:0] tb_csr_access_rs1_data_w;
  wire tb_csr_probe_valid_w;
  wire [11:0] tb_csr_probe_addr_w;
  wire [2:0] tb_csr_probe_funct3_w;
  wire [`REG_ADDR_W-1:0] tb_csr_probe_rs1_idx_w;
  wire tb_pending_fp_fflags_commit_w;
  wire [4:0] tb_pending_fp_commit_fflags_w;
  wire tb_csr_trap_mem_valid_w;
  wire [`XLEN-1:0] tb_csr_trap_mem_pc_w;
  wire [`TRAP_CAUSE_W-1:0] tb_csr_trap_mem_cause_w;
  wire [`XLEN-1:0] tb_csr_trap_mem_tval_w;
  wire tb_csr_trap_ex_valid_w;
  wire [`XLEN-1:0] tb_csr_trap_ex_pc_w;
  wire [`TRAP_CAUSE_W-1:0] tb_csr_trap_ex_cause_w;
  wire [`XLEN-1:0] tb_csr_trap_ex_tval_w;
  wire tb_csr_trap_irq_valid_w;
  wire [`XLEN-1:0] tb_csr_trap_irq_pc_w;
  wire [`TRAP_CAUSE_W-1:0] tb_csr_trap_irq_cause_w;
  wire tb_csr_real_mret_valid_w;
  wire tb_csr_sret_valid_w;
  wire [`XLEN-1:0] tb_csr_rdata_w;
  wire tb_csr_illegal_w;
  wire tb_csr_irq_pending_w;
  wire [`TRAP_CAUSE_W-1:0] tb_csr_irq_cause_w;
  wire [`XLEN-1:0] tb_csr_trap_target_w;
  wire [`XLEN-1:0] tb_csr_mepc_w;
  wire [`XLEN-1:0] tb_csr_ret_target_w;
  wire [1:0] tb_csr_priv_mode_w;
  wire [`TRAP_CAUSE_W-1:0] tb_csr_ecall_cause_w;
  wire [`XLEN-1:0] tb_csr_mstatus_w;
  wire [`XLEN-1:0] tb_csr_satp_w;
  wire tb_csr_svpbmt_en_w;
  wire [`PMP_CFG_BUS_W-1:0] tb_csr_pmpcfg_w;
  wire [`PMP_ADDR_BUS_W-1:0] tb_csr_pmpaddr_w;

  CsrFile u_csr_file (
    .clk(clk),
    .rst(rst),
    .cycle_count_enable_i(tb_csr_cycle_count_enable_w),
    .time_i(tb_csr_time_w),
    .instret_inc_i(tb_core_retire_count_w),
    .csr_valid_i(tb_csr_access_valid_w),
    .csr_addr_i(tb_csr_access_addr_w),
    .csr_funct3_i(tb_csr_access_funct3_w),
    .csr_rs1_idx_i(tb_csr_access_rs1_idx_w),
    .csr_rs1_data_i(tb_csr_access_rs1_data_w),
    .csr_zimm_i(tb_csr_access_rs1_idx_w),
    .csr_probe_valid_i(tb_csr_probe_valid_w),
    .csr_probe_addr_i(tb_csr_probe_addr_w),
    .csr_probe_funct3_i(tb_csr_probe_funct3_w),
    .csr_probe_rs1_idx_i(tb_csr_probe_rs1_idx_w),
    // Mirror NpcCoreTop: CSR state commits via the drained pending-system path
    // or via the queue-head CSR retire pulse when OOO_CSR_QUEUE_HEAD is enabled.
    .csr_commit_i(tb_pending_system_csr_commit_w || tb_head0_csr_commit_w),
    .csr_rdata_o(tb_csr_rdata_w),
    .csr_illegal_o(tb_csr_illegal_w),
    .fp_fflags_valid_i(tb_pending_fp_fflags_commit_w),
    .fp_fflags_i(tb_pending_fp_commit_fflags_w),
    .fp_dirty_i(tb_pending_fp_fflags_commit_w),
    .trap_mem_valid_i(tb_csr_trap_mem_valid_w),
    .trap_mem_pc_i(tb_csr_trap_mem_pc_w),
    .trap_mem_cause_i(tb_csr_trap_mem_cause_w),
    .trap_mem_tval_i(tb_csr_trap_mem_tval_w),
    .trap_ex_valid_i(tb_csr_trap_ex_valid_w),
    .trap_ex_pc_i(tb_csr_trap_ex_pc_w),
    .trap_ex_cause_i(tb_csr_trap_ex_cause_w),
    .trap_ex_tval_i(tb_csr_trap_ex_tval_w),
    .irq_software_i(tb_csr_irq_software_w),
    .irq_timer_i(tb_csr_irq_timer_w),
    .irq_external_i(tb_csr_irq_external_w),
    .irq_pending_o(tb_csr_irq_pending_w),
    .irq_cause_o(tb_csr_irq_cause_w),
    .trap_irq_valid_i(tb_csr_trap_irq_valid_w),
    .trap_irq_pc_i(tb_csr_trap_irq_pc_w),
    .trap_irq_cause_i(tb_csr_trap_irq_cause_w),
    .mret_valid_i(tb_csr_real_mret_valid_w),
    .sret_valid_i(tb_csr_sret_valid_w),
    .trap_target_o(tb_csr_trap_target_w),
    .mepc_o(tb_csr_mepc_w),
    .ret_target_o(tb_csr_ret_target_w),
    .priv_mode_o(tb_csr_priv_mode_w),
    .ecall_cause_o(tb_csr_ecall_cause_w),
    .mstatus_o(tb_csr_mstatus_w),
    .satp_o(tb_csr_satp_w),
    .svpbmt_en_o(tb_csr_svpbmt_en_w),
    .pmpcfg_o(tb_csr_pmpcfg_w),
    .pmpaddr_o(tb_csr_pmpaddr_w)
  );

`define TB_OOO_CORE_TOP_GLUE_CSR_PORTS \
    .csr_cycle_count_enable_w(tb_csr_cycle_count_enable_w), \
    .core_retire_count_w(tb_core_retire_count_w), \
    .pending_system_csr_commit_w(tb_pending_system_csr_commit_w), \
    .head0_csr_commit_w(tb_head0_csr_commit_w), \
    .csr_access_valid_w(tb_csr_access_valid_w), \
    .csr_access_addr_w(tb_csr_access_addr_w), \
    .csr_access_funct3_w(tb_csr_access_funct3_w), \
    .csr_access_rs1_idx_w(tb_csr_access_rs1_idx_w), \
    .csr_access_rs1_data_w(tb_csr_access_rs1_data_w), \
    .csr_probe_valid_w(tb_csr_probe_valid_w), \
    .csr_probe_addr_w(tb_csr_probe_addr_w), \
    .csr_probe_funct3_w(tb_csr_probe_funct3_w), \
    .csr_probe_rs1_idx_w(tb_csr_probe_rs1_idx_w), \
    .pending_fp_fflags_commit_w(tb_pending_fp_fflags_commit_w), \
    .pending_fp_commit_fflags_w(tb_pending_fp_commit_fflags_w), \
    .csr_trap_mem_valid_w(tb_csr_trap_mem_valid_w), \
    .csr_trap_mem_pc_w(tb_csr_trap_mem_pc_w), \
    .csr_trap_mem_cause_w(tb_csr_trap_mem_cause_w), \
    .csr_trap_mem_tval_w(tb_csr_trap_mem_tval_w), \
    .csr_trap_ex_valid_w(tb_csr_trap_ex_valid_w), \
    .csr_trap_ex_pc_w(tb_csr_trap_ex_pc_w), \
    .csr_trap_ex_cause_w(tb_csr_trap_ex_cause_w), \
    .csr_trap_ex_tval_w(tb_csr_trap_ex_tval_w), \
    .csr_trap_irq_valid_w(tb_csr_trap_irq_valid_w), \
    .csr_trap_irq_pc_w(tb_csr_trap_irq_pc_w), \
    .csr_trap_irq_cause_w(tb_csr_trap_irq_cause_w), \
    .csr_real_mret_valid_w(tb_csr_real_mret_valid_w), \
    .csr_sret_valid_w(tb_csr_sret_valid_w), \
    .csr_rdata_w(tb_csr_rdata_w), \
    .csr_illegal_w(tb_csr_illegal_w), \
    .csr_irq_pending_w(tb_csr_irq_pending_w), \
    .csr_irq_cause_w(tb_csr_irq_cause_w), \
    .csr_trap_target_w(tb_csr_trap_target_w), \
    .csr_mepc_w(tb_csr_mepc_w), \
    .csr_ret_target_w(tb_csr_ret_target_w), \
    .csr_priv_mode_w(tb_csr_priv_mode_w), \
    .csr_ecall_cause_w(tb_csr_ecall_cause_w), \
    .csr_mstatus_w(tb_csr_mstatus_w), \
    .csr_satp_w(tb_csr_satp_w), \
    .csr_svpbmt_en_w(tb_csr_svpbmt_en_w), \
    .csr_pmpcfg_w(tb_csr_pmpcfg_w), \
    .csr_pmpaddr_w(tb_csr_pmpaddr_w),
