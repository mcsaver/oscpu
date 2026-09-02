#include "trap.h"

#if defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)

#define UART_BASE        0x10000000ul
#define UART_IER         (UART_BASE + 1ul)
#define UART_IIR         (UART_BASE + 2ul)

#define PLIC_BASE        0x0c000000ul
#define PLIC_PRIORITY0   (PLIC_BASE + 0x000000ul)
#define PLIC_PRIORITY1   (PLIC_BASE + 0x000004ul)
#define PLIC_PRIORITY31  (PLIC_BASE + 0x00007cul)
#define PLIC_PENDING     (PLIC_BASE + 0x001000ul)
#define PLIC_M_ENABLE    (PLIC_BASE + 0x002000ul)
#define PLIC_S_ENABLE    (PLIC_BASE + 0x002080ul)
#define PLIC_M_THRESHOLD (PLIC_BASE + 0x200000ul)
#define PLIC_M_CLAIM     (PLIC_BASE + 0x200004ul)
#define PLIC_S_THRESHOLD (PLIC_BASE + 0x201000ul)
#define PLIC_S_CLAIM     (PLIC_BASE + 0x201004ul)

#define UART_SOURCE      1u
#define UART_SOURCE_BIT  (1u << UART_SOURCE)
#define LAST_SOURCE_BIT  (1u << 31)
#define MIP_MEIP         (1ul << 11)

#if defined(__ISA_RISCV64__)
#define PLIC_REG_STORE "sd"
#else
#define PLIC_REG_STORE "sw"
#endif

volatile uintptr_t plic_fault_cause;

extern void plic_access_trap(void);

asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl plic_access_trap\n"
"plic_access_trap:\n"
"  csrr t0, mcause\n"
"  la t1, plic_fault_cause\n"
"  " PLIC_REG_STORE " t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
".option pop\n"
);

static inline void write_mmio32(uintptr_t addr, uint32_t value) {
  *(volatile uint32_t *)addr = value;
}

static inline uint32_t read_mmio32(uintptr_t addr) {
  return *(volatile uint32_t *)addr;
}

static inline void write_mmio8(uintptr_t addr, uint8_t value) {
  *(volatile uint8_t *)addr = value;
}

static inline uint8_t read_mmio8(uintptr_t addr) {
  return *(volatile uint8_t *)addr;
}

static inline uintptr_t read_csr_mip(void) {
  uintptr_t value;
  asm volatile("csrr %0, mip" : "=r"(value));
  return value;
}

static inline uintptr_t read_csr_mtvec(void) {
  uintptr_t value;
  asm volatile("csrr %0, mtvec" : "=r"(value));
  return value;
}

static inline void write_csr_mtvec(uintptr_t value) {
  asm volatile("csrw mtvec, %0" : : "r"(value) : "memory");
}

static void check_or_halt(bool condition, int code) {
  if (!condition) halt(code);
}

static void expect_load_access_fault_byte(uintptr_t address, int code) {
  plic_fault_cause = 0;
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lbu zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_or_halt(plic_fault_cause == 5, code);
}

static void expect_load_access_fault_word(uintptr_t address, int code) {
  plic_fault_cause = 0;
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lw zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_or_halt(plic_fault_cause == 5, code);
}

static void expect_store_access_fault_byte(uintptr_t address, int code) {
  plic_fault_cause = 0;
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sb zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_or_halt(plic_fault_cause == 7, code);
}

static void expect_store_access_fault_word(uintptr_t address, int code) {
  plic_fault_cause = 0;
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sw zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_or_halt(plic_fault_cause == 7, code);
}

