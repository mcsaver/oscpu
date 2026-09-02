/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#ifndef __NEMU_ISA_RISCV_PLIC_H__
#define __NEMU_ISA_RISCV_PLIC_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/*
 * 本实现对应单 hart virt 平台的两个 PLIC context：M-mode 与 S-mode。
 * source 0 是架构保留的“不存在中断”，32 个编号槽因此提供 source 1..31。
 */
enum {
  RISCV_PLIC_SOURCE_COUNT = 32,
  RISCV_PLIC_FIRST_SOURCE = 1,
  RISCV_PLIC_LAST_SOURCE = RISCV_PLIC_SOURCE_COUNT - 1,
  RISCV_PLIC_PRIORITY_BITS = 3,
  RISCV_PLIC_PRIORITY_MAX = (1u << RISCV_PLIC_PRIORITY_BITS) - 1u,
};

enum {
  RISCV_PLIC_BASE = UINT64_C(0x0c000000),
  RISCV_PLIC_SIZE = UINT64_C(0x04000000),
  RISCV_PLIC_PRIORITY_BASE = 0x000000u,
  RISCV_PLIC_PENDING_BASE = 0x001000u,
  RISCV_PLIC_MACHINE_ENABLE = 0x002000u,
  RISCV_PLIC_SUPERVISOR_ENABLE = 0x002080u,
  RISCV_PLIC_MACHINE_THRESHOLD = 0x200000u,
  RISCV_PLIC_MACHINE_CLAIM_COMPLETE = 0x200004u,
  RISCV_PLIC_SUPERVISOR_THRESHOLD = 0x201000u,
  RISCV_PLIC_SUPERVISOR_CLAIM_COMPLETE = 0x201004u,
};

typedef uint32_t RiscvPlicSourceId;
typedef uint32_t RiscvPlicPriority;

typedef enum {
  RISCV_PLIC_MACHINE_CONTEXT = 0,
  RISCV_PLIC_SUPERVISOR_CONTEXT = 1,
  RISCV_PLIC_CONTEXT_COUNT = 2,
} RiscvPlicContextId;

typedef struct {
  uint32_t enable;
  RiscvPlicPriority threshold;
  uint32_t in_service;
} RiscvPlicContextState;

typedef struct {
  RiscvPlicPriority source_priority[RISCV_PLIC_SOURCE_COUNT];
  uint32_t pending;
  uint32_t line_level;
  RiscvPlicContextState context[RISCV_PLIC_CONTEXT_COUNT];
} RiscvPlicState;

typedef enum {
  RISCV_PLIC_MMIO_NO_EFFECT = 0,
  RISCV_PLIC_MMIO_CLAIM,
  RISCV_PLIC_MMIO_COMPLETION,
} RiscvPlicMmioEffectKind;

typedef struct {
  RiscvPlicMmioEffectKind kind;
  RiscvPlicContextId context;
  RiscvPlicSourceId source;
  bool accepted;
} RiscvPlicMmioEffect;

static inline bool riscv_plic_source_is_valid(RiscvPlicSourceId source) {
  return source >= RISCV_PLIC_FIRST_SOURCE && source <= RISCV_PLIC_LAST_SOURCE;
}

static inline bool riscv_plic_context_is_valid(RiscvPlicContextId context) {
  return (uint32_t)context < RISCV_PLIC_CONTEXT_COUNT;
}

static inline uint32_t riscv_plic_source_bit(RiscvPlicSourceId source) {
  /* 先判 ID 再移位，guest 提供的 source 永远不能触发宿主 C 位移 UB。 */
  return riscv_plic_source_is_valid(source) ? (UINT32_C(1) << source) : 0;
}

static inline RiscvPlicPriority riscv_plic_priority_warl(uint32_t value) {
  /* QEMU virt 使用 3 个优先级位；非法高位按 WARL 规则过滤，合法范围是 0..7。 */
  return value & RISCV_PLIC_PRIORITY_MAX;
}

