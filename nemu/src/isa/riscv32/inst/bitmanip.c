/* RV32 Zba/Zbb/Zbc/Zbs：这里只陈述手册运算，不解释原始编码。 */

static inline word_t rv32_rotate_left(word_t value, word_t amount) {
  const word_t shamt = amount & 0x1fu;
  if (shamt == 0) return value;
  return (value << shamt) | (value >> (32 - shamt));
}

static inline word_t rv32_rotate_right(word_t value, word_t amount) {
  const word_t shamt = amount & 0x1fu;
  if (shamt == 0) return value;
  return (value >> shamt) | (value << (32 - shamt));
}

static inline word_t rv32_count_leading_zero_bits(word_t value) {
  if (value == 0) return 32;
  word_t count = 0;
  for (word_t mask = 0x80000000u; (value & mask) == 0; mask >>= 1) {
    count++;
  }
  return count;
}

static inline word_t rv32_count_trailing_zero_bits(word_t value) {
  if (value == 0) return 32;
  word_t count = 0;
  for (word_t mask = 1; (value & mask) == 0; mask <<= 1) {
    count++;
  }
  return count;
}

static inline word_t rv32_count_set_bits(word_t value) {
  word_t count = 0;
  for (uint32_t bit = 0; bit < 32; bit++) {
    count += (value >> bit) & 1u;
  }
  return count;
}

static inline word_t rv32_sign_extend_byte(word_t value) {
  const word_t byte = value & 0xffu;
  return (byte & 0x80u) != 0 ? byte | 0xffffff00u : byte;
}

static inline word_t rv32_sign_extend_halfword(word_t value) {
  const word_t halfword = value & 0xffffu;
  return (halfword & 0x8000u) != 0
      ? halfword | 0xffff0000u : halfword;
}

static inline word_t rv32_or_combine_bytes(word_t value) {
  word_t result = 0;
  for (uint32_t byte = 0; byte < 4; byte++) {
    if (((value >> (byte * 8)) & 0xffu) != 0) {
      result |= (word_t)0xffu << (byte * 8);
    }
  }
  return result;
}

static inline word_t rv32_reverse_bytes(word_t value) {
  return ((value & 0x000000ffu) << 24) |
         ((value & 0x0000ff00u) << 8) |
         ((value & 0x00ff0000u) >> 8) |
         ((value & 0xff000000u) >> 24);
}

static inline word_t rv32_carryless_multiply_low(word_t lhs, word_t rhs) {
  word_t result = 0;
  for (uint32_t bit = 0; bit < 32; bit++) {
    if (((rhs >> bit) & 1u) != 0) result ^= lhs << bit;
  }
  return result;
}

static inline word_t rv32_carryless_multiply_high(word_t lhs, word_t rhs) {
  word_t result = 0;
  for (uint32_t bit = 1; bit < 32; bit++) {
    if (((rhs >> bit) & 1u) != 0) result ^= lhs >> (32 - bit);
  }
  return result;
}

static inline word_t rv32_carryless_multiply_reversed(
    word_t lhs, word_t rhs) {
  word_t result = 0;
  for (uint32_t bit = 0; bit < 32; bit++) {
    if (((rhs >> bit) & 1u) != 0) result ^= lhs >> (31 - bit);
  }
  return result;
}

static inline bool rv32_bitmanip_result(
    Rv32Operation operation, word_t lhs, word_t rhs_or_shamt,
    word_t *result) {
  const word_t bit_index = rhs_or_shamt & 0x1fu;

  switch (operation) {
    case RV32_OPERATION_SH1ADD: *result = (lhs << 1) + rhs_or_shamt; return true;
    case RV32_OPERATION_SH2ADD: *result = (lhs << 2) + rhs_or_shamt; return true;
    case RV32_OPERATION_SH3ADD: *result = (lhs << 3) + rhs_or_shamt; return true;
    case RV32_OPERATION_ANDN: *result = lhs & ~rhs_or_shamt; return true;
    case RV32_OPERATION_ORN: *result = lhs | ~rhs_or_shamt; return true;
    case RV32_OPERATION_XNOR: *result = ~(lhs ^ rhs_or_shamt); return true;
    case RV32_OPERATION_CLZ: *result = rv32_count_leading_zero_bits(lhs); return true;
    case RV32_OPERATION_CTZ: *result = rv32_count_trailing_zero_bits(lhs); return true;
    case RV32_OPERATION_CPOP: *result = rv32_count_set_bits(lhs); return true;
    case RV32_OPERATION_SEXT_B: *result = rv32_sign_extend_byte(lhs); return true;
    case RV32_OPERATION_SEXT_H: *result = rv32_sign_extend_halfword(lhs); return true;
    case RV32_OPERATION_ROL: *result = rv32_rotate_left(lhs, rhs_or_shamt); return true;
    case RV32_OPERATION_ROR:
    case RV32_OPERATION_RORI:
      *result = rv32_rotate_right(lhs, rhs_or_shamt);
      return true;
    case RV32_OPERATION_MIN:
      *result = (sword_t)lhs < (sword_t)rhs_or_shamt ? lhs : rhs_or_shamt;
      return true;
    case RV32_OPERATION_MINU:
      *result = lhs < rhs_or_shamt ? lhs : rhs_or_shamt;
      return true;
    case RV32_OPERATION_MAX:
      *result = (sword_t)lhs > (sword_t)rhs_or_shamt ? lhs : rhs_or_shamt;
      return true;
    case RV32_OPERATION_MAXU:
      *result = lhs > rhs_or_shamt ? lhs : rhs_or_shamt;
      return true;
    case RV32_OPERATION_ORC_B: *result = rv32_or_combine_bytes(lhs); return true;
    case RV32_OPERATION_REV8: *result = rv32_reverse_bytes(lhs); return true;
    case RV32_OPERATION_ZEXT_H: *result = lhs & 0xffffu; return true;
    case RV32_OPERATION_CLMUL:
      *result = rv32_carryless_multiply_low(lhs, rhs_or_shamt);
      return true;
    case RV32_OPERATION_CLMULR:
      *result = rv32_carryless_multiply_reversed(lhs, rhs_or_shamt);
      return true;
    case RV32_OPERATION_CLMULH:
      *result = rv32_carryless_multiply_high(lhs, rhs_or_shamt);
      return true;
    case RV32_OPERATION_BSET:
    case RV32_OPERATION_BSETI:
      *result = lhs | ((word_t)1 << bit_index);
      return true;
    case RV32_OPERATION_BCLR:
    case RV32_OPERATION_BCLRI:
      *result = lhs & ~((word_t)1 << bit_index);
      return true;
    case RV32_OPERATION_BEXT:
    case RV32_OPERATION_BEXTI:
      *result = (lhs >> bit_index) & 1u;
      return true;
    case RV32_OPERATION_BINV:
    case RV32_OPERATION_BINVI:
      *result = lhs ^ ((word_t)1 << bit_index);
      return true;
    default:
      return false;
  }
}
