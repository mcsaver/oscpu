// NEMU RV64 PMP/Sv39 smoke：页表 A/D 位自动写回被 PMP 拒绝时必须产生 access fault。
#ifndef PMP_PAGEWALK_AD_STACK
#define PMP_PAGEWALK_AD_STACK 0x87ee9000
#endif

#ifndef SYSCON_RESET_MMIO
#define SYSCON_RESET_MMIO 0x100000
#endif

#ifndef SYSCON_POWEROFF_VALUE
#define SYSCON_POWEROFF_VALUE 0x5555
#endif

#define TEST_VA 0x0000000040000000
#define IDENTITY_BASE 0x80000000
#define PMP_ALLOW_SIZE 0x40000000
#define PMP_RO_SIZE 0x1000
#define PMP_NAPOT_ADDR(base, size) (((base) >> 2) | (((size) - 1) >> 3))
#define PMP_CFG_NAPOT 0x18
#define PMP_CFG_R_NAPOT 0x19
#define PMP_CFG_RWX_NAPOT 0x1f
#define PTE_V 0x001
#define PTE_VR 0x003
#define PTE_VRWXAD 0x0cf
#define CAUSE_LOAD_ACCESS 5

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2

_start:
  li sp, PMP_PAGEWALK_AD_STACK
  la t0, trap_handler
  csrw mtvec, t0
  csrw medeleg, zero

  call setup_page_tables
  call setup_pmp
  call enable_sv39

  li s0, CAUSE_LOAD_ACCESS
  li s1, TEST_VA

  li t0, (3 << 11)
  csrc mstatus, t0
  li t0, (1 << 11)
  csrs mstatus, t0
  la t0, smode_load_test
  csrw mepc, t0
  mret

setup_page_tables:
  la t0, root_table

  la t1, l1_test_table
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_V
  sd t1, 8(t0)        // root[1] covers TEST_VA.

  li t1, IDENTITY_BASE
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_VRWXAD
  sd t1, 16(t0)       // root[2] identity superpage keeps S-mode code executable.

  la t0, l1_test_table
  la t1, l0_test_table
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_V
  sd t1, 0(t0)

  la t0, l0_test_table
  la t1, data_page
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_VR  // 故意不置 A/D，迫使 walker 尝试写回 A 位。
  sd t1, 0(t0)
  ret

setup_pmp:
  la t0, l0_test_table
  srli t0, t0, 2
  li t1, ((PMP_RO_SIZE - 1) >> 3)
  or t0, t0, t1
  csrw pmpaddr0, t0

  li t0, PMP_NAPOT_ADDR(IDENTITY_BASE, PMP_ALLOW_SIZE)
  csrw pmpaddr1, t0
  li t0, (PMP_CFG_R_NAPOT | (PMP_CFG_RWX_NAPOT << 8))
  csrw pmpcfg0, t0
  fence.i
  ret

enable_sv39:
  li t0, (8 << 60)
  la t1, root_table
  srli t1, t1, 12
  or t0, t0, t1
  csrw satp, t0
  sfence.vma
  ret

smode_load_test:
  li t0, TEST_VA
  ld t1, 0(t0)
  j fail

trap_handler:
  csrr t0, mcause
  bne t0, s0, fail
  csrr t0, mtval
  bne t0, s1, fail

pass:
  csrw satp, zero
  sfence.vma
  li t0, SYSCON_RESET_MMIO
  li t1, SYSCON_POWEROFF_VALUE
  sw t1, 0(t0)

pass_spin:
  j pass_spin

fail:
  csrw satp, zero
  sfence.vma
  li t0, 0x10000000
  li t1, 0x46
  sb t1, 0(t0)

fail_spin:
  j fail_spin

  .section .data, "aw", @progbits
  .balign 4096
root_table:
  .zero 4096
  .balign 4096
l1_test_table:
  .zero 4096
  .balign 4096
l0_test_table:
  .zero 4096
  .balign 4096
data_page:
  .dword 0x1122334455667788
  .zero 4088

  .option pop
