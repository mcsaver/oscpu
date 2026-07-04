// ace-sim/core/execute: FP 算术单元(对应 npc OooFpArithGate + FpConvert/Compare)。
// 一个全流水 FP 单元(II=1),完成延迟按 op:FADD/FMUL/FCVT/FCMP=lat,FDIV=div_lat(较长)。
// 语义用 host double,与 FunctionalBackend 逐位同源(golden==详细核)。
#pragma once
#include <cstdint>
#include "hw/module.hh"
#include "hw/resource.hh"
#include "isa/inst.hh"
#include "sim/cycle.hh"

namespace ace {

class FpAlu : public Module {
 public:
  FpAlu(FuDesc pipe, uint32_t div_lat) : Module("FpAlu"), fu_(pipe), div_lat_(div_lat) {}

  bool     can_issue(Cycle c) const { return fu_.can_issue(c); }
  void     reserve(Cycle c) { fu_.reserve(c); }
  Cycle    next_free() const { return fu_.next_free(); }
  uint32_t latency(FuType op) const { return op == FuType::FDIV ? div_lat_ : fu_.latency(); }

  uint64_t compute(FuType op, uint64_t a, uint64_t b) const {
    switch (op) {
      case FuType::FADD:   return fbits(f64(a) + f64(b));
      case FuType::FMUL:   return fbits(f64(a) * f64(b));
      case FuType::FDIV:   return fbits(f64(a) / f64(b));
      case FuType::FCVTIF: return fbits(static_cast<double>(static_cast<int64_t>(a)));
      case FuType::FCVTFI: return static_cast<uint64_t>(static_cast<int64_t>(f64(a)));
      case FuType::FCMP:   return (f64(a) < f64(b)) ? 1 : 0;
      default:             return 0;
    }
  }

 private:
  FunctionalUnit fu_;       // 全流水 FP 单元
  uint32_t       div_lat_;  // FDIV 完成延迟(单元仍 II=1 流水化 —— 模型简化)
};

}  // namespace ace
