# Dispatch Log

## 2026-05-23

### `sim-top`

- 读取 `npc/single/Makefile`、`npc/soc/Makefile` 和 AM 平台入口，确认当前 `single` 是默认 AM/NpcSimTop 后端，`soc` 是复制出的 ysyxSoC 接入后端。
- 按用户澄清后的要求新增 `npc/sim/Makefile`，把它作为平台无关仿真顶层，提供 `BACKEND=single/soc` 临时选择、`switch/status/help`、常用目标代理、`soc/soc-lint` 固定代理到 `npc/soc`。
- 新增 `npc/sim/backends/{single,soc}.mk` 描述后端目录和语义；`npc/Makefile` 改成兼容代理，继续允许从 `npc/` 调用常用目标。
- 新增 `npc/sim/README.md` 并更新 `npc/README.md`，明确外部模块优先调用 `npc/sim`。

### `kconfig-selector`

- 按用户“类似 Kconfig 的方式方便管理，直接切换顶层”的要求，新增 `npc/sim/Kconfig`、`configs/default_defconfig`、`configs/single_defconfig`、`configs/soc_defconfig` 和 `scripts/config.mk`。
- `npc/sim/Makefile` 改为优先读取 `include/config/auto.conf` 中的 `CONFIG_NPC_SIM_BACKEND`；选择优先级为显式 `BACKEND`、`NPC_SIM_BACKEND`、兼容变量 `PLATFORM/NPC_PLATFORM`、Kconfig `.config`、旧 `npc/.platform`、默认 `single`。
- 修正 Kconfig string 配置带双引号的问题，用 `remove_quote` 在 Makefile 里把 `CONFIG_NPC_SIM_BACKEND="single"` 转成 `single` 后再匹配后端。
- `make -C npc/sim switch BACKEND=soc` 不再写旧 `.backend`，而是执行 `soc_defconfig` 并持久化到 `npc/sim/.config`；最后切回 `single_defconfig`，保持默认路径为老 core。

### `am-route`

- 修改 `abstract-machine/scripts/platform/npc.mk`，让 `riscv32-npc run` 调用 `make -C npc run PLATFORM=$(NPC_PLATFORM)`。
- 默认 `NPC_PLATFORM=single`，保持现有 AM 行为；需要切复制版时传 `NPC_PLATFORM=soc`。
- 随后按平台无关顶层要求改为 `make -C npc/sim run`：默认不显式传后端，让 `npc/sim` 自己读取默认/持久选择；只有用户传 `NPC_SIM_BACKEND` 或旧变量 `NPC_PLATFORM` 时才转换成 `BACKEND=...`。

### `soc-am-build-fix`

- 验证 `NPC_PLATFORM=soc` 时发现 `npc/soc` 普通 `NpcSimTop` 构建误编 `csrc/soc-main.cpp`，导致缺少 `VysyxSoCFull.h`。
- 修改 `npc/soc/Makefile`，从普通 `CSRCS_ALL` 中排除 `SOC_CSRCS`，使 `soc-main.cpp` 只服务 ysyxSoCFull 目标。

### `verify`

- `make -C npc status` PASS。
- `make -C npc BACKEND=soc status` PASS。
- `make -C npc/sim status` PASS。
- `make -C npc/sim default_defconfig` PASS。
- `make -C npc/sim help-config` PASS。
- `make -C npc/sim BACKEND=soc status` PASS。
- `make -C npc/sim switch BACKEND=soc` PASS。
- `make -C npc/sim switch BACKEND=single` PASS。
- `make -C npc help` PASS。
- `make -C npc backend-help-config` PASS。
- `make -C npc -n backend-perf_defconfig` PASS，确认后端 defconfig 代理会展开为 `npc/single perf_defconfig`。
- `make -C npc -n run IMG=/tmp/fake.bin RUN_ARGS='--no-progress'` 展开到 `npc/single run`，变量透传正常。
- `make -C npc/sim lint` PASS。
- `make -C npc/sim BACKEND=soc lint` PASS。
- `make -C npc/sim soc-lint` PASS。
- `make -C npc/sim soc` PASS。
- `make -C npc lint` PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--no-progress -m 0'` PASS。
- `make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_SIM_BACKEND=soc NPC_RUN_ARGS='--no-progress -m 0'` PASS。
