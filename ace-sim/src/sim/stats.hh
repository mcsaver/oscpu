// ace-sim: 全局统计计数(TraceEvent 类,只统计不驱动仿真)。
#pragma once
#include <cstdint>

namespace ace {

struct Stats {
  uint64_t cycles_advanced = 0;  // 实际推进(执行)的周期数
  uint64_t cycles_skipped  = 0;  // 通过 time-skip 跳过的空闲周期数
  uint64_t events_delivered = 0; // 投递到 inbox 的到期事件数
  uint64_t phase_evals = 0;      // 组件 eval 调用次数
  uint64_t insts_fetched = 0;
  uint64_t insts_issued = 0;
  uint64_t insts_retired = 0;
  uint64_t fetch_stalls_full = 0;   // 因 fetch queue 满而停顿的次数
  uint64_t issue_stalls_hazard = 0; // 因数据/结构冒险而停顿的次数
};

}  // namespace ace
