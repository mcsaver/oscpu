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

#ifndef __ISA_H__
#define __ISA_H__

// Located at src/isa/$(GUEST_ISA)/include/isa-def.h
#include <isa-def.h>

// The macro `__GUEST_ISA__` is defined in $(CFLAGS).
// It will be expanded as "x86" or "mips32" ...
typedef concat(__GUEST_ISA__, _CPU_state) CPU_state;
typedef concat(__GUEST_ISA__, _ISADecodeInfo) ISADecodeInfo;

// monitor
extern unsigned char isa_logo[];
void init_isa();

// reg
extern CPU_state cpu;
void isa_reg_display();
word_t isa_reg_str2val(const char *name, bool *success);

// exec
struct Decode;
int isa_exec_once(struct Decode *s);

// memory
enum { MMU_DIRECT, MMU_TRANSLATE, MMU_FAIL };
enum { MEM_TYPE_IFETCH, MEM_TYPE_READ, MEM_TYPE_WRITE };
enum { MEM_RET_OK, MEM_RET_FAIL, MEM_RET_CROSS_PAGE };
#ifndef isa_mmu_check
int isa_mmu_check(vaddr_t vaddr, int len, int type);
#endif
paddr_t isa_mmu_translate(vaddr_t vaddr, int len, int type);

// interrupt/exception
vaddr_t isa_raise_intr(word_t NO, vaddr_t epc);
#ifdef CONFIG_ISA_riscv
vaddr_t isa_raise_intr_with_tval(word_t NO, vaddr_t epc, word_t tval);
#endif
#define INTR_EMPTY ((word_t)-1)
word_t isa_query_intr();

#ifdef CONFIG_ISA_riscv
// RISC-V 平台级 CLINT/CSR 钩子放在 ISA 层，保证 difftest reference so 不依赖完整设备初始化也能响应 0x0200_0000 MMIO。
bool isa_riscv32_clint_in_range(paddr_t addr);
word_t isa_riscv32_clint_read(paddr_t addr, int len);
void isa_riscv32_clint_write(paddr_t addr, int len, word_t data);
bool isa_riscv32_plic_in_range(paddr_t addr);
word_t isa_riscv32_plic_read(paddr_t addr, int len);
void isa_riscv32_plic_write(paddr_t addr, int len, word_t data);
void isa_riscv32_plic_reset(void);
void isa_riscv32_plic_set_irq(uint32_t irq, bool level);
word_t isa_riscv32_plic_pending_bits(void);
void isa_riscv32_plic_statistic(void);
void isa_riscv32_post_exec(void);
void isa_riscv32_reset(void);
void isa_riscv32_mmu_tlb_flush(void);
void isa_riscv32_wfi(void);

word_t isa_riscv32_mip_value(void);
void isa_riscv32_write_mie(word_t value);
void isa_riscv32_write_mip(word_t value);
void isa_riscv32_write_mcycle_lo(word_t value);
void isa_riscv32_write_mcycle_hi(word_t value);
void isa_riscv32_raise_timer_intr(void);
#endif

// difftest
bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc);
void isa_difftest_attach();

#endif
