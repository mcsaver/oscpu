
.section .text
.globl _start
.option norelax
_start:
 la sp,buffer
 la t0,handler
 csrw mtvec,t0
 li t0,-1
 csrw pmpaddr0,t0
 li t0,0x1f
 csrw pmpcfg0,t0
 // Identity map the first 2 MiB through real three-level, 4 KiB tables.
 la s0,root_table
 la t0,level1
 srli t0,t0,12
 slli t0,t0,10
 ori t0,t0,1
 sd t0,16(s0)
 la t0,level0
 srli t0,t0,12
 slli t0,t0,10
 ori t0,t0,1
 la t1,level1
 sd t0,0(t1)
 la t1,level0
 li t0,0x2000000f
 li t2,512
1:
 sd t0,0(t1)
 addi t0,t0,1024
 addi t1,t1,8
 addi t2,t2,-1
 bnez t2,1b
 la t1,buffer
 li t2,1
 li t3,65
 li t4,4096
2:
 sd t2,0(t1)
 sd t2,8(t1)
 add t1,t1,t4
 addi t2,t2,1
 bne t2,t3,2b
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
 li s3,4
 li s4,0
 li s5,8192
.globl contention_begin
contention_begin:
 sfence.vma
 la s1,buffer
 li t0,4104
 add s2,s1,t0
 li s6,32
3:
 // Independent data loads drive both data walkers and opposite data banks;
 // instruction misses and A/D updates also use the shared physical service.
 ld t1,0(s1)
 ld t2,0(s2)
 add s4,s4,t1
 add s4,s4,t2
 sd t1,0(s1)
 add s1,s1,s5
 add s2,s2,s5
 addi s6,s6,-1
 bnez s6,3b
 addi s3,s3,-1
 bnez s3,contention_begin
.globl contention_end
contention_end:
 li t0,8320
 bne s4,t0,fail
 ecall
 li a0,0
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
.balign 4096
root_table: .zero 4096
level1: .zero 4096
level0: .zero 4096
buffer: .zero 262144
