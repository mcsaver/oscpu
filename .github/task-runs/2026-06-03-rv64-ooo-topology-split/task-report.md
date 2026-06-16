# RV64 OoO RTL topology split

## 需求抽象

用户要求把现有真实 RV64 OoO core 中仍然集中在大模块里的 RTL 继续细粒度拆分，便于后续单模块性能建模、优化最短路径分析和 PPA 评估。重点包括但不限于：

- 从 `OooFetchAxiBridge` 分离 I-cache/ITLB 类状态。
- 从 `OooMemAxiBridge` 分离 D-cache/DTLB 类状态。
- 从 `OooAluFetchCore` 分离分支预测相关表项。
- 使用既有活动目录 `vsrc/cache`、`vsrc/common`、`vsrc/frontend` 等，不再把活动 RTL 放入 `legacy`。
- 不改变 core 顶层外部端口，不让拆分影响原生 ready/valid、AXI、提交和异常性能路径。

## 拓扑边界

### IFU bridge

- `OooFetchAxiBridge`: IFU request/response、Sv39 page-walk 时序、AXI read、flush/mmu_flush 协议 owner。
- `OooFetchPacketCache`: fetch packet cache 的 tag/context、lookup、fill、store overlap invalidate owner。
- `OooSv39Tlb` as ITLB: satp/VPN/PTE/level translation cache owner。

### LSU bridge

- `OooMemAxiBridge`: 双 LSU 仲裁、load/store/page-walk AXI、flush/drop response、fault/permission 检查 owner。
- `OooDataWordCache`: 物理地址 word D-cache lookup、read fill、store update、virtio-blk invalidate owner。
- `OooSv39Tlb` as DTLB: data translation cache owner。

### Frontend control flow

- `OooAluFetchCore`: packet FIFO、dispatch、redirect、branch speculation、RAS、精确系统边界 owner。
- `OooBranchDirectionPredictor`: gshare + local history/PHT 方向预测 owner。
- `OooJalrBtb`: 普通 JALR target BTB owner。
- `OooBranchTargetCache`: lane1 branch target packet cache owner。

## 协议推导

- cache/TLB leaf module 不直接驱动父模块 ready/valid，只接受 lookup/fill/clear/invalidate 信号并返回组合 hit/data。
- bridge/core 保持原协议主导权：只在原先会响应 CPU、发起 AXI、提交 redirect 或报告 fault 的状态点消费 leaf hit。
- store invalidate 和 fence/satp clear 仍由父模块根据架构事件发起，leaf 不自行理解 ROB/CSR。
- BPU leaf module 只负责 lookup/update table；frontend 仍负责 pending jump、prefetch shadow packet、branch spec queue、redirect/flush 选择。

## FSM 推导

本轮拆分不新增可阻塞 pipeline 的 leaf FSM：

- `OooFetchPacketCache`、`OooDataWordCache`、`OooSv39Tlb`、`OooBranchDirectionPredictor`、`OooJalrBtb`、`OooBranchTargetCache` 都是同步表项更新 + 组合 lookup。
- `OooFetchAxiBridge` 原 demand fetch/page-walk AXI FSM 保留在父模块。
- `OooMemAxiBridge` 原 LSU read/write/page-walk/drop/flush FSM 保留在父模块。
- `OooAluFetchCore` 原 fetch/dispatch/redirect/branch speculation 控制仍保留在父模块。

## 不变量

- TLB hit 后的权限、A/D、SUM/MXR、execute/load/store fault 检查仍在 bridge 内执行。
- `mmu_flush_i` 清 ITLB/DTLB；fetch packet cache 保持原行为随 mmu flush 清除，物理 D-cache 不因 satp/sfence 全清。
- virtio-blk store 仍会清空 D-cache valid，避免 DMA 写回被旧 word cache 遮住。
- fetch packet cache store invalidate 仍按 packet 与 store word overlap 定向清除。
- satp boundary 仍清 JALR BTB 与 branch target cache。
- 新 leaf 模块 reset 只清 valid/状态必要位，避免给数据阵列增加无意义 reset 扇出。

## 数据通路约束

- 不增加 `NpcCoreTop`/core 外部端口。
- 保留 bridge/core 内部关键层次化观测 wire，例如 `cache_hit_w`、`req_dcache_hit_w`、bridge `state_q` 等，便于既有 bypass 性能统计继续读取。
- 每个新 module 一个文件，并通过 `npc/rv64/vsrc/filelist.mk` 统一纳入构建。
- focused bridge testbench 显式加入新 cache/TLB helper source，frontend testbench 通过 `RTL_OOO_FRONTEND_HELPERS` 获取 BPU helper。

## RTL 实现

新增：

- `npc/rv64/vsrc/cache/OooFetchPacketCache.v`
- `npc/rv64/vsrc/cache/OooDataWordCache.v`
- `npc/rv64/vsrc/common/OooSv39Tlb.v`
- `npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v`
- `npc/rv64/vsrc/frontend/OooJalrBtb.v`
- `npc/rv64/vsrc/frontend/OooBranchTargetCache.v`

修改：

- `npc/rv64/vsrc/core/OooFetchAxiBridge.v`
- `npc/rv64/vsrc/core/OooMemAxiBridge.v`
- `npc/rv64/vsrc/ooo/frontend/OooAluFetchCore.v`
- `npc/rv64/vsrc/filelist.mk`
- `npc/rv64/testbench/Makefile`

## 验证证据

通过：

- `git diff --check`
- `make -C npc/rv64 lint`
- `make -C npc/rv64 -j1`
- `make -C npc/rv64/testbench TESTS='tb_ooo_fetch_axi_bridge' RESULT_TIMESTAMP=20260603-ooo-split-fetch run`
- `make -C npc/rv64/testbench TESTS='tb_ooo_mem_axi_bridge' RESULT_TIMESTAMP=20260603-ooo-split-mem run`
- `make -C npc/rv64/testbench TESTS='tb_ooo_sv39_boot' RESULT_TIMESTAMP=20260603-ooo-split-sv39 run`
- `make -C npc/rv64/testbench TESTS='tb_ooo_priv_system' RESULT_TIMESTAMP=20260603-ooo-split-priv run`

未闭合：

- `make -C npc/rv64/testbench TESTS='tb_ooo_alu_fetch_core' RESULT_TIMESTAMP=20260603-ooo-split-alu-fetch-retry run` 仍失败。
- 该 testbench 仍有 `mem_req_wstrb_o/mem1_req_wstrb_o` 8-bit 端口接 4-bit testbench 信号 warning，并包含多处旧 control-flow/privilege 断言；本轮不把它作为 RTL 拆分通过证据。

## 后续优化入口

- RAS 仍在 `OooAluFetchCore` 内，后续可以继续抽为 `OooReturnAddressStack`，把 return fast path 和 satp/fence 边界独立建模。
- 当前 I/D cache leaf 仍是 packet/word 级微 cache，下一步可以分别演进为 line fill、miss buffer、page-walk cache 或多 outstanding AXI model。
- 当前 branch predictor leaf 已拆出方向/JALR/target cache，后续可在 leaf 内加入独立性能计数或替换预测算法，而不扰动前端 dispatch/redirect 协议。
