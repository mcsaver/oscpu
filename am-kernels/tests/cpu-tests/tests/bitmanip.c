#include "trap.h"

typedef unsigned int uint32_t;

#define CHECK1(OP, A, EXPECT) do { \
  uint32_t out; \
  asm volatile(OP " %0, %1" : "=r"(out) : "r"((uint32_t)(A))); \
  check(out == (uint32_t)(EXPECT)); \
} while (0)

#define CHECK2(OP, A, B, EXPECT) do { \
  uint32_t out; \
  asm volatile(OP " %0, %1, %2" : "=r"(out) : "r"((uint32_t)(A)), "r"((uint32_t)(B))); \
  check(out == (uint32_t)(EXPECT)); \
} while (0)

int main() {
  uint32_t out;

  asm volatile("bseti %0, %1, 5" : "=r"(out) : "r"(0x12345678u));
  check(out == 0x12345678u);
  asm volatile("bclri %0, %1, 4" : "=r"(out) : "r"(0x12345678u));
  check(out == 0x12345668u);
  asm volatile("binvi %0, %1, 3" : "=r"(out) : "r"(0x12345678u));
  check(out == 0x12345670u);
  asm volatile("rori %0, %1, 8" : "=r"(out) : "r"(0x12345678u));
  check(out == 0x78123456u);
  asm volatile("bexti %0, %1, 3" : "=r"(out) : "r"(0x12345678u));
  check(out == 0x00000001u);

  CHECK1("clz", 0x00100000u, 0x0000000bu);
  CHECK1("ctz", 0x00100000u, 0x00000014u);
  CHECK1("cpop", 0xf0f10001u, 0x0000000au);
  CHECK1("sext.b", 0x00000080u, 0xffffff80u);
  CHECK1("sext.h", 0x00008001u, 0xffff8001u);
  CHECK1("orc.b", 0x12003400u, 0xff00ff00u);
  CHECK1("rev8", 0x12345678u, 0x78563412u);
  CHECK1("zext.h", 0xffffabcdu, 0x0000abcdu);

  CHECK2("sh1add", 0x11111111u, 0x01020304u, 0x23242526u);
  CHECK2("sh2add", 0x11111111u, 0x01020304u, 0x45464748u);
  CHECK2("sh3add", 0x11111111u, 0x01020304u, 0x898a8b8cu);
  CHECK2("andn", 0xf0f0aa55u, 0x0ff00ff0u, 0xf000a005u);
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
  CHECK2("bset", 0x12345678u, 1u, 0x1234567au);
  CHECK2("bclr", 0x12345678u, 3u, 0x12345670u);
  CHECK2("bext", 0x12345678u, 3u, 0x00000001u);
  CHECK2("binv", 0x12345678u, 2u, 0x1234567cu);

  return 0;
}
