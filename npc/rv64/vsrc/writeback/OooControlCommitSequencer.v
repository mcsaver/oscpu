`include "define.v"

module OooControlCommitSequencer (
  input clk,
  input rst,

  input pending_jump_nolink_commit_i,
  input [`XLEN-1:0] pending_jump_pc_i,
  input [`INST_W-1:0] pending_jump_inst_i,
  input [`XLEN-1:0] pending_jump_target_i,

  input drain_complete_i,
  input drain_pending_arch_trap_i,
  input drain_pending_system_i,
  input drain_pending_system_ecall_i,
  input drain_pending_system_irq_i,
  input drain_pending_system_mret_i,
  input [`XLEN-1:0] pending_system_pc_i,
  input [`INST_W-1:0] pending_system_inst_i,
  input [`XLEN-1:0] pending_system_next_pc_i,
  input [`XLEN-1:0] csr_ret_target_i,

  input drain_pending_branch_undispatched_i,
  input drain_pending_branch_misaligned_i,
  input [`XLEN-1:0] pending_branch_pc_i,
  input [`INST_W-1:0] pending_branch_inst_i,
  input [`XLEN-1:0] pending_branch_next_pc_i,

  input drain_pending_jump_i,
  input drain_pending_mem_i,

  // 【serialize-at-retire Phase1 §9】head0-CSR 队头提交脉冲(已被 OooRob 的 mem_quiet 门控, 只在 mem
  // 全静默拍拉高)。复活 core_serial_flush(此前恒 0 死信号): 提交拍触发 1 拍脉冲, 镜像 trap flush 时序,
  // 刷 younger + phys-recover + 前端 redirect。因 mem 已静默, serial_flush→lsu_axi_abort 中止不了任何东西。
  input head0_csr_commit_i,


  output ctrl_commit_valid_o,
  output [`XLEN-1:0] ctrl_commit_pc_o,
  output [`INST_W-1:0] ctrl_commit_inst_o,
  output [`XLEN-1:0] ctrl_commit_next_pc_o,
  output ctrl_commit_rd_en_o,
  output [`REG_ADDR_W-1:0] ctrl_commit_rd_addr_o,
  output [`XLEN-1:0] ctrl_commit_rd_data_o,
  output ctrl_commit_write_o,
  output core_serial_flush_o
);

  reg valid_q;
  reg [`XLEN-1:0] pc_q;
  reg [`INST_W-1:0] inst_q;
  reg [`XLEN-1:0] next_pc_q;
  reg rd_en_q;
  reg [`REG_ADDR_W-1:0] rd_addr_q;
  reg [`XLEN-1:0] rd_data_q;
  reg write_q;
  reg serial_flush_q;

  wire drain_system_commit_w =
      drain_complete_i && !drain_pending_arch_trap_i &&
      drain_pending_system_i &&
      (drain_pending_system_mret_i ||
       !(drain_pending_system_ecall_i || drain_pending_system_irq_i));
  wire drain_branch_commit_w =
      drain_complete_i && !drain_pending_arch_trap_i &&
      !drain_pending_system_i &&
      drain_pending_branch_undispatched_i &&
      !drain_pending_branch_misaligned_i;
  // 【B-FP 簇】pending-FP 壳已拆: drain_fp_commit 臂删除(FP 经 ROB 真 commit)。
  wire any_drain_commit_w =
      drain_system_commit_w || drain_branch_commit_w;

  always @(posedge clk) begin
    if (rst) begin
      valid_q <= 1'b0;
      pc_q <= {`XLEN{1'b0}};
      inst_q <= {`INST_W{1'b0}};
      next_pc_q <= {`XLEN{1'b0}};
      rd_en_q <= 1'b0;
      rd_addr_q <= {`REG_ADDR_W{1'b0}};
      rd_data_q <= {`XLEN{1'b0}};
      write_q <= 1'b0;
      serial_flush_q <= 1'b0;
    end else begin
      valid_q <= 1'b0;
      rd_en_q <= 1'b0;
      rd_addr_q <= {`REG_ADDR_W{1'b0}};
      rd_data_q <= {`XLEN{1'b0}};
      write_q <= 1'b0;
      // 【serialize Phase1 §9】复活 serial_flush: head0-CSR 提交拍(mem 静默) → 下拍 1 拍 flush 脉冲。
      serial_flush_q <= head0_csr_commit_i;

      if (pending_jump_nolink_commit_i) begin
        valid_q <= 1'b1;
        pc_q <= pending_jump_pc_i;
        inst_q <= pending_jump_inst_i;
        next_pc_q <= pending_jump_target_i;
      end else if (any_drain_commit_w) begin
        valid_q <= 1'b1;
        if (drain_system_commit_w) begin
          pc_q <= pending_system_pc_i;
          inst_q <= pending_system_inst_i;
          next_pc_q <= drain_pending_system_mret_i ?
                       csr_ret_target_i : pending_system_next_pc_i;
        end else if (drain_branch_commit_w) begin
          pc_q <= pending_branch_pc_i;
          inst_q <= pending_branch_inst_i;
          next_pc_q <= pending_branch_next_pc_i;
        end
      end
    end
  end

  assign ctrl_commit_valid_o = valid_q;
  assign ctrl_commit_pc_o = pc_q;
  assign ctrl_commit_inst_o = inst_q;
  assign ctrl_commit_next_pc_o = next_pc_q;
  assign ctrl_commit_rd_en_o = rd_en_q;
  assign ctrl_commit_rd_addr_o = rd_addr_q;
  assign ctrl_commit_rd_data_o = rd_data_q;
  assign ctrl_commit_write_o = write_q;
  assign core_serial_flush_o = serial_flush_q;

endmodule
