# Dispatch Log

## 基本信息

- `task_id`: `2026-04-13-rv32i-nonpipe-core`
- `task_slug`: `rv32i-nonpipe-core`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-04-13 00:00] `study-recall` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `收到用户关于 RV32I 非流水线核心设计与子 agent 协作的请求`
- `depends_on`: `无`
- `inputs`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`.github/memory/modules/agent-system.md`、`.github/agentic-hardware-blueprint.md`、`npc/single/design/study/README.md`、专题 study 笔记
- `action`: `按协议读取记忆、蓝图、NPC 学习资料，提炼本轮实现约束`
- `outputs`: `实现目标收敛为“单在途多周期 + 统一控制包 + 明确访存/提交/trap 边界”`
- `evidence`: `已读取对应文件并形成实现计划`
- `handoff_to`: `survey-existing`
- `next_step`: `盘点 npc/single 现有工程骨架`
- `notes`: `确认 npc/single 任务必须走 study-first 流程`

### [2026-04-13 00:10] `survey-existing` - `completed`

- `owner_agent`: `Explore`
- `trigger`: `需要确认当前工程可复用骨架与落点`
- `depends_on`: `study-recall`
- `inputs`: `npc/single/Makefile`、`csrc/main.cpp`、`vsrc/**`
- `action`: `只读盘点 npc/single 现状`
- `outputs`: `确认当前仅有 define.v 与 RegisterFile.v 占位骨架，没有顶层、译码、ALU、LSU、WBU 和仿真框架`
- `evidence`: `子 agent 返回目录和文件清单`
- `handoff_to`: `architecture-synthesis`
- `next_step`: `结合 study 笔记收敛模块边界`
- `notes`: `确认需要以新增 RTL 为主而不是在旧骨架上局部修补`

### [2026-04-13 00:20] `architecture-synthesis` - `completed`

- `owner_agent`: `npc`
- `trigger`: `需要在编码前确认更接近商业实现的非流水线架构形状`
- `depends_on`: `survey-existing`
- `inputs`: `study/README.md`、`RV32I-ai-notes.md`、`RV32I-implementation-checklist.md`、功能仿真与硬件架构笔记
- `action`: `让 npc 子 agent 给出架构建议与工程化取舍`
- `outputs`: `决定采用单在途多周期状态机、统一控制包、WBU 唯一提交点、LSU 收口访存语义`
- `evidence`: `子 agent 返回模块边界、控制包分层和后续优先级`
- `handoff_to`: `rtl-implement`
- `next_step`: `在 vsrc 中落 RTL`
- `notes`: `同时确认当前 trap 可先停机，后续再升级到 CSR/mtvec 闭环`

### [2026-04-13 00:40] `rtl-implement` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `架构边界已明确`
- `depends_on`: `architecture-synthesis`
- `inputs`: `study 结论`、`npc/single/vsrc/define.v`、`npc/single/vsrc/RegisterFile.v`
- `action`: `重写 define.v / RegisterFile.v，并新增 ImmGen / DecodeUnit / ALU / CompareUnit / LSU / WBU / NpcCore`
- `outputs`: `一版可综合的 RV32I 非流水线核心 RTL`
- `evidence`: `npc/single/vsrc 下 9 个 RTL 文件已存在`
- `handoff_to`: `lint-validate`
- `next_step`: `执行静态检查和 Verilator lint`
- `notes`: `顶层暴露 IFU/LSU 握手口、commit 口和 trap 停机口`

### [2026-04-13 01:00] `lint-validate` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `RTL 初稿完成`
- `depends_on`: `rtl-implement`
- `inputs`: `npc/single/vsrc/*.v`
- `action`: `运行 get_errors 与 verilator --lint-only -Wall，并修复 LSU 语法与 unused 控制位问题`
- `outputs`: `无错误的 RTL`
- `evidence`: `get_errors 返回 No errors found；Verilator lint 通过`
- `handoff_to`: `review-and-record`
- `next_step`: `让 npc 子 agent 做一轮结构审查并更新记忆`
- `notes`: `中途修正了 Verilog-2001 不支持的表达式切片写法`

### [2026-04-13 01:10] `review-and-record` - `completed`

- `owner_agent`: `npc` + `GitHub Copilot`
- `trigger`: `静态检查已通过，需要确认残余风险并固化记录`
- `depends_on`: `lint-validate`
- `inputs`: `npc/single/vsrc/*.v`、`.github/memory/*.md`
- `action`: `让 npc 子 agent 做只读审查，并补 task-run、project-status、npc 模块记忆、设计决策`
- `outputs`: `残余风险清单与持久化记录`
- `evidence`: `子 agent 指出 trap halt-only 与总线契约较窄；相关信息已写入 task-run 和 memory`
- `handoff_to`: `无`
- `next_step`: `等待用户决定是否继续做 CSR/trap/testbench`
- `notes`: `本轮实现已经具备后续演进到 CSR / difftest 的边界条件`

### [2026-04-13 01:20] `exit-protocol` - `completed`

- `owner_agent`: `GitHub Copilot`
- `trigger`: `用户要求 CPU 能通过 ecall/ebreak 优雅退出程序`
- `depends_on`: `review-and-record`
- `inputs`: `NpcCore.v`、`RegisterFile.v`、`define.v`、functional-sim 笔记中关于 ECALL/EBREAK 的约定`
- `action`: `将 ecall/ebreak 从普通 trap 卡死改为显式 EEI 退出协议：新增 HALT 状态、exit_valid/exit_is_ecall/exit_is_ebreak/exit_code 输出，并导出 a0 作为退出码`
- `outputs`: `可区分主动退出与异常停机的核心接口`
- `evidence`: `get_errors 通过；Verilator lint 通过`
- `handoff_to`: `无`
- `next_step`: `可继续接 testbench 或最小 pmem，直接消费 exit 信号做仿真退出`
- `notes`: `当前普通异常仍停在 TRAP，ecall/ebreak 单独走 HALT 结束协议`
