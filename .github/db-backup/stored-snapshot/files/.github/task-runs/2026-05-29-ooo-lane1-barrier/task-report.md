# OoO lane1 半包精确屏障

## 目标

把 `NPC_OOO_ALU_EXPERIMENT=1` 实验核从“lane1 control/memory 直接 unsupported”推进到半包精确处理：当 fetch packet 的 lane0 是可进入后端的普通 uop，而 lane1 是分支、跳转、访存、`ebreak` 或取指异常时，先单发并提交 lane0，再按 lane1 的真实 PC 处理对应精确边界。

## RTL 四阶段记录

### 1. 需求

- 支持 packet lane1 的 `branch/JAL/JALR/load/store/ebreak/fetch fault` 精确边界。
- lane1 屏障不得吞掉或跳过同 packet 更老的 lane0 普通 uop。
- lane1 屏障处理时仍复用现有 lane0 pending branch/jump/memory/exit/trap 机制，避免新增并行提交语义。
- lane1 memory 仍以 drain barrier 方式单发，不实现真正 LSQ 或 lane1 后端 memory issue。
- lane1 非上述类型的 unsupported 指令暂不扩展，仍按当前实验核非法边界处理。

### 2. 协议/状态机/不变量

- 正常双发：lane0/lane1 都是后端支持 uop 时，维持原 2-wide dispatch。
- lane0 屏障：lane0 自身为 branch/jump/memory/ebreak/fetch fault 时，维持原先“不派发本 packet，先 drain 更老项”的协议。
- lane1 屏障：lane0 支持且 lane1 命中屏障时，只向后端派发 lane0，`dispatch1_valid=0`；lane0 fire 后弹出 fetch FIFO、冻结前端，并保存 lane1 PC/inst/译码元数据。
- drain 后处理：
  - lane1 branch：用已提交架构 GPR 计算方向，synthetic commit 分支本身，redirect 到 target 或 `pc+4`。
  - lane1 jump：用已提交架构 GPR 解析 target，单 lane 派发 jump uop，提交后 redirect。
  - lane1 memory：单 lane 派发 memory uop，提交后从 lane1 `pc+4` 继续取指。
  - lane1 ebreak/fetch fault：等待 lane0 与更老项 drain 后再 exit/trap。
- 不变量：
  - lane1 屏障最多派发一个 lane0 uop，且 lane1 不会同拍进入后端。
  - lane1 屏障只有在 lane0 fire 后才可弹出 FIFO、设置 pending 状态。
  - pending lane1 memory 的继续 PC 必须是 `lane1_pc + 4`，不同于 lane0 memory 的 `pc + 4`。
  - lane1 branch/jump 读取的架构 GPR 必须包含同 packet lane0 已提交结果。

### 3. 数据通路

- `OooAluFetchCore` 复用 head1 `DecodeStage` 输出，保留 lane1 `rs1/rs2/imm/cmp_op`。
- 新增 lane1 barrier dispatch mux：`core_dispatch0` 仍取 head lane0，`core_dispatch1_valid=0`。
- pending memory 增加 `pending_mem_next_pc_q`，让 lane0/lane1 memory 共用同一 pending 机制但使用不同 fallthrough。
- pending branch/jump 直接复用已有 `pending_*` 寄存器，只是元数据来自 lane1。

### 4. RTL 修改计划

- 调整 `OooAluFetchCore` 的 fetch fault、dispatch valid、unsupported 与 FIFO pop 条件，区分 lane0 fatal 与 lane1 半包屏障。
- 新增 lane1 ebreak/control/memory/fetch-fault 捕获逻辑。
- 扩展 `tb_ooo_alu_fetch_core`，覆盖 lane1 fetch fault 先提交 lane0、lane1 ebreak、lane1 branch/jump/memory。
- 回归 OoO testbench、实验 lint/build、raw CPI smoke 与默认主线。

## 验证记录

- `make RESULT_DIR=/tmp/ysyx-ooo-lane1 /tmp/ysyx-ooo-lane1/logs/tb_ooo_alu_fetch_core.log` PASS；新增覆盖 lane1 `ebreak`、taken branch、`JAL`、store/load barrier 和 lane1 fetch fault 先提交 lane0。
- `make -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-lane1-module summary` PASS，模块回归 `38/38`。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 lint` PASS。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 default` PASS。
- raw memory smoke `/tmp/ysyx-ooo-mem.bin` 在实验核 GOOD TRAP：`pc=0x80000020`、`cycles=28`、`commits=8`、`CPI=3.500`。
- raw 4096 独立 ALU smoke `/tmp/ysyx-ooo-alu4096.bin` 在实验核 GOOD TRAP：`pc=0x80004000`、`cycles=2055`、`commits=4096`、`CPI=0.502`。
- `make -C npc/single lint` PASS。
- `make -C npc/single clean && make -C npc/single default` PASS；确认默认构建未带 `NPC_OOO_ALU_EXPERIMENT`。
- `AM_HOME=/home/lyg/PA/ysyx-workbench/abstract-machine make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS="--no-progress -m 200000"` PASS / GOOD TRAP：`cycles=1509`、`commits=838`、`CPI=1.801`。

## 结果与限制

- 本轮消除了 lane1 control/memory/ebreak/fetch fault 作为 packet 后半条时会直接落入 unsupported 或吞掉 lane0 的问题。
- lane1 branch/jump/memory 当前仍是精确 drain barrier：功能正确、边界清楚，但控制流和访存密集程序 CPI 会差。
- 尚未实现 branch checkpoint/rollback、BTB/RAS 接入、LSQ、store commit、CSR/trap 全面精确路径；因此长期目标“完整乱序超标量处理器、CPI=0.5”尚未完成。
