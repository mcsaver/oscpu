# V11D dispatch log

## RECALL

- bounded brief：
  `python3 scripts/github_index_db.py brief OooPendingDrainResolveGate --profile npc-dev --focus-scope non-history`
  返回 `ok=true`、`recall_status=complete`。
- A3 checker-replay、V10D simulation-exit 与 V11C tracker map/live-set
  均已按原证据边界闭合。
- architecture debt ledger 无开放 P0/P1；V11C 明确留下
  `tracker-next-token-cursor` GAP，因此选择该单一技术目标。
- `npc/rv64/design/study/README.md` 当前不存在；按导航回退读取
  `npc/rv64/README.md`、`npc/rv64/design/README.md`、active spec 与
  `npc/rv64/design/history/study/README.md`，不把归档 RV32 笔记用作
  当前 RV64 allocator 语义依据。

## PLAN

1. 冻结独立 cursor 周期模型与反例矩阵。
2. 用机器可校验合同派发只读独立预审。
3. 依据预审只修改 verification/evidence 路径；发现 production 反例才重分类。
4. 跑 baseline、compile-success mutation、Python/ledger 与 task-specific e2e。
5. 独立终审后更新 task-run、memory、DB 与 guard。

## DISPATCH

- 预审合同：
  `subagent-contracts/v11d-memory-tracker-cursor-pre-review.json`
- 合同 SHA-256：
  `4f9bf8c34276eeba4a1758e4243583def7cd907e94f6ffd676646a13290c3cb9`
- reviewer 裁决：H1 静态支持、H2 未发现 production RTL 反例、H3
  假绿成立；任务保持 `verification` 分类。
- 主节点新增参数化独立 TB、cursor evidence builder/mutator、semantic
  ledger binding 与 ARCH_STABLE workflow binding，production tracker 不变。
- attempt-1 为 4/4 baseline、9/9 mutation PASS，但复读发现首个 lane1
  mutation failure 过早依赖 invalid-lane token 输出；原始证据保留，不晋级。
- TB 将 ready/token 比较限定到对应 valid，并显式加入 post-reset idle；
  attempt-2 重新绑定为 canonical PASS。
- canonical design-id：
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`
- canonical summary SHA-256：
  `21a209961c55f4036af32c716701ed52803caf2dd61889a9dfe662c1105d3a50`
- ledger：6 PASS / 38 GAP / 44，整体 `status=GAP`。
- ARCH_STABLE 自检：51/53；V11D 无新增失败，剩余两项为既有 V9R
  identity/status 与旧 full-core candidate dynamic-inventory GAP。
- 终审合同：
  `subagent-contracts/v11d-memory-tracker-cursor-final-review.json`
- 终审合同 SHA-256：
  `e783df2547e64f7674300370658b51819888e120a2ef1ee8c5d79e7e4afab001`
- independent final review：bounded APPROVE，blocker=0，仅覆盖
  `tracker-next-token-cursor`；直接 `next_token_q` 状态比较属于第二个
  oracle，valid-qualified token 合同与其余 38 个 GAP 保持显式。
- 终审后重放 ARCH_STABLE unittest 并保存原始日志：51/53，
  `v11d_new_failures=0`，两项既有 failure 继续按 GAP 记录。
- task-specific `npc-dev` run
  `2026-07-30-memory-tracker-cursor-semantic-revtag-v11d` 为 5/5 completed。
- V11D 10-path scoped strict guard PASS；全工作树 strict guard 仅因共享
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence 而 FAIL。
- final identity helper 重算 146-file RTL binding、核对 canonical 12-file
  manifest 与 production tracker SHA，结果 PASS。
- raw evidence index 当前为 141 assets。技术 task-run 不伪造
  `complete.marker`/`run-manifest.json`；Markdown 采用逐文档
  `update-stored`，canonical e2e publication 由独立五节点 run 承担。
- 8 份技术 Markdown 与两份 memory 已通过 `update-stored` 同步；
  `snapshot-stored`、DB-first、Markdown coverage 与 runtime-artifact
  audit 均 PASS。
- commit gate 观察 branch `ai`、HEAD `af027d1b...`、249 个 tracked
  修改、1,564 个 untracked 文件和一个无关 staged profile；未执行
  stage/commit，避免混入 shared-worktree provenance。

所有 Windows→WSL 工程命令保持 single-flight；预审 reviewer 结束时已明确
归还执行权，无遗留工程进程；终审 reviewer 结束时也已明确归还执行权。
