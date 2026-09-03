#include "trap.h"

#if defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)

#define SYSCON_RESET_CONTROL ((uintptr_t)0x00100000u)

static inline uint32_t syscon_read_control(void) {
  return *(volatile uint32_t *)SYSCON_RESET_CONTROL;
}

static inline void syscon_write_control(uint32_t value) {
  *(volatile uint32_t *)SYSCON_RESET_CONTROL = value;
}

static void check_or_halt(bool condition, int error_code) {
  if (!condition) halt(error_code);
}

int main(void) {
  /*
   * A syscon reset endpoint is a 32-bit read/write register map.  OpenSBI's
   * syscon-poweroff and syscon-reboot drivers implement the device-tree
   * mask/value binding with this exact read-modify-write sequence.
   */
  check_or_halt(syscon_read_control() == 0, 2);

  syscon_write_control(UINT32_C(0xa5a50000));
  const uint32_t current = syscon_read_control();
  const uint32_t mask = UINT32_C(0x0000ffff);
  const uint32_t value = UINT32_C(0x00001234);
  syscon_write_control((current & ~mask) | (value & mask));

  check_or_halt(syscon_read_control() == UINT32_C(0xa5a51234), 3);

  /* AM halt(0) performs the terminal 0x5555 write after the RMW check. */
  halt(0);
  return 0;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif
