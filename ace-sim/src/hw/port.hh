// ace-sim/hw: RTL 式端口 —— 模块间数据流连接(gem5 风格)。
//
// 顶层持有 Wire(网),把生产者 Out 与消费者 In 用 `out >> in` 绑定到同一 Wire。
//  - Wire<T>:组合网。生产者当拍写、消费者当拍读(=组合连线);要求生产者先于消费者 eval。
//  - 寄存边界(cur 延迟)用 hw/reg.hh 的 Reg<T> 表达,不在此处。
// 纯组合"输出=输入函数"的叶子(*Gate)可直接用方法,不必强套端口;端口用于真正的阶段间数据流。
#pragma once

namespace ace {

template <typename T>
struct Wire {
  T value{};
};

template <typename T>
class Out {
 public:
  void bind(Wire<T>* w) { w_ = w; }
  void drive(const T& v) { w_->value = v; }   // 生产者写(组合)
  bool connected() const { return w_ != nullptr; }
 private:
  Wire<T>* w_ = nullptr;
};

template <typename T>
class In {
 public:
  void bind(const Wire<T>* w) { w_ = w; }
  const T& get() const { return w_->value; }  // 消费者读(组合,当拍)
  bool connected() const { return w_ != nullptr; }
 private:
  const Wire<T>* w_ = nullptr;
};

// 连接语法糖:out >> in(经一根 Wire)。Wire 由顶层拥有(生命周期覆盖两端)。
template <typename T>
inline void connect(Out<T>& o, In<T>& i, Wire<T>* w) {
  o.bind(w);
  i.bind(w);
}

// ready/valid 通道:fire = valid && ready;跨模块背压载体(不变量 #7)。
template <typename T>
struct ReadyValid {
  bool valid = false;
  bool ready = false;
  T    data{};
  bool fire() const { return valid && ready; }
};

}  // namespace ace
