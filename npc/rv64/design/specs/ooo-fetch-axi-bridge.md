# 规范：取指 AXI 桥 OooFetchAxiBridge

> 模块：`vsrc/execute/../frontend/OooFetchAxiBridge.v`。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：**已实现并验证**（含 iter1 取指 cache PMP 门控修复）。

## 1. 目的与范围
把前端取指请求(PC)落到 IFU AXI，返回一个 **fetch packet**（两条对齐的 32-bit 槽，支持 RVC）。
内含取指包 cache、Sv39 ITLB、PMP 检查、跨页拼接。单事务在飞。不负责分支预测/重定向(前端控制面)。

## 2. 接口（要点）
| 信号 | 含义 |
| --- | --- |
| `fetch_req_valid_i/ready_o` + `fetch_req_pc_i` | 取指请求 |
| `fetch_rsp_*`（inst0/inst1/resp0/resp1/next_pc） | 返回包(两槽+各自 resp) |
| `priv_mode_i/satp_i/svpbmt_en_i` + `pmpcfg_i/pmpaddr_i` | 翻译/权限上下文 |
| `mmu_flush_i`（sfence/satp 写）/`flush_i` | 失效/冲刷 |
| `invalidate_*`（store/MISC-MEM） | 取指 cache 失效(自修改代码/fence.i) |

## 3. 主要数据通路
- **取指包 cache** `OooFetchPacketCache`：按 {PC, satp/priv 上下文} 命中，返回 inst0/1+resp0/1。
- **ITLB** `OooSv39Tlb`：paging 时翻译 PC→paddr；miss 触发 page table walk(S_WALK_*)。
- **PMP**：对 exec_paddr(及 +4 的第二槽)逐访问检查；fault→resp=ACCESS_FAULT。
- **跨页**：包尾跨 4KiB 页时，第二槽需第二次翻译/取指并拼接(merge_cross_page)。

## 4. PMP × 取指 cache 门控（iter1 修复，关键）
**问题**：原实现 `cache_hit = cache_hit_raw && !pmp_active`、`fill = !pmp_active && ...`——
只要任何 PMP entry 激活就**整体禁用取指 cache**。真实 Linux/OpenSBI 永远配 PMP，导致取指永远
miss→走慢速 AXI，CPI 近 2x。
**修复**：命中改为按 **PMP-grant 逐访问门控**、fill 恒开：
```
cache_hit_w = cache_hit_raw_w &&
    (pmp_active ? (!req_exec_pmp_fault && !req_exec1_pmp_fault &&
                   (!paging || itlb_hit))
                : 1'b1);
fetch_cache_fill_valid_w = (fill_r0 || fill_r1);   // 不再被 pmp_active 门控
```
- 不变量 **FB-I1**：命中供给的包必通过当拍 PMP 检查(两槽均放行)；若会 fault，cache_hit=0→
  落到下方 `req_exec_pmp_fault` 分支正确报 ACCESS_FAULT(语义不变)。
- 不变量 **FB-I2**：非 PMP 场景(pmp_active=0)行为与原实现逐位一致(走 1'b1 分支)。
- 经验：把"PMP active"当成"禁用缓存"开关是错误的性能杀手；正确做法是命中时按当前 PMP 逐访问检查。

## 5. 状态机（简）
```
 S_IDLE --hit--> S_RESP
 S_IDLE --miss,no-trans--> S_R0[/S_R1 跨页] --> S_RESP
 S_IDLE --need-trans,itlb-miss--> S_WALK_AR/S_WALK_R(三级) --> 取指/RESP
 S_IDLE --pmp/page fault--> S_RESP(resp=ACCESS_FAULT/PAGE_FAULT)
```
A/D：leaf PTE 的 A=0 → instruction page fault(核非 Svadu，软件管理 A/D)。

## 6. 验证
- riscv-tests `rv64ui`(取指正确性)、`rv64mi/si`(特权/翻译)、ACT4 Sv39/PMP。
- iter1 A/B(同配 PMP)：add 2052→1086、matrix-mul 22094→8508；riscv-tests 271/0 不变。
- 自修改代码/fence.i：`invalidate_*` 失效路径(AM fence-i)。

## 7. 关键路径
PMP(16 entry) × 两槽 + ITLB + cache 命中比较并行；是潜在长组合链，时序阶段(待 STA)评估。

## 8. 变更记录
- iter1(2026-06-28)：取指 cache 从"PMP 全禁"改为 PMP-grant 逐访问门控 + fill 恒开。
- 本规范(2026-06-28)：文档化 fetch 桥与该修复。

## 已知隐患(2026-06-28 bug-hunt,安全/当前不可触发)
- 跨页已缓存包槽1 PMP 复检用错物理地址(`req_exec1_paddr_w=paddr0+4` 对跨页是错页);PMP 运行期 allow→deny 第二页且无取指 cache 失效时可绕过槽1 PMP。详见 `.github/memory/known-issues.md`(隐患B)。根因修复:PMP CSR 写时失效取指 cache(CSR↔fetch 布线)。
