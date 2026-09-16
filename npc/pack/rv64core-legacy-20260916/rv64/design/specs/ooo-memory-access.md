# OooMemoryAccess 子系统 wrapper Spec

## 1. 目标

`OooCoreTopGlue` 历史上把 ~80 个职责 owner 扁平例化在同一层，违背"目录即架构边界"。
本 spec 固化子系统 wrapper 分层战线的第一刀：把 `memory/` 目录下供 core 数据访问用的
两个 owner 聚合到一个子系统 wrapper `memory/OooMemoryAccess.v`，让 `OooCoreTopGlue`
只对 memory 子系统做一次实例化，而不是逐个例化其内部 owner。

本刀是**纯结构聚合**：不新增任何组合或时序逻辑，不改变任何 owner 的行为；只是把
原先在 glue 顶层逐实例例化的两个 owner 下沉到 wrapper 内部，并把跨子系统边界的信号
导出为 wrapper 端口。

## 2. 责任边界

| 内部 owner | 目录 | 职责（2026-07-03 现状） |
| --- | --- | --- |
| `OooMemoryRequestGate` | `memory/` | 已退化为纯透传：core mem 请求 9 路 assign 直通（含 probe/pretrans/nokill），仅聚合 `mem_flush`（core-local‖checkpoint）与 `mmu_flush`（satp 写‖sfence commit）两根 OR；pending-FP 直写旁路与 mem1 双口均已拆除 |
| ~~`OooPendingMemorySequencer`~~ **已 B4 物理删除（2026-07-04, b2918073a）** | ~~lane1 memory barrier 的 pending memory 单 entry 注册状态~~ capture 恒 0（lane1 barrier 与 FACT_MEM 严格互斥，从未可达）→整链删除；跨模块死信号已在 TopGlue/ControlPlane 常量0 tie-off。spec 归档 `history/ooo-pending-memory-sequencer.md` |

wrapper 自身不持有任何 `always`、`assign` 或新 wire 逻辑，按原顺序例化两个 owner
（原内部信号 `pending_fp_mem_req_valid_w` 已随 pending-FP 直写旁路拆除而消失，现无内部 wire）。

## 3. 接口与不变量

- wrapper 端口 = 原两个 owner 与 glue 其余部分之间跨边界的全部信号（抽取时 60 个；FP/mem1
  信号拆除、probe/pretrans/nokill 加入后现为 45 个），
  方向由"谁驱动"决定：owner 输出且被 glue 其余部分消费 → wrapper 输出；glue 其余部分
  或顶层输入驱动且被 owner 消费 → wrapper 输入。
- glue 顶层 wire 名保持不变：`mem_req_*_o/mem_flush_o/mmu_flush_o`（mem1 双口已删）等顶层
  输出端口由 wrapper 输出直接驱动；`pending_mem_q/pending_mem_dispatched_q/
  pending_mem_pc_q/pending_mem_inst_q/pending_mem_next_pc_q` 等 pending memory 状态
  仍以同名 glue 顶层 wire 形式存在（wrapper 输出 → glue wire），保证现有 testbench 探针
  `dut.u_ooo_core.pending_mem_q` 等层级不失效。
- wrapper 无参数：两个 memory owner 不使用 `OOO_*` 结构参数，故 wrapper 不声明、glue
  实例化也不透传参数（避免 Verilator `UNUSEDPARAM` 报错）。
- `OooPendingMemorySequencer` 的 `rst` 仍接 `rst || flush_i`，保持原 reset/flush 语义。

## 4. 验证

- `make -C npc/rv64 lint`（Verilator `-Wall`，warning 即 error）PASS。
- `make -C npc/rv64 -j2` build PASS。
- 默认 module testbench 103/103 PASS（含探针深入 glue 内部的 `tb_ooo_core_top_glue`、
  `tb_ooo_fetch_trap_gate`、`tb_ooo_priv_system`、`tb_ooo_sv39_boot`）。
- official riscv-tests（default + A + FP + privileged）回归 PASS。

## 5. 边界

本刀只完成 memory 子系统 wrapper 抽取；`control/`、`execute/`、`writeback/`、
`frontend/` 子系统 wrapper 仍待后续切片。本刀不改变 LSU/MMU 协议、pending owner 状态机、
trap/redirect 语义或 precise recovery，也不代表 `OooFpPendingExec`/`OooIntBackend`
巨石拆分或完整工业 CPU sign-off。
