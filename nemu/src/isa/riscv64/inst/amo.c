/* RV64A LR/SC 与 AMO 扩展。 */

#ifdef CONFIG_RISCV_EXT_A
static inline word_t amo_sext_word(uint32_t value) {
  return MUXDEF(CONFIG_ISA64, (word_t)SEXT(value, 32), (word_t)value);
}

static inline bool amo_funct5_valid(uint32_t funct5) {
  switch (funct5) {
    case 0x00: case 0x01: case 0x04: case 0x08: case 0x0c:
    case 0x10: case 0x14: case 0x18: case 0x1c:
      return true;
    default:
      return false;
  }
}

static inline uint32_t amo_compute_w(uint32_t old, uint32_t src, uint32_t funct5) {
  switch (funct5) {
    case 0x01: return src;                                      // amoswap.w
    case 0x00: return old + src;                                // amoadd.w
    case 0x04: return old ^ src;                                // amoxor.w
    case 0x0c: return old & src;                                // amoand.w
    case 0x08: return old | src;                                // amoor.w
    case 0x10: return (int32_t)old < (int32_t)src ? old : src;  // amomin.w
    case 0x14: return (int32_t)old > (int32_t)src ? old : src;  // amomax.w
    case 0x18: return old < src ? old : src;                    // amominu.w
    case 0x1c: return old > src ? old : src;                    // amomaxu.w
    default: return old;
  }
}

static inline bool amo_raise_misaligned(word_t addr, uint32_t funct5) {
  // AMO/LR/SC 编码有效但地址不对齐时应投递地址异常，不能退化成 illegal instruction。
  vaddr_set_fault(funct5 == 0x02 ? CAUSE_LOAD_MISALIGNED : CAUSE_STORE_MISALIGNED, addr);
  return true;
}

static inline bool amo_translate_paddr(word_t addr, int len, int type, paddr_t *paddr) {
  int mmu = isa_mmu_check(addr, len, type);
  if (mmu == MMU_DIRECT) {
    *paddr = (paddr_t)addr;
    return true;
  }
  if (mmu == MMU_TRANSLATE) {
    paddr_t translated = isa_mmu_translate(addr, len, type);
    if (translated != (paddr_t)-1) {
      *paddr = translated;
      return true;
    }
  }

  vaddr_set_fault(type == MEM_TYPE_WRITE ? CAUSE_STORE_PAGE_FAULT : CAUSE_LOAD_PAGE_FAULT, addr);
  return false;
}

static inline void lr_sc_set_reservation(word_t addr, int len, paddr_t paddr) {
  (void)addr;
  lr_reservation_valid = true;
  lr_reservation_paddr = paddr;
  lr_reservation_len = len;
}

static inline bool lr_sc_reservation_matches(word_t addr, int len, paddr_t *paddr) {
  if (!lr_reservation_valid || lr_reservation_len != len) return false;
  if (!amo_translate_paddr(addr, len, MEM_TYPE_WRITE, paddr)) return false;
  return *paddr == lr_reservation_paddr;
}

static inline word_t amo_compute_xlen(word_t old, word_t src, uint32_t funct5) {
  switch (funct5) {
    case 0x01: return src;                                      // amoswap.d
    case 0x00: return old + src;                                // amoadd.d
    case 0x04: return old ^ src;                                // amoxor.d
    case 0x0c: return old & src;                                // amoand.d
    case 0x08: return old | src;                                // amoor.d
    case 0x10: return (sword_t)old < (sword_t)src ? old : src;  // amomin.d
    case 0x14: return (sword_t)old > (sword_t)src ? old : src;  // amomax.d
    case 0x18: return old < src ? old : src;                    // amominu.d
    case 0x1c: return old > src ? old : src;                    // amomaxu.d
    default: return old;
  }
}

static inline bool exec_rva_amo(uint32_t inst, int rd, int rs1, int rs2) {
  uint32_t funct3 = FUNCT3(inst);
  uint32_t funct5 = BITS(inst, 31, 27);
  word_t addr = R(rs1);

  if (funct3 == 0x2) {
    if (funct5 == 0x02) {                                      // lr.w
      if ((addr & 0x3) != 0) return amo_raise_misaligned(addr, funct5);
      uint32_t old = Mr(addr, 4);
      if (vaddr_has_fault()) return true;
      paddr_t paddr = 0;
      if (!amo_translate_paddr(addr, 4, MEM_TYPE_READ, &paddr)) return true;
      lr_sc_set_reservation(addr, 4, paddr);
      R(rd) = amo_sext_word(old);
      return true;
    }
    if (funct5 == 0x03) {                                      // sc.w
      if ((addr & 0x3) != 0) return amo_raise_misaligned(addr, funct5);
      paddr_t paddr = 0;
      bool ok = lr_sc_reservation_matches(addr, 4, &paddr);
      if (vaddr_has_fault()) return true;
      if (ok) {
        Mw(addr, 4, (uint32_t)R(rs2));
        if (vaddr_has_fault()) return true;
      }
      lr_reservation_valid = false;
      R(rd) = ok ? 0 : 1;
      return true;
    }
    if (!amo_funct5_valid(funct5)) return false;
    if ((addr & 0x3) != 0) return amo_raise_misaligned(addr, funct5);

    uint32_t old = Mr(addr, 4);
    if (vaddr_has_fault()) return true;
    uint32_t result = amo_compute_w(old, (uint32_t)R(rs2), funct5);
    Mw(addr, 4, result);
    if (vaddr_has_fault()) return true;
    lr_reservation_valid = false;
    R(rd) = amo_sext_word(old);
    return true;
  }

  if (funct3 == 0x3 && ISDEF(CONFIG_ISA64)) {
    if (funct5 == 0x02) {                                      // lr.d
      if ((addr & 0x7) != 0) return amo_raise_misaligned(addr, funct5);
      word_t old = Mr(addr, 8);
      if (vaddr_has_fault()) return true;
      paddr_t paddr = 0;
      if (!amo_translate_paddr(addr, 8, MEM_TYPE_READ, &paddr)) return true;
      lr_sc_set_reservation(addr, 8, paddr);
      R(rd) = old;
      return true;
    }
    if (funct5 == 0x03) {                                      // sc.d
      if ((addr & 0x7) != 0) return amo_raise_misaligned(addr, funct5);
      paddr_t paddr = 0;
      bool ok = lr_sc_reservation_matches(addr, 8, &paddr);
      if (vaddr_has_fault()) return true;
      if (ok) {
        Mw(addr, 8, R(rs2));
        if (vaddr_has_fault()) return true;
      }
      lr_reservation_valid = false;
      R(rd) = ok ? 0 : 1;
      return true;
    }
    if (!amo_funct5_valid(funct5)) return false;
    if ((addr & 0x7) != 0) return amo_raise_misaligned(addr, funct5);

    word_t old = Mr(addr, 8);
    if (vaddr_has_fault()) return true;
    word_t result = amo_compute_xlen(old, R(rs2), funct5);
    Mw(addr, 8, result);
    if (vaddr_has_fault()) return true;
    lr_reservation_valid = false;
    R(rd) = old;
    return true;
  }

  return false;
}
#endif
