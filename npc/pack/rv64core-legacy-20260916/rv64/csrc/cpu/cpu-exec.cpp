#if defined(CONFIG_NPC_OOO_STATS) && !defined(CONFIG_NPC_SIM_STATS)
// Match NpcSimTop's file-local build closure for manual OOO-only builds.
// Normal Kconfig builds already select SIM_STATS before OOO_STATS.
#define CONFIG_NPC_SIM_STATS 1
#endif

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
static bool g_tohost_enabled = false;
static npc_paddr_t g_tohost_addr = 0;

struct CommitEvent {
  bool     valid;
  npc_word_t pc;
  uint32_t inst;
  npc_word_t next_pc;
  bool     rd_en;
  uint32_t rd_addr;
  npc_word_t rd_data;
  npc_word_t gpr_after[32];
  npc_word_t csr[NPC_DIFF_CSR_N];   // 全状态 difftest: 本条提交后的 CSR+priv 快照
  uint64_t   fpr[NPC_DIFF_FPR_N];   // 阶段2: 本条提交后的 arch FPR 快照
};

struct ExitEvent {
  bool     valid;
  bool     is_ebreak;
  bool     is_ecall;
  bool     is_system_reset;
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
  uint64_t mem_diag;
  uint64_t fetch_pte_addr;
  uint64_t fetch_pte;
  uint64_t fetch_pte_meta;
};

static constexpr uint32_t kMaxCommitEventsPerCycle = 2;
static constexpr uint32_t kRecentCommitRingSize = 32;
static constexpr uint32_t kRecentDebugRingSize = 32;
static constexpr uint32_t kTopBranchWaitPcCount = 8;

enum RetireObservationReason : uint32_t {
  RETIRE_REASON_RETIRED = 0,
  RETIRE_REASON_ROB_EMPTY = 1,
  RETIRE_REASON_DEPENDENCY = 2,
  RETIRE_REASON_ISSUE_TERMINAL = 3,
  RETIRE_REASON_EXECUTION_LATENCY = 4,
  RETIRE_REASON_MEMORY_RESERVATION_QUEUE = 5,
  RETIRE_REASON_MEMORY_TRANSLATION_ORDER = 6,
  RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING = 7,
  RETIRE_REASON_MEMORY_RESPONSE_TERMINAL = 8,
  RETIRE_REASON_MEMORY_RETRY = 9,
  RETIRE_REASON_MEMORY_LIFECYCLE_UNKNOWN = 10,
  RETIRE_REASON_HEAD_LIFECYCLE_UNKNOWN = 11,
  RETIRE_REASON_EXCEPTION_REDIRECT = 12,
  RETIRE_REASON_MEMORY_COMMIT = 13,
  RETIRE_REASON_SERIALIZATION = 14,
  RETIRE_REASON_UNKNOWN = 15,
  RETIRE_REASON_COUNT = 16,
};

enum MemoryRequestDetail : uint32_t {
  MEMORY_REQUEST_DETAIL_NONE = 0,
  MEMORY_REQUEST_DETAIL_CACHE_LOOKUP = 1,
  MEMORY_REQUEST_DETAIL_DEVICE_WAIT = 2,
  MEMORY_REQUEST_DETAIL_AXI_READ_ADDRESS = 3,
  MEMORY_REQUEST_DETAIL_AXI_READ_DATA = 4,
  MEMORY_REQUEST_DETAIL_AXI_WRITE_REQUEST = 5,
  MEMORY_REQUEST_DETAIL_AXI_WRITE_RESPONSE = 6,
  MEMORY_REQUEST_DETAIL_UNKNOWN = 7,
  MEMORY_REQUEST_DETAIL_COUNT = 8,
};

struct RetireObservationStats {
  uint64_t cycle_reason[RETIRE_REASON_COUNT];
  uint64_t slot_reason[RETIRE_REASON_COUNT];
  uint64_t cycle_request_detail[MEMORY_REQUEST_DETAIL_COUNT];
  uint64_t slot_request_detail[MEMORY_REQUEST_DETAIL_COUNT];
  uint32_t current_slot_reason[2];
  uint32_t current_slot_request_detail[2];
  uint64_t current_cycle;
  uint64_t invalid_events;
  bool current_valid;
  bool current_invalid;
  bool current_overflow;
  bool overflow;
};

struct RetireObservationSnapshot {
  uint64_t cycle_reason[RETIRE_REASON_COUNT];
  uint64_t slot_reason[RETIRE_REASON_COUNT];
  uint64_t cycle_request_detail[MEMORY_REQUEST_DETAIL_COUNT];
  uint64_t slot_request_detail[MEMORY_REQUEST_DETAIL_COUNT];
  uint32_t current_slot_reason[2];
  uint32_t current_slot_request_detail[2];
  uint64_t event_cycle;
  uint64_t invalid_events;
  bool available;
  bool current_invalid;
  bool current_overflow;
  bool overflow;
};

struct SqIdleFusionCounters {
  uint64_t cycles;
  uint64_t prequal;
  uint64_t exact;
  uint64_t allow;
  uint64_t forward;
  uint64_t replay;
  uint64_t invalid;
  uint64_t allow_rob_head;
};

struct SqIdleFusionState {
  SqIdleFusionCounters counters;
  uint64_t current_cycle;
  bool current_valid;
  bool encoding_malformed;
  bool sequence_malformed;
  bool overflow;
};

struct SqIdleFusionSnapshot {
  SqIdleFusionCounters counters;
  uint64_t event_cycle;
  bool available;
  bool malformed;
  bool overflow;
};

static CommitEvent g_commit_events[kMaxCommitEventsPerCycle] = {};
static uint32_t    g_commit_event_count = 0;
static CommitEvent g_recent_commits[kRecentCommitRingSize] = {};
static uint64_t    g_recent_commit_seq[kRecentCommitRingSize] = {};
static uint64_t    g_recent_commit_count = 0;
static DebugCycleEvent g_recent_debug[kRecentDebugRingSize] = {};
static uint64_t    g_recent_debug_count = 0;
static ExitEvent   g_exit_event   = {};
static TrapEvent   g_trap_event   = {};
struct RegionProbeState {
  bool enabled;
  bool start_seen;
  bool end_seen;
  bool final_emitted;
  npc_word_t start_pc;
  npc_word_t end_pc;
  uint64_t start_pc_hits;
  uint64_t end_pc_hits;
  uint64_t start_cycle;
  uint64_t end_cycle;
  uint64_t start_retired;
  uint64_t end_retired;
  uint32_t start_lane;
  uint32_t end_lane;
  RetireObservationSnapshot start_counter;
  RetireObservationSnapshot end_counter;
  SqIdleFusionSnapshot start_sq_idle_fusion;
  SqIdleFusionSnapshot end_sq_idle_fusion;
};
static RegionProbeState g_region_probe = {};
static RetireObservationStats g_retire_observation = {};
static SqIdleFusionState g_sq_idle_fusion = {};
static npc_word_t  g_shadow_gpr[32] = {};
static uint64_t    g_shadow_fpr[32] = {};   // 阶段2 FPR shadow: 逐提交精确 FP arch 值(对称 GPR)
// 全状态 difftest: 本拍 CSR+priv 快照(NpcSimTop 每 commit 拍经 npc_arch_csr_event XMR 更新)。
static npc_word_t  g_dut_csr_live[NPC_DIFF_CSR_N] = {};
static uint64_t    g_dut_fpr_live[NPC_DIFF_FPR_N] = {};   // 阶段2(旧): arch FPR 快照(改用 shadow 后弃用)
static bool        g_commit_watch_inited = false;
static bool        g_commit_watch_enabled = false;
static npc_word_t  g_commit_watch_start = 0;
static npc_word_t  g_commit_watch_end = 0;
static uint64_t    g_commit_watch_min_commit = 0;
static uint64_t    g_commit_watch_max_commit = UINT64_MAX;
static bool        g_commit_watch_stop_on_match = false;
static uint64_t    g_commit_watch_stop_after = 1;
static uint64_t    g_commit_watch_match_count = 0;
static uint64_t    g_commit_watch_post_cycles = 0;
static bool        g_commit_watch_post_active = false;
static uint64_t    g_commit_watch_post_deadline = 0;
static bool        g_commit_watch_matched = false;
static bool        g_trap_watch_inited = false;
static bool        g_trap_watch_enabled = false;
static bool        g_user_trace_inited = false;
static bool        g_user_ecall_trace_enabled = false;
static bool        g_user_ecall_trace_priv_enabled = false;
static bool        g_user_progress_enabled = false;
static bool        g_user_ecall_path_trace_enabled = false;
static uint64_t    g_user_trace_min_commit = 0;
static uint64_t    g_user_ecall_min_commit = 0;
static uint64_t    g_user_ecall_trace_limit = 128;
static uint64_t    g_user_ecall_path_max = 96;
static uint64_t    g_user_progress_interval = 0;
static uint64_t    g_user_progress_limit = 64;
static uint64_t    g_user_ecall_trace_count = 0;
static uint64_t    g_user_progress_count = 0;
static uint64_t    g_user_progress_next_commit = 0;

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
  uint64_t ooo_fetch_busy_cycles;
  uint64_t ooo_mem_busy_cycles;
  uint64_t ooo_axi_wait_cycles;
  uint64_t ooo_hazard_busy_cycles;
  uint64_t ooo_branch_flush_cycles;
  uint64_t ooo_exception_busy_cycles;
  // OooTensorRobSidecar already owns these cumulative counters.  The host
  // stores a post-posedge RTL snapshot instead of summing it again.
  uint64_t ooo_tensor_issued_count;
  uint64_t ooo_tensor_terminal_count;
  uint64_t ooo_tensor_completion_count;
  uint64_t ooo_tensor_wait_head_cycles;
  uint64_t ooo_tensor_wait_drain_cycles;
  uint64_t ooo_tensor_npu_backpressure_cycles;
  uint64_t ooo_tensor_serialize_cycles;
  uint64_t ooo_tensor_alloc_direct_issue_count;
  uint64_t ooo_tensor_attr_prelaunch_cancel_cycles;
  uint64_t ooo_tensor_attr_wait_not_exact_head_cycles;
  uint64_t ooo_tensor_attr_wait_launch_gate_cycles;
  uint64_t ooo_tensor_attr_wait_src_dependency_cycles;
  uint64_t ooo_tensor_attr_wait_src_value_cycles;
  uint64_t ooo_tensor_attr_wait_mem_active_cycles;
  uint64_t ooo_tensor_attr_wait_mem_retire_cycles;
  uint64_t ooo_tensor_attr_launch_to_offer_cycles;
  uint64_t ooo_tensor_attr_offer_backpressure_cycles;
  uint64_t ooo_tensor_attr_offer_accept_cycles;
  uint64_t ooo_tensor_attr_sent_terminal_absent_cycles;
  uint64_t ooo_tensor_attr_sent_terminal_stale_cycles;
  uint64_t ooo_tensor_attr_sent_terminal_accept_cycles;
  uint64_t ooo_tensor_attr_complete_wb_backpressure_cycles;
  uint64_t ooo_tensor_attr_complete_stale_drop_cycles;
  uint64_t ooo_tensor_attr_complete_wb_accept_cycles;
  uint64_t ooo_tensor_attr_invalid_state_cycles;
  uint64_t ooo_tensor_attr_sent_terminal_completion_stale_cycles;
  uint64_t ooo_tensor_attr_sent_terminal_wb_accept_cycles;
  npc_word_t ooo_branch_wait_pc[kTopBranchWaitPcCount];
  uint64_t ooo_branch_wait_pc_cycles[kTopBranchWaitPcCount];
  npc_word_t ooo_jump_wait_pc[kTopBranchWaitPcCount];
  uint64_t ooo_jump_wait_pc_cycles[kTopBranchWaitPcCount];
};

struct OooWindowStats {
  uint64_t start_cycle;
  uint64_t cycles;
  uint64_t retire;
  uint64_t execute;
  uint64_t dispatch;
  uint64_t fetch_busy;
  uint64_t mem_busy;
  uint64_t axi_wait;
  uint64_t hazard_busy;
  uint64_t branch_flush;
  uint64_t exception_busy;
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

/* 这些计数来自 NpcSimTop.sv 对 RTL 内部信号的层次化采样。逐拍事件在
 * host 累加；RTL 本身已经累计的 Tensor 计数在 posedge eval 返回后采样。 */
static SimPerfStats g_sim_perf = {};
static BpuStats g_bpu_stats = {};
static BranchMissPcStat g_branch_miss_pc_stats[256] = {};
static bool g_last_ooo_branch_prefetch_hit = false;
static constexpr uint64_t kDefaultOooWindowCycles = 1000000ull;
static OooWindowStats g_ooo_window = {};
static uint64_t g_ooo_window_cycles = kDefaultOooWindowCycles;
static bool g_ooo_window_config_inited = false;
static bool g_ooo_window_enabled = true;
static uint64_t g_nr_branch       = 0;  // B-type 条件分支总数
static uint64_t g_nr_branch_taken = 0;  // 条件分支中实际跳转的次数
static uint64_t g_nr_jal          = 0;  // JAL 无条件跳转
static uint64_t g_nr_jalr         = 0;  // JALR 间接跳转（含 ret）

#ifdef CONFIG_NPC_OOO_STATS
struct RtlCounter32Epoch {
  uint32_t last_raw = 0;
  uint64_t extended = 0;
  bool initialized = false;
};

struct TensorSnapshotEpochs {
  RtlCounter32Epoch issued;
  RtlCounter32Epoch terminal;
  RtlCounter32Epoch completion;
  RtlCounter32Epoch wait_head;
  RtlCounter32Epoch wait_drain;
  RtlCounter32Epoch npu_backpressure;
  RtlCounter32Epoch serialize;
  RtlCounter32Epoch alloc_direct_issue;
  RtlCounter32Epoch attr_prelaunch_cancel;
  RtlCounter32Epoch attr_wait_not_exact_head;
  RtlCounter32Epoch attr_wait_launch_gate;
  RtlCounter32Epoch attr_wait_src_dependency;
  RtlCounter32Epoch attr_wait_src_value;
  RtlCounter32Epoch attr_wait_mem_active;
  RtlCounter32Epoch attr_wait_mem_retire;
  RtlCounter32Epoch attr_launch_to_offer;
  RtlCounter32Epoch attr_offer_backpressure;
  RtlCounter32Epoch attr_offer_accept;
  RtlCounter32Epoch attr_sent_terminal_absent;
  RtlCounter32Epoch attr_sent_terminal_stale;
  RtlCounter32Epoch attr_sent_terminal_accept;
  RtlCounter32Epoch attr_complete_wb_backpressure;
  RtlCounter32Epoch attr_complete_stale_drop;
  RtlCounter32Epoch attr_complete_wb_accept;
  RtlCounter32Epoch attr_invalid_state;
  RtlCounter32Epoch attr_sent_terminal_completion_stale;
  RtlCounter32Epoch attr_sent_terminal_wb_accept;
};

static TensorSnapshotEpochs g_tensor_snapshot_epochs = {};

static uint64_t extend_rtl_counter32(RtlCounter32Epoch *epoch,
                                     uint32_t raw) {
  if (!epoch->initialized) {
    epoch->last_raw = raw;
    epoch->extended = raw;
    epoch->initialized = true;
    return epoch->extended;
  }

  // Sampling every active edge bounds the increment well below 2^32.  The
  // uint32 subtraction therefore extends a single hardware wrap exactly.
  const uint32_t delta = raw - epoch->last_raw;
  epoch->last_raw = raw;
  epoch->extended += static_cast<uint64_t>(delta);
  return epoch->extended;
}

static void reset_tensor_snapshot_epochs(void) {
  g_tensor_snapshot_epochs = {};
}

static void sample_tensor_snapshot_post_posedge(void) {
  if (!g_top || g_top->rst) return;

  g_sim_perf.ooo_tensor_issued_count = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.issued,
      static_cast<uint32_t>(g_top->debug_tensor_issued_count_o));
  g_sim_perf.ooo_tensor_terminal_count = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.terminal,
      static_cast<uint32_t>(g_top->debug_tensor_terminal_count_o));
  g_sim_perf.ooo_tensor_completion_count = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.completion,
      static_cast<uint32_t>(g_top->debug_tensor_completion_count_o));
  g_sim_perf.ooo_tensor_wait_head_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.wait_head,
      static_cast<uint32_t>(g_top->debug_tensor_wait_head_cycles_o));
  g_sim_perf.ooo_tensor_wait_drain_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.wait_drain,
      static_cast<uint32_t>(g_top->debug_tensor_wait_drain_cycles_o));
  g_sim_perf.ooo_tensor_npu_backpressure_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.npu_backpressure,
      static_cast<uint32_t>(g_top->debug_tensor_npu_backpressure_cycles_o));
  g_sim_perf.ooo_tensor_serialize_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.serialize,
      static_cast<uint32_t>(g_top->debug_tensor_serialize_cycles_o));
  g_sim_perf.ooo_tensor_alloc_direct_issue_count = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.alloc_direct_issue,
      static_cast<uint32_t>(
          g_top->debug_tensor_alloc_direct_issue_count_o));
  g_sim_perf.ooo_tensor_attr_prelaunch_cancel_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.attr_prelaunch_cancel,
      static_cast<uint32_t>(
          g_top->debug_tensor_attribution_prelaunch_cancel_cycles_o));
  g_sim_perf.ooo_tensor_attr_wait_not_exact_head_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_wait_not_exact_head,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_wait_not_exact_head_cycles_o));
  g_sim_perf.ooo_tensor_attr_wait_launch_gate_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.attr_wait_launch_gate,
      static_cast<uint32_t>(
          g_top->debug_tensor_attribution_wait_launch_gate_cycles_o));
  g_sim_perf.ooo_tensor_attr_wait_src_dependency_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_wait_src_dependency,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_wait_src_dependency_cycles_o));
  g_sim_perf.ooo_tensor_attr_wait_src_value_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.attr_wait_src_value,
      static_cast<uint32_t>(
          g_top->debug_tensor_attribution_wait_src_value_cycles_o));
  g_sim_perf.ooo_tensor_attr_wait_mem_active_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.attr_wait_mem_active,
      static_cast<uint32_t>(
          g_top->debug_tensor_attribution_wait_mem_active_cycles_o));
  g_sim_perf.ooo_tensor_attr_wait_mem_retire_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.attr_wait_mem_retire,
      static_cast<uint32_t>(
          g_top->debug_tensor_attribution_wait_mem_retire_cycles_o));
  g_sim_perf.ooo_tensor_attr_launch_to_offer_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.attr_launch_to_offer,
      static_cast<uint32_t>(
          g_top->debug_tensor_attribution_launch_to_offer_cycles_o));
  g_sim_perf.ooo_tensor_attr_offer_backpressure_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_offer_backpressure,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_offer_backpressure_cycles_o));
  g_sim_perf.ooo_tensor_attr_offer_accept_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.attr_offer_accept,
      static_cast<uint32_t>(
          g_top->debug_tensor_attribution_offer_accept_cycles_o));
  g_sim_perf.ooo_tensor_attr_sent_terminal_absent_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_sent_terminal_absent,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_sent_terminal_absent_cycles_o));
  g_sim_perf.ooo_tensor_attr_sent_terminal_stale_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_sent_terminal_stale,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_sent_terminal_stale_cycles_o));
  g_sim_perf.ooo_tensor_attr_sent_terminal_accept_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_sent_terminal_accept,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_sent_terminal_accept_cycles_o));
  g_sim_perf.ooo_tensor_attr_complete_wb_backpressure_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_complete_wb_backpressure,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_complete_wb_backpressure_cycles_o));
  g_sim_perf.ooo_tensor_attr_complete_stale_drop_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_complete_stale_drop,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_complete_stale_drop_cycles_o));
  g_sim_perf.ooo_tensor_attr_complete_wb_accept_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_complete_wb_accept,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_complete_wb_accept_cycles_o));
  g_sim_perf.ooo_tensor_attr_invalid_state_cycles = extend_rtl_counter32(
      &g_tensor_snapshot_epochs.attr_invalid_state,
      static_cast<uint32_t>(
          g_top->debug_tensor_attribution_invalid_state_cycles_o));
  g_sim_perf.ooo_tensor_attr_sent_terminal_completion_stale_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_sent_terminal_completion_stale,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_sent_terminal_completion_stale_cycles_o));
  g_sim_perf.ooo_tensor_attr_sent_terminal_wb_accept_cycles =
      extend_rtl_counter32(
          &g_tensor_snapshot_epochs.attr_sent_terminal_wb_accept,
          static_cast<uint32_t>(
              g_top->debug_tensor_attribution_sent_terminal_wb_accept_cycles_o));
}
#endif

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

