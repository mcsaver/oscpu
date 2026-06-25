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

#include <isa.h>
#include <memory/vaddr.h>
#include <memory/paddr.h>
#include <utils/profile.h>

#include <stdlib.h>
#include <string.h>

#define SATP64_MODE(value) ((value) >> 60)
#define SATP64_ASID(value) ((uint16_t)(((value) >> 44) & 0xffffu))
#define SATP64_PPN(value)  ((value) & (((word_t)1 << 44) - 1))

#define PTE_V ((word_t)1 << 0)
#define PTE_R ((word_t)1 << 1)
#define PTE_W ((word_t)1 << 2)
#define PTE_X ((word_t)1 << 3)
#define PTE_U ((word_t)1 << 4)
#define PTE_G ((word_t)1 << 5)
#define PTE_A ((word_t)1 << 6)
#define PTE_D ((word_t)1 << 7)

#define SV39_TLB_SIZE 4096

typedef struct {
  bool valid;
  uint64_t vpn;
  uint64_t root_ppn;
  uint64_t ppn;
  uint16_t asid;
  uint8_t type;
  uint8_t priv;
  bool global;
  bool mxr;
  bool sum;
  uint8_t *host_page;
} Sv39TlbEntry;

static Sv39TlbEntry sv39_itlb[SV39_TLB_SIZE];
static Sv39TlbEntry sv39_dtlb[SV39_TLB_SIZE];

#ifdef CONFIG_RISCV_DEBUG_LOG
static int sv39_fail_log_budget = CONFIG_RISCV_FAULT_DEBUG_BUDGET;
#endif
static word_t sv39_translate_fault_cause;
static bool sv39_tlb_is_enabled = true;

static bool runtime_env_enabled_default_true(const char *name) {
#ifndef CONFIG_TARGET_AM
  const char *env = getenv(name);
  return !(env != NULL && env[0] != '\0' && strcmp(env, "0") == 0);
#else
  (void)name;
  return true;
#endif
}

__attribute__((constructor))
static void sv39_runtime_config_init(void) {
  sv39_tlb_is_enabled = runtime_env_enabled_default_true("NEMU_RISCV_MMU_TLB");
}

static inline bool sv39_tlb_runtime_enabled(void) {
  return likely(sv39_tlb_is_enabled);
}

void isa_riscv64_mmu_tlb_flush(void) {
  memset(sv39_itlb, 0, sizeof(sv39_itlb));
  memset(sv39_dtlb, 0, sizeof(sv39_dtlb));
  nemu_profile_count_if(NEMU_PROFILE_MMU_TLB_FLUSH_FULL, 1);
  vaddr_ifetch_cache_flush();
}

static inline void sv39_tlb_flush_set(Sv39TlbEntry *tlb,
    bool flush_vaddr, uint64_t vpn, bool flush_asid, uint16_t asid) {
  for (size_t i = 0; i < SV39_TLB_SIZE; i++) {
    Sv39TlbEntry *entry = &tlb[i];
    if (!entry->valid) continue;
    if (flush_vaddr && entry->vpn != vpn) continue;
    /*
     * sfence.vma rs1, rs2 在 rs2 非 x0 时只约束该 ASID 的非 global
     * 映射；PTE_G 路径必须留给 rs2=x0，避免进程局部 fence 误伤全局页。
     */
    if (flush_asid && (entry->global || entry->asid != asid)) continue;
    entry->valid = false;
  }
}

void isa_riscv64_mmu_tlb_flush_selective(vaddr_t vaddr, bool flush_vaddr,
    word_t asid, bool flush_asid) {
  if (!flush_vaddr && !flush_asid) {
    isa_riscv64_mmu_tlb_flush();
    return;
  }

  uint64_t vpn = (uint64_t)vaddr >> PAGE_SHIFT;
  uint16_t asid16 = (uint16_t)(asid & 0xffffu);
  sv39_tlb_flush_set(sv39_itlb, flush_vaddr, vpn, flush_asid, asid16);
  sv39_tlb_flush_set(sv39_dtlb, flush_vaddr, vpn, flush_asid, asid16);
  nemu_profile_count_if(NEMU_PROFILE_MMU_TLB_FLUSH_SELECTIVE, 1);
  vaddr_ifetch_cache_flush();
}

