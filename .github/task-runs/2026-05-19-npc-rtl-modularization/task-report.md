# NPC RTL 模块化任务报告

## 目标

把 `cache/bpu` 等相关功能从大模块里拆出独立 RTL 源文件，并把可综合 RTL core 与含 DPI-C 的仿真顶层显式区分，提升查阅、理解、迭代和后续 PPA 优化的可控性。

## RTL 四阶段推导

### 需求

- 保持现有 RV32IMC + Zba/Zbb/Zbc/Zbs、`fence.i`、BPU、difftest 行为不变。
- 降低 `IfStage.v` 的职责密度，让 BPU 可独立阅读和后续替换。
- 将 `fence.i` 到 cache flush 的语义抽成 RTL 边界，但不伪装成已实现 RTL cache。
- Makefile 中显式区分纯 RTL 核心源与 DPI-C 仿真顶层源，避免综合入口污染。

### 协议 / 状态

- `BranchPredictor` 预测接口：输入已解压的 `predict_inst_i`、`predict_pc_i`、`predict_seq_pc_i`，输出 `predict_next_pc_o`。
- `BranchPredictor` 更新接口：只由 EX 阶段未异常控制流指令驱动，输入真实 `update_next_pc_i` 和 `update_taken_i`，同步更新 BTB/BHT/RAS。
- `CacheControl` 接口：只在 `ex_fire_i && fence_i_i && !exception_i` 时产生 `flush_valid_o`，redirect PC 为该指令顺序 PC。
- `NpcSimTop` 保持一拍 DPI 总线模型，只把 `fence_i_flush_o` 翻译成 `npc_cache_flush_all()`。

### 不变量

- EX 阶段仍是唯一真实控制流裁决点；BPU 只能预测，不提交架构状态。
- BPU 更新不能来自异常指令，错误路径不能提交。
- `fence.i` flush 事件必须同时清前端年轻级并通知仿真 cache；但当前 cache data/tag 仍在 host 模型。
- `NpcSimTop.sv` 不能进入 `RTL_CORE_SRCS/STA_RTL_FILES`。

### 数据通路

- `IfStage.v`：保留 fetch pending/buffer、RVC 解压、IFU request/response 接口。
- `BranchPredictor.v`：收口 BTB/BHT/RAS、JAL/JALR/RAS hint 解析和预测 next PC。
- `NpcCore.v`：收口异常、分支、mret、`fence.i` 的 flush/redirect 仲裁。
- `CacheControl.v`：收口 `fence.i` 对前端与仿真 cache 的同步事件。
- `NpcSimTop.sv`：只负责 DPI-C ifetch/load/store/cache flush 桥接。

## 改动摘要

- 新增 `npc/single/vsrc/BranchPredictor.v`：从 `IfStage.v` 抽出 128-entry BTB、256-entry BHT、16-entry RAS。
- 新增 `npc/single/vsrc/CacheControl.v`：抽出 `fence.i` flush/redirect 事件生成。
- 更新 `npc/single/vsrc/IfStage.v`：移除内联 BPU 表项和更新逻辑，实例化 `BranchPredictor`。
- 更新 `npc/single/vsrc/NpcCore.v`：实例化 `CacheControl`，用其输出参与 flush/redirect 仲裁和 `fence_i_flush_o`。
- 更新 `npc/single/vsrc/NpcSimTop.sv`：标注 DPI-C 仿真顶层，重命名本地 flush 线为 `sim_cache_flush_w`。
- 更新 `npc/single/Makefile`：新增 `RTL_CORE_TOP`、`SIM_TOP`、`RTL_HEADER_SRCS`、`RTL_CORE_SRCS`、`SIM_TOP_SRCS`，`STA_RTL_FILES` 默认只取纯 RTL core 源。
- 更新 `npc/single/README.md`：补充模块边界和综合源集合说明。

## 验证

- `make -C npc/single lint`: PASS。
- `make -C npc/single`: PASS。
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL='add if-else bitmanip compressed fence-i' run NPC_RUN_ARGS='--diff=default -m 0'`: 5/5 PASS。
- `timeout 300s make -C am-kernels/benchmarks/dhrystone ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0'`: PASS，`Dhrystone PASS 4 Marks`，`commits=230018888`，`CPI=2.039`。
- `timeout 120s make -C am-kernels/benchmarks/microbench ARCH=riscv32-npc mainargs=test run NPC_RUN_ARGS='-m 0'`: PASS，10/10 子项通过，`commits=522702`，`CPI=2.128`。
- `timeout 300s make -C am-kernels/benchmarks/coremark ARCH=riscv32-npc run NPC_RUN_ARGS='-m 0'`: 外层 timeout，退出前稳定推进到 `310000000` insts，未出现功能报错。
- `timeout 180s make -C npc/single syn`: 未执行综合，环境检查失败：缺 `/home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/yosys`。

## 边界说明

- 本轮是结构重构，不是新增硬件 cache。`CacheControl.v` 只是可综合的 `fence.i` 同步事件边界；真实 cache tag/data 仍在 Verilator host bus 模型。
- CoreMark 默认 1000 iterations 在当前仿真速度下需要更长 timeout；本轮已有 Dhrystone 默认规模和 MicroBench `test` 明确 PASS，CoreMark 只作为长跑稳定性观察。
