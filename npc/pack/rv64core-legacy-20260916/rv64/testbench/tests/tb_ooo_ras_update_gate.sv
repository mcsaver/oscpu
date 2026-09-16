`include "define.v"

module tb_ooo_ras_update_gate;
  `include "tb_common.svh"

  reg priv_predictor_boundary;
  reg branch_spec_restore;
  reg branch_resolve_untracked;
  reg direct_jal_call_unsafe;
  reg direct_ret0_fire;
  reg direct_ret1_fire;
  reg pending_jump_return_fire;
  reg direct_branch0_lane1_ret;
  reg direct_jal_call;
  reg pending_jump_call_fire;
  reg [`XLEN-1:0] pending_jump_next_pc;
  reg [`XLEN-1:0] direct_jal_link;

  wire ras_clear;
  wire ras_pop;
  wire ras_push;
  wire [`XLEN-1:0] ras_push_value;

  OooRasUpdateGate dut (
    .priv_predictor_boundary_i(priv_predictor_boundary),
    .branch_spec_restore_i(branch_spec_restore),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .direct_jal_call_unsafe_i(direct_jal_call_unsafe),
    .direct_ret0_fire_i(direct_ret0_fire),
    .direct_ret1_fire_i(direct_ret1_fire),
    .pending_jump_return_fire_i(pending_jump_return_fire),
    .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret),
    .direct_jal_call_i(direct_jal_call),
    .pending_jump_call_fire_i(pending_jump_call_fire),
    .pending_jump_next_pc_i(pending_jump_next_pc),
    .direct_jal_link_i(direct_jal_link),
    .ras_clear_o(ras_clear),
    .ras_pop_o(ras_pop),
    .ras_push_o(ras_push),
    .ras_push_value_o(ras_push_value)
  );

  task automatic tb_check64;
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

  task automatic clear_inputs;
    begin
      priv_predictor_boundary = 1'b0;
      branch_spec_restore = 1'b0;
      branch_resolve_untracked = 1'b0;
      direct_jal_call_unsafe = 1'b0;
      direct_ret0_fire = 1'b0;
      direct_ret1_fire = 1'b0;
      pending_jump_return_fire = 1'b0;
      direct_branch0_lane1_ret = 1'b0;
      direct_jal_call = 1'b0;
      pending_jump_call_fire = 1'b0;
      pending_jump_next_pc = 64'h0000_0000_8000_4000;
      direct_jal_link = 64'h0000_0000_8000_1004;
    end
  endtask

  task automatic check_clear_source;
    input [1023:0] label;
    begin
      #1;
      tb_check1(label, ras_clear, 1'b1);
      clear_inputs();
    end
  endtask

  task automatic check_pop_source;
    input [1023:0] label;
    begin
      #1;
      tb_check1(label, ras_pop, 1'b1);
      clear_inputs();
    end
  endtask

  initial begin
    tb_errors = 0;
    clear_inputs();
    #1;
    tb_check1("idle clear", ras_clear, 1'b0);
    tb_check1("idle pop", ras_pop, 1'b0);
    tb_check1("idle push", ras_push, 1'b0);
    tb_check64("idle push value direct fallthrough",
               ras_push_value, 64'h0000_0000_8000_1004);

    priv_predictor_boundary = 1'b1;
    check_clear_source("priv predictor boundary clears ras");
    branch_spec_restore = 1'b1;
    check_clear_source("branch spec restore clears ras");
    branch_resolve_untracked = 1'b1;
    check_clear_source("untracked resolve clears ras");
    direct_jal_call_unsafe = 1'b1;
    check_clear_source("unsafe direct jal call clears ras");

    direct_ret0_fire = 1'b1;
    check_pop_source("direct ret0 pops ras");
    direct_ret1_fire = 1'b1;
    check_pop_source("direct ret1 pops ras");
    pending_jump_return_fire = 1'b1;
    check_pop_source("pending jump return pops ras");
    direct_branch0_lane1_ret = 1'b1;
    check_pop_source("direct branch lane1 ret pops ras");

    direct_jal_call = 1'b1;
    #1;
    tb_check1("direct jal call pushes ras", ras_push, 1'b1);
    tb_check64("direct jal call push value",
               ras_push_value, 64'h0000_0000_8000_1004);

    pending_jump_call_fire = 1'b1;
    pending_jump_next_pc = 64'h0000_0000_8000_5000;
    #1;
    tb_check1("pending jump call pushes ras", ras_push, 1'b1);
    tb_check64("pending jump call push value priority",
               ras_push_value, 64'h0000_0000_8000_5000);

    direct_jal_call = 1'b0;
    #1;
    tb_check1("pending-only push", ras_push, 1'b1);
    tb_check64("pending-only push value",
               ras_push_value, 64'h0000_0000_8000_5000);

    tb_finish("tb_ooo_ras_update_gate");
  end
endmodule
