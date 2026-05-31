#include "trap.h"

#if defined(__ISA_RISCV64__)

#define MSTATUS_MPP_MASK   (3ul << 11)
#define MSTATUS_MPP_S      (1ul << 11)
#define SATP_MODE_SV39     (8ul << 60)
#define LOW_BASE           0x0000000080000000ul
#define PTE_FLAGS          0xcfu
#define VPN2(va)           (((uintptr_t)(va) >> 30) & 0x1ffu)
#define BOOT_HARTID        0ul
#define FDT_MAGIC          0xd00dfeedul
#define FDT_VERSION        17ul
#define EXC_ECALL_SMODE    9ul
#define SBI_TEST_DONE_EID  0x4c4d4254ul

static uintptr_t mini_root[512] __attribute__((aligned(4096)));
static uintptr_t mini_satp;
static volatile uintptr_t mini_trap_count;
static volatile uintptr_t mini_last_mcause;
static volatile uintptr_t mini_last_mepc;
static volatile uintptr_t mini_last_a0;
static volatile uintptr_t mini_last_a1;
static volatile uintptr_t mini_last_a7;
static volatile uintptr_t mini_order_word;
static volatile uint8_t mini_dst[16];

static const uint8_t fake_dtb[] __attribute__((aligned(8))) = {
  0xd0, 0x0d, 0xfe, 0xed,
  0x00, 0x00, 0x00, 0x28,
  0x00, 0x00, 0x00, 0x28,
  0x00, 0x00, 0x00, 0x28,
  0x00, 0x00, 0x00, 0x28,
  0x00, 0x00, 0x00, 0x11,
  0x00, 0x00, 0x00, 0x10,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00,
};
static const uint8_t mini_msg[] = "rv64-mini-boot";

extern void linux_mini_m_trap(void);
extern void linux_mini_s_entry(void);
void linux_mini_copy_probe(volatile uint8_t *out, const uint8_t *in,
                           uintptr_t len, uintptr_t rounds);
uintptr_t linux_mini_mem_order_probe(volatile uintptr_t *ptr, uintptr_t seed,
                                     uintptr_t rounds);

static void mini_linux_kernel(uintptr_t hartid, uintptr_t dtb_addr)
  __attribute__((noinline, noreturn, used));

