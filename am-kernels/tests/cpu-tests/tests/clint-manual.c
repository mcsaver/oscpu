#include "trap.h"

#if defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)

#define CLINT_BASE       0x02000000ul
#define CLINT_SIZE       0x00010000ul
#define CLINT_MSIP       (CLINT_BASE + 0x0000ul)
#define CLINT_MTIMECMP   (CLINT_BASE + 0x4000ul)
#define CLINT_MTIME      (CLINT_BASE + 0xbff8ul)

#define MIP_MSIP         (1ul << 3)
#define MIP_MTIP         (1ul << 7)
#define MSTATUS_MIE      (1ul << 3)

#if defined(__ISA_RISCV64__)
#define CLINT_REG_STORE "sd"
#else
#define CLINT_REG_STORE "sw"
#endif

volatile uintptr_t clint_fault_count;
volatile uintptr_t clint_fault_cause;
volatile uintptr_t clint_fault_tval;

extern void clint_access_trap(void);

asm(
".option push\n"
".option norvc\n"
".balign 4\n"
".globl clint_access_trap\n"
"clint_access_trap:\n"
"  csrr t0, mcause\n"
"  la t1, clint_fault_cause\n"
"  " CLINT_REG_STORE " t0, 0(t1)\n"
"  csrr t0, mtval\n"
"  la t1, clint_fault_tval\n"
"  " CLINT_REG_STORE " t0, 0(t1)\n"
"  la t1, clint_fault_count\n"
"  li t0, 1\n"
"  " CLINT_REG_STORE " t0, 0(t1)\n"
"  csrr t0, mepc\n"
"  addi t0, t0, 4\n"
"  csrw mepc, t0\n"
"  mret\n"
".option pop\n"
);

static inline uint32_t read_mmio32(uintptr_t address) {
  return *(volatile uint32_t *)address;
}

static inline void write_mmio32(uintptr_t address, uint32_t value) {
  *(volatile uint32_t *)address = value;
}

#if defined(__ISA_RISCV64__)
static inline uint64_t read_mmio64(uintptr_t address) {
  return *(volatile uint64_t *)address;
}

static inline void write_mmio64(uintptr_t address, uint64_t value) {
  *(volatile uint64_t *)address = value;
}
#endif

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

static inline uintptr_t read_csr_mie(void) {
  uintptr_t value;
  asm volatile("csrr %0, mie" : "=r"(value));
  return value;
}

static inline void write_csr_mie(uintptr_t value) {
  asm volatile("csrw mie, %0" : : "r"(value) : "memory");
}

static inline uintptr_t read_csr_mstatus(void) {
  uintptr_t value;
  asm volatile("csrr %0, mstatus" : "=r"(value));
  return value;
}

static inline void write_csr_mstatus(uintptr_t value) {
  asm volatile("csrw mstatus, %0" : : "r"(value) : "memory");
}

static inline void write_csr_mtvec(uintptr_t value) {
  asm volatile("csrw mtvec, %0" : : "r"(value) : "memory");
}

static inline void disable_machine_interrupt_delivery(void) {
  uintptr_t mask = MSTATUS_MIE;
  asm volatile(
      "csrw mie, zero\n"
      "csrc mstatus, %0"
      : : "r"(mask) : "memory");
}

static uint64_t read_mtime_halves(void) {
  uint32_t high_before;
  uint32_t low;
  uint32_t high_after;
  do {
    high_before = read_mmio32(CLINT_MTIME + 4);
    low = read_mmio32(CLINT_MTIME);
    high_after = read_mmio32(CLINT_MTIME + 4);
  } while (high_before != high_after);
  return ((uint64_t)high_after << 32) | low;
}

static uint64_t read_time_csr(void) {
#if defined(__ISA_RISCV64__)
  uintptr_t value;
  asm volatile("csrr %0, time" : "=r"(value));
  return value;
#else
  uint32_t high_before;
  uint32_t low;
  uint32_t high_after;
  do {
    asm volatile("csrr %0, timeh" : "=r"(high_before));
    asm volatile("csrr %0, time" : "=r"(low));
    asm volatile("csrr %0, timeh" : "=r"(high_after));
  } while (high_before != high_after);
  return ((uint64_t)high_after << 32) | low;
#endif
}

static void write_mtime(uint64_t value) {
#if defined(__ISA_RISCV64__)
  write_mmio64(CLINT_MTIME, value);
#else
  /* RV32 通过两个自然对齐 word 组成 mtime；最后写 low 固定最终低半。 */
  write_mmio32(CLINT_MTIME + 4, (uint32_t)(value >> 32));
  write_mmio32(CLINT_MTIME, (uint32_t)value);
#endif
}

