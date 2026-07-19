# RV64 v8c FP completion kill-cut task report

## 结果

`OooFpBackend` 的 exec1/long completion kill-edge 漏洞已在本合同范围内关闭。修复只改变一个
production RTL 文件：共享环形年龄计算，给 long 提取与 exec1 同构的 `long_kill_w`，并在
completion arbiter 入口形成 effective take；long kill 同沿清 meta+done-hold。正常仲裁仍是
`arith > live exec1 > live long`，killed exec1 不再阻挡 live long。

## Root cause

旧实现只让 `PipeStageReg` 与 long metadata 在上升沿响应 kill。沿前组合
`exec1_take_w/long_take_w` 仍为真，因此 wrong-path completion 已先驱动 generic WB/FIFO，FPR
destination 还会写 PRF、清 busy、发 ready/wakeup。FIFO 随后把条目标 killed 不能回滚这些前级
副作用。

## 实现者证据

- 冻结 pre-fix blob + 当前 TB：`26/170` 检查失败，包含 exec1、long、被取消 exec1 阻挡
  live-long；旧的 `21/90` 开工日志只保留作历史，不作为最终 hash-bound 权威。
- 当前 focused：`170/170 PASS`。
- compile-success semantic mutation：`14/14` 被定向测试检出；runner 明确拒绝 compile-fail、未跑完整 TB、
  空 PASS marker 与非目标异常退出。
- 当前共享源码 production module aggregate 已在 v8d 收尾重跑：`104/104 PASS`，并附 production/
  testbench source SHA 清单；此前 v8c 自身的 104/104 降格为 evidence-time supplemental。
- scoped Verilator lint、`check-rtl-style`、`check-contract` 均 PASS；assertion 数 `291 >= 89`。
- full strict lint 已对当前共享源码重跑，仍为 `115` warnings RED；归一化 SHA-256
  `414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b`，与 pre-v8a 基线字节相同，
  且没有 `OooFpBackend` warning。

## 独立反例复核与纠偏

- 复核了 younger/equal/older、双环回、live/killed FPR/GPR destination、三源
  `arith > exec1 > long` 碰撞、完整 FIFO head tuple、ready handshake、long done-hold、raw
  long-done+kill 与取消后无 delayed pulse。
- focused runner 原先只看进程返回码；现已加精确 170-check marker、完整 TB fatal oracle、冻结
  pre-fix blob/hash 与 current source inventory，防止 compile-fail 或陈旧日志假绿。
- 独立复核发现原 108-check 缺 live GPR、FIFO dequeue 与 arith+long/三源碰撞；4 类可生存
  变异证明确属覆盖洞，现由新增正控与 mutation 收口，不再沿用过宽结论。
- 相邻 P0 census 的 `AUTH→EXEMPT` 曾能假绿；现有 strongest-live-authority id 锁和 9 个
  self-test 明确拒绝降格成 `TOMBSTONE/EXEMPT/DETACHED`。

## 非声明与下一步

本刀没有 fresh synthesis/STA/benchmark，因此不声明 area、power、timing、IPC 或 PPA 改善；
只签收 FP completion kill-now scoped GREEN。global ROB no-live-reuse、generation-safe full identity、
WB authorization、Q1/CSR owner 与全核 strict lint 继续 RED。

整数 EX0/EX1 completion 同沿资格已由 v8d 切片 scoped GREEN；下一真实功能刀按 P1/P2 建立独立
`ProducerId={slot_generation,rob_idx}` 权威、传播到全部 AUTH carrier，并以 edge-old collision/
wrap guard 和 full-ID WB 完成资格关闭本轮已动态复现的 ROB slot ABA。

本目录是业务 RTL 证据包，不冒充 canonical agent-e2e publication；AI 环境的可发现/可执行/可审计
状态由 task-specific profile 与 strict guard 独立签收。
