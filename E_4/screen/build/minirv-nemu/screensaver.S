#include "/home/lyg/PA/ysyx-workbench/abstract-machine/tools/minirv/inst-replace.h"
	.file	"screensaver.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.draw,"ax",@progbits
	.align	2
	.globl	draw
	.hidden	draw
	.type	draw, @function
draw:
.LFB3:
	.cfi_startproc
	addi	sp,sp,-64
	.cfi_def_cfa_offset 64
	sw	s1,52(sp)
	.cfi_offset 9, -12
	lla	s1,row_buf
	sw	ra,60(sp)
	sw	s0,56(sp)
	sw	s2,48(sp)
	sw	s3,44(sp)
	sw	s4,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	.cfi_offset 18, -16
	.cfi_offset 19, -20
	.cfi_offset 20, -24
	mv	a5,s1
	lla	a4,row_buf+1600
.L2:
	sw	a0,0(a5)
	addi	a5,a5,4
	bne	a5,a4,.L2
	li	s0,0
	li	s4,400
	li	s2,1
	li	s3,300
.L3:
	sw	s0,12(sp)
	addi	a1,sp,8
	li	a0,11
	addi	s0,s0,1
	sw	zero,8(sp)
	sw	s1,16(sp)
	sw	s4,20(sp)
	sw	s2,24(sp)
	sb	zero,28(sp)
	call	ioe_write
	bne	s0,s3,.L3
	addi	a1,sp,8
	li	a0,11
	sb	s2,28(sp)
	sw	zero,8(sp)
	sw	zero,12(sp)
	sw	zero,16(sp)
	sw	zero,20(sp)
	sw	zero,24(sp)
	call	ioe_write
	lw	ra,60(sp)
	.cfi_restore 1
	lw	s0,56(sp)
	.cfi_restore 8
	lw	s1,52(sp)
	.cfi_restore 9
	lw	s2,48(sp)
	.cfi_restore 18
	lw	s3,44(sp)
	.cfi_restore 19
	lw	s4,40(sp)
	.cfi_restore 20
	addi	sp,sp,64
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE3:
	.size	draw, .-draw
	.globl	__udivdi3
	.globl	__divsi3
	.section	.text.startup.main,"ax",@progbits
	.align	2
	.globl	main
	.hidden	main
	.type	main, @function
