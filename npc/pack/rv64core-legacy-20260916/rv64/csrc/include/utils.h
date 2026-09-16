/* NPC 仿真环境核心类型定义 — C 重构版
 * 从 C++ namespace/constexpr/std::string 全面改为纯 C，贴合底层硬件仿真风格。 */
#ifndef NPC_RV64_CSRC_UTILS_H_
#define NPC_RV64_CSRC_UTILS_H_

#include <stdbool.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- Kconfig 默认值回退 ---- */
/* Kconfig 的 bool=n 在 autoconf.h 中表现为“未定义”，所以这里的布尔回退必须保守为 0；
 * 否则 perf_defconfig 关闭的设备/调试功能会被 C 侧重新打开。 */
#ifndef CONFIG_NPC_DEFAULT_MAX_CYCLES
#define CONFIG_NPC_DEFAULT_MAX_CYCLES 2000000
#endif
#ifndef CONFIG_NPC_DEFAULT_LOG_PATH
#define CONFIG_NPC_DEFAULT_LOG_PATH "build/npc-log.txt"
#endif
#ifndef CONFIG_NPC_BATCH_MODE
#define CONFIG_NPC_BATCH_MODE 0
#endif
#ifndef CONFIG_NPC_STDIN_KEYBOARD
#define CONFIG_NPC_STDIN_KEYBOARD 0
#endif
#ifndef CONFIG_NPC_HAS_VGA
#define CONFIG_NPC_HAS_VGA 0
#endif
#ifndef CONFIG_NPC_TRACE_BY_DEFAULT
#define CONFIG_NPC_TRACE_BY_DEFAULT 0
#endif
#ifndef CONFIG_NPC_SDB
#define CONFIG_NPC_SDB 0
#endif
#ifndef CONFIG_NPC_EXPR
#define CONFIG_NPC_EXPR 0
#endif
#ifndef CONFIG_NPC_WATCHPOINT
#define CONFIG_NPC_WATCHPOINT 0
#endif
#ifndef CONFIG_NPC_TEXT_TRACE
#define CONFIG_NPC_TEXT_TRACE 0
#endif
#ifndef CONFIG_NPC_ITRACE_BY_DEFAULT
#define CONFIG_NPC_ITRACE_BY_DEFAULT 0
#endif
#ifndef CONFIG_NPC_ITRACE_COND
#define CONFIG_NPC_ITRACE_COND "true"
#endif
#ifndef CONFIG_NPC_MTRACE_BY_DEFAULT
#define CONFIG_NPC_MTRACE_BY_DEFAULT 0
#endif
#ifndef CONFIG_NPC_DTRACE_BY_DEFAULT
#define CONFIG_NPC_DTRACE_BY_DEFAULT 0
#endif
#ifndef CONFIG_NPC_DIFFTEST
#define CONFIG_NPC_DIFFTEST 0
#endif
#ifndef CONFIG_NPC_LOG_FILE
#define CONFIG_NPC_LOG_FILE 0
#endif
#ifndef CONFIG_NPC_PROGRESS_BY_DEFAULT
#define CONFIG_NPC_PROGRESS_BY_DEFAULT 0
#endif
#ifndef CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL
#define CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL 10000000
#endif
#ifndef NPC_HAS_SDL
#define NPC_HAS_SDL 0
#endif
#ifndef NPC_DEFAULT_DIFF_SO
#define NPC_DEFAULT_DIFF_SO ""
#endif

/* ---- RV64 公共类型与地址常量 ---- */
#define NPC_XLEN                64
typedef uint64_t npc_word_t;
typedef uint64_t npc_paddr_t;
#define NPC_PRIxWORD            PRIx64
#define NPC_PRIxPADDR           PRIx64

#define NPC_RESET_PC            UINT64_C(0x80000000)
#define NPC_PMEM_BASE           UINT64_C(0x80000000)
/* 与 Linux/npc-rv64 rootfs DTS 的 1 GiB RAM 声明保持一致。 */
#define NPC_PMEM_SIZE           (1024ull * 1024ull * 1024ull)
// 设备地址统一由单一集中点提供 (serial→RTL UART, 简易设备→0x12000000 DPI 窗口)
#include "device_address.h"
/* 必须与 vsrc/core/NpcTop.v 的 localparam CLINT_MTIME_DIVISOR 一致:
 * RTL CLINT 每 N 个 core 周期才让 mtime 自增 1(模拟 mtime 慢于 core 时钟),
 * 故 mtime 的期望值是 cycles/N。仅统计行用它把 mtime 与 cycles/N 对照,不参与功能。 */
#define NPC_CLINT_MTIME_DIVISOR UINT64_C(10)
#define NPC_SCREEN_WIDTH        400u
#define NPC_SCREEN_HEIGHT       300u
#define NPC_VISIBLE_FB_SIZE     (NPC_SCREEN_WIDTH * NPC_SCREEN_HEIGHT * 4u)
#define NPC_FB_MAP_SIZE         0x00200000u
#define NPC_KEYDOWN_MASK        0x8000u
#define NPC_UNLIMITED_MAX_CYCLES 0ull
#define NPC_PROGRESS_DISABLED   0ull
#define NPC_SUGGESTED_PROGRESS_INTERVAL 10000000ull
#define NPC_DEFAULT_MAX_CYCLES  ((uint64_t)(CONFIG_NPC_DEFAULT_MAX_CYCLES))
/* 默认 progress 先受 Kconfig bool 控制；关闭时不要再依赖 interval=0 这种隐式约定。 */
#define NPC_DEFAULT_PROGRESS_INTERVAL \
  (CONFIG_NPC_PROGRESS_BY_DEFAULT ? ((uint64_t)(CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL)) : NPC_PROGRESS_DISABLED)
