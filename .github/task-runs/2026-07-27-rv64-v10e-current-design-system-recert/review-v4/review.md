RV64 RTL 结论｜对象=.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/run-v10e-current-design-systemd-strict.sh::capture_terminal_evidence / .github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v4｜周期/配置=pre-launch, max_cycles=6000000000, OOO_CSR_QUEUE_HEAD=1, OOO_ASSERT=1, OOO_TERMINAL_HOLDER_ASSERT=1｜TB/EDA 观测=bash syntax rc=0；status-helper rc=0；41/41 static + 7/7 dynamic；production rg rc=0/1/2；rtl_binding=sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594｜范围=PASS

# V10E runner pre-launch independent review V4

## 结论

本节点的启动前合同裁决为 `PASS`。未启动 6B-cycle Verilator
systemd-strict 长回放，也未修改 production RTL、testbench、runner、两份
launcher 或共享 status helper。`gate-summary.json` 的
`all_gates` 全部为 true。

## V3 blocker 与 design-id scope GAP

- V3 assertion regex blocker：生产赋值位于 `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/run-v10e-current-design-systemd-strict.sh:34`，
  V4 独立 exact-pattern fixture 得到 match/no-match/read-error
  `rc=0/1/2`；
  `overescape-assertion-regex` 静态反例被定向测试拒绝。与 V3 的双反斜杠
  `rg rc=2` 反例相比，此 blocker 已闭合。
- V3 design-id scope GAP：`architecture_hard_gates.rtl_binding()` 对
  `146` 个 `.v/.sv/.vh/.svh/.mk` 源文件重算 pre/post 均为
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`，与合同目标
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594` 一致，scope GAP 已闭合。

## runner / launcher / terminal 合同

- `bash -n` 同时检查 runner、V10E launcher、历史 V9S launcher 和
  `scripts/task-run-status.sh`，返回 `rc=0`。
- status helper 定向 suite 返回 `rc=0`；PASS-write 失败、
  early exit、command failure、cleanup failure 与 HUP/INT/TERM 均有
  fail-closed marker。
- selftest 返回 `rc=0`，保存
  `41/41` 个原始 `[NEGATIVE]` marker 和
  `7/7` 个原始 `[DYNAMIC]` marker。
- 五类 terminal oracle
  `strict_done/poweroff_begin/syscon_terminal/system_reset_exit/good_trap`
  的 `-eq 1` guard 在 production runner 中各出现一次；
  `allow-duplicate-strict-done` 与 `allow-duplicate-good-trap` 反例被拒绝。
- 两份 launcher 均绑定
  `.github/runtime-artifacts/rv64-engineering-single-flight.lock`、
  background contention `rc=73` 与 failure publisher；动态 V9S probe
  返回 `rc=3`。fixture 结束后该锁 nonblocking reacquire `rc=0`，
  未遗留本节点锁持有者。

## post-hash 与漂移

production runner 的 rootfs template/cpio、RTL design-id、simulator、NPC
config/Makefile/manifest、kernel/OpenSBI/DTB、runner/status helper、Linux
Makefile、guest/strict checker、transaction parser、rootfs helper 与 durable
prelaunch log 的 post-hash token 均存在。V4 验证前后
`16` 个声明控制输入 SHA-256
无漂移；完整清单见
`input-sha256-pre.txt`、`input-sha256-post.txt` 和 `rtl-binding.txt`。

## 反例、unknowns、假设与替代解释

- 反例：过度转义 production regex、两类允许重复 terminal marker、私有化
  V10E/V9S lock、删除 launcher failure publisher、忽略 PASS-write failure
  均被静态变异检出；cleanup rc=7、TERM rc=143、post-binding rc=1、
  assertion read-error rc=2 与 rootfs reuse rc=4 均不能产生 PASS。
- unknowns：本节点没有观察 17/17 guest transaction、natural poweroff、
  reset-syscon、`GOOD TRAP`、实际 simulator clean exit，也没有运行综合或 STA；
  因而 `PASS` 只覆盖 pre-launch runner 合同，不是 system recert PASS。
- 显式假设：当前 `rg` 对不存在路径稳定返回 2；`rtl_binding()` 的规范源集合
  仍是 `npc/rv64/vsrc` 下 `.v/.sv/.vh/.svh/.mk`。工具文件本身已纳入
  immutable input pre/post hash。
- 替代解释：静态 token/变异测试可以证明声明的 fail-closed 结构，却不能排除
  6B 长回放中才出现的 runtime artifact mutation、guest progress 或 terminal
  lifecycle 缺陷；这些只能由后续真实 systemd-strict 运行裁决。
- scope_extension_request：无。合同 V4 已授权关闭 design-id gate；真实 6B
  system 回放属于主节点后续动作，且本节点明确禁止启动。
- confidence_and_basis：对 pre-launch 合同为高；依据是原始 rc、41/41 与
  7/7 marker、0/1/2 exact regex、pre/post design-id、输入 SHA-256 与锁释放
  观测。对完整 Linux system 行为不作置信外推。

## 实现者 / 审查者复核

- 实现者证据：只在 `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v4` 生成验证脚本、原始日志、返回码、JSON、
  SHA-256 清单与本报告；production 文件未写入。
- 审查者质疑：优先复跑 V3 exact-regex 反例、核对静态 marker 集合而非只看
  overall PASS、重算 live RTL design-id、比较 immutable inputs pre/post，
  并复取全工作区锁排除遗留 owner。上述质疑
  均由本地证据闭合；
  长回放未运行是明确范围边界，不作假绿推断。

本报告及哈希落盘后，本节点停止工程命令；
single-flight ownership=RETURNED。
