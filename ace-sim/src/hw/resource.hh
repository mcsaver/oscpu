// ace-sim: 多周期资源占用模型(不变量 #5)。
// 一个功能单元同时建模三件事:completion latency、initiation interval(吞吐)、width(每拍并发)。
#pragma once
#include <cstdint>
#include "sim/cycle.hh"

namespace ace {

struct FuDesc {
  uint32_t latency = 1;              // 从发射到 completion 的周期数
  uint32_t initiation_interval = 1;  // 相邻两次发射的最小间隔(1 = 全流水)
  uint32_t width = 1;                // 同一周期可接受的发射数
};

class FunctionalUnit {
 public:
  FunctionalUnit() = default;
  explicit FunctionalUnit(FuDesc d) : desc_(d) {}

  const FuDesc& desc() const { return desc_; }
  uint32_t latency() const { return desc_.latency; }

  // 能否再接受一次发射?同周期只受 width 约束,跨周期只受 II(initiation_interval)约束。
  // 关键:必须先判"同周期"分支 —— 否则 reserve() 写入的 next_accept=now+II 会把本周期
  // 剩余的 width 槽全部误杀(width 在 II>=1 时形同虚设,审查缺陷 #7)。
  bool can_issue(Cycle now) const {
    if (now == issued_cycle_) return issued_this_cycle_ < desc_.width;  // 同周期:仅 width
    return now >= next_accept_cycle_;                                    // 后续周期:仅 II
  }

  // 结构冒险下 FU 最早可再次受理的周期:供 CPU 主动自唤醒,避免 II>latency 时丢唤醒
  // (完成事件在 now+latency 触发,而 II 窗口延到 now+II,二者间无事件兜底 -> 睡死)。
  Cycle next_free() const { return next_accept_cycle_; }

  // 占用一次发射额度。必须在 can_issue()==true 时调用。
  void reserve(Cycle now) {
    if (now != issued_cycle_) {
      issued_cycle_ = now;
      issued_this_cycle_ = 0;
    }
    ++issued_this_cycle_;
    next_accept_cycle_ = now + desc_.initiation_interval;
  }

 private:
  FuDesc   desc_{};
  Cycle    next_accept_cycle_ = 0;
  Cycle    issued_cycle_ = kInvalidCycle;
  uint32_t issued_this_cycle_ = 0;
};

}  // namespace ace
