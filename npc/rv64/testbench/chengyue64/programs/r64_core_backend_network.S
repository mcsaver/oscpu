.section .text
.globl _start
.option norelax
.option norvc
_start:
 li t0,7
 csrw mscratch,t0
 li t0,11
 csrw sscratch,t0
 li s0,0
 li s1,0
 li s2,0
.globl backend_network_begin
backend_network_begin:
 .rept 128
 csrrs t1,mscratch,zero
 csrrci t2,sscratch,0
 add s0,s0,t1
 add s1,s1,t2
 .endr
 .rept 128
 addi s2,s2,1
 .endr
 .rept 32
 mul s3,t1,t2
 div s4,t2,t1
 .endr
.globl backend_network_end
backend_network_end:
 li t0,896
 bne s0,t0,fail
 li t0,1408
 bne s1,t0,fail
 li t0,128
 bne s2,t0,fail
 li t0,77
 bne s3,t0,fail
 li t0,1
 bne s4,t0,fail
 li a0,0
 ebreak
fail:
 li a0,1
 ebreak
