# RV64 RAW-I1：冻结双 lane 无 RAW，并拒绝回退的 dead-forward 删除实验

## 基本信息

- `task_id`: 2026-07-12-rv64-t3a-dead-crosslane-forward
- `task_slug`: rv64-t3a-dead-crosslane-forward
- `graph_template`: architecture-refactor + timing-ab
- `graph_mode`: static+dynamic
- `status`: complete_rejected_candidate
- `owner`: root + t3_prf_cut_audit + raw_forward_red + dead_forward_timing + dead_forward_final_review
- `started_at`: 2026-07-12 12:01:00 +0800
- `updated_at`: 2026-07-12 13:31:00 +0800

## 目标与范围

- `source_request`: 持续优化架构，直到完整功能与 200 MHz 同时闭合。
- `goal`: 证明并看护 simultaneous valid 双 lane 无整数 RAW，实验性删除
  `OooIntBackend` 的 issue0 current result → issue1 operand 前递 mux，并用当前基线 fresh
  5ns 全顶 A/B 决定是否交付删除。
- `scope`: backend issue1 integer operand consumers、RAW-I1 立即断言、定向 TB 与整数 IQ spec；
  不改 IQ select/wakeup、PRF write-through、memory order、branch winner 或 long-op priority。

## 不可达证明（RTL 阶段 0）

1. 同拍 dispatch lane0 producer + lane1 RAW consumer 时，`OooRenameMap.map_after_lane0`
   让 lane1 source tag 精确取得 lane0 新分配 pdest。
2. `OooBusyTable` 的“本拍 alloc 命中”优先于 wakeup，故该 lane1 source 入 IQ 时 ready=0。
3. dispatch→issue bypass 已删除；IQ select 的唯一真源是寄存 entry。entry ready 只能来自已存
   ready bit 或整数 WB wakeup，issue0 current result 没有 early-wakeup 回送 IQ。
4. producer 尚未 WB 时，consumer 不可能 ready；物理寄存器唯一分配/commit 后释放又排除
   另一个在飞 producer 以同一非零 tag 提前唤醒。
5. 因而对同时有效的整数 issue0/issue1，`issue1 enabled source preg == issue0 pdest != 0`
   不可达。内部数组默认 index 在 issue1 invalid 时可偶然数值相等，断言必须由 lane valid、
   source-enable、integer destination domain 与 nonzero tag 门控。

该证明依赖“无 dispatch→issue bypass、无 issue-result early wakeup”；未来重引入任一机制，
必须重新审查 RAW-I1。证明成立不等于物理删除一定改善映射；本 run 正是用 A/B 区分二者。

## 六类合同

1. **握手**：最终 issue valid/ready/fire 与 operand mux 均不变；RAW-I1 仅作观察断言。
2. **stall**：issue1 stalled 时 payload/tag 仍由 IQ 寄存 entry 保持；不新增 valid↔ready 路径。
3. **flush/kill**：flush、ROB-age kill、recover 对 IQ/EX 的优先级不变；本刀不新增状态。
4. **异常序**：合法状态下 issue1 operand 仍由 PRF/WB write-through 提供；precise
   exception/ROB commit 不变。实验 B 的删除只改变合同禁止的非法 RAW 输入组合。
5. **访存序**：SQ/MIQ/order、MMIO/LRSC owner 与全部 issue1 memory consumer 最终不变。
6. **恢复/单一真源**：新增断言不拥有状态；flush/kill/recover 语义不变。

### 同拍优先级

| issue0 | issue1 | 预期 |
| --- | --- | --- |
| independent int producer | independent int uop | 可双发，issue1 读 PRF |
| int producer | RAW consumer | consumer 不得成为 valid lane，留 IQ 等 WB |
| FP destination-domain producer | 数值相同的 int preg | 不构成 RAW-I1 |
| pdest=0 / source disabled | 任意默认 tag | 不构成 RAW-I1 |
| kill/flush/recover | 任意 | 沿用 IQ/EX 既有抑制，不由本刀改变 |

## 最终 RTL 拓扑

- **保留** `issue0_current_result_valid_w`、`issue1_current_result_valid_w`、两路 forward
  predicate 与 `issue1_src*_value_w`；所有原 consumer 恢复到 A 形态。
- 新增 OOO_ASSERT `RAW-I1`：同时有效双 lane 不得出现 enabled integer RAW；该断言不进入
  production synth defines。
