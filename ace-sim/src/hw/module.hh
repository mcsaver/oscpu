// ace-sim/hw: 硬件模块基类(类 Verilator/RTL 结构)。
//
// 约定(镜像 npc,见 design/arch/engineering.md §3):
//  - 每个硬件模块 = 一个继承 Module 的类,一文件一模块,文件名 == 类名。
//  - 持状态的模块用 hw::Reg<T>(cur/next),在 tick() 里提交(= RTL 时钟沿)。
//  - 纯组合的"输出=输入与状态的函数"(npc 的 *Gate,如 predict/compute/disambiguate)
//    直接用**方法**表达(C++ 方法天然就是组合函数);跨阶段/寄存边界的数据流用 hw/port.hh 的
//    Out>>In 端口。
//  - 模块是 CpuTop 的子块;顶层 CpuTop 才是参与活动调度的 Component,负责实例化+连线+编排 phase。
#pragma once
#include <string>
#include <utility>

namespace ace {

class SimContext;

class Module {
 public:
  explicit Module(std::string name) : name_(std::move(name)) {}
  virtual ~Module() = default;

  const std::string& mod_name() const { return name_; }

  // 可选覆盖:comb() = 组合逻辑(读 _i/_q,写 _o/next);tick() = 时钟沿提交内部 Reg。
  // 不是所有模块都需要(纯组合叶子只暴露方法即可)。
  virtual void comb(SimContext&) {}
  virtual void tick() {}

 private:
  std::string name_;
};

}  // namespace ace
