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

// 全状态 difftest 扩展：CSR + priv 扁平化到 buf。★索引约定必须与 NPC difftest.cpp 完全一致。
// 阶段1 比较 0..16(确定性 CSR + priv); 17+ 先填但暂不比(mie/mip=阶段3中断, mcycle/minstret=
// 阶段3计数掩码, fflags/frm=阶段2随 FPR)。buf 至少 32 word。
void isa_difftest_csr_snapshot(uint64_t *buf) {
  buf[0]  = cpu.csr.mstatus;
  buf[1]  = cpu.csr.mepc;
  buf[2]  = cpu.csr.mcause;
  buf[3]  = cpu.csr.mtvec;
  buf[4]  = cpu.csr.mtval;
  buf[5]  = cpu.csr.mscratch;
  buf[6]  = cpu.csr.sepc;
  buf[7]  = cpu.csr.scause;
  buf[8]  = cpu.csr.stvec;
  buf[9]  = cpu.csr.stval;
  buf[10] = cpu.csr.sscratch;
  buf[11] = cpu.csr.medeleg;
  buf[12] = cpu.csr.mideleg;
  buf[13] = cpu.csr.satp;
  buf[14] = cpu.csr.mcounteren;
  buf[15] = cpu.csr.scounteren;
  buf[16] = cpu.priv;
  buf[17] = cpu.csr.mie;
  buf[18] = cpu.csr.mip;
  buf[19] = cpu.csr.mcycle;
  buf[20] = cpu.csr.minstret;
  buf[21] = cpu.csr.fflags;
  buf[22] = cpu.csr.frm;
}
