# YSYX AI 驱动硬件开发环境蓝图

## 目标

- 把当前工作区从“模块专家集合”升级为“图任务调度 + 工作流 agent + 模块专家执行 + 经验沉淀”的 AI 驱动硬件开发环境。
- 围绕当前工作区真正可执行的后端建立闭环：`am-kernels + AbstractMachine + npc/sim + NPC/Verilator + NEMU reference`。
- 在硬件流程之外补齐软件开发流程层：`software-flow` 负责软件需求、脚本/工具链、NEMU/AM/am-kernels/Linux guest check 与 host side 软件的全流程闭环；NEMU 这类“用软件建硬件/系统模型”的任务必须先走软件闭环，再叠加硬件/系统 gate。
- 为 `.github` 规则、记忆、profile、task-run 文本证据和根目录/多 AI 入口 shim 提供轻量 SQLite 开发记忆系统：文件系统仍保存当前原始产物，数据库提供索引、元数据、状态、查询、目录压缩、按需 chunk 加载和经 `promote` 固化的 stored documents；后续迁移为 DB-first 时，必须通过 `migrate/materialize/restore` 保留兼容 shim、备份目录和恢复 gate。
- 保留 `NEMU + AbstractMachine + am-kernels` 作为纯参考/快速定位闭环；当任务目标涉及 target 行为时，默认把 `npc/sim`、`npc/single`/`npc/soc` 和 difftest 纳入图。
- `ysyxSoC` 作为 SoC/Chisel 集成节点接入 `npc/soc`，真实 EDA 工具仍作为后续 PPA/STA 下游节点，不替代功能验证闭环。

## Marco 思想在本工作区的映射

| Marco 思想 | YSYX 的落地方式 |
| ----------- | ---------------- |
| Graph-based task solving | 先选静态图模板，再按当前任务动态扩图 |
| Agent config per sub-task | 每个节点指定 owner agent、输入、输出、成功标准与回退策略 |
| Tool / skill config | 每个节点都绑定当前可用工具：Make、NEMU、Verilator、日志、study 笔记 |
| Memory / knowledge base | `.github/memory/`、根目录/多 AI 入口 shim、`.github/cache/github-index.sqlite` 本地索引、`npc/{single,soc}/design/study/`、`ysyxSoC/spec/`、README、Makefile、已有构建脚本 |
| Iterative self-debug | 采用“构建 → 运行 → 对比 → 定位 → 修复 → 回归”的循环，而不是一次性生成后结束 |

## 当前真实后端

- 当前默认回归后端：
  - `am-kernels`：测试与最小工作负载入口
  - `abstract-machine`：平台抽象、链接脚本、镜像封装
  - `npc/sim`：NPC 平台无关仿真入口，按 Kconfig/覆盖变量选择后端
  - `npc/single` + `Verilator`：普通 NPC 自仿真后端
  - `npc/soc` + `ysyxSoCFull`：ysyxSoC 接入后端
  - `nemu`：参考模型、NEMU SoC reference、trace / watchpoint / batch 调试入口
  - `difftest`：NPC single/soc 与 NEMU reference 的提交级 GPR/PC 对比层
- 下游节点：
  - `ysyxSoC`：Chisel SoC、CPU ABI、外设地址图与生成物
  - `yosys-sta`：综合、STA、PPA 节点
- RV64 Linux/Ubuntu 扩展后端：
  - `npc/rv64`：RV64 OoO core、Kconfig、testbench、Verilator target
  - `Linux/`：OpenSBI/Linux/Ubuntu bring-up 的 Makefile 入口、脚本、平台配置、tools 和验证套件
  - `Linux/env/`：工作区内的 OpenSBI、Linux、BusyBox、Ubuntu Base、QEMU、镜像与日志套件
  - `rv64-linux`：OpenSBI/Linux/Ubuntu 启动层级与 QEMU/NPC 证据分层
  - `linux-device`：UART、CLINT、PLIC、virtio-mmio、rootfs 和 Linux driver 设备契约
  - `display-vga`：Linux-visible framebuffer/simplefb/simpledrm/fbcon 与 SDL scanout
  - `verilator-tapeout`：Verilator 真实性能仿真、仿真-only 边界和后续可流片约束

