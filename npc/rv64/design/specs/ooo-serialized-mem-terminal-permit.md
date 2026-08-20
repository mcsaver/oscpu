# 规范：serialized control 的 owner-bound memory-terminal permit

> 状态：V16A 可回退时序实验定义；尚未获得 PPA/promotion 资格。
> 受影响模块：`OooSerializedMemTerminalPermit`、`OooControlPlane`、
> `OooPendingDrainResolveGate`。父合同见
> [`ooo-serialize-memory-owner-terminal.md`](./ooo-serialize-memory-owner-terminal.md)。

## 1. 目的与范围

current f72e 的两轮 exact-5 ns mapped top-40 均经过
`OooIntBackend.mem_owner_terminalized_o → OooPendingDrainResolveGate.drain_complete_o →`
trap/redirect/fetch-PC。当前组合实现正确，但 WNS 为负，不能晋级。

本切片只把 non-CSR serialized owner 的 exact memory-terminal 资格打一拍，形成一个带当前
owner one-hot 身份的 cancellable permit。permit 只替代 drain 方程里的同拍
`mem_owner_terminalized_i`；以下条件继续当拍重查，不允许被 permit 缓存：

- `backend_drained_o` 的 ROB/IQ/synthetic/SQ quiet；
- ordinary FENCE 的完整 `mem_idle_i`；
- trap/exit、CSR/xRET、branch recovery 的既有优先级；
- collector/tracker 的真实 terminal dequeue/free 与 token conservation。

不在范围内：不改变 memory holder、collector ingress、tracker allocator、AXI/SQ/LSQ、CSR
dispatch permit、benchmark image、SDC、Power 口径或 promotion policy。裸一 bit、没有 owner
比较的 `serialized-mem-terminal-readiness-register-v1` 保持拒绝。

## 2. 接口契约

### 2.1 `OooSerializedMemTerminalPermit` 端口

| 端口 | 方向/宽度 | 时序/复位 | owner 与语义 |
| --- | --- | --- | --- |
| `clk` | in/1 | 单一 core clock | permit 两个寄存器的时钟 |
| `rst` | in/1 | 同步高有效；最高优先 | 清 `permit_valid_q/permit_owner_q`；父层合入 global reset/flush |
| `cancel_i` | in/1 | 当拍 feedback-free clear witness | core-local flush、ROB-head trap、older control recovery 或 queue-head CSR commit；组合封住 `ready_o` 并在下一沿清 permit，不清 memory transaction；禁止接入含 `drain_complete` 的完整 holder clear |
| `stop_pending_i` | in/1 | 组合读取 registered stop owner | `OooStopPendingSequencer` 单一真源；为 0 时 permit 输出无效并在下一沿清除 |
| `backend_drained_q_i` | in/1 | 上一沿 registered drain | 只允许 arm；不能替代本拍 `backend_drained_o` |
| `owner_i` | in/3 | 当拍 registered holder one-hot | bit0=`pending_system && !pending_system_csr`，bit1=`pending_arch_trap`，bit2=`pending_exit`；来源只允许三个 sequencer Q |
| `mem_owner_terminalized_i` | in/1 | 当拍 exact owner phase | 只进入 permit D；same-edge memory birth 必须使其为 0 |
| `consume_i` | in/1 | 当拍 accepted `drain_complete` | clear-dominant；同一 permit 不能重复授权 C1 |
| `ready_o` | out/1 | permit Q + feedback-free cancel + 小 one-hot compare | 仅 `!cancel_i && permit_valid_q && stop_pending_i && owner_i==permit_owner_q && owner_i exact-one`；不读 `mem_owner_terminalized_i` |

该接口不是 ready/valid payload channel；它是 serialized owner 的一次性完成资格。没有 payload，
不允许 consumer 反压，也不产生任何 memory dequeue/free。`ready_o` 只能被
`OooPendingDrainResolveGate` 的 serialized-memory 条件消费。

### 2.2 典型周期

```text
cycle k    owner=A, stop=1, backend_drained_q=1, mem_terminalized=1
edge k     IDLE -> ARMED(owner=A)
cycle k+1  ready=1；drain gate 仍重查 raw backend_drained 和 FENCE mem_idle
edge k+1   若 drain_complete=1，ARMED -> IDLE；对应 owner/stop 由既有 sequencer 清
cycle k+2  ready=0，禁止重复 trap/exit/system terminal
```

