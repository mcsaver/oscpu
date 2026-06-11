/* RV64C 压缩指令扩展。 */

#ifdef CONFIG_RISCV_EXT_C
/* RV64C 扩展：可变长取指只负责拿到 16/32 位原始指令，压缩语义全部收口在本块。 */
#define C_FUNCT3(i) BITS(i, 15, 13)
#define C_RD(i)     (8 + BITS(i, 4, 2))
#define C_RS1(i)    (8 + BITS(i, 9, 7))
#define C_RS2(i)    (8 + BITS(i, 4, 2))

static inline word_t c_imm_addi4spn(uint16_t inst) {
  return (BITS(inst, 10, 7) << 6) |
         (BITS(inst, 12, 11) << 4) |
         (BITS(inst, 5, 5) << 3) |
         (BITS(inst, 6, 6) << 2);
}

static inline word_t c_imm_lw_sw(uint16_t inst) {
  return (BITS(inst, 5, 5) << 6) |
         (BITS(inst, 12, 10) << 3) |
         (BITS(inst, 6, 6) << 2);
}

static inline word_t c_imm_ld_sd(uint16_t inst) {
  return (BITS(inst, 6, 5) << 6) |
         (BITS(inst, 12, 10) << 3);
}

static inline word_t c_imm_6(uint16_t inst) {
  return SEXT((BITS(inst, 12, 12) << 5) | BITS(inst, 6, 2), 6);
}

static inline word_t c_imm_j(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 11) |
                 (BITS(inst, 11, 11) << 4) |
                 (BITS(inst, 10, 9) << 8) |
                 (BITS(inst, 8, 8) << 10) |
                 (BITS(inst, 7, 7) << 6) |
                 (BITS(inst, 6, 6) << 7) |
                 (BITS(inst, 5, 3) << 1) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 12);
}

static inline word_t c_imm_addi16sp(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 9) |
                 (BITS(inst, 6, 6) << 4) |
                 (BITS(inst, 5, 5) << 6) |
                 (BITS(inst, 4, 3) << 7) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 10);
}

static inline word_t c_imm_b(uint16_t inst) {
  uint32_t imm = (BITS(inst, 12, 12) << 8) |
                 (BITS(inst, 11, 10) << 3) |
                 (BITS(inst, 6, 5) << 6) |
                 (BITS(inst, 4, 3) << 1) |
                 (BITS(inst, 2, 2) << 5);
  return SEXT(imm, 9);
}

static inline word_t c_imm_lwsp(uint16_t inst) {
  return (BITS(inst, 12, 12) << 5) |
         (BITS(inst, 6, 4) << 2) |
         (BITS(inst, 3, 2) << 6);
}

static inline word_t c_imm_ldsp(uint16_t inst) {
  return (BITS(inst, 12, 12) << 5) |
         (BITS(inst, 6, 5) << 3) |
         (BITS(inst, 4, 2) << 6);
}

static inline word_t c_imm_swsp(uint16_t inst) {
  return (BITS(inst, 8, 7) << 6) |
         (BITS(inst, 12, 9) << 2);
}

static inline word_t c_imm_sdsp(uint16_t inst) {
  return (BITS(inst, 9, 7) << 6) |
         (BITS(inst, 12, 10) << 3);
}

static inline word_t c_shamt(uint16_t inst) {
  return (BITS(inst, 12, 12) << 5) | BITS(inst, 6, 2);
}

