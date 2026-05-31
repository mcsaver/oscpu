#include "trap.h"

#if defined(__ISA_RISCV64__)

typedef unsigned long uintptr_t;
typedef unsigned char uint8_t;

static const uint8_t src[] = "5012-coremark-branch-loop";
static volatile uint8_t dst[sizeof(src)];

void branch_resolve_loop_probe(volatile uint8_t *out, const uint8_t *in,
                               uintptr_t len, uintptr_t rounds);

asm(
".text\n"
".align 3\n"
".globl branch_resolve_loop_probe\n"
"branch_resolve_loop_probe:\n"
"  .option push\n"
"  .option norvc\n"
"  beqz a3, 3f\n"
"2:\n"
"  mv t0, a1\n"
"  add t1, a1, a2\n"
"  mv t2, a0\n"
"1:\n"
"  lbu t3, 0(t0)\n"
"  addi t0, t0, 1\n"
"  sb t3, 0(t2)\n"
"  addi t2, t2, 1\n"
"  bne t0, t1, 1b\n"
"  addi a3, a3, -1\n"
"  bnez a3, 2b\n"
"3:\n"
"  .option pop\n"
"  ret\n"
);

int main(void) {
  for (uintptr_t i = 0; i < sizeof(dst); i++) {
    dst[i] = 0xa5u;
  }

  branch_resolve_loop_probe(dst, src, sizeof(src), 257);

  for (uintptr_t i = 0; i < sizeof(src); i++) {
    check(dst[i] == src[i]);
  }

  branch_resolve_loop_probe(dst, src, 1, 64);
  check(dst[0] == src[0]);
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
