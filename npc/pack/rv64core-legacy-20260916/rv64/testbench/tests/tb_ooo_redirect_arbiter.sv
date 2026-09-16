`include "include/define.v"

// OooRedirectArbiter 定向单测：年龄优先级（最老 rob_idx 胜）、同 age 类平手（trap>branch>direct）、
// 环形 wrap 年龄比较，以及 typed control-event / fetch redirect 两种投影的字段透传。
module tb_ooo_redirect_arbiter;
  `include "tb_common.svh"

  integer casenum;

  reg [`OOO_ROB_INDEX_W-1:0] rob_head_idx_i;

  reg                        trap_valid_i;
  reg [`XLEN-1:0]            trap_pc_i;
  reg [`OOO_ROB_INDEX_W-1:0] trap_rob_idx_i;
  reg [`REDIR_REASON_W-1:0]  trap_reason_i;
  reg                        trap_flush_fetch_i;
  reg [`OOO_BACKEND_ACTION_W-1:0] trap_backend_action_i;

  reg                        branch_valid_i;
  reg [`XLEN-1:0]            branch_pc_i;
  reg [`OOO_ROB_INDEX_W-1:0] branch_rob_idx_i;
  reg [`REDIR_REASON_W-1:0]  branch_reason_i;
  reg                        branch_flush_fetch_i;
  reg [`OOO_BACKEND_ACTION_W-1:0] branch_backend_action_i;

  reg                        direct_valid_i;
  reg [`XLEN-1:0]            direct_pc_i;
  reg [`OOO_ROB_INDEX_W-1:0] direct_rob_idx_i;
  reg [`REDIR_REASON_W-1:0]  direct_reason_i;
  reg                        direct_flush_fetch_i;
  reg [`OOO_BACKEND_ACTION_W-1:0] direct_backend_action_i;

  wire                        control_event_valid_o;
  wire                        redirect_valid_o;
  wire [`XLEN-1:0]            redirect_pc_o;
  wire [`OOO_ROB_INDEX_W-1:0] redirect_kill_idx_o;
  wire [`REDIR_REASON_W-1:0]  redirect_reason_o;
  wire                        redirect_flush_fetch_o;
  wire                        redirect_flush_backend_o;
  wire [`OOO_BACKEND_ACTION_W-1:0] redirect_backend_action_o;

  OooRedirectArbiter dut (
    .rob_head_idx_i(rob_head_idx_i),
    .trap_valid_i(trap_valid_i),
    .trap_pc_i(trap_pc_i),
    .trap_rob_idx_i(trap_rob_idx_i),
    .trap_reason_i(trap_reason_i),
    .trap_flush_fetch_i(trap_flush_fetch_i),
    .trap_backend_action_i(trap_backend_action_i),
    .branch_valid_i(branch_valid_i),
    .branch_pc_i(branch_pc_i),
    .branch_rob_idx_i(branch_rob_idx_i),
    .branch_reason_i(branch_reason_i),
    .branch_flush_fetch_i(branch_flush_fetch_i),
    .branch_backend_action_i(branch_backend_action_i),
    .direct_valid_i(direct_valid_i),
    .direct_pc_i(direct_pc_i),
    .direct_rob_idx_i(direct_rob_idx_i),
    .direct_reason_i(direct_reason_i),
    .direct_flush_fetch_i(direct_flush_fetch_i),
    .direct_backend_action_i(direct_backend_action_i),
    .control_event_valid_o(control_event_valid_o),
    .redirect_valid_o(redirect_valid_o),
    .redirect_pc_o(redirect_pc_o),
    .redirect_kill_idx_o(redirect_kill_idx_o),
    .redirect_reason_o(redirect_reason_o),
    .redirect_flush_fetch_o(redirect_flush_fetch_o),
    .redirect_flush_backend_o(redirect_flush_backend_o),
    .redirect_backend_action_o(redirect_backend_action_o)
  );

  // 默认：全源无效，各源给可区分的 pc/idx/reason/action 以验透传。
  task clr;
    begin
      rob_head_idx_i        = 4'd0;
      trap_valid_i          = 1'b0;
      trap_pc_i             = 64'h8000_1000;
      trap_rob_idx_i        = 4'd0;
      trap_reason_i         = `REDIR_REASON_TRAP;
      trap_flush_fetch_i    = 1'b1;
      trap_backend_action_i = `OOO_BACKEND_ACTION_FULL_NEXT;
      branch_valid_i        = 1'b0;
      branch_pc_i           = 64'h8000_2000;
      branch_rob_idx_i      = 4'd5;
      branch_reason_i       = `REDIR_REASON_BRANCH_MISS;
      branch_flush_fetch_i  = 1'b1;
      branch_backend_action_i = `OOO_BACKEND_ACTION_SELECTIVE_NOW;
      direct_valid_i        = 1'b0;
      direct_pc_i           = 64'h8000_3000;
      direct_rob_idx_i      = 4'd9;
      direct_reason_i       = `REDIR_REASON_DIRECT;
      direct_flush_fetch_i  = 1'b1;
      direct_backend_action_i = `OOO_BACKEND_ACTION_NONE;
    end
  endtask

  task expect_r;
    input                       exp_event_valid;
    input                       exp_redirect_valid;
    input [`XLEN-1:0]           exp_pc;
    input [`OOO_ROB_INDEX_W-1:0] exp_kill;
    input [`REDIR_REASON_W-1:0] exp_reason;
    input                       exp_ff;
    input [`OOO_BACKEND_ACTION_W-1:0] exp_action;
    begin
      #1;
      if (control_event_valid_o !== exp_event_valid) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] case %0d event_valid got=%0b exp=%0b",
                 casenum, control_event_valid_o, exp_event_valid);
      end
      if (redirect_valid_o !== exp_redirect_valid) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] case %0d redirect_valid got=%0b exp=%0b",
                 casenum, redirect_valid_o, exp_redirect_valid);
      end
      if (exp_event_valid) begin
        if (redirect_pc_o !== exp_pc) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] case %0d pc got=%0h exp=%0h", casenum, redirect_pc_o, exp_pc);
        end
        if (redirect_kill_idx_o !== exp_kill) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] case %0d kill got=%0d exp=%0d", casenum, redirect_kill_idx_o, exp_kill);
        end
        if (redirect_reason_o !== exp_reason) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] case %0d reason got=%0d exp=%0d", casenum, redirect_reason_o, exp_reason);
        end
        if (redirect_flush_fetch_o !== exp_ff) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] case %0d flush_fetch got=%0b exp=%0b", casenum, redirect_flush_fetch_o, exp_ff);
        end
        if (redirect_backend_action_o !== exp_action) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] case %0d backend_action got=%0d exp=%0d",
                   casenum, redirect_backend_action_o, exp_action);
        end
        if (redirect_flush_backend_o !==
            (exp_action != `OOO_BACKEND_ACTION_NONE)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] case %0d compat_flush_backend got=%0b exp=%0b",
                   casenum, redirect_flush_backend_o,
                   (exp_action != `OOO_BACKEND_ACTION_NONE));
        end
      end
      casenum = casenum + 1;
    end
  endtask

  initial begin
    tb_errors = 0;
    casenum   = 1;

    // C1 无源 → valid=0
    clr();
    expect_r(1'b0, 1'b0, 64'h0, 4'd0, `REDIR_REASON_NONE, 1'b0,
             `OOO_BACKEND_ACTION_NONE);

    // C2 仅 direct → direct 透传（backend action=NONE）
    clr(); direct_valid_i = 1'b1;
    expect_r(1'b1, 1'b1, 64'h8000_3000, 4'd9, `REDIR_REASON_DIRECT, 1'b1,
             `OOO_BACKEND_ACTION_NONE);

    // C3 仅 branch
    clr(); branch_valid_i = 1'b1;
    expect_r(1'b1, 1'b1, 64'h8000_2000, 4'd5, `REDIR_REASON_BRANCH_MISS, 1'b1,
             `OOO_BACKEND_ACTION_SELECTIVE_NOW);

    // C4 仅 trap
    clr(); trap_valid_i = 1'b1;
    expect_r(1'b1, 1'b1, 64'h8000_1000, 4'd0, `REDIR_REASON_TRAP, 1'b1,
             `OOO_BACKEND_ACTION_FULL_NEXT);

    // C5 trap(age0) + branch(age5) → trap 胜
    clr(); trap_valid_i = 1'b1; branch_valid_i = 1'b1;
    expect_r(1'b1, 1'b1, 64'h8000_1000, 4'd0, `REDIR_REASON_TRAP, 1'b1,
             `OOO_BACKEND_ACTION_FULL_NEXT);

    // C6 branch(age5) + direct(age9) → branch 胜（更老）
    clr(); branch_valid_i = 1'b1; direct_valid_i = 1'b1;
    expect_r(1'b1, 1'b1, 64'h8000_2000, 4'd5, `REDIR_REASON_BRANCH_MISS, 1'b1,
             `OOO_BACKEND_ACTION_SELECTIVE_NOW);

    // C7 branch + direct 同 idx(age 平手) → branch 胜（类优先级）
    clr(); branch_valid_i = 1'b1; direct_valid_i = 1'b1; direct_rob_idx_i = 4'd5;
    expect_r(1'b1, 1'b1, 64'h8000_2000, 4'd5, `REDIR_REASON_BRANCH_MISS, 1'b1,
             `OOO_BACKEND_ACTION_SELECTIVE_NOW);

    // C8 trap + branch 同 idx(misaligned 分支既误预测又异常) → trap 胜
    clr(); trap_valid_i = 1'b1; trap_rob_idx_i = 4'd5; branch_valid_i = 1'b1; branch_rob_idx_i = 4'd5;
    expect_r(1'b1, 1'b1, 64'h8000_1000, 4'd5, `REDIR_REASON_TRAP, 1'b1,
             `OOO_BACKEND_ACTION_FULL_NEXT);

    // C9 三源, branch 最老（head=4: trap age5, branch age1, direct age5）→ branch 胜
    clr(); rob_head_idx_i = 4'd4;
    trap_valid_i = 1'b1; trap_rob_idx_i = 4'd9;
    branch_valid_i = 1'b1; branch_rob_idx_i = 4'd5;
    direct_valid_i = 1'b1; direct_rob_idx_i = 4'd9;
    expect_r(1'b1, 1'b1, 64'h8000_2000, 4'd5, `REDIR_REASON_BRANCH_MISS, 1'b1,
             `OOO_BACKEND_ACTION_SELECTIVE_NOW);

    // C10 三源, direct 最老（head=8: direct age1, branch age13, trap age8）→ direct 胜（fb=0）
    clr(); rob_head_idx_i = 4'd8;
    trap_valid_i = 1'b1; trap_rob_idx_i = 4'd0;
    branch_valid_i = 1'b1; branch_rob_idx_i = 4'd5;
    direct_valid_i = 1'b1; direct_rob_idx_i = 4'd9;
    expect_r(1'b1, 1'b1, 64'h8000_3000, 4'd9, `REDIR_REASON_DIRECT, 1'b1,
             `OOO_BACKEND_ACTION_NONE);

    // C11 环形 wrap：head=14, branch idx15(age1) vs direct idx2(age4) → branch 胜
    clr(); rob_head_idx_i = 4'd14;
    branch_valid_i = 1'b1; branch_rob_idx_i = 4'd15;
    direct_valid_i = 1'b1; direct_rob_idx_i = 4'd2;
    expect_r(1'b1, 1'b1, 64'h8000_2000, 4'd15, `REDIR_REASON_BRANCH_MISS, 1'b1,
             `OOO_BACKEND_ACTION_SELECTIVE_NOW);

    // C12 reason 透传变体：branch=JALR_MISS
    clr(); branch_valid_i = 1'b1; branch_reason_i = `REDIR_REASON_JALR_MISS;
    expect_r(1'b1, 1'b1, 64'h8000_2000, 4'd5, `REDIR_REASON_JALR_MISS, 1'b1,
             `OOO_BACKEND_ACTION_SELECTIVE_NOW);

    // C13 reason 透传变体：trap=XRET
    clr(); trap_valid_i = 1'b1; trap_reason_i = `REDIR_REASON_XRET;
    expect_r(1'b1, 1'b1, 64'h8000_1000, 4'd0, `REDIR_REASON_XRET, 1'b1,
             `OOO_BACKEND_ACTION_FULL_NEXT);

    // C14 branch 事件存在，但该事件只执行后端选择性恢复，不产生 fetch redirect。
    clr(); branch_valid_i = 1'b1; branch_flush_fetch_i = 1'b0;
    expect_r(1'b1, 1'b0, 64'h8000_2000, 4'd5, `REDIR_REASON_BRANCH_MISS, 1'b0,
             `OOO_BACKEND_ACTION_SELECTIVE_NOW);

    tb_finish("tb_ooo_redirect_arbiter");
  end
endmodule