static bool add_u64_checked(uint64_t *value, uint64_t increment) {
  if (value == nullptr || UINT64_MAX - *value < increment) return false;
  *value += increment;
  return true;
}

static bool sub_u64_checked(uint64_t *value, uint64_t decrement) {
  if (value == nullptr || *value < decrement) return false;
  *value -= decrement;
  return true;
}

static void capture_retire_observation_snapshot(
    RetireObservationSnapshot *snapshot) {
  if (snapshot == nullptr) return;
  memset(snapshot, 0, sizeof(*snapshot));
  memcpy(snapshot->cycle_reason, g_retire_observation.cycle_reason,
         sizeof(snapshot->cycle_reason));
  memcpy(snapshot->slot_reason, g_retire_observation.slot_reason,
         sizeof(snapshot->slot_reason));
  memcpy(snapshot->cycle_request_detail,
         g_retire_observation.cycle_request_detail,
         sizeof(snapshot->cycle_request_detail));
  memcpy(snapshot->slot_request_detail,
         g_retire_observation.slot_request_detail,
         sizeof(snapshot->slot_request_detail));
  memcpy(snapshot->current_slot_reason,
         g_retire_observation.current_slot_reason,
         sizeof(snapshot->current_slot_reason));
  memcpy(snapshot->current_slot_request_detail,
         g_retire_observation.current_slot_request_detail,
         sizeof(snapshot->current_slot_request_detail));
  snapshot->event_cycle = g_retire_observation.current_cycle;
  snapshot->invalid_events = g_retire_observation.invalid_events;
  snapshot->available = g_retire_observation.current_valid &&
                        snapshot->event_cycle == npc_stats()->cycles;
  snapshot->current_invalid = g_retire_observation.current_invalid;
  snapshot->current_overflow = g_retire_observation.current_overflow;
  snapshot->overflow = g_retire_observation.overflow;
}

struct SqIdleFusionReport {
  SqIdleFusionCounters counters;
  uint64_t identity_or_lq_reject;
  bool complete;
  bool available;
  bool overflow;
  bool malformed;
  bool conservation;
};

static void capture_sq_idle_fusion_snapshot(
    SqIdleFusionSnapshot *snapshot) {
  if (snapshot == nullptr) return;
  memset(snapshot, 0, sizeof(*snapshot));
  snapshot->counters = g_sq_idle_fusion.counters;
  snapshot->event_cycle = g_sq_idle_fusion.current_cycle;
  snapshot->available = g_sq_idle_fusion.current_valid &&
                        snapshot->event_cycle == npc_stats()->cycles;
  snapshot->malformed = g_sq_idle_fusion.encoding_malformed ||
                        g_sq_idle_fusion.sequence_malformed;
  snapshot->overflow = g_sq_idle_fusion.overflow;
}

static bool subtract_sq_idle_fusion_counters(
    const SqIdleFusionCounters &end,
    const SqIdleFusionCounters &start,
    SqIdleFusionCounters *delta) {
  if (delta == nullptr) return false;
  memset(delta, 0, sizeof(*delta));
#define SQ_IDLE_FUSION_SUB_FIELD(field)                                  \
  do {                                                                   \
    if (end.field < start.field) return false;                           \
    delta->field = end.field - start.field;                              \
  } while (0)
  SQ_IDLE_FUSION_SUB_FIELD(cycles);
  SQ_IDLE_FUSION_SUB_FIELD(prequal);
  SQ_IDLE_FUSION_SUB_FIELD(exact);
  SQ_IDLE_FUSION_SUB_FIELD(allow);
  SQ_IDLE_FUSION_SUB_FIELD(forward);
  SQ_IDLE_FUSION_SUB_FIELD(replay);
  SQ_IDLE_FUSION_SUB_FIELD(invalid);
  SQ_IDLE_FUSION_SUB_FIELD(allow_rob_head);
#undef SQ_IDLE_FUSION_SUB_FIELD
  return true;
}

static SqIdleFusionReport make_sq_idle_fusion_report(
    const SqIdleFusionCounters &counters,
    bool scope_complete,
    bool available,
    bool overflow,
    bool malformed) {
  SqIdleFusionReport report = {};
  report.counters = counters;
  report.available = available;
  report.overflow = overflow;
  report.malformed = malformed;

  if (counters.prequal < counters.exact) {
    report.malformed = true;
  } else {
    report.identity_or_lq_reject = counters.prequal - counters.exact;
  }

  uint64_t decision_sum = 0;
  if (!add_u64_checked(&decision_sum, counters.allow) ||
      !add_u64_checked(&decision_sum, counters.forward) ||
      !add_u64_checked(&decision_sum, counters.replay) ||
      !add_u64_checked(&decision_sum, counters.invalid)) {
    report.overflow = true;
  }
  report.conservation = !report.overflow && !report.malformed &&
      counters.exact == decision_sum &&
      counters.prequal >= counters.exact &&
      counters.allow_rob_head <= counters.allow;
  report.complete = scope_complete && report.available &&
      !report.overflow && !report.malformed && report.conservation;
  return report;
}

static void emit_sq_idle_fusion_report(
    const char *marker,
    const SqIdleFusionReport &report) {
  LogBothTag(
      "sq_idle_fusion",
      "%s schema=npc-rv64-sq-idle-fusion-qualification-v1"
      " complete=%u available=%u overflow=%u malformed=%u cycles=%llu"
      " prequal=%llu exact=%llu identity_or_lq_reject=%llu"
      " allow=%llu forward=%llu replay=%llu invalid=%llu"
      " allow_rob_head=%llu conservation=%u",
      marker,
      report.complete ? 1u : 0u,
      report.available ? 1u : 0u,
      report.overflow ? 1u : 0u,
      report.malformed ? 1u : 0u,
      (unsigned long long)report.counters.cycles,
      (unsigned long long)report.counters.prequal,
      (unsigned long long)report.counters.exact,
      (unsigned long long)report.identity_or_lq_reject,
      (unsigned long long)report.counters.allow,
      (unsigned long long)report.counters.forward,
      (unsigned long long)report.counters.replay,
      (unsigned long long)report.counters.invalid,
      (unsigned long long)report.counters.allow_rob_head,
      report.conservation ? 1u : 0u);
}

static void report_sq_idle_fusion_region(bool boundary_complete) {
  const SqIdleFusionSnapshot &start =
      g_region_probe.start_sq_idle_fusion;
  const SqIdleFusionSnapshot &end =
      g_region_probe.end_sq_idle_fusion;
  const bool available = start.available && end.available;
  bool malformed = start.malformed || end.malformed;
  const bool overflow = start.overflow || end.overflow;
  SqIdleFusionCounters delta = {};
  if (available &&
      !subtract_sq_idle_fusion_counters(
          end.counters, start.counters, &delta)) {
    malformed = true;
  }
  if (available &&
      (start.event_cycle != g_region_probe.start_cycle ||
       end.event_cycle != g_region_probe.end_cycle ||
       end.event_cycle < start.event_cycle ||
       delta.cycles != end.event_cycle - start.event_cycle)) {
    malformed = true;
  }
  const SqIdleFusionReport report = make_sq_idle_fusion_report(
      delta, boundary_complete, available, overflow, malformed);
  emit_sq_idle_fusion_report("SQ_IDLE_FUSION_REGION", report);
}

static void report_sq_idle_fusion_final(void) {
  const bool available = g_sq_idle_fusion.current_valid &&
      g_sq_idle_fusion.current_cycle == npc_stats()->cycles;
  const bool malformed = g_sq_idle_fusion.encoding_malformed ||
      g_sq_idle_fusion.sequence_malformed ||
      (available &&
       g_sq_idle_fusion.counters.cycles != g_sq_idle_fusion.current_cycle);
  const SqIdleFusionReport report = make_sq_idle_fusion_report(
      g_sq_idle_fusion.counters, true, available,
      g_sq_idle_fusion.overflow, malformed);
  emit_sq_idle_fusion_report("SQ_IDLE_FUSION_FINAL", report);
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
  const char *stop_s = std::getenv("NPC_COMMITWATCH_STOP");
  g_commit_watch_stop_on_match =
      stop_s != nullptr && stop_s[0] != '\0' && stop_s[0] != '0';
  const char *stop_after_s = std::getenv("NPC_COMMITWATCH_STOP_AFTER");
  if (stop_after_s && stop_after_s[0] != '\0') {
    char *stop_after_end = nullptr;
    uint64_t stop_after = std::strtoull(stop_after_s, &stop_after_end, 0);
    if (stop_after_end != stop_after_s && stop_after > 0) {
      g_commit_watch_stop_after = stop_after;
    }
  }
  const char *post_cycles_s = std::getenv("NPC_COMMITWATCH_POST_CYCLES");
  if (post_cycles_s && post_cycles_s[0] != '\0') {
    char *post_cycles_end = nullptr;
    uint64_t post_cycles = std::strtoull(post_cycles_s, &post_cycles_end, 0);
    if (post_cycles_end != post_cycles_s) {
      g_commit_watch_post_cycles = post_cycles;
    }
  }
  g_commit_watch_enabled = true;
  LogBothTag("commitwatch",
             "enabled pc=[0x%016" NPC_PRIxWORD ",0x%016" NPC_PRIxWORD
             "] commit=[%llu,%llu] stop=%s stop_after=%llu post_cycles=%llu",
             g_commit_watch_start, g_commit_watch_end,
             (unsigned long long)g_commit_watch_min_commit,
             (unsigned long long)g_commit_watch_max_commit,
             g_commit_watch_stop_on_match ? "yes" : "no",
             (unsigned long long)g_commit_watch_stop_after,
             (unsigned long long)g_commit_watch_post_cycles);
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
             "match=%llu commit=%llu pc=0x%016" NPC_PRIxWORD
             " inst=0x%08x next=0x%016" NPC_PRIxWORD
             " rd=%u wen=%u rd_data=0x%016" NPC_PRIxWORD
             " ra=0x%016" NPC_PRIxWORD " sp=0x%016" NPC_PRIxWORD
             " s0=0x%016" NPC_PRIxWORD " s1=0x%016" NPC_PRIxWORD
             " s2=0x%016" NPC_PRIxWORD " s3=0x%016" NPC_PRIxWORD
             " s4=0x%016" NPC_PRIxWORD " s5=0x%016" NPC_PRIxWORD
             " s6=0x%016" NPC_PRIxWORD " s7=0x%016" NPC_PRIxWORD
             " a0=0x%016" NPC_PRIxWORD " a1=0x%016" NPC_PRIxWORD
             " a2=0x%016" NPC_PRIxWORD " a3=0x%016" NPC_PRIxWORD
             " a4=0x%016" NPC_PRIxWORD " a5=0x%016" NPC_PRIxWORD
             " a6=0x%016" NPC_PRIxWORD " a7=0x%016" NPC_PRIxWORD,
             (unsigned long long)(g_commit_watch_match_count + 1),
             (unsigned long long)npc_stats()->commits, pc, inst, next_pc,
             rd_addr, rd_en, rd_data,
             g_shadow_gpr[1], g_shadow_gpr[2], g_shadow_gpr[8],
             g_shadow_gpr[9], g_shadow_gpr[18], g_shadow_gpr[19],
             g_shadow_gpr[20], g_shadow_gpr[21], g_shadow_gpr[22],
             g_shadow_gpr[23], g_shadow_gpr[10], g_shadow_gpr[11],
             g_shadow_gpr[12], g_shadow_gpr[13], g_shadow_gpr[14],
             g_shadow_gpr[15], g_shadow_gpr[16], g_shadow_gpr[17]);
  g_commit_watch_match_count++;
  if (g_commit_watch_stop_on_match &&
      g_commit_watch_match_count >= g_commit_watch_stop_after) {
    if (g_commit_watch_post_cycles > 0 && !g_commit_watch_post_active) {
      g_commit_watch_post_active = true;
      g_commit_watch_post_deadline =
          npc_stats()->cycles + g_commit_watch_post_cycles;
      LogBothTag("commitwatch",
                 "post window armed cycles=%llu deadline=%llu",
                 (unsigned long long)g_commit_watch_post_cycles,
                 (unsigned long long)g_commit_watch_post_deadline);
    } else if (g_commit_watch_post_cycles == 0) {
      g_commit_watch_matched = true;
    }
  }
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

