/* RV64M result semantics after opcode/funct fields have been decoded once. */

#ifdef CONFIG_RISCV_EXT_M
static inline bool rv_multiply_divide_result(
    RvOperation operation, word_t dividend, word_t divisor,
    word_t *result) {
  switch (operation) {
    case RV_OPERATION_MUL:
      *result = (word_t)((unsigned __int128)dividend * divisor);
      return true;
    case RV_OPERATION_MULH: {
      const __int128 product =
          (__int128)(sword_t)dividend * (__int128)(sword_t)divisor;
      *result = (word_t)((unsigned __int128)product >> XLEN_BITS);
      return true;
    }
    case RV_OPERATION_MULHSU: {
      const __int128 product =
          (__int128)(sword_t)dividend * (__int128)divisor;
      *result = (word_t)((unsigned __int128)product >> XLEN_BITS);
      return true;
    }
    case RV_OPERATION_MULHU: {
      const unsigned __int128 product =
          (unsigned __int128)dividend * (unsigned __int128)divisor;
      *result = (word_t)(product >> XLEN_BITS);
      return true;
    }
    case RV_OPERATION_DIV:
      if (divisor == 0) {
        *result = (word_t)-1;
      } else if (dividend == WORD_SIGN_BIT && divisor == (word_t)-1) {
        *result = WORD_SIGN_BIT;
      } else {
        *result = (word_t)((sword_t)dividend / (sword_t)divisor);
      }
      return true;
    case RV_OPERATION_DIVU:
      *result = divisor == 0 ? (word_t)-1 : dividend / divisor;
      return true;
    case RV_OPERATION_REM:
      if (divisor == 0) {
        *result = dividend;
      } else if (dividend == WORD_SIGN_BIT && divisor == (word_t)-1) {
        *result = 0;
      } else {
        *result = (word_t)((sword_t)dividend % (sword_t)divisor);
      }
      return true;
    case RV_OPERATION_REMU:
      *result = divisor == 0 ? dividend : dividend % divisor;
      return true;
    default:
      return false;
  }
}

static inline bool rv_multiply_divide_word_result(
    RvOperation operation, word_t dividend, word_t divisor,
    word_t *result) {
  const uint32_t dividend_u32 = (uint32_t)dividend;
  const uint32_t divisor_u32 = (uint32_t)divisor;
  const int32_t dividend_i32 = (int32_t)dividend_u32;
  const int32_t divisor_i32 = (int32_t)divisor_u32;

  switch (operation) {
    case RV_OPERATION_MULW:
      *result = sext32((uint32_t)(
          (int64_t)dividend_i32 * (int64_t)divisor_i32));
      return true;
    case RV_OPERATION_DIVW:
      if (divisor_u32 == 0) {
        *result = sext32(UINT32_MAX);
      } else if (dividend_u32 == UINT32_C(0x80000000) &&
                 divisor_u32 == UINT32_MAX) {
        *result = sext32(UINT32_C(0x80000000));
      } else {
        *result = sext32((uint32_t)(dividend_i32 / divisor_i32));
      }
      return true;
    case RV_OPERATION_DIVUW:
      *result = sext32(
          divisor_u32 == 0 ? UINT32_MAX : dividend_u32 / divisor_u32);
      return true;
    case RV_OPERATION_REMW:
      if (divisor_u32 == 0) {
        *result = sext32(dividend_u32);
      } else if (dividend_u32 == UINT32_C(0x80000000) &&
                 divisor_u32 == UINT32_MAX) {
        *result = 0;
      } else {
        *result = sext32((uint32_t)(dividend_i32 % divisor_i32));
      }
      return true;
    case RV_OPERATION_REMUW:
      *result = sext32(
          divisor_u32 == 0 ? dividend_u32 : dividend_u32 % divisor_u32);
      return true;
    default:
      return false;
  }
}
#endif
