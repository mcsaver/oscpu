#ifndef __RISCV_ATOMIC_H__
#define __RISCV_ATOMIC_H__

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/*
 * RISC-V A 扩展的纯手册层。
 *
 * 本文件只描述编码、原子操作、物理 reservation set 与 PMA 类别，不读取
 * CPU、虚拟内存、物理内存、宿主线程或构建配置。RV32/RV64 的译码器和执行器
 * 只能把它作为纯值层使用，不能在 execute 阶段重新解释 raw instruction。
 */

typedef enum {
  RISCV_ATOMIC_MNEMONIC_INVALID = 0,
  RISCV_ATOMIC_MNEMONIC_LR,
  RISCV_ATOMIC_MNEMONIC_SC,
  RISCV_ATOMIC_MNEMONIC_AMOSWAP,
  RISCV_ATOMIC_MNEMONIC_AMOADD,
  RISCV_ATOMIC_MNEMONIC_AMOXOR,
  RISCV_ATOMIC_MNEMONIC_AMOAND,
  RISCV_ATOMIC_MNEMONIC_AMOOR,
  RISCV_ATOMIC_MNEMONIC_AMOMIN,
  RISCV_ATOMIC_MNEMONIC_AMOMAX,
  RISCV_ATOMIC_MNEMONIC_AMOMINU,
  RISCV_ATOMIC_MNEMONIC_AMOMAXU,
} RiscvAtomicMnemonic;

typedef enum {
  RISCV_ATOMIC_WIDTH_WORD = 4,
  RISCV_ATOMIC_WIDTH_DOUBLEWORD = 8,
} RiscvAtomicWidth;

typedef struct {
  RiscvAtomicMnemonic mnemonic;
  RiscvAtomicWidth width;
  bool aq;
  bool rl;
} RiscvAtomicInstruction;

/* 每个 hart 至多持有一个物理 reservation set；NEMU 选择精确到 LR 宽度。 */
typedef struct {
  bool valid;
  uint64_t physical_address;
  uint8_t size_bytes;
} RiscvLoadReservation;

/*
 * 原子 PMA 类别按手册能力递增：AMOArithmetic 包含 logical/swap，
 * AMOLogical 包含 swap。misaligned_atomicity_granule_bytes=0 表示未实现
 * misaligned atomicity granule，因此 A 扩展访问必须自然对齐。
 */
typedef enum {
  RISCV_AMO_PMA_NONE = 0,
  RISCV_AMO_PMA_SWAP,
  RISCV_AMO_PMA_LOGICAL,
  RISCV_AMO_PMA_ARITHMETIC,
} RiscvAmoPma;

typedef enum {
  RISCV_RSRV_PMA_NONE = 0,
  RISCV_RSRV_PMA_NON_EVENTUAL,
  RISCV_RSRV_PMA_EVENTUAL,
} RiscvReservationPma;

typedef struct {
  RiscvAmoPma amo;
  RiscvReservationPma reservation;
  uint16_t misaligned_atomicity_granule_bytes;
} RiscvAtomicPma;

#define RISCV_SC_SUCCESS 0u
/* SC 的非零失败码由实现选择；NEMU 固定采用规范允许的 1。 */
#define RISCV_SC_FAILURE 1u

static inline bool riscv_atomic_decode(uint32_t encoding, uint8_t xlen_bits,
    RiscvAtomicInstruction *instruction) {
  if (instruction == NULL || (encoding & UINT32_C(0x7f)) != UINT32_C(0x2f)) {
    return false;
  }

  RiscvAtomicInstruction decoded = {
    .mnemonic = RISCV_ATOMIC_MNEMONIC_INVALID,
    .width = RISCV_ATOMIC_WIDTH_WORD,
    .aq = ((encoding >> 26) & UINT32_C(1)) != 0,
    .rl = ((encoding >> 25) & UINT32_C(1)) != 0,
  };

  const uint32_t funct3 = (encoding >> 12) & UINT32_C(0x7);
  if (funct3 == UINT32_C(0x2)) {
    decoded.width = RISCV_ATOMIC_WIDTH_WORD;
  } else if (funct3 == UINT32_C(0x3) && xlen_bits == 64) {
    decoded.width = RISCV_ATOMIC_WIDTH_DOUBLEWORD;
  } else {
    return false;
  }

  const uint32_t funct5 = (encoding >> 27) & UINT32_C(0x1f);
  switch (funct5) {
    case 0x02:
      /* LR 的 rs2 字段固定为 x0；非法编码必须先于任何地址访问拒绝。 */
      if (((encoding >> 20) & UINT32_C(0x1f)) != 0) return false;
      decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_LR;
      break;
    case 0x03: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_SC; break;
    case 0x01: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOSWAP; break;
    case 0x00: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOADD; break;
    case 0x04: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOXOR; break;
    case 0x0c: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOAND; break;
    case 0x08: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOOR; break;
    case 0x10: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOMIN; break;
    case 0x14: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOMAX; break;
    case 0x18: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOMINU; break;
    case 0x1c: decoded.mnemonic = RISCV_ATOMIC_MNEMONIC_AMOMAXU; break;
    default: return false;
  }

  if (xlen_bits != 32 && xlen_bits != 64) return false;
  *instruction = decoded;
  return true;
}

