# S2-G1 MMU epoch / barrier 只读审计（implementation RED）

> 审计性质：只读 RTL / contract source audit。
>
> 结论状态：**implementation RED**。当前 RTL 与 testbench 中均不存在真实
> `mmu_epoch` / `mem_context_quiet` 实体；`mmu_flush`、
> `priv_predictor_boundary` 和现有 `mem_idle` 均不能替代。
>
> 本文只记录 source-of-truth、反例、最小实现边界与 focused RED 建议；本次审计未修改
> RTL/测试，未运行 Linux workload、功能回归或综合。

## 1. 合同结论与唯一正确的 effective-context 来源

冻结合同 `npc/rv64/design/specs/ooo-memory-typed-abi.md:197-223` 规定：

- `mmu_epoch[1:0]` 是 translation-context generation，不是性能预测 tag；
- 只有上下文有效改变且 `mem_context_quiet` 时才推进；
- 需要推进的事件为：
  - SATP 有效值变化（line 204）；
  - SFENCE.VMA commit（line 205）；
  - PMP cfg/address 有效值变化，locked/no-op write 不推进（line 206）；
  - MPRV、MPP、SUM、MXR 有效值变化（line 207）；
  - `menvcfg.PBMTE` 有效值变化（line 208）；
  - trap/IRQ entry、MRET/SRET 导致当前 privilege 变化（line 209）；
- FENCE.I、普通 FENCE、静态 PMA 不单独推进 data-MMU epoch（lines 211-212）；
- quiet 至少覆盖 request station、bridge active owner、MIQ、LQ/SQ、已授权 nonkill
  store、LR/SC/AMO owner（lines 214-216）；
- owner 创建时捕获 epoch，request/response/SQ drain 全程 echo；mismatch 不得 WB、SQ
  fill、cache fill 或形成 architectural fault，nonkill STORE mismatch 必须 fatal
  （lines 218-223）。

S2 completion definition 进一步明确：
`.github/task-runs/2026-07-15-rv64-ppa-architecture-recovery/s2-g1-exact-owner-provenance-completion-definition.md:92-106`
禁止常量 epoch 或 raw `mmu_flush` 冒充，且 wrap 只能发生在没有旧 owner 的 quiet 边界。

### 1.1 语义上的最小有效上下文投影

```text
{
  priv_mode[1:0],
  satp[63:0],
  mstatus.{MPRV, MPP[1:0], SUM, MXR},
  menvcfg.PBMTE,
  effective pmpcfg[0:15],
  effective pmpaddr[0:15]
}
```

这只是语义投影，不应在 PPA 实现中真的构造约 1224-bit 的全局比较器。应在
`npc/rv64/vsrc/core/CsrFile.v` 内对被触碰的局部状态做 old→candidate 比较，再窄 OR：

- SATP：比较 `sanitize_satp(csr_new_value_w)` 与 `csr_satp_q`。WARL sanitizer 位于
  `CsrFile.v:468-477`，只保留 mode 0/8，其他 mode 写为零。
- PMPCFG：只比较选中的 64-bit CSR 经 `apply_pmpcfg_lock()` 后的值与旧值。
  lock/sanitize 语义位于 `CsrFile.v:258-315`；每个 locked entry 保留原值，未锁 entry
  先清 reserved bits，并把 W=1/R=0 的非法组合归零。
- PMPADDR：仅当 `!csr_pmpaddr_locked_w` 且
  `(csr_new_value_w & PMPADDR_WRITABLE_MASK) != old_selected_addr` 时成立。TOR 后继锁定
  已由 `pmpaddr_locked()` 在 `CsrFile.v:276-285` 覆盖。
- MSTATUS/SSTATUS：只比较
  `MSTATUS_MPRV | MSTATUS_MPP_MASK | MSTATUS_SUM | MSTATUS_MXR` 投影。
- MENVCFG：只比较 PBMTE；当前 `MENVCFG_WRITABLE_MASK` 本来就只有 PBMTE，见
  `CsrFile.v:86` 与写入点 `CsrFile.v:827`。
