#ifndef __NEMU_ISA_RISCV_COMPRESSED_H__
#define __NEMU_ISA_RISCV_COMPRESSED_H__

#include <stdbool.h>
#include <stdint.h>

/*
 * RISC-V C extension, expressed in the same three steps as chapter 27:
 *
 *   16-bit encoding -> compressed mnemonic -> architectural operands
 *
 * This descriptor is deliberately independent of NEMU's RV32/RV64 executor.
 * In particular, every operand names its register file.  That distinction is
 * architectural: RVE removes x16-x31, but it does not remove f16-f31.
 */
typedef enum {
  RISCV_COMPRESSED_OPERATION_ILLEGAL = 0,
  RISCV_COMPRESSED_OPERATION_C_ADDI4SPN,
  RISCV_COMPRESSED_OPERATION_C_FLD,
  RISCV_COMPRESSED_OPERATION_C_LW,
  RISCV_COMPRESSED_OPERATION_C_FLW,
  RISCV_COMPRESSED_OPERATION_C_LD,
  RISCV_COMPRESSED_OPERATION_C_FSD,
  RISCV_COMPRESSED_OPERATION_C_SW,
  RISCV_COMPRESSED_OPERATION_C_FSW,
  RISCV_COMPRESSED_OPERATION_C_SD,
  RISCV_COMPRESSED_OPERATION_C_NOP,
  RISCV_COMPRESSED_OPERATION_C_ADDI,
  RISCV_COMPRESSED_OPERATION_C_JAL,
  RISCV_COMPRESSED_OPERATION_C_ADDIW,
  RISCV_COMPRESSED_OPERATION_C_LI,
  RISCV_COMPRESSED_OPERATION_C_ADDI16SP,
  RISCV_COMPRESSED_OPERATION_C_LUI,
  RISCV_COMPRESSED_OPERATION_C_SRLI,
  RISCV_COMPRESSED_OPERATION_C_SRAI,
  RISCV_COMPRESSED_OPERATION_C_ANDI,
  RISCV_COMPRESSED_OPERATION_C_SUB,
  RISCV_COMPRESSED_OPERATION_C_XOR,
  RISCV_COMPRESSED_OPERATION_C_OR,
  RISCV_COMPRESSED_OPERATION_C_AND,
  RISCV_COMPRESSED_OPERATION_C_SUBW,
  RISCV_COMPRESSED_OPERATION_C_ADDW,
  RISCV_COMPRESSED_OPERATION_C_J,
  RISCV_COMPRESSED_OPERATION_C_BEQZ,
  RISCV_COMPRESSED_OPERATION_C_BNEZ,
  RISCV_COMPRESSED_OPERATION_C_SLLI,
  RISCV_COMPRESSED_OPERATION_C_FLDSP,
  RISCV_COMPRESSED_OPERATION_C_LWSP,
  RISCV_COMPRESSED_OPERATION_C_FLWSP,
  RISCV_COMPRESSED_OPERATION_C_LDSP,
  RISCV_COMPRESSED_OPERATION_C_JR,
  RISCV_COMPRESSED_OPERATION_C_MV,
  RISCV_COMPRESSED_OPERATION_C_EBREAK,
  RISCV_COMPRESSED_OPERATION_C_JALR,
  RISCV_COMPRESSED_OPERATION_C_ADD,
  RISCV_COMPRESSED_OPERATION_C_FSDSP,
  RISCV_COMPRESSED_OPERATION_C_SWSP,
  RISCV_COMPRESSED_OPERATION_C_FSWSP,
  RISCV_COMPRESSED_OPERATION_C_SDSP,
  RISCV_COMPRESSED_OPERATION_HINT,
} RiscvCompressedOperation;

typedef enum {
  RISCV_COMPRESSED_REGISTER_NONE = 0,
  RISCV_COMPRESSED_REGISTER_X,
  RISCV_COMPRESSED_REGISTER_F,
} RiscvCompressedRegisterFile;

