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

#define GOLDFISH_RTC_SIZE 0x1000u
#define GOLDFISH_RTC_IRQ 4u

/* Register names and write actions follow the goldfish timer specification. */
typedef enum {
  GOLDFISH_RTC_TIME_LOW        = 0x00u,
  GOLDFISH_RTC_TIME_HIGH       = 0x04u,
  GOLDFISH_RTC_ALARM_LOW       = 0x08u,
  GOLDFISH_RTC_ALARM_HIGH      = 0x0cu,
  GOLDFISH_RTC_IRQ_ENABLED     = 0x10u,
  GOLDFISH_RTC_CLEAR_ALARM     = 0x14u,
  GOLDFISH_RTC_ALARM_STATUS    = 0x18u,
  GOLDFISH_RTC_CLEAR_INTERRUPT = 0x1cu,
} GoldfishRtcRegister;

#define GOLDFISH_RTC_REG32(reg_name, reg_offset, access) \
  { \
    .name = (reg_name), \
    .first_offset = (reg_offset), \
    .last_offset = (reg_offset) + 3u, \
    .stride = 4u, \
    .width_mask = IO_WIDTH_4, \
    .direction_mask = (access), \
    .naturally_aligned = true, \
  }

static const IoRegisterDescriptor goldfish_rtc_registers[] = {
  GOLDFISH_RTC_REG32("TIME_LOW", GOLDFISH_RTC_TIME_LOW,
      IO_TRANSACTION_READ | IO_TRANSACTION_WRITE),
  GOLDFISH_RTC_REG32("TIME_HIGH", GOLDFISH_RTC_TIME_HIGH,
      IO_TRANSACTION_READ | IO_TRANSACTION_WRITE),
  GOLDFISH_RTC_REG32("ALARM_LOW", GOLDFISH_RTC_ALARM_LOW,
      IO_TRANSACTION_READ | IO_TRANSACTION_WRITE),
  GOLDFISH_RTC_REG32("ALARM_HIGH", GOLDFISH_RTC_ALARM_HIGH,
      IO_TRANSACTION_READ | IO_TRANSACTION_WRITE),
  GOLDFISH_RTC_REG32("IRQ_ENABLED", GOLDFISH_RTC_IRQ_ENABLED,
      IO_TRANSACTION_WRITE),
  GOLDFISH_RTC_REG32("CLEAR_ALARM", GOLDFISH_RTC_CLEAR_ALARM,
      IO_TRANSACTION_WRITE),
  GOLDFISH_RTC_REG32("ALARM_STATUS", GOLDFISH_RTC_ALARM_STATUS,
      IO_TRANSACTION_READ),
  GOLDFISH_RTC_REG32("CLEAR_INTERRUPT", GOLDFISH_RTC_CLEAR_INTERRUPT,
      IO_TRANSACTION_WRITE),
};

static const IoAccessPolicy goldfish_rtc_mmio_policy = {
  .registers = goldfish_rtc_registers,
  .register_count = ARRLEN(goldfish_rtc_registers),
};

#undef GOLDFISH_RTC_REG32

typedef struct {
  uint8_t *mmio_space;

  /* current_time = epoch_base + elapsed_virtual_time */
  uint64_t epoch_base_ns;
  uint64_t epoch_base_host_us;
  uint64_t epoch_base_mtime;
  uint64_t last_observed_time_ns;
  uint64_t virtual_clock_rebases;

  /* Reading TIME_LOW snapshots TIME_HIGH for a coherent 64-bit read. */
  uint64_t time_read_latch_ns;

  uint64_t alarm_time_ns;
  bool alarm_armed;
  bool interrupt_enabled;
  bool interrupt_pending;
} GoldfishRtcState;

static GoldfishRtcState goldfish_rtc;

static uint64_t host_realtime_ns(void) {
  struct timespec now;
  clock_gettime(CLOCK_REALTIME, &now);
  return (uint64_t)now.tv_sec * 1000000000ull + (uint64_t)now.tv_nsec;
}

