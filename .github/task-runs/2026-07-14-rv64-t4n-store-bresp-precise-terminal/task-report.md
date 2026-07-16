# T4N plain-store late-B precise terminal

## Root cause

旧流程把 successful store probe 当成 ROB done，随后 store 先 commit、SQ 再后台发
`pretrans+nokill` 写。设备运行时 B `SLVERR/DECERR` 到达时 ROB owner 已释放，只能警告，无法形成
精确 cause/tval；SQ request fire 也同时承担了 entry release，真实写/B/架构提交缺少独立 owner。

## Implementation

- `OooStoreQueue` 改为 `request fire → terminal → ROB release` 三事件；VA/PA 分开保存。
- physical request 只在 physical SQ head 与 ROB head 同 tag 时有效；fire 后 owner/forwarding 保持，
  `request_sent` 阻止重复写。
- backend successful probe 只 fill；B 等 formal-WB credit，OKAY/SLVERR/DECERR 各形成唯一 store WB。
- B error 固定 `EXC_STORE_ACCESS_FAULT`（cause 7），`tval` 取 SQ original VA。
- request mux 显式单热：SQ physical owner 优先于 younger buffer/issue；loser 不得 false fire，可转 buffer。
- branch flush 保留 older active owner；global flush 与 live physical owner 重叠由 load-bearing assertion 拒绝。
- translated younger load 在 older SQ/probe 存在时继续 blind block，避免先占 bridge T4M device wait；
  无 older store 时 translated PMEM 路径不变。

详细合同见 `npc/rv64/design/specs/ooo-store-bresp-precise-terminal.md`。

## RED → GREEN evidence

| Evidence | Result |
| --- | --- |
| `evidence/red-store-queue/logs/tb_ooo_store_queue.log` | RED：request fire 后旧 RTL count 由 4 降 3 |
| `evidence/green-store-queue-v2/logs/tb_ooo_store_queue.log` | PASS：SQ 三事件、VA/PA、branch/global flush、two-store order |
| `evidence/int-backend-v4/logs/tb_ooo_int_backend.log` | PASS：probe no-WB、late B/cause7/tval VA、priority、T4M admission |
| `evidence/mem-bridge-v1/logs/tb_ooo_mem_axi_bridge.log` | PASS：OKAY/SLVERR/DECERR unique held response |
| `evidence/focused-final/summary.txt` | PASS 3/3 combined focused |
| `evidence/check-rtl-style.log` | PASS |

Icarus 只报告项目既有形态的 unpacked-array `@* sensitive to all words` warning；无 width、implicit-net、
端口或 latch error。scoped `git diff --check` 通过。

## Directed counterexamples

- delayed B 且双 EX 占满 formal-WB：B ready 保持 0；credit 释放后只 WB 一次，B 前无 commit。
- VA `0x40001040` → PA `0x80001240`，B error：真实写使用 PA，WB/commit cause=7、tval=VA。
- 两 store：store0 fill 与 store1 reservation 重叠；SQ grant 胜出，store1 无 false fire 而转 buffer；
  两次 physical write/B/commit 严格按序且各一次。
- T4M：older store fill 后 younger PMEM-looking translated load 常驻 reservation、不发 request；
  store write/B/commit/release 后 load 才发 request并形成 device-release owner。
- bridge 对 OKAY/SLVERR/DECERR 分别在 response-ready stall 下保持 payload，握手后不重放。

## Implementer / reviewer switch

实现者结论：功能事件方程已改变，不是症状级断言；ROB done 的唯一成功 store 来源已从 probe 移到 B，
SQ owner 横跨 request/B/commit，MIQ DRAIN 携带真实 ROB tag。

审查者反例复核：

1. probe fault 可在未 fill/未 request 时 terminal，并可被 older branch/global trap squash；
2. B error 的 MIQ request address 是 PA，但 WB tval 明确旁路到 SQ VA；
3. request-ready stall、B-credit stall 和 same-cycle terminal/release 均不重复 request/terminal；
4. branch 只能清程序序 suffix；global flush 不得把 accepted write 静默遗失；
5. SQ priority 不让 losing issue 消费 bridge ready，reservation→buffer 是独立 owner handoff；
6. T4M admission 与 bridge post-translate device wait 联合证明无单 FSM/MIQ deadlock，普通 PMEM 未全局串行。

未发现 unresolved functional conflict。本子任务按授权未跑综合/STA，不宣称单独复验 200 MHz；
strict guard 由 root 在共享工作树合并后统一运行。

## Reviewer follow-up：异常 lane / local terminal / restore gate

### RED 证据

- `evidence/reviewer-red-rob/logs/tb_ooo_rob.log`：旧 RTL 令 head1 exception 从 commit1
  同拍退休并提前 trap，下一拍 ROB 已空，共 14 个定向失败。
- `evidence/reviewer-red-backend/logs/tb_ooo_int_backend.log`：SD/FSD page-end 均无 SQ
  terminal；older ALU + fault store 触发 commit1；checkpoint restore 拍 SQ fire 而 MIQ flush，
  形成 `request_sent=1 / MIQ=0` owner 丢失，共 25 个定向失败。

