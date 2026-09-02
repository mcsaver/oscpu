#ifndef __NEMU_ISA_RISCV_PMP_ENCODING_H__
#define __NEMU_ISA_RISCV_PMP_ENCODING_H__

/* RISC-V 特权手册定义的 PMP 表项数与 pmpcfg 字段编码。 */
enum { RISCV_PMP_ENTRY_COUNT = 16 };

typedef enum {
  RISCV_PMP_READ    = 1u << 0,
  RISCV_PMP_WRITE   = 1u << 1,
  RISCV_PMP_EXECUTE = 1u << 2,
  RISCV_PMP_ADDRESS_MATCHING_MASK = 3u << 3,
  RISCV_PMP_LOCKED  = 1u << 7,
} RiscvPmpConfigBit;

typedef enum {
  RISCV_PMP_OFF   = 0u << 3,
  RISCV_PMP_TOR   = 1u << 3,
  RISCV_PMP_NA4   = 2u << 3,
  RISCV_PMP_NAPOT = 3u << 3,
} RiscvPmpAddressMatching;

#endif
