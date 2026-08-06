# 证据台账

## 1. 研究对象与审计边界

本文研究的不是“AI 是否会写 RTL”，而是一个更窄、也更可检验的问题：

> 当自然语言中的“当前设计”“验证通过”“性能提升”和“任务完成”被迁移为可执行约束时，仓库级 RTL Agent 的输出是否更容易被归属、检验、拒绝和限定？

审计材料限定为当前仓库中 2026 年 4 月至 8 月 4 日的源码旁证、task-run 报告、原始仿真或 EDA 日志、结构化结果、design-id、哈希、负向 RTL 变体及回滚记录。本文没有改写任何历史 task-run，也没有为缺失的历史字段补造模型名称、返回码或设计身份。月度目录盘点仍冻结于 2026-07-29；八月现状以具名 run 和精确路径加入，不回填这张历史计数表。

这是一项纵向探索性案例研究。模型、任务难度、代码快照、工具和工作流在四月至八月初同时变化，所以本文可以报告“某机制在某个案例中实际拒绝了错误结论”，不能据此识别该机制的独立平均因果效应。

## 2. 证据优先级

发生冲突时，采用以下优先级：

1. 原始仿真、运行、综合或 STA 日志；
2. 绑定配置、design-id 和哈希的结构化结果；
3. task-report、evidence index 与 publication；
4. DB stored memory、模块记录与 known issues；
5. 个人叙述只解释背景，不单独承担技术结论。

“文件存在”不等于“主张成立”。每项主张还要核对设计对象、配置、命令、返回码、验证层级、反例能力和外推边界。

## 3. 证据状态

| 状态 | 含义 |
|---|---|
| `SUPPORTED` | 原始或结构化证据直接支持限定范围内的主张 |
| `PARTIALLY_SUPPORTED` | 存在相关证据，但缺少对照、覆盖或关键身份字段 |
| `OBSERVATIONAL_ONLY` | 只说明共现、过程或个案，不能解释因果 |
| `CONTRADICTED` | 仓库中的反例或边界直接否定该主张 |
| `MISSING` | 现有材料不足以支撑该主张 |

完整逐项映射见 `claim-evidence-map.tsv`。只读校验脚本当前检查 30 项主张，得到：

- `SUPPORTED`：18；
- `PARTIALLY_SUPPORTED`：4；
- `OBSERVATIONAL_ONLY`：1；
- `CONTRADICTED`：6；
- `MISSING`：1。

这些数量只是台账分类，不是研究效果指标。

## 4. task-run 目录盘点

`scripts/paper_evidence_extract.py` 对 `.github/task-runs/` 顶层目录做只读盘点。下表冻结于
2026-07-29 13:36 CST；工作区继续产生记录时，后续计数不回写为本文既有证据：

| 月份 | workflow-event 目录 | task-report | legacy report | manifest | evidence index | complete marker | publication |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2026-04 | 8 | 8 | 0 | 0 | 0 | 0 | 0 |
| 2026-05 | 137 | 132 | 0 | 0 | 0 | 0 | 0 |
| 2026-06 | 1246 | 1149 | 10 | 556 | 667 | 0 | 0 |
| 2026-07 | 670 | 636 | 0 | 480 | 585 | 224 | 219 |

计数口径非常重要：一个顶层日期目录只算一个 **workflow-event directory**。它不自动等于独立任务、成功任务、实验样本或生产率。六月的 1246 个目录主要说明工作流记录密度上升，不能写成“完成了 1246 个独立工程任务”。

## 5. 关键 task episode

正文把阶段里程碑限定为“当时新增且能够由原始记录支持的最高工程能力”，而不是当月所有
工作的集合：

