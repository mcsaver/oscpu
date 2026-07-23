# v8g 异步内存 ProducerId 租约切片合同

## 目标与裁决

- `task_class`: architecture correctness closure
- `selected_root_cause`: memory response 生命周期可长于 ROB 槽生命周期；现有 exact memory
  owner tuple 不含 ROB incarnation，MIQ/SQ/bridge 的 raw ROB index 不能阻止 generation 回绕重名。
- `atomic_scope`: owner-token→ProducerId immutable metadata、registered memory PID lease bitmap、
  parent dispatch collision gate、SQ full-PID owner、AMO/STORE launch authorization、memory
  completion 互斥 exact-open/closed 分类 + sink-credit atomic acceptance + bounded grant。
- `not_in_scope`: 全核 lease、MulDiv/CLMUL/FP/branch carrier、memory 双发射、PPA 晋级、AXI ABI 扩宽。
- `promotion_target`: `MEMORY_ACTIVE_OWNER_PID_LEASE=SCOPED_GREEN`；
  `GLOBAL_NO_LIVE_REUSE=RED` 保持不变。

规范真源：`npc/rv64/design/specs/ooo-memory-producer-lease.md`。其中 §2/§3 已在动 RTL 前
冻结；任何实现若无法满足其 ready DAG、flush 表或同拍事件代数，必须退回合同阶段。

## 六类跨模块契约冻结

| 契约 | 冻结结论 | 可执行判据 |
| --- | --- | --- |
| 握手 | memory owner 只在 current-authorized reservation capture 分配；dispatch fire 是 ROB generation 唯一推进点 | alloc/fire/mask assertions + focused TB |
| stall/ready DAG | dispatch 只读 tracker registered PID bitmap 与 ROB Q candidate；response credit 不得读 release/free 结果 | structural audit；mandatory pair candidate 不依赖 fire；credit cone audit |
| flush/recovery | flush/kill 不直接清已发 owner lease；exact terminal/free 后下一沿才可复用 | kill/drop/store-B tests + same-edge reuse negative |
| 异常序 | stale speculative response可 drain 无 WB；physical STORE B 必须 exact-open 后才完成 ROB | LOAD/PROBE/AMO/DRAIN directed cases |
| 访存序 | owner tuple 仍负责 bridge/MIQ pairing；PID 只增加 ROB incarnation authorization，不改变既有 request/SQ 顺序 | tuple+PID two-stage authorization assertions |
| 投机恢复 | raw idx 只作 age；strictly-younger cancellation 与 full PID completion gate共同成立 | branch kill + stale PID mutation |

补充硬裁决：`owner_open` 必须同时要求 exact tuple、tracker kind/epoch
exact-live、ROB
query match、`!effective_killed`与 `!done_now`；`owner_closed=exact_tuple&&!owner_open`，
credit 不得改变分类。physical STORE/AMO write 的 request fire 另须 exact-live tuple、
tracker/SQ/head PID chain、ROB launch-open 与 one-shot sent-clear。STORE token 的 bulk death
必须证明未发，或 aggregate B status 已被 exact completion 接收；只按 STORE
kind、AW/W、flush、SQ dequeue 或 commit 意图均不充分。closed STORE DRAIN、
tracker dead/tag mismatch 或 AMO write 已发后的 closed final 只可 fatal drain，不产生
normal owner death。post-launch ROB head 在 final completion 前必须保持 `!done`。

## 硬门

1. 先完成 holder/terminal census 与 RTL derivation，禁止边改边猜。
2. 所有新增断言必须有 compile-success mutation-negative。
3. focused release/assert 全绿；模块 aggregate 不回退；`check-contract`、style/structure gate 通过。
4. 全核 lint 若仍为继承 warning baseline，只能报告归一化相等，不得宣称 lint GREEN。
5. 不运行/不报告 PPA 晋级，直至功能与架构 hard gate 完成。
6. 实现者交付后切换 reviewer 人格，优先寻找同沿复用、optional lane1、open-no-credit、
   tracker tag mismatch、collector 反压/间接组合环、EX 连续占位饿饿、killed load、
   AMO read→write、AMO-write-sent closed final、late B、post-launch early done、`done_now`
   B 释放、token 提前释放与组合环反例。

## 停止条件

- 若需要把 MIQ/SQ holder compare tree 拉进 dispatch ready：停止并重做边界。
- 若 STORE DRAIN 只能通过静默 drop 闭合：停止，记录 owner 生命周期 blocker。
- 若必须扩大到非 memory holder 才能证明当前切片：只交付 scoped 状态，不越级宣称 global closure。
