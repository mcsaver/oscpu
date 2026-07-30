RV64 RTL 结论｜对象=.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/run-v10e-current-design-systemd-strict.sh::runner-preflight / Linux/scripts/check-npc-systemd-guest.sh / .github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v5｜周期/配置=pre-launch, a1 fail audit, a2 validate-only, max_cycles=6000000000, OOO_CSR_QUEUE_HEAD=1, OOO_ASSERT=1, OOO_TERMINAL_HOLDER_ASSERT=1｜TB/EDA 观测=a1 未进入 build/sim；bash syntax rc=0；status-helper rc=0；42/42 static + 8/8 dynamic；a2 validate-only rc=0；production rg rc=0/1/2；rtl_binding=sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594｜范围=PASS

# V10E runner pre-launch independent review V5

## 结论

本节点的启动前合同裁决为 `PASS`。未启动 6B-cycle Verilator
systemd-strict 长回放，也未修改 production RTL、testbench、runner、两份
launcher 或共享 status helper。`gate-summary.json` 的 `all_gates`
全部为 true。

## a1 runner-preflight 根因

- a1 固定状态为 `FAIL rc=1 stage=runner-preflight evidence_complete=0 cleanup_rc=2`；`evidence-query-errors.log` 对尚未生成的
  `driver.log`/`guest` 返回读取错误，`post-binding.txt` 的
  `rtl_design_id_post=PREHASH_UNAVAILABLE`、`npc_makefile_pre_sha256=UNAVAILABLE`
  和 `guest_checker_pre_sha256=UNAVAILABLE` 与 9/9
  build/sim 路径缺失共同证明它未进入构建或 guest cycle。
- a1 runner SHA-256 `63e2d9f1cb1a3a2d74efadb02e1daae5d6168c291b6d21d443b11f26614da8f9` 与 V4 pre-snapshot 相同，而当前修正版
  runner SHA-256 为 `71c4d23a96421008a2e8bbe2c6218837685ee1d1b806b3887486afb412d7a27a`。`dispatch-log.md:205-207` 记录旧版在
  `runner-preflight` 错误要求 `test -x "${guest_checker}"`；a1 原 runner
  源码没有单独快照，因而该旧谓词的来源绑定为 V4 SHA + dispatch record，
  不把当前修正版倒推成旧源码。
- `git diff --raw 4b825dc642cb6eb9a060e54bf8d69288fbee4904` 给出
  `:000000 100644 000000000 c8b92b48b A	Linux/scripts/check-npc-systemd-guest.sh`，且相对 `HEAD` 的 raw diff 为空；当前文件 mode
  为 `0644`、SHA-256 为 `1b3cc4695f2f4c40627a5e792ae67d7ab06a434636e5ecf287000aa645d56cda`，可读、非空且不可执行。
  当前 runner `344` /
  `345` 行使用 `test -r`/`test -s`，
  `543` 行通过 `bash "${guest_checker}"`
  调用。因此修正后的前置条件与实际 Bash 输入合同一致。

## runner / launcher / terminal 合同

- `bash -n` 检查 runner、V10E launcher、历史 V9S launcher 和 status helper，
  返回 `rc=0`；status helper 定向 suite 返回
  `rc=0`。
- selftest 返回 `rc=0`，保存 `42/42`
  个原始 `[NEGATIVE]` marker 与 `8/8` 个原始
  `[DYNAMIC]` marker；`require-guest-checker-executable` 回退变异被拒绝，
  mode-0644 Bash fixture 返回 0。
- a2 的 result/status/runtime 三个目标在 validate-only 前后均为空；
  `V10E_RECERT_LAUNCH_VALIDATE_ONLY=1` 返回 `rc=0` 并记录
  `[V10E-RECERT-LAUNCH] validation PASS label=rootfs-c1b531-systemd-strict-6b-a2`。没有创建 a2
  status、结果目录或 runtime build。