static inline word_t mmu_page_fault_cause_for_type(int type) {
  switch (type) {
    case MEM_TYPE_IFETCH: return CAUSE_INST_PAGE_FAULT;
    case MEM_TYPE_WRITE:  return CAUSE_STORE_PAGE_FAULT;
    case MEM_TYPE_READ:
    default: return CAUSE_LOAD_PAGE_FAULT;
  }
}

static inline word_t mmu_access_fault_cause_for_type(int type) {
  switch (type) {
    case MEM_TYPE_IFETCH: return CAUSE_INST_ACCESS;
    case MEM_TYPE_WRITE:  return CAUSE_STORE_ACCESS;
    case MEM_TYPE_READ:
    default: return CAUSE_LOAD_ACCESS;
  }
}

word_t isa_riscv64_mmu_fault_cause(int type) {
  return sv39_translate_fault_cause != 0 ?
    sv39_translate_fault_cause : mmu_page_fault_cause_for_type(type);
}

static paddr_t sv39_fail_with_cause(vaddr_t vaddr, int type, int level,
    paddr_t pte_addr, word_t pte, const char *reason, word_t cause) {
  sv39_translate_fault_cause = cause;
  nemu_profile_count_if(NEMU_PROFILE_MMU_FAULTS, 1);
#ifdef CONFIG_RISCV_DEBUG_LOG
  if (sv39_fail_log_budget > 0) {
    sv39_fail_log_budget--;
    Log("Sv39 translate failed: reason=%s vaddr=" FMT_WORD
        " type=%d level=%d pte_addr=" FMT_PADDR " pte=" FMT_WORD
        " satp=" FMT_WORD " priv=%u mstatus=" FMT_WORD,
        reason, vaddr, type, level, pte_addr, pte, cpu.csr.satp,
        cpu.priv, cpu.csr.mstatus);
  }
#else
  (void)vaddr;
  (void)type;
  (void)level;
  (void)pte_addr;
  (void)pte;
  (void)reason;
#endif
  return (paddr_t)-1;
}

static paddr_t sv39_fail(vaddr_t vaddr, int type, int level,
    paddr_t pte_addr, word_t pte, const char *reason) {
  return sv39_fail_with_cause(vaddr, type, level, pte_addr, pte,
      reason, mmu_page_fault_cause_for_type(type));
}

static inline uint8_t mmu_effective_priv(int type) {
  if (type != MEM_TYPE_IFETCH && cpu.priv == PRIV_M && (cpu.csr.mstatus & MSTATUS_MPRV)) {
    switch (cpu.csr.mstatus & MSTATUS_MPP_MASK) {
      case MSTATUS_MPP_S: return PRIV_S;
      case MSTATUS_MPP_M: return PRIV_M;
      default: return PRIV_U;
    }
  }
  return cpu.priv;
}

typedef struct {
  uint64_t start;
  uint64_t end;
} PmpRange;

typedef struct {
  PmpRange range;
  uint8_t cfg;
  bool active;
} PmpCachedEntry;

static PmpCachedEntry pmp_cached_entries[RISCV64_PMP_ENTRY_COUNT];
static bool pmp_cache_valid = false;
static bool pmp_cache_any_active = false;

static inline uint8_t pmp_cfg_a(uint8_t cfg) {
  return cfg & PMP_CFG_A_MASK;
}

static inline bool pmp_entry_active(uint32_t index) {
  return pmp_cfg_a(cpu.csr.pmpcfg[index]) != PMP_CFG_A_OFF;
}

static inline bool pmp_any_active(void) {
  return cpu.csr.pmp_active;
}

void isa_riscv64_pmp_mark_dirty(void) {
  pmp_cache_valid = false;
}

static inline uint64_t pmp_saturating_end(uint64_t start, uint64_t size) {
  uint64_t max = ~(uint64_t)0;
  if (size == 0) return start;
  return start > max - size ? max : start + size;
}

