# 原生 AXI 到 NPC 平台接口

当前实际实例参数、请求/响应/背压网络和端口映射见 [BUS 拓扑文档](../bus/TOPOLOGY.md)（2026-09-08）。下文直接验证的周期数字与日志路径保留为早期切片记录；四批实施、CPI 和综合结果从拓扑文档链接进入。


`R64AxiFabric.v` 是实际 AXI4 burst 到现有单拍平台端点的转换 fabric。它没有实例化旧 `NpcAxiBus` 或 `AxiCrossbar`。

原始 `AxiCrossbar.v` 明确忽略 LEN/BURST/WLAST，恒定输出 RLAST=1；`NpcAxiBus` 还丢弃 RID/BID。`AxiDpiSlave.sv`、CLINT/PLIC/UART/reset 及 virtio 都只能为一个单拍请求提供一个单拍响应。因此新核不能直接沿用旧连接并去掉 burst 元数据。

## 接线

新 core 的统一 read master 接本模块 AR/R（4-bit ID，64-bit address/data，8-bit LEN）；统一 write master 接 AW/W/B。新核必须消费真实 RID/RLAST/BID。完整核心撤销不能 reset fabric；已经接受的事务继续 drain，由核心 transaction owner 丢弃被撤销的完成。

包含 `platform/R64PlatformMap.vh` 后参数如下：

