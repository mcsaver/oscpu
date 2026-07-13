# 规范：backend drain 的 ROB-empty / retire-count 冗余消除

> 模块：`OooRob`、`OooAluCoreSlice`、`OooPendingDrainResolveGate`、
> `OooControlPlane`。模板见 `../arch/SPEC-TEMPLATE.md`。
> 状态：T3I 已实现并完成 full regression、CoreMark、fresh synthesis 与
> exact-5 ns OpenSTA；功能/周期等价成立，但 WNS `-9.38 ns`，200 MHz 尚未闭合。

## 1. 目的与范围

T3H fresh 5 ns STA（loops=0、WNS `-10.10 ns`、TNS `-201564.20 ns`，top1
`-10.097 ns`）的 top40 共 40 条路径都从 `ex0_valid_q` 起，经 ROB 的同拍
writeback-done bypass 形成 commit valid。`OooAluCoreSlice` 把两个 commit valid 相加为
`core_retire_count`，`OooPendingDrainResolveGate` 又把这个计数与 ROB-empty 重复 AND 进
`backend_drained`，从而把 execute/writeback/commit 锥无谓接入 drain、redirect、fetch 和
CSR 控制长链。

本切片只消除这个**可达状态域上的冗余条件**：

```text
commit0_valid = commit0_fire，且 commit0_fire -> count_q != 0
commit1_valid = commit1_fire，且 commit1_fire -> commit0_fire
rob_count     = count_q
retire_count  = commit0_valid + commit1_valid

因此：rob_count == 0 -> retire_count == 0
```

`backend_drained` 仍必须同时满足 ROB empty、integer issue queue empty、synthetic lane1
ret/drop 均清空以及退休侧内存静默。切片不改变 ROB 退休、pending 状态机、redirect 仲裁、
CSR/异常顺序、SQ/AXI owner，也不新增流水寄存器或 false path。

边界如下：

- `OooRob` 是 ROB occupancy 与两个 commit valid 的单一真源；
  `OooAluCoreSlice` 只派生并保留 `retire_count_o` 给正常 commit/debug 消费者。
- `OooPendingDrainResolveGate` 是无状态组合判据汇合点，只判断“本拍是否排空/可 resolve”，
  不拥有任何 pending、stop、ROB、IQ、SQ 或 redirect 状态。
- `OooControlPlane` 只作结构接线与事件消费；删除的 retire-count 端口不得以别名或 zombie ABI
  回流 drain 域。
- 200 MHz 的裁决目标是 current-source、fresh netlist、5.000 ns 约束下 WNS `>= 0`；
  本切片本身不承诺单刀闭合该目标。

## 2. 接口契约

### 2.1 端口、时序与 owner

`OooPendingDrainResolveGate` 没有 `clk`/`rst`，全部输出都是输入在**同一组合拍**的函数；
“复位值”由具名 producer 的寄存器决定，gate 自身没有可清状态。表中“源复位”只描述 owner
复位后的可见值，不把状态所有权甩给 wrapper。

