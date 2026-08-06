// SPDX-License-Identifier: MIT
// Local RV64 L2 mini-system payload. OpenSBI enters this image in S-mode.

#define L2_STACK                 0x83fff000
#define FDT_MAGIC_LE             0xedfe0dd0

#define SBI_SUCCESS              0
#define SBI_EXT_LEGACY_PUTCHAR   0x1
#define SBI_EXT_BASE             0x10
#define SBI_EXT_TIME             0x54494d45
#define SBI_EXT_SRST             0x53525354
#define SBI_BASE_GET_SPEC        0
#define SBI_BASE_PROBE_EXT       3

#define SSTATUS_SIE              0x2
#define SSTATUS_SPP              0x100
#define SIE_STIE                 0x20
#define SIE_SEIE                 0x200
#define SCAUSE_INTERRUPT         0x8000000000000000
#define IRQ_STI                  5
#define IRQ_SEI                  9

#define UART_BASE                0x10000000
#define UART_RBR                 (UART_BASE + 0)
#define UART_IER                 (UART_BASE + 1)
#define UART_IIR                 (UART_BASE + 2)
#define UART_LCR                 (UART_BASE + 3)
#define UART_LSR                 (UART_BASE + 5)

#define PLIC_PRIORITY1           0x0c000004
#define PLIC_S_ENABLE            0x0c002080
#define PLIC_S_THRESHOLD         0x0c201000
#define PLIC_S_CLAIM             0x0c201004

#define SATP_SV39                0x8000000000000000
#define U_CODE_VA                0x0000000040000000
#define U_AD_VA                  0x0000000040001000
#define U_PERMISSION_VA          0x0000000040002000
#define S_REMAP_VA               0x0000000040003000
#define U_ATOMIC_VA              0x0000000040004000

#define PTE_V                    0x001
#define PTE_R                    0x002
#define PTE_W                    0x004
#define PTE_X                    0x008
#define PTE_U                    0x010
#define PTE_A                    0x040
#define PTE_D                    0x080
#define PTE_S_RWXAD              0x0cf
#define PTE_U_RXA                0x05b
#define PTE_U_RW                 0x017
#define PTE_U_RA                 0x053
#define PTE_U_RWAD               0x0d7
#define PTE_S_RWAD               0x0c7

  .section .text.start, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, L2_STACK
  mv s1, a1
  bnez a0, fail_hartid
  beqz s1, fail_dtb
  lwu t0, 0(s1)
  li t1, FDT_MAGIC_LE
  bne t0, t1, fail_dtb

  li a7, SBI_EXT_BASE
  li a6, SBI_BASE_GET_SPEC
  ecall
  bnez a0, fail_sbi_base
  beqz a1, fail_sbi_base
  li a0, SBI_EXT_TIME
  call probe_extension
  beqz a0, fail_sbi_time
  li a0, SBI_EXT_SRST
  call probe_extension
  beqz a0, fail_sbi_srst

  la a0, marker_begin
  call sbi_puts
  la a0, marker_opensbi
  call sbi_puts
  la a0, marker_m_to_s
  call sbi_puts
  la a0, marker_fdt
  call sbi_puts

  la t0, s_trap
  csrw stvec, t0
  la a0, marker_case_select
  call sbi_puts
  call uart_read_selector
  mv s2, a0

  li t0, 'p'
  beq s2, t0, case_privilege
  li t0, 'v'
  beq s2, t0, case_sv39
  li t0, 't'
  beq s2, t0, case_timer
  li t0, 'i'
  beq s2, t0, case_interrupt
  li t0, 'a'
  beq s2, t0, case_atomic_mmio
  li t0, 'd'
  beq s2, t0, case_shutdown
  li t0, 'x'
  beq s2, t0, case_all
  li a0, 10
  j l2_fail

case_privilege:
  la a0, marker_case_privilege
  call sbi_puts
  call run_vm_user
  j l2_finish

case_sv39:
  la a0, marker_case_sv39
  call sbi_puts
  call run_vm_user
  j l2_finish

case_timer:
  la a0, marker_case_timer
  call sbi_puts
  call run_timer
  j l2_finish

