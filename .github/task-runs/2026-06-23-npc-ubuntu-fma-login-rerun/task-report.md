# Task Report

## 基本信息

- `task_id`: `2026-06-23-npc-ubuntu-fma-login-rerun`
- `task_slug`: `npc-ubuntu-fma-login-rerun`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed-with-blocker`
- `owner`: `codex`
- `started_at`: `2026-06-23 23:46:17 +08:00`
- `updated_at`: `2026-06-24 01:35:01 +08:00`

## 任务目标

- `source_request`: `/goal 推进npc中完整ubuntu2204启动`
- `goal`: 推进 NPC/Verilator 上完整 Ubuntu 22.04 rootfs/login gate。
- `scope`: 复用上一轮 full-login generators-enabled 失败点，先验证 RV64 FMA focused smoke，再用同一 full-login rootfs、preseed/sysusers 条件、`__NPC_LOGIN_CHECK_DONE__ rc=0` marker 和 2.5B-cycle 预算复跑。

## 选图说明

- `selected_template`: `rv64-ubuntu-rootfs-loop`
- `why_this_graph`: 当前 strongest NPC gate 已到 full package generators-enabled autocheck PASS，full-login 最新硬前沿是 `plymouth` 在 `fmadd.d` 上 SIGILL；因此应沿 rootfs/login 路线继续，而不是切回 NEMU 或低层 shell probe。
- `dynamic_nodes_added`: `npc-rv64-fma-frontier`
- `why_dynamic_nodes_were_needed`: 静态 rootfs loop 没有单独表达 ISA/FMA 前沿；新增节点用于把 FMA focused smoke 与 full-login rerun 分层，避免越级宣称完整 Ubuntu 已启动。

## RTL 推导摘要

- `需求`: NPC RV64 FP 路径需要识别 `FMADD/FMSUB/FNMSUB/FNMADD.{S,D}`，读取 `frs1/frs2/frs3`，写回 `frd`，让 Ubuntu full-login 中的 `plymouth` 不再因 `fmadd.d` 触发 illegal instruction。
- `协议规则`: FMA 仍走既有 pending FP 序列化控制路径；译码命中后由 `pending_fp_q` 持有指令，等待 backend drained 后在 FP compute 路径生成结果，并在 pending FP commit 点写回 FPR 或提交 GPR 结果。它不新增 AXI、cache、CSR 或异常握手。
- `状态机`: 沿用现有 `pending_fp_q -> pending_fp_compute_done_q -> pending_fp commit` 小状态，不新增长期状态；FMA 属于 compute 类，不进入 div/sqrt long-op 或 FP load/store memory sub-state。
- `不变量`: FMA 不能被 OP-FP 的 `funct7` long-op 误分类；FMA 结果只写 FPR，不设置 `pending_fp_gpr_write_q`；`rs3` 只来自指令 `[31:27]`；单精度结果保持既有 NaN-boxing/符号扩展约定；本轮不声称完整 IEEE fused rounding/fflags 覆盖。
- `数据通路骨架`: `OooFpDecode` 通过四个 FMA opcode 和 `fmt` 产生 `fp_fma_o/fp_double_o`；`OooAluFetchCore` 从 FPR 读 `frs1/frs2/frs3`，组合调用既有 `fp_mul_value` 与 `fp_addsub_value`，按 opcode 选择 product/addend 符号，结果接入 `pending_fp_compute_value_w`。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | AGENTS/Copilot/memory/rv64-linux/npc docs | 当前前沿确认为 NPC FMA -> full-login rerun | 对话工具输出；旧报告 `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/task-report.md` |
| npc-rv64-fma-frontier | codex | completed | 当前未提交 FMA 实现、`Linux/tools/fp-fma-smoke.S` | FMA 与相邻 FP smoke PASS | `make -C Linux/tools smoke-fp-addsub smoke-fp-mul smoke-fp-fma smoke-fp-minmax smoke-fp-div smoke-fp-sqrt` |
| npc-rootfs-loginctl-path | codex | completed | rebuilt full-login rootfs、Ubuntu Jammy `systemd.list` | `loginctl` source-of-truth 修正为 `/bin/loginctl`，静态 full rootfs readiness PASS | direct rootfs check；console/rootfs check 中 `systemd /bin/loginctl` 与 `rootfs readiness check passed` |
| npc-full-login-rerun | codex | completed-with-blocker | full-login generators-enabled rootfs、2.5B cycles | 旧 `plymouth fmadd.d` SIGILL 未复现；自动登录出现两次；最终卡在 `Coldplug All udev Devices`，2.5B cycle 上限触发，marker 未到 | `evidence/npc-systemd-login-full-generators-enabled-fma-rerun/run.log`、`console.log`、`login-full-generators-enabled-fma-rerun.rc` |
| record | codex | completed | 验证结果 | memory/task-run 更新 | 本报告、dispatch log、memory 更新 |

## 关键产物

- `artifacts`: `run-login-fma-rerun.sh`
- `logs_or_traces`: `evidence/npc-systemd-login-full-generators-enabled-fma-rerun/run.log`、`evidence/npc-systemd-login-full-generators-enabled-fma-rerun/console.log`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: `Coldplug All udev Devices` 未在 2.5B-cycle budget 内完成，`__NPC_LOGIN_CHECK_DONE__ rc=0` marker 未出现。最终 abort 为 cycle budget 上限，`run.rc=2`。
- `missing_dependencies`: 需要继续定位 udev coldplug 的事件队列、规则、设备等待链，必要时给 full-login gate 增加 guest-side udev diagnostics 或将 coldplug 依赖拆成可观测 hard marker。
- `risk_assessment`: 本轮证明旧 `plymouth fmadd.d` SIGILL 未复现，但不等同完整 Ubuntu login gate；`*** longjmp causes uninitialized stack frame ***` 曾出现一次并未阻止 `Create Static Device Nodes` 完成，后续仍需判定它是否与登录 shell/profile 未输出 marker 有关。

## 下一步建议

1. 围绕 `systemd-udev-trigger.service` / `Coldplug All udev Devices` 增加 guest-side diagnostics：列出 pending udev events、`udevadm settle` 状态、`udevadm trigger` 状态、`systemctl status systemd-udev-trigger.service systemd-udevd.service` 和 journal tail。
2. 复跑同一 full-login marker；不要放宽 `__NPC_LOGIN_CHECK_DONE__ rc=0`，也不要把 NEMU full Ubuntu 进展混入 NPC 结论。

## 模板升级候选

- `repeated_dynamic_subgraph`: `npc-rv64-isa-frontier -> npc-full-login-rerun`
- `should_promote_to_static_template`: `false`
- `reason`: 当前只是 full-login 路线里的一个 FMA 前沿切片，是否反复出现需继续观察。

## 收尾结论

- `final_result`: partial-progress; full-login gate still failed at new udev coldplug frontier.
- `evidence_summary`: FMA focused smoke 与相邻 FP smoke PASS；direct full rootfs readiness PASS，`loginctl` 修正为 `/bin/loginctl`；full-login rerun 进入 systemd 249 / Ubuntu 22.04.5，serial getty 启动、root 自动登录出现两次，`Rule-based Manager for Device Events and Files` started，`Coldplug All udev Devices` 在 14/15/16s no-limit 状态后未完成；2.5B cycles / 1,262,975,631 commits 上限 abort，`run.rc=2`，done marker 未到。负向扫描 `SIGILL|Illegal instruction|fmadd|plymouth` 返回 `no-old-fma-sigill-markers`。
- `notes`: 不把 NEMU full Ubuntu 进展混入 NPC 结论；本轮关闭的是旧 FMA illegal-instruction 前沿和 rootfs `loginctl` 静态路径假设，不关闭完整 Ubuntu 22.04 login gate。
