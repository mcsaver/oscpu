# architecture-first 落地报告（本周最小起步 + 闭环 gate + agent 环境结合）

> **类型**: task-run 证据（只增不改）。**日期**: 2026-07-05。**承接**: 同目录 `architecture-first.md` 的"最小起步"与 decisions [38]。
> **性质**: 实质代码 + agent 环境改动（非纯分析）。所有验证证据在下方，均本地实跑复核。

## 目标与结论

把 decisions [38] 的两件最小起步落地，并按用户要求把 architecture-first **有机结合进整个 agent 环境**，且把"assert 探针"升级为**工作流常驻的 RTL-vs-spec 符合性 gate**（用户洞察）。

| 项 | 结论 | 证据 |
|---|---|---|
| ① rv64ua/uf/ud 入默认回归 | **早已完成**（2026-07-01 commit `d32b256be`，非本次） | 白名单 `npc-rv64-core-regress.sh:24`；本次实跑三套件 42 测试全 PASS（`perf/results/core-regress/20260705-121653-889826/`） |
| ①加固 | 新增防回退护栏 | 只校验 `RISCV_SUITES_DEFAULT` 常量（不误伤运行时 `--riscv-suites` 缩集）；逻辑实测：含 A/F/D→rc=0，删 rv64ua→FAIL |
| ② --assert 立即断言探针 | **工具链验证通过：能走契约→可执行检查这条路** | 见下"三步证据" |
| ③ 闭环 gate（用户洞察） | `make check-contract` 建成并有牙齿 | 删断言→gate rc≠0，恢复→rc=0 |
| ④ agent 环境有机结合 | 8 文件焊进"发现→工作流→完成→gate"四道装置 | 见下"改动清单" |

## 关键校正（诚实记录）

`architecture-first.md` 原断言"rv64ua/uf/ud 不在默认回归里 = 零护栏"**前提是错的**——侦察实读 `npc-rv64-core-regress.sh:24` + commit `d32b256be` + 实跑日志证明它们 2026-07-01 就已进默认回归且全绿。当时那句是照报告叙事推断、未核实脚本。这再次印证复盘主结论"别信没核实的断言"。任务①因此从"添加"降级为"确认 + 上防回退护栏"。

## ② 三步证据：工具链能执行契约→立即断言

在 `OooFetchPacketFifo.v` 加契约②不变量（count_q ≤ 物理深度 4）的立即断言（`ifdef OOO_ASSERT` 门控），iverilog module-TB 实跑：

| 步骤 | vvp exit | 输出 |
|---|---|---|
| 真版 | 0 | `[PASS]`，编译通过、不误报 |
| 制造违约（条件改 `!rst` 恒真） | 1 | `ERROR: OooFetchPacketFifo.v:162: [CONTRACT-FIFO-OVFL] count_q=0 exceeds depth=4` + `FATAL` |
| 恢复真版 | 0 | `[PASS]`，文件干净 |

工具链事实（Agent 隔离实验实证）：过程式 `always @(posedge clk) if(违约) $error/$fatal` 在 Verilator（`--assert`/`--noassert`/无flag）与 iverilog **全部会响**；`--assert` 只管 SV `assert()` 关键字。全核带 `--assert`+`+define+OOO_ASSERT` 构建 `npc-build PASS`、三套件全绿、`CONTRACT-FIFO-OVFL` 误报=0。

## 改动清单（16 文件：新建 4 + 修改 12）

**RTL / 构建 / 回归**
- `npc/rv64/vsrc/frontend/OooFetchPacketFifo.v`：加契约②立即断言（`ifdef OOO_ASSERT`）。
- `npc/rv64/Makefile`：`--noassert`→`--assert`；加 `+define+OOO_ASSERT`（断言常驻全核 sim，synth 不含）；挂 `check-contract` target。
- `npc/rv64/testbench/Makefile`：`IVFLAGS` 加 `-DOOO_ASSERT`（module-TB 也编入断言）。
- `npc/rv64/eval/check-contract.sh` + `contract-assert-baseline.txt`（**新建 gate**）：三检查（`--assert` 存在 / `+define+OOO_ASSERT` 存在 / 立即断言 `$error` 计数不回退）。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh`：默认白名单防回退护栏。

**agent 环境（契约先行焊进四道装置）**
- `.github/instructions/interface-contract-first.instructions.md`（**新建**，六类契约规范单一真源，`applyTo: npc/rv64/**`）。
- `.github/instructions/rtl-generation-workflow.instructions.md`：阶段 0 契约先行 + 验证回环⑤ `check-contract` + 留痕「接口契约冻结」+ 禁止条。
- `.github/AGENTS.md`：必读链加契约先行项 + §7 完成判定钩子加契约核对条。
- `.github/agents/npc.agent.md`：顶部 RTL 强制工作流节 + 边界契约硬门槛。
- `.github/agents/hardware-flow.agent.md`：节点原则加 `interface-contract-freeze` 前置节点。
- `npc/rv64/design/arch/SPEC-TEMPLATE.md`：顶部契约先行强制 + §2 flush「谁清谁保持」表必填 + §4 立即断言义务。

## 全部 gate 验证（本地实跑）

- `make check-rtl-style` PASS（断言合规，未引入 SV 关键字）。
- `make check-contract` PASS（`--assert`✓ / `OOO_ASSERT`✓ / 断言计数 1≥1✓）；删断言→rc≠0，恢复→rc=0。
- `tb_ooo_fetch_packet_fifo` module-TB PASS（断言常驻不破坏）。
- 全核 build（`--assert`+`OOO_ASSERT`）`npc-build PASS`；rv64ua/uf/ud 三套件全 PASS，断言误报=0。

## 下一步（未做，排在最小起步之后）

按 [38]/`architecture-first.md`：flush「谁清谁保持」表逐源填实、评估 flush/redirect 单点仲裁器局部重写、补 per-bug 耗时数据把"慢是方法还是复杂度"从假说变定量。均排在本周两件之后。