case_interrupt:
  la a0, marker_case_interrupt
  call sbi_puts
  call run_mmio
  call run_uart_plic_irq
  j l2_finish

case_atomic_mmio:
  la a0, marker_case_atomic_mmio
  call sbi_puts
  call run_vm_user
  call run_mmio
  j l2_finish

case_shutdown:
  la a0, marker_case_shutdown
  call sbi_puts
  j l2_finish

case_all:
  la a0, marker_case_all
  call sbi_puts
  call run_vm_user
  call run_timer
  call run_mmio
  call run_uart_plic_irq

l2_finish:
  la a0, marker_powerdown
  call sbi_puts
  la a0, marker_pass
  call sbi_puts
  li a0, 0
  call sbi_shutdown
1:
  wfi
  j 1b

fail_hartid:
  li a0, 1
  j l2_fail
fail_dtb:
  li a0, 2
  j l2_fail
fail_sbi_base:
  li a0, 3
  j l2_fail
fail_sbi_time:
  li a0, 4
  j l2_fail
fail_sbi_srst:
  li a0, 5
  j l2_fail

probe_extension:
  mv t0, a0
  li a7, SBI_EXT_BASE
  li a6, SBI_BASE_PROBE_EXT
  mv a0, t0
  ecall
  bnez a0, 1f
  snez a0, a1
  ret
1:
  li a0, 0
  ret

sbi_puts:
  addi sp, sp, -16
  sd ra, 8(sp)
  sd s0, 0(sp)
  mv s0, a0
1:
  lbu a0, 0(s0)
  beqz a0, 2f
  li a7, SBI_EXT_LEGACY_PUTCHAR
  ecall
  addi s0, s0, 1
  j 1b
2:
  ld s0, 0(sp)
  ld ra, 8(sp)
  addi sp, sp, 16
  ret

uart_read_selector:
  li t0, UART_BASE
1:
  lbu t1, 5(t0)
  andi t1, t1, 1
  beqz t1, 1b
  lbu a0, 0(t0)
  ret

run_vm_user:
  addi sp, sp, -16
  sd ra, 8(sp)
  call clear_vm_state
  call setup_page_tables
  la t0, l2_root
  srli t0, t0, 12
  li t1, SATP_SV39
  or t0, t0, t1
  csrw satp, t0
  sfence.vma
  la a0, marker_sv39
  call sbi_puts
  call enter_user

  la t0, ad_fault_seen
  ld t1, 0(t0)
  li t2, 1
  bgtu t1, t2, fail_vm
  la t0, u_l0
  ld t1, 8(t0)
  andi t1, t1, PTE_A | PTE_D
  li t2, PTE_A | PTE_D
  bne t1, t2, fail_vm
  la t0, permission_fault_seen
  ld t1, 0(t0)
  li t2, 1
  bne t1, t2, fail_vm
  la t0, user_ecall_seen
  ld t1, 0(t0)
  bne t1, t2, fail_vm

  la a0, marker_ad
  call sbi_puts
  la a0, marker_permission
  call sbi_puts
  la a0, marker_s_to_u
  call sbi_puts
  la a0, marker_atomic
  call sbi_puts

  li t0, S_REMAP_VA
  ld t1, 0(t0)
  li t2, 0x1111222233334444
  bne t1, t2, fail_vm
  la t0, u_l0
  la t1, remap_page_b
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_S_RWAD
  sd t1, 24(t0)
  li t0, S_REMAP_VA
  sfence.vma t0, zero
  ld t1, 0(t0)
  li t2, 0x5555666677778888
  bne t1, t2, fail_vm
  la a0, marker_sfence
  call sbi_puts

  ld ra, 8(sp)
  addi sp, sp, 16
  ret
fail_vm:
  li a0, 20
  j l2_fail

clear_vm_state:
  la t0, __bss_start
  la t1, __bss_end
1:
  bgeu t0, t1, 2f
  sd zero, 0(t0)
  addi t0, t0, 8
  j 1b
2:
  ret