| 端口 | 方向/宽度 | 组合时序与源复位 | 语义与决定状态的 owner |
| --- | --- | --- | --- |
| `rob_count_i` | in / `ROB_COUNT_W` | 组合读取；源复位为 0 | `OooRob.count_q/count_o` 是唯一 occupancy owner；经过 execute wrappers 原样透传 |
| `issue_count_i` | in / `ISSUE_COUNT_W` | 组合读取；源复位为 0 | `OooIntIssueQueue.count_q/count_o` 是 integer IQ occupancy owner |
| `synth_lane1_ret_pending_i` | in / 1 | 组合读取；源复位为 0 | synthetic lane1 retire owner；当前由 `OooCoreTopGlue` 常量 0 封死已退休路径 |
| `synth_lane1_branch_drop_pending_i` | in / 1 | 组合读取；源复位为 0 | synthetic lane1 branch-drop owner；当前由 `OooCoreTopGlue` 常量 0 封死已退休路径 |
| `mem_retire_quiet_i` | in / 1 | 组合读取；由 SQ/drain 状态派生 | `OooIntBackend` 按 `!sq_mode || (sq_empty && !drain_inflight)` 唯一判定已退休 store 是否排空 |
| `direct_frontend_flush_i` | in / 1 | 当拍控制脉冲 | `OooFrontendActionGate` 产生；只在本 gate 中否决 stale pending-branch resolve/clear，不清本 gate 状态 |
| `stop_pending_i` | in / 1 | 组合读取；源复位为 0 | `OooStopPendingSequencer.stop_pending_o` 持有 stop 生命周期 |
| `backend_drained_q_i` | in / 1 | 组合读取上一沿结果；tracker 复位/force 后为 1 | `OooBackendDrainTracker.drained_q` 持有经一拍确认的 drained 历史；它不替代本拍 raw predicate |
| `pending_control_ready_i` | in / 1 | 当拍 ready；当前 frontend tie 1 | `OooFrontend` 控制消费端决定能否接受 drain completion |
| `dispatch0_ready_i` | in / 1 | 当拍 ready | `OooDispatchBackend` 汇合 ROB/IQ/free-list/SQ 容量与 recover freeze，`OooIntBackend` 再合 FP 资源；二者共同决定 lane0 fire，本 gate 不反向产生 ready |
| `branch_resolve_pending_match_i` | in / 1 | 当拍比较结果 | `OooBranchResolveRecoveryGate` 产生当前 resolve 是否命中 pending branch |
| `branch_spec_active_i` | in / 1 | 组合读取；源复位为 0 | `OooBranchSpecTracker.active_q` 是 speculation active 单一真源 |
| `branch_spec_checkpoint_pending_i` | in / 1 | 组合读取；源复位为 0 | `OooBranchSpecTracker.checkpoint_pending_q` 是 checkpoint pending 单一真源 |
| `pending_arch_trap_i` | in / 1 | 组合读取；源复位为 0 | `OooPendingTrapExitSequencer.pending_arch_trap_o` 持有待提交精确异常 |
| `pending_branch_i`, `pending_branch_dispatched_i` | in / 各 1 | 组合读取；源复位为 0 | pending-branch owner 属 frontend pending 域；当前 ROB-walk 模式下相应 sequencer 已删除并 tie 0 |
| `pending_jump_i`, `pending_jump_dispatched_i` | in / 各 1 | 组合读取；源复位为 0 | pending-jump owner 属 frontend pending 域；当前 ROB-walk 模式下相应状态 tie 0 |
| `pending_jump_resolve_ready_i`, `pending_jump_nolink_i`, `pending_jump_misaligned_i` | in / 各 1 | 当拍组合事实 | `OooFrontend` jump resolve/target 域产生；当前删除路径均 tie 0 |
| `pending_system_i`, `pending_system_csr_i`, `pending_system_dispatched_i` | in / 各 1 | 组合读取；源复位为 0 | `OooPendingSystemSequencer` 持有 SYSTEM/CSR valid、类型和 dispatched 生命周期 |
| `backend_drained_o` | out / 1 | 当拍组合，无独立复位值 | gate 拥有 raw drain 判据；`OooBackendDrainTracker`、flush sequencer 和 system refresh 消费 |
| `jump_dispatch_valid_o` | out / 1 | 当拍组合 valid；不得依赖 backend `dispatch0_ready_i` | gate 拥有 jump dispatch 资格；`OooFrontendBackendDispatchMux` 另算 `valid&&dispatch0_ready` 的 fire，jump payload/持有状态仍由 frontend pending-jump owner 负责 |
| `system_csr_dispatch_valid_o` | out / 1 | 当拍组合 valid；不得依赖 `dispatch0_ready_i` | gate 拥有 CSR 注入 valid；持久性由 `OooPendingSystemSequencer` 的 pending/dispatched 状态保证 |
| `system_csr_dispatch_fire_o` | out / 1 | `valid && dispatch0_ready_i` 的当拍 fire | dispatch consumer 与 `OooPendingSystemSequencer` 在上升沿记账 dispatched |
| `pending_branch_commit_resolve_o` | out / 1 | 当拍组合事件 | gate 拥有“排空后无 match 的 pending branch 提交式 resolve”资格；BranchSpec/Stop/TrapExit consumers 清状态 |
| `pending_branch_match_clear_o` | out / 1 | 当拍组合事件 | gate 拥有“已 match 的 pending branch clear”资格；与上一事件由 match 极性构造互斥 |
| `pending_replay_wait_o` | out / 1 | 当拍组合状态摘要 | gate 汇总尚未 resolve/dispatch 的 pending 控制；不拥有被摘要的状态 |
| `drain_complete_o` | out / 1 | 当拍组合 completion 事件 | gate 在 stop、raw drained、consumer-ready 且无需 replay 时宣告完成；各 sequencer 在沿上消费 |

