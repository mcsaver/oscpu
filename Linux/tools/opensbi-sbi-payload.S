#ifndef OPENSBI_SBI_STACK
#define OPENSBI_SBI_STACK 0x87efd000
#endif

#define FDT_MAGIC_LE          0xedfe0dd0
#define SBI_SUCCESS           0
#define SBI_EXT_LEGACY_PUTCHAR 0x1
#define SBI_EXT_BASE          0x10
#define SBI_EXT_TIME          0x54494d45
#define SBI_BASE_GET_SPEC_VERSION 0
#define SBI_BASE_PROBE_EXTENSION  3
#define SSTATUS_SIE           0x2
#define SIE_STIE              0x20
#define SCAUSE_INTERRUPT      0x8000000000000000
#define IRQ_STI               5

  .section .bss, "aw", @nobits
  .align 3
timer_seen:
  .dword 0
timer_scause:
  .dword 0
timer_sepc:
  .dword 0

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, OPENSBI_SBI_STACK

  bnez a0, fail_hartid
  beqz a1, fail_dtb
  lwu t0, 0(a1)
  li t1, FDT_MAGIC_LE
  bne t0, t1, fail_dtb

  li a7, SBI_EXT_BASE
  li a6, SBI_BASE_GET_SPEC_VERSION
  ecall
  li t0, SBI_SUCCESS
  bne a0, t0, fail_base
  beqz a1, fail_base

  li a7, SBI_EXT_BASE
  li a6, SBI_BASE_PROBE_EXTENSION
  li a0, SBI_EXT_TIME
  ecall
  li t0, SBI_SUCCESS
  bne a0, t0, fail_probe_time
  beqz a1, fail_probe_time

  li a7, SBI_EXT_BASE
  li a6, SBI_BASE_PROBE_EXTENSION
  li a0, SBI_EXT_LEGACY_PUTCHAR
  ecall
  li t0, SBI_SUCCESS
  bne a0, t0, fail_probe_console
  beqz a1, fail_probe_console

  li a0, 'B'
  li a7, SBI_EXT_LEGACY_PUTCHAR
  ecall
  li a0, '\n'
  li a7, SBI_EXT_LEGACY_PUTCHAR
  ecall

  la t0, s_timer_trap
  csrw stvec, t0
  li t0, SIE_STIE
  csrs sie, t0
  li t0, SSTATUS_SIE
  csrs sstatus, t0

  rdtime t0
  li t1, 100000
  add a0, t0, t1
  li a7, SBI_EXT_TIME
  li a6, 0
  ecall
  li t0, SBI_SUCCESS
  bne a0, t0, fail_timer

  li t3, 200000
s_timer_wait:
  .globl s_timer_wfi_pc
s_timer_wfi_pc:
  wfi
  la t0, timer_seen
  ld t1, 0(t0)
  bnez t1, check_timer
  addi t3, t3, -1
  bnez t3, s_timer_wait
  j fail_timer_timeout

check_timer:
  la t0, timer_scause
  ld t1, 0(t0)
  li t2, SCAUSE_INTERRUPT
  ori t2, t2, IRQ_STI
  bne t1, t2, fail_timer_cause

  la t0, timer_sepc
  ld t1, 0(t0)
  la t2, s_timer_wfi_pc
  bltu t1, t2, fail_timer_epc
  la t2, check_timer
  bgeu t1, t2, fail_timer_epc

timer_ok:
  li a0, 0
  ebreak

s_timer_trap:
  csrr t0, scause
  la t1, timer_scause
  sd t0, 0(t1)
  csrr t0, sepc
  la t1, timer_sepc
  sd t0, 0(t1)
  li t0, SIE_STIE
  csrc sie, t0
  la t1, timer_seen
  li t0, 1
  sd t0, 0(t1)
  sret

fail_hartid:
  li a0, 1
  ebreak
fail_dtb:
  li a0, 2
  ebreak
fail_base:
  li a0, 3
  ebreak
fail_probe_time:
  li a0, 4
  ebreak
fail_probe_console:
  li a0, 5
  ebreak
fail_timer:
  li a0, 6
  ebreak
fail_timer_timeout:
  li a0, 7
  ebreak
fail_timer_cause:
  li a0, 8
  ebreak
fail_timer_epc:
  li a0, 9
  ebreak
  .option pop