- trap/IRQ/MRET/SRET：比较对应实际 next `{priv,relevant_mstatus}`，不能只看事件脉冲。
  next-state helpers 位于 `CsrFile.v:148-211`，更新优先级位于
  `CsrFile.v:729-780`。
- SFENCE.VMA：作为独立事件源，每个合格 architectural commit 推进一次；当前命名源位于
  `npc/rv64/vsrc/control/OooCsrAccessRequestMux.v:99-101`，但现有 drain 并不构成完整
  memory-context quiet，因此当前信号只能先视为需要 hold 的 request，或必须让其最终 commit
  受新 quiet grant 门控，不能直接作为 epoch clock-enable。

合法 CSR 更新的真实总门位于 `CsrFile.v:783`：

```verilog
csr_commit_i && csr_valid_i && ~csr_access_illegal_w && csr_need_write_w
```

CSRRS/CSRRC 的 `rs1=x0` 已由 `CsrFile.v:417-430` 判为无写意图。实际存储写点为：

- PMPCFG：`CsrFile.v:784-785`；
- PMPADDR：`CsrFile.v:786-788`；
- SSTATUS：`CsrFile.v:797-800`；
- SATP：`CsrFile.v:816`；
- MSTATUS：`CsrFile.v:817-818`；
- MENVCFG：`CsrFile.v:827`。

因此下列情形必须不 bump，也不应进入 context lock：

- illegal CSR；
- CSRRS/CSRRC `rs1=x0`；
- CSRRW 写回相同有效值；
- SATP WARL 后仍等于旧值；
- locked PMP、sanitize 后同值或 PMPADDR masked 后同值；
- 只改 FS/MIE/TVM/TW/TSR 等无关 mstatus 位；
- trap/xRET 后 `{priv,relevant_mstatus}` 未变；
- FENCE.I、普通 FENCE、静态 PMA。

补充语义：trap 进入同一 privilege 时，如果它仍实际改变了 MPP，则因 MPP 本身是合同 driver，
仍应 bump；反之，只有 SPP/MIE/SIE 等无关位变化且 `{priv,relevant_mstatus}` 不变时不 bump。
MRET 即使 current privilege 未变，只要实际清除了 MPP 或 MPRV，也应 bump。多个原因在同一
architectural boundary 同时成立时只能 `+1`，不能多次累加。

## 2. 现有信号为何不能冒充 epoch driver

### 2.1 `mmu_flush_o`

`npc/rv64/vsrc/memory/OooMemoryRequestGate.v:63-76` 将以下三项注册为通用 MMU flush：

```text
pending SATP write || SFENCE || FENCE.I
```

它不能作为 `effective_context_change`，原因是：

1. 错把 FENCE.I 包含进 data-MMU epoch；
2. SATP 只看写意图，不看 WARL 后有效值是否变化；
3. 漏掉 MSTATUS/SSTATUS、PMP、PBMTE、trap/xRET；
4. head0 SATP 路径明确不产生该 flush。`npc/rv64/vsrc/core/NpcCoreTop.v:557-561`
   注释说明 head0 CSR 状态写会发生，但 SATP 的 `mmu_flush` 不在 head0 拍拉起，只依赖
   serial redirect 与 ITLB SATP tag miss。

因此可以同时构造两条反例：FENCE.I 产生 raw `mmu_flush` 但不得 bump；head0 SATP 真变化不
产生 raw `mmu_flush` 但必须 bump。

### 2.2 `priv_predictor_boundary_o`

`npc/rv64/vsrc/control/OooCsrTrapRequestMux.v:97-100` 只 OR：

```text
trap_mem || trap_ex || trap_irq || mret/sret || pending SATP || SFENCE
```

它漏掉 MSTATUS/SSTATUS、PMP、PBMTE，也没有 actual old→next/no-op 判定，只能用于 predictor
边界控制，不能作为 epoch source。

### 2.3 `pending_system_satp_write_commit_o`

`npc/rv64/vsrc/control/OooCsrAccessRequestMux.v:95-98` 只是 pending-system 路径的 SATP
写意图；它既不做 WARL/no-op 比较，也漏掉 head0 CSR 路径。

### 2.4 当前不存在真实实体

