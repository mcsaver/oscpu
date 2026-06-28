`include "define.v"

// FP pending 执行数据通路：父模块仍持有 pending/FPR/commit 时序，
// 本模块只负责组合结果、fflags 和 FDIV/FSQRT 迭代单元包装。
module OooFpPendingExec (
  input clk,
  input rst,
  input flush_i,
  input pending_valid_i,
  input [`INST_W-1:0] inst_i,
  input load_i,
  input store_i,
  input double_i,
  input gpr_write_i,
  input [`XLEN-1:0] int_rs1_value_i,
  input [`XLEN-1:0] frs1_value_i,
  input [`XLEN-1:0] frs2_value_i,
  input [`XLEN-1:0] frs3_value_i,
  input long_start_i,

  output long_op_o,
  output compute_op_o,
  output div_busy_o,
  output sqrt_busy_o,
  output long_done_o,
  output [`XLEN-1:0] long_done_result_o,
  output [4:0] long_done_fflags_o,
  output [`XLEN-1:0] mem_addr_o,
  output [`XLEN-1:0] mem_aligned_addr_o,
  output [`XLEN-1:0] mem_wdata_o,
  output [`STRB_W-1:0] mem_wstrb_o,
  output [`XLEN-1:0] compute_value_o,
  output [4:0] compute_fflags_o
);

  localparam [6:0] FP_FUNCT7_FADD_S     = 7'b0000000;
  localparam [6:0] FP_FUNCT7_FADD_D     = 7'b0000001;
  localparam [6:0] FP_FUNCT7_FSUB_S     = 7'b0000100;
  localparam [6:0] FP_FUNCT7_FSUB_D     = 7'b0000101;
  localparam [6:0] FP_FUNCT7_FMUL_S     = 7'b0001000;
  localparam [6:0] FP_FUNCT7_FMUL_D     = 7'b0001001;
  localparam [6:0] FP_FUNCT7_FDIV_S     = 7'b0001100;
  localparam [6:0] FP_FUNCT7_FDIV_D     = 7'b0001101;
  localparam [6:0] FP_FUNCT7_FSQRT_S    = 7'b0101100;
  localparam [6:0] FP_FUNCT7_FSQRT_D    = 7'b0101101;
  localparam [6:0] FP_FUNCT7_FSGNJ_S    = 7'b0010000;
  localparam [6:0] FP_FUNCT7_FSGNJ_D    = 7'b0010001;
  localparam [6:0] FP_FUNCT7_FMINMAX_S  = 7'b0010100;
  localparam [6:0] FP_FUNCT7_FMINMAX_D  = 7'b0010101;
  localparam [6:0] FP_FUNCT7_FCVT_S_D   = 7'b0100000;
  localparam [6:0] FP_FUNCT7_FCVT_D_S   = 7'b0100001;
  localparam [6:0] FP_FUNCT7_FCMP_S     = 7'b1010000;
  localparam [6:0] FP_FUNCT7_FCMP_D     = 7'b1010001;
  localparam [6:0] FP_FUNCT7_FCVT_INT_S = 7'b1101000;
  localparam [6:0] FP_FUNCT7_FCVT_INT_D = 7'b1101001;
  localparam [6:0] FP_FUNCT7_FCVT_S_INT = 7'b1100000;
  localparam [6:0] FP_FUNCT7_FCVT_D_INT = 7'b1100001;
  localparam [6:0] FP_FUNCT7_FMV_X_W    = 7'b1110000;
  localparam [6:0] FP_FUNCT7_FMV_X_D    = 7'b1110001;
  // FP fflags 标志常量由 include/define.v 的 `FP_FLAG_* 宏统一管理；
  // NaN/inf/zero 谓词与舍入/规格化 helper 在下列共享头，FP owner 与本父模块共用。
  `include "execute/OooFpPredicates.v"
  `include "execute/OooFpRound.v"

  // FP 访存操作数形成（地址/对齐地址/store 写数据/写掩码）已抽到
  // execute/OooFpMemAccessGate.v，见下方 u_fp_mem_access_gate 实例。

  function [`XLEN-1:0] fp_move_to_gpr_value;
    input [`XLEN-1:0] value;
    input is_double;
    begin
      fp_move_to_gpr_value = is_double ? value :
                             {{32{value[31]}}, value[31:0]};
    end
  endfunction

  // FP 分类（FCLASS.S/D）已抽到 execute/OooFpClassifyGate.v，
  // 见下方 u_fp_classify_gate 实例。

  // FP 符号注入（FSGNJ/N/X）已抽到 execute/OooFpSgnjGate.v，
  // 见下方 u_fp_sgnj_gate 实例。

  // FP 比较/最值（FEQ/FLT/FLE、FMIN/FMAX）的 value/fflags 已抽到
  // execute/OooFpCompareGate.v，见下方 u_fp_compare_gate 实例。

  wire pending_fp_q = pending_valid_i;
  wire [`INST_W-1:0] pending_fp_inst_q = inst_i;
  wire pending_fp_load_q = load_i;
  wire pending_fp_store_q = store_i;
  wire pending_fp_double_q = double_i;
  wire pending_fp_gpr_write_q = gpr_write_i;
  wire pending_fp_op_fp_w = pending_fp_inst_q[6:0] == `OPCODE_OP_FP;
  wire [`XLEN-1:0] pending_fp_int_rs1_value_w = int_rs1_value_i;
  // FP 访存操作数形成下沉到 OooFpMemAccessGate（纯组合）。
  wire [`XLEN-1:0] pending_fp_mem_addr_w;
  wire [`XLEN-1:0] pending_fp_mem_aligned_addr_w;
  wire [`XLEN-1:0] pending_fp_mem_wdata_w;
  wire [`STRB_W-1:0] pending_fp_mem_wstrb_w;
  OooFpMemAccessGate u_fp_mem_access_gate (
    .inst_i(pending_fp_inst_q),
    .int_rs1_value_i(pending_fp_int_rs1_value_w),
    .frs2_value_i(frs2_value_i),
    .load_i(pending_fp_load_q),
    .double_i(pending_fp_double_q),
    .mem_addr_o(pending_fp_mem_addr_w),
    .mem_aligned_addr_o(pending_fp_mem_aligned_addr_w),
    .mem_wdata_o(pending_fp_mem_wdata_w),
    .mem_wstrb_o(pending_fp_mem_wstrb_w)
  );
  wire [`XLEN-1:0] pending_fp_move_to_fpr_value_w =
      pending_fp_double_q ? pending_fp_int_rs1_value_w :
      {32'hffff_ffff, pending_fp_int_rs1_value_w[31:0]};
  wire [`XLEN-1:0] pending_fp_frs1_value_w = frs1_value_i;
  wire [`XLEN-1:0] pending_fp_frs2_value_w = frs2_value_i;
  wire [`XLEN-1:0] pending_fp_frs3_value_w = frs3_value_i;
  wire pending_fp_class_w =
      pending_fp_op_fp_w && pending_fp_gpr_write_q &&
      (pending_fp_inst_q[14:12] == 3'b001) &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FMV_X_W) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FMV_X_D));
  wire pending_fp_compare_w =
      pending_fp_op_fp_w && pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FCMP_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FCMP_D));
  wire pending_fp_sgnj_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FSGNJ_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSGNJ_D));
  wire pending_fp_addsub_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FADD_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FADD_D) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSUB_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSUB_D));
  wire pending_fp_mul_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FMUL_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FMUL_D));
  wire pending_fp_fma_w =
      !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[6:0] == `OPCODE_MADD) ||
       (pending_fp_inst_q[6:0] == `OPCODE_MSUB) ||
       (pending_fp_inst_q[6:0] == `OPCODE_NMSUB) ||
       (pending_fp_inst_q[6:0] == `OPCODE_NMADD));
  wire pending_fp_div_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FDIV_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FDIV_D));
  wire pending_fp_sqrt_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FSQRT_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSQRT_D));
  wire pending_fp_minmax_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FMINMAX_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FMINMAX_D));
  wire pending_fp_convert_to_gpr_w =
      pending_fp_op_fp_w && pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_S_INT) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_D_INT));
  wire pending_fp_int_to_fpr_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_INT_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_INT_D));
  wire pending_fp_fpr_to_fpr_w =
      pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      (((pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_S_D) &&
        (pending_fp_inst_q[24:20] == 5'b00001)) ||
       ((pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_D_S) &&
        (pending_fp_inst_q[24:20] == 5'b00000)));
  wire pending_fp_convert_to_fpr_w =
      pending_fp_int_to_fpr_w || pending_fp_fpr_to_fpr_w;

  wire pending_fp_long_op_w =
      pending_fp_q && pending_fp_op_fp_w && !pending_fp_gpr_write_q &&
      ((pending_fp_inst_q[31:25] == FP_FUNCT7_FDIV_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FDIV_D) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSQRT_S) ||
       (pending_fp_inst_q[31:25] == FP_FUNCT7_FSQRT_D));
  wire pending_fp_compute_op_w =
      pending_fp_q && !pending_fp_load_q && !pending_fp_store_q &&
      !pending_fp_long_op_w;
  // FP 长延迟运算（FDIV/FSQRT，含迭代器）已抽到 execute/OooFpLongOpGate.v。
  wire pending_fp_div_busy_w;
  wire pending_fp_sqrt_busy_w;
  wire pending_fp_long_done_w;
  wire [`XLEN-1:0] pending_fp_long_done_result_w;
  wire [4:0] pending_fp_long_done_fflags_w;
  OooFpLongOpGate u_fp_long_op_gate (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .frs1_value_i(pending_fp_frs1_value_w),
    .frs2_value_i(pending_fp_frs2_value_w),
    .double_i(pending_fp_double_q),
    .rm_i(pending_fp_inst_q[14:12]),
    .long_start_i(long_start_i),
    .is_div_i(pending_fp_div_w),
    .is_sqrt_i(pending_fp_sqrt_w),
    .div_busy_o(pending_fp_div_busy_w),
    .sqrt_busy_o(pending_fp_sqrt_busy_w),
    .long_done_o(pending_fp_long_done_w),
    .long_done_result_o(pending_fp_long_done_result_w),
    .long_done_fflags_o(pending_fp_long_done_fflags_w)
  );

  wire pending_fp_convert_src_double_w =
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_D_INT) ||
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_S_D);
  wire pending_fp_convert_dst_double_w =
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_INT_D) ||
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FCVT_D_S);
  // FP convert value/fflags 已抽到 execute/OooFpConvertGate.v。
  wire [`XLEN-1:0] pending_fp_convert_to_gpr_value_w;
  wire [4:0] pending_fp_convert_to_gpr_fflags_w;
  wire [`XLEN-1:0] pending_fp_convert_to_fpr_value_w;
  wire [4:0] pending_fp_convert_to_fpr_fflags_w;
  OooFpConvertGate u_fp_convert_gate (
    .frs1_value_i(pending_fp_frs1_value_w),
    .int_rs1_value_i(pending_fp_int_rs1_value_w),
    .src_double_i(pending_fp_convert_src_double_w),
    .dst_double_i(pending_fp_convert_dst_double_w),
    .fpr_to_fpr_i(pending_fp_fpr_to_fpr_w),
    .int_fmt_i(pending_fp_inst_q[21:20]),
    .rm_i(pending_fp_inst_q[14:12]),
    .to_gpr_value_o(pending_fp_convert_to_gpr_value_w),
    .to_gpr_fflags_o(pending_fp_convert_to_gpr_fflags_w),
    .to_fpr_value_o(pending_fp_convert_to_fpr_value_w),
    .to_fpr_fflags_o(pending_fp_convert_to_fpr_fflags_w)
  );
  wire [`XLEN-1:0] pending_fp_compare_value_w;
  wire [4:0] pending_fp_compare_fflags_w;
  wire [`XLEN-1:0] pending_fp_minmax_value_w;
  wire [4:0] pending_fp_minmax_fflags_w;
  OooFpCompareGate u_fp_compare_gate (
    .frs1_value_i(pending_fp_frs1_value_w),
    .frs2_value_i(pending_fp_frs2_value_w),
    .double_i(pending_fp_double_q),
    .cmp_op_i(pending_fp_inst_q[14:12]),
    .is_max_i(pending_fp_inst_q[12]),
    .compare_value_o(pending_fp_compare_value_w),
    .compare_fflags_o(pending_fp_compare_fflags_w),
    .minmax_value_o(pending_fp_minmax_value_w),
    .minmax_fflags_o(pending_fp_minmax_fflags_w)
  );
  wire [`XLEN-1:0] pending_fp_sgnj_value_w;
  OooFpSgnjGate u_fp_sgnj_gate (
    .frs1_value_i(pending_fp_frs1_value_w),
    .frs2_value_i(pending_fp_frs2_value_w),
    .double_i(pending_fp_double_q),
    .op_i(pending_fp_inst_q[14:12]),
    .sgnj_value_o(pending_fp_sgnj_value_w)
  );
  wire pending_fp_sub_op_w =
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FSUB_S) ||
      (pending_fp_inst_q[31:25] == FP_FUNCT7_FSUB_D);
  wire pending_fp_negate_product_w =
      (pending_fp_inst_q[6:0] == `OPCODE_NMSUB) ||
      (pending_fp_inst_q[6:0] == `OPCODE_NMADD);
  wire pending_fp_subtract_addend_w =
      (pending_fp_inst_q[6:0] == `OPCODE_MSUB) ||
      (pending_fp_inst_q[6:0] == `OPCODE_NMADD);
  // FP 加减/乘/乘加 value+fflags 已抽到 execute/OooFpArithGate.v。
  wire [`XLEN-1:0] pending_fp_addsub_value_w;
  wire [4:0] pending_fp_addsub_fflags_w;
  wire [`XLEN-1:0] pending_fp_mul_value_w;
  wire [4:0] pending_fp_mul_fflags_w;
  wire [`XLEN-1:0] pending_fp_fma_value_w;
  wire [4:0] pending_fp_fma_fflags_w;
  OooFpArithGate u_fp_arith_gate (
    .frs1_value_i(pending_fp_frs1_value_w),
    .frs2_value_i(pending_fp_frs2_value_w),
    .frs3_value_i(pending_fp_frs3_value_w),
    .double_i(pending_fp_double_q),
    .sub_op_i(pending_fp_sub_op_w),
    .negate_product_i(pending_fp_negate_product_w),
    .subtract_addend_i(pending_fp_subtract_addend_w),
    .rm_i(pending_fp_inst_q[14:12]),
    .addsub_value_o(pending_fp_addsub_value_w),
    .addsub_fflags_o(pending_fp_addsub_fflags_w),
    .mul_value_o(pending_fp_mul_value_w),
    .mul_fflags_o(pending_fp_mul_fflags_w),
    .fma_value_o(pending_fp_fma_value_w),
    .fma_fflags_o(pending_fp_fma_fflags_w)
  );
  // pending_fp_long_done_w / _result_w / _fflags_w、div/sqrt busy 由 u_fp_long_op_gate 驱动（见上）。
  // pending_fp_minmax_value_w / _fflags_w 由 u_fp_compare_gate 驱动（见上）。
  // pending_fp_addsub/mul/fma_fflags_w 由 u_fp_arith_gate 驱动（见上）。
  // pending_fp_convert_to_gpr/fpr_fflags_w 由 u_fp_convert_gate 驱动（见上）。
  wire [4:0] pending_fp_gpr_fflags_w =
      pending_fp_compare_w ? pending_fp_compare_fflags_w :
      pending_fp_convert_to_gpr_w ? pending_fp_convert_to_gpr_fflags_w :
                                    5'b00000;
  wire [4:0] pending_fp_compute_fflags_w =
      pending_fp_gpr_write_q ? pending_fp_gpr_fflags_w :
      pending_fp_convert_to_fpr_w ? pending_fp_convert_to_fpr_fflags_w :
      pending_fp_addsub_w ? pending_fp_addsub_fflags_w :
      pending_fp_mul_w ? pending_fp_mul_fflags_w :
      pending_fp_fma_w ? pending_fp_fma_fflags_w :
      pending_fp_minmax_w ? pending_fp_minmax_fflags_w :
                            5'b00000;
  wire [`XLEN-1:0] pending_fp_class_value_w;
  OooFpClassifyGate u_fp_classify_gate (
    .frs1_value_i(pending_fp_frs1_value_w),
    .double_i(pending_fp_double_q),
    .class_value_o(pending_fp_class_value_w)
  );
  wire [`XLEN-1:0] pending_fp_gpr_value_w =
      pending_fp_class_w ? pending_fp_class_value_w :
      pending_fp_compare_w ? pending_fp_compare_value_w :
      pending_fp_convert_to_gpr_w ? pending_fp_convert_to_gpr_value_w :
      fp_move_to_gpr_value(pending_fp_frs1_value_w, pending_fp_double_q);
  wire [`XLEN-1:0] pending_fp_compute_value_w =
      pending_fp_gpr_write_q ? pending_fp_gpr_value_w :
      pending_fp_convert_to_fpr_w ? pending_fp_convert_to_fpr_value_w :
      pending_fp_sgnj_w ? pending_fp_sgnj_value_w :
      pending_fp_addsub_w ? pending_fp_addsub_value_w :
      pending_fp_mul_w ? pending_fp_mul_value_w :
      pending_fp_fma_w ? pending_fp_fma_value_w :
      pending_fp_minmax_w ? pending_fp_minmax_value_w :
                               pending_fp_move_to_fpr_value_w;

  assign long_op_o = pending_fp_long_op_w;
  assign compute_op_o = pending_fp_compute_op_w;
  assign div_busy_o = pending_fp_div_busy_w;
  assign sqrt_busy_o = pending_fp_sqrt_busy_w;
  assign long_done_o = pending_fp_long_done_w;
  assign long_done_result_o = pending_fp_long_done_result_w;
  assign long_done_fflags_o = pending_fp_long_done_fflags_w;
  assign mem_addr_o = pending_fp_mem_addr_w;
  assign mem_aligned_addr_o = pending_fp_mem_aligned_addr_w;
  assign mem_wdata_o = pending_fp_mem_wdata_w;
  assign mem_wstrb_o = pending_fp_mem_wstrb_w;
  assign compute_value_o = pending_fp_compute_value_w;
  assign compute_fflags_o = pending_fp_compute_fflags_w;

endmodule
