// ace-sim V1 demo:顺序核 + 多周期 FU + cache 延迟模型。
// 用"参考模型对拍"验证功能正确性,并逐条自检 DESIGN.md §7 的 7 个内核目标。
#include <cstdint>
#include <cstdio>
#include <vector>

#include "isa/inst.hh"
#include "isa/ref_model.hh"
#include "cpu/simple_cpu.hh"
#include "mem/simple_mem.hh"
#include "sim/context.hh"

using namespace ace;

static int g_fail = 0;
static void check(const char* what, bool ok) {
  std::printf("  [%s] %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) ++g_fail;
}

// 端到端回归:钉死审查修复的两个缺陷,防止回潮。
static void regressions() {
  std::printf("\n=== regressions (review fixes) ===\n");

  // 缺陷 #2/5/9:II > latency 的结构冒险必须由 CpuWake 兜底,不得睡死/提前静止。
  {
    SimContext ctx;
    SimpleMemory mem;
    CompId mem_id = ctx.add(&mem);
    CpuConfig cfg;
    cfg.alu = FuDesc{/*lat*/2, /*ii*/10, /*width*/1};  // II 远大于 latency
    Program prog;
    prog.push_back(alu(1, 0, 0, 5));   // 占用 ALU:next_accept = +10,completion = +2
    prog.push_back(alu(2, 0, 0, 7));   // 独立,同一 ALU:结构冒险停顿(无 completion 兜底)
    prog.push_back(halt());
    CycleSimpleCpu cpu(prog, &mem, mem_id, cfg);
    ctx.add(&cpu);
    cpu.kickoff(ctx);
    ctx.run(/*max_cycle=*/10'000);  // 有界:即便回潮也不会挂死进程
    check("regress[II>lat]: halts, no lost-wakeup (all issued & retired)",
          cpu.halted() && cpu.issued() == 3 && cpu.retired() == 2 &&
          cpu.reg(1) == 5 && cpu.reg(2) == 7);
  }

  // 缺陷 #4:HALT 之后的指令绝不取指/发射(不得发出真实内存请求)。
  {
    SimContext ctx;
    SimpleMemory mem;
    CompId mem_id = ctx.add(&mem);
    Program prog;
    prog.push_back(alu(1, 0, 0, 9));
    prog.push_back(halt());
    prog.push_back(load(30, 2, 0));    // HALT 之后:若被执行会发 DRAM(miss)请求
    prog.push_back(alu(31, 0, 0, 1));
    CycleSimpleCpu cpu(prog, &mem, mem_id, {});
    ctx.add(&cpu);
    cpu.set_reg(2, 0x80000000);
    cpu.kickoff(ctx);
    ctx.run(/*max_cycle=*/10'000);
    check("regress[post-HALT]: insts after HALT never execute (no mem req, regs untouched)",
          cpu.halted() && cpu.issued() == 2 && cpu.retired() == 1 &&
          mem.misses() == 0 && cpu.reg(30) == 0 && cpu.reg(31) == 0);
  }
}

int main() {
  // ---- 构造合成程序 ----
  const uint64_t kCached = 0x1000;       // 命中区
  const uint64_t kDram   = 0x80000000;   // 未命中区(触发 200 周期 DRAM 延迟)

  Program prog;
  prog.push_back(load(3, 1, 0));      // r3 = M[r1+0]   (hit)
  prog.push_back(load(4, 1, 8));      // r4 = M[r1+8]   (hit)
  prog.push_back(alu (5, 3, 4));      // r5 = r3 + r4
  prog.push_back(mul (6, 5, 5));      // r6 = r5 * r5   (3 cyc)
  prog.push_back(divi(7, 6, 1));      // r7 = r6 / r1   (20 cyc,长延迟)
  prog.push_back(alu (8, 7, -1, 1));  // r8 = r7 + 1    (依赖 r7 -> 队头停顿)
  for (int r = 9; r <= 17; ++r)       // 一批独立 ALU:堆积在 r8 之后,填满 fetch 队列
    prog.push_back(alu(r, 1, 1, static_cast<uint64_t>(r)));
  prog.push_back(load(20, 2, 0));     // r20 = M[r2]    (MISS,200 cyc)
  prog.push_back(alu (21, 20, -1, 7));// r21 = r20 + 7  (依赖 miss -> 大幅 time-skip)
  prog.push_back(halt());

  std::vector<uint64_t> init(32, 0);
  init[1] = kCached;
  init[2] = kDram;

  // ---- 搭建仿真 ----
  SimContext ctx;
  MemConfig mcfg;  // hit=3, dram=200, port cap=4
  SimpleMemory mem(mcfg);
  CompId mem_id = ctx.add(&mem);

  CpuConfig ccfg;  // fetch_q cap=8, fetch_width=2, issue_width=1, div 20cyc
  CycleSimpleCpu cpu(prog, &mem, mem_id, ccfg);
  ctx.add(&cpu);
  for (int r = 0; r < 32; ++r) cpu.set_reg(r, init[r]);
  cpu.kickoff(ctx);

  Cycle end = ctx.run(/*max_cycle=*/1'000'000);

  // ---- 报告 ----
  std::printf("\n=== ACE-Sim V1 run summary ===\n");
  std::printf("  simulated cycle (end)   : %llu\n", (unsigned long long)end);
  std::printf("  cycles advanced (run)   : %llu\n", (unsigned long long)ctx.stats.cycles_advanced);
  std::printf("  cycles skipped (idle)   : %llu\n", (unsigned long long)ctx.stats.cycles_skipped);
  std::printf("  events delivered        : %llu\n", (unsigned long long)ctx.stats.events_delivered);
  std::printf("  component phase-evals   : %llu\n", (unsigned long long)ctx.stats.phase_evals);
  std::printf("  fetched / issued / retired : %llu / %llu / %llu\n",
              (unsigned long long)cpu.fetched(), (unsigned long long)cpu.issued(),
              (unsigned long long)cpu.retired());
  std::printf("  max fetch-queue occupancy : %llu (cap %zu)\n",
              (unsigned long long)cpu.max_fetchq_occupancy(), ccfg.fetch_queue_cap);
  std::printf("  fetch-full / issue-hazard : %llu / %llu\n",
              (unsigned long long)cpu.fetch_full_events(),
              (unsigned long long)cpu.issue_hazard_events());
  std::printf("  mem hits / misses         : %llu / %llu\n",
              (unsigned long long)mem.hits(), (unsigned long long)mem.misses());

  // ---- 功能对拍 ----
  std::vector<uint64_t> ref = ref_run(prog, init);
  bool regs_ok = true;
  for (int r = 0; r < 32; ++r)
    if (cpu.reg(r) != ref[r]) { regs_ok = false;
      std::printf("  reg mismatch r%d: got %llu expected %llu\n", r,
                  (unsigned long long)cpu.reg(r), (unsigned long long)ref[r]); }

  // ---- 逐目标自检(DESIGN.md §7)----
  std::printf("\n=== V1 kernel goals ===\n");
  // 目标 1 (cur/next) 与 目标 2 (event wheel 细节) 由 `make test` 的单元测试严格覆盖。
  check("goal2: event wheel drove the sim (events delivered)",
        ctx.stats.events_delivered >= 8);
  // 目标 3:活动驱动 —— 实际 eval 次数远小于"每周期全量扫描"。
  {
    uint64_t total_cycles = ctx.stats.cycles_advanced + ctx.stats.cycles_skipped;
    uint64_t full_scan = ctx.num_components() * total_cycles;
    std::printf("  (activity-driven: %llu evals vs %llu full-scan)\n",
                (unsigned long long)ctx.stats.phase_evals, (unsigned long long)full_scan);
    check("goal3: active-set eval << full-scan; idle cycles skipped",
          ctx.stats.phase_evals < full_scan && ctx.stats.cycles_skipped > 0);
  }
  // 目标 4:多周期 FU completion 正确(功能对拍通过即证明 latency/结果链路正确)。
  check("goal4: multi-cycle FU results correct (ref match)", regs_ok);
  // 目标 5:FU 忙时前端仍前进 —— fetch 队列被填满。
  check("goal5: frontend advances while backend stalls (fetchq filled to cap)",
        cpu.max_fetchq_occupancy() == ccfg.fetch_queue_cap);
  // 目标 6:backpressure —— fetch 队列满事件发生。
  check("goal6: backpressure observed (fetch-queue-full events)",
        cpu.fetch_full_events() > 0 && cpu.issue_hazard_events() > 0);
  // 目标 7:系统 blocked 时跳到 next event —— DRAM miss 造成大幅跳跃。
  check("goal7: time-skip over idle cycles (>100 skipped on DRAM miss)",
        ctx.stats.cycles_skipped > 100);
  // 收尾正确性(issued 含 HALT,retired 不含 -> 相差 1)
  check("halted cleanly & all insts retired",
        cpu.halted() && cpu.issued() == cpu.retired() + 1 && regs_ok);

  regressions();

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
