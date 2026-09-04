/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <isa.h>
#include <isa/riscv/plic.h>
#ifndef CONFIG_TARGET_AM
#include <stdarg.h>
#include <stdio.h>
#endif

static RiscvPlicState plic;

#ifdef CONFIG_STATISTIC
static uint64_t plic_claim_count[RISCV_PLIC_SOURCE_COUNT];
static uint64_t plic_complete_count[RISCV_PLIC_SOURCE_COUNT];
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

static RiscvPlicSourceId plic_notification_source(RiscvPlicContextId context) {
  return riscv_plic_select_notification(&plic, context);
}

#ifndef CONFIG_TARGET_AM
typedef struct {
  uint32_t irq;
  const char *name;
  const char *kind;
  bool enabled;
} PlicSourceInfo;

static const PlicSourceInfo plic_sources[] = {
  {1, "serial0", "uart16550", ISDEF(CONFIG_HAS_SERIAL)},
  {2, "virtio-blk", "virtio-mmio", ISDEF(CONFIG_HAS_DISK)},
  {3, "virtio-rng", "virtio-mmio", ISDEF(CONFIG_HAS_VIRTIO_RNG)},
  {4, "goldfish-rtc", "platform-rtc", ISDEF(CONFIG_HAS_GOLDFISH_RTC)},
  {5, "virtio-net", "virtio-mmio", ISDEF(CONFIG_HAS_VIRTIO_NET)},
  {7, "virtio-input", "virtio-mmio", ISDEF(CONFIG_HAS_VIRTIO_INPUT)},
};

static const char *plic_json_bool(bool value) {
  return value ? "true" : "false";
}

static uint64_t plic_claim_count_value(uint32_t irq) {
#ifdef CONFIG_STATISTIC
  return riscv_plic_source_is_valid(irq) ? plic_claim_count[irq] : 0;
#else
  (void)irq;
  return 0;
#endif
}

static uint64_t plic_complete_count_value(uint32_t irq) {
#ifdef CONFIG_STATISTIC
  return riscv_plic_source_is_valid(irq) ? plic_complete_count[irq] : 0;
#else
  (void)irq;
  return 0;
#endif
}

static void plic_json_append(char *out, size_t out_size, size_t *used,
    const char *fmt, ...) {
  if (*used >= out_size) return;

  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(out + *used, out_size - *used, fmt, ap);
  va_end(ap);

  if (n < 0) return;
  if ((size_t)n >= out_size - *used) {
    *used = out_size;
  } else {
    *used += (size_t)n;
  }
}

void isa_riscv64_plic_dump_machine_info(FILE *out) {
  // source map 把“设备 IRQ 号”固定成可审计账本，避免后续只看设备局部字段而漏掉 PLIC。
  fprintf(out, "interrupt.plic.enabled=1\n");
  fprintf(out, "interrupt.plic.model=riscv,plic0\n");
  fprintf(out, "interrupt.plic.mmio=0x%08" PRIx64 "\n", (uint64_t)RISCV_PLIC_BASE);
  fprintf(out, "interrupt.plic.size=0x%08" PRIx64 "\n", (uint64_t)RISCV_PLIC_SIZE);
  fprintf(out, "interrupt.plic.nr_irqs=%u\n", RISCV_PLIC_SOURCE_COUNT);
  fprintf(out, "interrupt.plic.contexts=%u\n", RISCV_PLIC_CONTEXT_COUNT);
  fprintf(out, "interrupt.plic.pending=0x%08x\n", riscv_plic_pending_bits(&plic));
  fprintf(out, "interrupt.plic.level=0x%08x\n", plic.line_level);
  fprintf(out, "interrupt.plic.in_service=0x%08x\n", riscv_plic_in_service_bits(&plic));
  fprintf(out, "interrupt.plic.enable_m=0x%08x\n",
      riscv_plic_context_enable_bits(&plic, RISCV_PLIC_MACHINE_CONTEXT));
  fprintf(out, "interrupt.plic.enable_s=0x%08x\n",
      riscv_plic_context_enable_bits(&plic, RISCV_PLIC_SUPERVISOR_CONTEXT));
  fprintf(out, "interrupt.plic.threshold_m=%u\n",
      riscv_plic_context_threshold(&plic, RISCV_PLIC_MACHINE_CONTEXT));
  fprintf(out, "interrupt.plic.threshold_s=%u\n",
      riscv_plic_context_threshold(&plic, RISCV_PLIC_SUPERVISOR_CONTEXT));
  fprintf(out, "interrupt.plic.best_irq_m=%u\n",
      plic_notification_source(RISCV_PLIC_MACHINE_CONTEXT));
  fprintf(out, "interrupt.plic.best_irq_s=%u\n",
      plic_notification_source(RISCV_PLIC_SUPERVISOR_CONTEXT));

  for (size_t i = 0; i < ARRLEN(plic_sources); i++) {
    const PlicSourceInfo *src = &plic_sources[i];
    uint32_t bit = 1u << src->irq;
    fprintf(out, "interrupt.plic.source.%u.name=%s\n", src->irq, src->name);
    fprintf(out, "interrupt.plic.source.%u.kind=%s\n", src->irq, src->kind);
    fprintf(out, "interrupt.plic.source.%u.enabled=%u\n",
        src->irq, src->enabled ? 1u : 0u);
    fprintf(out, "interrupt.plic.source.%u.priority=%u\n",
        src->irq, riscv_plic_source_priority(&plic, src->irq));
    fprintf(out, "interrupt.plic.source.%u.level=%u\n",
        src->irq, (plic.line_level & bit) != 0);
    fprintf(out, "interrupt.plic.source.%u.pending=%u\n",
        src->irq, (riscv_plic_pending_bits(&plic) & bit) != 0);
    fprintf(out, "interrupt.plic.source.%u.in_service=%u\n",
        src->irq, (riscv_plic_in_service_bits(&plic) & bit) != 0);
  }
}

