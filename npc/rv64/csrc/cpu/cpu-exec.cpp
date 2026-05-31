/* NPC CPU 执行引擎 — C 重构后唯一保留的 C++ 文件
 * 必须用 C++ 是因为 Verilator 生成的 VNpcSimTop 是 C++ 类，
 * std::unique_ptr 用于管理仿真模型和 VCD 的生命周期。
 * 所有对外函数通过 extern "C" 暴露给 C 代码。 */
#include "cpu/cpu.h"

#include "cpu/difftest.h"
#include "device/device.h"
#include "monitor/disasm.h"
#include "monitor/log.h"
#include "monitor/trace.h"
#include "monitor/watchpoint.h"
#include "memory/paddr.h"
#include "utils.h"

#include <verilated.h>
/* VCD trace 头文件和对象只在编译了 --trace 时存在；
 * Verilator 不传 --trace 会定义 VM_TRACE=0 而非 undef，所以必须用 #if 而非 #ifdef。 */
#if VM_TRACE
#include <verilated_vcd_c.h>
#endif
#include "VNpcSimTop.h"

#include <cctype>
#include <csignal>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <memory>

/* Verilator 用于 VCD 时间戳的回调 */
#if VM_TRACE
double sc_time_stamp() {
  return (double)npc_stats()->sim_time;
}
#endif

/* ---- 内部状态 ---- */

static std::unique_ptr<VNpcSimTop>    g_top;
#if VM_TRACE
static std::unique_ptr<VerilatedVcdC> g_trace_file;
#endif
static uint64_t g_cycle_limit        = NPC_DEFAULT_MAX_CYCLES;
static uint64_t g_progress_interval  = NPC_DEFAULT_PROGRESS_INTERVAL;
static volatile std::sig_atomic_t g_stop_requested = 0;

struct CommitEvent {
  bool     valid;
  npc_word_t pc;
  uint32_t inst;
  npc_word_t next_pc;
  bool     rd_en;
  uint32_t rd_addr;
  npc_word_t rd_data;
  npc_word_t gpr_after[32];
};

struct ExitEvent {
  bool     valid;
  bool     is_ebreak;
  bool     is_ecall;
  npc_word_t code;
  npc_word_t pc;
};

struct TrapEvent {
  bool     valid;
  uint32_t cause;
  npc_word_t pc;
  npc_word_t tval;
};

struct DebugCycleEvent {
  bool     valid;
  uint64_t cycle;
  uint64_t commits;
  npc_word_t pc;
  uint32_t state;
  uint64_t flags;
  uint64_t bus;
  uint64_t bus2;
  uint64_t fetch_addr;
  uint64_t mem_addr;
  uint64_t fetch_pte_addr;
  uint64_t fetch_pte;
  uint64_t fetch_pte_meta;
};

static constexpr uint32_t kMaxCommitEventsPerCycle = 2;
static constexpr uint32_t kRecentCommitRingSize = 32;
static constexpr uint32_t kRecentDebugRingSize = 32;
static constexpr uint32_t kTopBranchWaitPcCount = 8;
static CommitEvent g_commit_events[kMaxCommitEventsPerCycle] = {};
static uint32_t    g_commit_event_count = 0;
static CommitEvent g_recent_commits[kRecentCommitRingSize] = {};
static uint64_t    g_recent_commit_seq[kRecentCommitRingSize] = {};
static uint64_t    g_recent_commit_count = 0;
static DebugCycleEvent g_recent_debug[kRecentDebugRingSize] = {};
static uint64_t    g_recent_debug_count = 0;
static ExitEvent   g_exit_event   = {};
static TrapEvent   g_trap_event   = {};
static npc_word_t  g_shadow_gpr[32] = {};
static bool        g_commit_watch_inited = false;
static bool        g_commit_watch_enabled = false;
static npc_word_t  g_commit_watch_start = 0;
static npc_word_t  g_commit_watch_end = 0;
static uint64_t    g_commit_watch_min_commit = 0;
static uint64_t    g_commit_watch_max_commit = UINT64_MAX;
static bool        g_trap_watch_inited = false;
static bool        g_trap_watch_enabled = false;

struct SimPerfStats {
  uint64_t icache_access;
  uint64_t icache_hit;
  uint64_t icache_miss;
  uint64_t dcache_access;
  uint64_t dcache_hit;
  uint64_t dcache_miss;
  uint64_t dcache_load_access;
  uint64_t dcache_load_hit;
  uint64_t dcache_load_miss;
  uint64_t dcache_store_access;
  uint64_t dcache_store_hit;
  uint64_t dcache_store_miss;
  uint64_t dcache_writeback;
  uint64_t dcache_write_through;
  uint64_t ooo_cycles;
  uint64_t ooo_retire_hist[3];
  uint64_t ooo_execute_hist[3];
  uint64_t ooo_dispatch_hist[3];
  uint64_t ooo_fetch_req_valid;
  uint64_t ooo_fetch_req_fire;
  uint64_t ooo_fetch_rsp_fire;
  uint64_t ooo_fetch_rsp_enqueue;
  uint64_t ooo_fetch_rsp_bypass;
  uint64_t ooo_stop_pending_cycles;
  uint64_t ooo_pending_branch_cycles;
  uint64_t ooo_pending_jump_cycles;
  uint64_t ooo_pending_mem_cycles;
  uint64_t ooo_synth_ret_pending_cycles;
  uint64_t ooo_branch_prefetch_fire;
  uint64_t ooo_branch_prefetch_hit;
  uint64_t ooo_mem0_req_fire;
  uint64_t ooo_mem1_req_fire;
  uint64_t ooo_mem0_rsp_fire;
  uint64_t ooo_mem1_rsp_fire;
  uint64_t ooo_commit1_block_cycles;
  npc_word_t ooo_branch_wait_pc[kTopBranchWaitPcCount];
  uint64_t ooo_branch_wait_pc_cycles[kTopBranchWaitPcCount];
  npc_word_t ooo_jump_wait_pc[kTopBranchWaitPcCount];
  uint64_t ooo_jump_wait_pc_cycles[kTopBranchWaitPcCount];
};

struct BpuStats {
  uint64_t branch_total;
  uint64_t branch_correct;
  uint64_t branch_dir_correct;
  uint64_t jal_total;
  uint64_t jal_correct;
  uint64_t jalr_total;
  uint64_t jalr_correct;
  uint64_t ret_total;
  uint64_t ret_correct;
  uint64_t btb_hit;
  uint64_t btb_miss;
  uint64_t bht_correct;
  uint64_t bht_miss;
  uint64_t bht_cold;
  uint64_t ras_hit;
  uint64_t ras_miss;
  uint64_t ras_overflow;
};

struct BranchMissPcStat {
  bool valid;
  uint32_t pc;
  uint64_t count;
};

/* 这些计数来自 NpcSimTop.sv 对 RTL 内部信号的层次化采样；host 只累加 DPI 事件。 */
static SimPerfStats g_sim_perf = {};
static BpuStats g_bpu_stats = {};
static BranchMissPcStat g_branch_miss_pc_stats[256] = {};
static bool g_last_ooo_branch_prefetch_hit = false;
static uint64_t g_nr_branch       = 0;  // B-type 条件分支总数
static uint64_t g_nr_branch_taken = 0;  // 条件分支中实际跳转的次数
static uint64_t g_nr_jal          = 0;  // JAL 无条件跳转
static uint64_t g_nr_jalr         = 0;  // JALR 间接跳转（含 ret）

static const char *kRegNames[32] = {
  "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0",   "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6",   "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8",   "s9", "s10","s11","t3", "t4", "t5", "t6",
};

struct ProgressReporter {
  bool     enabled;
  uint64_t interval;
  uint64_t next_commit;
  uint64_t last_commit;
  uint64_t last_report_time_us;
};

static uint64_t simulation_frequency(void) {
  if (npc_stats()->host_time_us == 0) return 0;
  return (npc_stats()->commits * 1000000ull) / npc_stats()->host_time_us;
}

static double ratio_percent(uint64_t part, uint64_t total) {
  return total > 0 ? (double)part / (double)total * 100.0 : 0.0;
}

static void record_ooo_control_flow_commit(uint32_t pc, uint32_t inst, uint32_t next_pc);
static void report_recent_commits(void);
static void report_recent_debug_cycles(void);

static void init_commit_watch(void) {
  if (g_commit_watch_inited) return;
  g_commit_watch_inited = true;

  const char *start_s = std::getenv("NPC_COMMITWATCH_START");
  const char *end_s = std::getenv("NPC_COMMITWATCH_END");
  if (!start_s || !end_s || start_s[0] == '\0' || end_s[0] == '\0') return;

  char *start_end = nullptr;
  char *end_end = nullptr;
  uint64_t start = std::strtoull(start_s, &start_end, 0);
  uint64_t end = std::strtoull(end_s, &end_end, 0);
  if (start_end == start_s || end_end == end_s || start > end) return;

  g_commit_watch_start = (npc_word_t)start;
  g_commit_watch_end = (npc_word_t)end;
  const char *min_commit_s = std::getenv("NPC_COMMITWATCH_MIN_COMMIT");
  const char *max_commit_s = std::getenv("NPC_COMMITWATCH_MAX_COMMIT");
  if (min_commit_s && min_commit_s[0] != '\0') {
    char *min_end = nullptr;
    uint64_t min_commit = std::strtoull(min_commit_s, &min_end, 0);
    if (min_end != min_commit_s) g_commit_watch_min_commit = min_commit;
  }
  if (max_commit_s && max_commit_s[0] != '\0') {
    char *max_end = nullptr;
    uint64_t max_commit = std::strtoull(max_commit_s, &max_end, 0);
    if (max_end != max_commit_s) g_commit_watch_max_commit = max_commit;
  }
  g_commit_watch_enabled = true;
  LogBothTag("commitwatch",
             "enabled pc=[0x%016" NPC_PRIxWORD ",0x%016" NPC_PRIxWORD
             "] commit=[%llu,%llu]",
             g_commit_watch_start, g_commit_watch_end,
             (unsigned long long)g_commit_watch_min_commit,
             (unsigned long long)g_commit_watch_max_commit);
}

