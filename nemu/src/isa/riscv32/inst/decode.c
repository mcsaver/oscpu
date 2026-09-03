/* RV32 纯译码：只把原始编码映射为手册助记符描述符。 */

static inline Rv32DecodedInstruction rv32_empty_decoded_instruction(
    uint32_t encoding) {
  return (Rv32DecodedInstruction) {
    .encoding = encoding,
    .immediate = 0,
    .instruction_class = RV32_INSTRUCTION_CLASS_ILLEGAL,
    .operation = RV32_OPERATION_ILLEGAL_INSTRUCTION,
    .length = 4,
    .rd = RD(encoding),
    .rs1 = RS1(encoding),
    .rs2 = RS2(encoding),
    .x_register_operands = RV32_X_OPERAND_NONE,
  };
}

static inline bool rv32_decoded_x_registers_exist(
    const Rv32DecodedInstruction *instruction) {
#ifdef CONFIG_RVE
  if ((instruction->x_register_operands & RV32_X_OPERAND_RD) != 0 &&
      instruction->rd >= 16) return false;
  if ((instruction->x_register_operands & RV32_X_OPERAND_RS1) != 0 &&
      instruction->rs1 >= 16) return false;
  if ((instruction->x_register_operands & RV32_X_OPERAND_RS2) != 0 &&
      instruction->rs2 >= 16) return false;
#else
  (void)instruction;
#endif
  return true;
}

static inline void rv32_assign_operation(
    Rv32DecodedInstruction *instruction,
    Rv32InstructionClass instruction_class,
    Rv32Operation operation,
    uint8_t x_register_operands) {
  instruction->instruction_class = instruction_class;
  instruction->operation = operation;
  instruction->x_register_operands = x_register_operands;

  if (!rv32_decoded_x_registers_exist(instruction)) {
    instruction->instruction_class = RV32_INSTRUCTION_CLASS_ILLEGAL;
    instruction->operation = RV32_OPERATION_ILLEGAL_INSTRUCTION;
  }
}

static inline bool rv32_decode_integer_immediate(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  const uint32_t funct3 = FUNCT3(encoding);
  const uint32_t funct7 = FUNCT7(encoding);
  word_t immediate = IMM_I(encoding);
  Rv32Operation operation;

  switch (funct3) {
    case 0x0: operation = RV32_OPERATION_ADDI; break;
    case 0x2: operation = RV32_OPERATION_SLTI; break;
    case 0x3: operation = RV32_OPERATION_SLTIU; break;
    case 0x4: operation = RV32_OPERATION_XORI; break;
    case 0x6: operation = RV32_OPERATION_ORI; break;
    case 0x7: operation = RV32_OPERATION_ANDI; break;
    case 0x1:
      if (funct7 != 0x00) return false;
      operation = RV32_OPERATION_SLLI;
      immediate = BITS(encoding, 24, 20);
      break;
    case 0x5:
      if (funct7 == 0x00) operation = RV32_OPERATION_SRLI;
      else if (funct7 == 0x20) operation = RV32_OPERATION_SRAI;
      else return false;
      immediate = BITS(encoding, 24, 20);
      break;
    default:
      return false;
  }

  instruction->immediate = immediate;
  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_INTEGER_IMMEDIATE, operation,
      RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1);
  return true;
}

static inline bool rv32_decode_integer_register(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  Rv32Operation operation;

  switch (OP_KEY(FUNCT3(encoding), FUNCT7(encoding))) {
    case OP_KEY(0x0, 0x00): operation = RV32_OPERATION_ADD; break;
    case OP_KEY(0x0, 0x20): operation = RV32_OPERATION_SUB; break;
    case OP_KEY(0x1, 0x00): operation = RV32_OPERATION_SLL; break;
    case OP_KEY(0x2, 0x00): operation = RV32_OPERATION_SLT; break;
    case OP_KEY(0x3, 0x00): operation = RV32_OPERATION_SLTU; break;
    case OP_KEY(0x4, 0x00): operation = RV32_OPERATION_XOR; break;
    case OP_KEY(0x5, 0x00): operation = RV32_OPERATION_SRL; break;
    case OP_KEY(0x5, 0x20): operation = RV32_OPERATION_SRA; break;
    case OP_KEY(0x6, 0x00): operation = RV32_OPERATION_OR; break;
    case OP_KEY(0x7, 0x00): operation = RV32_OPERATION_AND; break;
    default: return false;
  }

  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_INTEGER_REGISTER, operation,
      RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1 | RV32_X_OPERAND_RS2);
  return true;
}

