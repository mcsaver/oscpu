# 规范：重排序缓冲 OooRob

> 模块：`vsrc/writeback/OooRob.v`。模板见 `../arch/SPEC-TEMPLATE.md`。状态：已实现并验证。

## 1. 目的与范围
ROB 是乱序执行与精确提交的边界：执行可乱序完成(writeback)，但对外 commit、异常上报、
旧物理寄存器释放必须按 head 程序序发生。容量 ROB_ENTRIES=16(`OOO_ROB_INDEX_W`=4)。
2-wide dispatch / 2-wide writeback / 2-wide in-order commit。支持 checkpoint/restore(分支投机回滚)。

## 2. 接口（要点）
| 组 | 信号 | 含义 |
| --- | --- | --- |
| dispatch0/1 | valid/ready/rob_idx + pc/inst/rd/old_pdest/new_pdest | 在 tail 分配 ROB 项,返回 idx |
| wb0/1 | valid/rob_idx/exception | 乱序标记 done(可命中 head 或 head1) |
| commit0/1 | valid/pc/inst/rd/old_pdest/new_pdest/data/exception/cause/tval | head 程序序退休输出 |
| commit_ready_i / commit1_block_i | | 上游提交准入 / 单独阻断 commit1 |
| flush_i / checkpoint_capture/restore | | 冲刷 / 分支快照与回滚 |

## 3. 状态与时序
- 环形:`head_q`(提交端)、`tail_q`(分配端)、`count_q`;每项 `valid_q/done_q/exception_q/rd_en_q/...`。
- dispatch:`count+dispatch < ROB_ENTRIES` 时 ready;在 tail 写入 valid=1,done=0。
- writeback:`done_q[wb_rob_idx] <= 1`(可乱序,wb0/wb1 命中 head 或 head1)。
- commit:head(及 head1)valid&done&commit_ready 时退休;commit1 可被 `commit1_block_i` 单独挡。
  提交时输出架构 rd/data、释放 old_pdest、推进 head。
- 异常:提交项 exception=1 → commit0_exception 上报(精确,在 commit 边界),触发上游 flush。
- checkpoint:分支投机时 capture 全 ROB 状态;误预测 restore 回滚到检查点。

## 4. 不变量
- **ROB-I1 程序序提交**：commit 只从 head 起按序;commit1 必为 head 的下一项且不早于 commit0。
- **ROB-I2 精确异常**：异常只在 commit 边界对外可见;异常项之后的项不得提交其架构副作用。
- **ROB-I3 旧 pdest 释放**：仅在该写 rd 的 uop 提交时释放其 old_pdest(回 free list)。
- **ROB-I4 容量**：dispatch ready 严格按 `count+本拍dispatch ≤ ROB_ENTRIES`,不溢出覆盖未提交项。

## 5. 关键路径
Vivado OOC:OooRob 单独 6 逻辑级/logic ~1.4ns(浅,健康),非 Fmax 瓶颈。深度 16 项 commit-select 简单。
(对比:DispatchBackend 把 ROB/free-list/busy/IQ 合一才深,见 `ooo-rename-alloc.md`。)

## 6. 验证
- 模块 TB `tb_ooo_rob`;集成 riscv-tests 271(精确异常/委托/重定向)、AM 56(分支恢复/异常/退休序)。

## 7. 变更记录
- 2026-06-28：逆向文档化(2-wide in-order commit / 精确异常 / checkpoint)。
