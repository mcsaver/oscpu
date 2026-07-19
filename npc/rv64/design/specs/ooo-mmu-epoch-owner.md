# OooMmuEpochOwner 规范

> 状态：`Q1A abort-priority source-catalog GREEN / live integration RED`
>
> 本模块只闭合 R4-S1-ID MMU epoch/barrier 的 held-request、同拍封门、quiet 后 sticky grant、
> shared registered abort 消费与 2-bit epoch 单一真源。它不是完整 context barrier；CsrFile effective-value classifier、
> backend/SQ/bridge full quiet、commit gating、epoch echo/mismatch 和双 memory datapath仍须后续原子集成。

## 1. 目的与范围

`OooMmuEpochOwner` 位于有效 data-memory context change 与 memory-owner capture 之间。它把一个
已经由上游证明为 effective 的 context/SFENCE boundary 锁存为唯一 pending event，先组合封住新
memory capture，再等待完整 quiet，最后以可回压 grant 让 context apply 与 epoch increment 在同一
边沿发生。若上层发现 held identity 已失效，它必须先生成 shared registered abort event；本 leaf
在 event 展示拍立即屏蔽 request/grant，并在该沿清 held owner，且不推进 epoch。未来 live wrapper
必须把同一个 event 同拍送给 CsrFile reservation，不能各自重建取消条件。

本模块不负责：CSR WARL/PMP-lock/no-op 分类、ROB 年龄仲裁、年轻 memory owner squash、AXI drain、
LR reservation 清除、TLB clear、本次 grant 的具体架构状态写入、response-side epoch match，或任何
第二 AGU/translation/cache/completion 能力。Q1 只进入 source catalog 和 focused test，不接 live core
控制，因此不得产生功能、性能、面积、时序或 architecture-seed claim。

## 2. 接口契约

### 2.1 端口与握手

| 端口 | 方向/位宽 | 时序与复位 | 契约 |
| --- | --- | --- | --- |
| `clk` / `rst` | input / 1 | 同步高有效 reset | reset edge 清 pending、grant、held bundle 和 epoch |
| `request_valid_i` | input / 1 | ready-valid producer | effective boundary envelope；不得由 `capture_block_o` 组合门控 |
| `request_ready_o` | output / 1 | 组合 | 仅 `UNLOCKED`、cause 非零、无 abort/rearm 时为 1；状态只由本模块拥有 |
| `request_cause_i` | input / `CAUSE_W` | valid 到 fire 稳定 | 多个 cause bit 同一 envelope 只形成一次 epoch advance；全零非法 |
| `request_payload_i` | input / `PAYLOAD_W` | valid 到 fire 稳定 | opaque candidate/apply payload；本模块不解释其字段 |
| `abort_valid_i` | input / 1 | registered one-cycle event | 共享取消事件；展示拍立即 block 且屏蔽 request/grant，沿上清 held owner；不推进 epoch |
| `mem_context_quiet_i` | input / 1 | 已寄存事实的组合归约 | backend/MIQ/SQ/bridge 等完整 quiet；不得依赖本模块 ready/grant |
| `owner_live_empty_i` | input / 1 | owner tracker 寄存事实 | wrap/grant 前所有旧 memory token 必须为空 |
| `capture_block_o` | output / 1 | 组合 look-ahead | `abort_valid_i || abort_rearm_q || state != UNLOCKED || request_valid_i`；首次请求、abort 或 rearm 出现同拍即封住新 capture |
| `grant_valid_o` | output / 1 | sticky ready-valid | `COMMIT && !abort_valid_i`；无 abort 时持续为 1，直到 `grant_ready_i` 消费 |
| `grant_ready_i` | input / 1 | consumer backpressure | grant fire 是唯一 context apply/epoch publish 边界 |
| `grant_cause_o` | output / `CAUSE_W` | grant valid 时稳定 | request fire 捕获的 cause 原样回放 |
| `grant_payload_o` | output / `PAYLOAD_W` | grant valid 时稳定 | request fire 捕获的 payload 原样回放 |
| `mmu_epoch_o` | output / 2 | reset=0，寄存 | 只在 grant fire 边沿 modulo-4 `+1` |

典型时序：

```text
cycle             N              N+1...K             K+1          K+2
state          UNLOCKED        LOCKED_DRAIN         COMMIT      UNLOCKED
request_valid      1                 0                 0             0
request_ready      1                 0                 0             1
capture_block      1                 1                 1             0
quiet/empty        x               0 -> 1              1             1
grant_valid        0                 0                 1             0
grant_ready        x                 x                 1             x
epoch              e                 e                 e            e+1
```

`request_valid_i` 出现的 N 拍，`capture_block_o` 已经为 1；request 自身通过独立 ready-valid bypass
在 N edge 被捕获。grant fire 的 K+2 edge 之前 block 保持为 1，所以 transition edge 不可能同时创建
旧 epoch owner；edge 后新 capture 观察到已更新的 context 与 epoch。

### 2.2 六类跨模块契约

