#include "trap.h"

#if defined(__riscv) && (__riscv_xlen == 32 || __riscv_xlen == 64) && \
    defined(__riscv_flen) && __riscv_flen >= 32

#if __riscv_xlen == 64
#define FD_XLEN_LOAD  "ld"
#define FD_XLEN_STORE "sd"
#else
#define FD_XLEN_LOAD  "lw"
#define FD_XLEN_STORE "sw"
#endif

#define EXC_ILLEGAL_INSTRUCTION ((uintptr_t)2)
#define MSTATUS_FS_MASK          ((uintptr_t)3 << 13)
#define MSTATUS_FS_CLEAN         ((uintptr_t)2 << 13)
#define MSTATUS_FS_DIRTY         ((uintptr_t)3 << 13)
#define FFLAGS_DZ                ((uintptr_t)1 << 3)

enum {
  FD_FAIL_FS_OFF = 1u << 0,
  FD_FAIL_DYNAMIC_RM_LEGAL = 1u << 1,
  FD_FAIL_DYNAMIC_RM_RESERVED = 1u << 2,
  FD_FAIL_FFLAGS = 1u << 3,
  FD_FAIL_FS_DIRTY = 1u << 4,
  FD_FAIL_SINGLE_FLEN = 1u << 5,
  FD_FAIL_NAN_BOX = 1u << 6,
  FD_FAIL_RAW_MOVE = 1u << 7,
  FD_FAIL_RAW_STORE = 1u << 8,
  FD_FAIL_FCVT_WU = 1u << 9,
};

static volatile uintptr_t fd_trap_count;
static volatile uintptr_t fd_trap_cause;
static volatile uintptr_t fd_trap_tval;

extern void fd_manual_trap(void);
extern void fd_fs_off_instruction(void);
extern uint32_t fd_dynamic_add(uint32_t a, uint32_t b);
extern uint32_t fd_divide_by_zero(uint32_t a, uint32_t b);
extern uint32_t fd_single_identity(uint32_t value);

#if __riscv_flen >= 64
extern void fd_malformed_nan_box(const uint64_t *source, uint64_t *result);
extern uint32_t fd_malformed_raw(
    const uint64_t *source, uint32_t *stored_value);
#endif

#if __riscv_xlen == 64
extern uintptr_t fd_fcvt_wu(uint32_t value);
#endif

asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl fd_manual_trap\n"
"fd_manual_trap:\n"
"  csrr t0, mcause\n"
"  la t1, fd_trap_cause\n"
"  " FD_XLEN_STORE " t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, fd_trap_tval\n"
"  " FD_XLEN_STORE " t0, 0(t1)\n"
"  la t1, fd_trap_count\n"
"  " FD_XLEN_LOAD " t0, 0(t1)\n"
"  addi t0, t0, 1\n"
"  " FD_XLEN_STORE " t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
"\n"
".balign 4\n"
".globl fd_fs_off_instruction\n"
"fd_fs_off_instruction:\n"
"  .word 0x00000053\n"       /* fadd.s f0, f0, f0, rne */
"  ret\n"
"\n"
".balign 4\n"
".globl fd_dynamic_add\n"
"fd_dynamic_add:\n"
"  fmv.w.x f0, a0\n"
"  fmv.w.x f1, a1\n"
"  .word 0x00107153\n"       /* fadd.s f2, f0, f1, dyn */
"  fmv.x.w a0, f2\n"
"  ret\n"
"\n"
".balign 4\n"
".globl fd_divide_by_zero\n"
"fd_divide_by_zero:\n"
"  fmv.w.x f0, a0\n"
"  fmv.w.x f1, a1\n"
"  .word 0x18100153\n"       /* fdiv.s f2, f0, f1, rne */
"  fmv.x.w a0, f2\n"
"  ret\n"
"\n"
".balign 4\n"
".globl fd_single_identity\n"
"fd_single_identity:\n"
"  fmv.w.x f0, a0\n"
"  .word 0x200000d3\n"       /* fsgnj.s f1, f0, f0 */
"  fmv.x.w a0, f1\n"
"  ret\n"
".option pop\n"
);

#if __riscv_flen >= 64
asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl fd_malformed_nan_box\n"
"fd_malformed_nan_box:\n"
"  fld f0, 0(a0)\n"
"  .word 0x200000d3\n"       /* fsgnj.s f1, f0, f0 */
"  fsd f1, 0(a1)\n"
"  ret\n"
"\n"
".balign 4\n"
".globl fd_malformed_raw\n"
"fd_malformed_raw:\n"
"  fld f0, 0(a0)\n"
"  fmv.x.w a0, f0\n"        /* raw low 32 bits: no NaN-box check */
"  fsw f0, 0(a1)\n"         /* raw low 32 bits: no NaN-box check */
"  ret\n"
".option pop\n"
);
#endif

#if __riscv_xlen == 64
asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl fd_fcvt_wu\n"
"fd_fcvt_wu:\n"
"  fmv.w.x f0, a0\n"
"  .word 0xc0101553\n"       /* fcvt.wu.s a0, f0, rtz */
"  ret\n"
".option pop\n"
);
#endif

