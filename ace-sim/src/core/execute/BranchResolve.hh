// ace-sim/core/execute: 分支解析(对应 npc OooDirectBranchResolveGate)。
// 纯组合:比较实际方向/目标与取指时的预测,给出是否误判 + 正确重定向 PC。
// squash 本身属 control/Squash;本 gate 只做"判定"。
#pragma once
#include <cstdint>
#include "hw/module.hh"

namespace ace {

class BranchResolve : public Module {
 public:
  BranchResolve() : Module("BranchResolve") {}

  struct Result {
    bool     mispredict;
    uint64_t redirect_pc;   // 正确的下一 PC
  };

  Result resolve(uint64_t pc, uint64_t br_target, uint64_t pred_next_pc,
                 bool actual_taken) const {
    uint64_t actual_next = actual_taken ? br_target : (pc + 1);
    return {actual_next != pred_next_pc, actual_next};
  }
};

}  // namespace ace
