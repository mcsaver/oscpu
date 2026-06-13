# RV64 BPU/JALR BTB valid 向量化与 reset 收敛

## 目标

继续按商业 ASIC RTL 风格清理 RV64 活动前端路径中的仿真式 reset/clear 写法。本轮聚焦：

- `OooJalrBtb`
- `OooBranchDirectionPredictor`

目标是去掉 reset 时全表 payload 清零和 `BLKSEQ` waiver，降低 reset fanout 与无意义翻转，同时保持冷态预测、训练与 clear 语义不变。

## RTL 推导

### 需求

两个模块此前都使用仿真友好的 reset loop：

- JALR BTB reset/clear 清 valid、PC tag、target 全表。
- 方向预测器 reset/clear 清 BHT valid/counter、local history、local PHT valid/counter 全表。

这些 payload 清零对可见协议不是必需的，因为 lookup 已经由 valid bit 或 valid-gated fallback 门控；但它会带来：

- 大量 reset fanout。
- 不必要的寄存器翻转。
- sequential always 中 blocking loop 与 `BLKSEQ` waiver。
- 后续 SRAM/RF macro 化时更差的 reset 约束。

### 协议规则

`OooJalrBtb`：

- hit 当且仅当 `lookup_enable_i && valid_q[idx] && pc_q[idx] == lookup_pc_i`。
- `lookup_target_o` 只有在 hit 时对上游有意义。
- update 写入 `valid/pc/target`。
- `rst/clear` 的协议效果是所有 lookup miss。

`OooBranchDirectionPredictor`：

- invalid BHT/PHT lookup 继续按原 static BTFNT 方向预测。
- invalid local history lookup/update 使用 0 history。
- invalid BHT/PHT 首次 update 必须从 `BPU_COUNTER_INIT` 开始 saturating train，等价于旧 reset 后 counter 初值。
- valid entry 后续按既有 2-bit saturating counter 更新。

### 状态机/不变量

- payload 数组在对应 valid 为 0 时全部为 don't-care。
- clear/reset 后所有表项不可见，只有 `ghr_q` 需要回到 0，以保持 gshare 冷态索引确定。
- local history 额外需要 valid bit，否则 payload 不 reset 后首次 local PHT 索引会读到不确定历史。
- clear/reset 不改变后续第一个 update 的可见训练结果。

### 数据通路约束

- `valid_q` 从 unpacked bit array 改为 packed vector，清表用单个 vector assignment。
- 方向预测器新增 `local_hist_valid_q`，把 local history payload 与 BHT/PHT payload 一样 valid-gated。
- `counter_train()` 抽出 saturating update，统一 invalid-first 和 valid update 路径。
- 为单模块 strict lint，方向预测器用 `unused_predictor_input_bits_w` 显式消费未用于索引/符号判断的输入位；该逻辑没有 fanout，综合会优化掉。

## 代码改动

- `npc/rv64/vsrc/frontend/OooJalrBtb.v`
  - `valid_q` 改为 packed vector。
  - reset/clear 只清 valid vector。
  - 删除 reset loop 与 `BLKSEQ` waiver。
- `npc/rv64/vsrc/frontend/OooBranchDirectionPredictor.v`
  - BHT/local PHT valid 改为 packed vector。
  - 新增 local history valid vector。
  - reset/clear 只清 valid vectors 与 `ghr_q`。
  - invalid BHT/PHT update 从 `BPU_COUNTER_INIT` 训练。
  - invalid local history lookup/update 读作 0。
  - 删除 reset loops 与 `BLKSEQ` waiver。

## 验证

- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --top-module OooBranchDirectionPredictor ...`: PASS
- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --top-module OooJalrBtb ...`: PASS
- `make -C npc/rv64/testbench TESTS='tb_ooo_alu_fetch_core tb_ooo_fetch_trap_gate' RESULT_TIMESTAMP=20260603-bpu-valid-vector run`: PASS 2/2
- `make -C npc/rv64/testbench TESTS='tb_branch_predictor tb_ooo_alu_fetch_core tb_ooo_fetch_trap_gate' RESULT_TIMESTAMP=20260603-bpu-valid-vector-extra run`: PASS 3/3
- `make -C npc/rv64 lint`: PASS
- `make -C npc/rv64 -j2`: PASS
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-ras-trap-boundary`: GOOD TRAP
  - `smoke-jal-link`: cycles=41, commits=16
  - `smoke-branch-raw`: cycles=188448, commits=122893
  - `smoke-ras-trap-boundary`: cycles=119, commits=29
- `git diff --check`: PASS

## 边界

- 本轮只收敛 reset/clear 和 valid 门控，不改变预测算法或前端 redirect 协议。
- BHT/PHT/local history payload 仍是寄存器数组；若继续追求面积/功耗，应评估 SRAM/RF macro 化、epoch clear、局部写使能和读写端口约束。
- `OooAluFetchCore` 仍是前端大 owner，后续更大的 PPA 收敛应继续拆 FPU/JALR/branch-spec/redirect 等长组合路径。

