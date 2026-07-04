// ace-sim/core/memory: load 单元 —— 地址生成(AGU)+ 翻译 + TLB walk(对应 npc OooLoadUnit/AGU + Sv39Tlb 接口)。
// 消歧/前递由 StoreQueue 负责(load 侧只产地址 + 决定 walk 延迟);发射/事件编排留 CpuTop(glue)。
#pragma once
#include <cstdint>
#include "hw/module.hh"
#include "core/mmu/Tlb.hh"
#include "mem/mmu.hh"

namespace ace {

class LoadUnit : public Module {
 public:
  LoadUnit(Tlb& tlb, bool mmu_on) : Module("LoadUnit"), tlb_(tlb), mmu_on_(mmu_on) {}

  uint64_t vaddr(uint64_t base_val, uint64_t off) const { return base_val + off; }
  uint64_t paddr(uint64_t va) const { return mmu_translate(va, mmu_on_); }

  // 访存拍调用:TLB 命中返回 0,未命中返回页表 walk 额外延迟(并填充 TLB)。
  uint32_t walk_latency(uint64_t va, uint32_t walk_lat) {
    if (!mmu_on_) return 0;
    return tlb_.access(vpn_of(va)) ? 0u : walk_lat;
  }

 private:
  Tlb& tlb_;
  bool mmu_on_;
};

}  // namespace ace
