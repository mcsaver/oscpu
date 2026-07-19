# S2-Q2 live MMU epoch atomic-slice contract

> 日期：2026-07-18
>
> 状态：`contract/checker hardening checkpoint / implementation RED / mem0-only / Q1 source-catalog GREEN`。
>
> 机器接口映射：`s2-q2-live-epoch-interface.json`（schema v7，带 checker 内置 contract-lock digest）。
> 结构 readiness 检查通过仍只是必要条件；
> directed/mutation、全量回归与 PPA 硬门仍必须另行闭合。

## 1. 当前真源与实施边界

| 事实 | 当前真源 | 当前缺口 |
| --- | --- | --- |
| ROB head payload | `OooRob` 的 commit0 payload 无条件读 head Q | `commit0_valid_o=commit0_fire_w`，没有独立于 `commit_ready_i` 的 precommit valid |
| lane1 退休 | 当前只对 CSR/return 的部分情形 block | SFENCE/xRET/FENCE.I 等 potential boundary 仍可能从 commit1 越过 |
| CSR legality/WARL/lock | `CsrFile` 的 illegal、`sanitize_satp`、PMP lock/sanitize、trap/xRET helper | 没有 prepare→held normalized candidate→grant-time apply |
| 新 memory owner capture | `mem_issue_res_capture_candidate_w` / `OooMemOwnerTracker` | 当前只受通用 `mem_issue_block_w`；valid owner capture epoch 仍来自常量 0 |
| backend quiet | `mem_idle_o` 含 MIQ/pending/buffer/reservation/live-token/terminal pending | 不能直接再 AND `sq_empty` 后接回 ROB，否则 head boundary 与 younger SQ 自锁 |
| SQ retire quiet | `mem_retire_quiet_o = !sq_mode || (sq_empty && !drain_inflight)` | 只能在 younger selective squash 完成之后进入 Q1 full quiet |
| bridge quiet | `NpcCoreTop.ooo_mem0_idle_w` 由 registered FSM/station/residency facts 产生 | 顶层本地 wire 尚未进入 epoch barrier |
| IFU/FPC | 取指 outstanding/fill 未进入 data-MMU barrier | grant 后仍可能写入旧上下文 fetch response |
| response provenance | bridge/MIQ/SQ 已 echo/compare `{kind,token,epoch,tval}` | allocation/bind/capture epoch 仍为 `MEM_OWNER_EPOCH_BASE=0` |
| invalidate | `OooMemoryRequestGate.mmu_flush_q` 合并 SATP/SFENCE/FENCE.I | 晚一拍且语义混合；FENCE.I 被错误混入 data-MMU epoch 候选 |
| width | `issue1_mem_req_valid_w=0`，single mem0 bridge | 第二 AGU/translation/order/cache/completion 全部未实现 |

真实传播链为：

```text
NpcCoreTop
  -> OooCoreTopGlue
  -> OooExecuteBackend
  -> OooAluCoreSlice
  -> OooAluDecodeBackend
  -> OooIntBackend
  -> OooDispatchBackend
  -> OooRob
```

Q2 只闭合真实 mem0 context boundary。它不得冒充双 memory、Linux、200 MHz 或 PPA 结论。

## 2. 退休、prepare 与组合无环合同

### 2.1 ROB precommit 与 lane1 禁越界

`OooRob` 必须导出独立于 `commit_ready_i` 的 head0 基础候选 valid 和稳定 head identity。
现有 commit payload 可以继续作为 head Q 视图，但不得用已经等于 fire 的 `commit0_valid_o` 生成 request。

- `head0_retire_candidate_valid`：head0 valid、done、非 recovery；不含 `commit_ready_i`、Q1 ready、
  grant ready 或 context permit。
- `head0_identity`：至少含 ROB index；若实现允许 index 在 held 期间复用，还必须含 allocation generation。
- `head0_context_permit`：非 effective boundary 恒 1；effective boundary 只在 held identity 匹配且
  `grant_valid && grant_ready` 时为 1。
- 任意 **potential context/I-side boundary**（CSR、SFENCE.VMA、xRET、FENCE.I 及未来同类）不得由
  commit1 退休。head1 只做保守 potential 分类；合法性/effective old→next 等它成为 head0 后再判定。
- Q1 只接受 head0 identity；禁止用 lane1 payload 发 request，也禁止 head0 grant 同拍让 lane1 boundary
  搭车退休。

冻结无组合环方程：

