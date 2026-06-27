`include "define.v"
`include "tb_common.svh"

module tb_ooo_branch_target_capture_buffer;
  reg clk;
  reg rst;
  reg global_clear;
  reg frontend_clear;
  reg hit_clear_enable;
  reg arm;
  reg [`XLEN-1:0] arm_branch_pc;
  reg [`XLEN-1:0] arm_target_pc;
  reg rsp_valid;
  reg [`XLEN-1:0] rsp_pc;
  wire pending;
  wire [`XLEN-1:0] branch_pc;
  wire [`XLEN-1:0] target_pc;
  wire hit;

  OooBranchTargetCaptureBuffer dut (
    .clk(clk),
    .rst(rst),
    .global_clear_i(global_clear),
    .frontend_clear_i(frontend_clear),
    .hit_clear_enable_i(hit_clear_enable),
    .arm_i(arm),
    .arm_branch_pc_i(arm_branch_pc),
    .arm_target_pc_i(arm_target_pc),
    .rsp_valid_i(rsp_valid),
    .rsp_pc_i(rsp_pc),
    .pending_o(pending),
    .branch_pc_o(branch_pc),
    .target_pc_o(target_pc),
    .hit_o(hit)
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

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    global_clear = 1'b0;
    frontend_clear = 1'b0;
    hit_clear_enable = 1'b1;
    arm = 1'b0;
    arm_branch_pc = {`XLEN{1'b0}};
    arm_target_pc = {`XLEN{1'b0}};
    rsp_valid = 1'b0;
    rsp_pc = {`XLEN{1'b0}};
    tb_errors = 0;

    tick();
    tb_check1("reset clears pending", pending, 1'b0);
    tb_check64_local("reset clears branch pc", branch_pc, {`XLEN{1'b0}});
    tb_check64_local("reset clears target pc", target_pc, {`XLEN{1'b0}});

    rst = 1'b0;
    arm = 1'b1;
    arm_branch_pc = 64'h0000_0000_8000_0100;
    arm_target_pc = 64'h0000_0000_8000_0200;
    tick();
    arm = 1'b0;
    tb_check1("arm sets pending", pending, 1'b1);
    tb_check64_local("arm records branch pc", branch_pc,
                     64'h0000_0000_8000_0100);
    tb_check64_local("arm records target pc", target_pc,
                     64'h0000_0000_8000_0200);

    rsp_valid = 1'b1;
    rsp_pc = 64'h0000_0000_8000_0300;
    #1;
    tb_check1("wrong response misses", hit, 1'b0);
    tick();
    tb_check1("miss keeps pending", pending, 1'b1);
    tb_check64_local("miss keeps target pc", target_pc,
                     64'h0000_0000_8000_0200);

    hit_clear_enable = 1'b0;
    rsp_pc = 64'h0000_0000_8000_0200;
    #1;
    tb_check1("hit visible while clear gated", hit, 1'b1);
    tick();
    tb_check1("invalidate-all gate keeps pending", pending, 1'b1);

    hit_clear_enable = 1'b1;
    #1;
    tb_check1("hit visible before clear", hit, 1'b1);
    tick();
    tb_check1("enabled hit clears pending", pending, 1'b0);
    tb_check64_local("hit clear zeroes branch pc", branch_pc, {`XLEN{1'b0}});
    tb_check64_local("hit clear zeroes target pc", target_pc, {`XLEN{1'b0}});

    rsp_valid = 1'b0;
    arm = 1'b1;
    arm_branch_pc = 64'h0000_0000_8000_1000;
    arm_target_pc = 64'h0000_0000_8000_2000;
    tick();
    arm = 1'b0;
    frontend_clear = 1'b1;
    tick();
    frontend_clear = 1'b0;
    tb_check1("frontend clear drops pending", pending, 1'b0);

    frontend_clear = 1'b1;
    arm = 1'b1;
    arm_branch_pc = 64'h0000_0000_8000_3000;
    arm_target_pc = 64'h0000_0000_8000_4000;
    tick();
    frontend_clear = 1'b0;
    arm = 1'b0;
    tb_check1("arm wins ordinary frontend clear", pending, 1'b1);
    tb_check64_local("arm over clear branch pc", branch_pc,
                     64'h0000_0000_8000_3000);
    tb_check64_local("arm over clear target pc", target_pc,
                     64'h0000_0000_8000_4000);

    global_clear = 1'b1;
    arm = 1'b1;
    arm_branch_pc = 64'h0000_0000_8000_5000;
    arm_target_pc = 64'h0000_0000_8000_6000;
    tick();
    global_clear = 1'b0;
    arm = 1'b0;
    tb_check1("global clear wins arm", pending, 1'b0);
    tb_check64_local("global clear zeroes branch pc", branch_pc,
                     {`XLEN{1'b0}});
    tb_check64_local("global clear zeroes target pc", target_pc,
                     {`XLEN{1'b0}});

    tb_finish("tb_ooo_branch_target_capture_buffer");
  end

endmodule
