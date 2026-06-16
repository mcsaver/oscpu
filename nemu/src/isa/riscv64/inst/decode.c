/* 顶层译码、取指、异常收口和 isa_exec_once。 */

static int decode_exec(Decode *s) {
  s->dnpc = s->snpc;
  uint32_t inst = s->isa.inst;

#ifdef CONFIG_RISCV_EXT_C
  if ((inst & 0x3) != 0x3) {
    if (!exec_rv64c(s, inst & 0xffffu)) goto invalid;
    R(0) = 0;
    return 0;
  }
#endif

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
      if (!exec_rv64i_op_imm_32(inst, rd, src1)) goto invalid;
      break;
    }
    case OPC_LOAD: {
      word_t addr = R(rs1) + IMM_I(inst);
      if (!exec_rv64i_load(funct3, rd, addr)) goto invalid;
      break;
    }
    case OPC_LOAD_FP: {
      word_t addr = R(rs1) + IMM_I(inst);
      if (!exec_rvf_load(funct3, rd, addr)) goto invalid;
      break;
    }
    case OPC_MISC_MEM:
      if (!exec_misc_mem(funct3)) goto invalid;
      break;
    case OPC_STORE: {
      word_t addr = R(rs1) + IMM_S(inst);
      if (!exec_rv64i_store(funct3, addr, R(rs2))) goto invalid;
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
    case OPC_BRANCH:
      if (!exec_rv64i_branch(s, funct3, R(rs1), R(rs2), IMM_B(inst))) goto invalid;
      break;
    case OPC_JALR: {
      if (funct3 != 0x0) goto invalid;
      word_t target = (R(rs1) + IMM_I(inst)) & ~(word_t)1;
      R(rd) = s->pc + 4;
      s->dnpc = target;
      IFDEF(CONFIG_FTRACE, {
        if (rd == 0 && rs1 == 1) ftrace_log(-1, s->pc, target);
        else if (rd == 1 || rd == 5) ftrace_log(1, s->pc, target);
      })
      break;
    }
    case OPC_JAL:
      R(rd) = s->pc + 4;
      s->dnpc = s->pc + IMM_J(inst);
      IFDEF(CONFIG_FTRACE, if (rd == 1 || rd == 5) ftrace_log(1, s->pc, s->dnpc));
      break;
    case OPC_LUI:
      R(rd) = IMM_U(inst);
      break;
    case OPC_AUIPC:
      R(rd) = s->pc + IMM_U(inst);
      break;
    case OPC_SYSTEM:
      if (!exec_system(s, inst, funct3, rd, rs1, rs2)) goto invalid;
      break;
    default:
      goto invalid;
  }

  R(0) = 0;
  return 0;

invalid:
  raise_illegal_inst(s, inst);
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
#ifdef CONFIG_RISCV_EXT_C
  VaddrIfetchWideResult wide = vaddr_ifetch_wide(s->snpc);
  if (wide != VADDR_IFETCH_WIDE_MISS) {
    if (take_vaddr_fault(s)) {
      s->isa.inst = 0;
      return 0;
    }
    s->isa.inst = vaddr_ifetch_wide_inst(wide);
    s->snpc += vaddr_ifetch_wide_len(wide);
    syscall_debug_log_user_pc(s->pc, s->isa.inst);
    if (rv_decode_cache_exec(s)) {
      take_vaddr_fault(s);
      return 0;
    }
    int ret = decode_exec(s);
    rv_decode_cache_fill(s);
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
  if (rv_decode_cache_exec(s)) {
    take_vaddr_fault(s);
    return 0;
  }
  int ret = decode_exec(s);
  rv_decode_cache_fill(s);
  take_vaddr_fault(s);
  return ret;
}
