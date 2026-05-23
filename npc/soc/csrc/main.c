/* NPC 仿真主入口 — C 重构版 */
#include "cpu/cpu.h"
#include "monitor/monitor.h"

int main(int argc, char **argv) {
  NpcSimConfig config;
  npc_simconfig_init(&config);

  if (!npc_init_monitor(argc, argv, &config)) {
    return 1;
  }

  int exit_code = npc_monitor_run();
  npc_fini_monitor();
  return exit_code;
}
