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
  /*
   * funct3 是译码合法性，不是地址语义。必须在 MMU/对齐检查前拒绝保留编码，
   * 否则一个非法 LOAD 可能因“看起来像 8-byte 访存”而被错误改判成地址异常。
   */
  if (funct3 > 0x6) return false;
  // NPC 硬件语义(OooIntBackend.v:1057-1066): 普通 load 页内 misaligned 由 LSUDataPath 连续字节硬件
  // 支持(不 fault); 仅"地址翻译激活(isa_mmu_check==TRANSLATE) 且 跨 4KB 页(EA[11:0]+len>0x1000)"
  // misaligned 才抛 LOAD_MISALIGN(交软件 trap-emulate)。AMO/LR/SC 对齐约束在 amo.c 自查,不走此路。
  int len = 1 << (funct3 & 0x3);
  if ((addr & (word_t)(len - 1)) &&
      isa_mmu_check(addr, len, MEM_TYPE_READ) == MMU_TRANSLATE &&
      ((addr & (word_t)0xfff) + (word_t)len > (word_t)0x1000)) {
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
  // RV64 STORE 只定义 SB/SH/SW/SD；保留编码不能触发任何地址检查或访存副作用。
  if (funct3 > 0x3) return false;
  // 对齐 NPC 硬件语义(见 exec_rv64i_load): 普通 store 页内 misaligned 硬件支持,仅翻译激活且跨 4KB 页 fault。
  int len = 1 << (funct3 & 0x3);
  if ((addr & (word_t)(len - 1)) &&
      isa_mmu_check(addr, len, MEM_TYPE_WRITE) == MMU_TRANSLATE &&
      ((addr & (word_t)0xfff) + (word_t)len > (word_t)0x1000)) {
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
  bool taken = false;
  switch (funct3) {
    case 0x0: taken = src1 == src2; break;                  // beq
    case 0x1: taken = src1 != src2; break;                  // bne
    case 0x4: taken = (sword_t)src1 < (sword_t)src2; break; // blt
    case 0x5: taken = (sword_t)src1 >= (sword_t)src2; break;// bge
    case 0x6: taken = src1 < src2; break;                   // bltu
    case 0x7: taken = src1 >= src2; break;                  // bgeu
    default: return false;
  }
  if (taken) {
    word_t target = s->pc + imm;
    if (rv_instruction_target_valid(target)) s->dnpc = target;
  }
  return true;
}

typedef enum {
  RV64I_JUMP_JAL,
  RV64I_JUMP_JALR,
} Rv64iJumpKind;

/*
 * JAL/JALR 共用一个体系结构提交点：目标违反 IALIGN 时，先触发
 * Instruction Address Misaligned 异常，不提交 link register、dnpc 或 ftrace。
 * 普通译码和 decode-cache 命中都走这里，二者因而具有相同的跳转语义。
 */
static inline void exec_rv64i_jump(Decode *s, Rv64iJumpKind kind,
                                   int rd, int rs1, word_t src1,
                                   word_t immediate) {
  word_t target = kind == RV64I_JUMP_JALR
                      ? (src1 + immediate) & ~(word_t)1
                      : s->pc + immediate;
  if (!rv_instruction_target_valid(target)) return;

  R(rd) = s->pc + 4;
  s->dnpc = target;

  (void)rs1;
  IFDEF(CONFIG_FTRACE, {
    if (kind == RV64I_JUMP_JALR && rd == 0 && rs1 == 1) {
      ftrace_log(-1, s->pc, s->dnpc);
    } else if (rd == 1 || rd == 5) {
      ftrace_log(1, s->pc, s->dnpc);
    }
  })
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
