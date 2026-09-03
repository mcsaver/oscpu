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

//管理物理内存（pmem）与外设映射（MMIO）

#include <memory/host.h>
#include <memory/paddr.h>
#include <memory/vaddr.h>
#include <memory/cache.h>
#include <memory/soc.h>
#include <device/mmio.h>
#include <cpu/cpu.h>
#include <cpu/difftest.h>
#include <isa/riscv/clint.h>
#include <isa/riscv/plic.h>
#include <platform/platform-map.h>
#include <utils/profile.h>
#include <isa.h>
#include <errno.h>
#include <limits.h>
#include <stdlib.h>

#ifdef CONFIG_MTRACE
  #define CONFIG_MTRACE_START 0x80000000
  #define CONFIG_MTRACE_END 0x90000000
#endif

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

bool paddr_device_write_seen = false;
bool paddr_write_trace_is_enabled = false;
static paddr_t paddr_write_trace_start = 0;
static paddr_t paddr_write_trace_end = 0;
static uint64_t paddr_write_trace_max = 4096;
static uint64_t paddr_write_trace_count = 0;
static bool paddr_write_value_trace_is_enabled = false;
static word_t paddr_write_value_trace_value = 0;
static word_t paddr_write_value_trace_mask = (word_t)-1;
static uint64_t paddr_write_value_trace_max = 4096;
static uint64_t paddr_write_value_trace_count = 0;
// ACT4/riscv-tests report PASS/FAIL through a tohost memory word.
// Keep it disabled unless the command line explicitly passes --tohost.
static bool paddr_tohost_is_enabled = false;
static paddr_t paddr_tohost_addr = 0;

static bool paddr_trace_snapshot_range_ok(paddr_t addr, uint32_t len) {
  if (len == 0) return false;
  paddr_t end = addr + (paddr_t)len - 1;
  return end >= addr && in_pmem(addr) && in_pmem(end);
}

static void paddr_write_trace_log_snapshot(const char *phase,
    const char *reason) {
  uint64_t raw_len = (uint64_t)paddr_write_trace_end -
    (uint64_t)paddr_write_trace_start + 1;
  uint32_t len = raw_len > 32 ? 32 : (uint32_t)raw_len;
  if (!paddr_trace_snapshot_range_ok(paddr_write_trace_start, len)) {
    Log("paddr-write-trace snapshot phase=%s reason=%s ok=0 paddr=" FMT_PADDR
        " len=%u",
        phase != NULL ? phase : "-",
        reason != NULL ? reason : "-",
        paddr_write_trace_start, len);
    return;
  }

  const uint8_t *src = guest_to_host(paddr_write_trace_start);
  word_t first = 0;
  uint32_t take = len < sizeof(first) ? len : (uint32_t)sizeof(first);
  memcpy(&first, src, take);
  char bytes[32 * 2 + 1];
  for (uint32_t i = 0; i < len; i++) {
    snprintf(bytes + i * 2, sizeof(bytes) - i * 2, "%02x", src[i]);
  }
  bytes[len * 2] = '\0';

  Log("paddr-write-trace snapshot phase=%s reason=%s ok=1 paddr=" FMT_PADDR
      " len=%u first=" FMT_WORD " bytes=%s pc=" FMT_WORD
      " priv=%u satp=" FMT_WORD,
      phase != NULL ? phase : "-",
      reason != NULL ? reason : "-",
      paddr_write_trace_start, len, first, bytes, cpu.pc,
      MUXDEF(CONFIG_ISA_riscv, cpu.priv, 0),
      MUXDEF(CONFIG_ISA_riscv, cpu.csr.satp, 0));
}

#ifndef CONFIG_TARGET_AM
static bool paddr_runtime_env_u64(const char *name, uint64_t *value) {
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
}
#endif

void paddr_write_trace_arm_range(paddr_t start, paddr_t end,
    uint64_t max_count, const char *reason) {
  Assert(end >= start, "paddr write trace range end must be >= start");
  paddr_write_trace_is_enabled = true;
  paddr_write_trace_start = start;
  paddr_write_trace_end = end;
  paddr_write_trace_max = max_count;
  paddr_write_trace_count = 0;
  if (reason != NULL) {
    Log("paddr-write-trace armed start=" FMT_PADDR " end=" FMT_PADDR
        " max=%" PRIu64 " reason=%s",
        start, end, max_count, reason);
  }
  paddr_write_trace_log_snapshot("arm", reason);
}

