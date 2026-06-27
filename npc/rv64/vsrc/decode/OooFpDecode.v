`include "define.v"

module OooFpDecode (
  input decode_valid_i,
  input [`INST_W-1:0] inst_i,
  output fp_load_o,
  output fp_store_o,
  output fp_move_to_fpr_o,
  output fp_move_to_gpr_o,
  output fp_class_o,
  output fp_sgnj_o,
  output fp_addsub_o,
  output fp_mul_o,
  output fp_fma_o,
  output fp_div_o,
  output fp_sqrt_o,
  output fp_minmax_o,
  output fp_compare_o,
  output fp_convert_to_fpr_o,
  output fp_convert_to_gpr_o,
  output fp_o,
  output fp_double_o,
  output fp_gpr_write_o
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
  localparam [6:0] FP_FUNCT7_FMV_X      = 7'b1111000;
  localparam [6:0] FP_FUNCT7_FMV_D_X    = 7'b1111001;
  localparam [6:0] FP_FUNCT7_FMV_X_W    = 7'b1110000;
  localparam [6:0] FP_FUNCT7_FMV_X_D    = 7'b1110001;

  wire op_fp_w = (inst_i[6:0] == `OPCODE_OP_FP);
  wire op_fma_w =
      (inst_i[6:0] == `OPCODE_MADD) ||
      (inst_i[6:0] == `OPCODE_MSUB) ||
      (inst_i[6:0] == `OPCODE_NMSUB) ||
      (inst_i[6:0] == `OPCODE_NMADD);
  wire fp_rounding_arith_w =
      (inst_i[14:12] <= 3'b100) || (inst_i[14:12] == 3'b111);
  wire fp_fma_fmt_w =
      (inst_i[26:25] == 2'b00) || (inst_i[26:25] == 2'b01);
  wire fp_cmp_funct3_w =
      (inst_i[14:12] == 3'b000) ||
      (inst_i[14:12] == 3'b001) ||
      (inst_i[14:12] == 3'b010);

  assign fp_load_o =
      decode_valid_i &&
      (inst_i[6:0] == `OPCODE_LOAD_FP) &&
      ((inst_i[14:12] == `FUNCT3_LW) ||
       (inst_i[14:12] == `FUNCT3_LD));
  assign fp_store_o =
      decode_valid_i &&
      (inst_i[6:0] == `OPCODE_STORE_FP) &&
      ((inst_i[14:12] == `FUNCT3_SW) ||
       (inst_i[14:12] == `FUNCT3_SD));
  assign fp_move_to_fpr_o =
      decode_valid_i && op_fp_w &&
      (inst_i[14:12] == 3'b000) &&
      (inst_i[24:20] == 5'b00000) &&
      ((inst_i[31:25] == FP_FUNCT7_FMV_X) ||
       (inst_i[31:25] == FP_FUNCT7_FMV_D_X));
  assign fp_move_to_gpr_o =
      decode_valid_i && op_fp_w &&
      (inst_i[14:12] == 3'b000) &&
      (inst_i[24:20] == 5'b00000) &&
      ((inst_i[31:25] == FP_FUNCT7_FMV_X_W) ||
       (inst_i[31:25] == FP_FUNCT7_FMV_X_D));
  assign fp_class_o =
      decode_valid_i && op_fp_w &&
      (inst_i[14:12] == 3'b001) &&
      (inst_i[24:20] == 5'b00000) &&
      ((inst_i[31:25] == FP_FUNCT7_FMV_X_W) ||
       (inst_i[31:25] == FP_FUNCT7_FMV_X_D));
  assign fp_sgnj_o =
      decode_valid_i && op_fp_w && fp_cmp_funct3_w &&
      ((inst_i[31:25] == FP_FUNCT7_FSGNJ_S) ||
       (inst_i[31:25] == FP_FUNCT7_FSGNJ_D));
  assign fp_addsub_o =
      decode_valid_i && op_fp_w && fp_rounding_arith_w &&
      ((inst_i[31:25] == FP_FUNCT7_FADD_S) ||
       (inst_i[31:25] == FP_FUNCT7_FADD_D) ||
       (inst_i[31:25] == FP_FUNCT7_FSUB_S) ||
       (inst_i[31:25] == FP_FUNCT7_FSUB_D));
  assign fp_mul_o =
      decode_valid_i && op_fp_w && fp_rounding_arith_w &&
      ((inst_i[31:25] == FP_FUNCT7_FMUL_S) ||
       (inst_i[31:25] == FP_FUNCT7_FMUL_D));
  assign fp_fma_o =
      decode_valid_i && op_fma_w && fp_rounding_arith_w &&
      fp_fma_fmt_w;
  assign fp_div_o =
      decode_valid_i && op_fp_w && fp_rounding_arith_w &&
      ((inst_i[31:25] == FP_FUNCT7_FDIV_S) ||
       (inst_i[31:25] == FP_FUNCT7_FDIV_D));
  assign fp_sqrt_o =
      decode_valid_i && op_fp_w &&
      (inst_i[24:20] == 5'b00000) &&
      fp_rounding_arith_w &&
      ((inst_i[31:25] == FP_FUNCT7_FSQRT_S) ||
       (inst_i[31:25] == FP_FUNCT7_FSQRT_D));
  assign fp_minmax_o =
      decode_valid_i && op_fp_w &&
      ((inst_i[14:12] == 3'b000) ||
       (inst_i[14:12] == 3'b001)) &&
      ((inst_i[31:25] == FP_FUNCT7_FMINMAX_S) ||
       (inst_i[31:25] == FP_FUNCT7_FMINMAX_D));
  assign fp_compare_o =
      decode_valid_i && op_fp_w && fp_cmp_funct3_w &&
      ((inst_i[31:25] == FP_FUNCT7_FCMP_S) ||
       (inst_i[31:25] == FP_FUNCT7_FCMP_D));
  assign fp_convert_to_fpr_o =
      decode_valid_i && op_fp_w && fp_rounding_arith_w &&
      (((inst_i[31:25] == FP_FUNCT7_FCVT_INT_S) ||
        (inst_i[31:25] == FP_FUNCT7_FCVT_INT_D)) &&
       (inst_i[24:22] == 3'b000) ||
       ((inst_i[31:25] == FP_FUNCT7_FCVT_S_D) &&
        (inst_i[24:20] == 5'b00001)) ||
       ((inst_i[31:25] == FP_FUNCT7_FCVT_D_S) &&
        (inst_i[24:20] == 5'b00000)));
  assign fp_convert_to_gpr_o =
      decode_valid_i && op_fp_w && fp_rounding_arith_w &&
      ((inst_i[31:25] == FP_FUNCT7_FCVT_S_INT) ||
       (inst_i[31:25] == FP_FUNCT7_FCVT_D_INT)) &&
      (inst_i[24:22] == 3'b000);

  assign fp_o = fp_load_o || fp_store_o ||
                fp_move_to_fpr_o || fp_move_to_gpr_o || fp_class_o ||
                fp_sgnj_o || fp_addsub_o || fp_mul_o || fp_fma_o || fp_div_o ||
                fp_sqrt_o || fp_minmax_o || fp_compare_o ||
                fp_convert_to_fpr_o || fp_convert_to_gpr_o;
  assign fp_double_o =
      (inst_i[14:12] == `FUNCT3_LD) ||
      (inst_i[14:12] == `FUNCT3_SD) ||
      (op_fma_w && (inst_i[26:25] == 2'b01)) ||
      (inst_i[31:25] == FP_FUNCT7_FMV_X_D) ||
      (inst_i[31:25] == FP_FUNCT7_FMV_D_X) ||
      (inst_i[31:25] == FP_FUNCT7_FSGNJ_D) ||
      (inst_i[31:25] == FP_FUNCT7_FADD_D) ||
      (inst_i[31:25] == FP_FUNCT7_FSUB_D) ||
      (inst_i[31:25] == FP_FUNCT7_FMUL_D) ||
      (inst_i[31:25] == FP_FUNCT7_FDIV_D) ||
      (inst_i[31:25] == FP_FUNCT7_FSQRT_D) ||
      (inst_i[31:25] == FP_FUNCT7_FMINMAX_D) ||
      (inst_i[31:25] == FP_FUNCT7_FCMP_D) ||
      (inst_i[31:25] == FP_FUNCT7_FCVT_D_S) ||
      (inst_i[31:25] == FP_FUNCT7_FCVT_D_INT) ||
      (inst_i[31:25] == FP_FUNCT7_FCVT_INT_D);
  assign fp_gpr_write_o =
      fp_move_to_gpr_o || fp_class_o || fp_compare_o ||
      fp_convert_to_gpr_o;

endmodule
