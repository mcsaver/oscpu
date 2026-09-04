/* 顶层取指、体系结构译码编排、异常收口和 isa_exec_once。 */

//取值：
//1.查询decode cache
//2.miss的时候把原始编码译成RvDecodedInstruction
//3.rv_execute_decoded_instruction()
//访存/异常收口
//得到dnpc


static inline RvDecodedInstruction rv_decoded_instruction(uint32_t encoding) {
  return (RvDecodedInstruction) {
    .encoding = encoding,
    .immediate = 0,
    .instruction_class = RV_INSTRUCTION_CLASS_ILLEGAL,
    .operation = RV_OPERATION_ILLEGAL_INSTRUCTION,
    .length = 4,
    .rd = RD(encoding),
    .rs1 = RS1(encoding),
    .rs2 = RS2(encoding),
    .rs3 = RS3(encoding),
  };
}

static inline bool rv_decode_operation(
    RvDecodedInstruction *instruction,
    RvInstructionClass instruction_class,
    RvOperation operation) {
  instruction->instruction_class = instruction_class;
  instruction->operation = operation;
  return true;
}

#ifdef CONFIG_RISCV_EXT_M
static inline bool rv_decode_multiply_divide(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  if (FUNCT7(encoding) != 0x01) return false;

  switch (FUNCT3(encoding)) {
    case 0x0: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE,
        RV_OPERATION_MUL);
    case 0x1: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE,
        RV_OPERATION_MULH);
    case 0x2: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE,
        RV_OPERATION_MULHSU);
    case 0x3: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE,
        RV_OPERATION_MULHU);
    case 0x4: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE,
        RV_OPERATION_DIV);
    case 0x5: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE,
        RV_OPERATION_DIVU);
    case 0x6: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE,
        RV_OPERATION_REM);
    case 0x7: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE,
        RV_OPERATION_REMU);
    default: return false;
  }
}

static inline bool rv_decode_multiply_divide_word(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  if (FUNCT7(encoding) != 0x01) return false;

  switch (FUNCT3(encoding)) {
    case 0x0: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE_WORD,
        RV_OPERATION_MULW);
    case 0x4: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE_WORD,
        RV_OPERATION_DIVW);
    case 0x5: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE_WORD,
        RV_OPERATION_DIVUW);
    case 0x6: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE_WORD,
        RV_OPERATION_REMW);
    case 0x7: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MULTIPLY_DIVIDE_WORD,
        RV_OPERATION_REMUW);
    default: return false;
  }
}
#endif

#ifdef CONFIG_RISCV_EXT_B
static inline bool rv_decode_bitmanip_immediate(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  const uint32_t funct3 = FUNCT3(encoding);
  const uint32_t funct6 = BITS(encoding, 31, 26);
  const uint32_t funct7 = FUNCT7(encoding);
  const uint32_t immediate_5 = BITS(encoding, 24, 20);
  const word_t shamt = BITS(encoding, 25, 20);
  RvOperation operation = RV_OPERATION_ILLEGAL_INSTRUCTION;

  if (funct3 == 0x1) {
    switch (funct6) {
      case 0x0a: operation = RV_OPERATION_BSETI; break;
      case 0x12: operation = RV_OPERATION_BCLRI; break;
      case 0x1a: operation = RV_OPERATION_BINVI; break;
      default: break;
    }
    if (operation != RV_OPERATION_ILLEGAL_INSTRUCTION) {
      instruction->immediate = shamt;
      return rv_decode_operation(
          instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE,
          operation);
    }

    if (funct7 == 0x30) {
      switch (immediate_5) {
        case 0x00: operation = RV_OPERATION_CLZ; break;
        case 0x01: operation = RV_OPERATION_CTZ; break;
        case 0x02: operation = RV_OPERATION_CPOP; break;
        case 0x04: operation = RV_OPERATION_SEXT_B; break;
        case 0x05: operation = RV_OPERATION_SEXT_H; break;
        default: return false;
      }
      return rv_decode_operation(
          instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE,
          operation);
    }
    return false;
  }

  if (funct3 != 0x5) return false;
  switch (funct6) {
    case 0x18:
      instruction->immediate = shamt;
      return rv_decode_operation(
          instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE,
          RV_OPERATION_RORI);
    case 0x12:
      instruction->immediate = shamt;
      return rv_decode_operation(
          instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE,
          RV_OPERATION_BEXTI);
    default:
      break;
  }

  if (funct7 == 0x14 && immediate_5 == 0x07) {
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE,
        RV_OPERATION_ORC_B);
  }
  /* REV8 is the RV64 encoding imm[11:0]=0x6b8, not RV32's 0x698. */
  if (funct7 == 0x35 && immediate_5 == 0x18) {
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE,
        RV_OPERATION_REV8);
  }
  return false;
}

