// ace-sim: 周期内的固定 phase 顺序(不变量 #10)。
// 顺序即微架构定义,详见 DESIGN.md §3。
#pragma once
#include <cstdint>

namespace ace {

enum class Phase : uint8_t {
  EdgeCommit = 0,  // cur = next(仅本周期写过 next 的组件)
  Wakeup,          // 处理 inbox:completion / response / operand 唤醒
  Arbitrate,       // port / bus / FU / writeback 端口仲裁
  Eval,            // 活跃组件算 next-state / schedule 未来事件
  Transfer,        // ready-valid / packet 传输
  Retire,          // commit / 精确异常 / 中断边界(架构状态在此改变)
  EndCycle,        // stats / trace / 下周期激活
  kNumPhases
};

inline constexpr int kNumPhases = static_cast<int>(Phase::kNumPhases);

// harness 每个推进周期按此固定顺序执行组件 phase。
inline constexpr Phase kPhaseOrder[] = {
    Phase::EdgeCommit, Phase::Wakeup,  Phase::Arbitrate, Phase::Eval,
    Phase::Transfer,   Phase::Retire, Phase::EndCycle,
};

inline const char* phase_name(Phase p) {
  switch (p) {
    case Phase::EdgeCommit: return "EdgeCommit";
    case Phase::Wakeup:     return "Wakeup";
    case Phase::Arbitrate:  return "Arbitrate";
    case Phase::Eval:       return "Eval";
    case Phase::Transfer:   return "Transfer";
    case Phase::Retire:     return "Retire";
    case Phase::EndCycle:   return "EndCycle";
    default:                return "?";
  }
}

}  // namespace ace
