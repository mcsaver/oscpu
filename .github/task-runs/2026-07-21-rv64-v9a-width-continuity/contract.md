# V9A DI-2 全流水级双宽连续性合同

## 0. 工程边界

工作对象是授权工作区内的本地 RV64 Verilog/SystemVerilog 乱序处理器；操作范围仅含本地 RTL、spec、testbench、EDA 仿真工具与生成证据。不涉及网络主机、账号、凭据、第三方服务或未授权系统。本文中的流水线取消、恢复、验证变异等词均只表示本地处理器 RTL 信号、事务和 testbench 行为；措辞用于准确描述硬件工程语义，不改变任何平台审查规则。

本切片只关闭 `rv64-architecture-ppa-contract.md` 的 **DI-2 width continuity**。它不改变生产 RTL 的功能合同；若定向测试证明真实 RTL 无法达到本合同，必须先把根因、holder/owner 和接口变化写入本合同及相关 spec，再修改生产 RTL。任何本轮综合或时序观察只能是 diagnostic，`promotion_eligible=false`。

## 1. 成功条件冻结

同一个完整生产 RTL source-set SHA 下，使用无访存、无控制流、无异常、所有整数源均为 `x0`、目的寄存器非零且周期轮换的 RV64I `ADDI` 指令流。该指令流没有 RAW 依赖；重复架构目的寄存器由 rename 消除 WAW，不构成执行数据依赖。

以 reset 释放后的**第一个 `fetch_req_valid && fetch_req_ready` 上升沿**为唯一锚点；从该沿之后固定推进 `WARMUP_CYCLES=24` 个完整处理器周期，不等待任何内部“已饱和”条件，也不搜索后续窗口。随后采样连续 64 个固定周期。assert/release 使用同一锚点、同一周期编号和同一 start/end。以下七个语义边界各周期最多计两条不同事务，且必须满足：

- `peak_uops_per_cycle = 2`；
- `total_uops = 128`；
- `dual_uop_cycles = 64`；
- 退休总数为 128，`independent_alu_ipc = 2.000`；
- assert 与 release 两种编译配置结果一致；
- PC、instruction payload 和 full ProducerId 生命周期账本无遗漏、串 lane、active PID 重用或跨代混淆；已退休 PID 后续可被合法复用，但新 allocation instance 必须绑定新的 PC 和生命周期；
- 采样前后无 redirect、trap、stop、memory request 或外部副作用；
- 停止新 fetch 后，request/response/FIFO/ROB/IQ/EX holder 全部排空，free-list 回到 32。

架构 hard gate 仍按规范下限检查 `trace_cycles>=64`、IPC `>=1.90` 和每级总数 `ceil(1.90*trace)..2*trace`；focused test 使用上面的精确 2.000 条件，防止临界值四舍五入或空覆盖。

## 2. 七级事件与单一真源

| 边界 | 真实事件 | 身份真源 | semantic owner / sink |
| --- | --- | --- | --- |
| fetch | `OooFrontend.fetch_rsp_enqueue_w` 接纳一个双槽 packet | `fetch_dec0_pc_w/fetch_dec1_pc_w` 与两条非空指令 | `OooFetchPacketFifo` enqueue |
| decode | `fifo_pop_w` 使双槽 head 被 DecodeStage 消费 | `fifo_head_pc0_w/fifo_head_pc1_w` | `OooAluDecodeBackend` 两个 `DecodeStage` |
| rename | `backend_dispatchN_valid_w && backend_dispatchN_ready_w`，且 `OooRenameMap.renameN_valid_i` 为 1；下一沿对应非零 new pdest 成为该 rd 的 map owner | lane PC、`{inst,rd,imm}`、new pdest | `OooRenameMap` / `OooFreeList` |
| dispatch | parent `OooDispatchBackend.dispatchN_fire_w`、`OooRob.dispatchN_fire_w` 与 `OooIntIssueQueue.dispatchN_fire_w` 三者同拍一致；任一 sink 未接纳都不计 | ROB 分配的 full ProducerId、PC 与完整 payload | `OooRob` + `OooIntIssueQueue` 两个独立 sink |
| issue | `OooIntBackend.issueN_fire_w`（lane1 为普通整数执行 fire） | IQ 保存的 full ProducerId 与 PC | Universal/ALU physical terminal |
| execute | `executeN_valid_o`（普通 ALU 流等于授权 `wbN_valid_w`）从显式 EX→WB stage 产生 formal result_event | `wbN_producer_id_w`、result data；并要求前一沿 `exN_up_valid_w`/PID 与 stage capture 一致 | `PipeStageReg u_exN_stage` 的 down side / WB authorization |
| retire | `commitN_valid_o` | `rob_commitN_producer_id_w` 与 commit PC | `OooRob` in-order commit |

