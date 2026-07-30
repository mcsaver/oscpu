# HIST-SER-QH-YOUNGER-STORE-CYCLE 任务报告

## 状态

`BOUNDED_COMPLETE`

本切片完成本地 RV64 历史缺陷
`HIST-SER-QH-YOUNGER-STORE-CYCLE` 的限域 VD3 回填。整体历史账本、
architecture-stable 与 PPA 分别保持 `GAP / GAP / UNQUALIFIED`；
长期 RV64 OoO/PPA goal 保持 active。

## 对象、周期与配置

- RTL：
  `OooIntBackend.mem_idle_o/mem_retire_quiet_o`
  → `OooRob.head0_csr_mem_hold_w`。
- transaction：
  queue-head CSR 位于 ROB head，younger STORE 已完成地址 probe 并驻留 SQ。
- 周期：
  根窗口 → CSR C0 commit/barrier → C1 flush/owner death → C2 no-repeat。
- 配置：
  `current_owner_guard / historical_fixed / historical_cycle`
  × assertion on/off。
- promotion：
  `false`。本轮没有综合、STA、power 或系统级 promotion。

## 根因与判别

历史中间版本要求 queue-head CSR 同时等待
`mem_idle_o && mem_retire_quiet_o`。`mem_retire_quiet_o` 包含
`sq_empty`，但目标 SQ STORE 年轻于 CSR，只能在 CSR retirement
产生的 flush 后清除，因而形成：

`CSR waits younger SQ empty → younger SQ waits CSR retirement/flush`。

产品当前 owner-lifetime 语义又把 live STORE owner 纳入 `mem_idle_o`，
所以直接用当前产品 RTL 的 backend 注入状态只会得到 `mem_idle=0`。
本轮因此分离三种语义，而不是把 current guard 误报为历史修复进展。

## 产品前端边界

产品 glue TB 直接计 queue-head CSR birth：

- 3 个 committed transaction：
  `birth=1, lane1_fire=0, C0_commit=1, C0_barrier=1,
  CsrFile_request=1, C1_apply=1, C2_quiet=1`。
- 2 个 selectively killed transaction：
  `birth=1, lane1_fire=0, selective_kill=1, C0=0, C1=0`。
- older-store case 保留
  `[V9O-CSR-MEMORY-ORDER-INTEGRATION] older drain/younger refetch PASS`。

因此产品 frontend 会在 queue-head CSR packet 边界抑制 lane1；backend
CSR+younger STORE 双派发只用于历史 root-cone 判别。

## 历史 reconstruction

runner：
`run-historical-reconstruction.py --refresh`。

所有计数器直接统计 acceptance edge，不使用 sticky seen 或重复事件抑制。
每个 case 都观察：

- CSR/STORE dispatch 各 1；
- SQ allocation 1；
- successful probe request/response 各 1；
- exact STORE token/kind/ProducerId owner 1；
- physical non-probe write 0。

结果：

| 语义 | assertions | 编译 | 根窗口/终端 |
| --- | --- | --- | --- |
| current owner guard | on/off | 2/2 success | `root_window=4, C0=0, mem_idle=0`，2/2 PASS |
| historical transport-idle fixed | on/off | 2/2 success | `root_window=1, C0=1, C1=1, C2_quiet=1, physical_write=0`，2/2 PASS |
| historical `mem_idle && mem_retire_quiet` | on/off | 2/2 success | `root_window=4, C0=0, mem_idle=1, mem_retire_quiet=0, hold=1, SQ=1, owner=1`，2/2 被专用 oracle 拒绝 |

cycle case 的 make `driver_rc=2` 来自预期仿真返回值；对应 image
存在且带 SHA，没有 `SETUP-FAIL`、`CHECK-FAIL` 或 `FATAL`，不是编译失败。

Icarus `.vvp` 会把进程分配地址写入内部符号名，相同 elaboration 的 raw
image SHA 因此不稳定。runner v2 把身份拆为：

- 每个 case 的 `compile-image-receipt.json` 保留当次 raw SHA 与字节数；
- ledger-bound summary 对 VVP 内部
  `(?<=[A-Za-z_])0x[0-9a-fA-F]+` 标识符归一化后计算稳定 SHA；
- 2/2 单测证明仅改变内部地址时 normalized SHA 相等，而改变
  `C4` 语义内容时 normalized SHA 不等；
- 两次完整六 case replay 的 `summary.json` 字节完全相同。

独立 replay receipt 为
`evidence/replay-identity-v2/stability.json`，SHA-256
`bc93313525dcc6f89a5a2d387fe5796489b6687f6d7b6757abe76e6995d3107f`；
它记录 normalized image 6/6 稳定、compile/simulation log 6/6 稳定，
同时 raw image 6/6 确实因内部地址变化，从而证明归一化处理的是已观察到的
工具输出差异。

两个历史版本只重建与缺陷相关的根锥：

- fixed 去掉当前 `mem_idle_o` 的 owner-live/terminal-pending 附加项；
- cycle 在 fixed 上恢复历史
  `.mem_quiet_i(mem_idle_o && mem_retire_quiet_o)`。

它们不是完整历史快照。

## 身份与回归证据

- production `OooIntBackend.v` 前后 SHA-256：
  `49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a`。
- 146-file design-id：
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。
- reconstruction summary：
  `a7c15649be90432aa6961671b10e1be06ade4ddef18e8e06846fb6f3cd7b9fa0`。
- 产品 frontdoor log：
  `1ac4a715d1d18d91e11fa4d1ef2589e0291b4f7bea4a00d2ff24dd41f2c0228a`；
  同一 canonical build path 重放后字节相同。
