#ifndef NPU_SERVICE_MAILBOX_ABI_H
#define NPU_SERVICE_MAILBOX_ABI_H

/*
 * Fixed RV64 service-firmware mailbox ABI, version 1.3.
 *
 * All fields are little-endian.  The mailbox, command records, and completion
 * records live in the RTL's non-cacheable SDRAM aperture.  A submission
 * generation is nonzero and strictly increasing within one boot epoch.  The command record
 * is deliberately identical to the compiler artifact's 30 x uint64_t payload;
 * the firmware never parses command.bin's file header or metadata JSON.
 */

#define NPU_SERVICE_ABI_MAJOR                 1
#define NPU_SERVICE_ABI_MINOR                 3
#define NPU_SERVICE_MAILBOX_MAGIC             0x4d55504e

#define NPU_SERVICE_MAILBOX_ADDRESS           0x00000000a0000000
#define NPU_SERVICE_COMMAND_ADDRESS           0x00000000a0000100
#define NPU_SERVICE_COMPLETION_ADDRESS        0x00000000a0100000

// ABI 1.3 optional RTL DMA transport table: two (src,dst,bytes) triples per command.
// The firmware executes the first before CONFIG and the second after terminal.
#define NPU_SERVICE_DMA_MMIO_ADDRESS          0x00000000a0300000
#define NPU_SERVICE_ERROR_DMA                 11
#define NPU_SERVICE_COPY_ADDRESS             0x00000000a0200000
#define NPU_SERVICE_COPY_STRIDE               48
#define NPU_SERVICE_FLAG_RAW_COPIES           1
#define NPU_SERVICE_ERROR_BAD_FLAGS           10

#define NPU_SERVICE_MAILBOX_BYTES             64
#define NPU_SERVICE_COMMAND_WORDS             30
#define NPU_SERVICE_COMMAND_STRIDE             240
#define NPU_SERVICE_COMPLETION_STRIDE          64
#define NPU_SERVICE_MAX_COMMANDS               4368

#define NPU_SERVICE_STATE_FREE                0
#define NPU_SERVICE_STATE_READY               1
#define NPU_SERVICE_STATE_RUNNING             2
#define NPU_SERVICE_STATE_DONE                3
#define NPU_SERVICE_STATE_ERROR               4

#define NPU_SERVICE_ERROR_NONE                0
#define NPU_SERVICE_ERROR_BAD_MAGIC           1
#define NPU_SERVICE_ERROR_BAD_VERSION         2
#define NPU_SERVICE_ERROR_BAD_STRIDE          3
#define NPU_SERVICE_ERROR_BAD_COUNT           4
#define NPU_SERVICE_ERROR_BAD_COMMAND_BASE    5
#define NPU_SERVICE_ERROR_BAD_COMPLETION_BASE 6
#define NPU_SERVICE_ERROR_BAD_GENERATION      7
#define NPU_SERVICE_ERROR_NPU_FAULT           8
#define NPU_SERVICE_ERROR_NPU_FATAL           9

#define NPU_SERVICE_COMPLETION_STATUS_SUCCESS   0
#define NPU_SERVICE_COMPLETION_STATUS_NPU_FAULT 1
#define NPU_SERVICE_COMPLETION_STATUS_NPU_FATAL 2

/* CPU <-> firmware precise NPU-fault ABI (mtval format version 1). */
#define NPU_SERVICE_NPU_FAULT_MCAUSE          24
#define NPU_SERVICE_NPU_FAULT_MTVAL_VERSION   1
#define NPU_SERVICE_NPU_FAULT_VERSION_SHIFT   32
#define NPU_SERVICE_NPU_FAULT_VERSION_MASK    0x3f
#define NPU_SERVICE_NPU_FAULT_FATAL_BIT       63

