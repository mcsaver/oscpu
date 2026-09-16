# RV64 OoO PERF_BASELINE current 方法与工作流

## 1. 当前结论

本页是 `ARCH_STABLE` 之后、CPI 单机制优化之前的性能基线入口。它采用先进 SoC
sign-off 通用的四项原则：不可变输入、版本化合同、职责分离、fail-closed 发布。
production RTL、workload、ROI、simulator、配置或 memory/device latency 语义均未因本轮
checker 修订而改变。

当前设计身份：

- `sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488`
- CoreMark10：`5,392,187 cycles / 3,183,617 retired`，CPI `1.693729804810`
- Dhrystone10000：`10,311,431 cycles / 4,250,000 retired`，CPI `2.426219058824`
- 两个 workload 均为 3 次完整 counter stack bit-exact；stats-off 的 cycles/retired
  与 stats-on 完全一致
- 本阶段只授予 `PERF_BASELINE`；PPA 为 `UNQUALIFIED`，不得据此声称 frequency、area、
  power 或 Pareto promotion

规范入口：

- 基线合同：`../../design/arch/performance-baseline-contract-v2.json`
- lane 端点资格勘误：`../../design/arch/performance-boundary-qualification-amendment-v1.json`
- 原始测量合同：`../../design/arch/performance-measurement-contract-v1.json`
- 原始计数 schema：`../../design/arch/performance-counter-schema-v4.json`
- canonical receipt：`evidence/performance-baseline-current.json`

## 2. 为什么保留原始 FAIL

V14N A1 与 A2 都保持原始 `FAIL`，不得回写为 PASS。A2 的六次 stats-on、一次
stats-off build、两次 stats-off 执行、manifest 和清理均完成；旧 consumer 因
Dhrystone ROI 从 lane1 开始、到 lane0 结束而拒绝其 `phase_aligned=0`。

该区间的精确双发射 slot 容量是：

```text
slot_capacity = 2 * cycles + end_lane - start_lane
              = 2 * 10,311,431 + 0 - 1
              = 20,622,861
```

v4 计数器本身已经定义并满足这个公式，但旧 qualification 子句另行要求
`start_lane == end_lane`。因此修复对象是资格合同，不是 RTL、benchmark、ROI 或原始
日志。v1 checker 继续拒绝该输入；只有显式绑定 endpoint amendment 的 v2
composite replay 才能接受，防止静默放宽 oracle。

## 3. 发布状态机

```text
A1/A2 immutable FAIL
        |
        v
bind frozen A2 manifest + v2 contract + endpoint amendment
        |
        v
PRECHECK (all identity, marker, ledger, repetition, stats-off checks)
        |
        v
fresh ARCH_STABLE verify
        |
        v
bind postflight artifact -> canonical build -> canonical verify
        |
        v
independent review -> publish PERF_BASELINE current
```

任一阶段返回非零、marker 缺失、artifact hash 漂移、原始 FAIL 被改写、postflight 未执行、
counter 不守恒或重复运行不再 bit-exact，都必须停在 FAIL/GAP。checker replay 不能单独
覆盖原始 full-run 状态；最终 v2 receipt 必须同时绑定原始执行、清理、合同勘误和新鲜
postflight。

## 4. 固定轮子与人工职责

确定性动作由以下固定入口完成，AI/审查者只读其 bounded 输出：

- full DUT 执行模板：`run-performance-baseline-current.sh`
  - 保留 v1 行为；在当前 Dhrystone 未对齐端点下应 fail-closed
  - 仅当 RTL、elaboration、simulator/device semantics 或冻结输入需要重跑时使用
- 冻结证据组合重放：`run-performance-baseline-replay.sh`
  - 不启动 DUT、不综合
  - 顺序执行 replay-manifest、precheck、ARCH_STABLE postflight、postflight binding、
    canonical build 与 verify
- receipt consumer：`tools/performance_baseline_current.py`
- 定向回归：`tests/test_performance_baseline_current.py`

独立审查通过后，canonical 发布只走一个固定入口：

```text
python3 -B npc/rv64/eval/ppa/tools/performance_baseline_current.py publish \
  --review npc/rv64/eval/ppa/evidence/performance-baseline-independent-review-current.json \
  --output npc/rv64/eval/ppa/evidence/performance-baseline-current.json
```

`publish` 会重新验证 review decision、result/final-manifest SHA、task-run PASS、六阶段
返回码、bounded regression marker 和 canonical result；不能用复制文件替代。

阶段归属也属于合同：`npc/rv64/design/arch/*.md` 是 ARCH_STABLE 的上游规范集合，
ARCH_STABLE 之后产生的性能方法与收据说明必须放在 `npc/rv64/eval/ppa/`。这样可以防止
下游 PERF_BASELINE 文档反向改变上游 architecture-freeze exact-input 集合，形成循环依赖。

实现者负责给出合同、artifact identity、返回码与 counter 账本；独立审查者优先寻找
合同冲突、原始状态改写、未绑定 postflight、守恒假绿、bit-exact 假绿和 PPA 越级。
审查在确定性交付点集中执行，不在普通只读 review 或每次局部编辑后重复启动重流程。

## 5. task-run 留存边界

task-run 只保留：

- fail-closed status 与各阶段返回码
- precheck/final manifest、canonical result、postflight marker
- bounded checker/test 日志、独立审查结论和关键 SHA-256
- 原始 A1/A2 的证据指针；原始状态和日志保持不可变