## 图节点契约

每个任务节点至少包含以下字段：

```yaml
node_id:
goal:
owner_agent:
depends_on:
inputs:
outputs:
success_criteria:
fallback:
evidence:
```

其中：

- `inputs` 要明确依赖的源码、笔记、镜像、日志或配置
- `outputs` 要明确交付给下游节点的产物
- `success_criteria` 不能只写“完成”，要写可验证结果
- `fallback` 用来说明失败后改由哪个 agent 或哪种方案接手
- `evidence` 用来记录日志、测试、波形、记忆更新等验证证据

## 图选择规则

### 静态图优先条件

- 任务类别已反复出现，且已有模板能覆盖主要依赖链
- 节点输入、输出、成功标准在多轮任务中基本稳定
- 任务目标更像“执行一条已知流程”，而不是“探索未知边界”

### 动态图触发条件

- 现有模板无法表达当前任务的关键步骤或边界
- 某个节点连续失败，需要插入 `reproduce`、`collect-log`、`localize-boundary`、`config-bisect` 等诊断节点
- 出现新的跨模块依赖，必须先补“契约澄清”或“产物转换”节点
- 当前结果无法形成证据链，必须补充日志、trace、波形或对比摘要节点

### 模板升级条件

- 同类动态图在多轮任务中重复出现，且节点依赖、输入输出、成功标准趋于稳定
- 新流程已经不再依赖人工临时判断才能落地
- 升级后能减少重复扩图和重复解释成本

## 子任务智能体配置

- 默认每个节点只指定一个 `owner_agent`，由它对节点输出负责
- 当一个节点内部天然包含“规划 + 实施 + 审阅”或跨知识边界时，可以在节点内部使用 single-AI 或 multi-AI 配置，但对外仍暴露一个统一的 `owner_agent`
- 工作流 agent 负责图结构与节点交接，模块专家负责节点内部实现；不要把“图调度”和“模块实现”混成一个超大节点

## 动态图扩展规则

- 节点执行失败时，优先把失败节点拆成 `reproduce → collect-evidence → localize → fix → rerun`
- 若关键产物缺少证据，插入专门的 `collect-log`、`collect-trace`、`wave-summary` 或 `artifact-audit` 节点
- 若依赖的 target、reference 或 SoC 生成路径不可用，应用“截断而非伪造”原则，把图收敛到当前可执行节点，并把缺口记录成基础设施节点
- 若需要对比或诊断，必须先确保两侧产物可比较；不能在只有参考输出或只有目标输出时创建 `compare-or-difftest` 节点

## 图质量门槛

- 每个非 `record` 节点都必须留下至少一条可复核证据
- 每条边都应能解释为“执行依赖”或“知识依赖”，不能只是模糊的顺序摆放
- 同一节点不要同时承担“构建、定位、修复、记录”四种职责；职责过宽时应拆节点
- 图中出现未来节点时，要明确它是“预留接入点”还是“当前硬依赖”，不能混写

## 结构化任务产物

- 任务级产物与长期记忆分离：
  - `.github/memory/` 保存稳定结论、长期经验和设计决策
  - `.github/task-runs/` 保存单次图任务的执行摘要和派发历史
- 模板入口：
  - `.github/task-runs/templates/task-report.template.md`
  - `.github/task-runs/templates/dispatch-log.template.md`
- 建议每个重要图任务创建一个目录：`.github/task-runs/YYYY-MM-DD-<task-slug>/`
- `task-report.md` 用于汇总当前任务的目标、选图、节点状态、关键产物、阻塞点、下一步和模板升级候选
- `dispatch-log.md` 用于追加记录节点派发、状态变更、输入输出、证据与 handoff

## 静态图模板

### `rv32-reference-loop`

```text
study-recall → image-build(am-kernels / AM) → nemu-reference → record
```

适用场景：纯参考功能验证、AM/NEMU 平台调研、最小工作负载快速回归，以及为 target 路径准备稳定参考输出。

### `rv32-bringup`

