#ifndef __NEMU_ISA_RISCV_FLOATING_H__
#define __NEMU_ISA_RISCV_FLOATING_H__

#include <stdbool.h>
#include <stdint.h>

/*
 * fflags[4:0], in the architectural order defined by the F extension.
 * SoftFloat's RISC-V specialization deliberately uses the same bit layout.
 */
#define RISCV_FFLAGS_NX UINT32_C(0x01)
#define RISCV_FFLAGS_UF UINT32_C(0x02)
#define RISCV_FFLAGS_OF UINT32_C(0x04)
#define RISCV_FFLAGS_DZ UINT32_C(0x08)
#define RISCV_FFLAGS_NV UINT32_C(0x10)

/*
 * F/D instruction descriptor.  Decode owns every opcode/funct/fmt selector;
 * execute sees only the mnemonic and architectural operands below.
 */
typedef enum {
  RISCV_FLOAT_OPERATION_ILLEGAL = 0,
  RISCV_FLOAT_OPERATION_FLW,
  RISCV_FLOAT_OPERATION_FLD,
  RISCV_FLOAT_OPERATION_FSW,
  RISCV_FLOAT_OPERATION_FSD,
  RISCV_FLOAT_OPERATION_FMADD_S,
  RISCV_FLOAT_OPERATION_FMADD_D,
  RISCV_FLOAT_OPERATION_FMSUB_S,
  RISCV_FLOAT_OPERATION_FMSUB_D,
  RISCV_FLOAT_OPERATION_FNMSUB_S,
  RISCV_FLOAT_OPERATION_FNMSUB_D,
  RISCV_FLOAT_OPERATION_FNMADD_S,
  RISCV_FLOAT_OPERATION_FNMADD_D,
  RISCV_FLOAT_OPERATION_FADD_S,
  RISCV_FLOAT_OPERATION_FADD_D,
  RISCV_FLOAT_OPERATION_FSUB_S,
  RISCV_FLOAT_OPERATION_FSUB_D,
  RISCV_FLOAT_OPERATION_FMUL_S,
  RISCV_FLOAT_OPERATION_FMUL_D,
  RISCV_FLOAT_OPERATION_FDIV_S,
  RISCV_FLOAT_OPERATION_FDIV_D,
  RISCV_FLOAT_OPERATION_FSQRT_S,
  RISCV_FLOAT_OPERATION_FSQRT_D,
  RISCV_FLOAT_OPERATION_FSGNJ_S,
  RISCV_FLOAT_OPERATION_FSGNJN_S,
  RISCV_FLOAT_OPERATION_FSGNJX_S,
  RISCV_FLOAT_OPERATION_FSGNJ_D,
  RISCV_FLOAT_OPERATION_FSGNJN_D,
  RISCV_FLOAT_OPERATION_FSGNJX_D,
  RISCV_FLOAT_OPERATION_FMIN_S,
  RISCV_FLOAT_OPERATION_FMAX_S,
  RISCV_FLOAT_OPERATION_FMIN_D,
  RISCV_FLOAT_OPERATION_FMAX_D,
  RISCV_FLOAT_OPERATION_FCVT_S_D,
  RISCV_FLOAT_OPERATION_FCVT_D_S,
  RISCV_FLOAT_OPERATION_FLE_S,
  RISCV_FLOAT_OPERATION_FLT_S,
  RISCV_FLOAT_OPERATION_FEQ_S,
  RISCV_FLOAT_OPERATION_FLE_D,
  RISCV_FLOAT_OPERATION_FLT_D,
  RISCV_FLOAT_OPERATION_FEQ_D,
  RISCV_FLOAT_OPERATION_FCVT_W_S,
  RISCV_FLOAT_OPERATION_FCVT_WU_S,
  RISCV_FLOAT_OPERATION_FCVT_L_S,
  RISCV_FLOAT_OPERATION_FCVT_LU_S,
  RISCV_FLOAT_OPERATION_FCVT_W_D,
  RISCV_FLOAT_OPERATION_FCVT_WU_D,
  RISCV_FLOAT_OPERATION_FCVT_L_D,
  RISCV_FLOAT_OPERATION_FCVT_LU_D,
  RISCV_FLOAT_OPERATION_FCVT_S_W,
  RISCV_FLOAT_OPERATION_FCVT_S_WU,
  RISCV_FLOAT_OPERATION_FCVT_S_L,
  RISCV_FLOAT_OPERATION_FCVT_S_LU,
  RISCV_FLOAT_OPERATION_FCVT_D_W,
  RISCV_FLOAT_OPERATION_FCVT_D_WU,
  RISCV_FLOAT_OPERATION_FCVT_D_L,
  RISCV_FLOAT_OPERATION_FCVT_D_LU,
  RISCV_FLOAT_OPERATION_FMV_X_W,
  RISCV_FLOAT_OPERATION_FCLASS_S,
  RISCV_FLOAT_OPERATION_FMV_W_X,
  RISCV_FLOAT_OPERATION_FMV_X_D,
  RISCV_FLOAT_OPERATION_FCLASS_D,
  RISCV_FLOAT_OPERATION_FMV_D_X,
} RiscvFloatingOperation;

