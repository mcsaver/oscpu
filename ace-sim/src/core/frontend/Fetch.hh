// ace-sim/core/frontend: 取指(对应 npc OooFetchPacketDecode + OooFetchPcOutstandingSequencer)。
// 持 PC + 取指队列;PC 驱动逐条取指,分支/跳转在取指拍向 Bpu 查方向、预译码目标(imm=绝对 PC)。
// squash 时 redirect():清空取指队列 + 复位停指 + 重定向 PC。
#pragma once
#include <cstdint>
#include "isa/inst.hh"
#include "core/frontend/Bpu.hh"
#include "core/frontend/Ras.hh"
#include "hw/module.hh"
#include "hw/queue.hh"

namespace ace {

class Fetch : public Module {
 public:
  struct Item {  // 取指队列条目:指令 + 取指时的控制流预测元数据
    Inst     inst;
    uint64_t pc = 0;
    bool     pred_taken = false;
    uint64_t pred_next_pc = 0;
    uint64_t target = 0;   // taken 目标
  };

  Fetch(const Program& prog, Bpu& bpu, Ras& ras, size_t qcap, uint32_t width, size_t start_pc = 0)
      : Module("Fetch"), prog_(prog), bpu_(bpu), ras_(ras), q_(qcap), width_(width), pc_(start_pc) {}

  // 取指一拍:沿预测控制流产 Item 进队;返回是否有进展。
  bool step() {
    if (stopped_) return false;
    bool progressed = false;
    for (uint32_t i = 0; i < width_; ++i) {
      if (pc_ >= prog_.size()) break;
      if (!q_.can_push()) break;  // backpressure
      const Inst& in = prog_[pc_];
      Item fi;
      fi.inst = in;
      fi.pc = pc_;
      fi.target = in.imm;
      if (in.fu == FuType::BRANCH) {
        fi.pred_taken = bpu_.predict(pc_);
        fi.pred_next_pc = fi.pred_taken ? in.imm : pc_ + 1;
      } else if (in.fu == FuType::JUMP) {
        fi.pred_taken = true;
        fi.pred_next_pc = in.imm;  // 无条件:目标已知,不会误判
      } else if (in.fu == FuType::JAL) {   // 直接调用:目标 imm 已知;call 则 RAS push 返回地址(⑤)
        fi.pred_taken = true;
        fi.pred_next_pc = in.imm;
        if (is_call(in)) ras_.push(pc_ + 1);
      } else if (in.fu == FuType::JALR) {  // 间接跳转/返回:目标 execute 才知 -> RAS 预测返回目标(⑤)
        fi.pred_taken = true;
        fi.pred_next_pc = is_ret(in) ? ras_.pop(pc_ + 1) : pc_ + 1;  // ret 弹 RAS;否则暂预测 fall-through
      } else {
        fi.pred_taken = false;
        fi.pred_next_pc = pc_ + 1;
      }
      q_.push(fi);
      ++fetched_;
      progressed = true;
      pc_ = fi.pred_next_pc;
      if (in.fu == FuType::HALT) { stopped_ = true; break; }
    }
    return progressed;
  }

  uint64_t    fetched() const { return fetched_; }
  size_t      pc() const { return pc_; }  // 当前取指 PC(中断保存 mepc 用,③)
  bool        can_pop() const { return q_.can_pop(); }
  const Item& front() const { return q_.front(); }
  void        pop() { q_.pop(); }

  // 误判重定向:丢弃错误路径已取但未分派条目,复位停指,跳到正确 PC。
  void redirect(uint64_t pc) {
    while (q_.can_pop()) q_.pop();
    stopped_ = false;
    pc_ = pc;
  }

 private:
  const Program&     prog_;
  Bpu&               bpu_;
  Ras&               ras_;
  BoundedQueue<Item> q_;
  uint32_t           width_;
  size_t             pc_ = 0;
  bool               stopped_ = false;
  uint64_t           fetched_ = 0;
};

}  // namespace ace
