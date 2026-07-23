# v8g RTL derivation（冻结后实现输入）

## 最小修改面

1. `OooMemOwnerTracker.v`
   - 参数化 `PRODUCER_ID_W/PRODUCER_COUNT`；alloc 两路新增 PID。
   - 每 token 保存不可变 `producer_id_q`，导出 table。
   - 新增寄存 `producer_live_q`；alloc duplicate PID fail closed；free/release 按旧 metadata 清。
   - 断言 live-token/PID 一一映射、popcount、同沿禁止复用、metadata hold。
2. `OooRob.v`
   - 增加第三个 completion exact-open query，语义与 query0/1 相同。
   - 新增 mandatory-pair 专用 Q-only lane1 candidate=`tail+1`；保留实际
     `dispatch1_producer_id_o` 的 standalone accepted 语义不变。
   - 导出 ROB head full PID 与 launch-open（exact valid、`!done`、非 recovery/kill）。
3. `OooDispatchBackend.v`
   - 输入 registered memory PID lease mask；lane0、mandatory pair、lane1 ready 全部 fail closed。
   - 透传 completion2 query；导出 dispatch0/1 与 ROB head full PID；断言 fire candidate lease-clear。
4. `OooIntBackend.v`
   - reservation capture 先要求 issue PID current；mismatch 允许 IQ 消费但不创建 owner。
   - tracker alloc 写入 issue PID，table[token] 形成 MIQ head completion PID。
   - MIQ holder 必须先通过 tracker live+kind+epoch exact-tag，才可取 PID。response
     先形成互斥 `owner_open/owner_closed`，再用 WB/terminal credit 形成统一
     `mem_completion_fire`；当前无-ready side-effect sinks 冻结为常收。
   - response terminal credit 只读 edge-old pending 与无 ready/fire/grant 依赖的其它
     raw terminal candidate；其它候选固定优先，response 后选。
   - open-no-credit 保持；tracker-exact closed speculative response 等 collector credit
     后 drain-only；tracker mismatch、closed STORE DRAIN 或 AMO-write-sent closed final 均
     fatal/poison 且无 normal death。
   - 利用现有 response-wait 对 lane1 EX 的准入门，断言 stable open response
     首次 WB 全满后下拍获得 memory grant。
   - AMO write request 重新检查 interphase exact-live tuple、token→PID == current
     ROB head PID、ROB launch-open 与 one-shot；AMO read closed 不得进入 write。
   - `mem_amo_write_sent_q` 未 final completion 期间断言 head PID exact-open/`!done`；
     final completion 是唯一 done 事件。
   - tracker PID mask 接 parent dispatch，不进 bridge/MIQ request-ready。
5. `OooStoreQueue.v`
   - dispatch allocation保存 full PID；owner bind、physical request、terminal release 均比较 full PID。
   - physical request 只在 SQ owner bound、tuple exact-live、SQ/tracker/head PID 一致、
     ROB launch-open 且 `!request_sent`；已发写在 B exact terminal 前禁止 release。
   - `request_sent && !terminal` 期间断言 head PID exact-open/`!done`；B completion
     是唯一 terminal/done 事件。
6. focused TB / task-run audit
   - tracker leaf TB、dispatch/ROB/backend directed cases、compile-success mutations、结构审计。

## 组合环审计预判

- lane0 candidate 只读 `tail_q/slot_generation_q`。
- lane1 candidate 必须改成无条件 `tail_q+1`，否则 mandatory-pair collision 会形成
  `parent ready -> child fire -> lane1 candidate -> parent ready` 环。
- PID mask 是 tracker Q，不是从 `live_q + metadata` 临时译码后再回 ready。
- completion2 query 只进入 response side-effect gate，不进入 dispatch/request ready。

## 事件更新伪码

```text
death[token] = exact_tagged_free OR qualified_store_release
birth[token] = allocation selected from edge-old free token and edge-old clear PID
pid_clear[old_pid] = OR of death[token] using old metadata
pid_set[new_pid] = OR of birth[token]
live_next = (live_q & ~death) | birth
pid_live_next = (pid_live_q & ~pid_clear) | pid_set
```

旧 token allocator 不允许选择同沿 release/free 的 token；新增 PID allocator 同样读取 edge-old
`producer_live_q`。exact free 与 release 同 token 归并成一个 death；合法 birth/death 不会同
token/PID 重叠。若发生重叠，立即断言而不是用过程语句顺序定义赢家。

## 验证矩阵

| 层 | 正向 | 独立反例 |
| --- | --- | --- |
| tracker | alloc/hold/free/release/dual event | duplicate PID、same-edge reuse、table/bitmap漂移 |
| ROB | query2 current/open；lane1 tail+1 | residual generation、done target、candidate依赖fire |
| dispatch | lane0/pair/optional collision | 删除任一 collision gate、mask 常量0 |
| backend | tracker-exact LOAD/PROBE/AMO/DRAIN；open-no-credit hold；exact-capability launch；bounded completion | stale epoch WB/free、current mismatch alloc、AMO closed进入write、AMO-write-sent normal drain、early done、collector 环/无 credit pop、B前release |
| aggregate | module regression + contract/style | source manifest、normalized lint baseline |

实现完成前本文件不记录 GREEN；证据路径与 case count 在 task report 收尾时填写。

## 实现后裁决

- frozen contract 的最小修改面已全部落地，并追加 bridge/collector response-ready 物理断环：
  raw drop 不读 advance、station query Q-only、local terminal 因式分解、killed buffer 禁止 grant、
  六路 mask 使用独立 scalar source。
- canonical runner：release/assert 各 `standard=6/6 + backend-focused=1/1`；29/29
  compile-success mutations 全部命中，其中 4 个要求仿真 PASS、结构审计 RED。
- broad：module aggregate 105/105；style/contract/structural audit PASS；full lint 115 条继承
  warning 且 normalized 与 v8d byte-equal。
- architecture self-tests 15/15，但真实 DI/OOO inventory `OVERALL: RED`；无 synthesis/STA/Power，
  `promotion_eligible=false`，父目标继续 active。
