// ace-sim 内存层级 demo:多级 cache(L1D+L2+DRAM+LRU+MSHR)插入 CpuTop 的 load/store 路径。
// 值来自后备内存(与 ref_model 逐位一致 -> difftest 护栏);延迟/命中率来自 cache 走查。
#include <cstdint>
#include <cstdio>
#include <vector>

#include "core/top/CpuTop.hh"
#include "isa/inst.hh"
#include "isa/ref_model.hh"
#include "mem/mem_system.hh"
#include "sim/context.hh"

using namespace ace;

static int g_fail = 0;
static void check(const char* what, bool ok) {
  std::printf("  [%s] %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) ++g_fail;
}

// 随机 load/store 程序在小地址池上跑(制造复用 -> cache 命中),CpuTop+MemSystem vs ref_model 对拍。
static void fuzz(int iters) {
  uint64_t s = 0xca54e1a7ull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t l1h = 0, l1m = 0, dram = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    init[1] = 0x1000; init[2] = 0x1040; init[3] = 0x1080; init[4] = 0x10c0;  // 4 条 cache 线
    for (int r = 5; r <= 8; ++r) init[r] = rnd(1000);

    int len = 6 + static_cast<int>(rnd(20));
    Program prog;
    for (int i = 0; i < len; ++i) {
      int base = 1 + static_cast<int>(rnd(4));
      int data = 1 + static_cast<int>(rnd(8));
      int dst  = 1 + static_cast<int>(rnd(8));
      int s0   = static_cast<int>(rnd(9));
      uint64_t off = rnd(4) * 8;   // 同线内不同字 -> 空间局部性
      switch (rnd(5)) {
        case 0: case 1: prog.push_back(load(dst, base, off)); break;
        case 2: prog.push_back(store(base, data, off)); break;
        default: prog.push_back(alu(dst, s0, s0, rnd(8))); break;
      }
    }
    prog.push_back(halt());

    SimContext ctx;
    MemSystem ms;
    CompId mid = ctx.add(&ms);
    CpuTop cpu(prog, &ms, mid, {});
    ctx.add(&cpu);
    for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
    cpu.kickoff(ctx);
    ctx.run(500'000);

    RefResult ref = ref_run_full(prog, init);
    bool ok = cpu.halted();
    for (int r = 0; r < 32 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (ms.peek(kv.first) == kv.second);
    if (!ok) ++bad;
    l1h += ms.l1().hits(); l1m += ms.l1().misses(); dram += ms.dram_accesses();
  }
  std::printf("\n=== memory-hierarchy fuzz ===\n");
  std::printf("  %d programs; L1 hit-rate ~%.1f%%, DRAM accesses %llu\n",
              iters, 100.0 * double(l1h) / double(l1h + l1m ? l1h + l1m : 1),
              (unsigned long long)dram);
  check("mem-hierarchy: all programs match ref (regs+mem) through L1/L2/DRAM", bad == 0);
}

int main() {
  // 直线程序展示命中/未命中:复用同地址 -> 命中;冷访问 -> 未命中 -> DRAM。
  Program prog;
  prog.push_back(load(5, 1, 0));     // M[0x1000] 冷 miss
  prog.push_back(load(6, 1, 0));     // 复用 -> L1 hit
  prog.push_back(load(7, 1, 64));    // 另一线 -> miss
  prog.push_back(load(8, 1, 0));     // hit
  prog.push_back(load(9, 1, 64));    // hit
  prog.push_back(store(1, 5, 128));  // M[0x1080]=r5 write-allocate
  prog.push_back(load(10, 1, 128));  // hit(已 allocate)
  prog.push_back(halt());
  std::vector<uint64_t> init(32, 0);
  init[1] = 0x1000;

  SimContext ctx;
  MemSystem ms;
  CompId mid = ctx.add(&ms);
  CpuTop cpu(prog, &ms, mid, {});
  ctx.add(&cpu);
  for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
  cpu.kickoff(ctx);
  ctx.run(100'000);

  RefResult ref = ref_run_full(prog, init);

  std::printf("=== ACE-Sim memory hierarchy (L1D + L2 + DRAM) ===\n");
  std::printf("  L1D: %llu hit / %llu miss (%.0f%%)   L2: %llu hit / %llu miss   DRAM: %llu\n",
              (unsigned long long)ms.l1().hits(), (unsigned long long)ms.l1().misses(),
              100.0 * ms.l1().hit_rate(), (unsigned long long)ms.l2().hits(),
              (unsigned long long)ms.l2().misses(), (unsigned long long)ms.dram_accesses());

  bool regs_ok = true;
  for (int r = 0; r < 32; ++r) if (cpu.arch_reg(r) != ref.regs[r]) regs_ok = false;

  std::printf("\n=== goals ===\n");
  check("functional correct through L1/L2/DRAM (regs match ref)", regs_ok && cpu.halted());
  check("cache modeled: cold misses + reuse hits both observed",
        ms.l1().misses() > 0 && ms.l1().hits() > 0);
  check("miss path reached DRAM", ms.dram_accesses() > 0);

  fuzz(20000);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
