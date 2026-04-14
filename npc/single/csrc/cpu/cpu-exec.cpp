#include "cpu/cpu.h"

#include "device/device.h"
#include "monitor/expr.h"
#include "monitor/log.h"
#include "monitor/trace.h"
#include "monitor/watchpoint.h"

#include <verilated.h>
#include <verilated_vcd_c.h>

#include <array>
#include <csignal>
#include <cstdio>
#include <cctype>
#include <cstring>
#include <limits>
#include <memory>
#include <string>

#include "VNpcSimTop.h"

namespace npc {

namespace {

std::unique_ptr<VNpcSimTop> g_top;
std::unique_ptr<VerilatedVcdC> g_trace_file;
uint64_t g_cycle_limit = kDefaultMaxCycles;
uint64_t g_progress_interval = kDefaultProgressInterval;
volatile std::sig_atomic_t g_stop_requested = 0;

constexpr std::array<const char *, 32> kRegNames = {
  "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6",
};

struct ProgressReporter {
  bool enabled = false;
  uint64_t interval = 0;
  uint64_t next_commit = 0;
  uint64_t last_commit = 0;
  uint64_t last_report_time_us = 0;
};

uint64_t simulation_frequency() {
  if (npc_stats().host_time_us == 0) {
    return 0;
  }
  return (npc_stats().commits * 1000000ull) / npc_stats().host_time_us;
}

void on_sigint(int) {
  g_stop_requested = 1;
}

bool install_sigint_handler() {
  struct sigaction action = {};
  action.sa_handler = on_sigint;
  sigemptyset(&action.sa_mask);
  // 不打开 SA_RESTART，这样 monitor 在提示符上阻塞读 stdin 时，Ctrl-C 可以真正打断读操作并退出。
  return sigaction(SIGINT, &action, nullptr) == 0;
}

uint32_t debug_reg_value(int index) {
  return g_top->debug_gprs_o[index];
}

void clear_runtime_state() {
  reset_npc_state();
  npc_state().state = NPC_STOP;
}

void trace_commit() {
  if (!itrace_enabled()) {
    return;
  }

  if (g_top->commit_rd_en_o) {
    Log("itrace pc=0x%08x inst=0x%08x x%u(%s)=0x%08x",
        g_top->commit_pc_o,
        g_top->commit_inst_o,
        g_top->commit_rd_addr_o,
        kRegNames[g_top->commit_rd_addr_o],
        g_top->commit_rd_data_o);
  } else {
    Log("itrace pc=0x%08x inst=0x%08x", g_top->commit_pc_o, g_top->commit_inst_o);
  }
}

// 长时间 batch/c 路径默认会静默运行，定期吐一行提交进度能直接区分“还在跑”和“真的卡死了”。
ProgressReporter make_progress_reporter(uint64_t max_instructions) {
  ProgressReporter reporter;
  if (!progress_enabled(g_progress_interval) || max_instructions != std::numeric_limits<uint64_t>::max()) {
    return reporter;
  }

  reporter.enabled = true;
  reporter.interval = g_progress_interval;
  reporter.next_commit = ((npc_stats().commits / reporter.interval) + 1) * reporter.interval;
  reporter.last_commit = npc_stats().commits;
  reporter.last_report_time_us = get_time_us();
  return reporter;
}

void maybe_report_progress(ProgressReporter *reporter) {
  if (reporter == nullptr || !reporter->enabled || npc_stats().commits < reporter->next_commit) {
    return;
  }

  const uint64_t now_us = get_time_us();
  const uint64_t commits = npc_stats().commits;
  const uint64_t delta_commits = commits - reporter->last_commit;
  const uint64_t delta_us = now_us - reporter->last_report_time_us;
  const uint64_t inst_per_sec = (delta_us == 0) ? 0 : (delta_commits * 1000000ull) / delta_us;

  std::printf("[progress] %llu insts, pc=0x%08x, %llu inst/s\n",
              static_cast<unsigned long long>(commits),
              g_top->debug_pc_o,
              static_cast<unsigned long long>(inst_per_sec));
  std::fflush(stdout);

  reporter->last_commit = commits;
  reporter->last_report_time_us = now_us;
  while (reporter->next_commit <= commits) {
    reporter->next_commit += reporter->interval;
  }
}

void accumulate_host_time(uint64_t start_time_us) {
  npc_stats().host_time_us += get_time_us() - start_time_us;
}

// 结束时补一组 NEMU 风格统计，方便直接把 NPC 跑分结果和参考模型放在一起对比。
void report_statistics() {
  Log("host time spent = %llu us", static_cast<unsigned long long>(npc_stats().host_time_us));
  Log("total guest instructions = %llu", static_cast<unsigned long long>(npc_stats().commits));
  if (npc_stats().host_time_us > 0) {
    Log("simulation frequency = %llu inst/s", static_cast<unsigned long long>(simulation_frequency()));
  } else {
    Log("Finish running in less than 1 us and can not calculate the simulation frequency");
  }
}

void report_run_result() {
  const auto &state = npc_state();
  switch (state.state) {
    case NPC_END: {
      const char *trap_text = (state.halt_ret == 0) ? (ANSI_FG_GREEN "HIT GOOD TRAP" ANSI_NONE)
                                                    : (ANSI_FG_RED "HIT BAD TRAP" ANSI_NONE);
      Log("npc: %s at pc = 0x%08x", trap_text, state.halt_pc);
      Log("exit via %s, code=%u, cycles=%llu, commits=%llu",
          state.exit_is_ebreak ? "ebreak" : (state.exit_is_ecall ? "ecall" : "unknown"),
          state.halt_ret,
          static_cast<unsigned long long>(npc_stats().cycles),
          static_cast<unsigned long long>(npc_stats().commits));
      report_statistics();
      return;
    }
    case NPC_TRAP:
      Log("npc: %s at pc = 0x%08x", ANSI_FG_RED "TRAP" ANSI_NONE, state.halt_pc);
      Log("trap cause=%u tval=0x%08x, cycles=%llu, commits=%llu",
          state.trap_cause,
          state.trap_tval,
          static_cast<unsigned long long>(npc_stats().cycles),
          static_cast<unsigned long long>(npc_stats().commits));
      report_statistics();
      return;
    case NPC_ABORT:
      Log("npc: %s at pc = 0x%08x", ANSI_FG_RED "ABORT" ANSI_NONE, state.halt_pc);
      Log("cycles=%llu, commits=%llu, core-state=0x%08x",
          static_cast<unsigned long long>(npc_stats().cycles),
          static_cast<unsigned long long>(npc_stats().commits),
          cpu_state_bits());
      report_statistics();
      return;
    case NPC_QUIT:
      Log("npc: quit");
      report_statistics();
      return;
    default:
      return;
  }
}

void eval_half_cycle(uint8_t clk_level) {
  g_top->clk = clk_level;
  g_top->eval();
  if (g_trace_file) {
    g_trace_file->dump(npc_stats().sim_time);
  }
  ++npc_stats().sim_time;
}

void step_cycle() {
  device_update();
  eval_half_cycle(0);
  eval_half_cycle(1);

  ++npc_stats().cycles;
  if (g_top->commit_valid_o) {
    ++npc_stats().commits;
  }
}

void apply_reset() {
  g_top->rst = 1;
  g_top->clk = 0;
  for (int warmup = 0; warmup < 5; ++warmup) {
    step_cycle();
  }
  g_top->rst = 0;
  npc_stats() = NpcStats();
  clear_runtime_state();
}

void report_exit() {
  auto &state = npc_state();
  state.state = NPC_END;
  state.halt_pc = g_top->debug_pc_o;
  state.halt_ret = g_top->exit_code_o;
  state.exit_is_ebreak = g_top->exit_is_ebreak_o;
  state.exit_is_ecall = g_top->exit_is_ecall_o;
}

void report_trap() {
  auto &state = npc_state();
  state.state = NPC_TRAP;
  state.halt_pc = g_top->trap_pc_o;
  state.trap_cause = g_top->trap_cause_o;
  state.trap_tval = g_top->trap_tval_o;
}

void report_timeout() {
  auto &state = npc_state();
  state.state = NPC_ABORT;
  state.halt_pc = g_top->debug_pc_o;
}

void report_interrupt() {
  npc_state().state = NPC_STOP;
  std::printf("\n[npc] execution interrupted at pc=0x%08x after %llu cycles\n",
              g_top->debug_pc_o,
              static_cast<unsigned long long>(npc_stats().cycles));
}

int reg_index_from_name(const char *name) {
  if (name == nullptr) {
    return -1;
  }

  if (std::strcmp(name, "pc") == 0) {
    return 32;
  }

  if (name[0] == 'x') {
    char *end = nullptr;
    const long value = std::strtol(name + 1, &end, 10);
    if (end != nullptr && *end == '\0' && value >= 0 && value < 32) {
      return static_cast<int>(value);
    }
  }

  for (int index = 0; index < 32; ++index) {
    if (std::strcmp(name, kRegNames[index]) == 0) {
      return index;
    }
  }

  return -1;
}

}  // namespace

bool init_cpu(int argc, char **argv, const SimConfig &config) {
  Verilated::commandArgs(argc, argv);
  g_cycle_limit = config.max_cycles;
  g_progress_interval = config.progress_interval;
  if (!install_sigint_handler()) {
    std::perror("[npc] sigaction(SIGINT)");
    return false;
  }

  g_top = std::make_unique<VNpcSimTop>();
  if (!g_top) {
    return false;
  }

  if (config.trace) {
    Verilated::traceEverOn(true);
    g_trace_file = std::make_unique<VerilatedVcdC>();
    g_top->trace(g_trace_file.get(), 99);
    g_trace_file->open(config.trace_path.c_str());
  }

  // 这里把复位放到初始化阶段做掉，后续 monitor 的 si/c 命令才能在同一颗已上电的核上连续推进。
  apply_reset();

  return true;
}

int cpu_exec(uint64_t max_instructions) {
  if (!g_top) {
    return 1;
  }

  if (npc_state().state == NPC_END || npc_state().state == NPC_TRAP || npc_state().state == NPC_ABORT) {
    std::printf("[npc] core already stopped in state=%s, reset the simulator to restart.\n",
                npc_state_name(npc_state().state));
    return (npc_state().state == NPC_END) ? static_cast<int>(npc_state().halt_ret) : 1;
  }

  if (max_instructions == 0) {
    npc_state().state = NPC_STOP;
    return 0;
  }

  g_stop_requested = 0;
  npc_state().state = NPC_RUNNING;
  npc_state().watchpoint_id = -1;
  npc_state().watchpoint_expr.clear();

  const uint64_t timer_start_us = get_time_us();
  auto finish_exec = [&](int ret, bool report_summary) -> int {
    accumulate_host_time(timer_start_us);
    if (report_summary) {
      report_run_result();
    }
    return ret;
  };

  uint64_t executed = 0;
  ProgressReporter progress = make_progress_reporter(max_instructions);

  // 运行循环只关心“推进一个周期、记录提交、接住退出/异常”，其余平台细节都被压到 memory/device 层里。
  while (!Verilated::gotFinish()) {
    if (consume_sigint_request()) {
      report_interrupt();
      return finish_exec(0, false);
    }

    if (cycle_limit_enabled(g_cycle_limit) && npc_stats().cycles >= g_cycle_limit) {
      report_timeout();
      return finish_exec(2, true);
    }

    step_cycle();

    if (g_top->exit_valid_o) {
      report_exit();
      return finish_exec(static_cast<int>(g_top->exit_code_o), true);
    }

    if (g_top->trap_valid_o) {
      report_trap();
      return finish_exec(1, true);
    }

    if (g_top->commit_valid_o) {
      ++executed;
      trace_commit();
      if (check_watchpoints()) {
        return finish_exec(0, false);
      }
      maybe_report_progress(&progress);
      if (executed >= max_instructions) {
        // 单步/定步命中提交点后，再额外冲一个“不产生新提交”的周期，
        // 这样 monitor 里看到的 PC 会前推到下一条待执行指令，更接近 NEMU 的 si 观感。
        if (!Verilated::gotFinish() &&
            (!cycle_limit_enabled(g_cycle_limit) || npc_stats().cycles < g_cycle_limit)) {
          step_cycle();

          if (g_top->exit_valid_o) {
            report_exit();
            return finish_exec(static_cast<int>(g_top->exit_code_o), true);
          }

          if (g_top->trap_valid_o) {
            report_trap();
            return finish_exec(1, true);
          }
        }

        npc_state().state = NPC_STOP;
        return finish_exec(0, false);
      }
    }

    if (npc_state().state == NPC_QUIT) {
      return finish_exec(0, true);
    }
  }

  if (Verilated::gotFinish()) {
    npc_state().state = NPC_QUIT;
    return finish_exec(0, true);
  }

  report_timeout();
  return finish_exec(2, true);
}

void cpu_reg_display() {
  if (!g_top) {
    std::printf("NPC core is not initialized.\n");
    return;
  }

  for (int index = 0; index < 32; ++index) {
    std::printf("x%-2d %-4s 0x%08x%s",
                index,
                kRegNames[index],
                debug_reg_value(index),
                ((index + 1) % 4 == 0) ? "\n" : "    ");
  }
  if ((32 % 4) != 0) {
    std::printf("\n");
  }
  std::printf("pc      0x%08x\n", g_top->debug_pc_o);
}

void cpu_info_display() {
  std::printf("state    : %s\n", npc_state_name(npc_state().state));
  std::printf("pc       : 0x%08x\n", cpu_pc());
  std::printf("core     : 0x%08x\n", cpu_state_bits());
  std::printf("cycles   : %llu\n", static_cast<unsigned long long>(npc_stats().cycles));
  std::printf("commits  : %llu\n", static_cast<unsigned long long>(npc_stats().commits));
  std::printf("host-us  : %llu\n", static_cast<unsigned long long>(npc_stats().host_time_us));
  if (npc_stats().host_time_us > 0) {
    std::printf("inst/s   : %llu\n", static_cast<unsigned long long>(simulation_frequency()));
  }
}

bool isa_reg_str2val(const char *name, uint32_t *value) {
  if (value == nullptr) {
    return false;
  }

  std::string lowered = name == nullptr ? "" : std::string(name);
  for (char &ch : lowered) {
    ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
  }

  const int reg_index = reg_index_from_name(lowered.c_str());
  if (reg_index < 0) {
    return false;
  }

  if (reg_index == 32) {
    *value = cpu_pc();
    return true;
  }

  return cpu_read_reg(reg_index, value);
}

bool cpu_read_reg(int index, uint32_t *value) {
  if (!g_top || value == nullptr || index < 0 || index >= 32) {
    return false;
  }
  *value = debug_reg_value(index);
  return true;
}

uint32_t cpu_pc() {
  return g_top ? g_top->debug_pc_o : kResetPc;
}

uint32_t cpu_state_bits() {
  return g_top ? g_top->debug_state_o : 0;
}

bool consume_sigint_request() {
  if (g_stop_requested == 0) {
    return false;
  }
  g_stop_requested = 0;
  return true;
}

void fini_cpu() {
  if (g_top) {
    g_top->final();
  }

  if (g_trace_file) {
    g_trace_file->close();
    g_trace_file.reset();
  }

  g_top.reset();
}

}  // namespace npc