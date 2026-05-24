#include <am.h>

#include "ysyxsoc.h"

static uint64_t read_mtime_raw() {
  uint32_t hi0, lo, hi1;
  do {
    hi0 = inl(YSYXSOC_CLINT_MTIME + 4);
    lo = inl(YSYXSOC_CLINT_MTIME);
    hi1 = inl(YSYXSOC_CLINT_MTIME + 4);
  } while (hi0 != hi1);
  return ((uint64_t)hi1 << 32) | lo;
}

static uint64_t read_time_us() {
  // 当前 npc/soc 与 NEMU SoC reference 都提供 CLINT-like mtime；频率差异用宏留给后续板级配置覆盖。
  return read_mtime_raw() / YSYXSOC_MTIME_TICKS_PER_US;
}

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = read_time_us();
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
