# RV64 T3B：long-op full-WB / EX-MEM fast broadcast 分离

## 基本信息

- `task_id`: 2026-07-13-rv64-t3b-longop-fast-broadcast
- `status`: completed (structural slice); parent timing goal remains active
- `profile`: npc-dev
- `base_commit`: eb9bd3b28
- `parent_goal`: active；完整功能与 physical 200MHz 未闭合
- `updated_at`: 2026-07-13 11:30:00 +0800

## 目标与接受门禁

把 current A 的108条 long-op response→full-WB→PRF/IQ→branch-kill 组合反馈从 RTL 结构上切断，
保留唯一 FP admission SCC 给下一刀。接受条件：

1. full WB、long-op current-kill、ROB/BusyTable/IQ sticky state/PRF时序写逐拍不变；
2. IQ select和PRF read0–3只吃物理独立的EX/MEM fast payload，不能复用full-WB mux；
3. long-op/FPWB dependency只晚1拍，EX/MEM load-use/ALU-use拍数不变；
4. focused/negative/module/lint/contract/CoreMark/全功能回归通过；
5. fresh同参数 OpenSTA loops目标109→1，若 WNS/TNS/PPA/CPI无接受依据则回退。

## 接口契约冻结

六类合同、周期表、优先级与RED矩阵的单一真源是
`npc/rv64/design/specs/ooo-longop-fast-broadcast.md`。摘要：

- 握手：无新ready；fast必须逐lane是full WB子集。
- stall：formal WB反压不变；full pulse全部粘IQ状态，只有fast可同拍select。
- flush/kill：MulDiv/CLMUL当拍kill不动；kill survivor仍吸收full wakeup。
- 异常：full WB仍独占ROB done/exception owner；fast不拥有异常状态。
- 访存：fast MEM只来自accepted正式response，load-use同拍快路保留。
- 恢复/单真源：full WB是完成真源；fast直接由raw EX/MEM winner构造，不反解full mux。

## Reviewer 前置反例

- 仅增加 `wb_fast` class bit而继续复用`wb_pdest/data`是假切点，门级long-op payload arc仍存在。
- 仅延迟IQ select会留下38条PRF loop；仅删除PRF write-through会留下70条IQ loop。
- 注册branch kill或普通long-op response buffer会打开wrong-path dirty-WB窗口，当前不选。
- PRF read8不属于108环，保留full write-through；FPWB先归non-fast，避免扩大组合SCC。

## 实现者交付证据

- IQ/PRF/DispatchBackend/IntBackend 的 RED 均先稳定失败，GREEN 覆盖 full-only
  lane0/lane1、mixed fast/full、compaction/dispatch、kill survivor 与真实 DIV/CLMUL 依赖。
- fast wake/bypass 逐 lane 子集断言已做非真空负探针；完整 WB 仍是 ROB/
  BusyTable/PRF write/IQ sticky 唯一真源。
- T3B/C/D 累计候选通过 93/93 module、full Verilator、lint/style/contract、AM/FP/
  official 177 与 CoreMark10；CoreMark 为 `2,937,909 cycles / 3,218,573 commits`，
  CPI `0.913`、CRC `fcaf`。
- fresh 同参数络合将 original 109 loops 降到 16；top/loop 中已无
  MulDiv/CLMUL→integer IQ select 或 PRF read0–3 族。这关闭 T3B 的结构目标。

## 审查者裁决

- T3B/C/D fresh WNS/TNS=`-16.37/-273561.75 ns`、area `1,571,309.60`、power
  `0.120 W`，整体 timing candidate 被拒绝，父目标保持 active。
- T3E fresh 后证明 T3B 保留的 PRF read8 full write-through 会进入 FP execute top40；
  该前提已由 T3F 独立契约修订，不回写 T3B 当时的 108-loop 结论。
