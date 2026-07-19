# OooCoreTopGlue 边界 Spec

## 目标

历史上的 ALU/fetch 巨石已经被持续拆分为 `frontend/`、`control/`、
`execute/`、`memory/`、`writeback/` 和 `regread_bypass/` 下的独立 owner。
本 spec 固化当前终态切片：`core/OooCoreTopGlue.v` 只作为 core 级装配壳存在，
不再放在 `frontend/`，也不再用历史巨石名承载功能语义；状态 owner 可以继续上提到
`core/NpcCoreTop.v`，让顶层按目录边界直接例化。

## 责任边界

| 分类 | 目标目录 | 当前 owner | 拆分状态 |
| --- | --- | --- | --- |
| PC/预测/取指 request-response | `frontend/` | fetch request/flow/FIFO/PC/prefetch helper；`OooBranchPrefetchRequestGate` 承接 prefetch request fire | 已拆为 helper，由 core glue 实例化 |
| RAS/return continuation/branch target capture | `frontend/` | `OooDirectControlFlowGate`、RAS/return-cont/branch target capture helper | 已拆 |
| predictor update 事件 | `frontend/` | `OooPredictorUpdateGate`、BPU/BTB/cache update helper | 已拆 |
| CSR/privilege/PMP 状态 | `core/` 状态实现 + `control/` 事件 mux | `NpcCoreTop` 直接例化 `CsrFile`；`OooCoreTopGlue` 只导出 CSR access/trap/fflags/retire 事件并消费 CSR 状态 | CSR 状态 owner 已从 glue 上提 |
| 基础 decode/RVC/FP decode | `decode/` | 独立 helper | 已拆 |
| rename/dispatch/ROB/IQ/PRF/backend | 对应外层目录 | `OooAluCoreSlice` 及子模块 | 已拆为执行核心切片 |
| FP 执行数据通路 | `execute/` | FP 真乱序簇（`OooFpBackend`/`OooFpArithGate` 等，经 `OooAluCoreSlice` 子树）；旧 `OooFpPendingExec`/`OooPendingFpSequencer` 已随 pending-FP 拆除删除 | 已迁域 A |
| FPR 状态/读写 | `regread_bypass/`（模块源） | `OooFpRegFile` 已随 FP 迁域 A 移入 execute/ FP 簇内例化（`OooIntBackend`→`OooFpBackend` 的 `u_arch_fpr`）；glue 与 `NpcCoreTop` 均不再持有 FPR 状态 | FPR 状态 owner 已下沉到 FP 簇 |
| pending/drain/CSR/trap/flush/recovery | `control/` + `frontend/` helper | pending/control sequencer 与 mux；`OooPendingDrainResolveGate` 承接 drain/resolve 中枢；`OooCsrIllegalProbeGate` 承接 CSR illegal lane probe；`OooCoreSliceControlGate` 承接 core slice 准入 | 已拆为 helper，由 core glue 接线 |
| FP commit/GPR-FPR/fflags 修饰 | `writeback/` | `OooFpCommitGate` 已随 FP 迁域 A 删除（FP 经 ROB 真 commit，fflags/dirty commit 聚合降为 glue 级连续赋值） | 已删除 |
| writeback/commit 修饰 | `writeback/` | commit/control/synthetic sequencer 与 mux；`OooSyntheticLane1RetCommitGate` 承接 synthetic lane1 return commit/drop 判定 | 已拆为 helper，由 core glue 接线 |
| pending operand read | `regread_bypass/` | `OooPendingOperandReadGate` | 已拆 |
| 对外 trap/debug/CSR 观测输出 | `control/` | `OooCoreObservableOutputGate` | 已拆 |

## 关键不变量

- `OooCoreTopGlue` 不包含 `always` 状态块；新增功能状态必须落到职责目录的
  sequencer/register owner 中。
