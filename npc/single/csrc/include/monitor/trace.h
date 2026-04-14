#ifndef NPC_SINGLE_CSRC_MONITOR_TRACE_H_
#define NPC_SINGLE_CSRC_MONITOR_TRACE_H_

#include "../utils.h"

#include <string>

namespace npc {

void init_trace(const SimConfig &config);
bool itrace_compiled();
bool mtrace_compiled();
bool dtrace_compiled();
bool itrace_configured();
bool mtrace_configured();
bool dtrace_configured();
bool itrace_enabled();
bool mtrace_enabled();
bool dtrace_enabled();
const std::string &itrace_condition();
void trace_info_display();
bool trace_set_mode(const std::string &name, bool enabled, std::string *message);
bool trace_set_itrace_condition(const std::string &expression, std::string *message);

}  // namespace npc

#endif