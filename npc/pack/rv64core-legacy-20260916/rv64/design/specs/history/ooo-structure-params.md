# OoO 结构参数统一

## 需求

- 功能目标：把 RV64 OoO 核的默认结构容量事实集中到 `vsrc/include/define.v`，让 PRF、FreeList、ROB、Issue Queue 和 fetch packet FIFO 的默认位宽由同一组宏派生。
- 输入输出边界：本切片不新增运行时端口，只调整已有参数默认值和顶层调试计数端口位宽表达式。
- 时序约束：不新增寄存器、不改变 ready/valid、不改变数组深度数值；这是等价参数化重构。
- 上下游边界：`NpcTop`/`NpcCoreTop` 对外暴露 `free_count_o/rob_count_o/issue_count_o`，内部 `OooAluFetchCore -> OooAluCoreSlice -> OooAluDecodeBackend -> OooIntBackend -> OooDispatchBackend` 继续把参数向下传递。
- 不在范围：不改变 ROB/IQ/PRF/FETCH 容量，不拆 `OooFpPendingExec`，不调整 dispatch/issue/commit 策略。

## 协议规则

- `OOO_PHY_REG_ADDR_W` 决定物理寄存器索引宽度，`OOO_PHY_REG_COUNT` 默认为 `1 << OOO_PHY_REG_ADDR_W`。
- `OOO_FREE_COUNT_W` 必须能表达完整物理寄存器个数，因此默认是 `OOO_PHY_REG_ADDR_W + 1`。
- `OOO_ROB_INDEX_W` 决定 ROB 指针宽度，`OOO_ROB_COUNT_W` 必须比索引宽一位以表达 full count。
- `OOO_ISSUE_INDEX_W` 决定 IQ 指针宽度，`OOO_ISSUE_COUNT_W` 必须比索引宽一位以表达 full count。
- `OOO_FETCH_PACKET_COUNT_W` 决定 fetch packet FIFO 深度指数，局部 `FETCH_COUNT_W` 仍由 FIFO/父模块派生。

## 状态机

本切片无新增状态机。所有状态机保持原 owner：

| 状态 owner | 本切片影响 |
| --- | --- |
| `OooFreeList` head/tail/count | 仅默认参数来源改变，状态转移不变 |
| `OooRob` head/tail/count | 仅默认参数来源改变，状态转移不变 |
| `OooIntIssueQueue` queue count | 仅默认参数来源改变，选择/压缩逻辑不变 |
| `OooFetchPacketFifo` head/tail/count | 仅默认 fetch packet count 参数来源改变 |

## 不变量

- `free_count_o` 宽度等于 `OOO_FREE_COUNT_W`，必须能表示 `OOO_PHY_REG_COUNT`。
- `rob_count_o` 宽度等于 `OOO_ROB_COUNT_W`，必须能表示 `1 << OOO_ROB_INDEX_W`。
- `issue_count_o` 宽度等于 `OOO_ISSUE_COUNT_W`，必须能表示 `1 << OOO_ISSUE_INDEX_W`。
- 子模块默认参数不得再使用散落的 `6/7/4/5/3/2` 作为 OoO 结构默认事实。
- 非默认实例仍可通过 parameter override 做 focused test，不把 testbench 局部参数强行绑死到宏。

## 数据通路约束

- `NpcTop` 与 `NpcCoreTop` 的计数端口使用宏宽度，避免 SoC/debug ABI 与内部容量漂移。
- `NpcCoreTop` 显式向 `OooAluFetchCore` 传入完整宏参数组，包括 `PHY_REG_ADDR_W/FREE_COUNT_W/FETCH_PACKET_COUNT_W`。
- `OooDispatchBackend` 内部仍按 `ROB_INDEX_W` 和 `ISSUE_COUNT_W - 1` 派生真实 ROB/IQ 深度。
- `OooRob`、`OooFreeList`、`OooIntIssueQueue`、`OooPhysRegFile` 默认参数引用宏，但外部显式覆盖优先级保持 Verilog parameter 规则。

## RTL 自检

- `define.v` 新增 `OOO_PHY_REG_ADDR_W`、`OOO_PHY_REG_COUNT`、`OOO_FREE_COUNT_W`、`OOO_ROB_INDEX_W`、`OOO_ROB_COUNT_W`、`OOO_ISSUE_INDEX_W`、`OOO_ISSUE_COUNT_W`、`OOO_FETCH_PACKET_COUNT_W`。
- `NpcTop`/`NpcCoreTop` 调试计数端口改用宏位宽，删除 `NpcCoreTop` 内重复 `localparam`。
- `OooAluFetchCore`、`OooIntBackend`、`OooDispatchBackend`、`OooRob`、`OooFreeList`、`OooIntIssueQueue`、`OooPhysRegFile` 等默认参数改为引用宏。
- 残留扫描：`rg` 未发现 vsrc 中同类默认参数硬编码。

## 验证

- focused module testbench：`tb_ooo_free_list tb_ooo_rob tb_ooo_int_issue_queue tb_ooo_phys_reg_file tb_ooo_dispatch_backend tb_ooo_int_backend tb_ooo_alu_fetch_core tb_ooo_fetch_packet_fifo tb_ooo_sv39_boot` 9/9 PASS，结果目录 `npc/rv64/perf/results/20260627-ooo-struct-params/focused/`。
- `make -C npc/rv64 lint` PASS。
- `make -C npc/rv64 -j2` PASS。

