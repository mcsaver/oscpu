RV64 RTL 结论｜对象=.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/run-v10e-current-design-systemd-strict.sh::simulator-define-binding / .github/runtime-artifacts/rv64-systemd-strict/rootfs-c1b531-systemd-strict-6b-a2/sim-build/obj_dir/VNpcSimTop__verFiles.dat / .github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v6｜周期/配置=pre-launch, a2 fail audit, a3 validate-only, max_cycles=6000000000, OOO_CSR_QUEUE_HEAD=1, OOO_ASSERT=1, OOO_TERMINAL_HOLDER_ASSERT=1｜TB/EDA 观测=a2 build PASS 后未进入 guest cycle；bash syntax rc=0；status-helper rc=0；43/43 static + 9/9 dynamic；a3 validate-only rc=0；production rg rc=0/1/2；rtl_binding=sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594｜范围=PASS

# V10E runner pre-launch independent review V6

## 结论

本节点的启动前合同裁决为 `PASS`。未启动 6B-cycle Verilator
systemd-strict 长回放，也未修改 production RTL、testbench、runner、两份
launcher 或共享 status helper。`gate-summary.json` 的 `all_gates`
全部为 true。

## a2 simulator-define-binding 根因

- a2 固定状态为 `FAIL rc=1 stage=simulator-define-binding evidence_complete=0 cleanup_rc=2`。rootfs build/static check、完整
  `NpcSimTop` build 与 generated manifest 均存在；`driver.log`、`guest/`、
  `systemd-transaction-evidence.json`、`binding.txt`、`simulator-defines.txt`
  和 writable `rootfs.ext4` 均缺失。cleanup 查询又对 `driver.log`/`guest`
  给出 3 个 `EVIDENCE-QUERY-FAIL rc=2`。因此 a2 在 simulator define
  文本绑定处退出，未调用 guest checker、未开始任何 RTL guest cycle。
- a2 simulator 实体 SHA-256 `0332824953b7960f7195c197bd64042b2a67c69585a139e71673a35756bb4a0e` 与
  `post-binding.txt::simulator_sha256_post` 一致；`rtl_design_id_post` 为
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`。manifest/kernel/DTB pre-hash 仍为
  `UNAVAILABLE`，符合在 `evidence-binding-pre` 之前退出。
- a2 runner SHA-256 `71c4d23a96421008a2e8bbe2c6218837685ee1d1b806b3887486afb412d7a27a` 与 V5 input snapshot 一致，而当前
  修正版为 `88a9261a95ebd77dc49a2aa71c68b6da912deead26db69b078632f57f85f4b21`。dispatch 记录旧版错误要求
  `+define+OOO_TERMINAL_HOLDER_ASSERT=1`；a2 原 runner 没有独立 byte-for-byte 副本，
  其历史谓词来源绑定为 runner SHA + V5 snapshot + dispatch record。这是
  历史源码可追溯性限制，不把当前修正版倒推成 a2 源码。

## Makefile / a2 manifest / corrected runner 三方 token

- `npc/rv64/Makefile:93` 唯一发出
  `+define+OOO_TERMINAL_HOLDER_ASSERT`；当前 SHA-256 `fb4110acb7cf3c4ff1964b8b93e3e516ffdea4a4cf1f97b6f8f96c1dc0f81118` 与 a2 pre/post Makefile
  SHA 完全相同。`OooIntBackend.v` 有 3 处
  `` `ifdef OOO_TERMINAL_HOLDER_ASSERT``，只消费宏是否存在，不消费替换文本。
- a2 实际 `.github/runtime-artifacts/rv64-systemd-strict/rootfs-c1b531-systemd-strict-6b-a2/sim-build/obj_dir/VNpcSimTop__verFiles.dat` 的唯一 Verilator command line 同时含
  `--assert`、`+define+OOO_CSR_QUEUE_HEAD=1`、`+define+OOO_ASSERT` 与一个
  无值 `+define+OOO_TERMINAL_HOLDER_ASSERT`；含值 `+define+OOO_TERMINAL_HOLDER_ASSERT=1` 计数为
  `0`。
- 当前 runner `443` 行 oracle 精确为
  `+define+OOO_TERMINAL_HOLDER_ASSERT `；错误 `=1` oracle 出现 0 次。
  `require-terminal-holder-define-value` compile-success 静态回退变异被
  selftest 拒绝。由此 a2 失败根因裁决为：make 变量值 `1` 仅控制宏发出，
  旧 runner 却把它误当作 Verilator macro replacement text。

