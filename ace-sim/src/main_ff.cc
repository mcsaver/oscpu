// ace-sim V5 demo:functional backend 与 timing engine 分层 —— fast-forward + detailed 切换。
// 功能后端(= difftest 金标准同一份代码)快进无趣前缀(长循环),把架构状态(寄存器+内存+PC)
// 种子进详细(周期级)核,只对 ROI 做 cycle-accurate。三方对拍 + 加速度量。
#include <cstdint>
#include <cstdio>
#include <vector>

#include "core/top/CpuTop.hh"
#include "isa/functional.hh"
#include "isa/inst.hh"
#include "isa/ref_model.hh"
#include "mem/simple_mem.hh"
#include "sim/context.hh"

using namespace ace;

static int g_fail = 0;
static void check(const char* what, bool ok) {
  std::printf("  [%s] %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) ++g_fail;
}

int main() {
  // ---- 程序:无趣前缀(长循环求和)+ ROI(用循环结果的乱序友好代码)----
  // PC:0 初始化;1..3 循环体+回边;4 前缀尾把和 stash 进内存;5.. = ROI 入口;10 halt。
  const int N = 200;                 // 循环 200 次 -> 前缀约 600 条动态指令
  const size_t ROI_ENTRY = 5;
  const uint64_t A1 = 0x3000, A2 = 0x3008;
  Program prog;
  prog.push_back(alu(10, 0, 0, 0));                        // 0: r10 = 0(累加器)
  prog.push_back(alu(10, 10, 1, 0));                       // 1: r10 += r1   (循环体入口)
  prog.push_back(alu(1, 1, 0, static_cast<uint64_t>(-1)));// 2: r1 -= 1
  prog.push_back(bne(1, 0, 1));                            // 3: if r1 != 0 goto 1
  prog.push_back(store(22, 10, 0));                        // 4: M[r22] = r10  (前缀尾:stash 和到内存)
  prog.push_back(load(11, 22, 0));                         // 5: r11 = M[r22]  (ROI:从内存读回 -> 压内存种子)
  prog.push_back(alu(12, 11, 0, 5));                       // 6: r12 = r11 + 5
  prog.push_back(mul(13, 12, 12));                         // 7: r13 = r12 * r12
  prog.push_back(store(23, 13, 0));                        // 8: M[r23] = r13
  prog.push_back(load(14, 23, 0));                         // 9: r14 = M[r23]
  prog.push_back(halt());                                  // 10

  std::vector<uint64_t> init(32, 0);
  init[1] = N;
  init[22] = A1;
  init[23] = A2;

  // ---- ① 全功能金标准 ----
  RefResult gold = ref_run_full(prog, init);

  // ---- ② 全详细(周期级跑整程序,含长循环)----
  SimContext ctx_full;
  SimpleMemory mem_full;
  CompId mf = ctx_full.add(&mem_full);
  CpuTop cpu_full(prog, &mem_full, mf, {});               // start_pc=0
  ctx_full.add(&cpu_full);
  for (int r = 0; r < 32; ++r) cpu_full.set_arch_reg(r, init[r]);
  cpu_full.kickoff(ctx_full);
  ctx_full.run(5'000'000);

  // ---- ③ fast-forward(功能快进前缀到 ROI 入口)+ detailed(只 cycle-model ROI)----
  FunctionalBackend fb(prog, init);
  uint64_t ffwd = fb.run_until_pc(ROI_ENTRY, 10'000'000);  // 功能快进,"0 周期"

  SimContext ctx_hy;
  SimpleMemory mem_hy;
  CompId mh = ctx_hy.add(&mem_hy);
  OooConfig cfg;
  cfg.start_pc = fb.state().pc;                            // 从 ROI 入口续取指
  CpuTop cpu_hy(prog, &mem_hy, mh, cfg);
  ctx_hy.add(&cpu_hy);
  for (int r = 0; r < 32; ++r) cpu_hy.set_arch_reg(r, fb.state().regs[r]);  // 种子寄存器
  for (const auto& kv : fb.state().mem) mem_hy.write(kv.first, kv.second);  // 种子内存
  cpu_hy.kickoff(ctx_hy);
  ctx_hy.run(1'000'000);

  // ---- 报告 ----
  std::printf("=== ACE-Sim V5 (fast-forward + detailed) ===\n");
  std::printf("  fast-forwarded (functional, 0 cycles): %llu insts -> PC %zu\n",
              (unsigned long long)ffwd, fb.state().pc);
  std::printf("  full-detailed  : %llu cycles advanced, %llu insts retired\n",
              (unsigned long long)ctx_full.stats.cycles_advanced,
              (unsigned long long)cpu_full.retired());
  std::printf("  hybrid detailed: %llu cycles advanced, %llu insts retired (ROI only)\n",
              (unsigned long long)ctx_hy.stats.cycles_advanced,
              (unsigned long long)cpu_hy.retired());

  // 三方寄存器/内存一致
  bool full_ok = true, hy_ok = true, mem_ok = true;
  for (int r = 0; r < 32; ++r) {
    if (cpu_full.arch_reg(r) != gold.regs[r]) full_ok = false;
    if (cpu_hy.arch_reg(r)   != gold.regs[r]) hy_ok = false;
  }
  for (const auto& kv : gold.mem) {
    if (mem_full.peek(kv.first) != kv.second) mem_ok = false;
    if (mem_hy.peek(kv.first)   != kv.second) mem_ok = false;
  }

  std::printf("\n=== V5 goals ===\n");
  check("full-detailed matches functional golden (regs)", full_ok && cpu_full.halted());
  check("fast-forward+detailed matches functional golden (regs)", hy_ok && cpu_hy.halted());
  check("memory matches golden (both paths)", mem_ok);
  check("fast-forward skipped the boring prefix (>=500 insts functional)", ffwd >= 500);
  check("hybrid only cycle-models the ROI (retired << full)",
        cpu_hy.retired() <= 8 && cpu_hy.retired() < cpu_full.retired());
  check("layering pays off: ROI detailed cycles << full-detailed cycles",
        ctx_hy.stats.cycles_advanced < ctx_full.stats.cycles_advanced);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
