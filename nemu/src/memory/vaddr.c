/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/
//提供三个接口，vaddr_ifetch（指令抓取）、vaddr_read（数据读取）、vaddr_write（数据写入）
//当前实现直接把虚拟地址当成物理地址，调用paddr_read/paddr_write（即不做地址转换/页表/TLB)
//作为上层（CPU/指令译码）和下层物理内存访问的桥梁，未来可以在这里插入虚拟地址到物理地址的转换逻辑

#include <isa.h>
#include <memory/host.h>
#include <memory/vaddr.h>
#include <memory/cache.h>
#include <memory/paddr.h>
#include <utils/profile.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#if !defined(CONFIG_TARGET_AM) && !defined(CONFIG_TARGET_SHARE)
#include "../monitor/gdbstub.h"
#endif

//添加MTRACE标志，以免每次取值都写入log
bool g_in_ifetch = false;
bool vaddr_fault_pending = false;
static word_t vaddr_fault_cause = 0;
static vaddr_t vaddr_fault_tval = 0;
bool vaddr_ifetch_wide_is_enabled = true;
bool vaddr_host_fast_is_enabled = true;
bool vaddr_write_trace_is_enabled = false;
#define VADDR_WRITE_TRACE_MAX_RANGES 4
static vaddr_t vaddr_write_trace_start = 0;
static vaddr_t vaddr_write_trace_end = 0;
static vaddr_t vaddr_write_trace_extra_start[VADDR_WRITE_TRACE_MAX_RANGES];
static vaddr_t vaddr_write_trace_extra_end[VADDR_WRITE_TRACE_MAX_RANGES];
static uint32_t vaddr_write_trace_range_count = 0;
static uint64_t vaddr_write_trace_max = 4096;
static uint64_t vaddr_write_trace_count = 0;
static bool vaddr_write_trace_user_only = true;
static bool vaddr_write_value_trace_is_enabled = false;
static word_t vaddr_write_value_trace_value = 0;
static word_t vaddr_write_value_trace_mask = (word_t)-1;
static uint64_t vaddr_write_value_trace_max = 4096;
static uint64_t vaddr_write_value_trace_count = 0;
static bool vaddr_write_value_trace_user_only = true;
// 最近一次 vaddr_read 的译址元数据只服务诊断 trace，不参与访存语义。
static bool vaddr_last_read_trace_valid = false;
static vaddr_t vaddr_last_read_trace_vaddr = 0;
static int vaddr_last_read_trace_len = 0;
static paddr_t vaddr_last_read_trace_paddr = 0;

//vaddr是虚拟地址，是cpu执行的时候看到的地址
//paddr是物理地址，是MMU转换过后的结果，直接对应内存芯片

typedef struct {
  paddr_t paddr;
  uint8_t *host_addr;
} VaddrTranslateResult;

static bool runtime_env_enabled_default_true(const char *name) {
#ifndef CONFIG_TARGET_AM
  const char *env = getenv(name);
  return !(env != NULL && env[0] != '\0' && strcmp(env, "0") == 0);
#else
  (void)name;
  return true;
#endif
}

static bool runtime_env_u64(const char *name, uint64_t *value) {
#ifndef CONFIG_TARGET_AM
  const char *env = getenv(name);
  if (env == NULL || env[0] == '\0') {
    return false;
  }
  errno = 0;
  char *end = NULL;
  uint64_t parsed = strtoull(env, &end, 0);
  Assert(errno == 0 && end != env && *end == '\0',
      "invalid %s=%s, expect an integer", name, env);
  *value = parsed;
  return true;
#else
  (void)name;
  (void)value;
  return false;
#endif
}

static inline void vaddr_last_read_trace_clear(void) {
  vaddr_last_read_trace_valid = false;
}

static inline void vaddr_last_read_trace_record(vaddr_t addr, int len,
    paddr_t paddr) {
  vaddr_last_read_trace_valid = true;
  vaddr_last_read_trace_vaddr = addr;
  vaddr_last_read_trace_len = len;
  vaddr_last_read_trace_paddr = paddr;
}

bool vaddr_last_read_paddr(vaddr_t addr, int len, paddr_t *paddr) {
  if (!vaddr_last_read_trace_valid ||
      vaddr_last_read_trace_vaddr != addr ||
      vaddr_last_read_trace_len != len) {
    return false;
  }
  if (paddr != NULL) {
    *paddr = vaddr_last_read_trace_paddr;
  }
  return true;
}

