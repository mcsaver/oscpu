#include <am.h>
#include <nemu.h>

static uint64_t bool_time = 0;

static uint64_t read_time() {
#if defined(__riscv) && !defined(DEVICE_MAP_LEGACY)
  // 统一到设备树 goldfish-rtc: 先读 TIME_LOW(0x0) 锁存当前纳秒, 再读 TIME_HIGH(0x4) 取锁存高位。
  // goldfish 返回纳秒, AM timer 的 uptime 语义是微秒, 故 /1000。
  uint32_t lo = inl(GOLDFISH_RTC_ADDR + 0x0);
  uint32_t hi = inl(GOLDFISH_RTC_ADDR + 0x4);
  return (((uint64_t)hi << 32) | lo) / 1000ull;
#else
  uint32_t hi = inl(RTC_ADDR + 4);
  uint32_t lo = inl(RTC_ADDR);
  return ((uint64_t)hi << 32) | lo;
#endif
}

void __am_timer_init() {
  bool_time = read_time();
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = read_time() - bool_time;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  uint64_t seconds = read_time() / 1000000;

  rtc->second = seconds % 60;
  rtc->minute = (seconds / 60) % 60;
  rtc->hour   = (seconds / 3600) % 24;
  rtc->day    = 1 + (seconds / 86400);
  rtc->month  = 1;
  rtc->year   = 1900;
}
