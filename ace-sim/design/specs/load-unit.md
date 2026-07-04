# LoadUnit — load 地址生成 + 翻译 + TLB walk

**文件**:`src/core/memory/LoadUnit.hh` · **↔ npc**:`OooLoadUnit` / AGU + `Sv39Tlb` 接口

## 职责
load 侧的地址生成(AGU)+ 虚实翻译 + TLB walk 延迟决定。消歧/前递由 `StoreQueue` 负责,发射/事件编排留 `CpuTop`(glue)。

## 状态
持 `Tlb&` 引用 + `mmu_on`(翻译开关)。TLB 命中/未命中状态在 `Tlb`(本模块只驱动)。

## 接口
- `vaddr(base_val, off)`:`base_val + off`(AGU)。
- `paddr(va)`:`mmu_translate(va, mmu_on)`(消歧/访存都用物理地址)。
- `walk_latency(va, walk_lat)`:访存拍调用 —— TLB 命中返回 0,未命中返回页表 walk 额外延迟(并填充 TLB)。仅 `mmu_on` 时生效。

## 不变量 / 行为
- 翻译对功能透明(golden 同样翻译);walk 延迟只改时序。`walk_latency` 有副作用(填 TLB),须在**确定访存**后调用(前递/跳过的 load 不计)。

## 测试
`make run-mmu`(翻译 + TLB 命中/walk)、`make run-sta`(与 STA/STD 消歧协同)、全套回归。
