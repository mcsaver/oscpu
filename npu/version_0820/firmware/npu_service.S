#include "npu_service_mailbox_abi.h"

/*
 * Fixed RV64 NPU service firmware, mailbox ABI v1.3.
 *
 * This firmware consumes raw 30-word descriptor records from the NC SDRAM
 * mailbox.  CONFIG instructions are deliberately static: only the value in
 * t2 changes.  The adjacent LO/HI launch pair is one precise RV64 transaction,
 * so code after the pair executes only after a successful NPU terminal.
 *
 * A recoverable NPU terminal becomes precise synchronous exception 24.  The
 * trap handler issues the architectural CONFIG-30 clear exactly once, writes
 * a failure completion, and returns to the mailbox poll without replaying the
 * failed LO/HI pair.  Fatal NPU errors and unexpected traps require reset.
 */

    .option norvc
    .option norelax

    .equ NPU_CONFIG_BASE, ((5 << 25) | (7 << 15) | (4 << 12) | \
                           (31 << 7) | 0x5b)
    .equ NPU_LAUNCH_LO, 0x0220305b
    .equ NPU_LAUNCH_HI, 0x0bf0305b
    /* CONFIG index 30, rs1=x0: value-free architectural recovery command. */
    .equ NPU_RECOVERY_CLEAR, 0x0be04fdb

    .globl npu_service_mailbox_address
    .set npu_service_mailbox_address, NPU_SERVICE_MAILBOX_ADDRESS
    .globl npu_service_command_address
    .set npu_service_command_address, NPU_SERVICE_COMMAND_ADDRESS
    .globl npu_service_completion_address
    .set npu_service_completion_address, NPU_SERVICE_COMPLETION_ADDRESS
    .globl npu_service_mailbox_bytes
    .set npu_service_mailbox_bytes, NPU_SERVICE_MAILBOX_BYTES
    .globl npu_service_command_stride
    .set npu_service_command_stride, NPU_SERVICE_COMMAND_STRIDE
    .globl npu_service_completion_stride
    .set npu_service_completion_stride, NPU_SERVICE_COMPLETION_STRIDE
    .globl npu_service_max_commands
    .set npu_service_max_commands, NPU_SERVICE_MAX_COMMANDS
    .globl npu_service_success_only_v1
    .set npu_service_success_only_v1, 0
    .globl npu_service_fault_recovery_v1
    .set npu_service_fault_recovery_v1, 1

    /*
     * Each expansion stays four 32-bit instructions wide.  The NOPs preserve
     * the already-qualified LD -> CONFIG scheduling shape used by SystemTop.
     */
    .macro NPU_CONFIG index, byte_offset
        ld      t2, \byte_offset(s1)
        nop
        .4byte  (NPU_CONFIG_BASE | ((\index) << 20))
        nop
    .endm

    .section .text.entry, "ax", @progbits
    .balign 8
    .globl _start
    .type _start, @function
_start:
    li      s0, NPU_SERVICE_MAILBOX_ADDRESS
    li      s7, 0  /* generation zero is never a valid accepted owner */
    li      s8, 0  /* trap re-entry guard; nonzero until recovery mret */
    lla     t0, npu_service_trap_entry
    csrw    mtvec, t0

    /* Host initializes boot_count before releasing reset. */
    ld      t0, NPU_SERVICE_MB_BOOT_COUNT_OFFSET(s0)
    addi    t0, t0, 1
    sd      t0, NPU_SERVICE_MB_BOOT_COUNT_OFFSET(s0)

