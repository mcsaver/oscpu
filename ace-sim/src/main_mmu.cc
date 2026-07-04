// ace-sim ④ TLB/MMU demo:虚拟->物理地址翻译 + TLB 缓存 + 页表 walk 延迟。
//
// 翻译的**值**是确定性双射(PPN = VPN ^ KEY),golden 与详细核共用 -> load/store 落在相同物理地址
// -> difftest 逐位一致。**TLB**(组相联 + LRU)是纯时序/统计:命中=快,未命中=页表 walk(加延迟),
// 对**功能结果无影响**(与 cache 层级同理)。展示:同页第二次访问 TLB 命中;vaddr≠paddr。
#include <cstdint>
#include <cstdio>
#include <vector>

#include "core/top/CpuTop.hh"
#include "isa/inst.hh"
#include "isa/ref_model.hh"
#include "mem/mmu.hh"
#include "mem/simple_mem.hh"
#include "sim/context.hh"

using namespace ace;

static int g_fail = 0;
static void check(const char* what, bool ok) {
  std::printf("  [%s] %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) ++g_fail;
}

static OooConfig mmu_cfg() {
  OooConfig cfg;
  cfg.mmu_on = true;
  cfg.tlb_sets = 16; cfg.tlb_ways = 4; cfg.tlb_walk_lat = 20;
  return cfg;
}

// 随机 load/store(跨若干页)对拍功能金标准(golden 同样翻译 -> 物理地址一致)。
static void fuzz(int iters) {
  uint64_t s = 0x4d3120e77ull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t hits = 0, misses = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    // r1..r4 = 4 个页基址(跨页,制造 TLB 复用/替换)
    for (int r = 1; r <= 4; ++r) init[r] = (uint64_t)(r) << PAGE_SHIFT;
    for (int r = 5; r <= 12; ++r) init[r] = rnd(1000);

    int len = 6 + static_cast<int>(rnd(20));
    Program prog;
    for (int i = 0; i < len; ++i) {
      int base = 1 + static_cast<int>(rnd(4));           // r1..r4(页基址)
      uint64_t off = rnd(4) * 8;                          // 页内偏移
      int d = 5 + static_cast<int>(rnd(8)), a = 5 + static_cast<int>(rnd(8));
      switch (rnd(6)) {
        case 0: case 1: prog.push_back(load(d, base, off)); break;
        case 2: case 3: prog.push_back(store(base, a, off)); break;
        default: prog.push_back(alu(d, a, 5 + int(rnd(8)), rnd(16))); break;
      }
    }
    prog.push_back(halt());

    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    CpuTop cpu(prog, &mem, mid, mmu_cfg());
    ctx.add(&cpu);
    for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
    cpu.kickoff(ctx);
    ctx.run(500'000);

    RefResult ref = ref_run_full(prog, init, /*mmu_on=*/true);  // golden 同样翻译
    bool ok = cpu.halted();
    for (int r = 0; r < 32 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (mem.peek(kv.first) == kv.second);  // 物理地址键
    if (!ok) ++bad;
    hits += cpu.tlb_hits(); misses += cpu.tlb_misses();
  }
  std::printf("\n=== MMU differential fuzz ===\n");
  std::printf("  %d programs;TLB 累计 命中 %llu / 未命中 %llu(命中率 %.1f%%)\n",
              iters, (unsigned long long)hits, (unsigned long long)misses,
              100.0 * hits / (hits + misses + 1));
  check("mmu-fuzz: 所有 load/store 程序(开翻译)对拍金标准(regs + 物理内存)", bad == 0);
}

int main() {
  // 展示翻译 + TLB:store/load 往返,同页二次访问 TLB 命中。
  std::vector<uint64_t> init(32, 0);
  init[1] = 0x1000; init[2] = 0x2000; init[3] = 0x3000;
  init[4] = 111; init[5] = 222;

  Program prog;
  prog.push_back(store(1, 4, 0));   // mem[V0x1000] = 111
  prog.push_back(store(2, 5, 0));   // mem[V0x2000] = 222
  prog.push_back(load(6, 1, 0));    // r6 = mem[V0x1000] = 111
  prog.push_back(load(7, 2, 0));    // r7 = mem[V0x2000] = 222
  prog.push_back(load(8, 1, 8));    // r8 = mem[V0x1008](与 r6 同页 -> TLB 命中)
  prog.push_back(store(3, 6, 0));   // mem[V0x3000] = r6 = 111
  prog.push_back(load(9, 3, 0));    // r9 = mem[V0x3000] = 111
  prog.push_back(halt());

  SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid, mmu_cfg());
  ctx.add(&cpu);
  for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
  cpu.kickoff(ctx);
  ctx.run(100'000);

  RefResult ref = ref_run_full(prog, init, /*mmu_on=*/true);

  std::printf("=== ACE-Sim TLB/MMU 地址翻译 ===\n");
  std::printf("  翻译示例:V0x1000 -> P0x%llx, V0x2000 -> P0x%llx, V0x3000 -> P0x%llx\n",
              (unsigned long long)mmu_translate(0x1000, true),
              (unsigned long long)mmu_translate(0x2000, true),
              (unsigned long long)mmu_translate(0x3000, true));
  std::printf("  r6=%llu r7=%llu r8=%llu r9=%llu  TLB 命中/未命中 = %llu/%llu\n",
              (unsigned long long)cpu.arch_reg(6), (unsigned long long)cpu.arch_reg(7),
              (unsigned long long)cpu.arch_reg(8), (unsigned long long)cpu.arch_reg(9),
              (unsigned long long)cpu.tlb_hits(), (unsigned long long)cpu.tlb_misses());

  bool regs_ok = cpu.halted();
  for (int r = 0; r < 32 && regs_ok; ++r) regs_ok = (cpu.arch_reg(r) == ref.regs[r]);
  bool mem_ok = true;
  for (const auto& kv : ref.mem) mem_ok = mem_ok && (mem.peek(kv.first) == kv.second);

  std::printf("\n=== goals ===\n");
  check("翻译透明:regs bit-exact vs 功能金标准(同样翻译)", regs_ok);
  check("物理内存值一致(store 落在翻译后物理地址)", mem_ok);
  check("vaddr ≠ paddr(翻译确实生效)", mmu_translate(0x1000, true) != 0x1000);
  check("值经翻译往返正确(r6=111 r7=222 r9=111)",
        cpu.arch_reg(6) == 111 && cpu.arch_reg(7) == 222 && cpu.arch_reg(9) == 111);
  check("TLB 命中确有发生(同页复用)", cpu.tlb_hits() > 0);

  fuzz(20000);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
