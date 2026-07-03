`include "define.v"
`include "common/OooSlotFacts.v"

module tb_ooo_fetch_head_classify_gate;
  `include "tb_common.svh"

  reg decode_valid;
  reg fetch_fault;
  reg [`INST_W-1:0] inst;
  reg [`INST_W-1:0] semihost_peer_inst;
  reg semihost_peer_is_enter;
  reg [`CTRL_BUS_W-1:0] ctrl;
  reg [1:0] priv_mode;
  reg [`XLEN-1:0] mstatus;
  reg [2:0] frm;

  wire illegal_raw;
  wire branch_raw;
  wire jal_raw;
  wire jalr_raw;
  wire jump_raw;
  wire mem_raw;
  wire control_raw;
  wire fp_load_raw;
  wire fp_store_raw;
  wire fp_move_to_fpr_raw;
  wire fp_move_to_gpr_raw;
  wire fp_class_raw;
  wire fp_sgnj_raw;
  wire fp_addsub_raw;
  wire fp_mul_raw;
  wire fp_fma_raw;
  wire fp_div_raw;
  wire fp_sqrt_raw;
  wire fp_minmax_raw;
  wire fp_compare_raw;
  wire fp_convert_to_fpr_raw;
  wire fp_convert_to_gpr_raw;
  wire fp_raw;
  wire fp_double;
  wire fp_gpr_write;
  wire fp_disabled;
  wire fp_enabled;
  wire ecall_raw;
  wire ebreak_raw;
  wire semihost_ebreak;
  wire csr_raw;
  wire mret_raw;
  wire sret_raw;
  wire xret_raw;
  wire wfi_raw;
  wire sfence_raw;
  wire priv_system_illegal;
  wire exit_raw;
  wire system_raw;
  wire arch_trap_raw;
  wire stop_raw;
  wire [`OOO_SLOT_FACTS_W-1:0] facts;

  localparam [`INST_W-1:0] INST_ADDI = 32'h0000_0093;
  localparam [`INST_W-1:0] INST_FADD_S = 32'h0020_80d3;
  localparam [`INST_W-1:0] INST_FADD_S_DYN = 32'h0020_f0d3;  // FADD.S 但 rm=DYN(funct3=111)
  localparam [`INST_W-1:0] INST_EBREAK = 32'h0010_0073;
  localparam [`INST_W-1:0] SEMIHOST_ENTER_INST = 32'h01f0_1013;
  localparam [`INST_W-1:0] SEMIHOST_EXIT_INST = 32'h4070_5013;

  OooFetchHeadClassifyGate dut (
    .decode_valid_i(decode_valid),
    .fetch_fault_i(fetch_fault),
    .inst_i(inst),
    .semihost_peer_inst_i(semihost_peer_inst),
    .semihost_peer_is_enter_i(semihost_peer_is_enter),
    .ctrl_i(ctrl),
    .priv_mode_i(priv_mode),
    .mstatus_i(mstatus),
    .frm_i(frm),
    .illegal_raw_o(illegal_raw),
    .branch_raw_o(branch_raw),
    .jal_raw_o(jal_raw),
    .jalr_raw_o(jalr_raw),
    .jump_raw_o(jump_raw),
    .mem_raw_o(mem_raw),
    .control_raw_o(control_raw),
    .fp_load_raw_o(fp_load_raw),
    .fp_store_raw_o(fp_store_raw),
    .fp_move_to_fpr_raw_o(fp_move_to_fpr_raw),
    .fp_move_to_gpr_raw_o(fp_move_to_gpr_raw),
    .fp_class_raw_o(fp_class_raw),
    .fp_sgnj_raw_o(fp_sgnj_raw),
    .fp_addsub_raw_o(fp_addsub_raw),
    .fp_mul_raw_o(fp_mul_raw),
    .fp_fma_raw_o(fp_fma_raw),
    .fp_div_raw_o(fp_div_raw),
    .fp_sqrt_raw_o(fp_sqrt_raw),
    .fp_minmax_raw_o(fp_minmax_raw),
    .fp_compare_raw_o(fp_compare_raw),
    .fp_convert_to_fpr_raw_o(fp_convert_to_fpr_raw),
    .fp_convert_to_gpr_raw_o(fp_convert_to_gpr_raw),
    .fp_raw_o(fp_raw),
    .fp_double_o(fp_double),
    .fp_gpr_write_o(fp_gpr_write),
    .fp_disabled_o(fp_disabled),
    .fp_enabled_o(fp_enabled),
    .ecall_raw_o(ecall_raw),
    .ebreak_raw_o(ebreak_raw),
    .semihost_ebreak_o(semihost_ebreak),
    .csr_raw_o(csr_raw),
    .mret_raw_o(mret_raw),
    .sret_raw_o(sret_raw),
    .xret_raw_o(xret_raw),
    .wfi_raw_o(wfi_raw),
    .sfence_raw_o(sfence_raw),
    .priv_system_illegal_o(priv_system_illegal),
    .exit_raw_o(exit_raw),
    .system_raw_o(system_raw),
    .arch_trap_raw_o(arch_trap_raw),
    .stop_raw_o(stop_raw),
    .facts_o(facts)
  );

  task automatic check_fact_aliases;
    input [8*48-1:0] prefix;
    begin
      tb_check1({prefix, " facts illegal"}, facts[`OOO_SLOT_FACT_ILLEGAL],
                illegal_raw);
      tb_check1({prefix, " facts branch"}, facts[`OOO_SLOT_FACT_BRANCH],
                branch_raw);
      tb_check1({prefix, " facts jal"}, facts[`OOO_SLOT_FACT_JAL],
                jal_raw);
      tb_check1({prefix, " facts jalr"}, facts[`OOO_SLOT_FACT_JALR],
                jalr_raw);
      tb_check1({prefix, " facts jump"}, facts[`OOO_SLOT_FACT_JUMP],
                jump_raw);
      tb_check1({prefix, " facts mem"}, facts[`OOO_SLOT_FACT_MEM],
                mem_raw);
      tb_check1({prefix, " facts control"}, facts[`OOO_SLOT_FACT_CONTROL],
                control_raw);
      tb_check1({prefix, " facts fp load"}, facts[`OOO_SLOT_FACT_FP_LOAD],
                fp_load_raw);
      tb_check1({prefix, " facts fp store"}, facts[`OOO_SLOT_FACT_FP_STORE],
                fp_store_raw);
      tb_check1({prefix, " facts fp raw"}, facts[`OOO_SLOT_FACT_FP_RAW],
                fp_raw);
      tb_check1({prefix, " facts fp disabled"},
                facts[`OOO_SLOT_FACT_FP_DISABLED], fp_disabled);
      tb_check1({prefix, " facts fp enabled"},
                facts[`OOO_SLOT_FACT_FP_ENABLED], fp_enabled);
      tb_check1({prefix, " facts ecall"}, facts[`OOO_SLOT_FACT_ECALL],
                ecall_raw);
      tb_check1({prefix, " facts ebreak"}, facts[`OOO_SLOT_FACT_EBREAK],
                ebreak_raw);
      tb_check1({prefix, " facts semihost"},
                facts[`OOO_SLOT_FACT_SEMIHOST_EBREAK], semihost_ebreak);
      tb_check1({prefix, " facts csr"}, facts[`OOO_SLOT_FACT_CSR],
                csr_raw);
      tb_check1({prefix, " facts mret"}, facts[`OOO_SLOT_FACT_MRET],
                mret_raw);
      tb_check1({prefix, " facts sret"}, facts[`OOO_SLOT_FACT_SRET],
                sret_raw);
      tb_check1({prefix, " facts xret"}, facts[`OOO_SLOT_FACT_XRET],
                xret_raw);
      tb_check1({prefix, " facts wfi"}, facts[`OOO_SLOT_FACT_WFI],
                wfi_raw);
      tb_check1({prefix, " facts sfence"}, facts[`OOO_SLOT_FACT_SFENCE],
                sfence_raw);
      tb_check1({prefix, " facts priv illegal"},
                facts[`OOO_SLOT_FACT_PRIV_SYSTEM_ILLEGAL],
                priv_system_illegal);
      tb_check1({prefix, " facts exit"}, facts[`OOO_SLOT_FACT_EXIT],
                exit_raw);
      tb_check1({prefix, " facts system"}, facts[`OOO_SLOT_FACT_SYSTEM],
                system_raw);
      tb_check1({prefix, " facts arch trap"},
                facts[`OOO_SLOT_FACT_ARCH_TRAP], arch_trap_raw);
      tb_check1({prefix, " facts stop"}, facts[`OOO_SLOT_FACT_STOP],
                stop_raw);
    end
  endtask

  task automatic reset_inputs;
    begin
      decode_valid = 1'b1;
      fetch_fault = 1'b0;
      inst = INST_ADDI;
      semihost_peer_inst = 32'h0000_0013;
      semihost_peer_is_enter = 1'b0;
      ctrl = {`CTRL_BUS_W{1'b0}};
      // 真实合法指令均 NEED_EXEC=1(不变量 legal⟹need_exec); 默认置位以免误触
      // 新增的 unsupported_residual(ctrl_legal && !NEED_EXEC)。
      ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      priv_mode = `PRIV_M;
      mstatus = `MSTATUS_FS_CLEAN;
      frm = 3'b000;
      #1;
    end
  endtask

  task automatic set_ctrl_bit;
    input integer bit_idx;
    input value;
    begin
      ctrl[bit_idx] = value;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    tb_check1("ordinary alu does not stop", stop_raw, 1'b0);
    tb_check1("ordinary alu no trap", arch_trap_raw, 1'b0);
    check_fact_aliases("ordinary");

    reset_inputs();
    set_ctrl_bit(`CTRL_ILLEGAL_BIT, 1'b1);
    #1;
    tb_check1("base illegal raw", illegal_raw, 1'b1);
    tb_check1("base illegal traps", arch_trap_raw, 1'b1);
    tb_check1("base illegal stops", stop_raw, 1'b1);

    reset_inputs();
    inst = INST_FADD_S;
    set_ctrl_bit(`CTRL_ILLEGAL_BIT, 1'b1);
    #1;
    tb_check1("legal fp masks integer illegal", illegal_raw, 1'b0);
    tb_check1("legal fp raw", fp_raw, 1'b1);
    tb_check1("legal fp enabled", fp_enabled, 1'b1);
    // 【B-FP 簇】FP 迁域 A: fp_raw 不再是 stop 类(普通 dispatch 进 FP 簇)
    tb_check1("legal fp no longer stops (domain-A)", stop_raw, 1'b0);
    check_fact_aliases("fp enabled");

    reset_inputs();
    inst = INST_FADD_S;
    set_ctrl_bit(`CTRL_ILLEGAL_BIT, 1'b1);
    mstatus = {`XLEN{1'b0}};
    #1;
    tb_check1("fs off disables fp", fp_disabled, 1'b1);
    tb_check1("fs off fp traps", arch_trap_raw, 1'b1);

    reset_inputs();
    set_ctrl_bit(`CTRL_CSR_BIT, 1'b1);
    #1;
    tb_check1("csr raw", csr_raw, 1'b1);
    tb_check1("csr system raw", system_raw, 1'b1);
    tb_check1("csr stops", stop_raw, 1'b1);
    check_fact_aliases("csr");

    reset_inputs();
    set_ctrl_bit(`CTRL_ECALL_BIT, 1'b1);
    #1;
    tb_check1("ecall raw", ecall_raw, 1'b1);
    tb_check1("ecall system raw", system_raw, 1'b1);

    reset_inputs();
    inst = INST_EBREAK;
    set_ctrl_bit(`CTRL_EBREAK_BIT, 1'b1);
    #1;
    tb_check1("ordinary ebreak raw", ebreak_raw, 1'b1);
    tb_check1("ordinary ebreak exits", exit_raw, 1'b1);
    tb_check1("ordinary ebreak does not arch trap", arch_trap_raw, 1'b0);

    reset_inputs();
    inst = INST_EBREAK;
    semihost_peer_inst = SEMIHOST_EXIT_INST;
    semihost_peer_is_enter = 1'b0;
    set_ctrl_bit(`CTRL_EBREAK_BIT, 1'b1);
    #1;
    tb_check1("semihost exit recognized", semihost_ebreak, 1'b1);
    tb_check1("semihost exit is not normal exit", exit_raw, 1'b0);
    tb_check1("semihost exit traps", arch_trap_raw, 1'b1);
    check_fact_aliases("semihost");

    reset_inputs();
    inst = INST_EBREAK;
    semihost_peer_inst = SEMIHOST_ENTER_INST;
    semihost_peer_is_enter = 1'b1;
    set_ctrl_bit(`CTRL_EBREAK_BIT, 1'b1);
    #1;
    tb_check1("semihost enter recognized", semihost_ebreak, 1'b1);
    tb_check1("semihost enter traps", arch_trap_raw, 1'b1);

    reset_inputs();
    set_ctrl_bit(`CTRL_MRET_BIT, 1'b1);
    #1;
    tb_check1("mret raw", mret_raw, 1'b1);
    tb_check1("mret xret raw", xret_raw, 1'b1);
    tb_check1("mret system raw", system_raw, 1'b1);

    reset_inputs();
    set_ctrl_bit(`CTRL_SRET_BIT, 1'b1);
    priv_mode = `PRIV_S;
    #1;
    tb_check1("sret raw", sret_raw, 1'b1);
    tb_check1("sret no tsr no trap", arch_trap_raw, 1'b0);
    mstatus = `MSTATUS_FS_CLEAN | `MSTATUS_TSR;
    #1;
    tb_check1("sret under tsr illegal", priv_system_illegal, 1'b1);
    tb_check1("sret under tsr traps", arch_trap_raw, 1'b1);
    check_fact_aliases("sret tsr");

    reset_inputs();
    set_ctrl_bit(`CTRL_SFENCE_VMA_BIT, 1'b1);
    set_ctrl_bit(`CTRL_SFENCE_TVM_BIT, 1'b1);
    priv_mode = `PRIV_U;
    #1;
    tb_check1("u-mode supervisor fence illegal", priv_system_illegal, 1'b1);
    tb_check1("u-mode supervisor fence traps", arch_trap_raw, 1'b1);

    reset_inputs();
    set_ctrl_bit(`CTRL_SFENCE_VMA_BIT, 1'b1);
    set_ctrl_bit(`CTRL_SFENCE_TVM_BIT, 1'b1);
    priv_mode = `PRIV_S;
    mstatus = `MSTATUS_FS_CLEAN | `MSTATUS_TVM;
    #1;
    tb_check1("s-mode tvm address fence illegal", priv_system_illegal, 1'b1);
    tb_check1("s-mode tvm address fence traps", arch_trap_raw, 1'b1);

    reset_inputs();
    set_ctrl_bit(`CTRL_SFENCE_VMA_BIT, 1'b1);
    set_ctrl_bit(`CTRL_SFENCE_TVM_BIT, 1'b0);
    priv_mode = `PRIV_S;
    mstatus = `MSTATUS_FS_CLEAN | `MSTATUS_TVM;
    #1;
    tb_check1("s-mode tvm non-address fence legal", priv_system_illegal, 1'b0);
    tb_check1("s-mode tvm non-address fence no trap", arch_trap_raw, 1'b0);

    reset_inputs();
    fetch_fault = 1'b1;
    set_ctrl_bit(`CTRL_BRANCH_BIT, 1'b1);
    set_ctrl_bit(`CTRL_LOAD_BIT, 1'b1);
    inst = INST_FADD_S;
    #1;
    tb_check1("fetch fault traps", arch_trap_raw, 1'b1);
    tb_check1("fetch fault stops", stop_raw, 1'b1);
    tb_check1("fetch fault suppresses branch", branch_raw, 1'b0);
    tb_check1("fetch fault suppresses mem", mem_raw, 1'b0);
    tb_check1("fetch fault suppresses fp", fp_raw, 1'b0);
    check_fact_aliases("fetch fault");

    // 【§3.1 #4 unsupported-trap-exit】译码合法却 !NEED_EXEC 的残差 → arch_trap 精确出口
    reset_inputs();
    set_ctrl_bit(`CTRL_NEED_EXEC_BIT, 1'b0);
    #1;
    tb_check1("unsupported residual (legal & !need_exec) traps",
              arch_trap_raw, 1'b1);
    tb_check1("unsupported residual stops", stop_raw, 1'b1);

    // 【§3.2 frm-DYN】DYN(rm=111) FP 算术 + frm=保留值(5) → illegal + trap + 不派 FP 簇
    reset_inputs();
    inst = INST_FADD_S_DYN;
    set_ctrl_bit(`CTRL_ILLEGAL_BIT, 1'b1);  // 整数译码器把 FP 判 illegal, fp_raw 掩掉
    frm = 3'b101;
    #1;
    tb_check1("fp dyn reserved frm illegal", illegal_raw, 1'b1);
    tb_check1("fp dyn reserved frm traps", arch_trap_raw, 1'b1);
    tb_check1("fp dyn reserved frm not dispatched to fp", fp_enabled, 1'b0);
    check_fact_aliases("fp dyn frm illegal");

    // 对照: DYN + frm=合法(2) → 正常派 FP, 不 trap
    reset_inputs();
    inst = INST_FADD_S_DYN;
    set_ctrl_bit(`CTRL_ILLEGAL_BIT, 1'b1);
    frm = 3'b010;
    #1;
    tb_check1("fp dyn legal frm not illegal", illegal_raw, 1'b0);
    tb_check1("fp dyn legal frm enabled", fp_enabled, 1'b1);
    tb_check1("fp dyn legal frm no trap", arch_trap_raw, 1'b0);

    // 【§3.2 wfi-TW】mstatus.TW=1 且 priv<M 的 WFI → priv_system_illegal + trap
    reset_inputs();
    set_ctrl_bit(`CTRL_WFI_BIT, 1'b1);
    priv_mode = `PRIV_S;
    mstatus = `MSTATUS_FS_CLEAN | `MSTATUS_TW;
    #1;
    tb_check1("wfi under tw (priv<M) illegal", priv_system_illegal, 1'b1);
    tb_check1("wfi under tw traps", arch_trap_raw, 1'b1);
    // 对照: TW=1 但 M 态 → 合法(M 态 WFI 永不受 TW 约束)
    reset_inputs();
    set_ctrl_bit(`CTRL_WFI_BIT, 1'b1);
    priv_mode = `PRIV_M;
    mstatus = `MSTATUS_FS_CLEAN | `MSTATUS_TW;
    #1;
    tb_check1("wfi under tw in M-mode legal", priv_system_illegal, 1'b0);
    // 对照: TW=0 S 态 → 合法(现有测试全此情形, 零回归)
    reset_inputs();
    set_ctrl_bit(`CTRL_WFI_BIT, 1'b1);
    priv_mode = `PRIV_S;
    mstatus = `MSTATUS_FS_CLEAN;
    #1;
    tb_check1("wfi without tw legal", priv_system_illegal, 1'b0);

    tb_finish("tb_ooo_fetch_head_classify_gate");
  end
endmodule
