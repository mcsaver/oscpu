#include "trap.h"

#if defined(__riscv) && (__riscv_xlen == 32 || __riscv_xlen == 64) && \
    defined(__riscv_compressed)

#if __riscv_xlen == 64
#define C_XLEN_LOAD  "ld"
#define C_XLEN_STORE "sd"
#else
#define C_XLEN_LOAD  "lw"
#define C_XLEN_STORE "sw"
#endif

#define MSTATUS_FS_MASK  ((uintptr_t)3 << 13)
#define MSTATUS_FS_DIRTY ((uintptr_t)3 << 13)

static volatile uintptr_t c_trap_count;
static volatile uintptr_t c_trap_cause;
static volatile uintptr_t c_trap_tval;

extern void c_manual_trap(void);
extern void c_manual_lui_x0_hint(void);

#if defined(__riscv_flen) && __riscv_flen >= 64
extern void c_manual_fldsp_f0(const uint64_t *source, uint64_t *result);
#endif

#if __riscv_xlen == 32 && defined(__riscv_flen) && __riscv_flen >= 32
extern uint32_t c_manual_flw_fsw(uint32_t value);
extern uint32_t c_manual_flwsp_fswsp(uint32_t value);
#endif

/*
 * Every instruction under test is emitted as its architectural 16-bit
 * encoding.  The compiler therefore cannot replace it with an uncompressed
 * equivalent or choose a different FPR.
 */
asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl c_manual_trap\n"
"c_manual_trap:\n"
"  csrr t0, mcause\n"
"  la t1, c_trap_cause\n"
"  " C_XLEN_STORE " t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, c_trap_tval\n"
"  " C_XLEN_STORE " t0, 0(t1)\n"
"  la t1, c_trap_count\n"
"  " C_XLEN_LOAD " t0, 0(t1)\n"
"  addi t0, t0, 1\n"
"  " C_XLEN_STORE " t0, 0(t1)\n"
/* All deliberately exposed C encodings below are exactly two bytes. */
"  csrr t0, mepc\n"
"  addi t0, t0, 2\n"
"  csrw mepc, t0\n"
"  mret\n"
"\n"
".balign 4\n"
".globl c_manual_lui_x0_hint\n"
"c_manual_lui_x0_hint:\n"
/* C.LUI x0,1 is a HINT, not an illegal instruction. */
"  .2byte 0x6005\n"
"  ret\n"
".option pop\n"
);

#if defined(__riscv_flen) && __riscv_flen >= 64
asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl c_manual_fldsp_f0\n"
"c_manual_fldsp_f0:\n"
"  addi sp, sp, -16\n"
/* Put the caller's datum at 0(sp), then require C.FLDSP to name f0. */
"  fld f1, 0(a0)\n"
"  fsd f1, 0(sp)\n"
"  fld f0, 0(a1)\n"
"  .2byte 0x2002\n"       /* c.fldsp f0, 0(sp) */
"  fsd f0, 0(a1)\n"
"  addi sp, sp, 16\n"
"  ret\n"
".option pop\n"
);
#endif

#if __riscv_xlen == 32 && defined(__riscv_flen) && __riscv_flen >= 32
asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl c_manual_flw_fsw\n"
"c_manual_flw_fsw:\n"
"  addi sp, sp, -16\n"
"  sw s0, 12(sp)\n"
"  sw a0, 0(sp)\n"
"  mv s0, sp\n"
"  .2byte 0x6000\n"       /* c.flw f8, 0(s0) */
"  sw zero, 4(sp)\n"
"  addi s0, sp, 4\n"
"  .2byte 0xe000\n"       /* c.fsw f8, 0(s0) */
"  lw a0, 4(sp)\n"
"  lw s0, 12(sp)\n"
"  addi sp, sp, 16\n"
"  ret\n"
"\n"
".balign 4\n"
".globl c_manual_flwsp_fswsp\n"
"c_manual_flwsp_fswsp:\n"
"  addi sp, sp, -16\n"
"  sw a0, 0(sp)\n"
"  .2byte 0x6482\n"       /* c.flwsp f9, 0(sp) */
"  sw zero, 0(sp)\n"
"  .2byte 0xe026\n"       /* c.fswsp f9, 0(sp) */
"  lw a0, 0(sp)\n"
"  addi sp, sp, 16\n"
"  ret\n"
".option pop\n"
);
#endif

static inline uintptr_t c_read_mstatus(void) {
  uintptr_t value;
  asm volatile("csrr %0, mstatus" : "=r"(value));
  return value;
}

static inline void c_write_mstatus(uintptr_t value) {
  asm volatile("csrw mstatus, %0" : : "r"(value) : "memory");
}

static void c_clear_trap(void) {
  c_trap_count = 0;
  c_trap_cause = 0;
  c_trap_tval = 0;
}

static void c_require(bool condition, int code) {
  if (!condition) {
    printf("riscv-c-manual failure %d: traps=%lu cause=%lu tval=0x%lx\n",
        code, (unsigned long)c_trap_count,
        (unsigned long)c_trap_cause, (unsigned long)c_trap_tval);
    halt(code);
  }
}

int main(void) {
  const uintptr_t old_mstatus = c_read_mstatus();
  asm volatile("csrw mtvec, %0" : : "r"(c_manual_trap) : "memory");

  c_clear_trap();
  c_manual_lui_x0_hint();
  c_require(c_trap_count == 0, 1);

#if defined(__riscv_flen) && __riscv_flen >= 32
  c_write_mstatus((old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY);
#endif

#if defined(__riscv_flen) && __riscv_flen >= 64
  const uint64_t input = UINT64_C(0x0123456789abcdef);
  uint64_t result = ~input;
  c_clear_trap();
  c_manual_fldsp_f0(&input, &result);
  c_require(c_trap_count == 0, 2);
  c_require(result == input, 3);
#endif

#if __riscv_xlen == 32 && defined(__riscv_flen) && __riscv_flen >= 32
  const uint32_t single = UINT32_C(0x7fa12345);
  c_clear_trap();
  c_require(c_manual_flw_fsw(single) == single, 4);
  c_require(c_trap_count == 0, 5);

  c_clear_trap();
  c_require(c_manual_flwsp_fswsp(single) == single, 6);
  c_require(c_trap_count == 0, 7);
#endif

  c_write_mstatus(old_mstatus);
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