static bool init_tohost_watch(const NpcSimConfig *config) {
  g_tohost_enabled = false;
  g_tohost_addr = 0;
  if (!config || !config->tohost_enable) return true;

  if ((config->tohost_addr & (sizeof(npc_word_t) - 1u)) != 0) {
    fprintf(stderr, "[npc-tohost] unaligned --tohost address: 0x%016" NPC_PRIxPADDR "\n",
            config->tohost_addr);
    return false;
  }
  if (!npc_pmem_range_valid(config->tohost_addr, sizeof(npc_word_t))) {
    fprintf(stderr, "[npc-tohost] --tohost address is outside PMEM: 0x%016" NPC_PRIxPADDR "\n",
            config->tohost_addr);
    return false;
  }

  g_tohost_enabled = true;
  g_tohost_addr = config->tohost_addr;
  LogBothTag("tohost", "watching word at 0x%016" NPC_PRIxPADDR, g_tohost_addr);
  return true;
}

static bool read_tohost_word(npc_word_t *value) {
  if (!value || !g_tohost_enabled) return false;
  uint8_t *host = npc_guest_to_host(g_tohost_addr);
  if (!host) return false;
  memcpy(value, host, sizeof(*value));
  return true;
}

static bool maybe_stop_on_tohost(void) {
  npc_word_t value = 0;
  if (!read_tohost_word(&value) || value == 0) return false;

  uint64_t code = 1;
  if (value == 1) {
    code = 0;
  } else if ((value & 1u) != 0) {
    code = (uint64_t)(value >> 1);
    if (code == 0) code = 1;
  } else {
    code = (uint64_t)value;
  }

  NpcState *st = npc_state();
  st->state = NPC_END;
  st->halt_pc = g_top ? g_top->debug_pc_o : NPC_RESET_PC;
  st->halt_ret = (npc_word_t)code;
  st->exit_is_ebreak = false;
  st->exit_is_ecall = false;
  st->exit_is_system_reset = false;
  st->exit_is_tohost = true;
  st->tohost_value = value;
  LogBothTag("tohost", "observed value=0x%016" NPC_PRIxWORD " code=%llu",
             value, (unsigned long long)code);
  return true;
}

static bool sv39_canonical_va(npc_word_t vaddr) {
  uint64_t sign = (vaddr >> 38) & 1u;
  uint64_t high = vaddr >> 39;
  return sign ? (high == ((1ull << 25) - 1ull)) : (high == 0);
}

static bool translate_debug_sv39(npc_word_t vaddr, npc_paddr_t *paddr) {
  if (!paddr || !g_top) return false;
  uint64_t satp = (uint64_t)g_top->debug_ooo_satp_o;
  if ((satp >> 60) != 8u) {
    *paddr = (npc_paddr_t)vaddr;
    return true;
  }
  if (!sv39_canonical_va(vaddr)) return false;

  uint64_t vpn[3] = {
    (vaddr >> 12) & 0x1ffu,
    (vaddr >> 21) & 0x1ffu,
    (vaddr >> 30) & 0x1ffu,
  };
  uint64_t ppn = satp & ((1ull << 44) - 1ull);

  for (int level = 2; level >= 0; --level) {
    npc_word_t pte = 0;
    npc_paddr_t pte_addr = (npc_paddr_t)((ppn << 12) + vpn[level] * 8u);
    if (!npc_paddr_read(pte_addr, &pte, NPC_BUS_LOAD)) return false;

    bool valid = (pte & 0x1u) != 0;
    bool readable = (pte & 0x2u) != 0;
    bool writable = (pte & 0x4u) != 0;
    bool executable = (pte & 0x8u) != 0;
    if (!valid || (!readable && writable)) return false;

    if (readable || executable) {
      uint64_t pte_ppn0 = (pte >> 10) & 0x1ffu;
      uint64_t pte_ppn1 = (pte >> 19) & 0x1ffu;
      uint64_t pte_ppn2 = (pte >> 28) & ((1ull << 26) - 1ull);
      if (level == 2) {
        if (pte_ppn0 != 0 || pte_ppn1 != 0) return false;
        *paddr = (npc_paddr_t)((pte_ppn2 << 30) | (vaddr & ((1ull << 30) - 1ull)));
        return true;
      }
      if (level == 1) {
        if (pte_ppn0 != 0) return false;
        *paddr = (npc_paddr_t)((pte_ppn2 << 30) | (pte_ppn1 << 21) |
                               (vaddr & ((1ull << 21) - 1ull)));
        return true;
      }
      *paddr = (npc_paddr_t)((pte_ppn2 << 30) | (pte_ppn1 << 21) |
                             (pte_ppn0 << 12) | (vaddr & 0xfffull));
      return true;
    }

    ppn = (pte >> 10) & ((1ull << 44) - 1ull);
  }
  return false;
}

static bool read_guest_user_u8(npc_word_t vaddr, uint8_t *byte) {
  npc_paddr_t paddr = 0;
  return translate_debug_sv39(vaddr, &paddr) && read_guest_u8(paddr, byte);
}

static bool read_guest_user_cstr(npc_word_t vaddr, char *buf, size_t size) {
  if (!buf || size == 0 || vaddr == 0) return false;
  buf[0] = '\0';
  for (size_t i = 0; i + 1 < size; ++i) {
    uint8_t ch = 0;
    if (!read_guest_user_u8(vaddr + i, &ch)) {
      buf[i] = '\0';
      return i > 0;
    }
    if (ch == 0) {
      buf[i] = '\0';
      return true;
    }
    if (ch == '"' || ch == '\\') {
      buf[i] = '?';
    } else {
      buf[i] = (ch >= 32 && ch < 127) ? (char)ch : '.';
    }
  }
  buf[size - 1] = '\0';
  return true;
}

static bool env_enabled(const char *name) {
  const char *s = std::getenv(name);
  return s != nullptr && s[0] != '\0' && s[0] != '0';
}

static uint64_t env_u64_or(const char *name, uint64_t fallback) {
  const char *s = std::getenv(name);
  if (!s || s[0] == '\0') return fallback;
  char *end = nullptr;
  uint64_t value = std::strtoull(s, &end, 0);
  return (end != s) ? value : fallback;
}

static void init_user_trace(void) {
  if (g_user_trace_inited) return;
  g_user_trace_inited = true;

  g_user_trace_min_commit = env_u64_or("NPC_USER_TRACE_MIN_COMMIT", 0);
  g_user_ecall_trace_enabled = env_enabled("NPC_USER_ECALL_TRACE");
  g_user_ecall_trace_priv_enabled = env_enabled("NPC_USER_ECALL_TRACE_PRIV");
  g_user_ecall_path_trace_enabled = env_enabled("NPC_USER_ECALL_PATH_TRACE");
  g_user_ecall_min_commit =
      env_u64_or("NPC_USER_ECALL_MIN_COMMIT", g_user_trace_min_commit);
  g_user_ecall_trace_limit = env_u64_or("NPC_USER_ECALL_TRACE_LIMIT", 128);
  g_user_ecall_path_max = env_u64_or("NPC_USER_ECALL_PATH_MAX", 96);
  if (g_user_ecall_path_max < 16) g_user_ecall_path_max = 16;
  if (g_user_ecall_path_max > 240) g_user_ecall_path_max = 240;
  g_user_progress_interval = env_u64_or("NPC_USER_PROGRESS_INTERVAL", 0);
  g_user_progress_limit = env_u64_or("NPC_USER_PROGRESS_LIMIT", 64);
  g_user_progress_enabled = g_user_progress_interval > 0;
  g_user_progress_next_commit = g_user_trace_min_commit;

  if (g_user_ecall_trace_enabled || g_user_progress_enabled) {
    LogBothTag("user_trace",
               "enabled ecall=%u ecall_priv=%u path_trace=%u ecall_limit=%llu "
               "ecall_min_commit=%llu progress_interval=%llu "
               "progress_limit=%llu min_commit=%llu path_max=%llu",
               g_user_ecall_trace_enabled ? 1u : 0u,
               g_user_ecall_trace_priv_enabled ? 1u : 0u,
               g_user_ecall_path_trace_enabled ? 1u : 0u,
               (unsigned long long)g_user_ecall_trace_limit,
               (unsigned long long)g_user_ecall_min_commit,
               (unsigned long long)g_user_progress_interval,
               (unsigned long long)g_user_progress_limit,
               (unsigned long long)g_user_trace_min_commit,
               (unsigned long long)g_user_ecall_path_max);
  }
}

static void reset_user_trace_counters(void) {
  init_user_trace();
  g_user_ecall_trace_count = 0;
  g_user_progress_count = 0;
  g_user_progress_next_commit = g_user_trace_min_commit;
}

static bool sv39_lower_user_va(npc_word_t pc) {
  return pc >= 0x1000ull && pc < 0x0000004000000000ull;
}

static bool dynamic_user_va(npc_word_t pc) {
  return pc >= 0x0000000100000000ull && pc < 0x0000004000000000ull;
}

static void append_text_field(char *buf, size_t size, const char *text) {
  if (!buf || size == 0 || !text) return;
  size_t used = strlen(buf);
  if (used + 1 >= size) return;
  snprintf(buf + used, size - used, "%s", text);
}

static void append_user_path_field(char *buf, size_t size,
                                   const char *name, npc_word_t vaddr) {
  if (!buf || size == 0 || !name) return;
  char value[256];
  size_t max_len = (size_t)g_user_ecall_path_max;
  if (max_len >= sizeof(value)) max_len = sizeof(value) - 1;
  bool ok = read_guest_user_cstr(vaddr, value, max_len + 1);
  size_t used = strlen(buf);
  if (used + 1 >= size) return;
  if (ok) {
    snprintf(buf + used, size - used, " %s=\"%s\"", name, value);
  } else {
    snprintf(buf + used, size - used, " %s=<unreadable:0x%016" NPC_PRIxWORD ">",
             name, vaddr);
  }
}

static void format_ecall_path_fields(char *buf, size_t size) {
  if (!buf || size == 0) return;
  buf[0] = '\0';
  if (!g_user_ecall_path_trace_enabled) return;

  uint64_t syscall = g_shadow_gpr[17];
  switch (syscall) {
    case 27:  // inotify_add_watch(fd, pathname, mask)
    case 33:  // mknodat(dirfd, pathname, ...)
    case 34:  // mkdirat(dirfd, pathname, ...)
    case 35:  // unlinkat(dirfd, pathname, ...)
    case 48:  // faccessat(dirfd, pathname, ...)
    case 53:  // fchmodat(dirfd, pathname, ...)
    case 54:  // fchownat(dirfd, pathname, ...)
    case 56:  // openat(dirfd, pathname, ...)
    case 78:  // readlinkat(dirfd, pathname, ...)
    case 79:  // newfstatat(dirfd, pathname, ...)
    case 88:  // utimensat(dirfd, pathname, ...)
    case 291: // statx(dirfd, pathname, ...)
    case 437: // openat2(dirfd, pathname, ...)
    case 439: // faccessat2(dirfd, pathname, ...)
      append_user_path_field(buf, size, "path", g_shadow_gpr[11]);
      break;
    case 36:  // symlinkat(target, newdirfd, linkpath)
      append_user_path_field(buf, size, "target", g_shadow_gpr[10]);
      append_user_path_field(buf, size, "linkpath", g_shadow_gpr[12]);
      break;
    case 37:  // linkat(olddirfd, oldpath, newdirfd, newpath, flags)
    case 38:  // renameat(olddirfd, oldpath, newdirfd, newpath)
    case 276: // renameat2(olddirfd, oldpath, newdirfd, newpath, flags)
      append_user_path_field(buf, size, "oldpath", g_shadow_gpr[11]);
      append_user_path_field(buf, size, "newpath", g_shadow_gpr[13]);
      break;
    case 40:  // mount(source, target, filesystemtype, ...)
      append_user_path_field(buf, size, "source", g_shadow_gpr[10]);
      append_user_path_field(buf, size, "target", g_shadow_gpr[11]);
      append_user_path_field(buf, size, "fstype", g_shadow_gpr[12]);
      break;
    case 49:  // chdir(path)
      append_user_path_field(buf, size, "path", g_shadow_gpr[10]);
      break;
    default:
      break;
  }

  if (buf[0] != '\0') append_text_field(buf, size, " path_trace=sv39");
}

static void maybe_log_user_trace(npc_word_t pc, uint32_t inst, npc_word_t next_pc) {
  init_user_trace();
  if (!g_user_ecall_trace_enabled && !g_user_progress_enabled) return;

  uint64_t commit = npc_stats()->commits;
  if (commit < g_user_trace_min_commit &&
      commit < g_user_ecall_min_commit) {
    return;
  }

  uint64_t flags = g_top ? (uint64_t)g_top->debug_ooo_flags_o : 0;
  // Bit 63 is payload/configuration validity, not transaction validity.
  bool debug_valid = ((flags >> 63) & 0x1u) != 0;
  uint64_t priv = (flags >> 27) & 0x3u;
  bool sv39 = ((flags >> 29) & 0x1u) != 0;
  bool user_pc = sv39_lower_user_va(pc);
  bool dynamic_user_pc = dynamic_user_va(pc);
  bool user_context = (debug_valid && sv39 && user_pc) || dynamic_user_pc;
  if (!user_context) return;

  if (g_user_progress_enabled &&
      ((debug_valid && priv == 0) || dynamic_user_pc) &&
      g_user_progress_count < g_user_progress_limit &&
      commit >= g_user_progress_next_commit) {
    LogBothTag("user_progress",
               "sample=%llu commit=%llu pc=0x%016" NPC_PRIxWORD
               " inst=0x%08x next=0x%016" NPC_PRIxWORD
               " debug_valid=%u priv=%llu sv39=%u ra=0x%016" NPC_PRIxWORD
               " sp=0x%016" NPC_PRIxWORD " a0=0x%016" NPC_PRIxWORD
               " a1=0x%016" NPC_PRIxWORD " a2=0x%016" NPC_PRIxWORD
               " a3=0x%016" NPC_PRIxWORD " a4=0x%016" NPC_PRIxWORD
               " a5=0x%016" NPC_PRIxWORD " a7=0x%016" NPC_PRIxWORD,
               (unsigned long long)(g_user_progress_count + 1),
               (unsigned long long)commit, pc, inst, next_pc,
               debug_valid ? 1u : 0u,
               (unsigned long long)priv, sv39 ? 1u : 0u,
               g_shadow_gpr[1], g_shadow_gpr[2], g_shadow_gpr[10],
               g_shadow_gpr[11], g_shadow_gpr[12], g_shadow_gpr[13],
               g_shadow_gpr[14], g_shadow_gpr[15], g_shadow_gpr[17]);
    g_user_progress_count++;
    g_user_progress_next_commit = commit + g_user_progress_interval;
  }

  if (g_user_ecall_trace_enabled && inst == 0x00000073u &&
      commit >= g_user_ecall_min_commit &&
      g_user_ecall_trace_count < g_user_ecall_trace_limit) {
    LogBothTag("user_ecall",
               "hit=%llu commit=%llu pc=0x%016" NPC_PRIxWORD
               " next=0x%016" NPC_PRIxWORD
               " debug_valid=%u priv=%llu sv39=%u"
               " syscall=%llu ra=0x%016" NPC_PRIxWORD
               " sp=0x%016" NPC_PRIxWORD " a0=0x%016" NPC_PRIxWORD
               " a1=0x%016" NPC_PRIxWORD " a2=0x%016" NPC_PRIxWORD
               " a3=0x%016" NPC_PRIxWORD " a4=0x%016" NPC_PRIxWORD
               " a5=0x%016" NPC_PRIxWORD " a6=0x%016" NPC_PRIxWORD
               " a7=0x%016" NPC_PRIxWORD,
               (unsigned long long)(g_user_ecall_trace_count + 1),
               (unsigned long long)commit, pc, next_pc,
               debug_valid ? 1u : 0u,
               (unsigned long long)priv, sv39 ? 1u : 0u,
               (unsigned long long)g_shadow_gpr[17],
               g_shadow_gpr[1], g_shadow_gpr[2], g_shadow_gpr[10],
               g_shadow_gpr[11], g_shadow_gpr[12], g_shadow_gpr[13],
               g_shadow_gpr[14], g_shadow_gpr[15], g_shadow_gpr[16],
               g_shadow_gpr[17]);
    g_user_ecall_trace_count++;
  }
}

