# NEMU E2E Contract

本合同只在显式选择 NEMU/NEMU Ubuntu profile 或维护其 runner/checker 时生效。普通 NEMU 源码修改应先用
直接相关的 build、smoke 或单测闭环；profile 不因路径命中自动成为开工或收尾许可。

## Canonical sources

- Profile 组成：[`../profiles/nemu.tsv`](../profiles/nemu.tsv)、
  [`../profiles/nemu-dev.tsv`](../profiles/nemu-dev.tsv) 及同目录的 `nemu-dev-*` / `nemu-ubuntu-*` TSV。
- E2E 节点实现：[`scripts/e2e/modules/nemu.sh`](../../../scripts/e2e/modules/nemu.sh)。
- Ubuntu rootfs 与 guest 的真实 oracle：
  [`Linux/scripts/check-ubuntu-rootfs.sh`](../../../Linux/scripts/check-ubuntu-rootfs.sh) 和
  [`Linux/scripts/check-nemu-systemd-guest.sh`](../../../Linux/scripts/check-nemu-systemd-guest.sh)。
- 顶层运行和持久化语义见 [`../README.md`](../README.md)。精确 marker、包清单、设备字段与版本变化只在
  上述实现中维护；本文不建立第二份细粒度清单。

## 验证层级

| 层级 | Canonical profile | 支持的 claim | 不支持的升级结论 |
| --- | --- | --- | --- |
| Reference | `nemu` | 当前 NEMU target/ISA 配置可分类；匹配的 host-native RISC-V reference 可运行最小 cpu-test | Linux boot、NPC/RTL、完整 ISA |
| Static/slice | `nemu-dev` / `nemu-ubuntu-focused` | Ubuntu/NEMU 脚本、配置、rootfs/DTB/machine-info 合同及声明的 ISA、设备、QMP/GDB focused smoke | 真实 guest boot、PID1/userland |
| Focused guest | `nemu-dev-gate` / `nemu-ubuntu-gate` | 真实 NEMU 上的 OpenSBI/DTB → kernel → PID1、声明的设备事务、guest check 与自然 poweroff 闭环 | full rootfs、桌面、NPC 等价 |
| Full Ubuntu | `nemu-dev-full-gate` / `nemu-ubuntu-full-gate` | full rootfs 静态 ownership，加上当前 profile 声明的 systemd、账号/PAM、包管理、存储、网络、时间、SSH、维护与资源控制 runtime | 外部网络、桌面/图形栈、多 hart、长期稳定性或完整服务器策略 |
| Full soak | `nemu-dev-full-soak` / `nemu-ubuntu-full-soak` | full gate 加上配置时长和负载下的 uptime、I/O/进程/串口及中断稳定性检查 | 无限期稳定性、性能签核 |
| Performance | `nemu-ubuntu-profile` | tests-off 条件下的 full Ubuntu boot/profile summary 与预算 | 功能 full gate 或 PPA 结论 |
| Integrated | `nemu-ubuntu-integrated` | RV64 Linux profile 与 NEMU static/slice 的显式组合 | NEMU full guest、NPC DiffTest 或端到端 RTL |

这些层级不可互相替代：静态 hook/marker 存在不证明 guest 执行；kernel 启动不证明 PID1 healthy；PID1
运行不证明 full userland；full gate 的一次完成不证明 soak 或长期性能。NEMU-only PASS 也不能证明 NPC、
RTL 或 ysyxSoC；NPC-only profile 同理不能借用 NEMU Ubuntu 结果。

## Fail-closed correctness

1. **Reference 配置**：只有 `CONFIG_TARGET_NATIVE_ELF=y` 且 ISA 明确匹配 `riscv32`/`riscv64` 才能作为
   host-native reference。AM/SHARE target、非 RISC-V native、缺 ISA 或缺配置必须拒绝；AM 镜像不是
   cpu-tests reference 的替代执行目标。
2. **Profile 闭包**：NEMU dev profile 只能展开 NEMU 允许的 node/module/owner/function/source；任何 NPC
   或 RV64 Linux 节点只能通过显式 integrated profile 组合。隔离失败在 workload 前终止。
3. **Opt-in 长门**：focused/full/soak gate 分别要求对应 `AGENT_E2E_NEMU_UBUNTU_*_GATE=1`。未启用返回
   SKIP；SKIP 是 required closure 不完整，不是降级 PASS。
4. **超时与进程终态**：focused gate 默认总超时为 1700 秒，full 与 soak 默认 7200 秒，均可由对应
   profile 环境变量显式调整。外层 timeout、NEMU 提前退出、等待串口/FIFO/guest marker/poweroff 超时、
   signal 或非零 make/NEMU 退出都必须失败；不能因已经出现若干 PASS 行而忽略终态。guest checker 的
   EXIT cleanup 负责回收仍存活的 NEMU 进程，但 cleanup 不把中断改写为成功。
5. **完整完成链**：runtime PASS 至少要求 guest check 的完整 rc=0、无 guest fail marker、GOOD TRAP、
   预期的 systemd/poweroff 终态，以及 host checker 声明的设备 runtime ledger 与 rootfs backing 未被破坏。
   full/soak 还必须满足该 profile 当前实现列出的全部额外 oracle；不得从单个服务或单个 marker 推断整层
   完成。
6. **负向扫描**：console 必须拒绝 kernel panic、Oops/Call Trace、BAD TRAP、文件系统或 I/O error，以及
   checker 维护的启动/配置回归模式。已知良性文本只能在其上下文分类器同时证明预期启动或完整关机链时
   豁免；不能用宽泛 grep ignore 掩盖运行期错误。

默认网络是 NEMU hostless backend，只证明内置 DHCP/DNS/NTP/HTTP 等被该 gate 明示的语义；TAP 与外部
连通性必须显式配置并满足 host preflight/packet criteria。hostless PASS 不代表 TAP/NAT、外部 DHCP、
Ubuntu mirror、IPv6、多网卡或桌面网络。

## 运行与报告

普通 NEMU E2E 使用 compact/direct，并直接报告所选层级的最终结果、最接近根因的失败日志和未覆盖范围。
不要逐项复述 marker、hash、package evidence 或历史版本流水账；只有出现真实异常时才围绕失败 criterion
追加定向诊断。durable `--publish` 仅用于明确的 release/migration/security/forensic/publication 需求，
不会扩大 NEMU profile 的工程 claim，也不会替代 timeout、终态、负向扫描、DiffTest 或系统级 oracle。