对 `npc/rv64/vsrc` 和 `npc/rv64/testbench` 的 Verilog/SystemVerilog/C++ source 搜索，当前没有
`mmu_epoch` 或 `mem_context_quiet` 命中。因此整个 epoch checkpoint 仍是结构性 RED，而不只是
少一个断言或一个测试。

## 3. 现有 quiet 信号及真实缺口

### 3.1 当前可复用的局部 quiet 分量

`npc/rv64/vsrc/execute/OooIntBackend.v:1508-1514` 当前定义：

```text
mem_idle =
    MIQ empty
 && !mem_pending
 && !mem_buffer_valid
 && !mem_issue_res_valid

mem_retire_quiet =
    SQ disabled
 || (SQ empty && !drain_inflight)
```

其覆盖关系是：

- `mem_idle`：MIQ、memory issue reservation、plain-memory buffer、legacy/AMO pending；
- `mem_retire_quiet`：SQ 与退休 store drain。

memory issue reservation 的状态与准入位于 `OooIntBackend.v:562-648`；MIQ push 与 bridge
request-station accept 同拍，见 `OooIntBackend.v:2514-2526`。

### 3.2 ROB head0 CSR 实际只等待 `mem_idle`

`OooIntBackend.v:512-516` 明确把 ROB 的 `mem_quiet_i` 接成 `mem_idle_o`，不含 SQ empty；原因是
head CSR 与 younger speculative SQ entry 若互相等待会死锁。

`npc/rv64/vsrc/writeback/OooRob.v:61-67` 的接口注释仍描述
`mem_idle && mem_retire_quiet`，但真实 hold 只消费该单一输入，见 `OooRob.v:233-249`；其断言注释
也在 `OooRob.v:529-532` 承认当前连接实际是 mem_idle-only。

这意味着不能通过简单把 `sq_empty` AND 回 `mem_quiet_i` 来补洞；必须先清退 younger
speculative store，再等待已授权 nonkill owner。

### 3.3 system drain 同样不完整

`npc/rv64/vsrc/control/OooPendingDrainResolveGate.v:57-61` 的 `backend_drained_o` 只覆盖：

```text
ROB empty && IQ empty && no synthetic pending && mem_retire_quiet
```

只有 ordinary FENCE 额外在 `OooPendingDrainResolveGate.v:88-92` 等待 `mem_idle_i`。SFENCE、xRET、
IRQ 等 pending-system 路径没有完整 data-memory quiet。

### 3.4 最大缺口：bridge 没有 idle/busy 握手

`npc/rv64/vsrc/memory/OooMemAxiBridge.v:3-55` 的模块接口没有 `idle_o` 或 `busy_o`。

关键内部 owner 包括：

- FSM `state_q`：`OooMemAxiBridge.v:120`；
- request station `stg_valid_q`：`OooMemAxiBridge.v:146-162`；
- `drop_rsp_q`：`OooMemAxiBridge.v:137`；
- `aw_done_q/w_done_q`：`OooMemAxiBridge.v:135-136`；
- `nokill_q` / `nokill_busy_w`：`OooMemAxiBridge.v:145`、`383-387`。

flush 后 bridge 的 AR/R/AW/W/B owner 不能立即消失：

- stalled AR 必须保持到 handshake，随后 drain R：`OooMemAxiBridge.v:1013-1047`；
- partial AW/W 必须继续补齐并等 B：`OooMemAxiBridge.v:1049-1072`；
- PTW A/D update 必须完成 AW/W/B：`OooMemAxiBridge.v:1075-1088`；
- request station 在普通 flush 下可被清掉，但 nokill station 项不能丢：
  `OooMemAxiBridge.v:1351-1383`。

因此存在确定的假 quiet 反例：

```text
1. 一个 AXI AR 已经形成跨拍 owner；
2. precise/global/serial flush 清掉 MIQ；
3. R 被测试平台延迟；
4. 后端出现 MIQ empty、mem_pending/buffer/reservation 全零，mem_idle=1；
5. bridge 仍处于 S_READ_DATA/S_WALK_R，drop_rsp_q=1，并等待 R。
```

此时任何把 `mem_idle` 当 `mem_context_quiet` 的实现都会提前改变上下文。

### 3.5 建议的 fail-closed quiet

