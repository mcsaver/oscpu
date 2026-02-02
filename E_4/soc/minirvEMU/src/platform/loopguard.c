#include "platform/loopguard.h"

/*
 * 模块定位：循环保护层。
 * 核心思路是记录最近一次 PC 与重复次数，并对照阈值判断是否需要介入。
 */

/* loopguard_init:
 *   使用配置中的阈值初始化 LoopGuard，并将 last_pc 置为无效值。
 */
void loopguard_init(LoopGuard *guard, const RuntimeOptions *opts) {
    if (!guard || !opts) {
        return;
    }
    guard->last_pc = 0xffffffffu;
    guard->repeat_count = 0;
    guard->repeat_threshold = opts->loop_repeat_threshold;
    guard->step_ceiling = opts->loop_step_ceiling;
}

/* loopguard_observe:
 *   在每步执行前调用：
 *     - 如果 PC 与上次相同，repeat_count++；否则重置计数并记录新 PC；
 *     - 当 repeat_count 超过阈值或总步数超过上限时，返回相应信号。
 */
LoopSignal loopguard_observe(LoopGuard *guard, uint32_t pc, uint64_t global_step) {
    if (!guard) {
        return LOOP_SIGNAL_NONE;
    }
    if (pc == guard->last_pc) {
        guard->repeat_count++;
    } else {
        guard->last_pc = pc;
        guard->repeat_count = 0;
    }

    if (guard->repeat_threshold > 0 && guard->repeat_count >= guard->repeat_threshold) {
        return LOOP_SIGNAL_REPEAT;
    }
    if (guard->step_ceiling > 0 && global_step >= guard->step_ceiling) {
        return LOOP_SIGNAL_STEP_LIMIT;
    }
    return LOOP_SIGNAL_NONE;
}

/* loopguard_reset:
 *   在平台层采取措施（如跳转到 halt_pc）后，调用该函数重启计数。
 */
void loopguard_reset(LoopGuard *guard) {
    if (!guard) {
        return;
    }
    guard->repeat_count = 0;
    guard->last_pc = 0xffffffffu;
}
