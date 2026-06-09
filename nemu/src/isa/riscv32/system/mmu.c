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

#include <isa.h>

int isa_mmu_check(vaddr_t vaddr, int len, int type) {
  (void)vaddr;
  (void)len;
  (void)type;
  // RV32 当前未实现页表遍历；保持 direct translation，避免把其它宽度的 MMU 逻辑混进来。
  return MMU_DIRECT;
}

paddr_t isa_mmu_translate(vaddr_t vaddr, int len, int type) {
  (void)len;
  (void)type;
  return vaddr;
}

void isa_riscv32_mmu_tlb_flush(void) {
}

void isa_riscv32_mmu_tlb_flush_selective(vaddr_t vaddr, bool flush_vaddr,
    word_t asid, bool flush_asid) {
  (void)vaddr;
  (void)flush_vaddr;
  (void)asid;
  (void)flush_asid;
}
