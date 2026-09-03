#include "trap.h"

#if defined(__ISA_RISCV32__)

typedef uint32_t u32;

#define EXC_ILLEGAL_INST        2u
#define EXC_LOAD_MISALIGNED     4u
#define EXC_LOAD_ACCESS_FAULT   5u
#define EXC_STORE_MISALIGNED    6u
#define EXC_STORE_ACCESS_FAULT  7u
#define EXC_ECALL_S             9u

#define MSTATUS_MPP_MASK        (3u << 11)
#define MSTATUS_MPP_S           (1u << 11)
#define MSTATUS_MPP_M           (3u << 11)
#define SATP_MODE_SV32          (1u << 31)

#define PAGE_BYTES              4096u
#define PHYSICAL_BASE           0x80000000u
#define ATOMIC_ALIAS            0x40000000u

#define PTE_VALID               (1u << 0)
#define PTE_READ                (1u << 1)
#define PTE_WRITE               (1u << 2)
#define PTE_EXECUTE             (1u << 3)
#define PTE_ACCESSED            (1u << 6)
#define PTE_DIRTY               (1u << 7)

static volatile u32 amo_word __attribute__((aligned(4)));
static volatile u32 lrsc_words[2] __attribute__((aligned(4)));

#ifdef __PLATFORM_NEMU
static volatile u32 amo_pmp_readonly[2] __attribute__((aligned(8)));

static volatile u32 sv32_root[1024] __attribute__((aligned(PAGE_BYTES)));
static volatile u32 sv32_leaf[1024] __attribute__((aligned(PAGE_BYTES)));
static volatile u32 sv32_page_a[PAGE_BYTES / sizeof(u32)]
    __attribute__((aligned(PAGE_BYTES)));
static volatile u32 sv32_page_b[PAGE_BYTES / sizeof(u32)]
    __attribute__((aligned(PAGE_BYTES)));

volatile uintptr_t rv32a_trap_seen;
volatile uintptr_t rv32a_trap_cause;
volatile uintptr_t rv32a_trap_tval;
volatile uintptr_t rv32a_sv32_satp;
volatile uintptr_t rv32a_sv32_sc_status;
volatile uintptr_t rv32a_sv32_page_a_value;
volatile uintptr_t rv32a_sv32_page_b_value;

extern void rv32a_amo_trap(void);
extern void rv32a_invalid_lr_rs2(void);
extern void rv32a_sv32_roundtrip(void);
extern void rv32a_sv32_resume(void);

asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl rv32a_amo_trap\n"
"rv32a_amo_trap:\n"
"  csrr t0, mcause\n"
"  li t1, 9\n"
"  beq t0, t1, rv32a_return_from_supervisor\n"
"  la t1, rv32a_trap_cause\n"
"  sw t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, rv32a_trap_tval\n"
"  sw t0, 0(t1)\n"
"  la t1, rv32a_trap_seen\n"
"  li t0, 1\n"
"  sw t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
"rv32a_return_from_supervisor:\n"
"  la t0, rv32a_sv32_resume\n"
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
".globl rv32a_invalid_lr_rs2\n"
"rv32a_invalid_lr_rs2:\n"
/* LR.W a0,(a1)，但把手册固定为 x0 的 rs2 字段强制编码成 x1。 */
"  .word 0x1015a52f\n"
"  ret\n"
"\n"
".balign 4\n"
".globl rv32a_sv32_roundtrip\n"
"rv32a_sv32_roundtrip:\n"
"  la t0, rv32a_sv32_entry\n"
"  csrw mepc, t0\n"
"  csrr t0, mstatus\n"
"  li t1, 0xffffe7ff\n"
"  and t0, t0, t1\n"
"  li t1, 0x800\n"
"  or t0, t0, t1\n"
"  csrw mstatus, t0\n"
"  mret\n"
"rv32a_sv32_resume:\n"
"  ret\n"
"rv32a_sv32_entry:\n"
"  la t0, rv32a_sv32_satp\n"
"  lw t1, 0(t0)\n"
"  csrw satp, t1\n"
"  sfence.vma\n"
/* LR 先在 alias -> page A 上建立物理 reservation。 */
"  li t0, 0x40000000\n"
"  lr.w t1, (t0)\n"
/* 同一 VA 改映射到 page B；SC 不能把 VA 相等误当成 reservation 命中。 */
"  la t2, sv32_leaf\n"
"  la t3, sv32_page_b\n"
"  srli t3, t3, 12\n"
"  slli t3, t3, 10\n"
"  ori t3, t3, 0xc7\n"
"  sw t3, 0(t2)\n"
"  sfence.vma t0, zero\n"
"  li t4, 0x55667788\n"
"  sc.w t5, t4, (t0)\n"
"  la t6, rv32a_sv32_sc_status\n"
"  sw t5, 0(t6)\n"
"  la t0, sv32_page_a\n"
"  lw t1, 0(t0)\n"
"  la t2, rv32a_sv32_page_a_value\n"
"  sw t1, 0(t2)\n"
"  la t0, sv32_page_b\n"
"  lw t1, 0(t0)\n"
"  la t2, rv32a_sv32_page_b_value\n"
"  sw t1, 0(t2)\n"
"  ecall\n"
".option pop\n"
);
#endif