在 exact-owner allocator 成为唯一 owner truth 后，建议至少为：

```text
mem_context_quiet =
    mem_idle
 && mem_retire_quiet
 && bridge_idle_registered
 && (memory_token_live_bitmap == 0)
```

其中 `bridge_idle_registered` 至少应证明：

```text
state_q == S_IDLE
&& !stg_valid_q
&& !drop_rsp_q
&& !nokill_busy_w
&& !aw_done_q
&& !w_done_q
```

`state_q==S_IDLE` 单独不够，因为 request station 可以独立占用；`stg_valid_q==0` 单独也不够，
因为 AXI/FSM 可以继续 drain。建议 idle/busy 只依赖注册状态，不形成 ready→quiet→ready 的组合环。

`reservation_valid_q`（`OooIntBackend.v:1197-1220`）是已完成 LR 留下的架构 reservation，不应
直接作为 quiet 条件，否则没有后续 SC 时会永久锁死。正确语义是：

- 活跃 LR/SC/AMO transaction/owner 必须由 issue reservation、MIQ、`mem_pending`、bridge、token
  live 状态覆盖；
- dormant LR reservation 在 context-change grant 时显式清除；后续 SC 必须本地失败，不得复用
  旧 PA/context。

IFU bridge 不应未经合同更新偷偷混进 data-MMU `mem_context_quiet`。若未来需要 fetch/data 共享
全局 epoch，应另行扩展合同、provenance 和测试。

## 4. response 端 epoch mismatch 为何仍然不够

bridge 在事务中途继续读取 live context，而非完整捕获：

- `req_priv_w` 与 translation enable 直接读取 live `priv_mode_i/mstatus_i/satp_i`：
  `OooMemAxiBridge.v:371-375`；
- DTLB hit permission 继续读取 live `mstatus_i`：`OooMemAxiBridge.v:416-420`；
- PTW leaf permission 在 `OooMemAxiBridge.v:505-512` 与 `1137-1143` 继续读取 live
  `mstatus_i`；
- DTLB lookup/fill 继续读取 live `satp_i`：`OooMemAxiBridge.v:606-624`；
- PTW root 在 `OooMemAxiBridge.v:923` 读取 live `satp_i`；
- request、walk leaf、PTE read、PTE A/D write 的 PMP checker 均读取 live PMP：
  `OooMemAxiBridge.v:626-666`、`730-760`；
- fast path classifier 使用 live PBMTE：`OooMemAxiBridge.v:682-700`；walk path 才使用捕获的
  `access_svpbmt_en_q`：`702-719`。

bridge 只在 `accept_request` 时捕获部分上下文：`paging_q/access_priv_q/access_svpbmt_en_q`，见
`OooMemAxiBridge.v:879-884`，没有完整捕获 SATP、mstatus、PMP。

因此上下文在事务中途变化时，可以形成“旧 SATP + 新 mstatus/PMP/PBMTE”的混合上下文，且
可能已经产生：

- PTW A/D PTE write；
- external AXI side effect；
- TLB fill；
- cache fill；
- 错误的 page/access fault 分类。

最后响应再发现 epoch mismatch 已经无法撤回这些副作用。epoch echo/mismatch 是 owner 完成端的
第二道防线，不能替代 context lock 与 full quiet。

## 5. 最小但诚实的实现边界

只增加一个 2-bit counter 或把 raw pulse 接到 counter 都是假完成。最小闭环至少跨以下边界。

### 5.1 `CsrFile.v`：唯一 effective-value classifier

在 `npc/rv64/vsrc/core/CsrFile.v` 内局部计算实际 old→next 的
`effective_context_change_candidate`：

- 使用与真实存储更新完全相同的 legality、write-intent、WARL、PMP lock/sanitize 与优先级；
- 不能只按 CSR address 或 commit pulse 分类；
- 相关 context state 写必须受 context-change grant 控制，不能先写状态再补 epoch；
- trap/xRET 若需要被延迟，必须保留精确 payload/next-state，单拍事件不能丢失。

### 5.2 新建唯一 epoch/barrier owner