若 k+1 的 owner 从 A 变成 B，`owner_i==permit_owner_q` 立即为 0，B 不能消费 A 的 permit；
下一沿清除后，B 必须重新经过一次 exact terminal arm。若 k+1 出现 memory birth，raw
ROB/IQ/SQ drain 必须保持 0，故旧 permit 不得形成 `drain_complete`。

### 2.3 六类跨模块契约

| 类别 | 冻结规则 | 可执行牙齿 |
| --- | --- | --- |
| 握手 | permit 从 arm 沿后有效，直到 consume/cancel/owner mismatch/stop drop；同一 owner 最多消费一次 | helper TB 覆盖 ready stall、consume 与 no-repeat；立即断言检查 shape |
| 反压/stall | permit 不产生 ready 回吹；`can_run=0` 仍由 live serialized owner + stop 决定；permit 不能 birth 新 uop | ControlPlane 断言 live owner 与 `stop_pending/can_run` 关系；mutation 删除 owner compare 必须失败 |
| flush/redirect | reset/global-local flush、ROB-head trap、older recovery、head0 CSR commit 高于 arm/hold；direct frontend fire 与 live serialized owner 构造性互斥 | feedback-free cancel 当拍封住 ready 且 clear-dominant；arm/held+cancel TB；现有 priority mux 不改 |
| 异常序 | ROB-head trap 继续压住 pending arch/system/exit；pending owner exact-one；C0 fire、C1 owner/stop/permit clear | `OooCsrTrapRequestMux` 不改；C0/C1 directed TB + immediate assertion |
| 访存序 | permit 不释放 token，不杀已发 AXI，不清 committed store；FENCE 仍需 current `mem_idle_i` | drain gate保留 raw drain/FENCE 条件；非法 stale-permit+raw-drain+active-holder tuple fail loud |
| 投机恢复/单一真源 | permit owner 只镜像当前 exact-one holder用于防重用，不重新分类 instruction；owner mismatch立即失效 | owner one-hot/match assertion；A→B handoff mutation case |

### 2.4 flush/clear 表与同拍优先级

| 事件 | permit 动作 | 必须保持 |
| --- | --- | --- |
| `rst` / global flush | 清 valid/owner | 无 pending 控制可提交 |
| core-local flush / ROB-head trap | `ready_o` 当拍失效，沿上清 valid/owner；低优先级输出不得被采纳 | committed store、已发 AXI、已提交 CSR |
| branch recovery / older control terminal | 清 | 仅清 younger pending owner，不撤销 memory terminal |
| `drain_complete` | 清；该拍只消费一次 | collector/tracker 自行完成 dequeue/free |
| owner clear/handoff / `stop_pending=0` | `ready_o` 当拍失效，下一沿清 | 新 owner 必须重新 arm |
| 无上述事件 | IDLE 可 arm；ARMED 同 owner保持 | 当前 owner payload/类型由原 sequencer Q 保持 |

同拍优先级：

```text
reset/global-local flush > ROB-head trap/older recovery cancel
  > drain consume > owner mismatch/stop drop > arm > hold
```

三条铁律保持：committed store 不清；已发 AXI 只 drain；CSR commit 拍的架构写不可撤销。

## 3. 状态与时序模型

### 3.1 FSM

```text
IDLE -- arm(exact-one owner && stop && backend_drained_q && terminalized) --> ARMED(owner)
ARMED -- same owner && stop && !cancel && !consume ----------------------> ARMED
ARMED -- cancel || consume || !stop || owner mismatch/non-onehot --------> IDLE
IDLE  -- reset/cancel/consume/invalid owner ------------------------------> IDLE
```

### 3.2 寄存器与组合拓扑

| 寄存器 | 位宽 | 复位 | 更新 |
| --- | ---: | ---: | --- |
| `permit_valid_q` | 1 | 0 | clear-dominant；IDLE arm 时置 1 |
| `permit_owner_q` | 3 | 0 | clear 时归 0；arm 时捕获 exact-one `owner_i` |

组合块只有 exact-one detector、owner equality、arm predicate、feedback-free cancel 与 `ready_o`。没有 function、
仲裁器、valid/ready 环、共享算术资源或 payload mux。`mem_owner_terminalized_i` 只到寄存器 D；
critical path 预期从 permit Q 经 3-bit compare、drain/priority mux 到 trap/redirect/fetch，原 memory
owner/LSQ/PMP 大锥不再直达这些端点。

### 3.3 owner lifecycle 可达性依据