typedef enum {
  RISCV_FLOAT_REGISTER_NONE = 0,
  RISCV_FLOAT_REGISTER_X,
  RISCV_FLOAT_REGISTER_F,
} RiscvFloatingRegisterFile;

typedef struct {
  uint32_t encoding;
  RiscvFloatingOperation operation;
  int64_t immediate;
  uint8_t rd;
  uint8_t rs1;
  uint8_t rs2;
  uint8_t rs3;
  uint8_t rounding_mode;
  RiscvFloatingRegisterFile rd_file;
  RiscvFloatingRegisterFile rs1_file;
  RiscvFloatingRegisterFile rs2_file;
  RiscvFloatingRegisterFile rs3_file;
} RiscvFloatingInstruction;

static inline uint32_t riscv_fp_bits(
    uint32_t encoding, unsigned high, unsigned low) {
  const uint32_t width = high - low + 1;
  return (encoding >> low) & ((UINT32_C(1) << width) - 1);
}

static inline int64_t riscv_fp_sign_extend(uint32_t value, unsigned width) {
  const uint32_t sign = UINT32_C(1) << (width - 1);
  return (int64_t)((int32_t)((value ^ sign) - sign));
}

static inline RiscvFloatingInstruction riscv_fp_instruction(
    uint32_t encoding) {
  return (RiscvFloatingInstruction) {
    .encoding = encoding,
    .operation = RISCV_FLOAT_OPERATION_ILLEGAL,
    .immediate = 0,
    .rd = riscv_fp_bits(encoding, 11, 7),
    .rs1 = riscv_fp_bits(encoding, 19, 15),
    .rs2 = riscv_fp_bits(encoding, 24, 20),
    .rs3 = riscv_fp_bits(encoding, 31, 27),
    .rounding_mode = riscv_fp_bits(encoding, 14, 12),
    .rd_file = RISCV_FLOAT_REGISTER_NONE,
    .rs1_file = RISCV_FLOAT_REGISTER_NONE,
    .rs2_file = RISCV_FLOAT_REGISTER_NONE,
    .rs3_file = RISCV_FLOAT_REGISTER_NONE,
  };
}

static inline bool riscv_fp_assign(
    RiscvFloatingInstruction *instruction,
    RiscvFloatingOperation operation,
    RiscvFloatingRegisterFile rd_file,
    RiscvFloatingRegisterFile rs1_file,
    RiscvFloatingRegisterFile rs2_file,
    RiscvFloatingRegisterFile rs3_file) {
  instruction->operation = operation;
  instruction->rd_file = rd_file;
  instruction->rs1_file = rs1_file;
  instruction->rs2_file = rs2_file;
  instruction->rs3_file = rs3_file;
  return true;
}

