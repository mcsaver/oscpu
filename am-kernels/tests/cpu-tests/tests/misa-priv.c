#include "trap.h"

#if defined(__ISA_RISCV64__)

#define MISA_BIT(ch) (1ul << ((ch) - 'A'))
#define MISA_MXL_MASK (3ul << 62)
#define MISA_MXL_RV64 (2ul << 62)

static inline uintptr_t read_misa(void) {
  uintptr_t value;
  asm volatile("csrr %0, misa" : "=r"(value));
  return value;
}

static inline uintptr_t read_mvendorid(void) {
  uintptr_t value;
  asm volatile("csrr %0, mvendorid" : "=r"(value));
  return value;
}

static inline uintptr_t read_marchid(void) {
  uintptr_t value;
  asm volatile("csrr %0, marchid" : "=r"(value));
  return value;
}

static inline uintptr_t read_mimpid(void) {
  uintptr_t value;
  asm volatile("csrr %0, mimpid" : "=r"(value));
  return value;
}

static inline uintptr_t read_mhartid(void) {
  uintptr_t value;
  asm volatile("csrr %0, mhartid" : "=r"(value));
  return value;
}

int main(void) {
  uintptr_t misa = read_misa();

  check((misa & MISA_MXL_MASK) == MISA_MXL_RV64);
  check((misa & MISA_BIT('I')) != 0);
  check((misa & MISA_BIT('M')) != 0);
  check((misa & MISA_BIT('A')) != 0);
  check((misa & MISA_BIT('C')) != 0);
  check((misa & MISA_BIT('S')) != 0);
  check((misa & MISA_BIT('U')) != 0);
  check(read_mvendorid() == 0x79737978ul);
  check(read_marchid() == 26010035ul);
  check(read_mimpid() == 0);
  check(read_mhartid() == 0);
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