static void maybe_log_commit_watch(npc_word_t pc, uint32_t inst, npc_word_t next_pc,
                                   uint32_t rd_en, uint32_t rd_addr,
                                   npc_word_t rd_data) {
  init_commit_watch();
  uint64_t commit = npc_stats()->commits;
  if (!g_commit_watch_enabled || pc < g_commit_watch_start ||
      pc > g_commit_watch_end || commit < g_commit_watch_min_commit ||
      commit > g_commit_watch_max_commit) {
    return;
  }

  LogBothTag("commitwatch",
             "commit=%llu pc=0x%016" NPC_PRIxWORD
             " inst=0x%08x next=0x%016" NPC_PRIxWORD
             " rd=%u wen=%u rd_data=0x%016" NPC_PRIxWORD
             " ra=0x%016" NPC_PRIxWORD " sp=0x%016" NPC_PRIxWORD
             " s0=0x%016" NPC_PRIxWORD " s1=0x%016" NPC_PRIxWORD
             " s2=0x%016" NPC_PRIxWORD " s3=0x%016" NPC_PRIxWORD
             " s4=0x%016" NPC_PRIxWORD " s5=0x%016" NPC_PRIxWORD
             " s6=0x%016" NPC_PRIxWORD " s7=0x%016" NPC_PRIxWORD
             " a0=0x%016" NPC_PRIxWORD " a1=0x%016" NPC_PRIxWORD
             " a2=0x%016" NPC_PRIxWORD " a3=0x%016" NPC_PRIxWORD
             " a4=0x%016" NPC_PRIxWORD " a5=0x%016" NPC_PRIxWORD,
             (unsigned long long)npc_stats()->commits, pc, inst, next_pc,
             rd_addr, rd_en, rd_data,
             g_shadow_gpr[1], g_shadow_gpr[2], g_shadow_gpr[8],
             g_shadow_gpr[9], g_shadow_gpr[18], g_shadow_gpr[19],
             g_shadow_gpr[20], g_shadow_gpr[21], g_shadow_gpr[22],
             g_shadow_gpr[23], g_shadow_gpr[10], g_shadow_gpr[11],
             g_shadow_gpr[12], g_shadow_gpr[13], g_shadow_gpr[14],
             g_shadow_gpr[15]);
}

static void format_u64_delta(char *buf, size_t size, uint64_t lhs, uint64_t rhs) {
  if (!buf || size == 0) return;
  if (lhs >= rhs) {
    snprintf(buf, size, "+%llu", (unsigned long long)(lhs - rhs));
  } else {
    snprintf(buf, size, "-%llu", (unsigned long long)(rhs - lhs));
  }
}

static bool read_guest_u8(npc_word_t addr, uint8_t *byte) {
  if (!byte) return false;
  npc_word_t word = 0;
  if (!npc_paddr_read(addr & ~(npc_word_t)0x7, &word, NPC_BUS_LOAD)) return false;
  *byte = (uint8_t)((word >> ((addr & 0x7) * 8)) & 0xffu);
  return true;
}

static void read_guest_cstr(npc_word_t addr, char *buf, size_t size) {
  if (!buf || size == 0) return;
  buf[0] = '\0';
  for (size_t i = 0; i + 1 < size; ++i) {
    uint8_t ch = 0;
    if (!read_guest_u8(addr + i, &ch)) {
      buf[i] = '\0';
      return;
    }
    buf[i] = (ch >= 32 && ch < 127) ? (char)ch : '.';
    if (ch == 0) return;
  }
  buf[size - 1] = '\0';
}

static void on_sigint(int) { g_stop_requested = 1; }

static void clear_cycle_events(void) {
  for (uint32_t i = 0; i < kMaxCommitEventsPerCycle; ++i) {
    g_commit_events[i].valid = false;
  }
  g_commit_event_count = 0;
  g_exit_event.valid = false;
  g_trap_event.valid = false;
}

static void reset_event_state(void) {
  clear_cycle_events();
  memset(g_shadow_gpr, 0, sizeof(g_shadow_gpr));
  memset(g_recent_commits, 0, sizeof(g_recent_commits));
  memset(g_recent_commit_seq, 0, sizeof(g_recent_commit_seq));
  g_recent_commit_count = 0;
  memset(g_recent_debug, 0, sizeof(g_recent_debug));
  g_recent_debug_count = 0;
  memset(&g_sim_perf, 0, sizeof(g_sim_perf));
  memset(&g_bpu_stats, 0, sizeof(g_bpu_stats));
  memset(g_branch_miss_pc_stats, 0, sizeof(g_branch_miss_pc_stats));
  g_last_ooo_branch_prefetch_hit = false;
}

static void remember_commit_event(const CommitEvent *event) {
  if (!event || !event->valid) return;
  uint32_t slot = (uint32_t)(g_recent_commit_count % kRecentCommitRingSize);
  g_recent_commits[slot] = *event;
  g_recent_commit_seq[slot] = g_recent_commit_count;
  ++g_recent_commit_count;
}

static void remember_debug_cycle(void) {
  if (!g_top) return;
  uint32_t slot = (uint32_t)(g_recent_debug_count % kRecentDebugRingSize);
  DebugCycleEvent &event = g_recent_debug[slot];
  event.valid = true;
  event.cycle = npc_stats()->cycles;
  event.commits = npc_stats()->commits;
  event.pc = g_top->debug_pc_o;
  event.state = g_top->debug_state_o;
  event.flags = (uint64_t)g_top->debug_ooo_flags_o;
  event.bus = (uint64_t)g_top->debug_bus_flags_o;
  event.bus2 = (uint64_t)g_top->debug_bus2_flags_o;
  event.fetch_addr = (uint64_t)g_top->debug_fetch_addr_o;
  event.mem_addr = (uint64_t)g_top->debug_mem_addr_o;
  event.fetch_pte_addr = (uint64_t)g_top->debug_fetch_pte_addr_o;
  event.fetch_pte = (uint64_t)g_top->debug_fetch_pte_o;
  event.fetch_pte_meta = (uint64_t)g_top->debug_fetch_pte_meta_o;
  ++g_recent_debug_count;
}

