/* RV64 Zba/Zbb/Zbc/Zbs bitmanip 扩展。 */

#ifdef CONFIG_RISCV_EXT_B
/* Zba/Zbb/Zbc/Zbs 扩展：所有 bitmanip 逻辑集中在这里。
 * 主译码只在 RV64I 没命中时进入本块，常见基础指令不为扩展表付额外层次。 */
static inline bool exec_zb_op_imm(uint32_t inst, int rd, word_t src1) {
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  uint32_t funct6 = BITS(inst, 31, 26);
  uint32_t imm = MUXDEF(CONFIG_ISA64, BITS(inst, 25, 20), BITS(inst, 24, 20));
  uint32_t imm5 = BITS(inst, 24, 20);

  if (funct3 == 0x1) {
    switch (funct6) {
      case 0x0a: R(rd) = src1 | ((word_t)1 << imm); return true;       // bseti
      case 0x12: R(rd) = src1 & ~((word_t)1 << imm); return true;      // bclri
      case 0x1a: R(rd) = src1 ^ ((word_t)1 << imm); return true;       // binvi
      default: break;
    }
    switch (funct7) {
      case 0x30:
        switch (imm5) {
          case 0x00: R(rd) = clz_xlen(src1); return true;        // clz
          case 0x01: R(rd) = ctz_xlen(src1); return true;        // ctz
          case 0x02: R(rd) = cpop_xlen(src1); return true;       // cpop
          case 0x04: R(rd) = sext_b_xlen(src1); return true;     // sext.b
          case 0x05: R(rd) = sext_h_xlen(src1); return true;     // sext.h
          default: return false;
        }
      default:
        return false;
    }
  }

  if (funct3 == 0x5) {
    switch (funct6) {
      case 0x18: R(rd) = ror_xlen(src1, imm); return true;       // rori
      case 0x12: R(rd) = (src1 >> imm) & 1u; return true;        // bexti
      default: break;
    }
    switch (funct7) {
      case 0x14:
        if (imm5 != 0x07) return false;
        R(rd) = orc_b_xlen(src1);                               // orc.b
        return true;
      case 0x35:
        if (imm5 != 0x18) return false;
        // RV64 REV8 的 imm[11:0]=0x6b8；0x698 是 RV32 专属编码。
        R(rd) = rev8_xlen(src1);                                // rev8 (RV64)
        return true;
      default:
        return false;
    }
  }

  return false;
}

static inline bool exec_zb_op(uint32_t funct3, uint32_t funct7, int rd, int rs2, word_t src1, word_t src2) {
  (void)rs2; // 保留 unity-build/译码缓存共享签名；RV64 Zbb 的 OP 类不再需要检查 RV32 ZEXT.H 的 rs2。
  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x2, 0x10): R(rd) = (src1 << 1) + src2; return true; // sh1add
    case OP_KEY(0x4, 0x10): R(rd) = (src1 << 2) + src2; return true; // sh2add
    case OP_KEY(0x6, 0x10): R(rd) = (src1 << 3) + src2; return true; // sh3add
    case OP_KEY(0x7, 0x20): R(rd) = src1 & ~src2; return true;       // andn
    case OP_KEY(0x6, 0x20): R(rd) = src1 | ~src2; return true;       // orn
    case OP_KEY(0x4, 0x20): R(rd) = ~(src1 ^ src2); return true;     // xnor
    case OP_KEY(0x1, 0x30): R(rd) = rol_xlen(src1, src2); return true;  // rol
    case OP_KEY(0x5, 0x30): R(rd) = ror_xlen(src1, src2); return true;  // ror
    case OP_KEY(0x4, 0x05): R(rd) = ((sword_t)src1 < (sword_t)src2) ? src1 : src2; return true; // min
    case OP_KEY(0x5, 0x05): R(rd) = (src1 < src2) ? src1 : src2; return true;                   // minu
    case OP_KEY(0x6, 0x05): R(rd) = ((sword_t)src1 > (sword_t)src2) ? src1 : src2; return true; // max
    case OP_KEY(0x7, 0x05): R(rd) = (src1 > src2) ? src1 : src2; return true;                   // maxu
    case OP_KEY(0x1, 0x05): R(rd) = clmul_xlen(src1, src2); return true;  // clmul
    case OP_KEY(0x2, 0x05): R(rd) = clmulr_xlen(src1, src2); return true; // clmulr
    case OP_KEY(0x3, 0x05): R(rd) = clmulh_xlen(src1, src2); return true; // clmulh
    case OP_KEY(0x1, 0x14): R(rd) = src1 | ((word_t)1 << SHAMT_XLEN(src2)); return true;      // bset
    case OP_KEY(0x1, 0x24): R(rd) = src1 & ~((word_t)1 << SHAMT_XLEN(src2)); return true;     // bclr
    case OP_KEY(0x5, 0x24): R(rd) = (src1 >> SHAMT_XLEN(src2)) & 1u; return true;             // bext
    case OP_KEY(0x1, 0x34): R(rd) = src1 ^ ((word_t)1 << SHAMT_XLEN(src2)); return true;      // binv
    default:
      return false;
  }
}

