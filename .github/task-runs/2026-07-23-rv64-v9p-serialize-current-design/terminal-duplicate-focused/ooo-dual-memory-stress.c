#include "trap.h"

#if defined(__ISA_RISCV64__)

typedef unsigned long word_t;

static volatile word_t buffer_a[8] __attribute__((aligned(64)));
static volatile word_t buffer_b[8] __attribute__((aligned(64)));

void ooo_dual_memory_stress(volatile word_t *src, volatile word_t *dst,
                            word_t rounds);

asm(
".text\n"
".align 3\n"
".globl ooo_dual_memory_stress\n"
"ooo_dual_memory_stress:\n"
"  .option push\n"
"  .option norvc\n"
"1:\n"
"  ld t0, 0(a0)\n"
"  ld t1, 8(a0)\n"
"  sd t0, 0(a1)\n"
"  sd t1, 8(a1)\n"
"  ld t2, 16(a0)\n"
"  ld t3, 24(a0)\n"
"  sd t2, 16(a1)\n"
"  sd t3, 24(a1)\n"
"  ld t0, 32(a0)\n"
"  ld t1, 40(a0)\n"
"  sd t0, 32(a1)\n"
"  sd t1, 40(a1)\n"
"  ld t2, 48(a0)\n"
"  ld t3, 56(a0)\n"
"  sd t2, 48(a1)\n"
"  sd t3, 56(a1)\n"
"  mv t4, a0\n"
"  mv a0, a1\n"
"  mv a1, t4\n"
"  addi a2, a2, -1\n"
"  bnez a2, 1b\n"
"  fence rw, rw\n"
"  .option pop\n"
"  ret\n"
);

int main(void) {
  word_t i;

  for (i = 0; i < 8; i = i + 1) {
    buffer_a[i] = 0x1020304050607080ul ^
                  (i * 0x1111111111111111ul);
    buffer_b[i] = 0;
  }

  ooo_dual_memory_stress(buffer_a, buffer_b, 131072ul);

  for (i = 0; i < 8; i = i + 1) {
    check(buffer_a[i] ==
          (0x1020304050607080ul ^ (i * 0x1111111111111111ul)));
    check(buffer_b[i] ==
          (0x1020304050607080ul ^ (i * 0x1111111111111111ul)));
  }
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
