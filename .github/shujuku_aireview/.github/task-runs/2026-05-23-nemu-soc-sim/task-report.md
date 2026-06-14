# Task Report

## 基本信息

- `task_id`: `2026-05-23-nemu-soc-sim`
- `task_slug`: `nemu-soc-sim`
- `graph_template`: `rv32-reference-loop`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-23`
- `updated_at`: `2026-05-23`

## 任务目标

- `source_request`: 用户要求在 NEMU Kconfig 中新增 SoC 仿真选项，并按 NPC 中已接入的 SoC 模块内容补齐 NEMU reference，使 NPC SoC 后端可以跑 difftest。
- `goal`: NEMU 在 `CONFIG_SOC_SIM=y` 时能在 paddr 层模拟当前 NPC/ysyxSoC 地址图的最小功能窗口，并作为 NPC SoC difftest reference 通过 cpu-tests。
- `scope`: `nemu/src/isa/riscv32/Kconfig`、`nemu/src/memory/*`、`nemu/src/cpu/difftest/ref.c`、`nemu/src/utils/disasm.c`、NEMU defconfig、memory/task-run 记录。

## 选图说明

- `selected_template`: `rv32-reference-loop`
- `why_this_graph`: 本任务核心是把 NEMU 作为 NPC SoC 后端的 RV32 reference 模型，并用 AM cpu-tests 闭环验证。
- `dynamic_nodes_added`: `study-context`、`soc-map`、`nemu-soc-model`、`reference-sync`、`capstone-crash-fix`、`verify`、`record`
- `why_dynamic_nodes_were_needed`: 任务横跨 NPC SoC 地址图、NEMU paddr、difftest shared object 与运行目录环境，需要在标准 reference 回归外补充宿主崩溃定位。

## 节点概览

| node_id | status | inputs | outputs | evidence |
| --- | --- | --- | --- | --- |
| `study-context` | completed | AGENTS、memory、NPC study notes | 明确需要先按 SoC 地址图补 reference，且 reference so 不能依赖完整 device init | 已读取项目规范与相关模块记忆 |
| `soc-map` | completed | `npc/single`/`npc/soc` 地址宏和 ysyxSoC 外设范围 | 采用 CLINT、SRAM、UART、SPI/GPIO/PS2、MROM、VGA、Flash、SDRAM 最小功能模型 | 地址范围记录在 memory |
| `nemu-soc-model` | completed | NEMU paddr/PMEM/CLINT 路径 | 新增 `CONFIG_SOC_SIM`、`memory/soc.{h,c}`、`riscv32-soc_defconfig`，并在 paddr read/write 接入 | `make -C nemu -j4` PASS |
| `reference-sync` | completed | NPC difftest loader 调用 `difftest_memcpy()` | NEMU reference 支持把镜像/数据同步到 SoC 片上窗口；MROM 允许运行前加载，运行期仍只读 | `make -C npc/sim BACKEND=soc difftest-ref` PASS |
| `capstone-crash-fix` | completed | NPC SoC difftest 段错误回溯 | `disasm.c` 优先用 `NEMU_HOME` 定位 Capstone，失败时输出 `.word` 而非空指针调用 | 单个 `dummy` 带 difftest GOOD TRAP |
| `verify` | completed | NEMU executable 与 NPC SoC backend | NEMU self、SoC UART smoke、NPC SoC difftest 全通过 | 见 evidence summary |
| `record` | completed | 代码改动与验证结果 | project/modules memory 与本 task-run | 本文件和 memory 条目 |

## 关键产物

- `nemu/src/isa/riscv32/Kconfig`: 新增 `CONFIG_SOC_SIM`。
- `nemu/configs/riscv32-soc_defconfig`: SoC reference 推荐配置。
- `nemu/include/memory/soc.h`、`nemu/src/memory/soc.c`: ysyxSoC 最小 paddr 平台模型。
- `nemu/src/memory/paddr.c`: 在 PMEM/CLINT 后接入 SoC paddr 模型。
- `nemu/src/cpu/difftest/ref.c`: `difftest_memcpy()` 可同步 SoC 非 PMEM 窗口。
- `nemu/src/utils/disasm.c`: 修复 reference so 从非 NEMU cwd 启动时的 Capstone 路径崩溃。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 无。
- `risk_assessment`: 当前 SoC 模型是 difftest/功能对齐用的最小模型，Flash 仅 sparse read-zero/write-ignore，ChipLink 远端窗口尚未建模；如果后续 guest 真正运行完整 SoC boot flow，还需要按外设行为继续细化。

## 下一步建议

1. 后续若把 AM/NPC 迁到严格 ysyxSoC 地址表，应同步处理 NPC legacy `0xa000_0000` 兼容窗口与 NEMU SoC SDRAM/legacy MMIO 的冲突边界。
2. 若引入真实 SPI flash、GPIO/PS2 输入、VGA framebuffer 检查或 ChipLink 访问，应把这些行为逐项扩成可测试的 reference 子模型。

## 模板升级候选

- `repeated_dynamic_subgraph`: `reference shared object cwd/path crash -> gdb bt -> env/absolute path fix -> difftest rerun`
- `should_promote_to_static_template`: `maybe`
- `reason`: NPC/NEMU reference 后续还可能多次遇到 shared object 在不同 cwd 下运行导致的路径问题。

## 收尾结论

- `final_result`: NEMU 已新增 SoC reference 模式并能支撑 NPC SoC 后端 difftest。
- `evidence_summary`: `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C npc/sim BACKEND=soc difftest-ref` PASS；NEMU SoC UART smoke 对 `0x1000_0000` 写字符 `S` 并 GOOD TRAP；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run NEMUFLAGS=-b` 38/38 PASS；`AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu timeout 900s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_SIM_BACKEND=soc NPC_RUN_ARGS="--diff=default --no-progress -m 0"` 38/38 PASS；`git diff --check` PASS。
- `notes`: 构建过程中仍出现 `warning: adding embedded git repository: ysyxSoC`，这是既有工作树状态，本任务未改动该嵌套仓库问题。
