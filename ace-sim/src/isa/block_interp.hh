// ace-sim/isa: DBT basic-block 解释器(⑦)—— 功能后端从逐指令解释升级为块级执行,加速 fast-forward。
//
// 思路(动态二进制翻译):把指令流按 basic block(直线段 + 一条终结指令)切分,按入口 PC 缓存"翻译"结果
// (块边界)。循环体的块只翻译(扫描边界)一次、复用多次执行 —— 摊销边界判定。指令语义复用
// FunctionalBackend::apply_inst(**单一来源**)-> 与逐指令解释逐位一致(difftest 护栏)。
#pragma once
#include <cstdint>
#include <unordered_map>
#include "isa/inst.hh"
#include "isa/functional.hh"

namespace ace {

class BlockInterpreter {
 public:
  BlockInterpreter(const Program& prog, std::vector<uint64_t> init_regs, bool mmu_on = false)
      : prog_(prog), mmu_on_(mmu_on) { st_.regs = std::move(init_regs); }

  struct Block { uint64_t start = 0; uint64_t term = 0; };  // body = [start, term);终结 = prog[term]

  // 执行至多 budget 条动态指令。块内直线体不再逐条判终结(边界已缓存)。
  uint64_t run(uint64_t budget) {
    uint64_t n = 0;
    while (n < budget && !st_.halted && st_.pc < prog_.size()) {
      const Block& b = block_at(st_.pc);
      while (st_.pc < b.term && n < budget) {   // 直线体:边界已知,直接跑
        FunctionalBackend::apply_inst(prog_[st_.pc], st_, mmu_on_); ++n; ++insts_;
      }
      if (n >= budget) break;
      FunctionalBackend::apply_inst(prog_[b.term], st_, mmu_on_); ++n; ++insts_;  // 终结指令自设 pc
      ++block_execs_;
    }
    if (st_.pc >= prog_.size()) st_.halted = true;
    return n;
  }

  const FuncState& state() const { return st_; }
  uint64_t translations() const { return translations_; }  // 块翻译(边界扫描)次数
  uint64_t block_execs()  const { return block_execs_; }   // 块执行次数
  uint64_t insts()        const { return insts_; }
  size_t   cached_blocks() const { return cache_.size(); }

 private:
  const Block& block_at(uint64_t pc) {
    auto it = cache_.find(pc);
    if (it != cache_.end()) return it->second;          // 命中翻译缓存(循环复用)
    uint64_t t = pc;                                     // 翻译:扫到首个终结指令
    while (t < prog_.size() && !is_terminator(prog_[t].fu)) ++t;
    if (t >= prog_.size()) t = prog_.size() - 1;         // 无终结(落尾):以末条收束
    ++translations_;
    return cache_.emplace(pc, Block{pc, t}).first->second;
  }

  const Program&                      prog_;
  FuncState                           st_;
  bool                                mmu_on_;
  std::unordered_map<uint64_t, Block> cache_;             // 翻译块缓存(入口 PC -> 块)
  uint64_t translations_ = 0, block_execs_ = 0, insts_ = 0;
};

}  // namespace ace
