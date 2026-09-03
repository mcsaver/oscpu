/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
***************************************************************************************/

#include <isa.h>
#include <isa/riscv/paging.h>
#include <isa/riscv/pmp.h>
#include <memory/cache.h>
#include <memory/paddr.h>
#include <memory/vaddr.h>
#include <utils/profile.h>

#define SATP32_MODE(value) (((value) >> 31) & 0x1u)
#define SATP32_ASID(value) (((value) >> 22) & 0x1ffu)
#define SATP32_PPN(value)  ((value) & 0x003fffffu)

enum {
  SV32_LEVELS = 2,
  SV32_VPN_BITS_PER_LEVEL = 10,
  SV32_PTE_BYTES = 4,
  SV32_PPN_BITS = 22,
};

static word_t sv32_translate_fault_cause;

#ifdef CONFIG_RISCV_DEBUG_LOG
static int sv32_fail_log_budget = CONFIG_RISCV_FAULT_DEBUG_BUDGET;
#endif

static paddr_t sv32_fail_with_cause(vaddr_t virtual_address, int access_type,
    int level, uint64_t pte_address, word_t pte, const char *reason,
    word_t cause) {
  sv32_translate_fault_cause = cause;
  nemu_profile_count_if(NEMU_PROFILE_MMU_FAULTS, 1);
#ifdef CONFIG_RISCV_DEBUG_LOG
  if (sv32_fail_log_budget > 0) {
    sv32_fail_log_budget--;
    Log("Sv32 walk failed: reason=%s va=" FMT_WORD
        " access=%d level=%d pte_addr=0x%" PRIx64
        " pte=" FMT_WORD " satp=" FMT_WORD " priv=%u mstatus=" FMT_WORD,
        reason, virtual_address, access_type, level, pte_address, pte,
        cpu.csr.satp, cpu.priv, cpu.csr.mstatus);
  }
#else
  (void)virtual_address;
  (void)access_type;
  (void)level;
  (void)pte_address;
  (void)pte;
  (void)reason;
#endif
  return (paddr_t)-1;
}

static paddr_t sv32_page_fault(vaddr_t virtual_address, int access_type,
    int level, uint64_t pte_address, word_t pte, const char *reason) {
  return sv32_fail_with_cause(virtual_address, access_type, level,
      pte_address, pte, reason, riscv_page_fault_cause(access_type));
}

static paddr_t sv32_access_fault(vaddr_t virtual_address, int access_type,
    int level, uint64_t pte_address, word_t pte, const char *reason) {
  return sv32_fail_with_cause(virtual_address, access_type, level,
      pte_address, pte, reason, riscv_access_fault_cause(access_type));
}

word_t isa_riscv32_mmu_fault_cause(int access_type) {
  return sv32_translate_fault_cause != 0 ?
      sv32_translate_fault_cause : riscv_page_fault_cause(access_type);
}

bool isa_riscv32_pmp_check(paddr_t physical_address, int length,
    int access_type) {
  /* Keep the existing NEMU platform contract: an all-OFF bank is disabled. */
  if (!cpu.csr.pmp_active) return true;
  uint8_t effective_privilege = riscv_effective_memory_privilege(
      cpu.priv, cpu.csr.mstatus, access_type);
  return riscv_pmp_access_allowed(cpu.csr.pmpcfg, cpu.csr.pmpaddr,
      RISCV_PMP_ENTRY_COUNT, (uint64_t)PMPADDR_MASK,
      physical_address, length, access_type, effective_privilege);
}

static inline bool sv32_physical_address_representable(uint64_t address) {
  return (uint64_t)(paddr_t)address == address;
}

static inline bool sv32_page_table_access_allowed(
    uint64_t address, int access_type) {
  if (!sv32_physical_address_representable(address)) return false;
  paddr_t paddr = (paddr_t)address;
  /*
   * An implicit page-table access requires idempotent main memory in NEMU's
   * fixed PMA.  A readable MMIO register is not page-table memory: probing it
   * as a PTE could latch/dequeue device state before the original access
   * faults.
   */
  return paddr_span_in_pmem(paddr, SV32_PTE_BYTES) &&
         isa_riscv32_pmp_check(paddr, SV32_PTE_BYTES, access_type);
}

int isa_mmu_check(vaddr_t virtual_address, int length, int access_type) {
  (void)virtual_address;
  (void)length;
  RiscvPageAccess access =
      riscv_page_access(cpu.priv, cpu.csr.mstatus, access_type);
  if (access.effective_privilege == PRIV_M) return MMU_DIRECT;

  RiscvPagingMode mode = (RiscvPagingMode)SATP32_MODE(cpu.csr.satp);
  return mode == RISCV_PAGING_BARE ? MMU_DIRECT : MMU_TRANSLATE;
}