#define NPC_TEXT_TRACE_DEFAULT_ENABLED(cfg) (CONFIG_NPC_TEXT_TRACE && (cfg))

/* 把 0 统一约定成"关闭周期超时"，Kconfig 和命令行走同一套语义 */
static inline bool npc_cycle_limit_enabled(uint64_t max_cycles) {
  return max_cycles != NPC_UNLIMITED_MAX_CYCLES;
}

static inline bool npc_progress_enabled(uint64_t interval) {
  return interval != NPC_PROGRESS_DISABLED;
}

/* 即使默认 progress 关掉，命令行显式传 --progress 时需要一个稳定回退间隔 */
static inline uint64_t npc_normalized_progress_interval(uint64_t interval) {
  return npc_progress_enabled(interval) ? interval : NPC_SUGGESTED_PROGRESS_INTERVAL;
}

/* ---- AM 键码枚举 ---- */
#define NPC_AM_KEYS(_) \
  _(ESCAPE) _(F1) _(F2) _(F3) _(F4) _(F5) _(F6) _(F7) _(F8) _(F9) _(F10) _(F11) _(F12) \
  _(GRAVE) _(1) _(2) _(3) _(4) _(5) _(6) _(7) _(8) _(9) _(0) _(MINUS) _(EQUALS) _(BACKSPACE) \
  _(TAB) _(Q) _(W) _(E) _(R) _(T) _(Y) _(U) _(I) _(O) _(P) _(LEFTBRACKET) _(RIGHTBRACKET) _(BACKSLASH) \
  _(CAPSLOCK) _(A) _(S) _(D) _(F) _(G) _(H) _(J) _(K) _(L) _(SEMICOLON) _(APOSTROPHE) _(RETURN) \
  _(LSHIFT) _(Z) _(X) _(C) _(V) _(B) _(N) _(M) _(COMMA) _(PERIOD) _(SLASH) _(RSHIFT) \
  _(LCTRL) _(APPLICATION) _(LALT) _(SPACE) _(RALT) _(RCTRL) \
  _(UP) _(DOWN) _(LEFT) _(RIGHT) _(INSERT) _(DELETE) _(HOME) _(END) _(PAGEUP) _(PAGEDOWN)

#define NPC_AM_KEY_NAME(key) AM_KEY_##key,
enum NpcAmKeycode {
  AM_KEY_NONE = 0,
  NPC_AM_KEYS(NPC_AM_KEY_NAME)
};
#undef NPC_AM_KEY_NAME

/* ---- 执行状态枚举 ---- */
enum NpcExecState {
  NPC_STOP = 0,
  NPC_RUNNING,
  NPC_END,
  NPC_ABORT,
  NPC_QUIT,
  NPC_TRAP,
  NPC_WATCHPOINT_HIT,
};

/* ---- 总线访问类型（原 enum class，改为普通 enum + 前缀） ---- */
enum NpcBusAccess {
  NPC_BUS_IFETCH = 0,
  NPC_BUS_LOAD,
  NPC_BUS_STORE,
};

/* ---- 路径缓冲区大小 ---- */
#define NPC_PATH_MAX 4096
#define NPC_EXPR_MAX 256
#define NPC_MAX_LOAD_IMAGES 8

typedef struct {
  npc_paddr_t addr;
  char path[NPC_PATH_MAX];
} NpcLoadImageSpec;

/* ---- 核心结构体（不再使用 NSDMI，由初始化函数清零） ---- */
typedef struct {
  int state;
  npc_word_t halt_pc;
  npc_word_t halt_ret;
  uint32_t trap_cause;
  npc_word_t trap_tval;
  bool exit_is_ebreak;
  bool exit_is_ecall;
  bool exit_is_system_reset;
  bool exit_is_tohost;
  npc_word_t tohost_value;
  int watchpoint_id;
  npc_word_t watchpoint_old_value;
  npc_word_t watchpoint_new_value;
  char watchpoint_expr[NPC_EXPR_MAX];
} NpcState;

typedef struct {
  uint64_t cycles;
  uint64_t commits;
  uint64_t clint_mtime;
  uint64_t sim_time;
  uint64_t host_time_us;
} NpcStats;

typedef struct {
  char image_path[NPC_PATH_MAX];
  NpcLoadImageSpec load_images[NPC_MAX_LOAD_IMAGES];
  int load_image_count;
  uint64_t max_cycles;
  bool trace;
  char trace_path[NPC_PATH_MAX];
  bool stdin_keyboard;
  bool vga_enable;
  bool batch_mode;
  bool log_to_file;
  char log_path[NPC_PATH_MAX];
  uint64_t progress_interval;
  bool itrace;
  char itrace_cond[NPC_EXPR_MAX];
  bool mtrace;
  bool dtrace;
  bool difftest;
  char diff_so_path[NPC_PATH_MAX];
  int diff_port;
  char block_path[NPC_PATH_MAX];
  bool tohost_enable;
  npc_paddr_t tohost_addr;
} NpcSimConfig;

/* ---- 全局状态访问 ----
 * 热循环每拍多次访问 npc_state()/npc_stats()；
 * 用 extern + static inline 让编译器在调用点直接内联，消除跨 TU 函数调用开销。 */
extern NpcState g_npc_state;
extern NpcStats g_npc_stats;
static inline NpcState *npc_state(void) { return &g_npc_state; }
static inline NpcStats *npc_stats(void) { return &g_npc_stats; }
void npc_reset_state(void);
uint64_t npc_get_time_us(void);
const char *npc_state_name(int state);

/* 初始化 SimConfig 为默认值 */
void npc_simconfig_init(NpcSimConfig *cfg);

#ifdef __cplusplus
}
#endif

#endif
