# RV64 Fetch Packet Cache 定点失效

日期：2026-06-03

## 目标

将 `OooFetchPacketCache` 的 store invalidate 从默认 4096 项全表扫描，收敛为固定 5 个 halfword index 候选的定点失效，降低 store commit 路径的扇出和综合面积/时序风险，同时保持自修改代码/指令包重叠失效语义。

## RTL 推导

### 需求

- 不改变 fetch packet cache 的 lookup/fill/clear 外部协议。
- 保持 store 写入代码区时对重叠 fetch packet 的保守失效。
- 去掉 `for (0..ENTRY_COUNT-1)` 的全表扫描。
- 使用可解释、可局部验证的固定候选 index 逻辑。

### 协议与地址规则

- cache entry 的 index 使用 fetch PC 的 halfword index：`pc[INDEX_W:1]`。
- fetch packet 覆盖 `fetch_pc..fetch_pc+7`。
- store invalidate 以 4B store word 为保守重叠窗口：`store_word..store_word+3`。
- 两个窗口重叠当且仅当 `store_word <= fetch_pc + 7` 且 `store_word + 3 >= fetch_pc`。

### 不变量

- 合法 RISC-V 指令 PC 至少 halfword aligned，`pc[0] == 0`。
- 对齐后的 store word 地址满足 `store_word[1:0] == 2'b00`。
- 若某 fetch PC 与 store word 重叠，则 fetch PC 必在：
  - `store_word - 6`
  - `store_word - 4`
  - `store_word - 2`
  - `store_word`
  - `store_word + 2`
- 因此只需检查 base halfword index 的 `-3/-2/-1/+0/+1` 五个候选。
- 每个候选仍用 `same_fetch_window(pc_q[idx], invalidate_addr_i)` 复验，避免 index alias 误清无关 entry。

### 数据通路约束

- 新增 `INVALIDATE_DELTA_1/2/3` 和 `invalidate_base_idx_w`。
- `invalidate_base_idx_w = {invalidate_addr_i[INDEX_W:2], 1'b0}`，表示 store word 对齐后的 halfword index。
- 删除 `integer invalidate_idx` 与全表 `for` 循环。
- invalidate 只访问 `m6/m4/m2/p0/p2` 五个候选 entry 的 valid/pc。
- reset/clear 仍一次性清 `valid_q`；fill 同拍规则保持原先顺序，`fill_invalidated_w` 仍阻止刚被 store 命中的 packet 填入。

## 改动文件

- `npc/rv64/vsrc/cache/OooFetchPacketCache.v`

## 验证

- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -I... --top-module OooFetchPacketCache npc/rv64/vsrc/cache/OooFetchPacketCache.v` PASS
- `make -C npc/rv64 lint` PASS
- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_axi_bridge RESULT_TIMESTAMP=20260603-fetch-cache-directed-inv run` PASS
- `make -C npc/rv64 -j2` PASS
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv` PASS
  - `smoke-jal-link`: GOOD TRAP，`cycles=41, commits=16`
  - `smoke-branch-raw`: GOOD TRAP，`cycles=188448, commits=122893`
  - `smoke-muldiv`: GOOD TRAP，`cycles=634, commits=88`
- `git diff --check` PASS

## 边界

- 本轮不改变 cache 存储体形态，`valid/tag/data` 仍是寄存器数组。
- 本轮只去除 store invalidate 的全表扫描；`rst || clear_i` 仍全量清 valid，后续若面向 RAM 化可继续用 generation bit 或 epoch valid。
- 没有声明量化 PPA；本轮可证明的是从 `ENTRY_COUNT` 项动态扫描变成固定 5 项访问。

## 后续

- 若继续推进 fetch cache PPA，应把 entry data/tag 映射到 SRAM/寄存器文件风格存储，并用 epoch/generation bit 处理全局 clear。
- Branch target cache/BPU 表项仍有类似全表 clear/invalidate 风险，可沿同样“推导覆盖集合，再定点失效”的方式收敛。