void vaddr_write_trace_arm_range(vaddr_t start, vaddr_t end,
    uint64_t max_count, bool user_only, const char *reason) {
  Assert(end >= start, "vaddr write trace range end must be >= start");
  vaddr_write_trace_is_enabled = true;
  vaddr_write_trace_start = start;
  vaddr_write_trace_end = end;
  vaddr_write_trace_extra_start[0] = start;
  vaddr_write_trace_extra_end[0] = end;
  vaddr_write_trace_range_count = 1;
  vaddr_write_trace_max = max_count;
  vaddr_write_trace_count = 0;
  vaddr_write_trace_user_only = user_only;
  if (reason != NULL) {
    Log("vaddr-write-trace armed start=" FMT_WORD " end=" FMT_WORD
        " max=%" PRIu64 " user_only=%d reason=%s",
        (word_t)start, (word_t)end, max_count, user_only ? 1 : 0, reason);
  }
}

static void vaddr_write_trace_add_range(vaddr_t start, vaddr_t end,
    const char *reason) {
  Assert(end >= start, "vaddr write trace range end must be >= start");
  Assert(vaddr_write_trace_range_count < VADDR_WRITE_TRACE_MAX_RANGES,
      "too many vaddr write trace ranges");
  uint32_t index = vaddr_write_trace_range_count++;
  vaddr_write_trace_extra_start[index] = start;
  vaddr_write_trace_extra_end[index] = end;
  if (reason != NULL) {
    Log("vaddr-write-trace add-range index=%u start=" FMT_WORD
        " end=" FMT_WORD " reason=%s",
        index, (word_t)start, (word_t)end, reason);
  }
}

void vaddr_write_trace_disarm(const char *reason) {
  if (!vaddr_write_trace_is_enabled) return;
  vaddr_write_trace_is_enabled = false;
  if (reason != NULL) {
    Log("vaddr-write-trace disarmed reason=%s count=%" PRIu64,
        reason, vaddr_write_trace_count);
  }
}

void vaddr_write_value_trace_arm(word_t value, word_t mask,
    uint64_t max_count, const char *reason) {
  vaddr_write_value_trace_is_enabled = true;
  vaddr_write_value_trace_value = value;
  vaddr_write_value_trace_mask = mask;
  vaddr_write_value_trace_max = max_count;
  vaddr_write_value_trace_count = 0;
  Log("vaddr-write-value-trace armed value=" FMT_WORD " mask=" FMT_WORD
      " max=%" PRIu64 " reason=%s",
      value, mask, max_count, reason != NULL ? reason : "-");
}

void vaddr_write_value_trace_set_user_only(bool user_only) {
  vaddr_write_value_trace_user_only = user_only;
}

void vaddr_write_value_trace_disarm(const char *reason) {
  if (!vaddr_write_value_trace_is_enabled) return;
  vaddr_write_value_trace_is_enabled = false;
  Log("vaddr-write-value-trace disarmed reason=%s count=%" PRIu64,
      reason != NULL ? reason : "-", vaddr_write_value_trace_count);
}

__attribute__((constructor))
static void vaddr_runtime_config_init(void) {
  vaddr_ifetch_wide_is_enabled =
    runtime_env_enabled_default_true("NEMU_INTERPRETER_WIDE_IFETCH");
  vaddr_host_fast_is_enabled =
    runtime_env_enabled_default_true("NEMU_VADDR_HOST_FAST");

  uint64_t start = 0;
  uint64_t end = 0;
  bool has_start = runtime_env_u64("NEMU_VADDR_WRITE_TRACE_START", &start);
  bool has_end = runtime_env_u64("NEMU_VADDR_WRITE_TRACE_END", &end);
  const char *trace_env = getenv("NEMU_VADDR_WRITE_TRACE");
  bool requested = trace_env != NULL && trace_env[0] != '\0' &&
    strcmp(trace_env, "0") != 0;
  if (requested || has_start || has_end) {
    Assert(has_start && has_end,
        "NEMU_VADDR_WRITE_TRACE requires START and END");
    Assert(end >= start,
        "NEMU_VADDR_WRITE_TRACE range end must be >= start");
    runtime_env_u64("NEMU_VADDR_WRITE_TRACE_MAX", &vaddr_write_trace_max);
    vaddr_write_trace_user_only =
      runtime_env_enabled_default_true("NEMU_VADDR_WRITE_TRACE_USER_ONLY");
    vaddr_write_trace_arm_range((vaddr_t)start, (vaddr_t)end,
        vaddr_write_trace_max, vaddr_write_trace_user_only, NULL);
    for (uint32_t i = 2; i <= VADDR_WRITE_TRACE_MAX_RANGES; i++) {
      char start_name[64];
      char end_name[64];
      snprintf(start_name, sizeof(start_name),
          "NEMU_VADDR_WRITE_TRACE_START%u", i);
      snprintf(end_name, sizeof(end_name),
          "NEMU_VADDR_WRITE_TRACE_END%u", i);
      uint64_t extra_start = 0;
      uint64_t extra_end = 0;
      bool has_extra_start = runtime_env_u64(start_name, &extra_start);
      bool has_extra_end = runtime_env_u64(end_name, &extra_end);
      if (has_extra_start || has_extra_end) {
        Assert(has_extra_start && has_extra_end,
            "extra NEMU_VADDR_WRITE_TRACE range requires STARTn and ENDn");
        vaddr_write_trace_add_range((vaddr_t)extra_start,
            (vaddr_t)extra_end, NULL);
      }
    }
  }

  uint64_t value = 0;
  uint64_t mask = UINT64_MAX;
  bool has_value = runtime_env_u64("NEMU_VADDR_WRITE_VALUE_TRACE_VALUE", &value);
  bool has_mask = runtime_env_u64("NEMU_VADDR_WRITE_VALUE_TRACE_MASK", &mask);
  const char *value_trace_env = getenv("NEMU_VADDR_WRITE_VALUE_TRACE");
  bool value_requested = value_trace_env != NULL && value_trace_env[0] != '\0' &&
    strcmp(value_trace_env, "0") != 0;
  if (value_requested || has_value || has_mask) {
    Assert(has_value, "NEMU_VADDR_WRITE_VALUE_TRACE requires VALUE");
    runtime_env_u64("NEMU_VADDR_WRITE_VALUE_TRACE_MAX",
        &vaddr_write_value_trace_max);
    vaddr_write_value_trace_user_only =
      runtime_env_enabled_default_true("NEMU_VADDR_WRITE_VALUE_TRACE_USER_ONLY");
    vaddr_write_value_trace_arm((word_t)value, (word_t)mask,
        vaddr_write_value_trace_max, "env");
  }
}

