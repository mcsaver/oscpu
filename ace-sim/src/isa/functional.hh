// ace-sim/isa: 功能后端(functional backend)—— 与 timing engine 分层的功能真源。
//
// 单一实现的指令语义,同时服务:
//   ① 差分对拍金标准(ref_model 委托本类);
//   ② V5 fast-forward:功能快进跳过无趣前缀,再把架构状态种子进 detailed(周期级)核。
// "0 周期"执行:纯功能,不建流水线。可界定条数 / 界定到某 PC,支持快进-详细模式切换。
#pragma once
#include <cstdint>
#include <unordered_map>
#include <utility>
#include <vector>
#include "isa/inst.hh"
#include "mem/mmu.hh"
#include "mem/simple_mem.hh"

namespace ace {

struct FuncState {
  std::vector<uint64_t>                  regs;   // 架构寄存器
  std::unordered_map<uint64_t, uint64_t> mem;    // 被写过的地址(其余取 data_at)
  std::vector<uint64_t>                  csr = std::vector<uint64_t>(CSR_COUNT, 0);  // ③ CSR
  size_t                                 pc = 0; // 架构 PC(下标)
  bool                                   halted = false;
};

class FunctionalBackend {
 public:
  FunctionalBackend(const Program& prog, std::vector<uint64_t> init_regs, bool mmu_on = false)
      : prog_(prog), mmu_on_(mmu_on) { st_.regs = std::move(init_regs); }

  // 执行至多 budget 条动态指令(遇 HALT / 跑出程序尾提前停);返回实际执行条数。
  uint64_t run(uint64_t budget) {
    uint64_t n = 0;
    while (n < budget && !st_.halted && st_.pc < prog_.size()) { step_one(); ++n; }
    if (st_.pc >= prog_.size()) st_.halted = true;
    return n;
  }

  // 功能快进:执行到 PC 首次等于 target(= ROI 入口)或 halt / 越尾 / 耗尽 budget。
  uint64_t run_until_pc(size_t target, uint64_t budget) {
    uint64_t n = 0;
    while (n < budget && !st_.halted && st_.pc < prog_.size() && st_.pc != target) {
      step_one(); ++n;
    }
    if (st_.pc >= prog_.size()) st_.halted = true;
    return n;
  }

  const FuncState& state() const { return st_; }
  uint64_t         insts() const { return insts_; }  // 累计功能执行条数

  // 指令语义**单一来源**:per-inst 解释(step_one)与 block 解释(DBT ⑦)共用此静态函数。
  // 就地改 st(含 pc)。straight-line 指令 ++pc;终结指令自设 pc。
  static void apply_inst(const Inst& in, FuncState& st, bool mmu_on) {
    auto rd = [&](int r) -> uint64_t { return r >= 0 ? st.regs[r] : 0; };
    auto mrd = [&](uint64_t a) -> uint64_t {
      auto it = st.mem.find(a);
      return it != st.mem.end() ? it->second : SimpleMemory::data_at(a);
    };
    switch (in.fu) {
      case FuType::ALU:    if (in.dst >= 0) st.regs[in.dst] = rd(in.src0) + rd(in.src1) + in.imm; ++st.pc; break;
      case FuType::MUL:    if (in.dst >= 0) st.regs[in.dst] = rd(in.src0) * rd(in.src1); ++st.pc; break;
      case FuType::DIV:    if (in.dst >= 0) { uint64_t b = rd(in.src1); st.regs[in.dst] = b ? rd(in.src0) / b : 0; } ++st.pc; break;
      case FuType::LOAD:   if (in.dst >= 0) st.regs[in.dst] = mrd(mmu_translate(rd(in.src0) + in.imm, mmu_on)); ++st.pc; break;
      case FuType::STORE:  st.mem[mmu_translate(rd(in.src0) + in.imm, mmu_on)] = rd(in.src1); ++st.pc; break;
      case FuType::BRANCH: { bool taken = in.cond == 0 ? (rd(in.src0) == rd(in.src1))
                                                       : (rd(in.src0) != rd(in.src1));
                             st.pc = taken ? in.imm : st.pc + 1; break; }
      case FuType::JUMP:   st.pc = in.imm; break;
      // ---- FP(② FP 数据通路),host double 语义,golden 与详细核逐位同源 ----
      case FuType::FADD:   if (in.dst >= 0) st.regs[in.dst] = fbits(f64(rd(in.src0)) + f64(rd(in.src1))); ++st.pc; break;
      case FuType::FMUL:   if (in.dst >= 0) st.regs[in.dst] = fbits(f64(rd(in.src0)) * f64(rd(in.src1))); ++st.pc; break;
      case FuType::FDIV:   if (in.dst >= 0) st.regs[in.dst] = fbits(f64(rd(in.src0)) / f64(rd(in.src1))); ++st.pc; break;
      case FuType::FCVTIF: if (in.dst >= 0) st.regs[in.dst] = fbits(static_cast<double>(static_cast<int64_t>(rd(in.src0)))); ++st.pc; break;
      case FuType::FCVTFI: if (in.dst >= 0) st.regs[in.dst] = static_cast<uint64_t>(static_cast<int64_t>(f64(rd(in.src0)))); ++st.pc; break;
      case FuType::FCMP:   if (in.dst >= 0) st.regs[in.dst] = (f64(rd(in.src0)) < f64(rd(in.src1))) ? 1 : 0; ++st.pc; break;
      // ---- 系统/CSR(③)----
      case FuType::CSRW:   st.csr[in.cond] = in.imm; ++st.pc; break;
      case FuType::CSRR:   if (in.dst >= 0) st.regs[in.dst] = st.csr[in.cond]; ++st.pc; break;
      case FuType::ECALL:  st.csr[CSR_MEPC] = st.pc + 1; st.csr[CSR_MCAUSE] = CAUSE_ECALL;
                           st.pc = st.csr[CSR_MTVEC]; break;
      case FuType::MRET:   st.pc = st.csr[CSR_MEPC]; break;
      // ---- 调用/返回(⑤)----
      case FuType::JAL:    { if (in.dst >= 0) { st.regs[in.dst] = st.pc + 1; } st.pc = in.imm; break; }
      case FuType::JALR:   { uint64_t t = rd(in.src0) + in.imm;
                             if (in.dst >= 0) { st.regs[in.dst] = st.pc + 1; } st.pc = t; break; }
      case FuType::STA: case FuType::STD: ++st.pc; break;  // 详细核微 op,功能模型不可见(占位)
      case FuType::HALT:   st.halted = true; break;
    }
  }

 private:
  void step_one() { apply_inst(prog_[st_.pc], st_, mmu_on_); ++insts_; }

  const Program& prog_;
  FuncState      st_;
  bool           mmu_on_ = false;  // ④ 地址翻译开关
  uint64_t       insts_ = 0;
};

}  // namespace ace
