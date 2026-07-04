// ace-sim ⑤ gshare + RAS + JAL/JALR demo:全局历史预测 + 返回地址栈 + 调用/返回控制流。
//
// · JAL(直接调用):目标 imm 取指即知,写链接 rd=pc+1;call(rd=ra)取指拍 RAS push。
// · JALR(间接跳转/返回):目标 reg[rs]+off execute 才知 -> RAS 预测返回目标;误判 execute 拍 squash。
// · gshare:GHR ^ PC 索引 PHT,捕获分支相关性(opt-in,ghist_bits>0)。
// 三者只影响**预测/时序**;架构正确性由 resolve + squash + RAS/GHR 投机结构保证 -> difftest 逐位一致。
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

static OooConfig gshare_cfg() {
  OooConfig cfg;
  cfg.ghist_bits = 8;   // 开 gshare
  cfg.ras_depth = 16;
  return cfg;
}

// 随机含 call/return + 分支 + int/mem 的程序对拍功能金标准。
// 程序结构:主体随机(可含 call 到子程序),子程序 = 少量计算 + ret。控制流确定 -> golden 复现。
static void fuzz(int iters) {
  uint64_t s = 0x9a5711e0cull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t calls = 0, jalrs = 0, jmis = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    init[10] = 0x1000; init[11] = 0x1040;
    for (int r = 2; r <= 9; ++r) init[r] = rnd(40);

    // 主体长度 + 子程序数;先占位 call 目标,构完子程序后回填。
    int body = 5 + static_cast<int>(rnd(10));
    int nsub = 1 + static_cast<int>(rnd(3));
    Program prog;
    std::vector<size_t> call_sites;
    for (int i = 0; i < body; ++i) {
      int d = 2 + static_cast<int>(rnd(8)), a = 2 + static_cast<int>(rnd(8)), b = 2 + static_cast<int>(rnd(8));
      switch (rnd(8)) {
        case 0: call_sites.push_back(prog.size()); prog.push_back(call(0)); break;  // 目标待回填
        case 1: prog.push_back(load(d, 10 + int(rnd(2)), rnd(2) * 8)); break;
        case 2: prog.push_back(store(10 + int(rnd(2)), a, rnd(2) * 8)); break;
        case 3: if (i + 2 < body) prog.push_back(beq(a, b, prog.size() + 2)); else prog.push_back(alu(d, a, b, rnd(8))); break;
        default: prog.push_back(alu(d, a, b, rnd(8))); break;
      }
    }
    prog.push_back(halt());
    // 子程序:每个 = 几条计算 + ret。记录入口。
    std::vector<uint64_t> sub_entry;
    for (int ssub = 0; ssub < nsub; ++ssub) {
      sub_entry.push_back(prog.size());
      int slen = 1 + static_cast<int>(rnd(3));
      for (int j = 0; j < slen; ++j) {
        int d = 20 + static_cast<int>(rnd(6)), a = 2 + static_cast<int>(rnd(8));
        prog.push_back(alu(d, a, 2 + int(rnd(8)), rnd(8)));
      }
      prog.push_back(ret());
    }
    // 回填 call 目标(轮流指向各子程序)
    for (size_t ci = 0; ci < call_sites.size(); ++ci)
      prog[call_sites[ci]] = call(sub_entry[ci % sub_entry.size()]);

    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    CpuTop cpu(prog, &mem, mid, gshare_cfg());
    ctx.add(&cpu);
    for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
    cpu.kickoff(ctx);
    ctx.run(500'000);

    RefResult ref = ref_run_full(prog, init);
    bool ok = cpu.halted();
    for (int r = 0; r < 32 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (mem.peek(kv.first) == kv.second);
    if (!ok) ++bad;
    calls += cpu.calls(); jalrs += cpu.jalrs(); jmis += cpu.jalr_mispredicts();
  }
  std::printf("\n=== gshare/RAS differential fuzz ===\n");
  std::printf("  %d programs;call %llu, JALR/ret %llu(其中误判 %llu -> RAS 命中率 %.1f%%)\n",
              iters, (unsigned long long)calls, (unsigned long long)jalrs, (unsigned long long)jmis,
              100.0 * (jalrs - jmis) / (jalrs + 1));
  check("gshare-fuzz: 所有 call/ret/分支/int/mem 程序对拍金标准(regs+mem)", bad == 0);
  check("RAS 有效:返回目标预测命中占多数(误判 < JALR 半数)", jmis * 2 < jalrs);
}

int main() {
  // 展示:主程序 call 子程序两次,子程序 ret 回不同返回点 -> RAS 正确预测两个返回目标。
  //   pc0: r2 = 10
  //   pc1: call SUB        (link ra=2, 跳 SUB;RAS push 2)
  //   pc2: r3 = r2 + 100   (=110;第一次返回点)
  //   pc3: call SUB        (link ra=4, 跳 SUB;RAS push 4)
  //   pc4: r4 = r2 + 200   (=210;第二次返回点)
  //   pc5: halt
  //   pc6: SUB: r2 = r2 + 5 (=15)
  //   pc7: ret              (跳 ra)
  Program prog;
  prog.push_back(alu(2, 0, 0, 10));   // 0: r2 = 10
  prog.push_back(call(6));            // 1: call SUB(pc6)
  prog.push_back(alu(3, 2, 0, 100));  // 2: r3 = r2 + 100
  prog.push_back(call(6));            // 3: call SUB
  prog.push_back(alu(4, 2, 0, 200));  // 4: r4 = r2 + 200
  prog.push_back(halt());             // 5:
  prog.push_back(alu(2, 2, 0, 5));    // 6: SUB: r2 += 5
  prog.push_back(ret());              // 7: ret -> ra

  std::vector<uint64_t> init(32, 0);

  SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid, gshare_cfg());
  ctx.add(&cpu);
  cpu.kickoff(ctx);
  ctx.run(100'000);

  RefResult ref = ref_run_full(prog, init);

  std::printf("=== ACE-Sim gshare + RAS + call/return ===\n");
  std::printf("  r2=%llu r3=%llu r4=%llu  (call=%llu JALR=%llu 误判=%llu)\n",
              (unsigned long long)cpu.arch_reg(2), (unsigned long long)cpu.arch_reg(3),
              (unsigned long long)cpu.arch_reg(4), (unsigned long long)cpu.calls(),
              (unsigned long long)cpu.jalrs(), (unsigned long long)cpu.jalr_mispredicts());

  bool regs_ok = cpu.halted();
  for (int r = 0; r < 32 && regs_ok; ++r) regs_ok = (cpu.arch_reg(r) == ref.regs[r]);

  std::printf("\n=== goals ===\n");
  // 语义:r2: 10 -> call SUB(+5)=15 -> r3=15+100=115 -> call SUB(+5)=20 -> r4=20+200=220
  check("call/return 控制流正确,regs bit-exact vs golden", regs_ok);
  check("r2=20 r3=115 r4=220(两次 call/ret 语义)",
        cpu.arch_reg(2) == 20 && cpu.arch_reg(3) == 115 && cpu.arch_reg(4) == 220);
  check("两次 call + 两次 ret 均被执行", cpu.calls() == 2 && cpu.jalrs() == 2);
  check("RAS 正确预测两个不同返回目标(ret 零误判)", cpu.jalr_mispredicts() == 0);

  fuzz(20000);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
