#include <am.h>
#include <nemu.h>

static uint64_t bool_time = 0;

static uint64_t read_time() {
  uint32_t hi = inl(RTC_ADDR + 4);
  uint32_t lo = inl(RTC_ADDR);
  return ((uint64_t)hi << 32) | lo;
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
