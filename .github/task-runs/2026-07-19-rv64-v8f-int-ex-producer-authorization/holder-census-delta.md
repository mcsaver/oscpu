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