/*
 * Sv32 translation algorithm, Privileged Architecture section 12.3.2:
 * a starts at satp.PPN, i starts at LEVELS-1, and each iteration either
 * descends through a non-leaf PTE or commits a leaf translation.
 */
static paddr_t sv32_translate(
    vaddr_t virtual_address, int length, int access_type) {
  (void)length;
  sv32_translate_fault_cause = riscv_page_fault_cause(access_type);

  const RiscvPageAccess access =
      riscv_page_access(cpu.priv, cpu.csr.mstatus, access_type);
  const uint64_t virtual_page_number =
      (uint64_t)virtual_address >> PAGE_SHIFT;
  const uint64_t page_offset = virtual_address & PAGE_MASK;
  uint64_t page_table_address = (uint64_t)SATP32_PPN(cpu.csr.satp)
                                << PAGE_SHIFT;

  nemu_profile_count_if(NEMU_PROFILE_MMU_WALKS, 1);
  for (int level = SV32_LEVELS - 1; level >= 0; level--) {
    const uint64_t vpn_at_level =
        (virtual_page_number >> (SV32_VPN_BITS_PER_LEVEL * level)) & 0x3ffu;
    const uint64_t pte_address =
        page_table_address + vpn_at_level * SV32_PTE_BYTES;

    /* The implicit page-table access is an S-mode physical memory access. */
    if (!sv32_page_table_access_allowed(pte_address, MEM_TYPE_READ)) {
      return sv32_access_fault(virtual_address, access_type, level,
          pte_address, 0, "page-table-read");
    }

    nemu_profile_count_if(NEMU_PROFILE_MMU_PTE_READS, 1);
    word_t pte = dcache_peek_read((paddr_t)pte_address, SV32_PTE_BYTES);
    if (riscv_pte_has_invalid_permissions(pte)) {
      return sv32_page_fault(virtual_address, access_type, level,
          pte_address, pte, "invalid-pte");
    }

    const uint64_t pte_ppn = ((uint64_t)pte >> 10) &
                             ((1ull << SV32_PPN_BITS) - 1);
    if (riscv_pte_is_leaf(pte)) {
      /* A level-1 leaf is a 4 MiB megapage and PPN[0] must be zero. */
      const uint64_t replaced_ppn_mask =
          level == 0 ? 0 : ((1ull << SV32_VPN_BITS_PER_LEVEL) - 1);
      if ((pte_ppn & replaced_ppn_mask) != 0) {
        return sv32_page_fault(virtual_address, access_type, level,
            pte_address, pte, "misaligned-superpage");
      }
      if (!riscv_leaf_pte_allows_access(pte, access)) {
        return sv32_page_fault(virtual_address, access_type, level,
            pte_address, pte, "permission");
      }

      const word_t required_ad_bits =
          (word_t)riscv_leaf_pte_required_ad_bits(access_type);
      if ((pte & required_ad_bits) != required_ad_bits) {
        if (!sv32_page_table_access_allowed(pte_address, MEM_TYPE_WRITE)) {
          return sv32_access_fault(virtual_address, access_type, level,
              pte_address, pte, "page-table-ad-write");
        }
        nemu_profile_count_if(NEMU_PROFILE_MMU_PTE_UPDATES, 1);
        dcache_coherent_write((paddr_t)pte_address, SV32_PTE_BYTES,
            pte | required_ad_bits);
      }

      const uint64_t physical_page_number =
          (pte_ppn & ~replaced_ppn_mask) |
          (virtual_page_number & replaced_ppn_mask);
      const uint64_t physical_address =
          (physical_page_number << PAGE_SHIFT) | page_offset;
      if (!sv32_physical_address_representable(physical_address)) {
        return sv32_access_fault(virtual_address, access_type, level,
            pte_address, pte, "physical-address-width");
      }
      return (paddr_t)physical_address;
    }

    if (riscv_nonleaf_pte_has_reserved_adu(pte)) {
      return sv32_page_fault(virtual_address, access_type, level,
          pte_address, pte, "nonleaf-reserved-adu");
    }
    page_table_address = pte_ppn << PAGE_SHIFT;
  }

  return sv32_page_fault(virtual_address, access_type, -1, 0, 0,
      "walk-exhausted");
}

paddr_t isa_mmu_translate(vaddr_t virtual_address, int length,
    int access_type) {
  return sv32_translate(virtual_address, length, access_type);
}

void isa_riscv32_mmu_tlb_flush(void) {
  /* Sv32 currently has no translation cache; fence still invalidates fetch. */
  vaddr_ifetch_cache_flush();
}

void isa_riscv32_mmu_tlb_flush_selective(vaddr_t virtual_address,
    bool flush_virtual_address, word_t asid, bool flush_asid) {
  (void)virtual_address;
  (void)flush_virtual_address;
  (void)asid;
  (void)flush_asid;
  isa_riscv32_mmu_tlb_flush();
}
