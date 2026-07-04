// ace-sim/core/mmu: 地址翻译旁视缓冲 TLB(组相联 + LRU),对应 npc Sv39Tlb。
// 缓存 VPN->PPN 翻译。命中 = 快;未命中 = 触发页表 walk(加 walk 延迟)后填充。
// **纯时序/统计**:翻译的**值**由 mmu_translate() 确定性给出(与 golden 一致),本模块只决定"是否需要 walk"。
#pragma once
#include <cstdint>
#include <vector>
#include "hw/module.hh"
#include "mem/mmu.hh"

namespace ace {

class Tlb : public Module {
 public:
  Tlb(size_t sets, size_t ways) : Module("Tlb"),
      sets_(sets), ways_(ways), vpn_(sets * ways, 0), valid_(sets * ways, 0), lru_(sets * ways, 0) {}

  // 访问一个 VPN:命中返回 true(快);未命中按 LRU 填充并返回 false(需页表 walk)。
  bool access(uint64_t vpn) {
    size_t base = static_cast<size_t>(vpn % sets_) * ways_;
    uint64_t tag = vpn / sets_;
    for (size_t w = 0; w < ways_; ++w)
      if (valid_[base + w] && vpn_[base + w] == tag) { touch(base + w); ++hits_; return true; }
    ++misses_;
    size_t victim = 0;
    uint64_t oldest = ~0ull;
    for (size_t w = 0; w < ways_; ++w) {
      if (!valid_[base + w]) { victim = w; break; }
      if (lru_[base + w] < oldest) { oldest = lru_[base + w]; victim = w; }
    }
    valid_[base + victim] = 1;
    vpn_[base + victim] = tag;
    touch(base + victim);
    return false;
  }

  void flush() { std::fill(valid_.begin(), valid_.end(), 0); }  // sfence.vma 等(未来)

  uint64_t hits() const { return hits_; }
  uint64_t misses() const { return misses_; }

 private:
  void touch(size_t idx) { lru_[idx] = ++clock_; }
  size_t                sets_, ways_;
  std::vector<uint64_t> vpn_;
  std::vector<uint8_t>  valid_;
  std::vector<uint64_t> lru_;
  uint64_t              clock_ = 0, hits_ = 0, misses_ = 0;
};

}  // namespace ace
