# OooExecuteBackend 子系统 wrapper Spec

## 1. 目标

把 `execute/` 目录供 core 数据通路用的执行 owner 聚合到
`execute/OooExecuteBackend.v`，让 `OooCoreTopGlue` 只对执行子系统做一次实例化。
纯结构聚合，不新增逻辑、不改行为。
（抽取当时为 4 个实例；pending-FP 通路拆除后现仅剩 2 个,见 §2。）

## 2. 责任边界（内部 owner）

> ⚠️ **状态（2026-07-03 RTL 重读）**：原 wrapper 内的 `OooFpPendingExec` / `OooPendingFpSequencer`
> （域 B pending-FP 通路）已随 FP 簇真乱序迁移被拆除,FP 执行现居 `OooFpBackend`（挂在
> `OooIntBackend` 内）;wrapper 现仅含下表 2 个实例。

| 内部 owner | 职责 |
| --- | --- |
| `OooAluCoreSlice` | 整数 OoO backend slice（内含 rename/dispatch/ROB/IQ/PRF/ALU/mul-div 及 FP 簇 `OooFpBackend` 等执行核心） |
| `CompareUnit`(u_pending_branch_compare) | pending branch 比较（域 B 死通道：pending_branch capture 被 `!OOO_ROB_WALK_MODE` 门死恒 0,本比较器输出无活消费,拆除计划见 `../arch/ooo-core-architecture.md` §8.3） |

## 3. 接口与不变量

- wrapper 端口 = 内部实例跨边界信号（抽取当时 4 实例 149 个;pending-FP 拆除后 2 实例,
  `pending_fp_*` 端口族已随之消失）。
- glue 顶层 wire 名保留；`core_*`、debug count（`free_count_o`/
  `rob_count_o`/`issue_count_o`）等仍以同名 glue wire/端口形式存在。
- wrapper 保留 `PHY_REG_ADDR_W`/`ROB_INDEX_W`/`ROB_COUNT_W`/`FREE_COUNT_W`/
  `ISSUE_COUNT_W`（core slice 使用），不保留未用的 `FETCH_PACKET_COUNT_W`。

## 4. 验证

- `make -C npc/rv64 lint` / build PASS；module testbench 103/103 PASS；
  official riscv-tests（177 项）0 FAIL。

## 5. 边界

只完成 execute 子系统 wrapper 抽取；`OooFpPendingExec`/`OooIntBackend` 巨石内部拆分、
PPA/timing/sign-off 仍待后续。
