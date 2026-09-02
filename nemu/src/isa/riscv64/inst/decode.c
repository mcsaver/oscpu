/* 顶层取指、体系结构译码编排、异常收口和 isa_exec_once。 */

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
    .funct3 = FUNCT3(encoding),
    .funct7 = FUNCT7(encoding),
  };
}

static inline bool rv_decode_integer_immediate(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  const uint32_t funct3 = FUNCT3(encoding);
  const uint32_t funct6 = BITS(encoding, 31, 26);

  instruction->instruction_class =
      RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE;
  instruction->immediate = IMM_I(encoding);

  switch (funct3) {
    case 0x0: instruction->operation = RV_OPERATION_ADDI; return true;
    case 0x2: instruction->operation = RV_OPERATION_SLTI; return true;
    case 0x3: instruction->operation = RV_OPERATION_SLTIU; return true;
    case 0x4: instruction->operation = RV_OPERATION_XORI; return true;
    case 0x6: instruction->operation = RV_OPERATION_ORI; return true;
    case 0x7: instruction->operation = RV_OPERATION_ANDI; return true;
    case 0x1:
      if (funct6 == 0x00) {
        instruction->operation = RV_OPERATION_SLLI;
        instruction->immediate = BITS(encoding, 25, 20);
        return true;
      }
      return false;
    case 0x5:
      if (funct6 == 0x00) {
        instruction->operation = RV_OPERATION_SRLI;
        instruction->immediate = BITS(encoding, 25, 20);
        return true;
      }
      if (funct6 == 0x10) {
        instruction->operation = RV_OPERATION_SRAI;
        instruction->immediate = BITS(encoding, 25, 20);
        return true;
      }
      return false;
    default:
      return false;
  }
}

static inline bool rv_decode_integer_immediate_word(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  const uint32_t funct3 = FUNCT3(encoding);
  const uint32_t funct7 = FUNCT7(encoding);

  instruction->instruction_class =
      RV_INSTRUCTION_CLASS_INTEGER_IMMEDIATE_WORD;

  if (funct3 == 0x0) {
    instruction->operation = RV_OPERATION_ADDIW;
    instruction->immediate = IMM_I(encoding);
    return true;
  }
  if (funct3 == 0x1 && funct7 == 0x00) {
    instruction->operation = RV_OPERATION_SLLIW;
    instruction->immediate = BITS(encoding, 24, 20);
    return true;
  }
  if (funct3 == 0x5 && funct7 == 0x00) {
    instruction->operation = RV_OPERATION_SRLIW;
    instruction->immediate = BITS(encoding, 24, 20);
    return true;
  }
  if (funct3 == 0x5 && funct7 == 0x20) {
    instruction->operation = RV_OPERATION_SRAIW;
    instruction->immediate = BITS(encoding, 24, 20);
    return true;
  }
  return false;
}

static inline bool rv_decode_integer_register(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->instruction_class =
      RV_INSTRUCTION_CLASS_INTEGER_REGISTER;

  switch (OP_KEY(FUNCT3(encoding), FUNCT7(encoding))) {
    case OP_KEY(0x0, 0x00): instruction->operation = RV_OPERATION_ADD; return true;
    case OP_KEY(0x0, 0x20): instruction->operation = RV_OPERATION_SUB; return true;
    case OP_KEY(0x1, 0x00): instruction->operation = RV_OPERATION_SLL; return true;
    case OP_KEY(0x2, 0x00): instruction->operation = RV_OPERATION_SLT; return true;
    case OP_KEY(0x3, 0x00): instruction->operation = RV_OPERATION_SLTU; return true;
    case OP_KEY(0x4, 0x00): instruction->operation = RV_OPERATION_XOR; return true;
    case OP_KEY(0x5, 0x00): instruction->operation = RV_OPERATION_SRL; return true;
    case OP_KEY(0x5, 0x20): instruction->operation = RV_OPERATION_SRA; return true;
    case OP_KEY(0x6, 0x00): instruction->operation = RV_OPERATION_OR; return true;
    case OP_KEY(0x7, 0x00): instruction->operation = RV_OPERATION_AND; return true;
    default: return false;
  }
}

