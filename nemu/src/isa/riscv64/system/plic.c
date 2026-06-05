/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <isa.h>

#define PLIC_BASE 0x0c000000u
#define PLIC_SIZE 0x04000000u
#define PLIC_NR_IRQS 32

#define PLIC_PRIORITY_BASE 0x000000u
#define PLIC_PENDING       0x001000u
#define PLIC_M_ENABLE     0x002000u
#define PLIC_S_ENABLE     0x002080u
#define PLIC_M_THRESHOLD  0x200000u
#define PLIC_M_CLAIM      0x200004u
#define PLIC_S_THRESHOLD  0x201000u
#define PLIC_S_CLAIM      0x201004u

static uint32_t plic_priority[PLIC_NR_IRQS + 1];
static uint32_t plic_enable_m;
static uint32_t plic_enable_s;
static uint32_t plic_threshold_m;
static uint32_t plic_threshold_s;
// level 记录设备线电平，in_service 防止 claim 后到 complete 前反复重入；
// complete 时若电平仍高再重新 pending，匹配 UART THRE/virtio 这类电平中断。
static uint32_t plic_level;
static uint32_t plic_in_service;
static uint32_t plic_pending;

#ifdef CONFIG_STATISTIC
static uint64_t plic_claim_count[PLIC_NR_IRQS + 1];
static uint64_t plic_complete_count[PLIC_NR_IRQS + 1];
#endif

#ifdef CONFIG_RISCV_IRQ_DEBUG_LOG
static int plic_debug_log_budget = 128;

static bool plic_debug_log_enabled(void) {
  extern bool log_enable();
  return plic_debug_log_budget > 0 && log_enable();
}

#define PLIC_DEBUG_LOG(...) \
  do { \
    if (plic_debug_log_enabled()) { \
      plic_debug_log_budget--; \
      Log(__VA_ARGS__); \
    } \
  } while (0)
#else
#define PLIC_DEBUG_LOG(...) ((void)0)
#endif

static uint32_t plic_best_irq(bool supervisor) {
  uint32_t enable = supervisor ? plic_enable_s : plic_enable_m;
  uint32_t threshold = supervisor ? plic_threshold_s : plic_threshold_m;

  for (uint32_t irq = 1; irq <= PLIC_NR_IRQS && irq < 32; irq++) {
    if ((plic_pending & (1u << irq)) == 0) continue;
    if ((enable & (1u << irq)) == 0) continue;
    if (plic_priority[irq] <= threshold) continue;
    return irq;
  }
  return 0;
}

void isa_riscv32_plic_reset(void) {
  memset(plic_priority, 0, sizeof(plic_priority));
  plic_enable_m = 0;
  plic_enable_s = 0;
  plic_threshold_m = 0;
  plic_threshold_s = 0;
  plic_level = 0;
  plic_in_service = 0;
  plic_pending = 0;
#ifdef CONFIG_STATISTIC
  memset(plic_claim_count, 0, sizeof(plic_claim_count));
  memset(plic_complete_count, 0, sizeof(plic_complete_count));
#endif
}

void isa_riscv32_plic_set_irq(uint32_t irq, bool level) {
  if (irq == 0 || irq > PLIC_NR_IRQS || irq >= 32) return;
  uint32_t bit = 1u << irq;
  if (level) {
    plic_level |= bit;
    if ((plic_in_service & bit) == 0) plic_pending |= bit;
  } else {
    plic_level &= ~bit;
    plic_pending &= ~bit;
  }
}

word_t isa_riscv32_plic_pending_bits(void) {
  word_t pending = 0;
  if (plic_best_irq(false) != 0) pending |= MIP_MEIP;
  if (plic_best_irq(true) != 0) pending |= MIP_SEIP;
  return pending;
}

bool isa_riscv32_plic_in_range(paddr_t addr) {
  return addr >= PLIC_BASE && addr < PLIC_BASE + PLIC_SIZE;
}

