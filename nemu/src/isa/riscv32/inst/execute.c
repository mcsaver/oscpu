/* 已译码 RV32 指令的唯一体系结构执行入口。 */

static inline word_t rv32_read_x_register(uint8_t index) {
  return R(index);
}

static inline void rv32_write_x_register(uint8_t index, word_t value) {
  if (index != 0) R(index) = value;
}

static inline bool rv32_instruction_target_valid(vaddr_t target) {
#ifdef CONFIG_RISCV_EXT_C
  const vaddr_t alignment_mask = 0x1u;
#else
  const vaddr_t alignment_mask = 0x3u;
#endif
  if ((target & alignment_mask) == 0) return true;
  vaddr_set_fault(CAUSE_INST_MISALIGNED, target);
  return false;
}

static inline bool rv32_execute_integer_immediate(
    const Rv32DecodedInstruction *instruction) {
  const word_t source = rv32_read_x_register(instruction->rs1);
  const word_t immediate = instruction->immediate;

  switch (instruction->operation) {
    case RV32_OPERATION_ADDI:
      rv32_write_x_register(instruction->rd, source + immediate);
      return true;
    case RV32_OPERATION_SLTI:
      rv32_write_x_register(
          instruction->rd, (sword_t)source < (sword_t)immediate);
      return true;
    case RV32_OPERATION_SLTIU:
      rv32_write_x_register(instruction->rd, source < immediate);
      return true;
    case RV32_OPERATION_XORI:
      rv32_write_x_register(instruction->rd, source ^ immediate);
      return true;
    case RV32_OPERATION_ORI:
      rv32_write_x_register(instruction->rd, source | immediate);
      return true;
    case RV32_OPERATION_ANDI:
      rv32_write_x_register(instruction->rd, source & immediate);
      return true;
    case RV32_OPERATION_SLLI:
      rv32_write_x_register(instruction->rd, source << immediate);
      return true;
    case RV32_OPERATION_SRLI:
      rv32_write_x_register(instruction->rd, source >> immediate);
      return true;
    case RV32_OPERATION_SRAI:
      rv32_write_x_register(
          instruction->rd, (sword_t)source >> immediate);
      return true;
    default:
      return false;
  }
}

static inline bool rv32_execute_integer_register(
    const Rv32DecodedInstruction *instruction) {
  const word_t lhs = rv32_read_x_register(instruction->rs1);
  const word_t rhs = rv32_read_x_register(instruction->rs2);

  switch (instruction->operation) {
    case RV32_OPERATION_ADD:
      rv32_write_x_register(instruction->rd, lhs + rhs);
      return true;
    case RV32_OPERATION_SUB:
      rv32_write_x_register(instruction->rd, lhs - rhs);
      return true;
    case RV32_OPERATION_SLL:
      rv32_write_x_register(instruction->rd, lhs << SHAMT_XLEN(rhs));
      return true;
    case RV32_OPERATION_SLT:
      rv32_write_x_register(
          instruction->rd, (sword_t)lhs < (sword_t)rhs);
      return true;
    case RV32_OPERATION_SLTU:
      rv32_write_x_register(instruction->rd, lhs < rhs);
      return true;
    case RV32_OPERATION_XOR:
      rv32_write_x_register(instruction->rd, lhs ^ rhs);
      return true;
    case RV32_OPERATION_SRL:
      rv32_write_x_register(instruction->rd, lhs >> SHAMT_XLEN(rhs));
      return true;
    case RV32_OPERATION_SRA:
      rv32_write_x_register(
          instruction->rd, (sword_t)lhs >> SHAMT_XLEN(rhs));
      return true;
    case RV32_OPERATION_OR:
      rv32_write_x_register(instruction->rd, lhs | rhs);
      return true;
    case RV32_OPERATION_AND:
      rv32_write_x_register(instruction->rd, lhs & rhs);
      return true;
    default:
      return false;
  }
}

static inline bool rv32_execute_multiply_divide(
    const Rv32DecodedInstruction *instruction) {
  const word_t lhs = rv32_read_x_register(instruction->rs1);
  const word_t rhs = rv32_read_x_register(instruction->rs2);
  word_t result;

  if (!rv32_multiply_divide_result(
          instruction->operation, lhs, rhs, &result)) return false;
  rv32_write_x_register(instruction->rd, result);
  return true;
}

