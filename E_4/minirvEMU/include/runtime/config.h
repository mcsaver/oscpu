#pragma once

#include <stdint.h>

/*
 * RuntimeOptions 汇总运行时的所有行为开关，由环境变量填充。
 * 你可以理解为“用户控制面板”，通过调整字段来影响仿真体验。
 */
typedef struct {
    int trace_enabled;           /* 是否开启指令追踪 */
    uint64_t trace_limit;        /* 追踪输出的最大条数（0 表示无限） */
    int show_regs_after;         /* 程序结束后是否打印寄存器快照 */
    uint64_t progress_stride;    /* 多少步打印一次进度（0 表示关闭） */
    uint64_t loop_repeat_threshold; /* 检测同一 PC 重复的阈值 */
    uint64_t loop_step_ceiling;  /* 最大总步数限制，用于防止死循环 */
    int hold_after_halt;         /* 是否在程序结束后保持窗口等待用户关闭 */
    int auto_clean;              /* 是否在结束时自动清理编译产物 */
} RuntimeOptions;

/* runtime_config_load:
 *   从环境变量读取配置，如果某个变量未设置则采用默认值。
 */
void runtime_config_load(RuntimeOptions *cfg);