static uint32_t plic_read32(uint32_t offset) {
  if (offset < PLIC_PENDING) {
    uint32_t irq = offset >> 2;
    return irq <= PLIC_NR_IRQS ? plic_priority[irq] : 0;
  }

  switch (offset) {
    case PLIC_PENDING:     return plic_pending;
    case PLIC_M_ENABLE:    return plic_enable_m;
    case PLIC_S_ENABLE:    return plic_enable_s;
    case PLIC_M_THRESHOLD: return plic_threshold_m;
    case PLIC_S_THRESHOLD: return plic_threshold_s;
    case PLIC_M_CLAIM: {
      uint32_t irq = plic_best_irq(false);
      if (irq != 0) {
        uint32_t bit = 1u << irq;
        plic_pending &= ~bit;
        plic_in_service |= bit;
#ifdef CONFIG_STATISTIC
        plic_claim_count[irq]++;
#endif
        PLIC_DEBUG_LOG("PLIC M claim irq=%u pending=0x%08x level=0x%08x in_service=0x%08x enable=0x%08x threshold=%u",
            irq, plic_pending, plic_level, plic_in_service,
            plic_enable_m, plic_threshold_m);
      }
      return irq;
    }
    case PLIC_S_CLAIM: {
      uint32_t irq = plic_best_irq(true);
      if (irq != 0) {
        uint32_t bit = 1u << irq;
        plic_pending &= ~bit;
        plic_in_service |= bit;
#ifdef CONFIG_STATISTIC
        plic_claim_count[irq]++;
#endif
        PLIC_DEBUG_LOG("PLIC S claim irq=%u pending=0x%08x level=0x%08x in_service=0x%08x enable=0x%08x threshold=%u",
            irq, plic_pending, plic_level, plic_in_service,
            plic_enable_s, plic_threshold_s);
      }
      return irq;
    }
    default: return 0;
  }
}

static void plic_write32(uint32_t offset, uint32_t value, uint32_t mask) {
  if (offset < PLIC_PENDING) {
    uint32_t irq = offset >> 2;
    if (irq <= PLIC_NR_IRQS) plic_priority[irq] = (plic_priority[irq] & ~mask) | (value & mask);
    return;
  }

  switch (offset) {
    case PLIC_PENDING:
      plic_pending = (plic_pending & ~mask) | (value & mask);
      break;
    case PLIC_M_ENABLE:
      plic_enable_m = (plic_enable_m & ~mask) | (value & mask);
      break;
    case PLIC_S_ENABLE:
      plic_enable_s = (plic_enable_s & ~mask) | (value & mask);
      break;
    case PLIC_M_THRESHOLD:
      plic_threshold_m = (plic_threshold_m & ~mask) | (value & mask);
      break;
    case PLIC_S_THRESHOLD:
      plic_threshold_s = (plic_threshold_s & ~mask) | (value & mask);
      break;
    case PLIC_M_CLAIM:
    case PLIC_S_CLAIM:
      if ((value & 31u) > 0 && (value & 31u) <= PLIC_NR_IRQS) {
        uint32_t bit = 1u << (value & 31u);
        plic_in_service &= ~bit;
        if (plic_level & bit) plic_pending |= bit;
#ifdef CONFIG_STATISTIC
        plic_complete_count[value & 31u]++;
#endif
        PLIC_DEBUG_LOG("PLIC complete irq=%u pending=0x%08x level=0x%08x in_service=0x%08x",
            value & 31u, plic_pending, plic_level, plic_in_service);
      }
      break;
    default:
      break;
  }
}

word_t isa_riscv32_plic_read(paddr_t addr, int len) {
  assert(len >= 1 && len <= 8);
  if (len == 8) {
    return isa_riscv32_plic_read(addr, 4) |
           (isa_riscv32_plic_read(addr + 4, 4) << 32);
  }
  uint32_t offset = addr - PLIC_BASE;
  uint32_t shift = (offset & 0x3u) * 8u;
  uint32_t word = plic_read32(offset & ~0x3u);
  uint32_t mask = len == 4 ? 0xffffffffu : ((1u << (len * 8)) - 1u);
  return (word >> shift) & mask;
}

void isa_riscv32_plic_write(paddr_t addr, int len, word_t data) {
  assert(len >= 1 && len <= 8);
  if (len == 8) {
    isa_riscv32_plic_write(addr, 4, (uint32_t)data);
    isa_riscv32_plic_write(addr + 4, 4, (uint32_t)(data >> 32));
    return;
  }
  uint32_t offset = addr - PLIC_BASE;
  uint32_t shift = (offset & 0x3u) * 8u;
  uint32_t mask = len == 4 ? 0xffffffffu : ((1u << (len * 8)) - 1u);
  uint32_t word_mask = mask << shift;
  uint32_t word_value = ((uint32_t)data << shift) & word_mask;
  plic_write32(offset & ~0x3u, word_value, word_mask);
}

void isa_riscv32_plic_statistic(void) {
#ifdef CONFIG_STATISTIC
  for (uint32_t irq = 1; irq <= PLIC_NR_IRQS && irq < 32; irq++) {
    if (plic_claim_count[irq] == 0 && plic_complete_count[irq] == 0) continue;
    uint32_t bit = 1u << irq;
    Log("plic irq%u claim=%" PRIu64 " complete=%" PRIu64
        " level=%u pending=%u in_service=%u",
        irq, plic_claim_count[irq], plic_complete_count[irq],
        (plic_level & bit) != 0, (plic_pending & bit) != 0,
        (plic_in_service & bit) != 0);
  }
#endif
}
