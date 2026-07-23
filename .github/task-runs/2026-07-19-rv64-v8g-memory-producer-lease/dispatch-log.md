# v8g dispatch log

## `v8g-memory-lease-contract-review`

- `task_kind`: `read-only-review`
- `contract_json`: `.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/subagent-contracts/v8g-memory-lease-contract-review.json`
- `contract_json_sha256`: `de5814ab05adf13e0d966e5963b1b948dea5fa4c287fd5938e27bddd79b1b0a2`
- 哈希只绑定上述 JSON；不绑定 active spec、设计 `contract.md`、RTL、TB 或其它上下文。
- JSON canonical 权限上限只含只读 `rg`；本次实际调度进一步收紧为 **no tools / no shell / no
  file access / no network**，只消费主 agent 提供的自包含冻结摘要。
- Windows→WSL 工程命令只由主 agent single-flight 串行调度；子 agent 不启动 `wsl.exe`。
- 若平台不处理该节点，只记 `review_pending`；父目标保持 `active`，不得改变 RTL 语义重试。
- `first_review`: 3 blockers（AMO/STORE launch、STORE B terminal、completion credit atomicity）
- `response`: 已新增 `contract-amendment-v8g1.md` 并同步 active spec/census/derivation；未改 RTL。
- `second_review`: v8g.1 主方向成立，但仍有 4 blockers（open/closed 重叠、
  launch capability 不充分、`done_now` B 误 death、collector credit/WB 活性）。
- `response`: 已新增 `contract-amendment-v8g2.md`，同步 active spec/contract/derivation；
  仍未改 RTL。
- `status`: v8g2_amendment_pending_rereview
- `third_review`: v8g.2 仍有 5 blockers（tracker exact-tag、post-launch `!head_done`、
  terminal credit 间接环、bounded grant 未覆盖 side-effect credit、AMO-write-sent 误归类）。
- `response`: 已新增 `contract-amendment-v8g3.md`，同步 active spec/contract/derivation；
  仍未改 RTL。
- `status`: v8g3_amendment_pending_rereview
- `fourth_review`: `scoped green`；tracker exact-tag、互斥分类、terminal 单向 DAG、
  next-cycle completion、post-launch `!done`、irrevocable AMO/STORE poison 与 edge-old B release
  未再发现合同级反例。
- `status`: contract_scoped_green_rtl_authorized

## scoped-green 后的无工具反例复核

- 实际派发继续使用同一已校验 JSON 授权上限，但运行边界进一步收紧为
  `no tools / no shell / no file access / no network`；reviewer 只消费主 agent 给出的冻结摘要，
  未执行命令、未读写文件、未访问外部服务。
- reviewer 提出三类后实现风险：post-launch early done/release、连续 WB contention、tracker
  kind/epoch mutation。主 agent 没有把文字答复当作验证，而是分别落成
  `V8G-AMO-POST-LAUNCH`/SQ pre-B、`V8G-MEM-CONTINUOUS-WB-COMPETITION` 和
  `V8G-MEM-TRACKER-QUARANTINE` 定向测试及对应 compile-success mutation。
- full lint 随后独立暴露 response-ready SCC；四个“动态等价、结构非法”变异把 active/station
  drop ready 回读、local-complete request-ready 回读和 packed-vector 假环固化为静态 RED。
- 结论：子 agent 只提供反例候选；主 agent 必须把候选转换为可执行门禁或显式剩余风险。