### 2.2 组合方程与握手边界

令 `R0=(rob_count_i==0)`、`I0=(issue_count_i==0)`、`SR0=!synth_lane1_ret_pending_i`、
`SD0=!synth_lane1_branch_drop_pending_i`、`MQ=mem_retire_quiet_i`，则：

```text
backend_drained = R0 && I0 && SR0 && SD0 && MQ

jump_dispatch_valid = jump_resolve_ready && !jump_nolink && !jump_misaligned

system_csr_dispatch_valid = stop_pending && pending_system && pending_system_csr
                          && !pending_system_dispatched && backend_drained_q
system_csr_dispatch_fire  = system_csr_dispatch_valid && dispatch0_ready

branch_commit_resolve = !direct_frontend_flush && stop_pending && backend_drained
                      && pending_branch && pending_branch_dispatched
                      && !branch_resolve_pending_match
                      && !branch_spec_active && !branch_spec_checkpoint_pending
                      && !pending_jump && !pending_arch_trap && !pending_system

branch_match_clear = !direct_frontend_flush && stop_pending
                   && pending_branch && pending_branch_dispatched
                   && branch_resolve_pending_match && !branch_spec_active

branch_resolve_wait = pending_branch && pending_branch_dispatched
                    && !branch_resolve_pending_match && !branch_commit_resolve
replay_wait = branch_resolve_wait
           || (pending_jump && !pending_jump_dispatched)
           || (pending_system && pending_system_csr)

drain_complete = stop_pending && backend_drained && pending_control_ready
               && !replay_wait
```

向 backend 注入的 ready-valid 边界有 jump 与 SYSTEM/CSR 两条：两种 valid 都禁止组合依赖
backend `dispatch0_ready`，ready 只参与各自 fire；payload 分别由 frontend pending-jump owner 与
`OooPendingSystemSequencer` 持有，valid stall 期间不得被覆写。这里名为
`pending_jump_resolve_ready` 的输入是 producer-side resolve 资格，不是 backend 的同级 ready。
其它输出是 predicate/event，不是可任意撤回的 payload channel；需要跨拍保持时，由表中具名
owner 的寄存器保持。当前 ROB-walk 配置把 legacy pending-jump 路径 tie 0，但接口约束仍不得放松。

典型 CSR 注入时序：

```text
cycle N      raw backend_drained=1
edge N       OooBackendDrainTracker: backend_drained_q <= 1
cycle N+1    system_csr_dispatch_valid=1, dispatch0_ready=0, pending payload 保持
cycle N+2    system_csr_dispatch_valid=1, dispatch0_ready=1, fire=1
edge N+2     OooPendingSystemSequencer: dispatched_q <= 1
cycle N+3    valid=0；后继 commit/redirect 由各自 owner 继续处理
```

### 2.3 六类跨模块契约逐项冻结