1. live system/arch/exit 使 `OooFrontendRunGate.stop_pending_busy_o=1`，从而 `can_run_o=0`；
   `OooPendingDispatchArbiter.capture_base_w` 因此不能无缝 birth 第二个 pending owner。
2. `OooControlPlane` 已要求 system/arch/exit holder exact-one，且 C1 清 owner 与 stop。
3. `backend_drained_q_i` 只有上一拍 raw backend empty 且无 dispatch 时置 1；force-drained 只来自
   更高优先级 ROB-head trap，该事件同时 cancel/clear permit。
4. same-edge reservation birth 已显式令 `mem_owner_terminalized_i=0`；arm 拍不会与 birth 共存。
5. arm 后即使出现非法 active-holder reappearance，`drain_complete` 仍重查 raw ROB/IQ/SQ drain；
   `ready && raw_drained && !current_terminalized` 作为 fail-loud contract guard，不能静默完成。

## 4. 不变量

1. `permit_valid_q -> onehot(permit_owner_q)`；否则 owner identity 损坏。
2. `ready_o -> !cancel_i && permit_valid_q && stop_pending_i && exact_one(owner_i) && owner_i==permit_owner_q`；
   否则 stale owner 可能完成另一 transaction。
3. 上一拍 consume/cancel/stop drop/owner mismatch 后，本拍 permit 必须为 0。
4. exact arm 后若无更高优先级 clear，本拍 permit 必须持有同一 owner。
5. serialized `drain_complete` 必须由当前 owner 的 permit 授权；ordinary FENCE 同时必须
   `mem_idle_i=1`。
6. `ready_o && backend_drained_o && !mem_owner_terminalized_i` 在合法集成域不可达；若出现说明
   active holder/birth 在 raw drain 之外复活，必须 `$fatal`，不得靠 stale permit继续。
7. permit 的建立/消费不改变 collector ingress、pending mask、tracker live mask 或 token free 次数。

断言使用 `always @(posedge clk)` 立即检查并由 `OOO_ASSERT` 门控；每项需有编译成功的负向 RTL
变体或 directed illegal tuple 证明非真空。

## 5. 关键路径与 PPA 边界

本切片目标是切断 f72e top40 中 40/40 的
`mem_owner_terminalized → drain_complete` 组合段。增加 4 FF（valid + one-hot owner）和小比较器；
只有 fresh 同配置 mapped A/B 才能报告 WNS/TNS/area。即使 WNS改善但仍小于 +0.10 ns，timing hard
gate 仍 FAIL；vectorless power和 unknown macro area 保持 unqualified。

## 6. 验证计划

- helper focused TB：arm/hold/consume、A→B mismatch、stop drop、arm+cancel、held+cancel 同拍阻断、reset、non-onehot。
- drain integration TB：permit 只替代 serialized terminal；raw backend drain 与 FENCE `mem_idle`
  仍逐项阻塞；trap/exit/system exact-one/no-repeat。
- `OOO_ASSERT=1/0` 两种编译；compile-success mutation 至少删除 owner match、cancel state-clear、
  cancel-cycle ready block 和 FENCE current-idle 条件，必须由专属 marker 拒绝。
- `make -C npc/rv64 check-contract`、style、lint 与受影响 L0/L1；若候选保留，再运行同 design/config
  CoreMark/Dhrystone 与两轮 fresh mapped STA。

## 7. 风险与回退

- 若 active memory holder 能在 `backend_drained_o=1` 时重新出现，立即回退，不允许用断言代替生产
  安全性。
- 若 owner handoff 可在没有 exact-one/stop 失效边界时发生，升级为带 generation 的 owner ID，不能
  保留裸一 bit。
- 若新增一拍改变 FENCE/trap/exit/IRQ/xRET 的架构顺序或造成重复请求，回退整个 helper与接线。
- 若同配置 STA 未移除目标路径族、CPI floor退化或面积超出候选边界，作为负候选留证后回退。

## 8. 变更记录

- 2026-08-08：基于 f72e current timing receipt 与独立 GAP 复核，拒绝无身份的一 bit readiness；
  冻结 owner-bound cancellable permit 的接口、FSM、六类契约、反例与 PPA 非声明。
- 2026-08-09：独立 reviewer 构造 held-permit+cancel+raw-drain 同拍反例；`cancel_i` 收敛为
  feedback-free 单向见证并组合封住 `ready_o`，避免低优先级 terminal side effect 抢在 clear 沿前发生。
