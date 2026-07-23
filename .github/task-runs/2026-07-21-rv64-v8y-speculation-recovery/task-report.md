# RV64 V8Y OOO-4 推测恢复硬门报告

## 工程范围

本轮只处理授权工作区内的本地 RV64 双发射 OoO Verilog/SystemVerilog 处理器、testbench、Icarus/静态 checker、架构证据和任务审计产物。多义术语均限定为流水线事务、RTL 信号、分支错误预测恢复或 compile-success RTL 验证变异语义；不涉及网络扫描、远程主机、账号、凭据、第三方服务或未授权系统。

## 交付结论

- OOO-4 `speculation_recovery` 在最终 design/suite 绑定内为 scoped `GREEN`。
- `DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3/OOO-4=GREEN`；`DI-1/DI-2/overall=RED`。
- PPA 仍为 `UNQUALIFIED`，`promotion_eligible=false`；本轮没有 production RTL 功能修改，也没有正式 PPA 晋级。
- 长期完整 OoO/PPA 目标保持 active；下一架构主线是 DI-1 与 DI-2。

## 实现者交付

1. `tb_ooo_int_backend.sv` 新增同一 focused 二进制内的两类控制流恢复布局：linear `D0/A1/B2` 与 ROB 环回 `D14/A15/B0`。A、B 同时驻留且独立就绪时，只允许最老 A 发射和解析；B 的发射、解析、完成和退休必须为零。
2. 两种布局均使用 full ProducerId ledger 检查 D/A 各完成一次、退休一次，B 完成/退休为零；恢复后严格年轻 B 从 ROB、IQ 与全局 holder census 清除，older D 与 boundary A 保持精确开放，最终所有 holder 守恒归零。
3. 同一 focused 二进制复用 V8D 的 EX-stage 严格年轻事务清除矩阵和 V8X 的真实 backend MIQ + dual-memory bridge 排空轨迹，覆盖已握手 AXI 读的 drop/pop/terminal，以及 pre-AXI killed station 的精确终结。
4. 新增 `make -C npc/rv64 check-speculation-recovery` 永久入口、专用 evidence builder 和 9 项 compile-success RTL 验证变异。evidence builder 精确校验 marker 唯一性、metric mapping、source pre/post、同 design predecessor、命令与 provenance，并以原子 merge 发布定向记录。
5. `architecture_hard_gates.py` 新增 OOO-4 七项指标和 exact command/source/provenance 检查；最终 `architecture-current.json` 在同一 design_id 下同时保存七项定向记录。

## 规范运行证据

- canonical command：`make -C npc/rv64 check-speculation-recovery`
- 最终 suite：`v8y-ooo4-20260721T072758Z-1732951`
- design_id：`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`
- focused：assert/release `2/2 PASS`
- OOO-4 metrics：`7/7 GREEN`
- compile-success RTL verification mutations：`9/9` 编译成功且均被定向 oracle 动态检出
- 相邻回归：`6/6 PASS`
- source manifest：27 个唯一文件，聚合 SHA-256 `fa41ce6b191c065fd49de4491175be752d277d6f2b7a41e3df4ab102cb743a41`
- source pre/post 文件 SHA-256：均为 `42d0b58102a5c08de5cc6696c8de7241f7598752d67efddb6cdf838296bf29cc`
- provenance：52 个唯一文件，聚合 SHA-256 `e25ce5fbf2b056774913174dacf52eb733fe83cee290e2ff57f803e7782b9812`
- architecture gate 日志 SHA-256：`979ad5792cbb96ef760c49d250af52a0635d229182e0f5e4b3c1da1f00bcd384`
- 完整可综合 RTL 源集：145 个文件

## 运行中暴露并修正的根因