| 类别 | 本切片冻结的可判定契约 | T3I 的保持方式/牙齿 |
| --- | --- | --- |
| ① 握手协议 | jump 与 SYSTEM/CSR valid 在 fire 前不得因 backend ready 单独变化而撤回；payload 整拍冻结；`valid` 不依赖同级 `ready`，`fire=valid&&ready` | 两 valid 都不读 `dispatch0_ready`；ready 只进入各自 fire。持久性分别由 frontend pending-jump owner 与 `OooPendingSystemSequencer` 保证 |
| ② 反压/stall | `OooDispatchBackend` 从 ROB/IQ/free-list/SQ 容量构成单向 resource DAG，`OooIntBackend` 再合 FP 可用性；本 gate 只消费 `dispatch0_ready_i`，不得把 `fire`/`drain_complete` 回灌成 ready；stop 表示冻结新控制推进，不回退已进多周期 FU 或已发事务 | gate 无寄存器、无 ready 输出；删除 retire 输入不会新增组合环或改变 stall DAG |
| ③ flush/redirect | trap/exit > CSR/xRET > branch mispredict > BPU/RAS > 顺序 PC；`direct_frontend_flush` 当拍否决 stale pending-branch 两事件；committed store、已发 AXI、commit 拍 CSR 写均不可撤销 | §3.3 给出逐源清/保持表和同拍全序；gate 本身无状态可清 |
| ④ 异常序 | 精确异常只在最老边界处理；`pending_arch_trap` 必须压住 pending branch commit-resolve；双退休恒 `commit0` 先于 `commit1`，且 `commit1 -> commit0` | branch 方程显式含 `!pending_arch_trap`；ROB 定理前提与 §3.2 最后退休边界保证 drain 不提前 |
| ⑤ 访存序 | ROB empty 不代表退休 store 已落存；只有 `mem_retire_quiet=1` 才可 drain。flush 不清 committed SQ entry，不 kill 已发 AXI，只能等待 drain | `mem_retire_quiet_i` 保留为不可删除安全项；retire-count 删除不触碰 SQ/AXI owner |
| ⑥ 投机恢复/单一真源 | ROB occupancy 只认 `OooRob.count_q`；IQ occupancy 只认 IQ `count_q`；branch speculation、pending SYSTEM、SQ drain 各认自己的具名 owner；gate 禁止镜像/缓存这些成员关系 | gate 纯组合；`core_retire_count` 仍可供 commit/debug 使用，但不再作为 ROB-empty 的第二份 drain 成员关系 |

## 3. 状态与时序模型

### 3.1 无状态周期模型

本模块不是 FSM，不能为了画状态图虚构跨拍状态。其完整周期模型是：

```text
上升沿 k 后：ROB/IQ/SQ/pending/stop/spec owners 输出 Q(k)
                           |
                           v
同一 cycle k：OooPendingDrainResolveGate 计算 §2.2 全部组合谓词
                           |
                           v
上升沿 k+1：BackendDrainTracker / PendingSystem / StopPending /
             BranchSpec 等具名 consumer 按各自优先级吸收事件
```

gate 的寄存器清单为空；没有 reset value、hold 条件或内部同拍竞争。`backend_drained_q_i`
是 `OooBackendDrainTracker` 拥有的一拍历史：其更新为
`rst || force_drained ? 1 : backend_drained_o && !dispatch_fire`。raw `backend_drained_o`
与 registered `backend_drained_q_i` 语义不同，不得互相替换。

### 3.2 最后一项退休的前沿/后沿

冗余删除必须以时钟沿两侧的真实组合值判断，而不是把“这一拍退休后会空”误当成沿前已空。
设其它 drain 条件均为 1，且同拍无新 dispatch：

| 情形 | 沿前 `count_q` | 沿前 commit/retire | 沿前 old/new drained | 上升沿动作 | 沿后稳定值 |
| --- | ---: | --- | --- | --- | --- |
| 单项最后退休 | 1 | `c0=1,c1=0,retire=1` | 都为 0（ROB 非空） | `count_q<=0` | `count=0,c0=0,c1=0,retire=0`，两式才可为 1 |
| 两项同拍最后退休 | 2 | `c0=1,c1=1,retire=2` | 都为 0（ROB 非空） | `count_q<=0` | `count=0,c0=0,c1=0,retire=0`，两式才可为 1 |
| 退休并同拍 dispatch | 1 或 2 | 合法 commit | 都为 0 | `count'=count+dispatch-commit` | 只要新项进入，`count'!=0`，仍不 drain |
| ROB recover/kill | 非零 | `recovering` 抑制 commit | 都为 0 | owner walk/kill younger | 只有 owner 真正把 count 更新为 0 后，组合 retire 才为 0 |
| reset/flush 清 ROB | 任意合法值 | 沿前若 count 非零也不会令 drain 为 1 | 都为 0 | owner 最高优先清 count/valid | 沿后 `count=0` 且 commit valids=0；其它 quiet 项仍独立决定 drain |

因此删除 `retire_count==0` 既不会在最后退休的沿前提前宣告 drain，也不会在沿后额外延迟一拍。
如果最后退休同时接收新 dispatch，post-edge ROB 仍非空，ROB-count 条件继续阻止 drain。

### 3.3 flush/redirect“谁清谁保持”表