extern "C" void npc_commit_event(npc_word_t pc, uint32_t inst, npc_word_t next_pc,
                                 uint32_t rd_en, uint32_t rd_addr, npc_word_t rd_data) {
  const bool write_rd = (rd_en != 0) && rd_addr > 0 && rd_addr < 32;
  if (write_rd) {
    g_shadow_gpr[rd_addr] = rd_data;
  }
  g_shadow_gpr[0] = 0;

  record_ooo_control_flow_commit(pc, inst, next_pc);
  maybe_log_commit_watch(pc, inst, next_pc, rd_en, rd_addr, rd_data);

  static const bool linux_probe_enabled = [] {
    const char *enabled = std::getenv("NPC_LINUX_HANG_PROBE");
    return enabled != nullptr && enabled[0] != '\0' && enabled[0] != '0';
  }();
  const bool linux_probe_hit =
      linux_probe_enabled &&
      (pc == 0x8000564cull || pc == 0x8000cf42ull ||
      pc < 0x80000000ull || next_pc < 0x80000000ull ||
      pc == 0x8000c72eull || pc == 0x8000c730ull ||
      pc == 0x8000c738ull || pc == 0x8000c73aull ||
      pc == 0x80005eaeull || pc == 0x80005eb2ull ||
      next_pc == 0x8000564cull ||
      pc == 0x8001845aull || pc == 0x800184f8ull ||
      pc == 0x80018554ull || pc == 0x80018558ull ||
      pc == 0x80020600ull || pc == 0x80020602ull ||
      pc == 0x8002060eull || pc == 0x80020614ull ||
      pc == 0x8002062cull || pc == 0x80020656ull ||
      pc == 0x8002065aull || pc == 0x80020666ull ||
      pc == 0x80020670ull || pc == 0x80020674ull ||
      pc == 0x80020698ull || pc == 0x80020776ull ||
      pc == 0x8002078eull || pc == 0x800206bcull ||
      pc == 0x8001f454ull || pc == 0x8001f456ull ||
      pc == 0x8001f4f4ull || pc == 0x8001f4f6ull ||
      pc == 0x80023dccull || pc == 0x80023e20ull ||
      pc == 0x80023e3eull || pc == 0x80023e44ull ||
      pc == 0x80023eb2ull || pc == 0x80023cd2ull ||
      pc == 0x80023cd6ull || pc == 0x80023cdaull ||
      pc == 0x80023cdcull || pc == 0x80023ce4ull ||
      pc == 0x80023d2eull || pc == 0x80023d32ull);

  if (linux_probe_hit) {
    if (pc == 0x8000cf42ull) {
      npc_word_t ctx = g_shadow_gpr[12];
      npc_word_t mepc = 0, mstatus = 0, cause = 0, tval = 0, tval2 = 0, tinst = 0, prev = 0;
      bool ok = npc_paddr_read(ctx + 256, &mepc, NPC_BUS_LOAD) &&
                npc_paddr_read(ctx + 264, &mstatus, NPC_BUS_LOAD) &&
                npc_paddr_read(ctx + 280, &cause, NPC_BUS_LOAD) &&
                npc_paddr_read(ctx + 288, &tval, NPC_BUS_LOAD) &&
                npc_paddr_read(ctx + 296, &tval2, NPC_BUS_LOAD) &&
                npc_paddr_read(ctx + 304, &tinst, NPC_BUS_LOAD) &&
                npc_paddr_read(ctx + 320, &prev, NPC_BUS_LOAD);
      LogBothTag("linux_hang_probe",
                 "trap_error_entry commit=%llu msg=0x%016" NPC_PRIxWORD
                 " rc=0x%016" NPC_PRIxWORD " ctx=0x%016" NPC_PRIxWORD
                 " ok=%d cause=0x%016" NPC_PRIxWORD " tval=0x%016" NPC_PRIxWORD
                 " tval2=0x%016" NPC_PRIxWORD " tinst=0x%016" NPC_PRIxWORD
                 " mepc=0x%016" NPC_PRIxWORD " mstatus=0x%016" NPC_PRIxWORD
                 " prev=0x%016" NPC_PRIxWORD,
                 (unsigned long long)npc_stats()->commits,
                 g_shadow_gpr[10], g_shadow_gpr[11], ctx,
                 ok ? 1 : 0, cause, tval, tval2, tinst, mepc, mstatus, prev);
    }
    if (pc == 0x80002a80ull || pc == 0x80002ab8ull ||
        pc == 0x80002ac8ull || pc == 0x8000564cull ||
        next_pc == 0x8000564cull) {
      char msg[96];
      read_guest_cstr(g_shadow_gpr[10], msg, sizeof(msg));
      LogBothTag("linux_hang_probe",
                 "panic_hang_edge commit=%llu pc=0x%016" NPC_PRIxWORD
                 " next=0x%016" NPC_PRIxWORD " a0=0x%016" NPC_PRIxWORD
                 " ra=0x%016" NPC_PRIxWORD " sp=0x%016" NPC_PRIxWORD
                 " msg=\"%s\"",
                 (unsigned long long)npc_stats()->commits, pc, next_pc,
                 g_shadow_gpr[10], g_shadow_gpr[1], g_shadow_gpr[2], msg);
    }
    npc_word_t stk24 = 0, stk40 = 0, stk72 = 0;
    npc_word_t mt_off = 0, hart0_scratch = 0, hart0_mtimer = 0;
    npc_word_t s1_hart_pair = 0, s6_hart_pair = 0;
    npc_word_t fp_m128 = 0, fp_m120 = 0;
    bool stk24_ok = npc_paddr_read(g_shadow_gpr[2] + 24, &stk24, NPC_BUS_LOAD);
    bool stk40_ok = npc_paddr_read(g_shadow_gpr[2] + 40, &stk40, NPC_BUS_LOAD);
    bool stk72_ok = npc_paddr_read(g_shadow_gpr[2] + 72, &stk72, NPC_BUS_LOAD);
    bool mt_off_ok = npc_paddr_read(0x80044d30ull, &mt_off, NPC_BUS_LOAD);
    bool hart0_scratch_ok = npc_paddr_read(0x80044498ull, &hart0_scratch, NPC_BUS_LOAD);
    bool hart0_mtimer_ok = mt_off_ok && hart0_scratch_ok &&
                           (hart0_scratch >= 0x80000000ull) &&
                           npc_paddr_read(hart0_scratch + mt_off, &hart0_mtimer, NPC_BUS_LOAD);
    bool s1_hart_pair_ok = (g_shadow_gpr[9] >= 0x80000000ull) &&
                           npc_paddr_read(g_shadow_gpr[9] + 40, &s1_hart_pair, NPC_BUS_LOAD);
    bool s6_hart_pair_ok = (g_shadow_gpr[22] >= 0x80000000ull) &&
                           npc_paddr_read(g_shadow_gpr[22] + 40, &s6_hart_pair, NPC_BUS_LOAD);
    bool fp_m128_ok = (g_shadow_gpr[8] >= 0x80000080ull) &&
                      npc_paddr_read(g_shadow_gpr[8] - 128, &fp_m128, NPC_BUS_LOAD);
    bool fp_m120_ok = (g_shadow_gpr[8] >= 0x80000078ull) &&
                      npc_paddr_read(g_shadow_gpr[8] - 120, &fp_m120, NPC_BUS_LOAD);
    LogBothTag("linux_hang_probe",
               "commit=%llu pc=0x%016" NPC_PRIxWORD " inst=0x%08x next=0x%016" NPC_PRIxWORD
               " rd=%u wen=%u rd_data=0x%016" NPC_PRIxWORD
               " ra=0x%016" NPC_PRIxWORD " sp=0x%016" NPC_PRIxWORD
               " a0=0x%016" NPC_PRIxWORD " a1=0x%016" NPC_PRIxWORD
               " a2=0x%016" NPC_PRIxWORD " a3=0x%016" NPC_PRIxWORD
               " a4=0x%016" NPC_PRIxWORD " a5=0x%016" NPC_PRIxWORD
               " s1=0x%016" NPC_PRIxWORD " s2=0x%016" NPC_PRIxWORD
               " s3=0x%016" NPC_PRIxWORD " s4=0x%016" NPC_PRIxWORD
               " s5=0x%016" NPC_PRIxWORD " s6=0x%016" NPC_PRIxWORD
               " s7=0x%016" NPC_PRIxWORD " s8=0x%016" NPC_PRIxWORD
               " s9=0x%016" NPC_PRIxWORD " s10=0x%016" NPC_PRIxWORD
               " s11=0x%016" NPC_PRIxWORD
               " mt_off=0x%016" NPC_PRIxWORD "(%d)"
               " hart0_scratch=0x%016" NPC_PRIxWORD "(%d)"
               " hart0_mtimer=0x%016" NPC_PRIxWORD "(%d)"
               " s1_hart_pair=0x%016" NPC_PRIxWORD "(%d)"
               " s6_hart_pair=0x%016" NPC_PRIxWORD "(%d)"
               " fp_m128=0x%016" NPC_PRIxWORD "(%d)"
               " fp_m120=0x%016" NPC_PRIxWORD "(%d)"
               " stk24=0x%016" NPC_PRIxWORD "(%d)"
               " stk40=0x%016" NPC_PRIxWORD "(%d) stk72=0x%016" NPC_PRIxWORD "(%d)",
               (unsigned long long)npc_stats()->commits,
               pc, inst, next_pc,
               rd_addr, rd_en, rd_data,
               g_shadow_gpr[1], g_shadow_gpr[2],
               g_shadow_gpr[10], g_shadow_gpr[11], g_shadow_gpr[12],
               g_shadow_gpr[13], g_shadow_gpr[14], g_shadow_gpr[15],
               g_shadow_gpr[9], g_shadow_gpr[18], g_shadow_gpr[19],
               g_shadow_gpr[20], g_shadow_gpr[21], g_shadow_gpr[22],
               g_shadow_gpr[23], g_shadow_gpr[24], g_shadow_gpr[25],
               g_shadow_gpr[26], g_shadow_gpr[27],
               mt_off, mt_off_ok ? 1 : 0,
               hart0_scratch, hart0_scratch_ok ? 1 : 0,
               hart0_mtimer, hart0_mtimer_ok ? 1 : 0,
               s1_hart_pair, s1_hart_pair_ok ? 1 : 0,
               s6_hart_pair, s6_hart_pair_ok ? 1 : 0,
               fp_m128, fp_m128_ok ? 1 : 0,
               fp_m120, fp_m120_ok ? 1 : 0,
               stk24, stk24_ok ? 1 : 0,
               stk40, stk40_ok ? 1 : 0, stk72, stk72_ok ? 1 : 0);
  }

  if (g_commit_event_count < kMaxCommitEventsPerCycle) {
    CommitEvent *event = &g_commit_events[g_commit_event_count++];
    event->valid = true;
    event->pc = pc;
    event->inst = inst;
    event->next_pc = next_pc;
    event->rd_en = write_rd;
    event->rd_addr = rd_addr;
    event->rd_data = rd_data;
    // 双提交时每条事件都保留“该条提交后”的 GPR 快照，避免 lane0 被 lane1 的未来写回污染。
    memcpy(event->gpr_after, g_shadow_gpr, sizeof(event->gpr_after));
    remember_commit_event(event);
  }
}

extern "C" void npc_exit_event(uint32_t is_ebreak, uint32_t is_ecall,
                               npc_word_t code, npc_word_t pc) {
  g_exit_event.valid = true;
  g_exit_event.is_ebreak = is_ebreak != 0;
  g_exit_event.is_ecall = is_ecall != 0;
  g_exit_event.code = code;
  g_exit_event.pc = pc;
}

extern "C" void npc_trap_event(uint32_t cause, npc_word_t pc, npc_word_t tval) {
  g_trap_event.valid = true;
  g_trap_event.cause = cause;
  g_trap_event.pc = pc;
  g_trap_event.tval = tval;
}

extern "C" void npc_handled_trap_event(uint32_t kind, uint32_t cause,
                                       npc_word_t pc, npc_word_t tval) {
  if (!g_trap_watch_inited) {
    g_trap_watch_inited = true;
    const char *enabled = std::getenv("NPC_TRAPWATCH");
    g_trap_watch_enabled = enabled && enabled[0] != '\0' && enabled[0] != '0';
  }
  if (!g_trap_watch_enabled) return;

  const char *kind_name = (kind == 0) ? "mem" : (kind == 1) ? "ex" : "irq";
  LogBothTag("trapwatch",
             "commit=%llu kind=%s cause=%u pc=0x%016" NPC_PRIxWORD
             " tval=0x%016" NPC_PRIxWORD,
             (unsigned long long)npc_stats()->commits, kind_name, cause, pc, tval);
}

extern "C" void npc_control_flow_event(uint32_t is_branch, uint32_t branch_taken,
                                       uint32_t is_jal, uint32_t is_jalr) {
  if (is_branch) {
    g_nr_branch++;
    if (branch_taken) g_nr_branch_taken++;
  }
  if (is_jal) g_nr_jal++;
  if (is_jalr) g_nr_jalr++;
}

extern "C" void npc_bpu_lookup_event(uint32_t is_branch, uint32_t is_jalr,
                                     uint32_t is_ret, uint32_t btb_hit,
                                     uint32_t bht_valid, uint32_t ras_lookup,
                                     uint32_t ras_hit, uint32_t ras_overflow) {
  // lookup 类指标描述预测器表项质量；它按 IF 预测点计数，不参与架构行为。
  if (is_branch && !bht_valid) g_bpu_stats.bht_cold++;
  if (is_jalr) {
    if (btb_hit) g_bpu_stats.btb_hit++;
    else g_bpu_stats.btb_miss++;
  }
  if (is_ret && ras_lookup) {
    if (ras_hit) g_bpu_stats.ras_hit++;
    else g_bpu_stats.ras_miss++;
  }
  if (ras_overflow) g_bpu_stats.ras_overflow++;
}

static void record_branch_mispredict_pc(uint32_t pc) {
  const uint32_t mask = (sizeof(g_branch_miss_pc_stats) / sizeof(g_branch_miss_pc_stats[0])) - 1u;
  uint32_t pos = ((pc >> 1) * 2654435761u) & mask;
  for (uint32_t probe = 0; probe <= mask; ++probe) {
    BranchMissPcStat *slot = &g_branch_miss_pc_stats[(pos + probe) & mask];
    if (!slot->valid) {
      slot->valid = true;
      slot->pc = pc;
      slot->count = 1;
      return;
    }
    if (slot->pc == pc) {
      slot->count++;
      return;
    }
  }
}

extern "C" void npc_bpu_resolve_event(uint32_t is_branch, uint32_t pc,
                                      uint32_t is_jal,
                                      uint32_t is_jalr, uint32_t is_ret,
                                      uint32_t pred_taken,
                                      uint32_t actual_taken,
                                      uint32_t correct) {
  // resolve 类指标以 EX 解析结果为准，pred_pc == real_next_pc 才算最终预测正确。
  if (is_branch) {
    g_bpu_stats.branch_total++;
    if (correct) g_bpu_stats.branch_correct++;
    if (pred_taken == actual_taken) {
      g_bpu_stats.branch_dir_correct++;
      g_bpu_stats.bht_correct++;
    } else {
      g_bpu_stats.bht_miss++;
    }
    if (!correct) record_branch_mispredict_pc(pc);
  }
  if (is_jal) {
    g_bpu_stats.jal_total++;
    if (correct) g_bpu_stats.jal_correct++;
  }
  if (is_jalr) {
    g_bpu_stats.jalr_total++;
    if (correct) g_bpu_stats.jalr_correct++;
  }
  if (is_ret) {
    g_bpu_stats.ret_total++;
    if (correct) g_bpu_stats.ret_correct++;
  }
}

