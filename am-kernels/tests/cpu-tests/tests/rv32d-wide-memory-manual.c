#include "trap.h"

#if defined(__ISA_RISCV32__) && defined(__riscv_flen) && \
    __riscv_flen >= 64 && defined(__PLATFORM_NEMU)

#define EXC_LOAD_MISALIGNED   4u
#define EXC_STORE_MISALIGNED  6u
#define EXC_LOAD_PAGE_FAULT   13u
#define EXC_STORE_PAGE_FAULT  15u

#define MSTATUS_MPP_MASK      (3u << 11)
#define MSTATUS_MPP_S         (1u << 11)
#define MSTATUS_MPP_M         (3u << 11)
#define MSTATUS_FS_MASK       (3u << 13)
#define MSTATUS_FS_DIRTY      (3u << 13)
#define SATP_MODE_SV32        (1u << 31)

#define PAGE_BYTES            4096u
#define PHYSICAL_BASE         0x80000000u
#define ALIAS_BASE            0x40000000u

#define PTE_VALID             (1u << 0)
#define PTE_READ              (1u << 1)
#define PTE_WRITE             (1u << 2)
#define PTE_EXECUTE           (1u << 3)
#define PTE_ACCESSED          (1u << 6)
#define PTE_DIRTY             (1u << 7)

static volatile uint32_t wide_root[1024]
    __attribute__((aligned(PAGE_BYTES)));
static volatile uint32_t wide_leaf[1024]
    __attribute__((aligned(PAGE_BYTES)));
static volatile uint8_t wide_first_page[PAGE_BYTES]
    __attribute__((aligned(PAGE_BYTES)));
static volatile uint8_t wide_second_page[PAGE_BYTES]
    __attribute__((aligned(PAGE_BYTES)));

volatile uintptr_t rv32d_satp;
volatile uintptr_t rv32d_cross_address;
volatile uintptr_t rv32d_resume_pc;
volatile uintptr_t rv32d_trap_count;
volatile uintptr_t rv32d_trap_cause;
volatile uintptr_t rv32d_trap_tval;

extern void rv32d_wide_trap(void);
extern void rv32d_wide_roundtrip(const uint64_t *source, uint64_t *result);
extern void rv32d_cross_load(void);
extern void rv32d_cross_store(const uint64_t *source);

asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl rv32d_wide_trap\n"
"rv32d_wide_trap:\n"
"  csrr t0, mcause\n"
"  la t1, rv32d_trap_cause\n"
"  sw t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, rv32d_trap_tval\n"
"  sw t0, 0(t1)\n"
"  la t1, rv32d_trap_count\n"
"  lw t0, 0(t1)\n"
"  addi t0, t0, 1\n"
"  sw t0, 0(t1)\n"
/* Resume the bounded harness in M mode, where it disables satp. */
"  la t1, rv32d_resume_pc\n"
"  lw t0, 0(t1)\n"
"  csrw mepc, t0\n"
"  csrr t0, mstatus\n"
"  li t1, 0xffffe7ff\n"
"  and t0, t0, t1\n"
"  li t1, 0x1800\n"
"  or t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"\n"
".balign 4\n"
".globl rv32d_wide_roundtrip\n"
"rv32d_wide_roundtrip:\n"
"  fld f0, 0(a0)\n"
"  fsd f0, 0(a1)\n"
"  ret\n"
"\n"
".balign 4\n"
".globl rv32d_cross_load\n"
"rv32d_cross_load:\n"
"  la t0, 1f\n"
"  la t1, rv32d_resume_pc\n"
"  sw t0, 0(t1)\n"
"  la t0, rv32d_s_cross_load\n"
"  csrw mepc, t0\n"
"  csrr t0, mstatus\n"
"  li t1, 0xffffe7ff\n"
"  and t0, t0, t1\n"
"  li t1, 0x800\n"
"  or t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"1:\n"
"  csrw satp, zero\n"
"  sfence.vma\n"
"  ret\n"
"rv32d_s_cross_load:\n"
"  la t0, rv32d_satp\n"
"  lw t1, 0(t0)\n"
"  csrw satp, t1\n"
"  sfence.vma\n"
"  la t0, rv32d_cross_address\n"
"  lw t0, 0(t0)\n"
"  fld f0, 0(t0)\n"
/* If FLD unexpectedly succeeds, ECALL makes the failure observable. */
"  ecall\n"
"\n"
".balign 4\n"
".globl rv32d_cross_store\n"
"rv32d_cross_store:\n"
"  fld f0, 0(a0)\n"
"  la t0, 2f\n"
"  la t1, rv32d_resume_pc\n"
"  sw t0, 0(t1)\n"
"  la t0, rv32d_s_cross_store\n"
"  csrw mepc, t0\n"
"  csrr t0, mstatus\n"
"  li t1, 0xffffe7ff\n"
"  and t0, t0, t1\n"
"  li t1, 0x800\n"
"  or t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"2:\n"
"  csrw satp, zero\n"
"  sfence.vma\n"
"  ret\n"
"rv32d_s_cross_store:\n"
"  la t0, rv32d_satp\n"
"  lw t1, 0(t0)\n"
"  csrw satp, t1\n"
"  sfence.vma\n"
"  la t0, rv32d_cross_address\n"
"  lw t0, 0(t0)\n"
"  fsd f0, 0(t0)\n"
/* If FSD unexpectedly succeeds, ECALL makes the failure observable. */
"  ecall\n"
".option pop\n"
);

