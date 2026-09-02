#ifndef __NEMU_ISA_RISCV_PMP_H__
#define __NEMU_ISA_RISCV_PMP_H__

#include <common.h>
#include <isa/riscv/pmp-encoding.h>

/* PMP regions are represented as [first_byte, one_past_last_byte). */
typedef struct {
  uint64_t first_byte;
  uint64_t one_past_last_byte;
} RiscvPmpRange;

static inline RiscvPmpAddressMatching riscv_pmp_address_matching(
    uint8_t config) {
  return (RiscvPmpAddressMatching)(
      config & RISCV_PMP_ADDRESS_MATCHING_MASK);
}

static inline uint8_t riscv_pmp_sanitize_config(uint8_t config) {
  config &= RISCV_PMP_READ | RISCV_PMP_WRITE | RISCV_PMP_EXECUTE |
            RISCV_PMP_ADDRESS_MATCHING_MASK | RISCV_PMP_LOCKED;
  /* R=0,W=1 is a reserved permission encoding. */
  if ((config & RISCV_PMP_WRITE) != 0 &&
      (config & RISCV_PMP_READ) == 0) {
    config &= ~RISCV_PMP_WRITE;
  }
  return config;
}

static inline uint64_t riscv_pmp_saturating_end(
    uint64_t first_byte, uint64_t size) {
  if (size == 0) return first_byte;
  return first_byte > UINT64_MAX - size ? UINT64_MAX : first_byte + size;
}

static inline bool riscv_pmp_decode_napot(uint64_t encoded_address,
    uint64_t pmpaddr_mask, RiscvPmpRange *range) {
  encoded_address &= pmpaddr_mask;
  uint32_t trailing_ones = 0;
  while (trailing_ones < 64 &&
         ((encoded_address >> trailing_ones) & 1u) != 0) {
    trailing_ones++;
  }

  if (trailing_ones >= 61) {
    range->first_byte = 0;
    range->one_past_last_byte = UINT64_MAX;
    return true;
  }

  const uint64_t encoded_low_mask = trailing_ones == 0 ? 0 :
      ((1ull << trailing_ones) - 1);
  range->first_byte = (encoded_address & ~encoded_low_mask) << 2;
  range->one_past_last_byte = riscv_pmp_saturating_end(
      range->first_byte, 1ull << (trailing_ones + 3));
  return range->first_byte < range->one_past_last_byte;
}

static inline bool riscv_pmp_decode_range(uint32_t index,
    const uint8_t *configs, const word_t *encoded_addresses,
    uint64_t pmpaddr_mask, RiscvPmpRange *range) {
  const uint64_t address =
      (uint64_t)encoded_addresses[index] & pmpaddr_mask;
  switch (riscv_pmp_address_matching(configs[index])) {
    case RISCV_PMP_OFF:
      return false;
    case RISCV_PMP_TOR:
      range->first_byte = index == 0 ? 0 :
          (((uint64_t)encoded_addresses[index - 1] & pmpaddr_mask) << 2);
      range->one_past_last_byte = address << 2;
      return range->first_byte < range->one_past_last_byte;
    case RISCV_PMP_NA4:
      range->first_byte = address << 2;
      range->one_past_last_byte =
          riscv_pmp_saturating_end(range->first_byte, 4);
      return range->first_byte < range->one_past_last_byte;
    case RISCV_PMP_NAPOT:
      return riscv_pmp_decode_napot(address, pmpaddr_mask, range);
    default:
      return false;
  }
}

static inline bool riscv_pmp_range_overlaps(
    RiscvPmpRange range, uint64_t first_byte, uint64_t one_past_last_byte) {
  return first_byte < range.one_past_last_byte &&
         one_past_last_byte > range.first_byte;
}

static inline bool riscv_pmp_range_contains(
    RiscvPmpRange range, uint64_t first_byte, uint64_t one_past_last_byte) {
  return first_byte >= range.first_byte &&
         one_past_last_byte <= range.one_past_last_byte;
}

static inline bool riscv_pmp_entry_allows_access(
    uint8_t config, int access_type, uint8_t privilege) {
  /* An unlocked matching entry does not constrain an M-mode access. */
  if (privilege == PRIV_M && (config & RISCV_PMP_LOCKED) == 0) return true;

  switch (access_type) {
    case MEM_TYPE_IFETCH: return (config & RISCV_PMP_EXECUTE) != 0;
    case MEM_TYPE_WRITE:  return (config & RISCV_PMP_WRITE) != 0;
    case MEM_TYPE_READ:
    default: return (config & RISCV_PMP_READ) != 0;
  }
}

/*
 * PMP uses static priority: the lowest-numbered entry that overlaps any byte
 * wins.  That entry must contain every byte of the access; partial overlap is
 * a failure and later entries are never considered.
 */
static inline bool riscv_pmp_access_allowed(const uint8_t *configs,
    const word_t *encoded_addresses, uint32_t entry_count,
    uint64_t pmpaddr_mask, paddr_t physical_address, int length,
    int access_type, uint8_t privilege) {
  if (length <= 0) return false;
  const uint64_t first_byte = (uint64_t)physical_address;
  const uint64_t one_past_last_byte =
      riscv_pmp_saturating_end(first_byte, (uint64_t)length);
  if (one_past_last_byte <= first_byte) return false;

  for (uint32_t index = 0; index < entry_count; index++) {
    RiscvPmpRange range;
    if (!riscv_pmp_decode_range(index, configs, encoded_addresses,
            pmpaddr_mask, &range)) continue;
    if (!riscv_pmp_range_overlaps(
            range, first_byte, one_past_last_byte)) continue;
    if (!riscv_pmp_range_contains(
            range, first_byte, one_past_last_byte)) return false;
    return riscv_pmp_entry_allows_access(
        configs[index], access_type, privilege);
  }

  /* No matching entry permits M-mode and denies S/U-mode. */
  return privilege == PRIV_M;
}

#endif