static inline bool riscv_atomic_is_load_reserved(
    const RiscvAtomicInstruction *instruction) {
  return instruction->mnemonic == RISCV_ATOMIC_MNEMONIC_LR;
}

static inline bool riscv_atomic_is_store_conditional(
    const RiscvAtomicInstruction *instruction) {
  return instruction->mnemonic == RISCV_ATOMIC_MNEMONIC_SC;
}

static inline bool riscv_atomic_is_memory_operation(
    const RiscvAtomicInstruction *instruction) {
  return instruction->mnemonic >= RISCV_ATOMIC_MNEMONIC_AMOSWAP &&
         instruction->mnemonic <= RISCV_ATOMIC_MNEMONIC_AMOMAXU;
}

static inline uint8_t riscv_atomic_width_bytes(
    const RiscvAtomicInstruction *instruction) {
  return (uint8_t)instruction->width;
}

static inline bool riscv_atomic_address_is_naturally_aligned(
    uint64_t address, const RiscvAtomicInstruction *instruction) {
  const uint8_t width = riscv_atomic_width_bytes(instruction);
  return (address & ((uint64_t)width - UINT64_C(1))) == 0;
}

static inline uint64_t riscv_atomic_width_mask(RiscvAtomicWidth width) {
  return width == RISCV_ATOMIC_WIDTH_WORD
      ? UINT64_C(0xffffffff) : UINT64_MAX;
}

static inline bool riscv_atomic_signed_less(uint64_t lhs, uint64_t rhs,
    RiscvAtomicWidth width) {
  const uint64_t mask = riscv_atomic_width_mask(width);
  const uint64_t sign = width == RISCV_ATOMIC_WIDTH_WORD
      ? (UINT64_C(1) << 31) : (UINT64_C(1) << 63);
  lhs &= mask;
  rhs &= mask;
  if (((lhs ^ rhs) & sign) != 0) return (lhs & sign) != 0;
  return lhs < rhs;
}

static inline uint64_t riscv_atomic_compute_new_value(
    const RiscvAtomicInstruction *instruction, uint64_t old_value,
    uint64_t source_value) {
  const uint64_t mask = riscv_atomic_width_mask(instruction->width);
  const uint64_t old_bits = old_value & mask;
  const uint64_t source_bits = source_value & mask;

  switch (instruction->mnemonic) {
    case RISCV_ATOMIC_MNEMONIC_AMOSWAP: return source_bits;
    case RISCV_ATOMIC_MNEMONIC_AMOADD:
      return (old_bits + source_bits) & mask;
    case RISCV_ATOMIC_MNEMONIC_AMOXOR: return old_bits ^ source_bits;
    case RISCV_ATOMIC_MNEMONIC_AMOAND: return old_bits & source_bits;
    case RISCV_ATOMIC_MNEMONIC_AMOOR: return old_bits | source_bits;
    case RISCV_ATOMIC_MNEMONIC_AMOMIN:
      return riscv_atomic_signed_less(old_bits, source_bits,
          instruction->width) ? old_bits : source_bits;
    case RISCV_ATOMIC_MNEMONIC_AMOMAX:
      return riscv_atomic_signed_less(old_bits, source_bits,
          instruction->width) ? source_bits : old_bits;
    case RISCV_ATOMIC_MNEMONIC_AMOMINU:
      return old_bits < source_bits ? old_bits : source_bits;
    case RISCV_ATOMIC_MNEMONIC_AMOMAXU:
      return old_bits > source_bits ? old_bits : source_bits;
    default: return old_bits;
  }
}

