#include "trap.h"

#if defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)

#define CLINT_MTIME                  ((uintptr_t)0x0200bff8u)
#define PLIC_PENDING                 ((uintptr_t)0x0c001000u)
#define GOLDFISH_RTC_BASE            ((uintptr_t)0x10003000u)
#define GOLDFISH_RTC_TIME_LOW        (GOLDFISH_RTC_BASE + 0x00u)
#define GOLDFISH_RTC_TIME_HIGH       (GOLDFISH_RTC_BASE + 0x04u)
#define GOLDFISH_RTC_ALARM_LOW       (GOLDFISH_RTC_BASE + 0x08u)
#define GOLDFISH_RTC_ALARM_HIGH      (GOLDFISH_RTC_BASE + 0x0cu)
#define GOLDFISH_RTC_IRQ_ENABLED     (GOLDFISH_RTC_BASE + 0x10u)
#define GOLDFISH_RTC_CLEAR_ALARM     (GOLDFISH_RTC_BASE + 0x14u)
#define GOLDFISH_RTC_ALARM_STATUS    (GOLDFISH_RTC_BASE + 0x18u)
#define GOLDFISH_RTC_CLEAR_INTERRUPT (GOLDFISH_RTC_BASE + 0x1cu)
#define GOLDFISH_RTC_PLIC_SOURCE     4u
#define ONE_SECOND_NS                UINT64_C(1000000000)

static inline uint32_t mmio_read32(uintptr_t address) {
  return *(volatile uint32_t *)address;
}

static inline void mmio_write32(uintptr_t address, uint32_t value) {
  *(volatile uint32_t *)address = value;
}

static uint64_t clint_read_mtime(void) {
#if __riscv_xlen == 64
  return *(volatile uint64_t *)CLINT_MTIME;
#else
  uint32_t high_before;
  uint32_t low;
  uint32_t high_after;
  do {
    high_before = mmio_read32(CLINT_MTIME + 4);
    low = mmio_read32(CLINT_MTIME);
    high_after = mmio_read32(CLINT_MTIME + 4);
  } while (high_before != high_after);
  return ((uint64_t)high_after << 32) | low;
#endif
}

static void clint_write_mtime(uint64_t value) {
#if __riscv_xlen == 64
  *(volatile uint64_t *)CLINT_MTIME = value;
#else
  mmio_write32(CLINT_MTIME + 4, (uint32_t)(value >> 32));
  mmio_write32(CLINT_MTIME, (uint32_t)value);
#endif
}

/* TIME_LOW snapshots TIME_HIGH, so a complete read is low then high. */
static uint64_t goldfish_rtc_read_time(void) {
  const uint32_t low = mmio_read32(GOLDFISH_RTC_TIME_LOW);
  const uint32_t high = mmio_read32(GOLDFISH_RTC_TIME_HIGH);
  return ((uint64_t)high << 32) | low;
}

/* Each half write is immediate; high-then-low leaves the requested 64-bit value. */
static void goldfish_rtc_write_time(uint64_t value) {
  mmio_write32(GOLDFISH_RTC_TIME_HIGH, (uint32_t)(value >> 32));
  mmio_write32(GOLDFISH_RTC_TIME_LOW, (uint32_t)value);
}

static void goldfish_rtc_write_alarm(uint64_t value) {
  mmio_write32(GOLDFISH_RTC_ALARM_HIGH, (uint32_t)(value >> 32));
  mmio_write32(GOLDFISH_RTC_ALARM_LOW, (uint32_t)value);
}

static void check_or_halt(bool condition, int error_code) {
  if (!condition) halt(error_code);
}

int main(void) {
  const uint64_t saved_mtime = clint_read_mtime();
  const uint64_t saved_wall_time = goldfish_rtc_read_time();

  /*
   * A TIME_LOW read is the architectural snapshot point. A later write that
   * changes current TIME_HIGH must not change the already latched high word.
   */
  const uint64_t latch_probe = UINT64_C(0x1234567820000000);
  goldfish_rtc_write_time(latch_probe);
  const uint32_t latched_low = mmio_read32(GOLDFISH_RTC_TIME_LOW);
  (void)latched_low;
  mmio_write32(GOLDFISH_RTC_TIME_HIGH, UINT32_C(0x87654321));
  check_or_halt(mmio_read32(GOLDFISH_RTC_TIME_HIGH) == UINT32_C(0x12345678), 2);

  goldfish_rtc_write_time(saved_wall_time);
  const uint64_t before_rollback = goldfish_rtc_read_time();

  /* Start with no stale alarm level or gateway request. */
  mmio_write32(GOLDFISH_RTC_CLEAR_ALARM, 1);
  mmio_write32(GOLDFISH_RTC_CLEAR_INTERRUPT, 1);
  mmio_write32(GOLDFISH_RTC_IRQ_ENABLED, 1);
  check_or_halt(
      (mmio_read32(PLIC_PENDING) & (1u << GOLDFISH_RTC_PLIC_SOURCE)) == 0, 3);

  goldfish_rtc_write_alarm(before_rollback + ONE_SECOND_NS);
  check_or_halt(mmio_read32(GOLDFISH_RTC_ALARM_STATUS) == 1, 4);

  /*
   * mtime is writable. Rolling it back is a clock rebase, not unsigned elapsed
   * time; RTC must stay monotonic and a future alarm must not fire immediately.
   */
  clint_write_mtime(0);
  const uint64_t after_rollback = goldfish_rtc_read_time();
  check_or_halt(after_rollback >= before_rollback, 5);
  check_or_halt(after_rollback - before_rollback < ONE_SECOND_NS, 6);
  check_or_halt(mmio_read32(GOLDFISH_RTC_ALARM_STATUS) == 1, 7);
  check_or_halt(
      (mmio_read32(PLIC_PENDING) & (1u << GOLDFISH_RTC_PLIC_SOURCE)) == 0, 8);

  mmio_write32(GOLDFISH_RTC_CLEAR_ALARM, 1);
  mmio_write32(GOLDFISH_RTC_CLEAR_INTERRUPT, 1);
  mmio_write32(GOLDFISH_RTC_IRQ_ENABLED, 0);
  clint_write_mtime(saved_mtime);
  goldfish_rtc_write_time(saved_wall_time);

  halt(0);
  return 0;
}

#else

int main(void) {
  halt(0);
  return 0;
}

#endif
