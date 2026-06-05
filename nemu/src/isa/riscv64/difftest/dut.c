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
#include <cpu/difftest.h>
#include "../local-include/reg.h"

//gpr(i)
bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  // 1. 检查 PC 是否一致
  if (cpu.pc != ref_r->pc) {
    Log("PC mismatch! Expected " FMT_WORD ", but got " FMT_WORD, ref_r->pc, cpu.pc);
    return false;
  }

  // 2. 检查 32 个寄存器是否一致
  for (int i = 0; i < 32; i++) {
    if (cpu.gpr[i] != ref_r->gpr[i]) {
      Log("Register %s (x%d) mismatch! Expected " FMT_WORD ", but got " FMT_WORD, 
          reg_name(i), i, ref_r->gpr[i], cpu.gpr[i]);
      return false;
    }
  }

  // 3. 只有全部一致才通过
  return true;
}

void isa_difftest_attach() {
}
