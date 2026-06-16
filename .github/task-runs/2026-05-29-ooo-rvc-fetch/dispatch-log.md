# Dispatch Log

## 2026-05-29

- 任务：补齐 OoO 实验核 RVC fetch/decompress 与真实 `next_pc` 元数据。
- 失败定位：实验构建运行 `cpu-tests add` 时在 `0x8000000c` 报 `EXC_ILLEGAL_INST`；反汇编显示该地址是 `2859 c.jal 0x800000a2`，高半字为下一条 `c.beqz`，当前前端把 `0xc1112859` 当成单条 32-bit 指令。
- 设计选择：不绕过 AM 的 RVC，也不把 compressed jump 特判成伪 PC；改为让每条 uop 携带真实 `next_pc`，前端只负责解压，后端照常执行解压后的 32-bit 指令。
- 范围边界：本轮仍不引入预测/checkpoint/rollback/LSQ；control 与 memory 沿用 drain barrier，目标是先把默认 AM RVC 指令流跑进实验核。
- 实现：`OooAluFetchCore` 从 response 两个 word 中组成 halfword window，按 lane0 长度决定 lane1 起点，可处理 compressed、32-bit 和 offset2 跨 word 32-bit 指令；fetch FIFO 保存 lane0/lane1 `pc/next_pc` 和 packet next PC。`OooAluCoreSlice -> OooAluDecodeBackend -> OooIntBackend -> OooDispatchBackend -> OooIntIssueQueue/OooRob` 全链路新增 `next_pc` 元数据，`WBU` 的 link 输入改接 issue `next_pc`。
- 测试：新增 fetch-core RVC `c.jal` 覆盖；全量模块回归 `38/38`；实验 OoO 路径默认 AM `cpu-tests add` GOOD TRAP，`cycles=3647/commits=839/CPI=4.347`；raw 4096 ALU 仍 `CPI=0.502`；默认主线 `cpu-tests add` 仍 `CPI=1.801`。
- 注意：实验 OoO 的 AM `add` 已功能通过，但 CPI 被 drain barrier 拉高；后续性能目标应优先消除 control/memory 全排空路径。
