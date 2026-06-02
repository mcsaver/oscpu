// Focused Sv39 SRET smoke for entering a mapped U-mode execute page.
// Linux restores user registers while still in S-mode and then executes SRET;
// the first user fetch must use U privilege, not the old S privilege.

#ifndef SRET_USER_SV39_STACK
#define SRET_USER_SV39_STACK 0x87ef4000
#endif
#ifndef SRET_USER_SV39_ROOT
#define SRET_USER_SV39_ROOT 0x80004000
#endif
#ifndef SRET_USER_SV39_L1
#define SRET_USER_SV39_L1 0x80005000
#endif
#ifndef SRET_USER_SV39_L0
#define SRET_USER_SV39_L0 0x80006000
#endif
#ifndef SRET_USER_SV39_UVA
#define SRET_USER_SV39_UVA 0x0000003fb6410002
#endif

#define PTE_VRWXAD 0xcf
#define PTE_U_VRWXAD 0xdf

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, SRET_USER_SV39_STACK

  lla t0, m_handler
  csrw mtvec, t0
  lla t0, s_handler
  csrw stvec, t0

  li t0, (1 << 8) | (1 << 12)
  csrs medeleg, t0

  li t0, (1 << 11)
  csrs mstatus, t0
  lla t0, s_entry
  csrw mepc, t0
  mret

m_handler:
  csrr a0, mcause
  ebreak

s_entry:
  li t0, SRET_USER_SV39_ROOT
  li t1, SRET_USER_SV39_L1
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, 0x1
  sd t1, 16(t0) // root VPN2=2 for 0x80000000

  li t2, SRET_USER_SV39_UVA
  srli t3, t2, 30
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  li t0, SRET_USER_SV39_L1
  li t1, SRET_USER_SV39_L0
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, 0x1
  sd t1, 0(t0)

  srli t3, t2, 21
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  li t0, SRET_USER_SV39_L0
  li t1, 0x80000000
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_VRWXAD
  sd t1, 0(t0)

  lla t2, u_entry
  srli t1, t2, 12
  slli t1, t1, 10
  ori t1, t1, PTE_U_VRWXAD
  li t2, SRET_USER_SV39_UVA
  srli t3, t2, 12
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  li t0, (8 << 60)
  li t1, SRET_USER_SV39_ROOT
  srli t1, t1, 12
  or t0, t0, t1
  csrw satp, t0
  sfence.vma

  li t0, SRET_USER_SV39_UVA
  csrw sepc, t0
  li t0, 0x100
  csrc sstatus, t0
  nop
  sret

s_handler:
  csrr t0, scause
  li t1, 8
  bne t0, t1, fail_scause
  csrr t0, sepc
  li t1, SRET_USER_SV39_UVA
  bne t0, t1, fail_sepc
  csrr t0, sstatus
  andi t0, t0, 0x100
  bnez t0, fail_spp
  li a0, 0
  ebreak

fail_scause:
  li a0, 1
  ebreak

fail_sepc:
  li a0, 2
  ebreak

fail_spp:
  li a0, 3
  ebreak

  .balign 4096
  .2byte 0x0001 // c.nop padding: u_entry is intentionally 2-byte aligned.
u_entry:
  .4byte 0x00000073 // ecall at pc % 4 == 2, matching RVC-heavy userland.
  li a0, 4
  ebreak

  .option pop
