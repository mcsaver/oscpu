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

void isa_riscv64_mmu_tlb_flush(void) {
  memset(sv39_itlb, 0, sizeof(sv39_itlb));
  memset(sv39_dtlb, 0, sizeof(sv39_dtlb));
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
}

static paddr_t sv39_fail(vaddr_t vaddr, int type, int level,
    paddr_t pte_addr, word_t pte, const char *reason) {
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
  paddr_t page_base = paddr & ~(paddr_t)PAGE_MASK;
  if (page_base >= PMEM_LEFT && page_base <= PMEM_RIGHT - PAGE_MASK) {
    return guest_to_host(page_base);
  }
  return NULL;
}

static inline bool sv39_tlb_lookup(vaddr_t vaddr, int type, uint8_t priv,
    paddr_t *paddr, uint8_t **host_addr) {
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
    return true;
  }
  return false;
}

static inline void sv39_tlb_fill(vaddr_t vaddr, paddr_t paddr,
    int type, uint8_t priv, bool global) {
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
  if (!sv39_va_canonical(vaddr)) return sv39_fail(vaddr, type, -1, 0, 0, "non-canonical");

  uint64_t va = vaddr;
  uint64_t vpn[3] = {
    (va >> 12) & 0x1ff,
    (va >> 21) & 0x1ff,
    (va >> 30) & 0x1ff,
  };
  uint64_t page_offset = va & 0xfff;
  uint64_t table = SATP64_PPN(cpu.csr.satp) << 12;
  uint8_t priv = mmu_effective_priv(type);
  bool global_mapping = false;
  paddr_t cached_paddr = 0;
  if (sv39_tlb_lookup(vaddr, type, priv, &cached_paddr, host_addr)) return cached_paddr;

  for (int level = 2; level >= 0; level--) {
    paddr_t pte_addr = (paddr_t)(table + vpn[level] * 8);
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
        paddr_write(pte_addr, 8, pte | needed);
      }

      uint64_t pa;
      if (level == 2) {
        pa = (ppn2 << 30) | (vpn[1] << 21) | (vpn[0] << 12) | page_offset;
      } else if (level == 1) {
        pa = (ppn2 << 30) | (ppn1 << 21) | (vpn[0] << 12) | page_offset;
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
