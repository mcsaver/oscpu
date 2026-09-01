# RV64 direct Tensor 协处理器事务合同

## 1. 状态、权限与证据边界

本文冻结 `npc/rv64` 与 `npu/version_0820` 的 direct custom-2 架构及其已实现的首个受限切片。
CPU Architect 路由结果为 `ARCHITECT`；初始只读审查合同为
`tmp/subagent-contracts/rv64-direct-npu-architect-v3.json`，声明 SHA-256：

```text
a02affbff695f77c6aa61f173cd6d28fd2f84504390c45e1783bdcd9350f49a5
```

初始裁决 `retain_for_next_slice` 已推进到一个真实 RTL implementation slice，但不是全模型 promotion：

- 已选择“按需 LO/HI pair owner + 单 ROB sidecar + exact ROB-head launch + 单命令在途 + full
  ProducerId completion + DMA terminal 后 typed D-cache invalidate”作为首个实现结构；
- `OooTensorPairOwner`、`OooTensorRobSidecar`、生产 decode/dispatch/ROB/terminal 接线和真实
  `TensorNpuCoprocessor` 系统 wrapper 已实现；当前 CONFIG 只足以建立一个 `VECTOR_F32/P00` descriptor；
- fresh 系统 Verilator 测试从 RV64 指令存储器真实取指三十条 CONFIG 和相邻 LO+HI，对成功宏事务等待 NPU
  terminal 后精确退休，对错误宏事务产生 precise exception，并验证 full ProducerId、GMEM/terminal
  backpressure 与 raw-bit 输出；
- 通用多-kernel descriptor、cacheable GMEM coherence/IOMMU、Qwen 每个 required node 经 RV64 指令发射
  仍未闭合，因此当前 PASS 只属于该 P00 slice；
- 本目标是功能实现阶段，只允许运行 Verilator 功能/周期测试；禁止综合、STA、面积、功耗和 PPA 命令；
- 下文的时序只表示相对 RTL 周期和握手先后，不是 STA 或目标频率结论。

trap+MMIO 路径仅作为 bring-up、差分定位与编译期回滚。它仍必须把主要计算交给 NPU；CPU 软件代算
required opclass 不是回滚，而是验收失败。

## 2. 初始 RV64 证据基础（实施前快照）

下表保留 Architecture Transform 作出时的只读基线，用来解释为何需要新增 pair owner、sidecar 和 exact
completion；其中“尚无/不存在”是实施前事实，不覆盖第 1 节记录的当前 P00 slice 状态。

| 对象 | 本地证据 | 当前事实 |
| --- | --- | --- |
| fetch slot/fault | `npc/rv64/design/specs/ooo-fetch-packet-decode.md` | 8-byte response 解为两个 16/32-bit slot；slot/fault provenance 已细化。 |
| packet residency | `npc/rv64/design/specs/ooo-fetch-packet-fifo.md` | FIFO 深度 4 packet，整 packet push/pop；无 slot-level partial pop。 |
| head visibility | `npc/rv64/design/specs/ooo-fetch-head-pair-gate.md`、`ooo-frontend-dispatch-gate.md` | 当前只处理普通双 lane、trap/barrier；不存在 Tensor pair owner。 |
| decode | `npc/rv64/vsrc/DecodeUnit.v`、`npc/rv64/vsrc/OooAluDecodeBackend.v` | custom-2 `7'b1011011` 未被生产 decode 接管，当前按 illegal 处理。 |
| ROB/identity | `npc/rv64/design/specs/ooo-rob.md`、`npc/rv64/vsrc/OooDispatchBackend.v` | ROB16、2-wide；ProducerId=`{generation[3:0],rob_idx[3:0]}`；completion 要求 full exact match。 |
| completion | `npc/rv64/vsrc/OooIntBackend.v` | 当前有 8 个 exact completion query、两个 WB 端口及重复 claim 排除；尚无 NPU query。 |
| irreversible launch | `npc/rv64/design/specs/ooo-memory-producer-lease.md` | `rob_head_owner_open`/`rob_head_launch_open` 已冻结不可取消 memory owner 的 head launch 资格。 |
| memory drain | `npc/rv64/design/specs/ooo-fence-drain-ordering.md` | `mem_retire_quiet`/`mem_idle` 是 older-memory drain 与外部事务静默判据。 |
| redirect/flush | `npc/rv64/design/specs/ooo-flush-redirect-contract.md` | typed recovery、严格 younger 清除以及不可回滚外部副作用已有合同。 |
| cache invalidation | `npc/rv64/design/specs/ooo-data-word-cache.md`、`npc/rv64/vsrc/core/NpcCoreTop.v`、`NpcTop.v` | 现有 `dma_invalidate_all_i` 绑定 virtio queue-notify，不是通用 NPU DMA 一致性保证。 |
| Tensor decoder | `rtl/TensorNpuCommandDecoder.v` | 无状态组合 decoder；明确要求上游先形成 32/64-bit command，不拥有 fetch/pair/ROB/flush。 |

若生产 RTL 与这些证据发生变化，必须重新核对受影响合同，不能永久复用本次只读结论。

## 3. 选定 Architecture Transform

```yaml
base:
  custom2: precise_illegal_trap
  fetch_storage: four_packet_fifo
  rob: 16_entries_2wide
  producer_id: generation4_plus_rob_index4
transform:
  primitive: [reencode_lifecycle, buffer, serialize, add_exact_completion]
  frontend: on_demand_tensor_pair_owner
  decode: one_logical_tensor_instruction
  lifetime: one_rob_owned_sidecar
  launch: exact_rob_head_after_source_and_memory_drain
  npu_concurrency: one_command_in_flight
  completion: full_producer_id_exact_query
  cacheable_dma: terminal_then_typed_full_dcache_invalidate_ack
  required_offload: fail_closed_no_cpu_software_fallback
rollback:
  compile_time: ENABLE_DIRECT_TENSOR=0
  path: precise_illegal_trap_then_mmio_npu_offload
  forbidden: switch_path_after_any_command_fire
```

该结构优先 correctness 与可证伪性：所有不可取消 NPU/DMA 副作用只允许在该事务成为 exact ROB head 后
发生。首个版本不做 speculative NPU issue，不需要 NPU 提供尚不存在的 rollback/abort transaction。

## 4. 周期与唯一 owner

相对周期定义：

- `F`：包含单字 Tensor 指令或 LO 的 FIFO head 首次可见；
- `P`：完整 pair identity 建立；同 packet 可与 `F` 同周期，跨 packet 为 `F+n`；
- `D`：一个 logical Tensor instruction 与 ROB/sidecar 同拍 dispatch fire；
- `H`：其 full ProducerId 成为 exact ROB head，source 与 memory drain 条件满足；`cmd_ready` 不属于
  该资格，也不得反馈到 `cmd_valid` 或 payload；
- `L`：`cmd_valid && cmd_ready`，第一个允许出现 NPU side effect 的周期；若 `H` 拍 ready 已高，`L=H`；
- `R`：NPU terminal response 到达；若 DMA 写 cacheable GMEM，invalidate ack 也必须完成；
- `Q`：exact completion 写 ROB 后的 commit-eligible 周期；基线最早 `R+1`。

