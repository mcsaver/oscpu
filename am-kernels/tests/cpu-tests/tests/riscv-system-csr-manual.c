#include "trap.h"

#if defined(__riscv) && (__riscv_xlen == 32 || __riscv_xlen == 64)

#define EXC_ILLEGAL_INSTRUCTION 2u
#define EXC_ECALL_U             8u
#define EXC_ECALL_S             9u
#define EXC_ECALL_M             11u

#define MSTATUS_SPP             ((uintptr_t)1 << 8)
#define MSTATUS_MPP_MASK        ((uintptr_t)3 << 11)
#define MSTATUS_MPP_S           ((uintptr_t)1 << 11)
#define MSTATUS_FS_MASK         ((uintptr_t)3 << 13)
#define MSTATUS_FS_CLEAN        ((uintptr_t)2 << 13)
#define MSTATUS_FS_DIRTY        ((uintptr_t)3 << 13)
#define MSTATUS_TVM             ((uintptr_t)1 << 20)
#define MSTATUS_TW              ((uintptr_t)1 << 21)
#define MSTATUS_TSR             ((uintptr_t)1 << 22)

#define MIP_SSIP                ((uintptr_t)1 << 1)
#define MIP_STIP                ((uintptr_t)1 << 5)
#define MIP_SEIP                ((uintptr_t)1 << 9)
#define MIP_SUPERVISOR_MASK     (MIP_SSIP | MIP_STIP | MIP_SEIP)

#define MEDELEG_IMPLEMENTED_MASK ((uintptr_t)0xb3ff)

#if __riscv_xlen == 64
#define SYSTEM_XLEN_LOAD  "ld"
#define SYSTEM_XLEN_STORE "sd"
#else
#define SYSTEM_XLEN_LOAD  "lw"
#define SYSTEM_XLEN_STORE "sw"
#endif

static volatile uintptr_t system_trap_count;
static volatile uintptr_t system_trap_cause;
static volatile uintptr_t system_trap_tval;
static volatile uintptr_t system_trap_epc;
static volatile uintptr_t system_resume_pc;

extern void system_trap_entry(void);
extern void system_enter_supervisor(void (*entry)(void));
extern void system_enter_user(void (*entry)(void));
extern void system_invalid_csr_funct3(void);
extern void system_unimplemented_csr(void);
extern void system_write_readonly_csr(void);
extern void system_fcsr_read_raw(void);
extern void system_s_ecall(void);
extern void system_u_ecall(void);
extern void system_s_read_mstatus(void);
extern void system_s_sfence(void);
extern void system_s_read_satp(void);
extern void system_s_wfi(void);
extern void system_s_sret(void);
extern void system_u_sret(void);
extern void system_u_sret_fallback(void);
extern void system_s_sret_to_user(void);
extern void system_u_after_legal_sret(void);
extern void system_u_sfence(void);

asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl system_trap_entry\n"
"system_trap_entry:\n"
"  csrr t0, mcause\n"
"  la t1, system_trap_cause\n"
"  " SYSTEM_XLEN_STORE " t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, system_trap_tval\n"
"  " SYSTEM_XLEN_STORE " t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  la t1, system_trap_epc\n"
"  " SYSTEM_XLEN_STORE " t0, 0(t1)\n"
"  la t1, system_trap_count\n"
"  " SYSTEM_XLEN_LOAD " t2, 0(t1)\n"
"  addi t2, t2, 1\n"
"  " SYSTEM_XLEN_STORE " t2, 0(t1)\n"
"  la t1, system_resume_pc\n"
"  " SYSTEM_XLEN_LOAD " t2, 0(t1)\n"
"  beqz t2, 1f\n"
"  " SYSTEM_XLEN_STORE " zero, 0(t1)\n"
"  csrw mepc, t2\n"
"  csrr t0, mstatus\n"
"  li t1, -6145\n"       /* clear MPP[1:0] */
"  and t0, t0, t1\n"
"  li t1, 0x1800\n"      /* return to M mode */
"  or t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"1:\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
"\n"
".balign 4\n"
".globl system_enter_supervisor\n"
"system_enter_supervisor:\n"
"  la t0, 2f\n"
"  la t1, system_resume_pc\n"
"  " SYSTEM_XLEN_STORE " t0, 0(t1)\n"
"  csrw mepc, a0\n"
"  csrr t0, mstatus\n"
"  li t1, -6145\n"
"  and t0, t0, t1\n"
"  li t1, 0x800\n"
"  or t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"2:\n"
"  ret\n"
"\n"
".balign 4\n"
".globl system_enter_user\n"
"system_enter_user:\n"
"  la t0, 3f\n"
"  la t1, system_resume_pc\n"
"  " SYSTEM_XLEN_STORE " t0, 0(t1)\n"
"  csrw mepc, a0\n"
"  csrr t0, mstatus\n"
"  li t1, -6145\n"
"  and t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"3:\n"
"  ret\n"
"\n"
".balign 4\n"
".globl system_invalid_csr_funct3\n"
"system_invalid_csr_funct3:\n"
/* funct3=100 is reserved; CSR address deliberately names mscratch. */
"  .word 0x34004073\n"
"  ret\n"
"\n"
".balign 4\n"
".globl system_unimplemented_csr\n"
"system_unimplemented_csr:\n"
/* csrr a0, 0x7ff */
"  .word 0x7ff02573\n"
"  ret\n"
"\n"
".balign 4\n"
".globl system_write_readonly_csr\n"
"system_write_readonly_csr:\n"
/* csrrw x0, cycle, x0: read is suppressed, write intent is still illegal. */
"  .word 0xc0001073\n"
"  ret\n"
"\n"
".balign 4\n"
".globl system_fcsr_read_raw\n"
"system_fcsr_read_raw:\n"
/* csrr a0, fcsr */
"  .word 0x00302573\n"
"  ret\n"
"\n"
".balign 4\n"
".globl system_s_ecall\n"
"system_s_ecall:\n"
"  ecall\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_u_ecall\n"
"system_u_ecall:\n"
"  ecall\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_s_read_mstatus\n"
"system_s_read_mstatus:\n"
"  csrr a0, mstatus\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_s_sfence\n"
"system_s_sfence:\n"
"  sfence.vma zero, zero\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_s_read_satp\n"
"system_s_read_satp:\n"
"  csrr a0, satp\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_s_wfi\n"
"system_s_wfi:\n"
"  wfi\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_s_sret\n"
"system_s_sret:\n"
"  la t0, 4f\n"
"  csrw sepc, t0\n"
"  li t0, 0x100\n"
"  csrs sstatus, t0\n"
"  sret\n"
"4:\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_u_sret\n"
"system_u_sret:\n"
"  sret\n"
"  ecall\n"
".globl system_u_sret_fallback\n"
"system_u_sret_fallback:\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_s_sret_to_user\n"
"system_s_sret_to_user:\n"
"  la t0, system_u_after_legal_sret\n"
"  csrw sepc, t0\n"
"  li t0, 0x100\n"
"  csrc sstatus, t0\n"
"  sret\n"
".globl system_u_after_legal_sret\n"
"system_u_after_legal_sret:\n"
"  ecall\n"
"\n"
".balign 4\n"
".globl system_u_sfence\n"
"system_u_sfence:\n"
"  sfence.vma zero, zero\n"
"  ecall\n"
".option pop\n"
);