void vaddr_write_trace_dump_machine_info(FILE *out) {
  fprintf(out, "runtime.vaddr_write_trace.enabled=%d\n",
      vaddr_write_trace_is_enabled ? 1 : 0);
  fprintf(out, "runtime.vaddr_write_trace.env=NEMU_VADDR_WRITE_TRACE\n");
  fprintf(out, "runtime.vaddr_write_trace.start_env=NEMU_VADDR_WRITE_TRACE_START\n");
  fprintf(out, "runtime.vaddr_write_trace.end_env=NEMU_VADDR_WRITE_TRACE_END\n");
  fprintf(out, "runtime.vaddr_write_trace.max_env=NEMU_VADDR_WRITE_TRACE_MAX\n");
  fprintf(out, "runtime.vaddr_write_trace.user_only_env=NEMU_VADDR_WRITE_TRACE_USER_ONLY\n");
  fprintf(out, "runtime.vaddr_write_trace.extra_start_env=NEMU_VADDR_WRITE_TRACE_START2..4\n");
  fprintf(out, "runtime.vaddr_write_trace.extra_end_env=NEMU_VADDR_WRITE_TRACE_END2..4\n");
  fprintf(out, "runtime.vaddr_write_value_trace.enabled=%d\n",
      vaddr_write_value_trace_is_enabled ? 1 : 0);
  if (vaddr_write_trace_is_enabled) {
    fprintf(out, "runtime.vaddr_write_trace.start=0x%016" PRIx64 "\n",
        (uint64_t)vaddr_write_trace_start);
    fprintf(out, "runtime.vaddr_write_trace.end=0x%016" PRIx64 "\n",
        (uint64_t)vaddr_write_trace_end);
    fprintf(out, "runtime.vaddr_write_trace.max=%" PRIu64 "\n",
        vaddr_write_trace_max);
    fprintf(out, "runtime.vaddr_write_trace.user_only=%d\n",
        vaddr_write_trace_user_only ? 1 : 0);
    fprintf(out, "runtime.vaddr_write_trace.range_count=%u\n",
        vaddr_write_trace_range_count);
    for (uint32_t i = 0; i < vaddr_write_trace_range_count; i++) {
      fprintf(out, "runtime.vaddr_write_trace.range%u=0x%016" PRIx64
          "-0x%016" PRIx64 "\n", i,
          (uint64_t)vaddr_write_trace_extra_start[i],
          (uint64_t)vaddr_write_trace_extra_end[i]);
    }
  }
}

#if defined(CONFIG_INTERPRETER_IFETCH_PAGE_CACHE) && defined(CONFIG_ISA_riscv) && \
    defined(CONFIG_ISA64) && !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
typedef struct {
  bool valid;
  vaddr_t vpage;
  paddr_t ppage;
  word_t satp;
  uint8_t priv;
  uint8_t *host_page;
} VaddrIfetchPageCache;

static VaddrIfetchPageCache ifetch_page_cache;

void vaddr_ifetch_cache_flush(void) {
  nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_CACHE_FLUSHES, 1);
  ifetch_page_cache.valid = false;
}

