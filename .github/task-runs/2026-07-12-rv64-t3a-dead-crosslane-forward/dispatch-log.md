# 派发日志

## 基本信息

- `task_id`: 2026-07-12-rv64-t3a-dead-crosslane-forward
- `graph_template`: architecture-refactor + timing-ab
- `log_policy`: append-only

---

### [2026-07-12 12:01 +0800] `recall-map` - PASS

- `owner_agent`: root + t3_prf_cut_audit
- `action`: 对齐 rename→busy→IQ wakeup/select→PRF/backend operand 全链。
- `outputs`: 证明 simultaneous valid integer RAW 不可达；read0–3 bypass 暂不可删，read8 必留。
- `handoff_to`: freeze-contract, negative-probe。

### [2026-07-12 12:03 +0800] `freeze-contract` - PASS

- `owner_agent`: root
- `action`: 冻结六类合同、RAW-I1 精确门控、删除清单与功能/时序验收边界。
- `outputs`: task-report + `ooo-int-issue-queue.md`。
- `handoff_to`: negative-probe, implement-delete。

### [2026-07-12 12:10 +0800] `negative-probe` - PASS

- `owner_agent`: root + raw_forward_red
- `action`: 在合法 independent 双 issue lane 上对 issue1 enabled source tag 做消费边界 mutation。
- `outputs`: runner rc=1，仅命中 RAW-I1；日志持久化到 `evidence/raw-i1-negative-final/`。
- `handoff_to`: implement-delete。

### [2026-07-12 12:17 +0800] `implement-delete` - PASS

- `owner_agent`: root
- `action`: 删除 6 个 dead-forward/current-result 符号，8 类 issue1 consumer 直连 PRF；
  新增三 uop WB-wakeup→issue1 write-through 常驻回归并修正 current 文档。
- `outputs`: focused 5/5、module 87/87、style/lint、contract 38/38，结构引用为 0。
- `handoff_to`: timing-ab, full-regression, record-review。

### [2026-07-12 12:22 +0800] `functional-review` - PASS

- `owner_agent`: dead_forward_final_review
- `action`: 独立检查 RAW-I1 门控、所有 consumer、三 uop 周期与 FP/long-op/memory 反例。
- `outputs`: OOO_ASSERT focused 5/5、负探针 rc!=0 且仅 RAW-I1，裁决 `NO BLOCKER`。
- `handoff_to`: timing-ab, final record-review。

### [2026-07-12 12:24 +0800] `timing-ab-isolation` - PASS

- `owner_agent`: root + dead_forward_timing
- `action`: 建立同 HEAD/config/tool/lib 的 A/B detached worktree 与完整 synth manifest。
- `outputs`: 105 个 RTL 输入中仅 `OooIntBackend.v` hash 不同；A full synth 已启动。
- `handoff_to`: timing-ab-remap。

### [2026-07-12 13:18 +0800] `timing-ab-remap` - REJECT CANDIDATE

- `owner_agent`: root + dead_forward_timing
- `action`: A/B 各做 NpcTop 200MHz target-driven full synth + OpenSTA 5ns top40。
- `outputs`: 两侧 105/105 target cone、0 problem；B WNS 无改善，TNS 恶化 18.23%，
  backend/top area +851.76，power 报告精度下 +0.001W；top40 完全相同且不含 backend。
- `decision`: 删除候选不满足优化门禁，必须回退；A 成为当前 timing baseline。
- `handoff_to`: rollback-delete, keep-raw-guard。

### [2026-07-12 13:20 +0800] `rollback-delete` - PASS

- `owner_agent`: root（审查者人格）
- `action`: 恢复 6 个 current-result/forward 符号与全部原 consumer，只保留 RAW-I1
  观察合同、三-uop GREEN、负探针与 current 文档修正。
- `outputs`: final OOO_ASSERT focused 5/5、module 87/87、style/lint、contract 38/38；
  final negative probe rc=1 且仅命中 RAW-I1。
- `handoff_to`: memory/guard/commit, next frontend slice。

### [2026-07-12 13:31 +0800] `record-review` - PASS

- `owner_agent`: root + dead_forward_final_review（实现者/审查者双人格）。
- `action`: 登记 300 个 raw evidence asset，回读 project/NPC/known-issues stored memory，
  运行 fresh `npc-dev` 5/5 与 strict guard，并复核最终 RTL 只增加 OOO_ASSERT 合同。
- `outputs`: 删除候选保持 REJECTED/ROLLED BACK；RAW-I1 guard slice 可精确提交，未借此
  越级声明 200 MHz 已达成。
- `handoff_to`: commit, frontend 5ns critical-cone architecture slice。
