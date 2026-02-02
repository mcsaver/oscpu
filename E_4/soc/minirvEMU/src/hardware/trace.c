#include "hardware/trace.h"

#include <stdio.h>

/*
 * 模块定位：指令追踪输出层。
 * 通过简单的开关与计数器控制是否打印每一步的执行信息。
 */

/* trace_init:
 *   用运行时配置初始化追踪器，缺少参数时直接返回避免空指针。
 */
void trace_init(TraceUnit *trace, const RuntimeOptions *opts) {
    if (!trace || !opts) {
        return;
    }
    trace->enabled = opts->trace_enabled;
    trace->limit = opts->trace_limit;
}

/* trace_active:
 *   判断当前 step 是否仍在追踪范围内。
 */
int trace_active(const TraceUnit *trace, uint64_t step) {
    if (!trace || !trace->enabled) {
        return 0;
    }
    if (trace->limit == 0) {
        return 1;
    }
    return step < trace->limit;
}

/* trace_emit:
 *   当追踪启用时输出调试信息，包括指令地址、原始指令以及寄存器快照。
 */
void trace_emit(const TraceUnit *trace, uint64_t step, uint32_t pc, uint32_t inst, const uint32_t *regs) {
    if (!trace_active(trace, step)) {
        return;
    }
    printf("[trace] step=%llu pc=0x%08x inst=0x%08x\n", (unsigned long long)step, pc, inst);
    if (!regs) {
        return;
    }
    for (int i = 0; i < HW_GPR_COUNT; ++i) {
        printf("  x%-2d=0x%08x\n", i, regs[i]);
    }
    fflush(stdout);
}