int main() {
  /* 非 32-bit、未自然对齐和跨 aperture 的事务必须成为 guest access-fault。 */
  uintptr_t old_mtvec = read_csr_mtvec();
  write_csr_mtvec((uintptr_t)plic_access_trap);
  expect_load_access_fault_byte(PLIC_PRIORITY0, 29);
  expect_load_access_fault_word(PLIC_PRIORITY0 + 2, 30);
  expect_load_access_fault_word(PLIC_BASE + 0x04000000ul - 2, 31);
  expect_store_access_fault_byte(PLIC_PRIORITY0, 32);
  expect_store_access_fault_word(PLIC_PRIORITY0 + 2, 33);
  expect_store_access_fault_word(PLIC_BASE + 0x04000000ul - 2, 34);
  write_csr_mtvec(old_mtvec);

  /* 先撤销 UART THRE 设备线，测试从可观察的空闲网关状态开始。 */
  write_mmio8(UART_IER, 0);
  (void)read_mmio8(UART_IIR);
  write_mmio32(PLIC_M_ENABLE, 0);
  write_mmio32(PLIC_S_ENABLE, 0);
  write_mmio32(PLIC_M_THRESHOLD, 0);
  write_mmio32(PLIC_S_THRESHOLD, 0);

  /* source 0 在 priority、pending 和每个 context enable 中都必须硬读为 0。 */
  write_mmio32(PLIC_PRIORITY0, 7);
  check_or_halt(read_mmio32(PLIC_PRIORITY0) == 0, 2);
  write_mmio32(PLIC_M_ENABLE, 1);
  write_mmio32(PLIC_S_ENABLE, 1);
  check_or_halt((read_mmio32(PLIC_M_ENABLE) & 1u) == 0, 3);
  check_or_halt((read_mmio32(PLIC_S_ENABLE) & 1u) == 0, 4);
  check_or_halt((read_mmio32(PLIC_PENDING) & 1u) == 0, 5);

  /* virt PLIC 实现 3 个 WARL 优先级位，source 31 是单个 pending word 的边界。 */
  write_mmio32(PLIC_PRIORITY31, UINT32_MAX);
  check_or_halt(read_mmio32(PLIC_PRIORITY31) == 7, 6);
  write_mmio32(PLIC_M_ENABLE, LAST_SOURCE_BIT | 1u);
  check_or_halt(read_mmio32(PLIC_M_ENABLE) == LAST_SOURCE_BIT, 7);
  write_mmio32(PLIC_M_THRESHOLD, UINT32_MAX);
  check_or_halt(read_mmio32(PLIC_M_THRESHOLD) == 7, 8);

  /* IP 只读：软件写入不能充当中断注入后门。 */
  uint32_t pending_before = read_mmio32(PLIC_PENDING);
  write_mmio32(PLIC_PENDING, ~pending_before);
  check_or_halt(read_mmio32(PLIC_PENDING) == pending_before, 9);

  /* UART THRE 是真实 level 型 source；priority 0 时保留 pending 但不通知、不可 claim。 */
  write_mmio32(PLIC_PRIORITY1, 0);
  write_mmio32(PLIC_M_ENABLE, UART_SOURCE_BIT);
  write_mmio32(PLIC_M_THRESHOLD, 0);
  write_mmio8(UART_IER, 0x02);
  check_or_halt((read_mmio32(PLIC_PENDING) & UART_SOURCE_BIT) != 0, 10);
  check_or_halt((read_csr_mip() & MIP_MEIP) == 0, 11);
  check_or_halt(read_mmio32(PLIC_M_CLAIM) == 0, 12);

  /* enable=0 同样抑制 notification 与 claim，但不能清掉网关已转发的 pending。 */
  write_mmio32(PLIC_PRIORITY1, 1);
  write_mmio32(PLIC_M_ENABLE, 0);
  check_or_halt((read_csr_mip() & MIP_MEIP) == 0, 13);
  check_or_halt(read_mmio32(PLIC_M_CLAIM) == 0, 14);
  check_or_halt((read_mmio32(PLIC_PENDING) & UART_SOURCE_BIT) != 0, 15);

  /* priority == threshold 不产生通知；claim 只要求 priority > 0，不受 threshold 影响。 */
  write_mmio32(PLIC_M_ENABLE, UART_SOURCE_BIT);
  write_mmio32(PLIC_S_ENABLE, UART_SOURCE_BIT);
  write_mmio32(PLIC_M_THRESHOLD, 1);
  check_or_halt((read_csr_mip() & MIP_MEIP) == 0, 16);
  check_or_halt(read_mmio32(PLIC_M_CLAIM) == UART_SOURCE, 17);
  check_or_halt(read_mmio32(PLIC_M_CLAIM) == 0, 18);

  /* source 正由 M context 服务时，S context 的错误 completion 必须静默忽略。 */
  write_mmio32(PLIC_S_CLAIM, UART_SOURCE);
  check_or_halt((read_mmio32(PLIC_PENDING) & UART_SOURCE_BIT) == 0, 19);

  /* 即使 context 正确，软件先清 enable 后写 completion 也必须忽略。 */
  write_mmio32(PLIC_M_ENABLE, 0);
  write_mmio32(PLIC_M_CLAIM, UART_SOURCE);
  check_or_halt((read_mmio32(PLIC_PENDING) & UART_SOURCE_BIT) == 0, 20);
  write_mmio32(PLIC_M_ENABLE, UART_SOURCE_BIT);
  check_or_halt(read_mmio32(PLIC_M_CLAIM) == 0, 21);

  /* 正确 completion 结束 in-service；设备线仍高时网关立即重新置 pending。 */
  write_mmio32(PLIC_M_CLAIM, UART_SOURCE);
  check_or_halt((read_mmio32(PLIC_PENDING) & UART_SOURCE_BIT) != 0, 22);
  write_mmio32(PLIC_M_THRESHOLD, 0);
  check_or_halt((read_csr_mip() & MIP_MEIP) != 0, 23);
  check_or_halt(read_mmio32(PLIC_M_CLAIM) == UART_SOURCE, 24);

  /* 再次完成得到 pending 后撤销设备线：deassert 不能撤回已转发请求。 */
  write_mmio32(PLIC_M_CLAIM, UART_SOURCE);
  write_mmio8(UART_IER, 0);
  check_or_halt((read_mmio32(PLIC_PENDING) & UART_SOURCE_BIT) != 0, 25);
  pending_before = read_mmio32(PLIC_PENDING);
  write_mmio32(PLIC_PENDING, 0);
  check_or_halt(read_mmio32(PLIC_PENDING) == pending_before, 26);
  check_or_halt(read_mmio32(PLIC_M_CLAIM) == UART_SOURCE, 27);
  write_mmio32(PLIC_M_CLAIM, UART_SOURCE);
  check_or_halt((read_mmio32(PLIC_PENDING) & UART_SOURCE_BIT) == 0, 28);

  halt(0);
  return 0;
}

#else

int main() {
  halt(0);
  return 0;
}

#endif
