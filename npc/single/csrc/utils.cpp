#include "utils.h"

#include <chrono>

namespace npc {

namespace {

NpcState g_npc_state;
NpcStats g_npc_stats;

}  // namespace

NpcState &npc_state() {
  return g_npc_state;
}

NpcStats &npc_stats() {
  return g_npc_stats;
}

void reset_npc_state() {
  g_npc_state = NpcState();
  g_npc_stats = NpcStats();
}

uint64_t get_time_us() {
  static const auto boot_time = std::chrono::steady_clock::now();
  const auto now = std::chrono::steady_clock::now();
  return static_cast<uint64_t>(
      std::chrono::duration_cast<std::chrono::microseconds>(now - boot_time).count());
}

const char *npc_state_name(int state) {
  switch (state) {
    case NPC_STOP: return "stop";
    case NPC_RUNNING: return "running";
    case NPC_END: return "end";
    case NPC_ABORT: return "abort";
    case NPC_QUIT: return "quit";
    case NPC_TRAP: return "trap";
    case NPC_WATCHPOINT_HIT: return "watchpoint";
    default: return "unknown";
  }
}

}  // namespace npc