| 类别 | Q1 冻结语义 |
| --- | --- |
| 握手 | request/grant valid 到 fire 前不撤回且 bundle 稳定；valid 不组合依赖同级 ready。abort 是显式 cancellation；旧 request 必须先 valid-low，leaf rearm 前不重收 |
| stall | request backpressure 只由本模块 FSM；capture block 只封新 owner，不能封旧 owner drain；quiet 不反向依赖 ready |
| flush/kill | raw branch/flush 不直连本 leaf；上层先把 identity mismatch/global flush 归一成 shared registered abort。reset 或 abort 才清 held owner |
| 异常序 | 上游只允许精确 ROB-head context boundary 进入；本模块不自行选择年龄或宣告异常完成 |
| 访存序 | grant 前必须 `mem_context_quiet && owner_live_empty`；已授权 store/AXI/PTW drain 不受 block 影响 |
| 恢复真源 | held cause/payload 与 `mmu_epoch_o` 是唯一真源；live CSR、raw `mmu_flush`、ROB/SQ index不得重建；abort 只来自上层唯一 registered event |

### 2.3 flush/redirect 表与同拍优先级

| 来源 | 清除 | 保持 |
| --- | --- | --- |
| reset | FSM、held bundle、epoch | 无 |
| shared abort | FSM、held bundle；同拍屏蔽 request/grant | epoch |
| raw branch/redirect/global flush | 无（模块无 raw 输入） | 由上层决定是否生成 shared abort |
| context boundary capture | 无旧 event 可清 | 新 event 捕获后一直保持到 grant fire |
| grant backpressure | 无 | grant valid、cause、payload、epoch |

同拍全序为 `reset > abort > grant/当前状态的合法 handshake/transition > hold`。abort 展示拍组合
屏蔽 request-ready 和 grant-valid，因此 abort+request、abort+grant-ready 均不产生 fire；该沿只清
held owner，epoch 保持。不同 FSM 状态没有 capture、drain transition 与 grant fire 的同拍竞争；
不支持 grant-fire + next-request 的零气泡 handoff。

abort edge 把 `abort_rearm_q` 置为当拍 `request_valid_i`。若当拍存在被取消的 request envelope，
只要旧 producer `request_valid_i` 仍为 1，rearm 就保持并继续令 `capture_block=1/request_ready=0`；
观察到一个 valid-low edge 后才清 rearm，下一拍可接受重新资格化的新 envelope。abort 拍没有 request
时不凭空增加 rearm bubble。这样 continuous-valid 不能在 abort 后被静默重捕获。

## 3. 状态与时序模型

```text
UNLOCKED
  -- request_fire --> LOCKED_DRAIN
LOCKED_DRAIN
  -- mem_context_quiet && owner_live_empty --> COMMIT
COMMIT
  -- grant_fire / epoch+1 --> UNLOCKED
```

| 状态 | 输出/动作 | 退出条件 |
| --- | --- | --- |
| `UNLOCKED` | request ready；无 pending grant | 非零 cause request fire，锁存 bundle |
| `LOCKED_DRAIN` | capture block；不授权 context apply | quiet 与 live-empty 同时成立的 edge 后进入 COMMIT |
| `COMMIT` | capture block；sticky grant 输出 held bundle | grant fire 同 edge epoch+1，下一拍回 UNLOCKED |

寄存器：`state_q[1:0]` reset=`UNLOCKED`；`held_cause_q`/`held_payload_q` reset=0，只在 request fire
写，在 grant fire 或 abort 清；`mmu_epoch_q[1:0]` reset=0，只在 grant fire `+1`，abort 不写。非法状态在 release build 下保持
锁闭（ready=0、block=1、grant=0），assert build 立即失败。

## 4. 不变量

- **EPOCH-I1 first-cycle block**：`request_valid_i -> capture_block_o`；否则同拍可创建旧 epoch owner。
- **EPOCH-I2 single pending owner**：非 UNLOCKED 时 request ready 恒 0，held bundle 不被第二请求覆盖。
- **EPOCH-I3 full-quiet grant**：grant valid/fire 只可能发生在已观察 quiet+live-empty 后；COMMIT 中二者不得回落。
- **EPOCH-I4 sticky grant**：`grant_valid && !grant_ready` 后 grant 与 bundle/epoch保持，不能丢单拍事件。
- **EPOCH-I5 atomic publish**：epoch 只在 grant fire 改变，每次精确 `+1 mod 4`；无 grant fire 时稳定。
- **EPOCH-I6 transition gap closed**：grant fire edge 前 block=1；新 capture 最早下一拍看到新 epoch。
- **EPOCH-I7 valid cause**：accepted request cause 非零；同拍多 bit 仍只对应一个 event。
- **EPOCH-I8 legal/fail-closed state**：状态只允许三种编码；非法编码不得 ready/grant，必须 block。
- **EPOCH-I9 abort immediate mask**：`abort_valid -> capture_block && !request_ready && !grant_valid`；
  abort 与 ready/grant 同拍不能泄漏 fire。
