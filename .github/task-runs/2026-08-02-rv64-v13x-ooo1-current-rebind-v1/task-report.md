# V13X current-design OOO-1 rebind

## 分类与结论

- 本轮唯一分类：`architecture`；workflow class 为 `development`。
- current complete RTL design-id：
  `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
  （146 个 RTL 文件）。
- 结论：`PASS_WITH_DECLARED_GAPS`。仅 `OOO-1 true_ooo_long_latency` 在当前设计下
  GREEN；scoped aggregate 保持 `overall_status=RED`、`exit_code=1`。
- 本轮没有修改 `npc/rv64/vsrc/**`，不授权全架构、CPI 或 PPA promotion。

## 可证伪假设与根因

- H1：current RTL 仍满足 load miss、迭代 MUL/DIV 的 owner residency、年轻指令并行完成与
  ROB 队头有序退休，历史 RED 仅来自旧 design/evidence binding。
- H2：packed IQ、memory owner 或 MUL/DIV owner 路径引入串行化、ProducerId 截断或提前退休。
- H3：RTL 行为正确，但历史 V8N runner 的固定输出、Git root 推导或证据 inventory 不能形成
  caller-owned current-design 记录。

release/OOO_ASSERT 首次基线均通过，7 个现有 RTL 反例锚点在 current source 中仍唯一，因此 H2
在本轮定向范围内被否定，H1/H3 得到支持。根因是历史 runner 只能写固定 evidence 路径，且 gate
只绑定固定 provenance，没有 task-run proof role、EDA binary/config 或每个负向编译镜像的身份。

## 实现

- `.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/run-focused.sh`
  新增 task-run scoped 模式、严格路径同根约束、无需 Git 的仓库根推导、Icarus 配置/二进制哈希、
  source/mutant/image SHA、caller-owned manifest/log 与自动临时镜像清理；canonical 默认入口保持兼容。
- `true_ooo_long_latency_evidence.py` 新增 `task-run-v1` 输入绑定、精确 source manifest、20 个固定
  proof role、负向 activation/目标 `[CHECK-FAIL]`/唯一 `[RESULT] FAIL` 核对、proof digest 与
  scoped manifest 边界。
- `architecture_hard_gates.py` 为 OOO-1 接入 task-run source/proof inventory，并继续要求 exact
  command、current full-RTL design-id、日志唯一 PASS marker 与 15 项 OOO-1 metric。
- `test_architecture_hard_gates.py` 增加 proof 内容漂移/缺 role 反例，以及
  `test_ooo1_negative_fatal_is_expected_but_pass_or_drift_is_rejected`：SystemVerilog `$fatal` 可作为
  已命中目标 checker 的负向结束，但 `[RESULT] PASS` 或 live source hash 漂移必须拒绝。

开发期间首轮 builder 将负向 TB 的预期 `$fatal` 误判为不洁净结果并 fail-closed。规则修正后没有
放宽成功条件：仍必须有 activation、目标 `[CHECK-FAIL]`、唯一 `[RESULT] FAIL` 且禁止 PASS；随后
完整 suite 重跑。新增单测后又执行最终完整重跑，避免把旧 manifest/hash 追认为最终证据。

## 最终 RTL/TB/EDA 观测

- release 与 `OOO_ASSERT` 两个 profile：各有唯一 `[RESULT] PASS`。
- load miss、MUL、DIV：各 `8` 个 younger completion、`8` 个 owner-live younger completion、
  `4` 个 dual-issue cycle；`rob_peak=9`、`rob_valid_peak=9`、
  `retire_order_violations=0`。
- 7/7 compile-success RTL 反例被动态检出：`serial_issue1`、`miq_issue1_freeze`、
  `muldiv_issue1_freeze`、`retire_before_head_done`、`load_owner_pid_truncate`、
  `muldiv_owner_pid_truncate`、`muldiv_resp_pid_truncate`。
- checker/manifest 单测：37/37 PASS。
- scoped hard gate：OOO-1 的 contract、design binding、command、log、source/proof inventory、
  proof file/hash/log binding、proof digest 与 15 项 metric 全部 GREEN；其它未随附动态记录的 gate
  保持 RED。
- Icarus：`iverilog=a6071e4b…b6d8a3`，`vvp=a10bd7d4…8f4023`；release/assert/mutation IVFLAGS
  由 `static/simulator-config.txt` 精确绑定。

## 证据身份

- scoped manifest：`ed757ec21d717f74be9b857deba2d37edc8c91f9308d153766d92d2f113c5689`。
- OOO-1 gate log：`6a7635c930f7e7dab097451c146939fd85ee05276463e401ff007281a3c87434`。
- scoped architecture result：`fb9e3f7c2ab3e86d645f0bc889adc0e42c13bf71f97dbb182978c6643dcd789d`。
- proof aggregate：`03d53b56a4c3b628dc5a217b13fe1c0fd40204c2d593b6cebe2ca42074f788a9`。
- `sources.pre.sha256` 与 `sources.post.sha256` 字节相同，文件 SHA-256 均为
  `edc8be166252e8eda4631639fdebfa00b267178d4c141591198752e411212694`。
- canonical `npc/rv64/eval/ppa/evidence/architecture-current.json` 未被目标化，SHA-256 仍为
  `a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1`。

## 审查与边界

- v1 合同因 Windows→WSL 传参丢失 `$fatal` 字面量，只保留 candidate 记录。
- v2 冻结材料复核批准 scoped OOO-1，但其后新增 oracle 单测并重跑，导致 manifest/proof hash
  变化；v2 结果因此保留为 stale candidate，不作为最终 reviewer 结论。
- v3 合同 SHA-256
  `fc9a7696d3f8237aea8cd5527ea6ee05e29a1e222fb8fde2885346586d51f35f`；独立冻结材料 reviewer
  返回 `APPROVED_FOR_CURRENT_SCOPE`，未发现 scoped OOO-1 假绿 blocker。
- reviewer 保留的覆盖洞：ROB wrap/tag reuse 后迟到 response、flush/exception/kill/replay、多个
  长延迟 owner 同时在途、完成端口冲突/backpressure，以及明确的退休 forward-progress/liveness。
  这些不能由本轮 aggregate counts 推导。
- full-system、DI-1/2/5、OOO-2/3/4 aggregate、CPI、综合、STA、area、power 均为 GAP/NOT_RUN。

## 产物策略与下一步

- 初次预检日志在最终完整 suite 覆盖后删除；runner 已删除所有 `.vvp`、mutant RTL 和
  `/tmp/v8n-true-ooo.*`，task-run 只保留 JSON、日志、哈希、合同与审查记录。
- `agent-flow finish` 为 PASS；只运行 `rtl-task-contract` 固定门，耗时 1.107 s，记录的流程开销
  约 0.06%（40% 仅为非阻断复盘目标）。raw evidence 已索引 40 个资产，不把完整日志复制进 DB。
- 下一最小 architecture 切片：在同一 current design-id 下重绑 `DI-5 dual_memory_issue`；不得把
  V13X 的 OOO-1 scoped PASS 或 V13S/T/U/V 的其它 scoped PASS 提前合并成 canonical 全架构 GREEN。
