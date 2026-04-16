#ifndef NPC_SINGLE_CSRC_MONITOR_TRACE_H_
#define NPC_SINGLE_CSRC_MONITOR_TRACE_H_

#include <stdbool.h>
#include <stddef.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

void npc_init_trace(const NpcSimConfig *config);
bool npc_itrace_compiled(void);
bool npc_mtrace_compiled(void);
bool npc_dtrace_compiled(void);
bool npc_itrace_configured(void);
bool npc_mtrace_configured(void);
bool npc_dtrace_configured(void);
bool npc_itrace_enabled(void);
bool npc_mtrace_enabled(void);
bool npc_dtrace_enabled(void);
const char *npc_itrace_condition(void);
void npc_trace_info_display(void);
bool npc_trace_set_mode(const char *name, bool enabled, char *msg_buf, size_t bufsize);
bool npc_trace_set_itrace_condition(const char *expression, char *msg_buf, size_t bufsize);

#ifdef __cplusplus
}
#endif

#endif
