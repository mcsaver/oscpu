# Task Report

## 基本信息

- `task_id`: `2026-05-20-npc-axi-bus-crossbar`
- `task_slug`: `npc-axi-bus-crossbar`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-05-20`
- `updated_at`: `2026-05-20`

## 任务目标

- `source_request`: 用户希望 NPC 的 AXI 后续能接入更多设备，并要求把总线作为独立模块抽出，同时设计 crossbar 管理主从交流。
- `goal`: 在不改变现有 ICache/DCache/NpcCore 行为的前提下，把 NpcSimTop 中直连 DPI 的 single-beat AXI-like 总线抽成独立 bus + crossbar + DPI slave 边界。
- `scope`: `npc/single/vsrc` 纯 RTL 总线模块、仿真 DPI slave、`NpcSimTop.sv` 接线、Makefile 源文件列表、基础回归验证。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 任务是 NPC RTL 平台边界重构，现有静态模板未覆盖 AXI crossbar 设计。
- `dynamic_nodes_added`: recall/design/implement/verify/record
- `why_dynamic_nodes_were_needed`: 需要按 RTL 强制工作流留下需求、协议、状态机、不变量和数据通路推导，再落 RTL 并验证。

## RTL 推导摘要

### 需求

- 当前 master 为 ICache miss-side read 和 DCache miss/writeback-side read/write，后续预留 DMA/debug 等 master 扩展。
- 当前 slave 为 DPI 平台内存模型，后续可拆成 PMEM、串口、RTC、键盘、VGA、默认错误 slave。
- 对外协议保持当前 single-beat AXI-like 形态：独立 AR/R 与 AW/W/B 通道，无 ID、无 burst、32-bit data、4-bit wstrb。
- 总线层必须独立于 core/cache，地址译码与主从仲裁不能继续散落在 `NpcSimTop.sv`。
- 第一阶段不改变 cache line refill/writeback 的 16 次 word 访问行为，不引入完整 AXI4 burst/coherence。

### 协议规则

- master 侧 valid/ready payload 在握手前必须稳定；crossbar 通过内部 register slice 接收请求，避免 slave backpressure 时组合 grant 抖动。
- read channel：每个 master 每方向最多一个 outstanding；每个 slave read channel 同时最多服务一个 outstanding，response 固定回到发起 master。
- write channel：AW/W 可独立进入 crossbar master-side buffer；当同一 master 的 AW/W 都齐备后再仲裁到目标 slave；B response 固定回到发起 master。
- 地址译码按 `(addr & SLAVE_MASK) == SLAVE_BASE` 匹配，未命中走 `DEFAULT_SLAVE`。
- read user 字段用于保留访问语义：`0=ifetch`，`1=data load`，供 DPI slave 选择 `npc_ifetch` 或 `npc_mem_read`。

### 状态机骨架

- read per-slave：`IDLE` 接收某 master AR 到内部寄存器，`SEND_AR` 向 slave 保持 AR valid，`WAIT_R` 等待 slave R 并按 owner 回送，R 握手后回到 `IDLE`。
- write per-master：AW buffer 与 W buffer 独立接收，两个 buffer 都有效时成为可仲裁 write request。
- write per-slave：`IDLE` 选择某 master 的完整 AW/W，`SEND_AW_W` 分别等待 AW/W handshake，`WAIT_B` 把 B response 回送 owner，B 握手后回到 `IDLE`。
- DPI slave：read 收到 AR 后下一拍返回 R；write 收到 AW/W 后下一拍返回 B。

### 关键不变量

- 同一 slave 的 read/write 通道每拍最多各 grant 一个 master。
- no-ID 模式下同一 master 的 read 和 write 方向各最多一个 outstanding。
- response 只能发给 route/owner 寄存器记录的 master。
- slave-side valid 在 ready 接受前 payload 不变。
- 非法地址不得静默成功，后续接默认错误 slave 时必须返回错误响应。

### 数据通路骨架

- `NpcAxiBus` 将 IFU/LSU 两个现有端口打包为 flattened master bus，并为 IFU/LSU read 生成 `aruser`。
- `AxiLiteXbar` 负责地址译码、read/write 独立仲裁、owner/route 寄存、response demux。
- `AxiDpiSlave` 承接原 `NpcSimTop.sv` 中 DPI PMEM/MMIO 调用，作为一个可替换 slave。
- `NpcSimTop.sv` 只保留 `NpcCore + NpcAxiBus + AxiDpiSlave` 结构和性能事件采样。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | Codex | completed | AGENTS/memory/study/source scan | 当前 AXI-like 端口和仿真壳边界 | 源码阅读 |
| design | Codex | completed | RTL workflow | 总线/crossbar 推导摘要 | 本文件 |
| implement | Codex | completed | 设计摘要 | RTL 与接线改动 | `AxiLiteXbar/NpcAxiBus/AxiDpiSlave/AxiDefaultSlave` 与 `NpcSimTop` 改接 |
| verify | Codex | completed | 改动后源码 | lint/testbench/build/cpu-test | lint PASS、testbench 21/21、`add/load-store/fence-i` PASS |
| record | Codex | completed | 验证结果 | memory 与 task-run 更新 | 本文件、dispatch log、project-status、npc memory |

## 关键产物

- `artifacts`:
  - `npc/single/vsrc/AxiLiteXbar.v`
  - `npc/single/vsrc/NpcAxiBus.v`
  - `npc/single/vsrc/AxiDpiSlave.sv`
  - `npc/single/vsrc/AxiDefaultSlave.v`
  - `npc/single/vsrc/NpcSimTop.sv`
  - `npc/single/Makefile`
- `logs_or_traces`:
  - `/tmp/npc-lint-xbar-fix.log`
  - `/tmp/npc-build-xbar-fix.log`
  - `/tmp/npc-add-xbar-fix.log`
  - `/tmp/npc-load-store-xbar-fix.log`
  - `/tmp/npc-fence-i-xbar-fix.log`
  - `/tmp/npc-tb-xbar-fix.log`
  - `/tmp/npc-xbar-debug4.vcd` 用于定位修复前 orphan R response
- `linked_memory_updates`:
  - `.github/memory/project-status.md`
  - `.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无