建议新建例如 `npc/rv64/vsrc/control/OooMmuEpochOwner.v`，只有它拥有 `mmu_epoch_q` 与
context lock 状态。最小 FSM：

```text
UNLOCKED
  --true candidate/SFENCE request-->
LOCKED_DRAIN
  --full mem_context_quiet-->
COMMIT
  --context write/TLB clear + epoch increment same edge-->
UNLOCKED
```

要求：

- true candidate 出现当拍即阻断新 memory request/reservation/SQ owner capture；
- request 必须 held 到 grant，trap/IRQ/xRET/SFENCE 的一拍脉冲不能丢；
- 可杀 younger owner 先 squash/cancel；
- 已经授权的 nonkill store、部分 AW/W、PTW A/D write 必须 drain 到 terminal；
- 只有 full quiet 才授权 context state 改变，并在同一 edge 令 epoch `+1`；
- 最稳妥是下一拍才解除 lock，防止 bump edge 同时创建 owner；
- 同一 architectural boundary 的多个原因合并为一次 bump。

### 5.3 `OooMemAxiBridge.v`：显式 registered idle 与 context block

需要新增显式 registered idle/busy；context candidate/lock 同拍必须压低新请求准入。当前 request
ready 位于 `OooMemAxiBridge.v:801-812`：

```verilog
assign mem0_req_ready_o = !flush_i && !mmu_flush_i &&
                          (!stg_valid_q || stage_advance_w);
```

新 block 不得形成 `ready -> quiet -> ready` 的组合环。bridge idle 还应配套断言：idle 时不得有
AR/R/AW/W/B residual、drop state、nokill owner 或 request-station item。

### 5.4 `OooIntBackend.v`：完整 memory-owner quiet 与清退

需要：

- 输出 MIQ/reservation/buffer/legacy-or-AMO pending/SQ/drain 的完整 quiet 分量；
- context lock 时阻断 memory issue reservation、buffer、MIQ push、SQ 新 owner；
- squash/cancel younger speculative SQ/MIQ owner；
- 等待 authorized nonkill drain 与 active LR/SC/AMO terminal；
- context grant 时清除 dormant LR reservation；
- exact-owner allocator 落地后以 memory token live bitmap 守住遗漏 owner。

### 5.5 ROB / control / top：真正的 pre-transition barrier

至少需要协调：

- `npc/rv64/vsrc/writeback/OooRob.v`；
- `npc/rv64/vsrc/control/OooPendingDrainResolveGate.v`；
- `npc/rv64/vsrc/control/OooCsrTrapRequestMux.v`；
- `npc/rv64/vsrc/control/OooCsrAccessRequestMux.v`；
- `npc/rv64/vsrc/control/OooControlPlane.v`；
- `npc/rv64/vsrc/core/NpcCoreTop.v`。

当前 trap memory exception 由 `OooCsrTrapRequestMux.v:60-72` 在 ROB exception commit 时产生；
CsrFile 又在同一事件上立即更新 privilege/mstatus，而 trap flush 由
`npc/rv64/vsrc/control/OooControlFlushSequencer.v:19-30` 注册到下一拍。head0 CSR 同样是先 commit
context write，再由 serial flush 清 younger。该顺序不满足冻结的“change only at quiet”。

必须让 context-changing CSR/trap/xRET/SFENCE 先形成 barrier request，阻断新 memory，清退 younger
owner，并在 full quiet 后才提交 context state 与 epoch。若选择“先改 context、之后再 drain/bump”，
则与冻结 completion definition 冲突，不能在不更新合同 hash/provenance/test 的情况下采用。

### 5.6 head CSR + younger SQ 的死锁边界

`OooIntBackend.v:512-516` 当前故意不让 head0 CSR 等待 SQ empty，因为 younger speculative SQ
entry 可以存在，而它又不能越过 head CSR 发真实写；简单增加 `sq_empty` 会互等。

正确顺序必须是：

```text
识别 true context-change candidate
  -> 当拍 lock / block new memory
  -> squash/cancel younger speculative memory owners
  -> 保留并 drain 已授权 nonkill owners
  -> full quiet
  -> commit context state + epoch bump
```

这也是为什么独立 counter 或单个 AND gate 不是最小诚实实现。

