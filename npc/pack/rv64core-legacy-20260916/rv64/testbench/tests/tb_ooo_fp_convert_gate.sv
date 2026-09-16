`include "define.v"

// OooFpConvertGate 专属 testbench：覆盖 FCVT 主路径的高置信度精确值
// （fp↔int 双向、int 宽度/符号、fp↔fp 升降精度、负数与无符号饱和）。
// 穷举舍入/边界 corner 由 official rv64uf/ud 回归兜底。
// int_fmt = inst[21:20]：bit1=L(1)/W(0)，bit0=unsigned。rm=0 为 RNE。
module tb_ooo_fp_convert_gate;
  `include "tb_common.svh"

  reg [`XLEN-1:0] frs1, int_rs1;
  reg src_dbl, dst_dbl, fpr2fpr;
  reg [1:0] int_fmt;
  reg [2:0] rm;
  wire [`XLEN-1:0] gpr_val, fpr_val;
  wire [4:0] gpr_ff, fpr_ff;

  OooFpConvertGate dut (
    .frs1_value_i(frs1), .int_rs1_value_i(int_rs1),
    .src_double_i(src_dbl), .dst_double_i(dst_dbl), .fpr_to_fpr_i(fpr2fpr),
    .int_fmt_i(int_fmt), .rm_i(rm),
    .to_gpr_value_o(gpr_val), .to_gpr_fflags_o(gpr_ff),
    .to_fpr_value_o(fpr_val), .to_fpr_fflags_o(fpr_ff)
  );

  task automatic chk_gpr;
    input [1023:0] what; input [`XLEN-1:0] ev; input [4:0] ef;
    begin #1;
      if (gpr_val !== ev) begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s val got=0x%016x exp=0x%016x", what, gpr_val, ev); end
      if (gpr_ff !== ef) begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s ff got=0x%02x exp=0x%02x", what, gpr_ff, ef); end
    end
  endtask
  task automatic chk_fpr;
    input [1023:0] what; input [`XLEN-1:0] ev; input [4:0] ef;
    begin #1;
      if (fpr_val !== ev) begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s val got=0x%016x exp=0x%016x", what, fpr_val, ev); end
      if (fpr_ff !== ef) begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s ff got=0x%02x exp=0x%02x", what, fpr_ff, ef); end
    end
  endtask

  localparam [`XLEN-1:0] S1   = 64'hffffffff_3f800000; // 1.0f (boxed)
  localparam [`XLEN-1:0] SN1  = 64'hffffffff_bf800000; // -1.0f
  localparam [`XLEN-1:0] D1   = 64'h3ff0000000000000;  // 1.0d

  initial begin
    tb_errors = 0;
    rm = 3'b000; fpr2fpr = 0;

    // ---- fp -> int ----
    // FCVT.W.S(1.0f) = 1
    frs1 = S1; src_dbl = 0; int_fmt = 2'b00; chk_gpr("FCVT.W.S 1.0", 64'd1, 5'b00000);
    // FCVT.W.S(-1.0f) = -1
    frs1 = SN1; src_dbl = 0; int_fmt = 2'b00; chk_gpr("FCVT.W.S -1.0", {`XLEN{1'b1}}, 5'b00000);
    // FCVT.WU.S(-1.0f) -> 饱和 0，NV
    frs1 = SN1; src_dbl = 0; int_fmt = 2'b01; chk_gpr("FCVT.WU.S -1.0 sat", 64'd0, 5'b10000);
    // FCVT.L.D(1.0d) = 1
    frs1 = D1; src_dbl = 1; int_fmt = 2'b10; chk_gpr("FCVT.L.D 1.0", 64'd1, 5'b00000);

    // ---- int -> fp ----
    // FCVT.S.W(1) = 1.0f boxed
    int_rs1 = 64'd1; dst_dbl = 0; int_fmt = 2'b00; chk_fpr("FCVT.S.W 1", S1, 5'b00000);
    // FCVT.D.L(1) = 1.0d
    int_rs1 = 64'd1; dst_dbl = 1; int_fmt = 2'b10; chk_fpr("FCVT.D.L 1", D1, 5'b00000);
    // FCVT.S.W(-1) = -1.0f
    int_rs1 = {`XLEN{1'b1}}; dst_dbl = 0; int_fmt = 2'b00; chk_fpr("FCVT.S.W -1", SN1, 5'b00000);

    // ---- fp -> fp ----
    // FCVT.D.S(1.0f) = 1.0d（精确升精度）
    frs1 = S1; fpr2fpr = 1; dst_dbl = 1; chk_fpr("FCVT.D.S 1.0", D1, 5'b00000);
    // FCVT.S.D(1.0d) = 1.0f boxed（精确降精度）
    frs1 = D1; fpr2fpr = 1; dst_dbl = 0; chk_fpr("FCVT.S.D 1.0", S1, 5'b00000);

    tb_finish("tb_ooo_fp_convert_gate");
  end
endmodule
