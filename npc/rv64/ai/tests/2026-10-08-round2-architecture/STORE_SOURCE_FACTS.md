# 普通 store 的源码事实核查

日期：2026-10-08（Asia/Shanghai）。本文件供第二轮网页 Pro 架构咨询后的源码核查与必要反证使用。

- 实际 worktree：`/home/lyg/PA/ysyx-workbench`
- 分支：`ai`
- 记录时 HEAD：`ec653b952ca3938c893f14d9696bcb6b05b65f60`
- 分析对象是该工作区当时的实际源码，包含上一轮尚未提交的修改，不能把 HEAD 单独当作全部被分析内容的身份。
- 本子任务仅读源码；没有修改 RTL，没有启动构建、仿真或 EDA。收到保存要求后只新增本证据文件，保留其他工作者的改动。
- 下文时序是源码可证明的条件性寄存边界，**不是本轮实测延迟、CPI 或性能收益**。源码行号对应记录时的工作区。

## 已确认的核心事实

真实 `SystemTop → Core → Memory → LSU / Dcache → AXI → ROB` 连线中，普通对齐 RAM store 已有非头预备、AXI B 返回旁路、Dcache 等 B 时与读重叠，以及独立的 store→ROB 完成通道。普通 fast store 不经过 completion CQ 和 9→2 数据 WB 仲裁。

以下路径均相对 worktree。

## 真实默认配置

- `npc/rv64/vsrc/platform/R64SystemTop.v:108` 直接实例化 `R64CoreTop core`。
- `npc/rv64/vsrc/core/R64CoreTop.v:547–549` 设置 `HEAD_AUTHORIZED_QUERY(1)`、`PREPARED_CANCEL(1)`。
- `npc/rv64/vsrc/memory/R64Memory.v:253–259` 实例化 `R64LoadStore`，设置 `ENTRIES(20)`，未覆写 `EARLY_STORE`。
- `npc/rv64/vsrc/lsu/R64LoadStore.v:6` 默认 `EARLY_STORE=1`，`:139` 原样传给 LSU。
- `npc/rv64/vsrc/core/R64CoreTop.v:677–678` 明确设置 `R64AxiWrite.B_BYPASS(1)`。
- `npc/rv64/vsrc/lsu/R64LoadStore.v:327–330` 实例化 Dcache，未覆写 `SPLIT_STORE_OWNER`，所以使用 `R64Dcache.v:10` 的默认值 `1`。

关键片段：

```verilog
// core/R64CoreTop.v:547
R64Memory #(
  .HEAD_AUTHORIZED_QUERY(1),
  .PREPARED_CANCEL(1)
) memory (...);

// lsu/R64LoadStore.v:6,139
parameter EARLY_STORE = 1;
...
.EARLY_STORE(EARLY_STORE)

// lsu/R64Lsu.v:458
assign mem_fast_store_o[g] = EARLY_STORE &&
    physical_store_w[g] && !physical_atomic_w[g] &&
    !physical_misaligned_w[g] && physical_class_w[g] != 2;

// core/R64CoreTop.v:677
R64AxiWrite #(.B_BYPASS(1)) write_bus (...);
```

`class!=2` 是代码的实际表达式，不能自行改写为“所有非 MMIO 类都一定是合法 RAM”；普通正常 RAM 的 class 0/1 确实走此通道。

## Store owner 路径

本表中的短文件名属于 `npc/rv64/vsrc/`，具体子目录已在文件名中列出。

