# Modular Agent E2E

本目录把原本分散在 `AGENTS.md`、`.github/agents/*.agent.md`、`.github/instructions/*.instructions.md`、`.github/memory/**` 中的“语言规则”，转换成可执行、可记录、可扩展的 e2e 流水线配置。

## 分层

| 层级 | 内容 | 产物 |
| --- | --- | --- |
| L0 发现层 | 规则入口、profile、模块契约、工具链 | discovery 证据 |
| L1 模块层 | 每个 agent/module 的最小 contract gate | module profile 报告 |
| L2 跨模块层 | AM/NEMU、NPC target、SoC/DiffTest 等闭环 | cross-module profile 报告 |
| L3 系统层 | RV64 Linux/Ubuntu、display、tapeout readiness | system profile 报告 |
| L4 记录/优化层 | task-run、memory、known-issues、模板升级 | 可追溯闭环 |

## 文件职责

- `profiles/*.tsv`：profile 编排。每行一个节点，格式为 `node_id|module|function|owner_agent|inputs|outputs`。
- `modules/*.md`：每个 agent/module 的 e2e 合约，说明上下游、gate、证据和升级路线。
- `scripts/agent-e2e.sh`：profile 调度入口，只负责展开 profile、调用模块函数和生成 task-run。
- `scripts/e2e/lib/*.sh`：公共工具与报告层。
- `scripts/e2e/modules/*.sh`：模块执行库，承载具体 gate。

## 执行入口

```bash
scripts/agent-e2e.sh --list-profiles
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-e2e.sh --profile discovery
scripts/agent-e2e.sh --profile contracts
scripts/agent-e2e.sh --profile abstract-machine
scripts/agent-e2e.sh --profile nemu
scripts/agent-e2e.sh --profile nemu-ubuntu
AGENT_E2E_NEMU_UBUNTU_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-gate
scripts/agent-e2e.sh --profile npc
```

`--validate-profile` / `--validate-all-profiles` 只展开 profile 并检查 TSV 字段、模块函数绑定，不执行 NEMU/NPC/回归命令，适合在新增模块或重构 runner 后快速做全量覆盖检查。

`contracts` profile 会实际执行所有低成本模块 contract gate，用于检查 agent/module 的规则入口、上游/下游合约和关键文件是否存在，但不替代 smoke、DiffTest 或 Linux/Ubuntu gate。

`nemu-ubuntu` profile 是 NEMU Ubuntu 切片开发的快速生产守门：检查 Linux/NEMU rootfs 脚本语法、DTS 生成器、NEMU performance config，以及近期 `virtio-rng`、`goldfish-rtc`、`virtio-blk topology`、`CONFIG_WCE/cache_type`、`virtio event idx`、`DISCARD/WRITE_ZEROES`、`pread/pwrite` 后端、串口 TX 宿主缓冲、vaddr PMEM direct fast path、Sv39 host-page TLB、iTLB/dTLB 分离、保守 interpreter basic-block/TB 边界批执行、RVC wide ifetch、解释器预译码 cache 和 TB 边界中断 fast flag 等切片是否仍然挂入 guest-check 或设备 hook。`nemu-ubuntu-gate` 在此基础上提供可选真实 guest gate；默认 SKIP，只有设置 `AGENT_E2E_NEMU_UBUNTU_GATE=1` 才会运行耗时较长的 `check-nemu-systemd-guest`。

## 解读原则

- PASS 只证明该节点的 success criteria；不能越级证明未执行节点。
- SKIP 表示当前配置/依赖不满足该 gate，不能作为已验证证据。
- FAIL 后必须按 `regression-debug-loop` 扩图，而不是重复同一个命令。
- profile 是可升级配置；当一个 contract gate 变得稳定，应升级为 smoke/regression gate。
