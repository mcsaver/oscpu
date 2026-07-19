# 规范：访存桥状态机 OooMemAxiBridge（FSM / flush-drain / 响应时序）

> 模块：`vsrc/memory/OooMemAxiBridge.v`。本规范逆向并固化其控制 FSM。历史 B1
> (store AW/W-fire 写回解耦) 已被 T4I lane-adapter owner 契约取代；当前所有
> store 都等待聚合 B。模板见 `../arch/SPEC-TEMPLATE.md`。状态：**已文档化当前实现（行为基线，
> 2026-07-03 RTL 重读校正）**。T3W 将 req load 的内部 D-cache SRAM 读与
> DTLB/PMP 判决并行化；只有授权结果可消费投机 payload。
> T4C 进一步把 PTW leaf 的地址 payload owner 固定为 `S_WALK_R`，而
> `walk_read_lookup_fire` 只保留权限/类型/有效性许可；两者不得再在 SRAM
> 地址 mux 上合并。T4E 固化 AXI AR hold：注册地址 owner 的 VALID/payload
> 在 READY 前不受 flush/drop 撤回，握手后由桥本地吞掉 R。T4F 补齐
> A/D PTE 回写前独立的 S-mode/8B/WRITE PMP authorization。T4H 在最终数据 PA
> 上增加与当前 `NpcTop` 实例地址图一致的 fail-closed PMA 检查，使默认/空壳窗口的
> plain store 在 probe 阶段形成精确 access fault，而不是退休后才观察到 B 错误。
> T4I 将标准 AXI lane/split 放在 NpcCoreTop 独立 adapter；本桥继续输出 logical low-window，
> 但 cacheable line 与 uncached exact read 的 owner 必须显式区分。
> T4P 新增同步 virtio queue-notify DMA 完成事件的透传；桥不为其增加 FSM 状态，
> D-cache 在事件拍屏蔽 hit 并 valid-only 全失效。

## 1. 目的与范围
把后端 lane0/lane1 的访存请求（含 Sv39 翻译、PMP、dcache）落到 LSU AXI 总线，并把结果回送后端。
FSM 单事务在飞（single outstanding）+ 桥侧 req 寄存站单深度排队（P5 刀 M：桥内至多
"1 站内待发 + 1 FSM 在飞"，两者都记账在 MIQ）。本规范只描述控制 FSM 与响应/flush 时序，
不展开 PTW/PMP/PMA 的编码细节。

DMA 边界只覆盖当前仿真 `AxiVirtioBlk`：queue-notify 的 DPI task 同步完成本批 guest PMEM
写后，经 `NpcSimTop -> NpcTop -> NpcCoreTop -> OooMemAxiBridge` 送入
`dcache_dma_invalidate_all_i`。桥仅把脉冲透传给 `OooDataWordCache`，不把它解释为请求、
不占 AXI owner、不改变桥 FSM，也不声明 autonomous DMA 或通用 IO coherence。

## 2. 状态与 req 寄存站
| 状态 | 含义 |
|---|---|
| （req 寄存站） | 【P5 刀 M】非 FSM 状态：`stg_*_q` 8 字段(valid/addr/wdata/wstrb/write/probe/pretrans/nokill)。req fire 拍**零计算**只锁存字段；翻译/权限/分流推迟到 `stage_advance_w`。T3W 对每个 advance load 同拍投机发内部 D-cache SRAM read，地址用翻译命中 PA，否则用原地址候选；DTLB/PMP/PMA fault/miss 只丢弃 raw payload，不得消费为 hit。CSR 上下文不进站——寄存站占用⇒MIQ 非空⇒mem_idle=0⇒CSR/trap 不能退休，advance 拍上下文必与 fire 拍相同（KM-STG-CTX） |
| S_IDLE | 空闲，等寄存站项 advance(`accept_request` 从 `stg_*` 取数) |
| S_LOOKUP | 【SRAM 同步读】dcache 判决态：上拍已发单口读，本拍 SRAM rdata 有效，判 hit(→S_RESP)/miss(当拍发 AR) |
| S_DEVICE_WAIT | 【T4M】最终授权 PA 为非 PMEM 的 read 等待精确 non-spec owner；release 前无 data AR，cancel 则 quiet response |
| S_WALK_AR/S_WALK_R | Sv39 页表遍历 发 AR / 收 PTE；`S_WALK_R` 同时是 leaf-derived lookup 地址的固定角色 owner，RVALID/PTE/PMP/A-D 只决定是否抬 lookup enable |
| S_READ_ADDR/S_READ_DATA | load: 发读地址 / 收读数据 |
| S_WRITE_REQ | store: 发 AW+W |
| S_WRITE_RESP | store: 等 B |
| S_RESP | 向后端拉 `mem*_rsp_valid`，等 `rsp_ready` 后回 S_IDLE |

