#include "trap.h"

#if defined(__ISA_RISCV64__)

#define UART_BASE          0x10000000ul
#define MSTATUS_MPP_MASK   (3ul << 11)
#define MSTATUS_MPP_S      (1ul << 11)
#define EXC_ECALL_SMODE    9
#define SBI_SUCCESS        0ul
#define SBI_ERR_NOTSUPP    (-2l)
#define SBI_EXT_LEGACY_CONSOLE_PUTCHAR 0x1ul
#define SBI_EXT_BASE       0x10ul
#define SBI_EXT_TIME       0x54494d45ul
#define SBI_FID_GET_SPEC_VERSION 0
#define SBI_FID_GET_IMPL_ID      1
#define SBI_FID_GET_IMPL_VERSION 2
#define SBI_FID_PROBE_EXTENSION  3
#define SBI_FID_GET_MVENDORID    4
#define SBI_FID_GET_MARCHID      5
#define SBI_SPEC_VERSION_0_2     2ul
#define SBI_IMPL_ID_YSYX         0x79737978ul
#define SBI_IMPL_VERSION         1ul
#define EXPECTED_MVENDORID       0x79737978ul
#define EXPECTED_MARCHID         26010035ul

typedef struct {
  uintptr_t error;
  uintptr_t value;
} SbiRet;

volatile uintptr_t sbi_base_call_count;
volatile uintptr_t sbi_base_console_count;
volatile uintptr_t sbi_base_last_mcause;
volatile uintptr_t sbi_base_last_mepc;
volatile uintptr_t sbi_base_last_eid;
volatile uintptr_t sbi_base_last_fid;
volatile uintptr_t sbi_base_console_chars[4];

extern void m_sbi_base_console_trap(void);
static void s_sbi_base_console_payload(void) __attribute__((noinline, noreturn));

