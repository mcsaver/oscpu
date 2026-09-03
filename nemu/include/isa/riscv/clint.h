/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#ifndef __NEMU_ISA_RISCV_CLINT_H__
#define __NEMU_ISA_RISCV_CLINT_H__

#include <stdbool.h>
#include <stdint.h>

/*
 * 本实现描述 virt 单 hart 平台的 CLINT 寄存器语义。地址、容量和 timebase
 * 都在这里定义；宿主时钟同步、统计和 QMP 只属于各 XLEN 的平台包装器。
 */
enum {
  RISCV_CLINT_MSIP_OFFSET = 0x0000u,
  RISCV_CLINT_MTIMECMP_OFFSET = 0x4000u,
  RISCV_CLINT_MTIME_OFFSET = 0xbff8u,
};

#define RISCV_CLINT_BASE UINT64_C(0x02000000)
#define RISCV_CLINT_SIZE UINT64_C(0x00010000)
#define RISCV_CLINT_TIMEBASE_HZ UINT64_C(10000000)
#define RISCV_CLINT_NO_DEADLINE UINT64_MAX

typedef struct {
  /* msip 只有 bit 0 是 WARL；其余位永远读作零。 */
  uint32_t msip;
  /* mtimecmp 是无符号比较期限；全 1 表示本平台没有已编程期限。 */
  uint64_t mtimecmp;
  /* mtime 是所有 MMIO 与 CSR time 视图共同读取的平台时间。 */
  uint64_t mtime;
} RiscvClintState;

/*
 * 每个枚举值都对应手册里一个完整、合法的总线事务。LOW/HIGH 是 RV32
 * 可见的 32-bit half，FULL 是 RV64 可选择支持的自然对齐 64-bit 事务。
 */
typedef enum {
  RISCV_CLINT_ACCESS_INVALID = 0,
  RISCV_CLINT_ACCESS_MSIP_32,
  RISCV_CLINT_ACCESS_MTIMECMP_LOW_32,
  RISCV_CLINT_ACCESS_MTIMECMP_HIGH_32,
  RISCV_CLINT_ACCESS_MTIMECMP_FULL_64,
  RISCV_CLINT_ACCESS_MTIME_LOW_32,
  RISCV_CLINT_ACCESS_MTIME_HIGH_32,
  RISCV_CLINT_ACCESS_MTIME_FULL_64,
} RiscvClintAccessKind;

static inline void riscv_clint_reset(RiscvClintState *clint) {
  clint->msip = 0;
  clint->mtimecmp = RISCV_CLINT_NO_DEADLINE;
  clint->mtime = 0;
}

static inline uint32_t riscv_clint_msip_warl(uint32_t value) {
  return value & UINT32_C(1);
}

static inline bool riscv_clint_software_interrupt_pending(
    const RiscvClintState *clint) {
  return riscv_clint_msip_warl(clint->msip) != 0;
}

static inline bool riscv_clint_timer_interrupt_pending(
    const RiscvClintState *clint) {
  /* CLINT 的 timer 比较是无符号 64-bit mtime >= mtimecmp。 */
  return clint->mtime >= clint->mtimecmp;
}

static inline uint32_t riscv_clint_low_half(uint64_t value) {
  return (uint32_t)value;
}

static inline uint32_t riscv_clint_high_half(uint64_t value) {
  return (uint32_t)(value >> 32);
}

static inline uint64_t riscv_clint_replace_low_half(
    uint64_t old_value, uint32_t low) {
  return (old_value & UINT64_C(0xffffffff00000000)) | (uint64_t)low;
}

static inline uint64_t riscv_clint_replace_high_half(
    uint64_t old_value, uint32_t high) {
  return ((uint64_t)high << 32) | (uint32_t)old_value;
}

static inline bool riscv_clint_address_in_aperture(uint64_t address) {
  return address >= RISCV_CLINT_BASE &&
         address - RISCV_CLINT_BASE < RISCV_CLINT_SIZE;
}

static inline RiscvClintAccessKind riscv_clint_decode_access(
    uint64_t address, int length, bool supports_64_bit_transaction) {
  if (!riscv_clint_address_in_aperture(address)) {
    return RISCV_CLINT_ACCESS_INVALID;
  }

  uint64_t offset = address - RISCV_CLINT_BASE;
  if (length == 4) {
    if ((address & UINT64_C(3)) != 0) return RISCV_CLINT_ACCESS_INVALID;
    switch (offset) {
      case RISCV_CLINT_MSIP_OFFSET:
        return RISCV_CLINT_ACCESS_MSIP_32;
      case RISCV_CLINT_MTIMECMP_OFFSET:
        return RISCV_CLINT_ACCESS_MTIMECMP_LOW_32;
      case RISCV_CLINT_MTIMECMP_OFFSET + 4:
        return RISCV_CLINT_ACCESS_MTIMECMP_HIGH_32;
      case RISCV_CLINT_MTIME_OFFSET:
        return RISCV_CLINT_ACCESS_MTIME_LOW_32;
      case RISCV_CLINT_MTIME_OFFSET + 4:
        return RISCV_CLINT_ACCESS_MTIME_HIGH_32;
      default:
        return RISCV_CLINT_ACCESS_INVALID;
    }
  }

  if (length == 8 && supports_64_bit_transaction &&
      (address & UINT64_C(7)) == 0) {
    switch (offset) {
      case RISCV_CLINT_MTIMECMP_OFFSET:
        return RISCV_CLINT_ACCESS_MTIMECMP_FULL_64;
      case RISCV_CLINT_MTIME_OFFSET:
        return RISCV_CLINT_ACCESS_MTIME_FULL_64;
      default:
        return RISCV_CLINT_ACCESS_INVALID;
    }
  }

  /* byte/half、RV32 doubleword、未对齐和保留 offset 都不是寄存器事务。 */
  return RISCV_CLINT_ACCESS_INVALID;
}

