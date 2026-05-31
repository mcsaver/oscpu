#include "trap.h"

#if defined(__ISA_RISCV64__)

#define MSTATUS_MPP_MASK (3ul << 11)
#define MSTATUS_MPP_S    (1ul << 11)
#define SATP_MODE_SV39   (8ul << 60)
#define LOW_BASE         0x0000000080000000ul
#define HIGH_BASE        0xffffffff80000000ul
#define HIGH_OFFSET      0xffffffff00000000ul
#define PTE_FLAGS_NO_AD  0x0fu
#define VPN2(va)         (((uintptr_t)(va) >> 30) & 0x1ffu)

static uintptr_t ad_root[512] __attribute__((aligned(4096)));
volatile uintptr_t sv39_ad_data = 0x12345678ul;
uintptr_t sv39_ad_satp;

extern void sv39_ad_fault_trap(void);
extern void sv39_ad_s_entry(void);

asm(
".align 2\n"
".globl sv39_ad_fault_trap\n"
"sv39_ad_fault_trap:\n"
"  csrr a0, mcause\n"
"  andi a0, a0, 0xff\n"
"  ebreak\n"
".align 2\n"
".globl sv39_ad_s_entry\n"
"sv39_ad_s_entry:\n"
"  la t0, sv39_ad_satp\n"
"  ld t1, 0(t0)\n"
"  csrw satp, t1\n"
"  sfence.vma\n"
"  li t1, 0xffffffff00000000\n"
"  la t0, sv39_ad_high\n"
"  add t0, t0, t1\n"
"  add sp, sp, t1\n"
"  jr t0\n"
".align 2\n"
"sv39_ad_high:\n"
"  la t0, sv39_ad_data\n"
"  ld t2, 0(t0)\n"
"  addi t2, t2, 1\n"
"  sd t2, 0(t0)\n"
"  ld t3, 0(t0)\n"
"  bne t2, t3, sv39_ad_fail\n"
"  li a0, 0\n"
"  ebreak\n"
"sv39_ad_fail:\n"
"  li a0, 3\n"
"  ebreak\n"
);

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

static void enter_s_mode(void) {
  uintptr_t status = read_csr_mstatus();
  status = (status & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  write_csr_mstatus(status);
  write_csr_mepc((uintptr_t)sv39_ad_s_entry);
  asm volatile("mret" : : : "memory");
}

int main(void) {
  for (int i = 0; i < 512; i++) {
    ad_root[i] = 0;
  }

  uintptr_t leaf = ((LOW_BASE >> 12) << 10) | PTE_FLAGS_NO_AD;
  ad_root[VPN2(LOW_BASE)] = leaf;
  ad_root[VPN2(HIGH_BASE)] = leaf;
  sv39_ad_satp = SATP_MODE_SV39 | ((uintptr_t)ad_root >> 12);

  write_csr_mtvec((uintptr_t)sv39_ad_fault_trap);
  write_csr_medeleg(0);
  asm volatile("sfence.vma" : : : "memory");
  enter_s_mode();
  halt(1);
  return 1;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif
