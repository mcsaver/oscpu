#include "trap.h"

#if defined(__ISA_RISCV64__)

#define PLIC_BASE        0x0c000000ul
#define PLIC_PRIORITY1   (PLIC_BASE + 0x000004ul)
#define PLIC_PENDING     (PLIC_BASE + 0x001000ul)
#define PLIC_S_ENABLE    (PLIC_BASE + 0x002080ul)
#define PLIC_S_THRESHOLD (PLIC_BASE + 0x201000ul)
#define PLIC_S_CLAIM     (PLIC_BASE + 0x201004ul)

#define MSTATUS_MPP_MASK (3ul << 11)
#define MSTATUS_MPP_S    (1ul << 11)
#define MSTATUS_SIE      (1ul << 1)
#define MSTATUS_SPP      (1ul << 8)
#define MIE_SEIE         (1ul << 9)
#define IRQ_CAUSE_MEI    11
#define IRQ_CAUSE_SEI    9
#define MCAUSE_INTERRUPT (1ul << 63)

volatile uintptr_t s_plic_seen;
volatile uintptr_t s_plic_scause;
volatile uintptr_t s_plic_sepc;
volatile uintptr_t s_plic_sstatus;
volatile uintptr_t s_plic_claim;

extern void s_plic_trap(void);
extern char s_wfi_pc_marker[];
static void s_payload(void) __attribute__((noinline, noreturn));

asm(
".align 2\n"
".globl s_plic_trap\n"
"s_plic_trap:\n"
"  csrr t0, scause\n"
"  la t1, s_plic_scause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, sepc\n"
"  la t1, s_plic_sepc\n"
"  sd t0, 0(t1)\n"
"  csrr t0, sstatus\n"
"  la t1, s_plic_sstatus\n"
"  sd t0, 0(t1)\n"
"  li t2, 0x0c201004\n"
"  lw t3, 0(t2)\n"
"  la t1, s_plic_claim\n"
"  sd t3, 0(t1)\n"
"  sw t3, 0(t2)\n"
"  la t1, s_plic_seen\n"
"  li t0, 1\n"
"  sd t0, 0(t1)\n"
"  sret\n"
);

static inline void write_csr_stvec(uintptr_t value) {
  asm volatile("csrw stvec, %0" : : "r"(value) : "memory");
}

static inline void write_csr_mideleg(uintptr_t value) {
  asm volatile("csrw mideleg, %0" : : "r"(value) : "memory");
}

static inline void write_csr_mepc(uintptr_t value) {
  asm volatile("csrw mepc, %0" : : "r"(value) : "memory");
}

static inline uintptr_t read_csr_mstatus(void) {
  uintptr_t value;
  asm volatile("csrr %0, mstatus" : "=r"(value));
  return value;
}

static inline void write_csr_mstatus(uintptr_t value) {
  asm volatile("csrw mstatus, %0" : : "r"(value) : "memory");
}

static inline void write_csr_sie(uintptr_t value) {
  asm volatile("csrw sie, %0" : : "r"(value) : "memory");
}

static inline void set_csr_sstatus(uintptr_t value) {
  asm volatile("csrs sstatus, %0" : : "r"(value) : "memory");
}

static inline void mret_to_s_payload(void) {
  uintptr_t status = read_csr_mstatus();
  status = (status & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  write_csr_mstatus(status);
  write_csr_mepc((uintptr_t)s_payload);
  asm volatile("mret" : : : "memory");
}

static inline void write_mmio32(uintptr_t addr, uint32_t value) {
  *(volatile uint32_t *)addr = value;
}

static void check_or_halt(bool cond, int code) {
  if (!cond) halt(code);
}

static void s_payload(void) {
  write_mmio32(PLIC_PRIORITY1, 1);
  write_mmio32(PLIC_S_ENABLE, 2);
  write_mmio32(PLIC_S_THRESHOLD, 0);
  write_mmio32(PLIC_PENDING, 2);
  write_csr_sie(MIE_SEIE);
  set_csr_sstatus(MSTATUS_SIE);

  asm volatile(
      ".globl s_wfi_pc_marker\n"
      "s_wfi_pc_marker:\n"
      "  wfi\n"
      : : : "memory");

  check_or_halt(s_plic_seen == 1, 2);
  check_or_halt(s_plic_claim == 1, 3);
  check_or_halt(s_plic_scause == (MCAUSE_INTERRUPT | IRQ_CAUSE_SEI), 4);
  check_or_halt(s_plic_sepc == (uintptr_t)s_wfi_pc_marker, 5);
  check_or_halt((s_plic_sstatus & MSTATUS_SPP) == MSTATUS_SPP, 6);

  halt(0);
  __builtin_unreachable();
}

int main() {
  s_plic_seen = 0;
  s_plic_scause = 0;
  s_plic_sepc = 0;
  s_plic_sstatus = 0;
  s_plic_claim = 0;

  write_csr_stvec((uintptr_t)s_plic_trap);
  write_csr_mideleg(1ul << IRQ_CAUSE_SEI);
  mret_to_s_payload();
  halt(1);
  return 1;
}

#else

int main() {
  return 0;
}

#endif