typedef struct {
  uint16_t encoding;
  RiscvCompressedOperation operation;
  int64_t immediate;
  uint8_t length;
  uint8_t rd;
  uint8_t rs1;
  uint8_t rs2;
  RiscvCompressedRegisterFile rd_file;
  RiscvCompressedRegisterFile rs1_file;
  RiscvCompressedRegisterFile rs2_file;
} RiscvCompressedInstruction;

static inline uint32_t riscv_c_bits(
    uint16_t encoding, unsigned high, unsigned low) {
  const uint32_t width = high - low + 1;
  return ((uint32_t)encoding >> low) & ((UINT32_C(1) << width) - 1);
}

static inline int64_t riscv_c_sign_extend(uint32_t value, unsigned width) {
  const uint32_t sign = UINT32_C(1) << (width - 1);
  return (int64_t)((int32_t)((value ^ sign) - sign));
}

static inline int64_t riscv_c_imm_addi4spn(uint16_t encoding) {
  return (int64_t)((riscv_c_bits(encoding, 10, 7) << 6) |
                   (riscv_c_bits(encoding, 12, 11) << 4) |
                   (riscv_c_bits(encoding, 5, 5) << 3) |
                   (riscv_c_bits(encoding, 6, 6) << 2));
}

static inline int64_t riscv_c_imm_lw_sw(uint16_t encoding) {
  return (int64_t)((riscv_c_bits(encoding, 5, 5) << 6) |
                   (riscv_c_bits(encoding, 12, 10) << 3) |
                   (riscv_c_bits(encoding, 6, 6) << 2));
}

static inline int64_t riscv_c_imm_ld_sd(uint16_t encoding) {
  return (int64_t)((riscv_c_bits(encoding, 6, 5) << 6) |
                   (riscv_c_bits(encoding, 12, 10) << 3));
}

static inline int64_t riscv_c_imm_6(uint16_t encoding) {
  return riscv_c_sign_extend(
      (riscv_c_bits(encoding, 12, 12) << 5) |
          riscv_c_bits(encoding, 6, 2),
      6);
}

static inline int64_t riscv_c_imm_jump(uint16_t encoding) {
  const uint32_t immediate =
      (riscv_c_bits(encoding, 12, 12) << 11) |
      (riscv_c_bits(encoding, 11, 11) << 4) |
      (riscv_c_bits(encoding, 10, 9) << 8) |
      (riscv_c_bits(encoding, 8, 8) << 10) |
      (riscv_c_bits(encoding, 7, 7) << 6) |
      (riscv_c_bits(encoding, 6, 6) << 7) |
      (riscv_c_bits(encoding, 5, 3) << 1) |
      (riscv_c_bits(encoding, 2, 2) << 5);
  return riscv_c_sign_extend(immediate, 12);
}

static inline int64_t riscv_c_imm_addi16sp(uint16_t encoding) {
  const uint32_t immediate =
      (riscv_c_bits(encoding, 12, 12) << 9) |
      (riscv_c_bits(encoding, 6, 6) << 4) |
      (riscv_c_bits(encoding, 5, 5) << 6) |
      (riscv_c_bits(encoding, 4, 3) << 7) |
      (riscv_c_bits(encoding, 2, 2) << 5);
  return riscv_c_sign_extend(immediate, 10);
}

static inline int64_t riscv_c_imm_branch(uint16_t encoding) {
  const uint32_t immediate =
      (riscv_c_bits(encoding, 12, 12) << 8) |
      (riscv_c_bits(encoding, 11, 10) << 3) |
      (riscv_c_bits(encoding, 6, 5) << 6) |
      (riscv_c_bits(encoding, 4, 3) << 1) |
      (riscv_c_bits(encoding, 2, 2) << 5);
  return riscv_c_sign_extend(immediate, 9);
}

