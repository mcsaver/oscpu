# 调度记录

- 读取工程规则、NPC/NEMU/DiffTest/AM-Kernels 记忆与相关 instructions。
- 定位 NPC 当前提交口、PMEM/MMIO 路径、AM `riscv32-npc` 运行入口和 Spike difftest reference 接口。
- 按 RTL 四阶段推导补提交后 PC 观测口。
- 实现 host 侧 difftest loader、提交级 GPR/PC 对比、MMIO skip-ref、CLI 和 Makefile 入口。
- 构建 Spike REF、NPC lint/build。
- 运行 `cpu-tests` difftest smoke 和全量 35 项回归。
- 运行 Dhrystone、CoreMark、MicroBench benchmark difftest 回归；CoreMark 首次 240s timeout 后改用 900s 完成默认 1000 iterations；MicroBench 构建缺 `riscv64-linux-gnu-g++` 后改用可用的 `riscv64-unknown-elf-` 工具链。
- 更新 `.github/memory/project-status.md`、`.github/memory/modules/{npc,difftest,am-kernels}.md`。
