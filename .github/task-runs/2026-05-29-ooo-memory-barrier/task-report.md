# OoO lane0 load/store 精确屏障

## 目标

把 ALU-only OoO 实验核推进到最小访存能力：lane0 自然对齐 `load/store` 可以在精确屏障下执行，`load` 的 rd 写回仍经过 rename/PRF/ROB，`store` 通过后端 memory uop 完成并按 ROB 提交可见。

## RTL 四阶段记录

### 1. 需求

- 支持 fetch packet lane0 的 RV32I load/store 子集，第一阶段以自然对齐 PMEM/MMIO 访问为验证重点。
- `load` 不能由前端 synthetic commit 直接改架构 GPR，必须走后端 rename、物理寄存器、ROB 和架构提交。
- `store` 不写 rd，但要以 uop 形式进入 ROB，便于未来替换为真正 LSQ/commit-store。
- lane1 load/store 暂不执行，作为 unsupported 边界；lane0 memory 后续指令通过重新取 `pc+4` 保持程序序。
- 当前不实现乱序 load-store speculation、store buffer forwarding、cache miss 多 outstanding 或内存依赖预测。

### 2. 协议/状态机/不变量

- 前端协议：发现 lane0 memory 后冻结 fetch/dispatch，等待更老 ROB、issue queue、retire 输出全部排空。
- 单发协议：排空后只派发 lane0 memory uop，lane1 不派发；memory uop 提交并 drain 后清空 fetch FIFO/outstanding，`next_fetch_pc=pc+4`。
- 后端协议：memory uop 只从 issue0 发射；发射时若 LSU 判定 misaligned，直接写回 ROB exception；否则发起单 outstanding memory request，等待 response 后写回 ROB done。
- 不变量：
  - 前端 memory barrier 期间不发新 fetch request，也不 dispatch 年轻 packet。
  - 任意时刻后端最多一个 memory request outstanding。
  - `load` 的写回数据来自 LSU 对 memory response 的提取/符号扩展。
  - `store` 在当前 barrier 模式下不会与更老异常或更年轻执行交错；未来接 LSQ 时要把 side effect 移到 commit-store。
  - lane1 memory/control-flow 不会因为 decode backend 放行 lane0 memory 而误进入后端。

### 3. 数据通路

- `OooIntBackend` 新增 memory request/response 端口，复用现有 `LSU` 生成 aligned address、write data、write strobe、load extract 和 misaligned 标志。
- `OooAluDecodeBackend` 对 lane0 放行 load/store，lane1 继续拒绝 memory uop。
- `OooAluFetchCore` 新增 lane0/lane1 memory decode 观测、pending memory 元数据、单 lane dispatch mux。
- `NpcSimTop` 在实验路径用已有 DPI `npc_mem_read/npc_mem_write` 建模一拍后返回的 memory response；默认 `NpcCore` 路径不变。

### 4. RTL 修改计划

- 扩展 `OooIntBackend/OooAluDecodeBackend/OooAluCoreSlice/OooAluFetchCore` 的 memory 端口链路。
- 在 `OooIntBackend` 中加入单 outstanding memory request 状态与 memory response writeback mux。
- 在 `OooAluFetchCore` 中加入 lane0 memory precise barrier。
- 更新 OoO 相关 testbench 端口和 `tb_ooo_alu_fetch_core` 的 store/load/consumer 覆盖。
- 在 `NpcSimTop` 实验路径接入 `npc_mem_read/npc_mem_write`，并跑 raw memory smoke。

## 验证记录

- `make RESULT_DIR=/tmp/ysyx-ooo-mem /tmp/ysyx-ooo-mem/logs/tb_ooo_int_backend.log` PASS。
- `make RESULT_DIR=/tmp/ysyx-ooo-mem /tmp/ysyx-ooo-mem/logs/tb_ooo_alu_decode_backend.log` PASS。
- `make RESULT_DIR=/tmp/ysyx-ooo-mem /tmp/ysyx-ooo-mem/logs/tb_ooo_alu_core_slice.log` PASS。
- `make RESULT_DIR=/tmp/ysyx-ooo-mem /tmp/ysyx-ooo-mem/logs/tb_ooo_alu_fetch_core.log` PASS；新增 `MODE_MEM_LW_SW` 验证 `sw x1,0(x2)` 写入 `11`、`lw x4,0(x2)` 读回 `11`、消费者 `x5=12`。
- `make -C npc/single/testbench RESULT_DIR=/tmp/ysyx-ooo-mem-full run` PASS，模块回归 `38/38`。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 lint` PASS。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1` PASS。
- raw memory smoke `/tmp/ysyx-ooo-mem.bin` 在实验核 GOOD TRAP：`pc=0x80000020`、`cycles=28`、`commits=8`、`CPI=3.500`。
- raw 4096 独立 ALU smoke 在实验核 GOOD TRAP：`pc=0x80004000`、`cycles=2055`、`commits=4096`、`CPI=0.502`。
- `make -C npc/single lint` PASS。
- `make -C npc/single clean && make -C npc/single` 默认构建 PASS。
- `make -C npc/single run IMG=/home/lyg/PA/ysyx-workbench/am-kernels/tests/cpu-tests/build/add-riscv32-npc.bin RUN_ARGS="--max-cycles 200000"` GOOD TRAP：`cycles=1509`、`commits=838`、`CPI=1.801`。
- `git diff --check` 全仓失败仅来自既有 unrelated `outputs/manual-20260528-ai-dev-env-package/...` 两个空行 EOF；本次相关文件范围 `git diff --check -- <changed files>` PASS。

## 结论与限制

- 结论：当前实验核已从 ALU/control-flow 子集推进到最小 RV32I lane0 load/store 可运行；访存结果通过 PRF/ROB/ArchRegFile 提交，不再需要前端 synthetic 修改架构 GPR。
- 限制：访存仍通过 drain barrier 保精确性，没有 LSQ、store buffer、load-store speculation 和多 outstanding；store side effect 当前发生在执行响应阶段，依赖 barrier 保证没有更老异常和更年轻执行，后续引入预测/异常恢复时必须改为 commit-store。