static constexpr uint32_t kOpcodeBranch = 0x63;
static constexpr uint32_t kOpcodeJalr   = 0x67;
static constexpr uint32_t kOpcodeJal    = 0x6f;

static bool is_link_reg(uint32_t reg_idx) {
  return reg_idx == 1u || reg_idx == 5u;
}

static int32_t sign_extend_u32(uint32_t value, unsigned bits) {
  const uint32_t sign = 1u << (bits - 1u);
  return (int32_t)((value ^ sign) - sign);
}

static int32_t decode_branch_imm(uint32_t inst) {
  uint32_t imm = 0;
  imm |= ((inst >> 31) & 0x1u) << 12;
  imm |= ((inst >> 7)  & 0x1u) << 11;
  imm |= ((inst >> 25) & 0x3fu) << 5;
  imm |= ((inst >> 8)  & 0x0fu) << 1;
  return sign_extend_u32(imm, 13);
}

static void record_ooo_control_flow_commit(uint32_t pc, uint32_t inst, uint32_t next_pc) {
  const uint32_t opcode = inst & 0x7fu;
  const bool is_branch = opcode == kOpcodeBranch;
  const bool is_jal = opcode == kOpcodeJal;
  const bool is_jalr = opcode == kOpcodeJalr;
  if (!is_branch && !is_jal && !is_jalr) return;

  const uint32_t rd = (inst >> 7) & 0x1fu;
  const uint32_t rs1 = (inst >> 15) & 0x1fu;
  const bool is_ret = is_jalr && !is_link_reg(rd) && is_link_reg(rs1);
  bool actual_taken = is_jal || is_jalr;
  bool pred_taken = is_jal || is_jalr;
  bool correct = true;

  if (is_branch) {
    const int32_t imm = decode_branch_imm(inst);
    const uint32_t target = pc + (uint32_t)imm;
    actual_taken = next_pc == target;
    // OoO 的动态方向预测在 RTL resolve 点上报；commit 侧只恢复架构控制流计数，
    // 避免把旧的静态 BTFNT 估算重复计入 BPU accuracy。
    npc_control_flow_event(1u, actual_taken ? 1u : 0u, 0u, 0u);
    return;
  }

  npc_control_flow_event(is_branch ? 1u : 0u, actual_taken ? 1u : 0u,
                         is_jal ? 1u : 0u, is_jalr ? 1u : 0u);
  npc_bpu_resolve_event(is_branch ? 1u : 0u, pc, is_jal ? 1u : 0u,
                        is_jalr ? 1u : 0u, is_ret ? 1u : 0u,
                        pred_taken ? 1u : 0u, actual_taken ? 1u : 0u,
                        correct ? 1u : 0u);
}

extern "C" void npc_icache_event(uint32_t access, uint32_t hit, uint32_t miss) {
  g_sim_perf.icache_access += access ? 1u : 0u;
  g_sim_perf.icache_hit += hit ? 1u : 0u;
  g_sim_perf.icache_miss += miss ? 1u : 0u;
}

extern "C" void npc_dcache_event(uint32_t access, uint32_t hit, uint32_t miss,
                                 uint32_t writeback, uint32_t write_through,
                                 uint32_t is_store) {
  g_sim_perf.dcache_access += access ? 1u : 0u;
  g_sim_perf.dcache_hit += hit ? 1u : 0u;
  g_sim_perf.dcache_miss += miss ? 1u : 0u;
  // load/store 明细帮助区分容量冲突、写分配和脏行换出的真实来源。
  if (access) {
    if (is_store) {
      g_sim_perf.dcache_store_access++;
      g_sim_perf.dcache_store_hit += hit ? 1u : 0u;
      g_sim_perf.dcache_store_miss += miss ? 1u : 0u;
    } else {
      g_sim_perf.dcache_load_access++;
      g_sim_perf.dcache_load_hit += hit ? 1u : 0u;
      g_sim_perf.dcache_load_miss += miss ? 1u : 0u;
    }
  }
  g_sim_perf.dcache_writeback += writeback ? 1u : 0u;
  g_sim_perf.dcache_write_through += write_through ? 1u : 0u;
}

static void bump_ooo_hist(uint64_t hist[3], uint32_t value) {
  hist[value < 2 ? value : 2]++;
}

static void bump_branch_wait_pc(npc_word_t pc) {
  if (pc == 0) return;

  uint32_t free_idx = kTopBranchWaitPcCount;
  uint32_t min_idx = 0;
  for (uint32_t i = 0; i < kTopBranchWaitPcCount; i++) {
    if (g_sim_perf.ooo_branch_wait_pc_cycles[i] != 0 &&
        g_sim_perf.ooo_branch_wait_pc[i] == pc) {
      g_sim_perf.ooo_branch_wait_pc_cycles[i]++;
      return;
    }
    if (g_sim_perf.ooo_branch_wait_pc_cycles[i] == 0 &&
        free_idx == kTopBranchWaitPcCount) {
      free_idx = i;
    }
    if (g_sim_perf.ooo_branch_wait_pc_cycles[i] <
        g_sim_perf.ooo_branch_wait_pc_cycles[min_idx]) {
      min_idx = i;
    }
  }

  uint32_t idx = (free_idx != kTopBranchWaitPcCount) ? free_idx : min_idx;
  g_sim_perf.ooo_branch_wait_pc[idx] = pc;
  g_sim_perf.ooo_branch_wait_pc_cycles[idx] = 1;
}

static void bump_jump_wait_pc(npc_word_t pc) {
  if (pc == 0) return;

  uint32_t free_idx = kTopBranchWaitPcCount;
  uint32_t min_idx = 0;
  for (uint32_t i = 0; i < kTopBranchWaitPcCount; i++) {
    if (g_sim_perf.ooo_jump_wait_pc_cycles[i] != 0 &&
        g_sim_perf.ooo_jump_wait_pc[i] == pc) {
      g_sim_perf.ooo_jump_wait_pc_cycles[i]++;
      return;
    }
    if (g_sim_perf.ooo_jump_wait_pc_cycles[i] == 0 &&
        free_idx == kTopBranchWaitPcCount) {
      free_idx = i;
    }
    if (g_sim_perf.ooo_jump_wait_pc_cycles[i] <
        g_sim_perf.ooo_jump_wait_pc_cycles[min_idx]) {
      min_idx = i;
    }
  }

  uint32_t idx = (free_idx != kTopBranchWaitPcCount) ? free_idx : min_idx;
  g_sim_perf.ooo_jump_wait_pc[idx] = pc;
  g_sim_perf.ooo_jump_wait_pc_cycles[idx] = 1;
}

extern "C" void npc_ooo_cycle_event(uint32_t retire_count,
                                    uint32_t execute_count,
                                    uint32_t dispatch_count,
                                    uint32_t fetch_req_valid,
                                    uint32_t fetch_req_fire,
                                    uint32_t fetch_rsp_fire,
                                    uint32_t fetch_rsp_enqueue,
                                    uint32_t fetch_rsp_bypass,
                                    uint32_t stop_pending,
                                    uint32_t pending_branch,
                                    uint32_t pending_jump,
                                    uint32_t pending_mem,
                                    uint32_t synth_ret_pending,
                                    uint32_t branch_prefetch_fire,
                                    uint32_t branch_prefetch_hit,
                                    uint32_t mem0_req_fire,
                                    uint32_t mem1_req_fire,
                                    uint32_t mem0_rsp_fire,
                                    uint32_t mem1_rsp_fire,
                                    uint32_t commit1_block,
                                    npc_word_t pending_branch_pc,
                                    npc_word_t pending_jump_pc) {
  g_sim_perf.ooo_cycles++;
  bump_ooo_hist(g_sim_perf.ooo_retire_hist, retire_count);
  bump_ooo_hist(g_sim_perf.ooo_execute_hist, execute_count);
  bump_ooo_hist(g_sim_perf.ooo_dispatch_hist, dispatch_count);
  g_sim_perf.ooo_fetch_req_valid += fetch_req_valid ? 1u : 0u;
  g_sim_perf.ooo_fetch_req_fire += fetch_req_fire ? 1u : 0u;
  g_sim_perf.ooo_fetch_rsp_fire += fetch_rsp_fire ? 1u : 0u;
  g_sim_perf.ooo_fetch_rsp_enqueue += fetch_rsp_enqueue ? 1u : 0u;
  g_sim_perf.ooo_fetch_rsp_bypass += fetch_rsp_bypass ? 1u : 0u;
  g_sim_perf.ooo_stop_pending_cycles += stop_pending ? 1u : 0u;
  g_sim_perf.ooo_pending_branch_cycles += pending_branch ? 1u : 0u;
  if (pending_branch) bump_branch_wait_pc(pending_branch_pc);
  g_sim_perf.ooo_pending_jump_cycles += pending_jump ? 1u : 0u;
  if (pending_jump) bump_jump_wait_pc(pending_jump_pc);
  g_sim_perf.ooo_pending_mem_cycles += pending_mem ? 1u : 0u;
  g_sim_perf.ooo_synth_ret_pending_cycles += synth_ret_pending ? 1u : 0u;
  g_sim_perf.ooo_branch_prefetch_fire += branch_prefetch_fire ? 1u : 0u;
  // RTL 侧 hit_available 是状态信号；host 侧只在上升沿计一次命中事件，避免长等待时把同一次命中重复累加。
  bool branch_prefetch_hit_now = branch_prefetch_hit != 0;
  g_sim_perf.ooo_branch_prefetch_hit +=
      (branch_prefetch_hit_now && !g_last_ooo_branch_prefetch_hit) ? 1u : 0u;
  g_last_ooo_branch_prefetch_hit = branch_prefetch_hit_now;
  g_sim_perf.ooo_mem0_req_fire += mem0_req_fire ? 1u : 0u;
  g_sim_perf.ooo_mem1_req_fire += mem1_req_fire ? 1u : 0u;
  g_sim_perf.ooo_mem0_rsp_fire += mem0_rsp_fire ? 1u : 0u;
  g_sim_perf.ooo_mem1_rsp_fire += mem1_rsp_fire ? 1u : 0u;
  g_sim_perf.ooo_commit1_block_cycles += commit1_block ? 1u : 0u;
}

