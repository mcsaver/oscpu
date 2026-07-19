`timescale 1ns/1ps
`include "define.v"

module tb_ooo_fp_backend_completion_kill;
  localparam ROB_W = `OOO_ROB_INDEX_W;
  localparam PHY_W = `OOO_PHY_REG_ADDR_W;
  localparam [63:0] OLD_VALUE = 64'h0123_4567_89ab_cdef;
  localparam [63:0] EXEC_VALUE = 64'h1111_2222_3333_4444;
  localparam [63:0] LONG_VALUE = 64'h5555_6666_7777_8888;
  localparam [63:0] ARITH_VALUE = 64'haaaa_bbbb_cccc_dddd;

  logic clk;
  logic rst;
  logic kill_valid;
  logic [ROB_W-1:0] kill_rob_idx;
  logic [ROB_W-1:0] rob_head_idx;

  logic arith_valid_drv;
  logic [ROB_W-1:0] arith_rob_drv;
  logic [PHY_W-1:0] arith_pdest_drv;
  logic [63:0] arith_value_drv;
  logic [4:0] arith_fflags_drv;

  wire fp_wake0_valid;
  wire [PHY_W-1:0] fp_wake0_preg;
  wire fpwb_valid;
  wire [ROB_W-1:0] fpwb_rob_idx;
  wire [PHY_W-1:0] fpwb_pdest;
  wire fpwb_rd_en;
  wire [63:0] fpwb_data;
  wire [4:0] fpwb_fflags;
  logic fpwb_ready;

  integer checks;
  integer failures;

  always #5 clk = ~clk;

  OooFpBackend dut (
    .clk(clk),
    .rst(rst),
    .flush_i(1'b0),
    .frm_i(3'b000),

    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .rob_head_idx_i(rob_head_idx),
    .recover_active_i(1'b0),

    .walk0_fp_valid_i(1'b0),
    .walk0_arch_i('0),
    .walk0_old_pdest_i('0),
    .walk0_new_pdest_i('0),
    .walk1_fp_valid_i(1'b0),
    .walk1_arch_i('0),
    .walk1_old_pdest_i('0),
    .walk1_new_pdest_i('0),

    .disp_valid_i(1'b0),
    .disp_ready_o(),
    .disp_rob_idx_i('0),
    .disp_inst_i('0),
    .disp_double_i(1'b0),
    .disp_frd_en_i(1'b0),
    .disp_frd_arch_i('0),
    .disp_dst_gpr_i(1'b0),
    .disp_gpr_pdest_i('0),
    .disp_fs1_en_i(1'b0),
    .disp_fs1_arch_i('0),
    .disp_fs2_en_i(1'b0),
    .disp_fs2_arch_i('0),
    .disp_fs3_en_i(1'b0),
    .disp_fs3_arch_i('0),
    .disp_gpr_src_en_i(1'b0),
    .disp_gpr_src_preg_i('0),
    .disp_gpr_src_ready_i(1'b0),
    .disp_frd_new_pdest_o(),
    .disp_frd_old_pdest_o(),

    .disp1_valid_i(1'b0),
    .disp1_ready_o(),
    .disp1_rob_idx_i('0),
    .disp1_inst_i('0),
    .disp1_double_i(1'b0),
    .disp1_frd_en_i(1'b0),
    .disp1_frd_arch_i('0),
    .disp1_dst_gpr_i(1'b0),
    .disp1_gpr_pdest_i('0),
    .disp1_fs1_en_i(1'b0),
    .disp1_fs1_arch_i('0),
    .disp1_fs2_en_i(1'b0),
    .disp1_fs2_arch_i('0),
    .disp1_fs3_en_i(1'b0),
    .disp1_fs3_arch_i('0),
    .disp1_gpr_src_en_i(1'b0),
    .disp1_gpr_src_preg_i('0),
    .disp1_gpr_src_ready_i(1'b0),
    .disp1_frd_new_pdest_o(),
    .disp1_frd_old_pdest_o(),

    .dispatch0_accept_i(1'b0),
    .dispatch1_accept_i(1'b0),

    .fpld0_alloc_valid_i(1'b0),
    .fpld0_alloc_arch_i('0),
    .fpld0_new_pdest_o(),
    .fpld0_old_pdest_o(),
    .fpld1_alloc_valid_i(1'b0),
    .fpld1_alloc_arch_i('0),
    .fpld1_new_pdest_o(),
    .fpld1_old_pdest_o(),
    .fp_alloc0_ready_o(),
    .fp_alloc1_ready_o(),

    .fpst0_query_arch_i('0),
    .fpst0_query_preg_o(),
    .fpst0_query_ready_o(),
    .fpst1_query_arch_i('0),
    .fpst1_query_preg_o(),
    .fpst1_query_ready_o(),

    .fp_wake0_valid_o(fp_wake0_valid),
    .fp_wake0_preg_o(fp_wake0_preg),
    .fp_wake1_valid_o(),
    .fp_wake1_preg_o(),

    .fpst_read_preg_i('0),
    .fpst_read_data_o(),

    .fpld_wb_valid_i(1'b0),
    .fpld_wb_pdest_i('0),
    .fpld_wb_data_i('0),
    .fpld_wb_double_i(1'b0),

    .int_wake0_valid_i(1'b0),
    .int_wake0_preg_i('0),
    .int_wake1_valid_i(1'b0),
    .int_wake1_preg_i('0),

    .gpr_read_addr_o(),
    .gpr_read_data_i('0),

    .fpwb_valid_o(fpwb_valid),
    .fpwb_rob_idx_o(fpwb_rob_idx),
    .fpwb_pdest_o(fpwb_pdest),
    .fpwb_rd_en_o(fpwb_rd_en),
    .fpwb_data_o(fpwb_data),
    .fpwb_fflags_o(fpwb_fflags),
    .fpwb_ready_i(fpwb_ready),

    .commit0_fp_valid_i(1'b0),
    .commit0_fp_arch_i('0),
    .commit0_fp_data_i('0),
    .commit0_fp_old_pdest_i('0),
    .commit1_fp_valid_i(1'b0),
    .commit1_fp_arch_i('0),
    .commit1_fp_data_i('0),
    .commit1_fp_old_pdest_i('0)
  );

  // Independent contract oracle: strict circular age, not a DUT kill net.
  wire expected_long_killed = kill_valid && dut.long_meta_valid_q &&
      ((dut.long_rob_q - rob_head_idx) > (kill_rob_idx - rob_head_idx));

  task automatic check(input logic condition, input string label);
    begin
      checks = checks + 1;
      if (condition !== 1'b1) begin
        failures = failures + 1;
        $display("[FAIL] %s @%0t", label, $time);
      end
    end
  endtask

  task automatic reset_dut;
    begin
      kill_valid = 1'b0;
      kill_rob_idx = '0;
      rob_head_idx = '0;
      arith_valid_drv = 1'b0;
      arith_rob_drv = '0;
      arith_pdest_drv = '0;
      arith_value_drv = '0;
      arith_fflags_drv = '0;
      fpwb_ready = 1'b0;
      rst = 1'b1;
      repeat (2) @(posedge clk);
      #1;
      rst = 1'b0;
      @(negedge clk);
    end
  endtask

  task automatic seed_exec1(
      input [ROB_W-1:0] rob,
      input [PHY_W-1:0] pdest,
      input logic dst_gpr,
      input logic dst_en,
      input [63:0] value,
      input [4:0] fflags);
    begin
      dut.u_exec1_stage.valid_q = 1'b1;
      dut.u_exec1_stage.payload_q =
          {rob, pdest, dst_gpr, dst_en, value, fflags};
      dut.fp_busy_q[pdest] = 1'b1;
      dut.u_fp_phys_reg_file.regs_q[pdest] = OLD_VALUE;
      #1;
    end
  endtask

  task automatic seed_long(
      input [ROB_W-1:0] rob,
      input [PHY_W-1:0] pdest,
      input [63:0] value,
      input [4:0] fflags);
    begin
      dut.long_meta_valid_q = 1'b1;
      dut.long_done_hold_q = 1'b1;
      dut.long_rob_q = rob;
      dut.long_pdest_q = pdest;
      dut.long_result_hold_q = value;
      dut.long_fflags_hold_q = fflags;
      dut.fp_busy_q[pdest] = 1'b1;
      dut.u_fp_phys_reg_file.regs_q[pdest] = OLD_VALUE;
      #1;
    end
  endtask

  task automatic check_no_completion(input string prefix);
    begin
      check(dut.fp_result_wb_valid_w === 1'b0,
            {prefix, ": result valid must be low"});
      check(dut.fp_fpr_complete_w === 1'b0,
            {prefix, ": FPR completion must be low"});
      check(fp_wake0_valid === 1'b0,
            {prefix, ": wake must be low"});
      check(dut.df_push_w === 1'b0,
            {prefix, ": done FIFO push must be low"});
    end
  endtask

  task automatic check_fpwb_tuple(
      input string prefix,
      input [ROB_W-1:0] expected_rob,
      input [PHY_W-1:0] expected_pdest,
      input logic expected_rd_en,
      input [63:0] expected_data,
      input [4:0] expected_fflags);
    begin
      check(fpwb_valid === 1'b1, {prefix, ": valid"});
      check(fpwb_rob_idx == expected_rob, {prefix, ": ROB"});
      check(fpwb_pdest == expected_pdest, {prefix, ": pdest"});
      check(fpwb_rd_en === expected_rd_en, {prefix, ": rd_en"});
      check(fpwb_data == expected_data, {prefix, ": data"});
      check(fpwb_fflags == expected_fflags, {prefix, ": fflags"});
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    kill_valid = 1'b0;
    kill_rob_idx = '0;
    rob_head_idx = '0;
    arith_valid_drv = 1'b0;
    arith_rob_drv = '0;
    arith_pdest_drv = '0;
    arith_value_drv = '0;
    arith_fflags_drv = '0;
    fpwb_ready = 1'b0;
    checks = 0;
    failures = 0;

    // Completion arbitration is the DUT under test. Override only the arithmetic
    // producer outputs so arbitration can be exercised without launching an FMA.
    force dut.arith_out_valid_w = arith_valid_drv;
    force dut.arith_out_rob_w = arith_rob_drv;
    force dut.arith_out_pdest_w = arith_pdest_drv;
    force dut.arith_out_value_w = arith_value_drv;
    force dut.arith_out_fflags_w = arith_fflags_drv;

    // exec1 strictly younger across ROB wrap: all direct side effects are blocked
    // before the edge, state clears on the edge, and no delayed pulse follows.
    reset_dut();
    rob_head_idx = 4'he;
    kill_rob_idx = 4'hf;
    seed_exec1(4'h2, 6'd12, 1'b0, 1'b1, EXEC_VALUE, 5'h01);
    kill_valid = 1'b1;
    #1;
    check(dut.exec1_kill_w === 1'b1, "exec1 wrap-younger classified killed");
    check(dut.exec1_take_w === 1'b0, "exec1 wrap-younger take blocked");
    check_no_completion("exec1 wrap-younger kill edge");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd0, "exec1 killed did not push FIFO");
    check(dut.fp_busy_q[12] === 1'b1, "exec1 killed did not clear busy");
    check(dut.u_fp_phys_reg_file.regs_q[12] == OLD_VALUE,
          "exec1 killed did not write FPR");
    check(dut.u_exec1_stage.valid_q === 1'b0, "exec1 killed state cleared");
    kill_valid = 1'b0;
    #1;
    check_no_completion("exec1 post-kill no delayed pulse");

    // The same kill qualification must cover GPR-destination exec1 completions:
    // they do not write FPRs, but would otherwise still enqueue a false ROB WB.
    reset_dut();
    rob_head_idx = 4'd3;
    kill_rob_idx = 4'd5;
    seed_exec1(4'd7, 6'd11, 1'b1, 1'b1, EXEC_VALUE, 5'h11);
    kill_valid = 1'b1;
    #1;
    check(dut.exec1_kill_w === 1'b1, "exec1 GPR younger classified killed");
    check(dut.exec1_take_w === 1'b0, "exec1 GPR younger take blocked");
    check(dut.fp_result_wb_valid_w === 1'b0,
          "exec1 GPR younger generic WB blocked");
    check(dut.df_push_w === 1'b0, "exec1 GPR younger FIFO push blocked");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd0, "exec1 GPR killed no FIFO entry");

    // A live GPR-destination completion must enqueue the complete integer-WB
    // payload, must not touch the FPR domain, and must retire on ready.
    reset_dut();
    seed_exec1(4'd5, 6'd11, 1'b1, 1'b1, EXEC_VALUE, 5'h11);
    #1;
    check(dut.exec1_take_w === 1'b1, "live GPR exec1 selected");
    check(dut.fp_result_wb_valid_w === 1'b1, "live GPR result valid");
    check(dut.fp_result_wb_frd_w === 1'b0, "live GPR not classified FPR");
    check(dut.fp_fpr_complete_w === 1'b0, "live GPR no FPR completion");
    check(fp_wake0_valid === 1'b0, "live GPR no FPR wake");
    check(dut.df_push_w === 1'b1, "live GPR pushes FIFO");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd1, "live GPR FIFO count");
    check_fpwb_tuple("live GPR FIFO head", 4'd5, 6'd11, 1'b1,
                     EXEC_VALUE, 5'h11);
    check(dut.u_fp_phys_reg_file.regs_q[11] == OLD_VALUE,
          "live GPR leaves FPR unchanged");
    check(dut.fp_busy_q[11] === 1'b1, "live GPR leaves FP busy unchanged");
    fpwb_ready = 1'b1;
    #1;
    check(dut.df_pop_w === 1'b1, "live GPR ready handshake pops");
    @(posedge clk);
    #1;
    fpwb_ready = 1'b0;
    check(dut.done_fifo_count_q == 4'd0, "live GPR FIFO drained");
    check(fpwb_valid === 1'b0, "live GPR valid clears after handshake");

    // Equal boundary survives.
    reset_dut();
    rob_head_idx = 4'd3;
    kill_rob_idx = 4'd5;
    seed_exec1(4'd5, 6'd13, 1'b0, 1'b1, EXEC_VALUE, 5'h02);
    kill_valid = 1'b1;
    #1;
    check(dut.exec1_kill_w === 1'b0, "exec1 equal boundary survives");
    check(dut.exec1_take_w === 1'b1, "exec1 equal boundary completes");
    check(fp_wake0_valid === 1'b1, "exec1 equal boundary wakes FPR");
    check(dut.df_push_w === 1'b1, "exec1 equal boundary pushes FIFO");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd1, "exec1 equal FIFO count");
    check(dut.fp_busy_q[13] === 1'b0, "exec1 equal clears busy");
    check(dut.u_fp_phys_reg_file.regs_q[13] == EXEC_VALUE,
          "exec1 equal writes FPR");

    // Older-than-boundary survives.
    reset_dut();
    rob_head_idx = 4'd3;
    kill_rob_idx = 4'd8;
    seed_exec1(4'd5, 6'd14, 1'b0, 1'b1, EXEC_VALUE, 5'h03);
    kill_valid = 1'b1;
    #1;
    check(dut.exec1_kill_w === 1'b0, "exec1 older survives");
    check(dut.exec1_take_w === 1'b1, "exec1 older completes");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd1, "exec1 older FIFO count");
    check(dut.u_fp_phys_reg_file.regs_q[14] == EXEC_VALUE,
          "exec1 older writes FPR");

    // long strictly younger across wrap: block all effects and clear both state bits.
    reset_dut();
    rob_head_idx = 4'he;
    kill_rob_idx = 4'hf;
    seed_long(4'h2, 6'd20, LONG_VALUE, 5'h04);
    kill_valid = 1'b1;
    #1;
    check(expected_long_killed === 1'b1, "long wrap-younger oracle killed");
    check(dut.long_take_w === 1'b0, "long wrap-younger take blocked");
    check_no_completion("long wrap-younger kill edge");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd0, "long killed did not push FIFO");
    check(dut.fp_busy_q[20] === 1'b1, "long killed did not clear busy");
    check(dut.u_fp_phys_reg_file.regs_q[20] == OLD_VALUE,
          "long killed did not write FPR");
    check(dut.long_meta_valid_q === 1'b0, "long killed meta cleared");
    check(dut.long_done_hold_q === 1'b0, "long killed hold cleared");
    kill_valid = 1'b0;
    #1;
    check_no_completion("long post-kill no delayed pulse");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd0, "long no delayed FIFO push");

    // A raw long_done arriving on the kill edge may capture data transiently in
    // the sequential block, but the later kill priority clears meta and hold.
    reset_dut();
    rob_head_idx = 4'd3;
    kill_rob_idx = 4'd5;
    seed_long(4'd7, 6'd19, LONG_VALUE, 5'h12);
    dut.long_done_hold_q = 1'b0;
    force dut.long_done_w = 1'b1;
    force dut.long_result_w = LONG_VALUE;
    force dut.long_fflags_w = 5'h12;
    kill_valid = 1'b1;
    #1;
    check_no_completion("raw long_done kill edge");
    @(posedge clk);
    #1;
    release dut.long_done_w;
    release dut.long_result_w;
    release dut.long_fflags_w;
    kill_valid = 1'b0;
    #1;
    check(dut.long_meta_valid_q === 1'b0, "raw long_done kill clears meta");
    check(dut.long_done_hold_q === 1'b0, "raw long_done kill clears hold");
    check_no_completion("raw long_done post-kill no delayed pulse");
    check(dut.done_fifo_count_q == 4'd0, "raw long_done kill no FIFO entry");
    check(dut.fp_busy_q[19] === 1'b1, "raw long_done kill keeps busy");
    check(dut.u_fp_phys_reg_file.regs_q[19] == OLD_VALUE,
          "raw long_done kill keeps FPR");

    // Equal and older long completions survive the same kill interface.
    reset_dut();
    rob_head_idx = 4'd3;
    kill_rob_idx = 4'd5;
    seed_long(4'd5, 6'd21, LONG_VALUE, 5'h05);
    kill_valid = 1'b1;
    #1;
    check(expected_long_killed === 1'b0, "long equal boundary oracle survives");
    check(dut.long_take_w === 1'b1, "long equal boundary completes");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd1, "long equal FIFO count");
    check(dut.u_fp_phys_reg_file.regs_q[21] == LONG_VALUE,
          "long equal writes FPR");

    reset_dut();
    rob_head_idx = 4'he;
    kill_rob_idx = 4'h2;
    seed_long(4'hf, 6'd22, LONG_VALUE, 5'h06);
    kill_valid = 1'b1;
    #1;
    check(expected_long_killed === 1'b0, "long wrap-older oracle survives");
    check(dut.long_take_w === 1'b1, "long wrap-older completes");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd1, "long older FIFO count");
    check(dut.u_fp_phys_reg_file.regs_q[22] == LONG_VALUE,
          "long older writes FPR");

    // A killed exec1 is removed before arbitration, so a surviving held long
    // completion can use the slot instead of being spuriously blocked.
    reset_dut();
    rob_head_idx = 4'd3;
    kill_rob_idx = 4'd5;
    seed_exec1(4'd7, 6'd24, 1'b0, 1'b1, EXEC_VALUE, 5'h07);
    seed_long(4'd4, 6'd25, LONG_VALUE, 5'h08);
    kill_valid = 1'b1;
    #1;
    check(dut.exec1_kill_w === 1'b1, "mixed killed exec1 classified");
    check(expected_long_killed === 1'b0, "mixed live long oracle survives");
    check(dut.exec1_take_w === 1'b0, "mixed killed exec1 not selected");
    check(dut.long_take_w === 1'b1, "mixed live long promoted");
    check(dut.fp_result_wb_preg_w == 6'd25, "mixed selected long identity");
    @(posedge clk);
    #1;
    check(dut.u_fp_phys_reg_file.regs_q[24] == OLD_VALUE,
          "mixed killed exec1 FPR untouched");
    check(dut.u_fp_phys_reg_file.regs_q[25] == LONG_VALUE,
          "mixed live long FPR written");

    // A surviving exec1 still outranks a killed long, and long cannot reappear.
    reset_dut();
    rob_head_idx = 4'd3;
    kill_rob_idx = 4'd5;
    seed_exec1(4'd4, 6'd26, 1'b0, 1'b1, EXEC_VALUE, 5'h09);
    seed_long(4'd7, 6'd27, LONG_VALUE, 5'h0a);
    kill_valid = 1'b1;
    #1;
    check(dut.exec1_take_w === 1'b1, "mixed live exec1 selected");
    check(expected_long_killed === 1'b1, "mixed long oracle killed");
    check(dut.long_take_w === 1'b0, "mixed killed long not selected");
    check(dut.fp_result_wb_preg_w == 6'd26, "mixed selected exec1 identity");
    @(posedge clk);
    #1;
    kill_valid = 1'b0;
    #1;
    check_no_completion("mixed killed long no delayed pulse");
    check(dut.u_fp_phys_reg_file.regs_q[27] == OLD_VALUE,
          "mixed killed long FPR untouched");

    // Arithmetic remains highest priority. Killing exec1 must not suppress the
    // unrelated arithmetic completion or leak the killed exec1 identity.
    reset_dut();
    rob_head_idx = 4'd3;
    kill_rob_idx = 4'd5;
    seed_exec1(4'd7, 6'd28, 1'b0, 1'b1, EXEC_VALUE, 5'h0b);
    dut.fp_busy_q[30] = 1'b1;
    dut.u_fp_phys_reg_file.regs_q[30] = OLD_VALUE;
    arith_rob_drv = 4'd4;
    arith_pdest_drv = 6'd30;
    arith_value_drv = ARITH_VALUE;
    arith_fflags_drv = 5'h0c;
    arith_valid_drv = 1'b1;
    kill_valid = 1'b1;
    #1;
    check(dut.exec1_take_w === 1'b0, "arith race killed exec1 not selected");
    check(dut.fp_result_wb_valid_w === 1'b1, "arith race result remains valid");
    check(dut.fp_result_wb_preg_w == 6'd30, "arith race identity is arithmetic");
    check(dut.done_in_rob_w == 4'd4, "arith race ROB identity is arithmetic");
    @(posedge clk);
    #1;
    check(dut.u_fp_phys_reg_file.regs_q[28] == OLD_VALUE,
          "arith race killed exec1 FPR untouched");
    check(dut.u_fp_phys_reg_file.regs_q[30] == ARITH_VALUE,
          "arith race arithmetic FPR written");

    // Normal arith > exec1 arbitration holds exec1, then completes it next cycle.
    reset_dut();
    seed_exec1(4'd6, 6'd31, 1'b0, 1'b1, EXEC_VALUE, 5'h0d);
    dut.fp_busy_q[32] = 1'b1;
    dut.u_fp_phys_reg_file.regs_q[32] = OLD_VALUE;
    arith_rob_drv = 4'd5;
    arith_pdest_drv = 6'd32;
    arith_value_drv = ARITH_VALUE;
    arith_fflags_drv = 5'h0e;
    arith_valid_drv = 1'b1;
    #1;
    check(dut.exec1_take_w === 1'b0, "arith priority blocks live exec1");
    check(dut.fp_result_wb_preg_w == 6'd32, "arith priority selects arithmetic");
    @(posedge clk);
    #1;
    check(dut.u_exec1_stage.valid_q === 1'b1, "arith priority holds exec1 state");
    arith_valid_drv = 1'b0;
    #1;
    check(dut.exec1_take_w === 1'b1, "held exec1 completes next cycle");
    check(dut.fp_result_wb_preg_w == 6'd31, "held exec1 identity preserved");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd2, "arith then exec1 produced two FIFO entries");

    // Normal exec1 > long arbitration must retain done-hold and emit it once.
    reset_dut();
    seed_exec1(4'd5, 6'd33, 1'b0, 1'b1, EXEC_VALUE, 5'h0f);
    seed_long(4'd4, 6'd34, LONG_VALUE, 5'h10);
    #1;
    check(dut.exec1_take_w === 1'b1, "exec1 priority selects exec1");
    check(dut.long_take_w === 1'b0, "exec1 priority blocks long");
    @(posedge clk);
    #1;
    check(dut.long_meta_valid_q === 1'b1, "blocked long meta held");
    check(dut.long_done_hold_q === 1'b1, "blocked long done-hold held");
    check(dut.long_take_w === 1'b1, "held long completes after exec1");
    check(dut.fp_result_wb_preg_w == 6'd34, "held long identity preserved");
    @(posedge clk);
    #1;
    check(dut.done_fifo_count_q == 4'd2, "exec1 then long produced two FIFO entries");
    check(dut.long_meta_valid_q === 1'b0, "long meta consumed once");
    check(dut.long_done_hold_q === 1'b0, "long done-hold consumed once");
    #1;
    check_no_completion("long done-hold no duplicate pulse");

    // All three producers live together: arith > exec1 > long. Losing held
    // producers retain identity, complete in order, and expose exact FIFO tuples.
    reset_dut();
    seed_exec1(4'd6, 6'd35, 1'b0, 1'b1, EXEC_VALUE, 5'h0d);
    seed_long(4'd7, 6'd36, LONG_VALUE, 5'h10);
    dut.fp_busy_q[37] = 1'b1;
    dut.u_fp_phys_reg_file.regs_q[37] = OLD_VALUE;
    arith_rob_drv = 4'd5;
    arith_pdest_drv = 6'd37;
    arith_value_drv = ARITH_VALUE;
    arith_fflags_drv = 5'h0e;
    arith_valid_drv = 1'b1;
    #1;
    check(dut.exec1_take_w === 1'b0, "three-source arith blocks exec1");
    check(dut.long_take_w === 1'b0, "three-source arith blocks long");
    check(dut.fp_result_wb_preg_w == 6'd37, "three-source arith pdest");
    check(dut.done_in_rob_w == 4'd5, "three-source arith ROB");
    check(dut.fp_result_wb_value_w == ARITH_VALUE, "three-source arith value");
    check(dut.done_in_fflags_w == 5'h0e, "three-source arith fflags");
    @(posedge clk);
    #1;
    check(dut.u_exec1_stage.valid_q === 1'b1,
          "three-source exec1 retained behind arith");
    check((dut.long_meta_valid_q === 1'b1) &&
          (dut.long_done_hold_q === 1'b1),
          "three-source long retained behind arith");

    arith_valid_drv = 1'b0;
    #1;
    check(dut.exec1_take_w === 1'b1, "three-source exec1 second");
    check(dut.long_take_w === 1'b0, "three-source exec1 blocks long");
    check(dut.fp_result_wb_preg_w == 6'd35, "three-source exec1 pdest");
    check(dut.done_in_rob_w == 4'd6, "three-source exec1 ROB");
    check(dut.fp_result_wb_value_w == EXEC_VALUE, "three-source exec1 value");
    check(dut.done_in_fflags_w == 5'h0d, "three-source exec1 fflags");
    @(posedge clk);
    #1;
    check((dut.long_meta_valid_q === 1'b1) &&
          (dut.long_done_hold_q === 1'b1),
          "three-source long retained behind exec1");
    check(dut.long_take_w === 1'b1, "three-source long third");
    check(dut.fp_result_wb_preg_w == 6'd36, "three-source long pdest");
    check(dut.done_in_rob_w == 4'd7, "three-source long ROB");
    check(dut.fp_result_wb_value_w == LONG_VALUE, "three-source long value");
    check(dut.done_in_fflags_w == 5'h10, "three-source long fflags");
    @(posedge clk);
    #1;
    check((dut.long_meta_valid_q === 1'b0) &&
          (dut.long_done_hold_q === 1'b0),
          "three-source long consumed once");
    check(dut.done_fifo_count_q == 4'd3,
          "three-source produced exactly three FIFO entries");

    check_fpwb_tuple("three-source FIFO arith head", 4'd5, 6'd37,
                     1'b0, ARITH_VALUE, 5'h0e);
    fpwb_ready = 1'b1;
    @(posedge clk);
    #1;
    fpwb_ready = 1'b0;
    check(dut.done_fifo_count_q == 4'd2, "three-source FIFO after arith pop");
    check_fpwb_tuple("three-source FIFO exec1 head", 4'd6, 6'd35,
                     1'b0, EXEC_VALUE, 5'h0d);
    fpwb_ready = 1'b1;
    @(posedge clk);
    #1;
    fpwb_ready = 1'b0;
    check(dut.done_fifo_count_q == 4'd1, "three-source FIFO after exec1 pop");
    check_fpwb_tuple("three-source FIFO long head", 4'd7, 6'd36,
                     1'b0, LONG_VALUE, 5'h10);
    fpwb_ready = 1'b1;
    @(posedge clk);
    #1;
    fpwb_ready = 1'b0;
    check(dut.done_fifo_count_q == 4'd0, "three-source FIFO fully drained");
    check(fpwb_valid === 1'b0, "three-source FIFO no duplicate pulse");

    release dut.arith_out_valid_w;
    release dut.arith_out_rob_w;
    release dut.arith_out_pdest_w;
    release dut.arith_out_value_w;
    release dut.arith_out_fflags_w;

    if (failures == 0) begin
      $display("PASS tb_ooo_fp_backend_completion_kill checks=%0d", checks);
      $finish;
    end
    $fatal(1, "FAIL tb_ooo_fp_backend_completion_kill failures=%0d checks=%0d",
           failures, checks);
  end
endmodule