#define CHECK_AMO_W(OP, ORDER, INIT, SRC, EXPECT_NEW) do {                 \
  uintptr_t old;                                                           \
  uintptr_t source = (uintptr_t)(SRC);                                     \
  amo_word = (u32)(INIT);                                                  \
  asm volatile(OP ".w" ORDER " %0, %2, (%1)"                            \
      : "=r"(old) : "r"(&amo_word), "r"(source) : "memory");          \
  check(old == (uintptr_t)(u32)(INIT));                                    \
  check(amo_word == (u32)(EXPECT_NEW));                                    \
} while (0)

#ifdef __PLATFORM_NEMU
static inline void clear_trap_record(void) {
  rv32a_trap_seen = 0;
  rv32a_trap_cause = 0;
  rv32a_trap_tval = 0;
}

static inline void check_trap(uintptr_t cause, uintptr_t tval) {
  check(rv32a_trap_seen == 1);
  check(rv32a_trap_cause == cause);
  check(rv32a_trap_tval == tval);
}

static void check_word_amos(void) {
  /* funct5 直接对应手册中的九个 AMO.W；四种 aq/rl 组合都保留功能语义。 */
  CHECK_AMO_W("amoswap", "",      0x80000001u, 2u,          2u);
  CHECK_AMO_W("amoadd",  ".aq",   0x7fffffffu, 1u,          0x80000000u);
  CHECK_AMO_W("amoxor",  ".rl",   0xaaaa5555u, 0xf0f00f0fu, 0x5a5a5a5au);
  CHECK_AMO_W("amoand",  ".aqrl", 0xf0f0aa55u, 0x0ff00ff0u, 0x00f00a50u);
  CHECK_AMO_W("amoor",   "",      0xf000aa00u, 0x0ff00ff0u, 0xfff0aff0u);
  CHECK_AMO_W("amomin",  "",      0xfffffffeu, 3u,          0xfffffffeu);
  CHECK_AMO_W("amomax",  "",      0xfffffffeu, 3u,          3u);
  CHECK_AMO_W("amominu", "",      0xfffffffeu, 3u,          3u);
  CHECK_AMO_W("amomaxu", "",      0xfffffffeu, 3u,          0xfffffffeu);
}