寄存站进出与 ready（`stage_advance_w` = FSM 收下寄存站项的时机 = 原 accept 语义时点）：
```
stage_advance_w  = stg_valid_q && !dcache_rmw_busy_w &&
                   (S_IDLE || (S_RESP && rsp_ready_w)) &&
                   (!cpu_kill_w || stg_nokill_q)
mem0_req_ready_o = !flush_i && (!stg_valid_q || stage_advance_w)
```
- `!flush_i` 必须保留在 ready（关键决策，非可选）：MIQ 的 flush 分支是 else-if，flush 拍
  push 被忽略——flush 拍若允许 fire 即"桥内有事务、MIQ 无记账"（rsp 无主/序配对破坏）。
  ready 含 `!flush_i` ⟺ MIQ 不漏记 ⟺ 寄存站项↔MIQ 项双射（BRG-NOFIRE-FLUSH +
  跨模块 KM-STG-MIQ 断言化）。
- `drop_rsp_q` 退出 ready：drain 窗口寄存站可提前收下 correct-path 请求排队（免费 skid，
  部分抵消 +1 拍 CPI），advance 由 state 门天然挡住。
- `rmw_busy` 从 ready 迁入 advance：RMW 判决拍请求可进站，bubble 观察点从 ready 压制变
  寄存站保持（bubble 数不变，见 §3 要点）。
- flush 拍：非 nokill 站内项当拍清除（未发射即止损，全程不发 lookup/AR/rsp，比旧"进 FSM
  再 drain"更早）；nokill（SQ drain 落存）项存活，且可在 flush 拍照常 advance 进 FSM
  （写必达，BRG-STG-NOKILL 断言）。

## 3. 正常转移（`else` 分支，flush_i=0 且 drop_rsp_q=0；req=寄存站项 advance）
```
 (寄存站) --advance(load,任意翻译结果)--------------> 同拍投机发 dcache 同步读
              |--可翻译无fault,PMEM-----------------> S_LOOKUP(锁 paddr_q/wstrb_q/read_cross_q，次拍才可消费 raw payload)
              |--可翻译无fault,device---------------> S_DEVICE_WAIT -(release)-> S_READ_{ADDR|DATA}
                                                                  \-(cancel)-> S_RESP(quiet,no AR)
              |--DTLB/PMP/PMA fault 或 TLB miss-----> fault response / PTW（投机 payload 无效）
 S_LOOKUP --(hit 且 !read_cross_q)-----------------> S_RESP(判决拍锁 rsp_rdata = line >> {paddr_q[2:0],3'b0})
 S_LOOKUP --(miss/跨线)----------------------------> S_READ_ADDR -> S_READ_DATA -(rvalid)-> S_RESP
                                                    (判决拍当拍发 AR;arready 即 fire 时跳过 S_READ_ADDR 直入 S_READ_DATA)
 (寄存站) --advance(store,probe,PMP/PMA allow)-----> S_RESP(不写内存,PA 经 rsp_rdata 回传)
 (寄存站) --advance(store,no-trans)----------------> S_WRITE_REQ -(aw&w)-> S_WRITE_RESP -(bvalid)-> S_RESP
 (寄存站) --advance(need-trans,tlb-miss)-----------> S_WALK_AR -> S_WALK_R -(...)-> {S_RESP | S_LOOKUP | S_WRITE_REQ | 下一级 S_WALK_AR}
 S_WALK_R --(leaf-ok,read,PMEM)--------------------> S_LOOKUP(当拍发 dcache 读,addr=walk_leaf_paddr_w；addr owner 由 state 固定，fire 只作 enable)
 S_WALK_R --(leaf-ok,read,device)------------------> S_DEVICE_WAIT
 S_AD_UPDATE --(b-ok,read,PMEM/device)-------------> S_LOOKUP / S_DEVICE_WAIT(用锁存 paddr_q 分类)
 S_WALK_AR --(PTE 读地址 PMP 违例,F9)-------------> S_RESP(access fault,不发 AR)
 (寄存站) --advance(pmp/pma/perm/page fault)-------> S_RESP(error/page_fault 置位)
 S_RESP --(rsp_ready)-----------------------------> S_IDLE(站内有项则同拍 advance 直接 accept,back-to-back;
                                                    且 advance 拍站口腾出、新请求可同拍 fire 进站)
```
要点：
- **store 统一等 B（T4I）**：`S_WRITE_REQ` 的 AW/W fire 只表示
  `OooLsuAxiLaneAdapter` 已收下逻辑命令，不代表所有物理 beat 已落存。
  PMEM/MMIO/uncacheable store 均进 `S_WRITE_RESP`，以聚合 B 作唯一完成点，
  `rsp_error` 统一来自 `bresp`。这保证 split write 不被后续 read 越过，并让
  adapter 粘滞错误可见。
