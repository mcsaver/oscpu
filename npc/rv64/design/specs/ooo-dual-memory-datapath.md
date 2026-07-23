# 规范：DI-5 双内存数据通路（S2，v8q 起）

> 状态：S2 总体合同冻结；v8q 已实现并验证 **F0 共享 AXI miss fabric 叶模块**，
> v8r 正在冻结并实现 **F1 双 bridge/cache-hit wrapper 与 peer maintenance**。
> F1 仍不接入 canonical core/backend，也不增加第二份 MIQ、physical SQ query 或 WB credit，
> 因此 DI-5、OOO-3、overall architecture 与 PPA promotion 继续 RED。

## 1. 目标、范围与明确非目标

最终 S2 必须把 v8p 已存在的两个普通整数 memory reservation owner 贯通为两条
真实数据通路：两路 captured-data AGU、两路翻译接纳、两路 final-PA 物理 SQ
字节消歧、两路 banked cache admission、两份独立 memory credit/MIQ 和两路 tagged
completion。对齐、cacheable、TLB/cache hit、不同 bank 且 credit 充足的 64-cycle
轨迹必须达到 memory issue IPC >= 1.90。

S2 允许共享外部 AXI miss 通道；共享点必须位于两条 cache-hit 通路之后，并由锁持有
仲裁器覆盖完整 `AR->R` 或 `AW/W->B` 事务。miss 串行不允许反向把无冲突的另一条
TLB/cache hit 通路冻结。

本轮 v8q/F0 的范围只有：

- 新增可综合 `OooDualMemAxiArbiter`；
- 两个上游单 outstanding、单 beat AXI master 共享一个下游 AXI master；
- owner 从请求被选中起保持到 R/B terminal，AW/W 可独立反压；
- release/`OOO_ASSERT` 定向 TB、compile-success mutation 与 fail-closed checker。

F0 明确不包含：core/bridge 接线、第二 MIQ、第二 DTLB/D-cache、物理 SQ query、
peer-cache maintenance、双 response/WB、DI-5 性能轨迹、OOO-3 或 PPA 数字。未实例化的
F0 是 F1 的已验证构件，不得被 source checker 当成活的第二数据通路。

v8r/F1 的范围严格限定为：新增一个未接入 canonical core 的可综合 wrapper，实例化两份
`OooMemAxiBridge` 和 F0 arbiter；两 bridge 保留各自 station/DTLB/D-cache/FSM、exact owner
接口和 response；bridge 只从既有、已授权的 store/A-D `B` terminal 导出维护事件，wrapper
把该事件交叉接到 peer D-cache 做 valid-only conservative invalidate；定向证明同拍两个真实
cache hit、peer miss 锁持有期间另一侧 hit 仍前进，以及 peer `B` terminal 与 lookup 判决冲突时
旧 alias 不得成为 response。

F1 明确不包含：canonical core/backend 接线、第二 MIQ、请求 bank 路由、final-PA SQ byte
query、store forwarding/replay、双 WB credit、64-cycle IPC、等总容量物理双 bank、系统级
DiffTest/Linux 或任何 PPA 晋级。初版复制两份 32KB D-cache/DTLB 只允许声明
`dual_bridge_cache_hit_leaf_verified`，并继续标记 architecture prototype、PPA unqualified。

## 2. 六类接口契约

### 2.1 端口、位宽、时钟与复位

`OooDualMemAxiArbiter` 只有 `clk`、同步高有效 `rst` 和三组 AXI 子集端口：

| 面 | 方向 | 字段 | 合同 |
| --- | --- | --- | --- |
| `lane0` / `lane1` read request | lane -> arbiter | `arvalid/araddr/arid/arlen/arsize/arburst/arprot` | 上游 payload 在 `valid&&!ready` 时稳定；当前 bridge 只产生单 beat (`arlen=0`) |
| `lane0` / `lane1` read response | arbiter -> lane | `rvalid/rdata/rresp`，lane 回 `rready` | 只对锁定 read owner 可见；terminal=`rvalid&&rready` |
| `lane0` / `lane1` write request | lane -> arbiter | AW 全字段与 `wvalid/wdata/wstrb/wlast` | AW/W 可任意先后或同拍完成；两者都完成前不得进入 B phase |
| `lane0` / `lane1` write response | arbiter -> lane | `bvalid/bresp`，lane 回 `bready` | 只对锁定 write owner 可见；terminal=`bvalid&&bready` |
| downstream | arbiter <-> existing LSU lane adapter | 同构单 master 子集 | 一次最多一个锁定 owner；不制造、合并或重排 beat |

数据宽度使用 `XLEN=64`，写掩码使用 `STRB_W=8`，ID=4、LEN=8、SIZE=3、
BURST=2、PROT=3。F0 不引入 flush 输入：已提交或已经展示的 AXI 事务不能被流水
取消撤回；上游 bridge 继续拥有 flush/drop/nokill 语义。