static inline uintptr_t rv32d_read_mstatus(void) {
  uintptr_t value;
  asm volatile("csrr %0, mstatus" : "=r"(value));
  return value;
}

static inline void rv32d_write_mstatus(uintptr_t value) {
  asm volatile("csrw mstatus, %0" : : "r"(value) : "memory");
}

static void rv32d_clear_trap(void) {
  rv32d_trap_count = 0;
  rv32d_trap_cause = 0;
  rv32d_trap_tval = 0;
}

static bool rv32d_load_fault_is_precise(void) {
  const uintptr_t second_page = ALIAS_BASE + PAGE_BYTES;
  return rv32d_trap_count == 1 &&
         (rv32d_trap_cause == EXC_LOAD_MISALIGNED ||
          rv32d_trap_cause == EXC_LOAD_PAGE_FAULT) &&
         (rv32d_trap_tval == rv32d_cross_address ||
          rv32d_trap_tval == second_page);
}

static bool rv32d_store_fault_is_precise(void) {
  const uintptr_t second_page = ALIAS_BASE + PAGE_BYTES;
  return rv32d_trap_count == 1 &&
         (rv32d_trap_cause == EXC_STORE_MISALIGNED ||
          rv32d_trap_cause == EXC_STORE_PAGE_FAULT) &&
         (rv32d_trap_tval == rv32d_cross_address ||
          rv32d_trap_tval == second_page);
}

static void rv32d_require(bool condition, int code) {
  if (!condition) {
    printf("rv32d-wide-memory-manual failure %d: traps=%lu cause=%lu "
           "tval=0x%lx\n",
        code, (unsigned long)rv32d_trap_count,
        (unsigned long)rv32d_trap_cause,
        (unsigned long)rv32d_trap_tval);
    halt(code);
  }
}

int main(void) {
  const uintptr_t old_mstatus = rv32d_read_mstatus();
  rv32d_write_mstatus(
      (old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY);
  asm volatile("csrw mtvec, %0" : : "r"(rv32d_wide_trap) : "memory");
  asm volatile("csrw medeleg, zero" ::: "memory");

  /* Ordinary RV32D memory data are 64 bits even though XLEN is 32. */
  const uint64_t source __attribute__((aligned(8))) =
      UINT64_C(0x0123456789abcdef);
  uint64_t result __attribute__((aligned(8))) = 0;
  rv32d_clear_trap();
  rv32d_wide_roundtrip(&source, &result);
  rv32d_require(rv32d_trap_count == 0, 1);
  rv32d_require(result == source, 2);

  for (int index = 0; index < 1024; index++) {
    wide_root[index] = 0;
    wide_leaf[index] = 0;
  }
  for (int index = 0; index < PAGE_BYTES; index++) {
    wide_first_page[index] = 0;
    wide_second_page[index] = 0;
  }

  /* Keep code/data/stack reachable after S mode enables Sv32. */
  const uintptr_t identity_vpn1 = PHYSICAL_BASE >> 22;
  const uintptr_t identity_ppn = PHYSICAL_BASE >> 12;
  wide_root[identity_vpn1] = (identity_ppn << 10) |
      PTE_VALID | PTE_READ | PTE_WRITE | PTE_EXECUTE |
      PTE_ACCESSED | PTE_DIRTY;

  /* Map only the first alias page; the immediately following PTE stays invalid. */
  const uintptr_t alias_vpn1 = ALIAS_BASE >> 22;
  wide_root[alias_vpn1] = (((uintptr_t)wide_leaf >> 12) << 10) | PTE_VALID;
  wide_leaf[0] = (((uintptr_t)wide_first_page >> 12) << 10) |
      PTE_VALID | PTE_READ | PTE_WRITE | PTE_ACCESSED | PTE_DIRTY;
  wide_leaf[1] = 0;
  rv32d_satp = SATP_MODE_SV32 | ((uintptr_t)wide_root >> 12);
  rv32d_cross_address = ALIAS_BASE + PAGE_BYTES - 4;

  rv32d_clear_trap();
  rv32d_cross_load();
  rv32d_require(rv32d_load_fault_is_precise(), 3);

  /* A faulting FSD must not commit the four bytes that lie in page one. */
  wide_first_page[PAGE_BYTES - 4] = 0x11;
  wide_first_page[PAGE_BYTES - 3] = 0x22;
  wide_first_page[PAGE_BYTES - 2] = 0x33;
  wide_first_page[PAGE_BYTES - 1] = 0x44;
  const uint64_t store_value __attribute__((aligned(8))) =
      UINT64_C(0xfedcba9876543210);
  rv32d_clear_trap();
  rv32d_cross_store(&store_value);
  rv32d_require(rv32d_store_fault_is_precise(), 4);
  rv32d_require(wide_first_page[PAGE_BYTES - 4] == 0x11, 5);
  rv32d_require(wide_first_page[PAGE_BYTES - 3] == 0x22, 6);
  rv32d_require(wide_first_page[PAGE_BYTES - 2] == 0x33, 7);
  rv32d_require(wide_first_page[PAGE_BYTES - 1] == 0x44, 8);

  asm volatile("csrw satp, zero\nsfence.vma" ::: "memory");
  rv32d_write_mstatus(old_mstatus);
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