static bool pmp_decode_napot(uint64_t raw, PmpRange *range) {
  uint32_t ones = 0;
  raw &= (uint64_t)PMPADDR_MASK;
  while (ones < 54 && ((raw >> ones) & 1u)) {
    ones++;
  }

  if (ones + 3 >= 63) {
    range->start = 0;
    range->end = ~(uint64_t)0;
    return true;
  }

  uint64_t low_mask = ones == 0 ? 0 : ((1ull << ones) - 1);
  uint64_t start = (raw & ~low_mask) << 2;
  uint64_t size = 1ull << (ones + 3);
  range->start = start;
  range->end = pmp_saturating_end(start, size);
  return range->start < range->end;
}

static bool pmp_decode_range(uint32_t index, PmpRange *range) {
  uint8_t cfg = cpu.csr.pmpcfg[index];
  uint64_t addr = (uint64_t)(cpu.csr.pmpaddr[index] & PMPADDR_MASK);

  switch (pmp_cfg_a(cfg)) {
    case PMP_CFG_A_OFF:
      return false;
    case PMP_CFG_A_TOR: {
      uint64_t start = index == 0 ? 0 :
        (uint64_t)(cpu.csr.pmpaddr[index - 1] & PMPADDR_MASK) << 2;
      uint64_t end = addr << 2;
      range->start = start;
      range->end = end;
      return range->start < range->end;
    }
    case PMP_CFG_A_NA4:
      range->start = addr << 2;
      range->end = pmp_saturating_end(range->start, 4);
      return range->start < range->end;
    case PMP_CFG_A_NAPOT:
      return pmp_decode_napot(addr, range);
    default:
      return false;
  }
}

static inline bool pmp_range_overlaps(PmpRange range, uint64_t start, uint64_t end) {
  return start < range.end && end > range.start;
}

static inline bool pmp_range_contains(PmpRange range, uint64_t start, uint64_t end) {
  return start >= range.start && end <= range.end;
}

static inline bool pmp_permission_ok(uint8_t cfg, int type, uint8_t priv) {
  if (priv == PRIV_M && (cfg & PMP_CFG_L) == 0) {
    return true;
  }

  switch (type) {
    case MEM_TYPE_IFETCH: return (cfg & PMP_CFG_X) != 0;
    case MEM_TYPE_WRITE:  return (cfg & PMP_CFG_W) != 0;
    case MEM_TYPE_READ:
    default: return (cfg & PMP_CFG_R) != 0;
  }
}

static void pmp_cache_refresh(void) {
  pmp_cache_any_active = pmp_any_active();
  for (uint32_t i = 0; i < RISCV64_PMP_ENTRY_COUNT; i++) {
    pmp_cached_entries[i].cfg = cpu.csr.pmpcfg[i];
    pmp_cached_entries[i].active =
      pmp_cache_any_active && pmp_decode_range(i, &pmp_cached_entries[i].range);
  }
  pmp_cache_valid = true;
}

static bool pmp_check_with_priv(paddr_t paddr, int len, int type, uint8_t priv) {
  if (len <= 0) return false;
  if (!pmp_any_active()) return true;
  if (unlikely(!pmp_cache_valid)) {
    pmp_cache_refresh();
  }
  if (!pmp_cache_any_active) return true;

  uint64_t start = (uint64_t)paddr;
  uint64_t end = pmp_saturating_end(start, (uint64_t)len);
  if (end <= start) return false;

  for (uint32_t i = 0; i < RISCV64_PMP_ENTRY_COUNT; i++) {
    if (!pmp_cached_entries[i].active) continue;
    PmpRange range = pmp_cached_entries[i].range;
    if (!pmp_range_overlaps(range, start, end)) continue;
    if (!pmp_range_contains(range, start, end)) return false;
    return pmp_permission_ok(pmp_cached_entries[i].cfg, type, priv);
  }

  return priv == PRIV_M;
}

bool isa_riscv64_pmp_check_as_priv(paddr_t paddr, int len, int type, uint8_t priv) {
  return pmp_check_with_priv(paddr, len, type, priv);
}

bool isa_riscv64_pmp_check(paddr_t paddr, int len, int type) {
  return pmp_check_with_priv(paddr, len, type, mmu_effective_priv(type));
}

