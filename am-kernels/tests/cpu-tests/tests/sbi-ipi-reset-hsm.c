#include "trap.h"

#if defined(__ISA_RISCV64__)

#define MSTATUS_MPP_MASK  (3ul << 11)
#define MSTATUS_MPP_S     (1ul << 11)
#define MSTATUS_SIE       (1ul << 1)
#define MSTATUS_SPP       (1ul << 8)
#define SIE_SSIE          (1ul << 1)
#define SIP_SSIP          (1ul << 1)
#define IRQ_CAUSE_SSI     1
#define EXC_ECALL_SMODE   9
#define MCAUSE_INTERRUPT  (1ul << 63)

#define SBI_SUCCESS       0ul
#define SBI_ERR_NOTSUPP   (-2l)
#define SBI_EXT_IPI       0x735049ul
#define SBI_EXT_HSM       0x48534dul
#define SBI_EXT_SRST      0x53525354ul
#define SBI_FID_SEND_IPI  0ul
#define SBI_FID_HART_STATUS 2ul
#define SBI_FID_SYSTEM_RESET 0ul
#define SBI_HSM_STARTED   0ul
#define SBI_SRST_SHUTDOWN 0ul
#define SBI_SRST_NO_REASON 0ul

typedef struct {
  uintptr_t error;
  uintptr_t value;
} SbiRet;

volatile uintptr_t sbi_ipi_m_seen;
volatile uintptr_t sbi_ipi_s_seen;
volatile uintptr_t sbi_ipi_reset_seen;
volatile uintptr_t sbi_ipi_last_mcause;
volatile uintptr_t sbi_ipi_last_eid;
volatile uintptr_t sbi_ipi_last_fid;
volatile uintptr_t sbi_ipi_last_arg0;
volatile uintptr_t sbi_ipi_last_arg1;
volatile uintptr_t sbi_ipi_last_arg2;
volatile uintptr_t sbi_ipi_scause;
volatile uintptr_t sbi_ipi_sepc;
volatile uintptr_t sbi_ipi_sstatus;

extern void m_sbi_ipi_trap(void);
extern void s_sbi_ipi_trap(void);
extern char s_sbi_ipi_wfi_marker[];
static void s_sbi_ipi_payload(void) __attribute__((noinline, noreturn));

