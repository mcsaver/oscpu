#include "monitor/watchpoint.h"

#include "monitor/expr.h"
#include "utils.h"

#include <array>
#include <cstdio>

namespace npc {

namespace {

struct WatchpointSlot {
  bool used = false;
  int no = -1;
  std::string expression;
  uint32_t last_value = 0;
};

constexpr int kMaxWatchpoints = 32;
std::array<WatchpointSlot, kMaxWatchpoints> g_watchpoints;

}  // namespace

void init_watchpoint_pool() {
  for (int index = 0; index < kMaxWatchpoints; ++index) {
    g_watchpoints[index] = WatchpointSlot{.used = false, .no = index};
  }
}

bool new_watchpoint(const std::string &expression) {
#if !CONFIG_NPC_WATCHPOINT
  std::printf("Watchpoint is disabled in current NPC config.\n");
  (void)expression;
  return false;
#else
  uint32_t value = 0;
  if (!expr(expression, &value)) {
    std::printf("Bad expression: %s\n", expression.c_str());
    return false;
  }

  for (auto &slot : g_watchpoints) {
    if (slot.used) {
      continue;
    }
    slot.used = true;
    slot.expression = expression;
    slot.last_value = value;
    std::printf("Watchpoint %d: %s = 0x%08x\n", slot.no, slot.expression.c_str(), slot.last_value);
    return true;
  }

  std::printf("No free watchpoint slot left.\n");
  return false;
#endif
}

bool free_watchpoint(int no) {
#if !CONFIG_NPC_WATCHPOINT
  (void)no;
  return false;
#else
  for (auto &slot : g_watchpoints) {
    if (slot.no != no || !slot.used) {
      continue;
    }
    slot = WatchpointSlot{.used = false, .no = no};
    std::printf("Watchpoint %d deleted.\n", no);
    return true;
  }
  std::printf("Unknown watchpoint %d.\n", no);
  return false;
#endif
}

void watchpoint_display() {
#if !CONFIG_NPC_WATCHPOINT
  std::printf("Watchpoint is disabled in current NPC config.\n");
#else
  bool any = false;
  for (const auto &slot : g_watchpoints) {
    if (!slot.used) {
      continue;
    }
    any = true;
    std::printf("%-4d %s = 0x%08x\n", slot.no, slot.expression.c_str(), slot.last_value);
  }
  if (!any) {
    std::printf("No watchpoints.\n");
  }
#endif
}

bool check_watchpoints() {
#if !CONFIG_NPC_WATCHPOINT
  return false;
#else
  for (auto &slot : g_watchpoints) {
    if (!slot.used) {
      continue;
    }

    uint32_t current_value = 0;
    if (!expr(slot.expression, &current_value)) {
      continue;
    }

    if (current_value == slot.last_value) {
      continue;
    }

    npc_state().state = NPC_WATCHPOINT_HIT;
    npc_state().watchpoint_id = slot.no;
    npc_state().watchpoint_old_value = slot.last_value;
    npc_state().watchpoint_new_value = current_value;
    npc_state().watchpoint_expr = slot.expression;

    std::printf("\nWatchpoint %d triggered: %s\n", slot.no, slot.expression.c_str());
    std::printf("Old value = 0x%08x\n", slot.last_value);
    std::printf("New value = 0x%08x\n", current_value);

    slot.last_value = current_value;
    return true;
  }
  return false;
#endif
}

}  // namespace npc