- **事务三属性（LSQ·SQ 切换新增，T4H 收紧）**：`probe`=write 探测（翻译+PMP+PMA
  走完不写内存，PA 经 rsp_rdata 回传）；`pretrans`=地址已是此前 probe 授权的 PA（SQ drain
  落存），功能路径跳过翻译/PMP/PMA，`MEM-PMA-PRETRANS` 断言复核其静态地址图 provenance；
  `nokill`=flush/drop 对该事务失效（已退休 store 写必达）。三位全 0 时行为与旧版一致。
- **line 读（LSQ Phase2+3 + T3W speculative read）**：dcache 为 32KB 直映 word cache（`OOO_DATA_WORD_CACHE_INDEX_W=12`，
  tag+data 已进 1RW 同步读宏 Sram4096x113）。每个 staged load advance 拍先发内部单口读；
  同拍 DTLB/PMP/PMA 决定是否有权进入 S_LOOKUP，并只在授权路径锁
  `paddr_q/wstrb_q/read_cross_q` → **S_LOOKUP 判决拍**：hit 且不跨线 → `rsp_rdata` 按 line 内偏移
  （`paddr_q[2:0]`）右移出 CPU 视图 → S_RESP；miss/跨线 → 判决拍当拍发 AR（不跨线发 line 对齐 AR、
  回填整 line；跨线按原地址窗口读且不 fill）。**load hit 1→2 拍、miss AR 晚 1 拍**是 SRAM 化一期
  接受的代价；store/probe/fault/walk 分流决策不依赖 dcache，仍在 fire 拍完成。walk 路径
  （S_WALK_R leaf-ok read 与 S_AD_UPDATE b-ok read）同样发 dcache 读进同一 S_LOOKUP 统一判决——
  此举顺手修复两个既有 bug：① 旧 walk 组合口无移位无跨线检查、把未移位整行当 rsp_rdata（S/U 态
  walk-leaf 命中 + offset≠0 时 load 回错值）；② S_AD_UPDATE 的 walk 命中判定依赖 R 通道已完事的
  live `lsu_axi_rdata_i`（靠 xbar 保持 rdata 才碰巧对）——现统一用锁存 `paddr_q`。
  `req_ready` 在 S_LOOKUP 为 0（单 outstanding 不变）；`read_cross_q` 在 accept 拍按 VA 低 3 位判定，
  VA/PA 页内偏移相同故对 walk 路径同样成立。D-cache 模块级 lookup/fill/store 维护语义由
  `ooo-data-word-cache.md` 冻结（store 维护 = 2 拍 RMW write-update，v1.1），桥 spec 只约束
  事务级 FSM 与 AXI 行为。
  投机 read 只能改变 SRAM raw rdata/lookup shadow；不得置 valid、fill、RMW、replacement，
  也不得在 fault/walk/miss 路径产生成功 response 或 data AXI AR。
  **T4C PTW valid/payload 分离**：`walk_lookup_payload_owner=(state==S_WALK_R)`
  只选择 `walk_leaf_paddr_w` 到 lookup address；`walk_read_lookup_fire` 继续完整包含
  RVALID/RRESP/PTE validity/permission/PMP/A-D/read-only 条件；`fsm_normal/RMW`
  继续在 `dcache_lookup_en_w` 外层把关实际发射。因此所有 `lookup_en=1` 的地址与旧实现逐位相同；差异只在
  S_WALK_R 等待、invalid/nonleaf、PMP deny、A-D needed、write 或 flush/drop 的
  `lookup_en=0` 周期，D-cache 不锁 lookup context、SRAM enable 不抬，没有可见副作用。
- **T4P 同步 virtio DMA 完成边界**：`dcache_dma_invalidate_all_i` 不参与
  `stage_advance_w`、状态转移或 1RW 宏口仲裁，只透传到 D-cache。DPI 已先完成 data/status/
  used-ring PMEM 写；失效脉冲可见拍 D-cache 组合屏蔽 `lookup_hit_o`，因此即使正处于
  S_LOOKUP 判决拍也必须走 miss/AR，从已更新 PMEM 取 fresh line，而不能融合旧 cache line。
  下一沿清空全部 valid；`AxiVirtioBlk` 直到该沿才把锁存的 notify B/IRQ 发布，故 CPU/PLIC
  观察到完成时 cache 已采样失效。全失效只丢 clean line：当前 CPU store 均在聚合 B 后更新
  D-cache，没有 dirty/write-back 数据。该端口不覆盖设备自主异步写、line snoop 或任意 DMA master。
- **T4I cacheable/exact read 边界（已实施）**：只有 cacheable 且不跨 8B line 的
  miss 才能发 `{paddr[63:3],3'b0},ARSIZE=8B` 并 fill；uncacheable 或跨线访问必须发 exact
  `paddr,ARSIZE=原访问宽度`，raw RDATA 保持 low-window 且禁止 fill。后者由 NpcCoreTop 的
  `OooLsuAxiLaneAdapter` 转成标准 lane；misaligned 再拆 byte 微事务。桥不得再用全行 MMIO read
  扩张设备 side effect，也不得把 adapter 下游 lane 语义反向渗入 SQ/forwarding。
