// ace-sim: 活动调度器(不变量 #3/#7)。
// 只维护"每个 phase 当前需要 eval 的组件集合",不负责调用 eval(交给 SimContext)。
// 这样避免与 Component/Context 的循环依赖。
#pragma once
#include <cstdint>
#include <utility>
#include <vector>
#include "sim/cycle.hh"
#include "sim/phase.hh"

namespace ace {

class ActiveScheduler {
 public:
  void resize(size_t n_components) {
    for (int p = 0; p < kNumPhases; ++p) in_set_[p].assign(n_components, 0);
  }

  // 把组件加入某 phase 的活跃集(去重)。
  void activate(CompId id, Phase phase) {
    int p = static_cast<int>(phase);
    if (id >= in_set_[p].size()) return;  // 未注册,忽略
    if (!in_set_[p][id]) {
      in_set_[p][id] = 1;
      active_[p].push_back(id);
    }
  }

  // 取出并清空某 phase 的活跃集。eval 期间若再次 activate 同 phase,会进入新的空集合,
  // 于"下一个周期"该 phase 运行时才被处理(避免同周期内无限自激)。
  std::vector<CompId> drain(Phase phase) {
    int p = static_cast<int>(phase);
    std::vector<CompId> list = std::move(active_[p]);
    active_[p].clear();
    for (CompId id : list) in_set_[p][id] = 0;
    return list;
  }

  // 是否存在"下一个周期"要处理的活动(任一 phase 非空)。
  bool has_activity() const {
    for (int p = 0; p < kNumPhases; ++p)
      if (!active_[p].empty()) return true;
    return false;
  }

 private:
  std::vector<CompId>  active_[kNumPhases];
  std::vector<uint8_t> in_set_[kNumPhases];  // per-component 去重位
};

}  // namespace ace
