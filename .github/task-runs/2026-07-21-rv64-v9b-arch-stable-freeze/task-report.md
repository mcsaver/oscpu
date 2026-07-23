# RV64 V9B full-core arch-stable freeze 报告

状态：检查工作流 `PASS`；当前 full-core `architecture_freeze=GAP`。

## 本地工程边界

本轮对象仅为工作区内的 RV64 Verilog/SystemVerilog 双发射 OoO 核、架构合同、仿真证据和
EDA 冻结输入。未运行正式综合、STA、物理实现或 Power 分析；所有 PPA 字段仅用于拒绝不合格
晋级，不构成频率、面积、功耗或 Pareto 结论。

## 实现者结论与证据

- 永久入口：`bash npc/rv64/eval/ppa/run-arch-stable-audit.sh`。
- 检查器、五项 JSON schema、canonical runner 与 38 项正例/定向反例测试已落盘。
- canonical runner 完成 `38/38` 测试、current audit 与 current verify，三者返回码均为 0。
- 当前设计绑定：`sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- 当前结果：`113 PASS / 46 GAP`，`architecture_freeze=GAP`，`ppa=UNQUALIFIED`，
  `promotion_eligible=false`。
- task-run result：`evidence/arch-stable-current.json`，SHA-256
  `f1fef32b525090a17b94e6d370f23d8361f5f4dedd3be60326e8b36b49e9a4d5`；内容评价摘要
  `evaluation_sha256=2942e092686519889dd85ebf49f5d745f728d5e76c71b57b7bc2dd5bf7a2a4ed`。
- 九项 DI-1..DI-5 / OOO-1..OOO-4 架构定向门在同一设计上为 `9/9 GREEN`；该事实只证明
  已声明的九项合同，不替代 full-core debt、holder census、功能 aggregate 或冻结输入闭合。

## 审查者结论与反例复核

- v2 独立复核实际发现两条可执行假绿路径：零字节 functional log 未检查语义 marker，以及
  `./` 非 canonical 路径别名绕过跨组文件身份复用检查。实现者修复根因并补充永久回归。
- v3 独立复核重新执行 38 项测试、current verify，以及空日志、重复 marker、日志 inode 复用、
  非 canonical 路径、父目录 symlink 与 hardlink identity 等定向反例，结论为
  `WORKFLOW=PASS`，未发现声明的冻结合同反例集合内残留的可执行假绿或假拒绝。
- v3 evidence：`evidence/reviewer-v3/review-summary.json`，SHA-256
  `f3ab9a4352a513555780609a37b5ab7b7c0edb94c4acb4096853640af866af40`。

## 仍未闭合的 full-core 条件

46 个 blocker 均被 fail-closed 保留：

- 19 项未闭合架构债务：`OPEN=3`、`STALE_EVIDENCE=11`、
  `SCOPE_DECISION_REQUIRED=5`；仅 `STORE-BRESP-G1` 为 `CLOSED`。
- 2 项 holder/owner census 缺口：当前 census 尚无完整设计绑定、实例图/语义闭合及动态生命周期证据。
- 1 项功能 aggregate 缺口：尚无同一设计绑定的 109 个动态导出模块测试、official 177、AM 59、
  DiffTest 与 benchmark 语义汇总。
- 24 项 cohort/freeze-input 缺口：规范 cohort inventory 及 config、generated header、filelist、
  specification、test source、workflow、tool executable/version、Liberty、macro、SDC、image、binary
  和运行参数尚未形成完整内容寻址清单。

## 证明边界与下一步

工作流证明的是冻结资格检查的输入闭包、内容绑定和 fail-closed 行为；它不提供外部证明，也假设
单次审计期间工作区文件不会被并发替换。下一架构切片优先闭合 P0 `INSTRET-G1`：补齐程序级
回归，证明异常退休贡献 0、每条合法控制退休贡献 1，并绑定当前设计的 compile-success RTL
source mutation。完成剩余 P0/P1、census、功能 aggregate 和完整输入清单前，不签发 arch-stable。

## DB 与 e2e 收尾

- 稳定结论已通过 `update-stored` 写入 `.github/memory/project-status.md` 与
  `.github/memory/modules/npc.md`，随后刷新 retained snapshot；`audit-db-first` 与
  `audit-markdown-coverage --fail-on-live-evidence` 均 PASS。
- final fresh `npc-dev` run：`.github/task-runs/2026-07-21-rv64-architecture-stable-freeze-final-revtag-v9b/`，
  5/5 profile nodes PASS、6 个 evidence asset、canonical publication `completed`。
- strict guard 对当前工作树推荐的 `agent-system`、`npc-dev`、`github-index` 三个 profile 全部 PASS。
- 最终再次运行 canonical freeze runner：38/38 tests、audit、verify PASS；live result SHA-256
  `d72c31aaaae5aa0eb05dc3a4b26375b163462dbf8f90ff3c3cdabab175369c81`，内容评价摘要仍为
  `2942e092686519889dd85ebf49f5d745f728d5e76c71b57b7bc2dd5bf7a2a4ed`，资格状态仍为
  `113 PASS / 46 GAP`。
