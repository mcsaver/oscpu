#include "trap.h"

#if defined(__riscv) && __riscv_xlen == 64

typedef unsigned long u64;

#define EXC_INST_MISALIGNED 0ul
#define EXC_ILLEGAL_INST 2ul
#define EXC_LOAD_MISALIGNED 4ul
#define EXC_STORE_MISALIGNED 6ul

#define MSTATUS_MPP_MASK (3ul << 11)
#define MSTATUS_MPP_S (1ul << 11)
#define MSTATUS_FS_MASK (3ul << 13)
#define MSTATUS_FS_CLEAN (2ul << 13)
#define MSTATUS_FS_DIRTY (3ul << 13)
#define MSTATUS_UXL_MASK (3ul << 32)
#define MSTATUS_UXL_64 (2ul << 32)
#define MSTATUS_SXL_MASK (3ul << 34)
#define MSTATUS_SXL_64 (2ul << 34)

#define MCOUNTINHIBIT_CY (1ul << 0)
#define MCOUNTINHIBIT_IR (1ul << 2)

#define MIP_SSIP (1ul << 1)
#define MIP_STIP (1ul << 5)
#define MIP_SEIP (1ul << 9)
#define MIP_SUPERVISOR_MASK (MIP_SSIP | MIP_STIP | MIP_SEIP)

#define MEDELEG_IMPLEMENTED_MASK 0xb3fful
#define SATP_MODE_SV39 (8ul << 60)
#define PTE_LEAF_AD 0xcful
#define VPN2(va) (((u64)(va) >> 30) & 0x1fful)

enum {
  FAIL_C_FLDSP_F0 = 1ul << 0,
  FAIL_C_LUI_HINT = 1ul << 1,
  FAIL_RV32_REV8_ENCODING = 1ul << 2,
  FAIL_RV32_ZEXTH_ENCODING = 1ul << 3,
  FAIL_RV64_REV8_ENCODING = 1ul << 4,
  FAIL_RV64_ZEXTH_ENCODING = 1ul << 5,
  FAIL_RV64_HIGH_COUNTER_CSR = 1ul << 6,
  FAIL_FCSR_FS_OFF = 1ul << 7,
  FAIL_FCSR_DIRTY = 1ul << 8,
  FAIL_COUNTER_WRITE_WIDTH = 1ul << 9,
  FAIL_SSTATUS_VIEW = 1ul << 10,
  FAIL_MPP_WARL = 1ul << 11,
  FAIL_DELEG_WARL = 1ul << 12,
  FAIL_SIE_SIP_VIEW = 1ul << 13,
  FAIL_INVALID_MEM_PRIORITY = 1ul << 14,
  FAIL_U_SFENCE = 1ul << 15,
  FAIL_CONTROL_TARGET_ALIGNMENT = 1ul << 16,
  FAIL_COUNTER_WRITE_RETIRE = 1ul << 17,
};

static volatile u64 audit_trap_count;
static volatile u64 audit_trap_cause[8];
static volatile u64 audit_trap_tval[8];
static volatile u64 audit_resume_pc;
static volatile u64 audit_satp;
static volatile u64 audit_bad_addr;

static u64 audit_root[512] __attribute__((aligned(4096)));
static unsigned char audit_pages[8192] __attribute__((aligned(4096)));

extern void audit_trap_entry(void);
extern u64 audit_c_fldsp_f0(u64 value, u64 sentinel);
extern void audit_c_lui_hint(void);
extern u64 audit_rv32_rev8(u64 value);
extern u64 audit_rv64_rev8(u64 value);
extern u64 audit_rv32_zexth(u64 value);
extern u64 audit_rv64_zexth(u64 value);
extern void audit_cycleh(void);
extern void audit_mcycleh(void);
extern u64 audit_mcycle_write_read(u64 value);
extern u64 audit_minstret_write_read(u64 value);
extern void audit_fcsr_read(void);
extern void audit_run_s_invalid_mem(void);
extern void audit_run_u_sfence(void);
#ifdef RV64_INST_AUDIT_NO_C
extern u64 audit_jal_misaligned(u64 sentinel);
extern u64 audit_jalr_misaligned(u64 sentinel, u64 target);
extern void audit_branch_misaligned(void);
extern void audit_branch_not_taken(void);
extern void audit_aligned_target(void);
#endif

