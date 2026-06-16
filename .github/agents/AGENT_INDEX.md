# Agent Index

本索引用于快速了解 agent 体系；具体 `.agent.md` 文件是 live 原文件，也可通过索引按需读取：

```bash
python3 scripts/github_index_db.py load --source auto --path .github/agents/<name>.agent.md
```

| Agent | 责任 |
| --- | --- |
| `agent-system` | AI 环境维护、DB-first、branch-health、review routing、delivery gate。 |
| `ysyx-coordinator` | 跨模块协调、任务拆分和证据闭环。 |
| `npc` | NPC RTL、Verilator 仿真、DiffTest target、single/soc 后端。 |
| `nemu` | NEMU、ISA reference、设备模型、Ubuntu/Linux reference gate。 |
| `rv64-linux` | RV64 Linux/OpenSBI/rootfs bring-up。 |
| `hardware-flow` | 硬件设计、验证、综合和流程化硬件 gate。 |
| `software-flow` | 软件/系统模型任务的硬件感知调试闭环。 |
| `abstract-machine` | AM 平台、运行时和测试承载层。 |
| `am-kernels` | AM 测试程序、benchmark 和 smoke。 |
| `difftest` | NPC/NEMU 差分验证和 trace 收敛。 |
| `ysyx-soc` | ysyxSoC、Chisel SoC 和 SoC 地址图。 |
| `linux-device` | Linux 设备、rootfs、驱动可见行为。 |
| `digital-logic` | 数字逻辑实验。 |
| `display-vga` | VGA/display 相关验证。 |
| `fceux-am` | NES/FCEUX on AM。 |
| `nvboard` | NVBoard 虚拟开发板。 |
| `verilator-tapeout` | Verilator/tapeout realism 相关检查。 |
| `yosys-sta` | Yosys 综合、STA、功耗分析。 |

新增 agent 时，同步本文件、对应 `.github/e2e/profiles/*.tsv` 和必要的 module 文档。