void paddr_write_trace_disarm(const char *reason) {
  if (!paddr_write_trace_is_enabled) return;
  paddr_write_trace_log_snapshot("disarm", reason);
  paddr_write_trace_is_enabled = false;
  if (reason != NULL) {
    Log("paddr-write-trace disarmed reason=%s count=%" PRIu64,
        reason, paddr_write_trace_count);
  }
}

void paddr_write_value_trace_arm(word_t value, word_t mask,
    uint64_t max_count, const char *reason) {
  paddr_write_value_trace_is_enabled = true;
  paddr_write_value_trace_value = value;
  paddr_write_value_trace_mask = mask;
  paddr_write_value_trace_max = max_count;
  paddr_write_value_trace_count = 0;
  Log("paddr-write-value-trace armed value=" FMT_WORD " mask=" FMT_WORD
      " max=%" PRIu64 " reason=%s",
      value, mask, max_count, reason != NULL ? reason : "-");
}

void paddr_write_value_trace_disarm(const char *reason) {
  if (!paddr_write_value_trace_is_enabled) return;
  paddr_write_value_trace_is_enabled = false;
  Log("paddr-write-value-trace disarmed reason=%s count=%" PRIu64,
      reason != NULL ? reason : "-", paddr_write_value_trace_count);
}

__attribute__((constructor))
static void paddr_runtime_config_init(void) {
#ifndef CONFIG_TARGET_AM
  uint64_t start = 0;
  uint64_t end = 0;
  bool has_start = paddr_runtime_env_u64("NEMU_PADDR_WRITE_TRACE_START", &start);
  bool has_end = paddr_runtime_env_u64("NEMU_PADDR_WRITE_TRACE_END", &end);
  const char *trace_env = getenv("NEMU_PADDR_WRITE_TRACE");
  bool requested = trace_env != NULL && trace_env[0] != '\0' &&
    strcmp(trace_env, "0") != 0;
  if (requested || has_start || has_end) {
    Assert(has_start && has_end,
        "NEMU_PADDR_WRITE_TRACE requires START and END");
    Assert(end >= start,
        "NEMU_PADDR_WRITE_TRACE range end must be >= start");
    paddr_runtime_env_u64("NEMU_PADDR_WRITE_TRACE_MAX", &paddr_write_trace_max);
    paddr_write_trace_arm_range((paddr_t)start, (paddr_t)end,
        paddr_write_trace_max, NULL);
  }

  uint64_t value = 0;
  uint64_t mask = UINT64_MAX;
  bool has_value = paddr_runtime_env_u64("NEMU_PADDR_WRITE_VALUE_TRACE_VALUE", &value);
  bool has_mask = paddr_runtime_env_u64("NEMU_PADDR_WRITE_VALUE_TRACE_MASK", &mask);
  const char *value_trace_env = getenv("NEMU_PADDR_WRITE_VALUE_TRACE");
  bool value_requested = value_trace_env != NULL && value_trace_env[0] != '\0' &&
    strcmp(value_trace_env, "0") != 0;
  if (value_requested || has_value || has_mask) {
    Assert(has_value, "NEMU_PADDR_WRITE_VALUE_TRACE requires VALUE");
    paddr_runtime_env_u64("NEMU_PADDR_WRITE_VALUE_TRACE_MAX",
        &paddr_write_value_trace_max);
    paddr_write_value_trace_arm((word_t)value, (word_t)mask,
        paddr_write_value_trace_max, "env");
  }
#endif
}

void paddr_write_trace_dump_machine_info(FILE *out) {
  fprintf(out, "runtime.paddr_write_trace.enabled=%d\n",
      paddr_write_trace_is_enabled ? 1 : 0);
  fprintf(out, "runtime.paddr_write_trace.env=NEMU_PADDR_WRITE_TRACE\n");
  fprintf(out, "runtime.paddr_write_trace.start_env=NEMU_PADDR_WRITE_TRACE_START\n");
  fprintf(out, "runtime.paddr_write_trace.end_env=NEMU_PADDR_WRITE_TRACE_END\n");
  fprintf(out, "runtime.paddr_write_trace.max_env=NEMU_PADDR_WRITE_TRACE_MAX\n");
  if (paddr_write_trace_is_enabled) {
    fprintf(out, "runtime.paddr_write_trace.start=0x%016" PRIx64 "\n",
        (uint64_t)paddr_write_trace_start);
    fprintf(out, "runtime.paddr_write_trace.end=0x%016" PRIx64 "\n",
        (uint64_t)paddr_write_trace_end);
    fprintf(out, "runtime.paddr_write_trace.max=%" PRIu64 "\n",
        paddr_write_trace_max);
  }
  fprintf(out, "runtime.paddr_write_value_trace.enabled=%d\n",
      paddr_write_value_trace_is_enabled ? 1 : 0);
  fprintf(out, "runtime.tohost.enabled=%d\n",
      paddr_tohost_is_enabled ? 1 : 0);
  if (paddr_tohost_is_enabled) {
    fprintf(out, "runtime.tohost.addr=0x%016" PRIx64 "\n",
        (uint64_t)paddr_tohost_addr);
  }
}