static inline int64_t riscv_c_imm_lwsp(uint16_t encoding) {
  return (int64_t)((riscv_c_bits(encoding, 12, 12) << 5) |
                   (riscv_c_bits(encoding, 6, 4) << 2) |
                   (riscv_c_bits(encoding, 3, 2) << 6));
}

static inline int64_t riscv_c_imm_ldsp(uint16_t encoding) {
  return (int64_t)((riscv_c_bits(encoding, 12, 12) << 5) |
                   (riscv_c_bits(encoding, 6, 5) << 3) |
                   (riscv_c_bits(encoding, 4, 2) << 6));
}

static inline int64_t riscv_c_imm_swsp(uint16_t encoding) {
  return (int64_t)((riscv_c_bits(encoding, 8, 7) << 6) |
                   (riscv_c_bits(encoding, 12, 9) << 2));
}

static inline int64_t riscv_c_imm_sdsp(uint16_t encoding) {
  return (int64_t)((riscv_c_bits(encoding, 9, 7) << 6) |
                   (riscv_c_bits(encoding, 12, 10) << 3));
}

static inline int64_t riscv_c_shift_amount(uint16_t encoding) {
  return (int64_t)((riscv_c_bits(encoding, 12, 12) << 5) |
                   riscv_c_bits(encoding, 6, 2));
}

static inline RiscvCompressedInstruction riscv_c_instruction(
    uint16_t encoding) {
  return (RiscvCompressedInstruction) {
    .encoding = encoding,
    .operation = RISCV_COMPRESSED_OPERATION_ILLEGAL,
    .immediate = 0,
    .length = 2,
    .rd = 0,
    .rs1 = 0,
    .rs2 = 0,
    .rd_file = RISCV_COMPRESSED_REGISTER_NONE,
    .rs1_file = RISCV_COMPRESSED_REGISTER_NONE,
    .rs2_file = RISCV_COMPRESSED_REGISTER_NONE,
  };
}

static inline bool riscv_c_assign(
    RiscvCompressedInstruction *instruction,
    RiscvCompressedOperation operation,
    uint8_t rd, RiscvCompressedRegisterFile rd_file,
    uint8_t rs1, RiscvCompressedRegisterFile rs1_file,
    uint8_t rs2, RiscvCompressedRegisterFile rs2_file,
    int64_t immediate) {
  instruction->operation = operation;
  instruction->rd = rd;
  instruction->rd_file = rd_file;
  instruction->rs1 = rs1;
  instruction->rs1_file = rs1_file;
  instruction->rs2 = rs2;
  instruction->rs2_file = rs2_file;
  instruction->immediate = immediate;
  return true;
}

static inline bool riscv_c_assign_x_imm(
    RiscvCompressedInstruction *instruction,
    RiscvCompressedOperation operation,
    uint8_t rd, uint8_t rs1, int64_t immediate) {
  return riscv_c_assign(
      instruction, operation,
      rd, RISCV_COMPRESSED_REGISTER_X,
      rs1, RISCV_COMPRESSED_REGISTER_X,
      0, RISCV_COMPRESSED_REGISTER_NONE,
      immediate);
}

static inline bool riscv_c_assign_memory(
    RiscvCompressedInstruction *instruction,
    RiscvCompressedOperation operation,
    bool load, RiscvCompressedRegisterFile data_file,
    uint8_t data_register, uint8_t address_register, int64_t immediate) {
  return load
      ? riscv_c_assign(
            instruction, operation,
            data_register, data_file,
            address_register, RISCV_COMPRESSED_REGISTER_X,
            0, RISCV_COMPRESSED_REGISTER_NONE,
            immediate)
      : riscv_c_assign(
            instruction, operation,
            0, RISCV_COMPRESSED_REGISTER_NONE,
            address_register, RISCV_COMPRESSED_REGISTER_X,
            data_register, data_file,
            immediate);
}

