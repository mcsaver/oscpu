#include "trap.h"

#if defined(__ISA_RISCV32__)

#define MSTATUS_MPP_MASK (3u << 11)
#define MSTATUS_MPP_S    (1u << 11)
#define SATP_MODE_SV32   (1u << 31)

#define PAGE_BYTES       4096u
#define MEGAPAGE_BYTES   (4u * 1024u * 1024u)
#define PHYSICAL_BASE    0x80000000u
#define ALIAS_BASE       0x40000000u

#define PTE_VALID        (1u << 0)
#define PTE_READ         (1u << 1)
#define PTE_WRITE        (1u << 2)
#define PTE_EXECUTE      (1u << 3)
#define PTE_ACCESSED     (1u << 6)
#define PTE_DIRTY        (1u << 7)

#define PMP_NAPOT        (3u << 3)
#define PMP_RWX          0x07u

static volatile uintptr_t sv32_root[1024]
    __attribute__((aligned(PAGE_BYTES)));
static volatile uint8_t denied_page[PAGE_BYTES]
    __attribute__((aligned(PAGE_BYTES)));
static volatile uint32_t shared_value = 0x12345678u;

volatile uintptr_t sv32_satp;
volatile uintptr_t sv32_alias_address;
volatile uintptr_t sv32_fault_cause;
volatile uintptr_t sv32_fault_tval;
volatile uintptr_t sv32_fault_seen;

extern void sv32_machine_trap(void);
extern void sv32_supervisor_entry(void);

asm(
".align 2\n"
".globl sv32_machine_trap\n"
"sv32_machine_trap:\n"
"  csrr t0, mcause\n"
"  li t1, 5\n"                       /* 加载访问异常 */
"  beq t0, t1, sv32_expected_pmp_fault\n"
"  li t1, 3\n"                       /* 断点异常携带测试结果 */
"  beq t0, t1, sv32_finish\n"
"  mv a0, t0\n"
"  j sv32_finish\n"
"sv32_expected_pmp_fault:\n"
"  la t1, sv32_fault_cause\n"
"  sw t0, 0(t1)\n"
"  csrr t2, mtval\n"
"  la t1, sv32_fault_tval\n"
"  sw t2, 0(t1)\n"
"  li t2, 1\n"
"  la t1, sv32_fault_seen\n"
"  sw t2, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
"sv32_finish:\n"
/* 退出由 AM halt 选择当前平台的标准测试终结器。 */
"  call halt\n"
"sv32_finish_spin:\n"
"  j sv32_finish_spin\n"

".align 2\n"
".globl sv32_supervisor_entry\n"
"sv32_supervisor_entry:\n"
"  la t0, sv32_satp\n"
"  lw t1, 0(t0)\n"
"  csrw satp, t1\n"
"  sfence.vma\n"

/* 恒等映射与别名大页必须指向同一个物理字。 */
"  la t0, shared_value\n"
"  lw t1, 0(t0)\n"
"  la t2, sv32_alias_address\n"
"  lw t2, 0(t2)\n"
"  lw t3, 0(t2)\n"
"  bne t1, t3, sv32_fail_1\n"
"  addi t3, t3, 1\n"
"  sw t3, 0(t2)\n"
"  lw t4, 0(t0)\n"
"  bne t3, t4, sv32_fail_2\n"

/* 取指/访存置位 A；经别名页写入还必须置位 D。 */
"  la t0, sv32_root\n"
"  li t1, 2048\n"                   /* 根页表项 VPN1(0x80000000) */
"  add t1, t0, t1\n"
"  lw t2, 0(t1)\n"
"  andi t2, t2, 0xc0\n"
"  li t3, 0x40\n"
"  bne t2, t3, sv32_fail_3\n"
"  li t1, 1024\n"                   /* 根页表项 VPN1(0x40000000) */
"  add t1, t0, t1\n"
"  lw t2, 0(t1)\n"
"  andi t2, t2, 0xc0\n"
"  li t3, 0xc0\n"
"  bne t2, t3, sv32_fail_4\n"

/* PMP 表项 0 优先拒绝此页，表项 1 的全地址兜底权限不得覆盖它。 */
"  la t0, denied_page\n"
"  lw t1, 0(t0)\n"                  /* 预期产生精确的加载访问异常 */
"  la t0, sv32_fault_seen\n"
"  lw t1, 0(t0)\n"
"  li t2, 1\n"
"  bne t1, t2, sv32_fail_5\n"
"  la t0, sv32_fault_cause\n"
"  lw t1, 0(t0)\n"
"  li t2, 5\n"
"  bne t1, t2, sv32_fail_6\n"
"  la t0, sv32_fault_tval\n"
"  lw t1, 0(t0)\n"
"  la t2, denied_page\n"
"  bne t1, t2, sv32_fail_7\n"
"  li a0, 0\n"
"  ebreak\n"
"sv32_fail_1: li a0, 1; ebreak\n"
"sv32_fail_2: li a0, 2; ebreak\n"
"sv32_fail_3: li a0, 3; ebreak\n"
"sv32_fail_4: li a0, 4; ebreak\n"
"sv32_fail_5: li a0, 5; ebreak\n"
"sv32_fail_6: li a0, 6; ebreak\n"
"sv32_fail_7: li a0, 7; ebreak\n"
);

