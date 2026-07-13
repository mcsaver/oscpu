# RV64 T3C：FP admission state-only credit / actual accept 拆环

## 基本信息

- `task_id`: 2026-07-13-rv64-t3c-fp-admission-credit
- `status`: completed (structural slice); parent timing goal remains active
- `profile`: npc-dev
- `base_commit`: eb9bd3b28（工作树叠加未提交 T3B）
- `parent_goal`: active；完整功能与 physical 200 MHz 未闭合
- `trigger`: T3B 后 Verilator full build 暴露唯一 FP admission `UNOPTFLAT` 真环并 fatal

## 目标与接受门禁

用 raw intent / state-only registered count credit / joint admission / actual accept 恢复 FP ready DAG，
不增加流水级、不建立 shadow credit、不吞吐降级。接受条件：

1. mandatory lane1 始终 `fire0==fire1`，optional lane1 可仅 fire0；
2. accept=0 时 FP map/free/busy/IQ 不变化，恢复后 payload exactly-once；
3. FP arithmetic/load/store 的 credit need 精确，kill/recover/flush/ROB-walk 语义不变；
4. focused、负探针、93项模块、Verilator full build、FP difftest/AM/CoreMark 全绿；
5. fresh OpenSTA 的 FP admission loop family 为0，且 T3B long-op loop fan-in另行核验。

## 合同真源

六类合同、credit 公式、周期表与 RED/GREEN 矩阵统一见
`npc/rv64/design/specs/ooo-fp-admission-credit.md`。

## 交付证据与裁决

- 旧 RTL 在 mandatory pair credit 边界稳定 RED；实现后 state-only count credit、raw
  intent、joint admission 与 actual accept 分层，optional/mandatory 双 lane 和反压恢复均通过。
- `[FP-DISPATCH-PAIR-ATOMIC]` 负探针精准触发；93/93 module、full Verilator、
  AM/FP/official 177 与 CoreMark10 通过。
- T3B/C/D fresh OpenSTA 中 FP admission 真环已消失；剩余 16 环全属 legacy
  checkpoint capture 族，后由 T3E 清零。
- T3C 结构切点保留；合并候选 WNS/TNS 仍为 `-16.37/-273561.75 ns`，
  不声称 200 MHz。