| IR 节点 | Candidate 状态/事务 | 唯一 owner 与不变量 |
| --- | --- | --- |
| `F0` normalized word | `OooFetchPacketDecode` 继续唯一拥有 RVC 长度、slot PC、fetch fault provenance。 | Tensor 逻辑不复制长度 decoder，只消费规范化 32-bit slot。 |
| `F1` packet/residual | `OooFetchPacketFifo` 保持整 packet；`TensorPairOwner` 只在合法 LO role 时按需接管。 | 一个 word 只能属于 FIFO/head pending、pair owner 或 post-HI residual 之一。 |
| `P0` pair identity | `{pc_lo,pc_hi=pc_lo+4,lo,hi,epoch,fetch_provenance}`。 | HI 必须紧邻、同 epoch、未被 redirect/flush；禁止按 opcode 相似度越过中间 word 配对。 |
| `P1` same packet | slot0=LO、slot1=HI 时形成一个 logical dispatch。 | ROB allocate=1、retire=1、next PC=`pc_lo+8`；HI 不可成为第二 ROB entry。 |
| `P2` cross packet | slot1=LO 可在前一 slot0 独立 fire 后保存；下一 packet slot0 只能被验证为 HI，slot1 进入 `post_hi_residual_q`。 | next packet slot1 不丢失、不重复；mismatch word 保留给正常 decode。 |
| `P3` pair fault | HI fetch fault归属于从 `pc_lo` 开始的未发 Tensor 事务；孤立 HI/直接 branch 到 HI 在 HI PC illegal；LO 后 mismatch 使 LO illegal并保留 next word。 | 所有 mismatch/fault 路径 `npu_cmd_fire=0`。mismatch=`illegal`、`epc=pc_lo`、`tval=zero_extend(lo)`；HI fetch fault保持page/access分类、`epc=pc_lo`、`tval=precise fault VA`。 |
| `D0` logical decode | `OooAluDecodeBackend` 附近增加专用 Tensor sideband，不把 LO/HI伪装为两个 ALU uop。 | Tensor sideband与 precise illegal owner二选一。 |
| `D1` required metadata | `npu_required`、`opclass_id`、command width、PC/next-PC随 dispatch 进入 sidecar。 | required事务不能转换为 CPU软件算子；unsupported/error只能trap/报错。 |
| `R0` ROB sidecar | `TensorRobSidecar`与ROB allocation同拍保存full ProducerId、command、source identity、PC、opclass、epoch、sent/terminal。 | 不允许只保存ROB index；sidecar必须进入producer-live/reuse约束。 |
| `R1` operand | 保存renamed source identity/ready，复用PRF/wakeup，不假定新增architectural RF组合读。 | serialization不能阻断其等待的older producer completion；实际port owner仍是实现GAP。 |
| `S0` serialization | Tensor在`D`建立后阻止所有younger dispatch，直到terminal/commit/trap；older ROB/IQ/memory继续drain。 | 不能阻止older response、NPU response或completion crossbar，否则会形成自锁。 |
| `L0` head launch | exact PID=head、`rob_head_launch_open`、source ready、`mem_retire_quiet`与`mem_idle`构成完整 launch eligibility；WAIT 当拍直接驱动 valid。 | ready=1 时同沿 fire→SENT；ready=0 时同沿锁存 prospective source 并进入 OFFER skid。`L`前可kill且零side effect；`L`后`sent_q`不可清。 |
| `L1` command owner | sidecar唯一驱动`cmd_valid/cmd_bits/cmd_rs_value/cmd_is_64/npu_required/opclass_id/ProducerId`。 | valid/payload 均不依赖 ready；WAIT→OFFER 边界及 OFFER backpressure 期间 payload 全稳定；每个 PID 最多一次 fire。 |
| `M0` memory order | launch前drain older CPU memory；NPU在途阻止younger memory；cacheable DMA写terminal后请求typed invalidate。 | invalidate ack前不可给ROB completion；不得把virtio专用pulse直接复用为证明。 |
| `C0` completion | NPU terminal成为第9个full ProducerId exact query，进入同PID duplicate-claim与两个WB端口仲裁。 | 只有`valid&&!done&&full_pid_match`可置ROB done；recycled slot或late mismatch只drain。 |
| `Q0` retire | completion只完成一个matching ROB entry；64-bit pair next-PC=`pc_lo+8`。 | logical command恰好一个instret；错误只在exact head可见。 |

## 5. Pair/sidecar 状态机

```text
NORMAL
  ├─ single-word TCR/config/sync ────────────> SINGLE_READY
  ├─ same-packet valid LO+HI ────────────────> PAIR_READY
  └─ older slot0 fire + slot1 LO ────────────> WAIT_HI

WAIT_HI
  ├─ next slot0 == matching HI @ pc_lo+4 ───> PAIR_READY
  ├─ next slot0 mismatch ────────────────────> TRAP_LO_KEEP_NEXT
  ├─ next slot0 fetch fault ─────────────────> TRAP_PAIR_FAULT
  └─ redirect/flush kills LO ────────────────> NORMAL

TRAP_LO_KEEP_NEXT / TRAP_PAIR_FAULT
  ├─ exact pending-trap capture grant ───────> PENDING_ARCH_TRAP
  ├─ backpressure ───────────────────────────> hold {pc,cause,tval}
  └─ typed/global flush ─────────────────────> NORMAL

PAIR_READY / SINGLE_READY
  ├─ ROB allocation && sidecar allocation ──> SERIAL_WAIT_HEAD
  ├─ backpressure ───────────────────────────> hold identity/payload
  └─ kill before dispatch fire ──────────────> NORMAL

SERIAL_WAIT_HEAD
  ├─ exact head + source + drain + ready ────> SENT (direct fire)
  ├─ exact head + source + drain + !ready ───> OFFER_SKID
  └─ exact recovery kill before launch ──────> NORMAL

OFFER_SKID
  ├─ ready ─────────────────────────> SENT
  ├─ !ready ────────────────────────> hold stable payload
  └─ exact recovery kill before fire ──────> NORMAL

SENT
  ├─ exact terminal + live ROB + WB credit ──> ROB_DONE（同边沿清 Sidecar owner）
  ├─ exact terminal + stale ROB query ───────> direct stale-drop（零 ROB/WB 写）
  ├─ exact terminal + WB denied ─────────────> COMPLETION_PENDING
  ├─ mismatched terminal ────────────────────> drain stale beat，retain SENT
  └─ younger redirect / deferred IRQ ────────> retain owner and drain

COMPLETION_PENDING
  ├─ exact completion crossbar fire ─────────> ROB_DONE
  └─ WB backpressure ────────────────────────> hold full completion payload
```

PairOwner 不增加第三个 trap holder：`error_valid && capture_grant` 的同一边沿清 PairOwner/residual，并由既有
`OooPendingTrapExitSequencer` 建立唯一 `pending_arch_trap` owner；grant 不依赖 FIFO residency 或
`can_run`。优先级：reset > terminal response/drain > typed recovery > completion acceptance > new launch >
new dispatch。
同一事务在任一周期只有一个状态 owner，禁止 frontend pending、sidecar和completion holder同时宣称可清除。

## 6. 六类接口合同

| 类别 | Owner/触发 | 保持规则 | 禁止事件 | Verilator oracle |
| --- | --- | --- | --- | --- |
| handshake/backpressure | pair owner、sidecar、NPU wrapper、completion holder；分别以dispatch/cmd/WB fire为转移点 | pair valid未fire时PC/LO/HI/fault稳定；`cmd_valid&&!cmd_ready`时全部payload与PID稳定；WB busy时completion稳定 | valid组合依赖ready；backpressure期间换PID/payload；重复fire | `$stable(payload)`；每PID fire≤1；pair/ROB/sidecar allocation计数同拍相等 |
| stall/serialization | `TensorSerialOwner`从`D`到terminal/commit/trap阻止younger dispatch | older completion、store/AXI/NPU response和WB arbiter必须继续推进 | Tensor stall阻断自身等待的older producer；NPU busy时改CPU算 | `tensor_wait_head/drain/npu_busy/serialize_cycles`；response最终返回假设下bounded progress |
| flush/redirect | frontend typed recovery清pre-dispatch pair；ROB age/full PID清prelaunch sidecar；post-launch lease保留owner | `L`前严格按epoch/age清除且零fire；`L`后请求只drain一次 | wrong-path fire；flush清已发DMA owner；PID terminal前复用 | LO capture、HI capture、dispatch后、launch前分别注入redirect；`L`后注入younger redirect/IRQ |
| exception/retire | pairer负责pair/fetch异常，ROB负责exact head，NPU负责terminal error | 64-bit pair一个ROB entry/PC/commit；unsupported/error fail-closed；HI无独立retire | malformed pair部分副作用；error透明CPU代算；old PID完成new generation | alloc/fire/commit/instret delta各1；next-PC+8；错误路径fire=0或terminal error后exact trap |
| DMA/cache/order | serial owner、NPU master arbiter、memory drain owner、typed Dcache invalidate owner | launch前older memory terminal；NPU在途无younger memory；DMA写terminal→invalidate request→ack→ROB completion | cacheable DMA无invalidate；invalidate前younger load；`mem_idle=0` launch | older store→NPU read；cache预热→NPU write→younger load新值；移除invalidate mutation必须失败 |
| speculative recovery | full PID、epoch、live、`sent_q`与ROB age owner | prelaunch kill零请求；post-launch owner到terminal；PID mismatch只drain不WB | 只比ROB index；sidecar不进入live mask；late response完成recycled entry | ROB wrap/generation reuse；old PID与new same index；EX/MEM/NPU同PID claim排他 |

## 7. precise trap、IRQ 与不可取消事务

1. reset可同步清CPU/NPU。若最终存在不同reset domain，reset后response必须由epoch丢弃且不得architectural WB。
2. `L`前branch/full flush可清pair/sidecar，并必须证明从未发生command fire。
3. `L`后command/DMA不可取消；该事务已是exact ROB head，younger recovery不能撤销其副作用。
4. MVP对`L`后到达的external interrupt/debug trap选择延期apply，直到NPU terminal、invalidate ack和exact
   completion。除非未来NPU提供可证明所有TCR/LMEM/GMEM副作用回滚的abort+ack，否则不能抢占。
