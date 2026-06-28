`include "define.v"

// OooFpClassifyGate 专属 testbench：验证 FCLASS.S/FCLASS.D 10 位 class mask。
module tb_ooo_fp_classify_gate;
  `include "tb_common.svh"

  reg [`XLEN-1:0] frs1;
  reg dbl;
  wire [`XLEN-1:0] cls;

  OooFpClassifyGate dut (
    .frs1_value_i(frs1),
    .double_i(dbl),
    .class_value_o(cls)
  );

  // class bit: 0 -inf,1 -normal,2 -subnormal,3 -0,4 +0,5 +subnormal,6 +normal,7 +inf,8 sNaN,9 qNaN
  task automatic chk;
    input [1023:0] what;
    input integer bit_idx;
    reg [`XLEN-1:0] exp;
    begin
      #1;
      exp = (64'd1 << bit_idx);
      if (cls !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%03x expected bit%0d (0x%03x)", what, cls[9:0], bit_idx, exp[9:0]);
      end
    end
  endtask

  initial begin
    tb_errors = 0;

    // ---- 单精度 (NaN-box 高 32 位无关，模块只看 frs1[31:0]) ----
    dbl = 0;
    frs1 = 64'hffffffff_ff800000; chk("S -inf",       0);
    frs1 = 64'hffffffff_7f800000; chk("S +inf",       7);
    frs1 = 64'hffffffff_c0000000; chk("S -normal",    1);
    frs1 = 64'hffffffff_40000000; chk("S +normal",    6);
    frs1 = 64'hffffffff_80000000; chk("S -0",         3);
    frs1 = 64'hffffffff_00000000; chk("S +0",         4);
    frs1 = 64'hffffffff_00000001; chk("S +subnormal", 5);
    frs1 = 64'hffffffff_80000001; chk("S -subnormal", 2);
    frs1 = 64'hffffffff_7f800001; chk("S sNaN",       8);
    frs1 = 64'hffffffff_7fc00000; chk("S qNaN",       9);

    // ---- 双精度 ----
    dbl = 1;
    frs1 = 64'hfff0000000000000; chk("D -inf",        0);
    frs1 = 64'h7ff0000000000000; chk("D +inf",        7);
    frs1 = 64'hc000000000000000; chk("D -normal",     1);
    frs1 = 64'h4000000000000000; chk("D +normal",     6);
    frs1 = 64'h8000000000000000; chk("D -0",          3);
    frs1 = 64'h0000000000000000; chk("D +0",          4);
    frs1 = 64'h0000000000000001; chk("D +subnormal",  5);
    frs1 = 64'h7ff0000000000001; chk("D sNaN",        8);
    frs1 = 64'h7ff8000000000000; chk("D qNaN",        9);

    tb_finish("tb_ooo_fp_classify_gate");
  end
endmodule
