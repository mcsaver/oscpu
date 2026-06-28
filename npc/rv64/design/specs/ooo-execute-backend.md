# OooExecuteBackend 子系统 wrapper Spec

## 1. 目标

把 `execute/` 目录供 core 数据通路用的 4 个执行 owner 聚合到
`execute/OooExecuteBackend.v`，让 `OooCoreTopGlue` 只对执行子系统做一次实例化。
纯结构聚合，不新增逻辑、不改行为。

## 2. 责任边界（内部 owner，行为不变）

| 内部 owner | 职责（不变） |
| --- | --- |
| `OooAluCoreSlice` | 整数 OoO backend slice（内含 rename/dispatch/ROB/IQ/PRF/ALU/mul-div 等执行核心） |
| `OooFpPendingExec` | FP pending 执行数据通路（含 div/sqrt 迭代器） |
| `OooPendingFpSequencer` | pending FP 单 entry 注册状态 |
| `CompareUnit`(u_pending_branch_compare) | pending branch 比较 |

## 3. 接口与不变量

- wrapper 端口 = 4 个内部实例跨边界信号（149 个）。
- glue 顶层 wire 名保留；`core_*`、`pending_fp_*`、debug count（`free_count_o`/
  `rob_count_o`/`issue_count_o`）等仍以同名 glue wire/端口形式存在。
- `pending_fp_div_busy_w` / `pending_fp_sqrt_busy_w` 等被 glue 顶层 unused 聚合
  `wire X = ...;` 消费的信号，作为 wrapper **输出**保留（不下沉），保证 glue 聚合仍可引用。
- wrapper 保留 `PHY_REG_ADDR_W`/`ROB_INDEX_W`/`ROB_COUNT_W`/`FREE_COUNT_W`/
  `ISSUE_COUNT_W`（core slice 使用），不保留未用的 `FETCH_PACKET_COUNT_W`。

## 4. 验证

- `make -C npc/rv64 lint` / build PASS；module testbench 103/103 PASS；
  official riscv-tests（177 项）0 FAIL。

## 5. 边界

只完成 execute 子系统 wrapper 抽取；`OooFpPendingExec`/`OooIntBackend` 巨石内部拆分、
PPA/timing/sign-off 仍待后续。
