#include "trap.h"

typedef int (*code_fn_t)(void);

static unsigned int code_buf[2] __attribute__((aligned(64))) = {
  0x00100513u,  // addi a0, zero, 1
  0x00008067u,  // jalr zero, 0(ra)
};

int main() {
  volatile code_fn_t fn = (code_fn_t)code_buf;

  check(fn() == 1);
  code_buf[0] = 0x00200513u;  // addi a0, zero, 2
  asm volatile("fence.i" ::: "memory");
  check(fn() == 2);

  return 0;
}
