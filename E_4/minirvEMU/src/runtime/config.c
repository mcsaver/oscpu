#include "runtime/config.h"

#include <stdlib.h>

/*
 * 模块定位：运行时配置加载层。
 * 负责从环境变量中提取用户设置，同时在缺省或解析失败时回落到安全默认值。
 */

/* load_uint64:
 *   工具函数，将字符串解析为无符号 64 位整数；若输入为空或格式错误则返回默认值。
 */
static uint64_t load_uint64(const char *value, uint64_t fallback) {
    if (!value) {
        return fallback;
    }
    char *end = NULL;
    unsigned long long parsed = strtoull(value, &end, 10);
    if (end == value) {
        return fallback;
    }
    return (uint64_t)parsed;
}

/* load_flag:
 *   将字符串转换为布尔标志，非零视为 true，用于解析开关型环境变量。
 */
static int load_flag(const char *value, int fallback) {
    if (!value) {
        return fallback;
    }
    return (atoi(value) != 0);
}

/* runtime_config_load:
 *   将所有配置项一次性写入 RuntimeOptions，供后续模块直接使用。
 */
void runtime_config_load(RuntimeOptions *cfg) {
    if (!cfg) {
        return;
    }
    cfg->trace_enabled         = load_flag(getenv("TRACE_INS"), 0);
    cfg->trace_limit           = load_uint64(getenv("TRACE_LIMIT"), 200ull);
    cfg->show_regs_after       = load_flag(getenv("SHOW_REGS_AFTER"), 0);
    cfg->progress_stride       = load_uint64(getenv("PROGRESS_EVERY"), 0ull);
    cfg->loop_repeat_threshold = load_uint64(getenv("LOOP_THRESH"), 1000000ull);
    cfg->loop_step_ceiling     = load_uint64(getenv("LOOP_MAX_STEPS"), 5000000ull);
    cfg->hold_after_halt       = load_flag(getenv("HOLD_IMAGE_AFTER_HALT"), 0);
    cfg->auto_clean            = load_flag(getenv("AUTO_CLEAN_AFTER_HALT"), 1);
}
