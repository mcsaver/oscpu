`include "tb_common.svh"
`include "define.v"

module tb_ooo_branch_spec_tracker;
  reg clk;
  reg rst;
  reg csr_trap_clear;
  reg direct_frontend_flush;
  reg direct_branch_fire;
  reg direct_branch_resolve_redirect;
  reg direct_branch_spec_start;
  reg [`XLEN-1:0] direct_branch_pred_pc;
  reg checkpoint_capture;
  reg resolve_valid;
  reg pending_branch_commit_resolve;
  reg pending_branch_match_clear;
  reg branch_resolve_untracked;

  wire active;
  wire checkpoint_pending;
  wire [`XLEN-1:0] pred_pc;

  OooBranchSpecTracker dut (
    .clk(clk),
    .rst(rst),
    .csr_trap_clear_i(csr_trap_clear),
    .direct_frontend_flush_i(direct_frontend_flush),
    .direct_branch_fire_i(direct_branch_fire),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect),
    .direct_branch_spec_start_i(direct_branch_spec_start),
    .direct_branch_pred_pc_i(direct_branch_pred_pc),
    .checkpoint_capture_i(checkpoint_capture),
    .resolve_valid_i(resolve_valid),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve),
    .pending_branch_match_clear_i(pending_branch_match_clear),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .active_o(active),
    .checkpoint_pending_o(checkpoint_pending),
    .pred_pc_o(pred_pc)
  );

  task automatic tick;
    begin
      #1 clk = 1'b1;
      #1 clk = 1'b0;
    end
  endtask

  task automatic clear_inputs;
    begin
      csr_trap_clear = 1'b0;
      direct_frontend_flush = 1'b0;
      direct_branch_fire = 1'b0;
      direct_branch_resolve_redirect = 1'b0;
      direct_branch_spec_start = 1'b0;
      direct_branch_pred_pc = {`XLEN{1'b0}};
      checkpoint_capture = 1'b0;
      resolve_valid = 1'b0;
      pending_branch_commit_resolve = 1'b0;
      pending_branch_match_clear = 1'b0;
      branch_resolve_untracked = 1'b0;
    end
  endtask

  task automatic check_state;
    input [1023:0] what;
    input exp_active;
    input exp_pending;
    input [`XLEN-1:0] exp_pred_pc;
    begin
      tb_check1({what, " active"}, active, exp_active);
      tb_check1({what, " pending"}, checkpoint_pending, exp_pending);
      if (pred_pc !== exp_pred_pc) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s pred_pc got=0x%016x expected=0x%016x",
                 what, pred_pc, exp_pred_pc);
      end
    end
  endtask

  task automatic start_spec;
    input [`XLEN-1:0] pc;
    begin
      clear_inputs();
      direct_frontend_flush = 1'b1;
      direct_branch_fire = 1'b1;
      direct_branch_spec_start = 1'b1;
      direct_branch_pred_pc = pc;
      tick();
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    tb_errors = 0;
    clear_inputs();

    tick();
    check_state("reset clears branch spec state", 1'b0, 1'b0, {`XLEN{1'b0}});

    rst = 1'b0;
    start_spec(64'h0000_0000_8000_1234);
    check_state("direct branch spec start creates pending", 1'b0, 1'b1,
                64'h0000_0000_8000_1234);

    clear_inputs();
    checkpoint_capture = 1'b1;
    tick();
    check_state("checkpoint capture enters active and retains pred pc", 1'b1,
                1'b0, 64'h0000_0000_8000_1234);

    clear_inputs();
    resolve_valid = 1'b1;
    tick();
    check_state("resolve clears active state", 1'b0, 1'b0, {`XLEN{1'b0}});

    start_spec(64'h0000_0000_8000_2000);
    clear_inputs();
    direct_frontend_flush = 1'b1;
    checkpoint_capture = 1'b1;
    tick();
    check_state("direct flush suppresses capture", 1'b0, 1'b0, {`XLEN{1'b0}});

    start_spec(64'h0000_0000_8000_3000);
    clear_inputs();
    pending_branch_commit_resolve = 1'b1;
    tick();
    check_state("commit fallback clears pending", 1'b0, 1'b0, {`XLEN{1'b0}});

    start_spec(64'h0000_0000_8000_4000);
    clear_inputs();
    checkpoint_capture = 1'b1;
    tick();
    clear_inputs();
    pending_branch_match_clear = 1'b1;
    tick();
    check_state("pending branch match clears active", 1'b0, 1'b0,
                {`XLEN{1'b0}});

    start_spec(64'h0000_0000_8000_5000);
    clear_inputs();
    branch_resolve_untracked = 1'b1;
    tick();
    check_state("untracked recovery clears pending", 1'b0, 1'b0,
                {`XLEN{1'b0}});

    clear_inputs();
    csr_trap_clear = 1'b1;
    direct_frontend_flush = 1'b1;
    direct_branch_fire = 1'b1;
    direct_branch_spec_start = 1'b1;
    direct_branch_pred_pc = 64'h0000_0000_8000_6000;
    checkpoint_capture = 1'b1;
    tick();
    check_state("csr trap clear wins over start and capture", 1'b0, 1'b0,
                {`XLEN{1'b0}});

    tb_finish("tb_ooo_branch_spec_tracker");
  end
endmodule
