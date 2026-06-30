`timescale 1ns/1ps
`include "define.v"

module tb_ooo_pending_fp_sequencer;
  reg clk;
  reg rst;
  reg late_clear;
  reg clear;
  reg capture_head0;
  reg capture_head0_load;
  reg capture_head0_store;
  reg capture_head0_double;
  reg capture_head0_gpr_write;
  reg [`XLEN-1:0] capture_head0_pc;
  reg [`INST_W-1:0] capture_head0_inst;
  reg [`XLEN-1:0] capture_head0_next_pc;
  reg [`REG_ADDR_W-1:0] capture_head0_rd;
  reg capture_lane1;
  reg capture_lane1_valid;
  reg capture_lane1_load;
  reg capture_lane1_store;
  reg capture_lane1_double;
  reg capture_lane1_gpr_write;
  reg [`XLEN-1:0] capture_lane1_pc;
  reg [`INST_W-1:0] capture_lane1_inst;
  reg [`XLEN-1:0] capture_lane1_next_pc;
  reg [`REG_ADDR_W-1:0] capture_lane1_rd;
  reg mem_req_fire;
  reg [`XLEN-1:0] mem_req_addr;
  reg [`XLEN-1:0] mem_req_wdata;
  reg [`STRB_W-1:0] mem_req_wstrb;
  reg mem_rsp_fire;
  reg long_start;
  reg long_done_i;
  reg [`XLEN-1:0] long_done_result;
  reg [4:0] long_done_fflags;
  reg compute_start;
  reg compute_ready;
  reg [`XLEN-1:0] compute_result;
  reg [4:0] compute_fflags;

  wire valid;
  wire mem_pending;
  wire mem_done;
  wire long_pending;
  wire long_done;
  wire [`XLEN-1:0] long_result;
  wire [4:0] long_fflags;
  wire compute_done;
  wire [`XLEN-1:0] compute_result_q;
  wire [4:0] compute_fflags_q;
  wire load;
  wire store;
  wire double_bit;
  wire gpr_write;
  wire [`XLEN-1:0] pc;
  wire [`INST_W-1:0] inst;
  wire [`XLEN-1:0] next_pc;
  wire [`XLEN-1:0] addr;
  wire [`XLEN-1:0] wdata;
  wire [`STRB_W-1:0] wstrb;
  wire [`REG_ADDR_W-1:0] rd;

  integer errors;

  OooPendingFpSequencer dut (
    .clk(clk),
    .rst(rst),
    .late_clear_i(late_clear),
    .clear_i(clear),
    .capture_head0_i(capture_head0),
    .capture_head0_load_i(capture_head0_load),
    .capture_head0_store_i(capture_head0_store),
    .capture_head0_double_i(capture_head0_double),
    .capture_head0_gpr_write_i(capture_head0_gpr_write),
    .capture_head0_pc_i(capture_head0_pc),
    .capture_head0_inst_i(capture_head0_inst),
    .capture_head0_next_pc_i(capture_head0_next_pc),
    .capture_head0_rd_i(capture_head0_rd),
    .capture_lane1_i(capture_lane1),
    .capture_lane1_valid_i(capture_lane1_valid),
    .capture_lane1_load_i(capture_lane1_load),
    .capture_lane1_store_i(capture_lane1_store),
    .capture_lane1_double_i(capture_lane1_double),
    .capture_lane1_gpr_write_i(capture_lane1_gpr_write),
    .capture_lane1_pc_i(capture_lane1_pc),
    .capture_lane1_inst_i(capture_lane1_inst),
    .capture_lane1_next_pc_i(capture_lane1_next_pc),
    .capture_lane1_rd_i(capture_lane1_rd),
    .mem_req_fire_i(mem_req_fire),
    .mem_req_addr_i(mem_req_addr),
    .mem_req_wdata_i(mem_req_wdata),
    .mem_req_wstrb_i(mem_req_wstrb),
    .mem_rsp_fire_i(mem_rsp_fire),
    .long_start_i(long_start),
    .long_done_i(long_done_i),
    .long_done_result_i(long_done_result),
    .long_done_fflags_i(long_done_fflags),
    .compute_start_i(compute_start),
    .compute_ready_i(compute_ready),
    .compute_result_i(compute_result),
    .compute_fflags_i(compute_fflags),
    .valid_o(valid),
    .mem_pending_o(mem_pending),
    .mem_done_o(mem_done),
    .long_pending_o(long_pending),
    .long_done_o(long_done),
    .long_result_o(long_result),
    .long_fflags_o(long_fflags),
    .compute_done_o(compute_done),
    .compute_result_o(compute_result_q),
    .compute_fflags_o(compute_fflags_q),
    .load_o(load),
    .store_o(store),
    .double_o(double_bit),
    .gpr_write_o(gpr_write),
    .pc_o(pc),
    .inst_o(inst),
    .next_pc_o(next_pc),
    .addr_o(addr),
    .wdata_o(wdata),
    .wstrb_o(wstrb),
    .rd_o(rd)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tb_check1;
    input [255:0] name;
    input actual;
    input expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=%0b expected=%0b", name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check5;
    input [255:0] name;
    input [4:0] actual;
    input [4:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%02h expected=0x%02h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check_reg;
    input [255:0] name;
    input [`REG_ADDR_W-1:0] actual;
    input [`REG_ADDR_W-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=%0d expected=%0d", name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check64;
    input [255:0] name;
    input [`XLEN-1:0] actual;
    input [`XLEN-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%016h expected=0x%016h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic tb_check_inst;
    input [255:0] name;
    input [`INST_W-1:0] actual;
    input [`INST_W-1:0] expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=0x%08h expected=0x%08h",
                 name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      late_clear = 1'b0;
      clear = 1'b0;
      capture_head0 = 1'b0;
      capture_head0_load = 1'b0;
      capture_head0_store = 1'b0;
      capture_head0_double = 1'b0;
      capture_head0_gpr_write = 1'b0;
      capture_head0_pc = 64'h0000_0000_8000_1000;
      capture_head0_inst = 32'h0000_7053;
      capture_head0_next_pc = 64'h0000_0000_8000_1004;
      capture_head0_rd = 5'd3;
      capture_lane1 = 1'b0;
      capture_lane1_valid = 1'b0;
      capture_lane1_load = 1'b0;
      capture_lane1_store = 1'b0;
      capture_lane1_double = 1'b0;
      capture_lane1_gpr_write = 1'b0;
      capture_lane1_pc = 64'h0000_0000_8000_2004;
      capture_lane1_inst = 32'h0000_7853;
      capture_lane1_next_pc = 64'h0000_0000_8000_2008;
      capture_lane1_rd = 5'd4;
      mem_req_fire = 1'b0;
      mem_req_addr = 64'h0000_0000_9000_0004;
      mem_req_wdata = 64'h1122_3344_5566_7788;
      mem_req_wstrb = 8'hf0;
      mem_rsp_fire = 1'b0;
      long_start = 1'b0;
      long_done_i = 1'b0;
      long_done_result = 64'h0102_0304_0506_0708;
      long_done_fflags = 5'b10001;
      compute_start = 1'b0;
      compute_ready = 1'b1;  // 非流水路径默认就绪;本 TB 单独验 sequencer 锁存语义
      compute_result = 64'h8877_6655_4433_2211;
      compute_fflags = 5'b00101;
    end
  endtask

  task automatic tick;
    begin
      @(negedge clk);
      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    errors = 0;
    clear_inputs();
    rst = 1'b1;
    repeat (2) tick();
    tb_check1("reset valid", valid, 1'b0);
    tb_check1("reset mem pending", mem_pending, 1'b0);
    tb_check1("reset mem done", mem_done, 1'b0);
    tb_check64("reset pc", pc, {`XLEN{1'b0}});
    tb_check_inst("reset inst", inst, {`INST_W{1'b0}});

    rst = 1'b0;
    clear_inputs();
    capture_head0 = 1'b1;
    capture_head0_load = 1'b1;
    capture_head0_double = 1'b1;
    capture_head0_pc = 64'h0000_0000_8000_3000;
    capture_head0_inst = 32'h0000_3787;
    capture_head0_next_pc = 64'h0000_0000_8000_3004;
    capture_head0_rd = 5'd15;
    tick();
    tb_check1("head0 capture valid", valid, 1'b1);
    tb_check1("head0 capture load", load, 1'b1);
    tb_check1("head0 capture mem done", mem_done, 1'b0);
    tb_check1("head0 capture double", double_bit, 1'b1);
    tb_check64("head0 capture pc", pc, 64'h0000_0000_8000_3000);
    tb_check_inst("head0 capture inst", inst, 32'h0000_3787);
    tb_check_reg("head0 capture rd", rd, 5'd15);

    clear_inputs();
    mem_req_fire = 1'b1;
    mem_req_addr = 64'h0000_0000_9000_0018;
    mem_req_wdata = 64'haaaa_bbbb_cccc_dddd;
    mem_req_wstrb = 8'h0f;
    tick();
    tb_check1("mem req pending", mem_pending, 1'b1);
    tb_check64("mem req addr", addr, 64'h0000_0000_9000_0018);
    tb_check64("mem req wdata", wdata, 64'haaaa_bbbb_cccc_dddd);
    tb_check64("mem req wstrb", {{(`XLEN-`STRB_W){1'b0}}, wstrb},
               {{(`XLEN-`STRB_W){1'b0}}, 8'h0f});

    clear_inputs();
    mem_rsp_fire = 1'b1;
    tick();
    tb_check1("mem rsp clears pending", mem_pending, 1'b0);
    tb_check1("mem rsp done", mem_done, 1'b1);

    clear_inputs();
    capture_head0 = 1'b1;
    capture_head0_double = 1'b1;
    capture_head0_rd = 5'd8;
    tick();
    tb_check1("compute entry mem done", mem_done, 1'b1);

    clear_inputs();
    compute_start = 1'b1;
    compute_result = 64'h1234_5678_9abc_def0;
    compute_fflags = 5'b00011;
    tick();
    tb_check1("compute done", compute_done, 1'b1);
    tb_check64("compute result", compute_result_q, 64'h1234_5678_9abc_def0);
    tb_check5("compute fflags", compute_fflags_q, 5'b00011);

    clear_inputs();
    long_start = 1'b1;
    tick();
    tb_check1("long pending", long_pending, 1'b1);
    tb_check1("long done cleared by start", long_done, 1'b0);

    clear_inputs();
    long_done_i = 1'b1;
    long_done_result = 64'hfeed_face_cafe_beef;
    long_done_fflags = 5'b10100;
    tick();
    tb_check1("long pending cleared", long_pending, 1'b0);
    tb_check1("long done", long_done, 1'b1);
    tb_check64("long result", long_result, 64'hfeed_face_cafe_beef);
    tb_check5("long fflags", long_fflags, 5'b10100);

    clear_inputs();
    clear = 1'b1;
    tick();
    tb_check1("clear valid", valid, 1'b0);
    tb_check1("clear load", load, 1'b0);
    tb_check1("clear store", store, 1'b0);
    tb_check1("clear gpr write", gpr_write, 1'b0);
    tb_check1("clear keeps double", double_bit, 1'b1);
    tb_check64("clear keeps pc", pc, 64'h0000_0000_8000_1000);

    clear_inputs();
    capture_lane1 = 1'b1;
    capture_lane1_valid = 1'b0;
    capture_lane1_load = 1'b1;
    capture_lane1_pc = 64'h0000_0000_8000_4004;
    capture_lane1_inst = 32'h0000_2707;
    capture_lane1_next_pc = 64'h0000_0000_8000_4008;
    capture_lane1_rd = 5'd14;
    tick();
    tb_check1("lane1 non-fp valid", valid, 1'b0);
    tb_check1("lane1 non-fp load gated", load, 1'b0);
    tb_check64("lane1 non-fp pc", pc, 64'h0000_0000_8000_4004);
    tb_check_inst("lane1 non-fp inst", inst, 32'h0000_2707);

    clear_inputs();
    clear = 1'b1;
    capture_lane1 = 1'b1;
    capture_lane1_valid = 1'b1;
    capture_lane1_store = 1'b1;
    capture_lane1_pc = 64'h0000_0000_8000_5004;
    capture_lane1_inst = 32'h00f0_3027;
    capture_lane1_next_pc = 64'h0000_0000_8000_5008;
    tick();
    tb_check1("lane1 capture over clear", valid, 1'b1);
    tb_check1("lane1 store", store, 1'b1);
    tb_check1("lane1 store mem done", mem_done, 1'b0);
    tb_check64("lane1 capture pc", pc, 64'h0000_0000_8000_5004);

    clear_inputs();
    capture_lane1 = 1'b1;
    capture_lane1_valid = 1'b1;
    capture_lane1_pc = 64'h0000_0000_8000_6004;
    capture_head0 = 1'b1;
    capture_head0_pc = 64'h0000_0000_8000_6000;
    tick();
    tb_check64("head0 over lane1 pc", pc, 64'h0000_0000_8000_6000);

    clear_inputs();
    late_clear = 1'b1;
    capture_head0 = 1'b1;
    capture_head0_pc = 64'h0000_0000_8000_7000;
    capture_head0_next_pc = 64'h0000_0000_8000_7004;
    tick();
    tb_check1("late clear valid", valid, 1'b0);
    tb_check64("late clear keeps pc", pc, 64'h0000_0000_8000_7000);
    tb_check64("late clear clears next pc", next_pc, {`XLEN{1'b0}});

    if (errors == 0) begin
      $display("PASS tb_ooo_pending_fp_sequencer");
      $finish;
    end
    $display("FAIL tb_ooo_pending_fp_sequencer errors=%0d", errors);
    $finish;
  end

endmodule