```text
study-recall → image-build(am-kernels / AM) → nemu-reference → rtl-sim(npc / verilator) → compare-or-difftest → record
```

适用场景：普通 NPC target 的指令、CSR、流水线、cache、设备 bring-up、最小功能回归和 target 仿真链路验证。

### `npc-sim-regression`

```text
backend-select(npc/sim) → image-build(am-kernels / AM) → npc-run(single or soc) → optional-difftest → record
```

适用场景：通过 `npc/sim` 统一入口验证 `riscv32-npc` 镜像、默认后端、临时 `NPC_SIM_BACKEND` 覆盖和后端配置是否生效。

### `soc-difftest-loop`

```text
soc-contract(ysyxSoC + npc/soc + nemu SOC_SIM) → difftest-ref → image-build → npc-soc-run → compare → record
```

适用场景：ysyxSoC 地址图、`npc/soc`、NEMU `CONFIG_SOC_SIM` reference 和 AM `riscv32-npc` SoC 后端的协同验证。

### `ysyx-soc-integration`

```text
cpu-abi-recall → chisel-or-generated-audit → npc-soc-wrapper → build-ysyxSoCFull → soc-lint-or-smoke → record
```

适用场景：修改 ysyxSoC Chisel、CPU 顶层 ABI、SoC 生成链路或 `npc/soc` 的 ysyxSoC wrapper。

### `am-device-loop`

```text
device-contract → am-impl → nemu-device → am-test → compare → record
```

适用场景：IOE / 设备模型 / AM 平台联调。

### `software-dev-loop`

```text
scope-contract → design-plan → implement → unit-or-contract-test → integration-smoke → regression-or-e2e → review-record
```

适用场景：新增软件功能、脚本/工具链能力、NEMU/AM/am-kernels/Linux guest check、host C/C++/Python/Shell/Make/Kconfig 或可独立验证的软件重构。

### `software-bugfix-loop`

```text
reproduce → collect-log → localize-root-cause → fix → focused-test → regression → record
```

适用场景：软件 bug、脚本 gate 失败、工具链配置漂移、host/guest 软件接口异常。必须先定位 root cause，再在正确抽象层修复。

### `software-refactor-loop`

```text
inventory-callers → preserve-contract → mechanical-change → focused-test → consumer-regression → record
```

适用场景：拆分大软件文件、重命名入口、重构目录结构、抽取公共库、整理脚本层次。路径敏感 e2e hook、profile、文档和 memory 必须同轮更新。

### `hardware-aware-software-loop`

```text
scope-contract → hardware-semantic-contract → design-plan → implement → software-focused-test → system-or-hardware-gate → review-record
```

适用场景：NEMU/RV64/Linux bring-up、ISA/CSR/中断/virtio/QMP/GDB、设备模型、性能模型、guest check、rootfs/tool 脚本等“软件实现硬件或系统语义”的任务。它把 `software-flow` 和 `hardware-flow`/`nemu-ubuntu` 有机组合：软件流程保证代码、调用链、测试和记录，硬件/系统 gate 保证架构语义、guest 可见行为和生产链路消费。

### `rv64-ubuntu-probe-loop`

```text
recall → qemu-reference → npc-verilator-run → uart-visible-check → record
```

适用场景：用同一份 OpenSBI/Linux/DTB/Ubuntu probe initramfs 先跑 QEMU reference，再跑 NPC/Verilator target，验证是否达到 Ubuntu probe `/init` 和 `/etc/os-release` 可见 gate。

### `rv64-ubuntu-rootfs-loop`

```text
rootfs-artifact → virtio-device-contract → multi-source-plic → qemu-reference → npc-rootfs-run → shell-check → record
```

适用场景：从 initramfs 推进到真实 Ubuntu rootfs，要求 virtio-mmio block、多源 PLIC、Linux driver probe、`/dev/vda` 与 rootfs mount 形成证据链。

### `linux-display-loop`

```text
display-contract → dtb-framebuffer → kernel-config → npc-sdl-scanout → fbcon-smoke → record
```

