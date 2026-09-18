.section .text
.globl _start
.option norelax
_start:
 la sp, data
 la t0, handler
 csrw mtvec,t0
 csrw mscratch,zero
 li t0, -12345
 li t1, 789
 mul s0,t0,t1
 mulh s1,t0,t1
 div s2,t0,t1
 rem s3,t0,t1
 divu s4,t0,zero
 divw s5,t0,t1
 remw s6,t0,t1
 sd s0,0(sp)
 sd s1,8(sp)
 ld a0,0(sp)
 ld a1,8(sp)
 sb t1,3(sp)
 lbu a2,3(sp)
 lw a3,0(sp)
 lr.d a4,(sp)
 sc.d a5,t1,(sp)
 lr.d a6,(sp)
 addi a6,a6,3
 sc.d a7,a6,(sp)
 amoadd.d s7,t1,(sp)
 amomax.w s8,t0,(sp)
 li t0,0x6000
 csrs mstatus,t0
 li t0,0x3ff8000000000000
 fmv.d.x f0,t0
 li t1,0x4004000000000000
 fmv.d.x f1,t1
 fadd.d f2,f0,f1
 fmul.d f3,f2,f1
 fdiv.d f4,f3,f0
 fsqrt.d f5,f2
 fmadd.d f6,f0,f1,f2
 fcvt.l.d s9,f3,rtz
 fsd f6,16(sp)
 fld f7,16(sp)
 fmv.x.d s10,f7
 li t0,20
1:
 addi t0,t0,-1
 addi s11,s11,1
 bnez t0,1b
 ecall
 .word 0x02000073
 csrr a0,mscratch
 addi a0,a0,-2
 ebreak
.balign 4
handler:
 csrr t3,mscratch
 addi t3,t3,1
 csrw mscratch,t3
 csrr t4,mepc
 addi t4,t4,4
 csrw mepc,t4
 mret
.section .data
.balign 64
data:
 .zero 64