static inline bool rv_decode_bitmanip_immediate_word(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  const uint32_t funct3 = FUNCT3(encoding);
  const uint32_t funct6 = BITS(encoding, 31, 26);
  const uint32_t funct7 = FUNCT7(encoding);
  const uint32_t immediate_5 = BITS(encoding, 24, 20);

  if (funct3 == 0x1 && funct6 == 0x02) {
    /* SLLI.UW is RV64-only and carries a full six-bit shift amount. */
    instruction->immediate = BITS(encoding, 25, 20);
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE_WORD,
        RV_OPERATION_SLLI_UW);
  }
  if (funct3 == 0x1 && funct7 == 0x30) {
    RvOperation operation;
    switch (immediate_5) {
      case 0x00: operation = RV_OPERATION_CLZW; break;
      case 0x01: operation = RV_OPERATION_CTZW; break;
      case 0x02: operation = RV_OPERATION_CPOPW; break;
      default: return false;
    }
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE_WORD,
        operation);
  }
  if (funct3 == 0x5 && funct7 == 0x30) {
    instruction->immediate = immediate_5;
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_IMMEDIATE_WORD,
        RV_OPERATION_RORIW);
  }
  return false;
}

static inline bool rv_decode_bitmanip_register(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  RvOperation operation;
  switch (OP_KEY(FUNCT3(encoding), FUNCT7(encoding))) {
    case OP_KEY(0x2, 0x10): operation = RV_OPERATION_SH1ADD; break;
    case OP_KEY(0x4, 0x10): operation = RV_OPERATION_SH2ADD; break;
    case OP_KEY(0x6, 0x10): operation = RV_OPERATION_SH3ADD; break;
    case OP_KEY(0x7, 0x20): operation = RV_OPERATION_ANDN; break;
    case OP_KEY(0x6, 0x20): operation = RV_OPERATION_ORN; break;
    case OP_KEY(0x4, 0x20): operation = RV_OPERATION_XNOR; break;
    case OP_KEY(0x1, 0x30): operation = RV_OPERATION_ROL; break;
    case OP_KEY(0x5, 0x30): operation = RV_OPERATION_ROR; break;
    case OP_KEY(0x4, 0x05): operation = RV_OPERATION_MIN; break;
    case OP_KEY(0x5, 0x05): operation = RV_OPERATION_MINU; break;
    case OP_KEY(0x6, 0x05): operation = RV_OPERATION_MAX; break;
    case OP_KEY(0x7, 0x05): operation = RV_OPERATION_MAXU; break;
    case OP_KEY(0x1, 0x05): operation = RV_OPERATION_CLMUL; break;
    case OP_KEY(0x2, 0x05): operation = RV_OPERATION_CLMULR; break;
    case OP_KEY(0x3, 0x05): operation = RV_OPERATION_CLMULH; break;
    case OP_KEY(0x1, 0x14): operation = RV_OPERATION_BSET; break;
    case OP_KEY(0x1, 0x24): operation = RV_OPERATION_BCLR; break;
    case OP_KEY(0x5, 0x24): operation = RV_OPERATION_BEXT; break;
    case OP_KEY(0x1, 0x34): operation = RV_OPERATION_BINV; break;
    default: return false;
  }
  return rv_decode_operation(
      instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_REGISTER,
      operation);
}

