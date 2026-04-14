#include "monitor/monitor.h"

#include "cpu/cpu.h"
#include "device/device.h"
#include "memory/paddr.h"
#include "monitor/expr.h"
#include "monitor/log.h"
#include "monitor/sdb.h"
#include "monitor/trace.h"
#include "monitor/watchpoint.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <string>

namespace npc {

namespace {

SimConfig g_config;

void print_usage(const char *argv0) {
  std::fprintf(stderr,
               "Usage: %s <image.bin> [-b|--batch] [--no-batch] [--max-cycles N(0=unlimited)] [--progress] [--no-progress]\n"
               "           [--progress-interval N(0=off)] [--trace] [--trace-file path]\n"
               "           [--stdin-kbd] [-l|--log path] [--itrace[=on]] [--no-itrace] [--itrace-cond EXPR]\\n"
               "           [--mtrace[=on]] [--no-mtrace] [--dtrace[=on]] [--no-dtrace]\n",
               argv0);
}

int state_to_exit_code() {
  switch (npc_state().state) {
    case NPC_END: return static_cast<int>(npc_state().halt_ret);
    case NPC_ABORT: return 2;
    case NPC_TRAP: return 1;
    case NPC_QUIT:
    case NPC_STOP:
    case NPC_WATCHPOINT_HIT:
    default:
      return 0;
  }
}

void welcome() {
  const char *trace_text = g_config.trace ? ANSI_FG_GREEN "ON" ANSI_NONE : ANSI_FG_RED "OFF" ANSI_NONE;
  const char *batch_text = g_config.batch_mode ? ANSI_FG_GREEN "ON" ANSI_NONE : ANSI_FG_RED "OFF" ANSI_NONE;
  const std::string max_cycles_text = cycle_limit_enabled(g_config.max_cycles) ?
                                      std::to_string(g_config.max_cycles) :
                                      std::string("unlimited");
    const std::string progress_text = progress_enabled(g_config.progress_interval) ?
                    (std::to_string(g_config.progress_interval) + " commits") :
                    std::string("OFF");
  Log("image: %s", g_config.image_path.c_str());
    Log("wave: %s, itrace: %s, mtrace: %s, dtrace: %s, batch: %s, max cycles: %s, progress: %s",
      trace_text,
      itrace_configured() ? ANSI_FG_GREEN "ON" ANSI_NONE : ANSI_FG_RED "OFF" ANSI_NONE,
      mtrace_configured() ? ANSI_FG_GREEN "ON" ANSI_NONE : ANSI_FG_RED "OFF" ANSI_NONE,
      dtrace_configured() ? ANSI_FG_GREEN "ON" ANSI_NONE : ANSI_FG_RED "OFF" ANSI_NONE,
      batch_text,
      max_cycles_text.c_str(),
      progress_text.c_str());
  if (g_config.log_to_file) {
    Log("log file: %s", g_config.log_path.c_str());
  }
  if ((itrace_configured() || mtrace_configured() || dtrace_configured()) && !g_config.log_to_file) {
    Log("software trace logs currently go to stdout; pass --log path if you want to keep them in a file");
  }

  std::printf("Welcome to " ANSI_FG_YELLOW ANSI_BG_RED "riscv32" ANSI_NONE "-NPC!\n");
  std::printf("For help, type \"help\"\n");
}

bool parse_args(int argc, char **argv, SimConfig *config) {
  if (config == nullptr) {
    return false;
  }

  for (int index = 1; index < argc; ++index) {
    if (std::strcmp(argv[index], "-b") == 0 || std::strcmp(argv[index], "--batch") == 0) {
      config->batch_mode = true;
    } else if (std::strcmp(argv[index], "--no-batch") == 0) {
      // Kconfig 现在可以把 batch 作为默认启动方式，但临时想进 monitor 时不应该被迫回去改配置重编。
      config->batch_mode = false;
    } else if (std::strcmp(argv[index], "--max-cycles") == 0) {
      if (index + 1 >= argc) {
        std::fprintf(stderr, "[npc] --max-cycles requires an argument\n");
        return false;
      }
      // 这里让命令行和 Kconfig 共用同一条语义：传 0 表示关闭超时，不再强制跑到固定周期数就退出。
      config->max_cycles = std::strtoull(argv[++index], nullptr, 0);
    } else if (std::strcmp(argv[index], "--progress") == 0) {
      // 长跑时打开 progress，可以直接看出仿真仍在推进，而不是静默卡在某个状态上。
      config->progress_interval = normalized_progress_interval(config->progress_interval);
    } else if (std::strcmp(argv[index], "--no-progress") == 0) {
      config->progress_interval = kProgressDisabled;
    } else if (std::strcmp(argv[index], "--progress-interval") == 0) {
      if (index + 1 >= argc) {
        std::fprintf(stderr, "[npc] --progress-interval requires an argument\n");
        return false;
      }
      config->progress_interval = std::strtoull(argv[++index], nullptr, 0);
    } else if (std::strcmp(argv[index], "--trace") == 0) {
      config->trace = true;
    } else if (std::strcmp(argv[index], "--trace-file") == 0) {
      if (index + 1 >= argc) {
        std::fprintf(stderr, "[npc] --trace-file requires an argument\n");
        return false;
      }
      config->trace = true;
      config->trace_path = argv[++index];
    } else if (std::strcmp(argv[index], "--itrace") == 0) {
      config->itrace = true;
    } else if (std::strcmp(argv[index], "--no-itrace") == 0) {
      config->itrace = false;
    } else if (std::strcmp(argv[index], "--itrace-cond") == 0) {
      if (index + 1 >= argc) {
        std::fprintf(stderr, "[npc] --itrace-cond requires an argument\n");
        return false;
      }
      config->itrace = true;
      config->itrace_cond = argv[++index];
    } else if (std::strcmp(argv[index], "--mtrace") == 0) {
      config->mtrace = true;
    } else if (std::strcmp(argv[index], "--no-mtrace") == 0) {
      config->mtrace = false;
    } else if (std::strcmp(argv[index], "--dtrace") == 0) {
      config->dtrace = true;
    } else if (std::strcmp(argv[index], "--no-dtrace") == 0) {
      config->dtrace = false;
    } else if (std::strcmp(argv[index], "--stdin-kbd") == 0) {
      config->stdin_keyboard = true;
    } else if (std::strcmp(argv[index], "-l") == 0 || std::strcmp(argv[index], "--log") == 0) {
      if (index + 1 >= argc) {
        std::fprintf(stderr, "[npc] --log requires an argument\n");
        return false;
      }
      config->log_to_file = true;
      config->log_path = argv[++index];
    } else if (std::strcmp(argv[index], "--help") == 0 || std::strcmp(argv[index], "-h") == 0) {
      return false;
    } else if (argv[index][0] == '-') {
      std::fprintf(stderr, "[npc] unknown option: %s\n", argv[index]);
      return false;
    } else if (config->image_path.empty()) {
      config->image_path = argv[index];
    } else {
      std::fprintf(stderr, "[npc] duplicated image path: %s\n", argv[index]);
      return false;
    }
  }

  if (config->image_path.empty()) {
    std::fprintf(stderr, "[npc] missing image path\n");
    return false;
  }
  return true;
}

}  // namespace

const SimConfig &sim_config() {
  return g_config;
}

bool init_monitor(int argc, char **argv, SimConfig *config) {
  if (!parse_args(argc, argv, &g_config)) {
    print_usage(argv[0]);
    return false;
  }

  if (config != nullptr) {
    *config = g_config;
  }

  init_log(g_config);

  // 启动顺序固定为“状态 -> 内存/设备 -> 镜像 -> CPU”，这样任一步失败时都能明确知道回滚边界在哪。
  reset_npc_state();
  init_mem();
  init_device(g_config.stdin_keyboard);

  if (!load_img(g_config.image_path)) {
    fini_device();
    close_log();
    return false;
  }

  if (!init_cpu(argc, argv, g_config)) {
    fini_device();
    close_log();
    return false;
  }

  init_expr();
  init_trace(g_config);
  init_watchpoint_pool();
  welcome();

  return true;
}

int monitor_run() {
  if (g_config.batch_mode || !CONFIG_NPC_SDB) {
    cpu_exec(std::numeric_limits<uint64_t>::max());
    return state_to_exit_code();
  }

  return sdb_mainloop();
}

void fini_monitor() {
  fini_cpu();
  fini_device();
  close_log();
}

}  // namespace npc