| 工程阶段 | 可证里程碑 | 主要原始对象 |
|---|---|---|
| RV32 single（4 月） | 从 9 文件 lint-only RV32I 骨架推进到 AM image、pmem、serial/trace 和 code 0 构成的最小动态闭环；NEMU 此时提供分层与 ABI 参照，尚未成为运行时 DiffTest oracle | E01、E02 |
| RV32 SoC（5 月 23—24 日） | `npc/sim` 分流 `single/soc`，同一 `riscv32-ysyxsoc` 镜像和 MROM/SRAM 地址图进入 ysyxSoCFull target 与 NEMU reference；cpu-tests 39/39 DiffTest | E02-SOC |
| RV64 target/reference（5 月 29—30 日） | NPC 宽度迁移先形成无对拍 38/38；NEMU 补齐 RV64 reference 后形成 40/40 与 CoreMark DiffTest | E02-RV64 |
| RV64 系统与协议（5 月底—6 月） | 真实 OpenSBI handoff 后，NEMU 进入非交互 Ubuntu shell、NPC 到达 rootfs + systemd/banner；聚合回归定位并回退 branch speculation/JALR pending 全核死锁 | E03—E05 |
| RV64 系统事务与证据工程（7 月） | design-id、mutation、freshness 与发布边界进入同一证据链；A3 完成绑定快照的 Ubuntu 系统事务且永久保留 raw FAIL | E06—E11 |
| RV64 性能基线与因果诊断（8 月初） | 当前 design-id 达到 ARCH_STABLE/PERF_BASELINE；CPI census 形成嵌套驻留排序；owner-timing 外置诊断在首次 workload A/B 中因非法身份事件 fail-closed | E12 |

### E01：4 月 RV32I 骨架——语法通过不等于功能完成

- 报告：`.github/task-runs/2026-04-13-rv32i-nonpipe-core/task-report.md`
- 产物：`NpcCore` 与 8 个辅助 RTL 文件，共 9 个文件。
- 已证事实：Verilator lint 通过。
- 缺口：无 testbench、镜像加载器和 NEMU 对拍；普通异常仍是 halt-only。
- 台账结论：这是“代码生成能力”的证据，也是“只凭 lint 会产生假完成”的反例。

### E02：4 月 NPC DPI bring-up——第一次形成动态反馈

- 报告：`.github/task-runs/2026-04-13-npc-dpic-bringup/task-report.md`
- trace 补充报告：`.github/task-runs/2026-04-14-npc-trace-experience/task-report.md`
- 已证事实：DPI/C++、AM 镜像、pmem 与退出协议接通；`hello` 可输出并以 code 0 退出。
- trace 已证事实：batch `itrace`、batch `mtrace+dtrace` 和 monitor 动态 trace 三条路径均
  实测通过；mtrace 明确排除 ifetch。
- 意义：在本文回查材料中，Agent 候选首次进入“生成—运行—观察—修正”闭环。
- 边界：只证明最小运行链，不证明 ISA 或系统完整性。

### E02-SOC：RV32 single/soc 分层与 ysyxSoC/NEMU 对拍

- 目录与入口：
  - `.github/task-runs/2026-05-23-npc-single-soc-split/task-report.md`
  - `.github/task-runs/2026-05-23-npc-platform-switch/task-report.md`
- CPU ABI 与 SoC 接入：
  - `.github/task-runs/2026-05-23-npc-ysyx-soc-integration/task-report.md`
  - `.github/task-runs/2026-05-23-am-ysyxsoc-platform/task-report.md`
- Full SoC/cache：
  - `.github/task-runs/2026-05-24-b2-ysyxsocfull-cache/task-report.md`
- 已证数据流：`ARCH=riscv32-ysyxsoc -> npc/sim BACKEND=soc -> npc/soc ->
  ysyxSoCFull -> ysyx_26010035`；NEMU `CONFIG_SOC_SIM` 使用同类 MROM/SRAM
  地址图承担 DiffTest reference。
- 已证结果：MROM 入口 `0x20000000`，SRAM
  `0x0f000000..0x0f001fff`；新增 `char-test` 后 cpu-tests 39/39
  DiffTest PASS；Full SoC `char-test` 输出两条 UART 路径，`mem-test` 在
  PC `0x200002c6` GOOD TRAP。
- 边界：这些结果属于 Verilator/AM/NEMU 仿真闭环，不证明 ChipLink、FPGA 或物理芯片。

### E02-RV64：NPC 宽度迁移与 NEMU RV64 reference 同步形成

- NPC 首个 RV64 后端：
  `.github/task-runs/2026-05-29-npc-rv64-backend/task-report.md`
- NEMU RV64 DiffTest：
  `.github/task-runs/2026-05-30-rv64-nemu-difftest/task-report.md`
