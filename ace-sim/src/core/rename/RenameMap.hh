// ace-sim/core/rename: 推测寄存器别名表 RAT(对应 npc OooRenameMap)。
// arch -> phys 映射;初始恒等。分支处 snapshot(),误判 restore() 回滚(= npc 的 ROB-walk 恢复)。
#pragma once
#include <vector>
#include "hw/module.hh"

namespace ace {

class RenameMap : public Module {
 public:
  explicit RenameMap(int num_arch) : Module("RenameMap"), map_(num_arch) {
    for (int i = 0; i < num_arch; ++i) map_[i] = i;  // 恒等映射
  }

  int  phys(int arch) const { return map_[arch]; }        // 读:rename 源
  int  remap(int arch, int new_phys) {                    // 写:rename 目的,返回旧映射
    int old = map_[arch];
    map_[arch] = new_phys;
    return old;
  }
  std::vector<int> snapshot() const { return map_; }       // 分支检查点
  void restore(const std::vector<int>& ckpt) { map_ = ckpt; }

 private:
  std::vector<int> map_;
};

}  // namespace ace