`rst` 是全系统同步高有效 reset；F0 的两个上游 bridge、下游 lane adapter 与外部 AXI
reset domain 必须在同一个上升沿看到它。reset 明确允许全系统共同放弃 reset 前在途事务，
不是普通流水取消或局部 bridge reset。`rst=1` 的整个组合观察期，F0 所有 request READY、
downstream request VALID、response VALID 与 downstream response READY 均强制为 0；上升沿把
FSM=`S_IDLE`、`owner_q=0`、`is_write_q=0`、`rr_q=0`、`aw_seen_q=0`、
`w_seen_q=0`。reset 解除后的第一个请求必须像冷启动一样重新捕获，不得重复 reset 前事务。

### 2.2 握手与稳定性

1. IDLE 只在时钟沿捕获一个合法 request owner，不在同拍向上游返回 READY；因此选择
   结果从下一拍开始稳定展示，切断 live contender -> downstream payload 的抖动路径。
2. read owner 从 `S_READ_ADDR` 保持到 `R` terminal；write owner 从
   `S_WRITE_DATA` 保持到 `B` terminal。AR/AW/W fire 均不得提前释放 owner。
3. `AW` 与 `W` 各有 `seen` 位；已 fire 的 channel 必须撤下 VALID，未 fire 的 channel
   继续逐位保持。只有 `aw_seen_next && w_seen_next` 才进入 `S_WRITE_RESP`。
4. 非 owner 的 `arready/awready/wready/rvalid/bvalid` 全为 0；下游 response READY 只取
   当前 owner 对应的 `rready` 或 `bready`。
5. 一个 lane 同拍同时呈现 read 与 write request 属于合同违例；`read-present=arvalid`，
   `write-present=awvalid||wvalid`。该检查在所有非 reset 状态成立。IDLE 中只要任一 lane
   违规，release 与 assert profile 都全局 fail-closed：本拍不捕获另一条合法 lane，也不更新
   FSM/owner/type/rr/seen，不产生任何 READY/VALID/fire；`OOO_ASSERT` 另外报告专属错误。
6. READY 不进入任一上游 VALID 的生成；本模块不把 response READY 回灌到新 request
   选择。所有 `valid&&!ready` payload 必须稳定。

### 2.3 stall / ready DAG

合法依赖方向固定为：

`lane request valid(Q/FSM)` -> `IDLE request census` -> `registered owner/type`
-> `downstream request valid/payload` -> `downstream ready` -> `owner request fire`
-> `registered response phase` -> `lane response valid` -> `lane response ready`
-> `downstream response ready` -> `terminal` -> `IDLE/round-robin bit`。

禁止方向：

- downstream READY -> lane request VALID；
- lane response READY -> request selection；
- non-owner payload/ready -> owner payload；
- AR/AW/W fire -> combinational owner reselection；
- downstream R/B -> 两个 lane 同时可见。

### 2.4 flush / kill / recovery 矩阵

| 事件 | IDLE | request phase | response phase |
| --- | --- | --- | --- |
| 普通流水 flush / branch recovery | F0 无输入；由上游决定是否仍展示新请求 | 已锁 owner 不变；上游 bridge 按 AXI hold 合同继续展示不可撤 request | 必须 drain 到 exact owner；不得广播或改 owner |
| killed speculative load | 上游可不再请求 | 若尚未经上游 VALID 展示可取消；一旦本模块锁定，仍按总线合同完成 | response 只回原 bridge，由 bridge/MIQ 负责 drop，不由 arbiter猜测 owner |
| `nokill` store | 正常竞争 | AW/W 两 channel 均 exactly-once | B 只回原 bridge，不能因另一 lane 请求而提前解锁 |
| 全系统同步 `rst` | 全接口静默；沿上清到冷启动值 | 全接口静默并共同放弃 reset 前事务 | 全接口静默并共同放弃 reset 前事务；解除后不得接收孤儿 R/B |

F1/F2 集成时必须另行证明 bridge drop terminal、MIQ owner、tracker token 与 arbiter lane
owner 的层次关系；F0 不拥有 ProducerId/token，不能作为架构完成资格真源。

### 2.5 异常、内存序与副作用

- arbiter逐位透传 `RRESP/BRESP`，不生成 page/access fault，也不解释 PMA/PBMT。
- write 的外部副作用许可仍来自 backend `ROB-head commit_authorized` -> SQ drain；
  arbiter只序列化已经由 bridge 展示的总线事务，不能扩大授权。
- `AW` 或 `W` 单独 fire 只表示该 channel 被下游接受，不是 store terminal；聚合 `B`
  才是 write terminal。
- read `AR` fire 不是 load completion；`R` terminal 才把响应交回 exact lane。
- round-robin只在 R/B terminal 更新，不能造成 transaction interleave。
- 两个 bridge 的 cache-hit completion 不经过本 arbiter；F1 集成不得把这里的 miss lock
  反向变成全局 cache-hit stall。

### 2.6 owner / source-of-truth

| 事实 | 唯一真源 | 禁止替代 |
| --- | --- | --- |
| 当前共享 AXI owner | `owner_q` | live priority encoder、地址位、response ready |
| 当前事务类别 | `is_write_q` / FSM state | AW/W/R/B 当前输入猜测 |
| AW 已完成 | `aw_seen_q` | `!awvalid` |
| W 已完成 | `w_seen_q` | `!wvalid` |
| 公平起点 | `rr_q`，只在 terminal 更新 | 每拍翻转或 request fire 更新 |
| architectural memory owner | 后续 backend tracker/MIQ full identity | arbiter lane bit |