static inline bool riscv_c_decode_quadrant_0(
    uint16_t encoding, uint32_t xlen, bool has_f, bool has_d,
    RiscvCompressedInstruction *instruction) {
  const uint8_t rd_prime = 8 + riscv_c_bits(encoding, 4, 2);
  const uint8_t rs1_prime = 8 + riscv_c_bits(encoding, 9, 7);
  const uint8_t rs2_prime = 8 + riscv_c_bits(encoding, 4, 2);

  switch (riscv_c_bits(encoding, 15, 13)) {
    case 0x0: {
      const int64_t immediate = riscv_c_imm_addi4spn(encoding);
      if (immediate == 0) return false;
      return riscv_c_assign_x_imm(
          instruction, RISCV_COMPRESSED_OPERATION_C_ADDI4SPN,
          rd_prime, 2, immediate);
    }
    case 0x1:
      return has_d && riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_FLD, true,
          RISCV_COMPRESSED_REGISTER_F, rd_prime, rs1_prime,
          riscv_c_imm_ld_sd(encoding));
    case 0x2:
      return riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_LW, true,
          RISCV_COMPRESSED_REGISTER_X, rd_prime, rs1_prime,
          riscv_c_imm_lw_sw(encoding));
    case 0x3:
      if (xlen == 32) {
        return has_f && riscv_c_assign_memory(
            instruction, RISCV_COMPRESSED_OPERATION_C_FLW, true,
            RISCV_COMPRESSED_REGISTER_F, rd_prime, rs1_prime,
            riscv_c_imm_lw_sw(encoding));
      }
      return riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_LD, true,
          RISCV_COMPRESSED_REGISTER_X, rd_prime, rs1_prime,
          riscv_c_imm_ld_sd(encoding));
    case 0x5:
      return has_d && riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_FSD, false,
          RISCV_COMPRESSED_REGISTER_F, rs2_prime, rs1_prime,
          riscv_c_imm_ld_sd(encoding));
    case 0x6:
      return riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_SW, false,
          RISCV_COMPRESSED_REGISTER_X, rs2_prime, rs1_prime,
          riscv_c_imm_lw_sw(encoding));
    case 0x7:
      if (xlen == 32) {
        return has_f && riscv_c_assign_memory(
            instruction, RISCV_COMPRESSED_OPERATION_C_FSW, false,
            RISCV_COMPRESSED_REGISTER_F, rs2_prime, rs1_prime,
            riscv_c_imm_lw_sw(encoding));
      }
      return riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_SD, false,
          RISCV_COMPRESSED_REGISTER_X, rs2_prime, rs1_prime,
          riscv_c_imm_ld_sd(encoding));
    default:
      return false;
  }
}

