`include "define.v"

module tb_ooo_rob;
  `include "tb_common.svh"

  localparam ROB_INDEX_W = 4;
  localparam ROB_COUNT_W = 5;
  localparam PHY_REG_ADDR_W = 6;

  reg clk;
  reg rst;
  reg flush;
  reg dispatch0_valid;
  wire dispatch0_ready;
  wire [ROB_INDEX_W-1:0] dispatch0_rob_idx;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`INST_W-1:0] dispatch0_inst;
  reg dispatch0_rd_en;
  reg [`REG_ADDR_W-1:0] dispatch0_arch_rd;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_old_pdest;
  reg [PHY_REG_ADDR_W-1:0] dispatch0_new_pdest;
  reg dispatch1_valid;
  wire dispatch1_ready;
  wire [ROB_INDEX_W-1:0] dispatch1_rob_idx;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  reg dispatch1_rd_en;
  reg [`REG_ADDR_W-1:0] dispatch1_arch_rd;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_old_pdest;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_new_pdest;
  reg wb0_valid;
  reg [ROB_INDEX_W-1:0] wb0_rob_idx;
  reg [`XLEN-1:0] wb0_data;
  reg wb0_exception;
  reg [`TRAP_CAUSE_W-1:0] wb0_cause;
  reg [`XLEN-1:0] wb0_tval;
  reg wb1_valid;
  reg [ROB_INDEX_W-1:0] wb1_rob_idx;
  reg [`XLEN-1:0] wb1_data;
  reg wb1_exception;
  reg [`TRAP_CAUSE_W-1:0] wb1_cause;
  reg [`XLEN-1:0] wb1_tval;
  reg commit_ready;
  wire commit0_valid;
  wire [`XLEN-1:0] commit0_pc;
  wire [`XLEN-1:0] commit0_next_pc;
  wire [`INST_W-1:0] commit0_inst;
  wire commit0_rd_en;
  wire [`REG_ADDR_W-1:0] commit0_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit0_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit0_new_pdest;
  wire [`XLEN-1:0] commit0_data;
  wire commit0_exception;
  wire [`TRAP_CAUSE_W-1:0] commit0_cause;
  wire [`XLEN-1:0] commit0_tval;
  wire commit1_valid;
  wire [`XLEN-1:0] commit1_pc;
  wire [`XLEN-1:0] commit1_next_pc;
  wire [`INST_W-1:0] commit1_inst;
  wire commit1_rd_en;
  wire [`REG_ADDR_W-1:0] commit1_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit1_new_pdest;
  wire [`XLEN-1:0] commit1_data;
  wire commit1_exception;
  wire [`TRAP_CAUSE_W-1:0] commit1_cause;
  wire [`XLEN-1:0] commit1_tval;
  wire [ROB_COUNT_W-1:0] count;
  wire empty;
  wire full;
  wire arch_commit0_write;
  wire arch_commit1_write;
  wire [`XLEN-1:0] arch_a0;
  wire [`XLEN * `REG_NUM - 1:0] arch_gprs;
  wire commit_exception_trap;
  wire trap_mem_valid;
  wire [`XLEN-1:0] trap_mem_pc;
  wire [`TRAP_CAUSE_W-1:0] trap_mem_cause;
  wire [`XLEN-1:0] trap_mem_tval;
  reg [ROB_INDEX_W-1:0] saved0;
  reg [ROB_INDEX_W-1:0] saved1;

  // B2 ROB-walk 恢复端口
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  wire recover_active;
  wire walk0_valid;
  wire [`REG_ADDR_W-1:0] walk0_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] walk0_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] walk0_new_pdest;
  wire walk0_rd_en;
  wire walk1_valid;
  wire [`REG_ADDR_W-1:0] walk1_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] walk1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] walk1_new_pdest;
  wire walk1_rd_en;
  wire unused_walk_w = walk0_rd_en | walk1_rd_en |
                       (|walk0_new_pdest) | (|walk1_new_pdest);

  OooRob dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_rob_idx_o(dispatch0_rob_idx),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_rd_en_i(dispatch0_rd_en),
    .dispatch0_is_fp_rd_i(1'b0),
    .dispatch0_arch_rd_i(dispatch0_arch_rd),
    .dispatch0_old_pdest_i(dispatch0_old_pdest),
    .dispatch0_new_pdest_i(dispatch0_new_pdest),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_rob_idx_o(dispatch1_rob_idx),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_rd_en_i(dispatch1_rd_en),
    .dispatch1_is_fp_rd_i(1'b0),
    .dispatch1_arch_rd_i(dispatch1_arch_rd),
    .dispatch1_old_pdest_i(dispatch1_old_pdest),
    .dispatch1_new_pdest_i(dispatch1_new_pdest),
    .wb0_valid_i(wb0_valid),
    .wb0_rob_idx_i(wb0_rob_idx),
    .wb0_data_i(wb0_data),
    .wb0_exception_i(wb0_exception),
    .wb0_cause_i(wb0_cause),
    .wb0_tval_i(wb0_tval),
    .wb0_fflags_i(5'b00000),
    .wb1_valid_i(wb1_valid),
    .wb1_rob_idx_i(wb1_rob_idx),
    .wb1_data_i(wb1_data),
    .wb1_exception_i(wb1_exception),
    .wb1_cause_i(wb1_cause),
    .wb1_tval_i(wb1_tval),
    .wb1_fflags_i(5'b00000),
    .commit_ready_i(commit_ready),
    .commit1_block_i(1'b0),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_arch_rd_o(commit0_arch_rd),
    .commit0_old_pdest_o(commit0_old_pdest),
    .commit0_new_pdest_o(commit0_new_pdest),
    .commit0_data_o(commit0_data),
    .commit0_exception_o(commit0_exception),
    .commit0_cause_o(commit0_cause),
    .commit0_tval_o(commit0_tval),
    .commit1_valid_o(commit1_valid),
    .commit1_pc_o(commit1_pc),
    .commit1_next_pc_o(commit1_next_pc),
    .commit1_inst_o(commit1_inst),
    .commit1_rd_en_o(commit1_rd_en),
    .commit1_arch_rd_o(commit1_arch_rd),
    .commit1_old_pdest_o(commit1_old_pdest),
    .commit1_new_pdest_o(commit1_new_pdest),
    .commit1_data_o(commit1_data),
    .commit1_exception_o(commit1_exception),
    .commit1_cause_o(commit1_cause),
    .commit1_tval_o(commit1_tval),
    .count_o(count),
    .empty_o(empty),
    .full_o(full),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .recover_active_o(recover_active),
    .walk0_valid_o(walk0_valid),
    .walk0_arch_rd_o(walk0_arch_rd),
    .walk0_old_pdest_o(walk0_old_pdest),
    .walk0_new_pdest_o(walk0_new_pdest),
    .walk0_rd_en_o(walk0_rd_en),
    .walk1_valid_o(walk1_valid),
    .walk1_arch_rd_o(walk1_arch_rd),
    .walk1_old_pdest_o(walk1_old_pdest),
    .walk1_new_pdest_o(walk1_new_pdest),
    .walk1_rd_en_o(walk1_rd_en)
  );

  // 用生产侧副作用/陷阱模块消费真实 ROB commit，总线不靠 TB 重写判据。
  // 这样 head1 exception 的定向用例同时覆盖 lane1 trap 选择和 GPR 写抑制。
  OooArchRegFile u_arch_regfile (
    .clk(clk),
    .rst(rst),
    .commit0_valid_i(commit0_valid),
    .commit0_rd_en_i(commit0_rd_en),
    .commit0_arch_rd_i(commit0_arch_rd),
    .commit0_data_i(commit0_data),
    .commit0_exception_i(commit0_exception),
    .commit1_valid_i(commit1_valid),
    .commit1_rd_en_i(commit1_rd_en),
    .commit1_arch_rd_i(commit1_arch_rd),
    .commit1_data_i(commit1_data),
    .commit1_exception_i(commit1_exception),
    .serial_write_valid_i(1'b0),
    .serial_write_arch_rd_i({`REG_ADDR_W{1'b0}}),
    .serial_write_data_i({`XLEN{1'b0}}),
    .commit0_write_o(arch_commit0_write),
    .commit1_write_o(arch_commit1_write),
    .a0_data_o(arch_a0),
    .debug_gprs_o(arch_gprs)
  );

  OooCsrTrapRequestMux u_trap_request_mux (
    .core_commit0_valid_i(commit0_valid),
    .core_commit0_exception_i(commit0_exception),
    .core_commit0_pc_i(commit0_pc),
    .core_commit0_cause_i(commit0_cause),
    .core_commit0_tval_i(commit0_tval),
    .core_commit1_valid_i(commit1_valid),
    .core_commit1_exception_i(commit1_exception),
    .core_commit1_pc_i(commit1_pc),
    .core_commit1_cause_i(commit1_cause),
    .core_commit1_tval_i(commit1_tval),
    .stop_pending_i(1'b0),
    .drain_complete_i(1'b0),
    .pending_arch_trap_i(1'b0),
    .pending_trap_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .pending_trap_pc_i({`XLEN{1'b0}}),
    .pending_trap_tval_i({`XLEN{1'b0}}),
    .pending_system_i(1'b0),
    .pending_system_ecall_i(1'b0),
    .pending_system_mret_i(1'b0),
    .pending_system_irq_i(1'b0),
    .pending_system_pc_i({`XLEN{1'b0}}),
    .pending_system_inst_i({`INST_W{1'b0}}),
    .pending_system_irq_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .csr_ecall_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .pending_system_satp_write_commit_i(1'b0),
    .pending_system_sfence_commit_i(1'b0),
    .core_commit_exception_trap_o(commit_exception_trap),
    .trap_mem_valid_o(trap_mem_valid),
    .trap_mem_pc_o(trap_mem_pc),
    .trap_mem_cause_o(trap_mem_cause),
    .trap_mem_tval_o(trap_mem_tval),
    .pending_system_ecall_trap_o(),
    .pending_arch_trap_fire_o(),
    .trap_ex_valid_o(),
    .trap_ex_pc_o(),
    .trap_ex_cause_o(),
    .trap_ex_tval_o(),
    .trap_irq_valid_o(),
    .trap_irq_pc_o(),
    .trap_irq_cause_o(),
    .mret_valid_o(),
    .sret_valid_o(),
    .real_mret_valid_o(),
    .priv_predictor_boundary_o()
  );

  wire unused_next_pc_w = (|commit0_next_pc) | (|commit1_next_pc) |
                          (|arch_a0);

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
      dispatch0_rd_en = 1'b0;
      dispatch0_arch_rd = 5'd0;
      dispatch0_old_pdest = 6'd0;
      dispatch0_new_pdest = 6'd0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_inst = 32'h0;
      dispatch1_rd_en = 1'b0;
      dispatch1_arch_rd = 5'd0;
      dispatch1_old_pdest = 6'd0;
      dispatch1_new_pdest = 6'd0;
      wb0_valid = 1'b0;
      wb0_rob_idx = 4'd0;
      wb0_data = 32'h0;
      wb0_exception = 1'b0;
      wb0_cause = 5'd0;
      wb0_tval = 32'h0;
      wb1_valid = 1'b0;
      wb1_rob_idx = 4'd0;
      wb1_data = 32'h0;
      wb1_exception = 1'b0;
      wb1_cause = 5'd0;
      wb1_tval = 32'h0;
      kill_valid = 1'b0;
      kill_rob_idx = 4'd0;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      commit_ready = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();
    tb_check1("reset empty", empty, 1'b1);

    // Kept behind a plusarg so the normal regression remains positive while
    // the task-run negative runner can prove the dual-WB owner contract fires.
    if ($test$plusargs("T3W_ROB_WB_COLLISION_NEGATIVE")) begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = 32'h8000_0bad;
      dispatch0_inst = 32'h0000_0013;
      #1;
      saved0 = dispatch0_rob_idx;
      `TB_TICK(clk);
      clear_inputs();
      wb0_valid = 1'b1;
      wb0_rob_idx = saved0;
      wb0_data = 32'h1111_1111;
      wb1_valid = 1'b1;
      wb1_rob_idx = saved0;
      wb1_data = 32'h2222_2222;
      `TB_TICK(clk);
      $display("[CHECK-FAIL] dual-WB collision contract did not terminate");
      $fatal;
    end

    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0000;
    dispatch0_inst = 32'h0000_0093;
    dispatch0_rd_en = 1'b1;
    dispatch0_arch_rd = 5'd1;
    dispatch0_old_pdest = 6'd1;
    dispatch0_new_pdest = 6'd32;
    dispatch1_valid = 1'b1;
    dispatch1_pc = 32'h8000_0004;
    dispatch1_inst = 32'h0010_0113;
    dispatch1_rd_en = 1'b1;
    dispatch1_arch_rd = 5'd2;
    dispatch1_old_pdest = 6'd2;
    dispatch1_new_pdest = 6'd33;
    #1;
    tb_check1("dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("dispatch1 ready", dispatch1_ready, 1'b1);
    tb_check32("dispatch0 index", {28'b0, dispatch0_rob_idx}, 32'd0);
    tb_check32("dispatch1 index", {28'b0, dispatch1_rob_idx}, 32'd1);
    saved0 = dispatch0_rob_idx;
    saved1 = dispatch1_rob_idx;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("count after dispatch", {27'b0, count}, 32'd2);
    tb_check1("head not done yet", commit0_valid, 1'b0);

    // checkpoint capture/restore 场景已删（dead silicon，ROB-walk 取代）；
    // 净效果 = ROB 回到 capture 前(2 条 idx0/idx1，head 未 done)，此处保持该态。
    clear_inputs();

    wb1_valid = 1'b1;
    wb1_rob_idx = saved1;
    wb1_data = 32'h2222_0002;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("younger done cannot commit", commit0_valid, 1'b0);

    wb0_valid = 1'b1;
    wb0_rob_idx = saved0;
    wb0_data = 32'h1111_0001;
    #1;
    tb_check1("writeback edge required before commit0", commit0_valid, 1'b0);
    tb_check1("head blocks younger before registered done", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("commit0 valid from registered done", commit0_valid, 1'b1);
    tb_check1("commit1 valid from registered done", commit1_valid, 1'b1);
    tb_check32("commit0 pc from ROB Q", commit0_pc, 32'h8000_0000);
    tb_check32("commit1 pc from ROB Q", commit1_pc, 32'h8000_0004);
    tb_check32("commit0 data from ROB Q", commit0_data, 32'h1111_0001);
    tb_check32("commit1 data from ROB Q", commit1_data, 32'h2222_0002);
    tb_check32("commit0 old pdest from ROB Q", {26'b0, commit0_old_pdest}, 32'd1);
    tb_check32("commit1 new pdest from ROB Q", {26'b0, commit1_new_pdest}, 32'd33);
    $display("[T3W-ROB-Q-RETIRE] dual writeback is absorbed before exact dual retirement");
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("count after dual commit", {27'b0, count}, 32'd0);

    // T4N reviewer: 异常只能由 commit0 精确退休。即使 lane0 是可退休的正常指令，
    // lane1 异常项也必须留在 ROB，下一拍升为 head 后再宣告 trap。
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0080;
    dispatch0_inst = 32'h0020_0193;
    dispatch0_rd_en = 1'b1;
    dispatch0_arch_rd = 5'd3;
    dispatch0_old_pdest = 6'd3;
    dispatch0_new_pdest = 6'd34;
    dispatch1_valid = 1'b1;
    dispatch1_pc = 32'h8000_0084;
    dispatch1_inst = 32'h0000_2203;  // lw x4,0(x0): fault 时 rd_en 仍非真空
    dispatch1_rd_en = 1'b1;
    dispatch1_arch_rd = 5'd4;
    dispatch1_old_pdest = 6'd4;
    dispatch1_new_pdest = 6'd35;
    #1;
    saved0 = dispatch0_rob_idx;
    saved1 = dispatch1_rob_idx;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("head1 exception pair count after dispatch", {27'b0, count}, 32'd2);

    wb0_valid = 1'b1;
    wb0_rob_idx = saved0;
    wb0_data = 32'h4444_0004;
    wb1_valid = 1'b1;
    wb1_rob_idx = saved1;
    wb1_data = 32'hdead_0005;
    wb1_exception = 1'b1;
    wb1_cause = `EXC_LOAD_ACCESS_FAULT;
    wb1_tval = 32'hdead_1000;
    #1;
    tb_check1("head1 exception pair waits for registered WB commit0", commit0_valid, 1'b0);
    tb_check1("head1 exception pair waits for registered WB commit1", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("head1 exception pair commit0 valid", commit0_valid, 1'b1);
    tb_check1("head1 exception structurally blocks commit1", commit1_valid, 1'b0);
    tb_check32("head1 exception pair count before retire edge", {27'b0, count}, 32'd2);
    tb_check32("head1 exception pair commit0 pc", commit0_pc, 32'h8000_0080);
    tb_check32("head1 exception pair commit0 data", commit0_data, 32'h4444_0004);
    tb_check1("head1 exception pair commit0 is normal", commit0_exception, 1'b0);
    tb_check1("head1 exception does not trap before becoming head", commit_exception_trap, 1'b0);
    tb_check1("head1 exception keeps trap invalid in lane1 cycle", trap_mem_valid, 1'b0);
    tb_check1("head1 exception pair normal lane0 writes GPR", arch_commit0_write, 1'b1);
    tb_check1("blocked exceptional lane1 suppresses GPR write",
              arch_commit1_write, 1'b0);
    $display("[T4N-ROB-HEAD1-EXCEPTION-BLOCK] normal head0 retires alone; exceptional head1 stays resident");
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("exception remains after older-only retire", {27'b0, count}, 32'd1);
    tb_check32("head1 exception pair normal lane0 GPR side effect", arch_gprs[3*`XLEN +: `XLEN],
               32'h4444_0004);
    tb_check32("head1 exception pair exceptional lane1 GPR remains zero",
               arch_gprs[4*`XLEN +: `XLEN], 32'd0);
    tb_check1("exception becomes commit0 at new head", commit0_valid, 1'b1);
    tb_check1("new-head exception cannot pair commit1", commit1_valid, 1'b0);
    tb_check32("new-head exception pc", commit0_pc, 32'h8000_0084);
    tb_check1("new-head exception metadata valid", commit0_exception, 1'b1);
    tb_check32("new-head exception cause", {27'b0, commit0_cause},
               {27'b0, `EXC_LOAD_ACCESS_FAULT});
    tb_check32("new-head exception tval", commit0_tval, 32'hdead_1000);
    tb_check1("new-head exception raises precise trap", commit_exception_trap, 1'b1);
    tb_check1("new-head exception trap valid", trap_mem_valid, 1'b1);
    tb_check32("new-head trap pc", trap_mem_pc, 32'h8000_0084);
    tb_check32("new-head trap cause", {27'b0, trap_mem_cause},
               {27'b0, `EXC_LOAD_ACCESS_FAULT});
    tb_check32("new-head trap tval", trap_mem_tval, 32'hdead_1000);
    tb_check1("exceptional commit0 suppresses GPR write", arch_commit0_write, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("count after precise exception retire", {27'b0, count}, 32'd0);

    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0100;
    dispatch0_inst = 32'h0000_0073;
    dispatch1_valid = 1'b1;
    dispatch1_pc = 32'h8000_0104;
    dispatch1_inst = 32'h0000_0093;
    #1;
    saved0 = dispatch0_rob_idx;
    saved1 = dispatch1_rob_idx;
    `TB_TICK(clk);
    clear_inputs();

    wb0_valid = 1'b1;
    wb0_rob_idx = saved0;
    wb0_exception = 1'b1;
    wb0_cause = `EXC_ILLEGAL_INST;
    wb0_tval = 32'hfeed_beef;
    wb1_valid = 1'b1;
    wb1_rob_idx = saved1;
    wb1_data = 32'h3333_0003;
    #1;
    tb_check1("exception writeback cannot retire combinationally", commit0_valid, 1'b0);
    tb_check1("younger cannot pass unregistered exception", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("registered exception commits at head", commit0_valid, 1'b1);
    tb_check1("registered exception blocks younger", commit1_valid, 1'b0);
    tb_check1("commit0 exception from ROB Q", commit0_exception, 1'b1);
    tb_check32("commit0 cause from ROB Q", {27'b0, commit0_cause}, {27'b0, `EXC_ILLEGAL_INST});
    tb_check32("commit0 tval from ROB Q", commit0_tval, 32'hfeed_beef);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check1("younger commits next", commit0_valid, 1'b1);
    tb_check32("younger pc preserved", commit0_pc, 32'h8000_0104);
    `TB_TICK(clk);
    #1;
    tb_check32("count after exception sequence", {27'b0, count}, 32'd0);

    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0200;
    `TB_TICK(clk);
    clear_inputs();
    flush = 1'b1;
    `TB_TICK(clk);
    flush = 1'b0;
    #1;
    tb_check1("flush empties rob", empty, 1'b1);

    // ============ B2 ROB-walk 误预测恢复 ============
    // dispatch 5 条(idx0..4，arch_rd=i+1/old=10+i/new=40+i)，kill 存活分支 idx1 → squash idx2/3/4。
    reset_dut();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd1;
    dispatch0_old_pdest = 6'd10; dispatch0_new_pdest = 6'd40; dispatch0_pc = 32'h9000_0000;
    dispatch1_valid = 1'b1; dispatch1_rd_en = 1'b1; dispatch1_arch_rd = 5'd2;
    dispatch1_old_pdest = 6'd11; dispatch1_new_pdest = 6'd41; dispatch1_pc = 32'h9000_0004;
    `TB_TICK(clk); clear_inputs();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd3;
    dispatch0_old_pdest = 6'd12; dispatch0_new_pdest = 6'd42; dispatch0_pc = 32'h9000_0008;
    dispatch1_valid = 1'b1; dispatch1_rd_en = 1'b1; dispatch1_arch_rd = 5'd4;
    dispatch1_old_pdest = 6'd13; dispatch1_new_pdest = 6'd43; dispatch1_pc = 32'h9000_000c;
    `TB_TICK(clk); clear_inputs();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd5;
    dispatch0_old_pdest = 6'd14; dispatch0_new_pdest = 6'd44; dispatch0_pc = 32'h9000_0010;
    `TB_TICK(clk); clear_inputs();
    #1;
    tb_check32("walk: count before kill", {27'b0, count}, 32'd5);

    // 启动 kill（存活 idx1）：本拍冻结 dispatch、尚未 emit
    kill_valid = 1'b1; kill_rob_idx = 4'd1;
    #1;
    tb_check1("walk: kill cycle freezes dispatch", dispatch0_ready, 1'b0);
    tb_check1("walk: kill cycle no emit yet", walk0_valid, 1'b0);
    `TB_TICK(clk); kill_valid = 1'b0;
    #1;
    // recover 拍 B：lane0=idx4(arch5/old14/new44)、lane1=idx3(arch4/old13)
    tb_check1("walk B recover active", recover_active, 1'b1);
    tb_check1("walk B lane0 valid", walk0_valid, 1'b1);
    tb_check32("walk B lane0 arch_rd", {27'b0, walk0_arch_rd}, 32'd5);
    tb_check32("walk B lane0 old_pdest", {26'b0, walk0_old_pdest}, 32'd14);
    tb_check32("walk B lane0 new_pdest", {26'b0, walk0_new_pdest}, 32'd44);
    tb_check1("walk B lane1 valid", walk1_valid, 1'b1);
    tb_check32("walk B lane1 arch_rd", {27'b0, walk1_arch_rd}, 32'd4);
    tb_check32("walk B lane1 old_pdest", {26'b0, walk1_old_pdest}, 32'd13);
    `TB_TICK(clk);
    #1;
    // recover 拍 C：lane0=idx2(arch3/old12)、lane1 到分支边界无效、walk_done
    tb_check1("walk C lane0 valid", walk0_valid, 1'b1);
    tb_check32("walk C lane0 arch_rd", {27'b0, walk0_arch_rd}, 32'd3);
    tb_check32("walk C lane0 old_pdest", {26'b0, walk0_old_pdest}, 32'd12);
    tb_check1("walk C lane1 invalid at branch boundary", walk1_valid, 1'b0);
    `TB_TICK(clk);
    #1;
    // 收尾：count=2(idx0/1 存活)、recover 退出、dispatch 解冻
    tb_check1("walk done recover inactive", recover_active, 1'b0);
    tb_check32("walk done count=2", {27'b0, count}, 32'd2);
    tb_check1("walk done dispatch ready", dispatch0_ready, 1'b1);
    tb_check1("walk done not empty", empty, 1'b0);
    // 存活 idx0/1 仍可按序提交、状态完好
    wb0_valid = 1'b1; wb0_rob_idx = 4'd0; wb0_data = 32'h0000_aaaa;
    wb1_valid = 1'b1; wb1_rob_idx = 4'd1; wb1_data = 32'h0000_bbbb;
    #1;
    tb_check1("walk survivors wait for registered WB", commit0_valid, 1'b0);
    `TB_TICK(clk); clear_inputs();
    #1;
    tb_check1("walk surv commit0 valid", commit0_valid, 1'b1);
    tb_check32("walk surv commit0 pc", commit0_pc, 32'h9000_0000);
    tb_check1("walk surv commit1 valid", commit1_valid, 1'b1);
    tb_check32("walk surv commit1 pc", commit1_pc, 32'h9000_0004);
    tb_check32("walk surv commit0 old_pdest", {26'b0, commit0_old_pdest}, 32'd10);
    `TB_TICK(clk); clear_inputs();
    #1;
    tb_check32("walk surv count=0", {27'b0, count}, 32'd0);

    // 偶数 younger：dispatch 5、kill 存活 idx2 → squash idx3/4(2 条)→走 last_two 单拍终止
    reset_dut();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd1;
    dispatch0_old_pdest = 6'd10; dispatch0_new_pdest = 6'd40; dispatch0_pc = 32'ha000_0000;
    dispatch1_valid = 1'b1; dispatch1_rd_en = 1'b1; dispatch1_arch_rd = 5'd2;
    dispatch1_old_pdest = 6'd11; dispatch1_new_pdest = 6'd41; dispatch1_pc = 32'ha000_0004;
    `TB_TICK(clk); clear_inputs();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd3;
    dispatch0_old_pdest = 6'd12; dispatch0_new_pdest = 6'd42; dispatch0_pc = 32'ha000_0008;
    dispatch1_valid = 1'b1; dispatch1_rd_en = 1'b1; dispatch1_arch_rd = 5'd4;
    dispatch1_old_pdest = 6'd13; dispatch1_new_pdest = 6'd43; dispatch1_pc = 32'ha000_000c;
    `TB_TICK(clk); clear_inputs();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd5;
    dispatch0_old_pdest = 6'd14; dispatch0_new_pdest = 6'd44; dispatch0_pc = 32'ha000_0010;
    `TB_TICK(clk); clear_inputs(); #1;
    tb_check32("walk2: count before kill", {27'b0, count}, 32'd5);
    kill_valid = 1'b1; kill_rob_idx = 4'd2;
    `TB_TICK(clk); kill_valid = 1'b0; #1;
    // recover 单拍：lane0=idx4、lane1=idx3，last_two 同拍收尾
    tb_check1("walk2 lane0 valid", walk0_valid, 1'b1);
    tb_check32("walk2 lane0 arch_rd", {27'b0, walk0_arch_rd}, 32'd5);
    tb_check1("walk2 lane1 valid", walk1_valid, 1'b1);
    tb_check32("walk2 lane1 arch_rd", {27'b0, walk1_arch_rd}, 32'd4);
    `TB_TICK(clk); #1;
    tb_check1("walk2 done via last_two: recover inactive", recover_active, 1'b0);
    tb_check32("walk2 done count=3", {27'b0, count}, 32'd3);

    // 边界：kill 时无更年轻者(存活=最新)→不进 recover、不改 ROB 内容；
    // 但 kill 脉冲当拍仍冻结 dispatch 1 拍（recovering_w=recover_q||kill_valid_i），
    // 与 IQ(按 kill_valid squash/gate)+ dispatch backend(dispatch_freeze=kill_valid_q)严格一致，
    // 否则当拍 ROB 仍放新指令进 ROB、而 IQ 把它的发射项 squash → 僵尸 ROB 项永不 done（B2 实测竞争）。
    reset_dut();
    dispatch0_valid = 1'b1; dispatch0_rd_en = 1'b1; dispatch0_arch_rd = 5'd7;
    dispatch0_old_pdest = 6'd20; dispatch0_new_pdest = 6'd50; dispatch0_pc = 32'h9100_0000;
    `TB_TICK(clk); clear_inputs(); #1;
    tb_check32("walk-edge count=1", {27'b0, count}, 32'd1);
    kill_valid = 1'b1; kill_rob_idx = 4'd0;   // idx0 是最新且存活，无更年轻
    #1;
    tb_check1("walk-edge no younger: not recovering", recover_active, 1'b0);
    tb_check1("walk-edge no younger: dispatch frozen this cycle (kill pulse)", dispatch0_ready, 1'b0);
    `TB_TICK(clk); kill_valid = 1'b0; #1;
    tb_check32("walk-edge count unchanged", {27'b0, count}, 32'd1);

    tb_finish("tb_ooo_rob");
  end
endmodule
