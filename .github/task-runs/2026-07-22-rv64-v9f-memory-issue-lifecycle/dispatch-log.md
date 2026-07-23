# RV64 V9F 子 agent 派发记录

## 统一边界

- 工作对象：授权工作区内的 RV64 Verilog/SystemVerilog 双发射 OoO 核、
  testbench 与本地证据；
- 合同管线：每轮均为 canonical `create → validate → render`，渲染提示原样派发；
- 模式：`read-only-review`、`self-contained-no-tools`；
- shell ownership：始终由主 agent 保留，reviewer 不执行工程命令或文件读写；
- parent goal：长期目标保持 active；每轮只审查 V9F 当前证据模型；
- contract SHA 只绑定对应 JSON，不绑定 design、spec、RTL、日志或 result。

## Proof-model review v1

- task：`/root/v9f_proof_model_review`
- contract：`.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/subagent-contracts/v9f-proof-model-review.json`
- contract SHA-256：`7529e8adffa5aa5d947f5b71b5cb260bd26b487151d7e1b9782c3293da9f2206`
- verdict：`GAP`
- 可操作发现：缺少 ready backpressure、发射后 exactly-once 和 owner identity
  的足够反例模型。
- 处置：增加 held-valid/ready-release、terminal clear/quiet window 和 15 字段
  identity scoreboard；扩展变异集合。

## Proof-model review v2

- task：`/root/v9f_proof_model_review_v2`
- contract：`.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/subagent-contracts/v9f-proof-model-review-v2.json`
- contract SHA-256：`a1fdbec51ab5cdb370c465774c71508d2f0feae45603172d272a16f6de77bb40`
- verdict：`GAP`
- 可操作发现：全局 bank fire 仍可能错误消费 terminal1；MIQ flush 尚未证明
  valid 但没有实际 pop fire 的 DRAIN head 必须保留。
- 处置：增加 terminal0 竞争 owner fire 场景、terminal1 hold/zero-birth
  oracle、valid/no-pop DRAIN head 场景和对应变异。

## Proof-model review v3

- task：`/root/v9f_proof_model_review_v3`
- contract：`.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/subagent-contracts/v9f-proof-model-review-v3.json`
- contract SHA-256：`af8b6a5827ab82ada63d893c02f47f4811120b5bcbb11a6a801bb15401e4c407`
- verdict：`GAP（条件式）`
- 可操作发现：需要冻结 terminal1 自身 grant/fire 与全局 bank fire 的单端口
  可达性不变量，以及 MIQ `pop_valid/pop_fire` 和 owner-match 的合法输入域。
- 处置：证据构建器加入静态 request/pop topology audit；明确 focused 配置
  `TB_ENABLE_DUAL_MEM=0`、bank0 fire 没有独立 accept 条件、MIQ 没有
  `pop_ready`，owner mismatch 是 assertion 定义的非法输入。

## Proof-model review v4

- task：`/root/v9f_proof_model_review_v4`
- contract：`.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/subagent-contracts/v9f-proof-model-review-v4.json`
- contract SHA-256：`5fb23bac8c79bfea6597f5814f42c30e76119f472c2335134cce27f81de52247`
- verdict：`PASS（局部、条件式）`
- accepted：单端口 grant/fire 代数、MIQ exact-owner 合法输入域、11/11
  变异灵敏度和 `t+1..t+3` bounded exactly-once。
- retained boundary：不覆盖 dual-port、`t+4` 以后、response/retire、完整
  core 或 PPA。

## 最终 evidence review

- task：`/root/v9f_final_evidence_review`
- contract：`.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/subagent-contracts/v9f-final-evidence-review.json`
- contract SHA-256：`a530367efc4e1fade81bb8134c537695e36006d3901a2f4b8c337a0be8d4d221`
- verdict：`PASS（限定性 PASS）`
- blocker 级反例：无；`MEM-ISSUE-G1` 与 `MIQ-FLUSH-G1` 可在当前
  design-id、单端口和给定证据边界内保持 CLOSED。
- accepted：请求 owner、terminal consume、MIQ birth、flush survivor、11/11
  变异、三路径来源 rebind、9/9 hard gate 与 arch-stable GAP 声明边界。
- residual：exact-owner 上游合同未独立证明；竞争路径只抽查 5/15 identity；
  backpressure/quiet window 有界；变异集合非形式完备。
- `scope_extension_request=none`；`confidence_and_basis=中高`。

## AI e2e wiring candidate review

- task：`/root/ai_trace_state_fix_review`
- authority：早期 delta 复核没有先绑定 task-local JSON 合同，因此只记为
  `candidate-only`，不追认为正式 PASS。
- 初始 verdict：`GAP`；要求补 exact collection invariant、幂等、metadata
  refresh、删除/peer-run 隔离、finalization 顺序、真实 CLI 与历史边界。
- follow-up：在上述行为 probe 与真实 targeted audit 计划补齐后给出有限
  `PASS`；其发现被吸收到正式合同，但该节点本身不授予最终审查状态。

## AI e2e wiring formal final review

- task：`/root/v9f_ai_e2e_final_review`
- contract：`.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/subagent-contracts/v9f-ai-e2e-audit-final-review.json`
- contract SHA-256：`61220627819dec28e25d1d05ee24a1ed36cab46fff627f4b30016c3e6233d05c`
- mode：`prompt-supplied-self-contained`、`read-only-review`；
  `allowed_commands=[]`、`write_paths=[]`，无 shell/filesystem/network/accounts/
  credentials/external-services authority。
- verdict：`PASS`；`blocker_counterexamples=[]`。
- accepted：仅对 manifest 已写定、按 `render manifest → index → validate`
  完成重新索引并通过验证的规范 final-state run，可接受
  `DB = ordinary_assets ∪ {唯一 canonical run-manifest.json}`；manifest 不进入
  ordinary count/bytes/kind/list。
- residual：索引后再次修改/删除 manifest 必须重索引；历史、blocked、
  non-final run 不自动迁移；并发写入/索引中断/崩溃中间态原子性未证明；
  不外推生产 RTL、full-core arch-stable 或 PPA。
