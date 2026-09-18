/* NPC 全局状态与工具函数 — C 重构版
 * std::chrono 替换为 clock_gettime(CLOCK_MONOTONIC)，
 * std::string 成员改为 char 缓冲区，NSDMI 改为显式初始化函数。 */
#include "utils.h"

#include <string.h>
#include <time.h>

/* ---- 全局单例 ---- */
/* 声明为非 static，让 utils.h 中的 extern 声明能找到；
 * 头文件中的 inline 访问器可以直接引用这两个符号，消除热循环中的间接调用开销。 */
NpcState  g_npc_state;
NpcStats  g_npc_stats;

void npc_reset_state(void) {
  memset(&g_npc_state, 0, sizeof(g_npc_state));
  g_npc_state.watchpoint_id = -1;
  memset(&g_npc_stats, 0, sizeof(g_npc_stats));
}

/* 用 CLOCK_MONOTONIC 替代 std::chrono::steady_clock，更贴近底层 */
uint64_t npc_get_time_us(void) {
  static int boot_initialized = 0;
  static struct timespec boot_time;

  if (!boot_initialized) {
    clock_gettime(CLOCK_MONOTONIC, &boot_time);
    boot_initialized = 1;
  }

  struct timespec now;
  clock_gettime(CLOCK_MONOTONIC, &now);

  uint64_t sec_diff  = (uint64_t)(now.tv_sec  - boot_time.tv_sec);
  uint64_t nsec_diff = (now.tv_nsec >= boot_time.tv_nsec)
                       ? (uint64_t)(now.tv_nsec - boot_time.tv_nsec)
                       : (1000000000ull - (uint64_t)(boot_time.tv_nsec - now.tv_nsec));
  if (now.tv_nsec < boot_time.tv_nsec) sec_diff--;

  return sec_diff * 1000000ull + nsec_diff / 1000ull;
}

const char *npc_state_name(int state) {
  switch (state) {
    case NPC_STOP:           return "stop";
    case NPC_RUNNING:        return "running";
    case NPC_END:            return "end";
    case NPC_ABORT:          return "abort";
    case NPC_QUIT:           return "quit";
    case NPC_TRAP:           return "trap";
    case NPC_WATCHPOINT_HIT: return "watchpoint";
    default:                 return "unknown";
  }
}

/* 初始化 SimConfig 为 Kconfig 默认值 */
void npc_simconfig_init(NpcSimConfig *cfg) {
  memset(cfg, 0, sizeof(*cfg));
  cfg->max_cycles        = NPC_DEFAULT_MAX_CYCLES;
  cfg->trace             = CONFIG_NPC_TRACE_BY_DEFAULT;
  strncpy(cfg->trace_path, "build/npc-wave.vcd", NPC_PATH_MAX - 1);
  cfg->stdin_keyboard    = CONFIG_NPC_STDIN_KEYBOARD;
  cfg->vga_enable        = CONFIG_NPC_HAS_VGA;
  cfg->batch_mode        = CONFIG_NPC_BATCH_MODE;
  cfg->log_to_file       = CONFIG_NPC_LOG_FILE;
  strncpy(cfg->log_path, CONFIG_NPC_DEFAULT_LOG_PATH, NPC_PATH_MAX - 1);
  cfg->progress_interval = NPC_DEFAULT_PROGRESS_INTERVAL;
  cfg->itrace            = NPC_TEXT_TRACE_DEFAULT_ENABLED(CONFIG_NPC_ITRACE_BY_DEFAULT);
  strncpy(cfg->itrace_cond, CONFIG_NPC_ITRACE_COND, NPC_EXPR_MAX - 1);
  cfg->mtrace            = NPC_TEXT_TRACE_DEFAULT_ENABLED(CONFIG_NPC_MTRACE_BY_DEFAULT);
  cfg->dtrace            = NPC_TEXT_TRACE_DEFAULT_ENABLED(CONFIG_NPC_DTRACE_BY_DEFAULT);
  /* CONFIG_NPC_DIFFTEST=y 表示验证构建，默认应逐条驱动 reference；跑分用 --no-diff 或 perf_defconfig 显式关闭。 */
  cfg->difftest          = CONFIG_NPC_DIFFTEST;
  strncpy(cfg->diff_so_path, NPC_DEFAULT_DIFF_SO, NPC_PATH_MAX - 1);
  cfg->diff_port         = 1234;
}