F0 的 lane bit只是 transport owner，不包含 ROB index、ProducerId、token、epoch、class 或
fault provenance。任何后续集成都必须保留这些字段在 bridge/MIQ 的 exact identity 链上。

### 2.7 F1 双 bridge wrapper 六类接口扩展

#### 2.7.1 端口、位宽、时钟与复位

`OooDualMemBridgeWrapper` 使用一个 `clk`、同步高有效 `rst`、共同的 pipeline/MMU/DMA 与
CSR/PMP 上下文，暴露两组**完整且互不合并**的 `OooMemAxiBridge` request/expected/tracker/
station/device/response/drop/query/residency/idle/translate 接口，以及一组接向既有
`OooLsuAxiLaneAdapter` 的 downstream AXI 子集。wrapper 内部实例名固定为 `u_bridge0`、
`u_bridge1`、`u_miss_arbiter`，两 bridge 以 `ENABLE_PEER_INVALIDATE=1` 实例化。

为避免从 transport 重新猜测 cache authority，`OooMemAxiBridge` 新增以下维护边界：

| 端口 | 方向 | 唯一语义 |
| --- | --- | --- |
| `peer_invalidate_valid_i/addr_i/wstrb_i` | peer -> bridge D-cache | 已由 peer bridge 授权的 store/A-D `B` terminal；只做 conservative valid clear，不占 SRAM 口、不做 RMW、不产生 response |
| `peer_maintenance_valid_o/addr_o/wstrb_o` | bridge -> peer | 必须逐拍等于本 bridge 既有 `dcache_store_commit_w` 及其本地维护地址/宽度；不得由裸 `BVALID`、request bus、arbiter lane bit或地址 bank 位重建 |

`OooDataWordCache` 对应新增 peer invalidate 三输入。为保持既有单 bridge/canonical core 的
行为和回归不漂移，bridge/cache 的 `ENABLE_PEER_INVALIDATE` 参数默认 `0`；只有 F1 wrapper
显式设为 `1` 并完整连接。参数关闭时 peer 输入不得影响 hit、valid 或 SRAM owner。

维护 `addr` 是 producer 锁存的原始 byte PA，不是 line base 或 AXI beat address；`wstrb` 是相对
该 byte PA 从低位开始的规范化连续掩码，合法集合严格为 `8'b0000_0001/0000_0011/
0000_1111/1111_1111`（1/2/4/8B）。该 ABI 与 `LSUControl`、bridge
`access_size_from_wstrb` 和既有 D-cache store RMW 相同；producer/consumer 在
`OOO_ASSERT` 下都必须拒绝 zero、稀疏或 AXI lane-shifted mask。因而跨线判定唯一为
`addr[2:0] + popcount(wstrb) > 8`，实际受影响 line 集合至多为首 line 与紧邻次 line。

两份 bridge 与 arbiter 必须同域同步 reset。reset 断言不是异步组合取消：从采样到 `rst=1`
的第一个上升沿起，wrapper/children 才进入 reset-quiet 冷状态；该沿后的整个 reset 区间不得
输出旧 response 或维护事件，reset 前维护不跨 reset 保存或重放。F0 额外保留其既有
`rst=1` 组合静默强化，但不能据此外推所有同步子模块在采样沿之前已经清空。

#### 2.7.2 握手、稳定性与双命中

1. lane0/lane1 request READY 只能分别来自 `u_bridge0/u_bridge1`，wrapper 不得用 arbiter
   idle、peer busy、任一 lane response READY 或维护事件做全局门控。
2. 两 bridge 的 response/drop/query/idle/translate 逐端口独立透传；同拍两个 cache hit
   必须能同时形成两个带各自 kind/token/epoch/tval 的 response，禁止压成单 mux。
3. cache hit 完全位于 F0 arbiter 之前；只有 miss/PTW/store/A-D AXI request 进入 arbiter。
   一侧 miss 从 AR 捕获到 R terminal 或 write 从 AW/W 捕获到 B terminal 的锁持有，不得冻结
   另一 bridge 已预热 line 的 request admission、lookup 或 response。
4. peer maintenance 是无反压一拍事件。producer 只在其本地授权 `B` terminal 产生一次；
   consumer 不返回 ready，也不得排队后再猜 owner。共享 arbiter 使同一拍至多一个 bridge
   获得真实 B terminal；若该结构条件未来改变，必须重新冻结双维护冲突合同。
5. 两 bridge 到 F0 的 AXI payload/stall 合同完全继承 §2.2；wrapper 不增加 combinational
   fall-through owner 或跨 lane response-ready 路径。

#### 2.7.3 stall / ready DAG

每 lane 的合法 hit DAG 为：

`laneN request Q -> bridgeN station/DTLB/cache lookup Q -> bridgeN hit decision
-> laneN response valid -> laneN response ready -> bridgeN terminal`。

miss DAG 才在 cache decision 后追加：

`bridgeN AXI Q -> F0 registered lane owner -> downstream request/response
-> exact laneN bridge terminal`。

peer maintenance DAG 独立为：

`bridgeN authorized B terminal -> authorized local maintenance facts -> wrapper cross-wire
-> peer cache valid clear / same-cycle hit suppression`。