- **T4M 翻译后 device non-spec owner**：最终 data PA 的 device 分类只属于 bridge；VA 数值窗
  不能替代该判决。direct/Bare/DTLB-hit、PTW leaf 与 A/D update continuation 三条 read 路径若
  最终 PA 非 PMEM，均先进入 `S_DEVICE_WAIT`。backend 只在当前 MIQ head 未 kill 且等于 ROB head
  时 release；MIQ killed 则 cancel。wait/release 前、cancel 与 wait 中 global flush 均不得发
  data AR；cancel 只生成 quiet response 给 MIQ 静默 pop。release 后复用 exact read payload 与
  既有 AR hold/drain。translated PMEM 仍走原 S_LOOKUP，不得被 ROB-head 门控。
- **store RMW write-update（2026-07-09 赎回，刀 M 重述观察点）**：真 store commit
  （S_WRITE_RESP b-ok 拍——非 lookup/fill 消费态，dcache 宏读口
  空闲）即 dcache RMW 发射拍；次拍（判决拍，状态必∈{S_RESP,S_IDLE}）dcache 拉 `rmw_busy_o`
  占宏口，桥以 `!dcache_rmw_busy_w` 压 `stage_advance_w`——**store 完成后 1 bubble**
  （站内项被保持一拍；判决拍 ready 可为 1=新请求可进站排队，bubble 数不变）。
  `dcache_lookup_en_w`/S_LOOKUP-miss 的 arvalid 与状态转移同加
  `!rmw_busy` 安全网（状态互斥下恒不触发，MEM-RMW-PORT 断言把关）。
  普通与 flush-drain store 都只在 b-ok 拍单次提交，不再存在 AW/W-fire 早提交
  与双 commit 窗口。HW A/D PTE 写回维护（S_AD_UPDATE b-ok）不走 RMW
  （`store_rmw_en_i=0`，无条件失效）——该拍的 read 续访问可能同拍发 lookup，宏读口不空闲。
- **PTW 隐式访问 PMP（F9 + T4F）**：每级 PTE read address（`walk_pte_addr_w`）按
  S-mode/8B/READ 经独立 PmpChecker 检查，违例在 S_WALK_AR 报 access fault 且不发 AR。
  leaf 需要 A/D 回写时，再对同一 PTE address 按 S-mode/8B/WRITE 独立检查；WRITE deny
  优先于进入 `S_AD_UPDATE`，原 load/store 返回 `rsp_error=1,page_fault=0`，不发 AW/W、
  不填 DTLB、不续原访问。READ grant 不能替代 WRITE grant。取指侧同一合同见
  `ooo-fetch-axi-bridge.md`。
- **最终 PA 的静态 PMA（T4H）**：Bare、DTLB hit 与 PTW leaf 三条数据路径都在成功
  response、D-cache/AXI 数据访问及 A/D 后续动作前，用 `OooPmaChecker` 检查完整 byte range。
  当前允许 CLINT、PLIC、UART、virtio-blk、PSRAM、legacy-MMIO、SDRAM 的真实 RTL/外部端口；
  GPIO、PS2、MROM、VGA、FLASH、ChipLink 与 default 等 `AxiDefaultSlave` 空壳窗口 fail closed。
  名义 SRAM 窗口被更高优先级 PLIC decode 完整覆盖，故按实际 xbar 路由归入 PLIC。首尾地址必须
  位于同一允许区域，跨区域与地址回绕均拒绝。deny 返回 access fault（`page_fault=0`），不发
  data AR/AW/W、不填 DTLB、不进入成功 probe。PMA 是实现地址图，不受 M-mode PMP no-match
  放行语义替代。PTE read/write 的总线错误发生在原指令退休前，仍由 PTW 原路径精确报告；
  T4H 只补最终数据 PA 的提前判决。
- **Svnapot 64KiB**：PTW 只接受 level0 leaf 且 `PTE.N=1 && PTE.PPN[3:0]=4'b1000`；非 leaf、
  level1/2 leaf 或其它 NAPOT 编码均报 load/store page fault。合法 leaf 的 PA 拼接使用 VA[15:12]
  替代 PTE.PPN[3:0]，再进入 PMP、dcache 或 AXI 访问；DTLB hit 复核必须带 leaf level。
- FSM 单 outstanding 由**状态**强制：`stage_advance_w` 只在 S_IDLE 或 (S_RESP && rsp_ready)
  放行，写/读事务进行中(非 S_IDLE/S_RESP)寄存站项不进 FSM；dcache RMW 判决拍(store 完成次拍)
  额外压 1 拍。ready 只看寄存站占用（`!flush_i && (!stg_valid_q || stage_advance_w)`），
  **与 drop_rsp_q 无关**——FSM 忙/drain 期间新请求可进站排队（单深度）。