static inline void riscv_plic_reset(RiscvPlicState *plic) {
  for (RiscvPlicSourceId source = 0; source < RISCV_PLIC_SOURCE_COUNT; source++) {
    plic->source_priority[source] = 0;
  }
  plic->pending = 0;
  plic->line_level = 0;
  for (uint32_t context = 0; context < RISCV_PLIC_CONTEXT_COUNT; context++) {
    plic->context[context].enable = 0;
    plic->context[context].threshold = 0;
    plic->context[context].in_service = 0;
  }
}

static inline RiscvPlicPriority riscv_plic_source_priority(
    const RiscvPlicState *plic, RiscvPlicSourceId source) {
  return riscv_plic_source_is_valid(source) ? plic->source_priority[source] : 0;
}

static inline void riscv_plic_write_source_priority(
    RiscvPlicState *plic, RiscvPlicSourceId source, uint32_t value) {
  if (!riscv_plic_source_is_valid(source)) return;
  plic->source_priority[source] = riscv_plic_priority_warl(value);
}

static inline uint32_t riscv_plic_pending_bits(const RiscvPlicState *plic) {
  return plic->pending & ~UINT32_C(1);
}

static inline uint32_t riscv_plic_context_enable_bits(
    const RiscvPlicState *plic, RiscvPlicContextId context) {
  return riscv_plic_context_is_valid(context)
      ? (plic->context[context].enable & ~UINT32_C(1)) : 0;
}

static inline void riscv_plic_write_context_enable(
    RiscvPlicState *plic, RiscvPlicContextId context, uint32_t value) {
  if (!riscv_plic_context_is_valid(context)) return;
  /* source 0 在每个 enable word 中都硬连为 0。 */
  plic->context[context].enable = value & ~UINT32_C(1);
}

static inline RiscvPlicPriority riscv_plic_context_threshold(
    const RiscvPlicState *plic, RiscvPlicContextId context) {
  return riscv_plic_context_is_valid(context) ? plic->context[context].threshold : 0;
}

static inline void riscv_plic_write_context_threshold(
    RiscvPlicState *plic, RiscvPlicContextId context, uint32_t value) {
  if (!riscv_plic_context_is_valid(context)) return;
  plic->context[context].threshold = riscv_plic_priority_warl(value);
}

static inline uint32_t riscv_plic_in_service_bits(const RiscvPlicState *plic) {
  return plic->context[RISCV_PLIC_MACHINE_CONTEXT].in_service |
         plic->context[RISCV_PLIC_SUPERVISOR_CONTEXT].in_service;
}

static inline bool riscv_plic_source_is_in_service(
    const RiscvPlicState *plic, RiscvPlicSourceId source) {
  uint32_t bit = riscv_plic_source_bit(source);
  return bit != 0 && (riscv_plic_in_service_bits(plic) & bit) != 0;
}

static inline void riscv_plic_gateway_update_level(
    RiscvPlicState *plic, RiscvPlicSourceId source, bool asserted) {
  uint32_t bit = riscv_plic_source_bit(source);
  if (bit == 0) return;

  if (asserted) {
    plic->line_level |= bit;
    if (!riscv_plic_source_is_in_service(plic, source)) {
      plic->pending |= bit;
    }
  } else {
    /*
     * 网关已经转发到 PLIC core 的请求由 pending 锁存；设备撤销电平只改变
     * 网关输入，不能撤回该请求。pending 只能由 claim 原子清除。
     */
    plic->line_level &= ~bit;
  }
  plic->line_level &= ~UINT32_C(1);
  plic->pending &= ~UINT32_C(1);
}