static bool install_sigint_handler(void) {
  struct sigaction act = {};
  act.sa_handler = on_sigint;
  sigemptyset(&act.sa_mask);
  // 不打开 SA_RESTART，Ctrl-C 可以打断 monitor 阻塞的 stdin 读操作
  return sigaction(SIGINT, &act, nullptr) == 0;
}

static npc_word_t debug_reg_value(int index) {
  return g_shadow_gpr[index];
}

static void clear_runtime_state(void) {
  NpcState *st = npc_state();
  memset(st, 0, sizeof(*st));
  st->state = NPC_STOP;
  st->watchpoint_id = -1;
}

/* ---- itrace 提交记录 ---- */

static void trace_commit(const CommitEvent &event) {
  if (!npc_itrace_enabled()) return;

  char asm_buf[128];
  int asm_len = npc_disassemble_inst(event.pc, event.inst,
                                     asm_buf, sizeof(asm_buf));
  const char *asm_text = (asm_len > 0) ? asm_buf : "<decode unavailable>";

  if (event.rd_en) {
    // <= 表示"提交后新值写入寄存器"
    Log("itrace pc=0x%016" NPC_PRIxWORD " inst=0x%08x asm=\"%s\" x%u(%s)<=0x%016" NPC_PRIxWORD,
        event.pc, event.inst, asm_text,
        event.rd_addr, kRegNames[event.rd_addr],
        event.rd_data);
  } else {
    Log("itrace pc=0x%016" NPC_PRIxWORD " inst=0x%08x asm=\"%s\"",
        event.pc, event.inst, asm_text);
  }
}

/* ---- Progress ---- */

static ProgressReporter make_progress_reporter(uint64_t max_instructions) {
  ProgressReporter rpt = {};
  if (!npc_progress_enabled(g_progress_interval) || max_instructions != UINT64_MAX)
    return rpt;
  rpt.enabled = true;
  rpt.interval = g_progress_interval;
  rpt.next_commit = ((npc_stats()->commits / rpt.interval) + 1) * rpt.interval;
  rpt.last_commit = npc_stats()->commits;
  rpt.last_report_time_us = npc_get_time_us();
  return rpt;
}

static void maybe_report_progress(ProgressReporter *rpt) {
  if (!rpt || !rpt->enabled || npc_stats()->commits < rpt->next_commit) return;

  uint64_t now_us        = npc_get_time_us();
  uint64_t commits       = npc_stats()->commits;
  uint64_t delta_commits = commits - rpt->last_commit;
  uint64_t delta_us      = now_us - rpt->last_report_time_us;
  uint64_t inst_per_sec  = (delta_us == 0) ? 0 : (delta_commits * 1000000ull) / delta_us;

  npc_log_plain("[progress] %llu insts, pc=0x%016" NPC_PRIxWORD ", %llu inst/s\n",
                (unsigned long long)commits, g_top->debug_pc_o,
                (unsigned long long)inst_per_sec);

  rpt->last_commit = commits;
  rpt->last_report_time_us = now_us;
  while (rpt->next_commit <= commits) rpt->next_commit += rpt->interval;
}

/* ---- 统计与报告 ---- */

static void accumulate_host_time(uint64_t start_us) {
  npc_stats()->host_time_us += npc_get_time_us() - start_us;
}

// 分支/跳转统计报告：按指令类型汇总动态执行次数，方便与其他仿真器输出对比
static void report_branch_stats(void) {
  uint64_t total_commits = npc_stats()->commits;
  uint64_t nr_not_taken = g_nr_branch - g_nr_branch_taken;
  double taken_rate = g_nr_branch > 0
      ? (double)g_nr_branch_taken / (double)g_nr_branch * 100.0 : 0.0;
  uint64_t total_jb = g_nr_branch + g_nr_jal + g_nr_jalr;
  double jb_pct = total_commits > 0
      ? (double)total_jb / (double)total_commits * 100.0 : 0.0;

  LogBothTag("statistic", "=== Branch/Jump Statistics ===");
  LogBothTag("statistic", "  conditional branch  = %llu (taken %llu, not-taken %llu, taken rate %.1f%%)",
          (unsigned long long)g_nr_branch,
          (unsigned long long)g_nr_branch_taken,
          (unsigned long long)nr_not_taken, taken_rate);
  LogBothTag("statistic", "  JAL  (unconditional) = %llu", (unsigned long long)g_nr_jal);
  LogBothTag("statistic", "  JALR (indirect/ret)  = %llu", (unsigned long long)g_nr_jalr);
  LogBothTag("statistic", "  total jump/branch    = %llu (%.1f%% of all instructions)",
          (unsigned long long)total_jb, jb_pct);
  LogBothTag("statistic", "=== BPU Prediction Statistics ===");
  LogBothTag("statistic", "  branch accuracy      = %llu/%llu correct, %llu mispredict (%.1f%%)",
          (unsigned long long)g_bpu_stats.branch_correct,
          (unsigned long long)g_bpu_stats.branch_total,
          (unsigned long long)(g_bpu_stats.branch_total - g_bpu_stats.branch_correct),
          ratio_percent(g_bpu_stats.branch_correct, g_bpu_stats.branch_total));
  LogBothTag("statistic", "  branch direction     = %llu/%llu correct (%.1f%%), dir miss=%llu, gshare cold=%llu",
          (unsigned long long)g_bpu_stats.branch_dir_correct,
          (unsigned long long)g_bpu_stats.branch_total,
          ratio_percent(g_bpu_stats.branch_dir_correct, g_bpu_stats.branch_total),
          (unsigned long long)g_bpu_stats.bht_miss,
          (unsigned long long)g_bpu_stats.bht_cold);
  LogBothTag("statistic", "  JAL accuracy         = %llu/%llu correct (%.1f%%)",
          (unsigned long long)g_bpu_stats.jal_correct,
          (unsigned long long)g_bpu_stats.jal_total,
          ratio_percent(g_bpu_stats.jal_correct, g_bpu_stats.jal_total));
  LogBothTag("statistic", "  JALR accuracy        = %llu/%llu correct (%.1f%%)",
          (unsigned long long)g_bpu_stats.jalr_correct,
          (unsigned long long)g_bpu_stats.jalr_total,
          ratio_percent(g_bpu_stats.jalr_correct, g_bpu_stats.jalr_total));
  LogBothTag("statistic", "  return accuracy      = %llu/%llu correct (%.1f%%)",
          (unsigned long long)g_bpu_stats.ret_correct,
          (unsigned long long)g_bpu_stats.ret_total,
          ratio_percent(g_bpu_stats.ret_correct, g_bpu_stats.ret_total));
  LogBothTag("statistic", "  BTB JALR lookup      = hit %llu, miss %llu",
          (unsigned long long)g_bpu_stats.btb_hit,
          (unsigned long long)g_bpu_stats.btb_miss);
  LogBothTag("statistic", "  direction predictor  = correct %llu, miss %llu",
          (unsigned long long)g_bpu_stats.bht_correct,
          (unsigned long long)g_bpu_stats.bht_miss);
  LogBothTag("statistic", "  RAS lookup           = hit %llu, miss/underflow %llu, overflow %llu",
          (unsigned long long)g_bpu_stats.ras_hit,
          (unsigned long long)g_bpu_stats.ras_miss,
          (unsigned long long)g_bpu_stats.ras_overflow);
  LogBothTag("statistic", "  top branch miss PCs  =");
  bool printed[256] = {};
  for (int rank = 0; rank < 8; ++rank) {
    int best_idx = -1;
    for (int i = 0; i < 256; ++i) {
      if (!g_branch_miss_pc_stats[i].valid) continue;
      if (printed[i]) continue;
      if (best_idx < 0 || g_branch_miss_pc_stats[i].count > g_branch_miss_pc_stats[best_idx].count) {
        best_idx = i;
      }
    }
    if (best_idx < 0) break;
    LogBothTag("statistic", "    #%d pc=0x%08x miss=%llu",
               rank + 1, g_branch_miss_pc_stats[best_idx].pc,
               (unsigned long long)g_branch_miss_pc_stats[best_idx].count);
    printed[best_idx] = true;
  }
}

static void report_cache_stats(void) {
  LogBothTag("statistic", "=== Cache Statistics ===");
  LogBothTag("statistic", "icache: access=%llu, hit=%llu, miss=%llu",
             (unsigned long long)g_sim_perf.icache_access,
             (unsigned long long)g_sim_perf.icache_hit,
             (unsigned long long)g_sim_perf.icache_miss);
  LogBothTag("statistic", "dcache: access=%llu, hit=%llu, miss=%llu",
             (unsigned long long)g_sim_perf.dcache_access,
             (unsigned long long)g_sim_perf.dcache_hit,
             (unsigned long long)g_sim_perf.dcache_miss);
  LogBothTag("statistic", "dcache load: access=%llu, hit=%llu, miss=%llu",
             (unsigned long long)g_sim_perf.dcache_load_access,
             (unsigned long long)g_sim_perf.dcache_load_hit,
             (unsigned long long)g_sim_perf.dcache_load_miss);
  LogBothTag("statistic", "dcache store: access=%llu, hit=%llu, miss=%llu",
             (unsigned long long)g_sim_perf.dcache_store_access,
             (unsigned long long)g_sim_perf.dcache_store_hit,
             (unsigned long long)g_sim_perf.dcache_store_miss);
  LogBothTag("statistic", "dcache writeback = %llu, write-through store = %llu",
             (unsigned long long)g_sim_perf.dcache_writeback,
             (unsigned long long)g_sim_perf.dcache_write_through);
}