```text
request_valid = head0_retire_candidate_valid && csr_prepare_effective
request_valid 不依赖 request_ready / commit_ready / grant_ready / commit fire

grant_valid_q = Q1 Moore state
grant_ready   = held_head_match && head0_base_ready && registered_quiet_seen &&
                csr_context_writer_owned && !identity_mismatch_recovery_q
head0_context_permit = !head0_effective_boundary ||
                       (grant_valid_q && grant_ready && held_head_match)
commit0_fire = head0_base_ready && head0_context_permit
grant_fire   = grant_valid_q && grant_ready
```

`grant_ready` 不得读取 `head0_context_permit`、`commit0_fire` 或 grant fire。若 held identity 不匹配，
显式 `held_head_match=(current_head_identity==held_identity)` 必须为 0，并进入 registered recovery；
grant-ready 与 permit 都必须依赖该 equality，不能对新 head apply 旧 payload。

identity mismatch 不能只把 `grant_ready` 拉低后“进入 recovery”：现有 Q1 owner 的 `ST_COMMIT`
grant 是 sticky，若没有终端动作会永久保持 capture block。冻结恢复时序如下：N 拍
`grant_valid && !held_head_match` 只置 registered `identity_mismatch_recovery_q`，该拍及随后 abort
拍 `grant_ready/permit=0`；N+1 的唯一 `abort_fire` 同一信号精确连接
`OooMmuEpochOwner.abort_i` 与 `CsrFile.context_abort_valid_i`。abort 优先于 grant/apply；该沿 owner
从 busy/commit 回 unlocked、清 held cause/payload 但 epoch 不变，CSR 只释放本 held reservation，保留
deferred writer。该沿 capture block 仍高，且禁止 commit、context write、invalidate、LR clear、pending
clear 与 redirect；新 request/capture 最早下一拍。owner/CSR/phase/sent/recovery 必须由唯一 next-state
writer 消费 abort，禁止仅清 wrapper phase 而留下 sticky owner。

### 2.2 CsrFile prepare/apply envelope

Q1 request fire 必须锁存 `{operation/source, head identity, old context, normalized next, effect mask}`。
之后禁止从 live CSR 重建。`CsrFile` 必须复用真实 legality、WARL、PMP lock 与 sanitize 逻辑得到
old→normalized-next；grant fire 同沿才 apply exact held payload。

effective boundary 的所有 context-state 写者必须收口到唯一 write arbiter：legacy `csr_commit_i`、
`trap_mem/ex/irq_valid_i`、`mret_valid_i`、`sret_valid_i` 只能作为 prepare source；从 CAPTURE 到
GRANT 期间，它们不得绕过 held envelope 直接写 `priv/mstatus/satp/menvcfg/PMP` 及 trap envelope。
非 boundary CSR 仍可走 legacy path，但必须由 post-effective classifier 明确放行。

writer 冲突策略冻结为 **registered reserve + defer**：prepare effective 只有在独立、寄存化的
`context_reserve_ready` 为真时才与 Q1 request 同拍 reservation；`context_writer_owned_q` 从该边沿
保持到 grant apply。held boundary 自身的 legacy commit 被 envelope 吸收，不进入 busy/quiet 计算；
随后到来的 IRQ/trap/xRET/context CSR 进入 pending/deferred，等本次 grant 后重新仲裁，不允许 level
请求永久拉低 grant-ready，也不允许 abort 后把旧 payload apply 给新 head。`context_writer_owned`
只能来自 registered owner fact，不能组合依赖 permit、commit fire、raw legacy valid 或 grant fire。
grant 边沿只能由 `context_apply_valid_i` 对 held normalized payload 写一次，禁止 legacy 与 apply 双写。
`context_legacy_active_q` 以及 deferred 的 valid/cause/payload/owner 都必须是单一 exact
`always @(posedge clk)` driver + 单一 module-scope continuous combinational next；outer reset predicate
冻结为 exact positive `rst`，`!rst`、`~rst`、zero-compare、复合 predicate、async/multi-event sensitivity
均不接受。常量只允许出现在已识别 reset 分支，blocking write、多 always driver、legacy
分支常量写都失败。held 期间每个 raw legacy writer 必须进入 `context_deferred_enqueue`，payload/cause/
owner 保持到 exactly-once 重仲裁；raw valid 到 reserve-ready、writer-owned、grant-ready 或 context CSR
写口的组合捷径一律禁止。abort 只释放 held reservation，不能吞 deferred writer。

