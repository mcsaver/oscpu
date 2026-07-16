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
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] static_facts;
  wire [`OOO_SLOT_FACTS_W-1:0] legacy_facts;
  integer diff_i;

  localparam [`INST_W-1:0] INST_ADDI = 32'h0000_0093;
  localparam [`INST_W-1:0] INST_FADD_S = 32'h0020_80d3;
  localparam [`INST_W-1:0] INST_FADD_S_DYN = 32'h0020_f0d3;  // FADD.S 但 rm=DYN(funct3=111)
  localparam [`INST_W-1:0] INST_EBREAK = 32'h0010_0073;
  localparam [`INST_W-1:0] INST_FENCE = 32'h0ff0_000f;
  localparam [`INST_W-1:0] SEMIHOST_ENTER_INST = 32'h01f0_1013;
  localparam [`INST_W-1:0] SEMIHOST_EXIT_INST = 32'h4070_5013;

  OooFetchStaticClassify static_classify (
    .inst_i(inst),
    .semihost_peer_inst_i(semihost_peer_inst),
    .semihost_peer_is_enter_i(semihost_peer_is_enter),
    .static_facts_o(static_facts)
  );

  OooFetchHeadClassifyGate dut (
    .decode_valid_i(decode_valid),
    .fetch_fault_i(fetch_fault),
    .static_facts_i(static_facts),
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

  OooFetchHeadClassifyLegacyRef legacy_ref (
    .decode_valid_i(decode_valid),
    .fetch_fault_i(fetch_fault),
    .inst_i(inst),
    .semihost_peer_inst_i(semihost_peer_inst),
    .semihost_peer_is_enter_i(semihost_peer_is_enter),
    .ctrl_i(ctrl),
    .priv_mode_i(priv_mode),
    .mstatus_i(mstatus),
    .frm_i(frm),
    .facts_o(legacy_facts)
  );

  task automatic check_legacy_equivalence;
    input [8*48-1:0] label;
    begin
      #1;
      if (facts !== legacy_facts) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s new facts=%h legacy facts=%h inst=%h ctrl=%h",
                 label, facts, legacy_facts, inst, ctrl);
      end
    end
  endtask

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

    // T4L：普通 FENCE 不是后端 no-op。它必须进入与其他串行指令共用的
    // pending-system stop 通路，待 drain 完成后才产生一次 ISA retirement。
    reset_inputs();
    inst = INST_FENCE;
    set_ctrl_bit(`CTRL_FENCE_BIT, 1'b1);
    set_ctrl_bit(`CTRL_MISC_MEM_BIT, 1'b1);
    #1;
    tb_check1("ordinary fence is system boundary", system_raw, 1'b1);
    tb_check1("ordinary fence stops younger dispatch", stop_raw, 1'b1);
    tb_check1("ordinary fence remains legal", arch_trap_raw, 1'b0);
    tb_check1("ordinary fence system fact",
              facts[`OOO_SLOT_FACT_SYSTEM], 1'b1);
    tb_check1("ordinary fence stop fact",
              facts[`OOO_SLOT_FACT_STOP], 1'b1);

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
    tb_check1("mret in M-mode raw", mret_raw, 1'b1);
    tb_check1("mret in M-mode xret raw", xret_raw, 1'b1);
    tb_check1("mret in M-mode system raw", system_raw, 1'b1);
    tb_check1("mret in M-mode legal", priv_system_illegal, 1'b0);
    tb_check1("mret in M-mode no trap", arch_trap_raw, 1'b0);

    // XRET-G1：MRET 只能从 M-mode 执行；raw fact 仍保留，但必须改走 illegal trap。
    reset_inputs();
    set_ctrl_bit(`CTRL_MRET_BIT, 1'b1);
    priv_mode = `PRIV_S;
    #1;
    tb_check1("mret in S-mode remains classified", mret_raw, 1'b1);
    tb_check1("mret in S-mode illegal", priv_system_illegal, 1'b1);
    tb_check1("mret in S-mode traps", arch_trap_raw, 1'b1);
    tb_check1("mret in S-mode stops", stop_raw, 1'b1);

    reset_inputs();
    set_ctrl_bit(`CTRL_MRET_BIT, 1'b1);
    priv_mode = `PRIV_U;
    #1;
    tb_check1("mret in U-mode remains classified", mret_raw, 1'b1);
    tb_check1("mret in U-mode illegal", priv_system_illegal, 1'b1);
    tb_check1("mret in U-mode traps", arch_trap_raw, 1'b1);

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

    // XRET-G1：SRET 可从 S 或更高特权执行，但 U-mode 必须 illegal。
    reset_inputs();
    set_ctrl_bit(`CTRL_SRET_BIT, 1'b1);
    priv_mode = `PRIV_U;
    #1;
    tb_check1("sret in U-mode remains classified", sret_raw, 1'b1);
    tb_check1("sret in U-mode illegal", priv_system_illegal, 1'b1);
    tb_check1("sret in U-mode traps", arch_trap_raw, 1'b1);
    tb_check1("sret in U-mode stops", stop_raw, 1'b1);

    // TSR 只拦截 S-mode；M-mode 执行 SRET 时即使 TSR=1 也合法。
    reset_inputs();
    set_ctrl_bit(`CTRL_SRET_BIT, 1'b1);
    priv_mode = `PRIV_M;
    mstatus = `MSTATUS_FS_CLEAN | `MSTATUS_TSR;
    #1;
    tb_check1("sret in M-mode ignores tsr", priv_system_illegal, 1'b0);
    tb_check1("sret in M-mode with tsr no trap", arch_trap_raw, 1'b0);

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

    // T3W compatibility boundary: fp_double remains raw even when visibility
    // is suppressed, while all 42 facts stay legacy-identical.
    reset_inputs();
    inst = {7'b0000001, 5'd3, 5'd2, 3'b000, 5'd1, `OPCODE_OP_FP};
    decode_valid = 1'b0;
    check_legacy_equivalence("invalid head preserves raw fp_double ABI");
    tb_check1("invalid double retains fp_double", fp_double, 1'b1);

    for (diff_i = 0; diff_i < 1000; diff_i = diff_i + 1) begin
      decode_valid = $urandom_range(0, 1);
      fetch_fault = $urandom_range(0, 1);
      inst = $urandom;
      semihost_peer_inst = $urandom;
      semihost_peer_is_enter = $urandom_range(0, 1);
      ctrl = {$urandom, $urandom, $urandom, $urandom};
      priv_mode = $urandom;
      mstatus = {$urandom, $urandom};
      frm = $urandom;
      check_legacy_equivalence("random 42-bit legacy differential");
    end

    tb_finish("tb_ooo_fetch_head_classify_gate");
  end
endmodule

// Frozen pre-T3W reference.  It deliberately decodes the raw instruction at
// head time so the DUT's stored-static implementation can be checked bit for
// bit across the entire 42-bit public facts bus.
module OooFetchHeadClassifyLegacyRef (
  input decode_valid_i,
  input fetch_fault_i,
  input [`INST_W-1:0] inst_i,
  input [`INST_W-1:0] semihost_peer_inst_i,
  input semihost_peer_is_enter_i,
  input [`CTRL_BUS_W-1:0] ctrl_i,
  input [1:0] priv_mode_i,
  input [`XLEN-1:0] mstatus_i,
  input [2:0] frm_i,
  output [`OOO_SLOT_FACTS_W-1:0] facts_o
);
  localparam [`INST_W-1:0] SEMIHOST_ENTER_INST = 32'h01f0_1013;
  localparam [`INST_W-1:0] SEMIHOST_EXIT_INST  = 32'h4070_5013;

  wire decode_ok = decode_valid_i && !fetch_fault_i;
  wire decode_illegal = decode_ok && ctrl_i[`CTRL_ILLEGAL_BIT];
  wire ctrl_legal = decode_ok && !ctrl_i[`CTRL_ILLEGAL_BIT];
  wire unsupported_residual = ctrl_legal && !ctrl_i[`CTRL_NEED_EXEC_BIT];
  wire fp_load;
  wire fp_store;
  wire fp_move_to_fpr;
  wire fp_move_to_gpr;
  wire fp_class;
  wire fp_sgnj;
  wire fp_addsub;
  wire fp_mul;
  wire fp_fma;
  wire fp_div;
  wire fp_sqrt;
  wire fp_minmax;
  wire fp_compare;
  wire fp_convert_to_fpr;
  wire fp_convert_to_gpr;
  wire fp_raw;
  wire fp_double;
  wire fp_gpr_write;

  OooFpDecode fp_decode (
    .decode_valid_i(decode_ok), .inst_i(inst_i),
    .fp_load_o(fp_load), .fp_store_o(fp_store),
    .fp_move_to_fpr_o(fp_move_to_fpr),
    .fp_move_to_gpr_o(fp_move_to_gpr), .fp_class_o(fp_class),
    .fp_sgnj_o(fp_sgnj), .fp_addsub_o(fp_addsub), .fp_mul_o(fp_mul),
    .fp_fma_o(fp_fma), .fp_div_o(fp_div), .fp_sqrt_o(fp_sqrt),
    .fp_minmax_o(fp_minmax), .fp_compare_o(fp_compare),
    .fp_convert_to_fpr_o(fp_convert_to_fpr),
    .fp_convert_to_gpr_o(fp_convert_to_gpr), .fp_o(fp_raw),
    .fp_double_o(fp_double), .fp_gpr_write_o(fp_gpr_write)
  );

  wire fp_dyn_rm_bearing =
      fp_addsub || fp_mul || fp_fma || fp_div || fp_sqrt ||
      fp_convert_to_fpr || fp_convert_to_gpr;
  wire fp_dyn_frm_illegal =
      fp_dyn_rm_bearing && (inst_i[14:12] == 3'b111) &&
      ((frm_i == 3'b101) || (frm_i == 3'b110) || (frm_i == 3'b111));
  wire illegal_raw = (decode_illegal && !fp_raw) || fp_dyn_frm_illegal;
  wire branch_raw = ctrl_legal && ctrl_i[`CTRL_BRANCH_BIT];
  wire jal_raw = ctrl_legal && ctrl_i[`CTRL_JAL_BIT];
  wire jalr_raw = ctrl_legal && ctrl_i[`CTRL_JALR_BIT];
  wire jump_raw = jal_raw || jalr_raw;
  wire mem_raw = ctrl_legal &&
                 (ctrl_i[`CTRL_LOAD_BIT] || ctrl_i[`CTRL_STORE_BIT]);
  wire control_raw = branch_raw || jal_raw || jalr_raw;
  wire ecall_raw = ctrl_legal && ctrl_i[`CTRL_ECALL_BIT];
  wire ebreak_raw = ctrl_legal && ctrl_i[`CTRL_EBREAK_BIT];
  wire semihost_ebreak =
      ebreak_raw && (semihost_peer_is_enter_i ?
          (semihost_peer_inst_i == SEMIHOST_ENTER_INST) :
          (semihost_peer_inst_i == SEMIHOST_EXIT_INST));
  wire csr_raw = ctrl_legal && ctrl_i[`CTRL_CSR_BIT];
  wire mret_raw = ctrl_legal && ctrl_i[`CTRL_MRET_BIT];
  wire sret_raw = ctrl_legal && ctrl_i[`CTRL_SRET_BIT];
  wire xret_raw = mret_raw || sret_raw;
  wire wfi_raw = ctrl_legal && ctrl_i[`CTRL_WFI_BIT];
  wire sfence_raw = ctrl_legal && ctrl_i[`CTRL_SFENCE_VMA_BIT];
  wire fencei_raw = ctrl_legal && ctrl_i[`CTRL_FENCEI_BIT];
  // T4L is an intentional public-facts contract extension; keep the frozen
  // implementation reference aligned only for this newly specified class.
  wire fence_raw = ctrl_legal && ctrl_i[`CTRL_FENCE_BIT] && !fencei_raw;
  wire sfence_u_illegal = sfence_raw && (priv_mode_i == `PRIV_U);
  wire sfence_tvm_illegal =
      sfence_raw && ctrl_i[`CTRL_SFENCE_TVM_BIT] &&
      (priv_mode_i == `PRIV_S) &&
      ((mstatus_i & `MSTATUS_TVM) != {`XLEN{1'b0}});
  wire mret_mode_illegal = mret_raw && (priv_mode_i != `PRIV_M);
  wire sret_mode_illegal = sret_raw && (priv_mode_i == `PRIV_U);
  wire sret_tsr_illegal =
      sret_raw && (priv_mode_i == `PRIV_S) &&
      ((mstatus_i & `MSTATUS_TSR) != {`XLEN{1'b0}});
  wire wfi_tw_illegal =
      wfi_raw && (priv_mode_i != `PRIV_M) &&
      ((mstatus_i & `MSTATUS_TW) != {`XLEN{1'b0}});
  wire priv_system_illegal =
      sfence_u_illegal || sfence_tvm_illegal || mret_mode_illegal ||
      sret_mode_illegal || sret_tsr_illegal || wfi_tw_illegal;
  wire exit_raw = ebreak_raw && !semihost_ebreak;
  wire system_raw =
      ecall_raw || csr_raw || xret_raw || wfi_raw || sfence_raw ||
      fencei_raw || fence_raw;
  wire fp_disabled =
      fp_raw && ((mstatus_i & `MSTATUS_FS_MASK) == {`XLEN{1'b0}});
  wire fp_enabled = fp_raw && !fp_disabled && !fp_dyn_frm_illegal;
  wire arch_trap_raw =
      fetch_fault_i || illegal_raw || semihost_ebreak || fp_disabled ||
      priv_system_illegal || unsupported_residual;
  wire stop_raw =
      fetch_fault_i || exit_raw || system_raw || arch_trap_raw;

  assign facts_o[`OOO_SLOT_FACT_ILLEGAL] = illegal_raw;
  assign facts_o[`OOO_SLOT_FACT_BRANCH] = branch_raw;
  assign facts_o[`OOO_SLOT_FACT_JAL] = jal_raw;
  assign facts_o[`OOO_SLOT_FACT_JALR] = jalr_raw;
  assign facts_o[`OOO_SLOT_FACT_JUMP] = jump_raw;
  assign facts_o[`OOO_SLOT_FACT_MEM] = mem_raw;
  assign facts_o[`OOO_SLOT_FACT_CONTROL] = control_raw;
  assign facts_o[`OOO_SLOT_FACT_FP_LOAD] = fp_load;
  assign facts_o[`OOO_SLOT_FACT_FP_STORE] = fp_store;
  assign facts_o[`OOO_SLOT_FACT_FP_MOVE_TO_FPR] = fp_move_to_fpr;
  assign facts_o[`OOO_SLOT_FACT_FP_MOVE_TO_GPR] = fp_move_to_gpr;
  assign facts_o[`OOO_SLOT_FACT_FP_CLASS] = fp_class;
  assign facts_o[`OOO_SLOT_FACT_FP_SGNJ] = fp_sgnj;
  assign facts_o[`OOO_SLOT_FACT_FP_ADDSUB] = fp_addsub;
  assign facts_o[`OOO_SLOT_FACT_FP_MUL] = fp_mul;
  assign facts_o[`OOO_SLOT_FACT_FP_FMA] = fp_fma;
  assign facts_o[`OOO_SLOT_FACT_FP_DIV] = fp_div;
  assign facts_o[`OOO_SLOT_FACT_FP_SQRT] = fp_sqrt;
  assign facts_o[`OOO_SLOT_FACT_FP_MINMAX] = fp_minmax;
  assign facts_o[`OOO_SLOT_FACT_FP_COMPARE] = fp_compare;
  assign facts_o[`OOO_SLOT_FACT_FP_CONVERT_TO_FPR] = fp_convert_to_fpr;
  assign facts_o[`OOO_SLOT_FACT_FP_CONVERT_TO_GPR] = fp_convert_to_gpr;
  assign facts_o[`OOO_SLOT_FACT_FP_RAW] = fp_raw;
  assign facts_o[`OOO_SLOT_FACT_FP_DOUBLE] = fp_double;
  assign facts_o[`OOO_SLOT_FACT_FP_GPR_WRITE] = fp_gpr_write;
  assign facts_o[`OOO_SLOT_FACT_FP_DISABLED] = fp_disabled;
  assign facts_o[`OOO_SLOT_FACT_FP_ENABLED] = fp_enabled;
  assign facts_o[`OOO_SLOT_FACT_ECALL] = ecall_raw;
  assign facts_o[`OOO_SLOT_FACT_EBREAK] = ebreak_raw;
  assign facts_o[`OOO_SLOT_FACT_SEMIHOST_EBREAK] = semihost_ebreak;
  assign facts_o[`OOO_SLOT_FACT_CSR] = csr_raw;
  assign facts_o[`OOO_SLOT_FACT_MRET] = mret_raw;
  assign facts_o[`OOO_SLOT_FACT_SRET] = sret_raw;
  assign facts_o[`OOO_SLOT_FACT_XRET] = xret_raw;
  assign facts_o[`OOO_SLOT_FACT_WFI] = wfi_raw;
  assign facts_o[`OOO_SLOT_FACT_SFENCE] = sfence_raw;
  assign facts_o[`OOO_SLOT_FACT_PRIV_SYSTEM_ILLEGAL] = priv_system_illegal;
  assign facts_o[`OOO_SLOT_FACT_EXIT] = exit_raw;
  assign facts_o[`OOO_SLOT_FACT_SYSTEM] = system_raw;
  assign facts_o[`OOO_SLOT_FACT_ARCH_TRAP] = arch_trap_raw;
  assign facts_o[`OOO_SLOT_FACT_STOP] = stop_raw;
  assign facts_o[`OOO_SLOT_FACT_FENCEI] = fencei_raw;
endmodule