setup_page_tables:
  la t0, l2_root
  li t1, PTE_S_RWXAD
  sd t1, 0(t0)
  li t1, 0x80000000
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_S_RWXAD
  sd t1, 16(t0)

  la t1, u_l1
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_V
  sd t1, 8(t0)
  la t0, u_l1
  la t1, u_l0
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_V
  sd t1, 0(t0)

  la t0, u_l0
  la t1, u_entry
  li t2, -4096
  and t1, t1, t2
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_U_RXA
  sd t1, 0(t0)
  la t1, ad_page
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_U_RW
  sd t1, 8(t0)
  la t1, permission_page
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_U_RA
  sd t1, 16(t0)
  la t1, remap_page_a
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_S_RWAD
  sd t1, 24(t0)
  la t1, atomic_page
  srli t1, t1, 12
  slli t1, t1, 10
  ori t1, t1, PTE_U_RWAD
  sd t1, 32(t0)
  ret

enter_user:
  la t0, u_entry
  li t2, 0xfff
  and t0, t0, t2
  li t1, U_CODE_VA
  add t0, t0, t1
  csrw sepc, t0
  li t0, SSTATUS_SPP
  csrc sstatus, t0
  sret
s_after_user:
  ret

run_timer:
  addi sp, sp, -16
  sd ra, 8(sp)
  la t0, timer_seen
  sd zero, 0(t0)
  li t0, SIE_STIE
  csrs sie, t0
  li t0, SSTATUS_SIE
  csrs sstatus, t0
  rdtime t0
  li t1, 10000
  add a0, t0, t1
  li a7, SBI_EXT_TIME
  li a6, 0
  ecall
  bnez a0, fail_timer
  li t2, 1000000
1:
  wfi
  la t0, timer_seen
  ld t1, 0(t0)
  bnez t1, 2f
  addi t2, t2, -1
  bnez t2, 1b
  j fail_timer
2:
  la t0, timer_scause
  ld t1, 0(t0)
  li t2, SCAUSE_INTERRUPT
  ori t2, t2, IRQ_STI
  bne t1, t2, fail_timer
  la a0, marker_timer
  call sbi_puts
  ld ra, 8(sp)
  addi sp, sp, 16
  ret
fail_timer:
  li a0, 30
  j l2_fail

run_mmio:
  addi sp, sp, -16
  sd ra, 8(sp)
  li t0, UART_LCR
  lbu t1, 0(t0)
  li t2, 3
  sb t2, 0(t0)
  fence iorw, iorw
  lbu t3, 0(t0)
  bne t2, t3, fail_mmio
  sb t1, 0(t0)
  fence iorw, iorw
  la a0, marker_mmio
  call sbi_puts
  ld ra, 8(sp)
  addi sp, sp, 16
  ret
fail_mmio:
  li a0, 40
  j l2_fail

run_uart_plic_irq:
  addi sp, sp, -16
  sd ra, 8(sp)
  la t0, uart_irq_seen
  sd zero, 0(t0)
  li t0, UART_IER
  sb zero, 0(t0)
  li t0, UART_IIR
  lbu t1, 0(t0)
  li t0, PLIC_PRIORITY1
  li t1, 1
  sw t1, 0(t0)
  li t0, PLIC_S_ENABLE
  li t1, 2
  sw t1, 0(t0)
  li t0, PLIC_S_THRESHOLD
  sw zero, 0(t0)
  li t0, UART_IER
  li t1, 2
  sb t1, 0(t0)
  li t0, SIE_SEIE
  csrs sie, t0
  li t0, SSTATUS_SIE
  csrs sstatus, t0
  li t2, 1000000
1:
  wfi
  la t0, uart_irq_seen
  ld t1, 0(t0)
  bnez t1, 2f
  addi t2, t2, -1
  bnez t2, 1b
  j fail_uart_irq_timeout
2:
  la t0, uart_irq_scause
  ld t1, 0(t0)
  li t2, SCAUSE_INTERRUPT
  ori t2, t2, IRQ_SEI
  bne t1, t2, fail_uart_irq_scause
  la t0, uart_irq_claim
  ld t1, 0(t0)
  li t2, 1
  bne t1, t2, fail_uart_irq_claim
  la t0, uart_irq_iir
  ld t1, 0(t0)
  andi t1, t1, 0x0f
  li t2, 2
  bne t1, t2, fail_uart_irq_iir
  la a0, marker_uart_plic
  call sbi_puts
  ld ra, 8(sp)
  addi sp, sp, 16
  ret