当前 decode→rename→dispatch 没有新增寄存级，是同一拍的组合支持性、rename/allocate 与 ROB/IQ 接纳链。本合同分别观察三个既有语义 owner，不把它们虚构为三拍，也不把同一个 packet valid 重复当作不同事务。

## 3. 六类接口合同

### 3.1 握手

- 只计 `valid && ready` 或规范定义的 actual completion/commit fire；裸 `valid` 不计吞吐。
- 一个 fetch packet 只在两个槽都为合法 32-bit `ADDI` 时贡献两个 uop；两槽 PC、instruction、rd 和 immediate 必须不同。
- dispatch lane1 必须与 lane0 同拍接纳；issue physical terminal 编号不替代程序年龄。
- 每个 counted dispatch 必须同时得到 ROB 和 IQ 独立 sink fire；每个 counted execute 必须得到 EX stage capture 与下一拍授权 WB 的 PID/payload 对账。
- 每个 EX0/EX1 capture 必须在 testbench-only previous-cycle ledger 中保存 full ProducerId 与全部寄存 payload 字段（`pdest/result/exception/cause/tval/fwd`）；下一拍必须在 `PipeStageReg` down side 逐 lane 完整复现，之后才允许计入 WB。

### 3.2 stall / backpressure

- 固定 24 周期预热后的 64 周期窗口内，任一级出现小于两条 actual event 都使 focused test RED；不得基于 ready、retire 或“全级双宽”条件移动窗口。
- 采样结束只关闭外部 fetch request admission；已接纳 response 和内部 holder 必须自然 drain，不能用 flush 清空来制造守恒。

### 3.3 flush / redirect / recovery

- 测量指令流无控制流；窗口内任何 redirect、frontend flush、backend recovery、trap 或 stop 都是失败。
- 本切片不改变既有 branch selective recovery、已 fire AXI drain 或 committed store 规则。

### 3.4 exception / privilege

- 指令全部是当前特权态合法 RV64I `ADDI`；fetch response 为 OK，无 illegal、access fault、page fault 或 CSR/system 指令。
- 任一 commit exception、trap 或 exit 使测试失败。

### 3.5 memory ordering / side effect

- 指令流不包含 load/store/AMO/FP-memory；测量及 drain 期间 `mem_req_valid` 必须为 0。
- 因此本切片不提升 OOO-3/DI-5，也不重新解释现有 LQ/SQ/双 memory owner 证据。

### 3.6 source of truth / holder

- dispatch 前以 PC 和 instruction bits 标识事务；ROB 分配后以 full ProducerId 为唯一跨 IQ/EX/commit 身份。scoreboard 同时保存由 PC 派生的 `{inst,rd,imm,expected_data}`，并在 decode、rename、dispatch、issue、execute、commit 逐级核对，不能只核数量和 PID。
- raw ROB index 不能替代 ProducerId；testbench 账本必须覆盖 generation 位并核对 PC。
- full ProducerId 允许在旧 allocation 已退休并清除 active ledger 后复用；复用前若仍有 active owner、旧 completion 或 payload 不匹配，立即失败。生命周期状态固定为 `allocated -> issued -> executed -> retired`，每次转换必须存在、按序且 exactly-once。
- 每个边界只由表中 owner 贡献事件；monitor 不 force 生产 RTL 信号，不修改设计状态。

## 4. 验证与证据合同

1. `tb_ooo_core_top_glue_v9a_width_continuity` 在 release 和 `OOO_ASSERT` 下各运行一次，输出唯一 metric、identity、drain marker，并输出 64 行 canonical cycle trace；evidence builder 比较两种配置逐周期 `{boundary widths,PC,PID}` trace digest，而不只比较汇总计数。
2. compile-success RTL verification mutations 至少逐项切断/破坏 fetch identity、decode lane1、RenameMap lane1 sink、ROB lane1 sink、IQ lane1 sink、issue lane1、EX1 capture、EX1 registered payload、WB sink、commit1 retirement与 lane1 immediate payload，并由对应 focused oracle 拒绝。特别要求：保留 parent dispatch fire 但切断 IQ sink 的变异必须 RED；把 EX1 stage payload 改接 EX0 payload、或把 lane1 immediate 改接 lane0 payload 的变异也必须 RED。
3. 每个 mutation 必须满足：旧锚点唯一、mutant bytes 与原文件不同、编译成功、仿真非零、出现明确硬件 witness、生产源文件前后 SHA 集合相同。
4. evidence builder 必须拒绝重复 marker、非有限/错误 metric、缺失边界、mutation 集合漂移、stale hash、错误命令、错误 suite id 和不同 design_id。
5. 修改 architecture checker 后，DI-1/DI-3/DI-4/DI-5/OOO-1/OOO-2/OOO-3/OOO-4 必须在同一 design_id 下重建 sibling records；最终架构结果只在九门全部 GREEN 时为 GREEN。
6. 永久入口冻结为 `make -C npc/rv64 check-width-continuity`。
7. 另编译 `V9A_WIDTH_WINDOW_STALL_PROBE`：只在固定测量第 17 拍拉低 testbench 的 `fetch_req_admit` 一拍，baseline monitor 必须在原窗口 RED；禁止等待或滑动到后续干净窗口。
8. drain 控制固定为仅令 `fetch_req_admit=0`；`run=1`、`commit_ready=1`、response 接纳保持开启。drain 每拍继续禁止 flush/redirect/trap/stop/memory request，最终显式检查 pending response、outstanding、FIFO、ROB、IQ、EX0/EX1 stage、free-list 与 active ledger。

## 5. 允许修改范围

- `.github/task-runs/2026-07-21-rv64-v9a-width-continuity/**`
- `npc/rv64/Makefile`
- `npc/rv64/testbench/Makefile`
- `npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv`
- `npc/rv64/eval/ppa/tools/architecture_hard_gates.py`
- `npc/rv64/eval/ppa/tools/width_continuity_evidence.py`
- `npc/rv64/eval/ppa/tests/test_architecture_hard_gates.py`
- `npc/rv64/eval/ppa/tests/test_width_continuity_evidence.py`
- `npc/rv64/design/arch/rv64-architecture-ppa-contract.md` 与相关模块 spec 的证据入口说明
- 收尾所需 `.github/memory/**`、task-run 索引与数据库生成物

生产 `npc/rv64/vsrc/**` 默认只读。若 focused baseline 不能达到成功条件，停止证据发布，先形成 root-cause amendment 后再扩大写范围。

## 6. 声明边界

DI-2 GREEN 只说明本 design_id 的独立整数 ALU 流在七个既有语义边界具备连续双宽。它不单独证明 workload IPC、Linux、PPA、200 MHz、Power 或物理实现；在 full architecture result 与后续 arch-stable freeze 完成前，PPA 仍为 `UNQUALIFIED`。
