#pragma once

#include "runtime/config.h"
#include "hardware/core.h"
#include "runtime/loader.h"
#include "platform/loopguard.h"
#include "hardware/trace.h"
#include "platform/video.h"

/*
 * HardwareSystem 聚合 SoC 的全部状态，可理解为“单芯片系统”的抽象。
 * 主要字段说明：
 *   options         ：运行时配置副本；
 *   memory          ：统一的主存 + 显存；
 *   core            ：执行指令的 CPU 内核；
 *   rom_words       ：指向当前加载的程序指令数组；
 *   rom_word_count  ：指令条数；
 *   halt_pc         ：程序自然结束（ECALL/EBREAK）的地址，用于循环保护跳转；
 *   trace           ：指令追踪器；
 *   guard           ：循环保护器；
 *   step_counter    ：累计执行的步数（含取指失败）；
 *   retired_counter ：累计真正退休的指令条数；
 *   hold_after_halt ：是否在仿真结束后保持图形窗口。
 */
typedef struct {
    RuntimeOptions options;
    SystemMemory memory;
    CoreState core;
    uint32_t *rom_words;
    size_t rom_word_count;
    uint32_t halt_pc;
    TraceUnit trace;
    LoopGuard guard;
    uint64_t step_counter;
    uint64_t retired_counter;
    int hold_after_halt;
} HardwareSystem;

/* soc_bootstrap:
 *   根据给定配置初始化 HardwareSystem，重置内存、核心、追踪与保护模块。
 */
void soc_bootstrap(HardwareSystem *soc, const RuntimeOptions *opts);

/* soc_attach_program:
 *   将 ProgramImage 绑定到 SoC，使仿真循环能够读取指令。
 */
void soc_attach_program(HardwareSystem *soc, const ProgramImage *image);

/* soc_memory:
 *   方便外部模块获取内存指针（例如加载器写入程序）。
 */
SystemMemory *soc_memory(HardwareSystem *soc);

/* soc_run:
 *   启动主循环，直至程序结束或出现错误。返回 trap_code 或错误码。
 */
int soc_run(HardwareSystem *soc);

/* soc_force_hold:
 *   动态修改 hold_after_halt（常用于检测特定程序后保持窗口）。
 */
void soc_force_hold(HardwareSystem *soc, int enable);