static void report_ooo_stats(void) {
  if (g_sim_perf.ooo_cycles == 0) return;
  LogBothTag("statistic", "=== OoO Pipeline Statistics ===");
  LogBothTag("statistic", "ooo cycles observed = %llu",
             (unsigned long long)g_sim_perf.ooo_cycles);
  LogBothTag("statistic", "retire hist 0/1/2 = %llu/%llu/%llu",
             (unsigned long long)g_sim_perf.ooo_retire_hist[0],
             (unsigned long long)g_sim_perf.ooo_retire_hist[1],
             (unsigned long long)g_sim_perf.ooo_retire_hist[2]);
  LogBothTag("statistic", "execute hist 0/1/2 = %llu/%llu/%llu",
             (unsigned long long)g_sim_perf.ooo_execute_hist[0],
             (unsigned long long)g_sim_perf.ooo_execute_hist[1],
             (unsigned long long)g_sim_perf.ooo_execute_hist[2]);
  LogBothTag("statistic", "dispatch hist 0/1/2 = %llu/%llu/%llu",
             (unsigned long long)g_sim_perf.ooo_dispatch_hist[0],
             (unsigned long long)g_sim_perf.ooo_dispatch_hist[1],
             (unsigned long long)g_sim_perf.ooo_dispatch_hist[2]);
  LogBothTag("statistic", "fetch req valid/fire = %llu/%llu, rsp fire=%llu, enqueue=%llu, bypass=%llu",
             (unsigned long long)g_sim_perf.ooo_fetch_req_valid,
             (unsigned long long)g_sim_perf.ooo_fetch_req_fire,
             (unsigned long long)g_sim_perf.ooo_fetch_rsp_fire,
             (unsigned long long)g_sim_perf.ooo_fetch_rsp_enqueue,
             (unsigned long long)g_sim_perf.ooo_fetch_rsp_bypass);
  LogBothTag("statistic", "control wait cycles: stop=%llu, branch=%llu, jump=%llu, mem=%llu, synth-ret=%llu, commit1-block=%llu",
             (unsigned long long)g_sim_perf.ooo_stop_pending_cycles,
             (unsigned long long)g_sim_perf.ooo_pending_branch_cycles,
             (unsigned long long)g_sim_perf.ooo_pending_jump_cycles,
             (unsigned long long)g_sim_perf.ooo_pending_mem_cycles,
             (unsigned long long)g_sim_perf.ooo_synth_ret_pending_cycles,
             (unsigned long long)g_sim_perf.ooo_commit1_block_cycles);
  LogBothTag("statistic", "branch prefetch fire/hit = %llu/%llu",
             (unsigned long long)g_sim_perf.ooo_branch_prefetch_fire,
             (unsigned long long)g_sim_perf.ooo_branch_prefetch_hit);
  LogBothTag("statistic", "top branch wait PCs =");
  npc_word_t branch_wait_pc[kTopBranchWaitPcCount];
  uint64_t branch_wait_cycles[kTopBranchWaitPcCount];
  memcpy(branch_wait_pc, g_sim_perf.ooo_branch_wait_pc,
         sizeof(branch_wait_pc));
  memcpy(branch_wait_cycles, g_sim_perf.ooo_branch_wait_pc_cycles,
         sizeof(branch_wait_cycles));
  for (uint32_t rank = 0; rank < kTopBranchWaitPcCount; rank++) {
    uint32_t best_idx = kTopBranchWaitPcCount;
    uint64_t best_count = 0;
    for (uint32_t i = 0; i < kTopBranchWaitPcCount; i++) {
      if (branch_wait_cycles[i] > best_count) {
        best_count = branch_wait_cycles[i];
        best_idx = i;
      }
    }
    if (best_idx == kTopBranchWaitPcCount || best_count == 0) break;
    LogBothTag("statistic", "  pc=0x%016llx cycles=%llu",
               (unsigned long long)branch_wait_pc[best_idx],
               (unsigned long long)best_count);
    branch_wait_cycles[best_idx] = 0;
  }
  LogBothTag("statistic", "top jump wait PCs =");
  npc_word_t jump_wait_pc[kTopBranchWaitPcCount];
  uint64_t jump_wait_cycles[kTopBranchWaitPcCount];
  memcpy(jump_wait_pc, g_sim_perf.ooo_jump_wait_pc, sizeof(jump_wait_pc));
  memcpy(jump_wait_cycles, g_sim_perf.ooo_jump_wait_pc_cycles,
         sizeof(jump_wait_cycles));
  for (uint32_t rank = 0; rank < kTopBranchWaitPcCount; rank++) {
    uint32_t best_idx = kTopBranchWaitPcCount;
    uint64_t best_count = 0;
    for (uint32_t i = 0; i < kTopBranchWaitPcCount; i++) {
      if (jump_wait_cycles[i] > best_count) {
        best_count = jump_wait_cycles[i];
        best_idx = i;
      }
    }
    if (best_idx == kTopBranchWaitPcCount || best_count == 0) break;
    LogBothTag("statistic", "  pc=0x%016llx cycles=%llu",
               (unsigned long long)jump_wait_pc[best_idx],
               (unsigned long long)best_count);
    jump_wait_cycles[best_idx] = 0;
  }
  LogBothTag("statistic", "mem req0/req1/rsp0/rsp1 = %llu/%llu/%llu/%llu",
             (unsigned long long)g_sim_perf.ooo_mem0_req_fire,
             (unsigned long long)g_sim_perf.ooo_mem1_req_fire,
             (unsigned long long)g_sim_perf.ooo_mem0_rsp_fire,
             (unsigned long long)g_sim_perf.ooo_mem1_rsp_fire);
}

// NEMU 风格统计 + CPI + 分支统计，NPC 跑分结果可直接和参考模型对比
static void report_statistics(void) {
  char mtime_delta[48];
  format_u64_delta(mtime_delta, sizeof(mtime_delta),
                   npc_stats()->clint_mtime, npc_stats()->cycles);

  LogBothTag("statistic", "host time spent = %llu us",
          (unsigned long long)npc_stats()->host_time_us);
  LogBothTag("statistic", "total guest instructions = %llu",
          (unsigned long long)npc_stats()->commits);
  // 新增 cycles 和 CPI 输出，对齐参考工程的统计格式
  LogBothTag("statistic", "total guest cycles = %llu",
          (unsigned long long)npc_stats()->cycles);
  LogBothTag("statistic", "CLINT mtime = %llu (mtime-cycles=%s, match=%s)",
          (unsigned long long)npc_stats()->clint_mtime,
          mtime_delta,
          (npc_stats()->clint_mtime == npc_stats()->cycles) ? "yes" : "no");
  if (npc_stats()->commits > 0) {
    LogBothTag("statistic", "CPI (cycles/instruction) = %.3f",
            (double)npc_stats()->cycles / (double)npc_stats()->commits);
  }
  if (npc_stats()->host_time_us > 0) {
    LogBothTag("statistic", "simulation frequency = %llu inst/s",
            (unsigned long long)simulation_frequency());
  } else {
    LogBothTag("statistic", "Finish running in less than 1 us and can not calculate the simulation frequency");
  }
  report_branch_stats();
  report_cache_stats();
  report_ooo_stats();
}

static void report_recent_commits(void) {
  if (g_recent_commit_count == 0) return;
  uint64_t start = (g_recent_commit_count > kRecentCommitRingSize)
                       ? (g_recent_commit_count - kRecentCommitRingSize)
                       : 0;
  LogBothTag("cpu_exec", "recent commits before stop:");
  for (uint64_t seq = start; seq < g_recent_commit_count; ++seq) {
    uint32_t slot = (uint32_t)(seq % kRecentCommitRingSize);
    const CommitEvent &event = g_recent_commits[slot];
    if (!event.valid || g_recent_commit_seq[slot] != seq) continue;
    if (event.rd_en) {
      LogBothTag("cpu_exec",
                 "  #%llu pc=0x%016" NPC_PRIxWORD " inst=0x%08x next=0x%016" NPC_PRIxWORD
                 " x%u(%s)<=0x%016" NPC_PRIxWORD,
                 (unsigned long long)seq, event.pc, event.inst,
                 event.next_pc, event.rd_addr, kRegNames[event.rd_addr],
                 event.rd_data);
    } else {
      LogBothTag("cpu_exec",
                 "  #%llu pc=0x%016" NPC_PRIxWORD " inst=0x%08x next=0x%016" NPC_PRIxWORD,
                 (unsigned long long)seq, event.pc, event.inst,
                 event.next_pc);
    }
  }
}

static void report_recent_debug_cycles(void) {
  if (g_recent_debug_count == 0) return;
  uint64_t start = (g_recent_debug_count > kRecentDebugRingSize)
                       ? (g_recent_debug_count - kRecentDebugRingSize)
                       : 0;
  LogBothTag("cpu_exec", "recent debug cycles before stop:");
  for (uint64_t seq = start; seq < g_recent_debug_count; ++seq) {
    uint32_t slot = (uint32_t)(seq % kRecentDebugRingSize);
    const DebugCycleEvent &event = g_recent_debug[slot];
    if (!event.valid) continue;
    uint64_t flags = event.flags;
    uint64_t bus = event.bus;
    LogBothTag("cpu_exec",
               "  cyc=%llu commits=%llu pc=0x%016" NPC_PRIxWORD
               " state=%u stop=%llu arch=%llu sys=%llu trap_ex=%llu cause=%llu "
               "fifo=%llu fetch_state=%llu frsp=%llu/%llu out=%llu ifu_ar=%llu/%llu "
               "ifu_r=%llu/%llu active=0x%04llx ar_sent=0x%04llx fetch_addr=0x%016llx "
               "mem_addr=0x%016llx pte_addr=0x%016llx pte=0x%016llx pte_meta=0x%llx",
               (unsigned long long)event.cycle,
               (unsigned long long)event.commits,
               event.pc,
               event.state,
               (unsigned long long)((flags >> 0) & 1u),
               (unsigned long long)((flags >> 7) & 1u),
               (unsigned long long)((flags >> 8) & 1u),
               (unsigned long long)((flags >> 36) & 1u),
               (unsigned long long)((flags >> 21) & 0x3fu),
               (unsigned long long)((flags >> 20) & 1u),
               (unsigned long long)((bus >> 6) & 0xfu),
               (unsigned long long)((bus >> 2) & 1u),
               (unsigned long long)((bus >> 3) & 1u),
               (unsigned long long)((bus >> 4) & 1u),
               (unsigned long long)((bus >> 21) & 1u),
               (unsigned long long)((bus >> 22) & 1u),
               (unsigned long long)((bus >> 23) & 1u),
               (unsigned long long)((bus >> 24) & 1u),
               (unsigned long long)((bus >> 39) & 0xffffu),
               (unsigned long long)((event.bus2 >> 12) & 0xffffu),
               (unsigned long long)event.fetch_addr,
               (unsigned long long)event.mem_addr,
               (unsigned long long)event.fetch_pte_addr,
               (unsigned long long)event.fetch_pte,
               (unsigned long long)event.fetch_pte_meta);
  }
}