static inline bool rv_decode_integer_register_word(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->instruction_class =
      RV_INSTRUCTION_CLASS_INTEGER_REGISTER_WORD;

  switch (OP_KEY(FUNCT3(encoding), FUNCT7(encoding))) {
    case OP_KEY(0x0, 0x00): instruction->operation = RV_OPERATION_ADDW; return true;
    case OP_KEY(0x0, 0x20): instruction->operation = RV_OPERATION_SUBW; return true;
    case OP_KEY(0x1, 0x00): instruction->operation = RV_OPERATION_SLLW; return true;
    case OP_KEY(0x5, 0x00): instruction->operation = RV_OPERATION_SRLW; return true;
    case OP_KEY(0x5, 0x20): instruction->operation = RV_OPERATION_SRAW; return true;
    default: return false;
  }
}

static inline bool rv_decode_load(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->instruction_class = RV_INSTRUCTION_CLASS_LOAD;
  instruction->immediate = IMM_I(encoding);

  switch (FUNCT3(encoding)) {
    case 0x0: instruction->operation = RV_OPERATION_LB; return true;
    case 0x1: instruction->operation = RV_OPERATION_LH; return true;
    case 0x2: instruction->operation = RV_OPERATION_LW; return true;
    case 0x3: instruction->operation = RV_OPERATION_LD; return true;
    case 0x4: instruction->operation = RV_OPERATION_LBU; return true;
    case 0x5: instruction->operation = RV_OPERATION_LHU; return true;
    case 0x6: instruction->operation = RV_OPERATION_LWU; return true;
    default: return false;
  }
}

static inline bool rv_decode_store(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->instruction_class = RV_INSTRUCTION_CLASS_STORE;
  instruction->immediate = IMM_S(encoding);

  switch (FUNCT3(encoding)) {
    case 0x0: instruction->operation = RV_OPERATION_SB; return true;
    case 0x1: instruction->operation = RV_OPERATION_SH; return true;
    case 0x2: instruction->operation = RV_OPERATION_SW; return true;
    case 0x3: instruction->operation = RV_OPERATION_SD; return true;
    default: return false;
  }
}

static inline bool rv_decode_branch(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->instruction_class = RV_INSTRUCTION_CLASS_BRANCH;
  instruction->immediate = IMM_B(encoding);

  switch (FUNCT3(encoding)) {
    case 0x0: instruction->operation = RV_OPERATION_BEQ; return true;
    case 0x1: instruction->operation = RV_OPERATION_BNE; return true;
    case 0x4: instruction->operation = RV_OPERATION_BLT; return true;
    case 0x5: instruction->operation = RV_OPERATION_BGE; return true;
    case 0x6: instruction->operation = RV_OPERATION_BLTU; return true;
    case 0x7: instruction->operation = RV_OPERATION_BGEU; return true;
    default: return false;
  }
}

static inline bool rv_decode_jump(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->instruction_class = RV_INSTRUCTION_CLASS_JUMP;

  switch (OPCODE(encoding)) {
    case OPC_JAL:
      instruction->operation = RV_OPERATION_JAL;
      instruction->immediate = IMM_J(encoding);
      return true;
    case OPC_JALR:
      if (FUNCT3(encoding) != 0x0) return false;
      instruction->operation = RV_OPERATION_JALR;
      instruction->immediate = IMM_I(encoding);
      return true;
    default:
      return false;
  }
}

static inline bool rv_decode_memory_ordering(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->instruction_class = RV_INSTRUCTION_CLASS_MEMORY_ORDERING;

  switch (FUNCT3(encoding)) {
    case 0x0:
      instruction->operation = RV_OPERATION_FENCE;
      return true;
    case 0x1:
      instruction->operation = RV_OPERATION_FENCE_I;
      return true;
    default:
      return false;
  }
}