禁止 `F0 state/owner/downstream ready` 回灌任一 cache-hit request READY；禁止 lane0 response
READY 进入 lane1 request/response；禁止 peer invalidate 进入 SRAM enable/write 地址 owner。

#### 2.7.4 flush / kill / recovery 矩阵

| 事件 | producer bridge | peer bridge/cache | wrapper/F0 |
| --- | --- | --- | --- |
| pipeline `flush_i` | 按既有 exact owner、drop、escaped-write drain 合同 | 独立执行自身 flush；不得替 peer 猜 kill | 已锁 AXI 继续 drain 到 R/B terminal |
| killed escaped write 的真实 B terminal | 只有既有 captured maintenance authority 可产生维护；禁止 RMW/fill | 必须按地址 conservative invalidate | B 仍只回原 transport lane |
| `mmu_flush_i` | carrying contract 要求断言前两 bridge 已 `idle`；事件拍两份 DTLB 的 lookup hit 组合屏蔽并在沿上 clear，且该拍各自压 request READY | 同左；物理 D-cache 不因 mmu flush 擦除 | quiet 前不允许事件，因此不存在被取消的已锁 AXI |
| `dcache_dma_invalidate_all_i` | 两份 D-cache 同拍全失效并屏蔽 lookup hit | 同左 | 不占 F0/AXI |
| peer maintenance 与 lookup 判决同拍 | producer 正常完成 B | 若判决地址命中被维护 line，必须显式 miss/replay 到 AXI，不得先返回旧数据 | B terminal 后按正常 IDLE 捕获 peer miss |
| 同步 `rst` | 两份 bridge 冷启动 | valid 清零；无维护重放 | F0 冷启动且接口静默 |

#### 2.7.5 异常、内存序与副作用

- peer event 必须覆盖授权的 data-store 与 A/D-write 每个聚合 `B` terminal，包括 B error、
  PBMT NC/IO 和已逃逸后被 kill 的 write；B error/NC/IO/A-D 在本地也仍走 valid-only 失效。
- 只有当前 exact、未 killed、all-OK、final-CACHED 的 data store 可在 producer cache 做 RMW；
  peer consumer 永远不能 RMW，因为它没有 producer data/owner 的更新授权。
- peer invalidate 地址落入 PMEM 时无条件清首 line 的 valid；按 `addr[2:0]+nbytes(wstrb)>8`
  判定跨线并清下一 line。它可以保守淘汰同 index 的其它 tag，但不能让目标旧 alias 报 hit。
- valid 更新优先级冻结为 `rst > DMA full invalidate > peer line invalidate > local fill/store`；
  其中 peer/local 不是全 cache `if/else`：local fill/store 先按各自 index 更新，peer 再只覆盖首/
  次目标 index；不同 index 的 local update 必须同拍保留，同 index（含不同 tag）则 peer clear
  最终获胜。peer 与 fill/RMW/lookup 可同拍，因为它只写 valid FF；冲突时宏中可能写入的数据
  保持不可见。lookup 判决同拍还必须对 exact affected line 组合屏蔽 hit，不相关 exact line
  不做组合屏蔽。
- DMA 事件沿用既有 DWC-I10/I11：事件可见拍就组合令两份 `lookup_hit_o=0`，不是等沿上清
  `valid_q` 后才生效；沿上以全 cache 最高运行期优先级清 valid，吞掉该沿全部 fill/store/peer
  valid update。MMU flush 则由 `OooSv39Tlb.lookup_context_hit_o` 的 `!clear_i` 同拍屏蔽和
  quiet carrying contract共同闭合，禁止旧翻译在事件拍进入 D-cache/AXI。
- wrapper 不生成/合并 page/access fault，不改变每 lane response identity，不授予 architectural
  completion；F1 的双 response 只是叶级 bridge terminal，正式 WB credit 留给 F2。

#### 2.7.6 owner / source-of-truth

| 事实 | 唯一真源 | 禁止替代 |
| --- | --- | --- |
| laneN architectural transaction identity | bridgeN 的 active/station/held-response tuple + 外部 laneN expected/tracker/station truth | wrapper lane bit、地址 bit3、另一 lane tuple |
| 共享 miss transport owner | F0 `owner_q` | bridge token、live VALID、response READY |
| 本地 cache maintenance authority | bridgeN 既有 `dcache_store_commit_w` | 裸 `BVALID/BRESP`、AW/W fire、request write |
| peer maintenance payload | producer 的本地 maintenance address/wstrb | consumer 当前 request、arbiter payload、bank index |
| peer cache visibility | peer D-cache `valid_q` + exact lookup suppression | SRAM tag/data 残留 |
| 双 completion | 两份 bridge response 及各自 metadata | wrapper 单一 mux/priority encoder |

F1 wrapper 不新增 architectural identity 状态；它只装配两份既有 bridge 和 F0 transport owner。

## 3. 状态、优先级与资源共享

### 3.1 FSM

| 状态 | 输出/接受 | 迁移 |
| --- | --- | --- |
| `S_IDLE` | 所有 READY/VALID 为 0；计算两个合法 request predicate | 时钟沿按 `rr_q` 捕获 owner/type；无请求则保持 |
| `S_READ_ADDR` | 只路由 owner AR；R 不可见 | AR fire -> `S_READ_RESP` |
| `S_READ_RESP` | 只路由 downstream R 到 owner | R terminal -> `S_IDLE`，`rr_q<=~owner_q` |
| `S_WRITE_DATA` | 对未 seen 的 AW/W 独立路由 | 两者均 seen -> `S_WRITE_RESP` |
| `S_WRITE_RESP` | 只路由 downstream B 到 owner | B terminal -> `S_IDLE`，`rr_q<=~owner_q` |

IDLE capture 优先级：先检查任一 lane 是否非法 dual-type；若是则全局不捕获。否则只有
lane0 请求时选 lane0，只有 lane1 请求时选 lane1，两者都有时选 `rr_q`。lane request
合法条件为 read-present XOR write-present，其中 `write-present = awvalid || wvalid`。

fairness 不是无条件周期承诺，而是 transaction-bounded 条件：若两个 lane 在每个 IDLE
捕获点都持续给出合法请求，且每个已捕获 owner 最终补齐 AW/W、下游最终接受 request/
返回 response、owner 最终给出 response READY 从而产生 R/B terminal，则等待 lane 必须在
当前 terminal 后的**下一个 IDLE 捕获点**获选；同一 lane 不得连续赢得两个双竞争捕获点。
没有这些 progress 假设时，本合同不声称固定 cycle bound。

### 3.2 共享资源与关键路径

共享资源只有外部 AXI master。两条 DTLB/D-cache hit 路径在未来 F1 位于仲裁器之前。
F0 的关键组合路径是 registered owner -> 2:1 payload mux -> downstream channel，以及
downstream response -> owner demux。IDLE contender 选择只写寄存器，不直接穿到 downstream。

后续 2x bridge 初始实现允许复制 DTLB 和 32KB D-cache 以先闭合架构；这会使 cache macro
容量翻倍，只能标记为 architecture prototype、PPA unqualified。F4 前应改为真正两 bank
等总容量宏或给出面积可接受证据。

### 3.3 F1 装配、缓存维护与优先级

F1 wrapper 本身无新时序状态；`u_bridge0/u_bridge1/u_miss_arbiter` 保持各自状态机。两 bridge
的完整 raw AXI 子集进入 F0，对端 R/B 只回锁定 bridge。common flush/context 只 fanout，
禁止 wrapper 内生成跨 lane ready/valid 聚合状态。

每个 D-cache 新增的 peer invalidation 是 valid-only sideband：首 line index 由维护地址直接
计算；`wstrb` popcount 与低 3 位只用于判跨线，跨线时再清 `index+1`。它不读/写
`Sram4096x113`，因此不成为现有 lookup/fill/RMW 四 owner 的第五 owner。valid always block 中
peer clear 排在 local fill/store 之后，使同 index冲突最终为 invalid；不同 index 的 local
update仍执行，禁止把 peer 写成吞掉整拍 local update 的全局 `else if`。DMA 仍位于外层更高优先级。

lookup 判决使用已锁存 lookup tag/index；若当拍 peer event 的首/次 line 与该 exact line 相同，
`lookup_hit_o` 必须组合为 0。仅在时钟沿清 valid 而不做当拍屏蔽会产生一个 stale-hit 窗口，
属于 F1 blocker。peer event 与不相关 line 的 lookup 可并行；实现可以因 index 保守清除造成后续
额外 miss，但不得把不相关 event 广播成全 cache invalidate。

F1 初始复制两份 4096x113 SRAM 宏和两份 4096-bit valid，容量/面积约为当前 D-cache 的两倍。
该结构是 architecture prototype，只用于先验证并行 hit/维护拓扑；在等总容量双 bank 宏、macro
Liberty/LEF/OOC 条件和 arch-stable freeze 前，任何 area/timing/power 数字均
`diagnostic, promotion_eligible=false`。

## 4. S2 总体拓扑与分阶段退出条件

1. `OooIntIssueQueue/OooIntBackend`：保留 v8p 两个 reservation owner；按 VA/PA 页内稳定
   位 `addr[3]` 路由到 bank0/1，同 bank 由较老 owner优先，不同 bank 可同拍 fire。
2. `u_miq0/u_miq1`：每 bank 独立 request credit 和 in-order bridge pairing；两个 response
   可同拍独立匹配 exact kind/token/epoch/tval。
3. `u_bridge0/u_bridge1`：两份 station/DTLB/PTW/cache FSM；一个 PTW miss 不阻塞另一 lane
   的 TLB/cache hit。普通 request 的地址位 3 在 Sv39 翻译前后相同。
4. final-PA query：每个 bridge 在 cache/target admission 前输出 exact token、PA、size；
   backend 用 token->full ProducerId 映射和 SQ physical byte CAM 返回 allow/forward/replay。
   TLB miss 路也必须经过同一物理 query，不能只在 hit 快路检查。
5. cache coherence：普通数据 line 按 bit3 唯一 bank；page-walk cache 可能复制 PTE line，
   任意 store/A-D/B terminal maintenance 必须向 peer bank 广播 conservative invalidate；
   DMA/mmu flush 必须同时作用两 bank。