| cause | effective old→next 判据 | grant-time invalidate / action |
| --- | --- | --- |
| SATP | 合法写且 sanitize 后 `satp_next != satp_old` | ITLB、DTLB、PTE/translation cache、FPC translation provenance |
| SFENCE.VMA | 合法 head0 操作；payload 锁存 VA/ASID scope | 按 scope 失效 ITLB/DTLB/PTE cache；推进一次 data epoch |
| MSTATUS/SSTATUS | 仅 `{MPRV, MPP, SUM, MXR}` 等实际访问上下文位 normalized 后变化 | 失效依赖 access context 的 translation/access 决策；其他状态位变化不请求 epoch |
| MENVCFG.PBMTE | WARL 后 PBMTE 位变化 | ITLB、DTLB、缓存的 PTE/PBMT 属性及 FPC provenance；若 cache admission 元数据可跨请求存活，也必须失效 |
| PMP config/address | lock 与 sanitize 后 effective PMP image 变化 | 清除缓存的 access-decision/provenance；locked/no-op 写不推进 |
| trap | 三个 trap source 按 CsrFile 真实优先级得到 normalized `{priv, access-context bits}`，仅该 tuple 变化 | 对应 translation/access invalidate，并锁存 trap source/target envelope |
| xRET | 合法 mret/sret 后 normalized `{priv, access-context bits}` 变化 | 对应 translation/access invalidate，并锁存 return target envelope |
| FENCE.I | 不属于 data-MMU cause mask | 仅 I-side serialization/invalidate，**不得推进 data-MMU epoch** |

多 cause 落在同一 head envelope 时只推进一次 epoch。WARL 后不变、PMP lock 后不变、CSR set/clear
no-op 都不得请求 Q1。PBMTE/PMP 的消费者集合必须由实现清单明确，不能继续用无类型 `mmu_flush` pulse。

## 3. 屏障状态、年龄与 selective squash

Q2 live wrapper（或等价可观测状态）必须按下表单向推进：

| phase | 进入动作 | 允许前进的旧工作 | 离开条件 |
| --- | --- | --- | --- |
| CAPTURE | 接受 head0 request，锁存 identity/normalized envelope；request 首拍即拉高 capture block | 所有已登记 owner/transport | held bundle 已稳定 |
| SQUASH | **一次性**按 held ROB age 清 younger memory；按 boundary generation 取消所有 speculative fetch；不得复用 level flush | 已发 AXI、SQ nokill drain、bridge PTW/RMW、terminal collector | `memory_squash_done && ifu_squash_done` |
| WAIT_QUIET | capture block 持续高；采样 registered owner/transport facts | reservation consume、buffer、MIQ response、old SQ drain、AMO continuation、AXI/PTW/RMW | backend+SQ+bridge+IFU quiet，owner/terminal empty，且无同拍 ingress |
| GRANT | sticky grant；capture block 在 grant 当拍仍高 | 只允许 held grant backpressure | held head/base-ready 匹配后原子 grant fire |

年龄规则：memory selective squash 只删除 **严格年轻于 held boundary identity** 的 killable owner/SQ；
不得用 level `core_local_flush` 或 bridge `flush_i` 代替。必须保留已授权/不可撤回 side effect，继续其
SQ nokill、AXI、PTW/RMW 与 terminal exactly-once 路径。若 owner 当前不携带 ROB age/generation，
必须先补该 provenance，不能用“当前队列位置”猜年龄。

`OooMemOwnerTracker` 必须在 alloc fire 采样 ROB age，并在 exact memory-request fire 以
`{kind, token, epoch}` 匹配后置位 per-token `irrevocable_q`；age scan 必须同时读取
`live_q/kind_q/rob_idx_q/irrevocable_q`。STORE selective release 只能由 SQ 的既有 release mask 决策，
tracker 不得对同一 STORE token 二次 context-release；fired LOAD/PROBE/ATOMIC 必须留到唯一
terminal/drop。结构门只锁端口、capture 与动态依赖；strict-younger、identity generation 编码、
STORE 单一释放和 terminal+squash 同拍 exactly-once 仍是 directed/mutation 硬门，禁止越级结论。