static inline RiscvPlicSourceId riscv_plic_select_highest_priority(
    const RiscvPlicState *plic, RiscvPlicContextId context,
    RiscvPlicPriority priority_must_exceed) {
  if (!riscv_plic_context_is_valid(context)) return 0;

  uint32_t candidates = riscv_plic_pending_bits(plic) &
      riscv_plic_context_enable_bits(plic, context);
  RiscvPlicSourceId selected = 0;
  RiscvPlicPriority selected_priority = priority_must_exceed;

  /* 从低 ID 向高 ID 扫描且只在严格更高优先级时替换，天然实现同级最低 ID 胜出。 */
  for (RiscvPlicSourceId source = RISCV_PLIC_FIRST_SOURCE;
       source <= RISCV_PLIC_LAST_SOURCE; source++) {
    uint32_t bit = riscv_plic_source_bit(source);
    RiscvPlicPriority priority = plic->source_priority[source];
    if ((candidates & bit) != 0 && priority > selected_priority) {
      selected = source;
      selected_priority = priority;
    }
  }
  return selected;
}

static inline RiscvPlicSourceId riscv_plic_select_notification(
    const RiscvPlicState *plic, RiscvPlicContextId context) {
  /* notification 必须严格高于该 context 的 threshold。 */
  return riscv_plic_select_highest_priority(
      plic, context, riscv_plic_context_threshold(plic, context));
}

static inline RiscvPlicSourceId riscv_plic_select_claim(
    const RiscvPlicState *plic, RiscvPlicContextId context) {
  /* claim 不受 threshold 影响，但 priority 0 代表“永不递送”。 */
  return riscv_plic_select_highest_priority(plic, context, 0);
}

static inline bool riscv_plic_any_context_notifies(const RiscvPlicState *plic) {
  return riscv_plic_select_notification(plic, RISCV_PLIC_MACHINE_CONTEXT) != 0 ||
         riscv_plic_select_notification(plic, RISCV_PLIC_SUPERVISOR_CONTEXT) != 0;
}

static inline RiscvPlicSourceId riscv_plic_claim(
    RiscvPlicState *plic, RiscvPlicContextId context) {
  RiscvPlicSourceId source = riscv_plic_select_claim(plic, context);
  uint32_t bit = riscv_plic_source_bit(source);
  if (bit == 0) return 0;

  /* claim 是一个原子语义动作：返回 ID、清 pending、把网关标为 in-service。 */
  plic->pending &= ~bit;
  plic->context[context].in_service |= bit;
  return source;
}

static inline bool riscv_plic_complete(
    RiscvPlicState *plic, RiscvPlicContextId context,
    RiscvPlicSourceId source) {
  uint32_t bit = riscv_plic_source_bit(source);
  if (bit == 0 || !riscv_plic_context_is_valid(context)) return false;

  RiscvPlicContextState *target = &plic->context[context];
  /*
   * completion 不依赖“最后一次 claim”，但必须属于写入它的 context，且该
   * source 此刻仍对该 context enable；错误 context 或 disabled 写静默忽略。
   */
  if ((target->in_service & bit) == 0 || (target->enable & bit) == 0) return false;

  target->in_service &= ~bit;
  if ((plic->line_level & bit) != 0) {
    /* level 型设备尚未撤销：网关在 completion 后重新转发一个请求。 */
    plic->pending |= bit;
  }
  return true;
}

static inline RiscvPlicMmioEffect riscv_plic_no_mmio_effect(void) {
  RiscvPlicMmioEffect effect = {
    .kind = RISCV_PLIC_MMIO_NO_EFFECT,
    .context = RISCV_PLIC_MACHINE_CONTEXT,
    .source = 0,
    .accepted = false,
  };
  return effect;
}