#ifndef CONFIG_TARGET_AM
void isa_riscv64_pmp_dump_machine_info(FILE *out) {
  fprintf(out, "memory.pmp.mode=rv64-basic\n");
  fprintf(out, "memory.pmp.entries=%u\n", RISCV64_PMP_ENTRY_COUNT);
  fprintf(out, "memory.pmp.active=%d\n", pmp_any_active() ? 1 : 0);
  fprintf(out, "memory.sv39_tlb.enabled=%d\n", sv39_tlb_runtime_enabled() ? 1 : 0);
  fprintf(out, "memory.sv39_tlb.entries=%u\n", SV39_TLB_SIZE);
  fprintf(out, "memory.sv39_tlb.disable_env=NEMU_RISCV_MMU_TLB=0\n");
}
#endif

int isa_mmu_check(vaddr_t vaddr, int len, int type) {
  (void)vaddr;
  (void)len;
#ifdef CONFIG_ISA64
  uint8_t priv = mmu_effective_priv(type);
  if (priv == PRIV_M) return MMU_DIRECT;
  word_t mode = SATP64_MODE(cpu.csr.satp);
  if (mode == 0) return MMU_DIRECT;
  return mode == 8 ? MMU_TRANSLATE : MMU_FAIL;
#else
  return MMU_DIRECT;
#endif
}

static inline bool sv39_va_canonical(vaddr_t vaddr) {
  uint64_t va = vaddr;
  uint64_t top = va >> 39;
  return top == 0 || top == ((1ull << 25) - 1);
}

static inline uint32_t sv39_tlb_index(uint64_t root_ppn, uint16_t asid,
    uint64_t vpn, int type, uint8_t priv, bool mxr, bool sum) {
  uint64_t x = vpn ^ (vpn >> 9) ^ (root_ppn << 7) ^ (root_ppn >> 13);
  x ^= (uint64_t)asid * 0x9e3779b97f4a7c15ull;
  x ^= (uint64_t)type * 0x9e3779b97f4a7c15ull;
  x ^= (uint64_t)priv << 3;
  x ^= (uint64_t)mxr << 5;
  x ^= (uint64_t)sum << 6;
  return x & (SV39_TLB_SIZE - 1);
}

static inline Sv39TlbEntry *sv39_tlb_set_for_type(int type) {
  /*
   * Linux 启动阶段 instruction fetch 与 data load/store 都会高频命中 TLB。
   * 分离 iTLB/dTLB 可避免取指页和数据页在同一个 direct-mapped 表里互相驱逐；
   * dTLB 内仍保留 READ/WRITE type key，维持权限检查后的缓存边界。
   */
  return type == MEM_TYPE_IFETCH ? sv39_itlb : sv39_dtlb;
}

static inline uint8_t *sv39_host_page_base(paddr_t paddr) {
  if (!vaddr_host_fast_runtime_enabled()) {
    return NULL;
  }
  paddr_t page_base = paddr & ~(paddr_t)PAGE_MASK;
  if (page_base >= PMEM_LEFT && page_base <= PMEM_RIGHT - PAGE_MASK) {
    return guest_to_host(page_base);
  }
  return NULL;
}