不保留：可再生的 Verilator/Yosys build tree、对象文件、临时 Python cache、重复 simulator
副本或无结论的完整终端转储。stats-off build 在冻结所需 simulator 后立即清理；综合只保留
报告、约束、工具/设计身份和必要的最终网表，其他中间物按既定清理策略删除。

## 6. 刷新与复用

以下任一变化要求刷新基线或重跑相应层级：production/elaborated RTL、ARCH_STABLE
receipt/candidate、simulator/host harness 语义、配置、workload image、ROI PC、counter
schema、measurement/amendment/policy/checker、memory/device latency。

若只改变 checker、parser、report、collector、status 或文档，并且原始输入、完整日志、终端
状态、post-hash 和设计绑定齐全，则优先 versioned replay。此复用规则不允许删除反例、弱化
断言、去重重复事务或改变测量窗口来制造 PASS。

## 7. CPI bottleneck census 与候选准入

`PERF_BASELINE` 之后先做驻留统计，不直接改 RTL。当前固定入口为：

- consumer：`tools/performance_bottleneck_census.py`
- 定向测试：`tests/test_performance_bottleneck_census.py`
- fail-closed runner：`run-performance-bottleneck-census.sh`
- canonical evidence：`evidence/cpi-bottleneck-census-current.json`

方法按以下顺序执行：

1. 重新计算并验证 canonical `PERF_BASELINE`，绑定 design ID 与输入 SHA；
2. 输出完整 cycle、retire-slot、memory-lifecycle、request-detail 向量，并逐层守恒；
3. 把 ROB-head edge-old residency 与 transaction count、duration 和因果结论严格分开；
4. 为所有竞争假设预先定义判别 channel，而不是先选机制再寻找支持数据；
5. 只有双 workload 的 owner-correlated 量测完整、无 overflow/invalid/unknown、账本守恒且能排除
   主要替代解释时，才允许生成单一 RTL 优化候选。

当前两个 workload 的共同驻留层级是
`memory_latency -> request_outstanding -> axi_write_response`。这只是定位入口：
`S_WRITE_RESP` 在 `OooMemAxiBridge` 中仍等待真实 `BVALID`，B response 是唯一完成终端；不得以
高驻留为由提前完成 store、去掉 B terminal 或削弱断言。

V2 判别计划采用三个 channel：

- owner transaction：按 `STORE/AMO/A-D` 统计事务数及 `S_WRITE_REQ/S_WRITE_RESP` 固定分箱时长；
- bridge timing：记录 AW/W 完成到 BVALID、owner 入桥等待、write inflight occupancy 与独立内存
  工作重叠；
- pre-request pipeline：记录 reservation/translation 进入退出计数、时长分布及 ROB-head owner
  关联。

它们分别区分 downstream B latency、bridge concurrency、head-residency duration weighting 与
pre-request pipeline 四类解释。量测实现必须保持 workload、ROI、simulator、配置、memory/device
latency、生产请求/响应/退休语义、全部断言和 v4 counter 守恒不变。

当前 census 只授予 `CPI_BOTTLENECK_CENSUS`，并保持
`optimization_candidate_authorized=false`、`ppa=UNQUALIFIED`、
`promotion_eligible=false`。新增诊断 counter 通过定向测试和短 task-run 收口；只有生产 RTL 语义
或实际 elaborated RTL 改变后，才进入功能回归、完整 workload A/B 与 PPA sign-off 路径。

## 8. owner-correlated timing 诊断标准

V14P 把 V2 判别 channel 实现为 production 外置 bind probe 与独立 C++ collector。统一入口和
变化触发矩阵见 `instrumentation/README.md`，机器可读配置为
`instrumentation/owner-timing-validation-profile-v1.json`。该配置把常见 SoC sign-off 方法压缩为
四项可执行规则：基线设计身份不可变、诊断与 production filelist 隔离、按变化影响选择
fast/link/workload A-B 层级、确定性交付后再做独立反例审查。

`scripts/agent-flow.c` 只保存两个显式指针：普通 instrumentation 修改在候选点运行
`rv64-owner-timing-fast`；sample ABI、DPI、顶层层次或配置变化运行
`rv64-owner-timing-link`，并自动替代 fast，避免重复。只读 review/analysis 仍为零 gate；约 40%
只是流程开销复盘目标，不参与 PASS/FAIL。

量测合同区分正常 `response_fire`、`active_drop` 与 `station_cancel`，非法 `S13..S15` fail-closed，
并将 `S_SQ_QUERY` 单列，防止把 flush 取消计入正常完成分箱或把 SQ 查询误称为 translation。
在 stats-off/stats-on workload A/B、counter identity、终端 marker 与全区间守恒闭合前，V14P 仅是
诊断基础设施，继续保持候选未授权和 PPA 未资格化。

checker/profile/report-only 修订使用 `replay-owner-timing-link.sh`：原始 link task-run 状态保持不变，
新版本必须同时绑定 source simulator/log/identity SHA、当前 fast PASS、同一工具版本与 production
manifest，并逐个比较 contract/probe/collector/Make fragment。该 replay 只避免重复 elaboration/link，
不能替代首次 workload A/B 或任何 production/elaboration/simulator/device 语义变化后的重跑。