适用场景：让 Linux/Ubuntu 文本输出进入 Linux-visible framebuffer/fbcon，并由 Verilator host SDL 窗口扫描显示；明确区分 AM legacy VGA 与 Linux framebuffer。

### `rv64gc-userland-loop`

```text
isa-abi-recall → fp-focused-smoke → dynamic-linker-smoke → ubuntu-userland-run → record
```

适用场景：验证官方 Ubuntu riscv64 `rv64gc/lp64d` 用户态、动态链接器、libc 与 `/bin/sh`，不得用 rv64imac/lp64 syscall-only probe 代替。

### `verilator-tapeout-readiness-loop`

```text
synth-boundary-audit → verilator-perf-run → rtl-invariant-check → focused-regression → ppa-risk-record → record
```

适用场景：在暂不使用 Vivado 的阶段，用 Verilator 做尽量真实的性能/系统仿真，同时审计 core/SoC 可综合边界和后续流片风险。

### `modular-agent-e2e`（兼容名：`agent-e2e-loop`）

```text
.github/e2e/profiles/*.tsv → recall-discovery → tool-env-check → backend-status → module-contract/smoke → record
```

适用场景：验证 AI 开发环境自身是否可被稳定发现和执行，包括 AGENTS/Copilot/instructions/memory/task-run 入口、`.github/e2e/modules/*.md` 模块合约、`.github/e2e/profiles/*.tsv` profile 编排、基础工具链、`npc/sim` 后端状态，以及按 profile 选择的 NEMU/NPC smoke 或模块 contract gate。该图用于降低后续 AI 判断前提的不确定性，不替代具体模块的功能回归、DiffTest、Linux/Ubuntu gate 或 PPA/STA signoff。

其中 `github-index` profile 属于开发环境检索、按需加载和 DB-first 迁移辅助层：它验证 `scripts/github_index_db.py` 能从 `.github/**` 与根目录/多 AI 入口 shim 构建 SQLite 索引、查询结果、目录摘要、chunk 加载结果、stored documents、备份/迁移/物化/恢复和状态巡检。索引库不替代 memory/task-run 的事实记录；把 `.md` 原件迁入数据库、再将旧文件移动到备份目录必须通过 `migrate --yes`、`load --source stored`、`materialize` 与 `restore --yes` 的可逆证据链。

### `agent-env-refactor`

```text
audit → blueprint → file-edits → validate-discovery → record
```

适用场景：重构 `.github/` 下的 agent、instructions、记忆协议与工作流环境。

### `regression-debug-loop`

```text
reproduce → collect-log-or-trace → localize-boundary → fix → rerun → record
```

适用场景：参考路径回归失败、设备联调失败、或需要先稳定证据链再修复的问题。

## Agent 分层

| 层级 | 角色 | 责任 |
| ------ | ------ | ------ |
| L0 | `ysyx-coordinator` | 选择静态图 / 动态图，切分节点，调度与记录 |
| L1 | `agent-system` | 重构 agent 架构、指令、记忆、蓝图 |
| L1 | `hardware-flow` | 管理 NEMU / AM / am-kernels / npc-sim / difftest 闭环，并为 SoC、PPA 节点接入做编排 |
| L1 | `software-flow` | 管理软件需求到验证记录的完整闭环；对 NEMU/工具/guest check 等软件硬件模型，先收敛软件流程再交接硬件/系统 gate |
| L1 | `rv64-linux` | 管理 RV64 OpenSBI/Linux/Ubuntu 证据分层和 QEMU/NPC bring-up 闭环 |
| L1 | `verilator-tapeout` | 管理 Verilator 真实性能仿真、仿真-only 边界和后续流片约束 |
| L2 | `npc`、`linux-device`、`display-vga`、`ysyx-soc`、`nemu`、`abstract-machine`、`am-kernels`、`difftest` 等 | 在各自模块内实现与调试 |
| L3 | `.github/memory/` 与 `study/` | 提供长期知识、经验和稳定入口 |

## 当前阶段门槛

### Gate 1：参考路径稳定

- AM 程序可以稳定构建镜像
- NEMU 可以稳定跑同一镜像并产生日志

### Gate 2：参考闭环结构化

