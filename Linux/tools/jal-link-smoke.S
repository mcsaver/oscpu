// Focused RV64 control-flow smoke for JAL/JALR link-address semantics.
// Linux/OpenSBI depends on rd receiving pc+4, not the branch target.

#ifndef JAL_LINK_STACK
#define JAL_LINK_STACK 0x87ef9000
#endif

  .section .text, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li sp, JAL_LINK_STACK

  auipc t0, 0
  addi t0, t0, 12
  jal ra, jal_target
after_jal:
  la t2, jalr_target
  auipc t0, 0
  addi t0, t0, 12
  jalr ra, 0(t2)
after_jalr:
  li a0, 0
  ebreak

jal_target:
  bne ra, t0, fail_jal_link
  j after_jal

jalr_target:
  bne ra, t0, fail_jalr_link
  j after_jalr

fail_jal_link:
  li a0, 1
  ebreak

fail_jalr_link:
  li a0, 2
  ebreak

  .option pop
