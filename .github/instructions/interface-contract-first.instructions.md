---
description: "RV64 跨模块接口与控制语义指南。触碰 handshake、stall、flush/redirect/trap、异常/访存序或投机恢复时，用现有 spec、调用链、波形和定向检查理解 transaction ownership；不把表格、阶段或断言数量变成 RTL 编辑权限。"
applyTo: "npc/rv64/**/*.{v,sv,vh,svh}"
---

# RV64 Interface and Control Semantics

本指南与 `rtl-generation-workflow.instructions.md` 配合使用。它提醒 agent 在跨模块控制边界上先理解语义，
但不是“阶段 0”、permission gate 或强制文档流程。局部且可逆的 RTL/TB 探针可以帮助定位语义；是否先写
spec、表格、断言或小型实验由当前不确定性与 acceptance criteria 决定。

## 何时需要扩展上下游阅读

出现以下任一情形时，通常需要读取 producer、consumer、相关 spec/filelist/TB，并说明 transaction
lifecycle：

- valid/ready、backpressure 或 payload hold；
- stall、pipeline freeze、multi-cycle in-flight work；
- flush、redirect、trap、xRET、branch recovery；
- precise exception、retirement 或 serialize；
- load/store ordering、forward/replay、cache side effect；
- owner/tag/checkpoint、ROB/LSQ/SQ/MIQ 生命周期；
- 新 module/port，或有效周期、组合/寄存语义发生变化。

纯块内组合逻辑、数值修正或解码表若不影响这些边界，可以直接按其局部 contract 修改。文件数量和模块
数量本身不触发额外流程。

如果一开始还不能解释某个信号，先查 driver、consumer、波形或已有 test；也可以构造可逆的最小 RTL/TB
探针来区分假设。不要用填写表格代替理解，也不要因 spec 尚未更新就把安全本地调查变成禁止编辑。

## 需要回答的工程问题

按相关性选择，不要求把六类全部写成固定模板。

### Handshake 与 backpressure

- transaction 在哪一拍被接受，fire 条件是什么；
- valid 等待 ready 时 payload 是否必须保持；
- producer/consumer 谁持有 pending state；
- ready/valid 是否形成组合环；
- 多 lane 或多 uop 是独立接受还是原子接受。

### Stall 与在飞工作

- stall 的真实来源和传播方向；
- 哪些 pipeline state 冻结，哪些 multi-cycle/AXI transaction 必须继续推进；
- response、kill、retry 与 backpressure 同拍时谁优先；
- 是否存在 ownership 丢失、重复 fire 或 payload 被新请求覆盖。

### Flush、redirect 与 trap

- 每个源清除哪些年轻状态、保留哪些已提交或不可撤销状态；
- 多个源同拍时的实际优先级；
- 已接受的外部 transaction 是取消、抑制 response，还是 drain 后丢弃；
- redirect/trap 的 PC、cause、tval 与 owner/tag 在哪一拍锁定。

当前 OoO 设计通常应保持以下不变量，但修改前仍要核对生产 RTL/spec：

- committed store 不被 younger flush 撤销；
- 已接受且接口不支持 cancel 的 AXI transaction 必须安全 drain；
- commit 拍已经架构可见的 CSR/retirement effect 不被后续 flush 回滚；
- precise exception 只提交允许提交的 older state，并 squash younger state。

### Exception、retirement 与 memory ordering

- 双提交或多 lane 的全序与异常优先级；
- serialize 指令的进入、等待和完成条件；
- load 对 older store 的 address/data/strb 可见条件以及 forward、block 或 replay 策略；
- store 何时成为 committed side effect，何时更新或失效 cache；
- fault、replay、kill、response 同拍是否可能重复完成或漏完成。

### Speculation 与单一事实源

对 domain、member set、prediction metadata、owner/tag 或 next-PC，确认哪个 state 是 authoritative，哪些只是
投影或缓存。重复副本需要有明确更新/失效规则；不要让格式化 handoff 或 debug facts 反过来成为生产语义。

## 如何记录 contract

选择最靠近消费者、最容易维护的形式：

