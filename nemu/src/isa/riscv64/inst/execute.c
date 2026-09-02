/*
 * 已译码 RV64 指令的唯一体系结构执行入口。
 *
 * 每个 case 使用手册 mnemonic；opcode/funct 字段只属于 decode.c。读取源操作数、
 * 计算结果和提交目的寄存器按规范顺序显式书写。尚未迁移的扩展不会进入本文件，
 * 而是由 decode.c 的具名 legacy 边界执行。
 */

#include <utils/profile.h>

static inline word_t rv_read_x_register(uint8_t index) {
  return R(index);
}

static inline void rv_write_x_register(uint8_t index, word_t value) {
  if (index != 0) R(index) = value;
}

static inline bool rv_execute_integer_immediate(
    const RvDecodedInstruction *instruction) {
  const word_t source = rv_read_x_register(instruction->rs1);
  const word_t immediate = instruction->immediate;

  switch (instruction->operation) {
    case RV_OPERATION_ADDI:
      rv_write_x_register(instruction->rd, source + immediate);
      return true;
    case RV_OPERATION_SLTI:
      rv_write_x_register(instruction->rd,
                          (sword_t)source < (sword_t)immediate);
      return true;
    case RV_OPERATION_SLTIU:
      rv_write_x_register(instruction->rd, source < immediate);
      return true;
    case RV_OPERATION_XORI:
      rv_write_x_register(instruction->rd, source ^ immediate);
      return true;
    case RV_OPERATION_ORI:
      rv_write_x_register(instruction->rd, source | immediate);
      return true;
    case RV_OPERATION_ANDI:
      rv_write_x_register(instruction->rd, source & immediate);
      return true;
    case RV_OPERATION_SLLI:
      rv_write_x_register(instruction->rd, source << immediate);
      return true;
    case RV_OPERATION_SRLI:
      rv_write_x_register(instruction->rd, source >> immediate);
      return true;
    case RV_OPERATION_SRAI:
      rv_write_x_register(instruction->rd, (sword_t)source >> immediate);
      return true;
    default:
      return false;
  }
}

static inline bool rv_execute_integer_immediate_word(
    const RvDecodedInstruction *instruction) {
  const uint32_t source = rv_read_x_register(instruction->rs1);
  const uint32_t shamt = instruction->immediate;

  switch (instruction->operation) {
    case RV_OPERATION_ADDIW:
      rv_write_x_register(
          instruction->rd,
          sext32(source + (uint32_t)instruction->immediate));
      return true;
    case RV_OPERATION_SLLIW:
      rv_write_x_register(instruction->rd, sext32(source << shamt));
      return true;
    case RV_OPERATION_SRLIW:
      rv_write_x_register(instruction->rd, sext32(source >> shamt));
      return true;
    case RV_OPERATION_SRAIW:
      rv_write_x_register(
          instruction->rd,
          sext32((uint32_t)((int32_t)source >> shamt)));
      return true;
    default:
      return false;
  }
}

static inline bool rv_execute_integer_register(
    const RvDecodedInstruction *instruction) {
  const word_t lhs = rv_read_x_register(instruction->rs1);
  const word_t rhs = rv_read_x_register(instruction->rs2);

  switch (instruction->operation) {
    case RV_OPERATION_ADD:
      rv_write_x_register(instruction->rd, lhs + rhs);
      return true;
    case RV_OPERATION_SUB:
      rv_write_x_register(instruction->rd, lhs - rhs);
      return true;
    case RV_OPERATION_SLL:
      rv_write_x_register(instruction->rd, lhs << SHAMT_XLEN(rhs));
      return true;
    case RV_OPERATION_SLT:
      rv_write_x_register(instruction->rd, (sword_t)lhs < (sword_t)rhs);
      return true;
    case RV_OPERATION_SLTU:
      rv_write_x_register(instruction->rd, lhs < rhs);
      return true;
    case RV_OPERATION_XOR:
      rv_write_x_register(instruction->rd, lhs ^ rhs);
      return true;
    case RV_OPERATION_SRL:
      rv_write_x_register(instruction->rd, lhs >> SHAMT_XLEN(rhs));
      return true;
    case RV_OPERATION_SRA:
      rv_write_x_register(instruction->rd,
                          (sword_t)lhs >> SHAMT_XLEN(rhs));
      return true;
    case RV_OPERATION_OR:
      rv_write_x_register(instruction->rd, lhs | rhs);
      return true;
    case RV_OPERATION_AND:
      rv_write_x_register(instruction->rd, lhs & rhs);
      return true;
    default:
      return false;
  }
}