- 第一个冻结点：PC/GPR/CSR/AXI/DPI 扩宽，`*W` 和 8-byte lane 重新定义；
  cacheable 与 DiffTest 主动关闭，cpu-tests 38/38。
- 第二个冻结点：NEMU 补齐 RV64 CPU state/CSR、RV64I/M/B/C/W 等 reference
  路径；cpu-tests 40/40 DiffTest，CoreMark PASS、GOOD TRAP，
  `cycles=1915750807`、`commits=318393507`。
- 台账结论：38/38 只证明 NPC 在给定测试内自洽；40/40 与 CoreMark
  DiffTest 才增加了 target/reference 一致性证据。两者都不等于完整 ISA、Linux 或 PPA
  证明。

### E03：5 月 IQ 修复与候选淘汰

- 报告：`.github/task-runs/2026-05-29-ooo-cpi-645-iq-fix/task-report.md`
- 根因：dispatch-bypass 发射被错误当作 IQ entry 发射，compact 逻辑误删 slot0。
- 保留修复：增加真实 queue fire 判据及定向回归。
- 同配置结果：AM `add` 为 541 cycles / 839 commits / CPI 0.645。
- 被拒候选：
  - 双 memory 放宽后 CPI 从 0.645 退化到 0.665，回滚；
  - branch+ret focused test 通过，但 Verilator 报 `UNOPTFLAT` 组合环，回滚。
- 台账结论：反馈循环实际影响了候选的接受与拒绝；不能外推到其他 workload 或证明全局最优。

### E04：6 月分支推测——局部组件正确仍可能系统失败

- 报告：`.github/task-runs/2026-06-29-rv64-ooo-core-architecture-constitution/report.md`
- 快速门：lint 与 module 113/113 通过。
- 系统负结果：休眠分支推测打开后，riscv-tests 255/16，AM 25/32；ROB-walk 版本为 251/20，AM 14/43。
- 回退结果：mode=0 后 riscv-tests 恢复 271/0，module 113/113。
- 轨迹根因：branch speculation 冻结 commit，而 JALR 仍走 pending+drain；drain 等 ROB 排空，commit 又被冻结，形成环形等待。
- 台账结论：ROB-walk 局部 PASS 没有证明前端推测协议成立；聚合测试和 trace 关闭了一个具体假完成路径。

### E05：6 月 Ubuntu 里程碑——两个平台必须分层表述

NEMU：

- 报告：`.github/task-runs/2026-06-04-riscv64-nemu-ubuntu2204/task-report.md`
- 原始日志：`Linux/env/logs/linux-front/riscv64-nemu-ubuntu-rootfs-virtio-8b/console.log`
- 已证事实：virtio block 暴露 2 GiB vda，EXT4 挂载，Ubuntu 22.04.5，`/bin/sh -c` 返回 0，并进入 `/bin/sh`。

NPC：

- 报告：`.github/task-runs/2026-06-15-npc-ubuntu-current-direct/task-report.md`
- 原始日志：`.github/task-runs/2026-06-15-npc-ubuntu-current-direct/evidence/npc-rv64-linux-rootfs-mount-smoke-script/console.log`
- 已证事实：vda、EXT4/VFS root、systemd PID1、Ubuntu banner 和 hostname marker。
- 未证事实：没有 `root@ysyx-ubuntu2204:~#`，也没有 `__NPC_SYSTEMD_CHECK_DONE__ rc=0`。

台账结论：NEMU 是进入 shell 的里程碑；NPC 是 rootfs mount + systemd/banner 里程碑。二者不能合并成“NPC 与 NEMU 都完整启动 Ubuntu”。

### E06：7 月 Yosys 结构审计

- 报告：`.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/task-report.md`
- 原始日志：`.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/evidence/ppa-r3p4-alu-terminal/light-yosys/yosys.log`
- 结构统计：18115 wires、296118 wire bits、14645 generic cells、507 dff、6768 mux、1568 pmux。
- 工具结束状态：76 条 unique warning、124 条总 warning，`End of script`，24.82 s。
- 台账结论：日志证明了通用结构展开和可复核统计，不证明目标工艺映射面积、STA 或物理实现。

