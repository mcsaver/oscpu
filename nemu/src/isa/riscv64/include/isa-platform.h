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

#ifndef __RISCV64_ISA_PLATFORM_H__
#define __RISCV64_ISA_PLATFORM_H__

#include <common.h>
#ifndef CONFIG_TARGET_AM
#include <stdio.h>
#endif

// RV64 平台钩子只声明 RV64 宽度符号；通用层通过 isa_riscv_* 别名访问当前实现。
bool isa_riscv64_clint_in_range(paddr_t addr);
word_t isa_riscv64_clint_read(paddr_t addr, int len);
void isa_riscv64_clint_write(paddr_t addr, int len, word_t data);
uint64_t isa_riscv64_clint_timebase_hz(void);
uint64_t isa_riscv64_mtime_value(void);
const char *isa_riscv64_clint_time_source(void);
#ifndef CONFIG_TARGET_AM
void isa_riscv64_clint_dump_machine_info(FILE *out);
void isa_riscv64_clint_qmp_snapshot(char *out, size_t out_size);
#endif
bool isa_riscv64_plic_in_range(paddr_t addr);
word_t isa_riscv64_plic_read(paddr_t addr, int len);
void isa_riscv64_plic_write(paddr_t addr, int len, word_t data);
void isa_riscv64_plic_reset(void);
void isa_riscv64_plic_set_irq(uint32_t irq, bool level);
bool isa_riscv64_plic_maybe_pending(void);
word_t isa_riscv64_plic_pending_bits(void);
void isa_riscv64_plic_statistic(void);
#ifndef CONFIG_TARGET_AM
void isa_riscv64_plic_dump_machine_info(FILE *out);
void isa_riscv64_plic_qmp_snapshot(char *out, size_t out_size);
#endif
void isa_riscv64_post_exec(void);
void isa_riscv64_reset(void);
void isa_riscv64_restart(void);
void isa_riscv64_mmu_tlb_flush(void);
void isa_riscv64_mmu_tlb_flush_selective(vaddr_t vaddr, bool flush_vaddr,
    word_t asid, bool flush_asid);
extern bool isa_riscv64_decode_cache_is_enabled;
extern bool isa_riscv64_decode_cache_rvc_fast_is_enabled;
extern bool isa_riscv64_decode_cache_int_fast_is_enabled;

static inline bool isa_riscv64_decode_cache_runtime_enabled(void) {
  return likely(isa_riscv64_decode_cache_is_enabled);
}

static inline bool isa_riscv64_decode_cache_rvc_fast_runtime_enabled(void) {
  return likely(isa_riscv64_decode_cache_rvc_fast_is_enabled);
}

static inline bool isa_riscv64_decode_cache_int_fast_runtime_enabled(void) {
  return likely(isa_riscv64_decode_cache_int_fast_is_enabled);
}

word_t isa_riscv64_mmu_fault_cause(int type);
bool isa_riscv64_pmp_check(paddr_t paddr, int len, int type);
bool isa_riscv64_pmp_check_as_priv(paddr_t paddr, int len, int type, uint8_t priv);
void isa_riscv64_pmp_mark_dirty(void);
#ifndef CONFIG_TARGET_AM
void isa_riscv64_pmp_dump_machine_info(FILE *out);
#endif
bool isa_mmu_translate_host(vaddr_t vaddr, int len, int type,
    paddr_t *paddr, uint8_t **host_addr);
bool isa_riscv64_mmu_debug_translate_user(vaddr_t vaddr, int len, int type,
    paddr_t *paddr);
void isa_riscv64_lr_sc_invalidate(paddr_t paddr, int len);
void isa_riscv64_wfi(void);

word_t isa_riscv64_mip_value(void);
bool isa_riscv64_intr_pending_fast(void);
void isa_riscv64_write_mie(word_t value);
void isa_riscv64_write_mip(word_t value);
void isa_riscv64_write_mcycle_lo(word_t value);
void isa_riscv64_write_mcycle_hi(word_t value);
void isa_riscv64_raise_timer_intr(void);
bool isa_riscv64_last_sstatus_write_was_unchanged(void);
bool isa_riscv64_last_sstatus_write_only_cleared_sie(void);
bool isa_riscv64_last_sstatus_write_delta(word_t *old_status,
    word_t *new_status, word_t *delta);