static inline bool riscv_c_decode_quadrant_1(
    uint16_t encoding, uint32_t xlen,
    RiscvCompressedInstruction *instruction) {
  const uint8_t rd = riscv_c_bits(encoding, 11, 7);
  const uint8_t rs1_prime = 8 + riscv_c_bits(encoding, 9, 7);
  const uint8_t rs2_prime = 8 + riscv_c_bits(encoding, 4, 2);
  const int64_t immediate_6 = riscv_c_imm_6(encoding);

  switch (riscv_c_bits(encoding, 15, 13)) {
    case 0x0:
      if (rd == 0 && immediate_6 == 0) {
        return riscv_c_assign_x_imm(
            instruction, RISCV_COMPRESSED_OPERATION_C_NOP, 0, 0, 0);
      }
      if (rd == 0 || immediate_6 == 0) {
        return riscv_c_assign_x_imm(
            instruction, RISCV_COMPRESSED_OPERATION_HINT,
            rd, rd, immediate_6);
      }
      return riscv_c_assign_x_imm(
          instruction, RISCV_COMPRESSED_OPERATION_C_ADDI,
          rd, rd, immediate_6);
    case 0x1:
      if (xlen == 32) {
        return riscv_c_assign(
            instruction, RISCV_COMPRESSED_OPERATION_C_JAL,
            1, RISCV_COMPRESSED_REGISTER_X,
            0, RISCV_COMPRESSED_REGISTER_NONE,
            0, RISCV_COMPRESSED_REGISTER_NONE,
            riscv_c_imm_jump(encoding));
      }
      if (rd == 0) return false;
      return riscv_c_assign_x_imm(
          instruction, RISCV_COMPRESSED_OPERATION_C_ADDIW,
          rd, rd, immediate_6);
    case 0x2:
      if (rd == 0) {
        return riscv_c_assign_x_imm(
            instruction, RISCV_COMPRESSED_OPERATION_HINT,
            0, 0, immediate_6);
      }
      return riscv_c_assign(
          instruction, RISCV_COMPRESSED_OPERATION_C_LI,
          rd, RISCV_COMPRESSED_REGISTER_X,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          immediate_6);
    case 0x3:
      if (rd == 2) {
        const int64_t immediate = riscv_c_imm_addi16sp(encoding);
        if (immediate == 0) return false;
        return riscv_c_assign_x_imm(
            instruction, RISCV_COMPRESSED_OPERATION_C_ADDI16SP,
            2, 2, immediate);
      }
      if (immediate_6 == 0) return false;
      if (rd == 0) {
        return riscv_c_assign(
            instruction, RISCV_COMPRESSED_OPERATION_HINT,
            0, RISCV_COMPRESSED_REGISTER_X,
            0, RISCV_COMPRESSED_REGISTER_NONE,
            0, RISCV_COMPRESSED_REGISTER_NONE,
            immediate_6 * INT64_C(4096));
      }
      return riscv_c_assign(
          instruction, RISCV_COMPRESSED_OPERATION_C_LUI,
          rd, RISCV_COMPRESSED_REGISTER_X,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          immediate_6 * INT64_C(4096));
    case 0x4:
      switch (riscv_c_bits(encoding, 11, 10)) {
        case 0x0:
        case 0x1: {
          const int64_t shamt = riscv_c_shift_amount(encoding);
          if (xlen == 32 && riscv_c_bits(encoding, 12, 12)) return false;
          if (shamt == 0) {
            return riscv_c_assign_x_imm(
                instruction, RISCV_COMPRESSED_OPERATION_HINT,
                rs1_prime, rs1_prime, shamt);
          }
          return riscv_c_assign_x_imm(
              instruction,
              riscv_c_bits(encoding, 11, 10) == 0
                  ? RISCV_COMPRESSED_OPERATION_C_SRLI
                  : RISCV_COMPRESSED_OPERATION_C_SRAI,
              rs1_prime, rs1_prime, shamt);
        }
        case 0x2:
          return riscv_c_assign_x_imm(
              instruction, RISCV_COMPRESSED_OPERATION_C_ANDI,
              rs1_prime, rs1_prime, immediate_6);
        case 0x3: {
          RiscvCompressedOperation operation;
          switch ((riscv_c_bits(encoding, 12, 12) << 2) |
                  riscv_c_bits(encoding, 6, 5)) {
            case 0x0: operation = RISCV_COMPRESSED_OPERATION_C_SUB; break;
            case 0x1: operation = RISCV_COMPRESSED_OPERATION_C_XOR; break;
            case 0x2: operation = RISCV_COMPRESSED_OPERATION_C_OR; break;
            case 0x3: operation = RISCV_COMPRESSED_OPERATION_C_AND; break;
            case 0x4:
              if (xlen != 64) return false;
              operation = RISCV_COMPRESSED_OPERATION_C_SUBW;
              break;
            case 0x5:
              if (xlen != 64) return false;
              operation = RISCV_COMPRESSED_OPERATION_C_ADDW;
              break;
            default:
              return false;
          }
          return riscv_c_assign(
              instruction, operation,
              rs1_prime, RISCV_COMPRESSED_REGISTER_X,
              rs1_prime, RISCV_COMPRESSED_REGISTER_X,
              rs2_prime, RISCV_COMPRESSED_REGISTER_X,
              0);
        }
        default:
          return false;
      }
    case 0x5:
      return riscv_c_assign(
          instruction, RISCV_COMPRESSED_OPERATION_C_J,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          riscv_c_imm_jump(encoding));
    case 0x6:
    case 0x7:
      return riscv_c_assign(
          instruction,
          riscv_c_bits(encoding, 15, 13) == 0x6
              ? RISCV_COMPRESSED_OPERATION_C_BEQZ
              : RISCV_COMPRESSED_OPERATION_C_BNEZ,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          rs1_prime, RISCV_COMPRESSED_REGISTER_X,
          0, RISCV_COMPRESSED_REGISTER_NONE,
          riscv_c_imm_branch(encoding));
    default:
      return false;
  }
}