static inline uintptr_t read_mstatus(void) {
  uintptr_t value;
  asm volatile("csrr %0, mstatus" : "=r"(value));
  return value;
}

static inline uintptr_t read_pmpcfg0(void) {
  uintptr_t value;
  asm volatile("csrr %0, pmpcfg0" : "=r"(value));
  return value;
}

static inline uintptr_t read_pmpaddr0(void) {
  uintptr_t value;
  asm volatile("csrr %0, pmpaddr0" : "=r"(value));
  return value;
}

static inline uintptr_t read_pmpaddr1(void) {
  uintptr_t value;
  asm volatile("csrr %0, pmpaddr1" : "=r"(value));
  return value;
}

static inline uintptr_t napot_address(uintptr_t base, uintptr_t size) {
  return (base >> 2) | (size / 8 - 1);
}

int main(void) {
  const uintptr_t identity_vpn1 = PHYSICAL_BASE >> 22;
  const uintptr_t alias_vpn1 = ALIAS_BASE >> 22;
  const uintptr_t megapage_ppn = PHYSICAL_BASE >> 12;
  const uintptr_t leaf = (megapage_ppn << 10) |
      PTE_VALID | PTE_READ | PTE_WRITE | PTE_EXECUTE;

  for (int index = 0; index < 1024; index++) sv32_root[index] = 0;
  sv32_root[identity_vpn1] = leaf;
  sv32_root[alias_vpn1] = leaf;
  sv32_satp = SATP_MODE_SV32 | ((uintptr_t)sv32_root >> 12);
  sv32_alias_address = ALIAS_BASE |
      ((uintptr_t)&shared_value & (MEGAPAGE_BYTES - 1));
  uintptr_t deny = napot_address((uintptr_t)denied_page, PAGE_BYTES);
  asm volatile("csrw pmpaddr0, %0" : : "r"(deny) : "memory");
  asm volatile("csrw pmpaddr1, %0" : : "r"(~(uintptr_t)0) : "memory");
  uintptr_t pmpcfg0 = PMP_NAPOT | ((PMP_NAPOT | PMP_RWX) << 8);
  asm volatile("csrw pmpcfg0, %0" : : "r"(pmpcfg0) : "memory");

  check(read_pmpaddr0() == deny);
  check(read_pmpaddr1() == ~(uintptr_t)0);
  check((read_pmpcfg0() & 0xffffu) == pmpcfg0);

  asm volatile("csrw mtvec, %0" : : "r"(sv32_machine_trap) : "memory");
  asm volatile("csrw medeleg, zero" ::: "memory");
  asm volatile("csrw mepc, %0" : : "r"(sv32_supervisor_entry) : "memory");
  uintptr_t status = read_mstatus();
  status = (status & ~MSTATUS_MPP_MASK) | MSTATUS_MPP_S;
  asm volatile("csrw mstatus, %0" : : "r"(status) : "memory");
  asm volatile("mret" ::: "memory");
  halt(1);
  return 1;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif
