# NPC 控制/数据通路分离任务报告

## 摘要

本轮先做低风险的第一阶段模块化：把 `NpcCore.v` 中流水线控制仲裁抽成纯组合 `PipelineControl.v`，数据通路、CSR 状态、forward mux、ALU/LSU/WBU/cache 连接保持在 `NpcCore` 内。这样先稳定“控制面边界”，后续再逐步拆 `ExecuteDatapath`、`CsrBlock` 或更完整的 core datapath。

## RTL 推导摘要

- 需求：控制模块只管理 `stall/flush/fire/redirect/load-use/mem-wb source/bpu update`，不承载数据计算。
- 协议：沿用现有 valid/ready 与流水寄存器 `clear/load/kill/leave` 协议；`ex_fire` 是 EX 阶段唯一执行裁决点。
- 状态机：本轮不新增时序状态，`PipelineControl` 为纯组合模块，状态仍由 `IfStage`、`PipelineRegs`、`MemoryStage`、CSR/停机寄存器持有。
- 不变量：flush 阻断正常推进；load-use hazard 阻止 ID 接收；mem fault 优先于年轻级推进；redirect 优先级保持 `mem fault -> exception -> mret -> cache flush -> branch/control`；halt/fatal 后不再 `ex_fire`。
- 数据通路：ALU/Compare/LSU/WBU/CSR/cache/forward mux 不移动，只消费 `PipelineControl` 输出。

## 改动

- 新增 `npc/single/vsrc/PipelineControl.v`
  - 收口 load-use、EX fire、异常/redirect、flush、IF refill、EX/MEM leave/load、MEM/WB load 选择和 BPU update valid。
- 更新 `npc/single/vsrc/NpcCore.v`
  - 删除原地控制组合方程，实例化 `PipelineControl`。
  - `IfStage` 的 BPU update valid 改为使用控制模块输出。
- 更新 `npc/single/Makefile`
  - 将 `PipelineControl.v` 加入 `RTL_CORE_SRCS`，同步纳入仿真和纯 RTL 综合文件集合。

## 验证

- `make -C npc/single lint`: PASS
- `make -C npc/single`: PASS
- `timeout 300s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc run NPC_RUN_ARGS='--diff=default -m 0'`: 38/38 PASS
- `timeout 120s make -C am-kernels/benchmarks/microbench ARCH=riscv32-npc mainargs=test CROSS_COMPILE=/home/lyg/riscv-toolchain/riscv/bin/riscv64-unknown-elf- run NPC_RUN_ARGS='--diff=default -m 0'`: PASS

## 后续

- 下一步适合拆 `ExecuteDatapath`：把 ALU/Compare/RV32M/RV32B/WBU 输入选择收口，进一步降低 `NpcCore.v` 数据面长度。
- 再后续拆 `CsrBlock/TrapControl`：把 CSR 读改写、trap 进入和 mret mstatus 规则从 core 顶层移出。