## runner / launcher / terminal 合同

- `bash -n` 检查 runner、V10E launcher、历史 V9S launcher 和 status helper，
  返回 `rc=0`；status helper 定向 suite 返回
  `rc=0`。
- selftest 返回 `rc=0`，保存 `43/43`
  个原始 `[NEGATIVE]` marker 与 `9/9` 个原始
  `[DYNAMIC]` marker。九类 fixture 覆盖 PASS-write fallback、共享锁 rc=3、
  cleanup rc=7、TERM rc=143、post-binding rc=1、assertion `0/1/2`、
  mode-0644 Bash rc=0、三方 define token grep rc=0 与 rootfs reuse rc=4。
- a3 的 result/status/runtime 三个目标在 validate-only 前后均为空；
  `V10E_RECERT_LAUNCH_VALIDATE_ONLY=1` 返回 `rc=0` 并记录
  `[V10E-RECERT-LAUNCH] validation PASS label=rootfs-c1b531-systemd-strict-6b-a3`。没有创建 a3
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
  prelaunch log 的 20 类 post-hash token 均存在；本轮
  `26` 个声明输入 SHA-256
  无漂移。
- V10E/V9S launcher 均绑定
  `.github/runtime-artifacts/rv64-engineering-single-flight.lock` 与 background
  contention rc=73；本节点末次 nonblocking reacquire `rc=0`，
  随即释放，锁文件 pre/post SHA-256 均为 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

## 反例、unknowns、假设与替代解释

- 反例：错误 `+define+OOO_TERMINAL_HOLDER_ASSERT=1` 回退、删除 compiled define proof、
  过度转义 regex、允许重复 terminal marker、私有化 V10E/V9S lock、删除
  launcher failure publisher 与忽略 PASS-write failure 均被静态变异检出；
  cleanup/TERM/post-binding/assertion read error、mode-0644 Bash、三方 token
  与 rootfs reuse 均有动态 fixture。
- unknowns：本节点未观察 17/17 guest transaction、natural poweroff、
  reset-syscon、`GOOD TRAP` 或 simulator clean exit，也未运行综合/STA。
  a2 旧 runner 内容没有单独保存，只由其 SHA、V5 snapshot 与 dispatch
  根因记录绑定；这不影响当前 43/43、9/9 与实际 a2 manifest 的三方绑定，
  但限制对历史源码字节的直接复现。
- 显式假设：`architecture_hard_gates.rtl_binding()` 的规范源集合仍是
  `npc/rv64/vsrc` 下 `.v/.sv/.vh/.svh/.mk`；a2 immutable result 未被后续
  修改（本轮对全部绑定输入 pre/post SHA 做了无漂移检查）；`rg` 对缺失路径
  返回 2。
- 替代解释：若拒绝 dispatch 对 a2 旧 oracle 的 provenance，则只能把
  “旧 runner 具体哪一行含 `=1`”降为历史源码 inconclusive；但 a2 的失败
  stage、成功 build、实际无值 manifest、未进入 guest、当前同 SHA Makefile
  以及错误回退变异被拒绝，仍排除 RTL build failure 和 guest runtime failure。
- scope_extension_request：无。真实 6B system 回放属于主节点后续动作，本节点
  明确禁止启动。
- confidence_and_basis：对当前 pre-launch 合同为高，依据是 a2
  status/artifact/absence matrix、Makefile/manifest/runner 三方 token、43/43 与
  9/9 marker、a3 validate-only、0/1/2 exact regex、pre/post design-id、输入
  SHA-256 与锁释放；对完整 Linux system 行为不作外推。

## 实现者 / 审查者复核

- 实现者证据：仅在 `.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/review-v6` 生成脚本、原始日志、返回码、JSON、
  SHA-256 清单与本报告；production 文件未写入。
- 审查者质疑：优先检查 a2 是否可能进入 guest、历史 runner 是否缺少内容
  快照、Makefile/a2 manifest/current oracle 是否真的同 token、`=1` 回退是否
  被杀死、a3 validate-only 是否留下目标、marker 是否精确集合、live design-id
  与 immutable inputs 是否漂移、全工作区锁是否可重取。除已明确保留的历史
  源码字节追溯性限制与长回放范围边界外，当前启动前 gate
  均由本地证据闭合。

本报告及哈希落盘后，本节点停止工程命令；
single-flight ownership=RETURNED。
