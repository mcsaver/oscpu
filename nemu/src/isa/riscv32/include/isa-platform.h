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

#ifndef __RISCV32_ISA_PLATFORM_H__
#define __RISCV32_ISA_PLATFORM_H__

#include <common.h>

// RV32 平台钩子保留 RV32 宽度符号；通用层通过 isa_riscv_* 别名访问当前实现。
bool isa_riscv32_clint_in_range(paddr_t addr);
word_t isa_riscv32_clint_read(paddr_t addr, int len);
void isa_riscv32_clint_write(paddr_t addr, int len, word_t data);
uint64_t isa_riscv32_clint_timebase_hz(void);
uint64_t isa_riscv32_mtime_value(void);
const char *isa_riscv32_clint_time_source(void);
bool isa_riscv32_plic_in_range(paddr_t addr);
bool isa_riscv32_plic_access_valid(paddr_t addr, int len);
word_t isa_riscv32_plic_read(paddr_t addr, int len);
void isa_riscv32_plic_write(paddr_t addr, int len, word_t data);
void isa_riscv32_plic_reset(void);
void isa_riscv32_plic_set_irq(uint32_t irq, bool level);
bool isa_riscv32_plic_maybe_pending(void);
word_t isa_riscv32_plic_pending_bits(void);
void isa_riscv32_plic_statistic(void);
void isa_riscv32_post_exec(void);
void isa_riscv32_reset(void);
void isa_riscv32_restart(void);
void isa_riscv32_mmu_tlb_flush(void);
void isa_riscv32_mmu_tlb_flush_selective(vaddr_t vaddr, bool flush_vaddr,
    word_t asid, bool flush_asid);
word_t isa_riscv32_mmu_fault_cause(int type);
bool isa_riscv32_pmp_check(paddr_t paddr, int len, int type);
void isa_riscv32_lr_sc_invalidate(paddr_t paddr, int len);
void isa_riscv32_wfi(void);

word_t isa_riscv32_mip_value(void);
bool isa_riscv32_intr_pending_fast(void);
void isa_riscv32_write_mie(word_t value);
void isa_riscv32_write_mip(word_t value);
void isa_riscv32_write_mcycle_lo(word_t value);
void isa_riscv32_write_mcycle_hi(word_t value);
void isa_riscv32_raise_timer_intr(void);

#define isa_riscv_clint_in_range isa_riscv32_clint_in_range
#define isa_riscv_clint_read isa_riscv32_clint_read
#define isa_riscv_clint_write isa_riscv32_clint_write
#define isa_riscv_clint_timebase_hz isa_riscv32_clint_timebase_hz
#define isa_riscv_mtime_value isa_riscv32_mtime_value
#define isa_riscv_clint_time_source isa_riscv32_clint_time_source
#define isa_riscv_plic_in_range isa_riscv32_plic_in_range
#define isa_riscv_plic_access_valid isa_riscv32_plic_access_valid
#define isa_riscv_plic_read isa_riscv32_plic_read
#define isa_riscv_plic_write isa_riscv32_plic_write
#define isa_riscv_plic_reset isa_riscv32_plic_reset
#define isa_riscv_plic_set_irq isa_riscv32_plic_set_irq
#define isa_riscv_plic_maybe_pending isa_riscv32_plic_maybe_pending
#define isa_riscv_plic_pending_bits isa_riscv32_plic_pending_bits
#define isa_riscv_plic_statistic isa_riscv32_plic_statistic
#define isa_riscv_post_exec isa_riscv32_post_exec
#define isa_riscv_reset isa_riscv32_reset
#define isa_riscv_restart isa_riscv32_restart
#define isa_riscv_mmu_tlb_flush isa_riscv32_mmu_tlb_flush
#define isa_riscv_mmu_tlb_flush_selective isa_riscv32_mmu_tlb_flush_selective
#define isa_riscv_mmu_fault_cause isa_riscv32_mmu_fault_cause
#define isa_riscv_pmp_check isa_riscv32_pmp_check
#define isa_riscv_lr_sc_invalidate isa_riscv32_lr_sc_invalidate
#define isa_riscv_wfi isa_riscv32_wfi
#define isa_riscv_mip_value isa_riscv32_mip_value
#define isa_riscv_intr_pending_fast isa_riscv32_intr_pending_fast
#define isa_riscv_write_mie isa_riscv32_write_mie
#define isa_riscv_write_mip isa_riscv32_write_mip
#define isa_riscv_write_mcycle_lo isa_riscv32_write_mcycle_lo
#define isa_riscv_write_mcycle_hi isa_riscv32_write_mcycle_hi
#define isa_riscv_raise_timer_intr isa_riscv32_raise_timer_intr

#endif