static inline bool riscv_c_decode_quadrant_2(
    uint16_t encoding, uint32_t xlen, bool has_f, bool has_d,
    RiscvCompressedInstruction *instruction) {
  const uint8_t rd_rs1 = riscv_c_bits(encoding, 11, 7);
  const uint8_t rs2 = riscv_c_bits(encoding, 6, 2);

  switch (riscv_c_bits(encoding, 15, 13)) {
    case 0x0: {
      const int64_t shamt = riscv_c_shift_amount(encoding);
      if (xlen == 32 && riscv_c_bits(encoding, 12, 12)) return false;
      if (rd_rs1 == 0 || shamt == 0) {
        return riscv_c_assign_x_imm(
            instruction, RISCV_COMPRESSED_OPERATION_HINT,
            rd_rs1, rd_rs1, shamt);
      }
      return riscv_c_assign_x_imm(
          instruction, RISCV_COMPRESSED_OPERATION_C_SLLI,
          rd_rs1, rd_rs1, shamt);
    }
    case 0x1:
      return has_d && riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_FLDSP, true,
          RISCV_COMPRESSED_REGISTER_F, rd_rs1, 2,
          riscv_c_imm_ldsp(encoding));
    case 0x2:
      if (rd_rs1 == 0) return false;
      return riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_LWSP, true,
          RISCV_COMPRESSED_REGISTER_X, rd_rs1, 2,
          riscv_c_imm_lwsp(encoding));
    case 0x3:
      if (xlen == 32) {
        return has_f && riscv_c_assign_memory(
            instruction, RISCV_COMPRESSED_OPERATION_C_FLWSP, true,
            RISCV_COMPRESSED_REGISTER_F, rd_rs1, 2,
            riscv_c_imm_lwsp(encoding));
      }
      if (rd_rs1 == 0) return false;
      return riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_LDSP, true,
          RISCV_COMPRESSED_REGISTER_X, rd_rs1, 2,
          riscv_c_imm_ldsp(encoding));
    case 0x4:
      if (riscv_c_bits(encoding, 12, 12) == 0) {
        if (rs2 == 0) {
          if (rd_rs1 == 0) return false;
          return riscv_c_assign(
              instruction, RISCV_COMPRESSED_OPERATION_C_JR,
              0, RISCV_COMPRESSED_REGISTER_NONE,
              rd_rs1, RISCV_COMPRESSED_REGISTER_X,
              0, RISCV_COMPRESSED_REGISTER_NONE,
              0);
        }
        return riscv_c_assign(
            instruction,
            rd_rs1 == 0
                ? RISCV_COMPRESSED_OPERATION_HINT
                : RISCV_COMPRESSED_OPERATION_C_MV,
            rd_rs1, RISCV_COMPRESSED_REGISTER_X,
            0, RISCV_COMPRESSED_REGISTER_NONE,
            rs2, RISCV_COMPRESSED_REGISTER_X,
            0);
      }
      if (rs2 == 0) {
        if (rd_rs1 == 0) {
          return riscv_c_assign(
              instruction, RISCV_COMPRESSED_OPERATION_C_EBREAK,
              0, RISCV_COMPRESSED_REGISTER_NONE,
              0, RISCV_COMPRESSED_REGISTER_NONE,
              0, RISCV_COMPRESSED_REGISTER_NONE,
              0);
        }
        return riscv_c_assign(
            instruction, RISCV_COMPRESSED_OPERATION_C_JALR,
            1, RISCV_COMPRESSED_REGISTER_X,
            rd_rs1, RISCV_COMPRESSED_REGISTER_X,
            0, RISCV_COMPRESSED_REGISTER_NONE,
            0);
      }
      return riscv_c_assign(
          instruction,
          rd_rs1 == 0
              ? RISCV_COMPRESSED_OPERATION_HINT
              : RISCV_COMPRESSED_OPERATION_C_ADD,
          rd_rs1, RISCV_COMPRESSED_REGISTER_X,
          rd_rs1, RISCV_COMPRESSED_REGISTER_X,
          rs2, RISCV_COMPRESSED_REGISTER_X,
          0);
    case 0x5:
      return has_d && riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_FSDSP, false,
          RISCV_COMPRESSED_REGISTER_F, rs2, 2,
          riscv_c_imm_sdsp(encoding));
    case 0x6:
      return riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_SWSP, false,
          RISCV_COMPRESSED_REGISTER_X, rs2, 2,
          riscv_c_imm_swsp(encoding));
    case 0x7:
      if (xlen == 32) {
        return has_f && riscv_c_assign_memory(
            instruction, RISCV_COMPRESSED_OPERATION_C_FSWSP, false,
            RISCV_COMPRESSED_REGISTER_F, rs2, 2,
            riscv_c_imm_swsp(encoding));
      }
      return riscv_c_assign_memory(
          instruction, RISCV_COMPRESSED_OPERATION_C_SDSP, false,
          RISCV_COMPRESSED_REGISTER_X, rs2, 2,
          riscv_c_imm_sdsp(encoding));
    default:
      return false;
  }
}

