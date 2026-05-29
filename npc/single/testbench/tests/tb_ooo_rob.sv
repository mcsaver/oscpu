`include "define.v"

module tb_ooo_rob;
  `include "tb_common.svh"

  localparam ROB_INDEX_W = 4;
  localparam ROB_COUNT_W = 5;
  localparam PHY_REG_ADDR_W = 6;

  reg clk;
  reg rst;
  reg flush;
  reg checkpoint_capture;
  reg checkpoint_restore;
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
  reg [ROB_INDEX_W-1:0] saved0;
  reg [ROB_INDEX_W-1:0] saved1;

  OooRob dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .checkpoint_capture_i(checkpoint_capture),
    .checkpoint_restore_i(checkpoint_restore),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_rob_idx_o(dispatch0_rob_idx),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_rd_en_i(dispatch0_rd_en),
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
    .dispatch1_arch_rd_i(dispatch1_arch_rd),
    .dispatch1_old_pdest_i(dispatch1_old_pdest),
    .dispatch1_new_pdest_i(dispatch1_new_pdest),
    .wb0_valid_i(wb0_valid),
    .wb0_rob_idx_i(wb0_rob_idx),
    .wb0_data_i(wb0_data),
    .wb0_exception_i(wb0_exception),
    .wb0_cause_i(wb0_cause),
    .wb0_tval_i(wb0_tval),
    .wb1_valid_i(wb1_valid),
    .wb1_rob_idx_i(wb1_rob_idx),
    .wb1_data_i(wb1_data),
    .wb1_exception_i(wb1_exception),
    .wb1_cause_i(wb1_cause),
    .wb1_tval_i(wb1_tval),
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
    .full_o(full)
  );

  wire unused_next_pc_w = (|commit0_next_pc) | (|commit1_next_pc);

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      checkpoint_capture = 1'b0;
      checkpoint_restore = 1'b0;
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

    checkpoint_capture = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    dispatch0_valid = 1'b1;
    dispatch0_pc = 32'h8000_0008;
    dispatch0_inst = 32'h0020_0193;
    dispatch0_rd_en = 1'b1;
    dispatch0_arch_rd = 5'd3;
    dispatch0_old_pdest = 6'd3;
    dispatch0_new_pdest = 6'd34;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("checkpoint mutation count", {27'b0, count}, 32'd3);
    checkpoint_restore = 1'b1;
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("checkpoint restore count", {27'b0, count}, 32'd2);
    tb_check1("checkpoint restore head still waits", commit0_valid, 1'b0);

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
    tb_check1("commit0 valid via wb bypass", commit0_valid, 1'b1);
    tb_check1("commit1 valid via existing done", commit1_valid, 1'b1);
    tb_check32("commit0 pc via wb bypass", commit0_pc, 32'h8000_0000);
    tb_check32("commit1 pc via existing done", commit1_pc, 32'h8000_0004);
    tb_check32("commit0 data via wb bypass", commit0_data, 32'h1111_0001);
    tb_check32("commit1 data via existing done", commit1_data, 32'h2222_0002);
    tb_check32("commit0 old pdest via wb bypass", {26'b0, commit0_old_pdest}, 32'd1);
    tb_check32("commit1 new pdest via existing done", {26'b0, commit1_new_pdest}, 32'd33);
    `TB_TICK(clk);
    clear_inputs();
    #1;
    tb_check32("count after dual commit", {27'b0, count}, 32'd0);

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
    tb_check1("exception head commit0 via wb bypass", commit0_valid, 1'b1);
    tb_check1("exception blocks commit1 via wb bypass", commit1_valid, 1'b0);
    tb_check1("commit0 exception via wb bypass", commit0_exception, 1'b1);
    tb_check32("commit0 cause via wb bypass", {27'b0, commit0_cause}, {27'b0, `EXC_ILLEGAL_INST});
    tb_check32("commit0 tval via wb bypass", commit0_tval, 32'hfeed_beef);
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

    tb_finish("tb_ooo_rob");
  end
endmodule