void vaddr_ifetch_cache_invalidate_paddr(paddr_t addr, uint32_t len) {
  if (!ifetch_page_cache.valid || len == 0) return;
  paddr_t write_start = addr;
  paddr_t write_end = addr + (paddr_t)len - 1;
  paddr_t cache_start = ifetch_page_cache.ppage;
  paddr_t cache_end = ifetch_page_cache.ppage + PAGE_SIZE - 1;
  if (write_end < write_start || (write_start <= cache_end && write_end >= cache_start)) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_CACHE_INVALIDATES, 1);
    vaddr_ifetch_cache_flush();
  }
}

static inline bool vaddr_ifetch_cache_lookup(vaddr_t addr, uint8_t **host_addr) {
  vaddr_t vpage = addr & ~(vaddr_t)PAGE_MASK;
  if (likely(ifetch_page_cache.valid && ifetch_page_cache.vpage == vpage &&
      ifetch_page_cache.satp == cpu.csr.satp && ifetch_page_cache.priv == cpu.priv)) {
    *host_addr = ifetch_page_cache.host_page + (addr & PAGE_MASK);
    nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_CACHE_HITS, 1);
    return true;
  }
  nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_CACHE_MISSES, 1);
  return false;
}

static inline void vaddr_ifetch_cache_fill(vaddr_t addr, VaddrTranslateResult trans) {
  if (trans.host_addr == NULL) return;
  uint64_t page_offset = (uint64_t)addr & PAGE_MASK;
  /*
   * 只缓存 PMEM 页的 host base，并把 satp/priv 纳入 tag；页表或自修改代码
   * 同步点会显式 flush，避免把 host pointer 变成跨地址空间的陈旧翻译。
   */
  ifetch_page_cache = (VaddrIfetchPageCache) {
    .valid = true,
    .vpage = addr & ~(vaddr_t)PAGE_MASK,
    .ppage = trans.paddr & ~(paddr_t)PAGE_MASK,
    .satp = cpu.csr.satp,
    .priv = cpu.priv,
    .host_page = trans.host_addr - page_offset,
  };
  nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_CACHE_FILLS, 1);
}

static inline void vaddr_ifetch_cache_invalidate_write(VaddrTranslateResult trans, int len) {
  if (len <= 0) return;
  vaddr_ifetch_cache_invalidate_paddr(trans.paddr, (uint32_t)len);
}
#else
void vaddr_ifetch_cache_flush(void) {}

void vaddr_ifetch_cache_invalidate_paddr(paddr_t addr, uint32_t len) {
  (void)addr;
  (void)len;
}

static inline bool vaddr_ifetch_cache_lookup(vaddr_t addr, uint8_t **host_addr) {
  (void)addr;
  (void)host_addr;
  return false;
}

static inline void vaddr_ifetch_cache_fill(vaddr_t addr, VaddrTranslateResult trans) {
  (void)addr;
  (void)trans;
}

static inline void vaddr_ifetch_cache_invalidate_write(VaddrTranslateResult trans, int len) {
  (void)trans;
  (void)len;
}
#endif

bool vaddr_take_fault(word_t *cause, vaddr_t *tval) {
  if (!vaddr_fault_pending) return false;
  *cause = vaddr_fault_cause;
  *tval = vaddr_fault_tval;
  vaddr_fault_pending = false;
  return true;
}

void vaddr_set_fault(word_t cause, vaddr_t tval) {
  // 让 ISA 层的精确异常也走 vaddr fault 通道，统一在指令边界投递 trap。
  vaddr_fault_pending = true;
  vaddr_fault_cause = cause;
  vaddr_fault_tval = tval;
  nemu_profile_count_if(NEMU_PROFILE_VADDR_FAULTS, 1);
}

static word_t vaddr_fault_cause_for_type(int type) {
  switch (type) {
    case MEM_TYPE_IFETCH: return CAUSE_INST_PAGE_FAULT;
    case MEM_TYPE_WRITE:  return CAUSE_STORE_PAGE_FAULT;
    case MEM_TYPE_READ:
    default: return CAUSE_LOAD_PAGE_FAULT;
  }
}

static word_t vaddr_translate_fault_cause_for_type(int type) {
#ifdef CONFIG_ISA_riscv
  return isa_riscv_mmu_fault_cause(type);
#else
  return vaddr_fault_cause_for_type(type);
#endif
}

static word_t vaddr_access_fault_cause_for_type(int type) {
  switch (type) {
    case MEM_TYPE_IFETCH: return CAUSE_INST_ACCESS;
    case MEM_TYPE_WRITE:  return CAUSE_STORE_ACCESS;
    case MEM_TYPE_READ:
    default: return CAUSE_LOAD_ACCESS;
  }
}

static inline uint8_t *vaddr_paddr_host_fast(paddr_t paddr) {
#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  if (unlikely(!vaddr_host_fast_runtime_enabled())) {
    return NULL;
  }
  if (likely(in_pmem(paddr))) {
    return guest_to_host(paddr);
  }
#endif
  return NULL;
}