static inline uint32_t riscv_plic_read_register(
    RiscvPlicState *plic, uint32_t offset, RiscvPlicMmioEffect *effect) {
  if (effect != NULL) *effect = riscv_plic_no_mmio_effect();

  if (offset < RISCV_PLIC_SOURCE_COUNT * sizeof(uint32_t)) {
    return riscv_plic_source_priority(plic, offset / sizeof(uint32_t));
  }

  switch (offset) {
    case RISCV_PLIC_PENDING_BASE:
      return riscv_plic_pending_bits(plic);
    case RISCV_PLIC_MACHINE_ENABLE:
      return riscv_plic_context_enable_bits(plic, RISCV_PLIC_MACHINE_CONTEXT);
    case RISCV_PLIC_SUPERVISOR_ENABLE:
      return riscv_plic_context_enable_bits(plic, RISCV_PLIC_SUPERVISOR_CONTEXT);
    case RISCV_PLIC_MACHINE_THRESHOLD:
      return riscv_plic_context_threshold(plic, RISCV_PLIC_MACHINE_CONTEXT);
    case RISCV_PLIC_SUPERVISOR_THRESHOLD:
      return riscv_plic_context_threshold(plic, RISCV_PLIC_SUPERVISOR_CONTEXT);
    case RISCV_PLIC_MACHINE_CLAIM_COMPLETE:
    case RISCV_PLIC_SUPERVISOR_CLAIM_COMPLETE: {
      RiscvPlicContextId context = offset == RISCV_PLIC_MACHINE_CLAIM_COMPLETE
          ? RISCV_PLIC_MACHINE_CONTEXT : RISCV_PLIC_SUPERVISOR_CONTEXT;
      RiscvPlicSourceId source = riscv_plic_claim(plic, context);
      if (effect != NULL) {
        effect->kind = RISCV_PLIC_MMIO_CLAIM;
        effect->context = context;
        effect->source = source;
        effect->accepted = source != 0;
      }
      return source;
    }
    default:
      return 0;
  }
}

static inline void riscv_plic_write_register(
    RiscvPlicState *plic, uint32_t offset, uint32_t value,
    RiscvPlicMmioEffect *effect) {
  if (effect != NULL) *effect = riscv_plic_no_mmio_effect();

  if (offset < RISCV_PLIC_SOURCE_COUNT * sizeof(uint32_t)) {
    riscv_plic_write_source_priority(plic, offset / sizeof(uint32_t), value);
    return;
  }

  switch (offset) {
    case RISCV_PLIC_PENDING_BASE:
      /* IP 是网关到 core 的只读可见状态，软件写入没有任何效果。 */
      return;
    case RISCV_PLIC_MACHINE_ENABLE:
      riscv_plic_write_context_enable(plic, RISCV_PLIC_MACHINE_CONTEXT, value);
      return;
    case RISCV_PLIC_SUPERVISOR_ENABLE:
      riscv_plic_write_context_enable(plic, RISCV_PLIC_SUPERVISOR_CONTEXT, value);
      return;
    case RISCV_PLIC_MACHINE_THRESHOLD:
      riscv_plic_write_context_threshold(plic, RISCV_PLIC_MACHINE_CONTEXT, value);
      return;
    case RISCV_PLIC_SUPERVISOR_THRESHOLD:
      riscv_plic_write_context_threshold(plic, RISCV_PLIC_SUPERVISOR_CONTEXT, value);
      return;
    case RISCV_PLIC_MACHINE_CLAIM_COMPLETE:
    case RISCV_PLIC_SUPERVISOR_CLAIM_COMPLETE: {
      RiscvPlicContextId context = offset == RISCV_PLIC_MACHINE_CLAIM_COMPLETE
          ? RISCV_PLIC_MACHINE_CONTEXT : RISCV_PLIC_SUPERVISOR_CONTEXT;
      bool accepted = riscv_plic_complete(plic, context, value);
      if (effect != NULL) {
        effect->kind = RISCV_PLIC_MMIO_COMPLETION;
        effect->context = context;
        effect->source = value;
        effect->accepted = accepted;
      }
      return;
    }
    default:
      return;
  }
}

static inline bool riscv_plic_address_in_aperture(uint64_t address) {
  return address >= RISCV_PLIC_BASE &&
         address - RISCV_PLIC_BASE < RISCV_PLIC_SIZE;
}

static inline bool riscv_plic_mmio_access_valid(uint64_t address, int length) {
  if (length != (int)sizeof(uint32_t) || (address & 0x3u) != 0) return false;
  if (!riscv_plic_address_in_aperture(address)) return false;
  return address - RISCV_PLIC_BASE <= RISCV_PLIC_SIZE - sizeof(uint32_t);
}

#endif