static inline bool rv_decode_bitmanip_register_word(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  RvOperation operation;
  switch (OP_KEY(FUNCT3(encoding), FUNCT7(encoding))) {
    case OP_KEY(0x0, 0x04): operation = RV_OPERATION_ADD_UW; break;
    case OP_KEY(0x2, 0x10): operation = RV_OPERATION_SH1ADD_UW; break;
    case OP_KEY(0x4, 0x10): operation = RV_OPERATION_SH2ADD_UW; break;
    case OP_KEY(0x6, 0x10): operation = RV_OPERATION_SH3ADD_UW; break;
    case OP_KEY(0x4, 0x04):
      /* RV64 ZEXT.H is OP-32 with rs2=x0. */
      if (RS2(encoding) != 0) return false;
      operation = RV_OPERATION_ZEXT_H;
      break;
    case OP_KEY(0x1, 0x30): operation = RV_OPERATION_ROLW; break;
    case OP_KEY(0x5, 0x30): operation = RV_OPERATION_RORW; break;
    default: return false;
  }
  return rv_decode_operation(
      instruction, RV_INSTRUCTION_CLASS_BIT_MANIPULATION_REGISTER_WORD,
      operation);
}
#endif

static inline bool rv_decode_integer_immediate(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  const uint32_t funct3 = FUNCT3(encoding);
  const uint32_t funct6 = BITS(encoding, 31, 26);

  instruction->immediate = IMM_I(encoding);

  switch (funct3) {
    case 0x0: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
        RV_OPERATION_ADDI);
    case 0x2: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
        RV_OPERATION_SLTI);
    case 0x3: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
        RV_OPERATION_SLTIU);
    case 0x4: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
        RV_OPERATION_XORI);
    case 0x6: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
        RV_OPERATION_ORI);
    case 0x7: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
        RV_OPERATION_ANDI);
    case 0x1:
      if (funct6 == 0x00) {
        instruction->immediate = BITS(encoding, 25, 20);
        return rv_decode_operation(
            instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
            RV_OPERATION_SLLI);
      }
      break;
    case 0x5:
      if (funct6 == 0x00) {
        instruction->immediate = BITS(encoding, 25, 20);
        return rv_decode_operation(
            instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
            RV_OPERATION_SRLI);
      }
      if (funct6 == 0x10) {
        instruction->immediate = BITS(encoding, 25, 20);
        return rv_decode_operation(
            instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE,
            RV_OPERATION_SRAI);
      }
      break;
    default:
      break;
  }
#ifdef CONFIG_RISCV_EXT_B
  return rv_decode_bitmanip_immediate(encoding, instruction);
#else
  return false;
#endif
}

static inline bool rv_decode_integer_immediate_word(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  const uint32_t funct3 = FUNCT3(encoding);
  const uint32_t funct7 = FUNCT7(encoding);

  if (funct3 == 0x0) {
    instruction->immediate = IMM_I(encoding);
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE_WORD,
        RV_OPERATION_ADDIW);
  }
  if (funct3 == 0x1 && funct7 == 0x00) {
    instruction->immediate = BITS(encoding, 24, 20);
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE_WORD,
        RV_OPERATION_SLLIW);
  }
  if (funct3 == 0x5 && funct7 == 0x00) {
    instruction->immediate = BITS(encoding, 24, 20);
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE_WORD,
        RV_OPERATION_SRLIW);
  }
  if (funct3 == 0x5 && funct7 == 0x20) {
    instruction->immediate = BITS(encoding, 24, 20);
    return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE_WORD,
        RV_OPERATION_SRAIW);
  }
#ifdef CONFIG_RISCV_EXT_B
  return rv_decode_bitmanip_immediate_word(encoding, instruction);
#else
  return false;
#endif
}

static inline bool rv_decode_integer_register(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  switch (OP_KEY(FUNCT3(encoding), FUNCT7(encoding))) {
    case OP_KEY(0x0, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_ADD);
    case OP_KEY(0x0, 0x20): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_SUB);
    case OP_KEY(0x1, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_SLL);
    case OP_KEY(0x2, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_SLT);
    case OP_KEY(0x3, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_SLTU);
    case OP_KEY(0x4, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_XOR);
    case OP_KEY(0x5, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_SRL);
    case OP_KEY(0x5, 0x20): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_SRA);
    case OP_KEY(0x6, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_OR);
    case OP_KEY(0x7, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER,
        RV_OPERATION_AND);
    default: break;
  }
#ifdef CONFIG_RISCV_EXT_M
  if (rv_decode_multiply_divide(encoding, instruction)) return true;
#endif
#ifdef CONFIG_RISCV_EXT_B
  if (rv_decode_bitmanip_register(encoding, instruction)) return true;
