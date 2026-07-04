#include "mem/simple_mem.hh"
#include "sim/context.hh"

namespace ace {

bool SimpleMemory::eval(Phase phase, SimContext& ctx) {
  if (phase != Phase::Eval) return false;

  bool progressed = false;
  for (uint32_t i = 0; i < cfg_.port_width && in_.can_pop(); ++i) {
    MemReq req = in_.pop();
    bool miss = (req.addr >= cfg_.dram_base);
    Cycle lat = miss ? cfg_.dram_latency : cfg_.hit_latency;
    if (miss) ++misses_; else ++hits_;

    Event ev;
    ev.when     = ctx.cur_cycle + lat + req.extra_latency;  // +TLB miss 页表 walk(④)
    ev.target   = req.requester;
    ev.kind     = miss ? EventKind::DramResponse : EventKind::CacheResponse;
    ev.epoch    = req.epoch;
    ev.payload0 = req.dyn_id;
    ev.payload1 = read(req.addr);  // 含已落存的 store(backing_ 覆盖层)
    ev.payload2 = req.tag;         // 回显请求方标签(如 ROB idx)
    ctx.schedule(ev);
    progressed = true;
  }

  // 还有积压请求 -> 下周期继续受理(1 req/cycle 的端口吞吐)。
  if (in_.can_pop()) ctx.activate(id, Phase::Eval);
  return progressed;
}

}  // namespace ace