#ifdef CONFIG_RISCV_EXT_M
static inline void rv32_decode_multiply_divide(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  Rv32Operation operation;

  switch (FUNCT3(encoding)) {
    case 0x0: operation = RV32_OPERATION_MUL; break;
    case 0x1: operation = RV32_OPERATION_MULH; break;
    case 0x2: operation = RV32_OPERATION_MULHSU; break;
    case 0x3: operation = RV32_OPERATION_MULHU; break;
    case 0x4: operation = RV32_OPERATION_DIV; break;
    case 0x5: operation = RV32_OPERATION_DIVU; break;
    case 0x6: operation = RV32_OPERATION_REM; break;
    case 0x7: operation = RV32_OPERATION_REMU; break;
    default: return;
  }

  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_MULTIPLY_DIVIDE, operation,
      RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1 | RV32_X_OPERAND_RS2);
}
#endif

#ifdef CONFIG_RISCV_EXT_B
static inline bool rv32_decode_bitmanip_immediate(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  Rv32Operation operation = RV32_OPERATION_ILLEGAL_INSTRUCTION;

  /* 五位立即数编码的 mask 包含 bit25，拒绝 RV64 的第六位位号。 */
  switch (encoding & 0xfe00707fu) {
    case 0x28001013u: operation = RV32_OPERATION_BSETI; break;
    case 0x48001013u: operation = RV32_OPERATION_BCLRI; break;
    case 0x68001013u: operation = RV32_OPERATION_BINVI; break;
    case 0x48005013u: operation = RV32_OPERATION_BEXTI; break;
    case 0x60005013u: operation = RV32_OPERATION_RORI; break;
    default: break;
  }

  if (operation == RV32_OPERATION_ILLEGAL_INSTRUCTION) {
    /* 一元指令的 selector 是固定编码字段，不是动态位号。 */
    switch (encoding & 0xfff0707fu) {
      case 0x60001013u: operation = RV32_OPERATION_CLZ; break;
      case 0x60101013u: operation = RV32_OPERATION_CTZ; break;
      case 0x60201013u: operation = RV32_OPERATION_CPOP; break;
      case 0x60401013u: operation = RV32_OPERATION_SEXT_B; break;
      case 0x60501013u: operation = RV32_OPERATION_SEXT_H; break;
      case 0x28705013u: operation = RV32_OPERATION_ORC_B; break;
      case 0x69805013u: operation = RV32_OPERATION_REV8; break;
      default: return false;
    }
  }

  instruction->immediate = BITS(encoding, 24, 20);
  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_BIT_MANIPULATION, operation,
      RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1);
  return true;
}

static inline bool rv32_decode_bitmanip_register(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  Rv32Operation operation;
  uint8_t operands =
      RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1 | RV32_X_OPERAND_RS2;

  /* zext.h 的 rs2=x0 是固定字段，不能作为动态第三源。 */
  if ((encoding & 0xfff0707fu) == 0x08004033u) {
    operation = RV32_OPERATION_ZEXT_H;
    operands = RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1;
  } else {
    switch (encoding & 0xfe00707fu) {
      case 0x20002033u: operation = RV32_OPERATION_SH1ADD; break;
      case 0x20004033u: operation = RV32_OPERATION_SH2ADD; break;
      case 0x20006033u: operation = RV32_OPERATION_SH3ADD; break;
      case 0x40007033u: operation = RV32_OPERATION_ANDN; break;
      case 0x40006033u: operation = RV32_OPERATION_ORN; break;
      case 0x40004033u: operation = RV32_OPERATION_XNOR; break;
      case 0x60001033u: operation = RV32_OPERATION_ROL; break;
      case 0x60005033u: operation = RV32_OPERATION_ROR; break;
      case 0x0a004033u: operation = RV32_OPERATION_MIN; break;
      case 0x0a005033u: operation = RV32_OPERATION_MINU; break;
      case 0x0a006033u: operation = RV32_OPERATION_MAX; break;
      case 0x0a007033u: operation = RV32_OPERATION_MAXU; break;
      case 0x0a001033u: operation = RV32_OPERATION_CLMUL; break;
      case 0x0a002033u: operation = RV32_OPERATION_CLMULR; break;
      case 0x0a003033u: operation = RV32_OPERATION_CLMULH; break;
      case 0x28001033u: operation = RV32_OPERATION_BSET; break;
      case 0x48001033u: operation = RV32_OPERATION_BCLR; break;
      case 0x48005033u: operation = RV32_OPERATION_BEXT; break;
      case 0x68001033u: operation = RV32_OPERATION_BINV; break;
      default: return false;
    }
  }

  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_BIT_MANIPULATION,
      operation, operands);
  return true;
}
#endif

