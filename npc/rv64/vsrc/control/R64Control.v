`include "R64Uop.vh"
// 精确退休控制域：Commit 持有事件，Serial 持有串行事务，CSR 持有架构状态。
// 查询、prepare、退休写入的内部协议在本域闭合；层级不增加寄存器或改动拍数。
// full_flush、选择性 kill 与外部事务 reuse_block 保持独立的生命周期。
module R64Control #(
  parameter [63:0] RESET_PC = 64'h80000000
) (
  // 时钟、运行和外部事件。
  input                       clk_i,
  input                       rst_i,
  input                       run_i,
  input                       irq_software_i,
  input                       irq_timer_i,
  input                       irq_external_i,
  input                       irq_supervisor_external_i,
  input                       wfi_wait_i,
  input                [63:0] time_i,
  // ROB 退休窗口与常驻 head 事实。
  input                 [1:0] rob_valid_i,
  input                 [1:0] rob_serial_i,
  input                 [1:0] rob_exception_i,
  input                 [1:0] rob_write_i,
  input                 [1:0] rob_fp_i,
  output                [1:0] rob_ready_o,
  output                      commit1_allow_o,
  input                [17:0] rob_tag_i,
  input   [2*`R64_META_W-1:0] rob_meta_i,
  input               [127:0] rob_data_i,
  input               [127:0] rob_tval_i,
  input                [11:0] rob_cause_i,
  input                 [9:0] rob_arch_i,
  input                 [9:0] rob_flags_i,
  input                 [5:0] rob_count_i,
  input                 [8:0] head_tag_i,
  input                       head_serial_i,
  input                       head_exception_raw_i,
  input                       recover_i,
  input                [31:0] kill_mask_i,
  // 串行执行、完成与不可取消事务。
  input                       serial_fire_i,
  output                      serial_ready_o,
  input                 [8:0] serial_tag_i,
  input      [`R64_UOP_W-1:0] serial_uop_i,
  input               [191:0] serial_operand_i,
  output                      serial_result_valid_o,
  input                       serial_result_ready_i,
  output                [8:0] serial_result_tag_o,
  output  [`R64_RESULT_W-1:0] serial_result_o,
  input                       memory_idle_i,
  input                       lsu_irrevocable_i,
  output                      serial_irrevocable_o,
  output                      serial_idle_o,
  output               [31:0] serial_reuse_o,
  // 恢复、退休副作用及执行许可。
  output                      stop_birth_o,
  output                      full_flush_o,
  output                      control_redirect_o,
  output                      effect_allow_o,
  output                      serial_allow_o,
  output               [63:0] control_target_o,
  output                [1:0] retire_fire_o,
  // 架构上下文、保护与失效。
  output                [1:0] privilege_o,
  output               [63:0] mstatus_o,
  output               [63:0] satp_o,
  output               [63:0] trigger_address_o,
  output               [63:0] pmp_permission_o,
  output                [2:0] frm_o,
  output                [2:0] trigger_enable_o,
  output                      pbmt_enable_o,
  output                      icache_invalidate_o,
  output                      tlb_invalidate_o,
  output                      tlb_all_vaddr_o,
  output                      tlb_all_asid_o,
  output               [15:0] pmp_active_o,
  output               [15:0] tlb_asid_o,
  output              [895:0] pmp_lower_o,
  output              [895:0] pmp_upper_o,
  output               [26:0] tlb_vpn_o,
  // 可选 Tensor 外部事务。
  output                      tensor_cmd_valid_o,
  output                      tensor_pair_o,
  output                      tensor_terminal_ready_o,
  input                       tensor_cmd_ready_i,
  input                       tensor_terminal_valid_i,
  input                       tensor_error_i,
  output                [8:0] tensor_cmd_tag_o,
  input                 [8:0] tensor_terminal_tag_i,
  output               [63:0] tensor_cmd_o,
  output               [63:0] tensor_operand_o,
  output                [7:0] tensor_class_o,
  input                 [7:0] tensor_error_code_i,
  // 当前边沿的退休与 trap 观察。
  input                 [1:0] trace_ready_i,
  output                [1:0] trace_valid_o,
  output                [1:0] trace_rd_write_o,
  output                [1:0] trace_rd_fp_o,
  output              [127:0] trace_pc_o,
  output              [127:0] trace_raw_o,
  output              [127:0] trace_npc_o,
  output              [127:0] trace_data_o,
  output                [7:0] trace_length_o,
  output                [9:0] trace_rd_arch_o,
  output                [9:0] trace_fflags_o,
  output               [15:0] trace_kind_o,
  output                      trap_valid_o,
  output                      trap_interrupt_o,
  output                [5:0] trap_cause_o,
  output               [63:0] trap_pc_o,
  output               [63:0] trap_tval_o,
  output               [63:0] trap_raw_o,
  output               [63:0] trap_target_o,
  output                [3:0] trap_length_o
);
  localparam M = `R64_META_W;
  wire serial_commit;
  wire [8:0] serial_commit_tag;
  wire [1:0] retired_count;
  wire [127:0] retire_npc;
  wire fp_dirty;
  wire [4:0] fp_flags;
  wire trap, trap_interrupt, trap_prepare;
  wire csr_query, csr_query_valid, return_prepare;
  wire [5:0] trap_cause;
  wire [63:0] trap_pc, trap_tval, trap_target;
  wire irq_pending, wfi_wake;
  wire [5:0] irq_cause;
  wire [127:0] pmp_config;
  wire [863:0] pmp_address;
  wire [63:0] csr_select;
  wire [11:0] csr_address;
  wire [2:0] csr_operation;
  wire [4:0] csr_rs1;
  wire [63:0] csr_operand, csr_read, csr_write_value, return_target;
  wire csr_commit, csr_illegal, return_supervisor;
  wire [1:0] return_commit;

  R64PmpDecode pmp_decode (
    .config_i(pmp_config),
    .address_i(pmp_address),
    .active_o(pmp_active_o),
    .lower_o(pmp_lower_o),
    .upper_o(pmp_upper_o),
    .permission_o(pmp_permission_o)
  );
  R64Serial serial (
    .csr_query_o(csr_query),
    .csr_query_valid_i(csr_query_valid),
    .return_prepare_o(return_prepare),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .flush_i(full_flush_o),
    .kill_mask_i(kill_mask_i),
    .fire_i(serial_fire_i),
    .ready_o(serial_ready_o),
    .tag_i(serial_tag_i),
    .head_tag_i(head_tag_i),
    .uop_i(serial_uop_i),
    .operand_i(serial_operand_i),
    .memory_idle_i(memory_idle_i),
    .wfi_wake_i(!wfi_wait_i || wfi_wake || irq_timer_i),
    .result_valid_o(serial_result_valid_o),
    .result_ready_i(serial_result_ready_i),
    .result_tag_o(serial_result_tag_o),
    .result_o(serial_result_o),
    .commit_i(serial_commit),
    .commit_tag_i(serial_commit_tag),
    .privilege_i(privilege_o),
    .mstatus_i(mstatus_o),
    .csr_address_o(csr_address),
    .csr_select_o(csr_select),
    .csr_operation_o(csr_operation),
    .csr_rs1_o(csr_rs1),
    .csr_operand_o(csr_operand),
    .csr_commit_o(csr_commit),
    .csr_read_i(csr_read),
    .csr_write_value_i(csr_write_value),
    .csr_illegal_i(csr_illegal),
    .return_supervisor_o(return_supervisor),
    .return_commit_o(return_commit),
    .return_target_i(return_target),
    .icache_invalidate_o(icache_invalidate_o),
    .tlb_invalidate_o(tlb_invalidate_o),
    .tlb_all_vaddr_o(tlb_all_vaddr_o),
    .tlb_all_asid_o(tlb_all_asid_o),
    .tlb_vpn_o(tlb_vpn_o),
    .tlb_asid_o(tlb_asid_o),
    .tensor_cmd_valid_o(tensor_cmd_valid_o),
    .tensor_cmd_ready_i(tensor_cmd_ready_i),
    .tensor_cmd_tag_o(tensor_cmd_tag_o),
    .tensor_cmd_o(tensor_cmd_o),
    .tensor_operand_o(tensor_operand_o),
    .tensor_pair_o(tensor_pair_o),
    .tensor_class_o(tensor_class_o),
    .tensor_terminal_valid_i(tensor_terminal_valid_i),
    .tensor_terminal_ready_o(tensor_terminal_ready_o),
    .tensor_terminal_tag_i(tensor_terminal_tag_i),
    .tensor_error_i(tensor_error_i),
    .tensor_error_code_i(tensor_error_code_i),
    .irrevocable_o(serial_irrevocable_o),
    .reuse_block_o(serial_reuse_o),
    .idle_o(serial_idle_o)
  );
  R64Csr csr (
    .query_i(csr_query),
    .query_valid_o(csr_query_valid),
    .trap_prepare_i(trap_prepare),
    .return_prepare_i(return_prepare),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .count_enable_i(run_i),
    .time_i(time_i),
    .retired_i(retired_count),
    .address_i(csr_address),
    .select_i(csr_select),
    .operation_i(csr_operation),
    .rs1_i(csr_rs1),
    .operand_i(csr_operand),
    .commit_i(csr_commit),
    .read_o(csr_read),
    .illegal_o(csr_illegal),
    .fp_dirty_i(fp_dirty),
    .fp_flags_i(fp_flags),
    .trap_i(trap),
    .trap_interrupt_i(trap_interrupt),
    .trap_cause_i(trap_cause),
    .trap_pc_i(trap_pc),
    .trap_tval_i(trap_tval),
    .return_i(return_commit),
    .return_target_o(return_target),
    .irq_software_i(irq_software_i),
    .irq_timer_i(irq_timer_i),
    .irq_external_i(irq_external_i),
    .irq_supervisor_external_i(irq_supervisor_external_i),
    .wfi_wake_o(wfi_wake),
    .irq_pending_o(irq_pending),
    .irq_cause_o(irq_cause),
    .trap_target_o(trap_target),
    .privilege_o(privilege_o),
    .mstatus_o(mstatus_o),
    .satp_o(satp_o),
    .frm_o(frm_o),
    .pbmt_enable_o(pbmt_enable_o),
    .pmp_config_o(pmp_config),
    .pmp_address_o(pmp_address),
    .write_value_o(csr_write_value),
    .commit_value_i(csr_operand),
    .return_supervisor_i(return_supervisor),
    .trigger_enable_o(trigger_enable_o),
    .trigger_address_o(trigger_address_o)
  );
  R64Commit #(
    .SCRATCH_READ_RESUME(1),
    .RESET_PC(RESET_PC),
    .HEAD_SERIAL_ISSUE(1),
    .HEAD_SERIAL_STOP(1),
    .HEAD_EXCEPTION_STOP(1),
    .HEAD_SERIAL_CLASS(1)
  ) commit (
    .trap_prepare_o(trap_prepare),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .rob_valid_i(rob_valid_i),
    .rob_serial_i(rob_serial_i),
    .rob_ready_o(rob_ready_o),
    .commit1_allow_o(commit1_allow_o),
    .rob_tag_i(rob_tag_i),
    .rob_meta_i(rob_meta_i),
    .rob_data_i(rob_data_i),
    .rob_exception_i(rob_exception_i),
    .rob_cause_i(rob_cause_i),
    .rob_tval_i(rob_tval_i),
    .rob_rd_write_i(rob_write_i),
    .rob_rd_fp_i(rob_fp_i),
    .rob_fflags_i(rob_flags_i),
    .retire_ready_i(trace_ready_i),
    .rob_empty_i(rob_count_i == 0),
    .head_serial_i(head_serial_i),
    .head_exception_i(head_exception_raw_i),
    .recover_i(recover_i),
    .lsu_irrevocable_i(lsu_irrevocable_i),
    .serial_irrevocable_i(serial_irrevocable_o),
    .irq_pending_i(irq_pending),
    .irq_cause_i(irq_cause),
    .trap_target_i(trap_target),
    .retire_fire_o(retire_fire_o),
    .retire_npc_o(retire_npc),
    .retired_count_o(retired_count),
    .fp_dirty_o(fp_dirty),
    .fp_flags_o(fp_flags),
    .serial_commit_o(serial_commit),
    .serial_tag_o(serial_commit_tag),
    .trap_o(trap),
    .trap_interrupt_o(trap_interrupt),
    .trap_cause_o(trap_cause),
    .trap_pc_o(trap_pc),
    .trap_tval_o(trap_tval),
    .stop_birth_o(stop_birth_o),
    .full_flush_o(full_flush_o),
    .redirect_o(control_redirect_o),
    .redirect_target_o(control_target_o),
    .effect_allow_o(effect_allow_o),
    .serial_allow_o(serial_allow_o)
  );
  assign trace_valid_o = retire_fire_o;
  assign trace_npc_o = retire_npc;
  assign trace_data_o = rob_data_i;
  assign trace_rd_write_o = rob_write_i;
  assign trace_rd_fp_o = rob_fp_i;
  assign trace_rd_arch_o = rob_arch_i;
  assign trace_fflags_o = rob_flags_i;
  genvar lane;
  generate
    for (lane = 0; lane < 2; lane = lane + 1) begin : g_trace
      assign trace_pc_o[lane*64+:64]   = rob_meta_i[lane*M+:64];
      assign trace_raw_o[lane*64+:64]  = rob_meta_i[lane*M+64+:64];
      assign trace_length_o[lane*4+:4] = rob_meta_i[lane*M+192+:4];
      assign trace_kind_o[lane*8+:8]   = rob_meta_i[lane*M+196+:8];
    end
  endgenerate
  assign trap_valid_o = trap;
  assign trap_interrupt_o = trap_interrupt;
  assign trap_cause_o = trap_cause;
  assign trap_pc_o = trap_pc;
  assign trap_tval_o = trap_tval;
  assign trap_target_o = trap_target;
  assign trap_raw_o = trap_interrupt ? 64'b0 : rob_meta_i[127:64];
  assign trap_length_o = trap_interrupt ? 4'b0 : rob_meta_i[195:192];
endmodule