下表约束的是相关 owner；gate 自身没有状态可被任何 flush 清除。`rst` 是共同复位，可清总线
owner；表内其它 flush/redirect 都是功能事件，不得冒充总线 reset。

| 源（高到低见下节） | 清什么（由谁清） | 必须保持/排空什么 | 本 gate 当拍语义 |
| --- | --- | --- | --- |
| `rst` | ROB/IQ/pending/spec/stop/tracker 等 owner 回各自 reset；共同总线 reset 可清 transaction owner | 无架构功能事件可在 reset 拍提交 | 无独立 reset；只反映复位后 producer 值 |
| trap/exit | pending trap/exit、年轻 ROB/IQ/rename/spec 状态按 trap owner 清/恢复；前端转 trap target | 已 commit 架构状态；committed SQ entry；未处于共同 reset 的已发 AXI 必须 drain | `pending_arch_trap=1` 压住 branch commit-resolve；raw drain 仍等 ROB/IQ/SQ quiet |
| CSR/xRET/serialize redirect | serial owner 清 younger speculative frontend/backend 状态并重定向架构 next PC | CSR 写在 commit 沿即架构可见、不得撤回；older/committed store 与已发 AXI 保持至完成 | SYSTEM/CSR 先经 registered drained + ready fire；本 gate 不写 CSR、不清 AXI |
| branch mispredict / ROB-walk | ROB/IQ/rename/free-list owners 只清分支之后的 younger suffix；branch spec owner 清 checkpoint/active | 分支及更老项、committed store、已发 AXI；walk 期间 occupancy 由 ROB/IQ owner 单调修正 | direct flush 否决 stale pending-branch resolve/clear；等待 owner 的新 count 再判 drain |
| BPU/RAS 预测重定向 | frontend owner 更新 speculative PC/RAS；必要时作废未接受的 fetch 语义 | ROB/IQ/已提交状态、committed SQ、已发 AXI | 不直接改变 raw drain；不能越过更高优先级 trap/CSR/branch resolve |
| SQ/LSQ speculative flush | SQ owner 仅清 younger、未 commit 的 speculative entry | committed SQ entry、已发 store/AXI transaction 必须保留并 drain；`mem_retire_quiet` 在此之前保持 0 | 即使 ROB 已空，`mem_retire_quiet=0` 仍阻止 drain |
| 顺序推进 | 各 owner 按正常 fire 更新 | 所有未 fire 的 valid/payload/state 保持 | 按 §2.2 组合求值 |

三条不可降级的铁律：committed store 不得清；已发 AXI 不得 kill；CSR 写在 commit 拍即架构
可见且后续 flush 不得撤销。

### 3.4 同拍优先级

全局架构优先级（高到低）固定为：

```text
rst > trap/exit > CSR/xRET > branch mispredict/ROB-walk
    > BPU/RAS prediction redirect > sequential PC
```

`rst` 之外的功能 flush 都受上节三条铁律约束。gate 不实现完整 redirect mux，只执行以下
局部、可判定的优先关系：

1. `direct_frontend_flush_i=1` 无条件把两个 pending-branch 事件压为 0。
2. 对无 direct flush 的 pending branch，`branch_resolve_pending_match=1` 只可能走
   `match_clear`；为 0 时才可能走 `commit_resolve`，二者构造性互斥。
3. trap、pending jump、pending SYSTEM、active speculation 或 checkpoint pending 都比
   pending-branch commit-resolve 优先。
4. `branch_commit_resolve` 当拍成立时，`branch_resolve_wait` 因其反条件为 0；resolve 胜过 wait。
5. 任一 `replay_wait=1` 都压住 `drain_complete`；consumer-ready 只在所有 wait 清零后授权完成。
6. SYSTEM/CSR 的 ready 只决定 `fire`；即使同拍 fire，pending SYSTEM 状态要到沿后更新，
   本拍 `replay_wait` 仍为 1，故不会同时错误宣告 `drain_complete`。

## 4. 不变量（Invariants）

1. **ROB-empty 蕴含零退休。** `commit0_fire` 明含 `count_q!=0`，`commit1_fire` 明含
   `commit0_fire`，两个 commit valid 分别等于 fire，`count_o=count_q`，而 retire count 是
   两 valid 之和。因此 `rob_count==0 -> retire_count==0`。`OooAluCoreSlice` 中
   `[CORE-RETIRE-REQUIRES-ROB]` 立即断言在精确空 ROB 且 retire 非零时 fail closed。