- 调度结果能稳定产出结构化 task report / dispatch log
- 任务级产物能稳定落到 `.github/task-runs/` 统一目录，并与 `memory/` 分层保存
- `image-build` 与 `nemu-reference` 节点的命令、输入、输出、日志摘要可重复复用
- `scripts/agent-e2e.sh --list-profiles` 能列出模块 profile；`--validate-all-profiles` 能检查全部 profile 展开和函数绑定；`--profile discovery|agent-system|software-flow|github-index|contracts|quick` 能稳定生成 `modular-agent-e2e` 证据包，用于证明规则发现、profile/模块合约、工具自检、软件流程 agent、`.github` 检索索引与按需加载、`npc/sim status`；当 NEMU 当前是 AM-compatible 配置时，`quick` 还应包含最小 NEMU reference smoke，否则以 `SKIP` 记录配置边界

### Gate 3：目标路径打通

- NPC / Verilator 能加载或对接同类工作负载
- 能输出最小可用的仿真日志或波形
- `npc/sim` 能稳定选择 `single` / `soc` 后端，并被 AM `riscv32-npc` 入口调用

### Gate 4：对比与扩展闭环

- 能把 NEMU 结果与 NPC 结果收敛到同一套比较与诊断流程
- `difftest` 或等价比较层开始稳定工作
- SoC 后端具备 NEMU `CONFIG_SOC_SIM` reference，可验证 ysyxSoC 地址图下的基础 CPU 测试
- 在功能闭环稳定后，再把综合、STA、PPA 分析作为下游节点接入

## 分阶段路线图

1. **P0 骨架期**：落地图任务协议、`agent-system`、`hardware-flow`、`software-flow`、蓝图与记忆入口
2. **P1 参考闭环期**：稳定 `am-kernels -> AM -> NEMU` 工作流，并补结构化 task report / dispatch log
3. **P2 目标接入期**：通过 `npc/sim` 稳定 `npc/single` 与 `npc/soc` 后端、AM `riscv32-npc` 入口和 Verilator target 运行链路
4. **P3 对比与扩展期**：稳定 `difftest`、NEMU `CONFIG_SOC_SIM`、ysyxSoC 接入，并逐步引入 `yosys-sta`、PPA、时序诊断等更强的 EDA 节点
5. **P4 RV64 Ubuntu 系统闭环期**：围绕 `npc/rv64` 用 Verilator-first 路线分层推进 OpenSBI/Linux/Ubuntu 22.04，从 probe `/init`、官方 `/bin/sh`、dynamic linker/libc、rootfs/virtio、Linux-visible display 到长跑性能证据逐级闭合
6. **P5 流片水准收敛期**：在设备契约、可综合边界和系统 gate 清晰后，再把 Vivado/FPGA、综合、STA、PPA、模块 testbench 与 RTL 不变量作为下游 signoff 节点接入，而不是用它们替代功能 bring-up

## 当前落地原则

- 优先使用工作区已经具备的真实链路，而不是为了“像 EDA”而空转设计概念
- 让 agent 围绕镜像、NEMU 参考运行、NPC target 仿真、difftest 日志与结构化记录工作；SoC/Chisel 与综合/STA 作为明确的下游或并行节点接入
- NEMU、Linux tools、guest check、host C++ harness、QMP/GDB 和设备模型既是软件，又承载硬件/系统语义；开发时使用 `hardware-aware-software-loop`，不能只跑 `nemu-ubuntu` 而跳过软件需求/契约/测试/记录，也不能只跑软件测试而越级声明系统 gate 完成
- RV64 Linux/Ubuntu 任务默认走 QEMU reference + NPC/Verilator target 双证据，并按 `/init`、`/etc/os-release`、官方 `/bin/sh`、rootfs 和 Linux-visible framebuffer 分层记录
- 暂不把 Vivado/FPGA 作为 RV64 Ubuntu 功能 bring-up 前置；Verilator 平台可以有 DPI/host C++/SDL，但 core/长期 RTL 必须保留可综合边界
- 每一轮重构都要留下明确的静态图模板、节点契约与记忆更新，避免体系再次退化成散乱规则
