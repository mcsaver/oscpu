# 规范：访存桥状态机 OooMemAxiBridge（FSM / flush-drain / 响应时序）

> 模块：`vsrc/memory/OooMemAxiBridge.v`。本规范逆向并固化其控制 FSM，作为 B1(store 写回解耦)
> 的实现前置（B1 已落地）。模板见 `../arch/SPEC-TEMPLATE.md`。状态：**已文档化当前实现（行为基线，
> 2026-07-03 RTL 重读校正）**。

## 1. 目的与范围
把后端 lane0/lane1 的访存请求（含 Sv39 翻译、PMP、dcache）落到 LSU AXI 总线，并把结果回送后端。
FSM 单事务在飞（single outstanding）+ 桥侧 req 寄存站单深度排队（P5 刀 M：桥内至多
"1 站内待发 + 1 FSM 在飞"，两者都记账在 MIQ）。本规范只描述控制 FSM 与响应/flush 时序，
不展开 PTW/PMP 细节。

## 2. 状态与 req 寄存站
| 状态 | 含义 |
|---|---|
| （req 寄存站） | 【P5 刀 M】非 FSM 状态：`stg_*_q` 8 字段(valid/addr/wdata/wstrb/write/probe/pretrans/nokill)。req fire 拍**零计算**只锁存字段（core 侧 req mux 组合、次拍即消失，必须当拍接住）；翻译(DTLB CAM)/PMP/dcache 发射/全部分流决策推迟到 `stage_advance_w` 拍。CSR 上下文(priv/mstatus/satp/svpbmt/pmp)不进站——寄存站占用⇒MIQ 非空⇒mem_idle=0⇒CSR/trap 不能退休(serialize-at-retire)，advance 拍上下文必与 fire 拍相同（KM-STG-CTX 断言固化） |
| S_IDLE | 空闲，等寄存站项 advance(`accept_request` 从 `stg_*` 取数) |
| S_LOOKUP | 【SRAM 同步读】dcache 判决态：上拍已发单口读，本拍 SRAM rdata 有效，判 hit(→S_RESP)/miss(当拍发 AR) |
| S_WALK_AR/S_WALK_R | Sv39 页表遍历 发 AR / 收 PTE |
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
 (寄存站) --advance(load,可翻译无fault)------------> S_LOOKUP(advance 拍发 dcache 同步读+锁 paddr_q/wstrb_q/read_cross_q)
 S_LOOKUP --(hit 且 !read_cross_q)-----------------> S_RESP(判决拍锁 rsp_rdata = line >> {paddr_q[2:0],3'b0})
 S_LOOKUP --(miss/跨线)----------------------------> S_READ_ADDR -> S_READ_DATA -(rvalid)-> S_RESP
                                                    (判决拍当拍发 AR;arready 即 fire 时跳过 S_READ_ADDR 直入 S_READ_DATA)
 (寄存站) --advance(store,probe)-------------------> S_RESP(不写内存,PA 经 rsp_rdata 回传)
 (寄存站) --advance(store,no-trans)----------------> S_WRITE_REQ -(aw&w)-> {S_RESP(PMEM 解耦,B 交 bpend_q) | S_WRITE_RESP -(bvalid)-> S_RESP(MMIO/uncacheable)}
 (寄存站) --advance(need-trans,tlb-miss)-----------> S_WALK_AR -> S_WALK_R -(...)-> {S_RESP | S_LOOKUP | S_WRITE_REQ | 下一级 S_WALK_AR}
 S_WALK_R --(leaf-ok,read)-------------------------> S_LOOKUP(当拍发 dcache 读,addr=walk_leaf_paddr_w)
 S_AD_UPDATE --(b-ok,read)-------------------------> S_LOOKUP(当拍发 dcache 读,addr=paddr_q)
 S_WALK_AR --(PTE 读地址 PMP 违例,F9)-------------> S_RESP(access fault,不发 AR)
 (寄存站) --advance(pmp/perm/page fault)-----------> S_RESP(error/page_fault 置位)
 S_RESP --(rsp_ready)-----------------------------> S_IDLE(站内有项则同拍 advance 直接 accept,back-to-back;
                                                    且 advance 拍站口腾出、新请求可同拍 fire 进站)
```
要点：
- **store 分两类（B1 已落地）**：PMEM store 在 `aw&w` 完成拍即到 S_RESP（数据已落 PMEM，`bresp`
  恒 OK 假设），滞后 B 由 `bpend_q` 跟踪器后台吸收（`store_decouple_w` 含 `!bpend_q`，至多 1 笔）；
  MMIO/uncacheable store 仍经 S_WRITE_RESP 等 B，`rsp_error` 来自 `bresp`——精确 store 总线异常
  仅对该类保留。
- **事务三属性（LSQ·SQ 切换新增）**：`probe`=write 探测（翻译+PMP 走完不写内存，PA 经 rsp_rdata
  回传）；`pretrans`=地址已是 PA（SQ drain 落存），跳过翻译/PMP；`nokill`=flush/drop 对该事务
  失效（已退休 store 写必达）。三位全 0 时行为与旧版一致。
- **line 读（LSQ Phase2+3 → SRAM 同步读）**：dcache 为 32KB 直映 word cache（`OOO_DATA_WORD_CACHE_INDEX_W=12`，
  tag+data 已进 1RW 同步读宏 Sram4096x113）。读请求(可翻译、无 fault)fire 拍发 dcache 单口读并锁
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
- **store RMW write-update（2026-07-09 赎回，刀 M 重述观察点）**：真 store commit
  （S_WRITE_REQ 解耦拍 / S_WRITE_RESP b-ok 拍——两拍均非 lookup/fill 消费态，dcache 宏读口
  空闲）即 dcache RMW 发射拍；次拍（判决拍，状态必∈{S_RESP,S_IDLE}）dcache 拉 `rmw_busy_o`
  占宏口，桥以 `!dcache_rmw_busy_w` 压 `stage_advance_w`——**store 完成后 1 bubble**
  （站内项被保持一拍；判决拍 ready 可为 1=新请求可进站排队，bubble 数不变）。
  `dcache_lookup_en_w`/S_LOOKUP-miss 的 arvalid 与状态转移同加
  `!rmw_busy` 安全网（状态互斥下恒不触发，MEM-RMW-PORT 断言把关）。
  `store_decouple_commit_w` 限定 FSM 正常推进分支（`fsm_normal_w`）：flush-drain 拍
  FSM 进 S_WRITE_RESP 等 B、改由 b-ok 拍单次提交，消灭同一 store 双 commit（第二次 RMW
  发射会撞第一次判决拍，1RW 违约）。HW A/D PTE 写回维护（S_AD_UPDATE b-ok）不走 RMW
  （`store_rmw_en_i=0`，无条件失效）——该拍的 read 续访问可能同拍发 lookup，宏读口不空闲。
- **PTW 隐式访问 PMP（F9）**：每级 PTE 读地址（`walk_pte_addr_w`）经独立 PmpChecker 检查，违例在
  S_WALK_AR 直接转 S_RESP 报 access fault（非 page fault），不发 AR。
- **Svnapot 64KiB**：PTW 只接受 level0 leaf 且 `PTE.N=1 && PTE.PPN[3:0]=4'b1000`；非 leaf、
  level1/2 leaf 或其它 NAPOT 编码均报 load/store page fault。合法 leaf 的 PA 拼接使用 VA[15:12]
  替代 PTE.PPN[3:0]，再进入 PMP、dcache 或 AXI 访问；DTLB hit 复核必须带 leaf level。
- FSM 单 outstanding 由**状态**强制：`stage_advance_w` 只在 S_IDLE 或 (S_RESP && rsp_ready)
  放行，写/读事务进行中(非 S_IDLE/S_RESP)寄存站项不进 FSM；dcache RMW 判决拍(store 完成次拍)
  额外压 1 拍。ready 只看寄存站占用（`!flush_i && (!stg_valid_q || stage_advance_w)`），
  **与 drop_rsp_q 无关**——FSM 忙/drain 期间新请求可进站排队（单深度）。

## 4. flush / drain 路径（`if (flush_i || drop_rsp_q)` 分支）
`drop_rsp_q` = "本地已放弃当前事务、但下游可能仍会回一个需吞掉的响应" 的粘滞标志。
- `cpu_kill_w = flush_i || drop_rsp_q`：拉低对外 valid/ready，阻止把被取消事务的结果当真。
- 各状态被 flush 时：读地址态与 **S_LOOKUP**（dcache 读无外部副作用）直接回 S_IDLE；读数据/PTE 态
  flush 当拍**本地直接释放**回 S_IDLE
  （读无外部副作用，依赖 flush 同步请求 xbar abort/drop，不再等 R；`drop_rsp_q` 现只服务写路径）；
  写态用 `write_drain_w` 把 AW/W 发完(避免半截事务挂总线)，收到 B 后清 drop。S_RESP/S_IDLE 态
  清零并回 S_IDLE。walk/A-D 路的 dcache 读发射（`walk_read_lookup_fire_w/ad_read_lookup_fire_w`）
  只在 FSM 正常推进分支有效，flush 拍不发。
- 【刀 M】寄存站 flush 臂：`flush_i && !stg_nokill_q → stg_valid_q<=0`（payload 留脏，全核
  valid-only 惯例）。站内项=**未发** AXI/dcache 事务，flush 可清（比 FSM 内 drain 更早止损）；
  MIQ 侧同拍 flush-compress 掉对应 LOAD/PROBE 项，双射不破。mispredict/ROB-walk kill 不触桥
  （现状无 kill 口），站内 killed LOAD/PROBE 照常推进发射，rsp 由 MIQ `head_killed` 恒收吞掉。
- 不变量：被 flush 的事务，其 AXI 响应必须被吞掉且不得置 `mem*_rsp_valid`（**nokill 事务例外**：
  `nokill_busy_w` 使 flush/drop 对其推进与响应握手均无效，写必达；站内 nokill 项同理存活并可
  flush 拍 advance）；半截写必须发完再丢 B。

## 5. 关键不变量
- **MEM-I1 单事务（刀 M 重述）**：FSM 单事务在飞——非 S_IDLE/(S_RESP&&rsp_ready) 寄存站项不
  advance；桥内至多 1 站内 + 1 FSM 在飞，两者都在 MIQ 记账（KM-STG-MIQ：`stg_valid_q ⇒
  !miq_empty`，mem_quiet 独占谓词族自动计入寄存站，任何消费点无需加 term）。
- **MEM-I2 写顺序可见性**：sim slave 在 `AW.fire&&W.fire` 当拍写 PMEM，B 在其后一拍 ⇒ store 数据
  在 write_complete 当拍即对后续访问可见。
- **MEM-I3 精确异常（B1/SQ 后收窄）**：仅 MMIO/uncacheable store 的总线错误经 `bresp`→`rsp_error`
  在 S_RESP 报告；PMEM 解耦 store 假设 `bresp` 恒 OK（B 后台吸收不报错）；SQ 语义下 plain store 的
  翻译/PMP fault 已在发射拍 probe 前置，退休后 drain 的总线错误仅 `[SQ-DRAIN-ERROR]` 警告。
  flush 中的响应必须吞掉。
- **MEM-I4 无 ready/valid 组合环**：`mem0_req_ready` 只依赖 flush/寄存站占用/state/rmw/rsp_ready，
  不依赖本拍新请求是否 fire（valid）。
- **桥内断言族（OOO_ASSERT，立即断言）**：MEM-RMW-PORT（RMW 判决拍宏读口独占）、
  BRG-NOFIRE-FLUSH（flush 拍无 fire）、BRG-ADV-NODROP（advance ⇒ drop_rsp_q=0）、
  BRG-STG-LOOKUP（req 源 lookup 只在 advance 拍）、BRG-STG-HOLD（stall 拍站内字段冻结）、
  BRG-STG-NOKILL（flush 拍未 advance 的 nokill 项次拍存活）；跨模块（NpcSimTop）：
  KM-STG-MIQ（站占用⇒MIQ 非空）、KM-STG-CTX（站占用期 satp/mstatus/priv/svpbmt 冻结，
  pretrans 豁免）。

## 6. B1(store 写回解耦) 的安全改造点（据本规范；**已落地**——`bpend_q`+`store_decouple_w`，见 §3 要点）
- 目标：store 在 `aw&w done`(数据已落 PMEM, MEM-I2) 后即推进，不占用桥等 B；B 交独立 `bpend_q` 跟踪器。
- 必须保留：MEM-I3——若需保持精确 store 总线异常，跟踪器要能在 B 返回 error 时上报；
  若裁定 PMEM store 恒 OK、可接受 store 总线异常为非精确，则记录该真实度假设(verilator-tapeout-realism)。
- 必须保留：MEM-I1/I4 与 flush drain（§4）——`bpend_q` 在 flush 时也要被正确 drain，不得泄漏/误判。
- store-after-store 由 slave `awready=!bvalid` 自然串行（新写的 AW 等旧 B 排空）。
- 验证：`ooo-mem-order`(store→load 同地址)、`string`/`mem-test`/`load-store`、riscv-tests `ua`/`ui`，
  全量 `eval/npc-eval.sh --all` 三 gate 绿 + 加权 CPI 下降。

## 7. 变更记录
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

## 已知隐患(2026-06-28 bug-hunt,当前不可触发)
- "至多一个未收 B" 不变量未由桥自身保证,依赖外部 `AxiLiteXbar` 串行化写;接流水化写互连会 B 归因 off-by-one。详见 `.github/memory/known-issues.md`(隐患A)。IP 复用前应桥内自保证(accept 新写前 `!bpend_q` 或 B 计数+归属)。
