// ace-sim: 全局周期时间。
// 不变量 #(2.Time): V1 单时钟域,1 tick = 1 cycle。多时钟域留待后续版本扩展。
#pragma once
#include <cstdint>
#include <limits>

namespace ace {

using Cycle = uint64_t;

// 无效/哨兵周期:用于"没有下一个事件"的表达。
inline constexpr Cycle kInvalidCycle = std::numeric_limits<Cycle>::max();

// 组件 id。INVALID 表示未注册。
using CompId = uint32_t;
inline constexpr CompId kInvalidComp = std::numeric_limits<CompId>::max();

// epoch:分支/flush 的惰性取消代(不变量 #8)。V1 仅占位,V4 启用。
using Epoch = uint32_t;

}  // namespace ace