static bool paddr_write_trace_range_overlap(paddr_t addr, uint32_t len) {
  if (len == 0) return false;
  uint64_t access_start = (uint64_t)addr;
  uint64_t access_end = access_start + (uint64_t)len - 1;
  if (access_end < access_start) access_end = UINT64_MAX;
  return access_start <= (uint64_t)paddr_write_trace_end &&
    access_end >= (uint64_t)paddr_write_trace_start;
}

static word_t paddr_write_trace_first_word(const void *buf, uint32_t len) {
  if (buf == NULL || len == 0) return 0;
  word_t ret = 0;
  uint32_t take = len < sizeof(ret) ? len : (uint32_t)sizeof(ret);
  memcpy(&ret, buf, take);
  return ret;
}

static bool paddr_write_value_trace_match_byte(word_t first_word, uint32_t len,
    uint32_t *byte_offset) {
  if (paddr_write_value_trace_mask > 0xff ||
      paddr_write_value_trace_value > 0xff) {
    return false;
  }
  uint32_t take = len < sizeof(first_word) ? len : (uint32_t)sizeof(first_word);
  for (uint32_t i = 0; i < take; i++) {
    word_t byte = (first_word >> (i * 8)) & 0xffu;
    if ((byte & paddr_write_value_trace_mask) ==
        (paddr_write_value_trace_value & paddr_write_value_trace_mask)) {
      if (byte_offset != NULL) *byte_offset = i;
      return true;
    }
  }
  return false;
}

static bool paddr_write_value_trace_match_buffer(const void *buf, uint32_t len,
    word_t first_word, uint32_t *match_offset, word_t *match_word,
    bool *is_byte_match) {
  if (len == 0) return false;

  if (paddr_write_value_trace_mask <= 0xff &&
      paddr_write_value_trace_value <= 0xff) {
    uint32_t byte_offset = 0;
    if (buf != NULL) {
      const uint8_t *bytes = (const uint8_t *)buf;
      for (uint32_t i = 0; i < len; i++) {
        if ((bytes[i] & paddr_write_value_trace_mask) ==
            (paddr_write_value_trace_value & paddr_write_value_trace_mask)) {
          if (match_offset != NULL) *match_offset = i;
          if (match_word != NULL) {
            word_t word = 0;
            uint32_t take = len - i < sizeof(word) ? len - i : (uint32_t)sizeof(word);
            memcpy(&word, bytes + i, take);
            *match_word = word;
          }
          if (is_byte_match != NULL) *is_byte_match = true;
          return true;
        }
      }
      return false;
    }
    if (paddr_write_value_trace_match_byte(first_word, len, &byte_offset)) {
      if (match_offset != NULL) *match_offset = byte_offset;
      if (match_word != NULL) *match_word = first_word;
      if (is_byte_match != NULL) *is_byte_match = true;
      return true;
    }
    return false;
  }

  if (buf != NULL && len >= sizeof(word_t)) {
    const uint8_t *bytes = (const uint8_t *)buf;
    for (uint32_t i = 0; i + sizeof(word_t) <= len; i++) {
      word_t word = 0;
      memcpy(&word, bytes + i, sizeof(word));
      if ((word & paddr_write_value_trace_mask) ==
          (paddr_write_value_trace_value & paddr_write_value_trace_mask)) {
        if (match_offset != NULL) *match_offset = i;
        if (match_word != NULL) *match_word = word;
        if (is_byte_match != NULL) *is_byte_match = false;
        return true;
      }
    }
    return false;
  }

  if ((first_word & paddr_write_value_trace_mask) ==
      (paddr_write_value_trace_value & paddr_write_value_trace_mask)) {
    if (match_offset != NULL) *match_offset = 0;
    if (match_word != NULL) *match_word = first_word;
    if (is_byte_match != NULL) *is_byte_match = false;
    return true;
  }
  return false;
}