#endif
  return false;
}

static inline bool rv_decode_integer_register_word(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  switch (OP_KEY(FUNCT3(encoding), FUNCT7(encoding))) {
    case OP_KEY(0x0, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER_WORD,
        RV_OPERATION_ADDW);
    case OP_KEY(0x0, 0x20): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER_WORD,
        RV_OPERATION_SUBW);
    case OP_KEY(0x1, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER_WORD,
        RV_OPERATION_SLLW);
    case OP_KEY(0x5, 0x00): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER_WORD,
        RV_OPERATION_SRLW);
    case OP_KEY(0x5, 0x20): return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_INTEGER_REGISTER_WORD,
        RV_OPERATION_SRAW);
    default: break;
  }
#ifdef CONFIG_RISCV_EXT_B
  if (rv_decode_bitmanip_register_word(encoding, instruction)) return true;
#endif
#ifdef CONFIG_RISCV_EXT_M
  if (rv_decode_multiply_divide_word(encoding, instruction)) return true;
#endif
  return false;
}

static inline bool rv_decode_load(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->immediate = IMM_I(encoding);

  switch (FUNCT3(encoding)) {
    case 0x0: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_LOAD, RV_OPERATION_LB);
    case 0x1: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_LOAD, RV_OPERATION_LH);
    case 0x2: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_LOAD, RV_OPERATION_LW);
    case 0x3: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_LOAD, RV_OPERATION_LD);
    case 0x4: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_LOAD, RV_OPERATION_LBU);
    case 0x5: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_LOAD, RV_OPERATION_LHU);
    case 0x6: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_LOAD, RV_OPERATION_LWU);
    default: return false;
  }
}

static inline bool rv_decode_store(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->immediate = IMM_S(encoding);

  switch (FUNCT3(encoding)) {
    case 0x0: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_STORE, RV_OPERATION_SB);
    case 0x1: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_STORE, RV_OPERATION_SH);
    case 0x2: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_STORE, RV_OPERATION_SW);
    case 0x3: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_STORE, RV_OPERATION_SD);
    default: return false;
  }
}

static inline bool rv_decode_branch(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->immediate = IMM_B(encoding);

  switch (FUNCT3(encoding)) {
    case 0x0: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BRANCH, RV_OPERATION_BEQ);
    case 0x1: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BRANCH, RV_OPERATION_BNE);
    case 0x4: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BRANCH, RV_OPERATION_BLT);
    case 0x5: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BRANCH, RV_OPERATION_BGE);
    case 0x6: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BRANCH, RV_OPERATION_BLTU);
    case 0x7: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_BRANCH, RV_OPERATION_BGEU);
    default: return false;
  }
}

static inline bool rv_decode_jump(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  switch (OPCODE(encoding)) {
    case OPC_JAL:
      instruction->immediate = IMM_J(encoding);
      return rv_decode_operation(
          instruction, RV_INSTRUCTION_CLASS_JUMP, RV_OPERATION_JAL);
    case OPC_JALR:
      if (FUNCT3(encoding) != 0x0) return false;
      instruction->immediate = IMM_I(encoding);
      return rv_decode_operation(
          instruction, RV_INSTRUCTION_CLASS_JUMP, RV_OPERATION_JALR);
    default:
      return false;
  }
}

static inline bool rv_decode_memory_ordering(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  switch (FUNCT3(encoding)) {
    case 0x0: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MEMORY_ORDERING,
        RV_OPERATION_FENCE);
    case 0x1: return rv_decode_operation(
        instruction, RV_INSTRUCTION_CLASS_MEMORY_ORDERING,
        RV_OPERATION_FENCE_I);
    default:
      return false;
  }
}

