// ace-sim: 组件基类(不变量 #6)。
// 组件之间只通过 event(inbox)/ queue / port 通信,不做深层互调。
#pragma once
#include <vector>
#include "sim/cycle.hh"
#include "sim/event.hh"
#include "sim/phase.hh"

namespace ace {

class SimContext;  // 前向声明,打破循环依赖

class Component {
 public:
  CompId             id = kInvalidComp;
  std::vector<Event> inbox;  // harness 把到期事件投递到此,由本组件在 Wakeup 处理

  virtual ~Component() = default;
  virtual const char* name() const = 0;

  // 处理某 phase。返回 true 表示做了实质工作(progressed,仅用于统计/调试)。
  virtual bool eval(Phase phase, SimContext& ctx) = 0;
};

}  // namespace ace
