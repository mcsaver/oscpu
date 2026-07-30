# HIST-SER-QH-YOUNGER-STORE-CYCLE 派发日志

## root：根因与判别实验

- RTL 对象：
  `OooIntBackend.mem_idle_o/mem_retire_quiet_o`
  → `OooRob.head0_csr_mem_hold_w`。
- 周期/配置：
  queue-head CSR + younger SQ STORE；
  current/fixed/cycle 三种语义 × assertion on/off。
- 工程动作：
  产品前端 lane pair 观测、backend 原始计数器、可编译历史 root-cone
  reconstruction、ledger audit 与定向单测。
- 硬边界：
  production RTL 不改；不得用事件抑制掩盖重复 C0/C1；不得把 backend
  注入表述为产品可达；不得把单项 VD3 外推为 architecture/PPA。

## experiment-review-v1：预审结果

- contract：
  `subagent-contracts/hist-qh-younger-store-experiment-review-v1.json`。
- 结论：
  产品 glue 中 queue-head CSR 与 lane1 pair 会被前端抑制；直接 backend
  输入可形成区分状态，但当前 owner-live 语义令 `mem_idle=0`，不能直接
  充当历史 fixed 对照。
- 采纳动作：
  保留 current owner guard，并构造只改变历史根锥的 transport-idle
  fixed/cycle 两个版本。
- WSL ownership：
  reviewer 完成只读复核后已归还。

## transport-quiet-review-v2：未形成裁决

- contract：
  `subagent-contracts/hist-qh-younger-store-transport-quiet-review-v2.json`。
- 状态：
  节点未在限定时间内返回可采用的 PASS/GAP 技术裁决，主节点终止该节点。
- 处理：
  不把该节点记录为 PASS；其缺口由可编译历史重建与 v3 独立终审替代。

## root：实现与验证

- production `OooIntBackend.v`：
  前后 SHA-256 均为
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`。
- focused runner：
  `run-historical-reconstruction.py --refresh`。
- 结果：
  6/6 编译成功；current guard 2/2 PASS；historical fixed 2/2 PASS；
  historical cycle 2/2 在专用根窗口被动态拒绝。
- 产品前端：
  三个 committed 与两个 selectively killed queue-head CSR transaction
  均为 `birth=1, lane1_fire=0`。
- 回归：
  `tb_ooo_int_backend` PASS；ledger audit valid/GAP；定向 Python 单测
  4/4 PASS。

## final-evidence-review-v3：派发

- contract：
  `subagent-contracts/hist-qh-younger-store-final-evidence-review-v3.json`。
- contract SHA-256：
  `4d20cf8e613066b2907e26ac8e855f951122de6d11b2fa9517342d9c3e025729`。
- 校验：
  canonical `create → validate → render` PASS；子节点使用隔离的
  `fork_turns="none"` 和合同 render。
- 复核重点：
  产品可达性、backend raw counter、历史版本唯一 anchor、编译成功、
  assertion-off 等价、production identity、ledger VD3 及剩余 VD1。
- WSL ownership：
  唯一工程命令执行权在派发期间交给 reviewer，root 未并行启动工程命令。

## final-evidence-review-v3：结果

- verdict：
  `APPROVED_FOR_BOUNDED_VD3`。
- 审查结论：
  `HIST-SER-QH-YOUNGER-STORE-CYCLE` 可由 VD1 提升为限域 VD3。
- 保留范围：
  backend C1 是 TB 注入；重建不是完整历史快照；T3U 是诊断失败；
  四拍负向观测不是无限期形式证明。
- 整体状态：
  `HIST-SER-QH-STOP-HOLD-DROP=VD1`，ledger/architecture/PPA 继续
  `GAP/GAP/UNQUALIFIED`。
- WSL ownership：
  reviewer 已结束全部只读命令、无残留工程进程，并显式归还。

## root：replay identity 纠偏

- 触发：
  完整重放后 RTL 行为仍 PASS，但 raw `.vvp` image SHA 变化，ledger
  对 summary/product log 的旧哈希正确地返回 `INVALID`。
- 根因：
  Icarus textual VVP 的内部 cross-reference 名含当次进程分配地址；
  这些地址不改变 elaborated connectivity，却使 raw image SHA 非确定。
- 修订：
  runner v2 为每个 case 保留 raw image receipt，并在 ledger-bound
  summary 中使用 allocator-normalized VVP SHA；测试判据、RTL variant、
  assertion 配置和原始事件计数均不变。
- 验证：
  normalizer 正负向单测 2/2 PASS；连续两次六 case replay 的 summary
  字节相同；product frontdoor 与 module log 在 canonical build path
  上各重放一次后也字节相同。
- 下一复核：
  因 evidence identity 与哈希发生版本化变化，需新的只读 reviewer
  合同确认 v3 RTL 裁决仍适用于 v2 summary，不能沿用旧哈希静默通过。

## final-evidence-review-v4：派发

- contract：
  `subagent-contracts/hist-qh-younger-store-final-evidence-review-v4.json`。
- contract SHA-256：
  `b10cb173f390f7ae84f5dc6d4801aa7d2ddf2cad6a100f32c0a946654ffd5435`。
- skill：
  `prepare-rtl-task-contract` canonical `create → validate → render` PASS；
  新 reviewer 以 `fork_turns="none"` 消费原样 render。
- 复核重点：
  normalized VVP 是否只补工具内部身份稳定性、raw receipt/source/log/oracle
  是否仍保留、双 replay 是否 byte-equal，以及 v3 限域 VD3 是否仍成立。
- WSL ownership：
  唯一执行权交给 reviewer；root 在审查期间未运行工程命令。

## final-evidence-review-v4：结果

- verdict：
  `APPROVED_FOR_BOUNDED_VD3`。
- 结论：
  六组行为、assertion-on/off、产品 `lane1_fire=0`、production design-id
  与 ledger VD3 均保持成立；evidence identity v2 没有降低绑定强度。
- 保留边界：
  normalizer 单测不是所有未来 VVP 语法的完备证明；第一次 replay raw
  digest 未单独持久化，但最终逐 case raw receipt、source/log/oracle
  均在，因此不阻塞当前限域裁决。
- scope extension：
  `none`。
- WSL ownership：
  reviewer 已结束全部只读命令、无遗留工程进程并显式归还。

## root：workflow closure

- bounded recall：
  首个过窄查询因缺少独立 non-history focus match 正确返回 failed；改用
  蓝图 canonical 入口 `rv64 historical defect backfill loop` 后
  `ok=true`，命中 `rv64-historical-defect-backfill-loop`。
- retained store：
  current `project-status.md`、`modules/npc.md` 与相邻 V10G 五份 live
  文档已同步；本轮相关 missing/content mismatch 为 0。
- evidence index：
  task-run raw evidence 已登记；pre-update ledger test 与 T3U admission
  失败保留为 diagnostic，不作为 current PASS。
- e2e：
  `2026-07-29-rv64-historical-defect-backfill-loop` 的 `npc-dev`
  profile completed，5/5 PASS。
- strict guard：
  对 `guard-paths.txt` 的 17 个本轮路径要求 `npc-dev`，绑定 completed
  profile 后 PASS。
- external workflow GAP：
  DB-first 全局 rc=1 只剩 183 个更早历史 task-run live-content drift；
  不含当前 memory/task-run，保留范围豁免而不写成 PASS。