void isa_riscv64_plic_qmp_snapshot(char *out, size_t out_size) {
  size_t used = 0;
  plic_json_append(out, out_size, &used,
      "{\"model\":\"riscv,plic0\",\"mmio\":\"0x%08" PRIx64 "\","
      "\"size\":%" PRIu64 ",\"nr-irqs\":%u,\"contexts\":%u,"
      "\"pending\":\"0x%08x\",\"level\":\"0x%08x\","
      "\"in-service\":\"0x%08x\",\"enable-m\":\"0x%08x\","
      "\"enable-s\":\"0x%08x\",\"threshold-m\":%u,"
      "\"threshold-s\":%u,\"best-irq-m\":%u,"
      "\"best-irq-s\":%u,\"sources\":[",
      (uint64_t)RISCV_PLIC_BASE, (uint64_t)RISCV_PLIC_SIZE,
      RISCV_PLIC_SOURCE_COUNT, RISCV_PLIC_CONTEXT_COUNT,
      riscv_plic_pending_bits(&plic), plic.line_level,
      riscv_plic_in_service_bits(&plic),
      riscv_plic_context_enable_bits(&plic, RISCV_PLIC_MACHINE_CONTEXT),
      riscv_plic_context_enable_bits(&plic, RISCV_PLIC_SUPERVISOR_CONTEXT),
      riscv_plic_context_threshold(&plic, RISCV_PLIC_MACHINE_CONTEXT),
      riscv_plic_context_threshold(&plic, RISCV_PLIC_SUPERVISOR_CONTEXT),
      plic_notification_source(RISCV_PLIC_MACHINE_CONTEXT),
      plic_notification_source(RISCV_PLIC_SUPERVISOR_CONTEXT));

  for (size_t i = 0; i < ARRLEN(plic_sources); i++) {
    const PlicSourceInfo *src = &plic_sources[i];
    uint32_t bit = 1u << src->irq;
    plic_json_append(out, out_size, &used,
        "%s{\"irq\":%u,\"name\":\"%s\",\"kind\":\"%s\","
        "\"enabled\":%s,\"priority\":%u,\"level\":%s,"
        "\"pending\":%s,\"in-service\":%s,\"enabled-m\":%s,"
        "\"enabled-s\":%s,\"claim-count\":%" PRIu64 ","
        "\"complete-count\":%" PRIu64 "}",
        i == 0 ? "" : ",", src->irq, src->name, src->kind,
        plic_json_bool(src->enabled), riscv_plic_source_priority(&plic, src->irq),
        plic_json_bool((plic.line_level & bit) != 0),
        plic_json_bool((riscv_plic_pending_bits(&plic) & bit) != 0),
        plic_json_bool((riscv_plic_in_service_bits(&plic) & bit) != 0),
        plic_json_bool((riscv_plic_context_enable_bits(
            &plic, RISCV_PLIC_MACHINE_CONTEXT) & bit) != 0),
        plic_json_bool((riscv_plic_context_enable_bits(
            &plic, RISCV_PLIC_SUPERVISOR_CONTEXT) & bit) != 0),
        plic_claim_count_value(src->irq),
        plic_complete_count_value(src->irq));
  }

  plic_json_append(out, out_size, &used, "]}");
}
#endif

