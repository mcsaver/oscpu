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

#include <utils/profile.h>
#ifndef CONFIG_TARGET_AM
#include <stdlib.h>
#include <string.h>
#endif

uint64_t nemu_profile_counters[NEMU_PROFILE_COUNTER__COUNT];
bool nemu_profile_is_enabled = false;
bool nemu_profile_opcode_mix_is_enabled = false;
bool nemu_profile_stop_detail_is_enabled = false;
bool nemu_profile_decode_cache_is_enabled = false;
bool nemu_profile_rvc_detail_is_enabled = false;

static const char *profile_counter_names[NEMU_PROFILE_COUNTER__COUNT] = {
  [NEMU_PROFILE_CPU_EXEC_WINDOWS] = "cpu.exec_windows",
  [NEMU_PROFILE_CPU_EXEC_US] = "cpu.exec_us",
  [NEMU_PROFILE_CPU_BASIC_BLOCKS] = "cpu.basic_blocks",
  [NEMU_PROFILE_CPU_BASIC_BLOCK_INST] = "cpu.basic_block_inst",
  [NEMU_PROFILE_CPU_SINGLE_STEPS] = "cpu.single_steps",
  [NEMU_PROFILE_CPU_TB_STOP_STATE] = "cpu.tb_stop_state",
  [NEMU_PROFILE_CPU_TB_STOP_CONTROL] = "cpu.tb_stop_control",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM] = "cpu.tb_stop_system",
  [NEMU_PROFILE_CPU_TB_STOP_MEMORY_ORDER] = "cpu.tb_stop_memory_order",
  [NEMU_PROFILE_CPU_TB_STOP_IO_WRITE] = "cpu.tb_stop_io_write",
  [NEMU_PROFILE_CPU_TB_STOP_STORE_CONSERVATIVE] = "cpu.tb_stop_store_conservative",
  [NEMU_PROFILE_CPU_TB_STOP_LIMIT] = "cpu.tb_stop_limit",
  [NEMU_PROFILE_CPU_TB_STOP_CONTROL_FALLBACK] = "cpu.tb_stop_control_fallback",
  [NEMU_PROFILE_CPU_TB_CONTINUE_BRANCH_TAKEN] = "cpu.tb_continue_branch_taken",
  [NEMU_PROFILE_CPU_TB_CONTINUE_BRANCH_NOT_TAKEN] = "cpu.tb_continue_branch_not_taken",
  [NEMU_PROFILE_CPU_TB_CONTINUE_JUMP_DIRECT] = "cpu.tb_continue_jump_direct",
  [NEMU_PROFILE_CPU_TB_CONTINUE_JALR] = "cpu.tb_continue_jalr",
  [NEMU_PROFILE_CPU_TB_CONTINUE_COMPRESSED_MISC] = "cpu.tb_continue_compressed_misc",
  [NEMU_PROFILE_CPU_TB_CONTINUE_FENCE] = "cpu.tb_continue_fence",
  [NEMU_PROFILE_CPU_TB_CONTINUE_CSR_READONLY] = "cpu.tb_continue_csr_readonly",
  [NEMU_PROFILE_CPU_TB_CONTINUE_AMO] = "cpu.tb_continue_amo",
  [NEMU_PROFILE_CPU_TB_CONTINUE_AMO_LR] = "cpu.tb_continue_amo.lr",
  [NEMU_PROFILE_CPU_TB_CONTINUE_AMO_SC] = "cpu.tb_continue_amo.sc",
  [NEMU_PROFILE_CPU_TB_CONTINUE_AMO_SWAP] = "cpu.tb_continue_amo.swap",
  [NEMU_PROFILE_CPU_TB_CONTINUE_AMO_ADD] = "cpu.tb_continue_amo.add",
  [NEMU_PROFILE_CPU_TB_CONTINUE_AMO_OTHER] = "cpu.tb_continue_amo.other",
  [NEMU_PROFILE_CPU_TB_STOP_FENCE_I] = "cpu.tb_stop_fence_i",
  [NEMU_PROFILE_CPU_TB_STOP_AMO] = "cpu.tb_stop_amo",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR] = "cpu.tb_stop_system_csr",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_WFI] = "cpu.tb_stop_system_wfi",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_SFENCE_VMA] = "cpu.tb_stop_system_sfence_vma",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_OTHER] = "cpu.tb_stop_system_other",
  [NEMU_PROFILE_CPU_TB_STOP_AMO_LR] = "cpu.tb_stop_amo.lr",
  [NEMU_PROFILE_CPU_TB_STOP_AMO_SC] = "cpu.tb_stop_amo.sc",
  [NEMU_PROFILE_CPU_TB_STOP_AMO_SWAP] = "cpu.tb_stop_amo.swap",
  [NEMU_PROFILE_CPU_TB_STOP_AMO_ADD] = "cpu.tb_stop_amo.add",
  [NEMU_PROFILE_CPU_TB_STOP_AMO_OTHER] = "cpu.tb_stop_amo.other",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSTATUS] = "cpu.tb_stop_system_csr.sstatus",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SIE] = "cpu.tb_stop_system_csr.sie",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_STVEC] = "cpu.tb_stop_system_csr.stvec",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SSCRATCH] = "cpu.tb_stop_system_csr.sscratch",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SEPC] = "cpu.tb_stop_system_csr.sepc",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SCAUSE] = "cpu.tb_stop_system_csr.scause",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_STVAL] = "cpu.tb_stop_system_csr.stval",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SIP] = "cpu.tb_stop_system_csr.sip",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_SATP] = "cpu.tb_stop_system_csr.satp",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MSTATUS] = "cpu.tb_stop_system_csr.mstatus",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MIE] = "cpu.tb_stop_system_csr.mie",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MTVEC] = "cpu.tb_stop_system_csr.mtvec",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MSCRATCH] = "cpu.tb_stop_system_csr.mscratch",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MEPC] = "cpu.tb_stop_system_csr.mepc",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MCAUSE] = "cpu.tb_stop_system_csr.mcause",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MTVAL] = "cpu.tb_stop_system_csr.mtval",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MIP] = "cpu.tb_stop_system_csr.mip",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MEDELEG] = "cpu.tb_stop_system_csr.medeleg",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MIDELEG] = "cpu.tb_stop_system_csr.mideleg",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_MCOUNTEREN] = "cpu.tb_stop_system_csr.mcounteren",
  [NEMU_PROFILE_CPU_TB_STOP_SYSTEM_CSR_OTHER] = "cpu.tb_stop_system_csr.other",
  [NEMU_PROFILE_CPU_STOP_DETAIL_ENABLED] = "cpu.stop_detail.enabled",
  [NEMU_PROFILE_CPU_OPCODE_MIX_ENABLED] = "cpu.opcode_mix.enabled",
  [NEMU_PROFILE_CPU_OPCODE_RVC] = "cpu.opcode.rvc",
  [NEMU_PROFILE_CPU_OPCODE_LOAD] = "cpu.opcode.load",
  [NEMU_PROFILE_CPU_OPCODE_LOAD_FP] = "cpu.opcode.load_fp",
  [NEMU_PROFILE_CPU_OPCODE_MISC_MEM] = "cpu.opcode.misc_mem",
  [NEMU_PROFILE_CPU_OPCODE_OP_IMM] = "cpu.opcode.op_imm",
  [NEMU_PROFILE_CPU_OPCODE_OP_IMM_32] = "cpu.opcode.op_imm_32",
  [NEMU_PROFILE_CPU_OPCODE_AUIPC] = "cpu.opcode.auipc",
  [NEMU_PROFILE_CPU_OPCODE_STORE] = "cpu.opcode.store",
  [NEMU_PROFILE_CPU_OPCODE_STORE_FP] = "cpu.opcode.store_fp",
  [NEMU_PROFILE_CPU_OPCODE_AMO] = "cpu.opcode.amo",
  [NEMU_PROFILE_CPU_OPCODE_OP] = "cpu.opcode.op",
  [NEMU_PROFILE_CPU_OPCODE_OP_32] = "cpu.opcode.op_32",
  [NEMU_PROFILE_CPU_OPCODE_FP] = "cpu.opcode.fp",
  [NEMU_PROFILE_CPU_OPCODE_BRANCH] = "cpu.opcode.branch",
  [NEMU_PROFILE_CPU_OPCODE_JALR] = "cpu.opcode.jalr",
  [NEMU_PROFILE_CPU_OPCODE_JAL] = "cpu.opcode.jal",
  [NEMU_PROFILE_CPU_OPCODE_LUI] = "cpu.opcode.lui",
  [NEMU_PROFILE_CPU_OPCODE_SYSTEM] = "cpu.opcode.system",
  [NEMU_PROFILE_CPU_OPCODE_OTHER] = "cpu.opcode.other",
  [NEMU_PROFILE_CPU_DECODE_CACHE_LOOKUPS] = "cpu.decode_cache.lookups",
  [NEMU_PROFILE_CPU_DECODE_CACHE_HITS] = "cpu.decode_cache.hits",
  [NEMU_PROFILE_CPU_DECODE_CACHE_MISSES] = "cpu.decode_cache.misses",
  [NEMU_PROFILE_CPU_DECODE_CACHE_FILLS] = "cpu.decode_cache.fills",
  [NEMU_PROFILE_CPU_DECODE_CACHE_HIT_RVC] = "cpu.decode_cache.hit_rvc",
  [NEMU_PROFILE_CPU_DECODE_CACHE_FILL_RVC] = "cpu.decode_cache.fill_rvc",
  [NEMU_PROFILE_CPU_RVC_DETAIL_ENABLED] = "cpu.rvc_detail.enabled",
  [NEMU_PROFILE_CPU_RVC_ADDI4SPN] = "cpu.rvc.addi4spn",
  [NEMU_PROFILE_CPU_RVC_FLD] = "cpu.rvc.fld",
  [NEMU_PROFILE_CPU_RVC_LW] = "cpu.rvc.lw",
  [NEMU_PROFILE_CPU_RVC_LD] = "cpu.rvc.ld",
  [NEMU_PROFILE_CPU_RVC_FSD] = "cpu.rvc.fsd",
  [NEMU_PROFILE_CPU_RVC_SW] = "cpu.rvc.sw",
  [NEMU_PROFILE_CPU_RVC_SD] = "cpu.rvc.sd",
  [NEMU_PROFILE_CPU_RVC_ADDI] = "cpu.rvc.addi",
  [NEMU_PROFILE_CPU_RVC_ADDIW] = "cpu.rvc.addiw",
  [NEMU_PROFILE_CPU_RVC_LI] = "cpu.rvc.li",
  [NEMU_PROFILE_CPU_RVC_ADDI16SP] = "cpu.rvc.addi16sp",
  [NEMU_PROFILE_CPU_RVC_LUI] = "cpu.rvc.lui",
  [NEMU_PROFILE_CPU_RVC_SRLI] = "cpu.rvc.srli",
  [NEMU_PROFILE_CPU_RVC_SRAI] = "cpu.rvc.srai",
  [NEMU_PROFILE_CPU_RVC_ANDI] = "cpu.rvc.andi",
  [NEMU_PROFILE_CPU_RVC_SUB] = "cpu.rvc.sub",
  [NEMU_PROFILE_CPU_RVC_XOR] = "cpu.rvc.xor",
  [NEMU_PROFILE_CPU_RVC_OR] = "cpu.rvc.or",
  [NEMU_PROFILE_CPU_RVC_AND] = "cpu.rvc.and",
  [NEMU_PROFILE_CPU_RVC_SUBW] = "cpu.rvc.subw",
  [NEMU_PROFILE_CPU_RVC_ADDW] = "cpu.rvc.addw",
  [NEMU_PROFILE_CPU_RVC_J] = "cpu.rvc.j",
  [NEMU_PROFILE_CPU_RVC_BEQZ] = "cpu.rvc.beqz",
  [NEMU_PROFILE_CPU_RVC_BNEZ] = "cpu.rvc.bnez",
  [NEMU_PROFILE_CPU_RVC_SLLI] = "cpu.rvc.slli",
  [NEMU_PROFILE_CPU_RVC_FLDSP] = "cpu.rvc.fldsp",
  [NEMU_PROFILE_CPU_RVC_LWSP] = "cpu.rvc.lwsp",
  [NEMU_PROFILE_CPU_RVC_LDSP] = "cpu.rvc.ldsp",
  [NEMU_PROFILE_CPU_RVC_JR] = "cpu.rvc.jr",
  [NEMU_PROFILE_CPU_RVC_MV] = "cpu.rvc.mv",
  [NEMU_PROFILE_CPU_RVC_EBREAK] = "cpu.rvc.ebreak",
  [NEMU_PROFILE_CPU_RVC_JALR] = "cpu.rvc.jalr",
  [NEMU_PROFILE_CPU_RVC_ADD] = "cpu.rvc.add",
  [NEMU_PROFILE_CPU_RVC_FSDSP] = "cpu.rvc.fsdsp",
  [NEMU_PROFILE_CPU_RVC_SWSP] = "cpu.rvc.swsp",
  [NEMU_PROFILE_CPU_RVC_SDSP] = "cpu.rvc.sdsp",
  [NEMU_PROFILE_CPU_RVC_OTHER] = "cpu.rvc.other",

  [NEMU_PROFILE_DEVICE_UPDATE_CALLS] = "device.update_calls",
  [NEMU_PROFILE_DEVICE_UPDATE_RETIRED] = "device.update_retired",
  [NEMU_PROFILE_DEVICE_INTERVAL_SKIPS] = "device.interval_skips",
  [NEMU_PROFILE_DEVICE_INTERVAL_FIRES] = "device.interval_fires",
  [NEMU_PROFILE_DEVICE_TIME_SKIPS] = "device.time_skips",
  [NEMU_PROFILE_DEVICE_VISIBLE_TICKS] = "device.visible_ticks",
  [NEMU_PROFILE_DEVICE_INTERVAL_US] = "device.interval_us",
  [NEMU_PROFILE_DEVICE_VIRTIO_BLK_US] = "device.virtio_blk_us",
  [NEMU_PROFILE_DEVICE_VISIBLE_US] = "device.visible_us",

  [NEMU_PROFILE_CLINT_HOST_TIME_READS] = "clint.host_time_reads",

  [NEMU_PROFILE_SERIAL_TX_FLUSHES] = "serial.tx_flushes",
  [NEMU_PROFILE_SERIAL_TX_BYTES] = "serial.tx_bytes",
  [NEMU_PROFILE_SERIAL_TX_FLUSH_US] = "serial.tx_flush_us",
  [NEMU_PROFILE_SERIAL_RX_POLLS] = "serial.rx_polls",
  [NEMU_PROFILE_SERIAL_RX_BYTES] = "serial.rx_bytes",

  [NEMU_PROFILE_VADDR_IFETCH_CALLS] = "vaddr.ifetch_calls",
  [NEMU_PROFILE_VADDR_IFETCH_WIDE_ATTEMPTS] = "vaddr.ifetch_wide_attempts",
  [NEMU_PROFILE_VADDR_IFETCH_WIDE_HITS] = "vaddr.ifetch_wide_hits",
  [NEMU_PROFILE_VADDR_IFETCH_WIDE_DISABLED] = "vaddr.ifetch_wide_disabled",
  [NEMU_PROFILE_VADDR_IFETCH_WIDE_CROSS_PAGE] = "vaddr.ifetch_wide_cross_page",
  [NEMU_PROFILE_VADDR_IFETCH_WIDE_FAULTS] = "vaddr.ifetch_wide_faults",
  [NEMU_PROFILE_VADDR_IFETCH_WIDE_PADDR_FALLBACKS] = "vaddr.ifetch_wide_paddr_fallbacks",
  [NEMU_PROFILE_VADDR_IFETCH_CACHE_HITS] = "vaddr.ifetch_cache_hits",
  [NEMU_PROFILE_VADDR_IFETCH_CACHE_MISSES] = "vaddr.ifetch_cache_misses",
  [NEMU_PROFILE_VADDR_IFETCH_CACHE_FILLS] = "vaddr.ifetch_cache_fills",
  [NEMU_PROFILE_VADDR_IFETCH_CACHE_FLUSHES] = "vaddr.ifetch_cache_flushes",
  [NEMU_PROFILE_VADDR_IFETCH_CACHE_INVALIDATES] = "vaddr.ifetch_cache_invalidates",
  [NEMU_PROFILE_VADDR_CROSS_PAGE_READS] = "vaddr.cross_page_reads",
  [NEMU_PROFILE_VADDR_CROSS_PAGE_WRITES] = "vaddr.cross_page_writes",
  [NEMU_PROFILE_VADDR_HOST_FAST_READS] = "vaddr.host_fast_reads",
  [NEMU_PROFILE_VADDR_HOST_FAST_WRITES] = "vaddr.host_fast_writes",
  [NEMU_PROFILE_VADDR_PADDR_FALLBACK_READS] = "vaddr.paddr_fallback_reads",
  [NEMU_PROFILE_VADDR_PADDR_FALLBACK_WRITES] = "vaddr.paddr_fallback_writes",
  [NEMU_PROFILE_VADDR_FAULTS] = "vaddr.faults",

  [NEMU_PROFILE_MMU_TLB_DISABLED] = "mmu.tlb_disabled",
  [NEMU_PROFILE_MMU_TLB_LOOKUPS] = "mmu.tlb_lookups",
  [NEMU_PROFILE_MMU_TLB_HITS] = "mmu.tlb_hits",
  [NEMU_PROFILE_MMU_TLB_MISSES] = "mmu.tlb_misses",
  [NEMU_PROFILE_MMU_TLB_FILLS] = "mmu.tlb_fills",
  [NEMU_PROFILE_MMU_TLB_FLUSH_FULL] = "mmu.tlb_flush_full",
  [NEMU_PROFILE_MMU_TLB_FLUSH_SELECTIVE] = "mmu.tlb_flush_selective",
  [NEMU_PROFILE_MMU_WALKS] = "mmu.walks",
  [NEMU_PROFILE_MMU_PTE_READS] = "mmu.pte_reads",
  [NEMU_PROFILE_MMU_PTE_UPDATES] = "mmu.pte_updates",
  [NEMU_PROFILE_MMU_FAULTS] = "mmu.faults",

  [NEMU_PROFILE_PADDR_PMEM_READS] = "paddr.pmem_reads",
  [NEMU_PROFILE_PADDR_PMEM_READ_BYTES] = "paddr.pmem_read_bytes",
  [NEMU_PROFILE_PADDR_PMEM_WRITES] = "paddr.pmem_writes",
  [NEMU_PROFILE_PADDR_PMEM_WRITE_BYTES] = "paddr.pmem_write_bytes",
  [NEMU_PROFILE_PADDR_CLINT_READS] = "paddr.clint_reads",
  [NEMU_PROFILE_PADDR_CLINT_WRITES] = "paddr.clint_writes",
  [NEMU_PROFILE_PADDR_PLIC_READS] = "paddr.plic_reads",
  [NEMU_PROFILE_PADDR_PLIC_WRITES] = "paddr.plic_writes",
  [NEMU_PROFILE_PADDR_MMIO_READS] = "paddr.mmio_reads",
  [NEMU_PROFILE_PADDR_MMIO_WRITES] = "paddr.mmio_writes",
  [NEMU_PROFILE_PADDR_DMA_WRITES] = "paddr.dma_writes",
  [NEMU_PROFILE_PADDR_DMA_WRITE_BYTES] = "paddr.dma_write_bytes",
};

