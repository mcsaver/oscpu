# 规范：访存桥状态机 OooMemAxiBridge（FSM / flush-drain / 响应时序）

> 模块：`vsrc/memory/OooMemAxiBridge.v`。本规范逆向并固化其控制 FSM，作为 B1(store 写回解耦)
> 的实现前置。模板见 `../arch/SPEC-TEMPLATE.md`。状态：**已文档化当前实现（行为基线）**。

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
 S_IDLE --req(store,no-trans)---------------------> S_WRITE_REQ -(aw&w)-> S_WRITE_RESP -(bvalid)-> S_RESP
 S_IDLE --req(need-trans,tlb-miss)----------------> S_WALK_AR -> S_WALK_R -(...)-> {S_RESP | S_READ_ADDR | S_WRITE_REQ | 下一级 S_WALK_AR}
 S_IDLE --req(pmp/perm/page fault)----------------> S_RESP(error/page_fault 置位)
 S_RESP --(rsp_ready)-----------------------------> S_IDLE
```
要点：
- **store 经 S_WRITE_RESP 等 B 后才到 S_RESP**：后端等 store 的 `mem*_rsp_valid`，故 store 延迟含 B。
  store 的 `rsp_error` 来自 `bresp`（只有等到 B 才知）——这是精确 store 总线异常的来源。
- 单 outstanding 由**状态**强制：`req_slot_ready_w = !cpu_kill && (S_IDLE || (S_RESP && rsp_ready))`，
  写/读事务进行中(非 S_IDLE/S_RESP)不接受新请求。**与 drop_rsp_q 无关**。

## 4. flush / drain 路径（`if (flush_i || drop_rsp_q)` 分支）
`drop_rsp_q` = "本地已放弃当前事务、但下游可能仍会回一个需吞掉的响应" 的粘滞标志。
- `cpu_kill_w = flush_i || drop_rsp_q`：拉低对外 valid/ready，阻止把被取消事务的结果当真。
- 各状态被 flush 时：读地址态直接回 S_IDLE；读数据/PTE 态若 rvalid 当拍到则消费后回 S_IDLE，
  否则置 `drop_rsp_q=1` 等响应到来再吞；写态用 `write_drain_w` 把 AW/W 发完(避免半截事务挂总线)，
  收到 B 后清 drop。S_RESP/S_IDLE 态清零并回 S_IDLE。
- 不变量：被 flush 的事务，其 AXI 响应必须被吞掉且不得置 `mem*_rsp_valid`；半截写必须发完再丢 B。

## 5. 关键不变量
- **MEM-I1 单事务**：非 S_IDLE/S_RESP 不接受新请求。
- **MEM-I2 写顺序可见性**：sim slave 在 `AW.fire&&W.fire` 当拍写 PMEM，B 在其后一拍 ⇒ store 数据
  在 write_complete 当拍即对后续访问可见。
- **MEM-I3 精确异常**：store 总线错误经 `bresp`→`rsp_error` 在 store 的 S_RESP 报告；flush 中的响应必须吞掉。
- **MEM-I4 无 ready/valid 组合环**：`req_slot_ready` 只依赖 state/rsp_ready，不依赖本拍新请求是否 fire。

## 6. B1(store 写回解耦) 的安全改造点（据本规范）
- 目标：store 在 `aw&w done`(数据已落 PMEM, MEM-I2) 后即推进，不占用桥等 B；B 交独立 `bpend_q` 跟踪器。
- 必须保留：MEM-I3——若需保持精确 store 总线异常，跟踪器要能在 B 返回 error 时上报；
  若裁定 PMEM store 恒 OK、可接受 store 总线异常为非精确，则记录该真实度假设(verilator-tapeout-realism)。
- 必须保留：MEM-I1/I4 与 flush drain（§4）——`bpend_q` 在 flush 时也要被正确 drain，不得泄漏/误判。
- store-after-store 由 slave `awready=!bvalid` 自然串行（新写的 AW 等旧 B 排空）。
- 验证：`ooo-mem-order`(store→load 同地址)、`string`/`mem-test`/`load-store`、riscv-tests `ua`/`ui`，
  全量 `eval/npc-eval.sh --all` 三 gate 绿 + 加权 CPI 下降。

## 7. 变更记录
- 2026-06-28：逆向文档化当前 FSM（行为基线），为 B1 提供安全改造依据。
