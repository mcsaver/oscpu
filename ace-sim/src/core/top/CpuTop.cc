#include "core/top/CpuTop.hh"
#include <algorithm>
#include <cassert>
#include "mem/mmu.hh"
#include "sim/context.hh"

namespace ace {

CpuTop::CpuTop(Program prog, MemPort* mem, CompId mem_id, OooConfig cfg)
    : prog_(std::move(prog)),
      mem_(mem),
      mem_id_(mem_id),
      cfg_(cfg),
      pregs_(cfg.num_phys_regs, cfg.num_arch_regs),
      rename_(cfg.num_arch_regs),
      rrat_(cfg.num_arch_regs),
      freelist_(cfg.num_phys_regs, cfg.num_arch_regs),
      bpu_(cfg.bht_size, cfg.ghist_bits),
      ras_(cfg.ras_depth),
      fetch_(prog_, bpu_, ras_, cfg.fetch_queue_cap, cfg.fetch_width, cfg.start_pc),
      rob_(cfg.rob_size),
      iq_(cfg.iq_size, cfg.num_phys_regs),
      sq_(cfg.sq_size),
      alu_(cfg.alu),
      muldiv_(cfg.mul, cfg.div),
      fpalu_(cfg.fp, cfg.fdiv_lat),
      tlb_(cfg.tlb_sets, cfg.tlb_ways),
      ldu_(tlb_, cfg.mmu_on) {
  // 存活下界:至少要有 1 个可周转的物理寄存器,否则首条写指令就永久停顿(静默死锁)。
  // 性能下界(永不因 rename 停顿):num_phys_regs >= num_arch_regs + rob_size。fail-fast 优于静默挂死。
  assert(cfg.num_phys_regs > cfg.num_arch_regs &&
         "num_phys_regs must exceed num_arch_regs (liveness floor)");
  assert(cfg.rob_size > 0 && cfg.iq_size > 0 && cfg.sq_size > 0 &&
         cfg.drain_width > 0 && "zero-size queues / drain_width livelock");
  // 各模块(pregs_/rename_/freelist_/rob_/iq_/sq_)由其构造函数建立初态。
}

void CpuTop::kickoff(SimContext& ctx) { ctx.activate(id, Phase::Eval); }
void CpuTop::set_arch_reg(int r, uint64_t v) { pregs_.write(rename_.phys(r), v); }

bool CpuTop::eval(Phase phase, SimContext& ctx) {
  switch (phase) {
    case Phase::Wakeup: return on_wakeup(ctx);
    case Phase::Eval:   return on_eval(ctx);
    case Phase::Retire: return on_retire(ctx);
    default:            return false;
  }
}

// ---- Wakeup:完成事件写物理寄存器 + 唤醒依赖者 + 标 ROB done(completion,非 commit)----
bool CpuTop::on_wakeup(SimContext& ctx) {
  bool matched = false, wake_eval = false, saw_stale = false, irq = false;
  for (const Event& ev : inbox) {
    if (ev.kind == EventKind::CpuWake) { wake_eval = true; continue; }
    if (ev.kind == EventKind::TimerInterrupt) { pending_irq_ = true; irq = true; continue; }
    int rob_idx = static_cast<int>(ev.payload2);
    Rob::Entry& r = rob_.at(rob_idx);
    // 惰性取消(不变量 #8):以**全局唯一且单调**的 dyn_id 作为每指令标签。
    // squash 使更年轻指令的 ROB 槽被置无效或被新指令复用(dyn_id 不同),其陈旧完成事件在此丢弃;
    // 而更老正确路径指令的槽仍有效、dyn_id 匹配,照常应用 —— 无需删除 wheel 中的事件(O(1))。
    // (注:全局 fetch-epoch 无法区分"更老正确"与"更年轻错误",二者同代,故不能用 epoch 判死。)
    if (!r.valid || r.dyn_id != ev.payload0) { saw_stale = true; continue; }
    if (r.is_branch) {  // 分支:解析方向,误判则 squash(payload1 = 实际 taken)
      r.done = true;
      resolve_branch(rob_idx, ev.payload1 != 0, ctx);
      matched = true;
      continue;
    }
    if (r.is_jalr) {  // 间接跳转/返回:解析目标,误判则 squash(payload1 = 实际目标;rd 已在 dispatch 写)
      r.done = true;
      resolve_jalr(rob_idx, ev.payload1, ctx);
      matched = true;
      continue;
    }
    if (r.phys_dst >= 0) {
      pregs_.write(r.phys_dst, ev.payload1);
      iq_.wakeup(r.phys_dst);
    }
    r.done = true;
    completion_order_.push_back(ev.payload0);
    matched = true;
  }
  inbox.clear();
  if (matched || irq) ctx.activate(id, Phase::Retire);  // 队头可退休 / 中断在 Retire 边界注入
  // 任何事件投递(含被惰性丢弃的陈旧事件)都可能意味着外部状态变化,必须重评发射:
  // 睡眠安全律推论(V4 审查)—— 端口满停顿的 backing 是"in-flight load 响应",若这些 load 已被
  // squash,其陈旧响应被丢弃却不重激活 Eval,会漏唤醒端口停顿的存活 load(端口已随 pop 释放)。
  if (matched || wake_eval || saw_stale || irq) ctx.activate(id, Phase::Eval);
  return matched || wake_eval || saw_stale || irq;
}

// 解析分支:比较实际方向/目标 vs 预测。误判 -> 更新预测器 + squash 更年轻指令 + 重定向取指。
void CpuTop::resolve_branch(int rob_idx, bool actual_taken, SimContext& ctx) {
  Rob::Entry& r = rob_.at(rob_idx);
  ++branches_;
  bpu_.update(r.pc, actual_taken);
  BranchResolve::Result br = brres_.resolve(r.pc, r.br_target, r.pred_next_pc, actual_taken);
  if (br.mispredict) {
    ++mispredicts_;
    squash_after(rob_idx, br.redirect_pc, ctx);
  }
}

// 解析 JALR:实际目标(reg[rs]+imm)vs fetch 的 RAS/间接预测。误判 -> squash + 重定向到实际目标。
// rd(链接)已在 dispatch 写,故此处不写寄存器,仅做控制流解析(与分支同构)。
void CpuTop::resolve_jalr(int rob_idx, uint64_t actual_target, SimContext& ctx) {
  Rob::Entry& r = rob_.at(rob_idx);
  ++jalrs_;
  if (actual_target != r.pred_next_pc) {
    ++jalr_mispredicts_;
    ++mispredicts_;
    squash_after(rob_idx, actual_target, ctx);
  }
}

// squash:回收更年轻指令(ROB/IQ/SQ),回滚 RAT 到分支快照,重定向取指。
// 惰性取消不需在此做任何标记:错误路径指令的 ROB 槽被置无效/复用后,dyn_id 不再匹配,
// 其陈旧完成事件在 on_wakeup 自然被丢弃(见 on_wakeup 守卫)。
void CpuTop::squash_after(int branch_rob_idx, uint64_t redirect_pc, SimContext& ctx) {
  ++squashes_;

  uint64_t branch_dyn = rob_.at(branch_rob_idx).dyn_id;
  std::vector<int> ckpt = rob_.at(branch_rob_idx).rat_ckpt;  // squash 前抓分支快照(其条目存活)

  // 回收更年轻 ROB 条目(归还其错误路径物理寄存器),截断到分支
  rob_.squash(branch_rob_idx, freelist_);

  // RAT 回滚到分支快照(错误路径的重命名全部撤销)
  rename_.restore(ckpt);

  // 回收更年轻的 IQ 条目 + 从存活条目重建就绪/等待表
  iq_.squash(branch_dyn, pregs_);

  // 丢弃更年轻的(未提交)store
  sq_.squash(branch_dyn);

  // 清空取指队列(错误路径已取但未分派),重定向 PC
  fetch_.redirect(redirect_pc);

  ctx.activate(id, Phase::Eval);  // 从正确路径重新取指/发射
}

// 精确异步中断(③):在最老指令边界注入。squash 全部在飞指令(它们尚未提交,
// 不影响架构状态),把 RAT 回滚到已提交映射 RRAT,保存 mepc,跳 mtvec。
// 已提交但未落存的 store 保留(squash_uncommitted)。返回后从 mepc 续跑,中断对主程序透明。
void CpuTop::take_interrupt(SimContext& ctx) {
  uint64_t mepc;
  if (!rob_.empty())        mepc = rob_.head().pc;   // 最老在飞指令
  else if (fetch_.can_pop()) mepc = fetch_.front().pc; // 最老已取未分派
  else                      mepc = fetch_.pc();       // 下一取指

  uint64_t tgt = csr_.trap(mepc, CAUSE_TIMER_IRQ);
  rob_.squash_all(freelist_);          // 清所有在飞条目 + 归还 phys_dst
  rename_.restore(rrat_.snapshot());   // RAT 回滚到已提交映射(与分支 squash 同构,checkpoint=RRAT)
  iq_.squash(0, pregs_);               // 清空 IQ(全部 dyn_id>0)
  sq_.squash_uncommitted();            // 只丢未提交 store,已提交保留落存
  fetch_.redirect(tgt);                // 跳 handler
  system_stall_ = false;
  pending_irq_ = false;
  ++irqs_;
  ++squashes_;
  ctx.activate(id, Phase::Eval);
}

// ---- Eval:乱序发射 -> 重命名/分派 -> 取指(back-to-front,同周期复用释放的资源)----
bool CpuTop::on_eval(SimContext& ctx) {
  structural_wake_ = kInvalidCycle;
  bool a = select_issue(ctx);
  bool b = rename_dispatch(ctx);
  bool c = fetch_.step();
  if (a || b || c) {
    ctx.activate(id, Phase::Eval);
  } else if (structural_wake_ != kInvalidCycle) {
    Event e;
    e.when = structural_wake_;
    e.target = id;
    e.kind = EventKind::CpuWake;
    ctx.schedule(e);  // 结构冒险独占停顿:自唤醒兜底(DESIGN.md §5.1)
  }
  return a || b || c;
}

// 顺序重命名/分派:fetch 队列头 -> 分配物理寄存器 + ROB 项 + IQ 项(+分支 RAT 快照)。
bool CpuTop::rename_dispatch(SimContext& ctx) {
  bool progressed = false;
  for (uint32_t i = 0; i < cfg_.dispatch_width; ++i) {
    if (system_stall_) break;  // 系统 op 在飞 -> dispatch 串行,待其 commit(③)
    if (!fetch_.can_pop()) break;
    if (rob_.full()) break;  // ROB 满(backpressure)
    const Fetch::Item fi = fetch_.front();
    const Inst& in = fi.inst;
    const Decoded dec = Decode::decode(in);   // 译码分类(⑥)
    const bool is_halt = dec.is_halt, is_store = dec.is_store, is_branch = dec.is_branch;
    const bool is_jump = dec.is_jump, is_jal = dec.is_jal, is_jalr = dec.is_jalr, is_sys = dec.is_sys;
    const bool needs_dst = dec.needs_dst;
    // store 裂 STA+STD 需 2 个 IQ 槽;其它 needs_iq 需 1 个(⑥)
    const size_t iq_need = is_store ? 2 : (dec.needs_iq ? 1 : 0);
    if (iq_need > iq_.free_count()) break;            // IQ 槽不足
    if (needs_dst && freelist_.empty()) break;       // 无空闲物理寄存器
    if (is_store && sq_.full()) break; // SQ 满(backpressure)

    int rob_idx = rob_.alloc();  // 分配 ROB 项(内部 ++count)
    Rob::Entry& r = rob_.at(rob_idx);
    r = Rob::Entry{};
    r.dyn_id = next_id_++;
    r.valid = true;
    r.is_store = is_store;
    r.fu = in.fu;
    r.pc = fi.pc;  // 每条都记 PC(精确中断保存 mepc 用,③)

    if (is_halt) {
      r.is_halt = true;
      r.done = true;
      fetch_.pop();
      ++dispatched_;
      progressed = true;
      ctx.activate(id, Phase::Retire);
      break;  // HALT 之后不再分派
    }
    if (is_jump) {  // 无条件跳转:取指已跟随,dispatch 即完成(不会误判)
      r.done = true;
      fetch_.pop();
      ++dispatched_;
      progressed = true;
      ctx.activate(id, Phase::Retire);
      continue;
    }
    if (is_jal) {  // 直接调用:目标已知(fetch 已重定向),写链接 rd=pc+1,dispatch 即 done(⑤)
      if (in.dst >= 0) {
        int np = freelist_.alloc();
        int op = rename_.remap(in.dst, np);
        pregs_.write(np, fi.pc + 1);   // 链接值已知,立即就绪
        iq_.wakeup(np);                // 唤醒依赖 rd 的指令
        r.arch_dst = in.dst; r.phys_dst = np; r.old_phys = op;
      }
      if (is_call(in)) ++calls_;
      r.done = true;
      fetch_.pop();
      ++dispatched_;
      progressed = true;
      ctx.activate(id, Phase::Retire);
      continue;
    }
    if (is_jalr) {  // 间接跳转/返回:目标 execute 才知(reg[rs]+imm),预测在 fetch;resolve 同分支(⑤)
      if (in.dst >= 0) {  // 链接 rd=pc+1(已知,立即就绪)
        int np = freelist_.alloc();
        int op = rename_.remap(in.dst, np);
        pregs_.write(np, fi.pc + 1);
        iq_.wakeup(np);
        r.arch_dst = in.dst; r.phys_dst = np; r.old_phys = op;
      }
      r.is_jalr = true;
      r.pc = fi.pc;
      r.pred_next_pc = fi.pred_next_pc;   // fetch 的 RAS/间接预测
      r.rat_ckpt = rename_.snapshot();    // 误判回滚点(rd 已重命名 -> 快照含 rd)
      int p0 = in.src0 >= 0 ? rename_.phys(in.src0) : -1;
      iq_.insert(r.dyn_id, in.fu, p0, -1,
                 (p0 < 0) || pregs_.ready(p0), true, -1, rob_idx, in.imm, in.cond);
      fetch_.pop();
      ++dispatched_;
      progressed = true;
      continue;
    }
    if (is_sys) {  // 系统/CSR:效应在 commit;串行(其 commit 前不再 dispatch)
      r.done = true;
      r.csr_idx = in.cond;
      r.sys_imm = in.imm;
      r.pc = fi.pc;  // ECALL 的 epc 用
      if (needs_dst) {  // CSRR:分配 rd 的 phys(commit 拍写)
        int np = freelist_.alloc();
        int op = rename_.remap(in.dst, np);
        pregs_.set_unready(np);
        r.arch_dst = in.dst;
        r.phys_dst = np;
        r.old_phys = op;
      }
      system_stall_ = true;
      fetch_.pop();
      ++dispatched_;
      progressed = true;
      ctx.activate(id, Phase::Retire);
      break;  // 停 dispatch,待 commit 清 stall
    }

    // 重命名源:读当前 RAT
    int p0 = in.src0 >= 0 ? rename_.phys(in.src0) : -1;
    int p1 = in.src1 >= 0 ? rename_.phys(in.src1) : -1;
    // 重命名目的:分配新物理寄存器,旧映射留待 commit 释放
    int new_phys = -1, old_phys = -1;
    if (needs_dst) {
      new_phys = freelist_.alloc();
      old_phys = rename_.remap(in.dst, new_phys);
      pregs_.set_unready(new_phys);
    }
    r.arch_dst = needs_dst ? in.dst : -1;
    r.phys_dst = new_phys;
    r.old_phys = old_phys;

    if (is_branch) {  // 快照 RAT(误判回滚点);记录预测元数据
      r.is_branch = true;
      r.pc = fi.pc;
      r.br_target = fi.target;
      r.pred_taken = fi.pred_taken;
      r.pred_next_pc = fi.pred_next_pc;
      r.rat_ckpt = rename_.snapshot();  // 分支后的 RAT(分支无 dst,故 = 分支前)
    }

    if (is_store) {  // 程序序进 SQ,并裂成 STA(等 base=src0)+ STD(等 data=src1)两个微 op(⑥)
      sq_.alloc(r.dyn_id, rob_idx);
      iq_.insert(r.dyn_id, FuType::STA, p0, -1,
                 (p0 < 0) || pregs_.ready(p0), true, -1, rob_idx, in.imm, in.cond);
      iq_.insert(r.dyn_id, FuType::STD, -1, p1,
                 true, (p1 < 0) || pregs_.ready(p1), -1, rob_idx, in.imm, in.cond);
    } else {
      iq_.insert(r.dyn_id, in.fu, p0, p1,
                 (p0 < 0) || pregs_.ready(p0), (p1 < 0) || pregs_.ready(p1),
                 new_phys, rob_idx, in.imm, in.cond);
    }
    fetch_.pop();
    ++dispatched_;
    progressed = true;
  }
  return progressed;
}

// 乱序选择发射:
//  - ALU/MUL/DIV/STORE 类用 front-FIFO(FU 结构冒险 break 由 CpuWake 兜底;STORE 恒可执行);
//  - LOAD 类用 index 遍历并**跳过**(不 break!)消歧等待/端口满的 load。
//    若整类 break:一个等待的 younger load 会 head-of-line 堵住其后、恰好能解析该等待所依赖
//    store 地址的 older load,形成 load->store->load 环死锁,且无 backing 事件唤醒 —— V3 审查
//    确认的 critical 缺陷。跳过后 older load 可越过 waiter 发射,打破环。
bool CpuTop::select_issue(SimContext& ctx) {
  bool progressed = false;
  uint32_t budget = cfg_.issue_width;

  // ---- ALU / MUL / DIV / STORE:front-FIFO ----
  for (int cls = 0; cls <= 3 && budget > 0; ++cls) {
    std::vector<int>& rl = iq_.ready_list(cls);
    while (!rl.empty() && budget > 0) {
      int slot = rl.front();
      IssueQueue::Entry& e = iq_.at(slot);
      if (cls <= 2) {  // cls0=ALU/BRANCH(Alu FU),cls1=MUL,cls2=DIV(MulDiv FU)
        bool ok; Cycle nf;
        if (cls == 0) { ok = alu_.can_issue(ctx.cur_cycle); nf = alu_.next_free(); }
        else          { ok = muldiv_.can_issue(cls == 2, ctx.cur_cycle); nf = muldiv_.next_free(cls == 2); }
        if (!ok) {  // 结构冒险:记录 FU 释放周期用于自唤醒
          if (nf > ctx.cur_cycle && nf < structural_wake_) structural_wake_ = nf;
          break;
        }
        uint64_t a = e.src0 >= 0 ? pregs_.value(e.src0) : 0;
        uint64_t b = e.src1 >= 0 ? pregs_.value(e.src1) : 0;
        uint64_t res;
        uint32_t lat;
        if (cls == 0) {  // ALU / BRANCH / JALR
          alu_.reserve(ctx.cur_cycle);
          lat = alu_.latency();
          if (e.fu == FuType::BRANCH)    res = alu_.taken(e.cond, a, b) ? 1u : 0u;
          else if (e.fu == FuType::JALR) res = a + e.imm;          // 间接目标 = reg[rs] + imm(⑤)
          else                           res = alu_.compute(a, b, e.imm);
        } else {  // MUL / DIV
          bool is_div = (cls == 2);
          muldiv_.reserve(is_div, ctx.cur_cycle);
          lat = muldiv_.latency(is_div);
          res = muldiv_.compute(is_div, a, b);
        }
        Event ev;
        ev.when = ctx.cur_cycle + lat;
        ev.target = id;
        ev.kind = EventKind::FuComplete;
        ev.payload0 = e.dyn_id;
        ev.payload1 = res;
        ev.payload2 = static_cast<uint64_t>(e.rob_idx);
        ctx.schedule(ev);
      } else {  // cls == 3, STA/STD:各自回填地址/数据;两者俱全才标 ROB done(⑥)
        bool both;
        if (e.fu == FuType::STA) {  // store 地址:算地址 + 翻译,回填 SQ(解锁等地址的 load)
          uint64_t vaddr = (e.src0 >= 0 ? pregs_.value(e.src0) : 0) + e.imm;
          if (cfg_.mmu_on) tlb_.access(vpn_of(vaddr));   // 翻译(SQ 存物理地址,④)
          both = sq_.execute_addr(e.dyn_id, mmu_translate(vaddr, cfg_.mmu_on));
        } else {                    // STD:store 数据
          uint64_t data = (e.src1 >= 0 ? pregs_.value(e.src1) : 0);
          both = sq_.execute_data(e.dyn_id, data);
        }
        if (both) rob_.at(e.rob_idx).done = true;  // 地址+数据俱全 -> store 可提交
        ctx.activate(id, Phase::Retire);
      }
      iq_.free_slot(slot);
      rl.erase(rl.begin());
      ++issued_;
      --budget;
      progressed = true;
    }
  }

  // ---- FP(cls 5):front-FIFO;结构冒险 break 由 CpuWake 兜底(② FP 数据通路)----
  {
    std::vector<int>& rl = iq_.ready_list(5);
    while (!rl.empty() && budget > 0) {
      int slot = rl.front();
      IssueQueue::Entry& e = iq_.at(slot);
      if (!fpalu_.can_issue(ctx.cur_cycle)) {
        Cycle f = fpalu_.next_free();
        if (f > ctx.cur_cycle && f < structural_wake_) structural_wake_ = f;
        break;
      }
      fpalu_.reserve(ctx.cur_cycle);
      uint64_t a = e.src0 >= 0 ? pregs_.value(e.src0) : 0;
      uint64_t b = e.src1 >= 0 ? pregs_.value(e.src1) : 0;
      uint64_t res = fpalu_.compute(e.fu, a, b);
      Event ev;
      ev.when = ctx.cur_cycle + fpalu_.latency(e.fu);
      ev.target = id;
      ev.kind = EventKind::FuComplete;
      ev.payload0 = e.dyn_id;
      ev.payload1 = res;
      ev.payload2 = static_cast<uint64_t>(e.rob_idx);
      ctx.schedule(ev);
      iq_.free_slot(slot);
      rl.erase(rl.begin());
      ++issued_;
      --budget;
      progressed = true;
    }
  }

  // ---- LOAD:index 遍历,跳过不可发射者(避免 head-of-line 死锁)----
  std::vector<int>& lrl = iq_.ready_list(4);
  size_t k = 0;
  while (k < lrl.size() && budget > 0) {
    int slot = lrl[k];
    IssueQueue::Entry& e = iq_.at(slot);
    uint64_t vaddr = ldu_.vaddr(e.src0 >= 0 ? pregs_.value(e.src0) : 0, e.imm);  // AGU(⑥)
    uint64_t paddr = ldu_.paddr(vaddr);  // 翻译(消歧/访存都用物理地址,④)
    bool wait = false, fwd = false;
    uint64_t fwd_data = 0;
    sq_.disambiguate(e.dyn_id, paddr, wait, fwd, fwd_data);
    if (wait) { ++k; continue; }  // 更老 store 地址未知:跳过(store execute 进展会重激活 Eval 兜底)
    if (fwd) {                     // store->load 前递:免访存,单拍完成
      Event ev;
      ev.when = ctx.cur_cycle + cfg_.fwd_latency;
      ev.target = id;
      ev.kind = EventKind::FuComplete;
      ev.payload0 = e.dyn_id;
      ev.payload1 = fwd_data;
      ev.payload2 = static_cast<uint64_t>(e.rob_idx);
      ctx.schedule(ev);
      ++forwards_;
    } else {                       // 走内存(含已落存的更老 store)
      if (!mem_->can_send()) { ++k; continue; }  // 端口满:跳过(load 响应事件兜底)
      uint32_t walk = ldu_.walk_latency(vaddr, cfg_.tlb_walk_lat);  // TLB miss -> 页表 walk 额外延迟(④/⑥)
      MemReq req;
      req.dyn_id = e.dyn_id;
      req.addr = paddr;
      req.requester = id;
      req.tag = static_cast<uint32_t>(e.rob_idx);
      req.extra_latency = walk;
      mem_->send(req);
      ctx.activate(mem_id_, Phase::Eval);
      ++mem_loads_;
    }
    iq_.free_slot(slot);
    lrl.erase(lrl.begin() + k);  // 发射者删除(k 不前进,后续元素前移到 k)
    ++issued_;
    --budget;
    progressed = true;
  }
  return progressed;
}

// ---- Retire:ROB 队头 done 才按序退休;此处释放旧物理寄存器 = 架构状态提交边界 ----
bool CpuTop::on_retire(SimContext& ctx) {
  bool progressed = false;
  // 异步中断:在最老指令边界之前精确注入(commit 边界 = 架构状态一致点)。
  if (pending_irq_ && !halted_) { take_interrupt(ctx); return true; }
  for (uint32_t i = 0; i < cfg_.commit_width; ++i) {
    if (rob_.empty()) break;
    Rob::Entry& h = rob_.head();
    if (!h.valid || !h.done) break;  // 队头未完成 -> 停(按序)

    if (h.is_halt) {
      if (!sq_.empty()) break;  // fence before halt:先把 store buffer 排空再停机
      rob_.pop_head();
      halted_ = true;
      ctx.halt = true;
      progressed = true;
      break;
    }

    if (is_system(h.fu)) {  // 系统/CSR:精确效应在此 commit 边界(③)
      switch (h.fu) {
        case FuType::CSRW: csr_.write(h.csr_idx, h.sys_imm); break;
        case FuType::CSRR:
          if (h.phys_dst >= 0) pregs_.write(h.phys_dst, csr_.read(h.csr_idx));
          if (h.arch_dst >= 0) {
            rrat_.remap(h.arch_dst, h.phys_dst);  // 更新已提交映射(③)
            if (h.old_phys >= 0) freelist_.free(h.old_phys);
          }
          break;
        case FuType::ECALL: fetch_.redirect(csr_.trap(h.pc + 1, CAUSE_ECALL)); ++traps_; break;
        case FuType::MRET:  fetch_.redirect(csr_.mret()); break;
        default: break;
      }
      system_stall_ = false;  // 解除串行 -> dispatch 恢复
      commit_order_.push_back(h.dyn_id);
      rob_.pop_head();
      ++retired_;
      progressed = true;
      ctx.activate(id, Phase::Eval);
      continue;
    }

    if (h.is_store) {
      sq_.commit(h.dyn_id);  // 标 committed(仍留 SQ 供前递,drain 时才落存)
    } else if (h.arch_dst >= 0) {
      rrat_.remap(h.arch_dst, h.phys_dst);       // 更新已提交映射(RRAT,③)
      if (h.old_phys >= 0) freelist_.free(h.old_phys);  // 旧映射不再有读者 -> 归还
    }

    commit_order_.push_back(h.dyn_id);
    rob_.pop_head();
    ++retired_;
    progressed = true;
  }

  // store buffer 排空:按程序序把已提交的队头 store 落存(不变量:同址写序 = 程序序)。
  for (uint32_t i = 0; i < cfg_.drain_width; ++i) {
    if (!sq_.drain_one(mem_)) break;
    ++stores_drained_;
    progressed = true;
  }

  if (progressed) ctx.activate(id, Phase::Eval);  // 释放 ROB/物理寄存器/SQ -> 解锁分派与等待的 load
  if (!rob_.empty() && rob_.head().valid && rob_.head().done)
    ctx.activate(id, Phase::Retire);
  if (sq_.front_committed())
    ctx.activate(id, Phase::Retire);  // 继续排空 store buffer
  return progressed;
}

}  // namespace ace