## 4. flush / drain 路径（`if (flush_i || drop_rsp_q)` 分支）
`drop_rsp_q` = "本地已放弃当前事务、但下游可能仍会回一个需吞掉的响应" 的粘滞标志。
- `cpu_kill_w = flush_i || drop_rsp_q`：压 CPU response、fill/lookup 等可见副作用；**不得**组合门控
  已由 `S_WALK_AR/S_READ_ADDR` 注册拥有的 AXI ARVALID。
- **T4E AR hold**：若 `S_WALK_AR/S_READ_ADDR` 已呈现 AR 且 READY=0，flush/drop 后继续逐位保持
  VALID/ADDR/ID/LEN/SIZE/BURST/PROT；READY 到达才转 `S_WALK_R/S_READ_DATA`，随后保持 RREADY
  本地吞掉残响应。`S_WALK_AR` 的 PTE PMP 已拒绝（从未呈现 VALID）可直接释放。
  `S_LOOKUP` 的组合 miss AR 尚未形成跨拍 owner，flush 当拍仍可取消；若其在前一拍已经
  VALID&&!READY，则同一边沿必转入 `S_READ_ADDR`，之后按上述规则保持。
- 读数据/PTE 态 flush 置 `drop_rsp_q` 并本地等待/吞掉 R；写态用 `write_drain_w` 把 AW/W 发完
  （避免半截事务挂总线），收到 B 后清 drop。S_RESP/S_IDLE 态清零并回 S_IDLE。walk/A-D 路的
  dcache 读发射（`walk_read_lookup_fire_w/ad_read_lookup_fire_w`）只在 FSM 正常推进分支有效，
  flush 拍不发。当前 xbar/总线没有 read-abort 边带，不能把 flush 当作撤销 AXI 握手的例外。
- 【刀 M】寄存站 flush 臂：`flush_i && !stg_nokill_q → stg_valid_q<=0`（payload 留脏，全核
  valid-only 惯例）。站内项=**未发** AXI/dcache 事务，flush 可清（比 FSM 内 drain 更早止损）；
  MIQ 侧同拍 flush-compress 掉对应 LOAD/PROBE 项，双射不破。若 head 是 nokill DRAIN 且 response
  与 flush 同拍 fire，MIQ 的 keep-set 必须先扣除该 fired head，再压缩其余 DRAIN，即
  `filter_DRAIN(Q_old - fired_head)`；不得把已消费 owner 复活。mispredict/ROB-walk kill 不触桥
  （现状无 kill 口），站内 killed LOAD/PROBE 照常推进发射，rsp 由 MIQ `head_killed` 恒收吞掉。
- 不变量：被 flush 的事务，其 AXI 响应必须被吞掉且不得置 `mem*_rsp_valid`（**nokill 事务例外**：
  `nokill_busy_w` 使 flush/drop 对其推进与响应握手均无效，写必达；站内 nokill 项同理存活并可
  flush 拍 advance）；半截写必须发完再丢 B。

## 5. 关键不变量
- **MEM-I1 单事务（刀 M 重述）**：FSM 单事务在飞——非 S_IDLE/(S_RESP&&rsp_ready) 寄存站项不
  advance；桥内至多 1 站内 + 1 FSM 在飞，两者都在 MIQ 记账（KM-STG-MIQ：`stg_valid_q ⇒
  !miq_empty`，mem_quiet 独占谓词族自动计入寄存站，任何消费点无需加 term）。
- **MEM-I2 写顺序可见性**：bridge 在聚合 B 到达前不报 store 完成；
  lane adapter 与 xbar 都在 B 前锁住 write owner，因而后续 bus read 不会越过未完成的
  aligned 或 split write。
- **MEM-I3 异常传递边界（SQ/T4H/T4I/T4N）**：所有 store 的聚合 `bresp`
  都会进 `rsp_error`，不再假设 PMEM B 恒 OK。plain store 的翻译/PMP/PMA fault 在 probe 前置；
  T4N 又让 ROB/SQ owner 保持到 physical write 的 B，故设备运行时 `SLVERR/DECERR` 也形成精确
  cause 7 terminal，`tval` 使用 SQ 保存的 original VA。B response 必须等 formal-WB credit，
  flush 不得吞掉 `nokill` physical owner。完整合同见 `ooo-store-bresp-precise-terminal.md`。
- **MEM-I4 无 ready/valid 组合环**：`mem0_req_ready` 只依赖 flush/寄存站占用/state/rmw/rsp_ready，
  不依赖本拍新请求是否 fire（valid）。
- **MEM-I5 PTW lookup owner/许可分离**：S_WALK_R 是 PTE-derived address 的唯一
  payload role；权限资格只能进入 lookup enable，禁止反向作为 address mux select。
  `fsm_normal && !rmw_busy && walk_read_lookup_fire -> state==S_WALK_R && lookup_en && addr==walk_leaf_paddr`；
  S_WALK_R 非 qualified-fire 时不得产生 lookup enable。