5. malformed pair在launch前通过既有 pending-trap/drain/CSR 主干产生precise trap：mismatch映射
   `illegal instruction`，`epc=pc_lo`，`tval=zero_extend(lo)`；HI fetch fault保持 instruction
   page/access fault分类，`epc=pc_lo`，`tval`为精确失败取指VA。已发bus/NPU terminal error仍须先drain，
   再以匹配PID在head报错；这部分typed error ABI仍是GAP。
6. required opclass遇到unsupported、NPU unavailable、timeout或terminal error不得调用CPU版kernel继续运行。

## 8. DMA/缓存顺序的两个允许配置

### 8.1 cacheable physical GMEM

- launch要求`mem_idle && mem_retire_quiet`；
- 所有older CPU store已达到现有ordering合同的terminal/visible点；
- Tensor在途阻止younger memory issue；
- NPU terminal表示全部AXI read/write及response均已完成；
- 若NPU可能写GMEM，产生专用`npu_dma_invalidate_all`；
- Dcache返回`invalidate_applied`后才允许exact ROB completion。

### 8.2 硬件解码的non-cacheable GMEM window

- 地址decoder必须证明该region永不进入Dcache；
- 仍需older memory drain与Tensor在途younger memory阻塞；
- 可省略Dcache invalidate，但不能靠软件习惯把普通cacheable地址当作non-cacheable。

不存在第三种“任意cacheable地址、软件可能会clean/invalidate”的宽松模式。首版若无法完成typed invalidate，
必须把GMEM硬限制在经过负向测试的non-cacheable窗口。

## 9. Qwen required-offload 合同

### 9.1 分类

- 所有TIU、GDMA以及runtime冻结清单内的Qwen heavy opclass设置`npu_required=1`；
- TCR/config/sync属于NPU control，不能用它们冒充主要计算offload；
- CPU只允许执行manifest白名单中的tokenization、sampling、shape/index、循环/调度和小型标量控制；
- attention/FFN/LM-head的矩阵计算、Gated DeltaNet中映射为重型Tensor kernel的计算不得CPU代算。

具体`opclass_id`编码、Gated DeltaNet state/conv边界、normalization/activation是否由现有Tensor ISA原语覆盖，
必须由runtime映射切片冻结；不能由CPU RTL猜测。

### 9.2 计数点

- `npu_required_issued`/`npu_offload_count`：只在真实`cmd_valid&&cmd_ready`时递增；
- `npu_required_completed`：terminal成功且full PID匹配时递增；
- `npu_commit_count`：对应Tensor ROB entry exact commit时递增；
- `offload_by_opclass[]`：真实fire按冻结类别统计；
- `cpu_fallback_major_ops`：required runtime/backend进入CPU软件实现时递增；
- `npu_error_by_opclass[]`：unsupported/timeout/bus/descriptor错误分栏。

固定Qwen测试必须满足：

```text
cpu_fallback_attempts == 0
host_tensor_arithmetic == 0
npu_required_issued == expected_manifest_required_issued
npu_required_completed == expected_manifest_required_completed
offload_by_opclass[] == expected_manifest_by_opclass[]
npu_commit_count == expected_manifest_committed
```

只检查`npu_offload_count>0`会漏掉“仅offload少数算子、大部分仍由CPU计算”，禁止作为验收判据。

## 10. 实现 footprint

实现前须用新合同再次核对实际端口；预期受影响对象如下：

- frontend：`OooFrontend*`、`OooFetchPacket*`、head/pending/dispatch gates，新增按需pair与residual owner；
- decode：`OooAluDecodeBackend.v`，新增custom-2 Tensor logical-instruction sideband；
- dispatch/ROB：`OooDispatchBackend.v`、`OooRob*`，新增full-PID Tensor sidecar allocation/live/done；
- control：新增younger serialization、post-launch IRQ defer和typed recovery规则；
- completion：`OooIntBackend.v`新增第9个exact query/holder并进入两个WB端口仲裁与duplicate-claim checker；
- memory/cache：`NpcCoreTop.v`、`NpcTop.v`、Dcache/memory bus增加NPU master与typed invalidate request/ack；
- NPU：完整top、command holder、terminal/error、MM2/GDMA/GMEM master与reset/epoch接口；
- runtime：Qwen operator dispatch、raw `.insn`/编码发射、required-op manifest及CPU fallback instrumentation。

不得在一个不可归因切片中同时实现全部footprint。建议顺序是：pair/sidecar无副作用骨架 → fake terminal
completion → real NPU command handshake → memory/DMA ordering → runtime required-op enforcement。

## 11. 定向 Verilator 与 mutation 计划

### 11.1 pair/fetch

- same packet LO slot0 + HI slot1；
- 普通slot0、LO slot1、下一packet slot0=HI且slot1为post-HI residual；
- LO后same/cross-packet mismatch、branch target直接进入HI、HI fetch page/access fault；
- pair trap与IRQ/head fault同拍优先级、已有commit trap/stop/flush拒绝grant、空FIFO且`can_run=0`仍capture；
- pair error handoff后stop/drain/CsrFile精确采样一次，C1 owner clear、C2不重复；
- LO capture、HI capture、PAIR_READY、dispatch backpressure各点注入redirect；
- ROB/sidecar full和`cmd_ready=0`时payload稳定。

### 11.2 ProducerId/completion

- 相同ROB index、不同generation的旧completion；
- EX/MEM/NPU同周期竞争WB；
- completion holder在WB backpressure期间稳定；
- compile-success mutation：删generation compare、绕exact query、允许同PID重复claim，均须被checker拒绝。

### 11.3 memory/recovery/progress

- older CPU store→NPU DMA read；NPU DMA write→younger CPU load；cache预热旧值后NPU写；
- launch前kill、launch后younger mispredict、NPU busy期间IRQ、completion backpressure；
- mutation：删invalidate、允许younger memory提前issue、允许`mem_idle=0` launch；
- 在所有NPU/AXI response最终返回的假设下验证bounded progress。

### 11.4 required offload

- 固定Qwen operator trace与expected opclass manifest；
- unsupported/error必须trap；
- 启用CPU GEMM/attention fallback的mutation必须令验收失败；
- 跳过一个required command的mutation必须由exact manifest mismatch捕获。

### 11.5 仿真归因 observer

- `CONFIG_NPC_OOO_STATS` 对 `CONFIG_NPC_SIM_STATS` 有最小构建闭包：Kconfig 和 direct-system 脚本显式选择两者，
  `NpcSimTop.sv` 与 production C++ translation unit 也允许只定义 OOO 时自动补齐 SIM，禁止留下编译成功但
  DPI/link 缺符号的半配置；
- observer 保留原七个 32-bit cumulative 字段：
  `issued/terminal/completion/wait_head/wait_drain/npu_backpressure/serialize`。其中 lifecycle 三计数与
  `serialize` 是总量，`wait_head/wait_drain/npu_backpressure` 是 legacy coarse diagnostics；这七路不是
  one-hot partition，legacy `unattributed` 只表示从 `serialize` 扣除三个 coarse bucket 后的余量，不能解释成
  一个独立 stall reason；
- 在旧七路之后增加一个 32-bit cumulative event：`alloc_direct_issue`。它只统计 EMPTY owner 的实际
  allocation-edge command fire，必须满足 `alloc_direct_issue<=issued`；它不是 owner-cycle attribution class，
  不参加十九类之和；
- `CONFIG_NPC_OOO_STATS` 下 Sidecar 另有十九个 32-bit、只读、one-hot attribution cumulative 寄存器，DPI/debug
  ABI 必须严格按以下顺序在 `alloc_direct_issue` 之后追加，不得重排旧七路或该 event：
  `prelaunch_cancel`、`wait_not_exact_head`、`wait_launch_gate`、`wait_src_dependency`、`wait_src_value`、
  `wait_mem_active`、`wait_mem_retire`、`launch_to_offer`、`offer_backpressure`、`offer_accept`、
  `sent_terminal_absent`、`sent_terminal_stale`、`sent_terminal_accept`、`complete_wb_backpressure`、
  `complete_stale_drop`、`complete_wb_accept`、`invalid_state`、`sent_terminal_completion_stale`、
  `sent_terminal_wb_accept`。最后两类分别表示 exact terminal 令 completion channel 发生 valid/ready accept、但
  ROB query mismatch（零 WB、零 `completion_count`），以及 exact terminal 同拍完成正式 WB；若 WB credit 被拒，
  仍归 `sent_terminal_accept` 并捕获到 resident COMPLETE skid。分类读取当前
  pre-edge owner state 与同一拍的
  prospective handshake/source facts；eligible WAIT 的 ready-low 拍归 `launch_to_offer`，ready-high 直发归
  `offer_accept`，resident OFFER 的 ready-low 拍才归 `offer_backpressure`。每个 `owner_valid` active CPU edge
  必须且只能命中一类，所以十九路 64-bit extended sum 必须严格等于 `serialize`。同一 direct-WB owner edge虽然
  同时增加 `terminal_count` 与 `completion_count`，one-hot partition 中只计入组合类
  `sent_terminal_wb_accept` 一次。legacy
  `npu_backpressure` 仍保持原 `cmd_valid&&!cmd_ready` 定义，并严格等于
  `launch_to_offer + offer_backpressure`，没有重定义旧 ABI；
