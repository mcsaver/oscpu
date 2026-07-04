// ace-sim/core/regfile: 物理寄存器堆(对应 npc OooPhysRegFile + OooBusyTable)。
// 每项 = 值 + ready 位(ready 即 npc BusyTable 的"非忙")。dispatch 分配 dst 置 unready,
// 完成拍 write() 写值并置 ready。
#pragma once
#include <cstdint>
#include <vector>
#include "hw/module.hh"

namespace ace {

class PhysRegFile : public Module {
 public:
  PhysRegFile(int num_phys, int num_arch) : Module("PhysRegFile"), regs_(num_phys) {
    for (int i = 0; i < num_arch; ++i) regs_[i].ready = true;  // 初始架构 phys 就绪
  }

  uint64_t value(int p) const { return regs_[p].value; }
  bool     ready(int p) const { return regs_[p].ready; }
  void     write(int p, uint64_t v) { regs_[p].value = v; regs_[p].ready = true; }  // 完成写
  void     set_unready(int p) { regs_[p].ready = false; }                           // 分配为 dst

 private:
  struct Reg { uint64_t value = 0; bool ready = true; };
  std::vector<Reg> regs_;
};

}  // namespace ace
