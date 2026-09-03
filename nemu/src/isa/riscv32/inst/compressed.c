/* RV32C execution consumes the shared mnemonic descriptor; it never decodes bits. */

#ifdef CONFIG_RISCV_EXT_C
static inline word_t rv32_c_read_x(uint8_t index) {
  return R(index);
}

static inline void rv32_c_write_x(uint8_t index, word_t value) {
  if (index != 0) R(index) = value;
}

static inline word_t rv32_c_address(
    const RiscvCompressedInstruction *instruction) {
  return rv32_c_read_x(instruction->rs1) +
         (word_t)instruction->immediate;
}

static inline bool rv32_c_load_word(
    const RiscvCompressedInstruction *instruction) {
  const word_t value = Mr(rv32_c_address(instruction), 4);
  if (!vaddr_has_fault()) {
    rv32_c_write_x(instruction->rd, value);
  }
  return true;
}

static inline bool rv32_c_store_word(
    const RiscvCompressedInstruction *instruction) {
  Mw(rv32_c_address(instruction), 4, rv32_c_read_x(instruction->rs2));
  return true;
}

static inline bool rv32_c_control_transfer(
    Decode *state, const RiscvCompressedInstruction *instruction) {
  switch (instruction->operation) {
    case RISCV_COMPRESSED_OPERATION_C_J:
      state->dnpc = state->pc + (word_t)instruction->immediate;
      return true;
    case RISCV_COMPRESSED_OPERATION_C_JAL:
      rv32_c_write_x(1, state->pc + instruction->length);
      state->dnpc = state->pc + (word_t)instruction->immediate;
      IFDEF(CONFIG_FTRACE, ftrace_log(1, state->pc, state->dnpc));
      return true;
    case RISCV_COMPRESSED_OPERATION_C_BEQZ:
      if (rv32_c_read_x(instruction->rs1) == 0) {
        state->dnpc = state->pc + (word_t)instruction->immediate;
      }
      return true;
    case RISCV_COMPRESSED_OPERATION_C_BNEZ:
      if (rv32_c_read_x(instruction->rs1) != 0) {
        state->dnpc = state->pc + (word_t)instruction->immediate;
      }
      return true;
    case RISCV_COMPRESSED_OPERATION_C_JR:
      state->dnpc = rv32_c_read_x(instruction->rs1) & ~(word_t)1;
      IFDEF(CONFIG_FTRACE, {
        if (instruction->rs1 == 1) {
          ftrace_log(-1, state->pc, state->dnpc);
        }
      })
      return true;
    case RISCV_COMPRESSED_OPERATION_C_JALR: {
      /* rs1 may be x1: capture the target before committing the link. */
      const word_t target =
          rv32_c_read_x(instruction->rs1) & ~(word_t)1;
      rv32_c_write_x(1, state->pc + instruction->length);
      state->dnpc = target;
      IFDEF(CONFIG_FTRACE, ftrace_log(1, state->pc, target));
      return true;
    }
    default:
      return false;
  }
}

static inline bool rv32_execute_compressed(
    Decode *state, const RiscvCompressedInstruction *instruction) {
  switch (instruction->operation) {
    case RISCV_COMPRESSED_OPERATION_C_NOP:
    case RISCV_COMPRESSED_OPERATION_HINT:
      return true;

    case RISCV_COMPRESSED_OPERATION_C_ADDI4SPN:
    case RISCV_COMPRESSED_OPERATION_C_ADDI:
    case RISCV_COMPRESSED_OPERATION_C_ADDI16SP:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) +
              (word_t)instruction->immediate);
      return true;
    case RISCV_COMPRESSED_OPERATION_C_LI:
    case RISCV_COMPRESSED_OPERATION_C_LUI:
      rv32_c_write_x(instruction->rd, (word_t)instruction->immediate);
      return true;
    case RISCV_COMPRESSED_OPERATION_C_SRLI:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) >> instruction->immediate);
      return true;
    case RISCV_COMPRESSED_OPERATION_C_SRAI:
      rv32_c_write_x(
          instruction->rd,
          (word_t)((sword_t)rv32_c_read_x(instruction->rs1) >>
                   instruction->immediate));
      return true;
    case RISCV_COMPRESSED_OPERATION_C_ANDI:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) &
              (word_t)instruction->immediate);
      return true;
    case RISCV_COMPRESSED_OPERATION_C_SUB:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) -
              rv32_c_read_x(instruction->rs2));
      return true;
    case RISCV_COMPRESSED_OPERATION_C_XOR:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) ^
              rv32_c_read_x(instruction->rs2));
      return true;
    case RISCV_COMPRESSED_OPERATION_C_OR:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) |
              rv32_c_read_x(instruction->rs2));
      return true;
    case RISCV_COMPRESSED_OPERATION_C_AND:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) &
              rv32_c_read_x(instruction->rs2));
      return true;
    case RISCV_COMPRESSED_OPERATION_C_SLLI:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) << instruction->immediate);
      return true;
    case RISCV_COMPRESSED_OPERATION_C_MV:
      rv32_c_write_x(instruction->rd, rv32_c_read_x(instruction->rs2));
      return true;
    case RISCV_COMPRESSED_OPERATION_C_ADD:
      rv32_c_write_x(
          instruction->rd,
          rv32_c_read_x(instruction->rs1) +
              rv32_c_read_x(instruction->rs2));
      return true;

    case RISCV_COMPRESSED_OPERATION_C_LW:
    case RISCV_COMPRESSED_OPERATION_C_LWSP:
      return rv32_c_load_word(instruction);
    case RISCV_COMPRESSED_OPERATION_C_SW:
    case RISCV_COMPRESSED_OPERATION_C_SWSP:
      return rv32_c_store_word(instruction);

    case RISCV_COMPRESSED_OPERATION_C_FLW:
    case RISCV_COMPRESSED_OPERATION_C_FLWSP:
      return exec_rvf_flw(
          instruction->rd, rv32_c_address(instruction));
    case RISCV_COMPRESSED_OPERATION_C_FLD:
    case RISCV_COMPRESSED_OPERATION_C_FLDSP:
      return exec_rvf_fld(
          instruction->rd, rv32_c_address(instruction));
    case RISCV_COMPRESSED_OPERATION_C_FSW:
    case RISCV_COMPRESSED_OPERATION_C_FSWSP:
      return exec_rvf_fsw(
          rv32_c_address(instruction), instruction->rs2);
    case RISCV_COMPRESSED_OPERATION_C_FSD:
    case RISCV_COMPRESSED_OPERATION_C_FSDSP:
      return exec_rvf_fsd(
          rv32_c_address(instruction), instruction->rs2);

    case RISCV_COMPRESSED_OPERATION_C_J:
    case RISCV_COMPRESSED_OPERATION_C_JAL:
    case RISCV_COMPRESSED_OPERATION_C_BEQZ:
    case RISCV_COMPRESSED_OPERATION_C_BNEZ:
    case RISCV_COMPRESSED_OPERATION_C_JR:
    case RISCV_COMPRESSED_OPERATION_C_JALR:
      return rv32_c_control_transfer(state, instruction);
    case RISCV_COMPRESSED_OPERATION_C_EBREAK:
      return riscv32_execute_breakpoint(state);
    default:
      return false;
  }
}
#else
static inline bool rv32_execute_compressed(
    Decode *state, const RiscvCompressedInstruction *instruction) {
  (void)state;
  (void)instruction;
  return false;
}
#endif
