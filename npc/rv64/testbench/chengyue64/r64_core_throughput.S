# Full-core ideal throughput: independent integer writes, a resident 4 KiB
# instruction body, and eight natural loop iterations. The first iteration
# warms the real I-cache through AXI. No forced cache state or reference bypass.
.section .text
.globl _start, hot_body, hot_end
.option norelax
.option norvc
_start:
 li x31, 8
 .balign 64
hot_body:
 .rept 64
 addi x12, x0, 12
 addi x13, x0, 13
 addi x14, x0, 14
 addi x15, x0, 15
 addi x16, x0, 16
 addi x17, x0, 17
 addi x18, x0, 18
 addi x19, x0, 19
 addi x20, x0, 20
 addi x21, x0, 21
 addi x22, x0, 22
 addi x23, x0, 23
 addi x24, x0, 24
 addi x25, x0, 25
 addi x26, x0, 26
 addi x27, x0, 27
 .endr
hot_end:
 addi x31, x31, -1
 bnez x31, hot_body
 li a0, 0
 ebreak