| 阶段 | owner / 关键事件 | 源码可证明的行为 |
|---|---|---|
| 非头执行准备 | LSQ `tag_q[row]`、`bound_q`、VA/data/mask、翻译 owner FIFO | 地址、数据及翻译可以先准备；`lsu/R64Lsu.v:492–493` 的 `translation_candidate_w` 不要求 head。store 的 A/D 更新许可仍要求 head/effect，见 `:822` |
| 非头 store 预备 | `prepare_candidate_w → prepare_select → prepared_*_q` | 一个独立的预备描述符，选择 READY、非头、普通非原子且自然对齐 store，无外部副作用。见 `lsu/R64Lsu.v:518–520,620–648,1936–1947` |
| 获得 head/effect 许可 | `prepared_offer_w`、`prepared_take_w` | 要求完整 `prepared_tag_q == head_tag_i` 且 `effect_allow_i`；query credit 存在时进入注册 query。见 `lsu/R64Lsu.v:275–276,303` |
| query→物理请求 | `query_valid_w`、`physical_tag_w`、`mfire_w` | query 保存完整 tag/slot/payload；空 physical holder 可直接传到下一级，被阻塞才保存在 holder。见 `lsu/R64Lsu.v:389–405,426–428,461` |
| split→service | LSQ token，扩展成 `{CPU source=0, LSQ token}` | 对齐请求经 split 组合 bypass，没有额外 split 状态拍；service 有固定槽位的注册请求队列。见 `lsu/R64MemorySplit.v:69–89`、`lsu/R64MemoryService.v:169–190,232–240` |
| Dcache 接受 | `bank_take_w` 捕获 token/address/data/strb/fast_store | bank stage 是寄存器；普通 store 随后走 `start_w → WRITE`，不先做读 refill。见 `lsu/R64Dcache.v:445–457,477–501` |
| AXI 写命令与 W data | `cmd_fire_w`、`data_take_w`、transport client 0 | Core 设置 `cmd_len=0`、第二 client valid=0，普通 store 为单 beat 写；AW 描述符与 W 队列独立。见 `core/R64CoreTop.v:682–691`、`bus/R64AxiWrite.v:63–90,144–174` |
| AW/W 外部接受 | `aw_fire_w`、`w_fire_w` | 两个 channel 独立握手，W 顺序受写命令 owner 队列约束；B owner 必须已经完成 AW 和最后一个 W。见 `bus/R64AxiWrite.v:75–85` |
| 平台转发 | `platform.fabric` 的 AW owner、W FIFO、endpoint B owner | Fabric 捕获 AW 后解码、分配写 owner，再向 endpoint 发 AW/W；最终 endpoint B 可在同一拍选入空的注册 AXI B 输出。见 `platform/R64AxiFabric.v:267–293,323–326,351–373,547–553,677–705` |
| B 返回 Dcache | `write_response_fire_w`、`store_rsp_token_o` | transport 启用 B bypass 时，空 B FIFO 可同拍向 Dcache 转交实际 B；错误码仍检查/传递。见 `bus/R64AxiWrite.v:83–90,115–117` |
| Dcache→LSU store terminal | `store_response_fire_w → store_done_q/tag/error/tval` | 普通 fast store 的专用返回直接连接 Dcache→LSU，绕过 service/split 的普通结果回程。见 `lsu/R64LoadStore.v:160–169,335–339`、`lsu/R64Lsu.v:333–341,1953–1959` |
| LSU→ROB 完成 | `store_done_fire_w` | 按完整 head tag 接受，直接设置 ROB done/exception/cause/tval，不通过数据 WB。见 `backend/R64Rob.v:325–328,487–493` |
| ROB 退休 | `done_q[head] → commit_valid → retire_fire` | 正常成功才退休；error 则产生精确 store access fault。见 `backend/R64Rob.v:256–260`、`control/R64Commit.v:76–95` |

专用完成通道：

```verilog
// backend/R64Rob.v:325–328
assign store_done_ready_o = !rst && !flush_i &&
    count_q != 0 && valid_q[head_q] && !done_q[head_q] &&
    !kill_mask_o[head_q] && ordinary_store_head_w &&
    !rd_write_q[head_q] && !serial_q[head_q] &&
    store_done_tag_i == {generation_q[head_q], head_q};
wire store_done_fire_w = store_done_valid_i && store_done_ready_o;

// backend/R64Rob.v:487–493
if (store_done_fire_w) begin
  done_q[head_q]      <= 1'b1;
  data_q[head_q]      <= 64'b0;
  exception_q[head_q] <= store_done_error_i;
  cause_q[head_q]     <= store_done_error_i ? 6'd7 : 6'd0;
  tval_q[head_q]      <= store_done_tval_i;
  fflags_q[head_q]    <= 5'b0;
end
```

`backend/R64Rob.v:539–542` 还断言同一个 store 不能同时经窄 store terminal 和数据 WB 完成。

## 条件性拍边界：不是实测

在描述符早已预备、下游无阻塞、service/cache 空闲的条件下，以 **query 接受 prepared store 的边沿为 E0**：

- **E0**：query 登记 owner。
- **E1**：query 的物理请求可通过组合 split，被 service 注册队列接受。
- **E2**：service 输出可被 Dcache bank stage 接受。
- **E3**：Dcache 从 stage 选择 store，进入 `WRITE`。
- **E4**：AXI write transport 接受 command，写入 AW/W owner 队列。
- **E5**：最早可外部接受 AW，同时内部接受 W data 到 `wvalid_q`。
- **E6**：最早可外部接受 W。

这是**当前实现的条件性最短寄存路径**，不是架构协议要求必须花这么多拍。仲裁、cache 老 owner、invalidate、AWREADY/WREADY、Fabric 和 RAM 端点都会延长它；不能据此给出 benchmark 平均 store 延迟。

返回段以 **B0 为实际 core AXI B 被 transport 接受、且 B bypass/Dcache/LSU store terminal 均可消费的边沿**：

- **B0**：LSU 捕获 `store_done_q`；Dcache 同边沿接受成功写的 cache 更新事件。
- **B1**：ROB 通过 `store_done_fire_w` 登记 done 或精确异常。
- **B2**：若无恢复冻结、trace backpressure 或异常，store 最早退休。

所以当前成功 fast store 从 core AXI B 接受到退休有**两个时钟间隔**的注册尾部。若 B FIFO 原本非空、store terminal 受阻或 ROB 冻结，会更长。这不是“B 后还要过 CQ/WB”。

## 成功 B 更新 Dcache 的准确含义

`lsu/R64Dcache.v:179–180`：