static inline bool riscv_c_registers_exist(
    const RiscvCompressedInstruction *instruction,
    uint32_t x_register_count) {
  if (instruction->rd_file == RISCV_COMPRESSED_REGISTER_X &&
      instruction->rd >= x_register_count) return false;
  if (instruction->rs1_file == RISCV_COMPRESSED_REGISTER_X &&
      instruction->rs1 >= x_register_count) return false;
  if (instruction->rs2_file == RISCV_COMPRESSED_REGISTER_X &&
      instruction->rs2 >= x_register_count) return false;
  return true;
}

static inline bool riscv_decode_compressed_instruction(
    uint16_t encoding, uint32_t xlen, uint32_t x_register_count,
    bool has_f, bool has_d, RiscvCompressedInstruction *instruction) {
  *instruction = riscv_c_instruction(encoding);
  if (xlen != 32 && xlen != 64) return false;
  if (x_register_count != 16 && x_register_count != 32) return false;

  bool decoded = false;
  switch (encoding & UINT16_C(0x3)) {
    case 0x0:
      decoded = riscv_c_decode_quadrant_0(
          encoding, xlen, has_f, has_d, instruction);
      break;
    case 0x1:
      decoded = riscv_c_decode_quadrant_1(
          encoding, xlen, instruction);
      break;
    case 0x2:
      decoded = riscv_c_decode_quadrant_2(
          encoding, xlen, has_f, has_d, instruction);
      break;
    default:
      return false;
  }

  if (!decoded || !riscv_c_registers_exist(
          instruction, x_register_count)) {
    *instruction = riscv_c_instruction(encoding);
    return false;
  }
  return true;
}

#endif