static inline bool vaddr_pmp_check_or_fault(VaddrTranslateResult *trans,
    vaddr_t addr, int len, int type) {
#ifdef CONFIG_ISA_riscv
  /*
   * PMA: 物理地址不落在任何合法窗口 (pmem/CLINT/PLIC/SoC/已注册 MMIO) 时，
   * 抬 guest access-fault，而不是让 paddr/mmio 层用 host assert/panic 崩掉整个进程。
   * guest 可控的越界访存 (未支持分页模式导致 VA 当 PA、随机压测程序等) 只应产生精确异常，
   * 交给 guest 的 trap handler；这是把 NEMU 当 reference 跑不可信/随机程序 (rv64dv) 的可靠性前提。
   */
  if (unlikely(!paddr_is_accessible(trans->paddr, len))) {
    trans->host_addr = NULL;
    vaddr_set_fault(vaddr_access_fault_cause_for_type(type), addr);
    return false;
  }
  /*
   * PMP/PMA 类保护发生在最终物理地址上。MMU 翻译失败仍是 page fault；
   * 翻译成功但 PMP 拒绝时才报告 access fault，避免把保护错误混成页表错误。
   */
  if (!isa_riscv_pmp_check(trans->paddr, len, type)) {
    trans->host_addr = NULL;
    vaddr_set_fault(vaddr_access_fault_cause_for_type(type), addr);
    return false;
  }
#else
  (void)trans;
  (void)addr;
  (void)len;
  (void)type;
#endif
  return true;
}

static VaddrTranslateResult vaddr_translate_checked(vaddr_t addr, int len, int type) {
  VaddrTranslateResult result = { .paddr = 0, .host_addr = NULL };
  int mmu = isa_mmu_check(addr, len, type);
  if (mmu == MMU_DIRECT) {
    result.paddr = (paddr_t)addr;
    result.host_addr = vaddr_paddr_host_fast(result.paddr);
    vaddr_pmp_check_or_fault(&result, addr, len, type);
    return result;
  }

  if (mmu != MMU_TRANSLATE) {
    vaddr_set_fault(vaddr_fault_cause_for_type(type), addr);
    return result;
  }

#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE) && \
    defined(CONFIG_ISA_riscv) && defined(CONFIG_ISA64)
  if (!isa_mmu_translate_host(addr, len, type, &result.paddr, &result.host_addr)) {
    vaddr_set_fault(vaddr_translate_fault_cause_for_type(type), addr);
    return result;
  }
  vaddr_pmp_check_or_fault(&result, addr, len, type);
#else
  result.paddr = isa_mmu_translate(addr, len, type);
  if (result.paddr == (paddr_t)-1) {
    vaddr_set_fault(vaddr_translate_fault_cause_for_type(type), addr);
    return result;
  }
  result.host_addr = vaddr_paddr_host_fast(result.paddr);
  vaddr_pmp_check_or_fault(&result, addr, len, type);
#endif
  return result;
}

static inline word_t vaddr_paddr_read_fast(VaddrTranslateResult trans, int len) {
#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  /*
   * Ubuntu performance 配置关闭 cache/MTRACE 后，TLB/direct 翻译会尽量给出
   * PMEM host_addr；命中时直接落到 host buffer，非 PMEM 仍回落 paddr 层。
   */
  if (likely(trans.host_addr != NULL)) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_HOST_FAST_READS, 1);
    return host_read(trans.host_addr, len);
  }
#endif
  nemu_profile_count_if(NEMU_PROFILE_VADDR_PADDR_FALLBACK_READS, 1);
  return paddr_read(trans.paddr, len);
}

static inline void vaddr_gdbstub_watchpoint_after_access(vaddr_t addr, int len,
    bool is_write) {
#if !defined(CONFIG_TARGET_AM) && !defined(CONFIG_TARGET_SHARE)
  if (gdbstub_fast_enabled()) {
    gdbstub_watchpoint_after_access(addr, len, is_write);
  }
#else
  (void)addr;
  (void)len;
  (void)is_write;
#endif
}

static inline void vaddr_paddr_write_fast(VaddrTranslateResult trans, int len, word_t data) {
#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  if (likely(trans.host_addr != NULL)) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_HOST_FAST_WRITES, 1);
    host_write(trans.host_addr, len, data);
    // The host-fast path writes PMEM directly, so mirror paddr_write()'s
    // tohost check here for Linux performance configs.
    paddr_tohost_check_write(trans.paddr, (uint32_t)len);
    return;
  }
#endif
  nemu_profile_count_if(NEMU_PROFILE_VADDR_PADDR_FALLBACK_WRITES, 1);
  paddr_write(trans.paddr, len, data);
}

static inline bool vaddr_write_host_fast_hit(VaddrTranslateResult trans) {
#if !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  return trans.host_addr != NULL;
#else
  (void)trans;
  return false;
#endif
}