#define FD_CSR_READ(name, output) \
  asm volatile("csrr %0, " #name : "=r"(output))
#define FD_CSR_WRITE(name, value) \
  asm volatile("csrw " #name ", %0" : : "r"((uintptr_t)(value)) : "memory")

static void fd_clear_trap(void) {
  fd_trap_count = 0;
  fd_trap_cause = 0;
  fd_trap_tval = 0;
}

static bool fd_trapped_on(uint32_t encoding) {
  return fd_trap_count == 1 &&
         fd_trap_cause == EXC_ILLEGAL_INSTRUCTION &&
         fd_trap_tval == (uintptr_t)encoding;
}

int main(void) {
  uintptr_t fail = 0;
  uintptr_t old_mstatus;
  uintptr_t old_fcsr;
  uintptr_t value;

  FD_CSR_READ(mstatus, old_mstatus);
  FD_CSR_WRITE(mstatus,
      (old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY);
  FD_CSR_READ(fcsr, old_fcsr);
  FD_CSR_WRITE(mtvec, fd_manual_trap);

  /* FS=Off makes every F/D instruction illegal before any FPR side effect. */
  FD_CSR_WRITE(mstatus, old_mstatus & ~MSTATUS_FS_MASK);
  fd_clear_trap();
  fd_fs_off_instruction();
  if (!fd_trapped_on(UINT32_C(0x00000053))) fail |= FD_FAIL_FS_OFF;

  /* rm=dynamic resolves through frm; 0 is legal, 5 and 6 are reserved. */
  FD_CSR_WRITE(mstatus,
      (old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_CLEAN);
  FD_CSR_WRITE(frm, 0);
  fd_clear_trap();
  if (fd_dynamic_add(UINT32_C(0x3f800000), UINT32_C(0x40000000)) !=
          UINT32_C(0x40400000) ||
      fd_trap_count != 0) {
    fail |= FD_FAIL_DYNAMIC_RM_LEGAL;
  }

  FD_CSR_WRITE(frm, 5);
  fd_clear_trap();
  (void)fd_dynamic_add(UINT32_C(0x3f800000), UINT32_C(0x40000000));
  if (!fd_trapped_on(UINT32_C(0x00107153))) {
    fail |= FD_FAIL_DYNAMIC_RM_RESERVED;
  }

  FD_CSR_WRITE(frm, 6);
  fd_clear_trap();
  (void)fd_dynamic_add(UINT32_C(0x3f800000), UINT32_C(0x40000000));
  if (!fd_trapped_on(UINT32_C(0x00107153))) {
    fail |= FD_FAIL_DYNAMIC_RM_RESERVED;
  }

  /* Divide-by-zero sets DZ and makes the architectural FP state Dirty. */
  FD_CSR_WRITE(mstatus,
      (old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY);
  FD_CSR_WRITE(fflags, 0);
  FD_CSR_WRITE(frm, 0);
  FD_CSR_WRITE(mstatus,
      (old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_CLEAN);
  fd_clear_trap();
  if (fd_divide_by_zero(
          UINT32_C(0x3f800000), UINT32_C(0x00000000)) !=
          UINT32_C(0x7f800000) ||
      fd_trap_count != 0) {
    fail |= FD_FAIL_FFLAGS;
  }
  FD_CSR_READ(fflags, value);
  if ((value & FFLAGS_DZ) == 0) fail |= FD_FAIL_FFLAGS;
  FD_CSR_READ(mstatus, value);
  if ((value & MSTATUS_FS_MASK) != MSTATUS_FS_DIRTY) {
    fail |= FD_FAIL_FS_DIRTY;
  }

  /* This must work with FLEN=32 too: absent upper bits are not a bad box. */
  fd_clear_trap();
  if (fd_single_identity(UINT32_C(0x3f800000)) != UINT32_C(0x3f800000) ||
      fd_trap_count != 0) {
    fail |= FD_FAIL_SINGLE_FLEN;
  }

#if __riscv_flen >= 64
  /* A malformed FLEN=64 box is canonical NaN for arithmetic consumers. */
  const uint64_t malformed = UINT64_C(0x000000003f800000);
  uint64_t boxed_result = 0;
  fd_malformed_nan_box(&malformed, &boxed_result);
  if (boxed_result != UINT64_C(0xffffffff7fc00000)) {
    fail |= FD_FAIL_NAN_BOX;
  }

  /* FMV.X.W and FSW are raw-bit exceptions to NaN-box consumption. */
  uint32_t stored_value = 0;
  if (fd_malformed_raw(&malformed, &stored_value) !=
      UINT32_C(0x3f800000)) {
    fail |= FD_FAIL_RAW_MOVE;
  }
  if (stored_value != UINT32_C(0x3f800000)) {
    fail |= FD_FAIL_RAW_STORE;
  }
#endif

#if __riscv_xlen == 64
  /* All W/WU conversions sign-extend their 32-bit result to XLEN. */
  if (fd_fcvt_wu(UINT32_C(0x4f000000)) !=
      UINT64_C(0xffffffff80000000)) {
    fail |= FD_FAIL_FCVT_WU;
  }
#endif

  FD_CSR_WRITE(mstatus,
      (old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY);
  FD_CSR_WRITE(fcsr, old_fcsr);
  FD_CSR_WRITE(mstatus, old_mstatus);

  if (fail != 0) {
    printf("riscv-fd-manual fail mask = 0x%lx\n", (unsigned long)fail);
    halt(1);
  }
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
