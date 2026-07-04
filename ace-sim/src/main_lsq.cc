// ace-sim V3 demo:LSQ —— store queue + store→load 前递 + 内存消歧 + store buffer 落存。
// 用有状态参考模型(寄存器 + 内存)对拍,并逐条自检 LSQ 行为。
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

// 随机差分测试:随机 alu/mul/div/load/store 程序,CPU vs 参考模型(寄存器 + 内存)全对拍。
// 地址池小以制造别名(前递/消歧/落存全被压)。任一不匹配或未停机即失败。
static void fuzz(int iters) {
  uint64_t s = 0xace513d5ull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t total_fwd = 0, total_drain = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    init[1] = 0x1000; init[2] = 0x1040; init[3] = 0x1080; init[4] = 0x10c0;  // 地址寄存器
    for (int r = 5; r <= 8; ++r) init[r] = rnd(1000);

    Program prog;
    int len = 5 + static_cast<int>(rnd(26));
    for (int i = 0; i < len; ++i) {
      int base = 1 + static_cast<int>(rnd(4));    // r1..r4(地址)
      int data = 1 + static_cast<int>(rnd(8));    // r1..r8
      int dst  = 1 + static_cast<int>(rnd(8));
      int s0   = static_cast<int>(rnd(9));        // r0..r8
      int s1   = static_cast<int>(rnd(9));
      uint64_t off = rnd(2) * 8;
      switch (rnd(6)) {
        case 0: case 5: prog.push_back(alu(dst, s0, s1, rnd(16))); break;
        case 1: prog.push_back(mul(dst, s0, s1)); break;
        case 2: prog.push_back(divi(dst, s0, s1)); break;
        case 3: prog.push_back(load(dst, base, off)); break;
        case 4: prog.push_back(store(base, data, off)); break;
      }
    }
    prog.push_back(halt());

    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    CpuTop cpu(prog, &mem, mid, {});
    ctx.add(&cpu);
    for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
    cpu.kickoff(ctx);
    ctx.run(200'000);

    RefResult ref = ref_run_full(prog, init);
    bool ok = cpu.halted();
    for (int r = 0; r < 32 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (mem.peek(kv.first) == kv.second);
    if (!ok && bad < 3)
      std::printf("  fuzz FAIL iter=%d halted=%d len=%d\n", it, (int)cpu.halted(), len);
    if (!ok) ++bad;
    total_fwd += cpu.forwards();
    total_drain += cpu.stores_drained();
  }
  std::printf("\n=== V3 differential fuzz ===\n");
  std::printf("  %d random programs, %llu forwards, %llu drains exercised\n",
              iters, (unsigned long long)total_fwd, (unsigned long long)total_drain);
  check("fuzz: all random programs match ref model (regs + mem) and halt", bad == 0);
}

static void regressions() {
  std::printf("\n=== V3 regressions ===\n");

  // 同址两次 store,load 前递到"最年轻的更老 store"(WAW + 前递选最新)。
  {
    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    Program prog;
    prog.push_back(alu(2, 0, 0, 111));  // r2 = 111
    prog.push_back(alu(3, 0, 0, 222));  // r3 = 222
    prog.push_back(store(1, 2, 0));     // M[r1] = 111
    prog.push_back(store(1, 3, 0));     // M[r1] = 222  (更年轻)
    prog.push_back(load(4, 1, 0));      // r4 = M[r1] -> 前递 222(最年轻的更老 store)
    prog.push_back(halt());
    CpuTop cpu(prog, &mem, mid, {});
    ctx.add(&cpu);
    cpu.set_arch_reg(1, 0x3000);
    cpu.kickoff(ctx);
    ctx.run(10'000);
    check("regress[WAW+fwd]: load forwards youngest older store (222)",
          cpu.halted() && cpu.arch_reg(4) == 222 && mem.peek(0x3000) == 222);
  }

  // load->store->load 环:等待的 younger load 不得 head-of-line 堵住能解析它的 older load。
  // (V3 审查确认的 critical 死锁;修复=LOAD 就绪列表跳过等待项而非 break 整类。)
  {
    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    std::vector<uint64_t> in(32, 0);
    Program prog;
    prog.push_back(alu(30, 0, 0, 0x4000));  // r30 = 0x4000
    prog.push_back(alu(31, 0, 0, 1));       // r31 = 1
    prog.push_back(alu(12, 0, 0, 0x55));    // r12 = 0x55 (store data,早就绪)
    prog.push_back(divi(1, 30, 31));        // r1 = 0x4000 (20 周期,延后 L_d 的基址)
    prog.push_back(load(10, 1, 0));         // L_d:r10 = M[r1]  (基址被 DIV 延后)
    prog.push_back(store(10, 12, 0));       // S:M[r10] = r12   (地址来自 L_d)
    prog.push_back(load(13, 0, 0x9000));    // L_f:r13 = M[0x9000] (早就绪 -> 抢占就绪列表队头)
    prog.push_back(halt());
    CpuTop cpu(prog, &mem, mid, {});
    ctx.add(&cpu);
    cpu.kickoff(ctx);
    ctx.run(100'000);
    RefResult ref = ref_run_full(prog, in);
    bool ok = cpu.halted();
    for (int r = 0; r < 32 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (mem.peek(kv.first) == kv.second);
    check("regress[load->store->load]: no head-of-line deadlock, matches ref", ok);
  }

  // II>latency 睡眠安全 + HALT 闸门(LSQ 核继承 V2 机制)。
  {
    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    OooConfig cfg; cfg.alu = FuDesc{2, 10, 1};
    Program prog;
    prog.push_back(alu(1, 0, 0, 5));
    prog.push_back(alu(2, 0, 0, 7));
    prog.push_back(halt());
    CpuTop cpu(prog, &mem, mid, cfg);
    ctx.add(&cpu);
    cpu.kickoff(ctx);
    ctx.run(10'000);
    check("regress[II>lat]: no lost-wakeup with LSQ core",
          cpu.halted() && cpu.arch_reg(1) == 5 && cpu.arch_reg(2) == 7);
  }
}

int main() {
  // 程序覆盖:①即时前递 ②独立 load 走内存 ③store 地址依赖长延迟 DIV -> load 必须等待再前递
  //          ④前递链 ⑤全部 store 落存到内存。
  const uint64_t B = 0x2000;
  Program prog;
  prog.push_back(alu(2, 0, 0, 1));       // 0: r2 = 1
  prog.push_back(alu(3, 1, 0, 7));       // 1: r3 = r1+7 = 0x2007 (data)
  prog.push_back(store(1, 3, 0));        // 2: M[0x2000] = r3
  prog.push_back(load(4, 1, 0));         // 3: r4 = M[0x2000]     -> 前递 r3
  prog.push_back(load(5, 1, 64));        // 4: r5 = M[0x2040]     -> 走内存(无 store)
  prog.push_back(alu(6, 1, 0, 128));     // 5: r6 = 0x2080 (store 地址,快)
  prog.push_back(divi(7, 6, 2));         // 6: r7 = r6/1 = 0x2080 (20 周期,使 store#7 地址晚知)
  prog.push_back(store(7, 3, 0));        // 7: M[r7] = r3         (地址依赖 DIV)
  prog.push_back(load(8, 1, 128));       // 8: r8 = M[0x2080]     -> 须等 store#7 地址再前递 r3
  prog.push_back(alu(9, 8, 0, 1));       // 9: r9 = r8 + 1
  prog.push_back(store(1, 9, 256));      // 10: M[0x2100] = r9
  prog.push_back(halt());

  std::vector<uint64_t> init(32, 0);
  init[1] = B;

  SimContext ctx;
  SimpleMemory mem;
  CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid, {});
  ctx.add(&cpu);
  for (int r = 0; r < 32; ++r) cpu.set_arch_reg(r, init[r]);
  cpu.kickoff(ctx);
  Cycle end = ctx.run(1'000'000);

  RefResult ref = ref_run_full(prog, init);

  std::printf("=== ACE-Sim V3 (LSQ) run summary ===\n");
  std::printf("  end cycle              : %llu\n", (unsigned long long)end);
  std::printf("  fetched/dispatched/issued/retired : %llu / %llu / %llu / %llu\n",
              (unsigned long long)cpu.fetched(), (unsigned long long)cpu.dispatched(),
              (unsigned long long)cpu.issued(), (unsigned long long)cpu.retired());
  std::printf("  store->load forwards   : %llu\n", (unsigned long long)cpu.forwards());
  std::printf("  loads via memory       : %llu\n", (unsigned long long)cpu.mem_loads());
  std::printf("  stores drained to mem  : %llu\n", (unsigned long long)cpu.stores_drained());

  // 寄存器对拍
  bool regs_ok = true;
  for (int r = 0; r < 32; ++r)
    if (cpu.arch_reg(r) != ref.regs[r]) {
      regs_ok = false;
      std::printf("  reg mismatch r%d: got %llu expected %llu\n", r,
                  (unsigned long long)cpu.arch_reg(r), (unsigned long long)ref.regs[r]);
    }
  // 内存对拍(所有被写地址)
  bool mem_ok = true;
  for (const auto& kv : ref.mem)
    if (mem.peek(kv.first) != kv.second) {
      mem_ok = false;
      std::printf("  mem mismatch @0x%llx: got %llu expected %llu\n",
                  (unsigned long long)kv.first, (unsigned long long)mem.peek(kv.first),
                  (unsigned long long)kv.second);
    }

  std::printf("\n=== V3 goals ===\n");
  check("functional correct: registers match ref model", regs_ok);
  check("functional correct: memory matches ref model (stores drained)", mem_ok);
  check("store->load forwarding happened (>=2)", cpu.forwards() >= 2);
  check("some loads still went to memory (independent addr)", cpu.mem_loads() >= 1);
  // 内存消歧:load#8(r8)必须等 store#7 地址解析后前递 r3=0x2007,不能提前读内存 data_at(0x2080)。
  check("memory disambiguation: load waited for unknown older store, then forwarded",
        cpu.arch_reg(8) == 0x2007 && cpu.arch_reg(8) != SimpleMemory::data_at(0x2080));
  check("store buffer drained all stores (==3)", cpu.stores_drained() == 3);
  check("halted cleanly after store buffer fence", cpu.halted());

  regressions();
  fuzz(20000);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