- **MEM-I6 AXI AR hold**：任一拍 `ARVALID && !ARREADY` 后，下一拍必须继续 ARVALID 且
  ARADDR/ARID/ARLEN/ARSIZE/ARBURST/ARPROT 逐位不变，flush/drop 不例外；握手后的 killed read
  只能经 R drain 释放。`MEM-AR-HOLD` 立即断言覆盖此契约。
- **MEM-I7 PTW PTE WRITE authorization**：真实 leaf A/D deny event 下一拍只能是
  access-fault S_RESP，且 deny 拍 AW/W 恒 0；grant 才能由正常 FSM 转入 `S_AD_UPDATE`。
  `MEM-PTW-PMP-WRITE` shadow 断言覆盖 deny→response 与无 side effect，不把写态期间的
  live PMP 配置误当成已锁存授权证据。
- **MEM-I8 PMA fail closed**：direct/Bare/DTLB-hit 与 PTW-leaf deny 都必须转 quiet access-fault
  S_RESP；deny 周期以及其 shadow 响应周期不得发 data AR/AW/W。pretrans drain 只能携带同一静态
  checker 认可的 PA。`MEM-PMA-DIRECT`、`MEM-PMA-WALK` 与 `MEM-PMA-PRETRANS` 立即断言覆盖三条边界。
- **MEM-I9 翻译后 device 无投机 AR**：`S_DEVICE_WAIT && !device_release` 时 data AR 恒为 0；
  cancel 与 release 互斥且 cancel 拍无 AR。release 只能驱动当前 FSM/MIQ head owner，进入
  `S_READ_ADDR/S_READ_DATA` 后继续服从 MEM-I6。global flush/drop 可取消尚未 release 的 wait，
  但不得撤销已呈现的 registered AR owner。
- **MEM-I10 DMA stale-hit 禁止**：`dcache_dma_invalidate_all_i` 与 S_LOOKUP 判决重合时，
  D-cache hit 必须为 0；桥只能沿既有 miss/AR/refill 路径取得 DPI 已写入的 PMEM 数据。
  事件不创建 bridge transaction 或 AXI owner，也不允许 B/IRQ 先于 D-cache 采样失效对外可见。
- **MEM-I11 post-translation class 单点合并（R4-S0）**：Bare/DTLB-hit 和 PTW-leaf
  两条成功路径都必须经 `OooPostTranslateMemoryClass`，在最终 PA、PMA 与 leaf PBMT 已知后
  恰好合并一次。`access_cacheable_q` 在进入数据事务状态前锁存并保持到 response；
  `mem0_rsp_cacheable_o` 与 SQ/drain sideband 只能转发该锁存值。PBMT=11 或 PMA deny 产生
  fault 且不得保留 admission class；PBMT NC/IO 即使 PA 落在 PMEM 也不得 lookup/fill/RMW。
  target bridge、SQ 或 D-cache 禁止再次按 PA 猜测/覆盖该属性。
- **MEM-I12 B terminal cache 维护真值（R4-S0）**：`data_store_b_terminal` 与
  `data_store_b_ok` 必须分开。只有 `B=OKAY && access_cacheable_q` 的普通 store 能置
  `store_rmw_en_i`；PBMT NC/IO、A/D 写回以及任意聚合 B error 都走 valid-only alias
  invalidate。split write 的前 beat 可能已生效，所以 error 也必须保守维护本行与跨线 p1。
- **MEM-I13 S0 非 typed ABI**：S0 的 `access_cacheable_q` 仍把 NC 与 IO 合并为一个
  serialized/non-cacheable 类，只是正确性检查点，不满足完整 memory-order ABI。S1 必须改为
  `{attr_valid,class[1:0]}`（CACHED/NC/IO；fault 独立），并让 NC 与 IO 拥有不同 ordering；
  精确编码、PMA/PBMT 矩阵、owner token/MMU epoch 与 fault 关系已在
  [`ooo-memory-typed-abi.md`](ooo-memory-typed-abi.md) 以 R4-S1.0 冻结，但本模块 RTL
  尚未实施。在此之前不得把该
  bridge 计为 DI-5 或完整双内存发射通过。
- **桥内断言族（OOO_ASSERT，立即断言）**：MEM-RMW-PORT（RMW 判决拍宏读口独占）、
  BRG-NOFIRE-FLUSH（flush 拍无 fire）、BRG-ADV-NODROP（advance ⇒ drop_rsp_q=0）、
  BRG-STG-LOOKUP（req 源 lookup 只在 advance 拍）、BRG-STG-HOLD（stall 拍站内字段冻结）、
  BRG-STG-NOKILL（flush 拍未 advance 的 nokill 项次拍存活）、MEM-PMA-*（静态地址图 deny 与
  pretrans provenance）；跨模块（NpcSimTop）：
  KM-STG-MIQ（站占用⇒MIQ 非空）、KM-STG-CTX（站占用期 satp/mstatus/priv/svpbmt 冻结，
  pretrans 豁免）。

