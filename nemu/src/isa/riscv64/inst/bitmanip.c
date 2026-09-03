/* Zba/Zbb/Zbc/Zbs result semantics after one pure architectural decode. */

#ifdef CONFIG_RISCV_EXT_B
static inline word_t rv_rotate_right_word(uint32_t value, uint32_t shamt) {
  const uint32_t amount = SHAMT5(shamt);
  const uint32_t rotated = amount == 0
      ? value
      : (value >> amount) | (value << (32 - amount));
  return sext32(rotated);
}

static inline word_t rv_rotate_left_word(uint32_t value, uint32_t shamt) {
  return rv_rotate_right_word(value, 32u - SHAMT5(shamt));
}

static inline bool rv_bitmanip_immediate_result(
    RvOperation operation, word_t source, word_t immediate,
    word_t *result) {
  switch (operation) {
    case RV_OPERATION_BSETI:
      *result = source | ((word_t)1 << immediate);
      return true;
    case RV_OPERATION_BCLRI:
      *result = source & ~((word_t)1 << immediate);
      return true;
    case RV_OPERATION_BINVI:
      *result = source ^ ((word_t)1 << immediate);
      return true;
    case RV_OPERATION_CLZ:
      *result = clz_xlen(source);
      return true;
    case RV_OPERATION_CTZ:
      *result = ctz_xlen(source);
      return true;
    case RV_OPERATION_CPOP:
      *result = cpop_xlen(source);
      return true;
    case RV_OPERATION_SEXT_B:
      *result = sext_b_xlen(source);
      return true;
    case RV_OPERATION_SEXT_H:
      *result = sext_h_xlen(source);
      return true;
    case RV_OPERATION_RORI:
      *result = ror_xlen(source, immediate);
      return true;
    case RV_OPERATION_BEXTI:
      *result = (source >> immediate) & 1u;
      return true;
    case RV_OPERATION_ORC_B:
      *result = orc_b_xlen(source);
      return true;
    case RV_OPERATION_REV8:
      *result = rev8_xlen(source);
      return true;
    default:
      return false;
  }
}

static inline bool rv_bitmanip_immediate_word_result(
    RvOperation operation, word_t source, word_t immediate,
    word_t *result) {
  const uint32_t source_word = (uint32_t)source;

  switch (operation) {
    case RV_OPERATION_SLLI_UW:
      *result = (word_t)source_word << immediate;
      return true;
    case RV_OPERATION_CLZW:
      *result = source_word == 0
          ? 32 : (word_t)__builtin_clz(source_word);
      return true;
    case RV_OPERATION_CTZW:
      *result = source_word == 0
          ? 32 : (word_t)__builtin_ctz(source_word);
      return true;
    case RV_OPERATION_CPOPW:
      *result = (word_t)__builtin_popcount(source_word);
      return true;
    case RV_OPERATION_RORIW:
      *result = rv_rotate_right_word(source_word, immediate);
      return true;
    default:
      return false;
  }
}

static inline bool rv_bitmanip_register_result(
    RvOperation operation, word_t lhs, word_t rhs, word_t *result) {
  switch (operation) {
    case RV_OPERATION_SH1ADD:
      *result = (lhs << 1) + rhs;
      return true;
    case RV_OPERATION_SH2ADD:
      *result = (lhs << 2) + rhs;
      return true;
    case RV_OPERATION_SH3ADD:
      *result = (lhs << 3) + rhs;
      return true;
    case RV_OPERATION_ANDN:
      *result = lhs & ~rhs;
      return true;
    case RV_OPERATION_ORN:
      *result = lhs | ~rhs;
      return true;
    case RV_OPERATION_XNOR:
      *result = ~(lhs ^ rhs);
      return true;
    case RV_OPERATION_ROL:
      *result = rol_xlen(lhs, rhs);
      return true;
    case RV_OPERATION_ROR:
      *result = ror_xlen(lhs, rhs);
      return true;
    case RV_OPERATION_MIN:
      *result = (sword_t)lhs < (sword_t)rhs ? lhs : rhs;
      return true;
    case RV_OPERATION_MINU:
      *result = lhs < rhs ? lhs : rhs;
      return true;
    case RV_OPERATION_MAX:
      *result = (sword_t)lhs > (sword_t)rhs ? lhs : rhs;
      return true;
    case RV_OPERATION_MAXU:
      *result = lhs > rhs ? lhs : rhs;
      return true;
    case RV_OPERATION_CLMUL:
      *result = clmul_xlen(lhs, rhs);
      return true;
    case RV_OPERATION_CLMULR:
      *result = clmulr_xlen(lhs, rhs);
      return true;
    case RV_OPERATION_CLMULH:
      *result = clmulh_xlen(lhs, rhs);
      return true;
    case RV_OPERATION_BSET:
      *result = lhs | ((word_t)1 << SHAMT_XLEN(rhs));
      return true;
    case RV_OPERATION_BCLR:
      *result = lhs & ~((word_t)1 << SHAMT_XLEN(rhs));
      return true;
    case RV_OPERATION_BEXT:
      *result = (lhs >> SHAMT_XLEN(rhs)) & 1u;
      return true;
    case RV_OPERATION_BINV:
      *result = lhs ^ ((word_t)1 << SHAMT_XLEN(rhs));
      return true;
    default:
      return false;
  }
}

static inline bool rv_bitmanip_register_word_result(
    RvOperation operation, word_t lhs, word_t rhs, word_t *result) {
  const word_t lhs_unsigned_word = (uint32_t)lhs;

  switch (operation) {
    case RV_OPERATION_ADD_UW:
      *result = lhs_unsigned_word + rhs;
      return true;
    case RV_OPERATION_SH1ADD_UW:
      *result = (lhs_unsigned_word << 1) + rhs;
      return true;
    case RV_OPERATION_SH2ADD_UW:
      *result = (lhs_unsigned_word << 2) + rhs;
      return true;
    case RV_OPERATION_SH3ADD_UW:
      *result = (lhs_unsigned_word << 3) + rhs;
      return true;
    case RV_OPERATION_ZEXT_H:
      *result = lhs & UINT32_C(0xffff);
      return true;
    case RV_OPERATION_ROLW:
      *result = rv_rotate_left_word((uint32_t)lhs, (uint32_t)rhs);
      return true;
    case RV_OPERATION_RORW:
      *result = rv_rotate_right_word((uint32_t)lhs, (uint32_t)rhs);
      return true;
    default:
      return false;
  }
}
#endif
