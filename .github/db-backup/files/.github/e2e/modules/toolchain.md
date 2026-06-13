# toolchain E2E Contract

- **范围**: agent/e2e 非交互 shell、仓库软环境入口、基础 host 工具链与本机可选工具链 PATH。
- **上游**: `scripts/agent-env.sh`、WSL/Ubuntu host 环境、用户本机 toolchain 安装。
- **下游**: `discovery`、`agent-system`、`contracts`、NEMU/NPC/Linux profile。
- **L0 gate**: `e2e_toolchain_check` 检查 bash/git/make/python/gcc/timeout 等硬需求，打印 optional tools，并验证 `scripts/agent-env.sh` 已被 source。
- **软环境 gate**: `YSYX_HOME`、`AM_HOME`、`NEMU_HOME`、`NPC_HOME`、`NVBOARD_HOME` 必须指向当前工作区；若本机存在 `~/.local/bin`、`$RISCV_TOOLCHAIN_HOME/bin` 或 `~/oss-cad-suite/bin`，对应 `mill`、`riscv64-unknown-elf-gcc`、`yosys` 必须真实从这些目录解析；若 `JAVA_HOME` 可发现，则 `java` 必须从 `$JAVA_HOME/bin` 解析。`scripts/agent-env.sh` 还必须能识别并修复只继承 `YSYX_AGENT_ENV_SOURCED=1`、但工作区变量缺失的半初始化环境。
- **证据**: `tool-env-check` 日志中的 `PASS YSYX_AGENT_ENV_SOURCED`、环境变量等值检查、可选本机工具链 PATH 解析结果。
- **升级路线**: 后续可把 FPGA/EDA 重型环境通过显式 `YSYX_AGENT_ENV_ENABLE_XILINX=1` profile 接入，避免普通 NEMU/Ubuntu e2e 被 Vivado/Vitis 初始化拖慢。