static void paddr_write_trace_after_write(paddr_t addr, uint32_t len,
    word_t first_word, const void *buf, const char *source) {
  if (unlikely(paddr_write_value_trace_is_enabled)) {
    uint32_t match_offset = 0;
    word_t match_word = first_word;
    bool byte_match = false;
    bool matched = paddr_write_value_trace_match_buffer(buf, len, first_word,
        &match_offset, &match_word, &byte_match);
    if ((paddr_write_value_trace_max == 0 ||
          paddr_write_value_trace_count < paddr_write_value_trace_max) &&
        matched) {
      paddr_write_value_trace_count++;
      Log("paddr-write-value-trace count=%" PRIu64
          " match=%s match_offset=%u source=%s paddr="
          FMT_PADDR " match_paddr=" FMT_PADDR
          " len=%u first=" FMT_WORD " matched=" FMT_WORD " value=" FMT_WORD
          " mask=" FMT_WORD " pc=" FMT_WORD " priv=%u satp=" FMT_WORD,
          paddr_write_value_trace_count, byte_match ? "byte" : "exact",
          match_offset,
          source, addr, addr + (paddr_t)match_offset, len, first_word,
          match_word,
          paddr_write_value_trace_value, paddr_write_value_trace_mask, cpu.pc,
          MUXDEF(CONFIG_ISA_riscv, cpu.priv, 0),
          MUXDEF(CONFIG_ISA_riscv, cpu.csr.satp, 0));
    }
  }
  if (likely(!paddr_write_trace_runtime_enabled())) return;
  if (paddr_write_trace_max != 0 &&
      paddr_write_trace_count >= paddr_write_trace_max) {
    return;
  }
  if (!paddr_write_trace_range_overlap(addr, len)) {
    return;
  }
  paddr_write_trace_count++;
  Log("paddr-write-trace count=%" PRIu64 " source=%s paddr=" FMT_PADDR
      " len=%u first=" FMT_WORD " pc=" FMT_WORD " priv=%u satp=" FMT_WORD,
      paddr_write_trace_count, source, addr, len, first_word, cpu.pc,
      MUXDEF(CONFIG_ISA_riscv, cpu.priv, 0),
      MUXDEF(CONFIG_ISA_riscv, cpu.csr.satp, 0));
}

static inline void paddr_note_device_write(void) {
  paddr_device_write_seen = true;
}

bool paddr_take_device_write(void) {
  bool seen = paddr_device_write_seen;
  paddr_device_write_seen = false;
  return seen;
}

//guest物理地址与模拟器主机内存地址的映射转换
uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

//在主内存（pmem）上读写，使用host_read/host_write做按字节宽度的安全访问
//
static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static bool pmem_range_ok(paddr_t addr, uint32_t len) {
  return len == 0 || paddr_span_in_pmem(addr, len);
}

void paddr_tohost_set_addr(paddr_t addr) {
  Assert((addr & (sizeof(word_t) - 1u)) == 0,
      "--tohost address must be %zu-byte aligned: " FMT_PADDR,
      sizeof(word_t), addr);
  Assert(pmem_range_ok(addr, sizeof(word_t)),
      "--tohost address is outside PMEM: " FMT_PADDR, addr);
  paddr_tohost_addr = addr;
  paddr_tohost_is_enabled = true;
}

static bool paddr_tohost_range_overlap(paddr_t addr, uint32_t len) {
  if (!paddr_tohost_is_enabled || len == 0) return false;
  uint64_t access_start = (uint64_t)addr;
  uint64_t access_end = access_start + (uint64_t)len - 1;
  if (access_end < access_start) access_end = UINT64_MAX;
  uint64_t tohost_start = (uint64_t)paddr_tohost_addr;
  uint64_t tohost_end = tohost_start + sizeof(word_t) - 1;
  return access_start <= tohost_end && access_end >= tohost_start;
}

static uint64_t paddr_tohost_decode_exit(word_t value) {
  if (value == 1) {
    return 0;
  }
  if ((value & 1u) != 0) {
    uint64_t code = (uint64_t)(value >> 1);
    return code == 0 ? 1 : code;
  }
  return (uint64_t)value;
}