static inline bool riscv_clint_mmio_access_valid(
    uint64_t address, int length, bool supports_64_bit_transaction) {
  return riscv_clint_decode_access(
      address, length, supports_64_bit_transaction) !=
      RISCV_CLINT_ACCESS_INVALID;
}

static inline bool riscv_clint_access_writes_mtime(
    RiscvClintAccessKind access) {
  return access == RISCV_CLINT_ACCESS_MTIME_LOW_32 ||
         access == RISCV_CLINT_ACCESS_MTIME_HIGH_32 ||
         access == RISCV_CLINT_ACCESS_MTIME_FULL_64;
}

static inline uint64_t riscv_clint_read_register(
    const RiscvClintState *clint, RiscvClintAccessKind access) {
  switch (access) {
    case RISCV_CLINT_ACCESS_MSIP_32:
      return riscv_clint_msip_warl(clint->msip);
    case RISCV_CLINT_ACCESS_MTIMECMP_LOW_32:
      return riscv_clint_low_half(clint->mtimecmp);
    case RISCV_CLINT_ACCESS_MTIMECMP_HIGH_32:
      return riscv_clint_high_half(clint->mtimecmp);
    case RISCV_CLINT_ACCESS_MTIMECMP_FULL_64:
      return clint->mtimecmp;
    case RISCV_CLINT_ACCESS_MTIME_LOW_32:
      return riscv_clint_low_half(clint->mtime);
    case RISCV_CLINT_ACCESS_MTIME_HIGH_32:
      return riscv_clint_high_half(clint->mtime);
    case RISCV_CLINT_ACCESS_MTIME_FULL_64:
      return clint->mtime;
    default:
      return 0;
  }
}

static inline void riscv_clint_write_register(
    RiscvClintState *clint, RiscvClintAccessKind access, uint64_t value) {
  switch (access) {
    case RISCV_CLINT_ACCESS_MSIP_32:
      clint->msip = riscv_clint_msip_warl((uint32_t)value);
      return;
    case RISCV_CLINT_ACCESS_MTIMECMP_LOW_32:
      clint->mtimecmp = riscv_clint_replace_low_half(
          clint->mtimecmp, (uint32_t)value);
      return;
    case RISCV_CLINT_ACCESS_MTIMECMP_HIGH_32:
      clint->mtimecmp = riscv_clint_replace_high_half(
          clint->mtimecmp, (uint32_t)value);
      return;
    case RISCV_CLINT_ACCESS_MTIMECMP_FULL_64:
      clint->mtimecmp = value;
      return;
    case RISCV_CLINT_ACCESS_MTIME_LOW_32:
      clint->mtime = riscv_clint_replace_low_half(clint->mtime, (uint32_t)value);
      return;
    case RISCV_CLINT_ACCESS_MTIME_HIGH_32:
      clint->mtime = riscv_clint_replace_high_half(clint->mtime, (uint32_t)value);
      return;
    case RISCV_CLINT_ACCESS_MTIME_FULL_64:
      clint->mtime = value;
      return;
    default:
      return;
  }
}

static inline uint64_t riscv_clint_saturating_add_u64(
    uint64_t left, uint64_t right) {
  return right > UINT64_MAX - left ? UINT64_MAX : left + right;
}

static inline uint64_t riscv_clint_saturating_multiply_u64(
    uint64_t left, uint64_t right) {
  if (left != 0 && right > UINT64_MAX / left) return UINT64_MAX;
  return left * right;
}

static inline uint64_t riscv_clint_microseconds_to_ticks_at_rate(
    uint64_t us, uint64_t timebase_hz) {
  /*
   * floor(us * HZ / 1e6)，用商/余数展开避免 HZ 非整 MHz 时丢掉余数，
   * 也不依赖 TARGET_AM 工具链未必支持的 __int128。每一步都显式饱和。
   */
  const uint64_t scale = UINT64_C(1000000);
  const uint64_t hz_whole = timebase_hz / scale;
  const uint64_t hz_remainder = timebase_hz % scale;
  const uint64_t us_whole = us / scale;
  const uint64_t us_remainder = us % scale;

  uint64_t ticks = riscv_clint_saturating_multiply_u64(us, hz_whole);
  ticks = riscv_clint_saturating_add_u64(ticks,
      riscv_clint_saturating_multiply_u64(us_whole, hz_remainder));
  ticks = riscv_clint_saturating_add_u64(ticks,
      (us_remainder * hz_remainder) / scale);
  return ticks;
}

static inline uint64_t riscv_clint_microseconds_to_ticks(uint64_t us) {
  return riscv_clint_microseconds_to_ticks_at_rate(
      us, RISCV_CLINT_TIMEBASE_HZ);
}

static inline uint64_t riscv_clint_ticks_to_microseconds(uint64_t ticks) {
  /* 当前 timebase 下余项乘积有界；商项仍按 host sleep 的安全要求饱和。 */
  const uint64_t scale = UINT64_C(1000000);
  const uint64_t whole = ticks / RISCV_CLINT_TIMEBASE_HZ;
  const uint64_t remainder = ticks % RISCV_CLINT_TIMEBASE_HZ;
  uint64_t us = riscv_clint_saturating_multiply_u64(whole, scale);
  return riscv_clint_saturating_add_u64(
      us, (remainder * scale) / RISCV_CLINT_TIMEBASE_HZ);
}

#endif
