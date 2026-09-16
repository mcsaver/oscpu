#ifndef NPC_RV64_CSRC_MONITOR_WATCHPOINT_H_
#define NPC_RV64_CSRC_MONITOR_WATCHPOINT_H_

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void npc_init_watchpoint_pool(void);
bool npc_new_watchpoint(const char *expression);
bool npc_free_watchpoint(int no);
void npc_watchpoint_display(void);

bool npc_check_watchpoints(void);

#ifdef __cplusplus
}
#endif

#endif
