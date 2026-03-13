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

#include <dlfcn.h>

#include <isa.h>
#include <cpu/cpu.h>
#include <memory/paddr.h>
#include <utils.h>
#include <difftest-def.h>

//用于在NEMU和Ref之间同步内存
void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
//用于在NEMU和Ref之间同步寄存器
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
//控制Ref执行指定步骤的指令
void (*ref_difftest_exec)(uint64_t n) = NULL;
//向Ref抛出异常/中断
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

#ifdef CONFIG_DIFFTEST

static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;

// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
//跳过机制
//用途：当NEMU执行了一条Ref无法正确处理或不需要对比的指令时调用
//作用：直接把NEMU当前的寄存器状态覆盖给Ref，强行校准
void difftest_skip_ref() {
  is_skip_ref = true;
  // If such an instruction is one of the instruction packing in QEMU
  // (see below), we end the process of catching up with QEMU's pc to
  // keep the consistent behavior in our best.
  // Note that this is still not perfect: if the packed instructions
  // already write some memory, and the incoming instruction in NEMU
  // will load that memory, we will encounter false negative. But such
  // situation is infrequent.
  skip_dut_nr_inst = 0;
}

// this is used to deal with instruction packing in QEMU.
// Sometimes letting QEMU step once will execute multiple instructions.
// We should skip checking until NEMU's pc catches up with QEMU's pc.
// The semantic is
//   Let REF run `nr_ref` instructions first.
//   We expect that DUT will catch up with REF within `nr_dut` instructions.
//跳过机制
//用途：处理“指令打包”现象(如QEMU执行一步可能实际跑了多条指令)
//作用：先让Ref跑nr_ref步，并允许NEMU在接下来的nr_dut步内寻找回同步点(即PC对齐)
void difftest_skip_dut(int nr_ref, int nr_dut) {
  skip_dut_nr_inst += nr_dut;

  while (nr_ref -- > 0) {
    ref_difftest_exec(1);
  }
}

//初始化init_difftest
void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  //加载库：使用dlopen打开传入的ref_so_file
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  //获取符号：使用dlsym绑定对应接口
  ref_difftest_memcpy = dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  //调用ref_difftest_init初始化Ref
  ref_difftest_init(port);
  //使用ref_difftest_memcpy将加载到NEMU内存中的程序镜像(img_size)同步到Ref的物理地址RESET_VECTOR处
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  //使用ref_difftest_regcpy将NEMU当前的寄存器状态(cpu结构体)同步给Ref，确保两者起点相同
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

//如果发现寄存器值不相等，则打印寄存器状态并将NEMU状态设位NEMU_ABORT停机
static void checkregs(CPU_state *ref, vaddr_t pc) {
  if (!isa_difftest_checkregs(ref, pc)) {
    nemu_state.state = NEMU_ABORT;
    nemu_state.halt_pc = pc;
    isa_reg_display();
  }
}

//核心对比逻辑
//
void difftest_step(vaddr_t pc, vaddr_t npc) {
  CPU_state ref_r;

  //如果正处于skit_dut_nr_inst过程中，会检查NEMU的下一条指令PC是否已经追上了Ref的PC，如果追上了，进行一次寄存器检查并恢复正常对比
  if (skip_dut_nr_inst > 0) {
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    if (ref_r.pc == npc) {
      skip_dut_nr_inst = 0;
      checkregs(&ref_r, npc);
      return;
    }
    skip_dut_nr_inst --;
    if (skip_dut_nr_inst == 0)
      panic("can not catch up with ref.pc = " FMT_WORD " at pc = " FMT_WORD, ref_r.pc, pc);
    return;
  }

  //如果is_skip_ref被触发，则不执行Ref，直接同步寄存器并且退出
  if (is_skip_ref) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    is_skip_ref = false;
    return;
  }

  //常规对比：
  //让Reference执行一小步
  ref_difftest_exec(1);
  //将Ref执行后的寄存器状态读回到本地变量ref_r
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
  //调用ISA相关的对比函数
  checkregs(&ref_r, pc);
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif
