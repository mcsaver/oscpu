/* Native Sdtrig 1.0 interpretation, using architectural decoded operands.
 * No DUT tags, hit flags, or trap reports participate in this decision. */
#ifdef CONFIG_RISCV_EXT_SDTRIG
static inline bool rv_trigger_matches(word_t address, unsigned accesses) {
  const word_t control = cpu.csr.tdata1;
  const unsigned type = control >> 60;
  if (type != 2 && type != 6) return false;
  if (!(control & accesses) || address != cpu.csr.tdata2) return false;
  switch (cpu.priv) {
    case PRIV_M: return (control & 0x40) && (cpu.csr.mstatus & MSTATUS_MIE);
    case PRIV_S: return (control & 0x10) &&
        (!(cpu.csr.medeleg & 8) || (cpu.csr.mstatus & MSTATUS_SIE));
    case PRIV_U: return (control & 8) != 0;
    default: return false;
  }
}

static inline bool rv_trigger_memory(Decode *state,
    const RvDecodedInstruction *instruction) {
  unsigned accesses = 0;
  word_t address = 0;
  switch (instruction->instruction_class) {
    case RV_INSTRUCTION_CLASS_LOAD:
    case RV_INSTRUCTION_CLASS_STORE:
      accesses = instruction->instruction_class == RV_INSTRUCTION_CLASS_LOAD ? 1 : 2;
      address = R(instruction->rs1) + instruction->immediate;
      break;
    case RV_INSTRUCTION_CLASS_ATOMIC:
      accesses = riscv_atomic_is_load_reserved(&instruction->atomic) ? 1 :
          (riscv_atomic_is_store_conditional(&instruction->atomic) ? 2 : 3);
      address = R(instruction->rs1);
      break;
    case RV_INSTRUCTION_CLASS_FLOATING_POINT:
      if (!fp_state_enabled()) return false;
      switch (instruction->floating.operation) {
        case RISCV_FLOAT_OPERATION_FLW:
        case RISCV_FLOAT_OPERATION_FLD: accesses = 1; break;
        case RISCV_FLOAT_OPERATION_FSW:
        case RISCV_FLOAT_OPERATION_FSD: accesses = 2; break;
        default: return false;
      }
      address = R(instruction->floating.rs1) + instruction->floating.immediate;
      break;
    case RV_INSTRUCTION_CLASS_COMPRESSED: {
      const RiscvCompressedInstruction *c = &instruction->compressed;
      switch (c->operation) {
        case RISCV_COMPRESSED_OPERATION_C_FLD:
        case RISCV_COMPRESSED_OPERATION_C_FLDSP:
          if (!fp_state_enabled()) return false;
          accesses = 1; break;
        case RISCV_COMPRESSED_OPERATION_C_FSD:
        case RISCV_COMPRESSED_OPERATION_C_FSDSP:
          if (!fp_state_enabled()) return false;
          accesses = 2; break;
        case RISCV_COMPRESSED_OPERATION_C_LW:
        case RISCV_COMPRESSED_OPERATION_C_LD:
        case RISCV_COMPRESSED_OPERATION_C_LWSP:
        case RISCV_COMPRESSED_OPERATION_C_LDSP: accesses = 1; break;
        case RISCV_COMPRESSED_OPERATION_C_SW:
        case RISCV_COMPRESSED_OPERATION_C_SD:
        case RISCV_COMPRESSED_OPERATION_C_SWSP:
        case RISCV_COMPRESSED_OPERATION_C_SDSP: accesses = 2; break;
        default: return false;
      }
      address = R(c->rs1) + c->immediate;
      break;
    }
    default: return false;
  }
  if (!rv_trigger_matches(address, accesses)) return false;
  state->dnpc = isa_raise_intr_with_tval(CAUSE_BREAKPOINT, state->pc, address);
  return true;
}
#endif
