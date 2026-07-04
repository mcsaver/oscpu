// ace-sim: 时序状态 cur/next 分离(不变量 #4)。
//
// 纪律:eval 阶段只读 cur()、只写 write(next);写过 next 的组件必须
//       activate(self, Phase::EdgeCommit),EdgeCommit 阶段调用 commit() 完成 cur=next。
//       (Reg 本身无 context,故自激由持有它的组件负责,见 DESIGN.md §3。)
#pragma once
#include <utility>

namespace ace {

template <typename T>
class Reg {
 public:
  Reg() = default;
  explicit Reg(const T& init) : cur_(init), next_(init) {}

  const T& cur() const { return cur_; }        // eval 只读
  T& next() { dirty_ = true; return next_; }   // eval 写(取引用即视为将写)
  void write(const T& v) { next_ = v; dirty_ = true; }

  bool dirty() const { return dirty_; }

  // EdgeCommit:提交 next -> cur。
  void commit() {
    if (dirty_) {
      cur_ = next_;
      dirty_ = false;
    }
  }

 private:
  T    cur_{};
  T    next_{};
  bool dirty_ = false;  // 本周期是否写过 next
};

}  // namespace ace
