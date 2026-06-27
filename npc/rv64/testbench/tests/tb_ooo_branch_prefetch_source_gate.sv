`include "define.v"
`include "tb_common.svh"

module tb_ooo_branch_prefetch_source_gate;
  reg [`XLEN-1:0] pending_branch_pc;
  reg [`XLEN-1:0] pending_branch_imm;
  reg [`XLEN-1:0] pending_branch_next_pc;
  reg pending_branch_pred_taken;
  reg stop_pending;
  reg pending_jump;
  reg pending_jump_jalr;
  reg [`REG_ADDR_W-1:0] pending_jump_rd;
  reg [`REG_ADDR_W-1:0] pending_jump_rs1;
  reg [`XLEN-1:0] pending_jump_imm;
  reg ras_empty;

  wire [`XLEN-1:0] pending_branch_target;
  wire [`XLEN-1:0] branch_pred_pc;
  wire jalr_ret_hint;
  wire jalr_btb_lookup;

  OooBranchPrefetchSourceGate dut (
    .pending_branch_pc_i(pending_branch_pc),
    .pending_branch_imm_i(pending_branch_imm),
    .pending_branch_next_pc_i(pending_branch_next_pc),
    .pending_branch_pred_taken_i(pending_branch_pred_taken),
    .stop_pending_i(stop_pending),
    .pending_jump_i(pending_jump),
    .pending_jump_jalr_i(pending_jump_jalr),
    .pending_jump_rd_i(pending_jump_rd),
    .pending_jump_rs1_i(pending_jump_rs1),
    .pending_jump_imm_i(pending_jump_imm),
    .ras_empty_i(ras_empty),
    .pending_branch_target_o(pending_branch_target),
    .branch_pred_pc_o(branch_pred_pc),
    .jalr_ret_hint_o(jalr_ret_hint),
    .jalr_btb_lookup_o(jalr_btb_lookup)
  );

  task automatic check_xlen;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  task automatic reset_inputs;
    begin
      pending_branch_pc = 64'h0000_0000_0000_4000;
      pending_branch_imm = 64'h0000_0000_0000_0010;
      pending_branch_next_pc = 64'h0000_0000_0000_4004;
      pending_branch_pred_taken = 1'b0;
      stop_pending = 1'b1;
      pending_jump = 1'b0;
      pending_jump_jalr = 1'b0;
      pending_jump_rd = 5'd0;
      pending_jump_rs1 = 5'd1;
      pending_jump_imm = {`XLEN{1'b0}};
      ras_empty = 1'b1;
      #1;
    end
  endtask

  task automatic set_ret_hint_base;
    begin
      reset_inputs();
      pending_jump = 1'b1;
      pending_jump_jalr = 1'b1;
      pending_jump_rd = 5'd0;
      pending_jump_rs1 = 5'd1;
      pending_jump_imm = {`XLEN{1'b0}};
      ras_empty = 1'b1;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    check_xlen("branch target", pending_branch_target,
               64'h0000_0000_0000_4010);
    check_xlen("not taken predicts fallthrough", branch_pred_pc,
               64'h0000_0000_0000_4004);

    reset_inputs();
    pending_branch_pred_taken = 1'b1;
    #1;
    check_xlen("taken predicts target", branch_pred_pc,
               64'h0000_0000_0000_4010);

    set_ret_hint_base();
    tb_check1("ret hint x1", jalr_ret_hint, 1'b1);
    tb_check1("ras empty allows btb fallback", jalr_btb_lookup, 1'b1);

    set_ret_hint_base();
    pending_jump_rs1 = 5'd5;
    #1;
    tb_check1("ret hint x5", jalr_ret_hint, 1'b1);

    set_ret_hint_base();
    ras_empty = 1'b0;
    #1;
    tb_check1("ras nonempty suppresses btb ret lookup", jalr_btb_lookup,
              1'b0);

    set_ret_hint_base();
    pending_jump_rd = 5'd1;
    #1;
    tb_check1("nonzero rd is not ret hint", jalr_ret_hint, 1'b0);
    tb_check1("non-ret jalr still looks up btb", jalr_btb_lookup, 1'b1);

    set_ret_hint_base();
    pending_jump_rs1 = 5'd2;
    #1;
    tb_check1("non link rs1 is not ret hint", jalr_ret_hint, 1'b0);

    set_ret_hint_base();
    pending_jump_imm = 64'h0000_0000_0000_0004;
    #1;
    tb_check1("nonzero imm is not ret hint", jalr_ret_hint, 1'b0);

    set_ret_hint_base();
    stop_pending = 1'b0;
    #1;
    tb_check1("btb lookup requires stop pending", jalr_btb_lookup, 1'b0);

    set_ret_hint_base();
    pending_jump = 1'b0;
    #1;
    tb_check1("ret hint requires pending jump", jalr_ret_hint, 1'b0);
    tb_check1("btb lookup requires pending jump", jalr_btb_lookup, 1'b0);

    set_ret_hint_base();
    pending_jump_jalr = 1'b0;
    #1;
    tb_check1("ret hint requires jalr", jalr_ret_hint, 1'b0);
    tb_check1("btb lookup requires jalr", jalr_btb_lookup, 1'b0);

    tb_finish("tb_ooo_branch_prefetch_source_gate");
  end

endmodule
