// ace-sim: 周期级事件轮(timing wheel)。
// 近未来事件用环形桶 O(1) 调度/取出;超出窗口的远未来事件退化到最小堆。
// 适合 fixed-latency 的 FU/cache/DRAM 完成事件(讨论第 4 节)。
#pragma once
#include <cassert>
#include <queue>
#include <vector>
#include "sim/cycle.hh"
#include "sim/event.hh"

namespace ace {

class EventWheel {
 public:
  static constexpr Cycle kWindow = 4096;  // 环形窗口大小(必须为 2 的幂以便掩码)

  // 调度一个未来事件。V1 契约:严格未来(ev.when > now)。
  // now 桶在本周期开头已被 take_due 清空,若允许 when==now 会造成事件丢失 +
  // next_event_cycle 返回 now -> 主循环下溢/死循环。同周期唤醒(策略B)另走通道。
  void schedule(const Event& ev, Cycle now) {
    assert(ev.when > now && "V1: event must be strictly in the future");
    if (ev.when - now < kWindow) {
      buckets_[ev.when & kMask].push_back(ev);
    } else {
      far_.push(ev);
    }
    ++count_;
    if (ev.when < min_hint_ || count_ == 1) min_hint_ = ev.when;
  }

  // 取出并清空 now 桶内的所有到期事件。调用方负责投递。
  // 注意:必须在推进到某个 now 时、且不早于上次取出的 now 时调用。
  std::vector<Event> take_due(Cycle now) {
    std::vector<Event> out;
    // 先把远未来堆里已进入窗口的事件迁移进桶(通常极少发生)。
    migrate_far(now);
    auto& b = buckets_[now & kMask];
    if (!b.empty()) {
      out.swap(b);              // 移动出去,桶清空
      count_ -= out.size();
    }
    return out;
  }

  // 返回下一个非空事件的周期;若无事件返回 kInvalidCycle。
  // now 为当前周期(已处理完 now 桶后调用)。
  Cycle next_event_cycle(Cycle now) const {
    // 从 now+1 起扫描窗口内桶,找最近非空(d 递增即 when 递增)。
    // 严格从 d=1 起:now 桶已被清空,且契约保证无 when==now 事件,避免返回 now。
    // 窗口内所有 live 事件 when < now+kWindow < 任何 far_ 事件,故先扫桶再看 far_ 即得全局最早。
    for (Cycle d = 1; d < kWindow; ++d) {
      Cycle c = now + d;
      if (!buckets_[c & kMask].empty()) return c;
    }
    if (!far_.empty()) return far_.top().when;
    return kInvalidCycle;
  }

  bool empty() const { return count_ == 0; }
  size_t size() const { return count_; }

 private:
  static constexpr Cycle kMask = kWindow - 1;
  static_assert((kWindow & kMask) == 0, "kWindow must be power of two");

  // 远未来事件排序:小顶堆(when 越小越先)。
  struct FarCmp {
    bool operator()(const Event& a, const Event& b) const { return a.when > b.when; }
  };

  void migrate_far(Cycle now) {
    while (!far_.empty() && far_.top().when - now < kWindow) {
      Event e = far_.top();
      far_.pop();
      buckets_[e.when & kMask].push_back(e);
    }
  }

  std::vector<Event> buckets_[kWindow];
  std::priority_queue<Event, std::vector<Event>, FarCmp> far_;
  size_t count_ = 0;
  Cycle  min_hint_ = kInvalidCycle;  // 保留:未来可用于加速 next_event_cycle
};

}  // namespace ace