IFU 不强制携带 ROB identity：boundary 已在 ROB head 时，可撤回 fetch 天然都更年轻。IFU 使用
transaction generation 区分 one-shot request/ack 并整体取消 speculative fetch；memory/SQ 仍必须用
ROB identity/age 精确保留 older/nokill owner。bridge 必须锁存 request generation，并以单一 next-state
writer 维护 sticky ack；目标寄存器在整个 active module 中不得再有 `always_ff`、negedge、latch、
`initial`、continuous/compound 或其他 procedural writer。只有 fetch transport、PTW/A-update 与 FPC fill
全部 cancel-or-drain 后才置 ack。
`done = ack_q && (captured_generation == current_request_generation)`，且 top 再比较返回 ack generation
与 held generation；`done` 禁止依赖 one-shot request-valid pulse。generation wrap/reuse 前必须证明旧
generation 引用全空，不能依赖位宽足够大猜测不会回绕。

机器接口必须显式出现并连通 held identity、one-shot `selective_squash_valid`、memory/IFU 两路
`squash_done` 与 ack generation。memory 路必须 raw-map 到 canonical
`u_store_queue/u_mem_owner_tracker` 的统一 `{valid, full identity, done}` 真叶接口；backend 中单个
`*_rob_identity_w` 代理、dummy leaf 或宿主侧并行常量/别名驱动都不算真叶。`WAIT_QUIET` enable
必须依赖两路 current-generation acknowledgement；只声明 full quiet 或直接等待 SQ empty 不能通过
结构门。memory ack 必须来自 SQ/owner 的真实多 entry age compare 完成，IFU ack 必须来自
fetch/PTW/FPC younger cancel/drain 完成，不能接常量。

one-shot 必须由 registered phase/sent fact 的**精确枚举比较**产生：
`phase==MMU_EPOCH_PHASE_SQUASH && !squash_sent_q`，不能用 `phase_q && !sent_q`；fire 后
`squash_sent_q` 置位，离开 transaction 才清。持续 level、OR 合并两路 done、或用吸收常量伪造
quiet/classifier 都必须由 boolean-shape checker 与 mutation 拒绝。

不能在 CAPTURE 之前把 `sq_empty` 纳入 ROB `mem_quiet_i`。正确顺序是：锁定 boundary → 阻止新 capture
→ selective squash younger SQ → 旧不可撤事务/terminal drain → full quiet → grant。Q2 full quiet
**不得接回**现有 `OooRob.mem_quiet_i`；它只供 Q1 barrier 使用。

## 4. capture-only block、IFU 与 full quiet

`mem_context_capture_block` 只允许 gate 新 owner 创建点：

- reservation owner allocation；
- SQ owner bind/fill；
- 新 buffer/legacy/AMO owner capture；
- 未来 lane1 memory allocation。

严禁把它 OR 到现有 `mem_issue_block_w`、registered `issue0_mem_req_valid_w`、bridge ready/valid 或
PTW/RMW continuation。否则已登记 reservation/owner 无法 drain，会自锁。

Q2 对 I-side 冻结采用 **generation-matched sticky drain-and-block**，不采用尚不存在的 fetch epoch
猜测：CAPTURE 首拍以显式 `!context_capture_block` gate 新 fetch admission、ITLB fill 与 FPC fill；
SQUASH 取消可撤回的 younger fetch；不可撤回 fetch/PTW/A-update 继续完成但在 quiet 前不得再写 FPC。
capture block 不得 gate 已登记 `ifu_axi_{ar,r,aw,w,b}` continuation ready/valid。`ifu_context_quiet`
必须精确为 outstanding/cache-fill/FPC-write 三个寄存事实的全否定归约；旧 generation ack、非 sticky
done、clear 后旧 response refill 与 capture-block 错 gate continuation 都必须有 mutation negative。

冻结 quiet：

```text
backend_context_quiet = registered reservation/buffer/MIQ empty
                        && post-squash SQ retire quiet
                        && no old terminal ingress pending

full_quiet_comb = backend_context_quiet
                  && wait_quiet_enable_after_memory_and_ifu_squash_ack
                  && mem0_registered_facts_idle
                  && ifu_context_quiet
                  && owner_tracker_live_zero
                  && terminal_collector_pending_zero
                  && no_same_cycle_epoch_ingress

registered_quiet_set = (phase == WAIT_QUIET) && full_quiet_comb
registered_quiet_clear = grant_fire || abort_fire
registered_quiet_next = (registered_quiet_q || registered_quiet_set) && !registered_quiet_clear
```

