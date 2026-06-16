# RV64 MulDiv 多周期 RTL 化

日期：2026-06-03

## 目标

将 RV64 OoO integer backend 中用于功能仿真的 RV64M 组合 `/`、`%` 执行路径，收敛为更接近 ASIC RTL 的显式 ready/valid 多周期执行单元，降低主 issue/execute 组合关键路径风险，并保持可读、可验证的模块边界。

## RTL 推导

### 需求

- RV64M 指令不再在 `OooIntBackend` issue 当拍用组合函数完成。
- 乘除单元与 backend 之间使用 ready/valid 协议，最多一个 outstanding M uop。
- flush 或 checkpoint restore 后不能写回旧 M 响应。
- 依赖 M 结果的后续 uop 必须等待真实 writeback wakeup，不能同拍 issue 读未就绪物理寄存器。

### 协议规则

- `OooMulDivUnit.req_valid/req_ready` 接收一条 M uop，payload 包含 `rob_idx/pdest/inst/src1/src2/word_op`。
- `resp_valid/resp_ready` 返回写回 payload；响应在 ready 前保持稳定。
- backend 只在写回仲裁选中 MulDiv 响应时拉高 `resp_ready`。
- `flush_i || checkpoint_restore_i` 清空 MulDiv 单元内部状态和待返回响应。

### 状态机

- `IDLE`：可接收请求。
- `DIV_RUN`：对 DIV/REM 做 64-cycle unsigned restoring division，再按 signed/word 规则修正结果。
- `RESP`：保持响应，直到 backend 写回仲裁接收。

乘法类请求在 `IDLE` 接收后进入 `RESP`，除零和 signed overflow 作为特殊结果直接进入 `RESP`。

### 不变量

- 同一时间最多一条 M uop 在 MulDiv 单元内。
- M uop 发射后不会写 `ex0/ex1` 当拍结果寄存器。
- M uop 不参与 issue queue 的同拍 forward/bypass。
- M 响应只通过 `wb0/wb1` 统一写回和 wakeup。
- flush/checkpoint restore 后旧 M 响应无写回路径。

### 数据通路约束

- `OooIntBackend` 中删除 `rv64m_result()`，主 execute 组合路径不再包含 `/` 或 `%`。
- `OooMulDivUnit` 保留乘法高/低半部组合乘法表达式；除法/求余改为移位减法迭代。
- 写回优先级保持原 backend 风格：`ex` 和 memory 响应优先，MulDiv 响应填空闲写回槽。
- `OooIntIssueQueue.ctrl_can_forward()` 明确排除 `CTRL_MULDIV_BIT`，避免 M 结果消费者被同拍虚拟 entry 发射。

## Root Cause 与修复

初版拆分后新增 `smoke-muldiv` 在 `mulhsu` 后的依赖分支失败。临时最小程序确认单条 `mulhsu(-2, 3)` 算术结果正确；带 `mulh -> branch -> mulhsu -> consumer` 前缀时，consumer 读到未就绪物理寄存器值。

根因：`OooIntIssueQueue` 的 `ctrl_can_forward()` 仍把所有非 memory/control uop 视为可同拍 forward，RV64M 被错误纳入。虽然 `OooIntBackend` 已经停止 M 当拍写回和 current-result bypass，issue queue 仍可能让依赖 M 目标寄存器的 dispatch1/issue1 虚拟 entry 同拍发射。

修复：`ctrl_can_forward()` 增加 `ctrl_muldiv` 输入并返回 `!ctrl_muldiv`，所有调用传入 `CTRL_MULDIV_BIT`。

## 改动文件

- `npc/rv64/vsrc/ooo/backend/OooMulDivUnit.v`
- `npc/rv64/vsrc/ooo/backend/OooIntBackend.v`
- `npc/rv64/vsrc/ooo/issue/OooIntIssueQueue.v`
- `npc/rv64/vsrc/filelist.mk`
- `Linux/tools/muldiv-smoke.S`
- `Linux/tools/Makefile`

## 验证

- `make -C npc/rv64 lint` PASS
- `make -C npc/rv64 -j2` PASS
- `make -C Linux/tools smoke-muldiv` PASS，GOOD TRAP，`cycles=634, commits=88`
- `make -C Linux/tools smoke-jal-link smoke-branch-raw` PASS，两个用例均 GOOD TRAP

## 后续

- 当前 `OooMulDivUnit` 的除法是保守 64-cycle restoring divider，适合先移除主路径组合除法风险；后续 PPA 可替换为 radix-4/radix-8 divider 或独立可配置 latency。
- 乘法仍是单周期组合乘法表达式并隔离在独立单元内；后续如需面向频率/面积，可替换为 Booth/Wallace 或多周期 multiplier。
- 下一优先级建议继续处理 `OooAluFetchCore` 内 FP/FDIV/FSQRT 组合 helper 与 `AxiLiteXbar` 集中组合仲裁。