static void write_mtimecmp(uint64_t value) {
#if defined(__ISA_RISCV64__)
  write_mmio64(CLINT_MTIMECMP, value);
#else
  /*
   * RV32 手册推荐三写序列：先把 low 写成全 1，更新 high，最后写目标 low，
   * 从而避免拆分更新期间短暂满足 mtime >= mtimecmp。
   */
  write_mmio32(CLINT_MTIMECMP, UINT32_MAX);
  write_mmio32(CLINT_MTIMECMP + 4, (uint32_t)(value >> 32));
  write_mmio32(CLINT_MTIMECMP, (uint32_t)value);
#endif
}

static uint64_t read_mtimecmp(void) {
#if defined(__ISA_RISCV64__)
  return read_mmio64(CLINT_MTIMECMP);
#else
  uint32_t low = read_mmio32(CLINT_MTIMECMP);
  uint32_t high = read_mmio32(CLINT_MTIMECMP + 4);
  return ((uint64_t)high << 32) | low;
#endif
}

static void check_or_halt(bool condition, int code) {
  if (!condition) halt(code);
}

static void clear_fault_record(void) {
  clint_fault_count = 0;
  clint_fault_cause = 0;
  clint_fault_tval = 0;
}

static void check_fault(uintptr_t cause, uintptr_t address, int code) {
  (void)address;
  check_or_halt(clint_fault_count == 1, code);
  check_or_halt(clint_fault_cause == cause, code + 1);
}

static void expect_load_byte_fault(uintptr_t address, int code) {
  clear_fault_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lbu zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_fault(5, address, code);
}

static void expect_load_half_fault(uintptr_t address, int code) {
  clear_fault_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lhu zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_fault(5, address, code);
}

static void expect_load_word_fault(uintptr_t address, int code) {
  clear_fault_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "lw zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_fault(5, address, code);
}

static void expect_store_byte_fault(uintptr_t address, int code) {
  clear_fault_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sb zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_fault(7, address, code);
}

static void expect_store_half_fault(uintptr_t address, int code) {
  clear_fault_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sh zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_fault(7, address, code);
}

static void expect_store_word_fault(uintptr_t address, int code) {
  clear_fault_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sw zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_fault(7, address, code);
}

#if defined(__ISA_RISCV64__)
static void expect_load_double_fault(uintptr_t address, int code) {
  clear_fault_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "ld zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_fault(5, address, code);
}

static void expect_store_double_fault(uintptr_t address, int code) {
  clear_fault_record();
  asm volatile(
      ".option push\n"
      ".option norvc\n"
      "sd zero, 0(%0)\n"
      ".option pop\n"
      : : "r"(address) : "t0", "t1", "memory");
  check_fault(7, address, code);
}
#endif

static void check_access_contract(void) {
  uintptr_t old_mtvec = read_csr_mtvec();
  write_csr_mtvec((uintptr_t)clint_access_trap);

  /* byte/half、未对齐 word、保留 offset 和跨 aperture 都必须抬 access-fault。 */
  expect_load_byte_fault(CLINT_MSIP, 40);
  expect_load_half_fault(CLINT_MSIP, 43);
  expect_load_word_fault(CLINT_MTIMECMP + 2, 46);
  expect_load_word_fault(CLINT_BASE + 4, 49);
  expect_load_word_fault(CLINT_BASE + CLINT_SIZE - 2, 52);
  expect_store_byte_fault(CLINT_MSIP, 55);
  expect_store_half_fault(CLINT_MSIP, 58);
  expect_store_word_fault(CLINT_MTIMECMP + 2, 61);
  expect_store_word_fault(CLINT_BASE + 4, 64);
  expect_store_word_fault(CLINT_BASE + CLINT_SIZE - 2, 67);

#if defined(__ISA_RISCV64__)
  /* RV64 只在 mtime/mtimecmp 起始地址接受自然对齐 full 64-bit 事务。 */
  expect_load_double_fault(CLINT_MSIP, 70);
  expect_load_double_fault(CLINT_MTIMECMP + 4, 73);
  expect_store_double_fault(CLINT_MSIP, 76);
  expect_store_double_fault(CLINT_MTIME + 4, 79);
#endif

  write_csr_mtvec(old_mtvec);
}

