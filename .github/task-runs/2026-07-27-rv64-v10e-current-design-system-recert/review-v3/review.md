RV64 RTL 结论｜对象=.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/run-v10e-current-design-systemd-strict.sh::capture_terminal_evidence / review-v3｜周期/配置=pre-launch, max_cycles=6000000000, OOO_CSR_QUEUE_HEAD=1, OOO_ASSERT=1, OOO_TERMINAL_HOLDER_ASSERT=1｜TB/EDA 观测=bash syntax rc=0；status-helper rc=0；40/40 static + 7/7 dynamic selftest；exact assertion rg rc=2｜范围=GAP

# V10E runner pre-launch independent review V3

## 结论

禁止启动 6B-cycle systemd-strict 回放。生产 runner 在
`.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/run-v10e-current-design-systemd-strict.sh:151` 把双反斜杠 assertion
pattern 作为 argv 传给 `rg`；V3 exact-argv fixture 返回
rc=2，原始 marker 为
`[V10E-V3][ASSERTION-REGEX-RC] 2`。
`record_optional_rg` 正确把 rc>1 视为错误，因此
`capture_terminal_evidence` 会返回非零；strict-marker-check 的显式调用或
EXIT cleanup 均不能得到 PASS。这是 fail-closed，但会让当前 runner 无法完成
pre-launch PASS。

现有 `test-runner-contract.py` 仍 rc=0，并记录
40/40 个 `[NEGATIVE]` 与
7/7 个 `[DYNAMIC]` marker；假绿根因是其定向读错
fixture 在 `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/test-runner-contract.py:754` 运行简化的
`rg "RTL assertion" <missing-log>`，没有编译生产 pattern。静态检查仅要求
`record_optional_rg()` 与 `EVIDENCE-QUERY-FAIL` token 存在，也没有验证
exact regex argv。

## V2 六项反例裁决

1. PASS 写失败：既有 helper suite rc=0，`PASS-write fallback`
   marker PASS；在该定向注入模型内闭合。
2. cleanup signal：7 类动态 fixture 中 TERM rc=143 且状态 FAIL，闭合。
3. post-binding 输出失败：动态 rc=1 且状态 FAIL，闭合。
4. assertion 日志读取错误：未闭合。exact production regex 自身编译
   rc=2；selftest 的简化 missing-log probe 不能证明生产查询正确。
5. runtime control/post-hash：40 个静态负向变体中的声明项均被拒绝；
   本轮未启动长回放，不越级证明运行期无漂移。
6. 全工作区锁：动态 V9S contention rc=3，且两份 launcher 的背景
   rc=73/status publisher 静态 token 被接受；合同内 fixture 闭合，但未启动
   真实后台系统回放。

重复 terminal marker 的五个 `-eq 1` oracle 在生产 runner 中存在；40 个静态
负向 marker 包含 `allow-duplicate-strict-done` 与
`allow-duplicate-good-trap` 被拒绝。由于 assertion query blocker 已先失败，
本轮不授权任何 terminal PASS。

## design-id 与范围

runner 内配置的 `expected_design_sha=c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594` 与合同目标相同。
V3 合同未授权读取 `npc/rv64/vsrc/**`，因此未独立执行
`architecture_hard_gates.rtl_binding()`；实际当前 RTL design-id 只能记为
scope GAP，不能用配置常量替代 RTL 源集合哈希。

scope_extension_request：若后续需要独立关闭 design-id gate，新版本合同需增加
只读 `npc/rv64/vsrc/**`，再以已声明 `python3` 调用
`architecture_hard_gates.rtl_binding()`；本 V3 未扩权、未执行。

## unknowns / assumptions / alternatives

- unknowns：未运行 Verilator、testbench、综合或 STA；未观察 17/17 guest
  transaction、natural poweroff、reset-syscon 或 `GOOD TRAP`。
- assumption：`shlex` 对 runner 单引号参数的还原等价于 Bash；control pattern
  将双反斜杠方括号降为单反斜杠后，在同一输入上 rc=0，
  支持根因定位为 shell regex 过度转义。
- alternative：若期望匹配 literal `[`/`]`，生产 argv 应只携带单反斜杠转义；
  最终修复必须由生产 runner 的 exact-pattern fixture 验证，不能只复用简化
  `rg` probe。
- confidence_and_basis：高；语法/状态/selftest 原始日志、exact argv、rg parser
  原始 stderr 与 SHA-256 均保存在本目录。

## 实现者 / 审查者复核

- 实现者证据：未修改生产 RTL、TB、runner、launcher 或共享 helper；
  `bash-syntax.log`、`task-run-status.log`、`runner-contract.log` 记录 rc=0
  与原始 PASS marker。
- 审查者反例：`assertion-regex-fixture.log` 复现 production argv rc=2，
  否决 selftest overall PASS 对实际 `capture_terminal_evidence` 可执行性的
  越级结论。
- 分歧裁决：pre-launch 只能为 GAP；6B-cycle runner 不得启动。

本报告写入完成后本节点不再运行 WSL 工程命令；
single-flight ownership=RETURNED。
