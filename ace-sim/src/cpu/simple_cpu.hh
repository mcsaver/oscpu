// ace-sim: V1 顺序核(in-order issue + scoreboard,无 ROB)。
//
// 关键纪律:
//  - 结果在 issue 时算(ALU/MUL/DIV),放进 FuComplete 事件 payload(讨论第 14 节)。
//  - 源/目的寄存器"忙"位:issue 置、**retire** 清 —— 从而 completion ≠ commit,
//    架构寄存器只在 retire 边界写入(不变量 #2/#3)。V1 为保守顺序核,无前递。
//  - 空闲(既没 issue 也没 fetch)时不自激 -> 睡眠,靠 wheel 中的完成事件唤醒 -> 使能 time-skip。
#pragma once
#include <cstdint>
#include <deque>
#include <vector>
#include "hw/queue.hh"
#include "hw/resource.hh"
#include "isa/inst.hh"
#include "mem/mem_req.hh"
#include "sim/component.hh"

namespace ace {

class SimContext;

struct CpuConfig {
  int      num_regs        = 32;
  size_t   fetch_queue_cap = 8;
  uint32_t fetch_width     = 2;
  uint32_t issue_width     = 1;   // V1 顺序核:每周期至多发射 1 条
  uint32_t retire_width    = 2;
  FuDesc   alu{/*lat*/1,  /*ii*/1,  /*width*/2};
  FuDesc   mul{/*lat*/3,  /*ii*/1,  /*width*/1};
  FuDesc   div{/*lat*/20, /*ii*/20, /*width*/1};  // 非流水除法器
};

// 退休队列(in-order)条目
struct DynInst {
  uint64_t id = 0;
  FuType   fu = FuType::ALU;
  int      dst = -1;
  uint64_t result = 0;
  bool     done = false;      // completion 是否到达
  bool     is_load = false;
  Cycle    issue_cycle = 0;
  Cycle    done_cycle  = kInvalidCycle;
};

class CycleSimpleCpu : public Component {
 public:
  CycleSimpleCpu(Program prog, MemPort* mem, CompId mem_id, CpuConfig cfg = {});

  const char* name() const override { return "CycleSimpleCpu"; }
  bool eval(Phase phase, SimContext& ctx) override;

  void kickoff(SimContext& ctx);           // 激活初始取指
  void set_reg(int r, uint64_t v) { regfile_[r] = v; }

  // ---- 观测接口(自检用)----
  uint64_t reg(int r) const { return regfile_[r]; }
  uint64_t fetched() const { return fetched_; }
  uint64_t issued()  const { return issued_; }
  uint64_t retired() const { return retired_; }
  uint64_t max_fetchq_occupancy() const { return max_fq_; }
  uint64_t fetch_full_events() const { return fetch_full_; }
  uint64_t issue_hazard_events() const { return issue_hazard_; }
  uint64_t inflight_peak() const { return inflight_peak_; }
  bool     halted() const { return halted_; }

 private:
  bool on_wakeup(SimContext& ctx);
  bool on_eval(SimContext& ctx);
  bool on_retire(SimContext& ctx);
  bool try_issue(SimContext& ctx);
  bool try_fetch(SimContext& ctx);
  uint64_t compute_result(const Inst& in) const;
  static int fu_index(FuType t);

  Program   prog_;
  MemPort*  mem_;
  CompId    mem_id_;
  CpuConfig cfg_;

  std::vector<uint64_t> regfile_;  // 架构寄存器(retire 边界写)
  std::vector<uint8_t>  busy_;     // scoreboard:issue 置、retire 清
  BoundedQueue<Inst>    fetch_q_;
  size_t                pc_ = 0;
  std::deque<DynInst>   inflight_;
  FunctionalUnit        fu_[3];    // ALU / MUL / DIV
  uint64_t              next_id_ = 1;

  uint64_t fetched_ = 0, issued_ = 0, retired_ = 0;
  uint64_t max_fq_ = 0, fetch_full_ = 0, issue_hazard_ = 0, inflight_peak_ = 0;
  bool     halted_ = false;
  bool     fetch_stopped_ = false;         // HALT 已入队 -> 永久停止取指(缺陷 #4)
  Cycle    structural_wake_ = kInvalidCycle;  // 本周期若因结构冒险独立停顿,记录 FU 释放周期(缺陷 #2/5/9)
};

}  // namespace ace
