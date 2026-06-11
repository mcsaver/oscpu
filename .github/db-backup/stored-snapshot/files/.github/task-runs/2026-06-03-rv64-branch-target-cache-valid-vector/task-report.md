# RV64 BranchTargetCache valid 向量化与后端 testbench 协议重基线

## 目标

继续按商业 ASIC RTL 风格清理 RV64 活动路径中的仿真式写法。本轮聚焦 `OooBranchTargetCache`：

- 去掉 reset/clear/invalidate_all 路径中 blocking `for` 循环清全表 data/tag 的写法。
- 去掉局部 `BLKSEQ` waiver。
- 保持 lookup/capture/store invalidate/fence invalidate 语义不变。
- 顺手修复新 `OooMulDivUnit` 引入后 module testbench 源列表与 `tb_ooo_int_backend` 固定拍点假设，使验证真正覆盖新后端协议。

## RTL 推导

### 需求

`OooBranchTargetCache` 是 lane1 branch target packet cache，entry 规模小（当前 16），但 reset/clear 用仿真式全表 data/tag 清零：

- 对可综合实现不必要，因为 lookup hit 已由 valid bit 门控。
- blocking sequential loop 需要 `BLKSEQ` waiver。
- 清 data/tag 会增加无意义 reset fanout 和寄存器翻转。

### 协议规则

- lookup hit 当且仅当：
  - `valid_q[idx] == 1`
  - `branch_pc_q[idx] == lookup_branch_pc_i`
  - `target_pc_q[idx] == lookup_target_pc_i`
- capture 写入同一 index 的 `branch_pc/target_pc/next_pc/inst`，并置 valid。
- `clear_i` 与 `invalidate_all_i` 语义都是使所有 entry lookup miss。
- store invalidate 只清 target fetch word 被 store 命中的 entry。

### 状态机/不变量

- `valid=0` 时 data/tag 全部 don't-care。
- reset/clear/invalidate_all 只需清 `valid_q`，不会影响任何可见 hit/data 行为。
- `invalidate_all_i` 优先级保持高于 store/capture。
- store 与 capture 同拍时，若 store 命中 capture target fetch word，则 capture 不置 valid。

### 数据通路约束

- `valid_q` 从 unpacked bit array 改为 packed vector，可用单个 vector assignment 清表。
- store invalidate 仍保留 16-entry 小 CAM 扫描，因为失效依据是 target fetch word，不是 branch PC index；没有额外 target-indexed side structure 时，不能像 fetch packet cache 那样定点到少数 branch-PC index。
- store 命中比较改为 `store_addr` 是否处于 target fetch word `[tag_base, tag_base+7]`，避免函数输入高位切片造成未使用位告警。

## 代码改动

- `npc/rv64/vsrc/frontend/OooBranchTargetCache.v`
  - `valid_q` 改为 packed vector。
  - reset/clear/invalidate_all 只清 valid vector。
  - store invalidate 使用 nonblocking 清 valid。
  - 删除 `BLKSEQ` waiver。
- `npc/rv64/testbench/Makefile`
  - 新增 `TB_OOO_INT_BACKEND_SRCS`。
  - 把 `OooMulDivUnit` 纳入所有依赖 `OooIntBackend` 的 module testbench source list。
- `npc/rv64/vsrc/ooo/backend/OooIntBackend.v`
  - 将 `mem_issue_block_w` 声明提前到首次使用前，消除 Icarus implicit-wire 风险。
- `npc/rv64/testbench/tests/tb_ooo_int_backend.sv`
  - 补齐 `recover_gprs_i`。
  - 新增 mem0 request/response/commit 等待任务。
  - lane1 store、LR/SC、AMOADD 从固定拍点检查改为按真实 valid/ready/commit 事件检查。

## 验证

- `make -C npc/rv64/testbench TESTS='tb_ooo_fetch_trap_gate tb_ooo_alu_fetch_core tb_ooo_int_backend' RESULT_TIMESTAMP=20260603-btc-valid-vector-intbackend-r3 run`: PASS 3/3
- `make -C npc/rv64 lint`: PASS
- `make -C npc/rv64 -j2`: PASS
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv`: GOOD TRAP
  - `smoke-jal-link`: cycles=41, commits=16
  - `smoke-branch-raw`: cycles=188448, commits=122893
  - `smoke-muldiv`: cycles=634, commits=88
- `git diff --check`: PASS

## 边界

- `OooBranchTargetCache` 的 store target invalidation 仍是 16-entry 小 CAM 扫描；要完全去掉扫描，需要引入 target-word indexed structure 或 generation/tag 方案。
- `OooBranchDirectionPredictor` 与 `OooJalrBtb` 仍存在 reset loop/BLKSEQ 风格，是后续同类 cleanup 候选。
- 本轮 testbench 修改不是放宽验证，而是把固定拍点假设改为真实 ready/valid 多周期协议事件。
