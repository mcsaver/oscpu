# 证据台账

## 1. 研究对象与审计边界

本文研究的不是“AI 是否会写 RTL”，而是一个更窄、也更可检验的问题：

> 当自然语言中的“当前设计”“验证通过”“性能提升”和“任务完成”被迁移为可执行约束时，仓库级 RTL Agent 的输出是否更容易被归属、检验、拒绝和限定？

审计材料限定为当前仓库中 2026 年 4—7 月的源码旁证、task-run 报告、原始仿真或 EDA 日志、结构化结果、design-id、哈希、负向 RTL 变体及回滚记录。本文没有改写任何历史 task-run，也没有为缺失的历史字段补造模型名称、返回码或设计身份。

这是一项纵向探索性案例研究。模型、任务难度、代码快照、工具和工作流在四个月中同时变化，所以本文可以报告“某机制在某个案例中实际拒绝了错误结论”，不能据此识别该机制的独立平均因果效应。

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

完整逐项映射见 `claim-evidence-map.tsv`。只读校验脚本当前检查 21 项主张，得到：

- `SUPPORTED`：11；
- `PARTIALLY_SUPPORTED`：3；
- `OBSERVATIONAL_ONLY`：1；
- `CONTRADICTED`：5；
- `MISSING`：1。

这些数量只是台账分类，不是研究效果指标。

## 4. task-run 目录盘点

`scripts/paper_evidence_extract.py` 对 `.github/task-runs/` 顶层目录做只读盘点：

| 月份 | workflow-event 目录 | task-report | legacy report | manifest | evidence index | complete marker | publication |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2026-04 | 8 | 8 | 0 | 0 | 0 | 0 | 0 |
| 2026-05 | 137 | 132 | 0 | 0 | 0 | 0 | 0 |
| 2026-06 | 1246 | 1149 | 10 | 556 | 667 | 0 | 0 |
| 2026-07 | 586 | 557 | 0 | 421 | 514 | 195 | 190 |

计数口径非常重要：一个顶层日期目录只算一个 **workflow-event directory**。它不自动等于独立任务、成功任务、实验样本或生产率。六月的 1246 个目录主要说明工作流记录密度上升，不能写成“完成了 1246 个独立工程任务”。

## 5. 关键 task episode

### E01：4 月 RV32I 骨架——语法通过不等于功能完成

- 报告：`.github/task-runs/2026-04-13-rv32i-nonpipe-core/task-report.md`
- 产物：`NpcCore` 与 8 个辅助 RTL 文件，共 9 个文件。
- 已证事实：Verilator lint 通过。
- 缺口：无 testbench、镜像加载器和 NEMU 对拍；普通异常仍是 halt-only。
- 台账结论：这是“代码生成能力”的证据，也是“只凭 lint 会产生假完成”的反例。

### E02：4 月 NPC DPI bring-up——第一次形成动态反馈

- 报告：`.github/task-runs/2026-04-13-npc-dpic-bringup/task-report.md`
- 已证事实：DPI/C++、AM 镜像、pmem 与退出协议接通；`hello` 可输出并以 code 0 退出。
- 意义：Agent 的候选第一次进入“生成—运行—观察—修正”闭环。
- 边界：只证明最小运行链，不证明 ISA 或系统完整性。

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
- 工具终点：76 条 unique warning、124 条总 warning，`End of script`，24.82 s。
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
- 附随证据：该文件字节一直保持到 `e7ff03a1d` 战役终点，战役级回归为 module 112/112、official 271/0、AM 56/56；
- 边界：战役同时修改了大量其他对象，且没有保存该 drain 谓词的专用负向 oracle。

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

## 6. 八类失败模式

| 类别 | 假完成路径 | 仓库中的代表反例 | 当前机制 |
|---|---|---|---|
| A | 语法通过冒充功能正确 | 4 月 RV32I 只有 lint | 动态 TB、镜像和对拍 |
| B | 局部通过冒充系统通过 | branch+ret focused PASS 后 `UNOPTFLAT`；spec-on 聚合失败 | 分层回归 |
| C | 代理指标冒充签核 | generic Yosys cells、理想时钟 STA | PPA qualification boundary |
| D | 不可比指标拼成趋势 | 不同 workload 的 CPI / phase metric | matched configuration |
| E | 过期或跨设计证据 | V9O live `08d3…` 与 candidate `2eff…` | design-id / source-id |
| F | 不完整证据被当作完成 | marker、publication、DB 状态可能不一致 | fail-closed publication |
| G | 弱 oracle 使 mutation 假绿 | 同值连接、force/release 旧值、源码未变 | source-mutant SHA、非对称刺激 |
| H | 搜索失败未回滚 | 双 memory 退化、分支推测活锁 | 分层门禁与 rollback |

## 7. 当前最强的三项贡献

1. **可执行约束迁移框架**：把“当前设计”“通过”“性能提升”“完成”等自然语言要求拆成对象、配置、命令、退出码、负向证据和主张边界。
2. **设计身份与拒绝发布的证据闭环**：design-id、source-id、原始日志哈希、freshness、evidence index 和 GAP 状态共同使证据归属与不完整性可见。
3. **面向 oracle 的负向验证**：mutation 不再被当作 PASS 数装饰，而用于检验测试能否拒绝指定错误，同时保留等价变体、不可观测变体和全状态空间未覆盖等边界。

## 8. 不能由当前证据支持的三项原强主张

1. “Loop 已被证明比 Prompt 更好”：`MISSING`，因为没有同模型、同快照、同预算的 B0—B3 对照。
2. “当前 RV64CORE 已完成 200 MHz 物理 PPA 签核”：`CONTRADICTED`，因为 I/O 约束、寄生、时钟树、OCV 和真实宏模型均不完整。
3. “mutation 全绿说明 RTL 正确、oracle 完备”：`CONTRADICTED`，因为仓库已有等价、未改变字节、同值连接和旧值 force/release 等反例。

## 9. 复核入口

```bash
python3 docs/research-paper/scripts/paper_evidence_extract.py \
  --verify-claims docs/research-paper/claim-evidence-map.tsv
```

脚本只读取仓库并向标准输出打印 JSON；不更新 DB、不修改 task-run，也不生成“完成”状态。
