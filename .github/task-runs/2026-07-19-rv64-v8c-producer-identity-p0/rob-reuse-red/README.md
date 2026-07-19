# OooRob 迟到旧写回 / 槽别名 current-RED characterization

## 结论与 runner 语义

该目录只新增本地 RTL 仿真资产，不修改 `OooRob` 或现有 canonical TB。它动态证明当前
production `OooRob` 的 WB 包只有 raw ROB index 时，真实 branch recovery 释放的 slot 被新
uop 重用后，迟到旧写回会错误更新新 uop 的 registered `done_q/data_q`。

这是 **current-RED characterization**：runner 只有同时观察到该错误行为和正确 new WB
正控制时才返回 PASS。未来修复生效后，本 runner 应失败，并由 full-identity regression 取代，
不能把这里的 PASS 解读为设计正确。

可重跑命令：

```bash
flock /tmp/ysyx-workbench-wsl.lock bash \
  .github/task-runs/2026-07-19-rv64-v8c-producer-identity-p0/rob-reuse-red/run-rob-reuse-red.sh
```

## 验证推导

### 1. 需求

- 使用 production `OooRob.v`，禁止层级 force、禁止 global flush 代替 branch squash。
- 通过真实 allocate/WB/commit 把空 ROB 的 head/tail 推到 15。
- 双发分配 `branch@15 + old@0`，以 `kill_rob_idx=15` 触发真实 ROB reverse walk。
- walk squash old@0 并把 tail 回退到0；branch 退休后 new 必须真实重用 slot0。
- 先注入 old 的迟到 raw-index WB，证明 new 的 registered done/payload 被错误更新；再完整重跑
  同一恢复序列，用 new 自己的 WB 作正控制。

### 2. 协议、状态机与优先级

| 阶段 | production 事件 | 期望观测 |
| --- | --- | --- |
| ROTATE | 15 次 allocate→WB→commit | 空 ROB 的 `head=tail=15` |
| ALLOC | lane0 branch@15、lane1 old@0 | `count=2` 且发生 index wrap |
| KILL | `kill_valid`, cut=15 | 当拍冻结 dispatch/retire，下一拍进入 recover |
| WALK | `recover_active`, walk0=old@0 | old invalid，`tail=0,count=1` |
| SURVIVE | branch WB/commit | branch 正常退休，空 ROB `head=tail=0` |
| REUSE | lane0 new allocation | new@0 live 但未 done |
| LATE-WB | wb1(old idx0/data) | 当前 RTL错误令 new candidate=1、payload=old data |
| CONTROL | 独立重跑后 wb0(new idx0/data) | new candidate/commit 携带 new data |

测试只在时钟下降沿后的稳定窗口改变输入；WB 在上升沿写入 Q，candidate 只观察下一组合窗口。
当前 T3W 设计没有 same-cycle head-WB bypass，因此本证据严格称为 registered done/payload 槽别名，
不声称存在已删除的 bypass。

### 3. 不变量与 oracle

- `old_idx == new_idx == 0`、branch cut 为15、old 经 walk0 被 squash，四个 witness 缺一即 FAIL。
- new 自身 WB 前 retire candidate 必须为0。
- 迟到 old WB 后，若 candidate 未变1或 commit payload 不是 `new_pc + old_data`，expected-RED
  witness 不成立，runner 必须失败。
- 正控制必须在相同 wrap/recovery/reuse 序列后得到 `new_pc + new_data`，排除 WB 端口未接、
  permit tie-low或 recovery 尚未结束造成的假绿。
- old/new 故意使用同一 physical destination 17；`OOO_ASSERT` 变体也必须复现，从而证明已有
  pdest sentinel 无法区分“同 pdest + 同 raw ROB index”的槽重用。

### 4. 数据通路与范围

TB 只驱动 `dispatch* / kill* / wb* / commit_ready` production 端口，oracle 只读
`walk* / recover_active / count / head / retire candidate / commit payload`。release 与
`OOO_ASSERT` 两个 Icarus elaboration 都运行同一时序。

本切片没有覆盖 shared WB fanout、PRF 写、IQ wakeup、FP done FIFO、所有 producer 的 kill、
full identity/generation、Linux、PPA、频率或形式证明；也不把一个 leaf current-RED 提升为完整
Q2/v8c 状态。

## 证据

runner 重建 `evidence/` 下的 release/assert compile 与 simulation 日志、source SHA、summary 和
`expected-red.complete`。关键 marker：

- `[ROB-REUSE-RED][WITNESS]`
- `[ROB-REUSE-RED][POSITIVE]`
- `[ROB-REUSE-RED][PASS]`
- runner 的 `[ROB-REUSE-EXPECTED-RED][PASS]`

## Strict guard 边界

已实际运行 `scripts/agent-e2e.sh --guard --guard-mode strict`。guard 观察到共享工作树
`changed_paths=1377`，复用的 `agent-system` 与 `github-index` evidence 为 PASS，但因全工作树
缺少 `npc-dev` profile evidence 而返回 1。本 focused 子任务被明确限制为只新增本目录文件，
不得修改 production RTL、canonical TB、memory，也不得在其他 task-run 生成 profile 产物，
因此没有越过范围补跑全工作树 `npc-dev`。这不改变上面的 OooRob leaf release/assert 证据，
但全工作树 workflow guard 仍由父任务统一闭合。
