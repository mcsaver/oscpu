# RV64 T4K MIQ flush/pop 根因修复

## 基本信息

- `task_id`: `2026-07-14-rv64-t4k-miq-flush-pop`
- `status`: completed（本 focused slice；父任务全量/STA 门禁待 root 统一运行）
- `scope`: `OooMemInflightQueue` 的 flush/pop next-state、focused TB、合同与证据
- `non_goals`: 不改 bridge/SQ/control plane，不跑全量功能回归、综合或 STA，不提交

## Root cause

旧队列把 flush 与 normal pop 编成互斥 `else-if`。当旧 head 是已退休 store 的
`KIND_DRAIN` 且 response pop 与 flush 同拍时，父级与 SQ 已消费 response，但 flush 压缩仍从
旧 `valid_q/kind_q` 把该 head 当成“应存活 DRAIN”复制回来。正确集合运算应为
`filter_DRAIN(Q_old - fired_head)`，旧实现却是 `filter_DRAIN(Q_old)`。

## 接口契约冻结

| 类别 | T4K 冻结合同 |
| --- | --- |
| 握手 | `pop_valid_i && head_valid_o` 是当前 head 的最终消费事件；flush 不得撤销已 fire pop |
| stall | 本模块无 ready；full 时 normal push 不接收。上游 bridge 在 flush 拍压 ready，因此 flush+push 为非法上游交叠；模块 fail-safe 忽略该 push |
| flush | `reset > flush-compact > normal`；flush 先扣除同拍 fired head，再只保留未消费 DRAIN，保持相对顺序 |
| 异常序 | 不改 ROB/精确异常；trap flush 可与更老 retired-store DRAIN response 同拍 |
| 访存序 | committed DRAIN 不得被 flush 清，但已完成 DRAIN 必须恰好消费一次，不能复活 |
| 恢复 | kill 只标 LOAD/PROBE；flush 拍这些项均被清，DRAIN 不受 kill；push+kill 的既有 same-cycle age 标记保持 |

### 同拍优先级表

| 交叠 | next-state |
| --- | --- |
| `flush + pop(head=DRAIN)` | 排除 fired head，再压缩其余 DRAIN |
| `flush + pop(head=LOAD/PROBE/LEGACY)` | head 本就不在 DRAIN keep-set，其余 DRAIN 压缩保留 |
| `flush + push` | push 不接收；只执行 flush keep-set |
| `flush + kill` | flush 删除 LOAD/PROBE，未消费 DRAIN 保留且 killed=0 |
| normal `pop + push` | count 守恒，head/tail 各前进；非 full 时新 payload 成为队尾 |
| normal `push + kill` | 新 LOAD/PROBE 按 age 同拍写入 killed；DRAIN/LEGACY 不标 |

## RTL 推导摘要

### 阶段 1：需求

- 关闭 MIQ-G1 ghost：同拍已消费 DRAIN 不得被 flush 压回。
- 不改端口、容量、正常 push/pop 吞吐或 kill 年龄语义。
- 修复仅进入 flush 压缩选择树，不把 response/flush 组合锥接入 normal request credit。

### 阶段 2a/2b：协议与状态机

MIQ 是环形 FIFO，无显式枚举 FSM。状态转移为：reset 清空；flush 从 old head 起扫描
`count_q` 个逻辑 entry，跳过同拍 fired head 后过滤 DRAIN 并压到 index0；其它拍执行 normal
push/pop，再对旧 LOAD/PROBE 执行 kill 标记。

### 阶段 2c：不变量

1. `0 <= count_q <= ENTRY_N`，`head_valid_o <=> count_q != 0`。
2. flush 后 count 等于旧有效 DRAIN 数减去“同拍 popped head 为 DRAIN”。
3. flush survivor 的 FIFO 相对顺序与 payload 保持。
4. fired head 最多消费一次；不得在任何后继 response 前继续占 MIQ。
5. normal pop+push 与 same-cycle push+kill 行为不变。

### 阶段 2d/2e：数据通路与 RTL 拓扑

- 端口、时钟域、复位不变；所有状态仍由单个 `always @(posedge clk)` 更新。
- 4 路 flush `for` 循环综合为并行 kind/valid 比较与压缩 mux 树；新增谓词只排除
  `pop_fire_w && rd==0`，不添寄存器或共享资源。
- 优先级：`rst > flush compact(including fired-head subtraction) > normal push/pop/kill`。
- normal critical path 不变；新增条件只在 flush next-state 数据面。
- 不新增 function；计数 shadow 仅在 `OOO_ASSERT` 下用于 delayed invariant。

## 验证计划

1. 修复前运行新 focused TB，要求唯一 DRAIN 与 wrapped 两-DRAIN 场景精确 RED，并让 delayed
   count invariant 非真空触发。
2. 修复后同 TB GREEN，覆盖 flush-only、flush+pop、flush+pop+push+kill、normal pop+push、
   same-cycle push+kill。
3. 最小运行 RTL style、该 focused test；不以此越级替代父任务全量门禁。

## 实现与验证结果

- RTL：flush 压缩候选新增 `!(pop_fire_w && rd==0)`，先兑现已 fire 的 head pop；normal
  push/pop/kill 文本不改。
- 断言：`[MIQ-FLUSH-POP-COUNT]` 延迟一拍核对
  `old_valid_DRAIN_count - popped_head_DRAIN`。
- 永久 TB：新增 `tb_ooo_mem_inflight_queue` 并纳入 module test list，覆盖 single/wrapped
  flush+pop、flush-only、flush+pop+push+kill、normal pop+push、same-cycle push+kill。
- 修复前 RED：9 个检查失败；断言精确触发 3 次，分别为 `count 1!=0`、`2!=1`、`1!=0`。
- 修复后 GREEN：`[PASS] tb_ooo_mem_inflight_queue`、`[RESULT] PASS`。
- 既有集成 GREEN：`[PASS] tb_ooo_int_backend`，T3V full+pop、buffer-kill、LR/SC marker 均保留。
- RTL style：PASS。

证据：

- `evidence/red/logs/tb_ooo_mem_inflight_queue.log`
- `evidence/green/logs/tb_ooo_mem_inflight_queue.log`
- `evidence/integration/logs/tb_ooo_int_backend.log`
- `evidence/check-rtl-style.log`

## 实现者 / 审查者对抗

- 实现者：集合公式、wrapped payload 与同拍四事件矩阵均已由 RED→GREEN 关闭；修复不触及
  bridge/SQ/control 接口，也不改 normal request credit。
- 审查者：此前 T3V full+pop 测试不含 flush，不能替代 MIQ-G1；`KM-STG-MIQ` 也只检查
  `bridge staged => MIQ nonempty`，抓不到 bridge idle + MIQ ghost。新增 standalone invariant/TB
  补上该盲区。仍未提供完整 NpcCoreTop 程序波形、全量 module/ISA 回归或 fresh synthesis/STA；
  尤其父任务 5ns margin 很小，本 RTL 变化后旧 timing artifact 不能继续当作 current-source 证明。
