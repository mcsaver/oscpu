// ace-sim: 仿真上下文 + 主循环(不变量 #1/#9/#10)。
//
// 主循环模型(DESIGN.md §3/§5):
//   while 未静止:
//     deliver_due()                 // 到期事件 -> 目标 inbox,activate 目标 Wakeup
//     for phase in 固定顺序: 运行活跃组件
//     决定下一个 cur_cycle:有下周期活动则 +1,否则跳到 wheel 的下一个事件周期
#pragma once
#include <algorithm>
#include <vector>
#include "sim/active_scheduler.hh"
#include "sim/component.hh"
#include "sim/cycle.hh"
#include "sim/event.hh"
#include "sim/event_wheel.hh"
#include "sim/phase.hh"
#include "sim/stats.hh"

namespace ace {

class SimContext {
 public:
  Cycle          cur_cycle = 0;
  EventWheel     wheel;
  ActiveScheduler sched;
  Stats          stats;
  bool           halt = false;  // 组件置位以请求结束仿真

  // 注册组件,分配 id 并同步 scheduler 尺寸。
  CompId add(Component* c) {
    CompId id = static_cast<CompId>(comps_.size());
    c->id = id;
    comps_.push_back(c);
    sched.resize(comps_.size());
    return id;
  }

  Component* comp(CompId id) { return comps_[id]; }
  size_t     num_components() const { return comps_.size(); }

  // 调度未来事件(不变量 #1:到期后只投递到 inbox)。
  void schedule(const Event& ev) { wheel.schedule(ev, cur_cycle); }
  void activate(CompId id, Phase p) { sched.activate(id, p); }

  // 运行主循环,最多推进到 max_cycle(含);用于安全上限。
  // 返回结束时的 cur_cycle。
  Cycle run(Cycle max_cycle = kInvalidCycle) {
    while (!halt) {
      deliver_due();
      for (Phase p : kPhaseOrder) run_phase(p);
      if (halt) break;  // 停机本周期已在 Retire 生效:不再推进 cur_cycle / 计数(缺陷 #1)

      // ---- 决定下一个 cur_cycle(time-skip,DESIGN.md §5)----
      Cycle target = kInvalidCycle;
      if (sched.has_activity()) target = cur_cycle + 1;
      Cycle nev = wheel.next_event_cycle(cur_cycle);
      if (nev != kInvalidCycle) target = std::min(target, nev);

      if (target == kInvalidCycle) break;          // 系统静止:无活动、无事件
      if (target > max_cycle) { cur_cycle = max_cycle; break; }

      stats.cycles_advanced += 1;
      stats.cycles_skipped  += (target - cur_cycle - 1);  // 跳过的空闲周期
      cur_cycle = target;
    }
    return cur_cycle;
  }

 private:
  // 把 cur_cycle 到期的事件从 wheel 取出,投递到目标 inbox,并激活目标的 Wakeup。
  void deliver_due() {
    std::vector<Event> due = wheel.take_due(cur_cycle);
    for (Event& ev : due) {
      Component* c = comps_[ev.target];
      c->inbox.push_back(ev);
      sched.activate(ev.target, Phase::Wakeup);
      stats.events_delivered++;
    }
  }

  bool run_phase(Phase p) {
    std::vector<CompId> list = sched.drain(p);
    bool progressed = false;
    for (CompId id : list) {
      progressed |= comps_[id]->eval(p, *this);
      stats.phase_evals++;
    }
    return progressed;
  }

  std::vector<Component*> comps_;  // id -> component(非拥有)
};

}  // namespace ace
