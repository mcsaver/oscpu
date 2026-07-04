# Tlb — 地址翻译旁视缓冲

**文件**:`src/core/mmu/Tlb.hh`(+ 翻译值 `src/mem/mmu.hh`) · **↔ npc**:`Sv39Tlb`(+ PageTableWalker)

## 职责
缓存 VPN→PPN 翻译,决定一次访存**是否需要页表 walk**(时序)。属**纯时序/统计**模块:
翻译的**值**由 `mmu_translate()` 确定性给出(golden 与详细核共用),本模块只影响延迟与命中率,不影响功能结果(与 cache 层级同构)。

## 翻译值(`mem/mmu.hh`)
- `PAGE_SHIFT=12`;`mmu_translate(vaddr, on)`:`on=false` 恒等;否则 `PPN = VPN ^ VPN_XOR_KEY`(**双射** → 任意不同 vaddr 映射到不同 paddr → 无别名 → 内存语义守恒),`paddr = (PPN<<12) | offset`。
- golden(`FunctionalBackend`,`mmu_on`)与详细核(`OooConfig.mmu_on`)调**同一函数** → load/store 落在相同物理地址 → difftest 逐位一致。

## 状态
- 组相联标签阵列 `vpn_[sets×ways]` + `valid_` + `lru_`(时钟 LRU)。

## 接口
- `access(vpn)`:命中返回 `true`(快);未命中按 LRU 填充并返回 `false`(需 walk)。均更新 LRU + 命中/未命中统计。
- `flush()`:全无效(sfence.vma 等,未来)。

## 详细核集成(`CpuTop::select_issue`)
- LOAD:`paddr = mmu_translate(vaddr)` 用于**消歧/前递/访存**;走内存时 `access(vpn)`,miss → `MemReq.extra_latency = tlb_walk_lat`(内存把它加到响应时刻)。前递/被跳过的 load 不计 walk。
- STORE:execute 拍翻译到 paddr 存入 SQ(drain 落到物理地址);`access(vpn)` 计入 TLB 但不加流水延迟(store 已缓冲)。

## 不变量 / 行为
- 翻译对功能透明:程序可观测状态(regs + 载入值)与关翻译时一致地由 golden 复现(golden 也翻译)。
- TLB 仅改时序:命中率/walk 延迟影响周期数,不改架构结果。

## 测试
`make run-mmu`:demo(V0x1000→P0x4000 等 + 同页 TLB 命中 + 值往返 111/222)+ fuzz 2 万程序 / 19.6 万 TLB 访问对拍功能金标准(regs + 物理内存键)。