static inline bool rv32_execute_bit_manipulation(
    const Rv32DecodedInstruction *instruction) {
  const word_t lhs = rv32_read_x_register(instruction->rs1);
  word_t rhs_or_shamt = instruction->immediate;
  word_t result;

  if ((instruction->x_register_operands & RV32_X_OPERAND_RS2) != 0) {
    rhs_or_shamt = rv32_read_x_register(instruction->rs2);
  }
  if (!rv32_bitmanip_result(
          instruction->operation, lhs, rhs_or_shamt, &result)) return false;
  rv32_write_x_register(instruction->rd, result);
  return true;
}

typedef enum {
  RV32_MEMORY_WIDTH_BYTE = 1,
  RV32_MEMORY_WIDTH_HALFWORD = 2,
  RV32_MEMORY_WIDTH_WORD = 4,
} Rv32MemoryWidth;

typedef enum {
  RV32_LOAD_SIGN_EXTEND,
  RV32_LOAD_ZERO_EXTEND,
} Rv32LoadExtension;

static inline word_t rv32_extend_loaded_value(
    word_t loaded_bits, Rv32MemoryWidth width,
    Rv32LoadExtension extension) {
  if (extension == RV32_LOAD_ZERO_EXTEND) return loaded_bits;
  switch (width) {
    case RV32_MEMORY_WIDTH_BYTE: return SEXT(loaded_bits, 8);
    case RV32_MEMORY_WIDTH_HALFWORD: return SEXT(loaded_bits, 16);
    case RV32_MEMORY_WIDTH_WORD: return loaded_bits;
    default: return loaded_bits;
  }
}

static inline bool rv32_execute_load_with_semantics(
    const Rv32DecodedInstruction *instruction, Rv32MemoryWidth width,
    Rv32LoadExtension extension) {
  const vaddr_t effective_address =
      rv32_read_x_register(instruction->rs1) + instruction->immediate;
  const word_t loaded_bits = vaddr_read(effective_address, (int)width);

  /* 访存异常先于目的寄存器提交。 */
  if (vaddr_has_fault()) return true;
  rv32_write_x_register(
      instruction->rd,
      rv32_extend_loaded_value(loaded_bits, width, extension));
  return true;
}

static inline bool rv32_execute_load(
    const Rv32DecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV32_OPERATION_LB:
      return rv32_execute_load_with_semantics(
          instruction, RV32_MEMORY_WIDTH_BYTE, RV32_LOAD_SIGN_EXTEND);
    case RV32_OPERATION_LH:
      return rv32_execute_load_with_semantics(
          instruction, RV32_MEMORY_WIDTH_HALFWORD, RV32_LOAD_SIGN_EXTEND);
    case RV32_OPERATION_LW:
      return rv32_execute_load_with_semantics(
          instruction, RV32_MEMORY_WIDTH_WORD, RV32_LOAD_SIGN_EXTEND);
    case RV32_OPERATION_LBU:
      return rv32_execute_load_with_semantics(
          instruction, RV32_MEMORY_WIDTH_BYTE, RV32_LOAD_ZERO_EXTEND);
    case RV32_OPERATION_LHU:
      return rv32_execute_load_with_semantics(
          instruction, RV32_MEMORY_WIDTH_HALFWORD, RV32_LOAD_ZERO_EXTEND);
    default:
      return false;
  }
}

static inline bool rv32_execute_store_with_width(
    const Rv32DecodedInstruction *instruction, Rv32MemoryWidth width) {
  const vaddr_t effective_address =
      rv32_read_x_register(instruction->rs1) + instruction->immediate;
  const word_t source = rv32_read_x_register(instruction->rs2);
  vaddr_write(effective_address, (int)width, source);
  return true;
}

static inline bool rv32_execute_store(
    const Rv32DecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV32_OPERATION_SB:
      return rv32_execute_store_with_width(
          instruction, RV32_MEMORY_WIDTH_BYTE);
    case RV32_OPERATION_SH:
      return rv32_execute_store_with_width(
          instruction, RV32_MEMORY_WIDTH_HALFWORD);
    case RV32_OPERATION_SW:
      return rv32_execute_store_with_width(
          instruction, RV32_MEMORY_WIDTH_WORD);
    default:
      return false;
  }
}

static inline bool rv32_execute_branch(
    Decode *state, const Rv32DecodedInstruction *instruction) {
  const word_t lhs = rv32_read_x_register(instruction->rs1);
  const word_t rhs = rv32_read_x_register(instruction->rs2);
  bool condition_holds;

  switch (instruction->operation) {
    case RV32_OPERATION_BEQ: condition_holds = lhs == rhs; break;
    case RV32_OPERATION_BNE: condition_holds = lhs != rhs; break;
    case RV32_OPERATION_BLT:
      condition_holds = (sword_t)lhs < (sword_t)rhs;
      break;
    case RV32_OPERATION_BGE:
      condition_holds = (sword_t)lhs >= (sword_t)rhs;
      break;
    case RV32_OPERATION_BLTU: condition_holds = lhs < rhs; break;
    case RV32_OPERATION_BGEU: condition_holds = lhs >= rhs; break;
    default: return false;
  }

  if (!condition_holds) return true;
  const vaddr_t target = state->pc + instruction->immediate;
  if (!rv32_instruction_target_valid(target)) return true;
  state->dnpc = target;
  return true;
}