static inline bool rv32_decode_load(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  Rv32Operation operation;

  instruction->immediate = IMM_I(encoding);
  switch (FUNCT3(encoding)) {
    case 0x0: operation = RV32_OPERATION_LB; break;
    case 0x1: operation = RV32_OPERATION_LH; break;
    case 0x2: operation = RV32_OPERATION_LW; break;
    case 0x4: operation = RV32_OPERATION_LBU; break;
    case 0x5: operation = RV32_OPERATION_LHU; break;
    default: return false;
  }

  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_LOAD, operation,
      RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1);
  return true;
}

static inline bool rv32_decode_store(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  Rv32Operation operation;

  instruction->immediate = IMM_S(encoding);
  switch (FUNCT3(encoding)) {
    case 0x0: operation = RV32_OPERATION_SB; break;
    case 0x1: operation = RV32_OPERATION_SH; break;
    case 0x2: operation = RV32_OPERATION_SW; break;
    default: return false;
  }

  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_STORE, operation,
      RV32_X_OPERAND_RS1 | RV32_X_OPERAND_RS2);
  return true;
}

static inline bool rv32_decode_branch(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  Rv32Operation operation;

  instruction->immediate = IMM_B(encoding);
  switch (FUNCT3(encoding)) {
    case 0x0: operation = RV32_OPERATION_BEQ; break;
    case 0x1: operation = RV32_OPERATION_BNE; break;
    case 0x4: operation = RV32_OPERATION_BLT; break;
    case 0x5: operation = RV32_OPERATION_BGE; break;
    case 0x6: operation = RV32_OPERATION_BLTU; break;
    case 0x7: operation = RV32_OPERATION_BGEU; break;
    default: return false;
  }

  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_BRANCH, operation,
      RV32_X_OPERAND_RS1 | RV32_X_OPERAND_RS2);
  return true;
}

static inline bool rv32_decode_jump(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  switch (OPCODE(encoding)) {
    case OPC_JAL:
      instruction->immediate = IMM_J(encoding);
      rv32_assign_operation(
          instruction, RV32_INSTRUCTION_CLASS_JUMP, RV32_OPERATION_JAL,
          RV32_X_OPERAND_RD);
      return true;
    case OPC_JALR:
      if (FUNCT3(encoding) != 0x0) return false;
      instruction->immediate = IMM_I(encoding);
      rv32_assign_operation(
          instruction, RV32_INSTRUCTION_CLASS_JUMP, RV32_OPERATION_JALR,
          RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1);
      return true;
    default:
      return false;
  }
}

static inline bool rv32_decode_memory_ordering(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  switch (FUNCT3(encoding)) {
    case 0x0:
      rv32_assign_operation(
          instruction, RV32_INSTRUCTION_CLASS_MEMORY_ORDERING,
          RV32_OPERATION_FENCE, RV32_X_OPERAND_NONE);
      return true;
    case 0x1:
      rv32_assign_operation(
          instruction, RV32_INSTRUCTION_CLASS_MEMORY_ORDERING,
          RV32_OPERATION_FENCE_I, RV32_X_OPERAND_NONE);
      return true;
    default:
      return false;
  }
}

static inline bool rv32_decode_system(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  RiscvSystemInstruction system;
  if (!riscv_decode_system_instruction(encoding, &system)) return false;

  uint8_t operands = RV32_X_OPERAND_NONE;
  if (riscv_system_operation_is_csr(system.operation)) {
    operands |= RV32_X_OPERAND_RD;
    if (system.csr.source_kind == RISCV_CSR_SOURCE_REGISTER) {
      operands |= RV32_X_OPERAND_RS1;
    }
  } else if (system.operation == RISCV_SYSTEM_OPERATION_SFENCE_VMA) {
    operands = RV32_X_OPERAND_RS1 | RV32_X_OPERAND_RS2;
  }

  instruction->system = system;
  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_SYSTEM,
      RV32_OPERATION_SYSTEM, operands);
  return instruction->instruction_class == RV32_INSTRUCTION_CLASS_SYSTEM;
}