static uint64_t goldfish_rtc_saturating_add_ns(
    uint64_t base_ns, uint64_t elapsed_ns) {
  return elapsed_ns > UINT64_MAX - base_ns
      ? UINT64_MAX : base_ns + elapsed_ns;
}

static uint64_t goldfish_rtc_ticks_to_ns(uint64_t ticks, uint64_t hz) {
  if (hz == 0) return 0;
  const uint64_t seconds = ticks / hz;
  if (seconds > UINT64_MAX / 1000000000ull) return UINT64_MAX;
  const uint64_t whole_ns = seconds * 1000000000ull;
  const uint64_t remainder_ticks = ticks % hz;
  /*
   * remainder_ticks < hz，所以小数秒必然小于 1e9 ns。中间乘积仍可能
   * 超过 64 位；用宿主的宽整数表达手册中的 floor(remainder * 1e9 / hz)，
   * 避免先截断或用会再次溢出的等价式。
   */
  const uint64_t remainder_ns = (uint64_t)(
      ((__uint128_t)remainder_ticks * 1000000000ull) / hz);
  return goldfish_rtc_saturating_add_ns(whole_ns, remainder_ns);
}

static uint64_t goldfish_rtc_virtual_elapsed_ns(
    GoldfishRtcState *rtc) {
#ifdef CONFIG_ISA_riscv
  const uint64_t now_mtime = isa_riscv_mtime_value();
  const uint64_t hz = isa_riscv_clint_timebase_hz();
  if (hz != 0) {
    if (now_mtime < rtc->epoch_base_mtime) {
      /*
       * mtime 是可写寄存器；回拨不是 uint64 subtraction underflow。
       * Goldfish wall clock 在最近一次可观察值上重新建立 epoch，随后继续走时。
       */
      rtc->epoch_base_ns = rtc->last_observed_time_ns;
      rtc->epoch_base_mtime = now_mtime;
      rtc->epoch_base_host_us = get_time();
      rtc->virtual_clock_rebases++;
      return 0;
    }
    return goldfish_rtc_ticks_to_ns(now_mtime - rtc->epoch_base_mtime, hz);
  }
#endif
  const uint64_t host_us = get_time();
  if (host_us < rtc->epoch_base_host_us) {
    rtc->epoch_base_ns = rtc->last_observed_time_ns;
    rtc->epoch_base_host_us = host_us;
    rtc->virtual_clock_rebases++;
    return 0;
  }
  const uint64_t elapsed_us = host_us - rtc->epoch_base_host_us;
  return elapsed_us > UINT64_MAX / 1000ull
      ? UINT64_MAX : elapsed_us * 1000ull;
}

static uint64_t goldfish_rtc_current_time_ns(GoldfishRtcState *rtc) {
  uint64_t current = goldfish_rtc_saturating_add_ns(
      rtc->epoch_base_ns, goldfish_rtc_virtual_elapsed_ns(rtc));
  if (current < rtc->last_observed_time_ns) {
    /* 覆盖仍高于 epoch_base、但低于最近观测点的 mtime 回拨。 */
    current = rtc->last_observed_time_ns;
    rtc->epoch_base_ns = current;
    rtc->epoch_base_host_us = get_time();
#ifdef CONFIG_ISA_riscv
    rtc->epoch_base_mtime = isa_riscv_mtime_value();
#endif
    rtc->virtual_clock_rebases++;
  }
  rtc->last_observed_time_ns = current;
  return current;
}

static void goldfish_rtc_set_current_time_ns(
    GoldfishRtcState *rtc, uint64_t value) {
  rtc->epoch_base_ns = value;
  rtc->epoch_base_host_us = get_time();
  /* guest 显式写 TIME 寄存器可以重设墙钟，包括向后设置。 */
  rtc->last_observed_time_ns = value;
#ifdef CONFIG_ISA_riscv
  rtc->epoch_base_mtime = isa_riscv_mtime_value();
#endif
}

static const char *rtc_json_bool(bool value) {
  return value ? "true" : "false";
}

static bool goldfish_rtc_interrupt_line_asserted(
    const GoldfishRtcState *rtc) {
  return rtc->interrupt_pending && rtc->interrupt_enabled;
}

