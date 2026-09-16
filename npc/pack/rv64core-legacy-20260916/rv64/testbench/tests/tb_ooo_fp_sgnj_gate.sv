`include "define.v"

// OooFpSgnjGate 专属 testbench：验证 FSGNJ/FSGNJN/FSGNJX（单/双精度 + NaN-box）。
module tb_ooo_fp_sgnj_gate;
  `include "tb_common.svh"

  reg [`XLEN-1:0] frs1, frs2;
  reg dbl;
  reg [2:0] op;
  wire [`XLEN-1:0] sgnj;

  OooFpSgnjGate dut (
    .frs1_value_i(frs1),
    .frs2_value_i(frs2),
    .double_i(dbl),
    .op_i(op),
    .sgnj_value_o(sgnj)
  );

  task automatic chk;
    input [1023:0] what;
    input [`XLEN-1:0] exp;
    begin
      #1;
      if (sgnj !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x", what, sgnj, exp);
      end
    end
  endtask

  initial begin
    tb_errors = 0;

    // ---- 双精度 ----
    dbl = 1;
    // FSGNJ：取 rs2 符号；rs1=+1.0 (0x3ff0..)，rs2 负 -> 结果取 rs1 尾数 + rs2 符号
    frs1 = 64'h3ff0000000000000; frs2 = 64'h8000000000000000; op = 3'b000;
    chk("D FSGNJ rs2-", 64'hbff0000000000000);
    // FSGNJN：取 rs2 反符号；rs2 正 -> 结果负
    frs1 = 64'h3ff0000000000000; frs2 = 64'h0000000000000000; op = 3'b001;
    chk("D FSGNJN rs2+", 64'hbff0000000000000);
    // FSGNJX：rs1^rs2 符号；rs1 负, rs2 负 -> 正
    frs1 = 64'hbff0000000000000; frs2 = 64'h8000000000000000; op = 3'b010;
    chk("D FSGNJX neg^neg", 64'h3ff0000000000000);
    // FSGNJX：rs1 正, rs2 负 -> 负
    frs1 = 64'h3ff0000000000000; frs2 = 64'h8000000000000000; op = 3'b010;
    chk("D FSGNJX pos^neg", 64'hbff0000000000000);

    // ---- 单精度（NaN-box 高 32 位全 1）----
    dbl = 0;
    // 已 box：rs1=+1.0f(0x3f800000) box, rs2 单精度符号在 rs2[31]
    frs1 = 64'hffffffff_3f800000; frs2 = 64'hffffffff_bf800000; op = 3'b000;
    chk("S FSGNJ rs2-", 64'hffffffff_bf800000);
    frs1 = 64'hffffffff_3f800000; frs2 = 64'hffffffff_3f800000; op = 3'b001;
    chk("S FSGNJN rs2+", 64'hffffffff_bf800000);
    frs1 = 64'hffffffff_bf800000; frs2 = 64'hffffffff_bf800000; op = 3'b010;
    chk("S FSGNJX neg^neg", 64'hffffffff_3f800000);
    // rs1 未正确 box -> rs1_single 视为 canonical qNaN 0x7fc00000；FSGNJ 取 rs2 符号(+)
    frs1 = 64'h00000000_3f800000; frs2 = 64'hffffffff_3f800000; op = 3'b000;
    chk("S FSGNJ rs1-unboxed", 64'hffffffff_7fc00000);
    // rs2 未正确 box -> rs2_single 视为 qNaN(0x7fc00000，符号位0)，FSGNJN 取反 -> 1
    frs1 = 64'hffffffff_3f800000; frs2 = 64'h00000000_3f800000; op = 3'b001;
    chk("S FSGNJN rs2-unboxed", 64'hffffffff_bf800000);

    tb_finish("tb_ooo_fp_sgnj_gate");
  end
endmodule
