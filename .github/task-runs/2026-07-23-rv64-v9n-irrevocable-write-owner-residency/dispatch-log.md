# V9N dispatch log

## owner-residency-review-v1

- task kind：本地 RV64 STORE/AMO stateful-holder 只读复核。
- contract JSON：`.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/subagent-contracts/owner-residency-review-v1.json`。
- contract SHA-256：`591ea7e3b13a46e1d142d4223752b0b67f41c89ec0b8cca0afe5fbaa60d28e51`。
- contract pipeline：`create → validate → render` 已通过。
- write paths：空。
- reviewer：`/root/v9n_owner_residency_review`；只执行合同允许的 `rg`/`sed`，无写入。
- reviewer 结论：`GAP`；确认现有 STORE/AMO holder-qualified 同沿断言无法独立检出
  NBA 后下一拍 exact holder 消失，并明确归还 WSL shell ownership。
- 合同偏差：授权的 ledger 路径少了 `arch/`；reviewer 未据此读取其它路径。该偏差不以
  口头扩域修补，主 agent 直接从权威入口确认实际文件为
  `npc/rv64/design/arch/architecture-debt-ledger.json`。
- follow-up：主 agent 回查生产装配，确认唯一 `NpcCoreTop` RTL 实例静态连接
  `OooCoreTopGlue.flush_i=1'b0`；此事实由 V9N evidence builder 单独绑定。
- status：`REVIEW_COMPLETE_GAP_CONFIRMED`。

## owner-residency-review-v2

- task kind：本地 RV64 STORE/AMO 次拍 transaction-owner 驻留只读终审。
- contract JSON：`.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/subagent-contracts/owner-residency-review-v2.json`。
- contract SHA-256：`de35267426484ede9e84b382cb29c107656f02fb069baaf8593965289a515315`。
- contract pipeline：canonical `create → validate → render` 已通过；提示原样取自
  `owner-residency-review-v2.prompt.md`。
- write paths：空；工程命令仅 `rg`/`sed` read-only。
- scope correction：ledger 使用实际路径
  `npc/rv64/design/arch/architecture-debt-ledger.json`，并加入 canonical
  `NpcCoreTop.flush_i=1'b0`、两个 verification wrapper、两个 compile-success RTL
  源码变体、当前 design-id evidence 与 38-blocker arch-stable 结果。
- WSL shell ownership：派发期间交给 reviewer；主 agent 与其它 agent 不并发运行工程命令。
- status：`REVIEW_DISPATCH_READY`。
