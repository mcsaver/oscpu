#ifndef __NEMU_RISCV_PRIVILEGED_H__
#define __NEMU_RISCV_PRIVILEGED_H__

#include <common.h>
#include <isa-def.h>

/*
 * This header contains XLEN-independent entities named by the RISC-V
 * privileged architecture.  RV32 and RV64 must share these definitions so
 * trap delegation, interrupt priority and Zicsr access intent cannot drift
 * into two subtly different implementations.
 */

typedef enum {
  RISCV_CSR_OPERATION_WRITE,
  RISCV_CSR_OPERATION_SET_BITS,
  RISCV_CSR_OPERATION_CLEAR_BITS,
} RiscvCsrOperation;

typedef struct {
  RiscvCsrOperation operation;
  bool reads_csr;
  bool writes_csr;
} RiscvCsrAccessIntent;

typedef enum {
  RISCV_CSR_SOURCE_REGISTER,
  RISCV_CSR_SOURCE_IMMEDIATE,
} RiscvCsrSourceKind;

/* A decoded Zicsr instruction, expressed without an execution-time funct3. */
typedef struct {
  uint16_t address;
  uint8_t destination_register;
  uint8_t source_field;
  RiscvCsrSourceKind source_kind;
  RiscvCsrAccessIntent access;
} RiscvCsrInstruction;

/*
 * Zicsr defines CSR read and write intent from the encoded register field,
 * not from the register value observed while the instruction executes.
 */
static inline bool riscv_decode_csr_access_intent(
    uint32_t funct3, uint32_t rd, uint32_t source_field,
    RiscvCsrAccessIntent *access) {
  switch (funct3) {
    case 0x1:  /* CSRRW */
    case 0x5:  /* CSRRWI */
      access->operation = RISCV_CSR_OPERATION_WRITE;
      access->reads_csr = rd != 0;
      access->writes_csr = true;
      return true;
    case 0x2:  /* CSRRS */
    case 0x6:  /* CSRRSI */
      access->operation = RISCV_CSR_OPERATION_SET_BITS;
      access->reads_csr = true;
      access->writes_csr = source_field != 0;
      return true;
    case 0x3:  /* CSRRC */
    case 0x7:  /* CSRRCI */
      access->operation = RISCV_CSR_OPERATION_CLEAR_BITS;
      access->reads_csr = true;
      access->writes_csr = source_field != 0;
      return true;
    default:
      return false;
  }
}

static inline bool riscv_decode_csr_instruction(
    uint32_t funct3, uint32_t address, uint32_t rd, uint32_t source_field,
    RiscvCsrInstruction *instruction) {
  RiscvCsrAccessIntent access;
  if (!riscv_decode_csr_access_intent(funct3, rd, source_field, &access)) {
    return false;
  }

  *instruction = (RiscvCsrInstruction) {
    .address = address,
    .destination_register = rd,
    .source_field = source_field,
    .source_kind = (funct3 & 0x4u) != 0
                       ? RISCV_CSR_SOURCE_IMMEDIATE
                       : RISCV_CSR_SOURCE_REGISTER,
    .access = access,
  };
  return true;
}

/* CSR address[11:10] == 3 denotes a read-only CSR. */
static inline bool riscv_csr_address_is_read_only(uint32_t csr) {
  return ((csr >> 10) & 0x3u) == 0x3u;
}

#define RISCV_TVEC_MODE_MASK       ((word_t)0x3)
#define RISCV_TVEC_MODE_DIRECT     ((word_t)0x0)
#define RISCV_TVEC_MODE_VECTORED   ((word_t)0x1)

static inline bool riscv_cause_is_interrupt(word_t cause) {
  return (cause >> (sizeof(word_t) * 8 - 1)) != 0;
}

static inline word_t riscv_cause_code(word_t cause) {
  const word_t interrupt_bit = (word_t)1 << (sizeof(word_t) * 8 - 1);
  return cause & ~interrupt_bit;
}

typedef enum {
  RISCV_TRAP_TARGET_SUPERVISOR = PRIV_S,
  RISCV_TRAP_TARGET_MACHINE = PRIV_M,
} RiscvTrapTarget;

/* Architectural inputs consumed by one trap-entry state transition. */
typedef struct {
  word_t cause;
  vaddr_t exception_pc;
  word_t trap_value;
  uint8_t previous_privilege;
  RiscvTrapTarget target;
} RiscvTrapRequest;

/*
 * Traps taken from M-mode are never delegated.  Otherwise synchronous
 * exceptions consult medeleg and interrupts consult mideleg.
 */
static inline RiscvTrapTarget riscv_select_trap_target(
    word_t cause, word_t medeleg, word_t mideleg,
    uint8_t current_privilege) {
  if (current_privilege == PRIV_M) {
    return RISCV_TRAP_TARGET_MACHINE;
  }

  const word_t cause_code = riscv_cause_code(cause);
  const word_t xlen = sizeof(word_t) * 8;
  if (cause_code >= xlen) {
    return RISCV_TRAP_TARGET_MACHINE;
  }

  const word_t delegation =
      riscv_cause_is_interrupt(cause) ? mideleg : medeleg;
  return ((delegation >> cause_code) & 1u) != 0
             ? RISCV_TRAP_TARGET_SUPERVISOR
             : RISCV_TRAP_TARGET_MACHINE;
}