#ifndef CONFIG_TARGET_AM
static void nemu_profile_init(void) {
  const char *env = getenv("NEMU_PROFILE");
  nemu_profile_is_enabled =
    env != NULL && env[0] != '\0' && strcmp(env, "0") != 0;
  env = getenv("NEMU_PROFILE_OPCODE_MIX");
  nemu_profile_opcode_mix_is_enabled =
    nemu_profile_is_enabled &&
    env != NULL && env[0] != '\0' && strcmp(env, "0") != 0;
  env = getenv("NEMU_PROFILE_STOP_DETAIL");
  nemu_profile_stop_detail_is_enabled =
    nemu_profile_is_enabled &&
    env != NULL && env[0] != '\0' && strcmp(env, "0") != 0;
  env = getenv("NEMU_PROFILE_DECODE_CACHE");
  nemu_profile_decode_cache_is_enabled =
    nemu_profile_is_enabled &&
    env != NULL && env[0] != '\0' && strcmp(env, "0") != 0;
  env = getenv("NEMU_PROFILE_RVC_DETAIL");
  nemu_profile_rvc_detail_is_enabled =
    nemu_profile_is_enabled &&
    env != NULL && env[0] != '\0' && strcmp(env, "0") != 0;
  if (nemu_profile_opcode_mix_is_enabled) {
    nemu_profile_counters[NEMU_PROFILE_CPU_OPCODE_MIX_ENABLED] = 1;
  }
  if (nemu_profile_stop_detail_is_enabled) {
    nemu_profile_counters[NEMU_PROFILE_CPU_STOP_DETAIL_ENABLED] = 1;
  }
  if (nemu_profile_rvc_detail_is_enabled) {
    nemu_profile_counters[NEMU_PROFILE_CPU_RVC_DETAIL_ENABLED] = 1;
  }
}

