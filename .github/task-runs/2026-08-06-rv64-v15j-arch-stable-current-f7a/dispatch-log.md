# RV64 ARCH_STABLE dispatch log

## v15j-arch-stable-independent-review-f7a-v2

- 工程对象：本地 RV64 双发射 OoO 核 exact ARCH_STABLE candidate，只读独立反例复核。
- 合同：`.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/subagent-contracts/v15j-arch-stable-independent-review-f7a-v2.json`
- 合同 SHA-256：`e2eebbf8a54d9ad6cd7269614ab6fa9d485eb657202542f7ab4620281c725623`
- candidate SHA-256：`3d5f5d5813c680373ff1da361cc282e1faf35ec57f3a72ac49afccfcac1668b7`
- 权限：`read-only-review`；命令仅 `rg`、`sed`、`sha256sum`；无写路径。
- WSL single-flight：主节点把一个有界只读命令批次交给 reviewer；reviewer 返回后归还。
- 父目标：保持 active；本节点只裁决当前 candidate，不签发 PPA 或可选 Ubuntu 结论。
- 结论：`GAP`；未输出 approval marker。结构性反例为 candidate/checker 未直接消费 L2/L3/Ubuntu 分层回执，且合同缺少 live config/generated-header 与可审计工具身份输入。
- 报告：`.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/evidence/arch-stable-independent-review-f7a-v2-gap.md`
- 执行权：只读命令已停止，WSL shell ownership 已归还。

## v15j-arch-stable-independent-review-f7a-v3

- 工程对象：本地 RV64 双发射 OoO 核 candidate schema v2，只读复核上一版 system/layered consumer GAP 的关闭结果。
- 合同：`.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/subagent-contracts/v15j-arch-stable-independent-review-f7a-v3.json`
- 合同 SHA-256：`7f6ef838f0045c90f2b07d0e5c8e1995e45a223326cb646699d35c88d41a266a`
- candidate SHA-256：`4f25d52d235e8f19a5050302ea91de7e8be8197fa0af3f6163b7586b61ccd0f1`
- 扩展输入：live `.config`、generated headers、module specs、liberty、workspace-bound tool identity receipt、system/layered receipt 与 v2 GAP 报告。
- 权限：`read-only-review`；命令仅 `rg`、`sed`、`sha256sum`；无写路径。
- WSL single-flight：由主节点显式交付一个有界只读批次，完成后归还。
- 结论：`PASS`；`unknowns=[]`、`scope_extension_request=none`，exact approval marker 恰好一次。
- 报告：`.github/task-runs/2026-08-06-rv64-v15j-arch-stable-current-f7a/evidence/arch-stable-independent-review-f7a-v3.md`
- 反例复核：上一版 system/layered consumer 缺口由 candidate schema v2、canonical replay 与四个负向测试关闭；L1 原 FAIL 保留，PPA 未晋升。
- 执行权：全部只读命令已停止，WSL shell ownership 已归还。
