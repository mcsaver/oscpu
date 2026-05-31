#include "trap.h"

#if defined(__ISA_RISCV64__)

#define UART_BASE        0x10000000ul
#define UART_IER         (UART_BASE + 1ul)
#define UART_IIR         (UART_BASE + 2ul)

#define PLIC_BASE        0x0c000000ul
#define PLIC_PRIORITY1   (PLIC_BASE + 0x000004ul)
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

volatile uintptr_t uart_irq_seen;
volatile uintptr_t uart_irq_scause;
volatile uintptr_t uart_irq_sepc;
volatile uintptr_t uart_irq_sstatus;
volatile uintptr_t uart_irq_claim;
volatile uintptr_t uart_irq_iir;

extern void s_uart_plic_trap(void);
extern char s_uart_wfi_pc_marker[];
static void s_uart_payload(void) __attribute__((noinline, noreturn));

asm(
".align 2\n"
".globl s_uart_plic_trap\n"
"s_uart_plic_trap:\n"
"  csrr t0, scause\n"
"  la t1, uart_irq_scause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, sepc\n"
"  la t1, uart_irq_sepc\n"
"  sd t0, 0(t1)\n"
"  csrr t0, sstatus\n"
"  la t1, uart_irq_sstatus\n"
"  sd t0, 0(t1)\n"
"  li t2, 0x0c201004\n"
"  lw t3, 0(t2)\n"
"  la t1, uart_irq_claim\n"
"  sd t3, 0(t1)\n"
"  li t4, 0x10000002\n"
"  lbu t5, 0(t4)\n"
"  la t1, uart_irq_iir\n"
"  sd t5, 0(t1)\n"
"  li t4, 0x10000001\n"
"  sb zero, 0(t4)\n"
"  sw t3, 0(t2)\n"
"  la t1, uart_irq_seen\n"
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
  write_csr_mepc((uintptr_t)s_uart_payload);
  asm volatile("mret" : : : "memory");
}

static inline void write_mmio32(uintptr_t addr, uint32_t value) {
  *(volatile uint32_t *)addr = value;
}

static inline void write_mmio8(uintptr_t addr, uint8_t value) {
  *(volatile uint8_t *)addr = value;
}

static inline uint8_t read_mmio8(uintptr_t addr) {
  return *(volatile uint8_t *)addr;
}

static void check_or_halt(bool cond, int code) {
  if (!cond) halt(code);
}

static void s_uart_payload(void) {
  write_mmio8(UART_IER, 0);
  (void)read_mmio8(UART_IIR);

  write_mmio32(PLIC_PRIORITY1, 1);
  write_mmio32(PLIC_S_ENABLE, 2);
  write_mmio32(PLIC_S_THRESHOLD, 0);

  write_mmio8(UART_IER, 0x02);
  write_csr_sie(MIE_SEIE);
  set_csr_sstatus(MSTATUS_SIE);

  asm volatile(
      ".globl s_uart_wfi_pc_marker\n"
      "s_uart_wfi_pc_marker:\n"
      "  wfi\n"
      : : : "memory");

  check_or_halt(uart_irq_seen == 1, 2);
  check_or_halt(uart_irq_claim == 1, 3);
  check_or_halt(uart_irq_iir == 0x02, 4);
  check_or_halt(uart_irq_scause == (MCAUSE_INTERRUPT | IRQ_CAUSE_SEI), 5);
  check_or_halt(uart_irq_sepc == (uintptr_t)s_uart_wfi_pc_marker, 6);
  check_or_halt((uart_irq_sstatus & MSTATUS_SPP) == MSTATUS_SPP, 7);

  halt(0);
  __builtin_unreachable();
}

int main() {
  uart_irq_seen = 0;
  uart_irq_scause = 0;
  uart_irq_sepc = 0;
  uart_irq_sstatus = 0;
  uart_irq_claim = 0;
  uart_irq_iir = 0;

  write_csr_stvec((uintptr_t)s_uart_plic_trap);
  write_csr_mideleg(1ul << IRQ_CAUSE_MEI);
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
