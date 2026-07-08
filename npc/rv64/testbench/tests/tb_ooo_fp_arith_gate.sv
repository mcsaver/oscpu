`include "define.v"

// OooFpArithGate 专属 testbench：FADD/FSUB/FMUL/FMADD/FMSUB 的高置信度精确值
// （单/双精度整数值运算，结果精确、fflags=0）。穷举舍入/特殊值由 rv64uf/ud 回归兜底。
// negate_product/subtract_addend：FMADD=(0,0) 算 rs1*rs2+rs3、FMSUB=(0,1) 算 rs1*rs2-rs3。
//
// 2026-06-29 多周期流水化后：gate 变时序(clk/rst/flush/start→done)。本 TB 用「等 done
// 再采样」的时钟协议，与 FP_ARITH_LATENCY 解耦——后续相位加深流水深度时 TB 不用改。
module tb_ooo_fp_arith_gate;
  `include "tb_common.svh"

  reg clk, rst, flush, start;
  reg [`XLEN-1:0] frs1, frs2, frs3;
  reg dbl, sub_op, neg_prod, sub_add;
  reg [2:0] rm;
  wire [`XLEN-1:0] addsub_v, mul_v, fma_v;
  wire [4:0] addsub_f, mul_f, fma_f;
  wire done;
  reg launch_valid;
  reg [`OOO_ROB_INDEX_W-1:0] launch_rob_idx;
  reg [`OOO_PHY_REG_ADDR_W-1:0] launch_pdest;
  reg [1:0] launch_kind;
  reg kill_valid;
  reg [`OOO_ROB_INDEX_W-1:0] kill_rob_idx;
  reg [`OOO_ROB_INDEX_W-1:0] rob_head_idx;
  wire out_valid;
  wire [`OOO_ROB_INDEX_W-1:0] out_rob_idx;
  wire [`OOO_PHY_REG_ADDR_W-1:0] out_pdest;
  wire [`XLEN-1:0] out_value;
  wire [4:0] out_fflags;

  OooFpArithGate dut (
    .clk(clk), .rst(rst), .flush_i(flush), .start_i(start),
    .frs1_value_i(frs1), .frs2_value_i(frs2), .frs3_value_i(frs3),
    .double_i(dbl), .sub_op_i(sub_op),
    .negate_product_i(neg_prod), .subtract_addend_i(sub_add), .rm_i(rm),
    .addsub_value_o(addsub_v), .addsub_fflags_o(addsub_f),
    .mul_value_o(mul_v), .mul_fflags_o(mul_f),
    .fma_value_o(fma_v), .fma_fflags_o(fma_f),
    .done_o(done),
    .launch_valid_i(launch_valid),
    .launch_rob_idx_i(launch_rob_idx),
    .launch_pdest_i(launch_pdest),
    .launch_kind_i(launch_kind),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob_idx),
    .rob_head_idx_i(rob_head_idx),
    .out_valid_o(out_valid),
    .out_rob_idx_o(out_rob_idx),
    .out_pdest_o(out_pdest),
    .out_value_o(out_value),
    .out_fflags_o(out_fflags)
  );

  // 10ns 时钟
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // 启动一个 arith op:置 start,推进时钟直到 done_o,采样后撤 start 复位计数器。
  // 操作数需在调用前已稳定;本 task 全程保持(由调用方在调用前设置、调用后再改)。
  task automatic run_op;
    integer guard;
    begin
      start = 1'b1;
      @(posedge clk); #1;
      guard = 0;
      while ((done !== 1'b1) && (guard < 100)) begin
        @(posedge clk); #1;
        guard = guard + 1;
      end
      if (done !== 1'b1) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] arith done timeout (guard=%0d)", guard);
      end
      // done 这拍流水末级寄存器已就绪;撤 start 复位 done 计数器,为下一 op 备好。
      start = 1'b0;
      @(posedge clk); #1;
    end
  endtask

  task automatic chk;
    input [1023:0] what; input [`XLEN-1:0] got; input [`XLEN-1:0] exp;
    input [4:0] gotf; input [4:0] expf;
    begin
      if (got !== exp) begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s val got=0x%016x exp=0x%016x", what, got, exp); end
      if (gotf !== expf) begin tb_errors=tb_errors+1; $display("[CHECK-FAIL] %0s ff got=0x%02x exp=0x%02x", what, gotf, expf); end
    end
  endtask

  task automatic launch_op;
    input [1:0] kind;
    input [`OOO_ROB_INDEX_W-1:0] rob_idx;
    input [`OOO_PHY_REG_ADDR_W-1:0] pdest;
    input is_double;
    input is_sub;
    input neg_product;
    input sub_addend;
    input [`XLEN-1:0] a;
    input [`XLEN-1:0] b;
    input [`XLEN-1:0] c;
    begin
      launch_kind = kind;
      launch_rob_idx = rob_idx;
      launch_pdest = pdest;
      dbl = is_double;
      sub_op = is_sub;
      neg_prod = neg_product;
      sub_add = sub_addend;
      frs1 = a;
      frs2 = b;
      frs3 = c;
      launch_valid = 1'b1;
      @(posedge clk); #1;
    end
  endtask

  task automatic chk_out;
    input [1023:0] what;
    input exp_valid;
    input [`OOO_ROB_INDEX_W-1:0] exp_rob_idx;
    input [`OOO_PHY_REG_ADDR_W-1:0] exp_pdest;
    input [`XLEN-1:0] exp_value;
    input [4:0] exp_fflags;
    begin
      if (out_valid !== exp_valid) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s valid got=%0b exp=%0b", what, out_valid, exp_valid);
      end
      if (exp_valid) begin
        if (out_rob_idx !== exp_rob_idx) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] %0s rob got=0x%0x exp=0x%0x", what, out_rob_idx, exp_rob_idx);
        end
        if (out_pdest !== exp_pdest) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] %0s pdest got=0x%0x exp=0x%0x", what, out_pdest, exp_pdest);
        end
        chk(what, out_value, exp_value, out_fflags, exp_fflags);
      end
    end
  endtask

  // double 常量
  localparam [`XLEN-1:0] D1=64'h3ff0000000000000, D2=64'h4000000000000000,
                         D3=64'h4008000000000000, D5=64'h4014000000000000,
                         D6=64'h4018000000000000, D7=64'h401c000000000000;
  // single 常量（NaN-box）
  localparam [`XLEN-1:0] S1=64'hffffffff_3f800000, S2=64'hffffffff_40000000,
                         S3=64'hffffffff_40400000, S6=64'hffffffff_40c00000,
                         S7=64'hffffffff_40e00000;

  initial begin
    tb_errors = 0; rm = 3'b000; neg_prod = 0; sub_add = 0;
    flush = 1'b0; start = 1'b0;
    launch_valid = 1'b0; launch_rob_idx = {`OOO_ROB_INDEX_W{1'b0}};
    launch_pdest = {`OOO_PHY_REG_ADDR_W{1'b0}}; launch_kind = 2'b00;
    kill_valid = 1'b0; kill_rob_idx = {`OOO_ROB_INDEX_W{1'b0}};
    rob_head_idx = {`OOO_ROB_INDEX_W{1'b0}};
    frs1 = 0; frs2 = 0; frs3 = 0; dbl = 1; sub_op = 0;
    // 复位:清流水寄存器与 done 计数器
    rst = 1'b1; repeat (3) @(posedge clk); #1; rst = 1'b0; @(posedge clk); #1;

    // ---- double ----
    dbl = 1;
    sub_op = 0; frs1 = D1; frs2 = D1; run_op; chk("FADD 1+1", addsub_v, D2, addsub_f, 5'b0);
    sub_op = 1; frs1 = D2; frs2 = D1; run_op; chk("FSUB 2-1", addsub_v, D1, addsub_f, 5'b0);
    sub_op = 0; frs1 = D2; frs2 = D3; run_op; chk("FMUL 2*3", mul_v, D6, mul_f, 5'b0);
    // FMADD 2*3+1=7
    frs1 = D2; frs2 = D3; frs3 = D1; neg_prod = 0; sub_add = 0; run_op; chk("FMADD 2*3+1", fma_v, D7, fma_f, 5'b0);
    // FMSUB 2*3-1=5
    frs1 = D2; frs2 = D3; frs3 = D1; neg_prod = 0; sub_add = 1; run_op; chk("FMSUB 2*3-1", fma_v, D5, fma_f, 5'b0);

    // ---- single ----
    dbl = 0; neg_prod = 0; sub_add = 0;
    sub_op = 0; frs1 = S1; frs2 = S1; run_op; chk("FADD.S 1+1", addsub_v, S2, addsub_f, 5'b0);
    frs1 = S2; frs2 = S3; run_op; chk("FMUL.S 2*3", mul_v, S6, mul_f, 5'b0);

    // ---- B-FP 自流水 launch/out 接口 ----
    // 连续三拍发射 add/mul/fma，检查 stage5 连续吐出 meta + value/fflags。
    kill_valid = 1'b0; rob_head_idx = 0; start = 1'b0; dbl = 1'b1;
    launch_op(2'd0, 4'd1, 6'd33, 1'b1, 1'b0, 1'b0, 1'b0, D1, D1, 64'b0);
    launch_op(2'd1, 4'd2, 6'd34, 1'b1, 1'b0, 1'b0, 1'b0, D2, D3, 64'b0);
    launch_op(2'd2, 4'd3, 6'd35, 1'b1, 1'b0, 1'b0, 1'b0, D2, D3, D1);
    launch_valid = 1'b0;
    repeat (2) @(posedge clk); #1;
    chk_out("launch addsub out", 1'b1, 4'd1, 6'd33, D2, 5'b0);
    @(posedge clk); #1;
    chk_out("launch mul out", 1'b1, 4'd2, 6'd34, D6, 5'b0);
    @(posedge clk); #1;
    chk_out("launch fma out", 1'b1, 4'd3, 6'd35, D7, 5'b0);
    @(posedge clk); #1;
    chk_out("launch pipe drained", 1'b0, 4'd0, 6'd0, 64'b0, 5'b0);

    // younger-than-kill 的在飞 meta 必须被清 valid；数据可以继续流动，但 out_valid 不得拉高。
    launch_op(2'd2, 4'd4, 6'd36, 1'b1, 1'b0, 1'b0, 1'b0, D2, D3, D1);
    launch_valid = 1'b0;
    kill_valid = 1'b1; kill_rob_idx = 4'd2; rob_head_idx = 4'd0;
    @(posedge clk); #1;
    kill_valid = 1'b0;
    repeat (3) @(posedge clk); #1;
    chk_out("launch killed younger meta", 1'b0, 4'd0, 6'd0, 64'b0, 5'b0);

    // flush 必须清掉在飞自流水 meta；结果数据可在内部继续变化，但 out_valid 不能泄漏。
    launch_op(2'd2, 4'd5, 6'd37, 1'b1, 1'b0, 1'b0, 1'b0, D2, D3, D1);
    launch_valid = 1'b0;
    @(posedge clk); #1;
    flush = 1'b1;
    @(posedge clk); #1;
    chk_out("launch flush clear meta", 1'b0, 4'd0, 6'd0, 64'b0, 5'b0);
    flush = 1'b0;
    repeat (5) begin
      @(posedge clk); #1;
      chk_out("launch flush drain invalid", 1'b0, 4'd0, 6'd0, 64'b0, 5'b0);
    end

    // 确定性混合精度 back-to-back：防止 double bit 与 value/fflags 对齐链错拍。
    launch_op(2'd0, 4'd6, 6'd38, 1'b0, 1'b0, 1'b0, 1'b0, S1, S1, 64'b0);
    launch_op(2'd1, 4'd7, 6'd39, 1'b1, 1'b0, 1'b0, 1'b0, D2, D3, 64'b0);
    launch_op(2'd2, 4'd8, 6'd40, 1'b0, 1'b0, 1'b0, 1'b0, S2, S3, S1);
    launch_valid = 1'b0;
    repeat (2) @(posedge clk); #1;
    chk_out("launch mixed fadd.s out", 1'b1, 4'd6, 6'd38, S2, 5'b0);
    @(posedge clk); #1;
    chk_out("launch mixed fmul.d out", 1'b1, 4'd7, 6'd39, D6, 5'b0);
    @(posedge clk); #1;
    chk_out("launch mixed fmadd.s out", 1'b1, 4'd8, 6'd40, S7, 5'b0);
    @(posedge clk); #1;
    chk_out("launch mixed pipe drained", 1'b0, 4'd0, 6'd0, 64'b0, 5'b0);

    tb_finish("tb_ooo_fp_arith_gate");
  end
endmodule