`no_same_cycle_epoch_ingress` 至少覆盖 owner alloc、SQ bind/fill、reservation/buffer capture、terminal
ingress、bridge station ingress、PTW/RMW station ingress 与 IFU/FPC fill。无效/reset 默认 epoch 可以为 0；
任何 `valid` owner capture 必须采样 `current_mmu_epoch`。同拍 grant 时 capture block 仍为 1，不能产生
新 owner、terminal 或 station ingress。

memory squash 也使用 captured identity + 无损 sticky ack。SQ/owner 完成可能错拍，也可能与新请求
同拍，因此冻结 set-dominant 方程：

```text
sq_seen_next    = (sq_seen_q    && !request_valid) || sq_done
owner_seen_next = (owner_seen_q && !request_valid) || owner_done
all_done        = sq_seen_next && owner_seen_next
ack_next        = (ack_q && !request_valid) || all_done
done            = ack_q && (captured_identity == request_identity)
```

旧的 raw `sq_done && owner_done` 与 `(ack_q || all_done) && !request_valid` 会分别丢错拍 pulse 和
请求拍即时完成，均禁止。每个真叶还必须持有 captured identity 和 registered completion；leaf
`done_o` 必须含 `!request_valid` 与 identity equality，禁止 request-valid 回声或常量。backend ingress
idle 必须是五类 ingress 的全否定 AND，owner live empty 必须是 owner/terminal count 同时为零，
context quiet 必须把这两项与 mem idle、retire quiet、memory squash done 全部 AND；OR、组合别名或
丢脉冲 ack 都不接受。

### 4.1 FENCE.I 独立序列化（不推进 data epoch）

FENCE.I 不能退化成 commit-fire 后单拍 FPC clear。它必须有独立的 prepare/squash/registered-ready
事务，并复用现有 stop/drain 的 store 排空事实：

```text
fencei_prepare_valid = head0_retire_candidate_valid && head0_is_fencei
fencei_ifu_current_done = ifu_done && (ifu_ack_generation == fencei_generation_q)
fencei_serial_ready_next = fencei_prepare_valid && mem_retire_quiet && mem0_idle &&
                           fencei_ifu_current_done && ifu_context_quiet
fencei_retire_permit = !head0_is_fencei || fencei_serial_ready_q
fencei_commit_fire = commit0_fire && head0_is_fencei && fencei_serial_ready_q
```

上述四个承重输入不能只锁 consumer：`head0_fencei_raw_w` 必须来自 canonical
`u_frontend.head0_fencei_raw_w`，`core_commit0_valid_w/core_mem_idle_w/
core_mem_retire_quiet_w` 必须来自 canonical `u_execute_backend` 同名 output。checker 同时禁止这些
host net 的 local direct/compound/concat 第二写者；这一定义的是“精确 named child output + 无
host-local override”，不冒充任意未知 child/primitive 的全网表 driver-count 证明。

`fencei_retire_permit` 必须穿过真实 wrapper 到 ROB commit0 gate；只把 ready AND 到 clear pulse 不能
防止提前退休。FetchBridge 使用独立 generation-matched sticky cancel/drain ack，FPC 只在最终
`fencei_commit_fire` 清除，旧 fetch response 在 clear 后不得 refill。该信号不得进入 Q1 request、
DTLB/ITLB typed invalidate 或 epoch next；`pending_system_fencei_commit` 也不得继续驱动 legacy 合并
`mmu_flush`。旧 store/SQ 尚未 retire quiet、IFU ack 旧 generation、FPC clear 后旧 fill、FENCE.I 误推
data epoch 都是必须失败的 directed mutation。

## 5. grant 原子边界与 dynamic epoch

grant fire 的同一边沿必须同时发生：

1. 匹配 held identity 的 commit0 fire；
2. held normalized CsrFile apply；
3. cause-mask 对应的 translation/I-side/access-provenance invalidate；
4. LR reservation clear；
5. pending/redirect 的同一 owner 清除与正确 next-PC 选择；
6. Q1 epoch `+1 mod 4`。

任一 consumer 未 ready 时 grant/payload/epoch 必须保持。不得先改 context、invalidate 或 epoch 再等退休。
结构清单必须把同一个 `grant_fire` 逐项连接到 CsrFile apply、typed translation invalidate、LR clear、
pending clear、redirect/next-PC 选择；FENCE.I invalidate 必须显式证明不依赖 data-MMU grant fire。
`grant_ready` 禁止经任何直接或间接别名依赖 permit、commit0 fire 或 grant fire；prepare effective/request
valid 也禁止依赖 request/grant ready。