## 6. wrap、locked、quiet 与同拍语义

### 6.1 reset / increment / wrap

- reset 初始化 epoch=0；reset 不算运行期 context change，不产生额外 bump；
- 每个获批完整 boundary 执行一次 `epoch <= epoch + 2'b01`，自然 modulo-4；
- `3 -> 0` 只允许发生在 full quiet 且 memory-owner live bitmap 为零的边界；
- 2-bit wrap 不是 stale-response 容忍机制；任何旧 response 仍存在都表示 quiet/owner accounting
  契约已破坏，必须断言失败；
- 四次连续 context change 必须每次分别经过 quiet，不能在 lock 中累计后一次跨多代。

### 6.2 lock / allocation

- true candidate 出现当拍必须防止新 owner capture；只在下一拍注册 lock 而不阻断当拍 request fire
  会留下竞态；
- bump edge 不得同时分配/capture memory owner；
- lock 保持到 context state write、TLB clear 与 epoch bump 已完成；
- unlock 后的新 owner 捕获新 epoch；
- lock 期间允许 drain killed speculative response，但禁止这些响应形成 WB/SQ/cache/fault；
- authorized nonkill STORE 不能被 drop，必须等待聚合 B terminal；
- no-op/locked CSR 不得进入 lock，也不能制造无意义 memory stall。

### 6.3 duplicate cause

同一 architectural boundary 若同时出现多个 true cause，只能 bump 一次。例如同一受控 boundary 的
context write 与 SFENCE invalidation 不能各自累加；epoch owner 应对 held cause bits 做 OR 后单次提交。

## 7. focused RED / GREEN 测试建议

S2 completion definition 的 `ID-R06` 要求 old RTL 对 effective/no-op/nonquiet change 先出现非真空
RED。建议拆成四个 focused testbench，保留唯一 marker，并要求删除 exact classifier、quiet、lock、
live-token 任一承重条件的 mutation 重新 RED。

### 7.1 `tb_csr_mmu_epoch_effective_change.sv`

覆盖 CsrFile 的 exact old→next classifier：

1. SATP：
   - valid different SATP：true，一次 bump；
   - 写相同有效值：false；
   - unsupported mode sanitize 为零：仅旧 SATP 非零时 true；旧值已零时 false；
   - illegal SATP access：false。
2. PMP：
   - unlocked PMPCFG/PMPADDR 真变化：true；
   - same value：false；
   - locked cfg/address 尝试写：false；
   - PMPCFG 部分 entry locked，仅未锁 entry sanitize 后实际向量变化时 true；
   - TOR 后继 lock 对前一 PMPADDR 生效。
3. MSTATUS/SSTATUS/MENVCFG：
   - MPRV、MPP、SUM、MXR、PBMTE 真变化：true；
   - FS/MIE/SIE/TVM/TW/TSR-only：false；
   - CSRRS/CSRRC `rs1=x0`：false；
   - CSRRW 写同值：false。
4. trap/xRET：
   - U→S、U/S→M、MRET/SRET 当前 privilege 真变化：true；
   - current privilege 不变但 MPP/MPRV 实际改变：true；
   - 只有无关 status 位变化且投影不变：false。
5. no-op/locked 事件必须证明既无 bump，也不进入 context lock。

### 7.2 `tb_ooo_mmu_epoch_owner.sv`

覆盖唯一 owner FSM：

1. `effective_context_change_req=1, mem_context_quiet=0`：请求被 held，context state 与 epoch 均不变；
2. lock 期间新 memory allocation/capture 被拒绝；
3. quiet 到达时 context grant 与 epoch `+1` 同 edge；
4. SFENCE commit request 每次恰好 bump 一次；FENCE.I/普通 FENCE 不 bump；
5. 多个 cause 同拍只 `+1`；
6. 四次 quiet change 验证 `0→1→2→3→0`；
7. bump edge 强制 allocation false；
8. 注入“旧 epoch response”并证明它在合法设计中因 live/bridge invariant 不可能存在；若强行注入则
   contract assertion 命中；
9. mutation 删除 quiet、lock、single-owner 或 wrap/live-bit 条件必须重新 RED。

