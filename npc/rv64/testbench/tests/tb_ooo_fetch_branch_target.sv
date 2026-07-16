`include "define.v"
`include "tb_common.svh"

module tb_ooo_fetch_branch_target;
  reg clk;
  reg rst;
  reg valid;
  reg [`XLEN-1:0] pc;
  reg [12:0] bimm;
  wire [`XLEN-1:0] target;

  reg [`XLEN-1:0] expected;
  integer sample_idx;

  OooFetchBranchTarget dut (
    .clk(clk),
    .rst(rst),
    .valid_i(valid),
    .pc_i(pc),
    .bimm_i(bimm),
    .target_o(target)
  );

  task automatic check_target;
    input [1023:0] what;
    input [`XLEN-1:0] test_pc;
    input [12:0] test_bimm;
    input [`XLEN-1:0] test_expected;
    begin
      pc = test_pc;
      bimm = test_bimm;
      valid = 1'b1;
      #1;
      if (target !== test_expected) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s pc=0x%016x bimm=0x%04x got=0x%016x expected=0x%016x",
                 what, test_pc, test_bimm, target, test_expected);
      end
      `TB_TICK(clk);
    end
  endtask

  initial begin
    clk = 1'b0;
    rst = 1'b1;
    valid = 1'b0;
    pc = {`XLEN{1'b0}};
    bimm = 13'b0;
    tb_errors = 0;
    `TB_TICK(clk);
    rst = 1'b0;

    check_target("zero", 64'h0, 13'h0000, 64'h0);
    check_target("minimum -4096", 64'h0, 13'h1000,
                 64'hffff_ffff_ffff_f000);
    check_target("negative -2", 64'h0, 13'h1ffe,
                 64'hffff_ffff_ffff_fffe);
    check_target("negative carry cancels sign", 64'h2, 13'h1ffe, 64'h0);
    check_target("positive page carry", 64'h0ffe, 13'h0002, 64'h1000);
    check_target("positive high wrap", 64'hffff_ffff_ffff_ffff,
                 13'h0002, 64'h1);
    check_target("negative page borrow", 64'h1000, 13'h1ffe,
                 64'h0ffe);
    check_target("minimum cancels page", 64'h1000, 13'h1000, 64'h0);
    check_target("maximum positive", 64'hffff_ffff_ffff_f001,
                 13'h0ffe, 64'hffff_ffff_ffff_ffff);

    for (sample_idx = 0; sample_idx < 2048; sample_idx = sample_idx + 1) begin
      pc = {$random, $random};
      bimm = $random & 13'h1ffe;
      expected = pc + {{(`XLEN-13){bimm[12]}}, bimm};
      check_target("random reference", pc, bimm, expected);
    end

    valid = 1'b0;
    tb_finish("tb_ooo_fetch_branch_target");
  end

endmodule