- T3Z active fetch-owner PC 由 `NpcCoreTop.u_ooo_fetch_bridge` 持有，Glue 只做
  `NpcCoreTop -> OooFrontend` 端口透传；不得在 Glue 或 Frontend 再造 64-bit owner 状态。
- `OooCoreTopGlue` 可以保留跨子系统 wire、实例参数和端口转接；顶层只保留少量
  聚合级连续赋值（当前 4 个 `assign`：`csr_cycle_count_enable_w` 与 FP
  fflags/dirty commit 聚合，另有 `dispatch0_facts_w` packing 等 `wire =` 赋值），
  不能写 pending/drain 规则、redirect 规则或 fetch packet 规则。
- `OooCoreTopGlue` 不再实例化 `CsrFile`；CSR/privilege/PMP 状态由 `NpcCoreTop`
  直接例化的 `CsrFile` 持有，core glue 只能通过边界端口产生精确 CSR 事件并消费
  CSR 状态。
- `OooCoreTopGlue` 不再实例化 `OooFpRegFile`；FPR 状态随 FP 迁域 A 由 execute/ FP 簇
  （`OooFpBackend` 内 `u_arch_fpr`）持有，glue 与 `NpcCoreTop` 均不再接触 FPR 读写散线
  （pending-FP 通道已拆除）。
- direct JAL/return、predictor update、CSR illegal lane 归属、synthetic lane1 retire
  和 core slice commit/flush 准入都必须由职责目录 owner 输出，不能在 core glue
  重新拼布尔公式。
- IFU fetch fault 的 xEPC 与 xTVAL 是两条独立 payload：frontend 提供 slot PC
  与 packet-level `head_fetch_fault_tval_w`，glue 只把二者透传到 control plane；
  禁止在装配层把 xTVAL alias 为 `head_pc_w/head_pc1_w`。
- 子模块不得绕过 core glue 直接提交架构事件；commit/trap/exit 输出仍通过既有
  writeback/control mux 和 sequencer 形成。
- 后续新增 helper 必须有同名源文件、filelist 条目和 focused 或父模块回归覆盖。

## 子系统 wrapper 分层（已落地）

`OooCoreTopGlue` 不再扁平例化 ~80 个 owner，而是按"目录即架构边界"聚合为 5 个
子系统 wrapper + 1 个共享叶子：

| glue 实例 | wrapper / 模块 | 聚合目录 | spec |
| --- | --- | --- | --- |
| `u_frontend` | `OooFrontend` | `frontend/`(49) + `decode/` DecodeStage(6) | [`history/ooo-frontend.md`](./history/ooo-frontend.md)(已归档;现状见 `vsrc/frontend/OooFrontend.v`) |
| `u_control_plane` | `OooControlPlane` | `control/`(13) | [`ooo-control-plane.md`](./ooo-control-plane.md) |
| `u_execute_backend` | `OooExecuteBackend` | `execute/`(2：`OooAluCoreSlice`+`CompareUnit`，FP pending 壳拆除后) | [`ooo-execute-backend.md`](./ooo-execute-backend.md) |
| `u_writeback` | `OooWriteback` | `writeback/`(4，`OooFpCommitGate` 删除后) | [`ooo-writeback.md`](./ooo-writeback.md) |
| `u_memory_access` | `OooMemoryAccess` | `memory/`(2) | [`ooo-memory-access.md`](./ooo-memory-access.md) |
| `u_pending_operand_read_gate` | `OooPendingOperandReadGate` | `regread_bypass/`(1) | 单模块叶子，无需独立 wrapper |

wrapper 抽取为纯结构变换：每个 wrapper 只把跨边界信号导出为端口、把仅内部使用的
信号下沉为内部 wire，不新增任何组合/时序逻辑。统一不变量：

