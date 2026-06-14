# Dispatch log

## RECALL

- 读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/known-issues.md`、`.github/instructions/npc-optimization-workflow.instructions.md`、`.github/instructions/rtl-generation-workflow.instructions.md`。
- 复核 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、`npc/single/design/study/README.md`。
- 代码入口：`BranchPredictor.v`、`OooAluFetchCore.v`、`NpcSimTop.sv`、`cpu-exec.cpp`。

## PLAN

1. 确认 OoO 剩余 BPU 缺口。
2. 设计与原 BPU 等价但不破坏 OoO 边界的方向预测数据通路。
3. 修改 RTL 与仿真统计链路。
4. focused/build/full CPU-test 验证。
5. 更新 memory 与 task-run。

## DISPATCH / VERIFY

- 定位原 BPU 逻辑：`BranchPredictor.v` 使用 direct-mapped BTB、gshare BHT/GHR、local history/PHT、local strong override、RAS arch/spec。
- 定位 OoO 缺口：普通 JALR BTB 已补；条件分支方向仍在 `OooAluFetchCore.v` 用 `imm[31]` 静态 BTFNT；`cpu-exec.cpp` 的 OoO branch accuracy 仍按静态估算。
- RTL 推导后落盘：
  - `OooAluFetchCore.v` 新增 branch BHT/GHR/local predictor。
  - `NpcSimTop.sv` 新增 OoO branch lookup/resolve DPI 事件。
  - `cpu-exec.cpp` 停止 OoO branch commit-time BPU resolve 静态估算。
- focused:
  - `make -C npc/single/testbench run TESTS=tb_ooo_alu_fetch_core` PASS。
- build:
  - 首次 OoO build 因 `branch_ghr_q` reset 使用 blocking、运行时使用 nonblocking 被 Verilator `BLKANDNBLK` 拒绝。
  - 修复为 `branch_ghr_q <= ...` 后 `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 -B -j4` PASS。
- smoke:
  - `recursion` GOOD TRAP，branch accuracy `401/439`，`gshare cold=57`，JALR BTB `hit 212, miss 6`。
- full:
  - CPU-test 全量 `40/40 PASS`。
  - `/tmp/ooo-bpu-dynamic-full-cputests.tsv`：`64582/78679/0.820829`。
  - 三类代表：`dummy`、`crc32`、`leap-year`。
- non-OoO:
  - `make -C npc/single NPC_OOO_ALU_EXPERIMENT=0 -B -j4` PASS。

## ADAPT

- 未实例化顺序核 `BranchPredictor` 的原因：该模块会同时带入 spec RAS/BTB 预测语义，而 OoO 已有独立 RAS、JALR BTB、pending/drain/branch shadow prefetch 协议，直接复用会扩大回滚边界并增加冲突风险。
- 本轮选择“同构实现方向预测”的原因：能在 OoO 当前安全预测点达成相同的 gshare/local 训练效果，并保留既有 OoO 控制流不变量。

## RECORD

- 已更新 `.github/memory/project-status.md`。
- 已更新 `.github/memory/modules/npc.md`。
- 本目录记录本轮 RTL 推导与验证证据。
