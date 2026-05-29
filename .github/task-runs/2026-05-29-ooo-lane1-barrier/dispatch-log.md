# Dispatch Log

## 2026-05-29

- 任务：补齐 OoO 实验核 packet lane1 半包精确屏障。
- 设计选择：不新建 lane1 专用后端执行路径，而是“lane0 单发 + lane1 元数据 pending”，复用已有 branch/jump/memory/exit/trap drain 协议。
- 范围边界：本轮不解决真正预测、checkpoint/rollback、LSQ、store commit 或 lane1 任意 unsupported 指令；目标是先消除 lane1 control/memory 直接丢功能覆盖的问题。
- 实现：`OooAluFetchCore` 对 lane1 `branch/JAL/JALR/load/store/ebreak/fetch fault` 识别半包屏障；屏障 fire 时只派发 lane0，保存 lane1 PC/inst/rs/imm/cmp 元数据，drain 后进入既有 pending branch/jump/memory/exit/trap 路径；新增 `pending_mem_next_pc_q` 区分 lane0 memory 的 `pc+4` 和 lane1 memory 的 `pc+8` 继续取指。
- 测试：`tb_ooo_alu_fetch_core` 新增 lane1 ebreak、lane1 taken branch、lane1 JAL、lane1 memory、lane1 fetch fault 先退休 lane0；全量模块回归仍 `38/38`。
- 验证证据：实验 lint/build PASS；raw memory smoke GOOD TRAP `cycles=28/commits=8/CPI=3.500`；raw 4096 独立 ALU smoke GOOD TRAP `cycles=2055/commits=4096/CPI=0.502`；默认 lint、clean rebuild、`cpu-tests add` PASS，默认 `CPI=1.801`。
- 注意：`npc/single/build` 不会因 `NPC_OOO_ALU_EXPERIMENT` 变量变化自动失效；从实验构建切回默认构建时应 `make clean && make default`，本轮已按该方式验证默认主线。
