# NPC 控制/数据通路分离派发记录

## RECALL

- 已读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`。
- 已读取 `.github/instructions/rtl-generation-workflow.instructions.md`、`.github/instructions/memory-protocol.instructions.md`。
- 已读取 `npc/single/design/study/README.md` 与硬件架构规范摘要。

## RTL 推导摘要

### 阶段 1：需求

- 功能目标：把 `NpcCore.v` 中流水线 stall/flush/fire/redirect/load-use/mem-wb load 选择等控制仲裁抽成独立纯组合模块，降低数据通路与控制面的耦合。
- 输入边界：控制模块只接收各流水级 valid、译码源寄存器使用情况、EX 原始异常条件、MEM response/fault、停止状态和 redirect PC 候选。
- 输出边界：输出 IF/ID/ID/EX/EX/MEM/MEM/WB 的 load/clear/consume 类控制信号，以及 EX fire、异常/redirect/cache flush 相关控制信号。
- 性能约束：本轮不新增时序状态，不改变流水级数和 cache miss 协议；组合路径保持与原 `NpcCore` 等价。
- Out-of-scope：不拆 CSR block、不拆 EXU 数据通路、不改 cache/BPU 行为、不新增性能优化。

### 阶段 2a：协议规则

- 流水协议仍是现有寄存器模块的 `clear/load/kill/leave` 固定时序接口。
- `ex_fire` 表示 ID/EX 指令在本拍被 EX 接收并可进入后续仲裁；异常、mret、branch redirect、ebreak 都必须基于同一拍 `ex_fire`。
- `mem_response` 表示 EX/MEM 中访存指令本拍完成；访存 fault 优先于正常流水推进。
- `flush` 清 IF/ID 和 IF outstanding/fetch buffer，redirect PC 按 `mem fault -> exception -> mret -> cache flush -> branch/control` 优先级选择。

### 阶段 2b：状态机

- 本轮不新增独立时序状态机；`PipelineControl` 是纯组合控制器。
- 受控状态仍位于既有 `IfStage`、`PipelineRegs`、`MemoryStage` 和 `NpcCore` CSR/停机寄存器中。
- 组合转移等价于原方程：`ex_mem_can_accept -> ex_fire -> exception/redirect -> normal_update -> 各流水寄存器 load/clear/leave`。

### 阶段 2c：不变量

- flush 优先级不变量：`mem_fault/ex_exception/ebreak` 发生时，正常流水推进必须被 `pipeline_normal_update=0` 阻断。
- load-use 不变量：ID/EX 为 load 且 IF/ID 消费同一 `rd` 时，`id_accept=0`。
- 访存 fault 不变量：`mem_fault=1` 时 EX/MEM 不再正常 leave/load，年轻级被清空或重定向。
- redirect 不变量：异常和 mret 的 redirect 优先级高于分支预测修正，cache flush redirect 高于普通 control redirect。
- 停机不变量：`halt/fatal` 置位后 `ex_fire=0`，不再产生新提交。

### 阶段 2d：数据通路骨架

- 数据通路保持在 `NpcCore`：forward mux、ALU/Compare/LSU/WBU、CSR 读改写、cache 连接和 pipeline payload 不移动。
- 控制模块只输出选择/使能/清空信号，不计算 ALU/CSR/load 数据。
- `NpcCore` 从“自己拼控制方程”改为“实例化 `PipelineControl` 并把输出接到原消费点”。
