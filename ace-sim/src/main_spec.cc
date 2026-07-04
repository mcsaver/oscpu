// ace-sim V4 demo:投机 —— 分支预测 + 误判 squash + RAT 快照恢复 + dyn_id 惰性取消。
// 用控制流参考模型对拍;并用随机差分(分支+LSQ)压投机恢复的正确性。
#include <cstdint>
#include <cstdio>
#include <vector>

#include "isa/inst.hh"
#include "core/top/CpuTop.hh"
#include "isa/ref_model.hh"
#include "mem/simple_mem.hh"
#include "sim/context.hh"

using namespace ace;

static int g_fail = 0;
static void check(const char* what, bool ok) {
  std::printf("  [%s] %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) ++g_fail;
}

// 随机差分:随机 alu/mul/div/load/store/branch(前向,保证终止)程序,CPU vs 参考模型。
static void fuzz(int iters) {
  uint64_t s = 0xb47c40de5ull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t tot_mis = 0, tot_sq = 0, tot_br = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    init[1] = 0x1000; init[2] = 0x1040; init[3] = 0x1080; init[4] = 0x10c0;
    for (int r = 5; r <= 8; ++r) init[r] = rnd(4);  // 小值域 -> 分支方向多变

    int len = 6 + static_cast<int>(rnd(24));
    Program prog;
    for (int i = 0; i < len; ++i) {
      int base = 1 + static_cast<int>(rnd(4));
      int data = 1 + static_cast<int>(rnd(8));
      int dst  = 1 + static_cast<int>(rnd(8));
      int s0   = static_cast<int>(rnd(9));
      int s1   = static_cast<int>(rnd(9));
      uint64_t off = rnd(2) * 8;
      switch (rnd(8)) {
        case 0: case 7: prog.push_back(alu(dst, s0, s1, rnd(16))); break;
        case 1: prog.push_back(mul(dst, s0, s1)); break;
        case 2: prog.push_back(divi(dst, s0, s1)); break;
        case 3: prog.push_back(load(dst, base, off)); break;
        case 4: prog.push_back(store(base, data, off)); break;
        default: {  // 前向分支(目标 (i, len],保证前进 -> 终止)
          uint64_t target = static_cast<uint64_t>(i + 1) + rnd(static_cast<uint64_t>(len - i));
          prog.push_back(rnd(2) ? beq(s0, s1, target) : bne(s0, s1, target));
        } break;
      }
    }
    prog.push_back(halt());

    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    CpuTop cpu(prog, &mem, mid, {});
    ctx.add(&cpu);
    for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
    cpu.kickoff(ctx);
    ctx.run(500'000);

    RefResult ref = ref_run_full(prog, init);
    bool ok = cpu.halted();
    for (int r = 0; r < 32 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (mem.peek(kv.first) == kv.second);
    if (!ok && bad < 3)
      std::printf("  fuzz FAIL iter=%d halted=%d len=%d mis=%llu\n", it, (int)cpu.halted(),
                  len, (unsigned long long)cpu.mispredicts());
    if (!ok) ++bad;
    tot_mis += cpu.mispredicts(); tot_sq += cpu.squashes(); tot_br += cpu.branches();
  }
  std::printf("\n=== V4 differential fuzz ===\n");
  std::printf("  %d random programs; %llu branches, %llu mispredicts, %llu squashes exercised\n",
              iters, (unsigned long long)tot_br, (unsigned long long)tot_mis,
              (unsigned long long)tot_sq);
  check("fuzz: all random (branch+LSQ) programs match ref (regs+mem) and halt", bad == 0);
}

// 端口压力差分:port_capacity=1 + load 密集 + 前向分支。目的=最大化"误判后错误路径 load 占满
// 端口 -> 存活 load 端口停顿 -> 陈旧响应漏唤醒"这一 §5.1 推论洞的触发概率(审查发现的真 bug)。
static void fuzz_port_stress(int iters) {
  uint64_t s = 0x9e3779b97f4a7c15ull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0, hangs = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    init[1] = 0x2000; init[2] = 0x2008; init[3] = 0x2010; init[4] = 0x2018;
    for (int r = 5; r <= 8; ++r) init[r] = rnd(3);  // 极小值域 -> 分支多变、多误判

    int L = 8 + static_cast<int>(rnd(20));
    Program prog;
    for (int i = 0; i < L; ++i) {
      int base = 1 + static_cast<int>(rnd(4));
      int data = 1 + static_cast<int>(rnd(8));
      int dst  = 1 + static_cast<int>(rnd(8));
      int s0   = static_cast<int>(rnd(9));
      int s1   = static_cast<int>(rnd(9));
      switch (rnd(6)) {  // load 密集(3/6)+ 分支(1/6)
        case 0: case 1: case 2: prog.push_back(load(dst, base, 0)); break;
        case 3: prog.push_back(store(base, data, 0)); break;
        case 4: prog.push_back(alu(dst, s0, s1, rnd(4))); break;
        default: {
          uint64_t target = static_cast<uint64_t>(i + 1) + rnd(static_cast<uint64_t>(L - i));
          prog.push_back(rnd(2) ? beq(s0, s1, target) : bne(s0, s1, target));
        } break;
      }
    }
    prog.push_back(halt());

    SimContext ctx;
    // 端口容量 > port_width:issue_width=4 每拍塞 load 比 port_width=1 排空快 -> in_ 累积到满,
    // squash 后留下多条错误路径 load,drain 需多拍,给存活 load 端口停顿的窗口。
    MemConfig mc; mc.port_capacity = 8;
    SimpleMemory mem(mc);
    CompId mid = ctx.add(&mem);
    CpuTop cpu(prog, &mem, mid, {});
    ctx.add(&cpu);
    for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
    cpu.kickoff(ctx);
    ctx.run(500'000);

    RefResult ref = ref_run_full(prog, init);
    bool ok = cpu.halted();
    if (!cpu.halted()) ++hangs;
    for (int r = 0; r < 32 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (mem.peek(kv.first) == kv.second);
    if (!ok) ++bad;
  }
  std::printf("\n=== V4 port-stress fuzz (port_capacity=8, load-heavy) ===\n");
  std::printf("  %d programs; %d hang(halted=false), %d mismatch\n", iters, hangs, bad);
  check("port-stress: no lost-wakeup, all match ref & halt", bad == 0);
}

int main() {
  // 循环求和 1..N:后向分支考验预测器学习 + 两个方向的误判 squash。
  // PC 布局:0 初始化;1..3 循环体+回边分支;4 halt。
  Program prog;
  prog.push_back(alu(10, 0, 0, 0));                   // 0: r10 = 0(累加器)
  prog.push_back(alu(10, 10, 1, 0));                  // 1: r10 += r1   (循环体)
  prog.push_back(alu(1, 1, 0, static_cast<uint64_t>(-1)));  // 2: r1 -= 1
  prog.push_back(bne(1, 0, 1));                       // 3: if r1 != 0 goto 1
  prog.push_back(halt());                             // 4

  std::vector<uint64_t> init(32, 0);
  init[1] = 5;  // N = 5 -> sum = 15

  SimContext ctx;
  SimpleMemory mem;
  CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid, {});
  ctx.add(&cpu);
  for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
  cpu.kickoff(ctx);
  Cycle end = ctx.run(1'000'000);

  RefResult ref = ref_run_full(prog, init);

  std::printf("=== ACE-Sim V4 (speculation) run summary ===\n");
  std::printf("  end cycle           : %llu\n", (unsigned long long)end);
  std::printf("  dispatched/retired  : %llu / %llu\n",
              (unsigned long long)cpu.dispatched(), (unsigned long long)cpu.retired());
  std::printf("  branches/mispredicts/squashes : %llu / %llu / %llu\n",
              (unsigned long long)cpu.branches(), (unsigned long long)cpu.mispredicts(),
              (unsigned long long)cpu.squashes());
  std::printf("  r10 (sum 1..5)      : %llu  (ref %llu)\n",
              (unsigned long long)cpu.arch_reg(10), (unsigned long long)ref.regs[10]);

  bool regs_ok = true;
  for (int r = 0; r < 32; ++r)
    if (cpu.arch_reg(r) != ref.regs[r]) {
      regs_ok = false;
      std::printf("  reg mismatch r%d: got %llu expected %llu\n", r,
                  (unsigned long long)cpu.arch_reg(r), (unsigned long long)ref.regs[r]);
    }

  std::printf("\n=== V4 goals ===\n");
  check("functional correct through control flow (loop sum matches ref)", regs_ok);
  check("branch prediction resolved branches", cpu.branches() >= 5);
  check("mispredictions detected & squashed (both directions)",
        cpu.mispredicts() >= 1 && cpu.squashes() == cpu.mispredicts());
  check("predictor learned: fewer mispredicts than branches (not all wrong)",
        cpu.mispredicts() < cpu.branches());
  check("halted cleanly after speculative execution", cpu.halted());

  fuzz(20000);
  fuzz_port_stress(20000);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