#define isa_riscv_clint_in_range isa_riscv64_clint_in_range
#define isa_riscv_clint_read isa_riscv64_clint_read
#define isa_riscv_clint_write isa_riscv64_clint_write
#define isa_riscv_clint_timebase_hz isa_riscv64_clint_timebase_hz
#define isa_riscv_mtime_value isa_riscv64_mtime_value
#define isa_riscv_clint_time_source isa_riscv64_clint_time_source
#ifndef CONFIG_TARGET_AM
#define isa_riscv_clint_dump_machine_info isa_riscv64_clint_dump_machine_info
#define isa_riscv_clint_qmp_snapshot isa_riscv64_clint_qmp_snapshot
#endif
#define isa_riscv_plic_in_range isa_riscv64_plic_in_range
#define isa_riscv_plic_read isa_riscv64_plic_read
#define isa_riscv_plic_write isa_riscv64_plic_write
#define isa_riscv_plic_reset isa_riscv64_plic_reset
#define isa_riscv_plic_set_irq isa_riscv64_plic_set_irq
#define isa_riscv_plic_maybe_pending isa_riscv64_plic_maybe_pending
#define isa_riscv_plic_pending_bits isa_riscv64_plic_pending_bits
#define isa_riscv_plic_statistic isa_riscv64_plic_statistic
#ifndef CONFIG_TARGET_AM
#define isa_riscv_plic_dump_machine_info isa_riscv64_plic_dump_machine_info
#define isa_riscv_plic_qmp_snapshot isa_riscv64_plic_qmp_snapshot
#endif
#define isa_riscv_post_exec isa_riscv64_post_exec
#define isa_riscv_reset isa_riscv64_reset
#define isa_riscv_restart isa_riscv64_restart
#define isa_riscv_mmu_tlb_flush isa_riscv64_mmu_tlb_flush
#define isa_riscv_mmu_tlb_flush_selective isa_riscv64_mmu_tlb_flush_selective
#define isa_riscv_decode_cache_runtime_enabled isa_riscv64_decode_cache_runtime_enabled
#define isa_riscv_decode_cache_rvc_fast_runtime_enabled isa_riscv64_decode_cache_rvc_fast_runtime_enabled
#define isa_riscv_decode_cache_int_fast_runtime_enabled isa_riscv64_decode_cache_int_fast_runtime_enabled
#define isa_riscv_mmu_fault_cause isa_riscv64_mmu_fault_cause
#define isa_riscv_pmp_check isa_riscv64_pmp_check
#ifndef CONFIG_TARGET_AM
#define isa_riscv_pmp_dump_machine_info isa_riscv64_pmp_dump_machine_info
#endif
#define isa_riscv_lr_sc_invalidate isa_riscv64_lr_sc_invalidate
#define isa_riscv_wfi isa_riscv64_wfi
#define isa_riscv_mip_value isa_riscv64_mip_value
#define isa_riscv_intr_pending_fast isa_riscv64_intr_pending_fast
#define isa_riscv_write_mie isa_riscv64_write_mie
#define isa_riscv_write_mip isa_riscv64_write_mip
#define isa_riscv_write_mcycle_lo isa_riscv64_write_mcycle_lo
#define isa_riscv_write_mcycle_hi isa_riscv64_write_mcycle_hi
#define isa_riscv_raise_timer_intr isa_riscv64_raise_timer_intr
#define isa_riscv_last_sstatus_write_was_unchanged isa_riscv64_last_sstatus_write_was_unchanged
#define isa_riscv_last_sstatus_write_only_cleared_sie isa_riscv64_last_sstatus_write_only_cleared_sie
#define isa_riscv_last_sstatus_write_delta isa_riscv64_last_sstatus_write_delta

#endif