```verilog
store_write_w = write_response_fire_w && write_resp_i == 0 &&
                write_hit_w && !write_poison_w && !invalidate_i;
```

`:303–355` 先把更新写进**一拍 pending bank-write 缓冲**；该期间 lookup 按字节从 pending 数据转发，下一拍再写 data array。逻辑可见性从成功 B 更新事件开始保持一致，物理阵列写入晚一拍。

- B error 不更新 cache 数据。
- 没有 resident hit 不做 store allocate/refill。
- invalidate/poison 禁止把过期行重新写成有效数据。
- 该 pending buffer 是 data-array 写口流水，**不是 store 提前退休结构，也不是多条 store 合并**。

## 已有优化与未见能力

已有：

1. **非头 store 预备**：单个 `prepared_*_q` 描述符；当前 head 可覆盖较年轻的 prepared store，前提它尚未发布副作用。见 `lsu/R64Lsu.v:633–648,2225–2232`。
2. **head 许可保存在 query owner 中**：真实 Core 启用 `HEAD_AUTHORIZED_QUERY=1`，避免在末级 mem_valid 重走 head/effect 锥；保留与原判定逐拍相等的断言。见 `lsu/R64Lsu.v:420–446`。
3. **普通 cached store 的独立 B owner**：AW/W 内部都接受后，将 store token/address/data 保留在 detached owner，主慢路径回 IDLE，允许另 bank、不同 set 的普通 cached read 重叠。见 `lsu/R64Dcache.v:90–109,125–143,558–570`。
4. **B bypass 与 store→ROB 专用终结**：真实配置已启用。
5. **store→load 按字节 forwarding、源 owner pin**：见 `lsu/R64Lsu.v:1031–1064,1148–1160`。这保证 load 取得正确 store 字节，不是写合并。

没有看到多个普通 store 合并成一个外部 transaction 的通路：每个请求保留独立 LSQ token，每次 Core command `len=0`；Dcache 明确只允许一个独立 ordinary-store B owner，真实 Core 只使用 write transport client 0。见 `lsu/R64Dcache.v:65–68,131–143`、`core/R64CoreTop.v:682–691`。

## 当前精确性与握手约束

这些接受/保留条件是当前正确性的真实约束；不能因优化而删除。具体注册边界属于实现选择，不应混同为协议的必需周期数。

- 实际 store 物理接受必须为 ROB head 且有 effect 许可：`lsu/R64Lsu.v:2337–2339`。
- 已接受的副作用 owner 必须持有到真实 B/error/retirement，不能因年轻分支恢复被取消：`lsu/R64Lsu.v:1981–1983,2314–2322`。
- `effect_allow` 在部分分支 recovery 期间仍保持 head 请求合法，不随 retirement freeze 撤销 backpressured valid：`control/R64Commit.v:113–117`。
- IRQ 停止新 birth，但不能让已接受的 head store 消失；异常捕获等待 irrevocable owner 消除：`control/R64Commit.v:78,94–117`。
- B ID 必须对应已完成 AW/W 的存活 owner，错误 B 不可当成功：`bus/R64AxiWrite.v:83–90,177,222–223`。
- B error 写入同一 head 的 cause 7、原 VA tval；成功 store 留在 LSQ RETIRE，直到对应完整 tag 退休才释放 effect owner：`lsu/R64Lsu.v:1749–1757,1797–1798,1953–1962,2010–2014`。
- 背压时已发布的物理请求 valid/payload 必须保持：`lsu/R64Lsu.v:2254–2263`。
- 准确接受条件、owner 生命周期和错误归属必须保持；本文件不设计 posted buffer 或任何替代机制。

## 可请求的最小观测

现有 `sim/vsrc/R64CpiProfile.svh:124–130` 的 `store_b_owner` 只统计 `cache.store_active_q`，不覆盖所有 store 前端等待、非 cached BRESP，也不区分 B 前 Fabric/endpoint 延迟。现有 `R64LoadCompletionProfile.svh` 主要观测 load，不提供下列完整 store 分段时序。

建议仅为**普通 store 的 head owner**记录以下时间戳，以及对应完整 ROB tag/LSQ token，无需全核波形：

```text
首次成为 head 且 effect_allow
prepared_valid 命中该 head（首次 / 当时是否已预备）
prepared_take / query_fire
mfire
service cache_take
Dcache bank_take、start
write_bus cmd_fire / data_take
core AW fire / W fire
platform endpoint AW/W fire、endpoint B fire
core B fire
LSU store_response_fire
ROB store_done_fire
retire_fire
```

每条 store 附 class、cache hit、B error、等待期间的 freeze。这样一次短程序或小 benchmark 即可把时间分为：

1. head 时尚未准备好；
2. head 到真实 AW/W 的内部注册和资源等待；
3. Fabric/endpoint B 返回；
4. B 到 ROB 完成及退休。

这些目前仍是**建议请求的观测**，本子任务未实现或执行。仅凭旧 `store_b_owner` 比例，不能判断哪一段占主导，更不能预先声称优化收益。
