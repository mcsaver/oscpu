# v8i FP holder census delta

| holder | v8h state | v8i signed state | claim boundary |
|---|---|---|---|
| FP IQ entries | raw idx AUTH/RED | full PID + Q-only live mask AUTH | issue transition |
| FP issue packet | raw idx packed AUTH/RED | full PID + Q-only live mask AUTH | execute launch |
| FP arith meta[1..5] | raw idx AUTH/RED | full PID + five Q owners AUTH | raw arith output |
| FP exec1 stage | raw idx packed AUTH/RED | full PID + Q-only live mask AUTH | raw exec1 take |
| FP long meta/done hold | raw idx AUTH/RED | full PID + Q-only live mask AUTH | raw long take |
| FP done FIFO | raw idx AUTH/RED | full PID + occupied-token pending/live mask AUTH | raw formal pop |
| FP result side effect | kill-now only | exact-open + pending/claim AUTH | PRF/Busy/wake/FIFO push |
| FP formal WB | raw idx only | exact-open + token-owner/claim AUTH | WB/ROB/GPR/public |
| post-launch capacity | empirical `fifo_count<=2` | exact Q occupancy credit AUTH | issue launch |

本 delta 的 local holder census 已由 16 项 source-bound audit、release/assert、10 个 compile-success
mutation、旧 v8f/v8g/v8h 专项与 105/105 module aggregate 签收。`AUTH` 只表示本表 FP scoped
边界，不表示完整 Domain-A、全核 last-reference 或 finite-generation global no-live-reuse 已闭合。

非本 delta：branch、pending-system/CSR、完整 Domain-A census、global no-live-reuse。
