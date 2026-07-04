// ace-sim/core/execute: 整数 ALU + 分支比较(对应 npc ALU + CompareUnit)。
// 持 ALU 功能单元(latency/II/width);组合计算加法与分支条件。分支借用本 FU。
#pragma once
#include <cstdint>
#include "hw/module.hh"
#include "hw/resource.hh"
#include "sim/cycle.hh"

namespace ace {

class Alu : public Module {
 public:
  explicit Alu(FuDesc d) : Module("Alu"), fu_(d) {}

  // FU 资源端口
  bool     can_issue(Cycle c) const { return fu_.can_issue(c); }
  void     reserve(Cycle c) { fu_.reserve(c); }
  Cycle    next_free() const { return fu_.next_free(); }
  uint32_t latency() const { return fu_.latency(); }

  // 组合计算
  uint64_t compute(uint64_t a, uint64_t b, uint64_t imm) const { return a + b + imm; }
  bool     taken(int cond, uint64_t a, uint64_t b) const {
    return cond == 0 ? (a == b) : (a != b);  // 0=EQ,1=NE
  }

 private:
  FunctionalUnit fu_;
};

}  // namespace ace
