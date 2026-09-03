#include "trap.h"

#ifdef __ISA_RISCV64__

typedef unsigned int u32;
typedef unsigned long u64;

static volatile u32 amo_word __attribute__((aligned(4)));
static volatile u64 amo_double __attribute__((aligned(8)));
static volatile u64 lrsc_words[2] __attribute__((aligned(8)));

#ifdef __PLATFORM_NEMU
#define EXC_ILLEGAL_INST        2ul
#define EXC_LOAD_MISALIGNED     4ul
#define EXC_LOAD_ACCESS_FAULT   5ul
#define EXC_STORE_MISALIGNED    6ul
#define EXC_STORE_ACCESS_FAULT  7ul

static volatile u64 amo_trap_seen;
static volatile u64 amo_trap_cause;
static volatile u64 amo_trap_tval;
static volatile u64 amo_pmp_readonly __attribute__((aligned(8)));

extern void rv64a_amo_trap(void);
extern void rv64a_invalid_lr_rs2(void);

asm(
".align 2\n"
".globl rv64a_amo_trap\n"
"rv64a_amo_trap:\n"
"  csrr t0, mcause\n"
"  la t1, amo_trap_cause\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, amo_trap_tval\n"
"  sd t0, 0(t1)\n"
"  la t1, amo_trap_seen\n"
"  li t0, 1\n"
"  sd t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
"\n"
".align 2\n"
".globl rv64a_invalid_lr_rs2\n"
"rv64a_invalid_lr_rs2:\n"
// lr.w a0, (a1)，但把规范要求为 x0 的 rs2 强制编码成 x1。
"  .word 0x1015a52f\n"
"  ret\n"
);
#endif

#define CHECK_AMO_W(OP, ORDER, INIT, SRC, EXPECT_NEW) do {                 \
  u64 old;                                                                 \
  u64 src = (u64)(SRC);                                                     \
  amo_word = (u32)(INIT);                                                   \
  asm volatile(OP ".w" ORDER " %0, %2, (%1)"                              \
      : "=r"(old) : "r"(&amo_word), "r"(src) : "memory");                 \
  check(old == (u64)(long)(int)(u32)(INIT));                                \
  check(amo_word == (u32)(EXPECT_NEW));                                     \
} while (0)

#define CHECK_AMO_D(OP, ORDER, INIT, SRC, EXPECT_NEW) do {                 \
  u64 old;                                                                 \
  u64 src = (u64)(SRC);                                                     \
  amo_double = (u64)(INIT);                                                 \
  asm volatile(OP ".d" ORDER " %0, %2, (%1)"                              \
      : "=r"(old) : "r"(&amo_double), "r"(src) : "memory");               \
  check(old == (u64)(INIT));                                                \
  check(amo_double == (u64)(EXPECT_NEW));                                   \
} while (0)

static void check_word_amos(void) {
  // .W 只使用 rs2 低 32 bit，并把内存旧值符号扩展后写入 XLEN 宽的 rd。
  CHECK_AMO_W("amoswap", ".aq", 0x80000001u, 0xffffffff00000002ul, 2u);
  CHECK_AMO_W("amoadd", ".rl", 0x7fffffffu, 1u, 0x80000000u);
  CHECK_AMO_W("amoxor", ".aqrl", 0xaaaa5555u, 0xf0f00f0fu, 0x5a5a5a5au);
  CHECK_AMO_W("amoand", "", 0xf0f0aa55u, 0x0ff00ff0u, 0x00f00a50u);
  CHECK_AMO_W("amoor", "", 0xf000aa00u, 0x0ff00ff0u, 0xfff0aff0u);
  CHECK_AMO_W("amomin", "", 0xfffffffeu, 3u, 0xfffffffeu);
  CHECK_AMO_W("amomax", "", 0xfffffffeu, 3u, 3u);
  CHECK_AMO_W("amominu", "", 0xfffffffeu, 3u, 3u);
  CHECK_AMO_W("amomaxu", "", 0xfffffffeu, 3u, 0xfffffffeu);
}

static void check_double_amos(void) {
  CHECK_AMO_D("amoswap", ".aq", 0x8000000000000001ul, 2ul, 2ul);
  CHECK_AMO_D("amoadd", ".rl", 0x7ffffffffffffffful, 1ul,
      0x8000000000000000ul);
  CHECK_AMO_D("amoxor", ".aqrl", 0xaaaa5555aaaa5555ul,
      0xf0f00f0ff0f00f0ful, 0x5a5a5a5a5a5a5a5aul);
  CHECK_AMO_D("amoand", "", 0xf0f0f0f0aaaa5555ul,
      0x0ff00ff00ff00ff0ul, 0x00f000f00aa00550ul);
  CHECK_AMO_D("amoor", "", 0xf000f000aaaa0000ul,
      0x0ff00ff00000fff0ul, 0xfff0fff0aaaafff0ul);
  CHECK_AMO_D("amomin", "", 0xfffffffffffffffeul, 3ul,
      0xfffffffffffffffeul);
  CHECK_AMO_D("amomax", "", 0xfffffffffffffffeul, 3ul, 3ul);
  CHECK_AMO_D("amominu", "", 0xfffffffffffffffeul, 3ul, 3ul);
  CHECK_AMO_D("amomaxu", "", 0xfffffffffffffffeul, 3ul,
      0xfffffffffffffffeul);
}

