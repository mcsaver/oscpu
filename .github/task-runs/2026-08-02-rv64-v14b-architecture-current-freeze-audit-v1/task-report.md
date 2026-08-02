# RV64 V14B — current-design architecture freeze audit

## 本轮结论

- 状态：`APPROVED_CURRENT_SCOPE_NOT_PROMOTION_ELIGIBLE`。
- production RTL：本轮未修改；完整 source-set 为 146 文件，current design-id
  `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`。
- 当前九项 directed gate 已通过 task-local checker replay；只证明 DI-1..DI-5、OOO-1..OOO-4
  的冻结 current-design 定向记录可在当前 checker 下组合，不等于 Section 13 architecture GREEN。
- 本轮动态重绑 `MEM-ISSUE-G1` 与 `PTW-PMP-G1`；独立审查批准这两个 P0 的
  current dynamic scope。完整架构仍 `RED`，`arch-stable=false`，PPA=`BLOCKED_BY_ARCHITECTURE`。
- canonical architecture/debt/historical 记录保持旧设计冻结状态，未覆盖、未发布、未晋级。

## RTL 身份与有效锥

- 旧冻结 design-id `sha256:882111fb…bed67b` 与当前 design-id 的 146 文件清单完全同构，
  只有以下 5 个 production/elaborated RTL 输入哈希变化：
  `OooLoadQueue.v`、`OooMemAxiBridge.v`、`OooStoreQueue.v`、`OooIntIssueQueue.v`、
  `NpcSimTop.sv`。
- P0 owner-path 直接交集只有：
  - `MEM-ISSUE-G1` ← `OooStoreQueue.v`
  - `PTW-PMP-G1` ← `OooMemAxiBridge.v`
- 因此先重验这两项；其它 debt 不因“无直接 owner-path 交集”自动判为 current，仍需
  transitive-cone review 后决定 replay 或 rerun。

## 九项 directed checker replay

- 八份 current scoped manifest 共九项 record，current checker 初检仅 DI-2 GREEN；其它八项
  只因非 DUT provenance 文件/摘要哈希演进而 RED，冻结 proof、artifact、gate log、RTL/TB
  输入均无漂移。
- versioned replay 只更新声明过的非 DUT provenance 绑定，结果 9/9 GREEN；未重跑 DUT，
  未改 source task-run、proof、gate log 或 canonical manifest。
- 4/4 负向 fixture 被拒绝：缺 OOO-2 record、OOO-1 proof hash 漂移、DI-1 provenance
  rollback、aggregate design-id 漂移。
- 证据：`evidence/audit-1/closure-audit.json`、`evidence/replay-1/replay-receipt.json`。

## Section 13 blocker matrix

`evidence/section13-audit-1/section13-audit.json` 的审计执行 PASS，但架构状态为 RED：

- 旧 ledger 上 9 个 P0 与 7 个 cohort 内 P1 未绑定当前 design-id；4 个 P1 仍按冻结 cohort 排除。
- historical defect backfill ledger 仍绑定更早 design-id。
- producer/holder census design-id 当前，但 semantic coverage=`GAP`。
- functional aggregate/result 仍绑定旧 design-id。
- arch-stable candidate 缺 cohort inventory，12 类 freeze input 均为空；既有 arch-stable
  result=`GAP`、PPA=`UNQUALIFIED`。

本轮 task-local 动态证据关闭两个直接有效锥 P0 后，仍余 7 个 P0、7 个 cohort 内 P1；
authoritative ledger 暂不改写，以保留旧 cohort 冻结语义。

## P0 直接有效锥动态重绑

- 正向 TB：
  - `tb_ooo_int_backend` 1/1 PASS；`tb_ooo_mem_inflight_queue` 1/1 PASS。
  - `tb_ooo_fetch_axi_bridge`、`tb_ooo_mem_axi_bridge` 2/2 PASS。
  - 共享模块回归 113/113 PASS。
- `MEM-ISSUE-G1`：atomic pair capture、edge-old terminal ordering、backpressure hold、
  request-fire/terminal-consume/MIQ-birth owner identity、no-repeat、flush survivor 均满足；
  compile-success RTL mutation 11/11 rejected。
- `PTW-PMP-G1`：IFU F=0/2/4/6、LSU deny/allow、8B S-mode WRITE footprint、AW/W
  任意顺序、B terminal、owner/token/epoch/tval 稳定均满足；compile-success RTL mutation
  28/28 rejected。
- 完整 RTL source map 前后相同；编译产物全部位于 `/tmp` 且 cleanup rc=0。task-run 仅保留
  结果、正向/反例日志与摘要，无 `.vvp`、`.o`、`.a` 或 simulator binary。

## 原始 FAIL 与 checker replay

- `p0-direct-rebind-1.status` 原样保留：
  `FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0`。
- 唯一失败阶段是随后执行的历史 Python 单测；这些用例固定读取旧 canonical result/mutation
  summary，因此报告旧 full-RTL binding stale 及旧 `lsu_disable_write_request` anchor stale。
- 在失败前生成的 task-local current result 均为 PASS；本轮 PTW task-local mutation summary
  明确为 28/28 compile-success/dynamic-rejected/source-unchanged。
- 独立 `p0-direct-rebind-checker-replay-1.status=PASS`：重新核验 current design-id、完整
  source map、九项 directed checker、两项 result、39/39 RTL 反例、canonical 哈希与 4/4
  evidence-field 负向 fixture。该 replay 不回写原始 FAIL，也不冒充原 runner PASS。
- 证据：`evidence/p0-direct-rebind-checker-replay-1/rebind-receipt.json`。

## 独立审查

- 合同：`v14b-p0-review.contract.json`，SHA-256
  `cdbe48a1ed916dac37f948c742d1ee89e5375f6fc37daea79a9be8f053c5eb87`。
- 结论：`APPROVED_CURRENT_SCOPE`；只批准 `MEM-ISSUE-G1`、`PTW-PMP-G1` current dynamic
  scope，不批准 aggregate architecture、release 或 PPA。
- 保留风险：冻结摘要未逐项内联 mutation ID/内容哈希/target-to-observation 映射；没有形式覆盖率，
  不能外推 token/epoch 回绕、reset、分裂 AW/W 并发、同周期 flush/request-fire/B-terminal 或
  任意多 owner 时序；审查者未独立读取原始文件，因而置信度为中高。
- reviewer 建议：未来让 legacy 单测按 run-id/design-id 消费 task-local result，并给 mutation
  manifest 增加唯一 ID、内容哈希和目标观测映射。为控制流程开销，本轮不转成环境改造主线。

## 流程分类纠偏

- V14B 初始为只读 `analysis`；加入 task-local runner/receipt 后，原 agent-flow generation 按规则
  拒绝以 analysis 收尾并保留 `BLOCKED class=analysis forbids source modifications`。
- 未放宽规则、未重跑 RTL；另建同轮 delivery generation，按 `development` 分类复用既有证据，
  `RESULT=PASS`、archive=`none`。该分类反例留给后续自动分类纠偏，不影响上述 RTL 结论。

## 下一主线

优先对剩余 7 个 P0 做 changed-RTL transitive-cone audit；只有有效锥落入当前五文件或 simulator
语义改变的门才动态重跑，其余门走同样的 frozen-input replay + negative fixture。P0 current binding
归零前不启动 PPA 晋级。
