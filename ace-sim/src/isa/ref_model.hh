// ace-sim/isa: 参考模型(差分对拍金标准)。
// 语义**单一来源** = FunctionalBackend(functional.hh);本文件只是"跑到终止"的便捷封装。
// 这保证 V5 fast-forward 用的功能模型与 difftest 金标准逐位一致(同一份代码)。
#pragma once
#include <cstdint>
#include <unordered_map>
#include <vector>
#include "isa/functional.hh"
#include "isa/inst.hh"

namespace ace {

struct RefResult {
  std::vector<uint64_t>                  regs;
  std::unordered_map<uint64_t, uint64_t> mem;  // 被写过的地址
};

// 按控制流跑到终止(HALT / 越尾),返回最终寄存器 + 内存。mmu_on:开地址翻译(④)。
inline RefResult ref_run_full(const Program& prog, const std::vector<uint64_t>& init, bool mmu_on = false) {
  FunctionalBackend fb(prog, init, mmu_on);
  fb.run(100000000ull);  // cap 防畸形程序死循环
  return {fb.state().regs, fb.state().mem};
}

inline std::vector<uint64_t> ref_run(const Program& prog, const std::vector<uint64_t>& init) {
  return ref_run_full(prog, init).regs;
}

}  // namespace ace
