// ace-sim: 有界队列 —— backpressure 的基本载体(不变量 #7)。
#pragma once
#include <cassert>
#include <cstddef>
#include <deque>

namespace ace {

template <typename T>
class BoundedQueue {
 public:
  explicit BoundedQueue(size_t capacity) : cap_(capacity) {}

  bool   can_push() const { return q_.size() < cap_; }
  bool   can_pop()  const { return !q_.empty(); }
  bool   full()     const { return q_.size() >= cap_; }
  bool   empty()    const { return q_.empty(); }
  size_t size()     const { return q_.size(); }
  size_t capacity() const { return cap_; }

  void push(const T& x) { assert(can_push()); q_.push_back(x); }
  const T& front() const { assert(can_pop()); return q_.front(); }
  T pop() { assert(can_pop()); T x = std::move(q_.front()); q_.pop_front(); return x; }

 private:
  std::deque<T> q_;
  size_t        cap_;
};

}  // namespace ace