static bool vaddr_write_trace_range_overlap(vaddr_t addr, int len) {
  if (len <= 0) return false;
  uint64_t access_start = (uint64_t)addr;
  uint64_t access_end = access_start + (uint64_t)len - 1;
  if (access_end < access_start) access_end = UINT64_MAX;
  for (uint32_t i = 0; i < vaddr_write_trace_range_count; i++) {
    if (access_start <= (uint64_t)vaddr_write_trace_extra_end[i] &&
        access_end >= (uint64_t)vaddr_write_trace_extra_start[i]) {
      return true;
    }
  }
  return false;
}

static inline word_t vaddr_write_trace_data_mask(word_t data, int len) {
  if (len <= 0) return 0;
  if ((size_t)len >= sizeof(word_t)) return data;
  word_t mask = (((word_t)1) << (len * 8)) - 1;
  return data & mask;
}

static bool vaddr_write_value_trace_match_byte(word_t data, int len,
    uint32_t *byte_offset) {
  if (vaddr_write_value_trace_mask > 0xff ||
      vaddr_write_value_trace_value > 0xff) {
    return false;
  }
  int checked_len = len < (int)sizeof(word_t) ? len : (int)sizeof(word_t);
  for (int i = 0; i < checked_len; i++) {
    word_t byte = (data >> (i * 8)) & 0xffu;
    if ((byte & vaddr_write_value_trace_mask) ==
        (vaddr_write_value_trace_value & vaddr_write_value_trace_mask)) {
      *byte_offset = (uint32_t)i;
      return true;
    }
  }
  return false;
}

static void vaddr_write_trace_after_write(vaddr_t addr, int len, word_t data,
    VaddrTranslateResult trans, bool host_fast) {
  if (unlikely(vaddr_write_value_trace_is_enabled)) {
#ifdef CONFIG_ISA_riscv
    if (vaddr_write_value_trace_user_only && cpu.priv != PRIV_U) {
      goto skip_value_trace;
    }
#endif
    word_t masked_data = vaddr_write_trace_data_mask(data, len);
    bool exact_match = (masked_data & vaddr_write_value_trace_mask) ==
      (vaddr_write_value_trace_value & vaddr_write_value_trace_mask);
    uint32_t byte_offset = UINT32_MAX;
    bool byte_match =
      vaddr_write_value_trace_match_byte(masked_data, len, &byte_offset);
    if ((vaddr_write_value_trace_max == 0 ||
          vaddr_write_value_trace_count < vaddr_write_value_trace_max) &&
        (exact_match || byte_match)) {
      vaddr_write_value_trace_count++;
      Log("vaddr-write-value-trace count=%" PRIu64
          " match=%s byte_offset=%u vaddr=" FMT_WORD " paddr=" FMT_PADDR
          " len=%d data=" FMT_WORD " value=" FMT_WORD " mask=" FMT_WORD
          " pc=" FMT_WORD " priv=%u satp=" FMT_WORD " host_fast=%d",
          vaddr_write_value_trace_count, exact_match ? "exact" : "byte",
          exact_match ? 0 : byte_offset, (word_t)addr, trans.paddr, len, masked_data,
          vaddr_write_value_trace_value, vaddr_write_value_trace_mask, cpu.pc,
          cpu.priv, MUXDEF(CONFIG_ISA_riscv, cpu.csr.satp, 0),
          host_fast ? 1 : 0);
    }
  }
skip_value_trace:
  if (likely(!vaddr_write_trace_runtime_enabled())) return;
  if (vaddr_write_trace_max != 0 &&
      vaddr_write_trace_count >= vaddr_write_trace_max) {
    return;
  }
#ifdef CONFIG_ISA_riscv
  if (vaddr_write_trace_user_only && cpu.priv != PRIV_U) {
    return;
  }
#endif
  if (!vaddr_write_trace_range_overlap(addr, len)) {
    return;
  }
  vaddr_write_trace_count++;
  // 该 trace 只在显式 env 打开时生效，用来追 PyLongObject header 等 guest 用户态写坏来源。
  Log("vaddr-write-trace count=%" PRIu64 " vaddr=" FMT_WORD
      " len=%d data=" FMT_WORD " paddr=" FMT_PADDR
      " pc=" FMT_WORD " priv=%u satp=" FMT_WORD " host_fast=%d",
      vaddr_write_trace_count, (word_t)addr, len,
      vaddr_write_trace_data_mask(data, len), trans.paddr, cpu.pc,
      cpu.priv, MUXDEF(CONFIG_ISA_riscv, cpu.csr.satp, 0), host_fast ? 1 : 0);
}

