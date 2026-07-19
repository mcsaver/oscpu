# RV64 S2-Q1A abort-priority 任务报告

## 基本信息

- `task_id`: `2026-07-19-rv64-q1a-abort-priority`
- `status`: `completed (scoped)`
- `scope`: `OooMmuEpochOwner source-catalog inactive leaf`
- `verdict`: `Q1A abort-priority source-catalog GREEN / live integration RED`
- `parent_goal`: 持续优化 RV64 双发射完整 OoO 核及其 PPA，并把验证/证据/协作规则固化成可发现、可执行、可审计工作流

## 根因与架构裁决

1. 原 Q1 leaf 没有显式取消入口；若 held head/full identity 在上层失效，leaf 仍可能展示 grant 或推进 epoch。
2. 只增加单拍 abort 仍不充分：被取消 producer 若连续保持 `request_valid=1`，owner 会在 abort 后第一拍把同一旧 envelope 当作新事务重新捕获。
3. 当前 leaf 因此采用 `abort_rearm_q`：abort 当拍组合屏蔽 request/grant 并清 held owner；仅当 abort 当拍存在 request envelope 时置 rearm，continuous-valid 期间 fail closed，观察 valid-low edge 后才开放。idle abort 不凭空增加 bubble。
4. quiet 被冻结为当前 transaction 的 sticky/irrevocable completion；`capture_block` 只封另一条 admission，禁止组合回灌本 request producer。
5. 本轮没有直接落 full identity：8-bit 单调 allocation identity 在 ROB-only 模型也会回绕。持有一个旧项、允许 k 个年轻槽嵌套 wrong/correct-path recovery 时，`F(k)=1+2F(k-1)=2^k-1`；`k=9` 已达 511 次 allocation。没有覆盖 ROB/IQ/EX/WB/PRF wakeup/SQ/MIQ/bridge/PTW/RMW/Q1/Csr/FENCE/tombstone 的 last-reference/no-live-reuse 协议，任何 8-bit 或 4+4 generation/index 直接接入都可能让 stale WB 写坏 PRF/wakeup。

## 实现与工作流

- RTL：`npc/rv64/vsrc/memory/OooMmuEpochOwner.v`
  - 优先级固定为 `reset > abort > grant/current-state transition > hold`；
  - abort 展示拍 `capture_block=1/request_ready=0/grant_valid=0`；
  - abort edge 清 state/cause/payload，不写 epoch；
  - `abort_rearm_q <= request_valid_i`，valid-low edge 后清；
  - `mmu_epoch_q` 静态锁定为 reset 与 grant-fire 两个时序写点。
- 正例 TB 增加 idle、request race、drain、ready grant、backpressured grant 与 continuous-valid rearm 反例。
- assertion-negative 为 5/5；compile-success semantic mutation 为 13/13，新增 `no-abort-rearm`。
- 静态 checker 扫描 production `vsrc/**/*.v`，证明 leaf 没有 live RTL 引用，防止把 source-catalog 结论越级成 active integration。
- 新增两个 canonical 入口：
  - `run-q1a-abort-priority.sh`：聚焦正/负例、变异、lint/style/Yosys/static contract 与源码哈希；
  - `run-q1a-broad-gates.sh`：重跑聚焦、104-module、全 RTL style/contract、strict/default/nonfatal lint、pre-v8a 告警基线比较和证据哈希闭包。

## 验证证据

| Gate | 结果 | 证据 |
| --- | --- | --- |
| release/assert positive | PASS / PASS，含 3 个唯一 PASS marker | `evidence/focused-r2/summary.txt` |
| assertion-negative | PASS `5/5` | `evidence/focused-r2/negative/` |
| compile-success mutation | PASS `13/13`，均由唯一 oracle 杀死 | `evidence/focused-r2/mutations/` |
| leaf Verilator/style/Yosys/static contract | PASS | `evidence/focused-r2/gates/` |
| module aggregate | PASS `104/104` | `evidence/module-r3/summary.txt` |
| full RTL style | PASS | `evidence/rtl-style-full-r2.log` |
| full contract | PASS，当前 `289 >= 89` | `evidence/check-contract-r2.log` |
| strict lint | RED（继承）`115` warnings | `evidence/strict-lint-r2.log` |
| full default build | RED（继承）`115` warnings | `evidence/full-build-r2.log` |
| nonfatal parse/elaboration | PASS | `evidence/lint-nonfatal-r2.log` |
| warning normalization | 三份均与 frozen pre-v8a baseline byte-match | `evidence/*-r2.normalized` |
| broad evidence closure | 21 项 hash + 105 项 module hash 均可复核 | `evidence/broad-gates-r2.sha256`、`evidence/module-r3.sha256` |