## 6. 历史 B1 状态（T4I 已取代）

旧 B1 依赖“bridge AW/W fire=数据已落 PMEM”，并用 `bpend_q` 后台吸收 B。
T4I 在 bridge 与物理总线之间加入寄存 lane adapter 后，该前提不再成立：
upstream AW/W fire 只是 capture，split write 可能尚有多个下游 beat。因此 RTL 已删除
`bpend_q/store_decouple_w/store_decouple_commit_w`，统一走 `S_WRITE_RESP`。历史方案仅保留在
`design/arch/history/mem-store-decouple.md`，不得当作当前行为依据。

## 7. 变更记录
- 2026-07-16（R4-S1.0 docs-only）：冻结 typed ABI、owner identity、epoch、PMA/PBMT 矩阵及
  S1 single-owner/S2 RED 边界；本模块实现状态保持 R4-S0 Boolean 单 owner，不声明 RTL 完成。
- 2026-07-15（R4-S0 post-translation memory semantics）：新增统一分类器，Bare/DTLB-hit/
  PTW-leaf 在最终 PA 后合并 PMA/PBMT；请求站、response 与 SQ drain 传播最终 cacheability。
  store cache 维护从“PA 是否 PMEM”拆成“alias 是否可能存在”和“事务是否允许 RMW”两真值；
  cacheable+B OK 才 write-update，NC/IO、A/D、B error 均失效（含 cross-line）。该切片仍把
  NC/IO 合并，明确是 correctness checkpoint，而非 typed class、双 translation 或双 cache
  admission 的架构完成态。
- 2026-07-15（T4P virtio DMA/D-cache contract）：桥新增
  `dcache_dma_invalidate_all_i` 透传，不增状态/owner/宏口占用；D-cache 以 lookup-hit masking +
  valid-only 全失效阻断 queue-notify 同步 DPI 写造成的 stale hit，设备端将 notify B/IRQ 延后一拍。
  `tb_ooo_mem_axi_bridge` 用 hot stale line + S_LOOKUP 同拍事件证明 miss/AR/fresh refill；
  `Linux/tools/virtio-blk-smoke.S` 永久预热 status/used/data line 防冷 miss 假绿。范围仍仅是当前
  同步 virtio-blk 后端；截至该日 Linux 已推进到 ext4/systemd，但 strict guest-check +
  natural-poweroff 尚未闭合，不能据此声称完整 Linux 或 autonomous DMA coherence。
- 2026-07-14（T4M post-translate device owner）：最终 PA 非 PMEM 的 read 新增
  `S_DEVICE_WAIT`，由 MIQ/ROB 精确 release 或 killed cancel；修复 PMEM-window VA 经 Sv39
  映射到 PLIC/UART/virtio PA 时 wrong-path load 可发 device AR 的根因，且不串行化 translated PMEM。
- 2026-07-14（T4K MIQ-G1）：冻结 nokill DRAIN response 与 flush 同拍的跨模块事件代数；
  `OooMemInflightQueue` flush 压缩先排除 fired head，再保留其余 DRAIN，并用 delayed count
  invariant 与 wrapped/push/kill 交叠 focused TB 防止 ghost owner 回退。
- 2026-07-14（T4I standard-lane）：cacheable line 与 exact read owner 分离；
  `OooLsuAxiLaneAdapter` 在 core 边界完成标准 lane/授权 PMEM byte split。由于
  bridge AW/W fire 只代表 adapter capture，删除 B1 `bpend/store_decouple` 路，
  所有 store 等聚合 B 后单次提交 dcache RMW/响应。
- 2026-07-14（T4H PMA-PRECISE-STORE）：新增与具体 `NpcTop` 非空壳地址图一致的
  `OooPmaChecker`；Bare/DTLB-hit/PTW-leaf 的最终数据 PA 在成功 probe 或任何数据副作用前检查，
  default/空壳、跨区域与回绕 store 现在精确报 store access fault，原 VA 保持为 `tval`，SQ 不
  fill/drain。静态 PMA 无法预知设备内部动态 `SLVERR`，MEM-I3 明确保留该架构限制。
- 2026-07-14（T4F PTW-PMP-G1）：IFU/LSU walker 都新增独立 PTE WRITE checker；
  LSU 的 load-A/store-D R-only 页表反例与 IFU instruction 反例均证明 READ allow 不再绕过
  WRITE deny，RW allow control 保持原 A/D update 行为。
- 2026-07-14（T4E AXI AR hold）：移除注册地址态 ARVALID 的 live kill 门；flush/drop 对
  stalled data/walk AR 改为保持握手后本地 R drain，新增 `MEM-AR-HOLD` payload 冻结断言与
  data/walk repeated-flush 定向反例，删除对已移除 xbar abort 的陈旧依赖。
- 2026-07-14（T4C 契约冻结）：PTW leaf D-cache lookup 的 payload owner 从
  permission-qualified fire 分离为 fixed-role `S_WALK_R`；不改 enable、状态转移、
  响应拍或 AXI 行为，目标是切断 leaf PMP→SRAM address 的无意义控制污染。
