#ifndef NPC_SINGLE_CSRC_MONITOR_MONITOR_H_
#define NPC_SINGLE_CSRC_MONITOR_MONITOR_H_

#include <stdbool.h>
#include "../utils.h"

#ifdef __cplusplus
extern "C" {
#endif

bool npc_init_monitor(int argc, char **argv, NpcSimConfig *config);
int npc_monitor_run(void);
void npc_fini_monitor(void);
const NpcSimConfig *npc_sim_config(void);

#ifdef __cplusplus
}
#endif

#endif
