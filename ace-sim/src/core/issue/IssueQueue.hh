// ace-sim/core/issue: 发射队列(对应 npc OooIntIssueQueue)。
// 拥有 IQ 条目池 + 每 FU 类就绪列表 + 物理寄存器等待表;负责唤醒、就绪登记、squash 重建。
// 选择/发射的执行部分(读寄存器/算结果/发事件)由编排者(CpuTop)按类做,经 ready_list/at/free_slot 访问。
#pragma once
#include <cstdint>
#include <vector>
#include "isa/inst.hh"
#include "core/regfile/PhysRegFile.hh"
#include "hw/module.hh"

namespace ace {

class IssueQueue : public Module {
 public:
  struct Entry {
    bool     valid = false, queued = false;  // queued=已进就绪列表(防重复入队)
    uint64_t dyn_id = 0;
    FuType   fu = FuType::ALU;
    int      src0 = -1, src1 = -1;  // 物理源寄存器
    bool     s0r = false, s1r = false;
    int      dst = -1;              // 物理目的寄存器
    int      rob_idx = -1;
    uint64_t imm = 0;
    int      cond = 0;             // 分支条件
  };

  IssueQueue(size_t size, int num_phys)
      : Module("IssueQueue"), iq_(size), waiting_(num_phys) {
    for (int s = static_cast<int>(size) - 1; s >= 0; --s) iq_free_.push_back(s);
  }

  bool   full() const { return iq_free_.empty(); }
  size_t free_count() const { return iq_free_.size(); }  // store 裂 STA/STD 需 2 槽(⑥)

  // dispatch 分配并登记一条(s0r/s1r 由调用方按 pregs 就绪算好传入)。
  void insert(uint64_t dyn_id, FuType fu, int src0, int src1, bool s0r, bool s1r,
              int dst, int rob_idx, uint64_t imm, int cond) {
    int slot = iq_free_.back();
    iq_free_.pop_back();
    Entry& e = iq_[slot];
    e = Entry{};
    e.valid = true; e.dyn_id = dyn_id; e.fu = fu;
    e.src0 = src0; e.src1 = src1; e.s0r = s0r; e.s1r = s1r;
    e.dst = dst; e.rob_idx = rob_idx; e.imm = imm; e.cond = cond;
    if (e.s0r && e.s1r) { e.queued = true; ready_[ru_index(fu)].push_back(slot); }
    else {
      if (!e.s0r) waiting_[src0].push_back(slot);
      if (!e.s1r && src1 != src0) waiting_[src1].push_back(slot);
    }
  }

  // 供编排者选择/发射
  std::vector<int>& ready_list(int cls) { return ready_[cls]; }
  Entry&            at(int slot) { return iq_[slot]; }
  void              free_slot(int slot) { iq_[slot].valid = false; iq_free_.push_back(slot); }

  // 物理寄存器就绪 -> 推进依赖者;两源皆就绪则入就绪列表。
  void wakeup(int phys) {
    std::vector<int>& list = waiting_[phys];
    for (int slot : list) {
      Entry& e = iq_[slot];
      if (!e.valid) continue;  // 防御:已发射的陈旧引用
      if (e.src0 == phys) e.s0r = true;
      if (e.src1 == phys) e.s1r = true;
      if (e.s0r && e.s1r && !e.queued) { e.queued = true; ready_[ru_index(e.fu)].push_back(slot); }
    }
    list.clear();
  }

  // squash:回收更年轻(dyn_id > branch_dyn)条目,并从存活条目按 pregs 就绪重建(消除陈旧 slot 引用)。
  void squash(uint64_t branch_dyn, const PhysRegFile& pregs) {
    for (int slot = 0; slot < static_cast<int>(iq_.size()); ++slot) {
      if (iq_[slot].valid && iq_[slot].dyn_id > branch_dyn) {
        iq_[slot].valid = false;
        iq_free_.push_back(slot);
      }
    }
    rebuild(pregs);
  }

 private:
  static int ru_index(FuType t) {  // 就绪列表下标:ALU/BRANCH0 MUL1 DIV2 STORE3 LOAD4 FP5
    switch (t) {
      case FuType::ALU: case FuType::BRANCH: case FuType::JALR: return 0;  // JALR 用 Alu FU 算目标(⑤)
      case FuType::MUL:   return 1;
      case FuType::DIV:   return 2;
      case FuType::STORE: case FuType::STA: case FuType::STD: return 3;  // store 及其裂出微 op
      case FuType::LOAD:  return 4;
      case FuType::FADD: case FuType::FMUL: case FuType::FDIV:
      case FuType::FCVTIF: case FuType::FCVTFI: case FuType::FCMP: return 5;
      default:            return 0;
    }
  }

  void rebuild(const PhysRegFile& pregs) {
    for (int c = 0; c < 6; ++c) ready_[c].clear();
    for (auto& w : waiting_) w.clear();
    for (int slot = 0; slot < static_cast<int>(iq_.size()); ++slot) {
      Entry& e = iq_[slot];
      if (!e.valid) continue;
      e.s0r = (e.src0 < 0) || pregs.ready(e.src0);
      e.s1r = (e.src1 < 0) || pregs.ready(e.src1);
      e.queued = false;
      if (e.s0r && e.s1r) { e.queued = true; ready_[ru_index(e.fu)].push_back(slot); }
      else {
        if (!e.s0r) waiting_[e.src0].push_back(slot);
        if (!e.s1r && e.src1 != e.src0) waiting_[e.src1].push_back(slot);
      }
    }
  }

  std::vector<Entry>            iq_;
  std::vector<int>              iq_free_;
  std::vector<int>              ready_[6];
  std::vector<std::vector<int>> waiting_;
};

}  // namespace ace
