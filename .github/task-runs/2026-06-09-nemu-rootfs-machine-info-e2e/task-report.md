# Task Report

## 基本信息

- `task_id`: 2026-06-09-nemu-rootfs-machine-info-e2e
- `task_slug`: nemu-rootfs-machine-info-e2e
- `graph_template`: modular-agent-e2e
- `profile`: nemu-ubuntu
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-09 01:55:16 +0800
- `updated_at`: 2026-06-09 01:55:17 +0800

## 任务目标

- `source_request`: 修复 NEMU Ubuntu rootfs 进入完整规模启动前的低成本预检缺口。
- `goal`: 让 `nemu-ubuntu` profile 不只检查 virtio-blk MMIO 地址图，还能检查真实 rootfs ext4 镜像是否被 NEMU block 后端打开为可写 virtio-blk 设备。
- `scope`: profile=nemu-ubuntu；本轮只覆盖开机前 rootfs-attached machine-info 契约，不越级声明真实 guest/systemd/完整 VM 已完成。

## 选图说明

- `selected_template`: modular-agent-e2e
- `why_this_graph`: 本 profile 从 `.github/e2e/profiles/` 读取节点，把 agent/instructions/memory 中的模块职责转换为可执行 gate。
- `dynamic_nodes_added`: 无
- `why_dynamic_nodes_were_needed`: 无

## 节点概览

| node_id | owner_agent | module | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------ | ------- | -------- |
| `recall-discovery` | `agent-system` | `agent-system` | `PASS` | AGENTS/copilot/instructions/memory/e2e profiles | 规则发现链和 e2e 配置入口存在 | .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/recall-discovery.log |
| `tool-env-check` | `agent-system` | `toolchain` | `PASS` | bash/git/make/python/gcc/verilator/toolchain | hard requirements 与 optional tools 可见 | .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/tool-env-check.log |
| `npc-sim-status` | `hardware-flow` | `hardware-flow` | `PASS` | npc/sim Kconfig 与 backend mk | 当前 npc/sim 后端状态 | .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/npc-sim-status.log |
| `npc-rv64-contract` | `npc` | `npc` | `PASS` | npc/rv64 + Linux README | RV64 core/Linux 入口合约存在 | .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/npc-rv64-contract.log |
| `rv64-linux-contract` | `rv64-linux` | `rv64-linux` | `PASS` | Linux Makefile/env/platform/instructions | RV64 Linux/Ubuntu 合约入口存在 | .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/rv64-linux-contract.log |
| `nemu-ubuntu-static` | `nemu` | `nemu` | `PASS` | Linux/NEMU Ubuntu rootfs scripts + performance config | NEMU Ubuntu 切片静态生产守门 PASS | .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/nemu-ubuntu-static.log |
| `nemu-ubuntu-slice-contract` | `nemu` | `nemu` | `PASS` | recent NEMU Ubuntu device slice hooks and guest markers | 近期 NEMU Ubuntu 设备切片合约仍挂入 guest gate | .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence/nemu-ubuntu-slice-contract.log |

## 关键产物

- `artifacts`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e
- `logs_or_traces`: .github/task-runs/2026-06-09-nemu-rootfs-machine-info-e2e/evidence
- `profile_manifest`: .github/e2e/profiles/nemu-ubuntu.tsv
- `linked_memory_updates`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

## 本轮切片补充

- `nemu-ubuntu-static` 证据中，无 `--block` 的 machine-info 明确检查 `device.virtio_blk.block_image=detached`、`mmio_device_id=0`、`capacity_bytes=0`、`capacity_sectors=0`。
- 本地 Ubuntu rootfs 镜像存在时，static gate 运行 `make -C Linux ARCH=riscv64-nemu nemu-rootfs-machine-info`，先通过 `check-ubuntu-rootfs-systemd`，再由 NEMU 打开 `Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64.ext4`。
- `evidence/nemu-ubuntu-static.log` 记录 rootfs-attached PASS：`block_image=attached`、`mmio_device_id=2`、`capacity_bytes=2147483648`、`capacity_sectors=4194304`、`readonly=0`、`writeback=1`、`queue_num_max=64`、`mmio.virtio-blk=0x10001000..0x10001fff`。
- 若 future 环境缺少 rootfs 镜像，该检查会打印 SKIP；SKIP 不能当作 rootfs attached 证据。

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 见对应 tool/env 节点日志
- `risk_assessment`: 无 hard fail；optional tool 缺失只作为后续节点风险。

## 下一步建议

1. 按模块或跨模块目标选择更深 profile，或进入具体静态图。
2. 对含 `SKIP` 的模块，先补依赖或切换到合适配置，再把该模块提升到 PASS 证据。

## 模板升级候选

- `repeated_dynamic_subgraph`: 无
- `should_promote_to_static_template`: 已作为 modular-agent-e2e profile 固化
- `reason`: profile + module library + task-run 证据包能把 agent 提示转为可执行流水线

## 收尾结论

- `final_result`: profile=nemu-ubuntu 通过，rootfs-attached machine-info 预检已进入 static production gate。
- `evidence_summary`: 详见节点表、`evidence/nemu-ubuntu-static.log` 的 rootfs-attached PASS 行与 `Linux/build/nemu-rootfs-machine-info.txt`。
- `notes`: 这是开机前契约 gate，不替代真实 guest focused gate、长期 block 压力、DiffTest、Linux/Ubuntu 分层 gate 或 QEMU 级 VM 完整性。
