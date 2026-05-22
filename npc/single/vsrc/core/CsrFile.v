`include "define.v"

// CSRFile 收口 machine CSR 的读改写、合法性和 trap/mret 副作用，避免 NpcCore 主数据通路继续堆 CSR 细节。
module CsrFile (
  input clk,
  input rst,

  input cycle_count_enable_i,

  input csr_valid_i,
  input [11:0] csr_addr_i,
  input [2:0] csr_funct3_i,
  input [`REG_ADDR_W-1:0] csr_rs1_idx_i,
  input [`XLEN-1:0] csr_rs1_data_i,
  input [4:0] csr_zimm_i,
  input csr_commit_i,
  output [`XLEN-1:0] csr_rdata_o,
  output csr_illegal_o,

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
  output [`XLEN-1:0] trap_target_o,
  output [`XLEN-1:0] mepc_o
);

  function [`XLEN-1:0] trap_mstatus;
    input [`XLEN-1:0] old_status;
    begin
      trap_mstatus = old_status;
      if ((old_status & `MSTATUS_MIE) != {`XLEN{1'b0}})
        trap_mstatus = trap_mstatus | `MSTATUS_MPIE;
      else
        trap_mstatus = trap_mstatus & ~`MSTATUS_MPIE;
      trap_mstatus = trap_mstatus & ~`MSTATUS_MIE;
      trap_mstatus = (trap_mstatus & ~`MSTATUS_MPP_MASK) | `MSTATUS_MPP_M;
    end
  endfunction

  function [`XLEN-1:0] mret_mstatus;
    input [`XLEN-1:0] old_status;
    begin
      mret_mstatus = old_status;
      if ((old_status & `MSTATUS_MPIE) != {`XLEN{1'b0}})
        mret_mstatus = mret_mstatus | `MSTATUS_MIE;
      else
        mret_mstatus = mret_mstatus & ~`MSTATUS_MIE;
      mret_mstatus = mret_mstatus | `MSTATUS_MPIE;
      mret_mstatus = mret_mstatus & ~`MSTATUS_MPP_MASK;
    end
  endfunction

  function csr_writable;
    input [11:0] csr_addr;
    begin
      case (csr_addr)
        `CSR_MSTATUS,
        `CSR_MIE,
        `CSR_MTVEC,
        `CSR_MCOUNTINHIBIT,
        `CSR_MSCRATCH,
        `CSR_MEPC,
        `CSR_MCAUSE,
        `CSR_MTVAL,
        `CSR_MIP,
        `CSR_MCYCLE,
        `CSR_MCYCLEH: csr_writable = 1'b1;
        default:      csr_writable = 1'b0;
      endcase
    end
  endfunction

  function csr_known;
    input [11:0] csr_addr;
    begin
      case (csr_addr)
        `CSR_MVENDORID,
        `CSR_MARCHID,
        `CSR_MSTATUS,
        `CSR_MISA,
        `CSR_MIE,
        `CSR_MTVEC,
        `CSR_MCOUNTINHIBIT,
        `CSR_MSCRATCH,
        `CSR_MEPC,
        `CSR_MCAUSE,
        `CSR_MTVAL,
        `CSR_MIP,
        `CSR_MCYCLE,
        `CSR_MCYCLEH,
        `CSR_CYCLE,
        `CSR_CYCLEH,
        `CSR_MHARTID: csr_known = 1'b1;
        default:      csr_known = 1'b0;
      endcase
    end
  endfunction

  reg [`XLEN-1:0] csr_mstatus_q;
  reg [`XLEN-1:0] csr_mtvec_q;
  reg [`XLEN-1:0] csr_mscratch_q;
  reg [`XLEN-1:0] csr_mepc_q;
  reg [`XLEN-1:0] csr_mcause_q;
  reg [`XLEN-1:0] csr_mtval_q;
  reg [`XLEN-1:0] csr_mie_q;
  reg [`XLEN-1:0] csr_mip_q;
  reg [63:0] csr_mcycle_q;
  reg [`XLEN-1:0] csr_mcountinhibit_q;

  /* verilator lint_off UNUSEDSIGNAL */
  wire trap_mem_pc_align_bit_unused_w = trap_mem_pc_i[0];
  wire trap_ex_pc_align_bit_unused_w = trap_ex_pc_i[0];
  wire trap_irq_pc_align_bit_unused_w = trap_irq_pc_i[0];
  /* verilator lint_on UNUSEDSIGNAL */

  wire csr_imm_op_w = csr_funct3_i[2];
  wire [`XLEN-1:0] csr_zimm_w = {{(`XLEN-5){1'b0}}, csr_zimm_i};
  wire [`XLEN-1:0] csr_src_w = csr_imm_op_w ? csr_zimm_w : csr_rs1_data_i;
  wire csr_set_clear_noop_w = ((csr_funct3_i == 3'b010) || (csr_funct3_i == 3'b011) ||
                               (csr_funct3_i == 3'b110) || (csr_funct3_i == 3'b111)) &&
                              (csr_rs1_idx_i == {`REG_ADDR_W{1'b0}});
  wire csr_need_write_w = csr_valid_i && ((csr_funct3_i == 3'b001) ||
                                          (csr_funct3_i == 3'b101) ||
                                          ~csr_set_clear_noop_w);
  wire mcycle_inhibit_w = (csr_mcountinhibit_q & `MCOUNTINHIBIT_CY) != {`XLEN{1'b0}};
  wire [`XLEN-1:0] csr_mip_hw_w =
      (irq_software_i ? `MIP_MSIP : {`XLEN{1'b0}}) |
      (irq_timer_i    ? `MIP_MTIP : {`XLEN{1'b0}}) |
      (irq_external_i ? `MIP_MEIP : {`XLEN{1'b0}});
  wire [`XLEN-1:0] csr_mip_visible_w = csr_mip_q | csr_mip_hw_w;
  wire [`XLEN-1:0] irq_enabled_pending_w = csr_mip_visible_w & csr_mie_q &
                                           (`MIP_MSIP | `MIP_MTIP | `MIP_MEIP);
  wire irq_global_enable_w = (csr_mstatus_q & `MSTATUS_MIE) != {`XLEN{1'b0}};
  wire [`XLEN-1:0] csr_new_value_w =
      ((csr_funct3_i == 3'b001) || (csr_funct3_i == 3'b101)) ? csr_src_w :
      ((csr_funct3_i == 3'b010) || (csr_funct3_i == 3'b110)) ? (csr_rdata_o | csr_src_w) :
      ((csr_funct3_i == 3'b011) || (csr_funct3_i == 3'b111)) ? (csr_rdata_o & ~csr_src_w) :
                                                               csr_rdata_o;

  assign csr_rdata_o =
      // YSYX 平台识别 CSR 做成只读常量，后续修改身份信息只需改这一处。
      (csr_addr_i == `CSR_MVENDORID) ? 32'h7973_7978 :
      (csr_addr_i == `CSR_MARCHID)   ? 32'd26010035 :
      (csr_addr_i == `CSR_MSTATUS)  ? csr_mstatus_q :
      (csr_addr_i == `CSR_MISA)     ? 32'h4000_1106 :
      (csr_addr_i == `CSR_MIE)      ? csr_mie_q :
      (csr_addr_i == `CSR_MTVEC)    ? csr_mtvec_q :
      (csr_addr_i == `CSR_MCOUNTINHIBIT) ? csr_mcountinhibit_q :
      (csr_addr_i == `CSR_MSCRATCH) ? csr_mscratch_q :
      (csr_addr_i == `CSR_MEPC)     ? csr_mepc_q :
      (csr_addr_i == `CSR_MCAUSE)   ? csr_mcause_q :
      (csr_addr_i == `CSR_MTVAL)    ? csr_mtval_q :
      (csr_addr_i == `CSR_MIP)      ? csr_mip_visible_w :
      (csr_addr_i == `CSR_MCYCLE)   ? csr_mcycle_q[31:0] :
      (csr_addr_i == `CSR_MCYCLEH)  ? csr_mcycle_q[63:32] :
      (csr_addr_i == `CSR_CYCLE)    ? csr_mcycle_q[31:0] :
      (csr_addr_i == `CSR_CYCLEH)   ? csr_mcycle_q[63:32] :
      (csr_addr_i == `CSR_MHARTID)  ? {`XLEN{1'b0}} :
                                      {`XLEN{1'b0}};
  assign csr_illegal_o = csr_valid_i && (~csr_known(csr_addr_i) ||
                                         (csr_need_write_w && ~csr_writable(csr_addr_i)));
  assign trap_target_o = {csr_mtvec_q[`XLEN-1:2], 2'b00};
  assign mepc_o = csr_mepc_q;
  assign irq_pending_o = irq_global_enable_w && (irq_enabled_pending_w != {`XLEN{1'b0}});
  // M-mode 标准固定优先级：外部中断优先，其次软件中断，最后定时器中断。
  assign irq_cause_o = ((irq_enabled_pending_w & `MIP_MEIP) != {`XLEN{1'b0}}) ? `IRQ_CAUSE_MEI :
                       ((irq_enabled_pending_w & `MIP_MSIP) != {`XLEN{1'b0}}) ? `IRQ_CAUSE_MSI :
                                                                                `IRQ_CAUSE_MTI;

  always @(posedge clk) begin
    if (rst) begin
      csr_mstatus_q <= {`XLEN{1'b0}};
      csr_mtvec_q <= {`XLEN{1'b0}};
      csr_mscratch_q <= {`XLEN{1'b0}};
      csr_mepc_q <= {`XLEN{1'b0}};
      csr_mcause_q <= {`XLEN{1'b0}};
      csr_mtval_q <= {`XLEN{1'b0}};
      csr_mie_q <= {`XLEN{1'b0}};
      csr_mip_q <= {`XLEN{1'b0}};
      csr_mcycle_q <= 64'h0;
      csr_mcountinhibit_q <= {`XLEN{1'b0}};
    end else begin
      // mcycle 属于核心周期计数器；把默认递增放在模块内部，后续改 counter 语义只需改 CsrFile。
      csr_mcycle_q <= (cycle_count_enable_i && ~mcycle_inhibit_w) ?
                      (csr_mcycle_q + 64'd1) : csr_mcycle_q;

      if (trap_mem_valid_i) begin
        csr_mepc_q <= {trap_mem_pc_i[`XLEN-1:1], 1'b0};
        csr_mcause_q <= {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_mem_cause_i};
        csr_mtval_q <= trap_mem_tval_i;
        csr_mstatus_q <= trap_mstatus(csr_mstatus_q);
      end else if (trap_ex_valid_i) begin
        csr_mepc_q <= {trap_ex_pc_i[`XLEN-1:1], 1'b0};
        csr_mcause_q <= {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_ex_cause_i};
        csr_mtval_q <= trap_ex_tval_i;
        csr_mstatus_q <= trap_mstatus(csr_mstatus_q);
      end else if (trap_irq_valid_i) begin
        csr_mepc_q <= {trap_irq_pc_i[`XLEN-1:1], 1'b0};
        csr_mcause_q <= `MCAUSE_INTERRUPT | {{(`XLEN-`TRAP_CAUSE_W){1'b0}}, trap_irq_cause_i};
        csr_mtval_q <= {`XLEN{1'b0}};
        csr_mstatus_q <= trap_mstatus(csr_mstatus_q);
      end else begin
        if (mret_valid_i) begin
          csr_mstatus_q <= mret_mstatus(csr_mstatus_q);
        end

        if (csr_commit_i && csr_valid_i && ~csr_illegal_o && csr_need_write_w) begin
          case (csr_addr_i)
            `CSR_MSTATUS:  csr_mstatus_q <= csr_new_value_w;
            `CSR_MIE:      csr_mie_q <= csr_new_value_w & (`MIE_MSIE | `MIE_MTIE | `MIE_MEIE);
            `CSR_MTVEC:    csr_mtvec_q <= {csr_new_value_w[`XLEN-1:2], 2'b00};
            `CSR_MCOUNTINHIBIT: csr_mcountinhibit_q <= csr_new_value_w & `MCOUNTINHIBIT_CY;
            `CSR_MSCRATCH: csr_mscratch_q <= csr_new_value_w;
            `CSR_MEPC:     csr_mepc_q <= {csr_new_value_w[`XLEN-1:1], 1'b0};
            `CSR_MCAUSE:   csr_mcause_q <= csr_new_value_w;
            `CSR_MTVAL:    csr_mtval_q <= csr_new_value_w;
            // 标准 M-mode 硬件 pending 位由 CLINT/外部控制器驱动，CSR 写不能伪造或清除它们。
            `CSR_MIP:      csr_mip_q <= csr_new_value_w & ~(`MIP_MSIP | `MIP_MTIP | `MIP_MEIP);
            `CSR_MCYCLE:   csr_mcycle_q <= {csr_mcycle_q[63:32], csr_new_value_w};
            `CSR_MCYCLEH:  csr_mcycle_q <= {csr_new_value_w, csr_mcycle_q[31:0]};
            default: begin end
          endcase
        end
      end
    end
  end

endmodule