fail_uart_irq_timeout:
  li a0, 50
  j l2_fail
fail_uart_irq_scause:
  li a0, 51
  j l2_fail
fail_uart_irq_claim:
  li a0, 52
  j l2_fail
fail_uart_irq_iir:
  li a0, 53
  j l2_fail

s_trap:
  csrr t0, scause
  li t1, 15
  beq t0, t1, trap_store_page_fault
  li t1, 8
  beq t0, t1, trap_user_ecall
  li t1, SCAUSE_INTERRUPT
  ori t1, t1, IRQ_STI
  beq t0, t1, trap_timer
  li t1, SCAUSE_INTERRUPT
  ori t1, t1, IRQ_SEI
  beq t0, t1, trap_uart_plic
  li a0, 60
  j l2_fail

trap_store_page_fault:
  csrr t0, stval
  li t1, U_AD_VA
  beq t0, t1, trap_ad_fault
  li t1, U_PERMISSION_VA
  beq t0, t1, trap_permission_fault
  li a0, 61
  j l2_fail
trap_ad_fault:
  la t2, u_l0
  ld t3, 8(t2)
  ori t3, t3, PTE_A | PTE_D
  sd t3, 8(t2)
  sfence.vma t0, zero
  la t2, ad_fault_seen
  li t3, 1
  sd t3, 0(t2)
  sret
trap_permission_fault:
  la t2, u_l0
  ld t3, 16(t2)
  ori t3, t3, PTE_W | PTE_D
  sd t3, 16(t2)
  sfence.vma t0, zero
  la t2, permission_fault_seen
  li t3, 1
  sd t3, 0(t2)
  sret

trap_user_ecall:
  bnez a0, trap_user_fail
  la t0, user_ecall_seen
  li t1, 1
  sd t1, 0(t0)
  la t0, s_after_user
  csrw sepc, t0
  li t0, SSTATUS_SPP
  csrs sstatus, t0
  sret
trap_user_fail:
  addi a0, a0, 70
  j l2_fail

trap_timer:
  la t1, timer_scause
  sd t0, 0(t1)
  csrr t2, sepc
  la t1, timer_sepc
  sd t2, 0(t1)
  li t1, SIE_STIE
  csrc sie, t1
  la t1, timer_seen
  li t2, 1
  sd t2, 0(t1)
  sret

trap_uart_plic:
  la t1, uart_irq_scause
  sd t0, 0(t1)
  li t1, PLIC_S_CLAIM
  lw t2, 0(t1)
  la t3, uart_irq_claim
  sd t2, 0(t3)
  li t3, UART_IIR
  lbu t4, 0(t3)
  la t3, uart_irq_iir
  sd t4, 0(t3)
  li t3, UART_IER
  sb zero, 0(t3)
  fence iorw, iorw
  sw t2, 0(t1)
  li t1, SIE_SEIE
  csrc sie, t1
  la t1, uart_irq_seen
  li t2, 1
  sd t2, 0(t1)
  sret

l2_fail:
  mv s3, a0
  la a0, marker_fail_prefix
  call sbi_puts
  li t0, 10
  divu s4, s3, t0
  remu s5, s3, t0
  beqz s4, 1f
  addi a0, s4, '0'
  li a7, SBI_EXT_LEGACY_PUTCHAR
  ecall
1:
  addi a0, s5, '0'
  li a7, SBI_EXT_LEGACY_PUTCHAR
  ecall
  la a0, marker_newline
  call sbi_puts
  li a0, 1
  call sbi_shutdown
2:
  wfi
  j 2b

sbi_shutdown:
  mv a1, a0
  li a0, 0
  li a6, 0
  li a7, SBI_EXT_SRST
  ecall
  ret

  .section .user, "ax", @progbits
  .balign 4096
u_entry:
  li s2, U_AD_VA
  li s3, 0x1122334455667788
  sd s3, 0(s2)
  ld s4, 0(s2)
  bne s3, s4, u_fail_1

  li s2, U_PERMISSION_VA
  li s3, 0x8877665544332211
  sd s3, 0(s2)
  ld s4, 0(s2)
  bne s3, s4, u_fail_2

  li s2, U_ATOMIC_VA
  li s3, 5
  amoadd.d s4, s3, (s2)
  li s5, 7
  bne s4, s5, u_fail_3
  ld s4, 0(s2)
  li s5, 12
  bne s4, s5, u_fail_3
