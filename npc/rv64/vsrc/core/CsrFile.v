`include "define.v"

// CSRFile 收口特权级、CSR 读改写、trap/xRET 副作用。Linux 早期启动需要 S-mode
// 控制面，因此这里把 M/S 两级状态放在同一个精确提交边界内维护。
module CsrFile (
  input clk,
  input rst,

  input cycle_count_enable_i,
  input [`XLEN-1:0] time_i,
  input [1:0] instret_inc_i,

  input csr_valid_i,
  input [11:0] csr_addr_i,
  input [2:0] csr_funct3_i,
  input [`REG_ADDR_W-1:0] csr_rs1_idx_i,
  input [`XLEN-1:0] csr_rs1_data_i,
  input [4:0] csr_zimm_i,
  input csr_commit_i,
  output [`XLEN-1:0] csr_rdata_o,
  output csr_illegal_o,

  input fp_fflags_valid_i,
  input [4:0] fp_fflags_i,
  input fp_dirty_i,  // F8：FP 写 FPR 或更新 fcsr 的提交脉冲（置 mstatus.FS=Dirty）

  input trap_mem_valid_i,
  input [`XLEN-1:0] trap_mem_pc_i,
  input [`TRAP_CAUSE_W-1:0] trap_mem_cause_i,
  input [`XLEN-1:0] trap_mem_tval_i,

  input trap_ex_valid_i,
  input [`XLEN-1:0] trap_ex_pc_i,
  input [`TRAP_CAUSE_W-1:0] trap_ex_cause_i,
  input [`XLEN-1:0] trap_ex_tval_i,

  input irq_software_i,
  input irq_timer_i,
  input irq_external_i,
  output irq_pending_o,
  output [`TRAP_CAUSE_W-1:0] irq_cause_o,

  input trap_irq_valid_i,
  input [`XLEN-1:0] trap_irq_pc_i,
  input [`TRAP_CAUSE_W-1:0] trap_irq_cause_i,
  input mret_valid_i,
  input sret_valid_i,
  output [`XLEN-1:0] trap_target_o,
  output [`XLEN-1:0] mepc_o,
  output [`XLEN-1:0] ret_target_o,
  output [1:0] priv_mode_o,
  output [`TRAP_CAUSE_W-1:0] ecall_cause_o,
  output [`XLEN-1:0] mstatus_o,
  output [`XLEN-1:0] satp_o,
  output svpbmt_en_o,
  output [2:0] frm_o,  // FP#1: fcsr.frm 供 FP datapath 做 DYN 舍入
  output [`PMP_CFG_BUS_W-1:0] pmpcfg_o,
  output [`PMP_ADDR_BUS_W-1:0] pmpaddr_o
);

  localparam [`XLEN-1:0] MSTATUS_WRITABLE_MASK =
      `MSTATUS_SIE | `MSTATUS_MIE | `MSTATUS_SPIE | `MSTATUS_MPIE |
      `MSTATUS_SPP | `MSTATUS_FS_MASK | `MSTATUS_MPP_MASK | `MSTATUS_MPRV |
      `MSTATUS_SUM | `MSTATUS_MXR | `MSTATUS_TVM | `MSTATUS_TW |
      `MSTATUS_TSR;
  localparam [`XLEN-1:0] SSTATUS_WRITABLE_MASK =
      `MSTATUS_SIE | `MSTATUS_SPIE | `MSTATUS_SPP | `MSTATUS_FS_MASK |
      `MSTATUS_SUM | `MSTATUS_MXR;
  localparam [`XLEN-1:0] SUPERVISOR_INT_MASK =
      `MIE_SSIE | `MIE_STIE | `MIE_SEIE;
  localparam [`XLEN-1:0] MACHINE_INT_MASK =
      `MIE_MSIE | `MIE_MTIE | `MIE_MEIE;
  localparam [`XLEN-1:0] CSR_MISA_VALUE =
      64'h8000_0000_0014_1105 | (64'd1 << 3) | (64'd1 << 5);
  localparam [`XLEN-1:0] EPC_WARL_MASK =
      {{(`XLEN-1){1'b1}}, 1'b0};
  localparam [`XLEN-1:0] CSR_TSELECT_NO_TRIGGER_VALUE =
      {{(`XLEN-1){1'b0}}, 1'b1};
  localparam [`XLEN-1:0] MENVCFG_WRITABLE_MASK = `MENVCFG_PBMTE;
  localparam [`XLEN-1:0] PMPADDR_WRITABLE_MASK = `PMP_ADDR_MASK;
  localparam integer PMP_CFG_CSR_COUNT = 2;
  localparam integer PMP_ADDR_COUNT = 16;

  function csr_counter;
    input [11:0] csr_addr;
    begin
      case (csr_addr)
        `CSR_CYCLE,
        `CSR_TIME,
        `CSR_INSTRET,
        `CSR_CYCLEH,
        `CSR_TIMEH,
        `CSR_INSTRETH: csr_counter = 1'b1;
        default:       csr_counter = 1'b0;
      endcase
    end
  endfunction

  function [`XLEN-1:0] csr_counter_bit;
    input [11:0] csr_addr;
    begin
      case (csr_addr)
        `CSR_CYCLE,
        `CSR_CYCLEH:   csr_counter_bit = `COUNTEREN_CY;
        `CSR_TIME,
        `CSR_TIMEH:    csr_counter_bit = `COUNTEREN_TM;
        `CSR_INSTRET,
        `CSR_INSTRETH: csr_counter_bit = `COUNTEREN_IR;
        default:       csr_counter_bit = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function [1:0] mpp_to_priv;
    input [`XLEN-1:0] status;
    begin
      case (status & `MSTATUS_MPP_MASK)
        `MSTATUS_MPP_S: mpp_to_priv = `PRIV_S;
        `MSTATUS_MPP_M: mpp_to_priv = `PRIV_M;
        default:        mpp_to_priv = `PRIV_U;
      endcase
    end
  endfunction

  function [`XLEN-1:0] encode_mpp;
    input [1:0] mode;
    begin
      case (mode)
        `PRIV_S: encode_mpp = `MSTATUS_MPP_S;
        `PRIV_M: encode_mpp = `MSTATUS_MPP_M;
        default: encode_mpp = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function [`XLEN-1:0] trap_to_m_mstatus;
    input [`XLEN-1:0] old_status;
    input [1:0] from_mode;
    begin
      trap_to_m_mstatus = old_status;
      if ((old_status & `MSTATUS_MIE) != {`XLEN{1'b0}})
        trap_to_m_mstatus = trap_to_m_mstatus | `MSTATUS_MPIE;
      else
        trap_to_m_mstatus = trap_to_m_mstatus & ~`MSTATUS_MPIE;
      trap_to_m_mstatus = trap_to_m_mstatus & ~`MSTATUS_MIE;
      trap_to_m_mstatus =
          (trap_to_m_mstatus & ~`MSTATUS_MPP_MASK) | encode_mpp(from_mode);
      trap_to_m_mstatus = trap_to_m_mstatus | `MSTATUS_SXL_UXL;
    end
  endfunction

  function [`XLEN-1:0] trap_to_s_mstatus;
    input [`XLEN-1:0] old_status;
    input [1:0] from_mode;
    begin
      trap_to_s_mstatus = old_status;
      if ((old_status & `MSTATUS_SIE) != {`XLEN{1'b0}})
        trap_to_s_mstatus = trap_to_s_mstatus | `MSTATUS_SPIE;
      else
        trap_to_s_mstatus = trap_to_s_mstatus & ~`MSTATUS_SPIE;
      trap_to_s_mstatus = trap_to_s_mstatus & ~`MSTATUS_SIE;
      if (from_mode == `PRIV_S)
        trap_to_s_mstatus = trap_to_s_mstatus | `MSTATUS_SPP;
      else
        trap_to_s_mstatus = trap_to_s_mstatus & ~`MSTATUS_SPP;
      trap_to_s_mstatus = trap_to_s_mstatus | `MSTATUS_SXL_UXL;
    end
  endfunction

  function [`XLEN-1:0] mret_mstatus;
    input [`XLEN-1:0] old_status;
    input [1:0] next_mode;
    begin
      mret_mstatus = old_status;
      if ((old_status & `MSTATUS_MPIE) != {`XLEN{1'b0}})
        mret_mstatus = mret_mstatus | `MSTATUS_MIE;
      else
        mret_mstatus = mret_mstatus & ~`MSTATUS_MIE;
      mret_mstatus = mret_mstatus | `MSTATUS_MPIE;
      mret_mstatus = mret_mstatus & ~`MSTATUS_MPP_MASK;
      if (next_mode != `PRIV_M)
        mret_mstatus = mret_mstatus & ~`MSTATUS_MPRV;
      mret_mstatus = mret_mstatus | `MSTATUS_SXL_UXL;
    end
  endfunction

  function [`XLEN-1:0] sret_mstatus;
    input [`XLEN-1:0] old_status;
    begin
      sret_mstatus = old_status;
      if ((old_status & `MSTATUS_SPIE) != {`XLEN{1'b0}})
        sret_mstatus = sret_mstatus | `MSTATUS_SIE;
      else
        sret_mstatus = sret_mstatus & ~`MSTATUS_SIE;
      sret_mstatus = sret_mstatus | `MSTATUS_SPIE;
      sret_mstatus = sret_mstatus & ~`MSTATUS_SPP;
      sret_mstatus = sret_mstatus | `MSTATUS_SXL_UXL;
    end
  endfunction

  function csr_pmpcfg_known;
    input [11:0] csr_addr;
    begin
      // RV64 only implements even pmpcfg CSRs; odd pmpcfg CSRs are illegal.
      csr_pmpcfg_known = (csr_addr == `CSR_PMPCFG0) || (csr_addr == `CSR_PMPCFG2);
    end
  endfunction

  function csr_pmpcfg_storage;
    input [11:0] csr_addr;
    begin
      csr_pmpcfg_storage = csr_pmpcfg_known(csr_addr) && (csr_addr[0] == 1'b0);
    end
  endfunction

  function [0:0] csr_pmpcfg_idx;
    input [11:0] csr_addr;
    begin
      csr_pmpcfg_idx = csr_addr[1];
    end
  endfunction

  function csr_pmpaddr_known;
    input [11:0] csr_addr;
    begin
      csr_pmpaddr_known = (csr_addr >= `CSR_PMPADDR0) && (csr_addr <= `CSR_PMPADDR15);
    end
  endfunction

  function [3:0] csr_pmpaddr_idx;
    input [11:0] csr_addr;
    begin
      csr_pmpaddr_idx = csr_addr[3:0];
    end
  endfunction

  function [`PMP_CFG_ENTRY_W-1:0] pmpcfg_entry_value;
    input integer entry_idx;
    begin
      pmpcfg_entry_value =
          csr_pmpcfg_q[entry_idx / 8]
                      [(entry_idx % 8) * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W];
    end
  endfunction

  function pmp_entry_locked;
    input integer entry_idx;
    reg [`PMP_CFG_ENTRY_W-1:0] cfg;
    begin
      cfg = pmpcfg_entry_value(entry_idx);
      pmp_entry_locked = cfg[`PMP_CFG_L];
    end
  endfunction

  function pmp_entry_tor;
    input integer entry_idx;
    reg [`PMP_CFG_ENTRY_W-1:0] cfg;
    begin
      cfg = pmpcfg_entry_value(entry_idx);
      pmp_entry_tor = cfg[`PMP_CFG_A_HI:`PMP_CFG_A_LO] == `PMP_A_TOR;
    end
  endfunction

  function pmpaddr_locked;
    input [3:0] entry_idx;
    begin
      pmpaddr_locked = pmp_entry_locked(entry_idx);
      if (entry_idx != 4'd15)
        pmpaddr_locked = pmpaddr_locked ||
                         (pmp_entry_locked(entry_idx + 1) &&
                          pmp_entry_tor(entry_idx + 1));
    end
  endfunction

  function [`PMP_CFG_ENTRY_W-1:0] sanitize_pmpcfg_entry;
    input [`PMP_CFG_ENTRY_W-1:0] cfg;
    reg [`PMP_CFG_ENTRY_W-1:0] clean_cfg;
    begin
      clean_cfg = cfg;
      clean_cfg[6:5] = 2'b00;
      if (cfg[`PMP_CFG_W] && !cfg[`PMP_CFG_R])
        clean_cfg[`PMP_CFG_X:`PMP_CFG_R] = 3'b000;
      sanitize_pmpcfg_entry = clean_cfg;
    end
  endfunction

  function [`XLEN-1:0] apply_pmpcfg_lock;
    input [`XLEN-1:0] old_cfg;
    input [`XLEN-1:0] new_cfg;
    integer cfg_entry_idx;
    reg [`PMP_CFG_ENTRY_W-1:0] old_entry_cfg;
    begin
      apply_pmpcfg_lock = old_cfg;
      for (cfg_entry_idx = 0; cfg_entry_idx < 8; cfg_entry_idx = cfg_entry_idx + 1) begin
        old_entry_cfg =
            old_cfg[cfg_entry_idx * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W];
        if (!old_entry_cfg[`PMP_CFG_L])
          apply_pmpcfg_lock[cfg_entry_idx * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W] =
              sanitize_pmpcfg_entry(
                  new_cfg[cfg_entry_idx * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W]);
      end
    end
  endfunction

  // CSR 合法性 decode 由下方两个 always @(*) 组合块算出(纯组合)
  reg csr_known_r, csr_writable_r;
  always @(*) begin : csr_writable_blk
    reg [11:0] csr_addr;
    begin
      csr_addr = csr_addr_i;
      csr_writable_r = 0;
      case (csr_addr)
        `CSR_FFLAGS,
        `CSR_FRM,
        `CSR_FCSR,
        `CSR_SSTATUS,
        `CSR_SIE,
        `CSR_STVEC,
        `CSR_SSCRATCH,
        `CSR_SEPC,
        `CSR_SCAUSE,
        `CSR_STVAL,
        `CSR_SIP,
        `CSR_SCOUNTEREN,
        `CSR_SATP,
        `CSR_MSTATUS,
        `CSR_MISA,
        `CSR_MEDELEG,
        `CSR_MIDELEG,
        `CSR_MIE,
        `CSR_MTVEC,
        `CSR_MCOUNTEREN,
        `CSR_MCOUNTINHIBIT,
        `CSR_MENVCFG,
        `CSR_PMPCFG0,
        `CSR_MSCRATCH,
        `CSR_MEPC,
        `CSR_MCAUSE,
        `CSR_MTVAL,
        `CSR_MIP,
        `CSR_PMPADDR0,
        `CSR_MCYCLE,
        `CSR_MINSTRET,
        `CSR_MNSTATUS,
        `CSR_TSELECT,
        `CSR_TDATA1,
        `CSR_TDATA2,
        `CSR_TCONTROL: csr_writable_r = 1'b1;
        default:      csr_writable_r = csr_pmpcfg_known(csr_addr) ||
                                      csr_pmpaddr_known(csr_addr);
      endcase
    end
  end

  always @(*) begin : csr_known_blk
    reg [11:0] csr_addr;
    begin
      csr_addr = csr_addr_i;
      csr_known_r = 0;
      case (csr_addr)
        `CSR_FFLAGS,
        `CSR_FRM,
        `CSR_FCSR,
        `CSR_MVENDORID,
        `CSR_MARCHID,
        `CSR_MIMPID,
        `CSR_SSTATUS,
        `CSR_SIE,
        `CSR_STVEC,
        `CSR_SSCRATCH,
        `CSR_SEPC,
        `CSR_SCAUSE,
        `CSR_STVAL,
        `CSR_SIP,
        `CSR_SCOUNTEREN,
        `CSR_SATP,
        `CSR_MSTATUS,
        `CSR_MISA,
        `CSR_MEDELEG,
        `CSR_MIDELEG,
        `CSR_MIE,
        `CSR_MTVEC,
        `CSR_MCOUNTEREN,
        `CSR_MCOUNTINHIBIT,
        `CSR_MENVCFG,
        `CSR_PMPCFG0,
        `CSR_MSCRATCH,
        `CSR_MEPC,
        `CSR_MCAUSE,
        `CSR_MTVAL,
        `CSR_MIP,
        `CSR_PMPADDR0,
        `CSR_MCYCLE,
        `CSR_MINSTRET,
        `CSR_MNSTATUS,
        `CSR_TSELECT,
        `CSR_TDATA1,
        `CSR_TDATA2,
        `CSR_TCONTROL,
        `CSR_CYCLE,
        `CSR_TIME,
        `CSR_INSTRET,
        // RV64 下 cycleh/timeh/instreth/mcycleh/minstreth 不存在（XLEN=64 计数器无高半
        // 镜像）；访问应触发 illegal-instruction。从 known 列表移除 → 落 default →
        // csr_illegal_o 拉高，与金标 NEMU(RV64) 一致。
        `CSR_MHARTID: csr_known_r = 1'b1;
        default:      csr_known_r = csr_pmpcfg_known(csr_addr) ||
                                  csr_pmpaddr_known(csr_addr);
      endcase
    end
  end

  function [`XLEN-1:0] sanitize_satp;
    input [`XLEN-1:0] value;
    begin
      case (value[63:60])
        4'h0,
        4'h8: sanitize_satp = value;
        default: sanitize_satp = {`XLEN{1'b0}};
      endcase
    end
  endfunction

  function [`XLEN-1:0] epc_warl_value;
    input [`XLEN-1:0] value;
    begin
      epc_warl_value = value & EPC_WARL_MASK;
    end
  endfunction

  reg [1:0] priv_mode_q;
  reg [`XLEN-1:0] csr_mstatus_q;
  reg [`XLEN-1:0] csr_medeleg_q;
  reg [`XLEN-1:0] csr_mideleg_q;
  reg [`XLEN-1:0] csr_mtvec_q;
  reg [`XLEN-1:0] csr_stvec_q;
  reg [`XLEN-1:0] csr_mscratch_q;
  reg [`XLEN-1:0] csr_sscratch_q;
  reg [`XLEN-1:0] csr_mepc_q;
  reg [`XLEN-1:0] csr_sepc_q;
  reg [`XLEN-1:0] csr_mcause_q;
  reg [`XLEN-1:0] csr_scause_q;
  reg [`XLEN-1:0] csr_mtval_q;
  reg [`XLEN-1:0] csr_stval_q;
  reg [`XLEN-1:0] csr_mie_q;
  reg [`XLEN-1:0] csr_mip_q;
  reg [`XLEN-1:0] csr_satp_q;
  reg [63:0] csr_mcycle_q;
  reg [63:0] csr_minstret_q;
  reg [`XLEN-1:0] csr_mcounteren_q;
  reg [`XLEN-1:0] csr_scounteren_q;
  reg [`XLEN-1:0] csr_mcountinhibit_q;
  reg [`XLEN-1:0] csr_menvcfg_q;
  reg [`XLEN-1:0] csr_pmpcfg_q [0:PMP_CFG_CSR_COUNT-1];
  reg [`XLEN-1:0] csr_pmpaddr_q [0:PMP_ADDR_COUNT-1];
  reg [4:0] csr_fflags_q;
  reg [2:0] csr_frm_q;
  integer pmp_reset_idx;

  wire csr_imm_op_w = csr_funct3_i[2];
  wire [`XLEN-1:0] csr_zimm_w = {{(`XLEN-5){1'b0}}, csr_zimm_i};
  wire [`XLEN-1:0] csr_src_w = csr_imm_op_w ? csr_zimm_w : csr_rs1_data_i;
  wire csr_set_clear_noop_w = ((csr_funct3_i == 3'b010) || (csr_funct3_i == 3'b011) ||
                               (csr_funct3_i == 3'b110) || (csr_funct3_i == 3'b111)) &&
                              (csr_rs1_idx_i == {`REG_ADDR_W{1'b0}});
  wire csr_need_write_w = csr_valid_i && ((csr_funct3_i == 3'b001) ||
                                          (csr_funct3_i == 3'b101) ||
                                          ~csr_set_clear_noop_w);
  wire csr_priv_ok_w = (priv_mode_q >= csr_addr_i[9:8]);
  wire csr_satp_tvm_illegal_w =
      csr_valid_i && (csr_addr_i == `CSR_SATP) &&
      (priv_mode_q == `PRIV_S) &&
      ((csr_mstatus_q & `MSTATUS_TVM) != {`XLEN{1'b0}});
  wire mcycle_inhibit_w = (csr_mcountinhibit_q & `MCOUNTINHIBIT_CY) != {`XLEN{1'b0}};
  wire minstret_inhibit_w = (csr_mcountinhibit_q & `MCOUNTINHIBIT_IR) != {`XLEN{1'b0}};
  wire csr_counter_m_allowed_w =
      (csr_mcounteren_q & csr_counter_bit(csr_addr_i)) != {`XLEN{1'b0}};
  wire csr_counter_s_allowed_w =
      (csr_scounteren_q & csr_counter_bit(csr_addr_i)) != {`XLEN{1'b0}};
  wire csr_counter_allowed_w =
      !csr_counter(csr_addr_i) ||
      (priv_mode_q == `PRIV_M) ||
      ((priv_mode_q == `PRIV_S) && csr_counter_m_allowed_w) ||
      ((priv_mode_q == `PRIV_U) && csr_counter_m_allowed_w && csr_counter_s_allowed_w);
  wire csr_pmpcfg_known_w = csr_pmpcfg_known(csr_addr_i);
  wire csr_pmpcfg_storage_w = csr_pmpcfg_storage(csr_addr_i);
  wire [0:0] csr_pmpcfg_idx_w = csr_pmpcfg_idx(csr_addr_i);
  wire csr_pmpaddr_known_w = csr_pmpaddr_known(csr_addr_i);
  wire [3:0] csr_pmpaddr_idx_w = csr_pmpaddr_idx(csr_addr_i);
  wire [`XLEN-1:0] csr_pmpcfg_rdata_w =
      csr_pmpcfg_storage_w ? csr_pmpcfg_q[csr_pmpcfg_idx_w] : {`XLEN{1'b0}};
  wire [`XLEN-1:0] csr_pmpaddr_rdata_w = csr_pmpaddr_q[csr_pmpaddr_idx_w];

  wire [`XLEN-1:0] csr_mip_hw_m_w =
      (irq_software_i ? `MIP_MSIP : {`XLEN{1'b0}}) |
      (irq_timer_i    ? `MIP_MTIP : {`XLEN{1'b0}}) |
      (irq_external_i ? `MIP_MEIP : {`XLEN{1'b0}});
  wire [`XLEN-1:0] csr_mip_hw_s_w =
      ((irq_software_i && csr_mideleg_q[`IRQ_CAUSE_SSI]) ? `MIP_SSIP : {`XLEN{1'b0}}) |
      ((irq_timer_i    && csr_mideleg_q[`IRQ_CAUSE_STI]) ? `MIP_STIP : {`XLEN{1'b0}}) |
      ((irq_external_i && csr_mideleg_q[`IRQ_CAUSE_SEI]) ? `MIP_SEIP : {`XLEN{1'b0}});
  wire [`XLEN-1:0] csr_mip_visible_w = csr_mip_q | csr_mip_hw_m_w | csr_mip_hw_s_w;
  wire csr_sd_w = ((csr_mstatus_q & `MSTATUS_FS_MASK) == `MSTATUS_FS_DIRTY);
  // SD 是 FS/VS/XS 的只读 summary；当前核未实现 VS/XS，所以只由 FS Dirty 派生。
  wire [`XLEN-1:0] csr_mstatus_visible_w =
      (csr_mstatus_q | `MSTATUS_SXL_UXL) |
      (csr_sd_w ? `MSTATUS_SD : {`XLEN{1'b0}});
  wire [`XLEN-1:0] csr_sstatus_visible_w =
      csr_mstatus_visible_w & `SSTATUS_MASK;
  wire [`XLEN-1:0] m_irq_enabled_pending_w =
      csr_mip_visible_w & csr_mie_q & MACHINE_INT_MASK &
      ~({`XLEN{(priv_mode_q != `PRIV_M)}} &
        ((csr_mideleg_q[`IRQ_CAUSE_SSI] ? `MIP_MSIP : {`XLEN{1'b0}}) |
         (csr_mideleg_q[`IRQ_CAUSE_STI] ? `MIP_MTIP : {`XLEN{1'b0}}) |
         (csr_mideleg_q[`IRQ_CAUSE_SEI] ? `MIP_MEIP : {`XLEN{1'b0}})));
  wire [`XLEN-1:0] s_irq_enabled_pending_w =
      csr_mip_visible_w & csr_mie_q & SUPERVISOR_INT_MASK;
  wire m_irq_global_enable_w =
      (priv_mode_q != `PRIV_M) ||
      ((csr_mstatus_q & `MSTATUS_MIE) != {`XLEN{1'b0}});
  wire s_irq_global_enable_w =
      (priv_mode_q == `PRIV_U) ||
      ((priv_mode_q == `PRIV_S) &&
       ((csr_mstatus_q & `MSTATUS_SIE) != {`XLEN{1'b0}}));
  wire s_irq_pending_w = s_irq_global_enable_w &&
                         (s_irq_enabled_pending_w != {`XLEN{1'b0}});
  wire m_irq_pending_w = m_irq_global_enable_w &&
                         (m_irq_enabled_pending_w != {`XLEN{1'b0}});

  wire [`TRAP_CAUSE_W-1:0] s_irq_cause_w =
      ((s_irq_enabled_pending_w & `MIP_SEIP) != {`XLEN{1'b0}}) ? `IRQ_CAUSE_SEI :
      ((s_irq_enabled_pending_w & `MIP_SSIP) != {`XLEN{1'b0}}) ? `IRQ_CAUSE_SSI :
                                                                 `IRQ_CAUSE_STI;
  wire [`TRAP_CAUSE_W-1:0] m_irq_cause_w =
      ((m_irq_enabled_pending_w & `MIP_MEIP) != {`XLEN{1'b0}}) ? `IRQ_CAUSE_MEI :
      ((m_irq_enabled_pending_w & `MIP_MSIP) != {`XLEN{1'b0}}) ? `IRQ_CAUSE_MSI :
                                                                 `IRQ_CAUSE_MTI;

  wire [`XLEN-1:0] csr_new_value_w =
      ((csr_funct3_i == 3'b001) || (csr_funct3_i == 3'b101)) ? csr_src_w :
      ((csr_funct3_i == 3'b010) || (csr_funct3_i == 3'b110)) ? (csr_rdata_o | csr_src_w) :
      ((csr_funct3_i == 3'b011) || (csr_funct3_i == 3'b111)) ? (csr_rdata_o & ~csr_src_w) :
                                                               csr_rdata_o;
  wire [`XLEN-1:0] csr_pmpcfg_write_value_w =
      apply_pmpcfg_lock(csr_pmpcfg_q[csr_pmpcfg_idx_w], csr_new_value_w);
  wire csr_pmpaddr_locked_w = pmpaddr_locked(csr_pmpaddr_idx_w);
  wire [`XLEN-1:0] csr_pmpaddr_write_value_w =
      csr_new_value_w & PMPADDR_WRITABLE_MASK;

  wire trap_mem_to_s_w = trap_mem_valid_i && (priv_mode_q != `PRIV_M) &&
                         csr_medeleg_q[trap_mem_cause_i];
  wire trap_ex_to_s_w = trap_ex_valid_i && (priv_mode_q != `PRIV_M) &&
                        csr_medeleg_q[trap_ex_cause_i];
  wire trap_irq_to_s_w = trap_irq_valid_i && (priv_mode_q != `PRIV_M) &&
                         ((trap_irq_cause_i == `IRQ_CAUSE_SSI) ||
                          (trap_irq_cause_i == `IRQ_CAUSE_STI) ||
                          (trap_irq_cause_i == `IRQ_CAUSE_SEI));
  wire trap_to_s_w = trap_mem_to_s_w | trap_ex_to_s_w | trap_irq_to_s_w;

  assign csr_rdata_o =
      (csr_addr_i == `CSR_MVENDORID) ? 64'h0000_0000_7973_7978 :
      (csr_addr_i == `CSR_MARCHID)   ? 64'd26010035 :
      (csr_addr_i == `CSR_MIMPID)    ? {`XLEN{1'b0}} :
      (csr_addr_i == `CSR_FFLAGS)   ? {{(`XLEN-5){1'b0}}, csr_fflags_q} :
      (csr_addr_i == `CSR_FRM)      ? {{(`XLEN-3){1'b0}}, csr_frm_q} :
      (csr_addr_i == `CSR_FCSR)     ? {{(`XLEN-8){1'b0}}, csr_frm_q, csr_fflags_q} :
      (csr_addr_i == `CSR_SSTATUS)  ? csr_sstatus_visible_w :
      (csr_addr_i == `CSR_SIE)      ? (csr_mie_q & SUPERVISOR_INT_MASK) :
      (csr_addr_i == `CSR_STVEC)    ? csr_stvec_q :
      (csr_addr_i == `CSR_SSCRATCH) ? csr_sscratch_q :
      (csr_addr_i == `CSR_SEPC)     ? csr_sepc_q :
      (csr_addr_i == `CSR_SCAUSE)   ? csr_scause_q :
      (csr_addr_i == `CSR_STVAL)    ? csr_stval_q :
      (csr_addr_i == `CSR_SIP)      ? (csr_mip_visible_w & SUPERVISOR_INT_MASK) :
      (csr_addr_i == `CSR_SCOUNTEREN) ? csr_scounteren_q :
      (csr_addr_i == `CSR_SATP)     ? csr_satp_q :
      (csr_addr_i == `CSR_MSTATUS)  ? csr_mstatus_visible_w :
      (csr_addr_i == `CSR_MISA)     ? CSR_MISA_VALUE :
      (csr_addr_i == `CSR_MEDELEG)  ? csr_medeleg_q :
      (csr_addr_i == `CSR_MIDELEG)  ? csr_mideleg_q :
      (csr_addr_i == `CSR_MIE)      ? csr_mie_q :
      (csr_addr_i == `CSR_MTVEC)    ? csr_mtvec_q :
      (csr_addr_i == `CSR_MCOUNTEREN) ? csr_mcounteren_q :
      (csr_addr_i == `CSR_MCOUNTINHIBIT) ? csr_mcountinhibit_q :
      (csr_addr_i == `CSR_MENVCFG)  ? csr_menvcfg_q :
      csr_pmpcfg_known_w            ? csr_pmpcfg_rdata_w :
      (csr_addr_i == `CSR_MSCRATCH) ? csr_mscratch_q :
      (csr_addr_i == `CSR_MEPC)     ? csr_mepc_q :
      (csr_addr_i == `CSR_MCAUSE)   ? csr_mcause_q :
      (csr_addr_i == `CSR_MTVAL)    ? csr_mtval_q :
      (csr_addr_i == `CSR_MIP)      ? csr_mip_visible_w :
      csr_pmpaddr_known_w           ? csr_pmpaddr_rdata_w :
      (csr_addr_i == `CSR_MCYCLE)   ? csr_mcycle_q :
      (csr_addr_i == `CSR_MINSTRET) ? csr_minstret_q :
      (csr_addr_i == `CSR_TSELECT)  ? CSR_TSELECT_NO_TRIGGER_VALUE :
      (csr_addr_i == `CSR_TDATA1)   ? {`XLEN{1'b0}} :
      (csr_addr_i == `CSR_TDATA2)   ? {`XLEN{1'b0}} :
      (csr_addr_i == `CSR_TCONTROL) ? {`XLEN{1'b0}} :
      (csr_addr_i == `CSR_CYCLE)    ? csr_mcycle_q :
      (csr_addr_i == `CSR_TIME)     ? time_i :
      (csr_addr_i == `CSR_INSTRET)  ? csr_minstret_q :
      (csr_addr_i == `CSR_MHARTID)  ? {`XLEN{1'b0}} :
                                      {`XLEN{1'b0}};
  assign csr_illegal_o = csr_valid_i && (~csr_known_r ||
                                         ~csr_priv_ok_w ||
                                         csr_satp_tvm_illegal_w ||
                                         ~csr_counter_allowed_w ||
                                         (csr_need_write_w && ~csr_writable_r));
  assign trap_target_o = trap_to_s_w ? {csr_stvec_q[`XLEN-1:2], 2'b00} :
                                      {csr_mtvec_q[`XLEN-1:2], 2'b00};
  assign mepc_o = csr_mepc_q;
  assign ret_target_o = sret_valid_i ? csr_sepc_q : csr_mepc_q;
  assign priv_mode_o = priv_mode_q;
  assign ecall_cause_o = (priv_mode_q == `PRIV_M) ? `EXC_ECALL_MMODE :
                         (priv_mode_q == `PRIV_S) ? `EXC_ECALL_SMODE :
                                                    `EXC_ECALL_UMODE;
  assign mstatus_o = csr_mstatus_q | `MSTATUS_SXL_UXL;
  assign satp_o = csr_satp_q;
  assign frm_o = csr_frm_q;
  assign svpbmt_en_o = (csr_menvcfg_q & `MENVCFG_PBMTE) != {`XLEN{1'b0}};
  assign irq_pending_o = s_irq_pending_w | m_irq_pending_w;
  // M 级中断优先于 S 级(规范全序 MEI>MSI>MTI>SEI>SSI>STI);双 pending 时先取 M。
  assign irq_cause_o = m_irq_pending_w ? m_irq_cause_w : s_irq_cause_w;

  genvar pmp_out_idx;
  generate
    for (pmp_out_idx = 0; pmp_out_idx < PMP_ADDR_COUNT; pmp_out_idx = pmp_out_idx + 1) begin : gen_pmp_out
      assign pmpcfg_o[pmp_out_idx * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W] =
          csr_pmpcfg_q[pmp_out_idx / 8][(pmp_out_idx % 8) * `PMP_CFG_ENTRY_W +: `PMP_CFG_ENTRY_W];
      assign pmpaddr_o[pmp_out_idx * `XLEN +: `XLEN] = csr_pmpaddr_q[pmp_out_idx];
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      priv_mode_q <= `PRIV_M;
      csr_mstatus_q <= `MSTATUS_SXL_UXL;
      csr_medeleg_q <= {`XLEN{1'b0}};
      csr_mideleg_q <= {`XLEN{1'b0}};
      csr_mtvec_q <= {`XLEN{1'b0}};
      csr_stvec_q <= {`XLEN{1'b0}};
      csr_mscratch_q <= {`XLEN{1'b0}};
      csr_sscratch_q <= {`XLEN{1'b0}};
      csr_mepc_q <= {`XLEN{1'b0}};
      csr_sepc_q <= {`XLEN{1'b0}};
      csr_mcause_q <= {`XLEN{1'b0}};
      csr_scause_q <= {`XLEN{1'b0}};
      csr_mtval_q <= {`XLEN{1'b0}};
      csr_stval_q <= {`XLEN{1'b0}};
      csr_mie_q <= {`XLEN{1'b0}};
      csr_mip_q <= {`XLEN{1'b0}};
      csr_satp_q <= {`XLEN{1'b0}};
      csr_mcycle_q <= 64'h0;
      csr_minstret_q <= 64'h0;
      csr_mcounteren_q <= {`XLEN{1'b0}};
      csr_scounteren_q <= {`XLEN{1'b0}};
      csr_mcountinhibit_q <= {`XLEN{1'b0}};
      csr_menvcfg_q <= {`XLEN{1'b0}};
      for (pmp_reset_idx = 0; pmp_reset_idx < PMP_CFG_CSR_COUNT; pmp_reset_idx = pmp_reset_idx + 1)
        csr_pmpcfg_q[pmp_reset_idx] <= {`XLEN{1'b0}};
      for (pmp_reset_idx = 0; pmp_reset_idx < PMP_ADDR_COUNT; pmp_reset_idx = pmp_reset_idx + 1)
        csr_pmpaddr_q[pmp_reset_idx] <= {`XLEN{1'b0}};
      csr_fflags_q <= 5'b00000;
      csr_frm_q <= 3'b000;
    end else begin
      csr_mcycle_q <= (cycle_count_enable_i && ~mcycle_inhibit_w) ?
                      (csr_mcycle_q + 64'd1) : csr_mcycle_q;
      csr_minstret_q <= (cycle_count_enable_i && ~minstret_inhibit_w) ?
                        (csr_minstret_q + {62'd0, instret_inc_i}) :
                        csr_minstret_q;

      if (trap_mem_valid_i) begin
        if (trap_mem_to_s_w) begin
          csr_sepc_q <= epc_warl_value(trap_mem_pc_i);
          csr_scause_q <= {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_mem_cause_i};
          csr_stval_q <= trap_mem_tval_i;
          csr_mstatus_q <= trap_to_s_mstatus(csr_mstatus_q, priv_mode_q);
          priv_mode_q <= `PRIV_S;
        end else begin
          csr_mepc_q <= epc_warl_value(trap_mem_pc_i);
          csr_mcause_q <= {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_mem_cause_i};
          csr_mtval_q <= trap_mem_tval_i;
          csr_mstatus_q <= trap_to_m_mstatus(csr_mstatus_q, priv_mode_q);
          priv_mode_q <= `PRIV_M;
        end
      end else if (trap_ex_valid_i) begin
        if (trap_ex_to_s_w) begin
          csr_sepc_q <= epc_warl_value(trap_ex_pc_i);
          csr_scause_q <= {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_ex_cause_i};
          csr_stval_q <= trap_ex_tval_i;
          csr_mstatus_q <= trap_to_s_mstatus(csr_mstatus_q, priv_mode_q);
          priv_mode_q <= `PRIV_S;
        end else begin
          csr_mepc_q <= epc_warl_value(trap_ex_pc_i);
          csr_mcause_q <= {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_ex_cause_i};
          csr_mtval_q <= trap_ex_tval_i;
          csr_mstatus_q <= trap_to_m_mstatus(csr_mstatus_q, priv_mode_q);
          priv_mode_q <= `PRIV_M;
        end
      end else if (trap_irq_valid_i) begin
        if (trap_irq_to_s_w) begin
          csr_sepc_q <= epc_warl_value(trap_irq_pc_i);
          csr_scause_q <= `MCAUSE_INTERRUPT |
                          {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_irq_cause_i};
          csr_stval_q <= {`XLEN{1'b0}};
          csr_mstatus_q <= trap_to_s_mstatus(csr_mstatus_q, priv_mode_q);
          priv_mode_q <= `PRIV_S;
        end else begin
          csr_mepc_q <= epc_warl_value(trap_irq_pc_i);
          csr_mcause_q <= `MCAUSE_INTERRUPT |
                          {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_irq_cause_i};
          csr_mtval_q <= {`XLEN{1'b0}};
          csr_mstatus_q <= trap_to_m_mstatus(csr_mstatus_q, priv_mode_q);
          priv_mode_q <= `PRIV_M;
        end
      end else begin
        if (mret_valid_i) begin
          priv_mode_q <= mpp_to_priv(csr_mstatus_q);
          csr_mstatus_q <= mret_mstatus(csr_mstatus_q, mpp_to_priv(csr_mstatus_q));
        end else if (sret_valid_i) begin
          priv_mode_q <= ((csr_mstatus_q & `MSTATUS_SPP) != {`XLEN{1'b0}}) ?
                         `PRIV_S : `PRIV_U;
          csr_mstatus_q <= sret_mstatus(csr_mstatus_q);
        end

        if (csr_commit_i && csr_valid_i && ~csr_illegal_o && csr_need_write_w) begin
          if (csr_pmpcfg_storage_w) begin
            csr_pmpcfg_q[csr_pmpcfg_idx_w] <= csr_pmpcfg_write_value_w;
          end else if (csr_pmpaddr_known_w) begin
            if (!csr_pmpaddr_locked_w)
              csr_pmpaddr_q[csr_pmpaddr_idx_w] <= csr_pmpaddr_write_value_w;
          end else begin
            case (csr_addr_i)
            `CSR_FFLAGS:   csr_fflags_q <= csr_new_value_w[4:0];
            `CSR_FRM:      csr_frm_q <= csr_new_value_w[2:0];
            `CSR_FCSR: begin
              csr_fflags_q <= csr_new_value_w[4:0];
              csr_frm_q <= csr_new_value_w[7:5];
            end
            `CSR_SSTATUS:  csr_mstatus_q <=
                ((csr_mstatus_q & ~SSTATUS_WRITABLE_MASK) |
                 (csr_new_value_w & SSTATUS_WRITABLE_MASK) |
                 `MSTATUS_SXL_UXL);
            `CSR_SIE:      csr_mie_q <=
                (csr_mie_q & ~SUPERVISOR_INT_MASK) |
                (csr_new_value_w & SUPERVISOR_INT_MASK);
            `CSR_STVEC:    csr_stvec_q <= {csr_new_value_w[`XLEN-1:2], 2'b00};
            `CSR_SSCRATCH: csr_sscratch_q <= csr_new_value_w;
            `CSR_SEPC:     csr_sepc_q <= epc_warl_value(csr_new_value_w);
            `CSR_SCAUSE:   csr_scause_q <= csr_new_value_w;
            `CSR_STVAL:    csr_stval_q <= csr_new_value_w;
            // sip 是 mip 的受限视图：S 态经 sip 只能写 SSIP；STIP/SEIP 在 sip 视图为
            // 只读（由 M 态/硬件控制）。旧实现用 SUPERVISOR_INT_MASK 放行了 STIP/SEIP 写
            // → S 态可伪造 S 级 timer/external 中断（WARL 违规）。收紧为仅 SSIP 可写。
            `CSR_SIP:      csr_mip_q <=
                (csr_mip_q & ~`MIP_SSIP) |
                (csr_new_value_w & `MIP_SSIP);
            `CSR_SCOUNTEREN: csr_scounteren_q <= csr_new_value_w & `COUNTEREN_MASK;
            `CSR_SATP:     csr_satp_q <= sanitize_satp(csr_new_value_w);
            `CSR_MSTATUS:  csr_mstatus_q <=
                (csr_new_value_w & MSTATUS_WRITABLE_MASK) | `MSTATUS_SXL_UXL;
            `CSR_MEDELEG:  csr_medeleg_q <= csr_new_value_w;
            `CSR_MIDELEG:  csr_mideleg_q <= csr_new_value_w;
            `CSR_MIE:      csr_mie_q <= csr_new_value_w &
                (MACHINE_INT_MASK | SUPERVISOR_INT_MASK);
            `CSR_MTVEC:    csr_mtvec_q <= {csr_new_value_w[`XLEN-1:2], 2'b00};
            `CSR_MCOUNTEREN: csr_mcounteren_q <= csr_new_value_w & `COUNTEREN_MASK;
            `CSR_MCOUNTINHIBIT: csr_mcountinhibit_q <=
                csr_new_value_w & (`MCOUNTINHIBIT_CY | `MCOUNTINHIBIT_IR);
            `CSR_MENVCFG: csr_menvcfg_q <= csr_new_value_w & MENVCFG_WRITABLE_MASK;
            `CSR_MSCRATCH: csr_mscratch_q <= csr_new_value_w;
            `CSR_MEPC:     csr_mepc_q <= epc_warl_value(csr_new_value_w);
            `CSR_MCAUSE:   csr_mcause_q <= csr_new_value_w;
            `CSR_MTVAL:    csr_mtval_q <= csr_new_value_w;
            // mip：MSIP/MTIP/MEIP 是只读硬件位（CLINT/PLIC 驱动，经 csr_mip_visible_w
            // 动态 OR 注入，从不入 csr_mip_q）；M 态经 mip 只能写 S 级软件位
            // SSIP/STIP/SEIP。旧实现用 ~(当前拉高的硬件位) 当掩码，当硬件中断线为低时
            // 反而放行 M 态把 MSIP/MTIP/MEIP 写进 csr_mip_q → 可注入伪机器中断（WARL 违规）。
            `CSR_MIP:      csr_mip_q <=
                (csr_mip_q & ~SUPERVISOR_INT_MASK) |
                (csr_new_value_w & SUPERVISOR_INT_MASK);
            `CSR_MCYCLE:   csr_mcycle_q <= csr_new_value_w;
            `CSR_MINSTRET: csr_minstret_q <= csr_new_value_w;
            default: begin end
            endcase
          end
        end else if (fp_dirty_i) begin
          // F8：任意写 FPR 或更新 fcsr 的 FP 指令提交时，必须把 mstatus.FS 置 Dirty，
          // 否则只读 SD 派生位恒为 0、依赖 FS=Dirty 做惰性保存的 OS 会漏存 FP 上下文。
          // fp_dirty_i = fflags 提交 | FPR load 写 | FPR 结果写（在 NpcCoreTop 处 OR）；
          // fp_fflags_valid_i 是其子集，仅它高时累积 fflags。FP 走域B串行，此拍无并发
          // mret/sret/mstatus CSR 写，故直接覆写 FS 字段安全。
          if (fp_fflags_valid_i)
            csr_fflags_q <= csr_fflags_q | fp_fflags_i;
          csr_mstatus_q <= (csr_mstatus_q & ~`MSTATUS_FS_MASK) | `MSTATUS_FS_DIRTY;
        end
      end
    end
  end


endmodule