static void maybe_log_ecall_trap(uint32_t kind, uint32_t cause,
                                 npc_word_t pc, npc_word_t tval) {
  init_user_trace();
  uint64_t commit = npc_stats()->commits;
  if (!g_user_ecall_trace_enabled ||
      commit < g_user_ecall_min_commit ||
      g_user_ecall_trace_count >= g_user_ecall_trace_limit) {
    return;
  }

  if (cause != 8u && cause != 9u && cause != 11u) return;
  if (cause != 8u && !g_user_ecall_trace_priv_enabled) return;
  const char *kind_name = (kind == 0) ? "mem" : (kind == 1) ? "ex" : "irq";
  const char *mode_name = (cause == 8u) ? "u" : (cause == 9u) ? "s" : "m";
  char path_fields[768];
  format_ecall_path_fields(path_fields, sizeof(path_fields));
  LogBothTag("user_ecall",
             "trap_hit=%llu commit=%llu kind=%s mode=%s cause=%u"
             " pc=0x%016" NPC_PRIxWORD " tval=0x%016" NPC_PRIxWORD
             " syscall=%llu ra=0x%016" NPC_PRIxWORD
             " sp=0x%016" NPC_PRIxWORD " a0=0x%016" NPC_PRIxWORD
             " a1=0x%016" NPC_PRIxWORD " a2=0x%016" NPC_PRIxWORD
             " a3=0x%016" NPC_PRIxWORD " a4=0x%016" NPC_PRIxWORD
             " a5=0x%016" NPC_PRIxWORD " a6=0x%016" NPC_PRIxWORD
             " a7=0x%016" NPC_PRIxWORD "%s",
             (unsigned long long)(g_user_ecall_trace_count + 1),
             (unsigned long long)commit, kind_name, mode_name,
             cause, pc, tval, (unsigned long long)g_shadow_gpr[17],
             g_shadow_gpr[1], g_shadow_gpr[2], g_shadow_gpr[10],
             g_shadow_gpr[11], g_shadow_gpr[12], g_shadow_gpr[13],
             g_shadow_gpr[14], g_shadow_gpr[15], g_shadow_gpr[16],
             g_shadow_gpr[17], path_fields);
  g_user_ecall_trace_count++;
}

static void on_sigint(int) { g_stop_requested = 1; }

static void configure_region_probe(void) {
  g_region_probe = {};

  const char *start_s = std::getenv("NPC_REGION_START_PC");
  const char *end_s = std::getenv("NPC_REGION_END_PC");
  if (!start_s || !end_s || start_s[0] == '\0' || end_s[0] == '\0') return;

  char *start_end = nullptr;
  char *end_end = nullptr;
  const uint64_t start = std::strtoull(start_s, &start_end, 0);
  const uint64_t end = std::strtoull(end_s, &end_end, 0);
  if (start_end == start_s || *start_end != '\0' ||
      end_end == end_s || *end_end != '\0') {
    LogBothTag("region_probe", "ERROR invalid NPC_REGION_START_PC/END_PC");
    return;
  }

  g_region_probe.enabled = true;
  g_region_probe.start_pc = (npc_word_t)start;
  g_region_probe.end_pc = (npc_word_t)end;
  LogBothTag("region_probe",
             "enabled start=0x%016" NPC_PRIxWORD
             " end=0x%016" NPC_PRIxWORD,
             g_region_probe.start_pc, g_region_probe.end_pc);
}

static void observe_region_boundary(const CommitEvent &event,
                                    uint32_t commit_lane) {
  if (!g_region_probe.enabled) return;

  const uint64_t cycle_retire = g_commit_event_count;
  const uint64_t retired_before =
      npc_stats()->commits - cycle_retire + commit_lane;

  if (event.pc == g_region_probe.start_pc) {
    ++g_region_probe.start_pc_hits;
    if (!g_region_probe.start_seen) {
      g_region_probe.start_seen = true;
      g_region_probe.start_cycle = npc_stats()->cycles;
      g_region_probe.start_retired = retired_before;
      g_region_probe.start_lane = commit_lane;
      capture_retire_observation_snapshot(&g_region_probe.start_counter);
      capture_sq_idle_fusion_snapshot(
          &g_region_probe.start_sq_idle_fusion);
      LogBothTag("region_probe",
                 "BOUNDARY kind=start pc=0x%016" NPC_PRIxWORD
                 " cycle=%llu retired_before=%llu lane=%u cycle_retire=%llu",
                 event.pc,
                 (unsigned long long)g_region_probe.start_cycle,
                 (unsigned long long)g_region_probe.start_retired,
                 g_region_probe.start_lane,
                 (unsigned long long)cycle_retire);
    }
  }

  if (event.pc == g_region_probe.end_pc) {
    ++g_region_probe.end_pc_hits;
    if (!g_region_probe.end_seen) {
      g_region_probe.end_seen = true;
      g_region_probe.end_cycle = npc_stats()->cycles;
      g_region_probe.end_retired = retired_before;
      g_region_probe.end_lane = commit_lane;
      capture_retire_observation_snapshot(&g_region_probe.end_counter);
      capture_sq_idle_fusion_snapshot(
          &g_region_probe.end_sq_idle_fusion);
      LogBothTag("region_probe",
                 "BOUNDARY kind=end pc=0x%016" NPC_PRIxWORD
                 " cycle=%llu retired_before=%llu lane=%u cycle_retire=%llu",
                 event.pc,
                 (unsigned long long)g_region_probe.end_cycle,
                 (unsigned long long)g_region_probe.end_retired,
                 g_region_probe.end_lane,
                 (unsigned long long)cycle_retire);
      if (!g_region_probe.start_seen) {
        LogBothTag("region_probe", "ERROR end boundary observed before start");
      }
    }
  }
}

static void report_region_probe_final(int termination_rc) {
  if (!g_region_probe.enabled || g_region_probe.final_emitted) return;
  g_region_probe.final_emitted = true;

  const bool complete =
      g_region_probe.start_seen && g_region_probe.end_seen &&
      g_region_probe.end_cycle >= g_region_probe.start_cycle &&
      g_region_probe.end_retired > g_region_probe.start_retired;
  const uint64_t region_cycles = complete
      ? g_region_probe.end_cycle - g_region_probe.start_cycle
      : 0;
  const uint64_t region_retired = complete
      ? g_region_probe.end_retired - g_region_probe.start_retired
      : 0;
  LogBothTag("region_probe",
             "FINAL schema=npc-rv64-region-final-v1"
             " counter_scope=pc_bounded_region_v1"
             " complete=%u termination_rc=%d start_seen=%u end_seen=%u"
             " start_hits=%llu end_hits=%llu start_cycle=%llu"
             " end_cycle=%llu cycles=%llu start_retired=%llu"
             " end_retired=%llu retired=%llu",
             complete ? 1u : 0u,
             termination_rc,
             g_region_probe.start_seen ? 1u : 0u,
             g_region_probe.end_seen ? 1u : 0u,
             (unsigned long long)g_region_probe.start_pc_hits,
             (unsigned long long)g_region_probe.end_pc_hits,
             (unsigned long long)g_region_probe.start_cycle,
             (unsigned long long)g_region_probe.end_cycle,
             (unsigned long long)region_cycles,
             (unsigned long long)g_region_probe.start_retired,
             (unsigned long long)g_region_probe.end_retired,
             (unsigned long long)region_retired);

  // These cycle-event snapshots are already inclusive of their boundary
  // cycles.  Direct subtraction therefore measures (S,E]; unlike retire-slot
  // counters, no start/end lane suffix correction applies.
  report_sq_idle_fusion_region(complete);

  uint64_t cycle_reason[RETIRE_REASON_COUNT] = {};
  uint64_t slot_reason[RETIRE_REASON_COUNT] = {};
  uint64_t cycle_request_detail[MEMORY_REQUEST_DETAIL_COUNT] = {};
  uint64_t slot_request_detail[MEMORY_REQUEST_DETAIL_COUNT] = {};
  const bool counter_available =
      g_region_probe.start_counter.available &&
      g_region_probe.end_counter.available;
  bool counter_arithmetic_ok = complete && counter_available;
  bool counter_overflow =
      g_region_probe.start_counter.overflow ||
      g_region_probe.end_counter.overflow ||
      g_region_probe.start_counter.current_overflow ||
      g_region_probe.end_counter.current_overflow;

  if (counter_arithmetic_ok) {
    for (uint32_t reason = 0; reason < RETIRE_REASON_COUNT; ++reason) {
      if (g_region_probe.end_counter.cycle_reason[reason] <
              g_region_probe.start_counter.cycle_reason[reason] ||
          g_region_probe.end_counter.slot_reason[reason] <
              g_region_probe.start_counter.slot_reason[reason]) {
        counter_arithmetic_ok = false;
        break;
      }
      cycle_reason[reason] =
          g_region_probe.end_counter.cycle_reason[reason] -
          g_region_probe.start_counter.cycle_reason[reason];
      slot_reason[reason] =
          g_region_probe.end_counter.slot_reason[reason] -
          g_region_probe.start_counter.slot_reason[reason];
    }
  }
  if (counter_arithmetic_ok) {
    for (uint32_t detail = 0; detail < MEMORY_REQUEST_DETAIL_COUNT;
         ++detail) {
      if (g_region_probe.end_counter.cycle_request_detail[detail] <
              g_region_probe.start_counter.cycle_request_detail[detail] ||
          g_region_probe.end_counter.slot_request_detail[detail] <
              g_region_probe.start_counter.slot_request_detail[detail]) {
        counter_arithmetic_ok = false;
        break;
      }
      cycle_request_detail[detail] =
          g_region_probe.end_counter.cycle_request_detail[detail] -
          g_region_probe.start_counter.cycle_request_detail[detail];
      slot_request_detail[detail] =
          g_region_probe.end_counter.slot_request_detail[detail] -
          g_region_probe.start_counter.slot_request_detail[detail];
    }
  }

  // Full-cycle deltas cover S+1..E.  Convert the slot ledger to the exact
  // committed-marker interval [before(start,lane), before(end,lane)) by adding
  // the suffix of S and removing the suffix of E.  Add first so the same-cycle
  // lane0->lane1 interval remains a one-slot positive case.
  if (counter_arithmetic_ok &&
      g_region_probe.start_lane < kMaxCommitEventsPerCycle &&
      g_region_probe.end_lane < kMaxCommitEventsPerCycle) {
    for (uint32_t lane = g_region_probe.start_lane;
         lane < kMaxCommitEventsPerCycle; ++lane) {
      const uint32_t reason =
          g_region_probe.start_counter.current_slot_reason[lane];
      if (reason >= RETIRE_REASON_COUNT ||
          !add_u64_checked(&slot_reason[reason], 1)) {
        counter_arithmetic_ok = false;
        counter_overflow = true;
        break;
      }
      if (reason == RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING) {
        const uint32_t detail =
            g_region_probe.start_counter.current_slot_request_detail[lane];
        if (detail == MEMORY_REQUEST_DETAIL_NONE ||
            detail >= MEMORY_REQUEST_DETAIL_COUNT ||
            !add_u64_checked(&slot_request_detail[detail], 1)) {
          counter_arithmetic_ok = false;
          counter_overflow = true;
          break;
        }
      }
    }
    for (uint32_t lane = g_region_probe.end_lane;
         counter_arithmetic_ok && lane < kMaxCommitEventsPerCycle; ++lane) {
      const uint32_t reason =
          g_region_probe.end_counter.current_slot_reason[lane];
      if (reason >= RETIRE_REASON_COUNT ||
          !sub_u64_checked(&slot_reason[reason], 1)) {
        counter_arithmetic_ok = false;
        break;
      }
      if (reason == RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING) {
        const uint32_t detail =
            g_region_probe.end_counter.current_slot_request_detail[lane];
        if (detail == MEMORY_REQUEST_DETAIL_NONE ||
            detail >= MEMORY_REQUEST_DETAIL_COUNT ||
            !sub_u64_checked(&slot_request_detail[detail], 1)) {
          counter_arithmetic_ok = false;
          break;
        }
      }
    }
  } else if (counter_arithmetic_ok) {
    counter_arithmetic_ok = false;
  }

  uint64_t invalid_events = 0;
  if (counter_available &&
      g_region_probe.end_counter.invalid_events >=
          g_region_probe.start_counter.invalid_events) {
    invalid_events = g_region_probe.end_counter.invalid_events -
                     g_region_probe.start_counter.invalid_events;
    if (g_region_probe.start_counter.current_invalid &&
        !add_u64_checked(&invalid_events, 1)) {
      counter_arithmetic_ok = false;
      counter_overflow = true;
    }
  } else if (counter_available) {
    counter_arithmetic_ok = false;
  }

  uint64_t slot_capacity = 0;
  if (counter_arithmetic_ok) {
    if (region_cycles > UINT64_MAX / kMaxCommitEventsPerCycle) {
      counter_arithmetic_ok = false;
      counter_overflow = true;
    } else {
      slot_capacity = region_cycles * kMaxCommitEventsPerCycle;
      if (g_region_probe.end_lane >= g_region_probe.start_lane) {
        if (!add_u64_checked(
                &slot_capacity,
                g_region_probe.end_lane - g_region_probe.start_lane)) {
          counter_arithmetic_ok = false;
          counter_overflow = true;
        }
      } else if (!sub_u64_checked(
                     &slot_capacity,
                     g_region_probe.start_lane - g_region_probe.end_lane)) {
        counter_arithmetic_ok = false;
      }
    }
  }

  uint64_t cycle_sum = 0;
  uint64_t unused_slots = 0;
  uint64_t slot_sum = 0;
  for (uint32_t reason = 0;
       counter_arithmetic_ok && reason < RETIRE_REASON_COUNT; ++reason) {
    if (!add_u64_checked(&cycle_sum, cycle_reason[reason]) ||
        !add_u64_checked(&slot_sum, slot_reason[reason]) ||
        (reason != RETIRE_REASON_RETIRED &&
         !add_u64_checked(&unused_slots, slot_reason[reason]))) {
      counter_arithmetic_ok = false;
      counter_overflow = true;
    }
  }

  const bool phase_aligned =
      g_region_probe.start_seen && g_region_probe.end_seen &&
      g_region_probe.start_lane == g_region_probe.end_lane;
  const uint64_t retired_slots = slot_reason[RETIRE_REASON_RETIRED];
  uint64_t cycle_head_not_complete = 0;
  uint64_t slot_head_not_complete = 0;
  uint64_t cycle_memory_latency = 0;
  uint64_t slot_memory_latency = 0;
  uint64_t cycle_memory_request_detail_sum = 0;
  uint64_t slot_memory_request_detail_sum = 0;
  for (uint32_t reason = RETIRE_REASON_DEPENDENCY;
       counter_arithmetic_ok &&
       reason <= RETIRE_REASON_HEAD_LIFECYCLE_UNKNOWN; ++reason) {
    if (!add_u64_checked(&cycle_head_not_complete, cycle_reason[reason]) ||
        !add_u64_checked(&slot_head_not_complete, slot_reason[reason])) {
      counter_arithmetic_ok = false;
      counter_overflow = true;
    }
  }
  for (uint32_t reason = RETIRE_REASON_MEMORY_RESERVATION_QUEUE;
       counter_arithmetic_ok &&
       reason <= RETIRE_REASON_MEMORY_LIFECYCLE_UNKNOWN; ++reason) {
    if (!add_u64_checked(&cycle_memory_latency, cycle_reason[reason]) ||
        !add_u64_checked(&slot_memory_latency, slot_reason[reason])) {
      counter_arithmetic_ok = false;
      counter_overflow = true;
    }
  }
  for (uint32_t detail = MEMORY_REQUEST_DETAIL_CACHE_LOOKUP;
       counter_arithmetic_ok && detail < MEMORY_REQUEST_DETAIL_COUNT;
       ++detail) {
    if (!add_u64_checked(&cycle_memory_request_detail_sum,
                         cycle_request_detail[detail]) ||
        !add_u64_checked(&slot_memory_request_detail_sum,
                         slot_request_detail[detail])) {
      counter_arithmetic_ok = false;
      counter_overflow = true;
    }
  }
  const bool request_detail_conservation = counter_arithmetic_ok &&
      cycle_request_detail[MEMORY_REQUEST_DETAIL_NONE] == 0 &&
      slot_request_detail[MEMORY_REQUEST_DETAIL_NONE] == 0 &&
      cycle_memory_request_detail_sum ==
          cycle_reason[RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING] &&
      slot_memory_request_detail_sum ==
          slot_reason[RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING];
  const bool conservation = counter_arithmetic_ok &&
      cycle_sum == region_cycles &&
      slot_sum == slot_capacity &&
      retired_slots == region_retired &&
      retired_slots <= slot_capacity &&
      unused_slots == slot_capacity - retired_slots &&
      request_detail_conservation;
  const bool counter_complete = complete && counter_available &&
                                counter_arithmetic_ok;

  LogBothTag("region_probe",
             "COUNTERS_FINAL schema=npc-rv64-performance-counter-v4"
             " complete=%u available=%u overflow=%u invalid_events=%llu"
             " start_lane=%u end_lane=%u phase_aligned=%u cycles=%llu"
             " cycle_useful=%llu cycle_rob_empty=%llu"
             " cycle_head_not_complete=%llu"
             " cycle_dependency=%llu cycle_issue_terminal=%llu"
             " cycle_execution_latency=%llu cycle_memory_latency=%llu"
             " cycle_memory_reservation_queue=%llu"
             " cycle_memory_translation_order=%llu"
             " cycle_memory_request_outstanding=%llu"
             " cycle_memory_request_cache_lookup=%llu"
             " cycle_memory_request_device_wait=%llu"
             " cycle_memory_request_axi_read_address=%llu"
             " cycle_memory_request_axi_read_data=%llu"
             " cycle_memory_request_axi_write_request=%llu"
             " cycle_memory_request_axi_write_response=%llu"
             " cycle_memory_request_detail_unknown=%llu"
             " cycle_memory_response_terminal=%llu"
             " cycle_memory_retry=%llu"
             " cycle_memory_lifecycle_unknown=%llu"
             " cycle_head_lifecycle_unknown=%llu"
             " cycle_exception_redirect=%llu cycle_memory_commit=%llu"
             " cycle_serialization=%llu cycle_unknown=%llu"
             " slot_capacity=%llu retired_slots=%llu unused_slots=%llu"
             " slot_rob_empty=%llu slot_head_not_complete=%llu"
             " slot_dependency=%llu slot_issue_terminal=%llu"
             " slot_execution_latency=%llu slot_memory_latency=%llu"
             " slot_memory_reservation_queue=%llu"
             " slot_memory_translation_order=%llu"
             " slot_memory_request_outstanding=%llu"
             " slot_memory_request_cache_lookup=%llu"
             " slot_memory_request_device_wait=%llu"
             " slot_memory_request_axi_read_address=%llu"
             " slot_memory_request_axi_read_data=%llu"
             " slot_memory_request_axi_write_request=%llu"
             " slot_memory_request_axi_write_response=%llu"
             " slot_memory_request_detail_unknown=%llu"
             " slot_memory_response_terminal=%llu"
             " slot_memory_retry=%llu"
             " slot_memory_lifecycle_unknown=%llu"
             " slot_head_lifecycle_unknown=%llu"
             " slot_exception_redirect=%llu slot_memory_commit=%llu"
             " slot_serialization=%llu slot_unknown=%llu conservation=%u",
             counter_complete ? 1u : 0u,
             counter_available ? 1u : 0u,
             counter_overflow ? 1u : 0u,
             (unsigned long long)invalid_events,
             g_region_probe.start_lane,
             g_region_probe.end_lane,
             phase_aligned ? 1u : 0u,
             (unsigned long long)region_cycles,
             (unsigned long long)cycle_reason[RETIRE_REASON_RETIRED],
             (unsigned long long)cycle_reason[RETIRE_REASON_ROB_EMPTY],
             (unsigned long long)cycle_head_not_complete,
             (unsigned long long)cycle_reason[RETIRE_REASON_DEPENDENCY],
             (unsigned long long)cycle_reason[RETIRE_REASON_ISSUE_TERMINAL],
             (unsigned long long)cycle_reason[RETIRE_REASON_EXECUTION_LATENCY],
             (unsigned long long)cycle_memory_latency,
             (unsigned long long)
                 cycle_reason[RETIRE_REASON_MEMORY_RESERVATION_QUEUE],
             (unsigned long long)
                 cycle_reason[RETIRE_REASON_MEMORY_TRANSLATION_ORDER],
             (unsigned long long)
                 cycle_reason[RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING],
             (unsigned long long)
                 cycle_request_detail[MEMORY_REQUEST_DETAIL_CACHE_LOOKUP],
             (unsigned long long)
                 cycle_request_detail[MEMORY_REQUEST_DETAIL_DEVICE_WAIT],
             (unsigned long long)
                 cycle_request_detail[MEMORY_REQUEST_DETAIL_AXI_READ_ADDRESS],
             (unsigned long long)
                 cycle_request_detail[MEMORY_REQUEST_DETAIL_AXI_READ_DATA],
             (unsigned long long)
                 cycle_request_detail[MEMORY_REQUEST_DETAIL_AXI_WRITE_REQUEST],
             (unsigned long long)
                 cycle_request_detail[MEMORY_REQUEST_DETAIL_AXI_WRITE_RESPONSE],
             (unsigned long long)
                 cycle_request_detail[MEMORY_REQUEST_DETAIL_UNKNOWN],
             (unsigned long long)
                 cycle_reason[RETIRE_REASON_MEMORY_RESPONSE_TERMINAL],
             (unsigned long long)cycle_reason[RETIRE_REASON_MEMORY_RETRY],
             (unsigned long long)
                 cycle_reason[RETIRE_REASON_MEMORY_LIFECYCLE_UNKNOWN],
             (unsigned long long)
                 cycle_reason[RETIRE_REASON_HEAD_LIFECYCLE_UNKNOWN],
             (unsigned long long)cycle_reason[RETIRE_REASON_EXCEPTION_REDIRECT],
             (unsigned long long)cycle_reason[RETIRE_REASON_MEMORY_COMMIT],
             (unsigned long long)cycle_reason[RETIRE_REASON_SERIALIZATION],
             (unsigned long long)cycle_reason[RETIRE_REASON_UNKNOWN],
             (unsigned long long)slot_capacity,
             (unsigned long long)retired_slots,
             (unsigned long long)unused_slots,
             (unsigned long long)slot_reason[RETIRE_REASON_ROB_EMPTY],
             (unsigned long long)slot_head_not_complete,
             (unsigned long long)slot_reason[RETIRE_REASON_DEPENDENCY],
             (unsigned long long)slot_reason[RETIRE_REASON_ISSUE_TERMINAL],
             (unsigned long long)slot_reason[RETIRE_REASON_EXECUTION_LATENCY],
             (unsigned long long)slot_memory_latency,
             (unsigned long long)
                 slot_reason[RETIRE_REASON_MEMORY_RESERVATION_QUEUE],
             (unsigned long long)
                 slot_reason[RETIRE_REASON_MEMORY_TRANSLATION_ORDER],
             (unsigned long long)
                 slot_reason[RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING],
             (unsigned long long)
                 slot_request_detail[MEMORY_REQUEST_DETAIL_CACHE_LOOKUP],
             (unsigned long long)
                 slot_request_detail[MEMORY_REQUEST_DETAIL_DEVICE_WAIT],
             (unsigned long long)
                 slot_request_detail[MEMORY_REQUEST_DETAIL_AXI_READ_ADDRESS],
             (unsigned long long)
                 slot_request_detail[MEMORY_REQUEST_DETAIL_AXI_READ_DATA],
             (unsigned long long)
                 slot_request_detail[MEMORY_REQUEST_DETAIL_AXI_WRITE_REQUEST],
             (unsigned long long)
                 slot_request_detail[MEMORY_REQUEST_DETAIL_AXI_WRITE_RESPONSE],
             (unsigned long long)
                 slot_request_detail[MEMORY_REQUEST_DETAIL_UNKNOWN],
             (unsigned long long)
                 slot_reason[RETIRE_REASON_MEMORY_RESPONSE_TERMINAL],
             (unsigned long long)slot_reason[RETIRE_REASON_MEMORY_RETRY],
             (unsigned long long)
                 slot_reason[RETIRE_REASON_MEMORY_LIFECYCLE_UNKNOWN],
             (unsigned long long)
                 slot_reason[RETIRE_REASON_HEAD_LIFECYCLE_UNKNOWN],
             (unsigned long long)slot_reason[RETIRE_REASON_EXCEPTION_REDIRECT],
             (unsigned long long)slot_reason[RETIRE_REASON_MEMORY_COMMIT],
             (unsigned long long)slot_reason[RETIRE_REASON_SERIALIZATION],
             (unsigned long long)slot_reason[RETIRE_REASON_UNKNOWN],
             conservation ? 1u : 0u);
}

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
  configure_region_probe();
  memset(g_shadow_gpr, 0, sizeof(g_shadow_gpr));
  memset(g_recent_commits, 0, sizeof(g_recent_commits));
  memset(g_recent_commit_seq, 0, sizeof(g_recent_commit_seq));
  g_recent_commit_count = 0;
  memset(g_recent_debug, 0, sizeof(g_recent_debug));
  g_recent_debug_count = 0;
  memset(&g_sim_perf, 0, sizeof(g_sim_perf));