static inline bool rv_decode_system(
    uint32_t encoding, RvDecodedInstruction *instruction) {
  instruction->instruction_class = RV_INSTRUCTION_CLASS_SYSTEM;

  /* Privileged instructions with architecturally fixed register fields. */
  switch (encoding) {
    case 0x00000073u: instruction->operation = RV_OPERATION_ECALL; return true;
    case 0x00100073u: instruction->operation = RV_OPERATION_EBREAK; return true;
    case 0x10200073u: instruction->operation = RV_OPERATION_SRET; return true;
    case 0x30200073u: instruction->operation = RV_OPERATION_MRET; return true;
    case 0x10500073u: instruction->operation = RV_OPERATION_WFI; return true;
    default:
      break;
  }

  /* SFENCE.VMA leaves rs1 and rs2 as the decoded address/ASID selectors. */
  if ((encoding & 0xfe007fffu) == 0x12000073u) {
    instruction->operation = RV_OPERATION_SFENCE_VMA;
    return true;
  }

  switch (FUNCT3(encoding)) {
    case 0x1: instruction->operation = RV_OPERATION_CSRRW; break;
    case 0x2: instruction->operation = RV_OPERATION_CSRRS; break;
    case 0x3: instruction->operation = RV_OPERATION_CSRRC; break;
    case 0x5: instruction->operation = RV_OPERATION_CSRRWI; break;
    case 0x6: instruction->operation = RV_OPERATION_CSRRSI; break;
    case 0x7: instruction->operation = RV_OPERATION_CSRRCI; break;
    default: return false;
  }

  return riscv_decode_csr_instruction(
      FUNCT3(encoding), BITS(encoding, 31, 20), instruction->rd,
      instruction->rs1, &instruction->csr);
}

/*
 * 已迁移的 RV64 指令：raw encoding 在这里变成手册 mnemonic，
 * 执行层不再读取 opcode/funct 字段。返回 false 表示该编码仍由
 * 明确的 legacy 扩展边界处理。
 */
static inline bool rv_decode_migrated_instruction(
    uint32_t encoding, RvDecodedInstruction *instruction) {
#ifdef CONFIG_RISCV_EXT_C
  if ((encoding & 0x3u) != 0x3u) {
    *instruction = rv_decoded_instruction(encoding & 0xffffu);
    return rv_decode_compressed_instruction(
        encoding & 0xffffu, instruction);
  }
#endif

  *instruction = rv_decoded_instruction(encoding);
  switch (OPCODE(encoding)) {
    case OPC_OP_IMM:
      return rv_decode_integer_immediate(encoding, instruction);
    case OPC_OP_IMM_32:
      return rv_decode_integer_immediate_word(encoding, instruction);
    case OPC_OP:
      return rv_decode_integer_register(encoding, instruction);
    case OPC_OP_32:
      return rv_decode_integer_register_word(encoding, instruction);
    case OPC_LOAD:
      return rv_decode_load(encoding, instruction);
    case OPC_STORE:
      return rv_decode_store(encoding, instruction);
    case OPC_BRANCH:
      return rv_decode_branch(encoding, instruction);
    case OPC_JAL:
    case OPC_JALR:
      return rv_decode_jump(encoding, instruction);
    case OPC_MISC_MEM:
      return rv_decode_memory_ordering(encoding, instruction);
    case OPC_SYSTEM:
      return rv_decode_system(encoding, instruction);
    case OPC_LUI:
      instruction->instruction_class =
          RV_INSTRUCTION_CLASS_UPPER_IMMEDIATE;
      instruction->operation = RV_OPERATION_LUI;
      instruction->immediate = IMM_U(encoding);
      return true;
    case OPC_AUIPC:
      instruction->instruction_class =
          RV_INSTRUCTION_CLASS_UPPER_IMMEDIATE;
      instruction->operation = RV_OPERATION_AUIPC;
      instruction->immediate = IMM_U(encoding);
      return true;
    default:
      return false;
  }
}

