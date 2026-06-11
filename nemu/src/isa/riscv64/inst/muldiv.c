/* RV64M 乘除扩展。 */

#ifdef CONFIG_RISCV_EXT_M
/* RVM 扩展：乘除相关编码集中在一个入口。关闭 Kconfig 后整组编码自然非法。 */
static inline bool exec_rvm_op(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  if (funct7 != 0x01) return false;

  switch (funct3) {
    case 0x0: { // mul
      R(rd) = (word_t)((unsigned __int128)src1 * (unsigned __int128)src2);
      return true;
    }
    case 0x1: { // mulh
      __int128 prod = (__int128)(sword_t)src1 * (__int128)(sword_t)src2;
      R(rd) = (word_t)(prod >> XLEN_BITS);
      return true;
    }
    case 0x2: { // mulhsu
      __int128 prod = (__int128)(sword_t)src1 * (__int128)(unsigned __int128)src2;
      R(rd) = (word_t)(prod >> XLEN_BITS);
      return true;
    }
    case 0x3: { // mulhu
      unsigned __int128 prod = (unsigned __int128)src1 * (unsigned __int128)src2;
      R(rd) = (word_t)(prod >> XLEN_BITS);
      return true;
    }
    case 0x4: // div
      if (src2 == 0) R(rd) = (word_t)-1;
      else if (src1 == WORD_SIGN_BIT && src2 == (word_t)-1) R(rd) = WORD_SIGN_BIT;
      else R(rd) = (sword_t)src1 / (sword_t)src2;
      return true;
    case 0x5: // divu
      R(rd) = (src2 == 0) ? (word_t)-1 : src1 / src2;
      return true;
    case 0x6: // rem
      if (src2 == 0) R(rd) = src1;
      else if (src1 == WORD_SIGN_BIT && src2 == (word_t)-1) R(rd) = 0;
      else R(rd) = (sword_t)src1 % (sword_t)src2;
      return true;
    case 0x7: // remu
      R(rd) = (src2 == 0) ? src1 : src1 % src2;
      return true;
    default:
      return false;
  }
}

static inline bool exec_rvm_op_32(uint32_t funct3, uint32_t funct7, int rd, word_t src1, word_t src2) {
  if (!ISDEF(CONFIG_ISA64) || funct7 != 0x01) return false;

  uint32_t a = src1;
  uint32_t b = src2;
  int32_t sa = (int32_t)a;
  int32_t sb = (int32_t)b;

  switch (funct3) {
    case 0x0: R(rd) = sext32((uint32_t)((int64_t)sa * (int64_t)sb)); return true; // mulw
    case 0x4: // divw
      if (b == 0) R(rd) = (word_t)-1;
      else if (a == 0x80000000u && b == 0xffffffffu) R(rd) = sext32(0x80000000u);
      else R(rd) = sext32((uint32_t)(sa / sb));
      return true;
    case 0x5: // divuw
      R(rd) = (b == 0) ? (word_t)-1 : sext32(a / b);
      return true;
    case 0x6: // remw
      if (b == 0) R(rd) = sext32(a);
      else if (a == 0x80000000u && b == 0xffffffffu) R(rd) = 0;
      else R(rd) = sext32((uint32_t)(sa % sb));
      return true;
    case 0x7: // remuw
      R(rd) = (b == 0) ? sext32(a) : sext32(a % b);
      return true;
    default:
      return false;
  }
}
#endif
