// Linux ret_from_exception shaped SRET smoke.
// It restores sstatus/sepc from a trapframe, reloads user GPRs, then executes
// sret to a high Sv39 U page. A wrong CSR serialization or privilege boundary
// shows up as an instruction page fault with SPP still set.

#ifndef SRET_RESTORE_STACK
#define SRET_RESTORE_STACK 0x87ef3000
#endif
#ifndef SRET_RESTORE_ROOT
#define SRET_RESTORE_ROOT 0x80004000
#endif
#ifndef SRET_RESTORE_L1
#define SRET_RESTORE_L1 0x80005000
#endif
#ifndef SRET_RESTORE_L0
#define SRET_RESTORE_L0 0x80006000
#endif
#ifndef SRET_RESTORE_FRAME
#define SRET_RESTORE_FRAME 0x80000800
#endif
#ifndef SRET_RESTORE_THREAD
#define SRET_RESTORE_THREAD 0x80000c00
#endif
#ifndef SRET_RESTORE_UVA
#define SRET_RESTORE_UVA 0x0000003fb6410002
#endif
#ifndef SRET_RESTORE_HIGH_DELTA
#define SRET_RESTORE_HIGH_DELTA 0xffffffff00000000
#endif

#define PTE_V 0x1
#define PTE_VRWXAD 0xcf
#define PTE_U_VRWXAD 0xdf
#define SSTATUS_SPIE 0x20
#define SSTATUS_SXL_UXL 0x0000000a00000000

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option rvc
  .align 2
_start:
  li sp, SRET_RESTORE_STACK

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
  jal setup_sv39
  jal setup_frame

  li t0, (8 << 60)
  li t1, SRET_RESTORE_ROOT
  srli t1, t1, 12
  or t0, t0, t1
  csrw satp, t0
  sfence.vma

  lla t0, high_s_entry
  li t1, SRET_RESTORE_HIGH_DELTA
  add t0, t0, t1
  jr t0

high_s_entry:
  li tp, SRET_RESTORE_THREAD
  li sp, SRET_RESTORE_FRAME

ret_from_exception_like:
  ld s0, 256(sp)
  andi s0, s0, 256
  bnez s0, 1f
  addi s0, sp, 288
  sd s0, 16(tp)
  csrw sscratch, tp
1:
  ld a0, 256(sp)
  ld a2, 0(sp)
  sc.d zero, a2, (sp)
  csrw sstatus, a0
  csrw sepc, a2
  ld ra, 8(sp)
  ld gp, 24(sp)
  ld tp, 32(sp)
  ld t0, 40(sp)
  ld t1, 48(sp)
  ld t2, 56(sp)
  ld s0, 64(sp)
  ld s1, 72(sp)
  ld a0, 80(sp)
  ld a1, 88(sp)
  ld a2, 96(sp)
  ld a3, 104(sp)
  ld a4, 112(sp)
  ld a5, 120(sp)
  ld a6, 128(sp)
  ld a7, 136(sp)
  ld s2, 144(sp)
  ld s3, 152(sp)
  ld s4, 160(sp)
  ld s5, 168(sp)
  ld s6, 176(sp)
  ld s7, 184(sp)
  ld s8, 192(sp)
  ld s9, 200(sp)
  ld s10, 208(sp)
  ld s11, 216(sp)
  ld t3, 224(sp)
  ld t4, 232(sp)
  ld t5, 240(sp)
  ld t6, 248(sp)
  ld sp, 16(sp)
  sret

setup_sv39:
  li t0, SRET_RESTORE_ROOT
  li t1, SRET_RESTORE_L1
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_V
  sd t1, 16(t0) // root VPN2=2 for 0x80000000
  li t3, 4080
  add t3, t0, t3
  sd t1, 0(t3) // root VPN2=510 for 0xffffffff80000000

  li t2, SRET_RESTORE_UVA
  srli t3, t2, 30
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  li t0, SRET_RESTORE_L1
  li t1, SRET_RESTORE_L0
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_V
  sd t1, 0(t0)

  srli t3, t2, 21
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)

  li t0, SRET_RESTORE_L0
  li t1, 0x80000000
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_VRWXAD
  sd t1, 0(t0)

  lla t2, u_entry
  srli t1, t2, 12
  slli t1, t1, 10
  ori t1, t1, PTE_U_VRWXAD
  li t2, SRET_RESTORE_UVA
  srli t3, t2, 12
  andi t3, t3, 0x1ff
  slli t3, t3, 3
  add t3, t0, t3
  sd t1, 0(t3)
  ret

setup_frame:
  li t0, SRET_RESTORE_FRAME
  li t1, SRET_RESTORE_UVA
  sd t1, 0(t0)
  li t1, 0x0000003fbcb89218
  sd t1, 8(t0)
  li t1, 0x0000003fcd4c7930
  sd t1, 16(t0)
  lla t1, __global_pointer$
  sd t1, 24(t0)
  sd zero, 32(t0)
  li t1, 0x0000003fbcb89210
  sd t1, 40(t0)
  li t1, 1
  sd t1, 48(t0)
  li t1, 0x2f
  sd t1, 56(t0)
  li t1, 0x0000003fcd4c7c00
  sd t1, 64(t0)
  li t1, 0x0000003fcd4c7988
  sd t1, 72(t0)
  li t1, 0x6474e551
  sd t1, 80(t0)
  sd zero, 88(t0)
  li t1, 0x6474e552
  sd t1, 96(t0)
  li t1, 0x0000003fbcb7edd4
  sd t1, 104(t0)
  li t1, 7
  sd t1, 112(t0)
  li t1, 0x0000002ad2cd6040
  sd t1, 120(t0)
  li t1, 0x0000003fbcb89800
  sd t1, 128(t0)
  li t1, 0xfff
  sd t1, 136(t0)
  li t1, 0x0000002ad2cd6270
  sd t1, 144(t0)
  li t1, 0x0000003fbcb892a0
  sd t1, 152(t0)
  li t1, 0x0000003fbcb87cf8
  sd t1, 160(t0)
  sd zero, 168(t0)
  li t1, 0x0000003fbcb87d18
  sd t1, 176(t0)
  sd zero, 184(t0)
  li t1, 0x0000003fbcb89050
  sd t1, 192(t0)
  li t1, 0x2e
  sd t1, 200(t0)
  li t1, 0x0000002ad2cd6040
  sd t1, 208(t0)
  sd zero, 216(t0)
  li t1, 2
  sd t1, 224(t0)
  li t1, -4096
  sd t1, 232(t0)
  sd zero, 240(t0)
  sd zero, 248(t0)
  li t1, SSTATUS_SXL_UXL | SSTATUS_SPIE
  sd t1, 256(t0)
  ret

  .align 2
s_handler:
  csrr t0, scause
  li t1, 8
  bne t0, t1, fail_scause
  csrr t0, sepc
  li t1, SRET_RESTORE_UVA
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
u_page:
  .org u_page + (SRET_RESTORE_UVA & 0xfff)
u_entry:
  .4byte 0x00000073
  li a0, 4
  ebreak

  .option pop