static int legacy_decode_and_execute(Decode *s) {
  s->dnpc = s->snpc;
  uint32_t inst = s->isa.inst;

  uint32_t opcode = OPCODE(inst);
  uint32_t funct3 = FUNCT3(inst);
  int rd = RD(inst);
  int rs1 = RS1(inst);
  int rs2 = RS2(inst);

  switch (opcode) {
    case OPC_OP_IMM: {
      word_t src1 = R(rs1);
      if (!exec_rv64i_op_imm(inst, rd, src1)) {
#ifdef CONFIG_RISCV_EXT_B
        if (!exec_zb_op_imm(inst, rd, src1)) goto invalid;
#else
        goto invalid;
#endif
      }
      break;
    }
    case OPC_OP_IMM_32: {
      word_t src1 = R(rs1);
      if (!exec_rv64i_op_imm_32(inst, rd, src1)) {
#ifdef CONFIG_RISCV_EXT_B
        if (!exec_zb_op_imm_32(inst, rd, src1)) goto invalid;
#else
        goto invalid;
#endif
      }
      break;
    }
    case OPC_LOAD_FP: {
      word_t addr = R(rs1) + IMM_I(inst);
      if (!exec_rvf_load(funct3, rd, addr)) goto invalid;
      break;
    }
    case OPC_STORE_FP: {
      word_t addr = R(rs1) + IMM_S(inst);
      if (!exec_rvf_store(funct3, addr, rs2)) goto invalid;
      break;
    }
    case OPC_MADD:
    case OPC_MSUB:
    case OPC_NMSUB:
    case OPC_NMADD:
      if (!exec_rvf_fused_madd(opcode, inst, rd, rs1, rs2)) goto invalid;
      break;
    case OPC_OP_FP:
      if (!exec_rvf_op(inst, rd, rs1, rs2)) goto invalid;
      break;
    case OPC_AMO:
#ifdef CONFIG_RISCV_EXT_A
      if (!exec_rva_amo(inst, rd, rs1, rs2)) goto invalid;
      break;
#else
      goto invalid;
#endif
    case OPC_OP: {
      uint32_t funct7 = FUNCT7(inst);
      word_t src1 = R(rs1);
      word_t src2 = R(rs2);
      if (exec_rv64i_op(funct3, funct7, rd, src1, src2)) break;
#ifdef CONFIG_RISCV_EXT_M
      if (exec_rvm_op(funct3, funct7, rd, src1, src2)) break;
#endif
#ifdef CONFIG_RISCV_EXT_B
      if (exec_zb_op(funct3, funct7, rd, rs2, src1, src2)) break;
#endif
      goto invalid;
    }
    case OPC_OP_32: {
      uint32_t funct7 = FUNCT7(inst);
      word_t src1 = R(rs1);
      word_t src2 = R(rs2);
#ifdef CONFIG_RISCV_EXT_B
      if (exec_zb_op_32(funct3, funct7, rd, rs2, src1, src2)) break;
#endif
      if (exec_rv64i_op_32(funct3, funct7, rd, src1, src2)) break;
#ifdef CONFIG_RISCV_EXT_M
      if (exec_rvm_op_32(funct3, funct7, rd, src1, src2)) break;
#endif
      goto invalid;
    }
    case OPC_LUI:
      R(rd) = IMM_U(inst);
      break;
    case OPC_AUIPC:
      R(rd) = s->pc + IMM_U(inst);
      break;
    default:
      goto invalid;
  }

  R(0) = 0;
  return 0;

invalid:
  raise_illegal_instruction_exception(s, inst);
  return 0;
}

static inline bool execute_migrated_instruction(Decode *state) {
  RvDecodedInstruction instruction;
  if (!rv_decode_cache_lookup(state->pc, state->isa.inst, &instruction)) {
    if (!rv_decode_migrated_instruction(state->isa.inst, &instruction)) {
      return false;
    }
    rv_decode_cache_insert(state->pc, &instruction);
  }

  if (!rv_execute_decoded_instruction(state, &instruction)) {
    raise_illegal_instruction_exception(state, state->isa.inst);
  }
  return true;
}

static inline int execute_current_instruction(Decode *state) {
  if (execute_migrated_instruction(state)) {
    /* Legacy extension helpers still use R() as an lvalue; keep this assertion
     * boundary until all instruction families use rv_write_x_register(). */
    R(0) = 0;
    return 0;
  }
  return legacy_decode_and_execute(state);
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