“连接到 consumer”指真实、唯一且锁定实例名的 leaf，不是代理 wire或同宿主 dummy：
`u_dtlb/u_itlb/u_fetch_packet_cache/u_control_plane/u_frontend/u_redirect_arbiter/
u_fetch_pc_outstanding` 必须 exact-map。DTLB/ITLB/FPC translation clear 分别精确为
`translation_invalidate && |(cause & LEAF_CAUSE_MASK)`；FPC 最终 clear 只能为 typed translation clear
或 `fencei_commit_fire`，canonical leaf 禁止保留 legacy `mmu_flush_i`。LR 的
`reservation_valid_next=(old || set) && !lr_context_clear`，clear 必须占优。boundary redirect 必须先进入
Frontend 的 `commit_trap_*`，再经 `u_redirect_arbiter` 到唯一 `u_fetch_pc_outstanding` PC writer，禁止
直接写 `next_fetch_pc_q/fetch_req_pc_o`。pending clear 必须是
`grant_fire && payload_owner_is_pending_system`，不能用未限定 grant 无条件清另一个 owner。
trap envelope 的 `mepc/sepc/mcause/scause/mtval/stval` 与 priv/mstatus/satp/menvcfg/PMP 一样，必须
进入唯一 normalized next writer，不能被 legacy trap 提前写或在 grant 漏写。

grant 根 consumer 不是“只要依赖 grant”即可：冻结
`translation_context_invalidate = grant_fire && |grant_cause`、
`lr_context_clear = grant_fire`，以及
`held_identity = grant_payload[OOO_CONTEXT_ID_MSB:OOO_CONTEXT_ID_LSB]`。payload 的 identity/owner
字段宽度、互不重叠和 payload 内边界，以及 cause 的 one-hot 数值和 DTLB/ITLB/FPC membership OR，
都由 `define.v` concrete macro value 机器检查，不能只锁宏名。

payload 生产侧同样冻结：`CsrFile` 必须且只能有一个 continuous canonical writer
`context_payload_o[OOO_CONTEXT_ID_MSB:OOO_CONTEXT_ID_LSB] = context_prepare_identity_i`。whole-bus、
重叠 part/bit-select、未知/indexed select、shift/concat/alias RHS、任意深度 concatenated LHS、
imported/package/hierarchical task actual、procedural/compound 或 conditional/replicated-generate
写者均为 RED；明确不重叠的其他 payload 字段 writer 允许。

所有 valid producer/capture 都必须使用 `current_mmu_epoch`：

| producer/capture | valid 时要求 | 无效/reset 例外 |
| --- | --- | --- |
| owner tracker alloc0 | alloc fire 同拍采 current epoch；issue1 禁用 | invalid slot 可为 0 |
| SQ owner bind/fill0 | bind 继承 reservation epoch；`sq_fill_mmu_epoch = sq_mode ? miq_head_mmu_epoch : mem_issue_res_mmu_epoch`，且 MIQ 分支必须来自 canonical `u_mem_inflight_queue.head_mmu_epoch_o` | 空 SQ entry 可为 0 |
| `mem_issue_res_mmu_epoch_q` | reservation capture 同拍采 current epoch | reset/clear 可为 0 |
| `mem_mmu_epoch_q` | active memory owner grant/capture 保持 reservation epoch | invalid/reset 可为 0 |
| `mem_buffer_mmu_epoch_q` | buffer capture 保持原 owner epoch | invalid/reset 可为 0 |
| AMO/legacy/MIQ/bridge station | 只转发已登记 owner epoch，禁止重建常量 | invalid station 可为 0 |
| response/drop/terminal | exact echo/match owner epoch | 无 valid 时 don't-care/0 |

MIQ 的 epoch 不能只锁 head output。完整 provenance 链冻结为
`mem_req_fire_any=mem_req_valid&&mem_req_ready` → `miq_push_valid=mem_req_fire_any`、
`miq_push_mmu_epoch=mem_req_mmu_epoch` → canonical instance push ports；child 内
`push_fire=push_valid&&!full&&!flush`、`mmu_epoch_q[tail] <= push_mmu_epoch` 且
`head_mmu_epoch=mmu_epoch_q[head]`。`mmu_epoch_q` 的 packed width、实例参数与 reset/flush-compaction/push
三类完整 writer multiset、reset/non-reset arm 归属及从 exact `rst:false` 到 capture guard 的完整 ancestor
control path 都锁定；额外 outer condition、negedge/comb、reset else 之后逃逸、任意 named/conditional/
replicated/dead-generate、nested condition、nested-index alias、任意深度 concat、bare/imported/package/
hierarchical escaped task、非只读 system output actual、compound 或常量 capture 均为 RED。parent fire 在
full/flush、同拍 pop+push 和 wrap 下的 exactly-once
接受/回放仍由 directed RTL gate 证明。