static void check_lr_sc(void) {
  uintptr_t old;
  uintptr_t status;

  lrsc_words[0] = 0x11223344u;
  asm volatile(
      "lr.w.aq %0, (%2)\n"
      "sc.w.rl %1, %3, (%2)"
      : "=&r"(old), "=&r"(status)
      : "r"(&lrsc_words[0]), "r"((uintptr_t)0x88776655u)
      : "memory");
  check(old == 0x11223344u);
  check(status == 0);
  check(lrsc_words[0] == 0x88776655u);

  /* 每条已退休 SC 都结束本 hart 的 reservation；第二条不得写内存。 */
  asm volatile("sc.w %0, %2, (%1)"
      : "=r"(status)
      : "r"(&lrsc_words[0]), "r"((uintptr_t)0x55u)
      : "memory");
  check(status != 0);
  check(lrsc_words[0] == 0x88776655u);

  /* NEMU 固定策略：同 hart 普通 store 与 reservation 重叠时主动失效。 */
  asm volatile(
      "lr.w %0, (%2)\n"
      "sw %3, 0(%2)\n"
      "sc.w %1, %4, (%2)"
      : "=&r"(old), "=&r"(status)
      : "r"(&lrsc_words[0]), "r"((uintptr_t)0xa5a5a5a5u),
        "r"((uintptr_t)0x5au)
      : "memory");
  check(status != 0);
  check(lrsc_words[0] == 0xa5a5a5a5u);

  lrsc_words[0] = 0x11223344u;
  asm volatile(
      "lr.w %0, (%2)\n"
      "sb %3, 1(%2)\n"
      "sc.w %1, %4, (%2)"
      : "=&r"(old), "=&r"(status)
      : "r"(&lrsc_words[0]), "r"((uintptr_t)0xaau),
        "r"((uintptr_t)0x55667788u)
      : "memory");
  check(status != 0);
  check(lrsc_words[0] == 0x1122aa44u);

  /* 一次普通失败的 SC 也清除先前由另一地址建立的 reservation。 */
  lrsc_words[0] = 1;
  lrsc_words[1] = 2;
  uintptr_t second_status;
  asm volatile(
      "lr.w %0, (%3)\n"
      "sc.w %1, zero, (%4)\n"
      "sc.w %2, zero, (%3)"
      : "=&r"(old), "=&r"(status), "=&r"(second_status)
      : "r"(&lrsc_words[0]), "r"(&lrsc_words[1])
      : "memory");
  check(status != 0);
  check(second_status != 0);
  check(lrsc_words[0] == 1);
  check(lrsc_words[1] == 2);
}

static void check_sv32_physical_reservation(void) {
  for (int index = 0; index < 1024; index++) {
    sv32_root[index] = 0;
    sv32_leaf[index] = 0;
  }
  sv32_page_a[0] = 0x11223344u;
  sv32_page_b[0] = 0xaabbccddu;
  rv32a_sv32_sc_status = 0;
  rv32a_sv32_page_a_value = 0;
  rv32a_sv32_page_b_value = 0;

  const uintptr_t identity_vpn1 = PHYSICAL_BASE >> 22;
  const uintptr_t alias_vpn1 = ATOMIC_ALIAS >> 22;
  const uintptr_t identity_ppn = PHYSICAL_BASE >> 12;
  sv32_root[identity_vpn1] = (identity_ppn << 10) |
      PTE_VALID | PTE_READ | PTE_WRITE | PTE_EXECUTE |
      PTE_ACCESSED | PTE_DIRTY;
  sv32_root[alias_vpn1] = (((uintptr_t)sv32_leaf >> 12) << 10) | PTE_VALID;
  sv32_leaf[0] = (((uintptr_t)sv32_page_a >> 12) << 10) |
      PTE_VALID | PTE_READ | PTE_WRITE | PTE_ACCESSED | PTE_DIRTY;
  rv32a_sv32_satp = SATP_MODE_SV32 | ((uintptr_t)sv32_root >> 12);

  clear_trap_record();
  asm volatile("csrw medeleg, zero" ::: "memory");
  rv32a_sv32_roundtrip();
  asm volatile("csrw satp, zero\nsfence.vma" ::: "memory");

  check(rv32a_trap_seen == 0);
  check(rv32a_sv32_sc_status == 1);
  check(rv32a_sv32_page_a_value == 0x11223344u);
  check(rv32a_sv32_page_b_value == 0xaabbccddu);
}