- lifecycle 与组合分类还必须满足三条 modulo-`2^32` 守恒式：
  `offer_accept==issued`；
  `sent_terminal_accept+sent_terminal_completion_stale+sent_terminal_wb_accept==terminal`；
  `complete_wb_accept+sent_terminal_wb_accept==completion`。direct stale 属于已接收 terminal、但不属于正式
  completion；direct WB 同时贡献 terminal 与 completion，但只占 one-hot partition 的一个 owner edge；
- cycle DPI 的旧七路、一个 direct event 和十九路 attribution 参数保留给 direct harness，其 active-region 值
  天然早于同边沿 NBA；production `VNpcSimTop` 则通过仿真 wrapper 专用的二十七个 debug outputs，在每次
  `eval_half_cycle(1)` 返回后采
  post-NBA snapshot。两条路径均不增加生产数据通路端口，也不改变 dispatch、transaction、recovery、PRF
  或 WB 行为；
- production host 不连接 direct-NPU transport；模型构造后、首次 reset/eval 前必须把
  `cmd_ready` 及全部 terminal 输入显式置零。production 的 DPI callback 不得用旧一拍 Tensor 参数覆盖
  post-eval snapshot，结束报告也不得为刷新统计而增加 guest cycle；
- production host 对二十七路 32-bit snapshot 分别做 modulo-`2^32` epoch extension，每个 active edge 的
  `uint32(raw-last)` 增量累加进独立 64-bit 值，并在 reset 后同步清扩展状态。direct-system harness 对 DPI 的
  二十七路 cumulative snapshot 也使用各自独立的同类 epoch extension；它仍以一个 stats-on/off 共同的
  observation edge 刷新 active-region snapshot，该 edge 仅属于定向 wrapper oracle，不是 production 收尾协议；
- stats-off/stats-on 必须使用相同 source/config/input，ordered command/terminal/commit、全部功能 oracle 与模拟
  cycle 完全相同；任何 architectural trace 或 cycle 改变都视为 observer 侵入并回滚；
- 当前固定系统定向在最后一次 reset 后要求
  `issued=terminal=completion=95`、两个 count gap 均为 0、
  `serialize >= wait_head + wait_drain + npu_backpressure`；
- `NpcTensorNpuSystemTop` 会在 descriptor inflight 期间关闭 CPU 子模块时钟，因此 Sidecar 的
  `serialize` 只表示 CPU active-clock cycles。系统 TB 必须独立同时报告 `system_serialize` 和
  `clock_gated_gap=system_serialize-active_serialize`；不得把 active-clock 数直接解释为系统 CPI 或 NPU latency；
- WAIT fall-through 实施前的同源 baseline，其 stats-off/stats-on 均为 5342 system cycles；stats-on 观测为
  `95/95/95`、`active_serialize=384`、`system_serialize=934`、`clock_gated_gap=550`。
  `wait_head/wait_drain/cmd_backpressure` 在该 case 均为 0，所以 384 拍全部落入 `unattributed`；它混合
  source/launch-open、SENT terminal wait 与 completion/WB wait，不能在未细分前当作单一瓶颈或直接据此实现
  younger speculation。新 one-hot attribution 的同一 fresh run 精确分布为：
  `launch_to_offer=95`、`offer_accept=95`、`sent_terminal_absent=4`、`sent_terminal_accept=95`、
  `complete_wb_accept=95`，其余十四类均为 0，总和 `384==active_serialize`；direct harness 将该分布与
  `sum==serialize` 冻结为 executable oracle。这里的 384 仍只是 CPU active-clock owner edges；934 才是 wrapper
  在系统时钟上看到的 serialize 区间，二者都不是 NPU kernel latency 的替代度量。该 observer 只提供归因证据，
  不形成 frequency、area、power、PPA 改善结论。
- 在该 baseline 上加入有界 `WAIT fall-through + OFFER skid` 后，fresh stats-off/stats-on 都为 **5340** system
  cycles，ordered command/terminal/commit 与全部功能 oracle 不变。stats-on 精确观测为
  `issued=terminal=completion=95`、`active_serialize=289`、`system_serialize=839`、`clock_gated_gap=550`；one-hot
  分布为 `offer_accept=95`、`sent_terminal_absent=4`、`sent_terminal_accept=95`、
  `complete_wb_accept=95`，其余十五类（含 `launch_to_offer`、`offer_backpressure`、`invalid_state` 及两个
  direct-terminal 类）均为 0，
  总和 `289==active_serialize`。因此候选确实消除了 95 个 WAIT→OFFER active 边界，但固定 workload 总周期只
  改善 2 拍；active owner edge 或 system serialize 的 95 拍下降不能换算成 95 拍 CPI 收益。direct harness
  将 `cycles=5340`、`system_serialize=839` 与 `clock_gated_gap=550` 一并冻结为 executable oracle，使
  stats-off 周期或 wrapper clock-gating 行为的后续漂移不能静默通过。
- 该候选把 exact-head/launch-open/prospective-source/memory-drain 资格与 prospective source bypass 延伸到
  `cmd_valid/payload` 的组合锥。ready 未反馈进 valid/payload，OFFER 仍隔离 backpressure，但该新增组合锥的
  实际 delay、fanout 与布线是 **physical GAP**；当前合同禁止综合/STA/PPA，所以这里只记录功能/周期实测，
  不声称频率、面积、功耗或 PPA 改善。
- 在上述 WAIT 候选上继续加入有界 `matched terminal → completion/WB fall-through + COMPLETE fallback/skid +
  direct stale-drop` 后，fresh stats-off/stats-on 都为 **5339** system cycles，ordered command/terminal/commit 与
  全部功能 oracle 不变。SENT 期间以 `sent_o` 对第 9 路 ROB completion query 做 side-effect-free 提前查询；真正
  的 WB claim 仍由 exact `completion_valid` 门控，`terminal_ready` 仍只依赖 registered SENT state，不读
  `completion_ready`。exact terminal 遇到 live ROB 和 WB credit 时同边沿正式 WB 并清 owner；WB denied 时将同一
  full-PID/error payload 捕获到既有 COMPLETE skid；ROB stale 时同边沿只发 stale-drop，禁止 WB/ROB 写。
- 该 terminal 候选的 recovery-window stats-on 精确观测为
  `issued=terminal=completion=95`、`active_serialize=194`、`system_serialize=744`、`clock_gated_gap=550`；十九类
  one-hot 分布为 `offer_accept=95`、`sent_terminal_absent=4`、`sent_terminal_wb_accept=95`，其余十六类均为 0，
  总和 `194==active_serialize`；legacy `wait_head/wait_drain/npu_backpressure` 三项也逐项冻结为 0。分类累计
  timing signature 为：91 条 CONFIG 的
  `issue→terminal/terminal→commit/issue→commit=91/0/91`，3 条合法 macro 为 `557/0/557`，1 条错误 macro 为
  `1/0/1`，并且 `terminal_commit_same=95`、`commit_next_issue_same=0`。
- 上述 95 个 direct-WB owner edges 只把全程固定系统周期从 5340 降到 5339，不能解释为 95 拍 CPI 收益；相邻
  Tensor 命令之间已有约 32–36 拍程序/前端 slack，大多数局部边沿被吸收。系统 TB 现在同时冻结
  `pre_recovery=1219`、`recovery=4120`、`total=5339`；前者在第二次 reset 解assert前采样，后者包含解assert后的
  recovery 与末尾共同 observation tick。它明确全程 cycle 覆盖 reset-abort 与 recovery 两阶段，而 Sidecar
  observer 在第二次 reset 后清零、只覆盖 recovery。`194/744` 仍是 owner occupancy 证据，不是 wall cycle。
