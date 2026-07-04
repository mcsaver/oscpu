// ace-sim ② FP 数据通路 demo:FADD/FMUL/FDIV/FCVT/FCMP。统一 64-bit 物理寄存器堆承载 double 位型
// (f0..f31 = arch 32..63)。语义用 host double,与 FunctionalBackend 逐位同源 -> difftest 护栏。
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

static OooConfig fp_cfg() {
  OooConfig cfg;
  cfg.num_arch_regs = 64;    // x0..31 + f0..31
  cfg.num_phys_regs = 128;   // >= 64 + rob_size
  return cfg;
}

// 随机 FP+int+mem 程序对拍(host double 语义,连 nan/inf 位型也同源)。
static void fuzz(int iters) {
  uint64_t s = 0xf9a7c0de5ull;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t fp_ops = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(64, 0);
    init[1] = 0x1000; init[2] = 0x1040;                    // 地址
    for (int r = 3; r <= 10; ++r) init[r] = rnd(20);       // int
    for (int f = 0; f < 8; ++f) init[freg(f)] = fbits(double(int(rnd(20)) - 10) / 2.0);  // fp

    int len = 6 + static_cast<int>(rnd(20));
    Program prog;
    for (int i = 0; i < len; ++i) {
      int fi = static_cast<int>(rnd(8)), fj = static_cast<int>(rnd(8)), fk = static_cast<int>(rnd(8));
      int ii = 1 + static_cast<int>(rnd(10)), ij = 1 + static_cast<int>(rnd(10));
      switch (rnd(9)) {
        case 0: prog.push_back(fadd(freg(fk), freg(fi), freg(fj))); ++fp_ops; break;
        case 1: prog.push_back(fmul(freg(fk), freg(fi), freg(fj))); ++fp_ops; break;
        case 2: prog.push_back(fdivi(freg(fk), freg(fi), freg(fj))); ++fp_ops; break;
        case 3: prog.push_back(fcvt_i2f(freg(fk), ii)); ++fp_ops; break;
        case 4: prog.push_back(fcvt_f2i(ii, freg(fi))); ++fp_ops; break;
        case 5: prog.push_back(fcmp_lt(ii, freg(fi), freg(fj))); ++fp_ops; break;
        case 6: prog.push_back(load(ii, 1 + int(rnd(2)), rnd(2) * 8)); break;
        case 7: prog.push_back(store(1 + int(rnd(2)), ii, rnd(2) * 8)); break;
        default: prog.push_back(alu(ii, ij, ij, rnd(8))); break;
      }
    }
    prog.push_back(halt());

    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    CpuTop cpu(prog, &mem, mid, fp_cfg());
    ctx.add(&cpu);
    for (int r = 0; r < 64; ++r) cpu.set_arch_reg(r, init[r]);
    cpu.kickoff(ctx);
    ctx.run(500'000);

    RefResult ref = ref_run_full(prog, init);
    bool ok = cpu.halted();
    for (int r = 0; r < 64 && ok; ++r) ok = (cpu.arch_reg(r) == ref.regs[r]);
    for (const auto& kv : ref.mem) ok = ok && (mem.peek(kv.first) == kv.second);
    if (!ok) ++bad;
  }
  std::printf("\n=== FP differential fuzz ===\n");
  std::printf("  %d programs, %llu FP ops exercised\n", iters, (unsigned long long)fp_ops);
  check("fp-fuzz: all FP+int+mem programs match ref (regs+mem, bit-exact double)", bad == 0);
}

int main() {
  // f0=3.0, f1=4.0;算 f2=7, f3=28, f4=28/3, r5=(int)f4=9, r6=(3<4)=1, f7=(double)7
  Program prog;
  prog.push_back(fadd(freg(2), freg(0), freg(1)));   // f2 = 3+4
  prog.push_back(fmul(freg(3), freg(2), freg(1)));   // f3 = 7*4
  prog.push_back(fdivi(freg(4), freg(3), freg(0)));  // f4 = 28/3
  prog.push_back(fcvt_f2i(5, freg(4)));              // r5 = (int)f4
  prog.push_back(fcmp_lt(6, freg(0), freg(1)));      // r6 = f0<f1
  prog.push_back(fcvt_i2f(freg(7), 1));              // f7 = (double)r1
  prog.push_back(halt());

  std::vector<uint64_t> init(64, 0);
  init[freg(0)] = fbits(3.0);
  init[freg(1)] = fbits(4.0);
  init[1] = 7;

  SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid, fp_cfg());
  ctx.add(&cpu);
  for (int r = 0; r < 64; ++r) cpu.set_arch_reg(r, init[r]);
  cpu.kickoff(ctx);
  ctx.run(100'000);

  RefResult ref = ref_run_full(prog, init);

  std::printf("=== ACE-Sim FP data path ===\n");
  std::printf("  f2=%.3f  f3=%.3f  f4=%.4f  r5=%llu  r6=%llu  f7=%.3f\n",
              f64(cpu.arch_reg(freg(2))), f64(cpu.arch_reg(freg(3))), f64(cpu.arch_reg(freg(4))),
              (unsigned long long)cpu.arch_reg(5), (unsigned long long)cpu.arch_reg(6),
              f64(cpu.arch_reg(freg(7))));

  bool regs_ok = true;
  for (int r = 0; r < 64; ++r) if (cpu.arch_reg(r) != ref.regs[r]) regs_ok = false;

  std::printf("\n=== goals ===\n");
  check("FP results bit-exact vs functional golden", regs_ok && cpu.halted());
  check("FADD/FMUL correct", cpu.arch_reg(freg(2)) == fbits(7.0) && cpu.arch_reg(freg(3)) == fbits(28.0));
  check("FDIV + FCVT(f->i) correct", cpu.arch_reg(freg(4)) == fbits(28.0 / 3.0) && cpu.arch_reg(5) == 9);
  check("FCMP + FCVT(i->f) correct", cpu.arch_reg(6) == 1 && cpu.arch_reg(freg(7)) == fbits(7.0));

  fuzz(20000);

  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
