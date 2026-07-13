`include "define.v"

// T3F：整数 formal-WB 对 FP IQ 的 GPR source 只能在上升沿落 sticky
// ready，不能把 resident entry 在 WB 当拍直接送进 select。本 TB 锁住双 wake lane、
// dispatch 同拍吸收、branch-kill survivor 和无关 wake 不阻塞独立 ready entry。
module tb_ooo_fp_issue_queue;
  `include "tb_common.svh"

  localparam ENTRY_INDEX_W = 3;
  localparam ROB_INDEX_W = 4;
  localparam PHY_REG_ADDR_W = 6;

  reg clk;
  reg rst;
  reg flush;
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob_idx;
  reg [ROB_INDEX_W-1:0] rob_head_idx;
  reg recover_active;

  reg dispatch_valid;
  wire dispatch_ready;
  reg [ROB_INDEX_W-1:0] dispatch_rob_idx;
  reg [`INST_W-1:0] dispatch_inst;
  reg dispatch_double;
  reg [PHY_REG_ADDR_W-1:0] dispatch_pdest;
  reg dispatch_dst_gpr;
  reg dispatch_dst_en;
  reg dispatch_fs1_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch_fs1_preg;
  reg dispatch_fs1_ready;
  reg dispatch_fs2_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch_fs2_preg;
  reg dispatch_fs2_ready;
  reg dispatch_fs3_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch_fs3_preg;
  reg dispatch_fs3_ready;
  reg dispatch_gpr_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch_gpr_preg;
  reg dispatch_gpr_ready;

  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [ROB_INDEX_W-1:0] dispatch1_rob_idx;
  reg [`INST_W-1:0] dispatch1_inst;
  reg dispatch1_double;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_pdest;
  reg dispatch1_dst_gpr;
  reg dispatch1_dst_en;
  reg dispatch1_fs1_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_fs1_preg;
  reg dispatch1_fs1_ready;
  reg dispatch1_fs2_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_fs2_preg;
  reg dispatch1_fs2_ready;
  reg dispatch1_fs3_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_fs3_preg;
  reg dispatch1_fs3_ready;
  reg dispatch1_gpr_en;
  reg [PHY_REG_ADDR_W-1:0] dispatch1_gpr_preg;
  reg dispatch1_gpr_ready;

  reg fp_wake0_valid;
  reg [PHY_REG_ADDR_W-1:0] fp_wake0_preg;
  reg fp_wake1_valid;
  reg [PHY_REG_ADDR_W-1:0] fp_wake1_preg;
  reg int_wake0_valid;
  reg [PHY_REG_ADDR_W-1:0] int_wake0_preg;
  reg int_wake1_valid;
  reg [PHY_REG_ADDR_W-1:0] int_wake1_preg;

  wire issue_valid;
  reg issue_ready;
  wire [ROB_INDEX_W-1:0] issue_rob_idx;
  wire [`INST_W-1:0] issue_inst;
  wire issue_double;
  wire [PHY_REG_ADDR_W-1:0] issue_pdest;
  wire issue_dst_gpr;
  wire issue_dst_en;
  wire [PHY_REG_ADDR_W-1:0] issue_fs1_preg;
  wire [PHY_REG_ADDR_W-1:0] issue_fs2_preg;
  wire [PHY_REG_ADDR_W-1:0] issue_fs3_preg;
  wire [PHY_REG_ADDR_W-1:0] issue_gpr_preg;
  wire [ENTRY_INDEX_W:0] count;

  OooFpIssueQueue #(
    .ENTRY_INDEX_W(ENTRY_INDEX_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .rob_head_idx_i(rob_head_idx),
    .recover_active_i(recover_active),
    .dispatch_valid_i(dispatch_valid),
    .dispatch_ready_o(dispatch_ready),
    .dispatch_rob_idx_i(dispatch_rob_idx),
    .dispatch_inst_i(dispatch_inst),
    .dispatch_double_i(dispatch_double),
    .dispatch_pdest_i(dispatch_pdest),
    .dispatch_dst_gpr_i(dispatch_dst_gpr),
    .dispatch_dst_en_i(dispatch_dst_en),
    .dispatch_fs1_en_i(dispatch_fs1_en),
    .dispatch_fs1_preg_i(dispatch_fs1_preg),
    .dispatch_fs1_ready_i(dispatch_fs1_ready),
    .dispatch_fs2_en_i(dispatch_fs2_en),
    .dispatch_fs2_preg_i(dispatch_fs2_preg),
    .dispatch_fs2_ready_i(dispatch_fs2_ready),
    .dispatch_fs3_en_i(dispatch_fs3_en),
    .dispatch_fs3_preg_i(dispatch_fs3_preg),
    .dispatch_fs3_ready_i(dispatch_fs3_ready),
    .dispatch_gpr_en_i(dispatch_gpr_en),
    .dispatch_gpr_preg_i(dispatch_gpr_preg),
    .dispatch_gpr_ready_i(dispatch_gpr_ready),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_rob_idx_i(dispatch1_rob_idx),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_double_i(dispatch1_double),
    .dispatch1_pdest_i(dispatch1_pdest),
    .dispatch1_dst_gpr_i(dispatch1_dst_gpr),
    .dispatch1_dst_en_i(dispatch1_dst_en),
    .dispatch1_fs1_en_i(dispatch1_fs1_en),
    .dispatch1_fs1_preg_i(dispatch1_fs1_preg),
    .dispatch1_fs1_ready_i(dispatch1_fs1_ready),
    .dispatch1_fs2_en_i(dispatch1_fs2_en),
    .dispatch1_fs2_preg_i(dispatch1_fs2_preg),
    .dispatch1_fs2_ready_i(dispatch1_fs2_ready),
    .dispatch1_fs3_en_i(dispatch1_fs3_en),
    .dispatch1_fs3_preg_i(dispatch1_fs3_preg),
    .dispatch1_fs3_ready_i(dispatch1_fs3_ready),
    .dispatch1_gpr_en_i(dispatch1_gpr_en),
    .dispatch1_gpr_preg_i(dispatch1_gpr_preg),
    .dispatch1_gpr_ready_i(dispatch1_gpr_ready),
    .fp_wake0_valid_i(fp_wake0_valid),
    .fp_wake0_preg_i(fp_wake0_preg),
    .fp_wake1_valid_i(fp_wake1_valid),
    .fp_wake1_preg_i(fp_wake1_preg),
    .int_wake0_valid_i(int_wake0_valid),
    .int_wake0_preg_i(int_wake0_preg),
    .int_wake1_valid_i(int_wake1_valid),
    .int_wake1_preg_i(int_wake1_preg),
    .issue_valid_o(issue_valid),
    .issue_ready_i(issue_ready),
    .issue_rob_idx_o(issue_rob_idx),
    .issue_inst_o(issue_inst),
    .issue_double_o(issue_double),
    .issue_pdest_o(issue_pdest),
    .issue_dst_gpr_o(issue_dst_gpr),
    .issue_dst_en_o(issue_dst_en),
    .issue_fs1_preg_o(issue_fs1_preg),
    .issue_fs2_preg_o(issue_fs2_preg),
    .issue_fs3_preg_o(issue_fs3_preg),
    .issue_gpr_preg_o(issue_gpr_preg),
    .count_o(count)
  );

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      kill_valid = 1'b0;
      kill_rob_idx = {ROB_INDEX_W{1'b0}};
      rob_head_idx = {ROB_INDEX_W{1'b0}};
      recover_active = 1'b0;
      dispatch_valid = 1'b0;
      dispatch_rob_idx = {ROB_INDEX_W{1'b0}};
      dispatch_inst = {`INST_W{1'b0}};
      dispatch_double = 1'b0;
      dispatch_pdest = {PHY_REG_ADDR_W{1'b0}};
      dispatch_dst_gpr = 1'b0;
      dispatch_dst_en = 1'b0;
      dispatch_fs1_en = 1'b0;
      dispatch_fs1_preg = {PHY_REG_ADDR_W{1'b0}};
      dispatch_fs1_ready = 1'b0;
      dispatch_fs2_en = 1'b0;
      dispatch_fs2_preg = {PHY_REG_ADDR_W{1'b0}};
      dispatch_fs2_ready = 1'b0;
      dispatch_fs3_en = 1'b0;
      dispatch_fs3_preg = {PHY_REG_ADDR_W{1'b0}};
      dispatch_fs3_ready = 1'b0;
      dispatch_gpr_en = 1'b0;
      dispatch_gpr_preg = {PHY_REG_ADDR_W{1'b0}};
      dispatch_gpr_ready = 1'b0;
      dispatch1_valid = 1'b0;
      dispatch1_rob_idx = {ROB_INDEX_W{1'b0}};
      dispatch1_inst = {`INST_W{1'b0}};
      dispatch1_double = 1'b0;
      dispatch1_pdest = {PHY_REG_ADDR_W{1'b0}};
      dispatch1_dst_gpr = 1'b0;
      dispatch1_dst_en = 1'b0;
      dispatch1_fs1_en = 1'b0;
      dispatch1_fs1_preg = {PHY_REG_ADDR_W{1'b0}};
      dispatch1_fs1_ready = 1'b0;
      dispatch1_fs2_en = 1'b0;
      dispatch1_fs2_preg = {PHY_REG_ADDR_W{1'b0}};
      dispatch1_fs2_ready = 1'b0;
      dispatch1_fs3_en = 1'b0;
      dispatch1_fs3_preg = {PHY_REG_ADDR_W{1'b0}};
      dispatch1_fs3_ready = 1'b0;
      dispatch1_gpr_en = 1'b0;
      dispatch1_gpr_preg = {PHY_REG_ADDR_W{1'b0}};
      dispatch1_gpr_ready = 1'b0;
      fp_wake0_valid = 1'b0;
      fp_wake0_preg = {PHY_REG_ADDR_W{1'b0}};
      fp_wake1_valid = 1'b0;
      fp_wake1_preg = {PHY_REG_ADDR_W{1'b0}};
      int_wake0_valid = 1'b0;
      int_wake0_preg = {PHY_REG_ADDR_W{1'b0}};
      int_wake1_valid = 1'b0;
      int_wake1_preg = {PHY_REG_ADDR_W{1'b0}};
      issue_ready = 1'b1;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic dispatch_waiting_gpr_entry;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] gpr_preg;
    begin
      dispatch_valid = 1'b1;
      dispatch_rob_idx = rob_idx;
      dispatch_inst = 32'hd200_0053;
      dispatch_double = 1'b1;
      dispatch_pdest = 6'd40;
      dispatch_dst_en = 1'b1;
      dispatch_gpr_en = 1'b1;
      dispatch_gpr_preg = gpr_preg;
      dispatch_gpr_ready = 1'b0;
    end
  endtask

  task automatic dispatch1_waiting_gpr_entry;
    input [ROB_INDEX_W-1:0] rob_idx;
    input [PHY_REG_ADDR_W-1:0] gpr_preg;
    begin
      dispatch1_valid = 1'b1;
      dispatch1_rob_idx = rob_idx;
      dispatch1_inst = 32'hd200_0053;
      dispatch1_double = 1'b1;
      dispatch1_pdest = 6'd41;
      dispatch1_dst_en = 1'b1;
      dispatch1_gpr_en = 1'b1;
      dispatch1_gpr_preg = gpr_preg;
      dispatch1_gpr_ready = 1'b0;
    end
  endtask

  task automatic run_full_wake0_resident;
    begin
      reset_dut();
      tb_check32("wake0 reset count", {28'b0, count}, 32'd0);
      dispatch_waiting_gpr_entry(4'd2, 6'd33);
      #1;
      tb_check1("wake0 waiting GPR entry dispatch ready", dispatch_ready, 1'b1);
      tb_check1("wake0 dispatch does not bypass into issue", issue_valid, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("wake0 waiting GPR entry resident", {28'b0, count}, 32'd1);
      tb_check1("wake0 resident GPR source starts unready", dut.gpr_ready_q[0], 1'b0);
      tb_check1("wake0 resident waits before integer WB", issue_valid, 1'b0);

      issue_ready = 1'b0;
      int_wake0_valid = 1'b1;
      int_wake0_preg = 6'd33;
      #1;
      $display("[T3F-GREEN-OBS] wake0 N full={valid=%0b,preg=%0d} resident={valid=%0b,gpr_ready=%0b} issue={valid=%0b,ready=%0b}",
               int_wake0_valid, int_wake0_preg, dut.valid_q[0],
               dut.gpr_ready_q[0], issue_valid, issue_ready);
      tb_check1("T3F wake0 full-only resident stays blocked in N", issue_valid, 1'b0);
      tb_check32("T3F wake0 full-only resident preserved in N", {28'b0, count}, 32'd1);

      `TB_TICK(clk);
      int_wake0_valid = 1'b0;
      int_wake0_preg = 6'd0;
      issue_ready = 1'b1;
      #1;
      $display("[T3F-GREEN-OBS] wake0 N+1 sticky={gpr_ready=%0b} issue={valid=%0b,rob=%0d,gpr=%0d}",
               dut.gpr_ready_q[0], issue_valid, issue_rob_idx, issue_gpr_preg);
      tb_check1("T3F wake0 formal WB sets sticky ready at N edge",
                dut.gpr_ready_q[0], 1'b1);
      tb_check1("T3F wake0 sticky resident issues in N+1", issue_valid, 1'b1);
      tb_check32("T3F wake0 N+1 issue ROB identity", {28'b0, issue_rob_idx}, 32'd2);
      tb_check32("T3F wake0 N+1 issue GPR identity", {26'b0, issue_gpr_preg}, 32'd33);
      `TB_TICK(clk);
      #1;
      tb_check32("T3F wake0 resident drains after N+1 fire", {28'b0, count}, 32'd0);
    end
  endtask

  task automatic run_full_wake1_resident;
    begin
      reset_dut();
      dispatch_waiting_gpr_entry(4'd3, 6'd34);
      #1;
      tb_check1("wake1 waiting GPR entry dispatch ready", dispatch_ready, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      issue_ready = 1'b0;
      int_wake1_valid = 1'b1;
      int_wake1_preg = 6'd34;
      #1;
      tb_check1("T3F wake1 full-only resident stays blocked in N", issue_valid, 1'b0);
      tb_check1("T3F wake1 resident remains sticky-unready in N",
                dut.gpr_ready_q[0], 1'b0);
      `TB_TICK(clk);
      int_wake1_valid = 1'b0;
      int_wake1_preg = 6'd0;
      issue_ready = 1'b1;
      #1;
      $display("[T3F-GREEN-OBS] wake1 N+1 sticky=%0b issue={valid=%0b,rob=%0d,gpr=%0d}",
               dut.gpr_ready_q[0], issue_valid, issue_rob_idx, issue_gpr_preg);
      tb_check1("T3F wake1 formal WB sets sticky ready at N edge",
                dut.gpr_ready_q[0], 1'b1);
      tb_check1("T3F wake1 sticky resident issues in N+1", issue_valid, 1'b1);
      tb_check32("T3F wake1 N+1 issue ROB identity", {28'b0, issue_rob_idx}, 32'd3);
      `TB_TICK(clk);
      #1;
      tb_check32("T3F wake1 resident drains after N+1 fire", {28'b0, count}, 32'd0);
    end
  endtask

  task automatic run_dispatch_full_wake_collision;
    begin
      reset_dut();
      issue_ready = 1'b0;
      dispatch_waiting_gpr_entry(4'd4, 6'd35);
      int_wake0_valid = 1'b1;
      int_wake0_preg = 6'd35;
      #1;
      tb_check1("T3F dispatch/full collision accepted", dispatch_ready, 1'b1);
      tb_check1("T3F dispatch/full collision cannot issue in dispatch N",
                issue_valid, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      $display("[T3F-GREEN-OBS] dispatch/full N+1 resident=%0b sticky=%0b issue={valid=%0b,rob=%0d}",
               dut.valid_q[0], dut.gpr_ready_q[0], issue_valid, issue_rob_idx);
      tb_check32("T3F dispatch/full collision creates one resident",
                 {28'b0, count}, 32'd1);
      tb_check1("T3F dispatch/full collision captures sticky on N edge",
                dut.gpr_ready_q[0], 1'b1);
      tb_check1("T3F dispatch/full collision issues in N+1", issue_valid, 1'b1);
      tb_check32("T3F dispatch/full collision ROB identity",
                 {28'b0, issue_rob_idx}, 32'd4);
      `TB_TICK(clk);
      #1;
      tb_check32("T3F dispatch/full collision drains", {28'b0, count}, 32'd0);
    end
  endtask

  task automatic run_kill_survivor_full_wake;
    begin
      reset_dut();
      dispatch_waiting_gpr_entry(4'd2, 6'd36);
      dispatch1_waiting_gpr_entry(4'd6, 6'd36);
      #1;
      tb_check1("T3F kill setup lane0 dispatch ready", dispatch_ready, 1'b1);
      tb_check1("T3F kill setup lane1 dispatch ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("T3F kill setup has two residents", {28'b0, count}, 32'd2);
      tb_check1("T3F kill setup survivor slot valid", dut.valid_q[0], 1'b1);
      tb_check1("T3F kill setup younger slot valid", dut.valid_q[1], 1'b1);

      kill_valid = 1'b1;
      kill_rob_idx = 4'd4;
      rob_head_idx = 4'd0;
      int_wake0_valid = 1'b1;
      int_wake0_preg = 6'd36;
      #1;
      tb_check1("T3F kill/full same cycle blocks issue", issue_valid, 1'b0);
      tb_check1("T3F kill marks older slot as survivor", dut.squash_r[0], 1'b0);
      tb_check1("T3F kill marks younger slot for squash", dut.squash_r[1], 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      $display("[T3F-GREEN-OBS] kill/full post count=%0d valid={%0b,%0b} survivor_sticky=%0b issue={valid=%0b,rob=%0d}",
               count, dut.valid_q[0], dut.valid_q[1], dut.gpr_ready_q[0],
               issue_valid, issue_rob_idx);
      tb_check32("T3F kill removes only younger entry", {28'b0, count}, 32'd1);
      tb_check1("T3F kill survivor remains valid", dut.valid_q[0], 1'b1);
      tb_check1("T3F kill younger entry is cleared", dut.valid_q[1], 1'b0);
      tb_check1("T3F kill survivor absorbs same-cycle full wake",
                dut.gpr_ready_q[0], 1'b1);
      tb_check1("T3F kill survivor issues in N+1", issue_valid, 1'b1);
      tb_check32("T3F kill survivor ROB identity", {28'b0, issue_rob_idx}, 32'd2);
      `TB_TICK(clk);
      #1;
      tb_check32("T3F kill survivor drains", {28'b0, count}, 32'd0);
    end
  endtask

  task automatic run_ready_entry_unrelated_wake;
    begin
      reset_dut();
      issue_ready = 1'b0;
      dispatch_waiting_gpr_entry(4'd7, 6'd37);
      dispatch_gpr_ready = 1'b1;
      #1;
      tb_check1("T3F ready entry dispatch accepted", dispatch_ready, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      issue_ready = 1'b0;
      #1;
      tb_check1("T3F independent entry is ready before unrelated wake",
                issue_valid, 1'b1);
      int_wake1_valid = 1'b1;
      int_wake1_preg = 6'd38;
      issue_ready = 1'b1;
      #1;
      $display("[T3F-GREEN-OBS] unrelated full=38 ready_entry={valid=%0b,rob=%0d,gpr=%0d}",
               issue_valid, issue_rob_idx, issue_gpr_preg);
      tb_check1("T3F unrelated integer wake does not block ready entry",
                issue_valid, 1'b1);
      tb_check32("T3F unrelated wake preserves ready ROB identity",
                 {28'b0, issue_rob_idx}, 32'd7);
      tb_check32("T3F unrelated wake preserves ready GPR identity",
                 {26'b0, issue_gpr_preg}, 32'd37);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("T3F ready entry drains under unrelated wake",
                 {28'b0, count}, 32'd0);
    end
  endtask

  task automatic run_recover_absorbs_wake;
    begin
      reset_dut();
      dispatch_waiting_gpr_entry(4'd5, 6'd39);
      `TB_TICK(clk);
      clear_inputs();
      recover_active = 1'b1;
      int_wake0_valid = 1'b1;
      int_wake0_preg = 6'd39;
      #1;
      tb_check1("T3F recover blocks issue in wake cycle", issue_valid, 1'b0);
      `TB_TICK(clk);
      int_wake0_valid = 1'b0;
      int_wake0_preg = 6'd0;
      #1;
      tb_check1("T3F recover survivor absorbed sticky wake",
                dut.gpr_ready_q[0], 1'b1);
      tb_check1("T3F multi-cycle recover continues to block issue",
                issue_valid, 1'b0);
      `TB_TICK(clk);
      recover_active = 1'b0;
      #1;
      tb_check1("T3F recovered sticky survivor issues", issue_valid, 1'b1);
      tb_check32("T3F recovered sticky survivor ROB identity",
                 {28'b0, issue_rob_idx}, 32'd5);
      `TB_TICK(clk);
      #1;
      tb_check32("T3F recovered sticky survivor drains",
                 {28'b0, count}, 32'd0);
    end
  endtask

  task automatic run_flush_discards_dispatch_wake;
    begin
      reset_dut();
      flush = 1'b1;
      dispatch_waiting_gpr_entry(4'd6, 6'd40);
      int_wake0_valid = 1'b1;
      int_wake0_preg = 6'd40;
      #1;
      tb_check1("T3F flush cycle never issues", issue_valid, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("T3F flush discards same-cycle dispatch and wake",
                 {28'b0, count}, 32'd0);
      tb_check1("T3F flush leaves no resurrected issue", issue_valid, 1'b0);
    end
  endtask

  task automatic run_lane1_dispatch_wake1_collision;
    begin
      reset_dut();
      issue_ready = 1'b0;
      dispatch_waiting_gpr_entry(4'd1, 6'd41);
      dispatch_gpr_ready = 1'b1;
      dispatch1_waiting_gpr_entry(4'd2, 6'd42);
      int_wake1_valid = 1'b1;
      int_wake1_preg = 6'd42;
      #1;
      tb_check1("T3F lane1 collision both slots accepted", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check32("T3F lane1 collision creates two residents",
                 {28'b0, count}, 32'd2);
      tb_check1("T3F lane1 collision captures wake1 sticky",
                dut.gpr_ready_q[1], 1'b1);
      tb_check32("T3F lane1 collision oldest lane0 issues first",
                 {28'b0, issue_rob_idx}, 32'd1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3F lane1 collision entry remains ready", issue_valid, 1'b1);
      tb_check32("T3F lane1 collision ROB identity",
                 {28'b0, issue_rob_idx}, 32'd2);
      `TB_TICK(clk);
      #1;
      tb_check32("T3F lane1 collision drains", {28'b0, count}, 32'd0);
    end
  endtask

  task automatic run_preg0_ready_without_wake;
    begin
      reset_dut();
      dispatch_waiting_gpr_entry(4'd3, {PHY_REG_ADDR_W{1'b0}});
      dispatch_gpr_ready = 1'b1;
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("T3F preg0 source is ready without fake wake", issue_valid, 1'b1);
      tb_check32("T3F preg0 source identity", {26'b0, issue_gpr_preg}, 32'd0);
      `TB_TICK(clk);
      #1;
      tb_check32("T3F preg0 source drains", {28'b0, count}, 32'd0);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

`ifdef FP_INT_WAKE0_WRITE_NEGATIVE
    // T3F wake 必须与真实非零 GPR write event 同义。
    int_wake0_valid = 1'b1;
    int_wake0_preg = {PHY_REG_ADDR_W{1'b0}};
    $display("[FP-INT-WAKE-WRITE-NEGATIVE] arm lane0 p0 wake");
    `TB_TICK(clk);
    $finish_and_return(0);
`endif

`ifdef FP_INT_WAKE1_WRITE_NEGATIVE
    int_wake1_valid = 1'b1;
    int_wake1_preg = {PHY_REG_ADDR_W{1'b0}};
    $display("[FP-INT-WAKE-WRITE-NEGATIVE] arm lane1 p0 wake");
    `TB_TICK(clk);
    $finish_and_return(0);
`endif

`ifdef FP_IQ_INT_STICKY_NEGATIVE
    // 先合法建立未 ready resident，再施加匹配 formal wake。自然组合结果必须
    // 保持不发射；只 force ready 视图跨一个 assertion edge，证明断言非真空。
    dispatch_waiting_gpr_entry(4'd2, 6'd33);
    #1;
    tb_check1("T3F sticky negative dispatch ready", dispatch_ready, 1'b1);
    `TB_TICK(clk);
    clear_inputs();
    issue_ready = 1'b0;
    int_wake0_valid = 1'b1;
    int_wake0_preg = 6'd33;
    #1;
    tb_check1("T3F sticky negative resident valid", dut.valid_q[0], 1'b1);
    tb_check1("T3F sticky negative source unready", dut.gpr_ready_q[0], 1'b0);
    tb_check1("T3F sticky negative natural issue blocked", issue_valid, 1'b0);
    force dut.entry_ready_r[0] = 1'b1;
    #1;
    $display("[FP-IQ-INT-STICKY-NEGATIVE] force entry_ready[0], issue=%0b sticky=%0b full=%0b/%0d",
             issue_valid, dut.gpr_ready_q[0], int_wake0_valid, int_wake0_preg);
    `TB_TICK(clk);
    release dut.entry_ready_r[0];
    #1;
    $display("[FP-IQ-INT-STICKY-NEGATIVE] completed one assertion edge");
    $finish_and_return(0);
`endif

    run_full_wake0_resident();
    run_full_wake1_resident();
    run_dispatch_full_wake_collision();
    run_kill_survivor_full_wake();
    run_ready_entry_unrelated_wake();
    run_recover_absorbs_wake();
    run_flush_discards_dispatch_wake();
    run_lane1_dispatch_wake1_collision();
    run_preg0_ready_without_wake();
    tb_finish("tb_ooo_fp_issue_queue");
  end

  wire unused_issue_payload_w = (|issue_inst) | issue_double | (|issue_pdest) |
      issue_dst_gpr | issue_dst_en | (|issue_fs1_preg) | (|issue_fs2_preg) |
      (|issue_fs3_preg) | dispatch1_ready;

endmodule
