# Task Report

## 基本信息

- `task_id`: `2026-05-23-npc-platform-switch`
- `task_slug`: `npc-platform-switch`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-23`
- `updated_at`: `2026-05-23`

## 任务目标

- `source_request`: 用户要求学习 AM 的模式，做一个平台无关的 NPC 仿真顶层，由该顶层直接和 AM 等模块交互，并在顶层内部用类似 Kconfig 的方式管理后端切换为 `single` 或 `soc`。
- `goal`: 新增 `npc/sim` 作为稳定仿真入口；外部模块只调用 `npc/sim`，`single/soc` 作为内部 backend；顶层后端选择可通过 `menuconfig`/`single_defconfig`/`soc_defconfig` 直接切换；`npc/` 根 Makefile 只做兼容代理。
- `scope`: `npc/sim/**`、`npc/Makefile`、`npc/README.md`、`abstract-machine/scripts/platform/npc.mk`、`.gitignore`、memory。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 本任务是构建入口与跨模块路由调整，涉及 NPC 与 AM 两侧，不修改 RTL。
- `dynamic_nodes_added`: `sim-top`、`kconfig-selector`、`backend-descriptors`、`am-route`、`soc-am-build-fix`、`verify`、`record`

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| `sim-top` | completed | `npc/single`、`npc/soc` 现有 Makefile | 新增 `npc/sim/Makefile`、`npc/sim/README.md` | `make -C npc/sim status/help` PASS |
| `kconfig-selector` | completed | NEMU Kconfig 工具与 NPC single 配置模式 | 新增 `npc/sim/Kconfig`、`configs/{default,single,soc}_defconfig`、`scripts/config.mk` | `default_defconfig/help-config/switch BACKEND=soc/switch BACKEND=single` PASS |
| `backend-descriptors` | completed | `single/soc` 两套目录 | 新增 `npc/sim/backends/{single,soc}.mk` | `BACKEND=soc/am/ysyx-soc status` PASS |
| `am-route` | completed | `abstract-machine/scripts/platform/npc.mk` | AM run 改为调用 `npc/sim`，仅在显式变量存在时传 `BACKEND=...` | AM 默认与 `NPC_SIM_BACKEND=soc` 均 PASS |
| `soc-am-build-fix` | completed | `npc/soc/Makefile` | 普通 `NpcSimTop` 构建排除 `soc-main.cpp`，该文件仅服务 `soc` 目标 | `NPC_SIM_BACKEND=soc ALL=add run` PASS |
| `verify` | completed | 顶层路由与两个平台 | single/soc lint、SoC lint/build、AM run 验证 | 见 evidence summary |
| `record` | completed | 改动与验证结果 | task-run 与 memory 更新 | 本文件与 memory 条目 |

## 关键产物

- `npc/sim/Makefile`: 平台无关仿真顶层，支持 Kconfig `.config` 持久选择、`BACKEND=single/soc` 临时覆盖、别名 `am/ysyx-soc`、`switch/status/help`，并代理常用构建目标。
- `npc/sim/Kconfig`、`npc/sim/configs/{default,single,soc}_defconfig`、`npc/sim/scripts/config.mk`: 顶层后端选择的 Kconfig 化入口，`switch BACKEND=soc` 持久化为 `soc_defconfig`。
- `npc/sim/backends/{single,soc}.mk`: 后端描述文件，将稳定入口和具体目录解耦。
- `npc/Makefile`: 保留兼容入口，所有目标转发到 `npc/sim`。
- `abstract-machine/scripts/platform/npc.mk`: `run` 改为调用 `make -C npc/sim run`，默认不覆盖 `npc/sim` 的持久选择；显式 `NPC_SIM_BACKEND` 或旧 `NPC_PLATFORM` 才转成 `BACKEND=...`。

## 当前阻塞点

- `blockers`: 无
- `risk_assessment`: `npc/soc` 仍是复制目录，后续公共逻辑修复需要明确是否同步到 `single` 与 `soc` 两侧；`npc/sim` 只统一外部入口和后端选择，不消除双份维护成本。

## 收尾结论

- `final_result`: 已建立 `npc/sim` 平台无关仿真顶层并改为 Kconfig 风格管理。AM 默认直接调用 `npc/sim`，后端默认跟随 `npc/sim/.config`；可用 `make -C npc/sim menuconfig`、`single_defconfig`、`soc_defconfig` 或 `switch BACKEND=soc` 持久切换，也可用 `NPC_SIM_BACKEND=soc`/`BACKEND=soc` 临时切到 SoC 复制版；`npc/` 根 Makefile 保留为兼容代理。
- `evidence_summary`: `make -C npc/sim default_defconfig` PASS；`make -C npc/sim status` PASS；`make -C npc/sim help-config` PASS；`make -C npc/sim switch BACKEND=soc` PASS；`make -C npc/sim switch BACKEND=single` PASS；`make -C npc/sim BACKEND=soc status` PASS；`make -C npc status` PASS；`make -C npc backend-help-config` PASS；`make -C npc -n backend-perf_defconfig` PASS；`make -C npc/sim lint` PASS；`make -C npc/sim BACKEND=soc lint` PASS；`make -C npc/sim soc-lint` PASS；`make -C npc/sim soc` PASS；AM `cpu-tests add` 默认后端与 `NPC_SIM_BACKEND=soc` 均 PASS；`git diff --check` PASS。
