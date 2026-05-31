#include "trap.h"

#if defined(__ISA_RISCV64__)

#define EXC_BREAKPOINT 3

volatile uintptr_t semihost_seen;
volatile uintptr_t semihost_mcause;
volatile uintptr_t semihost_mepc;
volatile uintptr_t semihost_mtval;

extern void semihost_trap(void);
extern char semihost_ebreak_site[];

asm(
".align 2\n"
".globl semihost_trap\n"
"semihost_trap:\n"
"  csrr t0, mcause\n"
"  la t1, semihost_mcause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  la t1, semihost_mepc\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, semihost_mtval\n"
"  sd t0, 0(t1)\n"
"  la t1, semihost_seen\n"
"  li t0, 1\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
);

static inline void write_csr_mtvec(uintptr_t value) {
  asm volatile("csrw mtvec, %0" : : "r"(value) : "memory");
}

int main(void) {
  semihost_seen = 0;
  semihost_mcause = 0;
  semihost_mepc = 0;
  semihost_mtval = 0;

  write_csr_mtvec((uintptr_t)semihost_trap);

  asm volatile(
      ".balign 8\n"
      ".4byte 0x01f01013\n"
      ".globl semihost_ebreak_site\n"
      "semihost_ebreak_site:\n"
      ".4byte 0x00100073\n"
      ".4byte 0x40705013\n"
      ::: "memory");

  check(semihost_seen == 1);
  check(semihost_mcause == EXC_BREAKPOINT);
  check(semihost_mepc == (uintptr_t)semihost_ebreak_site);
  check(semihost_mtval == 0);
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
