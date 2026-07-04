// ace-sim: 未来到期事件(不变量 #1/#2)。
// Event 只表达"跨周期 / 延迟完成 / 外部注入"的事情,到期后投递到目标 inbox,
// 由目标在自己的 phase 中处理,绝不直接改架构状态。
#pragma once
#include <cstdint>
#include "sim/cycle.hh"

namespace ace {

enum class EventKind : uint16_t {
  FuComplete,      // 功能单元多周期完成
  CacheResponse,   // cache 命中/填充响应
  DramResponse,    // DRAM 响应
  TimerInterrupt,  // 定时器中断(V2+)
  DmaComplete,     // DMA 完成(后续)
  BranchRedirect,  // 分支重定向(V4)
  MmioResponse,    // MMIO 响应
  CpuWake,         // CPU 自唤醒(结构冒险等纯 wall-clock 停顿的 backing 事件)
};

inline const char* event_name(EventKind k) {
  switch (k) {
    case EventKind::FuComplete:     return "FuComplete";
    case EventKind::CacheResponse:  return "CacheResponse";
    case EventKind::DramResponse:   return "DramResponse";
    case EventKind::TimerInterrupt: return "TimerInterrupt";
    case EventKind::DmaComplete:    return "DmaComplete";
    case EventKind::BranchRedirect: return "BranchRedirect";
    case EventKind::MmioResponse:   return "MmioResponse";
    case EventKind::CpuWake:        return "CpuWake";
    default:                        return "?";
  }
}

// 轻量 POD 事件。payload 语义由 kind + 目标模块约定。
struct Event {
  Cycle     when     = 0;             // 到期周期
  CompId    target   = kInvalidComp;  // 投递目标组件
  EventKind kind     = EventKind::FuComplete;
  Epoch     epoch    = 0;             // 惰性取消代(V4 启用)
  uint64_t  payload0 = 0;             // 惯例:dyn-inst id / 请求 id
  uint64_t  payload1 = 0;             // 惯例:结果值 / 数据
  uint64_t  payload2 = 0;
};

}  // namespace ace
