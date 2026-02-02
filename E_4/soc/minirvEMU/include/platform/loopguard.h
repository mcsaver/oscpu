#pragma once

#include "runtime/config.h"
#include "hardware/types.h"

#include <stdint.h>

/*
 * LoopGuard 负责检测“程序是否可能陷入死循环”，通过记录最近一次的 PC 以及重复统计来工作。
 */

/*
 * LoopSignal 列举了循环保护可以产生的三种信号：
 *   LOOP_SIGNAL_NONE      ：未检测到异常；
 *   LOOP_SIGNAL_REPEAT    ：同一 PC 连续出现超过阈值；
 *   LOOP_SIGNAL_STEP_LIMIT：总执行步数超过上限。
 */
typedef enum {
    LOOP_SIGNAL_NONE = 0,
    LOOP_SIGNAL_REPEAT,
    LOOP_SIGNAL_STEP_LIMIT
} LoopSignal;

/*
 * LoopGuard 内部字段：
 *   last_pc          ：最近一次观察到的 PC；
 *   repeat_count     ：该 PC 连续出现的次数；
 *   repeat_threshold ：允许重复的最大次数，对应 RuntimeOptions.loop_repeat_threshold；
 *   step_ceiling     ：允许的最大步数，对应 RuntimeOptions.loop_step_ceiling。
 */
typedef struct {
    uint32_t last_pc;
    uint64_t repeat_count;
    uint64_t repeat_threshold;
    uint64_t step_ceiling;
} LoopGuard;

/* loopguard_init:
 *   使用运行时配置初始化循环保护的阈值与初始状态。
 */
void loopguard_init(LoopGuard *guard, const RuntimeOptions *opts);

/* loopguard_observe:
 *   在每次执行前调用，传入当前 PC 与全局步数，返回是否需要介入的信号。
 */
LoopSignal loopguard_observe(LoopGuard *guard, uint32_t pc, uint64_t global_step);

/* loopguard_reset:
 *   重置重复计数器（例如在强制跳转到 halt PC 之后）。
 */
void loopguard_reset(LoopGuard *guard);