.Lpoll_ready:
    lw      t0, NPU_SERVICE_MB_STATE_OFFSET(s0)
    li      t1, NPU_SERVICE_STATE_READY
    bne     t0, t1, .Lpoll_ready
    fence   r, rw

    /* Fail closed on malformed ownership or layout fields. */
    lwu     t0, NPU_SERVICE_MB_MAGIC_OFFSET(s0)
    li      t1, NPU_SERVICE_MAILBOX_MAGIC
    bne     t0, t1, .Lbad_magic

    lhu     t0, NPU_SERVICE_MB_ABI_MAJOR_OFFSET(s0)
    li      t1, NPU_SERVICE_ABI_MAJOR
    bne     t0, t1, .Lbad_version
    lhu     t0, NPU_SERVICE_MB_ABI_MINOR_OFFSET(s0)
    li      t1, NPU_SERVICE_ABI_MINOR
    bne     t0, t1, .Lbad_version

    lwu     s4, NPU_SERVICE_MB_COMMAND_STRIDE_OFFSET(s0)
    li      t1, NPU_SERVICE_COMMAND_STRIDE
    bne     s4, t1, .Lbad_stride

    lwu     s3, NPU_SERVICE_MB_COUNT_OFFSET(s0)
    li      t1, NPU_SERVICE_MAX_COMMANDS
    bltu    t1, s3, .Lbad_count

    ld      s1, NPU_SERVICE_MB_COMMAND_BASE_OFFSET(s0)
    li      t1, NPU_SERVICE_COMMAND_ADDRESS
    bne     s1, t1, .Lbad_command_base

    ld      s6, NPU_SERVICE_MB_COMPLETION_BASE_OFFSET(s0)
    li      t1, NPU_SERVICE_COMPLETION_ADDRESS
    bne     s6, t1, .Lbad_completion_base

    /*
     * Per-boot strictly monotonic generation gate.  All other READY fields have been validated,
     * but ownership has not transitioned and no CONFIG can execute yet.
     * Update last_generation only for the request accepted below.
     */
    ld      s5, NPU_SERVICE_MB_GENERATION_OFFSET(s0)
    beqz    s5, .Lbad_generation
    bgeu    s7, s5, .Lbad_generation
    mv      s7, s5

    lwu     s9, NPU_SERVICE_MB_RESERVED0_OFFSET(s0)
    li      t0, NPU_SERVICE_FLAG_RAW_COPIES
    bltu    t0, s9, .Lbad_flags
    beqz    s9, .Lno_copies
    li      s9, NPU_SERVICE_COPY_ADDRESS
.Lno_copies:
    li      s2, 0
    sw      zero, NPU_SERVICE_MB_COMPLETED_OFFSET(s0)
    sw      zero, NPU_SERVICE_MB_ERROR_OFFSET(s0)
    li      t0, NPU_SERVICE_STATE_RUNNING
    fence   rw, w
    sw      t0, NPU_SERVICE_MB_STATE_OFFSET(s0)

    beqz    s3, .Lbatch_done

    /*
     * s1 points at the current 240-byte descriptor record.  Keep this block
     * mechanically ordered by descriptor word number; SystemTop accepts only
     * CONFIG indices 0..29 in sequence.
     */
 .Lcommand_begin:
    beqz    s9, .Lbefore_config
    mv      a0, s9
    jal     ra, .Ldma_copy
.Lbefore_config:
    .balign 8
    .globl npu_service_config_begin
npu_service_config_begin:
    NPU_CONFIG 0,   0
    NPU_CONFIG 1,   8
    NPU_CONFIG 2,  16
    NPU_CONFIG 3,  24
    NPU_CONFIG 4,  32
    NPU_CONFIG 5,  40
    NPU_CONFIG 6,  48
    NPU_CONFIG 7,  56
    NPU_CONFIG 8,  64
    NPU_CONFIG 9,  72
    NPU_CONFIG 10, 80
    NPU_CONFIG 11, 88
    NPU_CONFIG 12, 96
    NPU_CONFIG 13, 104
    NPU_CONFIG 14, 112
    NPU_CONFIG 15, 120
    NPU_CONFIG 16, 128
    NPU_CONFIG 17, 136
    NPU_CONFIG 18, 144
    NPU_CONFIG 19, 152
    NPU_CONFIG 20, 160
    NPU_CONFIG 21, 168
    NPU_CONFIG 22, 176
    NPU_CONFIG 23, 184
    NPU_CONFIG 24, 192
    NPU_CONFIG 25, 200
    NPU_CONFIG 26, 208
    NPU_CONFIG 27, 216
    NPU_CONFIG 28, 224
    NPU_CONFIG 29, 232
    .globl npu_service_config_end
npu_service_config_end:

    /*
     * Do not insert, relax, or compress anything between these two words.
     * PairOwner consumes them as one 64-bit logical Tensor instruction.
     */
    .balign 8
    .globl npu_service_launch_pair
npu_service_launch_pair:
    .4byte  NPU_LAUNCH_LO
    .4byte  NPU_LAUNCH_HI
    .globl npu_service_launch_pair_end
npu_service_launch_pair_end:
    beqz    s9, .Lpublish_completion
    addi    a0, s9, 24
    jal     ra, .Ldma_copy
    addi    s9, s9, NPU_SERVICE_COPY_STRIDE
