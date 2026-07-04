// ace-sim/core/memory: store queue 兼 store buffer(对应 npc OooStoreQueue)。
// 程序序:dispatch alloc -> execute 拍回填地址/数据 -> commit 标 committed -> 按序 drain 落存。
// load 消歧 disambiguate():最年轻的更老同址 store 前递;任一更老 store 地址未知 -> 等待。
#pragma once
#include <cstdint>
#include <deque>
#include "hw/module.hh"
#include "mem/mem_req.hh"

namespace ace {

class StoreQueue : public Module {
 public:
  explicit StoreQueue(size_t cap) : Module("StoreQueue"), cap_(cap) {}

  bool full() const { return sq_.size() >= cap_; }
  bool empty() const { return sq_.empty(); }

  void alloc(uint64_t dyn_id, int rob_idx) { sq_.push_back({dyn_id, rob_idx, 0, 0, false, false, false}); }

  // STA/STD 分离(⑥):地址与数据各由一个微 op 回填,互相独立。返回该 store 是否**此刻**地址+数据俱全。
  bool execute_addr(uint64_t dyn_id, uint64_t addr) {
    for (Entry& s : sq_)
      if (s.dyn_id == dyn_id) { s.addr = addr; s.addr_ready = true; return s.data_ready; }
    return false;
  }
  bool execute_data(uint64_t dyn_id, uint64_t data) {
    for (Entry& s : sq_)
      if (s.dyn_id == dyn_id) { s.data = data; s.data_ready = true; return s.addr_ready; }
    return false;
  }
  void commit(uint64_t dyn_id) {  // 退休 -> 可落存
    for (Entry& s : sq_)
      if (s.dyn_id == dyn_id) { s.committed = true; return; }
  }

  bool front_committed() const { return !sq_.empty() && sq_.front().committed; }
  bool drain_one(MemPort* mem) {  // 落存队头一条(已提交且地址+数据俱全),返回是否落存
    if (sq_.empty() || !sq_.front().committed) return false;
    const Entry& f = sq_.front();
    if (!f.addr_ready || !f.data_ready) return false;  // 理论上 committed 蕴含俱全,防御性检查
    mem->write(f.addr, f.data);
    sq_.pop_front();
    return true;
  }

  void squash(uint64_t branch_dyn) {  // 丢弃更年轻(未提交)store
    while (!sq_.empty() && sq_.back().dyn_id > branch_dyn) sq_.pop_back();
  }

  // 精确中断/异常:只丢未提交 store,已提交(队首连续前缀)保留待落存(③)。
  void squash_uncommitted() {
    while (!sq_.empty() && !sq_.back().committed) sq_.pop_back();
  }

  // load 消歧(STA/STD 分离后更精确,⑥):
  //  - 任一更老 store **地址未知**(STA 未执行)-> 等待(保守,可能有隐藏同址 store);
  //  - 否则取**最年轻**更老同址 store:数据就绪(STD 已执行)-> 前递;数据未就绪 -> 等待;
  //  - 无同址 -> 走内存。
  // 关键:地址已知但**不同址**的 store 不再阻塞 load(旧模型要等整条 store) —— 地址/数据解耦的收益。
  void disambiguate(uint64_t ld_dyn_id, uint64_t addr,
                    bool& wait, bool& fwd, uint64_t& fwd_data) const {
    wait = false; fwd = false; fwd_data = 0;
    bool have = false, best_data_ready = false;
    uint64_t best_dyn = 0, best_data = 0;
    for (const Entry& s : sq_) {
      if (s.dyn_id >= ld_dyn_id) continue;         // 只看更老
      if (!s.addr_ready) { wait = true; continue; }  // 地址未知 -> 无法消歧
      if (s.addr == addr && (!have || s.dyn_id > best_dyn)) {
        have = true; best_dyn = s.dyn_id; best_data_ready = s.data_ready; best_data = s.data;
      }
    }
    if (wait) return;                  // 有地址未知的更老 store -> 保守等待
    if (have) {                        // 最年轻同址 store 决定 load 值
      if (best_data_ready) { fwd = true; fwd_data = best_data; }
      else wait = true;                // 同址但数据未就绪 -> 等 STD
    }
  }

 private:
  struct Entry {
    uint64_t dyn_id = 0;
    int      rob_idx = -1;
    uint64_t addr = 0, data = 0;
    bool     addr_ready = false;  // STA 已执行(⑥)
    bool     data_ready = false;  // STD 已执行(⑥)
    bool     committed = false;
  };
  std::deque<Entry> sq_;
  size_t            cap_;
};

}  // namespace ace
