// Focused Sv39/RVC smoke for a 32-bit instruction at the last halfword of a
// page.
// The Ubuntu rootfs blocker showed ld-linux taking an illegal instruction where
// the low halfword matched memory but the high halfword did not.  This keeps the
// privilege/Sv39 shape of the Linux path and executes the same slli encoding
// family at a halfword-aligned user virtual address whose 32-bit instruction
// crosses into a non-contiguous physical page.

#ifndef SRET_USER_SV39_HALF_STACK
#define SRET_USER_SV39_HALF_STACK 0x87ef1000
#endif
#ifndef SRET_USER_SV39_HALF_ROOT
#define SRET_USER_SV39_HALF_ROOT 0x80004000
#endif
#ifndef SRET_USER_SV39_HALF_L1
#define SRET_USER_SV39_HALF_L1 0x80005000
#endif
#ifndef SRET_USER_SV39_HALF_L0
#define SRET_USER_SV39_HALF_L0 0x80006000
#endif
#ifndef SRET_USER_SV39_HALF_UVA
#define SRET_USER_SV39_HALF_UVA 0x0000003fa2184ffe
#endif

#define PTE_VRWXAD 0xcf
#define PTE_U_VRWXAD 0xdf
#define SSTATUS_SPIE 0x20
#define SSTATUS_SXL_UXL 0x0000000a00000000
#define USER_S0_VALUE 0x1234
#define USER_EXPECT (((USER_S0_VALUE) << 2) + 1)

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option rvc
  .align 2
_start:
  li sp, SRET_USER_SV39_HALF_STACK

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
  li t0, SRET_USER_SV39_HALF_ROOT
  li t1, SRET_USER_SV39_HALF_L1
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, 0x1
  sd t1, 16(t0) // root VPN2=2 for 0x80000000

  li t2, SRET_USER_SV39_HALF_UVA
  srli t3, t2, 30
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  li t0, SRET_USER_SV39_HALF_L1
  li t1, SRET_USER_SV39_HALF_L0
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, 0x1
  sd t1, 0(t0)

  srli t3, t2, 21
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  li t0, SRET_USER_SV39_HALF_L0
  li t1, 0x80000000
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_VRWXAD
  sd t1, 0(t0)

  lla t2, u_entry_lo
  srli t1, t2, 12
  slli t1, t1, 10
  ori t1, t1, PTE_U_VRWXAD
  li t2, SRET_USER_SV39_HALF_UVA
  srli t3, t2, 12
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  lla t2, u_entry_hi
  srli t1, t2, 12
  slli t1, t1, 10
  ori t1, t1, PTE_U_VRWXAD
  li t2, SRET_USER_SV39_HALF_UVA + 0x1000
  srli t3, t2, 12
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  li t0, (8 << 60)
  li t1, SRET_USER_SV39_HALF_ROOT
  srli t1, t1, 12
  or t0, t0, t1
  csrw satp, t0
  sfence.vma

  li s0, USER_S0_VALUE
  li t0, SRET_USER_SV39_HALF_UVA
  csrw sepc, t0
  li t0, 0x100
  csrc sstatus, t0
  li t0, SSTATUS_SXL_UXL | SSTATUS_SPIE
  csrs sstatus, t0
  nop
  sret

s_handler:
  csrr t0, scause
  li t1, 8
  bne t0, t1, fail_scause
  csrr t0, sepc
  li t1, SRET_USER_SV39_HALF_UVA + 8
  bne t0, t1, fail_sepc
  csrr t0, stval
  bnez t0, fail_stval
  li t0, USER_EXPECT
  bne a3, t0, fail_result
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

fail_stval:
  li a0, 3
  ebreak

fail_result:
  li a0, 4
  ebreak

fail_spp:
  li a0, 5
  ebreak

  .balign 4096
u_entry_lo_page:
  .space 4094
u_entry_lo:
  .2byte 0x1693 // low half of slli a3,s0,0x2 at page offset 0xffe.
u_entry_poison_page:
  .2byte 0x97de // contiguous-physical poison; old fetch forms 0x97de1693.
  .space 4094
u_entry_hi:
  .2byte 0x0024 // high half of the slli, mapped as the next virtual page.
  .4byte 0x00168693 // addi a3,a3,1; proves the first instruction executed.
  .4byte 0x00000073 // ecall.
  li a0, 6
  ebreak

  .option pop