/* Reserved xtvec.MODE values are WARL-coerced to Direct. */
static inline word_t riscv_tvec_warl_value(word_t value) {
  word_t mode = value & RISCV_TVEC_MODE_MASK;
  return (value & ~RISCV_TVEC_MODE_MASK) |
         (mode == RISCV_TVEC_MODE_VECTORED
              ? RISCV_TVEC_MODE_VECTORED
              : RISCV_TVEC_MODE_DIRECT);
}

/* Vectored mode offsets interrupts only; synchronous exceptions use BASE. */
static inline word_t riscv_tvec_trap_target(word_t tvec, word_t cause) {
  word_t base = tvec & ~RISCV_TVEC_MODE_MASK;
  if (riscv_cause_is_interrupt(cause) &&
      (tvec & RISCV_TVEC_MODE_MASK) == RISCV_TVEC_MODE_VECTORED) {
    return base + (riscv_cause_code(cause) << 2);
  }
  return base;
}

typedef struct {
  bool pending;
  uint8_t target_privilege;
  uint32_t cause_code;
} RiscvInterruptSelection;

static inline uint8_t riscv_interrupt_target_privilege(
    word_t cause_code, word_t mideleg, uint8_t current_privilege) {
  return (uint8_t)riscv_select_trap_target(
      MCAUSE_INTERRUPT | cause_code, 0, mideleg, current_privilege);
}

static inline word_t riscv_machine_interrupt_candidates(
    word_t enabled_pending, word_t mideleg) {
  return enabled_pending & ~mideleg & MIP_IRQ_MASK;
}

static inline word_t riscv_supervisor_interrupt_candidates(
    word_t enabled_pending, word_t mideleg) {
  return enabled_pending & mideleg & MIP_IRQ_MASK;
}

static inline bool riscv_machine_interrupts_globally_enabled(
    uint8_t current_privilege, word_t mstatus) {
  return current_privilege < PRIV_M ||
         (current_privilege == PRIV_M && (mstatus & MSTATUS_MIE));
}

static inline bool riscv_supervisor_interrupts_globally_enabled(
    uint8_t current_privilege, word_t mstatus) {
  return current_privilege < PRIV_S ||
         (current_privilege == PRIV_S && (mstatus & MSTATUS_SIE));
}

/* Standard interrupt priority: MEI > MSI > MTI > SEI > SSI > STI. */
static inline uint32_t riscv_machine_interrupt_priority(word_t candidates) {
  if (candidates & MIP_MEIP) return IRQ_CAUSE_MEI;
  if (candidates & MIP_MSIP) return IRQ_CAUSE_MSI;
  if (candidates & MIP_MTIP) return IRQ_CAUSE_MTI;
  if (candidates & MIP_SEIP) return IRQ_CAUSE_SEI;
  if (candidates & MIP_SSIP) return IRQ_CAUSE_SSI;
  if (candidates & MIP_STIP) return IRQ_CAUSE_STI;
  return UINT32_MAX;
}

static inline uint32_t riscv_supervisor_interrupt_priority(word_t candidates) {
  if (candidates & MIP_SEIP) return IRQ_CAUSE_SEI;
  if (candidates & MIP_SSIP) return IRQ_CAUSE_SSI;
  if (candidates & MIP_STIP) return IRQ_CAUSE_STI;
  return UINT32_MAX;
}

/*
 * First partition enabled pending interrupts by mideleg, then apply the
 * target privilege's global enable and standard priority order.
 */
static inline RiscvInterruptSelection riscv_select_interrupt(
    word_t enabled_pending, word_t mideleg, uint8_t current_privilege,
    word_t mstatus) {
  word_t machine_pending =
      riscv_machine_interrupt_candidates(enabled_pending, mideleg);
  if (riscv_machine_interrupts_globally_enabled(
          current_privilege, mstatus)) {
    uint32_t cause = riscv_machine_interrupt_priority(machine_pending);
    if (cause != UINT32_MAX) {
      return (RiscvInterruptSelection) {
        .pending = true,
        .target_privilege = (uint8_t)riscv_select_trap_target(
            MCAUSE_INTERRUPT | cause, 0, mideleg, current_privilege),
        .cause_code = cause,
      };
    }
  }

  word_t supervisor_pending =
      riscv_supervisor_interrupt_candidates(enabled_pending, mideleg);
  if (riscv_supervisor_interrupts_globally_enabled(
          current_privilege, mstatus)) {
    uint32_t cause = riscv_supervisor_interrupt_priority(supervisor_pending);
    if (cause != UINT32_MAX) {
      return (RiscvInterruptSelection) {
        .pending = true,
        .target_privilege = (uint8_t)riscv_select_trap_target(
            MCAUSE_INTERRUPT | cause, 0, mideleg, current_privilege),
        .cause_code = cause,
      };
    }
  }

  return (RiscvInterruptSelection) {
    .pending = false,
    .target_privilege = PRIV_M,
    .cause_code = UINT32_MAX,
  };
}

#endif