asm(
".align 2\n"
".globl audit_trap_entry\n"
"audit_trap_entry:\n"
"  csrr t0, mcause\n"
"  li t1, 8\n"
"  beq t0, t1, 2f\n"
"  li t1, 9\n"
"  beq t0, t1, 2f\n"
"  la t1, audit_trap_count\n"
"  ld t2, 0(t1)\n"
"  slli t3, t2, 3\n"
"  la t4, audit_trap_cause\n"
"  add t4, t4, t3\n"
"  sd t0, 0(t4)\n"
"  csrr t5, mtval\n"
"  la t4, audit_trap_tval\n"
"  add t4, t4, t3\n"
"  sd t5, 0(t4)\n"
"  addi t2, t2, 1\n"
"  sd t2, 0(t1)\n"
"  csrr t0, mepc\n"
"  li t1, 0x2002\n"
"  beq t5, t1, 1f\n"
"  li t1, 0x6005\n"
"  beq t5, t1, 1f\n"
"  addi t0, t0, 4\n"
"  j 3f\n"
"1:\n"
"  addi t0, t0, 2\n"
"3:\n"
"  csrw mepc, t0\n"
"  mret\n"
"2:\n"
"  la t0, audit_resume_pc\n"
"  ld t0, 0(t0)\n"
"  csrw mepc, t0\n"
"  csrr t0, mstatus\n"
"  li t1, -6145\n"
"  and t0, t0, t1\n"
"  li t1, 0x1800\n"
"  or t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"\n"
".align 2\n"
".globl audit_c_fldsp_f0\n"
"audit_c_fldsp_f0:\n"
"  addi sp, sp, -16\n"
"  sd a0, 0(sp)\n"
"  fmv.d.x f0, a1\n"
"  .2byte 0x2002\n"
"  fmv.x.d a0, f0\n"
"  addi sp, sp, 16\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_c_lui_hint\n"
"audit_c_lui_hint:\n"
"  .2byte 0x6005\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_rv32_rev8\n"
"audit_rv32_rev8:\n"
"  .word 0x69855513\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_rv64_rev8\n"
"audit_rv64_rev8:\n"
"  .word 0x6b855513\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_rv32_zexth\n"
"audit_rv32_zexth:\n"
"  .word 0x08054533\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_rv64_zexth\n"
"audit_rv64_zexth:\n"
"  .word 0x0805453b\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_cycleh\n"
"audit_cycleh:\n"
"  .word 0xc8002573\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_mcycleh\n"
"audit_mcycleh:\n"
"  .word 0xb8002573\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_mcycle_write_read\n"
"audit_mcycle_write_read:\n"
"  csrw mcycle, a0\n"
"  csrr a0, mcycle\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_minstret_write_read\n"
"audit_minstret_write_read:\n"
"  csrw minstret, a0\n"
"  csrr a0, minstret\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_fcsr_read\n"
"audit_fcsr_read:\n"
"  .word 0x00302573\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_run_s_invalid_mem\n"
"audit_run_s_invalid_mem:\n"
"  la t0, 1f\n"
"  la t1, audit_resume_pc\n"
"  sd t0, 0(t1)\n"
"  la t0, 2f\n"
"  csrw mepc, t0\n"
"  csrr t0, mstatus\n"
"  li t1, -6145\n"
"  and t0, t0, t1\n"
"  li t1, 0x800\n"
"  or t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"2:\n"
"  la t0, audit_satp\n"
"  ld t0, 0(t0)\n"
"  csrw satp, t0\n"
"  sfence.vma\n"
"  la t0, audit_bad_addr\n"
"  ld a1, 0(t0)\n"
"  .word 0x0005f503\n"
"  .word 0x0005f023\n"
"  ecall\n"
"  j .\n"
"1:\n"
"  csrw satp, zero\n"
"  sfence.vma\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_run_u_sfence\n"
"audit_run_u_sfence:\n"
"  la t0, 1f\n"
"  la t1, audit_resume_pc\n"
"  sd t0, 0(t1)\n"
"  la t0, 2f\n"
"  csrw mepc, t0\n"
"  csrr t0, mstatus\n"
"  li t1, -6145\n"
"  and t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"2:\n"
"  .word 0x12000073\n"
"  ecall\n"
"  j .\n"
"1:\n"
"  ret\n"
);

