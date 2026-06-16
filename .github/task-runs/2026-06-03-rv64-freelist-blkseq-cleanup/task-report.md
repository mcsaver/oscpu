# RV64 FreeList normal path waiver 清理

## 目标

继续按商业 ASIC RTL 风格清理 RV64 活动 OoO 路径中的仿真式写法。本轮聚焦 rename/dispatch 中的：

- `npc/rv64/vsrc/ooo/rename/OooFreeList.v`

目标是删除 normal allocate/free 路径里的 `BLKSEQ` waiver，并保持 FreeList 的 2-wide alloc/free、checkpoint、flush 语义不变。

## RTL 推导

### 需求

`OooFreeList` 是 rename/dispatch 活动状态之一，负责给新目的寄存器分配物理寄存器，并在 ROB commit 后回收 old pdest。旧实现为了在时序 always 内顺序计算 `push_count` 和 `next_count`，使用了 blocking 临时变量并关闭 `BLKSEQ` lint。

这类写法虽然仿真可工作，但会把“组合推导”和“时序落状态”混在同一个 always 中。商业 RTL 审查里更希望先把 normal path 的计数、写尾指针、写使能全部组合化，再由时序块用 nonblocking 统一落状态。

### 协议规则

- 每拍最多接受 2 个 allocate request 和 2 个 free request。
- `alloc1` 只有在 alloc0 之后还有空闲项时才 fire。
- free0 先于 free1 写回 FIFO tail。
- free1 只有在 free0 之后仍有空间时才被接受。
- 同拍释放的物理寄存器不参与同拍 allocate，最早下一拍可重新分配。
- p0 永远不入 FreeList。

### 状态机/不变量

- reset/flush 初始化 freelist 为 p32..p63，`head=0`、`tail=32`、`count=32`。
- normal path 的计数不变量为：
  - `post_alloc_count = count_q - alloc_count`
  - `accepted_free_count = free0_push + free1_push`
  - `next_count = post_alloc_count + accepted_free_count`
- `head_q` 只按 `alloc_count_w` 前进。
- `tail_q` 只按 accepted free 数量前进。
- checkpoint capture/restore 的 map、head、tail、count 行为不变。

### 数据通路约束

- `post_alloc_count_w/free0_push_w/free1_push_w/push_count_w/next_count_w/free1_tail_w` 都由组合 wires 推导。
- normal sequential block 只保留 FIFO 写入与 `head_q/tail_q/count_q` 的 nonblocking 更新。
- 不新增端口、不改 filelist、不改 testbench 协议。

## 代码改动

- 删除 `push_count`、`next_count` 时序临时寄存器。
- 删除 normal path 的 `verilator lint_off BLKSEQ` / `lint_on BLKSEQ` waiver。
- 新增组合 wires：
  - `post_alloc_count_w`
  - `free0_push_w`
  - `post_free0_count_w`
  - `free1_push_w`
  - `push_count_w`
  - `next_count_w`
  - `free1_tail_w`
- normal path 更新改为：
  - free0 写 `fifo_q[tail_q]`
  - free1 写 `fifo_q[free1_tail_w]`
  - `head_q <= ptr_add(head_q, alloc_count_w)`
  - `tail_q <= ptr_add(tail_q, push_count_w)`
  - `count_q <= next_count_w`

## 验证

- `rg -n "BLKSEQ|push_count|next_count|post_alloc|free0_push|free1_push" npc/rv64/vsrc/ooo/rename/OooFreeList.v`: 无 `BLKSEQ`，只剩预期组合 wires/use sites
- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -I./npc/rv64/vsrc/include -I./npc/rv64/vsrc/ooo/rename --top-module OooFreeList npc/rv64/vsrc/ooo/rename/OooFreeList.v`: PASS
- `make -C npc/rv64/testbench TESTS=tb_ooo_free_list RESULT_TIMESTAMP=20260603-freelist-blkseq-cleanup run`: PASS
- `make -C npc/rv64/testbench TESTS='tb_ooo_free_list tb_ooo_dispatch_backend tb_ooo_int_backend tb_ooo_alu_fetch_core' RESULT_TIMESTAMP=20260603-freelist-blkseq-cleanup-extra run`: PASS 4/4
- `make -C npc/rv64 lint`: PASS
- `make -C npc/rv64 -j2`: PASS
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv`: GOOD TRAP
  - `smoke-jal-link`: cycles=41, commits=16
  - `smoke-branch-raw`: cycles=188448, commits=122893
  - `smoke-muldiv`: cycles=634, commits=88
- `git diff --check`: PASS

## 边界

- 本轮是 FreeList normal path 的 RTL 风格收敛，不是 rename/ROB 协议重构。
- reset/flush/checkpoint 里的初始化/快照循环保持原结构。
- FreeList 仍是寄存器 FIFO；后续更大的 PPA 优化可继续评估 checkpoint 压缩、RAM 化或 rename/ROB backpressure 更细拆分。
