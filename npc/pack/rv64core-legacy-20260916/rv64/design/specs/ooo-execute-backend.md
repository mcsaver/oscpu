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
- S2-Q2 v8a 增加一条严格结构 spine：两个 permit 向下、三个 ROB shadow observation 向上，
  `OooExecuteBackend -> OooAluCoreSlice -> OooAluDecodeBackend -> OooIntBackend ->
  OooDispatchBackend -> OooRob` 全部同名同宽直连。各 wrapper 不得寄存、解释或本地重驱动；
  observation 不得回灌 stall/commit/dispatch。

## 4. 验证

- `make -C npc/rv64 lint` / build PASS；module testbench 103/103 PASS；
  official riscv-tests（177 项）0 FAIL。

## 5. 边界

只完成 execute 子系统 wrapper 抽取；`OooFpPendingExec`/`OooIntBackend` 巨石内部拆分、
PPA/timing/sign-off 仍待后续。

## 6. R4-S0 最终 PA/cacheability 传播合同

R4-S0 在既有单 memory owner 上增加一条承重 sideband；它不是新的静态 lane 角色：

```text
OooMemAxiBridge.mem0_rsp_cacheable_o
  -> OooCoreTopGlue.mem_rsp_cacheable_i
  -> OooExecuteBackend/OooAluCoreSlice/OooAluDecodeBackend
  -> OooIntBackend.sq_fill_cacheable_w
  -> OooStoreQueue.cacheable_q[owner]
  -> sq_drain_cacheable_w
  -> mem_req_cacheable_o
  -> bridge pretrans request station
```

- probe success 必须把 bridge 在最终 PA/PMA/PBMT 后产生的属性与 PA 一起写进同一个 SQ
  owner；从 fill 到 release 不可变。drain 只能读该 SQ entry 保存的值，禁止按当前 PA/VA、
  当前 PTE 或当前 lane 重新分类。
- `mem_req_cacheable_o` 仅在 `grant_sq_w` 时携带 physical drain owner 的保存属性；其它
  request 类型不得伪造 cacheable。已有断言要求 SQ head 的 drain 与 snoop 属性一致。
- 当前 sideband 是 Boolean，NC 与 IO 仍被合并；当前 execute backend 仍只有一个真实 memory
  terminal/admission owner。因此 R4-S0 只能作为 post-translation correctness checkpoint，
  DI-5 与完整双发射继续为 RED。
- S1 必须把该边界替换为 `attr_valid + class[1:0]`，且所有 legacy Boolean 只可由 typed
  class 局部派生；S2 必须增加两个独立 AGU/translation/physical-query/cache-admission/
  completion owner。端口 0/1 只是 transport slot，不得固定 load/store 或程序序 lane。
