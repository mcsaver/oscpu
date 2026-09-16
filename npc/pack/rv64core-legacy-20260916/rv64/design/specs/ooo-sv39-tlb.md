# 规范：Sv39 TLB OooSv39Tlb

> 模块：`vsrc/memory/OooSv39Tlb.v`(取指/访存桥各例化一份:ITLB/DTLB)。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：已实现并验证(ACT4 Sv39 gate)。

## 1. 目的与范围
缓存 Sv39 VA→PA 翻译,避免每次访问都走三级页表。组合查询(命中给 pte/level/paddr),miss 由桥触发
page table walk 后 fill。容量 ENTRY_COUNT=64(INDEX_W=6)。不做 page walk(桥的状态机做)、不判权限/AD
(桥按 pte 判 R/W/X/U/A/D 与 PMP)。

## 2. 接口
| 信号 | 含义 |
| --- | --- |
| lookup_valid/vaddr/satp | 查询(需翻译时);satp 携带 mode/ASID 上下文 |
| lookup_context_hit_o | 命中(vpn tag + satp 上下文均匹配) |
| lookup_pte_o/level_o/paddr_o | 命中的 PTE / 页表级(superpage) / 翻译后物理地址 |
| fill_valid/vaddr/satp/pte/level | page walk 完成后写入一条 |
| clear_i | sfence.vma / satp 写 → 全清 |

## 3. 结构与匹配
- 每项:`valid_q` + `vpn_q`(tag vaddr[38:12]) + `satp_q`(上下文) + `pte_q` + `level_q`(2/1/0=1G/2M/4K)。
- index = vaddr[INDEX_W+11:12];查询比较 vpn tag + satp(整 satp 作上下文,satp 变即 miss/由 clear 兜底)。
- **superpage/NAPOT**:按 level 用 level-dependent VPN 掩码匹配(1GiB 只比 VPN2、2MiB 比 VPN2:1),
  paddr 由 PTE PPN + 页内偏移按 level 拼接。Svnapot 目前只接受 level0 64KiB NAPOT leaf
  (`PTE.N=1 && PTE.PPN[3:0]=4'b1000`):TLB 仍按 4KiB VPN 精确填入/命中,但命中后 PA 的低
  4 个 PPN bit 来自 VA[15:12],而不是保留 PTE 编码位。

## 4. 不变量
- **TLB-I1 上下文正确**:命中要求 satp 上下文一致;sfence.vma/satp 写经 `clear_i` 全清,不残留旧映射。
- **TLB-I2 superpage 对齐**:level 决定匹配掩码与 paddr 拼接;superpage misaligned 由桥在 fill 前判并拒填。
- **TLB-I2b Svnapot 不缓存非法编码**:桥在 fill 前拒绝非法 `PTE.N`(非 leaf、非 level0、或
  `PTE.PPN[3:0] != 4'b1000`),TLB 只负责对已验证 leaf 做 PA 拼接。
- **TLB-I3 A/D 一致**:只缓存 A=1(且 store 时 D=1)的 leaf(桥按 A/D page-fault 策略,不把待置位 PTE 入 TLB)。

## 5. 关键路径
Vivado OOC:作为 OooFetchAxiBridge 关键路径一段(itlb vpn 比较 → walk_level/paddr);TLB 本身浅,
桥的 PMP×2+ITLB+cache 并行是该桥深度来源(见 `ooo-fetch-axi-bridge.md`)。

## 6. 验证
- ACT4 Sv39/Svpbmt/Svinval gate;riscv-tests 特权;AM sv39-*/linux-mini-boot(配 trm.c PMP)。
- 2026-07-07:Svnapot 64KiB focused TB 覆盖 fetch/mem 两侧 `pte_reserved_fault` 与 `leaf_paddr`;
  `rv64ssvnapot-p-napot` NPC+NEMU full-state difftest PASS。

## 7. 变更记录
- 2026-06-28：逆向文档化(64 项 / vpn+satp 上下文 / superpage / clear 语义 / A-D 入 TLB 约束)。
- 2026-07-07：补齐 Svnapot 64KiB NAPOT leaf 的 PA 拼接与非法编码拒填约束。