- terminal fall-through 新增长组合逻辑由两条并行锥汇合：registered SENT/COMPLETE owner + full PID 提前驱动
  completion8 的 Q-only ROB query/match；external terminal valid + full-PID/payload 独立驱动 completion
  valid/payload；二者再与 WB availability/claim 汇合并写 ROB D。提前 query 缩短了 terminal-valid 控制串链，
  但没有消除 terminal 到 ROB D
  的实路径；因此其 delay、fanout、布线、频率和 PPA 仍是 **physical GAP**。本阶段禁止综合/STA/PPA，当前仅能
  把它保留为 correctness + fixed-cycle 实验候选，不能宣称物理晋级。
- 在 terminal 候选上继续加入 **edge-old ROB empty-only allocation→command fall-through** 后，fresh stats-off
  与 stats-on 均为 **5337** system cycles，固定 phase 为
  `pre_recovery=1218`、`recovery=4119`。相对 5339 基线，两阶段各减少 1 拍；95 条 command/terminal/commit
  顺序、critical timing signature、GMEM cardinality 与全部功能 oracle 不变。stats-on 精确观测为
  `issued=terminal=completion=95`、`alloc_direct_issue=4`、`active_serialize=194`、
  `system_serialize=744`、`clock_gated_gap=550`；十九类分布仍是
  `offer_accept=95`、`sent_terminal_absent=4`、`sent_terminal_wb_accept=95`，其余十六类为 0，
  总和 `194==active_serialize`。这说明只有 4 个 allocation-edge fire，但它们命中了 reset-abort 与最终
  bad-macro 等 wall-critical endpoint；不得把 4 次 event 解释为 4 拍收益，也不得把其余 91 次 fallback
  误报为 direct。
- direct authority 必须来自显式、已驱动的 `OooDispatchBackend.rob_empty_o`，不能以未驱动局部 wire 或
  `!rob_head_valid` 推断。它还同时要求 actual Tensor allocation fire、checkpoint/restore/flush/branch/control
  barrier 全部关闭、source value 确实来自 x0/is64 或同拍 matching WB、`mem_idle&&mem_retire_quiet`；
  `cmd_ready` 不参与 valid/eligibility。ready-low 必须捕获到 OFFER，ready-high 必须同沿进入 SENT；非命中项
  原样进入 WAIT。`alloc_ready` 与 registered owner/live mask 均不得引入组合 bypass。
- allocation fall-through 新增从 dispatch/ROB-empty/prospective PID/source wake/memory facts 到 external command
  的组合锥。当前功能与 fixed-cycle A/B 不能证明其 delay、fanout、布线、频率或 PPA，因此仍是
  **physical GAP**；本轮没有运行综合、STA 或 PPA，也不得据此宣称物理优化晋级。
- **拒绝：committed-GPR allocation direct 候选。** 一次性 A/B 把
  `alloc_direct_issue` 从 4 提高到 95，但 stats-off/stats-on 的 total 仍为 5337，
  critical signature、phase、ordered command/terminal/commit 与功能 oracle 均未移动。
  它扩大 prospective committed-GPR value 的组合可见范围，并带来约 2048-bit 级宽数据
  选择/布线风险；在零固定-workload CPI 收益且无综合/STA/PPA 证据时已精确回滚，不进入合同。
- **拒绝：typed exact-NOP residual terminal-release 候选。** fixed workload 中共有
  `30 + 3*30 + 1 = 121` 个 slot0 CONFIG + raw 32-bit `0x00000013` packet。对 immutable
  baseline/candidate binary 的一次性 commit trace 表明，两边均为 495 条完全相同的
  `(pc,inst)` 序列；恰好 121 条 follower NOP 各提前 1 拍，其余 374 条（包括每个下一 load、
  Tensor issue 与最终 endpoint）全部不变，total 仍为 5337。该候选只消费 C0 lane1/Q-only
  commit 到 C1 dual-dispatch 之间的既有 slack，未缩短 wall-critical path，故已精确回滚。
- **保留：F32 non-last write-response turnover。** 3 条合法 16-element macro 各消除
  15 次中间 `ELEMENT_PREP`，system oracle 以 `3*(16-1)=45` 冻结节省：total
  `5337→5292`，recovery `4119→4074`，macro issue→terminal 总和 `557→512`，
  `system_serialize 744→699`、`clock_gated_gap 550→505`。stats-off/stats-on 均为
  5292 cycles；CONFIG/error timing、95 条 command/terminal/completion、active attribution
  194、GMEM `144=96 read+48 write` 与全部功能结果不变。该 45 拍真实落在 system critical
  serial region，因此保留；carry/mux→modulo/multiply 新组合链、投机翻转及综合器复制仍是
  未经综合/STA/power 证明的 **physical GAP**。
- **保留：F32 child-response→GMEM shadow-write direct。** normal matching child
  response 使用唯一 result/current-dst→shift/strobe/legality payload 网络；GMEM
  ready-high 时在同一边沿清 child owner、接受 GMEM write owner并进入 `WRITE_WAIT`，
  ready-low 时仍消费 response，把完全相同的 payload 捕获到既有 q，下一拍由
  `WRITE_REQ` 持有。direct/fallback 的 valid/payload 不依赖 ready，ready 只决定 fire；
  优先级固定为 `protocol/owner fault > command timeout > phase timeout > normal response`。
  illegal payload 不得形成 direct fire/owner，并在 registered legality check 以
  `ERR_INTERNAL_STATE` fail-closed。focused final3 冻结
  `direct-elements=16`、`fallback=1`、`max_owner=1`。
- 该 direct 变换在 turnover-only 的 5292 上再省 `3*16=48` 拍；相对 5337 baseline
  累计公式为 `3*(16-1)+3*16=45+48=93`。stats-off
  `rv64-direct-npu-system-20260831T235327-690143` 与 stats-on
  `rv64-direct-npu-system-20260831T235327-690173` 均冻结：total `5292→5244`
  （累计 `5337→5244`）、pre-recovery 保持 `1218`、recovery `4074→4026`
  （累计 `4119→4026`）、macro issue→terminal `512→464`（累计 `557→464`）、
  `system_serialize 699→651`（累计 `744→651`）、`clock_gated_gap 505→457`
  （累计 `550→457`）。GMEM `144=96 read+48 write`、active attribution `194`、
  CONFIG/error timing、95 条 command/terminal/completion 与功能结果不变；C++
  executable oracle 以 `kF32SavedCycles=3*(16-1)+3*16` 统一冻结 macro、phase、total、
  serialize 与 gap。
- child-direct 取得 5244-cycle A/B 时，该性能阶段的 F32 RTL/TB snapshot SHA-256 为
  `b306baea35779b08877b7619dd0320b0ce61b056eb57fe926ab04bded99685dc` /
  `b1951f9d9a945d46dec65c29231f16d9f4a08705a206d3b2a5193d1292aa2e3d`；F32 合同
  §11 的 `8eec...` / `2d45...` 只属于 turnover-only 历史阶段，`b306...` /
  `b195...` 也只绑定 5244 性能快照；后续 correctness 修复必须另记新 identity。历史 8 个 Qwen
  runner、9 处旧 hash 引用 GAP 保持不变。expanded lint 未出现新 SCC，且 ready 不反馈
  valid/payload；但 result/current-dst→shift/strobe/legality→output mux 与
  response/fault/timeout→direct-valid 控制锥的 delay、fanout、布线、投机翻转仍未经
  synthesis/STA/power 证明，继续列为 **physical GAP**。
- **保留：protocol-fault owned-response hold-to-DRAIN correctness repair。** matching
  GMEM/child response 与另一接口 unsolicited response 同拍时，global protocol fault
  必须组合压低两路 response ready/fire；fault edge 不消费 matching response、不清 edge-old
  owner，而是保留 credit 并把 owner 记入 DRAIN。offending wrong-owner valid 撤销后，下一
  DRAIN handshake 才恰好消费 matching held response 一次，随后 clean retry；不得产生 direct
  offer、新 owner 或重复 accounting。对 owned GMEM error response 的 collision，DRAIN 完成时
  仍必须保留 protocol/internal final cause：GMEM late error 只允许覆盖 command/stall timeout
  drain cause，不得覆盖 protocol/internal cause，以维持
  `protocol > GMEM response error > command timeout > phase timeout > normal`。focused fixture
  对称覆盖 owned child、owned GMEM success 及 owned GMEM error 三类 collision。
