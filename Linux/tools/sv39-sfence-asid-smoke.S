// NEMU Sv39 TLB smoke：验证 sfence.vma 按 VA/ASID 精细失效，并保留 PTE_G 全局项。
#ifndef SV39_SFENCE_ASID_STACK
#define SV39_SFENCE_ASID_STACK 0x87eee000
#endif

#ifndef SYSCON_RESET_MMIO
#define SYSCON_RESET_MMIO 0x100000
#endif

#ifndef SYSCON_POWEROFF_VALUE
#define SYSCON_POWEROFF_VALUE 0x5555
#endif

#define VA_NONGLOBAL 0x0000000040000000
#define VA_GLOBAL    0x0000000040001000
#define SATP_ASID1   1
#define SATP_ASID2   2

#define VALUE_A 0x1111222233334444
#define VALUE_B 0x5555666677778888

#define PTE_V       0x001
#define PTE_VRWXAD  0x0cf
#define PTE_VRWAD   0x0c7
#define PTE_G_VRWAD 0x0e7

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2

_start:
  li sp, SV39_SFENCE_ASID_STACK
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1f // NAPOT RWX for S-mode Sv39 focused smoke access.
  csrw pmpcfg0, t0
  call setup_page_tables
  call enable_sv39_asid1

  li t0, (3 << 11)
  csrc mstatus, t0
  li t0, (1 << 11)
  csrs mstatus, t0
  la t0, s_entry
  csrw mepc, t0
  mret

setup_page_tables:
  mv s0, ra           // 本函数会调用子 helper，先保存外层返回地址。
  la t0, root_table

  la t1, l1_table
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_V
  sd t1, 8(t0)       // root[1] 覆盖 0x40000000 测试 VA。

  li t1, 0x80000000
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_VRWXAD
  sd t1, 16(t0)      // root[2] 用 1GiB identity superpage 让 S-mode 访问代码和页表。

  la t0, l1_table
  la t1, l0_table
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_V
  sd t1, 0(t0)

  la t0, l0_table
  call map_nonglobal_to_page_a
  call map_global_to_page_a
  mv ra, s0
  ret

enable_sv39_asid1:
  li t0, 8
  slli t0, t0, 60
  li t1, SATP_ASID1
  slli t1, t1, 44
  or t0, t0, t1
  la t1, root_table
  srli t1, t1, 12
  or t0, t0, t1
  csrw satp, t0
  sfence.vma
  ret

switch_sv39_asid:
  li t4, 8
  slli t4, t4, 60
  slli t5, a0, 44
  or t4, t4, t5
  la t5, root_table
  srli t5, t5, 12
  or t4, t4, t5
  csrw satp, t4       // ASID 切换不发 fence，用来验证 satp 写不再粗暴清空 TLB。
  ret

map_nonglobal_to_page_a:
  la t2, l0_table
  la t3, page_a
  srli t3, t3, 12
  slli t3, t3, 10
  ori t3, t3, PTE_VRWAD
  sd t3, 0(t2)
  ret

map_nonglobal_to_page_b:
  la t2, l0_table
  la t3, page_b
  srli t3, t3, 12
  slli t3, t3, 10
  ori t3, t3, PTE_VRWAD
  sd t3, 0(t2)
  ret

map_global_to_page_a:
  la t2, l0_table
  la t3, page_a
  srli t3, t3, 12
  slli t3, t3, 10
  ori t3, t3, PTE_G_VRWAD
  sd t3, 8(t2)
  ret

map_global_to_page_b:
  la t2, l0_table
  la t3, page_b
  srli t3, t3, 12
  slli t3, t3, 10
  ori t3, t3, PTE_G_VRWAD
  sd t3, 8(t2)
  ret

s_entry:
  li t0, VA_NONGLOBAL
  ld t2, 0(t0)
  li t3, VALUE_A
  bne t2, t3, fail

  call map_nonglobal_to_page_b
  li t0, VA_NONGLOBAL
  li a0, SATP_ASID2
  call switch_sv39_asid
  ld t2, 0(t0)
  li t3, VALUE_B
  bne t2, t3, fail

  li a0, SATP_ASID1
  call switch_sv39_asid
  li t0, VA_NONGLOBAL
  ld t2, 0(t0)
  li t3, VALUE_A
  bne t2, t3, fail

  li t1, SATP_ASID2
  sfence.vma t0, t1
  ld t2, 0(t0)
  li t3, VALUE_A
  bne t2, t3, fail

  li t1, SATP_ASID1
  sfence.vma t0, t1
  ld t2, 0(t0)
  li t3, VALUE_B
  bne t2, t3, fail

  li t0, VA_GLOBAL
  ld t2, 0(t0)
  li t3, VALUE_A
  bne t2, t3, fail

  call map_global_to_page_b
  li t0, VA_GLOBAL
  li t1, SATP_ASID1
  sfence.vma t0, t1
  ld t2, 0(t0)
  li t3, VALUE_A
  bne t2, t3, fail

  sfence.vma t0, zero
  ld t2, 0(t0)
  li t3, VALUE_B
  bne t2, t3, fail

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
l1_table:
  .zero 4096
  .balign 4096
l0_table:
  .zero 4096
  .balign 4096
page_a:
  .dword VALUE_A
  .zero 4088
  .balign 4096
page_b:
  .dword VALUE_B
  .zero 4088

  .option pop