modulo-4 wrap 的安全条件不是自然回绕，而是 registered quiet 已证明：live owner/terminal/station 全空，
且 grant 当拍没有 alloc、SQ bind、terminal/bridge/PTW/IFU ingress。mismatch 只能拒绝 stale response，
不能替代 transition 前 quiet。

## 6. invalidate 拆分

`OooMemoryRequestGate.mmu_flush_q` 必须拆成：

- grant-time typed translation-context invalidate；
- FENCE.I 独立 store+IFU serialization 完成后的 I-side commit invalidate（不推进 data epoch）；
- checkpoint/local flush（保持 recovery 语义）；
- selective younger memory/IFU squash（one-shot age-based，不复用 bridge level flush）。

ITLB、DTLB、PTE/PBMT attribute cache、FPC、LR 与任何缓存的 access-decision 都必须显式消费 cause mask；
不能用一个无类型 pulse 冒充完整覆盖。

## 7. 结构 checker 与 directed/mutation 硬门

`check-s2-q2-live-epoch-readiness.py` 对 release 与 `-DOOO_ASSERT` 两个 active source 变体分别预处理并
运行完整检查；canonical instance 还必须在 Icarus VVP elaborated scope tree 中从 `NpcCoreTop` 可达且
每个 named child 恰好一次，并直接位于 host module lexical scope；即使恒真 named generate 可
elaboration，也不能以局部同名实例冒充。内部承重 target、全部 frozen source、reset/clock、
instance-map signal 以及全部 required port 均要求恰好一个 host-module declaration；端口 direction/width
只能由 module header 或 non-ANSI module lexical declaration 提供，task/function 同名 port、procedural
typedef/custom-type local、range/RHS 引用或 implicit net 不能冒充声明。`clk/rst` 还必须是 lexical input
port，host assignment、subroutine output actual、unknown/child output 或 primitive 驱动均为 RED。

writer/equation 必须是 module-level unconditional；任意 named/conditional/replicated generate、dead
`if/else/case` 或 generate-for 的文本不能提供 unique-next、payload 或 dependency provenance。随后检查
模块端口、锁名唯一真实实例、精确 `[WIDTH-1:0]`、canonical expression、纯组合 dependency graph、
reset true-arm 唯一 reset literal 与 exact `rst:false` non-reset next writer（并扫描 canonical block 外
的所有 procedural/initial/continuous driver）。裸大写 reset identifier 只有在 module lexical
parameter/localparam/enum 中声明时才是常量；live uppercase input 或 task-local shadow 不能冒充。
canonical writer/capture 内嵌 `@`、`#`、`wait` 一律拒绝，`always @ signal` 也必须被识别为 procedural
span。随后检查 Q1/CSR abort 与 grant consumer、typed leaf、generation ack、FENCE.I producer/retire
permit、MIQ/SQ/owner provenance、memory 真叶、无损 sticky 聚合、payload slice、quiet/ingress 及
capture-block forbidden sinks。

组合 equation 只接受 module-scope `assign` 或合法 `wire =` net declaration assignment；`logic/reg`
initializer 不是组合方程，initializer 加 live blocking、procedural `assign/deassign`、extra/concat/task
writer，以及 unknown child/primitive output 对 audited target 的额外驱动都必须失败。unknown user
subroutine 及 system call 默认按可能 output/inout fail-closed；调用即使嵌入 assignment/expression 也要
扫描，只对白名单只读诊断调用放行。inactive `ifdef` 或 dead generate 中的 canonical dummy/equation
不能掩盖 active 错误逻辑。schema v7 除证据基线外的完整 manifest projection 由 checker 内置 SHA-256
锁定；证据基线另由 checker 和 runner 共同锚定 digest，允许明确审阅后滚动，却不能随意改 162 项
self-test 名称/顺序、当前 RED 数量或 RED 行 digest。

runner 开始时删除旧 `complete.marker`。28-path inventory 必须在 checker 读取前写入
`sources.pre.sha256`，在 readiness 完成后重算 `sources.post.sha256` 并 byte-identical；canonical
`sources.sha256` 只取后验快照。仅在 self-test、双变体 readiness、RED count/digest 与 source hash 全部
复核后重建 completion marker；它绑定 summary/readiness/rc、canonical/pre/post sources、source-check
与 checker self-test 共八类 SHA。中断、失败或运行中 source 漂移不能再把旧 summary 当作完整新证据。

