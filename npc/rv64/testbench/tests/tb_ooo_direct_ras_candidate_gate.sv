`include "define.v"

module tb_ooo_direct_ras_candidate_gate;
  `include "tb_common.svh"

  reg head0_jal_raw;
  reg [`REG_ADDR_W-1:0] head0_rd;
  reg head1_jal_raw;
  reg [`REG_ADDR_W-1:0] head1_rd;
  reg [4:0] rob_count;
  reg stop_pending;
  reg branch_spec_active;
  reg branch_spec_checkpoint_pending;
  reg dispatch0_jump;
  reg [`REG_ADDR_W-1:0] head0_rs1;
  reg [`XLEN-1:0] head0_imm;
  reg head1_jalr_raw;
  reg [`REG_ADDR_W-1:0] head1_rs1;
  reg [`XLEN-1:0] head1_imm;
  reg ras_reliable;
  reg ras_empty;

  wire head0_jal_call_raw;
  wire head1_jal_call_raw;
  wire ras_direct_update_safe;
  wire dispatch0_return;
  wire head1_return_candidate;
  wire dispatch0_return_disabled;
  wire head1_return_candidate_disabled;

  OooDirectRasCandidateGate #(
    .ROB_COUNT_W(5),
    .ENABLE_DIRECT_RAS_RET(1'b1)
  ) dut (
    .head0_jal_raw_i(head0_jal_raw),
    .head0_rd_i(head0_rd),
    .head1_jal_raw_i(head1_jal_raw),
    .head1_rd_i(head1_rd),
    .rob_count_i(rob_count),
    .stop_pending_i(stop_pending),
    .branch_spec_active_i(branch_spec_active),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending),
    .dispatch0_jump_i(dispatch0_jump),
    .head0_rs1_i(head0_rs1),
    .head0_imm_i(head0_imm),
    .head1_jalr_raw_i(head1_jalr_raw),
    .head1_rs1_i(head1_rs1),
    .head1_imm_i(head1_imm),
    .ras_reliable_i(ras_reliable),
    .ras_empty_i(ras_empty),
    .head0_jal_call_raw_o(head0_jal_call_raw),
    .head1_jal_call_raw_o(head1_jal_call_raw),
    .ras_direct_update_safe_o(ras_direct_update_safe),
    .dispatch0_return_o(dispatch0_return),
    .head1_return_candidate_o(head1_return_candidate)
  );

  OooDirectRasCandidateGate #(
    .ROB_COUNT_W(5),
    .ENABLE_DIRECT_RAS_RET(1'b0)
  ) dut_disabled (
    .head0_jal_raw_i(head0_jal_raw),
    .head0_rd_i(head0_rd),
    .head1_jal_raw_i(head1_jal_raw),
    .head1_rd_i(head1_rd),
    .rob_count_i(rob_count),
    .stop_pending_i(stop_pending),
    .branch_spec_active_i(branch_spec_active),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending),
    .dispatch0_jump_i(dispatch0_jump),
    .head0_rs1_i(head0_rs1),
    .head0_imm_i(head0_imm),
    .head1_jalr_raw_i(head1_jalr_raw),
    .head1_rs1_i(head1_rs1),
    .head1_imm_i(head1_imm),
    .ras_reliable_i(ras_reliable),
    .ras_empty_i(ras_empty),
    .head0_jal_call_raw_o(),
    .head1_jal_call_raw_o(),
    .ras_direct_update_safe_o(),
    .dispatch0_return_o(dispatch0_return_disabled),
    .head1_return_candidate_o(head1_return_candidate_disabled)
  );

  task automatic clear_inputs;
    begin
      head0_jal_raw = 1'b0;
      head0_rd = {`REG_ADDR_W{1'b0}};
      head1_jal_raw = 1'b0;
      head1_rd = {`REG_ADDR_W{1'b0}};
      rob_count = 5'd0;
      stop_pending = 1'b0;
      branch_spec_active = 1'b0;
      branch_spec_checkpoint_pending = 1'b0;
      dispatch0_jump = 1'b0;
      head0_rs1 = {`REG_ADDR_W{1'b0}};
      head0_imm = {`XLEN{1'b0}};
      head1_jalr_raw = 1'b0;
      head1_rs1 = {`REG_ADDR_W{1'b0}};
      head1_imm = {`XLEN{1'b0}};
      ras_reliable = 1'b1;
      ras_empty = 1'b0;
    end
  endtask

  task automatic set_lane0_return_ready;
    begin
      dispatch0_jump = 1'b1;
      head0_rd = {`REG_ADDR_W{1'b0}};
      head0_rs1 = 5'd1;
      head0_imm = {`XLEN{1'b0}};
      rob_count = 5'd0;
      stop_pending = 1'b0;
      branch_spec_active = 1'b0;
      branch_spec_checkpoint_pending = 1'b0;
      ras_reliable = 1'b1;
      ras_empty = 1'b0;
    end
  endtask

  task automatic set_lane1_return_ready;
    begin
      head1_jalr_raw = 1'b1;
      head1_rd = {`REG_ADDR_W{1'b0}};
      head1_rs1 = 5'd5;
      head1_imm = {`XLEN{1'b0}};
      rob_count = 5'd0;
      stop_pending = 1'b0;
      branch_spec_active = 1'b0;
      branch_spec_checkpoint_pending = 1'b0;
      ras_reliable = 1'b1;
      ras_empty = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;

    clear_inputs();
    head0_jal_raw = 1'b1;
    head0_rd = 5'd1;
    head1_jal_raw = 1'b1;
    head1_rd = 5'd5;
    #1;
    tb_check1("head0 jal x1 call", head0_jal_call_raw, 1'b1);
    tb_check1("head1 jal x5 call", head1_jal_call_raw, 1'b1);
    head0_rd = 5'd2;
    head1_rd = {`REG_ADDR_W{1'b0}};
    #1;
    tb_check1("head0 jal rd x2 not call", head0_jal_call_raw, 1'b0);
    tb_check1("head1 jal rd x0 not call", head1_jal_call_raw, 1'b0);

    clear_inputs();
    #1;
    tb_check1("ras safe idle", ras_direct_update_safe, 1'b1);
    rob_count = 5'd1;
    #1;
    tb_check1("rob non-empty blocks ras safe", ras_direct_update_safe, 1'b0);
    rob_count = 5'd0;
    stop_pending = 1'b1;
    #1;
    tb_check1("stop pending blocks ras safe", ras_direct_update_safe, 1'b0);
    stop_pending = 1'b0;
    branch_spec_active = 1'b1;
    #1;
    tb_check1("branch spec active blocks ras safe", ras_direct_update_safe, 1'b0);
    branch_spec_active = 1'b0;
    branch_spec_checkpoint_pending = 1'b1;
    #1;
    tb_check1("checkpoint pending blocks ras safe",
              ras_direct_update_safe, 1'b0);

    clear_inputs();
    set_lane0_return_ready();
    #1;
    tb_check1("lane0 return positive", dispatch0_return, 1'b1);
    tb_check1("lane0 return disabled by parameter",
              dispatch0_return_disabled, 1'b0);
    dispatch0_jump = 1'b0;
    #1;
    tb_check1("lane0 no jump blocks return", dispatch0_return, 1'b0);
    set_lane0_return_ready();
    head0_rd = 5'd1;
    #1;
    tb_check1("lane0 rd nonzero blocks return", dispatch0_return, 1'b0);
    set_lane0_return_ready();
    head0_rs1 = 5'd2;
    #1;
    tb_check1("lane0 rs1 non-link blocks return", dispatch0_return, 1'b0);
    set_lane0_return_ready();
    head0_imm = 64'd4;
    #1;
    tb_check1("lane0 imm nonzero blocks return", dispatch0_return, 1'b0);
    set_lane0_return_ready();
    ras_reliable = 1'b0;
    #1;
    tb_check1("lane0 unreliable ras blocks return", dispatch0_return, 1'b0);
    set_lane0_return_ready();
    ras_empty = 1'b1;
    #1;
    tb_check1("lane0 empty ras blocks return", dispatch0_return, 1'b0);

    clear_inputs();
    set_lane1_return_ready();
    #1;
    tb_check1("lane1 return positive", head1_return_candidate, 1'b1);
    tb_check1("lane1 return disabled by parameter",
              head1_return_candidate_disabled, 1'b0);
    head1_jalr_raw = 1'b0;
    #1;
    tb_check1("lane1 no jalr blocks return", head1_return_candidate, 1'b0);
    set_lane1_return_ready();
    head1_rd = 5'd1;
    #1;
    tb_check1("lane1 rd nonzero blocks return", head1_return_candidate, 1'b0);
    set_lane1_return_ready();
    head1_rs1 = 5'd2;
    #1;
    tb_check1("lane1 rs1 non-link blocks return", head1_return_candidate, 1'b0);
    set_lane1_return_ready();
    head1_imm = 64'd8;
    #1;
    tb_check1("lane1 imm nonzero blocks return", head1_return_candidate, 1'b0);

    tb_finish("tb_ooo_direct_ras_candidate_gate");
  end
endmodule