#ifdef RV64_INST_AUDIT_NO_C
asm(
".align 2\n"
".globl audit_jal_misaligned\n"
"audit_jal_misaligned:\n"
"  .word 0x0020056f\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_jalr_misaligned\n"
"audit_jalr_misaligned:\n"
"  .word 0x00058567\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_branch_misaligned\n"
"audit_branch_misaligned:\n"
"  .word 0x00000163\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_branch_not_taken\n"
"audit_branch_not_taken:\n"
"  .word 0x00001163\n"
"  ret\n"
"\n"
".align 2\n"
".globl audit_aligned_target\n"
"audit_aligned_target:\n"
"  ret\n"
);
#endif

#define CSR_READ(name, out) \
  asm volatile("csrr %0, " #name : "=r"(out))
#define CSR_WRITE(name, value) \
  asm volatile("csrw " #name ", %0" : : "r"((u64)(value)) : "memory")

static void trap_reset(void) {
  audit_trap_count = 0;
  for (int i = 0; i < 8; i++) {
    audit_trap_cause[i] = 0;
    audit_trap_tval[i] = 0;
  }
}

static int trap_is(int index, u64 cause, u64 tval) {
  return audit_trap_count > (u64)index &&
         audit_trap_cause[index] == cause &&
         audit_trap_tval[index] == tval;
}

static u64 check_compressed_and_bitmanip(void) {
  const u64 input = 0x0123456789abcdeful;
  const u64 reversed = 0xefcdab8967452301ul;
  u64 fail = 0;
  u64 mstatus;

  CSR_READ(mstatus, mstatus);
  CSR_WRITE(mstatus, (mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_DIRTY);

#ifndef RV64_INST_AUDIT_NO_C
  trap_reset();
  if (audit_c_fldsp_f0(input, ~input) != input || audit_trap_count != 0) {
    fail |= FAIL_C_FLDSP_F0;
  }

  trap_reset();
  audit_c_lui_hint();
  if (audit_trap_count != 0) fail |= FAIL_C_LUI_HINT;
#endif

  trap_reset();
  if (audit_rv32_rev8(input) != input ||
      !trap_is(0, EXC_ILLEGAL_INST, 0x69855513ul)) {
    fail |= FAIL_RV32_REV8_ENCODING;
  }

  trap_reset();
  if (audit_rv64_rev8(input) != reversed || audit_trap_count != 0) {
    fail |= FAIL_RV64_REV8_ENCODING;
  }

  trap_reset();
  if (audit_rv32_zexth(input) != input ||
      !trap_is(0, EXC_ILLEGAL_INST, 0x08054533ul)) {
    fail |= FAIL_RV32_ZEXTH_ENCODING;
  }

  trap_reset();
  if (audit_rv64_zexth(input) != 0xcdeful || audit_trap_count != 0) {
    fail |= FAIL_RV64_ZEXTH_ENCODING;
  }
  return fail;
}

static u64 check_control_target_alignment(void) {
#ifndef RV64_INST_AUDIT_NO_C
  // C 扩展令 IALIGN=16，所有 J/B 立即数天然满足目标对齐，不会产生 cause 0。
  return 0;
#else
  const u64 sentinel = 0x13579bdf2468ace0ul;
  u64 fail = 0;

  trap_reset();
  if (audit_jal_misaligned(sentinel) != sentinel ||
      !trap_is(0, EXC_INST_MISALIGNED,
               (u64)(void *)audit_jal_misaligned + 2)) {
    fail |= FAIL_CONTROL_TARGET_ALIGNMENT;
  }

  trap_reset();
  u64 jalr_target = (u64)(void *)audit_aligned_target + 2;
  if (audit_jalr_misaligned(sentinel, jalr_target) != sentinel ||
      !trap_is(0, EXC_INST_MISALIGNED, jalr_target)) {
    fail |= FAIL_CONTROL_TARGET_ALIGNMENT;
  }

  trap_reset();
  audit_branch_misaligned();
  if (!trap_is(0, EXC_INST_MISALIGNED,
               (u64)(void *)audit_branch_misaligned + 2)) {
    fail |= FAIL_CONTROL_TARGET_ALIGNMENT;
  }

  trap_reset();
  audit_branch_not_taken();
  if (audit_trap_count != 0) fail |= FAIL_CONTROL_TARGET_ALIGNMENT;
  return fail;
#endif
}

static u64 check_csr_legality_and_fp_state(void) {
  u64 fail = 0;
  u64 old_mstatus;
  u64 value;

  trap_reset();
  audit_cycleh();
  if (!trap_is(0, EXC_ILLEGAL_INST, 0xc8002573ul)) {
    fail |= FAIL_RV64_HIGH_COUNTER_CSR;
  }

  trap_reset();
  audit_mcycleh();
  if (!trap_is(0, EXC_ILLEGAL_INST, 0xb8002573ul)) {
    fail |= FAIL_RV64_HIGH_COUNTER_CSR;
  }

  CSR_READ(mstatus, old_mstatus);
  CSR_WRITE(mstatus, old_mstatus & ~MSTATUS_FS_MASK);
  trap_reset();
  audit_fcsr_read();
  if (!trap_is(0, EXC_ILLEGAL_INST, 0x00302573ul)) {
    fail |= FAIL_FCSR_FS_OFF;
  }

  CSR_WRITE(mstatus, (old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_CLEAN);
  CSR_WRITE(fflags, 1);
  CSR_READ(mstatus, value);
  if ((value & MSTATUS_FS_MASK) != MSTATUS_FS_DIRTY) {
    fail |= FAIL_FCSR_DIRTY;
  }
  CSR_WRITE(mstatus, old_mstatus);
  return fail;
}

static u64 check_counter_width(void) {
  const u64 cycle_pattern = 0x123456789abcdef0ul;
  const u64 instret_pattern = 0x0fedcba987654321ul;
  u64 fail = 0;
  u64 old_inhibit;
  u64 value;

  CSR_READ(mcountinhibit, old_inhibit);
  CSR_WRITE(mcountinhibit, MCOUNTINHIBIT_CY | MCOUNTINHIBIT_IR);
  CSR_WRITE(mcycle, cycle_pattern);
  CSR_READ(mcycle, value);
  if (value != cycle_pattern) fail |= FAIL_COUNTER_WRITE_WIDTH;

  CSR_WRITE(minstret, instret_pattern);
  CSR_READ(minstret, value);
  if (value != instret_pattern) fail |= FAIL_COUNTER_WRITE_WIDTH;

  // A later mcycle read on a real OoO core legitimately observes the physical
  // cycles elapsed since the write.  Hold CY while checking the 64-bit CSR
  // write/read value; same-edge write priority is checked in tb_csr_file.
  CSR_WRITE(mcountinhibit, MCOUNTINHIBIT_CY);
  if (audit_mcycle_write_read(cycle_pattern) != cycle_pattern) {
    fail |= FAIL_COUNTER_WRITE_RETIRE;
  }

  // Keep IR enabled here: the minstret CSR write must win over the retirement
  // increment of that same instruction, and the following read sees the value
  // before its own retirement increment.
  CSR_WRITE(mcountinhibit, 0);
  if (audit_minstret_write_read(instret_pattern) != instret_pattern) {
    fail |= FAIL_COUNTER_WRITE_RETIRE;
  }
  CSR_WRITE(mcountinhibit, old_inhibit);
  return fail;
}

static u64 check_status_warl(void) {
  u64 fail = 0;
  u64 old_mstatus;
  u64 sstatus;
  u64 mstatus;

  CSR_READ(mstatus, old_mstatus);
  CSR_READ(sstatus, sstatus);
  CSR_WRITE(sstatus, sstatus | MSTATUS_UXL_MASK | MSTATUS_SXL_MASK);
  CSR_READ(sstatus, sstatus);
  CSR_READ(mstatus, mstatus);
  if ((sstatus & MSTATUS_UXL_MASK) != MSTATUS_UXL_64 ||
      (sstatus & MSTATUS_SXL_MASK) != 0 ||
      (mstatus & MSTATUS_UXL_MASK) != MSTATUS_UXL_64 ||
      (mstatus & MSTATUS_SXL_MASK) != MSTATUS_SXL_64) {
    fail |= FAIL_SSTATUS_VIEW;
  }

  CSR_WRITE(mstatus, (old_mstatus & ~MSTATUS_MPP_MASK) | (2ul << 11));
  CSR_READ(mstatus, mstatus);
  if ((mstatus & MSTATUS_MPP_MASK) != 0) fail |= FAIL_MPP_WARL;
  CSR_WRITE(mstatus, old_mstatus);
  return fail;
}

static u64 check_delegation_csrs(void) {
  u64 fail = 0;
  u64 old_medeleg;
  u64 old_mideleg;
  u64 old_mie;
  u64 value;

  CSR_READ(medeleg, old_medeleg);
  CSR_READ(mideleg, old_mideleg);
  CSR_READ(mie, old_mie);
  CSR_WRITE(mie, 0);

  CSR_WRITE(medeleg, ~0ul);
  CSR_READ(medeleg, value);
  if (value != MEDELEG_IMPLEMENTED_MASK) fail |= FAIL_DELEG_WARL;

  CSR_WRITE(mideleg, ~0ul);
  CSR_READ(mideleg, value);
  if (value != MIP_SUPERVISOR_MASK) fail |= FAIL_DELEG_WARL;

  CSR_WRITE(mideleg, 0);
  CSR_WRITE(sie, MIP_SUPERVISOR_MASK);
  CSR_READ(mie, value);
  if ((value & MIP_SUPERVISOR_MASK) != 0) fail |= FAIL_SIE_SIP_VIEW;
  CSR_READ(sie, value);
  if (value != 0) fail |= FAIL_SIE_SIP_VIEW;

  CSR_WRITE(mip, 0);
  CSR_WRITE(sip, MIP_SSIP);
  CSR_READ(mip, value);
  if ((value & MIP_SSIP) != 0) fail |= FAIL_SIE_SIP_VIEW;

  CSR_WRITE(mideleg, MIP_SUPERVISOR_MASK);
  CSR_WRITE(sie, MIP_SUPERVISOR_MASK);
  CSR_READ(sie, value);
  if (value != MIP_SUPERVISOR_MASK) fail |= FAIL_SIE_SIP_VIEW;
  CSR_WRITE(sip, MIP_SSIP);
  CSR_READ(mip, value);
  if ((value & MIP_SSIP) == 0) fail |= FAIL_SIE_SIP_VIEW;

  CSR_WRITE(mip, 0);
  CSR_WRITE(mie, old_mie);
  CSR_WRITE(mideleg, old_mideleg);
  CSR_WRITE(medeleg, old_medeleg);
  return fail;
}

static u64 check_privileged_and_fault_priority(void) {
  u64 fail = 0;

  for (int i = 0; i < 512; i++) audit_root[i] = 0;
  audit_root[VPN2(0x80000000ul)] =
      ((0x80000000ul >> 12) << 10) | PTE_LEAF_AD;
  audit_bad_addr = (u64)&audit_pages[0xffc];
  audit_satp = SATP_MODE_SV39 | ((u64)audit_root >> 12);

  CSR_WRITE(medeleg, 0);
  CSR_WRITE(mideleg, 0);
  CSR_WRITE(mie, 0);

  trap_reset();
  audit_run_s_invalid_mem();
  if (audit_trap_count != 2 ||
      !trap_is(0, EXC_ILLEGAL_INST, 0x0005f503ul) ||
      !trap_is(1, EXC_ILLEGAL_INST, 0x0005f023ul)) {
    fail |= FAIL_INVALID_MEM_PRIORITY;
  }

  trap_reset();
  audit_run_u_sfence();
  if (audit_trap_count != 1 ||
      !trap_is(0, EXC_ILLEGAL_INST, 0x12000073ul)) {
    fail |= FAIL_U_SFENCE;
  }
  return fail;
}

int main(void) {
  u64 fail = 0;

  CSR_WRITE(mtvec, audit_trap_entry);
  fail |= check_compressed_and_bitmanip();
  fail |= check_control_target_alignment();
  fail |= check_csr_legality_and_fp_state();
  fail |= check_counter_width();
  fail |= check_status_warl();
  fail |= check_delegation_csrs();
  fail |= check_privileged_and_fault_priority();

  if (fail != 0) halt(fail);
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
