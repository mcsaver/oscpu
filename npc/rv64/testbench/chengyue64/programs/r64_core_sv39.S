.section .text
.globl _start
.option norelax
_start:
 la sp, data
 la t0, handler
 csrw mtvec,t0
 csrw mscratch,zero
 li t0,-1
 csrw pmpaddr0,t0
 li t0,0x1f
 csrw pmpcfg0,t0
 la s0,root_table
 li t0,0x2000000f
 sd t0,16(s0)
 srli t0,s0,12
 li t1,0x8000000000000000
 or t0,t0,t1
 csrw satp,t0
 sfence.vma
 la t0,supervisor
 csrw mepc,t0
 li t0,0x1800
 csrc mstatus,t0
 li t0,0x800
 csrs mstatus,t0
 mret
supervisor:
 li s1,17
 sd s1,0(sp)
 ld s2,0(sp)
 lr.d s3,(sp)
 addi s3,s3,1
 sc.d s4,s3,(sp)
 li t0,4
 amoadd.d s5,t0,(sp)
 sfence.vma
 ld s6,0(sp)
 // Force page-table A/D clear through the same cache as the I and D walkers.
 li t0,0x2000000f
 sd t0,16(s0)
 sfence.vma
 ld s7,0(sp)
 ecall
 ld s8,16(s0)
 andi s8,s8,0x40
 addi a0,s8,-64
 ebreak
.balign 4
handler:
 csrr t3,mcause
 li t4,9
 bne t3,t4,fail
 csrr t3,mepc
 addi t3,t3,4
 csrw mepc,t3
 mret
fail:
 li a0,1
 ebreak
.section .data
.balign 64
data: .zero 64
.balign 4096
root_table: .zero 4096