- 已有 spec 中的一段 prose、时序表或优先级表；
- RTL 中清楚的组合/时序结构与必要注释；
- module TB、directed regression 或 reference/DiffTest oracle；
- 立即断言或旁挂 debug checker；
- 最终报告中的局限和仍未确认项。

两端并行实现或语义复杂时，§2/§3 表格很有价值；局部修复不强制补齐整份模板。RTL 暴露出新事实时，
同步更新真正会误导 consumer 的 spec/断言即可，不要求先创建 task-run、review record 或 memory 条目。

## Assertion 与 checker 选择

当前 module TB 常用 iverilog，全核主要用 Verilator；并发 SVA 支持并不统一。需要跨两套工具复用时，优先
使用时钟块里的立即断言：

```systemverilog
always @(posedge clk) begin
  if (assertion_enable && violation) $error("contract violation");
end
```

只有 acceptance criterion 需要 assertion 生效时才确认 Verilator 使用 `--assert`。断言必须表达独立
不变量，避免逐字重述 RTL。真空风险存在时，用覆盖计数、定向激励或一个能够区分实现的 negative case
证明前件可达；不要求为每条断言机械制造 mutation。

### 可选外部观测层

当跨模块状态难以观测且不应污染可综合 RTL 时，可以使用：

- `vsrc/debug/*.sv`：SIM_TOP 旁挂 checker/投影，不进入 `RTL_CORE_SRCS`；
- `vsrc/common/*.vh`：稳定的抽象 facts/位定义；
- `NpcSimTop.sv`：在 `OOO_ASSERT` 等仿真条件下例化并连接所需信号。

这是 observability 方案，不是所有 RTL 修改的必经层。组合仲裁可当拍检查；寄存输出要把条件和期望值与
目标拍对齐；跨仲裁器一致性要比较同一 transaction/cycle。

已知工具注意点：

- 空 output 连接可能触发 Verilator `PINCONNECTEMPTY`；内部 named sink 通常更稳；
- `$error` 在启用 assert 的 Verilator 下可能终止，非真空采样可用计数或 `$display`；
- XMR 路径必须跟随真实实例层级，修改 hierarchy 后重新确认；
- 某些 harness 的 `$time` 不推进，精确周期使用显式 counter；
- checker stdout 是否被 runner 捕获要由实际命令验证，不能只假设日志链存在；
- 时序仲裁的 reg 是下一拍结果，不能拿同拍旧值做错误比较；
- 先追 driver/consumer，避免把名称相似但阶段不同的 trap/fault 信号混用。

## 验证选择

根据改动支持的 claim 选择最小组合：

- module-local：相关 lint/elaboration + directed TB 或 assertion；
- 跨 pipeline：相邻模块 TB、全核 smoke、DiffTest slice 或波形；
- memory/exception：能触发相关 ordering/fault/replay/flush 交互的 case；
- system-visible：对应 OpenSBI/Linux/device workload；
- PPA：匹配 filelist/config/corner/workload 的 mapped/STA/PPA 证据。

固定输入和确定 oracle 默认一次。只有随机、并发、flaky、未固定 seed/thread、测量噪声、机器异常或矛盾
结果时重复。版本控制内未修改且没有异常迹象的 checker/runner 默认可信；不要先做全套 checker 自证再跑
真实 RTL。

## 结果边界

最终说明受影响 module/signal/transaction、关键周期/优先级、执行的 TB/仿真/EDA 观测、PASS/GAP 和未运行
范围。以下仍不可越级：

- lint/elaboration 不证明动态协议；
- module TB 不证明全核或 Linux；
- NEMU reference 不证明 NPC target；
- debug checker 不参与综合，不能证明 mapped timing/area；
- focused case 不证明未运行的 flush/ordering/config 矩阵；
- task contract、hash、profile 或 AI policy PASS 不证明 RTL correctness。

若 current spec 与生产 RTL/test 的语义确实矛盾，把它作为工程缺口处理并修正最接近事实源的一侧；不要以
“先契约”或“先 RTL”的口号替代对可观察行为的判断。
