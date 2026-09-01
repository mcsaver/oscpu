# YSYX 工作区 — Copilot 工程补充

跨 agent operating contract 统一见 .github/AGENTS.md；本文件只保留 YSYX 的构建、模块关系和真实
correctness 事实，不复制通用任务流程。

## Project overview

本工作区包含 RV32 教学主线与独立的 npc/rv64 CPU、系统验证和 PPA 主线：

- npc/sim：NPC 平台无关仿真入口。
- npc/single：普通 NPC 自仿真后端。
- npc/soc：ysyxSoC 接入后端。
- ysyxSoC：Scala/Chisel SoC、CPU ABI、地址图与生成 Verilog。
- nemu：RISC-V reference model 和 DiffTest reference。
- abstract-machine、am-kernels：AM 平台与测试/benchmark。
- yosys-sta：Yosys 综合及 iEDA STA/功耗分析。
- nvboard、digital_logic_experiment、fceux-am：开发板、数字逻辑实验和 AM 应用。

常用链路：

~~~text
am-kernels -> abstract-machine
  +-> riscv32-nemu -> NEMU reference
  +-> riscv32-npc  -> npc/sim -> npc/single or npc/soc
                                      +-> ysyxSoC

npc target <-> DiffTest <-> NEMU reference
~~~

## Languages and style

- RTL：Verilog/SystemVerilog，主要使用 Verilator；沿用现有模块和信号命名风格。
- SoC 生成：Scala、Chisel、Mill、Firtool。
- 软件：C/C++，沿用各模块既有代码风格。
- 构建：GNU Make + Kconfig。
- 文档和新增注释使用中文。

## Build command reference

| 模块 | 常用命令 |
| --- | --- |
| NEMU | cd nemu && make menuconfig && make |
| NPC 统一入口 | cd npc/sim && make status && make run IMG=/path/to/image.bin |
| NPC single | cd npc/single && make lint && make |
| NPC SoC | cd npc/soc && make lint && make soc-lint && make soc |
| ysyxSoC Verilog | cd ysyxSoC && make verilog |
| AM on NEMU | cd am-kernels/tests/cpu-tests && make ARCH=riscv32-nemu run |
| AM on NPC | cd am-kernels/tests/cpu-tests && make ARCH=riscv32-npc run NPC_RUN_ARGS="--diff=default --no-progress -m 0" |
| 综合 | cd yosys-sta && make syn |
| STA | cd yosys-sta && make sta |
| NVBoard | 在对应实验目录运行 make run |

这些是入口速查，不保证覆盖每个配置。执行前读取目标目录 Makefile、README 和当前 Kconfig；不要把一个
后端或 ISA 的成功外推到另一个后端或 ISA。

Windows 访问本 WSL 工作区时，PowerShell 仅启动 wsl.exe，工程命令在 Ubuntu 内运行。并行只需避开同一
build 目录、配置、数据库、服务、端口或设备等真实共享可变资源，不采用 workspace-wide unique shell。
NEMU、menuconfig、SDL/NVBoard 等交互程序应保留正常 stdin/stdout；需要自动化时优先使用程序自身 batch、
日志、trace 或配置接口。

## Shared correctness facts

- NPC 与 NEMU 的 DiffTest 必须使用匹配 ISA、镜像、地址图和配置，并按真实 commit/trace 比较；环境
  profile 或命令返回零不能代替 DiffTest 结论。
- CONFIG_SOC_SIM 是 NPC SoC/ysyxSoC 地址图的 reference 模式；SoC DiffTest reference 可从
  make -C npc/sim BACKEND=soc difftest-ref 构建。
- riscv32-npc 默认由 npc/sim 进入当前配置后端，可用 NPC_SIM_BACKEND=soc 临时选择 npc/soc。
- RTL 改动需保持 ready/valid、stall、flush/redirect/trap、异常序、访存序和恢复语义；能编码的关键
  不变量优先进入断言或定向 testbench。
- 仿真 smoke、综合成功、STA 通过和 PPA 改善回答不同问题，不能互相替代。比较 PPA 时保持 RTL、
  filelist、parameter/define、约束、工具版本/选项、corner 和 workload 一致。

## RV32 and NPC routing

处理 npc/single 或 npc/soc 的数据通路、译码、控制、功能仿真、SoC wrapper 或 RTL 时，先使用当前
源码、接口 spec、直接 README 和 TB。只有设计意图、历史约束或后端差异会改变判断时，才从对应
design/study/README.md 按需进入以下材料：

- RV32I-ai-notes.md 与 RV32I-implementation-checklist.md；
- RISC-V-spec-functional-sim-scope.md 与对应 notes；
- RISC-V-spec-hardware-architecture-scope.md 与对应 notes。

纯参考、AM/NEMU 平台或 target 无关问题可以截断在 NEMU；涉及 NPC 行为的结论应回到 npc/sim target +
NEMU reference 闭环。