static inline void rv32_trace_jump(
    Decode *state, const Rv32DecodedInstruction *instruction) {
  IFDEF(CONFIG_FTRACE, {
    if (instruction->operation == RV32_OPERATION_JALR &&
        instruction->rd == 0 && instruction->rs1 == 1) {
      ftrace_log(-1, state->pc, state->dnpc);
    } else if (instruction->rd == 1 || instruction->rd == 5) {
      ftrace_log(1, state->pc, state->dnpc);
    }
  })
}

static inline bool rv32_execute_jump(
    Decode *state, const Rv32DecodedInstruction *instruction) {
  const word_t return_address = state->pc + instruction->length;
  vaddr_t target;

  switch (instruction->operation) {
    case RV32_OPERATION_JAL:
      target = state->pc + instruction->immediate;
      break;
    case RV32_OPERATION_JALR:
      target =
          (rv32_read_x_register(instruction->rs1) +
           instruction->immediate) & ~(word_t)1;
      break;
    default:
      return false;
  }

  /* 目标地址异常先于 link、重定向和调用轨迹提交。 */
  if (!rv32_instruction_target_valid(target)) return true;
  rv32_write_x_register(instruction->rd, return_address);
  state->dnpc = target;
  rv32_trace_jump(state, instruction);
  return true;
}

static inline bool rv32_execute_upper_immediate(
    Decode *state, const Rv32DecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV32_OPERATION_LUI:
      rv32_write_x_register(instruction->rd, instruction->immediate);
      return true;
    case RV32_OPERATION_AUIPC:
      rv32_write_x_register(
          instruction->rd, state->pc + instruction->immediate);
      return true;
    default:
      return false;
  }
}

static inline bool rv32_execute_memory_ordering(
    const Rv32DecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV32_OPERATION_FENCE:
      /* 解释器中的体系结构访存按程序序完成。 */
      return true;
    case RV32_OPERATION_FENCE_I:
      IFDEF(CONFIG_CACHE, cache_flush_all());
      vaddr_ifetch_cache_flush();
      return true;
    default:
      return false;
  }
}

static inline bool rv32_execute_decoded_instruction(
    Decode *state, const Rv32DecodedInstruction *instruction) {
  state->dnpc = state->snpc;

  switch (instruction->instruction_class) {
    case RV32_INSTRUCTION_CLASS_INTEGER_IMMEDIATE:
      return rv32_execute_integer_immediate(instruction);
    case RV32_INSTRUCTION_CLASS_INTEGER_REGISTER:
      return rv32_execute_integer_register(instruction);
    case RV32_INSTRUCTION_CLASS_MULTIPLY_DIVIDE:
      return rv32_execute_multiply_divide(instruction);
    case RV32_INSTRUCTION_CLASS_BIT_MANIPULATION:
      return rv32_execute_bit_manipulation(instruction);
    case RV32_INSTRUCTION_CLASS_LOAD:
      return rv32_execute_load(instruction);
    case RV32_INSTRUCTION_CLASS_STORE:
      return rv32_execute_store(instruction);
    case RV32_INSTRUCTION_CLASS_BRANCH:
      return rv32_execute_branch(state, instruction);
    case RV32_INSTRUCTION_CLASS_JUMP:
      return rv32_execute_jump(state, instruction);
    case RV32_INSTRUCTION_CLASS_UPPER_IMMEDIATE:
      return rv32_execute_upper_immediate(state, instruction);
    case RV32_INSTRUCTION_CLASS_MEMORY_ORDERING:
      return rv32_execute_memory_ordering(instruction);
    case RV32_INSTRUCTION_CLASS_SYSTEM:
      return riscv32_execute_system(state, &instruction->system);
    case RV32_INSTRUCTION_CLASS_ATOMIC:
      return rv32_execute_atomic(instruction);
    case RV32_INSTRUCTION_CLASS_COMPRESSED:
      return rv32_execute_compressed(state, &instruction->compressed);
    case RV32_INSTRUCTION_CLASS_FLOATING_POINT:
      return exec_rvf_decoded(&instruction->floating);
    default:
      return false;
  }
}
