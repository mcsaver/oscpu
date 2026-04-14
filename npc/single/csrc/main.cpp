#include "include/cpu/cpu.h"
#include "include/monitor/monitor.h"

int main(int argc, char **argv) {
  npc::SimConfig config;
  // main 只保留启动和收尾，把 monitor/memory/device/cpu-exec 的职责边界固定下来。
  if (!npc::init_monitor(argc, argv, &config)) {
    return 1;
  }

  const int exit_code = npc::monitor_run();
  npc::fini_monitor();
  return exit_code;
}
