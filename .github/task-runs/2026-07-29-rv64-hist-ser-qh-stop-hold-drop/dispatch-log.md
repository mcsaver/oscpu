# Dispatch Log

## 2026-07-29

- 主 agent 冻结本地 RV64
  `OooFrontend.head0_csr_inflight_q`
  → `OooStopPendingSequencer.stop_pending_o`
  → younger lane1 pending-system capture 调用链。
- bounded brief 首次用目标专名检索未得到独立 focus；随后用
  `rv64 historical defect backfill loop --profile npc-dev
  --focus-scope non-history` 得到 `ok=true`，命中
  `.github/agentic-hardware-blueprint.md` 的独立工作流入口。
- 历史修复提交：
  `7f66f9d9d4badc08e0c51dc65c4db2b99683de46`。
- 当前 ledger selected：
  `HIST-SER-QH-STOP-HOLD-DROP=VD1`。
- 只读实验审查合同：
  `.github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/subagent-contracts/hist-qh-stop-hold-experiment-review-v1.json`，
  SHA-256
  `6225cf0183d3983fbf2a0d9fe8e4c785612c077eda6c69fc35ef6c341a64552d`；
  已按 canonical `create → validate → render` 通过。
- WSL 工程命令 single-flight ownership 已交给该只读节点；主 agent 在其返回前
  不运行其它 WSL 工程命令。
- 只读节点返回：
  - 静态链从 queue-head CSR birth 到 younger lane1 system capture 成立；
  - standalone sequencer 不能替代 product topology；
  - 原合同列出的
    `npc/rv64/design/verification/historical-defect-ledger.json` 不存在，真实路径
    更正为
    `npc/rv64/design/arch/historical-defect-backfill-ledger.json`；
  - 节点未修改文件，并归还 Windows→WSL 工程命令 ownership。
- product TB 首个 older-memory 版本观察不到
  `head0_csr_inflight && drain_complete && !commit`；正确 BNE 版本也观察到
  `branch_spec_resolve_valid=0, branch_resolve_untracked=0`。两者作为诊断失败
  保留，不计入 green evidence。
- 源码核对：
  - `7f66f9d9...^` 同时缺 sequencer inflight hold 与 RunGate inflight owner；
  - `7f66f9d9...` 只补前者；
  - `2a77fd4b6...` 后续补后者。
- 将原四 case 扩展为四种语义 × assertion on/off 八 case：
  current、drop-stop-hold、drop-RunGate-owner、historical-pre-T3U。
- matrix 结果：`8/8 compile-success, 8/8 oracle PASS`。current 与
  drop-stop-hold 保持 zero gap/drop/run/overlap；drop-RunGate-owner 得到
  `gap=2, run=2, real overlap=1`；historical-pre-T3U assertion-off 得到
  `gap=1, drop=1, run=2, real overlap=1`，assertion-on 保留并触发现有
  QCSR/owner assertion。
- runner/oracle 定向单测第一次因 Python dynamic module 未注册
  `sys.modules` 失败；只修正测试夹具加载后 `7/7 PASS`，没有修改 RTL 或
  oracle 条件。
- 完整 matrix replay：
  summary bytes、case logs、normalized VVP identities 稳定，`PASS`；raw VVP
  bytes 因 allocator 标识变化明确不作为 semantic identity。
- 分层 positive 回归：
  - `tb_ooo_core_top_glue_v9o_csr_qh` assertion on/off：PASS；
  - `tb_ooo_stop_pending_sequencer` assertion on/off：PASS。
- 主 agent 当前持有唯一 WSL 工程命令 ownership；下一步为模块 aggregate、
  证据冻结和独立 RTL reviewer。
- assertion-on module aggregate 完成 `113/113 PASS`。
- final reviewer 合同首次 create 时，`git`/`jq` 未在 command catalog 中取得
  非空 purpose，schema fail-closed；未派发该候选合同。收窄为已登记的
  `rg/sed/sha256sum` 后完成 canonical `create → validate → render`：
  - JSON：
    `subagent-contracts/hist-qh-stop-hold-final-review-v1.json`
  - SHA-256：
    `f585e77a3b99d950897d91c527f1c542cb5008445c0eaf26ad1ebce9ca693988`
  - rendered：
    `subagent-contracts/hist-qh-stop-hold-final-review-v1.rendered.md`
- final reviewer 使用 `fork_turns=none`，只读核对 sequencer、RunGate、
  frontend/control-plane/drain gate、TB raw scoreboard、8 个 case 的 source
  diff/compile receipt/log hash 与 replay identity，归还 WSL ownership 后给出
  `PASS（仅 bounded VD3）`。
- reviewer residual：
  - BNE 是 natural timing witness，不是当前 domain-A clear root；
  - combined negative 只能称 current-topology root-cone equivalent；
  - `successor_packet_cycles=0` 阻止 hold-only survival 外推；
  - 不关闭 VD4、formal、full-system、architecture-stable、综合、STA 或 PPA。
- 已修正 TB 中 BNE “competing clear”注释；随后重新执行：
  - matrix `8/8 compile-success, 8/8 oracle PASS`；
  - runner/oracle 单测 `7/7 PASS`；
  - replay summary/log/normalized images `PASS`；
  - V9O assertion on/off PASS；
  - module aggregate `113/113 PASS`。
- ledger 已按双合同根因更新：
  `VD0=0, VD1=0, VD3=3, VD4=2, selected=NONE, status=PASS`；
  `historical_defect_backfill.py --require-clear` PASS，定向单测 `4/4 PASS`。
- 联合运行 ledger 与 arch-stable 定向测试时：
  - ledger live-state 旧断言仍写死 `VD1/SELECTED/GAP`，已同步为
    `VD1=0/selected=NONE/PASS`；
  - 另外 3 个失败来自既有 `CONTROL-EVENT-G1/V9R` source hash drift，
    包括本轮范围外的 `tb_ooo_int_backend.sv`；未刷新或掩盖，full-core
    `ARCH_STABLE` 保持 GAP。
- DB-first memory：
  - project-status `58675 → 61454` bytes；
  - modules/npc `54769 → 58008` bytes；
  - 两份均 `update-stored`、refresh shim、snapshot；最终 audit 中无本轮
    memory mismatch，全局仅剩 8 个既有历史 task-run `missing_backup`。
- task-specific e2e
  `2026-07-29-rv64-queue-head-stop-owner-historical`：
  `npc-dev completed 5/5`，7 个 evidence asset 已索引。
- 本 task-run raw evidence 已索引 `285` 个 asset；20 条 scoped path 的
  strict guard 只要求 `npc-dev`，结果 PASS。
