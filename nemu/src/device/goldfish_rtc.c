/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <device/map.h>
#include <isa.h>
#include <memory/host.h>
#include <utils.h>

#include <inttypes.h>
#include <stdio.h>
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
static uint64_t rtc_base_mtime;
static uint64_t latched_time_ns;
static uint64_t alarm_ns;
static bool alarm_running;
static bool irq_enabled;
static bool interrupt_pending;

static uint64_t host_realtime_ns(void) {
  struct timespec now;
  clock_gettime(CLOCK_REALTIME, &now);
  return (uint64_t)now.tv_sec * 1000000000ull + (uint64_t)now.tv_nsec;
}

static uint64_t goldfish_rtc_virtual_elapsed_ns(void) {
#ifdef CONFIG_ISA_riscv
  uint64_t ticks = isa_riscv_mtime_value() - rtc_base_mtime;
  uint64_t hz = isa_riscv_clint_timebase_hz();
  if (hz != 0) {
    return (ticks / hz) * 1000000000ull + (ticks % hz) * 1000000000ull / hz;
  }
#endif
  uint64_t host_us = get_time();
  return (host_us - rtc_base_host_us) * 1000ull;
}

static uint64_t goldfish_rtc_time_ns(void) {
  return rtc_base_ns + goldfish_rtc_virtual_elapsed_ns();
}

static void goldfish_rtc_set_time_ns(uint64_t value) {
  rtc_base_ns = value;
  rtc_base_host_us = get_time();
#ifdef CONFIG_ISA_riscv
  rtc_base_mtime = isa_riscv_mtime_value();
#endif
}

static const char *rtc_json_bool(bool value) {
  return value ? "true" : "false";
}

static void goldfish_rtc_raise_irq(void) {
  IFDEF(CONFIG_ISA_riscv,
      isa_riscv_plic_set_irq(GOLDFISH_RTC_IRQ, interrupt_pending && irq_enabled));
}

static void goldfish_rtc_fire_alarm(void) {
  alarm_running = false;
  interrupt_pending = true;
  goldfish_rtc_raise_irq();
}

static void goldfish_rtc_arm_alarm(void) {
  alarm_running = true;
  if (goldfish_rtc_time_ns() >= alarm_ns) {
    goldfish_rtc_fire_alarm();
  } else {
    goldfish_rtc_raise_irq();
  }
}

static void goldfish_rtc_update_alarm(void) {
  if (alarm_running && goldfish_rtc_time_ns() >= alarm_ns) {
    goldfish_rtc_fire_alarm();
    return;
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
      return irq_enabled ? 1u : 0u;
    case TIMER_ALARM_STATUS:
      return alarm_running ? 1u : 0u;
    default:
      return 0;
  }
}

static void goldfish_rtc_write_reg(uint32_t offset, uint32_t value) {
  switch (offset) {
    case TIMER_TIME_LOW:
      goldfish_rtc_set_time_ns((goldfish_rtc_time_ns() & 0xffffffff00000000ull) | value);
      break;
    case TIMER_TIME_HIGH:
      goldfish_rtc_set_time_ns(((uint64_t)value << 32) | (goldfish_rtc_time_ns() & 0xffffffffull));
      break;
    case TIMER_ALARM_LOW:
      alarm_ns = (alarm_ns & 0xffffffff00000000ull) | value;
      goldfish_rtc_arm_alarm();
      break;
    case TIMER_ALARM_HIGH:
      alarm_ns = ((uint64_t)value << 32) | (alarm_ns & 0xffffffffull);
      break;
    case TIMER_IRQ_ENABLED:
      irq_enabled = value != 0;
      break;
    case TIMER_CLEAR_ALARM:
      if (value != 0) {
        alarm_running = false;
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
  rtc_base_mtime = 0;
#ifdef CONFIG_ISA_riscv
  rtc_base_mtime = isa_riscv_mtime_value();
#endif
  latched_time_ns = rtc_base_ns;
  alarm_ns = 0;
  alarm_running = false;
  irq_enabled = false;
  interrupt_pending = false;

  goldfish_rtc_base = new_space(GOLDFISH_RTC_SIZE);
  add_mmio_map("goldfish-rtc", CONFIG_GOLDFISH_RTC_MMIO,
      goldfish_rtc_base, GOLDFISH_RTC_SIZE, goldfish_rtc_io_handler);
}

void goldfish_rtc_dump_machine_info(FILE *out) {
  // RTC 的存在不足以证明 Ubuntu 能拿到 wall-clock；这里固定导出模型、单位和 alarm 能力。
  fprintf(out, "device.goldfish_rtc.model=google,goldfish-rtc\n");
  fprintf(out, "device.goldfish_rtc.time_source=host-realtime-epoch+clint-mtime\n");
  fprintf(out, "device.goldfish_rtc.time_unit=ns\n");
  fprintf(out, "device.goldfish_rtc.virtual_timebase_hz=%" PRIu64 "\n",
      MUXDEF(CONFIG_ISA_riscv, isa_riscv_clint_timebase_hz(), 0ull));
  fprintf(out, "device.goldfish_rtc.mmio_size=0x%08x\n", GOLDFISH_RTC_SIZE);
  fprintf(out, "device.goldfish_rtc.alarm_supported=1\n");
  fprintf(out, "device.goldfish_rtc.alarm_enabled=%d\n",
      alarm_running ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.alarm_running=%d\n",
      alarm_running ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.irq_enabled=%d\n",
      irq_enabled ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.interrupt_pending=%d\n",
      interrupt_pending ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.interrupt_line=%d\n",
      (interrupt_pending && irq_enabled) ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.time_latch=low-then-high\n");
}

void goldfish_rtc_qmp_query_rtc(char *out, size_t out_size) {
  goldfish_rtc_update_alarm();
  uint64_t now_ns = goldfish_rtc_time_ns();
  snprintf(out, out_size,
      "{\"return\":[{\"id\":\"rtc0\",\"type\":\"goldfish-rtc\","
      "\"model\":\"google,goldfish-rtc\",\"nemu\":{\"mmio\":\"0x%08x\","
      "\"irq\":%u,\"time-source\":\"host-realtime-epoch+clint-mtime\","
      "\"time-unit\":\"ns\",\"virtual-timebase-hz\":%llu,"
      "\"current-ns\":%llu,\"alarm-ns\":%llu,"
      "\"alarm-supported\":true,\"alarm-enabled\":%s,"
      "\"alarm-running\":%s,\"irq-enabled\":%s,"
      "\"interrupt-pending\":%s,\"interrupt-line\":%s,"
      "\"time-latch\":\"low-then-high\"}}]}",
      CONFIG_GOLDFISH_RTC_MMIO, GOLDFISH_RTC_IRQ,
      (unsigned long long)MUXDEF(CONFIG_ISA_riscv, isa_riscv_clint_timebase_hz(), 0ull),
      (unsigned long long)now_ns, (unsigned long long)alarm_ns,
      rtc_json_bool(alarm_running), rtc_json_bool(alarm_running),
      rtc_json_bool(irq_enabled), rtc_json_bool(interrupt_pending),
      rtc_json_bool(interrupt_pending && irq_enabled));
}