static inline bool rv32_decode_floating(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  RiscvFloatingInstruction floating;
  if (!riscv_decode_floating_instruction(
          encoding, 32, ISDEF(CONFIG_RVE) ? 16 : 32,
          ISDEF(CONFIG_RISCV_EXT_F), ISDEF(CONFIG_RISCV_EXT_D),
          &floating)) {
    return false;
  }
  instruction->floating = floating;
  instruction->immediate = (word_t)floating.immediate;
  instruction->rd = floating.rd;
  instruction->rs1 = floating.rs1;
  instruction->rs2 = floating.rs2;
  rv32_assign_operation(
      instruction, RV32_INSTRUCTION_CLASS_FLOATING_POINT,
      RV32_OPERATION_FLOATING, RV32_X_OPERAND_NONE);
  return true;
}

static inline void rv32_decode_instruction(
    uint32_t encoding, Rv32DecodedInstruction *instruction) {
  *instruction = rv32_empty_decoded_instruction(encoding);

#ifdef CONFIG_RISCV_EXT_C
  if ((encoding & 0x3u) != 0x3u) {
    instruction->length = 2;
    RiscvCompressedInstruction compressed;
    if (!riscv_decode_compressed_instruction(
            (uint16_t)encoding, 32,
            ISDEF(CONFIG_RVE) ? 16 : 32,
            ISDEF(CONFIG_RISCV_EXT_F), ISDEF(CONFIG_RISCV_EXT_D),
            &compressed)) {
      return;
    }
    instruction->compressed = compressed;
    instruction->immediate = (word_t)compressed.immediate;
    instruction->rd = compressed.rd;
    instruction->rs1 = compressed.rs1;
    instruction->rs2 = compressed.rs2;
    rv32_assign_operation(
        instruction, RV32_INSTRUCTION_CLASS_COMPRESSED,
        RV32_OPERATION_COMPRESSED, RV32_X_OPERAND_NONE);
    return;
  }
#endif

  switch (OPCODE(encoding)) {
    case OPC_OP_IMM:
      if (rv32_decode_integer_immediate(encoding, instruction)) return;
#ifdef CONFIG_RISCV_EXT_B
      (void)rv32_decode_bitmanip_immediate(encoding, instruction);
#endif
      return;
    case OPC_OP:
      if (rv32_decode_integer_register(encoding, instruction)) return;
      /* funct7=1 整组属于 M；扩展关闭时保持初始非法描述符。 */
      if (FUNCT7(encoding) == 0x01) {
#ifdef CONFIG_RISCV_EXT_M
        rv32_decode_multiply_divide(encoding, instruction);
#endif
        return;
      }
#ifdef CONFIG_RISCV_EXT_B
      (void)rv32_decode_bitmanip_register(encoding, instruction);
#endif
      return;
    case OPC_LOAD:
      (void)rv32_decode_load(encoding, instruction);
      return;
    case OPC_STORE:
      (void)rv32_decode_store(encoding, instruction);
      return;
    case OPC_BRANCH:
      (void)rv32_decode_branch(encoding, instruction);
      return;
    case OPC_JAL:
    case OPC_JALR:
      (void)rv32_decode_jump(encoding, instruction);
      return;
    case OPC_LUI:
      instruction->immediate = IMM_U(encoding);
      rv32_assign_operation(
          instruction, RV32_INSTRUCTION_CLASS_UPPER_IMMEDIATE,
          RV32_OPERATION_LUI, RV32_X_OPERAND_RD);
      return;
    case OPC_AUIPC:
      instruction->immediate = IMM_U(encoding);
      rv32_assign_operation(
          instruction, RV32_INSTRUCTION_CLASS_UPPER_IMMEDIATE,
          RV32_OPERATION_AUIPC, RV32_X_OPERAND_RD);
      return;
    case OPC_MISC_MEM:
      (void)rv32_decode_memory_ordering(encoding, instruction);
      return;
    case OPC_LOAD_FP:
    case OPC_STORE_FP:
    case OPC_MADD:
    case OPC_MSUB:
    case OPC_NMSUB:
    case OPC_NMADD:
    case OPC_OP_FP:
      (void)rv32_decode_floating(encoding, instruction);
      return;
    case OPC_AMO: {
#ifdef CONFIG_RISCV_EXT_A
      if (!riscv_atomic_decode(encoding, 32, &instruction->atomic)) return;
      uint8_t operands = RV32_X_OPERAND_RD | RV32_X_OPERAND_RS1;
      if (!riscv_atomic_is_load_reserved(&instruction->atomic)) {
        operands |= RV32_X_OPERAND_RS2;
      }
      rv32_assign_operation(
          instruction, RV32_INSTRUCTION_CLASS_ATOMIC,
          RV32_OPERATION_ATOMIC, operands);
#endif
      return;
    }
    case OPC_SYSTEM:
      (void)rv32_decode_system(encoding, instruction);
      return;
    default:
      return;
  }
}