static inline bool riscv_fp_assign_binary_f(
    RiscvFloatingInstruction *instruction,
    RiscvFloatingOperation operation) {
  return riscv_fp_assign(
      instruction, operation,
      RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_F,
      RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_NONE);
}

static inline bool riscv_fp_assign_unary_f(
    RiscvFloatingInstruction *instruction,
    RiscvFloatingOperation operation) {
  return riscv_fp_assign(
      instruction, operation,
      RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_F,
      RISCV_FLOAT_REGISTER_NONE, RISCV_FLOAT_REGISTER_NONE);
}

static inline bool riscv_fp_rounding_field_is_valid(uint8_t rm) {
  return rm <= 4 || rm == 7;
}

static inline bool riscv_fp_decode_memory(
    uint32_t opcode, uint32_t funct3, bool has_f, bool has_d,
    RiscvFloatingInstruction *instruction) {
  const bool load = opcode == UINT32_C(0x07);
  RiscvFloatingOperation operation;
  switch (funct3) {
    case 0x2:
      if (!has_f) return false;
      operation = load
          ? RISCV_FLOAT_OPERATION_FLW : RISCV_FLOAT_OPERATION_FSW;
      break;
    case 0x3:
      if (!has_d) return false;
      operation = load
          ? RISCV_FLOAT_OPERATION_FLD : RISCV_FLOAT_OPERATION_FSD;
      break;
    default:
      return false;
  }
  instruction->immediate = riscv_fp_sign_extend(
      load
          ? riscv_fp_bits(instruction->encoding, 31, 20)
          : ((riscv_fp_bits(instruction->encoding, 31, 25) << 5) |
             riscv_fp_bits(instruction->encoding, 11, 7)),
      12);
  return riscv_fp_assign(
      instruction, operation,
      load ? RISCV_FLOAT_REGISTER_F : RISCV_FLOAT_REGISTER_NONE,
      RISCV_FLOAT_REGISTER_X,
      load ? RISCV_FLOAT_REGISTER_NONE : RISCV_FLOAT_REGISTER_F,
      RISCV_FLOAT_REGISTER_NONE);
}

static inline bool riscv_fp_decode_fused(
    uint32_t opcode, bool has_f, bool has_d,
    RiscvFloatingInstruction *instruction) {
  if (!riscv_fp_rounding_field_is_valid(instruction->rounding_mode)) {
    return false;
  }
  const uint32_t format = riscv_fp_bits(instruction->encoding, 26, 25);
  if ((format == 0 && !has_f) || (format == 1 && !has_d) || format > 1) {
    return false;
  }

  RiscvFloatingOperation operation;
  switch (opcode) {
    case 0x43:
      operation = format == 0
          ? RISCV_FLOAT_OPERATION_FMADD_S
          : RISCV_FLOAT_OPERATION_FMADD_D;
      break;
    case 0x47:
      operation = format == 0
          ? RISCV_FLOAT_OPERATION_FMSUB_S
          : RISCV_FLOAT_OPERATION_FMSUB_D;
      break;
    case 0x4b:
      operation = format == 0
          ? RISCV_FLOAT_OPERATION_FNMSUB_S
          : RISCV_FLOAT_OPERATION_FNMSUB_D;
      break;
    case 0x4f:
      operation = format == 0
          ? RISCV_FLOAT_OPERATION_FNMADD_S
          : RISCV_FLOAT_OPERATION_FNMADD_D;
      break;
    default:
      return false;
  }
  return riscv_fp_assign(
      instruction, operation,
      RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_F,
      RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_F);
}

static inline bool riscv_fp_select_pair(
    bool double_precision,
    bool has_f, bool has_d,
    RiscvFloatingOperation single_operation,
    RiscvFloatingOperation double_operation,
    RiscvFloatingOperation *operation) {
  if (double_precision) {
    if (!has_d) return false;
    *operation = double_operation;
  } else {
    if (!has_f) return false;
    *operation = single_operation;
  }
  return true;
}

