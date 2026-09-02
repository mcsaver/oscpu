/* RV64C：16-bit encoding 到手册 mnemonic 的纯体系结构译码。 */

#ifdef CONFIG_RISCV_EXT_C
#define C_FUNCT3(i) BITS(i, 15, 13)
#define C_RD_PRIME(i)  (8 + BITS(i, 4, 2))
#define C_RS1_PRIME(i) (8 + BITS(i, 9, 7))
#define C_RS2_PRIME(i) (8 + BITS(i, 4, 2))

static inline word_t c_imm_addi4spn(uint16_t encoding) {
  return (BITS(encoding, 10, 7) << 6) |
         (BITS(encoding, 12, 11) << 4) |
         (BITS(encoding, 5, 5) << 3) |
         (BITS(encoding, 6, 6) << 2);
}

static inline word_t c_imm_lw_sw(uint16_t encoding) {
  return (BITS(encoding, 5, 5) << 6) |
         (BITS(encoding, 12, 10) << 3) |
         (BITS(encoding, 6, 6) << 2);
}

static inline word_t c_imm_ld_sd(uint16_t encoding) {
  return (BITS(encoding, 6, 5) << 6) |
         (BITS(encoding, 12, 10) << 3);
}

static inline word_t c_imm_6(uint16_t encoding) {
  return SEXT((BITS(encoding, 12, 12) << 5) |
              BITS(encoding, 6, 2), 6);
}

static inline word_t c_imm_jump(uint16_t encoding) {
  const uint32_t immediate =
      (BITS(encoding, 12, 12) << 11) |
      (BITS(encoding, 11, 11) << 4) |
      (BITS(encoding, 10, 9) << 8) |
      (BITS(encoding, 8, 8) << 10) |
      (BITS(encoding, 7, 7) << 6) |
      (BITS(encoding, 6, 6) << 7) |
      (BITS(encoding, 5, 3) << 1) |
      (BITS(encoding, 2, 2) << 5);
  return SEXT(immediate, 12);
}

static inline word_t c_imm_addi16sp(uint16_t encoding) {
  const uint32_t immediate =
      (BITS(encoding, 12, 12) << 9) |
      (BITS(encoding, 6, 6) << 4) |
      (BITS(encoding, 5, 5) << 6) |
      (BITS(encoding, 4, 3) << 7) |
      (BITS(encoding, 2, 2) << 5);
  return SEXT(immediate, 10);
}

static inline word_t c_imm_branch(uint16_t encoding) {
  const uint32_t immediate =
      (BITS(encoding, 12, 12) << 8) |
      (BITS(encoding, 11, 10) << 3) |
      (BITS(encoding, 6, 5) << 6) |
      (BITS(encoding, 4, 3) << 1) |
      (BITS(encoding, 2, 2) << 5);
  return SEXT(immediate, 9);
}

static inline word_t c_imm_lwsp(uint16_t encoding) {
  return (BITS(encoding, 12, 12) << 5) |
         (BITS(encoding, 6, 4) << 2) |
         (BITS(encoding, 3, 2) << 6);
}

static inline word_t c_imm_ldsp(uint16_t encoding) {
  return (BITS(encoding, 12, 12) << 5) |
         (BITS(encoding, 6, 5) << 3) |
         (BITS(encoding, 4, 2) << 6);
}

static inline word_t c_imm_swsp(uint16_t encoding) {
  return (BITS(encoding, 8, 7) << 6) |
         (BITS(encoding, 12, 9) << 2);
}

static inline word_t c_imm_sdsp(uint16_t encoding) {
  return (BITS(encoding, 9, 7) << 6) |
         (BITS(encoding, 12, 10) << 3);
}

static inline word_t c_shift_amount(uint16_t encoding) {
  return (BITS(encoding, 12, 12) << 5) | BITS(encoding, 6, 2);
}

static inline bool rv_decode_compressed_operation(
    RvDecodedInstruction *instruction, RvOperation operation,
    uint8_t rd, uint8_t rs1, uint8_t rs2, word_t immediate) {
  instruction->operation = operation;
  instruction->rd = rd;
  instruction->rs1 = rs1;
  instruction->rs2 = rs2;
  instruction->immediate = immediate;
  return true;
}

