#include "cpu/simple_cpu.hh"
#include <algorithm>
#include "sim/context.hh"

namespace ace {

CycleSimpleCpu::CycleSimpleCpu(Program prog, MemPort* mem, CompId mem_id, CpuConfig cfg)
    : prog_(std::move(prog)),
      mem_(mem),
      mem_id_(mem_id),
      cfg_(cfg),
      regfile_(cfg.num_regs, 0),
      busy_(cfg.num_regs, 0),
      fetch_q_(cfg.fetch_queue_cap) {
  fu_[0] = FunctionalUnit(cfg.alu);
  fu_[1] = FunctionalUnit(cfg.mul);
  fu_[2] = FunctionalUnit(cfg.div);
}

void CycleSimpleCpu::kickoff(SimContext& ctx) { ctx.activate(id, Phase::Eval); }

int CycleSimpleCpu::fu_index(FuType t) {
  switch (t) {
    case FuType::ALU: return 0;
    case FuType::MUL: return 1;
    case FuType::DIV: return 2;
    default:          return 0;
  }
}

uint64_t CycleSimpleCpu::compute_result(const Inst& in) const {
  uint64_t a = in.src0 >= 0 ? regfile_[in.src0] : 0;
  uint64_t b = in.src1 >= 0 ? regfile_[in.src1] : 0;
  switch (in.fu) {
    case FuType::ALU: return a + b + in.imm;
    case FuType::MUL: return a * b;
    case FuType::DIV: return b ? a / b : 0;
    default:          return 0;
  }
}

bool CycleSimpleCpu::eval(Phase phase, SimContext& ctx) {
  switch (phase) {
    case Phase::Wakeup: return on_wakeup(ctx);
    case Phase::Eval:   return on_eval(ctx);
    case Phase::Retire: return on_retire(ctx);
    default:            return false;
  }
}

// ---- Wakeup:处理到期的 completion / cache / dram 响应 / CpuWake ----
bool CycleSimpleCpu::on_wakeup(SimContext& ctx) {
  bool matched = false, wake_eval = false;
  for (const Event& ev : inbox) {
    if (ev.kind == EventKind::CpuWake) { wake_eval = true; continue; }  // 结构冒险自唤醒
    for (DynInst& d : inflight_) {
      if (d.id == ev.payload0) {
        d.done = true;
        d.result = ev.payload1;
        d.done_cycle = ctx.cur_cycle;
        matched = true;
        break;
      }
    }
  }
  inbox.clear();
  if (matched)   ctx.activate(id, Phase::Retire);  // 队头可能已可退休(retire 再解锁 Eval)
  if (wake_eval) ctx.activate(id, Phase::Eval);    // FU 结构资源已释放 -> 重试发射
  return matched || wake_eval;
}

// ---- Eval:先发射队头(顺序),再取指回填 ----
bool CycleSimpleCpu::on_eval(SimContext& ctx) {
  structural_wake_ = kInvalidCycle;  // 由 try_issue 重新判定
  bool did_issue = try_issue(ctx);
  bool did_fetch = try_fetch(ctx);
  inflight_peak_ = std::max<uint64_t>(inflight_peak_, inflight_.size());
  if (did_issue || did_fetch) {
    ctx.activate(id, Phase::Eval);  // 有进展则继续
  } else if (structural_wake_ != kInvalidCycle) {
    // 纯结构冒险停顿:无 completion/response 事件兜底,主动调度自唤醒(缺陷 #2/5/9)。
    Event e;
    e.when = structural_wake_;
    e.target = id;
    e.kind = EventKind::CpuWake;
    ctx.schedule(e);
  }
  // 否则(数据/内存端口冒险)睡眠:producer 完成事件 / load 响应事件会唤醒。
  return did_issue || did_fetch;
}

bool CycleSimpleCpu::try_fetch(SimContext& ctx) {
  (void)ctx;  // 取指不依赖 ctx(不 schedule 事件),保留形参以对称
  if (fetch_stopped_) return false;  // HALT 已入队 -> 永久停止取指(缺陷 #4)
  bool progressed = false;
  for (uint32_t i = 0; i < cfg_.fetch_width; ++i) {
    if (pc_ >= prog_.size()) break;
    if (!fetch_q_.can_push()) { ++fetch_full_; break; }  // backpressure(不变量 #7)
    Inst in = prog_[pc_++];
    fetch_q_.push(in);
    ++fetched_;
    progressed = true;
    if (in.fu == FuType::HALT) { fetch_stopped_ = true; break; }  // HALT 后的指令绝不取指/发射
  }
  max_fq_ = std::max<uint64_t>(max_fq_, fetch_q_.size());
  return progressed;
}

bool CycleSimpleCpu::try_issue(SimContext& ctx) {
  bool progressed = false;
  for (uint32_t i = 0; i < cfg_.issue_width; ++i) {
    if (!fetch_q_.can_pop()) break;
    const Inst in = fetch_q_.front();

    if (in.fu == FuType::HALT) {
      DynInst d;
      d.id = next_id_++;
      d.fu = FuType::HALT;
      d.done = true;
      d.issue_cycle = ctx.cur_cycle;
      d.done_cycle = ctx.cur_cycle;
      inflight_.push_back(d);
      fetch_q_.pop();
      ++issued_;
      progressed = true;
      ctx.activate(id, Phase::Retire);
      break;  // HALT 之后不再发射
    }

    // ---- 冒险检查(顺序核:队头停则全停)----
    // 按来源分类:数据冒险由 producer 的完成事件兜底唤醒;内存端口 backpressure 由
    // load 响应事件兜底;唯有结构冒险(FU II)是纯 wall-clock 条件、无事件兜底 ——
    // 若它是唯一阻塞原因,必须记录 FU 释放周期,由 on_eval 主动调度 CpuWake(缺陷 #2/5/9)。
    bool data_hz = false, struct_hz = false, memport_hz = false;
    Cycle fu_free = kInvalidCycle;
    if (in.dst  >= 0 && busy_[in.dst])  data_hz = true;  // WAW
    if (in.src0 >= 0 && busy_[in.src0]) data_hz = true;  // RAW
    if (in.src1 >= 0 && busy_[in.src1]) data_hz = true;  // RAW
    if (in.fu != FuType::LOAD) {
      FunctionalUnit& fu = fu_[fu_index(in.fu)];
      if (!fu.can_issue(ctx.cur_cycle)) { struct_hz = true; fu_free = fu.next_free(); }
    } else {
      if (!mem_->can_send()) memport_hz = true;
    }
    if (data_hz || struct_hz || memport_hz) {
      ++issue_hazard_;
      if (struct_hz && !data_hz && !memport_hz && fu_free > ctx.cur_cycle)
        structural_wake_ = fu_free;  // 结构冒险独占阻塞 -> 需要自唤醒兜底
      break;
    }

    // ---- 发射 ----
    DynInst d;
    d.id = next_id_++;
    d.fu = in.fu;
    d.dst = in.dst;
    d.is_load = (in.fu == FuType::LOAD);
    d.issue_cycle = ctx.cur_cycle;
    if (in.dst >= 0) busy_[in.dst] = 1;  // scoreboard 置忙(retire 才清)

    if (in.fu == FuType::LOAD) {
      MemReq req;
      req.dyn_id = d.id;
      req.addr = (in.src0 >= 0 ? regfile_[in.src0] : 0) + in.imm;
      req.requester = id;
      mem_->send(req);
      ctx.activate(mem_id_, Phase::Eval);
      d.done_cycle = kInvalidCycle;  // 由响应事件决定
    } else {
      FunctionalUnit& fu = fu_[fu_index(in.fu)];
      fu.reserve(ctx.cur_cycle);  // 占用资源(latency/II/width)
      uint64_t res = compute_result(in);
      d.result = res;
      Cycle when = ctx.cur_cycle + fu.latency();
      d.done_cycle = when;
      Event ev;
      ev.when = when;
      ev.target = id;
      ev.kind = EventKind::FuComplete;
      ev.payload0 = d.id;
      ev.payload1 = res;
      ctx.schedule(ev);
    }

    inflight_.push_back(d);
    fetch_q_.pop();
    ++issued_;
    progressed = true;
  }
  return progressed;
}

// ---- Retire:in-order,只有队头完成才退休;架构寄存器在此写入(commit 边界)----
bool CycleSimpleCpu::on_retire(SimContext& ctx) {
  bool progressed = false;
  for (uint32_t i = 0; i < cfg_.retire_width; ++i) {
    if (inflight_.empty()) break;
    DynInst& h = inflight_.front();
    if (!h.done) break;  // 队头未完成 -> 停(in-order)

    if (h.fu == FuType::HALT) {
      inflight_.pop_front();
      halted_ = true;
      ctx.halt = true;  // 所有更老指令已退休,安全停机
      progressed = true;
      break;
    }

    if (h.dst >= 0) {
      regfile_[h.dst] = h.result;  // 架构写(commit)
      busy_[h.dst] = 0;            // 清忙 -> 解锁依赖者
    }
    inflight_.pop_front();
    ++retired_;
    progressed = true;
  }
  if (progressed) ctx.activate(id, Phase::Eval);  // 释放寄存器可能解锁 issue
  if (!inflight_.empty() && inflight_.front().done)
    ctx.activate(id, Phase::Retire);  // 预算用尽但队头仍可退 -> 下周期继续
  return progressed;
}

}  // namespace ace
