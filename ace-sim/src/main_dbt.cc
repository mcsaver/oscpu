// ace-sim ⑦ JIT/DBT block 解释器 demo:功能后端从逐指令解释 -> basic-block 块级执行,加速 fast-forward。
//
// DBT:按 basic block 切分 + 按入口 PC 缓存块边界;循环体的块只翻译一次、复用多次执行 -> 摊销边界扫描。
// 指令语义复用 FunctionalBackend::apply_inst(单一来源)-> 块解释与逐指令解释、与详细核逐位一致。
#include <cstdint>
#include <cstdio>
#include <vector>

#include "core/top/CpuTop.hh"
#include "isa/inst.hh"
#include "isa/functional.hh"
#include "isa/block_interp.hh"
#include "isa/ref_model.hh"
#include "mem/simple_mem.hh"
#include "sim/context.hh"

using namespace ace;

static int g_fail = 0;
static void check(const char* what, bool ok) {
  std::printf("  [%s] %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) ++g_fail;
}

static bool same_state(const FuncState& a, const FuncState& b) {
  if (a.regs.size() != b.regs.size()) return false;
  for (size_t r = 0; r < a.regs.size(); ++r) if (a.regs[r] != b.regs[r]) return false;
  for (const auto& kv : a.mem) {
    auto it = b.mem.find(kv.first);
    uint64_t bv = (it != b.mem.end()) ? it->second : SimpleMemory::data_at(kv.first);
    if (kv.second != bv) return false;
  }
  for (const auto& kv : b.mem) {
    auto it = a.mem.find(kv.first);
    uint64_t av = (it != a.mem.end()) ? it->second : SimpleMemory::data_at(kv.first);
    if (kv.second != av) return false;
  }
  return true;
}

// 差分:块解释器 vs 逐指令解释器,对任意随机程序(含循环/分支/call/mem)最终态必须逐位一致。
static void fuzz(int iters) {
  uint64_t s = 0xdb7c0ffeeull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t tr = 0, be = 0, ins = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    init[10] = 0x1000; init[11] = 0x1040;
    for (int r = 2; r <= 9; ++r) init[r] = rnd(30);

    int len = 6 + static_cast<int>(rnd(16));
    Program prog;
    for (int i = 0; i < len; ++i) {
      int d = 2 + static_cast<int>(rnd(8)), a = 2 + static_cast<int>(rnd(8)), b = 2 + static_cast<int>(rnd(8));
      switch (rnd(9)) {
        case 0:
          if (i >= 1 && rnd(2)) { prog.push_back(beq(a, b, rnd(prog.size()))); }  // 后向可成环(budget 上限兜底)
          else { prog.push_back(bne(a, b, prog.size() + 1 + rnd(3))); }
          break;
        case 1: prog.push_back(load(d, 10 + int(rnd(2)), rnd(2) * 8)); break;
        case 2: prog.push_back(store(10 + int(rnd(2)), a, rnd(2) * 8)); break;
        case 3: prog.push_back(mul(d, a, b)); break;
        default: prog.push_back(alu(d, a, b, rnd(8))); break;
      }
    }
    prog.push_back(halt());

    // 两个功能模型跑同一程序、同一 budget。
    const uint64_t budget = 200000;
    FunctionalBackend fb(prog, init);   fb.run(budget);
    BlockInterpreter  bi(prog, init);   bi.run(budget);
    if (!same_state(fb.state(), bi.state())) ++bad;
    tr += bi.translations(); be += bi.block_execs(); ins += bi.insts();
  }
  std::printf("\n=== DBT block-interp differential fuzz ===\n");
  std::printf("  %d programs;块翻译 %llu 次,块执行 %llu 次,指令 %llu 条(复用比 execs/translations = %.2f)\n",
              iters, (unsigned long long)tr, (unsigned long long)be, (unsigned long long)ins,
              (double)be / (tr + 1));
  check("dbt-fuzz: 块解释器与逐指令解释器最终态逐位一致(任意程序)", bad == 0);
}

int main() {
  // 循环:块只翻译一次、复用 N 次。r1: 1..N;r3 = sum(1..N)。
  const uint64_t N = 1000;
  std::vector<uint64_t> init(32, 0);
  init[2] = N;

  Program prog;
  prog.push_back(alu(1, 1, 0, 1));    // 0: r1 += 1
  prog.push_back(alu(3, 3, 1, 0));    // 1: r3 += r1
  prog.push_back(bne(1, 2, 0));       // 2: if r1 != N goto 0
  prog.push_back(halt());             // 3:

  BlockInterpreter bi(prog, init);
  bi.run(10'000'000);

  // 金标准(逐指令)对照 + 详细核对照
  RefResult ref = ref_run_full(prog, init);
  SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid);
  ctx.add(&cpu);
  for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
  cpu.kickoff(ctx); ctx.run(5'000'000);

  std::printf("=== ACE-Sim DBT block 解释器 ===\n");
  std::printf("  循环 N=%llu:r1=%llu r3=%llu(=sum 1..N)\n",
              (unsigned long long)N, (unsigned long long)bi.state().regs[1],
              (unsigned long long)bi.state().regs[3]);
  std::printf("  块翻译 %llu 次,块执行 %llu 次,指令 %llu 条,缓存块 %zu\n",
              (unsigned long long)bi.translations(), (unsigned long long)bi.block_execs(),
              (unsigned long long)bi.insts(), bi.cached_blocks());

  bool block_vs_golden = (bi.state().regs[1] == ref.regs[1] && bi.state().regs[3] == ref.regs[3]);
  bool block_vs_detail = (bi.state().regs[1] == cpu.arch_reg(1) && bi.state().regs[3] == cpu.arch_reg(3));

  std::printf("\n=== goals ===\n");
  check("块解释结果 = 逐指令金标准(r1=N, r3=sum)",
        block_vs_golden && bi.state().regs[1] == N && bi.state().regs[3] == N * (N + 1) / 2);
  check("块解释结果 = 详细核(三方一致)", block_vs_detail);
  check("循环块只翻译一次、复用多次(翻译数 << 块执行数)",
        bi.translations() <= 4 && bi.block_execs() > N);
  check("翻译缓存有效(块数有界,不随迭代增长)", bi.cached_blocks() <= 4);

  fuzz(20000);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