static void check_lr_sc(void) {
  u64 old;
  u64 status;
  u64 value;

  lrsc_words[0] = 0x1122334455667788ul;
  value = 0x8877665544332211ul;
  asm volatile(
      "lr.d.aq %0, (%2)\n"
      "sc.d.rl %1, %3, (%2)"
      : "=&r"(old), "=&r"(status)
      : "r"(&lrsc_words[0]), "r"(value)
      : "memory");
  check(old == 0x1122334455667788ul);
  check(status == 0);
  check(lrsc_words[0] == value);

  // 成功或失败的 SC 都结束 reservation，第二次 SC 必须失败且不能写内存。
  value = 0x55ul;
  asm volatile("sc.d %0, %2, (%1)"
      : "=r"(status) : "r"(&lrsc_words[0]), "r"(value) : "memory");
  check(status != 0);
  check(lrsc_words[0] == 0x8877665544332211ul);

  // NEMU 固定策略：同 hart 普通 store 与 reservation 重叠时主动失效。
  value = 0xa5a5a5a5a5a5a5a5ul;
  asm volatile(
      "lr.d %0, (%2)\n"
      "sd %3, 0(%2)\n"
      "sc.d %1, %4, (%2)"
      : "=&r"(old), "=&r"(status)
      : "r"(&lrsc_words[0]), "r"(value), "r"(0x5aul)
      : "memory");
  check(status != 0);
  check(lrsc_words[0] == value);

  // word reservation 内任意一个 byte 的普通写也属于物理范围重叠。
  lrsc_words[0] = 0x11223344ul;
  asm volatile(
      "lr.w %0, (%2)\n"
      "sb %3, 1(%2)\n"
      "sc.w %1, %4, (%2)"
      : "=&r"(old), "=&r"(status)
      : "r"(&lrsc_words[0]), "r"(0xaaul), "r"(0x55667788ul)
      : "memory");
  check(status != 0);
  check(lrsc_words[0] == 0x1122aa44ul);

  // doubleword reservation 内的 word store 同样按重叠范围失效。
  lrsc_words[0] = 0x1122334455667788ul;
  asm volatile(
      "lr.d %0, (%2)\n"
      "sw %3, 0(%2)\n"
      "sc.d %1, %4, (%2)"
      : "=&r"(old), "=&r"(status)
      : "r"(&lrsc_words[0]), "r"(0xaabbccddul), "r"(0x5aul)
      : "memory");
  check(status != 0);
  check(lrsc_words[0] == 0x11223344aabbccddul);

  // LR.W 的旧值必须符号扩展；不同宽度的 SC 不匹配同一 reservation。
  lrsc_words[0] = 0x0000000080000001ul;
  asm volatile(
      "lr.w %0, (%2)\n"
      "sc.d %1, zero, (%2)"
      : "=&r"(old), "=&r"(status)
      : "r"(&lrsc_words[0])
      : "memory");
  check(old == 0xffffffff80000001ul);
  check(status != 0);
  check(lrsc_words[0] == 0x0000000080000001ul);

  // 对另一个地址执行失败 SC 也会清掉原 reservation。
  lrsc_words[0] = 1;
  lrsc_words[1] = 2;
  asm volatile(
      "lr.d %0, (%3)\n"
      "sc.d %1, zero, (%4)\n"
      "sc.d %2, zero, (%3)"
      : "=&r"(old), "=&r"(status), "=&r"(value)
      : "r"(&lrsc_words[0]), "r"(&lrsc_words[1])
      : "memory");
  check(status != 0);
  check(value != 0);
  check(lrsc_words[0] == 1);
  check(lrsc_words[1] == 2);
}

#ifdef __PLATFORM_NEMU
static void clear_trap_record(void) {
  amo_trap_seen = 0;
  amo_trap_cause = 0;
  amo_trap_tval = 0;
}

static void check_trap(u64 cause, u64 tval) {
  check(amo_trap_seen == 1);
  check(amo_trap_cause == cause);
  check(amo_trap_tval == tval);
}