- **保留：F32 successful SRC1 response→child request elastic direct。** normal matching
  `ST_SRC1_WAIT` response 可直接形成 child request；valid/op/registered LHS/RHS payload 与
  `child_req_ready` 无关。RHS 只经一份 direct-selected/registered raw mux，SUB 在 mux 后只翻转
  一次 sign；SCALE 继续走 `SRC0_WAIT→CHILD_REQ`，不得进入 SRC1 direct。ready-high 同沿清
  GMEM owner、建立 child owner并进入 `CHILD_WAIT`；ready-low 仍消费 GMEM response，把同一 raw
  RHS 捕获到 q 后进入 `CHILD_REQ`，eventual fire 才建立一次 child credit。response error、
  protocol、command/phase deadline 与 reset 均 fail-closed；existing illegal shadow-write payload
  也继续不得 fire/birth owner。focused run 冻结 direct-elements `16`、fallback `1`、
  `opcode-coverage=f`、illegal `1`、command/phase priority `1`、collision `3`、
  production force witness `17`、GMEM drain `7`、`max_owner=1` 与 PASS。
- 该 SRC1 direct 在 5244-cycle child-write-direct 阶段上再省 `3*16=48` 拍；相对 5337
  baseline 的累计公式为 `3*(16-1)+3*16+3*16=141`。stats-off 与 stats-on 均冻结：
  total `5244→5196`（累计 `5337→5196`）、pre-recovery `1218` 不变、recovery
  `4026→3978`、macro issue→terminal `464→416`、system serialize `651→603`、
  clock-gated gap `457→409`；active attribution `194`、GMEM `144=96 read+48 write`、
  CONFIG/error timing、95 条 ordered command/terminal/completion 与 raw F32 结果不变。
  executable oracle 以 `kF32SavedCycles=45+48+48=141` 同时冻结 macro、phase、total、
  serialize 与 gap。
- 当前 focused 证据为 `/tmp/f32-protocol-finalcode-20260901-root/{build,run}.log`；
  stats-off/stats-on
  系统证据分别为
  `/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/rv64-direct-npu-system-20260901T003236-699936/run.log`
  与
  `/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/rv64-direct-npu-system-20260901T003236-699973/run.log`。
  当前稳定 F32 RTL/TB/C++ SHA-256 分别为
  `eebe42af020eb9032bc3a7e917194f022f691819e34722d4467c8efca8f6fa62`、
  `ebced149d26cf57ab61bd7bb01a15e3713f992a46edb61b0ea30820ae7d93b84` 与
  `01a332f97f485bdd3d9b3743d0f0cdd95d34a9fa456f07ab3715512d0f26d370`。
  这些日志与 hash 绑定 final-code repair + SRC1 direct 稳定阶段，不改写上文 5244 及
  更早 historical evidence；final-code repair 前的中间
  `d6ef10431cec6e649fc4997ac8a214a98eca7774900b0a4abd56f99696409efe` /
  `5d750fc3355d589ab9ded2b2323932019f5ec047a22dc22525f4ba7d48c8312d`
  snapshot 与 `20260901T002325-697284` / `20260901T002325-697237` 双系统日志也仅作为
  historical 保留，不认证三重 collision。历史 8 个 Qwen runner、9 处旧 hash 引用 GAP
  原样保留。新增组合锥为
  `GMEM rsp data/valid→lane/raw RHS mux→optional SUB→fp_ext/FMA capture`。固定 workload
  cycle 改善 `48/5244≈0.915%`，仅在 new period degradation 小于
  `5244/5196-1≈0.924%` 时才有执行时间净收益；本轮未运行 synthesis/STA/area/power，
  所以该 break-even 不是 timing 证据，不能宣称物理提速或 PPA promotion。

### 11.6 F32 registered pair-beat reuse successor

本节显式继承而不覆盖 §11.5 的 5196-cycle predecessor。F32 engine 新增两个
command-local、single-entry、registered 64-bit source cache；具体 q 为
`src0_beat_{valid,tag,data}_q` 与 `src1_beat_{valid,tag,data}_q`，命中/取 word 组合量为
`src{0,1}_beat_reuse_hit_w`、`gmem_pair_reuse_hit_w` 与
`src{0,1}_beat_reuse_word_w`。每个 entry 由 valid、完整 `addr[63:3]` tag 与 raw 64-bit
data 组成，总新增 state 为
`2*(1+61+64)=252` bit。entry 只由 matching owner 的 clean successful
`SRC0_WAIT` / `SRC1_WAIT` response 填充；reset、新 command admission、abort 清 valid，
response error、protocol fault、timeout 与 DRAIN response 不得 fill 或 reuse。

reuse 只允许在 successful non-last `WRITE_WAIT` turnover：既有 preflight 与 next-address
检查必须先成功，opcode 必须是 binary `ADD/MUL/SUB`，而且 src0/src1 两个 cache 的完整 tag
必须同时 exact-match 各自下一 selected address。exact dual hit 把下一地址 bit 2 选择的
upper/lower raw lane 注册进既有 operand q，再走既有 `CHILD_REQ`；每个命中元素跳过两次 8B
source read，并令新的 64-bit `gmem_pair_reuse_elements` 加一。任一 single hit 都完整 fallback、
重读并更新两个 source，禁止按 source 独立省一次 read。故 pair-only oracle 下，现有
modulo-broadcast / transpose-like 定向序列分别是 `64→64`（0 hit）和 `32→16`（8 hit），
不能登记 per-source-independent 的 `64→48` / `32→10`。

selected-address 的 coordinate/modulo/broadcast/stride 计算仍是唯一地址 authority；cache 不
改写地址，只消费 next address 做完整 tag/lane 选择。src0 与 src1 可以 read-read alias，甚至
命中同一个 aligned beat；dst 仍必须与 source beat footprint disjoint。不同完整 tag 不能因
低位或数据相同 false hit。cache 始终保存 raw operands，尤其 SUB RHS 只允许在既有统一 child
mux 翻 sign 一次；SCALE 不得使用 pair cache 且 counter 必须为0。

优先级冻结为：

```text
reset > protocol/owner fault > GMEM response error
      > command timeout > phase timeout > normal progress

normal successful WRITE_WAIT:
current invalid > last > next invalid > exact dual hit > full fallback
```

busy start 不影响 resident cache；reuse 只能发生在 command preflight 已覆盖的地址内。last 不
计算 next；next-invalid、unknown tag/lane 或任何 error/timeout/protocol/drain condition 都在 hit
前 fail-closed。pair path 不新增 FSM state或 owner，不让 valid/data 依赖 GMEM/child ready；它只在
turnover edge 注册 operand q，由下一 `CHILD_REQ` held-valid handshake 建立唯一 child credit，
所以不得产生新 ready dependency 或 SCC，accepted owner 总数继续 `<=1`。

这项 reuse 还引入正式的 command-scoped source read lease。lease 从 command admission 持续到
terminal/reset/abort；期间 preflight 覆盖的每个 aligned 8B source footprint 必须稳定、
read-idempotent、nonvolatile、非 MMIO，并排除 CPU、DMA、device、other NPU command 与 alias
writer。可以由独占 aperture 或 coherent ownership/read lease 保证；否则必须在冲突写前可靠
invalidate reuse，或整条命令禁用 reuse。“uncached”本身不是证明。src0/src1 的 read-read alias
允许，dst/source disjoint 规则不变。当前测试 wrapper 的独占 uncached aperture满足已测 slice；
通用 cache/DMA/IOMMU alias/多 agent lease enforcement 仍是 GAP。

Adapter 的 actual bytes 必须独立按 clean successful source response 累计，每个 64-bit response
计 8B，不能从 reuse expected 反推。expected 使用扩宽中间值：binary logical baseline 为
`elements<<4`，SCALE 为 `elements<<3`，binary saved 为
`gmem_pair_reuse_elements<<4`，最后做 `expected=baseline-saved`。当前合同要求 68-bit
intermediate；SCALE/无 src1 出现非零 reuse、reuse count 超过 elements、subtract underflow 或
expected 高位非零都必须 fail-closed 为 accounting/protocol error，不能截断或 wraparound PASS。

production runner 的 current active oracle 也必须按 generic P00–P18 的独立 profile/source
address sequence 做 pair-only full-tag cache-aware constexpr 推导；所有 binary profile 静态
`16*N` 与 P00-only `128B` 硬编码都不再是有效 current expected。oracle 中的 single hit 同样
完整 fallback 并更新两个 entry，而且必须与 DUT raw counter/Adapter actual-response counter
独立实现。sealed historical runner/log/hash 不因 active oracle 演进而改写。

metadata requalification 仍是显式 GAP：`scripts/qwen_f32_alu_profiles.py:read_bytes` 目前仍是
旧 logical baseline binary `16*N` / SCALE `8*N`，并绑定 canonical manifest hash。若字段表示
semantic logical traffic，必须重命名或澄清 schema/consumer；若表示 raw completion physical
bytes，则 successor 尚未重资格化，旧 manifest 不能认证新 RTL physical traffic。本轮不改
script、manifest 或 sealed hash。旧 `QWEN_F32_ALU_OWNER_RTL_CONTRACT` 的 deadline 语义也可能
与当前 `protocol > GMEM response error > command timeout > phase timeout > normal` 冲突；该
historical contract GAP 必须单独闭合，不能静改旧合同或用它覆盖当前 error-before-timeout
优先级。