static void check_atomic_faults(void) {
  uintptr_t ignored;
  uintptr_t status;
  uintptr_t misaligned_word = (uintptr_t)(void *)((char *)(void *)&amo_word + 1);
  const uintptr_t uart = 0x10000000u;

  /* 非法 LR 编码必须先于地址对齐、翻译和设备访问被拒绝。 */
  clear_trap_record();
  rv32a_invalid_lr_rs2();
  check_trap(EXC_ILLEGAL_INST, 0x1015a52fu);

  clear_trap_record();
  asm volatile("lr.w %0, (%1)"
      : "=r"(ignored) : "r"(misaligned_word) : "t0", "t1", "memory");
  check_trap(EXC_LOAD_MISALIGNED, misaligned_word);

  /* faulting SC 清 reservation 是当前 NEMU 的固定实现策略，不是通用 ISA 强制。 */
  amo_word = 0x12345678u;
  asm volatile("lr.w %0, (%1)"
      : "=r"(ignored) : "r"(&amo_word) : "memory");
  clear_trap_record();
  asm volatile("sc.w %0, zero, (%1)"
      : "=r"(status) : "r"(misaligned_word) : "t0", "t1", "memory");
  check_trap(EXC_STORE_MISALIGNED, misaligned_word);
  asm volatile("sc.w %0, zero, (%1)"
      : "=r"(status) : "r"(&amo_word) : "memory");
  check(status != 0);
  check(amo_word == 0x12345678u);

  clear_trap_record();
  asm volatile("amoadd.w %0, zero, (%1)"
      : "=r"(ignored) : "r"(misaligned_word) : "t0", "t1", "memory");
  check_trap(EXC_STORE_MISALIGNED, misaligned_word);

  /* UART 是 RsrvNone + AMONone；任何失败都发生在设备副作用之前。 */
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

  /* 8-byte NAPOT 区域锁成只读；SC/AMO 都必须报告 store/AMO fault。 */
  amo_pmp_readonly[0] = 0x99aabbccu;
  uintptr_t pmp_target = (uintptr_t)&amo_pmp_readonly[0];
  uintptr_t pmpaddr = pmp_target >> 2;
  asm volatile(
      "csrw pmpaddr0, %0\n"
      "li t0, 0x99\n"  /* L | NAPOT | R */
      "csrw pmpcfg0, t0"
      : : "r"(pmpaddr) : "t0", "memory");

  amo_word = 0x10203040u;
  asm volatile("lr.w %0, (%1)"
      : "=r"(ignored) : "r"(&amo_word) : "memory");
  clear_trap_record();
  asm volatile("sc.w %0, zero, (%1)"
      : "=r"(status) : "r"(pmp_target) : "t0", "t1", "memory");
  check_trap(EXC_STORE_ACCESS_FAULT, pmp_target);
  check(amo_pmp_readonly[0] == 0x99aabbccu);

  asm volatile("sc.w %0, zero, (%1)"
      : "=r"(status) : "r"(&amo_word) : "memory");
  check(status != 0);
  check(amo_word == 0x10203040u);

  clear_trap_record();
  asm volatile("amoadd.w %0, zero, (%1)"
      : "=r"(ignored) : "r"(pmp_target) : "t0", "t1", "memory");
  check_trap(EXC_STORE_ACCESS_FAULT, pmp_target);
  check(amo_pmp_readonly[0] == 0x99aabbccu);
}
#endif

int main(void) {
#ifdef __PLATFORM_NEMU
  asm volatile("csrw mtvec, %0" : : "r"(rv32a_amo_trap) : "memory");
#endif
  check_word_amos();
  check_lr_sc();
#ifdef __PLATFORM_NEMU
  check_sv32_physical_reservation();
  check_atomic_faults();
#endif
  halt(0);
  return 0;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif
