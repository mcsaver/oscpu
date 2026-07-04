// ace-sim/mem: 地址翻译(④ TLB/MMU)。
// 翻译**值**是确定性双射函数(golden 与详细核共用 -> difftest 一致);TLB(时序/统计)在详细核侧。
// 简化"页表":PPN = VPN ^ KEY(异或双射,任意两个不同 VPN 映射到不同 PPN -> 无别名 -> 内存语义守恒)。
#pragma once
#include <cstdint>

namespace ace {

inline constexpr uint64_t PAGE_SHIFT   = 12;
inline constexpr uint64_t PAGE_SIZE    = 1ull << PAGE_SHIFT;
inline constexpr uint64_t PAGE_OFFMASK = PAGE_SIZE - 1;
inline constexpr uint64_t VPN_XOR_KEY  = 0x5;   // 单级"页表"remap(双射)

inline uint64_t vpn_of(uint64_t vaddr) { return vaddr >> PAGE_SHIFT; }

// 虚->物翻译。on=false 时恒等(非 MMU demo 不受影响)。
inline uint64_t mmu_translate(uint64_t vaddr, bool on) {
  if (!on) return vaddr;
  uint64_t ppn = vpn_of(vaddr) ^ VPN_XOR_KEY;
  return (ppn << PAGE_SHIFT) | (vaddr & PAGE_OFFMASK);
}

}  // namespace ace