static inline bool rv_decode_system(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  RiscvSystemInstruction system;
  if (!riscv_decode_system_instruction(encoding, &system)) return false;

  instruction->instruction_class = RV_INSTRUCTION_CLASS_SYSTEM;
  instruction->system = system;
  switch (system.operation) {
    case RISCV_SYSTEM_OPERATION_ECALL:
      instruction->operation = RV_OPERATION_ECALL; break;
    case RISCV_SYSTEM_OPERATION_EBREAK:
      instruction->operation = RV_OPERATION_EBREAK; break;
    case RISCV_SYSTEM_OPERATION_SRET:
      instruction->operation = RV_OPERATION_SRET; break;
    case RISCV_SYSTEM_OPERATION_MRET:
      instruction->operation = RV_OPERATION_MRET; break;
    case RISCV_SYSTEM_OPERATION_WFI:
      instruction->operation = RV_OPERATION_WFI; break;
    case RISCV_SYSTEM_OPERATION_SFENCE_VMA:
      instruction->operation = RV_OPERATION_SFENCE_VMA; break;
    case RISCV_SYSTEM_OPERATION_CSRRW:
      instruction->operation = RV_OPERATION_CSRRW; break;
    case RISCV_SYSTEM_OPERATION_CSRRS:
      instruction->operation = RV_OPERATION_CSRRS; break;
    case RISCV_SYSTEM_OPERATION_CSRRC:
      instruction->operation = RV_OPERATION_CSRRC; break;
    case RISCV_SYSTEM_OPERATION_CSRRWI:
      instruction->operation = RV_OPERATION_CSRRWI; break;
    case RISCV_SYSTEM_OPERATION_CSRRSI:
      instruction->operation = RV_OPERATION_CSRRSI; break;
    case RISCV_SYSTEM_OPERATION_CSRRCI:
      instruction->operation = RV_OPERATION_CSRRCI; break;
    default: return false;
  }
  return true;
}

static inline bool rv_decode_floating(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  RiscvFloatingInstruction floating;
  if (!riscv_decode_floating_instruction(
          encoding, 64, 32,
          ISDEF(CONFIG_RISCV_EXT_F), ISDEF(CONFIG_RISCV_EXT_D),
          &floating)) {
    return false;
  }
  instruction->instruction_class = RV_INSTRUCTION_CLASS_FLOATING_POINT;
  instruction->operation = RV_OPERATION_FLOATING;
  instruction->floating = floating;
  instruction->immediate = (word_t)floating.immediate;
  instruction->rd = floating.rd;
  instruction->rs1 = floating.rs1;
  instruction->rs2 = floating.rs2;
  instruction->rs3 = floating.rs3;
  return true;
}

/*
 * RV64 raw encoding 在这里唯一一次变成手册 mnemonic descriptor。
 * 每个 16/32-bit 编码都由本函数完整认领；保留或未实现的编码保持
 * ILLEGAL descriptor，由统一执行入口产生 Illegal Instruction。
 */
static inline void rv_decode_instruction(
    uint32_t encoding, RvDecodedInstruction *instruction) {
#ifdef CONFIG_RISCV_EXT_C
  if ((encoding & 0x3u) != 0x3u) {
    *instruction = rv_decoded_instruction(encoding & 0xffffu);
    instruction->length = 2;
    (void)rv_decode_compressed_instruction(
        encoding & 0xffffu, instruction);
    /*
     * C owns the complete 16-bit encoding space.  Reserved, custom and
     * unimplemented code points stay as an ILLEGAL descriptor and trap through
     * the same path; they must never be interpreted as a 32-bit instruction.
     */
    return;
  }
#endif

  *instruction = rv_decoded_instruction(encoding);
  switch (OPCODE(encoding)) {
    case OPC_OP_IMM:
      (void)rv_decode_integer_immediate(encoding, instruction);
      return;
    case OPC_OP_IMM_32:
      (void)rv_decode_integer_immediate_word(encoding, instruction);
      return;
    case OPC_OP:
      (void)rv_decode_integer_register(encoding, instruction);
      return;
    case OPC_OP_32:
      (void)rv_decode_integer_register_word(encoding, instruction);
      return;
    case OPC_LOAD:
      (void)rv_decode_load(encoding, instruction);
      return;
    case OPC_STORE:
      (void)rv_decode_store(encoding, instruction);
      return;
    case OPC_BRANCH:
      (void)rv_decode_branch(encoding, instruction);
      return;
    case OPC_JAL:
    case OPC_JALR:
      (void)rv_decode_jump(encoding, instruction);
      return;
    case OPC_MISC_MEM:
      (void)rv_decode_memory_ordering(encoding, instruction);
      return;
    case OPC_LOAD_FP:
    case OPC_STORE_FP:
    case OPC_MADD:
    case OPC_MSUB:
    case OPC_NMSUB:
    case OPC_NMADD:
    case OPC_OP_FP:
      /* F/D opcodes are wholly owned by the shared manual decoder. */
      (void)rv_decode_floating(encoding, instruction);
      return;
    case OPC_SYSTEM:
      /* SYSTEM is wholly owned by the shared decoder, including illegal encodings. */
      (void)rv_decode_system(encoding, instruction);
      return;
    case OPC_AMO:
#ifdef CONFIG_RISCV_EXT_A
      if (riscv_atomic_decode(encoding, 64, &instruction->atomic)) {
        instruction->instruction_class = RV_INSTRUCTION_CLASS_ATOMIC;
        instruction->operation = RV_OPERATION_ATOMIC;
      }
#endif
      /* AMO opcode 已由共享手册译码器完整认领。 */
      return;
    case OPC_LUI:
      instruction->instruction_class =
          RV_INSTRUCTION_CLASS_UPPER_IMMEDIATE;
      instruction->operation = RV_OPERATION_LUI;
      instruction->immediate = IMM_U(encoding);
      return;
    case OPC_AUIPC:
      instruction->instruction_class =
          RV_INSTRUCTION_CLASS_UPPER_IMMEDIATE;
      instruction->operation = RV_OPERATION_AUIPC;
      instruction->immediate = IMM_U(encoding);
      return;
    default:
      return;
  }
}

