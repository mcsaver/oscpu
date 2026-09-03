#include "trap.h"

#if defined(__ISA_RISCV64__)

#define MSTATUS_MPP_MASK (3ul << 11)
#define MSTATUS_MPP_S    (1ul << 11)
#define CSR_MCOUNTEREN   0x306
#define CSR_SCOUNTEREN   0x106
#define COUNTEREN_CY     0x1ul
#define COUNTEREN_TM     0x2ul
#define COUNTEREN_IR     0x4ul
#define COUNTEREN_ALL    (COUNTEREN_CY | COUNTEREN_TM | COUNTEREN_IR)
#define EXC_ILLEGAL_INST 2

volatile uintptr_t counter_trap_seen;
volatile uintptr_t counter_trap_mcause;
volatile uintptr_t counter_trap_mepc;

extern void m_counter_trap(void);
extern char s_rdtime_without_counteren[];
static void s_counter_payload(void) __attribute__((noinline, noreturn));

asm(
".align 2\n"
".globl m_counter_trap\n"
"m_counter_trap:\n"
"  csrr t0, mcause\n"
"  la t1, counter_trap_mcause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  la t1, counter_trap_mepc\n"
"  sd t0, 0(t1)\n"
"  li t0, 7\n"
"  csrw mcounteren, t0\n"
"  la t1, counter_trap_seen\n"
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

static inline void write_csr_mcounteren(uintptr_t value) {
  asm volatile("csrw 0x306, %0" : : "r"(value) : "memory");
}

static inline void write_csr_scounteren(uintptr_t value) {
  asm volatile("csrw 0x106, %0" : : "r"(value) : "memory");
}

static inline uintptr_t read_csr_scounteren(void) {
  uintptr_t value;
  asm volatile("csrr %0, 0x106" : "=r"(value));
  return value;
}

static inline uintptr_t read_time_csr(void) {
  uintptr_t value;
  asm volatile("csrr %0, time" : "=r"(value));
  return value;
}

static inline uintptr_t read_cycle_csr(void) {
  uintptr_t value;
  asm volatile("csrr %0, cycle" : "=r"(value));
  return value;
}

static inline uintptr_t read_instret_csr(void) {
  uintptr_t value;
  asm volatile("csrr %0, instret" : "=r"(value));
  return value;
}

static inline void mret_to_s_payload(void) {
  uintptr_t status = read_csr_mstatus();
  status = (status & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  write_csr_mstatus(status);
  write_csr_mepc((uintptr_t)s_counter_payload);
  asm volatile("mret" : : : "memory");
}

static void check_or_halt(bool cond, int code) {
  if (!cond) halt(code);
}

static void s_counter_payload(void) {
  uintptr_t ignored_time;
  asm volatile(
      ".globl s_rdtime_without_counteren\n"
      "s_rdtime_without_counteren:\n"
      "  csrr %0, time\n"
      : "=r"(ignored_time) : : "memory");
  (void)ignored_time;

  check_or_halt(counter_trap_seen == 1, 2);
  check_or_halt(counter_trap_mcause == EXC_ILLEGAL_INST, 3);
  check_or_halt(counter_trap_mepc == (uintptr_t)s_rdtime_without_counteren, 4);

  write_csr_scounteren(COUNTEREN_ALL);
  check_or_halt((read_csr_scounteren() & COUNTEREN_ALL) == COUNTEREN_ALL, 5);

  uintptr_t time0 = read_time_csr();
  uintptr_t cycle0 = read_cycle_csr();
  uintptr_t instret0 = read_instret_csr();
  uintptr_t mix = 0;
  uintptr_t time1 = time0;
  /*
   * instruction-time 会逐指令增长，host-time 则按宿主微秒采样；不要假定固定
   * 16 条指令必然跨过一个宿主 tick，只要求在有界轮询内观察到同源 TIME 前进。
   */
  for (int i = 0; i < 100000 && time1 == time0; i++) {
    mix += (uintptr_t)i + time0;
    time1 = read_time_csr();
  }
  uintptr_t cycle1 = read_cycle_csr();
  uintptr_t instret1 = read_instret_csr();

  check_or_halt(time0 != 0, 6);
  check_or_halt(time1 > time0, 7);
  check_or_halt(cycle1 > cycle0, 8);
  check_or_halt(instret1 > instret0, 9);
  check_or_halt(mix != 0, 10);

  halt(0);
  __builtin_unreachable();
}

int main() {
  counter_trap_seen = 0;
  counter_trap_mcause = 0;
  counter_trap_mepc = 0;

  write_csr_mtvec((uintptr_t)m_counter_trap);
  write_csr_mcounteren(0);
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