static inline bool rv_execute_integer_register_word(
    const RvDecodedInstruction *instruction) {
  const uint32_t lhs = rv_read_x_register(instruction->rs1);
  const uint32_t rhs = rv_read_x_register(instruction->rs2);
  const uint32_t shamt = rhs & 0x1fu;

  switch (instruction->operation) {
    case RV_OPERATION_ADDW:
      rv_write_x_register(instruction->rd, sext32(lhs + rhs));
      return true;
    case RV_OPERATION_SUBW:
      rv_write_x_register(instruction->rd, sext32(lhs - rhs));
      return true;
    case RV_OPERATION_SLLW:
      rv_write_x_register(instruction->rd, sext32(lhs << shamt));
      return true;
    case RV_OPERATION_SRLW:
      rv_write_x_register(instruction->rd, sext32(lhs >> shamt));
      return true;
    case RV_OPERATION_SRAW:
      rv_write_x_register(
          instruction->rd,
          sext32((uint32_t)((int32_t)lhs >> shamt)));
      return true;
    default:
      return false;
  }
}

typedef enum {
  RV_MEMORY_WIDTH_BYTE = 1,
  RV_MEMORY_WIDTH_HALFWORD = 2,
  RV_MEMORY_WIDTH_WORD = 4,
  RV_MEMORY_WIDTH_DOUBLEWORD = 8,
} RvMemoryWidth;

typedef enum {
  RV_LOAD_SIGN_EXTEND,
  RV_LOAD_ZERO_EXTEND,
} RvLoadExtension;

static inline bool rv_memory_address_is_naturally_aligned(
    vaddr_t address, RvMemoryWidth width) {
  return (address & ((vaddr_t)width - 1)) == 0;
}

static inline bool rv_memory_access_crosses_page(
    vaddr_t address, RvMemoryWidth width) {
  const vaddr_t page_offset = address & (vaddr_t)PAGE_MASK;
  return page_offset + (vaddr_t)width > (vaddr_t)PAGE_SIZE;
}

/*
 * NEMU's scalar-memory EEI permits a misaligned access when it stays within
 * one translated page. A misaligned access that spans translated pages is
 * left to the guest's trap handler. The vaddr layer still owns translation,
 * page splitting and MMIO transaction semantics.
 */
static inline bool rv_scalar_access_requires_misaligned_exception(
    vaddr_t address, RvMemoryWidth width, int access_type) {
  if (rv_memory_address_is_naturally_aligned(address, width)) return false;
  if (isa_mmu_check(address, (int)width, access_type) != MMU_TRANSLATE) {
    return false;
  }
  return rv_memory_access_crosses_page(address, width);
}

static inline bool rv_set_misaligned_exception_if_required(
    vaddr_t address, RvMemoryWidth width, int access_type, word_t cause) {
  if (!rv_scalar_access_requires_misaligned_exception(
          address, width, access_type)) {
    return false;
  }
  vaddr_set_fault(cause, address);
  return true;
}

static inline word_t rv_extend_loaded_value(
    word_t loaded_bits, RvMemoryWidth width, RvLoadExtension extension) {
  if (extension == RV_LOAD_ZERO_EXTEND) return loaded_bits;

  switch (width) {
    case RV_MEMORY_WIDTH_BYTE: return SEXT(loaded_bits, 8);
    case RV_MEMORY_WIDTH_HALFWORD: return SEXT(loaded_bits, 16);
    case RV_MEMORY_WIDTH_WORD: return SEXT(loaded_bits, 32);
    case RV_MEMORY_WIDTH_DOUBLEWORD: return loaded_bits;
    default: return loaded_bits;
  }
}