static void report_ooo_debug_flags(void) {
  uint64_t flags = g_top ? (uint64_t)g_top->debug_ooo_flags_o : 0;
  uint64_t bus = g_top ? (uint64_t)g_top->debug_bus_flags_o : 0;
  uint64_t bus2 = g_top ? (uint64_t)g_top->debug_bus2_flags_o : 0;
  uint64_t fetch_addr = g_top ? (uint64_t)g_top->debug_fetch_addr_o : 0;
  uint64_t mem_addr = g_top ? (uint64_t)g_top->debug_mem_addr_o : 0;
  uint64_t fetch_pte_addr = g_top ? (uint64_t)g_top->debug_fetch_pte_addr_o : 0;
  uint64_t fetch_pte = g_top ? (uint64_t)g_top->debug_fetch_pte_o : 0;
  uint64_t fetch_pte_meta = g_top ? (uint64_t)g_top->debug_fetch_pte_meta_o : 0;
  LogBothTag("cpu_exec",
             "ooo flags=0x%06llx stop=%llu owner=%llu orphan=%llu exit=%llu branch=%llu "
             "jump=%llu mem=%llu arch_trap=%llu system=%llu irq=%llu csr=%llu "
             "csr_dispatched=%llu irq_pending=%llu drained_q=%llu drained=%llu "
             "dispatch_ready=%llu csr_dispatch_valid=%llu csr_dispatch_fire=%llu "
             "csr_commit=%llu can_run=%llu fifo=%llu trap_cause=%llu head_resp=%llu "
             "head_fetch_fault=%llu dispatch_arch_trap=%llu csr_illegal=%llu dispatch_system=%llu "
             "priv=%llu satp_sv39=%llu arch_trap_fire=%llu csr_trap_ex=%llu drain_complete=%llu "
             "replay_wait=%llu direct_flush=%llu",
             (unsigned long long)flags,
             (unsigned long long)((flags >> 0) & 1u),
             (unsigned long long)((flags >> 1) & 1u),
             (unsigned long long)((flags >> 2) & 1u),
             (unsigned long long)((flags >> 3) & 1u),
             (unsigned long long)((flags >> 4) & 1u),
             (unsigned long long)((flags >> 5) & 1u),
             (unsigned long long)((flags >> 6) & 1u),
             (unsigned long long)((flags >> 7) & 1u),
             (unsigned long long)((flags >> 8) & 1u),
             (unsigned long long)((flags >> 9) & 1u),
             (unsigned long long)((flags >> 10) & 1u),
             (unsigned long long)((flags >> 11) & 1u),
             (unsigned long long)((flags >> 12) & 1u),
             (unsigned long long)((flags >> 13) & 1u),
             (unsigned long long)((flags >> 14) & 1u),
             (unsigned long long)((flags >> 15) & 1u),
             (unsigned long long)((flags >> 16) & 1u),
             (unsigned long long)((flags >> 17) & 1u),
             (unsigned long long)((flags >> 18) & 1u),
             (unsigned long long)((flags >> 19) & 1u),
             (unsigned long long)((flags >> 20) & 1u),
             (unsigned long long)((flags >> 21) & 0x3fu),
             (unsigned long long)((flags >> 27) & 0x3u),
             (unsigned long long)((flags >> 29) & 1u),
             (unsigned long long)((flags >> 30) & 1u),
             (unsigned long long)((flags >> 31) & 1u),
             (unsigned long long)((flags >> 32) & 1u),
             (unsigned long long)((flags >> 33) & 0x3u),
             (unsigned long long)((flags >> 35) & 1u),
             (unsigned long long)((flags >> 36) & 1u),
             (unsigned long long)((flags >> 37) & 1u),
             (unsigned long long)((flags >> 38) & 1u),
             (unsigned long long)((flags >> 39) & 1u),
             (unsigned long long)((flags >> 40) & 1u));
  LogBothTag("cpu_exec",
             "bus flags=0x%016llx fetch_req=%llu/%llu fetch_rsp=%llu/%llu "
             "out=%llu discard=%llu fetch_state=%llu paging=%llu wl=%llu ws=%llu "
             "mem_state=%llu mem_wr=%llu mem_port=%llu mem_drop=%llu "
             "ifu_ar=%llu/%llu ifu_r=%llu/%llu lsu_ar=%llu/%llu lsu_r=%llu/%llu "
             "lsu_aw=%llu/%llu lsu_w=%llu/%llu lsu_b=%llu/%llu "
             "xbar_busy=0x%llx xbar_resp=0x%llx xbar_active=0x%llx",
             (unsigned long long)bus,
             (unsigned long long)((bus >> 0) & 1u),
             (unsigned long long)((bus >> 1) & 1u),
             (unsigned long long)((bus >> 2) & 1u),
             (unsigned long long)((bus >> 3) & 1u),
             (unsigned long long)((bus >> 4) & 1u),
             (unsigned long long)((bus >> 5) & 1u),
             (unsigned long long)((bus >> 6) & 0xfu),
             (unsigned long long)((bus >> 10) & 1u),
             (unsigned long long)((bus >> 11) & 0x3u),
             (unsigned long long)((bus >> 13) & 1u),
             (unsigned long long)((bus >> 14) & 0xfu),
             (unsigned long long)((bus >> 18) & 1u),
             (unsigned long long)((bus >> 19) & 1u),
             (unsigned long long)((bus >> 20) & 1u),
             (unsigned long long)((bus >> 21) & 1u),
             (unsigned long long)((bus >> 22) & 1u),
             (unsigned long long)((bus >> 23) & 1u),
             (unsigned long long)((bus >> 24) & 1u),
             (unsigned long long)((bus >> 25) & 1u),
             (unsigned long long)((bus >> 26) & 1u),
             (unsigned long long)((bus >> 27) & 1u),
             (unsigned long long)((bus >> 28) & 1u),
             (unsigned long long)((bus >> 29) & 1u),
             (unsigned long long)((bus >> 30) & 1u),
             (unsigned long long)((bus >> 31) & 1u),
             (unsigned long long)((bus >> 32) & 1u),
             (unsigned long long)((bus >> 33) & 1u),
             (unsigned long long)((bus >> 34) & 1u),
             (unsigned long long)((bus >> 35) & 0x3u),
             (unsigned long long)((bus >> 37) & 0x3u),
             (unsigned long long)((bus >> 39) & 0xffffu));
  LogBothTag("cpu_exec",
             "bus2=0x%016llx mmu_flush=%llu mem_flush=%llu ifu_abort=%llu lsu_abort=%llu "
             "sram_ar=%llu/%llu sram_r=%llu/%llu owners clint/uart/sram/default=%llu/%llu/%llu/%llu "
             "xbar_ar_sent=0x%04llx xbar_drop=0x%04llx fetch_addr=0x%016llx"
             " mem_addr=0x%016llx pte_addr=0x%016llx pte=0x%016llx pte_meta=0x%llx",
             (unsigned long long)bus2,
             (unsigned long long)((bus2 >> 0) & 1u),
             (unsigned long long)((bus2 >> 1) & 1u),
             (unsigned long long)((bus2 >> 2) & 1u),
             (unsigned long long)((bus2 >> 3) & 1u),
             (unsigned long long)((bus2 >> 4) & 1u),
             (unsigned long long)((bus2 >> 5) & 1u),
             (unsigned long long)((bus2 >> 6) & 1u),
             (unsigned long long)((bus2 >> 7) & 1u),
             (unsigned long long)((bus2 >> 8) & 1u),
             (unsigned long long)((bus2 >> 9) & 1u),
             (unsigned long long)((bus2 >> 10) & 1u),
             (unsigned long long)((bus2 >> 11) & 1u),
             (unsigned long long)((bus2 >> 12) & 0xffffu),
             (unsigned long long)((bus2 >> 28) & 0xffffu),
             fetch_addr, mem_addr, fetch_pte_addr, fetch_pte, fetch_pte_meta);
}

static void report_run_result(void) {
  NpcState *st = npc_state();
  switch (st->state) {
    case NPC_END: {
      const char *trap_text = (st->halt_ret == 0)
          ? (ANSI_FG_GREEN "HIT GOOD TRAP" ANSI_NONE)
          : (ANSI_FG_RED   "HIT BAD TRAP"  ANSI_NONE);
      LogBothTag("cpu_exec", "npc: %s at pc = 0x%016" NPC_PRIxWORD, trap_text, st->halt_pc);
      LogBoth("exit via %s, code=%" PRIu64 ", cycles=%llu, commits=%llu",
              st->exit_is_ebreak ? "ebreak" : (st->exit_is_ecall ? "ecall" : "unknown"),
              (uint64_t)st->halt_ret,
              (unsigned long long)npc_stats()->cycles,
              (unsigned long long)npc_stats()->commits);
      report_statistics();
      return;
    }
    case NPC_TRAP:
      LogBothTag("cpu_exec", "npc: %s at pc = 0x%016" NPC_PRIxWORD, ANSI_FG_RED "TRAP" ANSI_NONE, st->halt_pc);
      LogBoth("trap cause=%u tval=0x%016" NPC_PRIxWORD ", cycles=%llu, commits=%llu",
              st->trap_cause, st->trap_tval,
              (unsigned long long)npc_stats()->cycles,
              (unsigned long long)npc_stats()->commits);
      report_ooo_debug_flags();
      report_recent_debug_cycles();
      report_recent_commits();
      report_statistics();
      return;
    case NPC_ABORT:
      LogBothTag("cpu_exec", "npc: %s at pc = 0x%016" NPC_PRIxWORD, ANSI_FG_RED "ABORT" ANSI_NONE, st->halt_pc);
      LogBoth("cycles=%llu, commits=%llu, core-state=0x%08x",
              (unsigned long long)npc_stats()->cycles,
              (unsigned long long)npc_stats()->commits,
              npc_cpu_state_bits());
      report_ooo_debug_flags();
      report_recent_debug_cycles();
      report_recent_commits();
      report_statistics();
      return;
    case NPC_QUIT:
      LogBoth("npc: quit");
      report_statistics();
      return;
    default:
      return;
  }
}

/* ---- 仿真步进 ---- */

static void eval_half_cycle(uint8_t clk_level) {
  g_top->clk = clk_level;
  g_top->eval();
#if VM_TRACE
  if (g_trace_file) {
    g_trace_file->dump(npc_stats()->sim_time);
  }
#endif
  ++npc_stats()->sim_time;
}

