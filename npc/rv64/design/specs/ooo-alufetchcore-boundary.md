# OooAluFetchCore 工业化拆分边界 Spec

## 目标

`frontend/OooAluFetchCore.v` 历史上同时承担前端取指、控制流恢复、特殊指令排空、FP 计算、CSR/trap 仲裁和提交修饰，已经不再符合一个 RTL module 的可审计边界。本 spec 固化后续拆分方向：父模块先保留系统级 glue 和时序所有权，算法型、队列型、状态型逻辑逐步迁入对应功能目录。

## 责任边界

| 分类 | 目标目录 | 当前 owner | 拆分状态 |
| --- | --- | --- | --- |
| PC/预测/取指 request-response | `frontend/` | `OooAluFetchCore` | 待拆；先写 FIFO/redirect spec |
| RAS/return continuation/branch target capture | `frontend/` | 独立 helper | 已拆 |
| 基础 decode/RVC/FP decode | `decode/` | 独立 helper | 已拆 |
| rename/dispatch/ROB/IQ/PRF/backend | 对应外层目录 | `OooAluCoreSlice` 及子模块 | 已拆为执行核心切片 |
| FP pending 执行数据通路 | `execute/` | 独立 helper | 已拆到 `OooFpPendingExec` |
| FPR 状态/读写 | `regread_bypass/` | 独立 helper | 已拆到 `OooFpRegFile` |
| CSR/trap/interrupt/flush/recovery | `control/` + `core/` | `OooAluFetchCore`/`CsrFile` | 待拆；需先建立 precise control spec |
| writeback/commit 修饰 | `writeback/` + 父模块 glue | `OooAluFetchCore` | 待拆；需保留 commit_ready 精确边界 |

## 关键不变量

- 父模块是当前 `stop_pending_q`、pending owner、`commit_ready_i`、flush 与 trap redirect 的唯一时序仲裁点；子模块不得自行提交架构事件。
- 前端 fetch FIFO 与 outstanding response 的所有权暂不移动，直到 redirect/drop/drain/fallthrough/branch-prefetch/JALR-prefetch 的单一 owner 规则写完。
- 执行类 helper 可以输出组合结果、迭代完成事件和 fflags，但不能直接写 GPR/FPR/CSR，也不能直接改变 `next_fetch_pc_q`。
- 任何新 helper 必须有同名源文件、filelist 条目和 focused 或父模块回归覆盖。

## 分阶段计划

1. 抽出 `execute/OooFpPendingExec.v`：只承接 FP pending 数据通路和 div/sqrt 迭代包装，父模块仍保存 pending/commit 时序。
2. 抽出 `regread_bypass/OooFpRegFile.v`：只承接 FPR 状态、读端口和 FP 写回，父模块只生成写回条件。
3. 为 fetch packet FIFO 写单独 spec：覆盖 enqueue/pop/bypass/drop/flush/redirect seed，不在没有 spec 前抽代码。
4. 为 precise control 写单独 spec：把 `pending_system_*`、`pending_arch_trap_*`、CSR probe/commit 与 interrupt/mret/sret 统一到控制边界。
5. 最后把 `OooAluFetchCore` 改名或缩小为真正的 core integration shell，避免 `frontend` 文件名继续承载执行/提交语义。