.Lpublish_completion:

    /*
     * Reaching here proves success: the precise launch pair retired
     * after its matching NPU terminal.  Publish one fixed-size completion.
     */
    sd      s5, NPU_SERVICE_CPL_GENERATION_OFFSET(s6)
    sw      s2, NPU_SERVICE_CPL_INDEX_OFFSET(s6)
    li      t0, NPU_SERVICE_COMPLETION_STATUS_SUCCESS
    sw      t0, NPU_SERVICE_CPL_STATUS_OFFSET(s6)
    ld      t0, 16(s1)  /* descriptor word 2: sequence_id */
    sd      t0, NPU_SERVICE_CPL_SEQUENCE_OFFSET(s6)
    ld      t0, 24(s1)  /* descriptor word 3: macro producer_id */
    sd      t0, NPU_SERVICE_CPL_PRODUCER_OFFSET(s6)
    ld      t0, 32(s1)  /* descriptor word 4: user_tag */
    sd      t0, NPU_SERVICE_CPL_USER_TAG_OFFSET(s6)
    sd      zero, NPU_SERVICE_CPL_FAULT_TVAL_OFFSET(s6)
    sd      zero, NPU_SERVICE_CPL_FAULT_PC_OFFSET(s6)
    sd      zero, NPU_SERVICE_CPL_FAULT_CAUSE_OFFSET(s6)

    addi    s1, s1, NPU_SERVICE_COMMAND_STRIDE
    addi    s6, s6, NPU_SERVICE_COMPLETION_STRIDE
    addi    s2, s2, 1
    fence   rw, w
    sw      s2, NPU_SERVICE_MB_COMPLETED_OFFSET(s0)
    bltu    s2, s3, .Lcommand_begin

.Lbatch_done:
    li      t0, NPU_SERVICE_STATE_DONE
    fence   rw, w
    sw      t0, NPU_SERVICE_MB_STATE_OFFSET(s0)
    j       .Lpoll_ready

/*
 * Byte-preserving RTL DMA; no RV64 or Host tensor arithmetic. The compiler
 * allocates disjoint ranges and Host Runtime validates their capabilities.
 * RV64 configures the device through committed MMIO stores, then polls DONE
 * before issuing the next NPU command or publishing completion.
 */
.Ldma_copy:
    ld      a1, 0(a0)
    ld      a2, 8(a0)
    ld      a3, 16(a0)
    beqz    a3, .Lcopy_return
    li      a4, NPU_SERVICE_DMA_MMIO_ADDRESS
    sd      a1, 0(a4)
    sd      a2, 8(a4)
    sd      a3, 16(a4)
    fence   rw, w
    li      a5, 1
    sd      a5, 24(a4)
.Ldma_poll:
    ld      a5, 32(a4)
    andi    a6, a5, 2
    beqz    a6, .Ldma_poll
    andi    a6, a5, 4
    bnez    a6, .Ldma_error
.Lcopy_return:
    fence   rw, rw
    ret
.Ldma_error:
    li      t0, NPU_SERVICE_ERROR_DMA
    j       .Lpublish_error

.Lbad_flags:
    li      t0, NPU_SERVICE_ERROR_BAD_FLAGS
    j       .Lpublish_error
.Lbad_magic:
    li      t0, NPU_SERVICE_ERROR_BAD_MAGIC
    j       .Lpublish_error
.Lbad_version:
    li      t0, NPU_SERVICE_ERROR_BAD_VERSION
    j       .Lpublish_error
.Lbad_stride:
    li      t0, NPU_SERVICE_ERROR_BAD_STRIDE
    j       .Lpublish_error
.Lbad_count:
    li      t0, NPU_SERVICE_ERROR_BAD_COUNT
    j       .Lpublish_error
.Lbad_command_base:
    li      t0, NPU_SERVICE_ERROR_BAD_COMMAND_BASE
    j       .Lpublish_error
.Lbad_completion_base:
    li      t0, NPU_SERVICE_ERROR_BAD_COMPLETION_BASE
    j       .Lpublish_error
.Lbad_generation:
    li      t0, NPU_SERVICE_ERROR_BAD_GENERATION

.Lpublish_error:
    sw      t0, NPU_SERVICE_MB_ERROR_OFFSET(s0)
    li      t1, NPU_SERVICE_STATE_ERROR
    fence   rw, w
    sw      t1, NPU_SERVICE_MB_STATE_OFFSET(s0)
    j       .Lpoll_ready

    /*
     * Direct-mode machine trap entry.  s8 deliberately remains set while the
     * recovery CONFIG is in flight.  If CONFIG-30 itself faults, the nested
     * entry takes the reset-required path without attempting another clear.
     *
     * NPU-fault mtval v1:
     *   [63]    fatal/reset-required
     *   [62:56] base NPU error code
     *   [55:48] exact CPU ProducerId
     *   [47:40] Tensor opclass
     *   [39]    npu_required
     *   [38]    64-bit logical command
     *   [37:32] format version (1)
     *   [31:0]  logical command low word
     */
    .balign 4
    .globl npu_service_trap_entry
    .type npu_service_trap_entry, @function
