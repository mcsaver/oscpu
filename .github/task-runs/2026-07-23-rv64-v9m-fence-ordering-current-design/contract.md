# V9M ordinary FENCE ordering contract

## 本地 RV64 工程范围

本任务只处理工作区内 RV64 Verilog/SystemVerilog RTL、testbench、Icarus 仿真、
证据 JSON 与架构账本。普通 `FENCE` 是 pending-system 串行退休事件；其完成不得早于
此前 memory effects 的可观察排空边界。

## 接口与状态合同

| 对象 | producer | consumer | 当前合同 |
| --- | --- | --- | --- |
| `pending_system_fence_i` | pending-system instruction decode/owner | `OooPendingDrainResolveGate` | 仅普通 `FENCE` 为 1 |
| `mem_retire_quiet_i` | SQ/退休侧 memory owner | `backend_drained_o` | 证明已无待退休 store，但不代表 MIQ/bridge/reservation 全空 |
| `mem_idle_i` | 完整 memory-owner graph | FENCE-specific predicate | MIQ、bridge transaction/buffer 与 reservation 均空时为 1 |
| `drain_complete_o` | drain gate | pending control retirement | 对普通 `FENCE` 必须同时满足 backend drained、control ready、无 replay wait、`mem_idle_i=1` |

## 访存顺序不变量

1. lane0 older store 与 lane1 `FENCE` 同包时，lane1 必须进入 pending owner。
2. `mem_retire_quiet_i=1 && mem_idle_i=0` 时，普通 `FENCE` 的
   `drain_complete_o` 必须为 0。
3. older store probe/drain 各发生一次；普通 `FENCE` 架构退休一次。
4. younger device read 不得早于 older store drain，也不得早于 `FENCE` 退休。
5. 非普通 `FENCE` 的既有 pending-system drain 条件不额外依赖 `mem_idle_i`。
6. `core_mem_idle_w` 经 CoreGlue→ControlPlane→drain gate 必须无变形直连；
   定向程序在 busy-memory 周期显式比较该端口。
7. focused 与 module aggregate 的每个成功日志必须含编译时注入的当前
   production RTL SHA，旧 design-id 日志不得重新绑定。

## flush/stall/同拍优先级

本轮不修改 production RTL 的 flush/stall/priority 逻辑。沿用现有全序与不可撤销
memory transaction 合同；负向 RTL 版本只替换 FENCE-specific combinational predicate，
不改变其它输入、状态或模块边界。第二个负向版本只把 CoreGlue 的
`.mem_idle_i(core_mem_idle_w)` 替换为常量，用于证明全核程序对跨模块传递有灵敏度。
