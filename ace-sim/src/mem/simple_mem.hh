// ace-sim: 简单内存 —— cache 命中/未命中延迟模型(V1)。
// 命中 -> CacheResponse @ +hit_latency;未命中(DRAM 区) -> DramResponse @ +dram_latency。
// 只在有请求时活跃;处理完请求即睡眠(支持 time-skip)。
#pragma once
#include <unordered_map>
#include "hw/queue.hh"
#include "mem/mem_req.hh"
#include "sim/component.hh"

namespace ace {

class SimContext;

struct MemConfig {
  size_t port_capacity = 4;   // 输入请求队列容量(满 -> backpressure)
  uint32_t port_width  = 1;   // 每周期可受理的请求数
  Cycle  hit_latency   = 3;   // cache 命中延迟
  Cycle  dram_latency  = 200; // DRAM 未命中延迟
  uint64_t dram_base   = 0x80000000ull;  // >= 此地址视为未命中(走 DRAM)
};

class SimpleMemory : public Component, public MemPort {
 public:
  explicit SimpleMemory(MemConfig cfg = {}) : cfg_(cfg), in_(cfg.port_capacity) {}

  const char* name() const override { return "SimpleMemory"; }
  bool eval(Phase phase, SimContext& ctx) override;

  // MemPort:
  bool can_send() const override { return in_.can_push(); }
  void send(const MemReq& req) override { in_.push(req); }
  void write(uint64_t addr, uint64_t data) override { backing_[addr] = data; }  // store 落存

  size_t pending() const { return in_.size(); }

  // 确定性初始"内存内容";已写地址以 backing_ 覆盖。便于端到端校验。
  static uint64_t data_at(uint64_t addr) { return addr ^ 0xdeadbeefcafef00dull; }
  uint64_t read(uint64_t addr) const {
    auto it = backing_.find(addr);
    return it != backing_.end() ? it->second : data_at(addr);
  }
  uint64_t peek(uint64_t addr) const { return read(addr); }  // 观测:最终内存值

  uint64_t hits() const { return hits_; }
  uint64_t misses() const { return misses_; }

 private:
  MemConfig                              cfg_;
  BoundedQueue<MemReq>                   in_;
  std::unordered_map<uint64_t, uint64_t> backing_;  // 已写地址覆盖层(word 粒度)
  uint64_t                               hits_ = 0;
  uint64_t                               misses_ = 0;
};

}  // namespace ace