asm(
".align 2\n"
".globl m_sbi_base_console_trap\n"
"m_sbi_base_console_trap:\n"
"  csrr t0, mcause\n"
"  la t1, sbi_base_last_mcause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  la t1, sbi_base_last_mepc\n"
"  sd t0, 0(t1)\n"
"  la t1, sbi_base_last_eid\n"
"  sd a7, 0(t1)\n"
"  la t1, sbi_base_last_fid\n"
"  sd a6, 0(t1)\n"
"  la t1, sbi_base_call_count\n"
"  ld t0, 0(t1)\n"
"  addi t0, t0, 1\n"
"  sd t0, 0(t1)\n"
"  li t0, 0x10\n"
"  beq a7, t0, 1f\n"
"  li t0, 0x1\n"
"  beq a7, t0, 20f\n"
"  j 90f\n"
"1:\n"
"  beqz a6, 10f\n"
"  li t0, 1\n"
"  beq a6, t0, 11f\n"
"  li t0, 2\n"
"  beq a6, t0, 12f\n"
"  li t0, 3\n"
"  beq a6, t0, 13f\n"
"  li t0, 4\n"
"  beq a6, t0, 14f\n"
"  li t0, 5\n"
"  beq a6, t0, 15f\n"
"  j 90f\n"
"10:\n"
"  li a0, 0\n"
"  li a1, 2\n"
"  j 99f\n"
"11:\n"
"  li a0, 0\n"
"  li a1, 0x79737978\n"
"  j 99f\n"
"12:\n"
"  li a0, 0\n"
"  li a1, 1\n"
"  j 99f\n"
"13:\n"
"  li t0, 0x1\n"
"  beq a0, t0, 16f\n"
"  li t0, 0x54494d45\n"
"  beq a0, t0, 16f\n"
"  li a0, 0\n"
"  li a1, 0\n"
"  j 99f\n"
"16:\n"
"  li a0, 0\n"
"  li a1, 1\n"
"  j 99f\n"
"14:\n"
"  csrr t0, mvendorid\n"
"  li a0, 0\n"
"  mv a1, t0\n"
"  j 99f\n"
"15:\n"
"  csrr t0, marchid\n"
"  li a0, 0\n"
"  mv a1, t0\n"
"  j 99f\n"
"20:\n"
"  la t1, sbi_base_console_count\n"
"  ld t0, 0(t1)\n"
"  la t2, sbi_base_console_chars\n"
"  slli t3, t0, 3\n"
"  add t2, t2, t3\n"
"  sd a0, 0(t2)\n"
"  addi t0, t0, 1\n"
"  sd t0, 0(t1)\n"
"  li t2, 0x10000000\n"
"  sb a0, 0(t2)\n"
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

static inline void mret_to_s_payload(void) {
  uintptr_t status = read_csr_mstatus();
  status = (status & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  write_csr_mstatus(status);
  write_csr_mepc((uintptr_t)s_sbi_base_console_payload);
  asm volatile("mret" : : : "memory");
}

static inline SbiRet sbi_call(uintptr_t eid, uintptr_t fid, uintptr_t arg0) {
  register uintptr_t a0 asm("a0") = arg0;
  register uintptr_t a1 asm("a1") = 0;
  register uintptr_t a6 asm("a6") = fid;
  register uintptr_t a7 asm("a7") = eid;
  asm volatile("ecall"
               : "+r"(a0), "+r"(a1)
               : "r"(a6), "r"(a7)
               : "memory", "t0", "t1", "t2", "t3");
  SbiRet ret = {a0, a1};
  return ret;
}

static inline void sbi_console_putchar(char ch) {
  (void)sbi_call(SBI_EXT_LEGACY_CONSOLE_PUTCHAR, 0, (uintptr_t)(uint8_t)ch);
}

static void check_or_halt(bool cond, int code) {
  if (!cond) halt(code);
}

static void s_sbi_base_console_payload(void) {
  SbiRet ret = sbi_call(SBI_EXT_BASE, SBI_FID_GET_SPEC_VERSION, 0);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == SBI_SPEC_VERSION_0_2, 2);

  ret = sbi_call(SBI_EXT_BASE, SBI_FID_GET_IMPL_ID, 0);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == SBI_IMPL_ID_YSYX, 3);

  ret = sbi_call(SBI_EXT_BASE, SBI_FID_GET_IMPL_VERSION, 0);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == SBI_IMPL_VERSION, 4);

  ret = sbi_call(SBI_EXT_BASE, SBI_FID_PROBE_EXTENSION, SBI_EXT_LEGACY_CONSOLE_PUTCHAR);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == 1, 5);

  ret = sbi_call(SBI_EXT_BASE, SBI_FID_PROBE_EXTENSION, SBI_EXT_TIME);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == 1, 6);

  ret = sbi_call(SBI_EXT_BASE, SBI_FID_PROBE_EXTENSION, 0xdeadbeeful);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == 0, 7);

  ret = sbi_call(SBI_EXT_BASE, SBI_FID_GET_MVENDORID, 0);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == EXPECTED_MVENDORID, 8);

  ret = sbi_call(SBI_EXT_BASE, SBI_FID_GET_MARCHID, 0);
  check_or_halt(ret.error == SBI_SUCCESS && ret.value == EXPECTED_MARCHID, 9);

  ret = sbi_call(0x12345678ul, 0, 0);
  check_or_halt((long)ret.error == SBI_ERR_NOTSUPP, 10);

  sbi_console_putchar('O');
  sbi_console_putchar('K');
  sbi_console_putchar('\n');

  check_or_halt(sbi_base_last_mcause == EXC_ECALL_SMODE, 11);
  check_or_halt(sbi_base_console_count == 3, 12);
  check_or_halt(sbi_base_console_chars[0] == 'O', 13);
  check_or_halt(sbi_base_console_chars[1] == 'K', 14);
  check_or_halt(sbi_base_console_chars[2] == '\n', 15);
  check_or_halt(sbi_base_call_count == 12, 16);
  check_or_halt(sbi_base_last_eid == SBI_EXT_LEGACY_CONSOLE_PUTCHAR, 17);

  halt(0);
  __builtin_unreachable();
}

int main() {
  sbi_base_call_count = 0;
  sbi_base_console_count = 0;
  sbi_base_last_mcause = 0;
  sbi_base_last_mepc = 0;
  sbi_base_last_eid = 0;
  sbi_base_last_fid = 0;
  for (int i = 0; i < 4; i++) {
    sbi_base_console_chars[i] = 0;
  }

  write_csr_mtvec((uintptr_t)m_sbi_base_console_trap);
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