### E07：7 月 IFU、FENCE 与 STORE/AMO 的 mutation-qualified evidence

IFU V9I：

- 报告：`.github/task-runs/2026-07-22-rv64-v9i-ifu-access-current-design/task-report.md`
- design-id：`sha256:6236b176...f3dc`。
- 结果：focused 4/4、module 109/109、compile-success 负向 RTL 19/19 被拒绝。
- 边界：只覆盖 IFU-ACCESS-G1 和给定故障集。

FENCE V9M：

- 报告：`.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/task-report.md`
- design-id：`sha256:2eff867b...c8b2`。
- 结果：focused 2/2、module 109/109、两份负向 RTL 2/2、validator 12/12。
- 发布边界：full-core 仍为 `GAP`，38 blockers；PPA `UNQUALIFIED`；promotion=false。

STORE/AMO V9N：

- 报告：`.github/task-runs/2026-07-23-rv64-v9n-irrevocable-write-owner-residency/task-report.md`
- 结果：focused 2/2，source variants 2/2 动态拒绝，evidence unit 8/8，module 109/109。
- freshness 反例：reviewer 记录晚于 owner evidence，因 provenance 字节变化触发 GAP；随后完整重放上层依赖，而不是只更新摘要。
- 边界：定向动态仿真与源码变体不等价于全状态空间形式证明。

### E08：7 月 current design 与 candidate 身份分离

- 报告：`.github/task-runs/2026-07-23-rv64-v9o-control-event-current-design/task-report.md`
- live RTL：`sha256:08d3d864...8c6a`。
- verification source：`sha256:300d...3c1`。
- 旧 candidate：`sha256:2eff867b...c8b2`。
- 局部结果：focused 10/10、queue-head config 3/3、module 110/110、RTL variants 11/11、architecture gates 9/9。
- 全核结果：`architecture_freeze=GAP`、59 blockers、`PPA=UNQUALIFIED`、promotion=false。
- 台账结论：design-id 不能证明设计正确，但能阻止把旧候选的完整结论直接贴到新工作树。

### E09：5 ns PPA proxy 的正确表述

- 报告：`.github/task-runs/2026-07-14-rv64-t4i-standard-axi-lanes/task-report.md`
- 原始 setup：`.github/task-runs/2026-07-14-rv64-t4i-standard-axi-lanes/evidence/opensta-fresh-t4i-final/opensta-current-check-setup.txt`
- 代理结果：top40 40/40 MET，最差正裕量 `+0.017907454 ns`。
- 缺失约束：303 个输入无 input delay、1873 个输出无 output delay、1875 个 endpoint 未约束；理想时钟、无 SPEF/CTS/OCV/uncertainty，宏为占位 Liberty。
- 台账结论：只能称“当前冻结 RTL 在给定代理约束下通过内部路径筛选”，不能称 200 MHz 物理签核。

### E10：`OooPendingDrainResolveGate` 的三快照源码演化

完整复核表：`docs/research-paper/module-evolution-evidence.md`。

快照 A（2026-06-28）：

- commit：`0bb371593315afe507752dc134cabf122ed9751c`；
- 文件 SHA-256：`e0ac0be2253d84ffd41bb83314f1d24f65a861a0d8b45cd6555a2b222a6a38c7`；
- 代码语义：`backend_drained_o` 合取 ROB 空、IQ 空、retire count 为 0 和两个 synthetic lane1 pending 为 0；尚无显式 `mem_retire_quiet_i` 或 `mem_idle_i`；
- 附随证据：该文件字节一直保持到 `e7ff03a1d`；该任务结束时的回归为 module 112/112、official 271/0、AM 56/56；
- 边界：同期任务还修改了大量其他对象，且没有保存该 drain 谓词的专用负向 oracle。

快照 B（2026-07-13）：