/* Quadrant 0: register-prime loads/stores and C.ADDI4SPN. */
static inline bool rv_decode_compressed_quadrant_0(
    uint16_t encoding, RvDecodedInstruction *instruction) {
  const uint8_t rd_prime = C_RD_PRIME(encoding);
  const uint8_t rs1_prime = C_RS1_PRIME(encoding);
  const uint8_t rs2_prime = C_RS2_PRIME(encoding);

  switch (C_FUNCT3(encoding)) {
    case 0x0: {
      const word_t immediate = c_imm_addi4spn(encoding);
      if (immediate == 0) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_ADDI4SPN,
          rd_prime, 2, 0, immediate);
    }
    case 0x1:
      if (!ISDEF(CONFIG_RISCV_EXT_D)) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_FLD,
          rd_prime, rs1_prime, 0, c_imm_ld_sd(encoding));
    case 0x2:
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_LW,
          rd_prime, rs1_prime, 0, c_imm_lw_sw(encoding));
    case 0x3:
      if (!ISDEF(CONFIG_ISA64)) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_LD,
          rd_prime, rs1_prime, 0, c_imm_ld_sd(encoding));
    case 0x5:
      if (!ISDEF(CONFIG_RISCV_EXT_D)) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_FSD,
          0, rs1_prime, rs2_prime, c_imm_ld_sd(encoding));
    case 0x6:
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_SW,
          0, rs1_prime, rs2_prime, c_imm_lw_sw(encoding));
    case 0x7:
      if (!ISDEF(CONFIG_ISA64)) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_SD,
          0, rs1_prime, rs2_prime, c_imm_ld_sd(encoding));
    default:
      return false;
  }
}

/* Quadrant 1: immediate arithmetic and PC-relative control transfer. */
static inline bool rv_decode_compressed_quadrant_1(
    uint16_t encoding, RvDecodedInstruction *instruction) {
  const uint8_t rd = BITS(encoding, 11, 7);
  const uint8_t rs1_prime = C_RS1_PRIME(encoding);
  const uint8_t rs2_prime = C_RS2_PRIME(encoding);
  const word_t immediate_6 = c_imm_6(encoding);

  switch (C_FUNCT3(encoding)) {
    case 0x0:
      if ((rd == 0 && immediate_6 != 0) ||
          (rd != 0 && immediate_6 == 0)) {
        return rv_decode_compressed_operation(
            instruction, RV_OPERATION_C_HINT, 0, 0, 0, 0);
      }
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_ADDI,
          rd, rd, 0, immediate_6);
    case 0x1:
      if (!ISDEF(CONFIG_ISA64) || rd == 0) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_ADDIW,
          rd, rd, 0, immediate_6);
    case 0x2:
      if (rd == 0) {
        return rv_decode_compressed_operation(
            instruction, RV_OPERATION_C_HINT, 0, 0, 0, 0);
      }
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_LI,
          rd, 0, 0, immediate_6);
    case 0x3:
      if (rd == 2) {
        const word_t immediate = c_imm_addi16sp(encoding);
        if (immediate == 0) return false;
        return rv_decode_compressed_operation(
            instruction, RV_OPERATION_C_ADDI16SP,
            2, 2, 0, immediate);
      }
      if (immediate_6 == 0) return false;
      if (rd == 0) {
        return rv_decode_compressed_operation(
            instruction, RV_OPERATION_C_HINT, 0, 0, 0, 0);
      }
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_LUI,
          rd, 0, 0, immediate_6 << 12);
    case 0x4:
      switch (BITS(encoding, 11, 10)) {
        case 0x0:
          if (!ISDEF(CONFIG_ISA64) && BITS(encoding, 12, 12)) return false;
          return rv_decode_compressed_operation(
              instruction, RV_OPERATION_C_SRLI,
              rs1_prime, rs1_prime, 0, c_shift_amount(encoding));
        case 0x1:
          if (!ISDEF(CONFIG_ISA64) && BITS(encoding, 12, 12)) return false;
          return rv_decode_compressed_operation(
              instruction, RV_OPERATION_C_SRAI,
              rs1_prime, rs1_prime, 0, c_shift_amount(encoding));
        case 0x2:
          return rv_decode_compressed_operation(
              instruction, RV_OPERATION_C_ANDI,
              rs1_prime, rs1_prime, 0, immediate_6);
        case 0x3:
          switch ((BITS(encoding, 12, 12) << 2) |
                  BITS(encoding, 6, 5)) {
            case 0x0:
              return rv_decode_compressed_operation(
                  instruction, RV_OPERATION_C_SUB,
                  rs1_prime, rs1_prime, rs2_prime, 0);
            case 0x1:
              return rv_decode_compressed_operation(
                  instruction, RV_OPERATION_C_XOR,
                  rs1_prime, rs1_prime, rs2_prime, 0);
            case 0x2:
              return rv_decode_compressed_operation(
                  instruction, RV_OPERATION_C_OR,
                  rs1_prime, rs1_prime, rs2_prime, 0);
            case 0x3:
              return rv_decode_compressed_operation(
                  instruction, RV_OPERATION_C_AND,
                  rs1_prime, rs1_prime, rs2_prime, 0);
            case 0x4:
              if (!ISDEF(CONFIG_ISA64)) return false;
              return rv_decode_compressed_operation(
                  instruction, RV_OPERATION_C_SUBW,
                  rs1_prime, rs1_prime, rs2_prime, 0);
            case 0x5:
              if (!ISDEF(CONFIG_ISA64)) return false;
              return rv_decode_compressed_operation(
                  instruction, RV_OPERATION_C_ADDW,
                  rs1_prime, rs1_prime, rs2_prime, 0);
            default:
              return false;
          }
        default:
          return false;
      }
    case 0x5:
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_J,
          0, 0, 0, c_imm_jump(encoding));
    case 0x6:
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_BEQZ,
          0, rs1_prime, 0, c_imm_branch(encoding));
    case 0x7:
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_BNEZ,
          0, rs1_prime, 0, c_imm_branch(encoding));
    default:
      return false;
  }
}

