#ifndef NPC_SINGLE_CSRC_UTILS_H_
#define NPC_SINGLE_CSRC_UTILS_H_

#include <cstddef>
#include <cstdint>
#include <string>

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

#ifndef CONFIG_NPC_TRACE_BY_DEFAULT
#define CONFIG_NPC_TRACE_BY_DEFAULT 0
#endif

#ifndef CONFIG_NPC_SDB
#define CONFIG_NPC_SDB 1
#endif

#ifndef CONFIG_NPC_EXPR
#define CONFIG_NPC_EXPR 1
#endif

#ifndef CONFIG_NPC_WATCHPOINT
#define CONFIG_NPC_WATCHPOINT 1
#endif

#ifndef CONFIG_NPC_ITRACE
#define CONFIG_NPC_ITRACE 0
#endif

#ifndef CONFIG_NPC_ITRACE_COND
#define CONFIG_NPC_ITRACE_COND "true"
#endif

#ifndef CONFIG_NPC_MTRACE
#define CONFIG_NPC_MTRACE 0
#endif

#ifndef CONFIG_NPC_DTRACE
#define CONFIG_NPC_DTRACE 0
#endif

#ifndef CONFIG_NPC_LOG_FILE
#define CONFIG_NPC_LOG_FILE 0
#endif

#ifndef CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL
#define CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL 10000000
#endif

namespace npc {

constexpr uint32_t kResetPc = 0x80000000u;
constexpr uint32_t kPmemBase = 0x80000000u;
constexpr std::size_t kPmemSize = 128ull * 1024ull * 1024ull;
constexpr uint32_t kDeviceBase = 0xa0000000u;
constexpr uint32_t kSerialPort = kDeviceBase + 0x000003f8u;
constexpr uint32_t kRtcAddr = kDeviceBase + 0x00000048u;
constexpr uint32_t kKbdAddr = kDeviceBase + 0x00000060u;
constexpr uint32_t kKeydownMask = 0x8000u;
constexpr uint64_t kUnlimitedMaxCycles = 0ull;
constexpr uint64_t kProgressDisabled = 0ull;
constexpr uint64_t kSuggestedProgressInterval = 10000000ull;
constexpr uint64_t kDefaultMaxCycles = static_cast<uint64_t>(CONFIG_NPC_DEFAULT_MAX_CYCLES);
constexpr uint64_t kDefaultProgressInterval = static_cast<uint64_t>(CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL);

// 把 0 统一约定成“关闭周期超时”，这样 Kconfig 默认值和命令行 --max-cycles 走的是同一套语义。
inline bool cycle_limit_enabled(uint64_t max_cycles) {
  return max_cycles != kUnlimitedMaxCycles;
}

// progress 也复用 0 = off 的约定，避免命令行、默认配置和 README 各讲一套语义。
inline bool progress_enabled(uint64_t progress_interval) {
  return progress_interval != kProgressDisabled;
}

// 即使用户把默认 progress 关掉，命令行显式传 --progress 时仍然需要一个稳定的回退间隔。
inline uint64_t normalized_progress_interval(uint64_t progress_interval) {
  return progress_enabled(progress_interval) ? progress_interval : kSuggestedProgressInterval;
}

// 这里镜像一份 AM 的键码枚举顺序，确保 NPC 仿真端注入的输入事件能和 AM 的 ABI 对齐。
#define NPC_AM_KEYS(_) \
  _(ESCAPE) _(F1) _(F2) _(F3) _(F4) _(F5) _(F6) _(F7) _(F8) _(F9) _(F10) _(F11) _(F12) \
  _(GRAVE) _(1) _(2) _(3) _(4) _(5) _(6) _(7) _(8) _(9) _(0) _(MINUS) _(EQUALS) _(BACKSPACE) \
  _(TAB) _(Q) _(W) _(E) _(R) _(T) _(Y) _(U) _(I) _(O) _(P) _(LEFTBRACKET) _(RIGHTBRACKET) _(BACKSLASH) \
  _(CAPSLOCK) _(A) _(S) _(D) _(F) _(G) _(H) _(J) _(K) _(L) _(SEMICOLON) _(APOSTROPHE) _(RETURN) \
  _(LSHIFT) _(Z) _(X) _(C) _(V) _(B) _(N) _(M) _(COMMA) _(PERIOD) _(SLASH) _(RSHIFT) \
  _(LCTRL) _(APPLICATION) _(LALT) _(SPACE) _(RALT) _(RCTRL) \
  _(UP) _(DOWN) _(LEFT) _(RIGHT) _(INSERT) _(DELETE) _(HOME) _(END) _(PAGEUP) _(PAGEDOWN)

#define NPC_AM_KEY_NAME(key) AM_KEY_##key,
enum AmKeycode {
  AM_KEY_NONE = 0,
  NPC_AM_KEYS(NPC_AM_KEY_NAME)
};
#undef NPC_AM_KEY_NAME

enum NpcExecState {
  NPC_STOP = 0,
  NPC_RUNNING,
  NPC_END,
  NPC_ABORT,
  NPC_QUIT,
  NPC_TRAP,
  NPC_WATCHPOINT_HIT,
};

enum class BusAccessKind {
  kIfetch = 0,
  kLoad,
  kStore,
};

struct NpcState {
  int state = NPC_STOP;
  uint32_t halt_pc = 0;
  uint32_t halt_ret = 0;
  uint32_t trap_cause = 0;
  uint32_t trap_tval = 0;
  bool exit_is_ebreak = false;
  bool exit_is_ecall = false;
  int watchpoint_id = -1;
  uint32_t watchpoint_old_value = 0;
  uint32_t watchpoint_new_value = 0;
  std::string watchpoint_expr;
};

struct NpcStats {
  uint64_t cycles = 0;
  uint64_t commits = 0;
  uint64_t sim_time = 0;
  uint64_t host_time_us = 0;
};

struct SimConfig {
  std::string image_path;
  uint64_t max_cycles = static_cast<uint64_t>(CONFIG_NPC_DEFAULT_MAX_CYCLES);
  bool trace = CONFIG_NPC_TRACE_BY_DEFAULT;
  std::string trace_path = "build/npc-wave.vcd";
  bool stdin_keyboard = CONFIG_NPC_STDIN_KEYBOARD;
  bool batch_mode = CONFIG_NPC_BATCH_MODE;
  bool log_to_file = CONFIG_NPC_LOG_FILE;
  std::string log_path = CONFIG_NPC_DEFAULT_LOG_PATH;
  uint64_t progress_interval = static_cast<uint64_t>(CONFIG_NPC_DEFAULT_PROGRESS_INTERVAL);
  // 软件 trace 默认保持关闭，避免把常规运行路径变成日志洪水；是否编进二进制由 Kconfig 决定。
  bool itrace = false;
  std::string itrace_cond = CONFIG_NPC_ITRACE_COND;
  bool mtrace = false;
  bool dtrace = false;
};

NpcState &npc_state();
NpcStats &npc_stats();
void reset_npc_state();
uint64_t get_time_us();
const char *npc_state_name(int state);

}  // namespace npc

#endif