6. `OooDualMemAxiArbiter`：只合并两 bridge 的 miss/maintenance AXI，锁到 terminal。
7. completion/WB：两个 response 各自持有 metadata 和 terminal credit；同拍两 load completion
   需要两个 formal WB credit，不能压成单一 mux 或丢失其中一个 owner。

阶段退出门：

| 阶段 | 退出条件 | 声明边界 |
| --- | --- | --- |
| F0（v8q） | arbiter release/assert、AW/W skew、双 read 公平、response isolation、锁持有 mutation 全过 | `dual_axi_miss_fabric_leaf_verified`；DI-5 RED |
| F1 | 双 bridge wrapper + peer invalidate + real cached-hit 双 admission 叶级验证 | 未接 backend，DI-5 RED |
| F2 | 双 request/MIQ/response 端到端接入，LL 不同 bank 可同拍 fire/complete | 缺 physical query 时 DI-5/OOO-3 RED |
| F3 | 两路 final-PA SQ byte query、alias wait/forward/replay、TLB miss 同路径 | 可运行 DI-5/OOO-3 directed gate，仍需全量证据 |
| F4 | 64-cycle IPC>=1.90、response-credit/station lookup、exact-token retry residency、release/assert、compile-success RTL verification variants、同 design_id manifest、module/official/AM/必要 DiffTest | 仅全部通过后才可提升 DI-5；PPA 仍需 arch-stable freeze |

## 5. F0/F1 不变量与可执行证据

立即断言至少覆盖：

- `ARB-REQ-CLASS-ONEHOT`：每 lane read-present 与 write-present 不可同时为 1；
- `ARB-OWNER-HOLD`：非 IDLE 到 terminal 前 `owner_q/is_write_q` 不变；
- `ARB-NONOWNER-ISOLATION`：非 owner 的 request READY/response VALID 恒 0；
- `ARB-AW-ONCE` / `ARB-W-ONCE`：seen 后不重复 fire；
- `ARB-WRITE-TERMINAL`：两 channel 完成前 B 不可见；
- `ARB-READ-TERMINAL`：AR fire 前 R 不可见；
- `ARB-RSP-ONEHOT`：R/B 不可广播到两个 lane；
- `ARB-IDLE-QUIET`：IDLE 不展示下游 request/response ready。

定向 TB 必须分别在 release 与 `OOO_ASSERT` 下证明：

1. lane0/lane1 单独 read；2. 两 lane 同时 read 的 round-robin terminal fairness；
3. AR 长反压时 owner/payload 稳定；4. R 长反压时只对 owner 可见；
5. AW-before-W、W-before-AW、同拍 AW/W；6. B 长反压时锁不释放；
7. 当前 owner terminal 后等待 lane 最迟下一事务被选；8. 非 owner READY/VALID 全零。

compile-success mutation 固定至少十二族：`read_release_on_ar`、
`write_release_on_aw`、`write_release_on_w`、`aw_seen_tieoff`、`w_seen_tieoff`、
`broadcast_rvalid`、`swap_rready`、`broadcast_bvalid`、`fixed_lane0_priority`、
`rr_update_on_capture`、`idle_fallthrough`、`reset_owner_residue`。每项独立记录
`compile_success/elaborated/activated/target_rejected` 和唯一目标失败码；四者全真且没有
无关 assertion/fatal 才算检出。release 与 `OOO_ASSERT` baseline 分别 fresh 运行；非法
dual-type 另以 assert-negative 运行并要求 `ARB-REQ-CLASS-ONEHOT`。

静态 checker 必须在剥离注释后对目标 module、五个状态、registered owner/type、两个
seen 位、R/B terminal 更新、非 owner 隔离赋值和 scoped claim 做非零且唯一/期望次数命中；
零匹配、只命中注释、空 module 或旧日志均失败。focused runner 在运行前后哈希 RTL、TB、
checker、mutator、runner、spec/contract、filelist/构建参数的完整闭包，并给 release/assert、
每个 mutation 与 run id 写 fresh digest。唯一总 PASS marker 只能在所有 TB、十二个 mutation、
source/claim checker 与 pre/post hash 相等后产生。claim checker 还必须证明 F0 未在 canonical
core 被实例化、未修改 architecture evidence，并拒绝把 leaf 结果写成 DI-5、OOO-3、overall
或 PPA GREEN。

### 5.1 F1 新增不变量与反例门

立即断言/旁挂 checker 至少覆盖：

- `DWC-PEER-HIT-BLOCK`：peer event 命中当前 lookup exact line 时 `lookup_hit_o=0`；
- `DWC-PEER-INVALIDATE`：peer event 后首 line（及跨线次 line）valid 不可见；
- `DWC-PEER-NO-SRAM-OWNER`：peer event 不得独立产生 SRAM enable/write，也不计入 1RW owner；
- `BRG-PEER-MAINT-AUTH`：bridge 导出 valid/address/wstrb 与既有 authorized local maintenance
  逐拍一致；参数关闭时 peer 输入不改变 cache 行为；
- `DMBW-MAINT-CROSS`：lane0 producer 只连 lane1 consumer，lane1 producer 只连 lane0
  consumer，禁止 self-only、断路或地址/宽度串线；