- **EPOCH-I10 abort clear/no-advance**：abort edge 后 owner 必须为 UNLOCKED、held bundle 为零且 epoch
  与 edge 前一致；优先级精确为 `abort > grant/normal > hold`。
- **EPOCH-I11 abort rearm**：若 abort 当拍有 request valid，则必须观察 request valid-low 才重新
  ready；rearm 期间 `capture_block && !request_ready && !grant_valid`。abort 当拍 request 无效时不置 rearm。

上述可编码项在 RTL 的 `` `ifdef OOO_ASSERT `` 时钟块中用立即检查实现；focused negative/源码
mutation 必须分别证明 assertion/test 不是空门禁。

## 5. 关键路径与时序考量

`capture_block_o` 只有 abort、状态比较与 `request_valid_i` OR，必须组合直达 memory admission；
它不能经过 quiet 或 ready。`request_ready_o` 只比较 abort、状态与 cause OR-reduction。quiet 只在时序边沿决定
`LOCKED_DRAIN -> COMMIT`，不会形成 `ready -> quiet -> ready` 环。cause/payload只进寄存器，不进入
memory request ready；Q1 不接 live top，因此当前 source 不产生可测 CPI/PPA 变化。

## 6. 验证计划

1. module TB：首次请求同拍 block、quiet 与 live-empty 独立门控、sticky grant/backpressure、第二请求
   不覆盖、multi-cause once、四次 modulo wrap、grant edge 不接受新 request。
2. mutation：删除 look-ahead、删除 quiet、删除 live-empty、grant 改为 ready-dependent pulse、grant
   payload 改读 live input、epoch 非 grant-fire 更新、wrap 饱和，均必须被单一 directed marker 杀死。
3. abort directed：IDLE+request、LOCKED_DRAIN、ready grant、backpressured grant 四相位；所有场景
   检查同拍 handshake 全灭、下一拍 held 清零和 epoch 稳定。
   另把被取消 request 连续保持两拍，证明 valid-low 前不会重收，valid-low edge 后才 rearm。
4. abort mutation：删除 abort look-ahead、ready mask、grant mask、降低 abort state priority、abort
   推进 epoch，必须 compile-success 且由各自唯一动态 oracle 杀死。
5. assertion negative：zero-cause、stalled request payload drift、COMMIT quiet drop、非法 state、
   abort-ready 泄漏等精确 marker。
6. style/lint/Yosys/module aggregate 只证明 leaf 可综合与既有 gate 不退化；完整 R4-S1-ID 继续 RED。

## 7. 风险与回退

- 最大风险是上游把 raw `mmu_flush` 或 raw CSR write冒充 effective request；Q1 不解决 classifier。
- `mem_context_quiet_i` 漏掉 PTW/AXI/SQ/AMO/LRSC/token 会产生假 quiet；Q1 focused 不能替代集成证明。
- block 若同时门住旧 drain 会死锁；后续 wrapper 必须把 capture admission 与 drain progress 分开。
- payload width 是 integration 期显式参数，不允许为省端口改回 live CSR 回读。
- leaf 的 `abort_valid_i` 只是 shared registered event 的 consumer；在 Q1 与 CsrFile 未由同一 wrapper
  同拍驱动前，不得把“leaf abort 已实现”越级写成 active reservation 原子取消。
- `mem_context_quiet_i && owner_live_empty_i` 在进入 COMMIT 后必须是本 transaction 的不可撤销完成事实，
  不是可重新变脏的瞬时 empty level；assertion-negative 会拒绝 backpressured grant 期间 quiet 回落。
- `capture_block_o` 只封另一条 memory admission，不得组合门控本模块的 `request_valid_i`；否则
  `request_valid -> capture_block -> request_valid` 会形成环。
- 回退点是删除未实例化 leaf、filelist/TB/spec 条目；不会改变 live core 行为。

## 8. 变更记录

- 2026-07-17：冻结 Q1 三态 held-request/quiet/sticky-grant/epoch 合同；implementation 尚未声明 GREEN。
- 2026-07-18：leaf 已进入共享 filelist 与正式 module harness；canonical runner 的 release/assert
  正例、4 个完整消息 assertion-negative、7 个唯一 oracle mutation、release/assert lint、style、
  Yosys 与 adoption contract 全 PASS；fresh module aggregate `104/104 PASS`。本状态不包含
  live ROB/CsrFile/MMU 接线、Linux、双 memory、200 MHz 或 PPA 声明。
- 2026-07-19：Q1A 增加 registered `abort_valid_i` consumer；组合面立即封住 capture/request/grant，
  时序面以 `reset > abort > grant/normal > hold` 清 held owner且不推进 epoch。该能力仍未 live instantiate，
  CsrFile shared abort、identity mismatch producer 与 active permit 继续 RED。
- 2026-07-19：独立反例审查后增加 `abort_rearm_q`；被取消 envelope 必须先 valid-low，continuous-valid
  在此之前持续 fail closed。quiet 同时冻结为 transaction-scoped irrevocable completion，raw empty
  level 不得冒充。