static inline bool rv_execute_load_with_semantics(
    const RvDecodedInstruction *instruction, RvMemoryWidth width,
    RvLoadExtension extension) {
  /* LOAD: effective address = x[rs1] + sign-extended I-immediate. */
  const vaddr_t effective_address =
      rv_read_x_register(instruction->rs1) + instruction->immediate;

  if (rv_set_misaligned_exception_if_required(
          effective_address, width, MEM_TYPE_READ, CAUSE_LOAD_MISALIGNED)) {
    return true;
  }

  /* Exactly one architectural load transaction is issued to the vaddr layer. */
  const word_t loaded_bits = vaddr_read(effective_address, (int)width);

  /* A faulting load has no destination-register write, including rd != x0. */
  if (vaddr_has_fault()) return true;

  const word_t result =
      rv_extend_loaded_value(loaded_bits, width, extension);
  rv_write_x_register(instruction->rd, result);
  return true;
}

static inline bool rv_execute_load(
    const RvDecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV_OPERATION_LB:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_BYTE, RV_LOAD_SIGN_EXTEND);
    case RV_OPERATION_LH:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_HALFWORD, RV_LOAD_SIGN_EXTEND);
    case RV_OPERATION_LW:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_WORD, RV_LOAD_SIGN_EXTEND);
    case RV_OPERATION_LD:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_DOUBLEWORD, RV_LOAD_ZERO_EXTEND);
    case RV_OPERATION_LBU:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_BYTE, RV_LOAD_ZERO_EXTEND);
    case RV_OPERATION_LHU:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_HALFWORD, RV_LOAD_ZERO_EXTEND);
    case RV_OPERATION_LWU:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_WORD, RV_LOAD_ZERO_EXTEND);
    default:
      return false;
  }
}

static inline bool rv_execute_store_with_width(
    const RvDecodedInstruction *instruction, RvMemoryWidth width) {
  /* STORE: effective address = x[rs1] + sign-extended S-immediate. */
  const vaddr_t effective_address =
      rv_read_x_register(instruction->rs1) + instruction->immediate;
  const word_t source = rv_read_x_register(instruction->rs2);

  if (rv_set_misaligned_exception_if_required(
          effective_address, width, MEM_TYPE_WRITE, CAUSE_STORE_MISALIGNED)) {
    return true;
  }

  /* Width selects the low-order source bits; vaddr owns the whole transaction. */
  vaddr_write(effective_address, (int)width, source);
  if (vaddr_has_fault()) return true;
  return true;
}

static inline bool rv_execute_store(
    const RvDecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV_OPERATION_SB:
      return rv_execute_store_with_width(instruction, RV_MEMORY_WIDTH_BYTE);
    case RV_OPERATION_SH:
      return rv_execute_store_with_width(instruction, RV_MEMORY_WIDTH_HALFWORD);
    case RV_OPERATION_SW:
      return rv_execute_store_with_width(instruction, RV_MEMORY_WIDTH_WORD);
    case RV_OPERATION_SD:
      return rv_execute_store_with_width(
          instruction, RV_MEMORY_WIDTH_DOUBLEWORD);
    default:
      return false;
  }
}

static inline bool rv_execute_branch(
    Decode *state, const RvDecodedInstruction *instruction) {
  const word_t lhs = rv_read_x_register(instruction->rs1);
  const word_t rhs = rv_read_x_register(instruction->rs2);
  bool condition_holds;

  switch (instruction->operation) {
    case RV_OPERATION_BEQ:
      condition_holds = lhs == rhs;
      break;
    case RV_OPERATION_BNE:
      condition_holds = lhs != rhs;
      break;
    case RV_OPERATION_BLT:
      condition_holds = (sword_t)lhs < (sword_t)rhs;
      break;
    case RV_OPERATION_BGE:
      condition_holds = (sword_t)lhs >= (sword_t)rhs;
      break;
    case RV_OPERATION_BLTU:
      condition_holds = lhs < rhs;
      break;
    case RV_OPERATION_BGEU:
      condition_holds = lhs >= rhs;
      break;
    default:
      return false;
  }

  const vaddr_t sequential_pc = state->snpc;
  state->dnpc = sequential_pc;
  if (!condition_holds) return true;

  const vaddr_t target = state->pc + instruction->immediate;
  if (!rv_instruction_target_valid(target)) return true;
  state->dnpc = target;
  return true;
}

