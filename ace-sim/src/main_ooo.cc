// ace-sim V2 demo:乱序核(rename + IQ + ROB)。
// 与 V1 顺序核 head-to-head 跑同一程序,证明:功能一致、乱序完成、按序精确提交、更快。
#include <cstdint>
#include <cstdio>
#include <vector>

#include "isa/inst.hh"
#include "core/top/CpuTop.hh"
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

static void regressions() {
  std::printf("\n=== V2 regressions (sleep-safety / HALT gating) ===\n");

  // II>latency 结构冒险:两条独立 ALU 抢同一 FU,第二条靠 CpuWake 兜底,不得睡死。
  {
    SimContext ctx;
    SimpleMemory mem;
    CompId mid = ctx.add(&mem);
    OooConfig cfg;
    cfg.alu = FuDesc{/*lat*/2, /*ii*/10, /*width*/1};
    Program prog;
    prog.push_back(alu(1, 0, 0, 5));
    prog.push_back(alu(2, 0, 0, 7));  // 独立,同一 ALU:结构冒险停顿
    prog.push_back(halt());
    CpuTop cpu(prog, &mem, mid, cfg);
    ctx.add(&cpu);
    cpu.kickoff(ctx);
    ctx.run(10'000);
    check("regress[II>lat]: OoO halts, no lost-wakeup",
          cpu.halted() && cpu.retired() == 2 && cpu.arch_reg(1) == 5 && cpu.arch_reg(2) == 7);
  }

  // HALT 之后的指令绝不取指/分派/发射(不得发真实内存请求)。
  {
    SimContext ctx;
    SimpleMemory mem;
    CompId mid = ctx.add(&mem);
    Program prog;
    prog.push_back(alu(1, 0, 0, 9));
    prog.push_back(halt());
    prog.push_back(load(30, 2, 0));   // HALT 后:若执行会发 DRAM 请求
    prog.push_back(alu(31, 0, 0, 1));
    CpuTop cpu(prog, &mem, mid, {});
    ctx.add(&cpu);
    cpu.set_arch_reg(2, 0x80000000);
    cpu.kickoff(ctx);
    ctx.run(10'000);
    check("regress[post-HALT]: OoO never executes past HALT (no mem req)",
          cpu.halted() && cpu.retired() == 1 && mem.misses() == 0 &&
          cpu.arch_reg(30) == 0 && cpu.arch_reg(31) == 0);
  }
}

int main() {
  // 程序:长延迟 DIV 产 r10;紧跟依赖它的 r11(在 IQ 里等);再跟一批独立 ALU
  // (顺序核会被 r11 卡死在发射队头,乱序核让它们越过 r11 先发射先完成)。
  Program prog;
  prog.push_back(alu(2, 0, 0, 1));      // r2 = 1
  prog.push_back(divi(10, 1, 2));       // r10 = r1 / r2 = r1  (20 周期长延迟)
  prog.push_back(alu(11, 10, -1, 1));   // r11 = r10 + 1       (依赖 DIV -> 在 IQ 等待)
  for (int r = 12; r <= 19; ++r)        // 8 条独立 ALU:乱序越过 r11 先发射/完成
    prog.push_back(alu(r, 1, 1, static_cast<uint64_t>(r)));
  prog.push_back(alu(20, 11, -1, 1));   // r20 = r11 + 1       (依赖 r11)
  prog.push_back(load(21, 1, 0));       // r21 = M[r1]         (cache 命中,与上文独立)
  prog.push_back(halt());

  std::vector<uint64_t> init(32, 0);
  init[1] = 0x1000;

  // V2 乱序核跑该程序(栈对象)
  SimContext ctx;
  SimpleMemory mem;
  CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid, {});
  ctx.add(&cpu);
  for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
  cpu.kickoff(ctx);
  Cycle end_ooo = ctx.run(1'000'000);

  // V1 顺序核跑同一程序(head-to-head)
  SimContext ctx1;
  SimpleMemory mem1;
  CompId mid1 = ctx1.add(&mem1);
  CycleSimpleCpu cpu1(prog, &mem1, mid1, {});
  ctx1.add(&cpu1);
  for (int r = 0; r < 32; ++r) cpu1.set_reg(r, init[r]);
  cpu1.kickoff(ctx1);
  Cycle end_inorder = ctx1.run(1'000'000);

  // ---- 报告 ----
  std::printf("=== ACE-Sim V2 (out-of-order) run summary ===\n");
  std::printf("  OoO end cycle       : %llu\n", (unsigned long long)end_ooo);
  std::printf("  in-order end cycle  : %llu  (same program on V1 core)\n",
              (unsigned long long)end_inorder);
  std::printf("  OoO fetched/dispatched/issued/retired : %llu / %llu / %llu / %llu\n",
              (unsigned long long)cpu.fetched(), (unsigned long long)cpu.dispatched(),
              (unsigned long long)cpu.issued(), (unsigned long long)cpu.retired());

  // 完成顺序 / 提交顺序(dyn_id 在重命名时按程序序递增分配)
  const std::vector<uint64_t>& co = cpu.completion_order();
  const std::vector<uint64_t>& cm = cpu.commit_order();
  std::printf("  completion order (dyn_id): ");
  for (uint64_t x : co) std::printf("%llu ", (unsigned long long)x);
  std::printf("\n  commit order     (dyn_id): ");
  for (uint64_t x : cm) std::printf("%llu ", (unsigned long long)x);
  std::printf("\n");

  bool ooo_completion = false;  // 存在逆序完成 => 真乱序
  for (size_t i = 1; i < co.size(); ++i)
    if (co[i] < co[i - 1]) ooo_completion = true;
  bool inorder_commit = true;   // 提交严格递增 => 按序精确提交
  for (size_t i = 1; i < cm.size(); ++i)
    if (cm[i] <= cm[i - 1]) inorder_commit = false;

  std::vector<uint64_t> ref = ref_run(prog, init);
  bool regs_ok = true;
  for (int r = 0; r < 32; ++r)
    if (cpu.arch_reg(r) != ref[r]) {
      regs_ok = false;
      std::printf("  reg mismatch r%d: got %llu expected %llu\n", r,
                  (unsigned long long)cpu.arch_reg(r), (unsigned long long)ref[r]);
    }

  std::printf("\n=== V2 goals ===\n");
  check("functional correct (arch state matches ref model)", regs_ok);
  check("out-of-order completion (younger indep insts finish before older stalled one)",
        ooo_completion);
  check("in-order precise commit (ROB retires in program order)", inorder_commit);
  check("completion != commit (all completed, retired strictly in order)",
        cpu.halted() && cpu.retired() == cm.size());
  check("OoO strictly faster than in-order on this program",
        end_ooo < end_inorder);

  regressions();

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
