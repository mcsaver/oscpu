#include "trap.h"

#if defined(__riscv) && __riscv_xlen == 32

typedef unsigned int u32;

#define EXC_ILLEGAL_INST 2u

volatile u32 rv32_audit_trap_count;
volatile u32 rv32_audit_trap_cause;
volatile u32 rv32_audit_trap_tval;
volatile u32 rv32_audit_trap_epc;

extern u32 rv32_audit_rev8(u32 value);
extern u32 rv32_audit_zext_h(u32 value);
extern u32 rv32_audit_rv64_rev8(u32 value);
extern u32 rv32_audit_zext_h_rs2_nonzero(u32 value);
extern u32 rv32_audit_op_32(u32 value);
extern u32 rv32_audit_bseti_bit25(u32 value);
extern u32 rv32_audit_bclri_bit25(u32 value);
extern u32 rv32_audit_binvi_bit25(u32 value);
extern u32 rv32_audit_bexti_bit25(u32 value);
extern u32 rv32_audit_rori_bit25(u32 value);
extern u32 rv32_audit_reserved_selector(u32 value);

asm(
".option push\n"
".option norvc\n"
".align 2\n"
".globl rv32_audit_rev8\n"
"rv32_audit_rev8:\n"
"  .word 0x69855513\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_zext_h\n"
"rv32_audit_zext_h:\n"
"  .word 0x08054533\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_rv64_rev8\n"
"rv32_audit_rv64_rev8:\n"
"  .word 0x6b855513\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_zext_h_rs2_nonzero\n"
"rv32_audit_zext_h_rs2_nonzero:\n"
"  .word 0x08154533\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_op_32\n"
"rv32_audit_op_32:\n"
"  .word 0x0805453b\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_bseti_bit25\n"
"rv32_audit_bseti_bit25:\n"
"  .word 0x2a351513\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_bclri_bit25\n"
"rv32_audit_bclri_bit25:\n"
"  .word 0x4a351513\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_binvi_bit25\n"
"rv32_audit_binvi_bit25:\n"
"  .word 0x6a351513\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_bexti_bit25\n"
"rv32_audit_bexti_bit25:\n"
"  .word 0x4a355513\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_rori_bit25\n"
"rv32_audit_rori_bit25:\n"
"  .word 0x62355513\n"
"  ret\n"
"\n"
".align 2\n"
".globl rv32_audit_reserved_selector\n"
"rv32_audit_reserved_selector:\n"
"  .word 0x60351513\n"
"  ret\n"
".option pop\n"
);

static void rv32_audit_reset_trap(void) {
  rv32_audit_trap_count = 0;
  rv32_audit_trap_cause = 0;
  rv32_audit_trap_tval = 0;
  rv32_audit_trap_epc = 0;
}

static Context *rv32_audit_trap_handler(Event event, Context *context) {
  uintptr_t tval;
  /* 在任何 handler 内存访问前锁存本次异常的 mtval。 */
  asm volatile("csrr %0, mtval" : "=r"(tval) :: "memory");

  (void)event;
  rv32_audit_trap_count++;
  rv32_audit_trap_cause = (u32)context->mcause;
  rv32_audit_trap_tval = (u32)tval;
  rv32_audit_trap_epc = (u32)context->mepc;
  /* 本文件注入的故障指令均为 32 位，恢复点必须跨过完整 raw word。 */
  context->mepc += 4;
  return context;
}

static void rv32_audit_expect_illegal(
    u32 (*instruction)(u32), u32 encoding) {
  const u32 sentinel = 0x13579bdfu;

  rv32_audit_reset_trap();
  check(instruction(sentinel) == sentinel);
  check(rv32_audit_trap_count == 1);
  check(rv32_audit_trap_cause == EXC_ILLEGAL_INST);
  check(rv32_audit_trap_tval == encoding);
  check(rv32_audit_trap_epc == (u32)(uintptr_t)instruction);
}

int main(void) {
  check(cte_init(rv32_audit_trap_handler));

  /* RV32 REV8 使用 imm12=0x698；合法执行不得进入 trap。 */
  rv32_audit_reset_trap();
  check(rv32_audit_rev8(0x12345678u) == 0x78563412u);
  check(rv32_audit_trap_count == 0);

  /* RV32 ZEXT.H 固定 rs2=x0，且只读取 rs1。 */
  rv32_audit_reset_trap();
  check(rv32_audit_zext_h(0x89abcdefu) == 0x0000cdefu);
  check(rv32_audit_trap_count == 0);

  rv32_audit_expect_illegal(rv32_audit_rv64_rev8, 0x6b855513u);
  rv32_audit_expect_illegal(
      rv32_audit_zext_h_rs2_nonzero, 0x08154533u);
  rv32_audit_expect_illegal(rv32_audit_op_32, 0x0805453bu);

  /* RV32 的立即数位号只有五位，bit25=1 必须逐条拒绝。 */
  rv32_audit_expect_illegal(rv32_audit_bseti_bit25, 0x2a351513u);
  rv32_audit_expect_illegal(rv32_audit_bclri_bit25, 0x4a351513u);
  rv32_audit_expect_illegal(rv32_audit_binvi_bit25, 0x6a351513u);
  rv32_audit_expect_illegal(rv32_audit_bexti_bit25, 0x4a355513u);
  rv32_audit_expect_illegal(rv32_audit_rori_bit25, 0x62355513u);

  /* CLZ 组的 selector=3 是保留编码。 */
  rv32_audit_expect_illegal(rv32_audit_reserved_selector, 0x60351513u);

  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