void paddr_tohost_check_write(paddr_t addr, uint32_t len) {
  if (!paddr_tohost_range_overlap(addr, len)) return;

  // Read the full XLEN word so byte/word/doubleword writes all converge.
  // tohost 可能刚被 guest store 写入、仍 dirty 停在 write-back dcache 未回 pmem，
  // 必须用 dcache 一致视图读，否则读到 pmem stale 0 → 漏判 tohost 退出(rv64dv self-loop 暴露)。
  word_t value = dcache_peek_read(paddr_tohost_addr, sizeof(word_t));
  if (value == 0) return;

  uint64_t code = paddr_tohost_decode_exit(value);
  int halt_ret = code > (uint64_t)INT_MAX ? 1 : (int)code;
  Log("nemu: %s via tohost at pc = " FMT_WORD
      ", addr=" FMT_PADDR ", value=" FMT_WORD ", code=%" PRIu64,
      code == 0 ? ANSI_FMT("TOHOST PASS", ANSI_FG_GREEN) :
      ANSI_FMT("TOHOST FAIL", ANSI_FG_RED),
      cpu.pc, paddr_tohost_addr, value, code);
  set_nemu_state(NEMU_END, cpu.pc, halt_ret);
}

static void paddr_dma_notify_cpu(paddr_t addr, uint32_t len) {
  if (len == 0) return;
  IFDEF(CONFIG_ISA_riscv, isa_riscv_lr_sc_invalidate(addr, (uint64_t)len));
  /*
   * Device DMA is an external PMEM write. Keep the interpreter's private
   * instruction-side host-page cache coherent without flushing unrelated pages.
   */
  vaddr_ifetch_cache_invalidate_paddr(addr, len);
}

// DMA 写必须经 dcache 一致视图落存(dcache_coherent_write: 命中原地改保持 dirty、
// 未命中直写 pmem)。旧实现 memcpy/pmem_write 直写 pmem: 若 dcache 恰有该行,
// guest 读 dcache 返回 stale 旧值(看不到 DMA 数据), dirty 行将来 writeback 还会
// 反向覆盖 DMA 数据。与 #108 tohost 漏判同源(write-back dcache 的 host 侧直访问)。
static void paddr_dma_coherent_copy_in(paddr_t addr, const uint8_t *src, uint32_t len) {
  const uint32_t chunk = sizeof(word_t);
  uint32_t i = 0;
  for (; i + chunk <= len && ((addr + i) & (chunk - 1)) == 0; i += chunk) {
    word_t v;
    memcpy(&v, src + i, chunk);
    dcache_coherent_write(addr + i, chunk, v);
  }
  for (; i < len; i++) dcache_coherent_write(addr + i, 1, src[i]);
}

bool paddr_dma_write(paddr_t addr, const void *buf, uint32_t len) {
  if (len == 0) return true;
  if (!pmem_range_ok(addr, len)) return false;
  paddr_dma_coherent_copy_in(addr, buf, len);
  paddr_dma_notify_cpu(addr, len);
  paddr_write_trace_after_write(addr, len,
      paddr_write_trace_first_word(buf, len), buf, "dma-buffer");
  paddr_tohost_check_write(addr, len);
  nemu_profile_count_if(NEMU_PROFILE_PADDR_DMA_WRITES, 1);
  nemu_profile_count_if(NEMU_PROFILE_PADDR_DMA_WRITE_BYTES, len);
  return true;
}

bool paddr_dma_write_value(paddr_t addr, int len, word_t data) {
  assert(len >= 1 && len <= (int)sizeof(word_t));
  if (!pmem_range_ok(addr, (uint32_t)len)) return false;
  dcache_coherent_write(addr, len, data);
  paddr_dma_notify_cpu(addr, (uint32_t)len);
  paddr_write_trace_after_write(addr, (uint32_t)len, data, &data, "dma-value");
  paddr_tohost_check_write(addr, (uint32_t)len);
  nemu_profile_count_if(NEMU_PROFILE_PADDR_DMA_WRITES, 1);
  nemu_profile_count_if(NEMU_PROFILE_PADDR_DMA_WRITE_BYTES, (uint64_t)len);
  return true;
}

// DMA 读的对称一致入口: 设备读 guest 内存(virtio ring/描述符/数据段)必须看到
// guest 经 dcache 写入(可能 dirty 未回 pmem)的最新值。旧路径 paddr_read/裸 memcpy
// 读 pmem 会拿到 stale——guest 刚 kick 的描述符 dirty 在 dcache 时 virtio 必错。
// Virtio 描述符包含 64-bit 字段；RV32 下用两个 XLEN 宽度的 coherent read
// 组合结果，不能让 8-byte DMA 读取经过 32-bit word_t 后静默截断。
uint64_t paddr_dma_read_value(paddr_t addr, int len) {
  assert(len >= 1 && len <= 8);
  if (!pmem_range_ok(addr, (uint32_t)len)) return 0;
  uint64_t value = 0;
  for (int offset = 0; offset < len; offset += (int)sizeof(word_t)) {
    int chunk = len - offset;
    if (chunk > (int)sizeof(word_t)) chunk = sizeof(word_t);
    word_t part = dcache_peek_read(addr + (paddr_t)offset, chunk);
    value |= (uint64_t)part << (offset * 8);
  }
  return value;
}