static inline bool exec_rv64c(Decode *s, uint16_t inst) {
  uint32_t funct3 = C_FUNCT3(inst);
  uint32_t rd = BITS(inst, 11, 7);
  uint32_t rs2 = BITS(inst, 6, 2);

  switch (BITS(inst, 1, 0)) {
    case 0x0:
      switch (funct3) {
        case 0x0: { // c.addi4spn
          word_t imm = c_imm_addi4spn(inst);
          if (imm == 0) BAD_DECODE();
          R(C_RD(inst)) = R(2) + imm;
          return true;
        }
        case 0x1: // c.fld
          if (!ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_load(0x3, C_RD(inst), R(C_RS1(inst)) + c_imm_ld_sd(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x2: // c.lw
          if (!exec_rv64i_load(0x2, C_RD(inst), R(C_RS1(inst)) + c_imm_lw_sw(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x3: // c.ld
          if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
          if (!exec_rv64i_load(0x3, C_RD(inst), R(C_RS1(inst)) + c_imm_ld_sd(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x6: // c.sw
          Mw(R(C_RS1(inst)) + c_imm_lw_sw(inst), 4, R(C_RS2(inst)));
          return true;
        case 0x5: // c.fsd
          if (!ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_store(0x3, R(C_RS1(inst)) + c_imm_ld_sd(inst), C_RS2(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x7: // c.sd
          if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
          Mw(R(C_RS1(inst)) + c_imm_ld_sd(inst), 8, R(C_RS2(inst)));
          return true;
        default:
          BAD_DECODE();
      }
    case 0x1:
      switch (funct3) {
        case 0x0: // c.addi / c.nop
          R(rd) = R(rd) + c_imm_6(inst);
          return true;
        case 0x1:
#ifdef CONFIG_ISA64
          if (rd == 0) BAD_DECODE();
          R(rd) = sext32((uint32_t)(R(rd) + c_imm_6(inst))); // c.addiw
#else
          R(1) = s->pc + 2;                                  // c.jal
          s->dnpc = s->pc + c_imm_j(inst);
          IFDEF(CONFIG_FTRACE, ftrace_log(1, s->pc, s->dnpc));
#endif
          return true;
        case 0x2: // c.li
          if (rd != 0) R(rd) = c_imm_6(inst);
          return true;
        case 0x3:
          if (rd == 2) { // c.addi16sp
            word_t imm = c_imm_addi16sp(inst);
            if (imm == 0) BAD_DECODE();
            R(2) = R(2) + imm;
          } else { // c.lui
            word_t imm = c_imm_6(inst);
            if (rd == 0 || imm == 0) BAD_DECODE();
            R(rd) = imm << 12;
          }
          return true;
        case 0x4: {
          uint32_t rs1p = C_RS1(inst);
          uint32_t rs2p = C_RS2(inst);
          switch (BITS(inst, 11, 10)) {
            case 0x0: // c.srli
              if (!ISDEF(CONFIG_ISA64) && BITS(inst, 12, 12)) BAD_DECODE();
              R(rs1p) = R(rs1p) >> c_shamt(inst);
              return true;
            case 0x1: // c.srai
              if (!ISDEF(CONFIG_ISA64) && BITS(inst, 12, 12)) BAD_DECODE();
              R(rs1p) = (sword_t)R(rs1p) >> c_shamt(inst);
              return true;
            case 0x2: // c.andi
              R(rs1p) = R(rs1p) & c_imm_6(inst);
              return true;
            case 0x3:
              switch ((BITS(inst, 12, 12) << 2) | BITS(inst, 6, 5)) {
                case 0x0: R(rs1p) = R(rs1p) - R(rs2p); return true; // c.sub
                case 0x1: R(rs1p) = R(rs1p) ^ R(rs2p); return true; // c.xor
                case 0x2: R(rs1p) = R(rs1p) | R(rs2p); return true; // c.or
                case 0x3: R(rs1p) = R(rs1p) & R(rs2p); return true; // c.and
                case 0x4:
                  if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
                  R(rs1p) = sext32((uint32_t)R(rs1p) - (uint32_t)R(rs2p)); return true; // c.subw
                case 0x5:
                  if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
                  R(rs1p) = sext32((uint32_t)R(rs1p) + (uint32_t)R(rs2p)); return true; // c.addw
                default: BAD_DECODE();
              }
            default:
              BAD_DECODE();
          }
        }
        case 0x5: // c.j
          s->dnpc = s->pc + c_imm_j(inst);
          return true;
        case 0x6: // c.beqz
          if (R(C_RS1(inst)) == 0) s->dnpc = s->pc + c_imm_b(inst);
          return true;
        case 0x7: // c.bnez
          if (R(C_RS1(inst)) != 0) s->dnpc = s->pc + c_imm_b(inst);
          return true;
        default:
          BAD_DECODE();
      }
    case 0x2:
      switch (funct3) {
        case 0x0: // c.slli
          if (!ISDEF(CONFIG_ISA64) && BITS(inst, 12, 12)) BAD_DECODE();
          R(rd) = R(rd) << c_shamt(inst);
          return true;
        case 0x1: // c.fldsp
          if (rd == 0 || !ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_load(0x3, rd, R(2) + c_imm_ldsp(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x2: // c.lwsp
          if (rd == 0) BAD_DECODE();
          if (!exec_rv64i_load(0x2, rd, R(2) + c_imm_lwsp(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x3: // c.ldsp
          if (!ISDEF(CONFIG_ISA64) || rd == 0) BAD_DECODE();
          if (!exec_rv64i_load(0x3, rd, R(2) + c_imm_ldsp(inst))) {
            BAD_DECODE();
          }
          return true;
        case 0x4:
          if (BITS(inst, 12, 12) == 0) {
            if (rs2 == 0) { // c.jr
              if (rd == 0) BAD_DECODE();
              s->dnpc = R(rd) & ~(word_t)1;
              IFDEF(CONFIG_FTRACE, if (rd == 1) ftrace_log(-1, s->pc, s->dnpc));
            } else if (rd != 0) { // c.mv
              R(rd) = R(rs2);
            }
          } else {
            if (rs2 == 0) {
              if (rd == 0) {
                if (ebreak_should_raise_breakpoint_trap()) {
                  s->dnpc = isa_raise_intr(CAUSE_BREAKPOINT, s->pc);
                } else {
                  NEMUTRAP(s->pc, R(10)); // c.ebreak
                }
              } else { // c.jalr
                word_t target = R(rd) & ~(word_t)1;
                R(1) = s->pc + 2;
                s->dnpc = target;
                IFDEF(CONFIG_FTRACE, ftrace_log(1, s->pc, target));
              }
            } else if (rd != 0) { // c.add
              R(rd) = R(rd) + R(rs2);
            }
          }
          return true;
        case 0x6: // c.swsp
          Mw(R(2) + c_imm_swsp(inst), 4, R(rs2));
          return true;
        case 0x5: // c.fsdsp
          if (!ISDEF(CONFIG_RISCV_EXT_D) ||
              !exec_rvf_store(0x3, R(2) + c_imm_sdsp(inst), rs2)) {
            BAD_DECODE();
          }
          return true;
        case 0x7: // c.sdsp
          if (!ISDEF(CONFIG_ISA64)) BAD_DECODE();
          Mw(R(2) + c_imm_sdsp(inst), 8, R(rs2));
          return true;
        default:
          BAD_DECODE();
      }
    default:
      BAD_DECODE();
  }
}
#endif
