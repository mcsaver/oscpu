#ifndef __NEMU_ISA_RISCV_PAGING_H__
#define __NEMU_ISA_RISCV_PAGING_H__

#include <common.h>

/* satp.MODE encodings from the RISC-V privileged architecture. */
typedef enum {
  RISCV_PAGING_BARE = 0,
  RISCV_PAGING_SV32 = 1,
  RISCV_PAGING_SV39 = 8,
  RISCV_PAGING_SV48 = 9,
  RISCV_PAGING_SV57 = 10,
} RiscvPagingMode;

/* Common low PTE bits shared by Sv32 and every RV64 paged mode. */
typedef enum {
  RISCV_PTE_VALID      = 1u << 0,
  RISCV_PTE_READ       = 1u << 1,
  RISCV_PTE_WRITE      = 1u << 2,
  RISCV_PTE_EXECUTE    = 1u << 3,
  RISCV_PTE_USER       = 1u << 4,
  RISCV_PTE_GLOBAL     = 1u << 5,
  RISCV_PTE_ACCESSED   = 1u << 6,
  RISCV_PTE_DIRTY      = 1u << 7,
} RiscvPageTableEntryBit;

/* The architectural access context used for leaf-PTE permission checks. */
typedef struct {
  int access_type;
  uint8_t effective_privilege;
  bool permit_supervisor_user_memory;
  bool execute_pages_are_readable;
} RiscvPageAccess;

/*
 * MPRV changes the privilege of explicit loads and stores, never instruction
 * fetch.  This is the effective privilege used by both translation and PMP.
 */
static inline uint8_t riscv_effective_memory_privilege(
    uint8_t current_privilege, word_t mstatus, int access_type) {
  if (access_type == MEM_TYPE_IFETCH || current_privilege != PRIV_M ||
      (mstatus & MSTATUS_MPRV) == 0) {
    return current_privilege;
  }

  switch (mstatus & MSTATUS_MPP_MASK) {
    case MSTATUS_MPP_M: return PRIV_M;
    case MSTATUS_MPP_S: return PRIV_S;
    default: return PRIV_U;
  }
}

static inline RiscvPageAccess riscv_page_access(
    uint8_t current_privilege, word_t mstatus, int access_type) {
  return (RiscvPageAccess) {
    .access_type = access_type,
    .effective_privilege = riscv_effective_memory_privilege(
        current_privilege, mstatus, access_type),
    .permit_supervisor_user_memory = (mstatus & MSTATUS_SUM) != 0,
    .execute_pages_are_readable = (mstatus & MSTATUS_MXR) != 0,
  };
}

static inline word_t riscv_page_fault_cause(int access_type) {
  switch (access_type) {
    case MEM_TYPE_IFETCH: return CAUSE_INST_PAGE_FAULT;
    case MEM_TYPE_WRITE:  return CAUSE_STORE_PAGE_FAULT;
    case MEM_TYPE_READ:
    default: return CAUSE_LOAD_PAGE_FAULT;
  }
}

static inline word_t riscv_access_fault_cause(int access_type) {
  switch (access_type) {
    case MEM_TYPE_IFETCH: return CAUSE_INST_ACCESS;
    case MEM_TYPE_WRITE:  return CAUSE_STORE_ACCESS;
    case MEM_TYPE_READ:
    default: return CAUSE_LOAD_ACCESS;
  }
}

/* V=0 and the reserved R=0,W=1 encoding both terminate a walk. */
static inline bool riscv_pte_has_invalid_permissions(uint64_t pte) {
  return (pte & RISCV_PTE_VALID) == 0 ||
         ((pte & RISCV_PTE_READ) == 0 &&
          (pte & RISCV_PTE_WRITE) != 0);
}

static inline bool riscv_pte_is_leaf(uint64_t pte) {
  return (pte & (RISCV_PTE_READ | RISCV_PTE_EXECUTE)) != 0;
}

/*
 * U, SUM and MXR are evaluated only after the walk reaches a leaf.  S-mode
 * can never execute from a U page; SUM only permits explicit data accesses.
 */
static inline bool riscv_leaf_pte_allows_access(
    uint64_t pte, RiscvPageAccess access) {
  const bool user_page = (pte & RISCV_PTE_USER) != 0;
  if (access.effective_privilege == PRIV_U && !user_page) return false;
  if (access.effective_privilege == PRIV_S && user_page) {
    if (access.access_type == MEM_TYPE_IFETCH) return false;
    if (!access.permit_supervisor_user_memory) return false;
  }

  switch (access.access_type) {
    case MEM_TYPE_IFETCH:
      return (pte & RISCV_PTE_EXECUTE) != 0;
    case MEM_TYPE_WRITE:
      return (pte & RISCV_PTE_WRITE) != 0;
    case MEM_TYPE_READ:
      return (pte & RISCV_PTE_READ) != 0 ||
             (access.execute_pages_are_readable &&
              (pte & RISCV_PTE_EXECUTE) != 0);
    default:
      return false;
  }
}

static inline uint64_t riscv_leaf_pte_required_ad_bits(int access_type) {
  return RISCV_PTE_ACCESSED |
         (access_type == MEM_TYPE_WRITE ? RISCV_PTE_DIRTY : 0);
}

/* A, D and U are reserved in a non-leaf page-table entry. */
static inline bool riscv_nonleaf_pte_has_reserved_adu(uint64_t pte) {
  return (pte & (RISCV_PTE_ACCESSED |
                 RISCV_PTE_DIRTY |
                 RISCV_PTE_USER)) != 0;
}

#endif
