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
// 为什么这么改：NPC 核未实现 Svadu(硬件自动置 A/D)，而是按 RISC-V 规范的另一种
// 合法实现——A=0 或(写且 D=0)时产生 page fault，由软件在 handler 里置位后重试。
// 原 handler 直接 ebreak 上报 mcause，使本测试只能在 HW 自动置 A/D 的实现(如 NEMU)
// 上通过；在 NPC 上首个 ld 即 page fault 而失败。这里改为标准的软件管理 A/D：
// page fault(cause 12/13/15) 时给唯一的叶子 PTE(ad_root[2]/[510]) 置 A|D 再 mret 重试，
// 从而真正验证核的 SW-managed A/D 路径。NEMU 上 HW 已置 A/D、handler 不会触发，
// 因此该测试在两类实现上都能通过；非 page fault 仍按原样上报 mcause。
"  csrr t4, mcause\n"
"  andi t4, t4, 0xff\n"
"  li t5, 12\n"
"  blt t4, t5, sv39_ad_unexpected\n"
"  li t5, 15\n"
"  blt t5, t4, sv39_ad_unexpected\n"
"  la t0, ad_root\n"
"  ld t1, 16(t0)\n"           // ad_root[2] (low/identity 1GiB 叶子)
"  ori t1, t1, 0xc0\n"        // 置 A(bit6)|D(bit7)
"  sd t1, 16(t0)\n"
"  li t2, 4080\n"             // 510*8
"  add t3, t0, t2\n"
"  ld t1, 0(t3)\n"            // ad_root[510] (high 半区 1GiB 叶子)
"  ori t1, t1, 0xc0\n"
"  sd t1, 0(t3)\n"
"  sfence.vma\n"
"  mret\n"                    // 返回 mepc(faulting inst) 重试
"sv39_ad_unexpected:\n"
"  mv a0, t4\n"
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
