`include "define.v"

// OooFpArithGate 专属 testbench：FADD/FSUB/FMUL/FMADD/FMSUB 的高置信度精确值
// （单/双精度整数值运算，结果精确、fflags=0）。穷举舍入/特殊值由 rv64uf/ud 回归兜底。
// negate_product/subtract_addend：FMADD=(0,0) 算 rs1*rs2+rs3、FMSUB=(0,1) 算 rs1*rs2-rs3。
module tb_ooo_fp_arith_gate;
  `include "tb_common.svh"

  reg [`XLEN-1:0] frs1, frs2, frs3;
  reg dbl, sub_op, neg_prod, sub_add;
  reg [2:0] rm;
  wire [`XLEN-1:0] addsub_v, mul_v, fma_v;
  wire [4:0] addsub_f, mul_f, fma_f;

  OooFpArithGate dut (
    .frs1_value_i(frs1), .frs2_value_i(frs2), .frs3_value_i(frs3),
    .double_i(dbl), .sub_op_i(sub_op),
    .negate_product_i(neg_prod), .subtract_addend_i(sub_add), .rm_i(rm),
    .addsub_value_o(addsub_v), .addsub_fflags_o(addsub_f),
    .mul_value_o(mul_v), .mul_fflags_o(mul_f),
    .fma_value_o(fma_v), .fma_fflags_o(fma_f)
  );

  // 注意：task 参数按值在调用时捕获，故调用方需先 #1 让组合输出 settle 再调用 chk。
  task automatic chk;
    input [1023:0] what; input [`XLEN-1:0] got; input [`XLEN-1:0] exp;
    input [4:0] gotf; input [4:0] expf;
    begin
      if (got !== exp) begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s val got=0x%016x exp=0x%016x", what, got, exp); end
      if (gotf !== expf) begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s ff got=0x%02x exp=0x%02x", what, gotf, expf); end
    end
  endtask

  // double 常量
  localparam [`XLEN-1:0] D1=64'h3ff0000000000000, D2=64'h4000000000000000,
                         D3=64'h4008000000000000, D5=64'h4014000000000000,
                         D6=64'h4018000000000000, D7=64'h401c000000000000;
  // single 常量（NaN-box）
  localparam [`XLEN-1:0] S1=64'hffffffff_3f800000, S2=64'hffffffff_40000000,
                         S3=64'hffffffff_40400000, S6=64'hffffffff_40c00000;

  initial begin
    tb_errors = 0; rm = 3'b000; neg_prod = 0; sub_add = 0;

    // ---- double ----
    dbl = 1;
    sub_op = 0; frs1 = D1; frs2 = D1; #1; chk("FADD 1+1", addsub_v, D2, addsub_f, 5'b0);
    sub_op = 1; frs1 = D2; frs2 = D1; #1; chk("FSUB 2-1", addsub_v, D1, addsub_f, 5'b0);
    frs1 = D2; frs2 = D3; #1; chk("FMUL 2*3", mul_v, D6, mul_f, 5'b0);
    // FMADD 2*3+1=7
    frs1 = D2; frs2 = D3; frs3 = D1; neg_prod = 0; sub_add = 0; #1; chk("FMADD 2*3+1", fma_v, D7, fma_f, 5'b0);
    // FMSUB 2*3-1=5
    frs1 = D2; frs2 = D3; frs3 = D1; neg_prod = 0; sub_add = 1; #1; chk("FMSUB 2*3-1", fma_v, D5, fma_f, 5'b0);

    // ---- single ----
    dbl = 0; neg_prod = 0; sub_add = 0;
    sub_op = 0; frs1 = S1; frs2 = S1; #1; chk("FADD.S 1+1", addsub_v, S2, addsub_f, 5'b0);
    frs1 = S2; frs2 = S3; #1; chk("FMUL.S 2*3", mul_v, S6, mul_f, 5'b0);

    tb_finish("tb_ooo_fp_arith_gate");
  end
endmodule
