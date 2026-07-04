// ace-sim/core/rename: 物理寄存器空闲列表(对应 npc OooFreeList)。
// 初始 [num_arch, num_phys) 空闲(0..num_arch-1 由架构寄存器恒等占用)。
#pragma once
#include <cassert>
#include <vector>
#include "hw/module.hh"

namespace ace {

class FreeList : public Module {
 public:
  FreeList(int num_phys, int num_arch) : Module("FreeList") {
    for (int p = num_phys - 1; p >= num_arch; --p) free_.push_back(p);
  }

  bool empty() const { return free_.empty(); }
  int  alloc() { assert(!free_.empty()); int p = free_.back(); free_.pop_back(); return p; }
  void free(int p) { free_.push_back(p); }

 private:
  std::vector<int> free_;  // 空闲物理寄存器栈
};

}  // namespace ace