1. 首轮完整运行发现前序 OOO-3 evidence 绑定旧 design_id。canonical runner 现在先在 live design 上重建 memory-ordering predecessor，再构造 OOO-4；不借用跨摘要 GREEN。
2. 前序 F2 runner 直接从 `npc/rv64` 调 Icarus 时没有加入 testbench include 根路径，无法找到 V8X bridge include。修复为给直接编译命令加入 `-I "$NPC_HOME/testbench"`；F2 随后 6 个配置和 18 项 RTL 验证变异全部通过，处理器 RTL 语义不变。
3. 重跑时旧 OOO-4 sibling 会被 pair-matrix 的阶段局部规则拒绝。runner 仅在开始时移除既有 `speculation_recovery` 记录，重建前序后再发布新的 OOO-4，最终七项记录均存在且绑定同一 design_id。
4. `dispatch-log.md` 会在 reviewer 返回后继续更新，若列入 architecture proof 会造成正常审计记录自污染冻结摘要。它现保留在 task-run/数据库审计层，但从架构 source/provenance 输入中移除；RTL、testbench、oracle、runner 与 gate 证据均仍受哈希约束。

## 审查者结论

- 初始合同复核返回 `GAP`，提出 ROB 环回、full-ProducerId 完成/退休账本、逐指标变异和同 suite/design 绑定；这些反例均已转为可执行 testbench、mutation 与 fail-closed evidence gate。
- 历史 final-review-v1 对旧 suite 给出限定材料 `PASS`，但最终运行绑定变化后只保留为审计历史。
- final-review-v2 合同 `.github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/subagent-contracts/v8y-speculation-recovery-final-review-v2.json`，SHA-256 `53fefcc58f5072b34aee9eb836326592fad8db54b5d1bad8901f2541d7fdee85`。独立 no-tools reviewer 对最终冻结材料给出 `PASS`，未发现未闭合反例，并确认两项运行生命周期修正不造成 stale-record 假绿或证据自污染。
- reviewer 未独立重算源码、日志或哈希，也未检查冻结摘要之外的 RTL 路径，因此结论只授权 OOO-4 scoped GREEN，不授权 overall architecture、仓库级独立审计或 PPA。

## AI 工作流与数据库收尾

- task-run raw evidence 已由 `index-evidence --write-index` 登记 37 个资产，报告、派发、合同与推导 Markdown 已进入 retained DB/backup；`audit-db-first` 与 `audit-markdown-coverage` 均 PASS。
- bounded startup recall `brief "OOO-4 speculation recovery" --profile npc-dev --focus-scope non-history` 为 `complete`，在 2400-token 上限内从当前 NPC memory 命中本条主事实。
- task-specific `npc-dev` e2e `.github/task-runs/2026-07-21-rv64-ooo4-speculation-recovery/` 已 completed，5 个展开节点全 PASS，`publication_contract=db-marker-v1` 且 `publication_valid=true`。
- 最终 strict guard 要求 `agent-system`、`npc-dev`、`github-index` 三个 profile；三者均有有效 completed evidence，guard PASS。

## 主要产物

- 设计/验证推导：`rtl-derivation.md`
- 任务合同：`contract.md`
- canonical runner：`run-focused.sh`
- 变异 runner：`run-v8y-mutations.py`
- 最终机器结果：`evidence/final-run/result.json`
- 最终审查：`final-review-v2-result.json`
- 子任务派发审计：`dispatch-log.md`

## 剩余风险与下一步

- DI-1 与 DI-2 仍为 RED，因此全核 architecture 仍未稳定，不能冻结正式全核 PPA 基线。
- no-tools reviewer 的未知项包括未独立重算 SHA、未检查原始波形和 runner 文件更新原子性；当前由 canonical runner、pre/post manifest、原子 evidence merge 与单元/变异门提供机器约束，但不把它们表述为形式完备证明。
- 下一轮应先从架构债务账本选择 DI-1/DI-2 中最老且可原子闭合的 P0/P1 子切片，再重复“合同—反例—focused—mutation—aggregate—同摘要 evidence—独立审查”流程。
