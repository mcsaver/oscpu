// ace-sim/mem: 组相联 cache(标签阵列 + LRU 替换)。数据存后备内存,本模块只建"命中/未命中 + 延迟"。
// 对应 gem5 classic memory 的 BaseCache;多级由 MemSystem 串联。
#pragma once
#include <cstdint>
#include <vector>
#include "hw/module.hh"

namespace ace {

class Cache : public Module {
 public:
  Cache(const char* name, size_t sets, size_t ways, size_t line_bytes)
      : Module(name), sets_(sets), ways_(ways), line_(line_bytes),
        tag_(sets * ways, 0), valid_(sets * ways, 0), lru_(sets * ways, 0) {}

  // 访问一个地址:命中返回 true;未命中则按 LRU 选牺牲 way 填充并返回 false。均更新 LRU。
  bool access(uint64_t addr) {
    uint64_t line = addr / line_;
    size_t   set = static_cast<size_t>(line % sets_);
    uint64_t tag = line / sets_;
    size_t   base = set * ways_;
    for (size_t w = 0; w < ways_; ++w)
      if (valid_[base + w] && tag_[base + w] == tag) { touch(base + w); ++hits_; return true; }
    ++misses_;
    size_t victim = 0;
    uint64_t oldest = ~0ull;
    for (size_t w = 0; w < ways_; ++w) {
      if (!valid_[base + w]) { victim = w; break; }         // 空 way 优先
      if (lru_[base + w] < oldest) { oldest = lru_[base + w]; victim = w; }
    }
    valid_[base + victim] = 1;
    tag_[base + victim] = tag;
    touch(base + victim);
    return false;
  }

  // 非破坏性命中查询(不更新 LRU / 不填充);供 MemSystem 在 MSHR 决策前判层级。
  bool probe(uint64_t addr) const {
    uint64_t line = addr / line_;
    size_t   base = static_cast<size_t>(line % sets_) * ways_;
    uint64_t tag = line / sets_;
    for (size_t w = 0; w < ways_; ++w)
      if (valid_[base + w] && tag_[base + w] == tag) return true;
    return false;
  }

  uint64_t hits() const { return hits_; }
  uint64_t misses() const { return misses_; }
  double   hit_rate() const { uint64_t t = hits_ + misses_; return t ? double(hits_) / t : 0.0; }

 private:
  void touch(size_t idx) { lru_[idx] = ++clock_; }
  size_t                sets_, ways_, line_;
  std::vector<uint64_t> tag_;
  std::vector<uint8_t>  valid_;
  std::vector<uint64_t> lru_;
  uint64_t              clock_ = 0, hits_ = 0, misses_ = 0;
};

}  // namespace ace
