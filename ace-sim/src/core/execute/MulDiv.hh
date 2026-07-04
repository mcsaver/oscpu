// ace-sim/core/execute: 乘除单元(对应 npc OooMulDivUnit)。
// 持 MUL 与 DIV 两个功能单元(各自 latency/II/width);组合计算乘除(除零 -> 0)。
#pragma once
#include <cstdint>
#include "hw/module.hh"
#include "hw/resource.hh"
#include "sim/cycle.hh"

namespace ace {

class MulDiv : public Module {
 public:
  MulDiv(FuDesc mul, FuDesc div) : Module("MulDiv"), mul_(mul), div_(div) {}

  bool     can_issue(bool is_div, Cycle c) const { return (is_div ? div_ : mul_).can_issue(c); }
  void     reserve(bool is_div, Cycle c) { (is_div ? div_ : mul_).reserve(c); }
  Cycle    next_free(bool is_div) const { return (is_div ? div_ : mul_).next_free(); }
  uint32_t latency(bool is_div) const { return (is_div ? div_ : mul_).latency(); }

  uint64_t compute(bool is_div, uint64_t a, uint64_t b) const {
    return is_div ? (b ? a / b : 0) : a * b;
  }

 private:
  FunctionalUnit mul_, div_;
};

}  // namespace ace