bool paddr_dma_read(paddr_t addr, void *buf, uint32_t len) {
  if (len == 0) return true;
  if (!pmem_range_ok(addr, len)) return false;
  uint8_t *out = buf;
  const uint32_t chunk = sizeof(word_t);
  uint32_t i = 0;
  for (; i + chunk <= len && ((addr + i) & (chunk - 1)) == 0; i += chunk) {
    word_t v = dcache_peek_read(addr + i, chunk);
    memcpy(out + i, &v, chunk);
  }
  for (; i < len; i++) out[i] = (uint8_t)dcache_peek_read(addr + i, 1);
  return true;
}


//当访问越界且没有MMIO时触发panic，并打印访问地址和cpu.pc以便调试
static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

/*
 * A physical-address range has exactly one owner in a machine profile.
 * PMEM is configurable on the generic machine, whereas CLINT/PLIC apertures
 * are architectural platform constants and bypass the IOMap registry.  Reject
 * an ambiguous map before allocating memory or starting a CPU: decoder order
 * is an implementation detail and must never decide the guest-visible device.
 */
static void validate_platform_memory_map(void) {
  const uint64_t pmem_base = (uint64_t)CONFIG_MBASE;
  const uint64_t pmem_size = (uint64_t)CONFIG_MSIZE;

  Assert(pmem_size != 0 && pmem_size - 1 <= UINT64_MAX - pmem_base,
      "%s PMEM range is empty or wraps around: base=0x%016" PRIx64
      " size=0x%016" PRIx64,
      NEMU_PLATFORM_NAME, pmem_base, pmem_size);

  const uint64_t pmem_end = pmem_base + pmem_size - 1;
  Assert(pmem_end <= (uint64_t)(paddr_t)-1,
      "%s PMEM end 0x%016" PRIx64
      " cannot be represented by the configured physical-address type",
      NEMU_PLATFORM_NAME, pmem_end);
#if NEMU_PLATFORM_HAS_RISCV_CLINT
  const uint64_t clint_end = RISCV_CLINT_BASE + RISCV_CLINT_SIZE - 1;
  Assert(pmem_end < RISCV_CLINT_BASE || pmem_base > clint_end,
      "%s PMEM [0x%016" PRIx64 ", 0x%016" PRIx64
      "] overlaps the RISC-V CLINT aperture [0x%016" PRIx64
      ", 0x%016" PRIx64 "]",
      NEMU_PLATFORM_NAME, pmem_base, pmem_end,
      (uint64_t)RISCV_CLINT_BASE, clint_end);
#endif
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  const uint64_t plic_end = RISCV_PLIC_BASE + RISCV_PLIC_SIZE - 1;
  Assert(pmem_end < RISCV_PLIC_BASE || pmem_base > plic_end,
      "%s PMEM [0x%016" PRIx64 ", 0x%016" PRIx64
      "] overlaps the RISC-V PLIC aperture [0x%016" PRIx64
      ", 0x%016" PRIx64 "]",
      NEMU_PLATFORM_NAME, pmem_base, pmem_end,
      (uint64_t)RISCV_PLIC_BASE, plic_end);
#endif
}

//分配/初始化pmem（支持CONFIG_PMEM_MALLOC或静态数组），可按照CONFIG_MEM_RANDOM填充随机值并打印物理内存区间日志
void init_mem() {
  validate_platform_memory_map();
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
  // SoC 仿真窗口是 paddr 层直连模型，初始化时清空其平台状态，避免 reference so 多轮复用串味。
#ifdef CONFIG_SOC_SIM
  soc_sim_reset();
  const SocSimRegionInfo *pmem_region = soc_sim_pmem_backed_region();
  Assert(pmem_region != NULL &&
         pmem_region->base == PMEM_LEFT &&
         pmem_region->size == (size_t)CONFIG_MSIZE,
      "NEMU PMEM [" FMT_PADDR ", " FMT_PADDR "] must exactly back "
      "the ysyxSoC PSRAM region",
      PMEM_LEFT, PMEM_RIGHT);
#endif
  // cache 以 paddr 层作为后端，初始化只建立 tag/data 状态，不改变 PMEM/MMIO 的权威语义。
  IFDEF(CONFIG_CACHE, init_cache());
}

