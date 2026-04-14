#ifndef NPC_SINGLE_CSRC_MONITOR_WATCHPOINT_H_
#define NPC_SINGLE_CSRC_MONITOR_WATCHPOINT_H_

#include <string>

namespace npc {

void init_watchpoint_pool();
bool new_watchpoint(const std::string &expression);
bool free_watchpoint(int no);
void watchpoint_display();
bool check_watchpoints();

}  // namespace npc

#endif