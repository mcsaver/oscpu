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
  uint32_t pc;
  uint32_t inst;
  uint32_t next_pc;
  bool     rd_en;
  uint32_t rd_addr;
  uint32_t rd_data;
};

struct ExitEvent {
  bool     valid;
  bool     is_ebreak;
  bool     is_ecall;
  uint32_t code;
  uint32_t pc;
};

struct TrapEvent {
  bool     valid;
  uint32_t cause;
  uint32_t pc;
  uint32_t tval;
};

static CommitEvent g_commit_event = {};
static ExitEvent   g_exit_event   = {};
static TrapEvent   g_trap_event   = {};
static uint32_t    g_shadow_gpr[32] = {};

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

static void on_sigint(int) { g_stop_requested = 1; }

static void clear_cycle_events(void) {
  g_commit_event.valid = false;
  g_exit_event.valid = false;
  g_trap_event.valid = false;
}

static void reset_event_state(void) {
  clear_cycle_events();
  memset(g_shadow_gpr, 0, sizeof(g_shadow_gpr));
  memset(&g_sim_perf, 0, sizeof(g_sim_perf));
  memset(&g_bpu_stats, 0, sizeof(g_bpu_stats));
  memset(g_branch_miss_pc_stats, 0, sizeof(g_branch_miss_pc_stats));
}

extern "C" void npc_commit_event(uint32_t pc, uint32_t inst, uint32_t next_pc,
                                 uint32_t rd_en, uint32_t rd_addr, uint32_t rd_data) {
  g_commit_event.valid = true;
  g_commit_event.pc = pc;
  g_commit_event.inst = inst;
  g_commit_event.next_pc = next_pc;
  g_commit_event.rd_en = rd_en != 0;
  g_commit_event.rd_addr = rd_addr;
  g_commit_event.rd_data = rd_data;

  if (g_commit_event.rd_en && rd_addr > 0 && rd_addr < 32) {
    g_shadow_gpr[rd_addr] = rd_data;
  }
  g_shadow_gpr[0] = 0;
}

extern "C" void npc_exit_event(uint32_t is_ebreak, uint32_t is_ecall,
                               uint32_t code, uint32_t pc) {
  g_exit_event.valid = true;
  g_exit_event.is_ebreak = is_ebreak != 0;
  g_exit_event.is_ecall = is_ecall != 0;
  g_exit_event.code = code;
  g_exit_event.pc = pc;
}