static inline bool riscv_fp_decode_op(
    uint32_t xlen, bool has_f, bool has_d,
    RiscvFloatingInstruction *instruction) {
  const uint32_t funct7 = riscv_fp_bits(instruction->encoding, 31, 25);
  const uint32_t funct3 = instruction->rounding_mode;
  const uint32_t rs2 = instruction->rs2;
  const bool double_precision = (funct7 & 1u) != 0;
  RiscvFloatingOperation operation;

  switch (funct7) {
    case 0x00: case 0x01:
      if (!riscv_fp_select_pair(
              double_precision, has_f, has_d,
              RISCV_FLOAT_OPERATION_FADD_S, RISCV_FLOAT_OPERATION_FADD_D,
              &operation)) return false;
      break;
    case 0x04: case 0x05:
      if (!riscv_fp_select_pair(
              double_precision, has_f, has_d,
              RISCV_FLOAT_OPERATION_FSUB_S, RISCV_FLOAT_OPERATION_FSUB_D,
              &operation)) return false;
      break;
    case 0x08: case 0x09:
      if (!riscv_fp_select_pair(
              double_precision, has_f, has_d,
              RISCV_FLOAT_OPERATION_FMUL_S, RISCV_FLOAT_OPERATION_FMUL_D,
              &operation)) return false;
      break;
    case 0x0c: case 0x0d:
      if (!riscv_fp_select_pair(
              double_precision, has_f, has_d,
              RISCV_FLOAT_OPERATION_FDIV_S, RISCV_FLOAT_OPERATION_FDIV_D,
              &operation)) return false;
      break;
    case 0x2c: case 0x2d:
      if (rs2 != 0 || !riscv_fp_select_pair(
              double_precision, has_f, has_d,
              RISCV_FLOAT_OPERATION_FSQRT_S, RISCV_FLOAT_OPERATION_FSQRT_D,
              &operation)) return false;
      if (!riscv_fp_rounding_field_is_valid(funct3)) return false;
      return riscv_fp_assign_unary_f(instruction, operation);
    case 0x10: case 0x11:
      if (!riscv_fp_select_pair(
              double_precision, has_f, has_d,
              funct3 == 0 ? RISCV_FLOAT_OPERATION_FSGNJ_S
                  : funct3 == 1 ? RISCV_FLOAT_OPERATION_FSGNJN_S
                                : RISCV_FLOAT_OPERATION_FSGNJX_S,
              funct3 == 0 ? RISCV_FLOAT_OPERATION_FSGNJ_D
                  : funct3 == 1 ? RISCV_FLOAT_OPERATION_FSGNJN_D
                                : RISCV_FLOAT_OPERATION_FSGNJX_D,
              &operation) || funct3 > 2) return false;
      return riscv_fp_assign_binary_f(instruction, operation);
    case 0x14: case 0x15:
      if (funct3 > 1 || !riscv_fp_select_pair(
              double_precision, has_f, has_d,
              funct3 == 0 ? RISCV_FLOAT_OPERATION_FMIN_S
                           : RISCV_FLOAT_OPERATION_FMAX_S,
              funct3 == 0 ? RISCV_FLOAT_OPERATION_FMIN_D
                           : RISCV_FLOAT_OPERATION_FMAX_D,
              &operation)) return false;
      return riscv_fp_assign_binary_f(instruction, operation);
    case 0x20:
      if (!has_f || !has_d || rs2 != 1 ||
          !riscv_fp_rounding_field_is_valid(funct3)) return false;
      return riscv_fp_assign_unary_f(
          instruction, RISCV_FLOAT_OPERATION_FCVT_S_D);
    case 0x21:
      if (!has_f || !has_d || rs2 != 0 ||
          !riscv_fp_rounding_field_is_valid(funct3)) return false;
      return riscv_fp_assign_unary_f(
          instruction, RISCV_FLOAT_OPERATION_FCVT_D_S);
    case 0x50: case 0x51:
      if (funct3 > 2 || !riscv_fp_select_pair(
              double_precision, has_f, has_d,
              funct3 == 0 ? RISCV_FLOAT_OPERATION_FLE_S
                  : funct3 == 1 ? RISCV_FLOAT_OPERATION_FLT_S
                                : RISCV_FLOAT_OPERATION_FEQ_S,
              funct3 == 0 ? RISCV_FLOAT_OPERATION_FLE_D
                  : funct3 == 1 ? RISCV_FLOAT_OPERATION_FLT_D
                                : RISCV_FLOAT_OPERATION_FEQ_D,
              &operation)) return false;
      return riscv_fp_assign(
          instruction, operation,
          RISCV_FLOAT_REGISTER_X, RISCV_FLOAT_REGISTER_F,
          RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_NONE);
    case 0x60: case 0x61: {
      if (rs2 > (xlen == 64 ? 3u : 1u) ||
          !riscv_fp_rounding_field_is_valid(funct3)) return false;
      static const RiscvFloatingOperation single[4] = {
        RISCV_FLOAT_OPERATION_FCVT_W_S,
        RISCV_FLOAT_OPERATION_FCVT_WU_S,
        RISCV_FLOAT_OPERATION_FCVT_L_S,
        RISCV_FLOAT_OPERATION_FCVT_LU_S,
      };
      static const RiscvFloatingOperation dual[4] = {
        RISCV_FLOAT_OPERATION_FCVT_W_D,
        RISCV_FLOAT_OPERATION_FCVT_WU_D,
        RISCV_FLOAT_OPERATION_FCVT_L_D,
        RISCV_FLOAT_OPERATION_FCVT_LU_D,
      };
      if ((funct7 == 0x60 && !has_f) || (funct7 == 0x61 && !has_d)) {
        return false;
      }
      return riscv_fp_assign(
          instruction, funct7 == 0x60 ? single[rs2] : dual[rs2],
          RISCV_FLOAT_REGISTER_X, RISCV_FLOAT_REGISTER_F,
          RISCV_FLOAT_REGISTER_NONE, RISCV_FLOAT_REGISTER_NONE);
    }
    case 0x68: case 0x69: {
      if (rs2 > (xlen == 64 ? 3u : 1u) ||
          !riscv_fp_rounding_field_is_valid(funct3)) return false;
      static const RiscvFloatingOperation single[4] = {
        RISCV_FLOAT_OPERATION_FCVT_S_W,
        RISCV_FLOAT_OPERATION_FCVT_S_WU,
        RISCV_FLOAT_OPERATION_FCVT_S_L,
        RISCV_FLOAT_OPERATION_FCVT_S_LU,
      };
      static const RiscvFloatingOperation dual[4] = {
        RISCV_FLOAT_OPERATION_FCVT_D_W,
        RISCV_FLOAT_OPERATION_FCVT_D_WU,
        RISCV_FLOAT_OPERATION_FCVT_D_L,
        RISCV_FLOAT_OPERATION_FCVT_D_LU,
      };
      if ((funct7 == 0x68 && !has_f) || (funct7 == 0x69 && !has_d)) {
        return false;
      }
      return riscv_fp_assign(
          instruction, funct7 == 0x68 ? single[rs2] : dual[rs2],
          RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_X,
          RISCV_FLOAT_REGISTER_NONE, RISCV_FLOAT_REGISTER_NONE);
    }
    case 0x70:
      if (!has_f || rs2 != 0 || funct3 > 1) return false;
      return riscv_fp_assign(
          instruction,
          funct3 == 0 ? RISCV_FLOAT_OPERATION_FMV_X_W
                      : RISCV_FLOAT_OPERATION_FCLASS_S,
          RISCV_FLOAT_REGISTER_X, RISCV_FLOAT_REGISTER_F,
          RISCV_FLOAT_REGISTER_NONE, RISCV_FLOAT_REGISTER_NONE);
    case 0x71:
      if (!has_d || rs2 != 0 || funct3 > 1 ||
          (funct3 == 0 && xlen != 64)) return false;
      return riscv_fp_assign(
          instruction,
          funct3 == 0 ? RISCV_FLOAT_OPERATION_FMV_X_D
                      : RISCV_FLOAT_OPERATION_FCLASS_D,
          RISCV_FLOAT_REGISTER_X, RISCV_FLOAT_REGISTER_F,
          RISCV_FLOAT_REGISTER_NONE, RISCV_FLOAT_REGISTER_NONE);
    case 0x78:
      if (!has_f || rs2 != 0 || funct3 != 0) return false;
      return riscv_fp_assign(
          instruction, RISCV_FLOAT_OPERATION_FMV_W_X,
          RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_X,
          RISCV_FLOAT_REGISTER_NONE, RISCV_FLOAT_REGISTER_NONE);
    case 0x79:
      if (!has_d || xlen != 64 || rs2 != 0 || funct3 != 0) return false;
      return riscv_fp_assign(
          instruction, RISCV_FLOAT_OPERATION_FMV_D_X,
          RISCV_FLOAT_REGISTER_F, RISCV_FLOAT_REGISTER_X,
          RISCV_FLOAT_REGISTER_NONE, RISCV_FLOAT_REGISTER_NONE);
    default:
      return false;
  }

  if (!riscv_fp_rounding_field_is_valid(funct3)) return false;
  return riscv_fp_assign_binary_f(instruction, operation);
}