/* Zbb 的 OP-IMM-32(0x1b)家族: clzw/ctzw/cpopw/roriw(slli.uw 在 rv64i 层)。 */
static inline word_t rorw_zb(uint32_t v, uint32_t sh) {
  sh &= 31;
  uint32_t r = sh ? ((v >> sh) | (v << (32 - sh))) : v;
  return (word_t)(int64_t)(int32_t)r;
}

static inline bool exec_zb_op_imm_32(uint32_t inst, int rd, word_t src1) {
  if (!ISDEF(CONFIG_ISA64)) return false;
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct7 = FUNCT7(inst);
  uint32_t imm5 = BITS(inst, 24, 20);
  uint32_t src32 = (uint32_t)src1;

  if (funct3 == 0x1 && funct7 == 0x30) {
    switch (imm5) {
      case 0x00: R(rd) = src32 == 0 ? 32 : (word_t)__builtin_clz(src32); return true;  // clzw
      case 0x01: R(rd) = src32 == 0 ? 32 : (word_t)__builtin_ctz(src32); return true;  // ctzw
      case 0x02: R(rd) = (word_t)__builtin_popcount(src32); return true;               // cpopw
      default: return false;
    }
  }
  if (funct3 == 0x5 && funct7 == 0x30) {                       // roriw
    R(rd) = rorw_zb(src32, imm5);
    return true;
  }
  return false;
}

static inline bool exec_zb_op_32(uint32_t funct3, uint32_t funct7, int rd, int rs2, word_t src1, word_t src2) {
  if (!ISDEF(CONFIG_ISA64)) return false;

  word_t src1_uw = (uint32_t)src1;
  switch (OP_KEY(funct3, funct7)) {
    case OP_KEY(0x0, 0x04): R(rd) = src1_uw + src2; return true;       // add.uw
    case OP_KEY(0x2, 0x10): R(rd) = (src1_uw << 1) + src2; return true; // sh1add.uw
    case OP_KEY(0x4, 0x10): R(rd) = (src1_uw << 2) + src2; return true; // sh2add.uw
    case OP_KEY(0x6, 0x10): R(rd) = (src1_uw << 3) + src2; return true; // sh3add.uw
    case OP_KEY(0x4, 0x04):
      if (rs2 != 0) return false;
      R(rd) = src1 & 0xffffu;                                           // zext.h
      return true;
    case OP_KEY(0x1, 0x30):                                             // rolw
      return R(rd) = rorw_zb((uint32_t)src1, 32u - ((uint32_t)src2 & 31u)), true;
    case OP_KEY(0x5, 0x30):                                             // rorw
      return R(rd) = rorw_zb((uint32_t)src1, (uint32_t)src2), true;
    default:
      return false;
  }
}
#endif
