// ace-sim/mem: 多级内存系统 —— L1D + L2 + DRAM(组相联 + LRU + MSHR)。
// 对应 gem5 classic memory system(BaseCache×N + MSHR + MemCtrl)。是 SimpleMemory 的可插拔替代:
// 同一 MemPort 接口,值来自可写后备内存(与 ref_model 逐位一致),延迟来自 cache 层级走查。
// MSHR 限制并发 miss(内存级并行 MLP);MSHR 满 -> load 端口 backpressure。
#pragma once
#include <unordered_map>
#include "hw/queue.hh"
#include "mem/cache.hh"
#include "mem/mem_req.hh"
#include "mem/simple_mem.hh"  // 复用 data_at(与 ref_model 同一初始内容公式)
#include "sim/component.hh"

namespace ace {

class SimContext;

struct MemSysConfig {
  size_t   port_capacity = 8;
  uint32_t port_width = 2;
  Cycle    l1_lat = 2, l2_lat = 12, dram_lat = 100;   // 逐级累加延迟
  size_t   l1_sets = 64,  l1_ways = 4;                // 16KB(64×4×64B)
  size_t   l2_sets = 512, l2_ways = 8;                // 256KB
  size_t   line = 64;
  uint32_t mshr_entries = 8;                          // 并发 DRAM miss 上限(MLP)
};

class MemSystem : public Component, public MemPort {
 public:
  explicit MemSystem(MemSysConfig cfg = {})
      : cfg_(cfg), in_(cfg.port_capacity),
        l1_("L1D", cfg.l1_sets, cfg.l1_ways, cfg.line),
        l2_("L2", cfg.l2_sets, cfg.l2_ways, cfg.line) {}

  const char* name() const override { return "MemSystem"; }
  bool eval(Phase phase, SimContext& ctx) override;

  // MemPort:load 走 send/响应;store drain 走 write(写后备 + write-allocate 进 cache)。
  bool can_send() const override { return in_.can_push(); }
  void send(const MemReq& req) override { in_.push(req); }
  void write(uint64_t addr, uint64_t data) override {
    backing_[addr] = data;
    l2_.access(addr);
    l1_.access(addr);  // write-allocate
  }

  uint64_t read(uint64_t addr) const {
    auto it = backing_.find(addr);
    return it != backing_.end() ? it->second : SimpleMemory::data_at(addr);
  }
  uint64_t peek(uint64_t addr) const { return read(addr); }

  const Cache& l1() const { return l1_; }
  const Cache& l2() const { return l2_; }
  uint64_t dram_accesses() const { return dram_; }

 private:
  MemSysConfig                           cfg_;
  BoundedQueue<MemReq>                   in_;
  std::unordered_map<uint64_t, uint64_t> backing_;
  Cache                                  l1_, l2_;
  uint32_t                               mshr_used_ = 0;
  uint64_t                               dram_ = 0;
};

}  // namespace ace