### 7.3 扩展 `tb_ooo_mem_axi_bridge.sv`

1. request station：`stg_valid_q=1` 时提出 context request，bridge idle 必须为 0，状态/epoch不得变化；
2. flush/drain hole：
   - 发出 AXI AR；
   - 触发 precise/global flush 并让 MIQ 清空；
   - 延迟 R；
   - 观察旧 `mem_idle` 可为 1，但新 `bridge_idle=0`、`mem_context_quiet=0`；
   - R drain 后 bridge 才能 idle；
3. nonkill store：AW/W 已接受、延迟聚合 B，context lock 必须保持，epoch 不得提前推进；
4. partial AW-only / W-only flush：直到补齐另一通道并吸收 B 都不能 quiet；
5. PTW A/D update：AW/W/B terminal 前不得 quiet；
6. S_RESP response skid 未被上游消费时不得 quiet；
7. mutation 只看 `state_q==S_IDLE` 或只看 `stg_valid_q==0` 均应被反例击穿。

### 7.4 顶层 / backend integration

建议在 `tb_ooo_core_top_glue.sv` 或新的 focused integration TB 中覆盖：

1. head context-changing CSR + younger SQ：
   - 识别 candidate 后先 lock；
   - younger speculative SQ 被 squash/cancel；
   - 不发生 head CSR↔SQ 互等；
   - full quiet 后才写 context 并 bump。
2. precise trap + 在途 killed bridge owner：
   - trap payload 被 held；
   - 新 memory 被阻断；
   - bridge drain 后才改变 privilege/mstatus 并 bump；
   - trap redirect 不得在新 context 尚未可见时让 handler 创建 data-memory owner。
3. pending SFENCE：现有 stop/drain 不能作为 full quiet 的替身；bridge residual 存在时 commit/grant 必须
   hold。
4. LR/SC：成功 LR 后留下 reservation；context change grant 清 reservation；随后 SC 本地失败且不得
   用旧 PA/context 发请求。
5. active AMO：read/write 两阶段及 bridge B terminal 前不得 quiet。
6. combined event：同一边界多 cause 只产生一个 epoch increment。

### 7.5 两个必须保留的 raw-flush 反证 marker

旧 RTL 必须先留下两个能唯一否定“raw `mmu_flush` 冒充 effective change”的 marker：

1. **FENCE.I false-positive**：当前 `OooMemoryRequestGate.v:72-74` 会令 FENCE.I 产生
   `mmu_flush_q`，但合同要求 data-MMU epoch 不变；
2. **head0 SATP false-negative**：`NpcCoreTop.v:557-561` 明确说明 head0 SATP 状态写不产生该
   `mmu_flush`，但 SATP 有效值变化必须令 epoch `+1`。

这两个 marker 同时存在时，任何直接连 raw `mmu_flush` 的实现都无法伪装 GREEN。

## 8. 审查者反例与完成判定

实现者可能给出的三个“看似最小”方案均不能晋级：

1. **只增加 2-bit counter，driver 接 raw `mmu_flush`**：被 FENCE.I false-positive、head0 SATP
   false-negative、MSTATUS/PMP/PBMTE 漏项直接否定。
2. **把 `mem_idle && mem_retire_quiet` 重命名为 `mem_context_quiet`**：flush 后 MIQ 清空而
   bridge 继续 AXI drain 的反例直接否定。
3. **允许 context 先改变，在 response 端用 epoch mismatch 丢结果**：live mstatus/SATP/PMP/PBMTE
   已可能影响 PTW A/D write、AXI side effect、TLB/cache fill；response 时已无法撤销。

因此 checkpoint 的最小诚实完成条件是以下跨模块闭环同时成立：

```text
CsrFile exact effective-value classifier
  + pre-transition held barrier
  + unique mmu_epoch owner
  + bridge explicit registered idle
  + backend/SQ/nonkill/LRSC/AMO/token full quiet
  + epoch capture/echo/mismatch enforcement
  + wrap/live-owner assertions
  + non-vacuous RED→GREEN focused tests
```

上述任一环缺失时，只能记录 intermediate GREEN；整个 S2 exact-owner epoch checkpoint 仍必须保持
**implementation RED**。
