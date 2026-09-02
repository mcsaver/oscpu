/* RV32M 乘除法只接收手册助记符和已读取的 XLEN 操作数。 */

static inline bool rv32_multiply_divide_result(
    Rv32Operation operation, word_t lhs, word_t rhs, word_t *result) {
  switch (operation) {
    case RV32_OPERATION_MUL: {
      const uint64_t product = (uint64_t)lhs * (uint64_t)rhs;
      *result = (word_t)product;
      return true;
    }
    case RV32_OPERATION_MULH: {
      const int64_t product =
          (int64_t)(int32_t)lhs * (int64_t)(int32_t)rhs;
      *result = (word_t)((uint64_t)product >> 32);
      return true;
    }
    case RV32_OPERATION_MULHSU: {
      const int64_t product =
          (int64_t)(int32_t)lhs * (int64_t)(uint32_t)rhs;
      *result = (word_t)((uint64_t)product >> 32);
      return true;
    }
    case RV32_OPERATION_MULHU: {
      const uint64_t product = (uint64_t)lhs * (uint64_t)rhs;
      *result = (word_t)(product >> 32);
      return true;
    }
    case RV32_OPERATION_DIV:
      if (rhs == 0) *result = (word_t)-1;
      else if (lhs == WORD_SIGN_BIT && rhs == (word_t)-1) {
        *result = WORD_SIGN_BIT;
      } else {
        *result = (sword_t)lhs / (sword_t)rhs;
      }
      return true;
    case RV32_OPERATION_DIVU:
      *result = rhs == 0 ? (word_t)-1 : lhs / rhs;
      return true;
    case RV32_OPERATION_REM:
      if (rhs == 0) *result = lhs;
      else if (lhs == WORD_SIGN_BIT && rhs == (word_t)-1) {
        *result = 0;
      } else {
        *result = (sword_t)lhs % (sword_t)rhs;
      }
      return true;
    case RV32_OPERATION_REMU:
      *result = rhs == 0 ? lhs : lhs % rhs;
      return true;
    default:
      return false;
  }
}
