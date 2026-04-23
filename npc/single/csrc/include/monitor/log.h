#ifndef NPC_SINGLE_CSRC_MONITOR_LOG_H_
#define NPC_SINGLE_CSRC_MONITOR_LOG_H_

#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

#define ANSI_NONE    "\033[0m"
#define ANSI_FG_BLUE "\033[1;34m"
#define ANSI_FG_GREEN "\033[1;32m"
#define ANSI_FG_RED  "\033[1;31m"
#define ANSI_FG_YELLOW "\033[1;33m"
#define ANSI_BG_RED  "\033[1;41m"

void npc_init_log(const NpcSimConfig *config);
void npc_close_log(void);
bool npc_log_enable(void);
void npc_log_putchar(char ch);
void npc_log_impl(const char *file, int line, const char *func, const char *fmt, ...);
void npc_log_both_impl(const char *file, int line, const char *func, const char *fmt, ...);
void npc_log_plain(const char *fmt, ...);

#ifdef __cplusplus
}
#endif

/* Log: 只写日志文件，不输出到终端 */
#define Log(fmt, ...) npc_log_impl(__FILE__, __LINE__, __func__, fmt, ##__VA_ARGS__)
/* LogBoth: 同时写日志文件和终端 */
#define LogBoth(fmt, ...) npc_log_both_impl(__FILE__, __LINE__, __func__, fmt, ##__VA_ARGS__)
/* LogBothTag: 同 LogBoth，但用自定义标签替代 __func__，对齐参考工程的 statistic / cpu_exec 标签 */
#define LogBothTag(tag, fmt, ...) npc_log_both_impl(__FILE__, __LINE__, tag, fmt, ##__VA_ARGS__)

#endif
