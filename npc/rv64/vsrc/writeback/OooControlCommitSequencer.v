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

  input drain_pending_fp_i,
  input pending_fp_gpr_write_i,
  input [`XLEN-1:0] pending_fp_pc_i,
  input [`INST_W-1:0] pending_fp_inst_i,
  input [`XLEN-1:0] pending_fp_next_pc_i,
  input [`REG_ADDR_W-1:0] pending_fp_rd_i,
  input [`XLEN-1:0] pending_fp_result_value_i,

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
  wire drain_fp_commit_w =
      drain_complete_i && !drain_pending_arch_trap_i &&
      !drain_pending_system_i &&
      !drain_pending_branch_undispatched_i &&
      !drain_pending_jump_i &&
      !drain_pending_mem_i &&
      drain_pending_fp_i;
  wire any_drain_commit_w =
      drain_system_commit_w || drain_branch_commit_w || drain_fp_commit_w;
  wire fp_write_x0_w =
      pending_fp_rd_i == {`REG_ADDR_W{1'b0}};

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
      serial_flush_q <= 1'b0;

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
        end else begin
          pc_q <= pending_fp_pc_i;
          inst_q <= pending_fp_inst_i;
          next_pc_q <= pending_fp_next_pc_i;
          rd_en_q <= pending_fp_gpr_write_i;
          rd_addr_q <= pending_fp_rd_i;
          rd_data_q <= pending_fp_result_value_i;
          write_q <= pending_fp_gpr_write_i && !fp_write_x0_w;
          serial_flush_q <= pending_fp_gpr_write_i;
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
