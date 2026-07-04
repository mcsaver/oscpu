// ace-sim/core/frontend: 返回地址栈 RAS(对应 npc 的 RAS)。
// call(JAL rd=ra)取指拍 push 返回地址(pc+1);ret(JALR rs=ra)取指拍 pop 得预测返回目标。
// **投机**结构:错误路径的 push/pop 会污染栈,但架构正确性由 execute 解析 + squash 保证,
// RAS 只影响预测准确率(与 gshare/TLB 同理:预测/时序 ≠ 架构结果)。饱和栈(满/空钳制)。
#pragma once
#include <cstdint>
#include <vector>
#include "hw/module.hh"

namespace ace {

class Ras : public Module {
 public:
  explicit Ras(size_t depth) : Module("Ras"), stack_(depth), depth_(depth) {}

  void push(uint64_t ret_addr) {
    if (sp_ < depth_) stack_[sp_++] = ret_addr;   // 满则丢弃(饱和)
  }
  // pop 预测返回目标;空则返回 fallback(通常 pc+1)。
  uint64_t pop(uint64_t fallback) {
    if (sp_ == 0) return fallback;
    return stack_[--sp_];
  }
  bool empty() const { return sp_ == 0; }

 private:
  std::vector<uint64_t> stack_;
  size_t                depth_, sp_ = 0;
};

}  // namespace ace