__attribute__((constructor))
static void nemu_profile_constructor(void) {
  nemu_profile_init();
}
#endif

static uint64_t profile_rate_per_sec(uint64_t numerator, uint64_t us) {
  return us == 0 ? 0 : numerator * 1000000ull / us;
}

static uint64_t profile_percent_x100(uint64_t numerator, uint64_t denominator) {
  return denominator == 0 ? 0 : numerator * 10000ull / denominator;
}

static uint64_t profile_average_x100(uint64_t numerator, uint64_t denominator) {
  return denominator == 0 ? 0 : numerator * 100ull / denominator;
}

static void profile_log_percent(const char *name, uint64_t numerator,
    uint64_t denominator) {
  Log("profile.%s_x100=%" PRIu64, name, profile_percent_x100(numerator, denominator));
}

static void profile_log_average(const char *name, uint64_t numerator,
    uint64_t denominator) {
  Log("profile.%s_x100=%" PRIu64, name, profile_average_x100(numerator, denominator));
}

void nemu_profile_dump(uint64_t guest_inst, uint64_t total_exec_us) {
  if (!nemu_profile_enabled()) {
    return;
  }

  Log("profile.enabled=1");
  Log("profile.guest_inst=%" PRIu64, guest_inst);
  Log("profile.total_exec_us=%" PRIu64, total_exec_us);
  Log("profile.inst_per_sec=%" PRIu64,
      profile_rate_per_sec(guest_inst, total_exec_us));

  for (int i = 0; i < NEMU_PROFILE_COUNTER__COUNT; i++) {
    if (profile_counter_names[i] == NULL) {
      continue;
    }
    Log("profile.%s=%" PRIu64, profile_counter_names[i], nemu_profile_counters[i]);
  }

  profile_log_average("cpu.basic_block_avg_inst",
      nemu_profile_counters[NEMU_PROFILE_CPU_BASIC_BLOCK_INST],
      nemu_profile_counters[NEMU_PROFILE_CPU_BASIC_BLOCKS]);
  profile_log_percent("device.visible_tick_rate",
      nemu_profile_counters[NEMU_PROFILE_DEVICE_VISIBLE_TICKS],
      nemu_profile_counters[NEMU_PROFILE_DEVICE_INTERVAL_FIRES]);
  profile_log_average("serial.tx_bytes_per_flush",
      nemu_profile_counters[NEMU_PROFILE_SERIAL_TX_BYTES],
      nemu_profile_counters[NEMU_PROFILE_SERIAL_TX_FLUSHES]);
  profile_log_percent("vaddr.ifetch_wide_hit_rate",
      nemu_profile_counters[NEMU_PROFILE_VADDR_IFETCH_WIDE_HITS],
      nemu_profile_counters[NEMU_PROFILE_VADDR_IFETCH_WIDE_ATTEMPTS]);
  profile_log_percent("vaddr.ifetch_cache_hit_rate",
      nemu_profile_counters[NEMU_PROFILE_VADDR_IFETCH_CACHE_HITS],
      nemu_profile_counters[NEMU_PROFILE_VADDR_IFETCH_CACHE_HITS] +
      nemu_profile_counters[NEMU_PROFILE_VADDR_IFETCH_CACHE_MISSES]);
  profile_log_percent("vaddr.host_fast_read_rate",
      nemu_profile_counters[NEMU_PROFILE_VADDR_HOST_FAST_READS],
      nemu_profile_counters[NEMU_PROFILE_VADDR_HOST_FAST_READS] +
      nemu_profile_counters[NEMU_PROFILE_VADDR_PADDR_FALLBACK_READS]);
  profile_log_percent("vaddr.host_fast_write_rate",
      nemu_profile_counters[NEMU_PROFILE_VADDR_HOST_FAST_WRITES],
      nemu_profile_counters[NEMU_PROFILE_VADDR_HOST_FAST_WRITES] +
      nemu_profile_counters[NEMU_PROFILE_VADDR_PADDR_FALLBACK_WRITES]);
  profile_log_percent("mmu.tlb_hit_rate",
      nemu_profile_counters[NEMU_PROFILE_MMU_TLB_HITS],
      nemu_profile_counters[NEMU_PROFILE_MMU_TLB_LOOKUPS]);
  profile_log_percent("paddr.mmio_read_rate",
      nemu_profile_counters[NEMU_PROFILE_PADDR_MMIO_READS],
      nemu_profile_counters[NEMU_PROFILE_PADDR_PMEM_READS] +
      nemu_profile_counters[NEMU_PROFILE_PADDR_CLINT_READS] +
      nemu_profile_counters[NEMU_PROFILE_PADDR_PLIC_READS] +
      nemu_profile_counters[NEMU_PROFILE_PADDR_MMIO_READS]);
}