- `DMBW-RSP-INDEPENDENT`：两份 bridge response 可同拍，metadata 不合并；
- `DMBW-HIT-BYPASS`：一侧 F0 miss owner 未 terminal 时，另一侧 hot lookup admission/response
  不依赖 F0 idle/owner/downstream READY。

F1 directed TB 必须至少证明：

1. 分别经真实 miss/fill 预热两个 cache，随后同拍发两个 request，二者同拍 fire、无 downstream
   AR，并在同一判决拍形成两个 exact-token hit response；
2. lane0 cold miss 被 R backpressure 锁在 F0 时，lane1 hot request 仍 fire 并完成，lane0 owner/
   payload 不漂移；lane0/lane1 角色互换至少一组；
3. 两 cache 预热同一 PA 后，lane0 store 在 request/AW/W 与 B 反压期间不得提前使 lane1 line
   失效，只有真实 B terminal 才使 lane1 后续 load 变 miss；lane0 本地 all-OK CACHED store 仍
   按既有 RMW 得到新数据；B-error/NC 或 A/D 至少一类验证 peer 只失效不更新；
4. peer B terminal 与对端同 PA lookup 判决精确重合时，对端不得返回 stale hit，必须等待 F0
   捕获并从 AXI 取 fresh data；
5. 跨 8B store 的 peer 次 line 被失效；不相关 line lookup 不被当拍误屏蔽；
6. DMA pulse 同拍使两 cache old line 均不可命中；MMU flush 同拍作用两 DTLB 的结构连接由
   checker 审核，不把物理 D-cache 误写成 mmu-flush 清空；另以参数关闭实例把 peer input
   拉高，证明 legacy 单桥/cache 的 hit、valid 与 SRAM owner 不受该输入影响；
7. direct cache 冲突矩阵覆盖 peer 与 local fill 的不同 index、同 index 不同 tag、同一 exact
   line，分别证明无关 fill 可见及目标 index peer-clear 获胜；枚举 1/2/4/8B 合法 mask 的所有
   `addr[2:0]` 跨线结果，并用 assert-negative 拒绝 zero/稀疏/lane-shifted mask；
8. `mmu_flush_i` 在两 bridge 非 idle 时必须由 wrapper carrying-contract assertion拒绝；合法
   idle 事件拍两 lane READY/hit均为零，事件后首个 paged request只能重新 walk。同步 reset覆盖
   peer/DMA/lookup/pending-response重合，第一采样沿后无旧 hit/response或延迟维护脉冲。

compile-success mutation 至少包含：`disconnect_peer_valid`、`self_only_peer`、
`swap_peer_addr`、`request_time_maintenance`、`b_ok_only_peer`、`drop_cross_line_peer`、
`remove_same_cycle_hit_block`、`fill_wins_peer`、`gate_lane1_ready_on_arbiter_idle`、
`merge_dual_response`。每项必须 compile success、elaborated、activated，并由唯一目标 oracle
拒绝；不能以编译失败或无关 assert 充数。F0 十二族 mutation 继续由其永久 target 独立承重。

F1 runner 必须 fresh 运行 release/assert/assert-negative（若有）、上述 mutation、静态 source/
claim checker和 F0 permanent target，绑定 wrapper/bridge/cache/arbiter/TB/checker/mutator/spec/
runner/filelist 的 pre/post closure digest。唯一 PASS claim 只能是
`dual_bridge_cache_hit_leaf_verified`。阶段拓扑必须 fail-closed 且可前向兼容：canonical 尚处 F1
时，checker 证明 wrapper 未在 `NpcCoreTop/NpcTop` 实例化且旧单桥恰有一份；canonical 晋级
F2 后，checker 改为证明双桥恰有一份、旧单桥为零、`ENABLE_DUAL_MEM(1)` 恰有一次，并核对
F2 contract/spec 的显式交接。两种状态都不能把叶级 claim 扩大为架构结论，DI-5/OOO-3/
overall 仍 RED、PPA unqualified；额外实例、混合拓扑或缺失交接一律拒绝。

### 5.2 F2 canonical 集成状态与证据边界（v8s）

F2 已把 `OooDualMemBridgeWrapper` 接入 `NpcCoreTop`，并沿
`OooCoreTopGlue → OooExecuteBackend → OooAluCoreSlice → OooAluDecodeBackend → OooIntBackend`
逐层显式传播默认关闭的 `ENABLE_DUAL_MEM` 参数；只有 canonical `NpcCoreTop` 固定置 1。
backend 以捕获地址 `addr[3]` 分 bank，维护两份独立 MIQ、expected/query/drop/residency 面和
两路 ROB-open completion query；共享的两槽 WB、两端口 SQ terminal/fill 及 32-token terminal
pending set 对两 bank 做一次全局分配。bank0 仍独占 SQ physical drain 与 LEGACY AMO/LR/SC，
bank1 只接 ordinary LOAD/PROBE；LEGACY 发射及 final response 释放边都禁止 ordinary
look-through。

