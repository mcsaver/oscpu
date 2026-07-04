// ace-sim: V2 乱序核(rename + 物理寄存器 + issue queue + 完成驱动唤醒 + ROB 精确 commit)。
//
// 相对 V1(顺序 scoreboard 核)的本质飞跃:
//  - 寄存器重命名(RAT + free list + 物理寄存器堆)消除 WAR/WAW 假依赖;
//  - issue queue 乱序选择:younger 独立指令可越过 stalled 的 older 指令发射;
//  - 完成驱动唤醒:producer **完成**(非退休)即写物理寄存器 + 唤醒依赖者 -> 真正 OoO;
//  - ROB 保证**按序精确 commit**:completion ≠ commit(不变量 #2/#3)彻底落地。
//  - 睡眠安全律(DESIGN.md §5.1)继续遵守:结构冒险(FU II)用 CpuWake 兜底。
//
// V2 暂无投机(分支预测=V4),故 rename map 无需 checkpoint/RRAT 恢复;暂无 store(=V3 LSQ)。
#pragma once
#include <cstdint>
#include <deque>
#include <vector>
#include "hw/queue.hh"
#include "hw/resource.hh"
#include "core/frontend/Bpu.hh"
#include "core/frontend/Ras.hh"
#include "core/frontend/Fetch.hh"
#include "core/execute/Alu.hh"
#include "core/execute/MulDiv.hh"
#include "core/execute/BranchResolve.hh"
#include "core/execute/FpAlu.hh"
#include "core/control/CsrFile.hh"
#include "core/decode/Decode.hh"
#include "core/memory/LoadUnit.hh"
#include "core/mmu/Tlb.hh"
#include "core/rename/RenameMap.hh"
#include "core/rename/FreeList.hh"
#include "core/regfile/PhysRegFile.hh"
#include "core/issue/IssueQueue.hh"
#include "core/memory/StoreQueue.hh"
#include "core/dispatch/Rob.hh"
#include "isa/inst.hh"
#include "mem/mem_req.hh"
#include "sim/component.hh"

namespace ace {

class SimContext;

struct OooConfig {
  int      num_arch_regs  = 32;
  int      num_phys_regs  = 64;   // >= arch + rob_size
  size_t   fetch_queue_cap = 8;
  size_t   rob_size       = 32;
  size_t   iq_size        = 16;
  size_t   sq_size        = 8;    // store queue / store buffer 深度(V3)
  uint32_t fetch_width    = 4;
  uint32_t dispatch_width = 2;
  uint32_t issue_width    = 4;    // 每周期跨 FU 的发射总额度
  uint32_t commit_width   = 4;
  uint32_t drain_width    = 1;    // 每周期 store buffer 落存条数(V3)
  Cycle    fwd_latency    = 1;    // store->load 前递延迟(V3)
  size_t   bht_size       = 256;  // 分支预测表项数(V4)
  uint32_t ghist_bits     = 0;    // 0=bimodal;>0=gshare 全局历史位数(⑤)
  size_t   ras_depth      = 16;   // 返回地址栈深度(⑤)
  size_t   start_pc       = 0;    // 详细核起始 PC(V5:fast-forward 后从 ROI 入口续跑)
  FuDesc   alu{/*lat*/1,  /*ii*/1,  /*width*/2};
  FuDesc   mul{/*lat*/3,  /*ii*/1,  /*width*/2};
  FuDesc   div{/*lat*/20, /*ii*/20, /*width*/1};
  FuDesc   fp{/*lat*/3,   /*ii*/1,  /*width*/2};  // FP 全流水单元(② FP)
  uint32_t fdiv_lat = 16;                          // FDIV 完成延迟
  // ④ TLB/MMU:
  bool     mmu_on       = false;  // 开地址翻译(load/store 走 vaddr->paddr)
  size_t   tlb_sets     = 16;
  size_t   tlb_ways     = 4;
  uint32_t tlb_walk_lat = 20;     // TLB miss 页表 walk 额外延迟
};

class CpuTop : public Component {
 public:
  CpuTop(Program prog, MemPort* mem, CompId mem_id, OooConfig cfg = {});

  const char* name() const override { return "CpuTop"; }
  bool eval(Phase phase, SimContext& ctx) override;

  void kickoff(SimContext& ctx);
  void set_arch_reg(int r, uint64_t v);
  void set_csr(int idx, uint64_t v) { csr_.write(idx, v); }  // 预置 CSR(如 mtvec,③)

