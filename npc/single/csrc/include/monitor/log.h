#ifndef NPC_SINGLE_CSRC_MONITOR_LOG_H_
#define NPC_SINGLE_CSRC_MONITOR_LOG_H_

#include "../utils.h"

namespace npc {

#define ANSI_NONE "\033[0m"
#define ANSI_FG_BLUE "\033[1;34m"
#define ANSI_FG_GREEN "\033[1;32m"
#define ANSI_FG_RED "\033[1;31m"
#define ANSI_FG_YELLOW "\033[1;33m"
#define ANSI_BG_RED "\033[1;41m"

void init_log(const SimConfig &config);
void close_log();
bool log_enable();
void log_impl(const char *file, int line, const char *func, const char *fmt, ...);
void log_plain(const char *fmt, ...);

}  // namespace npc

#define Log(fmt, ...) npc::log_impl(__FILE__, __LINE__, __func__, fmt, ##__VA_ARGS__)

#endif