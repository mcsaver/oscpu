.section .text
.globl _start
.option norvc
.option nopic
.option norelax
_start:
  la t0, mhandler
  csrw mtvec, t0
  li t0, 0x6008
  csrw mstatus, t0
  # Grant S/U access to the test image before entering those modes.
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x1f
  csrw pmpcfg0, t0
  la s0, data
  li s1, 0
  li s7, 0

  # Type 6 execute: precise C instruction boundary and no destination update.
  la s2, compressed_hit
  mv s3, s2
  li s4, 3
  li s5, 2
  li s6, 17
  csrw 0x7a2, s2
  li t0, 0x6000000000000044
  csrw 0x7a1, t0
.option rvc
compressed_hit:
  c.addi s6, 1
  c.nop
.option norvc
  li t0, 17
  bne s6, t0, fail
  csrw 0x7a1, zero

  # Execute address has priority over illegal instruction decode.
  la s2, illegal_hit
  mv s3, s2
  li s5, 4
  csrw 0x7a2, s2
  li t0, 0x6000000000000044
  csrw 0x7a1, t0
illegal_hit:
  .word 0xffffffff
  csrw 0x7a1, zero

  # A wrong-path execute match must disappear with the younger owner.
  la t0, wrong_path
  csrw 0x7a2, t0
  li t0, 0x6000000000000044
  csrw 0x7a1, t0
  j after_wrong_path
wrong_path:
  li a0, 80
after_wrong_path:
  csrw 0x7a1, zero
  li t0, 2
  bne s1, t0, fail

  # Load, store, LR, SC and AMO all trap before any architectural effect.
  mv s3, s0
  csrw 0x7a2, s0
  li t0, 0x6000000000000041
  csrw 0x7a1, t0
  la s2, load_hit
  li s6, 19
load_hit:
  ld s6, 0(s0)
  li t0, 19
  bne s6, t0, fail
  la s2, lr_hit
lr_hit:
  lr.d s6, (s0)
  li t0, 19
  bne s6, t0, fail
  la s2, amo_load_hit
amo_load_hit:
  amoadd.d s6, s6, (s0)
  li t0, 19
  bne s6, t0, fail
  li t0, 0x6000000000000042
  csrw 0x7a1, t0
  la s2, store_hit
store_hit:
  sd s6, 0(s0)
  la s2, sc_hit
sc_hit:
  sc.d s6, s6, (s0)
  li t0, 19
  bne s6, t0, fail
  la s2, amo_store_hit
amo_store_hit:
  amoswap.d s6, s6, (s0)
  li t0, 19
  bne s6, t0, fail
  csrw 0x7a1, zero
  ld t0, 0(s0)
  li t1, 0x123456
  bne t0, t1, fail
  li t0, 8
  bne s1, t0, fail

  # Disabling MIE suppresses native M-mode trigger reentrancy.
  csrci mstatus, 8
  la t0, masked_hit
  csrw 0x7a2, t0
  li t0, 0x6000000000000044
  csrw 0x7a1, t0
masked_hit:
  addi s6, s6, 1
  csrw 0x7a1, zero
  li t0, 20
  bne s6, t0, fail
  csrsi mstatus, 8

  # One S-mode breakpoint is delegated and resumes through SRET.
  la t0, shandler
  csrw stvec, t0
  li t0, 8
  csrw medeleg, t0
  la s2, supervisor_hit
  mv s3, s2
  csrw 0x7a2, s2
  li t0, 0x6000000000000014
  csrw 0x7a1, t0
  la t0, supervisor_hit
  csrw mepc, t0
  li t0, 0x6882
  csrw mstatus, t0
  mret
supervisor_hit:
  addi s6, s6, 1
  li t0, 20
  bne s6, t0, fail
  la s2, supervisor_ecall
  li s3, 0
  li s4, 9
  li s7, 1
supervisor_ecall:
  ecall
  csrw 0x7a1, zero
  csrw medeleg, zero
  li t0, 10
  bne s1, t0, fail

  # U execute breakpoint returns to U; trigger CSR access in U is illegal.
  la s2, user_hit
  mv s3, s2
  li s4, 3
  csrw 0x7a2, s2
  li t0, 0x600000000000000c
  csrw 0x7a1, t0
  la t0, user_hit
  csrw mepc, t0
  li t0, 0x6080
  csrw mstatus, t0
  mret
user_hit:
  addi s6, s6, 1
  li t0, 20
  bne s6, t0, fail
  la s2, user_csr
  li s3, 0x7a1022f3
  li s4, 2
  li s7, 1
user_csr:
  csrr t0, 0x7a1
  csrw 0x7a1, zero
  li t0, 12
  bne s1, t0, fail
  csrw mtvec, zero
  li a0, 0
  ebreak

.balign 4
mhandler:
  csrr t0, mcause
  bne t0, s4, fail
  csrr t0, mepc
  bne t0, s2, fail
  csrr t1, mtval
  bne t1, s3, fail
  add t0, t0, s5
  csrw mepc, t0
  addi s1, s1, 1
  beqz s7, 1f
  li t0, 0x1800
  csrs mstatus, t0
  li s7, 0
1:
  mret
.balign 4
shandler:
  csrr t0, scause
  bne t0, s4, fail
  csrr t0, sepc
  bne t0, s2, fail
  csrr t1, stval
  bne t1, s3, fail
  add t0, t0, s5
  csrw sepc, t0
  addi s1, s1, 1
  sret
fail:
  li a0, 99
  ebreak
.section .data
.balign 8
data:
  .dword 0x123456
