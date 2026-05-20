# NPC LSU/MemoryStage 控制数据分离记录

## 任务目标

- 继续推进 NPC RTL 中“控制信号和数据路径分离”的模块化方向。
- 本轮聚焦访存链：`LSU` 的 lane 控制与数据搬移拆分，`MemoryStage` 的 pending/response 控制与 LSU 数据路径拆分。
- 保持 `LSU`、`MemoryStage` 对 `NpcCore` 的外部端口不变，避免扩大上游流水线改动面。

## RTL 推导摘要

### 需求

- 新增 `LSUControl`：由 `addr_low/mem_size/mem_unsigned` 组合生成 `byte_shift/wstrb/load_size/load_unsigned/misaligned`。
- 新增 `LSUDataPath`：由控制面结果驱动地址对齐、store 数据移位、load 返回数据提取和符号/零扩展。
- 新增 `MemoryStageControl`：独立维护 MEM 阶段访存请求 pending 状态，产生 `lsu_req_valid/response/fault/pending`。
- 原 `LSU`、`MemoryStage` 作为封装与接线层保留，不改变对外接口。

### 协议规则

- `MemoryStageControl` 仍采用原 ready/valid 事务规则：非 pending 且 EX/MEM 有 load/store 时发起请求；`lsu_req_valid && lsu_req_ready` 后进入 pending；pending 且 `lsu_rsp_valid` 时产生 response。
- `clear_i` 清空 pending，优先级高于正常 update。
- `update_en_i=0` 时 pending 状态保持，防止全局流水线停顿时控制状态自行推进。
- `LSUControl` 和 `LSUDataPath` 均为组合逻辑，不引入新拍点。

### 状态机

- `MemoryStageControl` 只有 1 bit 状态 `mem_pending_q`：
  - `0`：没有在途数据访存，可在 `ex_valid && (load|store)` 时发请求。
  - `1`：已有在途请求，等待 `lsu_rsp_valid`。
- 转移：
  - reset/clear：任意状态到 `0`。
  - `0 -> 1`：`update_en_i && lsu_req_valid_o && lsu_req_ready_i`。
  - `1 -> 0`：`update_en_i && response_o`。
  - 其它条件保持。

### 不变量

- 非 pending 时才允许对 DCache 发起新的 CPU-side 请求。
- `response_o` 只能在 pending 且 EX/MEM 仍是有效 load/store 且 DCache 返回有效时为 1。
- `fault_o` 只在 `response_o && lsu_rsp_error_i` 时为 1。
- `LSUControl` 对 byte/half/word 的 `wstrb` 和 misaligned 判定与旧 `LSU.v` 逐位一致。
- `LSUDataPath` 对 aligned address、store data shift、load byte/half/word 扩展与旧 `LSU.v` 逐位一致。

### 数据通路约束

- 地址对齐由 `eff_addr_i & ...00` 完成，保持对齐 word 访问。
- store 数据只由 `store_data_i << byte_shift_i` 生成，wstrb 不在数据面中决定。
- load 数据先按 `byte_shift_i` 右移，再由 `load_size_i/load_unsigned_i` 选择 byte/half/word 和符号/零扩展。
- `MemoryStage` 数据面只连接 EX/MEM 保存的访存地址、store 数据、DCache 返回数据和 LSU 输出，不再持有 pending 寄存器。

## 实现摘要

- 新增 `npc/single/vsrc/LSUControl.v`。
- 新增 `npc/single/vsrc/LSUDataPath.v`。
- 新增 `npc/single/vsrc/MemoryStageControl.v`。
- `npc/single/vsrc/LSU.v` 改为组合封装层，内部实例化 `LSUControl` 和 `LSUDataPath`。
- `npc/single/vsrc/MemoryStage.v` 改为实例化 `MemoryStageControl`，保留 LSU 数据路径和 DCache 连接输出。
- `npc/single/Makefile` 将新增 RTL 文件加入 `RTL_CORE_SRCS`。

## 验证

- `make -C npc/single lint`：PASS。
- `make -C npc/single`：PASS。
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=add run NPC_RUN_ARGS='--diff=default -m 0'`：PASS。
- `timeout 180s make -C am-kernels/tests/cpu-tests ARCH=riscv32-npc ALL=load-store run NPC_RUN_ARGS='--diff=default -m 0'`：PASS。

## 备注

- 曾并行启动 `add` 与 `load-store` 两个 cpu-tests，`load-store` 日志已经 PASS，但外层 make 因共享 `.result` 文件的 `rm .result` 竞态退出码为 2；随后单独重跑 `load-store` 已 PASS。后续 cpu-tests 不应并行跑同一目录的 `run` 目标。
