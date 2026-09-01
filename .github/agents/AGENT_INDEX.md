# Agent Index

本索引用于快速了解 agent 体系；具体 `.agent.md` 文件是 live 原文件，也可通过索引按需读取：

```bash
python3 scripts/github_index_db.py load --source auto --path .github/agents/<name>.agent.md
```

| Agent | 责任 |
| --- | --- |
| `agent-system` | 显式 AI 环境维护、DB/release/branch-health 与高风险 review routing。 |
| `cpu-architect` | 仅处理真实 RV64 微架构重设计、因果实验和 correctness+CPI/PPA 取舍。 |
| `ysyx-coordinator` | 跨模块协调、任务拆分和证据闭环。 |
| `npc` | NPC RTL、Verilator 仿真、DiffTest target、single/soc 后端。 |
| `nemu` | NEMU、ISA reference、设备模型和 Ubuntu/Linux reference 验证。 |
| `rv64-linux` | RV64 Linux/OpenSBI/rootfs bring-up。 |
| `hardware-flow` | 硬件设计、验证、综合与跨模块结果编排。 |
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

新增 agent 时同步本索引；只有执行覆盖或 profile 接口确实改变时才同步对应 profile/module，不做机械全栈
更新。CPU Architect 由任务语义选择，分类器只是可选辅助，不能作为许可门。进入 RV64 全局架构任务时按需
读取 `npc/rv64/ARCHITECTURE.md` 或 registry 的有界 capability/path query；局部 RTL 修复不因此升级为
Architecture/Pareto research。
