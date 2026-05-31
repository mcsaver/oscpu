/* RV64 reset trampoline for OpenSBI/Linux bring-up.
 *
 * Build this file as a raw binary at NPC_RESET_PC, load firmware/kernel at
 * NEXT_ADDR, load the device tree at DTB_ADDR, then start simulation from
 * NPC_RESET_PC.  The trampoline provides the standard RISC-V boot handoff:
 *   a0 = boot hart id
 *   a1 = DTB physical address
 */

#ifndef BOOT_HARTID
#define BOOT_HARTID 0
#endif

#ifndef NEXT_ADDR
#define NEXT_ADDR 0x80200000
#endif

#ifndef DTB_ADDR
#define DTB_ADDR 0x87f00000
#endif

  .section .text.init, "ax", @progbits
  .globl _start
  .option push
  .option norvc
  .align 2
_start:
  li a0, BOOT_HARTID
  li a1, DTB_ADDR
  li t2, NEXT_ADDR
  jalr x0, 0(t2)
  .option pop