static inline void rv_trace_jump(
    Decode *state, const RvDecodedInstruction *instruction) {
  IFDEF(CONFIG_FTRACE, {
    if (instruction->operation == RV_OPERATION_JALR &&
        instruction->rd == 0 && instruction->rs1 == 1) {
      ftrace_log(-1, state->pc, state->dnpc);
    } else if (instruction->rd == 1 || instruction->rd == 5) {
      ftrace_log(1, state->pc, state->dnpc);
    }
  })
}

static inline bool rv_execute_jump(
    Decode *state, const RvDecodedInstruction *instruction) {
  const vaddr_t sequential_pc = state->snpc;
  const word_t return_address = state->pc + instruction->length;
  vaddr_t target;

  state->dnpc = sequential_pc;
  switch (instruction->operation) {
    case RV_OPERATION_JAL:
      target = state->pc + instruction->immediate;
      break;
    case RV_OPERATION_JALR: {
      const word_t base_address =
          rv_read_x_register(instruction->rs1);
      /* JALR forms the target first, then clears bit 0 as required by RV64I. */
      target = (base_address + instruction->immediate) & ~(word_t)1;
      break;
    }
    default:
      return false;
  }

  /* A misaligned target traps before rd, dnpc, or ftrace is committed. */
  if (!rv_instruction_target_valid(target)) return true;
  rv_write_x_register(instruction->rd, return_address);
  state->dnpc = target;
  rv_trace_jump(state, instruction);
  return true;
}

static inline bool rv_execute_upper_immediate(
    Decode *state, const RvDecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV_OPERATION_LUI:
      rv_write_x_register(instruction->rd, instruction->immediate);
      return true;
    case RV_OPERATION_AUIPC:
      rv_write_x_register(instruction->rd,
                          state->pc + instruction->immediate);
      return true;
    default:
      return false;
  }
}

static inline bool rv_execute_memory_ordering(
    const RvDecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV_OPERATION_FENCE:
      /* The interpreter completes memory operations in program order. */
      return true;
    case RV_OPERATION_FENCE_I:
      /* FENCE.I makes earlier stores visible to every instruction-fetch path. */
      IFDEF(CONFIG_CACHE, cache_flush_all());
      vaddr_ifetch_cache_flush();
      rv_decode_cache_flush();
      return true;
    default:
      return false;
  }
}

static inline word_t riscv_environment_call_cause(void) {
  switch (cpu.priv) {
    case PRIV_M: return CAUSE_ECALL_M;
    case PRIV_S: return CAUSE_ECALL_S;
    default: return CAUSE_ECALL_U;
  }
}

static inline bool rv_execute_environment_call(Decode *state) {
  syscall_debug_log_enter(state->pc);
  state->dnpc = isa_raise_intr(riscv_environment_call_cause(), state->pc);
  return true;
}

static inline bool rv_execute_breakpoint(Decode *state) {
  if (ebreak_should_raise_breakpoint_trap()) {
    state->dnpc = isa_raise_intr(CAUSE_BREAKPOINT, state->pc);
  } else {
    NEMUTRAP(state->pc, rv_read_x_register(10));
  }
  return true;
}