#define CSR_READ(name, output) \
  asm volatile("csrr %0, " #name : "=r"(output))
#define CSR_WRITE(name, input) \
  asm volatile("csrw " #name ", %0" : : "r"((uintptr_t)(input)) : "memory")

static void clear_trap_record(void) {
  system_trap_count = 0;
  system_trap_cause = 0;
  system_trap_tval = 0;
  system_trap_epc = 0;
  system_resume_pc = 0;
}

static void expect_one_trap(uintptr_t cause, uintptr_t tval,
    bool check_tval) {
  check(system_trap_count == 1);
  check(system_trap_cause == cause);
  if (check_tval) check(system_trap_tval == tval);
}

static void check_zicsr_access_intent(void) {
  uintptr_t old;
  uintptr_t value;

  CSR_WRITE(mscratch, 0x13579u);
  asm volatile("csrrw %0, mscratch, %1"
      : "=r"(old) : "r"((uintptr_t)0x2468au) : "memory");
  check(old == 0x13579u);
  CSR_READ(mscratch, value);
  check(value == 0x2468au);

  asm volatile("csrrs %0, mscratch, %1"
      : "=r"(old) : "r"((uintptr_t)0x5u) : "memory");
  check(old == 0x2468au);
  CSR_READ(mscratch, value);
  check(value == 0x2468fu);

  asm volatile("csrrc %0, mscratch, %1"
      : "=r"(old) : "r"((uintptr_t)0xfu) : "memory");
  check(old == 0x2468fu);
  CSR_READ(mscratch, value);
  check(value == 0x24680u);

  asm volatile("csrrwi %0, mscratch, 3" : "=r"(old) : : "memory");
  check(old == 0x24680u);
  asm volatile("csrrsi %0, mscratch, 4" : "=r"(old) : : "memory");
  check(old == 3u);
  asm volatile("csrrci %0, mscratch, 1" : "=r"(old) : : "memory");
  check(old == 7u);
  CSR_READ(mscratch, value);
  check(value == 6u);

  /* rs1/zimm=x0 suppresses CSRRS/CSRRC writes. */
  asm volatile("csrrs %0, mscratch, zero" : "=r"(old));
  check(old == 6u);
  asm volatile("csrrc %0, mscratch, zero" : "=r"(old));
  check(old == 6u);
  asm volatile("csrrsi %0, mscratch, 0" : "=r"(old));
  check(old == 6u);
  asm volatile("csrrci %0, mscratch, 0" : "=r"(old));
  check(old == 6u);

  /* rd=x0 suppresses CSRRW read；这里仍以最终写值作为可观察 oracle。 */
  asm volatile("csrrw zero, mscratch, %0"
      : : "r"((uintptr_t)0xabcdeu) : "memory");
  CSR_READ(mscratch, value);
  check(value == 0xabcdeu);

  clear_trap_record();
  system_invalid_csr_funct3();
  expect_one_trap(EXC_ILLEGAL_INSTRUCTION, 0x34004073u, true);
  CSR_READ(mscratch, value);
  check(value == 0xabcdeu);

  clear_trap_record();
  system_unimplemented_csr();
  expect_one_trap(EXC_ILLEGAL_INSTRUCTION, 0x7ff02573u, true);

  clear_trap_record();
  system_write_readonly_csr();
  expect_one_trap(EXC_ILLEGAL_INSTRUCTION, 0xc0001073u, true);
}

static void check_csr_warl_views(void) {
  uintptr_t old_mstatus;
  uintptr_t old_medeleg;
  uintptr_t old_mideleg;
  uintptr_t old_mie;
  uintptr_t value;

  CSR_READ(mstatus, old_mstatus);
  CSR_READ(medeleg, old_medeleg);
  CSR_READ(mideleg, old_mideleg);
  CSR_READ(mie, old_mie);

  CSR_WRITE(medeleg, ~(uintptr_t)0);
  CSR_READ(medeleg, value);
  check(value == MEDELEG_IMPLEMENTED_MASK);

  CSR_WRITE(mideleg, ~(uintptr_t)0);
  CSR_READ(mideleg, value);
  check(value == MIP_SUPERVISOR_MASK);

  CSR_WRITE(mstatus,
      (old_mstatus & ~MSTATUS_MPP_MASK) | ((uintptr_t)2 << 11));
  CSR_READ(mstatus, value);
  check((value & MSTATUS_MPP_MASK) == 0);

  CSR_WRITE(mideleg, MIP_SSIP);
  CSR_WRITE(mie, MIP_SUPERVISOR_MASK);
  CSR_READ(sie, value);
  check((value & MIP_SUPERVISOR_MASK) == MIP_SSIP);

  asm volatile("csrs mip, %0" : : "r"(MIP_SSIP) : "memory");
  CSR_READ(sip, value);
  check((value & MIP_SUPERVISOR_MASK) == MIP_SSIP);
  CSR_WRITE(mideleg, 0);
  CSR_READ(sie, value);
  check((value & MIP_SUPERVISOR_MASK) == 0);
  CSR_READ(sip, value);
  check((value & MIP_SUPERVISOR_MASK) == 0);
  asm volatile("csrc mip, %0" : : "r"(MIP_SSIP) : "memory");

  CSR_WRITE(mie, old_mie);
  CSR_WRITE(mideleg, old_mideleg);
  CSR_WRITE(medeleg, old_medeleg);
  CSR_WRITE(mstatus, old_mstatus);
}

static void run_supervisor(void (*entry)(void), uintptr_t control_bits,
    uintptr_t cause, uintptr_t tval, bool check_tval) {
  uintptr_t old_mstatus;
  CSR_READ(mstatus, old_mstatus);
  CSR_WRITE(mstatus, (old_mstatus &
      ~(MSTATUS_TVM | MSTATUS_TW | MSTATUS_TSR)) | control_bits);
  clear_trap_record();
  system_enter_supervisor(entry);
  expect_one_trap(cause, tval, check_tval);
  CSR_WRITE(mstatus, old_mstatus);
}

static void run_user(void (*entry)(void), uintptr_t cause,
    uintptr_t tval, bool check_tval) {
  clear_trap_record();
  system_enter_user(entry);
  expect_one_trap(cause, tval, check_tval);
}

static void check_privileged_system(void) {
  uintptr_t old_mstatus;
  uintptr_t old_medeleg;
  uintptr_t old_mideleg;
  uintptr_t old_sepc;
  uintptr_t value;

  CSR_READ(mstatus, old_mstatus);
  CSR_READ(medeleg, old_medeleg);
  CSR_READ(mideleg, old_mideleg);
  CSR_READ(sepc, old_sepc);
  CSR_WRITE(medeleg, 0);
  CSR_WRITE(mideleg, 0);

  clear_trap_record();
  asm volatile("ecall");
  expect_one_trap(EXC_ECALL_M, 0, true);
  run_supervisor(system_s_ecall, 0, EXC_ECALL_S, 0, true);
  run_user(system_u_ecall, EXC_ECALL_U, 0, true);

  run_supervisor(system_s_read_mstatus, 0,
      EXC_ILLEGAL_INSTRUCTION, 0x30002573u, true);
  run_user(system_u_sfence, EXC_ILLEGAL_INSTRUCTION, 0x12000073u, true);

  /* TVM/TSR/TW legality is checked before TLB, CSR, return or sleep effects. */
  run_supervisor(system_s_sfence, MSTATUS_TVM,
      EXC_ILLEGAL_INSTRUCTION, 0x12000073u, true);
  run_supervisor(system_s_read_satp, MSTATUS_TVM,
      EXC_ILLEGAL_INSTRUCTION, 0x18002573u, true);
  run_supervisor(system_s_sret, MSTATUS_TSR,
      EXC_ILLEGAL_INSTRUCTION, 0x10200073u, true);
  run_supervisor(system_s_wfi, MSTATUS_TW,
      EXC_ILLEGAL_INSTRUCTION, 0x10500073u, true);

  /* 无 TVM 时 S-mode SFENCE.VMA 合法，随后由 S-mode ECALL 返回 M。 */
  run_supervisor(system_s_sfence, 0, EXC_ECALL_S, 0, true);

  CSR_WRITE(sepc, (uintptr_t)system_u_sret_fallback);
  CSR_WRITE(mstatus, old_mstatus & ~MSTATUS_SPP);
  run_user(system_u_sret,
      EXC_ILLEGAL_INSTRUCTION, 0x10200073u, true);

  /* 合法 SRET 清 SPP 并进入 U；U-mode ECALL 的 cause 证明最终 privilege。 */
  run_supervisor(system_s_sret_to_user, 0, EXC_ECALL_U, 0, true);

  /* 保留的 xtvec MODE 必须 WARL 成一个受支持模式，不能原样读回 2/3。 */
  CSR_WRITE(mtvec, ((uintptr_t)system_trap_entry & ~(uintptr_t)3) | 3u);
  CSR_READ(mtvec, value);
  check((value & 3u) <= 1u);
  CSR_WRITE(mtvec, system_trap_entry);

  CSR_WRITE(sepc, old_sepc);
  CSR_WRITE(mideleg, old_mideleg);
  CSR_WRITE(medeleg, old_medeleg);
  CSR_WRITE(mstatus, old_mstatus);
}

static void check_fp_csr_state(void) {
  uintptr_t old_mstatus;
  uintptr_t value;
  CSR_READ(mstatus, old_mstatus);

  CSR_WRITE(mstatus, old_mstatus & ~MSTATUS_FS_MASK);
  clear_trap_record();
  system_fcsr_read_raw();
  expect_one_trap(EXC_ILLEGAL_INSTRUCTION, 0x00302573u, true);

#if defined(__riscv_flen) && __riscv_flen >= 32
  CSR_WRITE(mstatus,
      (old_mstatus & ~MSTATUS_FS_MASK) | MSTATUS_FS_CLEAN);
  asm volatile("csrw fcsr, zero" : : : "memory");
  CSR_READ(mstatus, value);
  check((value & MSTATUS_FS_MASK) == MSTATUS_FS_DIRTY);
#else
  CSR_WRITE(mstatus, old_mstatus | MSTATUS_FS_DIRTY);
  CSR_READ(mstatus, value);
  check((value & MSTATUS_FS_MASK) == 0);
#endif

  CSR_WRITE(mstatus, old_mstatus);
}

int main(void) {
  uintptr_t old_mtvec;
  CSR_READ(mtvec, old_mtvec);
  CSR_WRITE(mtvec, system_trap_entry);

  check_zicsr_access_intent();
  check_csr_warl_views();
  check_privileged_system();
  check_fp_csr_state();

  CSR_WRITE(mtvec, old_mtvec);
  halt(0);
  return 0;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif
