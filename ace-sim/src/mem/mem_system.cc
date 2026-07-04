#include "mem/mem_system.hh"
#include "sim/context.hh"

namespace ace {

bool MemSystem::eval(Phase phase, SimContext& ctx) {
  // Wakeup:自调度的 MSHR-free 事件到期 -> 释放 MSHR 槽,重激活 Eval 处理积压。
  if (phase == Phase::Wakeup) {
    size_t n = inbox.size();
    for (size_t i = 0; i < n && mshr_used_ > 0; ++i) --mshr_used_;
    inbox.clear();
    if (n > 0) { ctx.activate(id, Phase::Eval); return true; }
    return false;
  }
  if (phase != Phase::Eval) return false;

  bool progressed = false;
  for (uint32_t i = 0; i < cfg_.port_width && in_.can_pop(); ++i) {
    MemReq req = in_.front();
    uint64_t addr = req.addr;

    // 非破坏性判层级(决定延迟 + 是否需 MSHR),再真访问更新 stats/LRU/fill。
    bool l1h = l1_.probe(addr);
    bool l2h = l1h || l2_.probe(addr);
    Cycle lat;
    bool  is_dram = false;
    if (l1h)      lat = cfg_.l1_lat;
    else if (l2h) lat = cfg_.l1_lat + cfg_.l2_lat;
    else        { lat = cfg_.l1_lat + cfg_.l2_lat + cfg_.dram_lat; is_dram = true; }

    if (is_dram && mshr_used_ >= cfg_.mshr_entries) break;  // MSHR 满 -> backpressure(靠 free 事件重激活)

    in_.pop();
    l1_.access(addr);              // 更新 L1 命中/未命中 + LRU + 填充
    if (!l1h) l2_.access(addr);    // L1 miss 才查/填 L2

    if (is_dram) {
      ++mshr_used_;
      ++dram_;
      Event free_ev;              // 自调度:miss 数据返回时释放 MSHR
      free_ev.when = ctx.cur_cycle + lat;
      free_ev.target = id;
      free_ev.kind = EventKind::DmaComplete;
      ctx.schedule(free_ev);
    }

    Event resp;                    // 回 CPU 的响应(值来自后备内存)
    resp.when = ctx.cur_cycle + lat + req.extra_latency;  // +TLB miss 页表 walk(④)
    resp.target = req.requester;
    resp.kind = EventKind::CacheResponse;
    resp.payload0 = req.dyn_id;
    resp.payload1 = read(addr);
    resp.payload2 = req.tag;
    ctx.schedule(resp);
    ctx.activate(req.requester, Phase::Eval);  // 端口释放 -> 通知请求方(睡眠安全律推论2)
    progressed = true;
  }

  // 还有积压且 MSHR 有余 -> 下周期继续;MSHR 满则靠 free 事件重激活(不 busy-wait)。
  if (in_.can_pop() && mshr_used_ < cfg_.mshr_entries) ctx.activate(id, Phase::Eval);
  return progressed;
}

}  // namespace ace
