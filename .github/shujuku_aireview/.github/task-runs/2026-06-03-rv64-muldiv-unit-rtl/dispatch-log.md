# 调度记录

## 2026-06-03

- 读取 RV64 RTL PPA 审计结论，选择 P1 项：将 `OooIntBackend` RV64M 组合执行路径抽成独立多周期单元。
- 推导 ready/valid 协议、状态机、不变量和数据通路约束。
- 新增 `OooMulDivUnit`，接入 `OooIntBackend` issue backpressure、flush/checkpoint restore 和 `wb0/wb1` 写回仲裁。
- 新增 `Linux/tools/muldiv-smoke.S` 与 `smoke-muldiv` target。
- 首次 `smoke-muldiv` 在 `mulhsu` 后依赖分支失败，退出 code=4。
- 用临时最小程序确认单条 `mulhsu` 算术正确，带前缀时 consumer 可读到未就绪结果。
- 定位 `OooIntIssueQueue.ctrl_can_forward()` 未排除 `CTRL_MULDIV_BIT`，修正后重新验证通过。
- 完成验证：lint、Verilator build、`smoke-muldiv`、`smoke-jal-link`、`smoke-branch-raw`。