// 判断物理地址 span 是否落在任何已实现 region 内；不解码读写方向/寄存宽度。
// CPU 访存必须走下方 paddr_transaction_valid，未命中则抬 guest access-fault,
// 取代原先 paddr/mmio 层遇到 guest 可控越界地址就 host assert/panic 崩掉整个进程的行为
// (这是 rv64dv 等随机程序压测把 NEMU 当 reference 时的可靠性前提: 一条非法访存不该干掉进程内 ref.so)。
// 热路径 (pmem 命中) 只做一次 in_pmem 判断即返回, 不遍历设备表, 因此对正常访存零额外开销。
bool paddr_is_accessible(paddr_t addr, int len) {
  if (len <= 0) return false;
  paddr_t last = addr + (paddr_t)len - 1;
  if (last < addr) return false;  // 长度回绕/溢出视为不可访问
  if (likely(paddr_span_in_pmem(addr, (uint64_t)len))) return true;
#ifdef CONFIG_SOC_SIM
  /* SOC_SIM 的 manifest 是所选机器的固定总线合同，不与 generic 控制器竞争优先级。 */
  if (soc_sim_span_in_range(addr, len)) return true;
#endif
#if NEMU_PLATFORM_HAS_RISCV_CLINT
  if (isa_riscv_clint_in_range(addr)) {
    /* CLINT 只接受已实现寄存器上的自然对齐 32/64-bit 事务。 */
    return isa_riscv_clint_access_valid(addr, len);
  }
#endif
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  if (isa_riscv_plic_in_range(addr)) {
    // PLIC 只接受自然对齐的 32-bit 寄存器事务；false 交给 vaddr 层抬 access-fault。
    return isa_riscv_plic_access_valid(addr, len);
  }
#endif
  if (MUXDEF(CONFIG_DEVICE, mmio_is_mapped(addr, len), false)) return true;
  return false;
}

bool paddr_transaction_valid(
    paddr_t addr, int len, PaddrTransactionDirection direction) {
  if (len <= 0) return false;
  if (direction != PADDR_TRANSACTION_IFETCH &&
      direction != PADDR_TRANSACTION_READ &&
      direction != PADDR_TRANSACTION_WRITE) {
    return false;
  }
  if (likely(paddr_span_in_pmem(addr, (uint64_t)len))) return true;
#ifdef CONFIG_SOC_SIM
  if (soc_sim_span_in_range(addr, len)) {
    SocSimTransactionDirection soc_direction;
    switch (direction) {
      case PADDR_TRANSACTION_IFETCH:
        soc_direction = SOC_SIM_TRANSACTION_IFETCH;
        break;
      case PADDR_TRANSACTION_READ:
        soc_direction = SOC_SIM_TRANSACTION_READ;
        break;
      case PADDR_TRANSACTION_WRITE:
        soc_direction = SOC_SIM_TRANSACTION_WRITE;
        break;
      default:
        return false;
    }
    return soc_sim_transaction_valid(addr, len, soc_direction);
  }
#endif
#if NEMU_PLATFORM_HAS_RISCV_CLINT
  if (isa_riscv_clint_in_range(addr)) {
    return direction != PADDR_TRANSACTION_IFETCH &&
        isa_riscv_clint_access_valid(addr, len);
  }
#endif
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  if (isa_riscv_plic_in_range(addr)) {
    return direction != PADDR_TRANSACTION_IFETCH &&
        isa_riscv_plic_access_valid(addr, len);
  }
#endif
  if (direction == PADDR_TRANSACTION_IFETCH) return false;
  return MUXDEF(CONFIG_DEVICE,
      mmio_decode_transaction(addr, len,
          direction == PADDR_TRANSACTION_WRITE) == IO_TRANSACTION_ACCEPTED,
      false);
}

RiscvAtomicPma paddr_atomic_pma(paddr_t addr, int len) {
  if (len != RISCV_ATOMIC_WIDTH_WORD &&
      len != RISCV_ATOMIC_WIDTH_DOUBLEWORD) {
    return riscv_atomic_pma_none();
  }
  paddr_t last = addr + (paddr_t)len - 1;
  if (last < addr) return riscv_atomic_pma_none();
  /*
   * 固定平台 PMA：完整 PMEM 是 AMOArithmetic + RsrvEventual，且没有
   * misaligned atomicity granule；所选平台的控制器/SoC MMIO 均保持
   * AMONone + RsrvNone，不能用一次设备 read 加一次 write 冒充原子事务。
   */
  if (paddr_span_in_pmem(addr, (uint64_t)len)) {
    return riscv_atomic_pma_arithmetic_reservation_eventual();
  }
  return riscv_atomic_pma_none();
}

