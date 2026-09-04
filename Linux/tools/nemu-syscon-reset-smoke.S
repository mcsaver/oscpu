#ifndef SYSCON_VALUE
#error "compile with -DSYSCON_VALUE=<poweroff-or-reboot-value>"
#endif

#ifndef SYSCON_ADDRESS
#define SYSCON_ADDRESS 0x00100000
#endif

  .option norvc
  .section .text.init, "ax", @progbits
  .globl _start
  .type _start, @function
_start:
  li t0, SYSCON_ADDRESS
  li t1, SYSCON_VALUE
  sw t1, 0(t0)
  fence iorw, iorw
1:
  wfi
  j 1b
  .size _start, .-_start
