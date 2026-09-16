`include "define.v"
`include "tb_common.svh"

module tb_ooo_direct_branch_wait_buffer;
  reg clk;
  reg rst;
  reg clear;
  reg resolve_match;
  reg branch_fire;
  reg branch_resolve_valid;
  reg [`XLEN-1:0] branch_pc;

  wire pending;
  wire [`XLEN-1:0] pc;

  OooDirectBranchWaitBuffer dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .resolve_match_i(resolve_match),
    .branch_fire_i(branch_fire),
    .branch_resolve_valid_i(branch_resolve_valid),
    .branch_pc_i(branch_pc),
    .pending_o(pending),
    .pc_o(pc)
  );

  task automatic tick;
    begin
      #1 clk = 1'b1;
      #1 clk = 1'b0;
    end
  endtask

  task automatic tb_check64_local;
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
      clear = 1'b0;
      resolve_match = 1'b0;
      branch_fire = 1'b0;
      branch_resolve_valid = 1'b0;
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    clear = 1'b0;
    resolve_match = 1'b0;
    branch_fire = 1'b0;
    branch_resolve_valid = 1'b0;
    branch_pc = {`XLEN{1'b0}};
    tb_errors = 0;

    tick();
    tb_check1("reset clears pending", pending, 1'b0);
    tb_check64_local("reset clears pc", pc, {`XLEN{1'b0}});

    rst = 1'b0;
    branch_fire = 1'b1;
    branch_resolve_valid = 1'b0;
    branch_pc = 64'h0000_0000_8000_1000;
    tick();
    clear_inputs();
    tb_check1("unresolved branch arms pending", pending, 1'b1);
    tb_check64_local("unresolved branch stores pc", pc,
                     64'h0000_0000_8000_1000);

    resolve_match = 1'b1;
    tick();
    clear_inputs();
    tb_check1("resolve match clears pending", pending, 1'b0);
    tb_check64_local("resolve match clears pc", pc, {`XLEN{1'b0}});

    branch_fire = 1'b1;
    branch_resolve_valid = 1'b1;
    branch_pc = 64'h0000_0000_8000_2000;
    tick();
    clear_inputs();
    tb_check1("same-cycle resolved branch not pending", pending, 1'b0);
    tb_check64_local("same-cycle resolved branch clears pc", pc,
                     {`XLEN{1'b0}});

    branch_fire = 1'b1;
    branch_resolve_valid = 1'b0;
    branch_pc = 64'h0000_0000_8000_3000;
    tick();
    clear_inputs();
    tb_check1("second unresolved branch arms pending", pending, 1'b1);
    tb_check64_local("second unresolved branch stores pc", pc,
                     64'h0000_0000_8000_3000);

    resolve_match = 1'b1;
    branch_fire = 1'b1;
    branch_resolve_valid = 1'b0;
    branch_pc = 64'h0000_0000_8000_4000;
    tick();
    clear_inputs();
    tb_check1("match plus new fire keeps pending", pending, 1'b1);
    tb_check64_local("match plus new fire stores new pc", pc,
                     64'h0000_0000_8000_4000);

    clear = 1'b1;
    branch_fire = 1'b1;
    branch_resolve_valid = 1'b0;
    branch_pc = 64'h0000_0000_8000_5000;
    tick();
    clear_inputs();
    tb_check1("clear wins over branch fire", pending, 1'b0);
    tb_check64_local("clear wins clears pc", pc, {`XLEN{1'b0}});

    tb_finish("tb_ooo_direct_branch_wait_buffer");
  end
endmodule
