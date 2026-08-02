# Dispatch log

- 工程对象：本地 RV64 producer/holder transaction identity、holder lifecycle、current-design
  graph/census/semantic evidence；production RTL 零改动。
- Windows→WSL 工程 shell 全程 single-flight；独立 reviewer 使用
  `prompt-supplied-self-contained`，不运行 shell、不读取仓库、不写文件。
- 子任务合同：
  `.github/task-runs/2026-08-02-rv64-v13w-producer-holder-current-rebind-v1/subagent-contracts/v13w-frozen-delivery-review.json`；
  SHA-256 `36f306bc1431ff4c877065948431d547e9361a75738e0418eb54e313013e4429`，只绑定该 JSON。
- reviewer 原始结果：`evidence/reviewer-frozen-material-result.md`。反例落地结果：
  `evidence/reviewer-counterexample-closure.json`；结论为 holder local PASS、architecture/system/PPA GAP。
- 选择性删除前预览：`evidence/semantic-vvp-retirement.json`；删除结果：
  `evidence/compile-image-retirement-receipt.json`；逐镜像引用闭包：
  `evidence/compile-image-reference-closure.json`；Yosys 去重：
  `evidence/yosys-full-graph-hardlink-dedupe.json`。
- 历史 V11H attempt-99 状态是本轮误落路径，已迁入当前
  `evidence/v11h-load-queue-current/historical-runner-attempt-99.status`；历史原始 attempts 和
  attempt-4 FAIL 未改写。
- 路径/目录由 `scripts/agent-flow.sh` 的 C controller 记录；未用 Git 枚举整个工作树，也未把
  用户同步修改纳入本轮结论。

