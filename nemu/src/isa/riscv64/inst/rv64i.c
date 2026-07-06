/* RV64I 主干整数、访存、branch/jump/system/fence 执行入口。 */

/* RV64I 基础执行块：主干 ISA 按指令格式归类，直接 switch 到最终语义。
 * 这层是热路径，不使用表生成宏，读起来就是 RV64 编码到行为的最短映射。 */
static inline bool exec_rv64i_op_imm(uint32_t inst, int rd, word_t src1) {
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  uint32_t funct6 = BITS(inst, 31, 26);
  word_t imm = IMM_I(inst);
  uint32_t shamt = MUXDEF(CONFIG_ISA64, BITS(inst, 25, 20), BITS(inst, 24, 20));
  (void)funct7;
  (void)funct6;

  switch (funct3) {
    case 0x0: R(rd) = src1 + imm; return true;                                // addi
    case 0x2: R(rd) = (sword_t)src1 < (sword_t)imm ? 1 : 0; return true;       // slti
    case 0x3: R(rd) = src1 < (word_t)imm ? 1 : 0; return true;                 // sltiu
    case 0x4: R(rd) = src1 ^ imm; return true;                                 // xori
    case 0x6: R(rd) = src1 | imm; return true;                                  // ori
    case 0x7: R(rd) = src1 & imm; return true;                                  // andi
    case 0x1:
      if (MUXDEF(CONFIG_ISA64, funct6 == 0x00, funct7 == 0x00)) {
        R(rd) = src1 << shamt; return true;                                      // slli
      }
      break;
    case 0x5:
      if (MUXDEF(CONFIG_ISA64, funct6 == 0x00, funct7 == 0x00)) {
        R(rd) = src1 >> shamt; return true;                                      // srli
      }
      if (MUXDEF(CONFIG_ISA64, funct6 == 0x10, funct7 == 0x20)) {
        R(rd) = (sword_t)src1 >> shamt; return true;                             // srai
      }
      break;
  }

  return false;
}

static inline bool exec_rv64i_load(uint32_t funct3, int rd, word_t addr) {
  // NPC 硬件对 misaligned 普通 load 取 fault(LSUControl 按 size 检查 addr 低位)。NEMU 原透明
  // 处理 → difftest 发散。此处对齐: len = 1<<(funct3&3)(lb/lbu=1,lh/lhu=2,lw/lwu=4,ld=8),
  // addr%len!=0 → CAUSE_LOAD_MISALIGNED(tval=addr)。AMO 自查、页表 walk 走 dcache_peek 不受影响。
  int len = 1 << (funct3 & 0x3);
  if (addr & (word_t)(len - 1)) {
    vaddr_set_fault(CAUSE_LOAD_MISALIGNED, addr);
    return true;
  }
  word_t val = 0;
  switch (funct3) {
    case 0x0:
      val = Mr(addr, 1);
      if (vaddr_has_fault()) return true;
      R(rd) = SEXT(val, 8); return true;  // lb
    case 0x1:
      val = Mr(addr, 2);
      if (vaddr_has_fault()) return true;
      R(rd) = SEXT(val, 16); return true; // lh
    case 0x2:
      val = Mr(addr, 4);
      if (vaddr_has_fault()) return true;
      R(rd) = SEXT(val, 32); return true; // lw
    case 0x3:
      IFDEF(CONFIG_ISA64, {
        val = Mr(addr, 8);
        if (vaddr_has_fault()) return true;
        R(rd) = val; return true; // ld
      });
      return false;
    case 0x4:
      val = Mr(addr, 1);
      if (vaddr_has_fault()) return true;
      R(rd) = val; return true;           // lbu
    case 0x5:
      val = Mr(addr, 2);
      if (vaddr_has_fault()) return true;
      R(rd) = val; return true;           // lhu
    case 0x6:
      IFDEF(CONFIG_ISA64, {
        val = Mr(addr, 4);
        if (vaddr_has_fault()) return true;
        R(rd) = val; return true; // lwu
      });
      return false;
    default: return false;
  }
}

static inline bool exec_rv64i_store(uint32_t funct3, word_t addr, word_t data) {
  // 对齐 NPC: misaligned 普通 store → CAUSE_STORE_MISALIGNED(见 exec_rv64i_load 注释)。
  int len = 1 << (funct3 & 0x3);
  if (addr & (word_t)(len - 1)) {
    vaddr_set_fault(CAUSE_STORE_MISALIGNED, addr);
    return true;
  }
  switch (funct3) {
    case 0x0: Mw(addr, 1, data); return true; // sb
    case 0x1: Mw(addr, 2, data); return true; // sh
    case 0x2: Mw(addr, 4, data); return true; // sw
    case 0x3:
      IFDEF(CONFIG_ISA64, Mw(addr, 8, data); return true); // sd
      return false;
    default: return false;
  }
}

static inline bool exec_rv64i_branch(Decode *s, uint32_t funct3, word_t src1, word_t src2, word_t imm) {
  switch (funct3) {
    case 0x0: if (src1 == src2) s->dnpc = s->pc + imm; return true;                 // beq
    case 0x1: if (src1 != src2) s->dnpc = s->pc + imm; return true;                 // bne
    case 0x4: if ((sword_t)src1 < (sword_t)src2) s->dnpc = s->pc + imm; return true; // blt
    case 0x5: if ((sword_t)src1 >= (sword_t)src2) s->dnpc = s->pc + imm; return true;// bge
    case 0x6: if (src1 < src2) s->dnpc = s->pc + imm; return true;                  // bltu
    case 0x7: if (src1 >= src2) s->dnpc = s->pc + imm; return true;                 // bgeu
    default: return false;
  }
}