static inline bool sv39_tlb_lookup(vaddr_t vaddr, int type, uint8_t priv,
    paddr_t *paddr, uint8_t **host_addr) {
  if (!sv39_tlb_runtime_enabled()) {
    nemu_profile_count_if(NEMU_PROFILE_MMU_TLB_DISABLED, 1);
    return false;
  }
  nemu_profile_count_if(NEMU_PROFILE_MMU_TLB_LOOKUPS, 1);

  uint64_t vpn = (uint64_t)vaddr >> PAGE_SHIFT;
  uint64_t root_ppn = SATP64_PPN(cpu.csr.satp);
  uint16_t asid = SATP64_ASID(cpu.csr.satp);
  bool mxr = (cpu.csr.mstatus & MSTATUS_MXR) != 0;
  bool sum = (cpu.csr.mstatus & MSTATUS_SUM) != 0;
  Sv39TlbEntry *tlb = sv39_tlb_set_for_type(type);
  uint32_t index = sv39_tlb_index(root_ppn, asid, vpn, type, priv, mxr, sum);
  Sv39TlbEntry *entry = &tlb[index];

  if (entry->valid && !entry->global && entry->root_ppn == root_ppn &&
      entry->asid == asid && entry->vpn == vpn && entry->type == type &&
      entry->priv == priv && entry->mxr == mxr && entry->sum == sum) {
    uint64_t page_offset = (uint64_t)vaddr & PAGE_MASK;
    *paddr = (paddr_t)((entry->ppn << PAGE_SHIFT) | page_offset);
    if (host_addr != NULL) {
      *host_addr = entry->host_page != NULL ? entry->host_page + page_offset : NULL;
    }
    nemu_profile_count_if(NEMU_PROFILE_MMU_TLB_HITS, 1);
    return true;
  }

  /*
   * PTE_G 映射在 sfence.vma rs2!=x0 时不会被逐 ASID 失效。
   * direct-mapped TLB 为了让 global 页跨 ASID 命中，单独查 asid=0 的槽位。
   */
  index = sv39_tlb_index(root_ppn, 0, vpn, type, priv, mxr, sum);
  entry = &tlb[index];
  if (entry->valid && entry->global && entry->root_ppn == root_ppn &&
      entry->vpn == vpn && entry->type == type && entry->priv == priv &&
      entry->mxr == mxr && entry->sum == sum) {
    uint64_t page_offset = (uint64_t)vaddr & PAGE_MASK;
    *paddr = (paddr_t)((entry->ppn << PAGE_SHIFT) | page_offset);
    if (host_addr != NULL) {
      *host_addr = entry->host_page != NULL ? entry->host_page + page_offset : NULL;
    }
    nemu_profile_count_if(NEMU_PROFILE_MMU_TLB_HITS, 1);
    return true;
  }
  nemu_profile_count_if(NEMU_PROFILE_MMU_TLB_MISSES, 1);
  return false;
}

static inline void sv39_tlb_fill(vaddr_t vaddr, paddr_t paddr,
    int type, uint8_t priv, bool global) {
  if (!sv39_tlb_runtime_enabled()) return;

  uint64_t vpn = (uint64_t)vaddr >> PAGE_SHIFT;
  uint64_t root_ppn = SATP64_PPN(cpu.csr.satp);
  uint16_t asid = global ? 0 : SATP64_ASID(cpu.csr.satp);
  bool mxr = (cpu.csr.mstatus & MSTATUS_MXR) != 0;
  bool sum = (cpu.csr.mstatus & MSTATUS_SUM) != 0;
  uint32_t index = sv39_tlb_index(root_ppn, asid, vpn, type, priv, mxr, sum);
  sv39_tlb_set_for_type(type)[index] = (Sv39TlbEntry) {
    .valid = true,
    .vpn = vpn,
    .root_ppn = root_ppn,
    .ppn = (uint64_t)paddr >> PAGE_SHIFT,
    .asid = asid,
    .type = type,
    .priv = priv,
    .global = global,
    .mxr = mxr,
    .sum = sum,
    /*
     * Ubuntu 性能路径常在同一页内反复命中 TLB。TLB 同时缓存 PMEM 的 host
     * page base，让 vaddr 层命中后直接 host_read/write；MMIO 页保持 NULL。
    */
    .host_page = sv39_host_page_base(paddr),
  };
  nemu_profile_count_if(NEMU_PROFILE_MMU_TLB_FILLS, 1);
}

static inline bool pte_invalid(word_t pte) {
  return (pte & PTE_V) == 0 || ((pte & PTE_W) && !(pte & PTE_R));
}

static inline bool pte_leaf(word_t pte) {
  return (pte & (PTE_R | PTE_X)) != 0;
}

static inline bool pte_permission_ok(word_t pte, int type, uint8_t priv) {
  bool readable = (pte & PTE_R) || ((cpu.csr.mstatus & MSTATUS_MXR) && (pte & PTE_X));
  bool writable = (pte & PTE_W) != 0;
  bool executable = (pte & PTE_X) != 0;
  bool user_page = (pte & PTE_U) != 0;

  if (priv == PRIV_U && !user_page) return false;
  if (priv == PRIV_S && user_page) {
    if (type == MEM_TYPE_IFETCH) return false;
    if ((cpu.csr.mstatus & MSTATUS_SUM) == 0) return false;
  }

  switch (type) {
    case MEM_TYPE_IFETCH: return executable;
    case MEM_TYPE_READ:   return readable;
    case MEM_TYPE_WRITE:  return writable;
    default: return false;
  }
}