void isa_riscv64_plic_reset(void) {
  riscv_plic_reset(&plic);
#ifdef CONFIG_STATISTIC
  memset(plic_claim_count, 0, sizeof(plic_claim_count));
  memset(plic_complete_count, 0, sizeof(plic_complete_count));
#endif
}

void isa_riscv64_plic_set_irq(uint32_t irq, bool level) {
  riscv_plic_gateway_update_level(&plic, irq, level);
}

bool isa_riscv64_plic_maybe_pending(void) {
  return riscv_plic_any_context_notifies(&plic);
}

word_t isa_riscv64_plic_pending_bits(void) {
  word_t pending = 0;
  if (plic_notification_source(RISCV_PLIC_MACHINE_CONTEXT) != 0) pending |= MIP_MEIP;
  if (plic_notification_source(RISCV_PLIC_SUPERVISOR_CONTEXT) != 0) pending |= MIP_SEIP;
  return pending;
}

bool isa_riscv64_plic_in_range(paddr_t addr) {
  return riscv_plic_address_in_aperture(addr);
}

bool isa_riscv64_plic_access_valid(paddr_t addr, int len) {
  return riscv_plic_mmio_access_valid(addr, len);
}

static uint32_t plic_read32(uint32_t offset) {
  RiscvPlicMmioEffect effect;
  uint32_t value = riscv_plic_read_register(&plic, offset, &effect);
  if (effect.kind == RISCV_PLIC_MMIO_CLAIM && effect.accepted) {
#ifdef CONFIG_STATISTIC
    plic_claim_count[effect.source]++;
#endif
    PLIC_DEBUG_LOG(
        "PLIC %s claim irq=%u pending=0x%08x level=0x%08x in_service=0x%08x enable=0x%08x threshold=%u",
        effect.context == RISCV_PLIC_MACHINE_CONTEXT ? "M" : "S",
        effect.source, riscv_plic_pending_bits(&plic), plic.line_level,
        plic.context[effect.context].in_service,
        plic.context[effect.context].enable,
        plic.context[effect.context].threshold);
  }
  return value;
}

static void plic_write32(uint32_t offset, uint32_t value) {
  RiscvPlicMmioEffect effect;
  riscv_plic_write_register(&plic, offset, value, &effect);
  if (effect.kind == RISCV_PLIC_MMIO_COMPLETION && effect.accepted) {
#ifdef CONFIG_STATISTIC
    plic_complete_count[effect.source]++;
#endif
    PLIC_DEBUG_LOG(
        "PLIC %s complete irq=%u pending=0x%08x level=0x%08x in_service=0x%08x",
        effect.context == RISCV_PLIC_MACHINE_CONTEXT ? "M" : "S",
        effect.source, riscv_plic_pending_bits(&plic), plic.line_level,
        plic.context[effect.context].in_service);
  }
}

word_t isa_riscv64_plic_read(paddr_t addr, int len) {
  /* vaddr 预检负责给 guest 抬 access-fault；这里仍防御直接 paddr 调用。 */
  if (!isa_riscv64_plic_access_valid(addr, len)) return 0;
  uint32_t offset = (uint32_t)(addr - RISCV_PLIC_BASE);
  return plic_read32(offset);
}

void isa_riscv64_plic_write(paddr_t addr, int len, word_t data) {
  if (!isa_riscv64_plic_access_valid(addr, len)) return;
  uint32_t offset = (uint32_t)(addr - RISCV_PLIC_BASE);
  plic_write32(offset, (uint32_t)data);
}

void isa_riscv64_plic_statistic(void) {
#ifdef CONFIG_STATISTIC
  for (uint32_t irq = RISCV_PLIC_FIRST_SOURCE;
       irq <= RISCV_PLIC_LAST_SOURCE; irq++) {
    if (plic_claim_count[irq] == 0 && plic_complete_count[irq] == 0) continue;
    uint32_t bit = 1u << irq;
    Log("plic irq%u claim=%" PRIu64 " complete=%" PRIu64
        " level=%u pending=%u in_service=%u",
        irq, plic_claim_count[irq], plic_complete_count[irq],
        (plic.line_level & bit) != 0,
        (riscv_plic_pending_bits(&plic) & bit) != 0,
        (riscv_plic_in_service_bits(&plic) & bit) != 0);
  }
#endif
}
