#pragma once

#include "hardware/types.h"
#include "hardware/memory.h"

/*
 * CoreState 表示 RV32I 执行核心的全部可见状态：
 *   - regs 保存 x0~x31 寄存器的值（其中 x0 始终为 0）；
 *   - pc 保存下一条将要执行的指令地址。
 * 这部分可以理解为“CPU 内部寄存器组”。
 */
typedef struct {
    uint32_t regs[HW_GPR_COUNT]; /* 通用寄存器阵列 */
    uint32_t pc;                 /* 当前程序计数器 */
} CoreState;

/*
 * core_reset:
 *   将所有寄存器与 PC 清零，模拟硬件上电复位后的状态。
 */
void core_reset(CoreState *core);

/*
 * core_step:
 *   执行一条 32 位指令。
 *   参数 inst_word 是已经从存储器读出的指令字；mem 用于访存。
 *   返回 CoreStepResult，包含本次执行是否成功、是否触发陷入以及返回码。
 */
CoreStepResult core_step(CoreState *core, SystemMemory *mem, uint32_t inst_word);

/*
 * 调试辅助接口：
 *   core_regs  返回寄存器指针，便于外部遍历；
 *   core_pc    读取当前 PC；
 *   core_set_pc 修改 PC（例如用于循环保护或跳转）。
 */
const uint32_t *core_regs(const CoreState *core);
uint32_t core_pc(const CoreState *core);
void core_set_pc(CoreState *core, uint32_t pc);
