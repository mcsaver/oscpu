/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <device/map.h>
#include <isa.h>
#include <memory/host.h>
#include <utils.h>

#include <time.h>

// Ubuntu 用户态需要一个运行期 wall-clock RTC；goldfish-rtc 是 Linux 已有的
// 简单 platform driver，比继续依赖指令数驱动的 mtime 更接近真实 VM 平台语义。
#define GOLDFISH_RTC_SIZE 0x1000u
#define GOLDFISH_RTC_IRQ 4u

#define TIMER_TIME_LOW        0x00u
#define TIMER_TIME_HIGH       0x04u
#define TIMER_ALARM_LOW       0x08u
#define TIMER_ALARM_HIGH      0x0cu
#define TIMER_IRQ_ENABLED     0x10u
#define TIMER_CLEAR_ALARM     0x14u
#define TIMER_ALARM_STATUS    0x18u
#define TIMER_CLEAR_INTERRUPT 0x1cu

static uint8_t *goldfish_rtc_base;
static uint64_t rtc_base_ns;
static uint64_t rtc_base_host_us;
static uint64_t latched_time_ns;
static uint64_t alarm_ns;
static bool alarm_enabled;
static bool interrupt_pending;

static uint64_t host_realtime_ns(void) {
  struct timespec now;
  clock_gettime(CLOCK_REALTIME, &now);
  return (uint64_t)now.tv_sec * 1000000000ull + (uint64_t)now.tv_nsec;
}

static uint64_t goldfish_rtc_time_ns(void) {
  uint64_t host_us = get_time();
  return rtc_base_ns + (host_us - rtc_base_host_us) * 1000ull;
}

static void goldfish_rtc_raise_irq(void) {
  IFDEF(CONFIG_ISA_riscv,
      isa_riscv32_plic_set_irq(GOLDFISH_RTC_IRQ, interrupt_pending));
}

static void goldfish_rtc_update_alarm(void) {
  if (alarm_enabled && goldfish_rtc_time_ns() >= alarm_ns) {
    alarm_enabled = false;
    interrupt_pending = true;
  }
  goldfish_rtc_raise_irq();
}

static uint32_t goldfish_rtc_read_reg(uint32_t offset) {
  goldfish_rtc_update_alarm();

  switch (offset) {
    case TIMER_TIME_LOW:
      latched_time_ns = goldfish_rtc_time_ns();
      return (uint32_t)latched_time_ns;
    case TIMER_TIME_HIGH:
      return (uint32_t)(latched_time_ns >> 32);
    case TIMER_ALARM_LOW:
      return (uint32_t)alarm_ns;
    case TIMER_ALARM_HIGH:
      return (uint32_t)(alarm_ns >> 32);
    case TIMER_IRQ_ENABLED:
      return alarm_enabled ? 1u : 0u;
    case TIMER_ALARM_STATUS:
      return alarm_enabled ? 1u : 0u;
    default:
      return 0;
  }
}

static void goldfish_rtc_write_reg(uint32_t offset, uint32_t value) {
  switch (offset) {
    case TIMER_TIME_LOW:
      rtc_base_ns = (rtc_base_ns & 0xffffffff00000000ull) | value;
      rtc_base_host_us = get_time();
      break;
    case TIMER_TIME_HIGH:
      rtc_base_ns = ((uint64_t)value << 32) | (rtc_base_ns & 0xffffffffull);
      rtc_base_host_us = get_time();
      break;
    case TIMER_ALARM_LOW:
      alarm_ns = (alarm_ns & 0xffffffff00000000ull) | value;
      alarm_enabled = true;
      break;
    case TIMER_ALARM_HIGH:
      alarm_ns = ((uint64_t)value << 32) | (alarm_ns & 0xffffffffull);
      break;
    case TIMER_IRQ_ENABLED:
      alarm_enabled = value != 0;
      break;
    case TIMER_CLEAR_ALARM:
      if (value != 0) {
        alarm_enabled = false;
        interrupt_pending = false;
      }
      break;
    case TIMER_CLEAR_INTERRUPT:
      if (value != 0) interrupt_pending = false;
      break;
    default:
      break;
  }

  goldfish_rtc_update_alarm();
}

static void goldfish_rtc_io_handler(uint32_t offset, int len, bool is_write) {
  if (len <= 0 || offset >= GOLDFISH_RTC_SIZE) return;

  if (is_write) {
    if (len == 4) {
      goldfish_rtc_write_reg(offset, host_read(goldfish_rtc_base + offset, 4));
    } else if (len == 8) {
      goldfish_rtc_write_reg(offset, host_read(goldfish_rtc_base + offset, 4));
      goldfish_rtc_write_reg(offset + 4, host_read(goldfish_rtc_base + offset + 4, 4));
    }
    return;
  }

  if (len == 8) {
    host_write(goldfish_rtc_base + offset, 4, goldfish_rtc_read_reg(offset));
    host_write(goldfish_rtc_base + offset + 4, 4, goldfish_rtc_read_reg(offset + 4));
  } else {
    host_write(goldfish_rtc_base + offset, len, goldfish_rtc_read_reg(offset));
  }
}

void goldfish_rtc_update() {
  goldfish_rtc_update_alarm();
}

void init_goldfish_rtc() {
  rtc_base_ns = host_realtime_ns();
  rtc_base_host_us = get_time();
  latched_time_ns = rtc_base_ns;
  alarm_ns = 0;
  alarm_enabled = false;
  interrupt_pending = false;

  goldfish_rtc_base = new_space(GOLDFISH_RTC_SIZE);
  add_mmio_map("goldfish-rtc", CONFIG_GOLDFISH_RTC_MMIO,
      goldfish_rtc_base, GOLDFISH_RTC_SIZE, goldfish_rtc_io_handler);
}