生成或修改 Verilog/SystemVerilog 时，读取 rtl-generation-workflow.instructions.md；跨模块握手、
stall、flush、异常、访存或投机恢复同时读取 interface-contract-first.instructions.md。四段推导
需求 → 协议/状态机/不变量 → 数据通路约束 → RTL 用于保证设计完整性，不要求建立额外 AI 审计链。

## ysyxSoC / Chisel

- CPU 顶层 ABI、AXI4 端口和地址图以 ysyxSoC/spec/cpu-interface.md 及相关 agent/module 说明为准。
- ysyxSoC/build/ysyxSoCFull.v 是生成物；通常修改 ysyxSoC/src 后运行 make -C ysyxSoC verilog。
- 当前 Mill/Chisel 链依赖用户级 JDK 21 与本地 mill wrapper；系统 OpenJDK 8 失败不能直接归因于源码。

## RV64 architecture and delegation

- npc/rv64 的 current 状态、目录 owner、每个 .v/.sv 生命周期，以及 filelist → elaboration → dynamic
  → mapped → STA/PPA 可见性，从 npc/rv64/ARCHITECTURE.md 和
  npc/rv64/eval/ppa/tools/architecture_registry.py query 的有界结果进入。
- 用 cpu-architect-routing.instructions.md 区分 ARCHITECT、WORKER、EXPLORER、REVIEWER 和 NON_ARCH。
  只有存在开放的跨流水或事务生命周期结构取舍才使用 CPU Architect；局部 RTL、已定位 bug、验证、
  工具、文档和 registry 维护不升级。
- 派发复杂、并行或跨会话的本地 RV64 RTL 子任务时，可读取 rtl-agent-task-contract.instructions.md，
  并用 .github/skills/prepare-rtl-task-contract 提供具体 RTL/spec/TB/evidence 输入、输出和命令。
  局部且 ownership 清楚的子任务可直接派发；该接口帮助准确 handoff，不是普通本地 build/test 的许可 gate。

## RV64 Linux and devices

处理 OpenSBI、Linux kernel、DTB、initramfs/rootfs、Ubuntu Base 或 Verilator Linux 启动时，读取
rv64-linux.agent.md 和 rv64-linux-bringup.instructions.md；设备与显示任务再读取 linux-device、
virtio-rootfs、display-vga 和 linux-framebuffer-vga 对应文件。
声称官方 Ubuntu riscv64 `/bin/sh`、dynamic linker、libc 或 lp64d/F/D 用户态成立时，再读取
rv64gc-userland.instructions.md；局部 FPU/CSR RTL 修改本身不自动触发完整 Ubuntu gate。

结论按以下层级分别给出证据：环境构建、QEMU reference、OpenSBI handoff、kernel 推进、PID1 或 /init、
用户态 probe、rootfs/shell、设备事务、自然 poweroff。rv64imac/lp64 syscall probe 不能证明
rv64gc/lp64d Ubuntu 用户态；AM VGA 或预留 MMIO window 不能证明 Linux framebuffer/fbcon；没有
virtio-mmio、vring、host backend、PLIC 和 Linux probe 不能证明 /dev/vda 路线闭合。

Verilator 是当前主要功能平台，但 DPI/host C++/SDL/文件 IO 只属于仿真平台层，不得在长期 core/SoC RTL
中形成不可综合后门。Vivado/FPGA 不是默认功能 bring-up 前置。

## Performance, synthesis and PPA

- NPC CPI、cache、BPU、LSQ、OoO、issue/commit、取指或访存优化读取
  npc-optimization-workflow.instructions.md。
- npc/rv64 完整双发射/OoO/PPA、综合、STA 或功耗取舍读取
  rv64-ppa-optimization-workflow.instructions.md 和 architecture/PPA contract。
- 性能结论不能只来自 add 或单个 smoke。按 domain contract 使用足够覆盖的 workload，并区分 correctness、
  causal measurement、timing qualification 和 Pareto/promotion。
- full-core DiffTest、L0 directed RTL、L2 mini-system、L3 lightweight Linux、完整 Ubuntu、综合、STA 和
  PPA 各自有独立适用范围；只运行本次 acceptance criteria 需要的层，不以低层 PASS 越级声明高层。
- 显式 persistent/published 长跑使用 task-run-status helper；工作负载、必要结果或 cleanup 未完成以及
  HUP/INT/TERM 均不是 PASS。固定 design/config 的确定性执行无需仅因耗时长而机械重跑。

## Source and artifact boundaries

- 不直接手改可再生成 build、obj_dir、波形、Yosys 运行物或 runtime cache 作为生产源码。
- 大日志、镜像、波形和临时 build 放在现有 runtime/cache 位置；release 或 forensic 确实需要 byte
  identity 时才使用 manifest/hash。
- memory 只保存稳定跨会话项目事实；普通定位、单次测试和 AI 内部流程不属于本文件的工程事实。
