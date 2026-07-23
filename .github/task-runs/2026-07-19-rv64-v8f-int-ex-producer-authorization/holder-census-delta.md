# v8f holder census delta

| holder / terminal | v8e | v8f 目标 | 裁决 |
|---|---|---|---|
| ROB allocation/head/commit/walk | full PID shadow | 保持；新增 current/open exact query | local source/query |
| integer IQ entries | raw idx | full PID 单一 holder，raw 低位派生 | scoped carrier |
| memory reservation | raw idx | full PID 单一 holder；仅本地 EX0 terminal 消费 | scoped carrier |
| EX0/EX1 stage | raw idx | full PID 单一 holder；exact formal completion | scoped active |
| fixed-GPR early wake | raw issue fact | issue PID current-exact gate | scoped active |
| async memory / SQ / MIQ / bridge | raw idx + memory token | 未改变 | RED |
| MulDiv / CLMUL | raw idx | 未改变 | RED |
| FP IQ / arith / done FIFO / FPR | raw idx | 未改变 | RED |
| branch resolve / redirect | raw idx | 未改变 | RED |
| global lease / no-live-reuse | absent | 未实现 | RED |

本表只证明 scoped file/field 变化，不声称 Domain-A field/instance/semantic census complete。

## v8f.1 authorization / transport owner delta

v8f.1 不新增 stateful holder。它只把已有 EX stage 的两个组合视图分权：

| view | source | 允许消费 | 禁止消费 |
|---|---|---|---|
| physical WB lane occupancy | `exN_pre_auth_valid_w` | free count、memory/MulDiv/CLMUL/FP lane grant/ready | ROB/PRF/Busy/IQ/forward/public completion 副作用 |
| formal completion authority | `exN_wb_valid_w` | actual WB mux、ROB done/data、GPR write、wake、forward、public completion | shared source availability/transport ready |

结构审计锁定 occupancy view 恰有 9 个 availability use；targeted netlist cone 证明 ROB
generation 从 5 个 ready 目标消失、但仍到达 ROB WB authority。该结论只关闭本地 owner
混用，不改变上表中 async/long/FP/branch/global RED 项。