static inline bool riscv_fp_x_registers_exist(
    const RiscvFloatingInstruction *instruction,
    uint32_t x_register_count) {
  if (instruction->rd_file == RISCV_FLOAT_REGISTER_X &&
      instruction->rd >= x_register_count) return false;
  if (instruction->rs1_file == RISCV_FLOAT_REGISTER_X &&
      instruction->rs1 >= x_register_count) return false;
  if (instruction->rs2_file == RISCV_FLOAT_REGISTER_X &&
      instruction->rs2 >= x_register_count) return false;
  if (instruction->rs3_file == RISCV_FLOAT_REGISTER_X &&
      instruction->rs3 >= x_register_count) return false;
  return true;
}

static inline bool riscv_decode_floating_instruction(
    uint32_t encoding, uint32_t xlen, uint32_t x_register_count,
    bool has_f, bool has_d, RiscvFloatingInstruction *instruction) {
  *instruction = riscv_fp_instruction(encoding);
  if ((xlen != 32 && xlen != 64) ||
      (x_register_count != 16 && x_register_count != 32)) return false;

  const uint32_t opcode = encoding & UINT32_C(0x7f);
  bool decoded;
  switch (opcode) {
    case 0x07:
    case 0x27:
      decoded = riscv_fp_decode_memory(
          opcode, instruction->rounding_mode, has_f, has_d, instruction);
      break;
    case 0x43:
    case 0x47:
    case 0x4b:
    case 0x4f:
      decoded = riscv_fp_decode_fused(opcode, has_f, has_d, instruction);
      break;
    case 0x53:
      decoded = riscv_fp_decode_op(xlen, has_f, has_d, instruction);
      break;
    default:
      decoded = false;
      break;
  }
  if (!decoded || !riscv_fp_x_registers_exist(
          instruction, x_register_count)) {
    *instruction = riscv_fp_instruction(encoding);
    return false;
  }
  return true;
}

static inline uint32_t riscv_flen(bool has_f, bool has_d) {
  return has_d ? 64u : has_f ? 32u : 0u;
}

static inline uint64_t riscv_fp_box_single(uint32_t value, uint32_t flen) {
  return flen > 32
      ? UINT64_C(0xffffffff00000000) | value
      : (uint64_t)value;
}

static inline uint32_t riscv_fp_unbox_single(uint64_t value, uint32_t flen) {
  if (flen == 32 || (value >> 32) == UINT64_C(0xffffffff)) {
    return (uint32_t)value;
  }
  return UINT32_C(0x7fc00000);
}

#endif
