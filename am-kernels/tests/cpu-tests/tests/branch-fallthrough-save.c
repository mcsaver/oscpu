#include "trap.h"

#if defined(__ISA_RISCV64__)

typedef unsigned long uintptr_t;

uintptr_t branch_fallthrough_save_probe(uintptr_t value, uintptr_t branch_arg);

asm(
".text\n"
".align 3\n"
".globl branch_fallthrough_save_probe\n"
"branch_fallthrough_save_probe:\n"
"  addi sp, sp, -80\n"
"  sd s5, 0(sp)\n"
"  mv s5, a0\n"
"  .option push\n"
"  .option norvc\n"
"  .balign 8\n"
"  blt a1, zero, 1f\n"
"  sd s5, 24(sp)\n"
"  addi s5, sp, 12\n"
"  ld a0, 24(sp)\n"
"  j 2f\n"
"1:\n"
"  li a0, -1\n"
"2:\n"
"  .option pop\n"
"  ld s5, 0(sp)\n"
"  addi sp, sp, 80\n"
"  ret\n"
);

int main(void) {
  for (uintptr_t i = 0; i < 64; i++) {
    uintptr_t value = 0xff00ul + i;
    check(branch_fallthrough_save_probe(value, 1) == value);
  }

  check(branch_fallthrough_save_probe(0x80045c6cul, 0) == 0x80045c6cul);
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