2. **drain 安全项不回退。** `backend_drained` 必须精确包含 ROB zero、IQ zero、synthetic
   retire clear、synthetic branch-drop clear 与 memory-retire quiet；结构检查逐项 ratchet。
3. **retire-count 不得回流 drain ABI。** `OooPendingDrainResolveGate` 不得出现
   `core_retire_count_i`，`OooControlPlane` 不得出现其接线别名；否则会重新接回关键路径并产生
   两份成员关系真源。
4. **分支 resolve/clear 互斥。** 两者分别要求 match 为 0/1，且都受 direct flush 与 active
   speculation gate；同一 0/1 合法拍不能同时为 1。
5. **无 ready-valid 组合环。** jump/CSR 两种 dispatch valid 都不依赖 backend
   `dispatch0_ready`，本 gate 没有 ready 输出；ready 只进入各自 fire，故不能形成 valid↔ready 环。
6. **ROB-empty 不替代 memory quiet。** 已退休 store 可继续留在 SQ，所以 `mem_retire_quiet`
   是独立必要项；这也是 committed store/已发 AXI 不被 flush 丢弃的可见 backstop。

断言采用 `` `ifdef OOO_ASSERT `` 下的时钟块立即 `$error`，不用工具链不支持的 SVA 时序
算子。negative TB 必须强制一次空 ROB/非零 retire 的不可能 tuple，并精确命中 marker，防止
断言真空通过。断言守的是集成合法域；任意孤立端口的非法/X tuple 不属于行为等价声明。

## 5. 关键路径与时序考量

删除前的主路径族为：

```text
integer EX valid/writeback-done bypass
 -> OooRob commit0/1 valid
 -> OooAluCoreSlice retire_count adder
 -> OooPendingDrainResolveGate backend_drained AND
 -> pending trap/exit / redirect / fetch / CSR control
```

T3I 从 drain gate 和 `OooControlPlane` 物理删除 retire-count 端口与条件，使这个 adder/commit
锥不再成为 drain 的输入。该改动不插拍，因此预期所有功能 workload cycle-exact；这一点仍须
用 CoreMark 及全回归实测，不能由 RTL 观感代替。

独立 diagnostic pin-blocking projection 预计回收约 `0.72 ns`（投影 top
`-9.377 ns`）。current-source fresh 结果与该投影吻合：110 个模块在冻结输入下完成综合，
网表 SHA256 为 `91badd2b...f6926`、面积 `1572549.16`；正确 H7CL 标准库与四个 macro
liberty 下，5.000 ns OpenSTA 为 loops=0、top40=40、最差报告路径 `-9.377 ns`、
WNS `-9.38 ns`、TNS `-199464.16 ns`。top40 中 retire/drain token 均为 0，端点转为
1 条 fetch payload SRAM 与 39 条 pending-trap D；旧 T3H canonical-retire fanout 对
fetch/trap 的命中为 1/137，fresh T3I 为 0/0，而 ROB→fetch/trap residual path 仍存在，
所以不是空 collection 的真空绿。

因此本刀的结构目标与预期收益已兑现，但 200 MHz 明确未闭合。后续必须继续切断当前
integer EX→fetch SRAM enable / pending-trap 控制长链；不得为达标补 false path，也不得把
投影或负 WNS 写成 200 MHz 闭合结论。

## 6. 验证计划与证据口径

| 层次 | 检查 | 通过判据 |
| --- | --- | --- |
| 结构前提 + 有限域枚举 | `prove-t3i-drain-theorem.py` 检查六个 RTL 文本前提，并枚举 ROB 合法 count `0..16`、3 个 commit 条件与 4 个 quiet 条件 | `17 * 2^3 * 2^4 = 2176` 个 legal-domain old/new 公式案例全等价 |
| RED/GREEN 结构 | `check-t3i-drain-structure.py` 对旧 T3H 与 current source 运行 | 旧 RTL 因 retire 端口仍在而精确 RED；current 端口消失、安全项与 assertion marker 完整 |
| 模块动态 | `tb_ooo_pending_drain_resolve_gate` | 穷举代表性 count/五个 drain predicate，并覆盖 jump、SYSTEM/CSR、branch resolve/clear/replay |
| 定理动态牙齿 | `tb_ooo_alu_core_slice` + negative macro | 正向 empty ROB 不退休；negative 强制 illegal tuple，`[CORE-RETIRE-REQUIRES-ROB]` 精确命中一次 |
| 集成契约 | `make -C npc/rv64 check-contract`、RTL style、Verilator lint、全 module TB | contract ratchet 不回退，无新 lint/style/模块回归失败 |
| 功能回归 | AM、official/privileged riscv-tests 与 full core-regress | 与 T3H 功能集合一致，无 trap/redirect/访存顺序回退 |
| 周期等价 | CoreMark 10 iterations | cycles、commits、CPI、CRC 与 T3H 基线逐项相同，否则先定位根因，不接受“性能波动”解释 |
| 物理时序 | fresh synthesis + 5 ns OpenSTA + 定向 path-family checker | loops=0；fresh retire→drain/fetch/trap 路径族为 0；只在 WNS `>=0` 时声明 current-source 200 MHz 闭合 |

`prove-t3i-drain-theorem.py` 是**RTL 文本前提检查加有限 2-state 域枚举**，不是完整 formal
verification、等价检查器或可达性 model checking；它不覆盖 X/Z、任意参数、所有未来 RTL
改写或全系统状态空间。动态 assertion、回归与 fresh netlist 检查共同构成证据链，不能用
2176 个枚举案例越级替代它们。

实际证据：module TB `96/96`、official/privileged RISC-V tests `177/177`、AM cpu-tests
PASS；CoreMark 10 iterations 精确保持 T3H 的 `3020147` cycles、`3218532` commits、
CPI `0.938`、CRC `0xfcaf`。定理 runner 把 commit0/commit1 RHS ratchet 为顶层纯 `&&`
且 count/commit0 为精确 conjunct；删除 count guard 与追加顶层 `|| 1'b1` 两种 mutation
均被精确拒绝，避免“文本仍含 guard、逻辑却已绕过”的假绿。

