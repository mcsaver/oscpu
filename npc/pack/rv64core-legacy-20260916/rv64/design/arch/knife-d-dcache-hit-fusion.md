# 规范：刀 D——dcache hit 融合拍（S_LOOKUP 命中拍组合响应，load hit 流 1 拍/load）

> 状态：**spec 冻结（2026-07-10，侦查存 `.github/task-runs/2026-07-10-knife-d-recon/`）**。
> 与刀 F（`knife-f-fetch-hit-fusion.md`）同型；本 spec 只记差异与 mem 侧特有契约。
> 动机：刀 F 后等待源 mem 66.7% 升至第一顺位竞争者；load hit 稳态 2 拍/load 的结构
> 根因=`stage_advance_w` 不含 S_LOOKUP（判决拍禁 advance）。

## 1. 冻结形态

- 融合谓词：`lookup_hit_fusion_w = (S_LOOKUP) && dcache_lookup_hit_final_w && !cpu_kill_w`
  ——**必须门 kill**（p42 型污染：漏门会把被 kill load 的数据当真写 preg）。
  nokill 语义不需入融合谓词（S_LOOKUP 事务恒非 nokill）。
- 组合 rsp 臂：`rsp_valid += lookup_hit_fusion_w`；rdata 组合出线
  （`line >> {paddr_q[2:0],3'b000}`，与现行锁存表达式同源）。
- advance 集合加融合臂：`(lookup_hit_fusion_w && mem0_rsp_ready_i)`——融合拍=
  advance 拍，寄存站换手+下一项按类型走 accept_request 既有分叉（load→再 S_LOOKUP、
  store→S_WRITE_REQ、fault→S_RESP、TLB miss→S_WALK_AR）；无下一项→S_IDLE；
  rsp 不 ready→现行落寄存进 S_RESP（天然 skid）。
- **融合可行域**：plain load hit（主收益）+walk 续读/A-D 续读（同一判决臂顺带）。
  probe（不进 S_LOOKUP）/store/fault/MMIO（cacheable=0 hit 恒 0）/跨线
  （read_cross_q 压 hit）天然排除，全走原路径。
- **不需要 snoop 降级臂**（与刀 F 的关键差异）：hit 锥输入全 FF/锁存
  （lookup_pend_q/cacheable_q/valid_q FF+锁存 tag 比较），store 维护走 FF valid_q
  （发射拍同沿失效判决拍已可见，只会保守判 miss）；virtio DMA 在 C 侧直写 pmem
  不经 RTL dcache。**hit 锥天生干净。**
- 1RW 互斥保持：fill=S_READ_DATA、RMW 读=store commit 拍、RMW 判决∈{S_RESP,S_IDLE}
  ——全部与 S_LOOKUP 状态互斥，融合拍连续 lookup 只占读口；`!rmw_busy` 保留为
  安全网；DWC-SRAM-1RW/MEM-RMW-PORT 断言原样看门。
- MIQ 双射：ready 公式文本不变（`!flush_i && (!stg_valid || advance)`），advance
  扩融合臂后 ready 自动扩展；融合拍 pop+push 同拍 MIQ 原生支持；
  KM-STG-MIQ/KM-STG-CTX/BRG-STG-NOKILL 断言零改。

## 2. 收益预估与验收

- 收益上界=hit 判决数 590216 拍≈15.2% cycles；重叠折扣后预期带
  **ΔCPI ≈ -0.09~-0.16（CPI 1.207 → 1.05~1.12）**。验收以 CoreMark 实测+
  0xfcaf 为准，不拿预估当合格线。

## 3. 风险表（R1' 为主险）

| # | 风险 | 缓解/门禁 |
| --- | --- | --- |
| R1' | hit 提升为发射决策，消费面宽于 fetch（hit→{ready,rsp_valid,advance,lookup_en,arvalid}→MIQ pop/slot_open→IQ can_fire→五源 req mux→stg 装载） | hit 锥自身干净（单层 tag cmp）；全核 STA 门禁，**>0.5ns 劣化退缓解（收窄融合条件为 FF 谓词/预移位）** |
| R2' | 组合 rsp 数据锥（SRAM→移位→LSU→wb mux→PRF/ROB/唤醒） | rsp 不 ready 落 S_RESP skid；与 R1' 合并 STA |
| R3' | 融合拍 MIQ pop/push/wb 交叠错位 | 断言族+TB 交叠矩阵+mutation（ready 放宽到 miss 拍） |
| R4' | 融合臂漏 `!cpu_kill_w` | 谓词显式门 kill；p42 型定向用例（kill 拍融合关断） |
| R5' | mem_quiet 死锁家族 | 禁动 MIQ 记账时点与 flush 相位；`!flush_i` 铁律不动 |

## 4. 实施步骤

S1：OooMemAxiBridge.v 融合谓词+rsp 组合臂+advance 融合臂+S_LOOKUP hit 臂三分。
S2：桥 TB 定向（融合连发/skid/miss 拍不 advance/kill 拍融合关断/store-RMW 相邻拍）
+mutation；lint+contract。
S3：module TB 全量+riscv 177+CoreMark+全核综合/STA（R1' 判定 vs 基线 -5.69）；
文档/memory 收尾。

## 5. 落地记录（2026-07-10 同日）

| 指标 | 刀 D 前 | 刀 D 后 |
| --- | --- | --- |
| CoreMark CPI | 1.206 | **1.140（-5.5%，0xfcaf）** |
| CoreMark cycles | 3881109 | 3667974 |
| mem 等待桶 | 66.7% | 56.6% |
| WNS @100MHz | -5.69 | **-6.05（劣化 0.36ns，阈值内，R1' 未触发）** |

- 收益 0.066 落在预估带（0.09~0.16）下沿偏外——重叠折扣比预估大（fetch 87.9%
  仍掩盖大量 mem 等待）。
- 新 top 路径=dcache SRAM rdata→hit→发射决策锥（MIQ/SQ 记账→跨模块到 fetch
  lkp_inv_q / mem state_q）——融合拍预期形态；累计两融合刀 WNS -5.59→-6.05
  （-0.46），**后续刀再劣化需回头治 dcache-rdata 发射锥**（缓解=收窄融合条件为
  FF 谓词/预移位，spec §3 R1' 预案）。
- mutation 首轮逃逸教训：advance 放宽到 miss 拍在"站空"用例下无症状——杀手用例
  必须构造"miss 判决拍+站有下一项"（上下文覆写才显形）；且 TB 地址选择要避开
  直映 index 冲突（0x9000 与 0x1000 差 0x8000 同 index，fill 顶掉预热 line）。
- 验证：桥 TB 定向 4 组+mutation 闭环；86/86+lint+contract 32；riscv 177/177
  （含特权）；CoreMark 0xfcaf。

## 6. 变更记录

- 2026-07-10：spec 冻结。
- 2026-07-10（同日）：落地（§5）。