asm(
".align 2\n"
".globl m_sbi_ipi_trap\n"
"m_sbi_ipi_trap:\n"
"  csrr t0, mcause\n"
"  la t1, sbi_ipi_last_mcause\n"
"  sd t0, 0(t1)\n"
"  la t1, sbi_ipi_last_eid\n"
"  sd a7, 0(t1)\n"
"  la t1, sbi_ipi_last_fid\n"
"  sd a6, 0(t1)\n"
"  la t1, sbi_ipi_last_arg0\n"
"  sd a0, 0(t1)\n"
"  la t1, sbi_ipi_last_arg1\n"
"  sd a1, 0(t1)\n"
"  la t1, sbi_ipi_last_arg2\n"
"  sd a2, 0(t1)\n"
"  li t0, 0x735049\n"
"  beq a7, t0, 10f\n"
"  li t0, 0x48534d\n"
"  beq a7, t0, 20f\n"
"  li t0, 0x53525354\n"
"  beq a7, t0, 30f\n"
"  j 90f\n"
"10:\n"
"  bnez a6, 90f\n"
"  li t0, 1\n"
"  bne a0, t0, 90f\n"
"  bnez a1, 90f\n"
"  csrs sip, 2\n"
"  la t1, sbi_ipi_m_seen\n"
"  li t0, 1\n"
"  sd t0, 0(t1)\n"
"  li a0, 0\n"
"  li a1, 0\n"
"  j 99f\n"
"20:\n"
"  li t0, 2\n"
"  bne a6, t0, 90f\n"
"  bnez a0, 90f\n"
"  li a0, 0\n"
"  li a1, 0\n"
"  j 99f\n"
"30:\n"
"  bnez a6, 90f\n"
"  bnez a0, 90f\n"
"  bnez a1, 90f\n"
"  la t1, sbi_ipi_reset_seen\n"
"  li t0, 1\n"
"  sd t0, 0(t1)\n"
"  li a0, 0\n"
"  li a1, 0\n"
"  j 99f\n"
"90:\n"
"  li a0, -2\n"
"  li a1, 0\n"
"99:\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
".align 2\n"
".globl s_sbi_ipi_trap\n"
"s_sbi_ipi_trap:\n"
"  csrr t0, scause\n"
"  la t1, sbi_ipi_scause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, sepc\n"
"  la t1, sbi_ipi_sepc\n"
"  sd t0, 0(t1)\n"
"  csrr t0, sstatus\n"
"  la t1, sbi_ipi_sstatus\n"
"  sd t0, 0(t1)\n"
"  csrc sip, 2\n"
"  la t1, sbi_ipi_s_seen\n"
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

static inline void clear_csr_sstatus(uintptr_t value) {
  asm volatile("csrc sstatus, %0" : : "r"(value) : "memory");
}

static inline SbiRet sbi_call3(uintptr_t eid, uintptr_t fid,
                               uintptr_t arg0, uintptr_t arg1,
                               uintptr_t arg2) {
  register uintptr_t a0 asm("a0") = arg0;
  register uintptr_t a1 asm("a1") = arg1;
  register uintptr_t a2 asm("a2") = arg2;
  register uintptr_t a6 asm("a6") = fid;
  register uintptr_t a7 asm("a7") = eid;
  asm volatile("ecall"
               : "+r"(a0), "+r"(a1), "+r"(a2)
               : "r"(a6), "r"(a7)
               : "memory", "t0", "t1", "t2", "t3", "t4", "t5", "t6");
  SbiRet ret = {a0, a1};
  return ret;
}

static inline void mret_to_s_payload(void) {
  uintptr_t status = read_csr_mstatus();
  status = (status & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  write_csr_mstatus(status);
  write_csr_mepc((uintptr_t)s_sbi_ipi_payload);
  asm volatile("mret" : : : "memory");
}

static void check_or_halt(bool cond, int code) {
  if (!cond) halt(code);
}

static void s_sbi_ipi_payload(void) {
  write_csr_stvec((uintptr_t)s_sbi_ipi_trap);
  write_csr_sie(SIE_SSIE);

  SbiRet ret = sbi_call3(SBI_EXT_IPI, SBI_FID_SEND_IPI, 1, 0, 0);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == 0, 2);
  check_or_halt(sbi_ipi_m_seen == 1, 3);
  check_or_halt(sbi_ipi_last_mcause == EXC_ECALL_SMODE, 4);
  check_or_halt(sbi_ipi_last_eid == SBI_EXT_IPI, 5);
  check_or_halt(sbi_ipi_last_fid == SBI_FID_SEND_IPI, 6);
  check_or_halt(sbi_ipi_last_arg0 == 1, 7);
  check_or_halt(sbi_ipi_last_arg1 == 0, 8);

  set_csr_sstatus(MSTATUS_SIE);
  asm volatile(
      ".globl s_sbi_ipi_wfi_marker\n"
      "s_sbi_ipi_wfi_marker:\n"
      "  wfi\n"
      : : : "memory");
  clear_csr_sstatus(MSTATUS_SIE);

  check_or_halt(sbi_ipi_s_seen == 1, 9);
  check_or_halt(sbi_ipi_scause == (MCAUSE_INTERRUPT | IRQ_CAUSE_SSI), 10);
  check_or_halt(sbi_ipi_sepc == (uintptr_t)s_sbi_ipi_wfi_marker, 11);
  check_or_halt((sbi_ipi_sstatus & MSTATUS_SPP) == MSTATUS_SPP, 12);

  ret = sbi_call3(SBI_EXT_HSM, SBI_FID_HART_STATUS, 0, 0, 0);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == SBI_HSM_STARTED, 13);
  check_or_halt(sbi_ipi_last_eid == SBI_EXT_HSM, 14);
  check_or_halt(sbi_ipi_last_fid == SBI_FID_HART_STATUS, 15);

  ret = sbi_call3(SBI_EXT_SRST, SBI_FID_SYSTEM_RESET,
                  SBI_SRST_SHUTDOWN, SBI_SRST_NO_REASON, 0);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == 0, 16);
  check_or_halt(sbi_ipi_reset_seen == 1, 17);
  check_or_halt(sbi_ipi_last_eid == SBI_EXT_SRST, 18);
  check_or_halt(sbi_ipi_last_fid == SBI_FID_SYSTEM_RESET, 19);
  check_or_halt(sbi_ipi_last_arg0 == SBI_SRST_SHUTDOWN, 20);
  check_or_halt(sbi_ipi_last_arg1 == SBI_SRST_NO_REASON, 21);

  halt(0);
  __builtin_unreachable();
}

int main() {
  sbi_ipi_m_seen = 0;
  sbi_ipi_s_seen = 0;
  sbi_ipi_reset_seen = 0;
  sbi_ipi_last_mcause = 0;
  sbi_ipi_last_eid = 0;
  sbi_ipi_last_fid = 0;
  sbi_ipi_last_arg0 = 0;
  sbi_ipi_last_arg1 = 0;
  sbi_ipi_last_arg2 = 0;
  sbi_ipi_scause = 0;
  sbi_ipi_sepc = 0;
  sbi_ipi_sstatus = 0;

  write_csr_mtvec((uintptr_t)m_sbi_ipi_trap);
  write_csr_mideleg(1ul << IRQ_CAUSE_SSI);
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