- commit：`8532bad0794cb34199c8adf49b080e1773b1f16f`；
- 文件 SHA-256：`574fc78abebb587937e828ba961d1a6405cb20463d8f0ff0b7a9251d84e5628f`；
- 代码语义：快照中已存在退休/SQ 侧 `mem_retire_quiet_i`；T3I 以 `0b0d716...` 为直接基线，依据 `rob_count=0 -> retire_count=0` 删除冗余的 `core_retire_count_i`；
- 定向证据：2176 个有限二值合法域用例；删除 count guard 与 `|| 1'b1` 两个 proof mutation 均被拒绝；runner 19/19、module 96/96、official+privileged 177/177；
- PPA 边界：报告记录 fresh 5 ns WNS 从 -10.10 ns 变化到 -9.38 ns，但仍未达到 200 MHz 目标，状态保持 `UNQUALIFIED`；该变化不单独归因于谓词删除，2176 用例也不是完整形式化模型检查。

快照 C（2026-07-23）：

- commit：`c29532ead32bf2a268b821cef9665a44aec58f9f`；
- 文件 SHA-256：`6be380f766d03dfffbbe970b696226c14fd6eea4c6d741b491108c760be108b6`；
- 已验证 design-id：`sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`；
- 代码语义：ordinary FENCE 在既有 drain 合同之外额外等待 `mem_idle_i`，而其他 system event 不新增这一条件；
- 定向证据：focused 2/2、module 109/109、validator 12/12；两份可编译负向 RTL 分别删除 drain gate 条件和常量化 CoreGlue→ControlPlane 连接，均被唯一目标 oracle 拒绝；
- 发布边界：full-core `GAP`、38 blockers、PPA `UNQUALIFIED`、promotion=false。

台账结论：三个不可变快照直接支持同一模块合同的源码演化；T3I 和 V9M 还支持指定 fault set 内的辨识力。由于快照之间存在 LSQ/SQ、pending event 和其他模块的并行变化，这不是单因素实验，不能把性能或全核正确性的变化归因于某一条新增/删除的布尔条件。

### E11：7 月 NPC Ubuntu 22.04 十九小时 A3 系统事务

完整复核表：`docs/research-paper/ubuntu-19h-milestone-evidence.md`。

运行身份与口径：

- 源 run：`.github/task-runs/2026-07-27-rv64-v10e-current-design-system-recert/rootfs-c1b531-systemd-strict-6b-a3/`；
- design-id：`sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`，pre/post 相同；
- console SHA-256：`4cd087fc5ef5d466d6232987fecaf3765db5dc93dfe28366401e2da4501c60f0`；
- 启动：2026-07-27 19:16:03；fail-closed 状态落盘：2026-07-28 14:30:46；
- 墙钟约 19 h 14 min 43 s，其中 simulator 自报 host time 18 h 48 min 22 s；
- guest 在 49.720532 s 虚拟时间发起 power down。因此“十九小时”是宿主仿真耗时，不是 guest 连续运行十九小时。

系统数据流：

- OpenSBI v1.8 → Linux 6.6；
- `virtio_blk virtio0` 识别 2 GiB `/dev/vda`；
- EXT4 根文件系统挂载到 device 254:0；
- Ubuntu 22.04 的 systemd 249 作为 PID1 运行；
- guest strict checker 在 root context 下验证 `/bin/sh`、`/bin/bash`、vda 驱动、root-on-vda、EXT4 read-write；
- rootfs 写入、`sync`、回读通过；
- 128×4 KiB direct read 后 virtio IRQ 计数从 537 增至 672；
- systemd 自然关机，kernel `Power down`，syscon poweroff，`GOOD TRAP`，system-reset code 0。

执行结束时的规模：

- 5,071,521,696 guest cycles；
- 1,223,536,213 commits；
- CPI 4.145；
- 18,072 inst/s。

原始 gate：

- preflight 6/6 PASS；
- autocheck 6/6 PASS；
- strict 16/17，唯一 FAIL 为 `dmesg-no-critical`；
- 原始状态保持 `FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`。

根因与冻结 oracle 重放：

- A3 rootfs 内的旧规则使用大小写不敏感的裸 `BUG:` 子串，误匹配了两次
  `printk: debug: ignoring loglevel setting.`；
- 当前规则把 `BUG:` 限制为独立 token，A3 console 的 match 从 2 变为 0，同时真实
  `BUG: unable to handle page fault` fixture 仍被拒绝；
- 重放 run：`.github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/`；
- terminal 6/6，独立 reviewer 给出 `APPROVED_NOT_PROMOTION_ELIGIBLE`；
- A4 是 `FAIL rc=143 ... signal=TERM`，不是新 live PASS。