#ifdef CONFIG_RISCV_EXT_C
static inline NemuProfileCounter rv_compressed_profile_counter(
    RvOperation operation) {
  switch (operation) {
    case RV_OPERATION_C_ADDI4SPN: return NEMU_PROFILE_CPU_RVC_ADDI4SPN;
    case RV_OPERATION_C_FLD: return NEMU_PROFILE_CPU_RVC_FLD;
    case RV_OPERATION_C_LW: return NEMU_PROFILE_CPU_RVC_LW;
    case RV_OPERATION_C_LD: return NEMU_PROFILE_CPU_RVC_LD;
    case RV_OPERATION_C_FSD: return NEMU_PROFILE_CPU_RVC_FSD;
    case RV_OPERATION_C_SW: return NEMU_PROFILE_CPU_RVC_SW;
    case RV_OPERATION_C_SD: return NEMU_PROFILE_CPU_RVC_SD;
    case RV_OPERATION_C_ADDI: return NEMU_PROFILE_CPU_RVC_ADDI;
    case RV_OPERATION_C_ADDIW: return NEMU_PROFILE_CPU_RVC_ADDIW;
    case RV_OPERATION_C_LI: return NEMU_PROFILE_CPU_RVC_LI;
    case RV_OPERATION_C_ADDI16SP: return NEMU_PROFILE_CPU_RVC_ADDI16SP;
    case RV_OPERATION_C_LUI: return NEMU_PROFILE_CPU_RVC_LUI;
    case RV_OPERATION_C_SRLI: return NEMU_PROFILE_CPU_RVC_SRLI;
    case RV_OPERATION_C_SRAI: return NEMU_PROFILE_CPU_RVC_SRAI;
    case RV_OPERATION_C_ANDI: return NEMU_PROFILE_CPU_RVC_ANDI;
    case RV_OPERATION_C_SUB: return NEMU_PROFILE_CPU_RVC_SUB;
    case RV_OPERATION_C_XOR: return NEMU_PROFILE_CPU_RVC_XOR;
    case RV_OPERATION_C_OR: return NEMU_PROFILE_CPU_RVC_OR;
    case RV_OPERATION_C_AND: return NEMU_PROFILE_CPU_RVC_AND;
    case RV_OPERATION_C_SUBW: return NEMU_PROFILE_CPU_RVC_SUBW;
    case RV_OPERATION_C_ADDW: return NEMU_PROFILE_CPU_RVC_ADDW;
    case RV_OPERATION_C_J: return NEMU_PROFILE_CPU_RVC_J;
    case RV_OPERATION_C_BEQZ: return NEMU_PROFILE_CPU_RVC_BEQZ;
    case RV_OPERATION_C_BNEZ: return NEMU_PROFILE_CPU_RVC_BNEZ;
    case RV_OPERATION_C_SLLI: return NEMU_PROFILE_CPU_RVC_SLLI;
    case RV_OPERATION_C_FLDSP: return NEMU_PROFILE_CPU_RVC_FLDSP;
    case RV_OPERATION_C_LWSP: return NEMU_PROFILE_CPU_RVC_LWSP;
    case RV_OPERATION_C_LDSP: return NEMU_PROFILE_CPU_RVC_LDSP;
    case RV_OPERATION_C_JR: return NEMU_PROFILE_CPU_RVC_JR;
    case RV_OPERATION_C_MV: return NEMU_PROFILE_CPU_RVC_MV;
    case RV_OPERATION_C_EBREAK: return NEMU_PROFILE_CPU_RVC_EBREAK;
    case RV_OPERATION_C_JALR: return NEMU_PROFILE_CPU_RVC_JALR;
    case RV_OPERATION_C_ADD: return NEMU_PROFILE_CPU_RVC_ADD;
    case RV_OPERATION_C_FSDSP: return NEMU_PROFILE_CPU_RVC_FSDSP;
    case RV_OPERATION_C_SWSP: return NEMU_PROFILE_CPU_RVC_SWSP;
    case RV_OPERATION_C_SDSP: return NEMU_PROFILE_CPU_RVC_SDSP;
    default: return NEMU_PROFILE_CPU_RVC_OTHER;
  }
}

static inline void rv_profile_compressed_execution(RvOperation operation) {
  if (unlikely(nemu_profile_rvc_detail_enabled())) {
    nemu_profile_count(rv_compressed_profile_counter(operation), 1);
  }
}

static inline bool rv_execute_compressed_control_transfer(
    Decode *state, const RvDecodedInstruction *instruction) {
  const word_t source = rv_read_x_register(instruction->rs1);
  vaddr_t target;

  switch (instruction->operation) {
    case RV_OPERATION_C_J:
      target = state->pc + instruction->immediate;
      if (rv_instruction_target_valid(target)) state->dnpc = target;
      return true;
    case RV_OPERATION_C_BEQZ:
      if (source == 0) {
        target = state->pc + instruction->immediate;
        if (rv_instruction_target_valid(target)) state->dnpc = target;
      }
      return true;
    case RV_OPERATION_C_BNEZ:
      if (source != 0) {
        target = state->pc + instruction->immediate;
        if (rv_instruction_target_valid(target)) state->dnpc = target;
      }
      return true;
    case RV_OPERATION_C_JR:
      target = source & ~(word_t)1;
      if (!rv_instruction_target_valid(target)) return true;
      state->dnpc = target;
      IFDEF(CONFIG_FTRACE, {
        if (instruction->rs1 == 1) {
          ftrace_log(-1, state->pc, target);
        }
      })
      return true;
    case RV_OPERATION_C_JALR:
      /* Capture the target before writing x1; rs1 may itself be x1. */
      target = source & ~(word_t)1;
      if (!rv_instruction_target_valid(target)) return true;
      rv_write_x_register(1, state->pc + instruction->length);
      state->dnpc = target;
      IFDEF(CONFIG_FTRACE, ftrace_log(1, state->pc, target));
      return true;
    default:
      return false;
  }
}