`--self-test` 必须逐规则杀死 comment/dummy、同宿主 dummy、错误连接、`W:0/W-2:0` 假位宽、
非 reset 常量尾覆盖、时序延迟伪装组合依赖、lane1 self-inequality、inactive canonical、错误 payload
slice/macro mask、valid capture/SQ fill/MIQ epoch 常量、极性反转、旧 generation ack、clear-dominant
丢 pulse、宽吸收常量、ternary、legacy 常量写、scalar/多维/nested-index partial writer、local/imported/
package/hierarchical/escaped task actual、system output actual（包括嵌入 expression 的 `$sscanf(..., q)`/
unknown call）、任意深度 concatenated LHS、blocking/multiple/`always_ff`/negedge/latch/initial/continuous
writer、active-low/复合 reset、extra sensitivity、statement event/delay/wait、reset-arm/ancestor path
逃逸或错置、live uppercase reset literal、named/dead/else/case/replicated-generate equation/writer/instance、
variable initializer、unparenthesized procedural continuous assign、unknown child/primitive output、task-local
port direction/width shadow、canonical clk/rst host/child driver、declaration shadow、
FENCE producer override、payload overlap 与漏 atomic consumer 等假绿。即使结构 checker PASS，
也不得替代以下 RTL negative：

- lane1 potential boundary commit；
- younger SQ 未 squash 导致 quiet deadlock；
- SQ/owner done 错拍或请求拍即时完成被 clear-dominant 聚合丢失；
- owner 的 older/boundary/younger-unfired/younger-irrevocable 混合 age scan，STORE 只经 SQ mask 单一释放；
- IFU stale response/FPC fill 跨 grant；
- 旧 generation ack 或 one-shot done 提前进入 WAIT_QUIET；
- grant 同拍 owner alloc、SQ bind、terminal/bridge/PTW ingress；
- unused precommit/prepare/permit port 与 dummy owner instance；
- legacy CSR/trap/xRET 在 held/grant 前直接写 context，或 grant 边沿与 apply 双写；
- identity mismatch 只清 wrapper phase、未原子 abort sticky owner/held CSR reservation；
- capture block 传入 `mem_issue_block`/registered request valid；
- raw CSR write 误判 effective，locked/WARL no-op 误推进；
- apply/invalidate 早于 ROB commit 或与 epoch 不同沿；
- buffer/AMO/reservation epoch 常量；
- MIQ full/flush、同拍 pop+push 或 wrap 时 parent fire 丢失/重复，head 未回放 captured epoch；
- terminal ingress 与 epoch wrap 同拍竞争；
- FENCE.I 在旧 store/IFU drain 前退休、clear 后旧 fill，或错推 data epoch；
- stale response side effect 或重复 terminal release。

实施顺序：先 shadow 端口/断言且不改变退休 → selective squash/IFU drain → Q1 atomic grant →
SATP+SFENCE mem0 → mstatus/PBMTE/PMP/trap/xRET → dynamic epoch/stale/wrap → 全回归/Linux/PPA。

## 8. 当前裁决

当前允许声明的上界只有：`Q2 v7 contract/checker hardening checkpoint captured，live integration RED，
mem0-only，Q1 source-catalog GREEN`。v7 已把本轮审查反例编码成 active-source、精确宽度/方程、
实例名、宏值、next-state、canonical reset/event、完整 ancestor guard、module lexical binding、
module-scope continuous-driver-only、unknown child/primitive driver、generate shadow、nested selector writer、
embedded unknown/system task actual、canonical control-source ownership 及 runner pre/post source snapshot
机器门。checker self-test 为 162/162；release 与 `OOO_ASSERT` 各有 931 项预期 RED，聚合 1862 项，
RED digest `fc5baa96190e9bcac70248f912523f8ae9192045885d6023b6cb940f4675a592`，contract lock
`d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa`，baseline lock
`abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88`。completion marker 还绑定全部
证据哈希；但在对应 RTL 与 directed negative 实现前，仍不称
implementation-ready/final frozen。不得声明 context
barrier 已集成、full quiet 正确、dynamic epoch/wrap 安全、stale-response 安全、全 cause 覆盖、
双 memory、Linux 或任何 PPA 改善。
