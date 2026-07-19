# RV64 v8d integer EX completion kill-cut task report

## 当前状态

`intermediate_checkpoint / scoped GREEN`。本切片关闭当前动态可达的 branch-boundary EX0 +
strictly-younger EX1 在 selective recovery 同沿泄漏 completion 的问题；它不是完整 design-point，
不进入 PPA Pareto/promotion。

## Root cause 基线

现行 `OooIntBackend` 把两个 EX→WB `PipeStageReg.kill_i` 接为常 0，并让 raw `ex0/1_valid_q`
直接进入 WB source、PRF write、BusyTable/IQ wake 与 ROB WB。ROB-walk 虽会清严格年轻 ROB slot，
但 PRF/busy/wakeup 副作用已经在 ROB 入口前发生，故“晚到 WB 由 ROB squash 吞”不是完整恢复合同。

权威冻结见 [contract.md](contract.md)。

## 实现者交付

- `age(x)=x-rob_head_idx` 等宽环形减法、strict `>` 形成逐 lane `exN_kill_now_w`；raw valid
  只表示 stage 占用，effective `exN_wb_valid_w` 才是完成资格。
- 两个 `PipeStageReg.kill_i` 同源清 raw state；WB credit、低优先级 MEM/MulDiv/CLMul/FP
  补位、WB payload、PRF、registered forwarding、BusyTable/INT-IQ/FP-IQ、ROB 与 public
  completion 都读取 effective event。未新增端口、状态机、队列、ready loop 或流水拍。
- 真实无 force 场景固定 branch ROB0 / younger EX1 ROB1：boundary 完成存活，young EX1 的
  WB/PRF/forward/Busy/IQ/ROB/public pulse 全静默，沿后 PRF、Busy 与 ROB data/done 不变。
- 补充矩阵遍历全部 4-bit `head × boundary × completion`，两 lane 共 `8192` checks；forced
  替代源只用于证明被取消 completion 释放 WB0/WB1，不被表述为动态可达性证据。

## 验证证据

- 修复前真实运行（未冻结 source，只作时间点 witness）稳定出现 4 个失败：young EX1 formal
  WB、PRF write、public completion 与 PRF value 均泄漏。可重放的 current-source 机器门以
  11 个 compile-success semantic mutation 代替不可审计的旧源码复原。
- focused release 与 `OOO_ASSERT` 两构建均精确 PASS；`8192/8192` 年龄检查通过；11/11
  变异用例均完成编译/仿真并被定向检查检出，含 raw mask、`>=`、raw-index、全局
  mispredict mask、wrong-owner、替代源占槽、forward/PRF 及 Dispatch/FP-IQ fanout。
- 当前共享源码的 module aggregate：`104/104 PASS`；证据目录同时冻结 140 个 production
  source 与 112 个 testbench source 的 SHA-256 清单。
- `check-rtl-style` PASS；`check-contract` PASS，立即断言 `295 >= 89`。
- full lint 当前仍 RED：115 warnings；归一化 115 行的 SHA-256 为
  `414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b`，与上一轮基线
  byte-identical，说明本切片没有新增 warning，但不能把它写成 lint GREEN。

## 独立反例复核

- 当前控制流只从 lane0 resolve，且既有 coherence assertion 令 EX0 与 boundary identity
  相同，所以“strictly-younger EX0”没有动态可达证据；EX0 对称门是合同完整性和未来拓扑
  漂移防护。真正 root cause witness 是 younger EX1。
- 未证明曾发生错误架构提交；已证明的是 kill-start 沿的 PRF/Busy/wakeup/public pulse 不能由
  ROB walk 原子撤回。ROB 本地 young entry 随后仍可被 walk 清除。
- 现有 RTL 内 `kill_now && wb_valid` 断言与定义同源，非真空性主要由独立 TB oracle 和
  fanout mutation 提供；这条证据边界在报告中保留，不越级称 formal proof。
- 动态 older-EX1 与真实 long-op 补位仍未单独构造；strict survivor 年龄由全矩阵、动态
  boundary EX0 与全局-mask mutation 覆盖，替代源补位是 supplemental forced proof。

## 交付边界

- 本切片只关闭 integer EX0/EX1 completion kill-edge 资格。
- full ProducerId、slot generation/no-live-reuse、所有 carrier authorization、Q1/CSR、双 memory、
  official/AM/Linux、fresh synthesis/STA/power 与 PPA hard gates 保持 RED；不得因本切片
  GREEN 升级父目标。
- 本目录是业务 RTL 证据包，不冒充 canonical agent-e2e publication；AI 环境的可发现/可执行/可审计
  状态由 task-specific profile 与 strict guard 独立签收。