- 五类 terminal oracle
  `strict_done/poweroff_begin/syscon_terminal/system_reset_exit/good_trap`
  的 `-eq 1` guard 在 production runner 中各出现一次。production assertion
  regex 的独立 match/no-match/read-error 为
  `rc=0/1/2`。

## RTL binding、post-hash 与全工作区锁

- `architecture_hard_gates.rtl_binding()` 对 `146` 个
  `.v/.sv/.vh/.svh/.mk` 源文件重算 pre/post 均为
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`，与目标 design-id 一致。
- runner 对 rootfs template/cpio、RTL design-id、simulator、NPC
  config/Makefile/manifest、kernel/OpenSBI/DTB、runner/status helper、Linux
  Makefile、guest/strict checker、transaction parser、rootfs helper 与 durable
  prelaunch log 的 post-hash token 均存在；本轮 `22` 个输入
  SHA-256 无漂移。
- V10E/V9S launcher 均绑定
  `.github/runtime-artifacts/rv64-engineering-single-flight.lock` 与 background
  contention rc=73；本节点末次 nonblocking reacquire `rc=0`，
  随即释放，锁文件 pre/post SHA-256 均为 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

## 反例、unknowns、假设与替代解释

- 反例：`test -x` 回退、过度转义 regex、允许重复 terminal marker、私有化
  V10E/V9S lock、删除 launcher failure publisher 与忽略 PASS-write failure
  均被静态变异检出；cleanup rc=7、TERM rc=143、post-binding rc=1、
  assertion read-error rc=2、mode-0644 Bash 输入与 rootfs reuse rc=4 均有动态
  fixture。
- unknowns：本节点未观察 17/17 guest transaction、natural poweroff、
  reset-syscon、`GOOD TRAP` 或 simulator clean exit，也未运行综合/STA。a1
  的旧 runner 内容没有单独保存，只由其 SHA、V4 snapshot 与 dispatch 根因记录
  绑定；这不影响当前 42/42 变异与 mode-0644 动态反例，但属于历史源码可追溯性
  限制。
- 显式假设：Git empty-tree raw diff + HEAD 空 diff 足以绑定 tracked/current
  mode；`rg` 对不存在路径返回 2；`rtl_binding()` 的规范源集合仍是
  `npc/rv64/vsrc` 下 `.v/.sv/.vh/.svh/.mk`。
- 替代解释：a1 的 cleanup rc=2 是早期 terminal evidence 路径不存在的次生
  结果，不是 runner-preflight command rc=1 的起因；若否认 dispatch 中的旧
  `test -x` 记录，则只能把历史根因降为 inconclusive，但当前 `test -r`/`test -s`
  与 Bash 调用合同仍由独立静态/动态证据闭合。
- scope_extension_request：无。真实 6B system 回放属于主节点后续动作，本节点
  明确禁止启动。
- confidence_and_basis：对当前 pre-launch 合同为高，依据是原始 a1 rc/缺失
  artifact、Git/文件 mode、42/42 与 8/8 marker、a2 validate-only、0/1/2
  exact regex、pre/post design-id、输入 SHA-256 与锁释放；对完整 Linux system
  行为不作外推。

## 实现者 / 审查者复核

- 实现者证据：仅在 `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v5` 生成脚本、原始日志、返回码、JSON、SHA-256
  清单与本报告；production 文件未写入。
- 审查者质疑：优先检查 a1 是否可能进入 build/sim、旧 runner 是否缺少内容
  快照、tracked/current mode 是否真正为 100644、`test -x` 回退是否被杀死、
  a2 validate-only 是否留下目标、静态/dynamic marker 是否精确集合、live
  design-id 与 immutable inputs 是否漂移、全工作区锁是否可重取。除已明确保留
  的旧源码追溯性限制与长回放范围边界外，当前启动前 gate
  均由本地证据闭合。

本报告及哈希落盘后，本节点停止工程命令；
single-flight ownership=RETURNED。
