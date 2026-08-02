# RV64 V14D P1 direct active-cone current rebind

## 结论

- 对象：current design-id `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`，146 个 production RTL 文件；本轮 production RTL 零改动。
- 范围：`CONTROL-EVENT-G1`、`MIQ-FLUSH-G1`、`STORE-BRESP-G1` 均为 task-local `CURRENT_DYNAMIC_PASS`；独立 reviewer=`PASS_TASK_LOCAL_CURRENT_SCOPE`。
- 正向：CONTROL 16/16、MIQ 1/1、STORE 4/4，合计 21/21。
- 负向：24/24 compile-success RTL mutation 被动态拒绝，分别为 CONTROL 16、MIQ 3、STORE 5；24 个 `(source, variant_sha256)` 全部唯一，alias=0。
- 周期合同：CONTROL 覆盖 C0→C1 typed control-event 与 SQ retry holder；MIQ 覆盖 flush+pop 后只移除已消费 DRAIN、保留未消费 owner；STORE 覆盖 B-terminal 跨周期 holder、DECERR 精确捕获与 ROB `commit_ready` retirement hold。
- Icarus warning：CONTROL 2792、MIQ 4、STORE 1867，均由当前源行/数组或精确 TB port/signal matcher 解释；`unexplained=0`，正向 assertion failure=0。

## 历史状态

- `control-run-{1,2}.status` 与 `store-run-{1,2}.status` 均保留原始 `FAIL rc=1 stage=exit-trap evidence_complete=0 cleanup_rc=0`，没有原位改写。
- CONTROL attempt-1 是旧 Verilator UNOPTFLAT 行号 oracle 失配；attempt-2 是旧 warning 分类器失配。STORE attempt-1 是预期 FATAL 位置分类器误判；attempt-2 是遗漏 V13R 精确 optional IFU A/D port warning。
- 对应 checker replay 以正负向 fixture 固化新判据；当前 RTL 结果由 attempt-3 收据引用，历史 FAIL 只作纠偏证据。

## Fail-closed 边界

- Section13：P0 current=9/9，P1 direct current=3/3；仍有 `F0-G1`、`FENCE-G1`、`SERIALIZE-G1`、`VECTORED-TRAP-G1` 四项 current binding stale。
- historical backfill、producer/holder semantic coverage、functional aggregate、freeze inventory 与 architecture stable 仍未闭合。
- `architecture_gate_state=RED`、`arch_stable=false`、`ppa_state=BLOCKED_BY_ARCHITECTURE`、`promotion_eligible=false`；本轮不提供综合、STA、power、area 或 PPA promotion 结论。

## 证据指针

- P1 direct 权威收据：`evidence/p1-direct-1/receipt.json`
- CONTROL / STORE 汇总：`evidence/control-run-3/summary.json`、`evidence/store-run-3/summary.json`
- Section13：`evidence/section13-current-1/section13-current-audit.json`
- 独立审查：`subagent-contracts/v14d-p1-direct-final-review-v1.json`、`reviewer-result.md`
- 最终审计：`evidence/final-audit-1/audit.json`、`final-audit-1.status=PASS`
- task-run 仅保留脚本、结构化结果、选定日志和证据指针；无 `.vvp/.o/.pyc/variants/generated` 可再生产物。

## 下一主线

执行剩余 P1 current rebind：`F0-G1`、`FENCE-G1`、`SERIALIZE-G1`、`VECTORED-TRAP-G1`。按 gate 的实际 active cone 分类；只在 production RTL、实际 elaborated RTL、设备模型或 simulator 执行语义变化时升级到完整重跑，不从本轮三门 PASS 外推 architecture/PPA。