focused non-vacuous matrix至少冻结：连续16元素让每个 source 各呈现8 miss/8 exact-tag hit，
最终 pair hit `8`、miss `8`、physical source reads `16`；混合 dual/single/no-hit 的 single-hit
fallback；full-tag/upper-lower false-hit；stale reset/error/timeout/protocol-DRAIN retry；error
response不fill；ADD/MUL/SUB raw result与SUB single-transform；SCALE zero count；collision与
backpressure下 exact-once及 `max_owner=1`。final evidence 为：

```text
/tmp/f32-beat-cache-20260901-final/build.log
/tmp/f32-beat-cache-20260901-final/run.log
hit-elements=8 miss-elements=8 physical-reads=16 tag-oracle=1
protocol-owned-response-collision=3 max_owner=1 PASS

TensorNpuF32TensorAlu.v  389b276ac1c2f59e56639ed6f5dbed8afd2803c5f3d80522dcc5df8d6b447e7d
tb_f32_tensor_alu.sv     a9fc495fb34c4faaf1fc5287cd58e58f0e910bd3819ba1d19f23b62f3e69eaf6
```

旧 5196 executable oracle 的只读 raw run 只因旧 cycle expectation 得到预期失败；其
actual `5124`、macro `344`、recovery `3906`、GMEM req/rsp `96`（read48/write48），
功能 raw 结果与 95 个 ordered terminal 无失败。更新 current executable oracle 后，以下
stats-off/stats-on 均 exact `5124` PASS：

```text
/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/rv64-direct-npu-system-20260901T005521-705668/run.log
/home/lyg/PA/ysyx-workbench/npu/version_0820/tmp/rv64-direct-npu-system-20260901T005521-705618/run.log
```

两者冻结 `pre=1218`、`recovery=3906`、`macro=344`、GMEM
`96=48 read+48 write`；stats-on 另有 `active=194`、`system serialize=531`、
`gap=337`。每个 macro completion 为 read128B/write64B/elements16。beat reuse 项精确为
`3 macros * 8 hit elements * 3 cycles = 72`，因此：

```text
5196 -> 5124 = -72
5337 -> 5124 = -213 = -(45 + 48 + 48 + 72)
macro 416->344, recovery 3978->3906, serialize 603->531, gap 409->337
GMEM 144=(96 read+48 write) -> 96=(48 read+48 write)
```

新增物理对象仅能登记为 252-bit cache state 与
`next selected address→full-tag compare→lane/cache mux→operand q`；pair hit 注册后才到 child，
不新增 GMEM→FPU 组合路径。未运行 synthesis/STA/area/power，不能宣称物理收益；clock-period
break-even `5196/5124-1≈1.405%` 只是算术边界。§11.5 的 5196 predecessor 与更早 snapshot
全部 sealed 保留；历史 Qwen identity GAP 仍为 8 runners / 9 old-hash references，当前证据
没有重认证它们。current active raw oracle 可显式升级，但绝不能静默重写 historical oracle、
log 或 hash。

### 11.6.1 F32 registered prepared pair-hit → child elastic direct

本节是 §11.6 的 5124-cycle registered pair-beat reuse 后继，不回写其 source hash、日志、
physical-read oracle 或历史 identity。实现只增加一个 command-local
`pair_reuse_prepared_q` bit，并复用既有 `lhs_bits_q/rhs_bits_q`，不增加 64-bit payload
register。clean `CHILD_WAIT` response 边沿用与 WRITE_WAIT commit共享的唯一 successor
walker，在 non-last、地址合法、binary、两侧 cache valid、完整双 tag exact-hit、current
integrity与 write payload均有效且无 reset/protocol/deadline 时，把下一 raw operands 注册到 q
并置 prepared。walker/descriptors/opcode/cache 在随后的 WRITE_REQ/WRITE_WAIT 不变，故该 bit
与 commit 是同一 successor；原 live dual-hit 判定继续作为 prepared=false 时的 registered
fallback，不驱动 direct。

clean write response 的顺序固定为
`current invalid > last > next invalid > prepared > live-hit fallback > full read fallback`。
prepared direct 的 offer/valid/payload只依赖 registered q与 fail-closed guards，child ready只控制
fire。ready-high 同边沿完成 GMEM owner `1→0` 与 child owner `0→1`，request只计一次；ready-low
仍消费 write response并进入 held `CHILD_REQ`，两个 owner暂为0，payload保持到唯一后续 fire。
pair counter在 successful commit只加一次。reset、新 command、protocol、child/write timeout、
write response error、正常消费、DRAIN、DONE、ERROR与default都清 prepared。SUB cache RHS保持
raw，只在统一 child mux翻 sign一次；last/invalid/error/timeout不计 hit、不创建 successor owner。

该结构不把 live 4D modulo/stride/address/tag/lane 网络串入 child payload，也不形成
child-ready→GMEM-ready feedback或新 SCC。focused final冻结：

```text
/tmp/f32-pair-child-prepared-20260901-final/build.log
/tmp/f32-pair-child-prepared-20260901-final/run.log
hit=8 miss=8 pair-direct=8 physical-reads=16 tag-oracle=1 fallback=1
gmem reads/writes/responses=209/115/321
child accept/response/cancelled=121/120/1, max_owner=1, PASS

RTL e69fc4e517154638cd722781443be00907555b38068a5f04342f722439970ad1
TB  899a7700d555fc5cdc68dc68c1b601216c1fb371537d622e36cf76b4fc4c38ad
```

独立只读终审在这两个 hash 上得到 `RETAIN, must-fix=0`。旧 5124 oracle 的 raw A/B
`20260901T013823-713146` 仅产生五个预期 timing failure，实际功能、95 个 ordered terminal、
GMEM与 exact-once全通过，测得 5100。current C++ oracle以独立常量
`3*(16/2)=24` 更新后，stats-off/on fresh run：

```text
20260901T013941-713687  stats-off  PASS, SHA-256 8cd24341cbb6d84a6a36d65d767eade52f0f466e5014c1f79b7b0e89ceb28d1e
20260901T013941-713717  stats-on   PASS, SHA-256 06202a64900ad31edd834c7a97a2b8b485a6f3e0679dabe41969dc700a15a74c

total=5100, pre/recovery=1218/3882, macro=320
active=194, system serialize=507, gap=313
GMEM=96=(48 read+48 write), issued/terminal/completion=95/95/95
5124->5100=-24; 5337->5100=-237=-(45+48+48+72+24)
```

P00 physical traffic与 Adapter/runner expected不变。新增物理 state只有1 bit，但真实控制
fanout、write-response→child path、frequency、area、power与routing仍是 physical GAP；未运行
synthesis/STA/PPA。固定 workload 的 clock-period break-even
`5124/5100-1≈0.471%` 仅为算术边界，不能宣称物理提速。§11.6 的5124与更早 snapshot、
Qwen manifest/hash、coherence/lease及 full-model GAP原样保留。

### 11.6.2 F32 admission-captured first-element preparation fold

本节只继承并前推 §11.6.1 的 current executable stage，不回写5100 predecessor的 source hash、
日志、oracle或历史 identity。F32 macro首元素坐标恒为全零；唯一 `start_fire_w` 边沿把三条
`region_base + view_off` 结果写入既有 `gmem_req_addr_q/gmem_read_upper_q`、
`current_src1_word_q` 与 `current_dst_addr_q`。没有新增 register或 payload bank；capture为投机
内部状态，不产生 valid、owner、request或counter side effect。

原有 registered descriptor 的128-bit preflight仍是唯一合法性 authority。64-bit admission加法与
62-bit source-word cast不能替代 overflow/bounds/alignment证明；只有完整 preflight成功且非empty，
FSM才从 `ST_PREFLIGHT` 直接进入持有相同 payload的 `ST_SRC0_REQ`。preflight error、protocol fault、
command timeout、empty SCALE、reset与busy-start规则均不变；`ST_ELEMENT_PREP`保留为防御状态，但
正常成功命令不再进入。GMEM owner仍只由实际 request fire建立，ready-low held-valid与watchdog、
后续 walker、pair cache/direct、fault priority和 exact-once全部复用 predecessor合同。

