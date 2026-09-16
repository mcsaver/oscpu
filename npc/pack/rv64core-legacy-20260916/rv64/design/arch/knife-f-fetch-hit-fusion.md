# 规范：刀 F——fetch hit 融合拍（S_LOOKUP 命中拍组合响应，恢复 1 包/拍）

> 状态：**spec 冻结（2026-07-10，两路侦查后成文，侦查原文存
> `.github/task-runs/2026-07-10-knife-f-recon/evidence/`）**。
> 动机：刀 X 后 CoreMark 等待源分解 **fetch 占 90.8% 成唯一压倒性瓶颈**；根因=SRAM 化
> 一期把 hit 吞吐砍半（S_LOOKUP 不在 ready 集合，1 包/2 拍=前端供给 1 指令/拍=双发射
> 需求 50%），CPI 考证归因 +0.50。本刀恢复 hit 流 1 包/拍。
>
> **T3J supersession（2026-07-13）**：本文冻结的是刀 F 的 hit-fusion 语义与历史数据；
> 其中“`lookup_en`/fire 发射 SRAM 读”的物理描述已由
> `ooo-fetch-packet-cache.md` Contract v1 + T3J 超越。当前实现由
> `fetch_cache_read_window_w={S_IDLE,S_RESP,S_LOOKUP}` 驱动物理读，fire/`lookup_en_i`
> 只形成 semantic accept、锁存上下文和置判决资格；fusion 吞吐与 1-outstanding 语义不变。

## 1. 方案选型（三案对比后冻结 A）

- **A（冻结）：S_LOOKUP 命中拍组合响应（融合 LOOKUP/RESP）**。hit 拍直接组合出
  rsp_valid+payload，同拍可接受新请求（该拍即新 fire 拍，重新锁上下文+发射 SRAM 读，
  留在 S_LOOKUP）。接口保持 1-outstanding——"rsp fire+req fire 同拍"正是现行 S_RESP
  back-to-back 已验证的模式，**前端（sequencer 九臂记账/flow control/redirect 门/
  FIFO 信用）零手术**。
- B（否决）：真 2 深流水（S_LOOKUP 进 ready 集合、桥内双套上下文+重放）。前端
  outstanding=1 被三处硬编码（sequencer 单项记账 9 事件臂/发射门/redirect valid 门），
  discard 单 bit 变多深度=正面踩 F2 kill 窗口逃逸家族+"整臂删除=CoreMark 静默卡死"
  修复史雷区；且 RVC 变长包使 B 地址依赖 A 判决拍 rdata（冲突点 0），锥并不消失。
  改动半径数倍于 A，收益相同。
- C（中期选项，本刀不做）：对齐 8B 窗口取指——`next_window=window+8` 内容无关，
  地址递归环结构性消灭。代价=包语义/cache 索引/双发槽/FIFO/decode 全链重定义。
  若 A 的时序退出条件触发，C 升级为主案。

## 2. 冻结形态（方案 A 细则）

- `fetch_rsp_valid_o = (S_RESP) || (S_LOOKUP && cache_hit_w)`；组合臂 payload 走
  `cache_inst0/1_w` 直出，resp0/1 恒 NONE（hit 已含 PMP/ITLB 复检通过）。
- `fetch_req_ready_o = (S_IDLE) || (S_RESP && rsp_ready) || (S_LOOKUP && cache_hit_w && rsp_ready)`。
- S_LOOKUP hit 臂三分：
  - rsp fire 且新 req fire →（融合拍）锁新上下文+`lookup_en` 发射新读，留 S_LOOKUP；
  - rsp fire 无新 req → S_IDLE（响应已组合交付，不经 S_RESP）；
  - rsp 不 ready → 现行落寄存进 S_RESP（**S_RESP=天然 skid**，A1/A2 的 dec_en 一拍性
    与 sticky invalidate 问题随之消失）。
- **不动**：miss/walk/fault 全路径（fault 类仍走 S_RESP 寄存路径——罕见，CPI 无感）、
  fill 时点（S_R0/S_R1）、上下文单套寄存（判决组合读旧值、拍尾覆写，1-outstanding
  保证任意时刻单活跃上下文）、`lookup_direct_miss_w` 判决拍直发 AR、mmu_flush 复位
  语义、前端全部记账。
- **1RW 互斥保持**：ready 集合不含 S_R0/S_R1，lookup fire 与 fill 状态互斥不变，
  `CONTRACT-FPC-1RW` 断言原样看门。

T3J 对上述物理端口合同的补充：S_IDLE/S_RESP/S_LOOKUP 的 read window 恒开，无 fire 时是
无语义 dummy read；S_R0 final fill 时 read window=0、实际 write=1。1RW 断言现审核
`lookup_read_en_i && sram_we_w`，另以 `FPC-ACCEPT-REQUIRES-READ` 审核 accept 必须落在读窗内。

## 3. 稳态时序与收益

- hit 流：`fire→S_LOOKUP(判决+rsp+新fire)→S_LOOKUP→…` = **1 包/拍**（现 1 包/2 拍）。
- 前端供给上限恢复 2 指令/拍；CPI 收复带 ≈0.5（考证归因值；实测以 CoreMark 为准，
  fetch 等待桶 90.8% 应显著下降）。
- miss 侧无变化（miss AR 已在判决拍直发，无收益空间）；icache hit 率 99.68%，
  收益覆盖面即 hit 流本身。

## 4. 风险表与退出条件