```verilog
R64AxiFabric #(
  .SLAVES(`R64_PLATFORM_SLAVES), .SLAVE_W(4),
  .BASE(`R64_PLATFORM_BASE), .MASK(`R64_PLATFORM_MASK),
  .READ_MEMORY_MASK(16'h2800), // 实际 PSRAM / SDRAM
  .MEMORY(`R64_PLATFORM_MEMORY),
  .EXECUTABLE(`R64_PLATFORM_EXECUTABLE)
) u_fabric (...);
```

slave packed buses 保留 `NpcTop` 当前顺序，低位为 port 0：

| port | endpoint |
|---|---|
| 0 | CLINT |
| 1 | PLIC |
| 2 | reset syscon |
| 3 | UART |
| 4 | virtio block |
| 5 | Goldfish RTC（R64AxiRtc） |
| 6 | PS2 stub |
| 7,8,9 | MROM/VGA/flash stub |
| 10 | chiplink MMIO stub |
| 11 | PSRAM DPI memory |
| 12 | legacy MMIO DPI |
| 13 | SDRAM DPI memory |
| 14 | chiplink memory stub |
| 15 | default stub（新 fabric 对未命中地址内部 DECERR，此端口不选中） |

现有外设 IP 可以继续实例化；PSRAM/SDRAM/legacy/virtio 对外导出端口保持单拍 ABI。每一个合法 burst 会产生 LEN+1 个真实下游子事务，地址按 SIZE 递增（FIXED 保持地址），上游收到真实全部 R 拍或聚合所有子 B 错误的唯一 B。不能把此转换误称为 full-AXI memory：现有 DPI 端点自身单 outstanding 且至少有一个空拍，cache miss 补行吞吐受到这个端点限制。未来提高外部补行速率应增加真正的 full-AXI memory 端点与旁路路由，不能跳过末拍计数或伪造完成。

现有 Tensor 是 command/terminal 外部接口，不是此平台的 AXI master；virtio DMA 是同步 host PMEM 写后发 D-cache invalidate 请求，也不是此 fabric 的现有 master。它们的 owner/reuse/coherence 仍由 core 与平台集成维护，本模块没有臆造新的 DMA master 接口。

## 事务状态与限制

- 4 个读槽和 2 个写槽保存原始完整 ID、剩余拍数、地址及属性。相同 ID 的后续请求在前一最终 R/B 真正交付前不能占用新槽。
- AR/AW 各一个入口描述符寄存器；W 与 R 各一个共享两项 FIFO。AW 顺序队列保存两项 owner，W 可以早于 AW 到达。不同目标的读/写彼此独立。
- 读侧分为内存与 MMIO 两组，各有 plan、launch 和 return holder，共享四个事务槽和最终两项 R FIFO。每组只广播本组 AR 数据，组内先选择 RDATA；没有为 16 个目标分别复制宽 owner。慢 MMIO AR 不再占用内存组的 launch。
- 读 owner 在最终 R 交付后释放，目标的 Lite beat 占用在真实 R 接受后释放或由受控续拍保留。写 owner 在唯一 B 交付后释放；最后 W 可先释放 W 顺序队列，其他目标可以在旧 B 返回前开始工作。
- 每一个接口输出只来自寄存状态；输入 READY/VALID、地址、数据变化不会组合传播到 AXI 输出。等候 READY 的 VALID 与 payload 保持。
- 支持对齐的 1/2/4/8 字节访问、INCR 和至多 16 拍 FIXED。WRAP、不支持 SIZE、未对齐、4KiB 越界、地址窗越界、MMIO burst、非可执行端点 fetch 均内部 DECERR，禁止任何下游副作用，并完整 drain 原定拍数。
- WLAST 与原 AWLEN 不符为主设备协议错误：`protocol_error_o` 置位；`R64_ASSERT` 直接报错。核心正常数据流不得依靠这个容错路径。
- byte lane 数据/STRB 原样传输。现有 AxiDpiSlave 仅接受与 AWSIZE 一致的完整连续 WSTRB；核心自然对齐 store 与完整 cache writeback 满足此条件。任意稀疏合法 AXI strobe 的 DPI 支持仍需在仿真端点扩展，不能冒充全 AXI 外部设备功能。

## 直接验证与边界

`tb_r64_fabric.sv` 固定 LFSR seed `0x514aa731`，随机独立 master/slave 反压，验证外部输入到输出隔离、所有 payload hold、逐 ID 和逐拍数据/错误、写地址和 W 归属，以及拒绝请求零设备副作用：

- 96 个读事务、336 个 R 拍；64 个写事务、227 个 W 拍。
- 合法请求实际产生 184 个 Lite 读和 133 个 Lite 写；非法请求数量与响应分别计入上游，绝不伪称设备完成。
- 855 周期；271 次 RID 切换；91 周期读/写出口重叠；最多 6 个 live owner；AW 先到 96 次、W 先到 83 次（同拍两项都计入）。
- R 反压 100 周期、W 入口反压 413 周期。
- `+bad-last` 非零退出且精确触发 “fabric WLAST disagrees with accepted AWLEN”。
- Verilator `--lint-only -Wall -DR64_ASSERT` 无警告。

`tb_r64_fabric_devices.sv` 实例化真实 `bus/AxiClint.v`，验证 64-bit mtimecmp 写后读、32-bit 高/低字 lane、MSIP、被禁止 fetch/burst 无副作用。10 个读请求、6 个写请求中实际外设读 7 次、写 5 次，全部通过。因此旧 AM “CLINT 64 位写后 LD 0”没有在这条新 fabric + 原 CLINT 的完整握手边界复现；不能据旧症状断言 CLINT 存储坏了。CLINT 源码仍忽略 ARSIZE/AWSIZE 并将未知 offset 读零返回 OKAY，外设访问合法性需由完整平台测试判断。

原始日志：`build/rebuild/platform/fabric.log`、`bad-last.log`、`devices.log`。这些是 fabric/外设边界证据，不是完整核心/ISA/PPA PASS。

按同样 64-bit address、16 endpoints 静态数源码有效字段（不包括断言）：
旧 crossbar 地址字段 34×64=2176 bit（16 read +16 write +2 AW 入口），新 fabric 地址字段 8×64=512 bit（4 read +2 write +2 入口）。
旧 data 字段 20×64=1280 bit（16 write +2 W 入口 +2 R 完成），新 data 字段 4×64=256 bit（2 W FIFO +2 R FIFO）。
这只是宽状态复杂度减少，不是映射面积结果；旧核仅支持 single beat，新 fabric 支持实际 burst，两者功能身份不同，不能把周期直接当成 A/B CPI 收益。尚未综合/STA，也未证明 2 ns 时序。保留本切片供完整核心集成；若集成发现响应归属/进度错误则撤下该 filelist 项并修复，不能回退为忽略 LEN 的假 burst。