static paddr_t sv39_translate(vaddr_t vaddr, int len, int type,
    uint8_t **host_addr) {
#ifndef CONFIG_ISA64
  if (host_addr != NULL) *host_addr = NULL;
  return vaddr;
#else
  (void)len;
  if (host_addr != NULL) *host_addr = NULL;
  sv39_translate_fault_cause = mmu_page_fault_cause_for_type(type);
  if (!sv39_va_canonical(vaddr)) return sv39_fail(vaddr, type, -1, 0, 0, "non-canonical");

  uint64_t va = vaddr;
  /*
   * sv39_translate 是 Ubuntu 热路径；避免局部 VPN 数组触发
   * -fstack-protector-strong 给每次翻译插入 stack canary。
   */
  uint64_t vpn0 = (va >> 12) & 0x1ff;
  uint64_t vpn1 = (va >> 21) & 0x1ff;
  uint64_t vpn2 = (va >> 30) & 0x1ff;
  uint64_t page_offset = va & 0xfff;
  uint64_t table = SATP64_PPN(cpu.csr.satp) << 12;
  uint8_t priv = mmu_effective_priv(type);
  bool global_mapping = false;
  paddr_t cached_paddr = 0;
  if (sv39_tlb_lookup(vaddr, type, priv, &cached_paddr, host_addr)) return cached_paddr;

  nemu_profile_count_if(NEMU_PROFILE_MMU_WALKS, 1);
  for (int level = 2; level >= 0; level--) {
    uint64_t vpn_at_level = level == 2 ? vpn2 : (level == 1 ? vpn1 : vpn0);
    paddr_t pte_addr = (paddr_t)(table + vpn_at_level * 8);
    if (!isa_riscv64_pmp_check_as_priv(pte_addr, 8, MEM_TYPE_READ, PRIV_S)) {
      return sv39_fail_with_cause(vaddr, type, level, pte_addr, 0,
          "pmp-page-table-read", mmu_access_fault_cause_for_type(type));
    }
    nemu_profile_count_if(NEMU_PROFILE_MMU_PTE_READS, 1);
    word_t pte = paddr_read(pte_addr, 8);
    if (pte_invalid(pte)) return sv39_fail(vaddr, type, level, pte_addr, pte, "invalid-pte");
    global_mapping = global_mapping || (pte & PTE_G);

    uint64_t pte_ppn = (pte >> 10) & ((1ull << 44) - 1);
    uint64_t ppn0 = pte_ppn & 0x1ff;
    uint64_t ppn1 = (pte_ppn >> 9) & 0x1ff;
    uint64_t ppn2 = (pte_ppn >> 18) & ((1ull << 26) - 1);

    if (pte_leaf(pte)) {
      if ((level == 2 && (ppn0 != 0 || ppn1 != 0)) ||
          (level == 1 && ppn0 != 0)) {
        return sv39_fail(vaddr, type, level, pte_addr, pte, "misaligned-superpage");
      }
      if (!pte_permission_ok(pte, type, priv)) {
        return sv39_fail(vaddr, type, level, pte_addr, pte, "permission");
      }

      word_t needed = PTE_A | (type == MEM_TYPE_WRITE ? PTE_D : 0);
      if ((pte & needed) != needed) {
        if (!isa_riscv64_pmp_check_as_priv(pte_addr, 8, MEM_TYPE_WRITE, PRIV_S)) {
          return sv39_fail_with_cause(vaddr, type, level, pte_addr, pte,
              "pmp-page-table-write", mmu_access_fault_cause_for_type(type));
        }
        nemu_profile_count_if(NEMU_PROFILE_MMU_PTE_UPDATES, 1);
        paddr_write(pte_addr, 8, pte | needed);
      }

      uint64_t pa;
      if (level == 2) {
        pa = (ppn2 << 30) | (vpn1 << 21) | (vpn0 << 12) | page_offset;
      } else if (level == 1) {
        pa = (ppn2 << 30) | (ppn1 << 21) | (vpn0 << 12) | page_offset;
      } else {
        pa = (pte_ppn << 12) | page_offset;
      }
      sv39_tlb_fill(vaddr, (paddr_t)pa, type, priv, global_mapping);
      if (host_addr != NULL) {
        uint8_t *host_page = sv39_host_page_base((paddr_t)pa);
        *host_addr = host_page != NULL ? host_page + page_offset : NULL;
      }
      return (paddr_t)pa;
    }

    table = pte_ppn << 12;
  }

  return sv39_fail(vaddr, type, -1, 0, 0, "walk-exhausted");
#endif
}

