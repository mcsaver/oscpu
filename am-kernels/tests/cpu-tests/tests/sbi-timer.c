#include "trap.h"

#if defined(__ISA_RISCV64__)

#define CLINT_BASE       0x02000000ul
#define CLINT_MTIMECMP   (CLINT_BASE + 0x00004000ul)

#define MSTATUS_MPP_MASK (3ul << 11)
#define MSTATUS_MPP_S    (1ul << 11)
#define MSTATUS_SIE      (1ul << 1)
#define MSTATUS_SPP      (1ul << 8)
#define MIE_STIE         (1ul << 5)
#define IRQ_CAUSE_MTI    7
#define IRQ_CAUSE_STI    5
#define EXC_ECALL_SMODE  9
#define MCAUSE_INTERRUPT (1ul << 63)
#define SBI_EXT_TIME     0x54494d45ul

volatile uintptr_t sbi_timer_m_seen;
volatile uintptr_t sbi_timer_s_seen;
volatile uintptr_t sbi_timer_mcause;
volatile uintptr_t sbi_timer_mepc;
volatile uintptr_t sbi_timer_a0;
volatile uintptr_t sbi_timer_a6;
volatile uintptr_t sbi_timer_a7;
volatile uintptr_t sbi_timer_scause;
volatile uintptr_t sbi_timer_sepc;
volatile uintptr_t sbi_timer_sstatus;

extern void m_sbi_timer_trap(void);
extern void s_timer_trap(void);
extern char s_timer_wfi_pc_marker[];
static void s_timer_payload(void) __attribute__((noinline, noreturn));

asm(
".align 2\n"
".globl m_sbi_timer_trap\n"
"m_sbi_timer_trap:\n"
"  csrr t0, mcause\n"
"  la t1, sbi_timer_mcause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  la t1, sbi_timer_mepc\n"
"  sd t0, 0(t1)\n"
"  la t1, sbi_timer_a0\n"
"  sd a0, 0(t1)\n"
"  la t1, sbi_timer_a6\n"
"  sd a6, 0(t1)\n"
"  la t1, sbi_timer_a7\n"
"  sd a7, 0(t1)\n"
"  li t2, 0x02004004\n"
"  li t3, -1\n"
"  sw t3, 0(t2)\n"
"  li t2, 0x02004000\n"
"  sw zero, 0(t2)\n"
"  li t2, 0x02004004\n"
"  sw zero, 0(t2)\n"
"  la t1, sbi_timer_m_seen\n"
"  li t0, 1\n"
"  sd t0, 0(t1)\n"
"  li a0, 0\n"
"  li a1, 0\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
".align 2\n"
".globl s_timer_trap\n"
"s_timer_trap:\n"
"  csrr t0, scause\n"
"  la t1, sbi_timer_scause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, sepc\n"
"  la t1, sbi_timer_sepc\n"
"  sd t0, 0(t1)\n"
"  csrr t0, sstatus\n"
"  la t1, sbi_timer_sstatus\n"
"  sd t0, 0(t1)\n"
"  li t2, 0x02004004\n"
"  li t3, -1\n"
"  sw t3, 0(t2)\n"
"  li t2, 0x02004000\n"
"  sw t3, 0(t2)\n"
"  la t1, sbi_timer_s_seen\n"
"  li t0, 1\n"
"  sd t0, 0(t1)\n"
"  sret\n"
);

static inline void write_csr_mtvec(uintptr_t value) {
  asm volatile("csrw mtvec, %0" : : "r"(value) : "memory");
}

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
  write_csr_mepc((uintptr_t)s_timer_payload);
  asm volatile("mret" : : : "memory");
}

static inline uintptr_t sbi_set_timer_now(void) {
  register uintptr_t a0 asm("a0") = 0;
  register uintptr_t a1 asm("a1") = 0;
  register uintptr_t a6 asm("a6") = 0;
  register uintptr_t a7 asm("a7") = SBI_EXT_TIME;
  asm volatile("ecall"
               : "+r"(a0), "+r"(a1)
               : "r"(a6), "r"(a7)
               : "memory", "t0", "t1", "t2", "t3", "t4", "t5");
  return a0 | a1;
}

static void check_or_halt(bool cond, int code) {
  if (!cond) halt(code);
}

static void s_timer_payload(void) {
  write_csr_stvec((uintptr_t)s_timer_trap);
  write_csr_sie(MIE_STIE);

  uintptr_t ret = sbi_set_timer_now();
  check_or_halt(ret == 0, 2);
  check_or_halt(sbi_timer_m_seen == 1, 3);
  check_or_halt(sbi_timer_mcause == EXC_ECALL_SMODE, 4);
  check_or_halt(sbi_timer_a0 == 0, 5);
  check_or_halt(sbi_timer_a6 == 0, 6);
  check_or_halt(sbi_timer_a7 == SBI_EXT_TIME, 7);

  set_csr_sstatus(MSTATUS_SIE);
  asm volatile(
      ".globl s_timer_wfi_pc_marker\n"
      "s_timer_wfi_pc_marker:\n"
      "  wfi\n"
      : : : "memory");

  check_or_halt(sbi_timer_s_seen == 1, 8);
  check_or_halt(sbi_timer_scause == (MCAUSE_INTERRUPT | IRQ_CAUSE_STI), 9);
  check_or_halt(sbi_timer_sepc == (uintptr_t)s_timer_wfi_pc_marker, 10);
  check_or_halt((sbi_timer_sstatus & MSTATUS_SPP) == MSTATUS_SPP, 11);

  halt(0);
  __builtin_unreachable();
}

int main() {
  sbi_timer_m_seen = 0;
  sbi_timer_s_seen = 0;
  sbi_timer_mcause = 0;
  sbi_timer_mepc = 0;
  sbi_timer_a0 = 0;
  sbi_timer_a6 = 0;
  sbi_timer_a7 = 0;
  sbi_timer_scause = 0;
  sbi_timer_sepc = 0;
  sbi_timer_sstatus = 0;

  *(volatile uint32_t *)(CLINT_MTIMECMP + 4) = 0xffffffffu;
  *(volatile uint32_t *)(CLINT_MTIMECMP + 0) = 0xffffffffu;

  write_csr_mtvec((uintptr_t)m_sbi_timer_trap);
  write_csr_mideleg(1ul << IRQ_CAUSE_STI);
  mret_to_s_payload();
  halt(1);
  return 1;
}

#else

int main() {
  halt(0);
  return 0;
}

#endif