focused final 证明 admission拍公开 GMEM valid/owner均为0，首 payload与下一 `SRC0_REQ`逐bit一致，
整条16-element命令 `prep=0`、后续 turnover=15；25项 preflight negative、busy/reset、deadline、
fault/DRAIN、ready-low、pair hit/miss与 `max_owner=1` matrix均PASS：

```text
/tmp/f32-first-prep-fold-20260901-final/build.log
/tmp/f32-first-prep-fold-20260901-final/run.log

RTL bb3312e3949b86960a7b86a349f14499f6ebdea92cb29887d0a6538506d46891
TB  17a04c864c6c2f63033e5db5223a057491a4f7e7093568931cbbb9bd3a344758
build 4194545091fb55e9feb52849de9c0447783237d1d479d19e83c4e56b9ebc9dc7
run   b83aeb9429ced486b1ebda20fa3b7f7acc47f3ea1f767b81927b6b7d828402fa
```

独立只读终审逐项核对 admission宽度/preflight、SCALE/empty/busy/reset/deadline、状态可达性、
owner/exact-once与A/B分解，结论为 `RETAIN, must-fix=0`；非零 src1/dst view-offset mutation、
不可达防御分支 force与逐 macro savings打印只登记为可选覆盖加固，不阻断本阶段。

旧5100 oracle raw A/B `20260901T020254-717389`（SHA-256
`d166b0f29a2b174dbf93560e556c0fdaffca57706d53e91d732edd6d71676aeb`）只产生五个预期 timing
failure，实际为5097且功能/traffic/exact-once不变。current C++ oracle加入独立常量
`kF32FirstElementPrepFoldSavedCycles=3`，source SHA-256为
`61df1ac1a136b9ffab74181c64134204613aa1d32ababb7e89071ef94cb8bddd`。fresh run：

```text
20260901T020406-717811 stats-on  PASS, SHA-256 6115a1483d358ee38f4174c4e12f46e2e557998a53eae8500fcd62c280886ef7
20260901T020514-718607 stats-off PASS, SHA-256 11044e0a7ab89fa657b72e9b3e765ef4cdd3bb6501a0269a305f26ebc0e86003

total=5097, pre/recovery=1218/3879, macro=317
active=194, system serialize=504, gap=310
GMEM=96=(48 read+48 write), issued/terminal/completion=95/95/95
5100->5097=-3; 5337->5097=-240=-(45+48+48+72+24+3)
```

本节未运行 synthesis/STA/PPA。周期降幅 `3/5100≈0.058824%`，clock-period degradation
break-even仅 `5100/5097-1≈0.058858%`，不能外推为物理提速。剩余45个可数边界属于同一
GMEM endpoint response→request，而现有 `ready = stall_done && !rsp_valid`令其同拍收益为0；
若支持 credit swap必须跨 engine/Adapter/endpoint重定义合同。preflight→首 request direct也只多省
3拍并会拉长公开GMEM组合路径。故不在无physical证据时继续堆叠这两项，本局部以5097作为停止点，
后续转向更高收益的RV64 pipeline热点。5100及更早 snapshots、Qwen manifest/hash、lease/coherence、
full-model与physical GAP全部原样保留。

### 11.7 FP/Tensor 共享 PRF read8（5R2W）

- 生产 PRF 只保留 `read0..3` 与共享 `read8`，原 Tensor 专用 `read9` 必须从端口、组合读与 stored-only
  assertion tuple 中同时删除；这里的“5R2W”只描述 RTL 结构，不注册 area、timing、power 或 PPA 改善；
- FP 只有在一条实际 issue-fire 且确实消费整数 GPR 的 `FMV.*.X`/integer-to-FP conversion 上占用
  `read8`。不得用 raw valid、地址非零或 stalled packet 猜测占用；该 actual-use fire 固定高于 resident
  Tensor 请求，且 Tensor grant/data 不得反馈到 FP issue ready；
- Tensor Sidecar 必须把 dependency-ready 与 operand-valid 分开。非零 scalar source 在 dependency-ready
  后以 resident `valid/preg` 持续请求共享端口，直到 grant、matching WB wake 或 prelaunch cancel；denied
  request 的 preg 保持稳定。64-bit pair 与 x0 不请求端口，scalar operand 精确为零；
- resident payload 捕获优先级固定为 `wake1 > wake0 > shared-read`，allocation 同拍 matching WB 也必须
  捕获 WB payload，不能读取 edge-old stored PRF。grant/wake 与 head/drain/launch 条件同拍满足时，Sidecar
  必须在 WAIT 当拍直接给出 valid/prospective payload；ready=1 同沿 fire→SENT，ready=0 同沿锁存该 payload
  并进入 OFFER skid，不得人为增加注册气泡；
- targeted kill/global flush 必须组合阻断 read request 与 command valid，尤其 `cancel + cmd_ready` 同拍不得
  产生 command fire。OFFER payload 在 backpressure 期间冻结；SENT/COMPLETE 除 reset 与合法
  terminal/completion handoff 外不可取消；
- 回归必须同时覆盖：denied-hold/grant、`wake1>wake0>read`、kill/flush 与可用端口同拍、
  `cancel+cmd_ready`、64-bit/x0 no-read、OFFER payload hold、真实 WB×Tensor allocation collision，以及真实
  FP×Tensor read8 collision。后者须证明冲突拍 FP 地址/数据获权，Tensor 请求保持并在首个空闲拍获得自己
  的精确数据；
- 当前固定 direct-system workload 不含能暴露 FP×Tensor read8 冲突的流量；在后续 WAIT fall-through 之前，
  5R2W 前后以及 stats-on/off 都是 5342 system cycles。后续候选的 5340 不能倒归因给共享端口。因此这组
  系统结果只证明各自同源身份下的功能/周期行为，不能用来声称共享端口改善 IPC，亦不能替代未来同源
  冲突 workload 或 PPA gate。

每个固定输入/config/seed的确定性case默认执行一次。A/B corner、正负向与mutation是不同证据，不是重复执行。

## 12. 当前 GAP 与停止条件

以下任一未闭合时，direct integration不能宣称“Qwen 全模型经 RV64”PASS：

1. CONFIG/descriptor 仍只覆盖 `VECTOR_F32/P00`，尚不能表达 Q8 GEMV、GET_ROWS、mover、norm 等全部
   public macro kernel 的完整地址、shape、stride、capability、canonical identity 和 node hash；
2. 当前 GMEM 测试 wrapper 的独占 uncached 物理 aperture 满足已测 slice 的 command-scoped
   source read lease；但通用 NPU typed D-cache clean/invalidate、CPU/DMA/device/other-NPU
   alias writer 排除、cacheable DMA ordering、IOMMU/页表与 AXI arbitration/fairness 合同仍未
   闭合。拿不到 coherent/exclusive lease 时必须 invalidate 或禁用 reuse，不能仅凭 uncached
   标签继续命中；
3. malformed pair 的typed cause/`tval`、same/cross-packet residual与pending-trap exact-once已冻结并有
   定向回归；已发NPU terminal error/unsupported完整payload、post-launch IRQ/debug/NMI 的系统矩阵仍需在
   production 顶层逐项复核；
4. 当前系统测试证明真实成功 terminal 与 precise error，但还没有覆盖每个宏 kernel、所有 GMEM error/reset
   epoch、全部 stale-generation completion 和 mutation；
5. Qwen strict backend 已冻结 required-node manifest、CPU 轻量控制边界与零 fallback 计数，但当前 host
   Verilator frontend 尚未替换成“每个节点由 RV64 指令流提交”的 runtime；
6. 因而本合同允许声称 P00 direct slice PASS，不允许把它描述为 Qwen shell、完整 ISA、cache coherence 或
   full-model CPU/NPU 集成 PASS。

实现中一旦发现候选A必须阻断older completion/response、无法保留post-HI residual、无法以full PID持有
terminal response，或无法在cacheable DMA后取得invalidate ack，应立即停止该切片并回到合同层，不得用
CPU fallback、缩短tag、吞word或放宽checker绕过。

## 13. 竞争候选与重新开启条件

- **B：always-on 4-slot word queue**。pair规则较整齐但侵入所有普通指令；只有候选A在residual mutation中
  持续失败，且B对固定非Tensor workload的cycle完全不变时才重新评估。
- **C：speculative NPU issue queue**。只有NPU提供经测试的side-effect buffering/commit或abort+ack，能证明
  TCR/LMEM/GMEM wrong-path零残留时才允许研究；当前禁止MVP采用。
- **D：illegal trap + MMIO NPU offload**。保留为回滚/reference。若固定workload证明trap开销相对长kernel
  可忽略，可以重新比较，但它仍不得调用CPU软件重型kernel。

本文不注册frequency/area/power预测，不要求、也不允许在当前目标中运行综合、STA或PPA来裁决候选。
