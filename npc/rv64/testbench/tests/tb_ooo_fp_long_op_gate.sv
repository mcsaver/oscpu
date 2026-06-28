`include "define.v"

// OooFpLongOpGate 专属 testbench：驱动 FDIV / FSQRT 迭代到完成并检查结果/fflags。
// 时序模块（含 div/sqrt 迭代器）：脉冲 long_start 一拍，等 long_done，再核对。
// 穷举特殊值/舍入由 official rv64uf/ud 回归兜底。
module tb_ooo_fp_long_op_gate;
  `include "tb_common.svh"

  reg clk, rst, flush;
  reg [`XLEN-1:0] frs1, frs2;
  reg dbl;
  reg [2:0] rm;
  reg long_start, is_div, is_sqrt;
  wire div_busy, sqrt_busy, long_done;
  wire [`XLEN-1:0] long_result;
  wire [4:0] long_fflags;

  OooFpLongOpGate dut (
    .clk(clk), .rst(rst), .flush_i(flush),
    .frs1_value_i(frs1), .frs2_value_i(frs2), .double_i(dbl), .rm_i(rm),
    .long_start_i(long_start), .is_div_i(is_div), .is_sqrt_i(is_sqrt),
    .div_busy_o(div_busy), .sqrt_busy_o(sqrt_busy),
    .long_done_o(long_done), .long_done_result_o(long_result),
    .long_done_fflags_o(long_fflags)
  );

  always #1 clk = ~clk;

  // 发起一个长运算并等待 done（带超时）
  task automatic run_long;
    input [1023:0] what;
    input is_div_v, is_sqrt_v;
    input [`XLEN-1:0] a, b;
    input [`XLEN-1:0] exp_val;
    input [4:0] exp_ff;
    integer cyc;
    begin
      @(negedge clk);
      frs1 = a; frs2 = b; is_div = is_div_v; is_sqrt = is_sqrt_v;
      long_start = 1'b1;
      @(negedge clk);
      long_start = 1'b0;
      cyc = 0;
      while (!long_done && cyc < 200) begin @(negedge clk); cyc = cyc + 1; end
      if (!long_done) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s timeout (no long_done)", what);
      end else begin
        if (long_result !== exp_val) begin tb_errors=tb_errors+1;
          $display("[CHECK-FAIL] %0s result got=0x%016x exp=0x%016x", what, long_result, exp_val); end
        if (long_fflags !== exp_ff) begin tb_errors=tb_errors+1;
          $display("[CHECK-FAIL] %0s fflags got=0x%02x exp=0x%02x", what, long_fflags, exp_ff); end
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 0; rst = 1; flush = 0; long_start = 0; is_div = 0; is_sqrt = 0;
    frs1 = 0; frs2 = 0; dbl = 1; rm = 3'b000;
    @(negedge clk); @(negedge clk); rst = 0;

    // FDIV.D 6.0/3.0 = 2.0（精确）
    run_long("FDIV.D 6/3", 1'b1, 1'b0,
             64'h4018000000000000, 64'h4008000000000000,
             64'h4000000000000000, 5'b00000);

    // FSQRT.D 4.0 = 2.0（精确）
    run_long("FSQRT.D sqrt(4)", 1'b0, 1'b1,
             64'h4010000000000000, 64'h0,
             64'h4000000000000000, 5'b00000);

    // FDIV.S 1.0/2.0 = 0.5（精确，单精度 NaN-box）
    dbl = 0;
    run_long("FDIV.S 1/2", 1'b1, 1'b0,
             64'hffffffff_3f800000, 64'hffffffff_40000000,
             64'hffffffff_3f000000, 5'b00000);

    tb_finish("tb_ooo_fp_long_op_gate");
  end
endmodule