static inline void vaddr_notify_write_committed(VaddrTranslateResult trans, int len) {
#ifdef CONFIG_ISA_riscv
  /*
   * LR/SC reservation 是 RISC-V ISA 状态，但所有普通/压缩/浮点 store
   * 最终都会走到 vaddr 写路径；在这里用物理地址统一失效，避免各指令
   * helper 各补一份 reservation 逻辑，也能覆盖 Sv39 alias 写入。
   */
  isa_riscv_lr_sc_invalidate(trans.paddr, len);
#else
  (void)trans;
  (void)len;
#endif
}

static inline word_t vaddr_read_one_translated(vaddr_t addr, int len, int type,
    VaddrTranslateResult trans) {
  vaddr_last_read_trace_record(addr, len, trans.paddr);
  word_t ret = MUXDEF(CONFIG_CACHE,
      (type == MEM_TYPE_IFETCH ? icache_read(trans.paddr, len) : dcache_read(trans.paddr, len)),
      vaddr_paddr_read_fast(trans, len));
  if (type == MEM_TYPE_READ) {
    vaddr_gdbstub_watchpoint_after_access(addr, len, false);
  }
  return ret;
}

static inline void vaddr_write_one_translated(vaddr_t addr, int len, word_t data,
    VaddrTranslateResult trans) {
#ifdef CONFIG_CACHE
  dcache_write(trans.paddr, len, data);
  bool host_fast = false;
#else
  vaddr_ifetch_cache_invalidate_write(trans, len);
  bool host_fast = vaddr_write_host_fast_hit(trans);
  vaddr_paddr_write_fast(trans, len, data);
#endif
  vaddr_notify_write_committed(trans, len);
  vaddr_write_trace_after_write(addr, len, data, trans, host_fast);
}

static bool vaddr_atomic_translate_checked(vaddr_t addr, int len, int type,
    VaddrTranslateResult *trans) {
  *trans = vaddr_translate_checked(addr, len, type);
  if (vaddr_fault_pending) return false;
  /*
   * 原子能力属于物理区域属性。NEMU 当前只为 PMEM 声明完整 A 扩展，
   * 对设备窗口 fail closed，避免 MMIO read/write 副作用被错误拼成 AMO。
   */
  if (!paddr_supports_atomic(trans->paddr, len)) {
    vaddr_set_fault(vaddr_access_fault_cause_for_type(type), addr);
    return false;
  }
  return true;
}

bool vaddr_atomic_load_reserved(vaddr_t addr, int len,
    word_t *value, paddr_t *paddr) {
  vaddr_last_read_trace_clear();
  VaddrTranslateResult trans;
  if (!vaddr_atomic_translate_checked(addr, len, MEM_TYPE_READ, &trans)) {
    return false;
  }
  *value = vaddr_read_one_translated(addr, len, MEM_TYPE_READ, trans);
  *paddr = trans.paddr;
  return true;
}

bool vaddr_atomic_store_conditional(vaddr_t addr, int len, word_t data,
    bool reservation_valid, paddr_t reservation_paddr, bool *stored) {
  VaddrTranslateResult trans;
  /*
   * 即使 reservation 已失效，SC 退休前仍必须完成 store/AMO 权限检查；
   * 只有翻译和 PMA 均成功后，reservation 才决定是否真正提交写入。
   */
  if (!vaddr_atomic_translate_checked(addr, len, MEM_TYPE_WRITE, &trans)) {
    return false;
  }
  *stored = reservation_valid && trans.paddr == reservation_paddr;
  if (*stored) {
    vaddr_write_one_translated(addr, len, data, trans);
    vaddr_gdbstub_watchpoint_after_access(addr, len, true);
  }
  return true;
}

bool vaddr_atomic_rmw(vaddr_t addr, int len, vaddr_atomic_compute_t compute,
    const void *opaque, word_t *old_value) {
  vaddr_last_read_trace_clear();
  VaddrTranslateResult trans;
  /*
   * AMO 的显式访问统一按 store/AMO 分类。一次写类型翻译同时验证页表写权限，
   * 再补读侧 PMP 权限；任何失败都报告 store/AMO fault，而不是 load fault。
   */
  if (!vaddr_atomic_translate_checked(addr, len, MEM_TYPE_WRITE, &trans)) {
    return false;
  }
#ifdef CONFIG_ISA_riscv
  if (!isa_riscv_pmp_check(trans.paddr, len, MEM_TYPE_READ)) {
    vaddr_set_fault(vaddr_access_fault_cause_for_type(MEM_TYPE_WRITE), addr);
    return false;
  }
#endif

  word_t old = vaddr_read_one_translated(addr, len, MEM_TYPE_WRITE, trans);
  vaddr_gdbstub_watchpoint_after_access(addr, len, false);
  word_t data = compute(old, opaque);
  vaddr_write_one_translated(addr, len, data, trans);
  vaddr_gdbstub_watchpoint_after_access(addr, len, true);
  *old_value = old;
  return true;
}