extern "C" void npc_trap_event(uint32_t cause, uint32_t pc, uint32_t tval) {
  g_trap_event.valid = true;
  g_trap_event.cause = cause;
  g_trap_event.pc = pc;
  g_trap_event.tval = tval;
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

static bool install_sigint_handler(void) {
  struct sigaction act = {};
  act.sa_handler = on_sigint;
  sigemptyset(&act.sa_mask);
  // 不打开 SA_RESTART，Ctrl-C 可以打断 monitor 阻塞的 stdin 读操作
  return sigaction(SIGINT, &act, nullptr) == 0;
}

static uint32_t debug_reg_value(int index) {
  return g_shadow_gpr[index];
}

static void clear_runtime_state(void) {
  NpcState *st = npc_state();
  memset(st, 0, sizeof(*st));
  st->state = NPC_STOP;
  st->watchpoint_id = -1;
}

/* ---- itrace 提交记录 ---- */

static void trace_commit(void) {
  if (!npc_itrace_enabled()) return;

  char asm_buf[128];
  int asm_len = npc_disassemble_inst(g_commit_event.pc, g_commit_event.inst,
                                     asm_buf, sizeof(asm_buf));
  const char *asm_text = (asm_len > 0) ? asm_buf : "<decode unavailable>";

  if (g_commit_event.rd_en) {
    // <= 表示"提交后新值写入寄存器"
    Log("itrace pc=0x%08x inst=0x%08x asm=\"%s\" x%u(%s)<=0x%08x",
        g_commit_event.pc, g_commit_event.inst, asm_text,
        g_commit_event.rd_addr, kRegNames[g_commit_event.rd_addr],
        g_commit_event.rd_data);
  } else {
    Log("itrace pc=0x%08x inst=0x%08x asm=\"%s\"",
        g_commit_event.pc, g_commit_event.inst, asm_text);
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

  npc_log_plain("[progress] %llu insts, pc=0x%08x, %llu inst/s\n",
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

// NEMU 风格统计 + CPI + 分支统计，NPC 跑分结果可直接和参考模型对比
static void report_statistics(void) {
  LogBothTag("statistic", "host time spent = %llu us",
          (unsigned long long)npc_stats()->host_time_us);
  LogBothTag("statistic", "total guest instructions = %llu",
          (unsigned long long)npc_stats()->commits);
  // 新增 cycles 和 CPI 输出，对齐参考工程的统计格式
  LogBothTag("statistic", "total guest cycles = %llu",
          (unsigned long long)npc_stats()->cycles);
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
}

static void report_run_result(void) {
  NpcState *st = npc_state();
  switch (st->state) {
    case NPC_END: {
      const char *trap_text = (st->halt_ret == 0)
          ? (ANSI_FG_GREEN "HIT GOOD TRAP" ANSI_NONE)
          : (ANSI_FG_RED   "HIT BAD TRAP"  ANSI_NONE);
      LogBothTag("cpu_exec", "npc: %s at pc = 0x%08x", trap_text, st->halt_pc);
      LogBoth("exit via %s, code=%u, cycles=%llu, commits=%llu",
              st->exit_is_ebreak ? "ebreak" : (st->exit_is_ecall ? "ecall" : "unknown"),
              st->halt_ret,
              (unsigned long long)npc_stats()->cycles,
              (unsigned long long)npc_stats()->commits);
      report_statistics();
      return;
    }
    case NPC_TRAP:
      LogBothTag("cpu_exec", "npc: %s at pc = 0x%08x", ANSI_FG_RED "TRAP" ANSI_NONE, st->halt_pc);
      LogBoth("trap cause=%u tval=0x%08x, cycles=%llu, commits=%llu",
              st->trap_cause, st->trap_tval,
              (unsigned long long)npc_stats()->cycles,
              (unsigned long long)npc_stats()->commits);
      report_statistics();
      return;
    case NPC_ABORT:
      LogBothTag("cpu_exec", "npc: %s at pc = 0x%08x", ANSI_FG_RED "ABORT" ANSI_NONE, st->halt_pc);
      LogBoth("cycles=%llu, commits=%llu, core-state=0x%08x",
              (unsigned long long)npc_stats()->cycles,
              (unsigned long long)npc_stats()->commits,
              npc_cpu_state_bits());
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
  if (g_commit_event.valid) ++npc_stats()->commits;
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
  npc_log_plain("\n[npc] execution interrupted at pc=0x%08x after %llu cycles\n",
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

    if (g_commit_event.valid) {
      ++executed;
      trace_commit();
#if CONFIG_NPC_DIFFTEST
      if (npc_difftest_enabled()) {
        if (!npc_difftest_step(g_commit_event.pc, g_commit_event.inst,
                               g_commit_event.next_pc, g_shadow_gpr,
                               g_commit_event.rd_en, g_commit_event.rd_addr,
                               g_commit_event.rd_data)) {
          st->state = NPC_ABORT;
          st->halt_pc = g_commit_event.pc;
          return finish_exec(timer_start_us, 1, true);
        }
      }
#endif
      if (npc_check_watchpoints())
        return finish_exec(timer_start_us, 0, false);
      maybe_report_progress(&progress);

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
    printf("x%-2d %-4s 0x%08x%s", i, kRegNames[i], debug_reg_value(i),
           ((i + 1) % 4 == 0) ? "\n" : "    ");
  }
  if (32 % 4 != 0) printf("\n");
  printf("pc      0x%08x\n", g_top->debug_pc_o);
}

void npc_cpu_info_display(void) {
  NpcState *st = npc_state();
  printf("state    : %s\n", npc_state_name(st->state));
  printf("pc       : 0x%08x\n", npc_cpu_pc());
  printf("core     : 0x%08x\n", npc_cpu_state_bits());
  printf("cycles   : %llu\n", (unsigned long long)npc_stats()->cycles);
  printf("commits  : %llu\n", (unsigned long long)npc_stats()->commits);
  printf("host-us  : %llu\n", (unsigned long long)npc_stats()->host_time_us);
  if (npc_stats()->host_time_us > 0)
    printf("inst/s   : %llu\n", (unsigned long long)simulation_frequency());
}

bool npc_isa_reg_str2val(const char *name, uint32_t *value) {
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

bool npc_cpu_read_reg(int index, uint32_t *value) {
  if (!g_top || !value || index < 0 || index >= 32) return false;
  *value = debug_reg_value(index);
  return true;
}

uint32_t npc_cpu_pc(void) {
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