static void goldfish_rtc_update_interrupt_line(const GoldfishRtcState *rtc) {
  IFDEF(CONFIG_ISA_riscv,
      isa_riscv_plic_set_irq(
          GOLDFISH_RTC_IRQ, goldfish_rtc_interrupt_line_asserted(rtc)));
}

static void goldfish_rtc_signal_alarm(GoldfishRtcState *rtc) {
  rtc->alarm_armed = false;
  rtc->interrupt_pending = true;
  goldfish_rtc_update_interrupt_line(rtc);
}

/* Writing ALARM_LOW commits the programmed 64-bit deadline and arms it. */
static void goldfish_rtc_arm_alarm(GoldfishRtcState *rtc) {
  rtc->alarm_armed = true;
  if (goldfish_rtc_current_time_ns(rtc) >= rtc->alarm_time_ns) {
    goldfish_rtc_signal_alarm(rtc);
  } else {
    goldfish_rtc_update_interrupt_line(rtc);
  }
}

static void goldfish_rtc_evaluate_alarm(GoldfishRtcState *rtc) {
  if (rtc->alarm_armed &&
      goldfish_rtc_current_time_ns(rtc) >= rtc->alarm_time_ns) {
    goldfish_rtc_signal_alarm(rtc);
    return;
  }
  goldfish_rtc_update_interrupt_line(rtc);
}

static uint32_t goldfish_rtc_read_register(
    GoldfishRtcState *rtc, GoldfishRtcRegister reg) {
  goldfish_rtc_evaluate_alarm(rtc);

  switch (reg) {
    case GOLDFISH_RTC_TIME_LOW:
      rtc->time_read_latch_ns = goldfish_rtc_current_time_ns(rtc);
      return (uint32_t)rtc->time_read_latch_ns;
    case GOLDFISH_RTC_TIME_HIGH:
      return (uint32_t)(rtc->time_read_latch_ns >> 32);
    case GOLDFISH_RTC_ALARM_LOW:
      return (uint32_t)rtc->alarm_time_ns;
    case GOLDFISH_RTC_ALARM_HIGH:
      return (uint32_t)(rtc->alarm_time_ns >> 32);
    case GOLDFISH_RTC_IRQ_ENABLED:
      return rtc->interrupt_enabled ? 1u : 0u;
    case GOLDFISH_RTC_ALARM_STATUS:
      return rtc->alarm_armed ? 1u : 0u;
    default:
      return 0;
  }
}

static void goldfish_rtc_write_register(
    GoldfishRtcState *rtc, GoldfishRtcRegister reg, uint32_t value) {
  switch (reg) {
    case GOLDFISH_RTC_TIME_LOW:
      goldfish_rtc_set_current_time_ns(
          rtc, (goldfish_rtc_current_time_ns(rtc) & 0xffffffff00000000ull) |
                   value);
      break;
    case GOLDFISH_RTC_TIME_HIGH:
      goldfish_rtc_set_current_time_ns(
          rtc, ((uint64_t)value << 32) |
                   (goldfish_rtc_current_time_ns(rtc) & 0xffffffffull));
      break;
    case GOLDFISH_RTC_ALARM_LOW:
      rtc->alarm_time_ns =
          (rtc->alarm_time_ns & 0xffffffff00000000ull) | value;
      goldfish_rtc_arm_alarm(rtc);
      break;
    case GOLDFISH_RTC_ALARM_HIGH:
      rtc->alarm_time_ns =
          ((uint64_t)value << 32) | (rtc->alarm_time_ns & 0xffffffffull);
      break;
    case GOLDFISH_RTC_IRQ_ENABLED:
      rtc->interrupt_enabled = (value & 1u) != 0;
      break;
    case GOLDFISH_RTC_CLEAR_ALARM:
      rtc->alarm_armed = false;
      break;
    case GOLDFISH_RTC_CLEAR_INTERRUPT:
      rtc->interrupt_pending = false;
      break;
    default:
      break;
  }

  goldfish_rtc_evaluate_alarm(rtc);
}

