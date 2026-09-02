#include "trap.h"

typedef unsigned int uint32_t;

#ifdef __ISA_RISCV64__
typedef unsigned long uintptr_t;
#define WORD_SUFFIX ul
#define WORD_C(x) x##ul
#else
typedef unsigned int uintptr_t;
#define WORD_C(x) x##u
#endif

#define CHECK1(OP, A, EXPECT) do { \
  uintptr_t out; \
  asm volatile(OP " %0, %1" : "=r"(out) : "r"((uintptr_t)(A))); \
  check(out == (uintptr_t)(EXPECT)); \
} while (0)

#define CHECK2(OP, A, B, EXPECT) do { \
  uintptr_t out; \
  asm volatile(OP " %0, %1, %2" : "=r"(out) : "r"((uintptr_t)(A)), "r"((uintptr_t)(B))); \
  check(out == (uintptr_t)(EXPECT)); \
} while (0)

int main() {
  uintptr_t out;

  /* bit5 原本为零，确保 bseti 的正向断言能观察到真实改位。 */
  asm volatile("bseti %0, %1, 5" : "=r"(out) : "r"(WORD_C(0x12345658)));
  check(out == WORD_C(0x12345678));
  asm volatile("bclri %0, %1, 4" : "=r"(out) : "r"(WORD_C(0x12345678)));
  check(out == WORD_C(0x12345668));
  asm volatile("binvi %0, %1, 3" : "=r"(out) : "r"(WORD_C(0x12345678)));
  check(out == WORD_C(0x12345670));
  asm volatile("rori %0, %1, 8" : "=r"(out) : "r"(WORD_C(0x12345678)));
#ifdef __ISA_RISCV64__
  check(out == WORD_C(0x7800000000123456));
#else
  check(out == WORD_C(0x78123456));
#endif
  asm volatile("bexti %0, %1, 3" : "=r"(out) : "r"(WORD_C(0x12345678)));
  check(out == WORD_C(0x00000001));

#ifdef __ISA_RISCV64__
  CHECK1("clz", 0ul, 64ul);
  CHECK1("ctz", 0ul, 64ul);
  CHECK1("clz", 0x00100000ul, 0x0000002bul);
  CHECK1("ctz", 0x00100000ul, 0x00000014ul);
  CHECK1("cpop", 0xf0f10001ul, 0x0000000aul);
  CHECK1("sext.b", 0x00000080ul, 0xffffffffffffff80ul);
  CHECK1("sext.h", 0x00008001ul, 0xffffffffffff8001ul);
  CHECK1("orc.b", 0x12003400ul, 0x00000000ff00ff00ul);
  CHECK1("rev8", 0x12345678ul, 0x7856341200000000ul);
  CHECK1("zext.h", 0xffffabcdul, 0x0000abcdul);
#else
  CHECK1("clz", 0u, 32u);
  CHECK1("ctz", 0u, 32u);
  CHECK1("clz", 0x00100000u, 0x0000000bu);
  CHECK1("ctz", 0x00100000u, 0x00000014u);
  CHECK1("cpop", 0xf0f10001u, 0x0000000au);
  CHECK1("sext.b", 0x00000080u, 0xffffff80u);
  CHECK1("sext.h", 0x00008001u, 0xffff8001u);
  CHECK1("orc.b", 0x12003400u, 0xff00ff00u);
  CHECK1("rev8", 0x12345678u, 0x78563412u);
  CHECK1("zext.h", 0xffffabcdu, 0x0000abcdu);
#endif

  CHECK2("sh1add", WORD_C(0x11111111), WORD_C(0x01020304), WORD_C(0x23242526));
  CHECK2("sh2add", WORD_C(0x11111111), WORD_C(0x01020304), WORD_C(0x45464748));
  CHECK2("sh3add", WORD_C(0x11111111), WORD_C(0x01020304), WORD_C(0x898a8b8c));
  CHECK2("andn", WORD_C(0xf0f0aa55), WORD_C(0x0ff00ff0), WORD_C(0xf000a005));
#ifdef __ISA_RISCV64__
  CHECK2("orn", 0x00ff00fful, 0x0f0f0f0ful, 0xfffffffff0fff0fful);
  CHECK2("xnor", 0x12345678ul, 0xf0f0f0f0ul, 0xffffffff1d3b5977ul);
  CHECK2("rol", 0x12345678ul, 5ul, 0x00000002468acf00ul);
  CHECK2("ror", 0x12345678ul, 5ul, 0xc00000000091a2b3ul);
  CHECK2("min", 0x8000000000000000ul, 0x7ffffffffffffffful, 0x8000000000000000ul);
  CHECK2("minu", 0x8000000000000000ul, 0x7ffffffffffffffful, 0x7ffffffffffffffful);
  CHECK2("max", 0x8000000000000000ul, 0x7ffffffffffffffful, 0x7ffffffffffffffful);
  CHECK2("maxu", 0x8000000000000000ul, 0x7ffffffffffffffful, 0x8000000000000000ul);
  CHECK2("clmul", 0x12345678ul, 0x10203040ul, 0x0121008c0dbd1e00ul);
  CHECK2("clmulr", 0x12345678ul, 0x10203040ul, 0x0ul);
  CHECK2("clmulh", 0x12345678ul, 0x10203040ul, 0x0ul);
  CHECK2("add.uw", 0xffffffff80000001ul, 0x10ul, 0x0000000080000011ul);
  CHECK2("sh1add.uw", 0xfffffffffffffffful, 1ul, 0x00000001fffffffful);
  CHECK2("sh2add.uw", 0xffffffff80000001ul, 3ul, 0x0000000200000007ul);
  CHECK2("sh3add.uw", 0xfffffffffffffffful, 7ul, 0x00000007fffffffful);
  asm volatile("slli.uw %0, %1, 4"
               : "=r"(out)
               : "r"(0xfffffffffffffffful));
  check(out == 0x0000000ffffffff0ul);
#else
  CHECK2("orn", 0x00ff00ffu, 0x0f0f0f0fu, 0xf0fff0ffu);
  CHECK2("xnor", 0x12345678u, 0xf0f0f0f0u, 0x1d3b5977u);
  CHECK2("rol", 0x12345678u, 5u, 0x468acf02u);
  CHECK2("ror", 0x12345678u, 5u, 0xc091a2b3u);
  CHECK2("min", 0x80000000u, 0x7fffffffu, 0x80000000u);
  CHECK2("minu", 0x80000000u, 0x7fffffffu, 0x7fffffffu);
  CHECK2("max", 0x80000000u, 0x7fffffffu, 0x7fffffffu);
  CHECK2("maxu", 0x80000000u, 0x7fffffffu, 0x80000000u);
  CHECK2("clmul", 0x12345678u, 0x10203040u, 0x0dbd1e00u);
  CHECK2("clmulr", 0x12345678u, 0x10203040u, 0x02420118u);
  CHECK2("clmulh", 0x12345678u, 0x10203040u, 0x0121008cu);

  /* RV32 寄存器位号只取低五位，37/35/34 分别等价于 5/3/2。 */
  CHECK2("rol", 0x12345678u, 37u, 0x468acf02u);
  CHECK2("ror", 0x12345678u, 37u, 0xc091a2b3u);
  CHECK2("bset", 0x12345678u, 33u, 0x1234567au);
  CHECK2("bclr", 0x12345678u, 35u, 0x12345670u);
  CHECK2("bext", 0x12345678u, 35u, 0x00000001u);
  CHECK2("binv", 0x12345678u, 34u, 0x1234567cu);
#endif
  CHECK2("rol", WORD_C(0x12345678), WORD_C(0), WORD_C(0x12345678));
  CHECK2("ror", WORD_C(0x12345678), WORD_C(0), WORD_C(0x12345678));
  CHECK2("bset", WORD_C(0x12345678), WORD_C(1), WORD_C(0x1234567a));
  CHECK2("bclr", WORD_C(0x12345678), WORD_C(3), WORD_C(0x12345670));
  CHECK2("bext", WORD_C(0x12345678), WORD_C(3), WORD_C(0x00000001));
  CHECK2("binv", WORD_C(0x12345678), WORD_C(2), WORD_C(0x1234567c));

  return 0;
}
