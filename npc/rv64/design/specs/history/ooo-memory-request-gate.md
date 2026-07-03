# OooMemoryRequestGate 规格

## 阶段 1：需求

`OooMemoryRequestGate` 负责从 `OooAluFetchCore` 中抽出外部 data-memory
request/response 边界的纯组合控制：

- pending FP load/store 序列化请求的 valid/fire/rsp-fire 判定。
- pending FP 请求与 OoO core lane0 memory 请求之间的优先级 mux。
- OoO core lane1 memory 请求的直通。
- core-local/checkpoint memory flush 与 SATP/SFENCE MMU flush 输出。

本模块不持有状态。pending FP memory pending/done、core LSU 状态、
checkpoint/flush/trap 状态仍由父模块和既有子模块持有。

## 阶段 2a：协议规则

- pending FP memory request 在 `stop_pending && pending_fp && backend_drained`，
  且没有已发请求、没有已完成 memory 操作时有效。
- pending FP memory request fire 等于 pending FP request valid 与 external
  `mem_req_ready` 同拍握手。
- pending FP memory response fire 等于 pending FP memory pending 与 external
  `mem_rsp_valid` 同拍握手；旧逻辑不检查 error/page-fault，本切片保持不变。
- lane0 external memory port 优先承载 pending FP memory request；pending FP
  未请求时直通 OoO core lane0 memory request。
- lane1 external memory port 直通 OoO core lane1 memory request。
- pending FP memory pending 时，external `mem_rsp_ready` 强制为 1；否则直通
  core lane0 response ready。
- `mem_flush` 等于 core-local flush 或 checkpoint memory flush。
- `mmu_flush` 等于 SATP write commit 或 SFENCE commit。

## 阶段 2b：状态机

本模块无状态机，是纯 Mealy 组合网络。所有 pending/flush 状态更新都保留在
`OooAluFetchCore`、`OooControlFlushSequencer`、`OooFpPendingExec` 和
`OooAluCoreSlice` 中。

## 阶段 2c：不变量

- pending FP request 优先级高于 core lane0 request。
- pending FP request payload 必须使用 aligned bus address、FP store flag、
  FP wdata 和 FP wstrb。
- lane1 request payload 不受 pending FP request 影响。
- `pending_fp_mem_req_fire_o` 只能在 pending FP request valid 且 external ready
  时置位。
- `pending_fp_mem_rsp_fire_o` 只能在 pending FP memory pending 且 response valid
  时置位。
- 本模块不写 FPR/GPR/CSR/ROB，不生成 trap，不改变 pending 状态。

## 阶段 2d：数据通路约束

- pending FP request valid 是 5 个一位条件的 AND。
- lane0 memory request 是 pending-FP/core 的 2:1 mux。
- lane1 memory request 是直通 wire。
- flush 输出是两个 OR 门。

## 阶段 3：RTL 映射

RTL 文件为 `npc/rv64/vsrc/memory/OooMemoryRequestGate.v`。单元测试
`tb_ooo_memory_request_gate` 覆盖 idle/core直通、pending FP load/store 优先级、
FP request blockers、FP response ready/fire、lane1直通、mem flush 和 mmu flush。
