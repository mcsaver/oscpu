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
#include <cpu/bpu.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>
#include <memory/soc.h>
#include <utils.h>

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (n == 0) return;
  assert(buf != NULL);
  // SoC 模式允许 testbench/loader 把镜像或数据同步到片上 SRAM/MROM/SDRAM 等非主 PMEM 窗口。
  if (MUXDEF(CONFIG_SOC_SIM, soc_sim_memcpy(addr, buf, n, direction), false)) {
    return;
  }
  Assert(in_pmem(addr) && in_pmem(addr + n - 1),
      "difftest memcpy out of pmem: addr=" FMT_PADDR ", size=%zu", addr, n);

  if (direction == DIFFTEST_TO_REF) {
    memcpy(guest_to_host(addr), buf, n);
  } else {
    memcpy(buf, guest_to_host(addr), n);
  }
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  assert(dut != NULL);
  if (direction == DIFFTEST_TO_REF) {
    memcpy(&cpu, dut, DIFFTEST_REG_SIZE);
    cpu.gpr[0] = 0;
  } else {
    memcpy(dut, &cpu, DIFFTEST_REG_SIZE);
  }
}

#if defined(CONFIG_ISA_riscv)
// 全状态 difftest 扩展：旁路通道拷 CSR + priv(不动 regcpy 的 gpr+pc memcpy, 分阶段友好)。
__EXPORT void difftest_csr_snapshot(void *buf) {
  isa_difftest_csr_snapshot((uint64_t *)buf);
}
__EXPORT void difftest_fpr_snapshot(void *buf) {
  isa_difftest_fpr_snapshot((uint64_t *)buf);
}
#endif

__EXPORT void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  cpu.pc = isa_raise_intr(NO, cpu.pc);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  (void)port;
  init_mem();
  IFDEF(CONFIG_BPU, init_bpu());
  /* Perform ISA dependent initialization. */
  init_isa();
  nemu_state.state = NEMU_STOP;
}
