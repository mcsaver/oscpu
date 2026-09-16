# RV64 owner-correlated timing diagnostics

本目录是 `PERF_BASELINE` 之后、production RTL 优化候选之前的诊断层。方法参考先进 SoC
sign-off 的共同做法：需求到观测可追踪、配置不可变、按变化影响选择验证层级、实现与终审分工、
结果 fail-closed、可再生产物与需留档证据分离。这里不声称复刻任何厂商的私有流程。

## 1. 对象与边界

- probe 只通过 SystemVerilog `bind` 读取两个 `OooMemAxiBridge` 的 edge-old 状态、
  owner kind/token/epoch、station/request、AW/W/B 和 response/drop 终端；
- collector 只输出 owner-correlated duration、ROB-head token 关联、双桥 overlap、状态与区间守恒；
- `NpcSimTop.sv`、`OooMemAxiBridge.v`、production filelist 和退休/请求/响应语义均不修改；
- `BVALID` 仍是 write completion 的真实终端，flush/drop 进入 `cancelled`，不能进入正常完成分箱；
- 本层保持 `optimization_candidate_authorized=false`、`ppa=UNQUALIFIED`。

规范文件：

- 量测语义与 sample ABI：`owner-timing-contract-v1.json`
- 验证触发、配置和留存：`owner-timing-validation-profile-v1.json`
- 诊断 build fragment：`owner-timing.mk`
- 固定检查轮：`check-owner-timing.sh`
- fail-closed task-run 包装：`../run-owner-timing-diagnostics.sh`
- checker-only link 证据重放：`../replay-owner-timing-link.sh`
- 冻结 workload A/B 与单 workload invalid probe：`../run-owner-timing-workload-ab.sh`
- invalid-probe checker-only 重放：`../replay-owner-timing-invalid-probe.sh`

## 2. 按变化影响选择层级

| 工作类型 | 触发点 | 固定动作 | task-run |
|---|---|---|---|
| 只读 review / analysis | 无源码落盘 | 无 gate；直接给反例与 GAP | 不需要 |
| collector、合同或 probe 局部编辑 | 确定性候选形成后 | `--tier fast`：合同/ABI/config 负向检查、12 个 collector 与 14 个 workload consumer 正负向单测、SV lint、身份无漂移 | 通常不需要 |
| 层次路径、sample bit、DPI ABI、顶层 elaboration、Make/config 变化 | 确定性交付前一次 | `--tier link`：包含 fast，再做完整 Verilator/C++/DPI 链接 | 保留一次结果包 |
| 首次 workload 量测或 ROI/workload/simulator/device/elaborated RTL 变化 | 正式量测点 | stats-off/stats-on A/B、counter identity、终端 marker、collector 守恒 | 必须 |
| production RTL 语义变化后的根因复测 | focused闭合后一次 | current-design invalid probe；旧baseline只作counter reference，不作性能判定 | 必须 |
| production RTL 语义变化后的晋级 | 架构候选点 | 重建同设计ARCH_STABLE/cohort后再做完整A/B/CPI/PPA | 按既有等级 |

“约 40%”只用于复盘流程是否过重，不是时间门禁。完整链接不会因普通 review、每次文本编辑或
无关文件变化重复执行；`link` 已包含 `fast`，C 调度器会消除两者的重复调用。

## 3. 固定入口

快速开发验证：

```text
npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh --tier fast
```

ABI / elaboration 交付验证：

```text
npc/rv64/eval/ppa/instrumentation/check-owner-timing.sh --tier link
```

需要留档时：

```text
npc/rv64/eval/ppa/run-owner-timing-diagnostics.sh \
  --run-dir .github/task-runs/<run-id> --tier link
```

首次 workload A/B：

```text
npc/rv64/eval/ppa/run-owner-timing-workload-ab.sh \
  --run-dir .github/task-runs/<run-id>
```

该入口复用冻结 PERF_BASELINE 的三次 reference，重新执行每 workload 三次 diagnostic；逐日志比较
region final、完整 v4 counter payload、GOOD TRAP 与 owner 84 行账本。任一重复不一致、观测扰动、
overflow/invalid、产品 manifest 漂移或 runtime build 未清理都会 fail closed。

若完整 A/B 首次暴露 collector `invalid_events`，或production RTL修复后只需复测该根因，先用一个
workload做最小判别，不重跑六份样本：

```text
npc/rv64/eval/ppa/run-owner-timing-workload-ab.sh \
  --run-dir .github/task-runs/<run-id> \
  --mode invalid-probe --workload coremark
```

同设计invalid probe必须与冻结reference的region/v4 counter bit-exact。跨设计invalid probe仍必须保持
benchmark/GOOD TRAP、完整ROI、84行owner inventory、production manifest前后稳定、simulator identity、
invalid-reason conservation与cleanup闭合，但旧baseline只作counter reference；收据记录match结果并固定
`observer_noninterference_qualified=false`、`performance_comparison_authorized=false`、
`PPA=UNQUALIFIED`。`qualified`只表示本次collector无invalid，不授权candidate或PPA。

只修parser/checker且冻结输入完整时，另建版本化replay：

```text
npc/rv64/eval/ppa/replay-owner-timing-invalid-probe.sh \
  --source-run .github/task-runs/<immutable-failed-probe> \
  --run-dir .github/task-runs/<versioned-replay-run>
```

同设计replay默认要求结果byte identity。若原始跨设计run在receipt-build因旧oracle失败且尚无result，使用
`--mode current-design`；它重新解析冻结manifest/simulator/cleanup/log并生成v2诊断收据，不重跑DUT，
不把跨设计counter差当作observer或PPA证据。两种模式都保留原始FAIL并声明`dut_rerun=0`、
`production_rtl_modified=0`。

`scripts/agent-flow.c` 暴露 `rv64-owner-timing-fast` 与 `rv64-owner-timing-link` 两个 gate
pointer。instrumentation 路径默认只选择 fast；只有上述 ABI/elaboration 变化才显式登记 link。
review/analysis 类任务即使读取这些路径也保持零 gate。

只改 checker/profile/report 且 link 语义输入未变化时，保留原 link task-run 并组合当前 fast：

```text
npc/rv64/eval/ppa/replay-owner-timing-link.sh \
  --source-run .github/task-runs/<immutable-link-run> \
  --run-dir .github/task-runs/<versioned-replay-run>
```

replay 必须逐项复核 source PASS/rc/full-link/cleanup、诊断 simulator SHA、工具版本、完整
production manifest，以及 contract/probe/collector/Make fragment 四个 link 语义输入；任一变化即 FAIL。
失败 replay 保留原状态，修正 checker 后另建版本，不覆盖历史。

## 4. 证据与清理

task-run 只保留 status、返回码、有界日志、输入 SHA-256 和独立审查结论。unit binary、
Verilator `obj_dir`、诊断 simulator 和完整 build log 位于 `.github/runtime-artifacts`，检查结束时
按已解析目录清理。生产综合同理：通常只留报告、约束、工具/设计/配置身份和必要最终网表，
不留可再生 Yosys 中间树。

CoreMark/Dhrystone 的单个 ROI 均由首次 start PC 与其后的首次 end PC 界定。循环 workload 可以在
ROI 内重复退休 start PC；这些命中保留在 `start_hits`，但不会重开区间或制造 invalid event。
该规则只处理 benchmark 边界 PC，不合并或去重任何 B response、owner terminal 或事务事件。

PASS 只证明合同可解析、checker 对所列反例敏感、bind 可 elaboration、DPI 可链接且观测输入
未被构建改写；它不证明 workload 结果有效，不授权 RTL 优化或 PPA promotion。
