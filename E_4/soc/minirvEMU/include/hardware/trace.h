#pragma once

#include "hardware/types.h"
#include "runtime/config.h"

#include <stdint.h>

/*
 * TraceUnit 是一个轻量级的指令追踪器：
 *   enabled 表示是否启用追踪；
 *   limit   指定打印的最大步数（0 表示无限制）。
 * 在硬件仿真中常用于调试“指令执行顺序”。
 */
typedef struct {
    int enabled;    /* 是否开启追踪输出 */
    uint64_t limit; /* 追踪的最大步数上限 */
} TraceUnit;

/* trace_init:
 *   根据 RuntimeOptions 初始化追踪器开关与追踪上限。
 */
void trace_init(TraceUnit *trace, const RuntimeOptions *opts);

/* trace_active:
 *   判断在给定 step（自增步数）下是否需要输出追踪信息。
 */
int trace_active(const TraceUnit *trace, uint64_t step);

/* trace_emit:
 *   当 trace_active 返回 true 时调用，打印当前步数、PC、指令以及寄存器快照。
 */
void trace_emit(const TraceUnit *trace, uint64_t step, uint32_t pc, uint32_t inst, const uint32_t *regs);