- 不删除 PRF read0–3 write-through；同拍 WB wakeup→select 仍依赖它，须等 T3 tag/meta
  station 后再独立处理。PRF read8 FP GPR source 旁路必须长期保留。

## RED 与验收

- 删除候选 B：上述 6 个 forward/current-result 标识归零，8 类 consumer 直连 PRF；功能门禁
  全绿后才进入 timing A/B。
- 断言非真空：`RAW_I1_NEGATIVE_PROBE` 在一对合法 independent issue lane 上 force
  issue1 enabled source tag 等于 issue0 integer pdest；必须只触发 `RAW-I1` 且 runner 非零。
- 功能 GREEN：IQ S4、DispatchBackend rename/wakeup、IntBackend dependent-result 三层常驻覆盖。
- 决策门禁：当前 `c6b86f9a7` 前后各 fresh full remap；WNS/TNS/area/power 任一关键指标
  无收益或回退时拒绝删除，不以“代码更少”替代物理证据。

## 最终 guard 与功能证据

- `RAW-I1` 立即断言采用双 valid + issue0 RD_EN/integer-domain/nonzero-pdest + issue1
  source-enable 精确门控。消费边界 source-tag mutation 负探针退出码 1，日志仅命中目标
  RAW-I1；最终证据在 `evidence/guard-final-negative/logs/tb_ooo_int_backend.log`。
- 常驻三 uop GREEN 在 producer WB 组合拍检查两名依赖者分别落入 issue0/issue1，且
  issue1 的 64-bit operand 等于 WB→PRF write-through 值。
- 回退候选后重新运行：OOO_ASSERT focused 5/5、module 87/87、style/lint、contract 38/38。
- production datapath 已恢复为已完成 AM59 + official177 + Difftest AM59 的父提交
  `c6b86f9a7`；本 slice 仅新增 `OOO_ASSERT` 观察合同与 TB/文档，因此不重复耗时全核运行。
- fresh `npc-dev` profile 已在
  `.github/task-runs/2026-07-12-rv64-raw-i1-dead-forward-reject-final/` 完成 5/5；
  `scripts/agent-e2e.sh --guard --guard-mode strict` 对最终 36 个工作树路径判定 PASS。
- 300 个原始 evidence asset 已由 `index-evidence --write-index` 登记，长期 memory 的
  project/NPC/known-issues 三处结论已通过 DB stored load 回读核对。
- `audit-db-first`（5323 candidates/5365 stored）与
  `audit-markdown-coverage --fail-on-live-evidence`（live_evidence=0）均 PASS。

## 时序 A/B 隔离

- A/B 均为 detached `c6b86f9a7`，配置 hash `cb2cad...`，工具/脚本/Liberty/macro lib
  一致；两份 105-file synth manifest 唯一差异为 `OooIntBackend.v`。
- A=保留 forward（最终 production 形态），B=实验性删除；manifest 与输入身份在
  `evidence/timing-ab/`。
- 两侧均使用 NpcTop/200MHz/icsprout55/DELAY-4/同一 blackbox 与 keep-hierarchy 合同；
  两侧最终 target-driven `&nf -D 5000.0` 均为 105，post-map check 均为 0 problem。
- A→B：WNS `-11.74→-11.74ns` 无改善；TNS `-122774.48→-145157.48ns` 恶化 18.23%；
  backend/top area 同增 `851.76`；sequential area 不变；估算 power `0.117→0.118W`。
- top40 两侧完全相同且 40/40 为 fetch bridge→frontend/FIFO/PC-outstanding，0 条经过
  backend/ALU；完整原始口径与结论见 `evidence/timing-ab/summary.md`。

## 当前边界

- `candidate deletion`: **REJECTED + ROLLED BACK**；不能提交 WNS 无收益且 TNS/area/power
  全部回退的候选。
- `delivered`: RAW-I1 立即断言、非真空负探针、三-uop issue1 PRF 活路径回归，以及准确
  current 架构文档。
- `current timing baseline`: A，WNS `-11.74ns`；绝对值受 pre-layout/placeholder 宏和
  frontend 高扇出超表外推限制，不是物理 signoff。
- `parent_goal`: active；下一刀转向 fresh top40 的 frontend B-imm 宽广播/bridge 回包主锥。