台账结论：A3 支持“指定冻结设计完成 Ubuntu 22.04 guest 系统事务，并由独立重放定位旧
oracle 假阳性”。它不支持“raw 17/17 live recertification PASS”；更不能据此完成
architecture freeze 或 PPA qualification。这里最重要的工程信号是：系统行为、检查器结果
和 promotion 状态被拆成三个可独立审计的命题，十九小时成本没有迫使流程把它们粗暴合并。

### E12：8 月初从 ARCH_STABLE 到 CPI 因果诊断

当前设计与性能基线：

- design-id：`sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`；
- `npc/rv64/eval/ppa/evidence/arch-stable-current.json`：`ARCH_STABLE`、`ppa=UNQUALIFIED`、`promotion_eligible=false`；
- CoreMark10：5,392,187 cycles / 3,183,617 retired，CPI 1.693729804810；
- Dhrystone10000：10,311,431 cycles / 4,250,000 retired，CPI 2.426219058824；
- 每个 workload 三次 stats-on 的完整 counter stack bit-exact；各一次 stats-off 的 cycles/retired 与 stats-on 完全一致。

原始状态与资格勘误：

- A1/A2 原始性能 runner status 都保持 FAIL；旧 consumer 因 Dhrystone ROI 从 lane1 到 lane0、`phase_aligned=0` 而拒绝；
- 精确双发射容量满足 `2 * cycles + end_lane - start_lane = 20,622,861`；
- `performance-boundary-qualification-amendment-v1.json` 只替换冲突的 lane-equality 代理条件，保留身份、marker、overflow、invalid-event、cycle/slot/nested conservation 与重复性门；
- `.github/task-runs/2026-08-04-rv64-v14n-performance-baseline-current-v2/checker-replay-endpoint-correction-v1.status` 为 PASS；它绑定冻结 A2 日志、版本化勘误和新鲜 ARCH_STABLE postflight，不覆盖原始 FAIL；
- canonical receipt 只授予 `PERF_BASELINE`，PPA 仍为 `UNQUALIFIED`。

CPI census：

- run：`.github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/`；
- CoreMark 的 `memory_latency/request_outstanding/axi_write_response` 为 2,542,049 / 1,139,006 / 691,538 cycles；
- Dhrystone 为 7,100,359 / 4,510,140 / 2,969,998 cycles；
- 两个 workload 的共同嵌套排序为 `memory_latency -> request_outstanding -> axi_write_response`；
- 三层数字嵌套而非互斥可加；edge-old residency 不是事务数或单次延迟；H1 下游 B 延迟、H2 bridge 并发、H3 duration weighting、H4 pre-request pipeline 尚未区分；
- `optimization_candidate_authorized=false`。

owner-timing 诊断基础设施：

- `NpcOooOwnerTimingProbe.sv` 通过 `bind NpcSimTop` 只读两个 `OooMemAxiBridge`，每个 posedge 在一次 DPI 调用中提交两个 64-bit sample；
- `owner_timing_collector.cpp` 记录 owner kind/token/epoch、station/request、AW/W/B、response/drop/cancel，并对阶段时长、ROB-head 关联、双桥 overlap 和 invalid reason 守恒；
- `owner-timing.mk` 只向诊断构建追加 probe/collector/define，不修改 production filelist；
- V14P link 记录：9 个 C++ 单元用例、SV lint、full DPI link 通过；production manifest 前后都是 148 文件，aggregate SHA-256 为 `2f1489…a6edd`；
- 该 PASS 只证明诊断基础设施，不证明 workload owner timing。

首次 workload A/B 的失败关闭：

- run：`.github/task-runs/2026-08-04-rv64-v14q-owner-timing-workload-ab-v1/`；
- CoreMark、Dhrystone、baseline/ARCH_STABLE pre/post、manifest 与 cleanup 均能完成；
- CoreMark 三次 owner summary 均为 `complete=0 available=1 overflow=0 invalid_events=1176`；Dhrystone 三次均为 `complete=0 available=1 overflow=0 invalid_events=49993`；
- V3 冻结负向重放只覆盖 CoreMark 的 1176-event 样本：invalid 全部归入 `admission_identity_change`，并与 1176 个 cancelled admission 守恒；该结论不外推到 Dhrystone 样本；
- receipt build 返回 1，最终状态为 `FAIL rc=1 stage=receipt-build evidence_complete=0 cleanup_rc=0`；
- 冻结 invalid-probe replay 为 PASS，含义是 checker 成功拒绝 CoreMark 样本中的该类不合格量测；不是 workload 性能 PASS；
- 未消费同一日志中的阶段时长，未授权 production RTL candidate，PPA 仍为 `UNQUALIFIED`。