- `tb_ooo_int_backend` module regression：
  `[RESULT] PASS`，
  log SHA-256
  `afba2d8cbd4f7c52ed86a75a5fea95087c6f6643497325653eaa0bd0004bc78c`；
  同一 canonical build path 重放后字节相同。
- ledger audit：
  `valid=true, errors=[]`；深度为
  `VD0=0, VD1=1, VD2=0, VD3=2, VD4=2`。
- ledger 定向单测：
  4/4 `OK`，覆盖错误 selected entry、artifact hash drift 与 VD0/VD1
  清零状态。

## 实现者复核

- 修改只在 testbench、runner、ledger 与证据/记录层；production
  `OooIntBackend.v` 未改。
- 产品前端可达性与 backend root-cone 实验分别记录，没有合并为伪端到端波形。
- 负向版本均编译成功并到达专用根窗口；assertion-on/off 结果一致。
- C0/C1/C2 与 physical write 使用原始计数，没有添加事件去重或削弱断言。
- 证据身份在一次真实 hash-drift 触发后保持 fail-closed；修订的是 VVP
  elaboration receipt 规范，不是测试判据或 RTL 语义。
- A3 原始 FAIL、16/17 与 rc=1 保持不变；本轮没有改写 A3 证据。

## 独立审查者复核

final reviewer v3 对 RTL 语义给出：

`APPROVED_FOR_BOUNDED_VD3`。

evidence identity 修订后，隔离 final reviewer v4 再次给出：

`APPROVED_FOR_BOUNDED_VD3`。

v4 明确确认 normalized SHA 没有替代 RTL source、compile/simulation
log、专用 oracle 或最终 raw image receipt。两轮审查共同批准该单项由
VD1 提升到限域 VD3，同时保留：

- backend C1 是 TB 外部注入，产品 typed C1 由 glue scoreboard 独立覆盖；
- reconstruction 不是完整历史快照；
- `diagnostic-t3u` 是旧 admission 预期失败，不能作为绿色证据；
- 4 拍负向观测不是无限期形式化活性证明；
- `OooRob.v` 有一处非阻塞旧注释债务；
- normalizer 2 个单测是代表性敏感性证明，不是对未来所有 VVP 语法的
  形式完备证明；第一次 replay 的 raw digest 未单独持久化；
- `HIST-SER-QH-STOP-HOLD-DROP` 仍为 VD1。

最终合同 SHA-256：
`b10cb173f390f7ae84f5dc6d4801aa7d2ddf2cad6a100f32c0a946654ffd5435`。

## A3 重跑边界

本轮不要求完整 A3 重跑，因为：

- production core RTL 语义未变化；
- 当前配置实际 elaborated RTL 未变化；
- device model / simulator 执行语义未变化；
- A3 原始输入、终端链和 post-hash 证据没有缺失。

A3 继续定义为“系统事务完成、旧 oracle 误判”，原始 FAIL 不变。

## 剩余项与下一动作

当前唯一 VD0/VD1 blocker 为
`HIST-SER-QH-STOP-HOLD-DROP=VD1`，已被 ledger 选为下一项。下一轮应：

1. 在产品 glue 路径形成 head0 CSR inflight 与 younger lane1 CSR overlap；
2. 用 assertion-on/off 原始计数覆盖 C0/C1/C2 owner/stop；
3. 构造删除 `head0_csr_inflight` hold 的可编译
   `OooStopPendingSequencer` 负向版本并要求定向拒绝。

## 工作流闭环

- bounded brief：
  查询词 `rv64 historical defect backfill loop` 在
  `--profile npc-dev --focus-scope non-history` 下 `ok=true`，独立命中
  `.github/agentic-hardware-blueprint.md` 的
  `rv64-historical-defect-backfill-loop`，不是依赖历史 task-run 自我召回。
- evidence index：
  `github_index_db.py index-evidence --write-index` 已登记本 task-run 的
  source diff、raw receipt、日志、返回码、summary 与审查合同；旧
  `historical-ledger-tests.log` 和 `diagnostic-t3u` 保留为失败诊断，
  current 结论只引用 v3 ledger evidence 与 final reconstruction。
- task-specific e2e：
  `.github/task-runs/2026-07-29-rv64-historical-defect-backfill-loop/`
  为 `npc-dev` completed，5/5 节点 PASS；task-report SHA-256
  `46a0598ca2603ffbe18bc8698d3a4343e3811c2a5d2d769b10ffb1929dd71c64`。
- scoped strict guard：
  对 `guard-paths.txt` 的 17 个本轮 source/memory/task-run 路径只要求
  `npc-dev`，绑定上述 completed run 后 PASS；日志 SHA-256
  `6dcea821d97677c7de7bc4d749d478fcdf008313377ebd3913c661216b82f2b2`。
- DB-first：
  本轮 `project-status.md`、`modules/npc.md` 及相邻 V10G 五份 live
  文档已写入 retained store；当前没有 missing/mismatch。全局 audit
  仍以 rc=1 报告 183 个 2026-06/07 历史 task-run live-content drift，
  路径不含本轮 memory 或 task-run；该 mixed-history 状态按范围豁免保留，
  不写成 PASS，也不反向否定本轮 RTL/e2e 证据。

## Git 边界

当前分支 `ai`、HEAD
`af027d1bce085bace474b748dcd89113145f8772`。工作树在本轮前已包含
大量 mixed-origin tracked/untracked 文件，并有不属于本切片的 staged
profile 文件；无法证明原子提交边界，因此本轮不 commit、不 push，也不执行
reset/restore/clean/stash。
