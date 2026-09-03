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
#include <memory/paddr.h>
#include <memory/soc.h>

// this is not consistent with uint8_t
// but it is ok since we do not access the array directly
#ifdef CONFIG_SOC_SIM
/* ysyxSoC 从只读 MROM 复位；内建程序不能像 generic PMEM 测试那样自写数据。 */
static const uint32_t img [] = {
  0x00000513,  // addi a0, zero, 0
  0x00100073,  // ebreak (used as nemu_trap)
};
#else
static const uint32_t img [] = {
               // addi t1,
  0x00000297,  // auipc t0,0  t0 = pc +0
  0x00028823,  // sb  zero,16(t0) *(t0+16) = 0
  0x0102c503,  // lbu a0,16(t0) a0 = (uint8_t)(t0 + 16)
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data
};
#endif

void isa_riscv32_restart(void) {
  // reference so 可能被多轮 difftest 初始化复用；先清 ISA 状态，避免 CSR/CLINT 残留跨测试串味。
  memset(&cpu, 0, sizeof(cpu));
  isa_riscv32_reset();

  /* Set the initial program counter. */
  cpu.pc = RESET_VECTOR;
  cpu.priv = PRIV_M;
  cpu.csr.mstatus = MSTATUS_SXL_UXL;

  /* The zero register is always 0. */
  cpu.gpr[0] = 0;
}

void init_isa() {
  /* Load built-in image. */
#ifdef CONFIG_SOC_SIM
  Assert(soc_sim_copy_to_guest(RESET_VECTOR, img, sizeof(img)),
      "built-in image does not fit ysyxSoC reset MROM");
#else
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));
#endif

  /* Initialize this virtual computer system. */
  isa_riscv32_restart();
}