#define NPU_SERVICE_MB_MAGIC_OFFSET           0
#define NPU_SERVICE_MB_ABI_MAJOR_OFFSET       4
#define NPU_SERVICE_MB_ABI_MINOR_OFFSET       6
#define NPU_SERVICE_MB_STATE_OFFSET           8
#define NPU_SERVICE_MB_COUNT_OFFSET           12
#define NPU_SERVICE_MB_COMMAND_STRIDE_OFFSET  16
#define NPU_SERVICE_MB_RESERVED0_OFFSET       20
#define NPU_SERVICE_MB_GENERATION_OFFSET      24
#define NPU_SERVICE_MB_COMMAND_BASE_OFFSET    32
#define NPU_SERVICE_MB_COMPLETION_BASE_OFFSET 40
#define NPU_SERVICE_MB_COMPLETED_OFFSET       48
#define NPU_SERVICE_MB_ERROR_OFFSET           52
#define NPU_SERVICE_MB_BOOT_COUNT_OFFSET      56

#define NPU_SERVICE_CPL_GENERATION_OFFSET     0
#define NPU_SERVICE_CPL_INDEX_OFFSET          8
#define NPU_SERVICE_CPL_STATUS_OFFSET         12
#define NPU_SERVICE_CPL_SEQUENCE_OFFSET       16
#define NPU_SERVICE_CPL_PRODUCER_OFFSET       24
#define NPU_SERVICE_CPL_USER_TAG_OFFSET       32
#define NPU_SERVICE_CPL_FAULT_TVAL_OFFSET     40
#define NPU_SERVICE_CPL_FAULT_PC_OFFSET       48
#define NPU_SERVICE_CPL_FAULT_CAUSE_OFFSET    56

#ifndef __ASSEMBLER__

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

struct npu_service_mailbox_v1 {
    uint32_t magic;
    uint16_t abi_major;
    uint16_t abi_minor;
    uint32_t state;
    uint32_t count;
    uint32_t command_stride;
    uint32_t reserved0;
    uint64_t generation;
    uint64_t command_base;
    uint64_t completion_base;
    uint32_t completed;
    uint32_t error;
    uint64_t boot_count;
};

struct npu_service_command_record_v1 {
    uint64_t words[NPU_SERVICE_COMMAND_WORDS];
};

struct npu_service_completion_v1 {
    uint64_t generation;
    uint32_t index;
    uint32_t status;
    uint64_t sequence_id;
    uint64_t producer_id;
    uint64_t user_tag;
    uint64_t fault_tval;
    uint64_t fault_pc;
    uint64_t fault_cause;
};

#ifdef __cplusplus
}

static_assert(sizeof(npu_service_mailbox_v1) == NPU_SERVICE_MAILBOX_BYTES,
              "mailbox v1 layout changed");
static_assert(sizeof(npu_service_command_record_v1) ==
                  NPU_SERVICE_COMMAND_STRIDE,
              "command record must remain 30 x u64");
static_assert(sizeof(npu_service_completion_v1) ==
                  NPU_SERVICE_COMPLETION_STRIDE,
              "completion v1 layout changed");
static_assert(offsetof(npu_service_mailbox_v1, generation) ==
                  NPU_SERVICE_MB_GENERATION_OFFSET,
              "mailbox generation offset changed");
static_assert(offsetof(npu_service_mailbox_v1, boot_count) ==
                  NPU_SERVICE_MB_BOOT_COUNT_OFFSET,
              "mailbox boot_count offset changed");
static_assert(offsetof(npu_service_completion_v1, sequence_id) ==
                  NPU_SERVICE_CPL_SEQUENCE_OFFSET,
              "completion sequence offset changed");
static_assert(offsetof(npu_service_completion_v1, fault_tval) ==
                  NPU_SERVICE_CPL_FAULT_TVAL_OFFSET,
              "completion fault_tval offset changed");
static_assert(offsetof(npu_service_completion_v1, fault_pc) ==
                  NPU_SERVICE_CPL_FAULT_PC_OFFSET,
              "completion fault_pc offset changed");
static_assert(offsetof(npu_service_completion_v1, fault_cause) ==
                  NPU_SERVICE_CPL_FAULT_CAUSE_OFFSET,
              "completion fault_cause offset changed");
#endif

#endif /* !__ASSEMBLER__ */

#endif /* NPU_SERVICE_MAILBOX_ABI_H */