  // ---- 观测接口 ----
  uint64_t arch_reg(int r) const { return pregs_.value(rename_.phys(r)); }  // 最终架构值
  uint64_t fetched() const { return fetch_.fetched(); }
  uint64_t dispatched() const { return dispatched_; }
  uint64_t issued() const { return issued_; }
  uint64_t retired() const { return retired_; }
  bool     halted() const { return halted_; }
  uint64_t forwards() const { return forwards_; }          // store->load 前递次数
  uint64_t mem_loads() const { return mem_loads_; }        // 真正访存的 load 次数
  uint64_t stores_drained() const { return stores_drained_; }
  uint64_t branches() const { return branches_; }        // 已解析分支数
  uint64_t mispredicts() const { return mispredicts_; }  // 误判(触发 squash)数
  uint64_t squashes() const { return squashes_; }
  uint64_t traps() const { return traps_; }  // ECALL 精确 trap 次数(③)
  uint64_t irqs()  const { return irqs_; }   // 已服务异步中断次数(③)
  uint64_t tlb_hits()   const { return tlb_.hits(); }    // ④
  uint64_t tlb_misses() const { return tlb_.misses(); }
  uint64_t jalrs() const { return jalrs_; }                       // ⑤ JALR(间接跳转/返回)数
  uint64_t jalr_mispredicts() const { return jalr_mispredicts_; } // ⑤ RAS/间接目标误判数
  uint64_t calls() const { return calls_; }
  const std::vector<uint64_t>& completion_order() const { return completion_order_; }
  const std::vector<uint64_t>& commit_order() const { return commit_order_; }

 private:
  bool on_wakeup(SimContext& ctx);
  bool on_eval(SimContext& ctx);
  bool on_retire(SimContext& ctx);
  bool select_issue(SimContext& ctx);
  bool rename_dispatch(SimContext& ctx);

  // 投机恢复(V4);分支方向预测已抽出为 Bpu 模块(bpu_)。
  void resolve_branch(int rob_idx, bool actual_taken, SimContext& ctx);
  void resolve_jalr(int rob_idx, uint64_t actual_target, SimContext& ctx);  // 间接跳转/返回解析(⑤)
  void squash_after(int branch_rob_idx, uint64_t redirect_pc, SimContext& ctx);
  void take_interrupt(SimContext& ctx);  // 精确异步中断:squash 全体 + 回滚 RRAT + 跳 mtvec(③)

  Program   prog_;
  MemPort*  mem_;
  CompId    mem_id_;
  OooConfig cfg_;

  PhysRegFile          pregs_;      // 物理寄存器堆 + ready(模块)
  RenameMap            rename_;     // 推测 RAT(模块)
  RenameMap            rrat_;       // 已提交 RAT(RRAT):精确中断/异常回滚到此(③)
  FreeList             freelist_;   // 物理寄存器空闲列表(模块)

  Bpu                     bpu_;      // 分支方向预测器(模块,gshare 可选 ⑤)
  Ras                     ras_;      // 返回地址栈(模块,⑤)
  Fetch                   fetch_;    // PC + 取指队列(模块)
  // (惰性取消用 dyn_id 标签,不用 epoch;见 on_wakeup。Event/MemReq 的 epoch 字段为内核通用预留。)

  Rob                           rob_;        // 重排序缓冲(模块)
  IssueQueue                    iq_;         // 发射队列(模块)
  StoreQueue                    sq_;         // store queue / store buffer(模块)

  Alu            alu_;     // ALU + 分支比较(模块)
  MulDiv         muldiv_;  // MUL / DIV(模块)
  FpAlu          fpalu_;   // FP 算术(模块,② FP)
  BranchResolve  brres_;   // 分支误判判定(模块)
  CsrFile        csr_;     // CSR + trap 序列器(③)
  Tlb            tlb_;     // 地址翻译旁视缓冲(④)
  LoadUnit       ldu_;     // load AGU + 翻译 + TLB walk(⑥)
  Decode         decode_;  // 译码分类 + 微 op 裂分(⑥)
  bool           system_stall_ = false;  // 系统 op 在飞 -> dispatch 串行(③)
  bool           pending_irq_ = false;    // 异步中断待处理(③),commit 边界精确注入
  uint64_t       next_id_ = 1;
  Cycle          structural_wake_ = kInvalidCycle;

  uint64_t dispatched_ = 0, issued_ = 0, retired_ = 0;
  uint64_t forwards_ = 0, mem_loads_ = 0, stores_drained_ = 0;
  uint64_t branches_ = 0, mispredicts_ = 0, squashes_ = 0, traps_ = 0, irqs_ = 0;
  uint64_t jalrs_ = 0, jalr_mispredicts_ = 0, calls_ = 0;  // ⑤ 调用/返回统计
  bool     halted_ = false;
  std::vector<uint64_t> completion_order_, commit_order_;
};

}  // namespace ace
