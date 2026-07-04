// ace-sim/core/frontend: 分支方向预测器(对应 npc OooBranchDirectionPredictor)。
// bimodal(默认):PC 索引的 2-bit 饱和计数器表。
// gshare(⑤,ghist_bits>0):全局历史寄存器 GHR ^ PC 索引 PHT —— 捕获分支间相关性。
//
// 状态(PHT/GHR)在解析拍(Wakeup)写、取指拍(Eval)读;Wakeup < Eval,故同拍同 PC 的 update 先于
// predict 生效。GHR 在解析拍更新(非投机,滞后但简单;预测器只影响时序,不影响架构正确性)。
#pragma once
#include <cstdint>
#include <vector>
#include "hw/module.hh"

namespace ace {

class Bpu : public Module {
 public:
  explicit Bpu(size_t entries, uint32_t ghist_bits = 0)
      : Module("Bpu"), bht_(entries, 1),  // 弱不跳转起步
        ghist_bits_(ghist_bits), ghist_mask_(ghist_bits ? ((1u << ghist_bits) - 1) : 0) {}

  // 组合查询端口:taken? (计数器 >= 2 = 弱/强跳转)
  bool predict(uint64_t pc) const { return bht_[index(pc)] >= 2; }

  // 写端口:按实际方向饱和更新 PHT + 移入全局历史(分支解析拍调用)。
  void update(uint64_t pc, bool taken) {
    uint8_t& c = bht_[index(pc)];
    if (taken) { if (c < 3) ++c; }
    else       { if (c > 0) --c; }
    if (ghist_bits_) ghr_ = ((ghr_ << 1) | (taken ? 1u : 0u)) & ghist_mask_;
  }

 private:
  size_t index(uint64_t pc) const {
    return ghist_bits_ ? static_cast<size_t>((pc ^ ghr_) % bht_.size())
                       : static_cast<size_t>(pc % bht_.size());
  }
  std::vector<uint8_t> bht_;         // PHT(2-bit 计数器)
  uint32_t             ghist_bits_;  // 0 = bimodal;>0 = gshare 历史位数
  uint32_t             ghist_mask_;
  uint32_t             ghr_ = 0;     // 全局历史寄存器
};

}  // namespace ace
