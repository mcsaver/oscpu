`include "define.v"

module tb_ooo_branch_target_cache;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg clear;

  reg [`XLEN-1:0] lookup_branch_pc;
  reg [`XLEN-1:0] lookup_target_pc;
  wire [1:0] lookup_idx;
  wire lookup_hit;
  wire [`XLEN-1:0] lookup_target_pc_out;
  wire [`XLEN-1:0] lookup_next_pc;
  wire [`INST_W-1:0] lookup_inst;

  reg invalidate_all;
  reg store_fire;
  reg [`XLEN-1:0] store_addr;

  reg capture_valid;
  reg [`XLEN-1:0] capture_branch_pc;
  reg [`XLEN-1:0] capture_target_pc;
  reg [`XLEN-1:0] capture_next_pc;
  reg [`INST_W-1:0] capture_inst;

  localparam [`XLEN-1:0] BR0 = 64'h0000_0000_8000_0100;
  localparam [`XLEN-1:0] BR1 = 64'h0000_0000_8000_0104;
  localparam [`XLEN-1:0] BR2 = 64'h0000_0000_8000_0108;
  localparam [`XLEN-1:0] TG0 = 64'h0000_0000_8000_2000;
  localparam [`XLEN-1:0] TG1 = 64'h0000_0000_8000_3000;
  localparam [`XLEN-1:0] TG2 = 64'h0000_0000_8000_4000;

  OooBranchTargetCache #(
    .INDEX_W(2)
  ) dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .lookup_branch_pc_i(lookup_branch_pc),
    .lookup_target_pc_i(lookup_target_pc),
    .lookup_idx_o(lookup_idx),
    .lookup_hit_o(lookup_hit),
    .lookup_target_pc_o(lookup_target_pc_out),
    .lookup_next_pc_o(lookup_next_pc),
    .lookup_inst_o(lookup_inst),
    .invalidate_all_i(invalidate_all),
    .store_fire_i(store_fire),
    .store_addr_i(store_addr),
    .capture_valid_i(capture_valid),
    .capture_branch_pc_i(capture_branch_pc),
    .capture_target_pc_i(capture_target_pc),
    .capture_next_pc_i(capture_next_pc),
    .capture_inst_i(capture_inst)
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

  task automatic tick;
    begin
      `TB_TICK(clk)
    end
  endtask

  task automatic clear_inputs;
    begin
      clear = 1'b0;
      lookup_branch_pc = BR0;
      lookup_target_pc = TG0;
      invalidate_all = 1'b0;
      store_fire = 1'b0;
      store_addr = {`XLEN{1'b0}};
      capture_valid = 1'b0;
      capture_branch_pc = {`XLEN{1'b0}};
      capture_target_pc = {`XLEN{1'b0}};
      capture_next_pc = {`XLEN{1'b0}};
      capture_inst = {`INST_W{1'b0}};
    end
  endtask

  task automatic capture_entry;
    input [`XLEN-1:0] branch_pc;
    input [`XLEN-1:0] target_pc;
    input [`XLEN-1:0] next_pc;
    input [`INST_W-1:0] inst;
    begin
      capture_branch_pc = branch_pc;
      capture_target_pc = target_pc;
      capture_next_pc = next_pc;
      capture_inst = inst;
      capture_valid = 1'b1;
      tick();
      capture_valid = 1'b0;
      #1;
    end
  endtask

  task automatic expect_lookup;
    input [1023:0] label;
    input [`XLEN-1:0] branch_pc;
    input [`XLEN-1:0] target_pc;
    input exp_hit;
    input [`XLEN-1:0] exp_next_pc;
    input [`INST_W-1:0] exp_inst;
    begin
      lookup_branch_pc = branch_pc;
      lookup_target_pc = target_pc;
      #1;
      tb_check1({label, " hit"}, lookup_hit, exp_hit);
      if (exp_hit) begin
        tb_check64({label, " target"}, lookup_target_pc_out, target_pc);
        tb_check64({label, " next_pc"}, lookup_next_pc, exp_next_pc);
        tb_check32({label, " inst"}, lookup_inst, exp_inst);
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    #1;

    expect_lookup("reset miss", BR0, TG0, 1'b0, {`XLEN{1'b0}}, 32'h0);

    capture_entry(BR0, TG0, TG0 + 64'd4, 32'h0000_0013);
    capture_entry(BR1, TG1, TG1 + 64'd4, 32'h0000_0093);
    expect_lookup("entry0", BR0, TG0, 1'b1, TG0 + 64'd4, 32'h0000_0013);
    expect_lookup("entry1", BR1, TG1, 1'b1, TG1 + 64'd4, 32'h0000_0093);
    expect_lookup("branch pc mismatch", BR0 + 64'd4, TG0, 1'b0,
                  {`XLEN{1'b0}}, 32'h0);
    expect_lookup("target pc mismatch", BR0, TG1, 1'b0,
                  {`XLEN{1'b0}}, 32'h0);

    store_addr = TG0 + 64'd6;
    store_fire = 1'b1;
    tick();
    store_fire = 1'b0;
    #1;
    expect_lookup("store invalidates target word", BR0, TG0, 1'b0,
                  {`XLEN{1'b0}}, 32'h0);
    expect_lookup("store keeps other target", BR1, TG1, 1'b1,
                  TG1 + 64'd4, 32'h0000_0093);

    store_addr = TG2 + 64'd2;
    store_fire = 1'b1;
    capture_valid = 1'b1;
    capture_branch_pc = BR2;
    capture_target_pc = TG2;
    capture_next_pc = TG2 + 64'd4;
    capture_inst = 32'h0000_0113;
    tick();
    store_fire = 1'b0;
    capture_valid = 1'b0;
    #1;
    expect_lookup("store blocks same-word capture", BR2, TG2, 1'b0,
                  {`XLEN{1'b0}}, 32'h0);

    capture_entry(BR2, TG2, TG2 + 64'd4, 32'h0000_0113);
    clear = 1'b1;
    tick();
    clear = 1'b0;
    #1;
    expect_lookup("clear drops entry", BR2, TG2, 1'b0,
                  {`XLEN{1'b0}}, 32'h0);

    capture_entry(BR0, TG0, TG0 + 64'd4, 32'h0000_0013);
    invalidate_all = 1'b1;
    tick();
    invalidate_all = 1'b0;
    #1;
    expect_lookup("invalidate_all drops entry", BR0, TG0, 1'b0,
                  {`XLEN{1'b0}}, 32'h0);

    tb_check32("lookup index uses branch pc bits", {30'b0, lookup_idx},
               {30'b0, BR0[3:2]});
    tb_finish("tb_ooo_branch_target_cache");
  end
endmodule
