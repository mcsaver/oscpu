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

static const char *status_color(bool enabled) {
  return enabled ? ANSI_FG_GREEN "ON" ANSI_NONE : ANSI_FG_RED "OFF" ANSI_NONE;
}

static const char *text_trace_detail(void) {
  static char buf[96];
  snprintf(buf, sizeof(buf), "itrace=%s, mtrace=%s, dtrace=%s",
           npc_itrace_configured() ? "on" : "off",
           npc_mtrace_configured() ? "on" : "off",
           npc_dtrace_configured() ? "on" : "off");
  return buf;
}

/* 对齐参考工程的 welcome 输出，同时区分 VCD 波形和软件文本 trace。 */
static void welcome(void) {
  /* OFF 红色、ON 绿色；riscv32 黄字红底，与参考工程配色一致 */
  LogBothTag("welcome", "Wave Trace: %s", status_color(g_config.trace));
  LogBothTag("welcome", "Text Trace: %s (%s)",
             status_color(npc_text_trace_configured()), text_trace_detail());
  LogBothTag("welcome", "Difftest: %s", status_color(g_config.difftest));
  LogBothTag("welcome", "Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to " ANSI_FG_YELLOW ANSI_BG_RED "riscv32" ANSI_NONE "-NPC!\n");
  printf("For help, type \"help\"\n");
}

/* 解析命令行参数，结果写入 config */
static bool parse_args(int argc, char **argv, NpcSimConfig *config) {
  enum {
    OPT_NO_PROGRESS = 1000,
    OPT_NO_DIFF,
  };

  static const struct option long_opts[] = {
    {"batch",             no_argument,       NULL, 'b'},
    {"image",             required_argument, NULL, 'i'},
    {"max",               required_argument, NULL, 'm'},
    {"max-cycles",        required_argument, NULL, 'm'},
    {"log",               optional_argument, NULL, 'l'},
    {"trace",             optional_argument, NULL, 't'},
    {"progress",          optional_argument, NULL, 'P'},
    {"progress-interval", required_argument, NULL, 'P'},
    {"no-progress",       no_argument,       NULL, OPT_NO_PROGRESS},
    {"itrace",            no_argument,       NULL, 'I'},
    {"mtrace",            no_argument,       NULL, 'M'},
    {"dtrace",            no_argument,       NULL, 'D'},
    {"diff",              required_argument, NULL, 'F'},
    {"diff-port",         required_argument, NULL, 'p'},
    {"no-diff",           no_argument,       NULL, OPT_NO_DIFF},
    {"help",              no_argument,       NULL, 'h'},
    {NULL, 0, NULL, 0},
  };

  int opt;
  /* 使用 optind = 0 兼容 glibc 的重入 */
  optind = 0;
  while ((opt = getopt_long(argc, argv, "bi:m:l::t::P::IMDF:p:h", long_opts, NULL)) != -1) {
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
      case OPT_NO_PROGRESS:
        config->progress_interval = 0;
        break;
      case 'I': config->itrace = true; break;
      case 'M': config->mtrace = true; break;
      case 'D': config->dtrace = true; break;
      case 'F':
#if CONFIG_NPC_DIFFTEST
        /* 默认已开启 difftest；该选项保留给用户显式指定 reference so。 */
        config->difftest = true;
        if (optarg && strcmp(optarg, "default") == 0) {
          strncpy(config->diff_so_path, NPC_DEFAULT_DIFF_SO, NPC_PATH_MAX - 1);
          config->diff_so_path[NPC_PATH_MAX - 1] = '\0';
        } else if (optarg) {
          strncpy(config->diff_so_path, optarg, NPC_PATH_MAX - 1);
          config->diff_so_path[NPC_PATH_MAX - 1] = '\0';
        }
#else
        fprintf(stderr, "[npc-diff] --diff requested, but CONFIG_NPC_DIFFTEST is disabled.\n"
                        "           Enable it in menuconfig or use default_defconfig, then rebuild.\n");
        return false;
#endif
        break;
      case OPT_NO_DIFF:
        config->difftest = false;
        break;
      case 'p': {
#if CONFIG_NPC_DIFFTEST
        char *end = NULL;
        long val = strtol(optarg, &end, 10);
        if (end && *end == '\0' && val > 0) config->diff_port = (int)val;
#else
        fprintf(stderr, "[npc-diff] --diff-port is unavailable because CONFIG_NPC_DIFFTEST is disabled.\n");
        return false;
#endif
        break;
      }
      case 'h':
        printf("Usage: %s [OPTIONS]\n", argv[0]);
        printf("  -b, --batch          batch mode (no SDB)\n");
        printf("  -i, --image=FILE     load binary image\n");
        printf("  -m, --max=N          max cycles (0=unlimited)\n");
        printf("      --max-cycles=N   compatibility alias for --max\n");
        printf("  -l, --log[=FILE]     enable log to file\n");
        printf("  -t, --trace[=FILE]   enable VCD wave trace\n");
        printf("  -P, --progress[=N]   progress reporting interval\n");
        printf("      --progress-interval=N compatibility alias for --progress=N\n");
        printf("      --no-progress    disable progress reporting\n");
        printf("  -I, --itrace         enable instruction trace\n");
        printf("  -M, --mtrace         enable memory trace\n");
        printf("  -D, --dtrace         enable device trace\n");
#if CONFIG_NPC_DIFFTEST
        printf("  -F, --diff=SO        set difftest reference .so (default: built-in NEMU reference)\n");
        printf("      --diff-port=N    difftest reference port (default 1234)\n");
        printf("      --no-diff        disable difftest for this run\n");
#else
        printf("  -F, --diff=SO        unavailable: rebuild with CONFIG_NPC_DIFFTEST=y\n");
        printf("      --diff-port=N    unavailable: rebuild with CONFIG_NPC_DIFFTEST=y\n");
        printf("      --no-diff        accepted as a no-op; difftest is not built\n");
#endif
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