static word_t vaddr_read_translated(vaddr_t addr, int len, int type) {
  vaddr_last_read_trace_clear();
  if (((addr & PAGE_MASK) + len) > PAGE_SIZE) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_CROSS_PAGE_READS, 1);
    word_t ret = 0;
    for (int i = 0; i < len; i++) {
      ret |= vaddr_read_translated(addr + i, 1, type) << (i * 8);
    }
    return ret;
  }
  VaddrTranslateResult trans = vaddr_translate_checked(addr, len, type);
  if (vaddr_fault_pending) return 0;
  return vaddr_read_one_translated(addr, len, type, trans);
}

word_t vaddr_ifetch(vaddr_t addr, int len) {
  nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_CALLS, 1);
  g_in_ifetch = true;
  // 取指和数据访存从这里分流，便于分别统计 ICache/DCache，同时保留 paddr 层的 MMIO 处理。
  word_t ret = vaddr_read_translated(addr, len, MEM_TYPE_IFETCH);
  g_in_ifetch = false;
  return ret;
}

VaddrIfetchWideResult vaddr_ifetch_wide(vaddr_t addr) {
#if defined(CONFIG_INTERPRETER_WIDE_IFETCH) && defined(CONFIG_RISCV_EXT_C) && \
    !defined(CONFIG_CACHE) && !defined(CONFIG_MTRACE)
  nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_WIDE_ATTEMPTS, 1);
  if (unlikely(!vaddr_ifetch_wide_runtime_enabled())) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_WIDE_DISABLED, 1);
    return VADDR_IFETCH_WIDE_MISS;
  }

  if (((addr & PAGE_MASK) + 4) > PAGE_SIZE) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_WIDE_CROSS_PAGE, 1);
    return VADDR_IFETCH_WIDE_MISS;
  }

  uint8_t *cached_host_addr = NULL;
  if (vaddr_ifetch_cache_lookup(addr, &cached_host_addr)) {
    uint32_t raw = 0;
    memcpy(&raw, cached_host_addr, sizeof(raw));
    nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_WIDE_HITS, 1);
    return vaddr_ifetch_wide_pack(raw);
  }

  g_in_ifetch = true;
  VaddrTranslateResult trans = vaddr_translate_checked(addr, 4, MEM_TYPE_IFETCH);
  g_in_ifetch = false;
  if (vaddr_fault_pending) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_WIDE_FAULTS, 1);
    return VADDR_IFETCH_WIDE_FAULT;
  }
  if (trans.host_addr == NULL) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_WIDE_PADDR_FALLBACKS, 1);
    return VADDR_IFETCH_WIDE_MISS;
  }
  vaddr_ifetch_cache_fill(addr, trans);

  /*
   * RVC 取指通常先取 16 bit 再决定是否补取后半字。Ubuntu 热路径中
   * PMEM 同页命中时直接读 4 字节，只缓存“原始取指包”，不缓存译码结果；
   * MMIO/跨页/fault 仍走旧路径，避免额外设备读或改变精确异常地址。
   */
  uint32_t raw = 0;
  memcpy(&raw, trans.host_addr, sizeof(raw));
  nemu_profile_count_if(NEMU_PROFILE_VADDR_IFETCH_WIDE_HITS, 1);
  return vaddr_ifetch_wide_pack(raw);
#else
  (void)addr;
  return VADDR_IFETCH_WIDE_MISS;
#endif
}

word_t vaddr_read(vaddr_t addr, int len) {
  return vaddr_read_translated(addr, len, MEM_TYPE_READ);
}

void vaddr_write(vaddr_t addr, int len, word_t data) {
  if (((addr & PAGE_MASK) + len) > PAGE_SIZE) {
    nemu_profile_count_if(NEMU_PROFILE_VADDR_CROSS_PAGE_WRITES, 1);
    VaddrTranslateResult translations[8];
    assert(len <= (int)ARRLEN(translations));
    /* 跨页 store 必须先完成全部翻译，再真正写内存；否则后半截 page fault
     * 会留下前半截写入，破坏 Linux demand paging 依赖的精确异常语义。 */
    for (int i = 0; i < len; i++) {
      translations[i] = vaddr_translate_checked(addr + i, 1, MEM_TYPE_WRITE);
      if (vaddr_fault_pending) return;
    }
    for (int i = 0; i < len; i++) {
      vaddr_write_one_translated(addr + i, 1, data >> (i * 8), translations[i]);
    }
    vaddr_gdbstub_watchpoint_after_access(addr, len, true);
    return;
  }
  VaddrTranslateResult trans = vaddr_translate_checked(addr, len, MEM_TYPE_WRITE);
  if (vaddr_fault_pending) return;
  vaddr_write_one_translated(addr, len, data, trans);
  vaddr_gdbstub_watchpoint_after_access(addr, len, true);
}