#ifdef CONFIG_NPC_OOO_STATS
  reset_tensor_snapshot_epochs();
#endif
  memset(&g_retire_observation, 0, sizeof(g_retire_observation));
  memset(&g_sq_idle_fusion, 0, sizeof(g_sq_idle_fusion));
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
  event.mem_diag = (uint64_t)g_top->debug_mem_diag_o;
  event.fetch_pte_addr = (uint64_t)g_top->debug_fetch_pte_addr_o;
  event.fetch_pte = (uint64_t)g_top->debug_fetch_pte_o;
  event.fetch_pte_meta = (uint64_t)g_top->debug_fetch_pte_meta_o;
  ++g_recent_debug_count;
}

// 全状态 difftest: NpcSimTop 每 commit 拍 XMR 读 CsrFile → 更新本拍 CSR+priv 快照。
// 索引约定见 difftest.h/NEMU dut.c。commit event 填充时快照进 event->csr。
extern "C" void npc_arch_csr_event(
    npc_word_t c0, npc_word_t c1, npc_word_t c2, npc_word_t c3, npc_word_t c4,
    npc_word_t c5, npc_word_t c6, npc_word_t c7, npc_word_t c8, npc_word_t c9,
    npc_word_t c10, npc_word_t c11, npc_word_t c12, npc_word_t c13, npc_word_t c14,
    npc_word_t c15, npc_word_t c16, npc_word_t c17, npc_word_t c18, npc_word_t c19,
    npc_word_t c20, npc_word_t c21, npc_word_t c22) {
  const npc_word_t v[NPC_DIFF_CSR_N] = {
      c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11,
      c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22};
  for (int i = 0; i < NPC_DIFF_CSR_N; ++i) g_dut_csr_live[i] = v[i];
}

// 阶段2: NpcSimTop 每 commit 拍 XMR 读 arch FPR(32×64bit)→更新本拍 FPR 快照(32 scalar, 对称 CSR)。
extern "C" void npc_arch_fpr_event(
    uint64_t f0, uint64_t f1, uint64_t f2, uint64_t f3, uint64_t f4, uint64_t f5,
    uint64_t f6, uint64_t f7, uint64_t f8, uint64_t f9, uint64_t f10, uint64_t f11,
    uint64_t f12, uint64_t f13, uint64_t f14, uint64_t f15, uint64_t f16, uint64_t f17,
    uint64_t f18, uint64_t f19, uint64_t f20, uint64_t f21, uint64_t f22, uint64_t f23,
    uint64_t f24, uint64_t f25, uint64_t f26, uint64_t f27, uint64_t f28, uint64_t f29,
    uint64_t f30, uint64_t f31) {
  const uint64_t v[NPC_DIFF_FPR_N] = {
      f0, f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15,
      f16, f17, f18, f19, f20, f21, f22, f23, f24, f25, f26, f27, f28, f29, f30, f31};
  for (int i = 0; i < NPC_DIFF_FPR_N; ++i) g_dut_fpr_live[i] = v[i];
}

extern "C" void npc_commit_event(npc_word_t pc, uint32_t inst, npc_word_t next_pc,
                                 uint32_t rd_en, uint32_t rd_addr, npc_word_t rd_data,
                                 uint32_t is_fp) {
  // FP 提交不写整数 gpr(rd_en 对 difftest 的整数 gpr 更新, 故 FP 时 write_rd=0)。
  const bool write_rd = !is_fp && (rd_en != 0) && rd_addr > 0 && rd_addr < 32;
  if (is_fp) {
    // 阶段2 FPR shadow: FP 提交的 rd_addr/rd_data 复用为 FP arch addr/结果(OooIntBackend 用同一
    // commit0_data_o/arch_rd_o 写 arch FPR), 逐提交精确更新 shadow_fpr——对称 GPR shadow, 双提交/
    // co-issue 时 lane0/lane1 各更新自己的 FP rd, 无「同拍快照看不到另一 lane 写」的中间态污染。
    if (rd_addr < 32) g_shadow_fpr[rd_addr] = rd_data;
  } else if (write_rd) {
    g_shadow_gpr[rd_addr] = rd_data;
  }
  g_shadow_gpr[0] = 0;

#ifdef CONFIG_NPC_BRANCH_STATS
  record_ooo_control_flow_commit(pc, inst, next_pc);
#endif
  maybe_log_commit_watch(pc, inst, next_pc, rd_en, rd_addr, rd_data);
  maybe_log_user_trace(pc, inst, next_pc);

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
    // CSR+priv 快照(本拍值)。CSR 写指令 serialize 单发→双提交里无 CSR 写，两条 CSR 同值。
    memcpy(event->csr, g_dut_csr_live, sizeof(event->csr));
    memcpy(event->fpr, g_shadow_fpr, sizeof(event->fpr));   // 阶段2 FPR shadow(逐提交精确, 抗 co-issue)
    remember_commit_event(event);
  }
}

