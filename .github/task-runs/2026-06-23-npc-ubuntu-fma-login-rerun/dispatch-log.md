# Dispatch Log

## 基本信息

- `task_id`: `2026-06-23-npc-ubuntu-fma-login-rerun`
- `task_slug`: `npc-ubuntu-fma-login-rerun`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-06-23 23:46] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户目标 `/goal 推进npc中完整ubuntu2204启动`
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、rv64-linux/npc/Linux docs、旧 task-run
- `action`: 读取项目规则与最近 NPC full-login 状态。
- `outputs`: 当前 strongest blocker 定位为 `plymouth` 在 `fmadd.d` 上 SIGILL，下一步应验证 FMA 并复跑同一 full-login marker。
- `evidence`: `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/task-report.md`
- `handoff_to`: none
- `next_step`: `npc-rv64-fma-frontier`
- `notes`: NEMU full Ubuntu 进展只作参考，不作为 NPC 结论。

### [2026-06-23 23:48] `npc-rv64-fma-frontier` - `completed`

- `owner_agent`: `codex`
- `trigger`: 旧 full-login first hard fault 是 `fmadd.d`
- `depends_on`: `recall`
- `inputs`: 当前未提交 FMA 译码/执行实现、`Linux/tools/fp-fma-smoke.S`
- `action`: 跑 `make -C npc/rv64 -j8` 和 `make -C Linux/tools smoke-fp-addsub smoke-fp-mul smoke-fp-fma smoke-fp-minmax smoke-fp-div smoke-fp-sqrt`。
- `outputs`: `npc/rv64` 构建入口显示当前二进制最新；FMA 与相邻 FP smoke 均 GOOD TRAP。
- `evidence`: 终端输出含 `smoke-fp-fma` code=0 cycles=266 commits=80；addsub/mul/minmax/div/sqrt 均 `HIT GOOD TRAP`。
- `handoff_to`: none
- `next_step`: `npc-full-login-rerun`
- `notes`: 该证据只关闭 focused FMA smoke，不关闭完整 Ubuntu。

### [2026-06-24 01:35] `npc-rootfs-loginctl-path` - `completed`

- `owner_agent`: `codex`
- `trigger`: full-login rerun 首轮静态 rootfs check 发现 `systemd:/usr/bin/loginctl` 缺失
- `depends_on`: `npc-rv64-fma-frontier`
- `inputs`: rebuilt full-login rootfs、`systemd.list`、rootfs readiness scripts
- `action`: 确认 Ubuntu 22.04 riscv64 `systemd.list` 和 rootfs 实际提供 `/bin/loginctl`，修正 full flavor required path 与 dpkg ownership 断言；同步同源 guest helper 硬编码为 `/bin/loginctl`。
- `outputs`: direct full rootfs readiness PASS，日志含 `dpkg info ownership: systemd /bin/loginctl`、`Ubuntu full command loginctl: /bin/loginctl`、`rootfs readiness check passed`。
- `evidence`: 终端 direct check 输出；`evidence/npc-systemd-login-full-generators-enabled-fma-rerun/run.log`
- `handoff_to`: none
- `next_step`: `npc-full-login-rerun`
- `notes`: 这是 shared Ubuntu rootfs 路径假设修复，不作为 NEMU 进展宣称。

### [2026-06-24 01:35] `npc-full-login-rerun` - `completed-with-blocker`

- `owner_agent`: `codex`
- `trigger`: FMA focused smoke PASS 后复跑同一 NPC full-login marker
- `depends_on`: `npc-rootfs-loginctl-path`
- `inputs`: full-login generators-enabled rootfs、2.5B cycles、`__NPC_LOGIN_CHECK_DONE__ rc=0` marker
- `action`: 运行 `.github/task-runs/2026-06-23-npc-ubuntu-fma-login-rerun/run-login-fma-rerun.sh`。
- `outputs`: 进入 OpenSBI/Linux/systemd 249 / Ubuntu 22.04.5；serial getty 启动并出现两次 `root (automatic login)`；`Rule-based Manager for Device Events and Files` started；负向扫描无 `SIGILL|Illegal instruction|fmadd|plymouth`，旧 `plymouth fmadd.d` frontier 未复现；最终 `Coldplug All udev Devices` job 处于 no-limit 等待，2.5B-cycle budget abort，done marker 未到。
- `evidence`: `console.log` 行 234/278 自动登录，行 298 udevd started，行 301-306 coldplug no-limit，行 308 abort；`run.rc=2`；`riscv64-linux-gnu-addr2line` 将最终 PC `0xffffffff803fb214` 解到 `unix_dgram_sendmsg`。
- `handoff_to`: none
- `next_step`: 增加 udev coldplug diagnostics 后复跑同一 full-login marker。
- `notes`: `*** longjmp causes uninitialized stack frame ***` 在 650M insts 附近出现一次，但 `Create Static Device Nodes in /dev` 随后完成；当前 first hard frontier 记录为 udev coldplug/no-limit，而不是 FMA 或 sysusers。

