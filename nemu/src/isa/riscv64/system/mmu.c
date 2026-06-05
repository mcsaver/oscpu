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
#define SATP64_PPN(value)  ((value) & (((word_t)1 << 44) - 1))

#define PTE_V ((word_t)1 << 0)
#define PTE_R ((word_t)1 << 1)
#define PTE_W ((word_t)1 << 2)
#define PTE_X ((word_t)1 << 3)
#define PTE_U ((word_t)1 << 4)
#define PTE_A ((word_t)1 << 6)
#define PTE_D ((word_t)1 << 7)

#define SV39_TLB_SIZE 4096

typedef struct {
  bool valid;
  word_t satp;
  uint64_t vpn;
  uint64_t ppn;
  uint8_t type;
  uint8_t priv;
  bool mxr;
  bool sum;
} Sv39TlbEntry;

static Sv39TlbEntry sv39_tlb[SV39_TLB_SIZE];

#ifdef CONFIG_RISCV_DEBUG_LOG
static int sv39_fail_log_budget = CONFIG_RISCV_FAULT_DEBUG_BUDGET;
#endif

void isa_riscv32_mmu_tlb_flush(void) {
  memset(sv39_tlb, 0, sizeof(sv39_tlb));
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

static inline uint32_t sv39_tlb_index(word_t satp, uint64_t vpn,
    int type, uint8_t priv, bool mxr, bool sum) {
  uint64_t x = vpn ^ (vpn >> 9) ^ ((uint64_t)satp << 7) ^ ((uint64_t)satp >> 13);
  x ^= (uint64_t)type * 0x9e3779b97f4a7c15ull;
  x ^= (uint64_t)priv << 3;
  x ^= (uint64_t)mxr << 5;
  x ^= (uint64_t)sum << 6;
  return x & (SV39_TLB_SIZE - 1);
}

static inline bool sv39_tlb_lookup(vaddr_t vaddr, int type, uint8_t priv,
    paddr_t *paddr) {
  uint64_t vpn = (uint64_t)vaddr >> PAGE_SHIFT;
  bool mxr = (cpu.csr.mstatus & MSTATUS_MXR) != 0;
  bool sum = (cpu.csr.mstatus & MSTATUS_SUM) != 0;
  uint32_t index = sv39_tlb_index(cpu.csr.satp, vpn, type, priv, mxr, sum);
  Sv39TlbEntry *entry = &sv39_tlb[index];

  if (entry->valid && entry->satp == cpu.csr.satp && entry->vpn == vpn &&
      entry->type == type && entry->priv == priv &&
      entry->mxr == mxr && entry->sum == sum) {
    *paddr = (paddr_t)((entry->ppn << PAGE_SHIFT) | ((uint64_t)vaddr & PAGE_MASK));
    return true;
  }
  return false;
}

static inline void sv39_tlb_fill(vaddr_t vaddr, paddr_t paddr,
    int type, uint8_t priv) {
  uint64_t vpn = (uint64_t)vaddr >> PAGE_SHIFT;
  bool mxr = (cpu.csr.mstatus & MSTATUS_MXR) != 0;
  bool sum = (cpu.csr.mstatus & MSTATUS_SUM) != 0;
  uint32_t index = sv39_tlb_index(cpu.csr.satp, vpn, type, priv, mxr, sum);
  sv39_tlb[index] = (Sv39TlbEntry) {
    .valid = true,
    .satp = cpu.csr.satp,
    .vpn = vpn,
    .ppn = (uint64_t)paddr >> PAGE_SHIFT,
    .type = type,
    .priv = priv,
    .mxr = mxr,
    .sum = sum,
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

paddr_t isa_mmu_translate(vaddr_t vaddr, int len, int type) {
#ifndef CONFIG_ISA64
  return vaddr;
#else
  (void)len;
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
  paddr_t cached_paddr = 0;
  if (sv39_tlb_lookup(vaddr, type, priv, &cached_paddr)) return cached_paddr;

  for (int level = 2; level >= 0; level--) {
    paddr_t pte_addr = (paddr_t)(table + vpn[level] * 8);
    word_t pte = paddr_read(pte_addr, 8);
    if (pte_invalid(pte)) return sv39_fail(vaddr, type, level, pte_addr, pte, "invalid-pte");

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
      sv39_tlb_fill(vaddr, (paddr_t)pa, type, priv);
      return (paddr_t)pa;
    }

    table = pte_ppn << 12;
  }

  return sv39_fail(vaddr, type, -1, 0, 0, "walk-exhausted");
#endif
}
