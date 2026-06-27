`include "define.v"

module OooCommitOutputMux (
  input ctrl_commit_valid_i,
  input [`XLEN-1:0] ctrl_commit_pc_i,
  input [`INST_W-1:0] ctrl_commit_inst_i,
  input [`XLEN-1:0] ctrl_commit_next_pc_i,
  input ctrl_commit_rd_en_i,
  input [`REG_ADDR_W-1:0] ctrl_commit_rd_addr_i,
  input [`XLEN-1:0] ctrl_commit_rd_data_i,
  input ctrl_commit_write_i,

  input synth_lane1_branch_append_i,
  input [`XLEN-1:0] synth_branch_append_pc_i,
  input [`INST_W-1:0] synth_branch_append_inst_i,
  input [`XLEN-1:0] synth_branch_append_next_pc_i,

  input synth_lane1_ret_before_core0_i,
  input synth_lane1_ret_after_core0_i,
  input synth_lane1_ret_drop_branch_i,
  input [`XLEN-1:0] synth_lane1_ret_pc_i,
  input [`INST_W-1:0] synth_lane1_ret_inst_i,
  input [`XLEN-1:0] synth_lane1_ret_next_pc_i,

  input core_commit0_valid_i,
  input [`XLEN-1:0] core_commit0_pc_i,
  input [`XLEN-1:0] core_commit0_next_pc_i,
  input [`INST_W-1:0] core_commit0_inst_i,
  input core_commit0_rd_en_i,
  input [`REG_ADDR_W-1:0] core_commit0_rd_addr_i,
  input [`XLEN-1:0] core_commit0_rd_data_i,
  input core_commit0_exception_i,
  input core_commit0_write_i,

  input core_commit1_valid_i,
  input [`XLEN-1:0] core_commit1_pc_i,
  input [`XLEN-1:0] core_commit1_next_pc_i,
  input [`INST_W-1:0] core_commit1_inst_i,
  input core_commit1_rd_en_i,
  input [`REG_ADDR_W-1:0] core_commit1_rd_addr_i,
  input [`XLEN-1:0] core_commit1_rd_data_i,
  input core_commit1_exception_i,
  input core_commit1_write_i,

  input [1:0] core_retire_count_i,

  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_rd_addr_o,
  output [`XLEN-1:0] commit0_rd_data_o,
  output commit0_exception_o,
  output commit0_write_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_rd_addr_o,
  output [`XLEN-1:0] commit1_rd_data_o,
  output commit1_exception_o,
  output commit1_write_o,

  output [1:0] retire_count_o
);

  function [`XLEN-1:0] rv32_imm_j;
    input [`INST_W-1:0] inst;
    begin
      rv32_imm_j = {{(`XLEN-21){inst[31]}}, inst[31], inst[19:12],
                    inst[20], inst[30:21], 1'b0};
    end
  endfunction

  wire core_commit0_jal_w =
      core_commit0_valid_i && (core_commit0_inst_i[6:0] == `OPCODE_JAL);
  wire core_commit1_jal_w =
      core_commit1_valid_i && (core_commit1_inst_i[6:0] == `OPCODE_JAL);
  wire [`XLEN-1:0] core_commit0_arch_next_pc_w =
      core_commit0_jal_w ?
      (core_commit0_pc_i + rv32_imm_j(core_commit0_inst_i)) :
      core_commit0_next_pc_i;
  wire [`XLEN-1:0] core_commit1_arch_next_pc_w =
      core_commit1_jal_w ?
      (core_commit1_pc_i + rv32_imm_j(core_commit1_inst_i)) :
      core_commit1_next_pc_i;
  wire synth_lane1_ret_commit_w =
      synth_lane1_ret_before_core0_i ||
      synth_lane1_ret_after_core0_i ||
      synth_lane1_ret_drop_branch_i;

  assign commit0_valid_o =
      ctrl_commit_valid_i ? 1'b1 :
      (synth_lane1_ret_before_core0_i ||
       synth_lane1_ret_drop_branch_i) ? 1'b1 :
      core_commit0_valid_i;
  assign commit0_pc_o =
      ctrl_commit_valid_i ? ctrl_commit_pc_i :
      (synth_lane1_ret_before_core0_i ||
       synth_lane1_ret_drop_branch_i) ? synth_lane1_ret_pc_i :
      core_commit0_pc_i;
  assign commit0_inst_o =
      ctrl_commit_valid_i ? ctrl_commit_inst_i :
      (synth_lane1_ret_before_core0_i ||
       synth_lane1_ret_drop_branch_i) ? synth_lane1_ret_inst_i :
      core_commit0_inst_i;
  assign commit0_next_pc_o =
      ctrl_commit_valid_i ? ctrl_commit_next_pc_i :
      (synth_lane1_ret_before_core0_i ||
       synth_lane1_ret_drop_branch_i) ? synth_lane1_ret_next_pc_i :
      core_commit0_arch_next_pc_w;
  assign commit0_rd_en_o =
      ctrl_commit_valid_i ? ctrl_commit_rd_en_i :
      (synth_lane1_ret_before_core0_i || synth_lane1_ret_drop_branch_i) ?
      1'b0 : core_commit0_rd_en_i;
  assign commit0_rd_addr_o =
      ctrl_commit_valid_i ? ctrl_commit_rd_addr_i :
      (synth_lane1_ret_before_core0_i || synth_lane1_ret_drop_branch_i) ?
      {`REG_ADDR_W{1'b0}} : core_commit0_rd_addr_i;
  assign commit0_rd_data_o =
      ctrl_commit_valid_i ? ctrl_commit_rd_data_i :
      (synth_lane1_ret_before_core0_i || synth_lane1_ret_drop_branch_i) ?
      {`XLEN{1'b0}} : core_commit0_rd_data_i;
  assign commit0_exception_o =
      (ctrl_commit_valid_i || synth_lane1_ret_before_core0_i ||
       synth_lane1_ret_drop_branch_i) ?
      1'b0 : core_commit0_exception_i;
  assign commit0_write_o =
      ctrl_commit_valid_i ? ctrl_commit_write_i :
      (synth_lane1_ret_before_core0_i || synth_lane1_ret_drop_branch_i) ?
      1'b0 : core_commit0_write_i;

  assign commit1_valid_o =
      ctrl_commit_valid_i ? 1'b0 :
      synth_lane1_branch_append_i ? 1'b1 :
      synth_lane1_ret_after_core0_i ? 1'b1 :
      synth_lane1_ret_before_core0_i ? core_commit0_valid_i :
      synth_lane1_ret_drop_branch_i ? core_commit1_valid_i :
      core_commit1_valid_i;
  assign commit1_pc_o =
      ctrl_commit_valid_i ? {`XLEN{1'b0}} :
      synth_lane1_branch_append_i ? synth_branch_append_pc_i :
      synth_lane1_ret_after_core0_i ? synth_lane1_ret_pc_i :
      synth_lane1_ret_before_core0_i ? core_commit0_pc_i :
      synth_lane1_ret_drop_branch_i ? core_commit1_pc_i :
      core_commit1_pc_i;
  assign commit1_inst_o =
      ctrl_commit_valid_i ? {`INST_W{1'b0}} :
      synth_lane1_branch_append_i ? synth_branch_append_inst_i :
      synth_lane1_ret_after_core0_i ? synth_lane1_ret_inst_i :
      synth_lane1_ret_before_core0_i ? core_commit0_inst_i :
      synth_lane1_ret_drop_branch_i ? core_commit1_inst_i :
      core_commit1_inst_i;
  assign commit1_next_pc_o =
      ctrl_commit_valid_i ? {`XLEN{1'b0}} :
      synth_lane1_branch_append_i ? synth_branch_append_next_pc_i :
      synth_lane1_ret_after_core0_i ? synth_lane1_ret_next_pc_i :
      synth_lane1_ret_before_core0_i ? core_commit0_arch_next_pc_w :
      synth_lane1_ret_drop_branch_i ? core_commit1_arch_next_pc_w :
      core_commit1_arch_next_pc_w;
  assign commit1_rd_en_o =
      (ctrl_commit_valid_i || synth_lane1_branch_append_i ||
       synth_lane1_ret_after_core0_i) ?
      1'b0 :
      synth_lane1_ret_before_core0_i ? core_commit0_rd_en_i :
      synth_lane1_ret_drop_branch_i ? core_commit1_rd_en_i :
      core_commit1_rd_en_i;
  assign commit1_rd_addr_o =
      (ctrl_commit_valid_i || synth_lane1_branch_append_i ||
       synth_lane1_ret_after_core0_i) ?
      {`REG_ADDR_W{1'b0}} :
      synth_lane1_ret_before_core0_i ? core_commit0_rd_addr_i :
      synth_lane1_ret_drop_branch_i ? core_commit1_rd_addr_i :
      core_commit1_rd_addr_i;
  assign commit1_rd_data_o =
      (ctrl_commit_valid_i || synth_lane1_branch_append_i ||
       synth_lane1_ret_after_core0_i) ?
      {`XLEN{1'b0}} :
      synth_lane1_ret_before_core0_i ? core_commit0_rd_data_i :
      synth_lane1_ret_drop_branch_i ? core_commit1_rd_data_i :
      core_commit1_rd_data_i;
  assign commit1_exception_o =
      (ctrl_commit_valid_i || synth_lane1_branch_append_i ||
       synth_lane1_ret_after_core0_i) ?
      1'b0 :
      synth_lane1_ret_before_core0_i ? core_commit0_exception_i :
      synth_lane1_ret_drop_branch_i ? core_commit1_exception_i :
      core_commit1_exception_i;
  assign commit1_write_o =
      (ctrl_commit_valid_i || synth_lane1_branch_append_i ||
       synth_lane1_ret_after_core0_i) ?
      1'b0 :
      synth_lane1_ret_before_core0_i ? core_commit0_write_i :
      synth_lane1_ret_drop_branch_i ? core_commit1_write_i :
      core_commit1_write_i;

  assign retire_count_o = core_retire_count_i +
                          {1'b0, ctrl_commit_valid_i} +
                          {1'b0, synth_lane1_branch_append_i} +
                          {1'b0, synth_lane1_ret_commit_w} -
                          {1'b0, synth_lane1_ret_drop_branch_i};

endmodule