台账结论：E12 支持“环境已把性能基线、驻留分解、竞争假设和诊断非干扰落实为可执行链，并在首次 workload 量测不合格时失败关闭”。它不支持“已经找到唯一 CPI 根因”“已经完成 CPI/PPA 优化”或“owner-timing workload 已通过”。

## 6. 九类失败模式

| 类别 | 假完成路径 | 仓库中的代表反例 | 当前机制 |
|---|---|---|---|
| A | 语法通过冒充功能正确 | 4 月 RV32I 只有 lint | 动态 TB、镜像和对拍 |
| B | 局部通过冒充系统通过 | branch+ret focused PASS 后 `UNOPTFLAT`；spec-on 聚合失败 | 分层回归 |
| C | 代理指标冒充签核 | generic Yosys cells、理想时钟 STA | PPA qualification boundary |
| D | 不可比指标拼成趋势 | 不同 workload 的 CPI / phase metric | matched configuration |
| E | 过期或跨设计证据 | V9O task-report 与 evidence-index 保存了冲突的身份元组 | design-id / source-id + publication 一致性检查 |
| F | 不完整证据被当作完成 | marker、publication、DB 状态可能不一致 | fail-closed publication |
| G | 弱 oracle 使 mutation 假绿 | 同值连接、force/release 旧值、源码未变 | source-mutant SHA、非对称刺激 |
| H | 搜索失败未回滚 | 双 memory 退化、分支推测活锁 | 分层门禁与 rollback |
| I | benchmark PASS 冒充量测有效 | owner-timing A/B 中 CoreMark/Dhrystone 每次分别有 1176/49993 个 identity-change invalid event | complete/invalid/conservation gate + 有边界的负向 replay |

## 7. 当前最强的四项贡献

1. **可执行约束迁移框架**：把“当前设计”“通过”“性能提升”“完成”等自然语言要求拆成对象、配置、命令、退出码、负向证据和主张边界。
2. **设计身份与拒绝发布的证据闭环**：design-id、source-id、原始日志哈希、freshness、evidence index 和 GAP 状态共同使证据归属与不完整性可见。
3. **面向 oracle 的负向验证**：mutation 不再被当作 PASS 数装饰，而用于检验测试能否拒绝指定错误，同时保留等价变体、不可观测变体和全状态空间未覆盖等边界。
4. **归因前的性能诊断制度**：同一 design-id 下先冻结可重复基线、验证计数非干扰、守恒分解 CPI 并预注册竞争假设；诊断量测自身不合格时不得产生 RTL 候选。

## 8. 不能由当前证据支持的四项原强主张

1. “Loop 已被证明比 Prompt 更好”：`MISSING`，因为没有同模型、同快照、同预算的 B0—B3 对照。
2. “当前 RV64CORE 已完成 200 MHz 物理 PPA 签核”：`CONTRADICTED`，因为 I/O 约束、寄生、时钟树、OCV 和真实宏模型均不完整。
3. “mutation 全绿说明 RTL 正确、oracle 完备”：`CONTRADICTED`，因为仓库已有等价、未改变字节、同值连接和旧值 force/release 等反例。
4. “CPI census 已证明 AXI B response 是唯一根因并已完成优化”：`CONTRADICTED`，因为当前排序是嵌套驻留，H1—H4 尚未被合格 workload 量测区分，candidate 仍未授权。

## 9. 复核入口

```bash
python3 docs/research-paper/scripts/paper_evidence_extract.py \
  --verify-claims docs/research-paper/claim-evidence-map.tsv
```

脚本只读取仓库并向标准输出打印 JSON；不更新 DB、不修改 task-run，也不生成“完成”状态。
