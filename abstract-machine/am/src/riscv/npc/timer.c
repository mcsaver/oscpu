#include <am.h>

#include "npc.h"

static uint64_t boot_time = 0;

static uint64_t read_time() {
  uint32_t hi = inl(RTC_ADDR + 4);
  uint32_t lo = inl(RTC_ADDR);
  return ((uint64_t)hi << 32) | lo;
}

void __am_timer_init() {
  // 先复用最小 RTC MMIO，把 uptime 跑通，后面真做 mtime/mtimecmp 时再把这层替换成更完整的平台时钟。
  boot_time = read_time();
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = read_time() - boot_time;
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