extern "C" void npc_exit_event(uint32_t is_ebreak, uint32_t is_ecall,
                               uint32_t is_system_reset,
                               npc_word_t code, npc_word_t pc) {
  g_exit_event.valid = true;
  g_exit_event.is_ebreak = is_ebreak != 0;
  g_exit_event.is_ecall = is_ecall != 0;
  g_exit_event.is_system_reset = is_system_reset != 0;
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
  maybe_log_ecall_trap(kind, cause, pc, tval);

#if CONFIG_NPC_DIFFTEST
  // 阶段4 中断同步: kind==2(irq)登记 pending 中断(mcause = interrupt bit | cause 号),
  // difftest 在 handler 首条 commit 的同步点让 NEMU raise 同中断(见 difftest.cpp 自主恢复)。
  if (kind == 2 && npc_difftest_enabled()) {
    npc_difftest_set_pending_intr(((uint64_t)1 << 63) | (uint64_t)cause);
  }
#endif

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

#ifdef CONFIG_NPC_BRANCH_STATS
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
#endif  // CONFIG_NPC_BRANCH_STATS

#ifdef CONFIG_NPC_CACHE_STATS
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
#endif  // CONFIG_NPC_CACHE_STATS

#ifdef CONFIG_NPC_OOO_STATS
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

static double pct_u64(uint64_t value, uint64_t total) {
  return total == 0 ? 0.0 : (100.0 * (double)value / (double)total);
}

static void init_ooo_window_config(void) {
  if (g_ooo_window_config_inited) return;
  g_ooo_window_config_inited = true;

  const char *enabled_s = std::getenv("NPC_OOO_WINDOW");
  if (enabled_s != nullptr && enabled_s[0] != '\0') {
    char c = (char)std::tolower((unsigned char)enabled_s[0]);
    g_ooo_window_enabled = !(c == '0' || c == 'n' || c == 'f');
  }

  const char *cycles_s = std::getenv("NPC_OOO_WINDOW_CYCLES");
  if (cycles_s != nullptr && cycles_s[0] != '\0') {
    char *end = nullptr;
    uint64_t value = std::strtoull(cycles_s, &end, 0);
    if (end != cycles_s && *end == '\0' && value != 0) {
      g_ooo_window_cycles = value;
    }
  }
}

static void clear_ooo_window(uint64_t start_cycle) {
  memset(&g_ooo_window, 0, sizeof(g_ooo_window));
  g_ooo_window.start_cycle = start_cycle;
}

static void report_ooo_window(bool partial) {
  if (!g_ooo_window_enabled || g_ooo_window.cycles == 0) return;

  uint64_t end_cycle = g_ooo_window.start_cycle + g_ooo_window.cycles - 1;
  LogBothTag("ooo_window",
             "%s cycles=%llu..%llu n=%llu retire=%llu exec=%llu dispatch=%llu "
             "fetch=%llu(%.1f%%) mem=%llu(%.1f%%) axi_wait=%llu(%.1f%%) "
             "hazard=%llu(%.1f%%) branch_flush=%llu(%.1f%%) exception=%llu(%.1f%%)",
             partial ? "partial" : "window",
             (unsigned long long)g_ooo_window.start_cycle,
             (unsigned long long)end_cycle,
             (unsigned long long)g_ooo_window.cycles,
             (unsigned long long)g_ooo_window.retire,
             (unsigned long long)g_ooo_window.execute,
             (unsigned long long)g_ooo_window.dispatch,
             (unsigned long long)g_ooo_window.fetch_busy,
             pct_u64(g_ooo_window.fetch_busy, g_ooo_window.cycles),
             (unsigned long long)g_ooo_window.mem_busy,
             pct_u64(g_ooo_window.mem_busy, g_ooo_window.cycles),
             (unsigned long long)g_ooo_window.axi_wait,
             pct_u64(g_ooo_window.axi_wait, g_ooo_window.cycles),
             (unsigned long long)g_ooo_window.hazard_busy,
             pct_u64(g_ooo_window.hazard_busy, g_ooo_window.cycles),
             (unsigned long long)g_ooo_window.branch_flush,
             pct_u64(g_ooo_window.branch_flush, g_ooo_window.cycles),
             (unsigned long long)g_ooo_window.exception_busy,
             pct_u64(g_ooo_window.exception_busy, g_ooo_window.cycles));
}

static void bump_ooo_window(uint32_t retire_count, uint32_t execute_count,
                            uint32_t dispatch_count, uint32_t fetch_busy,
                            uint32_t mem_busy, uint32_t axi_wait,
                            uint32_t hazard_busy, uint32_t branch_flush,
                            uint32_t exception_busy) {
  init_ooo_window_config();
  if (!g_ooo_window_enabled) return;

  if (g_ooo_window.cycles == 0) {
    g_ooo_window.start_cycle = g_sim_perf.ooo_cycles;
  }
  g_ooo_window.cycles++;
  g_ooo_window.retire += retire_count;
  g_ooo_window.execute += execute_count;
  g_ooo_window.dispatch += dispatch_count;
  g_ooo_window.fetch_busy += fetch_busy ? 1u : 0u;
  g_ooo_window.mem_busy += mem_busy ? 1u : 0u;
  g_ooo_window.axi_wait += axi_wait ? 1u : 0u;
  g_ooo_window.hazard_busy += hazard_busy ? 1u : 0u;
  g_ooo_window.branch_flush += branch_flush ? 1u : 0u;
  g_ooo_window.exception_busy += exception_busy ? 1u : 0u;

  if (g_ooo_window.cycles >= g_ooo_window_cycles) {
    report_ooo_window(false);
    clear_ooo_window(g_sim_perf.ooo_cycles + 1);
  }
}

static void bump_retire_observation_counter(uint64_t *counter,
                                            bool *event_overflow) {
  if (add_u64_checked(counter, 1)) return;
  if (counter != nullptr) *counter = UINT64_MAX;
  if (event_overflow != nullptr) *event_overflow = true;
}

static void record_retire_observation_event(uint32_t retire_count,
                                            uint32_t slot0_reason,
                                            uint32_t slot1_reason,
                                            uint32_t slot0_request_detail,
                                            uint32_t slot1_request_detail) {
  bool event_invalid = false;
  bool event_overflow = false;

  uint64_t event_cycle = npc_stats()->cycles;
  if (!add_u64_checked(&event_cycle, 1)) {
    event_overflow = true;
  }
  if (g_retire_observation.current_valid) {
    uint64_t expected_cycle = g_retire_observation.current_cycle;
    if (!add_u64_checked(&expected_cycle, 1)) {
      event_overflow = true;
    } else if (event_cycle != expected_cycle) {
      event_invalid = true;
    }
  }

  if (slot0_reason >= RETIRE_REASON_COUNT) {
    slot0_reason = RETIRE_REASON_UNKNOWN;
    event_invalid = true;
  }
  if (slot1_reason >= RETIRE_REASON_COUNT) {
    slot1_reason = RETIRE_REASON_UNKNOWN;
    event_invalid = true;
  }
  if (slot0_request_detail >= MEMORY_REQUEST_DETAIL_COUNT) {
    slot0_request_detail = MEMORY_REQUEST_DETAIL_UNKNOWN;
    event_invalid = true;
  }
  if (slot1_request_detail >= MEMORY_REQUEST_DETAIL_COUNT) {
    slot1_request_detail = MEMORY_REQUEST_DETAIL_UNKNOWN;
    event_invalid = true;
  }
  if (slot0_reason == RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING) {
    if (slot0_request_detail == MEMORY_REQUEST_DETAIL_NONE) {
      slot0_request_detail = MEMORY_REQUEST_DETAIL_UNKNOWN;
      event_invalid = true;
    }
  } else if (slot0_request_detail != MEMORY_REQUEST_DETAIL_NONE) {
    slot0_request_detail = MEMORY_REQUEST_DETAIL_NONE;
    event_invalid = true;
  }
  if (slot1_reason == RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING) {
    if (slot1_request_detail == MEMORY_REQUEST_DETAIL_NONE) {
      slot1_request_detail = MEMORY_REQUEST_DETAIL_UNKNOWN;
      event_invalid = true;
    }
  } else if (slot1_request_detail != MEMORY_REQUEST_DETAIL_NONE) {
    slot1_request_detail = MEMORY_REQUEST_DETAIL_NONE;
    event_invalid = true;
  }
  if (retire_count > kMaxCommitEventsPerCycle) event_invalid = true;
  const uint32_t encoded_retire_count =
      (slot0_reason == RETIRE_REASON_RETIRED ? 1u : 0u) +
      (slot1_reason == RETIRE_REASON_RETIRED ? 1u : 0u);
  if (encoded_retire_count != retire_count ||
      (slot1_reason == RETIRE_REASON_RETIRED &&
       slot0_reason != RETIRE_REASON_RETIRED)) {
    event_invalid = true;
  }

  const uint32_t cycle_reason = retire_count != 0
      ? RETIRE_REASON_RETIRED : slot0_reason;
  bump_retire_observation_counter(
      &g_retire_observation.cycle_reason[cycle_reason], &event_overflow);
  bump_retire_observation_counter(
      &g_retire_observation.slot_reason[slot0_reason], &event_overflow);
  bump_retire_observation_counter(
      &g_retire_observation.slot_reason[slot1_reason], &event_overflow);
  if (cycle_reason == RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING) {
    bump_retire_observation_counter(
        &g_retire_observation.cycle_request_detail[slot0_request_detail],
        &event_overflow);
  }
  if (slot0_reason == RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING) {
    bump_retire_observation_counter(
        &g_retire_observation.slot_request_detail[slot0_request_detail],
        &event_overflow);
  }
  if (slot1_reason == RETIRE_REASON_MEMORY_REQUEST_OUTSTANDING) {
    bump_retire_observation_counter(
        &g_retire_observation.slot_request_detail[slot1_request_detail],
        &event_overflow);
  }
  if (event_invalid) {
    bump_retire_observation_counter(
        &g_retire_observation.invalid_events, &event_overflow);
  }

  g_retire_observation.current_slot_reason[0] = slot0_reason;
  g_retire_observation.current_slot_reason[1] = slot1_reason;
  g_retire_observation.current_slot_request_detail[0] =
      slot0_request_detail;
  g_retire_observation.current_slot_request_detail[1] =
      slot1_request_detail;
  g_retire_observation.current_cycle = event_cycle;
  g_retire_observation.current_valid = true;
  g_retire_observation.current_invalid = event_invalid;
  g_retire_observation.current_overflow = event_overflow;
  g_retire_observation.overflow =
      g_retire_observation.overflow || event_overflow;
}

static constexpr uint64_t sq_idle_fusion_pair_popcount(uint32_t pair) {
  return static_cast<uint64_t>(pair & 1u) +
         static_cast<uint64_t>((pair >> 1) & 1u);
}

static_assert(sq_idle_fusion_pair_popcount(0x3u) == 2u,
              "a two-lane SQ event pair must contribute two");

static void bump_sq_idle_fusion_counter(uint64_t *counter,
                                        uint64_t increment,
                                        bool *event_overflow) {
  if (add_u64_checked(counter, increment)) return;
  if (counter != nullptr) *counter = UINT64_MAX;
  if (event_overflow != nullptr) *event_overflow = true;
}

static void record_sq_idle_fusion_event(uint32_t mask) {
  static constexpr uint32_t kReservedMask = 0xffffc000u;
  bool event_encoding_malformed = (mask & kReservedMask) != 0;
  bool event_sequence_malformed = false;
  bool event_overflow = false;

  uint64_t event_cycle = npc_stats()->cycles;
  if (!add_u64_checked(&event_cycle, 1)) {
    event_overflow = true;
  }
  if (g_sq_idle_fusion.current_valid) {
    uint64_t expected_cycle = g_sq_idle_fusion.current_cycle;
    if (!add_u64_checked(&expected_cycle, 1)) {
      event_overflow = true;
    } else if (event_cycle != expected_cycle) {
      event_sequence_malformed = true;
    }
  } else if (event_cycle != 1) {
    event_sequence_malformed = true;
  }

  const uint32_t prequal = (mask >> 0) & 0x3u;
  const uint32_t exact = (mask >> 2) & 0x3u;
  const uint32_t allow = (mask >> 4) & 0x3u;
  const uint32_t forward = (mask >> 6) & 0x3u;
  const uint32_t replay = (mask >> 8) & 0x3u;
  const uint32_t invalid = (mask >> 10) & 0x3u;
  const uint32_t allow_rob_head = (mask >> 12) & 0x3u;
  const uint32_t decision_partition = allow | forward | replay | invalid;
  if ((exact & ~prequal) != 0 ||
      ((allow | forward | replay | invalid) & ~exact) != 0 ||
      (allow_rob_head & ~allow) != 0 ||
      (allow & forward) != 0 || (allow & replay) != 0 ||
      (allow & invalid) != 0 || (forward & replay) != 0 ||
      (forward & invalid) != 0 || (replay & invalid) != 0 ||
      decision_partition != exact) {
    event_encoding_malformed = true;
  }

  bump_sq_idle_fusion_counter(
      &g_sq_idle_fusion.counters.cycles, 1, &event_overflow);
  bump_sq_idle_fusion_counter(
      &g_sq_idle_fusion.counters.prequal,
      sq_idle_fusion_pair_popcount(prequal), &event_overflow);
  bump_sq_idle_fusion_counter(
      &g_sq_idle_fusion.counters.exact,
      sq_idle_fusion_pair_popcount(exact), &event_overflow);
  bump_sq_idle_fusion_counter(
      &g_sq_idle_fusion.counters.allow,
      sq_idle_fusion_pair_popcount(allow), &event_overflow);
  bump_sq_idle_fusion_counter(
      &g_sq_idle_fusion.counters.forward,
      sq_idle_fusion_pair_popcount(forward), &event_overflow);
  bump_sq_idle_fusion_counter(
      &g_sq_idle_fusion.counters.replay,
      sq_idle_fusion_pair_popcount(replay), &event_overflow);
  bump_sq_idle_fusion_counter(
      &g_sq_idle_fusion.counters.invalid,
      sq_idle_fusion_pair_popcount(invalid), &event_overflow);
  bump_sq_idle_fusion_counter(
      &g_sq_idle_fusion.counters.allow_rob_head,
      sq_idle_fusion_pair_popcount(allow_rob_head), &event_overflow);

  g_sq_idle_fusion.current_cycle = event_cycle;
  g_sq_idle_fusion.current_valid = true;
  g_sq_idle_fusion.encoding_malformed =
      g_sq_idle_fusion.encoding_malformed || event_encoding_malformed;
  g_sq_idle_fusion.sequence_malformed =
      g_sq_idle_fusion.sequence_malformed || event_sequence_malformed;
  g_sq_idle_fusion.overflow =
      g_sq_idle_fusion.overflow || event_overflow;
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
                                    uint32_t fetch_busy,
                                    uint32_t mem_busy,
                                    uint32_t axi_wait,
                                    uint32_t hazard_busy,
                                    uint32_t branch_flush,
                                    uint32_t exception_busy,
                                    npc_word_t pending_branch_pc,
                                    npc_word_t pending_jump_pc,
                                    uint32_t retire_slot0_reason,
                                    uint32_t retire_slot1_reason,
                                    uint32_t retire_slot0_request_detail,
                                    uint32_t retire_slot1_request_detail,
                                    uint32_t tensor_issued_count,
                                    uint32_t tensor_terminal_count,
                                    uint32_t tensor_completion_count,
                                    uint32_t tensor_wait_head_cycles,
                                    uint32_t tensor_wait_drain_cycles,
                                    uint32_t tensor_npu_backpressure_cycles,
                                    uint32_t tensor_serialize_cycles,
                                    uint32_t tensor_alloc_direct_issue_count,
                                    uint32_t tensor_attr_prelaunch_cancel_cycles,
                                    uint32_t tensor_attr_wait_not_exact_head_cycles,
                                    uint32_t tensor_attr_wait_launch_gate_cycles,
                                    uint32_t tensor_attr_wait_src_dependency_cycles,
                                    uint32_t tensor_attr_wait_src_value_cycles,
                                    uint32_t tensor_attr_wait_mem_active_cycles,
                                    uint32_t tensor_attr_wait_mem_retire_cycles,
                                    uint32_t tensor_attr_launch_to_offer_cycles,
                                    uint32_t tensor_attr_offer_backpressure_cycles,
                                    uint32_t tensor_attr_offer_accept_cycles,
                                    uint32_t tensor_attr_sent_terminal_absent_cycles,
                                    uint32_t tensor_attr_sent_terminal_stale_cycles,
                                    uint32_t tensor_attr_sent_terminal_accept_cycles,
                                    uint32_t tensor_attr_complete_wb_backpressure_cycles,
                                    uint32_t tensor_attr_complete_stale_drop_cycles,
                                    uint32_t tensor_attr_complete_wb_accept_cycles,
                                    uint32_t tensor_attr_invalid_state_cycles,
                                    uint32_t tensor_attr_sent_terminal_completion_stale_cycles,
                                    uint32_t tensor_attr_sent_terminal_wb_accept_cycles,
                                    uint32_t sq_idle_fusion_qualification_mask) {
  record_retire_observation_event(retire_count, retire_slot0_reason,
                                  retire_slot1_reason,
                                  retire_slot0_request_detail,
                                  retire_slot1_request_detail);
  record_sq_idle_fusion_event(sq_idle_fusion_qualification_mask);
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
  g_sim_perf.ooo_fetch_busy_cycles += fetch_busy ? 1u : 0u;
  g_sim_perf.ooo_mem_busy_cycles += mem_busy ? 1u : 0u;
  g_sim_perf.ooo_axi_wait_cycles += axi_wait ? 1u : 0u;
  g_sim_perf.ooo_hazard_busy_cycles += hazard_busy ? 1u : 0u;
  g_sim_perf.ooo_branch_flush_cycles += branch_flush ? 1u : 0u;
  g_sim_perf.ooo_exception_busy_cycles += exception_busy ? 1u : 0u;
  // The DPI callback runs in the SV active region, before this edge's NBA
  // counter updates.  Preserve these parameters for the direct-system ABI,
  // but production takes its authoritative snapshot after eval() returns.
  (void)tensor_issued_count;
  (void)tensor_terminal_count;
  (void)tensor_completion_count;
  (void)tensor_wait_head_cycles;
  (void)tensor_wait_drain_cycles;
  (void)tensor_npu_backpressure_cycles;
  (void)tensor_serialize_cycles;
  (void)tensor_alloc_direct_issue_count;
  (void)tensor_attr_prelaunch_cancel_cycles;
  (void)tensor_attr_wait_not_exact_head_cycles;
  (void)tensor_attr_wait_launch_gate_cycles;
  (void)tensor_attr_wait_src_dependency_cycles;
  (void)tensor_attr_wait_src_value_cycles;
  (void)tensor_attr_wait_mem_active_cycles;
  (void)tensor_attr_wait_mem_retire_cycles;
  (void)tensor_attr_launch_to_offer_cycles;
  (void)tensor_attr_offer_backpressure_cycles;
  (void)tensor_attr_offer_accept_cycles;
  (void)tensor_attr_sent_terminal_absent_cycles;
  (void)tensor_attr_sent_terminal_stale_cycles;
  (void)tensor_attr_sent_terminal_accept_cycles;
  (void)tensor_attr_complete_wb_backpressure_cycles;
  (void)tensor_attr_complete_stale_drop_cycles;
  (void)tensor_attr_complete_wb_accept_cycles;
  (void)tensor_attr_invalid_state_cycles;
  (void)tensor_attr_sent_terminal_completion_stale_cycles;
  (void)tensor_attr_sent_terminal_wb_accept_cycles;
  bump_ooo_window(retire_count, execute_count, dispatch_count, fetch_busy,
                  mem_busy, axi_wait, hazard_busy, branch_flush,
                  exception_busy);
}
#endif  // CONFIG_NPC_OOO_STATS

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
#ifdef CONFIG_NPC_BRANCH_STATS
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

#endif  // CONFIG_NPC_BRANCH_STATS

#ifdef CONFIG_NPC_CACHE_STATS
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

#endif  // CONFIG_NPC_CACHE_STATS

#ifdef CONFIG_NPC_OOO_STATS
static void report_ooo_stats(void) {
  report_sq_idle_fusion_final();
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
  LogBothTag("statistic",
             "cycle buckets (overlap): fetch=%llu(%.1f%%), mem=%llu(%.1f%%), axi_wait=%llu(%.1f%%), hazard=%llu(%.1f%%), branch_flush=%llu(%.1f%%), exception=%llu(%.1f%%)",
             (unsigned long long)g_sim_perf.ooo_fetch_busy_cycles,
             pct_u64(g_sim_perf.ooo_fetch_busy_cycles,
                     g_sim_perf.ooo_cycles),
             (unsigned long long)g_sim_perf.ooo_mem_busy_cycles,
             pct_u64(g_sim_perf.ooo_mem_busy_cycles, g_sim_perf.ooo_cycles),
             (unsigned long long)g_sim_perf.ooo_axi_wait_cycles,
             pct_u64(g_sim_perf.ooo_axi_wait_cycles, g_sim_perf.ooo_cycles),
             (unsigned long long)g_sim_perf.ooo_hazard_busy_cycles,
             pct_u64(g_sim_perf.ooo_hazard_busy_cycles,
                     g_sim_perf.ooo_cycles),
             (unsigned long long)g_sim_perf.ooo_branch_flush_cycles,
             pct_u64(g_sim_perf.ooo_branch_flush_cycles,
                     g_sim_perf.ooo_cycles),
             (unsigned long long)g_sim_perf.ooo_exception_busy_cycles,
             pct_u64(g_sim_perf.ooo_exception_busy_cycles,
                     g_sim_perf.ooo_cycles));
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
  const uint64_t tensor_attributed_cycles =
      g_sim_perf.ooo_tensor_wait_head_cycles +
      g_sim_perf.ooo_tensor_wait_drain_cycles +
      g_sim_perf.ooo_tensor_npu_backpressure_cycles;
  const bool tensor_bucket_overflow =
      tensor_attributed_cycles > g_sim_perf.ooo_tensor_serialize_cycles;
  const uint64_t tensor_unattributed_cycles = tensor_bucket_overflow
      ? 0
      : g_sim_perf.ooo_tensor_serialize_cycles - tensor_attributed_cycles;
  const int64_t tensor_issued_terminal_gap =
      static_cast<int64_t>(g_sim_perf.ooo_tensor_issued_count) -
      static_cast<int64_t>(g_sim_perf.ooo_tensor_terminal_count);
  const int64_t tensor_terminal_completion_gap =
      static_cast<int64_t>(g_sim_perf.ooo_tensor_terminal_count) -
      static_cast<int64_t>(g_sim_perf.ooo_tensor_completion_count);
  const double tensor_issued_den =
      g_sim_perf.ooo_tensor_issued_count == 0
          ? 1.0
          : static_cast<double>(g_sim_perf.ooo_tensor_issued_count);
  LogBothTag("statistic",
             "tensor issued/terminal/completion = %llu/%llu/%llu, gaps issued-terminal/terminal-completion = %lld/%lld",
             (unsigned long long)g_sim_perf.ooo_tensor_issued_count,
             (unsigned long long)g_sim_perf.ooo_tensor_terminal_count,
             (unsigned long long)g_sim_perf.ooo_tensor_completion_count,
             (long long)tensor_issued_terminal_gap,
             (long long)tensor_terminal_completion_gap);
  LogBothTag("statistic",
             "tensor allocation-edge direct issues = %llu/%llu",
             (unsigned long long)
                 g_sim_perf.ooo_tensor_alloc_direct_issue_count,
             (unsigned long long)g_sim_perf.ooo_tensor_issued_count);
  LogBothTag("statistic",
             "tensor cycles: serialize=%llu, wait-head=%llu, wait-drain=%llu, cmd-backpressure=%llu, unattributed=%llu%s",
             (unsigned long long)g_sim_perf.ooo_tensor_serialize_cycles,
             (unsigned long long)g_sim_perf.ooo_tensor_wait_head_cycles,
             (unsigned long long)g_sim_perf.ooo_tensor_wait_drain_cycles,
             (unsigned long long)g_sim_perf.ooo_tensor_npu_backpressure_cycles,
             (unsigned long long)tensor_unattributed_cycles,
             tensor_bucket_overflow ? " [bucket-overflow]" : "");
  LogBothTag("statistic",
             "tensor cycles/issued: serialize=%.2f, wait-head=%.2f, wait-drain=%.2f, cmd-backpressure=%.2f, unattributed=%.2f",
             static_cast<double>(g_sim_perf.ooo_tensor_serialize_cycles) /
                 tensor_issued_den,
             static_cast<double>(g_sim_perf.ooo_tensor_wait_head_cycles) /
                 tensor_issued_den,
             static_cast<double>(g_sim_perf.ooo_tensor_wait_drain_cycles) /
                 tensor_issued_den,
             static_cast<double>(
                 g_sim_perf.ooo_tensor_npu_backpressure_cycles) /
                 tensor_issued_den,
             static_cast<double>(tensor_unattributed_cycles) /
                 tensor_issued_den);
  const uint64_t tensor_attribution_counters[] = {
      g_sim_perf.ooo_tensor_attr_prelaunch_cancel_cycles,
      g_sim_perf.ooo_tensor_attr_wait_not_exact_head_cycles,
      g_sim_perf.ooo_tensor_attr_wait_launch_gate_cycles,
      g_sim_perf.ooo_tensor_attr_wait_src_dependency_cycles,
      g_sim_perf.ooo_tensor_attr_wait_src_value_cycles,
      g_sim_perf.ooo_tensor_attr_wait_mem_active_cycles,
      g_sim_perf.ooo_tensor_attr_wait_mem_retire_cycles,
      g_sim_perf.ooo_tensor_attr_launch_to_offer_cycles,
      g_sim_perf.ooo_tensor_attr_offer_backpressure_cycles,
      g_sim_perf.ooo_tensor_attr_offer_accept_cycles,
      g_sim_perf.ooo_tensor_attr_sent_terminal_absent_cycles,
      g_sim_perf.ooo_tensor_attr_sent_terminal_stale_cycles,
      g_sim_perf.ooo_tensor_attr_sent_terminal_accept_cycles,
      g_sim_perf.ooo_tensor_attr_complete_wb_backpressure_cycles,
      g_sim_perf.ooo_tensor_attr_complete_stale_drop_cycles,
      g_sim_perf.ooo_tensor_attr_complete_wb_accept_cycles,
      g_sim_perf.ooo_tensor_attr_invalid_state_cycles,
      g_sim_perf.ooo_tensor_attr_sent_terminal_completion_stale_cycles,
      g_sim_perf.ooo_tensor_attr_sent_terminal_wb_accept_cycles,
  };
  uint64_t tensor_attribution_sum = 0;
  bool tensor_attribution_overflow = false;
  for (uint64_t counter : tensor_attribution_counters) {
    if (!add_u64_checked(&tensor_attribution_sum, counter)) {
      tensor_attribution_overflow = true;
      break;
    }
  }
  const bool tensor_attribution_partition_ok =
      !tensor_attribution_overflow &&
      tensor_attribution_sum == g_sim_perf.ooo_tensor_serialize_cycles;
  LogBoth(
      "[TENSOR-ATTRIBUTION] prelaunch_cancel=%llu wait_not_exact_head=%llu wait_launch_gate=%llu wait_src_dependency=%llu wait_src_value=%llu wait_mem_active=%llu wait_mem_retire=%llu launch_to_offer=%llu offer_backpressure=%llu offer_accept=%llu sent_terminal_absent=%llu sent_terminal_stale=%llu sent_terminal_accept=%llu complete_wb_backpressure=%llu complete_stale_drop=%llu complete_wb_accept=%llu invalid_state=%llu sent_terminal_completion_stale=%llu sent_terminal_wb_accept=%llu sum=%llu serialize=%llu overflow=%u partition_ok=%u",
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_prelaunch_cancel_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_wait_not_exact_head_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_wait_launch_gate_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_wait_src_dependency_cycles,
      (unsigned long long)g_sim_perf.ooo_tensor_attr_wait_src_value_cycles,
      (unsigned long long)g_sim_perf.ooo_tensor_attr_wait_mem_active_cycles,
      (unsigned long long)g_sim_perf.ooo_tensor_attr_wait_mem_retire_cycles,
      (unsigned long long)g_sim_perf.ooo_tensor_attr_launch_to_offer_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_offer_backpressure_cycles,
      (unsigned long long)g_sim_perf.ooo_tensor_attr_offer_accept_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_sent_terminal_absent_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_sent_terminal_stale_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_sent_terminal_accept_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_complete_wb_backpressure_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_complete_stale_drop_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_complete_wb_accept_cycles,
      (unsigned long long)g_sim_perf.ooo_tensor_attr_invalid_state_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_sent_terminal_completion_stale_cycles,
      (unsigned long long)
          g_sim_perf.ooo_tensor_attr_sent_terminal_wb_accept_cycles,
      (unsigned long long)tensor_attribution_sum,
      (unsigned long long)g_sim_perf.ooo_tensor_serialize_cycles,
      tensor_attribution_overflow ? 1u : 0u,
      tensor_attribution_partition_ok ? 1u : 0u);
  LogBothTag("statistic", "tensor attribution partition check = %s",
             tensor_attribution_partition_ok ? "PASS" : "FAIL");
  report_ooo_window(true);
}
#endif  // CONFIG_NPC_OOO_STATS

// NEMU 风格统计 + CPI + 分支统计，NPC 跑分结果可直接和参考模型对比
static void report_statistics(void) {
#ifdef CONFIG_NPC_SUMMARY_STATS
  // CLINT mtime 按 NpcTop.v 的 CLINT_MTIME_DIVISOR 预分频(每 N 个 core 周期 mtime+1),
  // 期望值是 cycles/N 而非 cycles;旧诊断直接拿 mtime==cycles 判等,永远 mismatch。
  // 容忍 ±1 拍采样相位偏移(mtime 与 cycles 同在 posedge 更新)。
  uint64_t mtime_expected = npc_stats()->cycles / NPC_CLINT_MTIME_DIVISOR;
  uint64_t mtime_now      = npc_stats()->clint_mtime;
  uint64_t mtime_absdiff  = (mtime_now >= mtime_expected)
                              ? (mtime_now - mtime_expected)
                              : (mtime_expected - mtime_now);
  char mtime_delta[48];
  format_u64_delta(mtime_delta, sizeof(mtime_delta),
                   mtime_now, mtime_expected);

  LogBothTag("statistic", "host time spent = %llu us",
          (unsigned long long)npc_stats()->host_time_us);
  LogBothTag("statistic", "total guest instructions = %llu",
          (unsigned long long)npc_stats()->commits);
  // 新增 cycles 和 CPI 输出，对齐参考工程的统计格式
  LogBothTag("statistic", "total guest cycles = %llu",
          (unsigned long long)npc_stats()->cycles);
  LogBothTag("statistic", "CLINT mtime = %llu (= cycles/%u, expected %llu, delta=%s, match=%s)",
          (unsigned long long)mtime_now,
          (unsigned)NPC_CLINT_MTIME_DIVISOR,
          (unsigned long long)mtime_expected,
          mtime_delta,
          (mtime_absdiff <= 1) ? "yes" : "no");
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
#endif  // CONFIG_NPC_SUMMARY_STATS
#ifdef CONFIG_NPC_BRANCH_STATS
  report_branch_stats();
#endif
#ifdef CONFIG_NPC_CACHE_STATS
  report_cache_stats();
#endif
#ifdef CONFIG_NPC_OOO_STATS
  report_ooo_stats();
#endif
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
    uint64_t mem_diag = event.mem_diag;
    LogBothTag("cpu_exec",
               "  cyc=%llu commits=%llu pc=0x%016" NPC_PRIxWORD
               " state=%u stop=%llu csr_head=%llu spec=%llu/%llu synth=%llu/%llu "
               "arch=%llu sys=%llu trap_ex=%llu cause=%llu "
               "fifo=%llu fetch_state=%llu frsp=%llu/%llu out=%llu ifu_ar=%llu/%llu "
               "ifu_r=%llu/%llu active=0x%04llx ar_sent=0x%04llx fetch_addr=0x%016llx "
               "mem_addr=0x%016llx mdiag=0x%016llx br=%llu/%llu "
               "q0=%llu:%llu%llu%llu:%llu q1=%llu:%llu%llu%llu:%llu "
               "exact=%llu/%llu lq=%llu/%llu retry=%llu/%llu sel=%llu/%llu "
               "store=%llu/%llu older=%llu/%llu grant=%llu%llu/%llu%llu sq=%llu/%llu "
               "pte_addr=0x%016llx pte=0x%016llx pte_meta=0x%llx",
               (unsigned long long)event.cycle,
               (unsigned long long)event.commits,
               event.pc,
               event.state,
               (unsigned long long)((flags >> 0) & 1u),
               (unsigned long long)((flags >> 45) & 1u),
               (unsigned long long)((flags >> 44) & 1u),
               (unsigned long long)((flags >> 43) & 1u),
               (unsigned long long)((flags >> 42) & 1u),
               (unsigned long long)((flags >> 41) & 1u),
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
               (unsigned long long)mem_diag,
               (unsigned long long)((mem_diag >> 0) & 0xfu),
               (unsigned long long)((mem_diag >> 4) & 0xfu),
               (unsigned long long)((mem_diag >> 10) & 1u),
               (unsigned long long)((mem_diag >> 11) & 1u),
               (unsigned long long)((mem_diag >> 12) & 1u),
               (unsigned long long)((mem_diag >> 13) & 1u),
               (unsigned long long)((mem_diag >> 14) & 1u),
               (unsigned long long)((mem_diag >> 15) & 1u),
               (unsigned long long)((mem_diag >> 16) & 1u),
               (unsigned long long)((mem_diag >> 17) & 1u),
               (unsigned long long)((mem_diag >> 18) & 1u),
               (unsigned long long)((mem_diag >> 19) & 1u),
               (unsigned long long)((mem_diag >> 20) & 1u),
               (unsigned long long)((mem_diag >> 21) & 1u),
               (unsigned long long)((mem_diag >> 32) & 1u),
               (unsigned long long)((mem_diag >> 33) & 1u),
               (unsigned long long)((mem_diag >> 34) & 1u),
               (unsigned long long)((mem_diag >> 35) & 1u),
               (unsigned long long)((mem_diag >> 36) & 1u),
               (unsigned long long)((mem_diag >> 37) & 1u),
               (unsigned long long)((mem_diag >> 38) & 1u),
               (unsigned long long)((mem_diag >> 39) & 1u),
               (unsigned long long)((mem_diag >> 40) & 1u),
               (unsigned long long)((mem_diag >> 41) & 1u),
               (unsigned long long)((mem_diag >> 44) & 1u),
               (unsigned long long)((mem_diag >> 45) & 1u),
               (unsigned long long)((mem_diag >> 46) & 1u),
               (unsigned long long)((mem_diag >> 47) & 1u),
               (unsigned long long)((mem_diag >> 48) & 1u),
               (unsigned long long)((mem_diag >> 49) & 1u),
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
  uint64_t mem_diag = g_top ? (uint64_t)g_top->debug_mem_diag_o : 0;
  uint64_t fetch_pte_addr = g_top ? (uint64_t)g_top->debug_fetch_pte_addr_o : 0;
  uint64_t fetch_pte = g_top ? (uint64_t)g_top->debug_fetch_pte_o : 0;
  uint64_t fetch_pte_meta = g_top ? (uint64_t)g_top->debug_fetch_pte_meta_o : 0;
  LogBothTag("cpu_exec",
             "ooo flags=0x%016llx valid=%llu stop=%llu owner=%llu orphan=%llu "
             "csr_head=%llu spec=%llu/%llu synth=%llu/%llu exit=%llu branch=%llu "
             "jump=%llu mem=%llu arch_trap=%llu system=%llu irq=%llu csr=%llu "
             "csr_dispatched=%llu irq_pending=%llu drained_q=%llu drained=%llu "
             "dispatch_ready=%llu csr_dispatch_valid=%llu csr_dispatch_fire=%llu "
             "csr_commit=%llu can_run=%llu fifo=%llu trap_cause=%llu head_resp=%llu "
             "head_fetch_fault=%llu dispatch_arch_trap=%llu csr_illegal=%llu dispatch_system=%llu "
             "priv=%llu satp_sv39=%llu arch_trap_fire=%llu csr_trap_ex=%llu drain_complete=%llu "
             "replay_wait=%llu direct_flush=%llu",
             (unsigned long long)flags,
             (unsigned long long)((flags >> 63) & 1u),
             (unsigned long long)((flags >> 0) & 1u),
             (unsigned long long)((flags >> 1) & 1u),
             (unsigned long long)((flags >> 2) & 1u),
             (unsigned long long)((flags >> 45) & 1u),
             (unsigned long long)((flags >> 44) & 1u),
             (unsigned long long)((flags >> 43) & 1u),
             (unsigned long long)((flags >> 42) & 1u),
             (unsigned long long)((flags >> 41) & 1u),
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
  LogBothTag("cpu_exec",
             "memdiag=0x%016llx bridge=%llu/%llu stg=%llu/%llu "
             "q0=%llu:%llu%llu%llu:%llu q1=%llu:%llu%llu%llu:%llu "
             "exact=%llu/%llu head=%llu/%llu station=%llu/%llu selected=%llu/%llu "
             "tracker=%llu/%llu pre_lq=%llu/%llu lq_open=%llu/%llu "
             "retry=%llu/%llu retry_sel=%llu/%llu store=%llu/%llu older=%llu/%llu "
             "grant_retry=%llu/%llu grant_issue=%llu%llu/%llu%llu "
             "sq=%llu/%llu res=%llu/%llu plain_store=%llu/%llu "
             "miq_head_load=%llu/%llu miq_nonempty=%llu/%llu lq_full=%llu "
             "sq_nonempty=%llu same_pid=%llu barrier=%llu active_exact=%llu/%llu",
             (unsigned long long)mem_diag,
             (unsigned long long)((mem_diag >> 0) & 0xfu),
             (unsigned long long)((mem_diag >> 4) & 0xfu),
             (unsigned long long)((mem_diag >> 8) & 1u),
             (unsigned long long)((mem_diag >> 9) & 1u),
             (unsigned long long)((mem_diag >> 10) & 1u),
             (unsigned long long)((mem_diag >> 11) & 1u),
             (unsigned long long)((mem_diag >> 12) & 1u),
             (unsigned long long)((mem_diag >> 13) & 1u),
             (unsigned long long)((mem_diag >> 14) & 1u),
             (unsigned long long)((mem_diag >> 15) & 1u),
             (unsigned long long)((mem_diag >> 16) & 1u),
             (unsigned long long)((mem_diag >> 17) & 1u),
             (unsigned long long)((mem_diag >> 18) & 1u),
             (unsigned long long)((mem_diag >> 19) & 1u),
             (unsigned long long)((mem_diag >> 20) & 1u),
             (unsigned long long)((mem_diag >> 21) & 1u),
             (unsigned long long)((mem_diag >> 22) & 1u),
             (unsigned long long)((mem_diag >> 23) & 1u),
             (unsigned long long)((mem_diag >> 24) & 1u),
             (unsigned long long)((mem_diag >> 25) & 1u),
             (unsigned long long)((mem_diag >> 26) & 1u),
             (unsigned long long)((mem_diag >> 27) & 1u),
             (unsigned long long)((mem_diag >> 28) & 1u),
             (unsigned long long)((mem_diag >> 29) & 1u),
             (unsigned long long)((mem_diag >> 30) & 1u),
             (unsigned long long)((mem_diag >> 31) & 1u),
             (unsigned long long)((mem_diag >> 32) & 1u),
             (unsigned long long)((mem_diag >> 33) & 1u),
             (unsigned long long)((mem_diag >> 34) & 1u),
             (unsigned long long)((mem_diag >> 35) & 1u),
             (unsigned long long)((mem_diag >> 36) & 1u),
             (unsigned long long)((mem_diag >> 37) & 1u),
             (unsigned long long)((mem_diag >> 38) & 1u),
             (unsigned long long)((mem_diag >> 39) & 1u),
             (unsigned long long)((mem_diag >> 40) & 1u),
             (unsigned long long)((mem_diag >> 41) & 1u),
             (unsigned long long)((mem_diag >> 42) & 1u),
             (unsigned long long)((mem_diag >> 43) & 1u),
             (unsigned long long)((mem_diag >> 44) & 1u),
             (unsigned long long)((mem_diag >> 45) & 1u),
             (unsigned long long)((mem_diag >> 46) & 1u),
             (unsigned long long)((mem_diag >> 47) & 1u),
             (unsigned long long)((mem_diag >> 48) & 1u),
             (unsigned long long)((mem_diag >> 49) & 1u),
             (unsigned long long)((mem_diag >> 50) & 1u),
             (unsigned long long)((mem_diag >> 51) & 1u),
             (unsigned long long)((mem_diag >> 52) & 1u),
             (unsigned long long)((mem_diag >> 53) & 1u),
             (unsigned long long)((mem_diag >> 54) & 1u),
             (unsigned long long)((mem_diag >> 55) & 1u),
             (unsigned long long)((mem_diag >> 56) & 1u),
             (unsigned long long)((mem_diag >> 57) & 1u),
             (unsigned long long)((mem_diag >> 58) & 1u),
             (unsigned long long)((mem_diag >> 59) & 1u),
             (unsigned long long)((mem_diag >> 60) & 1u),
             (unsigned long long)((mem_diag >> 61) & 1u),
             (unsigned long long)((mem_diag >> 62) & 1u),
             (unsigned long long)((mem_diag >> 63) & 1u));
}

static void report_run_result(void) {
  NpcState *st = npc_state();
  switch (st->state) {
    case NPC_END: {
      const bool guest_watch_exit =
          (st->halt_ret == 0) && !st->exit_is_ebreak && !st->exit_is_ecall &&
          !st->exit_is_system_reset &&
          !st->exit_is_tohost &&
          npc_guest_expect_matched();
      const bool commit_watch_exit =
          (st->halt_ret == 0) && !st->exit_is_ebreak && !st->exit_is_ecall &&
          !st->exit_is_system_reset &&
          !st->exit_is_tohost &&
          g_commit_watch_matched;
      const bool tohost_exit = st->exit_is_tohost;
      const char *trap_text = tohost_exit
          ? ((st->halt_ret == 0)
             ? (ANSI_FG_GREEN "TOHOST PASS" ANSI_NONE)
             : (ANSI_FG_RED "TOHOST FAIL" ANSI_NONE))
          : guest_watch_exit
          ? (ANSI_FG_GREEN "GUEST EXPECT MATCH" ANSI_NONE)
          : commit_watch_exit
          ? (ANSI_FG_GREEN "COMMIT WATCH MATCH" ANSI_NONE)
          : (st->halt_ret == 0)
          ? (ANSI_FG_GREEN "HIT GOOD TRAP" ANSI_NONE)
          : (ANSI_FG_RED   "HIT BAD TRAP"  ANSI_NONE);
      LogBothTag("cpu_exec", "npc: %s at pc = 0x%016" NPC_PRIxWORD, trap_text, st->halt_pc);
      const char *exit_via = tohost_exit ? "tohost" :
          (guest_watch_exit ? "guest-watch" :
          (commit_watch_exit ? "commit-watch" :
          (st->exit_is_system_reset ? "system-reset" :
          (st->exit_is_ebreak ? "ebreak" :
          (st->exit_is_ecall ? "ecall" : "unknown")))));
      if (tohost_exit) {
        LogBoth("exit via %s, value=0x%016" NPC_PRIxWORD ", code=%" PRIu64
                ", cycles=%llu, commits=%llu",
                exit_via, st->tohost_value, (uint64_t)st->halt_ret,
                (unsigned long long)npc_stats()->cycles,
                (unsigned long long)npc_stats()->commits);
      } else {
        LogBoth("exit via %s, code=%" PRIu64 ", cycles=%llu, commits=%llu",
                exit_via, (uint64_t)st->halt_ret,
                (unsigned long long)npc_stats()->cycles,
                (unsigned long long)npc_stats()->commits);
      }
      if (commit_watch_exit) {
        report_ooo_debug_flags();
        report_recent_debug_cycles();
        report_recent_commits();
      }
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
#ifdef CONFIG_NPC_OOO_STATS
  sample_tensor_snapshot_post_posedge();
#endif
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
  st->exit_is_system_reset =
      g_exit_event.valid && g_exit_event.is_system_reset;
  st->exit_is_tohost = false;
  st->tohost_value = 0;
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
  if (report_summary) {
    report_region_probe_final(ret);
    report_run_result();
  }
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
  // The standard VNpcSimTop host exposes the CPU boundary only; it does not
  // implement the direct-NPU command/terminal transport.  Initialize every
  // Tensor input before the first eval/reset edge so the disconnected boundary
  // is deterministic and inactive.
  g_top->tensor_cmd_ready_i = 0;
  g_top->tensor_terminal_valid_i = 0;
  g_top->tensor_terminal_producer_id_i = 0;
  g_top->tensor_terminal_error_i = 0;
  g_top->tensor_terminal_error_code_i = 0;
  if (!init_tohost_watch(config)) return false;

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
  st->exit_is_tohost = false;
  st->exit_is_system_reset = false;
  st->tohost_value = 0;

  uint64_t timer_start_us = npc_get_time_us();
  uint64_t executed = 0;
  ProgressReporter progress = make_progress_reporter(max_instructions);
  const uint64_t commit_gap_limit_cycles =
      env_u64_or("NPC_COMMIT_GAP_LIMIT_CYCLES", 0);
  uint64_t commit_gap_last_cycle = npc_stats()->cycles;
  uint64_t commit_gap_last_count = npc_stats()->commits;
  if (commit_gap_limit_cycles > 0) {
    LogBothTag("commit-gap",
               "enabled limit_cycles=%llu start_cycle=%llu start_commits=%llu",
               (unsigned long long)commit_gap_limit_cycles,
               (unsigned long long)commit_gap_last_cycle,
               (unsigned long long)commit_gap_last_count);
  }
  npc_reset_guest_expect();
  reset_user_trace_counters();
  g_commit_watch_matched = false;
  g_commit_watch_match_count = 0;
  g_commit_watch_post_active = false;
  g_commit_watch_post_deadline = 0;

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

    // Guest-visible terminal（含 reset-syscon）优先于人为 guest/commit watch，
    // 防止同拍观察器把自然关机伪装成测试提前结束。
    if (g_exit_event.valid) {
      report_exit();
      return finish_exec(timer_start_us, (int)st->halt_ret, true);
    }

    if (maybe_stop_on_tohost()) {
      return finish_exec(timer_start_us, (int)st->halt_ret, true);
    }
    if (npc_guest_expect_matched()) {
      st->state = NPC_END;
      st->halt_pc = g_top->debug_pc_o;
      st->halt_ret = 0;
      st->exit_is_ebreak = false;
      st->exit_is_ecall = false;
      st->exit_is_system_reset = false;
      st->exit_is_tohost = false;
      st->tohost_value = 0;
      LogBothTag("guest-watch", "matched NPC_GUEST_EXPECT='%s'",
                 npc_guest_expect_text());
      return finish_exec(timer_start_us, 0, true);
    }
    if (g_commit_watch_post_active &&
        npc_stats()->cycles >= g_commit_watch_post_deadline) {
      g_commit_watch_post_active = false;
      g_commit_watch_matched = true;
      LogBothTag("commitwatch",
                 "post window expired at cycle=%llu after %llu match(es)",
                 (unsigned long long)npc_stats()->cycles,
                 (unsigned long long)g_commit_watch_match_count);
    }
    if (g_commit_watch_matched) {
      st->state = NPC_END;
      st->halt_pc = g_top->debug_pc_o;
      st->halt_ret = 0;
      st->exit_is_ebreak = false;
      st->exit_is_ecall = false;
      st->exit_is_system_reset = false;
      st->exit_is_tohost = false;
      st->tohost_value = 0;
      LogBothTag("commitwatch", "stop after %llu matching committed PC(s)",
                 (unsigned long long)g_commit_watch_match_count);
      return finish_exec(timer_start_us, 0, true);
    }

    if (g_trap_event.valid) {
      report_trap();
      return finish_exec(timer_start_us, 1, true);
    }

    if (g_commit_event_count > 0) {
      commit_gap_last_cycle = npc_stats()->cycles;
      commit_gap_last_count = npc_stats()->commits;
    } else if (commit_gap_limit_cycles > 0 &&
               commit_gap_last_count > 0 &&
               npc_stats()->cycles - commit_gap_last_cycle >=
                   commit_gap_limit_cycles) {
      st->state = NPC_ABORT;
      st->halt_pc = g_top->debug_pc_o;
      LogBothTag("commit-gap",
                 "expired gap_cycles=%llu limit_cycles=%llu "
                 "last_commit_cycle=%llu last_commit_count=%llu "
                 "current_cycle=%llu current_pc=0x%016" NPC_PRIxWORD,
                 (unsigned long long)(npc_stats()->cycles -
                                      commit_gap_last_cycle),
                 (unsigned long long)commit_gap_limit_cycles,
                 (unsigned long long)commit_gap_last_cycle,
                 (unsigned long long)commit_gap_last_count,
                 (unsigned long long)npc_stats()->cycles,
                 (npc_word_t)g_top->debug_pc_o);
      return finish_exec(timer_start_us, 3, true);
    }

    if (g_commit_event_count > 0) {
      for (uint32_t commit_idx = 0; commit_idx < g_commit_event_count; ++commit_idx) {
        const CommitEvent &event = g_commit_events[commit_idx];
        if (!event.valid) continue;

        observe_region_boundary(event, commit_idx);
        ++executed;
        trace_commit(event);
#if CONFIG_NPC_DIFFTEST
        if (npc_difftest_enabled()) {
          npc_difftest_set_dut_csr(event.csr);   // 全状态: 注入本条提交后的 CSR+priv
          npc_difftest_set_dut_fpr(event.fpr);   // 阶段2: 注入本条提交后的 arch FPR
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
          if (maybe_stop_on_tohost()) { return finish_exec(timer_start_us, (int)st->halt_ret, true); }
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