继承告警精确分布为 `TIMESCALEMOD:108`、`PINCONNECTEMPTY:2`、`LATCH:4`、`UNOPTFLAT:1`。它们没有被豁免，故 global strict lint/default build 仍为 RED；`-Wno-fatal` 只证明 parse/elaboration 可完成。

最终权威证据只取 `focused-r2`、`module-r3` 和所有 `*-r2` broad 文件；`focused-r1`、`module-r1` 及无后缀 broad 文件是 continuous-valid rearm 加固前的现场，保留用于追溯，不参与最终 GREEN 裁决。

## 独立审查与边界

独立 reviewer 以连续/多拍 abort、valid 连续高、quiet drop、grant backpressure、epoch 写点和 capture-block 组合环逐项找反例，最终裁决 scoped GREEN / live RED 严谨，未发现新的 P0/P1 blocker。两个实现注记也已满足：rearm 清除位于 abort 分支之后的 `else`，不会在同沿被 valid-low 覆盖；quiet-drop 检查只拒绝无 abort 的 COMMIT/backpressure 回落，reset/abort cancellation 不触发该检查。

- 本 leaf 只消费已经寄存的 shared abort event；active wrapper 仍需在 identity mismatch 检出拍以组合 `kill_now` 立即 gate grant/apply，并在下一拍广播唯一 registered abort。
- 同一 event 还必须同拍清 CsrFile reservation；full identity/reuse、same-owner typed payload、selective squash/full quiet、FENCE.I owner/generation、late response tombstone 均继续 RED。
- 当前 production RTL 无实例引用，所以没有 live 行为变化，也没有 Linux、综合、STA、频率、面积或功耗结论。

## AI e2e 实战纠偏

- 第一次 `npc-dev/rv64-q1a-abort-priority` 生成 `...-2` blocked run：5/5 node 虽 PASS，但 startup brief 在 memory 写入后、retained DB/index 同步前执行，找不到 non-history independent primary。runner 正确阻止 publication，没有被节点绿掩盖。
- 用 `update-stored` 同步 `project-status.md` 与 `modules/npc.md`，重做 stored snapshot 并通过 `audit-db-first` 后，显式 brief 以当前 `npc.md` Q1A chunk 为 primary；`...-3` completed 并生成 `complete.marker`/`completion-publication.md`。
- 首个 `agent-system/rv64-q1a-evidence-workflow` 因 slug 中 `evidence/workflow` 在当前 non-history 文本没有独立全词命中而 blocked；这是 fail-closed 的用户查询边界，不是节点失败。改用与当前事实一致的 `rv64-q1a-abort-priority` 后，`...-4` completed/publication-valid。
- 两个 blocked run 均原样保留，没有手工改 report 造绿。可复用顺序为：先写 memory → `update-stored`/snapshot/audit → 预检 bounded brief → 再执行 task-specific profile。

## 后续原子切片

1. 先冻结全局 still-live identity holder census、last-reference release 与 collision-stall 合同，再选择 `{generation,index}` 编码；不能只扩大位宽。
2. 为 active wrapper 实现 mismatch-cycle `kill_now` + next-cycle registered shared abort，并让 Q1/CsrFile 使用同一 event。
3. 用 stale WB→PRF/wakeup、Q1/Csr reservation、FENCE.I generation、selective squash/full quiet 反例关闭 live integration 后，才允许打开 permit 或声明 Q2 active。