## 7. 风险、非声明与回退

- 若未来 ROB 允许 `count_q==0` 时从独立 completion queue 产生 commit，或让 commit valid 不再
  等于 fire，本定理立即失效；必须先恢复安全条件或重构单一真源，再改 spec/RTL。集成断言用于
  尽早暴露这种漂移，但不替代设计评审。
- 行为等价只覆盖复位后合法 0/1 状态。孤立 gate 的非法 tuple（例如 `rob_count=0` 且
  `retire_count=1/X`）在旧/新公式间可能不同；它们由 owner 契约和 assertion 排除，不得伪装成
  任意输入组合等价。
- `backend_drained_q` 与 raw `backend_drained` 相差 tracker 一拍；误把二者合并会改变 CSR
  dispatch 周期，超出 T3I 范围。
- `mem_retire_quiet`、synthetic pending 项即使当前部分 tie-off，也不能借本定理顺手删除；
  它们分别守 SQ/AXI 与独立 pending owner，需另立可达性切片。
- 诊断投影约 `0.72 ns` 不是 fresh STA；本切片不承诺 200 MHz，不是 physical CTS/SPEF/OCV
  signoff，也不证明完整 Linux/Ubuntu 功能。
- 若功能、周期或定向时序检查不闭合，回退点为 T3H checkpoint `0b0d71673`；不得只回退 assertion
  而保留未经证明的结构删除。

## 8. 变更记录

- 2026-07-13（T3I 初稿）：记录 T3H top40 根因、ROB-empty 蕴含零退休的切点、结构/动态/
  fresh STA 验证路线与 200 MHz 非声明。
- 2026-07-13（契约补全）：按 interface-contract-first 补齐完整端口 owner、组合时序、六类
  契约、无状态周期模型、最后退休前沿/后沿、flush 清/保持表和同拍优先级；将有限合法域案例
  校正为 2176，并明确 Python runner 不是完整 formal verification。
- 2026-07-13（fresh 裁决）：功能/周期回归全绿；110-module frozen-input synthesis 与正确
  H7CL OpenSTA 证实 retire 路径族消失，WNS/TNS 为 `-9.38/-199464.16 ns`，故 T3I
  完成但 200 MHz 未闭合，下一切片继续处理 EX→fetch/trap 长链。