- `missing_dependencies`: 综合/STA 仍受已知 oss-cad-suite/yosys 路径缺失影响
- `risk_assessment`: 总线增加 register slice 后外部 miss 响应可能多 1 到数拍，但功能协议保持稳定；当前第一阶段仍只有一个 DPI slave，后续拆多 slave 时需补地址表和默认错误 slave 实例化。

## 下一步建议

1. 第一阶段先保持一个 DPI slave 跑通行为等价。
2. 后续把 PMEM/MMIO/default error 拆成多个 slave，再把 cacheability/PMA 从 cache 内部硬编码抽出。

## 模板升级候选

- `repeated_dynamic_subgraph`: NPC 总线/SoC 外设接入重构
- `should_promote_to_static_template`: 暂否
- `reason`: 当前是第一次执行该形态。

## 收尾结论

- `final_result`: 已完成第一阶段独立 NPC AXI-like bus/crossbar 边界。`NpcSimTop` 不再直连 IFU/LSU DPI 存储请求，而是通过 `NpcAxiBus -> AxiLiteXbar -> AxiDpiSlave`；crossbar 支持参数化 master/slave 数、地址译码、read/write 独立仲裁、master-side read response buffer、AW/W 独立接收与 response route。
- `evidence_summary`: `make -C npc/single lint` PASS；`make -C npc/single -j4` PASS；`make -C npc/single/testbench RESULT_DIR=/tmp/npc-axi-bus-crossbar-tests run` 21/21 PASS；`cpu-tests add/load-store/fence-i` 均 GOOD TRAP/PASS。
- `notes`: 调试时定位到 IFU flush 与 AR handshake 同拍会留下 orphan R response：AR 已经被 DPI slave 接收，但旧逻辑按“未发送”清掉 active/owner，随后 slave 端 RVALID 阻塞 LSU AR。最终约束为：只要 AR 当前拍或更早握手，abort 必须转成 drop-drain，master busy 保持到被取消的 R 返回并丢弃。