- glue 顶层 wire 名保持不变（成为 wrapper 端口连线），保证 `dut.<sig>` /
  `u_ooo_core.<sig>` testbench 与 `NpcSimTop` trace 探针不失效；只有深入被移动实例
  内部的探针（`tb_ooo_fetch_trap_gate` 的 `u_branch_resolve_recovery_gate` /
  `u_direct_branch_resolve_gate`）需加 `u_frontend.` 前缀。
- glue 级 `wire X = <expr>;` 连续赋值（如 unused 聚合、`dispatch0_facts_w` packing）
  保留在 glue 顶层；其驱动的信号按声明位宽作为 wrapper 输入/输出，不可截断。
- wrapper 只声明实际被内部实例使用的结构参数/ localparam，避免 Verilator UNUSEDPARAM。
- wrapper 实例插在 glue `endmodule` 之前，满足 iverilog "先声明后使用"，避免多位信号
  被隐式 1-bit 网截断。

经此分层，`OooCoreTopGlue` 降为 6 个实例、约 1.4k 行（原约 3.5k 行）、0 个 `always`。

## 后续边界

- 若继续推进 bus 化，应优先把 fetch packet、pending owner 和 commit event 的
  结构化定义落到 `common/`，再逐步替换散线。
- 单模块叶子 `OooPendingOperandReadGate` 可在后续 regread/bypass 子系统成形时并入；
  当前单实例独立 wrapper 无收益。
- `OooIntBackend` 巨石的内部拆分仍是独立战线，不属于本 wrapper 分层范围
  （`OooFpPendingExec` 已随 FP 迁域 A 删除）。

## S2-Q2 v8a neutral shadow 装配边界

`NpcCoreTop` 产生 `head0_context_shadow_permit_w=1'b1` 与
`fencei_shadow_permit_w=1'b1`，经 `u_ooo_core` 和 execute 子树逐级传到 ROB；ROB 的
`head0_retire_candidate_valid_o/head0_identity_valid_o/head0_identity_o` 沿同一路径返回。

- Glue 与六层 wrapper 只作同名端口映射，无新增状态、选择器或 writer；identity 全链固定
  ``[`OOO_CONTEXT_ID_W-1:0]``。
- 三个 observation 在 v8a 顶层只进入命名 unused sink/验证观测，不得成为 CSR/MMU/FENCE、
  commit、dispatch、flush 或 epoch 的 active consumer。
- 顶层 tie-high 是本切片行为等价的充分条件；未来激活 permit 必须先关闭 v8b 的 full identity、
  same-owner payload、FENCE.I transaction、Q1 abort 和 flush/live-head blocker，不能直接改常量。
- wrapper 无状态，故 reset/flush/kill 不新增保持规则；identity-valid 由 ROB live slot 单一真源回答。

## R4-S0 memory attribute 装配边界

`OooCoreTopGlue` 只透传 `mem_req_cacheable_o/mem_rsp_cacheable_i`，不得解释 PBMT、PMA、
VA/PA 范围或重算 cacheability。最终属性的 producer 是 `OooMemAxiBridge` 的 post-translation
分类点；owner 是 probe 后的 SQ entry；consumer 是 physical drain 与 B-terminal D-cache
维护。Glue 不拥有其中任何状态。

装配不变量：

- response 的 `{PA, cacheability, fault}` 必须属于同一 memory owner；fault response 不得把
  cacheability 写入 SQ；
- SQ drain 的 `{PA, cacheability}` 必须原样回到 bridge 的 `pretrans` request station；Glue
  不得以 live CSR/PTE 或地址范围覆盖；
- flush/restore 不得让属性从一个 ROB/SQ token 串到另一个 owner；已发 physical nokill store
  继续 drain，未发的 killed owner 按既有年龄规则清除；
- S0 Boolean 只为兼容迁移，NC/IO 合并且 memory datapath 仍单 owner。S1 typed ABI 和 S2
  双 memory owner 接入时，Glue 只能扩展同构 bundle/transport slot，不得以 lane 编号恢复
  静态角色或复制 lane0 payload 伪造双端口。
