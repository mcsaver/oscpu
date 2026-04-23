/* NPC Monitor 初始化与运行控制 — C 重构版
 * std::string 参数改为 char 缓冲区，getopt 保持 POSIX C 原样 */
#include "monitor/monitor.h"

#include "cpu/cpu.h"
#include "device/device.h"
#include "device/map.h"
#include "memory/paddr.h"
#include "monitor/expr.h"
#include "monitor/log.h"
#include "monitor/sdb.h"
#include "monitor/trace.h"
#include "monitor/watchpoint.h"
#include "utils.h"

#include <getopt.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static NpcSimConfig g_config;

/* 对齐参考工程的 welcome 输出：Trace 状态、编译时间、ISA 名称 */
static void welcome(void) {
  /* OFF 红色、ON 绿色；riscv32 黄字红底，与参考工程配色一致 */
  LogBothTag("welcome", "Trace: %s",
             g_config.trace ? ANSI_FG_GREEN "ON" ANSI_NONE
                            : ANSI_FG_RED   "OFF" ANSI_NONE);
  LogBothTag("welcome", "Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to " ANSI_FG_YELLOW ANSI_BG_RED "riscv32" ANSI_NONE "-NPC!\n");
  printf("For help, type \"help\"\n");
}

/* 解析命令行参数，结果写入 config */
static bool parse_args(int argc, char **argv, NpcSimConfig *config) {
  static const struct option long_opts[] = {
    {"batch",    no_argument,       NULL, 'b'},
    {"image",    required_argument, NULL, 'i'},
    {"max",      required_argument, NULL, 'm'},
    {"log",      optional_argument, NULL, 'l'},
    {"trace",    optional_argument, NULL, 't'},
    {"progress", optional_argument, NULL, 'P'},
    {"itrace",   no_argument,       NULL, 'I'},
    {"mtrace",   no_argument,       NULL, 'M'},
    {"dtrace",   no_argument,       NULL, 'D'},
    {"help",     no_argument,       NULL, 'h'},
    {NULL, 0, NULL, 0},
  };

  int opt;
  /* 使用 optind = 0 兼容 glibc 的重入 */
  optind = 0;
  while ((opt = getopt_long(argc, argv, "bi:m:l::t::P::IMDh", long_opts, NULL)) != -1) {
    switch (opt) {
      case 'b':
        config->batch_mode = true;
        break;
      case 'i':
        strncpy(config->image_path, optarg, NPC_PATH_MAX - 1);
        config->image_path[NPC_PATH_MAX - 1] = '\0';
        break;
      case 'm': {
        char *end = NULL;
        unsigned long long val = strtoull(optarg, &end, 10);
        if (end && *end == '\0') config->max_cycles = (uint64_t)val;
        break;
      }
      case 'l':
        config->log_to_file = true;
        if (optarg && optarg[0] != '\0') {
          strncpy(config->log_path, optarg, NPC_PATH_MAX - 1);
          config->log_path[NPC_PATH_MAX - 1] = '\0';
        }
        break;
      case 't':
        config->trace = true;
        if (optarg && optarg[0] != '\0') {
          strncpy(config->trace_path, optarg, NPC_PATH_MAX - 1);
          config->trace_path[NPC_PATH_MAX - 1] = '\0';
        }
        break;
      case 'P':
        if (optarg && optarg[0] != '\0') {
          char *end = NULL;
          unsigned long long val = strtoull(optarg, &end, 10);
          if (end && *end == '\0') config->progress_interval = (uint64_t)val;
        } else {
          config->progress_interval = NPC_SUGGESTED_PROGRESS_INTERVAL;
        }
        break;
      case 'I': config->itrace = true; break;
      case 'M': config->mtrace = true; break;
      case 'D': config->dtrace = true; break;
      case 'h':
        printf("Usage: %s [OPTIONS]\n", argv[0]);
        printf("  -b, --batch          batch mode (no SDB)\n");
        printf("  -i, --image=FILE     load binary image\n");
        printf("  -m, --max=N          max cycles (0=unlimited)\n");
        printf("  -l, --log[=FILE]     enable log to file\n");
        printf("  -t, --trace[=FILE]   enable VCD trace\n");
        printf("  -P, --progress[=N]   progress reporting interval\n");
        printf("  -I, --itrace         enable instruction trace\n");
        printf("  -M, --mtrace         enable memory trace\n");
        printf("  -D, --dtrace         enable device trace\n");
        return false;
      default:
        return false;
    }
  }

  /* 非选项参数也当作 image path */
  if (optind < argc && config->image_path[0] == '\0') {
    strncpy(config->image_path, argv[optind], NPC_PATH_MAX - 1);
    config->image_path[NPC_PATH_MAX - 1] = '\0';
  }

  return true;
}

bool npc_init_monitor(int argc, char **argv, NpcSimConfig *config) {
  if (!config) return false;
  memcpy(&g_config, config, sizeof(g_config));

  if (!parse_args(argc, argv, &g_config)) return false;

  /* 把解析后的完整配置回写给调用者 */
  memcpy(config, &g_config, sizeof(g_config));

  /* 初始化各子系统，顺序需保证依赖关系 */
  npc_init_log(&g_config);
  npc_init_mem();
  npc_init_map();

  if (g_config.image_path[0] != '\0') {
    if (!npc_load_img(g_config.image_path)) return false;
  } else {
    LogBoth("No image loaded; running built-in ROM.");
  }

  npc_init_device(g_config.stdin_keyboard, g_config.vga_enable);
  npc_init_trace(&g_config);
  npc_init_expr();
  npc_init_watchpoint_pool();

  if (!npc_init_cpu(argc, argv, &g_config)) {
    fprintf(stderr, "[npc] failed to initialize CPU.\n");
    return false;
  }

  welcome();
  return true;
}

int npc_monitor_run(void) {
  if (g_config.batch_mode) {
    npc_cpu_exec(UINT64_MAX);
    NpcState *st = npc_state();
    return (st->state == NPC_END) ? (int)st->halt_ret : 1;
  }

  return npc_sdb_mainloop();
}

void npc_fini_monitor(void) {
  npc_fini_cpu();
  npc_fini_device();
  npc_close_log();
}

const NpcSimConfig *npc_sim_config(void) {
  return &g_config;
}
