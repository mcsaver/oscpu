// ace-sim/core/dispatch: 重排序缓冲 ROB(对应 npc OooRob)。
// 程序序环:dispatch alloc、wakeup 标 done、retire 按序 pop、误判 squash walk(归还更年轻 phys_dst)。
#pragma once
#include <cstdint>
#include <vector>
#include "isa/inst.hh"
#include "core/rename/FreeList.hh"
#include "hw/module.hh"

namespace ace {

class Rob : public Module {
 public:
  struct Entry {
    uint64_t dyn_id = 0;
    bool     valid = false, done = false, is_halt = false, is_store = false;
    int      arch_dst = -1;
    int      phys_dst = -1, old_phys = -1;  // old_phys 在 commit 时释放
    FuType   fu = FuType::ALU;
    // 分支投机(V4)/ 间接跳转(⑤):
    bool             is_branch = false;
    bool             is_jalr = false;    // JALR:目标 execute 才知,resolve 同分支
    uint64_t         pc = 0;             // 该分支的 PC
    uint64_t         br_target = 0;      // taken 目标(绝对 PC)
    bool             pred_taken = false; // 取指时的方向预测
    uint64_t         pred_next_pc = 0;   // 预测的下一 PC
    std::vector<int> rat_ckpt;           // 分支处的 RAT 快照(误判时回滚)
    // 系统/CSR(③):效应在 commit 边界。
    int              csr_idx = 0;
    uint64_t         sys_imm = 0;        // CSRW 写入值
  };

  explicit Rob(size_t size) : Module("Rob"), rob_(size), size_(size) {}

  bool   full() const { return count_ >= size_; }
  bool   empty() const { return count_ == 0; }
  size_t count() const { return count_; }

  int    alloc() { int idx = static_cast<int>((head_ + count_) % size_); ++count_; return idx; }
  Entry& at(int idx) { return rob_[idx]; }
  Entry& head() { return rob_[head_]; }
  void   pop_head() { rob_[head_].valid = false; head_ = (head_ + 1) % size_; --count_; }

  // squash:回收分支之后(更年轻)的条目,归还其 phys_dst 到 free list,截断 count。
  // 分支条目本身(位置 k)存活。
  void squash(int branch_idx, FreeList& fl) {
    size_t k = (static_cast<size_t>(branch_idx) - head_ + size_) % size_;
    for (size_t pos = k + 1; pos < count_; ++pos) {
      Entry& e = rob_[(head_ + pos) % size_];
      if (e.phys_dst >= 0) fl.free(e.phys_dst);
      e.valid = false;
    }
    count_ = k + 1;
  }

  // 精确中断/异常:清空全部在飞条目,归还所有 phys_dst(RAT 由调用方回滚到 RRAT)。
  void squash_all(FreeList& fl) {
    for (size_t pos = 0; pos < count_; ++pos) {
      Entry& e = rob_[(head_ + pos) % size_];
      if (e.phys_dst >= 0) fl.free(e.phys_dst);
      e.valid = false;
    }
    count_ = 0;
  }

 private:
  std::vector<Entry> rob_;
  size_t             head_ = 0, count_ = 0, size_;
};

}  // namespace ace