static void step_cycle(void) {
  clear_cycle_events();
  npc_device_update();
  eval_half_cycle(0);
  eval_half_cycle(1);
  ++npc_stats()->cycles;
  // 在完整 posedge 之后采样 Verilator 顶层调试口，和同一拍的 DPIC cycles 计数对齐。
  npc_stats()->clint_mtime = g_top->debug_clint_mtime_o;
  npc_stats()->commits += g_commit_event_count;
  remember_debug_cycle();
}

static void apply_reset(void) {
  g_top->rst = 1;
  g_top->clk = 0;
  for (int i = 0; i < 5; ++i) step_cycle();
  g_top->rst = 0;
  /* 对齐参考工程：复位完成后打印 ***reset*** 标记 */
  printf("***reset***\n");
  // VCD 时间必须单调，只重置统计量，保留 trace 时间轴
  uint64_t trace_time = npc_stats()->sim_time;
  memset(npc_stats(), 0, sizeof(NpcStats));
  npc_stats()->sim_time = trace_time;
  clear_runtime_state();
  // 复位时清零分支/跳转计数器，确保统计只反映本次运行
  g_nr_branch = g_nr_branch_taken = g_nr_jal = g_nr_jalr = 0;
  reset_event_state();
}

/* ---- 状态报告 ---- */

static void report_exit(void) {
  NpcState *st = npc_state();
  st->state = NPC_END;
  st->halt_pc = g_exit_event.valid ? g_exit_event.pc : g_top->debug_pc_o;
  st->halt_ret = g_exit_event.valid ? g_exit_event.code : 1;
  st->exit_is_ebreak = g_exit_event.valid && g_exit_event.is_ebreak;
  st->exit_is_ecall = g_exit_event.valid && g_exit_event.is_ecall;
}

static void report_trap(void) {
  NpcState *st = npc_state();
  st->state = NPC_TRAP;
  st->halt_pc = g_trap_event.valid ? g_trap_event.pc : g_top->debug_pc_o;
  st->trap_cause = g_trap_event.valid ? g_trap_event.cause : 0;
  st->trap_tval = g_trap_event.valid ? g_trap_event.tval : 0;
}

static void report_timeout(void) {
  NpcState *st = npc_state();
  st->state = NPC_ABORT;
  st->halt_pc = g_top->debug_pc_o;
}

static void report_interrupt(void) {
  npc_state()->state = NPC_STOP;
  npc_log_plain("\n[npc] execution interrupted at pc=0x%016" NPC_PRIxWORD " after %llu cycles\n",
                g_top->debug_pc_o, (unsigned long long)npc_stats()->cycles);
}

static int reg_index_from_name(const char *name) {
  if (!name) return -1;
  if (strcmp(name, "pc") == 0) return 32;
  if (name[0] == 'x') {
    char *end = nullptr;
    long val = strtol(name + 1, &end, 10);
    if (end && *end == '\0' && val >= 0 && val < 32) return (int)val;
  }
  for (int i = 0; i < 32; ++i) {
    if (strcmp(name, kRegNames[i]) == 0) return i;
  }
  return -1;
}

/* finish_exec 替代原来的 lambda：收尾统计 + 有条件输出报告 */
static int finish_exec(uint64_t start_us, int ret, bool report_summary) {
  accumulate_host_time(start_us);
  if (report_summary) report_run_result();
  return ret;
}

/* ---- 对外 extern "C" 接口 ---- */

bool npc_init_cpu(int argc, char **argv, const NpcSimConfig *config) {
  Verilated::commandArgs(argc, argv);
  g_cycle_limit       = config->max_cycles;
  g_progress_interval = config->progress_interval;
  if (!install_sigint_handler()) {
    perror("[npc] sigaction(SIGINT)");
    return false;
  }
  g_top = std::make_unique<VNpcSimTop>();
  if (!g_top) return false;

#if VM_TRACE
  if (config->trace) {
    Verilated::traceEverOn(true);
    g_trace_file = std::make_unique<VerilatedVcdC>();
    g_top->trace(g_trace_file.get(), 99);
    g_trace_file->open(config->trace_path);
  }
#else
  if (config->trace) {
    fprintf(stderr, "[npc] warning: --trace requested but binary built without VCD support.\n"
                    "      Rebuild with 'make TRACE=1' or enable CONFIG_NPC_TRACE_BY_DEFAULT.\n");
  }
#endif
  // 初始化阶段复位，后续 si/c 在同一颗已上电核上推进
  apply_reset();
  if (!npc_init_difftest(config)) return false;
  return true;
}

int npc_cpu_exec(uint64_t max_instructions) {
  if (!g_top) return 1;

  NpcState *st = npc_state();
  if (st->state == NPC_END || st->state == NPC_TRAP || st->state == NPC_ABORT) {
    printf("[npc] core already stopped in state=%s, reset to restart.\n",
           npc_state_name(st->state));
    return (st->state == NPC_END) ? (int)st->halt_ret : 1;
  }
  if (max_instructions == 0) { st->state = NPC_STOP; return 0; }

  g_stop_requested = 0;
  st->state = NPC_RUNNING;
  st->watchpoint_id = -1;
  st->watchpoint_expr[0] = '\0';

  uint64_t timer_start_us = npc_get_time_us();
  uint64_t executed = 0;
  ProgressReporter progress = make_progress_reporter(max_instructions);

  // 运行循环：推进周期、记录提交、接住退出/异常
  while (!Verilated::gotFinish()) {
    if (npc_consume_sigint_request()) {
      report_interrupt();
      return finish_exec(timer_start_us, 0, false);
    }
    if (npc_cycle_limit_enabled(g_cycle_limit) && npc_stats()->cycles >= g_cycle_limit) {
      report_timeout();
      return finish_exec(timer_start_us, 2, true);
    }

    step_cycle();

    if (g_exit_event.valid) {
      report_exit();
      return finish_exec(timer_start_us, (int)st->halt_ret, true);
    }
    if (g_trap_event.valid) {
      report_trap();
      return finish_exec(timer_start_us, 1, true);
    }

    if (g_commit_event_count > 0) {
      for (uint32_t commit_idx = 0; commit_idx < g_commit_event_count; ++commit_idx) {
        const CommitEvent &event = g_commit_events[commit_idx];
        if (!event.valid) continue;

        ++executed;
        trace_commit(event);
#if CONFIG_NPC_DIFFTEST
        if (npc_difftest_enabled()) {
          if (!npc_difftest_step(event.pc, event.inst,
                                 event.next_pc, event.gpr_after,
                                 event.rd_en, event.rd_addr,
                                 event.rd_data)) {
            st->state = NPC_ABORT;
            st->halt_pc = event.pc;
            return finish_exec(timer_start_us, 1, true);
          }
        }
#endif
        if (npc_check_watchpoints())
          return finish_exec(timer_start_us, 0, false);
        maybe_report_progress(&progress);
      }

      if (executed >= max_instructions) {
        // 多走一个不提交周期让 PC 前推，接近 NEMU si 观感
        if (!Verilated::gotFinish() &&
            (!npc_cycle_limit_enabled(g_cycle_limit) || npc_stats()->cycles < g_cycle_limit)) {
          step_cycle();
          if (g_exit_event.valid) { report_exit(); return finish_exec(timer_start_us, (int)st->halt_ret, true); }
          if (g_trap_event.valid) { report_trap(); return finish_exec(timer_start_us, 1, true); }
        }
        st->state = NPC_STOP;
        return finish_exec(timer_start_us, 0, false);
      }
    }
    if (st->state == NPC_QUIT)
      return finish_exec(timer_start_us, 0, true);
  }

  if (Verilated::gotFinish()) {
    st->state = NPC_QUIT;
    return finish_exec(timer_start_us, 0, true);
  }
  report_timeout();
  return finish_exec(timer_start_us, 2, true);
}

void npc_cpu_reg_display(void) {
  if (!g_top) { printf("NPC core is not initialized.\n"); return; }
  for (int i = 0; i < 32; ++i) {
    printf("x%-2d %-4s 0x%016" NPC_PRIxWORD "%s", i, kRegNames[i], debug_reg_value(i),
           ((i + 1) % 4 == 0) ? "\n" : "    ");
  }
  if (32 % 4 != 0) printf("\n");
  printf("pc      0x%016" NPC_PRIxWORD "\n", (npc_word_t)g_top->debug_pc_o);
}

void npc_cpu_info_display(void) {
  NpcState *st = npc_state();
  printf("state    : %s\n", npc_state_name(st->state));
  printf("pc       : 0x%016" NPC_PRIxWORD "\n", npc_cpu_pc());
  printf("core     : 0x%08x\n", npc_cpu_state_bits());
  printf("cycles   : %llu\n", (unsigned long long)npc_stats()->cycles);
  printf("mtime    : %llu\n", (unsigned long long)npc_stats()->clint_mtime);
  printf("commits  : %llu\n", (unsigned long long)npc_stats()->commits);
  printf("host-us  : %llu\n", (unsigned long long)npc_stats()->host_time_us);
  if (npc_stats()->host_time_us > 0)
    printf("inst/s   : %llu\n", (unsigned long long)simulation_frequency());
}

bool npc_isa_reg_str2val(const char *name, npc_word_t *value) {
  if (!value) return false;
  /* 小写化到栈缓冲区，替代 std::string */
  char lowered[64] = {};
  if (name) {
    size_t len = strlen(name);
    if (len >= sizeof(lowered)) len = sizeof(lowered) - 1;
    for (size_t i = 0; i < len; ++i)
      lowered[i] = (char)tolower((unsigned char)name[i]);
  }
  int idx = reg_index_from_name(lowered);
  if (idx < 0) return false;
  if (idx == 32) { *value = npc_cpu_pc(); return true; }
  return npc_cpu_read_reg(idx, value);
}

bool npc_cpu_read_reg(int index, npc_word_t *value) {
  if (!g_top || !value || index < 0 || index >= 32) return false;
  *value = debug_reg_value(index);
  return true;
}

npc_word_t npc_cpu_pc(void) {
  return g_top ? g_top->debug_pc_o : NPC_RESET_PC;
}

uint32_t npc_cpu_state_bits(void) {
  return g_top ? g_top->debug_state_o : 0;
}

bool npc_consume_sigint_request(void) {
  if (g_stop_requested == 0) return false;
  g_stop_requested = 0;
  return true;
}

void npc_fini_cpu(void) {
  if (g_top) g_top->final();
#if VM_TRACE
  if (g_trace_file) { g_trace_file->close(); g_trace_file.reset(); }
#endif
  npc_fini_disasm();
  npc_fini_difftest();
  g_top.reset();
}