int main(void) {
  uintptr_t original_mie = read_csr_mie();
  uintptr_t original_mstatus = read_csr_mstatus();
  disable_machine_interrupt_delivery();
  write_mmio32(CLINT_MSIP, 0);
  write_mtimecmp(UINT64_MAX);

  /* msip[0] 是唯一 WARL 位；mip.MSIP 只能由设备寄存器驱动。 */
  write_mmio32(CLINT_MSIP, UINT32_MAX);
  check_or_halt(read_mmio32(CLINT_MSIP) == 1, 2);
  check_or_halt((read_csr_mip() & MIP_MSIP) != 0, 3);
  asm volatile("csrc mip, %0" : : "r"((uintptr_t)MIP_MSIP) : "memory");
  check_or_halt((read_csr_mip() & MIP_MSIP) != 0, 4);
  write_mmio32(CLINT_MSIP, 0);
  check_or_halt((read_csr_mip() & MIP_MSIP) == 0, 5);
  asm volatile("csrs mip, %0" : : "r"((uintptr_t)MIP_MSIP) : "memory");
  check_or_halt((read_csr_mip() & MIP_MSIP) == 0, 6);

  /*
   * WFI 看 locally enabled pending，不看 mstatus.MIE：MSIE=1、MIE=0 且
   * MSIP pending 时必须立即恢复，不能错误快进到较远 timer deadline。
   */
  uint64_t local_wakeup_now = read_mtime_halves();
  uint64_t local_wakeup_deadline = local_wakeup_now + UINT64_C(1000000);
  write_mtimecmp(local_wakeup_deadline);
  write_csr_mie(MIP_MSIP);
  write_mmio32(CLINT_MSIP, 1);
  check_or_halt((read_csr_mstatus() & MSTATUS_MIE) == 0, 21);
  asm volatile("wfi" : : : "memory");
  uint64_t local_wakeup_after = read_mtime_halves();
  check_or_halt(local_wakeup_after < local_wakeup_deadline, 20);
  write_mmio32(CLINT_MSIP, 0);
  write_csr_mie(original_mie);
  write_csr_mstatus(original_mstatus);
  disable_machine_interrupt_delivery();

  /* 4-byte halves 在两种 XLEN 都合法；RV64 的 full read/write 也必须同值。 */
  const uint64_t compare_pattern = UINT64_C(0x89abcdef01234567);
  write_mtimecmp(compare_pattern);
  check_or_halt(read_mtimecmp() == compare_pattern, 7);
  check_or_halt(read_mmio32(CLINT_MTIMECMP) == UINT32_C(0x01234567), 8);
  check_or_halt(read_mmio32(CLINT_MTIMECMP + 4) == UINT32_C(0x89abcdef), 9);
#if defined(__ISA_RISCV64__)
  check_or_halt(read_mmio64(CLINT_MTIMECMP) == compare_pattern, 10);
#endif

  /* mtime 的 MMIO 与 CSR time 是同一时间源；只断言单调关系，不绑定宿主墙钟精度。 */
  const uint64_t time_pattern = UINT64_C(0x0000000212345000);
  write_mtime(time_pattern);
  uint64_t mmio_time = read_mtime_halves();
  uint64_t csr_time = read_time_csr();
  check_or_halt(mmio_time >= time_pattern, 11);
  check_or_halt(csr_time >= mmio_time, 12);
#if defined(__ISA_RISCV64__)
  check_or_halt(read_mmio64(CLINT_MTIME) >= csr_time, 13);
#endif

  /* future 不 pending；equal/past pending；重写 future 立即撤销由比较器派生的 MTIP。 */
  uint64_t now = read_mtime_halves();
  write_mtimecmp(now + UINT64_C(1000000));
  check_or_halt((read_csr_mip() & MIP_MTIP) == 0, 14);
  now = read_mtime_halves();
  write_mtimecmp(now);
  check_or_halt((read_csr_mip() & MIP_MTIP) != 0, 15);
  write_mtimecmp(0);
  check_or_halt((read_csr_mip() & MIP_MTIP) != 0, 16);
  write_mtimecmp(UINT64_MAX);
  check_or_halt((read_csr_mip() & MIP_MTIP) == 0, 17);

  /* delta=1/已到期的 WFI 必须有界返回。 */
  now = read_mtime_halves();
  write_mtimecmp(now + 1);
  asm volatile("wfi" : : : "memory");
  check_or_halt((read_csr_mip() & MIP_MTIP) != 0, 18);

  /* 较远 deadline 下 WFI 仍必须在有限次提示内等到同一个 mtimecmp 比较器。 */
  write_mtimecmp(UINT64_MAX);
  now = read_mtime_halves();
  write_mtimecmp(now + UINT64_C(100000));
  for (int attempt = 0;
       attempt < 32 && (read_csr_mip() & MIP_MTIP) == 0; attempt++) {
    asm volatile("wfi" : : : "memory");
  }
  check_or_halt((read_csr_mip() & MIP_MTIP) != 0, 19);
  write_mtimecmp(UINT64_MAX);

  check_access_contract();
  halt(0);
  return 0;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif
