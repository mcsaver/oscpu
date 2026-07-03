`include "define.v"

// FP 加减/乘/乘加（FADD/FSUB、FMUL、FMADD/FMSUB/FNMADD/FNMSUB，单/双精度）：
// 从 OooFpPendingExec 抽出的纯组合 owner。op-decode（sub_op/negate_product/
// subtract_addend）由父模块从 funct7 算好后输入；rm = inst[14:12]。
// FMA fflags = mul_fflags | addsub_fflags(product, frs3, subtract_addend)，其中
// product = negate_product ? -mul(frs1,frs2) : mul(frs1,frs2)。行为与原 OooFpPendingExec
// 内联实现等价。
// 多周期流水化(2026-06-29):本 gate 原为纯组合,经时序 OOC 实测是真 Fmax 封顶
// (FMA 173 级/36.5ns ≫ dispatch 39 级/7.95ns,FMUL 91、FADD 69)。因 FP 执行完全串行
// (一次一个 op、backend 已 drain、操作数 frsN 全程稳定),不需吞吐型流水,改为
// 「固定 FP_ARITH_LATENCY 拍多周期」:组合 datapath 经若干级寄存器打拍,done 在 start
// 后第 LATENCY 拍拉高,父模块据此延后锁存 compute_done。算术逐行不变 → bit-exact 按构造
// 保持。FP_ARITH_LATENCY=5:FMA(最深)5 级、FMUL 3 级、FADD 2 级真流水(各 op datapath
// 内部切级,把原单拍 173/91/69 级关键路径压到每级 ≤ ~dispatch;见文件末各流水段)。
/* verilator lint_off UNOPTFLAT */
// kill 组合前视与 meta 链的保守判环, 行为由测试守。
module OooFpArithGate (
  input              clk,
  input              rst,
  input              flush_i,
  // start_i = compute_start(本 arith op 已 drain、操作数稳定),拉高启动多周期流水,
  // 保持到父模块锁存 compute_done。done_o 在 start 后第 FP_ARITH_LATENCY 拍拉高。
  input              start_i,
  input  [`XLEN-1:0] frs1_value_i,
  input  [`XLEN-1:0] frs2_value_i,
  input  [`XLEN-1:0] frs3_value_i,
  input              double_i,
  input              sub_op_i,
  input              negate_product_i,
  input              subtract_addend_i,
  input  [2:0]       rm_i,
  output [`XLEN-1:0] addsub_value_o,
  output [4:0]       addsub_fflags_o,
  output [`XLEN-1:0] mul_value_o,
  output [4:0]       mul_fflags_o,
  output [`XLEN-1:0] fma_value_o,
  output [4:0]       fma_fflags_o,
  output             done_o,

  // 【B-FP 簇·自流水接口】(spec §7): launch 单拍脉冲发射, 每拍可背靠背进新 op
  // (数据通路本就逐级寄存, 每拍采样输入); 5 级 meta 链(valid/rob_idx/pdest/double/
  // kind)随行, FADD(2 级)/FMUL(3 级)结果经对齐链补齐到统一第 5 拍, out_* 单口输出。
  // kill: 比 kill_rob_idx 年轻的在飞 meta 清 valid(防晚到 wb 写脏已回收 preg)。
  // 旧 start/done 接口保留给 pending 壳, 拆除时一并移除。
  input              launch_valid_i,
  input  [`OOO_ROB_INDEX_W-1:0] launch_rob_idx_i,
  input  [`OOO_PHY_REG_ADDR_W-1:0] launch_pdest_i,
  input  [1:0]       launch_kind_i,   // 0=addsub, 1=mul, 2=fma
  input              kill_valid_i,
  input  [`OOO_ROB_INDEX_W-1:0] kill_rob_idx_i,
  input  [`OOO_ROB_INDEX_W-1:0] rob_head_idx_i,
  output             out_valid_o,
  output [`OOO_ROB_INDEX_W-1:0] out_rob_idx_o,
  output [`OOO_PHY_REG_ADDR_W-1:0] out_pdest_o,
  output [`XLEN-1:0] out_value_o,
  output [4:0]       out_fflags_o
);

  `include "execute/OooFpPredicates.v"
  `include "execute/OooFpRound.v"
  // FADD/FSUB、FMUL、FMADD 系列结果各由下方流水化 datapath 算出(均 value+fflags 合并);
  // 输出端口由 double_i mux + 末级寄存器给出(见文件末)。FADD 2 级、FMUL 3 级、FMA 5 级。
  // ===========================================================================
  // FADD/FSUB 2 级流水(Phase 2):value/fflags 合并,算术逐行不变。
  //   S1: 特殊值判定 + 对齐(shift_right_jam 到较大指数)+ 幅度比较(a_lt_b/精确抵消)
  //   S2: 同号加 / 异号减 + 规格化 LZC(抵消)+ 单次舍入 + 组装(value+fflags)+ 特殊选择
  // double/single 两条独立流水,输出端 double_i mux。
  // ===========================================================================

  // ---- double FADD 流水寄存器 ----
  reg        as_d_s1_special_c, as_d_s1_special_q;
  reg [63:0] as_d_s1_spval_c,   as_d_s1_spval_q;
  reg [4:0]  as_d_s1_spff_c,    as_d_s1_spff_q;
  reg [55:0] as_d_s1_aaln_c,    as_d_s1_aaln_q;   // sig_a_aligned
  reg [55:0] as_d_s1_baln_c,    as_d_s1_baln_q;   // sig_b_aligned
  reg [10:0] as_d_s1_expz_c,    as_d_s1_expz_q;
  reg        as_d_s1_signa_c,   as_d_s1_signa_q;
  reg        as_d_s1_signb_c,   as_d_s1_signb_q;
  reg        as_d_s1_altb_c,    as_d_s1_altb_q;   // a_lt_b_mag
  reg        as_d_s1_cancel_c,  as_d_s1_cancel_q; // 精确抵消
  reg [2:0]  as_d_s1_rm_c,      as_d_s1_rm_q;
  reg [63:0] addsub_d_value_q;
  reg [4:0]  addsub_d_fflags_q;
  // S2 寄存器:同号加/异号减+规格化后的 sig_norm/exp_z/sign_z + 直通 special/rm。
  reg [55:0] as_d_s2_signorm_c, as_d_s2_signorm_q;
  reg [10:0] as_d_s2_expz_c,    as_d_s2_expz_q;
  reg        as_d_s2_signz_c,   as_d_s2_signz_q;
  reg        as_d_s2_special_q;
  reg [63:0] as_d_s2_spval_q;
  reg [4:0]  as_d_s2_spff_q;
  reg [2:0]  as_d_s2_rm_q;
  reg [63:0] as_d_s3_value_c;
  reg [4:0]  as_d_s3_fflags_c;

  always @(*) begin : as_d_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value;
    reg is_sub;
    reg sign_a, sign_b;
    reg [10:0] exp_a, exp_b, exp_a_eff, exp_b_eff, exp_z, exp_diff;
    reg [51:0] frac_a, frac_b;
    reg [55:0] sig_a, sig_b, sig_a_aligned, sig_b_aligned;
    reg [6:0] shift_dist;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i; is_sub = sub_op_i;
    exp_a_eff = 0; exp_b_eff = 0; exp_z = 0; exp_diff = 0; shift_dist = 0;
    sig_a = 0; sig_b = 0; sig_a_aligned = 0; sig_b_aligned = 0;
    as_d_s1_special_c = 1'b0; as_d_s1_spval_c = 64'b0; as_d_s1_spff_c = 5'b0;
    as_d_s1_altb_c = 1'b0; as_d_s1_cancel_c = 1'b0;
      sign_a = rs1_value[63];
      sign_b = rs2_value[63] ^ is_sub;
      exp_a = rs1_value[62:52]; exp_b = rs2_value[62:52];
      frac_a = rs1_value[51:0]; frac_b = rs2_value[51:0];
      a_is_nan = (exp_a == 11'h7ff) && (frac_a != 52'b0);
      b_is_nan = (exp_b == 11'h7ff) && (frac_b != 52'b0);
      a_is_inf = (exp_a == 11'h7ff) && (frac_a == 52'b0);
      b_is_inf = (exp_b == 11'h7ff) && (frac_b == 52'b0);
      a_is_zero = (exp_a == 11'h000) && (frac_a == 52'b0);
      b_is_zero = (exp_b == 11'h000) && (frac_b == 52'b0);
      // 特殊值(value),fflags 仅 snan / inf-inf 异号 置 NV。
      if (a_is_nan || b_is_nan) begin
        as_d_s1_special_c = 1'b1; as_d_s1_spval_c = 64'h7ff8000000000000;
        as_d_s1_spff_c = (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value)) ? `FP_FLAG_NV : 5'b00000;
      end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
        as_d_s1_special_c = 1'b1; as_d_s1_spval_c = 64'h7ff8000000000000;
        as_d_s1_spff_c = `FP_FLAG_NV;
      end else if (a_is_inf) begin
        as_d_s1_special_c = 1'b1; as_d_s1_spval_c = {sign_a, 11'h7ff, 52'b0};
      end else if (b_is_inf) begin
        as_d_s1_special_c = 1'b1; as_d_s1_spval_c = {sign_b, 11'h7ff, 52'b0};
      end else if (a_is_zero && b_is_zero) begin
        as_d_s1_special_c = 1'b1;
        as_d_s1_spval_c = {((rm_i == 3'b010) ? (sign_a | sign_b) : (sign_a & sign_b)), 63'b0};
      end else if (a_is_zero) begin
        as_d_s1_special_c = 1'b1; as_d_s1_spval_c = {sign_b, exp_b, frac_b};
      end else if (b_is_zero) begin
        as_d_s1_special_c = 1'b1; as_d_s1_spval_c = rs1_value;
      end
      // 主路对齐(特殊时下方也算,S2 丢弃)。
      exp_a_eff = (exp_a == 11'h000) ? 11'd1 : exp_a;
      exp_b_eff = (exp_b == 11'h000) ? 11'd1 : exp_b;
      sig_a = {(exp_a != 11'h000), frac_a, 3'b000};
      sig_b = {(exp_b != 11'h000), frac_b, 3'b000};
      if (exp_a_eff >= exp_b_eff) begin
        exp_z = exp_a_eff;
        sig_a_aligned = sig_a;
        exp_diff = exp_a_eff - exp_b_eff;
        shift_dist = (exp_diff >= 11'd56) ? 7'd56 : exp_diff[6:0];
        sig_b_aligned = fp_shift_right_jam_56(sig_b, shift_dist);
      end else begin
        exp_z = exp_b_eff;
        exp_diff = exp_b_eff - exp_a_eff;
        shift_dist = (exp_diff >= 11'd56) ? 7'd56 : exp_diff[6:0];
        sig_a_aligned = fp_shift_right_jam_56(sig_a, shift_dist);
        sig_b_aligned = sig_b;
      end
      as_d_s1_altb_c = (exp_a_eff < exp_b_eff) ||
                       ((exp_a_eff == exp_b_eff) && (sig_a < sig_b));
      as_d_s1_cancel_c = (exp_a_eff == exp_b_eff) && (sig_a == sig_b);
      as_d_s1_aaln_c = sig_a_aligned;
      as_d_s1_baln_c = sig_b_aligned;
      as_d_s1_expz_c = exp_z;
      as_d_s1_signa_c = sign_a;
      as_d_s1_signb_c = sign_b;
      as_d_s1_rm_c = rm_i;
  end

  // S2:同号加 / 异号减 + 规格化 → sig_norm/exp_z/sign_z(舍入移到 S3)。
  always @(*) begin : as_d_s2_comb
    reg [55:0] sig_a_aligned, sig_b_aligned, sig_norm;
    reg [56:0] sig_sum;
    reg [10:0] exp_z, norm_exp_limit;
    reg [6:0] norm_lzc, norm_shift;
    reg sign_a, sign_b, sign_z;
    sig_a_aligned = as_d_s1_aaln_q; sig_b_aligned = as_d_s1_baln_q;
    exp_z = as_d_s1_expz_q; sign_a = as_d_s1_signa_q; sign_b = as_d_s1_signb_q;
    sign_z = 1'b0; sig_norm = 0; sig_sum = 0; norm_exp_limit = 0;
    norm_lzc = 0; norm_shift = 0;
      if (sign_a == sign_b) begin
        sign_z = sign_a;
        sig_sum = {1'b0, sig_a_aligned} + {1'b0, sig_b_aligned};
        if (sig_sum[56]) begin
          sig_norm = sig_sum[56:1];
          sig_norm[0] = sig_norm[0] | sig_sum[0];
          exp_z = exp_z + 11'd1;
        end else sig_norm = sig_sum[55:0];
      end else begin
        if (as_d_s1_cancel_q) begin
          sign_z = 1'b0; sig_norm = 56'b0;
        end else if (as_d_s1_altb_q) begin
          sign_z = sign_b; sig_norm = sig_b_aligned - sig_a_aligned;
        end else begin
          sign_z = sign_a; sig_norm = sig_a_aligned - sig_b_aligned;
        end
        if ((sig_norm != 56'b0) && (exp_z > 11'd1)) begin
          norm_lzc = fp_lzc_56(sig_norm);
          norm_exp_limit = exp_z - 11'd1;
          norm_shift = ({4'b0, norm_lzc} < norm_exp_limit) ? norm_lzc : norm_exp_limit[6:0];
          sig_norm = sig_norm << norm_shift;
          exp_z = exp_z - {4'b0, norm_shift};
        end
      end
    as_d_s2_signorm_c = sig_norm;
    as_d_s2_expz_c    = exp_z;
    as_d_s2_signz_c   = sign_z;
  end

  // S3:零值 / 单次舍入 / 组装 + 特殊值选择 → 输出。
  always @(*) begin : as_d_s3_comb
    reg [55:0] sig_norm;
    reg [10:0] exp_z;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg sign_z, guard, sticky, inc;
    reg [2:0] rm;
    reg [63:0] value; reg [4:0] fflags;
    sig_norm = as_d_s2_signorm_q; exp_z = as_d_s2_expz_q; sign_z = as_d_s2_signz_q;
    rm = as_d_s2_rm_q;
    mant53 = 0; mant_round_ext = 0; guard = 0; sticky = 0; inc = 0;
    value = 64'b0; fflags = 5'b00000;
      if (sig_norm == 56'b0) begin
        value = (rm == 3'b010) ? {1'b1, 63'b0} : 64'b0;
        fflags = 5'b00000;
      end else begin
        mant53 = sig_norm[55:3];
        guard = sig_norm[2];
        sticky = sig_norm[1] | sig_norm[0];
        inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
        mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
        if (mant_round_ext[53]) begin exp_z = exp_z + 11'd1; mant53 = mant_round_ext[53:1]; end
        else mant53 = mant_round_ext[52:0];
        if (exp_z >= 11'h7ff) value = fp_overflow_d(sign_z, rm);
        else if ((exp_z == 11'd1) && !mant53[52]) value = {sign_z, 11'b0, mant53[51:0]};
        else value = {sign_z, exp_z, mant53[51:0]};
        fflags = fp_round_flags_d(sign_z, exp_z, mant53, guard, sticky);
      end
      as_d_s3_value_c  = as_d_s2_special_q ? as_d_s2_spval_q : value;
      as_d_s3_fflags_c = as_d_s2_special_q ? as_d_s2_spff_q  : fflags;
  end

  // ---- single FADD 流水寄存器 ----
  reg        as_s_s1_special_c, as_s_s1_special_q;
  reg [63:0] as_s_s1_spval_c,   as_s_s1_spval_q;
  reg [4:0]  as_s_s1_spff_c,    as_s_s1_spff_q;
  reg [26:0] as_s_s1_aaln_c,    as_s_s1_aaln_q;
  reg [26:0] as_s_s1_baln_c,    as_s_s1_baln_q;
  reg [7:0]  as_s_s1_expz_c,    as_s_s1_expz_q;
  reg        as_s_s1_signa_c,   as_s_s1_signa_q;
  reg        as_s_s1_signb_c,   as_s_s1_signb_q;
  reg        as_s_s1_altb_c,    as_s_s1_altb_q;
  reg        as_s_s1_cancel_c,  as_s_s1_cancel_q;
  reg [2:0]  as_s_s1_rm_c,      as_s_s1_rm_q;
  reg [63:0] addsub_s_value_q;
  reg [4:0]  addsub_s_fflags_q;
  reg [26:0] as_s_s2_signorm_c, as_s_s2_signorm_q;
  reg [7:0]  as_s_s2_expz_c,    as_s_s2_expz_q;
  reg        as_s_s2_signz_c,   as_s_s2_signz_q;
  reg        as_s_s2_special_q;
  reg [63:0] as_s_s2_spval_q;
  reg [4:0]  as_s_s2_spff_q;
  reg [2:0]  as_s_s2_rm_q;
  reg [63:0] as_s_s3_value_c;
  reg [4:0]  as_s_s3_fflags_c;

  always @(*) begin : as_s_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value;
    reg is_sub;
    reg [31:0] a, b;
    reg sign_a, sign_b;
    reg [7:0] exp_a, exp_b, exp_a_eff, exp_b_eff, exp_z, exp_diff;
    reg [22:0] frac_a, frac_b;
    reg [26:0] sig_a, sig_b, sig_a_aligned, sig_b_aligned;
    reg [5:0] shift_dist;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i; is_sub = sub_op_i;
    a = 0; b = 0; exp_a_eff = 0; exp_b_eff = 0; exp_z = 0; exp_diff = 0; shift_dist = 0;
    sig_a = 0; sig_b = 0; sig_a_aligned = 0; sig_b_aligned = 0;
    as_s_s1_special_c = 1'b0; as_s_s1_spval_c = 64'b0; as_s_s1_spff_c = 5'b0;
    as_s_s1_altb_c = 1'b0; as_s_s1_cancel_c = 1'b0;
      a = rs1_value[31:0]; b = rs2_value[31:0];
      sign_a = a[31]; sign_b = b[31] ^ is_sub;
      exp_a = a[30:23]; exp_b = b[30:23];
      frac_a = a[22:0]; frac_b = b[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      b_is_nan = fp_is_nan_s_value(rs2_value);
      a_is_inf = (rs1_value[63:32] == 32'hffff_ffff) && (exp_a == 8'hff) && (frac_a == 23'b0);
      b_is_inf = (rs2_value[63:32] == 32'hffff_ffff) && (exp_b == 8'hff) && (frac_b == 23'b0);
      a_is_zero = (rs1_value[63:32] == 32'hffff_ffff) && (exp_a == 8'h00) && (frac_a == 23'b0);
      b_is_zero = (rs2_value[63:32] == 32'hffff_ffff) && (exp_b == 8'h00) && (frac_b == 23'b0);
      if (a_is_nan || b_is_nan) begin
        as_s_s1_special_c = 1'b1; as_s_s1_spval_c = 64'hffffffff7fc00000;
        as_s_s1_spff_c = (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value)) ? `FP_FLAG_NV : 5'b00000;
      end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
        as_s_s1_special_c = 1'b1; as_s_s1_spval_c = 64'hffffffff7fc00000;
        as_s_s1_spff_c = `FP_FLAG_NV;
      end else if (a_is_inf) begin
        as_s_s1_special_c = 1'b1; as_s_s1_spval_c = {32'hffff_ffff, sign_a, 8'hff, 23'b0};
      end else if (b_is_inf) begin
        as_s_s1_special_c = 1'b1; as_s_s1_spval_c = {32'hffff_ffff, sign_b, 8'hff, 23'b0};
      end else if (a_is_zero && b_is_zero) begin
        as_s_s1_special_c = 1'b1;
        as_s_s1_spval_c = {32'hffff_ffff, ((rm_i == 3'b010) ? (sign_a | sign_b) : (sign_a & sign_b)), 31'b0};
      end else if (a_is_zero) begin
        as_s_s1_special_c = 1'b1; as_s_s1_spval_c = {32'hffff_ffff, sign_b, exp_b, frac_b};
      end else if (b_is_zero) begin
        as_s_s1_special_c = 1'b1; as_s_s1_spval_c = {32'hffff_ffff, a};
      end
      exp_a_eff = (exp_a == 8'h00) ? 8'd1 : exp_a;
      exp_b_eff = (exp_b == 8'h00) ? 8'd1 : exp_b;
      sig_a = {(exp_a != 8'h00), frac_a, 3'b000};
      sig_b = {(exp_b != 8'h00), frac_b, 3'b000};
      if (exp_a_eff >= exp_b_eff) begin
        exp_z = exp_a_eff;
        sig_a_aligned = sig_a;
        exp_diff = exp_a_eff - exp_b_eff;
        shift_dist = (exp_diff >= 8'd27) ? 6'd27 : exp_diff[5:0];
        sig_b_aligned = fp_shift_right_jam_27(sig_b, shift_dist);
      end else begin
        exp_z = exp_b_eff;
        exp_diff = exp_b_eff - exp_a_eff;
        shift_dist = (exp_diff >= 8'd27) ? 6'd27 : exp_diff[5:0];
        sig_a_aligned = fp_shift_right_jam_27(sig_a, shift_dist);
        sig_b_aligned = sig_b;
      end
      as_s_s1_altb_c = (exp_a_eff < exp_b_eff) ||
                       ((exp_a_eff == exp_b_eff) && (sig_a < sig_b));
      as_s_s1_cancel_c = (exp_a_eff == exp_b_eff) && (sig_a == sig_b);
      as_s_s1_aaln_c = sig_a_aligned;
      as_s_s1_baln_c = sig_b_aligned;
      as_s_s1_expz_c = exp_z;
      as_s_s1_signa_c = sign_a;
      as_s_s1_signb_c = sign_b;
      as_s_s1_rm_c = rm_i;
  end

  // S2:同号加 / 异号减 + 规格化 → sig_norm/exp_z/sign_z(舍入移到 S3)。
  always @(*) begin : as_s_s2_comb
    reg [26:0] sig_a_aligned, sig_b_aligned, sig_norm;
    reg [27:0] sig_sum;
    reg [7:0] exp_z, norm_exp_limit;
    reg [5:0] norm_lzc, norm_shift;
    reg sign_a, sign_b, sign_z;
    sig_a_aligned = as_s_s1_aaln_q; sig_b_aligned = as_s_s1_baln_q;
    exp_z = as_s_s1_expz_q; sign_a = as_s_s1_signa_q; sign_b = as_s_s1_signb_q;
    sign_z = 1'b0; sig_norm = 0; sig_sum = 0; norm_exp_limit = 0;
    norm_lzc = 0; norm_shift = 0;
      if (sign_a == sign_b) begin
        sign_z = sign_a;
        sig_sum = {1'b0, sig_a_aligned} + {1'b0, sig_b_aligned};
        if (sig_sum[27]) begin
          sig_norm = sig_sum[27:1];
          sig_norm[0] = sig_norm[0] | sig_sum[0];
          exp_z = exp_z + 8'd1;
        end else sig_norm = sig_sum[26:0];
      end else begin
        if (as_s_s1_cancel_q) begin
          sign_z = 1'b0; sig_norm = 27'b0;
        end else if (as_s_s1_altb_q) begin
          sign_z = sign_b; sig_norm = sig_b_aligned - sig_a_aligned;
        end else begin
          sign_z = sign_a; sig_norm = sig_a_aligned - sig_b_aligned;
        end
        if ((sig_norm != 27'b0) && (exp_z > 8'd1)) begin
          norm_lzc = fp_lzc_27(sig_norm);
          norm_exp_limit = exp_z - 8'd1;
          norm_shift = ({2'b0, norm_lzc} < norm_exp_limit) ? norm_lzc : norm_exp_limit[5:0];
          sig_norm = sig_norm << norm_shift;
          exp_z = exp_z - {2'b0, norm_shift};
        end
      end
    as_s_s2_signorm_c = sig_norm;
    as_s_s2_expz_c    = exp_z;
    as_s_s2_signz_c   = sign_z;
  end

  // S3:零值 / 单次舍入 / 组装 + 特殊值选择 → 输出。
  always @(*) begin : as_s_s3_comb
    reg [26:0] sig_norm;
    reg [7:0] exp_z;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg sign_z, guard, sticky, inc;
    reg [2:0] rm;
    reg [63:0] value; reg [4:0] fflags;
    sig_norm = as_s_s2_signorm_q; exp_z = as_s_s2_expz_q; sign_z = as_s_s2_signz_q;
    rm = as_s_s2_rm_q;
    mant24 = 0; mant_round_ext = 0; guard = 0; sticky = 0; inc = 0;
    value = 64'b0; fflags = 5'b00000;
      if (sig_norm == 27'b0) begin
        value = (rm == 3'b010) ? 64'hffffffff80000000 : 64'hffffffff00000000;
        fflags = 5'b00000;
      end else begin
        mant24 = sig_norm[26:3];
        guard = sig_norm[2];
        sticky = sig_norm[1] | sig_norm[0];
        inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
        mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
        if (mant_round_ext[24]) begin exp_z = exp_z + 8'd1; mant24 = mant_round_ext[24:1]; end
        else mant24 = mant_round_ext[23:0];
        if (exp_z >= 8'hff) value = fp_overflow_s(sign_z, rm);
        else if ((exp_z == 8'd1) && !mant24[23]) value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
        else value = {32'hffff_ffff, sign_z, exp_z, mant24[22:0]};
        fflags = fp_round_flags_s(sign_z, exp_z, mant24, guard, sticky);
      end
      as_s_s3_value_c  = as_s_s2_special_q ? as_s_s2_spval_q : value;
      as_s_s3_fflags_c = as_s_s2_special_q ? as_s_s2_spff_q  : fflags;
  end
  // ===========================================================================
  // FMUL 2 级流水(Phase 2):value/fflags 合并的 fused datapath 切为 2 级,算术逐行不变。
  //   S1: 特殊值判定 + 53×53(24×24)尾数积 product + 指数基 exp_z(进 DSP,LUT 浅)
  //   S2: 规格化 LZC + subnormal 右移 + 单次舍入 + 组装(value+fflags)+ 特殊值选择
  // double/single 两条独立流水,输出端 double_i mux。FP 串行+操作数稳定 → 第 2 拍输出
  // 稳定并保持到第 FP_ARITH_LATENCY 拍(done),故无需直通对齐。
  // ===========================================================================

  // ===========================================================================
  // FMUL 3 级流水(Phase 2-rebalance):value/fflags 合并,算术逐行不变。
  //   S1: 特殊值判定 + 53×53(24×24)尾数积 product + 指数基 exp_z(进 DSP,LUT 浅)
  //   S2: 规格化 LZC + 左规移位 + subnormal 右移 → product_norm(post-subnorm)/exp_z
  //   S3: 尾数抽取 + 单次舍入 + 组装(value+fflags)+ 特殊值选择
  // exp_z 用 signed[13:0](范围 [-1021,3072] 远在内),压短指数算术 CARRY4 链;double/single
  // 各独立流水,输出端 double_i mux。FP 串行+操作数稳定 → 第 3 拍输出稳定保持到 done。
  // ===========================================================================

  // ---- double FMUL 流水寄存器 ----
  reg        mul_d_s1_special_c, mul_d_s1_special_q;
  reg [63:0] mul_d_s1_spval_c,   mul_d_s1_spval_q;
  reg [4:0]  mul_d_s1_spff_c,    mul_d_s1_spff_q;
  reg [105:0] mul_d_s1_product_c, mul_d_s1_product_q;
  reg signed [13:0] mul_d_s1_expz_c, mul_d_s1_expz_q;
  reg        mul_d_s1_signz_c,   mul_d_s1_signz_q;
  reg [2:0]  mul_d_s1_rm_c,      mul_d_s1_rm_q;
  reg        mul_d_s2_special_q;
  reg [63:0] mul_d_s2_spval_q;
  reg [4:0]  mul_d_s2_spff_q;
  reg [105:0] mul_d_s2_pnorm_c, mul_d_s2_pnorm_q;
  reg signed [13:0] mul_d_s2_expz_c, mul_d_s2_expz_q;
  reg        mul_d_s2_signz_q;
  reg [2:0]  mul_d_s2_rm_q;
  reg [63:0] mul_d_value_q;
  reg [4:0]  mul_d_fflags_q;
  reg [63:0] mul_d_s3_value_c;
  reg [4:0]  mul_d_s3_fflags_c;

  always @(*) begin : mul_d_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value;
    reg sign_z;
    reg [10:0] exp_a, exp_b;
    reg [51:0] frac_a, frac_b;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    reg [52:0] sig_a, sig_b;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    sig_a = 0; sig_b = 0;
    mul_d_s1_special_c = 1'b0; mul_d_s1_spval_c = 64'b0; mul_d_s1_spff_c = 5'b0;
    mul_d_s1_product_c = 106'b0; mul_d_s1_expz_c = 0;
      sign_z = rs1_value[63] ^ rs2_value[63];
      exp_a = rs1_value[62:52]; exp_b = rs2_value[62:52];
      frac_a = rs1_value[51:0]; frac_b = rs2_value[51:0];
      a_is_nan = (exp_a == 11'h7ff) && (frac_a != 52'b0);
      b_is_nan = (exp_b == 11'h7ff) && (frac_b != 52'b0);
      a_is_inf = (exp_a == 11'h7ff) && (frac_a == 52'b0);
      b_is_inf = (exp_b == 11'h7ff) && (frac_b == 52'b0);
      a_is_zero = (exp_a == 11'h000) && (frac_a == 52'b0);
      b_is_zero = (exp_b == 11'h000) && (frac_b == 52'b0);
      if (a_is_nan || b_is_nan || (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
        mul_d_s1_special_c = 1'b1;
        mul_d_s1_spval_c = 64'h7ff8000000000000;
        mul_d_s1_spff_c = (fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value) ||
                           (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) ? `FP_FLAG_NV : 5'b00000;
      end else if (a_is_inf || b_is_inf) begin
        mul_d_s1_special_c = 1'b1; mul_d_s1_spval_c = {sign_z, 11'h7ff, 52'b0};
      end else if (a_is_zero || b_is_zero) begin
        mul_d_s1_special_c = 1'b1; mul_d_s1_spval_c = {sign_z, 63'b0};
      end
      sig_a = {(exp_a != 11'h000), frac_a};
      sig_b = {(exp_b != 11'h000), frac_b};
      mul_d_s1_expz_c = ((exp_a == 11'h000) ? 14'd1 : {3'b0, exp_a}) +
                        ((exp_b == 11'h000) ? 14'd1 : {3'b0, exp_b}) - 14'd1023;
      mul_d_s1_product_c = sig_a * sig_b;
      mul_d_s1_signz_c = sign_z;
      mul_d_s1_rm_c = rm_i;
  end

  // S2:仅做左规格化(subnormal 右移移到 S3,与 norm 解耦以压低每级 logic levels)。
  always @(*) begin : mul_d_s2_comb
    reg [105:0] product_norm;
    reg [7:0] norm_lzc, norm_required, norm_shift;
    reg signed [13:0] exp_z;
    product_norm = mul_d_s1_product_q;
    exp_z = mul_d_s1_expz_q;
    norm_lzc = 0; norm_required = 0; norm_shift = 0;
      if ((product_norm != 106'b0) && (exp_z > 1)) begin
        norm_lzc = fp_lzc_106(product_norm);
        norm_required = (norm_lzc > 8'd1) ? (norm_lzc - 8'd1) : 8'd0;
        norm_shift = (norm_required > (exp_z - 1)) ? (exp_z - 1) : norm_required;
        product_norm = product_norm << norm_shift;
        exp_z = exp_z - $signed({1'b0, norm_shift});
      end
    mul_d_s2_pnorm_c = product_norm;
    mul_d_s2_expz_c  = exp_z;
  end

  // S3:subnormal 右移 + 尾数抽取 + 单次舍入 + 组装。
  always @(*) begin : mul_d_s3_comb
    reg [105:0] product_norm;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard, sticky, inc;
    reg signed [13:0] exp_z;
    reg [7:0] sub_shift;
    integer sub_shift_int;
    reg sign_z; reg [2:0] rm;
    reg [63:0] value; reg [4:0] fflags;
    product_norm = mul_d_s2_pnorm_q;
    exp_z = mul_d_s2_expz_q;
    sign_z = mul_d_s2_signz_q;
    rm = mul_d_s2_rm_q;
    mant53 = 0; mant_round_ext = 0; guard = 0; sticky = 0; inc = 0;
    sub_shift = 0; sub_shift_int = 0;
    value = 64'b0; fflags = 5'b00000;
      if (exp_z < 1) begin
        sub_shift_int = 1 - exp_z;
        if (sub_shift_int >= 106) sub_shift = 8'd106; else sub_shift = sub_shift_int;
        product_norm = fp_shift_right_jam_106(product_norm, sub_shift);
        exp_z = 1;
      end
      if (product_norm[105]) begin
        mant53 = product_norm[105:53]; guard = product_norm[52];
        sticky = |product_norm[51:0]; exp_z = exp_z + 1;
      end else begin
        mant53 = product_norm[104:52]; guard = product_norm[51];
        sticky = |product_norm[50:0];
      end
      inc = fp_round_increment(sign_z, rm, mant53[0], guard, sticky);
      mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
      if (mant_round_ext[53]) begin mant53 = mant_round_ext[53:1]; exp_z = exp_z + 1; end
      else mant53 = mant_round_ext[52:0];
      if (exp_z >= 2047) value = fp_overflow_d(sign_z, rm);
      else if ((exp_z <= 1) && !mant53[52]) value = {sign_z, 11'b0, mant53[51:0]};
      else value = {sign_z, exp_z[10:0], mant53[51:0]};
      fflags = fp_round_flags_d(sign_z, exp_z[10:0], mant53, guard, sticky);
      if (exp_z >= 2047) fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      mul_d_s3_value_c  = mul_d_s2_special_q ? mul_d_s2_spval_q : value;
      mul_d_s3_fflags_c = mul_d_s2_special_q ? mul_d_s2_spff_q  : fflags;
  end

  // ---- single FMUL 流水寄存器 ----
  reg        mul_s_s1_special_c, mul_s_s1_special_q;
  reg [63:0] mul_s_s1_spval_c,   mul_s_s1_spval_q;
  reg [4:0]  mul_s_s1_spff_c,    mul_s_s1_spff_q;
  reg [47:0] mul_s_s1_product_c, mul_s_s1_product_q;
  reg signed [13:0] mul_s_s1_expz_c, mul_s_s1_expz_q;
  reg        mul_s_s1_signz_c,   mul_s_s1_signz_q;
  reg [2:0]  mul_s_s1_rm_c,      mul_s_s1_rm_q;
  reg        mul_s_s2_special_q;
  reg [63:0] mul_s_s2_spval_q;
  reg [4:0]  mul_s_s2_spff_q;
  reg [47:0] mul_s_s2_pnorm_c, mul_s_s2_pnorm_q;
  reg signed [13:0] mul_s_s2_expz_c, mul_s_s2_expz_q;
  reg        mul_s_s2_signz_q;
  reg [2:0]  mul_s_s2_rm_q;
  reg [63:0] mul_s_value_q;
  reg [4:0]  mul_s_fflags_q;
  reg [63:0] mul_s_s3_value_c;
  reg [4:0]  mul_s_s3_fflags_c;

  always @(*) begin : mul_s_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value;
    reg [31:0] a, b;
    reg sign_z;
    reg [7:0] exp_a, exp_b;
    reg [22:0] frac_a, frac_b;
    reg a_is_nan, b_is_nan, a_is_inf, b_is_inf, a_is_zero, b_is_zero;
    reg [23:0] sig_a, sig_b;
    rs1_value = frs1_value_i; rs2_value = frs2_value_i;
    a = 0; b = 0; sig_a = 0; sig_b = 0;
    mul_s_s1_special_c = 1'b0; mul_s_s1_spval_c = 64'b0; mul_s_s1_spff_c = 5'b0;
    mul_s_s1_product_c = 48'b0; mul_s_s1_expz_c = 0;
      a = rs1_value[31:0]; b = rs2_value[31:0];
      sign_z = a[31] ^ b[31];
      exp_a = a[30:23]; exp_b = b[30:23];
      frac_a = a[22:0]; frac_b = b[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      b_is_nan = fp_is_nan_s_value(rs2_value);
      a_is_inf = (rs1_value[63:32] == 32'hffff_ffff) && (exp_a == 8'hff) && (frac_a == 23'b0);
      b_is_inf = (rs2_value[63:32] == 32'hffff_ffff) && (exp_b == 8'hff) && (frac_b == 23'b0);
      a_is_zero = (rs1_value[63:32] == 32'hffff_ffff) && (exp_a == 8'h00) && (frac_a == 23'b0);
      b_is_zero = (rs2_value[63:32] == 32'hffff_ffff) && (exp_b == 8'h00) && (frac_b == 23'b0);
      if (a_is_nan || b_is_nan || (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) begin
        mul_s_s1_special_c = 1'b1;
        mul_s_s1_spval_c = 64'hffffffff7fc00000;
        mul_s_s1_spff_c = (fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value) ||
                           (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero)) ? `FP_FLAG_NV : 5'b00000;
      end else if (a_is_inf || b_is_inf) begin
        mul_s_s1_special_c = 1'b1; mul_s_s1_spval_c = {32'hffff_ffff, sign_z, 8'hff, 23'b0};
      end else if (a_is_zero || b_is_zero) begin
        mul_s_s1_special_c = 1'b1; mul_s_s1_spval_c = {32'hffff_ffff, sign_z, 31'b0};
      end
      sig_a = {(exp_a != 8'h00), frac_a};
      sig_b = {(exp_b != 8'h00), frac_b};
      mul_s_s1_expz_c = ((exp_a == 8'h00) ? 14'd1 : {6'b0, exp_a}) +
                        ((exp_b == 8'h00) ? 14'd1 : {6'b0, exp_b}) - 14'd127;
      mul_s_s1_product_c = sig_a * sig_b;
      mul_s_s1_signz_c = sign_z;
      mul_s_s1_rm_c = rm_i;
  end

  // S2:仅做左规格化(subnormal 右移移到 S3)。
  always @(*) begin : mul_s_s2_comb
    reg [47:0] product_norm;
    reg [5:0] norm_lzc, norm_required, norm_shift;
    reg signed [13:0] exp_z;
    product_norm = mul_s_s1_product_q;
    exp_z = mul_s_s1_expz_q;
    norm_lzc = 0; norm_required = 0; norm_shift = 0;
      if ((product_norm != 48'b0) && (exp_z > 1)) begin
        norm_lzc = fp_lzc_48(product_norm);
        norm_required = (norm_lzc > 6'd1) ? (norm_lzc - 6'd1) : 6'd0;
        norm_shift = (norm_required > (exp_z - 1)) ? (exp_z - 1) : norm_required;
        product_norm = product_norm << norm_shift;
        exp_z = exp_z - $signed({1'b0, norm_shift});
      end
    mul_s_s2_pnorm_c = product_norm;
    mul_s_s2_expz_c  = exp_z;
  end

  // S3:subnormal 右移 + 尾数抽取 + 单次舍入 + 组装。
  always @(*) begin : mul_s_s3_comb
    reg [47:0] product_norm;
    reg [5:0] sub_shift;
    integer sub_shift_int;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard, sticky, inc;
    reg signed [13:0] exp_z;
    reg sign_z; reg [2:0] rm;
    reg [63:0] value; reg [4:0] fflags;
    product_norm = mul_s_s2_pnorm_q;
    exp_z = mul_s_s2_expz_q;
    sign_z = mul_s_s2_signz_q;
    rm = mul_s_s2_rm_q;
    mant24 = 0; mant_round_ext = 0; guard = 0; sticky = 0; inc = 0;
    sub_shift = 0; sub_shift_int = 0;
    value = 64'b0; fflags = 5'b00000;
      if (exp_z < 1) begin
        sub_shift_int = 1 - exp_z;
        if (sub_shift_int >= 48) sub_shift = 6'd48; else sub_shift = sub_shift_int;
        product_norm = fp_shift_right_jam_48(product_norm, sub_shift);
        exp_z = 1;
      end
      if (product_norm[47]) begin
        mant24 = product_norm[47:24]; guard = product_norm[23];
        sticky = |product_norm[22:0]; exp_z = exp_z + 1;
      end else begin
        mant24 = product_norm[46:23]; guard = product_norm[22];
        sticky = |product_norm[21:0];
      end
      inc = fp_round_increment(sign_z, rm, mant24[0], guard, sticky);
      mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
      if (mant_round_ext[24]) begin mant24 = mant_round_ext[24:1]; exp_z = exp_z + 1; end
      else mant24 = mant_round_ext[23:0];
      if (exp_z >= 255) value = fp_overflow_s(sign_z, rm);
      else if ((exp_z <= 1) && !mant24[23]) value = {32'hffff_ffff, sign_z, 8'b0, mant24[22:0]};
      else value = {32'hffff_ffff, sign_z, exp_z[7:0], mant24[22:0]};
      fflags = fp_round_flags_s(sign_z, exp_z[7:0], mant24, guard, sticky);
      if (exp_z >= 255) fflags = `FP_FLAG_OF | `FP_FLAG_NX;
      mul_s_s3_value_c  = mul_s_s2_special_q ? mul_s_s2_spval_q : value;
      mul_s_s3_fflags_c = mul_s_s2_special_q ? mul_s_s2_spff_q  : fflags;
  end

  // ===========================================================================
  // FADD/FMUL 流水寄存器推进(2 级:S1 组合→S1 寄存器→S2 组合→输出寄存器)。
  // 操作数稳定 → 第 2 拍输出有效并保持;rst/flush 清零(squash 在飞 op)。
  // ===========================================================================
  always @(posedge clk) begin
    if (rst || flush_i) begin
      as_d_s1_special_q <= 1'b0; as_d_s1_spval_q <= 64'b0; as_d_s1_spff_q <= 5'b0;
      as_d_s1_aaln_q <= 56'b0; as_d_s1_baln_q <= 56'b0; as_d_s1_expz_q <= 11'b0;
      as_d_s1_signa_q <= 1'b0; as_d_s1_signb_q <= 1'b0;
      as_d_s1_altb_q <= 1'b0; as_d_s1_cancel_q <= 1'b0; as_d_s1_rm_q <= 3'b0;
      as_d_s2_signorm_q <= 56'b0; as_d_s2_expz_q <= 11'b0; as_d_s2_signz_q <= 1'b0;
      as_d_s2_special_q <= 1'b0; as_d_s2_spval_q <= 64'b0; as_d_s2_spff_q <= 5'b0;
      as_d_s2_rm_q <= 3'b0;
      addsub_d_value_q <= 64'b0; addsub_d_fflags_q <= 5'b0;
      as_s_s1_special_q <= 1'b0; as_s_s1_spval_q <= 64'b0; as_s_s1_spff_q <= 5'b0;
      as_s_s1_aaln_q <= 27'b0; as_s_s1_baln_q <= 27'b0; as_s_s1_expz_q <= 8'b0;
      as_s_s1_signa_q <= 1'b0; as_s_s1_signb_q <= 1'b0;
      as_s_s1_altb_q <= 1'b0; as_s_s1_cancel_q <= 1'b0; as_s_s1_rm_q <= 3'b0;
      as_s_s2_signorm_q <= 27'b0; as_s_s2_expz_q <= 8'b0; as_s_s2_signz_q <= 1'b0;
      as_s_s2_special_q <= 1'b0; as_s_s2_spval_q <= 64'b0; as_s_s2_spff_q <= 5'b0;
      as_s_s2_rm_q <= 3'b0;
      addsub_s_value_q <= 64'b0; addsub_s_fflags_q <= 5'b0;
      mul_d_s1_special_q <= 1'b0; mul_d_s1_spval_q <= 64'b0; mul_d_s1_spff_q <= 5'b0;
      mul_d_s1_product_q <= 106'b0; mul_d_s1_expz_q <= 0;
      mul_d_s1_signz_q <= 1'b0; mul_d_s1_rm_q <= 3'b0;
      mul_d_s2_special_q <= 1'b0; mul_d_s2_spval_q <= 64'b0; mul_d_s2_spff_q <= 5'b0;
      mul_d_s2_pnorm_q <= 106'b0; mul_d_s2_expz_q <= 0;
      mul_d_s2_signz_q <= 1'b0; mul_d_s2_rm_q <= 3'b0;
      mul_d_value_q <= 64'b0; mul_d_fflags_q <= 5'b0;
      mul_s_s1_special_q <= 1'b0; mul_s_s1_spval_q <= 64'b0; mul_s_s1_spff_q <= 5'b0;
      mul_s_s1_product_q <= 48'b0; mul_s_s1_expz_q <= 0;
      mul_s_s1_signz_q <= 1'b0; mul_s_s1_rm_q <= 3'b0;
      mul_s_s2_special_q <= 1'b0; mul_s_s2_spval_q <= 64'b0; mul_s_s2_spff_q <= 5'b0;
      mul_s_s2_pnorm_q <= 48'b0; mul_s_s2_expz_q <= 0;
      mul_s_s2_signz_q <= 1'b0; mul_s_s2_rm_q <= 3'b0;
      mul_s_value_q <= 64'b0; mul_s_fflags_q <= 5'b0;
    end else begin
      // FADD double
      as_d_s1_special_q <= as_d_s1_special_c; as_d_s1_spval_q <= as_d_s1_spval_c;
      as_d_s1_spff_q <= as_d_s1_spff_c; as_d_s1_aaln_q <= as_d_s1_aaln_c;
      as_d_s1_baln_q <= as_d_s1_baln_c; as_d_s1_expz_q <= as_d_s1_expz_c;
      as_d_s1_signa_q <= as_d_s1_signa_c; as_d_s1_signb_q <= as_d_s1_signb_c;
      as_d_s1_altb_q <= as_d_s1_altb_c; as_d_s1_cancel_q <= as_d_s1_cancel_c;
      as_d_s1_rm_q <= as_d_s1_rm_c;
      as_d_s2_signorm_q <= as_d_s2_signorm_c; as_d_s2_expz_q <= as_d_s2_expz_c;
      as_d_s2_signz_q <= as_d_s2_signz_c; as_d_s2_special_q <= as_d_s1_special_q;
      as_d_s2_spval_q <= as_d_s1_spval_q; as_d_s2_spff_q <= as_d_s1_spff_q;
      as_d_s2_rm_q <= as_d_s1_rm_q;
      addsub_d_value_q <= as_d_s3_value_c; addsub_d_fflags_q <= as_d_s3_fflags_c;
      // FADD single
      as_s_s1_special_q <= as_s_s1_special_c; as_s_s1_spval_q <= as_s_s1_spval_c;
      as_s_s1_spff_q <= as_s_s1_spff_c; as_s_s1_aaln_q <= as_s_s1_aaln_c;
      as_s_s1_baln_q <= as_s_s1_baln_c; as_s_s1_expz_q <= as_s_s1_expz_c;
      as_s_s1_signa_q <= as_s_s1_signa_c; as_s_s1_signb_q <= as_s_s1_signb_c;
      as_s_s1_altb_q <= as_s_s1_altb_c; as_s_s1_cancel_q <= as_s_s1_cancel_c;
      as_s_s1_rm_q <= as_s_s1_rm_c;
      as_s_s2_signorm_q <= as_s_s2_signorm_c; as_s_s2_expz_q <= as_s_s2_expz_c;
      as_s_s2_signz_q <= as_s_s2_signz_c; as_s_s2_special_q <= as_s_s1_special_q;
      as_s_s2_spval_q <= as_s_s1_spval_q; as_s_s2_spff_q <= as_s_s1_spff_q;
      as_s_s2_rm_q <= as_s_s1_rm_q;
      addsub_s_value_q <= as_s_s3_value_c; addsub_s_fflags_q <= as_s_s3_fflags_c;
      // FMUL double (S1→S2→S3 输出)
      mul_d_s1_special_q <= mul_d_s1_special_c; mul_d_s1_spval_q <= mul_d_s1_spval_c;
      mul_d_s1_spff_q <= mul_d_s1_spff_c; mul_d_s1_product_q <= mul_d_s1_product_c;
      mul_d_s1_expz_q <= mul_d_s1_expz_c; mul_d_s1_signz_q <= mul_d_s1_signz_c;
      mul_d_s1_rm_q <= mul_d_s1_rm_c;
      mul_d_s2_special_q <= mul_d_s1_special_q; mul_d_s2_spval_q <= mul_d_s1_spval_q;
      mul_d_s2_spff_q <= mul_d_s1_spff_q; mul_d_s2_pnorm_q <= mul_d_s2_pnorm_c;
      mul_d_s2_expz_q <= mul_d_s2_expz_c; mul_d_s2_signz_q <= mul_d_s1_signz_q;
      mul_d_s2_rm_q <= mul_d_s1_rm_q;
      mul_d_value_q <= mul_d_s3_value_c; mul_d_fflags_q <= mul_d_s3_fflags_c;
      // FMUL single (S1→S2→S3 输出)
      mul_s_s1_special_q <= mul_s_s1_special_c; mul_s_s1_spval_q <= mul_s_s1_spval_c;
      mul_s_s1_spff_q <= mul_s_s1_spff_c; mul_s_s1_product_q <= mul_s_s1_product_c;
      mul_s_s1_expz_q <= mul_s_s1_expz_c; mul_s_s1_signz_q <= mul_s_s1_signz_c;
      mul_s_s1_rm_q <= mul_s_s1_rm_c;
      mul_s_s2_special_q <= mul_s_s1_special_q; mul_s_s2_spval_q <= mul_s_s1_spval_q;
      mul_s_s2_spff_q <= mul_s_s1_spff_q; mul_s_s2_pnorm_q <= mul_s_s2_pnorm_c;
      mul_s_s2_expz_q <= mul_s_s2_expz_c; mul_s_s2_signz_q <= mul_s_s1_signz_q;
      mul_s_s2_rm_q <= mul_s_s1_rm_q;
      mul_s_value_q <= mul_s_s3_value_c; mul_s_fflags_q <= mul_s_s3_fflags_c;
    end
  end

  // ===========================================================================
  // FP#2 修复:fused multiply-add(单次舍入,IEEE-754 正确)——按硬件结构描述。
  //
  // 【硬件结构说明 — FMA 算法 + 4 级流水(Phase 1, 2026-06-29)】
  // 注:FMA 原为单拍纯组合,实测 173 级/36.5ns 是真 Fmax 封顶;现已切为 4 级流水
  //   (RTL 在文件末 "FMA 5 级流水" 段;此处仅保留算法/关键路径说明)。算术逐行不变。
  // - 组合 datapath 关键路径顺序(也是切级依据,见末段 S1..S4 边界):
  //     [S1] 特殊值译码 + 53×53 尾数乘法器(宽积 106/48b,进 DSP)+ 指数基 ep/ec
  //     [S2] 前导零 LZC + 宽度 → ref_w → addend/积对齐移位量 shift_p/shift_c
  //     [S3] addend/积 128b barrel 对齐 + 128b 宽加/减(进位链)→ mag
  //     [S4] 128b LZC 优先编码器 → 规格化 barrel → subnormal 右移 → 末级舍入加法器 → 组装
  // - 共享资源 mux:double/single 两条独立流水各算 {fflags,value},由 double_i 在
  //   输出处显式 mux(见文件末 assign fma_value_o/fma_fflags_o)。
  // - for-loop:无;所用 barrel shifter(fp_shift_right_jam_128)与优先编码器
  //   (fp_lzc_128)是展开的 log 级 mux 树纯组合 helper(综合成移位/编码网络)。
  //
  // 【实现形态说明 — 用 always@* 显式组合块,不用 always_comb 关键字,不藏进大 function】
  //   按规范:纯组合 datapath 用显式 always 块描述,使硬件结构可见;function 仅留给
  //   小型纯组合原语(lzc/barrel-shift/round/saturate/predicate)。
  //   关键工具链约束:本仓库"模块 testbench" gate 用 Icarus iverilog 12.0,实测其对
  //   **`always_comb` 关键字**内的变量常量位选会发 "sorry: constant selects in always_*
  //   ... all bits will be included"(静默错仿真),而 **`always @(*)` 与
  //   `always @(posedge clk)`** 对同样的常量位选完全正确。故本仓库可综合 .v 统一用
  //   `always @(*)`/`always @(posedge clk)`(Verilog-2001 写法,Vivado read_verilog -sv
  //   亦兼容),不用 SV 的 always_comb/always_ff 关键字(后者仅限 .sv 验证代码)。
  //   详见 .github/instructions/rtl-generation-workflow.instructions.md。
  //
  // 算法:精确宽积(106/48-bit)与 addend 在 128-bit 定点场内 anchor-at-larger 对齐
  //   (较小操作数 shift-right-jam 入粘滞),宽加/减 + 单次规格化 + 单次舍入。
  //   场:bit b 权重 = ref - 126 + b(较大操作数 MSB 置于 bit 126,bit 127 留进位)。
  //   E_biased = ref + 1024 - lzc(double) / ref + 128 - lzc(single)。
  //   c=0 折叠进主通路(sig_c=0 → addend_field=0 → 结果=round(a*b));product=0
  //   单列(其 ep 伪权重会污染 ref,不可折叠)。已用算例 1.5*1.0+1.0→2.5 + rv64uf/ud
  //   fmadd 金标 + 4000 迭代 difftest 对 NEMU fused softfloat 全匹配 验证。
  // 返回 {fflags[4:0], value[63:0]} 打包,避免 value/fflags 两份逻辑分歧。
  // ===========================================================================
  // ===========================================================================
  // FMA 5 级流水:原单拍 fused datapath(173 级)切为 5 个寄存器级,算术逐行不变 →
  // bit-exact 按构造保持。double/single 两条独立流水(宽度/偏置/slice 不同),输出端
  // 由 double_i mux。各级关键路径深度(估):S1 积进 DSP(LUT 浅);S2 lzc+宽度+移位量;
  // S3 128b 对齐+宽加;S4 128b LZC+规格化+subnormal;S5 单次舍入+组装。
  //   S1: 特殊值判定 + 53×53 尾数积 product + 指数基 ep/ec
  //   S2: lzc_p/lzc_c → pw/cw → ref_w → 对齐移位量 shift_p/shift_c
  //   S3: 积/加数 128b 对齐(barrel) + 128b 宽加减 mag + 结果符号 res_sign
  //   S4: 128b LZC + 规格化 + subnormal 右移 → magn/e_biased
  //   S5: 尾数抽取 + 单次舍入 + 组装 + 特殊值/零值选择
  // ===========================================================================

  // ---- double FMA 流水寄存器(_c=组合,_q=寄存) ----
  reg         fma_d_s1_special_c, fma_d_s1_special_q;
  reg [63:0]  fma_d_s1_spval_c,   fma_d_s1_spval_q;
  reg [4:0]   fma_d_s1_spff_c,    fma_d_s1_spff_q;
  reg [105:0] fma_d_s1_product_c, fma_d_s1_product_q;
  reg [52:0]  fma_d_s1_sigc_c,    fma_d_s1_sigc_q;
  reg signed [31:0] fma_d_s1_ep_c, fma_d_s1_ep_q;
  reg signed [31:0] fma_d_s1_ec_c, fma_d_s1_ec_q;
  reg         fma_d_s1_signp_c,   fma_d_s1_signp_q;
  reg         fma_d_s1_signc_c,   fma_d_s1_signc_q;
  reg [2:0]   fma_d_s1_rm_c,      fma_d_s1_rm_q;

  reg         fma_d_s2_special_q;
  reg [63:0]  fma_d_s2_spval_q;
  reg [4:0]   fma_d_s2_spff_q;
  reg [105:0] fma_d_s2_product_q;
  reg [52:0]  fma_d_s2_sigc_q;
  reg signed [31:0] fma_d_s2_shiftp_c, fma_d_s2_shiftp_q;
  reg signed [31:0] fma_d_s2_shiftc_c, fma_d_s2_shiftc_q;
  reg signed [31:0] fma_d_s2_refw_c,   fma_d_s2_refw_q;
  reg         fma_d_s2_signp_q;
  reg         fma_d_s2_signc_q;
  reg [2:0]   fma_d_s2_rm_q;

  reg         fma_d_s3_special_q;
  reg [63:0]  fma_d_s3_spval_q;
  reg [4:0]   fma_d_s3_spff_q;
  reg [127:0] fma_d_s3_mag_c, fma_d_s3_mag_q;
  reg         fma_d_s3_ressign_c, fma_d_s3_ressign_q;
  reg signed [31:0] fma_d_s3_refw_q;
  reg [2:0]   fma_d_s3_rm_q;

  // ---- double FMA S1 组合:特殊值 + 积 + ep/ec ----
  always @(*) begin : fma_d_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value, rs3_value;
    reg negate_product, subtract_addend;
    reg sign_a, sign_b, sign_c, sign_p;
    reg [10:0] exp_a, exp_b, exp_c;
    reg [51:0] frac_a, frac_b, frac_c;
    reg [52:0] sig_a, sig_b, sig_c;
    reg a_is_nan, b_is_nan, c_is_nan;
    reg a_is_inf, b_is_inf, c_is_inf;
    reg a_is_zero, b_is_zero, c_is_zero;
    reg prod_is_inf, prod_is_zero;
    reg invalid_mul0inf, invalid_infsub, result_is_nan, nv;
    integer exp_a_eff, exp_b_eff, exp_c_eff;
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    rs3_value = frs3_value_i;
    negate_product = negate_product_i;
    subtract_addend = subtract_addend_i;
    exp_a_eff = 0; exp_b_eff = 0; exp_c_eff = 0;
    sig_a = 0; sig_b = 0; sig_c = 0;
    fma_d_s1_special_c = 1'b0;
    fma_d_s1_spval_c = 64'b0;
    fma_d_s1_spff_c = 5'b00000;
    fma_d_s1_product_c = 106'b0;
    fma_d_s1_sigc_c = 53'b0;
    fma_d_s1_ep_c = 0;
    fma_d_s1_ec_c = 0;
      sign_a = rs1_value[63];
      sign_b = rs2_value[63];
      sign_c = rs3_value[63] ^ subtract_addend;
      sign_p = sign_a ^ sign_b ^ negate_product;
      exp_a = rs1_value[62:52]; exp_b = rs2_value[62:52]; exp_c = rs3_value[62:52];
      frac_a = rs1_value[51:0]; frac_b = rs2_value[51:0]; frac_c = rs3_value[51:0];
      a_is_nan = fp_is_nan_d_value(rs1_value);
      b_is_nan = fp_is_nan_d_value(rs2_value);
      c_is_nan = fp_is_nan_d_value(rs3_value);
      a_is_inf = fp_is_inf_d_value(rs1_value);
      b_is_inf = fp_is_inf_d_value(rs2_value);
      c_is_inf = fp_is_inf_d_value(rs3_value);
      a_is_zero = fp_is_zero_d_value(rs1_value);
      b_is_zero = fp_is_zero_d_value(rs2_value);
      c_is_zero = fp_is_zero_d_value(rs3_value);
      prod_is_inf = a_is_inf || b_is_inf;
      prod_is_zero = a_is_zero || b_is_zero;
      invalid_mul0inf = (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero);
      invalid_infsub = prod_is_inf && c_is_inf && (sign_c != sign_p);
      result_is_nan = a_is_nan || b_is_nan || c_is_nan ||
                      invalid_mul0inf || invalid_infsub;
      nv = fp_is_snan_d_value(rs1_value) || fp_is_snan_d_value(rs2_value) ||
           fp_is_snan_d_value(rs3_value) || invalid_mul0inf || invalid_infsub;

      // 特殊值早出(与原 datapath 同分支);main 路结果在 S4 再按 special 选择丢弃。
      if (result_is_nan) begin
        fma_d_s1_special_c = 1'b1;
        fma_d_s1_spval_c = 64'h7ff8000000000000;
        fma_d_s1_spff_c = nv ? `FP_FLAG_NV : 5'b00000;
      end else if (prod_is_inf) begin
        fma_d_s1_special_c = 1'b1;
        fma_d_s1_spval_c = {sign_p, 11'h7ff, 52'b0};
      end else if (c_is_inf) begin
        fma_d_s1_special_c = 1'b1;
        fma_d_s1_spval_c = {sign_c, 11'h7ff, 52'b0};
      end else if (prod_is_zero && c_is_zero) begin
        fma_d_s1_special_c = 1'b1;
        fma_d_s1_spval_c = {((sign_p == sign_c) ? sign_p : (rm_i == 3'b010)), 63'b0};
      end else if (prod_is_zero) begin
        fma_d_s1_special_c = 1'b1;
        fma_d_s1_spval_c = {sign_c, exp_c, frac_c};
      end

      // main 路操作数(无条件计算;特殊时被 S4 丢弃)。
      exp_a_eff = (exp_a == 11'h000) ? 1 : exp_a;
      exp_b_eff = (exp_b == 11'h000) ? 1 : exp_b;
      exp_c_eff = (exp_c == 11'h000) ? 1 : exp_c;
      sig_a = {(exp_a != 11'h000), frac_a};
      sig_b = {(exp_b != 11'h000), frac_b};
      sig_c = {(exp_c != 11'h000), frac_c};
      fma_d_s1_product_c = sig_a * sig_b;
      fma_d_s1_ep_c = exp_a_eff + exp_b_eff - 2150;
      fma_d_s1_ec_c = exp_c_eff - 1075;
      fma_d_s1_sigc_c = sig_c;
      fma_d_s1_signp_c = sign_p;
      fma_d_s1_signc_c = sign_c;
      fma_d_s1_rm_c = rm_i;
  end

  // ---- double FMA S2 组合:lzc/宽度 → ref_w → 对齐移位量 ----
  always @(*) begin : fma_d_s2_comb
    reg [7:0] lzc_p;
    reg [5:0] lzc_c53;
    integer ep, ec, pw, cw, ref_w;
    lzc_p = fp_lzc_106(fma_d_s1_product_q);
    lzc_c53 = fp_norm_shift_53(fma_d_s1_sigc_q);
    ep = fma_d_s1_ep_q;
    ec = fma_d_s1_ec_q;
    pw = ep + 105 - lzc_p;
    cw = ec + 52 - lzc_c53;
    ref_w = (pw >= cw) ? pw : cw;
    fma_d_s2_refw_c   = ref_w;
    fma_d_s2_shiftp_c = ep - ref_w + 126;
    fma_d_s2_shiftc_c = ec - ref_w + 126;
  end

  // ---- double FMA S3 组合:128b 对齐 + 宽加减 → mag/res_sign ----
  always @(*) begin : fma_d_s3_comb
    reg [127:0] prod_field, addend_field;
    integer shift_p, shift_c, negsh;
    reg sign_p, sign_c;
    shift_p = fma_d_s2_shiftp_q;
    shift_c = fma_d_s2_shiftc_q;
    sign_p = fma_d_s2_signp_q;
    sign_c = fma_d_s2_signc_q;
    negsh = 0;
    if (shift_p >= 0) begin
      prod_field = {22'b0, fma_d_s2_product_q} << shift_p;
    end else begin
      negsh = (-shift_p > 128) ? 128 : -shift_p;
      prod_field = fp_shift_right_jam_128({22'b0, fma_d_s2_product_q}, negsh[7:0]);
    end
    if (shift_c >= 0) begin
      addend_field = {75'b0, fma_d_s2_sigc_q} << shift_c;
    end else begin
      negsh = (-shift_c > 128) ? 128 : -shift_c;
      addend_field = fp_shift_right_jam_128({75'b0, fma_d_s2_sigc_q}, negsh[7:0]);
    end
    if (sign_p == sign_c) begin
      fma_d_s3_mag_c = prod_field + addend_field;
      fma_d_s3_ressign_c = sign_p;
    end else if (prod_field >= addend_field) begin
      fma_d_s3_mag_c = prod_field - addend_field;
      fma_d_s3_ressign_c = sign_p;
    end else begin
      fma_d_s3_mag_c = addend_field - prod_field;
      fma_d_s3_ressign_c = sign_c;
    end
  end

  // ---- double FMA S4/S5(由原单块 S4 拆为 2 级,把 50 级关键路径压到 ≤ dispatch)----
  reg [63:0] fma_d_value_q;
  reg [4:0]  fma_d_fflags_q;
  // S4 寄存器:lzc+规格化+subnormal 后的 magn / e_biased / is_zero + 直通 special/sign/rm。
  reg [127:0] fma_d_s4_magn_c, fma_d_s4_magn_q;
  reg signed [13:0] fma_d_s4_ebiased_c, fma_d_s4_ebiased_q;
  reg fma_d_s4_iszero_c, fma_d_s4_iszero_q;
  reg fma_d_s4_ressign_q;
  reg [2:0] fma_d_s4_rm_q;
  reg fma_d_s4_special_q;
  reg [63:0] fma_d_s4_spval_q;
  reg [4:0] fma_d_s4_spff_q;
  reg [63:0] fma_d_s5_value_c;
  reg [4:0]  fma_d_s5_fflags_c;

  // ---- double FMA S4 组合:128b LZC + 规格化 + subnormal 右移 ----
  always @(*) begin : fma_d_s4_comb
    reg [127:0] mag, magn;
    reg [7:0] lzc_m;
    integer ref_w, e_biased, sub_shift, negsh;
    mag = fma_d_s3_mag_q;
    ref_w = fma_d_s3_refw_q;
    magn = 128'b0; lzc_m = 0; e_biased = 0; sub_shift = 0; negsh = 0;
    fma_d_s4_iszero_c = (mag == 128'b0);
    if (mag != 128'b0) begin
      lzc_m = fp_lzc_128(mag);
      magn = mag << lzc_m;
      e_biased = ref_w + 1024 - lzc_m;
      if (e_biased < 1) begin
        sub_shift = 1 - e_biased;
        negsh = (sub_shift > 128) ? 128 : sub_shift;
        magn = fp_shift_right_jam_128(magn, negsh[7:0]);
        e_biased = 1;
      end
    end
    fma_d_s4_magn_c = magn;
    fma_d_s4_ebiased_c = e_biased;
  end

  // ---- double FMA S5 组合:尾数抽取 + 单次舍入 + 组装 + 特殊/零值选择 → 输出 ----
  always @(*) begin : fma_d_s5_comb
    reg [127:0] magn;
    reg signed [13:0] e_biased;
    reg [52:0] mant53;
    reg [53:0] mant_round_ext;
    reg guard, sticky, inc, res_sign;
    reg [2:0] rm;
    reg [63:0] value;
    reg [4:0] fflags;
    magn = fma_d_s4_magn_q;
    e_biased = fma_d_s4_ebiased_q;
    res_sign = fma_d_s4_ressign_q;
    rm = fma_d_s4_rm_q;
    mant53 = 0; mant_round_ext = 0; guard = 1'b0; sticky = 1'b0; inc = 1'b0;
    value = 64'b0; fflags = 5'b00000;
    if (fma_d_s4_iszero_q) begin
      value = (rm == 3'b010) ? {1'b1, 63'b0} : 64'b0;
    end else begin
      mant53 = magn[127:75];
      guard = magn[74];
      sticky = |magn[73:0];
      inc = fp_round_increment(res_sign, rm, mant53[0], guard, sticky);
      mant_round_ext = {1'b0, mant53} + {{53{1'b0}}, inc};
      if (mant_round_ext[53]) begin e_biased = e_biased + 1; mant53 = mant_round_ext[53:1]; end
      else mant53 = mant_round_ext[52:0];
      fflags = fp_round_flags_d(res_sign, e_biased[10:0], mant53, guard, sticky);
      if (e_biased >= 2047) begin value = fp_overflow_d(res_sign, rm); fflags = `FP_FLAG_OF | `FP_FLAG_NX; end
      else if ((e_biased <= 1) && !mant53[52]) value = {res_sign, 11'b0, mant53[51:0]};
      else value = {res_sign, e_biased[10:0], mant53[51:0]};
    end
    fma_d_s5_value_c  = fma_d_s4_special_q ? fma_d_s4_spval_q : value;
    fma_d_s5_fflags_c = fma_d_s4_special_q ? fma_d_s4_spff_q  : fflags;
  end

  // ---- single FMA 流水寄存器 ----
  reg         fma_s_s1_special_c, fma_s_s1_special_q;
  reg [63:0]  fma_s_s1_spval_c,   fma_s_s1_spval_q;
  reg [4:0]   fma_s_s1_spff_c,    fma_s_s1_spff_q;
  reg [47:0]  fma_s_s1_product_c, fma_s_s1_product_q;
  reg [23:0]  fma_s_s1_sigc_c,    fma_s_s1_sigc_q;
  reg signed [31:0] fma_s_s1_ep_c, fma_s_s1_ep_q;
  reg signed [31:0] fma_s_s1_ec_c, fma_s_s1_ec_q;
  reg         fma_s_s1_signp_c,   fma_s_s1_signp_q;
  reg         fma_s_s1_signc_c,   fma_s_s1_signc_q;
  reg [2:0]   fma_s_s1_rm_c,      fma_s_s1_rm_q;

  reg         fma_s_s2_special_q;
  reg [63:0]  fma_s_s2_spval_q;
  reg [4:0]   fma_s_s2_spff_q;
  reg [47:0]  fma_s_s2_product_q;
  reg [23:0]  fma_s_s2_sigc_q;
  reg signed [31:0] fma_s_s2_shiftp_c, fma_s_s2_shiftp_q;
  reg signed [31:0] fma_s_s2_shiftc_c, fma_s_s2_shiftc_q;
  reg signed [31:0] fma_s_s2_refw_c,   fma_s_s2_refw_q;
  reg         fma_s_s2_signp_q;
  reg         fma_s_s2_signc_q;
  reg [2:0]   fma_s_s2_rm_q;

  reg         fma_s_s3_special_q;
  reg [63:0]  fma_s_s3_spval_q;
  reg [4:0]   fma_s_s3_spff_q;
  reg [127:0] fma_s_s3_mag_c, fma_s_s3_mag_q;
  reg         fma_s_s3_ressign_c, fma_s_s3_ressign_q;
  reg signed [31:0] fma_s_s3_refw_q;
  reg [2:0]   fma_s_s3_rm_q;

  // ---- single FMA S1 组合 ----
  always @(*) begin : fma_s_s1_comb
    reg [`XLEN-1:0] rs1_value, rs2_value, rs3_value;
    reg negate_product, subtract_addend;
    reg [31:0] a, b, c;
    reg sign_a, sign_b, sign_c, sign_p;
    reg [7:0] exp_a, exp_b, exp_c;
    reg [22:0] frac_a, frac_b, frac_c;
    reg [23:0] sig_a, sig_b, sig_c;
    reg a_is_nan, b_is_nan, c_is_nan;
    reg a_is_inf, b_is_inf, c_is_inf;
    reg a_is_zero, b_is_zero, c_is_zero;
    reg prod_is_inf, prod_is_zero;
    reg invalid_mul0inf, invalid_infsub, result_is_nan, nv;
    integer exp_a_eff, exp_b_eff, exp_c_eff;
    rs1_value = frs1_value_i;
    rs2_value = frs2_value_i;
    rs3_value = frs3_value_i;
    negate_product = negate_product_i;
    subtract_addend = subtract_addend_i;
    a = 0; b = 0; c = 0;
    exp_a_eff = 0; exp_b_eff = 0; exp_c_eff = 0;
    sig_a = 0; sig_b = 0; sig_c = 0;
    fma_s_s1_special_c = 1'b0;
    fma_s_s1_spval_c = 64'b0;
    fma_s_s1_spff_c = 5'b00000;
    fma_s_s1_product_c = 48'b0;
    fma_s_s1_sigc_c = 24'b0;
    fma_s_s1_ep_c = 0;
    fma_s_s1_ec_c = 0;
      a = rs1_value[31:0]; b = rs2_value[31:0]; c = rs3_value[31:0];
      sign_a = a[31];
      sign_b = b[31];
      sign_c = c[31] ^ subtract_addend;
      sign_p = sign_a ^ sign_b ^ negate_product;
      exp_a = a[30:23]; exp_b = b[30:23]; exp_c = c[30:23];
      frac_a = a[22:0]; frac_b = b[22:0]; frac_c = c[22:0];
      a_is_nan = fp_is_nan_s_value(rs1_value);
      b_is_nan = fp_is_nan_s_value(rs2_value);
      c_is_nan = fp_is_nan_s_value(rs3_value);
      a_is_inf = fp_is_inf_s_value(rs1_value);
      b_is_inf = fp_is_inf_s_value(rs2_value);
      c_is_inf = fp_is_inf_s_value(rs3_value);
      a_is_zero = fp_is_zero_s_value(rs1_value);
      b_is_zero = fp_is_zero_s_value(rs2_value);
      c_is_zero = fp_is_zero_s_value(rs3_value);
      prod_is_inf = a_is_inf || b_is_inf;
      prod_is_zero = a_is_zero || b_is_zero;
      invalid_mul0inf = (a_is_inf && b_is_zero) || (b_is_inf && a_is_zero);
      invalid_infsub = prod_is_inf && c_is_inf && (sign_c != sign_p);
      result_is_nan = a_is_nan || b_is_nan || c_is_nan ||
                      invalid_mul0inf || invalid_infsub;
      nv = fp_is_snan_s_value(rs1_value) || fp_is_snan_s_value(rs2_value) ||
           fp_is_snan_s_value(rs3_value) || invalid_mul0inf || invalid_infsub;

      if (result_is_nan) begin
        fma_s_s1_special_c = 1'b1;
        fma_s_s1_spval_c = 64'hffffffff7fc00000;
        fma_s_s1_spff_c = nv ? `FP_FLAG_NV : 5'b00000;
      end else if (prod_is_inf) begin
        fma_s_s1_special_c = 1'b1;
        fma_s_s1_spval_c = {32'hffff_ffff, sign_p, 8'hff, 23'b0};
      end else if (c_is_inf) begin
        fma_s_s1_special_c = 1'b1;
        fma_s_s1_spval_c = {32'hffff_ffff, sign_c, 8'hff, 23'b0};
      end else if (prod_is_zero && c_is_zero) begin
        fma_s_s1_special_c = 1'b1;
        fma_s_s1_spval_c = {32'hffff_ffff, ((sign_p == sign_c) ? sign_p : (rm_i == 3'b010)), 31'b0};
      end else if (prod_is_zero) begin
        fma_s_s1_special_c = 1'b1;
        fma_s_s1_spval_c = {32'hffff_ffff, sign_c, exp_c, frac_c};
      end

      exp_a_eff = (exp_a == 8'h00) ? 1 : exp_a;
      exp_b_eff = (exp_b == 8'h00) ? 1 : exp_b;
      exp_c_eff = (exp_c == 8'h00) ? 1 : exp_c;
      sig_a = {(exp_a != 8'h00), frac_a};
      sig_b = {(exp_b != 8'h00), frac_b};
      sig_c = {(exp_c != 8'h00), frac_c};
      fma_s_s1_product_c = sig_a * sig_b;
      fma_s_s1_ep_c = exp_a_eff + exp_b_eff - 300;
      fma_s_s1_ec_c = exp_c_eff - 150;
      fma_s_s1_sigc_c = sig_c;
      fma_s_s1_signp_c = sign_p;
      fma_s_s1_signc_c = sign_c;
      fma_s_s1_rm_c = rm_i;
  end

  // ---- single FMA S2 组合 ----
  always @(*) begin : fma_s_s2_comb
    reg [5:0] lzc_p;
    reg [4:0] lzc_c24;
    integer ep, ec, pw, cw, ref_w;
    lzc_p = fp_lzc_48(fma_s_s1_product_q);
    lzc_c24 = fp_norm_shift_24(fma_s_s1_sigc_q);
    ep = fma_s_s1_ep_q;
    ec = fma_s_s1_ec_q;
    pw = ep + 47 - lzc_p;
    cw = ec + 23 - lzc_c24;
    ref_w = (pw >= cw) ? pw : cw;
    fma_s_s2_refw_c   = ref_w;
    fma_s_s2_shiftp_c = ep - ref_w + 126;
    fma_s_s2_shiftc_c = ec - ref_w + 126;
  end

  // ---- single FMA S3 组合 ----
  always @(*) begin : fma_s_s3_comb
    reg [127:0] prod_field, addend_field;
    integer shift_p, shift_c, negsh;
    reg sign_p, sign_c;
    shift_p = fma_s_s2_shiftp_q;
    shift_c = fma_s_s2_shiftc_q;
    sign_p = fma_s_s2_signp_q;
    sign_c = fma_s_s2_signc_q;
    negsh = 0;
    if (shift_p >= 0) begin
      prod_field = {80'b0, fma_s_s2_product_q} << shift_p;
    end else begin
      negsh = (-shift_p > 128) ? 128 : -shift_p;
      prod_field = fp_shift_right_jam_128({80'b0, fma_s_s2_product_q}, negsh[7:0]);
    end
    if (shift_c >= 0) begin
      addend_field = {104'b0, fma_s_s2_sigc_q} << shift_c;
    end else begin
      negsh = (-shift_c > 128) ? 128 : -shift_c;
      addend_field = fp_shift_right_jam_128({104'b0, fma_s_s2_sigc_q}, negsh[7:0]);
    end
    if (sign_p == sign_c) begin
      fma_s_s3_mag_c = prod_field + addend_field;
      fma_s_s3_ressign_c = sign_p;
    end else if (prod_field >= addend_field) begin
      fma_s_s3_mag_c = prod_field - addend_field;
      fma_s_s3_ressign_c = sign_p;
    end else begin
      fma_s_s3_mag_c = addend_field - prod_field;
      fma_s_s3_ressign_c = sign_c;
    end
  end

  // ---- single FMA S4/S5(同 double,拆为 2 级)----
  reg [63:0] fma_s_value_q;
  reg [4:0]  fma_s_fflags_q;
  reg [127:0] fma_s_s4_magn_c, fma_s_s4_magn_q;
  reg signed [13:0] fma_s_s4_ebiased_c, fma_s_s4_ebiased_q;
  reg fma_s_s4_iszero_c, fma_s_s4_iszero_q;
  reg fma_s_s4_ressign_q;
  reg [2:0] fma_s_s4_rm_q;
  reg fma_s_s4_special_q;
  reg [63:0] fma_s_s4_spval_q;
  reg [4:0] fma_s_s4_spff_q;
  reg [63:0] fma_s_s5_value_c;
  reg [4:0]  fma_s_s5_fflags_c;

  // ---- single FMA S4 组合:128b LZC + 规格化 + subnormal 右移 ----
  always @(*) begin : fma_s_s4_comb
    reg [127:0] mag, magn;
    reg [7:0] lzc_m;
    integer ref_w, e_biased, sub_shift, negsh;
    mag = fma_s_s3_mag_q;
    ref_w = fma_s_s3_refw_q;
    magn = 128'b0; lzc_m = 0; e_biased = 0; sub_shift = 0; negsh = 0;
    fma_s_s4_iszero_c = (mag == 128'b0);
    if (mag != 128'b0) begin
      lzc_m = fp_lzc_128(mag);
      magn = mag << lzc_m;
      e_biased = ref_w + 128 - lzc_m;
      if (e_biased < 1) begin
        sub_shift = 1 - e_biased;
        negsh = (sub_shift > 128) ? 128 : sub_shift;
        magn = fp_shift_right_jam_128(magn, negsh[7:0]);
        e_biased = 1;
      end
    end
    fma_s_s4_magn_c = magn;
    fma_s_s4_ebiased_c = e_biased;
  end

  // ---- single FMA S5 组合:尾数抽取 + 单次舍入 + 组装 + 特殊/零值选择 → 输出 ----
  always @(*) begin : fma_s_s5_comb
    reg [127:0] magn;
    reg signed [13:0] e_biased;
    reg [23:0] mant24;
    reg [24:0] mant_round_ext;
    reg guard, sticky, inc, res_sign;
    reg [2:0] rm;
    reg [63:0] value;
    reg [4:0] fflags;
    magn = fma_s_s4_magn_q;
    e_biased = fma_s_s4_ebiased_q;
    res_sign = fma_s_s4_ressign_q;
    rm = fma_s_s4_rm_q;
    mant24 = 0; mant_round_ext = 0; guard = 1'b0; sticky = 1'b0; inc = 1'b0;
    value = 64'b0; fflags = 5'b00000;
    if (fma_s_s4_iszero_q) begin
      value = (rm == 3'b010) ? 64'hffffffff80000000 : 64'hffffffff00000000;
    end else begin
      mant24 = magn[127:104];
      guard = magn[103];
      sticky = |magn[102:0];
      inc = fp_round_increment(res_sign, rm, mant24[0], guard, sticky);
      mant_round_ext = {1'b0, mant24} + {{24{1'b0}}, inc};
      if (mant_round_ext[24]) begin e_biased = e_biased + 1; mant24 = mant_round_ext[24:1]; end
      else mant24 = mant_round_ext[23:0];
      fflags = fp_round_flags_s(res_sign, e_biased[7:0], mant24, guard, sticky);
      if (e_biased >= 255) begin value = fp_overflow_s(res_sign, rm); fflags = `FP_FLAG_OF | `FP_FLAG_NX; end
      else if ((e_biased <= 1) && !mant24[23]) value = {32'hffff_ffff, res_sign, 8'b0, mant24[22:0]};
      else value = {32'hffff_ffff, res_sign, e_biased[7:0], mant24[22:0]};
    end
    fma_s_s5_value_c  = fma_s_s4_special_q ? fma_s_s4_spval_q : value;
    fma_s_s5_fflags_c = fma_s_s4_special_q ? fma_s_s4_spff_q  : fflags;
  end

  // ===========================================================================
  // 流水寄存器推进(操作数全程稳定,故每拍推进;仅在 done 拍由父模块采样)。
  // rst/flush 清零(squash 在飞 op)。FMA double/single 各 4 级;addsub/mul 见下方直通。
  // ===========================================================================
  always @(posedge clk) begin
    if (rst || flush_i) begin
      fma_d_s1_special_q <= 1'b0; fma_d_s1_spval_q <= 64'b0; fma_d_s1_spff_q <= 5'b0;
      fma_d_s1_product_q <= 106'b0; fma_d_s1_sigc_q <= 53'b0;
      fma_d_s1_ep_q <= 0; fma_d_s1_ec_q <= 0;
      fma_d_s1_signp_q <= 1'b0; fma_d_s1_signc_q <= 1'b0; fma_d_s1_rm_q <= 3'b0;
      fma_d_s2_special_q <= 1'b0; fma_d_s2_spval_q <= 64'b0; fma_d_s2_spff_q <= 5'b0;
      fma_d_s2_product_q <= 106'b0; fma_d_s2_sigc_q <= 53'b0;
      fma_d_s2_shiftp_q <= 0; fma_d_s2_shiftc_q <= 0; fma_d_s2_refw_q <= 0;
      fma_d_s2_signp_q <= 1'b0; fma_d_s2_signc_q <= 1'b0; fma_d_s2_rm_q <= 3'b0;
      fma_d_s3_special_q <= 1'b0; fma_d_s3_spval_q <= 64'b0; fma_d_s3_spff_q <= 5'b0;
      fma_d_s3_mag_q <= 128'b0; fma_d_s3_ressign_q <= 1'b0; fma_d_s3_refw_q <= 0;
      fma_d_s3_rm_q <= 3'b0;
      fma_d_s4_magn_q <= 128'b0; fma_d_s4_ebiased_q <= 0; fma_d_s4_iszero_q <= 1'b0;
      fma_d_s4_ressign_q <= 1'b0; fma_d_s4_rm_q <= 3'b0; fma_d_s4_special_q <= 1'b0;
      fma_d_s4_spval_q <= 64'b0; fma_d_s4_spff_q <= 5'b0;
      fma_d_value_q <= 64'b0; fma_d_fflags_q <= 5'b0;
      fma_s_s1_special_q <= 1'b0; fma_s_s1_spval_q <= 64'b0; fma_s_s1_spff_q <= 5'b0;
      fma_s_s1_product_q <= 48'b0; fma_s_s1_sigc_q <= 24'b0;
      fma_s_s1_ep_q <= 0; fma_s_s1_ec_q <= 0;
      fma_s_s1_signp_q <= 1'b0; fma_s_s1_signc_q <= 1'b0; fma_s_s1_rm_q <= 3'b0;
      fma_s_s2_special_q <= 1'b0; fma_s_s2_spval_q <= 64'b0; fma_s_s2_spff_q <= 5'b0;
      fma_s_s2_product_q <= 48'b0; fma_s_s2_sigc_q <= 24'b0;
      fma_s_s2_shiftp_q <= 0; fma_s_s2_shiftc_q <= 0; fma_s_s2_refw_q <= 0;
      fma_s_s2_signp_q <= 1'b0; fma_s_s2_signc_q <= 1'b0; fma_s_s2_rm_q <= 3'b0;
      fma_s_s3_special_q <= 1'b0; fma_s_s3_spval_q <= 64'b0; fma_s_s3_spff_q <= 5'b0;
      fma_s_s3_mag_q <= 128'b0; fma_s_s3_ressign_q <= 1'b0; fma_s_s3_refw_q <= 0;
      fma_s_s3_rm_q <= 3'b0;
      fma_s_s4_magn_q <= 128'b0; fma_s_s4_ebiased_q <= 0; fma_s_s4_iszero_q <= 1'b0;
      fma_s_s4_ressign_q <= 1'b0; fma_s_s4_rm_q <= 3'b0; fma_s_s4_special_q <= 1'b0;
      fma_s_s4_spval_q <= 64'b0; fma_s_s4_spff_q <= 5'b0;
      fma_s_value_q <= 64'b0; fma_s_fflags_q <= 5'b0;
    end else begin
      // ---- double FMA S1→S2→S3→S4 ----
      fma_d_s1_special_q <= fma_d_s1_special_c; fma_d_s1_spval_q <= fma_d_s1_spval_c;
      fma_d_s1_spff_q <= fma_d_s1_spff_c; fma_d_s1_product_q <= fma_d_s1_product_c;
      fma_d_s1_sigc_q <= fma_d_s1_sigc_c; fma_d_s1_ep_q <= fma_d_s1_ep_c;
      fma_d_s1_ec_q <= fma_d_s1_ec_c; fma_d_s1_signp_q <= fma_d_s1_signp_c;
      fma_d_s1_signc_q <= fma_d_s1_signc_c; fma_d_s1_rm_q <= fma_d_s1_rm_c;
      fma_d_s2_special_q <= fma_d_s1_special_q; fma_d_s2_spval_q <= fma_d_s1_spval_q;
      fma_d_s2_spff_q <= fma_d_s1_spff_q; fma_d_s2_product_q <= fma_d_s1_product_q;
      fma_d_s2_sigc_q <= fma_d_s1_sigc_q; fma_d_s2_shiftp_q <= fma_d_s2_shiftp_c;
      fma_d_s2_shiftc_q <= fma_d_s2_shiftc_c; fma_d_s2_refw_q <= fma_d_s2_refw_c;
      fma_d_s2_signp_q <= fma_d_s1_signp_q; fma_d_s2_signc_q <= fma_d_s1_signc_q;
      fma_d_s2_rm_q <= fma_d_s1_rm_q;
      fma_d_s3_special_q <= fma_d_s2_special_q; fma_d_s3_spval_q <= fma_d_s2_spval_q;
      fma_d_s3_spff_q <= fma_d_s2_spff_q; fma_d_s3_mag_q <= fma_d_s3_mag_c;
      fma_d_s3_ressign_q <= fma_d_s3_ressign_c; fma_d_s3_refw_q <= fma_d_s2_refw_q;
      fma_d_s3_rm_q <= fma_d_s2_rm_q;
      fma_d_s4_magn_q <= fma_d_s4_magn_c; fma_d_s4_ebiased_q <= fma_d_s4_ebiased_c;
      fma_d_s4_iszero_q <= fma_d_s4_iszero_c; fma_d_s4_ressign_q <= fma_d_s3_ressign_q;
      fma_d_s4_rm_q <= fma_d_s3_rm_q; fma_d_s4_special_q <= fma_d_s3_special_q;
      fma_d_s4_spval_q <= fma_d_s3_spval_q; fma_d_s4_spff_q <= fma_d_s3_spff_q;
      fma_d_value_q <= fma_d_s5_value_c; fma_d_fflags_q <= fma_d_s5_fflags_c;
      // ---- single FMA S1→S2→S3→S4→S5 ----
      fma_s_s1_special_q <= fma_s_s1_special_c; fma_s_s1_spval_q <= fma_s_s1_spval_c;
      fma_s_s1_spff_q <= fma_s_s1_spff_c; fma_s_s1_product_q <= fma_s_s1_product_c;
      fma_s_s1_sigc_q <= fma_s_s1_sigc_c; fma_s_s1_ep_q <= fma_s_s1_ep_c;
      fma_s_s1_ec_q <= fma_s_s1_ec_c; fma_s_s1_signp_q <= fma_s_s1_signp_c;
      fma_s_s1_signc_q <= fma_s_s1_signc_c; fma_s_s1_rm_q <= fma_s_s1_rm_c;
      fma_s_s2_special_q <= fma_s_s1_special_q; fma_s_s2_spval_q <= fma_s_s1_spval_q;
      fma_s_s2_spff_q <= fma_s_s1_spff_q; fma_s_s2_product_q <= fma_s_s1_product_q;
      fma_s_s2_sigc_q <= fma_s_s1_sigc_q; fma_s_s2_shiftp_q <= fma_s_s2_shiftp_c;
      fma_s_s2_shiftc_q <= fma_s_s2_shiftc_c; fma_s_s2_refw_q <= fma_s_s2_refw_c;
      fma_s_s2_signp_q <= fma_s_s1_signp_q; fma_s_s2_signc_q <= fma_s_s1_signc_q;
      fma_s_s2_rm_q <= fma_s_s1_rm_q;
      fma_s_s3_special_q <= fma_s_s2_special_q; fma_s_s3_spval_q <= fma_s_s2_spval_q;
      fma_s_s3_spff_q <= fma_s_s2_spff_q; fma_s_s3_mag_q <= fma_s_s3_mag_c;
      fma_s_s3_ressign_q <= fma_s_s3_ressign_c; fma_s_s3_refw_q <= fma_s_s2_refw_q;
      fma_s_s3_rm_q <= fma_s_s2_rm_q;
      fma_s_s4_magn_q <= fma_s_s4_magn_c; fma_s_s4_ebiased_q <= fma_s_s4_ebiased_c;
      fma_s_s4_iszero_q <= fma_s_s4_iszero_c; fma_s_s4_ressign_q <= fma_s_s3_ressign_q;
      fma_s_s4_rm_q <= fma_s_s3_rm_q; fma_s_s4_special_q <= fma_s_s3_special_q;
      fma_s_s4_spval_q <= fma_s_s3_spval_q; fma_s_s4_spff_q <= fma_s_s3_spff_q;
      fma_s_value_q <= fma_s_s5_value_c; fma_s_fflags_q <= fma_s_s5_fflags_c;
    end
  end

  // ===========================================================================
  // 统一多周期延迟 FP_ARITH_LATENCY=5(= FMA 流水深度,最深)。FADD 2 级、FMUL 3 级、
  // FMA 5 级;FP 串行 + 操作数全程稳定 → 各 op 流水输出在其自身深度即稳定并保持到第 5 拍
  // (done),故较浅的 FADD/FMUL 无需直通对齐,直接取其末级寄存器(done 拍仍有效)。
  // 输出端口由 double_i mux 选 double/single 末级寄存器。
  // ===========================================================================
  localparam integer FP_ARITH_LATENCY = 5;

  assign addsub_value_o  = double_i ? addsub_d_value_q  : addsub_s_value_q;
  assign addsub_fflags_o = double_i ? addsub_d_fflags_q : addsub_s_fflags_q;
  assign mul_value_o     = double_i ? mul_d_value_q     : mul_s_value_q;
  assign mul_fflags_o    = double_i ? mul_d_fflags_q    : mul_s_fflags_q;
  assign fma_value_o     = double_i ? fma_d_value_q     : fma_s_value_q;
  assign fma_fflags_o    = double_i ? fma_d_fflags_q    : fma_s_fflags_q;

  // done 计数器:start 拉高后逐拍计数,到 FP_ARITH_LATENCY 拍 done 拉高并保持;
  // start 落下(父模块已锁存 compute_done)清零;flush/rst 清零(squash 在飞 op)。
  reg [3:0] latency_cnt;
  always @(posedge clk) begin
    if (rst || flush_i || !start_i) latency_cnt <= 4'd0;
    else if (latency_cnt < FP_ARITH_LATENCY[3:0]) latency_cnt <= latency_cnt + 4'd1;
  end
  assign done_o = start_i && (latency_cnt == FP_ARITH_LATENCY[3:0]);

  // ===========================================================================
  // 【B-FP 簇·自流水控制】5 级 meta 链 + 浅 op 对齐链(spec §7)。
  // 数据通路每拍无条件推进(输入每拍采样进第一级), meta 链承载 op 身份;
  // FADD 结果在 stage2 末就绪 → 3 级对齐; FMUL stage3 末 → 2 级; FMA 恰第 5 拍。
  // 对齐链捕获拍 = op 位于该 stage 的拍末(下一 op 覆盖前), 用 meta 的 double 选 s/d。
  // kill: age 比 kill_rob_idx 年轻的 meta 清 valid(结果照常流出但 valid=0 不 wb)。
  // ===========================================================================
  reg meta_valid_q [1:5];
  reg [`OOO_ROB_INDEX_W-1:0] meta_rob_q [1:5];
  reg [`OOO_PHY_REG_ADDR_W-1:0] meta_pdest_q [1:5];
  reg meta_double_q [1:5];
  reg [1:0] meta_kind_q [1:5];

  function fp_meta_killed;
    input [`OOO_ROB_INDEX_W-1:0] idx;
    begin
      fp_meta_killed = kill_valid_i &&
          ((idx - rob_head_idx_i) > (kill_rob_idx_i - rob_head_idx_i));
    end
  endfunction

  // 对齐链: value+fflags(69b)
  reg [`XLEN-1:0] addsub_a1_value_q, addsub_a2_value_q;
  reg [4:0] addsub_a1_fflags_q, addsub_a2_fflags_q;
  reg [`XLEN-1:0] mul_a1_value_q, mul_a2_value_q;
  reg [4:0] mul_a1_fflags_q, mul_a2_fflags_q;

  integer mi;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      for (mi = 1; mi <= 5; mi = mi + 1) begin
        meta_valid_q[mi] <= 1'b0;
        meta_rob_q[mi] <= {`OOO_ROB_INDEX_W{1'b0}};
        meta_pdest_q[mi] <= {`OOO_PHY_REG_ADDR_W{1'b0}};
        meta_double_q[mi] <= 1'b0;
        meta_kind_q[mi] <= 2'b00;
      end
      addsub_a1_value_q <= {`XLEN{1'b0}}; addsub_a1_fflags_q <= 5'b0;
      addsub_a2_value_q <= {`XLEN{1'b0}}; addsub_a2_fflags_q <= 5'b0;
      mul_a1_value_q <= {`XLEN{1'b0}}; mul_a1_fflags_q <= 5'b0;
      mul_a2_value_q <= {`XLEN{1'b0}}; mul_a2_fflags_q <= 5'b0;
    end else begin
      meta_valid_q[1] <= launch_valid_i &&
                         !fp_meta_killed(launch_rob_idx_i);
      meta_rob_q[1] <= launch_rob_idx_i;
      meta_pdest_q[1] <= launch_pdest_i;
      meta_double_q[1] <= double_i;
      meta_kind_q[1] <= launch_kind_i;
      for (mi = 2; mi <= 5; mi = mi + 1) begin
        meta_valid_q[mi] <= meta_valid_q[mi-1] &&
                            !fp_meta_killed(meta_rob_q[mi-1]);
        meta_rob_q[mi] <= meta_rob_q[mi-1];
        meta_pdest_q[mi] <= meta_pdest_q[mi-1];
        meta_double_q[mi] <= meta_double_q[mi-1];
        meta_kind_q[mi] <= meta_kind_q[mi-1];
      end
      // kill 拍对链中存量再补一刀(上面的推进已带 kill gate, 这里覆盖"kill 拍不推进
      // 的场景不存在"——链恒推进, 推进 gate 已足够; 保留注释以说明语义)。

      // FADD 结果捕获: value_q 于 T+2 末写入, 最早 T+3 拍(op 在 meta[3])可读。
      addsub_a1_value_q <= meta_double_q[3] ? addsub_d_value_q
                                            : addsub_s_value_q;
      addsub_a1_fflags_q <= meta_double_q[3] ? addsub_d_fflags_q
                                             : addsub_s_fflags_q;
      addsub_a2_value_q <= addsub_a1_value_q;
      addsub_a2_fflags_q <= addsub_a1_fflags_q;
      // FMUL 结果 stage3 末捕获
      mul_a1_value_q <= meta_double_q[3] ? mul_d_value_q : mul_s_value_q;
      mul_a1_fflags_q <= meta_double_q[3] ? mul_d_fflags_q : mul_s_fflags_q;
      mul_a2_value_q <= mul_a1_value_q;
      mul_a2_fflags_q <= mul_a1_fflags_q;
    end
  end

  assign out_valid_o = meta_valid_q[5] && !fp_meta_killed(meta_rob_q[5]);
  assign out_rob_idx_o = meta_rob_q[5];
  assign out_pdest_o = meta_pdest_q[5];
  assign out_value_o =
      (meta_kind_q[5] == 2'd2) ? (meta_double_q[5] ? fma_d_value_q
                                                   : fma_s_value_q) :
      (meta_kind_q[5] == 2'd1) ? mul_a2_value_q :
                                 addsub_a2_value_q;
  assign out_fflags_o =
      (meta_kind_q[5] == 2'd2) ? (meta_double_q[5] ? fma_d_fflags_q
                                                   : fma_s_fflags_q) :
      (meta_kind_q[5] == 2'd1) ? mul_a2_fflags_q :
                                 addsub_a2_fflags_q;


endmodule