- 2026-06-28：逆向文档化当前 FSM（行为基线），为 B1 提供安全改造依据。
- 2026-07-03：RTL 重读对照校正——B1 落地（PMEM store 解耦/`bpend_q`）、probe/pretrans/nokill
  三事务属性、flush 读态改本地直接释放（依赖 xbar abort/drop）、MEM-I3 收窄。
- 2026-07-03（doc-lifecycle 审计补漂移）：F9 PTE 读地址 PMP（S_WALK_AR 可直转 S_RESP）、line 读
  （32KB dcache/对齐 AR 回填/跨线窗口读）、accept 拍 AR 直发跳过 S_READ_ADDR、S_RESP back-to-back accept。
- 2026-07-07：补齐 Svnapot 64KiB leaf 判定、PA 拼接与 DTLB hit 复核 level 约束。
- 2026-07-08：**dcache SRAM 同步读接入**——新增 S_LOOKUP 判决态：读请求 fire 拍发 dcache 单口读，
  次拍判决 hit(→S_RESP)/miss(当拍发 AR，复用 `pend_read_araddr_w` 支路，`req_*` AR 直通支路删除)；
  hit 判定/窗口移位/跨线阻断统一用锁存 `paddr_q/read_cross_q`。walk（S_WALK_R leaf-ok read）与
  S_AD_UPDATE read 分支改经同一 S_LOOKUP，顺手修复 walk 组合口无移位无跨线检查回错值、
  S_AD_UPDATE 依赖 live `lsu_axi_rdata_i` 两个既有 bug。load hit 1→2 拍（一期代价）。
  `store_invalidate_all_i` 死口删除；store 维护随 dcache 一期改无条件失效（见
  `ooo-data-word-cache.md` §4）。sim 统计探针 `req_dcache_hit_w` 改为判决拍粘滞值
  （`CONFIG_NPC_SIM_STATS` 构建专用，NpcSimTop 的 fire&&hit 表达式变为错位一拍近似，
  精确化归宏合同收尾统一改 NpcSimTop）。
- 2026-07-09：**store RMW write-update 赎回**——真 store commit 变 dcache 2 拍 RMW 发射
  （§3 要点），`req_slot_ready` 加 `!dcache_rmw_busy`（store 后 1 bubble），
  `store_decouple_commit_w` 限定正常推进分支（flush-drain 改 b-ok 拍单次提交），
  `dcache_lookup_en/arvalid(S_LOOKUP-miss)/S_LOOKUP miss 转移` 加 `!rmw_busy` 安全网 +
  MEM-RMW-PORT 断言。A/D PTE 写回维护保持无条件失效（`store_rmw_en_i=0`）。
  桥 TB：post-commit/post-drain 同址读改回 hit 预期、drain 完成后 1 bubble、新增
  `store_rmw_write_update_and_bubble` 定向（ready 压制 + 字节合并数据回读）。
- 2026-07-09（同日，P5 刀 M）：**桥侧 req 寄存站落地**——req fire 拍零计算只锁存 8 字段
  （§2 寄存站行），翻译/PMP/dcache 发射/分流决策整体推迟到 `stage_advance_w` 拍
  （load hit 2→3 拍）；ready 重定义为 `!flush_i && (!stg_valid_q || stage_advance_w)`
  （`!flush_i` 保 MIQ 双射；drop_rsp_q 退出 ready=免费 skid；rmw_busy 迁入 advance）；
  FSM 两处 accept 调用上提为 stage_advance 最高优先分支；寄存站 flush 臂清非 nokill 项、
  nokill 项存活/flush 拍照常 advance（写必达）；MIQ push 时点不变（fire 语义重释=进站）、
  独占谓词族经 MIQ 自动计入寄存站。新增桥内 BRG-* 断言族 + NpcSimTop 跨模块 KM-STG-MIQ/
  KM-STG-CTX；NpcSimTop dcache 统计打拍源 fire→advance。桥 TB 全量对拍 +1 并新增
  skid/PSR-HOLD/nokill-flush 存活定向与负测试锚点（fire 拍 req 源 lookup 恒 0）。
  CoreMark 10 迭代 0xfcaf，CPI 3.197→3.280（+2.57%，低于 +3~8% 预估带）。
  实施记录：`.github/task-runs/2026-07-09-p5-knife-m/`。
- 2026-07-11：把 F9 的 PTE READ 范围与 A/D PTE WRITE 权限分开，登记
  `PTW-PMP-G1`；该合同已由 2026-07-14 T4F 的独立 WRITE checker 关闭。

## 已关闭隐患
- 2026-06-28 的“未收 B / `bpend_q` 归因”隐患已随 T4I 结构性关闭：
  bridge 不再在 B 前释放 write owner，lane adapter 单 owner，xbar 也锁 owner 至 B。