| # | 风险 | 等级 | 缓解/门禁 |
| --- | --- | --- | --- |
| R1 | **单拍大 cone**：SRAM rdata→tag×2+ITLB+PMP 复检→hit→{ready/rsp_valid/lookup_en}，并行 payload→RVC×2→next_pc→req mux→SRAM addr（地址递归环单拍闭合）。与"重构期别造单拍大 cone"戒律正面张力 | 高 | 经典 I$ hit 路径形态+STA 流程护栏在。**退出条件：实施后 OOC fetch 桥+cache 判决锥 lev 或全核 WNS 显著劣化（>0.5ns）→ 退缓解①（payload 预存 next_pc/len_sum，SRAM 加宽新规格，砍 RVC 解码支链）或②（升级方案 C）** |
| R2 | 真宏 rdata 语义：任何依赖"rdata 跨拍保持"的设计不安全 | 中 | 方案 A 不依赖（hit 拍即消费或落寄存）；spec 明文禁止保持式变体 |
| R3 | 双 fire 拍从间歇态变稳态：sequencer 双 fire 臂与 E1-E9 臂同拍交叠组合 | 中 | module TB 拉满交叠矩阵（现 113/113 基础上扩）；负测试=融合拍记账错位应使 INV-2/SHADOW-EQ-PC fire |
| R4 | 组合 rsp 同拍进 FIFO 的锥（rdata→decode→enqueue） | 中 | 万幸 rsp 直通 dispatch 的 bypass 已 tie-0 物理删除，锥止于 FIFO 写口；与 R1 合并 STA 评估 |
| R5 | pmpcfg/pmpaddr 活值消费前提（CSR 写串行化期无在飞取指） | 低 | 前提不变；固化为断言 |

## 5. 实施步骤

- **S1（RTL，单模块 OooFetchAxiBridge.v）**：按 §2 三分臂改造；`lookup_en_i =
  fetch_req_fire_w` 语义自动覆盖融合拍。
- **S2（验证）**：桥 focused TB 契约改写（hit 1 拍口径+融合拍连发+rsp 反压落 S_RESP
  +miss/fault 拍数不变）；sequencer/融合拍交叠用例；负测试=故意把 ready 臂放宽到
  `cache_hit_w` 之外（miss 拍也 ready）应使 1RW/记账断言 fire；lint 双变体+
  check-contract 不降。
- **S3（集成+数据）**：module TB 全量+riscv 177+AM+CoreMark 10 迭代（CPI+fetch 桶
  对比）；全核综合+OpenSTA（R1 判定：WNS 与判决锥对比刀 X 后基线 -5.59）；
  spec/task-run/memory 收尾。

## 6. 落地记录（2026-07-10 同日）

| 指标 | 刀 F 前 | 刀 F 后 | 解读 |
| --- | --- | --- | --- |
| CoreMark CPI | 1.633 | **1.206** | **-26%（0xfcaf GOOD TRAP）** |
| CoreMark cycles | 5254589 | 3881109 | fetch 等待桶绝对值 -29% |
| WNS @100MHz | -5.59 | -5.69 | 时序中性（0.10ns 扰动带内） |
| 等待源(overlap) | fetch 90.8% | fetch 86.9%/mem 66.7%/branch_flush 16.8% | mem 升至第一顺位竞争者 |

**R1 实测触发与修复**：首版 WNS -6.73（劣化 1.14ns>0.5ns 阈值），top10 全族=
SQ snoop→fetch 桥（lkp_inv_q/SRAM addr/first_beat CE）——融合拍 fire 依赖
cache_hit_w，其**窗口②当拍 invalidate 地址比较**把跨模块 store 失效链串进取指
发射决策全家。修复两步：①cache 新增 `lookup_hit_no_snoop_o`（不含窗口②项），
融合臂=no_snoop hit && `!invalidate_valid_i`（单 bit 关断）——invalidate 拍融合
降级走精确寄存路径（正确性论证：inv_valid=0 时两式相等，inv_valid=1 时融合关闭
⇒ fusion⇒精确 hit 恒成立）；②`lkp_inv_q` 去 CE 无条件锁存（切断 CE-mux 串联；
非 fire 拍锁到的值因 dec_en_q=0 不被消费）。修复后 WNS -5.69、CPI 1.206
（降级臂零代价）。**教训：融合类优化把"判定"变成"发射决策"时，判定锥里的每条
输入链（尤其跨模块 snoop/失效类）都会被提升为发射关键路径——设计时要按输入链
逐条审查，把低频精确性条件（如失效撞拍）用单 bit 降级臂隔离。**

验证：module TB 86/86（桥 TB 新增融合连发/skid/miss 拍 ready=0/invalidate 降级/
同 window 失效杀 hit 定向用例；mutation=ready 放宽到 miss 拍被"miss beat not
ready"逮住）；lint 双变体；check-contract 32；riscv-tests 177/177（含特权）；
CoreMark 0xfcaf。

## 7. 变更记录

- 2026-07-10：spec 冻结（方案 A；B 否决=F2 雷区+改动半径；C 留作退出条件升级项）。
- 2026-07-10（同日）：落地+R1 触发与修复（§6）。
- 2026-07-13(T3J supersession)：hit-fusion 语义不变；物理 SRAM 读改由三态 read window
  提前打开，semantic accept 与物理 `en_i` 解耦。当前合同以 fetch-cache/bridge dedicated spec 为准。