static inline int execute_current_instruction(Decode *state) {
  RvDecodedInstruction instruction;
  if (!rv_decode_cache_lookup(state->pc, state->isa.inst, &instruction)) {
    rv_decode_instruction(state->isa.inst, &instruction);
    rv_decode_cache_insert(state->pc, &instruction);
  }

  if (!rv_execute_decoded_instruction(state, &instruction)) {
    raise_illegal_instruction_exception(state, state->isa.inst);
  }
  /* Architectural x0 is hard-wired even across shared extension helpers. */
  R(0) = 0;
  return 0;
}

static bool __attribute__((noinline, cold)) take_vaddr_fault_slow(Decode *s) {
  word_t cause;
  vaddr_t tval;
  if (!vaddr_take_fault(&cause, &tval)) return false;
  s->dnpc = isa_raise_intr_with_tval(cause, s->pc, tval);
  R(0) = 0;
  return true;
}

static inline bool take_vaddr_fault(Decode *s) {
  if (likely(!vaddr_has_fault())) return false;
  return take_vaddr_fault_slow(s);
}

int isa_exec_once(Decode *s) {
  /*
   * Counter retirement is a per-instruction transaction.  Start it before
   * instruction fetch so an instruction-access fault is attributed to this
   * attempt, while an asynchronous interrupt taken at the preceding TB
   * boundary is kept outside the transaction.
   */
  isa_riscv64_begin_exec();
#ifdef CONFIG_RISCV_EXT_C
  VaddrIfetchWideResult wide = vaddr_ifetch_wide(s->snpc);
  if (wide != VADDR_IFETCH_WIDE_MISS) {
    if (take_vaddr_fault(s)) {
      s->isa.inst = 0;
      return 0;
    }
    int inst_len = vaddr_ifetch_wide_len(wide);
    s->isa.inst = vaddr_ifetch_wide_inst(wide);
    if (inst_len == 2) s->isa.inst &= UINT32_C(0xffff);
    s->snpc += inst_len;
    syscall_debug_log_user_pc(s->pc, s->isa.inst);
    int ret = execute_current_instruction(s);
    take_vaddr_fault(s);
    return ret;
  }

  uint32_t inst = inst_fetch(&s->snpc, 2);
  if (take_vaddr_fault(s)) {
    s->isa.inst = 0;
    return 0;
  }
  if ((inst & 0x3) == 0x3) {
    inst |= inst_fetch(&s->snpc, 2) << 16;
    if (take_vaddr_fault(s)) {
      s->isa.inst = 0;
      return 0;
    }
  }
  s->isa.inst = inst;
#else
  s->isa.inst = inst_fetch(&s->snpc, 4);
  if (take_vaddr_fault(s)) return 0;
#endif
  syscall_debug_log_user_pc(s->pc, s->isa.inst);
  int ret = execute_current_instruction(s);
  take_vaddr_fault(s);
  return ret;
}