static inline bool rv_execute_compressed(
    Decode *state, const RvDecodedInstruction *instruction) {
  rv_profile_compressed_execution(instruction->operation);

  switch (instruction->operation) {
    case RV_OPERATION_C_HINT:
      return true;

    case RV_OPERATION_C_ADDI4SPN:
    case RV_OPERATION_C_ADDI:
    case RV_OPERATION_C_ADDI16SP:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) + instruction->immediate);
      return true;
    case RV_OPERATION_C_ADDIW:
      rv_write_x_register(
          instruction->rd,
          sext32((uint32_t)rv_read_x_register(instruction->rs1) +
                 (uint32_t)instruction->immediate));
      return true;
    case RV_OPERATION_C_LI:
    case RV_OPERATION_C_LUI:
      rv_write_x_register(instruction->rd, instruction->immediate);
      return true;
    case RV_OPERATION_C_SRLI:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) >> instruction->immediate);
      return true;
    case RV_OPERATION_C_SRAI:
      rv_write_x_register(
          instruction->rd,
          (sword_t)rv_read_x_register(instruction->rs1) >>
              instruction->immediate);
      return true;
    case RV_OPERATION_C_ANDI:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) & instruction->immediate);
      return true;
    case RV_OPERATION_C_SUB:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) -
              rv_read_x_register(instruction->rs2));
      return true;
    case RV_OPERATION_C_XOR:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) ^
              rv_read_x_register(instruction->rs2));
      return true;
    case RV_OPERATION_C_OR:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) |
              rv_read_x_register(instruction->rs2));
      return true;
    case RV_OPERATION_C_AND:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) &
              rv_read_x_register(instruction->rs2));
      return true;
    case RV_OPERATION_C_SUBW:
      rv_write_x_register(
          instruction->rd,
          sext32((uint32_t)rv_read_x_register(instruction->rs1) -
                 (uint32_t)rv_read_x_register(instruction->rs2)));
      return true;
    case RV_OPERATION_C_ADDW:
      rv_write_x_register(
          instruction->rd,
          sext32((uint32_t)rv_read_x_register(instruction->rs1) +
                 (uint32_t)rv_read_x_register(instruction->rs2)));
      return true;
    case RV_OPERATION_C_SLLI:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) << instruction->immediate);
      return true;
    case RV_OPERATION_C_MV:
      rv_write_x_register(
          instruction->rd, rv_read_x_register(instruction->rs2));
      return true;
    case RV_OPERATION_C_ADD:
      rv_write_x_register(
          instruction->rd,
          rv_read_x_register(instruction->rs1) +
              rv_read_x_register(instruction->rs2));
      return true;

    case RV_OPERATION_C_LW:
    case RV_OPERATION_C_LWSP:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_WORD, RV_LOAD_SIGN_EXTEND);
    case RV_OPERATION_C_LD:
    case RV_OPERATION_C_LDSP:
      return rv_execute_load_with_semantics(
          instruction, RV_MEMORY_WIDTH_DOUBLEWORD, RV_LOAD_ZERO_EXTEND);
    case RV_OPERATION_C_SW:
    case RV_OPERATION_C_SWSP:
      return rv_execute_store_with_width(
          instruction, RV_MEMORY_WIDTH_WORD);
    case RV_OPERATION_C_SD:
    case RV_OPERATION_C_SDSP:
      return rv_execute_store_with_width(
          instruction, RV_MEMORY_WIDTH_DOUBLEWORD);

    case RV_OPERATION_C_FLD:
    case RV_OPERATION_C_FLDSP:
      return exec_rvf_load(
          0x3, instruction->rd,
          rv_read_x_register(instruction->rs1) + instruction->immediate);
    case RV_OPERATION_C_FSD:
    case RV_OPERATION_C_FSDSP:
      return exec_rvf_store(
          0x3,
          rv_read_x_register(instruction->rs1) + instruction->immediate,
          instruction->rs2);

    case RV_OPERATION_C_J:
    case RV_OPERATION_C_BEQZ:
    case RV_OPERATION_C_BNEZ:
    case RV_OPERATION_C_JR:
    case RV_OPERATION_C_JALR:
      return rv_execute_compressed_control_transfer(state, instruction);
    case RV_OPERATION_C_EBREAK:
      return rv_execute_breakpoint(state);
    default:
      return false;
  }
}
#endif