static void goldfish_rtc_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 4);

  if (is_write) {
    goldfish_rtc_write_register(&goldfish_rtc, (GoldfishRtcRegister)offset,
        host_read(goldfish_rtc.mmio_space + offset, 4));
    return;
  }

  host_write(goldfish_rtc.mmio_space + offset, 4,
      goldfish_rtc_read_register(
          &goldfish_rtc, (GoldfishRtcRegister)offset));
}

void goldfish_rtc_update() {
  goldfish_rtc_evaluate_alarm(&goldfish_rtc);
}

void init_goldfish_rtc() {
  goldfish_rtc = (GoldfishRtcState) {
    .epoch_base_ns = host_realtime_ns(),
    .epoch_base_host_us = get_time(),
  };
#ifdef CONFIG_ISA_riscv
  goldfish_rtc.epoch_base_mtime = isa_riscv_mtime_value();
#endif
  goldfish_rtc.time_read_latch_ns = goldfish_rtc.epoch_base_ns;
  goldfish_rtc.last_observed_time_ns = goldfish_rtc.epoch_base_ns;

  goldfish_rtc.mmio_space = new_space(GOLDFISH_RTC_SIZE);
  add_mmio_map_with_policy("goldfish-rtc", DEV_GOLDFISH_RTC_MMIO,
      goldfish_rtc.mmio_space, GOLDFISH_RTC_SIZE,
      goldfish_rtc_io_handler, &goldfish_rtc_mmio_policy);
}

void goldfish_rtc_dump_machine_info(FILE *out) {
  // RTC 的存在不足以证明 Ubuntu 能拿到 wall-clock；这里固定导出模型、单位和 alarm 能力。
  fprintf(out, "device.goldfish_rtc.model=google,goldfish-rtc\n");
  fprintf(out, "device.goldfish_rtc.time_source=host-realtime-epoch+clint-mtime\n");
  fprintf(out, "device.goldfish_rtc.time_unit=ns\n");
  fprintf(out, "device.goldfish_rtc.virtual_timebase_hz=%" PRIu64 "\n",
      MUXDEF(CONFIG_ISA_riscv, isa_riscv_clint_timebase_hz(), 0ull));
  fprintf(out, "device.goldfish_rtc.virtual_clock_rebases=%" PRIu64 "\n",
      goldfish_rtc.virtual_clock_rebases);
  fprintf(out, "device.goldfish_rtc.mmio_size=0x%08x\n", GOLDFISH_RTC_SIZE);
  fprintf(out, "device.goldfish_rtc.alarm_supported=1\n");
  fprintf(out, "device.goldfish_rtc.alarm_enabled=%d\n",
      goldfish_rtc.alarm_armed ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.alarm_running=%d\n",
      goldfish_rtc.alarm_armed ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.irq_enabled=%d\n",
      goldfish_rtc.interrupt_enabled ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.interrupt_pending=%d\n",
      goldfish_rtc.interrupt_pending ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.interrupt_line=%d\n",
      goldfish_rtc_interrupt_line_asserted(&goldfish_rtc) ? 1 : 0);
  fprintf(out, "device.goldfish_rtc.time_latch=low-then-high\n");
}

void goldfish_rtc_qmp_query_rtc(char *out, size_t out_size) {
  goldfish_rtc_evaluate_alarm(&goldfish_rtc);
  uint64_t now_ns = goldfish_rtc_current_time_ns(&goldfish_rtc);
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
      DEV_GOLDFISH_RTC_MMIO, GOLDFISH_RTC_IRQ,
      (unsigned long long)MUXDEF(CONFIG_ISA_riscv, isa_riscv_clint_timebase_hz(), 0ull),
      (unsigned long long)now_ns,
      (unsigned long long)goldfish_rtc.alarm_time_ns,
      rtc_json_bool(goldfish_rtc.alarm_armed),
      rtc_json_bool(goldfish_rtc.alarm_armed),
      rtc_json_bool(goldfish_rtc.interrupt_enabled),
      rtc_json_bool(goldfish_rtc.interrupt_pending),
      rtc_json_bool(goldfish_rtc_interrupt_line_asserted(&goldfish_rtc)));
}
