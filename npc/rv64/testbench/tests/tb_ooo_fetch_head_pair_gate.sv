`include "define.v"
`include "common/OooSlotFacts.vh"

module tb_ooo_fetch_head_pair_gate;
  `include "tb_common.svh"

  reg fifo_has_packet;
  reg [1:0] head_resp0;
  reg [1:0] head_resp1;
  reg [`INST_W-1:0] head_inst0;
  reg [`INST_W-1:0] head_inst1;
  reg [`CTRL_BUS_W-1:0] head0_ctrl;
  reg [`CTRL_BUS_W-1:0] head1_ctrl;
  reg [1:0] priv_mode;
  reg [`XLEN-1:0] mstatus;
  reg branch_spec_active;
  reg can_run;
  reg csr_irq_pending;

  wire head_fetch_fault0;
  wire head_fetch_fault1;
  wire head_fetch_fault;

  wire head0_illegal_raw;
  wire head0_branch_raw;
  wire head0_jal_raw;
  wire head0_jalr_raw;
  wire head0_jump_raw;
  wire head0_mem_raw;
  wire head0_fp_load_raw;
  wire head0_fp_store_raw;
  wire head0_fp_move_to_fpr_raw;
  wire head0_fp_move_to_gpr_raw;
  wire head0_fp_class_raw;
  wire head0_fp_sgnj_raw;
  wire head0_fp_addsub_raw;
  wire head0_fp_mul_raw;
  wire head0_fp_fma_raw;
  wire head0_fp_div_raw;
  wire head0_fp_sqrt_raw;
  wire head0_fp_minmax_raw;
  wire head0_fp_compare_raw;
  wire head0_fp_convert_to_fpr_raw;
  wire head0_fp_convert_to_gpr_raw;
  wire head0_fp_raw;
  wire head0_fp_double;
  wire head0_fp_gpr_write;
  wire head0_fp_disabled;
  wire head0_fp_enabled;
  wire head0_ecall_raw;
  wire head0_ebreak_raw;
  wire head0_semihost_ebreak;
  wire head0_csr_raw;
  wire head0_mret_raw;
  wire head0_sret_raw;
  wire head0_xret_raw;
  wire head0_wfi_raw;
  wire head0_sfence_raw;
  wire head0_priv_system_illegal;
  wire head0_exit_raw;
  wire head0_system_raw;
  wire head0_arch_trap_raw;
  wire head0_stop_raw;
  wire [`OOO_SLOT_FACTS_W-1:0] head0_facts;

  wire head1_illegal_raw;
  wire head1_control_raw;
  wire head1_branch_raw;
  wire head1_jal_raw;
  wire head1_jalr_raw;
  wire head1_jump_raw;
  wire head1_mem_raw;
  wire head1_fp_load_raw;
  wire head1_fp_store_raw;
  wire head1_fp_move_to_fpr_raw;
  wire head1_fp_move_to_gpr_raw;
  wire head1_fp_class_raw;
  wire head1_fp_sgnj_raw;
  wire head1_fp_addsub_raw;
  wire head1_fp_mul_raw;
  wire head1_fp_fma_raw;
  wire head1_fp_div_raw;
  wire head1_fp_sqrt_raw;
  wire head1_fp_minmax_raw;
  wire head1_fp_compare_raw;
  wire head1_fp_convert_to_fpr_raw;
  wire head1_fp_convert_to_gpr_raw;
  wire head1_fp_raw;
  wire head1_fp_double;
  wire head1_fp_gpr_write;
  wire head1_fp_disabled;
  wire head1_fp_enabled;
  wire head1_ecall_raw;
  wire head1_ebreak_raw;
  wire head1_semihost_ebreak;
  wire head1_csr_raw;
  wire head1_mret_raw;
  wire head1_sret_raw;
  wire head1_xret_raw;
  wire head1_wfi_raw;
  wire head1_sfence_raw;
  wire head1_priv_system_illegal;
  wire head1_exit_raw;
  wire head1_system_raw;
  wire head1_arch_trap_raw;
  wire head1_stop_raw;
  wire [`OOO_SLOT_FACTS_W-1:0] head1_facts;

  wire branch_spec_dispatch_block;
  wire dispatch_valid;
  wire dispatch0_ecall;
  wire dispatch0_ebreak;
  wire dispatch0_exit;
  wire dispatch0_arch_trap;
  wire dispatch0_system;
  wire dispatch0_fp;
  wire dispatch0_branch;
  wire dispatch0_jal;
  wire dispatch0_jump;
  wire direct_branch0_dispatch_valid;

  localparam [`INST_W-1:0] INST_ADDI = 32'h0000_0093;
  localparam [`INST_W-1:0] INST_FADD_S = 32'h0020_80d3;

  OooFetchHeadPairGate dut (
    .fifo_has_packet_i(fifo_has_packet),
    .head_resp0_i(head_resp0),
    .head_resp1_i(head_resp1),
    .head_inst0_i(head_inst0),
    .head_inst1_i(head_inst1),
    .head0_ctrl_i(head0_ctrl),
    .head1_ctrl_i(head1_ctrl),
    .priv_mode_i(priv_mode),
    .mstatus_i(mstatus),
    .branch_spec_active_i(branch_spec_active),
    .can_run_i(can_run),
    .csr_irq_pending_i(csr_irq_pending),
    .head_fetch_fault0_o(head_fetch_fault0),
    .head_fetch_fault1_o(head_fetch_fault1),
    .head_fetch_fault_o(head_fetch_fault),
    .head0_illegal_raw_o(head0_illegal_raw),
    .head0_branch_raw_o(head0_branch_raw),
    .head0_jal_raw_o(head0_jal_raw),
    .head0_jalr_raw_o(head0_jalr_raw),
    .head0_jump_raw_o(head0_jump_raw),
    .head0_mem_raw_o(head0_mem_raw),
    .head0_fp_load_raw_o(head0_fp_load_raw),
    .head0_fp_store_raw_o(head0_fp_store_raw),
    .head0_fp_move_to_fpr_raw_o(head0_fp_move_to_fpr_raw),
    .head0_fp_move_to_gpr_raw_o(head0_fp_move_to_gpr_raw),
    .head0_fp_class_raw_o(head0_fp_class_raw),
    .head0_fp_sgnj_raw_o(head0_fp_sgnj_raw),
    .head0_fp_addsub_raw_o(head0_fp_addsub_raw),
    .head0_fp_mul_raw_o(head0_fp_mul_raw),
    .head0_fp_fma_raw_o(head0_fp_fma_raw),
    .head0_fp_div_raw_o(head0_fp_div_raw),
    .head0_fp_sqrt_raw_o(head0_fp_sqrt_raw),
    .head0_fp_minmax_raw_o(head0_fp_minmax_raw),
    .head0_fp_compare_raw_o(head0_fp_compare_raw),
    .head0_fp_convert_to_fpr_raw_o(head0_fp_convert_to_fpr_raw),
    .head0_fp_convert_to_gpr_raw_o(head0_fp_convert_to_gpr_raw),
    .head0_fp_raw_o(head0_fp_raw),
    .head0_fp_double_o(head0_fp_double),
    .head0_fp_gpr_write_o(head0_fp_gpr_write),
    .head0_fp_disabled_o(head0_fp_disabled),
    .head0_fp_enabled_o(head0_fp_enabled),
    .head0_ecall_raw_o(head0_ecall_raw),
    .head0_ebreak_raw_o(head0_ebreak_raw),
    .head0_semihost_ebreak_o(head0_semihost_ebreak),
    .head0_csr_raw_o(head0_csr_raw),
    .head0_mret_raw_o(head0_mret_raw),
    .head0_sret_raw_o(head0_sret_raw),
    .head0_xret_raw_o(head0_xret_raw),
    .head0_wfi_raw_o(head0_wfi_raw),
    .head0_sfence_raw_o(head0_sfence_raw),
    .head0_priv_system_illegal_o(head0_priv_system_illegal),
    .head0_exit_raw_o(head0_exit_raw),
    .head0_system_raw_o(head0_system_raw),
    .head0_arch_trap_raw_o(head0_arch_trap_raw),
    .head0_stop_raw_o(head0_stop_raw),
    .head0_facts_o(head0_facts),
    .head1_illegal_raw_o(head1_illegal_raw),
    .head1_control_raw_o(head1_control_raw),
    .head1_branch_raw_o(head1_branch_raw),
    .head1_jal_raw_o(head1_jal_raw),
    .head1_jalr_raw_o(head1_jalr_raw),
    .head1_jump_raw_o(head1_jump_raw),
    .head1_mem_raw_o(head1_mem_raw),
    .head1_fp_load_raw_o(head1_fp_load_raw),
    .head1_fp_store_raw_o(head1_fp_store_raw),
    .head1_fp_move_to_fpr_raw_o(head1_fp_move_to_fpr_raw),
    .head1_fp_move_to_gpr_raw_o(head1_fp_move_to_gpr_raw),
    .head1_fp_class_raw_o(head1_fp_class_raw),
    .head1_fp_sgnj_raw_o(head1_fp_sgnj_raw),
    .head1_fp_addsub_raw_o(head1_fp_addsub_raw),
    .head1_fp_mul_raw_o(head1_fp_mul_raw),
    .head1_fp_fma_raw_o(head1_fp_fma_raw),
    .head1_fp_div_raw_o(head1_fp_div_raw),
    .head1_fp_sqrt_raw_o(head1_fp_sqrt_raw),
    .head1_fp_minmax_raw_o(head1_fp_minmax_raw),
    .head1_fp_compare_raw_o(head1_fp_compare_raw),
    .head1_fp_convert_to_fpr_raw_o(head1_fp_convert_to_fpr_raw),
    .head1_fp_convert_to_gpr_raw_o(head1_fp_convert_to_gpr_raw),
    .head1_fp_raw_o(head1_fp_raw),
    .head1_fp_double_o(head1_fp_double),
    .head1_fp_gpr_write_o(head1_fp_gpr_write),
    .head1_fp_disabled_o(head1_fp_disabled),
    .head1_fp_enabled_o(head1_fp_enabled),
    .head1_ecall_raw_o(head1_ecall_raw),
    .head1_ebreak_raw_o(head1_ebreak_raw),
    .head1_semihost_ebreak_o(head1_semihost_ebreak),
    .head1_csr_raw_o(head1_csr_raw),
    .head1_mret_raw_o(head1_mret_raw),
    .head1_sret_raw_o(head1_sret_raw),
    .head1_xret_raw_o(head1_xret_raw),
    .head1_wfi_raw_o(head1_wfi_raw),
    .head1_sfence_raw_o(head1_sfence_raw),
    .head1_priv_system_illegal_o(head1_priv_system_illegal),
    .head1_exit_raw_o(head1_exit_raw),
    .head1_system_raw_o(head1_system_raw),
    .head1_arch_trap_raw_o(head1_arch_trap_raw),
    .head1_stop_raw_o(head1_stop_raw),
    .head1_facts_o(head1_facts),
    .branch_spec_dispatch_block_o(branch_spec_dispatch_block),
    .dispatch_valid_o(dispatch_valid),
    .dispatch0_ecall_o(dispatch0_ecall),
    .dispatch0_ebreak_o(dispatch0_ebreak),
    .dispatch0_exit_o(dispatch0_exit),
    .dispatch0_arch_trap_o(dispatch0_arch_trap),
    .dispatch0_system_o(dispatch0_system),
    .dispatch0_fp_o(dispatch0_fp),
    .dispatch0_branch_o(dispatch0_branch),
    .dispatch0_jal_o(dispatch0_jal),
    .dispatch0_jump_o(dispatch0_jump),
    .direct_branch0_dispatch_valid_o(direct_branch0_dispatch_valid)
  );

  task automatic reset_inputs;
    begin
      fifo_has_packet = 1'b1;
      head_resp0 = 2'b00;
      head_resp1 = 2'b00;
      head_inst0 = INST_ADDI;
      head_inst1 = INST_ADDI;
      head0_ctrl = {`CTRL_BUS_W{1'b0}};
      head1_ctrl = {`CTRL_BUS_W{1'b0}};
      priv_mode = `PRIV_M;
      mstatus = `MSTATUS_FS_CLEAN;
      branch_spec_active = 1'b0;
      can_run = 1'b1;
      csr_irq_pending = 1'b0;
      #1;
    end
  endtask

  task automatic set_ctrl0_bit;
    input integer bit_idx;
    input value;
    begin
      head0_ctrl[bit_idx] = value;
    end
  endtask

  task automatic set_ctrl1_bit;
    input integer bit_idx;
    input value;
    begin
      head1_ctrl[bit_idx] = value;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    fifo_has_packet = 1'b0;
    #1;
    tb_check1("idle no dispatch", dispatch_valid, 1'b0);
    tb_check1("idle no head0 branch", head0_branch_raw, 1'b0);
    tb_check1("idle no head1 branch", head1_branch_raw, 1'b0);
    tb_check1("idle no fetch fault", head_fetch_fault, 1'b0);

    reset_inputs();
    tb_check1("dual alu dispatch valid", dispatch_valid, 1'b1);
    tb_check1("dual alu no fault", head_fetch_fault, 1'b0);
    tb_check1("dual alu lane1 visible as no stop", head1_stop_raw, 1'b0);
    tb_check1("dual alu head0 facts stop", head0_facts[`OOO_SLOT_FACT_STOP],
              head0_stop_raw);
    tb_check1("dual alu head1 facts stop", head1_facts[`OOO_SLOT_FACT_STOP],
              head1_stop_raw);

    reset_inputs();
    set_ctrl0_bit(`CTRL_BRANCH_BIT, 1'b1);
    set_ctrl1_bit(`CTRL_BRANCH_BIT, 1'b1);
    head_resp1 = 2'b01;
    #1;
    tb_check1("lane0 branch raw", head0_branch_raw, 1'b1);
    tb_check1("lane0 branch fact", head0_facts[`OOO_SLOT_FACT_BRANCH], 1'b1);
    tb_check1("lane0 branch suppresses lane1 branch", head1_branch_raw, 1'b0);
    tb_check1("lane0 branch suppresses lane1 fault", head_fetch_fault1, 1'b0);
    tb_check1("branch dispatch alias", direct_branch0_dispatch_valid,
              dispatch0_branch);

    reset_inputs();
    set_ctrl0_bit(`CTRL_ILLEGAL_BIT, 1'b1);
    set_ctrl1_bit(`CTRL_BRANCH_BIT, 1'b1);
    #1;
    tb_check1("lane0 illegal stops", head0_stop_raw, 1'b1);
    tb_check1("lane0 illegal fact", head0_facts[`OOO_SLOT_FACT_ILLEGAL],
              1'b1);
    tb_check1("lane0 stop fact", head0_facts[`OOO_SLOT_FACT_STOP], 1'b1);
    tb_check1("lane0 stop suppresses lane1", head1_branch_raw, 1'b0);
    tb_check1("lane0 illegal dispatch arch trap", dispatch0_arch_trap, 1'b1);

    reset_inputs();
    head_resp0 = 2'b01;
    set_ctrl1_bit(`CTRL_BRANCH_BIT, 1'b1);
    #1;
    tb_check1("lane0 fetch fault", head_fetch_fault0, 1'b1);
    tb_check1("lane0 fetch fault suppresses lane1", head1_branch_raw, 1'b0);
    tb_check1("lane0 fetch fault blocks dispatch", dispatch_valid, 1'b0);

    reset_inputs();
    head_resp1 = 2'b10;
    #1;
    tb_check1("lane1 fetch fault", head_fetch_fault1, 1'b1);
    tb_check1("any fetch fault", head_fetch_fault, 1'b1);
    tb_check1("lane1 fault arch trap fact", head1_arch_trap_raw, 1'b1);
    tb_check1("lane1 fault stop fact", head1_stop_raw, 1'b1);
    tb_check1("lane1 facts arch trap",
              head1_facts[`OOO_SLOT_FACT_ARCH_TRAP], 1'b1);
    tb_check1("lane1 facts stop", head1_facts[`OOO_SLOT_FACT_STOP], 1'b1);

    reset_inputs();
    branch_spec_active = 1'b1;
    set_ctrl0_bit(`CTRL_LOAD_BIT, 1'b1);
    #1;
    tb_check1("branch spec blocks head0 memory", branch_spec_dispatch_block,
              1'b1);
    tb_check1("head0 memory fact", head0_facts[`OOO_SLOT_FACT_MEM], 1'b1);
    tb_check1("branch spec block suppresses dispatch", dispatch_valid, 1'b0);

    reset_inputs();
    branch_spec_active = 1'b1;
    set_ctrl1_bit(`CTRL_JAL_BIT, 1'b1);
    #1;
    tb_check1("branch spec blocks head1 control", branch_spec_dispatch_block,
              1'b1);
    tb_check1("head1 control fact", head1_facts[`OOO_SLOT_FACT_CONTROL],
              1'b1);

    reset_inputs();
    branch_spec_active = 1'b1;
    head_resp1 = 2'b01;
    #1;
    tb_check1("branch spec blocks lane1 fault", branch_spec_dispatch_block,
              1'b1);

    reset_inputs();
    csr_irq_pending = 1'b1;
    set_ctrl0_bit(`CTRL_BRANCH_BIT, 1'b1);
    #1;
    tb_check1("irq preserves head0 branch fact", head0_branch_raw, 1'b1);
    tb_check1("irq blocks dispatch", dispatch_valid, 1'b0);
    tb_check1("irq blocks dispatch0 branch", dispatch0_branch, 1'b0);

    reset_inputs();
    can_run = 1'b0;
    set_ctrl0_bit(`CTRL_JAL_BIT, 1'b1);
    #1;
    tb_check1("can run off preserves head0 jal fact", head0_jal_raw, 1'b1);
    tb_check1("can run off head0 jal fact", head0_facts[`OOO_SLOT_FACT_JAL],
              1'b1);
    tb_check1("can run off blocks dispatch", dispatch_valid, 1'b0);

    reset_inputs();
    set_ctrl0_bit(`CTRL_JAL_BIT, 1'b1);
    #1;
    tb_check1("jal sets jump fact", head0_facts[`OOO_SLOT_FACT_JUMP], 1'b1);
    tb_check1("jal dispatch0 jal", dispatch0_jal, 1'b1);
    tb_check1("jal does not drive dispatch0 jump", dispatch0_jump, 1'b0);

    reset_inputs();
    set_ctrl0_bit(`CTRL_JALR_BIT, 1'b1);
    #1;
    tb_check1("jalr sets jalr fact", head0_facts[`OOO_SLOT_FACT_JALR], 1'b1);
    tb_check1("jalr sets jump fact", head0_facts[`OOO_SLOT_FACT_JUMP], 1'b1);
    tb_check1("jalr drives dispatch0 jump", dispatch0_jump, 1'b1);

    reset_inputs();
    head_inst0 = INST_FADD_S;
    set_ctrl0_bit(`CTRL_ILLEGAL_BIT, 1'b1);
    mstatus = {`XLEN{1'b0}};
    #1;
    tb_check1("fs off fp raw", head0_fp_raw, 1'b1);
    tb_check1("fs off fp disabled", head0_fp_disabled, 1'b1);
    tb_check1("fs off fp disabled fact",
              head0_facts[`OOO_SLOT_FACT_FP_DISABLED], 1'b1);
    tb_check1("fs off fp arch trap", head0_arch_trap_raw, 1'b1);
    tb_check1("fs off fp no dispatch0 fp", dispatch0_fp, 1'b0);
    tb_check1("fs off fp dispatch0 arch trap", dispatch0_arch_trap, 1'b1);

    tb_finish("tb_ooo_fetch_head_pair_gate");
  end
endmodule
