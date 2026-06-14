# abstract-machine E2E Contract

- **范围**: AM 平台抽象、链接脚本、`riscv32-nemu`/`riscv32-npc`/`riscv64-npc` 架构脚本。
- **上游**: NEMU/NPC 配置、工具链。
- **下游**: am-kernels 镜像、NEMU reference、NPC target。
- **L0 gate**: `abstract-machine-contract` 检查 Makefile、AM headers、架构脚本和 memory。
- **L1 gate**: 通过 am-kernels profile 构建/运行最小镜像。
- **证据**: 架构脚本存在、镜像路径、构建日志。
- **升级路线**: 增加 `hello` image-only smoke，不依赖当前 NEMU 配置。
