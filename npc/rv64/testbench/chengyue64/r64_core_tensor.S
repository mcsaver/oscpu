.section .text
.globl _start
.option norvc
_start:
 li s1, 0x80010000
 li s2, 0x80011000
 li s3, 0x80012000
 li t0, 0x3f800000
 li t1, 0x40000000
 li t2, 0xdeadbeef
 li t3, 16
init:
 sw t0, 0(s1)
 sw t1, 0(s2)
 sw t2, 0(s3)
 lw t4, 0(s3)
 addi s1, s1, 4
 addi s2, s2, 4
 addi s3, s3, 4
 addi t3, t3, -1
 bnez t3, init
 la s0, descriptor
 ld t0, 0(s0)
 .word 0xa02cfdb
 ld t0, 8(s0)
 .word 0xa12cfdb
 ld t0, 16(s0)
 .word 0xa22cfdb
 ld t0, 24(s0)
 .word 0xa32cfdb
 ld t0, 32(s0)
 .word 0xa42cfdb
 ld t0, 40(s0)
 .word 0xa52cfdb
 ld t0, 48(s0)
 .word 0xa62cfdb
 ld t0, 56(s0)
 .word 0xa72cfdb
 ld t0, 64(s0)
 .word 0xa82cfdb
 ld t0, 72(s0)
 .word 0xa92cfdb
 ld t0, 80(s0)
 .word 0xaa2cfdb
 ld t0, 88(s0)
 .word 0xab2cfdb
 ld t0, 96(s0)
 .word 0xac2cfdb
 ld t0, 104(s0)
 .word 0xad2cfdb
 ld t0, 112(s0)
 .word 0xae2cfdb
 ld t0, 120(s0)
 .word 0xaf2cfdb
 ld t0, 128(s0)
 .word 0xb02cfdb
 ld t0, 136(s0)
 .word 0xb12cfdb
 ld t0, 144(s0)
 .word 0xb22cfdb
 ld t0, 152(s0)
 .word 0xb32cfdb
 ld t0, 160(s0)
 .word 0xb42cfdb
 ld t0, 168(s0)
 .word 0xb52cfdb
 ld t0, 176(s0)
 .word 0xb62cfdb
 ld t0, 184(s0)
 .word 0xb72cfdb
 ld t0, 192(s0)
 .word 0xb82cfdb
 ld t0, 200(s0)
 .word 0xb92cfdb
 ld t0, 208(s0)
 .word 0xba2cfdb
 ld t0, 216(s0)
 .word 0xbb2cfdb
 ld t0, 224(s0)
 .word 0xbc2cfdb
 ld t0, 232(s0)
 .word 0xbd2cfdb
 .word 0x0220305b
 .word 0x0bf0305b
 li s3, 0x80012000
 li t0, 0x40400000
 li t3, 16
verify:
 lw t1, 0(s3)
 bne t1, t0, failed
 addi s3, s3, 4
 addi t3, t3, -1
 bnez t3, verify
 li a0, 0
 ebreak
failed:
 li a0, 1
 ebreak
.balign 8
descriptor:
 .dword 0x11514e0010
 .dword 0x143414e01
 .dword 0x100000003
 .dword 0x8877665544332211
 .dword 0xfa091823bada0765
 .dword 0x100000001
 .dword 0x1122334455667788
 .dword 0x99aabbccddeeff00
 .dword 0x0
 .dword 0x100000000
 .dword 0x80010000
 .dword 0x80011000
 .dword 0x0
 .dword 0x80012000
 .dword 0x0
 .dword 0x10
 .dword 0x1
 .dword 0x0
 .dword 0x0
 .dword 0x40
 .dword 0x40
 .dword 0x0
 .dword 0x40
 .dword 0x80010000
 .dword 0x40
 .dword 0x97
 .dword 0x80011000
 .dword 0x40
 .dword 0x80012000
 .dword 0x40