F2 focused gate 必须在 release 与 `OOO_ASSERT` 下至少覆盖：正反 bank 映射、四种 reservation
consume mask、异 bank 双 request/双 response、同 bank 年龄选择（含真实 ROB index 跨零环绕）、
真实单 WB credit 下另一路 response 稳定反压、两个 edge-old EX completion 同时占满 WB0/WB1
时双 memory response 保持并在槽释放后双恢复、双 store probe fill、双 store probe fault 的双 WB/双 SQ terminal、全局
flush 后两 bridge exact-drop、AMO singleton 同拍优先和 release-edge 不穿透。source checker
必须拒绝 parameter 漏传或 canonical 未使能、lane tie-off/cross-wire、第二 MIQ/ROB query 删除、
局部 WB free-count 双重认领、collector ingress 缩回、第二 SQ fill/terminal 删除以及 wrapper
退回非 canonical。compile-success mutation 必须独立证明这些 oracle 会拒绝对应语义破坏。

Current F2 claim: `architecture_checkpoint`.

该固定句是 F1→F2 source checker 使用的机器可检交接哨兵，描述 F2 checkpoint 的阶段边界，
不替代后续 F4/全核架构证据的当前状态。

- DI-5: RED
- OOO-3: RED
- overall architecture: RED
- PPA: unqualified
- promotion_eligible=false
- F3: `final_pa_sq_ordering_checkpoint`（两路 final-PA SQ byte query/forward/replay、双 bank
  retry holder、release/assert directed、38 项 compile-success mutation、bounded holder proof、
  F0/F1/F2 前置与独立实现审查在同一 functional source closure 上闭合；该结论只覆盖 F3）
- F4: absent（尚无 64-cycle IPC、系统 workload、同 design-id aggregate 与 arch-stable PPA）

上行是 F2 checkpoint 的固定机器可检边界；当前 F4 行为合同与 V9L 修订见 5.3，正式 PPA
仍须另行冻结。

因此 F2 的 canonical 接通不是 DI-5/OOO-3 完成声明；复制 cache 的总容量也尚未归一化，
所有 synthesis/STA/area 只能是 diagnostic，不能进入 promotion。

### 5.3 F4 response credit 与 retry residency 修订（V9L）

F4 的 station 前视用于提前完成 SQ final-PA 判决，但不增加第二个 response 容量或第二个
SRAM read owner。对 `station_sq_lookahead_query` 的三类结果冻结如下：

- `forward/replay`：不得发起 D-cache lookup，也不得产生 AXI/terminal 副作用；
- `allow && rsp_ready`：允许 station 同沿晋升并发起同步 SRAM lookup；
- `allow && !rsp_ready`：SQ 判决可以保持 allow，但 SRAM lookup 必须关闭，沿后由已寄存状态等待
  response credit。断言因此检查 `allow -> (dcache_lookup_en == rsp_ready)`，不得退回
  `allow -> dcache_lookup_en` 的过约束形式。

每个 memory bank 的 retry holder 是一份 exact owner 状态。holder 有效时必须阻止新的同 bank
load admission，但 F4 可能已经在 bridge station/active 中保留另一条更年轻事务；只要二者
owner token 不同，这种双驻留合法且必须继续保持。禁止的是 retry token 在同 bank
active/station 中出现第二份副本。专项正向测试必须证明“不同 token 可并存且新 admission 仍关闭”；
compile-success RTL 断言验证变体必须把断言恢复成“任意 load residency 都非法”，并由该正向轨迹
精确拒绝，从而证明现行 exact-token 判据不是无效断言。

以上修订只澄清 F4 流控与 owner 身份，不改变 cache 容量、宏实现或 PPA 声明等级。架构证据必须
在每次 production RTL 变化后按当前 design-id 重放；未完成 arch-stable freeze 前，综合、STA、
area 与 power 仍为 diagnostic / unqualified。

## 6. 晋级边界

F0 只验证共享 miss fabric 的 transport safety/fairness。它不证明两路 AGU、翻译、物理
消歧、cache admission、credit 或 completion 存在，也不改变当前 canonical core 的功能或
PPA。architecture hard gate 必须继续因活的数据面缺口而 fail-closed；任何 source checker
只发现未实例化的 `OooDualMemAxiArbiter` 都不得把 DI-5 置绿。

F1 即使验证通过，也只证明未接入 wrapper 内的两份 bridge/cache 能并行命中、共享 miss fabric
且正确做 peer alias maintenance。它仍不证明 backend 有两份 MIQ/credit、request 已按 bank
路由、final-PA SQ 消歧存在、两个 response 有正式 WB credit，或系统持续达到目标 IPC。因此
architecture gate 只能新增叶级 claim；canonical core 仍保持单 bridge，DI-5/OOO-3/overall
继续 RED。复制 cache 的结构不得进入正式 PPA 对比，除非后续先改成等总容量 bank 并重新冻结
arch-stable baseline。

进入 F2 后，上段是 F1 历史边界而不是当前拓扑描述：当前 canonical core 已使用双 bridge、
双 MIQ 与共享双 WB allocator；F3 final-PA SQ 消歧数据通路已获得严格限域的
`final_pa_sq_ordering_checkpoint`，但持续 IPC/F4、全系统 aggregate 和
arch-stable PPA 也仍缺失。因此当前仍只能交付 `architecture_checkpoint`，DI-5、OOO-3、
overall 保持 RED，PPA 保持 unqualified；不得把 F2 局部行为或 F3 checkpoint 证据外推为完整
架构或性能晋级。