//对外的物理地址读写入口，若地址在pmem范围则走pmem_read/pmem_write，否则在启用CONFIG_DEVICE时调用mmio_read/mmio_write
//否则触发out_of_bound(panic)
word_t paddr_read(paddr_t addr, int len) {
  if (likely(len > 0 && paddr_span_in_pmem(addr, (uint64_t)len))) {
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PMEM_READS, 1);
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PMEM_READ_BYTES, (uint64_t)len);
    word_t ret = pmem_read(addr, len);
#ifdef CONFIG_MTRACE
    extern bool g_in_ifetch;
    if (!g_in_ifetch && cpu.pc >= CONFIG_MTRACE_START && cpu.pc <= CONFIG_MTRACE_END)
      log_write("[Mtrace] R addr=" FMT_PADDR " len=%d val " FMT_WORD " pc = " FMT_WORD "\n",
      addr, len, ret, cpu.pc);
#endif
  return ret;
  }
#ifdef CONFIG_SOC_SIM
  if (soc_sim_span_in_range(addr, len)) {
    // ysyxSoC 平台窗口不依赖 CONFIG_DEVICE；MROM/SRAM/SDRAM 是可比较内存，
    // 只有 UART/占位设备这类 MMIO 副作用需要跳过 reference 步进。
    if (soc_sim_should_skip_ref(addr)) difftest_skip_ref();
    return soc_sim_read(addr, len);
  }
#endif
#if NEMU_PLATFORM_HAS_RISCV_CLINT
  if (isa_riscv_clint_in_range(addr)) {
    // generic RISC-V CLINT 在 paddr 层直连，reference so 不需要完整 device init。
    if (!isa_riscv_clint_access_valid(addr, len)) return 0;
    difftest_skip_ref();
    nemu_profile_count_if(NEMU_PROFILE_PADDR_CLINT_READS, 1);
    return isa_riscv_clint_read(addr, len);
  }
#endif
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  if (isa_riscv_plic_in_range(addr)) {
    difftest_skip_ref();
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PLIC_READS, 1);
    return isa_riscv_plic_read(addr, len);
  }
#endif
  IFDEF(CONFIG_DEVICE, nemu_profile_count_if(NEMU_PROFILE_PADDR_MMIO_READS, 1); return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (likely(len > 0 && paddr_span_in_pmem(addr, (uint64_t)len))){
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PMEM_WRITES, 1);
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PMEM_WRITE_BYTES, (uint64_t)len);
    pmem_write(addr, len, data);
    paddr_write_trace_after_write(addr, (uint32_t)len, data, &data, "paddr-pmem");
    paddr_tohost_check_write(addr, (uint32_t)len);
#ifdef CONFIG_MTRACE
    extern bool g_in_ifetch;
    if(!g_in_ifetch && cpu.pc >= CONFIG_MTRACE_START && cpu.pc <= CONFIG_MTRACE_END)
      log_write("[Mtrace] W addr=" FMT_PADDR " len=%d val " FMT_WORD " pc = " FMT_WORD "\n",
      addr, len, data, cpu.pc);
#endif
    return;
  }
#ifdef CONFIG_SOC_SIM
  if (soc_sim_span_in_range(addr, len)) {
    // SoC 模型在 paddr 层完成副作用；片上存储保持指令级比较，MMIO 才跳过。
    if (soc_sim_should_skip_ref(addr)) {
      difftest_skip_ref();
      paddr_note_device_write();
    }
    soc_sim_write(addr, len, data);
    return;
  }
#endif
#if NEMU_PLATFORM_HAS_RISCV_CLINT
  if (isa_riscv_clint_in_range(addr)) {
    if (!isa_riscv_clint_access_valid(addr, len)) return;
    difftest_skip_ref();
    nemu_profile_count_if(NEMU_PROFILE_PADDR_CLINT_WRITES, 1);
    paddr_note_device_write();
    isa_riscv_clint_write(addr, len, data);
    return;
  }
#endif
#if NEMU_PLATFORM_HAS_RISCV_PLIC
  if (isa_riscv_plic_in_range(addr)) {
    difftest_skip_ref();
    nemu_profile_count_if(NEMU_PROFILE_PADDR_PLIC_WRITES, 1);
    paddr_note_device_write();
    isa_riscv_plic_write(addr, len, data);
    return;
  }
#endif
  IFDEF(CONFIG_DEVICE, nemu_profile_count_if(NEMU_PROFILE_PADDR_MMIO_WRITES, 1); paddr_note_device_write(); mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