paddr_t isa_mmu_translate(vaddr_t vaddr, int len, int type) {
  return sv39_translate(vaddr, len, type, NULL);
}

bool isa_mmu_translate_host(vaddr_t vaddr, int len, int type,
    paddr_t *paddr, uint8_t **host_addr) {
  uint8_t *translated_host = NULL;
  paddr_t translated = sv39_translate(vaddr, len, type, &translated_host);
  if (paddr != NULL) *paddr = translated;
  if (host_addr != NULL) *host_addr = translated_host;
  return translated != (paddr_t)-1;
}

bool isa_riscv64_mmu_debug_translate_user(vaddr_t vaddr, int len, int type,
    paddr_t *paddr) {
#ifndef CONFIG_ISA64
  if (paddr != NULL) *paddr = (paddr_t)vaddr;
  (void)len;
  (void)type;
  return true;
#else
  if (paddr != NULL) *paddr = 0;
  if (len <= 0 || ((vaddr & PAGE_MASK) + len) > PAGE_SIZE) return false;

  word_t mode = SATP64_MODE(cpu.csr.satp);
  if (mode == 0) {
    if (paddr != NULL) *paddr = (paddr_t)vaddr;
    return true;
  }
  if (mode != 8 || !sv39_va_canonical(vaddr)) return false;

  uint64_t va = vaddr;
  uint64_t vpn0 = (va >> 12) & 0x1ff;
  uint64_t vpn1 = (va >> 21) & 0x1ff;
  uint64_t vpn2 = (va >> 30) & 0x1ff;
  uint64_t page_offset = va & 0xfff;
  uint64_t table = SATP64_PPN(cpu.csr.satp) << 12;

  for (int level = 2; level >= 0; level--) {
    uint64_t vpn_at_level = level == 2 ? vpn2 : (level == 1 ? vpn1 : vpn0);
    paddr_t pte_addr = (paddr_t)(table + vpn_at_level * 8);
    if (!isa_riscv64_pmp_check_as_priv(pte_addr, 8, MEM_TYPE_READ, PRIV_S)) {
      return false;
    }
    word_t pte = paddr_read(pte_addr, 8);
    if (pte_invalid(pte)) return false;

    uint64_t pte_ppn = (pte >> 10) & ((1ull << 44) - 1);
    uint64_t ppn0 = pte_ppn & 0x1ff;
    uint64_t ppn1 = (pte_ppn >> 9) & 0x1ff;
    uint64_t ppn2 = (pte_ppn >> 18) & ((1ull << 26) - 1);

    if (pte_leaf(pte)) {
      if ((level == 2 && (ppn0 != 0 || ppn1 != 0)) ||
          (level == 1 && ppn0 != 0)) {
        return false;
      }
      if (!pte_permission_ok(pte, type, PRIV_U)) return false;

      uint64_t pa;
      if (level == 2) {
        pa = (ppn2 << 30) | (vpn1 << 21) | (vpn0 << 12) | page_offset;
      } else if (level == 1) {
        pa = (ppn2 << 30) | (ppn1 << 21) | (vpn0 << 12) | page_offset;
      } else {
        pa = (pte_ppn << 12) | page_offset;
      }
      if (paddr != NULL) *paddr = (paddr_t)pa;
      return true;
    }

    table = pte_ppn << 12;
  }
  return false;
#endif
}