1:
  lr.d s4, (s2)
  addi s5, s4, 1
  sc.d s3, s5, (s2)
  bnez s3, 1b
  li s5, 12
  bne s4, s5, u_fail_4
  ld s4, 0(s2)
  li s5, 13
  bne s4, s5, u_fail_4
  fence rw, rw
  li a0, 0
  ecall
u_fail_1:
  li a0, 1
  ecall
u_fail_2:
  li a0, 2
  ecall
u_fail_3:
  li a0, 3
  ecall
u_fail_4:
  li a0, 4
  ecall

  .section .rodata, "a", @progbits
marker_begin:            .asciz "__RV64_L2_BEGIN__\n"
marker_opensbi:          .asciz "__RV64_L2_OPENSBI_PASS__\n"
marker_m_to_s:           .asciz "__RV64_L2_M_TO_S_PASS__\n"
marker_fdt:              .asciz "__RV64_L2_FDT_PASS__\n"
marker_case_select:      .asciz "__RV64_L2_CASE_SELECT__\n"
marker_case_privilege:   .asciz "__RV64_L2_CASE_PRIVILEGE__\n"
marker_case_sv39:        .asciz "__RV64_L2_CASE_SV39__\n"
marker_case_timer:       .asciz "__RV64_L2_CASE_TIMER__\n"
marker_case_interrupt:   .asciz "__RV64_L2_CASE_INTERRUPT__\n"
marker_case_atomic_mmio: .asciz "__RV64_L2_CASE_ATOMIC_MMIO__\n"
marker_case_shutdown:    .asciz "__RV64_L2_CASE_SHUTDOWN__\n"
marker_case_all:         .asciz "__RV64_L2_CASE_ALL__\n"
marker_sv39:             .asciz "__RV64_L2_SV39_PASS__\n"
marker_ad:               .asciz "__RV64_L2_AD_UPDATE_PASS__\n"
marker_permission:       .asciz "__RV64_L2_PERMISSION_RECOVERY_PASS__\n"
marker_s_to_u:           .asciz "__RV64_L2_S_TO_U_PASS__\n"
marker_atomic:           .asciz "__RV64_L2_AMO_LRSC_FENCE_PASS__\n"
marker_sfence:            .asciz "__RV64_L2_SFENCE_VMA_PASS__\n"
marker_timer:             .asciz "__RV64_L2_TIMER_IRQ_PASS__\n"
marker_mmio:              .asciz "__RV64_L2_MMIO_PASS__\n"
marker_uart_plic:         .asciz "__RV64_L2_PLIC_UART_IRQ_PASS__\n"
marker_powerdown:         .asciz "__RV64_L2_POWERDOWN_ARM__\n"
marker_pass:              .asciz "__RV64_L2_MINI_SYSTEM_PASS__\n"
marker_fail_prefix:       .asciz "__RV64_L2_FAIL__ code="
marker_newline:           .asciz "\n"

  .section .data, "aw", @progbits
  .balign 4096
ad_page:
  .zero 4096
  .balign 4096
permission_page:
  .zero 4096
  .balign 4096
remap_page_a:
  .dword 0x1111222233334444
  .zero 4088
  .balign 4096
remap_page_b:
  .dword 0x5555666677778888
  .zero 4088
  .balign 4096
atomic_page:
  .dword 7
  .zero 4088

  .section .bss, "aw", @nobits
  .balign 4096
l2_root:                 .zero 4096
  .balign 4096
u_l1:                    .zero 4096
  .balign 4096
u_l0:                    .zero 4096
  .balign 8
ad_fault_seen:           .dword 0
permission_fault_seen:   .dword 0
user_ecall_seen:         .dword 0
timer_seen:              .dword 0
timer_scause:            .dword 0
timer_sepc:              .dword 0
uart_irq_seen:           .dword 0
uart_irq_scause:         .dword 0
uart_irq_claim:          .dword 0
uart_irq_iir:            .dword 0

  .option pop