npu_service_trap_entry:
    bnez    s8, .Ltrap_untrusted_fatal
    li      s8, 1

    csrr    t0, mcause
    li      t3, NPU_SERVICE_NPU_FAULT_MCAUSE
    bne     t0, t3, .Ltrap_untrusted_fatal

    csrr    t1, mtval
    csrr    t2, mepc
    srli    t3, t1, NPU_SERVICE_NPU_FAULT_VERSION_SHIFT
    andi    t3, t3, NPU_SERVICE_NPU_FAULT_VERSION_MASK
    li      t4, NPU_SERVICE_NPU_FAULT_MTVAL_VERSION
    bne     t3, t4, .Ltrap_untrusted_fatal

    /* A valid fatal report still owns an exact command completion record. */
    mv      s9, t1
    mv      s10, t2
    mv      s11, t0
    bltz    s9, .Ltrap_valid_fatal

    /*
     * This is intentionally not an NPU_CONFIG macro invocation: rs1=x0 and
     * no descriptor value is consumed.  CONFIG-30 completes like an ordinary
     * precise Tensor instruction; execution advances only after clear ack.
     */
    .balign 4
    .globl npu_service_recovery_clear
npu_service_recovery_clear:
    .4byte  NPU_RECOVERY_CLEAR
    .globl npu_service_recovery_clear_end
npu_service_recovery_clear_end:

    li      t3, NPU_SERVICE_ERROR_NPU_FAULT
    li      t4, NPU_SERVICE_COMPLETION_STATUS_NPU_FAULT
    li      t5, 0  /* recoverable: redirect to poll after publication */
    j       .Lpublish_precise_fault

.Ltrap_valid_fatal:
    /* Do not issue CONFIG-30 for a reset-required tagged terminal. */
    li      t3, NPU_SERVICE_ERROR_NPU_FATAL
    li      t4, NPU_SERVICE_COMPLETION_STATUS_NPU_FATAL
    li      t5, 1

.Lpublish_precise_fault:
    /* Publish the failed command exactly once; completed includes this row. */
    sd      s5, NPU_SERVICE_CPL_GENERATION_OFFSET(s6)
    sw      s2, NPU_SERVICE_CPL_INDEX_OFFSET(s6)
    sw      t4, NPU_SERVICE_CPL_STATUS_OFFSET(s6)
    ld      t0, 16(s1)  /* descriptor word 2: sequence_id */
    sd      t0, NPU_SERVICE_CPL_SEQUENCE_OFFSET(s6)
    ld      t0, 24(s1)  /* descriptor word 3: macro producer_id */
    sd      t0, NPU_SERVICE_CPL_PRODUCER_OFFSET(s6)
    ld      t0, 32(s1)  /* descriptor word 4: user_tag */
    sd      t0, NPU_SERVICE_CPL_USER_TAG_OFFSET(s6)
    sd      s9, NPU_SERVICE_CPL_FAULT_TVAL_OFFSET(s6)
    sd      s10, NPU_SERVICE_CPL_FAULT_PC_OFFSET(s6)
    sd      s11, NPU_SERVICE_CPL_FAULT_CAUSE_OFFSET(s6)

    addi    t0, s2, 1
    sw      t0, NPU_SERVICE_MB_COMPLETED_OFFSET(s0)
    sw      t3, NPU_SERVICE_MB_ERROR_OFFSET(s0)
    li      t0, NPU_SERVICE_STATE_ERROR
    fence   rw, w
    sw      t0, NPU_SERVICE_MB_STATE_OFFSET(s0)
    bnez    t5, .Ltrap_fatal_spin

    /* Never re-execute the faulting LO/HI pair. */
    lla     t0, .Lpoll_ready
    csrw    mepc, t0
    li      s8, 0
    mret

.Ltrap_untrusted_fatal:
    /*
     * Covers a wrong cause/version and recovery-clear re-entry.  A valid
     * fatal mtval tag took .Ltrap_valid_fatal and already published its exact
     * completion.  This untrusted path publishes mailbox diagnostics only;
     * ERROR+NPU_FATAL is terminal and reset is the sole exit.
     */
    li      t0, NPU_SERVICE_ERROR_NPU_FATAL
    sw      t0, NPU_SERVICE_MB_ERROR_OFFSET(s0)
    li      t0, NPU_SERVICE_STATE_ERROR
    fence   rw, w
    sw      t0, NPU_SERVICE_MB_STATE_OFFSET(s0)
.Ltrap_fatal_spin:
    j       .Ltrap_fatal_spin

    .size npu_service_trap_entry, . - npu_service_trap_entry

    .size _start, . - _start
