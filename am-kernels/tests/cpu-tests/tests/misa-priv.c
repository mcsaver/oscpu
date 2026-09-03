#include "trap.h"

#if defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)

#define MISA_BIT(ch) ((uintptr_t)1 << ((ch) - 'A'))

#if __riscv_xlen == 64
#define MISA_MXL_MASK ((uintptr_t)3 << 62)
#define MISA_MXL_IMPLEMENTED ((uintptr_t)2 << 62)
#else
#define MISA_MXL_MASK ((uintptr_t)3 << 30)
#define MISA_MXL_IMPLEMENTED ((uintptr_t)1 << 30)
#endif

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

  /* misa 是当前 hart ISA capability 的只读手册视图；MXL 只由 XLEN 决定。 */
  check((misa & MISA_MXL_MASK) == MISA_MXL_IMPLEMENTED);
#ifdef __riscv_32e
  check((misa & MISA_BIT('E')) != 0);
  check((misa & MISA_BIT('I')) == 0);
#else
  check((misa & MISA_BIT('I')) != 0);
#endif
#if defined(__riscv_mul) && defined(__riscv_div)
  check((misa & MISA_BIT('M')) != 0);
#else
  check((misa & MISA_BIT('M')) == 0);
#endif
#ifdef __riscv_atomic
  check((misa & MISA_BIT('A')) != 0);
#else
  check((misa & MISA_BIT('A')) == 0);
#endif
#ifdef __riscv_compressed
  check((misa & MISA_BIT('C')) != 0);
#else
  check((misa & MISA_BIT('C')) == 0);
#endif
#if defined(__riscv_flen) && __riscv_flen >= 32
  check((misa & MISA_BIT('F')) != 0);
#else
  check((misa & MISA_BIT('F')) == 0);
#endif
#if defined(__riscv_flen) && __riscv_flen >= 64
  check((misa & MISA_BIT('D')) != 0);
#else
  check((misa & MISA_BIT('D')) == 0);
#endif
  check((misa & MISA_BIT('S')) != 0);
  check((misa & MISA_BIT('U')) != 0);

  /* NEMU 的 ISA 集在创建 hart 时固定；misa 是 WARL，写入按忽略处理。 */
  asm volatile("csrw misa, %0" : : "r"(~misa) : "memory");
  check(read_misa() == misa);

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