main:
.LFB5:
	.cfi_startproc
	addi	sp,sp,-96
	.cfi_def_cfa_offset 96
	sw	ra,92(sp)
	sw	s0,88(sp)
	sw	s1,84(sp)
	sw	s2,80(sp)
	sw	s3,76(sp)
	sw	s4,72(sp)
	sw	s5,68(sp)
	sw	s6,64(sp)
	sw	s7,60(sp)
	sw	s8,56(sp)
	sw	s9,52(sp)
	sw	s10,48(sp)
	sw	s11,44(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	.cfi_offset 9, -12
	.cfi_offset 18, -16
	.cfi_offset 19, -20
	.cfi_offset 20, -24
	.cfi_offset 21, -28
	.cfi_offset 22, -32
	.cfi_offset 23, -36
	.cfi_offset 24, -40
	.cfi_offset 25, -44
	.cfi_offset 26, -48
	.cfi_offset 27, -52
	call	ioe_init
	addi	a1,sp,24
	li	a0,6
	call	ioe_read
	lw	a0,24(sp)
	lw	a1,28(sp)
	li	a2,1000
	li	a3,0
	call	__udivdi3
	bne	a0,zero,.L9
	li	a0,1
.L9:
	slli	a5,a0,8
	sub	a5,a5,a0
	slli	a5,a5,3
	add	a5,a5,a0
	slli	a5,a5,7
	add	a5,a5,a0
	slli	a5,a5,3
	sub	a5,a5,a0
	slli	a4,a5,5
	add	a5,a5,a4
	slli	a5,a5,2
	sub	a5,a5,a0
	slli	a5,a5,2
	li	a4,12288
	addi	a4,a4,57
	add	a5,a5,a0
	add	a5,a5,a4
	srli	s0,a5,16
	andi	s0,s0,7
	sw	a4,8(sp)
	lla	a3,COLORS
	slli	a4,s0,2
	add	a4,a3,a4
	lw	s7,0(a4)
	lla	a4,rng_state
	sw	a5,0(a4)
	mv	a0,s7
	call	draw
	li	s2,50
.L18:
	lla	a5,rng_state
	lw	a4,0(a5)
.L10:
	slli	a5,a4,8
	sub	a5,a5,a4
	slli	a5,a5,3
	add	a5,a5,a4
	slli	a5,a5,7
	add	a5,a5,a4
	slli	a5,a5,3
	sub	a5,a5,a4
	slli	a3,a5,5
	add	a5,a5,a3
	slli	a5,a5,2
	sub	a5,a5,a4
	slli	a5,a5,2
	add	a5,a5,a4
	lw	a4,8(sp)
	add	a4,a5,a4
	srli	a5,a4,16
	andi	a5,a5,7
	sw	a5,4(sp)
	beq	s0,a5,.L10
	lla	a3,COLORS
	slli	a5,a5,2
	add	a5,a3,a5
	lw	a2,0(a5)
	srli	s10,s7,16
	srli	s9,s7,8
	srli	a3,a2,16
	srli	a5,a2,8
	andi	a5,a5,255
	andi	s10,s10,255
	andi	s9,s9,255
	andi	s7,s7,255
	andi	a3,a3,255
	andi	s11,a2,255
	sub	s8,a5,s9
	sub	s3,a3,s10
	sub	s11,s11,s7
	lla	a5,rng_state
	sw	a2,12(sp)
	sw	s3,0(sp)
	sw	a4,0(a5)
	mv	s5,s11
	mv	s4,s8
	li	s6,100
.L17:
	li	a1,100
	mv	a0,s3
	call	__divsi3
	add	s0,a0,s10
	li	a1,100
	mv	a0,s4
	call	__divsi3
	add	a5,a0,s9
	slli	a5,a5,8
	li	a1,100
	slli	s0,s0,16
	mv	a0,s5
	or	s0,s0,a5
	call	__divsi3
	add	a5,a0,s7
	addi	a1,sp,24
	li	a0,8
	or	s0,s0,a5
	call	ioe_read
	lbu	a5,24(sp)
	beq	a5,zero,.L11
	lw	a5,28(sp)
	li	a4,1
	beq	a5,a4,.L24
	li	a5,5
	bgt	s2,a5,.L26
	li	a5,5
	li	s1,5
	beq	s2,a5,.L14
.L27:
	addi	s2,s2,1
	mv	s1,s2
.L14:
	addi	a1,sp,16
	li	a0,6
	call	ioe_read
	lw	a0,16(sp)
	lw	a1,20(sp)
	li	a2,1000
	li	a3,0
	call	__udivdi3
	mv	a5,a0
	mv	a0,s0
	mv	s0,a5
	call	draw
.L16:
	addi	a1,sp,16
	li	a0,6
	call	ioe_read
	lw	a0,16(sp)
	lw	a1,20(sp)
	li	a2,1000
	li	a3,0
	call	__udivdi3
	sub	a0,a0,s0
	bltu	a0,s1,.L16
	lw	a5,0(sp)
	addi	s6,s6,-1
	add	s4,s4,s8
	add	s3,s3,a5
	add	s5,s5,s11
	bne	s6,zero,.L17
	lw	s7,12(sp)
	lw	s0,4(sp)
	j	.L18
.L11:
	li	a5,50
	bgt	s2,a5,.L26
	li	a5,50
	li	s1,50
	beq	s2,a5,.L14
	j	.L27
.L26:
	addi	s2,s2,-1
	mv	s1,s2
	j	.L14
.L24:
	lw	ra,92(sp)
	.cfi_restore 1
	lw	s0,88(sp)
	.cfi_restore 8
	lw	s1,84(sp)
	.cfi_restore 9
	lw	s2,80(sp)
	.cfi_restore 18
	lw	s3,76(sp)
	.cfi_restore 19
	lw	s4,72(sp)
	.cfi_restore 20
	lw	s5,68(sp)
	.cfi_restore 21
	lw	s6,64(sp)
	.cfi_restore 22
	lw	s7,60(sp)
	.cfi_restore 23
	lw	s8,56(sp)
	.cfi_restore 24
	lw	s9,52(sp)
	.cfi_restore 25
	lw	s10,48(sp)
	.cfi_restore 26
	lw	s11,44(sp)
	.cfi_restore 27
	li	a0,0
	addi	sp,sp,96
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE5:
	.size	main, .-main
	.section	.sdata.rng_state,"aw"
	.align	2
	.type	rng_state, @object
	.size	rng_state, 4
rng_state:
	.word	1
	.section	.bss.row_buf,"aw",@nobits
	.align	2
	.type	row_buf, @object
	.size	row_buf, 1600
row_buf:
	.zero	1600
	.section	.rodata.COLORS,"a"
	.align	2
	.type	COLORS, @object
	.size	COLORS, 32
COLORS:
	.word	0
	.word	16711680
	.word	65280
	.word	255
	.word	16776960
	.word	16711935
	.word	65535
	.word	16777215
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
