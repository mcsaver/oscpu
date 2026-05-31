#include "trap.h"

#if defined(__ISA_RISCV64__)

typedef unsigned long uintptr_t;

static volatile uintptr_t order_buf[4] __attribute__((aligned(64)));

uintptr_t ooo_mem_order_probe(volatile uintptr_t *ptr, uintptr_t seed,
                              uintptr_t rounds);

asm(
".text\n"
".align 3\n"
".globl ooo_mem_order_probe\n"
"ooo_mem_order_probe:\n"
"  .option push\n"
"  .option norvc\n"
"  mv t0, a0\n"
"  mv t1, a1\n"
"  mv t2, a2\n"
"  li t5, 0\n"
"  li t6, 17\n"
"1:\n"
"  add t1, t1, t6\n"
"  sd t1, 0(t0)\n"
"  ld t3, 0(t0)\n"
"  xor t4, t3, t1\n"
"  or t5, t5, t4\n"
"  addi t2, t2, -1\n"
"  bnez t2, 1b\n"
"  mv a0, t5\n"
"  .option pop\n"
"  ret\n"
);

int main(void) {
  order_buf[0] = 0;
  order_buf[1] = 0;
  order_buf[2] = 0;
  order_buf[3] = 0;

  check(ooo_mem_order_probe(&order_buf[1], 0x123456789abcdef0ul, 2048) == 0);
  check(order_buf[0] == 0);
  check(order_buf[2] == 0);
  check(order_buf[3] == 0);
  check(order_buf[1] == 0x123456789abcdef0ul + 17ul * 2048ul);
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
