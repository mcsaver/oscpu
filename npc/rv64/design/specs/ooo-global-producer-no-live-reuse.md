# OoO 全局 ProducerId 持有者与有限代际不复用合同

> 状态：v8l current-production-top 合同。这里只关闭
> `NpcTop -> NpcCoreTop -> OooCoreTopGlue -> OooIntBackend` 范围内的
> ProducerId 持有者枚举与 no-live-reuse；完整双 memory、系统级验证、全核 architecture
> promotion 和 PPA 仍按 `../arch/rv64-architecture-ppa-contract.md` 保持 RED/unpromoted。

## 1. 身份与出生门

唯一事务身份为：

```text
P = {generation, rob_index}
```

ROB 的 `dispatch*_generation_candidate_w` 是出生身份唯一来源。dispatch guard、ROB 写槽和
下游 capture 必须消费同一个 exported P，不允许分别重算 generation，也不允许只用
`rob_index` 查询 lease。ROB 不借用同拍 commit 空位，generation 加法显式限制在
`PRODUCER_GEN_W` 位，因此回绕是定义明确的模运算。

```text
complete_live[P] = external_live[P] OR integer_iq_live[P]
dispatch_fire(P) -> !complete_live_old[P]
```

所有 birth ready/fire 都只读 edge-old Q holder。新出生 P 不得自阻塞；旧 holder 在其死亡沿
仍阻塞，只有下一周期才释放。

## 2. 当前生产 holder 域

完整机器清单是 `../arch/producer-holder-census.json`，由 checker 按字段和 packed stage
逐项核对。当前域分为：

- 直接 full-P Q：integer/FP IQ、EX0/EX1、memory reservation、retire-resident LQ、
  MulDiv、CLMUL、FP arith/exec1/long/done FIFO、branch resolve packet、dispatched
  pending system/CSR；
- tracker 映射：memory owner token 在 `OooMemOwnerTracker` 中不可变映射到 full P；
- 间接 token Q：memory reservation/buffer/pending、MIQ、SQ、AXI bridge 和 terminal
  collector。任一 resident token 必须属于 tracker 的 edge-old `live_q`；
- ROB generation authority：`slot_generation_q`。ROB 本体不是额外 lease mask，因为槽在
  commit 前不会被重新分配，且不借同拍 commit 空位；
- EXEMPT：pre-ROB control/trap metadata、组合 wire、ready/fire/next-state、断言 shadow 和
  allocator cursor。EXEMPT 不得独立授权 WB、redirect、memory side effect 或新出生。

Integer IQ 的源依赖是 physical-register tag + sticky-ready，不是 ProducerId；当前唯一 full-P
字段是 uop owner `producer_id_q`。今后若新增 full-P source tag、replay/skid/completion FIFO、
redirect packet 或 owner-token Q，静态 checker 必须先 RED，直到清单和 lease 证明同步更新。

## 3. Memory 原子交接

IQ memory owner 只在 tracker 分配成功时离队：

```text
capture_candidate = present && current_P
capture           = capture_candidate && tracker_alloc_ready
IQ_pop(memory)    = stale_drop || capture
STORE_bind        = capture && owner_kind==STORE
```

若 tracker backpressure，IQ 不 pop、reservation 不 capture、SQ 不 bind。成功交接沿由旧 IntIQ Q
lease 覆盖；下一拍 reservation Q 与 tracker Q 同时出现，且 token→P 映射保持稳定。MIQ、SQ、
buffer、bridge 与 terminal collector 只携 token 的阶段必须满足：

```text
indirect_resident_token_set subset_of tracker_live_q
```

STORE 在 dispatch 后、issue 前由 IntIQ lease 覆盖；bind 后由 tracker lease 覆盖。SQ 的 raw
full P 另由独立 assertion 扫描，防止 token handoff 或清单遗漏制造空窗。

ordinary LOAD 在 dispatch fire 时同时建立 LQ full-P holder；其 lease 横跨 reservation、MIQ
transport、formal WB 与 ROB retirement。branch recovery 后已 launch 的 incomplete load 以 killed
tombstone 继续持有 full P，直到精确 memory terminal；因此 LQ mask 不能退化为 MIQ occupancy mask，
也不能在 normal transport terminal 上提前清除。

所有本地 holder 还必须满足 `valid => identity known`：有效 full-P Q 在参与 onehot/位图索引前
必须是确定的二态值，有效 token Q 在参与 tracker/residency 索引前也必须是确定的二态值。该约束
由 holder 所在模块的 raw Q 断言承担，顶层 union/subset 断言不能替代它；否则 X 索引可能让
“没有遗漏”的比较本身变成空洞值。

## 4. 自动发现与验证

日常入口：

```bash
make -C npc/rv64 check-producer-holder-census
make -C npc/rv64 check-contract
make -C npc/rv64 check-global-producer-no-live-reuse
```

checker 会：

1. 去除 comment/string 和 `OOO_ASSERT` shadow 后，枚举全部
   `[PRODUCER_ID_W-1:0] *_q` 字段；所有 exact-width `reg/logic` 即使不以 `_q` 命名也必须进入
   显式组合豁免表，防止用命名变化绕过 holder 发现；
2. 递归解析 `PipeStageReg.WIDTH`，枚举所有含 ProducerId/generation 的 packed stage；
3. 枚举 production `_token_q` 字段，并要求每项归类为 indirect holder、derived alias 或明确的
   allocator cursor exemption；
4. 锁定 Q-only union、full-P guard、ROB candidate/store 同源、memory tracker、FP union 和
   SQ observational owner view；
5. 输出 manifest/checker/逐源文件 SHA-256 与 source-set SHA-256；
6. 运行 compile-independent mutation self-test，证明新增字段/packed stage/token、删 IntIQ
   union、改 raw-index lookup、manifest 自我晋级都会 fail closed。

动态门还必须运行 v8l focused runner：assert/release、真实 `GEN_W=1`
allocate→issue→WB→commit 整圈回绕、死亡沿、memory tracker backpressure/cancel/recovery，以及
compile-success semantic mutation。TB reference 直接扫描 raw Q holder，不复用 production mask。
`check-global-producer-no-live-reuse` 是该动态门的长期入口；它先运行静态 census，再执行绑定 task-run
runner，并要求 mutation 先成功生成 vvp 后才允许以预期运行后果计为击杀。

## 5. 声明边界

静态 census PASS 只表示当前 source-tree 的字段级清单闭合，不表示实例图或语义形式证明完成；
这两个布尔值在 manifest 中固定为 `false`。只有 source-bound focused/mutation/legacy/aggregate
证据同时通过，才可称 current-production-top 的 global no-live-reuse scoped GREEN。该结论不得
外推为完整架构 GREEN、系统级 GREEN、200 MHz、Power 或 PPA promotion。