static inline uint64_t riscv_atomic_old_value_to_xlen(
    const RiscvAtomicInstruction *instruction, uint64_t old_value,
    uint8_t xlen_bits) {
  const uint64_t width_value = old_value &
      riscv_atomic_width_mask(instruction->width);
  if (xlen_bits == 64 && instruction->width == RISCV_ATOMIC_WIDTH_WORD &&
      (width_value & (UINT64_C(1) << 31)) != 0) {
    return width_value | UINT64_C(0xffffffff00000000);
  }
  return xlen_bits == 32 ? width_value & UINT64_C(0xffffffff) : width_value;
}

static inline bool riscv_physical_ranges_overlap(uint64_t lhs_start,
    uint64_t lhs_size, uint64_t rhs_start, uint64_t rhs_size) {
  if (lhs_size == 0 || rhs_size == 0) return false;
  if (lhs_start <= rhs_start) return (rhs_start - lhs_start) < lhs_size;
  return (lhs_start - rhs_start) < rhs_size;
}

static inline void riscv_load_reservation_clear(
    RiscvLoadReservation *reservation) {
  reservation->valid = false;
  reservation->physical_address = 0;
  reservation->size_bytes = 0;
}

static inline void riscv_load_reservation_set(
    RiscvLoadReservation *reservation, uint64_t physical_address,
    uint8_t size_bytes) {
  reservation->valid = true;
  reservation->physical_address = physical_address;
  reservation->size_bytes = size_bytes;
}

static inline bool riscv_load_reservation_matches(
    const RiscvLoadReservation *reservation, uint64_t physical_address,
    uint8_t size_bytes) {
  return reservation->valid && reservation->physical_address == physical_address &&
         reservation->size_bytes == size_bytes;
}

static inline void riscv_load_reservation_invalidate_if_overlap(
    RiscvLoadReservation *reservation, uint64_t physical_address,
    uint64_t size_bytes) {
  if (reservation->valid && riscv_physical_ranges_overlap(
          reservation->physical_address, reservation->size_bytes,
          physical_address, size_bytes)) {
    riscv_load_reservation_clear(reservation);
  }
}

static inline RiscvAtomicPma riscv_atomic_pma_none(void) {
  const RiscvAtomicPma pma = {
    .amo = RISCV_AMO_PMA_NONE,
    .reservation = RISCV_RSRV_PMA_NONE,
    .misaligned_atomicity_granule_bytes = 0,
  };
  return pma;
}

static inline RiscvAtomicPma
riscv_atomic_pma_arithmetic_reservation_eventual(void) {
  const RiscvAtomicPma pma = {
    .amo = RISCV_AMO_PMA_ARITHMETIC,
    .reservation = RISCV_RSRV_PMA_EVENTUAL,
    .misaligned_atomicity_granule_bytes = 0,
  };
  return pma;
}

static inline RiscvAmoPma riscv_atomic_required_amo_pma(
    RiscvAtomicMnemonic mnemonic) {
  switch (mnemonic) {
    case RISCV_ATOMIC_MNEMONIC_AMOSWAP:
      return RISCV_AMO_PMA_SWAP;
    case RISCV_ATOMIC_MNEMONIC_AMOXOR:
    case RISCV_ATOMIC_MNEMONIC_AMOAND:
    case RISCV_ATOMIC_MNEMONIC_AMOOR:
      return RISCV_AMO_PMA_LOGICAL;
    case RISCV_ATOMIC_MNEMONIC_AMOADD:
    case RISCV_ATOMIC_MNEMONIC_AMOMIN:
    case RISCV_ATOMIC_MNEMONIC_AMOMAX:
    case RISCV_ATOMIC_MNEMONIC_AMOMINU:
    case RISCV_ATOMIC_MNEMONIC_AMOMAXU:
      return RISCV_AMO_PMA_ARITHMETIC;
    default:
      return RISCV_AMO_PMA_NONE;
  }
}

static inline bool riscv_atomic_pma_allows(
    RiscvAtomicPma pma, const RiscvAtomicInstruction *instruction) {
  if (riscv_atomic_is_load_reserved(instruction) ||
      riscv_atomic_is_store_conditional(instruction)) {
    return pma.reservation != RISCV_RSRV_PMA_NONE;
  }
  if (!riscv_atomic_is_memory_operation(instruction)) return false;
  return pma.amo >= riscv_atomic_required_amo_pma(instruction->mnemonic);
}

#endif
