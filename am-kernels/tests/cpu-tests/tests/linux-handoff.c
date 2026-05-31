#include "trap.h"

#if defined(__ISA_RISCV64__)

#define MSTATUS_MPP_MASK   (3ul << 11)
#define MSTATUS_MPP_S      (1ul << 11)
#define EXC_ECALL_SMODE    9
#define BOOT_HARTID        0ul
#define FDT_MAGIC          0xd00dfeedul
#define FDT_VERSION        17ul
#define SBI_TEST_DONE_EID  0x4c48444ful

static const uint8_t fake_dtb[] __attribute__((aligned(8))) = {
  0xd0, 0x0d, 0xfe, 0xed,  /* magic */
  0x00, 0x00, 0x00, 0x28,  /* totalsize */
  0x00, 0x00, 0x00, 0x28,  /* off_dt_struct */
  0x00, 0x00, 0x00, 0x28,  /* off_dt_strings */
  0x00, 0x00, 0x00, 0x28,  /* off_mem_rsvmap */
  0x00, 0x00, 0x00, 0x11,  /* version */
  0x00, 0x00, 0x00, 0x10,  /* last_comp_version */
  0x00, 0x00, 0x00, 0x00,  /* boot_cpuid_phys */
  0x00, 0x00, 0x00, 0x00,  /* size_dt_strings */
  0x00, 0x00, 0x00, 0x00,  /* size_dt_struct */
};

volatile uintptr_t handoff_last_mcause;
volatile uintptr_t handoff_last_mepc;
volatile uintptr_t handoff_last_a0;
volatile uintptr_t handoff_last_a1;
volatile uintptr_t handoff_last_a7;
volatile uintptr_t handoff_trap_count;

extern void m_linux_handoff_trap(void);
static void s_linux_payload(uintptr_t hartid, uintptr_t dtb_addr)
  __attribute__((noinline, noreturn));

asm(
".align 2\n"
".globl m_linux_handoff_trap\n"
"m_linux_handoff_trap:\n"
"  csrr t0, mcause\n"
"  la t1, handoff_last_mcause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  la t1, handoff_last_mepc\n"
"  sd t0, 0(t1)\n"
"  la t1, handoff_last_a0\n"
"  sd a0, 0(t1)\n"
"  la t1, handoff_last_a1\n"
"  sd a1, 0(t1)\n"
"  la t1, handoff_last_a7\n"
"  sd a7, 0(t1)\n"
"  la t1, handoff_trap_count\n"
"  ld t0, 0(t1)\n"
"  addi t0, t0, 1\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
);

static uintptr_t be32(const uint8_t *p) {
  return ((uintptr_t)p[0] << 24) | ((uintptr_t)p[1] << 16) |
         ((uintptr_t)p[2] << 8) | (uintptr_t)p[3];
}

static void check_or_halt(bool cond, int code) {
  if (!cond) halt(code);
}

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

static inline void mret_to_linux_payload(uintptr_t hartid, uintptr_t dtb_addr) {
  uintptr_t status = read_csr_mstatus();
  status = (status & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  write_csr_mstatus(status);
  write_csr_mepc((uintptr_t)s_linux_payload);

  register uintptr_t a0 asm("a0") = hartid;
  register uintptr_t a1 asm("a1") = dtb_addr;
  asm volatile("mret" : : "r"(a0), "r"(a1) : "memory");
}

static inline void sbi_test_done(uintptr_t hartid, uintptr_t dtb_addr) {
  register uintptr_t a0 asm("a0") = hartid;
  register uintptr_t a1 asm("a1") = dtb_addr;
  register uintptr_t a7 asm("a7") = SBI_TEST_DONE_EID;
  asm volatile("ecall"
               : "+r"(a0), "+r"(a1)
               : "r"(a7)
               : "memory", "t0", "t1");
}

static void s_linux_payload(uintptr_t hartid, uintptr_t dtb_addr) {
  const uint8_t *dtb = (const uint8_t *)dtb_addr;

  check_or_halt(hartid == BOOT_HARTID, 2);
  check_or_halt(dtb_addr == (uintptr_t)fake_dtb, 3);
  check_or_halt(be32(dtb + 0) == FDT_MAGIC, 4);
  check_or_halt(be32(dtb + 4) == sizeof(fake_dtb), 5);
  check_or_halt(be32(dtb + 20) == FDT_VERSION, 6);
  check_or_halt(be32(dtb + 28) == BOOT_HARTID, 7);

  sbi_test_done(hartid, dtb_addr);

  check_or_halt(handoff_trap_count == 1, 8);
  check_or_halt(handoff_last_mcause == EXC_ECALL_SMODE, 9);
  check_or_halt(handoff_last_a0 == BOOT_HARTID, 10);
  check_or_halt(handoff_last_a1 == (uintptr_t)fake_dtb, 11);
  check_or_halt(handoff_last_a7 == SBI_TEST_DONE_EID, 12);

  halt(0);
  __builtin_unreachable();
}

int main() {
  handoff_last_mcause = 0;
  handoff_last_mepc = 0;
  handoff_last_a0 = 0;
  handoff_last_a1 = 0;
  handoff_last_a7 = 0;
  handoff_trap_count = 0;

  write_csr_mtvec((uintptr_t)m_linux_handoff_trap);
  mret_to_linux_payload(BOOT_HARTID, (uintptr_t)fake_dtb);
  halt(1);
  return 1;
}

#else

int main() {
  halt(0);
  return 0;
}

#endif