asm(
".text\n"
".align 3\n"
".globl linux_mini_m_trap\n"
"linux_mini_m_trap:\n"
"  csrr t0, mcause\n"
"  la t1, mini_last_mcause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  la t1, mini_last_mepc\n"
"  sd t0, 0(t1)\n"
"  la t1, mini_last_a0\n"
"  sd a0, 0(t1)\n"
"  la t1, mini_last_a1\n"
"  sd a1, 0(t1)\n"
"  la t1, mini_last_a7\n"
"  sd a7, 0(t1)\n"
"  la t1, mini_trap_count\n"
"  ld t0, 0(t1)\n"
"  addi t0, t0, 1\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
".align 3\n"
".globl linux_mini_s_entry\n"
"linux_mini_s_entry:\n"
"  la t0, mini_satp\n"
"  ld t1, 0(t0)\n"
"  csrw satp, t1\n"
"  sfence.vma\n"
"  j mini_linux_kernel\n"
".align 3\n"
".globl linux_mini_copy_probe\n"
"linux_mini_copy_probe:\n"
"  .option push\n"
"  .option norvc\n"
"  beqz a3, 3f\n"
"2:\n"
"  mv t0, a1\n"
"  add t1, a1, a2\n"
"  mv t2, a0\n"
"1:\n"
"  lbu t3, 0(t0)\n"
"  addi t0, t0, 1\n"
"  sb t3, 0(t2)\n"
"  addi t2, t2, 1\n"
"  bne t0, t1, 1b\n"
"  addi a3, a3, -1\n"
"  bnez a3, 2b\n"
"3:\n"
"  .option pop\n"
"  ret\n"
".align 3\n"
".globl linux_mini_mem_order_probe\n"
"linux_mini_mem_order_probe:\n"
"  .option push\n"
"  .option norvc\n"
"  mv t0, a0\n"
"  mv t1, a1\n"
"  mv t2, a2\n"
"  li t5, 0\n"
"  li t6, 31\n"
"4:\n"
"  add t1, t1, t6\n"
"  sd t1, 0(t0)\n"
"  ld t3, 0(t0)\n"
"  xor t4, t3, t1\n"
"  or t5, t5, t4\n"
"  addi t2, t2, -1\n"
"  bnez t2, 4b\n"
"  mv a0, t5\n"
"  .option pop\n"
"  ret\n"
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

static inline void write_csr_medeleg(uintptr_t value) {
  asm volatile("csrw medeleg, %0" : : "r"(value) : "memory");
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

static inline void write_csr_sscratch(uintptr_t value) {
  asm volatile("csrw sscratch, %0" : : "r"(value) : "memory");
}

static inline uintptr_t read_csr_sscratch(void) {
  uintptr_t value;
  asm volatile("csrr %0, sscratch" : "=r"(value));
  return value;
}

static inline uintptr_t read_csr_satp(void) {
  uintptr_t value;
  asm volatile("csrr %0, satp" : "=r"(value));
  return value;
}

static void enter_s_mode(uintptr_t hartid, uintptr_t dtb_addr) {
  uintptr_t status = read_csr_mstatus();
  status = (status & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  write_csr_mstatus(status);
  write_csr_mepc((uintptr_t)linux_mini_s_entry);

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

static void mini_linux_kernel(uintptr_t hartid, uintptr_t dtb_addr) {
  const uint8_t *dtb = (const uint8_t *)dtb_addr;

  check_or_halt(read_csr_satp() == mini_satp, 2);
  check_or_halt(hartid == BOOT_HARTID, 3);
  check_or_halt(dtb_addr == (uintptr_t)fake_dtb, 4);
  check_or_halt(be32(dtb + 0) == FDT_MAGIC, 5);
  check_or_halt(be32(dtb + 4) == sizeof(fake_dtb), 6);
  check_or_halt(be32(dtb + 20) == FDT_VERSION, 7);

  write_csr_sscratch(0x13579bdf2468ace0ul);
  check_or_halt(read_csr_sscratch() == 0x13579bdf2468ace0ul, 8);

  linux_mini_copy_probe(mini_dst, mini_msg, sizeof(mini_msg), 64);
  for (uintptr_t i = 0; i < sizeof(mini_msg); i++) {
    check_or_halt(mini_dst[i] == mini_msg[i], 9);
  }

  check_or_halt(linux_mini_mem_order_probe(&mini_order_word,
                                           0x1020304050607080ul, 512) == 0,
                10);
  check_or_halt(mini_order_word == 0x1020304050607080ul + 31ul * 512ul, 11);

  sbi_test_done(hartid, dtb_addr);

  check_or_halt(mini_trap_count == 1, 12);
  check_or_halt(mini_last_mcause == EXC_ECALL_SMODE, 13);
  check_or_halt(mini_last_a0 == BOOT_HARTID, 14);
  check_or_halt(mini_last_a1 == (uintptr_t)fake_dtb, 15);
  check_or_halt(mini_last_a7 == SBI_TEST_DONE_EID, 16);

  halt(0);
  __builtin_unreachable();
}

int main(void) {
  for (int i = 0; i < 512; i++) {
    mini_root[i] = 0;
  }
  for (int i = 0; i < 16; i++) {
    mini_dst[i] = 0xa5u;
  }

  mini_trap_count = 0;
  mini_last_mcause = 0;
  mini_last_mepc = 0;
  mini_last_a0 = 0;
  mini_last_a1 = 0;
  mini_last_a7 = 0;
  mini_order_word = 0;

  mini_root[VPN2(LOW_BASE)] = ((LOW_BASE >> 12) << 10) | PTE_FLAGS;
  mini_satp = SATP_MODE_SV39 | ((uintptr_t)mini_root >> 12);

  write_csr_mtvec((uintptr_t)linux_mini_m_trap);
  write_csr_medeleg(0);
  asm volatile("sfence.vma" : : : "memory");
  enter_s_mode(BOOT_HARTID, (uintptr_t)fake_dtb);
  halt(1);
  return 1;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif
