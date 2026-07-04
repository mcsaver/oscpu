// ace-sim ⑥ STA/STD 分离 demo:store 裂成 STA(地址)+ STD(数据)两个独立微 op。
//
// 收益:store 的**地址**可在 base 就绪时先算(STA),无需等**数据**(STD,可能来自长延迟运算)。
// 于是:younger load 到**不同地址**可越过该 store 前进(旧模型要等整条 store);到**同址**则精确等 STD 后前递。
// 正确性(内存语义)由差分对拍守恒;module 抽取:Decode(译码裂分)+ LoadUnit(load AGU/翻译)。
#include <cstdint>
#include <cstdio>
#include <vector>

#include "core/top/CpuTop.hh"
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

// 压力:store 数据来自长延迟运算(div/mul),STD 滞后 STA;大量 load 交错(含同址/异址)。
// 全部差分对拍 —— STA/STD 分离 + 精确消歧(异址越过 / 同址等 STD 前递)不得改内存语义。
static void fuzz(int iters) {
  uint64_t s = 0x57a57de99ull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t fwds = 0, ld = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    // 少数几个地址寄存器(制造同址冲突 + 前递),其余为数据
    init[1] = 0x1000; init[2] = 0x1008; init[3] = 0x1010;
    for (int r = 4; r <= 12; ++r) init[r] = 1 + rnd(30);

    int len = 8 + static_cast<int>(rnd(20));
    Program prog;
    for (int i = 0; i < len; ++i) {
      int addr = 1 + static_cast<int>(rnd(3));            // r1..r3(少数地址 -> 冲突)
      int d = 4 + static_cast<int>(rnd(8)), a = 4 + static_cast<int>(rnd(8)), b = 4 + static_cast<int>(rnd(8));
      switch (rnd(9)) {
        case 0: prog.push_back(divi(d, a, b)); break;      // 长延迟 -> 后续 store 数据滞后
        case 1: prog.push_back(mul(d, a, b)); break;
        case 2: case 3: prog.push_back(store(addr, d, 0)); break;  // 数据 d 可能刚由 div/mul 产
        case 4: case 5: case 6: prog.push_back(load(d, addr, 0)); break;  // 同址/异址交错
        default: prog.push_back(alu(d, a, b, rnd(8))); break;
      }
    }
    prog.push_back(halt());

    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    CpuTop cpu(prog, &mem, mid);
    ctx.add(&cpu);
    for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
    cpu.kickoff(ctx);
    ctx.run(500'000);

    RefResult ref = ref_run_full(prog, init);
    bool ok = cpu.halted();
    for (int r = 0; r < 32 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (mem.peek(kv.first) == kv.second);
    if (!ok) ++bad;
    fwds += cpu.forwards(); ld += cpu.mem_loads();
  }
  std::printf("\n=== STA/STD differential fuzz ===\n");
  std::printf("  %d programs;store->load 前递 %llu 次,访存 load %llu 次\n",
              iters, (unsigned long long)fwds, (unsigned long long)ld);
  check("sta-fuzz: 所有(store 数据滞后 + 同址/异址 load 交错)程序对拍金标准(regs+mem)", bad == 0);
  check("确有 store->load 前递发生(消歧+STD 前递路径被覆盖)", fwds > 0);
}

int main() {
  // store 的数据来自长延迟 div;STA(地址)早就绪,STD(数据)等 div。
  // 异址 load(r4)可越过;同址 load(r5)等 STD 后前递。
  std::vector<uint64_t> init(32, 0);
  init[1] = 0x1000; init[2] = 0x2000; init[6] = 100; init[7] = 7;

  Program prog;
  prog.push_back(divi(3, 6, 7));    // 0: r3 = 100/7 = 14(长延迟)
  prog.push_back(store(1, 3, 0));   // 1: mem[0x1000] = r3。STA 早,STD 等 div。
  prog.push_back(load(4, 2, 0));    // 2: r4 = mem[0x2000](异址 -> 越过 store 数据)
  prog.push_back(load(5, 1, 0));    // 3: r5 = mem[0x1000] = 14(同址 -> 等 STD 前递)
  prog.push_back(halt());

  SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid);
  ctx.add(&cpu);
  for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
  cpu.kickoff(ctx);
  ctx.run(100'000);

  RefResult ref = ref_run_full(prog, init);

  std::printf("=== ACE-Sim STA/STD 地址/数据分离 ===\n");
  std::printf("  r3=%llu(store 数据) r4=%llu(异址 load) r5=%llu(同址前递)  前递=%llu\n",
              (unsigned long long)cpu.arch_reg(3), (unsigned long long)cpu.arch_reg(4),
              (unsigned long long)cpu.arch_reg(5), (unsigned long long)cpu.forwards());

  bool regs_ok = cpu.halted();
  for (int r = 0; r < 32 && regs_ok; ++r) regs_ok = (cpu.arch_reg(r) == ref.regs[r]);
  bool mem_ok = true;
  for (const auto& kv : ref.mem) mem_ok = mem_ok && (mem.peek(kv.first) == kv.second);

  std::printf("\n=== goals ===\n");
  check("STA/STD 分离下内存语义正确,regs bit-exact vs golden", regs_ok && mem_ok);
  check("r3=14 r5=14(同址前递取 store 数据)", cpu.arch_reg(3) == 14 && cpu.arch_reg(5) == 14);
  check("异址 load r4 值正确(= mem[0x2000])", cpu.arch_reg(4) == SimpleMemory::data_at(0x2000));
  check("同址 load 经 store->load 前递(免访存)", cpu.forwards() >= 1);

  fuzz(20000);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
