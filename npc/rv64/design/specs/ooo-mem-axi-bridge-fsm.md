# 规范：访存桥状态机 OooMemAxiBridge（FSM / flush-drain / 响应时序）

> 模块：`vsrc/memory/OooMemAxiBridge.v`。本规范逆向并固化其控制 FSM，作为 B1(store 写回解耦)
> 的实现前置（B1 已落地）。模板见 `../arch/SPEC-TEMPLATE.md`。状态：**已文档化当前实现（行为基线，
> 2026-07-03 RTL 重读校正）**。

## 1. 目的与范围
把后端 lane0/lane1 的访存请求（含 Sv39 翻译、PMP、dcache）落到 LSU AXI 总线，并把结果回送后端。
单事务在飞（single outstanding）。本规范只描述控制 FSM 与响应/flush 时序，不展开 PTW/PMP 细节。

## 2. 状态
| 状态 | 含义 |
|---|---|
| S_IDLE | 空闲，可接受新请求(`accept_request`) |
| S_WALK_AR/S_WALK_R | Sv39 页表遍历 发 AR / 收 PTE |
| S_READ_ADDR/S_READ_DATA | load: 发读地址 / 收读数据 |
| S_WRITE_REQ | store: 发 AW+W |
| S_WRITE_RESP | store: 等 B |
| S_RESP | 向后端拉 `mem*_rsp_valid`，等 `rsp_ready` 后回 S_IDLE |

## 3. 正常转移（`else` 分支，flush_i=0 且 drop_rsp_q=0）
```
 S_IDLE --req(load,hit)----------------------------> S_RESP
 S_IDLE --req(load,miss,no-trans)-----------------> S_READ_ADDR -> S_READ_DATA -(rvalid)-> S_RESP
                                                    (accept 拍 arready 即 fire 时跳过 S_READ_ADDR 直入 S_READ_DATA)
 S_IDLE --req(store,probe)------------------------> S_RESP(不写内存,PA 经 rsp_rdata 回传)
 S_IDLE --req(store,no-trans)---------------------> S_WRITE_REQ -(aw&w)-> {S_RESP(PMEM 解耦,B 交 bpend_q) | S_WRITE_RESP -(bvalid)-> S_RESP(MMIO/uncacheable)}
 S_IDLE --req(need-trans,tlb-miss)----------------> S_WALK_AR -> S_WALK_R -(...)-> {S_RESP | S_READ_ADDR | S_WRITE_REQ | 下一级 S_WALK_AR}
 S_WALK_AR --(PTE 读地址 PMP 违例,F9)-------------> S_RESP(access fault,不发 AR)
 S_IDLE --req(pmp/perm/page fault)----------------> S_RESP(error/page_fault 置位)
 S_RESP --(rsp_ready)-----------------------------> S_IDLE(同拍新请求 fire 则直接 accept,back-to-back)
```
要点：
- **store 分两类（B1 已落地）**：PMEM store 在 `aw&w` 完成拍即到 S_RESP（数据已落 PMEM，`bresp`
  恒 OK 假设），滞后 B 由 `bpend_q` 跟踪器后台吸收（`store_decouple_w` 含 `!bpend_q`，至多 1 笔）；
  MMIO/uncacheable store 仍经 S_WRITE_RESP 等 B，`rsp_error` 来自 `bresp`——精确 store 总线异常
  仅对该类保留。
- **事务三属性（LSQ·SQ 切换新增）**：`probe`=write 探测（翻译+PMP 走完不写内存，PA 经 rsp_rdata
  回传）；`pretrans`=地址已是 PA（SQ drain 落存），跳过翻译/PMP；`nokill`=flush/drop 对该事务
  失效（已退休 store 写必达）。三位全 0 时行为与旧版一致。
- **line 读（LSQ Phase2+3）**：dcache 为 32KB 直映 word cache（`DCACHE_INDEX_W=12`）；读 miss 不跨
  8B line 时发 line 对齐 AR（低 3 位清零）、回填整 line、`rsp_rdata` 按 line 内偏移（`paddr_q[2:0]`）
  右移出 CPU 视图；跨线（`read_cross_q`）按原地址窗口读且不 fill。
- **PTW 隐式访问 PMP（F9）**：每级 PTE 读地址（`walk_pte_addr_w`）经独立 PmpChecker 检查，违例在
  S_WALK_AR 直接转 S_RESP 报 access fault（非 page fault），不发 AR。
- **Svnapot 64KiB**：PTW 只接受 level0 leaf 且 `PTE.N=1 && PTE.PPN[3:0]=4'b1000`；非 leaf、
  level1/2 leaf 或其它 NAPOT 编码均报 load/store page fault。合法 leaf 的 PA 拼接使用 VA[15:12]
  替代 PTE.PPN[3:0]，再进入 PMP、dcache 或 AXI 访问；DTLB hit 复核必须带 leaf level。
- 单 outstanding 由**状态**强制：`req_slot_ready_w = !cpu_kill && (S_IDLE || (S_RESP && rsp_ready))`，
  写/读事务进行中(非 S_IDLE/S_RESP)不接受新请求。**与 drop_rsp_q 无关**。

## 4. flush / drain 路径（`if (flush_i || drop_rsp_q)` 分支）
`drop_rsp_q` = "本地已放弃当前事务、但下游可能仍会回一个需吞掉的响应" 的粘滞标志。
- `cpu_kill_w = flush_i || drop_rsp_q`：拉低对外 valid/ready，阻止把被取消事务的结果当真。
- 各状态被 flush 时：读地址态直接回 S_IDLE；读数据/PTE 态 flush 当拍**本地直接释放**回 S_IDLE
  （读无外部副作用，依赖 flush 同步请求 xbar abort/drop，不再等 R；`drop_rsp_q` 现只服务写路径）；
  写态用 `write_drain_w` 把 AW/W 发完(避免半截事务挂总线)，收到 B 后清 drop。S_RESP/S_IDLE 态
  清零并回 S_IDLE。
- 不变量：被 flush 的事务，其 AXI 响应必须被吞掉且不得置 `mem*_rsp_valid`（**nokill 事务例外**：
  `nokill_busy_w` 使 flush/drop 对其推进与响应握手均无效，写必达）；半截写必须发完再丢 B。

## 5. 关键不变量
- **MEM-I1 单事务**：非 S_IDLE/S_RESP 不接受新请求。
- **MEM-I2 写顺序可见性**：sim slave 在 `AW.fire&&W.fire` 当拍写 PMEM，B 在其后一拍 ⇒ store 数据
  在 write_complete 当拍即对后续访问可见。
- **MEM-I3 精确异常（B1/SQ 后收窄）**：仅 MMIO/uncacheable store 的总线错误经 `bresp`→`rsp_error`
  在 S_RESP 报告；PMEM 解耦 store 假设 `bresp` 恒 OK（B 后台吸收不报错）；SQ 语义下 plain store 的
  翻译/PMP fault 已在发射拍 probe 前置，退休后 drain 的总线错误仅 `[SQ-DRAIN-ERROR]` 警告。
  flush 中的响应必须吞掉。
- **MEM-I4 无 ready/valid 组合环**：`req_slot_ready` 只依赖 state/rsp_ready，不依赖本拍新请求是否 fire。

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

## 已知隐患(2026-06-28 bug-hunt,当前不可触发)
- "至多一个未收 B" 不变量未由桥自身保证,依赖外部 `AxiLiteXbar` 串行化写;接流水化写互连会 B 归因 off-by-one。详见 `.github/memory/known-issues.md`(隐患A)。IP 复用前应桥内自保证(accept 新写前 `!bpend_q` 或 B 计数+归属)。
