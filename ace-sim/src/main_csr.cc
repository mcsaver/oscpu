// ace-sim ③ CSR + trap/中断 demo:CSRW/CSRR + ECALL/MRET(同步精确 trap)+ 异步定时器中断。
//
// 展示 OoO 的招牌能力 —— **精确异常/中断在 commit 边界注入**:
//   · 系统 op(CSRW/CSRR/ECALL/MRET)dispatch 串行 + 效应在 commit 边界(不投机 CSR);
//   · ECALL 在 commit 拍精确 trap -> mtvec,MRET 返回 mepc;
//   · 异步中断在最老指令边界 squash 全体在飞指令、RAT 回滚到 RRAT(已提交映射)、跳 handler,
//     handler 返回后主程序从 mepc 无缝续跑(对主程序透明)。
// 同步路径用 FunctionalBackend 金标准 difftest;异步中断按架构结果(透明 + handler 恰跑一次)验证。
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

// ---- 同步精确 trap:ECALL -> handler -> MRET,difftest vs 功能金标准 ----
static void demo_trap() {
  Program prog;
  prog.push_back(csrw(CSR_MTVEC, 5));       // 0: 设 trap 向量 = pc5(handler)
  prog.push_back(alu(1, 0, 0, 10));         // 1: r1 = 10
  prog.push_back(ecall());                  // 2: 精确 trap -> mepc=3, mcause=8, pc=5
  prog.push_back(alu(2, 1, 0, 1));          // 3: r2 = r1 + 1 = 11(MRET 返回后执行)
  prog.push_back(halt());                   // 4:
  prog.push_back(csrr(5, CSR_MCAUSE));      // 5: (handler) r5 = mcause = 8
  prog.push_back(alu(6, 5, 0, 100));        // 6: r6 = r5 + 100 = 108
  prog.push_back(mret());                   // 7: 返回 -> mepc = 3

  std::vector<uint64_t> init(32, 0);
  SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
  CpuTop cpu(prog, &mem, mid);
  ctx.add(&cpu);
  cpu.kickoff(ctx);
  ctx.run(100'000);

  RefResult ref = ref_run_full(prog, init);
  bool regs_ok = cpu.halted();
  for (int r = 0; r < 32 && regs_ok; ++r) regs_ok = (cpu.arch_reg(r) == ref.regs[r]);

  std::printf("=== ACE-Sim CSR + trap (ECALL/MRET) ===\n");
  std::printf("  r1=%llu r2=%llu r5(mcause)=%llu r6=%llu  traps=%llu\n",
              (unsigned long long)cpu.arch_reg(1), (unsigned long long)cpu.arch_reg(2),
              (unsigned long long)cpu.arch_reg(5), (unsigned long long)cpu.arch_reg(6),
              (unsigned long long)cpu.traps());
  check("ECALL->handler->MRET 控制流精确,regs bit-exact vs golden", regs_ok);
  check("r1=10 r2=11(MRET 后续跑) r5=mcause=8 r6=108",
        cpu.arch_reg(1) == 10 && cpu.arch_reg(2) == 11 &&
        cpu.arch_reg(5) == CAUSE_ECALL && cpu.arch_reg(6) == 108);
  check("恰一次精确 trap 在 commit 边界", cpu.traps() == 1);
}

// ---- 异步定时器中断:透明性 + handler 恰跑一次(按架构结果验证)----
static void demo_interrupt() {
  const uint64_t counter = 0x2000;  // handler 自增的内存计数器
  const int chain = 40;             // 主程序:依赖 ALU 链(足够长,中断落在执行中段)

  Program prog;
  for (int i = 0; i < chain; ++i) prog.push_back(alu(1, 1, 0, 1));  // r1 += 1(×chain)
  prog.push_back(halt());
  int handler_pc = static_cast<int>(prog.size());
  prog.push_back(load(20, 9, 0));       // H0: r20 = mem[r9]   (r9=counter 地址)
  prog.push_back(alu(20, 20, 0, 1));    // H1: r20 += 1
  prog.push_back(store(9, 20, 0));      // H2: mem[r9] = r20
  prog.push_back(mret());               // H3: 返回 mepc

  auto build = [&](bool with_irq, uint64_t& r1_out, uint64_t& cnt_out, uint64_t& irqs_out) {
    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    mem.write(counter, 0);              // 计数器初值 0
    CpuTop cpu(prog, &mem, mid);
    CompId cid = ctx.add(&cpu);
    cpu.set_arch_reg(9, counter);       // r9 = counter 地址(handler 用)
    cpu.set_csr(CSR_MTVEC, handler_pc); // 预置 trap 向量
    cpu.kickoff(ctx);
    if (with_irq) {                     // 在执行中段注入一次定时器中断
      Event ev; ev.when = 12; ev.target = cid; ev.kind = EventKind::TimerInterrupt;
      ctx.schedule(ev);
    }
    ctx.run(100'000);
    r1_out = cpu.arch_reg(1);
    cnt_out = mem.peek(counter);
    irqs_out = cpu.irqs();
  };

  uint64_t base_r1, base_cnt, base_irq, int_r1, int_cnt, int_irq;
  build(false, base_r1, base_cnt, base_irq);
  build(true,  int_r1,  int_cnt,  int_irq);

  std::printf("\n=== ACE-Sim 异步精确中断 ===\n");
  std::printf("  baseline: r1=%llu counter=%llu irqs=%llu\n",
              (unsigned long long)base_r1, (unsigned long long)base_cnt, (unsigned long long)base_irq);
  std::printf("  w/ IRQ:   r1=%llu counter=%llu irqs=%llu\n",
              (unsigned long long)int_r1, (unsigned long long)int_cnt, (unsigned long long)int_irq);
  check("中断对主程序透明:r1 与无中断基线一致", int_r1 == base_r1 && base_r1 == (uint64_t)chain);
  check("handler 恰执行一次(counter 0->1)", int_cnt == 1 && base_cnt == 0);
  check("恰服务一次异步中断", int_irq == 1 && base_irq == 0);
}

// ---- 中断压力:在每个周期注入一次中断,验证"透明性不变量"(RRAT 回滚 + squash-all +
//      已提交 store 保留 都正确的充要证据)。主程序含寄存器重命名压力 + store,handler 只碰 scratch。 ----
static void demo_interrupt_stress() {
  const uint64_t counter = 0x3000, xaddr = 0x3100;
  std::vector<uint64_t> init(32, 0);
  init[8] = xaddr;                       // store 目标地址
  init[9] = counter;                     // handler 计数器地址
  init[1] = 100;

  Program prog;                          // 主程序:WAW/WAR 重命名压力 + store/load 往返
  prog.push_back(store(8, 1, 0));        // mem[X] = r1(=100),早提交
  prog.push_back(alu(2, 1, 0, 7));       // r2 = r1 + 7
  prog.push_back(alu(1, 2, 0, 3));       // r1 = r2 + 3   (WAW r1)
  prog.push_back(alu(3, 1, 2, 0));       // r3 = r1 + r2
  prog.push_back(alu(2, 3, 0, 1));       // r2 = r3 + 1   (WAW r2)
  prog.push_back(mul(4, 2, 3));          // r4 = r2 * r3  (多周期,拉长 in-flight 窗口)
  prog.push_back(alu(5, 4, 1, 0));       // r5 = r4 + r1
  prog.push_back(load(6, 8, 0));         // r6 = mem[X]   (=100,测已提交 store 保留)
  prog.push_back(alu(7, 6, 5, 0));       // r7 = r6 + r5
  prog.push_back(halt());
  int handler_pc = static_cast<int>(prog.size());
  prog.push_back(load(20, 9, 0));        // handler:counter += 1(仅碰 r20 + counter)
  prog.push_back(alu(20, 20, 0, 1));
  prog.push_back(store(9, 20, 0));
  prog.push_back(mret());

  auto run_at = [&](int irq_cycle, uint64_t r[8], uint64_t& memx, uint64_t& cnt, uint64_t& irqs) {
    SimContext ctx; SimpleMemory mem; CompId mid = ctx.add(&mem);
    mem.write(counter, 0);
    CpuTop cpu(prog, &mem, mid);
    CompId cid = ctx.add(&cpu);
    for (int rr = 0; rr < 32; ++rr) cpu.set_arch_reg(rr, init[rr]);
    cpu.set_csr(CSR_MTVEC, handler_pc);
    cpu.kickoff(ctx);
    if (irq_cycle >= 0) {
      Event ev; ev.when = (Cycle)irq_cycle; ev.target = cid; ev.kind = EventKind::TimerInterrupt;
      ctx.schedule(ev);
    }
    ctx.run(100'000);
    for (int rr = 0; rr < 8; ++rr) r[rr] = cpu.arch_reg(rr + 1);  // r1..r8... 取 r1..r8? 取 r1..r7 关键
    memx = mem.peek(xaddr);
    cnt = mem.peek(counter);
    irqs = cpu.irqs();
  };

  uint64_t base_r[8], base_memx, base_cnt, base_irq;
  run_at(-1, base_r, base_memx, base_cnt, base_irq);  // 无中断基线

  int violations = 0, taken = 0;
  for (int t = 1; t <= 80; ++t) {
    uint64_t r[8], memx, cnt, irqs;
    run_at(t, r, memx, cnt, irqs);
    bool transparent = true;
    for (int k = 0; k < 7; ++k) transparent = transparent && (r[k] == base_r[k]);  // r1..r7 透明
    transparent = transparent && (memx == base_memx);           // 已提交 store 未丢
    transparent = transparent && (cnt == irqs);                  // handler 跑 irqs 次
    if (irqs > 0) ++taken;
    if (!transparent) { ++violations; if (violations <= 3)
      std::printf("    [t=%d] r1=%llu(base %llu) memX=%llu(base %llu) cnt=%llu irqs=%llu\n",
        t, (unsigned long long)r[0], (unsigned long long)base_r[0],
        (unsigned long long)memx, (unsigned long long)base_memx,
        (unsigned long long)cnt, (unsigned long long)irqs); }
  }

  std::printf("\n=== 异步中断压力(注入周期 1..80)===\n");
  std::printf("  基线 r1..r7 = %llu %llu %llu %llu %llu %llu %llu, mem[X]=%llu; 命中中断 %d/80\n",
              (unsigned long long)base_r[0], (unsigned long long)base_r[1], (unsigned long long)base_r[2],
              (unsigned long long)base_r[3], (unsigned long long)base_r[4], (unsigned long long)base_r[5],
              (unsigned long long)base_r[6], (unsigned long long)base_memx, taken);
  check("每个注入周期:主程序架构态与基线一致(RRAT 回滚/squash-all/已提交 store 保留 全部正确)",
        violations == 0);
  check("确有中断在执行中段被命中(非全部落在 halt 后)", taken > 0);
}

// ---- 差分模糊:随机 CSRW/CSRR + ECALL/MRET + int + mem,对拍功能金标准 ----
static void fuzz(int iters) {
  uint64_t s = 0xc5720de1full;
  auto rnd = [&](uint64_t n) {
    s = s * 6364136223846793005ull + 1442695040888963407ull;
    return static_cast<uint64_t>((s >> 33) % n);
  };
  int bad = 0;
  uint64_t sys_ops = 0, ecalls = 0;
  for (int it = 0; it < iters; ++it) {
    std::vector<uint64_t> init(32, 0);
    init[1] = 0x1000; init[2] = 0x1040;
    for (int r = 3; r <= 12; ++r) init[r] = rnd(50);

    int len = 6 + static_cast<int>(rnd(16));
    Program prog;
    prog.push_back(csrw(CSR_MTVEC, 0));  // 占位,handler_pc 待定,稍后回填
    for (int i = 0; i < len; ++i) {
      int a = 3 + static_cast<int>(rnd(10)), b = 3 + static_cast<int>(rnd(10)), d = 3 + static_cast<int>(rnd(10));
      switch (rnd(10)) {
        case 0: prog.push_back(csrw(3 + int(rnd(5)), rnd(1000))); ++sys_ops; break;  // 写通用 CSR(避开 mtvec/mepc/mcause)
        case 1: prog.push_back(csrr(d, int(rnd(CSR_COUNT)))); ++sys_ops; break;       // 读任意 CSR
        case 2: prog.push_back(ecall()); ++sys_ops; ++ecalls; break;                  // 精确 trap
        case 3: prog.push_back(load(d, 1 + int(rnd(2)), rnd(2) * 8)); break;
        case 4: prog.push_back(store(1 + int(rnd(2)), a, rnd(2) * 8)); break;
        default: prog.push_back(alu(d, a, b, rnd(16))); break;
      }
    }
    prog.push_back(halt());
    int handler_pc = static_cast<int>(prog.size());
    prog[0] = csrw(CSR_MTVEC, handler_pc);         // 回填真实 handler 入口
    prog.push_back(csrr(28, CSR_MCAUSE));          // handler:读 cause
    prog.push_back(alu(29, 28, 3, 7));             // 少量计算
    prog.push_back(mret());                        // 返回 mepc(=ecall+1)

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
  }
  std::printf("\n=== CSR/trap differential fuzz ===\n");
  std::printf("  %d programs, %llu 系统 op(其中 %llu ECALL)exercised\n",
              iters, (unsigned long long)sys_ops, (unsigned long long)ecalls);
  check("csr-fuzz: 所有 CSRW/CSRR/ECALL/MRET+int+mem 程序对拍金标准(regs+mem)", bad == 0);
}

int main() {
  demo_trap();
  demo_interrupt();
  demo_interrupt_stress();
  fuzz(20000);
  std::printf("\n%s (%d failing checks)\n", g_fail == 0 ? "ALL PASS" : "SOME FAILED", g_fail);
  return g_fail == 0 ? 0 : 1;
}
