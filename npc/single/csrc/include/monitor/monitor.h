#ifndef NPC_SINGLE_CSRC_MONITOR_MONITOR_H_
#define NPC_SINGLE_CSRC_MONITOR_MONITOR_H_

#include "../utils.h"

namespace npc {

bool init_monitor(int argc, char **argv, SimConfig *config);
int monitor_run();
void fini_monitor();
const SimConfig &sim_config();

}  // namespace npc

#endif