static void check_atomic_faults(void) {
  u64 ignored;
  u64 status;
  u64 misaligned_word = (u64)(void *)((char *)(void *)&amo_word + 1);
  u64 misaligned_double = (u64)(void *)((char *)(void *)&amo_double + 1);
  u64 uart = 0x10000000ul;

  asm volatile("csrw mtvec, %0" : : "r"(rv64a_amo_trap) : "memory");

  // LR 的 rs2 非零是 illegal instruction，不能继续尝试地址访问。
  clear_trap_record();
  rv64a_invalid_lr_rs2();
  check_trap(EXC_ILLEGAL_INST, 0x1015a52ful);

  clear_trap_record();
  asm volatile("lr.w %0, (%1)"
      : "=r"(ignored) : "r"(misaligned_word) : "t0", "t1", "memory");
  check_trap(EXC_LOAD_MISALIGNED, misaligned_word);

  clear_trap_record();
  asm volatile("sc.w %0, zero, (%1)"
      : "=r"(status) : "r"(misaligned_word) : "t0", "t1", "memory");
  check_trap(EXC_STORE_MISALIGNED, misaligned_word);

  clear_trap_record();
  asm volatile("amoadd.w %0, zero, (%1)"
      : "=r"(ignored) : "r"(misaligned_word) : "t0", "t1", "memory");
  check_trap(EXC_STORE_MISALIGNED, misaligned_word);

  clear_trap_record();
  asm volatile("lr.d %0, (%1)"
      : "=r"(ignored) : "r"(misaligned_double) : "t0", "t1", "memory");
  check_trap(EXC_LOAD_MISALIGNED, misaligned_double);

  // faulting SC 清 reservation 是当前 NEMU 的固定实现策略，不是通用 ISA 强制。
  amo_double = 0x1234;
  asm volatile("lr.d %0, (%1)"
      : "=r"(ignored) : "r"(&amo_double) : "memory");
  clear_trap_record();
  asm volatile("sc.d %0, zero, (%1)"
      : "=r"(status) : "r"(misaligned_double) : "t0", "t1", "memory");
  check_trap(EXC_STORE_MISALIGNED, misaligned_double);
  asm volatile("sc.d %0, zero, (%1)"
      : "=r"(status) : "r"(&amo_double) : "memory");
  check(status != 0);
  check(amo_double == 0x1234);

  clear_trap_record();
  asm volatile("amoadd.d %0, zero, (%1)"
      : "=r"(ignored) : "r"(misaligned_double) : "t0", "t1", "memory");
  check_trap(EXC_STORE_MISALIGNED, misaligned_double);

  /*
   * 当前 NEMU PMA 明确把设备窗口声明为 AMONone/RsrvNone。尤其是无 reservation
   * 的 SC 也必须先做 store/AMO 权限检查，而不能静默返回 rd=1。
   */
  clear_trap_record();
  asm volatile("lr.w %0, (%1)"
      : "=r"(ignored) : "r"(uart) : "t0", "t1", "memory");
  check_trap(EXC_LOAD_ACCESS_FAULT, uart);

  clear_trap_record();
  asm volatile("sc.w %0, zero, (%1)"
      : "=r"(status) : "r"(uart) : "t0", "t1", "memory");
  check_trap(EXC_STORE_ACCESS_FAULT, uart);

  clear_trap_record();
  asm volatile("amoadd.w %0, zero, (%1)"
      : "=r"(ignored) : "r"(uart) : "t0", "t1", "memory");
  check_trap(EXC_STORE_ACCESS_FAULT, uart);

  /*
   * PMP 把一个 8-byte NAPOT 区域锁成只读。SC 的 reservation 明明指向另一个
   * 可写地址，仍应先因目标写权限失败而 trap；普通 AMO 也必须报 store fault，
   * 不能因为内部先读旧值而错误报成 load fault。
   */
  amo_pmp_readonly = 0x5566778899aabbccul;
  u64 pmp_target = (u64)(void *)&amo_pmp_readonly;
  u64 pmpaddr = pmp_target >> 2;
  asm volatile(
      "csrw pmpaddr0, %0\n"
      "li t0, 0x99\n"  // L | NAPOT | R：M-mode 也受约束，8-byte 区域只读。
      "csrw pmpcfg0, t0"
      : : "r"(pmpaddr) : "t0", "memory");

  amo_double = 0x1020304050607080ul;
  asm volatile("lr.d %0, (%1)"
      : "=r"(ignored) : "r"(&amo_double) : "memory");
  clear_trap_record();
  asm volatile("sc.d %0, zero, (%1)"
      : "=r"(status) : "r"(pmp_target) : "t0", "t1", "memory");
  check_trap(EXC_STORE_ACCESS_FAULT, pmp_target);
  check(amo_pmp_readonly == 0x5566778899aabbccul);

  // 按上述 NEMU policy，faulting SC 后回原地址也不得意外成功。
  asm volatile("sc.d %0, zero, (%1)"
      : "=r"(status) : "r"(&amo_double) : "memory");
  check(status != 0);
  check(amo_double == 0x1020304050607080ul);

  clear_trap_record();
  asm volatile("amoadd.d %0, zero, (%1)"
      : "=r"(ignored) : "r"(pmp_target) : "t0", "t1", "memory");
  check_trap(EXC_STORE_ACCESS_FAULT, pmp_target);
  check(amo_pmp_readonly == 0x5566778899aabbccul);
}
#endif

int main(void) {
  check_word_amos();
  check_double_amos();
  check_lr_sc();
#ifdef __PLATFORM_NEMU
  check_atomic_faults();
#endif
  return 0;
}

#else

int main(void) {
  return 0;
}

#endif