static inline bool exec_rv64i_op(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x0, 0x00): R(rd) = src1 + src2; return true;                             // add
    case OP_KEY(0x0, 0x20): R(rd) = src1 - src2; return true;                             // sub
    case OP_KEY(0x1, 0x00): R(rd) = src1 << SHAMT_XLEN(src2); return true;                // sll
    case OP_KEY(0x2, 0x00): R(rd) = (sword_t)src1 < (sword_t)src2 ? 1 : 0; return true;   // slt
    case OP_KEY(0x3, 0x00): R(rd) = src1 < src2 ? 1 : 0; return true;                     // sltu
    case OP_KEY(0x4, 0x00): R(rd) = src1 ^ src2; return true;                             // xor
    case OP_KEY(0x5, 0x00): R(rd) = src1 >> SHAMT_XLEN(src2); return true;                // srl
    case OP_KEY(0x5, 0x20): R(rd) = (sword_t)src1 >> SHAMT_XLEN(src2); return true;       // sra
    case OP_KEY(0x6, 0x00): R(rd) = src1 | src2; return true;                             // or
    case OP_KEY(0x7, 0x00): R(rd) = src1 & src2; return true;                             // and
    default: return false;
  }
}

static inline bool exec_rv64i_op_imm_32(uint32_t inst, int rd, word_t src1) {
  if (!ISDEF(CONFIG_ISA64)) return false;

  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  uint32_t shamt = BITS(inst, 24, 20);
  uint32_t src32 = src1;

  switch (funct3) {
    case 0x0: R(rd) = sext32(src32 + (uint32_t)IMM_I(inst)); return true; // addiw
    case 0x1:
#ifdef CONFIG_RISCV_EXT_B
      if (BITS(inst, 31, 26) == 0x02) { R(rd) = ((word_t)src32) << BITS(inst, 25, 20); return true; } // slli.uw
#endif
      if (funct7 == 0x00) { R(rd) = sext32(src32 << shamt); return true; } // slliw
      break;
    case 0x5:
      if (funct7 == 0x00) { R(rd) = sext32(src32 >> shamt); return true; } // srliw
      if (funct7 == 0x20) { R(rd) = sext32((uint32_t)((int32_t)src32 >> shamt)); return true; } // sraiw
      break;
  }

  return false;
}

static inline bool exec_rv64i_op_32(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  if (!ISDEF(CONFIG_ISA64)) return false;

  uint32_t a = src1;
  uint32_t b = src2;
  uint32_t shamt = b & 0x1f;

  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x0, 0x00): R(rd) = sext32(a + b); return true; // addw
    case OP_KEY(0x0, 0x20): R(rd) = sext32(a - b); return true; // subw
    case OP_KEY(0x1, 0x00): R(rd) = sext32(a << shamt); return true; // sllw
    case OP_KEY(0x5, 0x00): R(rd) = sext32(a >> shamt); return true; // srlw
    case OP_KEY(0x5, 0x20): R(rd) = sext32((uint32_t)((int32_t)a >> shamt)); return true; // sraw
    default: return false;
  }
}

static inline bool exec_system(Decode *s, uint32_t inst, uint32_t funct3, int rd, int rs1, int rs2) {
  if (funct3 != 0) return exec_csr(inst, funct3, rd, rs1);

  switch (inst) {
    case 0x00000073: // ecall
      syscall_debug_log_enter(s->pc);
      s->dnpc = isa_raise_intr(
          cpu.priv == PRIV_M ? CAUSE_ECALL_M :
          cpu.priv == PRIV_S ? CAUSE_ECALL_S : CAUSE_ECALL_U,
          s->pc);
      return true;
    case 0x00100073: // ebreak
      if (ebreak_should_raise_breakpoint_trap()) {
        s->dnpc = isa_raise_intr(CAUSE_BREAKPOINT, s->pc);
      } else {
        NEMUTRAP(s->pc, R(10));
      }
      return true;
    case 0x10200073: // sret
      if (cpu.priv < PRIV_S) return false;
      csr_sret(s);
      return true;
    case 0x30200073: // mret
      if (cpu.priv != PRIV_M) return false;
      csr_mret(s);
      return true;
    case 0x10500073: // wfi
      isa_riscv64_wfi();
      return true;
    default:
      if ((inst & 0xfe007fffu) == 0x12000073u) { // sfence.vma
        // TVM: S 态且 mstatus.TVM=1 时 SFENCE.VMA 触发 illegal instruction; M 态不受影响。
        if (cpu.priv == PRIV_S && (cpu.csr.mstatus & MSTATUS_TVM)) return false;
        isa_riscv64_mmu_tlb_flush_selective(R(rs1), rs1 != 0, R(rs2), rs2 != 0);
        return true;
      }
      return false;
  }
}

static inline bool exec_misc_mem(uint32_t funct3) {
  switch (funct3) {
    case 0x0: // fence
      return true;
    case 0x1: // fence.i
      // fence.i 是自修改代码的架构同步点；硬件 cache 模型和解释器预译码缓存都在这里失效。
      IFDEF(CONFIG_CACHE, cache_flush_all());
      vaddr_ifetch_cache_flush();
      rv_decode_cache_flush();
      return true;
    default:
      return false;
  }
}
