# RV64 AxiLiteXbar 预译码与 waiver 清理

日期：2026-06-03

## 目标

将 `AxiLiteXbar` 中 read-side 地址译码从 per-slave/per-master 仲裁内层提出来，降低 `S_COUNT*M_COUNT` 嵌套组合路径里的重复逻辑，并移除文件级 `UNUSEDSIGNAL` waiver，让参数化 helper 的位宽更接近可综合 RTL 写法。

## RTL 推导

### 需求

- 不改变现有 single-beat AXI-like 协议、地址图、read abort/drop-drain 语义。
- 每个 master 的 AR/AW 目标 slave 在组合块中只译码一次。
- read grant 仲裁复用预译码结果，不再在每个 slave 仲裁内层重复调用 `decode_slave()`。
- 去除 `AxiLiteXbar.v` 文件级 lint waiver，并用真实位宽表达 helper 入参。

### 协议规则

- 每个 slave 仍最多一个 active read 和一个 active write。
- read 通道仍由 `rd_active_q/rd_ar_sent_q/rd_drop_q/rd_owner_q` 持有 owner 和 drop-drain 状态。
- master-side read response buffer 行为不变：slave R 到达后可先收进 master buffer，释放 slave。
- `m_read_abort_i` 的既有契约不变：AR 未被 slave 接收时可取消；AR 已接收或同拍接收时转为 drop-drain。
- write 通道 AW/W 分开接收、合并后按 `wr_awtarget_q` 仲裁的语义不变。

### 状态机与不变量

- read/write active 状态机未新增状态，也未改变状态转移条件。
- `rd_master_busy_q` 仍保证同一 master 不产生多个未完成 read。
- `wr_master_busy_q/wr_aw_hold_q/wr_w_hold_q` 仍保证 AW/W 合并后才进入 slave write owner。
- 预译码信号 `artarget_decode_r/awtarget_decode_r` 是纯组合派生，不持有跨周期协议状态。
- flush/abort 后不会产生 orphan response，原 drop-drain 路径保持原样。

### 数据通路约束

- `decode_slave()` 仍是唯一地址窗口匹配函数，避免 read/write 两套译码规则漂移。
- `artarget_decode_r[m]` 和 `awtarget_decode_r[m]` 在组合块开头按 master 生成。
- read grant 条件从 `decode_slave(m_araddr[cand]) == slave_idx(s)` 改为 `artarget_decode_r[cand] == slave_idx(s)`。
- helper 函数索引入参收窄为 `MASTER_W/SLAVE_W`，不再用宽 `integer idx` 后只消费低位。

## 改动文件

- `npc/rv64/vsrc/bus/AxiLiteXbar.v`

## 验证

- `verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC --top-module AxiLiteXbar npc/rv64/vsrc/bus/AxiLiteXbar.v` PASS
- `make -C npc/rv64 lint` PASS
- `make -C npc/rv64 -j2` PASS
- `make -C Linux/tools smoke-jal-link smoke-branch-raw smoke-muldiv` PASS
  - `smoke-jal-link`: GOOD TRAP，`cycles=41, commits=16`
  - `smoke-branch-raw`: GOOD TRAP，`cycles=188448, commits=122893`
  - `smoke-muldiv`: GOOD TRAP，`cycles=634, commits=88`
- `git diff --check` PASS

## 边界

- 本轮是低风险结构化 RTL 清理，不声明已经完成 xbar route queue 或多 outstanding 改造。
- 当前仓库没有现成 `AxiLiteXbar` 专用 testbench；本轮验证覆盖为严格单模块 lint、完整顶层 lint/build，以及会经过 IFU/LSU 总线通道的 focused smoke。
- 没有运行 Vivado 综合或时序报告，因此不声明量化 PPA 收益；收益口径限于减少重复组合译码和去除文件级 lint waiver。

## 后续

- 下一步若继续处理 xbar PPA，应把 per-slave grant/route 拆为更明确的 route queue 或小型 arbiter 模块，并补专用协议 testbench。
- 当前 read 通道仍是 single outstanding/master busy，若要重叠 fetch refill 或 LSU miss，需要重新设计 owner/response route 协议，不能只改 bridge 两端。