static inline bool rv_execute_sfence_vma(
    const RvDecodedInstruction *instruction) {
  /* SFENCE.VMA is defined only in S/M mode. TVM constrains S mode alone. */
  if (cpu.priv < PRIV_S) return false;
  if (cpu.priv == PRIV_S && (cpu.csr.mstatus & MSTATUS_TVM)) return false;

  const bool selects_virtual_address = instruction->rs1 != 0;
  const bool selects_address_space = instruction->rs2 != 0;
  const word_t virtual_address = rv_read_x_register(instruction->rs1);
  const word_t address_space = rv_read_x_register(instruction->rs2);
  isa_riscv64_mmu_tlb_flush_selective(
      virtual_address, selects_virtual_address,
      address_space, selects_address_space);
  return true;
}

static inline bool rv_execute_system(
    Decode *state, const RvDecodedInstruction *instruction) {
  switch (instruction->operation) {
    case RV_OPERATION_ECALL:
      return rv_execute_environment_call(state);
    case RV_OPERATION_EBREAK:
      return rv_execute_breakpoint(state);
    case RV_OPERATION_SRET:
      return riscv_execute_supervisor_return(state);
    case RV_OPERATION_MRET:
      return riscv_execute_machine_return(state);
    case RV_OPERATION_WFI:
      /* TW makes an S/U-mode WFI illegal; M-mode is never constrained. */
      if (cpu.priv != PRIV_M && (cpu.csr.mstatus & MSTATUS_TW)) return false;
      isa_riscv64_wfi();
      return true;
    case RV_OPERATION_SFENCE_VMA:
      return rv_execute_sfence_vma(instruction);
    case RV_OPERATION_CSRRW:
    case RV_OPERATION_CSRRS:
    case RV_OPERATION_CSRRC:
    case RV_OPERATION_CSRRWI:
    case RV_OPERATION_CSRRSI:
    case RV_OPERATION_CSRRCI:
      return riscv_execute_csr_instruction(&instruction->csr);
    default:
      return false;
  }
}

static inline bool rv_execute_decoded_instruction(
    Decode *state, const RvDecodedInstruction *instruction) {
  state->dnpc = state->snpc;

  switch (instruction->instruction_class) {
    case RV_INSTRUCTION_CLASS_COMPRESSED:
#ifdef CONFIG_RISCV_EXT_C
      return rv_execute_compressed(state, instruction);
#else
      return false;
#endif
    case RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE:
      return rv_execute_integer_immediate(instruction);
    case RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE_WORD:
      return rv_execute_integer_immediate_word(instruction);
    case RV_INSTRUCTION_CLASS_INTEGER_REGISTER:
      return rv_execute_integer_register(instruction);
    case RV_INSTRUCTION_CLASS_INTEGER_REGISTER_WORD:
      return rv_execute_integer_register_word(instruction);
    case RV_INSTRUCTION_CLASS_LOAD:
      return rv_execute_load(instruction);
    case RV_INSTRUCTION_CLASS_STORE:
      return rv_execute_store(instruction);
    case RV_INSTRUCTION_CLASS_BRANCH:
      return rv_execute_branch(state, instruction);
    case RV_INSTRUCTION_CLASS_JUMP:
      return rv_execute_jump(state, instruction);
    case RV_INSTRUCTION_CLASS_UPPER_IMMEDIATE:
      return rv_execute_upper_immediate(state, instruction);
    case RV_INSTRUCTION_CLASS_MEMORY_ORDERING:
      return rv_execute_memory_ordering(instruction);
    case RV_INSTRUCTION_CLASS_SYSTEM:
      return rv_execute_system(state, instruction);
    default:
      return false;
  }
}
