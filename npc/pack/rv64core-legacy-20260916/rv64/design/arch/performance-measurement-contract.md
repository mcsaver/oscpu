# RV64 性能测量合同

> 当前 revision：`npc-rv64-pmc-v1-v13o-request-detail-20260801`  
> 机器真源：[`performance-measurement-contract-v1.json`](./performance-measurement-contract-v1.json)  
> 状态：测量意图、workload、边界和 v8 守恒 consumer 已冻结；正式 CPI baseline 仍未资格化。

## 1. 测量边界

本合同使用 committed-PC bounded region，不修改 production core RTL、workload 输入、编译参数、
memory/device latency 或结束条件：

- CoreMark 10 iterations：首次提交 `0x800017a8` 到首次提交 `0x800017b0`；
- Dhrystone 10000 runs：首次提交 `0x80000334` 到最终循环后的首次提交 `0x8000047c`；
- 两项各运行三次，cycles、retired 和 counter stack 必须 bit-exact，不删除 outlier；
- GOOD TRAP、CRC/run count 与全程序 exit counter 只验证完成语义，不进入 region CPI；
- baseline/candidate 必须绑定相同 production RTL、elaboration、simulator、workload binary、marker、
  统计方法和观测实现。

机器合同继续保持 `performance_baseline_eligible=false`。当前混合 source closure 不是
production-only 或 elaborated-model identity；typed identity、三次 CoreMark/Dhrystone cohort、
instrumentation-on/off 对照与 qualified STA/power 仍是 GAP。

## 2. 守恒读数

region 读数为：

```text
measured_cycles = end_cycle - start_cycle
retired_instructions = end_retired_before - start_retired_before
slot_capacity = 2 * measured_cycles + end_lane - start_lane
```

同拍提交按 lane0→lane1 排序。唯一 termination-time `FINAL` 绑定最终 hit 数、边界差值与
`termination_rc`；唯一 `COUNTERS_FINAL` 绑定 v4 counter、overflow、invalid event、聚合与守恒。
baseline 只接受 `start_lane == end_lane`，从而要求 `slot_capacity = 2 * cycles`。

v8 consumer 会 fail-closed 地拒绝缺失/重复 marker、非零 termination、phase 漂移、uint64
越界、cycle/slot 不守恒、retired-slot 不等于 region retired、request/memory/head 任一 aggregate
漂移，或 unknown 比例超限。

## 3. 当前 CPI 定位层

`performance-counter-schema-v4.json` 是本 revision 的规范解释器。一级 ROB-head lifecycle
依次包含 dependency、issue-terminal、execution-latency、memory-latency 和
head-lifecycle-unknown。memory-latency 再依据 full-`ProducerId` 反查的 exact owner token、
registered holder mask、双 bridge `state_q` 与 LQ terminal history 拆为：

- reservation/queue；
- translation/store-ordering；
- request-outstanding；
- response/terminal；
- retry；
- memory lifecycle unknown。

request-outstanding 另有一个不扰动一级 reason 编码的守恒子账本：cache lookup、device wait、
AXI read address、AXI read data、AXI write request、AXI write response 与 detail unknown。
cycle/slot 的七项之和必须分别等于 request-outstanding；`memory_latency` 必须等于六个 memory
子桶之和；`head_not_complete` 必须等于五个一级 lifecycle 子桶之和。

`memory_request_detail_unknown + memory_lifecycle_unknown + head_lifecycle_unknown + unknown`
的周期占比不得超过 1%。这些名称表达 edge-old holder-residency/request-phase，不单独证明排他
因果；既有重叠的 fetch/memory/hazard 诊断桶仍不得相加为完整 CPI stack。

## 4. 后续资格缺口

下一步按测得占比继续拆分最重的 holder 或 phase，而不是修改 oracle 迁移计数：

1. **V13N A2 已完成**：当前配置 CoreMark 在 workload 前持久化 simulator executable SHA，
   region PASS 后删除 230,213,569 bytes 专用 build 产物；cycles、retired 和两个兼容聚合与
   V13M bit-exact；
2. **V13O current-config CoreMark 1× 已完成**：仿真器 SHA-256 为
   `ee11d088c5492328927766daa38efa82b4e8948d4e3aa33ec7b84122d78c01a7`；region 为
   `5,395,310 cycles / 3,183,617 retired`，与 V13N 的 cycles、retired、head、memory 和
   request-outstanding aggregate bit-exact，GOOD TRAP=1、DiffTest mismatch=0、RTL assertion=0；
3. request-outstanding 中 AXI write response 为 `690,056/1,111,757`（约 62.06%），AXI write
   request 为 `300,929/1,111,757`（约 27.07%）。下一步先审计 AW/W/B channel、bridge owner、
   SQ terminal/release 与 ROB complete 的逐周期合同；该驻留比例本身不授权在聚合 B 前退休 store；
4. 生成三次 CoreMark 与三次 Dhrystone 的同设计 cohort；
5. 将 reservation/queue 继续分离 backend reservation、MIQ admission 与 bridge station；
6. 拆分 rob-empty 和 issue-terminal，并冻结 integer/FP 的全局 physical issue-slot 合同；
7. 增加 region-bound ROB/IQ/LQ/SQ/MIQ/bridge occupancy histogram；
8. 生成 production-only、elaborated-model 与 host harness 的 typed identity；
9. 完成 instrumentation-on/off 等价 cohort 与同设计综合/STA/power 绑定。

这些缺口关闭前，本合同只授予可审计的 CPI 定位能力，不授予性能 baseline、完整因果 CPI 或
PPA champion 结论。