/* Quadrant 2: stack-relative memory operations and CR register forms. */
static inline bool rv_decode_compressed_quadrant_2(
    uint16_t encoding, RvDecodedInstruction *instruction) {
  const uint8_t rd_rs1 = BITS(encoding, 11, 7);
  const uint8_t rs2 = BITS(encoding, 6, 2);

  switch (C_FUNCT3(encoding)) {
    case 0x0: {
      const word_t shamt = c_shift_amount(encoding);
      if (!ISDEF(CONFIG_ISA64) && BITS(encoding, 12, 12)) return false;
      if (rd_rs1 == 0 || shamt == 0) {
        return rv_decode_compressed_operation(
            instruction, RV_OPERATION_C_HINT, 0, 0, 0, 0);
      }
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_SLLI,
          rd_rs1, rd_rs1, 0, shamt);
    }
    case 0x1:
      if (!ISDEF(CONFIG_RISCV_EXT_D)) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_FLDSP,
          rd_rs1, 2, 0, c_imm_ldsp(encoding));
    case 0x2:
      if (rd_rs1 == 0) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_LWSP,
          rd_rs1, 2, 0, c_imm_lwsp(encoding));
    case 0x3:
      if (!ISDEF(CONFIG_ISA64) || rd_rs1 == 0) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_LDSP,
          rd_rs1, 2, 0, c_imm_ldsp(encoding));
    case 0x4:
      if (BITS(encoding, 12, 12) == 0) {
        if (rs2 == 0) {
          if (rd_rs1 == 0) return false;
          return rv_decode_compressed_operation(
              instruction, RV_OPERATION_C_JR,
              0, rd_rs1, 0, 0);
        }
        if (rd_rs1 == 0) {
          return rv_decode_compressed_operation(
              instruction, RV_OPERATION_C_HINT, 0, 0, 0, 0);
        }
        return rv_decode_compressed_operation(
            instruction, RV_OPERATION_C_MV,
            rd_rs1, 0, rs2, 0);
      }

      if (rs2 == 0) {
        if (rd_rs1 == 0) {
          return rv_decode_compressed_operation(
              instruction, RV_OPERATION_C_EBREAK,
              0, 0, 0, 0);
        }
        return rv_decode_compressed_operation(
            instruction, RV_OPERATION_C_JALR,
            1, rd_rs1, 0, 0);
      }
      if (rd_rs1 == 0) {
        return rv_decode_compressed_operation(
            instruction, RV_OPERATION_C_HINT, 0, 0, 0, 0);
      }
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_ADD,
          rd_rs1, rd_rs1, rs2, 0);
    case 0x5:
      if (!ISDEF(CONFIG_RISCV_EXT_D)) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_FSDSP,
          0, 2, rs2, c_imm_sdsp(encoding));
    case 0x6:
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_SWSP,
          0, 2, rs2, c_imm_swsp(encoding));
    case 0x7:
      if (!ISDEF(CONFIG_ISA64)) return false;
      return rv_decode_compressed_operation(
          instruction, RV_OPERATION_C_SDSP,
          0, 2, rs2, c_imm_sdsp(encoding));
    default:
      return false;
  }
}

static inline bool rv_decode_compressed_instruction(
    uint16_t encoding, RvDecodedInstruction *instruction) {
  instruction->encoding = encoding;
  instruction->instruction_class = RV_INSTRUCTION_CLASS_COMPRESSED;
  instruction->operation = RV_OPERATION_ILLEGAL_INSTRUCTION;
  instruction->length = 2;
  instruction->rd = 0;
  instruction->rs1 = 0;
  instruction->rs2 = 0;
  instruction->rs3 = 0;
  instruction->funct3 = 0;
  instruction->funct7 = 0;
  instruction->immediate = 0;

  switch (BITS(encoding, 1, 0)) {
    case 0x0:
      return rv_decode_compressed_quadrant_0(encoding, instruction);
    case 0x1:
      return rv_decode_compressed_quadrant_1(encoding, instruction);
    case 0x2:
      return rv_decode_compressed_quadrant_2(encoding, instruction);
    default:
      return false;
  }
}
#endif