### 接口契约冻结

| 边界 | 冻结契约 | 同拍优先级/保持 |
| --- | --- | --- |
| ROB commit | exception 只能从 commit0 宣告；head1 exception 禁 commit1 | older normal head0 可先退休；异常项保持一拍后成为 head0 |
| reservation → SQ | translated plain SD/FSW/FSD local exception 是 terminal | terminal ROB tag 取 reservation Q；不发 bridge request |
| terminal producers → SQ | response terminal 与 local terminal 是两个独立 CAM 写端口 | 同拍 tag 必须不同且各唯一命中；禁止 response→issue backpressure |
| SQ → request/MIQ | `flush || checkpoint_restore` 时 SQ grant/fire/push 全为 0 | restore 不清 SQ；下一拍同 owner 恢复 eligibility |
| MIQ DRAIN response | global flush 与 DRAIN pop 同拍先兑现 pop | keep-set 不得复活已消费 head |

受影响六类契约：握手（grant/fire/push 原子）、flush/restore（谁清谁保持）、异常序
（commit0-only）、访存序（local terminal 后才 release）、单一真源（terminal ROB tag 来自
reservation Q）。stall 与分支恢复接口未改变。

### RTL 推导摘要

1. **需求**：修复三个 RED，保持 2-wide normal retirement、SQ 三事件状态与既有 MIQ 状态机；
   不新增 pipeline/FSM，不做无关重构。
2. **协议/状态机**：ROB 仅收紧 commit1 eligibility；SQ terminal 状态由两个独立 CAM event
   端口置位（response/local exception）；request arbiter 仅在 eligibility 前增加 flush/restore mask。
3. **不变量**：`commit1 -> !head1_exception`；local plain-store exception consume
   `-> sq_terminal(tag=reservation.rob)`；`flush||restore -> !grant_sq&&!sq_fire`；MIQ DRAIN
   flush+pop 计数保持旧 `keep-pop` 代数。
4. **数据通路/拓扑**：无新寄存器/FSM/共享资源。ROB commit1 AND 树增加一项；SQ terminal
   CAM 增加第二组 tag compare/write-enable，两个不同 entry 可同拍 sticky；SQ eligibility AND 树
   增加两个 global gate。reset/flush/stall 优先级不变，B response 不回接 issue-ready，预计不形成
   新的数据关键路径。
5. **断言**：增加 exception-lane0-only、local-exception-terminal、global/restore-no-SQ-grant
   三组立即断言；RED 用例本身提供非真空触发窗口。

### 双 terminal 审查反例

首次三点修复转绿后，审查者继续构造出 `older physical B + younger SD/FSD page-end local
exception` 同拍反例：若 backend 把两路 OR 后只选一个 ROB tag，另一 SQ owner 永远收不到
terminal。最终结构改为 SQ 双 terminal CAM 端口，无新增状态/FSM，也没有把 B response 组合
回接到 issue-ready。

- `evidence/reviewer-dual-terminal-red-v2/logs/tb_ooo_int_backend.log`：test-only mutation
  强制第二 CAM hit 为 0，SD/FSD 均出现 younger sticky=0、nonterminal release 与 SQ 残留。
- `evidence/reviewer-dual-terminal-same-tag-red/logs/tb_ooo_store_queue.log`：同拍双端口故意
  使用相同 ROB tag，`T4N-SQ-TERMINAL-SAME-TAG` 精确报错。
- `evidence/reviewer-dual-terminal-green-v1/summary.txt`：StoreQueue/IntBackend 2/2 PASS；
  两个自然 B+local collision 中 older/younger tag 均 sticky，随后严格按 ROB 顺序释放。

### Reviewer follow-up 最终验证

| Evidence | Result |
| --- | --- |
| `evidence/reviewer-final-5/summary.txt` | PASS 5/5：ROB、StoreQueue、MIQ、IntBackend、MemAxiBridge |
| `evidence/reviewer-final-style.log` | PASS：可综合 RTL 风格 gate |
| `evidence/reviewer-final-lint.log` | PASS：NpcSimTop Verilator lint |
| `evidence/reviewer-final-diff-check.log` | PASS：reviewer scoped diff-check |

实现者复核：三处原始 root cause 与双-terminal 并发反例都由结构修复关闭；normal 2-wide commit
仍可双退，只有 exception lane 被限制到 commit0；SQ/MIQ owner 守恒在 restore、B/local collision、
flush+pop、release+alloc 下都有定向证据。

审查者复核：再次攻击了同拍两个 terminal、same-tag alias、第二 CAM hit 丢失、restore fire、
commit1 exception、terminal+release+flush 与 DRAIN pop+flush。两个 test-only mutation 均稳定 RED，
最终 5 个 focused TB、style、lint、diff 全绿，未发现剩余功能冲突。本 follow-up 按 root 授权不跑
全量、综合、STA、strict guard，也不据此单独声明 200 MHz closure。
