# OoO wide fetch 阶段任务记录

## 背景

目标仍是“完成一个乱序超标量处理器，CPI=0.5”。上一阶段已经把 ALU-only OoO 实验核接到 `NpcSimTop`，但 `OooAluFetchCore` 仍通过单字 `ifu_axi_*` 依次抓 `PC` 和 `PC+4`，raw smoke 只有 `CPI=4.833`。本阶段先解除实验核前端的单字串行瓶颈，做 2-wide packet fetch 与小 fetch FIFO。

## RTL 推导摘要

### 需求

- `OooAluFetchCore` 每个 fetch packet 覆盖 `PC` 与 `PC+4` 两条 32-bit 指令。
- 前端允许在后端 dispatch/commit 的同时继续预取后续 packet，避免“取完一包再派发下一包”的空泡。
- `NpcSimTop` 的 `NPC_OOO_ALU_EXPERIMENT=1` 路径用双 `npc_ifetch` 直接生成 packet response，默认 `NpcCore` 主线不变。
- 当前仍限定 ALU-only 子集，不在本阶段实现 LSQ、branch checkpoint、CSR/trap 精确回滚和 RVC。

### 协议规则

- fetch request 使用 `fetch_req_valid_o/fetch_req_ready_i/fetch_req_pc_o`，一次请求代表 `pc` 与 `pc+4` 两条指令。
- fetch response 使用 `fetch_rsp_valid_i/fetch_rsp_ready_o`，包含 lane0/lane1 指令和 lane0/lane1 `rresp`。
- 实验接口保持单 outstanding packet：新 request 只能在没有 outstanding，或旧 response 同拍 fire 时发出。
- response 必须按 request 顺序返回；前端用 outstanding PC 给 response 补上 packet PC，不依赖外部乱序 tag。
- fetch fault 只入 FIFO head 后触发 trap，不会把 fault packet dispatch 进 OoO 后端。

### 状态机

- 显式大状态压缩为 `running/halted`，取指生命周期由 `outstanding_valid_q` 表示。
- `next_fetch_pc_q` 指向下一次 packet request 的 PC；request fire 后加 8。
- `outstanding_pc_q` 保存当前未返回 packet 的 PC；response fire 后清除，若同拍发新 request 则切换到新 PC。
- FIFO head 若为 fault、lane0 ebreak、unsupported，会转入 halted；普通 supported packet 在后端 ready 时出队并 dispatch。

### 不变量

- `fifo_count_q <= FETCH_PACKET_COUNT`，且 request 只在 `fifo_count + outstanding < FETCH_PACKET_COUNT` 时发出。
- dispatch payload 只能来自 FIFO head；FIFO 非空且无 fault/exit/unsupported 时才允许进后端。
- lane0 fetch fault 优先于 lane1；fetch fault 优先级高于 decode unsupported。
- lane0 `ebreak` 是当前实验结束协议，不退休，不进入后端；lane1 `ebreak` 暂继续按 unsupported/trap 边界处理。
- ROB commit 口和 host 双 commit 队列保持程序序；前端预取不会改变提交顺序。

### 数据通路骨架

- `next_fetch_pc_q -> fetch_req_pc_o` 产生 packet 地址。
- `outstanding_pc_q + response lane data/resp -> fetch FIFO tail`。
- `fetch FIFO head -> OooAluCoreSlice dispatch0/dispatch1`。
- `OooAluCoreSlice -> ROB commit -> OooArchRegFile/host commit event` 保持上一阶段结构。

## 验证计划

- 扩展 `tb_ooo_alu_fetch_core`：检查连续 packet request、原 ALU/unsupported 行为、lane1 fetch fault、lane0 ebreak exit。
- 复跑 OoO 相关 testbench、实验 lint/build、实验 ALU raw smoke 与默认主线 lint/build/smoke。

## 实施结果

- `OooAluFetchCore` 从串行 `FETCH0/FETCH1/DISPATCH` FSM 改为 packet request、one-outstanding response 和 4-entry fetch FIFO。
- `NpcSimTop` 的 `NPC_OOO_ALU_EXPERIMENT=1` 路径改用双 `npc_ifetch(pc)` / `npc_ifetch(pc+4)` 生成 packet response；默认 `NpcCore` 路径仍走原 AXI bus。
- 修复宽取指后暴露的精确退出问题：`ebreak`、fetch fault 和 unsupported packet 现在先冻结前端，等待 ROB/issue drain 后再上报 exit/trap，避免更老指令被 host 退出检查跳过。
- `tb_ooo_alu_fetch_core` 新增连续 packet fetch、lane1 fetch fault、lane0 ebreak exit 覆盖。

## 验证结果

- `make -C npc/single/testbench ... tb_ooo_alu_fetch_core.log` PASS。
- OoO 相关 11 个 testbench 全部 `[RESULT] PASS`。
- `make -C npc/single NPC_OOO_ALU_EXPERIMENT=1 lint` PASS。
- `make -C npc/single BUILD_DIR=/tmp/npc-ooo-wide-fetch-sim-build NPC_OOO_ALU_EXPERIMENT=1 -j4` PASS。
- 短 ALU raw smoke：`/tmp/ooo-wide-short-ebreak.bin` GOOD TRAP，`cycles=11/commits=6/CPI=1.833`，上一阶段同类短程序为 `CPI=4.833`。
- 512 条独立 ALU raw smoke：GOOD TRAP，`cycles=263/commits=512/CPI=0.514`。
- 4096 条独立 ALU raw smoke：GOOD TRAP，`cycles=2055/commits=4096/CPI=0.502`。
- 默认主线 `make -C npc/single lint` PASS。
- 默认主线 `npc/single/testbench` 全量 38/38 PASS。
- 默认主线 `make -C npc/single -j4` PASS。
- 默认主线 `cpu-tests add` on `riscv32-npc` PASS，`cycles=1509/commits=838/CPI=1.801`。

## 剩余限制

- 该路径仍是 ALU-only 实验核，尚不能运行完整 AM 程序。
- wide fetch 当前是 Verilator 实验路径下的双 DPI ifetch 建模，还不是可综合 ICache/取指总线。
- lane1 `ebreak` 仍按 unsupported/trap 边界处理；后续需要半包派发或更完整的精确异常/停止协议。
- 下一阶段应把 wide fetch 从 DPI 实验源推进为真实 2-wide ICache/fetch buffer，并继续补 LSQ、branch checkpoint、CSR/trap。
